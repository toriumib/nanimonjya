import 'package:flutter/material.dart';

/// ホーム画面の着せ替えテーマ。コインを消費してアンロックする。
class HomeTheme {
  final String id;
  final String nameJa;
  final String nameEn;
  final String emoji;
  final int cost; // アンロックに必要なコイン（0 = 最初から）
  final List<Color> gradient; // 背景グラデーション
  final Color titleColor;
  final Color titleShadow;
  final bool darkBackground; // 暗い背景か（文字色の調整用）
  final Color accent; // アプリ全体のボタン・AppBarに使う主役色

  const HomeTheme({
    required this.id,
    required this.nameJa,
    required this.nameEn,
    required this.emoji,
    required this.cost,
    required this.gradient,
    required this.titleColor,
    required this.titleShadow,
    this.darkBackground = false,
    this.accent = const Color(0xFFFF4FA3),
  });
}

const List<HomeTheme> kHomeThemes = [
  HomeTheme(
    id: 'sunny',
    nameJa: 'サニー',
    nameEn: 'Sunny',
    emoji: '🌞',
    cost: 0,
    gradient: [Color(0xFFFFF3B0), Color(0xFFFFD6E8), Color(0xFFC9F2EF)],
    titleColor: Color(0xFFFF4FA3),
    titleShadow: Color(0xFFFFD93D),
    accent: Color(0xFFFF4FA3),
  ),
  HomeTheme(
    id: 'soda',
    nameJa: 'ソーダ',
    nameEn: 'Soda',
    emoji: '🥤',
    cost: 200,
    gradient: [Color(0xFFB8F0FF), Color(0xFFD6E8FF), Color(0xFFEAFFF7)],
    titleColor: Color(0xFF1E90D6),
    titleShadow: Color(0xFFB8F0FF),
    accent: Color(0xFF1EA7E0),
  ),
  HomeTheme(
    id: 'sakura',
    nameJa: 'サクラ',
    nameEn: 'Sakura',
    emoji: '🌸',
    cost: 400,
    gradient: [Color(0xFFFFE3EE), Color(0xFFFFC9DC), Color(0xFFFFF5F7)],
    titleColor: Color(0xFFE0447C),
    titleShadow: Color(0xFFFFFFFF),
    accent: Color(0xFFE85D97),
  ),
  HomeTheme(
    id: 'space',
    nameJa: 'ウチュウ',
    nameEn: 'Space',
    emoji: '🚀',
    cost: 800,
    gradient: [Color(0xFF2B2D64), Color(0xFF4B3B8F), Color(0xFF1B1B3A)],
    titleColor: Color(0xFFFFE45E),
    titleShadow: Color(0xFF8C7BFF),
    darkBackground: true,
    accent: Color(0xFF7B5CFF),
  ),
];

HomeTheme homeThemeById(String id) =>
    kHomeThemes.firstWhere((t) => t.id == id, orElse: () => kHomeThemes.first);

/// バトル画面に応援に来るわんちゃん。累計コインが増えるほど仲間が増える。
/// asset は描き下ろしSVGイラストのパス。
class DogCompanion {
  final String asset;
  final String nameJa;
  final String nameEn;
  final int requiredLifetimeCoins;

  const DogCompanion(
    this.asset,
    this.nameJa,
    this.nameEn,
    this.requiredLifetimeCoins,
  );
}

const String _sup = 'assets/images/supporters';

const List<DogCompanion> kDogCompanions = [
  DogCompanion('$_sup/dog_chihuahua.svg', 'チワワ', 'Chihuahua', 0),
  DogCompanion('$_sup/dog_shiba.svg', 'しばいぬ', 'Shiba Inu', 200),
  DogCompanion('$_sup/dog_corgi.svg', 'コーギー', 'Corgi', 600),
];

/// 🐶 なつき度レベル（あそぶほど上がる。声援や表示が変化）
class DogBond {
  final int required; // 必要なつき度
  final String nameJa;
  final String nameEn;
  final String emoji;
  const DogBond(this.required, this.nameJa, this.nameEn, this.emoji);
}

const List<DogBond> kDogBondLevels = [
  DogBond(0, 'しりあい', 'Acquaintance', '🤝'),
  DogBond(50, 'ともだち', 'Friend', '😊'),
  DogBond(150, 'なかよし', 'Buddy', '💕'),
  DogBond(400, 'しんゆう', 'Best Friend', '🌟'),
  DogBond(1000, 'かぞく', 'Family', '👑'),
];

/// 現在のなつき度レベル（0始まりのindex）
int dogBondIndex(int affection) {
  int idx = 0;
  for (int i = 0; i < kDogBondLevels.length; i++) {
    if (affection >= kDogBondLevels[i].required) idx = i;
  }
  return idx;
}

DogBond dogBond(int affection) => kDogBondLevels[dogBondIndex(affection)];

/// 次のレベルまでの進捗（0.0〜1.0、最大レベルなら1.0）
double dogBondProgress(int affection) {
  final idx = dogBondIndex(affection);
  if (idx >= kDogBondLevels.length - 1) return 1.0;
  final cur = kDogBondLevels[idx].required;
  final next = kDogBondLevels[idx + 1].required;
  return ((affection - cur) / (next - cur)).clamp(0.0, 1.0);
}

/// 累計コインでアンロック済みのわんちゃん一覧
List<DogCompanion> unlockedDogs(int lifetimeCoins) => kDogCompanions
    .where((d) => lifetimeCoins >= d.requiredLifetimeCoins)
    .toList();

/// 称号。累計コインで自動的にランクアップする。
class PlayerTitle {
  final String emoji;
  final String nameJa;
  final String nameEn;
  final int requiredLifetimeCoins;

  const PlayerTitle(
    this.emoji,
    this.nameJa,
    this.nameEn,
    this.requiredLifetimeCoins,
  );
}

const List<PlayerTitle> kPlayerTitles = [
  PlayerTitle('🐣', 'ひよっこプレイヤー', 'Rookie', 0),
  PlayerTitle('🪙', 'コインあつめ見習い', 'Coin Apprentice', 100),
  PlayerTitle('✨', 'なまえの達人', 'Name Master', 300),
  PlayerTitle('🐾', 'わんちゃんトレーナー', 'Dog Trainer', 600),
  PlayerTitle('👑', 'コインマスター', 'Coin Master', 1000),
  PlayerTitle('🏆', 'ナニモンジャ王', 'Nanimonjya King', 2000),
];

/// 現在の称号（累計コインで決まる）
PlayerTitle currentTitle(int lifetimeCoins) => kPlayerTitles.lastWhere(
      (t) => lifetimeCoins >= t.requiredLifetimeCoins,
      orElse: () => kPlayerTitles.first,
    );

/// バトル中に応援してくれるチア応援団。コインを消費してレベルアップする。
class CheerStage {
  final int level; // このステージのレベル（1〜）
  final String nameJa;
  final String nameEn;
  final int upgradeCost; // このレベルに上げるためのコイン
  final List<String> members; // 応援メンバーのイラスト(SVG)パス

  const CheerStage({
    required this.level,
    required this.nameJa,
    required this.nameEn,
    required this.upgradeCost,
    required this.members,
  });
}

const List<CheerStage> kCheerStages = [
  CheerStage(
    level: 1,
    nameJa: 'チアガール',
    nameEn: 'Cheer Girl',
    upgradeCost: 200,
    members: ['$_sup/cheer_girl.svg'],
  ),
  CheerStage(
    level: 2,
    nameJa: 'チア＆熱血団長',
    nameEn: 'Cheer & Captain',
    upgradeCost: 500,
    members: ['$_sup/cheer_girl.svg', '$_sup/squad_red.svg'],
  ),
  CheerStage(
    level: 3,
    nameJa: '応援団フル編成',
    nameEn: 'Full Cheer Squad',
    upgradeCost: 1000,
    members: [
      '$_sup/cheer_girl.svg',
      '$_sup/squad_blue.svg',
      '$_sup/squad_yellow.svg',
      '$_sup/squad_red.svg',
    ],
  ),
];

/// バトルに参加する応援メンバー。
/// ★チアガール＆応援団は最初から全員参加（無料）★
/// 引数 cheerLevel は後方互換のため残すが、常にフル編成を返す。
List<String> cheerMembers([int cheerLevel = 0]) => const [
      '$_sup/cheer_girl.svg',
      '$_sup/cheer_girl2.svg', // クール系の黒髪チア（2人組）
      '$_sup/squad_blue.svg',
      '$_sup/squad_yellow.svg',
      '$_sup/squad_red.svg',
    ];

/// 応援団の全メンバー（マイページのショーケース表示用）
const List<String> kAllCheerMembers = [
  '$_sup/cheer_girl.svg',
  '$_sup/cheer_girl2.svg',
  '$_sup/squad_blue.svg',
  '$_sup/squad_yellow.svg',
  '$_sup/squad_red.svg',
];

/// 🎽 応援団の衣装（コスチューム）。コインで解放して着せ替える。
/// ユーモア重視（流星のロックマン的ノリ）で、頭上アクセサリの絵文字と
/// 声援セリフ、応援ゾーンの色味が変わる。
class CheerCostume {
  final String id;
  final String nameJa;
  final String nameEn;
  final int cost;
  final String accessory; // 各メンバーの頭上に出る絵文字（''なら無し）
  final List<Color> zoneGradient; // 応援ゾーンの帯グラデ
  final List<String> cheersJa; // この衣装のときの声援（日本語）
  final List<String> cheersEn; // 同（英語）

  const CheerCostume({
    required this.id,
    required this.nameJa,
    required this.nameEn,
    required this.cost,
    required this.accessory,
    required this.zoneGradient,
    required this.cheersJa,
    required this.cheersEn,
  });
}

const List<CheerCostume> kCheerCostumes = [
  CheerCostume(
    id: 'normal',
    nameJa: 'がくラン隊',
    nameEn: 'School Squad',
    cost: 0,
    accessory: '',
    zoneGradient: [Color(0xFFFFF6D8), Color(0xFFFFE3F0), Color(0xFFD8F6F0)],
    cheersJa: ['がんばれ〜！', 'ナイス！', 'その調子！', 'いけいけ〜！', 'フレー！フレー！'],
    cheersEn: ['Go go!', 'Nice!', 'Keep it up!', 'You got this!', 'Hooray!'],
  ),
  CheerCostume(
    id: 'wave_hero',
    nameJa: 'でんぱヒーロー隊',
    nameEn: 'Wave Hero Squad',
    cost: 300,
    accessory: '⚡',
    zoneGradient: [Color(0xFFD6ECFF), Color(0xFFE0D6FF), Color(0xFFCFF7FF)],
    cheersJa: [
      'でんぱへんしーん！⚡',
      'ビリビリ〜いくぞ！',
      'エレキパワー全開！',
      '流星のごとく！☄',
      'キミの電波、うけとった！'
    ],
    cheersEn: [
      'Wave change! ⚡',
      'Zap zap, go!',
      'Full electro power!',
      'Like a meteor! ☄',
      'I got your wave!'
    ],
  ),
  CheerCostume(
    id: 'space',
    nameJa: 'うちゅう飛行隊',
    nameEn: 'Space Crew',
    cost: 500,
    accessory: '🚀',
    zoneGradient: [Color(0xFF2B2D64), Color(0xFF4B3B8F), Color(0xFF1B1B3A)],
    cheersJa: [
      '打ち上げ成功だ〜！🚀',
      '無重力でも応援！',
      '宇宙一のプレイ！🌌',
      'カウントダウン3・2・1！',
      'キミは銀河のスター！⭐'
    ],
    cheersEn: [
      'Liftoff! 🚀',
      'Cheering in zero-G!',
      'Best in the galaxy! 🌌',
      '3, 2, 1, go!',
      'A galaxy star! ⭐'
    ],
  ),
  CheerCostume(
    id: 'ninja',
    nameJa: 'にんぽう応援隊',
    nameEn: 'Ninja Troupe',
    cost: 700,
    accessory: '🥷',
    zoneGradient: [Color(0xFFE8E4DA), Color(0xFFD8E8E0), Color(0xFFEDE7D8)],
    cheersJa: [
      'ドロン！でござる！🥷',
      '奥義・応援の術！',
      'みごとでござる！',
      '忍法・記憶がくれ！',
      'いざ、まいる〜！'
    ],
    cheersEn: [
      'Poof! Ninja here! 🥷',
      'Secret cheer jutsu!',
      'Splendid, ninja!',
      'Memory ninjutsu!',
      'Here we go!'
    ],
  ),
  CheerCostume(
    id: 'king',
    nameJa: 'おうさま親衛隊',
    nameEn: 'Royal Guard',
    cost: 1000,
    accessory: '👑',
    zoneGradient: [Color(0xFFFFF0C8), Color(0xFFFFE7B0), Color(0xFFFFF6DC)],
    cheersJa: [
      'よきにはからえ！👑',
      'でかしたぞ、そち！',
      'あっぱれである！',
      '天晴れなる一手！',
      '王国の誇りじゃ！'
    ],
    cheersEn: [
      'As you wish! 👑',
      'Well done!',
      'Magnificent!',
      'A royal move!',
      'Pride of the kingdom!'
    ],
  ),
];

CheerCostume cheerCostumeById(String id) => kCheerCostumes.firstWhere(
      (c) => c.id == id,
      orElse: () => kCheerCostumes.first,
    );
