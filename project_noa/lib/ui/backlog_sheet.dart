/// SPEC 3.3 — バックログ。名前つきで過去のテキストを遡れる。
library;

import 'package:flutter/material.dart';

import '../engine/scene_player.dart';
import '../systems/contamination.dart';

Future<void> showBacklogSheet(
  BuildContext context,
  List<BacklogEntry> entries, {
  /// SPEC 4.5 の濁り。0 なら正典のまま出す。
  double contamination = 0,

  /// 差し替え候補になる人名（姓）。
  List<String> names = const [],
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0B1020),
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (ctx, controller) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Row(
              children: [
                Text('📖 ログ',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFD7E2FF))),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF1D2A4A)),
          Expanded(
            child: entries.isEmpty
                ? const Center(
                    child: Text('まだ何も読んでいません',
                        style: TextStyle(color: Color(0xFF6A7280))))
                : ListView.separated(
                    controller: controller,
                    // 新しいものを下に置き、開いたら末尾が見える形にする。
                    // 上から読み直せるほうが「遡る」動作に合う。
                    padding: const EdgeInsets.all(16),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (ctx, i) {
                      final e = entries[i];
                      // ⚠️ 表示のときだけ濁らせる。e.text（正典）は触らない。
                      //    行番号を種にしているので、開き直しても同じ濁りかたになる。
                      final shown = contaminate(
                        e.text,
                        level: contamination,
                        names: names,
                        seed: i,
                      );
                      final dirty = isContaminated(e.text, shown);
                      final speaker = contaminate(
                        e.speaker,
                        level: contamination,
                        names: names,
                        seed: i + 500000,
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (e.speaker.isNotEmpty)
                            Text(speaker,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF5AD1FF))),
                          if (e.speaker.isNotEmpty) const SizedBox(height: 3),
                          Text(shown,
                              style: TextStyle(
                                  fontSize: 14,
                                  height: 1.7,
                                  // 濁った行は少し沈ませる。読めなくはしない。
                                  color: dirty
                                      ? const Color(0xFFB9A6A0)
                                      : const Color(0xFFE8ECF1))),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}
