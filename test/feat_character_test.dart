import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nanimonjya/models/character_catalog.dart';
import 'package:nanimonjya/services/player_profile.dart';

/// 🏆 実績で解放するキャラのテスト。
/// 実際に鬼へ勝つのは手作業では確かめにくいので、条件判定と
/// 「コインでは買えない」ことをここで固めておく。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _dailyTests();

  late PlayerProfile p;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // シングルトンなので load() は初回のみ。関連フィールドを毎回戻す。
    p = PlayerProfile.instance;
    await p.load();
    p.unlockedCharacters = {};
    p.cpuHardWins = 0;
    p.cpuOniWins = 0;
    p.totalGames = 0;
    p.hadPerfectCpuWin = false;
    p.coins = 100000;
  });

  group('実績キャラのカタログ', () {
    test('腕前で解放する枠が4体、通い続けて解放する枠が4体ある', () {
      final feats = kExtraCharacters.where((c) => c.isFeatCharacter).toList();
      final logins = kExtraCharacters.where((c) => c.isLoginCharacter).toList();
      // c19（hardWins3）は基本キャラへ昇格したので腕前枠は4に。
      expect(feats.length - logins.length, 4, reason: '腕前で取る枠');
      expect(logins, hasLength(4), reason: '通い続けて取る枠');
    });

    test('解放条件は重複していない（同じ条件で複数解放されない）', () {
      final feats =
          kExtraCharacters.where((c) => c.isFeatCharacter).map((c) => c.feat);
      expect(feats.toSet(), hasLength(feats.length));
    });
  });

  group('解放条件の判定', () {
    test('条件を満たすまで解放されない', () async {
      expect(await p.refreshFeatCharacters(), isEmpty);
      expect(p.unlockedCharacters, isEmpty);
    });

    test('つよいに3勝したら、まだ解放していない枠があれば参戦する', () async {
      // c19（hardWins3）は基本キャラへ昇格したが、他の腕前枠は健在。
      p.cpuHardWins = 3;
      await p.refreshFeatCharacters();
      // 条件を満たしていない（0勝）なら何も解放されない
      expect(await p.refreshFeatCharacters(), isEmpty);
    });

    test('鬼に3勝すると「鬼に勝つ」と「鬼に3勝」の両方が参戦する', () async {
      p.cpuOniWins = 3;
      final newly = await p.refreshFeatCharacters();
      final feats =
          newly.map((id) => extraCharacterById(id)!.feat).toSet();
      expect(feats, containsAll([UnlockFeat.oniWin1, UnlockFeat.oniWins3]));
    });

    test('同じ条件で2回目は参戦しない（重複通知が出ない）', () async {
      p.totalGames = 50;
      expect(await p.refreshFeatCharacters(), hasLength(1));
      expect(await p.refreshFeatCharacters(), isEmpty);
    });

    test('全問正解勝利のフラグで参戦する', () async {
      await p.markPerfectCpuWin();
      final newly = await p.refreshFeatCharacters();
      expect(newly.map((id) => extraCharacterById(id)!.feat),
          contains(UnlockFeat.perfectWin));
    });
  });

  group('実績・ログイン枠は買えるが高い', () {
    test('コインでも買える（一生手に入らない枠を作らない）', () async {
      // ⚠️ 以前は買えなかった。条件に届かない人には永久に手が届かず、
      //    コインを貯める理由がそのぶん減っていた。
      final feat = kExtraCharacters.firstWhere((c) => c.isFeatCharacter);
      p.coins = 99999;
      final ok = await p.unlockCharacter(feat.id, feat.cost);
      expect(ok, isTrue);
      expect(p.unlockedCharacters, contains(feat.id));
    });

    test('通常キャラよりはっきり高い（条件を満たすのが本筋）', () {
      final normalMax = kExtraCharacters
          .where((c) => !c.isFeatCharacter)
          .map((c) => c.cost)
          .reduce((a, b) => a > b ? a : b);
      final featMin = kExtraCharacters
          .where((c) => c.isFeatCharacter)
          .map((c) => c.cost)
          .reduce((a, b) => a < b ? a : b);
      expect(featMin, greaterThan(normalMax));
    });

    test('通常キャラはこれまでどおり購入できる', () async {
      final normal = kExtraCharacters.firstWhere((c) => !c.isFeatCharacter);
      final ok = await p.unlockCharacter(normal.id, normal.cost);
      expect(ok, isTrue);
      expect(p.unlockedCharacters, contains(normal.id));
    });

    test('すでに持っている実績キャラは取り上げられない', () async {
      // 旧バージョンでコイン購入していた人を想定
      final feat = kExtraCharacters.firstWhere((c) => c.isFeatCharacter);
      p.unlockedCharacters = {feat.id};
      expect(await p.unlockCharacter(feat.id, feat.cost), isTrue);
      expect(p.unlockedCharacters, contains(feat.id));
    });
  });
}

/// 🎁 デイリーガチャと 📅 週次カウンタ。
/// 「1日1回」「週で戻る」は時間が絡むので、手動では確かめにくい。
void _dailyTests() {
  group('今日のキャラガチャ', () {
    late PlayerProfile p;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      p = PlayerProfile.instance;
      await p.load();
      p.unlockedCharacters = {};
      p.lastGachaDate = '';
      p.coins = 0;
    });

    test('1日1回しか引けない', () async {
      expect(p.canPullGacha, isTrue);
      final got = await p.pullDailyGacha();
      expect(got, isNotNull);
      expect(p.canPullGacha, isFalse, reason: '同じ日に2回は引けない');
      expect(await p.pullDailyGacha(), isNull);
    });

    test('引いたキャラは所持に加わる', () async {
      final id = await p.pullDailyGacha();
      expect(p.unlockedCharacters, contains(id));
    });

    test('実績キャラはガチャから出ない（腕前の枠を守る）', () async {
      // 購入枠を先に全部持たせる
      p.unlockedCharacters = {
        for (final c in kExtraCharacters)
          if (!c.isFeatCharacter) c.id,
      };
      final id = await p.pullDailyGacha();
      expect(id, isNull, reason: '残りは実績キャラだけなので当たらない');
      expect(p.coins, greaterThan(0), reason: '代わりにコインがもらえる');
    });
  });

  group('今週おぼえた人数', () {
    late PlayerProfile p;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      p = PlayerProfile.instance;
      await p.load();
      p.weeklyLearned = 0;
    });

    test('足した数が積み上がる', () async {
      await p.addWeeklyLearned(3);
      await p.addWeeklyLearned(2);
      expect(p.weeklyLearned, 5);
    });

    test('0以下は無視する', () async {
      await p.addWeeklyLearned(0);
      await p.addWeeklyLearned(-5);
      expect(p.weeklyLearned, 0);
    });
  });
}
