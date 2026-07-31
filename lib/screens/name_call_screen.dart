import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../l10n/meta_strings.dart';
import '../models/name_call.dart';
import '../models/character_catalog.dart';
import '../models/person.dart';
import '../models/shop_items.dart';
import '../services/ad_ids.dart';
import '../services/bgm.dart';
import '../services/interstitial_ad_helper.dart';
import '../services/review_prompt.dart';
import '../services/app_analytics.dart';
import '../services/online_match_service.dart';
import '../services/player_profile.dart';
import '../services/sfx.dart';
import '../widgets/double_coins_button.dart';
import '../widgets/face_view.dart';
import '../widgets/game_ui.dart';
import '../widgets/store_cta.dart';
import 'home_shell.dart';
import 'local_result_screen.dart';
import 'match_game_screen.dart' show PlatformDispatcherLocale, CpuLevel;
import 'online_result_screen.dart';
import 'rulebook_screen.dart';

/// メインモード「なまえコール」。
///
/// 1. 命名フェーズ: 全員の顔に順番に名前をつける（名簿はひみつ）
///    ※カスタム名簿（自分の写真）で遊ぶ場合は名前つき済みなのでスキップ
/// 2. 本編: カードが出てくる（基本は1枚ずつ／[doubleCard]で2枚同時）
/// 3. 終了時に名簿を公開して答え合わせ。獲得枚数で勝敗
///
/// 回答方式は2つ（[quizMode]で切替）:
/// - **呼んで判定（既定）**: 名前は暗記しておき、カードを見たら声に出して呼ぶ。
///   取れた人のボタンをタップして獲得。誰も思い出せなければ付け直して山札に戻す
/// - **4択クイズ**: 選択肢から選ぶ。ひとりで静かに遊びたいとき用
/// - オンライン対戦は相手の宣言を判定できないため常にクイズ
class NameCallScreen extends StatefulWidget {
  final int humanPlayers; // 1=ひとりで, 2..4=1台でみんなで
  final OnlineMatchSession? online;
  final bool doubleCard; // true=2枚同時出現オプション（まとめて命名のみ）
  final List<Person>? customPeople; // 自分の写真の名簿（各Person.nameが正解名）
  final int peopleCount; // 登場人数（6〜12）。カスタム/オンライン時は無視
  final bool nameAsYouGo; // true=出たとき命名（1枚ずつ・初登場でその場命名）
  /// まとめて命名のとき、名前を自分で入力せず自動でつける（入力が面倒な人向け）。
  final bool autoNames;

  /// 回答方式。
  ///
  /// false（既定）= **呼んで判定**。原作のボードゲームと同じで、
  /// カードを見たら声に出して名前を呼び、取れた人のボタンをタップする。
  /// 名前は「暗記しておくもの」で、選択肢は出ない。
  ///
  /// true = **4択クイズ**。1人で黙々と遊びたいとき用のオプション。
  /// オンライン対戦は相手の宣言を判定できないため常にクイズ。
  final bool quizMode;

  /// 🤖 CPU対戦の難易度。null ならCPU戦ではない。
  /// 顔が再登場したら4択で答え、CPUが思い出すより早く正解できれば
  /// そのカードを取れる。難易度が上がるほどCPUの反応が速くなり、
  /// 勝ったときのコインも大きくなる。
  final CpuLevel? cpuLevel;

  const NameCallScreen({
    super.key,
    this.humanPlayers = 1,
    this.online,
    this.doubleCard = false,
    this.customPeople,
    this.peopleCount = NameCallGame.peopleCount,
    this.nameAsYouGo = false,
    this.autoNames = false,
    this.quizMode = false,
    this.cpuLevel,
  });

  /// オンライン対戦は両者で同じ人数にそろえる必要があるため固定。
  static const int onlinePeopleCount = 9;

  @override
  State<NameCallScreen> createState() => _NameCallScreenState();
}

enum _Phase {
  naming,
  inlineNaming,
  /// 名簿を一覧で見て覚える画面。
  /// - 🎲名前おまかせのときは自動命名した名前をここで初めて見せる（必須）
  /// - 手入力のときは命名画面の「暗記する」ボタンからいつでも来られる
  rosterReview,
  sealed,
  round,
  roundResult,
  reveal
}

class _NameCallScreenState extends State<NameCallScreen> {
  late final Random _rng =
      widget.online != null ? Random(widget.online!.seed) : Random();
  late final NameCallGame _game;

  _Phase _phase = _Phase.naming;

  // 📉 完走率ファネル: 各通過点を1回だけ撃つためのフラグ。
  // 終了(_finishGame)まで到達したかどうかも持ち、dispose時に
  // 「完走せずに画面を出た＝離脱」を game_exit として記録する。
  final Set<String> _funnelSent = {};
  bool _finished = false;

  void _markProgress(String phase) {
    if (!_funnelSent.add(phase)) return; // すでに撃った通過点は無視
    AppAnalytics.namecallProgress(
      phase: phase,
      people: _game.people.length,
      mode: _modeName,
    );
  }

  /// 🤫 アプリが本当の名前を知らない人。
  ///
  /// 「名前をつけた！」で進んだ場合、名前はプレイヤーが口で言っただけで
  /// アプリには伝わっていない。札を区別するために内部でガチャ名を入れるが、
  /// **それを画面に出すと「言ってない名前」が出て混乱する**（報告されたバグ）。
  /// ここに入れておき、表示のときは必ず [_displayName] を通して伏せる。
  final Set<Person> _secretNames = {};

  /// 画面に出してよい名前。アプリが知らない名前は伏せ字にする。
  String _displayName(Person p, MetaStrings m) {
    if (_secretNames.contains(p)) return m.secretNamePlaceholder;
    return _game.roster[p] ?? '';
  }

  // 命名フェーズ
  int _namingIndex = 0;
  final TextEditingController _nameController = TextEditingController();

  // 出たとき命名: いま命名しようとしているカード
  Person? _inlinePerson;

  // ラウンド
  List<Person> _round = [];
  int _answering = 0; // 何枚目のカードを処理中か
  final List<bool> _roundHits = []; // クイズ用: そのカードを正解したか
  final List<int> _roundClaimer = []; // 審判用: そのカードを取ったプレイヤー(-1=パス)
  List<String> _choices = [];
  String? _pickedChoice; // クイズで選んだ答え（正誤ハイライト用）
  bool _answerLocked = false; // 正誤表示中の連打ガード
  int _roundSeq = 0; // ラウンドごとに増やしてカード登場アニメを再生
  late final List<int> _cardsWon =
      List.filled(widget.cpuLevel != null ? 2 : max(1, widget.humanPlayers), 0);

  /// 🤖 CPUが「思い出した」タイミングを表すタイマー。
  Timer? _cpuTimer;
  /// このラウンドでCPUが先に取ったか（プレイヤーの回答を無効にするため）。

  // 回答タイマー（クイズモードのみ）
  Timer? _quizTimer;
  // ⏳「ゆとりの砂時計」を装備していると持ち時間が5秒のびる
  int get _answerSeconds =>
      NameCallGame.answerSeconds +
      (luckyCharmById(PlayerProfile.instance.selectedCharm).effect ==
              CharmEffect.timeBonus
          ? 5
          : 0);
  int _timeLeft = NameCallGame.answerSeconds;

  // 記録
  int _quizCorrect = 0;
  int _quizTotal = 0;
  int _ryoudoriCount = 0;

  // 報酬（一人プレイの終了ビューで表示）
  int _coinsEarned = 0;
  /// 🤖 CPUに勝ったときの難易度ボーナス（終了画面で内訳を見せる）
  int _cpuBonus = 0;
  /// 🏆 この試合で新しく参戦した実績キャラのID
  List<String> _featUnlocked = [];
  List<String> _newAchievements = [];
  bool _rewarded = false;

  BannerAd? _bannerAd;

  bool get _isOnline => widget.online != null;
  bool get _isLocalMulti => !_isOnline && widget.humanPlayers >= 2;
  bool get _isCpu => !_isOnline && widget.cpuLevel != null;
  bool get _isSolo => !_isOnline && !_isLocalMulti && !_isCpu;
  bool get _isCustom => widget.customPeople != null;

  /// 「呼んで判定」方式か（原作のボードゲームと同じ流れ）。
  ///
  /// カードを見たら声に出して名前を呼び、取れた人のボタンをタップする。
  /// 名前は暗記しておくものなので選択肢は出さない。
  /// オンラインは相手の宣言を判定できないため、常に4択クイズになる。
  bool get _isReferee => !_isOnline && !widget.quizMode && !_isCpu;

  String get _modeName => _isOnline
      ? 'namecall_race'
      : _isCpu
          ? 'namecall_cpu_${widget.cpuLevel!.name}'
          : _isLocalMulti
              ? 'namecall_local'
              : 'namecall_solo';

  @override
  void initState() {
    super.initState();
    final ja = PlatformDispatcherLocale.isJa;
    final count = _isOnline
        ? NameCallScreen.onlinePeopleCount
        : widget.peopleCount.clamp(2, NameCallGame.maxPeople);
    // オンラインは両プレイヤーで顔が一致する必要があるため基本12のまま。
    // オフライン/ひとりは購入済みキャラも出演プールに加える。
    final charAssets = _isOnline
        ? null
        : applyDeckFilter(
            [
              ...kCharImageAssets,
              ...unlockedExtraAssets(PlayerProfile.instance.unlockedCharacters),
            ],
            PlayerProfile.instance.deckExcluded,
          );
    // 🎴 デッキで絞った結果が必要人数より少ないと、生成器は基本12人へ
    //    フォールバックしてしまい「OFFにしたキャラが出てくる」ことになる。
    //    デッキの意思を優先し、出演人数のほうをデッキの数に合わせる。
    final effectiveCount =
        charAssets == null ? count : min(count, charAssets.length);
    final people = _isCustom
        ? ([...widget.customPeople!]..shuffle(_rng))
        : generateImagePeople(effectiveCount,
            ja: ja, random: _rng, charAssets: charAssets);
    _game = NameCallGame(
      people: people,
      rng: _rng,
      // 出たとき命名は必ず1枚ずつ（初登場で命名→再登場で想起の流れのため）
      cardsPerRound: (widget.doubleCard && !widget.nameAsYouGo) ? 2 : 1,
    );
    if (_isCustom) {
      // カスタム名簿は名前つき済み → 命名フェーズをスキップして本編へ
      for (final p in people) {
        _game.roster[p] = p.name;
      }
      _phase = _Phase.sealed;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) _nextRound();
        });
      });
    } else if (widget.nameAsYouGo) {
      // 出たとき命名: 事前命名フェーズなし。最初のカードからスタート
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _nextRound();
      });
    } else if (widget.autoNames) {
      // 🎲 名前おまかせ: 入力の手間を省き、おなまえガチャで全員に命名して本編へ。
      // 同じ名前が2人に付くと4択の正解が定まらないので、重複しないようにする。
      final m = MetaStrings(ja);
      final used = <String>{};
      for (final p in people) {
        var name = m.gachaName(_rng.nextInt(9999), _rng.nextInt(9999));
        var guard = 0;
        while (used.contains(name) && guard < 60) {
          name = m.gachaName(_rng.nextInt(9999), _rng.nextInt(9999));
          guard += 1;
        }
        // それでも重複するなら末尾に番号を足して必ず一意にする
        if (used.contains(name)) name = '$name${used.length + 1}';
        used.add(name);
        _game.roster[p] = name;
      }
      // 自動でつけた名前は、ここで見せないと誰が誰だか分からないまま本編に入って
      // しまう。必ず名簿一覧を挟み、自分のタイミングで開始してもらう。
      _phase = _Phase.rosterReview;
    }
    AppAnalytics.gameStart(
      mode: _isCustom
          ? '${_modeName}_custom'
          : widget.nameAsYouGo
              ? '${_modeName}_asyougo'
              : _modeName,
      players: _isOnline ? 2 : widget.humanPlayers,
    );
    _loadBanner();
    Bgm.instance.playGame(); // 🎵 Android/Web どちらでも鳴る
  }

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
    // 📉 完走せずに画面を出た＝離脱。どこまで進んでいたかと一緒に記録する。
    // （_finishGame まで行った場合は 'completed' を撃ってあるので二重に撃たない）
    if (!_finished) {
      AppAnalytics.gameExit(
        mode: _modeName,
        reason: 'quit',
        progressPct: _game.progressPct,
        people: _game.people.length,
      );
    }
    _quizTimer?.cancel();
    _nameController.dispose();
    _bannerAd?.dispose();
    // リザルト画面が先に鳴らし始めていたら止めない
    Bgm.instance.stopGame();
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
    HapticFeedback.selectionClick();
    _game.roster[_namingPerson] = name;
    _nameController.clear();
    if (_namingIndex + 1 < _game.people.length) {
      setState(() => _namingIndex += 1);
    } else {
      // 全員に名前がついた → 封印する前に名簿を見て覚える時間をとる。
      // （準備ができてから自分で開始してもらう）
      setState(() => _phase = _Phase.rosterReview);
    }
  }

  // ─────────────── ラウンド ───────────────

  void _nextRound() {
    if (_game.isFinished) {
      _finishGame();
      return;
    }

    // 📉 ファネル: 全員に名前がついた時点＝本編に入れた
    if (_game.roster.length >= _game.people.length) {
      _markProgress('naming_done');
    }
    // 半分まで消化できたか（ここから先の離脱は「飽き」より「難しさ」を疑う）
    if (_game.progressPct >= 50) _markProgress('recall_half');

    // 出たとき命名モード: 1枚引いて、初登場なら命名・再登場なら想起
    if (widget.nameAsYouGo) {
      final card = _game.drawRound().first; // cardsPerRound=1固定
      if (!_game.roster.containsKey(card)) {
        // 初登場 → その場で名前をつける（無得点）
        setState(() {
          _inlinePerson = card;
          _phase = _Phase.inlineNaming;
        });
        return;
      }
      // 再登場 → 想起（1枚ラウンド）
      _markProgress('recall_first');
      setState(() {
        _round = [card];
        _answering = 0;
        _roundHits.clear();
        _roundClaimer.clear();
        _roundSeq += 1;
        if (!_isReferee) _choices = _buildChoices(card);
        _phase = _Phase.round;
      });
      if (!_isReferee) _startQuizTimer();
      return;
    }

    _markProgress('recall_first');
    setState(() {
      _round = _game.drawRound();
      _answering = 0;
      _roundHits.clear();
      _roundClaimer.clear();
      _roundSeq += 1;
      if (!_isReferee) _choices = _buildChoices(_round[0]);
      _phase = _Phase.round;
    });
    if (!_isReferee) _startQuizTimer();
  }

  // 出たとき命名: 初登場カードに名前をつけて次へ
  /// 出たとき命名で、いまのカードに名前を確定して次へ進む。
  ///
  /// [autoNameIfEmpty] が true のときは、未入力でもガチャ名を自動でつけて進む。
  /// このカードは再登場したときに名前を答える対象になるので、
  /// 「名前なし」のままにはできない（＝空でも必ず何かの名前を割り当てる）。
  void _submitInlineName({bool autoNameIfEmpty = false}) {
    if (_inlinePerson == null) return;
    var name = _nameController.text.trim();
    if (name.isEmpty) {
      if (!autoNameIfEmpty) return;
      // 「名前をつけた！」の場合、覚えるのはプレイヤーが声に出した名前。
      // アプリはその名前を知らないので、札を区別するための識別子として
      // 内部的にガチャ名を割り当てるだけ。**画面には出さない**
      // （出すと「言ってない名前」が表示されて混乱するため）。
      name = _uniqueGachaName();
      // アプリはこの人の本当の名前を知らない → 画面に出さない印をつける
      _secretNames.add(_inlinePerson!);
    }
    Sfx.instance.pop();
    HapticFeedback.selectionClick();
    _game.roster[_inlinePerson!] = name;
    _nameController.clear();
    _inlinePerson = null;
    _nextRound();
  }

  /// 🎲 アプリに名前を決めてもらう。
  ///
  /// 決まった名前は**この人を覚えるための名前**なので、小さなトーストではなく
  /// 画面いっぱいに大きく見せてから次へ進む（覚える時間をとる）。
  Future<void> _nameWithGacha() async {
    final person = _inlinePerson;
    if (person == null) return;
    final m = MetaStrings.of(context);
    final name = _uniqueGachaName();
    Sfx.instance.pop();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaceView(person: person, size: 120, radius: 16),
            const SizedBox(height: 14),
            Text(name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2B5CA5))),
            const SizedBox(height: 6),
            Text(m.gachaNamedHint,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
            ),
            child: Text(m.memorizedNext),
          ),
        ],
      ),
    );
    if (!mounted) return;
    _nameController.text = name;
    _submitInlineName();
  }

  /// まだ名簿で使われていないガチャ名を作る。
  /// 同じ名前が2人につくと、再登場時にどちらが正解か決まらなくなるため。
  String _uniqueGachaName() {
    final m = MetaStrings(PlatformDispatcherLocale.isJa);
    final used = _game.roster.values.toSet();
    for (var i = 0; i < 60; i++) {
      final n = m.gachaName(_rng.nextInt(9999), _rng.nextInt(9999));
      if (!used.contains(n)) return n;
    }
    // 出尽くしたときは番号を足して必ず一意にする
    return '${m.gachaName(_rng.nextInt(9999), _rng.nextInt(9999))}${used.length + 1}';
  }

  /// クイズの4択を作る。名簿の名前が4つに満たないとき（出たとき命名の序盤や
  /// 少人数のカスタム名簿）は、おなまえガチャの偽名で4つまで補充する。
  List<String> _buildChoices(Person card) {
    final choices = _game.choicesFor(card).toList();
    if (choices.length < 4) {
      final m = MetaStrings.of(context);
      var guard = 0;
      while (choices.length < 4 && guard < 40) {
        final decoy = m.gachaName(_rng.nextInt(9999), _rng.nextInt(9999));
        if (!choices.contains(decoy)) choices.add(decoy);
        guard++;
      }
      choices.shuffle(_rng);
    }
    return choices;
  }

  /// 難易度ごとのCPUの手強さ。
  /// (最短ms, ばらつきms, 見逃す確率%, 勝ったときのボーナスコイン)
  static const Map<CpuLevel, List<int>> _cpuSpec = {
    CpuLevel.easy: [4200, 3500, 35, 20],
    CpuLevel.normal: [3000, 3000, 20, 45],
    CpuLevel.hard: [2000, 2200, 10, 90],
    CpuLevel.oni: [1300, 1400, 3, 180],
  };

  List<int> get _spec =>
      _cpuSpec[widget.cpuLevel] ?? _cpuSpec[CpuLevel.normal]!;

  /// 🤖 CPUが「思い出す」までの時間を決める。
  /// 速すぎると理不尽なので、人が選択肢を読んで押せる範囲でばらつかせる。
  /// ときどきCPUも思い出せないことにして、取り返す余地を残す。
  void _startCpuTimer() {
    _cpuTimer?.cancel();
    if (!_isCpu) return;
    if (_rng.nextInt(10) < 2) return; // 2割はCPUも分からない
    final ms = 2500 + _rng.nextInt(4000); // 2.5〜6.5秒
    _cpuTimer = Timer(Duration(milliseconds: ms), _cpuAnswers);
  }

  /// CPUが先に思い出した。プレイヤーの回答を締め切ってCPUの取り分にする。
  void _cpuAnswers() {
    if (!mounted || _phase != _Phase.round || _answerLocked) return;
    _answer(null, takenByCpu: true);
  }

  void _startQuizTimer() {
    _quizTimer?.cancel();
    _timeLeft = _answerSeconds;
    _startCpuTimer();
    _quizTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      // 画面が破棄されたあともタイマーが動き続けるとリークになるので止める
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _timeLeft -= 1);
      if (_timeLeft <= 0) {
        // _answer() は回答ロック中だと即returnするため、タイマー側で止めないと
        // 残り秒数がマイナスに進み続けてしまう。
        t.cancel();
        _answer(null); // 時間切れ＝おてつき
      }
    });
  }

  // ── クイズ回答（ひとり／オンライン） ──
  // タップ → 正誤を色で見せる（0.75秒）→ 確定して次へ
  void _answer(String? choice, {bool takenByCpu = false}) {
    if (_phase != _Phase.round || _answerLocked) return;
    _answerLocked = true;
    _quizTimer?.cancel();
    _cpuTimer?.cancel();
    final target = _round[_answering];
    final correct = choice != null && choice == _game.roster[target];
    _quizTotal += 1;
    if (correct) {
      _quizCorrect += 1;
      Sfx.instance.correct();
      HapticFeedback.lightImpact();
    } else {
      Sfx.instance.wrong();
      HapticFeedback.mediumImpact();
    }
    // CPUに先を越された、または自分がまちがえた場合はCPUの取り分になる
    // CPUに取られたぶんは、下の _cardsWon[1] += (枚数 - 取れた数) で加算する
    _roundHits.add(correct && !takenByCpu);
    setState(() => _pickedChoice = choice ?? '__timeout__');

    Future.delayed(const Duration(milliseconds: 750), () {
      if (!mounted) return;
      _pickedChoice = null;
      _answerLocked = false;
      if (_answering + 1 < _round.length) {
        setState(() {
          _answering += 1;
          _choices = _buildChoices(_round[_answering]);
        });
        _startQuizTimer();
        return;
      }
      final gained = _roundHits.where((h) => h).length;
      _cardsWon[0] += gained;
      if (gained == _round.length && _round.length == 2) _ryoudoriCount += 1;
      if (_isOnline) widget.online!.reportProgress(_cardsWon[0]);
      _endRound();
    });
  }

  // ── 呼んで判定: 早かったプレイヤーをタップ、-1=だれも思い出せなかった ──
  void _claim(int player) {
    if (_phase != _Phase.round) return;
    if (player >= 0) {
      _cardsWon[player] += 1;
      Sfx.instance.correct();
      HapticFeedback.lightImpact();
    } else {
      Sfx.instance.wrong();
      // 📛 原作のルール: 誰も名前を正確に思い出せなかったら、
      // そのカードに**あらためて新しい名前をつけて**ゲームを続ける。
      // （出たとき命名のときだけ。まとめて命名は名簿が決まっているので対象外）
      if (widget.nameAsYouGo && _round.isNotEmpty) {
        final card = _round[_answering];
        _game.roster.remove(card); // 古い名前を捨てて付け直す
        // 付け直した名前をあとで試せるよう、山札に戻す
        _game.returnToDeck(card);
        setState(() {
          _inlinePerson = card;
          _phase = _Phase.inlineNaming;
        });
        return;
      }
    }
    _roundClaimer.add(player);

    if (_answering + 1 < _round.length) {
      setState(() => _answering += 1);
      return;
    }
    // りょうどり: 2枚とも同じプレイヤーが取ったら演出カウント
    if (_round.length == 2 &&
        _roundClaimer[0] >= 0 &&
        _roundClaimer[0] == _roundClaimer[1]) {
      _ryoudoriCount += 1;
    }
    _endRound();
  }

  void _endRound() {
    setState(() => _phase = _Phase.roundResult);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _nextRound();
    });
  }

  // ─────────────── 終了 ───────────────

  Future<void> _finishGame() async {
    setState(() => _phase = _Phase.reveal);
    _finished = true;
    AppAnalytics.gameEnd(mode: _modeName, topScore: _cardsWon.reduce(max));
    AppAnalytics.gameExit(
      mode: _modeName,
      reason: 'completed',
      progressPct: 100,
      people: _game.people.length,
    );
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
    } else if ((_isSolo || _isCpu) && !_rewarded) {
      _rewarded = true;
      final profile = PlayerProfile.instance;
      final reward = await profile.recordGamePlayed(_cardsWon[0]);
      // 🤖 CPU戦は勝敗を段位に反映し、勝ったら難易度ぶんのボーナスを出す。
      if (_isCpu) {
        final won = _cardsWon[0] > _cardsWon[1];
        if (won) {
          _cpuBonus = _spec[3];
          await profile.grantBonusCoins(_cpuBonus);
          // 全問正解での勝利は専用キャラの解放条件
          if (_quizTotal > 0 && _quizCorrect == _quizTotal) {
            await profile.markPerfectCpuWin();
          }
        }
        await profile.recordCpuGame(
          level: widget.cpuLevel!.name,
          won: won,
          correctQuizzes: _quizCorrect,
          totalQuizzes: _quizTotal,
          avgReactionMs: 0,
        );
        // 🏆 条件を満たした実績キャラをここで参戦させる
        _featUnlocked = await profile.refreshFeatCharacters();
      }
      final newly = await profile.refreshAchievements();
      if (mounted) {
        setState(() {
          _coinsEarned = reward.total;
          _newAchievements = newly;
        });
      }
      // ひとりプレイはリザルト画面を経由せずこの画面で終わるため、
      // 他モードで呼んでいる全画面広告とリザルト曲がここだけ抜けていた。
      Bgm.instance.playResult();
      InterstitialAdHelper.instance.onGameFinished(); // 3プレイに1回
      if (_quizTotal > 0 && _quizCorrect == _quizTotal) {
        maybeAskReview(minGames: 0); // 全問正解の好タイミングでレビュー依頼
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
        title: Text(widget.nameAsYouGo ? m.nameCallAsYouGoTitle : m.nameCallTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _confirmQuit,
        ),
        // 📖 ゲーム中でもルールを見直せるようにする
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: RulebookButton(
                focus: _isCpu ? RuleTopic.cpu : RuleTopic.nameCall,
                onDark: true,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: switch (_phase) {
                _Phase.naming => _buildNaming(m),
                _Phase.inlineNaming => _buildInlineNaming(m),
                _Phase.rosterReview => _buildRosterReview(m),
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
            child: FaceView(person: _namingPerson, size: 140, radius: 18),
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
          // 📖 命名の途中でも、ここまでつけた名前を一覧で見返して覚えられる。
          // （1人ずつ入力していると、前に何とつけたか忘れてしまうため）
          if (_namingIndex > 0) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Sfx.instance.pop();
                setState(() => _phase = _Phase.rosterReview);
              },
              icon: const Text('📖', style: TextStyle(fontSize: 15)),
              label: Text(m.namingMemorize),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2B5CA5),
                side: const BorderSide(color: Color(0xFF3A7BD5), width: 2),
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ],
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

  // 出たとき命名: 初登場のキャラにその場で名前をつける
  Widget _buildInlineNaming(MetaStrings m) {
    final named = _game.roster.length;
    final total = _game.people.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE9C7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              m.newComer,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFC26A00)),
            ),
          ),
          const SizedBox(height: 4),
          Text('${m.namedSoFar}: $named / $total',
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFFC93C), width: 3),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x33FFC93C),
                    blurRadius: 12,
                    offset: Offset(0, 5)),
              ],
            ),
            child: FaceView(person: _inlinePerson!, size: 150, radius: 18),
          )
              .animate(key: ValueKey(_inlinePerson))
              .fadeIn(duration: 240.ms)
              .scale(
                begin: const Offset(0.7, 0.7),
                end: const Offset(1, 1),
                duration: 380.ms,
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 14),
          // ⌨️ テキスト入力はやめた。
          // みんなで遊ぶときは口で名前を言うので、入力欄があると
          // 「打つ人」を待つことになって場が止まる。ボタン2つに絞る。
          //
          // ① 名前をつけた！ … 声に出してつけた名前を各自が覚える（アプリは記録だけ）
          // ② 🎲おまかせ    … アプリが名前を決める。決まった名前は大きく表示する
          //
          // ①のときアプリ側は名前を知らないので、内部的にはガチャ名を割り当てて
          // 「札を区別する識別子」として使う。プレイヤーが覚えるのは自分でつけた名前。
          //
          // ⚠️ ただし4択クイズ（CPU戦・オンライン）では、アプリが正解の名前を
          //    知らないと選択肢が作れず出題が成立しない。そのため①は出さず、
          //    かならずアプリが名前を決める（＝おまかせ）方式に一本化する。
          if (_isReferee) ...[
            ElevatedButton.icon(
              onPressed: () => _submitInlineName(autoNameIfEmpty: true),
              icon: const Text('✨', style: TextStyle(fontSize: 20)),
              label: Text(m.namedItAloud),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ECDC4),
                minimumSize: const Size.fromHeight(56),
                textStyle:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 10),
          ],
          OutlinedButton.icon(
            onPressed: _nameWithGacha,
            icon: const Text('🎲', style: TextStyle(fontSize: 18)),
            label: Text(m.gachaNameIt),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2B5CA5),
              side: const BorderSide(color: Color(0xFF3A7BD5), width: 2),
              minimumSize: const Size.fromHeight(50),
              textStyle:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              m.asYouGoHint,
              style: const TextStyle(fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  /// 命名済みの名簿を一覧で見せて覚えてもらう画面。
  /// 全員に名前がついていれば「おぼえた！はじめる」で本編へ、
  /// 途中なら「つづける」で命名画面に戻る。
  Widget _buildRosterReview(MetaStrings m) {
    final named = _game.people
        .where((p) => (_game.roster[p] ?? '').isNotEmpty)
        .toList();
    final done = named.length >= _game.people.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Column(
        children: [
          Text(m.rosterReviewTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2B5CA5))),
          const SizedBox(height: 4),
          Text(m.rosterReviewHint(named.length, _game.people.length),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.78,
              children: [
                for (final p in named)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFD8E4F0), width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Expanded(
                          child: FaceView(person: p, size: 200, radius: 0),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 6),
                          child: Text(
                            _displayName(p, m),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF2B5CA5)),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Sfx.instance.pop();
              if (!done) {
                // まだ命名の途中 → 命名画面に戻る
                setState(() => _phase = _Phase.naming);
                return;
              }
              setState(() => _phase = _Phase.sealed);
              Future.delayed(const Duration(milliseconds: 1200), () {
                if (mounted) _nextRound();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4ECDC4),
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text(done ? m.rosterReviewStart : m.rosterReviewBack,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900)),
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
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _scoreHeader(m),
          const SizedBox(height: 10),
          Row(
            key: ValueKey(_roundSeq),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _round.length; i++) ...[
                if (i > 0) const SizedBox(width: 14),
                _roundCard(i, resultPhase, m),
              ],
            ],
          )
              .animate(key: ValueKey(_roundSeq))
              .fadeIn(duration: 260.ms)
              .scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1, 1),
                duration: 320.ms,
                curve: Curves.easeOutBack,
              )
              .slideY(begin: 0.12, end: 0, duration: 300.ms),
          const SizedBox(height: 12),
          if (resultPhase)
            _roundResultBanner(m)
          else if (_isReferee)
            Expanded(child: _refereePanel(m))
          else
            Expanded(child: _quizPanel(m)),
        ],
      ),
    );
  }

  // クイズパネル（ひとり／オンライン）
  Widget _quizPanel(MetaStrings m) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _timeLeft / _answerSeconds,
            minHeight: 8,
            backgroundColor: Colors.grey.shade300,
            color: _timeLeft <= 3
                ? const Color(0xFFC62828)
                : const Color(0xFF3A7BD5),
          ),
        ),
        const SizedBox(height: 10),
        Text(m.whoIsThis,
            style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final c in _choices)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: SizedBox(
                      width: double.infinity,
                      child: _choiceButton(c),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // クイズ選択肢ボタン（立体・回答後は正解=緑・選んだ不正解=赤にハイライト）
  Widget _choiceButton(String c) {
    final correctName = _game.roster[_round[_answering]];
    // 通常時は白ベースの立体、判定中は色つきに切り替え
    List<Color> colors = const [Colors.white, Color(0xFFEAF3FF)];
    Color edge = const Color(0xFF9DBBD8);
    Color fg = const Color(0xFF2B5CA5);
    if (_answerLocked) {
      if (c == correctName) {
        colors = const [Color(0xFF4FBE7C), Color(0xFF2E9E5B)];
        edge = const Color(0xFF1E7A44);
        fg = Colors.white;
      } else if (c == _pickedChoice) {
        colors = const [Color(0xFFE06A6A), Color(0xFFC94A4A)];
        edge = const Color(0xFF9C3232);
        fg = Colors.white;
      }
    }
    return JuicyButton(
      onTap: _answerLocked ? null : () => _answer(c),
      colors: colors,
      edgeColor: edge,
      height: 56,
      radius: 14,
      child: Text(c,
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w900, color: fg)),
    );
  }

  // 審判パネル（オフライン対戦）: 一斉に名前を呼び、早かった人のボタンを押す
  Widget _refereePanel(MetaStrings m) {
    const colors = [
      [Color(0xFF5B9BE8), Color(0xFF3A7BD5)],
      [Color(0xFFF08A5D), Color(0xFFE8663C)],
      [Color(0xFF56BE82), Color(0xFF2E9E5B)],
      [Color(0xFFA57AD8), Color(0xFF8A5AC2)],
    ];
    return Column(
      children: [
        Text(
          // ひとりで遊ぶときは「一斉にコール」だと不自然なので言い方を変える
          widget.humanPlayers <= 1
              ? m.soloRecallPrompt
              : (_round.length == 2
                  ? m.refereePromptCard(_answering + 1)
                  : m.refereePrompt),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(widget.humanPlayers <= 1 ? m.soloRecallHint : m.refereeHint,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 2.4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              for (var i = 0; i < widget.humanPlayers; i++)
                JuicyButton(
                  onTap: () => _claim(i),
                  colors: colors[i],
                  height: double.infinity,
                  child: Text(
                    widget.humanPlayers <= 1
                        ? m.soloGot
                        : m.playerGot('P${i + 1}'),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                              offset: Offset(0, 1.5), color: Color(0x55000000)),
                        ]),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        JuicyButton(
          onTap: () => _claim(-1),
          colors: const [Color(0xFFF2F4F7), Color(0xFFDCE3EC)],
          edgeColor: const Color(0xFFB4C0CE),
          height: 46,
          child: Text(m.nobodyKnew,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF5A6A7A))),
        ),
      ],
    );
  }

  Widget _roundResultBanner(MetaStrings m) {
    final String text;
    final Color color;
    if (_isReferee) {
      final ryoudori = _round.length == 2 &&
          _roundClaimer.length == 2 &&
          _roundClaimer[0] >= 0 &&
          _roundClaimer[0] == _roundClaimer[1];
      final anyGot = _roundClaimer.any((c) => c >= 0);
      text = ryoudori
          ? m.ryoudori
          : anyGot
              ? m.katadori
              : m.missAll;
      color = ryoudori
          ? const Color(0xFFE8A400)
          : anyGot
              ? const Color(0xFF2E9E5B)
              : const Color(0xFF8A9AA8);
    } else {
      final gained = _roundHits.where((h) => h).length;
      text = _round.length == 2 && gained == 2
          ? m.ryoudori
          : gained >= 1
              ? m.katadori
              : m.missAll;
      color = gained == 2
          ? const Color(0xFFE8A400)
          : gained == 1
              ? const Color(0xFF2E9E5B)
              : const Color(0xFF8A9AA8);
    }
    return Expanded(
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.w900, color: color),
        )
            .animate()
            .fadeIn(duration: 180.ms)
            .scale(
              begin: const Offset(0.6, 0.6),
              end: const Offset(1, 1),
              duration: 420.ms,
              curve: Curves.elasticOut,
            ),
      ),
    );
  }

  Widget _roundCard(int i, bool resultPhase, MetaStrings m) {
    final person = _round[i];
    final claimed = i < _roundClaimer.length;
    final answered = i < _roundHits.length;
    // 現在処理中のカードをハイライト
    final active = !resultPhase && i == _answering;
    final ok = _isReferee ? (claimed && _roundClaimer[i] >= 0) : (answered && _roundHits[i]);
    final done = _isReferee ? claimed : answered;
    // 1枚だけのラウンドは大きく表示（見やすさ・タップしやすさ向上）
    final single = _round.length == 1;
    final faceSize = single ? 148.0 : 92.0;
    final cardWidth = single ? 190.0 : 128.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: cardWidth,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active
              ? const Color(0xFFE8A400)
              : done
                  ? (ok ? const Color(0xFF2E9E5B) : const Color(0xFFC62828))
                  : const Color(0xFFD8E4F0),
          width: active ? 4 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          FaceView(person: person, size: faceSize, radius: 14),
          const SizedBox(height: 8),
          Text(
            resultPhase
                ? _displayName(person, m)
                : (done
                    ? (_isReferee
                        ? (_roundClaimer[i] >= 0
                            ? 'P${_roundClaimer[i] + 1}'
                            : '—')
                        : (_roundHits[i] ? '⭕' : '❌'))
                    : '？'),
            style: TextStyle(
                fontSize: single ? 18 : 14, fontWeight: FontWeight.w900),
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
    // 🤖 CPU対戦: 自分とCPUの取ったカード数を並べる
    if (_isCpu) {
      return Row(
        children: [
          _chip('😀 ${m.you}', '${_cardsWon[0]}', const Color(0xFF3A7BD5)),
          const SizedBox(width: 8),
          _chip('🤖 CPU', '${_cardsWon[1]}', const Color(0xFF8A5AC2)),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors[i], width: 2),
                ),
                child: Column(
                  children: [
                    Text('P${i + 1}',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: colors[i])),
                    Text('${_cardsWon[i]}',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: colors[i])),
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
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          )
              .animate()
              .fadeIn(duration: 200.ms)
              .scale(
                begin: const Offset(0.6, 0.6),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.elasticOut,
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
                // 名簿を1人ずつ時間差でポップイン
                for (var i = 0; i < _game.people.length; i++)
                  SizedBox(
                    width: 76,
                    child: Column(
                      children: [
                        FaceView(
                            person: _game.people[i], size: 56, radius: 10),
                        const SizedBox(height: 3),
                        Text(
                          _displayName(_game.people[i], m),
                          style: const TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.w900),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: (200 + i * 80).ms, duration: 220.ms)
                      .scale(
                        begin: const Offset(0.6, 0.6),
                        end: const Offset(1, 1),
                        delay: (200 + i * 80).ms,
                        duration: 260.ms,
                        curve: Curves.easeOutBack,
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
            // 🏆 実績で新しく参戦したキャラを大きく知らせる。
            // ここを出さないと、条件を満たしても本人が気づけない。
            if (_featUnlocked.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final id in _featUnlocked)
                Builder(builder: (context) {
                  final c = extraCharacterById(id);
                  if (c == null) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8A5AC2), Color(0xFF3D1E6B)],
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(c.asset,
                              width: 56, height: 56, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            m.featJoined(c.emoji),
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1, 1),
                          curve: Curves.easeOutBack);
                }),
            ],
            // 🤖 CPU戦は勝敗をはっきり出す（ひとりでも手応えが残るように）
            if (_isCpu) ...[
              const SizedBox(height: 10),
              Text(
                _cardsWon[0] > _cardsWon[1] ? m.cpuWinTitle : m.cpuLoseTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: _cardsWon[0] > _cardsWon[1]
                      ? const Color(0xFF2E9E5B)
                      : const Color(0xFF8A9AA8),
                ),
              ),
            ],
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
                child: Column(
                  children: [
                    Text(
                      '🪙 ${m.earnedCoins(_coinsEarned)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8A6A1E)),
                    ),
                    // 難易度ボーナスは内訳として見せる（強い相手を選ぶ動機になる）
                    if (_cpuBonus > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        m.cpuBonusCoins(_cpuBonus),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFB07A00)),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      m.saveCoinsPitch,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 11.5, color: Color(0xFF8A6A1E)),
                    ),
                  ],
                ),
              ),
              // 💰 コインを見せた直後がリワード広告の一番刺さる位置。
              // ひとりプレイのこの画面だけ設置されていなかったので追加する。
              const SizedBox(height: 10),
              DoubleCoinsButton(coinsEarned: _coinsEarned),
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
            const SizedBox(height: 14),
            // 🛍 「次はどのキャラで遊ぶ？」でショップへ送る（他のリザルトと同じ導線）
            const StoreCtaCard(),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Sfx.instance.pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NameCallScreen(
                      doubleCard: widget.doubleCard,
                      customPeople: widget.customPeople,
                      peopleCount: widget.peopleCount,
                      nameAsYouGo: widget.nameAsYouGo,
                      autoNames: widget.autoNames,
                      quizMode: widget.quizMode,
                    ),
                  ),
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
