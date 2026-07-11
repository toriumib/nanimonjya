import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../components/ad_mob.dart'; // AdMobクラスを別ファイルに
import 'result_screen.dart'; // 結果表示画面
import 'top_screen.dart'; // ホームへ確実に戻るため
import 'package:just_audio/just_audio.dart'; // BGM用にjust_audioを追加
import '../services/player_profile.dart'; // 選択中BGMの参照
import '../services/app_analytics.dart'; // プレイ行動の分析ログ
import '../widgets/dog_squad.dart'; // 応援わんちゃんズ
import '../l10n/meta_strings.dart'; // やめる等のナビ文言

// 多言語対応のために追加
import 'package:untitled/l10n/app_localizations.dart'; // ★パス修正済み★

/// CPU対戦の強さ。かんたん/ふつう/つよいで記憶力と反応速度が変わる。
enum CpuLevel { easy, normal, hard }

class GameScreen extends StatefulWidget {
  final int playerCount; // プレイヤー人数を受け取る
  final CpuLevel? cpuLevel; // nullでなければ「あなた vs CPU」の一人プレイ

  const GameScreen({Key? key, required this.playerCount, this.cpuLevel})
      : super(key: key);

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

  // ── 🤖 CPU対戦（cpuLevel != null のとき、プレイヤー1=あなた, 2=CPU）──
  bool get _vsCpu => widget.cpuLevel != null;
  final Map<String, int> _exposures = {}; // 画像ごとの登場回数（CPUの記憶に使用）
  Timer? _cpuTimer; // CPUの「思い出すまでの時間」タイマー
  // TODO: ゲーム終了条件を決める（例：山札がなくなるまで）
  // final int _maxTurns = 20; // 例：最大ターン数

  @override
  void initState() {
    super.initState();
    _adMob.loadBanner(); // バナー広告の読み込み開始
    _initializeGame();
    _startBGM(); // BGM再生を開始
    AppAnalytics.gameStart(
      mode: _vsCpu ? 'cpu' : 'offline',
      players: widget.playerCount,
    );
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
    _cpuTimer?.cancel();
    _adMob.disposeBanner(); // 画面破棄時に広告も破棄
    _bgmPlayer.dispose(); // BGM用プレイヤーを解放
    super.dispose();
  }

  // ── 🤖 CPUの頭脳 ──
  // 見た回数が多いカードほど思い出しやすい。強さで基礎記憶力と反応速度が変わる。
  double _cpuRecallChance(String imagePath) {
    final seen = _exposures[imagePath] ?? 1;
    final (base, perExposure, cap) = switch (widget.cpuLevel!) {
      CpuLevel.easy => (0.30, 0.05, 0.55),
      CpuLevel.normal => (0.50, 0.08, 0.80),
      CpuLevel.hard => (0.65, 0.10, 0.95),
    };
    return (base + perExposure * (seen - 1)).clamp(0.0, cap);
  }

  Duration _cpuReactionDelay() {
    final (minMs, maxMs) = switch (widget.cpuLevel!) {
      CpuLevel.easy => (2600, 4200),
      CpuLevel.normal => (1900, 3200),
      CpuLevel.hard => (1300, 2400),
    };
    return Duration(milliseconds: minMs + _random.nextInt(maxMs - minMs));
  }

  /// 見たことあるカードが出たらCPUが「思い出しレース」に参加する。
  /// 思い出せたら反応時間の後にポイントを総取り。あなたが先にタップすれば勝ち。
  void _startCpuRace(String imagePath) {
    _cpuTimer?.cancel();
    if (_random.nextDouble() >= _cpuRecallChance(imagePath)) {
      return; // 今回は思い出せなかった（あなたのチャンス！）
    }
    _cpuTimer = Timer(_cpuReactionDelay(), () {
      if (!mounted || !_canSelectPlayer) return;
      final taken = _fieldCards.length;
      _awardPoints(1); // CPUはプレイヤー2
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(MetaStrings.of(context).cpuTook(taken)),
          duration: const Duration(milliseconds: 1500),
        ),
      );
    });
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

  // カードをめくる（次の画像を表示する）処理
  void _drawNextCard() {
    // ★800ms遅延中に「やめる」で画面を抜けた場合のクラッシュを防止★
    if (!mounted) return;
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
      _exposures[_currentImagePath!] = (_exposures[_currentImagePath!] ?? 0) + 1;

      // この画像が初めて出たかチェック
      if (_seenImages.contains(_currentImagePath)) {
        _isFirstAppearance = false;
        _canSelectPlayer = true; // 見たことあるカードならプレイヤー選択可能
        if (_vsCpu) _startCpuRace(_currentImagePath!); // 🤖 CPUも思い出しに挑戦
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
    _cpuTimer?.cancel(); // 先取りされたらCPUの挑戦は打ち切り

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
    _cpuTimer?.cancel();
    setState(() {
      // 現在のカードは場札に追加されるため、_drawNextCard内で処理される
      _canSelectPlayer = false; // 選択不可に
      Future.delayed(const Duration(milliseconds: 800), _drawNextCard);
    });
  }

  // ゲーム終了処理
  void _endGame() {
    if (!mounted) return; // 破棄済みcontextへのアクセスを防止
    _cpuTimer?.cancel();
    // 最後の場札が残っている場合、ルールに応じて処理（例：誰も獲得しない）
    _fieldCards.clear();
    AppAnalytics.gameEnd(
      mode: _vsCpu ? 'cpu' : 'offline',
      topScore: _scores.reduce(max),
    );

    // 結果画面へ遷移
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          scores: _scores,
          playerCount: widget.playerCount,
          vsCpu: _vsCpu,
        ),
      ),
    );
  }

  // ホームに戻る確認（オフラインはローカルなので確認後すぐ戻ってOK）
  Future<void> _confirmQuitOffline(BuildContext context) async {
    final m = MetaStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.quitTitle),
        content: Text(m.quitOfflineBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(m.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(m.quitGame),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const TopScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!; // 多言語対応のインスタンス

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.turn(_turnCount)), // ★修正★
        automaticallyImplyLeading: false,
        // ★やめてホームに戻るボタン（確認ダイアログ付き）★
        leading: IconButton(
          icon: const Icon(Icons.home_rounded),
          tooltip: MetaStrings.of(context).backToHome,
          onPressed: () => _confirmQuitOffline(context),
        ),
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
                      final isCpu = _vsCpu && index == 1;
                      return Chip(
                        avatar: CircleAvatar(
                          backgroundColor: isCpu
                              ? Colors.deepPurple.shade400
                              : Colors.blue.shade800,
                          child: Text(
                            isCpu ? '🤖' : '${index + 1}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        label: Text(
                          isCpu
                              ? 'CPU: ${_scores[index]}'
                              : localizations.playerScore(
                                  index + 1,
                                  _scores[index],
                                ),
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

          // --- 応援わんちゃんズ（累計コインで仲間が増える） ---
          const DogSquad(),

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
      // 🤖 CPU対戦: あなたの「おぼえてる！」ボタンだけ（CPUは自動で挑戦してくる）
      if (_vsCpu) {
        return Column(
          children: [
            ElevatedButton(
              onPressed: () => _awardPoints(0),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                textStyle: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w900),
              ),
              child: Text(MetaStrings.of(context).iRemember,
                  style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _skipCard,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(localizations.skip),
            ),
          ],
        );
      }
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
