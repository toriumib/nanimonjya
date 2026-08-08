/// 🖼 背景。画像素材を使わず、コードで描く。
///
/// 目的は「その場所だと分かること」。写実は狙わない。
/// 場面が変わったことが伝わればよいので、
/// **床の高さ・壁の色・置いてある物**の3つで差をつける。
///
/// 老化（0〜10）は色の転びで表す。年月がたつほど、
/// 白が黄ばみ、影が濃くなる（SPEC 4.8 の環境ストーリーテリング）。
library;

import 'dart:math';

import 'package:flutter/material.dart';

class NoahBackdrop extends StatelessWidget {
  final String id;
  final int age;
  const NoahBackdrop({super.key, required this.id, this.age = 0});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: CustomPaint(
        key: ValueKey('$id/$age'),
        painter: _BackdropPainter(id: id, age: age),
        size: Size.infinite,
      ),
    );
  }
}

/// 背景1枚ぶんの色づかい。
class _Palette {
  final Color skyTop;
  final Color skyBottom;
  final Color floor;
  final Color wall;
  final Color accent;
  const _Palette(this.skyTop, this.skyBottom, this.floor, this.wall, this.accent);
}

/// 場所ごとの色。知らないIDが来たら [_fallback] を使う。
const _fallback =
    _Palette(Color(0xFF16203A), Color(0xFF0A0F1C), Color(0xFF10182B),
        Color(0xFF1B2740), Color(0xFF3C5A88));

const Map<String, _Palette> _palettes = {
  // ── 地球・ドーム（地下。赤い外光が差す） ──
  'dome_office': _Palette(Color(0xFF3A1A16), Color(0xFF140A08),
      Color(0xFF231411), Color(0xFF33201A), Color(0xFFD4A24C)),
  'dome_hall': _Palette(Color(0xFF3E211A), Color(0xFF160C09),
      Color(0xFF2A1913), Color(0xFF3A241C), Color(0xFFE8A055)),
  'dome_lab': _Palette(Color(0xFF22303A), Color(0xFF0C1216),
      Color(0xFF16222A), Color(0xFF203038), Color(0xFF5AD1FF)),
  'med_lab': _Palette(Color(0xFF1D2E38), Color(0xFF0A1014),
      Color(0xFF152530), Color(0xFF1E323E), Color(0xFF7FE0E8)),
  'greenhouse': _Palette(Color(0xFF1B3324), Color(0xFF08130C),
      Color(0xFF13251A), Color(0xFF1D3A28), Color(0xFF7ACB8A)),
  'engine_bay': _Palette(Color(0xFF3A2016), Color(0xFF120806),
      Color(0xFF241209), Color(0xFF351D12), Color(0xFFFF8A3C)),

  // ── 船内 ──
  'ship_corridor': _Palette(Color(0xFF16203A), Color(0xFF080C16),
      Color(0xFF101A2E), Color(0xFF1C2A46), Color(0xFF5AD1FF)),
  'ship_lounge': _Palette(Color(0xFF1E2440), Color(0xFF0A0E1A),
      Color(0xFF161C32), Color(0xFF262F4E), Color(0xFFE0A44C)),
  'ship_river': _Palette(Color(0xFF12303A), Color(0xFF06131A),
      Color(0xFF0D2630), Color(0xFF173844), Color(0xFF4FD6E8)),
  'ship_food': _Palette(Color(0xFF33251A), Color(0xFF130D08),
      Color(0xFF241A12), Color(0xFF3A2A1C), Color(0xFFFFC46B)),
  'ship_karaoke': _Palette(Color(0xFF2A1838), Color(0xFF100818),
      Color(0xFF1E1128), Color(0xFF321E44), Color(0xFFC86BE8)),
  'ship_archive': _Palette(Color(0xFF1A1A26), Color(0xFF090910),
      Color(0xFF14141E), Color(0xFF232334), Color(0xFF9FB4D8)),
  'ship_bridge': _Palette(Color(0xFF101C2E), Color(0xFF05080F),
      Color(0xFF0C1626), Color(0xFF16263C), Color(0xFF7DFFB0)),
  'ship_hall': _Palette(Color(0xFF1C2136), Color(0xFF080B14),
      Color(0xFF141830), Color(0xFF232A46), Color(0xFFD4A24C)),

  // ── LHS 1140 b（赤色矮星の光。永遠の夕暮れ） ──
  'lhs1140_terminator': _Palette(Color(0xFF5A2438), Color(0xFF160A16),
      Color(0xFF2A1424), Color(0xFF3A1C2C), Color(0xFFFF9AA8)),
  'lhs1140_shore': _Palette(Color(0xFF6A2E36), Color(0xFF1A0E18),
      Color(0xFF1E2A3A), Color(0xFF3E2030), Color(0xFFFFB08A)),
  'lhs1140_city': _Palette(Color(0xFF4A2A44), Color(0xFF150C16),
      Color(0xFF241A2E), Color(0xFF35223C), Color(0xFFFFD08A)),
};

class _BackdropPainter extends CustomPainter {
  final String id;
  final int age;

  _BackdropPainter({required this.id, required this.age});

  /// 年月で色を転ばせる。白いものは黄ばみ、暗いものはより沈む。
  Color _aged(Color c) {
    final t = (age / 10).clamp(0.0, 1.0) * 0.35;
    return Color.lerp(c, const Color(0xFF6B4A28), t) ?? c;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final p = _palettes[id] ?? _fallback;
    final w = size.width;
    final h = size.height;
    // 床の高さ。ここを場所ごとに変えると、部屋の広さが変わって見える。
    final floorY = h * 0.72;

    // ── 奥（空・壁）
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, floorY),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_aged(p.skyTop), _aged(p.skyBottom)],
        ).createShader(Rect.fromLTWH(0, 0, w, floorY)),
    );

    // ── 床
    canvas.drawRect(
      Rect.fromLTWH(0, floorY, w, h - floorY),
      Paint()..color = _aged(p.floor),
    );
    // 床の手前を暗くして、奥行きを出す
    canvas.drawRect(
      Rect.fromLTWH(0, floorY, w, h - floorY),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.45)],
        ).createShader(Rect.fromLTWH(0, floorY, w, h - floorY)),
    );

    _drawScene(canvas, w, h, floorY, p);

    // ── 手前に暗い縁を落として、文字窓を読みやすくする
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.center,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
  }

  /// 場所ごとの置き物。
  void _drawScene(
      Canvas canvas, double w, double h, double floorY, _Palette p) {
    final accent = Paint()..color = _aged(p.accent).withValues(alpha: 0.85);
    final wall = Paint()..color = _aged(p.wall);

    switch (id) {
      case 'dome_office':
        _windows(canvas, w, floorY, wall, accent, count: 3, redOutside: true);
        _desk(canvas, w, floorY, wall, accent);

      case 'dome_hall':
        // 大勢が集まる広間。壁に長い帯と、椅子の列
        canvas.drawRect(
            Rect.fromLTWH(0, floorY - h * 0.10, w, h * 0.035), accent);
        for (var i = 0; i < 6; i++) {
          final x = w * (0.08 + i * 0.17);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(x, floorY + h * 0.03, w * 0.10, h * 0.06),
                const Radius.circular(4)),
            wall,
          );
        }

      case 'dome_lab':
      case 'med_lab':
        // 実験台と、光る計器
        _bench(canvas, w, floorY, wall, accent);
        for (var i = 0; i < 5; i++) {
          canvas.drawCircle(
              Offset(w * (0.12 + i * 0.19), floorY - h * 0.20),
              h * 0.012,
              accent);
        }
        // 冷凍ポッド（med_lab だけ）
        if (id == 'med_lab') {
          for (var i = 0; i < 3; i++) {
            final x = w * (0.16 + i * 0.30);
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(x, floorY - h * 0.30, w * 0.14, h * 0.30),
                Radius.circular(w * 0.07),
              ),
              Paint()..color = _aged(p.accent).withValues(alpha: 0.22),
            );
          }
        }

      case 'greenhouse':
        // 棚に並んだ緑
        for (var row = 0; row < 3; row++) {
          final y = floorY - h * (0.10 + row * 0.14);
          canvas.drawRect(Rect.fromLTWH(0, y, w, h * 0.012), wall);
          for (var i = 0; i < 7; i++) {
            canvas.drawCircle(
                Offset(w * (0.07 + i * 0.145), y - h * 0.022),
                h * 0.020,
                accent);
          }
        }

      case 'engine_bay':
        // 炉。中心に強い光
        canvas.drawCircle(
          Offset(w * 0.5, floorY - h * 0.22),
          h * 0.16,
          Paint()
            ..shader = RadialGradient(colors: [
              const Color(0xFFFFE0A8),
              _aged(p.accent).withValues(alpha: 0.0),
            ]).createShader(Rect.fromCircle(
                center: Offset(w * 0.5, floorY - h * 0.22), radius: h * 0.16)),
        );
        for (final sx in [-1, 1]) {
          canvas.drawRect(
              Rect.fromLTWH(w * 0.5 + sx * w * 0.34 - w * 0.05,
                  floorY - h * 0.42, w * 0.10, h * 0.42),
              wall);
        }

      case 'ship_corridor':
        // 奥へ続く通路。1点透視
        final cx = w * 0.5;
        for (var i = 1; i <= 5; i++) {
          final t = i / 6;
          final rw = w * (1.0 - t * 0.72);
          final rh = (h * 0.62) * (1.0 - t * 0.72);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(cx, floorY - rh * 0.5), width: rw, height: rh),
              Radius.circular(w * 0.03),
            ),
            Paint()
              ..color = _aged(p.wall).withValues(alpha: 0.55)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
        canvas.drawCircle(Offset(cx, floorY - h * 0.16), h * 0.02, accent);

      case 'ship_lounge':
        _windows(canvas, w, floorY, wall, accent, count: 3, stars: true);
        _desk(canvas, w, floorY, wall, accent);

      case 'ship_river':
        // 水面。横に伸びる帯を重ねる
        for (var i = 0; i < 6; i++) {
          final y = floorY + h * (0.02 + i * 0.045);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(w * (0.05 + (i.isEven ? 0 : 0.12)), y,
                    w * (0.7 - i * 0.05), h * 0.010),
                const Radius.circular(6)),
            Paint()..color = _aged(p.accent).withValues(alpha: 0.35),
          );
        }
        _windows(canvas, w, floorY, wall, accent, count: 2, stars: true);

      case 'ship_food':
        // カウンターと、吊るしたのれん
        canvas.drawRect(
            Rect.fromLTWH(0, floorY - h * 0.06, w, h * 0.06), wall);
        for (var i = 0; i < 4; i++) {
          canvas.drawRect(
              Rect.fromLTWH(w * (0.10 + i * 0.22), 0, w * 0.13, h * 0.16),
              accent);
        }

      case 'ship_karaoke':
        // 掲示板と、光る筋
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(w * 0.58, floorY - h * 0.34, w * 0.34, h * 0.26),
              const Radius.circular(8)),
          wall,
        );
        for (var i = 0; i < 5; i++) {
          canvas.drawRect(
              Rect.fromLTWH(w * 0.61, floorY - h * 0.30 + i * h * 0.042,
                  w * 0.28, h * 0.012),
              Paint()..color = Colors.white.withValues(alpha: 0.28));
        }
        for (var i = 0; i < 8; i++) {
          canvas.drawCircle(Offset(w * (0.05 + i * 0.065), h * 0.12),
              h * 0.008, accent);
        }

      case 'ship_archive':
        // 書架。台帳の並び
        for (var row = 0; row < 4; row++) {
          final y = floorY - h * (0.08 + row * 0.13);
          canvas.drawRect(Rect.fromLTWH(0, y, w, h * 0.010), wall);
          for (var i = 0; i < 16; i++) {
            canvas.drawRect(
              Rect.fromLTWH(w * (0.02 + i * 0.061), y - h * 0.048,
                  w * 0.030, h * 0.048),
              Paint()
                ..color = _aged(p.accent)
                    .withValues(alpha: 0.20 + (i % 4) * 0.10),
            );
          }
        }

      case 'ship_bridge':
        // 前面の大窓と、コンソールの光
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(w * 0.06, h * 0.10, w * 0.88, h * 0.42),
              Radius.circular(w * 0.05)),
          Paint()..color = const Color(0xFF04060C),
        );
        _stars(canvas, w * 0.06, h * 0.10, w * 0.88, h * 0.42, 40);
        // LHS 1140（赤い星）
        canvas.drawCircle(
          Offset(w * 0.70, h * 0.26),
          h * 0.055,
          Paint()
            ..shader = const RadialGradient(colors: [
              Color(0xFFFF8A7A),
              Color(0x00FF8A7A),
            ]).createShader(Rect.fromCircle(
                center: Offset(w * 0.70, h * 0.26), radius: h * 0.055)),
        );
        canvas.drawRect(
            Rect.fromLTWH(0, floorY - h * 0.10, w, h * 0.10), wall);
        for (var i = 0; i < 9; i++) {
          canvas.drawCircle(
              Offset(w * (0.07 + i * 0.105), floorY - h * 0.05),
              h * 0.009,
              accent);
        }

      case 'ship_hall':
        // 点呼の広間。整列した足元の光
        _windows(canvas, w, floorY, wall, accent, count: 4, stars: true);
        for (var i = 0; i < 10; i++) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(w * (0.04 + i * 0.096), floorY + h * 0.06,
                    w * 0.055, h * 0.008),
                const Radius.circular(4)),
            accent,
          );
        }

      case 'lhs1140_terminator':
        // 昼と夜の境目。地平に沈みかけた赤い星
        canvas.drawCircle(
          Offset(w * 0.5, floorY),
          h * 0.30,
          Paint()
            ..shader = RadialGradient(colors: [
              const Color(0xFFFFC9A0),
              const Color(0xFFB84A50).withValues(alpha: 0.0),
            ]).createShader(
                Rect.fromCircle(center: Offset(w * 0.5, floorY), radius: h * 0.30)),
        );
        canvas.drawCircle(
            Offset(w * 0.5, floorY), h * 0.13, Paint()..color = const Color(0xFFE86A5A));
        _stars(canvas, 0, 0, w, floorY * 0.6, 26);

      case 'lhs1140_shore':
        // 海。水平線と、ゆるい波
        canvas.drawCircle(
            Offset(w * 0.22, floorY - h * 0.02), h * 0.09,
            Paint()..color = const Color(0xFFE8806A));
        canvas.drawRect(
            Rect.fromLTWH(0, floorY, w, h - floorY),
            Paint()..color = const Color(0xFF16303F));
        for (var i = 0; i < 7; i++) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(w * (0.02 + (i.isEven ? 0.05 : 0.18)),
                    floorY + h * (0.03 + i * 0.038), w * 0.62, h * 0.008),
                const Radius.circular(6)),
            Paint()..color = Colors.white.withValues(alpha: 0.10),
          );
        }

      case 'lhs1140_city':
        // 浮遊都市。手前に灯りの並ぶ塔
        for (var i = 0; i < 7; i++) {
          final bw = w * 0.09;
          final bh = h * (0.14 + (i % 3) * 0.09);
          final x = w * (0.04 + i * 0.135);
          canvas.drawRect(Rect.fromLTWH(x, floorY - bh, bw, bh), wall);
          for (var k = 0; k < 4; k++) {
            canvas.drawRect(
              Rect.fromLTWH(x + bw * 0.22, floorY - bh + h * (0.02 + k * 0.032),
                  bw * 0.55, h * 0.012),
              accent,
            );
          }
        }

      default:
        _windows(canvas, w, floorY, wall, accent, count: 3, stars: true);
    }
  }

  // ── 部品 ──

  void _windows(Canvas canvas, double w, double floorY, Paint wall, Paint accent,
      {int count = 3, bool stars = false, bool redOutside = false}) {
    final ww = w * 0.20;
    final gap = (w - ww * count) / (count + 1);
    for (var i = 0; i < count; i++) {
      final x = gap + i * (ww + gap);
      final rect = Rect.fromLTWH(x, floorY * 0.22, ww, floorY * 0.42);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(w * 0.02)),
        Paint()
          ..color = redOutside
              ? const Color(0xFF7A2A20)
              : const Color(0xFF04060C),
      );
      if (stars) _stars(canvas, rect.left, rect.top, rect.width, rect.height, 10);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(w * 0.02)),
        Paint()
          ..color = accent.color.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _desk(Canvas canvas, double w, double floorY, Paint wall, Paint accent) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.16, floorY - w * 0.03, w * 0.68, w * 0.035),
          const Radius.circular(4)),
      wall,
    );
  }

  void _bench(Canvas canvas, double w, double floorY, Paint wall, Paint accent) {
    canvas.drawRect(
        Rect.fromLTWH(0, floorY - w * 0.045, w, w * 0.045), wall);
  }

  /// 星。**位置を固定する**（毎フレーム乱数だとチカチカして読めない）。
  void _stars(Canvas canvas, double x, double y, double w, double h, int n) {
    final rng = Random(1140);
    final p = Paint()..color = Colors.white;
    for (var i = 0; i < n; i++) {
      final sx = x + rng.nextDouble() * w;
      final sy = y + rng.nextDouble() * h;
      canvas.drawCircle(
          Offset(sx, sy), rng.nextDouble() * 1.3 + 0.5,
          p..color = Colors.white.withValues(alpha: 0.35 + rng.nextDouble() * 0.5));
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter old) => old.id != id || old.age != age;
}
