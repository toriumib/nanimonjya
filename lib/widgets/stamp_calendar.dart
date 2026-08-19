import 'package:flutter/material.dart';

import 'app_style.dart';

import '../services/player_profile.dart';

/// 📅 ハンコカレンダー。
///
/// 『脳を鍛える大人のDSトレーニング』のハンコと同じ役目。
/// 「連続7日」という数字よりも、**空いたマスが目に見える**ほうが
/// 「明日は埋めよう」につながる。ラジオ体操のカードと同じ心理。
///
/// 今月ぶんだけを出す。何か月も遡れるようにすると、
/// 埋まっていない過去が目について、かえって続ける気を削ぐ。
class StampCalendar extends StatelessWidget {
  const StampCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    final ja = Localizations.localeOf(context).languageCode == 'ja';
    final p = PlayerProfile.instance;
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    // 日曜はじまり。1日が何曜から始まるかぶん、頭に空きマスを置く
    final leading = first.weekday % 7;
    final stamped = <int>[
      for (var d = 1; d <= daysInMonth; d++)
        if (p.hasStamp(DateTime(now.year, now.month, d))) d,
    ];

    final weekLabels =
        ja ? const ['日', '月', '火', '水', '木', '金', '土'] : const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ja
              ? '${now.month}月：${stamped.length} / $daysInMonth 日'
              : '${now.month}/${now.year}: ${stamped.length} of $daysInMonth days',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          ja
              ? 'ボーナスを受け取った日にハンコが押されます。すき間が少なくなるように。'
              : 'A stamp appears on each day you collect the bonus. Try to leave no gaps.',
          style: const TextStyle(fontSize: 11, color: AppStyle.textMuted),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final w in weekLabels)
              Expanded(
                child: Center(
                  child: Text(w,
                      style: const TextStyle(
                          fontSize: 10.5, color: AppStyle.textFaint)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 7,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: [
            for (var i = 0; i < leading; i++) const SizedBox.shrink(),
            for (var d = 1; d <= daysInMonth; d++)
              _cell(d, stamped.contains(d), d == now.day),
          ],
        ),
      ],
    );
  }

  Widget _cell(int day, bool stamped, bool isToday) {
    return Container(
      decoration: BoxDecoration(
        color: stamped ? const Color(0x33E9C87A) : AppStyle.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isToday
              ? const Color(0xFF3A7BD5)
              : (stamped ? const Color(0xFFE8663C) : const Color(0xFFE3E9F2)),
          width: isToday ? 2 : 1,
        ),
      ),
      child: Center(
        child: stamped
            // ハンコ。少し傾けると「押した」感じが出る
            ? Transform.rotate(
                angle: -0.18,
                child: const Text('🌸', style: TextStyle(fontSize: 15)),
              )
            : Text('$day',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: isToday ? FontWeight.w900 : FontWeight.normal,
                    color: isToday
                        ? const Color(0xFF3A7BD5)
                        : AppStyle.textFaint)),
      ),
    );
  }
}
