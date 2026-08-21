import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nanimonjya/models/character_catalog.dart';
import 'package:nanimonjya/services/iap_service.dart';
import 'package:nanimonjya/services/player_profile.dart';

/// 💳 課金の「お金に直結するところ」を守るテスト。
///
/// 実際の購入フローはストアがないと流せないので、ここでは
/// **付与のルール**だけを見る。ここが崩れると、返金・二重付与・
/// 無限にコインが増える、のどれかが起きる。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final p = PlayerProfile.instance;
    await p.load();
    p.coins = 0;
    p.adsRemoved = false;
    p.premiumCoinsGranted = false;
    p.awakenings = 0; // コイン倍率を等倍に固定
    p.unlockedCharacters.clear();
  });

  test('商品IDは変えられない（Play Console 登録後は変更不可）', () {
    expect(IapService.productCoins500, 'coins-500');
    expect(IapService.productCoins1200, 'coins-1200');
    expect(IapService.productCoins3000, 'coins-3000');
    expect(IapService.productRemoveAds, 'remove-ads');
    expect(IapService.productPremium, 'premium');
    expect(IapService.productPremiumMonthly, 'premium_monthly');
    expect(IapService.allProductIds.length, 6);
    expect(IapService.allProductIds.toSet().length, 6, reason: 'IDが重複しない');
  });

  test('復元で渡していいのは買い切りだけ（消費型を含めるとコインが無限に増える）', () {
    expect(
        IapService.nonConsumables,
        {
          IapService.productRemoveAds,
          IapService.productPremium,
          IapService.productPremiumMonthly,
        });
    for (final id in [
      IapService.productCoins500,
      IapService.productCoins1200,
      IapService.productCoins3000,
    ]) {
      expect(IapService.nonConsumables.contains(id), isFalse,
          reason: '$id は消費型なので復元の対象にしない');
    }
  });

  test('プレミアムは広告除去・全キャラ・おまけコインを渡す', () async {
    final p = PlayerProfile.instance;
    await IapService.instance.deliverPremiumForTest();

    expect(p.adsRemoved, isTrue);
    // 実績の解除報酬が上乗せされることがあるので「最低でもおまけコインぶん」
    expect(p.coins, greaterThanOrEqualTo(IapService.premiumCoins));
    for (final c in kExtraCharacters) {
      expect(p.unlockedCharacters.contains(c.id), isTrue,
          reason: '${c.id} が解放されていない');
    }
  });

  test('プレミアムのおまけコインは、復元で何度通っても1回だけ', () async {
    final p = PlayerProfile.instance;
    await IapService.instance.deliverPremiumForTest();
    final afterFirst = p.coins;

    // 機種変更のたびに「購入の復元」で同じ購入が流れてくる
    await IapService.instance.deliverPremiumForTest();
    await IapService.instance.deliverPremiumForTest();

    expect(p.coins, afterFirst, reason: '復元のたびにコインが増えてはいけない');
    expect(p.premiumCoinsGranted, isTrue);
  });

  test('Webでは課金UIを出さない', () {
    // kIsWeb は false（VMテスト）なので、ここで見るのは
    // 「ストアにつながる前は false のまま」という側。
    expect(IapService.instance.available, isFalse,
        reason: 'ストア未接続のあいだ購入UIを出すと、押した先で必ず失敗する');
  });
}
