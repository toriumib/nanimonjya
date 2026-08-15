/// 📖 船内百科。用語集と、船内の謎。
///
/// 謎は3周目に全解禁（記憶率60%以上）。
/// 解禁前でも**問いだけは見せる**。気になるから本編で探すようになる。
library;

import 'package:flutter/material.dart';

import '../models/save_data.dart';
import '../systems/encyclopedia.dart';

class EncyclopediaScreen extends StatelessWidget {
  final SystemData system;

  /// いま遊んでいる周の到達フラグ。本編で自分で気づいた謎はここで開く。
  final Set<String> flags;

  const EncyclopediaScreen({
    super.key,
    required this.system,
    this.flags = const {},
  });

  @override
  Widget build(BuildContext context) {
    final allUnlocked = system.unlocks.mysteries;
    final openCount = kMysteries
        .where((m) =>
            isMysteryOpen(m, allUnlocked: allUnlocked, flags: flags))
        .length;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF05080F),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFFD7E2FF),
          title: const Text('船内百科',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          bottom: TabBar(
            labelColor: const Color(0xFFD4A24C),
            unselectedLabelColor: const Color(0xFF6A7280),
            indicatorColor: const Color(0xFFD4A24C),
            tabs: [
              const Tab(text: '📗 用語'),
              Tab(text: '🔎 謎  $openCount / ${kMysteries.length}'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _glossary(),
            _mysteries(allUnlocked),
          ],
        ),
      ),
    );
  }

  Widget _glossary() => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: kGlossary.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (ctx, i) {
          final e = kGlossary[i];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.term,
                  style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF5AD1FF))),
              const SizedBox(height: 4),
              Text(e.body,
                  style: const TextStyle(
                      fontSize: 13, height: 1.7, color: Color(0xFFE8ECF1))),
            ],
          );
        },
      );

  Widget _mysteries(bool allUnlocked) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!allUnlocked)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF12203C),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2B5CA5)),
              ),
              child: Text(
                '3周目に入り、記憶率が60%を超えると全部ひらきます。\n'
                'いまの最高記憶率 ${memoryRateLabel(system.maxMemoryRate)}'
                '／クリア ${system.cleared} 周\n'
                '——本編で自分で気づいたものは、それより先にひらきます。',
                style: const TextStyle(
                    fontSize: 11.5, height: 1.7, color: Color(0xFF9FB4D8)),
              ),
            ),
          for (final m in kMysteries) ...[
            _mysteryTile(m, allUnlocked),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 8),
          const Text(
            '解いても得はしません。解くと、誰かを少し好きになるだけです。',
            style: TextStyle(fontSize: 11, color: Color(0xFF6A7280)),
          ),
        ],
      );

  Widget _mysteryTile(ShipMystery m, bool allUnlocked) {
    final open = isMysteryOpen(m, allUnlocked: allUnlocked, flags: flags);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1020),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: open ? const Color(0xFFD4A24C) : const Color(0xFF1D2A4A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(open ? '🔎' : '🔒', style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(m.question,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        height: 1.5,
                        color: Color(0xFFE8ECF1))),
              ),
            ],
          ),
          if (open) ...[
            const SizedBox(height: 10),
            Text(m.answer,
                style: const TextStyle(
                    fontSize: 12.5, height: 1.8, color: Color(0xFFD4A24C))),
          ],
        ],
      ),
    );
  }
}
