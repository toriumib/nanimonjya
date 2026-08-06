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
      '地球はかろうじて呑まれずにいるが、地表は鉛が溶ける温度になった。'),
  NoahLine(NoahVoice.narration,
      '人類は、横浜・戸塚区大池町の地下三キロに潜っている。'),
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
