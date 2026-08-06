import 'dart:math';

import 'package:flutter/material.dart';

import '../models/noah_story.dart';
import '../services/player_profile.dart';
import '../services/sfx.dart';
import '../widgets/banner_ad_slot.dart';

/// 🚀 ストーリーモード「プロジェクト・ノア」。
///
/// 遊びの芯は本編と同じ「会って、覚えて、思い出す」。
/// 名刺交換で名前と所属と趣味を教わり、再会したときに3択で答える。
/// **覚えているほど親しくなり、結末が変わる**。
///
/// ⚠️ 劇中で人は死なない。孤独エンドのマインドアップロードも
/// 「死」ではなく引越しとして書く（船の世話係として全員を見守り続ける）。
///
/// 立ち絵は後から入れる前提で、いまは絵文字を大きく出しているだけ。
/// 差し替えるときは [_portrait] だけ直せば済むようにしてある。
class NoahStoryScreen extends StatefulWidget {
  const NoahStoryScreen({super.key});

  @override
  State<NoahStoryScreen> createState() => _NoahStoryScreenState();
}

enum _Phase { prologue, meet, recall, date, finalTest, ending }

class _NoahStoryScreenState extends State<NoahStoryScreen> {
  final _rng = Random();

  _Phase _phase = _Phase.prologue;

  /// この周回に出てくる科学者（4人）。8人だと1周が長すぎる。
  late List<NoahCharacter> _cast;

  final Map<String, int> _affection = {};

  int _index = 0; // いま何人目か／何問目か
  NoahQuestion? _q;
  String? _picked;

  /// 名刺交換で会った人（3択のまちがい選択肢のもとになる）。
  final List<NoahCharacter> _met = [];

  int _correct = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _cast = ([...kNoahCast]..shuffle(_rng)).take(4).toList();
    for (final c in _cast) {
      _affection[c.id] = 0;
    }
  }

  // ── 進行 ──

  void _next() {
    Sfx.instance.pop();
    setState(() {
      switch (_phase) {
        case _Phase.prologue:
          _phase = _Phase.meet;
          _index = 0;
        case _Phase.meet:
          _met.add(_cast[_index]);
          if (_index + 1 < _cast.length) {
            _index += 1;
          } else {
            _index = 0;
            _phase = _Phase.recall;
            _prepare(const [NoahField.name, NoahField.hobby]);
          }
        case _Phase.recall:
          if (_index + 1 < _cast.length) {
            _index += 1;
            _prepare(const [NoahField.name, NoahField.hobby]);
          } else {
            _index = 0;
            _phase = _Phase.date;
          }
        case _Phase.date:
          if (_index + 1 < _cast.length) {
            _index += 1;
          } else {
            _index = 0;
            _phase = _Phase.finalTest;
            _prepare(const [
              NoahField.affiliation,
              NoahField.commId,
              NoahField.school,
            ]);
          }
        case _Phase.finalTest:
          if (_index + 1 < _cast.length) {
            _index += 1;
            _prepare(const [
              NoahField.affiliation,
              NoahField.commId,
              NoahField.school,
            ]);
          } else {
            _phase = _Phase.ending;
            _grantReward();
          }
        case _Phase.ending:
          Navigator.pop(context);
      }
    });
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
      // 思い出せた項目のぶんだけ、相手との距離が縮まる
      _affection[q.target.id] = (_affection[q.target.id] ?? 0) + 1;
      Sfx.instance.correct();
    } else {
      Sfx.instance.wrong();
    }
    setState(() => _picked = choice);
  }

  Future<void> _grantReward() async {
    // 覚えた数がそのままごほうびになる（読むだけでは増えない）
    final coins = 20 + _correct * 10;
    await PlayerProfile.instance.grantBonusCoins(coins);
  }

  NoahResult get _result => resolveNoahEnding(_affection);

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
        title: const Text('🚀 プロジェクト・ノア',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
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
            padding: const EdgeInsets.all(18),
            child: switch (_phase) {
              _Phase.prologue => _prologue(),
              _Phase.meet => _meet(),
              _Phase.recall || _Phase.finalTest => _quiz(),
              _Phase.date => _date(),
              _Phase.ending => _ending(),
            },
          ),
        ),
      ),
    );
  }

  /// 立ち絵の置き場所。あとで画像に差し替える。
  Widget _portrait(NoahCharacter c, {double size = 96}) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Color(c.colorValue).withValues(alpha: 0.18),
          shape: BoxShape.circle,
          border: Border.all(color: Color(c.colorValue), width: 2),
        ),
        child: Text(c.emoji, style: TextStyle(fontSize: size * 0.45)),
      );

  Widget _body(String text, {double size = 15}) => Text(
        text,
        style: TextStyle(
            fontSize: size, height: 1.8, color: const Color(0xFFD7E2FF)),
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

  Widget _prologue() => ListView(
        children: [
          const SizedBox(height: 20),
          const Text('☀️', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          _body('太陽は赤く、大きくなった。\n'
              '空の三分の一が、燃えている。'),
          const SizedBox(height: 14),
          _body('横浜・戸塚区大池町。かつてゴルフ場だった丘の地下から、'
              '箱舟「ノア」が発つ。行き先は49光年先、LHS 1140 b。'),
          const SizedBox(height: 14),
          _body('片道330年。眠りながら渡る。'),
          const SizedBox(height: 14),
          _body('——ただ、ひとつだけ問題がある。'),
          const SizedBox(height: 8),
          _body('長く眠ると、人の名前から先に、忘れる。', size: 17),
          const SizedBox(height: 24),
          _nextButton('乗船する'),
        ],
      );

  Widget _meet() {
    final c = _cast[_index];
    return ListView(
      children: [
        Text('出会い ${_index + 1} / ${_cast.length}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF8FA3C8))),
        const SizedBox(height: 14),
        Center(child: _portrait(c, size: 120)),
        const SizedBox(height: 18),
        Center(
          child: Text(c.name,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(c.colorValue))),
        ),
        Center(
          child: Text(c.reading,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8FA3C8))),
        ),
        const SizedBox(height: 18),
        _card([
          _row('所属', c.field),
          _row('趣味', c.hobby),
          _row('通信ID', c.commId),
          _row('学生時代', c.school),
        ]),
        const SizedBox(height: 16),
        _body('「${c.name}です。よろしく」\n'
            '——名刺は、一度しか見せてもらえない。'),
        const SizedBox(height: 20),
        _nextButton(_index + 1 < _cast.length ? '次の人に会う' : '冷凍睡眠に入る'),
      ],
    );
  }

  Widget _card(List<Widget> children) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1020),
          border: Border.all(color: const Color(0xFF1D2A4A)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: children),
      );

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 70,
              child: Text(k,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF5AD1FF))),
            ),
            Expanded(
              child: Text(v,
                  style: const TextStyle(
                      fontSize: 13.5, color: Color(0xFFD7E2FF))),
            ),
          ],
        ),
      );

  Widget _quiz() {
    final q = _q!;
    final answered = _picked != null;
    final lead = _phase == _Phase.recall
        ? '——330年後。目が覚めた。'
        : '——減速がはじまる。もう一度だけ、確かめておきたい。';
    return ListView(
      children: [
        Text('${_index + 1} / ${_cast.length}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF8FA3C8))),
        const SizedBox(height: 10),
        _body(lead, size: 13),
        const SizedBox(height: 14),
        Center(child: _portrait(q.target, size: 110)),
        const SizedBox(height: 14),
        if (q.field != NoahField.name)
          Center(
            child: Text(q.target.name,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(q.target.colorValue))),
          ),
        const SizedBox(height: 10),
        Center(
          child: Text(q.field.questionJa,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFF9A3C))),
        ),
        const SizedBox(height: 16),
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
                      fontSize: 15, fontWeight: FontWeight.w900),
                ),
                child: Text(choice, textAlign: TextAlign.center),
              ),
            ),
          ),
        if (answered) ...[
          const SizedBox(height: 6),
          _body(
            q.isCorrect(_picked!)
                ? '「……覚えていてくれたんだ」'
                : '「いえ、それは——たぶん、別の人の話です」',
            size: 14,
          ),
          const SizedBox(height: 16),
          _nextButton(_index + 1 < _cast.length
              ? '次へ'
              : (_phase == _Phase.recall ? 'デートに誘う' : '結末へ')),
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

  /// デートは「思い出す手がかりを増やす場面」。
  /// ここで聞いた話が、そのまま最終テストの出題になる。
  Widget _date() {
    final c = _cast[_index];
    const places = ['百貨店', '人工河川', 'カラオケ', 'フードコート', 'テニスコート', '旧フェアウェイ'];
    final place = places[_index % places.length];
    return ListView(
      children: [
        Text('デート ${_index + 1} / ${_cast.length}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF8FA3C8))),
        const SizedBox(height: 14),
        Center(child: _portrait(c, size: 110)),
        const SizedBox(height: 16),
        Center(
          child: Text('$place・${c.name}',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Color(c.colorValue))),
        ),
        const SizedBox(height: 18),
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
            '💡 ここで聞いた話は、あとで聞かれます。',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF5AD1FF)),
          ),
        ),
        const SizedBox(height: 20),
        _nextButton(_index + 1 < _cast.length ? '次の人と過ごす' : '減速フェーズへ'),
      ],
    );
  }

  Widget _ending() {
    final r = _result;
    final (title, emoji, text) = switch (r.ending) {
      NoahEnding.happy => (
          'ハッピーエンド',
          '🌅',
          '${r.partner?.name ?? ''}と、ターミネータの浜に降りた。\n\n'
              '「${r.partner?.regret ?? ''}」——その心残りを、この星でやり直す。\n\n'
              'カプセルが開いて、最初の産声が上がる。\n'
              '「330年、かかったな」\n'
              '「うん。でも、名前は忘れなかった」',
        ),
      NoahEnding.bitter => (
          'ビターエンド',
          '👨‍👩‍👧‍👦',
          '誰のことも、同じくらい大切だった。\n'
              'だから誰とも、特別にはならなかった。\n\n'
              '500人全員で入植し、全員で子どもを育てた。\n\n'
              '——数世代あと。\n'
              '子孫たちが笑って言う。\n'
              '「ねえ、ご先祖さま。みんな顔が同じで、区別つかないんだけど」\n'
              '「それ、褒め言葉だよ」',
        ),
      NoahEnding.lonely => (
          '孤独エンド',
          '🛰️',
          '結局、誰の名前も覚えきれなかった。\n\n'
              'だから、世話係を志願した。\n'
              '眠る500人を起こさないよう、静かに船を回す役。\n\n'
              '意識をロボットへ移す。死ぬわけじゃない。引越しだ。\n'
              '体温は返ってこないけれど、手は動く。\n\n'
              '330年、ポッドを拭き続けた。\n'
              '到着の朝、全員が目を覚ます。\n'
              '「……あなたは？」\n'
              '「航行管理です。おはようございます。全員、そろっています」\n\n'
              'それで、じゅうぶんだった。',
        ),
    };

    final ranked = _affection.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      children: [
        Center(child: Text(emoji, style: const TextStyle(fontSize: 64))),
        const SizedBox(height: 10),
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
        _card([
          _row('思い出せた', '$_correct / $_total'),
          for (final e in ranked)
            _row(noahCharacterById(e.key)?.name ?? e.key, '♥ ${e.value}'),
        ]),
        const SizedBox(height: 12),
        Center(
          child: Text('🪙 ${20 + _correct * 10} コインを受け取りました',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF7DFFB0))),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text('※ この物語で亡くなる人はいません。',
              style: TextStyle(fontSize: 11, color: Color(0xFF8FA3C8))),
        ),
        const SizedBox(height: 20),
        _nextButton('とじる'),
      ],
    );
  }
}
