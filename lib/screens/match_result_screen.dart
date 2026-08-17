import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/meta_strings.dart';
import '../widgets/app_style.dart';
import '../models/cpu_rank.dart';
import '../models/person.dart';
import '../services/bgm.dart';
import '../services/interstitial_ad_helper.dart';
import '../services/player_profile.dart';
import '../services/review_prompt.dart'; // ⭐ レビュー依頼の共通処理
import '../services/sfx.dart';
import '../widgets/count_up.dart';
import '../widgets/double_coins_button.dart';
import '../widgets/roster_reveal.dart';
import '../widgets/store_cta.dart';
import '../widgets/native_ad_card.dart';
import 'match_game_screen.dart';
import 'home_shell.dart';
import '../widgets/banner_ad_slot.dart';
import '../services/app_analytics.dart';

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

  /// 📇 この試合に出てきた人たち。結果で「誰が誰だったか」を見せる。
  final List<Person> people;

  const MatchResultScreen({
    super.key,
    required this.cpuLevel,
    required this.level,
    required this.myPairs,
    required this.cpuPairs,
    required this.attempts,
    required this.matches,
    required this.avgDecisionMs,
    this.people = const [],
  });

  @override
  State<MatchResultScreen> createState() => _MatchResultScreenState();
}

class _MatchResultScreenState extends State<MatchResultScreen> {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 3));
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
    AppAnalytics.screen('match_result');
    WidgetsBinding.instance.addPostFrameCallback((_) => _grantRewards());
    Bgm.instance.playResult(); // 🎵 選んだリザルト曲（今までどこからも鳴っていなかった）
    InterstitialAdHelper.instance.onGameFinished(); // 3プレイに1回、全画面広告
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
      // ⭐ 勝利の余韻でレビューを頼む。
      // ⚠️ ここは以前 reviewPrompted（1回きりのフラグ）を直接見ていた。
      //    requestReview() は Google の割り当てで**何も出ないことがある**のに
      //    フラグだけ立つので、一度も表示されないまま二度と頼めなくなる。
      //    間隔をあけて数回試す maybeAskReview に寄せる。
      Future.delayed(const Duration(milliseconds: 1600), maybeAskReview);
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
      bottomNavigationBar: const BannerAdSlot(placement: 'match_result'),
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
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: _won
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
                  _scoreCard(m)
                      .animate()
                      .fadeIn(delay: 150.ms, duration: 300.ms)
                      .slideY(begin: 0.15, end: 0),
                  const SizedBox(height: 12),
                  if (_granted && !_draw)
                    _ratingCard(m, rank, ja)
                        .animate()
                        .fadeIn(delay: 450.ms, duration: 300.ms)
                        .slideY(begin: 0.15, end: 0),
                  if (_granted && _coinsEarned > 0) ...[
                    const SizedBox(height: 12),
                    _coinBanner(m)
                        .animate()
                        .fadeIn(delay: 700.ms, duration: 300.ms)
                        .slideY(begin: 0.15, end: 0),
                    const SizedBox(height: 10),
                    DoubleCoinsButton(coinsEarned: _coinsEarned)
                        .animate()
                        .fadeIn(delay: 850.ms, duration: 300.ms),
                  ],
                  if (_granted && _newAchievements.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _achievementsCard(m)
                        .animate()
                        .fadeIn(delay: 950.ms, duration: 300.ms)
                        .scale(
                          begin: const Offset(0.9, 0.9),
                          end: const Offset(1, 1),
                          duration: 300.ms,
                        ),
                  ],
                  const SizedBox(height: 20),
                  RosterRevealCard(people: widget.people),
                  const SizedBox(height: 12),
                  const StoreCtaCard(),
                  const SizedBox(height: 16),
                  const NativeAdCard(),
                  const SizedBox(height: 16),
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
            numberOfParticles: 42,
            maxBlastForce: 32,
            minBlastForce: 10,
            gravity: 0.22,
          ),
        ],
      ),
    );
  }

  Widget _scoreCard(MetaStrings m) {
    // 得点は色で競わせず、**数字の大きさ**で見せる。
    // 勝った側だけゴールドにして、どちらが上かは1色で示す。
    Widget side(String emoji, String label, int score, bool won) {
      final c = won ? AppStyle.gold : AppStyle.textMuted;
      return Expanded(
        child: Column(
          children: [
            Text(label,
                style: AppStyle.sectionLabel.copyWith(color: c)),
            const SizedBox(height: 6),
            CountUp(score, style: AppStyle.figure.copyWith(color: c)),
            Text(m.pairsUnit,
                style: const TextStyle(
                    fontSize: 11, color: AppStyle.textFaint)),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Row(
          children: [
            side('', m.you, widget.myPairs,
                widget.myPairs >= widget.cpuPairs),
            Container(width: 1, height: 46, color: AppStyle.line),
            side('', m.cpuLabel, widget.cpuPairs,
                widget.cpuPairs > widget.myPairs),
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
        color: AppStyle.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppStyle.line, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(rank.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 8),
          Text(
            '${ja ? rank.nameJa : rank.nameEn}  ',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          CountUp(
            _ratingAfter,
            begin: _ratingAfter - _ratingDelta,
            duration: const Duration(milliseconds: 1200),
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
        border: Border.all(color: AppStyle.line, width: 1),
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
        border: Border.all(color: AppStyle.line, width: 1),
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
