import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/speech.dart';
import '../widgets/banner_ad_slot.dart';

/// チュートリアルを見終えたかどうかの保存キー。
/// 初回起動時だけ自動で開き、一度終えたら二度と出さない。
const String kTutorialDoneKey = 'tutorialDone';

/// 初回起動かどうか（= まだチュートリアルを見ていないか）。
Future<bool> shouldShowTutorial() async {
  final p = await SharedPreferences.getInstance();
  return !(p.getBool(kTutorialDoneKey) ?? false);
}

Future<void> markTutorialDone() async {
  final p = await SharedPreferences.getInstance();
  await p.setBool(kTutorialDoneKey, true);
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
  final String body;
  final String illustration; // ページの大きな挿絵（絵文字）
  /// 実際のゲーム画面のスクショ。あると絵文字の代わりにこれを大きく出す。
  final String? screenshot;
  final List<Color> gradient;

  const _TutorialPage({
    required this.guideEmoji,
    this.guideAsset,
    required this.guideName,
    required this.title,
    required this.body,
    required this.illustration,
    this.screenshot,
    required this.gradient,
  });
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
          body: ja
              ? 'このアプリは「顔と名前をおぼえる」ゲームだよ。\nメインのあそび「なまえコール」のやりかたを\nこれから じゅんばんに せつめいするね！\n\nともだちや かぞくと 1台のスマホで あそぶよ📱'
              : 'This app is a face-and-name memory game.\nLet me walk you through Name Call,\nour main mode, step by step!\n\nPlay with friends on one phone 📱',
          illustration: '🏷️✨',
          gradient: const [Color(0xFFFFE3EE), Color(0xFFFFF6D8)],
        ),
        _TutorialPage(
          guideEmoji: '👦',
          guideAsset: 'assets/images/supporters/cheer_girl2.svg',
          guideName: ja ? 'モンくん' : 'Mon',
          title: ja ? '① まずは人数をえらぶ' : '1. Choose players',
          body: ja
              ? '「出たとき命名」をえらんで\n🎉みんなで（1台）を おす！\nそのあと なん人で あそぶか えらぶよ。\n\nはじめては 6人 が ちょうどいいよ😊'
              : 'Pick "Name as you go", tap\n🎉 Party (1 phone), then choose\nhow many of you are playing.\n\n6 faces is a good start 😊',
          illustration: '👥',
          screenshot: 'assets/images/tutorial/step_home.png',
          gradient: const [Color(0xFFD8F0FF), Color(0xFFE8FFF7)],
        ),
        _TutorialPage(
          guideEmoji: '👧',
          guideAsset: 'assets/images/supporters/cheer_girl.svg',
          guideName: ja ? 'ナナちゃん' : 'Nana',
          title: ja ? '② はじめての子に名前をつける' : '2. Name each newcomer',
          body: ja
              ? 'カードが 1まいずつ 出てくるよ。\nはじめて出た子には その場で 名前をつけよう！\n\n口に出して「〇〇！」と 名前を言ってから\n✨名前をつけた！を おす。\nまよったら 🎲おまかせ でもOK。\n\nこのときは まだ 点は入らないよ。'
              : 'Cards appear one at a time.\nWhen a new face shows up, name it!\n\nSay the name out loud, then tap\n✨ We named it!\nOr tap 🎲 to let the app decide.\n\nNo points yet at this step.',
          illustration: '✏️',
          screenshot: 'assets/images/tutorial/step_naming.png',
          gradient: const [Color(0xFFFFF6D8), Color(0xFFD8F6F0)],
        ),
        _TutorialPage(
          guideEmoji: '👦',
          guideAsset: 'assets/images/supporters/cheer_girl2.svg',
          guideName: ja ? 'モンくん' : 'Mon',
          title: ja ? '③ 同じ子が出たら 名前をさけぶ！' : '3. Shout the name!',
          body: ja
              ? 'まえに 名前をつけた子が また出てきたら…\nみんなで いっせいに 名前をさけぶ！📣\n\nいちばん早く 正しく 言えた人の\nボタン（P1・P2…）を おしてね。\nおされた人が そのカードを もらえるよ🎉\n\nだれも 思い出せなかったら\n「だれもわからなかった…」を おそう。'
              : 'When a face you already named comes back,\neveryone shouts its name at once! 📣\n\nTap the button (P1, P2...) of whoever\nsaid it first and correctly.\nThat player wins the card 🎉\n\nIf nobody remembers, tap\n"Nobody knew...".',
          illustration: '📣',
          screenshot: 'assets/images/tutorial/step_recall.png',
          gradient: const [Color(0xFFE8E3FF), Color(0xFFFFE3F0)],
        ),
        _TutorialPage(
          guideEmoji: '👧',
          guideAsset: 'assets/images/supporters/cheer_girl.svg',
          guideName: ja ? 'ナナちゃん' : 'Nana',
          title: ja ? '④ カードを多くあつめた人の勝ち！' : '4. Most cards wins!',
          body: ja
              ? 'カードが なくなったら おしまい。\nいちばん たくさん カードを あつめた人の勝ち🏆\n\nさいごに みんなの 名前が ぜんぶ 出るから\n「そんな名前だったっけ！？」で もりあがるよ😆'
              : 'The game ends when the cards run out.\nWhoever collected the most cards wins 🏆\n\nAt the end every name is revealed —\nthat is where the laughs happen 😆',
          illustration: '🏆',
          gradient: const [Color(0xFFFFE3EE), Color(0xFFD8F0FF)],
        ),
        _TutorialPage(
          guideEmoji: '👦',
          guideAsset: 'assets/images/supporters/cheer_girl2.svg',
          guideName: ja ? 'モンくん' : 'Mon',
          title: ja ? '🖇 ひとりのときは「ビジネス特訓」' : '🖇 Alone? Use Training',
          body: ja
              ? 'ひとりで あそびたいときは\n「ビジネス特訓」タブへ！\n\n🖇線むすび … 顔と名前を ゆびで つなぐ\n🧠思い出し … 名刺の人を おぼえて 当てる\n\nじぶんの しゃしんも とうろく できるよ📷'
              : 'Playing alone? Open the Training tab!\n\n🖇 Line Match — connect faces to names\n🧠 Recall — remember people from cards\n\nYou can add your own photos too 📷',
          illustration: '🖇️',
          gradient: const [Color(0xFFFFF6D8), Color(0xFFE8E3FF)],
        ),
      ];

  bool _voiceOn = true;
  bool _spokeFirstPage = false;

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
    await Speech.instance.speak('${page.title}。${page.body}', ja: ja);
  }

  Future<void> _finish() async {
    await Speech.instance.stop();
    await markTutorialDone();
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
            onPressed: _finish,
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
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 実際のゲーム画面があれば、絵文字よりそちらを大きく見せる。
          // 「どのボタンを押すのか」は文章より画面のほうが早く伝わる。
          if (p.screenshot != null)
            Expanded(
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
            Text(p.illustration, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
          ],
          // 案内キャラの吹き出しカード
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (p.guideAsset != null)
                      SvgPicture.asset(p.guideAsset!, width: 46, height: 46)
                    else
                      Text(p.guideEmoji,
                          style: const TextStyle(fontSize: 34)),
                    const SizedBox(width: 8),
                    Text(
                      p.guideName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  p.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFB4326E),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  p.body,
                  style: const TextStyle(fontSize: 15, height: 1.6),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
