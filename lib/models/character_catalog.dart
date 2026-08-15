import 'person.dart'; // 出演プールの顔（FaceRef）とバンドルのキャラ画像

/// コインで購入して仲間にできる「追加キャラ」カタログ。
///
/// 画像は assets/images/char14.webp 〜 char32.webp（pubspec の assets/images/ で
/// ディレクトリごとバンドルされるため、ファイルを置くだけで有効化される）。
/// 未配置のうちは購入時にシルエット表示となる（クラッシュはしない）。
///
/// 購入したキャラは「なまえがお」と「ビジネス特訓」の出演プールに加わり、
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

  /// 📅 ログインボーナスで手に入る（続けた日数で解放）。
  /// 買うのではなく**通い続けた人だけ**が受け取れる枠。
  login3,
  login7,
  login14,
  login30,
}

/// ログインボーナスで解放される条件か。
bool isLoginFeat(UnlockFeat f) =>
    f == UnlockFeat.login3 ||
    f == UnlockFeat.login7 ||
    f == UnlockFeat.login14 ||
    f == UnlockFeat.login30;

/// その条件に必要な連続ログイン日数（ログイン枠でなければ0）。
int loginDaysFor(UnlockFeat f) => switch (f) {
      UnlockFeat.login3 => 3,
      UnlockFeat.login7 => 7,
      UnlockFeat.login14 => 14,
      UnlockFeat.login30 => 30,
      _ => 0,
    };

class GameCharacter {
  final String id; // 保存キー（例: 'c13'）
  final String asset; // 画像パス
  final String emoji; // ショップ表示のワンポイント
  final int cost; // 購入に必要なコイン

  /// null ならコインで買える通常キャラ。
  ///
  /// 値が入っているキャラは、条件（試合の腕前・通い続けた日数）を
  /// 満たせば**タダで**参戦する。
  ///
  /// ⚠️ 以前はコインでは**一切買えなかった**。条件に届かない人には
  ///    一生手に入らず、コインを貯める理由がそのぶん減っていた。
  ///    いまは買えるが、[cost] を通常キャラよりかなり高くしてある。
  ///    「条件を満たすのが本筋、どうしても欲しければ高く払う」形。
  final UnlockFeat? feat;

  const GameCharacter({
    required this.id,
    required this.asset,
    required this.emoji,
    required this.cost,
    this.feat,
  });

  bool get isFeatCharacter => feat != null;

  /// 📅 ログインを続けると手に入る枠か。
  bool get isLoginCharacter => feat != null && isLoginFeat(feat!);
}

/// 追加キャラ19種（購入14＋実績解放5）。価格ラダー。
/// ⚠️ c13 は**欠番**。無料枠へ昇格させたあと取り下げたので、どこにも無い。
/// IDを使い回すと、以前買った人の unlockedCharacters が別のキャラを指す。
const List<GameCharacter> kExtraCharacters = [
  GameCharacter(id: 'c14', asset: 'assets/images/char14.webp', emoji: '💇‍♀️', cost: 120),
  GameCharacter(id: 'c15', asset: 'assets/images/char15.webp', emoji: '💻', cost: 150),
  GameCharacter(id: 'c16', asset: 'assets/images/char16.webp', emoji: '🍠', cost: 150),
  GameCharacter(id: 'c17', asset: 'assets/images/char17.webp', emoji: '👗', cost: 180),
  GameCharacter(id: 'c18', asset: 'assets/images/char18.webp', emoji: '🍣', cost: 180),
  GameCharacter(id: 'c19', asset: 'assets/images/char19.webp', emoji: '🦅', cost: 650, feat: UnlockFeat.hardWins3),
  GameCharacter(id: 'c20', asset: 'assets/images/char20.webp', emoji: '🐎', cost: 260),
  GameCharacter(id: 'c21', asset: 'assets/images/char21.webp', emoji: '🕴️', cost: 200),
  GameCharacter(id: 'c22', asset: 'assets/images/char22.webp', emoji: '✊', cost: 200),
  GameCharacter(id: 'c23', asset: 'assets/images/char23.webp', emoji: '😤', cost: 220),
  GameCharacter(id: 'c24', asset: 'assets/images/char24.webp', emoji: '😊', cost: 180),
  GameCharacter(id: 'c25', asset: 'assets/images/char25.webp', emoji: '😷', cost: 180),
  GameCharacter(id: 'c26', asset: 'assets/images/char26.webp', emoji: '🎮', cost: 650, feat: UnlockFeat.oniWin1),
  GameCharacter(id: 'c27', asset: 'assets/images/char27.webp', emoji: '🕹️', cost: 700, feat: UnlockFeat.play50),
  GameCharacter(id: 'c28', asset: 'assets/images/char28.webp', emoji: '🤵', cost: 220),
  GameCharacter(id: 'c29', asset: 'assets/images/char29.webp', emoji: '🧪', cost: 800, feat: UnlockFeat.oniWins3),
  GameCharacter(id: 'c30', asset: 'assets/images/char30.webp', emoji: '🧘‍♀️', cost: 260),
  GameCharacter(id: 'c31', asset: 'assets/images/char31.webp', emoji: '👩‍🔬', cost: 800, feat: UnlockFeat.perfectWin),
  GameCharacter(id: 'c32', asset: 'assets/images/char32.webp', emoji: '☂️', cost: 200),
  // ── 🆕 追加キャラ（ユーザー提供の実写フリー素材） ──
  // 通常枠は120〜340コイン。実績・ログイン枠は「本来タダで取れる」ので
  // コインで買うなら高い（600〜900）。
  GameCharacter(id: 'c33', asset: 'assets/images/161007-128_TP_V4.webp', emoji: '🧑‍💼', cost: 160),
  GameCharacter(id: 'c34', asset: 'assets/images/24191780_m.jpg', emoji: '🙋', cost: 160),
  GameCharacter(id: 'c35', asset: 'assets/images/25437893_s.jpg', emoji: '😌', cost: 180),
  GameCharacter(id: 'c36', asset: 'assets/images/ELFAyukata0704DSC01201_TP_V4.webp', emoji: '🎐', cost: 240),
  GameCharacter(id: 'c37', asset: 'assets/images/TSURU1891A014_TP_V4.webp', emoji: '🍶', cost: 200),
  GameCharacter(id: 'c38', asset: 'assets/images/datumouFTHG7300_TP_V4.webp', emoji: '💈', cost: 180),
  GameCharacter(id: 'c39', asset: 'assets/images/maxeIMGL8767_TP_V.jpg', emoji: '📷', cost: 200),
  GameCharacter(id: 'c40', asset: 'assets/images/model10211001_TP_V4.webp', emoji: '👠', cost: 220),
  GameCharacter(id: 'c41', asset: 'assets/images/nikumanFTHG2263_TP_V4.webp', emoji: '🥟', cost: 180),
  GameCharacter(id: 'c42', asset: 'assets/images/nissinIMGL0808_TP_V4.webp', emoji: '🍜', cost: 200),
  GameCharacter(id: 'c43', asset: 'assets/images/tuchimoto07100I9A6655_TP_V4.webp', emoji: '🧑‍🏫', cost: 220),
  // 📅 ログインを続けると手に入る4体（コインでも買えるが高い）
  GameCharacter(id: 'c44', asset: 'assets/images/mikoFTHG2083_TP_V4.webp', emoji: '⛩️', cost: 600, feat: UnlockFeat.login3),
  GameCharacter(id: 'c45', asset: 'assets/images/miuFTHG2011_TP_V4.webp', emoji: '🌸', cost: 700, feat: UnlockFeat.login7),
  GameCharacter(id: 'c46', asset: 'assets/images/yotakasanFTHG0883_TP_V4.webp', emoji: '🏮', cost: 800, feat: UnlockFeat.login14),
  GameCharacter(id: 'c47', asset: 'assets/images/yuka522032_TP_V.jpg', emoji: '👑', cost: 900, feat: UnlockFeat.login30),
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

/// 🎬 ゲームに出す顔の土台（基本の顔ぶれ＋買ったキャラ）。
///
/// ⚠️ **英語版には買ったキャラを混ぜない。**
///    買えるキャラ（char14〜32）は日本のフリー素材なので、欧米系の顔ぶれの
///    中に混ざると顔と名前がちぐはぐになり、名前を覚える練習の邪魔になる。
///    （英語版の顔ぶれを入れた狙いそのものが崩れる）
List<String> playablePool(bool ja, Set<String> unlockedIds) => [
      ...charImageAssetsFor(ja),
      if (ja) ...unlockedExtraAssets(unlockedIds),
    ];

/// 🎴 顔メモの人も含めた出演プールを組み立てる。
///
/// 以前はキャラデッキに「自分で登録した人」の欄があるのに、
/// 実際のゲームは `kCharImageAssets` と購入キャラしか見ていなかった。
/// つまり**登録した人をONにしても対戦には出てこなかった**。
/// ここで1本にまとめて、デッキの意思がそのまま出演に効くようにする。
///
/// [customFaces] は `CustomRosterService.instance.entries` の `toFaceRef()`。
/// 除外の判定は [FaceRef.deckKey] で行う（画像パスではない。理由は
/// `CustomEntry.toFaceRef` のコメントを参照）。
List<FaceRef> buildFacePool({
  required Set<String> unlockedIds,
  required Set<String> excluded,
  List<FaceRef> customFaces = const [],
  int minimum = 4,
  bool ja = true,
}) {
  final all = <FaceRef>[
    // 🌍 基本の顔ぶれと買ったキャラは [playablePool] の規則に従う
    //    （英語版に日本語版の買ったキャラを混ぜない）。
    //    顔メモの人は自分で登録した実在の相手なので、言語に関係なく出す。
    for (final a in playablePool(ja, unlockedIds)) FaceRef.asset(a),
    ...customFaces,
  ];
  if (excluded.isEmpty) return all;
  final kept = [
    for (final f in all)
      if (!excluded.contains(f.deckKey)) f,
  ];
  // 絞りすぎてゲームが成立しないときは、除外を無視する（既存の方針と同じ）
  return kept.length >= minimum ? kept : all;
}
