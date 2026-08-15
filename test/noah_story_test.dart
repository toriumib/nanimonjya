import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:nanimonjya/models/avatar.dart';
import 'package:nanimonjya/models/noah_story.dart';

/// 🚀 ストーリーモード「プロジェクト・ノア」のロジック。
///
/// 3択の作り方と、結末の判定を固定する。
/// とくに「まちがいの選択肢は他のキャラの本物のデータ」は、
/// 崩れると4択が実質2択になってしまう要点なのでテストで守る。
void main() {
  group('キャスト', () {
    test('8人いて、IDが重複していない', () {
      expect(kNoahCast.length, 8);
      expect(kNoahCast.map((c) => c.id).toSet().length, 8);
    });

    test('出題に使う項目が全員そろっている（空欄だと3択が作れない）', () {
      for (final c in kNoahCast) {
        for (final f in NoahField.values) {
          expect(f.valueOf(c), isNotEmpty, reason: '${c.id} / ${f.labelJa}');
        }
      }
    });

    test('IDから引ける／知らないIDは null', () {
      expect(noahCharacterById('hoshino')?.name, '星野 未来');
      expect(noahCharacterById('nobody'), isNull);
    });
  });

  group('3択の作り方', () {
    test('正解を必ず含み、重複のない3択になる', () {
      final rng = Random(1);
      for (final f in NoahField.values) {
        final q = buildNoahQuestion(
          target: kNoahCast.first,
          field: f,
          pool: kNoahCast,
          random: rng,
        );
        expect(q.choices.length, 3, reason: f.labelJa);
        expect(q.choices.toSet().length, 3, reason: f.labelJa);
        expect(q.choices, contains(q.answer), reason: f.labelJa);
      }
    });

    test('まちがいの選択肢は、すべて別のキャラの本物のデータ', () {
      final q = buildNoahQuestion(
        target: kNoahCast[0],
        field: NoahField.hobby,
        pool: kNoahCast,
        random: Random(2),
      );
      final real = kNoahCast.map((c) => c.hobby).toSet();
      for (final c in q.choices) {
        expect(real, contains(c)); // 適当な造語が混ざっていない
      }
    });

    test('自分自身は、まちがいの選択肢にならない', () {
      final target = kNoahCast[3];
      final q = buildNoahQuestion(
        target: target,
        field: NoahField.name,
        pool: kNoahCast,
        random: Random(3),
      );
      expect(q.choices.where((c) => c == target.name).length, 1);
    });

    test('出会った人が少なくても、全キャストから補って3択にする', () {
      final q = buildNoahQuestion(
        target: kNoahCast[0],
        field: NoahField.commId,
        pool: const [], // まだ誰にも会っていない
        random: Random(4),
      );
      expect(q.choices.length, 3);
      expect(q.choices, contains(kNoahCast[0].commId));
    });

    test('正誤の判定', () {
      final q = buildNoahQuestion(
        target: kNoahCast[2],
        field: NoahField.name,
        pool: kNoahCast,
        random: Random(5),
      );
      expect(q.isCorrect(kNoahCast[2].name), isTrue);
      expect(q.isCorrect('だれかの名前'), isFalse);
    });
  });

  group('結末の判定', () {
    test('誰の名前も覚えられなければ孤独エンド', () {
      final r = resolveNoahEnding({'a': 1, 'b': 0, 'c': 2});
      expect(r.ending, NoahEnding.lonely);
      expect(r.partner, isNull);
    });

    test('1位がはっきりリードしていればハッピーエンド', () {
      final r = resolveNoahEnding({'hoshino': 8, 'kiryu': 3, 'iwao': 1});
      expect(r.ending, NoahEnding.happy);
      expect(r.partner?.id, 'hoshino');
    });

    test('全員が横並びならビターエンド（相手は決まらない）', () {
      final r = resolveNoahEnding({'hoshino': 4, 'kiryu': 4, 'iwao': 4});
      expect(r.ending, NoahEnding.bitter);
      expect(r.partner, isNull);
    });

    test('1位が2人以上で並んでいる（全員ではない）と大家族エンド', () {
      final r = resolveNoahEnding({'hoshino': 6, 'kiryu': 6, 'iwao': 1});
      expect(r.ending, NoahEnding.harem);
      expect(r.partner, isNull);
    });

    test('全員が同着なら、2人だけでも大家族エンドにはならずビター', () {
      final r = resolveNoahEnding({'hoshino': 3, 'kiryu': 3});
      expect(r.ending, NoahEnding.bitter);
    });

    test('わずかなリードではハッピーにならない', () {
      final r = resolveNoahEnding({'hoshino': 5, 'kiryu': 4});
      expect(r.ending, NoahEnding.bitter);
    });

    test('しきい値ちょうどは孤独にならない', () {
      final r = resolveNoahEnding({'hoshino': kNoahLonelyThreshold});
      expect(r.ending, isNot(NoahEnding.lonely));
    });

    test('総好感度は結果に持ち回る', () {
      final r = resolveNoahEnding({'a': 5, 'b': 4});
      expect(r.totalAffection, 9);
    });
  });

  group('乗船定員（覚えるほど助かる人が増える）', () {
    test('全問正解で全員ぶんに届く', () {
      expect(noahCapacityFor(12, 12), kNoahCapacitySteps.last);
      expect(noahCapacityFor(12, 12), 500);
    });

    test('思い出せないと最初の計画のまま', () {
      expect(noahCapacityFor(0, 12), kNoahCapacitySteps.first);
      expect(noahCapacityFor(0, 12), 12);
    });

    test('思い出した数に応じて段階的に増える', () {
      final steps = [
        noahCapacityFor(0, 12),
        noahCapacityFor(4, 12),
        noahCapacityFor(8, 12),
        noahCapacityFor(12, 12),
      ];
      for (var i = 1; i < steps.length; i++) {
        expect(steps[i], greaterThan(steps[i - 1]));
      }
    });

    test('出題が無くても落ちない（0除算をしない）', () {
      expect(noahCapacityFor(0, 0), kNoahCapacitySteps.first);
    });

    test('段階の見出しが人数と同じ数だけある', () {
      expect(kNoahCapacityReasons.length, kNoahCapacitySteps.length);
      expect(noahCapacityStepIndex(12, 12), kNoahCapacitySteps.length - 1);
      expect(noahCapacityStepIndex(0, 12), 0);
    });
  });

  group('覚え方のメモ', () {
    test('本文と出典がそろっている（出典なしで断定しない方針）', () {
      expect(kNoahNotes, isNotEmpty);
      for (final n in kNoahNotes) {
        expect(n.title, isNotEmpty);
        expect(n.body, isNotEmpty);
        expect(n.source, isNotEmpty, reason: n.title);
      }
    });

    test('効果を断定する書き方をしていない', () {
      // 「必ず」「証明された」等の断定は薬機法・Playポリシーの観点で避ける
      const banned = ['必ず', '確実に', '証明された', '治る', '治療'];
      for (final n in kNoahNotes) {
        for (final w in banned) {
          expect(n.body.contains(w), isFalse, reason: '${n.title} / $w');
        }
      }
    });
  });

  group('セリフ', () {
    test('全員ぶんの挨拶・正解・不正解のセリフが出る', () {
      for (final c in kNoahCast) {
        expect(noahGreetLineJa(c), isNotEmpty, reason: c.id);
        expect(noahHitLineJa(c), isNotEmpty, reason: c.id);
        expect(noahMissLineJa(c, 'だれかの名前'), isNotEmpty, reason: c.id);
      }
    });

    test('正解のセリフはキャラごとに違う（使い回しをしない）', () {
      final lines = kNoahCast.map(noahHitLineJa).toSet();
      expect(lines.length, kNoahCast.length);
    });

    test('出題のセリフは項目ごとに用意されている', () {
      for (final f in NoahField.values) {
        expect(noahAskLineJa(kNoahCast.first, f, true), isNotEmpty,
            reason: f.labelJa);
        expect(noahAskLineJa(kNoahCast.first, f, false), isNotEmpty,
            reason: f.labelJa);
      }
    });

    test('初回の再会だけ「覚えてる？」で始まる', () {
      final first = noahAskLineJa(kNoahCast.first, NoahField.name, true);
      final later = noahAskLineJa(kNoahCast.first, NoahField.name, false);
      expect(first, contains('覚えてる'));
      expect(first, isNot(later));
    });

    test('まちがえたときは、選んだ答えを台詞に含める', () {
      final line = noahMissLineJa(kNoahCast.first, '星野 未来');
      expect(line, contains('星野 未来'));
    });
  });

  group('立ち絵（アバター）', () {
    test('全員に顔がある', () {
      for (final c in kNoahCast) {
        expect(c.avatar.encode(), isNotEmpty, reason: c.id);
      }
    });

    test('全員の顔が違う（見分けがつく）', () {
      final faces = kNoahCast.map((c) => c.avatar.encode()).toSet();
      expect(faces.length, kNoahCast.length);
    });

    test('顔の値が範囲内（描画で落ちない）', () {
      for (final c in kNoahCast) {
        final a = c.avatar;
        expect(a.skin, inInclusiveRange(0, Avatar.skinCount - 1), reason: c.id);
        expect(a.hair, inInclusiveRange(0, Avatar.hairCount - 1), reason: c.id);
        expect(a.glasses, inInclusiveRange(0, Avatar.glassesCount - 1),
            reason: c.id);
        expect(a.beard, inInclusiveRange(0, Avatar.beardCount - 1),
            reason: c.id);
        expect(a.mole, inInclusiveRange(0, Avatar.moleCount - 1), reason: c.id);
      }
    });

    test('保存して読み直しても同じ顔になる', () {
      for (final c in kNoahCast) {
        expect(Avatar.decode(c.avatar.encode()).encode(), c.avatar.encode(),
            reason: c.id);
      }
    });
  });
}
