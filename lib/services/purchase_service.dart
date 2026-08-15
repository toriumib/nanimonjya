import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'app_analytics.dart';
import 'player_profile.dart';

/// 💳 課金。**非消費型1つ**と**消費型3つ**を扱う。
///
/// 非消費（買い切り）:
///   `remove_ads` … バナー／インタースティシャルを消す
///
/// 消費型（コインパック）:
///   `coins_small` / `coins_medium` / `coins_large`
///
/// ⚠️ Play Console 側で同じ商品IDのアプリ内アイテムを作らないと、
/// [products] は空のままになり購入ボタンは出ない（コードだけでは完結しない）。
/// **IDが1文字でも違うと queryProductDetails が空を返す。**
///
/// 注意点:
/// - 非消費型なので `completePurchase` は呼ぶが消費はしない
/// - 消費型は `buyConsumable(autoConsume: true)`。非消費型と取り違えると
///   一度買ったきり二度と買えなくなる
/// - **復元でコインパックを配らないこと**。消費型は復元の対象外で、
///   `PurchaseStatus.restored` で付与すると再インストールのたびに
///   無限にコインが増える。復元で処理してよいのは `remove_ads` だけ
/// - 機種変更・再インストールに備えて「購入を復元」を必ず用意する
///   （Googleの要件でもあり、無いと問い合わせが増える）
/// - リワード広告は**消さない**。ユーザーが自分の意思でコインを得る手段であり、
///   消すと逆に不便になるため（広告除去の対象はバナーと全画面のみ）
class PurchaseService extends ChangeNotifier {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  /// Play Console に登録する商品ID。
  static const String removeAdsId = 'remove_ads';

  /// 🪙 コインパック（消費型）。商品ID → もらえるコイン。
  ///
  /// 額の決め方: 単価を低く抑えて入口を広げる方針。
  /// 既存の使い道はキャラ 120〜900、テーマ 〜1,200、BGM 〜800、記事 120〜180
  /// なので、いちばん小さいパックでもキャラが数体買える。
  /// いちばん大きいパックでも**全部は埋まらない**量にして、
  /// 買ったあとの目標が消えないようにしてある。
  ///
  /// ⚠️ ID にハイフンは使えない（Play の商品IDは小文字・数字・
  ///    アンダースコア・ピリオドのみ）。以前 `coins-500` と書かれていたが、
  ///    そのままでは Play Console に登録できない。
  static const Map<String, int> kCoinPacks = {
    'coins_small': 500,
    'coins_medium': 1200,
    'coins_large': 3000,
  };

  /// 表示順（安い順）。Play から返る順は保証されないので自前で持つ。
  static const List<String> kCoinPackOrder = [
    'coins_small',
    'coins_medium',
    'coins_large',
  ];

  static Set<String> get _allIds => {removeAdsId, ...kCoinPacks.keys};

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

  /// 商品IDから ProductDetails を引く（未取得なら null）。
  ProductDetails? productById(String id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// 取得できたコインパックだけを、安い順に返す。
  /// Play に未登録のものは並ばない（押せない行を見せないため）。
  List<ProductDetails> get coinPacks => [
        for (final id in kCoinPackOrder)
          if (productById(id) != null) productById(id)!,
      ];

  /// 表示用の価格文字列。取れていなければ空文字。
  /// ⚠️ 価格は必ずここ（ストアが返す値）から取ること。
  ///    通貨も税込み表記も国ごとに違うので、アプリ側で組み立ててはいけない。
  String priceFor(String id) => productById(id)?.price ?? '';

  /// 商品IDを見て適切な購入方式に振り分ける。
  /// 開始できたら true（購入の成否は purchaseStream 側で決まる）。
  Future<bool> buy(String id) async {
    if (productById(id) == null || _pending) return false;
    if (id == removeAdsId) {
      await buyRemoveAds();
      return true;
    }
    if (kCoinPacks.containsKey(id)) {
      await buyCoinPack(id);
      return true;
    }
    return false;
  }

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
      final res = await _iap.queryProductDetails(_allIds);
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

  /// 🪙 コインパックを購入する。
  ///
  /// ⚠️ 消費型なので `buyConsumable`。`buyNonConsumable` と取り違えると
  ///    一度買ったきり二度と買えなくなる（Playが所有済みとして弾く）。
  Future<void> buyCoinPack(String productId) async {
    if (!kCoinPacks.containsKey(productId)) return;
    final product = productById(productId);
    if (product == null || _pending) return;
    _pending = true;
    notifyListeners();
    try {
      await _iap.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
        autoConsume: true,
      );
    } catch (e) {
      debugPrint('buyCoinPack($productId) failed: $e');
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
            // 買い切りなので、購入でも復元でも同じように反映してよい
            await PlayerProfile.instance.setAdsRemoved(true);
            AppAnalytics.shopPurchase(
              category: 'iap',
              itemId: removeAdsId,
              cost: 0,
              method: 'iap',
            );
          } else if (kCoinPacks.containsKey(p.productID)) {
            // ⚠️ 復元では**絶対に**コインを配らないこと。
            //    消費型は復元の対象外で、restored で付与すると
            //    再インストールのたびにコインが無限に増える。
            if (p.status == PurchaseStatus.purchased) {
              final amount = kCoinPacks[p.productID]!;
              await PlayerProfile.instance.grantPurchasedCoins(amount);
              AppAnalytics.shopPurchase(
                category: 'iap',
                itemId: p.productID,
                cost: amount,
                method: 'iap',
              );
            }
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
