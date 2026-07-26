import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';

import '../l10n/meta_strings.dart';
import '../models/character_catalog.dart';
import '../models/person.dart';
import '../models/shop_items.dart';
import '../services/player_profile.dart';
import '../services/reward_ad_helper.dart';
import '../services/sfx.dart';
import '../services/speech.dart';

/// 🛍 キャラクターショップ。
/// - 動画（リワード広告）でコインを稼ぐ導線
/// - コインで追加キャラを購入（なまえコール／ビジネス特訓の出演プールに加わる）
/// - アプリ評価（★）でストア評価を後押し
class CharacterShopScreen extends StatefulWidget {
  const CharacterShopScreen({super.key});

  @override
  State<CharacterShopScreen> createState() => _CharacterShopScreenState();
}

class _CharacterShopScreenState extends State<CharacterShopScreen> {
  final RewardAdHelper _rewardAd = RewardAdHelper();
  static const int _adReward = 60;

  @override
  void initState() {
    super.initState();
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
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await PlayerProfile.instance.markReviewPrompted();
        await review.requestReview();
      } else {
        await review.openStoreListing();
      }
    } catch (_) {}
  }

  Future<void> _buy(GameCharacter c) async {
    final m = MetaStrings.of(context);
    final p = PlayerProfile.instance;
    if (p.unlockedCharacters.contains(c.id)) return;
    if (p.coins < c.cost) {
      Sfx.instance.wrong();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(m.notEnoughCoins)));
      return;
    }
    final ok = await p.unlockCharacter(c.id, c.cost);
    if (ok) {
      Sfx.instance.reward();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(m.storeBought)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(m.storeTitle)),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF3FF), Color(0xFFFFF9EC)],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge([PlayerProfile.instance, _rewardAd]),
            builder: (context, _) {
              final p = PlayerProfile.instance;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // コイン残高
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3D6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFFFC93C), width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Text(m.storeCoins(p.coins),
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF7A5A00))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 動画でコイン & 評価
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _rewardAd.isLoading ? null : _watchAd,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4ECDC4),
                              minimumSize: const Size.fromHeight(50),
                            ),
                            child: Text(
                              _rewardAd.isLoading
                                  ? m.storeAdLoading
                                  : m.storeWatchAd(_adReward),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 13.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _rate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFB300),
                              minimumSize: const Size.fromHeight(50),
                            ),
                            child: Text(m.storeRate,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13.5)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(m.storeHint,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11.5, color: Colors.black54)),
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
                    // 💳 名刺のデザイン
                    _sectionHeader(m.shopSkinsTitle, m.shopSkinsDesc),
                    _skinRow(m, p),
                    const SizedBox(height: 20),
                    // 追加キャラ
                    Text(m.storeMore,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
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
                    // 基本キャラ（所持）
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
                  ],
                ),
              );
            },
          ),
        ),
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
      Sfx.instance.wrong();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(m.notEnoughCoins)));
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

  Widget _skinRow(MetaStrings m, PlayerProfile p) {
    return Column(
      children: [
        for (final s in kCardSkins)
          _itemRow(
            emoji: s.emoji,
            name: s.name(m.ja),
            cost: s.cost,
            owned: p.unlockedSkins.contains(s.id),
            equipped: p.selectedSkin == s.id,
            tint: Color(s.bgBottom).withValues(alpha: 0.55),
            onBuy: () => _buyGeneric(() => p.unlockSkin(s.id, s.cost), s.cost,
                () => p.selectSkin(s.id)),
            onEquip: () {
              Sfx.instance.pop();
              p.selectSkin(s.id);
            },
          ),
      ],
    );
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
    return GestureDetector(
      onTap: owned ? null : () => _buy(c),
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
              color: owned ? const Color(0xFFDFF5F2) : const Color(0xFFFFF3D6),
              child: Text(
                owned ? m.storeOwned : '🪙 ${c.cost}',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: owned
                        ? const Color(0xFF1E9C8E)
                        : const Color(0xFF7A5A00)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
