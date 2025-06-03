import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart'; // for kDebugMode
import 'package:flutter/material.dart'; // for Widget, Container, etc.

class AdMob {
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  // TODO: Replace with your actual Ad Unit IDs from AdMob
  // Use Test IDs during development & testing!
  final String _bannerAdUnitId = kDebugMode // デバッグモードかチェック
      ? (defaultTargetPlatform == TargetPlatform.android
              ? 'ca-app-pub-3940256099942544/6300978111' // Android Test ID
              : 'ca-app-pub-3940256099942544/2934735716' // iOS Test ID
          )
      : (defaultTargetPlatform == TargetPlatform.android
          ? 'YOUR_ANDROID_BANNER_AD_UNIT_ID' // Replace with your real Android ID
          : 'YOUR_IOS_BANNER_AD_UNIT_ID' // Replace with your real iOS ID
      );

  // バナー広告を読み込むメソッド
  void loadBanner() {
    // 既に読み込み済み、または読み込み中の場合は処理しない
    if (_bannerAd != null && _isBannerLoaded) {
      debugPrint('BannerAd already loaded.');
      return;
    }
    if (_bannerAd != null && !_isBannerLoaded) {
      debugPrint('BannerAd is already loading.');
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      request: const AdRequest(),
      // 固定サイズのバナーを使用 (Adaptive Bannerは少し複雑になるため)
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint('$BannerAd loaded.');
          _isBannerLoaded = true;
          // 必要に応じて、UI更新のためのコールバックをここで呼び出す
          // (例: StateNotifier, Provider などで状態を通知)
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('$BannerAd failedToLoad: $error');
          ad.dispose(); // 失敗したらリソース解放
          _bannerAd = null; // 参照をnullに
          _isBannerLoaded = false;
        },
        // 他のリスナーイベント (任意)
        // onAdOpened: (Ad ad) => debugPrint('$BannerAd onAdOpened.'),
        // onAdClosed: (Ad ad) => debugPrint('$BannerAd onAdClosed.'),
        // onAdImpression: (Ad ad) => debugPrint('$BannerAd onAdImpression.'),
      ),
    )..load(); // 作成したらすぐに読み込み開始
  }

  // バナー広告を破棄するメソッド
  void disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerLoaded = false;
  }

  // 表示するバナー広告ウィジェットを取得するメソッド
  Widget getAdBannerWidget() {
    final banner = _bannerAd; // ローカル変数に入れてnullチェックしやすくする
    if (_isBannerLoaded && banner != null) {
      // 広告が読み込み完了していれば AdWidget を返す
      return SizedBox(
        width: banner.size.width.toDouble(),
        height: banner.size.height.toDouble(),
        child: AdWidget(ad: banner),
      );
    } else {
      // 広告が読み込み中、または失敗した場合は、高さを確保した空のコンテナを返す
      return Container(
        width: AdSize.banner.width.toDouble(),
        height: AdSize.banner.height.toDouble(),
        // color: Colors.grey[200], // 必要なら背景色をつける
        alignment: Alignment.center,
        // child: Text('広告読み込み中...', style: TextStyle(fontSize: 12)),
      );
    }
  }

  // バナー広告の高さを取得するメソッド (固定サイズバナー用)
  double getAdBannerHeight() {
    // AdSize.banner の高さを返す (ロード前でも高さを確定できる)
    return AdSize.banner.height.toDouble();
  }
}
