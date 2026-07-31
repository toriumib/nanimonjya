import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nanimonjya/models/character_catalog.dart';
import 'package:nanimonjya/services/player_profile.dart';

/// 🏆 実績で解放するキャラのテスト。
/// 実際に鬼へ勝つのは手作業では確かめにくいので、条件判定と
/// 「コインでは買えない」ことをここで固めておく。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    test('実績キャラはちょうど5体、購入キャラは15体', () {
      final feats = kExtraCharacters.where((c) => c.isFeatCharacter).toList();
      expect(feats, hasLength(5));
      expect(kExtraCharacters.length - feats.length, 15);
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

    test('つよいに3勝で1体だけ参戦する', () async {
      p.cpuHardWins = 2;
      expect(await p.refreshFeatCharacters(), isEmpty);
      p.cpuHardWins = 3;
      final newly = await p.refreshFeatCharacters();
      expect(newly, hasLength(1));
      expect(extraCharacterById(newly.first)!.feat, UnlockFeat.hardWins3);
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

  group('実績キャラはコインで買えない', () {
    test('コインが有り余っていても購入は失敗する', () async {
      final feat = kExtraCharacters.firstWhere((c) => c.isFeatCharacter);
      final before = p.coins;
      final ok = await p.unlockCharacter(feat.id, feat.cost);
      expect(ok, isFalse);
      expect(p.unlockedCharacters, isEmpty);
      expect(p.coins, before, reason: 'コインが減ってはいけない');
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
