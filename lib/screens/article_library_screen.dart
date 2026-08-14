import 'package:flutter/material.dart';

import '../l10n/meta_strings.dart';
import '../l10n/premium_articles.dart';
import '../services/app_analytics.dart';
import '../services/reward_ad_helper.dart';
import '../services/rewarded_interstitial_helper.dart';
import '../services/player_profile.dart';
import '../services/sfx.dart';
import '../widgets/banner_ad_slot.dart';
import '../widgets/coin_short_sheet.dart';
import '../widgets/themed_background.dart';

/// 📚 コインで読める読み物の一覧。
///
/// **タイトルと導入は最初から読める**。何の話か分からないものに
/// コインは払えないので、「読むと何が分かるか」までは先に見せる。
///
/// コインが足りない人には、その場で動画を見て貯める道を用意する
/// （読みたい気持ちがいちばん高いのがこの瞬間なので、
///  ここが動画を見てもらえる一番の場所になる）。
class ArticleLibraryScreen extends StatefulWidget {
  const ArticleLibraryScreen({super.key});

  @override
  State<ArticleLibraryScreen> createState() => _ArticleLibraryScreenState();
}

class _ArticleLibraryScreenState extends State<ArticleLibraryScreen> {
  final RewardAdHelper _rewardAd = RewardAdHelper(placement: 'article_library');

  @override
  void initState() {
    super.initState();
    _rewardAd.load();
    RewardedInterstitialHelper.instance.load();
  }

  @override
  void dispose() {
    _rewardAd.dispose();
    super.dispose();
  }

  Future<void> _open(PremiumArticle a) async {
    final m = MetaStrings.of(context);
    final p = PlayerProfile.instance;
    if (!p.hasArticle(a.id)) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(a.title(m.ja),
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          content: Text(m.articleBuyConfirm(a.cost, p.coins)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text(m.cancel)),
            ElevatedButton(
                onPressed: () => Navigator.pop(c, true),
                child: Text(m.articleBuy)),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      final bought = await p.unlockArticle(a.id, a.cost);
      if (!mounted) return;
      if (!bought) {
        await _offerCoins(m, a);
        return;
      }
      Sfx.instance.coin();
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _ArticleReaderScreen(article: a)),
    );
  }

  /// コインが足りないときに、その場で貯める道を出す。
  ///
  /// ここだけ共通の offerAdForCoins を使わず自前で持っているのは**わざと**。
  /// 先にリワードインタースティシャルを試す（単価が高い）作りになっていて、
  /// そちらのほうが取りこぼしが少ないため。文言と報酬額だけそろえる。
  Future<void> _offerCoins(MetaStrings m, PremiumArticle a) async {
    final p = PlayerProfile.instance;
    // 「何が欲しくて足りなかったか」「その結果 動画を見たか」を残す
    AppAnalytics.shopBlockedByCoins(
        category: 'article', itemId: a.id, shortBy: a.cost - p.coins);
    AppAnalytics.adOfferedForItem(
      category: 'article',
      itemId: a.id,
      cost: a.cost,
      coinsHeld: p.coins,
    );
    final want = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(m.articleNotEnough),
        content: Text(m.articleWatchToEarn(kCoinAdReward)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false), child: Text(m.cancel)),
          ElevatedButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(m.articleWatchButton)),
        ],
      ),
    );
    if (want != true || !mounted) return;
    void grant() {
      PlayerProfile.instance.grantBonusCoins(kCoinAdReward);
      Sfx.instance.reward();
      if (mounted) setState(() {});
    }

    // まずリワードインタースティシャル、無理なら通常のリワード広告
    final shown = await RewardedInterstitialHelper.instance
        .show(placement: 'article_unlock', onReward: grant);
    if (shown) return;
    await _rewardAd.showOrQueue(onReward: grant);
  }

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    final p = PlayerProfile.instance;
    return Scaffold(
      bottomNavigationBar: const BannerAdSlot(),
      appBar: AppBar(
        title: Text(m.articleLibraryTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: AnimatedBuilder(
                animation: p,
                builder: (_, __) => Text('🪙 ${p.coins}',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        ],
      ),
      body: ThemedBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: p,
            builder: (context, _) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(m.articleLibraryLead,
                    style: const TextStyle(fontSize: 12.5, height: 1.6)),
                const SizedBox(height: 14),
                for (final a in kPremiumArticles) _row(m, a, p.hasArticle(a.id)),
                const SizedBox(height: 10),
                Text(m.articleDisclaimer,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.black54, height: 1.6)),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(MetaStrings m, PremiumArticle a, bool owned) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _open(a),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: a.gradient),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: owned ? const Color(0xFF2E9E5B) : const Color(0xFFD8E4F0),
                width: 1.6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(a.title(m.ja),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: owned ? const Color(0xFF2E9E5B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      owned ? m.articleOwned : '🪙${a.cost}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: owned ? Colors.white : const Color(0xFF8A6A1E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // 買う前でも「何の話か」は読める
              Text(a.lead(m.ja),
                  style: const TextStyle(fontSize: 12, height: 1.6)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 買った記事の本文。
class _ArticleReaderScreen extends StatelessWidget {
  final PremiumArticle article;
  const _ArticleReaderScreen({required this.article});

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    return Scaffold(
      bottomNavigationBar: const BannerAdSlot(),
      appBar: AppBar(title: Text('${article.emoji} ${article.title(m.ja)}')),
      body: SafeArea(
        child: Container(
          decoration:
              BoxDecoration(gradient: LinearGradient(colors: article.gradient)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              Text(article.title(m.ja),
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w900, height: 1.5)),
              const SizedBox(height: 14),
              Text(article.body(m.ja),
                  style: const TextStyle(fontSize: 14, height: 1.9)),
              const SizedBox(height: 22),
              Text(m.articleSources,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              for (final s in article.sources)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('・$s',
                      style: const TextStyle(fontSize: 11.5, height: 1.6)),
                ),
              const SizedBox(height: 16),
              Text(m.articleDisclaimer,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.black54, height: 1.6)),
            ],
          ),
        ),
      ),
    );
  }
}
