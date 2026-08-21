import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:nanimonjya/models/person.dart';

/// 🎯 4択が「4択として成立している」ことを守るテスト。
///
/// 復習キュー（期限が来た人だけ）や、2〜3人しか登録していない顔メモでは、
/// 出題できる人数が足りず選択肢が正解＋1個になっていた。
/// 覚えていなくても当たってしまい、テストとして意味がなくなる。
void main() {
  test('人数が足りなくても、ダミーで4択ぶんの選択肢を作れる', () {
    final d = recallDistractors(RecallField.name,
        ja: true, count: 3, like: '佐藤さん', random: Random(1));
    expect(d.length, 3);
    expect(d.toSet().length, 3, reason: '選択肢が重複しない');
  });

  test('正解や、すでに出ている名前とはかぶらない', () {
    final exclude = {'佐藤さん', '鈴木さん', '高橋さん'};
    final d = recallDistractors(RecallField.name,
        ja: true, count: 3, like: '佐藤さん', exclude: exclude, random: Random(2));
    expect(d.length, 3);
    for (final v in d) {
      expect(exclude.contains(v), isFalse, reason: '$v がかぶっている');
    }
  });

  test('敬称の有無を正解にそろえる（そこだけ違うと答えが割れる）', () {
    final withSan = recallDistractors(RecallField.name,
        ja: true, count: 3, like: '佐藤さん', random: Random(3));
    expect(withSan.every((v) => v.endsWith('さん')), isTrue);

    // 顔メモの名前は自由入力なので敬称がないことが多い
    final bare = recallDistractors(RecallField.name,
        ja: true, count: 3, like: '田中', random: Random(3));
    expect(bare.any((v) => v.endsWith('さん')), isFalse);
  });

  test('英語のときは英語名から作る', () {
    final d = recallDistractors(RecallField.name,
        ja: false, count: 3, like: 'Smith', random: Random(4));
    expect(d.length, 3);
    expect(d.every((v) => !v.endsWith('さん')), isTrue);
  });

  test('名前以外の項目（会社名・肩書）もダミーを作れる', () {
    for (final f in [RecallField.company, RecallField.title]) {
      final d = recallDistractors(f, ja: true, count: 3, random: Random(5));
      expect(d.length, 3, reason: '$f のダミーが足りない');
      expect(d.every((v) => v.trim().isNotEmpty), isTrue);
    }
  });

  test('0個を求められたら空で返す', () {
    expect(recallDistractors(RecallField.name, ja: true, count: 0), isEmpty);
  });
}
