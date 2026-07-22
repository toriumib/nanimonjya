import 'dart:math';

import 'package:flutter/material.dart';

/// ホーム背景の季節装飾。月に応じた絵文字がゆっくり舞い落ちる。
/// 画面全体に重ねて使う（タッチは透過）。
class SeasonalDecor extends StatefulWidget {
  final int count;
  const SeasonalDecor({super.key, this.count = 10});

  /// 月ごとの装飾絵文字セット。
  static List<String> emojisForMonth(int month) {
    switch (month) {
      case 3:
      case 4:
        return ['🌸', '🌸', '🌷', '✨']; // 春: 桜
      case 5:
      case 6:
        return ['🍃', '🌿', '☔', '✨']; // 初夏〜梅雨
      case 7:
      case 8:
        return ['🎐', '⭐', '🌻', '✨']; // 夏
      case 9:
      case 10:
      case 11:
        return ['🍁', '🍂', '🌰', '✨']; // 秋: 紅葉
      case 12:
        return ['❄️', '⛄', '🎄', '✨']; // 12月: クリスマス
      case 1:
        return ['❄️', '⛄', '🎍', '✨']; // 正月
      default:
        return ['❄️', '⛄', '💎', '✨']; // 冬
    }
  }

  @override
  State<SeasonalDecor> createState() => _SeasonalDecorState();
}

class _Particle {
  final String emoji;
  final double x; // 0..1 横位置
  final double size;
  final double phase; // 0..1 開始タイミングのずらし
  final double drift; // 横ゆれ幅
  final double speed; // 落下速度係数

  _Particle({
    required this.emoji,
    required this.x,
    required this.size,
    required this.phase,
    required this.drift,
    required this.speed,
  });
}

class _SeasonalDecorState extends State<SeasonalDecor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    final emojis = SeasonalDecor.emojisForMonth(DateTime.now().month);
    _particles = List.generate(widget.count, (i) {
      return _Particle(
        emoji: emojis[i % emojis.length],
        x: rng.nextDouble(),
        size: 14 + rng.nextDouble() * 14,
        phase: rng.nextDouble(),
        drift: 12 + rng.nextDouble() * 22,
        speed: 0.7 + rng.nextDouble() * 0.6,
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final size = MediaQuery.of(context).size;
          return Stack(
            children: [
              for (final p in _particles) _buildParticle(p, size),
            ],
          );
        },
      ),
    );
  }

  Widget _buildParticle(_Particle p, Size size) {
    // 0..1 を位相ずらし＆速度つきでループ
    final t = ((_controller.value * p.speed + p.phase) % 1.0);
    final y = t * (size.height + 60) - 40; // 画面上から下へ
    final sway = sin(t * 2 * pi * 2 + p.phase * 2 * pi) * p.drift;
    // 出現直後と消える直前はフェード
    final opacity =
        (t < 0.1 ? t / 0.1 : (t > 0.9 ? (1 - t) / 0.1 : 1.0)) * 0.55;
    return Positioned(
      left: p.x * size.width + sway,
      top: y,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: sin(t * 2 * pi + p.phase * 6) * 0.4,
          child: Text(p.emoji, style: TextStyle(fontSize: p.size)),
        ),
      ),
    );
  }
}
