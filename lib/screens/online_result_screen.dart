import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/meta_strings.dart';
import '../models/cpu_rank.dart';
import '../services/interstitial_ad_helper.dart';
import '../services/online_match_service.dart';
import '../services/player_profile.dart';
import '../services/sfx.dart';
import '../services/review_prompt.dart';
import '../widgets/double_coins_button.dart';
import '../widgets/store_cta.dart';
import 'online_lobby_screen.dart';
import 'home_shell.dart';

/// オンライン同時レースの結果画面。
/// 相手の結果が届くのを待ち、手数（同数ならタイム）で勝敗を決める。
class OnlineResultScreen extends StatefulWidget {
  final OnlineMatchSession session;
  final int myAttempts;
  final int myMs;
  final int myPairs;

  /// false（ペアさがし）: 手数が少ない方が勝ち（同数ならタイム）。
  /// true（なまえコール）: 獲得枚数が多い方が勝ち（同数ならタイム）。
  final bool higherPairsWins;

  const OnlineResultScreen({
    super.key,
    required this.session,
    required this.myAttempts,
    required this.myMs,
    required this.myPairs,
    this.higherPairsWins = false,
  });

  @override
  State<OnlineResultScreen> createState() => _OnlineResultScreenState();
}

enum _Outcome { waiting, win, lose, draw }

class _OnlineResultScreenState extends State<OnlineResultScreen> {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));
  _Outcome _outcome = _Outcome.waiting;
  Map<String, dynamic>? _oppResult;
  Timer? _timeout;
  int _coinsEarned = 0;
  int _ratingDelta = 0;
  int _ratingAfter = PlayerProfile.instance.cpuRating;
  List<String> _newAchievements = [];
  bool _rewarded = false;

  @override
  void initState() {
    super.initState();
    widget.session.opponentResult.addListener(_onOpponentResult);
    _onOpponentResult(); // 既に届いている場合
    // 相手が長時間終わらない場合は勝ち扱い（切断・放置対策）
    _timeout = Timer(const Duration(seconds: 180), () {
      if (_outcome == _Outcome.waiting) _decide(win: true);
    });
    InterstitialAdHelper.instance.onGameFinished(); // 3プレイに1回、全画面広告
  }

  @override
  void dispose() {
    widget.session.opponentResult.removeListener(_onOpponentResult);
    widget.session.dispose();
    _confetti.dispose();
    _timeout?.cancel();
    super.dispose();
  }

  void _onOpponentResult() {
    if (_outcome != _Outcome.waiting) return;
    final r = widget.session.opponentResult.value;
    if (r == null) return;
    _oppResult = r;
    if (r['forfeit'] == true) {
      _decide(win: true);
      return;
    }
    final oppAttempts = (r['attempts'] as num?)?.toInt() ?? 1 << 20;
    final oppMs = (r['ms'] as num?)?.toInt() ?? 1 << 30;
    final oppPairs = (r['pairs'] as num?)?.toInt() ?? 0;
    if (widget.higherPairsWins) {
      // なまえコール: 獲得枚数 → タイム
      if (widget.myPairs != oppPairs) {
        _decide(win: widget.myPairs > oppPairs);
      } else if (widget.myMs != oppMs) {
        _decide(win: widget.myMs < oppMs);
      } else {
        _decide(draw: true);
      }
    } else if (widget.myAttempts != oppAttempts) {
      _decide(win: widget.myAttempts < oppAttempts);
    } else if (widget.myMs != oppMs) {
      _decide(win: widget.myMs < oppMs);
    } else {
      _decide(draw: true);
    }
  }

  Future<void> _decide({bool win = false, bool draw = false}) async {
    if (_outcome != _Outcome.waiting) return;
    setState(() {
      _outcome = draw
          ? _Outcome.draw
          : win
              ? _Outcome.win
              : _Outcome.lose;
    });
    _timeout?.cancel();

    // 報酬付与（1回だけ）
    if (_rewarded) return;
    _rewarded = true;
    final profile = PlayerProfile.instance;
    final reward = await profile.recordGamePlayed(widget.myPairs);
    var coins = reward.total;
    if (!draw) {
      final result = await profile.recordOnlineMatch(
        won: win,
        isRandomMatch: widget.session.isRandomMatch,
      );
      _ratingDelta = result.ratingDelta;
      _ratingAfter = result.ratingAfter;
      _newAchievements = result.newlyUnlockedAchievements;
      if (win) coins += 30; // recordOnlineMatch内で加算済みの表示分
    }
    if (!mounted) return;
    setState(() => _coinsEarned = coins);
    if (win) {
      _confetti.play();
      Sfx.instance.victory();
      maybeAskReview(); // オンライン勝利のあとにレビュー依頼（1回きり）
    } else {
      Sfx.instance.coin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    final rank = cpuRankForRating(_ratingAfter);

    return Scaffold(
      appBar: AppBar(
        title: Text(m.onlineMatchTitle),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _outcome == _Outcome.waiting
                  ? _waitingView(m)
                  : _resultView(m, rank),
            ),
          ),
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.08,
            numberOfParticles: 42,
            maxBlastForce: 32,
            minBlastForce: 8,
            gravity: 0.25,
          ),
        ],
      ),
    );
  }

  Widget _waitingView(MetaStrings m) {
    return Column(
      children: [
        const SizedBox(height: 40),
        const CircularProgressIndicator(),
        const SizedBox(height: 18),
        Text(
          m.waitingOpponentFinish(widget.session.opponentName),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        ValueListenableBuilder<int>(
          valueListenable: widget.session.opponentProgress,
          builder: (context, value, _) => Text(
            '🌐 $value/${OnlineMatchService.levelPairs} ${m.pairsUnit}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 30),
        _myRecordCard(m),
      ],
    );
  }

  Widget _resultView(MetaStrings m, CpuRank rank) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          switch (_outcome) {
            _Outcome.win => m.matchWin,
            _Outcome.lose => m.matchLose,
            _ => m.matchDraw,
          },
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: _outcome == _Outcome.win
                ? const Color(0xFFE8A400)
                : const Color(0xFF3A7BD5),
          ),
        )
            .animate()
            .fadeIn(duration: 200.ms)
            .scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1, 1),
              duration: 550.ms,
              curve: Curves.elasticOut,
            ),
        const SizedBox(height: 16),
        _compareCard(m)
            .animate()
            .fadeIn(delay: 150.ms, duration: 300.ms)
            .slideY(begin: 0.15, end: 0),
        const SizedBox(height: 12),
        if (_outcome != _Outcome.draw) _ratingCard(m, rank),
        if (_coinsEarned > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3D6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE6B54A), width: 1.5),
            ),
            child: Text(
              '🪙 ${m.earnedCoins(_coinsEarned)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8A6A1E)),
            ),
          ),
          const SizedBox(height: 10),
          DoubleCoinsButton(coinsEarned: _coinsEarned),
        ],
        if (_newAchievements.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFC93C), width: 1.5),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _newAchievements
                  .map((id) => Chip(
                        label: Text(m.achievementUnlocked(m.achTitle(id))),
                        backgroundColor: Colors.white,
                      ))
                  .toList(),
            ),
          ),
        ],
        const SizedBox(height: 20),
        const StoreCtaCard(),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            Sfx.instance.pop();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      OnlineLobbyScreen(game: widget.session.game)),
            );
          },
          icon: const Icon(Icons.refresh),
          label: Text(m.playAgain),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeShell()),
              (route) => false,
            );
          },
          icon: const Icon(Icons.home_rounded),
          label: Text(m.backToHome),
        ),
      ],
    );
  }

  Widget _myRecordCard(MetaStrings m) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('👆 ${m.attemptsLabel}: ${widget.myAttempts}',
                style: const TextStyle(fontWeight: FontWeight.w900)),
            Text('⏱️ ${(widget.myMs / 1000).toStringAsFixed(1)}s',
                style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _compareCard(MetaStrings m) {
    final opp = _oppResult;
    final oppForfeit = opp?['forfeit'] == true;
    Widget row(String label, String mine, String theirs) {
      return Row(
        children: [
          Expanded(
            child: Text(mine,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF3A7BD5))),
          ),
          SizedBox(
            width: 90,
            child: Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          Expanded(
            child: Text(theirs,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF8A5AC2))),
          ),
        ],
      );
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('😀 ${m.you}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 90, child: Text('VS', textAlign: TextAlign.center)),
                Expanded(
                  child: Text('🌐 ${widget.session.opponentName}',
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const Divider(height: 20),
            if (widget.higherPairsWins)
              row(m.cardsWonLabel, '${widget.myPairs}',
                  oppForfeit ? '—' : '${(opp?['pairs'] as num?)?.toInt() ?? '—'}')
            else
              row(m.attemptsLabel, '${widget.myAttempts}',
                  oppForfeit
                      ? '—'
                      : '${(opp?['attempts'] as num?)?.toInt() ?? '—'}'),
            const SizedBox(height: 8),
            row(
                'TIME',
                '${(widget.myMs / 1000).toStringAsFixed(1)}s',
                oppForfeit
                    ? m.opponentForfeited
                    : '${(((opp?['ms'] as num?)?.toInt() ?? 0) / 1000).toStringAsFixed(1)}s'),
          ],
        ),
      ),
    );
  }

  Widget _ratingCard(MetaStrings m, CpuRank rank) {
    final deltaText = _ratingDelta >= 0 ? '+$_ratingDelta' : '$_ratingDelta';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EDFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8A5AC2), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(rank.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 8),
          Text(
            '${m.ja ? rank.nameJa : rank.nameEn}  $_ratingAfter',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _ratingDelta >= 0
                  ? const Color(0xFFE0F5E0)
                  : const Color(0xFFFFE4E4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              deltaText,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: _ratingDelta >= 0
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFC62828),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
