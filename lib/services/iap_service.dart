import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/character_catalog.dart';
import '../models/knowledge_shop.dart';
import '../services/app_analytics.dart';
import '../services/player_profile.dart';
import '../services/sfx.dart';

/// Google Play / App Store 課金サービス。
///
/// ## 商品一覧
///
/// | ID | 種類 | 内容 |
/// |----|------|------|
/// | `coins_500` | 消費型 | 500コイン |
/// | `coins_1200` | 消費型 | 1200コイン（お得） |
/// | `coins_3000` | 消費型 | 3000コイン（いちばんお得） |
/// | `remove_ads` | 非消費型 | 広告を完全に消す（買い切り） |
/// | `premium` | 非消費型 | プレミアム（広告除去＋全キャラ＋殿堂全記事＋2000コイン） |
///
/// ## 使い方
///
/// ```dart
/// await IapService.instance.init();
/// IapService.instance.buy('coins_500');
/// ```
///
/// Web では課金は動かない（kIsWeb ガード）。Android と iOS で動作する。
class IapService {
  IapService._();
  static final IapService instance = IapService._();

  final InAppPurchase _iap = InAppPurchase.instance;

  /// ストアに登録されている商品の情報。
  List<ProductDetails> _products = [];

  /// 購入処理のストリーム。アプリ起動中ずっとlistenする。
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool _initialized = false;
  bool _restoring = false;

  /// Webでは動かない
  bool get available => !kIsWeb;

  /// 商品IDの定数（Google Play Console に登録するIDと一致させる）
  static const productCoins500 = 'coins_500';
  static const productCoins1200 = 'coins_1200';
  static const productCoins3000 = 'coins_3000';
  static const productRemoveAds = 'remove_ads';
  static const productPremium = 'premium';

  /// すべての商品ID
  static const allProductIds = [
    productCoins500,
    productCoins1200,
    productCoins3000,
    productRemoveAds,
    productPremium,
  ];

  /// 起動時に一度だけ呼ぶ。
  /// - ストアに接続
  /// - 商品情報を取得
  /// - 未完了の購入を処理
  Future<void> init() async {
    if (!available || _initialized) return;

    // 購入完了・保留のストリームを監視
    _sub = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (err) {
        debugPrint('IAP purchase stream error: $err');
      },
    );

    // ストアに接続して商品情報を取得
    final response = await _iap.queryProductDetails(allProductIds.toSet());
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('IAP: not found: ${response.notFoundIDs}');
    }
    if (response.error != null) {
      debugPrint('IAP query error: ${response.error}');
    }
    _products = response.productDetails;
    _initialized = true;
  }

  /// 商品情報を取得。未初期化なら空リスト。
  List<ProductDetails> get products => _products;

  /// 商品IDから商品情報を引く。
  ProductDetails? product(String id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// 商品の表示価格。見つからなければ空文字。
  String priceFor(String id) {
    final p = product(id);
    return p?.price ?? '';
  }

  /// 購入する。
  Future<bool> buy(String id) async {
    if (!available) return false;
    final p = product(id);
    if (p == null) {
      debugPrint('IAP: product $id not found');
      return false;
    }
    final param = PurchaseParam(productDetails: p);
    try {
      return await _iap.buyConsumable(
        purchaseParam: param,
        // 消費型は autoConsume: true（自動で消費して在庫に戻す）
        autoConsume: id != productRemoveAds && id != productPremium,
      );
    } catch (e) {
      debugPrint('IAP buy error: $e');
      return false;
    }
  }

  /// 購入をリストアする（機種変更時の復元）。
  /// 非消費型（remove_ads, premium）だけが対象。
  Future<void> restore() async {
    if (!available || _restoring) return;
    _restoring = true;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('IAP restore error: $e');
    }
    _restoring = false;
  }

  /// 購入ストリームの処理。
  void _onPurchaseUpdate(List<PurchaseDetails> details) {
    for (final p in details) {
      _deliverPurchase(p);
    }
  }

  /// 1件の購入を処理して報酬を付与する。
  Future<void> _deliverPurchase(PurchaseDetails p) async {
    final id = p.productID;

    if (p.status == PurchaseStatus.purchased ||
        p.status == PurchaseStatus.restored) {
      switch (id) {
        case productCoins500:
          await PlayerProfile.instance.grantBonusCoins(500);
          AppAnalytics.shopPurchase(
              category: 'iap', itemId: id, cost: 500, method: 'iap');
          break;

        case productCoins1200:
          await PlayerProfile.instance.grantBonusCoins(1200);
          AppAnalytics.shopPurchase(
              category: 'iap', itemId: id, cost: 1200, method: 'iap');
          break;

        case productCoins3000:
          await PlayerProfile.instance.grantBonusCoins(3000);
          AppAnalytics.shopPurchase(
              category: 'iap', itemId: id, cost: 3000, method: 'iap');
          break;

        case productRemoveAds:
          await PlayerProfile.instance.setAdsRemoved(true);
          AppAnalytics.shopPurchase(
              category: 'iap', itemId: id, cost: 0, method: 'iap');
          break;

        case productPremium:
          await _deliverPremium();
          AppAnalytics.shopPurchase(
              category: 'iap', itemId: id, cost: 0, method: 'iap');
          break;

        default:
          debugPrint('IAP: unknown product $id');
      }

      Sfx.instance.fanfare();
    }

    // 完了した購入をマーク
    await _iap.completePurchase(p);
  }

  /// プレミアム特典を全部付与する。
  Future<void> _deliverPremium() async {
    final profile = PlayerProfile.instance;

    // 広告除去
    await profile.setAdsRemoved(true);

    // 全キャラ解放
    for (final c in kExtraCharacters) {
      if (!profile.unlockedCharacters.contains(c.id)) {
        await profile.unlockCharacter(c.id, 0);
      }
    }

    // コイン2000枚
    await profile.grantBonusCoins(2000);

    // 全知識記事解放
    for (final a in kKnowledgeArticles) {
      if (!profile.hasArticle(a.id)) {
        await profile.unlockArticle(a.id, 0);
      }
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}

