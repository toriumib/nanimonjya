import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ad_ids.dart';
import 'app_analytics.dart';
import 'app_open_ad_helper.dart';
import 'player_profile.dart';

/// インタースティシャル（全画面）広告のヘルパー。
/// 「3プレイごとに1回」のペースでリザルト画面表示時に出す。
/// シングルトンで先読みし、失敗時は指数バックオフで自動リトライ。
class InterstitialAdHelper {
  InterstitialAdHelper._();
  static final InterstitialAdHelper instance = InterstitialAdHelper._();

  static const int playsPerAd = 3; // 何プレイごとに全画面広告を出すか
  static const String _prefsKey = 'playsSinceInterstitial';

  /// 🚦 前に出してから、最低これだけ間をあける（秒）。
  ///
  /// 「3プレイに1回」だけだと、短い試合を続けざまに終えたときに
  /// 全画面広告が立て続けに出る。全画面はいちばん嫌われやすい形なので、
  /// **回数**と**時間**の両方で止める（フリークエンシーキャップ）。
  /// 出しすぎて遊ぶのをやめられたら、その先の広告収入ごと失う。
  static const int minIntervalSeconds = 90;
  static const String _lastShownKey = 'interstitialLastShownMs';

  InterstitialAd? _ad;
  bool _loading = false;
  int _retryCount = 0;

  static bool get available => AdIds.interstitialAvailable;
  bool get isReady => _ad != null;

  void load() {
    if (!available || _loading || _ad != null) return;
    _loading = true;
    AppAnalytics.adLoadRequested(
        format: 'interstitial', placement: 'result');
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
    // 💳 広告除去を買ってくれた人には全画面広告を出さない
    if (PlayerProfile.instance.adsRemoved) return;
    final prefs = await SharedPreferences.getInstance();
    int plays = (prefs.getInt(_prefsKey) ?? 0) + 1;
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = prefs.getInt(_lastShownKey) ?? 0;
    final tooSoon = now - last < minIntervalSeconds * 1000;

    if (plays >= playsPerAd && _ad != null && !tooSoon) {
      plays = 0; // 表示するのでカウンタをリセット
      final ad = _ad!;
      _ad = null;
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          AppOpenAdHelper.instance.suspended = false;
          ad.dispose();
          load(); // 次回に備えて先読み
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          AppOpenAdHelper.instance.suspended = false;
          ad.dispose();
          load();
        },
      );
      await prefs.setInt(_lastShownKey, now);
      AppOpenAdHelper.instance.suspended = true;
      AppAnalytics.adShown(format: 'interstitial', placement: 'result');
      await ad.show();
    } else {
      // ⚠️ **あと1プレイで出る**ところまで来てから読む。
      //    起動時に読んでいたころは 56ロード/7表示だった。
      //    ゲームを終えずに離脱した人のぶんが全部空振りになっていた。
      if (plays >= playsPerAd - 1) {
        load();
      }
      if (plays >= playsPerAd) {
        AppAnalytics.adSkipped(
            format: 'interstitial',
            placement: 'result',
            reason: tooSoon ? 'cooldown' : 'not_loaded');
      }
    }
    await prefs.setInt(_prefsKey, plays);
  }
}
