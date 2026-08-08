import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/meta_strings.dart';
import '../models/person.dart';
import '../models/surnames.dart';
import '../services/app_analytics.dart';
import '../services/player_profile.dart';
import '../services/sfx.dart';
import '../widgets/emphasis_text.dart';
import '../widgets/face_view.dart';
import 'home_shell.dart';
import 'match_game_screen.dart' show PlatformDispatcherLocale;

/// このおためしを終えたか。
const String kTutorialPlayedKey = 'tutorialPlayed';

Future<bool> shouldPlayTutorial() async {
  final p = await SharedPreferences.getInstance();
  return !(p.getBool(kTutorialPlayedKey) ?? false);
}

Future<void> markTutorialPlayed() async {
  final p = await SharedPreferences.getInstance();
  await p.setBool(kTutorialPlayedKey, true);
}

/// 🎮 やってみるチュートリアル（読ませずに、やらせて覚えてもらう）。
///
/// **読むだけの説明では初回に離脱する。**
/// ここは「使い方を覚える場所」ではなく、**最初の成功体験を積む場所**。
/// だから絶対に詰まらない作りにしてある:
/// - 押す場所はいつも1つだけ。迷う余地を作らない
/// - 選択肢は2つ。まちがえても終わらず、その場でもう一度できる
/// - 最後は必ず勝って、**コインを受け取って**終わる
///
/// 教えるのは本編の核だけ:
/// ① はじめて出た人には名前をつける（ここでは点は入らない）
/// ② その人がまた出てきたら、名前を呼ぶ
/// ③ 早く正しく呼んだほうが、そのカードをもらえる
class TutorialPlayScreen extends StatefulWidget {
  const TutorialPlayScreen({super.key});

  @override
  State<TutorialPlayScreen> createState() => _TutorialPlayScreenState();
}

enum _Step {
  intro,
  nameFirst,
  nameSecond,
  recall,
  won,
  reward,
}

class _TutorialPlayScreenState extends State<TutorialPlayScreen> {
  static const int _rewardCoins = 100;

  final Random _rng = Random();
  late final List<Person> _people;
  late final List<String> _names;

  _Step _step = _Step.intro;
  String? _picked;
  bool _wrongOnce = false;
  int _cardsWon = 0;
  bool _granted = false;

  @override
  void initState() {
    super.initState();
    final ja = PlatformDispatcherLocale.isJa;
    _people = generateImagePeople(2, ja: ja, random: _rng);
    final pool = [...kCommonSurnames]..shuffle(_rng);
    _names = [
      surnameWithHonorific(pool[0], ja),
      surnameWithHonorific(pool[1], ja),
    ];
    AppAnalytics.gameStart(mode: 'tutorial_play', players: 1);
  }

  void _next(_Step s) {
    Sfx.instance.pop();
    setState(() {
      _step = s;
      _picked = null;
    });
  }

  void _answer(String choice) {
    if (_picked != null) return;
    setState(() => _picked = choice);
    if (choice == _names[0]) {
      Sfx.instance.correct();
      _cardsWon += 1;
      Timer(const Duration(milliseconds: 750), () {
        if (mounted) _next(_Step.won);
      });
      return;
    }
    // まちがえても詰まらせない。その場でもう一度やらせる
    Sfx.instance.wrong();
    _wrongOnce = true;
    Timer(const Duration(milliseconds: 950), () {
      if (mounted) setState(() => _picked = null);
    });
  }

  Future<void> _finish() async {
    if (_granted) return;
    _granted = true;
    await PlayerProfile.instance.grantBonusCoins(_rewardCoins);
    await markTutorialPlayed();
    AppAnalytics.gameEnd(mode: 'tutorial_play', topScore: _cardsWon);
    Sfx.instance.reward();
    if (!mounted) return;
    setState(() => _step = _Step.reward);
  }

  Future<void> _skip() async {
    await markTutorialPlayed();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    return PopScope(
      canPop: _step == _Step.reward,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF9EC),
        appBar: AppBar(
          title: Text(m.tutPlayTitle),
          automaticallyImplyLeading: false,
          actions: [
            if (_step != _Step.reward)
              TextButton(
                onPressed: _skip,
                child: Text(m.tutPlaySkip,
                    style: const TextStyle(color: Colors.white70)),
              ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: switch (_step) {
              _Step.intro => _intro(m),
              _Step.nameFirst => _naming(m, 0, _Step.nameSecond),
              _Step.nameSecond => _naming(m, 1, _Step.recall),
              _Step.recall => _recall(m),
              _Step.won => _won(m),
              _Step.reward => _reward(m),
            },
          ),
        ),
      ),
    );
  }

  Widget _bubble(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3A7BD5), width: 1.6),
        ),
        // ⚠️ 素の Text にすると、文言の `**強調**` が星印のまま画面に出る。
        //    このアプリに Markdown のレンダラは無いので、自前で太字にする。
        child: EmphasisText(text,
            style: const TextStyle(fontSize: 14.5, height: 1.6)),
      );

  Widget _bigButton(String label, VoidCallback onTap, {Color? color}) =>
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? const Color(0xFFE8663C),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle:
                const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900),
          ),
          child: Text(label),
        ),
      );

  Widget _intro(MetaStrings m) => Column(
        children: [
          const Spacer(),
          const Text('🎮', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          _bubble(m.tutPlayIntro),
          const Spacer(),
          _bigButton(m.tutPlayStart, () => _next(_Step.nameFirst)),
        ],
      );

  Widget _naming(MetaStrings m, int index, _Step next) {
    final p = _people[index];
    return Column(
      children: [
        _bubble(index == 0 ? m.tutPlayName1 : m.tutPlayName2),
        const SizedBox(height: 16),
        FaceView(person: p, size: 160, radius: 20),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(_names[index],
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2B5CA5))),
        ),
        const Spacer(),
        _bigButton(m.tutPlayNamed(_names[index]), () => _next(next)),
      ],
    );
  }

  Widget _recall(MetaStrings m) {
    final p = _people[0];
    return Column(
      children: [
        _bubble(_wrongOnce ? m.tutPlayRetry : m.tutPlayRecall),
        const SizedBox(height: 14),
        FaceView(person: p, size: 140, radius: 20),
        const SizedBox(height: 8),
        Text(m.tutPlayFaster,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: Color(0xFFE8663C))),
        const Spacer(),
        for (final n in _names)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _picked == null ? () => _answer(n) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _picked == null
                      ? Colors.white
                      : (n == _names[0]
                          ? const Color(0xFFD9F5DE)
                          : const Color(0xFFFFDDDD)),
                  disabledBackgroundColor: n == _names[0]
                      ? const Color(0xFFD9F5DE)
                      : const Color(0xFFFFDDDD),
                  foregroundColor: const Color(0xFF23405E),
                  disabledForegroundColor: const Color(0xFF23405E),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900),
                ),
                child: Text(n),
              ),
            ),
          ),
      ],
    );
  }

  Widget _won(MetaStrings m) => Column(
        children: [
          const Spacer(),
          const Text('🎉', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          _bubble(m.tutPlayWon(_names[0])),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3D6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE6B54A), width: 1.6),
            ),
            child: Text('🃏 ${m.cardsWonLabel} $_cardsWon',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900)),
          ),
          const Spacer(),
          _bigButton(m.tutPlayGetCoins(_rewardCoins), _finish,
              color: const Color(0xFFE8A400)),
        ],
      );

  Widget _reward(MetaStrings m) => Column(
        children: [
          const Spacer(),
          const Text('🪙', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text(m.earnedCoins(_rewardCoins),
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          _bubble(m.tutPlayDone),
          const Spacer(),
          _bigButton(m.tutPlayToGame, () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeShell()),
              (r) => false,
            );
          }),
        ],
      );
}
