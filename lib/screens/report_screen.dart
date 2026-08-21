import 'package:flutter/material.dart';

import '../l10n/meta_strings.dart';
import '../services/memory_stats.dart';
import '../services/player_profile.dart';
import '../widgets/banner_ad_slot.dart';
import '../widgets/themed_background.dart';
import '../services/app_analytics.dart';

/// 📊 Stats Report — CPU Battle / Name Call / Biz Card Quiz
/// measured by speed (⚡), accuracy (🎯), and retention (🧠).
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _stats = MemoryStats.instance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AppAnalytics.screen('report');
    _stats.load().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: const BannerAdSlot(placement: 'report'),
        appBar: AppBar(
          title: Text(m.ja ? '📊 成績レポート' : '📊 Stats Report'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _stats.isEmpty
                  ? _empty(m.ja)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      children: [
                        _overallCard(m.ja),
                        const SizedBox(height: 16),
                        Text(m.ja ? 'モード別' : 'By Mode',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        for (final mode in StatMode.values) ...[
                          _modeCard(mode, m.ja),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 8),
                        _explainCard(m.ja),
                        const SizedBox(height: 16),
                        _premiumCard(m.ja),
                      ],
                    ),
        ),
      ),
    );
  }

  /// 👑 プレミアムの案内カード。加入者には「加入中」を、未加入者には導線を出す。
  Widget _premiumCard(bool ja) {
    final active = PlayerProfile.instance.premiumActive;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EDFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF8A5AC2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            active
                ? (ja ? '👑 プレミアム加入中' : '👑 Premium active')
                : (ja ? '👑 プレミアムで詳細レポート' : '👑 Premium unlocks detailed reports'),
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF5B3E9E)),
          ),
          const SizedBox(height: 4),
          Text(
            active
                ? (ja
                    ? '記憶の伸び・モード別の詳細グラフをご利用いただけます。'
                    : 'Memory trends and detailed per-mode graphs are unlocked.')
                : (ja
                    ? '月額プランで、記憶の伸びのグラフや詳細な分析が見られます。'
                    : 'Subscribe monthly to see memory-trend graphs and deeper analysis.'),
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _empty(bool ja) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📊', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text(
                ja ? 'まだ記録がありません' : 'No records yet',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                ja
                    ? 'CPU対戦・なまえがお・名刺記憶を\nあそぶとここに成績がたまります。'
                    : 'Play CPU Battle, Name Call, or Biz Card Quiz\nand your stats will appear here.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 1.6),
              ),
            ],
          ),
        ),
      );

  Widget _overallCard(bool ja) {
    final answers = _stats.totalAnswers(null);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(ja ? 'ぜんぶ合わせて' : 'Overall',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(
              ja
                  ? '$answers問 / ${_stats.sessions(null)}回あそびました'
                  : '$answers Q / ${_stats.sessions(null)} games played',
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _metricTile('⚡', ja ? '速さ' : 'Speed', _speedText(null))),
              Expanded(child: _metricTile('🎯', ja ? '正確性' : 'Accuracy',
                  _pctText(_stats.accuracyPct(null)))),
              Expanded(child: _metricTile('🧠', ja ? '定着率' : 'Retained',
                  _pctText(_stats.retentionPct(null)))),
            ],
          ),
          const SizedBox(height: 12),
          _retentionBar(_stats.retentionPct(null), ja),
          const SizedBox(height: 10),
          Text(
            ja
                ? '🧠 おぼえた人：${_stats.retainedPeople}人'
                    '（会ったあとに名前を当てられた人）'
                : '🧠 People learned: ${_stats.retainedPeople}'
                    ' (face recognized after meeting)',
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _modeCard(StatMode mode, bool ja) {
    final answers = _stats.totalAnswers(mode);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(mode.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(mode.label(ja),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
              const Spacer(),
              Text(
                answers == 0
                    ? (ja ? 'まだ記録なし' : 'No records')
                    : (ja ? '$answers問' : '$answers Q'),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _metricTile('⚡', ja ? '速さ' : 'Speed', _speedText(mode))),
              Expanded(child: _metricTile('🎯', ja ? '正確性' : 'Accuracy',
                  _pctText(_stats.accuracyPct(mode)))),
              Expanded(child: _metricTile('🧠', ja ? '定着率' : 'Retained',
                  _pctText(_stats.retentionPct(mode)))),
            ],
          ),
          if (answers > 0 && _stats.retentionPct(mode) == null) ...[
            const SizedBox(height: 8),
            Text(
              ja
                  ? '定着率は、おぼえた人が出題されると出ます。'
                  : 'Retention appears when learned people are tested.',
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }

  Widget _explainCard(bool ja) => _card(
        color: const Color(0xFFF3F7FF),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ja ? '指標の見かた' : 'How to read',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            _ExplainRow('⚡',
                ja ? '速さ' : 'Speed',
                ja
                    ? '答えるまでにかかった時間の平均です。短いほど、思い出すのに迷っていません。'
                    : 'Average time to answer. Lower means less hesitation.'),
            const SizedBox(height: 8),
            _ExplainRow('🎯',
                ja ? '正確性' : 'Accuracy',
                ja
                    ? '出題に正解できた割合です。初対面の当てずっぽうも含みます。'
                    : '% of correct answers, including first-meeting guesses.'),
            const SizedBox(height: 8),
            _ExplainRow('🧠',
                ja ? '定着率' : 'Retention',
                ja
                    ? '名前をつけた人・おぼえタイムで見た人・名刺を受け取った人に、'
                        'あとで出題されて答えられた割合です。'
                        '一度も会っていない人への当てずっぽうは数えません。'
                    : '% recall for people you named, studied, or received cards from. '
                        'Guesses on never-met people don\'t count.'),
          ],
        ),
      );

  Widget _metricTile(String emoji, String label, String value) => Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      );

  Widget _retentionBar(int? pct, bool ja) {
    final v = (pct ?? 0) / 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: v,
            minHeight: 10,
            backgroundColor: Colors.black12,
            valueColor: AlwaysStoppedAnimation<Color>(
              pct == null
                  ? Colors.black26
                  : pct >= 80
                      ? const Color(0xFF2E9E5B)
                      : pct >= 50
                          ? const Color(0xFFE8A33D)
                          : const Color(0xFFD1495B),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          pct == null
              ? (ja ? 'おぼえた人が出題されると、定着率が出ます。'
                  : 'Retention shows when learned people are tested.')
              : pct >= 80
                  ? (ja ? 'よく定着しています。間をあけて会うともっと強くなります。'
                      : 'Well retained. Spaced review will make it even stronger.')
                  : pct >= 50
                      ? (ja ? 'あと一歩。まちがえた人をもう一度出してみましょう。'
                          : 'Almost there. Try reviewing the people you missed.')
                      : (ja ? 'まだ覚えきれていません。人数を減らすと定着しやすくなります。'
                          : 'Not yet retained. Try with fewer people.'),
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }

  String _pctText(int? pct) => pct == null ? '—' : '$pct%';

  String _speedText(StatMode? mode) {
    final ms = _stats.avgReactionMs(mode);
    if (ms == null || ms <= 0) return '—';
    return '${(ms / 1000).toStringAsFixed(1)}s';
  }

  Widget _card({required Widget child, Color? color}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: child,
      );
}

class _ExplainRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String body;
  const _ExplainRow(this.emoji, this.label, this.body);

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w900)),
                Text(body,
                    style: const TextStyle(fontSize: 12, height: 1.5)),
              ],
            ),
          ),
        ],
      );
}
