/// 🎉 「気持ちいい」を作るための部品。
///
/// ■ なぜ要るか
/// 2026-08 の計測で、229試合のうち **102件が完了も中断もせずに消えて**いた。
/// Crashlytics で「落ちていない」ことが確定したので、残る説明は
/// **途中で飽きて外に出たまま戻らない**。
/// 既定を山札60枚にしたぶん1試合が長いので、手ざわりが弱いと切れる。
///
/// ■ 作りかたの決まり
/// - **短くする。** カード獲得は0.9秒、勝利でも1.5秒で終わらせる。
///   ここが長いと「次の1回」に入る前に閉じられる
/// - **操作を止めない。** すべて [IgnorePointer] で乗せるだけ
/// - **外部パッケージを足さない。** 紙吹雪も自前で描く
library;

import 'dart:math';

import 'package:flutter/material.dart';

/// お祝いに使う極太フォント。
///
/// ⚠️ **`assets/fonts/DelaGothicOne-Pop.ttf` は出す文言の字しか入っていない。**
///    文言を変えたら `tools/subset_logo_font.py` の `CELEBRATION_TEXT` に
///    足して回し直すこと。入っていない字は豆腐（□）になる。
const String kPopFont = 'DelaGothicOne';

/// 🎴 カードを取ったときに出す帯。
///
/// 下から跳ね上がって、少し傾いて、消える。
class GetBanner extends StatelessWidget {
  /// 出す文字。例: 「カードゲット！」「P1 がゲット！」
  final String text;

  /// 帯の色。プレイヤーごとに変えると誰が取ったか一目で分かる。
  final List<Color> colors;

  const GetBanner({
    super.key,
    required this.text,
    this.colors = const [Color(0xFFFF6A3D), Color(0xFFFFC02E)],
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOut,
        builder: (_, t, child) {
          // 0→0.25 で跳ね上がり、0.75→1 で消える
          final rise = Curves.elasticOut.transform((t / 0.25).clamp(0.0, 1.0));
          final fade = t < 0.75 ? 1.0 : 1 - ((t - 0.75) / 0.25);
          return Opacity(
            opacity: fade.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, 40 * (1 - rise)),
              child: Transform.rotate(
                angle: -0.04,
                child: Transform.scale(scale: 0.7 + 0.3 * rise, child: child),
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x44000000), blurRadius: 12, offset: Offset(0, 4)),
            ],
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: kPopFont,
              fontSize: 22,
              color: Colors.white,
              shadows: [
                Shadow(offset: Offset(0, 2), color: Color(0x66000000)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 🎊 紙吹雪。
///
/// ⚠️ パッケージを足さずに自前で描く。依存を1つ増やすたびに
///    ビルドとアップデートの手間が増えるので、この程度は自分で持つ。
class Confetti extends StatefulWidget {
  /// 紙の枚数。多いほど重い。60〜120で足りる。
  final int count;

  /// 流す時間。
  final Duration duration;

  /// 種。テストで同じ絵を出したいときに固定する。
  final int? seed;

  const Confetti({
    super.key,
    this.count = 80,
    this.duration = const Duration(milliseconds: 1500),
    this.seed,
  });

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration)..forward();
  late final List<_Paper> _papers = _make();

  static const _colors = [
    Color(0xFFFF6A3D),
    Color(0xFFFFC02E),
    Color(0xFF62B6FF),
    Color(0xFF7BE0C8),
    Color(0xFFFF7FB6),
  ];

  List<_Paper> _make() {
    final r = Random(widget.seed ?? DateTime.now().microsecond);
    return [
      for (var i = 0; i < widget.count; i++)
        _Paper(
          x: r.nextDouble(),
          // 上のほうから時間差で降らせる。全部同時だと壁のように見える
          delay: r.nextDouble() * 0.35,
          drift: (r.nextDouble() - 0.5) * 0.5,
          spin: (r.nextDouble() - 0.5) * 12,
          size: 6 + r.nextDouble() * 8,
          color: _colors[r.nextInt(_colors.length)],
        ),
    ];
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(
            painter: _ConfettiPainter(_papers, _c.value),
            size: Size.infinite,
          ),
        ),
      );
}

class _Paper {
  final double x, delay, drift, spin, size;
  final Color color;
  const _Paper({
    required this.x,
    required this.delay,
    required this.drift,
    required this.spin,
    required this.size,
    required this.color,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Paper> papers;
  final double t;
  _ConfettiPainter(this.papers, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in papers) {
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      // 落下は少し加速させる。等速だと紙に見えない
      final y = (local * local * 0.75 + local * 0.35) * size.height;
      final x = (p.x + p.drift * local) * size.width;
      // 終わりぎわに消す
      final fade = local > 0.8 ? (1 - (local - 0.8) / 0.2) : 1.0;
      paint.color = p.color.withValues(alpha: fade.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y - size.height * 0.1);
      canvas.rotate(p.spin * local);
      // 細長い長方形。回るとひらひらして見える
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: p.size, height: p.size * 0.55),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

/// 🏆 勝利の瞬間。フラッシュ → 紙吹雪。
///
/// ⚠️ **1.5秒で終わらせる。** ここを長くすると次の試合に入らなくなる。
class VictoryBurst extends StatelessWidget {
  /// 中央に出す文字。空なら紙吹雪だけ。
  final String text;

  const VictoryBurst({super.key, this.text = ''});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 白フラッシュ。立ち上がりが速く、引きが遅い
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 420),
            builder: (_, t, __) => Container(
              color: Colors.white.withValues(alpha: (1 - t) * (1 - t) * 0.8),
            ),
          ),
          const Confetti(),
          if (text.isNotEmpty)
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                builder: (_, t, child) =>
                    Transform.scale(scale: 0.4 + 0.6 * t, child: child),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: kPopFont,
                    fontSize: 40,
                    color: Color(0xFFFF6A3D),
                    shadows: [
                      Shadow(
                          offset: Offset(0, 3),
                          blurRadius: 2,
                          color: Colors.white),
                      Shadow(
                          offset: Offset(0, 6),
                          blurRadius: 10,
                          color: Color(0x55000000)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 数字がパチパチ上がる表示。結果画面の得点に使う。
///
/// 出来上がった数をいきなり出すより、**上がっていくところを見せる**ほうが
/// 「稼いだ」感じが出る。
class CountUpText extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final String prefix;
  final Duration duration;

  const CountUpText({
    super.key,
    required this.value,
    this.style,
    this.prefix = '',
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.toDouble()),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => Text('$prefix${v.round()}', style: style),
      );
}
