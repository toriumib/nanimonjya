/// 実績の定義。判定はローカルの戦績（PlayerProfile）に対して行う。
class Achievement {
  final String id;
  final String emoji;
  final int rewardCoins;

  const Achievement(this.id, this.emoji, this.rewardCoins);
}

const List<Achievement> kAchievements = [
  Achievement('first_play', '🎮', 30),
  Achievement('regular', '⭐', 100),
  Achievement('veteran', '👑', 300),
  Achievement('daily3', '🔥', 100),
  Achievement('daily7', '🗓️', 300),
  Achievement('binge5', '🚀', 150),
  Achievement('sharp20', '🧠', 120),
  Achievement('rich1000', '💰', 200),
];
