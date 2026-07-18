import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nanimonjya/models/name_call.dart';
import 'package:nanimonjya/models/person.dart';

void main() {
  NameCallGame makeGame(int seed) {
    final rng = Random(seed);
    final game = NameCallGame(
      people: generatePeople(NameCallGame.peopleCount, ja: true, random: rng),
      rng: rng,
    );
    for (var i = 0; i < game.people.length; i++) {
      game.roster[game.people[i]] = 'なまえ$i';
    }
    return game;
  }

  group('NameCallGame', () {
    test('山札は人数×2枚で、2枚ずつ引くと使い切れる', () {
      final game = makeGame(1);
      expect(game.totalCards, NameCallGame.peopleCount * 2);
      var drawn = 0;
      while (!game.isFinished) {
        final round = game.drawRound();
        expect(round.length, inInclusiveRange(1, 2));
        drawn += round.length;
      }
      expect(drawn, game.totalCards);
    });

    test('選択肢は正解を含む4択・重複なし・すべて名簿の名前', () {
      final game = makeGame(7);
      final target = game.people.first;
      final choices = game.choicesFor(target);
      expect(choices, hasLength(4));
      expect(choices.toSet(), hasLength(4));
      expect(choices, contains(game.roster[target]));
      final rosterNames = game.roster.values.toSet();
      for (final c in choices) {
        expect(rosterNames, contains(c));
      }
    });
  });
}
