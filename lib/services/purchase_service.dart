import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'player_profile.dart';

/// 💳 買い切り課金（広告除去）。
///
/// 商品は1つだけの**非消費型（non-consumable）**:
///   `remove_ads` … バナー／インタースティシャルを消す
///
/// ⚠️ Play Console 側で同じ商品IDのアプリ内アイテムを作らないと、
/// [products] は空のままになり購入ボタンは出ない（コードだけでは完結しない）。
///
/// 注意点:
/// - 非消費型なので `completePurchase` は呼ぶが消費はしない
/// - 機種変更・再インストールに備えて「購入を復元」を必ず用意する
///   （Googleの要件でもあり、無いと問い合わせが増える）
/// - リワード広告は**消さない**。ユーザーが自分の意思でコインを得る手段であり、
///   消すと逆に不便になるため（広告除去の対象はバナーと全画面のみ）
class PurchaseService extends ChangeNotifier {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  /// Play Console に登録する商品ID。
  static const String removeAdsId = 'remove_ads';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool _available = false;
  bool _pending = false;
  List<ProductDetails> _products = [];

  /// ストアに接続できているか（Web やエミュレータでは false になりうる）。
  bool get available => _available;

  /// 購入処理の途中か（ボタンの二度押し防止に使う）。
  bool get pending => _pending;

  List<ProductDetails> get products => _products;

  /// 広告除去の商品（未取得なら null）。
  ProductDetails? get removeAdsProduct {
    for (final p in _products) {
      if (p.id == removeAdsId) return p;
    }
    return null;
  }

  /// 表示用の価格（"¥370" など）。取得できていなければ null。
  String? get removeAdsPrice => removeAdsProduct?.price;

  Future<void> init() async {
    if (kIsWeb) return; // Web はストア非対応
    try {
      _available = await _iap.isAvailable();
      if (!_available) {
        notifyListeners();
        return;
      }
      // 購入ストリームは init 中に来る復元通知も拾うので先に張る
      _sub = _iap.purchaseStream.listen(
        _onPurchaseUpdated,
        onError: (Object e) => debugPrint('purchaseStream error: $e'),
      );
      final res = await _iap.queryProductDetails({removeAdsId});
      _products = res.productDetails;
      if (res.notFoundIDs.isNotEmpty) {
        // Play Console に商品が未登録／審査中だとここに入る
        debugPrint('IAP products not found: ${res.notFoundIDs}');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('PurchaseService init failed: $e');
      _available = false;
      notifyListeners();
    }
  }

  /// 広告除去を購入する。
  Future<void> buyRemoveAds() async {
    final product = removeAdsProduct;
    if (product == null || _pending) return;
    _pending = true;
    notifyListeners();
    try {
      // 非消費型なので buyNonConsumable を使う
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (e) {
      debugPrint('buyRemoveAds failed: $e');
      _pending = false;
      notifyListeners();
    }
  }

  /// 購入を復元する（機種変更・再インストール時）。
  /// 結果は purchaseStream に流れてくる。
  Future<void> restore() async {
    if (!_available) return;
    _pending = true;
    notifyListeners();
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('restorePurchases failed: $e');
    }
    _pending = false;
    notifyListeners();
  }

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.pending:
          _pending = true;
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (p.productID == removeAdsId) {
            await PlayerProfile.instance.setAdsRemoved(true);
          }
          _pending = false;
          break;
        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          debugPrint('purchase ${p.status}: ${p.error}');
          _pending = false;
          break;
      }
      // 保留のままだと以後の購入がブロックされるので必ず完了させる
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
