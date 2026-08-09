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
