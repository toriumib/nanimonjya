import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_ids.dart';
import 'app_analytics.dart';

/// リワード広告のロード＆表示ヘルパー。
/// ★ChangeNotifier化: 読み込み状態の変化をUIに通知し、
///   「じゅんび中…→準備OK」をボタンが自動で反映できる★
/// ★読み込み失敗時は指数バックオフで自動リトライ（電波不安定でも復帰）★
class RewardAdHelper extends ChangeNotifier {
  RewardedAd? _ad;
  bool _loading = false;
  int _retryCount = 0;
  bool _disposed = false;

  // ★予約再生: 未準備のままタップされた場合、読み込み完了と同時に自動再生する★
  VoidCallback? _queuedReward;
  DateTime? _queuedAt;

  bool get isReady => _ad != null;
  bool get isLoading => _loading;
  bool get hasQueuedShow => _queuedReward != null;

  /// リワード広告が利用可能な構成か（本番IDが未設定のリリースでは false）。
  static bool get available => AdIds.rewardedAvailable;

  void load() {
    if (!available || _loading || _ad != null || _disposed) return;
    _loading = true;
    _safeNotify();
    RewardedAd.load(
      adUnitId: AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (_disposed) {
            ad.dispose();
            return;
          }
          _ad = ad;
          _loading = false;
          _retryCount = 0;
          debugPrint('RewardedAd loaded.');
          _safeNotify();
          // ★予約があれば即再生（30秒以内のタップのみ有効。古い予約は破棄）★
          final queued = _queuedReward;
          final queuedAt = _queuedAt;
          _queuedReward = null;
          _queuedAt = null;
          if (queued != null &&
              queuedAt != null &&
              DateTime.now().difference(queuedAt).inSeconds <= 30) {
            show(onReward: queued);
          }
        },
        onAdFailedToLoad: (err) {
          _ad = null;
          _loading = false;
          debugPrint('RewardedAd failed to load: $err');
          _safeNotify();
          // ★自動リトライ: 2,4,8,16,32秒後（最大5回）★
          if (!_disposed && _retryCount < 5) {
            _retryCount++;
            final delay = Duration(seconds: 1 << _retryCount);
            Future.delayed(delay, () {
              if (!_disposed) load();
            });
          }
        },
      ),
    );
  }

  /// 広告を表示し、報酬獲得時に [onReward] を呼ぶ。
  /// 表示できなかった場合は false を返す（呼び出し側でリトライ案内）。
  Future<bool> show({required VoidCallback onReward}) async {
    final ad = _ad;
    if (ad == null) {
      _retryCount = 0; // 手動タップ時はリトライ回数をリセットして再読込
      load();
      return false;
    }
    bool rewarded = false;
    AppAnalytics.adRewardPrompt('rewarded'); // 表示成功数（視聴率の分母）
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _ad = null;
        _safeNotify();
        load(); // 次回に備えて先読み
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _ad = null;
        _safeNotify();
        load();
      },
    );
    await ad.show(
      onUserEarnedReward: (ad, reward) {
        rewarded = true;
        AppAnalytics.adRewardEarned('rewarded'); // 最後まで視聴した数（分子）
        onReward();
      },
    );
    return rewarded;
  }

  /// ★準備済みなら即再生、未準備なら「予約」して読み込み完了と同時に自動再生★
  /// 戻り値: true=即再生できた（報酬有無はonRewardで反映）, false=予約した
  Future<bool> showOrQueue({required VoidCallback onReward}) async {
    if (_ad != null) {
      await show(onReward: onReward);
      return true;
    }
    _queuedReward = onReward;
    _queuedAt = DateTime.now();
    _retryCount = 0; // 手動タップなのでリトライ回数をリセット
    load();
    _safeNotify();
    return false;
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _ad?.dispose();
    _ad = null;
    super.dispose();
  }
}
