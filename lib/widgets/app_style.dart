import 'package:flutter/material.dart';

/// 🎨 見た目の決まりごとを1か所にまとめたもの。
///
/// 画面ごとに色と影を作り込んでいくと、同じアプリの中で
/// 「派手な画面」と「落ち着いた画面」が混ざる。実際そうなっていたので、
/// **決まりはここにだけ書き、各画面はここから借りる**形にする。
///
/// 決まりは3つだけ。
///   1. 色数を絞る … 地は明るい灰白、文字は黒か白、効かせる色はゴールド1色
///   2. 影を落とす … 立体的な影・太い枠・グラデーションは使わない
///   3. 順番は文字で示す … 見出しは小さく字間を広く、本文との差は大きさで作る
///
/// ⚠️ ホームだけは地が濃紺（`HomeTheme.darkBackground`）。
///    そこでは [onDark] の色を使うこと。本文が黒の画面で濃い地を使うと
///    文字が読めなくなる。
class AppStyle {
  AppStyle._();

  // ── 色 ──────────────────────────────────────────────
  /// 効かせる唯一の色。白い地の上で読める濃さにしてある。
  static const Color gold = Color(0xFFB08D4F);

  /// 明るい面の上に置くときの、少し濃いゴールド。
  static const Color goldOnLight = Color(0xFFB08D4F);

  /// 濃い地の上のゴールド（[gold] と同じ。呼び出し側の互換のため残す）。
  static const Color goldOnDark = Color(0xFFE9C87A);

  /// 区切り線。髪の毛ほどの細さで置く。
  static const Color line = Color(0x22000000);
  static const Color lineOnDark = Color(0x22FFFFFF);

  /// 画面の地。**白基調に戻した。**
  ///
  /// 2026-08 に濃紺へ寄せたが、黒文字が沈んで読めないという報告が続いた。
  /// 地は白（明るい灰白）に戻し、文字は黒側に寄せる。
  static const Color canvas = Color(0xFFF7F5F2);

  /// カードなど、地からひとつ持ち上げる面。
  static const Color surface = Colors.white;

  /// さらに上に重ねる面（カードの中のカード）。
  static const Color surfaceHigh = Color(0xFFF0EDE8);

  /// 文字。見出し・本文・添え物の3段だけ。
  static const Color text = Color(0xFF2C3446);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textFaint = Color(0xFF9AA0A6);

  // ── 文字づかい ──────────────────────────────────────
  /// 節の見出し。小さく、字間を広く、大文字。
  static const TextStyle sectionLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.0,
    color: textFaint,
  );

  /// カードや行の見出し。
  static const TextStyle title = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    color: text,
  );

  /// 本文。
  static const TextStyle body = TextStyle(
    fontSize: 13,
    height: 1.5,
    color: textMuted,
  );

  /// 数字を見せるとき（得点・コイン）。字は細く、大きさで見せる。
  static const TextStyle figure = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w300,
    letterSpacing: 1.0,
    color: text,
  );

  /// 見出しの下に置く短い横線。長い罫線を引くより軽い。
  static Widget rule({double width = 24, Color color = gold}) =>
      Container(width: width, height: 1, color: color);

  /// 節の見出し（横線つき）。
  static Widget section(String label, {bool onDark = false}) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 12, left: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stripLeadingSymbols(label).toUpperCase(),
              style: sectionLabel.copyWith(
                  color: onDark ? const Color(0x99FFFFFF) : textFaint),
            ),
            const SizedBox(height: 6),
            rule(color: onDark ? goldOnDark : gold),
          ],
        ),
      );

  /// 枠だけのカード。影は付けない。
  static Widget card({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(18),
    bool onDark = false,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: onDark ? Colors.white.withValues(alpha: 0.03) : surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: onDark ? lineOnDark : line, width: 1),
        ),
        padding: padding,
        child: child,
      );

  /// 主役のボタン。塗りはゴールド1色、影は付けない。
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: gold,
    // 濃いゴールドの上は白字のほうが読める
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(vertical: 18),
    shape: const StadiumBorder(),
    textStyle: const TextStyle(
        fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.4),
  );

  /// 添えのボタン。枠だけ。
  static ButtonStyle secondaryButton = OutlinedButton.styleFrom(
    foregroundColor: gold,
    side: const BorderSide(color: gold, width: 1.2),
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: const StadiumBorder(),
    textStyle: const TextStyle(
        fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3),
  );

  /// 文字列の先頭についた絵文字・記号を落とす。
  ///
  /// 見出しの頭に絵文字を置く書き方が全画面に散っていて、
  /// 節ごとに絵柄と色が増えて散らかっていた。呼び出し側を全部書き換える
  /// 代わりに、**表示するときに機械的に落とす**。
  static String stripLeadingSymbols(String s) =>
      s.replaceAll(RegExp(r'^[^\p{L}\p{N}]+', unicode: true), '').trim();
}
