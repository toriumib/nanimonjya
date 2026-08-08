/// SPEC 4.5 — バックログ汚染（クロス・コンタミネーション）。
///
/// 長期の冷凍保存で、誰の記憶かの区別がにじむ【創作】。
///
/// ⚠️ **正典のテキストは絶対に書き換えない**。
///    ログには本来の文をそのまま持たせて、**描画のときだけ**名前を差し替える。
///    保存されている文を汚してしまうと、あとで元に戻せない。
///
/// ⚠️ 差し替えは**同じ行なら毎回同じ結果**にする。
///    乱数をそのつど振ると、スクロールするたび名前が変わって
///    「にじみ」ではなく「バグ」に見える。行番号を種にして固定する。
library;

import 'dart:math';

/// サイクルが1つ進むごとに、どれだけ濁るか。
const double kContaminationPerCycle = 0.055;

/// 思い出せたときに、どれだけ晴れるか。
///
/// **覚えるほどログが澄む**。これがこの作品のいちばん素直な報酬になる。
const double kContaminationClearPerRecall = 0.02;

/// 濁りの上限。1.0 にすると全部の名前が入れ替わって読めなくなる。
const double kContaminationMax = 0.45;

double clampContamination(double v) => v.clamp(0.0, kContaminationMax);

/// 表示用に名前を差し替える。
///
/// [text] は正典。[names] は差し替え候補になる人名（姓だけでもよい）。
/// [level] は 0.0〜[kContaminationMax]。[seed] は行を特定する値。
///
/// 戻り値は表示用の文字列。**保存してはいけない**。
String contaminate(
  String text, {
  required double level,
  required List<String> names,
  required int seed,
}) {
  if (level <= 0 || names.length < 2 || text.isEmpty) return text;

  // 出現した名前を、前から順に拾う。
  // 長い名前から先に見ないと「土倉源三」が「土倉」で切れる。
  final sorted = [...names]..sort((a, b) => b.length.compareTo(a.length));

  var out = text;
  var hit = 0;
  for (final n in sorted) {
    if (n.isEmpty || !out.contains(n)) continue;
    // 行と、その行の何番目の名前かで種を決める。
    final rng = Random(seed * 1000 + hit);
    hit += 1;
    if (rng.nextDouble() >= level) continue;

    // 自分以外から1つ選ぶ
    final others = [for (final m in names) if (m != n && m.isNotEmpty) m];
    if (others.isEmpty) continue;
    final to = others[rng.nextInt(others.length)];
    // ⚠️ 最初の1か所だけ替える。全部替えると別人の話になってしまい、
    //    「にじんでいる」ではなく「書き換わっている」になる。
    out = out.replaceFirst(n, to);
  }
  return out;
}

/// その行が汚染されているか（表示に印をつけたいとき用）。
bool isContaminated(String canonical, String shown) => canonical != shown;
