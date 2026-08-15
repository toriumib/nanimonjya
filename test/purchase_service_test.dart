import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nanimonjya/models/achievement.dart';
import 'package:nanimonjya/services/player_profile.dart';
import 'package:nanimonjya/services/purchase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('コインパックのカタログ', () {
    test('表示順とコイン表の中身が一致している', () {
      // 片方だけ足すと「並ばない商品」や「0コインの商品」が生まれる
      expect(PurchaseService.kCoinPackOrder.toSet(),
          PurchaseService.kCoinPacks.keys.toSet());
    });

    test('安い順に並んでいて、量が単調に増える', () {
      final amounts = [
        for (final id in PurchaseService.kCoinPackOrder)
          PurchaseService.kCoinPacks[id]!,
      ];
      for (var i = 1; i < amounts.length; i++) {
        expect(amounts[i], greaterThan(amounts[i - 1]),
            reason: '${PurchaseService.kCoinPackOrder[i]} が前より少ない');
      }
    });

    test('広告除去のIDはコインパックと重ならない', () {
      // 重なると _onPurchaseUpdated の分岐が両方に入る
      expect(PurchaseService.kCoinPacks.containsKey(PurchaseService.removeAdsId),
          isFalse);
    });

    test('コイン量はすべて正の数', () {
      for (final e in PurchaseService.kCoinPacks.entries) {
        expect(e.value, greaterThan(0), reason: '${e.key} が0以下');
      }
    });
  });

  group('課金で買ったコイン', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final p = PlayerProfile.instance;
      await p.load();
      p.coins = 0;
      p.lifetimeCoins = 0;
      p.paidCoinsLifetime = 0;
      p.awakenings = 0;
      p.selectedCharm = 'none';
      p.missionCoinsEarned = 0;
      // grantPurchasedCoins は実績チェックも走らせる（コインを買って
      // 累計1000を超えれば rich1000 が解放されるのは正しい挙動）。
      // ここでは付与の計算だけを見たいので、実績は全部済みにして黙らせる。
      p.unlockedAchievements = {for (final a in kAchievements) a.id};
    });

    test('額面どおり入る（倍率を掛けない）', () async {
      final p = PlayerProfile.instance;
      p.awakenings = 4; // 1.2倍。これが掛かってはいけない
      await p.grantPurchasedCoins(1000);
      expect(p.coins, 1000);
      expect(p.paidCoinsLifetime, 1000);
    });

    test('デイリーミッションの進捗には入らない', () async {
      final p = PlayerProfile.instance;
      await p.grantPurchasedCoins(1000);
      // 課金で「今日60コイン稼ぐ」が達成されるのは筋が悪い
      expect(p.missionCoinsEarned, 0);
    });

    test('0以下は何もしない', () async {
      final p = PlayerProfile.instance;
      await p.grantPurchasedCoins(0);
      await p.grantPurchasedCoins(-100);
      expect(p.coins, 0);
      expect(p.paidCoinsLifetime, 0);
    });

    test('買うたびに累計が積み上がる', () async {
      final p = PlayerProfile.instance;
      await p.grantPurchasedCoins(1000);
      await p.grantPurchasedCoins(3500);
      expect(p.coins, 4500);
      expect(p.paidCoinsLifetime, 4500);
    });
  });
}
