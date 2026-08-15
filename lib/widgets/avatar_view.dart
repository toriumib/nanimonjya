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

/// 🧍 アバターの全身。身長・年齢・性別で立ち姿が変わる。
///
/// 顔だけだと「背が高い人」「年配の人」といった、
/// 実際に会ったときいちばん先に目に入る情報が抜け落ちる。
/// 全身で見せると、身長差・姿勢・年齢の印象がそのまま手がかりになる。
class AvatarBodyView extends StatelessWidget {
  final Avatar avatar;

  /// 描画領域の高さ。幅はこの半分を使う。
  final double height;

  /// 背景（薄い板）を描くか。
  final bool background;

  const AvatarBodyView({
    super.key,
    required this.avatar,
    required this.height,
    this.background = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: height * 0.55,
      height: height,
      child: CustomPaint(
        painter: _BodyPainter(avatar, background: background),
      ),
    );
  }
}

class _BodyPainter extends CustomPainter {
  final Avatar a;
  final bool background;

  _BodyPainter(this.a, {this.background = true});

  @override
  void paint(Canvas canvas, Size size) {
    // 110（幅）×200（高さ）で描いてから実サイズへ拡大する。
    final s = size.height / 200.0;
    canvas.scale(s, s);
    final w = size.width / s;
    final cx = w / 2;

    if (background) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, 200),
        Paint()..color = const Color(0xFFEFF4FB),
      );
    }

    // 身長 130〜200cm を、絵の中の背丈 0.80〜1.06 倍に写す。
    // そのままの比で描くと低い人が子どもに見えてしまうので、差は控えめにする。
    final tall =
        (0.80 + (a.height - Avatar.minHeight) / (Avatar.maxHeight - Avatar.minHeight) * 0.26);

    // 年配ほど少し前かがみになり、その分だけ全体の背が縮む。
    final aged = ((a.age - 50) / 30).clamp(0.0, 1.0);
    final stoop = aged * 6.0;

    final skin = _skinColors[a.skin % _skinColors.length];
    // 服の色は肌や髪と混ざらないよう、性別ごとに落ち着いた色を割り当てる。
    final cloth = switch (a.gender) {
      1 => const Color(0xFF4A6FA5),
      2 => const Color(0xFFB5678F),
      3 => const Color(0xFF6A8F6A),
      _ => const Color(0xFF6E7A8A),
    };

    // 足元を固定して、上へ伸ばす（背が高い人ほど頭が上にいく）。
    const groundY = 190.0;
    final bodyTop = groundY - 108 * tall + stoop;
    const headSize = 46.0;
    final headTop = bodyTop - headSize + 4;

    // ── 脚 ──
    final legPaint = Paint()..color = const Color(0xFF3C4657);
    final legTop = groundY - 52 * tall;
    for (final sign in [-1, 1]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + sign * 11 - 7, legTop, 14, groundY - legTop),
          const Radius.circular(6),
        ),
        legPaint,
      );
    }
    // 靴
    for (final sign in [-1, 1]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + sign * 11 - 9, groundY - 4, 18, 7),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFF262C36),
      );
    }

    // ── 胴 ──
    // 女性寄りは肩をやや狭く・腰をややしぼる。男性寄りは肩を広く。
    final shoulder = switch (a.gender) { 1 => 21.0, 2 => 17.0, _ => 19.0 };
    final torsoTop = bodyTop + 4;
    final torsoBottom = legTop + 4;
    final torso = Path()
      ..moveTo(cx - shoulder, torsoTop)
      ..lineTo(cx + shoulder, torsoTop)
      ..lineTo(cx + shoulder * (a.gender == 2 ? 0.86 : 0.95), torsoBottom)
      ..lineTo(cx - shoulder * (a.gender == 2 ? 0.86 : 0.95), torsoBottom)
      ..close();
    canvas.drawPath(torso, Paint()..color = cloth);

    // ── 腕 ──
    final armPaint = Paint()..color = cloth;
    final handPaint = Paint()..color = skin;
    for (final sign in [-1, 1]) {
      final x = cx + sign * (shoulder - 2);
      // 年配ほど腕をわずかに前へ垂らす
      final armLen = (torsoBottom - torsoTop) * 0.92;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 5, torsoTop + 2, 10, armLen),
          const Radius.circular(5),
        ),
        armPaint,
      );
      canvas.drawCircle(Offset(x, torsoTop + armLen + 4), 5, handPaint);
    }

    // 首
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 6, headTop + headSize - 8, 12, 12),
        const Radius.circular(4),
      ),
      Paint()..color = skin,
    );

    // ── 顔（既存の顔の絵をそのまま縮めて載せる）──
    canvas.save();
    canvas.translate(cx - headSize / 2, headTop);
    canvas.scale(headSize / 100.0);
    _AvatarPainter(a, background: false, withShoulders: false)
        .paint(canvas, const Size(100, 100));
    canvas.restore();

    // 杖（かなり年配のときだけ）
    if (a.age >= 70) {
      final cane = Paint()
        ..color = const Color(0xFF7A5230)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3;
      canvas.drawLine(
          Offset(cx + shoulder + 8, torsoTop + 26), Offset(cx + shoulder + 8, groundY), cane);
    }
  }

  @override
  bool shouldRepaint(_BodyPainter old) =>
      old.a.encode() != a.encode() || old.background != background;
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

  /// 首と肩を描くか。
  /// 全身表示（[AvatarBodyView]）はこの下に自前の胴体を描くので、
  /// ここで肩まで描くと二重になる。そのときだけ false にする。
  final bool withShoulders;

  _AvatarPainter(this.a, {this.background = true, this.withShoulders = true});

  @override
  void paint(Canvas canvas, Size size) {
    // 100×100 の座標で描いて、最後に実サイズへ拡大する。
    // こうしておくとどの大きさで表示しても同じ絵になる。
    final s = size.shortestSide / 100.0;
    canvas.scale(s, s);

    final skin = _skinColors[a.skin % _skinColors.length];
    final hairColor = _agedHair(_hairColors[a.hairColor % _hairColors.length]);

    if (background) {
      // 平らな一色だと切り絵のように見えるので、淡いグラデーションと
      // 後光を敷いて、顔が浮き上がるようにする。
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 100, 100),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7FAFF), Color(0xFFDDE8F5)],
          ).createShader(const Rect.fromLTWH(0, 0, 100, 100)),
      );
      canvas.drawCircle(
        const Offset(50, 54),
        40,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.85),
              Colors.white.withValues(alpha: 0.0),
            ],
          ).createShader(
              Rect.fromCircle(center: const Offset(50, 54), radius: 40)),
      );
    }

    if (withShoulders) _drawNeckAndShoulders(canvas, skin);
    _drawBackHair(canvas, hairColor);
    _drawFace(canvas, skin);
    _drawEars(canvas, skin);
    _drawFrontHair(canvas, hairColor);
    _drawHairShine(canvas, hairColor);
    _drawEyebrows(canvas);
    _drawEyes(canvas);
    _drawFeminineTouch(canvas);
    _drawNose(canvas);
    _drawMouth(canvas);
    _drawMasculineTouch(canvas);
    _drawAgeTouch(canvas);
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

  /// 首と肩。顔だけが宙に浮いて見えるのを防ぐ。
  void _drawNeckAndShoulders(Canvas canvas, Color skin) {
    final face = _faceRect().outerRect;
    // 首（あごの下に少しだけ影を落とす）
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(face.center.dx - 9, face.bottom - 12, 18, 24),
        const Radius.circular(6),
      ),
      Paint()..color = _shade(skin, 0.10),
    );
    // 肩（服）。性別で色を変えて、全身表示と印象をそろえる。
    final cloth = switch (a.gender) {
      1 => const Color(0xFF4A6FA5),
      2 => const Color(0xFFB5678F),
      3 => const Color(0xFF6A8F6A),
      _ => const Color(0xFF6E7A8A),
    };
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 88, 60, 30),
        const Radius.circular(16),
      ),
      Paint()..color = cloth,
    );
  }

  /// 色を暗くする（影づくり用）。
  static Color _shade(Color c, double amount) =>
      Color.lerp(c, const Color(0xFF6B4A32), amount) ?? c;

  void _drawFace(Canvas canvas, Color skin) {
    final r = _faceRect();
    // 肌はうっすら上が明るく、下（あご側）が暗い。これだけで丸みが出る。
    canvas.drawRRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(skin, Colors.white, 0.18) ?? skin,
            skin,
            _shade(skin, 0.12),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(r.outerRect),
    );
    canvas.drawRRect(
      r,
      Paint()
        ..color = _lineColor.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
  }

  /// 髪のつや。1本入れるだけで「塗り絵」感がかなり減る。
  void _drawHairShine(Canvas canvas, Color color) {
    // ぼうずと、前髪をほとんど描かない型には入れない
    if (a.hair == 0) return;
    final face = _faceRect().outerRect;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(face.center.dx - 6, face.top + 3),
        width: 26,
        height: 12,
      ),
      3.5,
      2.2,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.30)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.6,
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
      case 8: // ツインテール
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(22, 22, 56, 44), const Radius.circular(25)),
          p,
        );
        canvas.drawCircle(const Offset(19, 48), 8, p);
        canvas.drawCircle(const Offset(81, 48), 8, p);
      case 9: // おだんご
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(23, 22, 54, 44), const Radius.circular(25)),
          p,
        );
        canvas.drawCircle(const Offset(50, 15), 9, p);
      case 11: // パーマ（ふくらみのある外側）
        for (final dx in [22.0, 33.0, 50.0, 67.0, 78.0]) {
          canvas.drawCircle(Offset(dx, 34), 12, p);
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(20, 22, 60, 50), const Radius.circular(28)),
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
      case 10: // マッシュ（丸く深くかぶる）
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(face.left - 3, top - 5, face.width + 6, 24),
            topLeft: const Radius.circular(26),
            topRight: const Radius.circular(26),
            bottomLeft: const Radius.circular(12),
            bottomRight: const Radius.circular(12),
          ),
          p,
        );
      case 12: // サイド分け（片側に大きく寄せる）
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(face.left - 1, top - 4, face.width + 2, 17),
            topLeft: const Radius.circular(22),
            topRight: const Radius.circular(22),
          ),
          p,
        );
        final side = Path()
          ..moveTo(face.left - 1, top - 2)
          ..lineTo(face.left + face.width * 0.72, top - 4)
          ..lineTo(face.left + face.width * 0.30, top + 15)
          ..close();
        canvas.drawPath(side, p);
      case 13: // ぱっつん（前髪が一直線）
        canvas.drawRect(
          Rect.fromLTWH(face.left - 1, top - 4, face.width + 2, 19),
          p,
        );
      default: // ふつう / ショート / ロング / ポニーテール / ウェーブ / ツインテール / おだんご / パーマ の前髪
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

  // ── 性別・年齢の味つけ ──
  //
  // 性別は「そう見える」程度の控えめな差にとどめる。
  // 決めつけた記号（口紅＝女性 のような強い記号）は使わず、
  // まつげ・あご幅・ほお の淡い差だけで印象を寄せる。

  bool get _feminine => a.gender == 2;
  bool get _masculine => a.gender == 1;

  /// 50歳を過ぎたぶんだけ、髪の色を白へ寄せる。
  /// 「白髪まじり」を選んでいる人はそのままにする（二重に白くしない）。
  Color _agedHair(Color base) {
    if (a.hairColor == 5 || a.age < 50) return base;
    final t = ((a.age - 50) / 40).clamp(0.0, 0.55);
    return Color.lerp(base, const Color(0xFFD8D3CC), t) ?? base;
  }

  /// 女性寄りのとき、まつげとほおの赤みを足す。
  void _drawFeminineTouch(Canvas canvas) {
    if (!_feminine) return;
    final cx = _faceRect().outerRect.center.dx;
    final lash = Paint()
      ..color = _lineColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.3;
    for (final sign in [-1, 1]) {
      final c = Offset(cx + sign * _eyeDx, _eyeY);
      // 目じりのまつげ
      canvas.drawLine(
          c.translate(sign * 5.0, -2.5), c.translate(sign * 8.0, -4.5), lash);
      // ほおの赤み
      canvas.drawCircle(
        Offset(cx + sign * 16, _eyeY + 10),
        5,
        Paint()..color = const Color(0xFFE88A8A).withValues(alpha: 0.18),
      );
    }
  }

  /// 男性寄りのとき、あごのラインを少しだけ角ばらせる。
  void _drawMasculineTouch(Canvas canvas) {
    if (!_masculine) return;
    final face = _faceRect().outerRect;
    final p = Paint()
      ..color = _lineColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;
    final jaw = Path()
      ..moveTo(face.left + 4, face.bottom - 16)
      ..lineTo(face.left + 9, face.bottom - 4)
      ..lineTo(face.right - 9, face.bottom - 4)
      ..lineTo(face.right - 4, face.bottom - 16);
    canvas.drawPath(jaw, p);
  }

  /// 年齢の目安に応じて、ほうれい線・目じりのしわ・白髪まじりを足す。
  /// 45歳くらいから少しずつ、65歳を超えるとはっきり出す。
  void _drawAgeTouch(Canvas canvas) {
    if (a.age < 45) return;
    final face = _faceRect().outerRect;
    final cx = face.center.dx;
    // 45→0.0、80→1.0 のなだらかな強さ
    final t = ((a.age - 45) / 35).clamp(0.0, 1.0);
    final p = Paint()
      ..color = _lineColor.withValues(alpha: 0.12 + 0.22 * t)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2;

    // ほうれい線
    for (final sign in [-1, 1]) {
      canvas.drawArc(
        Rect.fromCenter(
            center: Offset(cx + sign * 10, _eyeY + 20), width: 14, height: 18),
        sign < 0 ? -0.6 : 2.1,
        1.3,
        false,
        p,
      );
    }
    // 目じりのしわ（65歳あたりから）
    if (a.age >= 65) {
      for (final sign in [-1, 1]) {
        final c = Offset(cx + sign * _eyeDx, _eyeY);
        for (final dy in [-2.0, 1.0]) {
          canvas.drawLine(c.translate(sign * 6.0, dy),
              c.translate(sign * 9.5, dy + dy.sign * 1.5), p);
        }
      }
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
          _catchlight(canvas, c, 2.4);
        case 5: // ぱっちり
          canvas.drawOval(
              Rect.fromCenter(center: c, width: 10, height: 8),
              Paint()..color = Colors.white);
          canvas.drawOval(Rect.fromCenter(center: c, width: 10, height: 8),
              stroke..strokeWidth = 1.4);
          canvas.drawCircle(c, 2.8, fill);
          _catchlight(canvas, c, 2.8);
        default: // ふつう
          canvas.drawCircle(c, 2.8, fill);
          _catchlight(canvas, c, 2.8);
      }
    }
  }

  /// 瞳のハイライト。これが入るだけで目が生きて見える。
  void _catchlight(Canvas canvas, Offset eye, double pupil) {
    canvas.drawCircle(
      eye.translate(-pupil * 0.35, -pupil * 0.4),
      pupil * 0.38,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
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
