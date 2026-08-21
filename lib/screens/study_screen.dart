import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/meta_strings.dart';
import '../models/person.dart';
import '../services/sfx.dart';
import '../services/memory_stats.dart';
import '../services/player_profile.dart';
import '../services/review_queue.dart';
import '../widgets/double_coins_button.dart';
import '../widgets/face_view.dart';
import '../widgets/banner_ad_slot.dart';
import '../services/app_analytics.dart';

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
  bool _ja = true;

  /// 出題した時刻。速さ（平均回答時間）の集計に使う。
  DateTime _shownAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    AppAnalytics.screen('study');
    _order = [...widget.people]..shuffle(_rng);
    // 🔁 覚えたい相手を日をまたいで出し直すため、キューを先に読んでおく
    ReviewQueue.instance.load();
    MemoryStats.instance.load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Localizations は initState では引けないので、ここで言語を決めてから
    // 最初の選択肢を作る（ダミー選択肢の言語がこれで決まる）。
    _ja = MetaStrings.of(context).ja;
    if (widget.quizMode && _choices.isEmpty) {
      _prepareChoices();
      // 📊 「この人に会った」= フラッシュカードや登録で一度見ている前提。
      //     出題前に記録しておかないと定着率の分母に入らない。
      _recordMeeting();
    }
  }

  Person get _current => _order[_index];

  String _statKey(Person p) =>
      MemoryStats.keyOf(face: p.face, name: p.name, field: 'name');

  void _recordMeeting() =>
      MemoryStats.instance.recordMeeting(itemKey: _statKey(_current));

  void _prepareChoices() {
    final others = widget.people
        .where((p) => p.name != _current.name)
        .map((p) => p.name)
        .toSet()
        .toList()
      ..shuffle(_rng);
    final picked = others.take(3).toList();
    // 🎯 登録が2〜3人しかない名簿だと選択肢が正解＋1個になり、
    //    覚えていなくても当たってしまう（＝確認テストにならない）。
    //    足りない分は実在しそうな苗字で埋めて必ず4択にする。
    if (picked.length < 3) {
      picked.addAll(recallDistractors(
        RecallField.name,
        ja: _ja,
        count: 3 - picked.length,
        like: _current.name,
        exclude: {
          for (final p in widget.people) p.name,
          ...picked,
        },
        random: _rng,
      ));
    }
    _choices = [_current.name, ...picked]..shuffle(_rng);
    _answered = false;
    _picked = null;
    _shownAt = DateTime.now();
  }

  void _next() {
    // 回答直後の遅延コールバックから呼ばれるため、離脱済みならなにもしない
    if (!mounted) return;
    if (_index + 1 < _order.length) {
      setState(() {
        _index += 1;
        _revealed = false;
        if (widget.quizMode) _prepareChoices();
      });
      if (widget.quizMode) _recordMeeting();
    } else if (widget.quizMode) {
      _finishQuiz();
    } else {
      Navigator.pop(context);
    }
  }

  void _answer(String choice) {
    if (_answered) return;
    final correct = choice == _current.name;
    final reactionMs = DateTime.now().difference(_shownAt).inMilliseconds;
    final person = _current;

    // 📊 成績レポート（顔メモ枠）。実在の人の記録なので架空の人と混ぜない。
    MemoryStats.instance.record(
      mode: StatMode.faceMemo,
      itemKey: _statKey(person),
      correct: correct,
      reactionMs: reactionMs,
    );
    // 🔁 日をまたいだ復習。まちがえた人は明日また出てくる。
    //     当てられた人は間隔をひろげて（1→3→7→14→30日）いずれ卒業する。
    if (correct) {
      ReviewQueue.instance.recordSuccess(person);
    } else {
      ReviewQueue.instance.recordMiss(person);
    }

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

  /// 確認テストを終える。成績を保存し、がんばりぶんのコインを渡してから結果を出す。
  Future<void> _finishQuiz() async {
    await MemoryStats.instance.finishSession(StatMode.faceMemo);
    final reward = _correct * 5 + (_correct == _order.length ? 15 : 0);
    if (reward > 0) await PlayerProfile.instance.grantBonusCoins(reward);
    if (!mounted) return;
    final m = MetaStrings.of(context);
    final due = ReviewQueue.instance.dueCount();
    final missed = _order.length - _correct;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.quizScore(_correct, _order.length)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reward > 0) ...[
              Text('🪙 +$reward',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900)),
              // 🎬 結果が出た直後は、動画を見てもらいやすい場面
              //    （他のリザルト画面と同じ置き方にそろえる）
              DoubleCoinsButton(coinsEarned: reward),
            ],
            const SizedBox(height: 8),
            Text(
              missed > 0
                  ? (m.ja
                      ? 'まちがえた$missed人は、日をあらためて「ビジネス特訓」の復習に出てきます。'
                      : 'The $missed you missed will come back for review in Business Training on a later day.')
                  : (m.ja
                      ? '全員おぼえられました。日をおいてもう一度ためすと、定着したかが分かります。'
                      : 'You got everyone. Try again after a few days to see what really stuck.'),
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
            if (due > 0) ...[
              const SizedBox(height: 8),
              Text(m.ja ? '🔁 復習の予定: $due人' : '🔁 Due for review: $due',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w900)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(m.ja ? 'とじる' : 'Close'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    return Scaffold(
      bottomNavigationBar: const BannerAdSlot(placement: 'study'),
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
            // 📊 名前を見た＝この人に会った。あとの確認テストが定着率の対象になる。
            if (!_revealed) _recordMeeting();
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
                  _revealed ? _current.name
                      : (MetaStrings.of(context).ja
                          ? 'タップで名前をひょうじ'
                          : 'Tap to reveal name'),
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
