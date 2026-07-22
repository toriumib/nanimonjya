import 'package:flutter/material.dart';

/// 0（または任意の開始値）から目標値まで数字がカウントアップして表示されるテキスト。
/// 結果画面のスコア・レーティング・コイン表示などに使う。
class CountUp extends StatelessWidget {
  final int value;
  final TextStyle style;
  final Duration duration;
  final int begin;
  final String prefix;
  final String suffix;
  final bool signed; // 正の値に + をつける（レーティング増減など）

  const CountUp(
    this.value, {
    super.key,
    required this.style,
    this.duration = const Duration(milliseconds: 900),
    this.begin = 0,
    this.prefix = '',
    this.suffix = '',
    this.signed = false,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: begin, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final sign = signed && v > 0 ? '+' : '';
        return Text('$prefix$sign$v$suffix', style: style);
      },
    );
  }
}
