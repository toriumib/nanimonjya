library;

import 'dart:math';

/// 🛍 ショップの拡張アイテム。
///
/// キャラ購入（character_catalog.dart）に加えて、
/// 「持っていると気分が良くなる」方向のアイテムを扱う。
///
/// - PraiseVoice : 正解・勝利のときに声で褒めてくれる（TTSで読み上げ）
/// - LuckyCharm  : プレイに小さな効果がつくお守り（1つだけ装備）
/// - CardSkin    : ビジネス特訓の名刺の見た目が変わる
/// - PlayerTitle : 名前の下に出る称号（マイページ・結果画面に表示）
///
/// いずれも購入状態は PlayerProfile に保存する。

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
  // 🙏 いろいろな立場の「ほめ方」を選べるようにする。
  // それぞれの言葉づかいの雰囲気を借りるだけで、
  // 教義や儀礼をまねたり、からかったりはしない（ほめる言葉だけを扱う）。
  PraiseVoice(
    id: 'miko',
    nameJa: '巫女さん',
    nameEn: 'Shrine maiden',
    emoji: '⛩️',
    cost: 400,
    linesJa: ['お見事です', 'よき心がけです', '清らかな集中ですね', '実を結んでいます'],
    linesEn: [
      'Beautifully done',
      'A fine effort',
      'Such clear focus',
      'It is bearing fruit',
    ],
    finaleJa: '今日の努力が、よい実りとなりますように。おつかれさまでした。',
    finaleEn: 'May today\'s effort bear good fruit. Well done.',
  ),
  PraiseVoice(
    id: 'pastor',
    nameJa: '牧師さん',
    nameEn: 'Pastor',
    emoji: '⛪',
    cost: 400,
    linesJa: ['すばらしい', 'よくやりましたね', 'その努力は実ります', '心強いかぎりです'],
    linesEn: [
      'Wonderful',
      'You have done well',
      'That effort will bear fruit',
      'Truly heartening',
    ],
    finaleJa: 'よく歩みましたね。今日の努力は、きっと報われます。',
    finaleEn: 'You walked well today. Your effort will not be wasted.',
  ),
  PraiseVoice(
    id: 'imam',
    nameJa: 'イマームさん',
    nameEn: 'Imam',
    emoji: '🕌',
    cost: 400,
    // 「マーシャーアッラー」は日常的に使われる称賛の言葉。
    linesJa: ['マーシャーアッラー', 'すばらしい集中です', 'よく努められました', '着実に進んでいます'],
    linesEn: [
      'Masha Allah',
      'Excellent focus',
      'You have striven well',
      'Steady progress',
    ],
    finaleJa: 'よく努められました。積み重ねは、かならず力になります。',
    finaleEn: 'You strove well. What you build up will become strength.',
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

  /// もらえるコインが2倍になる
  coinBoost,
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
    descJa: 'アイテムなしで挑みます。',
    descEn: 'Play without an item.',
  ),
  // 🗑 ヒント強調・選択肢を減らす・誤答を1回救済・持ち時間+5秒・ギフト短縮は廃止。
  //    種類が多いわりに効いているのか分からず、ゲームの難しさもぼやけていた。
  //    残すのは「コインが2倍になる」1つだけ。効果がはっきりしていて、
  //    何のために買うのかが一目で分かる。
  LuckyCharm(
    id: 'koban',
    nameJa: '招福こばん',
    nameEn: 'Lucky Coin',
    emoji: '🪙',
    cost: 380,
    effect: CharmEffect.coinBoost,
    descJa: '手に入るコインが2倍になります。',
    descEn: 'Doubles the coins you earn.',
  ),
];


LuckyCharm luckyCharmById(String id) => kLuckyCharms.firstWhere(
      (c) => c.id == id,
      orElse: () => kLuckyCharms.first,
    );

// 🗑 名刺スキン（CardSkin）は廃止した。名刺の配色が変わるだけで、
//    覚える練習には効かず、ショップの項目数だけを増やしていた。

// ═══════════════ 🏪 日替わりショップ ═══════════════

class DailyShopItem {
  final String id;
  final String nameJa;
  final String nameEn;
  final String emoji;
  final int originalCost;
  final int discountCost; // 割引後の価格（0なら動画で無料）

  const DailyShopItem({
    required this.id,
    required this.nameJa,
    required this.nameEn,
    required this.emoji,
    required this.originalCost,
    required this.discountCost,
  });

  String name(bool ja) => ja ? nameJa : nameEn;
  int get discount => originalCost - discountCost;
}

class DailyShop {
  final String date; // yyyy-mm-dd
  final List<DailyShopItem> items;

  const DailyShop({required this.date, required this.items});

  bool get isToday => date == _today();

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static DailyShop generate(int seed) {
    final tpls = <Map<String, Object>>[
      {'id': 'daily_coins', 'ja': 'コイン200枚', 'en': '200 Coins', 'emoji': '🪙', 'cost': 200},
      {'id': 'daily_coins_big', 'ja': 'コイン500枚', 'en': '500 Coins', 'emoji': '💰', 'cost': 500},
      {'id': 'daily_voice', 'ja': 'ほめボイス1種', 'en': '1 Praise Voice', 'emoji': '🎤', 'cost': 120},
      {'id': 'daily_charm', 'ja': 'お守り1種', 'en': '1 Lucky Charm', 'emoji': '🍀', 'cost': 150},
      {'id': 'daily_bgm', 'ja': 'BGM1曲', 'en': '1 BGM track', 'emoji': '🎵', 'cost': 400},
    ];
    final rng = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
        .millisecondsSinceEpoch ~/ 86400000;
    final r = seed + rng;
    final items = <DailyShopItem>[];
    for (final tpl in tpls) {
      final cost = tpl['cost'] as int;
      items.add(DailyShopItem(
        id: tpl['id'] as String,
        nameJa: tpl['ja'] as String,
        nameEn: tpl['en'] as String,
        emoji: tpl['emoji'] as String,
        originalCost: cost,
        discountCost: ((cost * (0.3 + (r % 5) / 10.0)) / 10).round() * 10,
      ));
    }
    return DailyShop(date: _today(), items: items);
  }
}

// ═══════════════ ⚡ コインブースト ═══════════════

class CoinBoost {
  static const int cost = 20;
  static const double multiplier = 2.0;

  static String name(bool ja) => ja ? '⚡ コイン2倍ブースト' : '⚡ Coin x2 Boost';
  static String desc(bool ja) => ja
      ? '次の1ゲームだけ、獲得コインが2倍になります。重ねがけできません。'
      : 'Doubles coins earned in your next game. Cannot be stacked.';
}

// ═══════════════ 🎰 ガチャ ═══════════════

class Gacha {
  static const int cost = 40; // 1回40コイン
  static const int multiCost = 100; // 3回100コイン

  static String name(bool ja) => ja ? '🎰 おなまえガチャ' : '🎰 Name Gacha';
  static String desc(bool ja) => ja
      ? '1回40コイン。レアなキャラや名刺スキンが当たります。3連100コイン。'
      : '40 coins per pull. Win rare characters & card skins! 3-pull for 100.';

  /// Returns prize. null = ハズレ（コイン一部返還）
  static ({String? id, String? type, int coinsBack}) pull(Random rng) {
    final roll = rng.nextDouble();
    if (roll < 0.05) return (id: 'jackpot', type: 'legendary_chara', coinsBack: 0); // 5% 神引き
    if (roll < 0.20) return (id: 'rare', type: 'rare_voice', coinsBack: 0); // 15% レア
    if (roll < 0.50) return (id: 'normal', type: 'random_chara', coinsBack: 0); // 30% 通常
    return (id: null, type: null, coinsBack: 15); // 50% ハズレ（15コイン返還）
  }
}

// ═══════════════ 🔥 連続ログイン保険 ═══════════════

class StreakSaver {
  static const int cost = 80;

  static String name(bool ja) => ja ? '🔥 ログイン保険' : '🔥 Streak Saver';
  static String desc(bool ja) => ja
      ? 'うっかりログインを忘れても連続日数が途切れません。購入後、次に途切れそうなときに自動で消費されます。'
      : 'If you miss a day, your streak is protected. Auto-consumed once when needed.';
}

// ═══════════════ 🧢 アバターアクセサリー ═══════════════

class AvatarAccessory {
  final String id;
  final String emoji;
  final String nameJa;
  final String nameEn;
  final int cost;
  final int avatarBit; // AvatarパラメータのどのビットをONにするか

  const AvatarAccessory({
    required this.id,
    required this.emoji,
    required this.nameJa,
    required this.nameEn,
    required this.cost,
    required this.avatarBit,
  });

  String name(bool ja) => ja ? nameJa : nameEn;
}

const List<AvatarAccessory> kAvatarAccessories = [
  AvatarAccessory(id: 'acc_glasses_round', emoji: '👓', nameJa: '丸メガネ', nameEn: 'Round Glasses', cost: 30, avatarBit: 1),
  AvatarAccessory(id: 'acc_glasses_square', emoji: '🕶', nameJa: '四角メガネ', nameEn: 'Square Glasses', cost: 30, avatarBit: 2),
  AvatarAccessory(id: 'acc_hat_cap', emoji: '🧢', nameJa: 'キャップ', nameEn: 'Cap', cost: 40, avatarBit: 3),
  AvatarAccessory(id: 'acc_hat_crown', emoji: '👑', nameJa: 'クラウン（プレミア）', nameEn: 'Crown (Premium)', cost: 100, avatarBit: 4),
  AvatarAccessory(id: 'acc_hat_tophat', emoji: '🎩', nameJa: 'トップハット', nameEn: 'Top Hat', cost: 50, avatarBit: 5),
  AvatarAccessory(id: 'acc_neck_tie', emoji: '👔', nameJa: 'ネクタイ', nameEn: 'Necktie', cost: 30, avatarBit: 6),
  AvatarAccessory(id: 'acc_ear_headphones', emoji: '🎧', nameJa: 'ヘッドホン', nameEn: 'Headphones', cost: 40, avatarBit: 7),
  AvatarAccessory(id: 'acc_mask_ninja', emoji: '🥷', nameJa: 'ニンジャマスク', nameEn: 'Ninja Mask', cost: 60, avatarBit: 8),
  AvatarAccessory(id: 'acc_scarf_red', emoji: '🧣', nameJa: '赤いマフラー', nameEn: 'Red Scarf', cost: 35, avatarBit: 9),
  AvatarAccessory(id: 'acc_wing_angel', emoji: '👼', nameJa: '天使の羽（激レア）', nameEn: 'Angel Wings (UR)', cost: 200, avatarBit: 10),
];

// ═══════════════ 🌟 神スキン ═══════════════

class GodSkin {
  final String id;
  final String emoji;
  final String nameJa;
  final String nameEn;
  final int cost;
  final String descJa;
  final String descEn;

  const GodSkin({
    required this.id,
    required this.emoji,
    required this.nameJa,
    required this.nameEn,
    required this.cost,
    required this.descJa,
    required this.descEn,
  });

  String name(bool ja) => ja ? nameJa : nameEn;
  String desc(bool ja) => ja ? descJa : descEn;
}

const List<GodSkin> kGodSkins = [
  GodSkin(
    id: 'god_skin_golden',
    emoji: '✨',
    nameJa: '黄金の記憶',
    nameEn: 'Golden Memory',
    cost: 500,
    descJa: 'なまえがおの名簿が金色に輝きます。全キャラに金色のオーラ。',
    descEn: 'Your roster shines in gold. All characters get a golden aura.',
  ),
  GodSkin(
    id: 'god_skin_cosmic',
    emoji: '🌌',
    nameJa: '宇宙の織り手',
    nameEn: 'Cosmic Weaver',
    cost: 800,
    descJa: '時空を超えた記憶の支配者。背景が星空に。覚えた数だけ星が増える。',
    descEn: 'Master of spacetime memory. Starfield background. Stars multiply with each name learned.',
  ),
  GodSkin(
    id: 'god_skin_neon',
    emoji: '💜',
    nameJa: 'ネオン・ゴッド',
    nameEn: 'Neon God',
    cost: 600,
    descJa: 'サイバーパンクの神。ネオンの輝きと共に名前を覚える。',
    descEn: 'Cyberpunk deity. Learn names with neon brilliance.',
  ),
];

// ═══════════════ 💀 ハードコアモードチケット ═══════════════

class HardcoreTicket {
  static const int cost = 30;

  static String name(bool ja) => ja ? '💀 ハードコアチケット' : '💀 Hardcore Ticket';
  static String desc(bool ja) => ja
      ? '1回だけハードコアモードでプレイ。選択肢が1つ減り、制限時間が半分に。成功報酬3倍。'
      : 'One hardcore game: -1 choice option, half the time limit, 3x rewards.';
}

// ═══════════════ 🎯 スタンプラリー ═══════════════

class StampRally {
  static const int targetDays = 7;

  static String title(bool ja, int days) => ja
      ? '🎯 動画スタンプラリー ($days/$targetDays)'
      : '🎯 Ad Watch Streak ($days/$targetDays)';

  static String desc(bool ja) => ja
      ? '毎日1回リワード広告を見るとスタンプがたまります。$targetDays日連続でレジェンドキャラをプレゼント！'
      : 'Watch 1 rewarded ad daily to earn stamps. $targetDays consecutive days = Legendary Character!';

  static bool canClaim(int streak, Set<String> unlockedCharacters) =>
      streak >= targetDays;
}
