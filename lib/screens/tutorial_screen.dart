import 'package:flutter/material.dart';
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
  final String guideEmoji; // 案内キャラ
  final String guideName;
  final String title;
  final String body;
  final String illustration; // ページの大きな挿絵（絵文字）
  final List<Color> gradient;

  const _TutorialPage({
    required this.guideEmoji,
    required this.guideName,
    required this.title,
    required this.body,
    required this.illustration,
    required this.gradient,
  });
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  List<_TutorialPage> _pages(bool ja) => [
        _TutorialPage(
          guideEmoji: '👧',
          guideName: ja ? 'ナナちゃん' : 'Nana',
          title: ja ? 'ペタネームへようこそ！' : 'Welcome to PetaName!',
          body: ja
              ? 'ペタネームは「顔と名前の記憶トレーニング」！\n人の名前を覚えるのが苦手…\nそんなあなたのための覚えゲームだよ💕'
              : 'PetaName is face & name memory training!\nBad with names? This game is\nmade exactly for you 💕',
          illustration: '🏷️✨',
          gradient: const [Color(0xFFFFE3EE), Color(0xFFFFF6D8)],
        ),
        _TutorialPage(
          guideEmoji: '👦',
          guideName: ja ? 'モンくん' : 'Mon',
          title: ja ? '📣 なまえコール①：名づけ' : '📣 Name Call ①: Naming',
          body: ja
              ? 'メインモード「なまえコール」は\nはじめに全員の顔に順番に名前をつけるよ。\nつけた名前は「名簿」にひみつで記録📖🔒\nゲームがおわるまで見られない！'
              : 'In Name Call, you start by naming\nevery face one by one.\nYour names go into a secret roster 📖🔒\nsealed until the game ends!',
          illustration: '✏️😀',
          gradient: const [Color(0xFFD8F0FF), Color(0xFFE8FFF7)],
        ),
        _TutorialPage(
          guideEmoji: '👧',
          guideName: ja ? 'ナナちゃん' : 'Nana',
          title: ja ? '📣 なまえコール②：思い出す！' : '📣 Name Call ②: Recall!',
          body: ja
              ? 'カードが出てきたら\n名前を思い出して答えよう！\n正解すると1枚ゲット🎉\n思い出せないと没収💦\nいちばん多くあつめた人の勝ち！'
              : 'When a card appears,\nrecall its name and answer!\nCorrect = one card 🎉\nForget it and it is gone 💦\nMost cards wins!',
          illustration: '🃏🃏',
          gradient: const [Color(0xFFE8E3FF), Color(0xFFFFE3F0)],
        ),
        _TutorialPage(
          guideEmoji: '👦',
          guideName: ja ? 'モンくん' : 'Mon',
          title: ja ? '🖇 ひとりでも「線むすび」' : '🖇 Solo: Line Match',
          body: ja
              ? 'ひとりのときは「ビジネス特訓」タブ！\n顔と名前を指で線でむすんで答えるよ✏️\nまちがえても何回でも引きなおせる。\n運じゃなくて実力でとける特訓だよ💪'
              : 'Alone? Open the Training tab!\nDrag your finger from a face to a name\nto connect them ✏️ Redo as often as\nyou like — pure skill, no luck 💪',
          illustration: '👤🖇️🏷️',
          gradient: const [Color(0xFFFFF6D8), Color(0xFFD8F6F0)],
        ),
        _TutorialPage(
          guideEmoji: '👧',
          guideName: ja ? 'ナナちゃん' : 'Nana',
          title: ja ? '🛍 ショップと🎴キャラデッキ' : '🛍 Shop & 🎴 Deck',
          body: ja
              ? 'あそぶとコインがたまるよ🪙\n「ショップ」タブで新しいキャラをおむかえ！\nそして「マイページ」の🎴キャラデッキで\nゲームに出す顔ぶれを自分で選べるんだ😊'
              : 'Playing earns you coins 🪙\nMeet new characters in the Shop tab!\nThen open 🎴 Character Deck in My Page\nto choose exactly who shows up 😊',
          illustration: '🛍🎴',
          gradient: const [Color(0xFFE8E3FF), Color(0xFFFFF6D8)],
        ),
        _TutorialPage(
          guideEmoji: '👧👦',
          guideName: ja ? 'ふたりから' : 'From us both',
          title: ja ? 'さあ、きたえよう！' : "Let's train!",
          body: ja
              ? 'じぶんの写真も登録できるよ📷\n本当に覚えたい人の顔で練習しよう！\nゲームで身につけたコツは\n明日出会う「あの人」にもきっと役立つ…！'
              : 'You can add your own photos too 📷\nPractice with the faces you truly\nneed to remember. The tricks you learn\nhere may help with real names tomorrow!',
          illustration: '🎉🏆',
          gradient: const [Color(0xFFFFE3EE), Color(0xFFD8F0FF)],
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
            child: Text(ja ? 'スキップ' : 'Skip',
                style: const TextStyle(fontWeight: FontWeight.w900)),
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
          Text(p.illustration, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 20),
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
                    Text(p.guideEmoji, style: const TextStyle(fontSize: 34)),
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
