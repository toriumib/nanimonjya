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

    const base = 10;
    final streakBonus = sessionStreak >= 2 ? (sessionStreak - 1) * 5 : 0;
    final total = base + streakBonus;
    await _addCoins(total);
    _checkAchievements();
    await _persist();
    notifyListeners();
    return GameReward(base: base, streakBonus: streakBonus, sessionStreak: sessionStreak);
  }

  /// リワード広告視聴などで追加コインを付与。
  Future<void> grantBonusCoins(int amount) async {
    await _addCoins(amount);
    _checkAchievements();
    await _persist();
    notifyListeners();
  }

  Future<void> _addCoins(int amount) async {
    coins += amount;
    lifetimeCoins += amount;
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
