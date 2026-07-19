import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/meta_strings.dart';
import '../models/person.dart';
import '../services/sfx.dart';
import '../widgets/face_view.dart';

/// おぼえるモード: アップした写真＋名前を覚える学習＆確認テスト。
/// [quizMode] false=学習（フラッシュカード）, true=クイズ（写真→4択で名前当て）。
class StudyScreen extends StatefulWidget {
  final List<Person> people;
  final bool quizMode;

  const StudyScreen({super.key, required this.people, this.quizMode = false});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  final Random _rng = Random();
  late List<Person> _order;
  int _index = 0;

  // 学習: 名前を表示中か
  bool _revealed = false;

  // クイズ
  List<String> _choices = [];
  int _correct = 0;
  bool _answered = false;
  String? _picked;

  @override
  void initState() {
    super.initState();
    _order = [...widget.people]..shuffle(_rng);
    if (widget.quizMode) _prepareChoices();
  }

  Person get _current => _order[_index];

  void _prepareChoices() {
    final others = widget.people
        .where((p) => p.name != _current.name)
        .map((p) => p.name)
        .toSet()
        .toList()
      ..shuffle(_rng);
    _choices = [_current.name, ...others.take(3)]..shuffle(_rng);
    _answered = false;
    _picked = null;
  }

  void _next() {
    if (_index + 1 < _order.length) {
      setState(() {
        _index += 1;
        _revealed = false;
        if (widget.quizMode) _prepareChoices();
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _answer(String choice) {
    if (_answered) return;
    final correct = choice == _current.name;
    if (correct) {
      _correct += 1;
      Sfx.instance.correct();
    } else {
      Sfx.instance.wrong();
    }
    setState(() {
      _answered = true;
      _picked = choice;
    });
    Future.delayed(const Duration(milliseconds: 900), _next);
  }

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quizMode ? m.quizTitle : m.studyTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: (_index + 1) / _order.length,
                minHeight: 6,
                backgroundColor: Colors.grey.shade300,
              ),
              const SizedBox(height: 6),
              Text('${_index + 1} / ${_order.length}',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              Expanded(
                child: widget.quizMode ? _buildQuiz(m) : _buildStudy(m),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudy(MetaStrings m) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(m.studyHint,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            Sfx.instance.pop();
            setState(() => _revealed = !_revealed);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFD8E4F0), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaceView(person: _current, size: 200, radius: 18),
                const SizedBox(height: 12),
                Text(
                  _revealed ? _current.name : 'タップで名前をひょうじ',
                  style: TextStyle(
                    fontSize: _revealed ? 26 : 14,
                    fontWeight: FontWeight.w900,
                    color: _revealed
                        ? const Color(0xFF2B5CA5)
                        : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _next,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(_index + 1 < _order.length
                ? (m.ja ? 'つぎへ →' : 'Next →')
                : m.studyDone),
          ),
        ),
      ],
    );
  }

  Widget _buildQuiz(MetaStrings m) {
    return Column(
      children: [
        FaceView(person: _current, size: 180, radius: 18),
        const SizedBox(height: 16),
        Text(m.whoIsThis,
            style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final c in _choices)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _answer(c),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !_answered
                              ? Colors.white
                              : (c == _current.name
                                  ? const Color(0xFFDFF5E1)
                                  : (c == _picked
                                      ? const Color(0xFFFCE4E4)
                                      : Colors.white)),
                          foregroundColor: const Color(0xFF2B5CA5),
                          side: const BorderSide(
                              color: Color(0xFF3A7BD5), width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(c,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_index + 1 >= _order.length && _answered)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              m.quizScore(_correct, _order.length),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
      ],
    );
  }
}
