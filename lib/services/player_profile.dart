import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';
import '../models/bgm_catalog.dart';
import '../models/character_catalog.dart';
import '../models/cpu_rank.dart';
import '../models/shop_items.dart';
import 'app_analytics.dart';
import 'daily_reminder.dart';

/// 端末ローカルに保存する戦績・コイン・実績などの「メタ層」状態。
/// 対戦ロジックとは独立。ChangeNotifier で UI に変化を通知する。
class PlayerProfile extends ChangeNotifier {
  PlayerProfile._();
  static final PlayerProfile instance = PlayerProfile._();

  SharedPreferences? _prefs;

  // 永続化する値
  int coins = 0;
  int lifetimeCoins = 0;
  int totalGames = 0;
  int highScore = 0;
  int onlineGames = 0; // オンライン対戦数
  int onlineWins = 0; // オンライン勝利数
  int randomMatches = 0; // ランダムマッチ参加数
  int dailyStreak = 0;
  int bestDailyStreak = 0;
  int bestSessionStreak = 0;
  String lastLoginDate = ''; // yyyy-mm-dd
  bool dailyClaimedToday = false;

  /// 📅 ハンコカレンダー: ボーナスを受け取った日（yyyy-mm-dd）。
  ///
  /// 『脳を鍛える大人のDSトレーニング』のハンコと同じ役目。
  /// 数字の「連続◯日」よりも、**空いたマスが目に見える**ほうが
  /// 通い続ける理由になる。増え続けると重いので直近90日だけ持つ。
  Set<String> stampDates = {};
  static const int _maxStamps = 90;
  Set<String> unlockedAchievements = {};
  /// ⚠️ **既定値は必ず [kFreeBgmAssets] から取ること。**
  ///    2026-08 に曲を8つ消したとき、ここが削除対象のファイル名の
  ///    ままだったため、そのまま出していれば全員が無音になっていた。
  Set<String> unlockedBgm = {...kFreeBgmAssets};
  String selectedBgm = kDefaultGameBgmAsset;
  Set<String> unlockedThemes = {'sunny'}; // ホーム着せ替え（デフォルトは最初から）
  String selectedTheme = 'sunny';
  String selectedResultBgm = kDefaultResultBgmAsset; // リザルト画面の曲
  /// 🏠 ホーム/試合前の曲。3場面（ホーム・試合中・リザルト）をそれぞれ選べる。
  /// 既定は [kHomeBgmRandom]（シチリアーノか運命をランダム）。
  String selectedHomeBgm = kHomeBgmRandom;
  int cheerLevel = 0; // チア応援団のレベル（0=なし、コインでアップグレード）
  String nickname = ''; // ランキング表示名
  int rankRating = 1000; // ランダムマッチのレーティング（Firestoreミラー）
  Set<String> unlockedCostumes = {'normal'}; // 応援団の衣装（デフォルトは所持）
  String selectedCostume = 'normal'; // 選択中の応援団衣装
  int dogAffection = 0; // 🐶なつき度（あそぶほど上がる）

  // 🧠 CPU対戦の段位・認知トレーニング統計
  int cpuRating = 1000; // CPU対戦の段位レーティング
  int cpuWins = 0;
  int cpuLosses = 0;
  int cpuEasyWins = 0;
  int cpuNormalWins = 0;
  int cpuHardWins = 0;
  int cpuOniWins = 0;
  /// 全問正解でCPUに勝ったことがあるか（実績キャラの解放条件）
  bool hadPerfectCpuWin = false;
  int bestQuizAccuracyPct = 0; // 1ゲーム内のベスト正答率(0-100)
  int bestAvgReactionMs = 0; // ベスト平均反応時間(ms)。0は未計測
  int soloTrainingSessions = 0; // 一人特訓モードの完了回数
  bool hadPerfectQuiz = false; // 5問以上のクイズで全問正解したことがあるか
  bool hadFastReflex = false; // 5問以上のクイズで平均反応1.5秒未満だったことがあるか
  bool reviewPrompted = false; // ストアレビュー依頼を出したことがあるか
  int reviewPromptCount = 0; // 依頼した回数（Google側の頻度制限で出ないことがあるため複数回試す）
  int reviewPromptedAtGames = 0; // 最後に依頼したときの総プレイ数

  // 🔔 練習リマインドの通知
  //
  // 7日維持率が伸びない一番の理由は「思い出すきっかけが無いまま忘れられる」こと。
  // 通知はその唯一の外からの合図なので、OSの許可を取れるかどうかが効いてくる。
  //
  // ⚠️ 以前は起動直後に何の説明もなくOSの許可ダイアログを出していた。
  //    Androidは一度断られると二度と出せないので、断られた時点で
  //    その人には永久に声をかけられなくなる。1ゲーム終えて価値が伝わった
  //    ところで、先にアプリ内で意思を聞いてから（ソフトアスク）
  //    OSの許可を求める形にした。
  /// 通知を受け取ることに同意したか（＝OSの許可を求めてよい）。
  bool notifyOptIn = false;
  /// アプリ内のお伺いを出した回数。しつこくしないための上限に使う。
  int notifyPromptCount = 0;
  /// 最後にお伺いを出したときの総プレイ数。間隔をあけるために使う。
  int notifyPromptedAtGames = 0;
  Set<String> unlockedCharacters = {}; // コインで購入した追加キャラのID
  /// 🔇 BGMを鳴らすか。効果音とは独立して切れる（音楽だけ邪魔なことがあるため）。
  bool bgmEnabled = true;

  /// 🌐 Web版で選んだ言語（nullなら端末の言語に従う）。
  /// shared_preferences に保存して次回も引き継ぐ。
  String? _webLocaleCode;
  String? get webLocaleCode => _webLocaleCode;
  Future<void> setWebLocale(String? code) async {
    _webLocaleCode = code;
    if (code == null) {
      await _prefs?.remove('webLocale');
    } else {
      await _prefs?.setString('webLocale', code);
    }
    notifyListeners();
  }

  /// 🎁 今日のキャラガチャを引いた日（yyyy-mm-dd）。
  /// 「1日1回タダで1体引ける」という戻ってくる理由を作るための仕組み。
  /// コインを貯めないと何も起きない状態だと、買うほど遊んでいない人が
  /// キャラに触れないまま離脱してしまう。
  String lastGachaDate = '';

  /// 📅 今週おぼえた人数（社会人向けの実感メーター）。
  /// 週が変わったら自動で0に戻す。
  int weeklyLearned = 0;
  /// 集計中の週の開始日（月曜, yyyy-mm-dd）
  String weekStartDate = '';

  /// 🎴 デッキから外したキャラの画像パス。空なら「全員出る」（既定）。
  /// 除外リスト方式にしているのは、キャラを買い足したり写真を登録したときに
  /// 自動でデッキに加わってほしいため（選択リスト方式だと毎回選び直しになる）。
  Set<String> deckExcluded = {};
  // 💳 広告除去を購入済みか（買い切り。バナーと全画面広告を出さなくなる）
  bool adsRemoved = false;
  /// 🔔 復習リマインドの時刻（時。既定19時）。自分で決めた時刻のほうが
  /// 生活の合図と結びつけやすく、習慣として続きやすいとされる。
  int reminderHour = 19;

  // 🌌 覚醒（プレステージ）: 鬼段位をきわめたら段位をリセットして
  // 永続コイン倍率を積み上げられる、終わりのない成長ループ
  int awakenings = 0;

  // 🛍 ショップ拡張アイテム（models/shop_items.dart）
  Set<String> unlockedVoices = {'none'}; // ほめボイス
  String selectedVoice = 'none';
  Set<String> unlockedCharms = {'none'}; // お守り（1つだけ装備）

  /// 📚 コインで開いた読み物のID。
  Set<String> unlockedArticles = {};

  /// 🛠 開発者モード。全部のアイテムを開けた状態にする（動作確認・撮影用）。
  ///
  /// ⚠️ 入れると持ち物が増えるだけで、**戻しても持ち物は元に戻らない**。
  ///    アイテムを取り上げるのは、間違って有効にした人のデータを
  ///    壊すことになるため、あえてやらない。
  bool devMode = false;
  String selectedCharm = 'none';

  // 🏪 日替わりショップ
  String dailyShopDate = '';
  Set<String> dailyShopBought = {}; // 今日買った日替わり品のID

  // 🎯 動画視聴スタンプラリー
  int adWatchStreak = 0;
  String lastAdWatchDate = '';
  Set<String> adStreakRewardsClaimed = {}; // 受け取り済みの日数報酬

  // ⚡ コインブースト（次の1ゲームだけ2倍）
  bool coinBoostActive = false;

  /// 🎯 動画スタンプ: 今日すでに動画を見たか
  bool get adWatchedToday {
    final today = DateTime.now();
    final d = '${today.year}-${today.month}-${today.day}';
    return lastAdWatchDate == d;
  }

  /// 🎯 スタンプラリーの今日の日数
  int get adStreakDay => adWatchStreak.clamp(1, 7);

  /// 🎯 動画視聴を記録。今日まだなら+1
  Future<void> recordAdWatch() async {
    final today = DateTime.now();
    final d = '${today.year}-${today.month}-${today.day}';
    if (lastAdWatchDate == d) return; // 今日もう見た
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final y = '${yesterday.year}-${yesterday.month}-${yesterday.day}';
    if (lastAdWatchDate == y) {
      adWatchStreak = (adWatchStreak + 1).clamp(1, 7);
    } else {
      adWatchStreak = 1;
    }
    lastAdWatchDate = d;
    await _persist();
    notifyListeners();
  }

  /// 📅 日替わりショップの日付が変わったらリセット
  void _refreshDailyShop() {
    final today = DateTime.now();
    final d = '${today.year}-${today.month}-${today.day}';
    if (dailyShopDate != d) {
      dailyShopDate = d;
      dailyShopBought.clear();
    }
  }

  // 📋 デイリーミッション（日付が変わるとリセット）
  String missionDate = '';
  int missionPlays = 0; // 今日あそんだ回数
  int missionCoinsEarned = 0; // 今日かせいだコイン
  int missionOnline = 0; // 今日オンラインであそんだ回数
  Set<String> missionClaimed = {}; // 受け取り済みミッションID

  // セッション内（アプリ起動中のみ）の連続プレイ数。再起動でリセット。
  int sessionStreak = 0;

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    coins = p.getInt('coins') ?? 0;
    lifetimeCoins = p.getInt('lifetimeCoins') ?? 0;
    totalGames = p.getInt('totalGames') ?? 0;
    highScore = p.getInt('highScore') ?? 0;
    onlineGames = p.getInt('onlineGames') ?? 0;
    onlineWins = p.getInt('onlineWins') ?? 0;
    randomMatches = p.getInt('randomMatches') ?? 0;
    dailyStreak = p.getInt('dailyStreak') ?? 0;
    stampDates = (p.getStringList('stampDates') ?? []).toSet();
    bestDailyStreak = p.getInt('bestDailyStreak') ?? 0;
    bestSessionStreak = p.getInt('bestSessionStreak') ?? 0;
    lastLoginDate = p.getString('lastLoginDate') ?? '';
    unlockedAchievements = (p.getStringList('achievements') ?? []).toSet();
    // 🎵 **消した曲を選んだままの人を救う。**（migrateBgmSelection のコメント参照）
    //    ホーム・リザルトの設定はこの下でも読むので、まとめてここで直す。
    final bgm = migrateBgmSelection(
      savedUnlocked: p.getStringList('unlockedBgm') ?? const [],
      savedGame: p.getString('selectedBgm'),
      savedResult: p.getString('selectedResultBgm'),
      savedHome: p.getString('selectedHomeBgm'),
    );
    unlockedBgm = bgm.unlocked;
    selectedBgm = bgm.game;
    unlockedThemes = (p.getStringList('unlockedThemes') ?? ['sunny']).toSet();
    unlockedThemes.add('sunny');
    selectedTheme = p.getString('selectedTheme') ?? 'sunny';
    if (!unlockedThemes.contains(selectedTheme)) {
      selectedTheme = 'sunny';
    }
    cheerLevel = p.getInt('cheerLevel') ?? 0;
    nickname = p.getString('nickname') ?? '';
    rankRating = p.getInt('rankRating') ?? 1000;
    _lastGiftMillis = p.getInt('lastGiftMillis') ?? 0;
    unlockedCostumes = (p.getStringList('unlockedCostumes') ?? ['normal']).toSet();
    unlockedCostumes.add('normal');
    selectedCostume = p.getString('selectedCostume') ?? 'normal';
    if (!unlockedCostumes.contains(selectedCostume)) selectedCostume = 'normal';
    dogAffection = p.getInt('dogAffection') ?? 0;
    cpuRating = p.getInt('cpuRating') ?? 1000;
    cpuWins = p.getInt('cpuWins') ?? 0;
    cpuLosses = p.getInt('cpuLosses') ?? 0;
    cpuEasyWins = p.getInt('cpuEasyWins') ?? 0;
    cpuNormalWins = p.getInt('cpuNormalWins') ?? 0;
    cpuHardWins = p.getInt('cpuHardWins') ?? 0;
    cpuOniWins = p.getInt('cpuOniWins') ?? 0;
    hadPerfectCpuWin = p.getBool('hadPerfectCpuWin') ?? false;
    bestQuizAccuracyPct = p.getInt('bestQuizAccuracyPct') ?? 0;
    bestAvgReactionMs = p.getInt('bestAvgReactionMs') ?? 0;
    soloTrainingSessions = p.getInt('soloTrainingSessions') ?? 0;
    hadPerfectQuiz = p.getBool('hadPerfectQuiz') ?? false;
    hadFastReflex = p.getBool('hadFastReflex') ?? false;
    reviewPrompted = p.getBool('reviewPrompted') ?? false;
    // 旧バージョンで1回頼み済みの人は、その1回を数えた状態から始める
    reviewPromptCount = p.getInt('reviewPromptCount') ?? (reviewPrompted ? 1 : 0);
    reviewPromptedAtGames = p.getInt('reviewPromptedAtGames') ?? 0;
    notifyOptIn = p.getBool('notifyOptIn') ?? false;
    notifyPromptCount = p.getInt('notifyPromptCount') ?? 0;
    notifyPromptedAtGames = p.getInt('notifyPromptedAtGames') ?? 0;
    unlockedCharacters = (p.getStringList('unlockedCharacters') ?? []).toSet();
    deckExcluded = (p.getStringList('deckExcluded') ?? []).toSet();
    bgmEnabled = p.getBool('bgmEnabled') ?? true;
    lastGachaDate = p.getString('lastGachaDate') ?? '';
    weeklyLearned = p.getInt('weeklyLearned') ?? 0;
    weekStartDate = p.getString('weekStartDate') ?? '';
    _refreshWeek();
    adsRemoved = p.getBool('adsRemoved') ?? false;
    reminderHour = (p.getInt('reminderHour') ?? 19).clamp(0, 23);
    awakenings = p.getInt('awakenings') ?? 0;
    unlockedVoices = (p.getStringList('unlockedVoices') ?? ['none']).toSet();
    unlockedVoices.add('none');
    selectedVoice = p.getString('selectedVoice') ?? 'none';
    if (!unlockedVoices.contains(selectedVoice)) selectedVoice = 'none';
    unlockedCharms = (p.getStringList('unlockedCharms') ?? ['none']).toSet();
    unlockedCharms.add('none');
    unlockedArticles = (p.getStringList('unlockedArticles') ?? []).toSet();
    devMode = p.getBool('devMode') ?? false;
    selectedCharm = p.getString('selectedCharm') ?? 'none';
    if (!unlockedCharms.contains(selectedCharm)) selectedCharm = 'none';
    missionDate = p.getString('missionDate') ?? '';
    missionPlays = p.getInt('missionPlays') ?? 0;
    missionCoinsEarned = p.getInt('missionCoinsEarned') ?? 0;
    missionOnline = p.getInt('missionOnline') ?? 0;
    missionClaimed = (p.getStringList('missionClaimed') ?? []).toSet();
    _refreshMissions();
    selectedHomeBgm = bgm.home;
    selectedResultBgm = bgm.result;
    _webLocaleCode = p.getString('webLocale');
    // 🏪 日替わりショップ + スタンプラリー
    dailyShopDate = p.getString('dailyShopDate') ?? '';
    dailyShopBought = (p.getStringList('dailyShopBought') ?? []).toSet();
    adWatchStreak = p.getInt('adWatchStreak') ?? 0;
    lastAdWatchDate = p.getString('lastAdWatchDate') ?? '';
    adStreakRewardsClaimed = (p.getStringList('adStreakRewards') ?? []).toSet();
    coinBoostActive = p.getBool('coinBoost') ?? false;
    _refreshDailyShop();
    _loaded = true;
    _refreshDailyState();
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 起動時に、今日のデイリーボーナスが受け取り可能かを判定する。
  void _refreshDailyState() {
    dailyClaimedToday = (lastLoginDate == _today());
    notifyListeners();
  }

  bool get canClaimDaily => !dailyClaimedToday;

  /// デイリーボーナスを受け取る。連続ログイン日数に応じて増加（上限あり）。
  /// 受け取ったコイン数を返す。既に受け取り済みなら 0。
  Future<int> claimDailyBonus() async {
    if (dailyClaimedToday) return 0;
    final today = _today();
    // 連続判定：前回が「昨日」なら継続、それ以外はリセット
    final yesterday = _dateString(DateTime.now().subtract(const Duration(days: 1)));
    if (lastLoginDate == yesterday) {
      dailyStreak += 1;
    } else {
      dailyStreak = 1;
    }
    if (dailyStreak > bestDailyStreak) bestDailyStreak = dailyStreak;

    // 20コインから+10ずつ、上限100
    final reward = (10 + dailyStreak * 10).clamp(20, 100);
    lastLoginDate = today;
    dailyClaimedToday = true;
    // 📅 今日のマスにハンコを押す
    stampDates.add(today);
    if (stampDates.length > _maxStamps) {
      final sorted = stampDates.toList()..sort();
      stampDates = sorted.sublist(sorted.length - _maxStamps).toSet();
    }
    await _addCoins(reward);
    await _saveDaily();
    _checkAchievements();
    await _persist();
    notifyListeners();
    // 📅 通い続けて解放されるキャラをここで受け取らせる
    await refreshFeatCharacters();
    AppAnalytics.dailyBonusClaimed(dailyStreak);
    DailyReminder.instance.onBonusClaimed(); // 今日のリマインド通知をスキップ
    return reward;
  }

  /// その日にハンコが押してあるか。
  bool hasStamp(DateTime d) => stampDates.contains(_dateString(d));

  String _dateString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// ゲームを1戦終えたときに呼ぶ。
  /// 基本報酬＋連続プレイボーナスを付与し、獲得コイン数と連続数を返す。
  Future<GameReward> recordGamePlayed(int myScore) async {
    totalGames += 1;
    sessionStreak += 1;
    if (sessionStreak > bestSessionStreak) bestSessionStreak = sessionStreak;
    if (myScore > highScore) highScore = myScore;
    dogAffection += 10; // 🐶あそぶほどなつく
    _refreshMissions();
    missionPlays += 1;

    const base = 10;
    final streakBonus = sessionStreak >= 2 ? (sessionStreak - 1) * 5 : 0;
    final total = base + streakBonus;
    await _addCoins(total);
    // 実績の解放はここでは行わない。リザルト画面が直後に refreshAchievements() を
    // 呼ぶので、そちらで解放してトースト表示の対象にする（ここで解放すると
    // 「新規解放」として検出されず通知が出ない）。
    await _persist();
    notifyListeners();
    return GameReward(base: base, streakBonus: streakBonus, sessionStreak: sessionStreak);
  }

  /// オンライン対戦を1戦終えたときに recordGamePlayed に加えて呼ぶ。
  /// 勝利時はボーナスコインを付与し、その額を返す（敗北時は 0）。
  Future<int> recordOnlineGame({
    required bool won,
    required bool isRandomMatch,
  }) async {
    onlineGames += 1;
    if (won) onlineWins += 1;
    if (isRandomMatch) randomMatches += 1;
    _refreshMissions();
    missionOnline += 1;
    int bonus = 0;
    if (won) {
      bonus = 20; // オンライン勝利ボーナス
      await _addCoins(bonus);
    }
    await _persist();
    notifyListeners();
    return bonus;
  }

  /// 新ルールのオンライン対戦（同時レース）を1戦終えたときに
  /// recordGamePlayed に加えて呼ぶ。勝敗カウント・コイン・段位レーティングを
  /// 更新し、新規解放実績を含めて結果を返す（引き分け時は呼ばない）。
  Future<CpuMatchResult> recordOnlineMatch({
    required bool won,
    required bool isRandomMatch,
  }) async {
    final before = cpuRating;
    onlineGames += 1;
    if (won) onlineWins += 1;
    if (isRandomMatch) randomMatches += 1;
    _refreshMissions();
    missionOnline += 1;
    if (won) {
      await _addCoins(30); // オンライン勝利ボーナス
      cpuRating += 25;
    } else {
      cpuRating = (cpuRating - 15).clamp(kCpuRatingFloor, 9999);
    }
    final newly = _checkAchievements();
    await _persist();
    notifyListeners();
    AppAnalytics.onlineMatchEnd(won: won, isRandomMatch: isRandomMatch);
    return CpuMatchResult(
      ratingDelta: cpuRating - before,
      ratingAfter: cpuRating,
      newlyUnlockedAchievements: newly,
    );
  }

  /// CPU対戦を1戦終えたときに recordGamePlayed に加えて呼ぶ。
  /// 段位レーティングを増減させ、クイズ正答率・平均反応時間のベストを更新し、
  /// 新たに解放された実績IDのリストを含めて結果を返す。
  Future<CpuMatchResult> recordCpuGame({
    required String level, // 'easy' | 'normal' | 'hard' | 'oni'
    required bool won,
    required int correctQuizzes,
    required int totalQuizzes,
    required int avgReactionMs,
  }) async {
    final before = cpuRating;
    if (won) {
      cpuWins += 1;
      switch (level) {
        case 'easy':
          cpuEasyWins += 1;
          break;
        case 'normal':
          cpuNormalWins += 1;
          break;
        case 'hard':
          cpuHardWins += 1;
          break;
        case 'oni':
          cpuOniWins += 1;
          break;
      }
      cpuRating += kCpuWinRatingGain[level] ?? 10;
    } else {
      cpuLosses += 1;
      cpuRating = (cpuRating - kCpuLossRatingLoss).clamp(kCpuRatingFloor, 9999);
    }
    _updateQuizStats(correctQuizzes, totalQuizzes, avgReactionMs);
    final newly = _checkAchievements();
    await _persist();
    notifyListeners();
    AppAnalytics.cpuMatchEnd(
      level: level,
      won: won,
      accuracyPct: totalQuizzes > 0 ? (correctQuizzes * 100 ~/ totalQuizzes) : 0,
      avgReactionMs: avgReactionMs,
    );
    return CpuMatchResult(
      ratingDelta: cpuRating - before,
      ratingAfter: cpuRating,
      newlyUnlockedAchievements: newly,
    );
  }

  /// 一人特訓モードを1セッション終えたときに呼ぶ。新規解放実績IDを返す。
  Future<List<String>> recordSoloTraining({
    required int correctQuizzes,
    required int totalQuizzes,
    required int avgReactionMs,
  }) async {
    soloTrainingSessions += 1;
    _updateQuizStats(correctQuizzes, totalQuizzes, avgReactionMs);
    final newly = _checkAchievements();
    await _persist();
    notifyListeners();
    AppAnalytics.soloTrainingEnd(
      accuracyPct: totalQuizzes > 0 ? (correctQuizzes * 100 ~/ totalQuizzes) : 0,
      avgReactionMs: avgReactionMs,
    );
    return newly;
  }

  void _updateQuizStats(int correctQuizzes, int totalQuizzes, int avgReactionMs) {
    if (totalQuizzes > 0) {
      final accuracyPct = (correctQuizzes * 100 ~/ totalQuizzes);
      if (accuracyPct > bestQuizAccuracyPct) bestQuizAccuracyPct = accuracyPct;
    }
    if (avgReactionMs > 0 && (bestAvgReactionMs == 0 || avgReactionMs < bestAvgReactionMs)) {
      bestAvgReactionMs = avgReactionMs;
    }
    // 実績の「最低5問」条件はここでゲートする（1問だけの100%を誤検知させないため）
    if (totalQuizzes >= 5) {
      if (correctQuizzes == totalQuizzes) hadPerfectQuiz = true;
      if (avgReactionMs > 0 && avgReactionMs < 1500) hadFastReflex = true;
    }
  }

  /// ストアレビュー依頼を出したことを記録する。
  /// 何回目か・そのときのプレイ数も残し、次に頼む間隔の判定に使う。
  Future<void> markReviewPrompted() async {
    reviewPrompted = true;
    reviewPromptCount += 1;
    reviewPromptedAtGames = totalGames;
    await _persist();
  }

  /// 🔔 アプリ内のお伺いを出したことを記録する（同意したかは [setNotifyOptIn]）。
  Future<void> markNotifyPrompted() async {
    notifyPromptCount += 1;
    notifyPromptedAtGames = totalGames;
    await _persist();
  }

  /// 🔔 通知を受け取るかどうかを切り替える。
  /// OFFにしたら予約済みの通知も消す（「あとで切れます」と伝えている以上、
  /// 切ったのに鳴り続けるのは約束違反になる）。
  Future<void> setNotifyOptIn(bool on) async {
    notifyOptIn = on;
    await _persist();
    if (on) {
      await DailyReminder.instance.scheduleNext();
    } else {
      await DailyReminder.instance.cancelAll();
    }
    notifyListeners();
  }

  /// ランキング表示名を設定。
  Future<void> setNickname(String name) async {
    nickname = name.trim();
    await _persist();
    notifyListeners();
  }

  /// 応援団の衣装をコインで解放。成功したら true。
  Future<bool> unlockCostume(String id, int cost) async {
    if (unlockedCostumes.contains(id)) return true;
    if (coins < cost) return false;
    coins -= cost;
    unlockedCostumes.add(id);
    await _persist();
    notifyListeners();
    return true;
  }

  /// 応援団の衣装を選択（所持済みのみ）。
  Future<void> selectCostume(String id) async {
    if (!unlockedCostumes.contains(id)) return;
    selectedCostume = id;
    await _persist();
    notifyListeners();
  }

  /// レーティングのローカルミラーを更新（Firestore側の確定値を渡す）。
  Future<void> setRankRating(int rating) async {
    rankRating = rating;
    await _persist();
    notifyListeners();
  }

  /// リワード広告視聴などで追加コインを付与。
  Future<void> grantBonusCoins(int amount) async {
    await _addCoins(amount);
    _checkAchievements();
    await _persist();
    notifyListeners();
  }

  // 🎁 動画で無料コインチェスト（クールダウン管理）
  // 30分→15分に短縮: 訪問頻度が上がるほどリワード広告の視聴機会が増える
  /// 🎁 無料コインチェストの待ち時間。
  /// 0 = 待ち時間なし（連続で受け取れる）。
  /// リワード広告は本人がボタンを押して見るものなので回数制限は設けない。
  /// 実際には広告在庫が尽きた時点で出なくなるため、そこが自然な上限になる。
  static const int giftCooldownMinutes = 0;
  int _lastGiftMillis = 0;

  int get effectiveGiftCooldownMinutes => giftCooldownMinutes;

  bool get canClaimGift {
    if (giftCooldownMinutes == 0) return true;
    if (_lastGiftMillis == 0) return true;
    final elapsed = DateTime.now().millisecondsSinceEpoch - _lastGiftMillis;
    return elapsed >= effectiveGiftCooldownMinutes * 60 * 1000;
  }

  Duration get giftCooldownRemaining {
    final next = _lastGiftMillis + effectiveGiftCooldownMinutes * 60 * 1000;
    final ms = next - DateTime.now().millisecondsSinceEpoch;
    return ms > 0 ? Duration(milliseconds: ms) : Duration.zero;
  }

  /// 無料コインチェストを受け取り（クールダウン開始）。付与額を返す。
  Future<int> claimGift(int amount) async {
    _lastGiftMillis = DateTime.now().millisecondsSinceEpoch;
    await _addCoins(amount);
    _checkAchievements();
    await _persist();
    notifyListeners();
    return amount;
  }

  // 日付が変わっていたらミッション進捗をリセット
  void _refreshMissions() {
    final today = _dateString(DateTime.now());
    if (missionDate != today) {
      missionDate = today;
      missionPlays = 0;
      missionCoinsEarned = 0;
      missionOnline = 0;
      missionClaimed = {};
    }
  }

  /// ミッション報酬を受け取る。成功したら true。
  Future<bool> claimMission(String id, int reward) async {
    _refreshMissions();
    if (missionClaimed.contains(id)) return false;
    missionClaimed.add(id);
    final scaled = _scaled(reward);
    coins += scaled;
    lifetimeCoins += scaled;
    await _persist();
    notifyListeners();
    return true;
  }

  /// 獲得コインにかかる倍率。
  /// 覚醒（1回につき+5%、上限なし）＋「招福こばん」を装備していると2倍。
  double get coinMultiplier {
    final m = 1.0 + awakenings * 0.05;
    return luckyCharmById(selectedCharm).effect == CharmEffect.coinBoost
        ? m * 2
        : m;
  }

  // ---- 🛍 ショップ拡張アイテム ----

  /// ほめボイスを購入。
  Future<bool> unlockVoice(String id, int cost) =>
      _buyInto(unlockedVoices, id, cost);

  Future<void> selectVoice(String id) async {
    if (!unlockedVoices.contains(id)) return;
    selectedVoice = id;
    await _persist();
    notifyListeners();
  }

  /// お守りを購入。
  Future<bool> unlockCharm(String id, int cost) =>
      _buyInto(unlockedCharms, id, cost);

  Future<void> selectCharm(String id) async {
    if (!unlockedCharms.contains(id)) return;
    selectedCharm = id;
    await _persist();
    notifyListeners();
  }



  /// 💳 広告除去の購入状態を反映する（購入時・復元時に呼ばれる）。
  Future<void> setAdsRemoved(bool value) async {
    if (adsRemoved == value) return;
    adsRemoved = value;
    await _persist();
    notifyListeners();
  }

  /// 🔔 練習リマインドの時刻を変える。変更したら通知を予約し直す。
  Future<void> setReminderHour(int hour) async {
    reminderHour = hour.clamp(0, 23);
    await _persist();
    await DailyReminder.instance.scheduleNext();
    notifyListeners();
  }

  /// コインを支払って集合に加える共通処理。
  Future<bool> _buyInto(Set<String> owned, String id, int cost) async {
    if (owned.contains(id)) return true;
    if (coins < cost) return false;
    coins -= cost;
    owned.add(id);
    await _persist();
    notifyListeners();
    return true;
  }

  int _scaled(int amount) => (amount * coinMultiplier).round();

  Future<void> _addCoins(int amount) async {
    final scaled = _scaled(amount);
    coins += scaled;
    lifetimeCoins += scaled;
    _refreshMissions();
    missionCoinsEarned += scaled; // 今日かせいだコイン（ミッション用）
  }

  /// 覚醒できる条件（鬼段位に到達し、鬼CPUに3勝以上）。
  bool get canAwaken =>
      cpuRating >= kCpuRanks.last.minRating && cpuOniWins >= 3;

  /// 覚醒する: 段位レーティングを見習いスタート相当にリセットし、
  /// 引き換えに永続コイン倍率を+5%積み上げる。何度でも繰り返せる。
  Future<bool> awaken() async {
    if (!canAwaken) return false;
    awakenings += 1;
    cpuRating = 1000;
    await _persist();
    notifyListeners();
    return true;
  }

  /// BGMをコインで解放。成功したら true。
  Future<bool> unlockBgm(String asset, int cost) async {
    if (unlockedBgm.contains(asset)) return true;
    if (coins < cost) return false;
    coins -= cost;
    unlockedBgm.add(asset);
    await _persist();
    notifyListeners();
    return true;
  }

  Future<void> selectBgm(String asset) async {
    if (!unlockedBgm.contains(asset)) return;
    selectedBgm = asset;
    await _persist();
    notifyListeners();
  }

  /// 全問正解でCPUに勝った記録をつける（実績キャラの解放条件）。
  Future<void> markPerfectCpuWin() async {
    if (hadPerfectCpuWin) return;
    hadPerfectCpuWin = true;
    await _persist();
    notifyListeners();
  }

  /// 🏆 腕前で解放するキャラの条件を満たしているか。
  bool hasFeat(UnlockFeat f) {
    switch (f) {
      case UnlockFeat.hardWins3:
        return cpuHardWins >= 3;
      case UnlockFeat.oniWin1:
        return cpuOniWins >= 1;
      case UnlockFeat.oniWins3:
        return cpuOniWins >= 3;
      case UnlockFeat.play50:
        return totalGames >= 50;
      case UnlockFeat.perfectWin:
        return hadPerfectCpuWin;
      // 📅 通い続けた日数で解放される枠。
      //    連続でなくても、これまでの最高記録で判定する
      //    （1日抜けたせいで永久に届かなくなると、続ける気が折れる）。
      case UnlockFeat.login3:
      case UnlockFeat.login7:
      case UnlockFeat.login14:
      case UnlockFeat.login30:
        final need = loginDaysFor(f);
        final best = dailyStreak > bestDailyStreak ? dailyStreak : bestDailyStreak;
        return best >= need;
    }
  }

  /// 条件を満たした実績キャラを解放する。新しく解放したIDを返す。
  /// 結果画面で「参戦！」を出すために使う。
  Future<List<String>> refreshFeatCharacters() async {
    final newly = <String>[];
    for (final c in kExtraCharacters) {
      final f = c.feat;
      if (f == null) continue;
      if (unlockedCharacters.contains(c.id)) continue;
      if (hasFeat(f)) {
        unlockedCharacters.add(c.id);
        newly.add(c.id);
      }
    }
    if (newly.isNotEmpty) {
      await _persist();
      notifyListeners();
    }
    return newly;
  }

  /// 追加キャラをコインで購入。成功したら true。
  /// 実績キャラはコインでは買えない（腕前でしか手に入らない枠）。
  Future<bool> unlockCharacter(String id, int cost) async {
    if (unlockedCharacters.contains(id)) return true;
    // 🏆 実績・📅 ログイン枠も**買える**。本筋は条件を満たすことだが、
    //    一生手に入らない枠があると、コインを貯める理由がそのぶん減る。
    //    値段を通常キャラよりかなり高くして差をつけてある。
    if (coins < cost) return false;
    coins -= cost;
    unlockedCharacters.add(id);
    await _persist();
    notifyListeners();
    return true;
  }

  /// 📚 読み物をコインで開く。足りなければ false。
  Future<bool> unlockArticle(String id, int cost) async {
    if (unlockedArticles.contains(id)) return true;
    if (coins < cost) return false;
    coins -= cost;
    unlockedArticles.add(id);
    await _persist();
    notifyListeners();
    return true;
  }

  bool hasArticle(String id) => unlockedArticles.contains(id);

  /// 🛠 開発者モードを入れる。全アイテムを開けた状態にする。
  ///
  /// 合言葉の確認は呼び出し側（マイページ）で済ませてから呼ぶこと。
  Future<void> enableDevMode({
    required Iterable<String> allThemes,
    required Iterable<String> allBgm,
    required Iterable<String> allCostumes,
    required Iterable<String> allCharacters,
    required Iterable<String> allVoices,
    required Iterable<String> allCharms,
    required Iterable<String> allArticles,
  }) async {
    devMode = true;
    unlockedThemes.addAll(allThemes);
    unlockedBgm.addAll(allBgm);
    unlockedCostumes.addAll(allCostumes);
    unlockedCharacters.addAll(allCharacters);
    unlockedVoices.addAll(allVoices);
    unlockedCharms.addAll(allCharms);
    unlockedArticles.addAll(allArticles);
    adsRemoved = true; // 撮影中に広告が挟まらないように
    await _persist();
    notifyListeners();
  }

  /// 🛠 開発者モードの表示だけを戻す（持ち物は取り上げない）。
  Future<void> disableDevMode() async {
    devMode = false;
    await _persist();
    notifyListeners();
  }

  /// 🎴 デッキの出演ON/OFFを切り替える。[assetPath] は画像パス
  /// （バンドルキャラは 'assets/images/...'、自分の写真は保存先ファイルパス）。
  Future<void> setDeckIncluded(String assetPath, bool included) async {
    if (included) {
      deckExcluded.remove(assetPath);
    } else {
      deckExcluded.add(assetPath);
    }
    await _persist();
    notifyListeners();
  }

  /// 🔇 BGMのON/OFF。切ったら即座に鳴っている曲を止める。
  Future<void> setBgmEnabled(bool on) async {
    bgmEnabled = on;
    await _persist();
    notifyListeners();
  }

  // ───────── 🎁 今日のキャラガチャ ─────────
  // 「1日1回タダで1体もらえる」だけで戻ってくる理由になる（ポケポケ型）。
  // コインを貯めないとキャラに触れない状態だと、買うほど遊んでいない人が
  // 32体の資産に一度も出会わないまま離脱してしまう。

  bool get canPullGacha => lastGachaDate != _today();

  /// まだ持っていない「コインで買える」キャラのID一覧。
  /// 実績キャラはガチャからも出さない（腕前でしか手に入らない枠を守る）。
  List<String> _gachaPool() => [
        for (final c in kExtraCharacters)
          if (!c.isFeatCharacter && !unlockedCharacters.contains(c.id)) c.id,
      ];

  /// 今日のガチャを引く。
  /// 当たったキャラIDを返す。全部持っているときは null を返し、
  /// 代わりにコインを渡す（引く動機を残すため）。
  Future<String?> pullDailyGacha({int consolationCoins = 80}) async {
    if (!canPullGacha) return null;
    lastGachaDate = _today();
    final pool = _gachaPool();
    if (pool.isEmpty) {
      coins += consolationCoins;
      lifetimeCoins += consolationCoins;
      await _persist();
      notifyListeners();
      return null;
    }
    final id = pool[DateTime.now().millisecondsSinceEpoch % pool.length];
    unlockedCharacters.add(id);
    await _persist();
    notifyListeners();
    return id;
  }

  // ───────── 📅 今週おぼえた人数 ─────────
  // 社会人向けの「実感」。勝ち負けより、実務で効いている感覚のほうが刺さる。

  /// 今週の月曜日（yyyy-mm-dd）。
  String _weekStart() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-'
        '${monday.day.toString().padLeft(2, '0')}';
  }

  /// 週が変わっていたらカウンタを0に戻す。
  void _refreshWeek() {
    final ws = _weekStart();
    if (weekStartDate != ws) {
      weekStartDate = ws;
      weeklyLearned = 0;
    }
  }

  /// 思い出せた人数を今週の記録に足す。
  Future<void> addWeeklyLearned(int n) async {
    if (n <= 0) return;
    _refreshWeek();
    weeklyLearned += n;
    await _persist();
    notifyListeners();
  }

  /// 全員をデッキに戻す。
  Future<void> resetDeck() async {
    deckExcluded.clear();
    await _persist();
    notifyListeners();
  }

  /// ホーム着せ替えテーマをコインで解放。成功したら true。
  Future<bool> unlockTheme(String id, int cost) async {
    if (unlockedThemes.contains(id)) return true;
    if (coins < cost) return false;
    coins -= cost;
    unlockedThemes.add(id);
    await _persist();
    notifyListeners();
    return true;
  }

  Future<void> selectTheme(String id) async {
    if (!unlockedThemes.contains(id)) return;
    selectedTheme = id;
    await _persist();
    notifyListeners();
  }

  /// チア応援団を1レベルアップグレード。成功したら true。
  Future<bool> upgradeCheer(int cost) async {
    if (coins < cost) return false;
    coins -= cost;
    cheerLevel += 1;
    await _persist();
    notifyListeners();
    return true;
  }

  /// リザルト画面の曲を選択（シャイニングスター or アンロック済みクラシック曲）
  /// 🏠 ホーム/試合前の曲を選ぶ。既定曲・おまかせは未購入でも選べる。
  Future<void> selectHomeBgm(String asset) async {
    if (asset != kHomeBgmAsset && asset != kHomeBgmRandom && !unlockedBgm.contains(asset)) return;
    selectedHomeBgm = asset;
    await _persist();
    notifyListeners();
  }

  Future<void> selectResultBgm(String asset) async {
    if (asset != kDefaultResultBgmAsset && !unlockedBgm.contains(asset)) return;
    selectedResultBgm = asset;
    await _persist();
    notifyListeners();
  }

  /// 実績条件を満たしているものを解放し、報酬コインを付与。
  /// 新たに解放された実績IDのリストを返す。
  List<String> _checkAchievements() {
    final newly = <String>[];
    for (final a in kAchievements) {
      if (unlockedAchievements.contains(a.id)) continue;
      if (_meetsAchievement(a.id)) {
        unlockedAchievements.add(a.id);
        coins += a.rewardCoins;
        lifetimeCoins += a.rewardCoins;
        newly.add(a.id);
      }
    }
    return newly;
  }

  /// 外部から実績チェックを促す（画面表示直後など）。新規解放IDを返す。
  Future<List<String>> refreshAchievements() async {
    final newly = _checkAchievements();
    if (newly.isNotEmpty) {
      await _persist();
      notifyListeners();
    }
    return newly;
  }

  bool _meetsAchievement(String id) {
    switch (id) {
      case 'first_play':
        return totalGames >= 1;
      case 'regular':
        return totalGames >= 10;
      case 'veteran':
        return totalGames >= 50;
      case 'daily3':
        return bestDailyStreak >= 3;
      case 'daily7':
        return bestDailyStreak >= 7;
      case 'binge5':
        return bestSessionStreak >= 5;
      case 'sharp20':
        return highScore >= 20;
      case 'rich1000':
        return lifetimeCoins >= 1000;
      case 'online_debut':
        return onlineGames >= 1;
      case 'online_win1':
        return onlineWins >= 1;
      case 'online_win5':
        return onlineWins >= 5;
      case 'online_win20':
        return onlineWins >= 20;
      case 'random_debut':
        return randomMatches >= 1;
      case 'cpu_win_easy':
        return cpuEasyWins >= 1;
      case 'cpu_win_normal':
        return cpuNormalWins >= 1;
      case 'cpu_win_hard':
        return cpuHardWins >= 1;
      case 'cpu_win_oni':
        return cpuOniWins >= 1;
      case 'quiz_perfect':
        return hadPerfectQuiz;
      case 'fast_reflex':
        return hadFastReflex;
      case 'training_10':
        return soloTrainingSessions >= 10;
      default:
        return false;
    }
  }

  Future<void> _saveDaily() async {
    final p = _prefs;
    if (p == null) return;
    await p.setInt('dailyStreak', dailyStreak);
    await p.setStringList('stampDates', stampDates.toList());
    await p.setInt('bestDailyStreak', bestDailyStreak);
    await p.setString('lastLoginDate', lastLoginDate);
  }

  Future<void> _persist() async {
    final p = _prefs;
    if (p == null) return;
    await p.setInt('coins', coins);
    await p.setInt('lifetimeCoins', lifetimeCoins);
    await p.setInt('totalGames', totalGames);
    await p.setInt('highScore', highScore);
    await p.setInt('onlineGames', onlineGames);
    await p.setInt('onlineWins', onlineWins);
    await p.setInt('randomMatches', randomMatches);
    await p.setInt('dailyStreak', dailyStreak);
    await p.setInt('bestDailyStreak', bestDailyStreak);
    await p.setInt('bestSessionStreak', bestSessionStreak);
    await p.setString('lastLoginDate', lastLoginDate);
    await p.setStringList('achievements', unlockedAchievements.toList());
    await p.setStringList('unlockedBgm', unlockedBgm.toList());
    await p.setString('selectedBgm', selectedBgm);
    await p.setStringList('unlockedThemes', unlockedThemes.toList());
    await p.setString('selectedTheme', selectedTheme);
    await p.setString('selectedResultBgm', selectedResultBgm);
    await p.setInt('cheerLevel', cheerLevel);
    await p.setString('nickname', nickname);
    await p.setInt('rankRating', rankRating);
    await p.setInt('lastGiftMillis', _lastGiftMillis);
    await p.setStringList('unlockedCostumes', unlockedCostumes.toList());
    await p.setString('selectedCostume', selectedCostume);
    await p.setInt('dogAffection', dogAffection);
    await p.setInt('cpuRating', cpuRating);
    await p.setInt('cpuWins', cpuWins);
    await p.setInt('cpuLosses', cpuLosses);
    await p.setInt('cpuEasyWins', cpuEasyWins);
    await p.setInt('cpuNormalWins', cpuNormalWins);
    await p.setInt('cpuHardWins', cpuHardWins);
    await p.setInt('cpuOniWins', cpuOniWins);
    await p.setInt('bestQuizAccuracyPct', bestQuizAccuracyPct);
    await p.setInt('bestAvgReactionMs', bestAvgReactionMs);
    await p.setInt('soloTrainingSessions', soloTrainingSessions);
    await p.setBool('hadPerfectQuiz', hadPerfectQuiz);
    await p.setBool('hadFastReflex', hadFastReflex);
    await p.setBool('reviewPrompted', reviewPrompted);
    await p.setInt('reviewPromptCount', reviewPromptCount);
    await p.setInt('reviewPromptedAtGames', reviewPromptedAtGames);
    await p.setBool('notifyOptIn', notifyOptIn);
    await p.setInt('notifyPromptCount', notifyPromptCount);
    await p.setInt('notifyPromptedAtGames', notifyPromptedAtGames);
    await p.setStringList('unlockedCharacters', unlockedCharacters.toList());
    await p.setStringList('unlockedArticles', unlockedArticles.toList());
    await p.setBool('devMode', devMode);
    await p.setStringList('deckExcluded', deckExcluded.toList());
    await p.setBool('hadPerfectCpuWin', hadPerfectCpuWin);
    await p.setBool('bgmEnabled', bgmEnabled);
    await p.setString('selectedHomeBgm', selectedHomeBgm);
    await p.setString('lastGachaDate', lastGachaDate);
    await p.setInt('weeklyLearned', weeklyLearned);
    await p.setString('weekStartDate', weekStartDate);
    await p.setBool('adsRemoved', adsRemoved);
    await p.setInt('reminderHour', reminderHour);
    await p.setInt('awakenings', awakenings);
    await p.setStringList('unlockedVoices', unlockedVoices.toList());
    await p.setString('selectedVoice', selectedVoice);
    await p.setStringList('unlockedCharms', unlockedCharms.toList());
    await p.setString('selectedCharm', selectedCharm);
    await p.setString('missionDate', missionDate);
    await p.setInt('missionPlays', missionPlays);
    await p.setInt('missionCoinsEarned', missionCoinsEarned);
    await p.setInt('missionOnline', missionOnline);
    await p.setStringList('missionClaimed', missionClaimed.toList());
    // 🏪 日替わりショップ + スタンプラリー
    await p.setString('dailyShopDate', dailyShopDate);
    await p.setStringList('dailyShopBought', dailyShopBought.toList());
    await p.setInt('adWatchStreak', adWatchStreak);
    await p.setString('lastAdWatchDate', lastAdWatchDate);
    await p.setStringList('adStreakRewards', adStreakRewardsClaimed.toList());
    await p.setBool('coinBoost', coinBoostActive);
  }

  /// ⚡ コインブーストを有効化
  Future<void> activateCoinBoost() async {
    if (coinBoostActive) return;
    if (coins < 20) return;
    coins -= 20;
    coinBoostActive = true;
    await _persist();
    notifyListeners();
  }

  /// ⚡ コインブーストを使って消費
  int applyBoost(int amount) {
    if (!coinBoostActive) return amount;
    coinBoostActive = false;
    final doubled = amount * 2;
    _persist(); // fire and forget
    notifyListeners();
    return doubled;
  }

  /// 📅 日替わりショップで購入
  Future<bool> buyDailyShopItem(String itemId, int cost) async {
    if (coins < cost) return false;
    if (dailyShopBought.contains(itemId)) return false;
    coins -= cost;
    dailyShopBought.add(itemId);
    await _persist();
    notifyListeners();
    return true;
  }
}

class GameReward {
  final int base;
  final int streakBonus;
  final int sessionStreak;
  const GameReward({
    required this.base,
    required this.streakBonus,
    required this.sessionStreak,
  });
  int get total => base + streakBonus;
}

class CpuMatchResult {
  final int ratingDelta;
  final int ratingAfter;
  final List<String> newlyUnlockedAchievements;
  const CpuMatchResult({
    required this.ratingDelta,
    required this.ratingAfter,
    required this.newlyUnlockedAchievements,
  });
}
