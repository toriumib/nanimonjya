import 'package:flutter_test/flutter_test.dart';

import 'package:project_noa/models/noah_field.dart';
import 'package:project_noa/systems/ending.dart';

/// STORY 8章。**誰も死なない。誰も嫌な思いをしない。**
/// 判定の順番を間違えると、覚えたのに見守りエンドになる、
/// 誰とも話していないのに同窓会になる、といった食い違いが出る。
void main() {
  NoahCharacter c(String id) => NoahCharacter(
        id: id,
        name: id,
        reading: '',
        affiliation: '',
        hobby: '',
        commId: '',
        school: '',
        regret: '',
        cast: 1,
        romance: true,
        color: 0,
        emoji: '🙂',
      );

  final cast = NoahCast([c('a'), c('b'), c('c'), c('d')]);

  EndingResult resolve(Map<String, int> aff, {double rate = 0.5}) =>
      resolveEnding(affection: aff, cast: cast, memoryRate: rate);

  test('記憶率100%なら、好感度に関係なく真エンド', () {
    final r = resolve({'a': 99}, rate: 1.0);
    expect(r.ending, NoahEnding.trueRoute,
        reason: '17人全員を覚えきった人には、必ず呼名を見せる');
  });

  test('覚えた総量が少なすぎると見守りエンド', () {
    final r = resolve({'a': 2, 'b': 1});
    expect(r.ending, NoahEnding.lonely);
    expect(r.partner, isNull);
  });

  test('誰とも距離が縮まらなかった場合も見守りエンド', () {
    expect(resolve(const {}).ending, NoahEnding.lonely);
  });

  test('1位がはっきりリードしていればハッピー', () {
    final r = resolve({'a': 8, 'b': 3, 'c': 1});
    expect(r.ending, NoahEnding.happy);
    expect(r.partner?.id, 'a');
  });

  test('僅差ではハッピーにならない（同窓会）', () {
    expect(resolve({'a': 5, 'b': 4}).ending, NoahEnding.bitter);
  });

  test('1位が2人で並ぶと大家族。相手が両方入る', () {
    final r = resolve({'a': 6, 'b': 6, 'c': 1});
    expect(r.ending, NoahEnding.harem);
    expect(r.partners.map((e) => e.id).toList(), containsAll(['a', 'b']));
  });

  test('出会った全員が同率なら同窓会', () {
    final r = resolve({'a': 4, 'b': 4, 'c': 4});
    expect(r.ending, NoahEnding.bitter);
    expect(r.partner, isNull);
  });

  test('好感度0の人は「同率1位」に数えない', () {
    // 0の人まで数えると、1人としか話していない周回が
    // 「全員同率」に化けて同窓会になってしまう。
    final r = resolve({'a': 9, 'b': 0, 'c': 0});
    expect(r.ending, NoahEnding.happy);
    expect(r.partner?.id, 'a');
  });

  test('総好感度は結果に持ち回る', () {
    expect(resolve({'a': 8, 'b': 3}).totalAffection, 11);
  });

  test('結末ごとに飛び先のシーンIDが決まっている', () {
    expect(NoahEnding.happy.sceneId, 'ending_happy');
    expect(NoahEnding.harem.sceneId, 'ending_harem');
    expect(NoahEnding.bitter.sceneId, 'ending_bitter');
    expect(NoahEnding.lonely.sceneId, 'ending_lonely');
    expect(NoahEnding.trueRoute.sceneId, 'ending_true');
  });
}
