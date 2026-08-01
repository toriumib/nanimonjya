import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cpu_difficulty.dart';
import '../services/speech.dart';
import '../widgets/banner_ad_slot.dart';

/// チュートリアルを見終えたかどうかの保存キー。
/// 初回起動時だけ自動で開き、一度終えたら二度と出さない。
const String kTutorialDoneKey = 'tutorialDone';

/// どのページまで見たか。次に開いたとき続きから読めるようにする。
/// 途中でアプリを閉じた人に、最初からやり直させないための保険。
const String kTutorialPageKey = 'tutorialPage';

Future<int> savedTutorialPage() async {
  final p = await SharedPreferences.getInstance();
  return p.getInt(kTutorialPageKey) ?? 0;
}

Future<void> saveTutorialPage(int page) async {
  final p = await SharedPreferences.getInstance();
  await p.setInt(kTutorialPageKey, page);
}

/// 初回起動かどうか（= まだチュートリアルを見ていないか）。
Future<bool> shouldShowTutorial() async {
  final p = await SharedPreferences.getInstance();
  return !(p.getBool(kTutorialDoneKey) ?? false);
}

Future<void> markTutorialDone() async {
  final p = await SharedPreferences.getInstance();
  await p.setBool(kTutorialDoneKey, true);
}

/// 途中で閉じた回数。
///
/// 最後まで読まずに閉じた人には、次の起動で「続きから」もう一度出す。
/// ただし何度も出すと、それ自体が嫌われて離脱の原因になるので、
/// [kMaxTutorialRetries] 回であきらめて二度と出さない。
const String kTutorialSkipsKey = 'tutorialSkips';
const int kMaxTutorialRetries = 2;

Future<void> markTutorialSkipped() async {
  final p = await SharedPreferences.getInstance();
  final n = (p.getInt(kTutorialSkipsKey) ?? 0) + 1;
  await p.setInt(kTutorialSkipsKey, n);
  // あきらめる回数に達したら「見終えた」ことにして、もう出さない
  if (n >= kMaxTutorialRetries) await p.setBool(kTutorialDoneKey, true);
}

/// あそびかたチュートリアル。
/// かわいい女の子(ナナちゃん)と男の子(モンくん)が交互に案内してくれる。
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialPage {
  final String guideEmoji; // 案内キャラ（SVGが無いページのフォールバック）
  /// ホームにいる応援キャラのSVG。ここを指定すると絵文字より優先される。
  final String? guideAsset;
  final String guideName;
  final String title;

  /// 本文。**1行＝1メッセージ**の箇条書きにする。
  ///
  /// 以前は改行入りの長い文章を中央そろえで出していたが、
  /// 日本語の中央そろえの多行はどこを読めばいいか分からず読み飛ばされる。
  /// 短い行を左そろえで並べたほうが、目で追える。
  final List<String> points;

  /// 補足（小さめの文字で最後に添える）。
  final String? note;

  final String illustration; // ページの大きな挿絵（絵文字）
  /// 実際のゲーム画面のスクショ。あると絵文字の代わりにこれを大きく出す。
  final String? screenshot;
  final List<Color> gradient;

  /// 表など、箇条書きでは伝わらないものを差し込む枠（難易度の説明で使う）。
  final Widget? extra;

  const _TutorialPage({
    required this.guideEmoji,
    this.guideAsset,
    required this.guideName,
    required this.title,
    required this.points,
    this.note,
    required this.illustration,
    this.screenshot,
    this.extra,
    required this.gradient,
  });

  /// 読み上げ用のテキスト。箇条書きを続けて読ませる。
  String get spoken => '$title。${points.join('。')}';
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  List<_TutorialPage> _pages(bool ja) => [
        _TutorialPage(
          guideEmoji: '👧',
          guideAsset: 'assets/images/supporters/cheer_girl.svg',
          guideName: ja ? 'ナナちゃん' : 'Nana',
          title: ja ? 'ようこそ！' : 'Welcome!',
          points: ja
              ? [
                  '顔と名前をおぼえる ゲームだよ',
                  'メインは「なまえコール」',
                  'ひとりでも、みんなでも あそべる',
                ]
              : [
                  'A face-and-name memory game',
                  'The main mode is Name Call',
                  'Play alone or with friends',
                ],
          note: ja
              ? 'やりかたを じゅんばんに せつめいするね！'
              : "Let's go through it step by step!",
          illustration: '🏷️✨',
          screenshot: 'assets/images/tutorial/hook_lab.png',
          gradient: const [Color(0xFFFFE3EE), Color(0xFFFFF6D8)],
        ),
        _TutorialPage(
          guideEmoji: '👦',
          guideAsset: 'assets/images/supporters/cheer_girl2.svg',
          guideName: ja ? 'モンくん' : 'Mon',
          title: ja ? '① あそびかたを えらぶ' : '1. Choose how to play',
          points: ja
              ? [
                  '🤖CPUとたいせん … ひとりであそぶ',
                  '🎉みんなで（1台） … 2〜4人であそぶ',
                  '👥スライダーで 出てくる人数を きめる',
                ]
              : [
                  '🤖 vs CPU — play alone',
                  '🎉 Party (1 phone) — 2-4 players',
                  '👥 Use the slider to set how many faces',
                ],
          note: ja
              ? 'はじめては 4人 が ちょうどいいよ。なれたら 16人まで ふやせる😊'
              : 'Start with 4 faces. You can go up to 16 later 😊',
          illustration: '👥',
          screenshot: 'assets/images/tutorial/step_home.png',
          gradient: const [Color(0xFFD8F0FF), Color(0xFFE8FFF7)],
        ),
        _TutorialPage(
          guideEmoji: '👧',
          guideAsset: 'assets/images/supporters/cheer_girl.svg',
          guideName: ja ? 'ナナちゃん' : 'Nana',
          title: ja ? '② はじめての子に 名前をつける' : '2. Name each newcomer',
          points: ja
              ? [
                  'カードが 1まいずつ 出てくるよ',
                  'はじめて出た子には 名前をつける',
                  '口に出して「〇〇！」と 言うのがコツ',
                ]
              : [
                  'Cards appear one at a time',
                  'Name each new face',
                  'Say it out loud — that helps',
                ],
          note: ja
              ? 'ここでは まだ 点は入らないよ。おぼえる じかん だからね。'
              : 'No points yet — this is the memorizing step.',
          illustration: '✏️',
          screenshot: 'assets/images/tutorial/step_naming.png',
          gradient: const [Color(0xFFFFF6D8), Color(0xFFD8F6F0)],
        ),
        _TutorialPage(
          guideEmoji: '👦',
          guideAsset: 'assets/images/supporters/cheer_girl2.svg',
          guideName: ja ? 'モンくん' : 'Mon',
          title: ja ? '③ また出てきたら 名前をこたえる' : '3. Answer when they return',
          points: ja
              ? [
                  'まえに 名前をつけた子が また出てくる',
                  'ひとりのときは 4つの中から えらぶ',
                  'みんなのときは いっせいに さけぶ📣',
                ]
              : [
                  'A face you already named comes back',
                  'Alone: pick from four choices',
                  'Party: everyone shouts at once 📣',
                ],
          note: ja
              ? 'みんなのときは 早く言えた人の P1・P2… を おす。せいかいすると カードがもらえる🎉'
              : 'In party mode, tap P1/P2… for whoever said it first. They win the card 🎉',
          illustration: '📣',
          screenshot: 'assets/images/tutorial/step_recall.png',
          gradient: const [Color(0xFFE8E3FF), Color(0xFFFFE3F0)],
        ),
        _TutorialPage(
          guideEmoji: '👧',
          guideAsset: 'assets/images/supporters/cheer_girl.svg',
          guideName: ja ? 'ナナちゃん' : 'Nana',
          title: ja ? '④ カードを 多くあつめた人の勝ち' : '4. Most cards wins!',
          points: ja
              ? [
                  'カードが なくなったら おしまい',
                  'たくさん あつめた人の勝ち🏆',
                  'さいごに みんなの名前が ぜんぶ出る',
                ]
              : [
                  'The game ends when cards run out',
                  'Most cards collected wins 🏆',
                  'Every name is revealed at the end',
                ],
          note: ja
              ? '「そんな名前だったっけ！？」で もりあがるよ😆'
              : 'That is where the laughs happen 😆',
          illustration: '🏆',
          screenshot: 'assets/images/tutorial/hook_school.png',
          gradient: const [Color(0xFFFFE3EE), Color(0xFFD8F0FF)],
        ),
        // 🤖 難易度の説明。「つよい＝相手が速いだけ」だと思われがちなので、
        //    実際は "何人まとめて覚えるか" が変わることを表で見せる。
        //    表の中身は models/cpu_difficulty.dart から作るので、
        //    数字を変えてもこのページの説明がズレない。
        _TutorialPage(
          guideEmoji: '👦',
          guideAsset: 'assets/images/supporters/cheer_girl2.svg',
          guideName: ja ? 'モンくん' : 'Mon',
          title: ja ? '🤖 むずかしさの しくみ' : '🤖 How difficulty works',
          points: ja
              ? [
                  'まとめて おぼえる人数が ふえる',
                  'こたえる じかんが みじかくなる',
                  'そのぶん もらえるコインが ふえる',
                ]
              : [
                  'You memorize more people at once',
                  'You get less time to answer',
                  'And you earn more coins',
                ],
          note: ja
              ? 'かんたんは「1人おぼえて すぐこたえる」。鬼は「4人おぼえてから 4人ぶんこたえる」。あいだに ほかの人が はさまるほど むずかしい。'
              : 'Easy: memorize 1, answer right away. Oni: memorize 4, then answer all 4.',
          illustration: '🤖',
          extra: _difficultyTable(ja),
          gradient: const [Color(0xFFE8F0FF), Color(0xFFFFE8E8)],
        ),
        _TutorialPage(
          guideEmoji: '👧',
          guideAsset: 'assets/images/supporters/cheer_girl.svg',
          guideName: ja ? 'ナナちゃん' : 'Nana',
          title: ja ? '🖇 ひとりのときは「名刺おぼえ」' : '🖇 Alone? Card Memory',
          points: ja
              ? [
                  '🖇線むすび … 顔と名前を ゆびでつなぐ',
                  '🧠思い出し … 名刺の人を おぼえて 当てる',
                  '📷じぶんの しゃしんも とうろくできる',
                ]
              : [
                  '🖇 Line Match — connect faces to names',
                  '🧠 Recall — remember people from cards',
                  '📷 Add your own photos too',
                ],
          note: ja
              ? '📊マイページの 成績レポートで「おぼえられているか」が 見られるよ。'
              : 'Check the report on My Page to see how much you retain.',
          illustration: '🖇️',
          screenshot: 'assets/images/tutorial/hook_office.png',
          gradient: const [Color(0xFFFFF6D8), Color(0xFFE8E3FF)],
        ),
        // 🌐 オンラインは3つあって、それぞれ「誰と」「どう進むか」が違う。
        //    どれを押せばいいのか分からないまま知らない人と当たると、
        //    途中で抜けられて相手にも迷惑がかかるので、先に区別を見せる。
        _TutorialPage(
          guideEmoji: '👦',
          guideAsset: 'assets/images/supporters/cheer_girl2.svg',
          guideName: ja ? 'モンくん' : 'Mon',
          title: ja ? '🌐 オンラインで あそぶ' : '🌐 Play online',
          points: ja
              ? [
                  '🤝フレンド … 合言葉で 友だちと。1台のときと 同じルール',
                  '🏆ランク … 知らない人と 早押し。通話は いらない',
                  '🔁ターン制 … 交互にめくる。急かされずに あそべる',
                ]
              : [
                  '🤝 Friend — a room code; same rules as one phone',
                  '🏆 Ranked — buzz against a stranger, no voice chat',
                  '🔁 Turn-based — take turns flipping, no rush',
                ],
          note: ja
              ? 'フレンドは 部屋をつくった人が 人数をきめて、相手にも おなじ人数が 出るよ。くわしくは 📖ルール を見てね。'
              : 'In Friend match the host picks how many faces, and the guest gets the same. See 📖 Rules for details.',
          illustration: '🌐',
          gradient: const [Color(0xFFD8F0FF), Color(0xFFFFF6D8)],
        ),
      ];

  /// 難易度の比較表。値は models/cpu_difficulty.dart が一次情報。
  static Widget _difficultyTable(bool ja) {
    const order = ['easy', 'normal', 'hard', 'oni'];
    const namesJa = {
      'easy': 'かんたん',
      'normal': 'ふつう',
      'hard': 'つよい',
      'oni': '鬼',
    };
    const namesEn = {
      'easy': 'Easy',
      'normal': 'Normal',
      'hard': 'Hard',
      'oni': 'Oni',
    };
    const head = TextStyle(
        fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF2B5CA5));
    const cell = TextStyle(fontSize: 12.5);

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.5),
        1: FlexColumnWidth(1.6),
        2: FlexColumnWidth(1.0),
        3: FlexColumnWidth(1.2),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0x14000000)),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Text(ja ? 'つよさ' : 'Level', style: head),
            ),
            Text(ja ? 'おぼえる' : 'Memorize', style: head),
            Text(ja ? 'じかん' : 'Time', style: head),
            Text(ja ? '勝つと' : 'Win', style: head),
          ],
        ),
        for (final k in order)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                child: Text(
                  '${kCpuDifficulties[k]!.emoji} ${ja ? namesJa[k] : namesEn[k]}',
                  style: cell,
                ),
              ),
              Text(
                ja
                    ? '${kCpuDifficulties[k]!.groupSize}人ずつ'
                    : '${kCpuDifficulties[k]!.groupSize} at once',
                style: cell,
              ),
              Text('${kCpuDifficulties[k]!.answerSeconds}${ja ? '秒' : 's'}',
                  style: cell),
              Text('🪙${kCpuDifficulties[k]!.winBonus}', style: cell),
            ],
          ),
      ],
    );
  }

  bool _voiceOn = true;
  bool _spokeFirstPage = false;

  @override
  void initState() {
    super.initState();
    // 途中で閉じた人を最初からやり直させない（離脱の大きな原因）
    savedTutorialPage().then((saved) {
      if (!mounted || saved <= 0) return;
      setState(() => _page = saved);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) _pageController.jumpToPage(saved);
      });
    });
  }

  @override
  void dispose() {
    Speech.instance.stop();
    _pageController.dispose();
    super.dispose();
  }

  /// 案内キャラのセリフを読み上げる。小学生でも読み飛ばさずに済むよう、
  /// タイトルと本文をそのまま声にする。
  Future<void> _speak(_TutorialPage page, bool ja) async {
    if (!_voiceOn) return;
    await Speech.instance.stop();
    await Speech.instance.speak(page.spoken, ja: ja);
  }

  /// スキップは1タップで消さず、いつでも読み直せることを伝えてから閉じる。
  /// 「読まずに閉じた＝ルールが分からないまま遊ぶ」を減らすための一拍。
  Future<void> _confirmSkip() async {
    final ja = Localizations.localeOf(context).languageCode == 'ja';
    await Speech.instance.stop();
    if (!mounted) return;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ja ? 'あそびかたを とじる？' : 'Close the guide?'),
        content: Text(ja
            ? 'とちゅうまで 読んだところは おぼえてあるよ。\n'
                'あとで 📖ルールブック から いつでも 読めます。'
            : 'Your place is saved. You can read it any time from the 📖 Rulebook.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ja ? 'つづける' : 'Keep reading'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ja ? 'とじる' : 'Close'),
          ),
        ],
      ),
    );
    if (leave == true) await _finish(skipped: true);
  }

  Future<void> _finish({bool skipped = false}) async {
    await Speech.instance.stop();
    if (skipped) {
      // 途中で閉じた → 次の起動で続きから出す（上限あり）
      await markTutorialSkipped();
    } else {
      await markTutorialDone();
      await saveTutorialPage(0); // 読み切ったので進捗は畳む
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final ja = Localizations.localeOf(context).languageCode == 'ja';
    final pages = _pages(ja);
    final isLast = _page == pages.length - 1;

    // 最初のページだけは自動で話しかける（以降はページ送りのたびに話す）
    if (!_spokeFirstPage) {
      _spokeFirstPage = true;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _speak(pages[0], ja));
    }

    // ⚠️ Androidの戻るボタンで抜けられると markTutorialDone() を通らず、
    //    「見終えた」記録が残らないまま毎回起動のたびに出続けてしまう。
    //    戻るで閉じるときも必ず記録してから閉じる。
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmSkip();
      },
      child: _buildScaffold(ja, pages, isLast),
    );
  }

  Widget _buildScaffold(
      bool ja, List<_TutorialPage> pages, bool isLast) {
    return Scaffold(
      bottomNavigationBar: const BannerAdSlot(),
      appBar: AppBar(
        title: Text(ja ? 'あそびかた' : 'How to Play'),
        automaticallyImplyLeading: false,
        actions: [
          // 🔊 声のON/OFF（うるさいときや電車の中で切れるように）
          IconButton(
            tooltip: ja ? 'こえ' : 'Voice',
            icon: Icon(_voiceOn ? Icons.volume_up : Icons.volume_off),
            onPressed: () {
              setState(() => _voiceOn = !_voiceOn);
              if (_voiceOn) {
                _speak(pages[_page], ja);
              } else {
                Speech.instance.stop();
              }
            },
          ),
          TextButton(
            onPressed: _confirmSkip,
            // AppBarの地色がピンクなので、既定色のままだとピンク文字になって
            // 事実上見えなかった。白で固定する。
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: Text(ja ? 'スキップ ▶' : 'Skip ▶',
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 15)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: pages.length,
              onPageChanged: (i) {
                setState(() => _page = i);
                saveTutorialPage(i); // 途中で閉じても続きから読める
                _speak(pages[i], ja);
              },
              itemBuilder: (context, i) => _buildPage(pages[i]),
            ),
          ),
          // ページインジケータ＋次へボタン
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? const Color(0xFFFF4FA3)
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isLast) {
                        _finish();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    child: Text(
                      isLast
                          ? (ja ? 'あそびにいく！🎮' : "Let's play! 🎮")
                          : (ja ? 'つぎへ →' : 'Next →'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_TutorialPage p) {
    // ⚠️ 以前は Column + Expanded で組んでいたため、
    //    文字を大きくしている端末や画面の低い端末で本文がはみ出し、
    //    肝心の説明が読めないことがあった。全体をスクロールできるようにする。
    return LayoutBuilder(
      builder: (context, box) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: p.gradient,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 実際のゲーム画面があれば、絵文字よりそちらを大きく見せる。
              // 「どのボタンを押すのか」は文章より画面のほうが早く伝わる。
              if (p.screenshot != null)
                ConstrainedBox(
                  // 画面の4割までに抑える。挿絵が主役になって
                  // 説明が画面の外へ押し出されるのを防ぐ。
                  constraints: BoxConstraints(maxHeight: box.maxHeight * 0.4),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 8,
                            offset: Offset(0, 3)),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(p.screenshot!, fit: BoxFit.contain),
                  ),
                )
              else ...[
                Text(p.illustration, style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 14),
              ],
              // 案内キャラの吹き出しカード
              Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.94),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (p.guideAsset != null)
                          SvgPicture.asset(p.guideAsset!, width: 40, height: 40)
                        else
                          Text(p.guideEmoji,
                              style: const TextStyle(fontSize: 30)),
                        const SizedBox(width: 8),
                        Text(
                          p.guideName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      p.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFB4326E),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // 1行＝1メッセージ。左そろえにして目で追えるようにする。
                    for (final line in p.points)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 7, right: 8),
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF4FA3),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                line,
                                style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.5,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (p.extra != null) ...[
                      const SizedBox(height: 6),
                      p.extra!,
                    ],
                    if (p.note != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF6D8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          p.note!,
                          style: const TextStyle(fontSize: 13, height: 1.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
