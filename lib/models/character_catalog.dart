/// コインで購入して仲間にできる「追加キャラ」カタログ。
///
/// 画像は assets/images/char13.webp 〜 char32.webp（pubspec の assets/images/ で
/// ディレクトリごとバンドルされるため、ファイルを置くだけで有効化される）。
/// 未配置のうちは購入時にシルエット表示となる（クラッシュはしない）。
///
/// 購入したキャラは「なまえコール」と「ビジネス特訓」の出演プールに加わり、
/// 出会える顔ぶれが増える（ルールは変えない）。
/// 🏆 コインでは買えず、腕前で解放するキャラの条件。
enum UnlockFeat {
  /// CPU「つよい」に3回勝つ
  hardWins3,
  /// CPU「鬼」に1回勝つ
  oniWin1,
  /// CPU「鬼」に3回勝つ
  oniWins3,
  /// 通算50回あそぶ
  play50,
  /// 全問正解でCPUに勝つ
  perfectWin,
}

class GameCharacter {
  final String id; // 保存キー（例: 'c13'）
  final String asset; // 画像パス
  final String emoji; // ショップ表示のワンポイント
  final int cost; // 購入に必要なコイン

  /// null ならコインで買える通常キャラ。
  /// 値が入っているキャラは**コインでは買えず**、条件を満たすと参戦する。
  /// 「勝てば無料で手に入る」枠を少しだけ作ることで、
  /// 腕前の目標を用意しつつ、購入枠（14体）は残す。
  final UnlockFeat? feat;

  const GameCharacter({
    required this.id,
    required this.asset,
    required this.emoji,
    required this.cost,
    this.feat,
  });

  bool get isFeatCharacter => feat != null;
}

/// 追加キャラ19種（購入14＋実績解放5）。価格ラダー。
/// c13 は基本16人の無料枠へ昇格したのでここには無い。
const List<GameCharacter> kExtraCharacters = [
  GameCharacter(id: 'c14', asset: 'assets/images/char14.webp', emoji: '💇‍♀️', cost: 120),
  GameCharacter(id: 'c15', asset: 'assets/images/char15.webp', emoji: '💻', cost: 150),
  GameCharacter(id: 'c16', asset: 'assets/images/char16.webp', emoji: '🍠', cost: 150),
  GameCharacter(id: 'c17', asset: 'assets/images/char17.webp', emoji: '👗', cost: 180),
  GameCharacter(id: 'c18', asset: 'assets/images/char18.webp', emoji: '🍣', cost: 180),
  GameCharacter(id: 'c19', asset: 'assets/images/char19.webp', emoji: '🦅', cost: 260, feat: UnlockFeat.hardWins3),
  GameCharacter(id: 'c20', asset: 'assets/images/char20.webp', emoji: '🐎', cost: 260),
  GameCharacter(id: 'c21', asset: 'assets/images/char21.webp', emoji: '🕴️', cost: 200),
  GameCharacter(id: 'c22', asset: 'assets/images/char22.webp', emoji: '✊', cost: 200),
  GameCharacter(id: 'c23', asset: 'assets/images/char23.webp', emoji: '😤', cost: 220),
  GameCharacter(id: 'c24', asset: 'assets/images/char24.webp', emoji: '😊', cost: 180),
  GameCharacter(id: 'c25', asset: 'assets/images/char25.webp', emoji: '😷', cost: 180),
  GameCharacter(id: 'c26', asset: 'assets/images/char26.webp', emoji: '🎮', cost: 260, feat: UnlockFeat.oniWin1),
  GameCharacter(id: 'c27', asset: 'assets/images/char27.webp', emoji: '🕹️', cost: 300, feat: UnlockFeat.play50),
  GameCharacter(id: 'c28', asset: 'assets/images/char28.webp', emoji: '🤵', cost: 220),
  GameCharacter(id: 'c29', asset: 'assets/images/char29.webp', emoji: '🧪', cost: 340, feat: UnlockFeat.oniWins3),
  GameCharacter(id: 'c30', asset: 'assets/images/char30.webp', emoji: '🧘‍♀️', cost: 260),
  GameCharacter(id: 'c31', asset: 'assets/images/char31.webp', emoji: '👩‍🔬', cost: 340, feat: UnlockFeat.perfectWin),
  GameCharacter(id: 'c32', asset: 'assets/images/char32.webp', emoji: '☂️', cost: 200),
];

GameCharacter? extraCharacterById(String id) {
  for (final c in kExtraCharacters) {
    if (c.id == id) return c;
  }
  return null;
}

/// 購入済みキャラの画像パス一覧。
List<String> unlockedExtraAssets(Set<String> unlockedIds) => [
      for (final c in kExtraCharacters)
        if (unlockedIds.contains(c.id)) c.asset,
    ];

/// 🎴 キャラデッキ編集でOFFにしたキャラを出演プールから外す。
///
/// ゲームが成立しなくなるのを避けるため、除外した結果が [minimum] 未満に
/// なる場合は除外を無視して元のプールをそのまま返す。
List<String> applyDeckFilter(
  List<String> pool,
  Set<String> excluded, {
  int minimum = 4,
}) {
  if (excluded.isEmpty) return pool;
  final kept = [
    for (final a in pool)
      if (!excluded.contains(a)) a,
  ];
  return kept.length >= minimum ? kept : pool;
}
