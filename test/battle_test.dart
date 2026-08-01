import 'package:flutter_test/flutter_test.dart';
import 'package:nanimonjya/models/battle.dart';

/// ⚔️ なまえバトルの戦闘ロジック。
///
/// 「強い／弱い」を感覚で語らずに済むように、勝ち筋のかたちだけ固定する。
void main() {
  group('役割', () {
    test('同じ顔からは必ず同じ役割になる（あの人は前衛、と覚えられる）', () {
      const face = 'assets/images/char3.jpg';
      expect(roleForFace(face), roleForFace(face));
    });

    test('顔が違えば役割が偏りすぎない', () {
      final roles = {
        for (var i = 1; i <= 15; i++) roleForFace('assets/images/char$i.jpg'),
      };
      expect(roles.length, greaterThan(1), reason: '全員同じ役割では戦術が生まれない');
    });
  });

  group('出撃コスト', () {
    test('コストが足りなければ出せない', () {
      final s = BattleState(myCost: 1);
      expect(s.deploy(UnitRole.guard, mine: true), isFalse);
      expect(s.units, isEmpty);
    });

    test('出したぶんコストが減る', () {
      final s = BattleState(myCost: 10);
      expect(s.deploy(UnitRole.runner, mine: true), isTrue);
      expect(s.myCost, 10 - kUnitSpecs[UnitRole.runner]!.cost);
    });

    test('コストは時間で回復し、上限を超えない', () {
      final s = BattleState(myCost: 0);
      s.tick(5);
      expect(s.myCost, closeTo(BattleState.costPerSecond * 5, 0.001));
      s.tick(60);
      expect(s.myCost, BattleState.maxCost);
    });
  });

  group('進軍とタワー', () {
    test('邪魔が無ければ進んで敵タワーを削る', () {
      final s = BattleState(myCost: 10);
      s.deploy(UnitRole.runner, mine: true);
      for (var i = 0; i < 200; i++) {
        s.tick(0.1);
      }
      expect(s.foeTower, lessThan(BattleState.towerHp));
    });

    test('タワーを0にしたら勝ち', () {
      final s = BattleState(foeTower: 1, myCost: 10);
      s.deploy(UnitRole.striker, mine: true);
      for (var i = 0; i < 400 && s.outcome == BattleOutcome.ongoing; i++) {
        s.tick(0.1);
      }
      expect(s.outcome, BattleOutcome.win);
    });
  });

  group('ぶつかり合い', () {
    test('前衛は攻撃役より長く生き残る（壁として機能する）', () {
      int survive(UnitRole role) {
        final s = BattleState(myCost: 10, foeCost: 10);
        s.deploy(role, mine: true);
        // 同じ位置に敵をぶつける
        s.units.add(BattleUnit(
          role: UnitRole.striker,
          mine: false,
          pos: 0.0,
          hp: 999,
        ));
        var t = 0;
        while (s.units.any((u) => u.mine) && t < 1000) {
          s.tick(0.1);
          t++;
        }
        return t;
      }

      expect(survive(UnitRole.guard), greaterThan(survive(UnitRole.striker)));
    });

    test('殴り合っている間は前に進まない', () {
      final s = BattleState(myCost: 10);
      s.deploy(UnitRole.guard, mine: true);
      final mine = s.units.first;
      s.units.add(BattleUnit(
          role: UnitRole.guard, mine: false, pos: 0.0, hp: 9999));
      final before = mine.pos;
      s.tick(0.5);
      expect(mine.pos, before);
    });
  });

  group('時間切れの判定', () {
    test('タワーの残りが多いほうが勝ち', () {
      final s = BattleState(myTower: 200, foeTower: 50, timeLeft: 0);
      expect(s.outcome, BattleOutcome.win);
    });

    test('同じならひきわけ', () {
      final s = BattleState(myTower: 120, foeTower: 120, timeLeft: 0);
      expect(s.outcome, BattleOutcome.draw);
    });

    test('決着後はいくらtickしても状態が動かない', () {
      final s = BattleState(foeTower: 0);
      final my = s.myTower;
      s.tick(10);
      expect(s.myTower, my);
      expect(s.outcome, BattleOutcome.win);
    });
  });
}
