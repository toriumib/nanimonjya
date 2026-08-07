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

    test('横並びならビターエンド（相手は決まらない）', () {
      final r = resolveNoahEnding({'hoshino': 4, 'kiryu': 4, 'iwao': 4});
      expect(r.ending, NoahEnding.bitter);
      expect(r.partner, isNull);
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

  group('世界線（覚えている項目でエンドが変わる）', () {
    Map<String, Set<NoahField>> full(List<NoahCharacter> cast) => {
          for (final c in cast) c.id: NoahField.values.toSet(),
        };

    test('項目を覚えるほどダイバージェンスが上がる', () {
      final cast = kNoahCast.take(4).toList();
      final askable = cast.length * (NoahField.values.length + 1);
      expect(noahDivergence({}, askable), 0);
      expect(noahDivergence({cast[0].id: {NoahField.name}}, askable),
          closeTo(1 / askable, 1e-9));
    });

    test('出題が無くても落ちない／1.0を超えない', () {
      expect(noahDivergence({'a': {NoahField.name}}, 0), 0);
      expect(noahDivergence(full(kNoahCast), 1), 1.0);
    });

    test('世界線の呼び名が段階で変わる', () {
      expect(noahWorldLineJa(0.0), 'β');
      expect(noahWorldLineJa(0.29), 'β');
      expect(noahWorldLineJa(0.30), 'α');
      expect(noahWorldLineJa(0.59), 'α');
      expect(noahWorldLineJa(0.60), 'γ');
      expect(noahWorldLineJa(0.99), 'γ');
      expect(noahWorldLineJa(1.0), 'Ω');
    });

    test('六桁で表示する（Steins;Gate 風）', () {
      expect(noahDivergenceLabel(0.5714285), '0.571429');
      expect(noahDivergenceLabel(1), '1.000000');
    });

    test('ダイバージェンス1.0で真エンドが開く', () {
      final r = resolveNoahEnding({'hoshino': 4, 'kiryu': 4}, divergence: 1.0);
      expect(r.ending, NoahEnding.trueEnd);
      expect(r.partner?.id, 'hoshino'); // 相手は好感度1位から決まる
    });

    test('真エンドは好感度より優先される（横並びでも開く）', () {
      // 「好きだから覚えている」ではなく「覚えているから会える」
      final flat = resolveNoahEnding({'a': 5, 'b': 5, 'c': 5});
      expect(flat.ending, NoahEnding.bitter);
      final same = resolveNoahEnding({'a': 5, 'b': 5, 'c': 5}, divergence: 1.0);
      expect(same.ending, NoahEnding.trueEnd);
    });

    test('一項目でも欠ければ真エンドにならない', () {
      final r = resolveNoahEnding({'hoshino': 9}, divergence: 0.999999);
      expect(r.ending, isNot(NoahEnding.trueEnd));
    });

    test('ダイバージェンスを渡さなければ従来どおり', () {
      expect(resolveNoahEnding({'hoshino': 8, 'kiryu': 3}).ending,
          NoahEnding.happy);
    });
  });

  group('転送権（もつれ対）', () {
    test('三対だけ積んでいる', () {
      // もつれは局所操作では増やせない＝地球で作ったぶんが全部、
      // という物理の縛りから来ている数字。補充できる実装に変えないこと
      expect(kNoahEntangledPairs, 3);
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

  group('船内の小さな謎', () {
    test('8人ぜんいんに謎がひとつずつある', () {
      expect(kNoahMysteries.length, kNoahCast.length);
      expect(kNoahMysteries.map((m) => m.charaId).toSet().length,
          kNoahCast.length);
      for (final m in kNoahMysteries) {
        expect(noahCharacterById(m.charaId), isNotNull, reason: m.charaId);
        expect(m.title, isNotEmpty, reason: m.charaId);
        expect(m.scene, isNotEmpty, reason: m.charaId);
        expect(m.answer, isNotEmpty, reason: m.charaId);
      }
    });

    test('正解を含む3択になり、選択肢が重複しない', () {
      final cast = kNoahCast.take(4).toList();
      final qs = buildNoahMysteries(cast: cast, random: Random(7));
      expect(qs, isNotEmpty);
      for (final q in qs) {
        expect(q.choices.length, 3);
        expect(q.choices.map((c) => c.id).toSet().length, 3);
        expect(q.choices.map((c) => c.id), contains(q.culprit.id));
      }
    });

    test('選択肢は、その周回に出てきた人だけから作る', () {
      // 会っていない人が混ざると、消去法で当たってしまって謎にならない
      final cast = kNoahCast.take(4).toList();
      final ids = cast.map((c) => c.id).toSet();
      for (final q in buildNoahMysteries(cast: cast, random: Random(8))) {
        for (final c in q.choices) {
          expect(ids, contains(c.id));
        }
      }
    });

    test('同じ人の謎が周回内で二度出ない', () {
      final cast = kNoahCast.take(4).toList();
      final qs = buildNoahMysteries(cast: cast, random: Random(9), count: 4);
      expect(qs.map((q) => q.culprit.id).toSet().length, qs.length);
    });

    test('キャストが少なすぎるときは謎を出さない（3択が作れない）', () {
      expect(buildNoahMysteries(cast: kNoahCast.take(1).toList()), isEmpty);
      expect(buildNoahMysteries(cast: const []), isEmpty);
    });

    test('要求した数より候補が少なければ、あるぶんだけ返す', () {
      final qs = buildNoahMysteries(
          cast: kNoahCast.take(3).toList(), random: Random(10), count: 9);
      expect(qs.length, 3);
    });

    test('正誤の判定', () {
      final cast = kNoahCast.take(4).toList();
      final q = buildNoahMysteries(cast: cast, random: Random(11)).first;
      final other = cast.firstWhere((c) => c.id != q.culprit.id);
      expect(q.isCorrect(q.culprit), isTrue);
      expect(q.isCorrect(other), isFalse);
    });

    test('IDから謎を引ける／知らないIDは null', () {
      expect(noahMysteryFor('shirakawa'), isNotNull);
      expect(noahMysteryFor('nobody'), isNull);
    });

    test('解けたとき・外したときのセリフが全員ぶん出る', () {
      for (final c in kNoahCast) {
        expect(noahMysteryHitLineJa(c), isNotEmpty, reason: c.id);
      }
      final line = noahMysteryMissLineJa(kNoahCast[0], kNoahCast[1]);
      expect(line, contains(kNoahCast[0].name)); // 選んだ人の名前を出す
    });
  });

  group('物語の章', () {
    test('地の文の章がどれも空でない（空だと画面が進まなくなる）', () {
      final chapters = <String, List<NoahLine>>{
        '序章': kNoahPrologue,
        '定員': kNoahCapacityScene,
        'なぜ名前': kNoahWhyNames,
        '名刺の前': kNoahBeforeMeeting,
        '前夜': kNoahBeforeSleep,
        '目覚め': kNoahAwake,
        '忘れた': kNoahForgot,
        '謎の前': kNoahBeforeMystery,
        '航行中': kNoahMidVoyage,
        '減速': kNoahClimax,
        '意識の淘汰': kNoahConsciousness,
        '着陸前': kNoahBeforeResult,
      };
      chapters.forEach((name, lines) {
        expect(lines, isNotEmpty, reason: name);
        for (final l in lines) {
          expect(l.text, isNotEmpty, reason: name);
        }
      });
    });

    test('所長の名前は、出す場所を絞ってある', () {
      // どこでも出していると、忘れる場面も思い出す場面も効かなくなる。
      // 名乗り（定員の章）と、最後に呼ぶところ（着陸前）の2か所だけ。
      final chapters = {
        '序章': kNoahPrologue,
        '定員': kNoahCapacityScene,
        'なぜ名前': kNoahWhyNames,
        '忘れた': kNoahForgot,
        '謎の前': kNoahBeforeMystery,
        '航行中': kNoahMidVoyage,
        '減速': kNoahClimax,
        '意識の淘汰': kNoahConsciousness,
        '着陸前': kNoahBeforeResult,
      };
      final appearsIn = <String>[];
      chapters.forEach((name, lines) {
        if (lines.any((l) => l.text.contains(kNoahDirectorName))) {
          appearsIn.add(name);
        }
      });
      expect(appearsIn, ['定員', '着陸前']);
    });

    test('意識の決着は、量子論の向きを保つ', () {
      // 「残った三理論はどれも十一回の死に行き着き、量子論だけが連続を言える」
      // という向きが、本作の「誰も死なない」を支えている。緩めたら落とす。
      final body = kNoahConsciousness.map((l) => l.text).join();
      expect(body, contains('複製できません'));
      expect(body, contains('一度も死んでいない'));
      expect(body, contains('引っ越し'));
      // コピー可能＝バックアップが残る、という書き方に戻っていないこと
      expect(body.contains('控えは残らない'), isTrue);
    });

    test('落とした名前を、最後に必ず回収する', () {
      // 忘れる章があるのに拾う章が無い、という壊れ方をしないように
      expect(kNoahForgot.any((l) => l.text.contains('名前だけが、無い')), isTrue);
      expect(
          kNoahBeforeResult.any((l) => l.text.contains(kNoahDirectorName)),
          isTrue);
    });

    test('所長のセリフには話し手の名前が入っている', () {
      for (final l in [...kNoahPrologue, ...kNoahCapacityScene]) {
        if (l.voice == NoahVoice.director) {
          expect(l.who, isNotEmpty, reason: l.text);
        }
      }
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
