/// 🎬 コインが足りないときに「動画を見て増やす？」と誘う共通ダイアログ。
///
/// 「欲しいのに足りない」瞬間が、リワード広告をいちばん見てもらえる場所。
/// ここで行き止まりのスナックバーを出すのはもったいないので、必ずこれを通す。
///
/// もともと character_shop_screen の中にプライベートメソッドとして
/// 書かれていて、ショップの中でしか働いていなかった。読み物・デッキ・
/// マイページでも同じ「足りない」が起きるので、共通化してある。
library;

import 'package:flutter/material.dart';

import '../l10n/meta_strings.dart';
import '../services/app_analytics.dart';
import '../services/player_profile.dart';
import '../services/reward_ad_helper.dart';
import '../services/sfx.dart';

/// 1本見てもらったときに渡すコイン。ショップの「動画でコイン」と同額にそろえる。
const int kCoinAdReward = 60;

/// コイン不足を伝え、その場でリワード広告に誘導する。
///
/// [cost] は買おうとしたものの値段、[category]/[itemId] は分析用の識別子。
/// [ad] は呼び出し側が持っている [RewardAdHelper]（画面ごとに1つ持つ作りなので
/// ここでは作らない。placement が画面ごとに分かれていないと視聴率が測れない）。
///
/// 広告を見てコインが入ったら true を返す。呼び出し側はそのまま購入を
/// 再試行してよい（コインが足りていない場合もあるので結果は再確認すること）。
Future<bool> offerAdForCoins(
  BuildContext context, {
  required RewardAdHelper ad,
  required int cost,
  required String category,
  required String itemId,
}) async {
  final m = MetaStrings.of(context);
  final p = PlayerProfile.instance;
  final short = cost - p.coins;

  // 「何が欲しくて足りなかったか」「その結果 動画を見たか」を残す。
  // よくタップされるのに買われない＝値段が高すぎる商品を見つけるため。
  AppAnalytics.shopBlockedByCoins(
      category: category, itemId: itemId, shortBy: short);
  AppAnalytics.adOfferedForItem(
    category: category,
    itemId: itemId,
    cost: cost,
    coinsHeld: p.coins,
  );
  Sfx.instance.wrong();

  final go = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(m.notEnoughCoins),
      content: Text(m.shortByCoins(short, kCoinAdReward)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(m.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(m.storeWatchAd(kCoinAdReward)),
        ),
      ],
    ),
  );
  if (go != true || !context.mounted) return false;

  var granted = false;
  // showOrQueue: まだ読み込めていなくても、タップの意思を覚えておいて
  // 読み終わり次第すぐ再生する（読込中に押して何も起きない、を避ける）
  //
  // ⚠️ onReward は ad.show() の中から**同期的に**呼ばれる。
  //    await をはさんでから granted を立てると showOrQueue が返るほうが
  //    先になり、見てもらったのに false を返してしまう。
  final playedNow = await ad.showOrQueue(onReward: () {
    granted = true;
    p.grantBonusCoins(kCoinAdReward); // 保存の完了は待たない（既存の導線と同じ）
  });
  if (!context.mounted) return granted;

  final messenger = ScaffoldMessenger.of(context);
  if (!playedNow) {
    messenger.showSnackBar(SnackBar(content: Text(m.storeAdLoading)));
  } else if (granted) {
    messenger.showSnackBar(SnackBar(content: Text(m.earnedCoins(kCoinAdReward))));
  }
  return granted;
}
