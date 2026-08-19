import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nanimonjya/models/shop_items.dart';
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

  group('ショップ拡張アイテム', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final p = PlayerProfile.instance;
      await p.load();
      p.awakenings = 0;
      p.coins = 0;
      p.unlockedVoices = {'none'};
      p.selectedVoice = 'none';
      p.unlockedCharms = {'none'};
      p.selectedCharm = 'none';
    });

    test('コインが足りないと買えない', () async {
      final p = PlayerProfile.instance;
      p.coins = 10;
      final ok = await p.unlockVoice('cheer', 180);
      expect(ok, isFalse);
      expect(p.unlockedVoices.contains('cheer'), isFalse);
      expect(p.coins, 10); // 減っていない
    });

    test('買うとコインが引かれ、装備できる', () async {
      final p = PlayerProfile.instance;
      p.coins = 500;
      final ok = await p.unlockVoice('cheer', 180);
      expect(ok, isTrue);
      expect(p.coins, 320);
      await p.selectVoice('cheer');
      expect(p.selectedVoice, 'cheer');
    });

    test('持っていないものは装備できない', () async {
      final p = PlayerProfile.instance;
      await p.selectCharm('shield');
      expect(p.selectedCharm, 'none');
    });

    test('招福こばんのお守りでコイン倍率が上がる', () async {
      final p = PlayerProfile.instance;
      expect(p.coinMultiplier, 1.0);
      p.coins = 1000;
      await p.unlockCharm('koban', 380);
      await p.selectCharm('koban');
      expect(p.coinMultiplier, closeTo(2.0, 0.001)); // コイン2倍
    });

    test('覚醒の倍率にアイテムの2倍が掛かる', () async {
      final p = PlayerProfile.instance;
      p.awakenings = 2; // +10%
      p.coins = 1000;
      await p.unlockCharm('koban', 380);
      await p.selectCharm('koban'); // コイン2倍
      expect(p.coinMultiplier, closeTo(2.2, 0.001)); // 1.1 × 2
    });

    test('アイテムはコイン2倍の1つだけ', () {
      expect(luckyCharmById('koban').effect, CharmEffect.coinBoost);
      // 未知のIDは「なし」に落ちる
      expect(luckyCharmById('unknown').effect, CharmEffect.none);
      // 廃止したお守りは、装備していても効果を持たない
      expect(luckyCharmById('shield').effect, CharmEffect.none);
      expect(luckyCharmById('compass').effect, CharmEffect.none);
      expect(kLuckyCharms.length, 2); // なし＋招福こばん
    });

    test('ほめボイスのカタログが引ける', () {
      expect(praiseVoiceById('butler').linesJa, isNotEmpty);
      expect(praiseVoiceById('none').linesJa, isEmpty);
      // 🙏 いろいろな立場のほめ方
      expect(praiseVoiceById('miko').linesJa, isNotEmpty);
    });
  });
}
