import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nanimonjya/services/player_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('覚醒（プレステージ）システム', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      // PlayerProfileはシングルトンでload()は初回しか読み直さないため、
      // テストごとに関連フィールドを直接デフォルトへ戻す。
      final p = PlayerProfile.instance;
      await p.load();
      p.awakenings = 0;
      p.cpuRating = 1000;
      p.cpuOniWins = 0;
      p.coins = 0;
    });

    test('初期状態では覚醒できない・倍率は1.0倍', () {
      final p = PlayerProfile.instance;
      expect(p.canAwaken, isFalse);
      expect(p.coinMultiplier, 1.0);
    });

    test('鬼段位＋鬼CPU3勝で覚醒できるようになる', () {
      final p = PlayerProfile.instance;
      p.cpuRating = 1600;
      p.cpuOniWins = 3;
      expect(p.canAwaken, isTrue);
    });

    test('覚醒するとレーティングがリセットされ、倍率が永続的に上がる', () async {
      final p = PlayerProfile.instance;
      p.cpuRating = 1700;
      p.cpuOniWins = 5;
      final ok = await p.awaken();
      expect(ok, isTrue);
      expect(p.awakenings, 1);
      expect(p.cpuRating, 1000);
      expect(p.coinMultiplier, 1.05);
    });

    test('覚醒後はコイン獲得が倍率ぶん多くなる', () async {
      final p = PlayerProfile.instance;
      p.cpuRating = 1600;
      p.cpuOniWins = 3;
      await p.awaken();
      // 覚醒条件を満たした状態での実績付与コインを先に流し切ってから計測する
      await p.grantBonusCoins(0);
      final before = p.coins;
      await p.grantBonusCoins(100);
      expect(p.coins - before, 105); // 100 * 1.05倍
    });

    test('条件を満たさないと覚醒できない', () async {
      final p = PlayerProfile.instance;
      p.cpuRating = 1600;
      p.cpuOniWins = 2; // 3勝未満
      final ok = await p.awaken();
      expect(ok, isFalse);
      expect(p.awakenings, 0);
    });
  });
}
