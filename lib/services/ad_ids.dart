import 'package:flutter/foundation.dart';

/// 広告ユニットIDの一元管理。
/// デバッグ時は Google のテストIDを使用し、リリース時は本番IDを使用する。
/// ※ dart:io の Platform は Web で UnsupportedError になるため使わず、
///    Web安全な defaultTargetPlatform / kIsWeb を使用する。
class AdIds {
  // --- バナー ---
  static const String _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIOS = 'ca-app-pub-3940256099942544/2934735716';
  static const String _realBannerAndroid = 'ca-app-pub-6744940157577324/4880687935'; // AdMobコンソール確認

  // --- リワード ---
  static const String _testRewardedAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testRewardedIOS = 'ca-app-pub-3940256099942544/1712485313';
  static const String _realRewardedAndroid = 'ca-app-pub-6744940157577324/9009716197'; // AdMobで作成

  // --- インタースティシャル（3プレイごとの全画面広告） ---
  static const String _testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIOS = 'ca-app-pub-3940256099942544/4411468910';
  // ★AdMobコンソールで「インタースティシャル」ユニットを作成したらここに貼る★
  static const String _realInterstitialAndroid = '';

  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  static String get banner {
    if (kDebugMode) {
      return _isIOS ? _testBannerIOS : _testBannerAndroid;
    }
    return _realBannerAndroid; // 現状Androidのみ本番配信
  }

  static String get rewarded {
    if (kDebugMode) {
      return _isIOS ? _testRewardedIOS : _testRewardedAndroid;
    }
    return _realRewardedAndroid;
  }

  /// リリースでリワード広告を出せる状態か（本番IDが設定済みか）。
  /// Webでは google_mobile_ads 非対応のため常に false。
  /// デバッグ中(モバイル)は常に true（テスト広告で動作確認できる）。
  static bool get rewardedAvailable =>
      !kIsWeb && (kDebugMode || _realRewardedAndroid.isNotEmpty);

  static String get interstitial {
    if (kDebugMode) {
      return _isIOS ? _testInterstitialIOS : _testInterstitialAndroid;
    }
    return _realInterstitialAndroid;
  }

  /// インタースティシャル広告を出せる状態か。
  /// 本番IDが未設定の間はリリースでは無効（テストIDを本番で使うのは規約違反のため）。
  static bool get interstitialAvailable =>
      !kIsWeb && (kDebugMode || _realInterstitialAndroid.isNotEmpty);
}
