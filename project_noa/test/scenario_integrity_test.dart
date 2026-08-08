import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:project_noa/models/noah_field.dart';
import 'package:project_noa/models/scene_script.dart';
import 'package:project_noa/systems/ending.dart';
import 'package:project_noa/ui/art/portrait.dart';

/// シナリオの通し検査。
///
/// エンジンは知らない行やIDを読み飛ばすように作ってあるので、
/// **書き間違えても落ちない代わりに、黙って素通りする**。
/// 気づけるのはここだけなので、参照切れを機械で拾う。
void main() {
  final dir = Directory('assets/scenes');
  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList();

  final scenes = <String, Scene>{};
  for (final f in files) {
    final s = Scene.parse(f.readAsStringSync());
    scenes[s.id] = s;
  }

  final cast = () {
    final j = jsonDecode(File('assets/characters.json').readAsStringSync())
        as Map<String, dynamic>;
    return NoahCast([
      for (final c in (j['characters'] as List))
        NoahCharacter.fromJson(c as Map<String, dynamic>),
    ]);
  }();

  test('シナリオが1本以上ある', () {
    expect(scenes, isNotEmpty);
  });

  test('登場人物は17人（STORY 1章の「残存人口17人」と合わせる）', () {
    // ここがずれると記憶率の分母（17×5＝85）も、
    // 最終盤の「17人ぶんの点呼」もおかしくなる。
    expect(cast.all.length, 17);
  });

  test('全員に立ち絵がある（誰か1人だけ出てこない、を防ぐ）', () {
    for (final c in cast.all) {
      expect(kPortraits.containsKey(c.id), isTrue,
          reason: '${c.name}（${c.id}）の立ち絵が無い');
    }
  });

  test('立ち絵の余りが無い（消したキャラの絵が残っていない）', () {
    final ids = cast.all.map((c) => c.id).toSet();
    for (final id in kPortraits.keys) {
      expect(ids.contains(id), isTrue, reason: '$id はもう名簿にいない');
    }
  });

  test('シナリオが指す立ち絵のIDが実在する', () {
    for (final s in scenes.values) {
      for (final l in s.lines) {
        if (l is LineSay && l.sprite.isNotEmpty) {
          final id = l.sprite.split('/').first;
          expect(kPortraits.containsKey(id), isTrue,
              reason: '${s.id}: 知らない立ち絵 ${l.sprite}');
        }
      }
    }
  });

  test('ファイル名と中の id が一致している', () {
    for (final f in files) {
      final name = f.uri.pathSegments.last.replaceAll('.json', '');
      final s = Scene.parse(f.readAsStringSync());
      expect(s.id, name, reason: '${f.path}: 読み込みは id ではなくファイル名で行う');
    }
  });

  test('jump の飛び先がすべて存在する', () {
    for (final s in scenes.values) {
      for (final l in s.lines) {
        if (l is LineJump) {
          expect(scenes.containsKey(l.to), isTrue,
              reason: '${s.id} → ${l.to} が無い');
        }
      }
    }
  });

  test('選択肢の飛び先がすべて存在する（空欄は「同じシーンを続ける」）', () {
    for (final s in scenes.values) {
      for (final l in s.lines) {
        if (l is LineChoice) {
          for (final o in l.options) {
            if (o.jump.isEmpty) continue;
            expect(scenes.containsKey(o.jump), isTrue,
                reason: '${s.id} の選択肢「${o.text}」→ ${o.jump} が無い');
          }
        }
      }
    }
  });

  test('名前入力の成功時の飛び先が存在する', () {
    for (final s in scenes.values) {
      for (final l in s.lines) {
        if (l is LineNameInput) {
          expect(scenes.containsKey(l.onSuccess), isTrue,
              reason: '${s.id} → ${l.onSuccess} が無い');
        }
      }
    }
  });

  test('memtest のキャラIDと項目が実在する', () {
    for (final s in scenes.values) {
      for (final l in s.lines) {
        if (l is LineMemTest) {
          expect(cast.byId(l.charId), isNotNull,
              reason: '${s.id}: 知らないキャラ ${l.charId}');
          expect(NoahField.fromKey(l.field), isNotNull,
              reason: '${s.id}: 知らない項目 ${l.field}');
        }
      }
    }
  });

  test('好感度を動かす相手が実在する', () {
    for (final s in scenes.values) {
      for (final l in s.lines) {
        if (l is LineAffection) {
          expect(cast.byId(l.charId), isNotNull,
              reason: '${s.id}: 知らないキャラ ${l.charId}');
        }
      }
    }
  });

  test('知らない種類の行が紛れていない（打ち間違いの検出）', () {
    for (final s in scenes.values) {
      for (final l in s.lines) {
        expect(l, isNot(isA<LineUnknown>()),
            reason: '${s.id}: 打ち間違えた行がある');
      }
    }
  });

  test('5つの結末すべてにシーンが用意されている', () {
    for (final e in NoahEnding.values) {
      expect(scenes.containsKey(e.sceneId), isTrue,
          reason: '${e.labelJa}（${e.sceneId}）が無い');
    }
  });

  /// あるシーンから出ていく先を、すべて集める。
  ///
  /// ⚠️ 「最後の jump」だけを追うと読み違える。
  ///    act5_sc02 は「入力成功→次へ」と「失敗→自分へ戻る」の
  ///    2本を持っていて、後ろにあるのは戻るほうだった。
  Set<String> exitsOf(Scene s) => {
        for (final l in s.lines)
          if (l is LineJump) l.to
          else if (l is LineNameInput) l.onSuccess
          else if (l is LineChoice)
            for (final o in l.options)
              if (o.jump.isNotEmpty) o.jump,
      };

  test('最初のシーンから、結末の判定までたどり着ける', () {
    // 届かないと、遊んでも永遠に終わらない。
    final seen = <String>{};
    final queue = <String>['act1_sc01'];
    var reachedEnding = false;

    while (queue.isNotEmpty) {
      final id = queue.removeAt(0);
      if (!seen.add(id)) continue;
      final s = scenes[id];
      if (s == null) continue;
      if (s.lines.any((l) => l is LineEnding)) {
        reachedEnding = true;
        break;
      }
      queue.addAll(exitsOf(s));
    }
    expect(reachedEnding, isTrue, reason: '本編をたどっても結末の判定に届かない');
  });

  test('本編のシーンに、たどり着けない孤島が無い', () {
    // エンドのシーンは ending 行から飛ぶので、jump では繋がっていない。
    // それ以外が浮いていたら、書いたのに読まれない話があるということ。
    final endingIds = {for (final e in NoahEnding.values) e.sceneId};
    final seen = <String>{};
    final queue = <String>['act1_sc01'];
    while (queue.isNotEmpty) {
      final id = queue.removeAt(0);
      if (!seen.add(id)) continue;
      final s = scenes[id];
      if (s == null) continue;
      queue.addAll(exitsOf(s));
    }
    final orphans = scenes.keys.where(
        (id) => !seen.contains(id) && !endingIds.contains(id));
    expect(orphans, isEmpty, reason: 'どこからも呼ばれていない: $orphans');
  });

  test('本編に記憶テストが十分ある（分母だけ増えて出題が無い、を防ぐ）', () {
    var count = 0;
    for (final s in scenes.values) {
      count += s.lines.whereType<LineMemTest>().length;
    }
    expect(count, greaterThanOrEqualTo(8),
        reason: '覚える機会が少ないと、記憶率がほとんど上がらない');
  });
}
