/// 🎵 BGMカタログ。
///
/// もとは profile_screen.dart に置いていたが、ショップからも参照するため
/// モデル層に移した（画面どうしの循環importを避ける）。
///
/// ⚠️ 魔王魂の楽曲は「魔王魂」のクレジット表記が利用条件。
/// [needsCredit] が true の曲を1曲でも収録している限り、
/// アプリ内のどこかに必ずクレジットを出すこと（マイページの音楽クレジット欄）。
library;

// 📉 2026-08 に8曲（約19MB）を削除した。
//    ノクターン / 練習曲Op.10-4 / エリーゼのために / 歓喜の歌 /
//    バーニングハート / アイネ・クライネ / ハルジオン / test_bgm
//    音声だけで38MBあり、アプリ全体の大きな塊になっていたため。
//
// ⚠️ **曲を消すときは、必ず player_profile 側の既定値と
//    保存済みの選択（selectedBgm / selectedResultBgm / selectedHomeBgm /
//    unlockedBgm）を確認すること。** 消したファイル名が残っていると無音になる。
//    救済は [resolveBgm] で行う。

class BgmItem {
  final String asset;
  final String nameJa;
  final String nameEn;
  final int cost;

  /// 提供元のクレジット表記が必要か（魔王魂の楽曲）。
  final bool needsCredit;

  const BgmItem(
    this.asset,
    this.nameJa,
    this.nameEn,
    this.cost, {
    this.needsCredit = false,
  });

  String name(bool ja) => ja ? nameJa : nameEn;
}

const List<BgmItem> kBgmCatalog = [
  // --- クラシック（パブリックドメイン） ---
  BgmItem('for_siciliano.mp3', 'シチリアーノ', 'Siciliano', 0),
  BgmItem('beethoven_5th.mp3', '運命（第5番）', 'Symphony No.5 "Fate"', 0),
  BgmItem('c00Chopin_Fantaisie-Impromptu.mp3', '幻想即興曲', 'Fantaisie-Impromptu', 800),
  // --- そのほか ---
  BgmItem('shining_star.mp3', 'シャイニングスター', 'Shining Star', 0),
  // --- 魔王魂（クレジット表記が必要） ---
  BgmItem('19_12345.mp3', '12345', '12345', 0, needsCredit: true),
];

/// 🎁 最初から使える曲。
///
/// ⚠️ **ここに載せる曲は、必ず [kBgmCatalog] にも `assets/audio/` にも
///    存在すること。** 片方でも欠けると、その人のBGMが無音になる。
const List<String> kFreeBgmAssets = [
  'for_siciliano.mp3', // ホームの既定（ランダムの片方）
  'beethoven_5th.mp3', // ホームの既定（ランダムの片方）
  'shining_star.mp3', // リザルトの既定
  '19_12345.mp3',
];

/// クレジット表記が必要な提供元があるか。
/// ⚠️ true の曲が1曲でもある限り、アプリ内にクレジットを出すこと。
bool get kHasCreditedBgm => kBgmCatalog.any((b) => b.needsCredit);

/// カタログに載っているか（＝アセットが同梱されているか）。
///
/// ⚠️ **曲を削除したときに、保存済みの選択を救うために使う。**
///    2026-08 にBGMを8曲消したとき、`selectedBgm` の既定が
///    削除対象（`08_burning_heart.mp3`）のままだったため、
///    そのまま出していれば全員が無音になるところだった。
bool isKnownBgm(String asset) => kBgmCatalog.any((b) => b.asset == asset);

/// 保存されていた曲が消えていたら、代わりの曲を返す。
String resolveBgm(String saved, String fallback) =>
    isKnownBgm(saved) ? saved : fallback;

/// 🎮 試合中の既定曲。
const String kDefaultGameBgmAsset = 'for_siciliano.mp3';

/// 🏆 リザルトの既定曲。オーナー指定でシャイニングスター。
const String kDefaultResultBgmAsset = 'shining_star.mp3';

/// 🏠 ホーム画面で流す曲。
///
/// ショップの購入対象とは別枠で、**最初から無料で流れる**アプリの雰囲気づくり用。
///
/// 以前は魔王魂「ハルジオン」（アップテンポのロック）を流していたが、
/// 記憶のトレーニングに集中したいアプリの性格に合わず落ち着かないため、
/// 穏やかなクラシック（パブリックドメイン）に変更した。
const String kHomeBgmAsset = 'for_siciliano.mp3';

/// 🎲 ホームで**ランダムに選ぶ**曲。
///
/// 毎回おなじ曲だと、起動のたびに同じ体験になって飽きる。
/// 落ち着いたシチリアーノと、力の入る運命を交互に引かせる。
///
/// ⚠️ ここに載せる曲は [kFreeBgmAssets] にも入れること。
///    買っていない曲が勝手に鳴ってしまう。
const List<String> kHomeRandomPool = [
  'for_siciliano.mp3',
  'beethoven_5th.mp3',
];

/// マイページで「ホームの曲」に選べる特別な値。
/// これが選ばれているときは [kHomeRandomPool] から毎回引く。
const String kHomeBgmRandom = 'random';

/// 保存されていたBGM設定一式。
class BgmSelection {
  final Set<String> unlocked;
  final String game;
  final String result;
  final String home;

  const BgmSelection({
    required this.unlocked,
    required this.game,
    required this.result,
    required this.home,
  });
}

/// 💾 保存されていたBGM設定を、いまのカタログに合わせて直す。
///
/// ⚠️ **これが無いと、曲を消したときに無音になる。**
///    保存されているのはファイル名なので、アプリから曲を消しても
///    端末には古い名前が残る。それを再生しようとして何も鳴らない。
///    2026-08 に8曲消したときに現実の危険になった。
///
/// ⚠️ 純粋関数にしてあるのは、テストを書くため。
///    `PlayerProfile` はシングルトンで `load()` が一度しか走らないので、
///    そちらでは「古い値から復帰する」試験が書けない。
BgmSelection migrateBgmSelection({
  required Iterable<String> savedUnlocked,
  required String? savedGame,
  required String? savedResult,
  required String? savedHome,
}) {
  final unlocked = savedUnlocked.where(isKnownBgm).toSet()
    ..addAll(kFreeBgmAssets);

  String pick(String? saved, String fallback) {
    final v = resolveBgm(saved ?? fallback, fallback);
    return unlocked.contains(v) ? v : fallback;
  }

  // 🎲 ホームだけは 'random' という**ファイル名ではない値**を取りうる。
  //    先に見分けないと、カタログに無いとして弾かれてしまう。
  final home = (savedHome == kHomeBgmRandom)
      ? kHomeBgmRandom
      : pick(savedHome, kHomeBgmRandom);

  return BgmSelection(
    unlocked: unlocked,
    game: pick(savedGame, kDefaultGameBgmAsset),
    result: pick(savedResult, kDefaultResultBgmAsset),
    home: home,
  );
}
