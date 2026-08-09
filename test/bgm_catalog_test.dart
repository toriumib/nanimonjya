import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nanimonjya/models/bgm_catalog.dart';

/// 🎵 曲を消したときに無音にならないか。
///
/// ⚠️ 2026-08 にBGMを8曲消したとき、`selectedBgm` の既定が削除対象
///    （`08_burning_heart.mp3`）のままだった。そのまま出していれば
///    **全ユーザーが無音**になっていた。二度とやらないための番人。
void main() {
  group('カタログの整合性', () {
    test('無料の曲は、すべてカタログに載っている', () {
      // ここが欠けると「持っているのに存在しない曲」が生まれて無音になる
      for (final a in kFreeBgmAssets) {
        expect(isKnownBgm(a), isTrue, reason: a);
      }
    });

    test('ホームでランダムに引く曲は、すべて無料で持っている', () {
      // 買っていない曲が勝手に鳴らないこと
      for (final a in kHomeRandomPool) {
        expect(kFreeBgmAssets, contains(a), reason: a);
      }
    });

    test('各場面の既定曲は、無料で持っている', () {
      expect(kFreeBgmAssets, contains(kDefaultGameBgmAsset));
      expect(kFreeBgmAssets, contains(kDefaultResultBgmAsset));
      expect(kFreeBgmAssets, contains(kHomeBgmAsset));
    });

    test('ランダムの目印は、曲のファイル名とぶつからない', () {
      expect(isKnownBgm(kHomeBgmRandom), isFalse);
    });

    test('カタログの曲は、すべて assets/audio に実在する', () {
      // ⚠️ **これがいちばん効く検査。**
      //    ファイルだけ消してカタログを直し忘れる、あるいはその逆を防ぐ。
      //    どちらも症状は「無音」で、実機で気づくまで分からない。
      for (final b in kBgmCatalog) {
        expect(File('assets/audio/${b.asset}').existsSync(), isTrue,
            reason: '${b.asset} がカタログにあるのにファイルが無い');
      }
    });

    test('クレジットが要る曲を積んでいる間は、表示フラグが立つ', () {
      expect(kHasCreditedBgm, kBgmCatalog.any((b) => b.needsCredit));
    });
  });

  group('消した曲からの復帰', () {
    test('消えた曲を選んでいたら、既定へ戻す', () {
      final s = migrateBgmSelection(
        savedUnlocked: const ['op9-2-Nocturne.mp3', '08_burning_heart.mp3'],
        savedGame: '08_burning_heart.mp3', // 2026-08 に消した曲
        savedResult: '19_12345.mp3',
        savedHome: '05_halzion.mp3', // 同上
      );
      expect(s.game, kDefaultGameBgmAsset);
      expect(s.home, kHomeBgmRandom);
      // 消えた曲は持ち物からも外れる
      expect(s.unlocked, isNot(contains('08_burning_heart.mp3')));
      expect(s.unlocked, isNot(contains('op9-2-Nocturne.mp3')));
    });

    test('残っている曲を選んでいたら、そのまま', () {
      final s = migrateBgmSelection(
        savedUnlocked: const ['c00Chopin_Fantaisie-Impromptu.mp3'],
        savedGame: 'c00Chopin_Fantaisie-Impromptu.mp3',
        savedResult: 'shining_star.mp3',
        savedHome: 'beethoven_5th.mp3',
      );
      expect(s.game, 'c00Chopin_Fantaisie-Impromptu.mp3');
      expect(s.result, 'shining_star.mp3');
      expect(s.home, 'beethoven_5th.mp3');
    });

    test('まっさらな人には、無料の曲が全部わたる', () {
      final s = migrateBgmSelection(
        savedUnlocked: const [],
        savedGame: null,
        savedResult: null,
        savedHome: null,
      );
      expect(s.unlocked, containsAll(kFreeBgmAssets));
      expect(s.game, kDefaultGameBgmAsset);
      expect(s.result, kDefaultResultBgmAsset);
      expect(s.home, kHomeBgmRandom); // 既定はおまかせ
    });

    test('買っていない曲を選んでいたら、既定へ戻す', () {
      // カタログにはあるが未購入。鳴らせないので戻す
      final s = migrateBgmSelection(
        savedUnlocked: const [],
        savedGame: 'c00Chopin_Fantaisie-Impromptu.mp3',
        savedResult: null,
        savedHome: null,
      );
      expect(s.game, kDefaultGameBgmAsset);
    });

    test('「おまかせ」はファイル名として弾かれない', () {
      final s = migrateBgmSelection(
        savedUnlocked: const [],
        savedGame: null,
        savedResult: null,
        savedHome: kHomeBgmRandom,
      );
      expect(s.home, kHomeBgmRandom);
    });
  });
}
