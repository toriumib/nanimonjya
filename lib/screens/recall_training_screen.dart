import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/meta_strings.dart';
import '../models/person.dart';
import '../services/player_profile.dart';
import '../services/sfx.dart';

/// 🧠 思い出しトレーニング
///
/// 実生活の「この人だれだっけ？」を再現する特訓。
/// 1) であう … 実写の人物（顔＋体）と名前・出会った場所を1人ずつ記銘
/// 2) 時間がたつ … 少し間をおく（すぐ答えさせない）
/// 3) 思い出す … 顔を見て名前を4択で想起。出会った場所がヒント
///
/// 顔はフリー素材の実写（char*.jpg / FaceKind.asset）を使い、体まで写して現実に近づける。
class RecallTrainingScreen extends StatefulWidget {
  final int level; // 1..3 → 人数 4/6/8

  const RecallTrainingScreen({super.key, this.level = 1});

  @override
  State<RecallTrainingScreen> createState() => _RecallTrainingScreenState();
}

enum _Phase { meet, gap, recall, result }

class _RecallTrainingScreenState extends State<RecallTrainingScreen> {
  final Random _rng = Random();
  late List<Person> _people; // 出会った順
  late List<Person> _quizOrder; // 思い出す順（シャッフル）

  _Phase _phase = _Phase.meet;
  int _meetIndex = 0;
  int _quizIndex = 0;

  // 思い出すフェーズ
  List<String> _choices = [];
  bool _answered = false;
  String? _picked;
  int _correct = 0;
  DateTime _questionShownAt = DateTime.now();
  int _totalReactionMs = 0;

  int get _peopleCount {
    switch (widget.level) {
      case 3:
        return 8;
      case 2:
        return 6;
      default:
        return 4;
    }
  }

  @override
  void initState() {
    super.initState();
    final ja =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'ja';
    _people = generateRecallPeople(_peopleCount, ja: ja, random: _rng);
    _quizOrder = [..._people]..shuffle(_rng);
  }

  // ---- であうフェーズ ----
  void _meetNext() {
    Sfx.instance.pop();
    if (_meetIndex + 1 < _people.length) {
      setState(() => _meetIndex += 1);
    } else {
      setState(() => _phase = _Phase.gap);
    }
  }

  // ---- 思い出すフェーズ ----
  void _startRecall() {
    Sfx.instance.pop();
    setState(() {
      _phase = _Phase.recall;
      _quizIndex = 0;
      _prepareChoices();
    });
  }

  Person get _quizPerson => _quizOrder[_quizIndex];

  void _prepareChoices() {
    final others = _people
        .where((p) => p.name != _quizPerson.name)
        .map((p) => p.name)
        .toList()
      ..shuffle(_rng);
    _choices = [_quizPerson.name, ...others.take(3)]..shuffle(_rng);
    _answered = false;
    _picked = null;
    _questionShownAt = DateTime.now();
  }

  void _answer(String choice) {
    if (_answered) return;
    _totalReactionMs += DateTime.now().difference(_questionShownAt).inMilliseconds;
    final correct = choice == _quizPerson.name;
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
    Future.delayed(const Duration(milliseconds: 950), _recallNext);
  }

  Future<void> _recallNext() async {
    if (_quizIndex + 1 < _quizOrder.length) {
      setState(() {
        _quizIndex += 1;
        _prepareChoices();
      });
    } else {
      await _finish();
    }
  }

  Future<void> _finish() async {
    final total = _quizOrder.length;
    final avgMs = total > 0 ? _totalReactionMs ~/ total : 0;
    // 記録＆コイン付与（思い出せた人数×8＋全問正解ボーナス）
    await PlayerProfile.instance.recordSoloTraining(
      correctQuizzes: _correct,
      totalQuizzes: total,
      avgReactionMs: avgMs,
    );
    final coins = _correct * 8 + (_correct == total ? 20 : 0);
    if (coins > 0) await PlayerProfile.instance.grantBonusCoins(coins);
    if (_correct == total) {
      Sfx.instance.victory();
    } else if (_correct >= (total / 2).ceil()) {
      Sfx.instance.fanfare();
    } else {
      Sfx.instance.coin();
    }
    if (mounted) setState(() => _phase = _Phase.result);
  }

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(m.recallTitle)),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF3FF), Color(0xFFFFF9EC)],
          ),
        ),
        child: SafeArea(
          child: switch (_phase) {
            _Phase.meet => _buildMeet(m),
            _Phase.gap => _buildGap(m),
            _Phase.recall => _buildRecall(m),
            _Phase.result => _buildResult(m),
          },
        ),
      ),
    );
  }

  // 実写の人物（顔＋体）を大きく見せるカード。頭が切れないよう上寄せでクロップ。
  Widget _personPhoto(Person p, {double height = 300}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Image.asset(
        p.face,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (_, __, ___) => Container(
          height: height,
          color: const Color(0xFFEAF3FF),
          child: const Icon(Icons.person, size: 90, color: Color(0xFF8FB4DC)),
        ),
      ),
    );
  }

  Widget _buildMeet(MetaStrings m) {
    final p = _people[_meetIndex];
    final isLast = _meetIndex + 1 >= _people.length;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: (_meetIndex + 1) / _people.length,
            minHeight: 6,
            backgroundColor: Colors.white,
            color: const Color(0xFF3A7BD5),
          ),
          const SizedBox(height: 6),
          Text('${m.recallMeetTitle}  ${_meetIndex + 1} / ${_people.length}',
              style: const TextStyle(color: Colors.black54, fontSize: 12.5)),
          const SizedBox(height: 6),
          Text(m.recallMeetHint,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black45)),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _personPhoto(p, height: 300),
                      const SizedBox(height: 14),
                      // 出会った場所（文脈）
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3D6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text('📍 ${m.metAt(p.where)}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF7A5A00))),
                      ),
                      const SizedBox(height: 10),
                      Text(p.name,
                          style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2B5CA5))),
                      if (p.hobby.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('${m.recallHobbyLabel}: ${p.hobby}',
                            style: const TextStyle(
                                fontSize: 13.5, color: Colors.black54)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _meetNext,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15)),
              child: Text(isLast ? m.recallRemembered : m.recallMeetNext,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGap(MetaStrings m) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⏳', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          Text(m.recallGapTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2B5CA5))),
          const SizedBox(height: 10),
          Text(m.recallGapSub,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startRecall,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text(m.recallGapButton,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecall(MetaStrings m) {
    final p = _quizPerson;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: (_quizIndex + 1) / _quizOrder.length,
            minHeight: 6,
            backgroundColor: Colors.white,
            color: const Color(0xFF3A7BD5),
          ),
          const SizedBox(height: 6),
          Text('${_quizIndex + 1} / ${_quizOrder.length}',
              style: const TextStyle(color: Colors.black54, fontSize: 12.5)),
          const SizedBox(height: 8),
          _personPhoto(p, height: 230),
          const SizedBox(height: 8),
          Text(m.recallWhoTitle,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2B5CA5))),
          Text('💡 ${m.hintMetAt(p.where)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black45)),
          const SizedBox(height: 10),
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
                                : (c == _quizPerson.name
                                    ? const Color(0xFFDFF5E1)
                                    : (c == _picked
                                        ? const Color(0xFFFCE4E4)
                                        : Colors.white)),
                            foregroundColor: const Color(0xFF2B5CA5),
                            elevation: _answered ? 0 : 3,
                            side: const BorderSide(
                                color: Color(0xFF3A7BD5), width: 2),
                            padding:
                                const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: Text(c,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(MetaStrings m) {
    final total = _quizOrder.length;
    final ratio = total > 0 ? _correct / total : 0.0;
    final encourage = ratio >= 1.0
        ? m.recallEncourageHigh
        : (ratio >= 0.5 ? m.recallEncourageMid : m.recallEncourageLow);
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          const SizedBox(height: 4),
          Text(m.recallResultTitle,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2B5CA5))),
          const SizedBox(height: 6),
          Text(m.recallCorrectOf(_correct, total),
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(encourage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(m.recallReview,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: _people.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final p = _people[i];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(p.face,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name,
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF2B5CA5))),
                            Text('📍 ${m.metAt(p.where)}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text(m.recallClose,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Sfx.instance.pop();
                    setState(() {
                      final ja = m.ja;
                      _people =
                          generateRecallPeople(_peopleCount, ja: ja, random: _rng);
                      _quizOrder = [..._people]..shuffle(_rng);
                      _phase = _Phase.meet;
                      _meetIndex = 0;
                      _quizIndex = 0;
                      _correct = 0;
                      _totalReactionMs = 0;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text(m.recallAgain,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
