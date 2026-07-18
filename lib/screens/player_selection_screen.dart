import 'package:flutter/material.dart';

import '../l10n/meta_strings.dart';
import '../models/cpu_rank.dart';
import '../services/player_profile.dart';
import '../services/sfx.dart';
import '../widgets/memory_tip_ticker.dart';
import 'cognitive_info_screen.dart';
import 'match_game_screen.dart';
import 'online_lobby_screen.dart';

/// あそぶモードの選択画面。
/// 一人特訓（レベル1〜3・記憶術ガイドあり/なし）と、CPU対戦（難易度4段階）を選ぶ。
class PlayerSelectionScreen extends StatefulWidget {
  const PlayerSelectionScreen({super.key});

  @override
  State<PlayerSelectionScreen> createState() => _PlayerSelectionScreenState();
}

class _PlayerSelectionScreenState extends State<PlayerSelectionScreen> {
  int _level = 1; // 1..3 → 4/6/8ペア
  int _localPlayers = 2; // みんなで対戦の人数（2〜4）

  void _start({CpuLevel? cpu, bool mnemonic = false, int humans = 1}) {
    Sfx.instance.pop();
    // タブシェルの中から呼ばれるので push（シェルを残す）
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MatchGameScreen(
          cpuLevel: cpu,
          level: _level,
          mnemonicGuide: mnemonic,
          humanPlayers: humans,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('🃏 ${m.tabPairs}')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF3FF), Color(0xFFFFF9EC)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const MemoryTipTicker(),
                const SizedBox(height: 16),
                _levelCard(m),
                const SizedBox(height: 16),
                _cpuCard(m),
                const SizedBox(height: 16),
                _localMultiCard(m),
                const SizedBox(height: 16),
                _onlineCard(m),
                const SizedBox(height: 14),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CognitiveInfoScreen()),
                    );
                  },
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: Text(m.cognitiveInfoButton),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1E7BA6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8E4F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _levelCard(MetaStrings m) {
    Widget chip(int level, int pairs) {
      final selected = _level == level;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _level = level),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF3A7BD5) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF3A7BD5), width: 2),
            ),
            child: Column(
              children: [
                Text(
                  'Lv.$level',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: selected ? Colors.white : const Color(0xFF3A7BD5),
                  ),
                ),
                Text(
                  m.levelDesc(pairs),
                  style: TextStyle(
                    fontSize: 10.5,
                    color: selected ? Colors.white : const Color(0xFF3A7BD5),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎚️ ${m.levelLabel}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            m.levelHint,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          Row(children: [chip(1, 4), chip(2, 6), chip(3, 8)]),
        ],
      ),
    );
  }

  // 🎉 1台のスマホをまわして遊ぶローカル対戦（2〜4人）
  Widget _localMultiCard(MetaStrings m) {
    Widget countChip(int n) {
      final selected = _localPlayers == n;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _localPlayers = n),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFE8663C) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8663C), width: 2),
            ),
            child: Text(
              '$n人',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: selected ? Colors.white : const Color(0xFFE8663C),
              ),
            ),
          ),
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            m.localMatchTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            m.localMatchDesc,
            style: const TextStyle(fontSize: 12.5, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          Row(children: [countChip(2), countChip(3), countChip(4)]),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _start(humans: _localPlayers),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8663C),
              minimumSize: const Size.fromHeight(46),
            ),
            child: Text(m.gameStartLabel),
          ),
        ],
      ),
    );
  }

  // 🌐 ペアさがしのオンライン対戦（同時レース）
  Widget _onlineCard(MetaStrings m) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(m.onlineMatchTitle,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(m.onlineRaceDesc,
              style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              Sfx.instance.fanfare();
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const OnlineLobbyScreen(game: 'pairs')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9F45),
              minimumSize: const Size.fromHeight(46),
            ),
            child: Text(m.onlineMatchTitle),
          ),
        ],
      ),
    );
  }

  Widget _cpuCard(MetaStrings m) {
    return AnimatedBuilder(
      animation: PlayerProfile.instance,
      builder: (context, _) {
        final profile = PlayerProfile.instance;
        final rank = cpuRankForRating(profile.cpuRating);
        final oniUnlocked = profile.cpuRating >= kOniUnlockRating;

        Widget cpuButton(String label, CpuLevel level, Color color,
            {bool locked = false}) {
          return ElevatedButton(
            onPressed: locked ? null : () => _start(cpu: level),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              minimumSize: const Size.fromHeight(44),
            ),
            child: Text(locked
                ? '$label 🔒 ${m.oniLockedHint(kOniUnlockRating)}'
                : label),
          );
        }

        return _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      m.cpuMatchTitle,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EDFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF8A5AC2)),
                    ),
                    child: Text(
                      '${rank.emoji} ${m.ja ? rank.nameJa : rank.nameEn} ${profile.cpuRating}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                m.cpuMatchDesc,
                style: const TextStyle(fontSize: 12.5, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              cpuButton(m.cpuEasy, CpuLevel.easy, Colors.green),
              const SizedBox(height: 8),
              cpuButton(m.cpuNormal, CpuLevel.normal, Colors.blueAccent),
              const SizedBox(height: 8),
              cpuButton(m.cpuHard, CpuLevel.hard, Colors.deepPurple),
              const SizedBox(height: 8),
              cpuButton(m.cpuOni, CpuLevel.oni, const Color(0xFFC62828),
                  locked: !oniUnlocked),
            ],
          ),
        );
      },
    );
  }
}
