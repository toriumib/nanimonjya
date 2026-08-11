import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/meta_strings.dart';
import '../models/person.dart';
import '../services/player_profile.dart';
import '../services/sfx.dart';
import '../widgets/face_view.dart';

/// 🪙 コイン倍増ミニゲーム。
/// 3人の顔と名前を覚えて、全問正解で賭けたコインが倍に。
/// 1問でも間違えたら没収。ハイリスク・ハイリターン。
class CoinDoublerScreen extends StatefulWidget {
  final int bet;
  const CoinDoublerScreen({super.key, this.bet = 50});

  @override
  State<CoinDoublerScreen> createState() => _CoinDoublerScreenState();
}

class _CoinDoublerScreenState extends State<CoinDoublerScreen> {
  final _rng = Random();
  late final List<Person> _people;
  int _phase = 0; // 0=memorize, 1..3=quiz, 4=result
  int _memorizeLeft = 6;
  int _correct = 0;
  int _index = 0;
  List<String> _choices = [];
  String? _picked;

  @override
  void initState() {
    super.initState();
    final ja = MetaStrings.of(context).ja;
    _people = generatePeople(3, ja: ja, random: _rng);
    _tickMemorize();
  }

  void _tickMemorize() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _memorizeLeft -= 1);
      if (_memorizeLeft <= 0) {
        setState(() { _phase = 1; _buildChoices(); });
      } else {
        _tickMemorize();
      }
    });
  }

  void _buildChoices() {
    final ja = MetaStrings.of(context).ja;
    final answer = _people[_index].name;
    final pool = <String>{answer};
    for (final p in _people) pool.add(p.name);
    final filler = generatePeople(4, ja: ja, random: _rng);
    for (final p in filler) { pool.add(p.name); if (pool.length >= 4) break; }
    _choices = [...pool]..shuffle(_rng);
    if (_choices.first == answer && _choices.length > 1) {
      final tmp = _choices[0]; _choices[0] = _choices.last; _choices[_choices.length - 1] = tmp;
    }
    _picked = null;
  }

  void _answer(String choice) {
    if (_picked != null) return;
    final correct = choice == _people[_index].name;
    if (correct) {
      _correct += 1;
      Sfx.instance.correct();
      HapticFeedback.lightImpact();
    } else {
      Sfx.instance.wrong();
      HapticFeedback.mediumImpact();
    }
    setState(() => _picked = choice);
    Future.delayed(Duration(milliseconds: correct ? 500 : 900), () {
      if (!mounted) return;
      _index += 1;
      if (_index >= _people.length) {
        setState(() => _phase = 4);
        _grantResult();
      } else {
        setState(() => _phase = _index + 1);
        _buildChoices();
      }
    });
  }

  void _grantResult() {
    final p = PlayerProfile.instance;
    if (_correct >= _people.length) {
      final reward = widget.bet * 2;
      p.grantBonusCoins(reward);
      Sfx.instance.fanfare();
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    final won = _correct >= _people.length;
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: Text(m.ja ? '🪙 コイン倍増ゲーム' : '🪙 Coin Doubler',
            style: const TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _phase == 0
            ? _memorizeView(m)
            : _phase <= 3
                ? _quizView(m)
                : _resultView(m, won),
      ),
    );
  }

  Widget _memorizeView(MetaStrings m) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(m.ja ? '🪙 コイン倍増チャレンジ！' : '🪙 Coin Doubler Challenge!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 4),
          Text(m.ja
              ? '3人全員覚えたら 🪙${widget.bet} → 🪙${widget.bet * 2} ！'
              : 'Memorize all 3 → 🪙${widget.bet} → 🪙${widget.bet * 2}!',
              style: const TextStyle(fontSize: 14, color: Color(0xFF8899BB))),
          const SizedBox(height: 6),
          Text(m.ja ? '1人でも間違えたら没収…！' : 'Miss even one and you lose it all!',
              style: const TextStyle(fontSize: 12, color: Color(0xFFFF6A3D))),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: _memorizeLeft / 6, minHeight: 4, color: const Color(0xFFFFC02E)),
          const SizedBox(height: 4),
          Text('$_memorizeLeft s', style: const TextStyle(color: Color(0xFF8899BB))),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                for (final p in _people)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD8E4F0)),
                    ),
                    child: Row(children: [
                      FaceView(person: p, size: 80, radius: 12),
                      const SizedBox(width: 14),
                      Expanded(child: Text(p.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
                    ]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quizView(MetaStrings m) {
    final person = _people[_index];
    final answered = _picked != null;
    final correct = answered && _picked == person.name;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Text('${_index + 1} / 3', style: const TextStyle(color: Color(0xFF8899BB))),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: answered
                  ? (correct ? const Color(0xFF2E9E5B) : const Color(0xFFC62828))
                  : const Color(0xFFD8E4F0),
              width: 3,
            ),
            boxShadow: [BoxShadow(
              color: answered && correct
                  ? const Color(0xFF2E9E5B).withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: answered && correct ? 20 : 8,
            )],
          ),
          child: Column(children: [
            FaceView(person: person, size: 180, radius: 16),
            if (answered) ...[
              const SizedBox(height: 8),
              Text(correct ? person.name : '？',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900,
                      color: correct ? const Color(0xFF2E9E5B) : const Color(0xFFC62828))),
            ],
          ]),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.8,
            children: [
              for (final choice in _choices)
                ElevatedButton(
                  onPressed: answered ? null : () => _answer(choice),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _choiceColor(choice, person.name),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _choiceColor(choice, person.name),
                    disabledForegroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                  child: Text(choice, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                ),
            ],
          ),
        ),
      ]),
    );
  }

  Color _choiceColor(String choice, String answer) {
    if (_picked == null) return const Color(0xFF3A7BD5);
    if (choice == answer) return const Color(0xFF2E9E5B);
    if (choice == _picked) return const Color(0xFFC62828);
    return const Color(0xFF44506B);
  }

  Widget _resultView(MetaStrings m, bool won) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(won ? '🪙' : '💸', style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          Text(
            won
                ? (m.ja ? '全問正解！\n🪙${widget.bet} → 🪙${widget.bet * 2} ゲット！'
                    : 'Perfect!\n🪙${widget.bet} → 🪙${widget.bet * 2}!')
                : (m.ja ? 'ざんねん…\n🪙${widget.bet} を失いました…' : 'Too bad…\nYou lost 🪙${widget.bet}…'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900,
                color: won ? const Color(0xFFFFC02E) : const Color(0xFFC62828)),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3A7BD5),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              padding: const EdgeInsets.symmetric(horizontal: 40),
            ),
            child: Text(m.ja ? 'とじる' : 'Close',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          ),
        ]),
      ),
    );
  }
}
