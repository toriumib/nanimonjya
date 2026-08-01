import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nanimonjya/services/memory_stats.dart';

/// 📊 成績レポートの3指標（速さ・正確性・定着率）の集計テスト。
///
/// とくに定着率は「初対面の1回目は数えない」のが要点なので、
/// そこが崩れていないかをここで守る。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final stats = MemoryStats.instance;
  const key = 'face.jpg|やまだ|name';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await stats.clearForTest();
  });

  test('記録が無ければ全部 null / 空', () {
    expect(stats.isEmpty, isTrue);
    expect(stats.accuracyPct(null), isNull);
    expect(stats.avgReactionMs(null), isNull);
    expect(stats.retentionPct(null), isNull);
  });

  test('正確性は全回答、速さは計測できた回答だけで平均する', () {
    stats.record(
        mode: StatMode.nameCall, itemKey: 'a', correct: true, reactionMs: 1000);
    stats.record(
        mode: StatMode.nameCall, itemKey: 'b', correct: false, reactionMs: 3000);
    // 反応時間を計測していない画面（0）は速さの平均に入れない
    stats.record(mode: StatMode.nameCall, itemKey: 'c', correct: true);

    expect(stats.accuracyPct(StatMode.nameCall), 66); // 2/3
    expect(stats.avgReactionMs(StatMode.nameCall), 2000); // (1000+3000)/2
  });

  test('出会いを記録した人への想起は定着率に数える', () {
    stats.recordMeeting(itemKey: key); // 命名・おぼえタイム＝出会い
    stats.record(mode: StatMode.nameCall, itemKey: key, correct: true);

    // 命名で一度会っているので、その後の想起は2回目の遭遇にあたる
    expect(stats.repeatAnswers(StatMode.nameCall), 1);
    expect(stats.retentionPct(StatMode.nameCall), 100);
    expect(stats.accuracyPct(StatMode.nameCall), 100);
  });

  test('出会いを記録していない人の初回は定着率に入らない', () {
    // カスタム名簿など、出会いフェーズを通らずいきなり出題される場合。
    // 当てずっぽうが混ざるので分母から外す。
    stats.record(mode: StatMode.nameCall, itemKey: key, correct: true);

    expect(stats.repeatAnswers(StatMode.nameCall), 0);
    expect(stats.retentionPct(StatMode.nameCall), isNull);
    expect(stats.accuracyPct(StatMode.nameCall), 100);
  });

  test('出会いのあとの想起はすべて定着率の分母に入る', () {
    stats.recordMeeting(itemKey: key);
    stats.record(mode: StatMode.nameCall, itemKey: key, correct: false);
    stats.record(mode: StatMode.nameCall, itemKey: key, correct: true);
    stats.record(mode: StatMode.nameCall, itemKey: key, correct: false);

    expect(stats.repeatAnswers(StatMode.nameCall), 3);
    expect(stats.retentionPct(StatMode.nameCall), 33); // 1/3
    expect(stats.accuracyPct(StatMode.nameCall), 33);
  });

  test('日をまたいで会えば、1回目の想起でも定着率に数える', () {
    final day1 = DateTime(2026, 8, 1);
    final day2 = DateTime(2026, 8, 3);
    stats.recordMeeting(itemKey: key, now: day1);
    stats.record(
        mode: StatMode.businessCard, itemKey: key, correct: true, now: day2);

    expect(stats.repeatAnswers(StatMode.businessCard), 1);
    expect(stats.retentionPct(StatMode.businessCard), 100);
  });

  test('モード別と全体を分けて集計する', () {
    stats.record(mode: StatMode.cpu, itemKey: 'x', correct: true);
    stats.record(mode: StatMode.nameCall, itemKey: 'y', correct: false);

    expect(stats.accuracyPct(StatMode.cpu), 100);
    expect(stats.accuracyPct(StatMode.nameCall), 0);
    expect(stats.accuracyPct(null), 50); // 全体
    expect(stats.totalAnswers(null), 2);
  });

  test('おぼえた人数は、会ったあとに正解できた人を数える', () {
    stats.recordMeeting(itemKey: 'p1');
    stats.record(mode: StatMode.cpu, itemKey: 'p1', correct: true); // 想起できた
    stats.recordMeeting(itemKey: 'p2');
    stats.record(mode: StatMode.cpu, itemKey: 'p2', correct: false); // 思い出せず
    // 出会いを記録していない人は、当たっても「おぼえた」に数えない
    stats.record(mode: StatMode.cpu, itemKey: 'p3', correct: true);

    expect(stats.retainedPeople, 1);
  });

  test('保存して読み直しても集計が残る', () async {
    stats.recordMeeting(itemKey: key);
    stats.record(
        mode: StatMode.cpu, itemKey: key, correct: true, reactionMs: 1200);
    stats.record(
        mode: StatMode.cpu, itemKey: key, correct: true, reactionMs: 800);
    await stats.finishSession(StatMode.cpu);

    expect(stats.sessions(StatMode.cpu), 1);
    expect(stats.retentionPct(StatMode.cpu), 100);
    expect(stats.avgReactionMs(StatMode.cpu), 1000);
  });
}
