import 'dart:math';

import 'package:flutter/material.dart';

/// ゲームらしい質感のUI部品集（クラロワ等の「立体・光沢・縁取り」の文法）。
/// - JuicyButton: 押すと沈む3Dベベルボタン
/// - OutlinedText: 縁取り（ストローク）つき文字
/// - SunRays: ロゴ背後などに置く回転する後光

Color _darken(Color c, [double amount = .32]) =>
    Color.lerp(c, Colors.black, amount)!;

/// 押すと「沈む」立体ボタン。下側に濃い色のエッジ（厚み）があり、
/// タップ中はエッジが薄くなって全体が下がる＝物理ボタンの感触。
class JuicyButton extends StatefulWidget {
  final VoidCallback? onTap;
  final List<Color> colors; // 上→下のグラデーション
  final Color? edgeColor; // 下エッジ色（省略時は自動で濃く）
  final double height;
  final double radius;
  final Widget child;

  const JuicyButton({
    super.key,
    required this.onTap,
    required this.colors,
    required this.child,
    this.edgeColor,
    this.height = 52,
    this.radius = 16,
  });

  @override
  State<JuicyButton> createState() => _JuicyButtonState();
}

class _JuicyButtonState extends State<JuicyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final edge = widget.edgeColor ?? _darken(widget.colors.last);
    const edgeH = 4.0;
    final disabled = widget.onTap == null;
    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            },
      onTapCancel:
          disabled ? null : () => setState(() => _pressed = false),
      child: Opacity(
        opacity: disabled ? 0.55 : 1,
        child: SizedBox(
          height: widget.height,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 70),
            margin: EdgeInsets.only(top: _pressed ? edgeH - 1 : 0),
            decoration: BoxDecoration(
              color: edge,
              borderRadius: BorderRadius.circular(widget.radius),
              boxShadow: [
                BoxShadow(
                  color: edge.withValues(alpha: 0.45),
                  blurRadius: _pressed ? 3 : 8,
                  offset: Offset(0, _pressed ? 1 : 4),
                ),
              ],
            ),
            padding: EdgeInsets.only(bottom: _pressed ? 1 : edgeH),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: widget.colors,
                ),
                borderRadius: BorderRadius.circular(widget.radius - 1),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              // 上半分にうっすら光沢
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.radius - 1),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [
                    Colors.white.withValues(alpha: 0.22),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Center(child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}

/// 縁取り（ストローク）つきテキスト。ゲームロゴや見出しのステッカー感を出す。
class OutlinedText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double strokeWidth;
  final Color strokeColor;
  final TextAlign textAlign;
  final int? maxLines;

  const OutlinedText(
    this.text, {
    super.key,
    required this.style,
    this.strokeWidth = 6,
    this.strokeColor = Colors.white,
    this.textAlign = TextAlign.center,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          textAlign: textAlign,
          maxLines: maxLines,
          style: style.copyWith(
            color: null,
            shadows: const [],
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..strokeJoin = StrokeJoin.round
              ..color = strokeColor,
          ),
        ),
        Text(text, textAlign: textAlign, maxLines: maxLines, style: style),
      ],
    );
  }
}

/// ロゴなどの背後でゆっくり回転する「後光」。
class SunRays extends StatefulWidget {
  final double size;
  final Color color;
  final int rayCount;

  const SunRays({
    super.key,
    required this.size,
    this.color = Colors.white,
    this.rayCount = 12,
  });

  @override
  State<SunRays> createState() => _SunRaysState();
}

class _SunRaysState extends State<SunRays>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 36),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RotationTransition(
        turns: _controller,
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: _RaysPainter(color: widget.color, rays: widget.rayCount),
        ),
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  final Color color;
  final int rays;
  _RaysPainter({required this.color, required this.rays});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final sweep = 2 * pi / (rays * 2);
    // 中心から外へ薄くなるグラデーションの扇形を交互に描く
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.30),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    for (var i = 0; i < rays; i++) {
      final start = i * sweep * 2;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(Rect.fromCircle(center: center, radius: radius), start,
            sweep, false)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RaysPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.rays != rays;
}
