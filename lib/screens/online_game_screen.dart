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

// 多言語対応のために追加
import 'package:untitled/l10n/app_localizations.dart';

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

  // 表示遅延制御用のタイムスタンプ
  DateTime? _displayDelayCompleteTimestamp;
  // 最後に名前がつけられたキャラの情報 (Firestoreからロード)
  Map<String, dynamic>? _lastNamedCharacterData;

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

          // ★表示遅延後のカード遷移を制御するロジックをより堅牢に★
          if (_displayDelayCompleteTimestamp != null &&
              _lastNamedCharacterData != null) {
            final now = DateTime.now().toUtc();
            final expectedCompletionTime = _displayDelayCompleteTimestamp!.add(
              const Duration(seconds: 2),
            ); // 2秒の表示遅延

            // カードを進める責任を持つプレイヤーかをチェック
            final String? currentNamerId =
                (_playerOrder.isNotEmpty &&
                    _currentPlayerIndex >= 0 &&
                    _currentPlayerIndex < _playerOrder.length)
                ? _playerOrder[_currentPlayerIndex]
                : null;
            final bool isResponsiblePlayer =
                (currentNamerId == widget.myPlayerId) || // 命名者
                (_playersAttemptedCurrentCard.containsKey(widget.myPlayerId) &&
                    _playersAttemptedCurrentCard[widget.myPlayerId] == true &&
                    _playersAttemptedCurrentCard.length >=
                        (roomData['players'] as List)
                            .length); // または全員回答済み時の最終アクション担当者

            if (now.isAfter(expectedCompletionTime)) {
              // 遅延時間が既に経過している場合、責任を持つプレイヤーが次のカードへ進める
              if (isResponsiblePlayer) {
                debugPrint(
                  'Delay already passed, advancing card directly by ${widget.myPlayerId}',
                );
                _advanceCardAfterDelay();
              }
            } else {
              // まだ遅延時間中の場合、残りの時間だけ待機
              final remainingDuration = expectedCompletionTime.difference(now);
              if (remainingDuration.inMilliseconds > 0) {
                Future.delayed(remainingDuration, () {
                  if (mounted && _displayDelayCompleteTimestamp != null) {
                    // 遅延中に状態が変わっていないか再確認
                    if (isResponsiblePlayer) {
                      debugPrint(
                        'Delay finished, advancing card by ${widget.myPlayerId}',
                      );
                      _advanceCardAfterDelay();
                    }
                  }
                });
              }
            }
          }

          // テキストモードで、カードが既出になったタイミングで選択肢を生成
          // かつ、まだ選択肢が生成されておらず、AI生成中でない場合
          // かつ、名前確認の遅延中ではない場合（重要：これがないと遅延中に選択肢が出てしまう）
          if (!widget.isVoiceMode &&
              !_isFirstAppearance &&
              _canSelectPlayer &&
              _choiceNames.isEmpty &&
              !_isLoadingChoices &&
              _currentImagePath != null &&
              _characterNames.containsKey(_currentImagePath!) &&
              _displayDelayCompleteTimestamp == null) {
            _generateAndShowChoices(_characterNames[_currentImagePath!]!);
          }
        } else {
          debugPrint('Room document does not exist.');
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

  // 遅延後に次のカードへ進めるメソッド
  Future<void> _advanceCardAfterDelay() async {
    final roomRef = _firestore.collection('rooms').doc(widget.roomId);
    await _firestore.runTransaction((transaction) async {
      final roomSnap = await transaction.get(roomRef);
      final roomData = roomSnap.data() as Map<String, dynamic>;

      // すでに次のカードへ進んでいる場合は何もしない
      if (roomData['displayDelayCompleteTimestamp'] == null) {
        return;
      }

      transaction.update(roomRef, {
        'displayDelayCompleteTimestamp': null, // タイムスタンプをリセット
        'canSelectPlayer': false, // 次のカードへ進むので選択不可に
        'lastNamedCharacterData': null, // 名前確認フェーズ終了でリセット
      });
    });
    // トランザクション完了後に次のカードをめくる
    _drawNextCardOnline(_firestore.collection('rooms').doc(widget.roomId));
  }

  /// ゲームの初期化とプレイヤーの参加処理
  Future<void> _initializeOnlineGame() async {
    DocumentReference roomRef = _firestore
        .collection('rooms')
        .doc(widget.roomId);
    DocumentSnapshot roomSnapshot = await roomRef.get();

    if (roomSnapshot.exists) {
      Map<String, dynamic> data = roomSnapshot.data() as Map<String, dynamic>;

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
          currentScores[widget.myPlayerId] = 0;

          List<dynamic> playersList = List.from(
            roomDataFromTransaction['players'] ?? [],
          );
          if (!playersList.contains(widget.myPlayerId)) {
            playersList.add(widget.myPlayerId);
          }

          transaction.update(roomRef, {
            'scores': currentScores,
            'players': playersList,
          });
        });
      }

      _loadGameState(data);
    }
  }

  /// ゲーム開始処理
  /// プレイヤーが「ゲーム開始」ボタンを押した際に呼び出されます。
  Future<void> _startGameOnline(DocumentReference roomRef) async {
    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot currentRoom = await transaction.get(roomRef);
      Map<String, dynamic> data = currentRoom.data() as Map<String, dynamic>;

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
      fullDeck.shuffle(_random);

      Map<String, dynamic> initialScores = {};
      (data['players'] as List<dynamic>).forEach((playerId) {
        initialScores[playerId] = 0;
      });

      List<String> shuffledPlayerOrder = List<String>.from(
        data['players'] as List<dynamic>,
      )..shuffle(_random);

      transaction.update(roomRef, {
        'status': 'playing',
        'deck': fullDeck,
        'scores': initialScores,
        'fieldCards': [],
        'seenImages': [],
        'characterNames': {},
        'currentCard': null,
        'isFirstAppearance': true,
        'canSelectPlayer': false,
        'turnCount': 0,
        'gameStarted': true,
        'playerOrder': shuffledPlayerOrder,
        'currentPlayerIndex': 0,
        'playersAttemptedCurrentCard': {},
        'displayDelayCompleteTimestamp': null,
        'lastNamedCharacterData': null,
      });
    });

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

      _characterNames = Map<String, String>.from(data['characterNames'] ?? {});
      _choiceNames.clear();
      _isLoadingChoices = false;

      _playerOrder = List<String>.from(data['playerOrder'] ?? []);
      _currentPlayerIndex = data['currentPlayerIndex'] as int? ?? 0;
      _playersAttemptedCurrentCard = Map<String, bool>.from(
        data['playersAttemptedCurrentCard'] ?? {},
      );

      final timestampData = data['displayDelayCompleteTimestamp'];
      if (timestampData is Timestamp) {
        _displayDelayCompleteTimestamp = timestampData.toDate();
      } else {
        _displayDelayCompleteTimestamp = null;
      }
      _lastNamedCharacterData =
          data['lastNamedCharacterData'] as Map<String, dynamic>?;
    });
  }

  @override
  void dispose() {
    _adMob.disposeBanner();
    _audioPlayer.dispose();
    _bgmPlayer.dispose();
    _nameInputController.dispose();
    super.dispose();
  }

  // BGM再生用のメソッド
  Future<void> _startBGM() async {
    try {
      await _bgmPlayer.setAsset('assets/audio/for_siciliano.mp3');
      _bgmPlayer.setLoopMode(LoopMode.one);
      _bgmPlayer.setVolume(0.5);
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
        'playersAttemptedCurrentCard': {},
        'displayDelayCompleteTimestamp': null,
        'lastNamedCharacterData': null, // 次のカードなのでリセット
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

      if (!(data['canSelectPlayer'] as bool? ?? false)) {
        return;
      }

      List<dynamic> fieldCards = List<dynamic>.from(data['fieldCards'] ?? []);
      Map<String, dynamic> scores = Map<String, dynamic>.from(
        data['scores'] ?? {},
      );

      scores[playerKey] = (scores[playerKey] as int? ?? 0) + fieldCards.length;

      transaction.update(roomRef, {
        'scores': scores,
        'fieldCards': [],
        'canSelectPlayer': false,
        'playersAttemptedCurrentCard': {},
        'displayDelayCompleteTimestamp':
            FieldValue.serverTimestamp(), // 遅延開始タイムスタンプを設定
      });
    });
    // _advanceCardAfterDelay によって次のカードへ進む
  }

  /// 「わからない」が選択された時の処理（オンライン版）
  Future<void> _skipCardOnline(DocumentReference roomRef) async {
    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot currentRoom = await transaction.get(roomRef);
      Map<String, dynamic> data = currentRoom.data() as Map<String, dynamic>;

      if (!(data['canSelectPlayer'] as bool? ?? false)) {
        return;
      }

      Map<String, bool> playersAttempted = Map<String, bool>.from(
        data['playersAttemptedCurrentCard'] ?? {},
      );
      List<String> allPlayers = List<String>.from(data['players'] ?? []);

      playersAttempted[widget.myPlayerId] = true;

      // Firestoreを更新
      transaction.update(roomRef, {
        'playersAttemptedCurrentCard': playersAttempted,
      });

      // 全員がお手つき/スキップ済みになったら次のカードへ進める
      if (playersAttempted.length >= allPlayers.length) {
        transaction.update(roomRef, {
          'canSelectPlayer': false,
          'displayDelayCompleteTimestamp':
              FieldValue.serverTimestamp(), // 遅延開始タイムスタンプを設定
        });
      } else {}
    });
  }

  // 通話モード専用: ゲーム状況をアナウンスするメソッド（Cloud Functions経由でTTSを呼び出す）
  Future<void> _announceGameStatus(Map<String, int> currentScores) async {
    if (!widget.isVoiceMode || !mounted) {
      debugPrint("Not in Voice Mode or Widget not mounted. Skipping TTS.");
      return;
    }

    String commentary;
    final localizations = AppLocalizations.of(context)!;

    if (currentScores.isEmpty ||
        currentScores.values.every((score) => score == 0)) {
      commentary = localizations.gameStart;
    } else {
      List<MapEntry<String, int>> sortedScores = currentScores.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      int maxScore = 0;
      List<String> leadingPlayerIds = [];

      for (var entry in sortedScores) {
        if (entry.value > maxScore) {
          maxScore = entry.value;
          leadingPlayerIds = [entry.key];
        } else if (entry.value == maxScore && entry.value > 0) {
          leadingPlayerIds.add(entry.key);
        }
      }

      if (leadingPlayerIds.length == 1) {
        String leadingPlayerAlias = leadingPlayerIds[0] == widget.myPlayerId
            ? localizations.you
            : localizations.player(
                sortedScores.indexOf(
                      leadingPlayerIds[0] as MapEntry<String, int>,
                    ) +
                    1,
              );
        commentary = localizations.leadingPlayer(leadingPlayerAlias, maxScore);
      } else {
        List<String> leadingPlayerAliases = leadingPlayerIds.map((id) {
          return id == widget.myPlayerId
              ? localizations.you
              : localizations.player(
                  sortedScores.indexOf(id as MapEntry<String, int>) + 1,
                );
        }).toList();
        String players = leadingPlayerAliases.join(localizations.andSeparator);
        commentary = localizations.tieLead(players, maxScore);
      }
    }
    _playTts(commentary);
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
          Uri.parse('data:audio/mpeg;base64,${base64Encode(audioBytes)}'),
        ),
      );
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Cloud TTS 呼び出しまたは再生エラー: $e');
    }
  }

  // テキストモード専用: 名前入力処理
  Future<void> _handleNameSubmission(String name) async {
    final localizations = AppLocalizations.of(context)!;

    if (name.isEmpty || name.length > 8 || _currentImagePath == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(localizations.nameTooLong)));
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

      transaction.update(roomRef, {
        'characterNames': currentNames,
        'currentPlayerIndex': nextPlayerIndex,
        'canSelectPlayer': false, // 名前をつけた後は選択不可にする
        'displayDelayCompleteTimestamp':
            FieldValue.serverTimestamp(), // 遅延開始タイムスタンプを設定
        'lastNamedCharacterData': {
          // 最後に名前がつけられたキャラの情報を保存
          'imagePath': _currentImagePath,
          'name': name,
          'namedBy': widget.myPlayerId, // 名前をつけたプレイヤーID
          'timestamp': FieldValue.serverTimestamp(),
        },
      });
    });

    _nameInputController.clear(); // 入力フィールドをクリア
    // _advanceCardAfterDelay によって次のカードへ進む
  }

  // テキストモード専用: AIによる名前生成と選択肢表示
  Future<void> _generateAndShowChoices(String correctName) async {
    final localizations = AppLocalizations.of(context)!;

    setState(() {
      _isLoadingChoices = true;
      _choiceNames.clear(); // 新しい生成前にクリア
    });

    try {
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

      List<String> choices = [correctName, ...generatedNames];
      choices = choices.toSet().toList();

      final List<String> dummyNames = [
        localizations.unknown,
        localizations.aiError,
        localizations.retry,
      ];
      int dummyIndex = 0;
      while (choices.length < 7) {
        final String currentDummy = dummyNames[dummyIndex % dummyNames.length];
        if (!choices.contains(currentDummy)) {
          choices.add(currentDummy);
        }
        dummyIndex++;
        if (dummyIndex > dummyNames.length * 2) break; // 無限ループ防止
      }

      if (choices.length > 7) {
        choices = choices.sublist(0, 7);
      }
      choices.shuffle();

      setState(() {
        _choiceNames = choices;
        _isLoadingChoices = false;
      });
    } catch (e) {
      debugPrint('AI名前生成エラー: $e');
      setState(() {
        _isLoadingChoices = false;
        _choiceNames = [
          correctName,
          localizations.aiError,
          localizations.retry,
          localizations.skip,
          localizations.unknown,
          '?',
          '??',
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
      await _awardPointsOnline(
        _firestore.collection('rooms').doc(widget.roomId),
        widget.myPlayerId,
      );
    } else {
      await _skipCardOnline(_firestore.collection('rooms').doc(widget.roomId));
    }
    _choiceNames.clear();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    String? currentNamerId;
    if (_playerOrder.isNotEmpty &&
        _currentPlayerIndex >= 0 &&
        _currentPlayerIndex < _playerOrder.length) {
      currentNamerId = _playerOrder[_currentPlayerIndex];
    }

    // 名前確認フェーズ（displayDelayCompleteTimestampが設定されている間）
    bool isInNameConfirmationPhase =
        _displayDelayCompleteTimestamp != null &&
        _lastNamedCharacterData != null;
    String? namedCharName;
    String? namedCharId;
    if (isInNameConfirmationPhase) {
      namedCharName = _lastNamedCharacterData!['name'] as String?;
      namedCharId = _lastNamedCharacterData!['namedBy'] as String?;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.gameStart),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _roomStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text(localizations.roomNotFound));
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
          );
          _playerOrder = List<String>.from(roomData['playerOrder'] ?? []);
          _currentPlayerIndex = roomData['currentPlayerIndex'] as int? ?? 0;
          _playersAttemptedCurrentCard = Map<String, bool>.from(
            roomData['playersAttemptedCurrentCard'] ?? {},
          );

          final timestampData = roomData['displayDelayCompleteTimestamp'];
          if (timestampData is Timestamp) {
            _displayDelayCompleteTimestamp = timestampData.toDate();
          } else {
            _displayDelayCompleteTimestamp = null;
          }
          _lastNamedCharacterData =
              roomData['lastNamedCharacterData'] as Map<String, dynamic>?;

          _scores = Map<String, int>.from(roomData['scores'] ?? {});

          List<MapEntry<String, int>> sortedScores = _scores.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));

          if (roomData['status'] == 'finished') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              List<int> resultScores = sortedScores
                  .map((e) => e.value)
                  .toList();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ResultScreen(
                    scores: resultScores,
                    playerCount: sortedScores.length,
                    isOnline: true,
                    roomId: widget.roomId,
                    myPlayerId: widget.myPlayerId,
                  ),
                ),
              );
            });
            return const SizedBox.shrink();
          }

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
                    localizations.waitingForPlayers,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${localizations.roomId}: ${widget.roomId}',
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
                            SnackBar(content: Text(localizations.copiedRoomId)),
                          );
                        },
                        tooltip: localizations.copyRoomId,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    localizations.tellOthersRoomId,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: canStartGame
                        ? () => _startGameOnline(
                            _firestore.collection('rooms').doc(widget.roomId),
                          )
                        : null,
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
                          ? localizations.startGame
                          : localizations.playersNeeded(currentPlayersCount, 2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(localizations.joinRoom),
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
                              localizations.playerScore(
                                sortedScores.indexOf(entry) + 1,
                                score,
                              ),
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
                          localizations.currentFieldCards(_fieldCards.length),
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
                                        : Text(localizations.gameEnd),
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
                                    ? localizations.firstAppearance
                                    : localizations.seenBefore,
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
                          currentNamerId == widget.myPlayerId
                              ? localizations.myNameTurn
                              : localizations.otherPlayersTurn(
                                  _playerOrder.indexOf(currentNamerId!) + 1,
                                ),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.blueGrey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 20),

                      // ★名前確認フェーズのUI (新しいブロック)★
                      if (isInNameConfirmationPhase) // 名前確認フェーズの場合
                        Column(
                          children: [
                            Text(
                              localizations.namedCharacterConfirmation(
                                namedCharName ?? localizations.unknown, // 名前
                                namedCharId == widget.myPlayerId
                                    ? localizations
                                          .you // 名付けたのが自分なら「あなた」
                                    : localizations.player(
                                        _playerOrder.indexOf(namedCharId!) + 1,
                                      ), // 名付けたプレイヤー
                              ),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "wait",
                              style: TextStyle(color: Colors.grey),
                            ), // 次のターン準備中...
                            const CircularProgressIndicator(), // ローディング表示
                          ],
                        )
                      else // 通常の操作ボタンエリア
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
    final localizations = AppLocalizations.of(context)!;

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
                hasAttempted ? localizations.answered : localizations.get,
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
                hasAttempted ? localizations.skipped : localizations.skip,
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
          label: Text(localizations.nextCard),
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
                decoration: InputDecoration(
                  labelText: localizations.charNamePrompt,
                  border: const OutlineInputBorder(),
                ),
                maxLength: 8, // 8文字制限
                onSubmitted: _handleNameSubmission, // エンターキーで送信
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () =>
                    _handleNameSubmission(_nameInputController.text.trim()),
                child: Text(localizations.nameIt),
              ),
            ],
          );
        } else {
          // 自分のターンではない場合、名前付けは他のプレイヤー待ち
          return Text(
            localizations.opponentNaming,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
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
                  hasAttempted ? localizations.skipped : localizations.skip,
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
          label: Text(localizations.nextCard),
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
