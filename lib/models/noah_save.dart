/// 💾 ストーリーモード「プロジェクト・ノア」の途中セーブ。
///
/// 一周が長い（十六人と会って、十六人ぶん思い出して、船内で話して、
/// 最終確認まで）ので、中断して戻れないと詰む。
///
/// ⚠️ **出題中の3択も保存する**こと。
/// 復帰時に作り直すと、答えが気に入らないときアプリを閉じて
/// 引き直せてしまう（実質やり直し放題になる）。
library;

import 'dart:convert';

import 'noah_story.dart';

/// 保存フォーマットの版。作りを変えたら上げる。
/// 読めない版のセーブは捨てて最初から始める（壊れたまま復帰させない）。
const int kNoahSaveVersion = 1;

class NoahSaveData {
  final String phase; // 画面側の _Phase.name
  final String gender; // NoahGender.name
  final String pref; // NoahPreference.name

  final List<String> castIds; // 出てくる十六人（並び順も意味を持つ）
  final List<String> talkableIds; // 船内で話す相手
  final List<String> metIds; // 名刺をもらい終えた人

  final Map<String, int> affection;
  final Map<String, List<String>> remembered; // id → NoahField.name
  final int mysterySolved;

  final int index;
  final int line;
  final int correct;
  final int total;

  final List<String> noteTitles; // 出す覚え方メモ（タイトルで引き直す）
  final int noteIndex;

  final List<String> mysteryCulpritIds;
  final List<List<String>> mysteryChoiceIds;
  final int mysteryIndex;
  final String? mysteryPickedId;

  /// 出題中の3択。無ければ null。
  final String? qTargetId;
  final String? qField;
  final List<String> qChoices;
  final String? qPicked;

  const NoahSaveData({
    required this.phase,
    required this.gender,
    required this.pref,
    required this.castIds,
    required this.talkableIds,
    required this.metIds,
    required this.affection,
    required this.remembered,
    required this.mysterySolved,
    required this.index,
    required this.line,
    required this.correct,
    required this.total,
    required this.noteTitles,
    required this.noteIndex,
    required this.mysteryCulpritIds,
    required this.mysteryChoiceIds,
    required this.mysteryIndex,
    this.mysteryPickedId,
    this.qTargetId,
    this.qField,
    this.qChoices = const [],
    this.qPicked,
  });

  Map<String, dynamic> toJson() => {
        'v': kNoahSaveVersion,
        'phase': phase,
        'gender': gender,
        'pref': pref,
        'cast': castIds,
        'talk': talkableIds,
        'met': metIds,
        'love': affection,
        'mem': remembered,
        'msolved': mysterySolved,
        'i': index,
        'line': line,
        'ok': correct,
        'n': total,
        'notes': noteTitles,
        'ni': noteIndex,
        'myst': mysteryCulpritIds,
        'mystc': mysteryChoiceIds,
        'mi': mysteryIndex,
        'mpick': mysteryPickedId,
        'qt': qTargetId,
        'qf': qField,
        'qc': qChoices,
        'qp': qPicked,
      };

  static NoahSaveData? fromJson(Map<String, dynamic> j) {
    if (j['v'] != kNoahSaveVersion) return null;
    List<String> strs(Object? o) =>
        (o as List?)?.map((e) => e.toString()).toList() ?? const [];
    return NoahSaveData(
      phase: j['phase']?.toString() ?? '',
      gender: j['gender']?.toString() ?? '',
      pref: j['pref']?.toString() ?? '',
      castIds: strs(j['cast']),
      talkableIds: strs(j['talk']),
      metIds: strs(j['met']),
      affection: {
        for (final e in (j['love'] as Map? ?? {}).entries)
          e.key.toString(): (e.value as num).toInt(),
      },
      remembered: {
        for (final e in (j['mem'] as Map? ?? {}).entries)
          e.key.toString(): strs(e.value),
      },
      mysterySolved: (j['msolved'] as num?)?.toInt() ?? 0,
      index: (j['i'] as num?)?.toInt() ?? 0,
      line: (j['line'] as num?)?.toInt() ?? 0,
      correct: (j['ok'] as num?)?.toInt() ?? 0,
      total: (j['n'] as num?)?.toInt() ?? 0,
      noteTitles: strs(j['notes']),
      noteIndex: (j['ni'] as num?)?.toInt() ?? 0,
      mysteryCulpritIds: strs(j['myst']),
      mysteryChoiceIds:
          (j['mystc'] as List? ?? []).map<List<String>>(strs).toList(),
      mysteryIndex: (j['mi'] as num?)?.toInt() ?? 0,
      mysteryPickedId: j['mpick']?.toString(),
      qTargetId: j['qt']?.toString(),
      qField: j['qf']?.toString(),
      qChoices: strs(j['qc']),
      qPicked: j['qp']?.toString(),
    );
  }

  String encode() => jsonEncode(toJson());

  /// 壊れた文字列でも落ちない。読めなければ null。
  static NoahSaveData? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final j = jsonDecode(raw);
      if (j is! Map<String, dynamic>) return null;
      return fromJson(j);
    } catch (_) {
      return null;
    }
  }

  // ── 復元のたすけ ──

  List<NoahCharacter> cast() => _byIds(castIds);
  List<NoahCharacter> talkable() => _byIds(talkableIds);
  List<NoahCharacter> met() => _byIds(metIds);

  static List<NoahCharacter> _byIds(List<String> ids) => [
        for (final id in ids)
          if (noahCharacterById(id) != null) noahCharacterById(id)!,
      ];

  Map<String, Set<NoahField>> rememberedFields() => {
        for (final e in remembered.entries)
          e.key: {
            for (final n in e.value)
              ...NoahField.values.where((f) => f.name == n),
          },
      };

  List<NoahNote> notes() => [
        for (final title in noteTitles)
          ...kNoahNotes.where((n) => n.title == title),
      ];

  List<NoahMysteryQuestion> mysteries() {
    final out = <NoahMysteryQuestion>[];
    for (var i = 0; i < mysteryCulpritIds.length; i++) {
      final culprit = noahCharacterById(mysteryCulpritIds[i]);
      final m = culprit == null ? null : noahMysteryFor(culprit.id);
      if (culprit == null || m == null) continue;
      final choices = i < mysteryChoiceIds.length
          ? _byIds(mysteryChoiceIds[i])
          : <NoahCharacter>[culprit];
      if (choices.isEmpty) continue;
      out.add(NoahMysteryQuestion(
          mystery: m, culprit: culprit, choices: choices));
    }
    return out;
  }

  NoahQuestion? question() {
    final target = qTargetId == null ? null : noahCharacterById(qTargetId!);
    if (target == null || qField == null || qChoices.isEmpty) return null;
    final field =
        NoahField.values.where((f) => f.name == qField).firstOrNull;
    if (field == null) return null;
    return NoahQuestion(target: target, field: field, choices: qChoices);
  }

  /// 続きの見出し。「つづきから」に添えて、どこまで進んだか分かるように。
  String get summaryJa {
    final people = castIds.length;
    return '$correct / $total 問正解・十六人中$people人が登場中';
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
