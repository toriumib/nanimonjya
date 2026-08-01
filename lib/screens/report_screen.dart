import 'package:flutter/material.dart';

import '../services/memory_stats.dart';
import '../widgets/banner_ad_slot.dart';
import '../widgets/themed_background.dart';

/// 📊 成績レポート。
///
/// CPU対戦・なまえコール・名刺記憶の3モードを、
/// **速さ（⚡）・正確性（🎯）・定着率（🧠）** の3指標で並べて見せる。
///
/// 速さと正確性だけだと反射神経の記録になってしまう。
/// このアプリの目的は人の名前を覚えることなので、
/// 「2回目以降に会ったときに答えられたか」＝定着率を主役の指標として置く。
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
    _stats.load().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: const BannerAdSlot(),
        appBar: AppBar(
          title: const Text('📊 成績レポート'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _stats.isEmpty
                  ? _empty()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      children: [
                        _overallCard(),
                        const SizedBox(height: 16),
                        const Text(
                          'モード別',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        for (final mode in StatMode.values) ...[
                          _modeCard(mode),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 8),
                        _explainCard(),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _empty() => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('📊', style: TextStyle(fontSize: 56)),
              SizedBox(height: 12),
              Text(
                'まだ記録がありません',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 8),
              Text(
                'CPU対戦・なまえコール・名刺記憶を\nあそぶとここに成績がたまります。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.6),
              ),
            ],
          ),
        ),
      );

  // ── 全体 ──

  Widget _overallCard() {
    final answers = _stats.totalAnswers(null);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('ぜんぶ合わせて',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('$answers問 / ${_stats.sessions(null)}回あそびました',
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _metricTile('⚡', '速さ', _speedText(null))),
              Expanded(
                  child: _metricTile('🎯', '正確性', _pctText(_stats.accuracyPct(null)))),
              Expanded(
                  child: _metricTile('🧠', '定着率', _pctText(_stats.retentionPct(null)))),
            ],
          ),
          const SizedBox(height: 12),
          _retentionBar(_stats.retentionPct(null)),
          const SizedBox(height: 10),
          Text(
            '🧠 おぼえた人：${_stats.retainedPeople}人'
            '（2回目以降に名前を当てられた人）',
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // ── モード別 ──

  Widget _modeCard(StatMode mode) {
    final answers = _stats.totalAnswers(mode);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(mode.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(mode.labelJa,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w900)),
              const Spacer(),
              Text(
                answers == 0 ? 'まだ記録なし' : '$answers問',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _metricTile('⚡', '速さ', _speedText(mode))),
              Expanded(
                  child: _metricTile('🎯', '正確性', _pctText(_stats.accuracyPct(mode)))),
              Expanded(
                  child: _metricTile('🧠', '定着率', _pctText(_stats.retentionPct(mode)))),
            ],
          ),
          if (answers > 0 && _stats.retentionPct(mode) == null) ...[
            const SizedBox(height: 8),
            const Text(
              '定着率は、同じ人がもう一度出題されると出ます。',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }

  // ── 説明 ──

  Widget _explainCard() => _card(
        color: const Color(0xFFF3F7FF),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('指標の見かた',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
            SizedBox(height: 10),
            _ExplainRow('⚡', '速さ',
                '答えるまでにかかった時間の平均です。短いほど、思い出すのに迷っていません。'),
            SizedBox(height: 8),
            _ExplainRow('🎯', '正確性',
                '出題に正解できた割合です。初対面の当てずっぽうも含みます。'),
            SizedBox(height: 8),
            _ExplainRow('🧠', '定着率',
                '一度会った人が、もう一度出題されたときに答えられた割合です。'
                    'まちがえた人の出し直しや、日をまたいだ復習が対象になります。'
                    '初対面の1回目は数えないので、当てずっぽうでは上がりません。'),
          ],
        ),
      );

  // ── パーツ ──

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

  Widget _retentionBar(int? pct) {
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
              ? '同じ人がもう一度出題されると、定着率が出ます。'
              : pct >= 80
                  ? 'よく定着しています。間をあけて会うともっと強くなります。'
                  : pct >= 50
                      ? 'あと一歩。まちがえた人をもう一度出してみましょう。'
                      : 'まだ覚えきれていません。人数を減らすと定着しやすくなります。',
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }

  String _pctText(int? pct) => pct == null ? '—' : '$pct%';

  String _speedText(StatMode? mode) {
    final ms = _stats.avgReactionMs(mode);
    if (ms == null || ms <= 0) return '—';
    return '${(ms / 1000).toStringAsFixed(1)}秒';
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
