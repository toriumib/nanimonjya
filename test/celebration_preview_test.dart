import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:nanimonjya/widgets/celebration.dart';
import 'package:nanimonjya/widgets/combo_badge.dart';

/// 🎨 お祝い演出を1枚に並べて書き出す。
///
/// 絵は「かっこいいか」をテストで言えない。できるのは**人が見られる形に
/// 並べること**。実機を触るより速く、毎回おなじ絵が出る。
///
/// 書き出しかた:
///   ART=1 flutter test --update-goldens test/celebration_preview_test.dart
///
/// ⚠️ ふだんの `flutter test` では走らせない。
///    ゴールデン画像はフォントやGPUで1ドットずれるので、
///    中身が正しくても別のマシンで落ちる。
void main() {
  if ((Platform.environment['ART'] ?? '').isEmpty) {
    test('お祝い演出の一覧（ART=1 のときだけ）', () {},
        skip: 'ART=1 flutter test --update-goldens '
            'test/celebration_preview_test.dart');
    return;
  }

  testWidgets('お祝い演出の一覧', (t) async {
    // ⚠️ **テストは pubspec のフォントを自動では読まない。**
    //    読まないと全部が豆腐（□）で描かれ、絵が確認できないうえ、
    //    「サブセットに字が足りない」のか「テストが読んでいないだけ」なのか
    //    区別がつかない。ここで明示的に読ませる。
    const fonts = <String, String>{
      'DelaGothicOne': 'assets/fonts/DelaGothicOne-Pop.ttf',
      'MochiyPopOne': 'assets/fonts/MochiyPopOne-Logo.ttf',
      'ZenMaruGothic': 'assets/fonts/ZenMaruGothic-Bold.ttf',
    };
    for (final e in fonts.entries) {
      final bytes = File(e.value).readAsBytesSync();
      final loader = FontLoader(e.key)
        ..addFont(Future.value(ByteData.view(bytes.buffer)));
      await loader.load();
    }
    await t.binding.setSurfaceSize(const Size(520, 760));
    await t.pumpWidget(
      MaterialApp(
        home: Container(
          color: const Color(0xFFFFF9EC),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const GetBanner(text: 'カードゲット！'),
              const GetBanner(
                text: '5 れんぞく！',
                colors: [Color(0xFFFF3D6A), Color(0xFFFFC02E)],
              ),
              const GetBanner(
                text: 'P1 がゲット！',
                colors: [Color(0xFF3A7BD5), Color(0xFF62B6FF)],
              ),
              const ComboBadge(combo: 3),
              const ComboBadge(combo: 7),
              SizedBox(
                width: 460,
                height: 300,
                child: Stack(children: [
                  Container(color: const Color(0xFFEAF3FF)),
                  // 種を固定して、毎回おなじ紙吹雪にする
                  const Confetti(seed: 7, count: 70),
                  const Center(
                    child: Text('クリア！',
                        style: TextStyle(
                            fontFamily: kPopFont,
                            fontSize: 40,
                            color: Color(0xFFFF6A3D))),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
    // アニメの見ごろで止める
    await t.pump(const Duration(milliseconds: 420));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/celebration.png'),
    );
  });
}
