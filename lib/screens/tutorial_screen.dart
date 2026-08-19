import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cpu_difficulty.dart';
import '../services/player_profile.dart';
import '../services/speech.dart';
import '../widgets/banner_ad_slot.dart';
import '../services/app_analytics.dart';

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

/// 🎁 読み切ったごほうびを受け取り済みか。二重取りを止めるための鍵。
const String kTutorialRewardKey = 'tutorialRewardGiven';
const int kTutorialRewardCoins = 60;

Future<void> markTutorialSkipped() async {
  final p = await SharedPreferences.getInstance();
  final n = (p.getInt(kTutorialSkipsKey) ?? 0) + 1;
  await p.setInt(kTutorialSkipsKey, n);
  // あきらめる回数に達したら「見終えた」ことにして、もう出さない
  if (n >= kMaxTutorialRetries) await p.setBool(kTutorialDoneKey, true);
}

/// あそびかたチュートリアル。
/// ナナちゃんとはなちゃんが交互に案内してくれる。
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

  /// 初回に見せるページ。
  ///
  /// ⚠️ **短く保つこと。** 以前は11ページあり、遊ぶ前に読み物を
  ///    最後まで読ませる形になっていた。初回に要るのは
  ///    「なまえコールのルール」と「ひとりでも遊べる」ことだけ。
  ///    他のモードは最後の1ページで名前を挙げるにとどめ、
  ///    詳しくはルールブック（いつでも開ける）に任せる。
  ///
  /// ⚠️ 絵文字は使わない。案内キャラはSVG、挿絵は実際のゲーム画面を使う。
  List<_TutorialPage> _pages(bool ja) => [
        _TutorialPage(
          guideEmoji: '',
          guideAsset: 'assets/images/supporters/cheer_girl.svg',
          guideName: ja ? 'ナナ' : 'Nana',
          title: ja ? '顔と名前をおぼえるゲーム' : 'A face-and-name memory game',
          points: ja
              ? [
                  '出てきた顔に名前をつける',
                  'もう一度出てきたら、その名前を思い出す',
                  'ひとりでも、みんなでも遊べる',
                ]
              : [
                  'Give each new face a name',
                  'When it returns, recall that name',
                  'Play alone or with friends',
                ],
          note: ja ? '30秒で説明します' : 'This takes 30 seconds',
          illustration: '',
          screenshot: 'assets/images/tutorial/hook_lab.png',
          gradient: const [Color(0xFF1B2130), Color(0xFF2C3446)],
        ),
        _TutorialPage(
          guideEmoji: '',
          guideAsset: 'assets/images/supporters/cheer_girl2.svg',
          guideName: ja ? 'ハナ' : 'Hana',
          title: ja ? '1. 名前をつける' : '1. Give a name',
          points: ja
              ? [
                  '知らない顔が1枚ずつ出てきます',
                  '自分で入力しても、おまかせでもOK',
                  'つけた名前は、あとで必ず聞かれます',
                ]
              : [
                  'New faces appear one at a time',
                  'Type a name, or let the app pick one',
                  'You will be asked for it later',
                ],
          illustration: '',
          screenshot: 'assets/images/tutorial/hook_office.png',
          gradient: const [Color(0xFF1B2130), Color(0xFF2C3446)],
        ),
        _TutorialPage(
          guideEmoji: '',
          guideAsset: 'assets/images/supporters/cheer_girl.svg',
          guideName: ja ? 'ナナ' : 'Nana',
          title: ja ? '2. 思い出す' : '2. Recall it',
          points: ja
              ? [
                  '同じ顔が、名前なしで戻ってきます',
                  'ひとりのときは4択で答えます',
                  'みんなでは、先に名前を呼んだ人が取ります',
                ]
              : [
                  'The same face comes back with no name',
                  'Alone: pick it from four choices',
                  'Together: whoever calls it first takes the card',
                ],
          note: ja
              ? '思い出せた回数が、そのまま得点になります'
              : 'Every name you recall is a point',
          illustration: '',
          screenshot: 'assets/images/tutorial/hook_school.png',
          gradient: const [Color(0xFF1B2130), Color(0xFF2C3446)],
        ),
        _TutorialPage(
          guideEmoji: '',
          guideAsset: 'assets/images/supporters/cheer_girl2.svg',
          guideName: ja ? 'ハナ' : 'Hana',
          title: ja ? '3. ひとりで対戦' : '3. Play solo',
          points: ja
              ? [
                  'ひとりで遊ぶなら、まずCPU戦から',
                  '難易度で「まとめて覚える人数」と持ち時間が変わります',
                  '勝つとコインがもらえます',
                ]
              : [
                  'Playing alone? Start with a CPU match',
                  'Difficulty changes how many faces at once, and your time',
                  'Win and you earn coins',
                ],
          note: ja
              ? 'このほかに、名刺覚え・顔メモ・オンライン対戦があります（ルールブックで説明します）'
              : 'There is also Card Memory, Face Notes and online play — see the rulebook',
          illustration: '',
          gradient: const [Color(0xFF1B2130), Color(0xFF2C3446)],
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
    AppAnalytics.screen('tutorial');
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
                'あとで 📖ルール から いつでも 読めます。'
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
      AppAnalytics.tutorialDone(completed: false, lastPage: _page);
      await markTutorialSkipped();
    } else {
      await markTutorialDone();
      await saveTutorialPage(0); // 読み切ったので進捗は畳む
      await _grantReward();
    }
    if (mounted) Navigator.pop(context);
  }

  /// 🎁 最後まで読んだ人へのごほうび。
  ///
  /// 説明を読むのは、それ自体は楽しくない。読み切った瞬間に何も起きないと
  /// 「読んで損した」で終わるので、その場でコインを渡して次の行動につなげる。
  ///
  /// ⚠️ 一度きり。`kTutorialRewardKey` で二重取りを止める。
  ///    ここを外すと、チュートリアルを開き直すだけでコインが無限に増える。
  Future<void> _grantReward() async {
    final p = await SharedPreferences.getInstance();
    if (p.getBool(kTutorialRewardKey) ?? false) return;
    await p.setBool(kTutorialRewardKey, true);
    await PlayerProfile.instance.grantBonusCoins(kTutorialRewardCoins);
    if (!mounted) return;

    final ja = Localizations.localeOf(context).languageCode == 'ja';
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8E6),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 10),
            Text(
              ja ? 'ぜんぶ よめたね！' : 'You read it all!',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFB4326E)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE9A8),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                '🪙 +$kTutorialRewardCoins',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF8A6100)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              ja
                  ? 'コインは 🛍ショップで あたらしい なかまと こうかんできるよ'
                  : 'Spend coins in the shop to unlock new characters',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ja ? 'やった！' : 'Nice!',
                style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ja = Localizations.localeOf(context).languageCode == 'ja';
    final pages = _pages(ja);
    final isLast = _page == pages.length - 1;

    // 最初のページだけは自動で話しかける（以降はページ送りのたびに話す）
    if (!_spokeFirstPage) {
      _spokeFirstPage = true;
      // 自動音声は不要のため無効化（ユーザー要望）
      // WidgetsBinding.instance
      //     .addPostFrameCallback((_) => _speak(pages[0], ja));
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
      bottomNavigationBar: const BannerAdSlot(placement: 'tutorial'),
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
          // ⏭ スキップは**押せる大きさ**にする。以前は小さな文字リンクで、
          //    読み飛ばしたい人が押しどころを探す羽目になっていた。
          Padding(
            // ⚠️ AppBarの高さ(56dp)に収まる範囲で最大化する。
            //    上下に余白を積むと文字が切れる。
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: TextButton(
              onPressed: _confirmSkip,
              // AppBarの地色が濃いので、既定色のままだと文字が沈む。白で固定する。
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                minimumSize: const Size(88, 42), // 指で押せる大きさ
                side: const BorderSide(color: Colors.white54, width: 1.2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
              child: Text(ja ? 'スキップ' : 'Skip',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 0.4)),
            ),
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
                // 自動音声は不要のため無効化（ユーザー要望）
                // _speak(pages[i], ja);
              },
              itemBuilder: (context, i) => _buildPage(pages[i]),
            ),
          ),
          // ページインジケータ＋次へボタン
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: [
                // ⭐ 進みぐあいを星で見せる。
                //    以前は小さな点だったが、点が増えても「進んでいる」
                //    感じがせず、最後まで読む人が少なかった。
                //    読んだページが星で埋まっていくほうが、次を押したくなる。
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(pages.length, (i) {
                    final done = i <= _page;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: TweenAnimationBuilder<double>(
                        // key を進捗で変えて、埋まった瞬間だけ跳ねさせる
                        key: ValueKey('star$i$done'),
                        tween: Tween(begin: done ? 0.4 : 1.0, end: 1.0),
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.elasticOut,
                        builder: (_, v, child) =>
                            Transform.scale(scale: v, child: child),
                        child: Icon(
                          done ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: i == _page ? 26 : 20,
                          color: done
                              ? const Color(0xFFFFC02E)
                              : Colors.grey.shade300,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 6),
                Text(
                  isLast
                      ? (ja ? 'これで準備完了' : 'Ready to play')
                      : (ja
                          ? 'あと ${pages.length - 1 - _page} ページ'
                          : '${pages.length - 1 - _page} to go!'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFB4326E),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isLast) {
                        AppAnalytics.tutorialDone(
                            completed: true, lastPage: _page);
                        _finish();
                      } else {
                        AppAnalytics.tutorialStep(
                            page: _page + 1, total: pages.length);
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      // 指で押す前提の大きさ。以前は小さくて押しにくかった。
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    child: Text(
                      isLast
                          ? (ja ? 'はじめる' : 'Start playing')
                          : (ja ? 'つぎへ' : 'Next'),
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
