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
  // ※旧オンライン対戦実績（online_debut等）はv2.0.0のルール刷新で撤去。
  //   解放済みユーザーのデータ（unlockedAchievements）はそのまま残るが表示されない。
  // 🧠 CPU対戦・認知トレーニング
  Achievement('cpu_win_easy', '🎮', 30),
  Achievement('cpu_win_normal', '🥋', 60),
  Achievement('cpu_win_hard', '🔥', 120),
  Achievement('cpu_win_oni', '👹', 250),
  Achievement('quiz_perfect', '💯', 100),
  Achievement('fast_reflex', '⚡', 80),
  Achievement('training_10', '🏋️', 150),
];
