/// ✨ 演出（SPEC 3.1）— シェイク・フラッシュ・フェード。
///
/// シナリオの `{"t":"fx","kind":"shake"}` を受けて画面を揺らす。
/// これが無いと、警報が鳴っても画面が静かなままで、
/// 台本が「衝撃」と書いているのに何も起きない。
///
/// ⚠️ **画面のゆれは、人によっては気分が悪くなる。**
///    コンフィグの「ゆれを弱める」がONのときは、
///    揺らさずに明滅だけにする（SPEC 3.5 アクセシビリティ）。
library;

import 'package:flutter/material.dart';

/// 演出の種類。知らない名前が来たら [none]。
enum FxKind { none, shake, flash, fadeBlack, fadeWhite }

FxKind fxFromKey(String? key) => switch (key) {
      'shake' => FxKind.shake,
      'flash' => FxKind.flash,
      'fadeBlack' => FxKind.fadeBlack,
      'fadeWhite' => FxKind.fadeWhite,
      _ => FxKind.none,
    };

/// 子を包んで、[play] を呼ぶと1回だけ演出する。
class FxLayer extends StatefulWidget {
  final Widget child;

  /// ゆれを弱める（アクセシビリティ）。
  final bool reduceShake;

  const FxLayer({
    super.key,
    required this.child,
    this.reduceShake = false,
  });

  @override
  State<FxLayer> createState() => FxLayerState();
}

class FxLayerState extends State<FxLayer> with TickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  FxKind _kind = FxKind.none;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// 演出を1回流す。
  void play(FxKind kind) {
    if (kind == FxKind.none) return;
    setState(() => _kind = kind);
    _c
      ..duration = switch (kind) {
        FxKind.shake => const Duration(milliseconds: 520),
        FxKind.flash => const Duration(milliseconds: 380),
        _ => const Duration(milliseconds: 900),
      }
      ..forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        final running = _c.isAnimating;

        var content = child!;

        // ── ゆれ
        if (_kind == FxKind.shake && running && !widget.reduceShake) {
          // だんだん収まる揺れ。ずっと同じ幅で揺れると酔う。
          final damp = (1 - t) * (1 - t);
          // 6.3 は 1秒で約3往復。速すぎると振動に、遅すぎると船酔いに見える。
          final dx = 14 * damp * _wave(t * 6.3);
          final dy = 5 * damp * _wave(t * 9.1 + 1.2);
          content = Transform.translate(offset: Offset(dx, dy), child: content);
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            if (running) ..._overlay(t),
          ],
        );
      },
      child: widget.child,
    );
  }

  List<Widget> _overlay(double t) {
    switch (_kind) {
      case FxKind.flash:
        // 立ち上がりが速く、引きが遅い。写真のフラッシュに近い出かた。
        final a = (1 - t) * (1 - t) * 0.85;
        return [IgnorePointer(child: Container(color: Colors.white.withValues(alpha: a)))];
      case FxKind.shake:
        // ゆれを弱める設定のときは、代わりに軽く赤く明滅させる。
        // 「何か起きた」ことは伝えたいので、無反応にはしない。
        if (!widget.reduceShake) return const [];
        final a = (1 - t) * 0.28;
        return [
          IgnorePointer(
              child: Container(color: const Color(0xFFFF4A3C).withValues(alpha: a)))
        ];
      case FxKind.fadeBlack:
      case FxKind.fadeWhite:
        // 0→1→0。いったん覆って、また戻る。
        final a = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.0, 1.0);
        final c = _kind == FxKind.fadeBlack ? Colors.black : Colors.white;
        return [IgnorePointer(child: Container(color: c.withValues(alpha: a)))];
      case FxKind.none:
        return const [];
    }
  }

  /// -1〜1 を行き来する波。sin を使わずに済ませて、依存を増やさない。
  double _wave(double x) {
    final p = (x % 2.0) - 1.0; // -1..1 の鋸波
    return 2 * p.abs() - 1; // 三角波に変える
  }
}

/// 章が変わったときに出すカード（SPEC 3.6）。
///
/// 幕が変わったことが分かると、長い話でも現在地がつかめる。
class ChapterCard extends StatelessWidget {
  final String chapter;
  const ChapterCard({super.key, required this.chapter});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        color: Colors.black.withValues(alpha: 0.72),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 46, height: 1.4, color: const Color(0xFFD4A24C)),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                chapter,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  height: 1.7,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFFE8ECF1),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(width: 46, height: 1.4, color: const Color(0xFFD4A24C)),
          ],
        ),
      ),
    );
  }
}
