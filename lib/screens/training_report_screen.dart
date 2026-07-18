import 'package:flutter/material.dart';
import '../l10n/meta_strings.dart';
import '../services/player_profile.dart';
import '../services/sfx.dart';
import 'cognitive_info_screen.dart';
import 'match_game_screen.dart';
import 'memory_tips_screen.dart';
import 'home_shell.dart';

/// 一人特訓モード（顔と名前の神経衰弱）終了後のトレーニングレポート。
/// 勝敗ではなく、一致成功率・手数効率・判断時間などの自己記録をフィードバックする。
class TrainingReportScreen extends StatefulWidget {
  final int cardsNamed; // おぼえた人数（ペア数）
  final int correctQuizzes; // ペア成立＋ボーナスクイズ正解
  final int totalQuizzes; // めくり試行＋ボーナスクイズ出題
  final int avgReactionMs; // 平均判断時間（1枚目→2枚目）
  final int bestStreak; // 最大連続ペア成立
  final int level;
  final bool mnemonicGuide;
  final int score;

  const TrainingReportScreen({
    super.key,
    required this.cardsNamed,
    required this.correctQuizzes,
    required this.totalQuizzes,
    required this.avgReactionMs,
    required this.bestStreak,
    this.level = 1,
    this.mnemonicGuide = false,
    this.score = 0,
  });

  @override
  State<TrainingReportScreen> createState() => _TrainingReportScreenState();
}

class _TrainingReportScreenState extends State<TrainingReportScreen> {
  int _coinsEarned = 0;
  List<String> _newAchievements = [];
  bool _granted = false;

  int get _accuracyPct => widget.totalQuizzes == 0
      ? 0
      : (widget.correctQuizzes * 100 ~/ widget.totalQuizzes);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _grantRewards());
  }

  Future<void> _grantRewards() async {
    final profile = PlayerProfile.instance;
    final reward = await profile.recordGamePlayed(widget.correctQuizzes);
    final newly = await profile.recordSoloTraining(
      correctQuizzes: widget.correctQuizzes,
      totalQuizzes: widget.totalQuizzes,
      avgReactionMs: widget.avgReactionMs,
    );
    if (!mounted) return;
    setState(() {
      _coinsEarned = reward.total;
      _newAchievements = newly;
      _granted = true;
    });
    if (_newAchievements.isNotEmpty) {
      Sfx.instance.coin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    final avgSec = (widget.avgReactionMs / 1000).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        title: Text(m.trainingReportTitle),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                m.trainingReportIntro,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 20),
              _statsCard(m, avgSec),
              const SizedBox(height: 16),
              if (_granted) _coinBanner(m),
              if (_granted && _newAchievements.isNotEmpty) ...[
                const SizedBox(height: 12),
                _achievementsCard(m),
              ],
              const SizedBox(height: 20),
              _tendencyCard(m),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Sfx.instance.pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MatchGameScreen(
                        level: widget.level,
                        mnemonicGuide: widget.mnemonicGuide,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: Text(m.playAgainTraining),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MemoryTipsScreen()),
                  );
                },
                icon: const Icon(Icons.menu_book_rounded),
                label: Text(m.memoryTipsButton),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CognitiveInfoScreen()),
                  );
                },
                icon: const Icon(Icons.info_outline),
                label: Text(m.cognitiveInfoButton),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {
                  Sfx.instance.pop();
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
    );
  }

  Widget _statsCard(MetaStrings m, String avgSec) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        child: Column(
          children: [
            if (widget.mnemonicGuide) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  m.mnemonicTrainingButton,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (widget.score > 0) ...[
              _statRow('🏅', m.levelLabel, 'Lv.${widget.level}'),
              const Divider(height: 22),
              _statRow('✨', 'SCORE', '${widget.score}'),
              const Divider(height: 22),
            ],
            _statRow('📇', m.cardsNamedLabel, '${widget.cardsNamed}'),
            const Divider(height: 22),
            _statRow('🎯', m.quizAccuracyLabel, '$_accuracyPct%'),
            const Divider(height: 22),
            _statRow('⏱️', m.avgReactionLabel,
                widget.avgReactionMs > 0 ? '$avgSec秒' : '—'),
            const Divider(height: 22),
            _statRow('🔥', m.bestStreakLabel, '${widget.bestStreak}'),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String emoji, String label, String value) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 15)),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _coinBanner(MetaStrings m) {
    if (_coinsEarned <= 0) return const SizedBox.shrink();
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
            fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8A6A1E)),
      ),
    );
  }

  Widget _achievementsCard(MetaStrings m) {
    return Container(
      width: double.infinity,
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

  Widget _tendencyCard(MetaStrings m) {
    final hasData = widget.totalQuizzes > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A7BD5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasData)
            Text(
              m.trainingReportIntro,
              style: const TextStyle(fontSize: 14),
            )
          else ...[
            _tendencyLine(
              m.skillWorkingMemory,
              _accuracyPct >= 70
                  ? m.skillCommentGood(m.skillWorkingMemory)
                  : m.skillCommentOk(m.skillWorkingMemory),
            ),
            const SizedBox(height: 10),
            _tendencyLine(
              m.skillAttention,
              widget.bestStreak >= 5
                  ? m.skillCommentGood(m.skillAttention)
                  : m.skillCommentOk(m.skillAttention),
            ),
            const SizedBox(height: 10),
            _tendencyLine(
              m.skillSpeed,
              (widget.avgReactionMs > 0 && widget.avgReactionMs < 2000)
                  ? m.skillCommentGood(m.skillSpeed)
                  : m.skillCommentOk(m.skillSpeed),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tendencyLine(String skill, String comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(skill,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF3A7BD5))),
        const SizedBox(height: 2),
        Text(comment, style: const TextStyle(fontSize: 13, height: 1.5)),
      ],
    );
  }
}
