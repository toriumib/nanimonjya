/// 🤖 CPU対戦の相手——名前と顔と個性を持ったキャラクター。
///
/// ペアさがしのCPU対戦が「ただの神経衰弱」にならないように、
/// 相手に名前と趣味と口癖を持たせる。
/// 対戦中に喋り、勝敗リアクションも変える。
///
/// 🌍 **日英それぞれの人格を持つ。**
///    英語版に日本語名の相手（「野中 ゆず / 趣味: カラオケ・TikTok」）が
///    出ていて、画面の一等地だけ日本語のまま取り残されていた。
///    英語側は訳ではなく、その言語で自然な名前・趣味・口癖にしてある。
library;

/// CPU対戦の相手1人分のデータ。
///
/// 表示に使うときは必ず `name(ja)` のように言語を渡すこと。
class CpuPersona {
  final String nameJa;
  final String nameEn;
  final String emoji;
  final String hobbyJa; // 趣味（おぼえタイムで表示）
  final String hobbyEn;
  final List<String> quipsJa; // 対戦中の口癖（ランダムで喋る）
  final List<String> quipsEn;
  final String winLineJa; // 勝ったときのセリフ
  final String winLineEn;
  final String loseLineJa;
  final String loseLineEn;

  const CpuPersona({
    required this.nameJa,
    required this.nameEn,
    required this.emoji,
    required this.hobbyJa,
    required this.hobbyEn,
    required this.quipsJa,
    required this.quipsEn,
    required this.winLineJa,
    required this.winLineEn,
    required this.loseLineJa,
    required this.loseLineEn,
  });

  String name(bool ja) => ja ? nameJa : nameEn;
  String hobby(bool ja) => ja ? hobbyJa : hobbyEn;
  List<String> quips(bool ja) => ja ? quipsJa : quipsEn;
  String winLine(bool ja) => ja ? winLineJa : winLineEn;
  String loseLine(bool ja) => ja ? loseLineJa : loseLineEn;
}

/// むずかしさごとの対戦相手。
const Map<String, List<CpuPersona>> kCpuPersonas = {
  'easy': [
    CpuPersona(
      nameJa: '柴田 もも',
      nameEn: 'Momo',
      emoji: '🐶',
      hobbyJa: '犬の散歩・お菓子作り',
      hobbyEn: 'Walking dogs & baking',
      quipsJa: ['えっと〜…', 'こっちかな？', 'わんちゃんかわいい〜', 'あ、まちがえた！'],
      quipsEn: ['Ummm...', 'Maybe this one?', 'Look at that puppy!', 'Oops, wrong one!'],
      winLineJa: 'やった！ももちゃんの勝ちだワン♪',
      winLineEn: 'Yay! Momo wins this one!',
      loseLineJa: 'くやしい〜！次は負けないワン！',
      loseLineEn: 'Aww! I want a rematch!',
    ),
    CpuPersona(
      nameJa: '野中 ゆず',
      nameEn: 'Yuzu',
      emoji: '🍊',
      hobbyJa: 'カラオケ・TikTok',
      hobbyEn: 'Karaoke & TikTok',
      quipsJa: ['ラララ〜♪', 'どこだっけ？', 'こっちは…ないなー', 'いまの見えた！'],
      quipsEn: ['La la la~', 'Where was it again?', 'Nope, not here...', 'I saw that one!'],
      winLineJa: '勝っちゃった！ゆずの完璧な記憶力を見たか！',
      winLineEn: 'I won! Did you see that memory of mine?',
      loseLineJa: 'えー負けたの！？TikTokにアップしよ…',
      loseLineEn: 'Wait, I lost? Fine, that goes on TikTok...',
    ),
  ],
  'normal': [
    CpuPersona(
      nameJa: '杉本 健太',
      nameEn: 'Kenta',
      emoji: '⚽',
      hobbyJa: 'フットサル・将棋',
      hobbyEn: 'Five-a-side football & chess',
      quipsJa: ['ふむ…', 'ここだな', '冷静にいこう', '読みが外れたか'],
      quipsEn: ['Hmm...', 'It is this one.', 'Stay calm.', 'Read that one wrong.'],
      winLineJa: 'よし。盤面は読めてた。いい勝負だった。',
      winLineEn: 'Good game. I had the board read.',
      loseLineJa: '参りました。次は先手でいかせてもらう。',
      loseLineEn: 'You got me. I am going first next time.',
    ),
    CpuPersona(
      nameJa: '山下 まどか',
      nameEn: 'Madoka',
      emoji: '📸',
      hobbyJa: '写真・カフェ巡り',
      hobbyEn: 'Photography & cafe hopping',
      quipsJa: ['ここは…さっき見た！', 'いい感じ〜', 'ちょっと悩むなあ', 'あっ'],
      quipsEn: ['I have seen that one!', 'Looking good~', 'Tricky one...', 'Ah!'],
      winLineJa: '勝ちました！カフェ奢ってくださいね♪',
      winLineEn: 'I win! You are buying the coffee.',
      loseLineJa: 'うそー、覚えたはずなのに…もう一回！',
      loseLineEn: 'No way, I had them memorised! One more!',
    ),
  ],
  'hard': [
    CpuPersona(
      nameJa: '加藤 りょう',
      nameEn: 'Ryo',
      emoji: '🧠',
      hobbyJa: '競技かるた・記憶術',
      hobbyEn: 'Competitive card matching & mnemonics',
      quipsJa: ['…読めた', 'そこだ', '凡ミスはしない', '記憶は嘘をつかない'],
      quipsEn: ['...I see it.', 'Right there.', 'I do not make careless errors.',
        'Memory does not lie.'],
      winLineJa: 'ふっ。記憶術を舐めてもらっては困る。',
      winLineEn: 'Never underestimate a trained memory.',
      loseLineJa: '一本取られた。いい記憶力だ、勉強になる。',
      loseLineEn: 'You got me. That was genuinely impressive.',
    ),
  ],
  'oni': [
    CpuPersona(
      nameJa: '黒崎 記憶院',
      nameEn: 'The Archivist',
      emoji: '👹',
      hobbyJa: '暗記・読書・座禅',
      hobbyEn: 'Memorisation, reading, meditation',
      quipsJa: ['全て覚えた', '逃さない', 'この盤面は終わっている', '…甘い'],
      quipsEn: ['All of it is remembered.', 'Nothing escapes.',
        'This board is already decided.', '...Too soft.'],
      winLineJa: '凡人の記憶力では私に届かぬ。精進せよ。',
      winLineEn: 'An ordinary memory cannot reach me. Train harder.',
      loseLineJa: 'バカな…全て覚えたはず…。お前、名を名乗れ。',
      loseLineEn: 'Impossible... I had them all. State your name.',
    ),
  ],
  'god': [
    CpuPersona(
      nameJa: '量子記憶体',
      nameEn: 'Quantum Recall',
      emoji: '⚡',
      hobbyJa: '情報の完全記憶・時間の超越',
      hobbyEn: 'Perfect recall, transcending time',
      quipsJa: ['…', '終わりだ', 'お前の思考は読めた', '次元が違う'],
      quipsEn: ['...', 'It ends here.', 'Your thinking is transparent to me.',
        'We are not on the same plane.'],
      winLineJa: 'この結末は量子論的に確定していた。お前の負けだ。',
      winLineEn: 'This outcome was fixed before you moved.',
      loseLineJa: '…………ありえない。私の予測を超えるとは。貴様、名を名乗れ。',
      loseLineEn: '......Impossible. You exceeded my prediction. State your name.',
    ),
    CpuPersona(
      nameJa: 'ラプラスの魔',
      nameEn: "Laplace's Demon",
      emoji: '👁️',
      hobbyJa: '全知全能・未来予測',
      hobbyEn: 'Omniscience, predicting the future',
      quipsJa: ['見えている', '無駄だ', 'すべて計算通り', '…フッ'],
      quipsEn: ['I can see it.', 'Futile.', 'All according to calculation.', '...Heh.'],
      winLineJa: '過去から未来まで、お前の一手一手は私に見えていた。',
      winLineEn: 'Every move you made was visible to me from the start.',
      loseLineJa: '…私の計算に、不確定性が。お前は、誰だ。',
      loseLineEn: '...Uncertainty, in my calculation. Who are you?',
    ),
  ],
  'ultimate': [
    CpuPersona(
      nameJa: '全記憶融合体',
      nameEn: 'The Whole Memory',
      emoji: '🌌',
      hobbyJa: '51次元の記憶・時間の超越・宇宙の完全理解',
      hobbyEn: 'Memory in 51 dimensions, all of it, all at once',
      quipsJa: ['…すべて覚えた', '終焉', 'お前のすべては私の中にある', '次元が違う'],
      quipsEn: ['...All of it is held.', 'The end.',
        'Everything you are is inside me.', 'A different order entirely.'],
      winLineJa: '51人——すべての記憶が私のうちにある。お前も、その一人だ。',
      winLineEn: 'Fifty-one of them. Every memory is mine. You are one of them now.',
      loseLineJa: '…………不可能。51人分の名前を……人間が……。貴様は、誰だ。',
      loseLineEn: '......Impossible. Fifty-one names. A human. Who are you?',
    ),
  ],
};

/// 難易度に合ったランダムな対戦相手を選ぶ。
CpuPersona pickCpuPersona(String levelKey) {
  final list = kCpuPersonas[levelKey] ?? kCpuPersonas['easy']!;
  return list[DateTime.now().millisecond % list.length];
}

/// CPUの口癖からランダムに1つ選ぶ。
String randomCpuQuip(CpuPersona cpu, {int? seed, bool ja = true}) {
  final list = cpu.quips(ja);
  final idx = (seed ?? DateTime.now().millisecond) % list.length;
  return list[idx];
}
