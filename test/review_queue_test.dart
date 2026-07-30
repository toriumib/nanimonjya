import 'package:flutter_test/flutter_test.dart';
import 'package:nanimonjya/models/person.dart';
import 'package:nanimonjya/services/review_queue.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 日をまたいだ復習キューのテスト。
/// 「いつ出し直すか」の日付計算と、正解で間隔が広がることを確認する。
void main() {
  const alice = Person(
      face: 'assets/images/char1.jpg',
      kind: FaceKind.asset,
      name: '佐藤さん',
      hobby: '');
  const bob = Person(
      face: 'assets/images/char2.jpg',
      kind: FaceKind.asset,
      name: '鈴木さん',
      hobby: '');

  final today = DateTime(2026, 7, 30);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ReviewQueue.instance.clearForTest();
  });

  test('まちがえた人は翌日に出るよう登録される', () async {
    await ReviewQueue.instance.recordMiss(alice, now: today);
    // 当日はまだ出ない
    expect(ReviewQueue.instance.dueCount(now: today), 0);
    // 翌日から出る
    expect(
        ReviewQueue.instance
            .dueCount(now: today.add(const Duration(days: 1))),
        1);
  });

  test('復習で正解すると次は3日後になる', () async {
    await ReviewQueue.instance.recordMiss(alice, now: today);
    final tomorrow = today.add(const Duration(days: 1));
    await ReviewQueue.instance.recordSuccess(alice, now: tomorrow);
    // 正解した直後は出ない
    expect(ReviewQueue.instance.dueCount(now: tomorrow), 0);
    // 2日後もまだ（間隔は3日）
    expect(
        ReviewQueue.instance
            .dueCount(now: tomorrow.add(const Duration(days: 2))),
        0);
    // 3日後に出る
    expect(
        ReviewQueue.instance
            .dueCount(now: tomorrow.add(const Duration(days: 3))),
        1);
  });

  test('最後の段階まで正解すると卒業してキューから消える', () async {
    await ReviewQueue.instance.recordMiss(alice, now: today);
    var d = today;
    // 段階の数だけ正解を重ねる
    for (var i = 0; i < ReviewQueue.intervalsDays.length; i++) {
      d = d.add(Duration(days: ReviewQueue.intervalsDays[i]));
      await ReviewQueue.instance.recordSuccess(alice, now: d);
    }
    expect(ReviewQueue.instance.items, isEmpty);
  });

  test('同じ人をまちがえ直すと段階が0に戻る', () async {
    await ReviewQueue.instance.recordMiss(alice, now: today);
    final tomorrow = today.add(const Duration(days: 1));
    await ReviewQueue.instance.recordSuccess(alice, now: tomorrow);
    expect(ReviewQueue.instance.items.first.stage, 1);
    await ReviewQueue.instance.recordMiss(alice, now: tomorrow);
    expect(ReviewQueue.instance.items.first.stage, 0);
    // 重複登録されない
    expect(ReviewQueue.instance.items.length, 1);
  });

  test('キューに無い人の正解は何も起こさない', () async {
    await ReviewQueue.instance.recordSuccess(bob, now: today);
    expect(ReviewQueue.instance.items, isEmpty);
  });

  test('duePeople は Person として復元でき、上限を守る', () async {
    await ReviewQueue.instance.recordMiss(alice, now: today);
    await ReviewQueue.instance.recordMiss(bob, now: today);
    final tomorrow = today.add(const Duration(days: 1));
    final people = ReviewQueue.instance.duePeople(limit: 1, now: tomorrow);
    expect(people.length, 1);
    expect(people.first.kind, FaceKind.asset);
    expect(people.first.name, isNotEmpty);
  });

  test('保存した内容がJSONから復元できる', () async {
    await ReviewQueue.instance.recordMiss(alice, now: today);
    final item = ReviewQueue.instance.items.first;
    final restored = ReviewItem.fromJson(item.toJson());
    expect(restored.name, item.name);
    expect(restored.face, item.face);
    expect(restored.kind, item.kind);
    expect(restored.dueDay, item.dueDay);
    expect(restored.stage, item.stage);
  });
}
