import 'package:flutter/material.dart';

/// **強調**つきの文章を出す。
///
/// ⚠️ このアプリには Markdown のレンダラが入っていない。
///    それなのに `meta_strings.dart` の文言には `**…**` が書かれていて、
///    素の [Text] に渡していたため、画面に星印がそのまま出ていた。
///    （「**はじめて出た人には、名前をつける。**」がそう見えていた）
///
///    文言から `**` を消してしまう手もあったが、強調したい場所は
///    実際に読ませたい一文なので、太字として出すほうを選んだ。
///
/// 対応するのは `**…**` だけ。見出しやリンクは扱わない。
/// 閉じていない `**` は、ただの文字として出す（消すと文章が欠ける）。
class EmphasisText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  const EmphasisText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    return Text.rich(
      TextSpan(children: parseEmphasis(text, base)),
      textAlign: textAlign,
      style: base,
    );
  }
}

/// `**…**` を太字のスパンに分解する。
///
/// テストしやすいよう、ウィジェットの外に出してある。
List<TextSpan> parseEmphasis(String text, TextStyle base) {
  final bold = base.copyWith(fontWeight: FontWeight.w900);
  final spans = <TextSpan>[];
  var i = 0;
  while (i < text.length) {
    final open = text.indexOf('**', i);
    if (open < 0) {
      spans.add(TextSpan(text: text.substring(i)));
      break;
    }
    final close = text.indexOf('**', open + 2);
    if (close < 0) {
      // 閉じていない。残りはそのまま出す。
      spans.add(TextSpan(text: text.substring(i)));
      break;
    }
    if (open > i) spans.add(TextSpan(text: text.substring(i, open)));
    spans.add(TextSpan(text: text.substring(open + 2, close), style: bold));
    i = close + 2;
  }
  return spans;
}

/// 読み上げ用に `**` を落とす。
///
/// ⚠️ TTS にそのまま渡すと、エンジンによっては記号を読み上げてしまう。
String stripEmphasis(String text) => text.replaceAll('**', '');
