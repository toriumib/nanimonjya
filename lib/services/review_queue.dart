import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/person.dart';

/// 🔁 日をまたいだ復習キュー（間隔をあけた再テスト）。
///
/// これまでの復習は**1回のプレイの中だけ**で完結していて、
/// 「今日まちがえた人に、明日もう一度会う」ことができなかった。
/// 長期記憶になったかどうかは、時間をおいて思い出せるかでしか分からないので、
/// まちがえた人を保存しておいて、日をあけて出し直す。
///
/// 間隔の広げ方は素朴な段階式:
///   まちがえた → 1日後 → 3日後 → 7日後 → 14日後 → 30日後 → 卒業
/// 復習で正解すれば次の段階へ、まちがえれば1日後に戻る。
///
/// 端末内の SharedPreferences にJSONで保存する（サーバーなし）。
class ReviewQueue extends ChangeNotifier {
  ReviewQueue._();
  static final ReviewQueue instance = ReviewQueue._();

  static const String _key = 'reviewQueue';

  /// 段階ごとの「次に出すまでの日数」。最後まで来たら卒業して消す。
  static const List<int> intervalsDays = [1, 3, 7, 14, 30];

  /// 溜めすぎると復習が苦行になるので上限を設ける。
  static const int maxItems = 60;

  List<ReviewItem> _items = [];
  bool _loaded = false;

  List<ReviewItem> get items => List.unmodifiable(_items);

  /// 今日が期限（またはそれより前）の項目。
  List<ReviewItem> dueItems({DateTime? now}) {
    final today = _dayNumber(now ?? DateTime.now());
    return _items.where((e) => e.dueDay <= today).toList();
  }

  int dueCount({DateTime? now}) => dueItems(now: now).length;

  /// 経過日数の基準（1970-01-01からの日数）。時刻は見ない。
  static int _dayNumber(DateTime t) =>
      DateTime(t.year, t.month, t.day).difference(DateTime(1970)).inDays;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List<dynamic>;
      _items = [
        for (final e in list)
          if (e is Map<String, dynamic>) ReviewItem.fromJson(e),
      ];
    } catch (e) {
      debugPrint('ReviewQueue load failed: $e');
      _items = [];
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
          _key, jsonEncode([for (final e in _items) e.toJson()]));
    } catch (e) {
      debugPrint('ReviewQueue persist failed: $e');
    }
  }

  /// まちがえた人を登録する（すでにあれば段階を0に戻す）。
  Future<void> recordMiss(Person person, {DateTime? now}) async {
    await load();
    final today = _dayNumber(now ?? DateTime.now());
    final key = ReviewItem.keyOf(person);
    final idx = _items.indexWhere((e) => e.key == key);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(stage: 0, dueDay: today + intervalsDays[0]);
    } else {
      if (_items.length >= maxItems) {
        // 古いものから押し出す（新しく苦戦した人を優先する）
        _items.removeAt(0);
      }
      _items.add(ReviewItem.fromPerson(person, dueDay: today + intervalsDays[0]));
    }
    await _persist();
    notifyListeners();
  }

  /// 復習で正解できた人を次の段階へ送る。最後まで来たら卒業（削除）。
  Future<void> recordSuccess(Person person, {DateTime? now}) async {
    await load();
    final today = _dayNumber(now ?? DateTime.now());
    final key = ReviewItem.keyOf(person);
    final idx = _items.indexWhere((e) => e.key == key);
    if (idx < 0) return;
    final next = _items[idx].stage + 1;
    if (next >= intervalsDays.length) {
      _items.removeAt(idx); // 卒業
    } else {
      _items[idx] =
          _items[idx].copyWith(stage: next, dueDay: today + intervalsDays[next]);
    }
    await _persist();
    notifyListeners();
  }

  /// 期限が来た人を Person に戻して返す（多すぎると重いので上限つき）。
  List<Person> duePeople({int limit = 8, DateTime? now}) {
    final due = dueItems(now: now)..sort((a, b) => a.dueDay.compareTo(b.dueDay));
    return [for (final e in due.take(limit)) e.toPerson()];
  }

  /// テスト用: 中身を空にする。
  @visibleForTesting
  Future<void> clearForTest() async {
    _loaded = true;
    _items = [];
    await _persist();
    notifyListeners();
  }
}

/// 復習キューの1件。人物を復元できるだけの最小限を持つ。
class ReviewItem {
  final String name;
  final String face;
  final FaceKind kind;
  final String where;
  final String company;
  final String title;

  /// 何段階目か（0=まちがえたばかり）。
  final int stage;

  /// 次に出す日（1970-01-01からの日数）。
  final int dueDay;

  const ReviewItem({
    required this.name,
    required this.face,
    required this.kind,
    required this.where,
    required this.company,
    required this.title,
    required this.stage,
    required this.dueDay,
  });

  /// 同じ人かどうかの判定キー（顔＋名前の組み合わせ）。
  String get key => '$face|$name';
  static String keyOf(Person p) => '${p.face}|${p.name}';

  factory ReviewItem.fromPerson(Person p, {required int dueDay}) => ReviewItem(
        name: p.name,
        face: p.face,
        kind: p.kind,
        where: p.where,
        company: p.company,
        title: p.title,
        stage: 0,
        dueDay: dueDay,
      );

  Person toPerson() => Person(
        face: face,
        kind: kind,
        name: name,
        hobby: '',
        where: where,
        company: company,
        title: title,
      );

  ReviewItem copyWith({int? stage, int? dueDay}) => ReviewItem(
        name: name,
        face: face,
        kind: kind,
        where: where,
        company: company,
        title: title,
        stage: stage ?? this.stage,
        dueDay: dueDay ?? this.dueDay,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'face': face,
        'kind': kind.index,
        'where': where,
        'company': company,
        'title': title,
        'stage': stage,
        'dueDay': dueDay,
      };

  factory ReviewItem.fromJson(Map<String, dynamic> j) => ReviewItem(
        name: (j['name'] as String?) ?? '',
        face: (j['face'] as String?) ?? '',
        kind: FaceKind
            .values[((j['kind'] as int?) ?? 0).clamp(0, FaceKind.values.length - 1)],
        where: (j['where'] as String?) ?? '',
        company: (j['company'] as String?) ?? '',
        title: (j['title'] as String?) ?? '',
        stage: (j['stage'] as int?) ?? 0,
        dueDay: (j['dueDay'] as int?) ?? 0,
      );
}
