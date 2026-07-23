import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';

import '../l10n/meta_strings.dart';
import '../models/character_catalog.dart';
import '../models/person.dart';
import '../services/player_profile.dart';
import '../services/reward_ad_helper.dart';
import '../services/sfx.dart';

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
                    const SizedBox(height: 16),
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
