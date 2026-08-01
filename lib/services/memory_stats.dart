import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 成績レポートの対象モード。
enum StatMode {
  /// CPU対戦（ペアさがしのCPU戦）
  cpu,

  /// なまえコール
  nameCall,

  /// 名刺記憶（ビジネス特訓の思い出しトレーニング）
  businessCard,
}

extension StatModeLabel on StatMode {
  String get id => switch (this) {
        StatMode.cpu => 'cpu',
        StatMode.nameCall => 'nameCall',
        StatMode.businessCard => 'businessCard',
      };

  String get labelJa => switch (this) {
        StatMode.cpu => 'CPU対戦',
        StatMode.nameCall => 'なまえコール',
        StatMode.businessCard => '名刺記憶',
      };

  String get emoji => switch (this) {
        StatMode.cpu => '🤖',
        StatMode.nameCall => '📣',
        StatMode.businessCard => '📇',
      };

  static StatMode? fromId(String id) {
    for (final m in StatMode.values) {
      if (m.id == id) return m;
    }
    return null;
  }
}

/// 🧠 成績レポートのもとになる集計。
///
/// 速さ（平均回答時間）と正確性（正答率）だけだと反射神経の記録になってしまう。
/// このアプリの目的は「人の名前を覚える」ことなので、
/// **2回目以降に会ったときに答えられたか＝定着率**を3つ目の指標として持つ。
/// 1回目は当てずっぽうでも当たるが、2回目に答えられたなら覚えた証拠になる。
///
/// 端末内の SharedPreferences にJSONで保存する（サーバーへは送らない）。
class MemoryStats extends ChangeNotifier {
  MemoryStats._();
  static final MemoryStats instance = MemoryStats._();

  static const String _key = 'memoryStats_v1';

  /// 保持する人物数の上限。超えたら最後に会ったのが古い順に捨てる。
  static const int maxItems = 400;

  final Map<String, ItemStat> _items = {};
  final Map<String, ModeStat> _modes = {};
  bool _loaded = false;

  Map<String, ItemStat> get items => Map.unmodifiable(_items);

  /// 記録がまだ1件も無いか（レポートの空状態の判定に使う）。
  bool get isEmpty => totalAnswers(null) == 0;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw == null || raw.isEmpty) return;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final items = (j['items'] as Map<String, dynamic>?) ?? {};
      for (final e in items.entries) {
        _items[e.key] = ItemStat.fromJson(e.value as Map<String, dynamic>);
      }
      final modes = (j['modes'] as Map<String, dynamic>?) ?? {};
      for (final e in modes.entries) {
        _modes[e.key] = ModeStat.fromJson(e.value as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('MemoryStats load failed: $e');
      _items.clear();
      _modes.clear();
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        _key,
        jsonEncode({
          'items': {for (final e in _items.entries) e.key: e.value.toJson()},
          'modes': {for (final e in _modes.entries) e.key: e.value.toJson()},
        }),
      );
    } catch (e) {
      debugPrint('MemoryStats persist failed: $e');
    }
  }

  /// 同じ人かどうかの判定キー。顔＋名前で1人とみなす（ReviewQueue と同じ考え方）。
  /// 出題項目（名前／会社名など）ごとに別で数えたいときは [field] を渡す。
  static String keyOf({
    required String face,
    required String name,
    String field = 'name',
  }) =>
      '$face|$name|$field';

  /// 「この人に会った」ことだけを記録する（命名・おぼえタイム・名刺交換など）。
  ///
  /// 定着率は**2回目以降に答えられたか**で数える。出会いを記録しておかないと、
  /// 初対面のあとの想起が「1回目」に数えられてしまい、
  /// 覚えられているのに定着率がいつまでも0のままになる。
  void recordMeeting({required String itemKey, DateTime? now}) {
    final day = _dayNumber(now ?? DateTime.now());
    _items[itemKey] = (_items[itemKey] ?? const ItemStat()).addMeeting(day);
  }

  /// 1問ぶんの回答を記録する。
  ///
  /// [reactionMs] は0以下なら速さの集計に入れない（計測していない画面のため）。
  /// 保存はまとめて行うので、1セッションの最後に [flush] を呼ぶこと。
  void record({
    required StatMode mode,
    required String itemKey,
    required bool correct,
    int reactionMs = 0,
    DateTime? now,
  }) {
    final prev = _items[itemKey];
    // 「2回目以降の遭遇」の定義。定着率はここだけを数える。
    //
    // ⚠️ 最初は「すでに1回答えたことがある」「別の日に会った」に限っていたが、
    //    それだと定着率がほぼ永久に「—」のままになった。
    //    なまえコールは1人につき命名1回＋想起1回なので、想起が
    //    毎回「1回目の回答」に数えられ、分母が増えなかったため。
    //    命名・おぼえタイム・名刺交換で「会った」ことを記録している以上、
    //    そのあとの想起は立派な2回目の遭遇なので、これを数える。
    final isRepeat = prev != null;
    final day = _dayNumber(now ?? DateTime.now());

    _items[itemKey] = (prev ?? const ItemStat()).addAnswer(
      correct: correct,
      isRepeat: isRepeat,
      day: day,
    );

    final m = _modes[mode.id] ?? const ModeStat();
    _modes[mode.id] = m.addAnswer(
      correct: correct,
      isRepeat: isRepeat,
      reactionMs: reactionMs,
    );
  }

  /// 1セッション（1試合・1特訓）を終えたときに呼ぶ。回数を数えて保存する。
  Future<void> finishSession(StatMode mode) async {
    final m = _modes[mode.id] ?? const ModeStat();
    _modes[mode.id] = m.addSession();
    _trim();
    await _persist();
    notifyListeners();
  }

  /// 記録だけ保存する（セッションの区切りではないとき）。
  Future<void> flush() async {
    _trim();
    await _persist();
    notifyListeners();
  }

  void _trim() {
    if (_items.length <= maxItems) return;
    final keys = _items.keys.toList()
      ..sort((a, b) => _items[a]!.lastDay.compareTo(_items[b]!.lastDay));
    for (final k in keys.take(_items.length - maxItems)) {
      _items.remove(k);
    }
  }

  ModeStat _agg(StatMode? mode) {
    if (mode != null) return _modes[mode.id] ?? const ModeStat();
    var total = const ModeStat();
    for (final m in _modes.values) {
      total = total.merge(m);
    }
    return total;
  }

  /// 総回答数。[mode] が null なら全モード合計。
  int totalAnswers(StatMode? mode) => _agg(mode).answers;

  /// セッション数。
  int sessions(StatMode? mode) => _agg(mode).sessions;

  /// 🎯 正確性（0-100）。回答が無ければ null。
  int? accuracyPct(StatMode? mode) {
    final a = _agg(mode);
    if (a.answers == 0) return null;
    return a.correct * 100 ~/ a.answers;
  }

  /// ⚡ 速さ（平均回答時間ms）。計測できた回答が無ければ null。
  int? avgReactionMs(StatMode? mode) {
    final a = _agg(mode);
    if (a.timedAnswers == 0) return null;
    return a.totalMs ~/ a.timedAnswers;
  }

  /// 🧠 定着率（0-100）＝2回目以降に会った人に答えられた割合。
  /// まだ誰とも再会していなければ null（「—」表示にする）。
  int? retentionPct(StatMode? mode) {
    final a = _agg(mode);
    if (a.repeatAnswers == 0) return null;
    return a.repeatCorrect * 100 ~/ a.repeatAnswers;
  }

  /// 2回目以降の出題数（定着率の分母。「まだ足りない」の案内に使う）。
  int repeatAnswers(StatMode? mode) => _agg(mode).repeatAnswers;

  /// 覚えた人数＝2回目以降に正解できたことがある人の数。
  int get retainedPeople =>
      _items.values.where((e) => e.repeatCorrect > 0).length;

  /// 苦手な人＝2回目以降に会ったのに半分も当てられていない人のキー。
  List<String> weakItemKeys({int limit = 5}) {
    final weak = _items.entries
        .where((e) => e.value.repeatAnswers >= 2)
        .where((e) => e.value.repeatCorrect * 2 < e.value.repeatAnswers)
        .toList()
      ..sort((a, b) => b.value.repeatAnswers.compareTo(a.value.repeatAnswers));
    return [for (final e in weak.take(limit)) e.key];
  }

  static int _dayNumber(DateTime t) =>
      DateTime(t.year, t.month, t.day).difference(DateTime(1970)).inDays;

  /// テスト用: 中身を空にする。
  @visibleForTesting
  Future<void> clearForTest() async {
    _loaded = true;
    _items.clear();
    _modes.clear();
    await _persist();
  }
}

/// 人物1人ぶんの記録。
@immutable
class ItemStat {
  final int seen; // 出題された回数
  final int correct; // 正解した回数
  final int repeatAnswers; // 2回目以降の出題数
  final int repeatCorrect; // 2回目以降の正解数
  final int lastDay; // 最後に会った日（1970-01-01からの日数）

  const ItemStat({
    this.seen = 0,
    this.correct = 0,
    this.repeatAnswers = 0,
    this.repeatCorrect = 0,
    this.lastDay = 0,
  });

  /// 出題ではなく「会った」だけの記録。次からは2回目あつかいになる。
  ItemStat addMeeting(int day) => ItemStat(
        seen: seen,
        correct: correct,
        repeatAnswers: repeatAnswers,
        repeatCorrect: repeatCorrect,
        lastDay: day,
      );

  ItemStat addAnswer({
    required bool correct,
    required bool isRepeat,
    required int day,
  }) =>
      ItemStat(
        seen: seen + 1,
        correct: this.correct + (correct ? 1 : 0),
        repeatAnswers: repeatAnswers + (isRepeat ? 1 : 0),
        repeatCorrect: repeatCorrect + (isRepeat && correct ? 1 : 0),
        lastDay: day,
      );

  Map<String, dynamic> toJson() => {
        's': seen,
        'c': correct,
        'ra': repeatAnswers,
        'rc': repeatCorrect,
        'd': lastDay,
      };

  factory ItemStat.fromJson(Map<String, dynamic> j) => ItemStat(
        seen: (j['s'] as int?) ?? 0,
        correct: (j['c'] as int?) ?? 0,
        repeatAnswers: (j['ra'] as int?) ?? 0,
        repeatCorrect: (j['rc'] as int?) ?? 0,
        lastDay: (j['d'] as int?) ?? 0,
      );
}

/// モード1つぶんの集計。
@immutable
class ModeStat {
  final int answers;
  final int correct;
  final int repeatAnswers;
  final int repeatCorrect;
  final int totalMs; // 速さを計測できた回答の合計時間
  final int timedAnswers; // 速さを計測できた回答数
  final int sessions;

  const ModeStat({
    this.answers = 0,
    this.correct = 0,
    this.repeatAnswers = 0,
    this.repeatCorrect = 0,
    this.totalMs = 0,
    this.timedAnswers = 0,
    this.sessions = 0,
  });

  ModeStat addAnswer({
    required bool correct,
    required bool isRepeat,
    required int reactionMs,
  }) =>
      ModeStat(
        answers: answers + 1,
        correct: this.correct + (correct ? 1 : 0),
        repeatAnswers: repeatAnswers + (isRepeat ? 1 : 0),
        repeatCorrect: repeatCorrect + (isRepeat && correct ? 1 : 0),
        totalMs: totalMs + (reactionMs > 0 ? reactionMs : 0),
        timedAnswers: timedAnswers + (reactionMs > 0 ? 1 : 0),
        sessions: sessions,
      );

  ModeStat addSession() => merge(const ModeStat(sessions: 1));

  ModeStat merge(ModeStat o) => ModeStat(
        answers: answers + o.answers,
        correct: correct + o.correct,
        repeatAnswers: repeatAnswers + o.repeatAnswers,
        repeatCorrect: repeatCorrect + o.repeatCorrect,
        totalMs: totalMs + o.totalMs,
        timedAnswers: timedAnswers + o.timedAnswers,
        sessions: sessions + o.sessions,
      );

  Map<String, dynamic> toJson() => {
        'a': answers,
        'c': correct,
        'ra': repeatAnswers,
        'rc': repeatCorrect,
        'ms': totalMs,
        'ta': timedAnswers,
        'ss': sessions,
      };

  factory ModeStat.fromJson(Map<String, dynamic> j) => ModeStat(
        answers: (j['a'] as int?) ?? 0,
        correct: (j['c'] as int?) ?? 0,
        repeatAnswers: (j['ra'] as int?) ?? 0,
        repeatCorrect: (j['rc'] as int?) ?? 0,
        totalMs: (j['ms'] as int?) ?? 0,
        timedAnswers: (j['ta'] as int?) ?? 0,
        sessions: (j['ss'] as int?) ?? 0,
      );
}
