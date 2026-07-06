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

/// 現在のチアレベルで応援に来るメンバー（レベル0なら空）
List<String> cheerMembers(int cheerLevel) {
  if (cheerLevel <= 0) return const [];
  final stage = kCheerStages.lastWhere(
    (s) => s.level <= cheerLevel,
    orElse: () => kCheerStages.first,
  );
  return stage.members;
}
