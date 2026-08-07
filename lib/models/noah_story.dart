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

import 'avatar.dart';

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
  final String emoji; // 一覧などで使う小さな目印
  final int colorValue; // 名前の色
  final bool male;

  /// 🧑‍🎨 立ち絵。顔メモと同じアバターで描く。
  ///
  /// 専用の絵を8人ぶん用意しなくても、特徴（メガネ・ひげ・髪型）で
  /// 見分けがつく。**顔メモで使っているのと同じ仕組み**なので、
  /// 「この人はこういう顔」を覚える練習としても筋が通る。
  final Avatar avatar;

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
    required this.avatar,
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
    // 陶芸の窯元育ち。長い髪をまとめている
    avatar: Avatar(
      skin: 1, faceShape: 0, hair: 5, hairColor: 1, eyes: 2, eyebrows: 0,
      nose: 0, mouth: 0, glasses: 0, mole: 3, beard: 0,
      gender: 2, age: 36, height: 162),
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
    // 理屈っぽい量子屋。四角メガネとオールバック
    avatar: Avatar(
      skin: 1, faceShape: 3, hair: 6, hairColor: 0, eyes: 3, eyebrows: 2,
      nose: 2, mouth: 3, glasses: 2, mole: 0, beard: 0,
      gender: 1, age: 41, height: 176),
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
    // よく笑う生物学者。ポニーテール
    avatar: Avatar(
      skin: 0, faceShape: 1, hair: 4, hairColor: 2, eyes: 5, eyebrows: 0,
      nose: 1, mouth: 1, glasses: 0, mole: 0, beard: 0,
      gender: 2, age: 33, height: 158),
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
    // 盆栽をやる年長者。白髪まじりとあごひげ
    avatar: Avatar(
      skin: 2, faceShape: 2, hair: 1, hairColor: 5, eyes: 1, eyebrows: 1,
      nose: 0, mouth: 0, glasses: 0, mole: 0, beard: 2,
      gender: 1, age: 45, height: 172),
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
    // 星を撮る若手。ショートとまるい目
    avatar: Avatar(
      skin: 0, faceShape: 0, hair: 2, hairColor: 0, eyes: 4, eyebrows: 0,
      nose: 1, mouth: 1, glasses: 0, mole: 4, beard: 0,
      gender: 2, age: 29, height: 165),
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
    // 山に登る惑星屋。ぼうずと無精ひげ、四角い輪郭
    avatar: Avatar(
      skin: 3, faceShape: 2, hair: 0, hairColor: 5, eyes: 3, eyebrows: 1,
      nose: 2, mouth: 2, glasses: 0, mole: 0, beard: 3,
      gender: 1, age: 52, height: 170),
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
    // ラジオを直すロボット屋。丸メガネとウェーブ
    avatar: Avatar(
      skin: 1, faceShape: 1, hair: 5, hairColor: 4, eyes: 0, eyebrows: 2,
      nose: 1, mouth: 3, glasses: 1, mole: 1, beard: 0,
      gender: 2, age: 30, height: 160),
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
    // 走る医師。細いメガネ、細い目
    avatar: Avatar(
      skin: 2, faceShape: 3, hair: 2, hairColor: 0, eyes: 3, eyebrows: 3,
      nose: 0, mouth: 0, glasses: 3, mole: 0, beard: 1,
      gender: 1, age: 38, height: 180),
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

  /// 🌟 真エンド。**全員の全項目を覚えている**ときだけ開く。
  ///
  /// 好感度では届かない。誰を好きかではなく、
  /// **誰の何を覚えているか**で決まるところがこの結末の趣旨。
  trueEnd,
}

// ── 🌐 世界線：覚えている項目の割合 ────────────────────

/// 真エンドに必要なダイバージェンス。
const double kNoahTrueEndDivergence = 1.0;

/// 世界線の呼び名。Steins;Gate 風に、数字を六桁で出す前提。
String noahWorldLineJa(double divergence) {
  if (divergence >= kNoahTrueEndDivergence) return 'Ω';
  if (divergence >= 0.6) return 'γ';
  if (divergence >= 0.3) return 'α';
  return 'β';
}

String noahDivergenceLabel(double d) => d.toStringAsFixed(6);

/// 覚えている項目の割合。
///
/// [remembered] は「この人のこの項目は正解した」の集合。
/// [askable] は出しうる (人物, 項目) の総数。
///
/// ⚠️ 好感度とは別物にしてあること。
/// 「好きだから覚えている」ではなく「覚えているから会える」に
/// したいので、♥は相手を決めるためだけに使う。
double noahDivergence(Map<String, Set<NoahField>> remembered, int askable) {
  if (askable <= 0) return 0;
  var hit = 0;
  for (final fields in remembered.values) {
    hit += fields.length;
  }
  final d = hit / askable;
  return d > 1 ? 1 : d;
}

// ── ⚡ 転送権（もつれ対）────────────────────────────

/// 積んできたもつれ対の数。
///
/// **これは作者が決めた数ではなく、物理から出てくる縛り**。
/// 量子テレポーテーション（Bennett ら 1993）は、事前に共有した
/// もつれ対と古典通信路を要求する。そしてもつれは局所操作と
/// 古典通信だけでは増やせないので、地球で作って積んだぶんが全部になる。
///
/// ⚠️ ここを「補充できる」に変えると、転送が使い捨ての切り札でなくなり、
/// 「移せば元は必ず壊れる」の重さも消える。
const int kNoahEntangledPairs = 3;


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

/// [divergence] が 1.0 に達していれば、好感度より先に真エンドが取れる。
/// 既定は 0 なので、渡さなければ従来どおりの判定になる。
NoahResult resolveNoahEnding(
  Map<String, int> affection, {
  double divergence = 0,
}) {
  final total = affection.values.fold<int>(0, (a, b) => a + b);

  // 🌟 全員の全項目を覚えている＝どの好感度より優先される
  if (divergence >= kNoahTrueEndDivergence) {
    final ranked = affection.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return NoahResult(
      ending: NoahEnding.trueEnd,
      totalAffection: total,
      partner: ranked.isEmpty ? null : noahCharacterById(ranked.first.key),
    );
  }

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

// ── 物語の地の文・セリフ ──────────────────────────────

/// 話し手。ナレーションと主人公と相手だけで足りる。
enum NoahVoice { narration, player, chara, director }

/// 1画面ぶんの文。
class NoahLine {
  final NoahVoice voice;
  final String text;

  /// 所長など、キャストではない人の表示名。
  final String who;

  const NoahLine(this.voice, this.text, {this.who = ''});
}

/// 主人公の性別。台詞は同一だが、一人称と呼ばれ方だけ変える。
enum NoahGender { male, female, none }

extension NoahGenderLabel on NoahGender {
  String get labelJa => switch (this) {
        NoahGender.male => '男性',
        NoahGender.female => '女性',
        NoahGender.none => 'どちらでもない',
      };

  /// 主人公の一人称。
  String get pronounJa => switch (this) {
        NoahGender.male => 'おれ',
        NoahGender.female => 'わたし',
        NoahGender.none => 'じぶん',
      };
}

/// 恋愛対象の絞り込み。
enum NoahPreference { men, women, all }

extension NoahPreferenceLabel on NoahPreference {
  String get labelJa => switch (this) {
        NoahPreference.men => '男性',
        NoahPreference.women => '女性',
        NoahPreference.all => 'どちらも',
      };

  List<NoahCharacter> filter(List<NoahCharacter> all) => switch (this) {
        NoahPreference.men => [for (final c in all) if (c.male) c],
        NoahPreference.women => [for (final c in all) if (!c.male) c],
        NoahPreference.all => all,
      };
}

/// 所長の名前。
///
/// ⚠️ **この物語のいちばん大事な一語**。
/// 所長は船に乗らないので、覚醒のたびに顔を見て呼び直す機会が無い。
/// だから五百人のうち、この人の名前だけが先に薄くなる——という筋が
/// [kNoahForgot] → [kNoahBeforeResult] で回収される。
/// 表示は基本 `所長` のままにして、名前を出す場所を絞ること。
/// どこでも出していると、忘れる場面も思い出す場面も効かなくなる。
const String kNoahDirectorName = '土倉 源三';

/// 序章。太陽が膨らみ、大池町から箱舟が発つまで。
const List<NoahLine> kNoahPrologue = [
  // ⚠️ 年代を「五十億年後」と書かないこと。
  //    Schröder & Smith (2008) では、太陽が赤色巨星分枝の先端に達するのは
  //    約76億年後。五十億年後はまだ主系列の終わりごろで、空は埋まらない。
  //    しかも同論文は「現在の軌道半径が1.15 AU 以上でないと生き残れない」
  //    ＝地球は呑まれる、と結論している。だから“呑まれる直前”に出る。
  NoahLine(NoahVoice.narration, '——太陽が、いちばん大きくなる年。'),
  NoahLine(NoahVoice.narration, '空は、赤い。'),
  NoahLine(NoahVoice.narration,
      '水素を使い切った星は膨らみ、空の半分を占めていた。'
      '水星と金星はもう無い。'),
  NoahLine(NoahVoice.narration,
      '地球はまだ呑まれずにいる。だが地表は鉛が溶ける温度になり、'
      'この軌道が残る保証も、もう無い。'),
  NoahLine(NoahVoice.narration,
      '人類は、横浜・戸塚区大池町の地下三キロに潜っている。'),
  NoahLine(NoahVoice.director, 'よく集まってくれた。', who: '所長'),
  NoahLine(NoahVoice.director,
      'ここは昔、ゴルフ場だった。十八ホール、七十万平方メートル。'
      '平らで、水があって、道がある。発射場にちょうどよかった。',
      who: '所長'),
  NoahLine(NoahVoice.director, '十八番グリーンの真下に、サイロを掘った。', who: '所長'),
  // ⚠️ 実在の天体。断定しないこと。
  //    確定しているのは「水素に富む大気ではない（>10σ で棄却）」まで。
  //    窒素大気は 2.3σ、水蒸気は約3σ の“兆候”にとどまる（Cadieux et al. 2024）。
  //    2026年に地上のマゼラン望遠鏡+WINEREDがヘリウム流出を検出している（Science）。
  //    「水がある」と言い切ると観測より先に行ってしまうので、賭けとして書く。
  NoahLine(NoahVoice.director,
      '行き先は四十八・九光年先、LHS 1140 b。'
      '赤色矮星をまわる、岩の惑星だ。',
      who: '所長'),
  NoahLine(NoahVoice.player, '……水は、あるんですか'),
  NoahLine(NoahVoice.director,
      'あるかもしれん、という段階だ。'
      'ガスの塊でないことは分かっている。大気を保っていることも。',
      who: '所長'),
  NoahLine(NoahVoice.director,
      'だが窒素の海があるかどうかは、まだ兆しが見えているだけだ。', who: '所長'),
  NoahLine(NoahVoice.player, '……賭けなんですね'),
  NoahLine(NoahVoice.director, 'ああ。人類で一番大きな賭けだ。', who: '所長'),
  NoahLine(NoahVoice.player, '……四十九光年。どれくらいかかるんですか'),
  NoahLine(NoahVoice.director,
      '光の十五パーセントで、三百三十年。眠りながら渡る。', who: '所長'),
  NoahLine(NoahVoice.narration, 'ざわめき。誰かが息を吸う音。'),
  NoahLine(NoahVoice.director, 'ただし、ひとつ問題がある。', who: '所長'),
  NoahLine(NoahVoice.director,
      '長期の冷凍睡眠から覚めると、記憶が欠ける。'
      'それも、いちばん先に消えるのが——',
      who: '所長'),
  NoahLine(NoahVoice.director, '人の、名前だ。', who: '所長'),
  NoahLine(NoahVoice.narration,
      '船には五百人が乗る。目覚めたとき、隣が誰か分からない五百人。'),
  NoahLine(NoahVoice.director,
      'だから君たちの仕事は、研究だけじゃない。', who: '所長'),
  NoahLine(NoahVoice.director, '覚えることだ。名前を。全員ぶん。', who: '所長'),
];

/// 🪑 定員の宣告。「さよならの手紙」の章。
///
/// 定員カウンターは画面の右上にずっと出ているが、
/// **なぜ12名なのか**を物語の中で一度も言っていなかった。
/// ここで言っておかないと、数字が増えても嬉しくない。
const List<NoahLine> kNoahCapacityScene = [
  NoahLine(NoahVoice.director, 'もうひとつ、先に言っておく。', who: '所長'),
  NoahLine(NoahVoice.director, 'この船に乗れるのは、十二名だ。', who: '所長'),
  NoahLine(NoahVoice.narration, '——誰も、声を出さなかった。'),
  NoahLine(NoahVoice.player, '……十二人。地下にいるのは、一万人以上いますよね'),
  NoahLine(NoahVoice.director,
      '差別でも、抽選でもない。ただの物理だ。', who: '所長'),
  NoahLine(NoahVoice.director,
      '冷凍睡眠から戻れるのが四割。生態系の物質収支が閉じない。'
      '推進剤の質量比が許さない。三つのうちひとつでも崩れれば、'
      '船はただの棺になる。',
      who: '所長'),
  NoahLine(NoahVoice.director,
      'だから計画の主役は人間じゃない。受精卵一万個と、人工子宮だ。', who: '所長'),
  NoahLine(NoahVoice.director,
      '十二名は、その荷物を四十九光年運ぶための世話人にすぎん。', who: '所長'),
  NoahLine(NoahVoice.narration,
      '乗れないと決まった者は、乗る者に宛てて手紙を一通書く。'),
  NoahLine(NoahVoice.narration,
      '到着後に開封され、新しい星の最初の図書館に収められる。'
      'それが、残る側に許されたただひとつの渡航手段だった。'),
  NoahLine(NoahVoice.narration, '——「さよならの手紙」と呼ばれている。'),
  NoahLine(NoahVoice.narration,
      '科学者たちも、全員が書いていた。技術者の枠は多く見ても四つ。'
      '八人のうち半分は、自分が作った船を見送る側にまわる。'),
  NoahLine(NoahVoice.director, 'だが、この数字は動く。', who: '所長'),
  NoahLine(NoahVoice.director,
      '研究がひとつ通るたび、乗れる人数は増える。'
      '冷凍睡眠が確かになれば百八名。生態系が閉じれば三百名。',
      who: '所長'),
  NoahLine(NoahVoice.director,
      '推進と減速の両方が成立すれば——五百名。全員だ。', who: '所長'),
  // ⚠️ 主人公の一人称は画面側が [NoahGender.pronounJa] で足すので、
  //    セリフ本文には「ぼく」「わたし」を書かないこと（二重になる）
  NoahLine(NoahVoice.player, '……何をすれば、いいんですか'),
  NoahLine(NoahVoice.director, '覚えろ。', who: '所長'),
  NoahLine(NoahVoice.director,
      '君が思い出せた数だけ、この船は大きくなる。', who: '所長'),
  NoahLine(NoahVoice.narration, '——所長は、名簿の綴りを机に置いた。'),
  NoahLine(NoahVoice.narration, 'まだ十二行しか埋まっていない。'),
  NoahLine(NoahVoice.director,
      'これは君が持っていけ。書くのも、読むのも、君だ。', who: '所長'),
  NoahLine(NoahVoice.player, '……所長は、乗らないんですか'),
  NoahLine(NoahVoice.narration, '答えは返ってこなかった。'),
  NoahLine(NoahVoice.narration,
      '名刺は八十枚刷られた。八人に十枚ずつ。計算はぴったり合う。'),
  NoahLine(NoahVoice.narration, 'この人のぶんだけ、一枚も無い。'),
  NoahLine(NoahVoice.director, '$kNoahDirectorName だ。', who: '所長'),
  NoahLine(NoahVoice.director, '……覚えなくていい。渡す名刺も無い', who: '所長'),
];

/// 🕳 いちばん大事な名前を落とす章。
///
/// 記憶テストで4人を思い出したあとに置く。
/// **覚えていた直後に、覚えていなかったことが分かる**のがこの章の役目なので、
/// 順番を入れ替えないこと。
const List<NoahLine> kNoahForgot = [
  NoahLine(NoahVoice.narration, '——テストのあと、ふと手が止まる。'),
  NoahLine(NoahVoice.narration,
      '目が覚めるたび、名簿を頭から順に呼ぶことにしていた。'
      '台帳は開かない。開いたら負けだと思っている。'),
  NoahLine(NoahVoice.narration, '一番から、四百九十九番まで。詰まらなかった。'),
  NoahLine(NoahVoice.narration, 'そして、五百番目で止まった。'),
  NoahLine(NoahVoice.narration, '顔は出る。白髪。分厚い手。曲がった襟。'),
  NoahLine(NoahVoice.narration,
      '声も出る。「中国四千年の歴史？ 可愛いもんだ」。'
      '「本日のホール、パー4」。'),
  NoahLine(NoahVoice.narration, '十八番グリーンの照明。机に置かれた、名簿の綴り。'),
  NoahLine(NoahVoice.narration, '全部ある。'),
  NoahLine(NoahVoice.narration, '名前だけが、無い。'),
  NoahLine(NoahVoice.player, '……うそだろ'),
  NoahLine(NoahVoice.chara, 'ああ、それか。理屈は簡単だ'),
  NoahLine(NoahVoice.chara,
      'この船の四百九十九人は、二十八年ごとに目の前に出てくる。'
      '顔を見て、声を聞いて、名前で呼ぶ。そのたびに塗り直される'),
  NoahLine(NoahVoice.chara, 'あの人は、乗っていない'),
  NoahLine(NoahVoice.chara, '塗り直す機会が、一度も無かった'),
  NoahLine(NoahVoice.narration,
      '——いちばん大事に持っていたつもりのものが、いちばん先に薄くなった。'),
  NoahLine(NoahVoice.narration, '持っていただけで、使っていなかったからだ。'),
  NoahLine(NoahVoice.player, '……調べれば、船の記録に載ってます'),
  NoahLine(NoahVoice.chara, '載っている。三秒で済む'),
  NoahLine(NoahVoice.player, '調べて出てきた名前は、思い出したことになりません'),
  NoahLine(NoahVoice.chara, '感傷だな'),
  NoahLine(NoahVoice.player, 'はい'),
  NoahLine(NoahVoice.chara, '……いい感傷だ。付き合ってやる'),
  NoahLine(NoahVoice.narration,
      'その日から、船の記録の人事の欄に鍵がかかった。'
      '外せるのは、医師ひとり。'),
  NoahLine(NoahVoice.narration,
      'そして——五百人に、ひとつだけ頼んで回ることになる。'),
  NoahLine(NoahVoice.narration, '「すれ違ったら、相手を名前で呼んでください」。'),
  NoahLine(NoahVoice.narration,
      '理由は言えなかった。自分が一人ぶん失くしたとは、'
      'どうしても言えなかったからだ。'),
  NoahLine(NoahVoice.narration,
      'それでも全員がやった。うるさくて、少し滑稽で、'
      '二百年近く誰も欠かさなかった。'),
];

/// 名刺交換の前口上。
const List<NoahLine> kNoahBeforeMeeting = [
  NoahLine(NoahVoice.narration, '——顔合わせが始まった。'),
  NoahLine(NoahVoice.narration,
      '全員が名刺を持っている。紙ではない。'
      '船内の通信IDと、所属と、趣味まで刷ってある。'),
  NoahLine(NoahVoice.narration,
      '「趣味まで書くのは、思い出す手がかりを増やすためです」——'
      '白川医師はそう言った。'),
  NoahLine(NoahVoice.narration, '名刺を見られるのは、一度きり。'),
];

/// 冷凍睡眠に入る前夜。
const List<NoahLine> kNoahBeforeSleep = [
  NoahLine(NoahVoice.narration, '出発の前夜。'),
  NoahLine(NoahVoice.narration,
      'テニスコートの壁に、誰かが爪で「また明日」と刻んでいた。'),
  NoahLine(NoahVoice.narration, 'その下に、また誰かが同じ言葉を刻む。'),
  NoahLine(NoahVoice.narration, '順番に、全員が。'),
  NoahLine(NoahVoice.player, '……三百三十年後の「また明日」か'),
  NoahLine(NoahVoice.narration,
      '十八番グリーンが割れ、箱舟「ノア」がせり上がる。'),
  NoahLine(NoahVoice.narration,
      '大池の水が霧になって噴き上がり、蒸気の幕が音を吸った。'),
  NoahLine(NoahVoice.director,
      '本日のホール、パー4。グリーンまでの距離——四十九光年。', who: '所長'),
  NoahLine(NoahVoice.narration, 'ポッドの蓋が閉じる。'),
];

/// 目覚め。ここから記憶テストが始まる。
const List<NoahLine> kNoahAwake = [
  NoahLine(NoahVoice.narration, '——三百三十年。'),
  NoahLine(NoahVoice.narration, '蓋が開く。冷たい空気。'),
  NoahLine(NoahVoice.narration, '天井が見える。自分の名前は、言える。'),
  NoahLine(NoahVoice.player, '（……じゃあ、あの人は？）'),
  NoahLine(NoahVoice.narration, '隣のポッドから、誰かが起き上がる。'),
];

/// 🛰 航行中の危機。先遣プローブが黙る。
///
/// 減速の山場（[kNoahClimax]）の前に、もうひとつ引っかかりを置く。
/// **引き返せない**ことをここで確定させておくと、
/// 減速の成否がそのまま全員の生死になる。
const List<NoahLine> kNoahMidVoyage = [
  NoahLine(NoahVoice.narration, '——航行、百六十三年目。'),
  NoahLine(NoahVoice.narration,
      '八十年先に出した先遣プローブ「ヨハネ」からの定時信号が、途絶えた。'),
  NoahLine(NoahVoice.chara, '大気モデルが外れている可能性がある'),
  NoahLine(NoahVoice.chara, '窒素が無ければ、こちらの菌は根づかない'),
  NoahLine(NoahVoice.player, '……引き返すことは'),
  NoahLine(NoahVoice.chara, 'できない'),
  NoahLine(NoahVoice.chara,
      '減速に使う磁気セイルは、あの星の恒星風でしか働かない。'
      'ここで止まる手段は、無い'),
  NoahLine(NoahVoice.narration, '沈黙。'),
  NoahLine(NoahVoice.chara, 'なら、外れていた場合の菌も作る'),
  NoahLine(NoahVoice.chara, 'あと百六十年ある。四十年で一系統、四系統は間に合う'),
  NoahLine(NoahVoice.narration,
      '——「ヨハネ」の沈黙の理由が分かるのは、到着の直前になる。'),
  NoahLine(NoahVoice.narration,
      'プローブは壊れていなかった。自己複製する機械が増えすぎて、'
      '送信アンテナごと基礎材に変えてしまっていた。'),
  NoahLine(NoahVoice.narration, '成功しすぎた結果の、沈黙だった。'),
];

/// 減速危機。全員が同時に動く場面。
const List<NoahLine> kNoahClimax = [
  NoahLine(NoahVoice.narration, '減速フェーズ、開始。'),
  NoahLine(NoahVoice.narration,
      '直径数百キロの磁気セイルを開き、恒星風を受けて止まる。'
      'これに失敗すると、船は星を素通りして虚空へ出る。'),
  NoahLine(NoahVoice.narration, 'セイル展開——七十三パーセントで停止。'),
  NoahLine(NoahVoice.chara, '窓は四分。四分で開く'),
  NoahLine(NoahVoice.chara, '融合炉の出力、ぜんぶセイルに回す'),
  NoahLine(NoahVoice.chara, 'ロボット群を船外へ。全員、帰す'),
  NoahLine(NoahVoice.chara, '生態系を最小消費に。命は、守る'),
  NoahLine(NoahVoice.chara, '右舷、三度だけ傾けろ。熱がもたない'),
  NoahLine(NoahVoice.chara, '息を止めて。大丈夫だ'),
  NoahLine(NoahVoice.narration, 'セイル、百パーセント展開。'),
  NoahLine(NoahVoice.narration, '減速、成功。'),
  NoahLine(NoahVoice.narration,
      '——窓の外に、赤い小さな太陽と、青黒い海の惑星があった。'),
  NoahLine(NoahVoice.narration,
      '着陸前に、もう一度だけ確かめておきたいことがある。'),
];

/// デートの場所。船内の設備は全部、生きるための装置でもある。
class NoahDate {
  final String place;
  final String flavor;
  const NoahDate(this.place, this.flavor);
}

const List<NoahDate> kNoahDates = [
  NoahDate('人工河川',
      'この川の水の九十九パーセントは、三百年前に誰かが飲んだ水だという。循環している。'),
  NoahDate('フードコート',
      '藻類のステーキとコオロギの天ぷら。醤油だけは地球から持ってきた酵母を継ぎ足している。'),
  NoahDate('カラオケ',
      '船の回転数と共鳴する曲があるらしく、特定の音程で床が微かに震える。'),
  NoahDate('百貨店',
      '船の中に新品は無い。全部リサイクル素材だ。だから、直す職人がいちばん偉い。'),
  NoahDate('テニスコート',
      '重力は半分。球はゆっくり落ちて、コリオリの力でわずかに曲がる。'),
  NoahDate('観測デッキ',
      '窓の外は、ただ黒い。星は動かない。三百三十年、ほとんど同じ景色だ。'),
  NoahDate('旧フェアウェイの記録映像',
      '発射の朝の映像。十八番のピンフラッグだけが、まだ立っている。'),
];

// ── 🔍 船内の小さな謎 ──────────────────────────────

/// 船の中で、誰かが毎日ひそかに続けていること。
///
/// **答えはすべて [NoahCharacter.regret] に繋がっている**。
/// デートで心残りを聞いていれば解ける、という作りにしてある。
/// 3択の顔ぶれは他のキャラなので、ここでも「混ざっている」感触が出る。
///
/// ⚠️ 犯人探しではない。誰も悪いことをしていない。
/// 見出しやセリフを足すときも、責める調子にはしないこと。
class NoahMystery {
  /// 続けている人。
  final String charaId;

  /// 謎の見出し。
  final String title;

  /// 気づくまでの地の文。
  final String scene;

  /// 種明かし。心残りとの繋がりをここで言う。
  final String answer;

  const NoahMystery({
    required this.charaId,
    required this.title,
    required this.scene,
    required this.answer,
  });
}

const List<NoahMystery> kNoahMysteries = [
  NoahMystery(
    charaId: 'hibino',
    title: '消灯後の工作室で、電気炉だけが温まっている',
    scene: '工作室の電気炉に、夜だけ火が入る。'
        '成形物は何も入っていない。空焚きだ。\n'
        '記録を見ると、温度の上げ下げが妙に不規則で、'
        '途中でわざと弱める時間が挟まっている。',
    answer: '備前の登り窯の温度カーブを、そのまま再現していた。\n'
        '火を強くしすぎると割れるから、途中で弱める。'
        '実家の窯焚きの手順そのものだ。\n\n'
        '「ただいま」を言えないまま出てきたから、'
        '代わりに毎晩、父の火加減をなぞっている。',
  ),
  NoahMystery(
    charaId: 'kiryu',
    title: '談話室の碁盤の石が、毎朝ひとつ増えている',
    scene: '談話室の隅に碁盤が置いてある。誰も打っているところを見た人がいない。\n'
        'なのに毎朝、石がひとつだけ増えている。'
        '黒と白が、きちんと交互に。',
    answer: '相手の手番も、自分で打っていた。\n'
        '一日一手。三百三十年かけて、一局を打ち切るつもりでいる。\n\n'
        '「一緒に碁を打とう」と言ってくれた姉の誘いを、'
        '断り続けたまま船に乗った。'
        'いまは、断らずに打っている。',
  ),
  NoahMystery(
    charaId: 'mizuhara',
    title: '食堂の醤油だけ、補給記録に載っていない',
    scene: '船の中の物は、一滴残らず収支表に載っている。'
        '載っていなければ、どこかで漏れている。\n'
        'ところが食堂の「特製醤油」だけ、'
        '入庫の記録が三百年ぶん、どこにも無い。',
    answer: '補給していないから、記録が無かった。継ぎ足していただけだ。\n\n'
        '祖母のぬか床は、塩の収支が合わなくて船に持ち込めなかった。'
        'だから乳酸菌と酵母だけを分けて、醤油として起こし直した。\n\n'
        '祖母の六十年に、船の三百三十年を継ぎ足している。',
  ),
  NoahMystery(
    charaId: 'tachibana',
    title: '観測デッキの鉢に、毎朝だれかが水をやっている',
    scene: '観測デッキの隅に、鉢がひとつ置いてある。'
        '閉じた生態系の収支表に載っていない、規格外の植物だ。\n'
        '当直のロボットへの引き継ぎ書には、一行だけ書いてある。\n'
        '——「量は多すぎないこと。こいつは、待つのが好きな株なので」',
    answer: '地球に残した妻が、最後まで育てていた株の分け身だった。\n\n'
        '「二人の庭を作る」という約束は、間に合わなかった。'
        '墓に水をやることも、ついにできなかった。\n\n'
        'だから三百三十年、毎朝この鉢に水をやっている。',
  ),
  NoahMystery(
    charaId: 'hoshino',
    title: '観測窓の、いちばん何も無い方角にカメラが向いている',
    scene: '船の望遠カメラが、毎晩きまった方角を向く。\n'
        '進行方向でもなければ、目的地でもない。'
        '撮っても何も写らない、ただ黒いだけの方角だ。',
    answer: '船が出てきた方角だった。\n'
        '四十九光年ぶん離れると、太陽はもう星の一粒にもならない。'
        'だから何も写らない。\n\n'
        '「本当の星空を見せる」と祖父に約束したまま、'
        '地上の空はとうに赤く濁ってしまった。\n'
        '見せられなかったぶんを、毎晩ここから撮り続けている。',
  ),
  NoahMystery(
    charaId: 'iwao',
    title: 'カラオケの掲示板に、匿名の俳句が一句ずつ増える',
    scene: '掲示板に、誰のものとも書かれていない句が貼られる。'
        '目覚めるたびに、一句だけ。\n'
        '達筆で、素っ気なくて、決して名前が入っていない。\n'
        '——並べてみると、季語が全部おなじだった。',
    answer: '全句に「山」が入っていた。船に山は無い。\n\n'
        '若いころ、開発で山をひとつ潰した。'
        '標高三百十二メートル、名前の付いていない山だった。'
        '名前が無かったから、誰も反対しなかった。\n\n'
        '故郷の山に最後に登れなかったぶんを、句で登り直している。',
  ),
  NoahMystery(
    charaId: 'kusunoki',
    title: '誰も使っていない周波数に、毎晩ノイズが乗る',
    scene: '船の通信帯のうち、いちばん端の周波数は空いている。'
        '割り当てが無いから、誰も使わない。\n'
        'その帯に、毎晩きまった時刻だけノイズが乗る。'
        '意味のある信号ではない。ただの雑音だ。\n'
        'なのに、聞いていると笑い方のクセのようなものが混じって聞こえる。',
    answer: '兄のラジオを、鳴らし続けていた。\n\n'
        '真空管の一本がどうしても手に入らなくて、'
        '最後まで直せないまま兄を見送った。\n'
        '直しきれない機械は、鳴らしておくしかない。\n\n'
        '「雑音でも、鳴っていれば壊れてはいない」——'
        'それが、修理屋の理屈だった。',
  ),
  NoahMystery(
    charaId: 'shirakawa',
    title: '冷凍ポッドの番号札が、毎晩ひとつだけ磨かれている',
    scene: 'ポッドは五百基。全部を磨くなら一晩で足りるはずだ。\n'
        'なのに毎晩、必ずひとつだけ磨かれている。'
        '五百日かけて一周し、また最初に戻る。',
    answer: '磨くとき、番号ではなく名前を声に出していた。\n\n'
        'かつて三人の患者を、冷凍で見送った。'
        'カルテには番号しか残していない。'
        '名前で呼ぶと、失敗が「人」になってしまうからだ。\n\n'
        '「大丈夫」と言えなかったぶん、名前だけは呼ぶことにした。'
        '五百人ぶん、順番に。',
  ),
];

/// 「この習慣は誰のものか」を当てる3択。
class NoahMysteryQuestion {
  final NoahMystery mystery;
  final NoahCharacter culprit;

  /// 表示順に並んだ選択肢（正解を1人含む）。
  final List<NoahCharacter> choices;

  const NoahMysteryQuestion({
    required this.mystery,
    required this.culprit,
    required this.choices,
  });

  bool isCorrect(NoahCharacter picked) => picked.id == culprit.id;
}

NoahMystery? noahMysteryFor(String charaId) {
  for (final m in kNoahMysteries) {
    if (m.charaId == charaId) return m;
  }
  return null;
}

/// [cast] の中から謎を [count] 個えらぶ。
///
/// 選択肢は必ず**その周回に出てきた人**から作る。
/// 会っていない人を混ぜると、消去法で当たってしまって謎にならない。
List<NoahMysteryQuestion> buildNoahMysteries({
  required List<NoahCharacter> cast,
  Random? random,
  int count = 2,
  int choiceCount = 3,
}) {
  final rng = random ?? Random();
  // 3択ぶんの顔ぶれが揃わないなら、謎そのものを出さない
  if (cast.length < choiceCount) return const [];

  final candidates = [
    for (final c in cast)
      if (noahMysteryFor(c.id) != null) c,
  ]..shuffle(rng);

  final out = <NoahMysteryQuestion>[];
  for (final culprit in candidates.take(count)) {
    final others = [
      for (final c in cast)
        if (c.id != culprit.id) c,
    ]..shuffle(rng);

    final choices = [culprit, ...others.take(choiceCount - 1)]..shuffle(rng);
    out.add(NoahMysteryQuestion(
      mystery: noahMysteryFor(culprit.id)!,
      culprit: culprit,
      choices: choices,
    ));
  }
  return out;
}

// ── 乗船定員：覚えるほど、助かる人が増える ──────────────

/// 定員の節目。
///
/// 最初の計画は「受精卵だけを送る」で、世話人12名しか乗れなかった。
/// 研究が進むほど乗れる人数が増える——という筋を、
/// **プレイヤーが思い出せた数**に結びつける。
/// 覚えることが人を救う、というのがこの物語の主題そのものなので、
/// 数字が動くところを画面に出す。
const List<int> kNoahCapacitySteps = [12, 108, 300, 500];

/// 節目に届いたときの見出しと、その根拠になった研究。
const List<String> kNoahCapacityReasons = [
  '受精卵と世話人だけの計画',
  '冷凍睡眠の見通しが立った',
  '閉じた生態系が回る計算になった',
  '推進と減速の両方が成立した',
];

/// [correct]問思い出せたときの乗船定員。
///
/// 全問正解で500名（全員）に届くようにしている。
int noahCapacityFor(int correct, int total) {
  if (total <= 0) return kNoahCapacitySteps.first;
  final ratio = correct / total;
  if (ratio >= 0.999) return kNoahCapacitySteps[3];
  if (ratio >= 0.66) return kNoahCapacitySteps[2];
  if (ratio >= 0.33) return kNoahCapacitySteps[1];
  return kNoahCapacitySteps.first;
}

int noahCapacityStepIndex(int correct, int total) =>
    kNoahCapacitySteps.indexOf(noahCapacityFor(correct, total));

/// 🧠 研究にもとづく「覚え方」の話。
///
/// ⚠️ 断定しない。「〜とされる」「〜と言われている」で書き、
/// 出典を添える（`meta_strings.dart` の cognitiveDisclaimer と同じ方針）。
/// 文章はこのアプリのオリジナル。外部記事の引き写しはしない。
class NoahNote {
  final String title;
  final String body;
  final String source;
  const NoahNote(this.title, this.body, this.source);
}

const List<NoahNote> kNoahNotes = [
  NoahNote(
    '声に出すと、残りやすい',
    '聞いただけの言葉より、自分で声に出したり書いたりした言葉のほうが'
        'あとで思い出しやすい、という報告がある。'
        '名刺をもらったら、その場で一度「○○さん」と呼んでみる。'
        'それだけで手がかりが増えるとされている。',
    'MacLeod ら（2010）産出効果の研究',
  ),
  NoahNote(
    '思い出す練習が、いちばん効く',
    '同じ時間をかけるなら、繰り返し読むより、'
        '一度隠して思い出すほうが長く残るとされる。'
        'この船で毎回テストがあるのは、意地悪だからではない。',
    'Roediger & Karpicke（2006）テスト効果の研究',
  ),
  NoahNote(
    '名前だけが、覚えにくい',
    '同じ「田中」でも、職業としての田中さんより、'
        '名字としての田中さんのほうが思い出しにくいという報告がある。'
        '名前はその人の何も説明しないので、引っかかる場所が少ないためだと言われる。',
    'McWeeny ら（1987）ベイカー・ベイカー錯誤',
  ),
  NoahNote(
    '意味をつけると、引っかかる',
    '顔の特徴や、聞いた話と結びつけて覚えたものは残りやすいとされる。'
        '「陶芸をやる日比野さん」「囲碁を打つ桐生さん」——'
        '趣味を先に聞くのは、名前をひとりにしないためでもある。',
    'Craik & Tulving（1975）処理水準の研究',
  ),
  NoahNote(
    '自分に結びつけると、強くなる',
    '自分と関係づけて覚えた情報は、そうでない情報より'
        '思い出しやすいという報告がある。'
        '「この人とどこで会ったか」を一緒に覚えておくと、あとで効く。',
    'Rogers ら（1977）自己関連づけ効果',
  ),
  NoahNote(
    '間をあけて、もう一度',
    '一度で覚えきろうとするより、間をあけて思い出し直すほうが'
        '長持ちするとされている。三百三十年は、さすがに空けすぎだが。',
    'Ebbinghaus 以来の分散学習の研究',
  ),
  NoahNote(
    '覚えたら、眠る',
    '眠っているあいだに、その日おぼえたことが整理されて'
        '定着していくと考えられている。'
        '徐波と紡錘波のタイミングが揃うときに、'
        'その受け渡しが起きているという説がある。\n'
        'この船が眠りながら渡るのは、燃料の都合だけではない。',
    'Staresina（2024）睡眠中の記憶固定に関する総説',
  ),
  NoahNote(
    'どこで会ったかを、一緒に覚える',
    '思い出すときの手がかりは、覚えたときの状況と結びついているとされる。'
        'その人の名前だけを裸で覚えるより、'
        '「観測デッキで会った星野さん」と場所ごと覚えたほうが'
        'あとで引っかかりやすいと言われている。',
    'Godden & Baddeley（1975）文脈依存記憶の研究',
  ),
  NoahNote(
    'まちがえても、ためになる',
    '思い出そうとして外したあとに正解を知ると、'
        '最初から正解だけを見せられるより残りやすいことがある、'
        'という報告がある。\n'
        'この船のテストでまちがえても、無駄にはならないとされている。',
    'Kornell ら（2009）失敗を含む検索の効果',
  ),
];

/// 幕間「船内の小さな謎」の前口上。
const List<NoahLine> kNoahBeforeMystery = [
  NoahLine(NoahVoice.narration, '——航行のあいだ、船には妙な習慣がいくつかある。'),
  NoahLine(NoahVoice.narration,
      '当番表にも、収支表にも載っていない。'
      'なのに、何十年たっても途切れない。'),
  NoahLine(NoahVoice.narration,
      '誰がやっているのか、誰も名乗り出ない。'
      '悪いことではないので、追及する者もいない。'),
  NoahLine(NoahVoice.player, '……でも、心当たりならある'),
  NoahLine(NoahVoice.narration,
      '船内を歩いたとき、みんな心残りをひとつずつ話していった。'),
  NoahLine(NoahVoice.narration, 'あれを覚えていれば、たぶん分かる。'),
];

/// 「なぜ名前なのか」を所長が話す章。物語の主題をここで言う。
const List<NoahLine> kNoahWhyNames = [
  NoahLine(NoahVoice.player, 'ひとつ、聞いていいですか'),
  NoahLine(NoahVoice.player,
      '名前を覚えるのが、そんなに大事なんですか。'
      '記録は全部、船のデータベースにあるのに'),
  NoahLine(NoahVoice.director, 'ある。', who: '所長'),
  NoahLine(NoahVoice.director,
      'データベースは、誰が誰かを教えてくれる。'
      'だが、呼んではくれない。',
      who: '所長'),
  NoahLine(NoahVoice.director,
      '三百三十年後、五百人が同時に目を覚ます。'
      '全員が、記憶の一部を失っている。',
      who: '所長'),
  NoahLine(NoahVoice.director,
      'そこで最初に起きることは、パニックでも略奪でもない。', who: '所長'),
  NoahLine(NoahVoice.director, '沈黙だ。', who: '所長'),
  NoahLine(NoahVoice.director,
      '隣に誰かがいるのに、話しかけられない。名前を知らないから。', who: '所長'),
  NoahLine(NoahVoice.narration,
      '——所長は、しばらく黙っていた。'),
  NoahLine(NoahVoice.director,
      '名前を呼ばれると、人は自分がここにいると分かる。', who: '所長'),
  NoahLine(NoahVoice.director,
      'それだけのことだ。それだけのことが、五百人を集団にする。', who: '所長'),
  NoahLine(NoahVoice.director,
      'だから、覚えてくれ。一人でも多く。', who: '所長'),
  NoahLine(NoahVoice.director,
      '君が覚えた人数のぶんだけ、この船は大きくなる。', who: '所長'),
];

/// 🧠 意識の淘汰。三百年かけて、理論がひとつずつ落ちる章。
///
/// 地上（Cogitate Consortium 2025, Nature）では IIT と GNWT の
/// 敵対的共同研究が**勝者なし**で終わっている。それを船が終わらせる。
///
/// ⚠️ 決着の向きを変えないこと。
/// 残った三つ（GNWT / IIT / 電磁場仮説）は、どれも
/// 「二十八年ごとに意識が消えている＝十一回死んだ」に行き着く。
/// 量子論だけが no-cloning のおかげで「複製されていない＝同じもの」と言える。
/// **これが本作の「誰も死なない」に理由を与えている**ので、
/// ここを緩めると作品の背骨が抜ける。
const List<NoahLine> kNoahConsciousness = [
  NoahLine(NoahVoice.narration, '——減速の前に、もうひとつ終わった実験がある。'),
  NoahLine(NoahVoice.chara, 'この船は、意識を調べる装置としては異常です'),
  NoahLine(NoahVoice.chara,
      '五百人の意識が、二十八年ごとに十一回、'
      '完全に止まって、また動く。地上では誰にも作れない'),
  NoahLine(NoahVoice.player, '……それで、何か分かったんですか'),
  NoahLine(NoahVoice.chara, '地球では、決着がつきませんでした'),
  NoahLine(NoahVoice.chara,
      '意識の理論を二つ並べて、どちらが正しければ何が見えるかを'
      '先に約束させて、第三者に実験させる。'
      'それでも勝者は出なかった'),
  NoahLine(NoahVoice.chara, 'ここでは、二十九のうち二十五が落ちました'),
  NoahLine(NoahVoice.narration,
      '——止まっているあいだを語れない理論が、まず落ちた。'),
  NoahLine(NoahVoice.narration,
      '——脳の中だけで説明する理論が、次に落ちた。'
      '隣のポッドほど記憶がにじむ、という事実を説明できなかったからだ。'),
  NoahLine(NoahVoice.chara, '残ったのは三つ。どれも強い理論です'),
  NoahLine(NoahVoice.chara, '情報が広く放送されたら意識、という説'),
  NoahLine(NoahVoice.chara, '統合された情報の量が意識、という説'),
  NoahLine(NoahVoice.chara, '脳が生む電磁場そのものが意識、という説'),
  NoahLine(NoahVoice.narration, '——三つ目は、この船で直に否定された。'),
  NoahLine(NoahVoice.narration,
      '磁気セイルを開いた日、船内の電磁環境は桁で変わった。'
      'それでも、誰の意識にも何も起きなかった。'),
  NoahLine(NoahVoice.chara, '問題は、残った二つです'),
  NoahLine(NoahVoice.chara, '放送が止まれば、意識は無い'),
  NoahLine(NoahVoice.chara, '統合が消えれば、意識は無い'),
  NoahLine(NoahVoice.chara,
      'どちらでも同じ結論になる。'
      '——この船の全員は、十一回死んで、十一回生まれた'),
  NoahLine(NoahVoice.narration, '誰も、何も言わなかった。'),
  NoahLine(NoahVoice.chara,
      '「二度と誰も死なせない」と言った人は、もう十一回死なせている'),
  NoahLine(NoahVoice.chara, '毎晩磨かれていた五百枚は、墓標だったことになる'),
  NoahLine(NoahVoice.chara, '理屈は通っています。誰も反証できない'),
  NoahLine(NoahVoice.chara, '……ただ、私は受け入れる気がありませんでした'),
  NoahLine(NoahVoice.narration, '——三百年かけて測っていたものが、ひとつだけある。'),
  NoahLine(NoahVoice.narration,
      '隣り合ったポッドほど、記憶が混ざる。'
      'その混ざり方が、距離に応じて減っていく。'),
  NoahLine(NoahVoice.narration,
      'ポッドのあいだに配線は無い。遮蔽もされている。'
      '情報が渡る道が、どこにも無い。'),
  NoahLine(NoahVoice.chara, 'ガラス化した脳は、熱の雑音がほとんど消えています'),
  NoahLine(NoahVoice.chara,
      'その状態でなら、近くに置かれたものどうしに'
      '相関が残る。にじみは、その跡です'),
  NoahLine(NoahVoice.player, '……名前を呼ぶと減るのは'),
  NoahLine(NoahVoice.chara, '呼ばれた状態は、繰り返し測られている'),
  NoahLine(NoahVoice.chara, '測られたものは、相関から切り離される'),
  NoahLine(NoahVoice.narration,
      '——二百年、理由も言わずに全員に頼んで回っていたことに、'
      'ここでようやく理由がついた。'),
  NoahLine(NoahVoice.chara, 'あなたがやっていたのは、感傷じゃない'),
  NoahLine(NoahVoice.chara, '保全作業です'),
  NoahLine(NoahVoice.narration, '——そして、いちばん大事なことが出てくる。'),
  NoahLine(NoahVoice.chara, '量子の状態は、複製できません'),
  NoahLine(NoahVoice.chara, '元を壊さずにコピーを作ることは、原理的にできない'),
  NoahLine(NoahVoice.chara,
      'コピーされていないなら、'
      '二十八年の眠りは「死んで生まれ直した」ではありえない'),
  NoahLine(NoahVoice.chara, '戻ってきたのは、同じものです'),
  NoahLine(NoahVoice.chara, '——五百人は、一度も死んでいない'),
  NoahLine(NoahVoice.narration,
      'そして、この人が四十年抱えていた問いが、'
      '答えの出ないまま消えた。'),
  NoahLine(NoahVoice.narration, '「コピーされた意識は、本人か」'),
  NoahLine(NoahVoice.narration, 'コピーは作れない。作れないものについて訊いても、仕方がない。'),
  NoahLine(NoahVoice.chara, 'できるのは、移すことだけです'),
  NoahLine(NoahVoice.chara, '移せば、元は必ず壊れる。控えは残らない。二人にもならない'),
  NoahLine(NoahVoice.chara, '——引っ越し、と呼んでいたやつです'),
  NoahLine(NoahVoice.narration,
      '三百三十年前から、この人はそう言っていた。'
      '証明できるようになるまでに、三百三十年かかっただけだった。'),
];

/// 到着直前。定員を見せる前に、落とした名前を回収する。
///
/// ⚠️ **思い出すのではなく、口が先に動く**という決着にしてある。
/// 二百年ぶん毎晩繰り返したものは、もう「思い出す」ものではなくなっている、
/// という筋（手続き記憶のたとえ）。ここを「頑張って思い出した」に直すと、
/// [kNoahForgot] で「使っていなかったから薄くなった」と言ったことと矛盾する。
const List<NoahLine> kNoahBeforeResult = [
  NoahLine(NoahVoice.narration, '着陸準備。'),
  NoahLine(NoahVoice.narration,
      '窓の外で、赤い小さな太陽が海に映っている。'
      '昼と夜の境目——ターミネータの帯だけが、ちょうどいい温度をしていた。'),
  NoahLine(NoahVoice.narration, '降りる前に、ひとつだけ儀式が残っている。'),
  NoahLine(NoahVoice.chara, 'そろそろ鍵を外すぞ。名簿を読むのは、あんただ'),
  NoahLine(NoahVoice.narration,
      '端末が差し出される。見れば三秒で終わる。'),
  NoahLine(NoahVoice.narration, '——受け取らなかった。'),
  NoahLine(NoahVoice.narration, '一番から、四百九十九番まで。詰まらなかった。'),
  NoahLine(NoahVoice.narration, 'そして、五百番目。'),
  NoahLine(NoahVoice.narration,
      '二百年近く出てこなかった名前だ。いま出てくる理由は、ひとつもない。'),
  NoahLine(NoahVoice.narration, '息を吸う。'),
  NoahLine(NoahVoice.narration, '——考えるより先に、口が動いた。'),
  NoahLine(NoahVoice.player, kNoahDirectorName),
  NoahLine(NoahVoice.narration, '言ってから、自分で驚いた。'),
  NoahLine(NoahVoice.narration,
      '思い出したのではない。毎晩、そう言っていた。'
      'ただ、言っていることに気づいていなかっただけだ。'),
  NoahLine(NoahVoice.narration,
      '忘れていたのは名前ではなく、'
      '自分がそれを呼び続けていたという事実のほうだった。'),
  NoahLine(NoahVoice.chara, '……ほらな'),
  NoahLine(NoahVoice.chara, '思い出せないものと、身についたものは、別のところにある'),
  NoahLine(NoahVoice.chara, '——ああ。それから'),
  NoahLine(NoahVoice.chara, '大丈夫だったな'),
  NoahLine(NoahVoice.narration,
      '「大丈夫」と言えない医師が、その一言を使ったのは、これが最初だった。'),
  NoahLine(NoahVoice.narration, '——乗員名簿、読み上げ完了。'),
];

// ── 3択のときのセリフ ────────────────────────────────

/// 出題のときに相手が言うこと。
///
/// 「この人の名前は？」だけだと問題集になってしまう。
/// 相手のほうから話しかけてくる形にして、
/// **人に向かって思い出している**手ざわりを出す。
String noahAskLineJa(NoahCharacter c, NoahField field, bool first) {
  switch (field) {
    case NoahField.name:
      return first
          ? 'あ、起きた。……ねえ、わたしのこと、覚えてる？'
          : 'ひさしぶり。名前、出てくる？';
    case NoahField.affiliation:
      return 'ところで、わたしがどこの所属だったか、言える？';
    case NoahField.hobby:
      return '船を出る前、何が好きだって話したか、覚えてる？';
    case NoahField.commId:
      return '通信ID、まだ登録してくれてる？ ……番号、言ってみて';
    case NoahField.school:
      return 'わたしがどこの学生だったか。あの夜、話したよね';
  }
}

/// 正解したとき。相手ごとに少し口ぶりを変える。
String noahHitLineJa(NoahCharacter c) {
  switch (c.id) {
    case 'hibino':
      return '「……覚えてたんだ。うれしい。窯の火みたいだね、そういうの」';
    case 'kiryu':
      return '「正解。三百三十年、よく持ちましたね、その記憶」';
    case 'mizuhara':
      return '「よかった。わたし、忘れられてたらどうしようって」';
    case 'tachibana':
      return '「ありがとう。……なんだ、そんなに嬉しいものなんだな、呼ばれるのは」';
    case 'hoshino':
      return '「合格！ じゃあ次の星空、一緒に撮りに行こう」';
    case 'iwao':
      return '「ほう。……わしの名を覚えとる若いのがおるとはな」';
    case 'kusunoki':
      return '「へえ。ちゃんと届いてたんだ、わたしの声」';
    case 'shirakawa':
      return '「上出来だ。……記憶が残ってるなら、蘇生は成功だな」';
    default:
      return '「……覚えていてくれたんだ」';
  }
}

/// まちがえたとき。責めない。**別の人と混ざっている**ことを示す。
String noahMissLineJa(NoahCharacter c, String picked) {
  return '「ううん、それは——たぶん、別の人の話。$picked、って言ったよね」';
}

/// 🔍 謎が解けたときに、その人が言うこと。
///
/// 白状させるのではなく、**見つけてもらった**という書き方にする。
String noahMysteryHitLineJa(NoahCharacter c) {
  switch (c.id) {
    case 'hibino':
      return '「……見てたんだ。恥ずかしいな。'
          '空焚きなんて、燃料の無駄なのにね」';
    case 'kiryu':
      return '「よく気づきましたね。'
          '——ええ、相手の手も私が打っています。ずるいですか？」';
    case 'mizuhara':
      return '「ばれた。収支表に載せると、'
          '『それ要りますか』って言われちゃうから」';
    case 'tachibana':
      return '「……よく分かったな。'
          '規格外の鉢がひとつ、それだけの話だ」';
    case 'hoshino':
      return '「あそこ、何も写らないんですよ。'
          'それでも、向けておきたくて」';
    case 'iwao':
      return '「季語で当てたか。……やるな、若いの」';
    case 'kusunoki':
      return '「聞こえてた？ よかった。'
          'わたしにしか聞こえてないのかと思ってた」';
    case 'shirakawa':
      return '「見られていたか。'
          '……別に、供養のつもりじゃない。手順のうちだ」';
    default:
      return '「……よく気づいたね」';
  }
}

/// 謎を外したとき。ここでも責めない。
String noahMysteryMissLineJa(NoahCharacter picked, NoahCharacter culprit) =>
    '「${picked.name}さんじゃないよ。'
    'その人にも心残りはあるけど、これは別の人のかたちだ」';

/// 出会いのとき、名刺を渡しながら言うこと。
String noahGreetLineJa(NoahCharacter c) {
  switch (c.id) {
    case 'hibino':
      return '「日比野です。炉をやってます。……よろしく」';
    case 'kiryu':
      return '「桐生です。意識の研究を。名前、覚えるの得意ですか？」';
    case 'mizuhara':
      return '「水原です。うちの子たち——受精卵カプセルの担当です」';
    case 'tachibana':
      return '「橘です。空気と水を回してます。あなたが吸ってるぶんも」';
    case 'hoshino':
      return '「星野未来です。未来って書いてミライ。祖父がつけました」';
    case 'iwao':
      return '「岩尾。山と、この星の地面を見とる」';
    case 'kusunoki':
      return '「楠です。ロボット担当。困ったら呼んでください」';
    case 'shirakawa':
      return '「白川です。あなたを眠らせて、起こす係です」';
    default:
      return '「${c.name}です。よろしく」';
  }
}
