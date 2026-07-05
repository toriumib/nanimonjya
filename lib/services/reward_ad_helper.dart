import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_ids.dart';

/// リワード広告のロード＆表示ヘルパー。
class RewardAdHelper {
  RewardedAd? _ad;
  bool _loading = false;

  bool get isReady => _ad != null;

  /// リワード広告が利用可能な構成か（本番IDが未設定のリリースでは false）。
  static bool get available => AdIds.rewardedAvailable;

  void load() {
    if (!available || _loading || _ad != null) return;
    _loading = true;
    RewardedAd.load(
      adUnitId: AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
          debugPrint('RewardedAd loaded.');
        },
        onAdFailedToLoad: (err) {
          _ad = null;
          _loading = false;
          debugPrint('RewardedAd failed to load: $err');
        },
      ),
    );
  }

  /// 広告を表示し、報酬獲得時に [onReward] を呼ぶ。
  /// 表示できなかった場合は false を返す。
  Future<bool> show({required VoidCallback onReward}) async {
    final ad = _ad;
    if (ad == null) {
      load();
      return false;
    }
    bool rewarded = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _ad = null;
        load(); // 次回に備えて先読み
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _ad = null;
        load();
      },
    );
    await ad.show(
      onUserEarnedReward: (ad, reward) {
        rewarded = true;
        onReward();
      },
    );
    return rewarded;
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
  }
}
