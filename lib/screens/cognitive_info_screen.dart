import 'package:flutter/material.dart';
import '../l10n/meta_strings.dart';

/// 一人特訓モード・トレーニングレポートから開ける「認知トレーニングについて」説明画面。
/// 査読研究の一般的な知見を紹介するが、効果を断定・保証する表現は避けている。
class CognitiveInfoScreen extends StatelessWidget {
  const CognitiveInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(m.cognitiveInfoTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              m.cognitiveInfoIntro,
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 20),
            _section(
              emoji: '🧠',
              title: m.cognitiveMemoryTitle,
              body: m.cognitiveMemoryBody,
              color: const Color(0xFFEAF3FF),
              accent: const Color(0xFF3A7BD5),
            ),
            _section(
              emoji: '👀',
              title: m.cognitiveAttentionTitle,
              body: m.cognitiveAttentionBody,
              color: const Color(0xFFFFF3E0),
              accent: const Color(0xFFE08A2E),
            ),
            _section(
              emoji: '⚡',
              title: m.cognitiveSpeedTitle,
              body: m.cognitiveSpeedBody,
              color: const Color(0xFFFFF0F6),
              accent: const Color(0xFFE0447C),
            ),
            _section(
              emoji: '🧩',
              title: m.cognitiveExecutiveTitle,
              body: m.cognitiveExecutiveBody,
              color: const Color(0xFFEFFCF3),
              accent: const Color(0xFF2E9E52),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCCCCCC)),
              ),
              child: Text(
                m.cognitiveDisclaimer,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.6,
                  color: Color(0xFF666666),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({
    required String emoji,
    required String title,
    required String body,
    required Color color,
    required Color accent,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }
}
