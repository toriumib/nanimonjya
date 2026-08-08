import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nanimonjya/services/player_profile.dart';
import 'package:nanimonjya/widgets/guide_talk.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🗣 ホームの声かけが「いま言うべきこと」を選べているか。
///
/// ここが外れる（復習どきの人がいるのに雑談する等）と、
/// 声かけそのものが読み飛ばされるようになる。順番を固定しておく。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlayerProfile p;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    p = PlayerProfile.instance;
    // シングルトンなので、テストごとに見る値を直接そろえる
    p.totalGames = 5;
    p.dailyStreak = 0;
    p.weeklyLearned = 0;
    p.dailyClaimedToday = true; // 「今日のごほうび」の声かけを黙らせる
  });

  String say({int due = 0, int hour = 14}) => pickGuideLine(
        profile: p,
        dueCount: due,
        hour: hour,
        ja: true,
        random: Random(1),
      ).text;

  test('まだ1回も遊んでいない人にも、遊びかたの説明を重ねない', () {
    // 以前はここで「はじめまして！まずは1ゲームだけ〜」を出していたが、
    // はじめて開いた人にいちばん見せたいのは遊ぶボタンなので取りやめた。
    // 遊びかたはチュートリアルとルールに任せる。
    p.totalGames = 0;
    final line = say(due: 3);
    expect(line, isNot(contains('1ゲーム')));
    expect(line, isNotEmpty, reason: '何も言わないのではなく、別の一言にする');
  });

  test('復習どきの人がいれば、それを最優先で言う', () {
    p.dailyStreak = 10; // ほめる材料があっても
    expect(say(due: 3), contains('3人'));
  });

  test('復習が無ければ、続いている日数をほめる', () {
    p.dailyStreak = 5;
    expect(say(), contains('5日'));
  });

  test('続いていなければ、今週の成果を返す', () {
    p.weeklyLearned = 7;
    expect(say(), contains('7人'));
  });

  test('材料が何も無いときは、時間帯に合う一言になる', () {
    expect(say(hour: 7), contains('朝'));
    expect(say(hour: 23), contains('寝る'));
  });

  test('昼で材料が無いときも、必ず何か言う（空にならない）', () {
    expect(say(hour: 14), isNotEmpty);
  });

  test('話し手は必ずナナちゃんかはなちゃん', () {
    final line = pickGuideLine(
        profile: p, dueCount: 0, hour: 14, ja: true, random: Random(1));
    expect(['ナナちゃん', 'はなちゃん'], contains(line.speaker));
    expect(line.asset, contains('supporters/'));
  });
}
