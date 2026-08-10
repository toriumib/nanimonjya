import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/meta_strings.dart';
import '../models/story.dart';
import '../services/player_profile.dart';
import '../services/sfx.dart';
import '../widgets/banner_ad_slot.dart';
import '../services/app_analytics.dart';

/// 📖 ストーリーモード。
///
/// タップで1行ずつ進む読み物形式。ゲームの合間に「なぜ覚えられないのか」を
/// 物語で受け取れるようにして、続きが気になるから戻ってくる、を作る。
///
/// 途中で閉じても続きから読めるよう、話ごとに読んだ行数を保存する。
class StoryScreen extends StatefulWidget {
  final StoryChapter chapter;
  const StoryScreen({super.key, required this.chapter});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

/// 読み終えた話のID（'ch1' など）。
const String kStoryDoneKey = 'storyDoneChapters';

/// 話ごとの読んだ行数（'storyLine_ch1'）。
String storyLineKey(String chapterId) => 'storyLine_$chapterId';

Future<Set<String>> readStoryDone() async {
  final p = await SharedPreferences.getInstance();
  return (p.getStringList(kStoryDoneKey) ?? []).toSet();
}

class _StoryScreenState extends State<StoryScreen> {
  int _index = 0;
  bool _finished = false;
  bool _rewarded = false;

  @override
  void initState() {
    super.initState();
    AppAnalytics.screen('story_legacy');
    SharedPreferences.getInstance().then((p) {
      final saved = p.getInt(storyLineKey(widget.chapter.id)) ?? 0;
      if (!mounted || saved <= 0) return;
      setState(() => _index = saved.clamp(0, widget.chapter.scenes.length - 1));
    }).catchError((_) {});
  }

  Future<void> _next() async {
    if (_finished) return;
    Sfx.instance.pop();
    if (_index + 1 < widget.chapter.scenes.length) {
      setState(() => _index += 1);
      final p = await SharedPreferences.getInstance();
      await p.setInt(storyLineKey(widget.chapter.id), _index);
      return;
    }
    setState(() => _finished = true);
    await _grantReward();
  }

  Future<void> _grantReward() async {
    if (_rewarded) return;
    _rewarded = true;
    final p = await SharedPreferences.getInstance();
    final done = (p.getStringList(kStoryDoneKey) ?? []).toSet();
    // ごほうびは1話につき1回だけ（読み直しでは配らない）
    final first = done.add(widget.chapter.id);
    await p.setStringList(kStoryDoneKey, done.toList());
    await p.setInt(storyLineKey(widget.chapter.id), 0); // 読み切ったので巻き戻す
    if (first && widget.chapter.reward > 0) {
      await PlayerProfile.instance.grantBonusCoins(widget.chapter.reward);
      Sfx.instance.coin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    final scene = widget.chapter.scenes[_index];
    return Scaffold(
      backgroundColor: const Color(0xFF1B2233),
      bottomNavigationBar: const BannerAdSlot(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
            m.ja ? '第${widget.chapter.number}話  ${widget.chapter.title}'
                : 'Ch.${widget.chapter.number}  ${widget.chapter.title}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
      ),
      body: GestureDetector(
        onTap: _next,
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Column(
            children: [
              LinearProgressIndicator(
                value: (_index + 1) / widget.chapter.scenes.length,
                minHeight: 3,
                backgroundColor: Colors.white12,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFFFF4FA3)),
              ),
              Expanded(child: _stage(scene)),
              _finished ? _finishCard(m.ja) : _textBox(scene, m.ja),
            ],
          ),
        ),
      ),
    );
  }

  /// 立ち絵。まだ専用の絵が無いので、ホームの応援キャラを流用する。
  Widget _stage(StoryScene scene) {
    final asset = switch (scene.speaker) {
      Speaker.nana => 'assets/images/supporters/cheer_girl.svg',
      Speaker.hana => 'assets/images/supporters/cheer_girl2.svg',
      _ => null,
    };
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: asset == null
            ? const SizedBox(key: ValueKey('none'))
            : SvgPicture.asset(asset,
                key: ValueKey(asset), width: 150, height: 150),
      ),
    );
  }

  Widget _textBox(StoryScene scene, bool ja) {
    final name = switch (scene.speaker) {
      Speaker.nana => 'ナナ',
      Speaker.hana => 'ハナ',
      Speaker.other => scene.who,
      Speaker.narration => '',
    };
    final color = switch (scene.speaker) {
      Speaker.nana => const Color(0xFFFF8FC0),
      Speaker.hana => const Color(0xFF6FD3E8),
      _ => Colors.white70,
    };
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (name.isNotEmpty)
            Text(name,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: color.withValues(alpha: 1.0))),
          const SizedBox(height: 4),
          Text(
            scene.text,
            style: TextStyle(
              fontSize: 16,
              height: 1.7,
              // 地の文は少し落ち着かせて、セリフと区別できるようにする
              fontStyle: scene.speaker == Speaker.narration
                  ? FontStyle.italic
                  : FontStyle.normal,
              color: scene.speaker == Speaker.narration
                  ? Colors.black87
                  : Colors.black,
            ),
          ),
          if (scene.source != null) ...[
            const SizedBox(height: 8),
            Text(ja ? '出典: ${scene.source}' : 'Source: ${scene.source}',
                style:
                    const TextStyle(fontSize: 10.5, color: Colors.black45)),
          ],
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(ja ? 'タップでつづき ▶' : 'Tap to continue ▶',
                style: const TextStyle(fontSize: 11, color: Colors.black38)),
          ),
        ],
      ),
    );
  }

  Widget _finishCard(bool ja) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.chapter.outro,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15, height: 1.7, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Text('🪙 +${widget.chapter.reward}',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF8A6A1E))),
          const SizedBox(height: 4),
          Text(
            widget.chapter.number >= kStoryChapterCount
                ? (ja ? 'つづきは準備中です。' : 'More chapters coming soon.')
                : (ja ? 'つぎの話が読めます。' : 'The next chapter is ready.'),
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
            ),
            child: Text(ja ? 'とじる' : 'Close'),
          ),
        ],
      ),
    );
  }
}

/// 📚 話の一覧。読んだ話には印がつく。
class StoryListScreen extends StatefulWidget {
  const StoryListScreen({super.key});

  @override
  State<StoryListScreen> createState() => _StoryListScreenState();
}

class _StoryListScreenState extends State<StoryListScreen> {
  Set<String> _done = {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final d = await readStoryDone();
    if (mounted) setState(() => _done = d);
  }

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    return Scaffold(
      appBar: AppBar(
          title: Text(m.ja ? '📖 ストーリー' : '📖 Story')),
      bottomNavigationBar: const BannerAdSlot(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            m.ja
                ? '名前が覚えられないナナと、同期のハナの話です。'
                    '読むだけで、覚えるコツが少しずつ分かります。'
                : 'A story about Nana, who struggles with names, and her colleague Hana. '
                    'As you read, you\'ll pick up memory tips along the way.',
            style: const TextStyle(fontSize: 12.5, height: 1.6, color: Colors.black54),
          ),
          const SizedBox(height: 14),
          for (final c in kStoryChapters)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: Text(_done.contains(c.id) ? '📗' : '📘',
                    style: const TextStyle(fontSize: 26)),
                title: Text(
                    m.ja ? '第${c.number}話  ${c.title}'
                        : 'Ch.${c.number}  ${c.title}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w900)),
                subtitle: Text(
                    _done.contains(c.id)
                        ? (m.ja ? '読了' : 'Read')
                        : '🪙+${c.reward}',
                    style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  Sfx.instance.pop();
                  await Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                        builder: (_) => StoryScreen(chapter: c)),
                  );
                  await _reload();
                },
              ),
            ),
          const SizedBox(height: 8),
          Text(
            m.ja ? 'つづきは順番に増えていきます。'
                : 'More chapters will be added in order.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.black38),
          ),
        ],
      ),
    );
  }
}
