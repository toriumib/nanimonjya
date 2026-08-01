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

/// ⚔️ ベータ「なまえバトル」。
///
/// **覚えたことが、そのまま強さになる**モード。
///
/// 1. 📖 名簿 … これから出る人の顔と名前をひととおり見る
/// 2. 🃏 神経衰弱 … 顔カードと名前カードを、決められためくり回数の中で当てる
/// 3. ⚔️ バトル … **当てた人が味方**になり、**取り逃した人が敵**になる
///
/// 神経衰弱を単体で置くと「覚える練習」から遠いのに時間だけ取られるが、
/// 取った札が次の勝負に効くとなると、1枚1枚を覚える理由ができる。
/// 逆に取り逃すとそのぶん相手が強くなるので、失敗も筋が通る。
///
/// 戦闘そのものは `models/battle.dart` に切り出してある（乱数なし・テスト済み）。
class NameBattleScreen extends StatefulWidget {
  const NameBattleScreen({super.key});

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
  static const int _pairs = 6;

  /// めくれる回数（2枚で1回）。全部当てるにはある程度覚えている必要がある。
  static const int _maxAttempts = 10;

  final Random _rng = Random();
  late final List<Person> _people;
  late final List<_Card> _cards;

  _Phase _phase = _Phase.roster;
  int _rosterLeft = _pairs * 3;
  Timer? _rosterTimer;

  int? _firstIndex;
  /// 2枚目にめくったカード。**表示のために持つ**。
  /// これが無いと、2枚目が伏せたまま判定だけ進んで
  /// 「何をめくったのか見えない」状態になる。
  int? _secondIndex;
  bool _resolving = false;
  int _attemptsLeft = _maxAttempts;

  final List<Person> _mine = []; // 当てた人＝味方
  final List<Person> _foes = []; // 取り逃した人＝敵

  late BattleState _battle;
  Timer? _battleTimer;
  Timer? _foeTimer;
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
    AppAnalytics.gameStart(mode: 'name_battle', players: 1);
    Bgm.instance.playGame();
  }

  @override
  void dispose() {
    _rosterTimer?.cancel();
    _battleTimer?.cancel();
    _foeTimer?.cancel();
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
      _attemptsLeft -= 1;
    });
    MemoryStats.instance.record(
      mode: StatMode.cpu,
      itemKey: MemoryStats.keyOf(face: a.person.face, name: a.person.name),
      correct: hit,
      reactionMs: 0,
    );
    if (hit) {
      Sfx.instance.correct();
      setState(() {
        a.matched = true;
        c.matched = true;
        _mine.add(a.person);
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
      });
      // 2枚を見せ終えてから終了判定（見えないまま終わらせない）
      if (_mine.length >= _pairs || _attemptsLeft <= 0) _endMemory();
    });
  }

  void _endMemory() {
    // 🃏 取り逃した人がそのまま相手の戦力になる
    _foes
      ..clear()
      ..addAll(_people.where((p) => !_mine.contains(p)));
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
        _foeTimer?.cancel();
        _finish();
      }
    });
    // 相手は一定間隔で、出せるものを勝手に出してくる
    _foeTimer = Timer.periodic(const Duration(milliseconds: 2200), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_foes.isEmpty) return;
      final p = _foes[_rng.nextInt(_foes.length)];
      _battle.deploy(roleForFace(p.face), mine: false);
    });
  }

  void _deploy(Person p) {
    if (_phase != _Phase.battle) return;
    final ok = _battle.deploy(roleForFace(p.face), mine: true);
    if (ok) {
      Sfx.instance.pop();
      setState(() {});
    }
  }

  Future<void> _finish() async {
    if (_rewarded) return;
    _rewarded = true;
    setState(() => _phase = _Phase.result);
    await MemoryStats.instance.finishSession(StatMode.cpu);
    await PlayerProfile.instance.addWeeklyLearned(_mine.length);
    final won = _battle.outcome == BattleOutcome.win;
    AppAnalytics.gameEnd(mode: 'name_battle', topScore: _mine.length);
    // 覚えた枚数が主、勝敗がおまけ。覚える動機を勝敗より上に置く。
    final coins = _mine.length * 8 + (won ? 25 : 0);
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

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FF),
      bottomNavigationBar: const BannerAdSlot(),
      appBar: AppBar(
        title: Row(
          children: [
            Text(m.battleTitle),
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
        const SizedBox(height: 10),
        Text(m.battleRosterTitle,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        Text(m.battleRosterHint,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 4),
        Text('⏳ $_rosterLeft',
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFFE8663C))),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.all(14),
            crossAxisCount: 3,
            childAspectRatio: 0.72,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              for (final p in _people)
                Column(
                  children: [
                    Expanded(child: FaceView(person: p, size: 200, radius: 12)),
                    const SizedBox(height: 3),
                    Text(p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w900)),
                    Text(m.roleLabel(roleForFace(p.face)),
                        style: const TextStyle(
                            fontSize: 10.5, color: Colors.black54)),
                  ],
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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

  Widget _memoryView(MetaStrings m) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(m.battleAttemptsLeft(_attemptsLeft),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w900)),
              Text(m.battleRecruited(_mine.length, _pairs),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF3A7BD5))),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.72,
            ),
            itemCount: _cards.length,
            itemBuilder: (context, i) {
              final c = _cards[i];
              final shown =
                  c.matched || i == _firstIndex || i == _secondIndex;
              return GestureDetector(
                onTap: () => _onCardTap(i),
                child: Opacity(
                  opacity: c.matched ? 0.35 : 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          shown ? Colors.white : const Color(0xFF3A7BD5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF2B5CA5), width: 2),
                    ),
                    child: shown
                        ? (c.isFace
                            ? Padding(
                                padding: const EdgeInsets.all(6),
                                child: FaceView(
                                    person: c.person,
                                    size: double.infinity,
                                    radius: 8),
                              )
                            : Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(c.person.name,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900)),
                                  ),
                                ),
                              ))
                        : const Center(
                            child: Text('🏷️',
                                style: TextStyle(fontSize: 26))),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(m.battleBriefBody,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
          const SizedBox(height: 14),
          _squadCard(m, m.battleMySquad, _mine, const Color(0xFF3A7BD5)),
          const SizedBox(height: 12),
          _squadCard(m, m.battleFoeSquad, _foes, const Color(0xFF8A5AC2)),
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
                for (final p in people)
                  Column(
                    children: [
                      FaceView(person: p, size: 52, radius: 10),
                      SizedBox(
                        width: 58,
                        child: Text(p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w900)),
                      ),
                      Text(m.roleEmoji(roleForFace(p.face)),
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _battleView(MetaStrings m) {
    return Column(
      children: [
        _towerBar(m),
        Expanded(child: _lane()),
        _handRow(m),
      ],
    );
  }

  Widget _towerBar(MetaStrings m) {
    Widget tower(String label, int hp, Color color) => Expanded(
          child: Column(
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: hp / BattleState.towerHp,
                  minHeight: 9,
                  backgroundColor: const Color(0xFFE3E9F2),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Text('$hp', style: const TextStyle(fontSize: 11)),
            ],
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Column(
        children: [
          Row(
            children: [
              tower('🏰 ${m.you}', _battle.myTower, const Color(0xFF3A7BD5)),
              const SizedBox(width: 14),
              tower('🏰 ${m.battleFoe}', _battle.foeTower,
                  const Color(0xFF8A5AC2)),
            ],
          ),
          const SizedBox(height: 4),
          Text('⏱ ${_battle.timeLeft.ceil()}s',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _lane() {
    return LayoutBuilder(
      builder: (context, c) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0DC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              for (final u in _battle.units)
                Positioned(
                  left: (u.pos * (c.maxWidth - 60)).clamp(0.0, c.maxWidth - 40),
                  top: u.mine ? c.maxHeight * 0.55 : c.maxHeight * 0.2,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _roleGlyph(u.role),
                        style: TextStyle(
                            fontSize: 26,
                            color: u.mine
                                ? const Color(0xFF3A7BD5)
                                : const Color(0xFF8A5AC2)),
                      ),
                      SizedBox(
                        width: 34,
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
        );
      },
    );
  }

  String _roleGlyph(UnitRole r) => switch (r) {
        UnitRole.guard => '🛡️',
        UnitRole.striker => '⚔️',
        UnitRole.runner => '🏃',
      };

  Widget _handRow(MetaStrings m) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _battle.myCost / BattleState.maxCost,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFE3E9F2),
                    valueColor:
                        const AlwaysStoppedAnimation(Color(0xFFE8A400)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(_battle.myCost.floor().toString(),
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 84,
            child: _mine.isEmpty
                ? Center(
                    child: Text(m.battleNoHand,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)))
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _mine.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final p = _mine[i];
                      final spec = kUnitSpecs[roleForFace(p.face)]!;
                      final can = _battle.myCost >= spec.cost;
                      return GestureDetector(
                        onTap: () => _deploy(p),
                        child: Opacity(
                          opacity: can ? 1 : 0.4,
                          child: Column(
                            children: [
                              FaceView(person: p, size: 44, radius: 8),
                              Text(p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900)),
                              Text('${_roleGlyph(spec.role)} ⚡${spec.cost}',
                                  style: const TextStyle(fontSize: 10.5)),
                            ],
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            switch (outcome) {
              BattleOutcome.win => m.matchWin,
              BattleOutcome.lose => m.battleLose,
              _ => m.matchDraw,
            },
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(m.battleRecruited(_mine.length, _pairs),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          if (_coinsEarned > 0) ...[
            const SizedBox(height: 12),
            Text('🪙 ${m.earnedCoins(_coinsEarned)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w900)),
          ],
          const SizedBox(height: 16),
          // 📇 誰が誰だったか（取り逃した人ほど見ておく意味がある）
          RosterRevealCard(people: _people),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const NameBattleScreen()),
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
