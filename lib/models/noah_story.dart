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
  /// 専用の絵を十六人ぶん用意しなくても、特徴（メガネ・ひげ・髪型）で
  /// 見分けがつく。**顔メモで使っているのと同じ仕組み**なので、
  /// 「この人はこういう顔」を覚える練習としても筋が通る。
  final Avatar avatar;

  /// 🧠 この人が持っている意識の理論（すべて実在の理論）。
  /// いちばん覚えていた人の理論が採択され、引っ越しのやり方が決まる。
  final String theory;
  final String theoryEn;

  /// 理論の一行説明。
  final String theoryShort;
  final String theoryShortEn;

  /// その理論が採択された世界の結末。
  final String uploadEnding;
  final String uploadEndingEn;

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
    required this.theory,
    required this.theoryEn,
    required this.theoryShort,
    required this.theoryShortEn,
    required this.uploadEnding,
    required this.uploadEndingEn,
  });

  String theoryOf(bool ja) => ja ? theory : theoryEn;
  String theoryShortOf(bool ja) => ja ? theoryShort : theoryShortEn;
  String uploadEndingOf(bool ja) => ja ? uploadEnding : uploadEndingEn;
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
    theory: 'ダイナミック・コア理論（DCT）',
    theoryEn: 'Dynamic Core Theory (DCT)',
    theoryShort: '動的にできる「核」が意識を担う。核はいつでも組み直せる',
    theoryShortEn: 'A dynamically formed "core" carries consciousness. The core can always be rebuilt.',
    uploadEnding: '楓の理論が採択された世界では、意識は器ではなく**炎の芯**として扱われる。\n'
        '薪を入れ替えても火が同じ火であるように、体を替えても核が続いていれば同じ人。\n'
        'だから引っ越しは「移す」ではなく「焚き直す」と呼ばれた。\n'
        '新東戸塚の最初の窯に火が入った日、彼女は炎の前で言う。\n'
        '「お父さん。核だけは、消さずに持ってきたよ」'
  ,
    uploadEndingEn:
        'In the world that adopted Kaede\'s theory, consciousness is treated not as a vessel but as **the heart of a flame**.\n'
        'As a fire stays the same fire when you change the wood, a person stays the same person when the core continues.\n'
        'So the move was never called "transferring." It was called "rekindling."\n'
        'On the day the first kiln was lit in New Higashi-Totsuka, she stood before the fire and said:\n'
        '"Dad. The core, at least — I carried it here without letting it go out."'),
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
    theory: '意識の量子論',
    theoryEn: 'Quantum Theory of Consciousness',
    theoryShort: '意識の基盤は量子状態。ゆえに複製できず、移すことしかできない',
    theoryShortEn: 'Consciousness rests on quantum states. It cannot be copied — only moved.',
    uploadEnding: '悟の理論が採択された世界には、**控えというものが存在しない**。\n'
        '量子状態は複製できないから、引っ越しは常に片道になる。二人にはならない。\n'
        'そして同じ理由で、三百三十年の眠りも「死んで生まれ直した」ではなくなる。\n'
        '複製されていないのだから、戻ってきたのは同じものだ。\n'
        '——十七人は、一度も死んでいない。\n'
        '碁盤の最後の一手を置いて、彼は言う。「負けました。姉さん、強かったな」'
  ,
    uploadEndingEn:
        'In the world that adopted Satoru\'s theory, **there is no such thing as a spare**.\n'
        'Quantum states cannot be cloned, so the move is always one-way. You never become two.\n'
        'And for the same reason, the three hundred and thirty years of sleep stop meaning "died and was remade."\n'
        'Nothing was copied, so what came back is the same thing.\n'
        '—The seventeen of them never died. Not once.\n'
        'Placing the last stone on the go board, he says, "I resign. You were strong, sister."'),
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
    theory: 'ラディカル可塑性仮説（RPT）',
    theoryEn: 'Radical Plasticity Thesis (RPT)',
    theoryShort: '学ぶことによって意識が生まれる。作り替わり続けるものが意識である',
    theoryShortEn: 'Consciousness arises from learning. What keeps remaking itself is what is conscious.',
    uploadEnding: '紗耶香の理論が採択された世界では、意識は**継ぎ足すもの**になる。\n'
        '完成品を移すのではなく、新しい体に少しずつ学び直させて、育て切る。\n'
        '時間はかかる。だが途切れない。ぬか床と同じやり方だ。\n'
        '「一世代で仕上げようとしないこと。それだけなんですよ」\n'
        '彼女はそう言って、その日82人目の子を取り上げる。'
  ,
    uploadEndingEn:
        'In the world that adopted Sayaka\'s theory, consciousness becomes something you **keep topping up**.\n'
        'You do not move a finished article; you let a new body learn its way back, a little at a time, until it is whole.\n'
        'It takes long. But it never breaks. The same method as a fermenting bed.\n'
        '"Just don\'t try to finish it in one generation. That\'s the whole trick."\n'
        'She says this, and delivers the eighty-second child of the day.'),
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
    theory: '統合情報理論（IIT）',
    theoryEn: 'Integrated Information Theory (IIT)',
    theoryShort: '統合された情報の量が、そのまま意識の量である',
    theoryShortEn: 'The amount of integrated information is, exactly, the amount of consciousness.',
    uploadEnding: '宗一郎の理論が採択された世界では、引っ越しの条件はただ一つ、\n'
        '**統合が途切れないこと**になる。切らずに、少しずつ、置き換える。\n'
        '彼が閉じた生態系でやったことと同じで、制御を足さずに、待つ。\n'
        '「急かすな。系は自分で釣り合う」\n'
        '新東戸塚のドームで、ゼラニウムが18鉢に増えた朝の言葉である。'
  ,
    uploadEndingEn:
        'In the world that adopted Soichiro\'s theory, the move has exactly one condition:\n'
        '**integration must never be cut**. Replace it gradually, without severing it.\n'
        'The same thing he did with the closed ecosystem — add no control, and wait.\n'
        '"Don\'t rush it. A system finds its own balance."\n'
        'His words on the morning the geraniums reached eighteen pots, under the New Higashi-Totsuka dome.'),
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
    theory: 'グローバル・ワークスペース理論（GNWT）',
    theoryEn: 'Global Neuronal Workspace Theory (GNWT)',
    theoryShort: '情報が広く放送されたとき、それが意識になる',
    theoryShortEn: 'When information is broadcast widely, that is when it becomes conscious.',
    uploadEnding: '未来の理論が採択された世界では、意識は**放送**として扱われる。\n'
        'だから引っ越しは、送信所を建て替える工事に似たものになった。\n'
        '電波は途切れない。周波数も、番組も、同じまま。ただ塔だけが新しい。\n'
        '「止まらずに切り替えられたら、それは同じ放送です」\n'
        '祖父に見せられなかった星空を、彼女は新しい空から撮り直しはじめる。'
  ,
    uploadEndingEn:
        'In the world that adopted Miku\'s theory, consciousness is treated as a **broadcast**.\n'
        'So the move came to resemble rebuilding a transmitter station.\n'
        'The signal never stops. Same frequency, same programme. Only the tower is new.\n'
        '"If you can switch it over without going off the air, it\'s the same broadcast."\n'
        'The night sky she could never show her grandfather, she begins photographing again — from a new sky.'),
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
    theory: '意識の電磁情報場理論（CEMI）',
    theoryEn: 'Conscious Electromagnetic Information Field Theory (CEMI)',
    theoryShort: '脳が生む電磁場そのものが意識である',
    theoryShortEn: 'The electromagnetic field the brain generates simply is consciousness.',
    uploadEnding: '玄助の理論が採択された世界では、意識は**場**として引っ越す。\n'
        '体は場を立てるための土地でしかなく、土地は造り替えればいい。\n'
        '標高312メートルの丘が人工島の中央に据えられた日、\n'
        '彼は設計図の備考欄に一行だけ書き足した。——「返却」。\n'
        'その丘の上でだけ、匿名の俳句に署名が入るようになった。'
  ,
    uploadEndingEn:
        'In the world that adopted Gensuke\'s theory, consciousness moves as a **field**.\n'
        'The body is only ground on which to raise that field, and ground can be rebuilt.\n'
        'On the day a hill of three hundred and twelve metres was set at the centre of the artificial island,\n'
        'he added one line to the notes column of the blueprint. —"Returned."\n'
        'On that hill alone, anonymous haiku began to carry signatures.'),
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
    theory: '注意スキーマ理論（AST）',
    theoryEn: 'Attention Schema Theory (AST)',
    theoryShort: '意識とは、注意についての脳の内部モデルである',
    theoryShortEn: 'Consciousness is the brain\'s internal model of its own attention.',
    uploadEnding: '玲の理論が採択された世界では、意識は**モデル**なので、\n'
        '描き直せる場所へ持っていける。人にも、機械にも、どちらにも。\n'
        'だから彼女の作った体は、最初から人間用と機械用の区別が無い。\n'
        '設計目標の体温は36.4℃。兄の平熱だった。\n'
        '「握れる手を作る。それがわたしの専門だから」'
  ,
    uploadEndingEn:
        'In the world that adopted Rei\'s theory, consciousness is a **model**,\n'
        'so it can be carried anywhere it can be drawn again. Into people, into machines, either one.\n'
        'That is why the bodies she built draw no distinction between human and machine from the start.\n'
        'The design target for body temperature was 36.4°C. Her brother\'s resting temperature.\n'
        '"I make hands that can be held. That\'s my field."'),
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
    theory: '活性化/情報/モード合成仮説（AIM）',
    theoryEn: 'Activation–Input–Modulation Model (AIM)',
    theoryShort: '覚醒・夢・眠りは三つの軸の合成にすぎない。意識は状態である',
    theoryShortEn: 'Waking, dreaming and sleep are just a blend of three axes. Consciousness is a state.',
    uploadEnding: '冬也の理論が採択された世界では、引っ越しは**第四の状態**として設計される。\n'
        '眠りでも覚醒でもない状態を通って、向こう側で目を覚ます。\n'
        '彼は十六人ぶんの手順書を書き、一人ずつ名前を読みながら送り出した。\n'
        '「『大丈夫』とは言わん。……いや」\n'
        '「今日は言う。大丈夫だ」'
  ,
    uploadEndingEn:
        'In the world that adopted Fuyuya\'s theory, the move is engineered as a **fourth state**.\n'
        'You pass through something that is neither sleep nor waking, and open your eyes on the other side.\n'
        'He wrote out the procedure sixteen times over, and sent each one off reading their name aloud.\n'
        '"I won\'t tell you it\'ll be fine. …No."\n'
        '"Today I will. It\'ll be fine."'),
  // ── ここから、第二陣の八人 ─────────────────────────
  NoahCharacter(
    id: 'aizawa',
    name: '相沢 灯',
    reading: 'あいざわ あかり',
    field: '認知科学研究所',
    hobby: '編み物',
    commId: 'ART-0311',
    school: '名大・情報学部',
    regret: '母のセーターを編み終えられなかった',
    emoji: '🧶',
    colorValue: 0xFFE8A0C0,
    male: false,
    // 編み物をする認知科学者。三つ編みとやわらかい目
    avatar: Avatar(
      skin: 0, faceShape: 1, hair: 7, hairColor: 3, eyes: 5, eyebrows: 0,
      nose: 1, mouth: 4, glasses: 0, mole: 2, beard: 0,
      gender: 2, age: 28, height: 156),
    theory: '適応共鳴理論（ART）',
    theoryEn: 'Adaptive Resonance Theory (ART)',
    theoryShort: '入ってきたものと覚えているものが響き合ったとき、認識が立つ',
    theoryShortEn: 'Recognition stands up when what comes in resonates with what is remembered.',
    uploadEnding: '灯の理論が採択された世界では、引っ越しは**編み直し**になる。\n'
        '古い段を一段ずつほどきながら、同じ模様を新しい糸で編んでいく。\n'
        'ほどく速さと編む速さが合っていれば、模様は一度も途切れない。\n'
        '「合ってさえいれば、いいんです。急がなければ」\n'
        '新東戸塚の冬、彼女は母のセーターの続きを編みはじめる。',
    uploadEndingEn:
        'In the world that adopted Akari\'s theory, the move becomes **re-knitting**.\n'
        'You unravel the old rows one at a time and knit the same pattern with new yarn.\n'
        'If the speed of unravelling matches the speed of knitting, the pattern never once breaks.\n'
        '"As long as they match, it\'s fine. As long as you don\'t hurry."\n'
        'In the winter of New Higashi-Totsuka, she picks up where her mother\'s sweater left off.',
  ),
  NoahCharacter(
    id: 'fuyuki',
    name: '冬木 遼',
    reading: 'ふゆき りょう',
    field: '高次脳機能研究センター',
    hobby: '落語',
    commId: 'HOT-0450',
    school: '早大・文学部から医学部へ',
    regret: '師匠の十八番を継がなかった',
    emoji: '🎭',
    colorValue: 0xFF9AA8E8,
    male: true,
    // 落語をやる神経科学者。角刈りに近い短髪、笑い皺
    avatar: Avatar(
      skin: 1, faceShape: 0, hair: 3, hairColor: 0, eyes: 4, eyebrows: 1,
      nose: 2, mouth: 4, glasses: 4, mole: 0, beard: 0,
      gender: 1, age: 44, height: 168),
    theory: '高次表象理論（HOT）',
    theoryEn: 'Higher-Order Thought Theory (HOT)',
    theoryShort: '「自分が見ている」と気づいたとき、はじめて意識になる',
    theoryShortEn: 'It becomes conscious only when you notice that you are the one seeing.',
    uploadEnding: '遼の理論が採択された世界では、引っ越しが済んだ合図は**本人の一言**になる。\n'
        '「ああ、いま自分が見ているな」——そう気づけたら、それで完了だ。\n'
        '外から測る装置は無い。高座で客がどこで笑うかを測れないのと同じで。\n'
        '「わかるんですよ。噺と一緒で、入った瞬間ってのは」\n'
        '彼は新東戸塚の広場で、師匠の十八番を三百三十年ぶりに掛ける。',
    uploadEndingEn:
        'In the world that adopted Ryo\'s theory, the signal that a move is complete is **the person\'s own remark**.\n'
        '"Ah — I\'m the one looking right now." Notice that, and it is done.\n'
        'There is no instrument to measure it from outside. No more than you can measure where an audience will laugh.\n'
        '"You can tell. Same as with a story — you know the moment it lands."\n'
        'In the square at New Higashi-Totsuka, he performs his master\'s signature piece for the first time in three hundred and thirty years.',
  ),
  NoahCharacter(
    id: 'mido',
    name: '御堂 静香',
    reading: 'みどう しずか',
    field: '神経内科・身体性研究部門',
    hobby: '合気道',
    commId: 'DAM-0628',
    school: '京大医学部・合気道部',
    regret: '父の介護を人任せにした',
    emoji: '🥋',
    colorValue: 0xFFE8C46A,
    male: false,
    // 合気道をやる医師。まとめ髪と静かな目
    avatar: Avatar(
      skin: 2, faceShape: 3, hair: 6, hairColor: 0, eyes: 1, eyebrows: 3,
      nose: 0, mouth: 2, glasses: 0, mole: 0, beard: 0,
      gender: 2, age: 39, height: 170),
    theory: 'ダマシオの理論（身体マップ）',
    theoryEn: 'Damasio\'s Theory (Body Maps)',
    theoryShort: '身体の地図が先にあり、そこから自己が立ち上がる',
    theoryShortEn: 'The map of the body comes first; the self stands up out of it.',
    uploadEnding: '静香の理論が採択された世界では、**先に体を用意する**ことになる。\n'
        '意識だけを送っても着地できない。受け止める身体の地図が要る。\n'
        'だから新東戸塚では、引っ越しの前に必ず「体に慣れる半年」が置かれた。\n'
        '一・九Gの床の上で、立って、歩いて、転んで、それから移る。\n'
        '「地面を覚えるのが先です。人はそこからしか始まらない」',
    uploadEndingEn:
        'In the world that adopted Shizuka\'s theory, **the body is prepared first**.\n'
        'Send consciousness alone and it has nowhere to land. It needs a body map to catch it.\n'
        'So in New Higashi-Totsuka, half a year of "getting used to the body" always precedes a move.\n'
        'On a floor at 1.9G you stand, you walk, you fall — and only then do you move.\n'
        '"Learning the ground comes first. That is the only place a person can begin."',
  ),
  NoahCharacter(
    id: 'karita',
    name: '苅田 亨',
    reading: 'かりた とおる',
    field: '情報統合工学研究室',
    hobby: '自作キーボード',
    commId: 'SPC-1024',
    school: '東工大・情報理工',
    regret: '共同開発者と喧嘩別れした',
    emoji: '⌨️',
    colorValue: 0xFF6ED0C0,
    male: true,
    // キーボードを作る工学者。無造作な髪と丸メガネ
    avatar: Avatar(
      skin: 1, faceShape: 1, hair: 4, hairColor: 1, eyes: 0, eyebrows: 2,
      nose: 1, mouth: 1, glasses: 1, mole: 0, beard: 0,
      gender: 1, age: 35, height: 174),
    theory: '統合セマンティックポインター競合理論（SPC）',
    theoryEn: 'Semantic Pointer Competition (SPC)',
    theoryShort: '意味の候補どうしが競い合い、勝ったものが意識に上る',
    theoryShortEn: 'Candidate meanings compete; the winner is what rises into consciousness.',
    uploadEnding: '亨の理論が採択された世界では、引っ越しは**勝ち抜き戦**の形をとる。\n'
        '新しい基盤の上で候補を走らせ、いつもと同じものが勝てば、それが本人だ。\n'
        '負け筋まで含めて同じでなければ通らない。癖も、迷いも、誤変換も。\n'
        '「その人らしさって、勝ち方じゃなくて負け方のほうに出るんですよ」\n'
        '彼は喧嘩別れした相手の設計を、そのままキー配列に残している。',
    uploadEndingEn:
        'In the world that adopted Toru\'s theory, the move takes the shape of a **knockout tournament**.\n'
        'Run the candidates on the new substrate; if the usual one wins, that is the person.\n'
        'It does not pass unless the losing lines match too. The habits, the hesitations, the typos.\n'
        '"What makes someone themselves shows up in how they lose, not how they win."\n'
        'He keeps the key layout designed by the man he fell out with, exactly as it was.',
  ),
  NoahCharacter(
    id: 'naka',
    name: '名嘉 うみ',
    reading: 'なか うみ',
    field: '麻酔科・意識モニタ研究',
    hobby: '素潜り',
    commId: 'NIH-0808',
    school: '琉大医学部',
    regret: '祖母に海を見せると言って果たせなかった',
    emoji: '🌊',
    colorValue: 0xFF5FC8E8,
    male: false,
    // 海に潜る麻酔科医。short hair、日焼け
    avatar: Avatar(
      skin: 3, faceShape: 0, hair: 2, hairColor: 0, eyes: 2, eyebrows: 0,
      nose: 2, mouth: 1, glasses: 0, mole: 3, beard: 0,
      gender: 2, age: 31, height: 163),
    theory: 'ネットワーク抑制仮説（NIH）',
    theoryEn: 'Network Inhibition Hypothesis (NIH)',
    theoryShort: '意識は抑えられている。抑えが外れたときに現れる',
    theoryShortEn: 'Consciousness is held down. It appears when the hold is released.',
    uploadEnding: 'うみの理論が採択された世界では、引っ越しは**足すのではなく外す**作業になる。\n'
        '新しい体には、あらかじめ全部が抑え込まれた状態で入っている。\n'
        'あとは順番に抑えを解いていくだけ。麻酔から覚ますのと同じ手順だ。\n'
        '「潜って、浮くだけです。息を止めていられれば大丈夫」\n'
        '新東戸塚の海に最初に潜ったのは、彼女だった。',
    uploadEndingEn:
        'In the world that adopted Umi\'s theory, the move is a matter of **removing, not adding**.\n'
        'The new body arrives with everything already suppressed.\n'
        'All that is left is to release the holds in order. The same procedure as waking from anaesthesia.\n'
        '"You dive, and you surface. If you can hold your breath, you\'re fine."\n'
        'She was the first to dive into the sea at New Higashi-Totsuka.',
  ),
  NoahCharacter(
    id: 'ashihara',
    name: '芦原 慎',
    reading: 'あしはら まこと',
    field: '生物物理学研究所',
    hobby: '燻製づくり',
    commId: 'BIE-0902',
    school: '阪大・生命機能',
    regret: '弟子に何も教えないまま送り出した',
    emoji: '🔥',
    colorValue: 0xFFC08A5A,
    male: true,
    // 燻製を作る生物物理屋。白髪まじりの長め、口ひげ
    avatar: Avatar(
      skin: 2, faceShape: 2, hair: 5, hairColor: 5, eyes: 3, eyebrows: 1,
      nose: 0, mouth: 3, glasses: 2, mole: 0, beard: 3,
      gender: 1, age: 49, height: 177),
    theory: 'ビーベリッヒの理論（膜・脂質過程）',
    theoryEn: 'Bieberich\'s Theory (Membrane / Lipid Processes)',
    theoryShort: '意識は細胞の膜のふるまいに支えられている',
    theoryShortEn: 'Consciousness is carried by the behaviour of cell membranes.',
    uploadEnding: '慎の理論が採択された世界では、運ぶのは情報ではなく**膜の状態**になる。\n'
        '燻製と同じで、急に温度を変えれば台無しになる。だから何日もかけて移す。\n'
        '新東戸塚の引っ越し施設は、彼の燻製小屋とそっくりの形をしている。\n'
        '「待てるかどうかだけなんだ、こういうのは」\n'
        '彼は今度こそ、弟子に手順を全部書いて渡した。',
    uploadEndingEn:
        'In the world that adopted Shin\'s theory, what you carry is not information but **the state of the membrane**.\n'
        'Like smoking food: change the temperature suddenly and you ruin it. So the move takes days.\n'
        'The transfer facility at New Higashi-Totsuka is shaped exactly like his smokehouse.\n'
        '"With this kind of thing, it only comes down to whether you can wait."\n'
        'This time, he wrote the whole procedure down and handed it to his apprentice.',
  ),
  NoahCharacter(
    id: 'chigusa',
    name: '千種 郁',
    reading: 'ちぐさ かおる',
    field: '記憶科学研究室',
    hobby: '古時計の修理',
    commId: 'MCT-1201',
    school: '筑波大・心理学',
    regret: '祖父の時計を止めたまま持ってきた',
    emoji: '🕰',
    colorValue: 0xFFB8A0E8,
    male: false,
    // 古時計を直す記憶研究者。長い髪を下ろしている、細いメガネ
    avatar: Avatar(
      skin: 0, faceShape: 3, hair: 5, hairColor: 2, eyes: 1, eyebrows: 2,
      nose: 1, mouth: 0, glasses: 3, mole: 1, beard: 0,
      gender: 2, age: 34, height: 161),
    theory: '記憶意識・一時性理論（MCTT）',
    theoryEn: 'Memory Consciousness and Temporality Theory (MCTT)',
    theoryShort: '意識とは、時間の流れと記憶がつくる連なりである',
    theoryShortEn: 'Consciousness is the chain that the flow of time and memory make together.',
    uploadEnding: '郁の理論が採択された世界では、引っ越しで大事なのは**時計を止めないこと**になる。\n'
        '中身を移すより、時間の連なりを切らないほうが先だ。\n'
        'だから移送中もずっと、その人の主観の時間は進み続けるよう設計された。\n'
        '「止まった時計は、直せます。でも止めないほうがずっと楽なので」\n'
        '祖父の時計は、着陸の朝にもう一度動きはじめる。',
    uploadEndingEn:
        'In the world that adopted Iku\'s theory, what matters in a move is **not stopping the clock**.\n'
        'Keeping the chain of time unbroken comes before moving the contents.\n'
        'So the design keeps the person\'s subjective time running throughout the transfer.\n'
        '"A stopped clock can be repaired. But it\'s far easier not to stop it."\n'
        'Her grandfather\'s watch starts again on the morning of the landing.',
  ),
  NoahCharacter(
    id: 'sakaki',
    name: '榊 秀一',
    reading: 'さかき しゅういち',
    field: '科学哲学・現象学研究室',
    hobby: '写経',
    commId: 'GUR-0056',
    school: '東北大・哲学',
    regret: '妻の問いに答えないまま四十年経った',
    emoji: '📜',
    colorValue: 0xFFA8B49A,
    male: true,
    // 写経をする哲学者。最年長、白髪と長いあごひげ
    avatar: Avatar(
      skin: 4, faceShape: 2, hair: 1, hairColor: 4, eyes: 1, eyebrows: 3,
      nose: 0, mouth: 2, glasses: 2, mole: 4, beard: 2,
      gender: 1, age: 56, height: 166),
    theory: 'ギュルヴィッチの理論（意識野）',
    theoryEn: 'Gurwitsch\'s Theory (Field of Consciousness)',
    theoryShort: '意識には中心と周縁があり、野そのものが形を持つ',
    theoryShortEn: 'Consciousness has a centre and a margin; the field itself has a shape.',
    uploadEnding: '秀一の理論が採択された世界では、移すのは中身ではなく**視野の形**になる。\n'
        '何がいま真ん中にあって、何が端に置かれているか。その配置が本人だ。\n'
        'だから引っ越しの検査は、記憶の照合ではなく「何が気になるか」を訊く。\n'
        '「答えは要りません。何を気にしているかが、あなたですから」\n'
        '四十年答えなかった妻の問いを、彼は写経の最後の一行に書き写す。',
    uploadEndingEn:
        'In the world that adopted Shuichi\'s theory, what moves is not the contents but **the shape of the field**.\n'
        'What sits at the centre right now, and what is set at the edge. That arrangement is the person.\n'
        'So the check after a move is not a memory test. It asks what you find yourself minding.\n'
        '"I don\'t need the answer. What you mind — that is you."\n'
        'The question his wife asked, that he did not answer for forty years, he copies onto the last line of his sutra.',
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

  /// 全員の好感度がぴったり同じ。十七人の同窓会エンド。
  /// 子孫に「顔が似すぎて見分けつかない」と笑われる（恨まれるほどではない）。
  bitter,

  /// 🌟 世界線Ω。全員の全項目と船内の謎まで、ひとつ残らず思い出した。
  /// 転送権を使う理由が消える（誰も引っ越す必要がない）。
  trueEnd,

  /// 🛰️ 見守りエンド。恋愛を選ばなかったルート。
  /// **失敗ではなく、選んで行く場所**。いちばんよく覚えていた人の理論が採られ、
  /// 自分が最初に引っ越して、十六人を見守る側にまわる。
  watching,

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

/// 結末を決める。
///
/// [divergence] は世界線の一致度（1.0 で真エンド）。
/// [romantic] が false のときは恋愛を選ばなかったルートなので、
/// 見守りエンドに寄せる（**失敗の lonely とは別物**）。
NoahResult resolveNoahEnding(
  Map<String, int> affection, {
  double divergence = 0,
  bool romantic = true,
}) {
  final total = affection.values.fold<int>(0, (a, b) => a + b);

  final ranked0 = affection.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  // 🌟 全部そろっていれば、恋愛の有無に関わらず真エンド。
  if (divergence >= kNoahTrueEndDivergence && ranked0.isNotEmpty) {
    return NoahResult(
      ending: NoahEnding.trueEnd,
      totalAffection: total,
      partner: noahCharacterById(ranked0.first.key),
    );
  }

  // 🛰️ 恋愛を選ばなかったなら見守りエンド。
  //    いちばんよく覚えていた人の理論が採択される。
  if (!romantic && ranked0.isNotEmpty && total >= kNoahLonelyThreshold) {
    return NoahResult(
      ending: NoahEnding.watching,
      totalAffection: total,
      partner: noahCharacterById(ranked0.first.key),
    );
  }

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
enum NoahPreference {
  men,
  women,
  all,

  /// 💍 独身モード。恋愛はしないが、**十六人全員と対話する**。
  /// 採択されるのは「いちばんよく覚えていた人」の理論で、
  /// 自分は意識を移して、みんなを見守る側にまわる。
  none,
}

extension NoahPreferenceLabel on NoahPreference {
  String label(bool ja) => ja ? labelJa : labelEn;

  String get labelJa => switch (this) {
        NoahPreference.men => '男性',
        NoahPreference.women => '女性',
        NoahPreference.all => 'どちらも',
        NoahPreference.none => '恋愛はしない',
      };

  String get labelEn => switch (this) {
        NoahPreference.men => 'Men',
        NoahPreference.women => 'Women',
        NoahPreference.all => 'All',
        NoahPreference.none => 'No romance',
      };

  String note(bool ja) => ja ? noteJa : noteEn;

  String get noteJa => switch (this) {
        NoahPreference.men => '男性8人と船内で過ごします。理論もその8人から選ばれます',
        NoahPreference.women => '女性8人と船内で過ごします。理論もその8人から選ばれます',
        NoahPreference.all => '十六人全員が対象になります',
        NoahPreference.none =>
          '恋愛はしません。十六人全員と対話し、いちばん覚えていた人の理論が採られます',
      };

  String get noteEn => switch (this) {
        NoahPreference.men =>
          'You spend the voyage with the eight men. The theory is chosen from them too.',
        NoahPreference.women =>
          'You spend the voyage with the eight women. The theory is chosen from them too.',
        NoahPreference.all => 'All sixteen are in play.',
        NoahPreference.none =>
          'No romance. You speak with all sixteen, and the theory of whoever you remembered best is adopted.',
      };

  /// 恋愛をするかどうか。
  bool get romantic => this != NoahPreference.none;

  /// 船内で腰を据えて話す相手。ここから採択される理論が決まる。
  List<NoahCharacter> filter(List<NoahCharacter> all) => switch (this) {
        NoahPreference.men => [for (final c in all) if (c.male) c],
        NoahPreference.women => [for (final c in all) if (!c.male) c],
        NoahPreference.all => all,
        // 独身モードでも全員と話す（恋愛にならないだけ）
        NoahPreference.none => all,
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
      '船に乗るのは十六人と、君だ。目覚めたとき、隣が誰か分からない十七人。'),
  NoahLine(NoahVoice.narration,
      '「誰か」のままだと、ひとは集団になれない。'
      '名前を失った十七人は、十七の孤独だ。'),
  NoahLine(NoahVoice.director,
      'だから君たちの仕事は、研究だけじゃない。', who: '所長'),
  NoahLine(NoahVoice.director, '覚えることだ。名前を。全員ぶん。', who: '所長'),
  NoahLine(NoahVoice.narration, '誰かが、小さく息を吐いた。'),
  NoahLine(NoahVoice.narration, '十七の名前——それは、十七の命の輪郭だ。'),
];

/// 🥶 無視されるシーン。名前を覚える意味を、体で知る。
///
/// 十七人のオリエンテーション。全員が名札をつけている。
/// 主人公は話しかけようとするが、誰にも気づかれない。
/// ——名前を呼ばれないと、人はいないのと同じなのだと、そのとき思い知る。
/// そのあと、ただ一人だけが振り返ってくれる。
const List<NoahLine> kNoahColdShoulder = [
  NoahLine(NoahVoice.narration, 'オリエンテーション。十七人が、旧テニスコートの広間に集まっている。'),
  NoahLine(NoahVoice.narration,
      '全員が名札をつけていた。ここでは名前が、その人のすべてだ。'),
  NoahLine(NoahVoice.player, '（……隣の人に、話しかけてみよう）'),
  NoahLine(NoahVoice.player, 'あの、どの研究班ですか'),
  NoahLine(NoahVoice.narration, '返事はなかった。相手は、だれか別の人と話している。'),
  NoahLine(NoahVoice.player, '……すみません、'),
  NoahLine(NoahVoice.narration,
      '今度は、声が届かなかった。広間のざわめきが、ひとりの言葉を埋める。'),
  NoahLine(NoahVoice.narration,
      '十七人のなかで、誰にも気づかれない。'
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
  NoahLine(NoahVoice.narration, '順番に、全員が。十七の「また明日」が壁を埋めた。'),
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
  NoahLine(NoahVoice.narration, 'また、十七人のなかで、ひとりだ。'),
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
const List<int> kNoahCapacitySteps = [4, 8, 12, 16];

/// 節目に届いたときの見出しと、その根拠になった研究。
const List<String> kNoahCapacityReasons = [
  '受精卵と世話人だけの計画',
  '冷凍睡眠の見通しが立った',
  '閉じた生態系が回る計算になった',
  '推進と減速の両方が成立した',
];

const List<String> kNoahCapacityReasonsEn = [
  'A plan with only embryos and their keepers',
  'Cryosleep became plausible',
  'The closed ecosystem balanced on paper',
  'Both thrust and deceleration came together',
];

String noahCapacityReason(int index, bool ja) {
  final list = ja ? kNoahCapacityReasons : kNoahCapacityReasonsEn;
  if (index < 0 || index >= list.length) return '';
  return list[index];
}

/// [correct]問思い出せたときの乗船定員。
///
/// 全問正解で16名（全員）に届くようにしている。
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
      '三百三十年後、十七人が同時に目を覚ます。'
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
      'それだけのことだ。それだけのことが、十七人を集団にする。', who: '所長'),
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
    case 'aizawa':
      return '「よかった……ほどかずに済みました」';
    case 'fuyuki':
      return '「よっ、名人。おあとがよろしいようで」';
    case 'mido':
      return '「ありがとう。……いま、少し体が軽くなりました」';
    case 'karita':
      return '「正解。ちゃんと勝ち筋のほうを覚えててくれたんだ」';
    case 'naka':
      return '「うわ、覚えてる！ じゃあ今度いっしょに潜ろう」';
    case 'ashihara':
      return '「ほう。……待った甲斐があったな」';
    case 'chigusa':
      return '「合ってます。時計より正確ですね、あなた」';
    case 'sakaki':
      return '「よろしい。——では、次の問いに進みましょうか」';
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
    case 'aizawa': return '"Oh good… I didn\'t have to unravel it."';
    case 'fuyuki': return '"Nicely done, maestro. And on that note, I\'ll take my leave."';
    case 'mido': return '"Thank you. …My body feels a little lighter just now."';
    case 'karita': return '"Correct. So you did remember the winning line."';
    case 'naka': return '"Whoa, you remembered! Right, we\'re diving together next time."';
    case 'ashihara': return '"Hm. …Worth the wait, then."';
    case 'chigusa': return '"That\'s right. You\'re more accurate than the clock."';
    case 'sakaki': return '"Very good. —Then shall we move to the next question?"';
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
    case 'aizawa': return '"Aizawa. Cognitive science. …I get restless if my hands aren\'t moving."';
    case 'fuyuki': return '"Fuyuki Ryo. Higher brain function. Thirty years as an opening act, mind you."';
    case 'mido': return '"Mido. I look at consciousness from the body\'s side. …Shall we shake hands?"';
    case 'karita': return '"Karita. Information integration. I built this keyboard myself."';
    case 'naka': return '"Naka Umi! Anaesthesiology. I put people under, and I bring them back."';
    case 'ashihara': return '"Ashihara. Biophysics. …You like smoked food?"';
    case 'chigusa': return '"Chigusa. I study memory. From the direction of time."';
    case 'sakaki': return '"Sakaki. Philosophy. …Your name, once more, if you would."';
    default: return '"I\'m ${c.name}. Nice to meet you."';
  }
}

// ── English story scene lists ─────────────────────────────

const _d = NoahVoice.director; const _n = NoahVoice.narration;
const _p = NoahVoice.player; const _c = NoahVoice.chara;

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
  NoahLine(_n, 'Sixteen people will board this ship, and you. Seventeen who will not know who stands beside them when they wake.'),
  NoahLine(_n, '"Someone" is not enough to form a community. Seventeen without names is seventeen isolates.'),
  NoahLine(_d, 'So your job is not just research.', who: 'Director'),
  NoahLine(_d, 'Your job is to remember. Names. Everyone\'s.', who: 'Director'),
  NoahLine(_n, 'Someone exhaled quietly.'),
  NoahLine(_n, 'Seventeen names—the outlines of seventeen lives.'),
];

const List<NoahLine> kNoahColdShoulderEn = [
  NoahLine(_n, 'Orientation. Seventeen people fill the old tennis court hall.'),
  NoahLine(_n, 'Everyone wears a name tag. Here, your name is everything you are.'),
  NoahLine(_p, '(…Maybe I should try talking to the person next to me.)'),
  NoahLine(_p, 'Hey, what research department are you in?'),
  NoahLine(_n, 'No answer. They\'re already deep in conversation with someone else.'),
  NoahLine(_p, '…Excuse me—'),
  NoahLine(_n, 'This time, your voice doesn\'t even land. The noise of the hall swallows a single person\'s words whole.'),
  NoahLine(_n, 'Seventeen people, and no one notices you. Someone bumps your shoulder. No one turns around.'),
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
  NoahLine(_n, 'Seventeen "see you tomorrow"s cover the wall.'),
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
  NoahLine(_n, 'Seventeen people, and you are alone again.'),
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
  NoahLine(_d, 'Three hundred and thirty years from now, seventeen people will wake up at the same time. Every one of them has lost part of their memory.', who: 'Director'),
  NoahLine(_d, 'The first thing that will happen is not panic, or looting.', who: 'Director'),
  NoahLine(_d, 'It\'s silence.', who: 'Director'),
  NoahLine(_d, 'Someone is next to you, and you can\'t speak to them—because you don\'t know their name.', who: 'Director'),
  NoahLine(_n, 'The director was quiet for a long moment.'),
  NoahLine(_d, 'When someone calls your name, you know you are here.', who: 'Director'),
  NoahLine(_d, 'That\'s all it is. And that small thing is what turns seventeen people into a community.', who: 'Director'),
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

// ── 🔍 船内の謎 ────────────────────────────────

class NoahMystery {
  /// 続けている人。
  final String charaId;

  /// 謎の見出し。
  final String title;
  final String titleEn;

  /// 気づくまでの地の文。
  final String scene;
  final String sceneEn;

  /// 種明かし。心残りとの繋がりをここで言う。
  final String answer;
  final String answerEn;

  const NoahMystery({
    required this.charaId,
    required this.title,
    required this.titleEn,
    required this.scene,
    required this.sceneEn,
    required this.answer,
    required this.answerEn,
  });

  String titleOf(bool ja) => ja ? title : titleEn;
  String sceneOf(bool ja) => ja ? scene : sceneEn;
  String answerOf(bool ja) => ja ? answer : answerEn;
}

const List<NoahMystery> kNoahMysteries = [
  NoahMystery(
    charaId: 'hibino',
    title: '消灯後の工作室で、電気炉だけが温まっている',
    titleEn: 'After lights-out, the electric kiln in the workshop is warm',
    scene: '工作室の電気炉に、夜だけ火が入る。'
        '成形物は何も入っていない。空焚きだ。\n'
        '記録を見ると、温度の上げ下げが妙に不規則で、'
        '途中でわざと弱める時間が挟まっている。',
    sceneEn:
        'The electric kiln in the workshop fires only at night. Nothing is inside it. It is running empty.\n'
        'The logs show the temperature rising and falling oddly, with deliberate lulls worked into the middle.',
    answer: '備前の登り窯の温度カーブを、そのまま再現していた。\n'
        '火を強くしすぎると割れるから、途中で弱める。'
        '実家の窯焚きの手順そのものだ。\n\n'
        '「ただいま」を言えないまま出てきたから、'
        '代わりに毎晩、父の火加減をなぞっている。',
    answerEn:
        'She was reproducing the temperature curve of a Bizen climbing kiln, exactly.\n'
        'Push the fire too hard and the work cracks, so you ease off partway. The firing procedure from her family kiln.\n'
        '\n'
        'She left without ever saying "I\'m home," so every night she traces her father\'s hand on the fire instead.',
  ),
  NoahMystery(
    charaId: 'kiryu',
    title: '談話室の碁盤の石が、毎朝ひとつ増えている',
    titleEn: 'One more stone appears on the go board every morning',
    scene: '談話室の隅に碁盤が置いてある。誰も打っているところを見た人がいない。\n'
        'なのに毎朝、石がひとつだけ増えている。'
        '黒と白が、きちんと交互に。',
    sceneEn:
        'A go board sits in the corner of the lounge. No one has ever seen anyone playing at it.\n'
        'And yet a single stone is added every morning. Black and white, strictly alternating.',
    answer: '相手の手番も、自分で打っていた。\n'
        '一日一手。三百三十年かけて、一局を打ち切るつもりでいる。\n\n'
        '「一緒に碁を打とう」と言ってくれた姉の誘いを、'
        '断り続けたまま船に乗った。'
        'いまは、断らずに打っている。',
    answerEn:
        'He was playing his opponent\'s moves as well.\n'
        'One move a day. He intends to finish a single game over three hundred and thirty years.\n'
        '\n'
        'He boarded the ship having turned down his sister\'s invitation to play, again and again. Now he is playing without refusing.',
  ),
  NoahMystery(
    charaId: 'mizuhara',
    title: '食堂の醤油だけ、補給記録に載っていない',
    titleEn: 'Only the soy sauce in the canteen is missing from the supply records',
    scene: '船の中の物は、一滴残らず収支表に載っている。'
        '載っていなければ、どこかで漏れている。\n'
        'ところが食堂の「特製醤油」だけ、'
        '入庫の記録が三百年ぶん、どこにも無い。',
    sceneEn:
        'Every item aboard is on the balance sheet, down to the drop. If it is not on the sheet, something is leaking.\n'
        'Yet for the canteen\'s "house soy sauce," three hundred years of intake records simply do not exist.',
    answer: '補給していないから、記録が無かった。継ぎ足していただけだ。\n\n'
        '祖母のぬか床は、塩の収支が合わなくて船に持ち込めなかった。'
        'だから乳酸菌と酵母だけを分けて、醤油として起こし直した。\n\n'
        '祖母の六十年に、船の三百三十年を継ぎ足している。',
    answerEn:
        'There were no records because there were no deliveries. She had only been topping it up.\n'
        '\n'
        'Her grandmother\'s fermenting bed could not come aboard — the salt balance would not reconcile. So she separated out the lactic bacteria and yeast alone, and raised them again as soy sauce.\n'
        '\n'
        'Sixty years of her grandmother\'s, with three hundred and thirty of the ship topped onto it.',
  ),
  NoahMystery(
    charaId: 'tachibana',
    title: '観測デッキの鉢に、毎朝だれかが水をやっている',
    titleEn: 'Someone waters a pot on the observation deck every morning',
    scene: '観測デッキの隅に、鉢がひとつ置いてある。'
        '閉じた生態系の収支表に載っていない、規格外の植物だ。\n'
        '当直のロボットへの引き継ぎ書には、一行だけ書いてある。\n'
        '——「量は多すぎないこと。こいつは、待つのが好きな株なので」',
    sceneEn:
        'A single pot sits in the corner of the observation deck. A non-standard plant, absent from the closed ecosystem\'s balance sheet.\n'
        'The handover note for the duty robot carries one line:\n'
        '—"Not too much. This one likes to wait."',
    answer: '地球に残した妻が、最後まで育てていた株の分け身だった。\n\n'
        '「二人の庭を作る」という約束は、間に合わなかった。'
        '墓に水をやることも、ついにできなかった。\n\n'
        'だから三百三十年、毎朝この鉢に水をやっている。',
    answerEn:
        'It was a division of the plant his wife kept tending, back on Earth, to the end.\n'
        '\n'
        'The promise to "make a garden for the two of us" did not come in time. Nor, in the end, could he water her grave.\n'
        '\n'
        'So for three hundred and thirty years he has watered this pot every morning.',
  ),
  NoahMystery(
    charaId: 'hoshino',
    title: '観測窓の、いちばん何も無い方角にカメラが向いている',
    titleEn: 'The camera points at the emptiest direction out the observation window',
    scene: '船の望遠カメラが、毎晩きまった方角を向く。\n'
        '進行方向でもなければ、目的地でもない。'
        '撮っても何も写らない、ただ黒いだけの方角だ。',
    sceneEn:
        'The ship\'s telescope turns to the same bearing every night.\n'
        'Not the heading, not the destination. A direction where nothing registers — only black.',
    answer: '船が出てきた方角だった。\n'
        '四十九光年ぶん離れると、太陽はもう星の一粒にもならない。'
        'だから何も写らない。\n\n'
        '「本当の星空を見せる」と祖父に約束したまま、'
        '地上の空はとうに赤く濁ってしまった。\n'
        '見せられなかったぶんを、毎晩ここから撮り続けている。',
    answerEn:
        'It was the direction the ship came from.\n'
        'At forty-nine light years out, the sun is not even a grain of a star. So nothing registers.\n'
        '\n'
        'She promised her grandfather she would show him a real night sky, and the sky above the ground turned red long before that.\n'
        'What she could not show him, she photographs here every night instead.',
  ),
  NoahMystery(
    charaId: 'iwao',
    title: 'カラオケの掲示板に、匿名の俳句が一句ずつ増える',
    titleEn: 'An anonymous haiku appears on the karaoke noticeboard, one at a time',
    scene: '掲示板に、誰のものとも書かれていない句が貼られる。'
        '目覚めるたびに、一句だけ。\n'
        '達筆で、素っ気なくて、決して名前が入っていない。\n'
        '——並べてみると、季語が全部おなじだった。',
    sceneEn:
        'Poems go up on the board with no name attached. One each time the crew wakes.\n'
        'Fine handwriting, blunt, never signed.\n'
        '—Lined up together, every one carried the same season word.',
    answer: '全句に「山」が入っていた。船に山は無い。\n\n'
        '若いころ、開発で山をひとつ潰した。'
        '標高三百十二メートル、名前の付いていない山だった。'
        '名前が無かったから、誰も反対しなかった。\n\n'
        '故郷の山に最後に登れなかったぶんを、句で登り直している。',
    answerEn:
        'Every poem contained "mountain." There is no mountain on the ship.\n'
        '\n'
        'In his youth, a development project of his flattened one. Three hundred and twelve metres, unnamed. Because it had no name, no one objected.\n'
        '\n'
        'The climb he never made up his home mountain, he climbs again in verse.',
  ),
  NoahMystery(
    charaId: 'kusunoki',
    title: '誰も使っていない周波数に、毎晩ノイズが乗る',
    titleEn: 'Noise rides a frequency nobody uses, every night',
    scene: '船の通信帯のうち、いちばん端の周波数は空いている。'
        '割り当てが無いから、誰も使わない。\n'
        'その帯に、毎晩きまった時刻だけノイズが乗る。'
        '意味のある信号ではない。ただの雑音だ。\n'
        'なのに、聞いていると笑い方のクセのようなものが混じって聞こえる。',
    sceneEn:
        'The furthest edge of the ship\'s comm band is vacant. Unallocated, so no one uses it.\n'
        'Noise rides that band at the same hour every night. Not a meaningful signal. Just static.\n'
        'And yet, listening to it, something like the shape of a laugh keeps surfacing in it.',
    answer: '兄のラジオを、鳴らし続けていた。\n\n'
        '真空管の一本がどうしても手に入らなくて、'
        '最後まで直せないまま兄を見送った。\n'
        '直しきれない機械は、鳴らしておくしかない。\n\n'
        '「雑音でも、鳴っていれば壊れてはいない」——'
        'それが、修理屋の理屈だった。',
    answerEn:
        'She was keeping her brother\'s radio playing.\n'
        '\n'
        'One vacuum tube she could never source, so she saw her brother off with it still unrepaired.\n'
        'A machine you cannot finish repairing, you can only leave running.\n'
        '\n'
        '"Static or not, if it\'s making a sound it isn\'t broken." — the repairer\'s reasoning.',
  ),
  NoahMystery(
    charaId: 'shirakawa',
    title: '冷凍ポッドの番号札が、毎晩ひとつだけ磨かれている',
    titleEn: 'One number plate on the cryo pods is polished each night',
    scene: 'ポッドは十六基。全部磨いても、一晩で終わる。\n'
        'なのに毎晩、必ずひとつだけ磨かれている。'
        '十六日かけて一周し、また最初に戻る。',
    sceneEn:
        'There are sixteen pods. Polishing all of them takes a single evening.\n'
        'And yet exactly one is polished each night. Sixteen days to come round, then back to the first.',
    answer: '磨くとき、番号ではなく名前を声に出していた。\n\n'
        'かつて三人の患者を、冷凍で見送った。'
        'カルテには番号しか残していない。'
        '名前で呼ぶと、失敗が「人」になってしまうからだ。\n\n'
        '「大丈夫」と言えなかったぶん、名前だけは呼ぶことにした。'
        '十六人ぶん、順番に。',
    answerEn:
        'As he polished, he spoke aloud not the number but the name.\n'
        '\n'
        'He once saw three patients out under cryo. His charts record only numbers. Call them by name and the failure becomes a person.\n'
        '\n'
        'For every time he could not say "it\'ll be fine," he decided he would at least say the name.',
  ),
  NoahMystery(
    charaId: 'aizawa',
    title: '談話室の毛糸が、毎晩ひと巻きだけ減っている',
    titleEn: 'One ball of yarn goes missing from the lounge every night',
    scene: '船に毛糸は持ち込めない。繊維は全部、循環系の資源として登録されている。\n'
        'なのに談話室の籠から、毎晩ひと巻きぶんだけ減る。\n'
        '減ったぶんは翌朝、きちんと同じ量だけ戻っている。',
    sceneEn:
        'Yarn cannot be brought aboard. All fibre is registered as a resource of the recycling system.\n'
        'And yet the basket in the lounge loses exactly one ball\'s worth every night.\n'
        'By the next morning, exactly that much has been returned.',
    answer: '編んではほどき、ほどいては編んでいた。\n\n'
        '地球で、母のセーターを編み終えられなかった。'
        '袖が片方だけ残ったまま、間に合わなかった。\n'
        '完成させてしまうと終わってしまうので、'
        '毎晩おなじところまで編んで、朝までにほどく。\n\n'
        '「終わらせないでおくのも、続けるうちなんです」',
    answerEn:
        'She was knitting and unravelling, unravelling and knitting.\n'
        '\n'
        'On Earth she never finished her mother\'s sweater. One sleeve was left, and time ran out.\n'
        'Finishing it would end it, so every night she knits to the same point and unravels it before morning.\n'
        '\n'
        'As long as it is not finished, it is not over.',
  ),
  NoahMystery(
    charaId: 'fuyuki',
    title: '誰もいない食堂から、笑い声だけが聞こえる日がある',
    titleEn: 'Some days, laughter comes from an empty canteen',
    scene: '当直の記録では、その時間、食堂には誰もいない。\n'
        'なのに扉の外まで、拍子のそろった笑い声が届く。'
        '録音しても、声は一人ぶんしか入っていない。',
    sceneEn:
        'The duty log says the canteen was empty at that hour.\n'
        'And yet laughter, in perfect rhythm, carries past the door. Recorded, the audio holds only one voice.',
    answer: '一人で高座をやっていた。客席のぶんの笑いも、自分で入れて。\n\n'
        '師匠の十八番を継がないまま船に乗った。'
        '継がなかった噺は、演じる人がいなくなれば消える。\n'
        'だから客がいなくても掛け続ける。'
        '笑いどころで笑う人がいないと噺は死ぬので、そこも自分でやる。\n\n'
        '「噺は、覚えてるやつが一人いれば残るんです」',
    answerEn:
        'He was performing alone — supplying the audience\'s laughter himself.\n'
        '\n'
        'He boarded without inheriting his master\'s signature piece. A story not inherited disappears once no one performs it.\n'
        'So he performs it with no audience. A story dies when no one laughs where the laugh belongs.',
  ),
  NoahMystery(
    charaId: 'mido',
    title: '低重力室の床に、毎朝きれいな円が描かれている',
    titleEn: 'A clean circle is drawn on the low-gravity room floor each morning',
    scene: '0.5G室の床に、直径四メートルほどの円が薄く残っている。'
        '掃除しても翌朝また現れる。\n'
        '床材の摩耗を測ると、円周に沿って均等に減っていた。'
        '——同じところを、同じ速さで、何百回も。',
    sceneEn:
        'A circle about four metres across sits faintly on the floor of the 0.5G room. Cleaned away, it reappears the next morning.\n'
        'Measure the wear on the flooring and it is even along the circumference. —The same place, at the same speed, hundreds of times.',
    answer: '毎朝、一人で受け身を取り続けていた。\n\n'
        '父の介護を人任せにしたまま、看取れなかった。'
        '身体に触れる仕事を選んだのに、いちばん触れるべき体に触れなかった。\n\n'
        '「倒れる練習です。倒れ方を知らない人は、人を支えられないので」',
    answerEn:
        'Every morning, alone, she was practising how to fall.\n'
        '\n'
        'She left her father\'s care to others and was not there at the end. She chose work that touches bodies, and did not touch the one body that mattered.\n'
        '\n'
        '"It\'s falling practice. Someone who doesn\'t know how to fall can\'t hold anyone up."',
  ),
  NoahMystery(
    charaId: 'karita',
    title: '船内端末のキー配列が、一台だけ違う',
    titleEn: 'One terminal aboard has a different key layout',
    scene: '十七台ある端末のうち、一台だけキーの並びが標準と違う。'
        '登録上は同じ型番で、改造の申請も出ていない。\n'
        '使っている人を見た者はいない。'
        'それでも摩耗の具合から、毎日誰かが打っているのは確かだった。',
    sceneEn:
        'Of the seventeen terminals, exactly one has a non-standard key arrangement. Registered as the same model, with no modification request filed.\n'
        'No one has seen anyone using it. Still, the wear makes it certain that someone types on it daily.',
    answer: '喧嘩別れした共同開発者の配列だった。\n\n'
        '二人で作りかけていたものが、途中で止まった。'
        '相手の癖に合わせた並びだけが、直さないまま残っている。\n'
        '直せば楽になる。直さないのは、直したら忘れるからだ。\n\n'
        '「その人らしさって、勝ち方じゃなくて負け方のほうに出るんですよ」',
    answerEn:
        'It was the layout of the co-developer he fell out with.\n'
        '\n'
        'What the two of them were building together stopped halfway. Only the arrangement fitted to the other man\'s habits remains, uncorrected.\n'
        'Fixing it would make things easier. He does not fix it because fixing it means forgetting.\n'
        '\n'
        '"What makes someone themselves shows up in how they lose."',
  ),
  NoahMystery(
    charaId: 'naka',
    title: '人工河川の水位が、毎晩ほんの少しだけ下がる',
    titleEn: 'The artificial river drops a little every night',
    scene: '循環系の収支は合っている。漏れてはいない。'
        'ただ、決まった時刻に数センチだけ水位が下がり、しばらくして戻る。\n'
        '——何かが、沈んでいる。',
    sceneEn:
        'The recycling balance reconciles. Nothing is leaking. It is only that at a fixed hour the level falls a few centimetres, and later returns.\n'
        '—Something is sinking.',
    answer: '毎晩、川底に潜って息を止めていた。\n\n'
        '祖母に海を見せると言って、果たせないまま船に乗った。'
        '船に海は無い。いちばん深いのが、この川の底だ。\n'
        '潜って、目を開けて、上を見る。それだけで海の代わりになる。\n\n'
        '「浮くところまでが海なんです。沈むだけなら、ただの水なので」',
    answerEn:
        'Every night she dived to the riverbed and held her breath.\n'
        '\n'
        'She promised to show her grandmother the sea, and boarded without keeping it. There is no sea aboard. The deepest thing is the bottom of this river.\n'
        'Dive, open your eyes, look up. That alone stands in for the sea.\n'
        '\n'
        '"The sea is the part up to where you surface."',
  ),
  NoahMystery(
    charaId: 'ashihara',
    title: 'フードコートの片隅で、いつも同じ温度が保たれている',
    titleEn: 'One corner of the food court is always held at the same temperature',
    scene: '空調の記録に、説明のつかない一角がある。'
        '摂氏28度前後を、三百年ずっと保っている小さな区画。\n'
        '何かを温めているのでも、冷やしているのでもない。'
        'ただ、変わらないように保っている。',
    sceneEn:
        'There is an unexplained pocket in the climate logs. A small zone held near 28°C for three hundred years.\n'
        'It is not warming anything, nor cooling anything. It is only being kept from changing.',
    answer: '燻製の代わりだった。煙は出せないので、温度だけを再現している。\n\n'
        '弟子に何も教えないまま送り出したことを、ずっと悔いていた。'
        '手順は言葉にすると死ぬ、と思い込んでいたからだ。\n'
        'だから温度だけを残した。いつか誰かが気づいて、訊きに来るように。\n\n'
        '「待てるかどうかだけなんだ、こういうのは」',
    answerEn:
        'It stood in for a smokehouse. Smoke is not permitted aboard, so he reproduced the temperature alone.\n'
        '\n'
        'He had always regretted sending his apprentice off without teaching him anything, convinced that procedure dies once you put it into words.\n'
        'So he left the temperature. In the hope that someone, someday, would notice and read it back.',
  ),
  NoahMystery(
    charaId: 'chigusa',
    title: '船内時計より、いつも七分遅れている時計がある',
    titleEn: 'One clock always runs seven minutes behind ship time',
    scene: '観測室の壁に、規格外の機械式時計が掛かっている。'
        '積載記録には「私物・重量200g」としか書かれていない。\n'
        '止まってはいない。ただ、いつ見ても船内時刻より七分遅れている。\n'
        '誰も直そうとしない。',
    sceneEn:
        'A non-standard mechanical clock hangs on the observation room wall. The manifest records only "personal effect, 200g."\n'
        'It has not stopped. It simply reads seven minutes behind ship time, whenever you look.\n'
        'No one tries to correct it.',
    answer: '祖父の時計で、地球を出た瞬間に止めたものだった。\n\n'
        '七分は、発射から最後の通信が届くまでの時間。'
        'そのぶんだけ遅らせて、動かし直してある。\n'
        '直せば合う。合わせないのは、合わせたら地球が消えるからだ。\n\n'
        '「止まった時計は直せます。でも、止めないほうがずっと楽なので」',
    answerEn:
        'It was her grandfather\'s clock, stopped at the instant they left Earth.\n'
        '\n'
        'Seven minutes is how long the last transmission took to arrive after launch. She set it back by exactly that, and started it again.\n'
        'Correcting it would make it agree. She does not, because agreeing would make Earth disappear.\n'
        '\n'
        '"A stopped clock can be repaired."',
  ),
  NoahMystery(
    charaId: 'sakaki',
    title: '図書区画に、同じ一行だけを写した紙が積まれている',
    titleEn: 'In the library, sheets copying a single line are stacked up',
    scene: '紙は貴重品なので、船内では再生紙しか使えない。'
        'その再生紙が、同じ一行だけを繰り返し写した状態で積まれている。\n'
        '写経のようだが、経文ではない。'
        '読むと、それは<b>問いかけ</b>だった。',
    sceneEn:
        'Paper is precious; only recycled stock may be used aboard. That recycled stock is stacked up, each sheet copying one line over and over.\n'
        'It looks like sutra-copying, but it is no sutra. Read it, and it is a <b>question</b>.',
    answer: '妻の問いだった。四十年、答えないまま来た問い。\n\n'
        '答えを書けば終わる。書けないから、問いのほうを写し続けている。\n'
        '写しているあいだは、まだ考えていることになるからだ。\n\n'
        '「答えは要りません。何を気にしているかが、あなたですから」\n'
        '——彼自身が、いちばんそれを実践していた。',
    answerEn:
        'It was his wife\'s question. The one he came forty years without answering.\n'
        '\n'
        'Writing the answer would end it. Because he cannot write it, he goes on copying the question instead.\n'
        'While he is copying, he is still thinking about it.\n'
        '\n'
        '"I don\'t need the answer. What you mind — that is you."',
  ),
];

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

/// キャラIDから謎を引く。持っていない人なら null。
NoahMystery? noahMysteryFor(String charaId) {
  for (final m in kNoahMysteries) {
    if (m.charaId == charaId) return m;
  }
  return null;
}

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
    case 'aizawa':
      return '「見てたんですね。……終わらせないでおくのも、続けるうちなので」';
    case 'fuyuki':
      return '「聞こえてましたか。いや、客がいないと噺は死ぬもんで」';
    case 'mido':
      return '「よく気づきました。倒れ方を知らない人は、人を支えられませんから」';
    case 'karita':
      return '「バレたか。直せば楽なんですけどね。直すと忘れるので」';
    case 'naka':
      return '「あー、水位でバレた。ちゃんと戻してたんだけどな」';
    case 'ashihara':
      return '「気づいたか。……いつか誰かが訊きに来ると思ってた」';
    case 'chigusa':
      return '「七分、数えたんですね。合わせないのは、合わせたら消えるからです」';
    case 'sakaki':
      return '「読みましたか。答えは書いてありませんよ。まだ考えているので」';
    default:
      return '「……よく気づいたね」';
  }
}

String noahMysteryMissLineJa(NoahCharacter picked, NoahCharacter culprit) =>
    '「${picked.name}さんじゃないよ。'
    'その人にも心残りはあるけど、これは別の人のかたちだ」';

String noahMysteryHitLineEn(NoahCharacter c) {
  switch (c.id) {
    case 'hibino':
      return '"…You saw. How embarrassing. Firing it empty is a waste of fuel, I know."';
    case 'kiryu':
      return '"Well spotted. —Yes, I play his side too. Does that count as cheating?"';
    case 'mizuhara':
      return '"Caught me. Put it on the balance sheet and someone asks whether we really need it."';
    case 'tachibana':
      return '"…You worked it out. One pot that doesn\'t meet spec. That\'s all it is."';
    case 'hoshino':
      return '"Nothing registers over there, you know. I still want it pointed that way."';
    case 'iwao':
      return '"Got me on the season word. …Not bad, youngster."';
    case 'kusunoki':
      return '"You could hear it? Good. I thought I was the only one who could."';
    case 'shirakawa':
      return '"Seen, was I. …It isn\'t a memorial. It\'s part of the procedure."';
    case 'aizawa':
      return '"So you were watching. …Leaving it unfinished is part of keeping it going."';
    case 'fuyuki':
      return '"You heard that? Well — a story dies without an audience."';
    case 'mido':
      return '"Well noticed. Someone who doesn\'t know how to fall can\'t hold anyone up."';
    case 'karita':
      return '"Found out. It\'d be easier fixed, sure. Fix it and I forget."';
    case 'naka':
      return '"Ah — the water level gave me away. I did put it back, you know."';
    case 'ashihara':
      return '"You noticed. …I always thought someone would come and ask, eventually."';
    case 'chigusa':
      return '"You counted the seven minutes. I don\'t set it right because setting it right makes it vanish."';
    case 'sakaki':
      return '"You read it. There\'s no answer written there. I\'m still thinking."';
    default:
      return '"…Well noticed."';
  }
}

String noahMysteryMissLineEn(NoahCharacter picked, NoahCharacter culprit) =>
    '"It isn\'t ${picked.name}. They carry regrets of their own, '
    'but this is the shape of someone else\'s."';

/// 日英どちらの台詞を出すかはここで選ぶ（画面側は ja だけ渡せばよい）。
String noahMysteryHitLine(NoahCharacter c, bool ja) =>
    ja ? noahMysteryHitLineJa(c) : noahMysteryHitLineEn(c);

String noahMysteryMissLine(
        NoahCharacter picked, NoahCharacter culprit, bool ja) =>
    ja
        ? noahMysteryMissLineJa(picked, culprit)
        : noahMysteryMissLineEn(picked, culprit);

/// 🎓 所長の名前。作中で主人公が**唯一なくす名前**なので、
/// 台詞のなかに直接書かず、ここ1か所から差しこむ。
const String kNoahDirectorName = '土倉 源三';

/// 真エンドに必要な世界線の一致度。
const double kNoahTrueEndDivergence = 1.0;

/// 記憶がにじむ「隣り合ったポッド」の組数。
const int kNoahEntangledPairs = 3;

// ── 📖 追加シーン（定員の宣告 / 忘れた名前 / 船内の謎 / 航行中の危機 / 意識の淘汰）──

const List<NoahLine> kNoahCapacityScene = [
  NoahLine(NoahVoice.director, 'もうひとつ、先に言っておく。', who: '所長'),
  NoahLine(NoahVoice.director, 'この船に乗れるのは、四名だ。', who: '所長'),
  NoahLine(NoahVoice.narration, '——誰も、声を出さなかった。'),
  NoahLine(NoahVoice.player, '……四人。ここに残っているのは、十七人ですよね'),
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
      '四名は、その荷物を四十九光年運ぶための世話人にすぎん。', who: '所長'),
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
      '冷凍睡眠が確かになれば八名。生態系が閉じれば十二名。',
      who: '所長'),
  NoahLine(NoahVoice.director,
      '推進と減速の両方が成立すれば——十六名。全員だ。', who: '所長'),
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
const List<NoahLine> kNoahCapacitySceneEn = [
  NoahLine(NoahVoice.director, 'One more thing, before we go on.', who: 'Director'),
  NoahLine(NoahVoice.director, 'This ship can carry four.', who: 'Director'),
  NoahLine(NoahVoice.narration, '—No one made a sound.'),
  NoahLine(NoahVoice.player, '…Four. There are seventeen of us left here, aren\'t there'),
  NoahLine(NoahVoice.director, 'It is not discrimination, and it is not a lottery. It is only physics.', who: 'Director'),
  NoahLine(NoahVoice.director, 'Forty percent return from cryosleep. The ecosystem\'s mass balance does not close. The propellant mass ratio does not allow it. Let any one of the three fail and the ship is simply a coffin.', who: 'Director'),
  NoahLine(NoahVoice.director, 'So the protagonists of this plan are not people. They are ten thousand embryos and the artificial wombs.', who: 'Director'),
  NoahLine(NoahVoice.director, 'The four are no more than keepers, carrying that cargo forty-nine light years.', who: 'Director'),
  NoahLine(NoahVoice.narration, 'Those who are ruled out write one letter each, addressed to those who go.'),
  NoahLine(NoahVoice.narration, 'It is opened after arrival and placed in the first library of the new world. That was the only passage granted to the ones who stay.'),
  NoahLine(NoahVoice.narration, '—They are called "the goodbye letters."'),
  NoahLine(NoahVoice.narration, 'The scientists had all written one too. The engineering slots number four at the most. Half of the eight will see off the ship they built.'),
  NoahLine(NoahVoice.director, 'But this number moves.', who: 'Director'),
  NoahLine(NoahVoice.director, 'Every time a piece of research lands, the number who can board goes up. Make cryosleep certain and it is eight. Close the ecosystem and it is twelve.', who: 'Director'),
  NoahLine(NoahVoice.director, 'Make both thrust and deceleration work — and it is sixteen. Everyone.', who: 'Director'),
  NoahLine(NoahVoice.player, '…What is it I should do'),
  NoahLine(NoahVoice.director, 'Remember.', who: 'Director'),
  NoahLine(NoahVoice.director, 'This ship grows by exactly as much as you can recall.', who: 'Director'),
  NoahLine(NoahVoice.narration, '—The director set the bound roster down on the desk.'),
  NoahLine(NoahVoice.narration, 'Only twelve lines are filled in.'),
  NoahLine(NoahVoice.director, 'This is yours to carry. You write in it, and you read from it.', who: 'Director'),
  NoahLine(NoahVoice.player, '…Are you not boarding, Director'),
  NoahLine(NoahVoice.narration, 'No answer came back.'),
  NoahLine(NoahVoice.narration, 'Eighty cards were printed. Ten each for eight people. The arithmetic comes out exactly even.'),
  NoahLine(NoahVoice.narration, 'For this one person, there is not a single card.'),
  NoahLine(NoahVoice.director, 'I am \\$kNoahDirectorName.', who: 'Director'),
  NoahLine(NoahVoice.director, '…You needn\'t remember it. There is no card to hand you', who: 'Director'),
];

const List<NoahLine> kNoahForgot = [
  NoahLine(NoahVoice.narration, '——テストのあと、ふと手が止まる。'),
  NoahLine(NoahVoice.narration,
      '目が覚めるたび、名簿を頭から順に呼ぶことにしていた。'
      '台帳は開かない。開いたら負けだと思っている。'),
  NoahLine(NoahVoice.narration, '一番から、十六番まで。詰まらなかった。'),
  NoahLine(NoahVoice.narration, 'そして、十七人目で止まった。'),
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
      'この船の十六人は、二十八年ごとに目の前に出てくる。'
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
      'そして——十六人に、ひとつだけ頼んで回ることになる。'),
  NoahLine(NoahVoice.narration, '「すれ違ったら、相手を名前で呼んでください」。'),
  NoahLine(NoahVoice.narration,
      '理由は言えなかった。自分が一人ぶん失くしたとは、'
      'どうしても言えなかったからだ。'),
  NoahLine(NoahVoice.narration,
      'それでも全員がやった。うるさくて、少し滑稽で、'
      '二百年近く誰も欠かさなかった。'),
];
const List<NoahLine> kNoahForgotEn = [
  NoahLine(NoahVoice.narration, '—After the test, my hand stops.'),
  NoahLine(NoahVoice.narration, 'Every time I woke, I made a point of calling the roster from the top. I do not open the ledger. Opening it feels like losing.'),
  NoahLine(NoahVoice.narration, 'From the first to the sixteenth. No stumbles.'),
  NoahLine(NoahVoice.narration, 'And then I stopped at the seventeenth.'),
  NoahLine(NoahVoice.narration, 'The face comes. White hair. Thick hands. A crooked collar.'),
  NoahLine(NoahVoice.narration, 'The voice comes too. "Four thousand years of Chinese history? That\'s nothing." "Today\'s hole, par four."'),
  NoahLine(NoahVoice.narration, 'The lights on the eighteenth green. The bound roster set down on the desk.'),
  NoahLine(NoahVoice.narration, 'All of it is there.'),
  NoahLine(NoahVoice.narration, 'Only the name is missing.'),
  NoahLine(NoahVoice.player, '…You\'re joking'),
  NoahLine(NoahVoice.chara, 'Ah, that. The reasoning is simple'),
  NoahLine(NoahVoice.chara, 'The sixteen aboard this ship appear in front of you every twenty-eight years. You see the face, hear the voice, call the name. Each time, it is painted over again'),
  NoahLine(NoahVoice.chara, 'That person is not aboard'),
  NoahLine(NoahVoice.chara, 'There was never once a chance to repaint it'),
  NoahLine(NoahVoice.narration, '—The thing I believed I was keeping most carefully was the first to thin out.'),
  NoahLine(NoahVoice.narration, 'Because I only kept it. I never used it.'),
  NoahLine(NoahVoice.player, '…If I look it up, it will be in the ship\'s records'),
  NoahLine(NoahVoice.chara, 'It is. Three seconds\' work'),
  NoahLine(NoahVoice.player, 'A name I got by looking it up does not count as remembering'),
  NoahLine(NoahVoice.chara, 'Sentiment'),
  NoahLine(NoahVoice.player, 'Yes'),
  NoahLine(NoahVoice.chara, '…Good sentiment. I\'ll go along with it'),
  NoahLine(NoahVoice.narration, 'From that day, the personnel column of the ship\'s records was locked. One physician alone can open it.'),
  NoahLine(NoahVoice.narration, 'And—I ended up going round to the sixteen with one request.'),
  NoahLine(NoahVoice.narration, '"If you pass someone, call them by name."'),
  NoahLine(NoahVoice.narration, 'I could not give a reason. I could not bring myself to say that I had lost one person\'s worth.'),
  NoahLine(NoahVoice.narration, 'They all did it anyway. Noisy, slightly absurd, and for nearly two hundred years not one of them missed a day.'),
];

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
const List<NoahLine> kNoahBeforeMysteryEn = [
  NoahLine(NoahVoice.narration, '—During the voyage, the ship acquires a few odd habits.'),
  NoahLine(NoahVoice.narration, 'They appear on no duty roster and no balance sheet. And yet decades pass without them breaking.'),
  NoahLine(NoahVoice.narration, 'No one admits to doing them. They do no harm, so no one presses.'),
  NoahLine(NoahVoice.player, '…But I have an idea'),
  NoahLine(NoahVoice.narration, 'When I walked the ship, each of them told me one thing they had left undone.'),
  NoahLine(NoahVoice.narration, 'If I remember that, I can probably work it out.'),
];

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
const List<NoahLine> kNoahMidVoyageEn = [
  NoahLine(NoahVoice.narration, '—Voyage, year one hundred and sixty-three.'),
  NoahLine(NoahVoice.narration, 'The scheduled signal from "John," the advance probe sent eighty years ahead, has stopped.'),
  NoahLine(NoahVoice.chara, 'The atmospheric model may be wrong'),
  NoahLine(NoahVoice.chara, 'Without nitrogen, our bacteria will not take root'),
  NoahLine(NoahVoice.player, '…Can we turn back'),
  NoahLine(NoahVoice.chara, 'No'),
  NoahLine(NoahVoice.chara, 'The magnetic sail we decelerate with only works in that star\'s wind. There is no way to stop here'),
  NoahLine(NoahVoice.narration, 'Silence.'),
  NoahLine(NoahVoice.chara, 'Then we build bacteria for the case where the model is wrong too'),
  NoahLine(NoahVoice.chara, 'We have a hundred and sixty years. Forty years per line — four lines will make it'),
  NoahLine(NoahVoice.narration, '—The reason for "John\'s" silence becomes clear only just before arrival.'),
  NoahLine(NoahVoice.narration, 'The probe had not broken. Its self-replicating machines had multiplied so far that they converted the transmitting antenna itself into feedstock.'),
  NoahLine(NoahVoice.narration, 'It was the silence of having succeeded too well.'),
];

const List<NoahLine> kNoahConsciousness = [
  NoahLine(NoahVoice.narration, '——減速の前に、もうひとつ終わった実験がある。'),
  NoahLine(NoahVoice.chara, 'この船は、意識を調べる装置としては異常です'),
  NoahLine(NoahVoice.chara,
      '十七人の意識が、二十八年ごとに十一回、'
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
  NoahLine(NoahVoice.chara, '毎晩磨かれていた十六枚は、墓標だったことになる'),
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
  NoahLine(NoahVoice.chara, '——十七人は、一度も死んでいない'),
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
const List<NoahLine> kNoahConsciousnessEn = [
  NoahLine(NoahVoice.narration, '—Before the deceleration, one more experiment came to an end.'),
  NoahLine(NoahVoice.chara, 'As an instrument for studying consciousness, this ship is abnormal'),
  NoahLine(NoahVoice.chara, 'Seventeen consciousnesses stop completely and start again, eleven times, once every twenty-eight years. No one on the ground could build that'),
  NoahLine(NoahVoice.player, '…And did it show you anything'),
  NoahLine(NoahVoice.chara, 'On Earth, it was never settled'),
  NoahLine(NoahVoice.chara, 'You line up two theories of consciousness, make them commit in advance to what each predicts, and have a third party run it. Even then, no winner emerged'),
  NoahLine(NoahVoice.chara, 'Here, twenty-five of the twenty-nine fell'),
  NoahLine(NoahVoice.narration, '—Theories that could say nothing about the interval when it is stopped fell first.'),
  NoahLine(NoahVoice.narration, '—Theories that explain everything inside the brain alone fell next. They could not account for the fact that memory bleeds more between neighbouring pods.'),
  NoahLine(NoahVoice.chara, 'Three were left. All of them strong'),
  NoahLine(NoahVoice.chara, 'That information broadcast widely is consciousness'),
  NoahLine(NoahVoice.chara, 'That the amount of integrated information is consciousness'),
  NoahLine(NoahVoice.chara, 'That the electromagnetic field the brain generates simply is consciousness'),
  NoahLine(NoahVoice.narration, '—The third was refuted directly, aboard this ship.'),
  NoahLine(NoahVoice.narration, 'On the day the magnetic sail opened, the electromagnetic environment changed by orders of magnitude. Nothing whatsoever happened to anyone\'s consciousness.'),
  NoahLine(NoahVoice.chara, 'The problem is the two that remain'),
  NoahLine(NoahVoice.chara, 'If the broadcast stops, there is no consciousness'),
  NoahLine(NoahVoice.chara, 'If integration is lost, there is no consciousness'),
  NoahLine(NoahVoice.chara, 'Either way the conclusion is the same. —Everyone aboard this ship has died eleven times and been born eleven times'),
  NoahLine(NoahVoice.narration, 'No one said anything.'),
  NoahLine(NoahVoice.chara, 'The person who said "I will never let anyone die again" has already let them die eleven times'),
  NoahLine(NoahVoice.chara, 'The sixteen plates polished each night turn out to have been gravestones'),
  NoahLine(NoahVoice.chara, 'The reasoning holds. No one can refute it'),
  NoahLine(NoahVoice.chara, '…Only, I had no intention of accepting it'),
  NoahLine(NoahVoice.narration, '—There is one thing that had been measured across three hundred years.'),
  NoahLine(NoahVoice.narration, 'The closer two pods sit, the more the memories mix. And that mixing falls off with distance.'),
  NoahLine(NoahVoice.narration, 'There is no wiring between the pods. They are shielded. There is nowhere for information to cross.'),
  NoahLine(NoahVoice.chara, 'A vitrified brain has almost no thermal noise left'),
  NoahLine(NoahVoice.chara, 'In that state, things placed close together keep a correlation. The bleed is the trace of it'),
  NoahLine(NoahVoice.player, '…And calling the name reduces it because'),
  NoahLine(NoahVoice.chara, 'A state that has been called is a state that has been measured, repeatedly'),
  NoahLine(NoahVoice.chara, 'What is measured is severed from the correlation'),
  NoahLine(NoahVoice.narration, '—Two hundred years of asking everyone for something without giving a reason: here, at last, the reason arrived.'),
  NoahLine(NoahVoice.chara, 'What you were doing was not sentiment'),
  NoahLine(NoahVoice.chara, 'It was preservation work'),
  NoahLine(NoahVoice.narration, '—And then the most important thing comes out.'),
  NoahLine(NoahVoice.chara, 'Quantum states cannot be copied'),
  NoahLine(NoahVoice.chara, 'Making a copy without destroying the original is impossible in principle'),
  NoahLine(NoahVoice.chara, 'If nothing was copied, twenty-eight years of sleep cannot be "died and was remade"'),
  NoahLine(NoahVoice.chara, 'What came back is the same thing'),
  NoahLine(NoahVoice.chara, '—The seventeen of us have never died. Not once'),
  NoahLine(NoahVoice.narration, 'And the question this person had carried for forty years vanished, with no answer given.'),
  NoahLine(NoahVoice.narration, '"Is a copied consciousness the person?"'),
  NoahLine(NoahVoice.narration, 'A copy cannot be made. There is no use asking about something that cannot be made.'),
  NoahLine(NoahVoice.chara, 'All that can be done is to move it'),
  NoahLine(NoahVoice.chara, 'Move it and the original is always destroyed. No spare remains. You never become two'),
  NoahLine(NoahVoice.chara, '—The thing we had been calling "moving house."'),
  NoahLine(NoahVoice.narration, 'This person had been saying so for three hundred and thirty years. It had simply taken three hundred and thirty years to become provable.'),
];

// ── 🌐 世界線（どれだけ思い出せたか） ──────────────────

double noahDivergence(
  Map<String, Set<NoahField>> remembered,
  int askable, {
  int extra = 0,
}) {
  if (askable <= 0) return 0;
  var hit = extra;
  for (final fields in remembered.values) {
    hit += fields.length;
  }
  final d = hit / askable;
  return d > 1 ? 1 : d;
}

String noahWorldLineJa(double divergence) {
  if (divergence >= kNoahTrueEndDivergence) return 'Ω';
  if (divergence >= 0.6) return 'γ';
  if (divergence >= 0.3) return 'α';
  return 'β';
}

String noahDivergenceLabel(double d) => d.toStringAsFixed(6);

/// 世界線の記号はギリシャ文字なので言語で変えない。
/// 見出し語だけ言語で切り替える。
String noahWorldLineLabel(bool ja) => ja ? '世界線' : 'World line';
