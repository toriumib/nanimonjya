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
          title: ja ? 'ナニモンジャへようこそ！' : 'Welcome to Nanimonja!',
          body: ja
              ? 'ナニモンジャは「名づけ神経衰弱」！\nはじめて出てきたキャラには、\nすきな名前をつけてあげてね💕'
              : 'Nanimonja is a name-memory game!\nWhen a new character appears,\ngive it any name you like 💕',
          illustration: '🃏✨',
          gradient: const [Color(0xFFFFE3EE), Color(0xFFFFF6D8)],
        ),
        _TutorialPage(
          guideEmoji: '👦',
          guideName: ja ? 'モンくん' : 'Mon',
          title: ja ? '見たことあるキャラが出たら…' : 'Seen this one before?',
          body: ja
              ? 'まえに名前をつけたキャラが出たら、\n名前を思い出していちばんに答えよう！\n正解すると場札をぜんぶゲット🎉'
              : 'When a named character returns,\nremember its name and answer first!\nCorrect answers win the field cards 🎉',
          illustration: '🧠⚡',
          gradient: const [Color(0xFFD8F0FF), Color(0xFFE8FFF7)],
        ),
        _TutorialPage(
          guideEmoji: '👧',
          guideName: ja ? 'ナナちゃん' : 'Nana',
          title: ja ? 'オンライン対戦のルール' : 'Online battle rules',
          body: ja
              ? '🥇 いちばんのり正解 → 場札を総取り！\n✅ あとから正解でも +1点\n💦 おてつきは −1点だから慎重に！\n⏰ 時間切れに気をつけてね'
              : '🥇 First correct → take all cards!\n✅ Later correct → +1 point\n💦 Wrong answer → −1, be careful!\n⏰ Watch the timer!',
          illustration: '⚔️🌐',
          gradient: const [Color(0xFFE8E3FF), Color(0xFFFFE3F0)],
        ),
        _TutorialPage(
          guideEmoji: '👦',
          guideName: ja ? 'モンくん' : 'Mon',
          title: ja ? 'コインをあつめよう！' : 'Collect coins!',
          body: ja
              ? 'あそぶとコインがもらえるよ🪙\n🎨 ホームのきせかえ\n🎵 クラシックBGM\n🐶 応援わんちゃん\n📣 チア応援団 がふえていく！'
              : 'Earn coins by playing 🪙\n🎨 Home themes\n🎵 Classical music\n🐶 Cheer dogs\n📣 Cheer squad — unlock them all!',
          illustration: '🪙🎁',
          gradient: const [Color(0xFFFFF6D8), Color(0xFFD8F6F0)],
        ),
        _TutorialPage(
          guideEmoji: '👧👦',
          guideName: ja ? 'ふたりから' : 'From us both',
          title: ja ? 'さあ、あそぼう！' : "Let's play!",
          body: ja
              ? '実績をあつめて称号をランクアップ！\nめざせ「ナニモンジャ王」👑\nいっしょにたのしもうね！'
              : 'Collect achievements, rank up titles,\nand become the Nanimonja King 👑\nHave fun!',
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
