import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';

import '../l10n/meta_strings.dart';
import '../models/cpu_rank.dart';
import '../services/player_profile.dart';
import '../services/sfx.dart';
import 'match_game_screen.dart';
import 'top_screen.dart';

/// CPU対戦（神経衰弱）の結果画面。
/// 獲得ペア数の勝敗、段位レーティングの増減、コイン・実績を表示する。
class MatchResultScreen extends StatefulWidget {
  final CpuLevel cpuLevel;
  final int level;
  final int myPairs;
  final int cpuPairs;
  final int attempts;
  final int matches;
  final int avgDecisionMs;

  const MatchResultScreen({
    super.key,
    required this.cpuLevel,
    required this.level,
    required this.myPairs,
    required this.cpuPairs,
    required this.attempts,
    required this.matches,
    required this.avgDecisionMs,
  });

  @override
  State<MatchResultScreen> createState() => _MatchResultScreenState();
}

class _MatchResultScreenState extends State<MatchResultScreen> {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));
  int _coinsEarned = 0;
  int _ratingDelta = 0;
  int _ratingAfter = PlayerProfile.instance.cpuRating;
  List<String> _newAchievements = [];
  bool _granted = false;

  bool get _won => widget.myPairs > widget.cpuPairs;
  bool get _draw => widget.myPairs == widget.cpuPairs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _grantRewards());
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _grantRewards() async {
    final profile = PlayerProfile.instance;
    final reward = await profile.recordGamePlayed(widget.myPairs);
    var coins = reward.total;

    if (!_draw) {
      final result = await profile.recordCpuGame(
        level: widget.cpuLevel.name,
        won: _won,
        correctQuizzes: widget.matches,
        totalQuizzes: widget.attempts,
        avgReactionMs: widget.avgDecisionMs,
      );
      _ratingDelta = result.ratingDelta;
      _ratingAfter = result.ratingAfter;
      _newAchievements = result.newlyUnlockedAchievements;
    }

    if (!mounted) return;
    setState(() {
      _coinsEarned = coins;
      _granted = true;
    });
    if (_won) {
      _confetti.play();
      Sfx.instance.victory();
      // レビュー依頼: 勝利の余韻タイミングで1回だけ
      if (!profile.reviewPrompted && profile.totalGames >= 5) {
        Future.delayed(const Duration(milliseconds: 1600), () async {
          final review = InAppReview.instance;
          if (await review.isAvailable()) {
            await profile.markReviewPrompted();
            review.requestReview();
          }
        });
      }
    } else {
      Sfx.instance.coin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    final rank = cpuRankForRating(_ratingAfter);
    final ja = m.ja;

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
                    _draw
                        ? m.matchDraw
                        : (_won ? m.matchWin : m.matchLose),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: _won
                          ? const Color(0xFFE8A400)
                          : const Color(0xFF3A7BD5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _scoreCard(m),
                  const SizedBox(height: 12),
                  if (_granted && !_draw) _ratingCard(m, rank, ja),
                  if (_granted && _coinsEarned > 0) ...[
                    const SizedBox(height: 12),
                    _coinBanner(m),
                  ],
                  if (_granted && _newAchievements.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _achievementsCard(m),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Sfx.instance.pop();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MatchGameScreen(
                            cpuLevel: widget.cpuLevel,
                            level: widget.level,
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
                        MaterialPageRoute(builder: (_) => const TopScreen()),
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
            blastDirection: pi / 2,
            emissionFrequency: 0.05,
            numberOfParticles: 24,
            maxBlastForce: 24,
            minBlastForce: 8,
            gravity: 0.25,
          ),
        ],
      ),
    );
  }

  Widget _scoreCard(MetaStrings m) {
    Widget side(String emoji, String label, int score, Color color) {
      return Expanded(
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 34)),
            Text(label,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w900, color: color)),
            Text('$score',
                style: TextStyle(
                    fontSize: 34, fontWeight: FontWeight.w900, color: color)),
            Text(m.pairsUnit,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      );
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            side('😀', m.you, widget.myPairs, const Color(0xFF3A7BD5)),
            const Text('VS',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey)),
            side('🤖', m.cpuLabel, widget.cpuPairs, const Color(0xFF8A5AC2)),
          ],
        ),
      ),
    );
  }

  Widget _ratingCard(MetaStrings m, CpuRank rank, bool ja) {
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
            '${ja ? rank.nameJa : rank.nameEn}  $_ratingAfter',
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

  Widget _coinBanner(MetaStrings m) {
    return Container(
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
    );
  }

  Widget _achievementsCard(MetaStrings m) {
    return Container(
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
    );
  }
}
