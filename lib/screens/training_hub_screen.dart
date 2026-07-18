import 'package:flutter/material.dart';

import '../l10n/meta_strings.dart';
import '../services/sfx.dart';
import '../widgets/memory_tip_ticker.dart';
import 'cognitive_info_screen.dart';
import 'match_game_screen.dart';

/// 「とっくん」タブ: 一人特訓（神経衰弱ベース）と記憶術トレーニング。
class TrainingHubScreen extends StatefulWidget {
  const TrainingHubScreen({super.key});

  @override
  State<TrainingHubScreen> createState() => _TrainingHubScreenState();
}

class _TrainingHubScreenState extends State<TrainingHubScreen> {
  int _level = 1;

  void _start({bool mnemonic = false}) {
    Sfx.instance.pop();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MatchGameScreen(
          level: _level,
          mnemonicGuide: mnemonic,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(m.tabTraining)),
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
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🎚️ ${m.levelLabel}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(m.levelHint,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 10),
                      Row(children: [
                        _levelChip(1, 4),
                        _levelChip(2, 6),
                        _levelChip(3, 8),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.soloTrainingTitle,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(m.soloTrainingDesc,
                          style: const TextStyle(
                              fontSize: 12.5, color: Colors.black54)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _start(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4ECDC4),
                          minimumSize: const Size.fromHeight(46),
                        ),
                        child: Text(m.soloTrainingStart),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _start(mnemonic: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE8A400),
                          minimumSize: const Size.fromHeight(46),
                        ),
                        child: Text(m.mnemonicTrainingButton),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        m.mnemonicTrainingDesc,
                        style: const TextStyle(
                            fontSize: 11.5, color: Colors.black45),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
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

  Widget _levelChip(int level, int pairs) {
    final m = MetaStrings.of(context);
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
              Text('Lv.$level',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color:
                          selected ? Colors.white : const Color(0xFF3A7BD5))),
              Text(m.levelDesc(pairs),
                  style: TextStyle(
                      fontSize: 10.5,
                      color:
                          selected ? Colors.white : const Color(0xFF3A7BD5))),
            ],
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
}
