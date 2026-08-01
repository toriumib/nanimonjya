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
      final s = BattleState(myCost: 0, myCostRate: 0.8);
      s.tick(5);
      expect(s.myCost, closeTo(0.8 * 5, 0.001));
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

    test('遠距離は撃ちながら進む（最大射程で列をせき止めない）', () {
      // ⚠️ ここで足を止めると、両軍が射程ぎりぎりで撃ち合ったまま
      //    90秒たっても誰もタワーに届かない。しかも列の先頭に弓がいると
      //    うしろの味方まで進めなくなる（実際にそうなっていた）。
      final s = BattleState();
      final archer = BattleUnit(
          spec: _spec(AttackType.ranged), mine: true, pos: 0.5, hp: 99);
      final foe = BattleUnit(
          spec: _spec(AttackType.melee), mine: false, pos: 0.65, hp: 999);
      s.units..add(archer)..add(foe);
      final before = archer.pos;
      s.tick(0.5);
      expect(archer.pos, greaterThan(before));
      expect(foe.hp, lessThan(999), reason: '進みながらも撃っている');
    });

    test('近距離は撃っている間は前に進まない', () {
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

  group('🛣 1本の線に並ぶ', () {
    test('足を止めた味方を追い越さない（壁のうしろに隠れられる）', () {
      final s = BattleState();
      // 前の味方は敵と交戦中で動けない
      final front = BattleUnit(
          spec: _spec(AttackType.melee), mine: true, pos: 0.50, hp: 999);
      final back = BattleUnit(
          spec: _spec(AttackType.melee), mine: true, pos: 0.47, hp: 999);
      s.units
        ..add(front)
        ..add(back)
        ..add(BattleUnit(
            spec: _spec(AttackType.melee), mine: false, pos: 0.53, hp: 9999));
      final beforeFront = front.pos;
      final beforeBack = back.pos;
      s.tick(1.0);
      expect(front.pos, beforeFront, reason: '交戦中は動かない');
      expect(back.pos, beforeBack, reason: '前がつかえているので進めない');
      expect(back.pos, lessThan(front.pos), reason: 'すり抜けて前に出ない');
    });

    test('同時に出した2体は重なったままにならない', () {
      // 同じ位置から始まるので、位置だけで前後を決めると永久に重なる。
      final s = BattleState(myCost: 10);
      s.deploy(_spec(AttackType.melee), mine: true);
      s.deploy(_spec(AttackType.melee), mine: true);
      expect(s.units[0].pos, s.units[1].pos, reason: '出た瞬間は同じ位置');
      for (var i = 0; i < 20; i++) {
        s.tick(0.1);
      }
      expect((s.units[0].pos - s.units[1].pos).abs(), greaterThan(0.0),
          reason: '重なったままでは1体にしか見えない');
    });

    test('前があいていれば進む', () {
      final s = BattleState();
      final u = BattleUnit(
          spec: _spec(AttackType.melee), mine: true, pos: 0.5, hp: 99);
      s.units.add(u);
      final before = u.pos;
      s.tick(0.5);
      expect(u.pos, greaterThan(before));
    });

    test('うしろの味方はせき止めない（前だけを見る）', () {
      final s = BattleState();
      final front = BattleUnit(
          spec: _spec(AttackType.melee), mine: true, pos: 0.5, hp: 99);
      s.units
        ..add(front)
        ..add(BattleUnit(
            spec: _spec(AttackType.melee), mine: true, pos: 0.47, hp: 99));
      final before = front.pos;
      s.tick(0.5);
      expect(front.pos, greaterThan(before));
    });

    test('相手の列はせき止めない（ぶつかったら戦う）', () {
      final s = BattleState();
      final u = BattleUnit(
          spec: _spec(AttackType.melee), mine: true, pos: 0.5, hp: 99);
      final foe = BattleUnit(
          spec: _spec(AttackType.melee), mine: false, pos: 0.52, hp: 100);
      s.units..add(u)..add(foe);
      s.tick(0.5);
      expect(foe.hp, lessThan(100), reason: '止まるだけで殴らないのでは列が固まる');
    });

    test('近距離の射程は体の幅より広い（止まったのに届かない、が起きない）', () {
      // ここが逆転すると、味方の後ろで足を止めたまま永久に何もしなくなる。
      for (final spec in kUnitCatalog.values) {
        if (spec.attack != AttackType.melee) continue;
        expect(spec.range, greaterThan(BattleState.bodySize),
            reason: '${spec.labelJa} の射程が体の幅より狭い');
      }
    });
  });

  group('⚖️ 覚えたほど有利になる（このモードの背骨）', () {
    /// 出せるようになったら順に出し続ける、という単純な打ち方で1試合まわす。
    BattleOutcome play(List<UnitSpec> mine, List<UnitSpec> foe) {
      final s = BattleState(
        myCostRate: BattleState.rateFor(mine.length),
        foeCostRate: BattleState.rateFor(foe.length),
      );
      var mi = 0, fi = 0;
      while (s.outcome == BattleOutcome.ongoing) {
        s.tick(0.1);
        if (mine.isNotEmpty && s.deploy(mine[mi % mine.length], mine: true)) {
          mi++;
        }
        if (foe.isNotEmpty && s.deploy(foe[fi % foe.length], mine: false)) fi++;
      }
      return s.outcome;
    }

    UnitSpec of(String label) =>
        kUnitCatalog.values.firstWhere((s) => s.labelJa == label);

    test('多く取った側が勝つ', () {
      // ⚠️ ここが通らないなら、神経衰弱をがんばる意味が無い。
      //    以前は両者の⚡が同じで、4人取っても2人取っても引き分けだった。
      expect(
        play([of('前衛'), of('弓'), of('斬りこみ'), of('遊撃')],
            [of('前衛'), of('弓')]),
        BattleOutcome.win,
      );
    });

    test('同じ人数・同じ構成なら引き分け', () {
      expect(play([of('前衛'), of('弓')], [of('前衛'), of('弓')]),
          BattleOutcome.draw);
    });

    test('全部当てて相手が0人なら、時間内に押し切れる', () {
      final r = play(
          [of('前衛'), of('弓'), of('斬りこみ'), of('遊撃'), of('重装'), of('狙撃')],
          const []);
      expect(r, BattleOutcome.win);
    });

    test('1人も取れなければ負ける', () {
      expect(
        play(const [], [of('前衛'), of('弓'), of('斬りこみ'), of('遊撃')]),
        BattleOutcome.lose,
      );
    });

    test('⚡の回復は取った人数で増える', () {
      expect(BattleState.rateFor(6), greaterThan(BattleState.rateFor(2)));
    });

    test('終盤は⚡が2倍になる（にらみ合いのまま終わらせない）', () {
      final s = BattleState(timeLeft: BattleState.rushSeconds - 1);
      expect(s.costMultiplier, 2.0);
      expect(BattleState(timeLeft: BattleState.matchSeconds).costMultiplier, 1.0);
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
