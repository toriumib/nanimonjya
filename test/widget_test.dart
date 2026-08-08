import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:nanimonjya/l10n/meta_strings.dart';
import 'package:nanimonjya/widgets/emphasis_text.dart';
import 'package:nanimonjya/models/character_catalog.dart';
import 'package:nanimonjya/models/person.dart';

void main() {
  group('character_catalog', () {
    test('追加キャラのIDと画像パスが一意（c13は欠番）', () {
      expect(kExtraCharacters.length, greaterThanOrEqualTo(19));
      expect(kExtraCharacters.map((c) => c.id).toSet(), hasLength(kExtraCharacters.length));
      expect(kExtraCharacters.map((c) => c.asset).toSet(), hasLength(kExtraCharacters.length));
      for (final c in kExtraCharacters) {
        // 追加素材は webp / jpg どちらもある
        expect(c.asset, startsWith('assets/images/'));
        expect(
            c.asset.endsWith('.webp') || c.asset.endsWith('.jpg'), isTrue,
            reason: '${c.id}: 画像として読めない拡張子');
        expect(c.cost, greaterThan(0));
      }
    });

    test('unlockedExtraAssets は購入済みIDだけを返す', () {
      final unlocked = unlockedExtraAssets({'c14', 'c20'});
      expect(unlocked, hasLength(2));
      expect(unlocked, contains('assets/images/char14.webp'));
      expect(unlocked, contains('assets/images/char20.webp'));
    });

    test('applyDeckFilter 除外したキャラがプールから消える', () {
      final pool = ['a', 'b', 'c', 'd', 'e', 'f'];
      final kept = applyDeckFilter(pool, {'b', 'e'});
      expect(kept, ['a', 'c', 'd', 'f']);
    });

    test('applyDeckFilter 除外なしなら元のプールをそのまま返す', () {
      final pool = ['a', 'b', 'c', 'd'];
      expect(applyDeckFilter(pool, {}), same(pool));
    });

    test('applyDeckFilter 残りが最低人数を割るときは除外を無視する', () {
      // 全部OFFにされてもゲームが成立しなくならないようにするための保険
      final pool = ['a', 'b', 'c', 'd', 'e'];
      expect(applyDeckFilter(pool, {'a', 'b', 'c'}), same(pool));
      // ちょうど最低人数(4)残るなら除外は有効
      expect(applyDeckFilter(pool, {'a'}), ['b', 'c', 'd', 'e']);
    });
  });
  group('generatePeople', () {
    test('指定人数ぶん、顔と名前が重複なく生成される', () {
      final people = generatePeople(8, ja: true, random: Random(42));
      expect(people, hasLength(8));
      expect(people.map((p) => p.faceAsset).toSet(), hasLength(8));
      expect(people.map((p) => p.name).toSet(), hasLength(8));
      for (final p in people) {
        expect(p.name, endsWith('さん'));
        // 顔はフリー素材の実写になった（SVGのイラスト顔から変更）
        expect(p.faceAsset, startsWith('assets/images/'));
      }
    });

    test('組み合わせはシードによって変わる（固定ペアの丸暗記防止）', () {
      final a = generatePeople(6, ja: true, random: Random(1));
      final b = generatePeople(6, ja: true, random: Random(2));
      final pairsA = a.map((p) => '${p.faceAsset}:${p.name}').toSet();
      final pairsB = b.map((p) => '${p.faceAsset}:${p.name}').toSet();
      expect(pairsA, isNot(equals(pairsB)));
    });
  });

  group('generateRecallPeople', () {
    test('実写アセット・重複なしの名前・出会った場所が割り当てられる', () {
      final people = generateRecallPeople(6, ja: true, random: Random(3));
      expect(people, hasLength(6));
      expect(people.map((p) => p.face).toSet(), hasLength(6));
      expect(people.map((p) => p.name).toSet(), hasLength(6));
      for (final p in people) {
        expect(p.kind, FaceKind.asset);
        // 基本デッキに char*.jpg 以外の実写も入ったので、
        // 「実写アセットであること」だけを見る
        expect(p.face, startsWith('assets/images/'));
        expect(p.name, endsWith('さん'));
        expect(p.where, isNotEmpty); // 「この人だれだっけ」を支える文脈
        // 架空の名刺情報が埋まっている
        expect(p.company, isNotEmpty);
        expect(p.title, isNotEmpty);
        expect(p.phone, matches(r'^0\d0-\d{4}-\d{4}$'));
        expect(p.email, contains('@'));
      }
    });

    test('recallFieldValue が各項目を返す', () {
      final p = generateRecallPeople(1, ja: true, random: Random(9)).first;
      expect(recallFieldValue(p, RecallField.name), p.name);
      expect(recallFieldValue(p, RecallField.company), p.company);
      expect(recallFieldValue(p, RecallField.email), p.email);
    });
  });

  group('hobbyChoices', () {
    test('正解を含む3択で、選択肢に重複がない', () {
      final person = generatePeople(1, ja: true, random: Random(7)).first;
      final choices = hobbyChoices(person, ja: true, random: Random(7));
      expect(choices, hasLength(3));
      expect(choices.toSet(), hasLength(3));
      expect(choices, contains(person.hobby));
    });
  });


  group('EmphasisText', () {
    const base = TextStyle(fontSize: 14);

    test('`**…**` を太字のスパンに分ける', () {
      final spans = parseEmphasis('あ**い**う', base);
      expect(spans.map((s) => s.text).toList(), ['あ', 'い', 'う']);
      expect(spans[1].style!.fontWeight, FontWeight.w900);
      expect(spans[0].style, isNull);
    });

    test('閉じていない `**` は、消さずにそのまま出す', () {
      // 消すと文章が途中で欠ける。星印が残るほうがまだ読める。
      final spans = parseEmphasis('あ**いう', base);
      expect(spans.map((s) => s.text).join(), 'あ**いう');
    });

    test('強調が無ければ1つのスパンにまとめる', () {
      expect(parseEmphasis('ふつうの文', base).length, 1);
    });

    test('読み上げ用には `**` を落とす', () {
      expect(stripEmphasis('あ**い**う'), 'あいう');
    });
  });

  test('画面に出る文言に、生の `**` を残さない', () {
    // ⚠️ このアプリに Markdown のレンダラは無い。素の Text に渡すと
    //    星印がそのまま画面に出る（実際にチュートリアルで出ていた）。
    //    `**` を書くなら EmphasisText で描くこと。
    for (final ja in [true, false]) {
      final m = MetaStrings(ja);
      // ルール文とチュートリアルの文言は EmphasisText 経由なので対象外。
      // ここでは「素の Text に渡している画面の文言」を見張る。
      expect(m.customEmpty.contains('**'), isFalse);
      expect(m.customDesc.contains('**'), isFalse);
      expect(m.tutPlayStart.contains('**'), isFalse);
    }
  });
}
