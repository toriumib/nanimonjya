import 'package:flutter/material.dart';

import '../l10n/meta_strings.dart';
import '../models/person.dart';
import '../services/sfx.dart';
import '../widgets/memory_tip_ticker.dart';
import 'cognitive_info_screen.dart';
import 'match_game_screen.dart';
import 'recall_training_screen.dart';

/// 「とっくん」タブ: 一人特訓（神経衰弱ベース）と記憶術トレーニング。
class TrainingHubScreen extends StatefulWidget {
  const TrainingHubScreen({super.key});

  @override
  State<TrainingHubScreen> createState() => _TrainingHubScreenState();
}

class _TrainingHubScreenState extends State<TrainingHubScreen> {
  int _level = 1;
  // 覚える項目。会社名＋名前が基本、他はオプション。
  final Set<RecallField> _fields = {RecallField.name, RecallField.company};

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

  void _startRecall() {
    Sfx.instance.fanfare();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecallTrainingScreen(level: _level, fields: {..._fields}),
      ),
    );
  }

  // 覚える項目トグル（名前は必須、会社はデフォルトON、他はオプション）
  Widget _fieldChip(RecallField f, String label, {bool fixed = false}) {
    final on = _fields.contains(f);
    return FilterChip(
      label: Text(label,
          style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: on ? const Color(0xFF2B5CA5) : Colors.white)),
      selected: on,
      showCheckmark: false,
      backgroundColor: Colors.white.withValues(alpha: 0.18),
      selectedColor: Colors.white,
      side: BorderSide(color: Colors.white.withValues(alpha: 0.7)),
      onSelected: fixed
          ? null
          : (v) {
              Sfx.instance.pop();
              setState(() {
                if (v) {
                  _fields.add(f);
                } else {
                  _fields.remove(f);
                }
              });
            },
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
                // 🧠 実写で「この人だれだっけ？」を思い出す特訓（とっくんの主役）
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3A7BD5), Color(0xFF00C2A8)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3A7BD5).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.recallTitle,
                          style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                      const SizedBox(height: 6),
                      Text(m.recallHubDesc,
                          style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                              color: Colors.white)),
                      const SizedBox(height: 12),
                      Text(m.recallFieldsTitle,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _fieldChip(RecallField.name, m.fieldLabel(RecallField.name),
                              fixed: true),
                          _fieldChip(
                              RecallField.company, m.fieldLabel(RecallField.company)),
                          _fieldChip(
                              RecallField.title, m.fieldLabel(RecallField.title)),
                          _fieldChip(
                              RecallField.phone, m.fieldLabel(RecallField.phone)),
                          _fieldChip(
                              RecallField.email, m.fieldLabel(RecallField.email)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: _startRecall,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF2B5CA5),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: Text(m.recallStart,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w900)),
                      ),
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
