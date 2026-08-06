import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:nanimonjya/models/avatar.dart';
import 'package:nanimonjya/models/person.dart';
import 'package:nanimonjya/services/custom_roster_service.dart';

/// 🧑‍🎨 顔メモ（アバター）のテスト。
///
/// 保存の後方互換と、値が壊れていても落ちないことを守る。
/// 名簿は他人の個人情報なので、読めなくなる＝データが消えるのが一番まずい。
void main() {
  group('保存と復元', () {
    test('作った顔がそのまま戻る', () {
      const a = Avatar(
        skin: 3,
        faceShape: 2,
        hair: 5,
        hairColor: 4,
        eyes: 3,
        eyebrows: 1,
        nose: 2,
        mouth: 4,
        glasses: 2,
        mole: 1,
        beard: 3,
        gender: 1,
        age: 42,
        height: 178,
      );
      final back = Avatar.decode(a.encode());
      expect(back.encode(), a.encode());
      expect(back.glasses, 2);
      expect(back.mole, 1);
      expect(back.age, 42);
      expect(back.height, 178);
    });

    test('壊れた文字列は既定の顔になる（名簿ごと落とさない）', () {
      expect(Avatar.decode('').encode(), const Avatar().encode());
      expect(Avatar.decode('こわれたデータ').encode(), const Avatar().encode());
      expect(Avatar.decode('{').encode(), const Avatar().encode());
    });

    test('範囲外の値は丸める（パーツを増減しても壊れない）', () {
      final a = Avatar.fromJson({
        'gl': 999,
        'ml': -5,
        'ha': 100,
        'ag': 999,
        'he': 10,
      });
      expect(a.glasses, Avatar.glassesCount - 1);
      expect(a.mole, 0);
      expect(a.hair, Avatar.hairCount - 1);
      expect(a.age, Avatar.maxAge);
      expect(a.height, Avatar.minHeight);
    });

    test('キーが欠けていても既定値で読める', () {
      final a = Avatar.fromJson({});
      expect(a.encode(), const Avatar().encode());
    });

    test('ランダム生成はどの値も範囲内に収まる', () {
      final r = Random(7);
      for (var i = 0; i < 50; i++) {
        final a = Avatar.random(r);
        expect(a.glasses, inInclusiveRange(0, Avatar.glassesCount - 1));
        expect(a.mole, inInclusiveRange(0, Avatar.moleCount - 1));
        expect(a.hair, inInclusiveRange(0, Avatar.hairCount - 1));
        expect(a.age, inInclusiveRange(Avatar.minAge, Avatar.maxAge));
        expect(a.height, inInclusiveRange(Avatar.minHeight, Avatar.maxHeight));
      }
    });

    test('アバターの文字列は画像パスと見分けられる', () {
      expect(Avatar.looksLikeAvatar(const Avatar().encode()), isTrue);
      expect(Avatar.looksLikeAvatar('assets/images/char1.jpg'), isFalse);
      expect(Avatar.looksLikeAvatar('/data/user/0/faces/abc.jpg'), isFalse);
    });
  });

  group('特徴の言語化', () {
    test('メガネ・ほくろ・ひげ・髪型が手がかりとして出る', () {
      const a = Avatar(glasses: 2, mole: 1, beard: 1, hair: 4);
      final f = a.featuresJa();
      expect(f, contains('四角メガネ'));
      expect(f, contains('左ほおにほくろ'));
      expect(f, contains('口ひげ'));
      expect(f, contains('ポニーテール'));
    });

    test('目立つ特徴が無ければ空（無理にひねり出さない）', () {
      // hair=1 は「ふつう」なので特徴に数えない
      const a = Avatar(glasses: 0, mole: 0, beard: 0, hair: 1);
      expect(a.featuresJa(), isEmpty);
    });
  });

  group('名簿への保存', () {
    test('アバターだけで登録できる（写真が無くても顔が出る）', () {
      final entry = const CustomEntry(id: 'a1', imagePath: '', name: '田中さん')
          .copyWith(avatar: const Avatar(glasses: 1).encode());
      final person = entry.toPerson();
      expect(person.kind, FaceKind.avatar);
      expect(Avatar.decode(person.face).glasses, 1);
      expect(person.name, '田中さん');
    });

    test('写真があれば写真を優先する（本物のほうが確実）', () {
      final entry = const CustomEntry(
              id: 'a2', imagePath: '/faces/a2.jpg', name: '鈴木さん')
          .copyWith(avatar: const Avatar(glasses: 1).encode());
      expect(entry.toPerson().kind, FaceKind.file);
      expect(entry.toPerson().face, '/faces/a2.jpg');
    });

    test('写真もアバターも無ければ既定の顔を描く（真っ白にしない）', () {
      const entry = CustomEntry(id: 'a3', imagePath: '', name: '佐藤さん');
      final person = entry.toPerson();
      expect(person.kind, FaceKind.avatar);
      expect(Avatar.looksLikeAvatar(person.face), isTrue);
    });

    test('旧データ（アバターのキーが無い）もそのまま読める', () {
      final e = CustomEntry.fromJson({
        'id': 'old',
        'imagePath': '/faces/old.jpg',
        'name': 'やまだ',
      });
      expect(e.avatar, '');
      expect(e.toPerson().kind, FaceKind.file);
    });

    test('保存して読み直してもアバターが残る', () {
      final e = const CustomEntry(id: 'a4', imagePath: '', name: 'やまだ')
          .copyWith(avatar: const Avatar(mole: 2, hair: 6).encode());
      final back = CustomEntry.fromJson(e.toJson());
      expect(Avatar.decode(back.avatar).mole, 2);
      expect(Avatar.decode(back.avatar).hair, 6);
    });

    test('copyWith で顔を差し替えても他の項目は消えない', () {
      const e = CustomEntry(
        id: 'a5',
        imagePath: '',
        name: 'やまだ',
        company: 'あおぞら商事',
        memo: '犬を飼っている',
      );
      final next = e.copyWith(avatar: const Avatar(glasses: 3).encode());
      expect(next.company, 'あおぞら商事');
      expect(next.memo, '犬を飼っている');
      expect(Avatar.decode(next.avatar).glasses, 3);
    });
  });
}
