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
import '../models/cpu_difficulty.dart';
import '../models/person.dart';
import '../models/surnames.dart';
import '../services/ad_ids.dart';
import '../services/bgm.dart';
import '../models/cpu_rank.dart';
import '../services/interstitial_ad_helper.dart';
import '../services/memory_stats.dart';
import '../services/notify_prompt.dart';
import '../services/review_prompt.dart';
import '../services/app_analytics.dart';
import '../services/online_match_service.dart';
import '../services/custom_roster_service.dart'; // 顔メモの人も出演プールに入れる
import '../services/player_profile.dart';
import '../services/sfx.dart';
import '../widgets/celebration.dart';
import '../widgets/combo_badge.dart';
import '../widgets/double_coins_button.dart';
import '../widgets/face_view.dart';
import '../widgets/game_ui.dart';
import '../widgets/store_cta.dart';
import 'home_shell.dart';
import 'local_result_screen.dart';
import 'match_game_screen.dart' show PlatformDispatcherLocale, CpuLevel;
import 'online_result_screen.dart';
import 'rulebook_screen.dart';

/// メインモード「なまえがお」。
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
  final List<Person>? customPeople; // 自分の写真の名簿（各Person.nameが正解名）
  final int peopleCount; // 登場人数（6〜12）。カスタム/オンライン時は無視
  /// 1人あたりの札の枚数（2〜5）。多いほど同じ顔に何度も会う。
  final int? copiesPerPerson;

  final bool nameAsYouGo; // true=出たとき命名（1枚ずつ・初登場でその場命名）
  /// まとめて命名のとき、名前を自分で入力せず自動でつける（入力が面倒な人向け）。

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
    this.customPeople,
    this.peopleCount = NameCallGame.peopleCount,
    this.copiesPerPerson,
    // 🗑 命名ルールの切り替えと「2枚同時に出す」は廃止した（設定が多すぎて
    //    遊ぶ前に迷わせていた）。常に「出たとき命名」で動く。
    this.nameAsYouGo = true,
    this.quizMode = false,
    this.cpuLevel,
  });

  /// オンライン対戦の人数は**部屋が持っている**（`session.peopleCount`）。
  /// 両者で同じ人数にそろっていないと盤面がずれるので、
  /// フレンドマッチはホストの設定を部屋ごしにゲストへ配り、
  /// ランダムマッチは同じ人数の部屋どうしだけをマッチさせている。

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

class _NameCallScreenState extends State<NameCallScreen>
    with WidgetsBindingObserver {
  /// 🚪 プレイ中にアプリの外へ出た時刻。戻ってきた秒数を測るために持つ。
  ///
  /// ⚠️ **「飽きた」と「落ちた」を分けるために要る。**
  ///    dispose の [AppAnalytics.gameExit] はアプリ内で画面を離れたときしか
  ///    走らない。ホームボタンで外に出られると何も残らないので、
  ///    2026-08 は 229試合のうち102件が行方不明になっていた。
  DateTime? _leftAt;

  /// 🎉 いま出しているお祝いの帯。null なら出さない。
  ///
  /// ⚠️ **中身が変わったことをアニメに伝えるため、key に使う値を添える。**
  ///    同じ文字が続けて出たとき、key が同じだと跳ね直さない。
  ({String text, List<Color> colors, int id})? _banner;
  int _bannerSeq = 0;

  /// 🏆 勝ったときのフラッシュと紙吹雪を出しているか。
  bool _victory = false;

  /// ✨ 正解した瞬間の金キラ演出。カードの位置を中心に出す。
  int _sparkleKey = 0;

  /// 🖐 審判ボタンの連打よけ。直前のタップ時刻。
  ///
  /// ⚠️ **連打すると名前が付け直されていた。**
  ///    P1/P2 を素早く押したあと、指が「だれも思い出せなかった」に
  ///    当たると、その場で名前が振り直される（出たとき命名のルール）。
  ///    覚えたばかりの名前が勝手に変わるので、いちばん困る誤操作だった。
  DateTime? _lastClaimAt;

  /// 🔥 連続正解の数。まちがえた／時間切れで0に戻る。
  int _combo = 0;

  /// この試合の最高連続数。結果画面で見せる。
  int _bestCombo = 0;

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
  /// このラウンドをCPUが先に取ったか。
  /// CPUに点が入るのは「CPUが先に思い出したとき」だけ。
  /// プレイヤーのおてつきは没収ではなく、単に点が入らないだけにする。
  bool _cpuTookRound = false;
  /// このラウンドでCPUが先に取ったか（プレイヤーの回答を無効にするため）。

  // 回答タイマー（クイズモードのみ）
  Timer? _quizTimer;
  // ⏳「ゆとりの砂時計」を装備していると持ち時間が5秒のびる
  /// 1問の持ち時間。CPU対戦は難易度で変わる（むずかしいほど短い）。
  int get _answerSeconds =>
      _isCpu ? _diff.answerSeconds : NameCallGame.answerSeconds;
  /// 残り時間（0.1秒単位）。1秒刻みだと神モード（4秒）のバーが
  /// 4段階でしか動かず「時間に即していない」ように見えるため細かくする。
  int _timeLeft = NameCallGame.answerSeconds * 10;

  // 記録
  int _quizCorrect = 0;
  int _quizTotal = 0;
  /// カードが出てから回答するまでの時間（ms）。速さの指標に使う。
  DateTime? _quizShownAt;
  final List<int> _reactionTimes = [];
  int _ryoudoriCount = 0;

  // 報酬（一人プレイの終了ビューで表示）
  int _coinsEarned = 0;
  /// 🤖 CPU戦のボーナスコイン合計（終了画面で内訳を見せる）
  int _cpuBonus = 0;
  int _cpuCorrectCoins = 0; // 正解ぶん
  int _cpuPerfectCoins = 0; // 全問正解ぶん
  int _cpuWinCoins = 0; // 勝利ぶん
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
    WidgetsBinding.instance.addObserver(this);
    final ja = PlatformDispatcherLocale.isJa;
    // 🐣 かんたん（groupSize=1）は「1人覚える→1人答える」を2セットだけ。
    //    それ以外は選択人数（ひとり=6、みんなで=2〜12）。
    final count = _isOnline
        ? widget.online!.peopleCount.clamp(2, NameCallGame.maxPeople)
        : (_isCpu && _diff.groupSize == 1
            ? 2
            : widget.peopleCount.clamp(2, NameCallGame.maxPeople));
    // オンラインは両プレイヤーで顔が一致する必要があるため基本16人プールのまま。
    // オフライン/ひとりは購入済みキャラと、**顔メモで登録した人**も出演プールに加える。
    // （以前はキャラデッキに「自分で登録した人」の欄があるのに、
    //   実際の出演プールには入っておらず、ONにしても出てこなかった）
    final facePool = _isOnline
        ? null
        : buildFacePool(
            ja: ja, // 🌍 英語版は欧米系の顔ぶれ
            unlockedIds: PlayerProfile.instance.unlockedCharacters,
            excluded: PlayerProfile.instance.deckExcluded,
            customFaces: [
              for (final e in CustomRosterService.instance.entries)
                e.toFaceRef(),
            ],
          );
    // 🎴 デッキで絞った結果が必要人数より少ないと、生成器は基本の顔ぶれへ
    //    フォールバックしてしまい「OFFにしたキャラが出てくる」ことになる。
    //    デッキの意思を優先し、出演人数のほうをデッキの数に合わせる。
    final effectiveCount =
        facePool == null ? count : min(count, facePool.length);
    final people = _isCustom
        ? ([...widget.customPeople!]..shuffle(_rng))
        : (facePool == null
            ? generateImagePeople(effectiveCount, ja: ja, random: _rng)
            : generatePeopleFromFaces(effectiveCount,
                faces: facePool, random: _rng));
    _game = NameCallGame(
      people: people,
      rng: _rng,
      // 出たとき命名は必ず1枚ずつ（初登場で命名→再登場で想起の流れのため）
      cardsPerRound: 1,
      // 🤖 CPU対戦は難易度ぶんの人数をまとめて覚えてから思い出す。
      //    かんたん=1人ずつ、鬼=4人まとめて。カスタム名簿は命名済みなので対象外。
      // 🌐 オンラインは両端末で山札の枚数が一致しないと成立しないので、
      //    部屋に載せていない設定はここで既定へ戻す。
      // 🤖 CPU対戦は「各人1回だけ答える」（命名1回＋想起1回）にする。
      //    既定の4枚だと同じ名前を何度も答えることになり、単調で分かりにくい。
      copiesPerPerson: _isCpu ? 2 : (_isOnline ? null : widget.copiesPerPerson),
      groupSize: (_isCpu && !_isCustom)
          ? _diff.groupSize
          : 0,
    );
    if (_isCustom) {
      // カスタム名簿は名前つき済み → 命名フェーズをスキップして本編へ
      for (final p in people) {
        _game.roster[p] = p.name;
        _noteMet(p, p.name);
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
    if (PlayerProfile.instance.adsRemovedOrPremium) return;
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_finished) return;
    if (state == AppLifecycleState.paused) {
      _leftAt = DateTime.now();
      AppAnalytics.gameBackground(
        mode: _modeName,
        progressPct: _game.progressPct,
        card: _game.consumedCards,
        totalCards: _game.totalCards,
      );
    } else if (state == AppLifecycleState.resumed && _leftAt != null) {
      AppAnalytics.gameResume(
        mode: _modeName,
        awaySeconds: DateTime.now().difference(_leftAt!).inSeconds,
      );
      _leftAt = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    _noteMet(_namingPerson, name);
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
          // 🤖 CPU戦など「アプリが名前を決める」方式では、
          //    わざわざ命名ボタンを押させる意味がない。相手はCPUで
          //    相談もしないので、ここで名前を確定して見せるだけにする。
          //    プレイヤーの仕事は「つける」ことではなく「覚える」こと。
          if (!_isReferee) {
            final gachaName = _uniqueGachaName();
            _game.roster[card] = gachaName;
            _noteMet(card, gachaName);
          }
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
    _noteMet(_inlinePerson!, name);
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
    final ja = PlatformDispatcherLocale.isJa;
    final used = _game.roster.values.toSet();
    // 🏷 実在しそうな名前から選ぶ。造語のガチャ名だと
    //    「人の名前を覚える」練習として現実味がないため。
    final pool = [...commonNamePool(ja)]..shuffle(_rng);
    for (final s in pool) {
      final n = formatNameForLocale(s, ja);
      if (!used.contains(n)) return n;
    }
    // 100人ぶん使い切ったときだけ番号を足して必ず一意にする
    return '${formatNameForLocale(pool.first, ja)}${used.length + 1}';
  }

  /// クイズの4択を作る。名簿の名前が4つに満たないとき（出たとき命名の序盤や
  /// 少人数のカスタム名簿）は、実在しそうな名前で4つまで補充する。
  List<String> _buildChoices(Person card) {
    // ⚠️ 以前はおなまえガチャの造語（カタカナ）で埋めていたが、
    //    「モジャモン」のような選択肢が並ぶと明らかに正解でないと分かり、
    //    4択が実質2択になってしまう。実在しそうな名前で埋める。
    final ja = PlatformDispatcherLocale.isJa;
    return _game.choicesFor(
      card,
      filler: [for (final n in commonNamePool(ja)) formatNameForLocale(n, ja)],
    );
  }

  /// 難易度ごとの設定（覚える人数・持ち時間・報酬・CPUの手強さ）。
  /// 表と実際の挙動がずれないよう models/cpu_difficulty.dart に一本化してある。
  CpuDifficulty get _diff => cpuDifficultyOf(widget.cpuLevel);

  /// 🤖 CPUが「思い出す」までの時間を決める。
  /// 速すぎると理不尽なので、人が選択肢を読んで押せる範囲でばらつかせる。
  /// ときどきCPUも思い出せないことにして、取り返す余地を残す。
  void _startCpuTimer() {
    _cpuTimer?.cancel();
    _cpuTookRound = false;
    if (!_isCpu) return;
    // 難易度ごとの見逃し率。かんたんは35%、鬼は3%しか見逃さない
    if (_rng.nextInt(100) < _diff.cpuMissPct) return;
    final ms = _diff.cpuMinMs + _rng.nextInt(_diff.cpuVarianceMs);
    _cpuTimer = Timer(Duration(milliseconds: ms), _cpuAnswers);
  }

  /// CPUが先に思い出した。プレイヤーの回答を締め切ってCPUの取り分にする。
  void _cpuAnswers() {
    if (!mounted || _phase != _Phase.round || _answerLocked) return;
    _answer(null, takenByCpu: true);
  }

  /// 📊 「この人に会った」ことを成績レポートに記録する。
  /// 命名した時点が出会い。次にその顔が出て名前を答えるのが「2回目以降」になる。
  void _noteMet(Person p, String name) {
    MemoryStats.instance
        .recordMeeting(itemKey: MemoryStats.keyOf(face: p.face, name: name));
  }

  void _startQuizTimer() {
    _quizTimer?.cancel();
    _quizShownAt = DateTime.now();
    _timeLeft = _answerSeconds * 10; // 0.1秒単位
    _startCpuTimer();
    _quizTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
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
    final m = MetaStrings.of(context);
    _answerLocked = true;
    _quizTimer?.cancel();
    _cpuTimer?.cancel();
    final target = _round[_answering];
    final correct = choice != null && choice == _game.roster[target];
    _quizTotal += 1;
    // 📊 成績レポート用。カードが出てから答えるまでの時間と、
    //    命名済みの人を思い出せたかを記録する。
    final shownAt = _quizShownAt;
    final reactionMs = shownAt == null
        ? 0
        : DateTime.now().difference(shownAt).inMilliseconds;
    if (reactionMs > 0) _reactionTimes.add(reactionMs);
    MemoryStats.instance.record(
      mode: StatMode.nameCall,
      itemKey: MemoryStats.keyOf(
          face: target.face, name: _game.roster[target] ?? target.name),
      correct: correct,
      reactionMs: reactionMs,
    );
    // 📊 1問ごとの正誤・反応時間を Firebase Analytics にも送る（正答率・速度を測る）。
    AppAnalytics.answerLogged(
      mode: 'namecall',
      correct: correct,
      reactionMs: reactionMs,
      index: _answering + 1,
      total: _round.length,
    );
    _quizShownAt = null;
    if (correct) {
      _quizCorrect += 1;
      _combo += 1;
      if (_combo > _bestCombo) _bestCombo = _combo;
      Sfx.instance.correct();
      // ✨ 正解の瞬間に金キラ演出
      _sparkleKey += 1;
      // 🔥 続くほど手ごたえを強くする。同じ反応の繰り返しは飽きる。
      if (_combo >= 5) {
        HapticFeedback.heavyImpact();
        Sfx.instance.get();
      } else if (_combo >= 3) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    } else {
      _combo = 0; // 途切れる。ここが惜しさになる
      Sfx.instance.wrong();
      HapticFeedback.mediumImpact();
    }
    // CPUに先を越された、または自分がまちがえた場合はCPUの取り分になる
    if (takenByCpu) _cpuTookRound = true;
    _roundHits.add(correct && !takenByCpu);
    setState(() => _pickedChoice = choice ?? '__timeout__');

    Future.delayed(const Duration(milliseconds: 400), () {
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
      if (gained > 0) {
        Sfx.instance.get(); // 🎴 カードが手に入った音
        // 🔥 バナー（カードゲット！）はみんなで対戦のときだけ出す。
        //    ひとりではマル/×の結果が出れば十分で、表示はテンポを落とす。
        if (widget.humanPlayers > 1) {
          _showBanner(
            _combo >= 3 ? m.comboBanner(_combo) : m.cardGetBanner,
            _combo >= 3
                ? const [Color(0xFFFF3D6A), Color(0xFFFFC02E)]
                : const [Color(0xFFFF6A3D), Color(0xFFFFC02E)],
          );
        }
      }
      // 🤖 CPUに点が入るのは「CPUが先に思い出したとき」だけ。
      //    プレイヤーのおてつきは没収せず、誰の点にもならない。
      if (_isCpu && _cpuTookRound) _cardsWon[1] += 1;
      if (gained == _round.length && _round.length == 2) _ryoudoriCount += 1;
      if (_isOnline) widget.online!.reportProgress(_cardsWon[0]);
      _endRound();
    });
  }

  // ── 呼んで判定: 早かったプレイヤーをタップ、-1=だれも思い出せなかった ──
  void _claim(int player) {
    if (_phase != _Phase.round) return;
    final m = MetaStrings.of(context);
    // 🖐 連打よけ。400ms は「意図した2回目」には十分で、
    //    指が滑って続けて当たるぶんは弾ける長さ。
    final now = DateTime.now();
    final last = _lastClaimAt;
    if (last != null && now.difference(last).inMilliseconds < 400) return;
    _lastClaimAt = now;
    // ⚠️ 人数（2〜12）とカードの枚数は別で、`_cardsWon` は人数ぶん確保している。
    //    想定外の値で来ても範囲外にならないようにガードする。
    if (player >= 0 && player < _cardsWon.length) {
      _cardsWon[player] += 1;
      // 🔊 誰かが取った瞬間は、**1台をみんなで見ている場面**。
      //    小さい音だと気づかれないので、獲得音にコインを重ねて厚くする。
      Sfx.instance.get();
      Sfx.instance.coin();
      HapticFeedback.mediumImpact();
      // 誰が取ったかを、その人の色で出す（みんなで対戦のときだけ。
      // ひとりでは正誤の結果が出れば十分で、表示はテンポを落とす）。
      if (widget.humanPlayers > 1) {
        _showBanner(
          m.playerGotBanner(player + 1),
          _playerColors(player),
        );
      }
    } else {
      Sfx.instance.wrong();
      // 📛 みんなで（一台）＝審判モードでは、名前をつけた人が
      //    消えて「もう一度命名」になるのは混乱の元。名前は保持したまま
      //    「だれも取れなかった」として次へ進める。
      //    （出たとき命名＋審判モードでも同じ扱いにする）
    }
    _roundClaimer.add(player);

    if (_answering + 1 < _round.length) {
      setState(() => _answering += 1);
      return;
    }
    // りょうどり: 2枚とも同じプレイヤーが取ったら演出カウント
    if (_round.length == 2 &&
        _roundClaimer.length >= 2 &&
        _roundClaimer[0] >= 0 &&
        _roundClaimer[0] == _roundClaimer[1]) {
      _ryoudoriCount += 1;
    }
    _endRound();
  }

  /// 🎉 お祝いの帯を出す。0.9秒で勝手に消える。
  void _showBanner(String text, List<Color> colors) {
    _bannerSeq += 1;
    final id = _bannerSeq;
    setState(() => _banner = (text: text, colors: colors, id: id));
    Future.delayed(const Duration(milliseconds: 900), () {
      // あいだに次の帯が出ていたら、そちらを消さない
      if (mounted && _banner?.id == id) setState(() => _banner = null);
    });
  }

  void _endRound() {
    setState(() => _phase = _Phase.roundResult);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _nextRound();
    });
  }

  // ─────────────── 終了 ───────────────

  Future<void> _finishGame() async {
    setState(() {
      _phase = _Phase.reveal;
      _victory = true;
    });
    // 📖 みんなで／オンラインは、このあと専用の結果画面がある。
    //    そこへ行く前に「名簿公開！おぼえてた？」をもう1枚挟むと、
    //    結果を見るまでにタップが1回増える。**そのまま結果へ送る。**
    //    ⚠️ ひとり／CPU はこの画面が結果そのものなので飛ばさない。
    if (_isOnline || _isLocalMulti) {
      Future.delayed(const Duration(milliseconds: 1300), () {
        if (mounted) _goToResult();
      });
    }
    // ⚠️ 1.5秒で消す。ここが長いと次の1回に入る前に閉じられる。
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _victory = false);
    });
    _finished = true;
    // 🎵 **勝利の曲はどのモードでも鳴らす。**
    //    以前は「ひとり／CPU」の枝の中でしか呼んでおらず、
    //    みんなで（1台）とオンラインでは、直前の曲が鳴り続けていた。
    //    Web で「結果になってもシチリアーノのまま」だったのはこれ。
    Bgm.instance.playResult();
    // 📊 成績レポートに1回ぶんとして保存する（審判方式は個人の記録が取れないので除く）
    if (!_isReferee) {
      await MemoryStats.instance.finishSession(StatMode.nameCall);
    }
    AppAnalytics.gameEnd(mode: _modeName, topScore: _cardsWon.reduce(max));
    AppAnalytics.gameExit(
      mode: _modeName,
      reason: 'completed',
      progressPct: 100,
      people: _game.people.length,
    );
    // 📅 今週おぼえた人数。
    //    みんなで(審判方式)は誰か1人ではなく「その場で思い出せた枚数」を数える。
    //    ここを solo/cpu の分岐に入れていたため、メインモードの
    //    みんなでで遊んでも一生0のままだった。
    if (!_isOnline) {
      final recalled = _isReferee
          ? _cardsWon.fold<int>(0, (a, b) => a + b)
          : _quizCorrect;
      await PlayerProfile.instance.addWeeklyLearned(recalled);
    }
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
      // 🤖 CPU戦は勝敗を段位に反映し、難易度に応じたコインを出す。
      if (_isCpu) {
        final won = _cardsWon[0] > _cardsWon[1];
        final perfect = _quizTotal > 0 && _quizCorrect == _quizTotal;
        // ⚠️ 以前は「勝ったときの難易度ボーナス」しか無く、
        //    ぜんぶ思い出せても負けたら基本の10コインだけだった。
        //    答えた中身が報われないと、むずかしい難易度を選ぶ理由が無くなる。
        //    正解1問ごと（難易度で単価が変わる）＋全問正解＋勝利ボーナスの3段にする。
        _cpuCorrectCoins = _quizCorrect * _diff.coinsPerCorrect;
        _cpuPerfectCoins = perfect ? _diff.perfectBonus : 0;
        _cpuWinCoins = won ? _diff.winBonus : 0;
        _cpuBonus = _cpuCorrectCoins + _cpuPerfectCoins + _cpuWinCoins;
        if (_cpuBonus > 0) await profile.grantBonusCoins(_cpuBonus);
        if (won && perfect) {
          // 全問正解での勝利は専用キャラの解放条件
          await profile.markPerfectCpuWin();
        }
        await profile.recordCpuGame(
          level: widget.cpuLevel!.name,
          won: won,
          correctQuizzes: _quizCorrect,
          totalQuizzes: _quizTotal,
          avgReactionMs: _avgReactionMs,
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
      InterstitialAdHelper.instance.onGameFinished(); // 3プレイに1回
      if (_quizTotal > 0 && _quizCorrect == _quizTotal) {
        maybeAskReview(minGames: 0); // 全問正解の好タイミングでレビュー依頼
      }
      // 🔔 1ゲーム終えて「覚えられた／忘れていた」を体験した直後に、
      //    明日また思い出す約束を持ちかける。ここが7日維持率の分かれ目。
      if (mounted) await maybeAskNotify(context);
    }
  }

  /// 計測できた回答の平均反応時間（ms）。計測ゼロなら0。
  int get _avgReactionMs => _reactionTimes.isEmpty
      ? 0
      : _reactionTimes.reduce((a, b) => a + b) ~/ _reactionTimes.length;

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
            peopleCount: _game.people.length,
            // 📇 誰が誰だったかを結果でも出す。ただしアプリが本当の名前を
            //    知らない人（「名前をつけた！」で進んだ人）は伏せたまま。
            //    内部のガチャ名を出すと「言ってない名前」が並ぶ。
            people: _revealPeople(),
          ),
        ),
      );
    }
  }

  /// 結果画面に出す「誰が誰だったか」。
  /// 名簿の名前を Person に載せ替えて返す（アプリが知らない名前は除く）。
  List<Person> _revealPeople() => [
        for (final p in _game.people)
          if (!_secretNames.contains(p) && (_game.roster[p] ?? '').isNotEmpty)
            Person(
              face: p.face,
              kind: p.kind,
              name: _game.roster[p]!,
              hobby: p.hobby,
            ),
      ];

  // ─────────────── UI ───────────────

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    // ⚠️ 端末の戻るボタンは ×ボタン(_confirmQuit) を通らないため、
    //    そのままだと「オンラインで降参を送らずに離脱」できてしまい、
    //    相手が結果を待ち続けることになる。戻るも確認ダイアログに寄せる。
    //    ゲームが終わって結果・名簿公開まで来ていれば、そのまま閉じてよい。
    return PopScope(
      canPop: _phase == _Phase.roundResult || _phase == _Phase.reveal,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmQuit();
      },
      child: _buildGame(m),
    );
  }

  Widget _buildGame(MetaStrings m) {
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
                focus: _isOnline
                    ? RuleTopic.onlineFriend
                    : _isCpu
                        ? RuleTopic.cpu
                        : RuleTopic.nameCall,
                onDark: true,
              ),
            ),
          ),
        ],
        // 📏 ゲーム全体の進み具合。
        //
        // ⚠️ **60枚あるのに「あと何枚か」が分からなかった。**
        //    画面にあった進捗バーは回答の残り時間で、山札とは無関係。
        //    終わりが見えないと、途中で飽きて閉じられる。
        //    2026-08 は 229試合のうち102件が行方不明だった。
        // 山札を触っている間だけ出す。命名中・結果では出さない。
        bottom: (_phase == _Phase.round || _phase == _Phase.roundResult)
            ? PreferredSize(
                preferredSize: const Size.fromHeight(22),
                child: _deckProgress(),
              )
            : null,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
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
            // 🎉 お祝いは上に重ねるだけ。操作は止めない（IgnorePointer）
            if (_banner != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 96,
                child: Center(
                  child: GetBanner(
                    key: ValueKey(_banner!.id),
                    text: _banner!.text,
                    colors: _banner!.colors,
                  ),
                ),
              ),
            if (_victory) VictoryBurst(text: m.clearVictory),
            // ✨ 正解の瞬間に金キラ
            if (_sparkleKey > 0)
              _NameCallScreenState.goldSparkle(context),
          ],
        ),
      ),
    );
  }

  /// ✨ 正解したときの金キラエフェクト。0.6秒で消える。
  static Widget goldSparkle(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (_, t, child) {
            final scale = 0.5 + t * 2.0;
            final fade = (1 - t).clamp(0.0, 1.0);
            return Opacity(
              opacity: fade,
              child: Transform.scale(
                scale: scale,
                child: child,
              ),
            );
          },
          child: Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0x44FFD700),
                  Color(0x22FFC02E),
                  Color(0x00FFA500),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🖼 顔を出す大きさ。命名でも想起でも**同じ値**を使う。
  ///
  /// ⚠️ 固定値にすると狭い端末で溢れる。画面幅から入る大きさを出す。
  static double _faceSize(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return ((w - 48).clamp(140.0, 260.0)) - 24;
  }

  /// プレイヤーごとの色。帯とボタンで同じ色を使う。
  List<Color> _playerColors(int i) => const [
        [Color(0xFF3A7BD5), Color(0xFF62B6FF)],
        [Color(0xFFE8663C), Color(0xFFFFA26B)],
        [Color(0xFF2E9E5B), Color(0xFF7BE0C8)],
        [Color(0xFF8A5AC2), Color(0xFFC49BFF)],
      ][i % 4];

  Widget _buildNaming(MetaStrings m) {
    final namerIndex =
        _isLocalMulti ? _namingIndex % widget.humanPlayers : 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Column(
        children: [
          Text(
            m.namingProgress(_namingIndex + 1, _game.people.length),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
          if (_isLocalMulti) ...[
            const SizedBox(height: 2),
            Text(
              m.namingTurnPlayer('P${namerIndex + 1}'),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFE8663C)),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD8E4F0), width: 2),
            ),
            child: FaceView(
                person: _namingPerson, size: _faceSize(context), radius: 14),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            maxLength: 8,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            inputFormatters: [LengthLimitingTextInputFormatter(8)],
            decoration: InputDecoration(
              labelText: m.nameFieldLabel,
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onSubmitted: (_) => _submitName(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _rollGacha,
                  icon: const Text('🎲'),
                  label: Text(m.gachaLabel),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(42)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitName,
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(42)),
                  child: Text(m.namingNext),
                ),
              ),
            ],
          ),
          if (_namingIndex > 0) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Sfx.instance.pop();
                setState(() => _phase = _Phase.rosterReview);
              },
              icon: const Text('📖', style: TextStyle(fontSize: 14)),
              label: Text(m.namingMemorize),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2B5CA5),
                side: const BorderSide(color: Color(0xFF3A7BD5), width: 2),
                minimumSize: const Size.fromHeight(40),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              m.namingHint,
              style: const TextStyle(fontSize: 11, height: 1.4),
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
    return LayoutBuilder(builder: (context, box) {
      final faceSz = ((box.maxWidth - 60).clamp(120.0, 200.0) - 24);
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE9C7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _isReferee ? m.newComer : m.newComerNamed,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFC26A00)),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${m.namedSoFar}: $named / $total',
                    style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFC93C), width: 3),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x33FFC93C),
                      blurRadius: 12,
                      offset: Offset(0, 5)),
                ],
              ),
              child: FaceView(
                  person: _inlinePerson!, size: faceSz, radius: 14),
            )
                .animate(key: ValueKey(_inlinePerson))
                .fadeIn(duration: 240.ms)
                .scale(
                  begin: const Offset(0.7, 0.7),
                  end: const Offset(1, 1),
                  duration: 380.ms,
                  curve: Curves.easeOutBack,
                ),
            const SizedBox(height: 8),
            if (!_isReferee) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3D6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE6B54A), width: 2),
                ),
                child: Text(
                  _game.roster[_inlinePerson!] ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF7A5A00)),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Sfx.instance.pop();
                  HapticFeedback.selectionClick();
                  setState(() => _inlinePerson = null);
                  _nextRound();
                },
                icon: const Text('🧠', style: TextStyle(fontSize: 18)),
                label: Text(m.memorizedNext),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  textStyle:
                      const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () => _submitInlineName(autoNameIfEmpty: true),
                icon: const Text('✨', style: TextStyle(fontSize: 18)),
                label: Text(m.namedItAloud),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  minimumSize: const Size.fromHeight(48),
                  textStyle:
                      const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _nameWithGacha,
                icon: const Text('🎲', style: TextStyle(fontSize: 16)),
                label: Text(m.gachaNameIt),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2B5CA5),
                  side: const BorderSide(color: Color(0xFF3A7BD5), width: 2),
                  minimumSize: const Size.fromHeight(42),
                  textStyle:
                      const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _isReferee ? m.asYouGoHint : m.newComerNamedHint,
                style: const TextStyle(fontSize: 11, height: 1.4),
              ),
            ),
          ],
        ),
      );
    });
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
    return LayoutBuilder(builder: (context, box) {
      return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Column(
        children: [
          _scoreHeader(m),
          const SizedBox(height: 4),
          Row(
            key: ValueKey(_roundSeq),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _round.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                _roundCard(i, resultPhase, m, box.maxHeight),
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
          const SizedBox(height: 6),
          if (resultPhase)
            _roundResultBanner(m)
          else if (_isReferee)
            Expanded(child: _refereePanel(m))
          else
            Expanded(child: _quizPanel(m)),
        ],
      ),
      );
    });
  }

  /// 📏 山札の進み具合。「のこり◯枚」を必ず数字でも出す。
  /// バーだけだと、あと何回押せば終わるのかが伝わらない。
  Widget _deckProgress() {
    final m = MetaStrings.of(context);
    final total = _game.totalCards;
    final done = _game.consumedCards.clamp(0, total);
    final left = total - done;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: total == 0 ? 0 : done / total),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  minHeight: 6,
                  backgroundColor: Colors.white24,
                  color: const Color(0xFFFFC02E),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            left > 0 ? m.cardsLeft(left) : m.lastCardLabel,
            style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: Colors.white),
          ),
        ],
      ),
    );
  }

  // クイズパネル（ひとり／オンライン）— 1画面に収めるためスクロールなし
  Widget _quizPanel(MetaStrings m) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: _timeLeft / (_answerSeconds * 10),
            minHeight: 5,
            backgroundColor: Colors.grey.shade300,
            color: _timeLeft <= 30
                ? const Color(0xFFC62828)
                : const Color(0xFF3A7BD5),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ComboBadge(combo: _combo),
            const SizedBox(width: 8),
            Text(m.whoIsThis,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Column(
            children: [
              for (final c in _choices)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: SizedBox(
                      width: double.infinity,
                      child: _choiceButton(c),
                    ),
                  ),
                ),
            ],
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
      height: 44,
      radius: 10,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(c,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w900, color: fg)),
      ),
    );
  }

  // 審判パネル（オフライン対戦）: 一斉に名前を呼び、早かった人のボタンを押す
  Widget _refereePanel(MetaStrings m) {
    return Column(
      children: [
        Text(
          widget.humanPlayers <= 1
              ? m.soloRecallPrompt
              : (_round.length == 2
                  ? m.refereePromptCard(_answering + 1)
                  : m.refereePrompt),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(widget.humanPlayers <= 1 ? m.soloRecallHint : m.refereeHint,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.black54)),
        const SizedBox(height: 6),
        Expanded(
          child: LayoutBuilder(builder: (context, box) {
            final n = widget.humanPlayers;
            const gap = 10.0;
            final fontSize = n <= 2
                ? 22.0
                : n == 3
                    ? 18.0
                    : 15.0;
            return Row(
              children: [
                for (var i = 0; i < n; i++) ...[
                  if (i > 0) const SizedBox(width: gap),
                  Expanded(
                    child: JuicyButton(
                      onTap: () => _claim(i),
                      colors: _playerColors(i),
                      height: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.humanPlayers <= 1
                                ? m.soloGot
                                : m.playerGot('P${i + 1}'),
                            style: TextStyle(
                                fontFamily: kPopFont,
                                fontSize: fontSize,
                                color: Colors.white,
                                shadows: const [
                                  Shadow(
                                      offset: Offset(0, 2),
                                      color: Color(0x66000000)),
                                ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          }),
        ),
        const SizedBox(height: 16),
        JuicyButton(
          onTap: () => _claim(-1),
          colors: const [Color(0xFFF2F4F7), Color(0xFFDCE3EC)],
          edgeColor: const Color(0xFFB4C0CE),
          height: 42,
          child: Text(m.nobodyKnew,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF5A6A7A))),
        ),
      ],
    );
  }

  Widget _roundResultBanner(MetaStrings m) {
    // 💬 「どちらも取れなかった」は出さない。寂しい表示はテンポを落とすだけ。
    final bool missedAll;
    if (_isReferee) {
      missedAll = !_roundClaimer.any((c) => c >= 0);
    } else {
      missedAll = _roundHits.where((h) => h).isEmpty;
    }
    if (missedAll) return const SizedBox.shrink();

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
    final gold = color == const Color(0xFFE8A400) || color == const Color(0xFF2E9E5B);
    return Expanded(
      child: Center(
        child: gold
            ? ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFFC02E), Color(0xFFFF6A3D), Color(0xFFFFC02E)],
                ).createShader(bounds),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [
                      Shadow(offset: Offset(0, 2), blurRadius: 4, color: Color(0x66000000)),
                      Shadow(offset: Offset(0, 0), blurRadius: 14, color: Color(0x44FFD700)),
                    ],
                  ),
                ),
              )
            : Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w900, color: color),
              ),
      )
          .animate()
          .fadeIn(duration: 180.ms)
          .scale(
            begin: const Offset(0.6, 0.6),
            end: const Offset(1, 1),
            duration: 420.ms,
            curve: Curves.elasticOut,
          ),
    );
  }

  Widget _roundCard(int i, bool resultPhase, MetaStrings m, double maxH) {
    final person = _round[i];
    final claimed = i < _roundClaimer.length;
    final answered = i < _roundHits.length;
    // 現在処理中のカードをハイライト
    final active = !resultPhase && i == _answering;
    final ok = _isReferee ? (claimed && _roundClaimer[i] >= 0) : (answered && _roundHits[i]);
    final done = _isReferee ? claimed : answered;
    // 🖼 顔は大きいほうがいい。**顔を覚えるゲームなので、顔が主役。**
    //    以前は2枚並ぶと92pxしかなく、誰なのか見分けづらかった。
    //
    // ⚠️ 固定値で大きくすると、狭い端末で横に溢れる。
    //    画面幅から入る大きさを出して、そこで頭打ちにする。
    //    2枚のときは「(幅 - 余白) / 2」が上限。
    final single = _round.length == 1;
    final screenW = MediaQuery.of(context).size.width;
    final byWidth = single
        ? (screenW - 48).clamp(140.0, 260.0)
        : ((screenW - 60) / 2).clamp(110.0, 190.0);
    // ⚠️ **高さからも上限を出す。**
    //    得点欄・見出し・ボタンにも場所が要る。カードに使ってよいのは
    //    残り高さの半分くらいまで。ここを見ないと、P1/P2 のボタンが
    //    画面の外へ押し出されて押せなくなる。
    final byHeight = (maxH * 0.30).clamp(100.0, 220.0);
    final maxCard = byWidth < byHeight ? byWidth : byHeight;
    final cardWidth = (single ? 236.0 : 168.0).clamp(110.0, maxCard);
    // カードの内側の余白（12*2）を引いた残りが顔に使える。
    // 1枚のときは命名画面（_faceSize）とそろう。
    final faceSize = cardWidth - 24;
    // ✨ 正解したカードは金色に光らせる
    final won = done && ok;
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
          if (won)
            BoxShadow(
              color: const Color(0xFFFFC02E).withValues(alpha: 0.55),
              blurRadius: 20,
              spreadRadius: 2,
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
                fontSize: single ? 18 : 14,
                fontWeight: FontWeight.w900,
                color: won ? const Color(0xFFB8860B) : null),
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
                  // ⚠️ 4色しかないので人数（2〜12人）では % 4 で循環させる
                  border: Border.all(color: colors[i % 4], width: 2),
                ),
                child: Column(
                  children: [
                    Text('P${i + 1}',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: colors[i % 4])),
                    Text('${_cardsWon[i]}',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: colors[i % 4])),
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
          // ⚠️ _isSolo は _isCpu を除外する定義なので、ここを _isSolo だけに
          //    するとCPU戦の勝敗・コイン・参戦バナーが一切出ず、
          //    みんなで用の結果画面へ飛んでしまう。CPU戦もここで締める。
          if (_isSolo || _isCpu) ...[
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
                    Text(m.bestComboLabel(_bestCombo),
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    Text(
                        '🎯 ${_quizTotal == 0 ? 0 : _quizCorrect * 100 ~/ _quizTotal}%',
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
            // ⚡ 反応速度と 🏅 段位（ひとりで対戦のとき、自分の強さが実感できるように）
            if (_isCpu) ...[
              const SizedBox(height: 8),
              Builder(builder: (context) {
                final rank = cpuRankForRating(
                    PlayerProfile.instance.cpuRating);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('⚡ ${_avgReactionMs}ms',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF3A7BD5))),
                    Text(
                        '🏅 ${m.ja ? rank.nameJa : rank.nameEn} (${PlayerProfile.instance.cpuRating})',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF8A5AC2))),
                  ],
                );
              }),
            ],
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
                    // 何で稼げたのかを内訳で見せる。
                    // 「強い相手ほど1問の単価が高い」と分かると難易度を上げる気になる。
                    if (_cpuBonus > 0) ...[
                      const SizedBox(height: 4),
                      for (final line in [
                        if (_cpuCorrectCoins > 0)
                          m.cpuCorrectCoins(_quizCorrect, _cpuCorrectCoins),
                        if (_cpuPerfectCoins > 0)
                          m.cpuPerfectCoins(_cpuPerfectCoins),
                        if (_cpuWinCoins > 0) m.cpuWinCoins(_cpuWinCoins),
                      ])
                        Text(
                          line,
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
                      customPeople: widget.customPeople,
                      peopleCount: widget.peopleCount,
                      copiesPerPerson: widget.copiesPerPerson,
                      quizMode: widget.quizMode,
                      // CPU戦の再戦で難易度が消えないように引き継ぐ
                      cpuLevel: widget.cpuLevel,
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
    // 結果・名簿公開まで来ていれば、確認せずそのまま戻る。
    if (_phase == _Phase.roundResult || _phase == _Phase.reveal) {
      Navigator.of(context).pop();
      return;
    }
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
