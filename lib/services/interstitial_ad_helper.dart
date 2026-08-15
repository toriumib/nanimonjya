import 'dart:async';

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

  static const int playsPerAd = 2; // 何プレイごとに全画面広告を出すか
  static const String _prefsKey = 'playsSinceInterstitial';

  /// 🚦 前に出してから、最低これだけ間をあける（秒）。
  ///
  /// 「2プレイに1回」だけだと、短い試合を続けざまに終えたときに
  /// 全画面広告が立て続けに出る。全画面はいちばん嫌われやすい形なので、
  /// **回数**と**時間**の両方で止める（フリークエンシーキャップ）。
  /// 出しすぎて遊ぶのをやめられたら、その先の広告収入ごと失う。
  static const int minIntervalSeconds = 60;
  static const String _lastShownKey = 'interstitialLastShownMs';

  InterstitialAd? _ad;
  bool _loading = false;
  int _retryCount = 0;
  DateTime? _loadedAt;

  /// ⏳ 読み込み済み広告の寿命。
  ///
  /// ⚠️ **これが無くて取りこぼしていた。** AdMobの広告は約1時間で期限切れになる。
  ///    `load()` は `_ad != null` なら何もしないので、**古い広告が居座り**、
  ///    試合を終えるたびに `show()` が失敗していた。しかも下の
  ///    「表示するのでカウンタをリセット」を**出す前に**やっていたので、
  ///    失敗した回のプレイまで消費されていた。
  ///    2026-08のAdMob: 表示7回／リクエスト56。完了した試合は90前後あったので、
  ///    2プレイに1回なら本来45回前後は出ていたはず。
  static const Duration _ttl = Duration(minutes: 50);

  static bool get available => AdIds.interstitialAvailable;
  bool get _expired =>
      _loadedAt == null || DateTime.now().difference(_loadedAt!) > _ttl;
  bool get isReady => _ad != null && !_expired;

  void load() {
    if (!available || _loading) return;
    if (_ad != null && !_expired) return; // 生きた在庫がある
    if (_ad != null) {
      // 期限切れは出しても失敗するだけなので捨ててから読み直す
      AppAnalytics.adSkipped(
          format: 'interstitial', placement: 'result', reason: 'expired');
      _ad!.dispose();
      _ad = null;
      _loadedAt = null;
    }
    _loading = true;
    AppAnalytics.adLoadRequested(
        format: 'interstitial', placement: 'result');
    // ⚠️ 読み込みの呼び出し自体が失敗することがある（広告SDKが使えない環境）。
    //    受け取らずに投げっぱなしにすると、拾い手のいない非同期エラーになる。
    unawaited(InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loadedAt = DateTime.now();
          _loading = false;
          _retryCount = 0;
          debugPrint('InterstitialAd loaded.');
        },
        onAdFailedToLoad: (err) {
          _ad = null;
          _loadedAt = null;
          _loading = false;
          AppAnalytics.adSkipped(
              format: 'interstitial', placement: 'result', reason: 'no_fill');
          debugPrint('InterstitialAd failed to load: $err');
          // 自動リトライ: 2,4,8,16,32秒（最大5回）
          if (_retryCount < 5) {
            _retryCount++;
            Future.delayed(Duration(seconds: 1 << _retryCount), load);
          }
        },
      ),
    ).catchError((Object e) {
      _loading = false;
      debugPrint('InterstitialAd load call failed: $e');
    }));
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

    if (plays >= playsPerAd && isReady && !tooSoon) {
      final ad = _ad!;
      _ad = null;
      _loadedAt = null;
      ad.fullScreenContentCallback = FullScreenContentCallback(
        // ✅ **本当に画面に出たときだけ**カウンタと時刻を進める。
        //    出す前にリセットしていたので、表示に失敗した回のプレイまで
        //    消費され、次にまた2プレイぶん待たされていた。
        onAdShowedFullScreenContent: (ad) async {
          final p = await SharedPreferences.getInstance();
          await p.setInt(_prefsKey, 0);
          await p.setInt(_lastShownKey, DateTime.now().millisecondsSinceEpoch);
          AppAnalytics.adShown(format: 'interstitial', placement: 'result');
        },
        onAdDismissedFullScreenContent: (ad) {
          AppOpenAdHelper.instance.suspended = false;
          ad.dispose();
          load(); // 次回に備えて先読み
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          AppOpenAdHelper.instance.suspended = false;
          ad.dispose();
          AppAnalytics.adSkipped(
              format: 'interstitial', placement: 'result', reason: 'error');
          load();
        },
      );
      AppOpenAdHelper.instance.suspended = true;
      await ad.show();
      // カウンタは onAdShowedFullScreenContent 側で0に戻す。
      // ここでは「持ち越し」の値を書き戻さないよう、この回は保存しない。
      return;
    } else {
      // あと1プレイで出る、またはもう出るはずの段階でまだ読めていない
      load();
      if (plays >= playsPerAd) {
        // 広告の準備ができていない・クールダウン中 → カウンタを進めず次回に持ち越す。
        // ここで plays を保存すると、次回起動時にも _ad が null なのに
        // plays だけが増え続けてしまう（SharedPreferencesは永続だが _ad はメモリ）
        AppAnalytics.adSkipped(
            format: 'interstitial',
            placement: 'result',
            reason: tooSoon
                ? 'cooldown'
                : (_ad != null ? 'expired' : 'not_loaded'));
        plays = playsPerAd; // 進めずにここで止める
      }
    }
    await prefs.setInt(_prefsKey, plays);
  }
}
