import 'package:flutter_test/flutter_test.dart';
import 'package:nanimonjya/services/card_ocr_service.dart';

/// 名刺OCRの「読み取った行 → 各項目」の振り分けロジックのテスト。
/// 画像認識そのもの（ML Kit）は端末が必要なので、ここでは行の解釈だけを検証する。
void main() {
  final svc = CardOcrService.instance;

  test('日本語の名刺から会社・肩書・氏名・電話・メールを拾う', () {
    final r = svc.extractForTest([
      '株式会社サンプル商事',
      '営業部 部長',
      '山田 太郎',
      '〒100-0001 東京都千代田区1-2-3',
      'TEL: 03-1234-5678',
      'yamada@example.co.jp',
    ]);
    expect(r.company, '株式会社サンプル商事');
    expect(r.title, '営業部 部長');
    expect(r.name, '山田 太郎');
    expect(r.phone, contains('03-1234-5678'));
    expect(r.email, 'yamada@example.co.jp');
  });

  test('英語表記の名刺でも拾える', () {
    final r = svc.extractForTest([
      'Example Inc.',
      'Senior Engineer',
      'Jane Doe',
      '+1 555-123-4567',
      'jane@example.com',
    ]);
    expect(r.company, 'Example Inc.');
    expect(r.title, 'Senior Engineer');
    expect(r.email, 'jane@example.com');
    expect(r.phone, isNotEmpty);
  });

  test('住所の行を氏名に採用しない', () {
    final r = svc.extractForTest([
      '東京都港区',
      '佐藤 花子',
    ]);
    expect(r.name, '佐藤 花子');
  });

  test('FAXを電話番号として拾わない', () {
    final r = svc.extractForTest([
      'FAX 03-9999-9999',
      'TEL 03-1111-2222',
    ]);
    expect(r.phone, contains('03-1111-2222'));
  });

  test('何も読めなければ isEmpty', () {
    final r = svc.extractForTest([]);
    expect(r.isEmpty, isTrue);
  });
}
