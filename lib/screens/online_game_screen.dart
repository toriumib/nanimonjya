import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../components/ad_mob.dart'; // AdMobクラスを別ファイルに
import 'result_screen.dart'; // 結果表示画面

class OnlineGameScreen extends StatefulWidget {
  final String roomId;
  final String myPlayerId; // 自身のプレイヤーIDを受け取る

  const OnlineGameScreen({
    Key? key,
    required this.roomId,
    required this.myPlayerId,
  }) : super(key: key);

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  final AdMob _adMob = AdMob();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  Stream<DocumentSnapshot>? _roomStream;

  String? _currentImagePath;
  bool _isFirstAppearance = true;
  bool _canSelectPlayer = false;
  int _turnCount = 0;
  // スコアはプレイヤーID（String）をキー、点数（int）を値とするマップで管理
  Map<String, int> _scores = {};
  List<String> _fieldCards = [];
  Set<String> _seenImages = {};

  @override
  void initState() {
    super.initState();
    _adMob.loadBanner();
    _roomStream = _firestore.collection('rooms').doc(widget.roomId).snapshots();
    _initializeOnlineGame();
  }

  /// ゲームの初期化とプレイヤーの参加処理
  Future<void> _initializeOnlineGame() async {
    DocumentReference roomRef = _firestore
        .collection('rooms')
        .doc(widget.roomId);
    DocumentSnapshot roomSnapshot = await roomRef.get();

    if (roomSnapshot.exists) {
      Map<String, dynamic> data = roomSnapshot.data() as Map<String, dynamic>;

      // ルームに自分のプレイヤーIDが存在しない場合（新規参加など）は追加
      final Map<String, dynamic> initialScoresCheck =
          data['scores'] as Map<String, dynamic>? ?? {};
      if (!initialScoresCheck.containsKey(widget.myPlayerId)) {
        await _firestore.runTransaction((transaction) async {
          DocumentSnapshot freshSnap = await transaction.get(roomRef);
          final Map<String, dynamic> roomDataFromTransaction =
              freshSnap.data() as Map<String, dynamic>? ?? {};

          Map<String, dynamic> currentScores = Map<String, dynamic>.from(
            roomDataFromTransaction['scores'] as Map<String, dynamic>? ?? {},
          );
          currentScores[widget.myPlayerId] = 0; // 自分のスコアを0で追加

          List<dynamic> playersList = List.from(
            roomDataFromTransaction['players'] ?? [],
          );
          if (!playersList.contains(widget.myPlayerId)) {
            playersList.add(widget.myPlayerId); // プレイヤーリストにも追加
          }

          transaction.update(roomRef, {
            'scores': currentScores,
            'players': playersList,
          });
        });
      }

      // ゲーム状態をロード
      _loadGameState(data);
    }
  }

  /// ゲーム開始処理
  /// プレイヤーが「ゲーム開始」ボタンを押した際に呼び出されます。
  Future<void> _startGameOnline(DocumentReference roomRef) async {
    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot currentRoom = await transaction.get(roomRef);
      Map<String, dynamic> data = currentRoom.data() as Map<String, dynamic>;

      // 既にゲームが始まっている場合は何もしない
      if (data['status'] == 'playing') {
        return;
      }

      List<dynamic> imageUrls = data['imageUrls'] as List<dynamic>;
      List<String> fullDeck = [];
      for (String url in imageUrls.cast<String>()) {
        for (int i = 0; i < 5; i++) {
          fullDeck.add(url);
        }
      }
      fullDeck.shuffle(_random); // デッキをシャッフル

      // 参加しているプレイヤー全員のスコアを初期化（既存スコアをリセット）
      Map<String, dynamic> initialScores = {};
      (data['scores'] as Map<String, dynamic>).keys.forEach((playerId) {
        initialScores[playerId] = 0;
      });

      // ゲーム状態をFirestoreに更新
      transaction.update(roomRef, {
        'status': 'playing', // ステータスを「プレイ中」に
        'deck': fullDeck,
        'scores': initialScores,
        'fieldCards': [],
        'seenImages': [],
        'currentCard': null,
        'isFirstAppearance': true,
        'canSelectPlayer': false,
        'turnCount': 0,
        'gameStarted': true,
      });
    });

    // ゲーム開始後の最初のカードをめくる
    _drawNextCardOnline(roomRef);
  }

  /// Firestoreのデータからゲーム状態をロード
  void _loadGameState(Map<String, dynamic> data) {
    setState(() {
      _currentImagePath = data['currentCard'] as String?;
      _isFirstAppearance = data['isFirstAppearance'] as bool;
      _canSelectPlayer = data['canSelectPlayer'] as bool;
      _turnCount = data['turnCount'] as int;
      _fieldCards = List<String>.from(data['fieldCards'] ?? []);
      _seenImages = Set<String>.from(data['seenImages'] ?? []);

      // スコアマップを直接更新
      _scores = Map<String, int>.from(data['scores'] ?? {});
    });
  }

  @override
  void dispose() {
    _adMob.disposeBanner();
    super.dispose();
  }

  /// カードをめくる処理（オンライン版）
  Future<void> _drawNextCardOnline(DocumentReference roomRef) async {
    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot currentRoom = await transaction.get(roomRef);
      Map<String, dynamic> data = currentRoom.data() as Map<String, dynamic>;

      List<dynamic> deck = List<dynamic>.from(data['deck'] ?? []);
      List<dynamic> fieldCards = List<dynamic>.from(data['fieldCards'] ?? []);
      Set<String> seenImages = Set<String>.from(data['seenImages'] ?? []);
      int turnCount = data['turnCount'] as int;
      String? previousCard = data['currentCard'] as String?;

      if (deck.isEmpty) {
        transaction.update(roomRef, {'status': 'finished'});
        return;
      }

      if (previousCard != null) {
        fieldCards.add(previousCard);
      }

      String nextCard = deck.removeLast();
      turnCount++;

      bool isFirst = !seenImages.contains(nextCard);
      if (isFirst) {
        seenImages.add(nextCard);
      }

      transaction.update(roomRef, {
        'deck': deck,
        'fieldCards': fieldCards,
        'seenImages': seenImages.toList(),
        'currentCard': nextCard,
        'isFirstAppearance': isFirst,
        'canSelectPlayer': !isFirst,
        'turnCount': turnCount,
      });
    });
  }

  /// プレイヤーがポイントを獲得する処理（オンライン版）
  Future<void> _awardPointsOnline(
    DocumentReference roomRef,
    String playerKey,
  ) async {
    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot currentRoom = await transaction.get(roomRef);
      Map<String, dynamic> data = currentRoom.data() as Map<String, dynamic>;

      if (!(data['canSelectPlayer'] as bool)) {
        return; // 既に誰かがポイントを獲得したか、まだ選択できない状態
      }

      List<dynamic> fieldCards = List<dynamic>.from(data['fieldCards'] ?? []);
      Map<String, dynamic> scores = Map<String, dynamic>.from(
        data['scores'] ?? {},
      );

      // 自分のスコアを更新
      scores[playerKey] = (scores[playerKey] as int? ?? 0) + fieldCards.length;

      transaction.update(roomRef, {
        'scores': scores,
        'fieldCards': [],
        'canSelectPlayer': false,
      });

      Future.delayed(
        const Duration(milliseconds: 800),
        () => _drawNextCardOnline(roomRef),
      );
    });
  }

  /// 「わからない」が選択された時の処理（オンライン版）
  Future<void> _skipCardOnline(DocumentReference roomRef) async {
    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot currentRoom = await transaction.get(roomRef);
      Map<String, dynamic> data = currentRoom.data() as Map<String, dynamic>;

      if (!(data['canSelectPlayer'] as bool)) {
        return; // 既に誰かがポイントを獲得したか、まだ選択できない状態
      }

      transaction.update(roomRef, {'canSelectPlayer': false});
    });
    Future.delayed(
      const Duration(milliseconds: 800),
      () => _drawNextCardOnline(roomRef),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('オンライン対戦 (ルーム: ${widget.roomId})'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _roomStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('エラー: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('ルームが見つかりません。'));
          }

          Map<String, dynamic> roomData =
              snapshot.data!.data() as Map<String, dynamic>;
          _currentImagePath = roomData['currentCard'] as String?;
          _isFirstAppearance = roomData['isFirstAppearance'] as bool? ?? true;
          _canSelectPlayer = roomData['canSelectPlayer'] as bool? ?? false;
          _turnCount = roomData['turnCount'] as int? ?? 0;
          _fieldCards = List<String>.from(roomData['fieldCards'] ?? []);
          _scores = Map<String, int>.from(
            roomData['scores'] ?? {},
          ); // マップとして読み込む

          // スコアをプレイヤーIDでソートして表示順序を安定させる
          List<MapEntry<String, int>> sortedScores = _scores.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));

          // ゲーム終了判定
          if (roomData['status'] == 'finished') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // 結果画面へ渡すスコアをList<int>形式に変換
              List<int> resultScores = sortedScores
                  .map((e) => e.value)
                  .toList();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ResultScreen(
                    scores: resultScores,
                    playerCount: sortedScores.length, // 実際のプレイヤー数
                  ),
                ),
              );
            });
            return const SizedBox.shrink(); // 遷移中は何も表示しない
          }

          // ゲームがまだ開始されていない場合（waiting状態）の表示
          if (roomData['status'] == 'waiting') {
            int currentPlayersCount =
                (roomData['players'] as List<dynamic>).length;
            bool canStartGame = currentPlayersCount >= 2;

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    '他のプレイヤーを待っています... ($currentPlayersCount / 最大6人)',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'ルームID: ${widget.roomId}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'このルームIDを他のプレイヤーに教えてください。',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: canStartGame
                        ? () => _startGameOnline(
                            _firestore.collection('rooms').doc(widget.roomId),
                          )
                        : null, // 2人未満の場合は無効
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      textStyle: const TextStyle(fontSize: 20),
                      backgroundColor: canStartGame ? Colors.blue : Colors.grey,
                    ),
                    child: Text(
                      canStartGame
                          ? 'ゲーム開始'
                          : 'プレイヤーが足りません (${currentPlayersCount}/2)',
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // ロビーに戻る
                    },
                    child: const Text('ロビーに戻る'),
                  ),
                ],
              ),
            );
          }

          // ゲームプレイ中のUI
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      // --- スコア表示 ---
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        alignment: WrapAlignment.center,
                        children: sortedScores.map((entry) {
                          String playerId = entry.key;
                          int score = entry.value;
                          return Chip(
                            avatar: CircleAvatar(
                              backgroundColor: widget.myPlayerId == playerId
                                  ? Colors.orange
                                  : Colors.blue.shade800,
                              child: Text(
                                playerId.split('_').last, // IDの最後の部分を表示
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            label: Text(
                              '${widget.myPlayerId == playerId ? "あなた" : "P${sortedScores.indexOf(entry) + 1}"}: $score 点',
                              style: const TextStyle(fontSize: 16),
                            ),
                            elevation: 2,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),

                      // --- 場札表示 ---
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '現在の場札: ${_fieldCards.length} 枚',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- カード（画像）表示エリア ---
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.35,
                        ),
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade400,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: _currentImagePath == null
                                ? Center(
                                    child: (roomData['deck'] as List).isNotEmpty
                                        ? const CircularProgressIndicator()
                                        : const Text(
                                            'ゲーム終了',
                                            style: TextStyle(fontSize: 18),
                                          ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(10.0),
                                    child:
                                        _currentImagePath!.startsWith('assets/')
                                        ? Image.asset(
                                            // assets/ なら Image.asset
                                            _currentImagePath!,
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Center(
                                                      child: Icon(
                                                        Icons.error_outline,
                                                        color: Colors.red,
                                                        size: 50,
                                                      ),
                                                    ),
                                          )
                                        : Image.network(
                                            // それ以外なら Image.network
                                            _currentImagePath!,
                                            fit: BoxFit.contain,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  value:
                                                      loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                                .cumulativeBytesLoaded /
                                                            loadingProgress
                                                                .expectedTotalBytes!
                                                      : null,
                                                ),
                                              );
                                            },
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Center(
                                                      child: Icon(
                                                        Icons.error_outline,
                                                        color: Colors.red,
                                                        size: 50,
                                                      ),
                                                    ),
                                          ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // --- メッセージ表示 ---
                      SizedBox(
                        height: 40,
                        child: _currentImagePath == null
                            ? const SizedBox.shrink()
                            : Text(
                                _isFirstAppearance
                                    ? '初登場！名前をつけて！'
                                    : '見たことある！名前は？',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _isFirstAppearance
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                      ),
                      const SizedBox(height: 20),

                      // --- 操作ボタンエリア ---
                      _buildActionButtonsOnline(roomData),
                    ],
                  ),
                ),
              ),

              // --- AdMob バナー広告 ---
              Container(
                alignment: Alignment.center,
                width: double.infinity,
                height: _adMob.getAdBannerHeight(),
                child: _adMob.getAdBannerWidget(),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 操作ボタン（オンライン版）を生成するメソッド
  Widget _buildActionButtonsOnline(Map<String, dynamic> roomData) {
    bool canAct = roomData['canSelectPlayer'] as bool? ?? false; // null許容に
    Map<String, dynamic> rawScores = roomData['scores'] ?? {};
    List<String> playerIds = rawScores.keys.toList()
      ..sort(); // プレイヤーIDをソートして表示順序を固定

    // プレイヤー選択が可能な状態の場合 (見たことあるカードが出た場合)
    if (canAct) {
      return Column(
        children: [
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            alignment: WrapAlignment.center,
            children: playerIds.map((playerId) {
              return ElevatedButton(
                onPressed: () => _awardPointsOnline(
                  _firestore.collection('rooms').doc(widget.roomId),
                  playerId,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.myPlayerId == playerId
                      ? Colors.red.shade700
                      : Colors.redAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  '${widget.myPlayerId == playerId ? "あなた" : playerId.split('_').last} GET!',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // 「わからない」ボタンを追加
          ElevatedButton(
            onPressed: () => _skipCardOnline(
              _firestore.collection('rooms').doc(widget.roomId),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('わからない', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    }
    // 初登場カードの後 or ポイント獲得後 (または「わからない」選択後)
    else if (_currentImagePath != null &&
        (roomData['deck'] as List).isNotEmpty) {
      return ElevatedButton.icon(
        onPressed: () => _drawNextCardOnline(
          _firestore.collection('rooms').doc(widget.roomId),
        ),
        icon: const Icon(Icons.navigate_next),
        label: const Text('次のカードをめくる'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          textStyle: const TextStyle(fontSize: 16),
        ),
      );
    }
    // ゲーム開始前や終了時
    else {
      return const SizedBox(height: 50);
    }
  }
}
