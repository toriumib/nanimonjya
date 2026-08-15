import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:nanimonjya/models/name_call.dart';
import 'package:nanimonjya/models/person.dart';

/// 🌍 英語版の顔ぶれについての決まりごと。
///
/// 日本語版の顔のまま英語の名前を付けると、顔と名前が結びつかず
/// 「名前を覚える」練習の邪魔になる。表示言語で顔プールを切り替える。
void main() {
  test('英語のときは英語版の顔、日本語のときは日本語版の顔を使う', () {
    expect(charImageAssetsFor(false), kCharImageAssetsEn);
    expect(charImageAssetsFor(true), kCharImageAssets);
  });

  test('英語版の顔は、なまえコールの最大人数ぶん足りている', () {
    // 足りないと generate 系の assert(count <= pool.length) で落ちる
    expect(kCharImageAssetsEn.length,
        greaterThanOrEqualTo(NameCallGame.maxPeople));
    expect(kCharImageAssetsEn.length,
        greaterThanOrEqualTo(kCharImageAssets.length));
  });

  test('英語版の顔のパスは重複せず、登録済みのフォルダを指している', () {
    expect(kCharImageAssetsEn.toSet().length, kCharImageAssetsEn.length);
    for (final a in kCharImageAssetsEn) {
      expect(a.startsWith('assets/images/en/'), isTrue, reason: a);
    }
  });

  test('英語で人物を作ると、英語版の顔と欧米系の名前になる', () {
    final people = generatePeople(6, ja: false, random: Random(1));
    for (final p in people) {
      expect(kCharImageAssetsEn.contains(p.face), isTrue,
          reason: '${p.face} は英語版の顔ではない');
      expect(p.name.endsWith('さん'), isFalse);
    }
    // 名前がローマ字読みの日本語姓のままになっていないこと
    final names = people.map((p) => p.name).toSet();
    expect(names.intersection({'Sato', 'Tanaka', 'Suzuki'}), isEmpty);
  });

  test('日本語で人物を作ると、これまでどおり日本語版の顔になる', () {
    final people = generatePeople(6, ja: true, random: Random(1));
    for (final p in people) {
      expect(kCharImageAssets.contains(p.face), isTrue, reason: p.face);
      expect(p.name.endsWith('さん'), isTrue);
    }
  });

  test('なまえコール用（generateImagePeople）も言語で顔が変わる', () {
    final en = generateImagePeople(5, ja: false, random: Random(2));
    expect(en.every((p) => kCharImageAssetsEn.contains(p.face)), isTrue);
    final ja = generateImagePeople(5, ja: true, random: Random(2));
    expect(ja.every((p) => kCharImageAssets.contains(p.face)), isTrue);
  });

  test('思い出しトレーニング用（generateRecallPeople）も言語で顔が変わる', () {
    final en = generateRecallPeople(4, ja: false, random: Random(3));
    expect(en.every((p) => kCharImageAssetsEn.contains(p.face)), isTrue);
    // 名刺のメールアドレスも英語の姓から作られる
    for (final p in en) {
      expect(p.email.contains('@'), isTrue);
    }
  });

  test('⚠️ オンライン用に渡すプールは言語で変えない（相手と顔ぶれを合わせるため）', () {
    // rank_match / turn_pairs / match_game のオンライン分岐は
    // kCharImageAssets を直接渡している。ここが言語別になると、
    // 日本語の人と英語の人で同じ盤面にならない。
    final people = generatePeople(8,
        ja: false, random: Random(4), charAssets: kCharImageAssets);
    expect(people.every((p) => kCharImageAssets.contains(p.face)), isTrue);
  });
}
