import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../components/ad_mob.dart'; // AdMobクラスを別ファイルに
import 'result_screen.dart'; // 結果表示画面

// Google Cloud Functions と音声再生のためのインポートを追加
import 'package:cloud_functions/cloud_functions.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:convert'; // Base64デコードのために必要

// クリップボード機能のために追加
import 'package:flutter/services.dart';

class OnlineGameScreen extends StatefulWidget {
  final String roomId;
  final String myPlayerId; // 自身のプレイヤーIDを受け取る
  final bool isVoiceMode; // 通話モードかテキストモードか

  const OnlineGameScreen({
    Key? key,
    required this.roomId,
    required this.myPlayerId,
    this.isVoiceMode = true, // デフォルトは通話モード
  }) : super(key: key);

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  final AdMob _adMob = AdMob();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();
  final AudioPlayer _audioPlayer = AudioPlayer(); // AudioPlayer インスタンスを追加
  final AudioPlayer _bgmPlayer = AudioPlayer(); // BGM用のAudioPlayerを追加

  Stream<DocumentSnapshot>? _roomStream;

  String? _currentImagePath;
  bool _isFirstAppearance = true;
  bool _canSelectPlayer = false;
  int _turnCount = 0;
  // スコアはプレイヤーID（String）をキー、点数（int）を値とするマップで管理
  Map<String, int> _scores = {};
  List<String> _fieldCards = [];
  Set<String> _seenImages = {};

  // テキストモード用の状態変数
  final TextEditingController _nameInputController = TextEditingController();
  Map<String, String> _characterNames = {}; // 画像URL -> 名前 のマップ
  List<String> _choiceNames = []; // 選択肢の名前リスト
  bool _isLoadingChoices = false; // AIの名前生成中か
  List<String> _playerOrder = []; // プレイヤーが名前をつける順番
  int _currentPlayerIndex = 0; // 現在名前をつけるプレイヤーのインデックス
  Map<String, bool> _playersAttemptedCurrentCard = {}; // 現在のカードで回答済みのプレイヤーを記録

  @override
  void initState() {
    super.initState();
    _adMob.loadBanner();
    _roomStream = _firestore.collection('rooms').doc(widget.roomId).snapshots();

    _initializeOnlineGame();
    _startBGM(); // BGM再生を開始

    // ルームデータの変更を監視し、スコアの更新があった場合に実況をトリガー
    _roomStream!.listen(
      (DocumentSnapshot snapshot) {
        if (snapshot.exists) {
          final Map<String, dynamic> roomData =
              snapshot.data() as Map<String, dynamic>;
          final Map<String, int> newScores = Map<String, int>.from(
            roomData['scores'] ?? {},
          );

          // スコアが前回から変更されている場合にのみ実況（通話モードのみ）
          if (widget.isVoiceMode &&
              _scores.toString() != newScores.toString()) {
            _scores = newScores; // 内部状態を更新
            _announceGameStatus(newScores); // 実況を呼び出す
          }

          // ゲーム状態をロード
          _loadGameState(roomData);

          // テキストモードで、カードが既出になったタイミングで選択肢を生成
          // かつ、まだ選択肢が生成されておらず、AI生成中でない場合
          if (!widget.isVoiceMode &&
              !_isFirstAppearance &&
              _canSelectPlayer &&
              _choiceNames.isEmpty &&
              !_isLoadingChoices &&
              _currentImagePath != null &&
              _characterNames.containsKey(_currentImagePath!)) {
            _generateAndShowChoices(_characterNames[_currentImagePath!]!);
          }
        } else {
          // ドキュメントが存在しない（削除されたなど）場合の処理
          debugPrint('Room document does not exist.');
          // 例: Navigator.pop(context); などでロビーに戻す処理
        }
      },
      onError: (error) {
        // Stream.listen のエラーハンドリング
        debugPrint('Stream Listener Error: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('オンラインゲーム中にエラーが発生しました: ${error.toString()}')),
        );
      },
      onDone: () {
        // ストリームが終了した場合のコールバック（オプション）
        debugPrint('Stream is done.');
      },
      cancelOnError: false, // エラーが発生してもストリームをキャンセルしない
    );
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
      (data['players'] as List<dynamic>).forEach((playerId) {
        // playersリストから初期化
        initialScores[playerId] = 0;
      });

      // プレイヤーの順番をシャッフルして設定
      List<String> shuffledPlayerOrder = List<String>.from(
        data['players'] as List<dynamic>,
      )..shuffle(_random);

      // ゲーム状態をFirestoreに更新
      transaction.update(roomRef, {
        'status': 'playing', // ステータスを「プレイ中」に
        'deck': fullDeck,
        'scores': initialScores,
        'fieldCards': [],
        'seenImages': [],
        'characterNames': {}, // キャラクター名を保存するマップ
        'currentCard': null,
        'isFirstAppearance': true,
        'canSelectPlayer': false,
        'turnCount': 0,
        'gameStarted': true,
        'playerOrder': shuffledPlayerOrder, // プレイヤーの順番を保存
        'currentPlayerIndex': 0, // 最初のプレイヤーのインデックス
        'playersAttemptedCurrentCard': {}, // 現在のカードで回答済みのプレイヤーを記録
      });
    });

    // ゲーム開始後の最初のカードをめくる
    _drawNextCardOnline(roomRef);
  }

  /// Firestoreのデータからゲーム状態をロード
  void _loadGameState(Map<String, dynamic> data) {
    setState(() {
      _currentImagePath = data['currentCard'] as String?;
      _isFirstAppearance = data['isFirstAppearance'] as bool? ?? true;
      _canSelectPlayer = data['canSelectPlayer'] as bool? ?? false;
      _turnCount = data['turnCount'] as int? ?? 0;
      _fieldCards = List<String>.from(data['fieldCards'] ?? []);
      _seenImages = Set<String>.from(data['seenImages'] ?? []);
      _scores = Map<String, int>.from(data['scores'] ?? {});

      // テキストモード用: キャラクター名をロード
      _characterNames = Map<String, String>.from(data['characterNames'] ?? {});
      // _nameInputController.clear(); // 名前入力フィールドは常にクリアせず、自分のターンでUIからクリア
      // 選択肢もクリア（新しいカードがめくられた時やターンが変わった時）
      _choiceNames.clear();
      _isLoadingChoices = false; // ローディング状態をリセット

      // プレイヤーの順番と現在名前をつけるプレイヤーのインデックスをロード
      _playerOrder = List<String>.from(data['playerOrder'] ?? []);
      _currentPlayerIndex = data['currentPlayerIndex'] as int? ?? 0;
      _playersAttemptedCurrentCard = Map<String, bool>.from(
        data['playersAttemptedCurrentCard'] ?? {},
      );
    });
  }

  @override
  void dispose() {
    _adMob.disposeBanner();
    _audioPlayer.dispose(); // 実況用プレイヤーを解放
    _bgmPlayer.dispose(); // BGM用プレイヤーを解放
    _nameInputController.dispose(); // テキスト入力コントローラーの解放
    super.dispose();
  }

  // BGM再生用のメソッド
  Future<void> _startBGM() async {
    try {
      await _bgmPlayer.setAsset('assets/audio/for_siciliano.mp3'); // BGMファイルのパス
      _bgmPlayer.setLoopMode(LoopMode.one); // ループ再生
      _bgmPlayer.setVolume(0.5); // 音量を調整 (0.0 から 1.0)
      _bgmPlayer.play();
    } catch (e) {
      debugPrint("Error loading BGM: $e");
    }
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

      // 前のカードが場札にある場合、場札に追加
      if (previousCard != null) {
        fieldCards.add(previousCard);
      }

      String nextCard = deck.removeLast();
      turnCount++;

      // この画像が初めて出たかチェック
      bool isFirst = !seenImages.contains(nextCard);
      if (isFirst) {
        seenImages.add(nextCard); // 初めてなら記録
      }

      transaction.update(roomRef, {
        'deck': deck,
        'fieldCards': fieldCards,
        'seenImages': seenImages.toList(), // Firestoreに保存する際はListに戻す
        'currentCard': nextCard,
        'isFirstAppearance': isFirst,
        'canSelectPlayer': !isFirst, // 初登場でなければプレイヤー選択可能
        'turnCount': turnCount,
        'playersAttemptedCurrentCard': {}, // 新しいカードで回答済みプレイヤーをリセット
      });
    });
    // StreamListener がスコア変更を検知してUIを更新し、必要な実況や選択肢生成をトリガー
  }

  /// プレイヤーがポイントを獲得する処理（オンライン版）
  Future<void> _awardPointsOnline(
    DocumentReference roomRef,
    String playerKey,
  ) async {
    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot currentRoom = await transaction.get(roomRef);
      Map<String, dynamic> data = currentRoom.data() as Map<String, dynamic>;

      if (!(data['canSelectPlayer'] as bool? ?? false)) {
        return; // 既に誰かがポイントを獲得したか、まだ選択できない状態
      }

      List<dynamic> fieldCards = List<dynamic>.from(data['fieldCards'] ?? []);
      Map<String, dynamic> scores = Map<String, dynamic>.from(
        data['scores'] ?? {},
      );

      scores[playerKey] = (scores[playerKey] as int? ?? 0) + fieldCards.length;

      transaction.update(roomRef, {
        'scores': scores,
        'fieldCards': [],
        'canSelectPlayer': false, // 正解したので即座に選択不可
        'playersAttemptedCurrentCard': {}, // 正解が出たのでリセット
      });

      // 正解が出た場合は、すぐに次のカードへ進める
      Future.delayed(
        const Duration(milliseconds: 800),
        () => _drawNextCardOnline(roomRef),
      );
    });
    // トランザクション外の遅延呼び出しは、トランザクション内の処理が完了してから実行される
  }

  /// 「わからない」が選択された時の処理（オンライン版）
  Future<void> _skipCardOnline(DocumentReference roomRef) async {
    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot currentRoom = await transaction.get(roomRef);
      Map<String, dynamic> data = currentRoom.data() as Map<String, dynamic>;

      if (!(data['canSelectPlayer'] as bool? ?? false)) {
        return; // 既に誰かがポイントを獲得したか、まだ選択できない状態
      }

      Map<String, bool> playersAttempted = Map<String, bool>.from(
        data['playersAttemptedCurrentCard'] ?? {},
      );
      List<String> allPlayers = List<String>.from(data['players'] ?? []);

      // 自分をお手つき/スキップ済みとして記録
      playersAttempted[widget.myPlayerId] = true;

      // Firestoreを更新
      transaction.update(roomRef, {
        'playersAttemptedCurrentCard': playersAttempted, // 回答済みプレイヤーを更新
      });

      // 全員がお手つき/スキップ済みになったら次のカードへ進める
      if (playersAttempted.length >= allPlayers.length) {
        transaction.update(roomRef, {'canSelectPlayer': false}); // 全員回答済みなら選択不可
        Future.delayed(
          const Duration(milliseconds: 800),
          () => _drawNextCardOnline(roomRef),
        );
      } else {
        // まだ回答していないプレイヤーがいる場合は、カードはそのまま維持
        // canSelectPlayer は true のままなので、他のプレイヤーが引き続き操作できる
      }
    });
    // ここにFuture.delayedを入れると、上記のロジックと衝突する可能性があるので注意
    // 次のカードへ進むのはトランザクション内の条件分岐で制御する
  }

  // 通話モード専用: ゲーム状況をアナウンスするメソッド（Cloud Functions経由でTTSを呼び出す）
  Future<void> _announceGameStatus(Map<String, int> currentScores) async {
    if (!widget.isVoiceMode || !mounted) {
      // 通話モードでなければ実行しない、Widgetがdisposeされていないか確認
      debugPrint("Not in Voice Mode or Widget not mounted. Skipping TTS.");
      return;
    }

    String commentary;

    // ゲーム開始時の初期スコアが空のケースを考慮
    if (currentScores.isEmpty ||
        currentScores.values.every((score) => score == 0)) {
      commentary = "オンラインゲームを開始します！まだ誰もポイントを獲得していません！";
    } else {
      // スコアをプレイヤーIDでソートして表示順序を安定させる
      List<MapEntry<String, int>> sortedScores = currentScores.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key)); // プレイヤーIDでソート

      int maxScore = 0;
      List<String> leadingPlayerIds = [];

      for (var entry in sortedScores) {
        if (entry.value > maxScore) {
          maxScore = entry.value;
          leadingPlayerIds = [entry.key];
        } else if (entry.value == maxScore && entry.value > 0) {
          // 0点同士は同点リードとしない
          leadingPlayerIds.add(entry.key);
        }
      }

      if (leadingPlayerIds.length == 1) {
        String leadingPlayerAlias = leadingPlayerIds[0] == widget.myPlayerId
            ? "あなた"
            : "プレイヤー${sortedScores.indexWhere((e) => e.key == leadingPlayerIds[0]) + 1}";
        commentary = "${leadingPlayerAlias}が${maxScore}点でリードしています！";
      } else {
        List<String> leadingPlayerAliases = leadingPlayerIds.map((id) {
          return id == widget.myPlayerId
              ? "あなた"
              : "プレイヤー${sortedScores.indexWhere((e) => e.key == id) + 1}";
        }).toList();
        String players = leadingPlayerAliases.join("と");
        commentary = "${players}が${maxScore}点で同点リード中！激戦です！";
      }
    }
    _playTts(commentary); // 実況テキストをTTSで読み上げ
  }

  // 通話モード専用: Text-to-Speech API を呼び出し、音声を再生するヘルパーメソッド
  Future<void> _playTts(String text) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'synthesizeSpeech',
      );
      final HttpsCallableResult result = await callable.call({'text': text});
      final String audioBase64 = result.data['audioContent'];

      final audioBytes = base64Decode(audioBase64);
      await _audioPlayer.setAudioSource(
        AudioSource.uri(
          // Data URI schemeを使用
          Uri.parse('data:audio/mpeg;base64,${base64Encode(audioBytes)}'),
        ),
      );
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Cloud TTS 呼び出しまたは再生エラー: $e');
      // 例: エラー時はOS標準TTSにフォールバックすることも可能
    }
  }

  // テキストモード専用: 名前入力処理
  Future<void> _handleNameSubmission(String name) async {
    if (name.isEmpty || name.length > 8 || _currentImagePath == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('名前は1〜8文字で入力してください。')));
      return;
    }
    // Firestoreに名前を保存するトランザクション
    await _firestore.runTransaction((transaction) async {
      final roomRef = _firestore.collection('rooms').doc(widget.roomId);
      final roomSnap = await transaction.get(roomRef);
      final roomData = roomSnap.data() as Map<String, dynamic>;

      Map<String, String> currentNames = Map<String, String>.from(
        roomData['characterNames'] ?? {},
      );
      currentNames[_currentImagePath!] = name;

      // 次のプレイヤーに名前をつける順番を回す
      List<String> playerOrder = List<String>.from(
        roomData['playerOrder'] ?? [],
      );
      int currentPlayerIndex = roomData['currentPlayerIndex'] as int? ?? 0;

      int nextPlayerIndex = (currentPlayerIndex + 1) % playerOrder.length;
      // String nextNamerId = playerOrder[nextPlayerIndex]; // Firestoreにはインデックスのみ保存で十分

      transaction.update(roomRef, {
        'characterNames': currentNames,
        'currentPlayerIndex': nextPlayerIndex,
      });
    });

    _nameInputController.clear(); // 入力フィールドをクリア
    // 次のカードへ進む
    Future.delayed(const Duration(milliseconds: 800), () {
      _drawNextCardOnline(_firestore.collection('rooms').doc(widget.roomId));
    });
  }

  // テキストモード専用: AIによる名前生成と選択肢表示
  Future<void> _generateAndShowChoices(String correctName) async {
    setState(() {
      _isLoadingChoices = true;
      _choiceNames.clear(); // 新しい生成前にクリア
    });

    try {
      // 名前から文字種を推測
      String scriptType = _determineScriptType(correctName);

      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'generateSimilarNames',
      );
      final HttpsCallableResult result = await callable.call({
        'originalName': correctName,
        'scriptType': scriptType,
        'numToGenerate': 6, // 6つの似た名前を生成 (合計7択にするため)
      });

      List<String> generatedNames = List<String>.from(
        result.data['similarNames'] ?? [],
      );

      // 正解の名前とAIが生成した名前を混ぜて選択肢を作成
      List<String> choices = [correctName, ...generatedNames];

      // 同じ名前が複数入らないようにユニークにする
      choices = choices.toSet().toList();

      // 常に7択になるように調整（足りない場合はダミー追加、多すぎる場合は切り詰め）
      final List<String> dummyNames = [
        'モコ',
        'ピコ',
        'フワ',
        'ギザ',
        'ポム',
        'クルル',
        'ニャー',
        'ハニャ',
        'ワンダー',
        'ミラクル',
      ]; // ダミー名リスト
      int dummyIndex = 0;
      while (choices.length < 7) {
        final String currentDummy = dummyNames[dummyIndex % dummyNames.length];
        if (!choices.contains(currentDummy)) {
          // 重複を避けて追加
          choices.add(currentDummy);
        }
        dummyIndex++;
        if (dummyIndex > dummyNames.length * 2) break; // 無限ループ防止
      }

      if (choices.length > 7) {
        choices = choices.sublist(0, 7);
      }
      choices.shuffle(); // 最後にもう一度シャッフル

      setState(() {
        _choiceNames = choices;
        _isLoadingChoices = false;
      });
    } catch (e) {
      debugPrint('AI名前生成エラー: $e');
      setState(() {
        _isLoadingChoices = false;
        // エラー時はフォールバックとして、正解名といくつかのダミー名を混ぜる
        _choiceNames = [
          correctName,
          'AIエラー',
          '再試行',
          'スキップ',
          '？',
          '？？',
          '？？？',
        ].toList()..shuffle();
      });
    }
  }

  // 文字種を推測する簡易ヘルパー関数 (必要に応じて精密化)
  String _determineScriptType(String text) {
    if (text.contains(RegExp(r'[\u4e00-\u9faf]'))) {
      // 漢字
      return 'kanji';
    } else if (text.contains(RegExp(r'[\u3040-\u309F]'))) {
      // ひらがな
      return 'hiragana';
    } else if (text.contains(RegExp(r'[\u30A0-\u30FF]'))) {
      // カタカナ
      return 'katakana';
    } else if (text.contains(RegExp(r'[a-zA-Z]'))) {
      // 英字
      return 'english';
    }
    return 'other'; // その他
  }

  // テキストモード専用: 選択肢が選ばれた時の処理
  Future<void> _handleChoiceSelection(String selectedName) async {
    if (_currentImagePath == null) return;
    final correctName = _characterNames[_currentImagePath!];

    if (selectedName == correctName) {
      // 正解の場合、ポイントを付与
      await _awardPointsOnline(
        _firestore.collection('rooms').doc(widget.roomId),
        widget.myPlayerId,
      );
    } else {
      // 不正解の場合、自分をお手つき済みとして記録し、他のプレイヤーの回答を待つ
      await _skipCardOnline(_firestore.collection('rooms').doc(widget.roomId));
    }
    _choiceNames.clear(); // 選択肢をクリア
    // 次のカードへ進むのは _awardPointsOnline/_skipCardOnline の中で呼ばれる
  }

  @override
  Widget build(BuildContext context) {
    // 現在名前をつけるべきプレイヤーのIDを計算
    String? currentNamerId;
    if (_playerOrder.isNotEmpty &&
        _currentPlayerIndex >= 0 &&
        _currentPlayerIndex < _playerOrder.length) {
      currentNamerId = _playerOrder[_currentPlayerIndex];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('オンライン対戦 (ルーム: ${widget.roomId})'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _roomStream,
        builder: (context, snapshot) {
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
          _seenImages = Set<String>.from(roomData['seenImages'] ?? []);
          _characterNames = Map<String, String>.from(
            roomData['characterNames'] ?? {},
          ); // 最新の名前マップをロード
          _playerOrder = List<String>.from(
            roomData['playerOrder'] ?? [],
          ); // プレイヤー順をロード
          _currentPlayerIndex =
              roomData['currentPlayerIndex'] as int? ?? 0; // 現在のプレイヤーインデックスをロード
          _playersAttemptedCurrentCard = Map<String, bool>.from(
            roomData['playersAttemptedCurrentCard'] ?? {},
          ); // ロード処理

          // スコアマップを直接更新
          _scores = Map<String, int>.from(roomData['scores'] ?? {});

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
                    isOnline: true, // オンラインゲームであることをResultScreenに伝える
                    roomId: widget.roomId, // ルームIDをResultScreenに渡す
                    myPlayerId: widget.myPlayerId, // プレイヤーIDをResultScreenに渡す
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
                  // ルームIDの表示とコピーボタン
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ルームID: ${widget.roomId}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: widget.roomId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('ルームIDをコピーしました！')),
                          );
                        },
                        tooltip: 'ルームIDをコピー', // ホバー時のヒント
                      ),
                    ],
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
                          // 現在名前をつけるべきプレイヤーの表示を強調
                          bool isMyTurnToName =
                              !widget.isVoiceMode &&
                              _isFirstAppearance &&
                              playerId == currentNamerId &&
                              playerId == widget.myPlayerId;
                          return Chip(
                            avatar: CircleAvatar(
                              backgroundColor: widget.myPlayerId == playerId
                                  ? Colors
                                        .orange // 自分のチップの色
                                  : isMyTurnToName
                                  ? Colors.green
                                  : Colors.blue.shade800, // 名前付けターンなら緑色
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
                      // テキストモードで自分のターンなら、名前をつけるプレイヤーを表示
                      if (!widget.isVoiceMode &&
                          _isFirstAppearance &&
                          _playerOrder.isNotEmpty &&
                          currentNamerId != null)
                        Text(
                          '次は ${currentNamerId == widget.myPlayerId ? "あなたの番" : "プレイヤー${_playerOrder.indexOf(currentNamerId!) + 1}の番"} です',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.blueGrey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 20),

                      // --- 操作ボタンエリア (モードによって分岐) ---
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
    bool canAct = roomData['canSelectPlayer'] as bool? ?? false;
    // 現在名前をつけるべきプレイヤーのID
    String? currentNamerId;
    if (_playerOrder.isNotEmpty &&
        _currentPlayerIndex >= 0 &&
        _currentPlayerIndex < _playerOrder.length) {
      currentNamerId = _playerOrder[_currentPlayerIndex];
    }

    // 現在のプレイヤーが既にお手つき/スキップ済みか
    bool hasAttempted =
        _playersAttemptedCurrentCard.containsKey(widget.myPlayerId) &&
        _playersAttemptedCurrentCard[widget.myPlayerId] == true;

    // ★通話モードのボタン★
    if (widget.isVoiceMode) {
      if (canAct) {
        return Column(
          children: [
            ElevatedButton(
              onPressed: hasAttempted
                  ? null
                  : () => _awardPointsOnline(
                      _firestore.collection('rooms').doc(widget.roomId),
                      widget.myPlayerId,
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text(
                hasAttempted ? '回答済み' : 'GET!',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: hasAttempted
                  ? null
                  : () => _skipCardOnline(
                      _firestore.collection('rooms').doc(widget.roomId),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text(
                hasAttempted ? 'スキップ済み' : 'わからない',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      } else if (_currentImagePath != null &&
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
    }
    // ★テキストモードのボタン★
    else {
      // !widget.isVoiceMode (テキストモード)
      if (_isFirstAppearance && _currentImagePath != null) {
        // 初登場カードの場合：名前入力フィールドを表示
        // 自分の命名ターンかどうかもチェック
        if (widget.myPlayerId == currentNamerId) {
          return Column(
            children: [
              TextField(
                controller: _nameInputController,
                decoration: const InputDecoration(
                  labelText: 'キャラクター名 (8文字まで)',
                  border: OutlineInputBorder(),
                ),
                maxLength: 8, // 8文字制限
                onSubmitted: _handleNameSubmission, // エンターキーで送信
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () =>
                    _handleNameSubmission(_nameInputController.text.trim()),
                child: const Text('名前をつける'),
              ),
            ],
          );
        } else {
          // 自分のターンではない場合、名前付けは他のプレイヤー待ち
          return const Text(
            '他のプレイヤーが名前をつけています...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          );
        }
      } else if (!_isFirstAppearance && _currentImagePath != null && canAct) {
        // 既出カードで選択可能な場合：AI生成名前の7択ボタンを表示
        if (_isLoadingChoices) {
          return const CircularProgressIndicator(); // 名前生成中はローディング表示
        } else if (_choiceNames.isNotEmpty) {
          return Column(
            children: [
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                alignment: WrapAlignment.center,
                children: _choiceNames.map((name) {
                  return ElevatedButton(
                    onPressed: hasAttempted
                        ? null
                        : () => _handleChoiceSelection(name),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: Text(name),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: hasAttempted
                    ? null
                    : () => _skipCardOnline(
                        _firestore.collection('rooms').doc(widget.roomId),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  hasAttempted ? 'スキップ済み' : 'スキップ',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        }
      } else if (_currentImagePath != null &&
          (roomData['deck'] as List).isNotEmpty) {
        // それ以外の状態（名前入力後や選択後の次のカードへ進むボタン）
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
    }
    // ゲーム開始前や終了時（どちらのモードでも）
    return const SizedBox(height: 50);
  }
}
