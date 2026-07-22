import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:just_audio/just_audio.dart';

import '../l10n/meta_strings.dart';
import '../models/person.dart';
import '../services/ad_ids.dart';
import '../services/app_analytics.dart';
import '../services/online_match_service.dart';
import '../services/player_profile.dart';
import '../services/sfx.dart';
import '../widgets/dog_squad.dart';
import 'local_result_screen.dart';
import 'match_result_screen.dart';
import 'online_result_screen.dart';
import 'home_shell.dart';
import 'training_report_screen.dart';

/// CPU対戦の強さ。CPUの「カード記憶力」と「思考時間」を決める。
enum CpuLevel { easy, normal, hard, oni }

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

enum _Phase { memorize, playing, hobbyQuiz, finished }

class _CardData {
  final Person person;
  final bool isFace; // true=顔カード, false=名前カード
  bool matched = false;
  bool revealed = false;
  _CardData(this.person, this.isFace);
}

class _MatchGameScreenState extends State<MatchGameScreen> {
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
  final List<int> _decisionTimes = []; // 1枚目→2枚目の判断時間(ms)
  DateTime? _firstFlipAt;
  late final DateTime _startedAt;

  // 趣味クイズ（一人特訓のレベル3以上）
  final List<Person> _quizTargets = [];
  int _quizIndex = 0;
  int _quizCorrect = 0;
  List<String> _quizChoices = [];

  BannerAd? _bannerAd;
  final AudioPlayer _bgmPlayer = AudioPlayer();

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
    _startedAt = DateTime.now();
    final ja = PlatformDispatcherLocale.isJa;
    _people = generatePeople(_pairCount, ja: ja, random: _rng);
    _cards = [
      for (final p in _people) ...[_CardData(p, true), _CardData(p, false)],
    ]..shuffle(_rng);
    if (_isOnline) {
      // 両端末で共通の締切（サーバー時刻基準）からおぼえタイムを計算
      _tickOnlineMemorize();
      _memorizeTimer = Timer.periodic(
          const Duration(milliseconds: 500), (_) => _tickOnlineMemorize());
    } else {
      // おぼえタイム: 1ペアあたり3秒 + ガイド時は読み時間を足す
      _memorizeLeft = _pairCount * 3 + (widget.mnemonicGuide ? 6 : 0);
      _memorizeTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        setState(() => _memorizeLeft -= 1);
        if (_memorizeLeft <= 0) _startPlaying();
      });
    }
    AppAnalytics.gameStart(
      mode: _modeName,
      players: _vsCpu || _isOnline ? 2 : widget.humanPlayers,
    );
    _loadBanner();
    _startBgm();
  }

  void _tickOnlineMemorize() {
    if (!mounted) return;
    final left =
        widget.online!.playStartAt.difference(DateTime.now()).inSeconds;
    setState(() => _memorizeLeft = left.clamp(0, 9999));
    if (left <= 0) _startPlaying();
  }

  Future<void> _startBgm() async {
    if (kIsWeb) return; // Webは自動再生制限があるためBGMなし
    try {
      await _bgmPlayer.setAsset(PlayerProfile.instance.selectedBgm);
      await _bgmPlayer.setLoopMode(LoopMode.one);
      await _bgmPlayer.setVolume(0.35);
      _bgmPlayer.play();
    } catch (_) {}
  }

  void _loadBanner() {
    if (kIsWeb) return;
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
    _memorizeTimer?.cancel();
    _cpuTimer?.cancel();
    _bannerAd?.dispose();
    _bgmPlayer.dispose();
    super.dispose();
  }

  // ─────────────── フェーズ遷移 ───────────────

  void _startPlaying() {
    _memorizeTimer?.cancel();
    if (_phase != _Phase.memorize) return;
    setState(() => _phase = _Phase.playing);
  }

  void _finishBoard() {
    // 盤面クリア。一人特訓のレベル3+は趣味クイズへ、それ以外は結果へ。
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
    _goToResult();
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
    _phase = _Phase.finished;
    _cpuTimer?.cancel();
    final avgMs = _decisionTimes.isEmpty
        ? 0
        : _decisionTimes.reduce((a, b) => a + b) ~/ _decisionTimes.length;
    AppAnalytics.gameEnd(
      mode: _modeName,
      topScore: _vsCpu || _isLocalMulti
          ? _pairsWon.reduce(max)
          : _soloScore(avgMs),
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
    if (isMatch) {
      _resolving = true;
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
          Sfx.instance.wrong(); // 相手に取られた合図
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
    };
    if (_rng.nextDouble() < chance) _cpuMemory.add(index);
  }

  int get _cpuThinkMs => switch (widget.cpuLevel!) {
        CpuLevel.easy => 1200,
        CpuLevel.normal => 1000,
        CpuLevel.hard => 850,
        CpuLevel.oni => 700,
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
    return Scaffold(
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
                _Phase.hobbyQuiz => _buildHobbyQuiz(m),
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
    );
  }

  Widget _buildMemorize(MetaStrings m) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
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
                    m.memorizePrompt,
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
                      SvgPicture.asset(p.faceAsset, width: 44, height: 44),
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
                onPressed: _startPlaying,
                child: Text(m.memorizeDone),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBoard(MetaStrings m) {
    const cols = 4;
    return Padding(
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
        chip('🤖 ${m.cpuLabel}', _pairsWon[1], _turn == 1,
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
                  child: SvgPicture.asset(card.person.faceAsset),
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
          SvgPicture.asset(target.faceAsset, width: 110, height: 110),
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
class PlatformDispatcherLocale {
  static bool get isJa =>
      WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'ja';
}
