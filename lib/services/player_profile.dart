import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';

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
  Set<String> unlockedAchievements = {};
  Set<String> unlockedBgm = {'op9-2-Nocturne.mp3'}; // デフォルトBGMは最初から解放
  String selectedBgm = 'op9-2-Nocturne.mp3';
  Set<String> unlockedThemes = {'sunny'}; // ホーム着せ替え（デフォルトは最初から）
  String selectedTheme = 'sunny';
  String selectedResultBgm = 'shining_star.mp3'; // リザルト画面の曲
  int cheerLevel = 0; // チア応援団のレベル（0=なし、コインでアップグレード）
  String nickname = ''; // ランキング表示名
  int rankRating = 1000; // ランダムマッチのレーティング（Firestoreミラー）
  Set<String> unlockedCostumes = {'normal'}; // 応援団の衣装（デフォルトは所持）
  String selectedCostume = 'normal'; // 選択中の応援団衣装
  int dogAffection = 0; // 🐶なつき度（あそぶほど上がる）

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
    bestDailyStreak = p.getInt('bestDailyStreak') ?? 0;
    bestSessionStreak = p.getInt('bestSessionStreak') ?? 0;
    lastLoginDate = p.getString('lastLoginDate') ?? '';
    unlockedAchievements = (p.getStringList('achievements') ?? []).toSet();
    unlockedBgm =
        (p.getStringList('unlockedBgm') ?? ['op9-2-Nocturne.mp3']).toSet();
    unlockedBgm.add('op9-2-Nocturne.mp3');
    selectedBgm = p.getString('selectedBgm') ?? 'op9-2-Nocturne.mp3';
    if (!unlockedBgm.contains(selectedBgm)) {
      selectedBgm = 'op9-2-Nocturne.mp3';
    }
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
    missionDate = p.getString('missionDate') ?? '';
    missionPlays = p.getInt('missionPlays') ?? 0;
    missionCoinsEarned = p.getInt('missionCoinsEarned') ?? 0;
    missionOnline = p.getInt('missionOnline') ?? 0;
    missionClaimed = (p.getStringList('missionClaimed') ?? []).toSet();
    _refreshMissions();
    selectedResultBgm = p.getString('selectedResultBgm') ?? 'shining_star.mp3';
    // シャイニングスター以外はBGMショップでアンロック済みの曲のみ許可
    if (selectedResultBgm != 'shining_star.mp3' &&
        !unlockedBgm.contains(selectedResultBgm)) {
      selectedResultBgm = 'shining_star.mp3';
    }
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
    await _addCoins(reward);
    await _saveDaily();
    _checkAchievements();
    await _persist();
    notifyListeners();
    return reward;
  }

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
  static const int giftCooldownMinutes = 30;
  int _lastGiftMillis = 0;

  bool get canClaimGift {
    if (_lastGiftMillis == 0) return true;
    final elapsed = DateTime.now().millisecondsSinceEpoch - _lastGiftMillis;
    return elapsed >= giftCooldownMinutes * 60 * 1000;
  }

  Duration get giftCooldownRemaining {
    final next = _lastGiftMillis + giftCooldownMinutes * 60 * 1000;
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
    coins += reward;
    lifetimeCoins += reward;
    await _persist();
    notifyListeners();
    return true;
  }

  Future<void> _addCoins(int amount) async {
    coins += amount;
    lifetimeCoins += amount;
    _refreshMissions();
    missionCoinsEarned += amount; // 今日かせいだコイン（ミッション用）
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
  Future<void> selectResultBgm(String asset) async {
    if (asset != 'shining_star.mp3' && !unlockedBgm.contains(asset)) return;
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
      default:
        return false;
    }
  }

  Future<void> _saveDaily() async {
    final p = _prefs;
    if (p == null) return;
    await p.setInt('dailyStreak', dailyStreak);
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
    await p.setString('missionDate', missionDate);
    await p.setInt('missionPlays', missionPlays);
    await p.setInt('missionCoinsEarned', missionCoinsEarned);
    await p.setInt('missionOnline', missionOnline);
    await p.setStringList('missionClaimed', missionClaimed.toList());
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
