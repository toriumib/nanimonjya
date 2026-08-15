import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:nanimonjya/models/avatar.dart';
import 'package:nanimonjya/models/character_catalog.dart';
import 'package:nanimonjya/models/person.dart';

/// 🎴 キャラデッキの意思が、実際の出演にそのまま効くかを守る。
///
/// ここが壊れていた:
/// - キャラデッキに「自分で登録した人」の欄があるのに、ゲーム側の
///   出演プールは kCharImageAssets と購入キャラしか見ていなかった
///   （ONにしても対戦に出てこない）
/// - 似顔絵だけの人は画像パスが空文字なので、パスをキーにすると
///   登録した全員が同じキーに潰れる（1人OFFで全員消える）
void main() {
  FaceRef avatarFace(String id) => FaceRef(
        deckKey: 'custom:$id',
        kind: FaceKind.avatar,
        face: const Avatar().encode(),
      );

  group('出演プールの組み立て', () {
    test('顔メモの人がプールに入る', () {
      final pool = buildFacePool(ja: true, 
        unlockedIds: const {},
        excluded: const {},
        customFaces: [avatarFace('a'), avatarFace('b')],
      );
      final keys = pool.map((f) => f.deckKey).toSet();
      expect(keys, contains('custom:a'));
      expect(keys, contains('custom:b'));
      expect(pool.length, kCharImageAssets.length + 2);
    });

    test('購入したキャラもプールに入る', () {
      final id = kExtraCharacters.first.id;
      final pool = buildFacePool(ja: true, unlockedIds: {id}, excluded: const {});
      expect(pool.map((f) => f.face), contains(kExtraCharacters.first.asset));
    });

    test('OFFにした人はプールから消える', () {
      final pool = buildFacePool(ja: true, 
        unlockedIds: const {},
        excluded: {'custom:a'},
        customFaces: [avatarFace('a'), avatarFace('b')],
      );
      final keys = pool.map((f) => f.deckKey).toSet();
      expect(keys, isNot(contains('custom:a')));
      expect(keys, contains('custom:b'), reason: 'OFFにしたのは a だけ');
    });

    test('似顔絵の人を1人OFFにしても、ほかの似顔絵の人は残る', () {
      // 画像パス（どちらも空文字）をキーにしていたころは、
      // ここで似顔絵の人が全員まとめて消えていた。
      final pool = buildFacePool(ja: true, 
        unlockedIds: const {},
        excluded: {'custom:a'},
        customFaces: [avatarFace('a'), avatarFace('b'), avatarFace('c')],
      );
      final customs =
          pool.where((f) => f.deckKey.startsWith('custom:')).toList();
      expect(customs.length, 2);
    });

    test('絞りすぎてゲームが成立しないときは、除外を無視する', () {
      final all = {
        for (final a in kCharImageAssets) a,
      };
      final pool = buildFacePool(ja: true, unlockedIds: const {}, excluded: all);
      expect(pool.length, kCharImageAssets.length,
          reason: '全部OFFにしても、遊べなくなるよりは元に戻す');
    });
  });

  group('プールから人を作る', () {
    test('指定した人数ぶん、重複なく作られる', () {
      final pool = buildFacePool(ja: true, 
        unlockedIds: const {},
        excluded: const {},
        customFaces: [avatarFace('a')],
      );
      final people =
          generatePeopleFromFaces(6, faces: pool, random: Random(1));
      expect(people.length, 6);
      expect(people.map((p) => p.face).toSet().length, 6);
    });

    test('似顔絵の人は avatar として作られる（画像として読もうとしない）', () {
      final people = generatePeopleFromFaces(
        1,
        faces: [avatarFace('a')],
        random: Random(1),
      );
      expect(people.single.kind, FaceKind.avatar);
      // 顔がアバターのJSONとして読み直せる
      expect(Avatar.looksLikeAvatar(people.single.face), isTrue);
    });

    test('プールが足りなければ基本の顔ぶれで埋める（人数不足で止まらない）', () {
      final people = generatePeopleFromFaces(
        8,
        faces: [avatarFace('a')],
        random: Random(2),
      );
      expect(people.length, 8);
      expect(people.map((p) => p.face).toSet().length, 8);
    });

    test('埋めるときも、すでにプールにいる顔は二重にしない', () {
      final dup = FaceRef.asset(kCharImageAssets.first);
      final people = generatePeopleFromFaces(
        5,
        faces: [dup],
        random: Random(3),
      );
      expect(people.map((p) => p.face).toSet().length, 5);
    });
  });
}
