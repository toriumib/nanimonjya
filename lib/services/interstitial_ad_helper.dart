import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ad_ids.dart';

/// インタースティシャル（全画面）広告のヘルパー。
/// 「3プレイごとに1回」のペースでリザルト画面表示時に出す。
/// シングルトンで先読みし、失敗時は指数バックオフで自動リトライ。
class InterstitialAdHelper {
  InterstitialAdHelper._();
  static final InterstitialAdHelper instance = InterstitialAdHelper._();

  static const int playsPerAd = 3; // 何プレイごとに全画面広告を出すか
  static const String _prefsKey = 'playsSinceInterstitial';

  InterstitialAd? _ad;
  bool _loading = false;
  int _retryCount = 0;

  static bool get available => AdIds.interstitialAvailable;
  bool get isReady => _ad != null;

  void load() {
    if (!available || _loading || _ad != null) return;
    _loading = true;
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
          _retryCount = 0;
          debugPrint('InterstitialAd loaded.');
        },
        onAdFailedToLoad: (err) {
          _ad = null;
          _loading = false;
          debugPrint('InterstitialAd failed to load: $err');
          // 自動リトライ: 2,4,8,16,32秒（最大5回）
          if (_retryCount < 5) {
            _retryCount++;
            Future.delayed(Duration(seconds: 1 << _retryCount), load);
          }
        },
      ),
    );
  }

  /// ゲーム1プレイ完了を記録し、規定回数に達していて広告準備済みなら表示する。
  /// リザルト画面の表示時に呼ぶ想定。
  Future<void> onGameFinished() async {
    if (!available) return;
    final prefs = await SharedPreferences.getInstance();
    int plays = (prefs.getInt(_prefsKey) ?? 0) + 1;

    if (plays >= playsPerAd && _ad != null) {
      plays = 0; // 表示するのでカウンタをリセット
      final ad = _ad!;
      _ad = null;
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          load(); // 次回に備えて先読み
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          load();
        },
      );
      await ad.show();
    } else {
      // まだ回数前 or 広告未準備（未準備なら読み込んでおき、次の機会に出す）
      if (plays >= playsPerAd) load();
    }
    await prefs.setInt(_prefsKey, plays);
  }
}
