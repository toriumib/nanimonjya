/// 🤖 CPU対戦の相手——名前と顔と個性を持ったキャラクター。
///
/// ペアさがしのCPU対戦が「ただの神経衰弱」にならないように、
/// 相手に名前と趣味と口癖を持たせる。
/// 対戦中に喋り、勝敗リアクションも変える。
library;

/// CPU対戦の相手1人分のデータ。
class CpuPersona {
  final String name;
  final String emoji;
  final String hobby; // 趣味（おぼえタイムで表示）
  final List<String> quips; // 対戦中の口癖（ランダムで喋る）
  final String winLine; // 勝ったときのセリフ
  final String loseLine; // 負けたときのセリフ

  const CpuPersona({
    required this.name,
    required this.emoji,
    required this.hobby,
    required this.quips,
    required this.winLine,
    required this.loseLine,
  });
}

/// むずかしさごとの対戦相手。
const Map<String, List<CpuPersona>> kCpuPersonas = {
  'easy': [
    CpuPersona(
      name: '柴田 もも',
      emoji: '🐶',
      hobby: '犬の散歩・お菓子作り',
      quips: ['えっと〜…', 'こっちかな？', 'わんちゃんかわいい〜', 'あ、まちがえた！'],
      winLine: 'やった！ももちゃんの勝ちだワン♪',
      loseLine: 'くやしい〜！次は負けないワン！',
    ),
    CpuPersona(
      name: '野中 ゆず',
      emoji: '🍊',
      hobby: 'カラオケ・TikTok',
      quips: ['ラララ〜♪', 'どこだっけ？', 'こっちは…ないなー', 'いまの見えた！'],
      winLine: '勝っちゃった！ゆずの完璧な記憶力を見たか！',
      loseLine: 'えー負けたの！？TikTokにアップしよ…',
    ),
  ],
  'normal': [
    CpuPersona(
      name: '杉本 健太',
      emoji: '⚽',
      hobby: 'フットサル・将棋',
      quips: ['ふむ…', 'ここだな', '冷静にいこう', '読みが外れたか'],
      winLine: 'よし。盤面は読めてた。いい勝負だった。',
      loseLine: '参りました。次は先手でいかせてもらう。',
    ),
    CpuPersona(
      name: '山下 まどか',
      emoji: '📸',
      hobby: '写真・カフェ巡り',
      quips: ['ここは…さっき見た！', 'いい感じ〜', 'ちょっと悩むなあ', 'あっ'],
      winLine: '勝ちました！カフェ奢ってくださいね♪',
      loseLine: 'うそー、覚えたはずなのに…もう一回！',
    ),
  ],
  'hard': [
    CpuPersona(
      name: '加藤 りょう',
      emoji: '🧠',
      hobby: '競技かるた・記憶術',
      quips: ['…読めた', 'そこだ', '凡ミスはしない', '記憶は嘘をつかない'],
      winLine: 'ふっ。記憶術を舐めてもらっては困る。',
      loseLine: '一本取られた。いい記憶力だ、勉強になる。',
    ),
  ],
  'oni': [
    CpuPersona(
      name: '黒崎 記憶院',
      emoji: '👹',
      hobby: '暗記・読書・座禅',
      quips: ['全て覚えた', '逃さない', 'この盤面は終わっている', '…甘い'],
      winLine: '凡人の記憶力では私に届かぬ。精進せよ。',
      loseLine: 'バカな…全て覚えたはず…。お前、名を名乗れ。',
    ),
  ],
  'god': [
    CpuPersona(
      name: '量子記憶体',
      emoji: '⚡',
      hobby: '情報の完全記憶・時間の超越',
      quips: ['…', '終わりだ', 'お前の思考は読めた', '次元が違う'],
      winLine: 'この結末は量子論的に確定していた。お前の負けだ。',
      loseLine: '…………ありえない。私の予測を超えるとは。貴様、名を名乗れ。',
    ),
    CpuPersona(
      name: 'ラプラスの魔',
      emoji: '👁️',
      hobby: '全知全能・未来予測',
      quips: ['見えている', '無駄だ', 'すべて計算通り', '…フッ'],
      winLine: '過去から未来まで、お前の一手一手は私に見えていた。',
      loseLine: '…私の計算に、不確定性が。お前は、誰だ。',
    ),
  ],
};

/// 難易度に合ったランダムな対戦相手を選ぶ。
CpuPersona pickCpuPersona(String levelKey) {
  final list = kCpuPersonas[levelKey] ?? kCpuPersonas['easy']!;
  return list[DateTime.now().millisecond % list.length];
}

/// CPUの口癖からランダムに1つ選ぶ。
String randomCpuQuip(CpuPersona cpu, {int? seed}) {
  final idx = (seed ?? DateTime.now().millisecond) % cpu.quips.length;
  return cpu.quips[idx];
}
