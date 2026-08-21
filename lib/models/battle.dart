/// ⚔️ ベータ「なまえバトル」の戦闘シミュレーション（タワーディフェンス）。
///
/// 神経衰弱で取った人が、そのまま戦う仲間になる。取った枚数が多いほど
/// 手札が厚くなり、戦いを有利に進められる——という繋ぎ方をしている。
/// 「覚えたことが強さになる」を目に見える形にするためのモード。
///
/// **タワーは自分から撃つ**。ただ殴られるだけの的ではないので、
/// 単騎で突っ込ませても溶ける。前衛で受けながら後ろから削る、という
/// 組み立てが要る。
///
/// ここはUIから完全に切り離した純粋なロジックにしてある。乱数も使わない。
/// 1タップぶんの結果が見た目に埋もれると、強さの調整が
/// 「なんとなく強い／弱い」でしか語れなくなるため。
library;

import 'dart:math';

/// 攻撃の当て方。
enum AttackType {
  /// 近距離。目の前の相手だけ殴る。
  melee,

  /// 遠距離。少し離れた相手を撃てる。前衛のうしろから効く。
  ranged,

  /// タワーのみ。ユニットを無視して素通りし、タワーだけを叩く。
  /// 相手からは殴られるので、単体で出すと着く前に落とされる。
  siege,
}

/// ユニット1種類の性能。**キャラごとに違う**（[kUnitCatalog]）。
class UnitSpec {
  /// 表示用の肩書き（「重装」「狙撃」など）。
  final String labelJa;
  final String labelEn;
  final String emoji;

  final AttackType attack;
  final int hp;
  final int power;

  /// 攻撃が届く距離（レーンの長さを1.0とした割合）。
  final double range;

  /// 1秒あたりに進む距離（同上）。
  final double speed;

  /// 出すのに必要なコスト。
  final int cost;

  const UnitSpec({
    required this.labelJa,
    required this.labelEn,
    required this.emoji,
    required this.attack,
    required this.hp,
    required this.power,
    required this.range,
    required this.speed,
    required this.cost,
  });

  bool get towerOnly => attack == AttackType.siege;
}

// ── 元になる7種の型。キャラはこのどれかを持つ ──

const UnitSpec _heavy = UnitSpec(
  labelJa: '重装', labelEn: 'Heavy', emoji: '🛡️',
  attack: AttackType.melee, hp: 150, power: 20, range: 0.07, speed: 0.05, cost: 5,
);
const UnitSpec _guard = UnitSpec(
  labelJa: '前衛', labelEn: 'Guard', emoji: '🧱',
  attack: AttackType.melee, hp: 110, power: 18, range: 0.07, speed: 0.06, cost: 4,
);
const UnitSpec _striker = UnitSpec(
  labelJa: '斬りこみ', labelEn: 'Striker', emoji: '⚔️',
  attack: AttackType.melee, hp: 55, power: 46, range: 0.07, speed: 0.08, cost: 3,
);
const UnitSpec _runner = UnitSpec(
  labelJa: '遊撃', labelEn: 'Runner', emoji: '🏃',
  attack: AttackType.melee, hp: 45, power: 22, range: 0.07, speed: 0.14, cost: 2,
);
const UnitSpec _archer = UnitSpec(
  labelJa: '弓', labelEn: 'Archer', emoji: '🏹',
  attack: AttackType.ranged, hp: 40, power: 25, range: 0.20, speed: 0.07, cost: 3,
);
const UnitSpec _sniper = UnitSpec(
  labelJa: '狙撃', labelEn: 'Sniper', emoji: '🎯',
  attack: AttackType.ranged, hp: 30, power: 34, range: 0.30, speed: 0.05, cost: 4,
);
const UnitSpec _siege = UnitSpec(
  labelJa: 'タワー狙い', labelEn: 'Siege', emoji: '💣',
  attack: AttackType.siege, hp: 85, power: 48, range: 0.07, speed: 0.07, cost: 4,
);

/// 🎭 キャラごとの能力表。
///
/// **顔と能力を固定で結びつける**。試合ごとに性能が変わると
/// 「この人は弓」という覚え方ができず、覚える練習にならない。
/// 表に無い顔（購入キャラ・自分の写真）は [specForFace] が
/// パスから決め打ちで割り当てる。
const Map<String, UnitSpec> kUnitCatalog = {
  'assets/images/char1.jpg': _guard,
  'assets/images/char2.jpg': _archer,
  'assets/images/char3.jpg': _striker,
  'assets/images/char4.jpg': _runner,
  'assets/images/char5.jpg': _heavy,
  'assets/images/char6.jpg': _sniper,
  'assets/images/char7.jpg': _siege,
  'assets/images/char8.jpg': _guard,
  'assets/images/char9.jpg': _striker,
  'assets/images/char10.jpg': _archer,
  'assets/images/char11.jpg': _runner,
  'assets/images/char12.jpg': _heavy,
  'assets/images/25808650_m.jpg': _sniper,
  'assets/images/26948510_s.jpg': _siege,
  'assets/images/4353720_s.jpg': _archer,
  // 🆕 char14〜22（基本キャラへ昇格した9種）の能力。
  'assets/images/char14.webp': _guard,
  'assets/images/char15.webp': _archer,
  'assets/images/char16.webp': _runner,
  'assets/images/char17.webp': _heavy,
  'assets/images/char18.webp': _sniper,
  'assets/images/char19.webp': _siege,
  'assets/images/char20.webp': _archer,
  'assets/images/char21.webp': _runner,
  'assets/images/char22.webp': _guard,
};

/// 表に無い顔にも、いつも同じ能力が付くようにする。
const List<UnitSpec> _fallbackPool = [
  _guard,
  _archer,
  _striker,
  _runner,
  _heavy,
  _sniper,
  _siege,
];

UnitSpec specForFace(String face) {
  final known = kUnitCatalog[face];
  if (known != null) return known;
  var h = 0;
  for (final c in face.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return _fallbackPool[h % _fallbackPool.length];
}

/// 場に出ている1体。
class BattleUnit {
  final UnitSpec spec;
  final bool mine;

  /// 自陣(0.0)から敵陣(1.0)へ向かう位置。相手のユニットは1.0側から来る。
  double pos;
  int hp;

  BattleUnit({
    required this.spec,
    required this.mine,
    required this.pos,
    required this.hp,
  });

  bool get alive => hp > 0;
}

enum BattleOutcome { ongoing, win, lose, draw }

/// 戦況。1試合ぶんの状態をまとめて持つ。
///
/// [tick] を一定間隔で呼ぶだけで進む。乱数を使わないので、同じ操作なら
/// 必ず同じ結果になる（調整とテストのため）。
///
/// `mine == true` が手前側（1人プレイのあなた／2人プレイのP1）、
/// `false` が奥側（CPU／P2）。2人プレイでも同じ場を共有する。
class BattleState {
  int myTower;
  int foeTower;

  double myCost;
  double foeCost;

  double timeLeft;

  final List<BattleUnit> units = [];

  /// ⚡の基本の回復量。ここに「取った人数ぶん」が乗る（[rateFor]）。
  static const double baseCostPerSecond = 0.45;

  /// 取った人ひとりあたりの上乗せ。
  ///
  /// ⚠️ ここが**このモードの背骨**。以前は両者とも同じ回復量だったので、
  /// 神経衰弱で多く取っても「出せる種類が増える」だけで強くならず、
  /// 4人 vs 2人でも引き分けていた（＝覚えても勝てない）。
  /// 覚えた人数がそのまま手数の差になるようにする。
  static const double costPerPerson = 0.11;

  /// 取った人数から⚡の回復量を出す。
  static double rateFor(int squadSize) =>
      baseCostPerSecond + costPerPerson * squadSize;

  static const double maxCost = 10;
  static const int towerHp = 190;
  static const double matchSeconds = 90;

  /// 🔥 残りこれ以下になったら⚡の回復が2倍。
  ///
  /// 中央でにらみ合ったまま時間切れ、が続くと勝負が動かない。
  /// 終盤に出せる量を増やして、どちらかの列が押し切れるようにする。
  static const double rushSeconds = 30;

  /// 🏰 タワーの反撃。射程に入った敵を撃つ。
  /// これが無いと「タワーディフェンス」ではなく、ただの殴り合いになる。
  static const double towerRange = 0.22;
  static const int towerPower = 17;

  /// ユニット1体ぶんの幅。
  ///
  /// **全員が1本の線の上に並ぶ**ので、味方どうしがすり抜けると
  /// 同じ場所に重なってしまう。前の味方がここまで近づいたら足を止め、
  /// 列を作って待つ。前に出した壁が本当に壁として働くようになる。
  static const double bodySize = 0.045;

  /// ⚡の回復量（陣営ごと）。取った人数で決まる。
  final double myCostRate;
  final double foeCostRate;

  BattleState({
    this.myTower = towerHp,
    this.foeTower = towerHp,
    this.myCost = 5,
    this.foeCost = 5,
    this.timeLeft = matchSeconds,
    double? myCostRate,
    double? foeCostRate,
  })  : myCostRate = myCostRate ?? rateFor(3),
        foeCostRate = foeCostRate ?? rateFor(3);

  /// いま⚡が何倍で回復しているか（終盤は2倍）。
  double get costMultiplier => timeLeft <= rushSeconds ? 2.0 : 1.0;

  /// 出撃させる。コストが足りなければ何もせず false。
  bool deploy(UnitSpec spec, {required bool mine}) {
    if (mine) {
      if (myCost < spec.cost) return false;
      myCost -= spec.cost;
    } else {
      if (foeCost < spec.cost) return false;
      foeCost -= spec.cost;
    }
    units.add(BattleUnit(
      spec: spec,
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
    final mult = costMultiplier;
    myCost = min(maxCost, myCost + myCostRate * mult * dt);
    foeCost = min(maxCost, foeCost + foeCostRate * mult * dt);

    for (var i = 0; i < units.length; i++) {
      final u = units[i];
      if (!u.alive) continue;
      // タワー狙いは足を止めずに素通りする（撃ち返されるのが弱点）
      if (!u.spec.towerOnly) {
        final target = _targetFor(u);
        if (target != null) {
          target.hp -= (u.spec.power * dt).round();
          // 近距離は足を止めて殴り合う。
          //
          // ⚠️ 遠距離まで足を止めると、**最大射程で立ち止まったまま
          //    撃ち合うにらみ合い**になる。しかも列の先頭に弓がいると
          //    うしろの味方まで進めなくなり、両軍が0.2ほど離れたまま
          //    90秒たっても誰もタワーに届かない（実際にそうなっていた）。
          //    遠距離は**撃ちながら進む**。前に壁を置けば列に守られる。
          if (u.spec.attack == AttackType.melee) continue;
        }
      }
      // 前の味方につかえていたら進まない（列に並ぶ）
      if (_blockedByAlly(i)) continue;
      final dir = u.mine ? 1.0 : -1.0;
      u.pos = (u.pos + u.spec.speed * dt * dir).clamp(0.0, 1.0);
      final atTower = u.mine ? u.pos >= 1.0 : u.pos <= 0.0;
      if (atTower) {
        final dmg = (u.spec.power * dt).round();
        if (u.mine) {
          foeTower = max(0, foeTower - dmg);
        } else {
          myTower = max(0, myTower - dmg);
        }
      }
    }

    // 🏰 タワーが撃ち返す（射程内でいちばん近い敵を1体ずつ）
    _towerFire(dt, defendingMine: true);
    _towerFire(dt, defendingMine: false);

    units.removeWhere((u) => !u.alive);
  }

  /// [defendingMine] 側のタワーが、攻めてきている敵を撃つ。
  void _towerFire(double dt, {required bool defendingMine}) {
    // 自陣(0.0)を守るのが mine 側。敵は 1.0 側から近づいてくる。
    final towerPos = defendingMine ? 0.0 : 1.0;
    BattleUnit? target;
    var bestDist = double.infinity;
    for (var i = 0; i < units.length; i++) {
      final u = units[i];
      if (!u.alive) continue;
      if (u.mine == defendingMine) continue; // 味方は撃たない
      final d = (u.pos - towerPos).abs();
      if (d <= towerRange && d < bestDist) {
        bestDist = d;
        target = u;
      }
    }
    if (target != null) {
      target.hp -= (towerPower * dt).round();
    }
  }

  /// すぐ前に味方がいて進めないか。
  ///
  /// 1本の線に全員が並ぶので、これが無いと味方が重なって
  /// 「壁のうしろに隠れる」が成立しない。
  ///
  /// ⚠️ 同時に2体出すと**まったく同じ位置**から始まる。位置だけで
  /// 前後を決めると、どちらも「前に味方はいない」と判断して重なったまま
  /// 進み続けてしまう。重なったときは**先に出したほうを前**とみなして、
  /// あとから出したほうに一歩ゆずらせる（すぐ列にほどける）。
  bool _blockedByAlly(int index) {
    final u = units[index];
    for (var j = 0; j < units.length; j++) {
      if (j == index) continue;
      final o = units[j];
      if (!o.alive || o.mine != u.mine) continue;
      if ((o.pos - u.pos).abs() >= bodySize) continue;
      final ahead = u.mine ? o.pos > u.pos : o.pos < u.pos;
      if (ahead || (o.pos == u.pos && j < index)) return true;
    }
    return false;
  }

  /// 射程に入っている敵のうち、いちばん近いもの。
  BattleUnit? _targetFor(BattleUnit u) {
    BattleUnit? best;
    var bestDist = double.infinity;
    for (final o in units) {
      if (o.mine == u.mine || !o.alive) continue;
      // 前にいる敵だけを狙う（後ろを向いて撃たない）
      final ahead = u.mine ? o.pos >= u.pos : o.pos <= u.pos;
      if (!ahead) continue;
      final d = (o.pos - u.pos).abs();
      if (d <= u.spec.range && d < bestDist) {
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
