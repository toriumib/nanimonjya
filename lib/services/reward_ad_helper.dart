import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:ui' show PlatformDispatcher;

import 'ad_ids.dart';
import 'app_open_ad_helper.dart';
import 'app_toast.dart';
import 'app_analytics.dart';

/// リワード広告のロード＆表示ヘルパー。
///
/// ■ 2026-08 に作り直した理由（**元に戻さないこと**）
///
/// AdMob のレポートで、リワードが **446ロード / 14表示（3.1%）** だった。
/// 収益の96%はリワードなのに、その97%を捨てていた。
///
/// 原因は、**画面ごとに別インスタンスを作って initState でロードし、
/// 画面を閉じるとロード済みの広告を dispose で捨てていた**こと。
/// ホーム・ショップ・結果画面・読み物・マイページの5か所が
/// それぞれ勝手にロードするので、通るたびに1リクエスト増え、
/// ボタンを押さずに画面を離れるたびに1つ無駄になっていた。
///
/// 空振りは収益ゼロなだけでなく、**マッチ率と単価にも効いてくる**。
///
/// ■ いまの作り
///
/// **広告の実体は static にひとつだけ持つ**（[_ad]）。
/// 各画面が作る [RewardAdHelper] は、その共有在庫を見にいくだけの窓口で、
/// 自分の [placement] を記録するために存在する。
/// - 在庫があれば、どの画面から呼んでもそれを出す
/// - 画面を閉じても在庫は**捨てない**
/// - 出したあとにだけ次を読む
///
/// ⚠️ AdMob のロード済み広告は**約1時間で期限切れ**になる。
///    古いまま出そうとしても失敗するので、[_ttl] を過ぎたら捨てて読み直す。
class RewardAdHelper extends ChangeNotifier {
  /// この広告がどこから再生されたか（分析用）。
  /// shop / shop_short_of_coins / home_gift / result_double / profile など。
  final String placement;

  RewardAdHelper({this.placement = 'unknown'}) {
    _listeners.add(this);
  }

  // ── ここから下は全インスタンスで共有 ──

  /// 共有の在庫。**インスタンスごとに持たない。**
  static RewardedAd? _ad;
  static bool _loading = false;
  static DateTime? _loadedAt;
  static int _retryCount = 0;

  /// ロード済み広告の寿命。AdMob の仕様に合わせて1時間より短くとる。
  static const Duration _ttl = Duration(minutes: 50);

  /// 生きている窓口。状態が変わったら全部に知らせる。
  static final Set<RewardAdHelper> _listeners = {};

  /// 予約再生。未準備のままタップされたら、届き次第そのまま流す。
  static VoidCallback? _queuedReward;
  static DateTime? _queuedAt;
  static String _queuedPlacement = 'unknown';

  static bool get _expired =>
      _loadedAt != null && DateTime.now().difference(_loadedAt!) > _ttl;

  bool get isReady => _ad != null && !_expired;
  bool get isLoading => _loading;
  bool get hasQueuedShow => _queuedReward != null;

  /// リワード広告が利用可能な構成か（本番IDが未設定のリリースでは false）。
  static bool get available => AdIds.rewardedAvailable;

  static void _notifyAll() {
    for (final l in [..._listeners]) {
      l.notifyListeners();
    }
  }

  /// 在庫が無ければ1つだけ読む。
  ///
  /// ⚠️ 画面の initState から**毎回**呼んでよい。在庫があれば何もしない。
  ///    ここで多重ロードを止めているので、呼び出し側は気にしなくてよい。
  void load() => _ensure(placement);

  static void _ensure(String placement) {
    if (!available || _loading) return;
    if (_ad != null && !_expired) return; // 在庫あり。読まない
    if (_ad != null && _expired) {
      // 期限切れは出しても失敗するだけなので捨てる
      AppAnalytics.adSkipped(
          format: 'rewarded', placement: placement, reason: 'expired');
      _ad!.dispose();
      _ad = null;
      _loadedAt = null;
    }
    _loading = true;
    AppAnalytics.adLoadRequested(format: 'rewarded', placement: placement);
    _notifyAll();
    RewardedAd.load(
      adUnitId: AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loadedAt = DateTime.now();
          _loading = false;
          _retryCount = 0;
          _notifyAll();
          // 予約があれば即再生（30秒以内のタップのみ。古い予約は捨てる）
          final queued = _queuedReward;
          final queuedAt = _queuedAt;
          _queuedReward = null;
          _queuedAt = null;
          if (queued != null &&
              queuedAt != null &&
              DateTime.now().difference(queuedAt).inSeconds <= 30) {
            _show(placement: _queuedPlacement, onReward: queued);
          }
        },
        onAdFailedToLoad: (err) {
          _ad = null;
          _loadedAt = null;
          _loading = false;
          AppAnalytics.adSkipped(
              format: 'rewarded', placement: placement, reason: 'no_fill');
          debugPrint('RewardedAd failed to load: $err');
          _notifyAll();
          // 自動リトライ: 2,4,8,16,32秒後（最大5回）
          // ⚠️ 回数を増やさないこと。在庫が無いときに叩き続けると
          //    マッチ率が下がって、次に本当に必要なときに出なくなる。
          if (_retryCount < 5) {
            _retryCount++;
            Future.delayed(Duration(seconds: 1 << _retryCount), () {
              if (_listeners.isNotEmpty) _ensure(placement);
            });
          }
        },
      ),
    );
  }

  /// 広告を表示し、報酬獲得時に [onReward] を呼ぶ。
  /// 表示できなかった場合は false を返す（呼び出し側でリトライ案内）。
  Future<bool> show({required VoidCallback onReward}) =>
      _show(placement: placement, onReward: onReward);

  static Future<bool> _show({
    required String placement,
    required VoidCallback onReward,
  }) async {
    final ad = _ad;
    if (ad == null || _expired) {
      AppAnalytics.adSkipped(
          format: 'rewarded',
          placement: placement,
          reason: ad == null ? 'not_loaded' : 'expired');
      _retryCount = 0; // 手動タップ時はリトライ回数をリセットして再読込
      _ensure(placement);
      return false;
    }
    bool rewarded = false;
    _ad = null; // 出す時点で在庫から外す（二重再生を防ぐ）
    _loadedAt = null;
    AppAnalytics.adShown(format: 'rewarded', placement: placement);
    AppAnalytics.adRewardPrompt(placement); // 表示成功数（視聴率の分母）
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        AppOpenAdHelper.instance.suspended = false;
        ad.dispose();
        _notifyAll();
        _ensure(placement); // 見終わったので次を読む
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        AppAnalytics.adSkipped(
            format: 'rewarded', placement: placement, reason: 'error');
        _notifyAll();
        _ensure(placement);
      },
    );
    AppOpenAdHelper.instance.suspended = true;
    await ad.show(
      onUserEarnedReward: (ad, reward) {
        rewarded = true;
        AppAnalytics.adRewardEarned(placement); // 最後まで視聴した数（分子）
        onReward();
        // 🙏 最後まで見てくれた人に、ひとことだけお礼を出す。
        AppToast.thanksForAd(
            PlatformDispatcher.instance.locale.languageCode == 'ja');
      },
    );
    return rewarded;
  }

  /// 準備済みなら即再生、未準備なら「予約」して読み込み完了と同時に自動再生。
  /// 戻り値: true=即再生できた（報酬有無はonRewardで反映）, false=予約した
  Future<bool> showOrQueue({required VoidCallback onReward}) async {
    if (isReady) {
      await show(onReward: onReward);
      return true;
    }
    _queuedReward = onReward;
    _queuedAt = DateTime.now();
    _queuedPlacement = placement;
    _retryCount = 0; // 手動タップなのでリトライ回数をリセット
    _ensure(placement);
    _notifyAll();
    return false;
  }

  /// ⚠️ **共有の在庫は捨てない。**
  ///    画面を閉じるたびに捨てていたのが、そもそもの不具合だった。
  @override
  void dispose() {
    _listeners.remove(this);
    super.dispose();
  }
}
