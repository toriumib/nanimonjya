import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nanimonjya/models/person.dart';

void main() {
  group('generatePeople', () {
    test('指定人数ぶん、顔と名前が重複なく生成される', () {
      final people = generatePeople(8, ja: true, random: Random(42));
      expect(people, hasLength(8));
      expect(people.map((p) => p.faceAsset).toSet(), hasLength(8));
      expect(people.map((p) => p.name).toSet(), hasLength(8));
      for (final p in people) {
        expect(p.name, endsWith('さん'));
        expect(p.faceAsset, startsWith('assets/images/faces/'));
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
        expect(p.face, startsWith('assets/images/char'));
        expect(p.name, endsWith('さん'));
        expect(p.where, isNotEmpty); // 「この人だれだっけ」を支える文脈
      }
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
}
