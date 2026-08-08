/// SPEC 4.2 / 4.3 — 記憶テスト（3択）と記憶率。
library;

import 'dart:math';

import '../models/noah_field.dart';

/// 出題1問ぶん。
class MemQuestion {
  final NoahCharacter target;
  final NoahField field;

  /// 3つの選択肢（並びはシャッフル済み）。
  final List<String> choices;

  const MemQuestion({
    required this.target,
    required this.field,
    required this.choices,
  });

  String get answer => target.valueOf(field);
  bool isCorrect(String picked) => picked == answer;
}

/// 3択を作る。
///
/// ⚠️ **誤答は「別のキャラクターの実データ」から取る**（SPEC 4.2）。
///    でたらめな造語を混ぜると、知らない語を消すだけで正解できてしまい、
///    覚えていなくても当たる。実データ同士でぶつけるからこそ
///    「あの人と混ざっている」という手触りになる。
///
/// [pool] は誤答を取る相手。ふつうは「すでに出会った人」を渡す。
/// 足りなければ [all] から補う（3択が作れないほうが困る）。
MemQuestion buildQuestion({
  required NoahCharacter target,
  required NoahField field,
  required List<NoahCharacter> pool,
  required List<NoahCharacter> all,
  Random? random,
}) {
  final rng = random ?? Random();
  final answer = target.valueOf(field);

  // 候補: 自分以外の実データ。値が同じもの・空のものは選択肢にならない。
  List<String> wrongFrom(List<NoahCharacter> src) => [
        for (final c in src)
          if (c.id != target.id &&
              c.valueOf(field).isNotEmpty &&
              c.valueOf(field) != answer)
            c.valueOf(field),
      ];

  final seen = <String>{};
  final wrong = <String>[];
  void addFrom(List<NoahCharacter> src) {
    final cands = wrongFrom(src)..shuffle(rng);
    for (final v in cands) {
      if (wrong.length >= 2) return;
      if (seen.add(v)) wrong.add(v);
    }
  }

  addFrom(pool);
  if (wrong.length < 2) addFrom(all); // 出会った人が少ないうちは全員から補う

  return MemQuestion(
    target: target,
    field: field,
    choices: [answer, ...wrong]..shuffle(rng),
  );
}

/// 記憶の帳簿。正解した (キャラ,項目) と、汚染ペアを持つ。
class MemoryStore {
  /// `hibino.hobby` → 正解したか。
  final Map<String, bool> _memory;

  /// 誤答の記録。「誰の答えと混ざったか」を残す（バックログ汚染に使う）。
  /// `hibino.hobby` → 選んでしまった値。
  final Map<String, String> _contaminated;

  MemoryStore({
    Map<String, bool>? memory,
    Map<String, String>? contaminated,
  })  : _memory = {...?memory},
        _contaminated = {...?contaminated};

  Map<String, bool> get memory => Map.unmodifiable(_memory);
  Map<String, String> get contaminated => Map.unmodifiable(_contaminated);

  bool knows(NoahCharacter c, NoahField f) => _memory[c.memoryKey(f)] == true;

  /// 答え合わせ。**間違えても減点はしない**（SPEC 4.2）。
  /// 罰を与えるのではなく、覚えていない事実がそのまま帰結になる。
  bool answer(MemQuestion q, String picked) {
    final key = q.target.memoryKey(q.field);
    final ok = q.isCorrect(picked);
    if (ok) {
      _memory[key] = true;
      _contaminated.remove(key); // 覚え直したら汚染は消える
    } else {
      // ⚠️ 一度正解した記録は消さない。記憶率は「到達した最大」を測る。
      _memory.putIfAbsent(key, () => false);
      _contaminated[key] = picked;
    }
    return ok;
  }

  int get correctCount => _memory.values.where((v) => v).length;
}
