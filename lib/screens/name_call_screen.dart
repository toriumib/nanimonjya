import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:just_audio/just_audio.dart';

import '../l10n/meta_strings.dart';
import '../models/name_call.dart';
import '../models/person.dart';
import '../services/ad_ids.dart';
import '../services/app_analytics.dart';
import '../services/online_match_service.dart';
import '../services/player_profile.dart';
import '../services/sfx.dart';
import 'home_shell.dart';
import 'local_result_screen.dart';
import 'match_game_screen.dart' show PlatformDispatcherLocale;
import 'online_result_screen.dart';

/// メインモード「なまえコール」。
///
/// 1. 命名フェーズ: 全員の顔に順番に名前をつける（名簿はひみつ）
/// 2. 本編: ランダムに2枚ずつ出現。2枚とも名前を思い出せたら「りょうどり」、
///    片方だけなら1枚獲得、どちらも外すと没収
/// 3. 終了時に名簿を公開して答え合わせ。獲得枚数で勝敗
class NameCallScreen extends StatefulWidget {
  final int humanPlayers; // 1=ひとりで, 2..4=1台でみんなで
  final OnlineMatchSession? online;

  const NameCallScreen({
    super.key,
    this.humanPlayers = 1,
    this.online,
  });

  @override
  State<NameCallScreen> createState() => _NameCallScreenState();
}

enum _Phase { naming, sealed, round, roundResult, reveal }

class _NameCallScreenState extends State<NameCallScreen> {
  late final Random _rng =
      widget.online != null ? Random(widget.online!.seed) : Random();
  late final NameCallGame _game;

  _Phase _phase = _Phase.naming;

  // 命名フェーズ
  int _namingIndex = 0;
  final TextEditingController _nameController = TextEditingController();

  // ラウンド
  List<Person> _round = [];
  int _answering = 0; // 0=左のカード, 1=右のカード
  final List<bool> _roundHits = [];
  List<String> _choices = [];
  int _turn = 0;
  late final List<int> _cardsWon = List.filled(widget.humanPlayers, 0);

  // 回答タイマー
  Timer? _quizTimer;
  int _timeLeft = NameCallGame.answerSeconds;

  // 記録
  int _quizCorrect = 0;
  int _quizTotal = 0;
  int _ryoudoriCount = 0;

  // 報酬（一人プレイの終了ビューで表示）
  int _coinsEarned = 0;
  List<String> _newAchievements = [];
  bool _rewarded = false;

  BannerAd? _bannerAd;
  final AudioPlayer _bgmPlayer = AudioPlayer();

  bool get _isOnline => widget.online != null;
  bool get _isLocalMulti => !_isOnline && widget.humanPlayers >= 2;
  bool get _isSolo => !_isOnline && !_isLocalMulti;

  String get _modeName => _isOnline
      ? 'namecall_race'
      : _isLocalMulti
          ? 'namecall_local'
          : 'namecall_solo';

  @override
  void initState() {
    super.initState();
    final ja = PlatformDispatcherLocale.isJa;
    _game = NameCallGame(
      people: generatePeople(NameCallGame.peopleCount, ja: ja, random: _rng),
      rng: _rng,
    );
    AppAnalytics.gameStart(
      mode: _modeName,
      players: _isOnline ? 2 : widget.humanPlayers,
    );
    _loadBanner();
    _startBgm();
  }

  Future<void> _startBgm() async {
    if (kIsWeb) return;
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
    _quizTimer?.cancel();
    _nameController.dispose();
    _bannerAd?.dispose();
    _bgmPlayer.dispose();
    super.dispose();
  }

  // ─────────────── 命名フェーズ ───────────────

  Person get _namingPerson => _game.people[_namingIndex];

  void _rollGacha() {
    final m = MetaStrings.of(context);
    _nameController.text = m.gachaName(_rng.nextInt(9999), _rng.nextInt(9999));
    setState(() {});
  }

  void _submitName() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Sfx.instance.pop();
    _game.roster[_namingPerson] = name;
    _nameController.clear();
    if (_namingIndex + 1 < _game.people.length) {
      setState(() => _namingIndex += 1);
    } else {
      // 名簿を封印して本編へ
      setState(() => _phase = _Phase.sealed);
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) _nextRound();
      });
    }
  }

  // ─────────────── ラウンド ───────────────

  void _nextRound() {
    if (_game.isFinished) {
      _finishGame();
      return;
    }
    setState(() {
      _round = _game.drawRound();
      _answering = 0;
      _roundHits.clear();
      _choices = _game.choicesFor(_round[0]);
      _phase = _Phase.round;
    });
    _startQuizTimer();
  }

  void _startQuizTimer() {
    _quizTimer?.cancel();
    _timeLeft = NameCallGame.answerSeconds;
    _quizTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _timeLeft -= 1);
      if (_timeLeft <= 0) _answer(null); // 時間切れ＝おてつき
    });
  }

  void _answer(String? choice) {
    if (_phase != _Phase.round) return;
    _quizTimer?.cancel();
    final target = _round[_answering];
    final correct = choice != null && choice == _game.roster[target];
    _quizTotal += 1;
    if (correct) {
      _quizCorrect += 1;
      Sfx.instance.correct();
    } else {
      Sfx.instance.wrong();
    }
    _roundHits.add(correct);

    if (_answering + 1 < _round.length) {
      setState(() {
        _answering += 1;
        _choices = _game.choicesFor(_round[_answering]);
      });
      _startQuizTimer();
      return;
    }

    // ラウンド確定
    final gained = _roundHits.where((h) => h).length;
    _cardsWon[_turn] += gained;
    if (gained == _round.length && _round.length == 2) _ryoudoriCount += 1;
    if (_isOnline) {
      widget.online!.reportProgress(_cardsWon[0]);
    }
    setState(() => _phase = _Phase.roundResult);
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (!mounted) return;
      if (_isLocalMulti) {
        _turn = (_turn + 1) % widget.humanPlayers; // 次の人へ
      }
      _nextRound();
    });
  }

  // ─────────────── 終了 ───────────────

  Future<void> _finishGame() async {
    setState(() => _phase = _Phase.reveal);
    AppAnalytics.gameEnd(mode: _modeName, topScore: _cardsWon.reduce(max));
    if (_isOnline) {
      final elapsedMs = DateTime.now()
          .difference(widget.online!.startedAt)
          .inMilliseconds
          .clamp(0, 1 << 30);
      await widget.online!.reportDone(
        attempts: _quizTotal,
        ms: elapsedMs,
        pairs: _cardsWon[0],
      );
    } else if (_isSolo && !_rewarded) {
      _rewarded = true;
      final profile = PlayerProfile.instance;
      final reward = await profile.recordGamePlayed(_cardsWon[0]);
      final newly = await profile.refreshAchievements();
      if (mounted) {
        setState(() {
          _coinsEarned = reward.total;
          _newAchievements = newly;
        });
      }
    }
  }

  void _goToResult() {
    if (_isOnline) {
      final elapsedMs = DateTime.now()
          .difference(widget.online!.startedAt)
          .inMilliseconds
          .clamp(0, 1 << 30);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OnlineResultScreen(
            session: widget.online!,
            myAttempts: _quizTotal,
            myMs: elapsedMs,
            myPairs: _cardsWon[0],
            higherPairsWins: true,
          ),
        ),
      );
    } else if (_isLocalMulti) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LocalResultScreen(
            pairsWon: _cardsWon,
            level: 1,
            nameCall: true,
          ),
        ),
      );
    }
  }

  // ─────────────── UI ───────────────

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(m.nameCallTitle),
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
                _Phase.naming => _buildNaming(m),
                _Phase.sealed => _buildSealed(m),
                _Phase.round || _Phase.roundResult => _buildRound(m),
                _Phase.reveal => _buildReveal(m),
              },
            ),
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

  Widget _buildNaming(MetaStrings m) {
    final namerIndex =
        _isLocalMulti ? _namingIndex % widget.humanPlayers : 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Text(
            m.namingProgress(_namingIndex + 1, _game.people.length),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          if (_isLocalMulti) ...[
            const SizedBox(height: 4),
            Text(
              m.namingTurnPlayer('P${namerIndex + 1}'),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFE8663C)),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFD8E4F0), width: 2),
            ),
            child: SvgPicture.asset(_namingPerson.faceAsset,
                width: 140, height: 140),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _nameController,
            maxLength: 8,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            inputFormatters: [LengthLimitingTextInputFormatter(8)],
            decoration: InputDecoration(
              labelText: m.nameFieldLabel,
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onSubmitted: (_) => _submitName(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _rollGacha,
                  icon: const Text('🎲'),
                  label: Text(m.gachaLabel),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitName,
                  child: Text(m.namingNext),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              m.namingHint,
              style: const TextStyle(fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSealed(MetaStrings m) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📖🔒', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 14),
          Text(
            m.rosterSealed,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildRound(MetaStrings m) {
    final resultPhase = _phase == _Phase.roundResult;
    final gained = _roundHits.where((h) => h).length;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _scoreHeader(m),
          const SizedBox(height: 10),
          // 出現した2枚
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _round.length; i++) ...[
                if (i > 0) const SizedBox(width: 14),
                _roundCard(i, resultPhase),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (!resultPhase) ...[
            // タイマーバー
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _timeLeft / NameCallGame.answerSeconds,
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
                color: _timeLeft <= 3
                    ? const Color(0xFFC62828)
                    : const Color(0xFF3A7BD5),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              m.whoIsThis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final c in _choices)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _answer(c),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF2B5CA5),
                              side: const BorderSide(
                                  color: Color(0xFF3A7BD5), width: 2),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(c,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const Spacer(),
            Text(
              _round.length == 2 && gained == 2
                  ? m.ryoudori
                  : gained >= 1
                      ? m.katadori
                      : m.missAll,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: gained == 2
                    ? const Color(0xFFE8A400)
                    : gained == 1
                        ? const Color(0xFF2E9E5B)
                        : const Color(0xFF8A9AA8),
              ),
            ),
            const Spacer(),
          ],
        ],
      ),
    );
  }

  Widget _roundCard(int i, bool resultPhase) {
    final active = !resultPhase && i == _answering;
    final person = _round[i];
    final answered = i < _roundHits.length;
    return Container(
      width: 120,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active
              ? const Color(0xFFE8A400)
              : answered
                  ? (_roundHits[i]
                      ? const Color(0xFF2E9E5B)
                      : const Color(0xFFC62828))
                  : const Color(0xFFD8E4F0),
          width: active ? 3 : 2,
        ),
      ),
      child: Column(
        children: [
          SvgPicture.asset(person.faceAsset, width: 84, height: 84),
          const SizedBox(height: 6),
          Text(
            resultPhase
                ? _game.roster[person]!
                : (answered ? (_roundHits[i] ? '⭕' : '❌') : '？'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _scoreHeader(MetaStrings m) {
    if (_isOnline) {
      return Row(
        children: [
          _chip('😀 ${m.you}', '${_cardsWon[0]}', const Color(0xFF3A7BD5)),
          const SizedBox(width: 8),
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: widget.online!.opponentProgress,
              builder: (context, v, _) => _chipBox(
                  '🌐 ${widget.online!.opponentName}', '$v',
                  const Color(0xFF8A5AC2)),
            ),
          ),
          const SizedBox(width: 8),
          _chip('🃏', '${_game.deck.length}', const Color(0xFF8A9AA8)),
        ],
      );
    }
    if (_isLocalMulti) {
      const colors = [
        Color(0xFF3A7BD5),
        Color(0xFFE8663C),
        Color(0xFF2E9E5B),
        Color(0xFF8A5AC2),
      ];
      return Row(
        children: [
          for (var i = 0; i < widget.humanPlayers; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: _turn == i ? colors[i] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors[i], width: 2),
                ),
                child: Column(
                  children: [
                    Text('P${i + 1}',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: _turn == i ? Colors.white : colors[i])),
                    Text('${_cardsWon[i]}',
                        style: TextStyle(
                            fontSize: 17,
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
    return Row(
      children: [
        _chip('🃏 ${m.cardsWonLabel}', '${_cardsWon[0]}',
            const Color(0xFF3A7BD5)),
        const SizedBox(width: 8),
        _chip('🎉', '$_ryoudoriCount', const Color(0xFFE8A400)),
        const SizedBox(width: 8),
        _chip('🂠', '${_game.deck.length}', const Color(0xFF8A9AA8)),
      ],
    );
  }

  Widget _chip(String label, String value, Color color) {
    return Expanded(child: _chipBox(label, value, color));
  }

  Widget _chipBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Text(label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w900, color: color)),
          Text(value,
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildReveal(MetaStrings m) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            m.rosterReveal,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            m.rosterRevealDesc,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: Colors.black54),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD8E4F0), width: 1.5),
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final p in _game.people)
                  SizedBox(
                    width: 76,
                    child: Column(
                      children: [
                        SvgPicture.asset(p.faceAsset, width: 56, height: 56),
                        const SizedBox(height: 3),
                        Text(
                          _game.roster[p] ?? '',
                          style: const TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.w900),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_isSolo) ...[
            Card(
              elevation: 2,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('🃏 ${_cardsWon[0]}/${_game.totalCards}',
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    Text('🎉 ${m.ryoudoriLabel}: $_ryoudoriCount',
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    Text(
                        '🎯 ${_quizTotal == 0 ? 0 : _quizCorrect * 100 ~/ _quizTotal}%',
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
            if (_coinsEarned > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3D6),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: const Color(0xFFE6B54A), width: 1.5),
                ),
                child: Text(
                  '🪙 ${m.earnedCoins(_coinsEarned)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8A6A1E)),
                ),
              ),
            ],
            if (_newAchievements.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _newAchievements
                    .map((id) => Chip(
                          label: Text(m.achievementUnlocked(m.achTitle(id))),
                          backgroundColor: const Color(0xFFFFF7E0),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Sfx.instance.pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const NameCallScreen()),
                );
              },
              icon: const Icon(Icons.refresh),
              label: Text(m.playAgain),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeShell()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.home_rounded),
              label: Text(m.backToHome),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: _goToResult,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(m.toResultButton),
            ),
          ],
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
