import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';

import '../l10n/meta_strings.dart';
import '../models/bgm_catalog.dart';
import '../models/character_catalog.dart';
import '../models/cosmetics.dart';
import '../models/person.dart';
import '../models/shop_items.dart';
import '../services/app_analytics.dart';
import '../services/bgm.dart';
import '../services/player_profile.dart';
import '../services/reward_ad_helper.dart';
import '../services/sfx.dart';
import '../services/speech.dart';
import '../widgets/themed_background.dart';
import '../widgets/banner_ad_slot.dart';
import '../widgets/coin_short_sheet.dart';
import 'character_deck_screen.dart';

/// 🛍 キャラクターショップ。
/// - 動画（リワード広告）でコインを稼ぐ導線
/// - コインで追加キャラを購入（なまえコール／ビジネス特訓の出演プールに加わる）
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
  /// 動画1本ぶんのコイン。コイン不足ダイアログと同額でないと
  /// 「60もらえる」と言われて別の額が入ることになるので、共通の定数を使う。
  static const int _adReward = kCoinAdReward;

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
      // （分析イベントと効果音は offerAdForCoins の中で出す）
      await _offerAdForCoins(c.cost, category: 'character', itemId: c.id);
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
                    // 💳 広告除去（買い切り）
                    _removeAdsCard(m, p),
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

  /// 💳 広告除去（買い切り）のカード。
  ///
  /// Play が Billing Library 8.0.0 以降を必須化したが、対応版の
  /// in_app_purchase は Dart 3.10 以上（Flutter 3.35+）を要求し、
  /// 本プロジェクトの Flutter 3.32 では解決できない。
  /// アップデート自体が承認されなくなるため、課金機能はいったん取り下げた。
  ///
  /// **すでに購入した人の権利は残す**: adsRemoved は端末に保存されたままで、
  /// バナー・全画面広告の抑制もそのまま効く。ここではお礼だけ出す。
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
    Future<void> Function() equip, {
    required String category,
    required String itemId,
  }) async {
    final m = MetaStrings.of(context);
    if (PlayerProfile.instance.coins < cost) {
      // 「欲しいのに足りない」瞬間が動画を見てもらえる一番のタイミング。
      // ここで行き止まりのスナックバーを出すのはもったいないので、その場で誘う。
      await _offerAdForCoins(cost, category: category, itemId: itemId);
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
  ///
  /// 中身は widgets/coin_short_sheet.dart に移した
  /// （マイページのテーマ・衣装・BGMでも同じ「足りない」が起きるため）。
  Future<void> _offerAdForCoins(
    int cost, {
    required String category,
    required String itemId,
  }) async {
    await offerAdForCoins(
      context,
      ad: _rewardAd,
      cost: cost,
      category: category,
      itemId: itemId,
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
          () => p.unlockVoice(v.id, v.cost), v.cost, () => p.selectVoice(v.id),
          category: 'voice', itemId: v.id),
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
          () => p.unlockCharm(c.id, c.cost), c.cost, () => p.selectCharm(c.id),
          category: 'charm', itemId: c.id),
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
          () => p.unlockTheme(t.id, t.cost), t.cost, () => p.selectTheme(t.id),
          category: 'theme', itemId: t.id),
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
              }, category: 'bgm', itemId: b.asset),
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
      Bgm.instance.restartGameBgm();
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
    // 🏆 実績・📅 ログイン枠は「条件を満たせばタダで手に入る」枠だが、
    //    コインでも買える（PlayerProfile.unlockCharacter が許可している）。
    //    以前ここで購入を封じていたため、600〜900コインという値付けが
    //    到達不能な死にデータになり、いちばん大きなコインの使い道が消えていた。
    //    条件はバッジで見せつつ、買う道も開けておく。
    final feat = c.feat;
    final featGated = feat != null && !owned;
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
                  // 🏆 条件を満たせばタダで取れる枠、という手がかり
                  if (featGated)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B3E9E).withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('🏆',
                            style: TextStyle(fontSize: 11)),
                      ),
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
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
              color: owned
                  ? const Color(0xFFDFF5F2)
                  : featGated
                      ? const Color(0xFFEFE6FF)
                      : const Color(0xFFFFF3D6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    owned ? m.storeOwned : '🪙 ${c.cost}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: owned
                            ? const Color(0xFF1E9C8E)
                            : featGated
                                ? const Color(0xFF5B3E9E)
                                : const Color(0xFF7A5A00)),
                  ),
                  // 買わずに取る道も併記する（そちらが本筋）
                  if (featGated)
                    Text(
                      m.featCondition(feat),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF7B65B5)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
