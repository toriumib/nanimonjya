import 'package:flutter_test/flutter_test.dart';
import 'package:nanimonjya/models/battle.dart';
import 'package:nanimonjya/models/person.dart';

/// ⚔️ なまえバトルの戦闘ロジック。
///
/// 「強い／弱い」を感覚で語らずに済むように、勝ち筋のかたちだけ固定する。
void main() {
  group('キャラの能力', () {
    test('基本の顔には全員ぶん能力が用意されている', () {
      for (final face in kCharImageAssets) {
        expect(kUnitCatalog[face], isNotNull,
            reason: '$face に能力が割り当てられていない');
      }
    });

    test('同じ顔からは必ず同じ能力になる（この人は弓、と覚えられる）', () {
      const face = 'assets/images/char2.jpg';
      expect(specForFace(face), same(specForFace(face)));
    });

    test('表に無い顔（購入キャラ・自分の写真）にも決まった能力が付く', () {
      const face = 'assets/images/char27.webp';
      expect(specForFace(face), isNotNull);
      expect(specForFace(face), same(specForFace(face)));
    });

    test('近距離・遠距離・タワー狙いが全部そろっている', () {
      final types = kCharImageAssets.map((f) => specForFace(f).attack).toSet();
      expect(types, containsAll(AttackType.values),
          reason: '1種類でも欠けると戦い方の幅が無くなる');
    });

    test('遠距離は近距離より射程が長い', () {
      expect(_spec(AttackType.ranged).range,
          greaterThan(_spec(AttackType.melee).range));
    });
  });

  group('出撃コスト', () {
    test('コストが足りなければ出せない', () {
      final s = BattleState(myCost: 1);
      expect(s.deploy(_spec(AttackType.melee), mine: true), isFalse);
      expect(s.units, isEmpty);
    });

    test('コストは時間で回復し、上限を超えない', () {
      final s = BattleState(myCost: 0);
      s.tick(5);
      expect(s.myCost, closeTo(BattleState.costPerSecond * 5, 0.001));
      s.tick(60);
      expect(s.myCost, BattleState.maxCost);
    });
  });

  group('🏰 タワーは撃ち返す', () {
    test('射程に入った敵はタワーに削られる', () {
      final s = BattleState();
      final foe = BattleUnit(
          spec: _spec(AttackType.melee), mine: false, pos: 0.05, hp: 100);
      s.units.add(foe);
      s.tick(1.0);
      expect(foe.hp, lessThan(100), reason: 'ただ殴られるだけの的ではない');
    });

    test('射程の外なら撃たれない', () {
      final s = BattleState();
      final foe = BattleUnit(
          spec: _spec(AttackType.melee), mine: false, pos: 0.9, hp: 100);
      s.units.add(foe);
      s.tick(1.0);
      expect(foe.hp, 100);
    });

    test('味方は撃たない', () {
      final s = BattleState();
      final ally = BattleUnit(
          spec: _spec(AttackType.melee), mine: true, pos: 0.02, hp: 100);
      s.units.add(ally);
      s.tick(1.0);
      expect(ally.hp, 100);
    });
  });

  group('💣 タワー狙い', () {
    test('目の前に敵がいても足を止めずに素通りする', () {
      final s = BattleState();
      final siege =
          BattleUnit(spec: _siegeSpec(), mine: true, pos: 0.5, hp: 500);
      s.units
        ..add(siege)
        ..add(BattleUnit(
            spec: _spec(AttackType.melee), mine: false, pos: 0.52, hp: 999));
      final before = siege.pos;
      s.tick(0.5);
      expect(siege.pos, greaterThan(before));
    });

    test('素通りされた敵は削られない（ユニットを攻撃しない）', () {
      final s = BattleState();
      final foe = BattleUnit(
          spec: _spec(AttackType.melee), mine: false, pos: 0.52, hp: 999);
      s.units
        ..add(BattleUnit(spec: _siegeSpec(), mine: true, pos: 0.5, hp: 500))
        ..add(foe);
      s.tick(0.5);
      // 相手の近距離ユニット側からは殴られるので、こちらのHPは減ってよい。
      // ここで見るのは「タワー狙いが相手を削っていない」こと。
      expect(foe.hp, 999);
    });
  });

  group('射程と向き', () {
    test('遠距離は離れていても前の敵を撃てる', () {
      final s = BattleState();
      final archer =
          BattleUnit(spec: _spec(AttackType.ranged), mine: true, pos: 0.5, hp: 99);
      final foe = BattleUnit(
          spec: _spec(AttackType.melee), mine: false, pos: 0.62, hp: 100);
      s.units..add(archer)..add(foe);
      s.tick(1.0);
      expect(foe.hp, lessThan(100));
    });

    test('後ろにいる敵は撃たない（振り向かない）', () {
      final s = BattleState();
      final archer =
          BattleUnit(spec: _spec(AttackType.ranged), mine: true, pos: 0.5, hp: 99);
      final behind = BattleUnit(
          spec: _spec(AttackType.melee), mine: false, pos: 0.42, hp: 100);
      s.units..add(archer)..add(behind);
      s.tick(1.0);
      expect(behind.hp, 100);
    });

    test('撃っている間は前に進まない', () {
      final s = BattleState();
      final mine =
          BattleUnit(spec: _spec(AttackType.melee), mine: true, pos: 0.5, hp: 99);
      s.units
        ..add(mine)
        ..add(BattleUnit(
            spec: _spec(AttackType.melee), mine: false, pos: 0.52, hp: 999));
      final before = mine.pos;
      s.tick(0.5);
      expect(mine.pos, before);
    });
  });

  group('決着', () {
    test('タワーを0にしたら勝ち', () {
      final s = BattleState(foeTower: 1, myCost: 10);
      s.deploy(_spec(AttackType.melee), mine: true);
      for (var i = 0; i < 600 && s.outcome == BattleOutcome.ongoing; i++) {
        s.tick(0.1);
      }
      expect(s.outcome, BattleOutcome.win);
    });

    test('時間切れならタワーの残りが多いほうが勝ち', () {
      expect(BattleState(myTower: 200, foeTower: 50, timeLeft: 0).outcome,
          BattleOutcome.win);
      expect(BattleState(myTower: 120, foeTower: 120, timeLeft: 0).outcome,
          BattleOutcome.draw);
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

/// テスト用: 指定した攻撃タイプの基本の型を1つ取り出す。
UnitSpec _spec(AttackType t) =>
    kUnitCatalog.values.firstWhere((s) => s.attack == t);

UnitSpec _siegeSpec() => _spec(AttackType.siege);
