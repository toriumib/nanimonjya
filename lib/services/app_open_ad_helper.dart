import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_ids.dart';
import 'app_analytics.dart';
import 'player_profile.dart';

/// 🚪 アプリ起動広告（App Open）。
///
/// **アプリを開き直すたびに1インプレッション取れる**ので、遊ぶ回数が
/// 増えなくても効く数少ない枠。AdMobで枠は作ってあったのに、実装が
/// 無くて丸ごと使われていなかった。
///
/// ただし出し方を誤ると、いちばん嫌われる枠でもある。次を必ず守る:
/// - **初回の起動では出さない**。何のアプリか分からないうちに全画面が
///   出ると、そのまま消される
/// - **他の全画面広告から戻ってきたときは出さない**。動画を見終えた直後に
///   さらに全画面が出るのは二重表示で、規約上も避けるべき挙動
/// - **前に出してから間をあける**（[minIntervalSeconds]）
/// - 読み込んだ広告は**4時間で捨てる**（古い広告は配信品質が落ちるため、
///   Googleも期限を設けるよう案内している）
class AppOpenAdHelper with WidgetsBindingObserver {
  AppOpenAdHelper._();
  static final AppOpenAdHelper instance = AppOpenAdHelper._();

  static const int minIntervalSeconds = 120;
  static const Duration _maxCacheAge = Duration(hours: 4);

  AppOpenAd? _ad;
  DateTime? _loadedAt;
  DateTime? _lastShownAt;
  bool _loading = false;
  bool _showing = false;

  /// 起動直後の1回目かどうか。初回は出さない。
  bool _firstResumeSkipped = false;

  /// 🎬 ほかの全画面広告（リワード・インタースティシャル）が出ている間は
  /// true にしてもらう。戻ってきた瞬間に起動広告が重なるのを防ぐ。
  bool suspended = false;

  static bool get available => AdIds.appOpenAvailable;

  void start() {
    if (!available) return;
    WidgetsBinding.instance.addObserver(this);
    load();
  }

  void load() {
    if (!available || _loading || _ad != null) return;
    _loading = true;
    // 📊 AdMobのレポートだけでは「読んだのに出せなかった」理由が分からない
    //    （アプリ起動は 51リクエスト中マッチ52.9%、表示は10回だった）。
    //    ロード・表示・空振りをそれぞれ残して、次回は理由まで追えるようにする。
    AppAnalytics.adLoadRequested(format: 'app_open', placement: 'cold_start');
    AppOpenAd.load(
      adUnitId: AdIds.appOpen,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loadedAt = DateTime.now();
          _loading = false;
        },
        onAdFailedToLoad: (err) {
          _loading = false;
          AppAnalytics.adSkipped(
              format: 'app_open', placement: 'cold_start', reason: 'no_fill');
          debugPrint('AppOpenAd failed: $err');
        },
      ),
    );
  }

  bool get _fresh =>
      _ad != null &&
      _loadedAt != null &&
      DateTime.now().difference(_loadedAt!) < _maxCacheAge;

  bool get _tooSoon =>
      _lastShownAt != null &&
      DateTime.now().difference(_lastShownAt!).inSeconds < minIntervalSeconds;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!_firstResumeSkipped) {
      // 起動そのもので出すと、まだ何のアプリか分からないうちに
      // 全画面が出ることになる。1回目は見送る。
      _firstResumeSkipped = true;
      return;
    }
    _showIfReady();
  }

  void _showIfReady() {
    if (!available || _showing || suspended) return;
    if (PlayerProfile.instance.adsRemovedOrPremium) return;
    if (_tooSoon) {
      AppAnalytics.adSkipped(
          format: 'app_open', placement: 'cold_start', reason: 'cooldown');
      return;
    }
    if (!_fresh) {
      AppAnalytics.adSkipped(
          format: 'app_open',
          placement: 'cold_start',
          reason: _ad == null ? 'not_loaded' : 'expired');
      _ad?.dispose();
      _ad = null;
      load();
      return;
    }
    final ad = _ad!;
    _ad = null;
    _showing = true;
    _lastShownAt = DateTime.now();
    AppAnalytics.adShown(format: 'app_open', placement: 'cold_start');
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _showing = false;
        load();
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        a.dispose();
        _showing = false;
        load();
      },
    );
    ad.show();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ad?.dispose();
    _ad = null;
  }
}
