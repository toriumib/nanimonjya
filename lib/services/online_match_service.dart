import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// 新ルール（顔と名前の神経衰弱）のオンライン対戦。
///
/// 方式は「同時レース」: 両者に同じseedを配布して同一の盤面を生成し、
/// それぞれが自分の端末で同時にプレイ。少ない手数（同数ならタイム）で
/// クリアした方が勝ち。ターン同期が不要なのでFirestoreの書き込みは
/// 進捗と最終結果だけで済み、旧ルールのようなカード送り同期は行わない。
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

  /// オンライン対戦は6ペア固定（マッチングを単純に保つため）。
  static const int levelPairs = 6;

  /// おぼえタイム(秒)。両端末で共通の締切を計算する。
  static const int memorizeSeconds = levelPairs * 3;

  /// スタートまでのバッファ(秒)。join書き込み〜両者の画面遷移のラグ吸収。
  static const int startBufferSeconds = 3;

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
  /// [game] は 'pairs'（神経衰弱レース）| 'namecall'（なまえコールレース）。
  Future<PendingRoom> createRoom({
    required bool random,
    required String nickname,
    String game = 'pairs',
  }) async {
    final uid = await _ensureUid();
    final code = _newCode();
    final doc = _rooms.doc(code);
    final prefix = game == 'namecall' ? 'nc' : 'race';
    await doc.set({
      'v2': true,
      'mode': random ? '${prefix}_random' : '${prefix}_friend',
      'status': 'waiting',
      'seed': Random.secure().nextInt(0x7FFFFFFF),
      'level': levelPairs,
      'players': [uid],
      'names': {uid: nickname},
      'progress': {uid: 0},
      'results': {},
      'createdAt': FieldValue.serverTimestamp(),
    });
    return PendingRoom(roomId: code, myUid: uid, service: this);
  }

  /// ランダムマッチ: 待機中の部屋を探して入る。無ければ自分で作って待つ。
  Future<PendingRoom> findRandomMatch({
    required String nickname,
    String game = 'pairs',
  }) async {
    final uid = await _ensureUid();
    final prefix = game == 'namecall' ? 'nc' : 'race';
    final snap = await _rooms
        .where('v2', isEqualTo: true)
        .where('mode', isEqualTo: '${prefix}_random')
        .where('status', isEqualTo: 'waiting')
        .limit(5)
        .get();
    for (final d in snap.docs) {
      final players = List<String>.from(d.data()['players'] ?? []);
      if (players.contains(uid)) {
        // 自分が過去に作った待機部屋 → そのまま再利用
        return PendingRoom(roomId: d.id, myUid: uid, service: this);
      }
      final joined = await _tryJoin(d.id, uid, nickname);
      if (joined) {
        return PendingRoom(roomId: d.id, myUid: uid, service: this);
      }
    }
    return createRoom(random: true, nickname: nickname, game: game);
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
    return OnlineMatchSession(
      service: service,
      roomId: roomId,
      myUid: myUid,
      opponentUid: opponentUid,
      opponentName: (names[opponentUid] as String?) ?? 'Player',
      seed: (data['seed'] as num?)?.toInt() ?? 1,
      isRandomMatch: mode.endsWith('_random'),
      game: mode.startsWith('nc') ? 'namecall' : 'pairs',
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
  final String game; // 'pairs' | 'namecall'
  final DateTime startedAt;

  final ValueNotifier<int> opponentProgress = ValueNotifier(0);
  final ValueNotifier<Map<String, dynamic>?> opponentResult =
      ValueNotifier(null);

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
    });
  }

  /// おぼえタイム終了（＝めくり解禁）時刻。両端末で同じ値になる。
  DateTime get playStartAt => startedAt.add(Duration(
      seconds:
          OnlineMatchService.startBufferSeconds +
          OnlineMatchService.memorizeSeconds));

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

  void dispose() {
    _sub?.cancel();
    opponentProgress.dispose();
    opponentResult.dispose();
  }
}
