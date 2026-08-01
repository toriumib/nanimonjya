/// 🤖 CPU対戦の難易度ごとの設定を1か所にまとめたもの。
///
/// これまで「勝ったときのコイン」は top_screen のボタン表示と
/// name_call_screen の付与処理に**別々の数字で書かれていて**、
/// 片方だけ直すと表示と実際の報酬が食い違う状態だった。
/// 難易度に関わる値はすべてここに置き、両方から参照する。
///
/// CpuLevel は screens/match_game_screen.dart にあるが、
/// models からUIを import したくないので、cpu_rank.dart と同じく
/// 文字列キー（'easy' / 'normal' / 'hard' / 'oni'）で引く。
class CpuDifficulty {
  /// 一度に覚える人数。この人数ぶん続けて登場して名前がつき、
  /// そのあと同じ顔ぶれが出題される。
  ///
  /// かんたん=1 なら「1人おぼえて、すぐその人が出る」。
  /// 鬼=4 なら「4人おぼえてから、4人ぶん答える」。
  /// 覚えてから思い出すまでに他の人が挟まるほど難しくなる。
  final int groupSize;

  /// 1問の回答制限時間（秒）。難しいほど短い。
  final int answerSeconds;

  /// 勝ったときの難易度ボーナス。
  final int winBonus;

  /// 正解1問ごとのコイン。負けても答えたぶんは報われるようにする。
  final int coinsPerCorrect;

  /// 全問正解したときの上乗せ。
  final int perfectBonus;

  /// CPUが思い出すまでの最短時間（ms）。
  final int cpuMinMs;

  /// CPUの思考時間のばらつき（ms）。
  final int cpuVarianceMs;

  /// CPUが思い出せずに見逃す確率（%）。
  final int cpuMissPct;

  final String emoji;

  const CpuDifficulty({
    required this.groupSize,
    required this.answerSeconds,
    required this.winBonus,
    required this.coinsPerCorrect,
    required this.perfectBonus,
    required this.cpuMinMs,
    required this.cpuVarianceMs,
    required this.cpuMissPct,
    required this.emoji,
  });

  /// この難易度で1ゲームに得られるコインの目安（表示用）。
  /// 出題数は人数と同じなので、全問正解して勝った場合の概算になる。
  int maxCoinsFor(int peopleCount) =>
      winBonus + coinsPerCorrect * peopleCount + perfectBonus;
}

/// 難易度ごとの設定表。
///
/// 覚える人数・持ち時間・報酬をまとめて上げ下げしている。
/// 「むずかしいほど短い時間で多く覚え、そのぶん多くもらえる」を
/// 3つの数字が同じ向きに動くようにそろえた。
const Map<String, CpuDifficulty> kCpuDifficulties = {
  'easy': CpuDifficulty(
    groupSize: 1,
    answerSeconds: 12,
    winBonus: 20,
    coinsPerCorrect: 3,
    perfectBonus: 10,
    cpuMinMs: 4200,
    cpuVarianceMs: 3500,
    cpuMissPct: 35,
    emoji: '🐣',
  ),
  'normal': CpuDifficulty(
    groupSize: 2,
    answerSeconds: 10,
    winBonus: 45,
    coinsPerCorrect: 6,
    perfectBonus: 25,
    cpuMinMs: 3000,
    cpuVarianceMs: 3000,
    cpuMissPct: 20,
    emoji: '🙂',
  ),
  'hard': CpuDifficulty(
    groupSize: 3,
    answerSeconds: 8,
    winBonus: 90,
    coinsPerCorrect: 10,
    perfectBonus: 50,
    cpuMinMs: 2000,
    cpuVarianceMs: 2200,
    cpuMissPct: 10,
    emoji: '🔥',
  ),
  'oni': CpuDifficulty(
    groupSize: 4,
    answerSeconds: 6,
    winBonus: 180,
    coinsPerCorrect: 16,
    perfectBonus: 100,
    cpuMinMs: 1300,
    cpuVarianceMs: 1400,
    cpuMissPct: 3,
    emoji: '👹',
  ),
};

/// CpuLevel（enum）や 'easy' などの文字列から設定を引く。
/// 見つからなければ ふつう を返す（想定外の値でゲームが止まらないように）。
CpuDifficulty cpuDifficultyOf(dynamic level) {
  if (level == null) return kCpuDifficulties['normal']!;
  final key = '$level'.split('.').last;
  return kCpuDifficulties[key] ?? kCpuDifficulties['normal']!;
}
