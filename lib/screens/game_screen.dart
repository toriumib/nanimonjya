import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../components/ad_mob.dart'; // AdMobクラスを別ファイルに
import 'result_screen.dart'; // 結果表示画面
import 'package:just_audio/just_audio.dart'; // BGM用にjust_audioを追加

// 多言語対応のために追加
import 'package:untitled/l10n/app_localizations.dart'; // ★パス修正済み★

class GameScreen extends StatefulWidget {
  final int playerCount; // プレイヤー人数を受け取る

  const GameScreen({Key? key, required this.playerCount}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final AdMob _adMob = AdMob();
  final Random _random = Random();
  final AudioPlayer _bgmPlayer = AudioPlayer(); // BGM用のAudioPlayerを追加

  // --- ゲーム状態 ---
  // TODO: assets/images/ に配置した画像ファイル名に合わせてください
  final List<String> _characterImageFiles = List.generate(
    12,
    (index) => 'assets/images/char${index + 1}.jpg',
  ); // 12 *種類* の画像ファイルパス
  late List<String> _deck; // 山札 (画像のパス)
  late List<int> _scores; // 各プレイヤーのスコア
  final Set<String> _seenImages = {}; // 一度出た画像のパスを記録
  final List<String> _fieldCards = []; // 場札 (ポイント対象のカード)

  String? _currentImagePath; // 現在表示中の画像のパス
  bool _isFirstAppearance = true; // 現在の画像が初登場か
  bool _canSelectPlayer = false; // プレイヤー選択ボタンを押せる状態か
  int _turnCount = 0; // 総ターン数 (デバッグや終了判定用)
  // TODO: ゲーム終了条件を決める（例：山札がなくなるまで）
  // final int _maxTurns = 20; // 例：最大ターン数

  @override
  void initState() {
    super.initState();
    _adMob.loadBanner(); // バナー広告の読み込み開始
    _initializeGame();
    _startBGM(); // BGM再生を開始
  }

  void _initializeGame() {
    _deck = []; // いったん空にする
    for (String imagePath in _characterImageFiles) {
      for (int i = 0; i < 5; i++) {
        _deck.add(imagePath);
      }
    }
    _deck.shuffle(_random);

    _scores = List.filled(widget.playerCount, 0); // スコアを0で初期化
    _seenImages.clear(); // 見たことのある画像種類のリセット
    _fieldCards.clear(); // 場札のリセット
    _currentImagePath = null; // 最初は何も表示しない
    _isFirstAppearance = true;
    _canSelectPlayer = false;
    _turnCount = 0;
    Future.delayed(const Duration(milliseconds: 500), _drawNextCard);
  }

  @override
  void dispose() {
    _adMob.disposeBanner(); // 画面破棄時に広告も破棄
    _bgmPlayer.dispose(); // BGM用プレイヤーを解放
    super.dispose();
  }

  // BGM再生用のメソッド
  Future<void> _startBGM() async {
    try {
      await _bgmPlayer.setAsset(
        'assets/audio/op9-2-Nocturne.mp3',
      ); // BGMファイルのパス
      _bgmPlayer.setLoopMode(LoopMode.one); // ループ再生
      _bgmPlayer.setVolume(0.5); // 音量を調整 (0.0 から 1.0)
      _bgmPlayer.play();
    } catch (e) {
      debugPrint("Error loading BGM: $e");
    }
  }

  // カードをめくる（次の画像を表示する）処理
  void _drawNextCard() {
    if (_deck.isEmpty) {
      _endGame(); // 山札がなくなったらゲーム終了
      return;
    }

    setState(() {
      // 前のカードが場札にあれば場札に追加
      if (_currentImagePath != null) {
        _fieldCards.add(_currentImagePath!);
      }

      // 山札から1枚引く
      _currentImagePath = _deck.removeLast();
      _turnCount++;

      // この画像が初めて出たかチェック
      if (_seenImages.contains(_currentImagePath)) {
        _isFirstAppearance = false;
        _canSelectPlayer = true; // 見たことあるカードならプレイヤー選択可能
      } else {
        _isFirstAppearance = true;
        _seenImages.add(_currentImagePath!); // 初めてなら記録
        _canSelectPlayer = false; // 初めてのカードではプレイヤーは選択できない
      }

      // TODO: 必要なら最大ターン数での終了判定
      // if (_turnCount >= _maxTurns) {
      //   _endGame();
      //   return;
      // }
    });
  }

  // プレイヤーがポイントを獲得する処理
  void _awardPoints(int playerIndex) {
    if (!_canSelectPlayer) return; // 選択不可なら何もしない

    setState(() {
      // 場札の枚数をポイントとして加算
      _scores[playerIndex] += _fieldCards.length;
      _fieldCards.clear(); // 場札をリセット
      _canSelectPlayer = false; // ポイント獲得後は選択不可に

      // 次のカードをめくる
      // 少し間を置いてから次のカードへ
      Future.delayed(const Duration(milliseconds: 800), _drawNextCard);
    });
  }

  // 「わからない」が選択された時の処理
  void _skipCard() {
    setState(() {
      // 現在のカードは場札に追加されるため、_drawNextCard内で処理される
      _canSelectPlayer = false; // 選択不可に
      Future.delayed(const Duration(milliseconds: 800), _drawNextCard);
    });
  }

  // ゲーム終了処理
  void _endGame() {
    // 最後の場札が残っている場合、ルールに応じて処理（例：誰も獲得しない）
    _fieldCards.clear();

    // 結果画面へ遷移
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ResultScreen(scores: _scores, playerCount: widget.playerCount),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!; // 多言語対応のインスタンス

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.turn(_turnCount)), // ★修正★
        automaticallyImplyLeading: false, // 戻るボタン非表示
      ),
      body: Column(
        // 本体と広告を縦に並べる
        children: [
          // --- ゲーム画面本体 ---
          Expanded(
            child: SingleChildScrollView(
              // コンテンツがはみ出たらスクロール可能に
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround, // 要素を均等配置
                children: <Widget>[
                  // --- スコア表示 ---
                  Wrap(
                    // プレイヤー数に応じて折り返し表示
                    spacing: 8.0, // 横の間隔
                    runSpacing: 4.0, // 縦の間隔
                    alignment: WrapAlignment.center,
                    children: List.generate(widget.playerCount, (index) {
                      return Chip(
                        avatar: CircleAvatar(
                          backgroundColor: Colors.blue.shade800,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        label: Text(
                          localizations.playerScore(
                            index + 1,
                            _scores[index],
                          ), // ★修正★
                          style: const TextStyle(fontSize: 16),
                        ),
                        elevation: 2,
                      );
                    }),
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
                      localizations.currentFieldCards(
                        _fieldCards.length,
                      ), // ★修正★
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- カード（画像）表示エリア ---
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight:
                          MediaQuery.of(context).size.height *
                          0.35, // 高さを画面の割合で制限
                    ),
                    child: AspectRatio(
                      // アスペクト比を保つ (例: 3:4)
                      aspectRatio: 3 / 4,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.shade400,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white, // 画像がない時の背景色
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
                                child: _deck.isNotEmpty
                                    ? const CircularProgressIndicator()
                                    : Text(localizations.gameEnd), // ★修正★
                              )
                            : ClipRRect(
                                // 画像を角丸にする
                                borderRadius: BorderRadius.circular(10.0),
                                child: Image.asset(
                                  _currentImagePath!,
                                  fit: BoxFit.contain, // コンテナ内に収まるように
                                  // 画像読み込みエラー時の代替表示
                                  errorBuilder: (context, error, stackTrace) =>
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
                    height: 40, // 高さを確保してレイアウト崩れを防ぐ
                    child: _currentImagePath == null
                        ? const SizedBox.shrink() // 何も表示しない
                        : Text(
                            _isFirstAppearance
                                ? localizations.firstAppearance
                                : localizations.seenBefore, // ★修正★
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
                  _buildActionButtons(),
                ],
              ),
            ),
          ),

          // --- AdMob バナー広告 ---
          Container(
            alignment: Alignment.center,
            width: double.infinity,
            // AdMobクラスから取得した高さを使う（ロード前でも高さを確保）
            height: _adMob.getAdBannerHeight(),
            child: _adMob.getAdBannerWidget(), // AdMobクラスからウィジェットを取得
          ),
        ],
      ),
    );
  }

  // 操作ボタン（プレイヤー選択 or 次へ）を生成するメソッド
  Widget _buildActionButtons() {
    final localizations = AppLocalizations.of(context)!;

    // プレイヤー選択が可能な状態の場合 (見たことあるカードが出た場合)
    if (_canSelectPlayer) {
      return Column(
        children: [
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            alignment: WrapAlignment.center,
            children: List.generate(widget.playerCount, (index) {
              return ElevatedButton(
                onPressed: () => _awardPoints(index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent, // ポイント獲得ボタンの色
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  localizations.playerScore(
                    index + 1,
                    localizations.get,
                  ), // ★修正★
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }),
          ),
          const SizedBox(height: 10), // ボタン間のスペース
          // 「わからない」ボタンを追加
          ElevatedButton(
            onPressed: _skipCard,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange, // わからないボタンの色
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(localizations.skip),
          ),
        ],
      );
    }
    // 初登場カードの後 or ポイント獲得後 (または「わからない」選択後)
    else if (_currentImagePath != null && _deck.isNotEmpty) {
      return ElevatedButton.icon(
        onPressed: _drawNextCard,
        icon: const Icon(Icons.navigate_next),
        label: Text(localizations.nextCard),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          textStyle: const TextStyle(fontSize: 16),
        ),
      );
    }
    // ゲーム開始前や終了時
    else {
      return const SizedBox(height: 50); // ボタンエリアのスペース確保
    }
  }
}
