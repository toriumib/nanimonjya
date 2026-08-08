import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:project_noa/models/scene_script.dart';
import 'package:project_noa/systems/encyclopedia.dart';

/// 船内百科（STORY 7章・9章）。
///
/// 謎は3周目に全解禁だが、本編で自分で気づいたものは先に開く。
/// この「先に開く」がフラグ頼りなので、シナリオ側と食い違うと
/// **一生開かない謎**ができてしまう。そこを機械で拾う。
void main() {
  test('STORY 7章の6つがそろっている', () {
    expect(kMysteries.length, 6);
    expect(kMysteries.map((m) => m.id).toSet().length, 6, reason: 'IDの重複');
  });

  test('問いと答えが、どれも空でない', () {
    for (final m in kMysteries) {
      expect(m.question, isNotEmpty, reason: m.id);
      expect(m.answer, isNotEmpty, reason: m.id);
    }
  });

  test('全解禁なら、フラグが無くても全部ひらく', () {
    for (final m in kMysteries) {
      expect(isMysteryOpen(m, allUnlocked: true, flags: const {}), isTrue,
          reason: m.id);
    }
  });

  test('解禁前は、フラグの立っているものだけひらく', () {
    final withFlag = kMysteries.firstWhere((m) => m.flag != null);
    expect(
      isMysteryOpen(withFlag, allUnlocked: false, flags: {withFlag.flag!}),
      isTrue,
    );
    expect(
      isMysteryOpen(withFlag, allUnlocked: false, flags: const {}),
      isFalse,
    );
  });

  test('フラグを持たない謎は、周回で解禁するしかない', () {
    final noFlag = kMysteries.where((m) => m.flag == null);
    expect(noFlag, isNotEmpty, reason: '全部が本編で解けると、周回の意味が無くなる');
    for (final m in noFlag) {
      expect(isMysteryOpen(m, allUnlocked: false, flags: const {'なんでも'}),
          isFalse);
    }
  });

  test('謎のフラグは、実際にシナリオのどこかで立つ', () {
    // ここが食い違うと、本編でいくら気づいても一生ひらかない。
    final setFlags = <String>{};
    for (final f in Directory('assets/scenes').listSync().whereType<File>()) {
      final s = Scene.fromJson(
          jsonDecode(f.readAsStringSync()) as Map<String, dynamic>);
      for (final l in s.lines) {
        if (l is LineFlag) setFlags.add(l.set);
      }
    }
    for (final m in kMysteries) {
      final f = m.flag;
      if (f == null) continue;
      expect(setFlags.contains(f), isTrue,
          reason: '${m.id} のフラグ $f を立てるシーンが無い');
    }
  });

  test('用語集がそろっていて、重複が無い', () {
    expect(kGlossary.length, greaterThanOrEqualTo(12));
    expect(kGlossary.map((e) => e.term).toSet().length, kGlossary.length);
    for (final e in kGlossary) {
      expect(e.body, isNotEmpty, reason: e.term);
    }
  });

  test('科学の項目に、確度の区分が書いてある（STORY 6.1）', () {
    // 【観測】【研究段階】【創作】のどれかを添える約束。
    const needsMark = ['ASC', 'MELiSSA', 'DFD', '磁気セイル', 'コネクトーム',
        'クロス・コンタミネーション', '東京層群', 'ベルの不等式'];
    for (final term in needsMark) {
      final e = kGlossary.firstWhere((g) => g.term == term);
      expect(
        e.body.contains('【観測】') ||
            e.body.contains('【研究段階】') ||
            e.body.contains('【創作】'),
        isTrue,
        reason: '$term に確度の区分が無い',
      );
    }
  });

  test('ベルの不等式の説明で、決定論を否定していない（STORY 6.3）', () {
    final e = kGlossary.firstWhere((g) => g.term == 'ベルの不等式');
    expect(e.body.contains('局所実在論'), isTrue);
    expect(e.body.contains('決定論そのものではない'), isTrue,
        reason: '「量子力学が運命を否定した」と読めてはいけない');
  });
}
