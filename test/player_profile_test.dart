import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nanimonjya/models/character_catalog.dart';
import 'package:nanimonjya/models/shop_items.dart';
import 'package:nanimonjya/services/player_profile.dart';

/// 実績の判定材料をすべて未達成に戻す。
///
/// PlayerProfile はシングルトンで `load()` が初回しか走らないため、
/// 前のグループが立てたフラグ（cpuOniWins など）が残っていると
/// 意図しない実績が発火して、付与コインの期待値がずれる。
void _clearAchievementStats(PlayerProfile p) {
  p.totalGames = 0;
  p.bestDailyStreak = 0;
  p.bestSessionStreak = 0;
  p.highScore = 0;
  p.onlineGames = 0;
  p.onlineWins = 0;
  p.randomMatches = 0;
  p.cpuEasyWins = 0;
  p.cpuNormalWins = 0;
  p.cpuHardWins = 0;
  p.cpuOniWins = 0;
  p.hadPerfectQuiz = false;
  p.hadFastReflex = false;
  p.soloTrainingSessions = 0;
}

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

  // 🐛 倍率（覚醒・招福こばん）が効かないコイン付与経路があった。
  //    倍率を買った人ほど損をするので、経路ごとに固定しておく。
  group('コイン倍率がすべての付与経路に効く', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final p = PlayerProfile.instance;
      await p.load();
      p.awakenings = 0;
      p.coins = 0;
      p.lifetimeCoins = 0;
      p.unlockedCharms = {'none'};
      p.selectedCharm = 'none';
      p.unlockedCharacters = {};
      p.unlockedAchievements = {};
      p.lastGachaDate = '';
      _clearAchievementStats(p);
    });

    test('実績報酬に倍率がかかる', () async {
      final p = PlayerProfile.instance;
      p.awakenings = 2; // 1.1倍
      p.totalGames = 1; // first_play（30コイン）の条件を満たす
      final newly = await p.refreshAchievements();
      expect(newly, contains('first_play'));
      expect(p.coins, 33); // 30 × 1.1
    });

    test('ガチャの残念賞に倍率がかかる', () async {
      final p = PlayerProfile.instance;
      p.awakenings = 2; // 1.1倍
      // 買えるキャラを全部持っている＝プールが空＝残念賞に落ちる
      p.unlockedCharacters = {
        for (final c in kExtraCharacters)
          if (!c.isFeatCharacter) c.id,
      };
      final got = await p.pullDailyGacha(consolationCoins: 80);
      expect(got, isNull); // キャラは出ない
      expect(p.coins, 88); // 80 × 1.1
    });

    test('倍率なしなら額面どおり入る', () async {
      final p = PlayerProfile.instance;
      p.totalGames = 1;
      await p.refreshAchievements();
      expect(p.coins, 30);
    });
  });

  group('実績・ログイン枠のキャラもコインで買える', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final p = PlayerProfile.instance;
      await p.load();
      p.coins = 0;
      p.lifetimeCoins = 0;
      p.awakenings = 0;
      p.selectedCharm = 'none';
      p.unlockedCharacters = {};
      p.unlockedAchievements = {};
      p.lastGachaDate = '';
      _clearAchievementStats(p);
    });

    test('条件を満たしていなくても、コインが足りていれば買える', () async {
      final feat = kExtraCharacters.firstWhere((c) => c.isFeatCharacter);
      final p = PlayerProfile.instance;
      p.coins = feat.cost;
      final ok = await p.unlockCharacter(feat.id, feat.cost);
      expect(ok, isTrue);
      expect(p.unlockedCharacters, contains(feat.id));
      expect(p.coins, 0);
    });

    test('コインが足りなければ買えない', () async {
      final feat = kExtraCharacters.firstWhere((c) => c.isFeatCharacter);
      final p = PlayerProfile.instance;
      p.coins = feat.cost - 1;
      final ok = await p.unlockCharacter(feat.id, feat.cost);
      expect(ok, isFalse);
      expect(p.unlockedCharacters, isNot(contains(feat.id)));
      expect(p.coins, feat.cost - 1); // 減っていない
    });

    test('実績キャラはガチャのプールには入らない', () async {
      final p = PlayerProfile.instance;
      p.unlockedCharacters = {};
      p.lastGachaDate = '';
      final got = await p.pullDailyGacha();
      expect(got, isNotNull);
      final won = kExtraCharacters.firstWhere((c) => c.id == got);
      expect(won.isFeatCharacter, isFalse);
    });
  });
}
