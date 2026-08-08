/// 🎭 立ち絵。画像素材を使わず、コードで描く。
///
/// 素材を待たずに全員ぶんの絵が出せるのが狙い。
/// 17人が**見分けられる**ことを最優先にして、
/// 髪型・髪色・服の色・小物の4つで差をつける。
///
/// 表情は normal / smile / tired / surprise の4つ。
/// シナリオの `"sprite": "hibino/smile"` の後ろ半分がこれにあたる。
library;

import 'package:flutter/material.dart';

/// 髪型。増やすときは [_drawHair] にも足すこと。
enum HairStyle {
  short, // 短髪
  bob, // ボブ
  longHair, // ロング
  ponytail, // ポニーテール
  bun, // おだんご
  buzz, // 刈り上げ
  sidePart, // 七三
  messy, // くせ毛
  twin, // ツインテール
  bald, // 薄い
}

/// 顔まわりの小物。人物を思い出す手がかりになる。
enum Accessory { none, glasses, roundGlasses, beard, mustache, headband, mask }

enum Expression { normal, smile, tired, surprise }

Expression expressionFromKey(String key) => switch (key) {
      'smile' => Expression.smile,
      'tired' => Expression.tired,
      'surprise' => Expression.surprise,
      _ => Expression.normal,
    };

/// 1人ぶんの見た目。
class PortraitSpec {
  final HairStyle hair;
  final Color hairColor;
  final Color skin;
  final Color outfit;
  final Accessory accessory;

  /// 肩幅。1.0 が標準。がっちりした人は大きく。
  final double build;

  /// 顔の縦横比。1.0 が標準、小さいほど丸顔。
  final double faceRatio;

  const PortraitSpec({
    required this.hair,
    required this.hairColor,
    required this.skin,
    required this.outfit,
    this.accessory = Accessory.none,
    this.build = 1.0,
    this.faceRatio = 1.0,
  });
}

// ── 配色 ──
const _skinA = Color(0xFFFFE0C4);
const _skinB = Color(0xFFF2CBA6);
const _skinC = Color(0xFFDDAE84);
const _skinD = Color(0xFFB98A63);

const _hairBlack = Color(0xFF2B2118);
const _hairBrown = Color(0xFF4A3324);
const _hairLight = Color(0xFF7A5230);
const _hairGrey = Color(0xFF9A9A9A);
const _hairWhite = Color(0xFFD8D3CC);
const _hairAuburn = Color(0xFF8C4A2F);

const _line = Color(0xFF3A2E26);

/// 17人ぶんの見た目。**IDはcharacters.jsonと合わせること**。
///
/// 髪型と小物が他とかぶらないように選んである。
/// 同じ髪型が並ぶと、暗い画面では誰か分からなくなる。
const Map<String, PortraitSpec> kPortraits = {
  // ── 1周目の4人 ──
  'hibino': PortraitSpec(
    hair: HairStyle.ponytail,
    hairColor: _hairBrown,
    skin: _skinB,
    outfit: Color(0xFFE8663C), // 炉の火
    build: 0.95,
  ),
  'kiryu': PortraitSpec(
    hair: HairStyle.sidePart,
    hairColor: _hairBlack,
    skin: _skinA,
    outfit: Color(0xFF5AC8E8),
    accessory: Accessory.glasses,
    build: 1.0,
  ),
  'mizuhara': PortraitSpec(
    hair: HairStyle.bob,
    hairColor: _hairBlack,
    skin: _skinA,
    outfit: Color(0xFF7ACB8A),
    build: 0.9,
    faceRatio: 0.94,
  ),
  'tachibana': PortraitSpec(
    hair: HairStyle.buzz,
    hairColor: _hairGrey,
    skin: _skinC,
    outfit: Color(0xFF4E9A51),
    accessory: Accessory.beard,
    build: 1.15,
  ),

  // ── 2周目の4人 ──
  'hoshino': PortraitSpec(
    hair: HairStyle.twin,
    hairColor: _hairAuburn,
    skin: _skinA,
    outfit: Color(0xFF6C7BE8),
    build: 0.88,
    faceRatio: 0.95,
  ),
  'iwao': PortraitSpec(
    hair: HairStyle.messy,
    hairColor: _hairGrey,
    skin: _skinD,
    outfit: Color(0xFF9A7B4F),
    accessory: Accessory.mustache,
    build: 1.2,
  ),
  'kusunoki': PortraitSpec(
    hair: HairStyle.longHair,
    hairColor: _hairLight,
    skin: _skinB,
    outfit: Color(0xFFB06BC8),
    build: 0.92,
  ),
  'shirakawa': PortraitSpec(
    hair: HairStyle.short,
    hairColor: _hairBlack,
    skin: _skinB,
    outfit: Color(0xFF4FA3D1),
    accessory: Accessory.mask, // 医師。あごに下げている
    build: 1.05,
  ),

  // ── 残りの7人 ──
  'mikami': PortraitSpec(
    hair: HairStyle.bun,
    hairColor: _hairBrown,
    skin: _skinB,
    outfit: Color(0xFFD08AA8),
    build: 0.9,
  ),
  'arase': PortraitSpec(
    hair: HairStyle.buzz,
    hairColor: _hairBlack,
    skin: _skinD,
    outfit: Color(0xFF8A8F98),
    accessory: Accessory.headband,
    build: 1.25,
  ),
  'utsumi': PortraitSpec(
    hair: HairStyle.short,
    hairColor: _hairAuburn,
    skin: _skinC,
    outfit: Color(0xFF3FA9C9),
    build: 0.95,
  ),
  'kanzaki': PortraitSpec(
    hair: HairStyle.bald,
    hairColor: _hairBlack,
    skin: _skinB,
    outfit: Color(0xFF9C6BB0),
    build: 1.05,
  ),
  'tobe': PortraitSpec(
    hair: HairStyle.bob,
    hairColor: _hairLight,
    skin: _skinA,
    outfit: Color(0xFFE0A44C),
    accessory: Accessory.roundGlasses,
    build: 0.9,
    faceRatio: 0.94,
  ),
  'shinohara': PortraitSpec(
    hair: HairStyle.short,
    hairColor: _hairBrown,
    skin: _skinC,
    outfit: Color(0xFFC9954A),
    accessory: Accessory.headband, // 調理の手ぬぐい
    build: 1.1,
  ),
  'oguri': PortraitSpec(
    hair: HairStyle.longHair,
    hairColor: _hairBlack,
    skin: _skinA,
    outfit: Color(0xFF7E6BC8),
    build: 0.88,
  ),

  // ── 所長 ──
  'tsuchikura': PortraitSpec(
    hair: HairStyle.sidePart,
    hairColor: _hairWhite,
    skin: _skinC,
    outfit: Color(0xFFD4A24C),
    accessory: Accessory.glasses,
    build: 1.1,
  ),
};

/// 立ち絵ウィジェット。
class NoahPortrait extends StatelessWidget {
  final String charId;
  final Expression expression;
  final double height;

  /// 老化（0〜10）。白髪と、少しの猫背に効く。
  final int aging;

  const NoahPortrait({
    super.key,
    required this.charId,
    this.expression = Expression.normal,
    required this.height,
    this.aging = 0,
  });

  @override
  Widget build(BuildContext context) {
    final spec = kPortraits[charId];
    if (spec == null) return SizedBox(height: height);
    return SizedBox(
      width: height * 0.72,
      height: height,
      child: CustomPaint(
        painter: _PortraitPainter(
          spec: spec,
          expression: expression,
          aging: aging,
        ),
      ),
    );
  }
}

class _PortraitPainter extends CustomPainter {
  final PortraitSpec spec;
  final Expression expression;
  final int aging;

  _PortraitPainter({
    required this.spec,
    required this.expression,
    required this.aging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 144（幅）×200（高さ）で描いてから拡大する。
    final s = size.height / 200.0;
    canvas.scale(s, s);
    final w = size.width / s;
    final cx = w / 2;

    // 老化で髪が白くなる
    final t = (aging / 10).clamp(0.0, 1.0);
    final hair = Color.lerp(spec.hairColor, _hairWhite, t * 0.5)!;

    // 顔の大きさ
    const r = 34.0;
    final faceCy = 74.0 + t * 3; // 年をとるほど、わずかに前かがみ

    _drawBody(canvas, cx, faceCy, r);
    _drawBackHair(canvas, cx, faceCy, r, hair);
    _drawHead(canvas, cx, faceCy, r);
    _drawFrontHair(canvas, cx, faceCy, r, hair);
    _drawFace(canvas, cx, faceCy, r);
    _drawAccessory(canvas, cx, faceCy, r, hair);
  }

  // ── 体 ──
  void _drawBody(Canvas canvas, double cx, double faceCy, double r) {
    final shoulder = 44.0 * spec.build;
    final top = faceCy + r * 0.95;

    // 首
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 9, top - 14, 18, 22),
        const Radius.circular(5),
      ),
      Paint()..color = Color.lerp(spec.skin, _line, 0.10)!,
    );

    // 肩から下（白衣を着ているつもりで、襟を作る）
    final body = Path()
      ..moveTo(cx - shoulder * 0.42, top - 2)
      ..quadraticBezierTo(cx - shoulder, top + 6, cx - shoulder, top + 26)
      ..lineTo(cx - shoulder, 200)
      ..lineTo(cx + shoulder, 200)
      ..lineTo(cx + shoulder, top + 26)
      ..quadraticBezierTo(cx + shoulder, top + 6, cx + shoulder * 0.42, top - 2)
      ..close();
    canvas.drawPath(body, Paint()..color = const Color(0xFFEFF2F6));

    // 服の色は襟の内側に出す。全身を原色で塗るとうるさい。
    final collar = Path()
      ..moveTo(cx - 15, top - 4)
      ..lineTo(cx, top + 22)
      ..lineTo(cx + 15, top - 4)
      ..close();
    canvas.drawPath(collar, Paint()..color = spec.outfit);

    // 白衣の合わせ
    canvas.drawLine(
      Offset(cx, top + 22),
      Offset(cx, 200),
      Paint()
        ..color = const Color(0x22000000)
        ..strokeWidth = 1.4,
    );
  }

  // ── 髪（顔の後ろ） ──
  void _drawBackHair(
      Canvas canvas, double cx, double cy, double r, Color hair) {
    final p = Paint()..color = hair;
    switch (spec.hair) {
      case HairStyle.longHair:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - r * 1.16, cy - r * 1.15, r * 2.32, r * 2.5),
            Radius.circular(r * 0.9),
          ),
          p,
        );
      case HairStyle.bob:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - r * 1.14, cy - r * 1.12, r * 2.28, r * 1.9),
            Radius.circular(r * 0.85),
          ),
          p,
        );
      case HairStyle.ponytail:
        canvas.drawCircle(Offset(cx + r * 1.16, cy - r * 0.10), r * 0.36, p);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx + r * 0.98, cy - r * 0.10, r * 0.42, r * 1.5),
            Radius.circular(r * 0.22),
          ),
          p,
        );
      case HairStyle.twin:
        for (final sx in [-1, 1]) {
          canvas.drawCircle(
              Offset(cx + sx * r * 1.14, cy - r * 0.05), r * 0.30, p);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(cx + sx * r * 1.14 - r * 0.19, cy - r * 0.05,
                  r * 0.38, r * 1.25),
              Radius.circular(r * 0.19),
            ),
            p,
          );
        }
      case HairStyle.bun:
        canvas.drawCircle(Offset(cx, cy - r * 1.28), r * 0.34, p);
      case HairStyle.messy:
        // ぼさぼさ。外周に小さな丸をばらまく
        for (final a in [-1.1, -0.75, -0.4, 0.0, 0.4, 0.75, 1.1]) {
          canvas.drawCircle(
            Offset(cx + r * 1.02 * a, cy - r * (1.0 - a.abs() * 0.28)),
            r * 0.26,
            p,
          );
        }
      default:
        break;
    }
  }

  // ── 顔 ──
  void _drawHead(Canvas canvas, double cx, double cy, double r) {
    final rect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: r * 2,
      height: r * 2.05 * spec.faceRatio,
    );
    // 上が明るく下が暗い。これだけで丸みが出る。
    canvas.drawOval(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(spec.skin, Colors.white, 0.16)!,
            spec.skin,
            Color.lerp(spec.skin, _line, 0.13)!,
          ],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );
    // 耳
    for (final sx in [-1, 1]) {
      canvas.drawCircle(
          Offset(cx + sx * r * 0.98, cy + r * 0.08), r * 0.16, Paint()..color = spec.skin);
    }
  }

  // ── 髪（顔の上） ──
  void _drawFrontHair(
      Canvas canvas, double cx, double cy, double r, Color hair) {
    final p = Paint()..color = hair;
    final top = cy - r * 1.02 * spec.faceRatio;

    if (spec.hair == HairStyle.bald) {
      // 生え際だけうっすら
      canvas.drawArc(
        Rect.fromCenter(
            center: Offset(cx, cy), width: r * 2.02, height: r * 2.05),
        3.35,
        2.58,
        false,
        Paint()
          ..color = hair.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.20,
      );
      return;
    }

    // 頭にかぶせる基本の形
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(cx, cy + r * 0.02),
          width: r * 2.10,
          height: r * 2.14 * spec.faceRatio),
      3.20,
      2.88,
      true,
      p,
    );

    switch (spec.hair) {
      case HairStyle.sidePart:
        // 七三。片側に大きく流す
        final path = Path()
          ..moveTo(cx - r * 1.05, top + r * 0.30)
          ..quadraticBezierTo(
              cx - r * 0.2, top - r * 0.10, cx + r * 1.05, top + r * 0.52)
          ..lineTo(cx + r * 1.05, top + r * 0.05)
          ..quadraticBezierTo(cx, top - r * 0.30, cx - r * 1.05, top + r * 0.05)
          ..close();
        canvas.drawPath(path, p);
      case HairStyle.buzz:
        // 刈り上げ。前髪をほとんど作らない（上の弧だけ）
        break;
      case HairStyle.messy:
        for (final dx in [-0.7, -0.25, 0.25, 0.7]) {
          canvas.drawCircle(
              Offset(cx + r * dx, top + r * 0.12), r * 0.24, p);
        }
      default:
        // ぱっつん寄りの前髪。両端を少し垂らす
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(cx - r * 1.02, top - r * 0.08, r * 2.04, r * 0.52),
            topLeft: Radius.circular(r * 0.8),
            topRight: Radius.circular(r * 0.8),
          ),
          p,
        );
        for (final sx in [-1, 1]) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(cx + sx * r * 0.80, top + r * 0.42),
              width: r * 0.52,
              height: r * 0.85,
            ),
            p,
          );
        }
    }

    // つや
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(cx - r * 0.22, top + r * 0.30),
          width: r * 0.95,
          height: r * 0.42),
      3.5,
      2.2,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.26)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = r * 0.09,
    );
  }

  // ── 目・鼻・口 ──
  void _drawFace(Canvas canvas, double cx, double cy, double r) {
    final eyeY = cy + r * 0.08;
    final dx = r * 0.40;

    final stroke = Paint()
      ..color = _line
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = r * 0.085;
    final fill = Paint()..color = _line;

    for (final sx in [-1, 1]) {
      final c = Offset(cx + sx * dx, eyeY);
      switch (expression) {
        case Expression.smile:
          // 笑って閉じた目（∩）
          canvas.drawArc(
            Rect.fromCenter(
                center: c, width: r * 0.46, height: r * 0.40),
            3.35,
            2.58,
            false,
            stroke,
          );
        case Expression.tired:
          // 半分閉じた目
          canvas.drawLine(
              c.translate(-r * 0.22, 0), c.translate(r * 0.22, 0), stroke);
          canvas.drawCircle(c.translate(0, r * 0.09), r * 0.07, fill);
        case Expression.surprise:
          canvas.drawCircle(c, r * 0.19, Paint()..color = Colors.white);
          canvas.drawCircle(
              c, r * 0.19, Paint()
                ..color = _line
                ..style = PaintingStyle.stroke
                ..strokeWidth = r * 0.05);
          canvas.drawCircle(c, r * 0.10, fill);
        case Expression.normal:
          canvas.drawOval(
              Rect.fromCenter(center: c, width: r * 0.24, height: r * 0.30),
              fill);
      }
      // ハイライト（目が生きて見える）
      if (expression != Expression.smile) {
        canvas.drawCircle(c.translate(-r * 0.05, -r * 0.06), r * 0.045,
            Paint()..color = Colors.white.withValues(alpha: 0.9));
      }
    }

    // まゆ。表情で高さと角度を変える
    final browY = eyeY - r * 0.34 - (expression == Expression.surprise ? r * 0.10 : 0);
    for (final sx in [-1, 1]) {
      final c = Offset(cx + sx * dx, browY);
      final tilt = switch (expression) {
        Expression.tired => r * 0.10, // 外側が下がる（困り顔）
        Expression.surprise => -r * 0.04,
        _ => -r * 0.05,
      };
      canvas.drawLine(
        c.translate(-r * 0.22, sx < 0 ? tilt : 0),
        c.translate(r * 0.22, sx < 0 ? 0 : tilt),
        Paint()
          ..color = _line.withValues(alpha: 0.75)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = r * 0.075,
      );
    }

    // 鼻
    canvas.drawLine(
      Offset(cx, eyeY + r * 0.28),
      Offset(cx + r * 0.06, eyeY + r * 0.36),
      Paint()
        ..color = _line.withValues(alpha: 0.55)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = r * 0.06,
    );

    // 口
    final my = eyeY + r * 0.58;
    switch (expression) {
      case Expression.smile:
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx, my), width: r * 0.5, height: r * 0.42),
          0.30,
          2.54,
          false,
          stroke,
        );
      case Expression.surprise:
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(cx, my + r * 0.04), width: r * 0.22, height: r * 0.30),
            fill);
      case Expression.tired:
        canvas.drawLine(Offset(cx - r * 0.16, my), Offset(cx + r * 0.16, my),
            stroke);
      case Expression.normal:
        canvas.drawLine(Offset(cx - r * 0.20, my), Offset(cx + r * 0.20, my),
            stroke);
    }

    // ほお（笑ったときだけ赤みを足す）
    if (expression == Expression.smile) {
      for (final sx in [-1, 1]) {
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx + sx * r * 0.62, eyeY + r * 0.30),
              width: r * 0.34,
              height: r * 0.22),
          Paint()..color = const Color(0xFFE88A8A).withValues(alpha: 0.28),
        );
      }
    }
  }

  // ── 小物 ──
  void _drawAccessory(
      Canvas canvas, double cx, double cy, double r, Color hair) {
    final eyeY = cy + r * 0.08;
    final dx = r * 0.40;
    final frame = Paint()
      ..color = const Color(0xFF3A3A3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.065;

    switch (spec.accessory) {
      case Accessory.glasses:
        for (final sx in [-1, 1]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(cx + sx * dx, eyeY),
                  width: r * 0.56,
                  height: r * 0.42),
              Radius.circular(r * 0.10),
            ),
            frame,
          );
        }
        canvas.drawLine(Offset(cx - r * 0.12, eyeY), Offset(cx + r * 0.12, eyeY),
            frame);
      case Accessory.roundGlasses:
        for (final sx in [-1, 1]) {
          canvas.drawCircle(Offset(cx + sx * dx, eyeY), r * 0.26, frame);
        }
        canvas.drawLine(Offset(cx - r * 0.14, eyeY), Offset(cx + r * 0.14, eyeY),
            frame);
      case Accessory.beard:
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx, eyeY + r * 0.86),
              width: r * 0.95,
              height: r * 0.62),
          Paint()..color = hair.withValues(alpha: 0.85),
        );
        // あごの肌を少し出して、口を隠しきらない
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx, eyeY + r * 0.60),
              width: r * 0.52,
              height: r * 0.30),
          Paint()..color = spec.skin,
        );
      case Accessory.mustache:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx, eyeY + r * 0.44),
                width: r * 0.6,
                height: r * 0.14),
            Radius.circular(r * 0.07),
          ),
          Paint()..color = hair,
        );
      case Accessory.headband:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx, cy - r * 0.72),
                width: r * 2.06,
                height: r * 0.30),
            Radius.circular(r * 0.10),
          ),
          Paint()..color = spec.outfit,
        );
      case Accessory.mask:
        // あごに下げたマスク（医師）
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx, eyeY + r * 0.96),
                width: r * 1.0,
                height: r * 0.44),
            Radius.circular(r * 0.10),
          ),
          Paint()..color = const Color(0xFFDCE7F0),
        );
      case Accessory.none:
        break;
    }
  }

  @override
  bool shouldRepaint(_PortraitPainter old) =>
      old.spec != spec || old.expression != expression || old.aging != aging;
}
