import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/meta_strings.dart';
import '../models/battle.dart';
import '../models/character_catalog.dart';
import '../models/person.dart';
import '../services/app_analytics.dart';
import '../services/bgm.dart';
import '../services/memory_stats.dart';
import '../services/player_profile.dart';
import '../services/sfx.dart';
import '../widgets/banner_ad_slot.dart';
import '../widgets/face_view.dart';
import '../widgets/roster_reveal.dart';
import 'home_shell.dart';
import 'match_game_screen.dart' show PlatformDispatcherLocale;
import 'rulebook_screen.dart';

/// ⚔️ ベータ「なまえバトル」（タワーディフェンス）。
///
/// **覚えたことが、そのまま強さになる**モード。
///
/// 1. 📖 名簿 … これから出る人の顔・名前・能力をひととおり見る
/// 2. 🃏 神経衰弱 … 顔カードと名前カードを当てる。**当てた人が自分の戦力**
/// 3. ⚔️ タワーディフェンス … 取った人を出撃させ、相手のタワーを狙う
///
/// 神経衰弱を単体で置くと「覚える練習」から遠いのに時間だけ取られるが、
/// 取った札が次の勝負に効くとなると、1枚1枚を覚える理由ができる。
///
/// [humanPlayers] が2なら**1台を回して2人で**遊ぶ。神経衰弱を交互にめくり、
/// 当てた人がその人を自分の戦力にする（8人ぶんあるので、おおよそ4人ずつ）。
/// バトルは同じ画面を上下に分けて、ふたり同時に操作する。
///
/// 戦闘そのものは `models/battle.dart`（乱数なし・テスト済み）。
class NameBattleScreen extends StatefulWidget {
  /// 1 = CPU戦 / 2 = 1台で2人
  final int humanPlayers;

  const NameBattleScreen({super.key, this.humanPlayers = 1});

  @override
  State<NameBattleScreen> createState() => _NameBattleScreenState();
}

enum _Phase { roster, memory, briefing, battle, result }

class _Card {
  final Person person;
  final bool isFace;
  bool matched = false;
  _Card(this.person, this.isFace);
}

class _NameBattleScreenState extends State<NameBattleScreen> {
  bool get _twoPlayer => widget.humanPlayers >= 2;

  /// 2人なら8人（おおよそ4人ずつ取る）、ひとりなら6人。
  int get _pairs => _twoPlayer ? 8 : 6;

  /// ひとりのときのめくれる回数（2枚で1回）。
  /// 2人のときは交互に取り合うので回数制限は置かない。
  static const int _maxAttempts = 10;

  final Random _rng = Random();
  late final List<Person> _people;
  late final List<_Card> _cards;

  _Phase _phase = _Phase.roster;
  late int _rosterLeft = _pairs * 3;
  Timer? _rosterTimer;

  int? _firstIndex;

  /// 2枚目にめくったカード。**表示のために持つ**。
  /// これが無いと、2枚目が伏せたまま判定だけ進んで
  /// 「何をめくったのか見えない」状態になる。
  int? _secondIndex;
  bool _resolving = false;
  int _attemptsLeft = _maxAttempts;

  /// 神経衰弱の手番（0=P1 / 1=P2）。ひとりのときは常に0。
  int _turn = 0;

  /// 陣営ごとの戦力。[0]=手前（あなた／P1）, [1]=奥（CPU／P2）。
  final List<List<Person>> _squads = [[], []];

  late BattleState _battle;
  Timer? _battleTimer;
  Timer? _cpuTimer;
  int _coinsEarned = 0;
  bool _rewarded = false;

  @override
  void initState() {
    super.initState();
    final ja = PlatformDispatcherLocale.isJa;
    _people = generatePeople(
      _pairs,
      ja: ja,
      random: _rng,
      charAssets: applyDeckFilter(
        [
          ...kCharImageAssets,
          ...unlockedExtraAssets(PlayerProfile.instance.unlockedCharacters),
        ],
        PlayerProfile.instance.deckExcluded,
      ),
    );
    // 🃏 1人につき2枚（顔カードと名前カード）。同じ人の2枚をそろえて取る。
    _cards = [
      for (final p in _people) ...[_Card(p, true), _Card(p, false)],
    ]..shuffle(_rng);
    // 📊 名簿で顔と名前を見せる＝「会った」。このあとのペア当てが
    //    「2回目」として定着率の対象になる。
    MemoryStats.instance.load().then((_) {
      for (final p in _people) {
        MemoryStats.instance.recordMeeting(
            itemKey: MemoryStats.keyOf(face: p.face, name: p.name));
      }
    });
    _rosterTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _rosterLeft -= 1);
      if (_rosterLeft <= 0) _startMemory();
    });
    AppAnalytics.gameStart(
        mode: _twoPlayer ? 'name_battle_2p' : 'name_battle',
        players: widget.humanPlayers);
    Bgm.instance.playGame();
  }

  @override
  void dispose() {
    _rosterTimer?.cancel();
    _battleTimer?.cancel();
    _cpuTimer?.cancel();
    Bgm.instance.stopGame();
    super.dispose();
  }

  // ─────────────── 🃏 神経衰弱 ───────────────

  void _startMemory() {
    _rosterTimer?.cancel();
    if (!mounted) return;
    setState(() => _phase = _Phase.memory);
  }

  void _onCardTap(int i) {
    if (_phase != _Phase.memory || _resolving) return;
    final c = _cards[i];
    if (c.matched || i == _firstIndex) return;
    Sfx.instance.pop();
    if (_firstIndex == null) {
      setState(() => _firstIndex = i);
      return;
    }
    final a = _cards[_firstIndex!];
    final hit = a.person == c.person && a.isFace != c.isFace;
    _resolving = true;
    setState(() {
      _secondIndex = i;
      if (!_twoPlayer) _attemptsLeft -= 1;
    });
    // 📊 記録するのは自分（P1）の手だけ。相手の手は自分の記憶ではない。
    if (_turn == 0) {
      MemoryStats.instance.record(
        mode: StatMode.cpu,
        itemKey: MemoryStats.keyOf(face: a.person.face, name: a.person.name),
        correct: hit,
        reactionMs: 0,
      );
    }
    if (hit) {
      Sfx.instance.correct();
      setState(() {
        a.matched = true;
        c.matched = true;
        _squads[_turn].add(a.person);
      });
    } else {
      Sfx.instance.wrong();
    }
    // 外したときは長めに見せる（どの2枚だったかを覚える時間になる）
    Future.delayed(Duration(milliseconds: hit ? 600 : 1100), () {
      if (!mounted) return;
      setState(() {
        _firstIndex = null;
        _secondIndex = null;
        _resolving = false;
        // 当てたらもう一度めくれる。外したら相手の番（2人プレイのみ）
        if (_twoPlayer && !hit) _turn = 1 - _turn;
      });
      final taken = _squads[0].length + _squads[1].length;
      if (taken >= _pairs || (!_twoPlayer && _attemptsLeft <= 0)) _endMemory();
    });
  }

  void _endMemory() {
    if (!_twoPlayer) {
      // 🃏 ひとりのときは、取り逃した人がそのまま相手の戦力になる
      _squads[1]
        ..clear()
        ..addAll(_people.where((p) => !_squads[0].contains(p)));
    }
    _battle = BattleState();
    setState(() => _phase = _Phase.briefing);
  }

  // ─────────────── ⚔️ バトル ───────────────

  void _startBattle() {
    Sfx.instance.fanfare();
    setState(() => _phase = _Phase.battle);
    _battleTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _battle.tick(0.1));
      if (_battle.outcome != BattleOutcome.ongoing) {
        t.cancel();
        _cpuTimer?.cancel();
        _finish();
      }
    });
    // CPU戦のときだけ、相手が勝手に出してくる（2人プレイは人が操作する）
    if (!_twoPlayer) {
      _cpuTimer = Timer.periodic(const Duration(milliseconds: 2200), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        if (_squads[1].isEmpty) return;
        final p = _squads[1][_rng.nextInt(_squads[1].length)];
        _battle.deploy(specForFace(p.face), mine: false);
      });
    }
  }

  void _deploy(Person p, {required bool mine}) {
    if (_phase != _Phase.battle) return;
    if (_battle.deploy(specForFace(p.face), mine: mine)) {
      Sfx.instance.pop();
      setState(() {});
    }
  }

  Future<void> _finish() async {
    if (_rewarded) return;
    _rewarded = true;
    setState(() => _phase = _Phase.result);
    await MemoryStats.instance.finishSession(StatMode.cpu);
    await PlayerProfile.instance.addWeeklyLearned(_squads[0].length);
    final won = _battle.outcome == BattleOutcome.win;
    AppAnalytics.gameEnd(
        mode: _twoPlayer ? 'name_battle_2p' : 'name_battle',
        topScore: _squads[0].length);
    // 覚えた人数が主、勝敗がおまけ。覚える動機を勝敗より上に置く。
    final coins = _squads[0].length * 8 + (won ? 25 : 0);
    if (coins > 0) await PlayerProfile.instance.grantBonusCoins(coins);
    if (!mounted) return;
    setState(() => _coinsEarned = coins);
    if (won) {
      Sfx.instance.victory();
    } else {
      Sfx.instance.coin();
    }
    Bgm.instance.playResult();
  }

  // ─────────────── UI ───────────────

  String _sideName(MetaStrings m, int side) {
    if (_twoPlayer) return side == 0 ? 'P1' : 'P2';
    return side == 0 ? m.you : m.battleFoe;
  }

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FF),
      bottomNavigationBar: const BannerAdSlot(),
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(
                child: Text(m.battleTitle, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(m.betaBadge,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Center(
                child: RulebookButton(focus: RuleTopic.battle, onDark: true)),
          ),
        ],
      ),
      body: SafeArea(
        child: switch (_phase) {
          _Phase.roster => _rosterView(m),
          _Phase.memory => _memoryView(m),
          _Phase.briefing => _briefingView(m),
          _Phase.battle => _battleView(m),
          _Phase.result => _resultView(m),
        },
      ),
    );
  }

  Widget _rosterView(MetaStrings m) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(m.battleRosterTitle,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        Text(m.battleRosterHint,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
        Text('⏳ $_rosterLeft',
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFFE8663C))),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.all(12),
            crossAxisCount: 4,
            childAspectRatio: 0.58,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (final p in _people) _rosterTile(m, p),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startMemory,
              child: Text(m.memorizeDone),
            ),
          ),
        ),
      ],
    );
  }

  Widget _rosterTile(MetaStrings m, Person p) {
    final spec = specForFace(p.face);
    return Column(
      children: [
        Expanded(child: FaceView(person: p, size: 200, radius: 10)),
        const SizedBox(height: 2),
        Text(p.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
        Text('${spec.emoji}${m.ja ? spec.labelJa : spec.labelEn}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Colors.black54)),
        Text('⚡${spec.cost}', style: const TextStyle(fontSize: 9.5)),
      ],
    );
  }

  Widget _memoryView(MetaStrings m) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
          child: _twoPlayer
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (var s = 0; s < 2; s++)
                      Text(
                        '${s == _turn ? '▶ ' : ''}P${s + 1}  ${_squads[s].length}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: s == _turn
                              ? const Color(0xFFE8663C)
                              : Colors.black38,
                        ),
                      ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(m.battleAttemptsLeft(_attemptsLeft),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w900)),
                    Text(m.battleRecruited(_squads[0].length, _pairs),
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF3A7BD5))),
                  ],
                ),
        ),
        if (_twoPlayer)
          Text(m.battleTurnOf('P${_turn + 1}'),
              style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.72,
            ),
            itemCount: _cards.length,
            itemBuilder: (context, i) => _cardTile(i),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _cardTile(int i) {
    final c = _cards[i];
    final shown = c.matched || i == _firstIndex || i == _secondIndex;
    return GestureDetector(
      onTap: () => _onCardTap(i),
      child: Opacity(
        opacity: c.matched ? 0.35 : 1,
        child: Container(
          decoration: BoxDecoration(
            color: shown ? Colors.white : const Color(0xFF3A7BD5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2B5CA5), width: 2),
          ),
          child: shown
              ? (c.isFace
                  ? Padding(
                      padding: const EdgeInsets.all(6),
                      child: FaceView(
                          person: c.person, size: double.infinity, radius: 8),
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(c.person.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ))
              : const Center(child: Text('🏷️', style: TextStyle(fontSize: 26))),
        ),
      ),
    );
  }

  Widget _briefingView(MetaStrings m) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(m.battleBriefTitle,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(_twoPlayer ? m.battleBrief2p : m.battleBriefBody,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
          const SizedBox(height: 14),
          _squadCard(m, _sideName(m, 0), _squads[0], const Color(0xFF3A7BD5)),
          const SizedBox(height: 12),
          _squadCard(m, _sideName(m, 1), _squads[1], const Color(0xFF8A5AC2)),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _startBattle,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8663C),
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text(m.battleStart,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _squadCard(
      MetaStrings m, String title, List<Person> people, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title（${people.length}）',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 8),
          if (people.isEmpty)
            Text(m.battleNobody,
                style: const TextStyle(fontSize: 12, color: Colors.black54))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in people) _squadChip(m, p),
              ],
            ),
        ],
      ),
    );
  }

  Widget _squadChip(MetaStrings m, Person p) {
    final spec = specForFace(p.face);
    return SizedBox(
      width: 62,
      child: Column(
        children: [
          FaceView(person: p, size: 50, radius: 10),
          Text(p.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
          Text('${spec.emoji}${m.ja ? spec.labelJa : spec.labelEn}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, color: Colors.black54)),
        ],
      ),
    );
  }

  /// ⚔️ 戦場は**縦**。手前（下）が自分の陣、奥（上）が相手の陣。
  ///
  /// 1台を挟んで向かい合うので、**スマホの両端がそれぞれの持ち場**になる。
  /// 相手側（上）はタワーも手札もまるごと180度回してあり、
  /// 向かいから見れば自分の陣が手前にある。横向きの盤面だと、
  /// どちらかが必ず横から覗きこむ形になって成立しない。
  Widget _battleView(MetaStrings m) {
    return Column(
      children: [
        // 奥（相手／P2）の陣。2人プレイでは手札ごと引っくり返す。
        if (_twoPlayer)
          RotatedBox(quarterTurns: 2, child: _sideBar(m, side: 1))
        else
          _towerStrip(m, side: 1),
        Expanded(child: _lane()),
        // 手前（あなた／P1）の陣
        _sideBar(m, side: 0),
      ],
    );
  }

  /// 陣ひとつぶん（タワーの体力＋⚡＋手札）。
  Widget _sideBar(MetaStrings m, {required int side}) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _towerStrip(m, side: side),
          _handRow(m, side: side),
        ],
      ),
    );
  }

  /// タワーの体力バー1本ぶん。
  Widget _towerStrip(MetaStrings m, {required int side}) {
    final hp = side == 0 ? _battle.myTower : _battle.foeTower;
    final color =
        side == 0 ? const Color(0xFF3A7BD5) : const Color(0xFF8A5AC2);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 2),
      child: Row(
        children: [
          Text('🏰 ${_sideName(m, side)}',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: hp / BattleState.towerHp,
                minHeight: 10,
                backgroundColor: const Color(0xFFE3E9F2),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text('$hp',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _lane() {
    return LayoutBuilder(
      builder: (context, c) {
        // 🏰 タワーの射程を帯で見せる。どこまで踏み込むと撃たれるのかが
        //    分からないと、前に出す／出さないの判断ができない。
        final band =
            (BattleState.towerRange * c.maxHeight).clamp(0.0, c.maxHeight / 2);
        const unitH = 46.0;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0DC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // 手前（下）＝自分のタワーの射程
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: band,
                  child: Container(color: const Color(0x223A7BD5)),
                ),
                // 奥（上）＝相手のタワーの射程
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: band,
                  child: Container(color: const Color(0x228A5AC2)),
                ),
                // 中央線（自陣・敵陣の境目）
                Positioned(
                  left: 0,
                  right: 0,
                  top: c.maxHeight / 2,
                  child: Container(height: 1.5, color: const Color(0x33000000)),
                ),
                Positioned(
                  top: c.maxHeight / 2 - 9,
                  right: 8,
                  child: Text('⏱ ${_battle.timeLeft.ceil()}',
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w900)),
                ),
                // ⚔️ ユニット。pos 0.0=手前(下) → 1.0=奥(上)。
                //    味方は上へ、相手は下へ進む。
                for (final u in _battle.units)
                  Positioned(
                    top: ((1 - u.pos) * (c.maxHeight - unitH))
                        .clamp(0.0, c.maxHeight - unitH),
                    // 味方と相手を左右に少しずらして、重なっても見分けられるように
                    left: u.mine ? c.maxWidth * 0.28 : c.maxWidth * 0.58,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(u.spec.emoji,
                            style: const TextStyle(fontSize: 24)),
                        SizedBox(
                          width: 32,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: u.hp / u.spec.hp,
                              minHeight: 4,
                              backgroundColor: Colors.white,
                              valueColor: AlwaysStoppedAnimation(u.mine
                                  ? const Color(0xFF3A7BD5)
                                  : const Color(0xFF8A5AC2)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 出撃用の手札。[side] 0=手前(P1) / 1=奥(P2、2人プレイのみ)。
  Widget _handRow(MetaStrings m, {required int side}) {
    final mine = side == 0;
    final cost = mine ? _battle.myCost : _battle.foeCost;
    final squad = _squads[side];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Text(_twoPlayer ? 'P${side + 1} ⚡' : '⚡',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w900)),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: cost / BattleState.maxCost,
                    minHeight: 9,
                    backgroundColor: const Color(0xFFE3E9F2),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFE8A400)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(cost.floor().toString(),
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 74,
            child: squad.isEmpty
                ? Center(
                    child: Text(m.battleNoHand,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)))
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: squad.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final p = squad[i];
                      final spec = specForFace(p.face);
                      final can = cost >= spec.cost;
                      return GestureDetector(
                        onTap: () => _deploy(p, mine: mine),
                        child: Opacity(
                          opacity: can ? 1 : 0.4,
                          child: SizedBox(
                            width: 54,
                            child: Column(
                              children: [
                                FaceView(person: p, size: 38, radius: 8),
                                Text(p.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900)),
                                Text('${spec.emoji}⚡${spec.cost}',
                                    style: const TextStyle(fontSize: 10)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _resultView(MetaStrings m) {
    final outcome = _battle.outcome;
    final title = switch (outcome) {
      BattleOutcome.win => _twoPlayer ? m.localWinner('P1') : m.matchWin,
      BattleOutcome.lose => _twoPlayer ? m.localWinner('P2') : m.battleLose,
      _ => m.matchDraw,
    };
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(m.battleRecruited(_squads[0].length, _pairs),
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          if (_coinsEarned > 0) ...[
            const SizedBox(height: 12),
            Text('🪙 ${m.earnedCoins(_coinsEarned)}',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          ],
          const SizedBox(height: 16),
          // 📇 誰が誰だったか（取り逃した人ほど見ておく意味がある）
          RosterRevealCard(people: _people),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        NameBattleScreen(humanPlayers: widget.humanPlayers)),
              );
            },
            icon: const Icon(Icons.refresh),
            label: Text(m.playAgain),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeShell()),
              (route) => false,
            ),
            icon: const Icon(Icons.home_rounded),
            label: Text(m.backToHome),
          ),
        ],
      ),
    );
  }
}
