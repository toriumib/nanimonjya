import 'package:flutter/material.dart';

import '../models/avatar.dart';

/// 🧑‍🎨 アバターの顔を描くウィジェット。
///
/// 画像素材は使わず、すべてコードで描く。
/// パーツを画像で持つとファイルが増えてアプリが重くなるうえ、
/// 組み合わせを増やすたびに素材を用意しないといけない。
/// 図形で描けば、パーツを足すのはコードを足すだけで済む。
class AvatarView extends StatelessWidget {
  final Avatar avatar;
  final double size;
  final double radius;

  /// 背景（顔の後ろの丸）を描くか。一覧では付けたほうが見やすい。
  final bool background;

  const AvatarView({
    super.key,
    required this.avatar,
    required this.size,
    this.radius = 12,
    this.background = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _AvatarPainter(avatar, background: background),
        ),
      ),
    );
  }
}

// ── 配色 ──

const List<Color> _skinColors = [
  Color(0xFFFFE0C4),
  Color(0xFFF6D0AC),
  Color(0xFFE8BC94),
  Color(0xFFC99B72),
  Color(0xFF9A6B4A),
];

const List<Color> _hairColors = [
  Color(0xFF2B2118),
  Color(0xFF4A3324),
  Color(0xFF7A5230),
  Color(0xFFD9A94C),
  Color(0xFF8C4A2F),
  Color(0xFF9E9E9E),
];

const Color _lineColor = Color(0xFF3A2E26);

class _AvatarPainter extends CustomPainter {
  final Avatar a;
  final bool background;

  _AvatarPainter(this.a, {this.background = true});

  @override
  void paint(Canvas canvas, Size size) {
    // 100×100 の座標で描いて、最後に実サイズへ拡大する。
    // こうしておくとどの大きさで表示しても同じ絵になる。
    final s = size.shortestSide / 100.0;
    canvas.scale(s, s);

    final skin = _skinColors[a.skin % _skinColors.length];
    final hairColor = _hairColors[a.hairColor % _hairColors.length];

    if (background) {
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 100, 100),
        Paint()..color = const Color(0xFFEFF4FB),
      );
    }

    _drawBackHair(canvas, hairColor);
    _drawFace(canvas, skin);
    _drawEars(canvas, skin);
    _drawFrontHair(canvas, hairColor);
    _drawEyebrows(canvas);
    _drawEyes(canvas);
    _drawNose(canvas);
    _drawMouth(canvas);
    _drawBeard(canvas, hairColor);
    _drawGlasses(canvas);
    _drawMole(canvas);
  }

  // ── 輪郭 ──

  /// 顔の外形。輪郭ごとに幅と角の丸みを変える。
  RRect _faceRect() {
    switch (a.faceShape) {
      case 1: // まる型
        return RRect.fromRectAndRadius(
            const Rect.fromLTWH(24, 22, 52, 56), const Radius.circular(26));
      case 2: // 四角い
        return RRect.fromRectAndRadius(
            const Rect.fromLTWH(24, 22, 52, 58), const Radius.circular(14));
      case 3: // 細おもて
        return RRect.fromRectAndRadius(
            const Rect.fromLTWH(29, 20, 42, 62), const Radius.circular(21));
      default: // たまご型
        return RRect.fromRectAndRadius(
            const Rect.fromLTWH(26, 20, 48, 60), const Radius.circular(23));
    }
  }

  void _drawFace(Canvas canvas, Color skin) {
    final r = _faceRect();
    canvas.drawRRect(r, Paint()..color = skin);
    canvas.drawRRect(
      r,
      Paint()
        ..color = _lineColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  void _drawEars(Canvas canvas, Color skin) {
    final r = _faceRect().outerRect;
    final y = r.top + r.height * 0.52;
    final p = Paint()..color = skin;
    canvas.drawCircle(Offset(r.left + 1, y), 5, p);
    canvas.drawCircle(Offset(r.right - 1, y), 5, p);
  }

  // ── 髪 ──

  /// 後ろ髪（顔より先に描く＝顔の下に隠れる部分）。
  void _drawBackHair(Canvas canvas, Color color) {
    final p = Paint()..color = color;
    switch (a.hair) {
      case 3: // ロング
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(20, 22, 60, 66), const Radius.circular(28)),
          p,
        );
      case 4: // ポニーテール
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(22, 22, 56, 46), const Radius.circular(26)),
          p,
        );
        canvas.drawCircle(const Offset(80, 46), 9, p);
      case 5: // ウェーブ
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(19, 22, 62, 54), const Radius.circular(30)),
          p,
        );
    }
  }

  /// 前髪（顔の上に描く）。
  void _drawFrontHair(Canvas canvas, Color color) {
    final p = Paint()..color = color;
    final face = _faceRect().outerRect;
    final top = face.top;

    switch (a.hair) {
      case 0: // ぼうず（うっすら生え際だけ）
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(face.left + 2, top - 1, face.width - 4, 12),
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
          ),
          Paint()..color = color.withValues(alpha: 0.55),
        );
      case 6: // オールバック
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(face.left - 1, top - 5, face.width + 2, 15),
            topLeft: const Radius.circular(22),
            topRight: const Radius.circular(22),
          ),
          p,
        );
      case 7: // つむじが立った髪
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(face.left - 1, top - 2, face.width + 2, 16),
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
          ),
          p,
        );
        final path = Path()
          ..moveTo(face.center.dx - 4, top - 1)
          ..lineTo(face.center.dx + 3, top - 13)
          ..lineTo(face.center.dx + 9, top + 1)
          ..close();
        canvas.drawPath(path, p);
      default: // ふつう / ショート / ロング / ポニーテール / ウェーブ の前髪
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(face.left - 1, top - 3, face.width + 2, 18),
            topLeft: const Radius.circular(22),
            topRight: const Radius.circular(22),
          ),
          p,
        );
        // 前髪の分け目
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(face.center.dx + 2, top - 2, 12, 14),
            const Radius.circular(6),
          ),
          Paint()..color = color,
        );
    }
  }

  // ── 目・まゆ ──

  double get _eyeY => _faceRect().outerRect.top + 30;
  double get _eyeDx => a.faceShape == 3 ? 10.0 : 11.0;

  void _drawEyes(Canvas canvas) {
    final cx = _faceRect().outerRect.center.dx;
    for (final sign in [-1, 1]) {
      final c = Offset(cx + sign * _eyeDx, _eyeY);
      final fill = Paint()..color = _lineColor;
      final stroke = Paint()
        ..color = _lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;

      switch (a.eyes) {
        case 1: // たれ目
          canvas.drawArc(Rect.fromCenter(center: c, width: 11, height: 9),
              3.6, 2.2, false, stroke);
          canvas.drawCircle(c.translate(0, 1), 2.2, fill);
        case 2: // つり目
          canvas.drawArc(
              Rect.fromCenter(center: c, width: 11, height: 9),
              sign < 0 ? 3.5 : 3.9,
              2.0,
              false,
              stroke);
          canvas.drawCircle(c.translate(sign * 0.5, 0), 2.2, fill);
        case 3: // 細い目
          canvas.drawLine(c.translate(-5, 0), c.translate(5, 0), stroke);
        case 4: // まるい目
          canvas.drawCircle(c, 4.2, Paint()..color = Colors.white);
          canvas.drawCircle(c, 4.2, stroke..strokeWidth = 1.2);
          canvas.drawCircle(c, 2.4, fill);
        case 5: // ぱっちり
          canvas.drawOval(
              Rect.fromCenter(center: c, width: 10, height: 8),
              Paint()..color = Colors.white);
          canvas.drawOval(Rect.fromCenter(center: c, width: 10, height: 8),
              stroke..strokeWidth = 1.4);
          canvas.drawCircle(c, 2.8, fill);
        default: // ふつう
          canvas.drawCircle(c, 2.8, fill);
      }
    }
  }

  void _drawEyebrows(Canvas canvas) {
    final cx = _faceRect().outerRect.center.dx;
    final y = _eyeY - 9;
    for (final sign in [-1, 1]) {
      final c = Offset(cx + sign * _eyeDx, y);
      final p = Paint()
        ..color = _lineColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = switch (a.eyebrows) { 1 => 3.4, 2 => 1.4, _ => 2.2 };

      if (a.eyebrows == 3) {
        // への字
        final path = Path()
          ..moveTo(c.dx - 5, c.dy + 1.5)
          ..lineTo(c.dx, c.dy - 1.5)
          ..lineTo(c.dx + 5, c.dy + 1.5);
        canvas.drawPath(path, p);
      } else {
        canvas.drawLine(c.translate(-5, 0.6), c.translate(5, -0.6), p);
      }
    }
  }

  // ── 鼻・口 ──

  void _drawNose(Canvas canvas) {
    final face = _faceRect().outerRect;
    final c = Offset(face.center.dx, _eyeY + 11);
    final p = Paint()
      ..color = _lineColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.8;
    switch (a.nose) {
      case 1: // 小さい
        canvas.drawCircle(c, 1.2, Paint()..color = _lineColor.withValues(alpha: 0.7));
      case 2: // 高い
        canvas.drawLine(c.translate(0, -5), c.translate(0, 3), p);
        canvas.drawLine(c.translate(0, 3), c.translate(3, 3), p);
      default: // ふつう
        canvas.drawLine(c.translate(-2, 2), c.translate(2, 2), p);
    }
  }

  void _drawMouth(Canvas canvas) {
    final face = _faceRect().outerRect;
    final c = Offset(face.center.dx, _eyeY + 22);
    final p = Paint()
      ..color = _lineColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.8;
    switch (a.mouth) {
      case 1: // にっこり
        canvas.drawArc(Rect.fromCenter(center: c, width: 16, height: 12),
            0.35, 2.44, false, p);
      case 2: // への字
        canvas.drawArc(
            Rect.fromCenter(center: c.translate(0, 5), width: 16, height: 12),
            3.5, 2.28, false, p);
      case 3: // 小さい
        canvas.drawLine(c.translate(-3, 0), c.translate(3, 0), p);
      case 4: // 大きい
        canvas.drawArc(Rect.fromCenter(center: c, width: 22, height: 16),
            0.3, 2.54, false, p..strokeWidth = 2.2);
      default: // ふつう
        canvas.drawLine(c.translate(-6, 0), c.translate(6, 0), p);
    }
  }

  // ── 特徴（覚える手がかりになるパーツ）──

  void _drawGlasses(Canvas canvas) {
    if (a.glasses == 0) return;
    final cx = _faceRect().outerRect.center.dx;
    final y = _eyeY;
    final frame = Paint()
      ..color = a.glasses == 4 ? const Color(0xFF222222) : const Color(0xFF444444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    Rect lensAt(int sign) => Rect.fromCenter(
          center: Offset(cx + sign * _eyeDx, y),
          width: a.glasses == 3 ? 13 : 14,
          height: switch (a.glasses) { 3 => 6, 1 => 12, _ => 11 },
        );

    for (final sign in [-1, 1]) {
      final r = lensAt(sign);
      if (a.glasses == 4) {
        // サングラスは中を塗る
        canvas.drawRRect(
            RRect.fromRectAndRadius(r, const Radius.circular(4)),
            Paint()..color = const Color(0xCC222222));
      }
      if (a.glasses == 1) {
        canvas.drawCircle(r.center, r.width / 2, frame);
      } else {
        canvas.drawRRect(
            RRect.fromRectAndRadius(r, Radius.circular(a.glasses == 3 ? 3 : 4)),
            frame);
      }
    }
    // ブリッジ
    canvas.drawLine(Offset(cx - _eyeDx + 7, y), Offset(cx + _eyeDx - 7, y), frame);
  }

  void _drawMole(Canvas canvas) {
    if (a.mole == 0) return;
    final face = _faceRect().outerRect;
    final cx = face.center.dx;
    final c = switch (a.mole) {
      1 => Offset(cx - 14, _eyeY + 14), // 左ほお
      2 => Offset(cx + 14, _eyeY + 14), // 右ほお
      3 => Offset(cx + 8, _eyeY + 26), // 口もと
      _ => Offset(cx - _eyeDx, _eyeY + 6), // 目の下
    };
    canvas.drawCircle(c, 1.6, Paint()..color = const Color(0xFF4A3324));
  }

  void _drawBeard(Canvas canvas, Color color) {
    if (a.beard == 0) return;
    final face = _faceRect().outerRect;
    final cx = face.center.dx;
    final mouthY = _eyeY + 22;
    final p = Paint()..color = color;

    switch (a.beard) {
      case 1: // 口ひげ
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx, mouthY - 6), width: 16, height: 4),
            const Radius.circular(2),
          ),
          p,
        );
      case 2: // あごひげ
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx, mouthY + 9), width: 18, height: 10),
            const Radius.circular(5),
          ),
          p,
        );
      case 3: // 無精ひげ（うっすら）
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx, mouthY + 5), width: 30, height: 18),
            const Radius.circular(9),
          ),
          Paint()..color = color.withValues(alpha: 0.22),
        );
    }
  }

  @override
  bool shouldRepaint(_AvatarPainter old) =>
      old.a.encode() != a.encode() || old.background != background;
}
