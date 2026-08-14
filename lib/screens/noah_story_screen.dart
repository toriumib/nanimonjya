import 'dart:math';

import 'package:flutter/material.dart';

import '../models/noah_save.dart';
import '../models/noah_story.dart';
import '../services/player_profile.dart';
import '../services/noah_save_store.dart';
import '../services/sfx.dart';
import '../widgets/avatar_view.dart';
import '../widgets/banner_ad_slot.dart';

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
  capacity, // 定員四名の宣告と「さよならの手紙」
  whyNames, // なぜ名前なのか（物語の主題）
  beforeMeeting, // 名刺交換の前口上
  meet, // 名刺をもらう
  beforeSleep, // 出発前夜
  awake, // 目覚め
  recall, // 記憶テスト（名前・趣味）
  forgot, // 十七人目の名前を落としていたことに気づく
  date, // デート
  beforeMystery, // 幕間の前口上
  mystery, // 船内の小さな謎（心残りから当てる）
  midVoyage, // 航行中の危機（引き返せなくなる）
  climax, // 減速危機
  consciousness, // 意識の淘汰（量子論が残る）
  note, // 研究にもとづく覚え方のメモ
  finalTest, // 最終テスト（所属・通信ID・学生時代）
  beforeResult, // 着陸準備
  ending,
}

class _NoahStoryScreenState extends State<NoahStoryScreen> {
  final _rng = Random();

  _Phase _phase = _Phase.setup;
  NoahGender _gender = NoahGender.female;
  NoahPreference _pref = NoahPreference.all;

  /// この周回に出てくる科学者。**一周で十六人全員**と会う。
  List<NoahCharacter> _cast = [];

  /// 船内で腰を据えて話す相手。恋愛対象の性別で絞られる（独身なら全員）。
  /// **採択される理論は、ここに入っている人からしか出ない**。
  List<NoahCharacter> _talkable = [];
  final List<NoahCharacter> _met = [];
  final Map<String, int> _affection = {};

  int _index = 0; // 何人目か
  int _line = 0; // 台詞の何行目か
  NoahQuestion? _q;
  String? _picked;

  int _correct = 0;
  int _total = 0;

  /// 🌐 「この人のこの項目は思い出せた」の記録。世界線はこれで決まる。
  /// 好感度（♥）とは別物で、♥は相手を決めるためだけに使う。
  final Map<String, Set<NoahField>> _remembered = {};

  /// 🔍 船内の謎を解けた数。項目には紐づかないので別に数える。
  int _mysterySolved = 0;

  /// 実際に出す問題の総数。
  /// 一人あたり「思い出す」で1問、「最終確認」で1問。それに謎の数を足す。
  /// ⚠️ ここを出題数と揃えていないと 1.000000 に到達できない。
  int get _askable => _cast.length * 2 + _mysteries.length;

  double get _divergence =>
      noahDivergence(_remembered, _askable, extra: _mysterySolved);

  /// 覚え方の話。毎回ちがうものが出るように、周回ごとに選び直す。
  List<NoahNote> _notes = const [];
  int _noteIndex = 0;

  /// 🔍 船内の小さな謎。この周回に出てきた人のぶんだけ出す。
  List<NoahMysteryQuestion> _mysteries = const [];
  int _mysteryIndex = 0;
  NoahCharacter? _mysteryPicked;

  /// 種明かしを読んでいる最中か（答えたあと、もう一度タップで進む）。
  bool get _mysteryAnswered => _mysteryPicked != null;

  /// いま何人まで乗れるか。思い出した数で伸びる。
  int get _capacity => noahCapacityFor(_correct, _total);

  // ── 💾 セーブ ──

  bool _hasSave = false;

  @override
  void initState() {
    super.initState();
    NoahSaveStore.instance.load().then((s) {
      if (mounted) setState(() => _hasSave = s != null);
    });
  }

  /// いまの進行をまるごと書き出す。
  /// ⚠️ 出題中の3択も一緒に保存する。作り直すと引き直せてしまうため。
  NoahSaveData _snapshot() => NoahSaveData(
        phase: _phase.name,
        gender: _gender.name,
        pref: _pref.name,
        castIds: [for (final c in _cast) c.id],
        talkableIds: [for (final c in _talkable) c.id],
        metIds: [for (final c in _met) c.id],
        affection: Map.of(_affection),
        remembered: {
          for (final e in _remembered.entries)
            e.key: [for (final f in e.value) f.name],
        },
        mysterySolved: _mysterySolved,
        index: _index,
        line: _line,
        correct: _correct,
        total: _total,
        noteTitles: [for (final n in _notes) n.title],
        noteIndex: _noteIndex,
        mysteryCulpritIds: [for (final m in _mysteries) m.culprit.id],
        mysteryChoiceIds: [
          for (final m in _mysteries) [for (final c in m.choices) c.id],
        ],
        mysteryIndex: _mysteryIndex,
        mysteryPickedId: _mysteryPicked?.id,
        qTargetId: _q?.target.id,
        qField: _q?.field.name,
        qChoices: _q?.choices ?? const [],
        qPicked: _picked,
      );

  void _persist() {
    if (_phase == _Phase.setup) return;
    NoahSaveStore.instance.save(_snapshot());
  }

  /// セーブから復帰する。読めない項目があっても落ちないようにしてある。
  void _resume(NoahSaveData s) {
    _cast = s.cast();
    if (_cast.isEmpty) return; // 壊れていたら最初から
    _talkable = s.talkable();
    if (_talkable.isEmpty) _talkable = _cast;
    _met
      ..clear()
      ..addAll(s.met());
    _affection
      ..clear()
      ..addAll(s.affection);
    _remembered
      ..clear()
      ..addAll(s.rememberedFields());
    _mysterySolved = s.mysterySolved;
    _index = s.index;
    _line = s.line;
    _correct = s.correct;
    _total = s.total;
    _notes = s.notes();
    _noteIndex = s.noteIndex;
    _mysteries = s.mysteries();
    _mysteryIndex = s.mysteryIndex;
    _mysteryPicked =
        s.mysteryPickedId == null ? null : noahCharacterById(s.mysteryPickedId!);
    _q = s.question();
    _picked = s.qPicked;
    _gender = NoahGender.values
        .firstWhere((g) => g.name == s.gender, orElse: () => _gender);
    _pref = NoahPreference.values
        .firstWhere((p) => p.name == s.pref, orElse: () => _pref);
    _phase = _Phase.values
        .firstWhere((p) => p.name == s.phase, orElse: () => _Phase.prologue);
    // 範囲外に飛ばないよう念のため丸める
    if (_index >= _cast.length) _index = 0;
    if (_noteIndex >= _notes.length) _noteIndex = 0;
    if (_mysteryIndex >= _mysteries.length) _mysteryIndex = 0;
  }

  // ── 進行 ──

  List<NoahLine> get _script => switch (_phase) {
        _Phase.prologue => kNoahPrologue,
        _Phase.capacity => kNoahCapacityScene,
        _Phase.whyNames => kNoahWhyNames,
        _Phase.beforeMeeting => kNoahBeforeMeeting,
        _Phase.beforeSleep => kNoahBeforeSleep,
        _Phase.awake => kNoahAwake,
        _Phase.forgot => kNoahForgot,
        _Phase.beforeMystery => kNoahBeforeMystery,
        _Phase.midVoyage => kNoahMidVoyage,
        _Phase.climax => kNoahClimax,
        _Phase.consciousness => kNoahConsciousness,
        _Phase.beforeResult => kNoahBeforeResult,
        _ => const [],
      };

  void _startGame() {
    // 🧑‍🤝‍🧑 一周で十六人**全員**と名刺を交換し、全員が記憶テストに出る。
    //    腰を据えて話す相手（＝理論が採択されうる相手）だけを _talkable で絞る。
    _cast = [...kNoahCast]..shuffle(_rng);
    _talkable = ([..._pref.filter(_cast)]..shuffle(_rng));
    if (_talkable.isEmpty) _talkable = _cast;
    _affection.clear();
    for (final c in _cast) {
      _affection[c.id] = 0;
    }
    _met.clear();
    _index = 0;
    _line = 0;
    _correct = 0;
    _total = 0;
    _remembered.clear();
    _mysterySolved = 0;
    _notes = ([...kNoahNotes]..shuffle(_rng)).take(3).toList();
    _noteIndex = 0;
    // 謎の手がかりは船内で聞いた心残りなので、話した相手からだけ出す
    _mysteries = buildNoahMysteries(cast: _talkable, random: _rng);
    _mysteryIndex = 0;
    _mysteryPicked = null;
    _phase = _Phase.prologue;
  }

  void _next() {
    Sfx.instance.pop();
    setState(() {
      // 台詞が続く章は、まず1行ずつ送る
      if (_script.isNotEmpty && _line + 1 < _script.length) {
        _line += 1;
        return;
      }
      _line = 0;
      switch (_phase) {
        case _Phase.setup:
          _startGame();
        case _Phase.prologue:
          _phase = _Phase.capacity;
        case _Phase.capacity:
          _phase = _Phase.whyNames;
        case _Phase.whyNames:
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
            // 4人を思い出せた直後に、十七人目を落としていたことが分かる
            _phase = _Phase.forgot;
          }
        case _Phase.forgot:
          _phase = _Phase.note; // 一息いれて、覚え方の話をする
        case _Phase.date:
          if (_index + 1 < _talkable.length) {
            _index += 1;
          } else {
            _index = 0;
            // 心残りを聞き終えたところで謎に入る。手がかりが揃った直後がいい
            _phase = _mysteries.isEmpty
                ? _Phase.midVoyage
                : _Phase.beforeMystery;
          }
        case _Phase.beforeMystery:
          _phase = _Phase.mystery;
          _mysteryIndex = 0;
          _mysteryPicked = null;
        case _Phase.mystery:
          if (_mysteryIndex + 1 < _mysteries.length) {
            _mysteryIndex += 1;
            _mysteryPicked = null;
          } else {
            _mysteryIndex = 0;
            _mysteryPicked = null;
            _phase = _Phase.midVoyage;
          }
        case _Phase.midVoyage:
          _phase = _Phase.climax;
        case _Phase.note:
          if (_noteIndex + 1 < _notes.length) {
            _noteIndex += 1;
          } else {
            _noteIndex = 0;
            _phase = _Phase.date;
          }
        case _Phase.climax:
          // 減速で「止まれた」直後に、意識の決着を置く。
          // 全員が生き延びた実感の上でないと「一度も死んでいない」が効かない
          _phase = _Phase.consciousness;
        case _Phase.consciousness:
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
          // 読み終えた周回のセーブは残さない（結果画面から再開しても意味がない）
          NoahSaveStore.instance.clear();
          _hasSave = false;
        case _Phase.ending:
          // タブの中では閉じられないので、最初から遊べるように戻す
          if (widget.embedded) {
            _phase = _Phase.setup;
          } else {
            Navigator.pop(context);
          }
      }
    });
    _persist();
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
      // どの項目を覚えていたかを記録する（世界線の材料）
      (_remembered[q.target.id] ??= <NoahField>{}).add(q.field);
      Sfx.instance.correct();
    } else {
      Sfx.instance.wrong();
    }
    setState(() => _picked = choice);
    _persist();
  }

  /// 🔍 謎の答え合わせ。
  ///
  /// 記憶テストと同じく、当たれば定員が伸びて相手との距離も縮まる。
  /// デートで聞いた心残りを覚えていたご褒美なので、扱いは正解と同じでいい。
  void _answerMystery(NoahCharacter picked) {
    if (_mysteryPicked != null) return;
    final q = _mysteries[_mysteryIndex];
    _total += 1;
    if (q.isCorrect(picked)) {
      _correct += 1;
      _affection[q.culprit.id] = (_affection[q.culprit.id] ?? 0) + 1;
      // 心残りは項目ではないので別勘定（集合に混ぜると重複で潰れる）
      _mysterySolved += 1;
      Sfx.instance.correct();
    } else {
      Sfx.instance.wrong();
    }
    setState(() => _mysteryPicked = picked);
    _persist();
  }

  Future<void> _grantReward() async {
    // 覚えた数がそのままごほうび。読むだけでは増えない
    await PlayerProfile.instance.grantBonusCoins(20 + _correct * 10);
  }

  NoahResult get _result => _pref.romantic
      ? resolveNoahEnding(_affection,
          divergence: _divergence,
          eligible: {for (final c in _talkable) c.id})
      : resolveNoahSingleEnding(
          remembered: _remembered,
          cast: _cast,
          affection: _affection,
          divergence: _divergence);

  // ── 画面 ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070F),
      bottomNavigationBar: const BannerAdSlot(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFFD7E2FF),
        automaticallyImplyLeading: !widget.embedded,
        title: const Text('🚀 プロジェクト・ノア',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        actions: [
          // 覚えた数がそのまま「助かる人数」になる。ずっと見えていてほしい
          if (_phase != _Phase.setup)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('定員 $_capacity名',
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF7DFFB0))),
                    Text(
                        '${noahWorldLineJa(_divergence)} '
                        '${noahDivergenceLabel(_divergence)}',
                        style: const TextStyle(
                            fontSize: 10,
                            fontFeatures: [FontFeature.tabularFigures()],
                            color: Color(0xFF8FA3C8))),
                  ],
                ),
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
              _Phase.mystery => _mysteryView(),
              _Phase.note => _noteView(),
              _Phase.ending => _ending(),
              _ => _scriptView(),
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
          const Center(
            child: Text('プロジェクト・ノア',
                style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF5AD1FF))),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text('大池町から、四十九光年',
                style: TextStyle(fontSize: 12, color: Color(0xFF8FA3C8))),
          ),
          const SizedBox(height: 22),
          _pickerCard(
            'あなたは',
            [
              for (final g in NoahGender.values)
                _chip(g.labelJa, _gender == g, () => setState(() => _gender = g))
            ],
          ),
          const SizedBox(height: 12),
          _pickerCard(
            '心を寄せる相手は',
            [
              for (final p in NoahPreference.values)
                _chip(p.labelJa, _pref == p, () => setState(() => _pref = p))
            ],
          ),
          const SizedBox(height: 8),
          Text(_pref.noteJa,
              style: const TextStyle(
                  fontSize: 12, height: 1.7, color: Color(0xFF8FA3C8))),
          const SizedBox(height: 18),
          _body(
              '一周で十六人全員と名刺を交換します。見られるのは一度だけ。\n'
              '三百三十年の冷凍睡眠のあと、どれだけ思い出せるかで結末が変わります。\n\n'
              '十六人はそれぞれ「意識の理論」をひとつずつ持っていて、'
              'いちばん覚えていた人の理論が採択され、そのやり方で引っ越しが実現します。',
              size: 13),
          const SizedBox(height: 20),
          _nextButton('はじめる'),
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

  // ── ② 地の文の章 ──

  Widget _scriptView() {
    final lines = _script;
    final shown = lines.take(_line + 1).toList();
    return Column(
      children: [
        Expanded(
          child: ListView(
            reverse: true,
            children: [
              for (final l in shown.reversed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _lineView(l, dim: l != shown.last),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text('${_line + 1} / ${lines.length}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF8FA3C8))),
        const SizedBox(height: 6),
        _nextButton(_line + 1 < lines.length ? '▼ つづき' : 'すすむ'),
      ],
    );
  }

  Widget _lineView(NoahLine l, {bool dim = false}) {
    final alpha = dim ? 0.42 : 1.0;
    return switch (l.voice) {
      NoahVoice.narration =>
        _body(l.text, color: const Color(0xFFA8B6D6).withValues(alpha: alpha)),
      NoahVoice.player => _body('（${_gender.pronounJa}）「${l.text}」',
          color: const Color(0xFF7DFFB0).withValues(alpha: alpha)),
      NoahVoice.director => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.who.isEmpty ? '所長' : l.who,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFFF9A3C).withValues(alpha: alpha))),
            _body('「${l.text}」',
                color: const Color(0xFFD7E2FF).withValues(alpha: alpha)),
          ],
        ),
      NoahVoice.chara => _body('「${l.text}」',
          color: const Color(0xFF5AD1FF).withValues(alpha: alpha)),
    };
  }

  // ── 覚え方の話（研究にもとづく／断定はしない）──

  Widget _noteView() {
    final n = _notes[_noteIndex];
    return ListView(
      children: [
        Text('船内資料 ${_noteIndex + 1} / ${_notes.length}',
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
          child: Text('出典：${n.source}',
              style: const TextStyle(
                  fontSize: 11.5, color: Color(0xFF8FA3C8), height: 1.6)),
        ),
        const SizedBox(height: 20),
        _nextButton(_noteIndex + 1 < _notes.length ? '次の資料' : '船内を歩く'),
      ],
    );
  }

  // ── ③ 名刺をもらう ──

  Widget _meet() {
    final c = _cast[_index];
    return ListView(
      children: [
        Text('名刺交換 ${_index + 1} / ${_cast.length}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF8FA3C8))),
        const SizedBox(height: 12),
        Center(child: _portrait(c, size: 104)),
        const SizedBox(height: 16),
        _businessCard(c),
        const SizedBox(height: 14),
        _body(noahGreetLineJa(c), size: 15),
        const SizedBox(height: 6),
        _body('——名刺は、これきり。次に会うのは三百三十年後。', size: 12.5),
        const SizedBox(height: 18),
        _nextButton(_index + 1 < _cast.length ? '次の人と挨拶する' : '出発の前夜へ'),
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
            _cardRow('通信ID', c.commId),
            _cardRow('趣味', c.hobby),
            _cardRow('学生時代', c.school),
            _cardRow('理論', c.theory),
            const SizedBox(height: 6),
            const Text('箱舟ノア 乗員証',
                style: TextStyle(fontSize: 9.5, color: Color(0xFF8899AD))),
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
    return ListView(
      children: [
        Text('${_phase == _Phase.recall ? '思い出す' : '最終確認'} '
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
        // 💬 相手のほうから話しかけてくる形にする。
        //    「この人の名前は？」だけだと問題集になってしまう。
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: Color(q.target.colorValue).withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: Color(q.target.colorValue).withValues(alpha: 0.5)),
          ),
          child: Text(
            '「${noahAskLineJa(q.target, q.field, _phase == _Phase.recall)}」',
            style: const TextStyle(
                fontSize: 15, height: 1.7, color: Color(0xFFD7E2FF)),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(q.field.questionJa,
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
                ? noahHitLineJa(q.target)
                : noahMissLineJa(q.target, _picked!),
            size: 14,
            color: q.isCorrect(_picked!)
                ? const Color(0xFF7DFFB0)
                : const Color(0xFFFFB4B4),
          ),
          const SizedBox(height: 16),
          _nextButton(_index + 1 < _cast.length
              ? '次の人へ'
              : (_phase == _Phase.recall ? '船内を歩く' : '着陸へ')),
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
    final c = _talkable[_index];
    final d = kNoahDates[(_index + c.id.length) % kNoahDates.length];
    return ListView(
      children: [
        Text('船内 ${_index + 1} / ${_talkable.length}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF8FA3C8))),
        const SizedBox(height: 12),
        Center(child: _portrait(c, size: 100)),
        const SizedBox(height: 14),
        Center(
          child: Text('${d.place}・${c.name}',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Color(c.colorValue))),
        ),
        const SizedBox(height: 16),
        _body(d.flavor, size: 13.5, color: const Color(0xFFA8B6D6)),
        const SizedBox(height: 16),
        _body('「${c.school}にいたころの話、してもいい？」'),
        const SizedBox(height: 10),
        _body('「${c.hobby}は、いまも続けてる。船の中でも」'),
        const SizedBox(height: 10),
        _body('「連絡先、${c.commId}。……もう地球には繋がらないけどね」'),
        const SizedBox(height: 14),
        _body('「${c.regret}。それが、心残り」', size: 14),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF12203C),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
              '💡 ここで聞いた話は、あとで聞かれます。\n'
              '心残りのほうは、船のどこかで見かけることになります。',
              style: TextStyle(
                  fontSize: 12.5, height: 1.6, color: Color(0xFF5AD1FF))),
        ),
        const SizedBox(height: 18),
        _nextButton(_index + 1 < _talkable.length
            ? (_pref.romantic ? '次の人と過ごす' : '次の人と話す')
            : '減速フェーズへ'),
      ],
    );
  }

  // ── ⑥ 船内の小さな謎 ──

  /// 🔍 「この習慣は誰のものか」を当てる。
  ///
  /// 手がかりはデートで聞いた心残りなので、
  /// **話をちゃんと聞いていたか**が問われる。名前の3択とは別の筋の記憶。
  Widget _mysteryView() {
    final q = _mysteries[_mysteryIndex];
    return ListView(
      children: [
        Text('船内の小さな謎 ${_mysteryIndex + 1} / ${_mysteries.length}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF8FA3C8))),
        const SizedBox(height: 14),
        const Center(child: Text('🔍', style: TextStyle(fontSize: 44))),
        const SizedBox(height: 14),
        Center(
          child: Text(q.mystery.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16.5,
                  height: 1.6,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFF9A3C))),
        ),
        const SizedBox(height: 16),
        _body(q.mystery.scene, size: 14, color: const Color(0xFFA8B6D6)),
        const SizedBox(height: 18),
        if (!_mysteryAnswered) ...[
          const Center(
            child: Text('——これは、誰の習慣だろう。',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF5AD1FF))),
          ),
          const SizedBox(height: 14),
          for (final c in q.choices)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _mysteryChoice(c),
            ),
        ] else ...[
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              color: Color(q.culprit.colorValue).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Color(q.culprit.colorValue).withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _portrait(q.culprit, size: 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(q.culprit.name,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(q.culprit.colorValue))),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _body(q.mystery.answer, size: 14),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _body(
            q.isCorrect(_mysteryPicked!)
                ? noahMysteryHitLineJa(q.culprit)
                : noahMysteryMissLineJa(_mysteryPicked!, q.culprit),
            size: 14,
            color: q.isCorrect(_mysteryPicked!)
                ? const Color(0xFF7DFFB0)
                : const Color(0xFFFFB4B4),
          ),
          const SizedBox(height: 18),
          _nextButton(_mysteryIndex + 1 < _mysteries.length
              ? '次の謎へ'
              : '航行をつづける'),
        ],
      ],
    );
  }

  Widget _mysteryChoice(NoahCharacter c) => GestureDetector(
        onTap: () => _answerMystery(c),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1020),
            border: Border.all(color: Color(c.colorValue), width: 1.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _portrait(c, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFD7E2FF))),
                    Text('${c.field}・${c.hobby}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF8FA3C8))),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  // ── ⑦ 結末 ──

  Widget _ending() {
    final r = _result;
    final (title, emoji, text) = switch (r.ending) {
      // 🧠 いちばん親しくなった相手の**理論が採択される**。
      //    16人が別々の理論を持っているので、ここから16通りの結末が生える。
      //    ⚠️ どれも人が死なない書き方を守ること。
      NoahEnding.happy => (
          '${r.partner?.theory ?? ''} 採択',
          '🌅',
          '受精卵カプセル一万個、無事に着床。\n'
              '人類は太陽系の外へ出て、この星で続いていくことになった。\n\n'
              '——そして、意識をどう運ぶかが決まる。\n'
              '採択されたのは、いちばん長く話を聞いた人の理論だった。\n\n'
              '【${r.partner?.theory ?? ''}】\n'
              '${r.partner?.theoryShort ?? ''}\n\n'
              '${r.partner?.uploadEnding ?? ''}\n\n'
              '「${r.partner?.regret ?? ''}」——その心残りを、この星でやり直す。\n\n'
              '「三百三十年、かかったな」\n'
              '「うん。でも、名前は忘れなかった」',
        ),
      NoahEnding.bitter => (
          '大家族エンド',
          '👨‍👩‍👧‍👦',
          '誰のことも、同じくらい覚えていた。\n'
              'だから誰とも、特別にはならなかった。\n\n'
              '十七人で降り、十七人で子どもを育てた。\n'
              '遺伝的多様性はむしろ足りている。'
              '創始者効果を避けるという意味では、計算上いちばん賢い。\n\n'
              '中央広場に椅子を円く並べた。'
              '当番の者がいるので、いつもひとつは空いている。'
              '空いた椅子には、その日の当番の名札を置くことにした。\n'
              'そうすれば、いない人も呼べる。\n\n'
              '——数世代あと。\n'
              '子孫たちが笑って言う。\n'
              '「ねえ、ご先祖さま。みんな顔が同じで、区別つかないんだけど」\n'
              '「それ、褒め言葉だよ」',
        ),
      NoahEnding.trueEnd => (
          '真エンド ─ 世界線 Ω',
          '🌟',
          '転送権は三対。地球で作って積んできたぶんが、全部だ。\n'
              'もつれは局所操作では増やせない。使えば消える。\n'
              'そして移せば、元の身体は必ず壊れる。控えは残らない。\n\n'
              '誰に使うか、という会議が開かれた。\n'
              '候補は出た。だが、どれも要らなかった。\n\n'
              '「十七人、全員生きています」\n'
              '「一度も死んでいない。証明されました」\n'
              '「引っ越す必要のある人が、いま、ひとりもいない」\n\n'
              '三対は封をして、新東戸塚の最初の図書館に納めた。\n'
              '「さよならの手紙」の隣に。\n'
              '札には一行だけ書いた。——「いつか、要る人が来たら」\n\n'
              'それから、名簿をもう一度読んだ。\n'
              '${r.partner?.name ?? ''}の名前も、所属も、趣味も、通信IDも、'
              '学生時代も、心残りも、ぜんぶ言えた。\n\n'
              '——十七人目の名前も。\n\n'
              'あの人の量子状態は、赤色巨星の中で散った。'
              '転送する相手が、もう宇宙のどこにも無い。\n'
              'それでも情報は消えていない。'
              'どこかへ移っただけで、無くなってはいない。\n\n'
              '回収する術は、永遠に無い。\n'
              'だから呼ぶ。届かないと分かっていても、在ることは確かだから。',
        ),
      // 💍 独身ルートの結末。**失敗ではなく、選んで行く場所**。
      //    採択されるのは「いちばんよく覚えていた人」の理論。
      NoahEnding.lonely => (
          '見守りエンド ─ ${r.partner?.theory ?? ''} 採択',
          '🛰️',
          '受精卵カプセル一万個、無事に着床。\n'
              '人類は太陽系の外へ出て、この星で続いていくことになった。\n\n'
              '——誰とも結ばれなかった。選ばなかったからだ。\n'
              'そのかわり、十六人全員の話を最後まで聞いた。\n\n'
              'いちばんよく覚えていたのは、${r.partner?.name ?? ''}だった。\n'
              '名前も、所属も、趣味も、通信IDも、学生時代も、心残りも。\n'
              'だからこの人の理論が採られた。\n\n'
              '【${r.partner?.theory ?? ''}】\n'
              '${r.partner?.theoryShort ?? ''}\n\n'
              '${r.partner?.uploadEnding ?? ''}\n\n'
              '——そして、最初に引っ越したのは自分だった。\n\n'
              '志願者はほかにもいた。だが名簿を全部そらで言えるのは一人しかいない。\n'
              '誰が誰かを取り違えない人間が、最初に行くべきだった。\n\n'
              '体温は返ってこない。手は動く。\n'
              '十六人が眠っているあいだ、船を静かに回し、ポッドを拭き、\n'
              '毎晩ひとつずつ名札を磨いて、名前を声に出した。\n\n'
              '着陸の朝、全員が目を覚ます。\n'
              '「……あなたは？」\n'
              '「呼名官です。おはようございます。全員、そろっています」\n\n'
              '誰も欠けていない。一人も。\n'
              'それを言えるのが、この星でただ一人の自分だった。\n\n'
              'それで、じゅうぶんだった。',
        ),
    };

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
              _statRow('思い出せた', '$_correct / $_total'),
              _statRow('世界線',
                  '${noahWorldLineJa(_divergence)} '
                  '${noahDivergenceLabel(_divergence)}'),
              _statRow('転送権（もつれ対）', '$kNoahEntangledPairs 対'),
              _statRow('乗船できた人数', '$_capacity 名'),
              for (final e in ranked)
                _statRow(noahCharacterById(e.key)?.name ?? e.key,
                    '♥ ${e.value}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text('🪙 ${20 + _correct * 10} コインを受け取りました',
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
            _result.ending == NoahEnding.trueEnd
                ? '世界線 Ω。名前・所属・趣味・通信ID・学生時代・心残り——'
                    '全員ぶんが揃った。転送権を使う理由が、ひとつも無くなった。'
                : _capacity >= kNoahCapacitySteps.last
                ? '全員ぶんの名前が、三百三十年を越えた。'
                    '${kNoahCapacityReasons[3]}のは、'
                    '君が誰ひとり取りこぼさなかったからだ。'
                : '${kNoahCapacityReasons[noahCapacityStepIndex(_correct, _total)]}。'
                    'もっと思い出せれば、もっと多くの人が乗れる。',
            style: const TextStyle(
                fontSize: 12.5, height: 1.7, color: Color(0xFF7DFFB0)),
          ),
        ),
        const SizedBox(height: 20),
        _nextButton(widget.embedded ? 'もう一度あそぶ' : 'とじる'),
      ],
    );
  }

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
