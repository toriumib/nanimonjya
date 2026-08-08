/// STORY 8章 — 結末の判定。
///
/// **誰も死なない。誰も嫌な思いをしない。全員が入植する。**
/// どの結末も「たどり着けなかった」ではなく「そうなった」として描く。
library;

import '../models/noah_field.dart';

enum NoahEnding {
  /// 好感度1位が明確。最愛の相手と結ばれる。
  happy,

  /// 1位が2人以上で並んでいる（全員ではない）。大家族。
  harem,

  /// 全員が同率、または僅差。500人が家族になる同窓会。
  bitter,

  /// 覚えた総量がしきい値未満。
  /// 一人、船と乗員の世話を続ける。**罰ではない**。
  lonely,

  /// 記憶率100%。17人全員の名を呼ぶ真ルート。
  trueRoute;

  /// 飛び先のシーンID。
  String get sceneId => switch (this) {
        NoahEnding.happy => 'ending_happy',
        NoahEnding.harem => 'ending_harem',
        NoahEnding.bitter => 'ending_bitter',
        NoahEnding.lonely => 'ending_lonely',
        NoahEnding.trueRoute => 'ending_true',
      };

  String get labelJa => switch (this) {
        NoahEnding.happy => 'ハッピーエンド',
        NoahEnding.harem => '大家族エンド',
        NoahEnding.bitter => '同窓会エンド',
        NoahEnding.lonely => '呼名のひと（見守りエンド）',
        NoahEnding.trueRoute => '真エンド ── 呼名',
      };
}

/// 孤独（見守り）になる総好感度のしきい値。これ未満。
const int kLonelyThreshold = 6;

/// ハッピーに必要な「1位と2位の差」。
const int kLeadNeeded = 3;

class EndingResult {
  final NoahEnding ending;

  /// ハッピーの相手（他の結末では null）。
  final NoahCharacter? partner;

  /// 大家族のときに並んだ相手。
  final List<NoahCharacter> partners;

  final int totalAffection;

  const EndingResult({
    required this.ending,
    required this.totalAffection,
    this.partner,
    this.partners = const [],
  });
}

/// 結末を決める。
///
/// 判定の順番が大事。
/// ① 記憶率100% → 真（好感度に関係なく最優先）
/// ② 覚えた総量が少なすぎる → 見守り
/// ③ 全員同率 → 同窓会
/// ④ 1位が複数 → 大家族
/// ⑤ 1位が2位を [kLeadNeeded] 以上リード → ハッピー
/// ⑥ それ以外（僅差） → 同窓会
EndingResult resolveEnding({
  required Map<String, int> affection,
  required NoahCast cast,
  required double memoryRate,
}) {
  final total = affection.values.fold<int>(0, (a, b) => a + b);

  if (memoryRate >= 1.0) {
    return EndingResult(ending: NoahEnding.trueRoute, totalAffection: total);
  }
  if (total < kLonelyThreshold) {
    return EndingResult(ending: NoahEnding.lonely, totalAffection: total);
  }

  // 好感度が1以上ついた相手だけを候補にする。
  // 0の人まで「同率1位」に数えると、誰とも話していない周回が
  // 全員同率＝同窓会になってしまう。
  final ranked = [
    for (final e in affection.entries)
      if (e.value > 0) e,
  ]..sort((a, b) => b.value.compareTo(a.value));

  if (ranked.isEmpty) {
    return EndingResult(ending: NoahEnding.lonely, totalAffection: total);
  }

  final top = ranked.first.value;
  final tied = [for (final e in ranked) if (e.value == top) e];
  final second = ranked.length > tied.length ? ranked[tied.length].value : 0;

  // 出会った全員が同じ数だけ並んでいる＝誰も特別にならなかった
  if (tied.length == ranked.length && ranked.length >= 2) {
    return EndingResult(ending: NoahEnding.bitter, totalAffection: total);
  }
  if (tied.length >= 2) {
    return EndingResult(
      ending: NoahEnding.harem,
      totalAffection: total,
      partners: [
        for (final e in tied)
          if (cast.byId(e.key) != null) cast.byId(e.key)!,
      ],
    );
  }
  if (top - second >= kLeadNeeded) {
    return EndingResult(
      ending: NoahEnding.happy,
      totalAffection: total,
      partner: cast.byId(ranked.first.key),
    );
  }
  return EndingResult(ending: NoahEnding.bitter, totalAffection: total);
}
