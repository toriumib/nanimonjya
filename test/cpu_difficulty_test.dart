import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:nanimonjya/models/cpu_difficulty.dart';
import 'package:nanimonjya/models/name_call.dart';
import 'package:nanimonjya/models/person.dart';
import 'package:nanimonjya/models/surnames.dart';

/// 🤖 CPU対戦の難易度まわり。
///
/// 「むずかしいほど、まとめて覚える人数が増え、持ち時間が減り、コインが増える」
/// が崩れていないかを固定する。表示（top_screen）と実際の報酬（name_call_screen）が
/// この表を共有しているので、ここが正なら食い違いは起きない。
void main() {
  group('難易度表', () {
    test('4段階すべて引ける', () {
      for (final k in ['easy', 'normal', 'hard', 'oni']) {
        expect(kCpuDifficulties[k], isNotNull, reason: k);
      }
    });

    test('まとめて覚える人数は 1 / 2 / 3 / 4', () {
      expect(kCpuDifficulties['easy']!.groupSize, 1);
      expect(kCpuDifficulties['normal']!.groupSize, 2);
      expect(kCpuDifficulties['hard']!.groupSize, 3);
      expect(kCpuDifficulties['oni']!.groupSize, 4);
    });

    test('むずかしいほど持ち時間が短く、コインが多い', () {
      final order = ['easy', 'normal', 'hard', 'oni']
          .map((k) => kCpuDifficulties[k]!)
          .toList();
      for (var i = 1; i < order.length; i++) {
        final prev = order[i - 1];
        final cur = order[i];
        expect(cur.groupSize, greaterThan(prev.groupSize));
        expect(cur.answerSeconds, lessThan(prev.answerSeconds));
        expect(cur.winBonus, greaterThan(prev.winBonus));
        expect(cur.coinsPerCorrect, greaterThan(prev.coinsPerCorrect));
        expect(cur.perfectBonus, greaterThan(prev.perfectBonus));
        // CPUも強くなる（速く答え、見逃さない）
        expect(cur.cpuMinMs, lessThan(prev.cpuMinMs));
        expect(cur.cpuMissPct, lessThan(prev.cpuMissPct));
      }
    });

    test('CpuLevel の enum 文字列からも、知らない値からも引ける', () {
      expect(cpuDifficultyOf('oni').groupSize, 4);
      expect(cpuDifficultyOf('CpuLevel.hard').groupSize, 3);
      // 想定外の値はふつう扱い（ゲームが止まらないように）
      expect(cpuDifficultyOf('unknown').groupSize, 2);
      expect(cpuDifficultyOf(null).groupSize, 2);
    });
  });

  group('山札の組み立て（groupSize）', () {
    // ⚠️ **既定の枚数に依存させない。**
    //    以前は defaultCopiesPerPerson が2である前提で山札の長さを
    //    直書きしていたため、既定を5に変えただけで4本まとめて落ちた。
    //    ここで見たいのは「並び順」なので、枚数は明示して固定する。
    const copies = 2;
    List<Person> people(int n) => [
          for (var i = 0; i < n; i++)
            Person(face: 'f$i', kind: FaceKind.asset, name: 'p$i', hobby: ''),
        ];

    test('groupSize=1 なら「1人おぼえて、すぐその人が出る」', () {
      final g = NameCallGame(
          people: people(4),
          rng: Random(1),
          groupSize: 1,
          copiesPerPerson: copies);
      expect(g.deck.length, 8);
      // 2枚ずつ同じ人が並ぶ
      for (var i = 0; i < g.deck.length; i += 2) {
        expect(g.deck[i], same(g.deck[i + 1]));
      }
    });

    test('groupSize=2 なら 2人おぼえてから 2人ぶん出題される', () {
      final g = NameCallGame(
          people: people(4),
          rng: Random(2),
          groupSize: 2,
          copiesPerPerson: copies);
      expect(g.deck.length, 8);
      // 前半4枚＝1組目。命名2枚と想起2枚が同じ顔ぶれになる
      expect(g.deck.sublist(0, 2).toSet(), g.deck.sublist(2, 4).toSet());
      expect(g.deck.sublist(4, 6).toSet(), g.deck.sublist(6, 8).toSet());
      // 組をまたいで混ざらない
      expect(
          g.deck.sublist(0, 4).toSet().intersection(
              g.deck.sublist(4, 8).toSet()),
          isEmpty);
    });

    test('groupSize=4（鬼）は 4人おぼえてから 4人ぶん出題される', () {
      final g = NameCallGame(
          people: people(8),
          rng: Random(3),
          groupSize: 4,
          copiesPerPerson: copies);
      expect(g.deck.sublist(0, 4).toSet(), g.deck.sublist(4, 8).toSet());
      expect(g.deck.sublist(8, 12).toSet(), g.deck.sublist(12, 16).toSet());
    });

    test('人数が groupSize で割り切れなくても全員ぶん出る', () {
      final g = NameCallGame(
          people: people(5),
          rng: Random(4),
          groupSize: 4,
          copiesPerPerson: copies);
      expect(g.deck.length, 10);
      // 端数の1人も命名＋想起の2枚ある
      final counts = <Person, int>{};
      for (final p in g.deck) {
        counts[p] = (counts[p] ?? 0) + 1;
      }
      expect(counts.length, 5);
      expect(counts.values.every((c) => c == 2), isTrue);
    });

    test('groupSize=0（既定）は従来どおり全部シャッフル', () {
      final g = NameCallGame(
          people: people(6), rng: Random(5), copiesPerPerson: copies);
      expect(g.deck.length, 12);
      final counts = <Person, int>{};
      for (final p in g.deck) {
        counts[p] = (counts[p] ?? 0) + 1;
      }
      expect(counts.values.every((c) => c == 2), isTrue);
    });
  });

  group('登場人数', () {
    test('既定は6人×4枚（山札24枚）、スライダーは4〜24', () {
      // 2026-08 の「同じ人が何回も出る」報告で5→2にし、その後4枚に調整。name_call.dart 参照。
      expect(NameCallGame.peopleCount, 6);
      expect(NameCallGame.defaultCopiesPerPerson, 4);
      expect(
          NameCallGame.peopleCount * NameCallGame.defaultCopiesPerPerson, 24);
      expect(NameCallGame.minSelectableCount, 4);
      expect(NameCallGame.maxSelectableCount, 24);
      // 既定が選べる範囲に収まっているか（ここがずれると初期値が clamp される）
      expect(NameCallGame.peopleCount,
          inInclusiveRange(NameCallGame.minSelectableCount,
              NameCallGame.maxSelectableCount));
      expect(NameCallGame.defaultCopiesPerPerson,
          inInclusiveRange(NameCallGame.minCopiesPerPerson,
              NameCallGame.maxCopiesPerPerson));
    });

    test('最大人数ぶんの顔が用意されている', () {
      // 足りないと generateImagePeople の assert に引っかかる
      expect(kCharImageAssets.length,
          greaterThanOrEqualTo(NameCallGame.maxSelectableCount));
      expect(NameCallGame.maxPeople, NameCallGame.maxSelectableCount);
    });

    test('上限人数でも顔が重複せず生成できる', () {
      // c13を欠番にしたので15枚。ここと maxPeople がずれると
      // 生成器が足りない顔を要求してassertで落ちる。
      const n = NameCallGame.maxPeople;
      final list = generateImagePeople(n, ja: true, random: Random(7));
      expect(list.length, n);
      expect(list.map((p) => p.face).toSet().length, n);
    });
  });

  group('クイズの選択肢', () {
    List<Person> people(int n) => [
          for (var i = 0; i < n; i++)
            Person(face: 'f$i', kind: FaceKind.asset, name: 'p$i', hobby: ''),
        ];

    test('名簿がそろっていれば名簿の名前だけで4択になる', () {
      final ps = people(4);
      final g = NameCallGame(people: ps, rng: Random(11));
      for (var i = 0; i < ps.length; i++) {
        g.roster[ps[i]] = '名前$i';
      }
      final c = g.choicesFor(ps[0], filler: const ['よそ者さん']);
      expect(c.length, 4);
      expect(c, contains('名前0'));
      expect(c, isNot(contains('よそ者さん')));
    });

    test('名簿が足りないときは filler で4つまで埋める', () {
      final ps = people(4);
      final g = NameCallGame(people: ps, rng: Random(12));
      // 出たとき命名の序盤＝まだ1人しか名前がついていない状態
      g.roster[ps[0]] = '佐藤さん';
      final c = g.choicesFor(ps[0],
          filler: const ['鈴木さん', '高橋さん', '田中さん', '伊藤さん']);
      expect(c.length, 4);
      expect(c, contains('佐藤さん'));
      // 正解が重複して埋められていない
      expect(c.toSet().length, 4);
    });

    test('filler が無ければ4つに満たなくても落ちない', () {
      final ps = people(2);
      final g = NameCallGame(people: ps, rng: Random(13));
      g.roster[ps[0]] = '佐藤さん';
      final c = g.choicesFor(ps[0]);
      expect(c, ['佐藤さん']);
    });

    test('埋める名前はカタカナの造語ではなく実在しそうな苗字', () {
      // 画面が渡しているプールそのものを確認する。
      // 「モジャモン」のような造語だと、明らかに正解でないと分かってしまい
      // 4択が実質2択になる（このテストはその退行を止めるためのもの）。
      expect(kCommonSurnames.length, greaterThanOrEqualTo(4));
      final katakana = RegExp(r'^[ァ-ヴー]+$');
      expect(kCommonSurnames.any((s) => katakana.hasMatch(s)), isFalse);
      expect(surnameWithHonorific('佐藤', true), '佐藤さん');
      expect(surnameWithHonorific('佐藤', false), '佐藤');
    });
  });

  group('1人あたりの枚数', () {
    List<Person> people(int n) => [
          for (var i = 0; i < n; i++)
            Person(face: 'f$i', kind: FaceKind.asset, name: 'p$i', hobby: ''),
        ];

    test('既定は2枚（命名1回＋想起1回）', () {
      final g = NameCallGame(people: people(4), rng: Random(21));
      expect(g.copiesPerPerson, NameCallGame.defaultCopiesPerPerson);
      expect(g.totalCards, 4 * NameCallGame.defaultCopiesPerPerson);
      expect(g.deck.length, g.totalCards);
    });

    test('最小の2枚なら、命名1回＋想起1回で終わる', () {
      final g = NameCallGame(
          people: people(4), rng: Random(21), copiesPerPerson: 2);
      expect(g.totalCards, 8);
      expect(g.deck.length, 8);
    });

    test('枚数を増やすと山札もその倍になる', () {
      final g = NameCallGame(
          people: people(4), rng: Random(22), copiesPerPerson: 5);
      expect(g.totalCards, 20);
      final counts = <Person, int>{};
      for (final p in g.deck) {
        counts[p] = (counts[p] ?? 0) + 1;
      }
      expect(counts.length, 4);
      expect(counts.values.every((c) => c == 5), isTrue);
    });

    test('範囲外の指定は丸める（ゲームが壊れないように）', () {
      expect(
          NameCallGame(people: people(4), rng: Random(23), copiesPerPerson: 99)
              .copiesPerPerson,
          NameCallGame.maxCopiesPerPerson);
      expect(
          NameCallGame(people: people(4), rng: Random(24), copiesPerPerson: 0)
              .copiesPerPerson,
          NameCallGame.minCopiesPerPerson);
    });

    test('CPU戦の組分けでも、1周目が命名・残りが想起になる', () {
      // groupSize=2, copies=3 → A B（命名）→ 2周ぶん想起
      final g = NameCallGame(
        people: people(4),
        rng: Random(25),
        groupSize: 2,
        copiesPerPerson: 3,
      );
      expect(g.deck.length, 12);
      final first = g.deck.sublist(0, 2).toSet();
      expect(g.deck.sublist(2, 4).toSet(), first); // 想起1周目
      expect(g.deck.sublist(4, 6).toSet(), first); // 想起2周目
      // 組をまたいで混ざらない
      expect(first.intersection(g.deck.sublist(6, 12).toSet()), isEmpty);
    });
  });
}
