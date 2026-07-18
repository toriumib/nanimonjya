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
  // オンライン対戦トロフィー
  Achievement('online_debut', '🌐', 50),
  Achievement('online_win1', '🥇', 100),
  Achievement('online_win5', '🏅', 200),
  Achievement('online_win20', '🏆', 500),
  Achievement('random_debut', '🎲', 80),
  // 🧠 CPU対戦・認知トレーニング
  Achievement('cpu_win_easy', '🎮', 30),
  Achievement('cpu_win_normal', '🥋', 60),
  Achievement('cpu_win_hard', '🔥', 120),
  Achievement('cpu_win_oni', '👹', 250),
  Achievement('quiz_perfect', '💯', 100),
  Achievement('fast_reflex', '⚡', 80),
  Achievement('training_10', '🏋️', 150),
];
