/// 🎵 BGMカタログ。
///
/// もとは profile_screen.dart に置いていたが、ショップからも参照するため
/// モデル層に移した（画面どうしの循環importを避ける）。
///
/// ⚠️ 魔王魂の楽曲は「魔王魂」のクレジット表記が利用条件。
/// [needsCredit] が true の曲を1曲でも収録している限り、
/// アプリ内のどこかに必ずクレジットを出すこと（マイページの音楽クレジット欄）。
library;

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
  BgmItem('op9-2-Nocturne.mp3', 'ノクターン Op.9-2', 'Nocturne Op.9-2', 0),
  BgmItem('bgm_ode_to_joy.wav', '歓喜の歌', 'Ode to Joy', 150),
  BgmItem('for_siciliano.mp3', 'シチリアーノ', 'Siciliano', 300),
  BgmItem('bgm_fur_elise.wav', 'エリーゼのために', 'Für Elise', 400),
  BgmItem('op.10-4.mp3', '練習曲 Op.10-4', 'Étude Op.10-4', 500),
  BgmItem('bgm_eine_kleine.wav', 'アイネ・クライネ', 'Eine kleine Nachtmusik', 700),
  BgmItem('c00Chopin_Fantaisie-Impromptu.mp3', '幻想即興曲', 'Fantaisie-Impromptu', 800),
  // --- 魔王魂（クレジット表記が必要） ---
  BgmItem('05_halzion.mp3', 'ハルジオン', 'Halzion', 250, needsCredit: true),
  BgmItem('08_burning_heart.mp3', 'バーニングハート', 'Burning Heart', 350,
      needsCredit: true),
  BgmItem('19_12345.mp3', '12345', '12345', 450, needsCredit: true),
];

/// クレジット表記が必要な提供元があるか。
bool get kHasCreditedBgm => kBgmCatalog.any((b) => b.needsCredit);

/// 🏠 ホーム画面で流す曲。
///
/// ショップの購入対象とは別枠で、**最初から無料で流れる**アプリの雰囲気づくり用。
///
/// 以前は魔王魂「ハルジオン」（アップテンポのロック）を流していたが、
/// 記憶のトレーニングに集中したいアプリの性格に合わず落ち着かないため、
/// 穏やかなクラシック（シチリアーノ・パブリックドメイン）に変更した。
/// 副次的に、ホームで魔王魂の曲を使わなくなった。
const String kHomeBgmAsset = 'for_siciliano.mp3';
