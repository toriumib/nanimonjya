/// ⚔️ ベータ「なまえバトル」の戦闘シミュレーション。
///
/// 神経衰弱で取った人が、そのまま戦う仲間になる。取った枚数が多いほど
/// 手札が厚くなり、戦いを有利に進められる——という繋ぎ方をしている。
/// 「覚えたことが強さになる」を目に見える形にするためのモード。
///
/// ここはUIから完全に切り離した純粋なロジックにしてある。
/// 1タップぶんの結果が見た目に埋もれると、強さの調整が
/// 「なんとなく強い／弱い」でしか語れなくなるため。
library;

import 'dart:math';

/// ユニットの役割。3種類だけにして、覚えることを増やさない。
enum UnitRole {
  /// 前衛。HPが高く、進みは遅い。壁になる。
  guard,

  /// 攻撃役。攻撃力が高く紙。前衛のうしろから効く。
  striker,

  /// 遊撃。速くて安い。数で押す。
  runner,
}

/// ユニット1種類の性能。
class UnitSpec {
  final UnitRole role;
  final int hp;
  final int attack;

  /// 1秒あたりに進む距離（レーンの長さを1.0とした割合）。
  final double speed;

  /// 出すのに必要なコスト。
  final int cost;

  const UnitSpec({
    required this.role,
    required this.hp,
    required this.attack,
    required this.speed,
    required this.cost,
  });
}

const Map<UnitRole, UnitSpec> kUnitSpecs = {
  UnitRole.guard:
      UnitSpec(role: UnitRole.guard, hp: 120, attack: 8, speed: 0.055, cost: 4),
  UnitRole.striker:
      UnitSpec(role: UnitRole.striker, hp: 45, attack: 22, speed: 0.075, cost: 3),
  UnitRole.runner:
      UnitSpec(role: UnitRole.runner, hp: 55, attack: 11, speed: 0.13, cost: 2),
};

/// 顔のアセットパスから役割を決める。
///
/// 見た目で役割が決まっていないと、同じ人が試合ごとに別の性能になり
/// 「あの人は前衛」という覚え方ができない。パスから決め打ちにして、
/// **同じ人はいつも同じ役割**にする。
UnitRole roleForFace(String face) {
  var h = 0;
  for (final c in face.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return UnitRole.values[h % UnitRole.values.length];
}

/// 場に出ている1体。
class BattleUnit {
  final UnitRole role;
  final bool mine;

  /// 自陣(0.0)から敵陣(1.0)へ向かう位置。相手のユニットは1.0側から来る。
  double pos;
  int hp;

  BattleUnit({
    required this.role,
    required this.mine,
    required this.pos,
    required this.hp,
  });

  UnitSpec get spec => kUnitSpecs[role]!;
  bool get alive => hp > 0;
}

/// 決着。
enum BattleOutcome { ongoing, win, lose, draw }

/// 戦況。1試合ぶんの状態をまとめて持つ。
///
/// [tick] を一定間隔で呼ぶだけで進む。乱数を使わないので、同じ操作なら
/// 必ず同じ結果になる（調整とテストのため）。
class BattleState {
  /// タワーの体力。0になった方が負け。
  int myTower;
  int foeTower;

  /// 出撃コスト。時間で回復する。
  double myCost;
  double foeCost;

  /// 残り時間(秒)。尽きたらタワーの残量で判定。
  double timeLeft;

  final List<BattleUnit> units = [];

  /// 1秒あたりのコスト回復量。
  static const double costPerSecond = 0.9;
  static const double maxCost = 10;
  static const int towerHp = 200;
  static const double matchSeconds = 75;

  /// タワーに触れたユニットが1秒あたりに与える damage 倍率。
  static const double towerDamageRate = 1.0;

  BattleState({
    this.myTower = towerHp,
    this.foeTower = towerHp,
    this.myCost = 4,
    this.foeCost = 4,
    this.timeLeft = matchSeconds,
  });

  /// 出撃させる。コストが足りなければ何もせず false。
  bool deploy(UnitRole role, {required bool mine}) {
    final spec = kUnitSpecs[role]!;
    if (mine) {
      if (myCost < spec.cost) return false;
      myCost -= spec.cost;
    } else {
      if (foeCost < spec.cost) return false;
      foeCost -= spec.cost;
    }
    units.add(BattleUnit(
      role: role,
      mine: mine,
      pos: mine ? 0.0 : 1.0,
      hp: spec.hp,
    ));
    return true;
  }

  /// [dt] 秒ぶん進める。
  void tick(double dt) {
    if (outcome != BattleOutcome.ongoing) return;
    timeLeft -= dt;
    myCost = min(maxCost, myCost + costPerSecond * dt);
    foeCost = min(maxCost, foeCost + costPerSecond * dt);

    for (final u in units) {
      if (!u.alive) continue;
      final foe = _nearestEnemy(u);
      if (foe != null) {
        // 目の前に敵がいる → 進まずに殴り合う
        u.hp -= (foe.spec.attack * dt).round();
        continue;
      }
      // 進む。行き着いたらタワーを削る
      final dir = u.mine ? 1.0 : -1.0;
      u.pos = (u.pos + u.spec.speed * dt * dir).clamp(0.0, 1.0);
      final atTower = u.mine ? u.pos >= 1.0 : u.pos <= 0.0;
      if (atTower) {
        final dmg = (u.spec.attack * towerDamageRate * dt).round();
        if (u.mine) {
          foeTower = max(0, foeTower - dmg);
        } else {
          myTower = max(0, myTower - dmg);
        }
      }
    }
    units.removeWhere((u) => !u.alive);
  }

  /// ぶつかっている敵（十分近い相手側のユニット）。
  BattleUnit? _nearestEnemy(BattleUnit u) {
    const reach = 0.06;
    BattleUnit? best;
    var bestDist = double.infinity;
    for (final o in units) {
      if (o.mine == u.mine || !o.alive) continue;
      final d = (o.pos - u.pos).abs();
      if (d <= reach && d < bestDist) {
        bestDist = d;
        best = o;
      }
    }
    return best;
  }

  BattleOutcome get outcome {
    if (foeTower <= 0 && myTower <= 0) return BattleOutcome.draw;
    if (foeTower <= 0) return BattleOutcome.win;
    if (myTower <= 0) return BattleOutcome.lose;
    if (timeLeft > 0) return BattleOutcome.ongoing;
    if (foeTower == myTower) return BattleOutcome.draw;
    return foeTower < myTower ? BattleOutcome.win : BattleOutcome.lose;
  }
}
