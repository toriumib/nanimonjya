import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../l10n/meta_strings.dart';
import '../models/character_catalog.dart';
import '../models/cpu_persona.dart';
import '../models/person.dart';
import '../models/surnames.dart';
import '../services/ad_ids.dart';
import '../services/bgm.dart';
import '../services/app_analytics.dart';
import '../services/memory_stats.dart';
import '../services/online_match_service.dart';
import '../services/player_profile.dart';
import '../services/sfx.dart';
import '../widgets/dog_squad.dart';
import '../widgets/face_view.dart';
import 'local_result_screen.dart';
import 'match_result_screen.dart';
import 'online_result_screen.dart';
import 'home_shell.dart';
import 'training_report_screen.dart';

/// CPU対戦の強さ。CPUの「カード記憶力」と「思考時間」を決める。
enum CpuLevel { easy, normal, hard, oni, god }

/// ペタネームのコアゲーム: 顔カード×名前カードの神経衰弱。
///
/// - おぼえタイム（記銘）: 人物プロフィールを一定時間表示
/// - マッチング（想起）: 裏向きカードから顔と名前の正しいペアを探す
/// - cpuLevel != null → 交互にめくって獲得ペア数を競うCPU対戦
/// - humanPlayers >= 2 → 1台のスマホを回して遊ぶローカル対戦（交互手番）
/// - online != null → 同じ盤面を同時に解く「オンライン同時レース」
/// - いずれでもなければ一人特訓（手数・タイムを計測しレポートへ）
class MatchGameScreen extends StatefulWidget {
  final CpuLevel? cpuLevel;
  final int level; // 1..3 → ペア数 4/6/8
  final bool mnemonicGuide; // 記憶術ガイド（タグ付け誘導）を表示するか
  final int humanPlayers; // ローカル対戦の人数（1なら一人モード）
  final OnlineMatchSession? online; // オンライン同時レースのセッション

  const MatchGameScreen({
    super.key,
    this.cpuLevel,
    this.level = 1,
    this.mnemonicGuide = false,
    this.humanPlayers = 1,
    this.online,
  });

  @override
  State<MatchGameScreen> createState() => _MatchGameScreenState();
}

enum _Phase { memorize, playing, recall, hobbyQuiz, nameReview, finished }

class _CardData {
  final Person person;
  final bool isFace; // true=顔カード, false=名前カード
  bool matched = false;
  bool revealed = false;
  _CardData(this.person, this.isFace);
}

class _MatchGameScreenState extends State<MatchGameScreen>
    with WidgetsBindingObserver {
  // オンライン時は共有seedで両端末に同一の盤面を作る
  late final Random _rng =
      widget.online != null ? Random(widget.online!.seed) : Random();
  late final List<Person> _people;
  late final List<_CardData> _cards;

  _Phase _phase = _Phase.memorize;
  int _memorizeLeft = 0; // 残りおぼえタイム(秒)
  Timer? _memorizeTimer;

  // めくり状態
  int? _firstIndex;
  bool _resolving = false; // ミスマッチ戻し中の連打ガード

  // 手番（CPU対戦: 0=あなた,1=CPU / ローカル対戦: 0..N-1）
  int _turn = 0;
  late final List<int> _pairsWon =
      List.filled(max(2, widget.humanPlayers), 0);

  // CPUの記憶: カードindex → 覚えているか
  final Set<int> _cpuMemory = {};
  Timer? _cpuTimer;

  // 自己記録（あなたの手番のみ計測）
  int _attempts = 0; // 2枚めくった回数
  int _matches = 0; // ペア成立回数
  int _streak = 0;
  int _bestStreak = 0;
  bool _finished = false;
  DateTime? _leftAt;
  final List<int> _decisionTimes = []; // 1枚目→2枚目の判断時間(ms)
  DateTime? _firstFlipAt;
  late final DateTime _startedAt;

  // 🤖 CPUの人格
  late final CpuPersona _cpuPersona;
  String? _cpuQuip; // いま表示している口癖
  int _cpuQuipsSaid = 0;

  // ⚡ CPUリコールバトル: おぼえたあとに顔を1人ずつ出題、名前を当てるレース
  late final int _recallPeople; // 覚える人数（難易度で変わる）
  List<Person> _recallQueue = []; // まだ正解していない人のキュー
  int _recallQueueIdx = 0; // いま出題している人
  List<String> _recallChoices = []; // 現在の選択肢
  int _playerCorrect = 0; // プレイヤーの正解数
  int _cpuCorrect = 0; // CPUの正解数
  final Set<String> _playerDone = {}; // プレイヤーが正解した人のface
  final Set<String> _cpuDone = {}; // CPUが正解した人のface
  bool _recallAnswerLocked = false;
  String? _recallPicked;
  Timer? _cpuRecallTimer;
  DateTime? _recallShownAt;
  final List<int> _recallReactionMs = [];
  int _recallCombo = 0; // 🔥 連続正解
  int _recallBestCombo = 0;
  int _recallSparkleKey = 0; // ✨ 金キラ
  bool _recallVictory = false; // 🏆 勝利演出

  // 🤖 CPUが取ったペア（おさらい用）
  final List<Person> _cpuPairsWon = [];
  final List<Person> _playerPairsWon = [];

  // 趣味クイズ（一人特訓のレベル3以上）
  final List<Person> _quizTargets = [];
  int _quizIndex = 0;
  int _quizCorrect = 0;
  List<String> _quizChoices = [];

  BannerAd? _bannerAd;

  bool get _vsCpu => widget.cpuLevel != null;
  bool get _isOnline => widget.online != null;
  bool get _isLocalMulti => !_vsCpu && !_isOnline && widget.humanPlayers >= 2;
  bool get _isSolo => !_vsCpu && !_isOnline && !_isLocalMulti;
  int get _pairCount => _isOnline
      ? OnlineMatchService.levelPairs
      : switch (widget.level) { 1 => 4, 2 => 6, _ => 8 };

  String get _modeName => _vsCpu
      ? 'cpu_match'
      : _isOnline
          ? 'online_race'
          : _isLocalMulti
              ? 'local_match'
              : 'solo_match';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startedAt = DateTime.now();
    // 🤖 CPU対戦のときは個性ある対戦相手をランダムで選ぶ
    _cpuPersona = pickCpuPersona(
      switch (widget.cpuLevel) {
        CpuLevel.easy => 'easy',
        CpuLevel.normal => 'normal',
        CpuLevel.hard => 'hard',
        CpuLevel.oni => 'oni',
        CpuLevel.god => 'god',
        _ => 'easy',
      },
    );
    final ja = PlatformDispatcherLocale.isJa;
    // ⚡ CPUリコールバトルの人数（難易度で変わる）
    _recallPeople = switch (widget.cpuLevel) {
      CpuLevel.easy => 2,
      CpuLevel.normal => 3,
      CpuLevel.hard => 5,
      CpuLevel.oni => 10,
      CpuLevel.god => 15,
      _ => 3,
    };
    // 🖼 顔はフリー素材の実写にする
    final totalPeople = _vsCpu ? _recallPeople : _pairCount;
    _people = generatePeople(
      totalPeople,
      ja: ja,
      random: _rng,
      charAssets: _isOnline
          ? kCharImageAssets
          : applyDeckFilter(
              [
                ...kCharImageAssets,
                ...unlockedExtraAssets(
                    PlayerProfile.instance.unlockedCharacters),
              ],
              PlayerProfile.instance.deckExcluded,
            ),
    );
    _cards = _vsCpu
        ? []
        : [
            for (final p in _people) ...[_CardData(p, true), _CardData(p, false)],
          ]..shuffle(_rng);
    // 📊 おぼえタイムで顔と名前を見せる＝「会った」。ここを記録しておくと、
    // このあとのペア当てが「2回目」として定着率の対象になる。
    if (_vsCpu) {
      MemoryStats.instance.load().then((_) {
        for (final p in _people) {
          MemoryStats.instance
              .recordMeeting(itemKey: MemoryStats.keyOf(face: p.face, name: p.name));
        }
      }).catchError((_) {}); // SharedPreferences の読み取り失敗は握りつぶして続行
    }
    if (_isOnline) {
      // 両端末で共通の締切（サーバー時刻基準）からおぼえタイムを計算
      _tickOnlineMemorize();
      _memorizeTimer = Timer.periodic(
          const Duration(milliseconds: 500), (_) => _tickOnlineMemorize());
    } else {
      // おぼえタイム: 難しいほど短い（鬼は一瞬で覚えきれないプレッシャー）
      _memorizeLeft = _vsCpu
          ? switch (widget.cpuLevel!) {
              CpuLevel.easy => 12,
              CpuLevel.normal => 9,
              CpuLevel.hard => 6,
              CpuLevel.oni => 4,
              CpuLevel.god => 2,
            }
          : _pairCount * 3 + (widget.mnemonicGuide ? 6 : 0);
      _memorizeTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) { t.cancel(); return; }
        setState(() => _memorizeLeft -= 1);
        if (_memorizeLeft <= 0) {
          if (_vsCpu) _startCpuRecall(); else _startPlaying();
        }
      });
    }
    AppAnalytics.gameStart(
      mode: _modeName,
      players: _vsCpu || _isOnline ? 2 : widget.humanPlayers,
    );
    _loadBanner();
    Bgm.instance.playGame(); // 🎵 Android/Web どちらでも鳴る
  }

  /// オンライン同時レースのおぼえタイム。
  ///
  /// 締切はサーバー時刻(startedAt)基準だが、残り秒の計算に使う「いま」は
  /// 端末の時計なので、時計がずれているとおぼえタイムが飛ぶ。
  /// （ランクマッチで「名簿が一度も出ない」として実際に報告された）
  /// 残りがありえない値のときは時計を信用せず、その場から自前で数える。
  void _tickOnlineMemorize() {
    if (!mounted) return;
    final full = OnlineMatchService.memorizeSecondsFor(
        widget.online!.game, widget.online!.peopleCount);
    final left =
        widget.online!.playStartAt.difference(DateTime.now()).inSeconds;
    if (left > full || (left <= 0 && _memorizeLeft == 0 && !_clockChecked)) {
      // 時計がずれている端末。共通締切をあきらめ、ローカルで数え直す。
      _clockChecked = true;
      _memorizeTimer?.cancel();
      setState(() => _memorizeLeft = full);
      _memorizeTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() => _memorizeLeft -= 1);
        if (_memorizeLeft <= 0) _startPlaying();
      });
      return;
    }
    _clockChecked = true;
    setState(() => _memorizeLeft = left.clamp(0, 9999));
    if (left <= 0) _startPlaying();
  }

  /// 端末の時計が信用できるか、最初の1回で判定したか。
  bool _clockChecked = false;

  void _loadBanner() {
    if (kIsWeb) return;
    // 💳 広告除去を買ってくれた人にはバナーを出さない
    if (PlayerProfile.instance.adsRemoved) return;
    final ad = BannerAd(
      adUnitId: AdIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, _) => ad.dispose(),
        onAdLoaded: (_) {
          if (mounted) setState(() {});
        },
      ),
    );
    ad.load();
    _bannerAd = ad;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!_finished) {
      AppAnalytics.gameExit(
        mode: _modeName,
        reason: 'quit',
        progressPct: _progressPct,
        people: _people.length,
      );
    }
    _memorizeTimer?.cancel();
    _cpuTimer?.cancel();
    _bannerAd?.dispose();
    Bgm.instance.stopGame();
    super.dispose();
  }

  int get _progressPct {
    if (_phase == _Phase.memorize) return 0;
    if (_vsCpu && _phase == _Phase.recall) {
      final done = _playerCorrect + _cpuCorrect;
      return _recallPeople == 0 ? 0 : done * 100 ~/ (_recallPeople * 2);
    }
    if (_phase == _Phase.nameReview || _phase == _Phase.finished) return 100;
    final matched = _cards.where((c) => c.matched).length;
    return _cards.isEmpty ? 0 : matched * 100 ~/ _cards.length;
  }

  int get _currentCard {
    if (_vsCpu) return _playerCorrect + _cpuCorrect;
    return _cards.where((c) => c.matched || c.revealed).length;
  }

  int get _totalCards {
    if (_vsCpu) return _recallPeople * 2;
    return _cards.length;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_finished) return;
    if (state == AppLifecycleState.paused) {
      _leftAt = DateTime.now();
      AppAnalytics.gameBackground(
        mode: _modeName,
        progressPct: _progressPct,
        card: _currentCard,
        totalCards: _totalCards,
      );
    } else if (state == AppLifecycleState.resumed && _leftAt != null) {
      AppAnalytics.gameResume(
        mode: _modeName,
        awaySeconds: DateTime.now().difference(_leftAt!).inSeconds,
      );
      _leftAt = null;
    }
  }

  // ─────────────── フェーズ遷移 ───────────────

  void _startPlaying() {
    _memorizeTimer?.cancel();
    if (_phase != _Phase.memorize) return;
    setState(() => _phase = _Phase.playing);
  }

  void _finishBoard() {
    if (_isSolo && widget.level >= 3) {
      _quizTargets
        ..clear()
        ..addAll(([..._people]..shuffle(_rng)).take(3));
      _quizIndex = 0;
      _quizCorrect = 0;
      _prepareQuizChoices();
      setState(() => _phase = _Phase.hobbyQuiz);
      return;
    }
    if (_vsCpu) {
      // CPUリコールバトルではここは通らない（_finishCpuRecallが使われる）
      setState(() => _phase = _Phase.nameReview);
      return;
    }
    _goToResult();
  }

  // ⚡ CPUリコールバトル — おぼえた顔を1人ずつランダムに出題し名前を当てるレース

  void _startCpuRecall() {
    _memorizeTimer?.cancel();
    _recallQueue = [..._people]..shuffle(_rng);
    _recallQueueIdx = 0;
    _playerCorrect = 0;
    _cpuCorrect = 0;
    _playerDone.clear();
    _cpuDone.clear();
    _recallAnswerLocked = false;
    _recallPicked = null;
    _buildRecallChoices(_recallQueue[0]);
    setState(() => _phase = _Phase.recall);
    _recallShownAt = DateTime.now();
    // CPUが一定間隔で正解していく
    _startCpuRecallTimer();
  }

  void _buildRecallChoices(Person target) {
    final ja = PlatformDispatcherLocale.isJa;
    final answer = target.name;
    // 4択: 正解 + 他の登場人物 + 足りなければ実名プールから補充
    final names = <String>{answer};
    for (final p in _people) {
      names.add(p.name);
    }
    final filler = commonNamePool(ja).map((n) => formatNameForLocale(n, ja));
    for (final n in filler) {
      if (names.length >= 4) break;
      names.add(n);
    }
    final all = [...names]..shuffle(_rng);
    if (all.length > 1 && all.first == answer) {
      final tmp = all[0]; all[0] = all.last; all[all.length - 1] = tmp;
    }
    _recallChoices = all.take(4).toList()..shuffle(_rng);
    if (!_recallChoices.contains(answer)) _recallChoices[_rng.nextInt(4)] = answer;
  }

  void _answerRecall(String choice) {
    if (_recallAnswerLocked || _recallQueue.isEmpty) return;
    _recallAnswerLocked = true;
    final target = _recallQueue[_recallQueueIdx];
    final correct = choice == target.name;
    final shownAt = _recallShownAt;
    if (shownAt != null) {
      _recallReactionMs.add(DateTime.now().difference(shownAt).inMilliseconds);
    }
    if (correct) {
      _playerCorrect += 1;
      _playerDone.add(target.face);
      _playerPairsWon.add(target);
      _recallCombo += 1;
      if (_recallCombo > _recallBestCombo) _recallBestCombo = _recallCombo;
      _recallSparkleKey += 1; // ✨ 金キラ発動
      // 🔥 連続で盛り上げる
      if (_recallCombo >= 5) {
        HapticFeedback.heavyImpact();
        Sfx.instance.get();
      } else if (_recallCombo >= 3) {
        HapticFeedback.mediumImpact();
        Sfx.instance.correct();
      } else {
        HapticFeedback.lightImpact();
        Sfx.instance.correct();
      }
      // 全問正解でクリア → 勝利演出
      if (_playerCorrect >= _recallPeople) _recallVictory = true;
    } else {
      _recallCombo = 0;
      Sfx.instance.wrong();
      HapticFeedback.mediumImpact();
    }
    _recallPicked = choice;
    _recallQueue.removeAt(_recallQueueIdx);
    setState(() {});

    // 正解も不正解も即次へ（効果音はすでに鳴っている）
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      if (_recallQueue.isEmpty) {
        _finishCpuRecall();
        return;
      }
      final remaining = _recallQueue
          .where((p) => !_playerDone.contains(p.face))
          .toList();
      if (remaining.isEmpty) {
        _finishCpuRecall();
        return;
      }
      _recallQueueIdx = remaining.length > 1
          ? _recallQueue.indexOf(remaining[_rng.nextInt(remaining.length)])
          : _recallQueue.indexOf(remaining.first);
      _recallPicked = null;
      _recallAnswerLocked = false;
      _buildRecallChoices(_recallQueue[_recallQueueIdx]);
      _recallShownAt = DateTime.now();
      if (mounted) setState(() {});
    });
  }

  void _startCpuRecallTimer() {
    final (intervalMs, accuracy, speedMs) = switch (widget.cpuLevel!) {
      CpuLevel.easy => (2800, 0.45, 3200),
      CpuLevel.normal => (2000, 0.60, 2400),
      CpuLevel.hard => (1400, 0.78, 1800),
      CpuLevel.oni => (800, 0.92, 1200),
      CpuLevel.god => (500, 0.98, 800),
    };
    _cpuRecallTimer?.cancel();
    _cpuRecallTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      if (!mounted || _recallQueue.isEmpty) return;
      // CPUがまだ正解してない人からランダムに「思い出す」
      final remaining = _recallQueue
          .where((p) => !_cpuDone.contains(p.face))
          .toList();
      if (remaining.isEmpty) return;
      if (_rng.nextDouble() < accuracy) {
        final picked = remaining[_rng.nextInt(remaining.length)];
        _cpuDone.add(picked.face);
        _cpuCorrect += 1;
        _cpuPairsWon.add(picked);
        _cpuQuip = randomCpuQuip(_cpuPersona, seed: _cpuQuipsSaid);
        _cpuQuipsSaid += 1;
        if (mounted) setState(() {});
        Future.delayed(const Duration(milliseconds: 1800), () {
          if (mounted) setState(() => _cpuQuip = null);
        });
        // CPUが全員終わったら終了
        if (_cpuDone.length >= _recallPeople) {
          _finishCpuRecall();
          return;
        }
      }
    });
  }

  void _finishCpuRecall() {
    _cpuRecallTimer?.cancel();
    // もう出題する人がいない or CPUが全問正解した
    _cpuTimer?.cancel();
    _attempts = _playerCorrect + (_recallPicked != null
        ? _recallQueue.length - _playerCorrect
        : 0);
    _matches = _playerCorrect;
    _pairsWon[0] = _playerCorrect;
    _pairsWon[1] = _cpuCorrect;
    // 古いカード型の変数も埋めておく（_goToResultで使う）
    setState(() => _phase = _Phase.nameReview);
  }

  void _prepareQuizChoices() {
    final ja = PlatformDispatcherLocale.isJa;
    _quizChoices =
        hobbyChoices(_quizTargets[_quizIndex], ja: ja, random: _rng);
  }

  void _answerHobbyQuiz(String choice) {
    final target = _quizTargets[_quizIndex];
    final correct = choice == target.hobby;
    if (correct) {
      _quizCorrect += 1;
      Sfx.instance.correct();
    } else {
      Sfx.instance.wrong();
    }
    if (_quizIndex + 1 < _quizTargets.length) {
      setState(() {
        _quizIndex += 1;
        _prepareQuizChoices();
      });
    } else {
      _goToResult();
    }
  }

  void _goToResult() {
    if (_phase == _Phase.finished) return;
    _finished = true;
    _phase = _Phase.finished;
    _cpuTimer?.cancel();
    if (_vsCpu) MemoryStats.instance.finishSession(StatMode.cpu);
    final avgMs = _decisionTimes.isEmpty
        ? 0
        : _decisionTimes.reduce((a, b) => a + b) ~/ _decisionTimes.length;
    AppAnalytics.gameEnd(
      mode: _modeName,
      topScore: _vsCpu || _isLocalMulti
          ? _pairsWon.reduce(max)
          : _soloScore(avgMs),
    );
    AppAnalytics.gameExit(
      mode: _modeName,
      reason: 'completed',
      progressPct: 100,
      people: _people.length,
    );
    if (_isOnline) {
      final session = widget.online!;
      final elapsedMs = DateTime.now()
          .difference(session.playStartAt)
          .inMilliseconds
          .clamp(0, 1 << 30);
      session.reportDone(
          attempts: _attempts, ms: elapsedMs, pairs: _matches);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OnlineResultScreen(
            session: session,
            myAttempts: _attempts,
            myMs: elapsedMs,
            myPairs: _matches,
          ),
        ),
      );
    } else if (_vsCpu) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MatchResultScreen(
            cpuLevel: widget.cpuLevel!,
            level: widget.level,
            people: _people, // 📇 誰が誰だったかを結果でもう一度見せる

            myPairs: _pairsWon[0],
            cpuPairs: _pairsWon[1],
            attempts: _attempts,
            matches: _matches,
            avgDecisionMs: avgMs,
          ),
        ),
      );
    } else if (_isLocalMulti) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LocalResultScreen(
            pairsWon: List<int>.from(_pairsWon.take(widget.humanPlayers)),
            level: widget.level,
            people: _people, // 📇 誰が誰だったかを結果でもう一度見せる
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TrainingReportScreen(
            cardsNamed: _pairCount,
            correctQuizzes: _matches + _quizCorrect,
            totalQuizzes: _attempts + _quizTargets.length,
            avgReactionMs: avgMs,
            bestStreak: _bestStreak,
            level: widget.level,
            mnemonicGuide: widget.mnemonicGuide,
            score: _soloScore(avgMs),
            people: _people, // 📇 誰が誰だったかを結果でもう一度見せる
          ),
        ),
      );
    }
  }

  /// 一人特訓のスコア: 少ない手数・短い時間ほど高い。
  int _soloScore(int avgMs) {
    final elapsedSec = DateTime.now().difference(_startedAt).inSeconds;
    final movePenalty = (_attempts - _pairCount) * 25;
    final timePenalty = elapsedSec * 2;
    final base = 400 + _pairCount * 100 + _quizCorrect * 50;
    return max(50, base - movePenalty - timePenalty);
  }

  // ─────────────── めくりロジック ───────────────

  void _onCardTap(int index) {
    if (_phase != _Phase.playing || _resolving) return;
    if (_vsCpu && _turn != 0) return; // CPUの手番中は触れない
    final card = _cards[index];
    if (card.matched || card.revealed) return;

    Sfx.instance.pop();
    setState(() => card.revealed = true);
    _cpuGlimpse(index); // CPUもこのカードを見ている（確率で記憶）

    if (_firstIndex == null) {
      _firstIndex = index;
      _firstFlipAt = DateTime.now();
      return;
    }
    // 2枚目
    final first = _cards[_firstIndex!];
    _attempts += 1;
    if (_firstFlipAt != null) {
      _decisionTimes.add(
          DateTime.now().difference(_firstFlipAt!).inMilliseconds);
    }
    _resolvePair(first, card, byCpu: false);
  }

  void _resolvePair(_CardData a, _CardData b, {required bool byCpu}) {
    _firstIndex = null;
    _firstFlipAt = null;
    final isMatch = a.person == b.person && a.isFace != b.isFace;
    // 📊 自分がめくった1手＝「1枚目の人の相方を当てられたか」。CPU対戦だけ記録する。
    if (_vsCpu && !byCpu) {
      MemoryStats.instance.record(
        mode: StatMode.cpu,
        itemKey: MemoryStats.keyOf(face: a.person.face, name: a.person.name),
        correct: isMatch,
        reactionMs: _decisionTimes.isEmpty ? 0 : _decisionTimes.last,
      );
    }
    if (isMatch) {
      _resolving = true;
      // 🤖 CPUが取ったペアを記録（おさらい用）
      if (_vsCpu && byCpu) {
        _cpuPairsWon.add(a.person);
        _cpuQuip = randomCpuQuip(_cpuPersona, seed: _cpuQuipsSaid);
        _cpuQuipsSaid += 1;
      }
      if (_vsCpu && !byCpu) _playerPairsWon.add(a.person);
      Future.delayed(const Duration(milliseconds: 450), () {
        if (!mounted) return;
        setState(() {
          a.matched = true;
          b.matched = true;
          _resolving = false;
          if (_vsCpu) {
            _pairsWon[byCpu ? 1 : 0] += 1;
          } else if (_isLocalMulti) {
            _pairsWon[_turn] += 1;
          }
        });
        if (!byCpu) {
          _matches += 1;
          _streak += 1;
          _bestStreak = max(_bestStreak, _streak);
          Sfx.instance.correct();
          if (_isOnline) widget.online!.reportProgress(_matches);
        } else {
          Sfx.instance.wrong();
          // CPUの口癖を2秒で消す
          Future.delayed(const Duration(milliseconds: 1800), () {
            if (mounted) setState(() => _cpuQuip = null);
          });
        }
        if (_cards.every((c) => c.matched)) {
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) _finishBoard();
          });
        } else if (byCpu) {
          _scheduleCpuMove(); // ペア成立→CPU連続手番
        }
        // 人間のペア成立時は手番継続（何もしない＝そのまま操作可能）
      });
    } else {
      _resolving = true;
      if (!byCpu) _streak = 0;
      Future.delayed(const Duration(milliseconds: 950), () {
        if (!mounted) return;
        setState(() {
          a.revealed = false;
          b.revealed = false;
          _resolving = false;
          if (_vsCpu) {
            _turn = byCpu ? 0 : 1;
          } else if (_isLocalMulti) {
            _turn = (_turn + 1) % widget.humanPlayers; // 次の人へ交代
          }
        });
        if (_vsCpu && !byCpu) _scheduleCpuMove();
      });
    }
  }

  // ─────────────── CPUの頭脳 ───────────────

  /// カードが表になったとき、CPUが確率で位置を記憶する。
  void _cpuGlimpse(int index) {
    if (!_vsCpu) return;
    final chance = switch (widget.cpuLevel!) {
      CpuLevel.easy => 0.35,
      CpuLevel.normal => 0.55,
      CpuLevel.hard => 0.75,
      CpuLevel.oni => 0.92,
      CpuLevel.god => 0.98,
    };
    if (_rng.nextDouble() < chance) _cpuMemory.add(index);
  }

  int get _cpuThinkMs => switch (widget.cpuLevel!) {
        CpuLevel.easy => 1200,
        CpuLevel.normal => 1000,
        CpuLevel.hard => 850,
        CpuLevel.oni => 700,
        CpuLevel.god => 450,
      };

  void _scheduleCpuMove() {
    _cpuTimer?.cancel();
    _cpuTimer = Timer(Duration(milliseconds: _cpuThinkMs + _rng.nextInt(500)),
        _cpuMove);
  }

  void _cpuMove() {
    if (!mounted || _phase != _Phase.playing || _turn != 1) return;

    final hidden = [
      for (var i = 0; i < _cards.length; i++)
        if (!_cards[i].matched && !_cards[i].revealed) i
    ];
    if (hidden.isEmpty) return;

    // 1) 記憶の中に完成ペアがあるか探す
    (int, int)? knownPair;
    final remembered = hidden.where(_cpuMemory.contains).toList();
    for (var i = 0; i < remembered.length && knownPair == null; i++) {
      for (var j = i + 1; j < remembered.length; j++) {
        final a = _cards[remembered[i]], b = _cards[remembered[j]];
        if (a.person == b.person && a.isFace != b.isFace) {
          knownPair = (remembered[i], remembered[j]);
          break;
        }
      }
    }

    int firstPick;
    if (knownPair != null) {
      firstPick = knownPair.$1;
    } else {
      // 覚えていないカードを優先してめくる（情報収集）
      final unknown = hidden.where((i) => !_cpuMemory.contains(i)).toList();
      firstPick = (unknown.isNotEmpty ? unknown : hidden)[
          _rng.nextInt((unknown.isNotEmpty ? unknown : hidden).length)];
    }

    setState(() => _cards[firstPick].revealed = true);
    _cpuMemory.add(firstPick); // 自分でめくったカードは確実に記憶

    // 2枚目は少し間を置いてめくる（人間が見て追える速度）
    _cpuTimer = Timer(Duration(milliseconds: 700 + _rng.nextInt(400)), () {
      if (!mounted || _phase != _Phase.playing) return;
      final hidden2 = [
        for (var i = 0; i < _cards.length; i++)
          if (!_cards[i].matched && !_cards[i].revealed) i
      ];
      if (hidden2.isEmpty) return;

      int secondPick;
      if (knownPair != null) {
        secondPick = knownPair.$2;
      } else {
        // 1枚目の相方を記憶から探す
        final firstCard = _cards[firstPick];
        final partner = hidden2.where((i) {
          if (!_cpuMemory.contains(i)) return false;
          final c = _cards[i];
          return c.person == firstCard.person && c.isFace != firstCard.isFace;
        }).toList();
        if (partner.isNotEmpty) {
          secondPick = partner.first;
        } else {
          secondPick = hidden2[_rng.nextInt(hidden2.length)];
        }
      }
      setState(() => _cards[secondPick].revealed = true);
      _cpuMemory.add(secondPick);
      _resolvePair(_cards[firstPick], _cards[secondPick], byCpu: true);
    });
  }

  // ─────────────── UI ───────────────

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    final canPop = _phase == _Phase.finished;
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmQuit();
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(
          _vsCpu
              ? m.cpuMatchTitle
              : _isOnline
                  ? m.onlineMatchTitle
                  : _isLocalMulti
                      ? m.localMatchTitle
                      : (widget.mnemonicGuide
                          ? m.mnemonicTrainingButton
                          : m.soloTrainingTitle),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _confirmQuit,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: switch (_phase) {
                _Phase.memorize => _buildMemorize(m),
                _Phase.recall => _buildCpuRecall(m),
                _Phase.hobbyQuiz => _buildHobbyQuiz(m),
                _Phase.nameReview => _buildNameReview(m),
                _ => _buildBoard(m),
              },
            ),
            const DogSquad(),
            if (_bannerAd != null)
              SizedBox(
                height: _bannerAd!.size.height.toDouble(),
                width: _bannerAd!.size.width.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
          ],
        ),
      ),
    ));
  }

  Widget _buildMemorize(MetaStrings m) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // 🤖 CPU対戦の相手表示
          if (_vsCpu) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFE3EE), Color(0xFFD8F0FF)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFF8FC0), width: 1.5),
              ),
              child: Row(
                children: [
                  Text(_cpuPersona.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_cpuPersona.name,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w900,
                                color: Color(0xFFE8663C))),
                        Text('${m.ja ? '趣味' : 'Hobby'}: ${_cpuPersona.hobby}',
                            style: const TextStyle(
                                fontSize: 11.5, color: Color(0xFF6A5A6A))),
                      ],
                    ),
                  ),
                  Icon(
                    switch (widget.cpuLevel!) {
                      CpuLevel.easy => Icons.star_border,
                      CpuLevel.normal => Icons.star_half,
                      CpuLevel.hard => Icons.star,
                      CpuLevel.oni => Icons.whatshot,
                      CpuLevel.god => Icons.bolt,
                    },
                    color: const Color(0xFFE8A400), size: 24),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF3A7BD5), width: 1.5),
            ),
            child: Row(
              children: [
                const Text('👀', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _vsCpu
                        ? (m.ja
                            ? '${_cpuPersona.name}と対戦。顔と名前を覚えてね！'
                            : 'vs ${_cpuPersona.name}. Remember faces & names!')
                        : m.memorizePrompt,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  '$_memorizeLeft',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF3A7BD5)),
                ),
              ],
            ),
          ),
          if (widget.mnemonicGuide) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFC93C)),
              ),
              child: Text(
                '${m.mnemonicGuideStep1}\n${m.mnemonicGuideStep2}',
                style: const TextStyle(fontSize: 12.5, height: 1.5),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _pairCount >= 8 ? 2 : 1,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: _pairCount >= 8 ? 2.4 : 4.6,
              ),
              itemCount: _people.length,
              itemBuilder: (context, i) {
                final p = _people[i];
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD8E4F0)),
                  ),
                  child: Row(
                    children: [
                      FaceView(person: p, size: 44, radius: 8),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w900),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.level >= 3)
                              Text(
                                '🎨 ${p.hobby}',
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF6A7A8A)),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (!_isOnline) // オンラインは共通締切で同時スタート（早抜け不可）
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _vsCpu ? _startCpuRecall : _startPlaying,
                child: Text(m.memorizeDone),
              ),
            ),
        ],
      ),
    );
  }

  // 🤖 CPU対戦後の名前おさらい
  Widget _buildNameReview(MetaStrings m) {
    final won = _pairsWon[0] >= _pairsWon[1];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Column(
        children: [
          // 勝敗 + CPUリアクション
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: won
                    ? const [Color(0xFFFFC02E), Color(0xFFFF6A3D)]
                    : const [Color(0xFF8A5AC2), Color(0xFF5A3A8E)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Text(_cpuPersona.emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        won
                            ? (m.ja ? 'あなたの勝ち！' : 'You win!')
                            : (m.ja ? '${_cpuPersona.name}の勝ち' : '${_cpuPersona.name} wins'),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        won ? _cpuPersona.loseLine : _cpuPersona.winLine,
                        style: const TextStyle(fontSize: 13, color: Color(0xEEFFFFFF), height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            m.ja ? '👀 登場した人をおさらいしよう' : '👀 Let\'s review who appeared',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.2,
              ),
              itemCount: _people.length,
              itemBuilder: (context, i) {
                final p = _people[i];
                final playerWon = _playerPairsWon.any((pp) => pp.face == p.face);
                final cpuWon = _cpuPairsWon.any((pp) => pp.face == p.face);
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: playerWon
                          ? const Color(0xFF2E9E5B)
                          : cpuWon
                              ? const Color(0xFF8A5AC2)
                              : const Color(0xFFD8E4F0),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      FaceView(person: p, size: 46, radius: 10),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w900)),
                            Text(p.hobby,
                                style: const TextStyle(fontSize: 10.5, color: Colors.black54),
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      if (playerWon)
                        const Text('✅', style: TextStyle(fontSize: 16))
                      else if (cpuWon)
                        const Text('🤖', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _goToResult,
            icon: const Text('🪙', style: TextStyle(fontSize: 16)),
            label: Text(m.ja ? '結果を見る' : 'See results',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3A7BD5),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ⚡ CPUリコールバトルのUI — 顔が出て名前を選ぶ
  Widget _buildCpuRecall(MetaStrings m) {
    if (_recallQueue.isEmpty) return const SizedBox.shrink();
    final person = _recallQueue[_recallQueueIdx];
    final answered = _recallPicked != null;
    final correct = answered && _playerDone.contains(person.face);
    final total = _recallPeople;
    final hotCombo = _recallCombo >= 3; // 🔥 3連続から熱く

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Column(
            children: [
              // スコアバー
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A7BD5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('😀 ${m.you}',
                                  style: const TextStyle(fontSize: 10, color: Color(0xCCFFFFFF))),
                              if (_recallCombo >= 2)
                                TweenAnimationBuilder<double>(
                                  key: ValueKey('combo$_recallCombo'),
                                  tween: Tween(begin: 0.4, end: 1),
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.elasticOut,
                                  builder: (_, v, child) =>
                                      Transform.scale(scale: v, child: child),
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      gradient: hotCombo
                                          ? const LinearGradient(colors: [
                                              Color(0xFFFF6A3D),
                                              Color(0xFFFFC02E)
                                            ])
                                          : const LinearGradient(colors: [
                                              Color(0xFF62B6FF),
                                              Color(0xFF7BE0C8)
                                            ]),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      hotCombo ? '🔥$_recallCombo' : '$_recallCombo',
                                      style: const TextStyle(
                                          fontFamily: 'DelaGothicOne',
                                          fontSize: 11,
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Text('$_playerCorrect / $total',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8A5AC2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                  child: Column(
                    children: [
                      Text('${_cpuPersona.emoji} ${_cpuPersona.name}',
                          style: const TextStyle(fontSize: 10, color: Color(0xCCFFFFFF))),
                      Text('$_cpuCorrect / $total',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 顔カード
          Expanded(
            flex: 3,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  key: ValueKey(person.face),
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
                    boxShadow: [
                      BoxShadow(
                        color: answered && correct
                            ? const Color(0xFF2E9E5B).withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.08),
                        blurRadius: answered && correct ? 20 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaceView(person: person, size: 200, radius: 16),
                      const SizedBox(height: 12),
                      if (answered)
                        Text(
                          correct ? person.name : '？',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: correct ? const Color(0xFF2E9E5B) : const Color(0xFFC62828)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 名前選択肢
          Expanded(
            flex: 2,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 3.0,
              ),
              itemCount: _recallChoices.length,
              itemBuilder: (context, i) {
                final choice = _recallChoices[i];
                final isCorrect = choice == person.name;
                Color bg = const Color(0xFF5AD1FF);
                Color fg = const Color(0xFF05070F);
                if (answered) {
                  if (isCorrect) {
                    bg = const Color(0xFF2E9E5B); fg = Colors.white;
                  } else if (choice == _recallPicked) {
                    bg = const Color(0xFFFF7A7A); fg = Colors.white;
                  } else {
                    bg = const Color(0xFF44506B); fg = const Color(0xFF8899BB);
                  }
                }
                return ElevatedButton(
                  onPressed: answered ? null : () => _answerRecall(choice),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bg,
                    foregroundColor: fg,
                    disabledBackgroundColor: bg,
                    disabledForegroundColor: fg,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                  child: Text(choice, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                );
              },
            ),
          ),
        ],
      ),
    ),
    // ✨ 正解時に金キラ
    if (_recallSparkleKey > 0)
      Positioned.fill(
        child: IgnorePointer(
          key: ValueKey('sparkle$_recallSparkleKey'),
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, t, child) => Opacity(
                opacity: (1 - t).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.5 + t * 2.0,
                  child: child,
                ),
              ),
              child: Container(
                width: 140, height: 140,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x55FFD700),
                      Color(0x33FFC02E),
                      Color(0x00FFA500),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    // 🏆 全問正解で紙吹雪
    if (_recallVictory)
      Positioned.fill(
        child: IgnorePointer(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1500),
            builder: (_, t, child) {
              return Opacity(
                opacity: (1 - t).clamp(0.0, 1.0),
                child: child,
              );
            },
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Color(0x44FFD700),
                    Color(0x22FFC02E),
                    Color(0x00FFFFFF),
                  ],
                ),
              ),
              child: const Center(
                child: Text('🔥 PERFECT! 🔥',
                    style: TextStyle(
                      fontFamily: 'DelaGothicOne',
                      fontSize: 38,
                      color: Color(0xFFFFC02E),
                      shadows: [
                        Shadow(offset: Offset(0, 3), blurRadius: 6, color: Color(0xAA000000)),
                        Shadow(offset: Offset(0, 0), blurRadius: 20, color: Color(0x88FFD700)),
                      ],
                    )),
              ),
            ),
          ),
        ),
      ),
  ],
);
  }

  Widget _buildBoard(MetaStrings m) {
    const cols = 4;
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              if (_vsCpu)
                _scoreBar(m)
              else if (_isLocalMulti)
                _localBar(m)
              else if (_isOnline)
                _onlineBar(m)
              else
                _soloBar(m),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: _cards.length,
                  itemBuilder: (context, i) => _buildCard(_cards[i], i),
                ),
              ),
            ],
          ),
        ),
        // 🤖 CPUの口癖吹き出し
        if (_vsCpu && _cpuQuip != null)
          Positioned(
            top: 52,
            left: 0, right: 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: _cpuQuip != null ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3D6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8A400)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_cpuPersona.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text('${_cpuPersona.name}「$_cpuQuip」',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900,
                              color: Color(0xFF5A4A1E))),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _scoreBar(MetaStrings m) {
    Widget chip(String label, int score, bool active, Color color) {
      return Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? color : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color, width: 2),
          ),
          child: Column(
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: active ? Colors.white : color)),
              Text('$score',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: active ? Colors.white : color)),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('😀 ${m.you}', _pairsWon[0], _turn == 0, const Color(0xFF3A7BD5)),
        const SizedBox(width: 10),
        chip(
            '${_cpuPersona.emoji} ${_cpuPersona.name}',
            _pairsWon[1],
            _turn == 1,
            const Color(0xFF8A5AC2)),
      ],
    );
  }

  // ローカル対戦: P1〜P4のスコアチップ（手番の人がハイライト）
  Widget _localBar(MetaStrings m) {
    const colors = [
      Color(0xFF3A7BD5),
      Color(0xFFE8663C),
      Color(0xFF2E9E5B),
      Color(0xFF8A5AC2),
    ];
    return Row(
      children: [
        for (var i = 0; i < widget.humanPlayers; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: _turn == i ? colors[i] : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors[i], width: 2),
              ),
              child: Column(
                children: [
                  Text('P${i + 1}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: _turn == i ? Colors.white : colors[i])),
                  Text('${_pairsWon[i]}',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _turn == i ? Colors.white : colors[i])),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // オンライン同時レース: 自分の進捗 vs 相手の進捗（リアルタイム購読）
  Widget _onlineBar(MetaStrings m) {
    Widget chip(String label, int score, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color, width: 2),
          ),
          child: Column(
            children: [
              Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: color)),
              Text('$score/$_pairCount',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: color)),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('😀 ${m.you}', _matches, const Color(0xFF3A7BD5)),
        const SizedBox(width: 10),
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: widget.online!.opponentProgress,
            builder: (context, value, _) => Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF8A5AC2), width: 2),
              ),
              child: Column(
                children: [
                  Text('🌐 ${widget.online!.opponentName}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF8A5AC2))),
                  Text('$value/$_pairCount',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF8A5AC2))),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _soloBar(MetaStrings m) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8E4F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text('🎯 $_matches/$_pairCount',
              style: const TextStyle(fontWeight: FontWeight.w900)),
          Text('👆 ${m.attemptsLabel}: $_attempts',
              style: const TextStyle(fontWeight: FontWeight.w900)),
          Text('🔥 $_streak',
              style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildCard(_CardData card, int index) {
    final faceUp = card.revealed || card.matched;
    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: card.matched ? 0.35 : 1,
        // ★3Dフリップ: 裏→表がY軸回転でめくれる★
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: faceUp ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOutCubic,
          builder: (context, t, _) {
            final angle = t * pi; // 0(裏) → pi(表)
            final showFront = t > 0.5;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012) // 奥行き（パース）
                ..rotateY(angle),
              child: showFront
                  // 表面はさらに180度回して鏡像を打ち消す
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(pi),
                      child: _cardFace(card, true),
                    )
                  : _cardFace(card, false),
            );
          },
        ),
      ),
    );
  }

  /// カードの面（表: 顔or名前 / 裏: タグ柄）。
  Widget _cardFace(_CardData card, bool front) {
    return Container(
      decoration: BoxDecoration(
        color: front
            ? Colors.white
            : (card.matched ? Colors.grey.shade200 : const Color(0xFF3A7BD5)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: front ? const Color(0xFFB8CCE0) : const Color(0xFF2B5CA5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: front
          ? (card.isFace
              ? Padding(
                  padding: const EdgeInsets.all(6),
                  child: FaceView(
                      person: card.person, size: double.infinity, radius: 8),
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        card.person.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ))
          : const Center(
              child: Text('🏷️', style: TextStyle(fontSize: 26)),
            ),
    );
  }

  Widget _buildHobbyQuiz(MetaStrings m) {
    final target = _quizTargets[_quizIndex];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            m.hobbyQuizPrompt,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          FaceView(person: target, size: 110, radius: 14),
          const SizedBox(height: 8),
          Text(
            m.hobbyQuizQuestion(target.name),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          ..._quizChoices.map(
            (c) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _answerHobbyQuiz(c),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF3A7BD5),
                    side: const BorderSide(color: Color(0xFF3A7BD5), width: 2),
                  ),
                  child: Text(c),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${_quizIndex + 1} / ${_quizTargets.length}',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _confirmQuit() {
    final m = MetaStrings.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(m.quitTitle),
        content: Text(m.quitOfflineBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(m.cancel),
          ),
          TextButton(
            onPressed: () {
              if (_isOnline) {
                // 途中離脱は相手の勝ち扱いにしてから抜ける
                widget.online!.forfeit();
                widget.online!.dispose();
              }
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeShell()),
                (route) => false,
              );
            },
            child: Text(m.quitGame),
          ),
        ],
      ),
    );
  }
}

/// ロケール判定ヘルパー（initStateでcontextなしに使うため）。
/// 🌐 Web版の言語切替（PlayerProfile.webLocaleCode）を優先する。
class PlatformDispatcherLocale {
  static bool get isJa {
    final web = PlayerProfile.instance.webLocaleCode;
    if (web != null) return web == 'ja';
    return WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'ja';
  }
}
