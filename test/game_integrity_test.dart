import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nanimonjya/models/character_catalog.dart';
import 'package:nanimonjya/models/name_call.dart';
import 'package:nanimonjya/models/person.dart';
import 'package:nanimonjya/models/surnames.dart';

/// 🛡 ゲームが成立しなくなる系のバグを止めるための不変条件テスト。
///
/// 見た目の不具合と違って「クイズに正解が無い」「ゲームが終わらない」
/// 「人数が足りない」は遊べなくなる致命傷なのに、
/// 手で遊んで気づくのは難しい。ここで機械的に確かめる。
void main() {
  NameCallGame makeGame(int seed, {int people = 6, int cardsPerRound = 1}) {
    final rng = Random(seed);
    final game = NameCallGame(
      people: generatePeople(people, ja: true, random: rng),
      rng: rng,
      cardsPerRound: cardsPerRound,
    );
    for (var i = 0; i < game.people.length; i++) {
      game.roster[game.people[i]] = 'なまえ$i';
    }
    return game;
  }

  group('クイズの選択肢（4択が成立するか）', () {
    test('選択肢には必ず正解がふくまれる', () {
      for (var seed = 0; seed < 30; seed++) {
        final game = makeGame(seed);
        for (final p in game.people) {
          final choices = game.choicesFor(p);
          expect(choices, contains(game.roster[p]),
              reason: 'seed=$seed で正解が選択肢に無い＝絶対に当たらない');
        }
      }
    });

    test('選択肢に重複がない（同じ名前が2つ並ばない）', () {
      for (var seed = 0; seed < 30; seed++) {
        final game = makeGame(seed);
        for (final p in game.people) {
          final choices = game.choicesFor(p);
          expect(choices.toSet().length, choices.length,
              reason: 'seed=$seed で選択肢が重複している');
        }
      }
    });

    test('人数が少なくても選択肢は1つ以上あり、正解を含む', () {
      // カスタム名簿など、登録が2人しかいない場合でも出題できること
      final game = makeGame(1, people: 2);
      for (final p in game.people) {
        final choices = game.choicesFor(p);
        expect(choices, isNotEmpty);
        expect(choices, contains(game.roster[p]));
      }
    });
  });

  group('ゲームが必ず終わる（無限ループしない）', () {
    test('引き続ければ山札は必ず空になる', () {
      for (var seed = 0; seed < 20; seed++) {
        final game = makeGame(seed);
        var guard = 0;
        while (!game.isFinished && guard < 1000) {
          game.drawRound();
          guard++;
        }
        expect(game.isFinished, isTrue, reason: 'seed=$seed で終わらない');
      }
    });

    test('山札に戻す操作をくり返しても最後は終わる', () {
      // 「だれも思い出せなかった」を毎回選ぶ最悪ケース。
      // 戻しっぱなしで永久に終わらないと詰んでしまう。
      final game = makeGame(7);
      var guard = 0;
      var returns = 0;
      while (!game.isFinished && guard < 5000) {
        final round = game.drawRound();
        // 最初の20回だけ戻す（ずっと戻し続けるのは仕様上ありえない）
        if (returns < 20 && round.isNotEmpty) {
          if (game.returnToDeck(round.first)) returns++;
        }
        guard++;
      }
      expect(game.isFinished, isTrue, reason: '戻す操作があっても終わること');
    });

    test('山札が空のときは戻せない（終われなくなるのを防ぐ）', () {
      final game = makeGame(3);
      while (!game.isFinished) {
        game.drawRound();
      }
      expect(game.returnToDeck(game.people.first), isFalse);
      expect(game.isFinished, isTrue);
    });
  });

  group('デッキ編集をしてもゲームが成立する', () {
    test('どれだけ除外しても出演プールは4人を下回らない', () {
      final pool = [...kCharImageAssets];
      for (var cut = 0; cut <= pool.length; cut++) {
        final excluded = pool.take(cut).toSet();
        final kept = applyDeckFilter(pool, excluded);
        expect(kept.length, greaterThanOrEqualTo(4),
            reason: '$cut 体を除外したときにプールが枯れている');
      }
    });

    test('プールに合わせて人数を丸めれば、必ず生成できる', () {
      // 画面側がやっている min(count, pool.length) と同じ計算をして、
      // 生成が例外にならないことを確かめる。
      final pool = applyDeckFilter(
          [...kCharImageAssets], kCharImageAssets.take(9).toSet());
      for (final requested in [6, 9, 12]) {
        final n = min(requested, pool.length);
        final people =
            generateImagePeople(n, ja: true, random: Random(1), charAssets: pool);
        expect(people, hasLength(n));
        expect(people.map((p) => p.faceAsset).toSet(), hasLength(n),
            reason: '同じ顔が2人出てはいけない');
      }
    });
  });

  group('人物生成の前提が崩れていない', () {
    test('なまえコール用は名前が空（各自が命名する仕様）', () {
      final people = generateImagePeople(6, ja: true, random: Random(2));
      expect(people.every((p) => p.name.isEmpty), isTrue);
    });

    test('線むすび・名刺おぼえ用は名前が必ず入っている', () {
      // ここが空だと線むすびの右列が空欄になる（実際に起きた不具合）
      final people = generateRecallPeople(8, ja: true, random: Random(2));
      expect(people.every((p) => p.name.trim().isNotEmpty), isTrue);
      expect(people.map((p) => p.name).toSet(), hasLength(8),
          reason: '同じ名前が2人いると線むすびの判定が壊れる');
    });
  });

  group('基本デッキ', () {
    test('24キャラある（重複なし・c13は欠番）', () {
      // 2026-08: char14〜22をショップから基本に昇格して15→24。
      expect(kCharImageAssets, hasLength(NameCallGame.maxPeople));
      expect(kCharImageAssets.toSet(), hasLength(kCharImageAssets.length));
      expect(kCharImageAssets.any((a) => a.contains('char13')), isFalse,
          reason: 'c13は欠番。IDを使い回すと購入済みの人の記録が別のキャラを指す');
    });

    test('みんなで対戦の最大12人ぶんは足りる', () {
      expect(kCharImageAssets.length, greaterThanOrEqualTo(12));
    });
  });

  group('おまかせ命名の苗字プール', () {
    test('100個あり、重複がない（同名が2人出ない前提）', () {
      expect(kCommonSurnames, hasLength(100));
      expect(kCommonSurnames.toSet(), hasLength(100));
    });

    test('空文字が混ざっていない（名前が空欄になるのを防ぐ）', () {
      expect(kCommonSurnames.every((s) => s.trim().isNotEmpty), isTrue);
    });

    test('日本語では敬称がつき、英語では苗字のみ', () {
      expect(surnameWithHonorific('佐藤', true), '佐藤さん');
      expect(surnameWithHonorific('佐藤', false), '佐藤');
    });

    test('最大12キャラでも苗字が足りる', () {
      expect(kCommonSurnames.length, greaterThan(12));
    });
  });
}
