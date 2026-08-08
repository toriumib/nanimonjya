/// 📒 台帳（SPEC 5）。17人 × 5項目の表。
///
/// **これが本作の「攻略一覧」**。
/// 正解したセルは値が埋まり、まだのセルは ??? のまま。
/// どこが空いているかがひと目で分かるので、
/// 「あと誰の何を覚えればいいか」がそのまま次の目標になる。
///
/// 常時開ける（SPEC 5）。隠しても、紙にメモされるだけなので。
library;

import 'package:flutter/material.dart';

import '../models/noah_field.dart';
import '../models/save_data.dart';
import '../systems/memory_store.dart';

class LedgerScreen extends StatelessWidget {
  final NoahCast cast;
  final MemoryStore memory;

  /// 好感度。誰と親しいかも、同じ表で見えたほうが早い。
  final Map<String, int> affection;

  const LedgerScreen({
    super.key,
    required this.cast,
    required this.memory,
    this.affection = const {},
  });

  @override
  Widget build(BuildContext context) {
    final total = totalPairsFor(cast.all.length);
    final rate = memoryRate(correct: memory.correctCount, totalPairs: total);

    return Scaffold(
      backgroundColor: const Color(0xFF05080F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFFD7E2FF),
        title: const Text('台帳',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Text(
                '${memory.correctCount} / $total　${memoryRateLabel(rate)}',
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF7DFFB0)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _legend(),
          const Divider(height: 1, color: Color(0xFF1D2A4A)),
          Expanded(
            // 17行 × 5列。横も縦もはみ出すので、両方向にスクロールさせる。
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _table(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                '埋まっているのが、思い出せたところ。\n'
                '「？」のままの列が、次に会うときの宿題になる。',
                style: TextStyle(
                    fontSize: 11.5, height: 1.6, color: Color(0xFF9FB4D8)),
              ),
            ),
            _chip('覚えた', const Color(0xFF7DFFB0)),
            const SizedBox(width: 6),
            _chip('混ざった', const Color(0xFFE0A44C)),
          ],
        ),
      );

  Widget _chip(String label, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.withValues(alpha: 0.6)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w900, color: c)),
      );

  Widget _table() {
    const nameW = 116.0;
    const cellW = 132.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 見出し
        Row(
          children: [
            const SizedBox(width: nameW, height: 34),
            for (final f in NoahField.values)
              SizedBox(
                width: cellW,
                height: 34,
                child: Center(
                  child: Text(f.labelJa,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF9FB4D8))),
                ),
              ),
          ],
        ),
        for (final c in cast.all) _row(c, nameW, cellW),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _row(NoahCharacter c, double nameW, double cellW) {
    final aff = affection[c.id] ?? 0;
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF12203C))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: nameW,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  Text(c.emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ⚠️ 名前そのものが出題対象なので、
                        //    覚えていない人は名前も伏せる。
                        //    ここで見えてしまうと「名前」の列が無意味になる。
                        Text(
                          memory.knows(c, NoahField.name) ? c.name : '？？？',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: memory.knows(c, NoahField.name)
                                ? const Color(0xFFE8ECF1)
                                : const Color(0xFF5A6472),
                          ),
                        ),
                        if (aff > 0)
                          Text('♥ $aff',
                              style: const TextStyle(
                                  fontSize: 9.5, color: Color(0xFFE88A8A))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final f in NoahField.values) _cell(c, f, cellW),
        ],
      ),
    );
  }

  Widget _cell(NoahCharacter c, NoahField f, double w) {
    final known = memory.knows(c, f);
    final wrong = memory.contaminated[c.memoryKey(f)];

    final (text, color) = switch ((known, wrong)) {
      (true, _) => (c.valueOf(f), const Color(0xFF7DFFB0)),
      // まちがえた場合は「何と混ざったか」を見せる。
      // ただの空欄より、混線しているという事実のほうが手がかりになる。
      (false, final String v) => (v, const Color(0xFFE0A44C)),
      _ => ('？', const Color(0xFF3A4453)),
    };

    return Container(
      width: w,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFF12203C))),
      ),
      child: Center(
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, height: 1.4, color: color),
        ),
      ),
    );
  }
}
