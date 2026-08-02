/// 📖 ストーリーモードの台本。
///
/// 名前を覚えられないナナが、ハナと一緒に働きながら
/// 「なぜ人の名前は覚えられないのか」を確かめていく話。
/// 最後は全員の名前を覚えて、みんなで宴をして終わる。
///
/// ⚠️ 記憶や脳の話は**断定しない**。研究で言われていることは
/// 「〜とされる」の形で書き、出典を [StoryScene.source] に添える。
/// （`meta_strings.dart` の cognitiveDisclaimer と同じ方針）
library;

/// 話し手。立ち絵と名前の色を切り替えるのに使う。
enum Speaker {
  /// 主人公。人の名前がどうしても覚えられない新人。
  nana,

  /// 同期。記憶のしくみに詳しく、ナナを引っぱる。
  hana,

  /// その他の登場人物（先輩・取引先など）。名前は [StoryScene.who] で出す。
  other,

  /// 地の文（話し手なし）。
  narration,
}

/// 1画面ぶんのセリフ。
class StoryScene {
  final Speaker speaker;

  /// [Speaker.other] のときの表示名。
  final String who;

  final String text;

  /// 研究の出典（あれば小さく添える）。
  final String? source;

  const StoryScene(
    this.speaker,
    this.text, {
    this.who = '',
    this.source,
  });
}

/// 1話ぶん。
class StoryChapter {
  final int number;
  final String title;

  /// 話の締めに出す一言（次への引き）。
  final String outro;

  final List<StoryScene> scenes;

  /// 読み終えたときのごほうび（コイン）。
  final int reward;

  const StoryChapter({
    required this.number,
    required this.title,
    required this.scenes,
    required this.outro,
    this.reward = 30,
  });

  String get id => 'ch$number';
}

/// 全話。少しずつ足していく。
const List<StoryChapter> kStoryChapters = [
  StoryChapter(
    number: 1,
    title: '名前が、出てこない',
    reward: 30,
    outro: '——名前を覚えるのに、コツなんてあるんだろうか。',
    scenes: [
      StoryScene(Speaker.narration, '入社式の朝。'),
      StoryScene(Speaker.narration,
          'ナナは、二十七人ぶんの自己紹介を聞いた。'),
      StoryScene(Speaker.nana, 'よし……覚えた。たぶん。'),
      StoryScene(Speaker.narration, '——三十分後。'),
      StoryScene(Speaker.other, 'ナナさん、これお願いできる？', who: '先輩'),
      StoryScene(Speaker.nana, 'は、はい！ ……あの、えっと、'),
      StoryScene(Speaker.nana, '（名前……名前が出てこない！）'),
      StoryScene(Speaker.nana, 'あ、ありがとうございます、せ、先輩！'),
      StoryScene(Speaker.narration, '先輩は笑って行ってしまった。'),
      StoryScene(Speaker.nana, 'また「先輩」で逃げた……。'),
      StoryScene(Speaker.hana, 'いまの、田島さんだよ。'),
      StoryScene(Speaker.nana, 'えっ、ハナちゃん、なんで覚えてるの！？'),
      StoryScene(Speaker.hana, 'わたしも得意じゃないよ。ただ——'),
      StoryScene(Speaker.hana, '聞いたとき、一回だけ口に出したの。'),
      StoryScene(Speaker.hana, '「田島さん、よろしくお願いします」って。'),
      StoryScene(Speaker.nana, 'それだけ？'),
      StoryScene(Speaker.hana,
          '声に出したり、書いたりして覚えたものは、'
          'ただ聞いただけより残りやすいとされているらしくて。'),
      StoryScene(Speaker.hana, 'なんて言うんだっけ……生成効果、だったかな。',
          source: 'MacLeod ら（2010）による産出効果の研究'),
      StoryScene(Speaker.nana, '……ちょっと、ずるい。'),
      StoryScene(Speaker.hana, 'ずるくないよ。やってみる？'),
      StoryScene(Speaker.hana, '明日、朝いちで会う人。'),
      StoryScene(Speaker.hana, '名前を聞いたら、その場で一回、声に出す。'),
      StoryScene(Speaker.nana, '……うん。やってみる。'),
      StoryScene(Speaker.narration,
          'ナナは手帳のいちばん前のページに、こう書いた。'),
      StoryScene(Speaker.narration, '『聞いたら、呼ぶ』'),
    ],
  ),
];

StoryChapter? storyChapterByNumber(int n) {
  for (final c in kStoryChapters) {
    if (c.number == n) return c;
  }
  return null;
}

/// 公開している話の数。
int get kStoryChapterCount => kStoryChapters.length;
