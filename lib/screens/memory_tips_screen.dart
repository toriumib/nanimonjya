import 'package:flutter/material.dart';
import '../l10n/memory_tips.dart';
import '../l10n/meta_strings.dart';
import '../services/app_analytics.dart';

/// 「名前の覚え方」記憶術の読み物画面。
/// チュートリアルと同じカード式PageViewで、タグ付け法・映像化・場所法などを紹介する。
class MemoryTipsScreen extends StatefulWidget {
  const MemoryTipsScreen({super.key});

  @override
  State<MemoryTipsScreen> createState() => _MemoryTipsScreenState();
}

class _MemoryTipsScreenState extends State<MemoryTipsScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    AppAnalytics.screen('memory_tips');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ja = Localizations.localeOf(context).languageCode == 'ja';
    final m = MetaStrings.of(context);
    const pages = kMemoryTipPages;
    final isLast = _page == pages.length - 1;

    return Scaffold(
      appBar: AppBar(title: Text(m.memoryTipsTitle)),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: pages.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) => _buildPage(pages[i], ja),
            ),
          ),
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
                            ? const Color(0xFF3A7BD5)
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
                      backgroundColor: const Color(0xFF3A7BD5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    child: Text(
                      isLast ? m.memoryTipsDone : (ja ? 'つぎへ →' : 'Next →'),
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

  Widget _buildPage(MemoryTipPage p, bool ja) {
    return SingleChildScrollView(
      child: Container(
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
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(p.emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    p.title(ja),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF3A7BD5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    p.body(ja),
                    style: const TextStyle(fontSize: 14.5, height: 1.7),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
