import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/meta_strings.dart';
import '../models/person.dart';
import '../models/surnames.dart';
import '../services/app_analytics.dart';
import '../services/bgm.dart';
import '../services/memory_stats.dart';
import '../services/online_match_service.dart';
import '../services/player_profile.dart';
import '../services/sfx.dart';
import '../widgets/banner_ad_slot.dart';
import '../widgets/face_view.dart';
import 'match_game_screen.dart' show PlatformDispatcherLocale;
import 'online_result_screen.dart';
import 'rulebook_screen.dart';

/// 🏆 ランクマッチ（知らない人との早押し勝負）。
///
/// フレンドマッチと違って、相手と話せない・条件を相談できないことを前提にする。
/// だから設定は一切選ばせず、**8人・苗字100から配布・4択**に固定してある。
///
/// 進行は「ロックステップ早押し」:
/// 1. おぼえタイム（両端末で同じ締切）で8人ぶんの顔と名前を見る
/// 2. 部屋の `cardIndex` が示す問題を**両者に同時に**出す
/// 3. 正解を押したら [OnlineMatchSession.claimCard] で先取を宣言する。
///    先にサーバーへ届いた方だけが true を受け取り、そのカードを取る
/// 4. 誰も取れないまま制限時間が過ぎたら [OnlineMatchSession.passCard] で次へ
///
/// 「どちらが先か」をクライアント同士で決めることはできないので、
/// 部屋ドキュメントのトランザクションを唯一の審判にしている。
/// 盤面（顔ぶれ・名前・選択肢・出題順）は共有seedから両端末が同じものを
/// 組み立てるため、Firestoreに載せるのは「何問目か」と「誰が取ったか」だけ。
class RankMatchScreen extends StatefulWidget {
  final OnlineMatchSession session;
  const RankMatchScreen({super.key, required this.session});

  @override
  State<RankMatchScreen> createState() => _RankMatchScreenState();
}

/// おぼえタイム → **相手待ち** → 早押し → 終了。
/// 相手待ちを挟むのは、おぼえタイムの締切が端末の時計だよりで、
/// 数秒ずれると片方だけ先に第1問を見てしまうため。
enum _Phase { memorize, readyWait, buzz, finished }

/// 1問ぶん（顔・正解・4択）。両端末で完全に同じものが作られる。
class _Question {
  final Person person;
  final String answer;
  final List<String> choices;
  const _Question(this.person, this.answer, this.choices);
}

class _RankMatchScreenState extends State<RankMatchScreen>
    with WidgetsBindingObserver {
  late final Random _rng = Random(widget.session.seed);
  late final List<Person> _people;
  late final Map<Person, String> _roster;
  late final List<_Question> _questions;

  _Phase _phase = _Phase.memorize;
  int _memorizeLeft = 0;
  Timer? _memorizeTimer;

  /// いま出ている問題番号。部屋の cardIndex をそのまま映す。
  int _index = 0;

  /// この問題でもう答えられない（正解して先取した／まちがえた／取られた）。
  bool _locked = false;
  String? _picked;

  /// 直前の問題の結果表示（先取・とられた・おてつき）。
  String? _flash;

  Timer? _buzzTimer;
  int _timeLeft = OnlineMatchService.rankAnswerSeconds;
  DateTime? _shownAt;
  bool _reported = false;

  Timer? _readyTimeout;
  bool _finished = false;
  DateTime? _leftAt;

  /// 結果表示（先取・とられた・おてつき）を消すタイマー。
  ///
  /// 先取が決まると部屋の問題番号がすぐ進むので、次の問題を出したときに
  /// 消してしまうと結果が一瞬も見えない。少しだけ次の問題にまたがって残す。
  Timer? _flashTimer;

  int get _questionCount => _people.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final ja = PlatformDispatcherLocale.isJa;
    // 🌐 両端末で顔ぶれを一致させる必要があるので、購入キャラもデッキ編集も
    //    混ぜず、誰でも持っている基本の顔だけを使う。
    _people = generateImagePeople(
      OnlineMatchService.rankPeopleCount,
      ja: ja,
      random: _rng,
      // 🌐 オンラインは相手と顔ぶれを合わせる必要があるので言語で変えない
      charAssets: kCharImageAssets,
    );
    // 🏷 名前は実際に多い苗字100から配る。造語だと「実在しそうな名前を
    //    覚える」練習にならないため。重複しないよう先頭から取る。
    final pool = [...kCommonSurnames]..shuffle(_rng);
    _roster = {
      for (var i = 0; i < _people.length; i++)
        _people[i]: surnameWithHonorific(pool[i], ja),
    };
    // 出題順と選択肢もseedから作る（＝相手とまったく同じ問題が同じ順で出る）
    final order = [..._people]..shuffle(_rng);
    _questions = [
      for (final p in order) _buildQuestion(p),
    ];
    // 📊 おぼえタイムで顔と名前を見せる＝「会った」。ここを記録しておくと
    //    このあとの早押しが「2回目」として定着率の対象になる。
    MemoryStats.instance.load().then((_) {
      for (final p in _people) {
        MemoryStats.instance.recordMeeting(
            itemKey: MemoryStats.keyOf(face: p.face, name: _roster[p]!));
      }
    }).catchError((_) {});

    _index = widget.session.cardIndex.value;
    widget.session.cardIndex.addListener(_onIndexChanged);
    widget.session.readyCount.addListener(_onReadyChanged);
    widget.session.claims.addListener(_onClaimsChanged);

    _memorizeLeft = OnlineMatchService.memorizeSecondsFor(
        'rank', OnlineMatchService.rankPeopleCount);
    _memorizeTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _tickMemorize());

    AppAnalytics.gameStart(mode: 'rank_match', players: 2);
    Bgm.instance.playGame();
  }

  _Question _buildQuestion(Person target) {
    final correct = _roster[target]!;
    final others = _roster.values.where((n) => n != correct).toList()
      ..shuffle(_rng);
    final choices = <String>[correct, ...others.take(3)]..shuffle(_rng);
    return _Question(target, correct, choices);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!_finished) {
      AppAnalytics.gameExit(
        mode: 'rank_match',
        reason: 'quit',
        progressPct: _progressPct,
        people: _people.length,
      );
    }
    widget.session.cardIndex.removeListener(_onIndexChanged);
    widget.session.claims.removeListener(_onClaimsChanged);
    widget.session.readyCount.removeListener(_onReadyChanged);
    _readyTimeout?.cancel();
    _memorizeTimer?.cancel();
    _buzzTimer?.cancel();
    _flashTimer?.cancel();
    Bgm.instance.stopGame();
    super.dispose();
  }

  int get _progressPct {
    if (_phase == _Phase.memorize) return 0;
    if (_phase == _Phase.readyWait) return 10;
    if (_phase == _Phase.buzz) {
      if (_questionCount == 0) return 50;
      return 10 + _index * 80 ~/ _questionCount;
    }
    return 100;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_finished) return;
    if (state == AppLifecycleState.paused) {
      _leftAt = DateTime.now();
      AppAnalytics.gameBackground(
        mode: 'rank_match',
        progressPct: _progressPct,
        card: _index,
        totalCards: _questionCount,
      );
    } else if (state == AppLifecycleState.resumed && _leftAt != null) {
      AppAnalytics.gameResume(
        mode: 'rank_match',
        awaySeconds: DateTime.now().difference(_leftAt!).inSeconds,
      );
      _leftAt = null;
    }
  }

  /// おぼえタイムを進める。
  ///
  /// ⚠️ ここは以前「サーバー時刻(startedAt)＋おぼえ秒数 − 端末の時計」で
  /// 残り秒を計算していた。端末の時計がサーバーより進んでいると
  /// 残り秒が最初からマイナスになり、**名簿が一度も表示されないまま
  /// 早押しが始まる**（報告されたバグ）。時計のずれは端末ごとに違うので、
  /// 片方だけ名簿を見られないという不公平にもなっていた。
  ///
  /// 時計の比較はやめて、**この画面を開いてからの経過**だけで数える。
  /// ふたりのスタートをそろえるのは時計ではなく
  /// [OnlineMatchSession.markReady] の待ち合わせの役目にする。
  void _tickMemorize() {
    if (!mounted || _phase != _Phase.memorize) return;
    setState(() => _memorizeLeft -= 1);
    if (_memorizeLeft <= 0) {
      _memorizeTimer?.cancel();
      setState(() => _phase = _Phase.readyWait);
      widget.session.markReady();
      // 相手が落ちている場合に永久に待たないための保険
      _readyTimeout = Timer(const Duration(seconds: 20), _beginBuzz);
      _onReadyChanged(); // 相手が先に準備できていた場合
    }
  }

  /// 両方の「準備できた」がそろったら第1問を出す。
  void _onReadyChanged() {
    if (!mounted || _phase != _Phase.readyWait) return;
    if (widget.session.readyCount.value >= 2) _beginBuzz();
  }

  void _beginBuzz() {
    if (!mounted || _phase != _Phase.readyWait) return;
    _readyTimeout?.cancel();
    setState(() => _phase = _Phase.buzz);
    _startQuestion();
  }

  // ─────────────── 早押し ───────────────

  void _startQuestion() {
    if (!mounted) return;
    if (_index >= _questionCount) {
      _finish();
      return;
    }
    _buzzTimer?.cancel();
    setState(() {
      _locked = false;
      _picked = null;
      _timeLeft = OnlineMatchService.rankAnswerSeconds;
    });
    _shownAt = DateTime.now();
    _buzzTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _timeLeft -= 1);
      if (_timeLeft <= 0) {
        t.cancel();
        // 誰も取れなかった。どちらの端末から送っても結果は同じになる。
        widget.session.passCard(_index);
      }
    });
  }

  /// 部屋の問題番号が進んだ＝この問題は決着した。次の問題へ。
  void _onIndexChanged() {
    final next = widget.session.cardIndex.value;
    if (next == _index || !mounted) return;
    // 決着した問題の結果を知らせる。自分が取ったときは _answer 側で
    // すでに出しているので、ここでは「取られた」「誰も取れなかった」だけ。
    final settled = _claims['$_index'];
    final m = MetaStrings.of(context);
    if (settled == 'none') {
      _showFlash(m.rankNobody);
    } else if (settled != null && settled != widget.session.myUid) {
      _showFlash(m.rankTaken);
    }
    _index = next;
    if (_phase == _Phase.buzz) {
      if (_index >= _questionCount) {
        _finish();
      } else {
        _startQuestion();
      }
    }
  }

  void _showFlash(String text) {
    if (!mounted) return;
    setState(() => _flash = text);
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _flash = null);
    });
  }

  /// 先取の結果が届いたら、いまの問題の表示を更新する。
  void _onClaimsChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Map<String, String> get _claims => widget.session.claims.value;

  int get _myCards =>
      _claims.values.where((v) => v == widget.session.myUid).length;
  int get _oppCards =>
      _claims.values.where((v) => v == widget.session.opponentUid).length;

  Future<void> _answer(String choice) async {
    if (_locked || _phase != _Phase.buzz) return;
    final q = _questions[_index];
    final correct = choice == q.answer;
    final shownAt = _shownAt;
    final reactionMs =
        shownAt == null ? 0 : DateTime.now().difference(shownAt).inMilliseconds;
    setState(() {
      _locked = true; // 正解でも誤答でも、この問題はもう押せない
      _picked = choice;
    });
    MemoryStats.instance.record(
      mode: StatMode.nameCall,
      itemKey: MemoryStats.keyOf(face: q.person.face, name: q.answer),
      correct: correct,
      reactionMs: reactionMs,
    );
    if (!correct) {
      Sfx.instance.wrong();
      HapticFeedback.mediumImpact();
      _showFlash(MetaStrings.of(context).rankMissed);
      return;
    }
    // ⚡ 正解。ここからは「相手より先にサーバーへ届いたか」の勝負。
    final took = await widget.session.claimCard(_index);
    if (!mounted) return;
    final m = MetaStrings.of(context);
    if (took) {
      Sfx.instance.correct();
      HapticFeedback.lightImpact();
      _showFlash(m.rankTook);
    } else {
      Sfx.instance.wrong();
      _showFlash(m.rankTaken);
    }
  }

  Future<void> _finish() async {
    if (_reported) return;
    _reported = true;
    _finished = true;
    _buzzTimer?.cancel();
    setState(() => _phase = _Phase.finished);
    await MemoryStats.instance.finishSession(StatMode.nameCall);
    AppAnalytics.gameEnd(mode: 'rank_match', topScore: _myCards);
    AppAnalytics.gameExit(
      mode: 'rank_match',
      reason: 'completed',
      progressPct: 100,
      people: _people.length,
    );
    await PlayerProfile.instance.addWeeklyLearned(_myCards);
    final elapsedMs = DateTime.now()
        .difference(widget.session.startedAt)
        .inMilliseconds
        .clamp(0, 1 << 30);
    await widget.session.reportDone(
      attempts: _questionCount,
      ms: elapsedMs,
      pairs: _myCards,
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OnlineResultScreen(
          session: widget.session,
          myAttempts: _questionCount,
          myMs: elapsedMs,
          myPairs: _myCards,
          higherPairsWins: true,
          ranked: true,
        ),
      ),
    );
  }

  // ─────────────── UI ───────────────

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmQuit(m);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F7FF),
        bottomNavigationBar: const BannerAdSlot(placement: 'rank_match'),
        appBar: AppBar(
          title: Text(m.rankMatchTitle),
          automaticallyImplyLeading: false,
          actions: [
            const RulebookButton(focus: RuleTopic.rank, onDark: true),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _confirmQuit(m),
            ),
          ],
        ),
        body: SafeArea(
          child: switch (_phase) {
            _Phase.memorize => _memorizeView(m),
            _Phase.readyWait => _readyWaitView(m),
            _Phase.buzz => _buzzView(m),
            _Phase.finished => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }

  Widget _memorizeView(MetaStrings m) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Text(m.rankMemorizeHeader(_people.length),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text('⏳ $_memorizeLeft',
            style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFFE8663C))),
        const SizedBox(height: 2),
        Text(m.rankMemorizeHint,
            style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            crossAxisCount: 4,
            childAspectRatio: 0.72,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (final p in _people)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(child: FaceView(person: p, size: 200, radius: 12)),
                    const SizedBox(height: 3),
                    Text(_roster[p]!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w900)),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _readyWaitView(MetaStrings m) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 18),
          Text(m.rankReadyWait,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(m.rankReadyWaitHint,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buzzView(MetaStrings m) {
    final q = _questions[_index.clamp(0, _questionCount - 1)];
    return Column(
      children: [
        _scoreBar(m),
        const SizedBox(height: 6),
        Text(m.rankQuestionOf(_index + 1, _questionCount),
            style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
        const SizedBox(height: 4),
        // ⏱ 残り時間バー。早押しは「あと何秒か」が一目で分かることが要る。
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _timeLeft / OnlineMatchService.rankAnswerSeconds,
              minHeight: 10,
              backgroundColor: const Color(0xFFE3E9F2),
              valueColor: AlwaysStoppedAnimation(
                _timeLeft <= 3 ? const Color(0xFFE8663C) : const Color(0xFF3A7BD5),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        FaceView(person: q.person, size: 150, radius: 18),
        const SizedBox(height: 6),
        SizedBox(
          height: 24,
          child: Text(
            _flash ?? (_locked ? m.rankWaitingJudge : m.rankBuzzTitle),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            crossAxisCount: 2,
            childAspectRatio: 2.6,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              for (final c in q.choices) _choiceButton(c, q.answer),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _choiceButton(String choice, String answer) {
    final picked = _picked == choice;
    final showTruth = _locked && (picked || choice == answer);
    final color = !showTruth
        ? Colors.white
        : choice == answer
            ? const Color(0xFFD9F5DE)
            : const Color(0xFFFFDDDD);
    return ElevatedButton(
      onPressed: _locked ? null : () => _answer(choice),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: color,
        foregroundColor: const Color(0xFF23405E),
        disabledForegroundColor: const Color(0xFF23405E),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(choice,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
    );
  }

  Widget _scoreBar(MetaStrings m) {
    Widget side(String label, int cards, Color color) => Expanded(
          child: Column(
            children: [
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
              Text('$cards',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            ],
          ),
        );
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          side('😀 ${m.rankMyCards}', _myCards, const Color(0xFF3A7BD5)),
          const Text('VS', style: TextStyle(fontWeight: FontWeight.w900)),
          side('🌐 ${widget.session.opponentName}', _oppCards,
              const Color(0xFF8A5AC2)),
        ],
      ),
    );
  }

  Future<void> _confirmQuit(MetaStrings m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(m.quitTitle),
        content: Text(m.quitOnlineBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(m.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(m.quitGame),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await widget.session.forfeit();
    widget.session.dispose();
    if (mounted) Navigator.pop(context);
  }
}
