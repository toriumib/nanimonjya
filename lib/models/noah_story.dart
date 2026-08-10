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
  String question(bool ja) => ja ? questionJa : questionEn;
  String label(bool ja) => ja ? labelJa : labelEn;

  /// 「〜は？」の見出し。
  String get questionJa => switch (this) {
        NoahField.name => 'この人の名前は？',
        NoahField.affiliation => 'この人の所属は？',
        NoahField.hobby => 'この人の趣味は？',
        NoahField.commId => 'この人の通信IDは？',
        NoahField.school => 'この人の学生時代は？',
      };

  String get questionEn => switch (this) {
        NoahField.name => 'What is their name?',
        NoahField.affiliation => 'What is their field?',
        NoahField.hobby => 'What is their hobby?',
        NoahField.commId => 'What is their comm ID?',
        NoahField.school => 'Where did they study?',
      };

  String get labelJa => switch (this) {
        NoahField.name => '名前',
        NoahField.affiliation => '所属',
        NoahField.hobby => '趣味',
        NoahField.commId => '通信ID',
        NoahField.school => '学生時代',
      };

  String get labelEn => switch (this) {
        NoahField.name => 'Name',
        NoahField.affiliation => 'Field',
        NoahField.hobby => 'Hobby',
        NoahField.commId => 'Comm ID',
        NoahField.school => 'School',
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

/// 結末。**どの結末でも誰も死なない・嫌な思いをする人もいない**。
enum NoahEnding {
  /// 好感度がはっきり1位の相手がいる。最愛の人とLHS 1140 bで結ばれる。
  happy,

  /// 2人以上が好感度1位で並んでいる（全員ではない）。
  /// みんなで子育てする大家族エンド。
  harem,

  /// 全員の好感度がぴったり同じ。500人の同窓会エンド。
  /// 子孫に「顔が似すぎて見分けつかない」と笑われる（恨まれるほどではない）。
  bitter,

  /// 誰の名前もほとんど覚えられなかった。
  /// 一人だけロケット同乗係として、穏やかに船と乗員のお世話をして過ごす。
  /// やがてマインドアップロードがロボットへ完了し、そのままお世話を続ける。
  lonely,
}

/// 結末の判定。
///
/// - 覚えた総量が少なすぎる → [NoahEnding.lonely]
/// - 全員が同じ好感度 → [NoahEnding.bitter]（同窓会エンド）
/// - 1位が2人以上で並んでいる（全員ではない）→ [NoahEnding.harem]
/// - 1位が2位より [leadNeeded] 以上リード → [NoahEnding.happy]
/// - それ以外（僅差） → [NoahEnding.bitter]
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
  final tiedAtTop = ranked.where((e) => e.value == top.value).length;

  if (tiedAtTop == ranked.length) {
    return NoahResult(ending: NoahEnding.bitter, totalAffection: total);
  }
  if (tiedAtTop >= 2) {
    return NoahResult(ending: NoahEnding.harem, totalAffection: total);
  }
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

/// 🎮 ADVの選択肢。プレイヤーが選ぶと好感度が変動する。
class NoahChoice {
  /// 選択肢の表示テキスト。
  final String text;

  /// 選んだ相手のID（どのキャラへの発言か）。
  /// null ならナレーション的な選択。
  final String? charaId;

  /// この選択肢を選んだときの好感度変化。
  final int affectionDelta;

  const NoahChoice({
    required this.text,
    this.charaId,
    this.affectionDelta = 0,
  });
}

/// 選択肢を含む行。[_script] の途中に埋め込んで使う。
/// [NoahLine] ではないので注意。画面側で専用にハンドルする。
class NoahChoicePoint {
  /// 誰に向けた選択か（表示用）。
  final String? charaId;

  /// 「どう答える？」のような前振り。
  final String prompt;

  /// 2〜4択。
  final List<NoahChoice> choices;

  const NoahChoicePoint({
    this.charaId,
    required this.prompt,
    required this.choices,
  });
}

/// スクリプトの1要素。通常のセリフ行か、選択肢か。
sealed class NoahScriptItem {
  const NoahScriptItem();
}
class _NoahLineItem extends NoahScriptItem {
  final NoahLine line;
  const _NoahLineItem(this.line);
}
class _NoahChoiceItem extends NoahScriptItem {
  final NoahChoicePoint choice;
  const _NoahChoiceItem(this.choice);
}

/// スクリプトを行と選択肢の混合リストに変換する。
List<NoahScriptItem> noahScriptItems({required List<NoahLine> lines, List<MapEntry<int, NoahChoicePoint>> choices = const []}) {
  final items = <NoahScriptItem>[];
  final choiceMap = <int, NoahChoicePoint>{for (final e in choices) e.key: e.value};
  for (var i = 0; i < lines.length; i++) {
    if (choiceMap.containsKey(i)) {
      items.add(_NoahChoiceItem(choiceMap[i]!));
    }
    items.add(_NoahLineItem(lines[i]));
  }
  return items;
}

/// 主人公の性別。台詞は同一だが、一人称と呼ばれ方だけ変える。
enum NoahGender { male, female, none }

extension NoahGenderLabel on NoahGender {
  String label(bool ja) => ja ? labelJa : labelEn;
  String pronoun(bool ja) => ja ? pronounJa : pronounEn;

  String get labelJa => switch (this) {
        NoahGender.male => '男性',
        NoahGender.female => '女性',
        NoahGender.none => 'どちらでもない',
      };

  String get labelEn => switch (this) {
        NoahGender.male => 'Male',
        NoahGender.female => 'Female',
        NoahGender.none => 'Neither',
      };

  /// 主人公の一人称。
  String get pronounJa => switch (this) {
        NoahGender.male => 'おれ',
        NoahGender.female => 'わたし',
        NoahGender.none => 'じぶん',
      };

  String get pronounEn => switch (this) {
        NoahGender.male => 'I',
        NoahGender.female => 'I',
        NoahGender.none => 'I',
      };
}

/// 恋愛対象の絞り込み。
enum NoahPreference { men, women, all }

extension NoahPreferenceLabel on NoahPreference {
  String label(bool ja) => ja ? labelJa : labelEn;

  String get labelJa => switch (this) {
        NoahPreference.men => '男性',
        NoahPreference.women => '女性',
        NoahPreference.all => 'どちらも',
      };

  String get labelEn => switch (this) {
        NoahPreference.men => 'Men',
        NoahPreference.women => 'Women',
        NoahPreference.all => 'All',
      };

  List<NoahCharacter> filter(List<NoahCharacter> all) => switch (this) {
        NoahPreference.men => [for (final c in all) if (c.male) c],
        NoahPreference.women => [for (final c in all) if (!c.male) c],
        NoahPreference.all => all,
      };
}

/// 序章。太陽が膨らみ、大池町から箱舟が発つまで。
const List<NoahLine> kNoahPrologue = [
  NoahLine(NoahVoice.narration, '西暦、五十億二千二十六年。'),
  NoahLine(NoahVoice.narration, '太陽は、赤い。'),
  NoahLine(NoahVoice.narration,
      '水素を使い切った星は膨らみ、空の三分の一を占めていた。'
      '水星と金星はもう無い。'),
  NoahLine(NoahVoice.narration,
      '地球はかろうじて呑まれずにいるが、地表は鉛が溶ける温度になった。'
      '海だった場所は、燐光を放つ溶岩の平原に変わっている。'),
  NoahLine(NoahVoice.narration,
      '人類は、横浜・戸塚区大池町の地下三キロに潜っている。'
      '最後の七十二万人が、かつてゴルフ場だった地面の下で肩を寄せ合っていた。'),
  NoahLine(NoahVoice.narration,
      'きみもその一人だ。地上の光も、風も、もう知らない。'),
  NoahLine(NoahVoice.director, 'よく集まってくれた。', who: '所長'),
  NoahLine(NoahVoice.director,
      'ここは昔、ゴルフ場だった。十八ホール、七十万平方メートル。'
      '平らで、水があって、道がある。発射場にちょうどよかった。',
      who: '所長'),
  NoahLine(NoahVoice.director, '十八番グリーンの真下に、サイロを掘った。', who: '所長'),
  NoahLine(NoahVoice.director,
      '行き先は四十九光年先、LHS 1140 b。'
      '赤色矮星をまわる、水のあるスーパーアースだ。',
      who: '所長'),
  NoahLine(NoahVoice.player, '……四十九光年。どれくらいかかるんですか'),
  NoahLine(NoahVoice.director,
      '光の十五パーセントで、三百三十年。眠りながら渡る。', who: '所長'),
  NoahLine(NoahVoice.narration, 'ざわめき。誰かが息を吸う音。'),
  NoahLine(NoahVoice.narration,
      '三百三十年。江戸開府から、きみたちの生まれるずっと前まで。'
      'そのあいだ、船はただの金属の塊になって星のあいだを滑る。'),
  NoahLine(NoahVoice.director, 'ただし、ひとつ問題がある。', who: '所長'),
  NoahLine(NoahVoice.director,
      '長期の冷凍睡眠から覚めると、記憶が欠ける。'
      'それも、いちばん先に消えるのが——',
      who: '所長'),
  NoahLine(NoahVoice.director, '人の、名前だ。', who: '所長'),
  NoahLine(NoahVoice.narration,
      '船には五百人が乗る。目覚めたとき、隣が誰か分からない五百人。'),
  NoahLine(NoahVoice.narration,
      '「誰か」のままだと、ひとは集団になれない。'
      '名前を失った五百人は、五百の孤独だ。'),
  NoahLine(NoahVoice.director,
      'だから君たちの仕事は、研究だけじゃない。', who: '所長'),
  NoahLine(NoahVoice.director, '覚えることだ。名前を。全員ぶん。', who: '所長'),
  NoahLine(NoahVoice.narration, '誰かが、小さく息を吐いた。'),
  NoahLine(NoahVoice.narration, '五百の名前——それは、五百の命の輪郭だ。'),
];

/// 🥶 無視されるシーン。名前を覚える意味を、体で知る。
///
/// 五百人のオリエンテーション。全員が名札をつけている。
/// 主人公は話しかけようとするが、誰にも気づかれない。
/// ——名前を呼ばれないと、人はいないのと同じなのだと、そのとき思い知る。
/// そのあと、ただ一人だけが振り返ってくれる。
const List<NoahLine> kNoahColdShoulder = [
  NoahLine(NoahVoice.narration, 'オリエンテーション。五百人が、旧テニスコートの広間に集まっている。'),
  NoahLine(NoahVoice.narration,
      '全員が名札をつけていた。ここでは名前が、その人のすべてだ。'),
  NoahLine(NoahVoice.player, '（……隣の人に、話しかけてみよう）'),
  NoahLine(NoahVoice.player, 'あの、どの研究班ですか'),
  NoahLine(NoahVoice.narration, '返事はなかった。相手は、だれか別の人と話している。'),
  NoahLine(NoahVoice.player, '……すみません、'),
  NoahLine(NoahVoice.narration,
      '今度は、声が届かなかった。広間のざわめきが、ひとりの言葉を埋める。'),
  NoahLine(NoahVoice.narration,
      '五百人のなかで、誰にも気づかれない。'
      '背中を誰かが押す。誰も、こちらを向かない。'),
  NoahLine(NoahVoice.narration,
      '——名前を呼ばれないと、人は消えたも同然なのだと、そのとき知った。'),
  NoahLine(NoahVoice.narration,
      'だから、なのか。全員の名前を覚えなければいけない理由が、'
      'ようやくからだの奥に落ちた。'),
  NoahLine(NoahVoice.narration, '忘れられることは、無視されることだ。'),
  NoahLine(NoahVoice.narration, 'そのあと。一人が、振り返った。'),
  NoahLine(NoahVoice.chara, '……さっき、話しかけてた？ ごめん、気づかなくて'),
  NoahLine(NoahVoice.narration,
      '——そのひとことが、妙に胸の奥に残った。'
      '見つけてもらえた、というあたたかさが。'),
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
  NoahLine(NoahVoice.narration, '順番に、全員が。五百の「また明日」が壁を埋めた。'),
  NoahLine(NoahVoice.narration,
      '地球に、明日は来ない。それでも、誰かが刻んだ言葉を、'
      '誰かがなぞる。その連なりが、集団というものだ。'),
  NoahLine(NoahVoice.player, '……三百三十年後の「また明日」か'),
  NoahLine(NoahVoice.narration,
      '十八番グリーンが割れ、箱舟「ノア」がせり上がる。'),
  NoahLine(NoahVoice.narration,
      '大池の水が霧になって噴き上がり、蒸気の幕が音を吸った。'
      'ゴルフ場は、発射の熱でいちど玻璃になった。'
      'それもすぐ、宇宙の黒に溶ける。'),
  NoahLine(NoahVoice.director,
      '本日のホール、パー4。グリーンまでの距離——四十九光年。', who: '所長'),
  NoahLine(NoahVoice.narration, 'ポッドの蓋が閉じる。冷たい眠りが、きみを包む。'),
  NoahLine(NoahVoice.narration, '次に目を開けたとき——覚えていられるだろうか。'),
];

/// 目覚め。ここから記憶テストが始まる。
const List<NoahLine> kNoahAwake = [
  NoahLine(NoahVoice.narration, '——三百三十年。'),
  NoahLine(NoahVoice.narration,
      '蓋が開く。冷たい空気。細胞が、ひとつずつ起きていく。'),
  NoahLine(NoahVoice.narration,
      '天井が見える。日付が表示されている。自分の名前は、言える。'),
  NoahLine(NoahVoice.narration,
      '「また明日」と刻んだ壁は、どこにもない。'),
  NoahLine(NoahVoice.player, '（……じゃあ、あの人は？）'),
  NoahLine(NoahVoice.narration, '隣のポッドから、誰かが起き上がる。'),
  NoahLine(NoahVoice.narration,
      '顔は、見覚えがある。でも——名前が、すぐに出てこない。'),
];

/// 減速危機。全員が同時に動く場面。
/// 通信が錯綜するなか、主人公の声は一度、誰にも届かない。
const List<NoahLine> kNoahClimax = [
  NoahLine(NoahVoice.narration, '減速フェーズ、開始。'),
  NoahLine(NoahVoice.narration,
      '直径数百キロの磁気セイルを開き、恒星風を受けて止まる。'
      'これに失敗すると、船は星を素通りして虚空へ出る。'),
  NoahLine(NoahVoice.narration, 'セイル展開——七十三パーセントで停止。'),
  NoahLine(NoahVoice.chara, '窓は四分。四分で開く'),
  NoahLine(NoahVoice.chara, '融合炉の出力、ぜんぶセイルに回す'),
  NoahLine(NoahVoice.player, '第三区画の温度、上がりすぎてます！'),
  NoahLine(NoahVoice.narration, '誰も、返事をしない。'),
  NoahLine(NoahVoice.narration, '——ちがう。聞こえていないのは、こちらの声だけじゃない。'),
  NoahLine(NoahVoice.narration, '全員が全員に叫んでいる。通信が、悲鳴の束になっている。'),
  NoahLine(NoahVoice.narration, 'また、五百人のなかで、ひとりだ。'),
  NoahLine(NoahVoice.player, '……第三区画、冷媒を回してください！'),
  NoahLine(NoahVoice.chara, '聞こえた。第三、冷媒まわす'),
  NoahLine(NoahVoice.narration, 'その一声で、肩の力が抜けた。'),
  NoahLine(NoahVoice.narration, '——オリエンテーションのときと、同じだ。'),
  NoahLine(NoahVoice.narration, 'ひとりが気づいてくれれば、それで、また立てる。'),
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

/// 到着直前、定員がどこまで伸びたかを見せる章の前口上。
const List<NoahLine> kNoahBeforeResult = [
  NoahLine(NoahVoice.narration, '着陸準備。'),
  NoahLine(NoahVoice.narration,
      '窓の外で、赤い小さな太陽が海に映っている。'
      '昼と夜の境目——ターミネータの帯だけが、ちょうどいい温度をしていた。'),
  NoahLine(NoahVoice.narration, '乗員名簿が読み上げられる。'),
];

// ── 3択のときのセリフ ────────────────────────────────

String noahAskLine(NoahCharacter c, NoahField field, bool first, bool ja) =>
    ja ? noahAskLineJa(c, field, first) : noahAskLineEn(c, field, first);
String noahHitLine(NoahCharacter c, bool ja) =>
    ja ? noahHitLineJa(c) : noahHitLineEn(c);
String noahMissLine(NoahCharacter c, String picked, bool ja) =>
    ja ? noahMissLineJa(c, picked) : noahMissLineEn(c, picked);
String noahGreetLine(NoahCharacter c, bool ja) =>
    ja ? noahGreetLineJa(c) : noahGreetLineEn(c);

/// 出題のときに相手が言うこと（Ja）。
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

String noahAskLineEn(NoahCharacter c, NoahField field, bool first) {
  switch (field) {
    case NoahField.name:
      return first
          ? 'Hey, you\'re awake… So, do you remember me?'
          : 'Long time. Can you remember my name?';
    case NoahField.affiliation:
      return 'So, can you tell me what my field was?';
    case NoahField.hobby:
      return 'Before we left, I told you what I love to do. Remember?';
    case NoahField.commId:
      return 'My comm ID — did you keep it registered?';
    case NoahField.school:
      return 'Where I went to school. We talked about it that night, remember?';
  }
}

String noahHitLineJa(NoahCharacter c) {
  switch (c.id) {
    case 'hibino': return '「……覚えてたんだ。うれしい。窯の火みたいだね、そういうの」';
    case 'kiryu': return '「正解。三百三十年、よく持ちましたね、その記憶」';
    case 'mizuhara': return '「よかった。わたし、忘れられてたらどうしようって」';
    case 'tachibana': return '「ありがとう。……なんだ、そんなに嬉しいものなんだな、呼ばれるのは」';
    case 'hoshino': return '「合格！ じゃあ次の星空、一緒に撮りに行こう」';
    case 'iwao': return '「ほう。……わしの名を覚えとる若いのがおるとはな」';
    case 'kusunoki': return '「へえ。ちゃんと届いてたんだ、わたしの声」';
    case 'shirakawa': return '「上出来だ。……記憶が残ってるなら、蘇生は成功だな」';
    default: return '「……覚えていてくれたんだ」';
  }
}

String noahHitLineEn(NoahCharacter c) {
  switch (c.id) {
    case 'hibino': return '"…You remembered. That makes me happy. It\'s like the fire in a kiln."';
    case 'kiryu': return '"Correct. You held onto that memory for 330 years. Impressive."';
    case 'mizuhara': return '"Oh, thank goodness. I was so afraid you\'d forgotten."';
    case 'tachibana': return '"Thank you. I didn\'t know… being called by name could feel this good."';
    case 'hoshino': return '"That\'s right! Let\'s go photograph the next starry sky together."';
    case 'iwao': return '"Well now. A young one who remembers this old man\'s name."';
    case 'kusunoki': return '"Huh. So my voice really did reach you."';
    case 'shirakawa': return '"Well done. If your memory survived… the revival was a success."';
    default: return '"…You remembered."';
  }
}

String noahMissLineJa(NoahCharacter c, String picked) {
  return '「ううん、それは——たぶん、別の人の話。$picked、って言ったよね」';
}

String noahMissLineEn(NoahCharacter c, String picked) {
  return '"No, that\'s… someone else. You said "$picked", didn\'t you?"';
}

String noahGreetLineJa(NoahCharacter c) {
  switch (c.id) {
    case 'hibino': return '「日比野です。炉をやってます。……よろしく」';
    case 'kiryu': return '「桐生です。意識の研究を。名前、覚えるの得意ですか？」';
    case 'mizuhara': return '「水原です。うちの子たち——受精卵カプセルの担当です」';
    case 'tachibana': return '「橘です。空気と水を回してます。あなたが吸ってるぶんも」';
    case 'hoshino': return '「星野未来です。未来って書いてミライ。祖父がつけました」';
    case 'iwao': return '「岩尾。山と、この星の地面を見とる」';
    case 'kusunoki': return '「楠です。ロボット担当。困ったら呼んでください」';
    case 'shirakawa': return '「白川です。あなたを眠らせて、起こす係です」';
    default: return '「${c.name}です。よろしく」';
  }
}

// ── 第2章「宇宙を織りなすもの」── 物理学者たちとの邂逅 ─────

/// 減速成功後、船はLHS 1140 bの周回軌道に入る。
/// 船内の量子重力研究所から、時空の構造そのものを研究する
/// 理論物理学者たちが姿を現す。
/// 彼らは「名前を覚えること」と「現実を観測すること」の
/// 関係を研究している——なぜなら、この宇宙では
/// 観測者が現実を決定するからだ。
///
/// 登場する概念:
/// - ミューオン（素粒子）と時空のゆらぎ
/// - エンタングルメントと空間の創発
/// - AdS/CFT対応（マルダセナ）
/// - フォンノイマン・エンタングルメント・エントロピー
/// - エルゴディック理論
/// - WIMP（暗黒物質）とウィンプ検出
/// - エフィーモフ状態
/// - ダーウィン的宇宙選択
const List<NoahLine> kNoahPhysics = [
  NoahLine(NoahVoice.narration, '惑星軌道、安定。'),
  NoahLine(NoahVoice.narration,
      'LHS 1140 b の海は、予想よりずっと青かった。'
      '赤色矮星の光を受けて、夕暮れが永遠に続いている。'),
  NoahLine(NoahVoice.narration,
      '船内の全システムが目覚めていく。'
      'その中に——誰も話したことのない区画があった。'),
  NoahLine(NoahVoice.director,
      '「量子重力研究所」……ここにいる連中は、'
      '船が飛んでいるあいだもずっと起きていた。'
      '冷凍睡眠を拒否して、三百三十年、研究を続けたんだ。',
      who: '所長'),
  NoahLine(NoahVoice.narration, '扉が開く。中は、星図と数式で埋まっていた。'),
  NoahLine(NoahVoice.narration,
      '壁一面に張られた紙。ホワイトボードに書かれた矢印。'
      'コーヒーの空き缶と、かじられたミュー粒子検出器。'),
  NoahLine(NoahVoice.chara,
      '——おや。新しい観測者が来たね。'),
  NoahLine(NoahVoice.narration,
      '振り返ったのは、白い髪の理論物理学者だった。'),
  NoahLine(NoahVoice.director,
      '紹介しよう。ミューオン異常の研究で名を残した、'
      '理論物理学者のトーマス・ナイジェル博士だ。',
      who: '所長'),
  NoahLine(NoahVoice.chara,
      '「ミューオンはね、標準模型のほころびなんだよ。'
      '磁気モーメントの値が、理論と合わない。'
      '重力子がミューオンに影響している証拠かもしれない。」'),
  NoahLine(NoahVoice.chara,
      '「この船の加速中に、私たちは面白いものを見つけた。'
      'エンタングルメントが——時空そのものを生み出している。」'),
  NoahLine(NoahVoice.narration,
      '——時空が、量子もつれから生まれる。'),
  NoahLine(NoahVoice.narration,
      'その理論は、マルダセナ——アルゼンチン出身の天才物理学者'
      'ファン・マルダセナ——の AdS/CFT 対応から始まった。'),
  NoahLine(NoahVoice.narration,
      '境界の量子論が、内部の時空のすべてを決める。'
      '宇宙は、ホログラムだ。'),
  NoahLine(NoahVoice.chara,
      '「それを発展させたのが、高柳 匡 博士の'
      'エンタングルメント・エントロピーの公式だ。'
      'フォンノイマンが考えた情報の尺度が、'
      '実はアインシュタイン方程式と等価だった。」'),
  NoahLine(NoahVoice.narration,
      '——情報＝時空。'),
  NoahLine(NoahVoice.chara,
      '「つまりね。名前を覚えることも、時空を織っているんだ。'
      '誰かの名前を呼ぶとき、あなたは文字通り、'
      '宇宙の構造を変えている。」'),
  NoahLine(NoahVoice.player, '名前を呼ぶことが……宇宙を？'),
  NoahLine(NoahVoice.chara,
      '「そう。観測が現実を決める——エルゴディックな系では、'
      'ひとつの軌道がすべての可能状態を覆う。'
      'ひとりの名前が、宇宙全部を含んでいるんだ。」'),
  NoahLine(NoahVoice.narration, '壁の数式が、かすかに光って見えた。'),
  NoahLine(NoahVoice.director,
      '「彼らは他にもいる。暗黒物質の狩人——'
      'ウィンプを探す村山 斉 博士のチームだ。」',
      who: '所長'),
  NoahLine(NoahVoice.chara,
      '「村山先生はウィンプ検出器を持ってきたんだ。'
      'この星の地下で、暗黒物質を捕まえようとしている。'
      '……いまごろ、地下で掘ってるよ。」'),
  NoahLine(NoahVoice.narration,
      'WIMP —— Weakly Interacting Massive Particle。'
      '宇宙の質量の85%を占める、見えない物質。'),
  NoahLine(NoahVoice.chara,
      '「見えないものを探すには、名前をつけるしかない。'
      '名前をつけた瞬間、それは"ある"んだ。」'),
  NoahLine(NoahVoice.narration,
      '——誰かが、「ファインマン」とつぶやいた。'),
  NoahLine(NoahVoice.chara,
      '「ああ、ファインマンはすごかった。'
      '経路積分って、つまり"すべての可能性が同時に起きている"んだ。'
      '僕たちは、そのひとつを見ているにすぎない。」'),
  NoahLine(NoahVoice.chara,
      '「スティーブン・ワインバーグは標準模型を作った。'
      '『重力ありの標準模型』と『なしの標準模型』——'
      'その境界こそが、いま僕たちが立っている場所だ。」'),
  NoahLine(NoahVoice.narration,
      '部屋の奥で、若い研究者が手を挙げた。'),
  NoahLine(NoahVoice.chara,
      '「エフィーモフ状態って知ってる？'
      '3つの粒子が、本来ありえないくらい遠くで束縛される。'
      '宇宙がスケール不変だから起きることなんだ。'
      'これもね、名前をつける前の状態にすごく似てる。」'),
  NoahLine(NoahVoice.narration,
      '——ダーウィンは言った。種は進化すると。'),
  NoahLine(NoahVoice.narration,
      'だがここでは、**宇宙そのもの**が進化している。'),
  NoahLine(NoahVoice.chara,
      '「リー・スモーリンの"ダーウィン的宇宙選択"を聞いたことがあるか？'
      'ブラックホールの先で新しい宇宙が生まれ、'
      '物理定数が自然選択される。'
      '僕たちは、膨大な宇宙のたったひとつの枝で、名前を呼び合っている。」'),
  NoahLine(NoahVoice.narration,
      '——レックス・ボイドマン。'),
  NoahLine(NoahVoice.narration,
      'その名前が、なぜか頭に浮かんだ。'),
  NoahLine(NoahVoice.narration,
      '川崎の夜空を、思い出した。'),
  NoahLine(NoahVoice.narration,
      '東京湾の向こうに工場の灯りが揺れて、'
      'その上を飛行機がひとつ、ゆっくり横切っていく。'),
  NoahLine(NoahVoice.narration,
      '地球にはもう、誰もいない。'),
  NoahLine(NoahVoice.narration,
      'でも、名前は残っている。'),
  NoahLine(NoahVoice.chara,
      '「ショーン・キャロルは言った——"宇宙を織りなすもの"は、'
      '粒子でも、時空でもない。"関係"なんだと。」'),
  NoahLine(NoahVoice.chara,
      '「複雑さ——コンプレキシティ——こそが、'
      'この宇宙の本当の通貨だ。'
      '名前を覚えるのに必要なのも、同じものだよ。」'),
  NoahLine(NoahVoice.narration,
      '白い髪の博士は、一枚の紙を差し出した。'),
  NoahLine(NoahVoice.narration, 'そこには、数式がひとつ。'),
  NoahLine(NoahVoice.narration,
      r'''I(A:B) = S(A) + S(B) - S(A∪B)'''),
  NoahLine(NoahVoice.narration,
      '相互情報量。ふたつの系のあいだで、どれだけの情報が'
      '共有されているか。'),
  NoahLine(NoahVoice.chara,
      '「あなたと、あなたが覚えた人のあいだの情報量だ。'
      '名前を覚えると、この値が増える。」'),
  NoahLine(NoahVoice.chara,
      '「さあ。量子重力研の連中の名前、おぼえてもらおうか。」'),
];

const List<NoahLine> kNoahPhysicsEn = [
  NoahLine(_n, 'Planetary orbit: stable.'),
  NoahLine(_n,
      'The seas of LHS 1140 b were bluer than expected. Under the red dwarf\'s light, twilight lasted forever.'),
  NoahLine(_n,
      'All ship systems were waking up. Among them — a section no one had mentioned before.'),
  NoahLine(_d, '"The Quantum Gravity Lab." The people in here stayed awake the whole flight. Refused cryosleep. They\'ve been researching for 330 years.', who: 'Director'),
  NoahLine(_n, 'The door opened. Inside was covered in star charts and equations.'),
  NoahLine(_n, 'Papers taped to every wall. Arrows on whiteboards. Empty coffee cans. A muon detector with bite marks.'),
  NoahLine(_c, '—Oh. A new observer.'),
  NoahLine(_n, 'A white-haired theoretical physicist turned around.'),
  NoahLine(_d, 'Meet Dr. Thomas Nigel — known for his work on the muon anomaly.', who: 'Director'),
  NoahLine(_c, '"Muons, you see — they\'re the cracks in the Standard Model. The magnetic moment doesn\'t match. Could be gravitons influencing them."'),
  NoahLine(_c, '"During acceleration, we found something interesting. Entanglement — it\'s generating spacetime itself."'),
  NoahLine(_n, '—Spacetime, born from quantum entanglement.'),
  NoahLine(_n, 'The idea began with Maldacena — Juan Maldacena, the Argentine genius — and his AdS/CFT correspondence.'),
  NoahLine(_n, 'The quantum theory on the boundary determines everything about the interior spacetime. The universe is a hologram.'),
  NoahLine(_c, '"Takayanagi extended it — the entanglement entropy formula. What von Neumann conceived as a measure of information turned out to be equivalent to Einstein\'s equations."'),
  NoahLine(_n, '—Information equals spacetime.'),
  NoahLine(_c, '"So, remembering a name — you\'re literally weaving spacetime. When you call someone\'s name, you change the structure of the universe."'),
  NoahLine(_p, 'Calling someone\'s name… changes the universe?'),
  NoahLine(_c, '"Yes. Observation determines reality. In an ergodic system, a single trajectory covers all possible states. One name contains the entire cosmos."'),
  NoahLine(_n, 'The equations on the wall seemed to glow faintly.'),
  NoahLine(_d, '"There are more of them. The dark matter hunters — Professor Satoshi Murayama\'s WIMP team."', who: 'Director'),
  NoahLine(_c, '"Professor Murayama brought a WIMP detector. He\'s underground right now, digging for dark matter on this planet."'),
  NoahLine(_n, 'WIMP — Weakly Interacting Massive Particle. The invisible substance that makes up 85% of the universe\'s mass.'),
  NoahLine(_c, '"To find the invisible, you have to name it. The moment you give it a name, it exists."'),
  NoahLine(_n, '—Someone whispered "Feynman."'),
  NoahLine(_c, '"Ah, Feynman. His path integral means every possibility happens at once. We only see one of them."'),
  NoahLine(_c, '"Steven Weinberg built the Standard Model. The boundary between gravity and no-gravity — that\'s where we stand right now."'),
  NoahLine(_n, 'A young researcher at the back raised a hand.'),
  NoahLine(_c, '"The Efimov state — three particles bound impossibly far apart. Happens because the universe is scale-invariant. Like a name before it\'s given."'),
  NoahLine(_n, '—Darwin said species evolve.'),
  NoahLine(_n, 'But here, the universe itself was evolving.'),
  NoahLine(_c, '"Ever heard of Lee Smolin\'s cosmological natural selection? New universes are born inside black holes, and physical constants undergo selection. We are calling each other\'s names on just one branch of a vast multiverse."'),
  NoahLine(_n, '—Rex Boydman.'),
  NoahLine(_n, 'The name floated up from somewhere. Kawasaki\'s night sky, the factory lights across Tokyo Bay, an airplane slowly crossing.'),
  NoahLine(_n, 'No one is left on Earth. But the names remain.'),
  NoahLine(_c, '"Sean Carroll said it — the fabric of the cosmos isn\'t particles, or spacetime. It\'s relationships."'),
  NoahLine(_c, '"Complexity is the real currency of this universe. And what it takes to remember a name — is exactly the same thing."'),
  NoahLine(_n, 'The white-haired physicist held out a piece of paper. A single equation.'),
  NoahLine(_n, r'''I(A:B) = S(A) + S(B) - S(A∪B)'''),
  NoahLine(_n, 'Mutual information. How much information is shared between two systems.'),
  NoahLine(_c, '"That\'s the amount of information between you and the person you remember. When you learn a name, this value goes up."'),
  NoahLine(_c, '"Now — let\'s see if you can remember the names of the Quantum Gravity Lab."'),
];

// ── 名刺交換（物理チーム）──

const List<NoahLine> kNoahBeforePhysicsMeet = [
  NoahLine(NoahVoice.narration, '——量子重力研の名刺交換が始まった。'),
  NoahLine(NoahVoice.narration,
      '彼らの名刺には、所属のほかに「arXivの番号」が書いてある。'
      'プレプリント・サーバーの識別子。研究成果のID。'),
  NoahLine(NoahVoice.narration,
      '「名前と、理論のIDを、一緒に覚えてください」——'
      'フェルミ研から来たという若い博士研究員が言った。'),
  NoahLine(NoahVoice.narration, 'これは、現実の構造を覚えることだ。'),
];

const List<NoahLine> kNoahBeforePhysicsMeetEn = [
  NoahLine(_n, '—The Quantum Gravity Lab\'s card exchange began.'),
  NoahLine(_n, 'Their business cards listed not just affiliations but arXiv numbers — preprint server identifiers. The IDs of research results.'),
  NoahLine(_n, '"Memorize the name and the theory ID together," said a young postdoc from Fermilab.'),
  NoahLine(_n, 'This was learning the structure of reality itself.'),
];

String noahGreetLineEn(NoahCharacter c) {
  switch (c.id) {
    case 'hibino': return '"I\'m Hibino. I work on the reactor. …Nice to meet you."';
    case 'kiryu': return '"Kiryu. I study consciousness. Are you good with names?"';
    case 'mizuhara': return '"Mizuhara. I look after these little ones — the embryo capsules."';
    case 'tachibana': return '"Tachibana. I manage the air and water. Including what you\'re breathing now."';
    case 'hoshino': return '"Hoshino Mirai. "Mirai" means future — my grandfather chose it."';
    case 'iwao': return '"Iwao. I study mountains. And the ground of our new planet."';
    case 'kusunoki': return '"Kusunoki. I\'m with the robots. Call me if anything breaks."';
    case 'shirakawa': return '"Shirakawa. I\'m the one who puts you to sleep, and wakes you up."';
    default: return '"I\'m ${c.name}. Nice to meet you."';
  }
}

// ── English story scene lists ─────────────────────────────

const _d = NoahVoice.director; const _n = NoahVoice.narration;
const _p = NoahVoice.player; const _c = NoahVoice.chara;

List<NoahLine> _en(List<NoahLine> jp) => jp; // placeholder, will be replaced with actual English

/// 🌐 Locale-aware story line picker.
List<NoahLine> noahStoryLines(bool ja, List<NoahLine> jaLines, List<NoahLine> enLines) =>
    ja ? jaLines : enLines;

const List<NoahLine> kNoahPrologueEn = [
  NoahLine(_n, 'Year five billion twenty-six.'),
  NoahLine(_n, 'The sun is red.'),
  NoahLine(_n, 'The star, having burned through its hydrogen, has swelled to fill a third of the sky. Mercury and Venus are gone.'),
  NoahLine(_n, 'Earth has barely escaped being swallowed—but its surface has reached temperatures that melt lead. The oceans have become plains of phosphorescent lava.'),
  NoahLine(_n, 'Humanity lives three kilometers underground, beneath the town of Totsuka, Yokohama. The last 720,000 souls crowd together under what was once a golf course.'),
  NoahLine(_n, 'You are one of them. You have never known the light or wind of the surface.'),
  NoahLine(_d, 'Thank you for coming.', who: 'Director'),
  NoahLine(_d, 'This place was a golf course. Eighteen holes, seven hundred thousand square meters. Flat, with water, with roads. Perfect for a launch site.', who: 'Director'),
  NoahLine(_d, 'We dug a silo beneath the 18th green.', who: 'Director'),
  NoahLine(_d, 'Our destination: LHS 1140 b, forty-nine light-years away. A super-Earth orbiting a red dwarf. It has water.', who: 'Director'),
  NoahLine(_p, 'Forty-nine light-years… How long will it take?'),
  NoahLine(_d, 'Fifteen percent of light speed. Three hundred and thirty years. We will sleep through the journey.', who: 'Director'),
  NoahLine(_n, 'A murmur. Someone draws a sharp breath.'),
  NoahLine(_n, 'Three hundred and thirty years. From the founding of Edo to long before your birth. All that time, the ship will be nothing but a metal shell coasting between the stars.'),
  NoahLine(_d, 'There is, however, a problem.', who: 'Director'),
  NoahLine(_d, 'After prolonged cryosleep, memory degrades. And what goes first—', who: 'Director'),
  NoahLine(_d, 'Is names.', who: 'Director'),
  NoahLine(_n, 'Five hundred people will board this ship. Five hundred people who will not know who stands beside them when they wake.'),
  NoahLine(_n, '"Someone" is not enough to form a community. Five hundred without names is five hundred isolates.'),
  NoahLine(_d, 'So your job is not just research.', who: 'Director'),
  NoahLine(_d, 'Your job is to remember. Names. Everyone\'s.', who: 'Director'),
  NoahLine(_n, 'Someone exhaled quietly.'),
  NoahLine(_n, 'Five hundred names—the outlines of five hundred lives.'),
];

const List<NoahLine> kNoahColdShoulderEn = [
  NoahLine(_n, 'Orientation. Five hundred people fill the old tennis court hall.'),
  NoahLine(_n, 'Everyone wears a name tag. Here, your name is everything you are.'),
  NoahLine(_p, '(…Maybe I should try talking to the person next to me.)'),
  NoahLine(_p, 'Hey, what research department are you in?'),
  NoahLine(_n, 'No answer. They\'re already deep in conversation with someone else.'),
  NoahLine(_p, '…Excuse me—'),
  NoahLine(_n, 'This time, your voice doesn\'t even land. The noise of the hall swallows a single person\'s words whole.'),
  NoahLine(_n, 'Five hundred people, and no one notices you. Someone bumps your shoulder. No one turns around.'),
  NoahLine(_n, '—That\'s when you understand. Without a name, a person might as well not exist.'),
  NoahLine(_n, 'So that\'s why. The reason you have to learn everyone\'s name finally sinks in, not in your head but in your body.'),
  NoahLine(_n, 'To be forgotten is to be invisible.'),
  NoahLine(_n, 'Then, one person turns around.'),
  NoahLine(_c, '…Were you trying to say something? Sorry, I didn\'t notice.'),
  NoahLine(_n, '—Those words stay with you, strangely warm. The feeling of being found.'),
];

const List<NoahLine> kNoahBeforeMeetingEn = [
  NoahLine(_n, '—The introductions begin.'),
  NoahLine(_n, 'Everyone carries a business card. Not paper—printed with comm IDs, fields, and even hobbies.'),
  NoahLine(_n, '"The hobbies are there to give you more hooks for memory." That\'s what Dr. Shirakawa said.'),
  NoahLine(_n, 'You only get to look at each card once.'),
];

const List<NoahLine> kNoahBeforeSleepEn = [
  NoahLine(_n, 'The night before departure.'),
  NoahLine(_n, 'On the tennis court wall, someone has scratched "see you tomorrow" with their nail.'),
  NoahLine(_n, 'Below it, another person carves the same words. Then another, in turn.'),
  NoahLine(_n, 'Five hundred "see you tomorrow"s cover the wall.'),
  NoahLine(_n, 'There will be no tomorrow on Earth. And yet the words someone carved are traced by someone else. That chain—that is what a community is.'),
  NoahLine(_p, '"See you tomorrow"—three hundred and thirty years from now…'),
  NoahLine(_n, 'The 18th green splits open, and the Ark "Noah" rises.'),
  NoahLine(_n, 'The water of Lake Oike bursts into mist, a curtain of steam swallowing all sound. The golf course vitrifies in the launch heat, then dissolves into the black of space.'),
  NoahLine(_d, 'Today\'s hole, par 4. Distance to the green—forty-nine light-years.', who: 'Director'),
  NoahLine(_n, 'The pod lid closes. Cold sleep wraps around you.'),
  NoahLine(_n, 'The next time you open your eyes—will you remember?'),
];

const List<NoahLine> kNoahAwakeEn = [
  NoahLine(_n, '—Three hundred and thirty years.'),
  NoahLine(_n, 'The lid opens. Cold air. Your cells wake up, one by one.'),
  NoahLine(_n, 'You see the ceiling. A date is displayed. You can remember your own name.'),
  NoahLine(_n, 'The wall that said "see you tomorrow" is nowhere.'),
  NoahLine(_p, '(…Then, what about that person?)'),
  NoahLine(_n, 'Someone stirs in the next pod.'),
  NoahLine(_n, 'The face looks familiar. But—the name won\'t come.'),
];

const List<NoahLine> kNoahClimaxEn = [
  NoahLine(_n, 'Deceleration phase, begin.'),
  NoahLine(_n, 'A magnetic sail hundreds of kilometers across unfurls, catching the stellar wind to brake. If this fails, the ship will overshoot the star and drift into the void.'),
  NoahLine(_n, 'Sail deployment—stalled at seventy-three percent.'),
  NoahLine(_c, 'Four minutes. We have four minutes to open it.'),
  NoahLine(_c, 'Fusion output—divert everything to the sail.'),
  NoahLine(_p, 'Sector Three, temperature is spiking!'),
  NoahLine(_n, 'No one responds.'),
  NoahLine(_n, '—No. It\'s not just your voice. Everyone is shouting at everyone else. The comms are a tangle of screams.'),
  NoahLine(_n, 'Five hundred people, and you are alone again.'),
  NoahLine(_p, '…Sector Three, route coolant now!'),
  NoahLine(_c, 'Heard. Sector Three, coolant routed.'),
  NoahLine(_n, 'That one acknowledgement loosens the knot in your shoulders.'),
  NoahLine(_n, 'Just like at orientation. One person notices, and you can stand again.'),
  NoahLine(_c, 'Send the robots outside. Bring everyone home.'),
  NoahLine(_c, 'Life support to minimum. Protect the lives.'),
  NoahLine(_c, 'Starboard, tilt three degrees. The heat won\'t hold.'),
  NoahLine(_c, 'Hold your breath. It\'ll be fine.'),
  NoahLine(_n, 'Sail, one hundred percent deployed.'),
  NoahLine(_n, 'Deceleration complete.'),
  NoahLine(_n, 'Beyond the window—a small red sun, and a planet with dark blue seas.'),
  NoahLine(_n, 'Before we land, there is one more thing to confirm.'),
];

const List<NoahLine> kNoahWhyNamesEn = [
  NoahLine(_p, 'Can I ask you something?'),
  NoahLine(_p, 'Is remembering names really that important? All the data is in the ship\'s database.'),
  NoahLine(_d, 'It is.', who: 'Director'),
  NoahLine(_d, 'The database can tell you who is who. But it can\'t call their name.', who: 'Director'),
  NoahLine(_d, 'Three hundred and thirty years from now, five hundred people will wake up at the same time. Every one of them has lost part of their memory.', who: 'Director'),
  NoahLine(_d, 'The first thing that will happen is not panic, or looting.', who: 'Director'),
  NoahLine(_d, 'It\'s silence.', who: 'Director'),
  NoahLine(_d, 'Someone is next to you, and you can\'t speak to them—because you don\'t know their name.', who: 'Director'),
  NoahLine(_n, 'The director was quiet for a long moment.'),
  NoahLine(_d, 'When someone calls your name, you know you are here.', who: 'Director'),
  NoahLine(_d, 'That\'s all it is. And that small thing is what turns five hundred people into a community.', who: 'Director'),
  NoahLine(_d, 'So remember. As many as you can.', who: 'Director'),
  NoahLine(_d, 'The size of this ship depends on the number of names you can carry.', who: 'Director'),
];

const List<NoahLine> kNoahBeforeResultEn = [
  NoahLine(_n, 'Landing preparations.'),
  NoahLine(_n, 'Outside the window, a small red sun reflects off the sea. Only the terminator zone—the strip between day and night—had the right temperature.'),
  NoahLine(_n, 'The passenger manifest is read aloud.'),
];

const List<NoahDate> kNoahDatesEn = [
  NoahDate('The Artificial River', 'Ninety-nine percent of the water in this river was once drunk by someone three hundred years ago. It circulates.'),
  NoahDate('Food Court', 'Algae steak and cricket tempura. The soy sauce is from yeast cultures brought all the way from Earth.'),
  NoahDate('Karaoke', 'Some frequencies seem to resonate with the ship\'s rotation. At certain notes, the floor hums.'),
  NoahDate('Department Store', 'Nothing on this ship is new. Everything is recycled. So the repair workers are the most respected people here.'),
  NoahDate('Tennis Court', 'Half gravity. The ball falls slowly, curving slightly with the Coriolis force.'),
  NoahDate('Observation Deck', 'The window shows nothing but black. The stars don\'t move. For three hundred and thirty years, almost the same view.'),
  NoahDate('Old Fairway Footage', 'Video from the morning of the launch. The 18th pin flag stands alone, still planted.'),
];

const List<NoahNote> kNoahNotesEn = [
  NoahNote(
    'Say it out loud',
    'Words you speak or write yourself tend to be recalled more easily than words you only heard. When you receive a business card, say the person\'s name aloud right there. Even that small act gives you more hooks for memory.',
    'MacLeod et al. (2010) — the production effect',
  ),
  NoahNote(
    'Retrieval is the best practice',
    'Given the same amount of time, hiding the information and trying to recall it leads to longer retention than re-reading. The constant testing on this ship isn\'t cruelty.',
    'Roediger & Karpicke (2006) — the testing effect',
  ),
  NoahNote(
    'Names are uniquely hard to remember',
    'The same word "Baker" as a surname is harder to recall than "baker" as a profession. Names tell you nothing about the person, so they have few places to stick.',
    'McWeeny et al. (1987) — the Baker/baker paradox',
  ),
  NoahNote(
    'Attach meaning',
    'Information connected to facial features or personal stories sticks better. "Hibino who does pottery." "Kiryu who plays Go." Learning hobbies first gives names something to hold onto.',
    'Craik & Tulving (1975) — levels of processing',
  ),
  NoahNote(
    'Connect it to yourself',
    'Information related to yourself is recalled more easily than neutral information. Remembering "where I met this person" can help later.',
    'Rogers et al. (1977) — self-reference effect',
  ),
  NoahNote(
    'Space it out, come back',
    'Rather than trying to memorize everything in one go, spacing out recall sessions leads to better long-term retention. Though 330 years might be a bit much.',
    'Spacing effect research since Ebbinghaus',
  ),
];
