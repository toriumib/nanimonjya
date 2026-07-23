import 'package:flutter/widgets.dart';

/// 「名前の覚え方」記憶術の読み物コンテンツ。
/// 一般的な記憶術の考え方（タグ付け・映像化・場所法・記憶の3段階）を
/// ペタネームの遊びと絡めたオリジナル文章で紹介する。
/// 効果を断定する表現は使わない（「〜と言われている」等のヘッジ表現に統一）。
class MemoryTipPage {
  final String emoji; // ページの挿絵（絵文字）
  final String titleJa;
  final String titleEn;
  final String bodyJa;
  final String bodyEn;
  final List<Color> gradient;

  const MemoryTipPage({
    required this.emoji,
    required this.titleJa,
    required this.titleEn,
    required this.bodyJa,
    required this.bodyEn,
    required this.gradient,
  });

  String title(bool ja) => ja ? titleJa : titleEn;
  String body(bool ja) => ja ? bodyJa : bodyEn;
}

const List<MemoryTipPage> kMemoryTipPages = [
  MemoryTipPage(
    emoji: '🧠',
    titleJa: 'なんで名前って覚えにくいの？',
    titleEn: 'Why are names so hard?',
    bodyJa: '記憶は「記銘（覚える）→保持（キープ）→想起（思い出す）」の3ステップ。'
        '名前は顔とちがって“意味のない音の並び”になりがちで、思い出す手がかりが少ないから、'
        '最後の「想起」でつまずきやすいと言われています。\n\n'
        '逆に言えば——手がかりを自分で作ってあげれば、ぐっと思い出しやすくなる。'
        'それが記憶術の考え方です。しかも「おもしろい！」と感情が動いたことは'
        '記憶に残りやすいとされています（脳では扁桃体の働きが海馬の記憶づくりを'
        '後押しすると考えられています）。楽しく覚えるのは、理にかなっているんです。',
    bodyEn: 'Memory works in three steps: encode, store, recall. '
        'Names are just sounds with little meaning, so they give you few cues '
        'and recall is where most of us stumble.\n\n'
        'The trick: build your own cues. That is the whole idea of mnemonics. '
        'And things that make you feel something are said to stick better '
        '(the amygdala is thought to boost the hippocampus). '
        'Having fun while memorizing actually makes sense.',
    gradient: [Color(0xFFE8E3FF), Color(0xFFD8F0FF)],
  ),
  MemoryTipPage(
    emoji: '🏷️',
    titleJa: 'タグ付け法①：第一印象を一言タグに',
    titleEn: 'Tagging ①: First impression → one-word tag',
    bodyJa: '出会った瞬間の第一印象を、一言の「タグ」にします。\n'
        '「歯が白い」「まゆげが太い」「声が高い」——見たまま、感じたままでOK。\n\n'
        'かっこいい表現よりも、思わず笑っちゃうくらい率直なタグのほうが残りやすい。'
        'そしてタグは1つより2つ、3つ。どれか1つからでも思い出せるので、'
        '再現率が上がると言われています。\n\n'
        '🏷️ ペタネームのおぼえタイムで顔の特徴をつかむのが、まさにこの練習！',
    bodyEn: 'Turn your first impression into a one-word tag: '
        '"white teeth", "thick eyebrows", "high voice" — whatever you honestly notice.\n\n'
        'Blunt, funny tags beat polite ones. And two or three tags beat one: '
        'any single tag can lead you back to the name.\n\n'
        '🏷️ Spotting features during the PetaName memorize phase is exactly this practice!',
    gradient: [Color(0xFFFFE3EE), Color(0xFFFFF6D8)],
  ),
  MemoryTipPage(
    emoji: '🔗',
    titleJa: 'タグ付け法②：連想ストーリーで名前とつなぐ',
    titleEn: 'Tagging ②: Link tag and name with a story',
    bodyJa: 'タグと名前を「連想のしりとり」でつなぎます。\n\n'
        '例：歯が白い → 虫歯ゼロ → 砂糖をひかえてる → 佐藤さん！\n\n'
        '再会したら、タグ（歯が白い）から連想をたどって名前にゴール。\n'
        'コツは連想2〜3段、長くても5段以内。長すぎると連想自体を忘れちゃう。\n\n'
        '作るときは名前側から逆算すると簡単です。'
        '「佐藤→砂糖→甘い→虫歯→歯が白い」と逆向きに考えてから、正方向に使う。'
        'ペタネームのペア当てでも、顔の特徴→名前の連想を作っておくと思い出しやすいよ。',
    bodyEn: 'Chain the tag to the name with associations.\n\n'
        'Example: white teeth → zero cavities → avoids sugar → Sato '
        '(sounds like "sato" = sugar in Japanese)!\n\n'
        'Keep chains 2–3 links, 5 at most — longer chains get forgotten themselves. '
        'Building backwards from the name is easier: name → ... → tag, '
        'then replay it forwards. Matching faces to names in PetaName works the same way.',
    gradient: [Color(0xFFD8F0FF), Color(0xFFE8FFF7)],
  ),
  MemoryTipPage(
    emoji: '🎬',
    titleJa: '名前を映像に変える',
    titleEn: 'Turn names into pictures',
    bodyJa: '名前そのものを「絵」に変えるやり方もあります。\n\n'
        '田中さん→田んぼのど真ん中に立っている姿。\n'
        '松本さん→松の木の下に本が積んである風景。\n\n'
        '顔とその映像をセットで思い浮かべておくと、'
        '顔を見た瞬間に映像→名前がよみがえりやすくなると言われています。\n\n'
        '趣味や家族構成もイメージ化しておくと、名前から芋づる式に'
        '会話の話題まで引き出せて一石二鳥。',
    bodyEn: 'You can also turn the name itself into an image.\n\n'
        'Tanaka ("middle of the rice field") → picture them standing in a rice paddy. '
        'Matsumoto ("pine + book") → books stacked under a pine tree.\n\n'
        'Pair the face with that image, and seeing the face is said to '
        'bring the image — and the name — right back. '
        'Visualize their hobbies and family too, and small talk comes along for free.',
    gradient: [Color(0xFFFFF6D8), Color(0xFFD8F6F0)],
  ),
  MemoryTipPage(
    emoji: '🏠',
    titleJa: '場所法（メモリーパレス）',
    titleEn: 'The Memory Palace',
    bodyJa: '記憶力競技の選手たちも使うと言われる、古典的で強力な方法。\n\n'
        '自宅など、目をつぶっても歩けるくらいなじみの場所に'
        '「玄関→廊下→キッチン→リビング」のような順路を決めます。'
        '覚えたいものを、順路の各地点にひとつずつ「置いていく」イメージを作る。\n\n'
        '思い出すときは、頭の中で順路を歩き直すだけ。'
        '覚える対象がたくさんあるときに特に力を発揮するとされています。\n\n'
        '大人数の飲み会で全員の名前を覚えるときにも使えるかも…！？',
    bodyEn: 'A classic technique said to be used by memory athletes.\n\n'
        'Pick a place you know by heart — your home — and fix a route: '
        'entrance → hallway → kitchen → living room. '
        'Mentally "place" each thing you want to remember at a stop along the route.\n\n'
        'To recall, just walk the route again in your head. '
        'It is said to shine when the list gets long — like a party full of new names.',
    gradient: [Color(0xFFE8FFF7), Color(0xFFE8E3FF)],
  ),
  MemoryTipPage(
    emoji: '🗣️',
    titleJa: '仕上げは「呼んで、となえる」',
    titleEn: 'Finish by saying it out loud',
    bodyJa: '覚えたら、使う。それがいちばんの復習です。\n\n'
        '会話の中で「◯◯さんはどう思います？」と名前を呼ぶ。'
        '相手の話を聞きながら、心の中で名前をとなえる。'
        'それだけで自然な反復になって、記憶が定着しやすくなると言われています。\n\n'
        '🏷️ 実は、ペタネームの遊びかたそのものが'
        '「タグを付ける→名前を覚える→ペアで思い出す」という記憶術の流れ。'
        '一人特訓の「記憶術トレーニング」で、ガイド付きで練習してみよう！\n\n'
        '※覚えやすさには個人差があります。自分に合うやり方を見つけてね。',
    bodyEn: 'Once you learn a name, use it. '
        'Call people by name in conversation, and silently repeat it while they talk — '
        'natural repetition that is said to help names stick.\n\n'
        '🏷️ PetaName itself follows the mnemonic loop: '
        'tag the look → memorize the name → recall the pair. '
        'Try the guided Mnemonic Training in solo mode!\n\n'
        '※ Everyone memorizes differently — find what works for you.',
    gradient: [Color(0xFFFFE3EE), Color(0xFFD8F0FF)],
  ),
  MemoryTipPage(
    emoji: '🔬',
    titleJa: '研究が言う名前のコツ①：思い出す練習が最強',
    titleEn: 'What research says ①: retrieval wins',
    bodyJa: '「見て覚える」より「思い出す」ほうが記憶に残る——これは記憶研究でくり返し確かめられてきた'
        '“テスト効果”です。覚えたい名前は、読み返すのではなく、あえて思い出してみるのがコツ。\n\n'
        'さらに、思い出す間隔を「直後→数分後→あとでもう一度」と少しずつ延ばすと、より長く覚えていられると'
        '報告されています（時間をあけた復習＝分散学習）。\n\n'
        '🧠 ペタネームの「思い出しトレーニング」は、出会って→時間をおいて→思い出す、というこの流れそのもの。\n\n'
        '🔬 出典: Roediger & Karpicke (2006), Psychological Science ／ '
        'Morris, Fritz ほか (2005), Applied Cognitive Psychology ／ '
        'Cepeda ほか (2006), Psychological Bulletin',
    bodyEn: 'Recalling something beats rereading it — the well-replicated “testing effect”. '
        'For a name you want to keep, try to retrieve it instead of just reviewing it.\n\n'
        'Spacing your recalls at growing gaps (right away → minutes later → again later) is reported to '
        'help names last even longer (spaced practice).\n\n'
        '🧠 PetaName’s Recall Training is exactly this loop: meet → let time pass → recall.\n\n'
        '🔬 Sources: Roediger & Karpicke (2006), Psychological Science; '
        'Morris, Fritz et al. (2005), Applied Cognitive Psychology; '
        'Cepeda et al. (2006), Psychological Bulletin',
    gradient: [Color(0xFFE3F0FF), Color(0xFFEFE8FF)],
  ),
  MemoryTipPage(
    emoji: '🔬',
    titleJa: '研究が言う名前のコツ②：声に出す・意味づけ・自分ごと',
    titleEn: 'What research says ②: say it, mean it, own it',
    bodyJa: '名前は「声に出す」と記憶に残りやすいとされます（黙読より発話が有利＝プロダクション効果）。\n\n'
        'また、字面だけでなく“どんな人か”と意味づけしたり、自分の知り合いや自分との共通点に結びつけると、'
        '思い出す手がかりが増えます。顔の特徴と名前を1枚の絵にする映像化も定番のコツ。\n\n'
        '💡 「ベイカーさん(名字)」より「パン屋さん(職業)」のほうが思い出しやすい——名前は意味の網に'
        'からめるほど強くなります。\n\n'
        '🔬 出典: MacLeod ほか (2010), J. Exp. Psychol.: LMC ／ '
        'Craik & Tulving (1975), J. Exp. Psychol.: General ／ '
        'Rogers, Kuiper & Kirker (1977), J. Personality & Social Psychology ／ '
        'Morris, Jones & Hampson (1978), British Journal of Psychology ／ '
        'McWeeny ほか (1987), British Journal of Psychology ／ '
        'DeGutis ほか (2024), Quarterly Journal of Experimental Psychology',
    bodyEn: 'Names are remembered better when said aloud (the “production effect”). '
        'Adding meaning — what the person is like — and tying the name to someone you know or to yourself '
        'gives you more cues. Fusing a facial feature and the name into one image helps too.\n\n'
        '💡 “Baker” the job is easier to recall than “Baker” the surname — names grow stronger when woven '
        'into meaning.\n\n'
        '🔬 Sources: MacLeod et al. (2010), J. Exp. Psychol.: LMC; '
        'Craik & Tulving (1975), J. Exp. Psychol.: General; '
        'Rogers, Kuiper & Kirker (1977), J. Personality & Social Psychology; '
        'Morris, Jones & Hampson (1978), British Journal of Psychology; '
        'McWeeny et al. (1987), British Journal of Psychology; '
        'DeGutis et al. (2024), Quarterly Journal of Experimental Psychology',
    gradient: [Color(0xFFFFF3D6), Color(0xFFE8FFF0)],
  ),
];

/// 待合室・人数選択画面などに出す一言Tips（タップで読み物全文へ）。
class MemoryShortTip {
  final String ja;
  final String en;
  final String? source; // 出典（研究の著者・年・誌名）。研究ベースのTipsに付く
  const MemoryShortTip(this.ja, this.en, {this.source});

  String text(bool isJa) => isJa ? ja : en;
}

const List<MemoryShortTip> kMemoryShortTips = [
  MemoryShortTip(
    '👀 出会って3秒の第一印象を「歯が白い」みたいな一言タグにしてみよう',
    '👀 Turn your 3-second first impression into a one-word tag like "white teeth"',
  ),
  MemoryShortTip(
    '🔗 タグと名前は連想でつなぐ：歯が白い→虫歯ゼロ→砂糖→佐藤さん！',
    '🔗 Chain tag to name: white teeth → no cavities → avoids sugar → Sato!',
  ),
  MemoryShortTip(
    '🏷️ タグは2〜3個つけると、どれか1つからでも名前にたどりつけるよ',
    '🏷️ Give 2–3 tags — any one of them can lead you back to the name',
  ),
  MemoryShortTip(
    '🎬 名前は映像に：田中さん→田んぼの真ん中に立っている姿をイメージ',
    '🎬 Picture the name: Tanaka → standing in the middle of a rice field',
  ),
  MemoryShortTip(
    '🏠 場所法：家の玄関→廊下→リビングに、覚えたいものを置いていくイメージ',
    '🏠 Memory palace: place each item along a route through your home',
  ),
  MemoryShortTip(
    '🗣️ 会話の中で相手の名前を呼ぶと、それだけで自然な復習になるよ',
    '🗣️ Saying someone\'s name in conversation is natural rehearsal',
  ),
  MemoryShortTip(
    '💓 「おもしろい！」と感じながら覚えたことは残りやすいと言われているよ',
    '💓 Fun and curiosity are said to make memories stick better',
  ),
];

/// 🔬 研究にもとづく「名前の覚え方」Tips（出典つき）。
/// とっくん中や読み物、ワンポイント表示に使う。
/// 断定は避け、原著の知見を要約したオリジナル文にしている。
const List<MemoryShortTip> kNameScienceTips = [
  MemoryShortTip(
    '🔁 見て覚えるより「思い出す」練習が効く。会ったあとに名前を思い出してみよう',
    '🔁 Recalling beats rereading — after meeting someone, quiz yourself on their name',
    source: 'Roediger & Karpicke (2006), Psychological Science',
  ),
  MemoryShortTip(
    '⏱️ 思い出す間隔を少しずつ延ばすと定着しやすい：直後→数分後→あとでもう一度',
    '⏱️ Space your recalls at growing gaps: right away → minutes later → again later',
    source: 'Morris, Fritz, Jackson, Nichol & Roberts (2005), Applied Cognitive Psychology',
  ),
  MemoryShortTip(
    '🗣️ 名前は声に出すと残りやすい。黙読よりも「発話」した言葉のほうが思い出しやすい',
    '🗣️ Say the name aloud — spoken words are recalled better than ones read silently',
    source: 'MacLeod, Gopie, Hourihan, Neary & Ozubko (2010), J. Exp. Psychol.: LMC',
  ),
  MemoryShortTip(
    '🧩 名前に意味づけを。字面より「どんな人か」と結びつけるほど思い出しやすい',
    '🧩 Give the name meaning — the deeper you link it to the person, the better recall',
    source: 'Craik & Tulving (1975), J. Exp. Psychol.: General',
  ),
  MemoryShortTip(
    '💡 同じ「ベイカー」でも“パン屋(職業)”は覚えやすく“名字”は忘れやすい。名前も意味の網にからめよう',
    '💡 “Baker” the job sticks better than “Baker” the surname — weave names into meaning',
    source: 'McWeeny, Young, Hay & Ellis (1987), British Journal of Psychology',
  ),
  MemoryShortTip(
    '🪞 自分ごとにすると覚えやすい：同じ名前の知人や、自分との共通点を探そう',
    '🪞 Relate it to yourself — a namesake you know or a shared trait makes it stick',
    source: 'Rogers, Kuiper & Kirker (1977), J. Personality & Social Psychology',
  ),
  MemoryShortTip(
    '🎨 顔の特徴と名前を1枚の絵に：森さん＝額に小さな森、のように映像化しよう',
    '🎨 Fuse a facial feature and the name into one image — “Mori” = a tiny forest on the brow',
    source: 'Morris, Jones & Hampson (1978), British Journal of Psychology',
  ),
  MemoryShortTip(
    '🧠 名前を思い出す練習は、顔を覚える力の高さとも結びつくと報告されている',
    '🧠 Practising name recall is linked to stronger face-recognition ability, recent work reports',
    source: 'DeGutis, Palsamudram, Campbell, Fry, Verfaellie & Anderson (2024), Quarterly Journal of Experimental Psychology',
  ),
];
