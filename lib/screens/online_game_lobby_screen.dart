import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuthをインポート
import '../services/player_profile.dart'; // 選択中BGMの参照
import 'package:just_audio/just_audio.dart'; // BGMのために追加
import '../l10n/meta_strings.dart'; // ランダムマッチ用の文言

import 'online_game_screen.dart'; // オンラインゲーム本体の画面
import 'top_screen.dart'; // Top画面に戻るため追加

// 多言語対応のために追加
import 'package:untitled/l10n/app_localizations.dart'; // プロジェクトの実際のパスに合わせてください

class OnlineGameLobbyScreen extends StatefulWidget {
  const OnlineGameLobbyScreen({super.key});

  @override
  State<OnlineGameLobbyScreen> createState() => _OnlineGameLobbyScreenState();
}

class _OnlineGameLobbyScreenState extends State<OnlineGameLobbyScreen> {
  final TextEditingController _roomIdController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  final AudioPlayer _bgmPlayer = AudioPlayer(); // BGM用のAudioPlayerを追加

  final List<String> _defaultCharacterImageFiles = List.generate(
    12,
    (index) => 'assets/images/char${index + 1}.jpg',
  );

  bool _isVoiceMode = false; // デフォルトをテキストモード (false) に変更
  bool _isMatching = false; // ランダムマッチの検索中か

  @override
  void initState() {
    super.initState();
    _startBGM(); // BGM再生を開始
  }

  @override
  void dispose() {
    _roomIdController.dispose();
    _bgmPlayer.dispose(); // BGM用プレイヤーを解放
    super.dispose();
  }

  // BGM再生用のメソッド
  Future<void> _startBGM() async {
    try {
      await _bgmPlayer.setAsset(
        'assets/audio/${PlayerProfile.instance.selectedBgm}',
      ); // 選択中のBGMを再生
      _bgmPlayer.setLoopMode(LoopMode.one); // ループ再生
      _bgmPlayer.setVolume(0.5); // 音量を調整 (0.0 から 1.0)
      _bgmPlayer.play();
    } catch (e) {
      debugPrint("Error loading BGM: $e");
    }
  }

  /// ★ランダムマッチ★
  /// 募集中のランダムマッチ部屋を探して参加する。見つからなければ
  /// 自分で部屋を作って待機する（2人揃うとゲーム画面側が自動開始する）。
  Future<void> _findRandomMatch() async {
    final m = MetaStrings.of(context);
    setState(() => _isMatching = true);
    try {
      // 匿名認証でサインイン
      User? user = FirebaseAuth.instance.currentUser;
      user ??= (await FirebaseAuth.instance.signInAnonymously()).user;
      if (user == null) {
        throw Exception('認証に失敗しました。');
      }
      final String myPlayerId = user.uid;

      // 募集中のランダムマッチ部屋を検索（等価条件のみなので複合インデックス不要）
      final QuerySnapshot<Map<String, dynamic>> candidates = await _firestore
          .collection('rooms')
          .where('isRandomMatch', isEqualTo: true)
          .where('status', isEqualTo: 'waiting')
          .limit(10)
          .get();

      final now = DateTime.now();
      String? joinedRoomId;
      for (final doc in candidates.docs) {
        final data = doc.data();
        // 作成から30分以上経った放置部屋はスキップ
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        if (createdAt == null ||
            now.difference(createdAt) > const Duration(minutes: 30)) {
          continue;
        }
        final players = List<String>.from(data['players'] ?? []);
        if (players.contains(myPlayerId)) {
          joinedRoomId = doc.id; // 自分が作った待機部屋に再入室
          break;
        }
        if (players.length >= 6) continue;

        // トランザクションで参加（同時参加の競合は再検証ではじく）
        try {
          await _firestore.runTransaction((transaction) async {
            final fresh = await transaction.get(doc.reference);
            if (!fresh.exists) throw Exception('room gone');
            final freshData = fresh.data() as Map<String, dynamic>;
            if (freshData['status'] != 'waiting') throw Exception('started');
            final freshPlayers =
                List<String>.from(freshData['players'] ?? []);
            if (freshPlayers.length >= 6) throw Exception('full');
            if (!freshPlayers.contains(myPlayerId)) {
              freshPlayers.add(myPlayerId);
              final scores = Map<String, dynamic>.from(
                freshData['scores'] ?? {},
              );
              scores[myPlayerId] = 0;
              transaction.update(doc.reference, {
                'players': freshPlayers,
                'scores': scores,
              });
            }
          });
          joinedRoomId = doc.id;
          break;
        } catch (_) {
          continue; // この部屋はダメだった → 次の候補へ
        }
      }

      // 空き部屋が無ければ自分で作って待つ
      joinedRoomId ??= await _createRandomRoom(myPlayerId);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OnlineGameScreen(
            roomId: joinedRoomId!,
            myPlayerId: myPlayerId,
            isVoiceMode: false, // ランダムマッチはテキストモード固定
          ),
        ),
      );
    } catch (e) {
      debugPrint('ランダムマッチに失敗しました: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${m.matchmakingFailed}: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isMatching = false);
    }
  }

  /// ランダムマッチ用の部屋を作成する。
  /// 知らない人同士なのでテキストモード固定＆デフォルト画像を使用。
  Future<String> _createRandomRoom(String myPlayerId) async {
    final String roomId = _uuid.v4().substring(0, 6).toUpperCase();
    await _firestore.collection('rooms').doc(roomId).set({
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'waiting',
      'players': [myPlayerId],
      'imageUrls': _defaultCharacterImageFiles,
      'deck': [],
      'fieldCards': [],
      'seenImages': [],
      'scores': {myPlayerId: 0},
      'currentCard': null,
      'isFirstAppearance': true,
      'canSelectPlayer': false,
      'turnCount': 0,
      'gameStarted': false,
      'gameMode': 'text',
      'characterNames': {},
      'playerOrder': [],
      'currentPlayerIndex': 0,
      'readyPlayerIds': [],
      'isRandomMatch': true, // マッチング検索の対象になるフラグ
    });
    return roomId;
  }

  /// 新しいルームを作成し、そのルームに参加します。
  /// カード画像はアプリ内蔵のデフォルト画像を使用します。
  /// （カスタム画像アップロード機能はStorage課金対策のため廃止）
  Future<void> _createRoom() async {
    final localizations = AppLocalizations.of(context)!;

    final String roomId = _uuid.v4().substring(0, 6).toUpperCase();

    final List<String> finalImageUrls = _defaultCharacterImageFiles;

    try {
      // 匿名認証でサインインを試みる
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        user = (await FirebaseAuth.instance.signInAnonymously()).user;
        if (user == null) {
          throw Exception('認証に失敗しました。'); // ローカライズが必要な場合は追加
        }
      }
      final String myPlayerId = user.uid; // Firebase AuthenticationのUIDを使用

      // ルームの初期状態をFirestoreに設定
      await _firestore.collection('rooms').doc(roomId).set({
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'waiting', // 初期状態は'waiting'
        'players': [myPlayerId], // 作成者を最初のプレイヤーとして追加
        'imageUrls': finalImageUrls, // 使用する画像URL/パスリスト
        'deck': [], // ゲーム開始時にシャッフルされたデッキ
        'fieldCards': [], // 場札
        'seenImages': [], // 見たことのある画像
        'scores': {myPlayerId: 0}, // 作成者の初期スコアを設定
        'currentCard': null, // 現在表示中のカード
        'isFirstAppearance': true,
        'canSelectPlayer': false,
        'turnCount': 0,
        'gameStarted': false, // ゲームが開始されたかどうかのフラグ
        'gameMode': _isVoiceMode ? 'voice' : 'text', // ゲームモードを保存
        'characterNames': {}, // キャラクター名を保存するマップ
        'playerOrder': [], // ターン順序を保存するリスト
        'currentPlayerIndex': 0, // 現在のターンプレイヤーのインデックス
        'readyPlayerIds': [], // 準備完了プレイヤーのIDリスト
      });

      // 作成後、自動的にゲーム画面へ遷移
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OnlineGameScreen(
            roomId: roomId,
            myPlayerId: myPlayerId,
            isVoiceMode: _isVoiceMode,
          ), // ゲームモードを渡す
        ),
      );
    } catch (e) {
      debugPrint('ルームの作成に失敗しました: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.errorCreatingRoom(e.toString()))),
      );
    }
  }

  /// 既存のルームに合言葉で参加します。
  /// ルームが存在し、かつ満員でない場合にのみ参加を許可します。
  Future<void> _joinRoom(String roomId) async {
    final localizations = AppLocalizations.of(context)!;

    DocumentReference roomRef = _firestore.collection('rooms').doc(roomId);

    try {
      // 匿名認証でサインインを試みる
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        user = (await FirebaseAuth.instance.signInAnonymously()).user;
        if (user == null) {
          throw Exception('認証に失敗しました。'); // ローカライズが必要な場合は追加
        }
      }
      final String myPlayerId = user.uid; // Firebase AuthenticationのUIDを使用

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot freshSnap = await transaction.get(roomRef);

        if (!freshSnap.exists) {
          throw Exception(localizations.roomNotFoundForPasscode);
        }

        Map<String, dynamic> roomData =
            freshSnap.data() as Map<String, dynamic>;
        List<dynamic> players = roomData['players'] ?? [];

        if (players.length >= 6) {
          throw Exception(localizations.roomFull);
        }
        if (roomData['status'] == 'playing') {
          throw Exception(localizations.roomInGame);
        }

        // 既にこのIDが参加者リストにあるかチェック（同一デバイスからの再接続など）
        if (players.contains(myPlayerId)) {
          debugPrint('既にこのプレイヤーはルームに参加しています。');
        } else {
          players.add(myPlayerId);
          Map<String, dynamic> scores = roomData['scores'] ?? {};
          scores[myPlayerId] = 0;

          transaction.update(roomRef, {'players': players, 'scores': scores});
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OnlineGameScreen(
              roomId: roomId,
              myPlayerId: myPlayerId,
              isVoiceMode: roomData['gameMode'] == 'voice', // ルームのゲームモードを渡す
            ),
          ),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.errorJoiningRoom(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.roomLobby),
        leading: IconButton(
          icon: const Icon(Icons.home), // ホームアイコン
          onPressed: () {
            // トップ画面に戻る (他の画面スタックを全てクリア)
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const TopScreen()),
              (Route<dynamic> route) => false,
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // ★ランダムマッチ（世界のだれかとすぐ対戦）★
            ElevatedButton.icon(
              onPressed: _isMatching ? null : _findRandomMatch,
              icon: _isMatching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('🎲', style: TextStyle(fontSize: 20)),
              label: Text(
                _isMatching
                    ? MetaStrings.of(context).matching
                    : MetaStrings.of(context).randomMatch,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              MetaStrings.of(context).randomMatchDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    MetaStrings.of(context).orPlayWithFriends,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 20),

            // ゲームモード選択トグル
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(localizations.textMode),
                Switch(
                  value: _isVoiceMode,
                  onChanged: (bool newValue) {
                    setState(() {
                      _isVoiceMode = newValue;
                    });
                  },
                ),
                Text(localizations.voiceMode),
              ],
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _createRoom,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
                backgroundColor: Colors.green,
              ),
              child: Text(localizations.createRoom),
            ),
            const SizedBox(height: 40),

            Text(
              localizations.joinExistingRoom,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _roomIdController,
              decoration: InputDecoration(
                labelText: localizations.enterPasscode,
                border: const OutlineInputBorder(),
                hintText: '例: ABCDEF',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _joinRoom(_roomIdController.text.trim()),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: Text(localizations.joinRoom),
            ),
          ],
        ),
      ),
    );
  }
}
