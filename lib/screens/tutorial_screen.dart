import 'package:flutter/material.dart';

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
          title: ja ? '📣 なまえコール②：りょうどり！' : '📣 Name Call ②: Double take!',
          body: ja
              ? '本編ではランダムに2枚ずつ登場！\n2枚とも名前を思い出せたら\n「りょうどり」で2枚ゲット🎉\n片方だけなら1枚、両方外すと没収💦\nいちばん多くあつめた人の勝ち！'
              : 'Two random cards appear each round!\nRecall both names = double take,\nboth cards are yours 🎉\nOne name = one card. Miss both? Gone!\nMost cards wins!',
          illustration: '🃏🃏',
          gradient: const [Color(0xFFE8E3FF), Color(0xFFFFE3F0)],
        ),
        _TutorialPage(
          guideEmoji: '👦',
          guideName: ja ? 'モンくん' : 'Mon',
          title: ja ? '🃏 ペアさがし＆とっくん' : '🃏 Pair Hunt & Training',
          body: ja
              ? '「ペアさがし」タブは顔と名前の神経衰弱。\nCPU対戦で段位レーティングを上げよう📈\n「とっくん」タブでは記憶術ガイド付きの\n一人特訓で記憶力をきたえられるよ📚'
              : 'The Pair Hunt tab is face-name\nconcentration — beat the CPU to\nraise your rating 📈 The Training tab\nteaches real mnemonics as you play 📚',
          illustration: '🤖📚',
          gradient: const [Color(0xFFFFF6D8), Color(0xFFD8F6F0)],
        ),
        _TutorialPage(
          guideEmoji: '👧👦',
          guideName: ja ? 'ふたりから' : 'From us both',
          title: ja ? 'さあ、きたえよう！' : "Let's train!",
          body: ja
              ? 'コインできせかえ、実績で称号UP👑\nゲームで身につけたコツは\n明日出会う「あの人」の名前にも\nきっと役立つはず…！'
              : 'Earn coins, unlock titles 👑\nThe tricks you learn here may help\nwith real names tomorrow!',
          illustration: '🎉🏆',
          gradient: const [Color(0xFFFFE3EE), Color(0xFFD8F0FF)],
        ),
      ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ja = Localizations.localeOf(context).languageCode == 'ja';
    final pages = _pages(ja);
    final isLast = _page == pages.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(ja ? 'あそびかた' : 'How to Play'),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: pages.length,
              onPageChanged: (i) => setState(() => _page = i),
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
                        Navigator.pop(context);
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
