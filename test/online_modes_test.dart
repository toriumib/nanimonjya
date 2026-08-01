import 'package:flutter_test/flutter_test.dart';
import 'package:nanimonjya/models/turn_pairs.dart';
import 'package:nanimonjya/services/online_match_service.dart';

/// 🌐 オンラインの3モード（フレンド／ランク／ターン制）の、
/// 通信なしで確かめられる部分だけを固める。
///
/// ここが崩れると「相手と盤面がずれる」「手番が食い違う」という、
/// 実機を2台つないで遊ばないと気づけないバグになる。
void main() {
  group('部屋の game 判別', () {
    test('mode の接頭辞と game が往復する', () {
      for (final game in const ['namecall', 'pairs', 'rank', 'turnpairs']) {
        final prefix = OnlineMatchService.prefixOf(game);
        expect(OnlineMatchService.gameOfMode('${prefix}_random'), game,
            reason: 'ランダムマッチの部屋から $game を復元できること');
        expect(OnlineMatchService.gameOfMode('${prefix}_friend'), game,
            reason: '合言葉の部屋から $game を復元できること');
      }
    });

    test('game ごとに接頭辞が重ならない（別モードの部屋に入らないため）', () {
      final prefixes = {
        for (final g in const ['namecall', 'pairs', 'rank', 'turnpairs'])
          OnlineMatchService.prefixOf(g),
      };
      expect(prefixes.length, 4);
    });

    test('v2以前の mode はペアさがし扱いにフォールバックする', () {
      expect(OnlineMatchService.gameOfMode('race_random'), 'pairs');
    });
  });

  group('人数の決まり方', () {
    test('なまえコールはホストの指定をそのまま使う', () {
      expect(OnlineMatchService.resolvePeople('namecall', 12), 12);
    });

    test('なまえコールの指定なしは既定値', () {
      expect(OnlineMatchService.resolvePeople('namecall', null),
          OnlineMatchService.defaultOnlinePeople);
    });

    test('なまえコールは顔の枚数を超えない（盤面生成が破綻するため）', () {
      expect(OnlineMatchService.resolvePeople('namecall', 999), 16);
      expect(OnlineMatchService.resolvePeople('namecall', 0), 2);
    });

    test('ランクマッチは指定を無視して8人に固定する', () {
      // 見知らぬ人同士が条件をそろえずに遊べることがランクの意味なので、
      // ここで人数が変わると相手が見つからなくなる。
      expect(OnlineMatchService.resolvePeople('rank', 4), 8);
      expect(OnlineMatchService.resolvePeople('rank', null),
          OnlineMatchService.rankPeopleCount);
    });

    test('ペアさがし系はペア数に固定する', () {
      expect(OnlineMatchService.resolvePeople('pairs', 12),
          OnlineMatchService.levelPairs);
      expect(OnlineMatchService.resolvePeople('turnpairs', 12),
          OnlineMatchService.levelPairs);
    });
  });

  group('おぼえタイム', () {
    test('ランクは人数ぶんだけ長くなる', () {
      expect(OnlineMatchService.memorizeSecondsFor('rank', 8), 24);
    });

    test('なまえコールは出たとき命名なので事前のおぼえタイムを持たない', () {
      expect(OnlineMatchService.memorizeSecondsFor('namecall', 12), 0);
    });
  });

  group('ターン制の再生', () {
    // 6枚 = 3ペア。偶数index=顔カード / 奇数index=名前カード。
    // 0と1、2と3、4と5がそれぞれペア。
    const pairId = [0, 0, 1, 1, 2, 2];
    const isFace = [true, false, true, false, true, false];

    TurnPairsState replay(List<int> moves) => replayTurnPairs(
        moves: moves, pairId: pairId, isFace: isFace);

    test('何もめくっていなければ先手の番', () {
      final s = replay([]);
      expect(s.turn, 0);
      expect(s.matched, isEmpty);
      expect(s.scores, [0, 0]);
    });

    test('めくりかけの1枚は判定に入れない', () {
      final s = replay([0]);
      expect(s.turn, 0, reason: '2枚目を出すまで手番は動かない');
      expect(s.matched, isEmpty);
    });

    test('ペアが成立したら手番は移らず、もう一度めくれる', () {
      final s = replay([0, 1]);
      expect(s.matched, {0, 1});
      expect(s.scores, [1, 0]);
      expect(s.turn, 0);
    });

    test('外したら相手の番になる', () {
      final s = replay([0, 3]);
      expect(s.matched, isEmpty);
      expect(s.scores, [0, 0]);
      expect(s.turn, 1);
    });

    test('同じ人でも顔どうし・名前どうしは成立しない', () {
      // 盤面には同じ人の顔カードと名前カードが1枚ずつしか無いが、
      // 判定条件を「pairIdが同じ」だけにすると将来ここが破れる。
      final s = replayTurnPairs(
        moves: [0, 1],
        pairId: const [0, 0],
        isFace: const [true, true],
      );
      expect(s.matched, isEmpty);
      expect(s.turn, 1);
    });

    test('連取のあと外すと、そこで初めて手番が移る', () {
      final s = replay([0, 1, 2, 3, 4, 1]);
      expect(s.scores, [2, 0]);
      expect(s.matched, {0, 1, 2, 3});
      expect(s.turn, 1);
    });

    test('同じ手順なら何度再生しても同じ盤面になる（両端末で一致する条件）', () {
      const moves = [0, 3, 2, 5, 4, 5, 0, 1];
      final a = replay(moves);
      final b = replay(moves);
      expect(a.matched, b.matched);
      expect(a.scores, b.scores);
      expect(a.turn, b.turn);
    });

    test('全部そろうと matched がカード枚数と一致する（終了条件）', () {
      final s = replay([0, 1, 2, 3, 4, 5]);
      expect(s.matched.length, pairId.length);
      expect(s.scores, [3, 0]);
    });
  });
}
