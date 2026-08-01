import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/meta_strings.dart';
import '../models/person.dart';
import '../models/turn_pairs.dart';
import '../services/app_analytics.dart';
import '../services/bgm.dart';
import '../services/memory_stats.dart';
import '../services/online_match_service.dart';
import '../services/player_profile.dart';
import '../services/sfx.dart';
import '../widgets/banner_ad_slot.dart';
import '../widgets/face_view.dart';
import 'match_game_screen.dart' show PlatformDispatcherLocale;
import 'online_result_screen.dart';
import 'rulebook_screen.dart';

/// 🔁 記憶術トレーニングのオンライン・ターン制対戦。
///
/// 同時レース（それぞれが自分の盤面を解く）と違って、**1つの盤面を
/// 2人で共有して交互にめくる**。だから「いま誰の番か」「どのカードが
/// もう表になったか」を両端末で完全に一致させる必要がある。
///
/// やり方は単純で、部屋ドキュメントに **めくった順のカード番号
/// （`moves`）だけ**を積む。盤面そのものは共有seedから両端末が同じものを
/// 生成するので、moves を先頭から再生すれば
/// 「どこが取れたか・いま誰の番か・得点はいくつか」が全部復元できる。
/// 書き込みはトランザクションで、自分が知っている手数と食い違うときは
/// 見送る（相手の手がまだ届いていない＝盤面認識がずれている状態）。
///
/// 表示は [_settled]＋[_flipping] が [OnlineMatchSession.moves] を
/// 少し遅れて追いかける形。
/// 2枚めくって揃わなかったカードを一瞬見せてから伏せるためで、
/// これが無いと相手の手が一瞬で消えて何が起きたか分からない。
class TurnPairsScreen extends StatefulWidget {
  final OnlineMatchSession session;
  const TurnPairsScreen({super.key, required this.session});

  @override
  State<TurnPairsScreen> createState() => _TurnPairsScreenState();
}

enum _Phase { memorize, playing, finished }

class _Card {
  final Person person;
  final bool isFace; // true=顔カード / false=名前カード
  const _Card(this.person, this.isFace);
}

class _TurnPairsScreenState extends State<TurnPairsScreen> {
  late final Random _rng = Random(widget.session.seed);
  late final List<Person> _people;
  late final List<_Card> _cards;

  _Phase _phase = _Phase.memorize;
  int _memorizeLeft = 0;
  Timer? _memorizeTimer;

  /// 判定まで終わった手（＝かならず2枚1組）。ここから盤面を再生する。
  final List<int> _settled = [];

  /// いま表にして見せている、判定前の1〜2枚。
  ///
  /// 判定の反映を [_settled] へ移すのを少し遅らせているのは、
  /// そろわなかった2枚を一瞬で伏せてしまうと、相手の手が何だったのか
  /// 見えないまま消えてしまうため。
  final List<int> _flipping = [];

  Timer? _catchUp;
  bool _sending = false;
  bool _reported = false;

  /// 盤面は「積んだ手を先頭から再生した結果」。得点も手番も別々に持たない。
  TurnPairsState get _state => replayTurnPairs(
        moves: _settled,
        pairId: _pairId,
        isFace: _isFaceCard,
      );
  late final List<int> _pairId;
  late final List<bool> _isFaceCard;

  bool get _myTurn => _state.turn == widget.session.myPlayerIndex;
  bool get _caughtUp =>
      _settled.length + _flipping.length ==
      widget.session.moves.value.length;

  @override
  void initState() {
    super.initState();
    final ja = PlatformDispatcherLocale.isJa;
    // 🌐 盤面が一致しないと成立しないので、購入キャラもデッキ編集も混ぜない
    _people = generatePeople(
      OnlineMatchService.levelPairs,
      ja: ja,
      random: _rng,
      charAssets: kCharImageAssets,
    );
    _cards = [
      for (final p in _people) ...[_Card(p, true), _Card(p, false)],
    ]..shuffle(_rng);
    _pairId = [for (final c in _cards) _people.indexOf(c.person)];
    _isFaceCard = [for (final c in _cards) c.isFace];
    // 📊 おぼえタイムで顔と名前を見せる＝「会った」。
    MemoryStats.instance.load().then((_) {
      for (final p in _people) {
        MemoryStats.instance.recordMeeting(
            itemKey: MemoryStats.keyOf(face: p.face, name: p.name));
      }
    });

    widget.session.moves.addListener(_onMoves);
    widget.session.opponentResult.addListener(_onOpponentResult);

    _tickMemorize();
    _memorizeTimer = Timer.periodic(
        const Duration(milliseconds: 400), (_) => _tickMemorize());

    AppAnalytics.gameStart(mode: 'turn_pairs', players: 2);
    Bgm.instance.playGame();
  }

  @override
  void dispose() {
    widget.session.moves.removeListener(_onMoves);
    widget.session.opponentResult.removeListener(_onOpponentResult);
    _memorizeTimer?.cancel();
    _catchUp?.cancel();
    Bgm.instance.stopGame();
    super.dispose();
  }

  void _tickMemorize() {
    if (!mounted) return;
    final left =
        widget.session.playStartAt.difference(DateTime.now()).inSeconds;
    setState(() => _memorizeLeft = left.clamp(0, 9999));
    if (left <= 0 && _phase == _Phase.memorize) {
      _memorizeTimer?.cancel();
      setState(() => _phase = _Phase.playing);
      _onMoves(); // 待っているあいだに相手が動いていた場合に備える
    }
  }

  // ─────────────── 手の再生 ───────────────

  void _onMoves() {
    if (!mounted || _phase != _Phase.playing) return;
    _scheduleCatchUp(const Duration(milliseconds: 60));
  }

  void _scheduleCatchUp(Duration delay) {
    _catchUp?.cancel();
    _catchUp = Timer(delay, _consumeNextMove);
  }

  /// 未反映の手を1つだけ取り込む。2枚めくり終わったところで間をおくため、
  /// まとめてではなく1手ずつ進める。
  void _consumeNextMove() {
    if (!mounted || _phase != _Phase.playing) return;
    final all = widget.session.moves.value;
    final consumed = _settled.length + _flipping.length;
    if (consumed >= all.length) return;
    final next = all[consumed];
    setState(() => _flipping.add(next));
    Sfx.instance.pop();

    if (_flipping.length < 2) {
      _scheduleCatchUp(const Duration(milliseconds: 120));
      return;
    }
    // 2枚めくった → 判定
    final a = _cards[_flipping[0]];
    final b = _cards[_flipping[1]];
    final hit = a.person == b.person && a.isFace != b.isFace;
    // 📊 自分の手番の1手＝「1枚目の人の相方を当てられたか」。
    //    相手の手は自分の記憶の記録ではないので数えない。
    if (_myTurn) {
      MemoryStats.instance.record(
        mode: StatMode.cpu,
        itemKey: MemoryStats.keyOf(face: a.person.face, name: a.person.name),
        correct: hit,
        reactionMs: 0,
      );
    }
    if (hit) {
      Sfx.instance.correct();
      HapticFeedback.lightImpact();
    } else {
      Sfx.instance.wrong();
    }
    // そろってもハズレても、いったん2枚見せる時間をとる
    Timer(Duration(milliseconds: hit ? 700 : 1100), () {
      if (!mounted) return;
      setState(() {
        _settled.addAll(_flipping);
        _flipping.clear();
      });
      if (_state.matched.length >= _cards.length) {
        _finish();
        return;
      }
      _scheduleCatchUp(const Duration(milliseconds: 60));
    });
  }

  Future<void> _onCardTap(int index) async {
    if (_phase != _Phase.playing || !_myTurn || _sending) return;
    if (!_caughtUp || _flipping.length >= 2) return;
    if (_state.matched.contains(index) || _flipping.contains(index)) return;
    _sending = true;
    final ok = await widget.session
        .pushMove(index, expectedLength: widget.session.moves.value.length);
    _sending = false;
    if (!ok && mounted) {
      // 相手の手がまだ届いていない等で見送った。届き次第すすむ。
      _scheduleCatchUp(const Duration(milliseconds: 200));
    }
  }

  /// 相手が離脱したら、待ち続けずにその場で終わらせる。
  void _onOpponentResult() {
    final r = widget.session.opponentResult.value;
    if (r == null || r['forfeit'] != true) return;
    _finish();
  }

  Future<void> _finish() async {
    if (_reported) return;
    _reported = true;
    setState(() => _phase = _Phase.finished);
    await MemoryStats.instance.finishSession(StatMode.cpu);
    final mine = _state.scores[widget.session.myPlayerIndex];
    AppAnalytics.gameEnd(mode: 'turn_pairs', topScore: mine);
    await PlayerProfile.instance.addWeeklyLearned(mine);
    final elapsedMs = DateTime.now()
        .difference(widget.session.startedAt)
        .inMilliseconds
        .clamp(0, 1 << 30);
    await widget.session.reportDone(
      attempts: _settled.length,
      ms: elapsedMs,
      pairs: mine,
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OnlineResultScreen(
          session: widget.session,
          myAttempts: _settled.length,
          myMs: elapsedMs,
          myPairs: mine,
          higherPairsWins: true,
        ),
      ),
    );
  }

  // ─────────────── UI ───────────────

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmQuit(m);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F7FF),
        bottomNavigationBar: const BannerAdSlot(),
        appBar: AppBar(
          title: Text(m.turnPairsTitle),
          automaticallyImplyLeading: false,
          actions: [
            const RulebookButton(focus: RuleTopic.turnPairs, onDark: true),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _confirmQuit(m),
            ),
          ],
        ),
        body: SafeArea(
          child: switch (_phase) {
            _Phase.memorize => _memorizeView(m),
            _Phase.playing => _boardView(m),
            _Phase.finished => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }

  Widget _memorizeView(MetaStrings m) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF3A7BD5), width: 1.5),
            ),
            child: Row(
              children: [
                const Text('👀', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(m.memorizePrompt,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w900)),
                ),
                Text('$_memorizeLeft',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF3A7BD5))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 🧠 記憶術トレーニングなので、タグ付けの誘導はここでも出す
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFC93C)),
            ),
            child: Text('${m.mnemonicGuideStep1}\n${m.mnemonicGuideStep2}',
                style: const TextStyle(fontSize: 12.5, height: 1.5)),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                mainAxisSpacing: 8,
                childAspectRatio: 4.6,
              ),
              itemCount: _people.length,
              itemBuilder: (context, i) {
                final p = _people[i];
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD8E4F0)),
                  ),
                  child: Row(
                    children: [
                      FaceView(person: p, size: 44, radius: 8),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(p.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _boardView(MetaStrings m) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _turnBar(m),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.72,
              ),
              itemCount: _cards.length,
              itemBuilder: (context, i) => _buildCard(i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _turnBar(MetaStrings m) {
    final me = widget.session.myPlayerIndex;
    final scores = _state.scores;
    Widget chip(String label, int score, bool active, Color color) => Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: active ? color : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color, width: 2),
            ),
            child: Column(
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: active ? Colors.white : color)),
                Text('$score',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: active ? Colors.white : color)),
              ],
            ),
          ),
        );

    return Column(
      children: [
        Row(
          children: [
            chip('😀 ${m.you}', scores[me], _myTurn, const Color(0xFF3A7BD5)),
            const SizedBox(width: 10),
            chip('🌐 ${widget.session.opponentName}', scores[1 - me], !_myTurn,
                const Color(0xFF8A5AC2)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _myTurn ? m.turnYours : m.turnTheirs(widget.session.opponentName),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _buildCard(int index) {
    final card = _cards[index];
    final matched = _state.matched.contains(index);
    final faceUp = matched || _flipping.contains(index);
    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: matched ? 0.35 : 1,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: faceUp ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOutCubic,
          builder: (context, t, _) {
            final angle = t * pi;
            final showFront = t > 0.5;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(angle),
              child: showFront
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(pi),
                      child: _cardFace(card, true, matched),
                    )
                  : _cardFace(card, false, matched),
            );
          },
        ),
      ),
    );
  }

  Widget _cardFace(_Card card, bool front, bool matched) {
    return Container(
      decoration: BoxDecoration(
        color: front
            ? Colors.white
            : (matched ? Colors.grey.shade200 : const Color(0xFF3A7BD5)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: front ? const Color(0xFFB8CCE0) : const Color(0xFF2B5CA5),
          width: 2,
        ),
      ),
      child: front
          ? (card.isFace
              ? Padding(
                  padding: const EdgeInsets.all(6),
                  child: FaceView(
                      person: card.person, size: double.infinity, radius: 8),
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(card.person.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ))
          : const Center(child: Text('🏷️', style: TextStyle(fontSize: 26))),
    );
  }

  Future<void> _confirmQuit(MetaStrings m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(m.quitTitle),
        content: Text(m.quitOnlineBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(m.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(m.quitGame),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await widget.session.forfeit();
    widget.session.dispose();
    if (mounted) Navigator.pop(context);
  }
}
