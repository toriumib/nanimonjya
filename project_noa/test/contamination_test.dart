import 'package:flutter_test/flutter_test.dart';

import 'package:project_noa/engine/scene_player.dart';
import 'package:project_noa/models/noah_field.dart';
import 'package:project_noa/models/scene_script.dart';
import 'package:project_noa/systems/contamination.dart';

/// SPEC 4.5 — バックログ汚染。
///
/// ここは壊れかたが分かりにくい。
/// 正典を書き換えてしまうと**元に戻せなく**なり、
/// 乱数を固定しないと**開くたび名前が変わって**バグに見える。
void main() {
  const names = ['日比野', '桐生', '水原', '橘', '星野'];

  group('差し替え', () {
    test('濁りが0なら、1文字も変えない', () {
      const t = '日比野さんと桐生さんが話している。';
      expect(contaminate(t, level: 0, names: names, seed: 1), t);
    });

    test('名前が入っていない文は変わらない', () {
      const t = 'ドームの朝は、鐘ではじまらない。';
      expect(contaminate(t, level: 1.0, names: names, seed: 1), t);
    });

    test('濁ると、名前が別の人の名前に変わる', () {
      const t = '日比野さんが笑った。';
      final out = contaminate(t, level: 1.0, names: names, seed: 3);
      expect(out, isNot(t));
      // 造語ではなく、**別の実在の名前**に変わっていること
      final replaced = names.where((n) => n != '日比野' && out.contains(n));
      expect(replaced, isNotEmpty,
          reason: 'でたらめな語ではなく、他のキャラの名前に入れ替わる');
    });

    test('同じ行なら、何度描いても同じ結果になる', () {
      // ここが崩れると、スクロールのたび名前が変わって
      // 「にじみ」ではなく「バグ」に見える。
      const t = '日比野さんと桐生さんが話している。';
      final a = contaminate(t, level: 0.8, names: names, seed: 7);
      final b = contaminate(t, level: 0.8, names: names, seed: 7);
      expect(a, b);
    });

    test('行が違えば、濁りかたも違う', () {
      const t = '日比野さんが笑った。';
      final a = contaminate(t, level: 1.0, names: names, seed: 1);
      final b = contaminate(t, level: 1.0, names: names, seed: 2);
      // 必ず違うとは限らないが、10行も見れば違いが出る
      final all = [
        for (var i = 0; i < 10; i++)
          contaminate(t, level: 1.0, names: names, seed: i)
      ];
      expect(all.toSet().length, greaterThan(1), reason: '$a / $b');
    });

    test('候補が1人しかいなければ、何も起きない', () {
      const t = '日比野さんが笑った。';
      expect(contaminate(t, level: 1.0, names: ['日比野'], seed: 1), t);
    });

    test('濁った行かどうかを見分けられる', () {
      const t = '日比野さんが笑った。';
      final out = contaminate(t, level: 1.0, names: names, seed: 3);
      expect(isContaminated(t, out), isTrue);
      expect(isContaminated(t, t), isFalse);
    });
  });

  group('濁りの増減', () {
    NoahCharacter c(String id, String name) => NoahCharacter(
          id: id,
          name: name,
          reading: '',
          affiliation: '$name研',
          hobby: '$name趣味',
          commId: 'ID-$id',
          school: '$name大',
          regret: '',
          cast: 1,
          romance: true,
          color: 0,
          emoji: '🙂',
        );
    final cast = NoahCast([
      c('a', '日比野'),
      c('b', '桐生'),
      c('c', '水原'),
      c('d', '橘'),
    ]);

    Scene scene(List<Map<String, dynamic>> lines) => Scene.fromJson({
          'id': 'test',
          'chapter': '',
          'bg': '',
          'lines': lines,
        });

    test('眠るほど濁る', () {
      final p = ScenePlayer(
        scene: scene([
          {'t': 'skip28y'},
          {'t': 'skip28y'},
          {'t': 'mono', 'text': 'あ'},
        ]),
        cast: cast,
      )..start();
      expect(p.contamination, closeTo(kContaminationPerCycle * 2, 1e-9));
    });

    test('上限を超えない（全部の名前が入れ替わって読めなくなるのを防ぐ）', () {
      final p = ScenePlayer(
        scene: scene([
          for (var i = 0; i < 30; i++) {'t': 'skip28y'},
          {'t': 'mono', 'text': 'あ'},
        ]),
        cast: cast,
      )..start();
      expect(p.contamination, kContaminationMax);
    });

    test('思い出すと、濁りが少し晴れる', () {
      final p = ScenePlayer(
        scene: scene([
          {'t': 'skip28y'},
          {'t': 'skip28y'},
          {'t': 'memtest', 'char': 'a', 'field': 'hobby'},
        ]),
        cast: cast,
      )..start();
      final before = p.contamination;
      p.answerMemTest('日比野趣味'); // 正解
      expect(p.contamination, lessThan(before));
    });

    test('まちがえたときは晴れない', () {
      final p = ScenePlayer(
        scene: scene([
          {'t': 'skip28y'},
          {'t': 'memtest', 'char': 'a', 'field': 'hobby'},
        ]),
        cast: cast,
      )..start();
      final before = p.contamination;
      p.answerMemTest('桐生趣味'); // 誤答
      expect(p.contamination, before);
    });

    test('濁りは0を下回らない', () {
      final p = ScenePlayer(
        scene: scene([
          {'t': 'memtest', 'char': 'a', 'field': 'hobby'},
        ]),
        cast: cast,
      )..start();
      p.answerMemTest('日比野趣味');
      expect(p.contamination, 0);
    });

    test('セーブして戻しても、濁りが引き継がれる', () {
      final s = scene([
        {'t': 'skip28y'},
        {'t': 'skip28y'},
        {'t': 'mono', 'text': 'あ'},
      ]);
      final p = ScenePlayer(scene: s, cast: cast)..start();
      final save = p.toSave(slot: 0, playSec: 0);
      expect(save.contamination, greaterThan(0));

      final q = ScenePlayer(scene: s, cast: cast)..restore(save);
      expect(q.contamination, closeTo(save.contamination, 1e-9));
    });

    test('差し替え候補は、姓だけで取れる', () {
      final p = ScenePlayer(scene: scene([]), cast: cast);
      expect(p.familyNames, containsAll(['日比野', '桐生', '水原', '橘']));
    });
  });
}
