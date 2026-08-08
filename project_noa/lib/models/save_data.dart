/// SPEC 7章 — スロットセーブとシステムデータ。
library;

import 'noah_field.dart';

/// スロット1つぶんのセーブ。
///
/// ロードで「シーンID・行・フラグ・好感度・記憶ペア・サイクル・老化」を
/// 完全に戻せること（SPEC 3.4）。ここに項目を足したら [toJson]/[fromJson]
/// の両方と、`version` の扱いを必ず見直す。
class SaveData {
  static const int version = 1;

  final int slot;
  final DateTime savedAt;
  final int playSec;

  final String sceneId;
  final int lineIndex;

  /// 何サイクル目の覚醒期か（0〜11）。
  final int cycle;

  /// 老化レベル（0〜10）。背景バリアントとUIの風合いに効く。
  final int aging;

  final Set<String> flags;

  /// キャラID → 好感度。
  final Map<String, int> affection;

  /// `hibino.hobby` → 正解したか。**記憶率の分子**。
  final Map<String, bool> memory;

  /// バックログ汚染の強さ（0.0〜1.0）。
  final double contamination;

  const SaveData({
    required this.slot,
    required this.savedAt,
    required this.playSec,
    required this.sceneId,
    required this.lineIndex,
    this.cycle = 0,
    this.aging = 0,
    this.flags = const {},
    this.affection = const {},
    this.memory = const {},
    this.contamination = 0,
  });

  /// 正解した (キャラ,項目) の数。
  int get correctCount => memory.values.where((v) => v).length;

  Map<String, dynamic> toJson() => {
        'v': version,
        'slot': slot,
        'ts': savedAt.toIso8601String(),
        'playSec': playSec,
        'scene': sceneId,
        'line': lineIndex,
        'cycle': cycle,
        'aging': aging,
        'flags': flags.toList(),
        'affection': affection,
        'memory': memory,
        'contamination': contamination,
      };

  factory SaveData.fromJson(Map<String, dynamic> j) => SaveData(
        slot: (j['slot'] as num?)?.toInt() ?? 0,
        savedAt: DateTime.tryParse(j['ts'] as String? ?? '') ?? DateTime(2000),
        playSec: (j['playSec'] as num?)?.toInt() ?? 0,
        sceneId: j['scene'] as String? ?? '',
        lineIndex: (j['line'] as num?)?.toInt() ?? 0,
        cycle: (j['cycle'] as num?)?.toInt() ?? 0,
        aging: (j['aging'] as num?)?.toInt() ?? 0,
        flags: {...(j['flags'] as List? ?? const []).map((e) => '$e')},
        affection: {
          for (final e in (j['affection'] as Map? ?? const {}).entries)
            '${e.key}': (e.value as num?)?.toInt() ?? 0,
        },
        memory: {
          for (final e in (j['memory'] as Map? ?? const {}).entries)
            '${e.key}': e.value == true,
        },
        contamination: (j['contamination'] as num?)?.toDouble() ?? 0,
      );

  SaveData copyWith({
    int? slot,
    DateTime? savedAt,
    int? playSec,
    String? sceneId,
    int? lineIndex,
    int? cycle,
    int? aging,
    Set<String>? flags,
    Map<String, int>? affection,
    Map<String, bool>? memory,
    double? contamination,
  }) =>
      SaveData(
        slot: slot ?? this.slot,
        savedAt: savedAt ?? this.savedAt,
        playSec: playSec ?? this.playSec,
        sceneId: sceneId ?? this.sceneId,
        lineIndex: lineIndex ?? this.lineIndex,
        cycle: cycle ?? this.cycle,
        aging: aging ?? this.aging,
        flags: flags ?? this.flags,
        affection: affection ?? this.affection,
        memory: memory ?? this.memory,
        contamination: contamination ?? this.contamination,
      );
}

/// 周回で解禁されるもの（SPEC 4.6）。
class Unlocks {
  final bool cast2;
  final bool mysteries;
  final bool trueRoute;

  const Unlocks({
    this.cast2 = false,
    this.mysteries = false,
    this.trueRoute = false,
  });

  Map<String, dynamic> toJson() =>
      {'cast2': cast2, 'mysteries': mysteries, 'true': trueRoute};

  factory Unlocks.fromJson(Map<String, dynamic> j) => Unlocks(
        cast2: j['cast2'] == true,
        mysteries: j['mysteries'] == true,
        trueRoute: j['true'] == true,
      );
}

/// システムデータ。**セーブデータをまたいで持ち越すもの**。
///
/// ⚠️ [maxMemoryRate] はここにしか置かない。スロットセーブ側に置くと、
///    低い記憶率のデータをロードするだけで解禁が巻き戻ってしまう
///    （SPEC 4.3「最大到達値はシステムデータ側。改変不可」）。
class SystemData {
  static const int version = 1;

  /// クリア回数。
  final int cleared;

  /// これまでの最高記憶率（0.0〜1.0）。**下がらない**。
  final double maxMemoryRate;

  final Unlocks unlocks;

  /// 既読のシーンID。スキップの判定に使う。
  final Set<String> readScenes;

  /// 集めた用語。
  final Set<String> glossary;

  const SystemData({
    this.cleared = 0,
    this.maxMemoryRate = 0,
    this.unlocks = const Unlocks(),
    this.readScenes = const {},
    this.glossary = const {},
  });

  Map<String, dynamic> toJson() => {
        'v': version,
        'cleared': cleared,
        'maxMemoryRate': maxMemoryRate,
        'unlocks': unlocks.toJson(),
        'readScenes': readScenes.toList(),
        'glossary': glossary.toList(),
      };

  factory SystemData.fromJson(Map<String, dynamic> j) => SystemData(
        cleared: (j['cleared'] as num?)?.toInt() ?? 0,
        maxMemoryRate: (j['maxMemoryRate'] as num?)?.toDouble() ?? 0,
        unlocks:
            Unlocks.fromJson((j['unlocks'] as Map?)?.cast<String, dynamic>() ?? {}),
        readScenes: {...(j['readScenes'] as List? ?? const []).map((e) => '$e')},
        glossary: {...(j['glossary'] as List? ?? const []).map((e) => '$e')},
      );

  /// 記憶率を報告する。**上がったときだけ**取り込み、解禁を計算し直す。
  /// 低い記憶率のセーブをロードしても、解禁が巻き戻らないようにするため。
  SystemData reportMemoryRate(double rate) =>
      rate <= maxMemoryRate ? this : copyWith(maxMemoryRate: rate);

  /// 1周おわった。クリア回数を増やして解禁を計算し直す。
  SystemData reportCleared() => copyWith(cleared: cleared + 1);

  SystemData copyWith({
    int? cleared,
    double? maxMemoryRate,
    Unlocks? unlocks,
    Set<String>? readScenes,
    Set<String>? glossary,
  }) {
    final rate = maxMemoryRate ?? this.maxMemoryRate;
    final clearedN = cleared ?? this.cleared;
    return SystemData(
      cleared: clearedN,
      maxMemoryRate: rate,
      // 解禁は「クリア回数」と「最高記憶率」から必ず導出する。
      // 直接書き換えられるようにすると、片方だけ食い違って
      // 「2周目なのにキャストが増えない」ような壊れ方をする。
      unlocks: unlocks ?? resolveUnlocks(cleared: clearedN, maxRate: rate),
      readScenes: readScenes ?? this.readScenes,
      glossary: glossary ?? this.glossary,
    );
  }
}

/// SPEC 4.6 の表をそのままコードにしたもの。
///
/// | 周回 | 解禁 | 条件 |
/// | 2周目 | 残り4人 | 1周目クリア |
/// | 3周目 | 船内の謎 | 記憶率の最大値 ≥ 60% |
/// | 真   | 転送権   | 記憶率 100% |
Unlocks resolveUnlocks({required int cleared, required double maxRate}) =>
    Unlocks(
      cast2: cleared >= 1,
      mysteries: cleared >= 2 && maxRate >= 0.60,
      trueRoute: maxRate >= 1.0,
    );

/// 記憶率（SPEC 4.3）。分母は「出しうる組の総数」。
double memoryRate({required int correct, required int totalPairs}) {
  if (totalPairs <= 0) return 0;
  return correct / totalPairs;
}

/// 画面に出す百分率（例 `43.75%`）。
String memoryRateLabel(double rate) =>
    '${(rate * 100).toStringAsFixed(2)}%';

/// 記憶率の分母。キャラ数 × 項目数。
int totalPairsFor(int characterCount) =>
    characterCount * NoahField.values.length;
