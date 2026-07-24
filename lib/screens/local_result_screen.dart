import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/meta_strings.dart';
import '../services/interstitial_ad_helper.dart';
import '../services/player_profile.dart';
import '../services/sfx.dart';
import '../widgets/count_up.dart';
import 'match_game_screen.dart';
import 'name_call_screen.dart';
import 'home_shell.dart';
import '../services/review_prompt.dart';
import '../widgets/double_coins_button.dart';
import '../widgets/store_cta.dart';

/// ローカル対戦（1台で2〜4人）の結果画面。獲得数のランキングを表示する。
/// [nameCall] がtrueなら「なまえコール」（単位は枚、再戦もなまえコール）。
class LocalResultScreen extends StatefulWidget {
  final List<int> pairsWon; // index=プレイヤー番号
  final int level;
  final bool nameCall;

  const LocalResultScreen({
    super.key,
    required this.pairsWon,
    required this.level,
    this.nameCall = false,
  });

  @override
  State<LocalResultScreen> createState() => _LocalResultScreenState();
}

class _LocalResultScreenState extends State<LocalResultScreen> {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));
  int _coinsEarned = 0;
  bool _granted = false;

  static const _colors = [
    Color(0xFF3A7BD5),
    Color(0xFFE8663C),
    Color(0xFF2E9E5B),
    Color(0xFF8A5AC2),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _grantRewards());
    InterstitialAdHelper.instance.onGameFinished(); // 3プレイに1回、全画面広告
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _grantRewards() async {
    // 端末の持ち主に1回ぶんのプレイ報酬（誰が勝っても同じ）
    final reward =
        await PlayerProfile.instance.recordGamePlayed(widget.pairsWon.reduce(max));
    if (!mounted) return;
    setState(() {
      _coinsEarned = reward.total;
      _granted = true;
    });
    _confetti.play();
    Sfx.instance.victory();
    maybeAskReview(); // みんなで対戦のあとにレビュー依頼（1回きり）
  }

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    final best = widget.pairsWon.reduce(max);
    final winners = [
      for (var i = 0; i < widget.pairsWon.length; i++)
        if (widget.pairsWon[i] == best) i
    ];
    // 順位順に並べる
    final order = List<int>.generate(widget.pairsWon.length, (i) => i)
      ..sort((a, b) => widget.pairsWon[b].compareTo(widget.pairsWon[a]));

    return Scaffold(
      appBar: AppBar(
        title: Text(m.resultTitle),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    winners.length == 1
                        ? m.localWinner('P${winners.first + 1}')
                        : m.matchDraw,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFE8A400),
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
                  const SizedBox(height: 18),
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 18),
                      child: Column(
                        children: [
                          // 順位ごとに時間差でスライドイン（1位から順に）
                          for (var rank = 0; rank < order.length; rank++) ...[
                            if (rank > 0) const Divider(height: 18),
                            Row(
                              children: [
                                Text(
                                  switch (rank) {
                                    0 => '🥇',
                                    1 => '🥈',
                                    2 => '🥉',
                                    _ => '　',
                                  },
                                  style: TextStyle(
                                      fontSize: rank == 0 ? 26 : 22),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _colors[order[rank]],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'P${order[rank] + 1}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900),
                                  ),
                                ),
                                const Spacer(),
                                CountUp(
                                  widget.pairsWon[order[rank]],
                                  suffix:
                                      ' ${widget.nameCall ? m.cardsUnit : m.pairsUnit}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900),
                                ),
                              ],
                            )
                                .animate()
                                .fadeIn(
                                    delay: (250 + rank * 220).ms,
                                    duration: 260.ms)
                                .slideX(begin: 0.25, end: 0),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (_granted && _coinsEarned > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3D6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFE6B54A), width: 1.5),
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
                  const SizedBox(height: 20),
                  const StoreCtaCard(),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Sfx.instance.pop();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => widget.nameCall
                              ? NameCallScreen(
                                  humanPlayers: widget.pairsWon.length)
                              : MatchGameScreen(
                                  level: widget.level,
                                  humanPlayers: widget.pairsWon.length,
                                ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(m.playAgain),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900),
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
              ),
            ),
          ),
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.08,
            numberOfParticles: 38,
            maxBlastForce: 30,
            minBlastForce: 8,
            gravity: 0.25,
          ),
        ],
      ),
    );
  }
}
