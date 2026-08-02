import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_ids.dart';
import 'app_open_ad_helper.dart';
import 'app_analytics.dart';
import 'app_toast.dart';

/// 🎬 リワードインタースティシャル広告。
///
/// 全画面で出るが、**最後まで見ると報酬がもらえる**形式。
/// 普通の全画面広告と違い、出す前に「見ますか？」の確認を出すのが
/// 決まりなので、呼び出し側で必ず了解をとってから [show] を呼ぶこと。
///
/// リワード広告（自分から押して見るもの）との使い分け:
/// - リワード … ショップや結果画面で「コインが欲しい人」が押す
/// - これ …… 読み物を開くコインが足りないときなど、**流れの中で**すすめる
class RewardedInterstitialHelper {
  RewardedInterstitialHelper._();
  static final RewardedInterstitialHelper instance =
      RewardedInterstitialHelper._();

  RewardedInterstitialAd? _ad;
  bool _loading = false;

  static bool get available => AdIds.rewardedInterstitialAvailable;

  bool get isReady => _ad != null;

  void load() {
    if (!available || _loading || _ad != null) return;
    _loading = true;
    RewardedInterstitialAd.load(
      adUnitId: AdIds.rewardedInterstitial,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
        },
        onAdFailedToLoad: (err) {
          _loading = false;
          debugPrint('RewardedInterstitial failed: $err');
        },
      ),
    );
  }

  /// 見てもらう前の確認ダイアログ。
  ///
  /// リワードインタースティシャルは**出す前に了解をとる**のが決まり。
  /// 「広告は挟まるけれど、そのぶんコインがもらえる」と正直に言う。
  /// 隠して出すと、見た人の信用と枠の価値を同時に落とす。
  static Future<bool> confirm(BuildContext context,
      {required int coins}) async {
    final ja = Localizations.localeOf(context).languageCode == 'ja';
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(ja ? '🎬 動画を見てコインをもらう' : '🎬 Watch for coins'),
        content: Text(ja
            ? '広告が1本はさまりますが、最後まで見ると 🪙$coins もらえます。'
            : 'One ad will play. Watch it through and get 🪙$coins.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(ja ? 'やめておく' : 'No thanks')),
          ElevatedButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(ja ? '見る' : 'Watch')),
        ],
      ),
    );
    return ok == true;
  }

  /// 表示する。最後まで見られたら [onReward] を呼ぶ。
  /// 表示できなければ false（呼び出し側は何も起きなかった扱いにすること）。
  Future<bool> show({
    required String placement,
    required VoidCallback onReward,
  }) async {
    final ad = _ad;
    if (ad == null) {
      load();
      return false;
    }
    _ad = null;
    AppAnalytics.adRewardPrompt(placement);
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        AppOpenAdHelper.instance.suspended = false;
        a.dispose();
        load(); // 次に備えて読み込んでおく
        if (earned) AppToast.show('🎁 ありがとうございます！');
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        AppOpenAdHelper.instance.suspended = false;
        a.dispose();
        load();
      },
    );
    AppOpenAdHelper.instance.suspended = true;
    await ad.show(onUserEarnedReward: (_, __) {
      earned = true;
      AppAnalytics.adRewardEarned(placement);
      onReward();
    });
    return true;
  }
}
