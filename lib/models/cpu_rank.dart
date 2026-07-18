/// CPU対戦の段位（PlayerProfile.cpuRating から算出）。
class CpuRank {
  final String id;
  final String emoji;
  final String nameJa;
  final String nameEn;
  final int minRating;

  const CpuRank(this.id, this.emoji, this.nameJa, this.nameEn, this.minRating);
}

const List<CpuRank> kCpuRanks = [
  CpuRank('novice', '🐣', '見習い', 'Novice', 0),
  CpuRank('adept', '🥋', '一人前', 'Adept', 1000),
  CpuRank('expert', '🎯', '達人', 'Expert', 1200),
  CpuRank('master', '🧠', '名人', 'Master', 1400),
  CpuRank('oni', '👹', '鬼段位', 'Oni Rank', 1600),
];

/// レーティングから現在の段位を求める（kCpuRanksはminRating昇順の前提）。
CpuRank cpuRankForRating(int rating) {
  var current = kCpuRanks.first;
  for (final r in kCpuRanks) {
    if (rating >= r.minRating) current = r;
  }
  return current;
}

/// CPU難易度ごとの勝利時レーティング増加量。
const Map<String, int> kCpuWinRatingGain = {
  'easy': 10,
  'normal': 20,
  'hard': 30,
  'oni': 40,
};

/// 敗北時のレーティング減少量（共通）。
const int kCpuLossRatingLoss = 15;

/// レーティングの下限（沼らないためのフロア）。
const int kCpuRatingFloor = 400;

/// 鬼段位CPU（oni）を選択できるようになるレーティング。
const int kOniUnlockRating = 1500;
