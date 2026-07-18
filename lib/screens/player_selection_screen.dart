import 'package:flutter/material.dart';
import '../models/cosmetics.dart'; // ホーム着せ替えテーマ（背景グラデーション）
import '../models/cpu_rank.dart'; // CPU段位
import '../services/player_profile.dart';
import 'cognitive_info_screen.dart'; // 認知トレーニングについて
import 'game_screen.dart'; // 次の画面
import '../l10n/meta_strings.dart'; // CPU対戦の文言

// 多言語対応のために追加
import 'package:nanimonjya/l10n/app_localizations.dart';

class PlayerSelectionScreen extends StatefulWidget {
  const PlayerSelectionScreen({super.key});

  @override
  State<PlayerSelectionScreen> createState() => _PlayerSelectionScreenState();
}

class _PlayerSelectionScreenState extends State<PlayerSelectionScreen> {
  // プレイヤー人数を保持する変数。初期値は2人
  int _playerCount = 2;

  // ゲーム開始処理
  void _startGame() {
    // GameScreen にプレイヤー人数を渡して遷移
    Navigator.pushReplacement(
      // この画面に戻れないように置き換え
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(playerCount: _playerCount),
      ),
    );
  }

  // 🤖 CPU対戦（ひとりプレイ）開始
  void _startCpuGame(CpuLevel level) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(playerCount: 2, cpuLevel: level),
      ),
    );
  }

  // 🧠 一人特訓モード開始（対戦相手なし）
  void _startSoloTraining() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const GameScreen(
          playerCount: 1,
          soloTraining: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 多言語対応の文字列にアクセスするためのインスタンス
    final localizations = AppLocalizations.of(context)!;
    final m = MetaStrings.of(context);
    final homeTheme = homeThemeById(PlayerProfile.instance.selectedTheme);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.playerCountSelection),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: m.cognitiveInfoButton,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CognitiveInfoScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: homeTheme.gradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // ── 👥 ローカル対戦（同じ端末でみんなで） ──
                _sectionCard(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Text(
                        localizations.selectPlayerCountPrompt,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10.0,
                        runSpacing: 10.0,
                        alignment: WrapAlignment.center,
                        children: List.generate(5, (index) {
                          int count = index + 2;
                          final selected = _playerCount == count;
                          return ElevatedButton(
                            onPressed: () => setState(() => _playerCount = count),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  selected ? const Color(0xFF4ECDC4) : Colors.grey.shade300,
                              foregroundColor: selected ? Colors.white : Colors.black87,
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                            child: Text(localizations.players(count)),
                          );
                        }),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: _startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9F45),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                        ),
                        child: Text(localizations.gameStart),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── 🤖 CPU対戦 ──
                _sectionCard(
                  color: Colors.white,
                  child: AnimatedBuilder(
                    animation: PlayerProfile.instance,
                    builder: (context, _) {
                      final profile = PlayerProfile.instance;
                      final rank = cpuRankForRating(profile.cpuRating);
                      final oniUnlocked = profile.cpuRating >= kOniUnlockRating;
                      return Column(
                        children: [
                          Text(
                            m.cpuSectionTitle,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m.cpuSectionDesc,
                            style: const TextStyle(fontSize: 13, color: Colors.black54),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          // 現在のCPU段位バッジ
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3D6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE6B54A)),
                            ),
                            child: Text(
                              '${rank.emoji} ${m.ja ? rank.nameJa : rank.nameEn}  '
                              '${m.cpuRatingLabel} ${profile.cpuRating}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF8A6A1E)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10.0,
                            runSpacing: 10.0,
                            alignment: WrapAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () => _startCpuGame(CpuLevel.easy),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                ),
                                child: Text(m.cpuEasy),
                              ),
                              ElevatedButton(
                                onPressed: () => _startCpuGame(CpuLevel.normal),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                ),
                                child: Text(m.cpuNormal),
                              ),
                              ElevatedButton(
                                onPressed: () => _startCpuGame(CpuLevel.hard),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                ),
                                child: Text(m.cpuHard),
                              ),
                              oniUnlocked
                                  ? ElevatedButton(
                                      onPressed: () => _startCpuGame(CpuLevel.oni),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF8B0000),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20)),
                                      ),
                                      child: Text(m.cpuOni),
                                    )
                                  : Tooltip(
                                      message: m.oniLockedHint(kOniUnlockRating),
                                      child: Chip(
                                        avatar: const Icon(Icons.lock, size: 16),
                                        label: Text(m.cpuOni),
                                        backgroundColor: Colors.grey.shade300,
                                      ),
                                    ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),

                // ── 🧠 一人特訓モード ──
                _sectionCard(
                  color: const Color(0xFFEAF3FF),
                  borderColor: const Color(0xFF3A7BD5),
                  child: Column(
                    children: [
                      Text(
                        m.soloTrainingTitle,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF3A7BD5)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        m.soloTrainingDesc,
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: _startSoloTraining,
                        icon: const Icon(Icons.self_improvement),
                        label: Text(m.soloTrainingStart),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3A7BD5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required Widget child,
    Color color = Colors.white,
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: borderColor != null ? Border.all(color: borderColor, width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
