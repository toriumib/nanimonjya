/// 🛍 ショップの拡張アイテム。
///
/// キャラ購入（character_catalog.dart）に加えて、
/// 「持っていると気分が良くなる」方向のアイテムを扱う。
///
/// - PraiseVoice : 正解・勝利のときに声で褒めてくれる（TTSで読み上げ）
/// - LuckyCharm  : プレイに小さな効果がつくお守り（1つだけ装備）
/// - CardSkin    : ビジネス特訓の名刺の見た目が変わる
///
/// いずれも購入状態は PlayerProfile に保存する。
library;

/// 🎉 ほめボイス。正解や勝利のときに、選んだキャラの口調で褒めてくれる。
class PraiseVoice {
  final String id;
  final String nameJa;
  final String nameEn;
  final String emoji;
  final int cost;

  /// 褒め言葉（正解時）。ランダムに1つ選ばれて読み上げられる。
  final List<String> linesJa;
  final List<String> linesEn;

  /// 勝利・全問正解のときの特別なひとこと。
  final String finaleJa;
  final String finaleEn;

  const PraiseVoice({
    required this.id,
    required this.nameJa,
    required this.nameEn,
    required this.emoji,
    required this.cost,
    required this.linesJa,
    required this.linesEn,
    required this.finaleJa,
    required this.finaleEn,
  });

  String name(bool ja) => ja ? nameJa : nameEn;
  List<String> lines(bool ja) => ja ? linesJa : linesEn;
  String finale(bool ja) => ja ? finaleJa : finaleEn;
}

const List<PraiseVoice> kPraiseVoices = [
  PraiseVoice(
    id: 'none',
    nameJa: 'なし（無音）',
    nameEn: 'None (silent)',
    emoji: '🔇',
    cost: 0,
    linesJa: [],
    linesEn: [],
    finaleJa: '',
    finaleEn: '',
  ),
  PraiseVoice(
    id: 'cheer',
    nameJa: '元気な応援',
    nameEn: 'Cheerful',
    emoji: '📣',
    cost: 180,
    linesJa: ['ナイス！', 'すごい！', 'その調子！', 'かんぺき！', 'やったね！'],
    linesEn: ['Nice!', 'Amazing!', 'Keep going!', 'Perfect!', 'You got it!'],
    finaleJa: 'さすがです！今日のあなたは最高でした！',
    finaleEn: 'Outstanding! You were on fire today!',
  ),
  PraiseVoice(
    id: 'gentle',
    nameJa: 'やさしい先生',
    nameEn: 'Gentle mentor',
    emoji: '🌷',
    cost: 240,
    linesJa: ['よく覚えていましたね', 'その調子で大丈夫', 'いい集中です', 'ちゃんと身についています'],
    linesEn: ['You remembered well', 'You are doing fine', 'Nice focus', 'It is really sinking in'],
    finaleJa: 'よく頑張りました。あなたのペースで大丈夫ですよ。',
    finaleEn: 'Well done. Your own pace is the right pace.',
  ),
  PraiseVoice(
    id: 'butler',
    nameJa: '執事',
    nameEn: 'Butler',
    emoji: '🎩',
    cost: 320,
    linesJa: ['お見事でございます', 'さすがでございます', '流石の記憶力でございます', '素晴らしい判断です'],
    linesEn: ['Splendid, sir', 'Most impressive', 'A remarkable memory', 'An excellent call'],
    finaleJa: 'お見事でございます。本日も完璧なお仕事でした。',
    finaleEn: 'Magnificent. A flawless performance today.',
  ),
  PraiseVoice(
    id: 'coach',
    nameJa: '熱血コーチ',
    nameEn: 'Hot-blooded coach',
    emoji: '🔥',
    cost: 320,
    linesJa: ['ナイスだ！', 'いいぞ、その集中！', '決まった！', '積み上がってるぞ！'],
    linesEn: ['Nice one!', 'That focus, yes!', 'Nailed it!', 'You are stacking wins!'],
    finaleJa: 'よくやった！この積み重ねが、本番で効くんだ！',
    finaleEn: 'Great work! This is what pays off when it counts!',
  ),
  PraiseVoice(
    id: 'zen',
    nameJa: '禅僧',
    nameEn: 'Zen monk',
    emoji: '🧘',
    cost: 400,
    linesJa: ['よい集中です', '心が静かですね', '今、ここに在ります', '迷いがありません'],
    linesEn: ['Fine concentration', 'A quiet mind', 'You are here, now', 'No hesitation'],
    finaleJa: '今日のあなたは、静かで確かでした。おつかれさまです。',
    finaleEn: 'Today you were calm and certain. Rest well.',
  ),
];

PraiseVoice praiseVoiceById(String id) => kPraiseVoices.firstWhere(
      (v) => v.id == id,
      orElse: () => kPraiseVoices.first,
    );

/// 🍀 お守り。1つだけ装備でき、プレイに小さな効果がつく。
enum CharmEffect {
  /// 効果なし（未装備）
  none,

  /// ビジネス特訓の「であう」で、出会った場所のヒントが思い出すときにも濃く出る
  extraHint,

  /// 獲得コインが+20%
  coinBoost,

  /// クイズの選択肢を4→3に減らす（当てやすくなる）
  fewerChoices,

  /// 1ゲームに1回だけ、まちがえても没収されない（お守りが守ってくれる）
  oneMistakeShield,
}

class LuckyCharm {
  final String id;
  final String nameJa;
  final String nameEn;
  final String emoji;
  final int cost;
  final CharmEffect effect;
  final String descJa;
  final String descEn;

  const LuckyCharm({
    required this.id,
    required this.nameJa,
    required this.nameEn,
    required this.emoji,
    required this.cost,
    required this.effect,
    required this.descJa,
    required this.descEn,
  });

  String name(bool ja) => ja ? nameJa : nameEn;
  String desc(bool ja) => ja ? descJa : descEn;
}

const List<LuckyCharm> kLuckyCharms = [
  LuckyCharm(
    id: 'none',
    nameJa: 'なし',
    nameEn: 'None',
    emoji: '➖',
    cost: 0,
    effect: CharmEffect.none,
    descJa: 'お守りなしで挑みます。',
    descEn: 'Play without a charm.',
  ),
  LuckyCharm(
    id: 'memo',
    nameJa: '思い出しのお守り',
    nameEn: 'Charm of Recall',
    emoji: '🍀',
    cost: 260,
    effect: CharmEffect.extraHint,
    descJa: '思い出すときのヒントが、はっきり表示されるようになります。',
    descEn: 'Hints during recall are shown more clearly.',
  ),
  LuckyCharm(
    id: 'koban',
    nameJa: '招福こばん',
    nameEn: 'Lucky Coin',
    emoji: '🪙',
    cost: 380,
    effect: CharmEffect.coinBoost,
    descJa: '手に入るコインが20%増えます。',
    descEn: 'Earn 20% more coins.',
  ),
  LuckyCharm(
    id: 'compass',
    nameJa: '絞りこみコンパス',
    nameEn: 'Narrowing Compass',
    emoji: '🧭',
    cost: 440,
    effect: CharmEffect.fewerChoices,
    descJa: 'クイズの選択肢が1つ減って、当てやすくなります。',
    descEn: 'One wrong option is removed from each quiz.',
  ),
  LuckyCharm(
    id: 'shield',
    nameJa: 'まちがえ守り',
    nameEn: 'Mistake Shield',
    emoji: '🛡️',
    cost: 520,
    effect: CharmEffect.oneMistakeShield,
    descJa: '1ゲームに1回だけ、まちがえても正解あつかいになります。',
    descEn: 'Once per game, a wrong answer counts as correct.',
  ),
];

LuckyCharm luckyCharmById(String id) => kLuckyCharms.firstWhere(
      (c) => c.id == id,
      orElse: () => kLuckyCharms.first,
    );

/// 💳 名刺スキン。ビジネス特訓で差し出される名刺の見た目が変わる。
class CardSkin {
  final String id;
  final String nameJa;
  final String nameEn;
  final String emoji;
  final int cost;
  /// 名刺の地の色（グラデーションの2色）と、文字・アクセントの色。
  final int bgTop;
  final int bgBottom;
  final int accent;
  final int textColor;

  const CardSkin({
    required this.id,
    required this.nameJa,
    required this.nameEn,
    required this.emoji,
    required this.cost,
    required this.bgTop,
    required this.bgBottom,
    required this.accent,
    required this.textColor,
  });

  String name(bool ja) => ja ? nameJa : nameEn;
}

const List<CardSkin> kCardSkins = [
  CardSkin(
    id: 'plain',
    nameJa: 'スタンダード',
    nameEn: 'Standard',
    emoji: '🪪',
    cost: 0,
    bgTop: 0xFFFFFFFF,
    bgBottom: 0xFFF3F8FF,
    accent: 0xFF3A7BD5,
    textColor: 0xFF223A5E,
  ),
  CardSkin(
    id: 'gold',
    nameJa: 'ゴールド',
    nameEn: 'Gold',
    emoji: '🥇',
    cost: 420,
    bgTop: 0xFFFFF6DC,
    bgBottom: 0xFFFFE7B0,
    accent: 0xFFB5810E,
    textColor: 0xFF6B4A00,
  ),
  CardSkin(
    id: 'midnight',
    nameJa: 'ミッドナイト',
    nameEn: 'Midnight',
    emoji: '🌃',
    cost: 460,
    bgTop: 0xFF2B2D64,
    bgBottom: 0xFF1B1B3A,
    accent: 0xFF8C7BFF,
    textColor: 0xFFFFFFFF,
  ),
  CardSkin(
    id: 'sakura',
    nameJa: 'サクラ',
    nameEn: 'Sakura',
    emoji: '🌸',
    cost: 380,
    bgTop: 0xFFFFF5F7,
    bgBottom: 0xFFFFE3EE,
    accent: 0xFFE0447C,
    textColor: 0xFF7A2846,
  ),
  CardSkin(
    id: 'mint',
    nameJa: 'ミント',
    nameEn: 'Mint',
    emoji: '🌿',
    cost: 380,
    bgTop: 0xFFF0FFF8,
    bgBottom: 0xFFD6F5E6,
    accent: 0xFF1E9C8E,
    textColor: 0xFF12513F,
  ),
];

CardSkin cardSkinById(String id) => kCardSkins.firstWhere(
      (s) => s.id == id,
      orElse: () => kCardSkins.first,
    );
