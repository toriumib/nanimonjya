/// SPEC 6章 — シナリオスクリプト（JSON）を読む。
///
/// 1ファイル1シーン。`assets/scenes/<id>.json`。
/// **知らない種類の行は落とさず [LineUnknown] にして読み飛ばす。**
/// シナリオを先に書いてエンジンが後から追いつくことがあるので、
/// 解釈できない行でクラッシュさせない。
library;

import 'dart:convert';

/// 1行ぶんの台本。
sealed class ScriptLine {
  const ScriptLine();

  factory ScriptLine.fromJson(Map<String, dynamic> j) {
    String s(String k) => (j[k] as String?) ?? '';
    switch (s('t')) {
      case 'mono':
        return LineMono(s('text'));
      case 'say':
        return LineSay(
          name: s('name'),
          text: s('text'),
          sprite: s('sprite'),
          slot: s('slot').isEmpty ? 'center' : s('slot'),
        );
      case 'fx':
        return LineFx(s('kind'));
      case 'se':
        return LineSe(s('id'));
      case 'bgm':
        return LineBgm(id: s('id'), fade: (j['fade'] as num?)?.toDouble() ?? 1.0);
      case 'bg':
        return LineBg(id: s('id'), age: (j['bgAge'] as num?)?.toInt() ?? 0);
      case 'choice':
        return LineChoice([
          for (final o in (j['options'] as List? ?? const []))
            ChoiceOption(
              text: (o as Map<String, dynamic>)['text'] as String? ?? '',
              jump: o['jump'] as String? ?? '',
            ),
        ]);
      case 'memtest':
        return LineMemTest(charId: s('char'), field: s('field'));
      case 'input':
        return LineNameInput(
          expect: s('expect'),
          onSuccess: s('onSuccess'),
        );
      case 'flag':
        return LineFlag(s('set'));
      case 'skip28y':
        return const LineSkip28y();
      case 'jump':
        return LineJump(s('to'));
      default:
        return LineUnknown(s('t'));
    }
  }

  /// バックログに残る行か（地の文と台詞だけ残す）。
  bool get isText => this is LineMono || this is LineSay;
}

/// 地の文。
class LineMono extends ScriptLine {
  final String text;
  const LineMono(this.text);
}

/// 台詞。[sprite] は `tsuchikura/normal` の形。
class LineSay extends ScriptLine {
  final String name;
  final String text;
  final String sprite;

  /// 立ち絵をどこに置くか（left / center / right）。
  final String slot;

  const LineSay({
    required this.name,
    required this.text,
    this.sprite = '',
    this.slot = 'center',
  });
}

/// 演出（shake / flash / fadeBlack / fadeWhite）。
class LineFx extends ScriptLine {
  final String kind;
  const LineFx(this.kind);
}

class LineSe extends ScriptLine {
  final String id;
  const LineSe(this.id);
}

class LineBgm extends ScriptLine {
  final String id;
  final double fade;
  const LineBgm({required this.id, this.fade = 1.0});
}

class LineBg extends ScriptLine {
  final String id;
  final int age;
  const LineBg({required this.id, this.age = 0});
}

class ChoiceOption {
  final String text;
  final String jump;
  const ChoiceOption({required this.text, required this.jump});
}

class LineChoice extends ScriptLine {
  final List<ChoiceOption> options;
  const LineChoice(this.options);
}

/// 3択の記憶テスト（SPEC 4.2）。選択肢はここでは持たない。
/// **誤答は他キャラの実データから毎回組み立てる**ので、実行時に作る。
class LineMemTest extends ScriptLine {
  final String charId;
  final String field;
  const LineMemTest({required this.charId, required this.field});
}

/// 名前入力（SPEC 4.7 最終テスト）。
class LineNameInput extends ScriptLine {
  final String expect;
  final String onSuccess;
  const LineNameInput({required this.expect, required this.onSuccess});
}

class LineFlag extends ScriptLine {
  final String set;
  const LineFlag(this.set);
}

/// 28年の冷凍睡眠。老化レベルを1つ進める（SPEC 4.8）。
class LineSkip28y extends ScriptLine {
  const LineSkip28y();
}

class LineJump extends ScriptLine {
  final String to;
  const LineJump(this.to);
}

/// エンジンがまだ知らない種類の行。**無視して次へ進む**。
class LineUnknown extends ScriptLine {
  final String kind;
  const LineUnknown(this.kind);
}

/// シーン1つ。
class Scene {
  final String id;
  final String chapter;
  final String bg;
  final int bgAge;
  final String bgm;
  final double bgmFade;
  final List<ScriptLine> lines;

  const Scene({
    required this.id,
    required this.chapter,
    required this.bg,
    required this.bgAge,
    required this.bgm,
    required this.bgmFade,
    required this.lines,
  });

  factory Scene.fromJson(Map<String, dynamic> j) {
    String s(String k) => (j[k] as String?) ?? '';
    final bgmObj = j['bgm'];
    return Scene(
      id: s('id'),
      chapter: s('chapter'),
      bg: s('bg'),
      bgAge: (j['bgAge'] as num?)?.toInt() ?? 0,
      bgm: bgmObj is Map ? (bgmObj['id'] as String? ?? '') : '',
      bgmFade: bgmObj is Map ? ((bgmObj['fade'] as num?)?.toDouble() ?? 1.0) : 1.0,
      lines: [
        for (final l in (j['lines'] as List? ?? const []))
          ScriptLine.fromJson(l as Map<String, dynamic>),
      ],
    );
  }

  static Scene parse(String jsonText) =>
      Scene.fromJson(jsonDecode(jsonText) as Map<String, dynamic>);
}
