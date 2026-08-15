import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/meta_strings.dart';
import '../models/bgm_catalog.dart';
import '../models/character_catalog.dart';
import '../models/cosmetics.dart';
import '../models/knowledge_shop.dart';
import '../models/person.dart';
import '../models/shop_items.dart';
import '../services/app_analytics.dart';
import '../services/bgm.dart';
import '../services/player_profile.dart';
import '../services/reward_ad_helper.dart';
import '../services/review_prompt.dart'; // ⭐ ストアのレビューを開く
import '../services/sfx.dart';
import '../services/speech.dart';
import '../widgets/themed_background.dart';
import '../widgets/banner_ad_slot.dart';
import '../services/iap_service.dart'; // 💰 課金
import 'character_deck_screen.dart';
import 'coin_doubler_screen.dart';

/// 🛍 キャラクターショップ。
/// - 動画（リワード広告）でコインを稼ぐ導線
/// - コインで追加キャラを購入（なまえがお／ビジネス特訓の出演プールに加わる）
/// - アプリ評価（★）でストア評価を後押し
class CharacterShopScreen extends StatefulWidget {
  /// タブとして表示するときは true。戻る矢印と重複するバナーを出さない。
  final bool embedded;

  const CharacterShopScreen({super.key, this.embedded = false});

  @override
  State<CharacterShopScreen> createState() => _CharacterShopScreenState();
}

class _CharacterShopScreenState extends State<CharacterShopScreen> {
  final RewardAdHelper _rewardAd = RewardAdHelper(placement: 'shop');
  static const int _adReward = 60;

  @override
  void initState() {
    super.initState();
    AppAnalytics.screen('shop');
    _rewardAd.load();
  }

  @override
  void dispose() {
    _rewardAd.dispose();
    super.dispose();
  }

  Future<void> _watchAd() async {
    final m = MetaStrings.of(context);
    final playedNow = await _rewardAd.showOrQueue(onReward: () {
      PlayerProfile.instance.grantBonusCoins(_adReward);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(m.earnedCoins(_adReward))),
        );
      }
    });
    if (!playedNow && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m.storeAdLoading)),
      );
    }
  }

  Future<void> _rate() async {
    Sfx.instance.pop();
    // ⚠️ 自分から押した人には、必ずストアのページを開く。
    //    アプリ内ダイアログ（requestReview）は Google の割り当てで
    //    黙って何も出ないことがあり、「押したのに反応が無い」になる。
    //    自動依頼の回数もここでは消費しない（openStoreReview 参照）。
    await openStoreReview();
  }

  Future<void> _buy(GameCharacter c) async {
    final m = MetaStrings.of(context);
    final p = PlayerProfile.instance;
    if (p.unlockedCharacters.contains(c.id)) return;
    // 何がタップされたか（買えたかどうかも含めて）を残す。
    // 「よくタップされるのに買われない＝値段が高すぎる」商品を見つけるため。
    AppAnalytics.shopItemTapped(
      category: 'character',
      itemId: c.id,
      cost: c.cost,
      affordable: p.coins >= c.cost,
    );
    if (p.coins < c.cost) {
      // キャラ購入も同じく、その場で動画に誘導する
      AppAnalytics.shopBlockedByCoins(
          category: 'character', itemId: c.id, shortBy: c.cost - p.coins);
      // 「この商品が欲しくて動画を見た」という因果を残す
      AppAnalytics.adOfferedForItem(
        category: 'character',
        itemId: c.id,
        cost: c.cost,
        coinsHeld: p.coins,
      );
      Sfx.instance.wrong();
      await _offerAdForCoins(m, c.cost);
      return;
    }
    final ok = await p.unlockCharacter(c.id, c.cost);
    if (ok) {
      AppAnalytics.shopPurchase(
          category: 'character', itemId: c.id, cost: c.cost, method: 'coins');
      Sfx.instance.reward();
      if (mounted) {
        // 買っただけでは何も変わらないように見えるので、
        // 「デッキに入った」ことを伝え、その場で編集画面へ行けるようにする。
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(m.storeBoughtDeckHint),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: m.storeOpenDeck,
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const CharacterDeckScreen()));
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    return Scaffold(
      // タブとして埋め込まれていても、HomeShell 側はバナーを持たないので
      // ここで出してよい（入れ子のScaffoldなので下タブの上に出る）。
      bottomNavigationBar: const BannerAdSlot(),
      appBar: AppBar(
        title: Text(m.storeTitle),
        automaticallyImplyLeading: !widget.embedded,
      ),
      // 買った着せ替えテーマをこの画面にも反映する
      body: ThemedBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge([PlayerProfile.instance, _rewardAd]),
            builder: (context, _) {
              final p = PlayerProfile.instance;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 💰 コインバー（グラデーション背景＋動画＋評価 一体化）
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFF3D6), Color(0xFFFFE3B0)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFFFC93C).withValues(alpha: 0.2), blurRadius: 8),
                        ],
                        border: Border.all(color: const Color(0xFFFFC93C), width: 1.5),
                      ),
                      child: Column(children: [
                        Row(children: [
                          const Text('🪙', style: TextStyle(fontSize: 28)),
                          const SizedBox(width: 8),
                          Text(m.storeCoins(p.coins),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF7A5A00))),
                          const Spacer(),
                          _miniBtn(m.storeWatchAd(_adReward), const Color(0xFF4ECDC4), _rewardAd.isLoading ? null : _watchAd, width: 120),
                          const SizedBox(width: 6),
                          _miniBtn(m.storeRate, const Color(0xFFFFB300), _rate, width: 80),
                        ]),
                        const SizedBox(height: 8),
                        Text(m.storeHint, textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 10.5, color: Color(0xAA7A5A00))),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    // 💳 広告除去
                    _removeAdsCard(m, p),
                    // 💳 ストアにつながって商品が取れてから出す。
                    //    起動直後はまだ取得中なので、取れた時点で描き直す。
                    AnimatedBuilder(
                      animation: IapService.instance,
                      builder: (context, _) => IapService.instance.available
                          ? Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: _iapSection(m, p),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 18),
                    // ── 🔥 人気セクション ──
                    _sectionHeader(m.ja ? '🔥 人気＆お得' : '🔥 Trending', ''),
                    const SizedBox(height: 10),
                    // 🏪 日替わり
                    _dailyShopCard(m, p),
                    const SizedBox(height: 10),
                    // 🎰 ガチャ
                    _gachaCard(m, p),
                    const SizedBox(height: 10),
                    // ⚡ ブースト + 🪙 コイン倍増（横並び）
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _coinBoostCard(m, p)),
                          const SizedBox(width: 8),
                          Expanded(child: _coinDoublerCard(m)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 🌟 神スキン
                    _godSkinCard(m, p),
                    const SizedBox(height: 8),
                    // 💀 ハードコア
                    _hardcoreTicketCard(m, p),
                    const SizedBox(height: 8),
                    // 🎯 スタンプラリー
                    _stampRallyCard(m, p),
                    const SizedBox(height: 20),
                    // 🧑‍🤝‍🧑 追加キャラ（このショップの主役なので一番上に置く）
                    _sectionHeader(m.storeMore, m.storeCharsDesc),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.72,
                      children: [
                        for (final c in kExtraCharacters)
                          _charCard(m, c, p.unlockedCharacters.contains(c.id)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 基本キャラ（最初から持っている12人）
                    Text(m.storeStarter,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.9,
                      children: [
                        for (final a in kCharImageAssets) _ownedThumb(a),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // 🧠 記憶の殿堂（コインで買うプレミアム読み物）
                    _sectionHeader(m.shopKnowledgeTitle, m.shopKnowledgeDesc),
                    for (final a in kKnowledgeArticles)
                      _knowledgeRow(m, p, a),
                    const SizedBox(height: 20),
                    // 🎉 ほめボイス（気分が良くなる系）
                    _sectionHeader(m.shopVoicesTitle, m.shopVoicesDesc),
                    for (final v in kPraiseVoices)
                      _voiceRow(m, p, v),
                    const SizedBox(height: 20),
                    // 🍀 お守り（プレイに効果）
                    _sectionHeader(m.shopCharmsTitle, m.shopCharmsDesc),
                    for (final c in kLuckyCharms)
                      _charmRow(m, p, c),
                    const SizedBox(height: 20),
                    // 🎨 着せ替えテーマ（アプリ全体の色あいが変わる）
                    _sectionHeader(m.shopThemesTitle, m.shopThemesDesc),
                    for (final t in kHomeThemes) _themeRow(m, p, t),
                    const SizedBox(height: 20),
                    // 🎵 BGM（コインで買う or 動画1本で解放）
                    _sectionHeader(m.shopBgmTitle, m.shopBgmDesc),
                    for (final b in kBgmCatalog) _bgmRow(m, p, b),
                    // 🎼 魔王魂の楽曲は提供元のクレジット表記が利用条件
                    if (kHasCreditedBgm)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                        child: Text(m.bgmCredit,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.black54)),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ═══════════════ 🏪 日替わりショップ ═══════════════

  Widget _dailyShopCard(MetaStrings m, PlayerProfile p) {
    p.refreshDailyShop();
    final shop = DailyShop.generate(42);
    return Card(
      color: const Color(0xFFFFF9E6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFFFC02E), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('🏪', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(child: Text(
                m.ja ? '本日限定！日替わり割引' : 'TODAY ONLY! Daily Deals',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF5A4A1E)),
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6A3D),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('SALE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ]),
            const SizedBox(height: 12),
            ...shop.items.take(3).map((item) {
              final bought = p.dailyShopBought.contains(item.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name(m.ja), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                        Row(children: [
                          Text('🪙${item.originalCost}', style: const TextStyle(fontSize: 11, decoration: TextDecoration.lineThrough, color: Colors.black38)),
                          const SizedBox(width: 4),
                          Text('→ 🪙${item.discountCost}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFC62828))),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE0E0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(m.ja ? '${(100 - item.discountCost * 100 ~/ item.originalCost)}%OFF' : '-${(100 - item.discountCost * 100 ~/ item.originalCost)}%',
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFFC62828))),
                          ),
                        ]),
                      ],
                    )),
                    ElevatedButton(
                      onPressed: bought ? null : () async {
                        if (p.coins < item.discountCost) {
                          await _offerAdForCoins(m, item.discountCost);
                          return;
                        }
                        final ok = await p.buyDailyShopItem(item.id, item.discountCost);
                        if (ok) {
                          Sfx.instance.coin();
                          if (item.id == 'daily_coins') {
                            p.grantBonusCoins(200);
                          } else if (item.id == 'daily_coins_big') {
                            p.grantBonusCoins(500);
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(m.shopBought)));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bought ? Colors.grey.shade300 : const Color(0xFFFFC02E),
                        foregroundColor: bought ? Colors.grey : const Color(0xFF5A4A1E),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                      ),
                      child: Text(bought ? (m.ja ? '済' : 'Done') : '🪙${item.discountCost}'),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ═══════════════ ⚡ コインブースト ═══════════════

  Widget _coinBoostCard(MetaStrings m, PlayerProfile p) {
    return Card(
      color: p.coinBoostActive ? const Color(0xFFFFF3D6) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: p.coinBoostActive ? const Color(0xFFFFC02E) : const Color(0xFFD8E4F0),
          width: p.coinBoostActive ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          const Text('⚡', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(CoinBoost.name(m.ja), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(CoinBoost.desc(m.ja), style: const TextStyle(fontSize: 11, color: Colors.black54)),
            ],
          )),
          const SizedBox(width: 8),
          p.coinBoostActive
              ? Chip(label: Text(m.ja ? '有効！' : 'ACTIVE', style: const TextStyle(fontSize: 11)),
                   backgroundColor: const Color(0xFFFFC02E).withValues(alpha: 0.3))
              : ElevatedButton(
                  onPressed: p.coins < 20 ? null : () async {
                    await p.activateCoinBoost();
                    Sfx.instance.coin();
                    if (mounted) setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6A3D),
                    foregroundColor: Colors.white,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                  child: const Text('🪙20'),
                ),
        ]),
      ),
    );
  }

  // ═══════════════ 🌟 神スキン ═══════════════

  Widget _godSkinCard(MetaStrings m, PlayerProfile p) {
    return Card(
      color: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('🌟', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(m.ja ? '神スキン' : 'God Skins',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFFFC02E))),
            ]),
            const SizedBox(height: 4),
            Text(m.ja ? '装備すると特別な演出が追加されます' : 'Equip for special visual effects',
                style: const TextStyle(fontSize: 11, color: Color(0xFF8899BB))),
            const SizedBox(height: 12),
            ...kGodSkins.map((s) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2A3A5A)),
                ),
                child: Row(children: [
                  Text(s.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name(m.ja), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(s.desc(m.ja), style: const TextStyle(fontSize: 10, color: Color(0xFF8899BB))),
                    ],
                  )),
                  ElevatedButton(
                    onPressed: p.coins < s.cost ? null : () async {
                      if (p.coins < s.cost) return;
                      p.coins -= s.cost;
                      p.unlockedAccessories.add(s.id);
                      p.selectedAccessory = s.id;
                      await p.buyDailyShopItem(s.id, s.cost);
                      Sfx.instance.fanfare();
                      if (mounted) setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC02E),
                      foregroundColor: const Color(0xFF1A1A2E),
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                    ),
                    child: Text('🪙${s.cost}'),
                  ),
                ]),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ═══════════════ 💀 ハードコアチケット ═══════════════

  Widget _hardcoreTicketCard(MetaStrings m, PlayerProfile p) {
    return Card(
      color: const Color(0xFF1A0000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFFFF4444).withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          const Text('💀', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(HardcoreTicket.name(m.ja),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFFF4444))),
              const SizedBox(height: 2),
              Text(HardcoreTicket.desc(m.ja),
                  style: const TextStyle(fontSize: 11, color: Color(0xFFFF8888))),
            ],
          )),
          ElevatedButton(
            onPressed: p.coins < HardcoreTicket.cost ? null : () async {
              if (p.coins < HardcoreTicket.cost) return;
              p.coins -= HardcoreTicket.cost;
              p.applyBoost(10); // activate as boost-like
              Sfx.instance.fanfare();
              HapticFeedback.heavyImpact();
              if (mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(m.ja ? '💀 ハードコア発動！次のゲームの報酬3倍' : '💀 Hardcore active! 3x rewards next game!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4444),
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            ),
            child: Text('🪙${HardcoreTicket.cost}'),
          ),
        ]),
      ),
    );
  }

  // ═══════════════ 🎰 ガチャ ═══════════════

  Widget _gachaCard(MetaStrings m, PlayerProfile p) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC02E), Color(0xFFFF6A3D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFFC02E).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('🎰', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 4),
            Text(Gacha.name(m.ja),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 2),
            Text(Gacha.desc(m.ja),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Color(0xFFFFF3D6))),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: p.coins < Gacha.cost ? null : () async {
                    if (p.coins < Gacha.cost) {
                      await _offerAdForCoins(m, Gacha.cost);
                      return;
                    }
                    final result = await p.pullGacha();
                    if (!mounted) return;
                    setState(() {});
                    final text = result.coinsBack > 0
                        ? (m.ja ? '🎰 ハズレ…でも${result.coinsBack}コイン戻ってきた！' : '🎰 Miss! But ${result.coinsBack} coins returned!')
                        : result.type == 'legendary_chara'
                            ? (m.ja ? '🌟 神引き！伝説のキャラGET！' : '🌟 JACKPOT! Legendary character!')
                            : (m.ja ? '🎉 レアアイテムGET！' : '🎉 Rare item won!');
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(text)));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFE8663C),
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: Text(m.ja ? '1回 🪙40' : '1x 🪙40',
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: p.coins < Gacha.multiCost ? null : () async {
                    for (var i = 0; i < 3; i++) {
                      if (p.coins < Gacha.cost) break;
                      await p.pullGacha();
                    }
                    if (mounted) {
                      setState(() {});
                      Sfx.instance.fanfare();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.85),
                    foregroundColor: const Color(0xFFFF6A3D),
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: Text(m.ja ? '3連 🪙100' : '3x 🪙100',
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ═══════════════ 🪙 コイン倍増ゲーム ═══════════════

  Widget _coinDoublerCard(MetaStrings m) {
    return Card(
      color: const Color(0xFFFFF8E6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFFFC02E), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          const Text('🪙', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.ja ? '🪙 コイン倍増ゲーム' : '🪙 Coin Doubler',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(m.ja
                  ? '3人の顔と名前を覚えて賭けたコインを倍に！1人でも間違えたら没収。'
                  : 'Memorize 3 faces. Double or nothing! Miss one and lose it all.',
                  style: const TextStyle(fontSize: 11, color: Colors.black54)),
            ],
          )),
          const SizedBox(width: 8),
          Column(children: [
            ElevatedButton(
              onPressed: () {
                Sfx.instance.fanfare();
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const CoinDoublerScreen(bet: 50)));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC02E),
                foregroundColor: const Color(0xFF5A4A1E),
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
              ),
              child: Text(m.ja ? '🪙50勝負' : '🪙50 Bet'),
            ),
            const SizedBox(height: 4),
            ElevatedButton(
              onPressed: () {
                Sfx.instance.fanfare();
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const CoinDoublerScreen(bet: 200)));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8663C),
                foregroundColor: Colors.white,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
              ),
              child: Text(m.ja ? '🪙200勝負' : '🪙200 Bet'),
            ),
          ]),
        ]),
      ),
    );
  }

  // ═══════════════ 🎯 動画スタンプラリー ═══════════════

  Widget _stampRallyCard(MetaStrings m, PlayerProfile p) {
    final day = p.adStreakDay;
    final watchedToday = p.adWatchedToday;
    return Card(
      color: const Color(0xFFF3E8FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: day >= 7 ? const Color(0xFFFFC02E) : const Color(0xFF8A5AC2),
          width: day >= 7 ? 2.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('🎯', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(child: Text(
                StampRally.title(m.ja, day),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF4A2A7A)),
              )),
              if (day >= 7 && !p.adStreakRewardsClaimed.contains('day7'))
                ElevatedButton(
                  onPressed: () => _claimLegendary(m, p),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC02E),
                    foregroundColor: const Color(0xFF5A4A1E),
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                  ),
                  child: Text(m.ja ? 'GET!' : 'CLAIM!'),
                ),
            ]),
            const SizedBox(height: 8),
            Text(StampRally.desc(m.ja), style: const TextStyle(fontSize: 11, color: Colors.black54)),
            const SizedBox(height: 10),
            // Stamp dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 7; i++)
                  Container(
                    width: 36, height: 36,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i <= day ? const Color(0xFF8A5AC2) : Colors.grey.shade200,
                      border: Border.all(color: i <= day ? const Color(0xFF6A3A9E) : Colors.grey.shade300, width: 1.5),
                    ),
                    child: Center(child: Text(
                      i <= day ? '✅' : '$i',
                      style: TextStyle(fontSize: i <= day ? 16 : 13, color: i <= day ? Colors.white : Colors.grey),
                    )),
                  ),
              ],
            ),
            if (!watchedToday) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _watchAdForRally(m, p),
                  icon: const Icon(Icons.play_circle_outline, size: 18),
                  label: Text(m.ja ? '🎬 動画を見てスタンプGET' : '🎬 Watch ad to stamp'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8A5AC2),
                    side: const BorderSide(color: Color(0xFF8A5AC2)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _watchAdForRally(MetaStrings m, PlayerProfile p) async {
    await _rewardAd.showOrQueue(onReward: () async {
      await p.recordAdWatch();
      Sfx.instance.fanfare();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(m.ja ? 'スタンプGET！ (${p.adStreakDay}/7)' : 'Stamped! (${p.adStreakDay}/7)')),
        );
      }
    });
  }

  Future<void> _claimLegendary(MetaStrings m, PlayerProfile p) async {
    if (p.adStreakRewardsClaimed.contains('day7')) return;
    // Pick a legendary character from historical figures
    final pool = [
      ('einstein_icon', '🧠', 'アインシュタイン', 'Einstein'),
      ('newton_icon', '🍎', 'ニュートン', 'Newton'),
      ('curie_icon', '⚛️', 'キュリー夫人', 'Marie Curie'),
    ];
    final pick = pool[DateTime.now().millisecond % pool.length];
    final id = 'legend_${pick.$1}';
    if (p.unlockedCharacters.contains(id)) {
      p.adStreakRewardsClaimed.add('day7');
      p.adWatchStreak = 0;
      if (mounted) setState(() {});
      return;
    }
    p.unlockedCharacters.add(id);
    p.adStreakRewardsClaimed.add('day7');
    p.adWatchStreak = 0;
    p.grantBonusCoins(200); // grantBonusCoins 内で _persist が呼ばれる
    Sfx.instance.fanfare();
    HapticFeedback.heavyImpact();
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m.ja
            ? '🎉 レジェンドキャラ「${pick.$3}」を解放しました！'
            : '🎉 Legendary "${pick.$4}" unlocked!')),
      );
    }
  }

  /// 🔘 ミニボタン
  Widget _miniBtn(String label, Color color, VoidCallback? onTap, {double width = 100}) => SizedBox(
    width: width,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color, foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(40),
        padding: EdgeInsets.zero,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
      ),
      child: Text(label, textAlign: TextAlign.center),
    ),
  );

  /// 💳 広告除去（買い切り）のカード。
  /// 💰 課金セクション（コインパック・広告除去・プレミアム）。
  Widget _iapSection(MetaStrings m, PlayerProfile p) {
    final iap = IapService.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(m.iapCoinsTitle, m.iapCoinsDesc),
        _iapCoinsRow(m, p),
        const SizedBox(height: 16),
        _sectionHeader(m.iapRemoveAdsTitle, m.iapRemoveAdsDesc),
        _iapRemoveAdsRow(m, p),
        const SizedBox(height: 16),
        _sectionHeader(m.iapPremiumTitle, m.iapPremiumDesc),
        _iapPremiumRow(m, p),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () async {
            await iap.restore();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(
                  m.ja ? '購入の復元を試みました' : 'Restore attempted',
                )),
              );
            }
          },
          child: Text(m.iapRestore, style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _iapProductCard({
    required String id,
    required String label,
    required String desc,
    required Color color,
    required VoidCallback onBuy,
    bool owned = false,
    String? badge,
  }) {
    final iap = IapService.instance;
    final price = iap.priceFor(id);
    final m = MetaStrings.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(badge ?? '🪙', style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w900)),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3D6A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(badge,
                              style: const TextStyle(
                                  fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(desc,
                      style: const TextStyle(fontSize: 11, color: Colors.black54)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            owned
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Text(m.iapOwned,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w900, color: Colors.green)),
                  )
                : ElevatedButton(
                    onPressed: onBuy,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      price.isNotEmpty ? '$price' : m.iapBuy,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w900),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _iapCoinsRow(MetaStrings m, PlayerProfile p) {
    return Column(
      children: [
        _iapProductCard(
          id: IapService.productCoins500,
          label: '500 🪙',
          desc: m.ja ? '基本パック' : 'Basic pack',
          color: const Color(0xFF3A7BD5),
          onBuy: () => _doIap(IapService.productCoins500),
        ),
        const SizedBox(height: 6),
        _iapProductCard(
          id: IapService.productCoins1200,
          label: '1200 🪙',
          desc: m.ja ? 'お得パック' : 'Value pack',
          color: const Color(0xFF6E44A8),
          badge: 'お得',
          onBuy: () => _doIap(IapService.productCoins1200),
        ),
        const SizedBox(height: 6),
        _iapProductCard(
          id: IapService.productCoins3000,
          label: '3000 🪙',
          desc: m.ja ? '最大お得パック' : 'Best value',
          color: const Color(0xFFE8A400),
          badge: m.ja ? 'いちばんお得' : 'BEST',
          onBuy: () => _doIap(IapService.productCoins3000),
        ),
      ],
    );
  }

  Widget _iapRemoveAdsRow(MetaStrings m, PlayerProfile p) {
    return _iapProductCard(
      id: IapService.productRemoveAds,
      label: m.iapRemoveAdsTitle,
      desc: m.iapRemoveAdsDesc,
      color: const Color(0xFF4ECDC4),
      badge: '💎',
      owned: p.adsRemoved,
      onBuy: p.adsRemoved ? () {} : () => _doIap(IapService.productRemoveAds),
    );
  }

  Widget _iapPremiumRow(MetaStrings m, PlayerProfile p) {
    return _iapProductCard(
      id: IapService.productPremium,
      label: m.iapPremiumTitle,
      desc: m.iapPremiumDesc,
      color: const Color(0xFFFFB300),
      badge: '👑',
      owned: p.adsRemoved, // premium も adsRemoved を立てるので目安
      onBuy: () => _doIap(IapService.productPremium),
    );
  }

  Future<void> _doIap(String id) async {
    final m = MetaStrings.of(context);
    AppAnalytics.shopItemTapped(
      category: 'iap', itemId: id, cost: 0, affordable: true,
    );
    final ok = await IapService.instance.buy(id);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          m.ja ? '購入を開始できませんでした。時間をおいてお試しください。'
              : 'Could not start purchase. Please try again later.',
        )),
      );
    }
  }

  /// 💳 広告除去済みのユーザーへのお礼カード（すでに購入済みの人のみ表示）。
  Widget _removeAdsCard(MetaStrings m, PlayerProfile p) {
    if (!p.adsRemoved) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4ECDC4), width: 1.5),
      ),
      child: Row(
        children: [
          const Text('💎', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(m.adsRemovedThanks,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF12705E))),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(desc,
              style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
        ],
      ),
    );
  }

  /// 買う／装備するを1行で扱う共通の行ウィジェット。
  Widget _itemRow({
    required String emoji,
    required String name,
    String? desc,
    required int cost,
    required bool owned,
    required bool equipped,
    required VoidCallback onBuy,
    required VoidCallback onEquip,
    VoidCallback? onPreview,
    Color? tint,
  }) {
    final m = MetaStrings.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tint ?? Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: equipped ? const Color(0xFF4ECDC4) : const Color(0xFFD8E4F0),
            width: equipped ? 2 : 1.5),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w900)),
                if (desc != null && desc.isNotEmpty)
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
          if (onPreview != null && owned)
            IconButton(
              onPressed: onPreview,
              icon: const Icon(Icons.volume_up_rounded, size: 20),
              tooltip: m.shopTry,
              color: const Color(0xFF3A7BD5),
            ),
          if (equipped)
            Text(m.shopEquipped,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E9C8E)))
          else if (owned)
            TextButton(
              onPressed: onEquip,
              child: Text(m.shopEquip,
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            )
          else
            ElevatedButton(
              onPressed: onBuy,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC93C),
                foregroundColor: const Color(0xFF7A5A00),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 34),
              ),
              child: Text('🪙 $cost',
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w900)),
            ),
        ],
      ),
    );
  }

  Future<void> _buyGeneric(
    Future<bool> Function() buy,
    int cost,
    Future<void> Function() equip,
  ) async {
    final m = MetaStrings.of(context);
    if (PlayerProfile.instance.coins < cost) {
      // 「欲しいのに足りない」瞬間が動画を見てもらえる一番のタイミング。
      // ここで行き止まりのスナックバーを出すのはもったいないので、その場で誘う。
      Sfx.instance.wrong();
      await _offerAdForCoins(m, cost);
      return;
    }
    final ok = await buy();
    if (!ok) return;
    await equip(); // 買ったらすぐ使えるようにする
    Sfx.instance.reward();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(m.shopBought)));
    }
  }

  /// コインが足りないときに「動画を見てコインを増やす？」と確認して、
  /// はいならそのままリワード広告を再生する。
  Future<void> _offerAdForCoins(MetaStrings m, int cost) async {
    final short = cost - PlayerProfile.instance.coins;
    final go = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(m.notEnoughCoins),
        content: Text(m.shortByCoins(short, _adReward)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(m.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(m.storeWatchAd(_adReward)),
          ),
        ],
      ),
    );
    if (go == true && mounted) await _watchAd();
  }

  /// 🧠 知識記事の行。買ってなければ買うボタン、買ってあれば読むボタン。
  Widget _knowledgeRow(MetaStrings m, PlayerProfile p, KnowledgeArticle a) {
    final owned = p.hasArticle(a.id);
    final ja = Localizations.localeOf(context).languageCode == 'ja';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Text(a.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.title(ja),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(a.source(ja).split('\n').first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: Colors.black54)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            owned
                ? ElevatedButton(
                    onPressed: () => _readArticle(a),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4ECDC4),
                    ),
                    child: Text(m.shopKnowledgeRead(a.title(ja)),
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w900)),
                  )
                : ElevatedButton(
                    onPressed: p.coins >= a.cost
                        ? () => _buyKnowledge(a)
                        : () {
                            AppAnalytics.shopBlockedByCoins(
                                category: 'knowledge',
                                itemId: a.id,
                                shortBy: a.cost - p.coins);
                            _offerAdForCoins(m, a.cost);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8A5AC2),
                    ),
                    child: Text(
                      '🪙${a.cost}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _buyKnowledge(KnowledgeArticle a) async {
    final m = MetaStrings.of(context);
    final p = PlayerProfile.instance;
    if (p.coins < a.cost) return;
    final ok = await p.unlockArticle(a.id, a.cost);
    if (ok) {
      AppAnalytics.shopPurchase(
          category: 'knowledge', itemId: a.id, cost: a.cost, method: 'coins');
      Sfx.instance.reward();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(m.storeBoughtKnowledge),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _readArticle(KnowledgeArticle a) async {
    final ja = Localizations.localeOf(context).languageCode == 'ja';
    Sfx.instance.pop();
    AppAnalytics.featureOpen('knowledge_${a.id}', from: 'shop');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(a.title(ja),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(a.body(ja),
                  style: const TextStyle(fontSize: 13.5, height: 1.65)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(a.source(ja),
                    style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF666666),
                        height: 1.5)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ja ? 'とじる' : 'Close'),
          ),
        ],
      ),
    );
  }

  Widget _voiceRow(MetaStrings m, PlayerProfile p, PraiseVoice v) {
    final owned = p.unlockedVoices.contains(v.id);
    return _itemRow(
      emoji: v.emoji,
      name: v.name(m.ja),
      desc: v.lines(m.ja).isEmpty ? null : '「${v.lines(m.ja).first}」',
      cost: v.cost,
      owned: owned,
      equipped: p.selectedVoice == v.id,
      onBuy: () => _buyGeneric(
          () => p.unlockVoice(v.id, v.cost), v.cost, () => p.selectVoice(v.id)),
      onEquip: () {
        Sfx.instance.pop();
        p.selectVoice(v.id);
      },
      onPreview: v.id == 'none'
          ? null
          : () async {
              await p.selectVoice(v.id);
              Speech.instance.praise(ja: m.ja);
            },
    );
  }

  Widget _charmRow(MetaStrings m, PlayerProfile p, LuckyCharm c) {
    final owned = p.unlockedCharms.contains(c.id);
    return _itemRow(
      emoji: c.emoji,
      name: c.name(m.ja),
      desc: c.desc(m.ja),
      cost: c.cost,
      owned: owned,
      equipped: p.selectedCharm == c.id,
      onBuy: () => _buyGeneric(
          () => p.unlockCharm(c.id, c.cost), c.cost, () => p.selectCharm(c.id)),
      onEquip: () {
        Sfx.instance.pop();
        p.selectCharm(c.id);
      },
    );
  }

  Widget _themeRow(MetaStrings m, PlayerProfile p, HomeTheme t) {
    return _itemRow(
      emoji: t.emoji,
      name: m.ja ? t.nameJa : t.nameEn,
      cost: t.cost,
      owned: p.unlockedThemes.contains(t.id),
      equipped: p.selectedTheme == t.id,
      tint: t.subtle.first,
      onBuy: () => _buyGeneric(
          () => p.unlockTheme(t.id, t.cost), t.cost, () => p.selectTheme(t.id)),
      onEquip: () {
        Sfx.instance.pop();
        p.selectTheme(t.id);
      },
    );
  }

  /// 🎵 BGM行。買う／**動画1本で解放**／試聴／装備 を1行で扱う。
  ///
  /// 「コインが足りないから諦める」で終わらせず、動画を見れば必ず手に入る道を
  /// 用意しておくと、リワード広告の再生数が伸びる（かつユーザーも損をしない）。
  Widget _bgmRow(MetaStrings m, PlayerProfile p, BgmItem b) {
    final owned = p.unlockedBgm.contains(b.asset);
    final selected = p.selectedBgm == b.asset;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: selected ? const Color(0xFF4ECDC4) : const Color(0xFFD8E4F0),
            width: selected ? 2 : 1.5),
      ),
      child: Row(
        children: [
          const Text('🎵', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.name(m.ja),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w900)),
                if (b.needsCredit)
                  const Text('魔王魂',
                      style: TextStyle(fontSize: 10.5, color: Colors.black45)),
              ],
            ),
          ),
          // ▶️ 試聴は持っていない曲でもできる。
          //    買う前に聴けないと、どれを選べばいいか分からない。
          IconButton(
            onPressed: () => Bgm.instance.preview(b.asset),
            icon: const Icon(Icons.play_arrow_rounded, size: 22),
            tooltip: m.shopTry,
            color: const Color(0xFF3A7BD5),
          ),
          if (selected)
            Text(m.shopEquipped,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E9C8E)))
          else if (owned)
            TextButton(
              onPressed: () async {
                Sfx.instance.pop();
                await p.selectBgm(b.asset);
                Bgm.instance.restartCurrent();
              },
              child: Text(m.shopEquip,
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            )
          else ...[
            // 動画1本で解放（コイン不要）
            if (RewardAdHelper.available)
              TextButton(
                onPressed: () => _unlockBgmByAd(m, b),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 34),
                ),
                child: Text(m.unlockByAd,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w900)),
              ),
            ElevatedButton(
              onPressed: () => _buyGeneric(
                  () => p.unlockBgm(b.asset, b.cost), b.cost, () async {
                await p.selectBgm(b.asset);
                Bgm.instance.restartCurrent();
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC93C),
                foregroundColor: const Color(0xFF7A5A00),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 34),
              ),
              child: Text('🪙 ${b.cost}',
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w900)),
            ),
          ],
        ],
      ),
    );
  }

  /// 動画を最後まで見たら、その曲をコインなしで解放してすぐ再生する。
  Future<void> _unlockBgmByAd(MetaStrings m, BgmItem b) async {
    final p = PlayerProfile.instance;
    final playedNow = await _rewardAd.showOrQueue(onReward: () async {
      await p.unlockBgm(b.asset, 0); // 広告視聴分なのでコインは引かない
      await p.selectBgm(b.asset);
      Bgm.instance.restartCurrent();
      Sfx.instance.reward();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(m.shopBought)));
      }
    });
    if (!playedNow && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(m.storeAdLoading)));
    }
  }

  Widget _ownedThumb(String asset) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(asset,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, __, ___) => _silhouette()),
    );
  }

  Widget _silhouette() => Container(
        color: const Color(0xFFDCE6F2),
        child: const Icon(Icons.person, color: Color(0xFF9FB8D4), size: 36),
      );

  Widget _charCard(MetaStrings m, GameCharacter c, bool owned) {
    // 🏆 実績キャラはコインで買えない。条件だけ見せて、腕前で取ってもらう。
    final feat = c.feat;
    final locked = feat != null && !owned;
    return GestureDetector(
      onTap: owned
          ? null
          : locked
              ? () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(m.featLocked(m.featCondition(feat)))))
              : () => _buy(c),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: owned ? const Color(0xFF4ECDC4) : const Color(0xFFD8E4F0),
              width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(c.asset,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (_, __, ___) => _silhouette()),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Text(c.emoji, style: const TextStyle(fontSize: 16)),
                  ),
                  if (owned)
                    Container(
                      color: Colors.black.withValues(alpha: 0.28),
                      alignment: Alignment.center,
                      child: const Icon(Icons.check_circle,
                          color: Colors.white, size: 34),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: owned
                  ? const Color(0xFFDFF5F2)
                  : locked
                      ? const Color(0xFFEFE6FF)
                      : const Color(0xFFFFF3D6),
              child: Text(
                owned
                    ? m.storeOwned
                    : locked
                        ? '🏆 ${m.featCondition(feat)}'
                        : '🪙 ${c.cost}',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: owned
                        ? const Color(0xFF1E9C8E)
                        : locked
                            ? const Color(0xFF5B3E9E)
                            : const Color(0xFF7A5A00)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
