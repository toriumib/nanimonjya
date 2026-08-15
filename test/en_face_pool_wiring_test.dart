import 'package:flutter_test/flutter_test.dart';

import 'package:nanimonjya/models/character_catalog.dart';
import 'package:nanimonjya/models/person.dart';

/// 🌍 出演プールの組み立てが、表示言語をちゃんと見ているか。
///
/// `buildFacePool` に `ja` の既定値（true）を置いていたせいで、
/// なまえコールが渡し忘れたまま日本語版の顔を出していた。
/// **アプリの主役モードで、いちばん目立つ場所**の取りこぼしだったので、
/// 引数は必須にしたうえで、ここで両方向を固定しておく。
void main() {
  test('英語版の出演プールは、英語版の顔だけになる', () {
    final pool = buildFacePool(
      ja: false,
      unlockedIds: const {},
      excluded: const {},
    );
    expect(pool, isNotEmpty);
    for (final f in pool) {
      expect(kCharImageAssetsEn.contains(f.face), isTrue,
          reason: '${f.face} は英語版の顔ではない');
    }
  });

  test('日本語版の出演プールは、これまでどおり日本語版の顔になる', () {
    final pool = buildFacePool(
      ja: true,
      unlockedIds: const {},
      excluded: const {},
    );
    expect(pool, isNotEmpty);
    for (final f in pool) {
      expect(kCharImageAssets.contains(f.face), isTrue, reason: f.face);
    }
  });

  test('顔メモで登録した人は、言語に関係なく出演プールに入る', () {
    const mine = FaceRef(
        deckKey: 'custom:1', kind: FaceKind.file, face: '/tmp/my_photo.jpg');
    for (final ja in [true, false]) {
      final pool = buildFacePool(
        ja: ja,
        unlockedIds: const {},
        excluded: const {},
        customFaces: const [mine],
      );
      expect(pool.any((f) => f.deckKey == 'custom:1'), isTrue,
          reason: 'ja=$ja で自分の登録した人が消えている');
    }
  });

  test('デッキで外した顔は出ないが、減らしすぎたら除外を無視する', () {
    final all = buildFacePool(ja: false, unlockedIds: const {}, excluded: const {});
    final dropped = all.first.deckKey;
    final filtered = buildFacePool(
      ja: false,
      unlockedIds: const {},
      excluded: {dropped},
    );
    expect(filtered.any((f) => f.deckKey == dropped), isFalse);

    // 全部外したらゲームが成立しないので、そのときは除外を無視する
    final allExcluded = buildFacePool(
      ja: false,
      unlockedIds: const {},
      excluded: {for (final f in all) f.deckKey},
    );
    expect(allExcluded.length, all.length);
  });
}
