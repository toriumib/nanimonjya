import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/meta_strings.dart';
import '../models/noah_story.dart';
import '../services/player_profile.dart';
import '../services/sfx.dart';
import '../widgets/avatar_view.dart';
import '../widgets/banner_ad_slot.dart';
import '../services/app_analytics.dart';

/// 🚀 ストーリーモード「プロジェクト・ノア」。
///
/// 遊びの芯は本編と同じ「会って、覚えて、思い出す」。
/// 名刺で名前・所属・趣味・通信IDを渡され、
/// 三百三十年の冷凍睡眠のあと、3択で思い出す。
/// **覚えているほど親しくなり、結末が変わる**。
///
/// 立ち絵は後から入れる前提。差し替えるのは [_portrait] の1か所で済む。
class NoahStoryScreen extends StatefulWidget {
  /// 下タブの中に置くときは true（戻る矢印と余白を減らす）。
  final bool embedded;

  const NoahStoryScreen({super.key, this.embedded = false});

  @override
  State<NoahStoryScreen> createState() => _NoahStoryScreenState();
}

enum _Phase {
  setup, // 性別・恋愛対象を選ぶ
  prologue, // 序章
  whyNames, // なぜ名前なのか（物語の主題）
  coldShoulder, // 🥶 無視されるシーン
  physics, // 🌀 量子重力研 — 時空の構造と名前
  beforePhysicsMeet, // 物理チーム名刺前口上
  physicsMeet, // 物理チームの名刺をもらう
  physicsRecall, // 物理チームの名前を思い出す
  beforeMeeting, // 名刺交換の前口上
  meet, // 名刺をもらう
  beforeSleep, // 出発前夜
  awake, // 目覚め
  recall, // 記憶テスト（名前・趣味）
  date, // デート
  climax, // 減速危機
  note, // 研究にもとづく覚え方のメモ
  finalTest, // 最終テスト（所属・通信ID・学生時代）
  beforeResult, // 着陸準備
  ending,
}

class _NoahStoryScreenState extends State<NoahStoryScreen> {
  @override
  void initState() {
    super.initState();
    AppAnalytics.screen('story_noah');
  }

  final _rng = Random();

  _Phase _phase = _Phase.setup;
  NoahGender _gender = NoahGender.female;
  NoahPreference _pref = NoahPreference.all;
  bool _ja = true; // updated each build

  /// この周回に出てくる科学者。4人だと1周が20分ほどで収まる。
  List<NoahCharacter> _cast = [];
  final List<NoahCharacter> _met = [];
  final Map<String, int> _affection = {};

  int _index = 0; // 何人目か
  int _line = 0; // 台詞の何行目か
  NoahQuestion? _q;
  String? _picked;

  int _correct = 0;
  int _total = 0;

  /// 覚え方の話。毎回ちがうものが出るように、周回ごとに選び直す。
  List<NoahNote> _notes = const [];
  int _noteIndex = 0;

  /// いま何人まで乗れるか。思い出した数で伸びる。
  int get _capacity => noahCapacityFor(_correct, _total);

  // ── 進行 ──

  List<NoahLine> get _script => noahStoryLines(_ja, switch (_phase) {
        _Phase.prologue => kNoahPrologue,
        _Phase.whyNames => kNoahWhyNames,
        _Phase.coldShoulder => kNoahColdShoulder,
        _Phase.physics => kNoahPhysics,
        _Phase.beforePhysicsMeet => kNoahBeforePhysicsMeet,
        _Phase.beforeMeeting => kNoahBeforeMeeting,
        _Phase.beforeSleep => kNoahBeforeSleep,
        _Phase.awake => kNoahAwake,
        _Phase.climax => kNoahClimax,
        _Phase.beforeResult => kNoahBeforeResult,
        _ => const [],
      }, switch (_phase) {
        _Phase.prologue => kNoahPrologueEn,
        _Phase.whyNames => kNoahWhyNamesEn,
        _Phase.coldShoulder => kNoahColdShoulderEn,
        _Phase.physics => kNoahPhysicsEn,
        _Phase.beforePhysicsMeet => kNoahBeforePhysicsMeetEn,
        _Phase.beforeMeeting => kNoahBeforeMeetingEn,
        _Phase.beforeSleep => kNoahBeforeSleepEn,
        _Phase.awake => kNoahAwakeEn,
        _Phase.climax => kNoahClimaxEn,
        _Phase.beforeResult => kNoahBeforeResultEn,
        _ => const [],
      });

  void _startGame() {
    final pool = _pref.filter(kNoahCast);
    // 絞りこんだ結果が少なすぎると3択の相手が作れないので、全員から補う
    final base = pool.length >= 4 ? pool : kNoahCast;
    _cast = ([...base]..shuffle(_rng)).take(4).toList();
    _affection.clear();
    for (final c in _cast) {
      _affection[c.id] = 0;
    }
    _met.clear();
    _index = 0;
    _line = 0;
    _correct = 0;
    _total = 0;
    _notes = ([...(_ja ? kNoahNotes : kNoahNotesEn)]..shuffle(_rng)).take(3).toList();
    _noteIndex = 0;
    _phase = _Phase.prologue;
  }

  void _next() {
    Sfx.instance.pop();
    final before = _phase;
    setState(() {
      // 台詞が続く章は、まず1行ずつ送る
      if (_script.isNotEmpty && _line + 1 < _script.length) {
        _line += 1;
        return;
      }
      _line = 0;
      switch (_phase) {
        case _Phase.setup:
          AppAnalytics.storyStart(); // story_progress の分母
          _startGame();
        case _Phase.prologue:
          _phase = _Phase.whyNames;
        case _Phase.whyNames:
          _phase = _Phase.coldShoulder;
        case _Phase.coldShoulder:
          _phase = _Phase.physics;
        case _Phase.physics:
          _phase = _Phase.beforePhysicsMeet;
        case _Phase.beforePhysicsMeet:
          _phase = _Phase.beforeMeeting;
        case _Phase.physicsMeet:
        case _Phase.physicsRecall:
          _phase = _Phase.beforeMeeting;
        case _Phase.beforeMeeting:
          _phase = _Phase.meet;
          _index = 0;
        case _Phase.meet:
          _met.add(_cast[_index]);
          if (_index + 1 < _cast.length) {
            _index += 1;
          } else {
            _index = 0;
            _phase = _Phase.beforeSleep;
          }
        case _Phase.beforeSleep:
          _phase = _Phase.awake;
        case _Phase.awake:
          _phase = _Phase.recall;
          _prepare(const [NoahField.name, NoahField.hobby]);
        case _Phase.recall:
          if (_index + 1 < _cast.length) {
            _index += 1;
            _prepare(const [NoahField.name, NoahField.hobby]);
          } else {
            _index = 0;
            _phase = _Phase.note; // 一息いれて、覚え方の話をする
          }
        case _Phase.date:
          if (_index + 1 < _cast.length) {
            _index += 1;
          } else {
            _index = 0;
            _phase = _Phase.climax;
          }
        case _Phase.note:
          if (_noteIndex + 1 < _notes.length) {
            _noteIndex += 1;
          } else {
            _noteIndex = 0;
            _phase = _Phase.date;
          }
        case _Phase.climax:
          _phase = _Phase.finalTest;
          _prepare(const [
            NoahField.affiliation,
            NoahField.commId,
            NoahField.school,
          ]);
        case _Phase.finalTest:
          if (_index + 1 < _cast.length) {
            _index += 1;
            _prepare(const [
              NoahField.affiliation,
              NoahField.commId,
              NoahField.school,
            ]);
          } else {
            _phase = _Phase.beforeResult;
          }
        case _Phase.beforeResult:
          _phase = _Phase.ending;
          _grantReward();
        case _Phase.ending:
          // タブの中では閉じられないので、最初から遊べるように戻す
          if (widget.embedded) {
            _phase = _Phase.setup;
          } else {
            Navigator.pop(context);
          }
      }
    });
    // 📊 章が変わったときだけ撃つ。1行送るたびに撃つと
    //    イベントが膨れて、どこまで進んだかが逆に読めなくなる。
    if (_phase != before) {
      AppAnalytics.storyProgress(_phase.name);
      if (_phase == _Phase.ending) {
        AppAnalytics.storyEnding(
          ending: _result.ending.name,
          correct: _correct,
          total: _total,
        );
      }
    }
  }

  void _prepare(List<NoahField> fields) {
    _picked = null;
    _q = buildNoahQuestion(
      target: _cast[_index],
      field: fields[_rng.nextInt(fields.length)],
      pool: _met,
      random: _rng,
    );
  }

  void _answer(String choice) {
    if (_picked != null) return;
    final q = _q!;
    final ok = q.isCorrect(choice);
    _total += 1;
    if (ok) {
      _correct += 1;
      // 思い出せたぶんだけ、相手との距離が縮まる
      _affection[q.target.id] = (_affection[q.target.id] ?? 0) + 1;
      Sfx.instance.correct();
    } else {
      Sfx.instance.wrong();
    }
    setState(() => _picked = choice);
  }

  Future<void> _grantReward() async {
    // 覚えた数がそのままごほうび。読むだけでは増えない
    await PlayerProfile.instance.grantBonusCoins(20 + _correct * 10);
  }

  NoahResult get _result => resolveNoahEnding(_affection);

  // ── 画面 ──

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    _ja = m.ja;
    return Scaffold(
      backgroundColor: const Color(0xFF05070F),
      bottomNavigationBar: const BannerAdSlot(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFFD7E2FF),
        automaticallyImplyLeading: !widget.embedded,
        title: Text(_ja ? '🚀 プロジェクト・ノア' : '🚀 Project Noah',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        actions: [
          if (_phase != _Phase.setup)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(
                child: Text(_ja ? '定員 $_capacity名' : 'Capacity: $_capacity',
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF7DFFB0))),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, 1.3),
              radius: 1.1,
              colors: [Color(0xFF2A0D0D), Color(0xFF05070F)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            child: switch (_phase) {
              _Phase.setup => _setup(),
              _Phase.meet => _meet(),
              _Phase.recall || _Phase.finalTest => _quiz(),
              _Phase.date => _date(),
              _Phase.note => _noteView(),
              _Phase.ending => _ending(),
              _ => _advView(m),
            },
          ),
        ),
      ),
    );
  }

  /// 🧑‍🎨 立ち絵。顔メモと同じアバターで描く。
  ///
  /// 専用の絵を8人ぶん用意しなくても、メガネ・ひげ・髪型で見分けがつく。
  /// 描画そのものは AvatarView に任せているので、
  /// 顔の作りを変えたければ models/noah_story.dart の avatar を直せばよい。
  Widget _portrait(NoahCharacter c, {double size = 96}) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Color(c.colorValue), width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Color(c.colorValue).withValues(alpha: 0.35),
              blurRadius: 18,
            ),
          ],
        ),
        child: ClipOval(
          child: AvatarView(
            avatar: c.avatar,
            size: size,
            radius: 0,
          ),
        ),
      );

  Widget _body(String text, {double size = 15, Color? color}) => Text(
        text,
        style: TextStyle(
            fontSize: size,
            height: 1.85,
            color: color ?? const Color(0xFFD7E2FF)),
      );

  Widget _nextButton(String label) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _next,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5AD1FF),
            foregroundColor: const Color(0xFF05070F),
            padding: const EdgeInsets.symmetric(vertical: 15),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          child: Text(label),
        ),
      );

  // ── ① 性別と恋愛対象をえらぶ ──

  Widget _setup() => ListView(
        children: [
          const SizedBox(height: 12),
          const Center(child: Text('🚀', style: TextStyle(fontSize: 56))),
          const SizedBox(height: 8),
          Center(
            child: Text(_ja ? 'プロジェクト・ノア' : 'Project Noah',
                style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF5AD1FF))),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(_ja ? '大池町から、四十九光年' : 'From Oike-cho, 49 light-years away',
                style: const TextStyle(fontSize: 12, color: Color(0xFF8FA3C8))),
          ),
          const SizedBox(height: 22),
          _pickerCard(
            _ja ? 'あなたは' : 'You are',
            [
              for (final g in NoahGender.values)
                _chip(g.label(_ja), _gender == g, () => setState(() => _gender = g))
            ],
          ),
          const SizedBox(height: 12),
          _pickerCard(
            _ja ? '心を寄せる相手は' : 'Interested in',
            [
              for (final p in NoahPreference.values)
                _chip(p.label(_ja), _pref == p, () => setState(() => _pref = p))
            ],
          ),
          const SizedBox(height: 18),
          _body(
              _ja
                  ? '名刺で名前・所属・趣味・通信IDを渡されます。見られるのは一度だけ。\n'
                    '三百三十年の冷凍睡眠のあと、どれだけ思い出せるかで結末が変わります。'
                  : 'You will receive business cards with names, fields, hobbies, and comm IDs. You only get one look.\n'
                    'After 330 years of cryosleep, your fate depends on what you can remember.',
              size: 13),
          const SizedBox(height: 20),
          _nextButton(_ja ? 'はじめる' : 'Begin'),
        ],
      );

  Widget _pickerCard(String title, List<Widget> chips) => Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1020),
          border: Border.all(color: const Color(0xFF1D2A4A)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF5AD1FF))),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: chips),
          ],
        ),
      );

  Widget _chip(String label, bool selected, VoidCallback onTap) => GestureDetector(
        onTap: () {
          Sfx.instance.pop();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF5AD1FF) : Colors.transparent,
            border: Border.all(color: const Color(0xFF5AD1FF), width: 1.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: selected
                      ? const Color(0xFF05070F)
                      : const Color(0xFF5AD1FF))),
        ),
      );

  // ── ADV風テキスト表示 ──

  Widget _advView(MetaStrings m) {
    final lines = _script;
    if (lines.isEmpty) return const SizedBox.shrink();
    final l = lines[_line];
    final isLastLine = _line + 1 >= lines.length;
    final hasChoices = isLastLine && _choicesForPhase.isNotEmpty;

    // 特定の行で選択肢をセット
    if (_phase == _Phase.physics && _line == 66) {
      // 物理学者「さあ…おぼえてもらおうか」のあとの返答
      _choicesForPhase = [
        NoahChoice(text: _ja ? '名刺を見せてください！' : 'Show me your card!', charaId: 'quantum', affectionDelta: 1),
        NoahChoice(text: _ja ? '数式の意味を教えてくれますか？' : 'Can you explain the formula?', charaId: 'quantum', affectionDelta: 2),
        NoahChoice(text: _ja ? '……宇宙を覚えるのは、むずかしい。' : '...Learning the universe is hard.', affectionDelta: 0),
      ];
    }
    if (_phase == _Phase.coldShoulder && _line >= 12 && _line < 15) {
      _choicesForPhase = [
        NoahChoice(text: _ja ? '（もう一度、話しかけてみる）' : '(Try speaking up again)', charaId: 'kiryu', affectionDelta: 1),
        NoahChoice(text: _ja ? '（だまって、周りを見渡す）' : '(Stay silent, look around)', affectionDelta: 0),
      ];
    }

    return Column(
      children: [
        Expanded(child: const SizedBox.shrink()),
        // テキストボックス
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: Container(
            key: ValueKey('line_$_line'),
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 6),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: const Color(0xEE0D1117),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2A3A5A), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 話者名
                if (l.voice == NoahVoice.chara || l.voice == NoahVoice.director)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 8, height: 12,
                          decoration: BoxDecoration(
                            color: l.voice == NoahVoice.director
                                ? const Color(0xFFFF9A3C)
                                : const Color(0xFF5AD1FF),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l.voice == NoahVoice.director
                              ? (l.who.isEmpty
                                  ? (_ja ? '所長' : 'Director')
                                  : l.who)
                              : _speakerName(_line, _ja),
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: l.voice == NoahVoice.director
                                  ? const Color(0xFFFF9A3C)
                                  : const Color(0xFF5AD1FF)),
                        ),
                      ],
                    ),
                  ),
                _body(l.text, size: 15),
              ],
            ),
          ),
        ),
        // 選択肢
        if (hasChoices) ...[
          ..._choicesForPhase.map((c) => Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Sfx.instance.pop();
                      if (c.affectionDelta != 0 && c.charaId != null) {
                        _affection[c.charaId!] =
                            (_affection[c.charaId!] ?? 0) + c.affectionDelta;
                      }
                      setState(() => _choicesForPhase = []);
                      _next();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D2A4A),
                      foregroundColor: const Color(0xFFD0D8E8),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFF334466), width: 1.2),
                      ),
                    ),
                    child: Text(c.text, textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13.5, height: 1.4)),
                  ),
                ),
              )),
        ],
        const SizedBox(height: 4),
        // 進むボタン
        if (!hasChoices)
          GestureDetector(
            onTap: _next,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5AD1FF), Color(0xFF3AA8E8)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    isLastLine
                        ? (_ja ? 'すすむ' : 'Next')
                        : (_ja ? '▼ つづき' : '▼ Continue'),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w900,
                        color: Color(0xFF05070F)),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 選択肢（現在のphaseの最終行に到達したら表示）
  List<NoahChoice> _choicesForPhase = [];

  /// 発言者の名前を返す（キャラのとき）
  String _speakerName(int line, bool ja) {
    // 物理章では文脈から判断
    if (_phase == _Phase.physics) {
      if (line <= 7) return ja ? '所長' : 'Director';
      if (line <= 18 || line == 19 || line >= 60) return ja ? '白髪の博士' : 'The Physicist';
      if (line >= 45 && line <= 55) return ja ? '若い研究員' : 'Young Researcher';
      return ja ? '白髪の博士' : 'The Physicist';
    }
    // 他章では castから文脈で判断 — とりあえずCharacter
    return ja ? '乗員' : 'Crew';
  }

  // ── 覚え方の話（研究にもとづく／断定はしない）──

  Widget _noteView() {
    final n = _notes[_noteIndex];
    return ListView(
      children: [
        Text(_ja ? '船内資料 ${_noteIndex + 1} / ${_notes.length}'
            : 'Ship Library ${_noteIndex + 1} / ${_notes.length}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF8FA3C8))),
        const SizedBox(height: 14),
        const Center(child: Text('🧠', style: TextStyle(fontSize: 48))),
        const SizedBox(height: 14),
        Center(
          child: Text(n.title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFF9A3C))),
        ),
        const SizedBox(height: 16),
        _body(n.body, size: 14.5),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1020),
            border: Border.all(color: const Color(0xFF1D2A4A)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(_ja ? '出典：${n.source}' : 'Source: ${n.source}',
              style: const TextStyle(
                  fontSize: 11.5, color: Color(0xFF8FA3C8), height: 1.6)),
        ),
        const SizedBox(height: 20),
        _nextButton(_noteIndex + 1 < _notes.length
            ? (_ja ? '次の資料' : 'Next document')
            : (_ja ? '船内を歩く' : 'Walk around the ship')),
      ],
    );
  }

  // ── ③ 名刺をもらう ──

  Widget _meet() {
    final c = _cast[_index];
    return ListView(
      children: [
        Text(_ja ? '名刺交換 ${_index + 1} / ${_cast.length}'
            : 'Card Exchange ${_index + 1} / ${_cast.length}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF8FA3C8))),
        const SizedBox(height: 12),
        Center(child: _portrait(c, size: 104)),
        const SizedBox(height: 16),
        _businessCard(c),
        const SizedBox(height: 14),
        _body(noahGreetLine(c, _ja), size: 15),
        const SizedBox(height: 6),
        _body(_ja ? '——名刺は、これきり。次に会うのは三百三十年後。'
            : '—You only get to see this card once. The next time you meet is 330 years from now.',
            size: 12.5),
        const SizedBox(height: 18),
        _nextButton(_index + 1 < _cast.length
            ? (_ja ? '次の人と挨拶する' : 'Greet the next person')
            : (_ja ? '出発の前夜へ' : 'To the night before departure')),
      ],
    );
  }

  /// 📇 名刺。ここに書いてあることが、そのまま後で出題される。
  Widget _businessCard(NoahCharacter c) => Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF7FAFF), Color(0xFFDDE7F5)],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Color(c.colorValue), width: 2),
          boxShadow: const [
            BoxShadow(
                color: Color(0x66000000), blurRadius: 14, offset: Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.field,
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2B5CA5))),
            const SizedBox(height: 6),
            Text(c.reading,
                style: const TextStyle(
                    fontSize: 10.5, color: Color(0xFF6A7A93))),
            Text(c.name,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF10182A),
                    letterSpacing: 2)),
            const SizedBox(height: 10),
            Container(height: 1, color: const Color(0x332B5CA5)),
            const SizedBox(height: 8),
            _cardRow(_ja ? '通信ID' : 'Comm ID', c.commId),
            _cardRow(_ja ? '趣味' : 'Hobby', c.hobby),
            _cardRow(_ja ? '学生時代' : 'School', c.school),
            const SizedBox(height: 6),
            Text(_ja ? '箱舟ノア 乗員証' : 'Ark Noah — Crew ID',
                style: const TextStyle(fontSize: 9.5, color: Color(0xFF8899AD))),
          ],
        ),
      );

  Widget _cardRow(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 62,
              child: Text(k,
                  style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2B5CA5))),
            ),
            Expanded(
              child: Text(v,
                  style: const TextStyle(
                      fontSize: 12.5, color: Color(0xFF10182A))),
            ),
          ],
        ),
      );

  // ── ④ 記憶テスト ──

  Widget _quiz() {
    final q = _q!;
    final answered = _picked != null;
    final isRecall = _phase == _Phase.recall;
    return ListView(
      children: [
        Text('${isRecall ? (_ja ? '思い出す' : 'Recall') : (_ja ? '最終確認' : 'Final Check')} '
            '${_index + 1} / ${_cast.length}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF8FA3C8))),
        const SizedBox(height: 10),
        Center(child: _portrait(q.target, size: 100)),
        const SizedBox(height: 12),
        if (q.field != NoahField.name)
          Center(
            child: Text(q.target.name,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(q.target.colorValue))),
          ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: Color(q.target.colorValue).withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: Color(q.target.colorValue).withValues(alpha: 0.5)),
          ),
          child: Text(
            '"${noahAskLine(q.target, q.field, isRecall, _ja)}"',
            style: const TextStyle(
                fontSize: 15, height: 1.7, color: Color(0xFFD7E2FF)),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(q.field.question(_ja),
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFF9A3C))),
        ),
        const SizedBox(height: 14),
        for (final choice in q.choices)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: answered ? null : () => _answer(choice),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _choiceColor(choice, q, answered),
                  foregroundColor: const Color(0xFF05070F),
                  disabledBackgroundColor: _choiceColor(choice, q, answered),
                  disabledForegroundColor: const Color(0xFF05070F),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w900),
                ),
                child: Text(choice, textAlign: TextAlign.center),
              ),
            ),
          ),
        if (answered) ...[
          const SizedBox(height: 6),
          _body(
            q.isCorrect(_picked!)
                ? noahHitLine(q.target, _ja)
                : noahMissLine(q.target, _picked!, _ja),
            size: 14,
            color: q.isCorrect(_picked!)
                ? const Color(0xFF7DFFB0)
                : const Color(0xFFFFB4B4),
          ),
          const SizedBox(height: 16),
          _nextButton(_index + 1 < _cast.length
              ? (_ja ? '次の人へ' : 'Next person')
              : (_phase == _Phase.recall
                  ? (_ja ? '船内を歩く' : 'Walk around the ship')
                  : (_ja ? '着陸へ' : 'To landing'))),
        ],
      ],
    );
  }

  Color _choiceColor(String choice, NoahQuestion q, bool answered) {
    if (!answered) return const Color(0xFF5AD1FF);
    if (choice == q.answer) return const Color(0xFF7DFFB0);
    if (choice == _picked) return const Color(0xFFFF7A7A);
    return const Color(0xFF44506B);
  }

  // ── ⑤ デート ──

  Widget _date() {
    final c = _cast[_index];
    final dates = _ja ? kNoahDates : kNoahDatesEn;
    final d = dates[(_index + c.id.length) % dates.length];
    return ListView(
      children: [
        Text(_ja ? '船内 ${_index + 1} / ${_cast.length}'
            : 'Aboard ${_index + 1} / ${_cast.length}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF8FA3C8))),
        const SizedBox(height: 12),
        Center(child: _portrait(c, size: 100)),
        const SizedBox(height: 14),
        Center(
          child: Text('${d.place} · ${c.name}',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Color(c.colorValue))),
        ),
        const SizedBox(height: 16),
        _body(d.flavor, size: 13.5, color: const Color(0xFFA8B6D6)),
        const SizedBox(height: 16),
        _body(_ja
            ? '「${c.school}にいたころの話、してもいい？」'
            : '"Do you want to hear about when I was at ${c.school}?"'),
        const SizedBox(height: 10),
        _body(_ja
            ? '「${c.hobby}は、いまも続けてる。船の中でも」'
            : '"I still keep up with ${c.hobby}, even on the ship."'),
        const SizedBox(height: 10),
        _body(_ja
            ? '「連絡先、${c.commId}。……もう地球には繋がらないけどね」'
            : '"My contact is ${c.commId}. …Though it won\'t reach Earth anymore."'),
        const SizedBox(height: 14),
        _body(_ja
            ? '「${c.regret}。それが、心残り」'
            : '"${c.regret}. That\'s my one regret."', size: 14),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF12203C),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(_ja ? '💡 ここで聞いた話は、あとで聞かれます。'
              : '💡 What you learn here will be tested later.',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF5AD1FF))),
        ),
        const SizedBox(height: 18),
        _nextButton(_index + 1 < _cast.length
            ? (_ja ? '次の人と過ごす' : 'Spend time with the next person')
            : (_ja ? '減速フェーズへ' : 'To deceleration phase')),
      ],
    );
  }

  // ── ⑥ 結末 ──

  Widget _ending() {
    final r = _result;
    final (title, emoji, text) = _ja ? _endingTextJa(r) : _endingTextEn(r);

    final ranked = _affection.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      children: [
        Center(child: Text(emoji, style: const TextStyle(fontSize: 60))),
        const SizedBox(height: 8),
        Center(
          child: Text(title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFF9A3C))),
        ),
        const SizedBox(height: 18),
        _body(text),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1020),
            border: Border.all(color: const Color(0xFF1D2A4A)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _statRow(_ja ? '思い出せた' : 'Remembered',
                  '$_correct / $_total'),
              _statRow(_ja ? '乗船できた人数' : 'Carried aboard',
                  _ja ? '$_capacity 名' : '$_capacity'),
              for (final e in ranked)
                _statRow(noahCharacterById(e.key)?.name ?? e.key,
                    '♥ ${e.value}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(_ja
              ? '🪙 ${20 + _correct * 10} コインを受け取りました'
              : '🪙 Received ${20 + _correct * 10} coins',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF7DFFB0))),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFF12203C),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _capacity >= kNoahCapacitySteps.last
                ? (_ja
                    ? '全員ぶんの名前が、三百三十年を越えた。'
                        '${kNoahCapacityReasons[3]}のは、'
                        '君が誰ひとり取りこぼさなかったからだ。'
                    : 'Everyone\'s names made it across 330 years. '
                        '${kNoahCapacityReasons[3]} because you remembered every single one.')
                : (_ja
                    ? '${kNoahCapacityReasons[noahCapacityStepIndex(_correct, _total)]}。'
                        'もっと思い出せれば、もっと多くの人が乗れる。'
                    : '${kNoahCapacityReasons[noahCapacityStepIndex(_correct, _total)]}. '
                        'Remember more names, and more people can come aboard.'),
            style: const TextStyle(
                fontSize: 12.5, height: 1.7, color: Color(0xFF7DFFB0)),
          ),
        ),
        const SizedBox(height: 20),
        _nextButton(widget.embedded
            ? (_ja ? 'もう一度あそぶ' : 'Play again')
            : (_ja ? 'とじる' : 'Close')),
      ],
    );
  }

  (String, String, String) _endingTextJa(NoahResult r) => switch (r.ending) {
    NoahEnding.happy => (
      'ハッピーエンド', '🌅',
      '${r.partner?.name ?? ''}と、ターミネータの浜に降りた。\n'
          '永遠の夕暮れの帯。昼と夜のあいだだけが、ちょうどいい温度をしている。\n\n'
          '「${r.partner?.regret ?? ''}」——その心残りを、この星でやり直す。\n\n'
          'カプセルが開いて、最初の産声が上がる。\n'
          '「三百三十年、かかったな」\n'
          '「うん。でも、名前は忘れなかった」',
    ),
    NoahEnding.harem => (
      '大家族エンド', '👨‍👩‍👧‍👦',
      '一番大切な人が、ひとりに絞れなかった。\n'
          'それでいい、とみんなが言った。\n\n'
          '複数人で降り、みんなで子どもを育てた。\n'
          '遺伝的多様性の確保としても、これは正しい選択だった。\n\n'
          '——数世代あと。\n子孫たちが笑って言う。\n'
          '「ご先祖さまたち、仲良かったんだね」\n'
          '「うん。誰も、独りにしなかった」',
    ),
    NoahEnding.bitter => (
      'ビターエンド（同窓会）', '🌸',
      '誰のことも、同じくらい大切だった。\n'
          'だから誰とも、特別にはならなかった。\n\n'
          '五百人で降り、五百人が家族になった。\n'
          '遺伝的多様性は足りている。計算上は、なんの問題もない。\n\n'
          '——数世代あと。\n子孫たちが、ちょっと恨めしそうに言う。\n'
          '「ねえご先祖さま、みんな顔が似すぎて見分けつかないんだけど」\n'
          '「……それは、ごめん」',
    ),
    NoahEnding.lonely => (
      '孤独エンド', '🛰️',
      '結局、誰の名前も覚えきれなかった。\n\n'
          'だから、世話係を志願した。\n'
          '眠る五百人を起こさないよう、静かに船を回す役。\n\n'
          '意識をロボットへ移す。引越しのようなものだ。\n'
          '体温は返ってこないけれど、手は動く。\n\n'
          '三百三十年、ポッドを拭き続けた。\n'
          '到着の朝、全員が目を覚ます。\n'
          '「……あなたは？」\n'
          '「航行管理です。おはようございます。全員、そろっています」\n\n'
          'それで、じゅうぶんだった。',
    ),
  };

  (String, String, String) _endingTextEn(NoahResult r) => switch (r.ending) {
    NoahEnding.happy => (
      'Happy End', '🌅',
      'You landed on the terminator shore with ${r.partner?.name ?? ''}.\n'
          'The strip of eternal twilight. Only the boundary between day and night has the right temperature.\n\n'
          '"${r.partner?.regret ?? ''}" — you can make it right, here on this planet.\n\n'
          'The capsule opens. The first newborn cry rises.\n'
          '"Three hundred and thirty years. We made it."\n'
          '"Yeah. And I never forgot your name."',
    ),
    NoahEnding.harem => (
      'Big Family End', '👨‍👩‍👧‍👦',
      'You couldn\'t choose just one person.\n'
          'And everyone said: that\'s okay.\n\n'
          'Several of you landed together and raised children as a family.\n'
          'For genetic diversity, this was actually the right call.\n\n'
          '—Generations later.\nTheir descendants laugh and say:\n'
          '"Our ancestors really loved each other, huh?"\n'
          '"Yeah. No one was left alone."',
    ),
    NoahEnding.bitter => (
      'Bitter End (Reunion)', '🌸',
      'Everyone was equally precious to you.\n'
          'So no one became special.\n\n'
          'Five hundred people landed. Five hundred became family.\n'
          'Genetic diversity is covered. Mathematically, there\'s no problem at all.\n\n'
          '—Generations later.\nTheir descendants say, a little reproachfully:\n'
          '"Hey ancestors, all your faces look so similar we can\'t tell you apart."\n'
          '"…Sorry about that."',
    ),
    NoahEnding.lonely => (
      'Solitude End', '🛰️',
      'In the end, you couldn\'t remember anyone\'s name.\n\n'
          'So you volunteered to be the caretaker.\n'
          'The one who keeps the ship running quietly, so the sleeping 500 are not disturbed.\n\n'
          'You transfer your consciousness into a robot. It feels like moving house.\n'
          'The warmth of your body never returns, but your hands still move.\n\n'
          'For 330 years, you wiped down every pod.\n'
          'On the morning of arrival, everyone wakes up.\n'
          '"…Who are you?"\n'
          '"Navigation management. Good morning. Everyone is accounted for."\n\n'
          'That was enough.',
    ),
  };

  Widget _statRow(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(k,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFFD7E2FF))),
            ),
            Text(v,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF5AD1FF))),
          ],
        ),
      );
}
