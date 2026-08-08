import 'package:flutter_test/flutter_test.dart';

import 'package:project_noa/models/noah_field.dart';
import 'package:project_noa/models/save_data.dart';

/// SPEC 4.3 / 4.6 / 7章。
///
/// ここが崩れると「解禁が巻き戻る」「セーブを積み直すと記憶率が上がる」
/// といった、遊んだ本人には理由の分からない壊れ方をする。
void main() {
  group('記憶率', () {
    test('分母は キャラ数 × 項目数', () {
      expect(totalPairsFor(17), 17 * NoahField.values.length);
    });

    test('割合と表示（SPEC の例 43.75%）', () {
      final r = memoryRate(correct: 7, totalPairs: 16);
      expect(r, 0.4375);
      expect(memoryRateLabel(r), '43.75%');
    });

    test('出題が無くても落ちない（0除算をしない）', () {
      expect(memoryRate(correct: 0, totalPairs: 0), 0);
    });
  });

  group('周回の解禁（SPEC 4.6）', () {
    test('1周目は何も解禁されていない', () {
      final u = resolveUnlocks(cleared: 0, maxRate: 1.0);
      expect(u.cast2, isFalse);
      expect(u.mysteries, isFalse);
    });

    test('1周クリアで2周目のキャストが解禁', () {
      expect(resolveUnlocks(cleared: 1, maxRate: 0).cast2, isTrue);
    });

    test('船内の謎は 3周目 かつ 記憶率60%以上', () {
      expect(resolveUnlocks(cleared: 2, maxRate: 0.59).mysteries, isFalse,
          reason: '周回は足りても記憶率が足りない');
      expect(resolveUnlocks(cleared: 1, maxRate: 0.99).mysteries, isFalse,
          reason: '記憶率は足りても周回が足りない');
      expect(resolveUnlocks(cleared: 2, maxRate: 0.60).mysteries, isTrue);
    });

    test('真ルートは記憶率100%のときだけ', () {
      expect(resolveUnlocks(cleared: 9, maxRate: 0.999).trueRoute, isFalse);
      expect(resolveUnlocks(cleared: 0, maxRate: 1.0).trueRoute, isTrue);
    });
  });

  group('システムデータは巻き戻らない', () {
    test('高い記憶率は取り込まれる', () {
      final s = const SystemData().reportMemoryRate(0.7);
      expect(s.maxMemoryRate, 0.7);
    });

    test('低い記憶率を報告しても下がらない', () {
      final s = const SystemData(maxMemoryRate: 0.8).reportMemoryRate(0.2);
      expect(s.maxMemoryRate, 0.8,
          reason: '低い記憶率のセーブをロードしても解禁が消えないこと');
    });

    test('記憶率が上がると解禁も再計算される', () {
      var s = const SystemData(cleared: 2, maxMemoryRate: 0.1);
      expect(s.unlocks.mysteries, isFalse);
      s = s.reportMemoryRate(0.75);
      expect(s.unlocks.mysteries, isTrue);
    });

    test('クリアすると2周目が開く', () {
      final s = const SystemData().reportCleared();
      expect(s.cleared, 1);
      expect(s.unlocks.cast2, isTrue);
    });

    test('JSONに書いて読み直しても同じ', () {
      const s = SystemData(
        cleared: 2,
        maxMemoryRate: 0.6875,
        readScenes: {'act1_sc01'},
        glossary: {'ASC', 'MELiSSA'},
      );
      final back = SystemData.fromJson(s.toJson());
      expect(back.cleared, 2);
      expect(back.maxMemoryRate, 0.6875);
      expect(back.readScenes, contains('act1_sc01'));
      expect(back.glossary.length, 2);
    });
  });

  group('スロットセーブ', () {
    SaveData sample() => SaveData(
          slot: 3,
          savedAt: DateTime.utc(2026, 8, 8, 12, 0),
          playSec: 4210,
          sceneId: 'act2_sc03',
          lineIndex: 42,
          cycle: 5,
          aging: 4,
          flags: const {'saw_alarm_3rd'},
          affection: const {'hibino': 3},
          memory: const {'hibino.hobby': true, 'kiryu.name': false},
          contamination: 0.12,
        );

    test('書いて読み直すと、続きから戻せる項目がすべて残る', () {
      final b = SaveData.fromJson(sample().toJson());
      expect(b.sceneId, 'act2_sc03');
      expect(b.lineIndex, 42);
      expect(b.cycle, 5);
      expect(b.aging, 4);
      expect(b.flags, contains('saw_alarm_3rd'));
      expect(b.affection['hibino'], 3);
      expect(b.memory['hibino.hobby'], isTrue);
      expect(b.contamination, closeTo(0.12, 1e-9));
    });

    test('正解数は true の数だけ（false は数えない）', () {
      expect(sample().correctCount, 1);
    });

    test('壊れたJSONでも既定値で読めて、落ちない', () {
      final b = SaveData.fromJson(const <String, dynamic>{});
      expect(b.sceneId, '');
      expect(b.lineIndex, 0);
      expect(b.memory, isEmpty);
    });
  });
}
