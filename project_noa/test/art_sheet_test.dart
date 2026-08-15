import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:project_noa/models/scene_script.dart';
import 'package:project_noa/ui/art/backdrop.dart';
import 'package:project_noa/ui/art/effects.dart';
import 'package:project_noa/ui/art/portrait.dart';

/// 🎨 絵を目で確かめるための一覧を書き出す。
///
/// 絵はテストで正しさを言えない（「かわいいか」は判定できない）。
/// できるのは**全部を一枚に並べて、人が見られるようにすること**。
///
/// 書き出しかた:
///
///   ART=1 flutter test --update-goldens test/art_sheet_test.dart
///
/// で test/goldens/ に PNG が出る。
///
/// ⚠️ ふだんの `flutter test` では走らせない。ゴールデン画像は
///    フォントやGPUの違いで1ドットずれるので、中身が正しくても
///    別のマシンで落ちてしまう。
///
/// ⚠️ dart_test.yaml の `tags` は使わなかった。
///    `skip:` にするとタグを指定しても走らず、`exclude_tags:` にすると
///    `--tags art` でも上書きできない（どちらも走らせる手段が無くなる）。
///    環境変数なら、走らせたいときに確実に走る。
const _enabled = bool.hasEnvironment('ART')
    ? true
    : String.fromEnvironment('ART', defaultValue: '') != '';

void main() {
  if (!_enabled && (Platform.environment['ART'] ?? '').isEmpty) {
    test('絵の一覧（ART=1 のときだけ書き出す）', () {}, skip: 'ART=1 flutter test --update-goldens test/art_sheet_test.dart');
    return;
  }
  testWidgets('立ち絵の一覧（全員 × 4表情）', (tester) async {
    final ids = kPortraits.keys.toList();
    await tester.binding.setSurfaceSize(const Size(1120, 1500));

    await tester.pumpWidget(
      MaterialApp(
        home: Container(
          color: const Color(0xFF12182A),
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final id in ids)
                  Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(id,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13)),
                      ),
                      for (final e in Expression.values)
                        NoahPortrait(charId: id, expression: e, height: 88),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/portraits.png'),
    );
  });

  testWidgets('背景の一覧（シナリオで使うぶん全部）', (tester) async {
    // 実際のシナリオが使っているIDだけを並べる。
    // ここに出ない＝どこからも使われていない背景。
    final ids = <String>{};
    for (final f in Directory('assets/scenes').listSync().whereType<File>()) {
      final j = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      final s = Scene.fromJson(j);
      ids.add(s.bg);
      for (final l in s.lines) {
        if (l is LineBg) ids.add(l.id);
      }
    }
    final list = ids.where((e) => e.isNotEmpty).toList()..sort();

    await tester.binding.setSurfaceSize(const Size(1200, 1400));
    await tester.pumpWidget(
      MaterialApp(
        home: Container(
          color: Colors.black,
          child: Wrap(
            children: [
              for (final id in list)
                SizedBox(
                  width: 300,
                  height: 200,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      NoahBackdrop(id: id),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text(id,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700)); // 切替アニメを終わらせる
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/backdrops.png'),
    );
  });

  testWidgets('演出（フラッシュ・ゆれ・章カード）', (tester) async {
    await tester.binding.setSurfaceSize(const Size(960, 360));
    final keys = [
      GlobalKey<FxLayerState>(),
      GlobalKey<FxLayerState>(),
    ];
    Widget panel(GlobalKey<FxLayerState> k, bool reduce) => Expanded(
          child: FxLayer(
            key: k,
            reduceShake: reduce,
            child: const Stack(fit: StackFit.expand, children: [
              NoahBackdrop(id: 'ship_bridge'),
              Align(
                alignment: Alignment.bottomCenter,
                child: NoahPortrait(charId: 'hoshino', height: 240,
                    expression: Expression.surprise),
              ),
            ]),
          ),
        );

    await tester.pumpWidget(MaterialApp(
      home: Row(children: [
        panel(keys[0], false),
        panel(keys[1], true), // ゆれを弱める設定
        const Expanded(child: ChapterCard(chapter: 'ACT V ／ 呼名')),
      ]),
    ));
    // 演出のいちばん濃いところで止めて撮る
    keys[0].currentState!.play(FxKind.flash);
    keys[1].currentState!.play(FxKind.shake);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/effects.png'),
    );
  });

  testWidgets('老化のかかりかた（同じ場所を age 0 / 5 / 10 で）', (tester) async {
    await tester.binding.setSurfaceSize(const Size(960, 440));
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            for (final age in [0, 5, 10])
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NoahBackdrop(id: 'ship_lounge', age: age),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: NoahPortrait(
                          charId: 'tsuchikura', height: 300, aging: age),
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text('age $age',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/aging.png'),
    );
  });
}
