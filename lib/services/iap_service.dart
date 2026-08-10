import 'package:flutter/foundation.dart';

/// Google Play / App Store 課金サービス。
///
/// 📦 現在は in_app_purchase パッケージを取り下げているため、
/// 全APIがスタブになっている（課金できず、available は常に false）。
///
/// Play が Billing Library 8.0.0+ を必須化したが、
/// それに必要な in_app_purchase_android 0.4.0+11 は Dart 3.10+ 依存。
/// 本プロジェクトの Flutter 3.32 / Dart 3.8 では解決できない。
/// Flutter 3.35+ に上げたあとで復活させる。
///
/// 購入済みユーザーの adsRemoved は端末側の SharedPreferences に残っており、
/// 広告は出ないままになる。
class IapService {
  IapService._();
  static final IapService instance = IapService._();

  /// 課金は現在利用不可。
  bool get available => false;

  /// 商品IDの定数（Google Play Console に登録するIDと一致させる）
  static const productCoins500 = 'coins-500';
  static const productCoins1200 = 'coins-1200';
  static const productCoins3000 = 'coins-3000';
  static const productRemoveAds = 'remove-ads';
  static const productPremium = 'premium';

  static const allProductIds = [
    productCoins500,
    productCoins1200,
    productCoins3000,
    productRemoveAds,
    productPremium,
  ];

  Future<void> init() async {}
  String priceFor(String id) => '';
  Future<bool> buy(String id) async => false;
  Future<void> restore() async {}
  void dispose() {}
}
