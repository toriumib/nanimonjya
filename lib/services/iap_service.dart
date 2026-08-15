import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/character_catalog.dart';
import '../models/knowledge_shop.dart';
import 'app_analytics.dart';
import 'player_profile.dart';
import 'sfx.dart';

/// 💳 Google Play / App Store 課金サービス。
///
/// ## 商品一覧
///
/// | ID | 種類 | 内容 |
/// |----|------|------|
/// | `coins-500` | 消費型 | 500コイン |
/// | `coins-1200` | 消費型 | 1200コイン（お得） |
/// | `coins-3000` | 消費型 | 3000コイン（いちばんお得） |
/// | `remove-ads` | 非消費型 | 広告を完全に消す（買い切り） |
/// | `premium` | 非消費型 | プレミアム（広告除去＋全キャラ＋殿堂全記事＋2000コイン） |
///
/// ## 経緯
///
/// Play が Billing Library 8.0.0 以降を必須化したとき、対応する
/// `in_app_purchase_android` が Dart 3.10 を要求したのに対し、当時の
/// このプロジェクトは Flutter 3.32（Dart 3.8）だったため、**依存ごと外して
/// 全メソッドを空のスタブにしていた**（＝課金は1円も発生しない状態）。
/// Flutter 3.38 に上げて復活させたのがこの実装。
///
/// ## 注意
///
/// - Web では動かない（`kIsWeb` ガード）。
/// - 商品は **Play Console に登録して有効化するまで `queryProductDetails` が
///   空を返す**。そのあいだ [available] は false になり、購入UIは出ない。
/// - Android の購入は3日以内に承認（acknowledge）しないと自動返金される。
///   承認は [InAppPurchase.completePurchase] が行うので、
///   **報酬を渡したあとに必ず呼ぶこと**。
class IapService extends ChangeNotifier {
  IapService._();
  static final IapService instance = IapService._();

  final InAppPurchase _iap = InAppPurchase.instance;

  /// ストアに登録されている商品の情報。
  List<ProductDetails> _products = [];

  /// 購入処理のストリーム。アプリ起動中ずっとlistenする。
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool _initialized = false;
  bool _restoring = false;

  /// ストアにつながって商品が取れたか。
  ///
  /// これが false のあいだ購入UIは出さない。値段の出ないカードを並べても
  /// 押した先で失敗するだけなので、出さないほうがいい。
  bool _storeReady = false;

  /// 課金UIを出してよいか。
  bool get available => !kIsWeb && _storeReady;

  /// 商品IDの定数（Play Console に登録するIDと完全一致させる。後から変更不可）
  static const productCoins500 = 'coins-500';
  static const productCoins1200 = 'coins-1200';
  static const productCoins3000 = 'coins-3000';
  static const productRemoveAds = 'remove-ads';
  static const productPremium = 'premium';

  /// すべての商品ID
  static const allProductIds = [
    productCoins500,
    productCoins1200,
    productCoins3000,
    productRemoveAds,
    productPremium,
  ];

  /// 買い切り（非消費型）の商品。復元の対象になるのはこの2つだけ。
  static const nonConsumables = {productRemoveAds, productPremium};

  /// 商品IDごとの付与コイン。
  static const _coinsFor = {
    productCoins500: 500,
    productCoins1200: 1200,
    productCoins3000: 3000,
  };

  /// プレミアムのおまけコイン。
  static const premiumCoins = 2000;

  /// 起動時に一度だけ呼ぶ。
  /// - ストアに接続できるか確かめる
  /// - 商品情報を取得
  /// - 未完了の購入（前回アプリが落ちた等）をストリームで受け取る
  Future<void> init() async {
    if (kIsWeb || _initialized) return;
    _initialized = true;

    // 購入完了・保留のストリームを監視。
    // ⚠️ 先に listen しておくこと。起動直後に「前回未完了の購入」が流れてくる。
    _sub = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (Object err) => debugPrint('IAP purchase stream error: $err'),
    );

    try {
      if (!await _iap.isAvailable()) {
        debugPrint('IAP: store not available');
        return;
      }
      final response = await _iap.queryProductDetails(allProductIds.toSet());
      if (response.error != null) {
        debugPrint('IAP query error: ${response.error}');
      }
      if (response.notFoundIDs.isNotEmpty) {
        // Play Console に商品が無い／未有効化のとき。ここが空でないうちは
        // その商品だけ買えない（登録漏れに気づけるようログに出す）。
        debugPrint('IAP: not found: ${response.notFoundIDs}');
      }
      _products = response.productDetails;
      _storeReady = _products.isNotEmpty;
    } catch (e) {
      debugPrint('IAP init error: $e');
    }
    notifyListeners();
  }

  /// 商品情報を取得。未初期化なら空リスト。
  List<ProductDetails> get products => List.unmodifiable(_products);

  /// 商品IDから商品情報を引く。
  ProductDetails? product(String id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// 商品の表示価格（現地通貨の書式つき）。見つからなければ空文字。
  String priceFor(String id) => product(id)?.price ?? '';

  /// 購入を開始する。開始できたら true（＝購入completeではない。
  /// 実際の付与はストリームの [_deliverPurchase] で行う）。
  Future<bool> buy(String id) async {
    if (!available) return false;
    final p = product(id);
    if (p == null) {
      debugPrint('IAP: product $id not found');
      return false;
    }
    final param = PurchaseParam(productDetails: p);
    try {
      // 買い切りと消耗品でAPIが違う。買い切りを buyConsumable で買うと
      // 消費されて「持っていない」状態に戻ってしまう。
      if (nonConsumables.contains(id)) {
        return await _iap.buyNonConsumable(purchaseParam: param);
      }
      return await _iap.buyConsumable(purchaseParam: param);
    } catch (e) {
      debugPrint('IAP buy error: $e');
      return false;
    }
  }

  /// 購入をリストアする（機種変更・再インストール時の復元）。
  /// 非消費型（remove-ads, premium）だけが対象。
  Future<void> restore() async {
    if (kIsWeb || _restoring) return;
    _restoring = true;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('IAP restore error: $e');
    }
    _restoring = false;
  }

  void _onPurchaseUpdate(List<PurchaseDetails> details) {
    for (final p in details) {
      _deliverPurchase(p);
    }
  }

  /// 1件の購入を処理して報酬を付与する。
  Future<void> _deliverPurchase(PurchaseDetails p) async {
    switch (p.status) {
      case PurchaseStatus.pending:
        // 決済待ち（コンビニ払い等）。まだ何も渡さないし、完了もしない。
        return;
      case PurchaseStatus.error:
        debugPrint('IAP purchase error: ${p.error}');
        break;
      case PurchaseStatus.canceled:
        break;
      case PurchaseStatus.purchased:
        await _grant(p.productID, restored: false);
        Sfx.instance.fanfare();
      case PurchaseStatus.restored:
        // 復元で渡していいのは買い切りだけ。消耗品まで渡すと、
        // 復元のたびにコインが増える（無限に増やせてしまう）。
        if (nonConsumables.contains(p.productID)) {
          await _grant(p.productID, restored: true);
        }
    }

    // ⚠️ 承認（acknowledge）はここ。Androidは3日以内に承認しないと
    //    自動返金される＝お金を受け取れない。エラー・キャンセルでも
    //    未完了のまま残さないよう、pending 以外は必ず完了させる。
    if (p.pendingCompletePurchase) {
      try {
        await _iap.completePurchase(p);
      } catch (e) {
        debugPrint('IAP completePurchase error: $e');
      }
    }
  }

  /// 商品に対応する中身を渡す。
  Future<void> _grant(String id, {required bool restored}) async {
    final coins = _coinsFor[id];
    if (coins != null) {
      await PlayerProfile.instance.grantBonusCoins(coins);
    } else if (id == productRemoveAds) {
      await PlayerProfile.instance.setAdsRemoved(true);
    } else if (id == productPremium) {
      await _deliverPremium();
    } else {
      debugPrint('IAP: unknown product $id');
      return;
    }
    AppAnalytics.shopPurchase(
      category: 'iap',
      itemId: id,
      cost: coins ?? 0,
      method: restored ? 'iap_restore' : 'iap',
    );
  }

  /// プレミアム特典を全部付与する。
  ///
  /// 復元でもここを通るので、**何度呼ばれても増えないもの**（解放系）と
  /// コインを分けて扱う。コインは「まだ渡していないときだけ」渡す。
  Future<void> _deliverPremium() async {
    final profile = PlayerProfile.instance;
    await profile.setAdsRemoved(true);
    for (final c in kExtraCharacters) {
      if (!profile.unlockedCharacters.contains(c.id)) {
        await profile.unlockCharacter(c.id, 0);
      }
    }
    for (final a in kKnowledgeArticles) {
      if (!profile.hasArticle(a.id)) {
        await profile.unlockArticle(a.id, 0);
      }
    }
    if (!profile.premiumCoinsGranted) {
      await profile.setPremiumCoinsGranted(true);
      await profile.grantBonusCoins(premiumCoins);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
