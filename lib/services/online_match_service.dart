import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// オンライン対戦の共通基盤。4つの遊び方を1つの `rooms` ドキュメントで扱う。
///
/// | game | 方式 | 勝敗 |
/// |---|---|---|
/// | `namecall` | 同時レース（同じseed・別々に解く） | 獲得枚数→タイム |
/// | `pairs` | 同時レース | 手数→タイム |
/// | `rank` | **ロックステップ早押し**（同じ問題を同時に出す） | 先取した枚数 |
/// | `turnpairs` | **ターン制**（交互にめくる） | 獲得ペア数 |
///
/// 同時レースは進捗と最終結果だけを書けば成立するので書き込みが軽い。
/// 早押しとターン制は「相手より先か」「いま誰の番か」を全員で
/// 一致させる必要があるので、部屋ドキュメントを唯一の真実にして
/// トランザクションで順序を決める（先に書けた方が勝ち）。
/// 盤面そのものは共有seedから両端末が同じものを生成するので、
/// カードの中身をFirestoreに載せる必要はない。
///
/// Firestoreは既存の `rooms` コレクションを再利用する（デプロイ済みルールが
/// 認証＋playersリスト等のサイズ検証で許可している範囲に収まる設計）。
/// 旧Cloud Functionsの `startGameOnPlayerCount` トリガーは
/// `readyPlayerIds`/`imageUrls` フィールドを要求するため、本モデルの
/// ドキュメント（どちらも持たない）では発火しない。
class OnlineMatchService {
  OnlineMatchService._();
  static final OnlineMatchService instance = OnlineMatchService._();

  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  /// ペアさがし（同時レース／ターン制）のペア数。
  static const int levelPairs = 6;

  /// 🏆 ランクマッチの出演人数。ここは**固定**にする。
  /// 見知らぬ人同士が条件をそろえずに遊べることがランクマッチの意味なので、
  /// 人数を選ばせると「同じ設定の相手が見つからない」だけになる。
  static const int rankPeopleCount = 8;

  /// なまえがおのオンライン既定人数（フレンドマッチはここから変えられる）。
  static const int defaultOnlinePeople = 8;

  /// おぼえタイム(秒)。両端末で共通の締切を計算する。
  static int memorizeSecondsFor(String game, int people) =>
      switch (game) {
        // 早押しは全員ぶんを先に覚えてから始める（1人3秒）
        'rank' => people * 3,
        'turnpairs' => levelPairs * 3,
        'pairs' => levelPairs * 3,
        // なまえがおは「出たとき命名」なので事前のおぼえタイムは無い
        _ => 0,
      };

  /// スタートまでのバッファ(秒)。join書き込み〜両者の画面遷移のラグ吸収。
  static const int startBufferSeconds = 3;

  /// 🏆 早押し1問の持ち時間(秒)。誰も取れなければ次の問題へ。
  static const int rankAnswerSeconds = 8;

  /// 部屋の `mode` に使う接頭辞。ランダムマッチの検索キーになる。
  static String prefixOf(String game) => switch (game) {
        'namecall' => 'nc',
        'rank' => 'rk',
        'turnpairs' => 'tp',
        _ => 'race',
      };

  static String gameOfMode(String mode) {
    if (mode.startsWith('nc')) return 'namecall';
    if (mode.startsWith('rk')) return 'rank';
    if (mode.startsWith('tp')) return 'turnpairs';
    return 'pairs';
  }

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _fs.collection('rooms');

  Future<String> _ensureUid() async {
    User? user = FirebaseAuth.instance.currentUser;
    user ??= (await FirebaseAuth.instance.signInAnonymously()).user;
    return user!.uid;
  }

  String _newCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 紛らわしい文字を除外
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  /// 部屋を作って相手を待つ。ランダムマッチ用と合言葉用の共通処理。
  ///
  /// [people] は「何人おぼえるか」。ローカルのスライダーと同じ設定を
  /// **部屋に載せて相手にも配る**ので、フレンドマッチでは1台で遊ぶときと
  /// 同じルールで対戦できる。ランクマッチは [rankPeopleCount] に固定。
  Future<PendingRoom> createRoom({
    required bool random,
    required String nickname,
    String game = 'pairs',
    int? people,
  }) async {
    final uid = await _ensureUid();
    final code = _newCode();
    final doc = _rooms.doc(code);
    final prefix = prefixOf(game);
    final count = resolvePeople(game, people);
    await doc.set({
      'v2': true,
      'mode': random ? '${prefix}_random' : '${prefix}_friend',
      'status': 'waiting',
      'seed': Random.secure().nextInt(0x7FFFFFFF),
      'level': levelPairs,
      // 何人おぼえる部屋か。ホストの設定がそのままゲストにも配られる。
      'people': count,
      'players': [uid],
      'names': {uid: nickname},
      'progress': {uid: 0},
      'results': {},
      // 🏆 早押し用: いま何問目か / 各問を先取したのは誰か
      'cardIndex': 0,
      'claims': <String, dynamic>{},
      // 🔁 ターン制用: めくった順に積むだけ。両端末が再生して盤面を復元する
      'moves': <int>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return PendingRoom(roomId: code, myUid: uid, service: this);
  }

  /// 人数の正規化。ランクは固定、ペアさがし系はペア数固定。
  static int resolvePeople(String game, int? people) => switch (game) {
        'rank' => rankPeopleCount,
        'pairs' || 'turnpairs' => levelPairs,
        _ => (people ?? defaultOnlinePeople).clamp(2, 16),
      };

  /// ランダムマッチ: 待機中の部屋を探して入る。無ければ自分で作って待つ。
  ///
  /// なまえがおのランダムマッチは**人数がそろっている部屋だけ**に入る。
  /// 人数が違うと盤面がずれて勝負にならないため。
  Future<PendingRoom> findRandomMatch({
    required String nickname,
    String game = 'pairs',
    int? people,
  }) async {
    final uid = await _ensureUid();
    final prefix = prefixOf(game);
    final count = resolvePeople(game, people);
    final snap = await _rooms
        .where('v2', isEqualTo: true)
        .where('mode', isEqualTo: '${prefix}_random')
        .where('status', isEqualTo: 'waiting')
        .limit(8)
        .get();
    for (final d in snap.docs) {
      final data = d.data();
      final players = List<String>.from(data['players'] ?? []);
      if (players.contains(uid)) {
        // 自分が過去に作った待機部屋 → そのまま再利用
        return PendingRoom(roomId: d.id, myUid: uid, service: this);
      }
      // 人数の違う部屋には入らない（古い部屋は people を持たないので既定値扱い）
      final roomPeople = (data['people'] as num?)?.toInt() ?? defaultOnlinePeople;
      if (roomPeople != count) continue;
      final joined = await _tryJoin(d.id, uid, nickname);
      if (joined) {
        return PendingRoom(roomId: d.id, myUid: uid, service: this);
      }
    }
    return createRoom(
        random: true, nickname: nickname, game: game, people: count);
  }

  /// 合言葉で友だちの部屋に入る。成功したらPendingRoom、失敗はnull。
  Future<PendingRoom?> joinByCode({
    required String code,
    required String nickname,
  }) async {
    final uid = await _ensureUid();
    final id = code.trim().toUpperCase();
    final joined = await _tryJoin(id, uid, nickname);
    if (!joined) return null;
    return PendingRoom(roomId: id, myUid: uid, service: this);
  }

  /// トランザクションで2人目として入室し、対戦開始状態にする。
  Future<bool> _tryJoin(String roomId, String uid, String nickname) async {
    try {
      return await _fs.runTransaction<bool>((tx) async {
        final ref = _rooms.doc(roomId);
        final snap = await tx.get(ref);
        if (!snap.exists) return false;
        final data = snap.data()!;
        if (data['v2'] != true || data['status'] != 'waiting') return false;
        final players = List<String>.from(data['players'] ?? []);
        if (players.contains(uid)) return true; // 再入室
        if (players.length >= 2) return false;
        tx.update(ref, {
          'players': [...players, uid],
          'names.$uid': nickname,
          'progress.$uid': 0,
          'status': 'playing',
          'startedAt': FieldValue.serverTimestamp(),
        });
        return true;
      });
    } catch (e) {
      debugPrint('joinRoom failed: $e');
      return false;
    }
  }

  /// 待機を取りやめる（部屋は削除不可ルールのため abandoned にして放置）。
  Future<void> abandonWaiting(String roomId) async {
    try {
      await _rooms.doc(roomId).update({'status': 'abandoned'});
    } catch (_) {}
  }
}

/// 相手待ち中の部屋。ロビーが [snapshots] を監視し、
/// status=='playing' になったら [toSession] で対戦セッションを作る。
class PendingRoom {
  final String roomId;
  final String myUid;
  final OnlineMatchService service;

  PendingRoom({
    required this.roomId,
    required this.myUid,
    required this.service,
  });

  Stream<DocumentSnapshot<Map<String, dynamic>>> get snapshots =>
      service._rooms.doc(roomId).snapshots();

  Future<void> cancel() => service.abandonWaiting(roomId);

  /// status=='playing' のスナップショットから対戦セッションを構築する。
  OnlineMatchSession? toSession(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data();
    if (data == null || data['status'] != 'playing') return null;
    final startedAt = data['startedAt'];
    if (startedAt is! Timestamp) return null; // serverTimestamp解決待ち
    final players = List<String>.from(data['players'] ?? []);
    final opponentUid =
        players.firstWhere((p) => p != myUid, orElse: () => '');
    if (opponentUid.isEmpty) return null;
    final names = Map<String, dynamic>.from(data['names'] ?? {});
    final mode = (data['mode'] as String?) ?? 'race_random';
    final game = OnlineMatchService.gameOfMode(mode);
    return OnlineMatchSession(
      service: service,
      roomId: roomId,
      myUid: myUid,
      opponentUid: opponentUid,
      opponentName: (names[opponentUid] as String?) ?? 'Player',
      seed: (data['seed'] as num?)?.toInt() ?? 1,
      isRandomMatch: mode.endsWith('_random'),
      game: game,
      peopleCount: (data['people'] as num?)?.toInt() ??
          OnlineMatchService.resolvePeople(game, null),
      // 部屋を作った人が先手。playersの並び順がそのまま手番順になる。
      myPlayerIndex: players.contains(myUid) ? players.indexOf(myUid) : 0,
      startedAt: startedAt.toDate(),
    );
  }
}

/// 対戦1回ぶんのセッション。ゲーム画面が進捗を書き、相手の進捗を購読する。
class OnlineMatchSession {
  final OnlineMatchService service;
  final String roomId;
  final String myUid;
  final String opponentUid;
  final String opponentName;
  final int seed;
  final bool isRandomMatch;
  final String game; // 'pairs' | 'namecall' | 'rank' | 'turnpairs'

  /// 何人おぼえる部屋か（なまえがお＝出演人数、ペア系＝ペア数）。
  final int peopleCount;

  /// ターン制で自分が何番目の手番か（0=先手）。
  final int myPlayerIndex;

  final DateTime startedAt;

  final ValueNotifier<int> opponentProgress = ValueNotifier(0);
  final ValueNotifier<Map<String, dynamic>?> opponentResult =
      ValueNotifier(null);

  /// 🏆 早押し: いま何問目か（両端末で一致する）。
  final ValueNotifier<int> cardIndex = ValueNotifier(0);

  /// 🏆 早押し: 問題番号 → 先取した uid（誰も取れなければ 'none'）。
  final ValueNotifier<Map<String, String>> claims = ValueNotifier(const {});

  /// 🔁 ターン制: めくった順のカードindex。両端末がこれを再生して盤面を復元する。
  final ValueNotifier<List<int>> moves = ValueNotifier(const []);

  /// 🏆 早押し: おぼえタイムを終えて「準備できた」と宣言した人数。
  final ValueNotifier<int> readyCount = ValueNotifier(0);

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  OnlineMatchSession({
    required this.service,
    required this.roomId,
    required this.myUid,
    required this.opponentUid,
    required this.opponentName,
    required this.seed,
    required this.isRandomMatch,
    required this.startedAt,
    this.game = 'pairs',
    this.peopleCount = OnlineMatchService.levelPairs,
    this.myPlayerIndex = 0,
  }) {
    _sub = service._rooms.doc(roomId).snapshots().listen((snap) {
      final data = snap.data();
      if (data == null) return;
      final progress = Map<String, dynamic>.from(data['progress'] ?? {});
      opponentProgress.value = (progress[opponentUid] as num?)?.toInt() ?? 0;
      final results = Map<String, dynamic>.from(data['results'] ?? {});
      if (results[opponentUid] != null) {
        opponentResult.value =
            Map<String, dynamic>.from(results[opponentUid] as Map);
      }
      // ⚠️ claims を先に、cardIndex をあとに反映すること。
      //    リスナーは代入した瞬間に同期で走るので、逆にすると
      //    「次の問題へ進んだ」通知を受けた側がまだ古い claims を見ることになり、
      //    最後の1問の先取が得点に入らない。
      final rawClaims = Map<String, dynamic>.from(data['claims'] ?? {});
      claims.value = {
        for (final e in rawClaims.entries) e.key: '${e.value}',
      };
      cardIndex.value = (data['cardIndex'] as num?)?.toInt() ?? 0;
      moves.value = [
        for (final v in (data['moves'] as List<dynamic>? ?? const []))
          (v as num).toInt(),
      ];
      readyCount.value =
          Map<String, dynamic>.from(data['ready'] ?? {}).values.length;
    });
  }

  /// おぼえタイム終了（＝めくり／早押し解禁）時刻。両端末で同じ値になる。
  DateTime get playStartAt => startedAt.add(Duration(
      seconds: OnlineMatchService.startBufferSeconds +
          OnlineMatchService.memorizeSecondsFor(game, peopleCount)));

  Future<void> reportProgress(int pairs) async {
    try {
      await service._rooms.doc(roomId).update({'progress.$myUid': pairs});
    } catch (_) {}
  }

  Future<void> reportDone({
    required int attempts,
    required int ms,
    required int pairs,
  }) async {
    try {
      await service._rooms.doc(roomId).update({
        'results.$myUid': {'attempts': attempts, 'ms': ms, 'pairs': pairs},
      });
    } catch (_) {}
  }

  /// 途中離脱（相手の勝ち扱い）。
  Future<void> forfeit() async {
    try {
      await service._rooms.doc(roomId).update({
        'results.$myUid': {'forfeit': true},
      });
    } catch (_) {}
  }

  // ─────────────── 🏆 早押し（ランクマッチ） ───────────────

  /// おぼえタイムを終えたことを知らせる。
  ///
  /// おぼえタイムの締切は端末の時計から計算しているので、時計が数秒ずれて
  /// いると片方だけ先に第1問を見てしまう。早押しでそれは致命的なので、
  /// **両方の「準備できた」がそろってから**第1問を開始する。
  /// 2問目以降はFirestoreの更新（前の問題の決着）が合図になるので、
  /// 時計のずれの影響を受けるのは第1問だけ。
  Future<void> markReady() async {
    try {
      await service._rooms.doc(roomId).update({'ready.$myUid': true});
    } catch (_) {}
  }

  /// [index] 問目を先取する。**先にサーバーに届いた方だけ true**。
  ///
  /// 両者が同時に正解を押したときの決着をクライアント同士では決められない
  /// ので、部屋ドキュメントを唯一の審判にする。取れた／取られたの判定と
  /// 次の問題への繰り上げを1つのトランザクションでまとめて行う。
  Future<bool> claimCard(int index) => _settleCard(index, myUid);

  /// 誰も取れないまま時間切れ。どちらの端末から呼んでも結果は同じ。
  Future<void> passCard(int index) async {
    await _settleCard(index, 'none');
  }

  Future<bool> _settleCard(int index, String winner) async {
    try {
      return await service._fs.runTransaction<bool>((tx) async {
        final ref = service._rooms.doc(roomId);
        final snap = await tx.get(ref);
        final data = snap.data();
        if (data == null) return false;
        final current = Map<String, dynamic>.from(data['claims'] ?? {});
        if (current.containsKey('$index')) return false; // すでに決着済み
        tx.update(ref, {
          'claims.$index': winner,
          'cardIndex': index + 1,
        });
        return true;
      });
    } catch (e) {
      debugPrint('claimCard failed: $e');
      return false;
    }
  }

  // ─────────────── 🔁 ターン制 ───────────────

  /// カードをめくったことを記録する。
  ///
  /// [expectedLength] は「自分が知っている手の数」。ここが食い違うときは
  /// 相手の手がまだ届いていない＝盤面認識がずれているということなので、
  /// 書き込まずに false を返して見送る（二重反映の防止）。
  Future<bool> pushMove(int cardIndex, {required int expectedLength}) async {
    try {
      return await service._fs.runTransaction<bool>((tx) async {
        final ref = service._rooms.doc(roomId);
        final snap = await tx.get(ref);
        final data = snap.data();
        if (data == null) return false;
        final current = [
          for (final v in (data['moves'] as List<dynamic>? ?? const []))
            (v as num).toInt(),
        ];
        if (current.length != expectedLength) return false;
        tx.update(ref, {'moves': [...current, cardIndex]});
        return true;
      });
    } catch (e) {
      debugPrint('pushMove failed: $e');
      return false;
    }
  }

  void dispose() {
    _sub?.cancel();
    opponentProgress.dispose();
    opponentResult.dispose();
    cardIndex.dispose();
    claims.dispose();
    moves.dispose();
    readyCount.dispose();
  }
}
