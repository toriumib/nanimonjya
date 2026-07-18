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
          title: ja ? 'まずは「おぼえタイム」！' : 'First: Memorize time!',
          body: ja
              ? 'ゲームがはじまると、みんなの\n顔と名前がしばらく表示されるよ。\n「まゆげが太い→高橋さん」みたいに\n特徴をタグにして覚えるのがコツ🏷️'
              : "Each game starts by showing\neveryone's face and name.\nTag each face with a feature —\n“thick brows → Takahashi” 🏷️",
          illustration: '👀📇',
          gradient: const [Color(0xFFD8F0FF), Color(0xFFE8FFF7)],
        ),
        _TutorialPage(
          guideEmoji: '👧',
          guideName: ja ? 'ナナちゃん' : 'Nana',
          title: ja ? 'カードをめくってペア当て！' : 'Flip cards & match pairs!',
          body: ja
              ? 'カードが裏返ってシャッフル！\n顔カードと名前カードをめくって、\n正しい組み合わせならペアGET🎉\n少ない手数でそろえるほどハイスコア！'
              : 'The cards flip over — now match\na face card to its name card.\nCorrect pair = yours! 🎉\nFewer moves = higher score!',
          illustration: '🧠⚡',
          gradient: const [Color(0xFFE8E3FF), Color(0xFFFFE3F0)],
        ),
        _TutorialPage(
          guideEmoji: '👦',
          guideName: ja ? 'モンくん' : 'Mon',
          title: ja ? 'CPU対戦と記憶術トレーニング' : 'CPU battles & mnemonics',
          body: ja
              ? '🤖 CPUと交代でめくってペア数勝負！\n勝つと段位レーティングがUP📈\n📚「記憶術トレーニング」なら\nタグ付けのコツをガイド付きで練習できるよ'
              : '🤖 Take turns vs the CPU —\nmost pairs wins & your rating grows 📈\n📚 Mnemonic Training guides you\nthrough real memory techniques!',
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
