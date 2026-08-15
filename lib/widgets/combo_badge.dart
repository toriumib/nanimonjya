import 'package:flutter/material.dart';

import 'celebration.dart' show kPopFont;

/// 🔥 連続正解のバッジ。
///
/// ■ なぜ要るか
/// 1回ごとの正解音だけだと、**10問目も30問目も同じ手ごたえ**になる。
/// 既定を山札60枚にしたので、途中で気持ちが切れやすい。
/// 積み上がっているものを見せると、途切れさせたくなくなる。
///
/// ⚠️ 2026-08 のデータで、229試合のうち102件が完了も中断もせずに
///    消えていた。長い試合の途中で飽きられている可能性が高い。
///
/// ■ 出しかたの決まり
/// - **1連続では出さない**。毎回出ると、ただの正解表示と変わらない
/// - 5連続から色と文言を変える。同じ見た目が続くと、そこで慣れる
class ComboBadge extends StatelessWidget {
  /// いまの連続正解数。まちがえたら0に戻す。
  final int combo;

  /// これ未満のときは何も描かない。
  static const int minToShow = 2;

  /// ここから「熱い」見た目に変える。
  static const int hotAt = 5;

  /// ここから金色にグレードアップ。
  static const int goldAt = 10;

  const ComboBadge({super.key, required this.combo});

  @override
  Widget build(BuildContext context) {
    if (combo < minToShow) return const SizedBox.shrink();
    final hot = combo >= hotAt;
    final gold = combo >= goldAt;
    return TweenAnimationBuilder<double>(
      // key を数で変えて、増えた瞬間だけ跳ねさせる
      key: ValueKey(combo),
      tween: Tween(begin: 0.5, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.elasticOut,
      builder: (_, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gold
                ? const [Color(0xFFFFC02E), Color(0xFFFF8C00), Color(0xFFFFC02E)]
                : hot
                    ? const [Color(0xFFFF6A3D), Color(0xFFFFC02E)]
                    : const [Color(0xFF62B6FF), Color(0xFF7BE0C8)],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: gold
              ? const [
                  BoxShadow(
                    color: Color(0x66FFD700),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Text(
          gold
              ? '👑 $combo れんぞく！'
              : hot
                  ? '🔥 $combo れんぞく！'
                  : '$combo れんぞく',
          // お祝いの文字は全部おなじ書体にそろえる。ここだけ本文書体だと
          // 「ごほうび」に見えない。
          style: const TextStyle(
              fontFamily: kPopFont, fontSize: 14, color: Colors.white),
        ),
      ),
    );
  }
}
