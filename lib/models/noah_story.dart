/// 🚀 ストーリーモード「プロジェクト・ノア」。
///
/// 太陽が赤色巨星になった遠い未来。横浜・戸塚区大池町の旧ゴルフ場から、
/// 49光年先の LHS 1140 b を目指す箱舟が発つ。
/// プレイヤーは乗員のひとりとして、8人の科学者と出会い、
/// **名前・所属・趣味・通信ID を覚えていく**。
///
/// 覚えているほど相手と親しくなり、結末が変わる。
/// ⚠️ 劇中で人は死なない。マインドアップロードも「死」ではなく引越しとして扱う。
///
/// イラストは後から差し替える前提で、いまは絵文字と色だけ持たせている。
library;

import 'dart:math';

/// 恋愛対象の8人。
///
/// ⚠️ 3択の**まちがいの選択肢は、必ず別のキャラの本物のデータ**から作る。
/// 適当な偽名を混ぜると「明らかに違う」ものが並んで実質2択になるうえ、
/// まちがえたときに「あの人と記憶が混ざっている」という手ざわりが出ない。
class NoahCharacter {
  final String id;
  final String name; // フルネーム
  final String reading; // よみ
  final String field; // 所属・専門
  final String hobby; // 趣味
  final String commId; // 通信ID（電話番号のかわり）
  final String school; // 学生時代
  final String regret; // やり残したこと（終盤で回収する）
  final String emoji; // 立ち絵が入るまでの仮の顔
  final int colorValue; // 名前の色
  final bool male;

  const NoahCharacter({
    required this.id,
    required this.name,
    required this.reading,
    required this.field,
    required this.hobby,
    required this.commId,
    required this.school,
    required this.regret,
    required this.emoji,
    required this.colorValue,
    required this.male,
  });
}

const List<NoahCharacter> kNoahCast = [
  NoahCharacter(
    id: 'hibino',
    name: '日比野 楓',
    reading: 'ひびの かえで',
    field: '量子推進研究所',
    hobby: '陶芸',
    commId: 'NH-0421',
    school: '京大工学部・山岳部',
    regret: '父に「ただいま」を言えなかった',
    emoji: '🔥',
    colorValue: 0xFFE8663C,
    male: false,
  ),
  NoahCharacter(
    id: 'kiryu',
    name: '桐生 悟',
    reading: 'きりゅう さとる',
    field: '量子意識研究所',
    hobby: '囲碁',
    commId: 'QZ-1024',
    school: '東大理学部・哲学副専攻',
    regret: '姉の「一緒に碁を打とう」を断り続けた',
    emoji: '⚛️',
    colorValue: 0xFF5AC8E8,
    male: true,
  ),
  NoahCharacter(
    id: 'mizuhara',
    name: '水原 紗耶香',
    reading: 'みずはら さやか',
    field: '宇宙発生生物学研究所',
    hobby: 'メダカ飼育',
    commId: 'BIO-2236',
    school: '東北大・海洋生物学',
    regret: '祖母のぬか床を次の誰かに渡せなかった',
    emoji: '🧬',
    colorValue: 0xFF7ACB8A,
    male: false,
  ),
  NoahCharacter(
    id: 'tachibana',
    name: '橘 宗一郎',
    reading: 'たちばな そういちろう',
    field: '閉鎖生態系工学センター',
    hobby: '盆栽',
    commId: 'ECO-0707',
    school: '北大農学部',
    regret: '妻と「二人の庭」を作る約束',
    emoji: '🌿',
    colorValue: 0xFF4E9A51,
    male: true,
  ),
  NoahCharacter(
    id: 'hoshino',
    name: '星野 未来',
    reading: 'ほしの みらい',
    field: '相模原宇宙航行力学研究所',
    hobby: '星空撮影',
    commId: 'ORB-1140',
    school: '東大理学部・天文部',
    regret: '祖父に本当の星空を見せたかった',
    emoji: '🛰️',
    colorValue: 0xFF6C7BE8,
    male: false,
  ),
  NoahCharacter(
    id: 'iwao',
    name: '岩尾 玄助',
    reading: 'いわお げんすけ',
    field: '惑星科学研究所',
    hobby: '登山と俳句',
    commId: 'TER-0050',
    school: '東大理学部・地質学科',
    regret: '故郷の山に最後に登れなかった',
    emoji: '🪨',
    colorValue: 0xFF9A7B4F,
    male: true,
  ),
  NoahCharacter(
    id: 'kusunoki',
    name: '楠 玲',
    reading: 'くすのき れい',
    field: 'ノア・システムズ局',
    hobby: 'ラジオ修理',
    commId: 'ROB-0093',
    school: '東工大・制御工学',
    regret: '兄のラジオを最後まで直せなかった',
    emoji: '🤖',
    colorValue: 0xFFB06BC8,
    male: false,
  ),
  NoahCharacter(
    id: 'shirakawa',
    name: '白川 冬也',
    reading: 'しらかわ とうや',
    field: '宇宙医学研究所',
    hobby: 'マラソン',
    commId: 'MED-0310',
    school: '慶應医学部',
    regret: '患者に「大丈夫」と言えなかった',
    emoji: '🩺',
    colorValue: 0xFF4FA3D1,
    male: true,
  ),
];

NoahCharacter? noahCharacterById(String id) {
  for (final c in kNoahCast) {
    if (c.id == id) return c;
  }
  return null;
}

/// 出題する項目。デートで聞いた話ほど後半に出る。
enum NoahField { name, affiliation, hobby, commId, school }

extension NoahFieldLabel on NoahField {
  /// 「〜は？」の見出し。
  String get questionJa => switch (this) {
        NoahField.name => 'この人の名前は？',
        NoahField.affiliation => 'この人の所属は？',
        NoahField.hobby => 'この人の趣味は？',
        NoahField.commId => 'この人の通信IDは？',
        NoahField.school => 'この人の学生時代は？',
      };

  String get labelJa => switch (this) {
        NoahField.name => '名前',
        NoahField.affiliation => '所属',
        NoahField.hobby => '趣味',
        NoahField.commId => '通信ID',
        NoahField.school => '学生時代',
      };

  String valueOf(NoahCharacter c) => switch (this) {
        NoahField.name => c.name,
        NoahField.affiliation => c.field,
        NoahField.hobby => c.hobby,
        NoahField.commId => c.commId,
        NoahField.school => c.school,
      };
}

/// 3択1問。
class NoahQuestion {
  final NoahCharacter target;
  final NoahField field;

  /// 表示順に並んだ選択肢（正解を1つ含む）。
  final List<String> choices;

  const NoahQuestion({
    required this.target,
    required this.field,
    required this.choices,
  });

  String get answer => field.valueOf(target);
  bool isCorrect(String picked) => picked == answer;
}

/// [target] についての3択を作る。
///
/// まちがいの選択肢は [pool]（＝すでに出会った他のキャラ）の本物の値から取る。
/// 出会った人が少ないうちは3つに満たないこともあるので、
/// 足りなければ全キャストから補う。
NoahQuestion buildNoahQuestion({
  required NoahCharacter target,
  required NoahField field,
  required List<NoahCharacter> pool,
  Random? random,
  int choiceCount = 3,
}) {
  final rng = random ?? Random();
  final answer = field.valueOf(target);
  final wrong = <String>{};

  void collect(List<NoahCharacter> from) {
    final list = [...from]..shuffle(rng);
    for (final c in list) {
      if (wrong.length >= choiceCount - 1) return;
      if (c.id == target.id) continue;
      final v = field.valueOf(c);
      if (v == answer || v.isEmpty) continue;
      wrong.add(v);
    }
  }

  collect(pool);
  if (wrong.length < choiceCount - 1) collect(kNoahCast);

  return NoahQuestion(
    target: target,
    field: field,
    choices: [answer, ...wrong].toList()..shuffle(rng),
  );
}

/// 結末。**どの結末でも誰も死なない**。
enum NoahEnding {
  /// 好感度がはっきり1位の相手がいる。
  happy,

  /// 全員がほぼ同じ。子孫に「顔が似すぎ」と笑われる。
  bitter,

  /// 誰の名前もほとんど覚えられなかった。
  /// マインドアップロードして、船の世話係として全員を見守り続ける。
  lonely,
}

/// 結末の判定。
///
/// - 覚えた総量が少なすぎる → [NoahEnding.lonely]
/// - 1位が2位より [leadNeeded] 以上リード → [NoahEnding.happy]
/// - それ以外（横並び） → [NoahEnding.bitter]
class NoahResult {
  final NoahEnding ending;

  /// ハッピーエンドの相手（他の結末では null）。
  final NoahCharacter? partner;

  final int totalAffection;

  const NoahResult({
    required this.ending,
    required this.totalAffection,
    this.partner,
  });
}

/// 孤独エンドになる総好感度のしきい値（これ未満）。
const int kNoahLonelyThreshold = 6;

/// ハッピーエンドに必要な「1位と2位の差」。
const int kNoahLeadNeeded = 3;

NoahResult resolveNoahEnding(Map<String, int> affection) {
  final total = affection.values.fold<int>(0, (a, b) => a + b);
  if (total < kNoahLonelyThreshold) {
    return NoahResult(ending: NoahEnding.lonely, totalAffection: total);
  }

  final ranked = affection.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final top = ranked.first;
  final second = ranked.length > 1 ? ranked[1].value : 0;

  if (top.value - second >= kNoahLeadNeeded) {
    return NoahResult(
      ending: NoahEnding.happy,
      totalAffection: total,
      partner: noahCharacterById(top.key),
    );
  }
  return NoahResult(ending: NoahEnding.bitter, totalAffection: total);
}
