import 'package:flutter/material.dart';
import '../l10n/memory_tips.dart';
import '../l10n/meta_strings.dart';
import '../widgets/app_style.dart';
import 'article_library_screen.dart';
import '../services/app_analytics.dart';
import '../services/sfx.dart';
import '../widgets/banner_ad_slot.dart';

/// 「名前の覚え方」記憶術の読み物画面。
/// チュートリアルと同じカード式PageViewで、タグ付け法・映像化・場所法・
/// 研究にもとづくコツ（出典つき）・記憶と意識の読み物を紹介する。
///
/// [embedded] が true のときは下部タブの1つとして表示される想定で、
/// 戻るボタンを出さず、最後のページでも画面を閉じない。
class MemoryTipsScreen extends StatefulWidget {
  final bool embedded;

  const MemoryTipsScreen({super.key, this.embedded = false});

  @override
  State<MemoryTipsScreen> createState() => _MemoryTipsScreenState();
}

class _MemoryTipsScreenState extends State<MemoryTipsScreen> {
  /// 全話を1本のスクロールで読めるようにした。目次からはこのスクロールを
  /// 該当セクションまでジャンプさせる。各話の先頭に key を付けて特定する。
  final List<GlobalKey> _sectionKeys =
      List.generate(kMemoryTipPages.length, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    AppAnalytics.screen('memory_tips');
    AppAnalytics.readOpen('memory_tips');
  }

  /// 📑 目次を開く。選んだ話へその場で飛ぶ（スクロール位置までジャンプ）。
  Future<void> _openContents(bool ja) async {
    Sfx.instance.pop();
    const pages = kMemoryTipPages;
    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (ctx, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  const Text('📑', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(ja ? '目次' : 'Contents',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w900)),
                  const Spacer(),
                  Text(ja ? '全${pages.length}話' : '${pages.length} articles',
                      style: const TextStyle(
                          fontSize: 12.5, color: Colors.black54)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: pages.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final p = pages[i];
                  return ListTile(
                    leading: Text(p.emoji,
                        style: const TextStyle(fontSize: 22)),
                    title: Text(
                      ja ? p.titleJa : p.titleEn,
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w600),
                    ),
                    trailing: Text('${i + 1}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black38)),
                    onTap: () => Navigator.pop(ctx, i),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    // 該当セクションまでスクロールで跳ぶ（アニメーションで送ると長いので直接）。
    final ctx = _sectionKeys[picked].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 400));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ja = Localizations.localeOf(context).languageCode == 'ja';
    final m = MetaStrings.of(context);
    const pages = kMemoryTipPages;

    return Scaffold(
      bottomNavigationBar: const BannerAdSlot(placement: 'memory_tips'),
      appBar: AppBar(
        title: Text(m.memoryTipsTitle),
        // タブとして表示するときは戻る矢印を出さない
        automaticallyImplyLeading: !widget.embedded,
        actions: [
          // 📑 目次。全話を縦スクロールで読めるので、読みたい話へ直接飛ぶ。
          IconButton(
            tooltip: ja ? '目次' : 'Contents',
            icon: const Icon(Icons.list_alt_rounded),
            onPressed: () => _openContents(ja),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 全話を1本に連結。目次から各話の先頭へジャンプできる。
            for (var i = 0; i < pages.length; i++)
              KeyedSubtree(
                key: _sectionKeys[i],
                child: _buildPage(pages[i], ja),
              ),
            // 📚 最後に、コインで読める記事の一覧へ。
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Sfx.instance.pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ArticleLibraryScreen()),
                    );
                  },
                  icon: const Icon(Icons.menu_book_rounded),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                  label: Text(m.articleMoreButton),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(MemoryTipPage p, bool ja) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // 読み物は文字が主役。色のグラデーションと白い太枠をやめ、
        // 白地＋細い枠にして、本文の可読性に場所を譲る。
        color: AppStyle.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyle.line, width: 1),
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
                // 📖 読みやすさ: 本文をそのまま流すと、出典や注意書きまで
                //    同じ見た目で続いて読みにくい。段落ごとに分け、
                //    **強調**・🔬出典・⚠️注意 を書式で区別する。
                ..._paragraphs(p.body(ja)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 本文を段落に割り、役割ごとに見た目を変えて読みやすくする。
  ///
  /// - `🔬 出典:` … 小さめ・グレーの引用ブロック（本文と混ざらないように）
  /// - `⚠️` … 薄い黄色の注意ブロック
  /// - `**強調**` … 太字（記事内で1〜2箇所だけ使う想定）
  /// - 箇条書き（・/ ①〜）… 行間を詰めて塊に見せる
  List<Widget> _paragraphs(String body) {
    final blocks = body.split('\n\n');
    return [
      for (final b in blocks)
        if (b.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _block(b.trim()),
          ),
    ];
  }

  Widget _block(String text) {
    final isSource = text.startsWith('🔬');
    final isWarning = text.startsWith('⚠️');
    if (isSource || isWarning) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: isSource ? const Color(0xFFF1F4F8) : const Color(0xFFFFF7E0),
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(
              color: isSource
                  ? const Color(0xFF9DBBD8)
                  : const Color(0xFFE6B54A),
              width: 3,
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: isSource ? 11.5 : 12.5,
            height: 1.6,
            color: isSource ? Colors.black54 : const Color(0xFF7A5A00),
          ),
        ),
      );
    }
    return _RichBody(text: text);
  }
}

/// `**強調**` を太字にして描くだけの本文。
class _RichBody extends StatelessWidget {
  final String text;
  const _RichBody({required this.text});

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final re = RegExp(r'\*\*(.+?)\*\*');
    var last = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      spans.add(TextSpan(
        text: m.group(1),
        style: const TextStyle(
            fontWeight: FontWeight.w900, color: Color(0xFF2B5CA5)),
      ));
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return RichText(
      text: TextSpan(
        style: const TextStyle(
            fontSize: 14.5, height: 1.75, color: Color(0xFF222222)),
        children: spans,
      ),
    );
  }
}
