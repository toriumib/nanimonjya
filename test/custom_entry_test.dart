import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:nanimonjya/services/custom_roster_service.dart';

/// 📇 名簿データのJSON後方互換テスト。
///
/// ここが壊れると**既存ユーザーの登録済みの名簿が消える**ので、
/// 旧バージョンが書いたJSONを必ず読めることを固定しておく。
void main() {
  test('v1（名前だけ）のJSONが読める', () {
    final e = CustomEntry.fromJson({
      'id': 'abc',
      'imagePath': '/faces/abc.jpg',
      'name': 'やまだ',
    });
    expect(e.name, 'やまだ');
    expect(e.company, '');
    expect(e.nickname, '');
    expect(e.memo, '');
  });

  test('v2（会社・肩書・電話・メール・名刺画像）のJSONが読める', () {
    final e = CustomEntry.fromJson({
      'id': 'abc',
      'imagePath': '/faces/abc.jpg',
      'name': 'やまだ',
      'company': 'あおぞら商事',
      'title': '部長',
      'phone': '03-0000-0000',
      'email': 'a@example.com',
      'cardImagePath': '/faces/abc_card.jpg',
    });
    expect(e.company, 'あおぞら商事');
    expect(e.title, '部長');
    expect(e.phone, '03-0000-0000');
    expect(e.email, 'a@example.com');
    expect(e.cardImagePath, '/faces/abc_card.jpg');
    // 新項目は既定値
    expect(e.reading, '');
    expect(e.relation, '');
  });

  test('新項目を含めて保存し、読み直しても全部残る', () {
    const e = CustomEntry(
      id: 'id1',
      imagePath: '/faces/id1.jpg',
      cardImagePath: '/faces/id1_card.jpg',
      name: 'やまだ',
      reading: 'やまだ',
      nickname: 'やまちゃん',
      gender: '女性',
      birthday: '4月1日',
      company: 'あおぞら商事',
      title: '部長',
      occupation: '営業',
      origin: '北海道',
      address: '東京都',
      relation: '取引先',
      phone: '090-0000-0000',
      email: 'a@example.com',
      x: '@yamada',
      instagram: 'yamada',
      line: 'yamada_line',
      facebook: 'yamada.fb',
      memo: '犬を飼っている',
    );
    final back =
        CustomEntry.fromJson(jsonDecode(jsonEncode(e.toJson())) as Map<String, dynamic>);
    expect(back.nickname, 'やまちゃん');
    expect(back.gender, '女性');
    expect(back.birthday, '4月1日');
    expect(back.occupation, '営業');
    expect(back.origin, '北海道');
    expect(back.address, '東京都');
    expect(back.relation, '取引先');
    expect(back.x, '@yamada');
    expect(back.instagram, 'yamada');
    expect(back.line, 'yamada_line');
    expect(back.facebook, 'yamada.fb');
    expect(back.memo, '犬を飼っている');
  });

  test('copyWith は id / 画像パスだけ差し替え、入力項目は保つ', () {
    const draft = CustomEntry(
      id: '',
      imagePath: '',
      name: 'やまだ',
      nickname: 'やまちゃん',
      memo: 'メモ',
    );
    final saved = draft.copyWith(
        id: 'new-id',
        imagePath: '/faces/new.jpg',
        cardImagePath: '/faces/new_card.jpg');
    expect(saved.id, 'new-id');
    expect(saved.imagePath, '/faces/new.jpg');
    expect(saved.cardImagePath, '/faces/new_card.jpg');
    expect(saved.nickname, 'やまちゃん');
    expect(saved.memo, 'メモ');
  });

  test('入力済みの項目だけを表示用に並べる', () {
    const e = CustomEntry(
      id: 'id1',
      imagePath: '/faces/id1.jpg',
      name: 'やまだ',
      company: 'あおぞら商事',
      memo: '  ', // 空白だけは未入力あつかい
    );
    final shown = e.filledFieldsJa();
    expect(shown.map((x) => x.key), ['会社名']);
  });

  test('Person への変換はクイズで使う項目を引き継ぐ', () {
    const e = CustomEntry(
      id: 'id1',
      imagePath: '/faces/id1.jpg',
      name: 'やまだ',
      company: 'あおぞら商事',
      title: '部長',
      phone: '090-0000-0000',
      email: 'a@example.com',
    );
    final p = e.toPerson();
    expect(p.name, 'やまだ');
    expect(p.company, 'あおぞら商事');
    expect(p.title, '部長');
    expect(p.phone, '090-0000-0000');
    expect(p.email, 'a@example.com');
  });
}
