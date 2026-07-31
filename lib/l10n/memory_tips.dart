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
        '🏷️ ペアさがしのおぼえタイムで顔の特徴をつかむのが、まさにこの練習！',
    bodyEn: 'Turn your first impression into a one-word tag: '
        '"white teeth", "thick eyebrows", "high voice" — whatever you honestly notice.\n\n'
        'Blunt, funny tags beat polite ones. And two or three tags beat one: '
        'any single tag can lead you back to the name.\n\n'
        '🏷️ Spotting features during the Pair Hunt memorize phase is exactly this practice!',
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
        'ペアさがしでも、顔の特徴→名前の連想を作っておくと思い出しやすいよ。',
    bodyEn: 'Chain the tag to the name with associations.\n\n'
        'Example: white teeth → zero cavities → avoids sugar → Sato '
        '(sounds like "sato" = sugar in Japanese)!\n\n'
        'Keep chains 2–3 links, 5 at most — longer chains get forgotten themselves. '
        'Building backwards from the name is easier: name → ... → tag, '
        'then replay it forwards. Matching faces to names in Pair Hunt works the same way.',
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
        '🏷️ 実は、このアプリの遊びかたそのものが'
        '「タグを付ける→名前を覚える→ペアで思い出す」という記憶術の流れ。'
        '一人特訓の「記憶術トレーニング」で、ガイド付きで練習してみよう！\n\n'
        '※覚えやすさには個人差があります。自分に合うやり方を見つけてね。',
    bodyEn: 'Once you learn a name, use it. '
        'Call people by name in conversation, and silently repeat it while they talk — '
        'natural repetition that is said to help names stick.\n\n'
        '🏷️ This app itself follows the mnemonic loop: '
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
        '🧠 「名刺おぼえ」は、出会って→時間をおいて→思い出す、というこの流れそのもの。\n\n'
        '🔬 出典: Roediger & Karpicke (2006), Psychological Science ／ '
        'Morris, Fritz ほか (2005), Applied Cognitive Psychology ／ '
        'Cepeda ほか (2006), Psychological Bulletin',
    bodyEn: 'Recalling something beats rereading it — the well-replicated “testing effect”. '
        'For a name you want to keep, try to retrieve it instead of just reviewing it.\n\n'
        'Spacing your recalls at growing gaps (right away → minutes later → again later) is reported to '
        'help names last even longer (spaced practice).\n\n'
        '🧠 Card Memory is exactly this loop: meet → let time pass → recall.\n\n'
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
  MemoryTipPage(
    emoji: '😴',
    titleJa: '研究が言う名前のコツ③：覚えたら、眠る',
    titleEn: 'What research says ③: learn, then sleep',
    bodyJa: '「覚えた」で終わりではありません。記憶が本当に固まるのは、そのあと眠っているあいだ——'
        'つまり、あなたが何もしていない時間だと考えられています。\n\n'
        '眠った脳は、静かに休んでいるわけではありません。'
        '「ゆっくりした波（徐波）」「紡錘波（スピンドル）」「リプル」と呼ばれる3種類の活動が、'
        'まるでオーケストラのように順序とタイミングを合わせて現れます。'
        'この連携が、その日の経験の中から“残すべきもの”を選び出し、'
        '海馬から大脳皮質へ書き写していく——という仕組みが提案されています。\n\n'
        'つまり、あなたが今日出会った人の顔と名前は、'
        '今夜の睡眠中に「保存するかどうか」の選抜を受けているわけです。\n\n'
        '🛏️ 実践はシンプルです。\n'
        '・名前を覚えたら、その日はしっかり眠る\n'
        '・7〜9時間、毎日だいたい同じ時間に寝る\n'
        '・寝る直前のカフェイン・お酒・強い光は避ける（睡眠が分断され、定着に不利になりうる）\n\n'
        '💡 大事な商談の前夜は、詰め込むより早く寝たほうが効くかもしれません。\n\n'
        '🔬 出典\n'
        '・Staresina, B. P. (2024). Coupled sleep rhythms for memory consolidation. '
        'Trends in Cognitive Sciences, 28(4), 339–351. doi:10.1016/j.tics.2024.02.002\n'
        '・Baranwal, N., Yu, P. K., & Siegel, N. S. (2023). Sleep physiology, pathophysiology, '
        'and sleep hygiene. Progress in Cardiovascular Diseases, 77, 59–69. '
        'doi:10.1016/j.pcad.2023.02.005',
    bodyEn: 'Learning is not the finish line. Memories are thought to be consolidated afterwards, '
        'while you sleep — during the hours you are doing nothing at all.\n\n'
        'A sleeping brain is far from idle. Three kinds of activity — slow oscillations, spindles and '
        'ripples — appear in a finely ordered sequence, like an orchestra. This coupling is proposed to '
        'select which of the day’s experiences are worth keeping, and to copy them from hippocampus to cortex.\n\n'
        'So the face and name you met today are, tonight, going through selection for storage.\n\n'
        '🛏️ The practice is simple:\n'
        '・Sleep well on the day you learn names\n'
        '・7–9 hours, on a roughly consistent schedule\n'
        '・Avoid late caffeine, alcohol and bright light (they fragment sleep, which can hinder consolidation)\n\n'
        '💡 The night before an important meeting, an early bedtime may beat cramming.\n\n'
        '🔬 Sources\n'
        '・Staresina, B. P. (2024). Coupled sleep rhythms for memory consolidation. '
        'Trends in Cognitive Sciences, 28(4), 339–351. doi:10.1016/j.tics.2024.02.002\n'
        '・Baranwal, N., Yu, P. K., & Siegel, N. S. (2023). Sleep physiology, pathophysiology, '
        'and sleep hygiene. Progress in Cardiovascular Diseases, 77, 59–69. '
        'doi:10.1016/j.pcad.2023.02.005',
    gradient: [Color(0xFFE3E8FF), Color(0xFFF3E8FF)],
  ),
  MemoryTipPage(
    emoji: '🌌',
    titleJa: 'おまけ①：記憶は残るのに、意識は消える',
    titleEn: 'Bonus ①: memory stays, consciousness fades',
    bodyJa: 'ここからは名前の覚え方を少し離れた、おまけの読み物です。\n\n'
        '不思議な事実があります。深い眠りのあいだ、私たちの意識はほとんど消えています。'
        '呼びかけても気づかず、時間の流れも感じない。'
        'それなのに、まさにその時間に、記憶はもっとも強く固まっていく。\n\n'
        'つまり——**記憶を作る仕組みと、意識を生む仕組みは別**らしいのです。\n\n'
        '🌙 では、意識が消えるとき、脳では何が起きているのか。'
        '眠りに落ちると、脳の神経細胞は「一斉に活動し、一斉に静まる」という単調なリズムに'
        '引き込まれていきます（バイステビリティ）。'
        'すると、脳のある場所で起きたことが他の場所に伝わっても、'
        'それ以上の複雑な反応が続かず、すぐ消えてしまう。'
        '情報が脳の中で豊かに広がれなくなること——それが意識の消失と関係している、'
        'という見方が提案されています。\n\n'
        '面白いのは、同じ「眠り」の中でも夢を見ているときには意識が戻ることです。'
        '外界から切り離され、体は動かないまま、脳は内側から鮮やかな世界を立ち上げる。'
        '夢は「意識の材料は脳の中だけで足りる」ことを教えてくれます。\n\n'
        '💤 麻酔の研究も同じ問いに迫っています。'
        '麻酔薬は「眠らせる」のではなく、脳の広い範囲のつながりを変えて意識だけを取り去る。'
        '意識をスイッチのように消せる道具として、いま意識研究の主要な手段になっています。\n\n'
        '🔬 出典\n'
        '・Tononi, G., Boly, M., & Cirelli, C. (2024). Consciousness and sleep. '
        'Neuron, 112(10), 1568–1594. doi:10.1016/j.neuron.2024.04.011\n'
        '・Mashour, G. A. (2024). Anesthesia and the neurobiology of consciousness. '
        'Neuron, 112(10), 1553–1567. doi:10.1016/j.neuron.2024.03.002',
    bodyEn: 'A bonus read, a little away from remembering names.\n\n'
        'Here is a strange fact. During deep sleep, consciousness largely vanishes. '
        'Call your name and you will not notice; time does not pass for you. '
        'And yet it is exactly then that memories are consolidated most strongly.\n\n'
        'In other words — **the machinery that builds memory and the machinery that produces '
        'consciousness appear to be separable.**\n\n'
        '🌙 So what happens in the brain as consciousness fades? '
        'Falling asleep, neurons are drawn into a monotonous rhythm of firing and falling silent '
        'together (bistability). An event in one region may still reach another, but no rich, '
        'sustained response follows — it dies out. The loss of that complex spread of information '
        'is proposed to be tied to the loss of consciousness.\n\n'
        'What is fascinating is that within the same sleep, consciousness returns when we dream. '
        'Cut off from the world, body still, the brain raises a vivid world from the inside. '
        'Dreams show us that the ingredients of consciousness can be found entirely within the brain.\n\n'
        '💤 Anesthesia research chases the same question. Anesthetics do not simply induce sleep; '
        'they reshape large-scale brain connectivity and remove consciousness alone — which is why '
        'they have become a central tool for studying it.\n\n'
        '🔬 Sources\n'
        '・Tononi, G., Boly, M., & Cirelli, C. (2024). Consciousness and sleep. '
        'Neuron, 112(10), 1568–1594. doi:10.1016/j.neuron.2024.04.011\n'
        '・Mashour, G. A. (2024). Anesthesia and the neurobiology of consciousness. '
        'Neuron, 112(10), 1553–1567. doi:10.1016/j.neuron.2024.03.002',
    gradient: [Color(0xFFE8E3FF), Color(0xFFD8F0FF)],
  ),
  MemoryTipPage(
    emoji: '⚔️',
    titleJa: 'おまけ②：2つの意識理論が、正面から戦った',
    titleEn: 'Bonus ②: two theories of consciousness, put to a duel',
    bodyJa: '「脳の活動が、なぜ“感じ”を生むのか」。'
        'この問いは1990年代に**意識のハードプロブレム**と名づけられ、いまも未解決です。\n\n'
        '有力な理論が2つあります。\n\n'
        '🔵 **統合情報理論（IIT）**\n'
        '意識の正体は「情報の統合度」だとする理論。'
        'ばらばらの部品ではなく、全体として1つに結びついた情報の構造がある——'
        'そこに意識が宿る、と考えます。主張の中心は脳の後方（後頭・側頭）にあります。\n\n'
        '🟠 **グローバル・ニューロナル・ワークスペース理論（GNWT）**\n'
        '情報が脳の一部から全体へ「放送」されたときに意識になる、とする理論。'
        '前頭前野を含む広い範囲での“点火（ignition）”を重視します。\n\n'
        '⚔️ 2025年、この2つが正面からぶつかりました。'
        'それぞれの理論の提唱者たちが、中立の研究チームと一緒に'
        '**「どちらが外れたら負けか」を事前に登録してから実験する**という'
        '敵対的協働（adversarial collaboration）を実施したのです。'
        '256人の参加者を対象に、fMRI・MEG・頭蓋内脳波という3つの方法で同時に測定。'
        '結果はNature誌に報告されました。\n\n'
        '結末は、どちらの完全勝利でもありませんでした。'
        '両理論の予測は部分的に当たった一方で、'
        'IITが中心に置く「後方皮質での持続的な同期」は見つからず、'
        'GNWTが予測した「刺激が消えた瞬間の点火」も広くは観察されなかった。'
        'つまり**両方の核心部分に、それぞれ課題が示された**のです。\n\n'
        '🌌 意識は、まだ誰にも説明できていません。'
        'いま顔を見て名前を思い出したその一瞬にも、科学が説明しきれていない何かが働いています。'
        'そう思うと、「思い出せた！」の瞬間が少し特別に感じられるかもしれません。\n\n'
        '🔬 出典\n'
        '・Cogitate Consortium, Ferrante, O., et al. (2025). Adversarial testing of global neuronal '
        'workspace and integrated information theories of consciousness. Nature, 642(8066), 133–142. '
        'doi:10.1038/s41586-025-08888-1\n'
        '（著者にはIIT提唱者のG. Tononi、GNWT側のS. Dehaene、C. Koch、'
        'そして「ハードプロブレム」の名づけ親である哲学者D. J. Chalmersが名を連ねています）\n\n'
        '※一般向けの紹介であり、解釈は研究者間で議論が続いています。',
    bodyEn: 'Why does brain activity feel like anything at all? '
        'Named the **hard problem of consciousness** in the 1990s, it is still unsolved.\n\n'
        'Two leading theories:\n\n'
        '🔵 **Integrated Information Theory (IIT)**\n'
        'Consciousness is the integration of information — not separate parts, but a structure bound '
        'into one whole. Its claims centre on posterior (occipital, temporal) cortex.\n\n'
        '🟠 **Global Neuronal Workspace Theory (GNWT)**\n'
        'Information becomes conscious when it is “broadcast” brain-wide, with an ignition across '
        'wide areas including prefrontal cortex.\n\n'
        '⚔️ In 2025 the two met head-on. Proponents of each theory worked with a theory-neutral '
        'consortium in an **adversarial collaboration**: they preregistered which outcomes would '
        'count against them, then ran the experiment. 256 participants were measured with fMRI, MEG '
        'and intracranial EEG. The results appeared in Nature.\n\n'
        'Neither won outright. Some predictions of both held up, but IIT’s central claim of sustained '
        'synchronization within posterior cortex was not found, and GNWT’s predicted ignition at '
        'stimulus offset was largely absent. **Core tenets of both were challenged.**\n\n'
        '🌌 Nobody can explain consciousness yet. In the instant you just recalled a name, something '
        'science cannot fully account for was at work. That may make the “I remembered!” moment feel '
        'a little special.\n\n'
        '🔬 Sources\n'
        '・Cogitate Consortium, Ferrante, O., et al. (2025). Adversarial testing of global neuronal '
        'workspace and integrated information theories of consciousness. Nature, 642(8066), 133–142. '
        'doi:10.1038/s41586-025-08888-1\n'
        '(Authors include IIT’s G. Tononi, GNWT-side S. Dehaene and C. Koch, and philosopher '
        'D. J. Chalmers, who named the hard problem.)\n\n'
        '※ A general-audience summary; interpretation remains debated among researchers.',
    gradient: [Color(0xFFD8E8FF), Color(0xFFFFE8F0)],
  ),
  MemoryTipPage(
    emoji: '📅',
    titleJa: '研究が言う名前のコツ④：一気に詰めず、間をあけて思い出す',
    titleEn: 'Tip ④ from research: don’t cram — space out your recall',
    bodyJa: '同じ10分を使うなら、どう配るのがいいのでしょう。\n\n'
        '学習研究には、くり返し出てくる2つの言葉があります。\n\n'
        '📅 **分散学習（distributed practice）**\n'
        '同じ回数やるなら、まとめてやるより日をまたいで散らしたほうが、'
        '後まで残りやすいとされています。\n\n'
        '📝 **検索練習（retrieval practice）**\n'
        '読み返すのではなく、**思い出そうと頭をひねる**ほうが定着に効くとされる考え方。'
        '「テスト効果」とも呼ばれます。\n\n'
        '2023年に医療系の教育研究をまとめた系統的レビューでは、'
        '63の実験のうち43で、この2つが対照群より成績を上げたと報告されました。'
        'つまり「あとで思い出せるかどうか」に、配り方はかなり効くらしいのです。\n\n'
        '同じ年には、医学生に心電図の小テストを実習期間中くり返し出した研究もあります。'
        '間隔をあけて出題されたグループは、事後テストの平均点が'
        '対照グループより有意に高かったと報告されました。'
        '「一度覚えた」で終わらせず、間をあけてもう一度自分に問う。'
        'それだけで、忘却の傾きがゆるやかになったわけです。\n\n'
        '🎯 このアプリだと\n'
        '・**1日1セットを何日か**やるのが、1日に何セットもやるより理にかなっています\n'
        '・名刺おぼえの「時間をおく → 思い出す」の間は、わざと空けてあります\n'
        '・まちがえた人だけをもう1周する**復習ラウンド**は、検索練習そのものです\n\n'
        '🔬 出典（PubMedより）\n'
        '・Trumble, E., Lodge, J., Mandrusiak, A., & Forbes, R. (2023). Systematic review of '
        'distributed practice and retrieval practice in health professions education. '
        'Advances in Health Sciences Education, 29(2), 689–714. doi:10.1007/s10459-023-10274-3\n'
        '・Cunningham, J. M., et al. (2023). The spacing effect: Improving electrocardiogram '
        'interpretation. The Clinical Teacher, 21(1), e13626. doi:10.1111/tct.13626\n\n'
        '※対象は医療系学生の学習で、名前の記憶そのものを調べた研究ではありません。'
        '効果には個人差があります。',
    bodyEn: 'If you only have ten minutes, how should you spread them out?\n\n'
        'Two terms keep coming up in learning research.\n\n'
        '📅 **Distributed practice**\n'
        'For the same number of repetitions, spreading them across days is said to leave more '
        'behind than doing them all at once.\n\n'
        '📝 **Retrieval practice**\n'
        'Straining to *recall* something is said to beat re-reading it — often called the '
        'testing effect.\n\n'
        'A 2023 systematic review of health professions education found that in 43 of 63 '
        'experiments, these two beat control and comparison groups. How you distribute your '
        'effort really does seem to matter for what survives.\n\n'
        'The same year, medical students were given repeated ECG quizzes across their clerkship '
        'year. The spaced group scored significantly higher on the post-test than controls. '
        'Simply asking yourself again, later, flattened the forgetting curve.\n\n'
        '🎯 In this app\n'
        '・**One set a day over several days** makes more sense than many sets in one day\n'
        '・The gap in Card Memory between “time passes” and “recall” is deliberate\n'
        '・The **review round** for the ones you missed is retrieval practice itself\n\n'
        '🔬 Sources (via PubMed)\n'
        '・Trumble, E., Lodge, J., Mandrusiak, A., & Forbes, R. (2023). Systematic review of '
        'distributed practice and retrieval practice in health professions education. '
        'Advances in Health Sciences Education, 29(2), 689–714. doi:10.1007/s10459-023-10274-3\n'
        '・Cunningham, J. M., et al. (2023). The spacing effect: Improving electrocardiogram '
        'interpretation. The Clinical Teacher, 21(1), e13626. doi:10.1111/tct.13626\n\n'
        '※ Studied in health professions students, not name memory as such. '
        'Individual results vary.',
    gradient: [Color(0xFFE3F0FF), Color(0xFFEAFBF3)],
  ),
  MemoryTipPage(
    emoji: '🏃',
    titleJa: '研究が言う名前のコツ⑤：覚えたあと、少し動く',
    titleEn: 'Tip ⑤ from research: move a little afterwards',
    bodyJa: '覚えたあとの数十分は、記憶にとって“工事中”の時間だと考えられています。'
        'ここに何を置くかで、残り方が変わるかもしれません。\n\n'
        '🏃 2025年のラット研究では、こんな設計が使われました。'
        '5分だけ場所を覚えさせると、1時間は覚えていても24時間後には消えてしまう。'
        'ところが学習の**直後に20分の中強度の運動**をさせると、24時間後にも残ったのです。\n\n'
        'さらに面白いのは、その先です。'
        '海馬（記憶づくりの中枢）でタンパク質の新規合成を止める薬を入れると、'
        'この運動の効果は消えました。'
        'つまり運動は「気分の問題」ではなく、'
        '**記憶を固める作業（固定化）そのものに関わっている**と考えられるわけです。\n\n'
        '⚡ 2023年の別の研究は、その運動の効果が'
        '**青斑核（locus coeruleus）**——ノルアドレナリンを出す小さな神経核——'
        'の働きを必要としていた、と報告しています。'
        '「体を動かすと頭が冴える」の裏側に、こういう回路が想定されています。\n\n'
        '🎯 このアプリだと\n'
        '・名刺交換のあと、席に戻る前にひと歩き。それが偶然いい復習環境かもしれません\n'
        '・特訓のあとにスマホを置いて散歩、は理にかなった終わり方です\n'
        '・そして眠る（→「名前のコツ③」）。動いて、寝る。どちらも“工事”の味方です\n\n'
        '🔬 出典（PubMedより）\n'
        '・Inoue, K., Okamoto, M., Fukuie, T., Soya, H., & Yamaguchi, A. (2025). Memory '
        'persistence enhancement by post-learning moderate exercise requires de novo protein '
        'synthesis in the dorsal hippocampus. PLoS ONE, 20(7), e0328128. '
        'doi:10.1371/journal.pone.0328128\n'
        '・Lima, K. R., et al. (2023). Acute physical exercise improves recognition memory via '
        'locus coeruleus activation but not via ventral tegmental area activation. '
        'Physiology & Behavior, 272, 114370. doi:10.1016/j.physbeh.2023.114370\n\n'
        '※いずれもラットを対象とした研究です。'
        'ヒトにそのまま当てはまるとは限らず、運動量は体調に合わせてください。'
        'このアプリは医療機器ではなく、治療・予防の効果をうたうものではありません。',
    bodyEn: 'The half hour after learning is thought to be “under construction” for memory. '
        'What you put there may change what remains.\n\n'
        '🏃 A 2025 rat study used a neat design. Five minutes of learning a location survived an '
        'hour but was gone at 24 hours. Yet with **20 minutes of moderate exercise immediately '
        'after learning**, the memory was still there a day later.\n\n'
        'The interesting part comes next: a drug blocking new protein synthesis in the '
        'hippocampus abolished the exercise benefit. So exercise looks less like a mood boost and '
        'more like part of **consolidation itself**.\n\n'
        '⚡ A separate 2023 study reported that this exercise benefit required the '
        '**locus coeruleus** — a small noradrenaline-releasing nucleus. There is a circuit behind '
        '“moving your body clears your head.”\n\n'
        '🎯 In this app\n'
        '・A short walk after swapping cards may be an accidentally good rehearsal setting\n'
        '・Putting the phone down and walking after training is a sensible way to finish\n'
        '・Then sleep (see Tip ③). Move, then sleep — both help the construction work\n\n'
        '🔬 Sources (via PubMed)\n'
        '・Inoue, K., Okamoto, M., Fukuie, T., Soya, H., & Yamaguchi, A. (2025). Memory '
        'persistence enhancement by post-learning moderate exercise requires de novo protein '
        'synthesis in the dorsal hippocampus. PLoS ONE, 20(7), e0328128. '
        'doi:10.1371/journal.pone.0328128\n'
        '・Lima, K. R., et al. (2023). Acute physical exercise improves recognition memory via '
        'locus coeruleus activation but not via ventral tegmental area activation. '
        'Physiology & Behavior, 272, 114370. doi:10.1016/j.physbeh.2023.114370\n\n'
        '※ Both are rat studies; they may not transfer directly to humans, and you should match '
        'any exercise to your own condition. This app is not a medical device and makes no claim '
        'to treat or prevent anything.',
    gradient: [Color(0xFFFFF0E3), Color(0xFFE8F7EC)],
  ),
  MemoryTipPage(
    emoji: '⏳',
    titleJa: '名前のしくみ①：3秒しかもたない「置き場」',
    titleEn: 'How names work ①: the 3-second shelf',
    bodyJa: '「はじめまして、○○です」——この直後、その名前はまだ**短期記憶**という'
        'とても小さな置き場に乗っているだけです。\n\n'
        'この置き場には2つのきびしい制約があると言われています。\n\n'
        '📦 **せまい**\n'
        '同時に保てるのは、意味のあるかたまり（チャンク）でせいぜい4つ前後。'
        '名刺交換で3人めに入ったころ、1人めが押し出されるのはこのためです。\n\n'
        '⏳ **短い**\n'
        '声に出したり心の中でくり返したりしないと、十数秒で薄れていきます。'
        '「聞いた瞬間は覚えていたのに」が起きるのは、あなたの能力の問題ではなく仕様です。\n\n'
        '🎯 だから最初の30秒がすべて\n'
        '・**すぐ声に出す**：「田中さんですね」と返す。それだけで置き場に留まる時間が伸びます\n'
        '・**かたまりにする**：「タナカ」より「田んぼの中の田中さん」。'
        '意味がつくと1チャンクとして扱えます\n'
        '・**欲ばらない**：一度に4人まで。それ以上は名刺を見返す前提で動く\n\n'
        '⚠️ ただし、ここで頑張っても**まだ長期記憶にはなっていません**。'
        '置き場に留めるのは時間稼ぎで、本当の保存は次のページの話になります。\n\n'
        '🎯 このアプリだと\n'
        '「まとめて命名」で6人・9人・12人を選べるのは、'
        'この「せまい置き場」をどこまで広げられるかの練習でもあります。'
        '4人前後で苦しくなったら、それが今のあなたの素の容量です。',
    bodyEn: 'The instant someone says their name, it is sitting in **short-term memory** — '
        'a very small shelf.\n\n'
        'That shelf has two harsh limits.\n\n'
        '📦 **It is narrow**\n'
        'Roughly four meaningful chunks at once. That is why the first person drops out '
        'as you reach the third handshake.\n\n'
        '⏳ **It is brief**\n'
        'Without rehearsal it fades within tens of seconds. "I knew it a second ago" is '
        'not a personal failing — it is the specification.\n\n'
        '🎯 So the first 30 seconds decide everything\n'
        '・**Say it out loud**: "Nice to meet you, Tanaka-san." That alone extends the shelf life\n'
        '・**Make it a chunk**: give the sound a meaning and it costs you one slot instead of several\n'
        '・**Do not be greedy**: about four people. Beyond that, plan to check the cards again\n\n'
        '⚠️ Even done well, none of this is long-term memory yet. Holding the shelf is '
        'buying time; real storage is the next page.\n\n'
        '🎯 In this app\n'
        'Choosing 6, 9 or 12 people is practice at stretching that narrow shelf. '
        'Where it starts to hurt is roughly your raw capacity.',
    gradient: [Color(0xFFFFF1E0), Color(0xFFFFE9F2)],
  ),
  MemoryTipPage(
    emoji: '🌙',
    titleJa: '名前のしくみ②：短期を長期に変える工程',
    titleEn: 'How names work ②: turning short into long',
    bodyJa: 'せまい置き場から、消えない棚へ。'
        'この引っ越しは**固定化（consolidation）**と呼ばれ、'
        'あなたが意識していない時間に進むと考えられています。\n\n'
        '2025年に出た大きな総説（400ページ超）は、'
        '睡眠中の長期記憶づくりを**能動的システム固定化**という枠組みで整理しています。'
        'その描像はこうです。\n\n'
        '🔁 **リプレイ**\n'
        '起きているあいだに海馬へ刻まれた並びが、'
        'ノンレム睡眠中に何度も再生される。\n\n'
        '🌊 **オーケストレーション**\n'
        '徐波・紡錘波といった睡眠中の脳のリズムが、'
        'その再生のタイミングを取り仕切り、情報の流れを整える。\n\n'
        '🏛️ **新皮質化**\n'
        'くり返し再生された表現が、海馬から大脳新皮質の長期の棚へ移っていく。'
        'このとき記憶は**より抽象的な形に作りかえられる**とされます。\n\n'
        'つまり「覚える」は録音ではなく、**編集と引っ越しを含む工程**です。'
        'ただしこの総説は、何が最終的に残るのか・シナプスのレベルで'
        'どう保存されるのかは**まだ論争中**だとも明言しています。\n\n'
        '🎯 このアプリだと\n'
        '・その日の特訓は「素材の録音」。棚入れは寝ているあいだに進みます\n'
        '・翌日もう一度おなじ名簿に会うと、引っ越し済みかどうかが分かります\n'
        '・**思い出せなかった＝消えた、ではありません**。'
        '棚のどこに置いたか分からないだけのこともあります\n\n'
        '🔬 出典（PubMedより）\n'
        '・Lutz, N. D., Harkotte, M., & Born, J. (2025). Sleep\'s contribution to memory '
        'formation. Physiological Reviews, 106(1), 363–483. doi:10.1152/physrev.00054.2024\n\n'
        '※ヒトとげっ歯類の広範な研究をまとめた総説です。'
        'このアプリは医療機器ではなく、治療・予防の効果をうたうものではありません。',
    bodyEn: 'From the narrow shelf to the permanent one. That move is called '
        '**consolidation**, and it largely happens while you are not paying attention.\n\n'
        'A large 2025 review organises sleep-dependent long-term memory formation as an '
        '**active systems consolidation** process:\n\n'
        '🔁 **Replay** — sequences encoded in the hippocampus during the day are replayed '
        'repeatedly during non-REM sleep.\n\n'
        '🌊 **Orchestration** — slow oscillations and spindles time that replay and regulate '
        'the flow of information across networks.\n\n'
        '🏛️ **Neocorticalization** — replayed representations move to long-term neocortical '
        'stores, and are **transformed into more abstract representations** on the way.\n\n'
        'So "remembering" is not recording. It is editing plus relocation. The same review '
        'is explicit that what ultimately gets stored, and how, **remains contested**.\n\n'
        '🎯 In this app\n'
        '・A training session is the raw recording; shelving happens while you sleep\n'
        '・Meeting the same roster tomorrow tells you whether the move completed\n'
        '・**Failing to recall is not the same as erased** — sometimes you just lost the shelf\n\n'
        '🔬 Source (via PubMed)\n'
        '・Lutz, N. D., Harkotte, M., & Born, J. (2025). Sleep\'s contribution to memory '
        'formation. Physiological Reviews, 106(1), 363–483. doi:10.1152/physrev.00054.2024\n\n'
        '※ A review across human and rodent work. This app is not a medical device and makes '
        'no claim to treat or prevent anything.',
    gradient: [Color(0xFFE6ECFF), Color(0xFFF3E8FF)],
  ),
  MemoryTipPage(
    emoji: '🧬',
    titleJa: 'おまけ③：脳から声を取り出す — BMIはどこまで来たか',
    titleEn: 'Bonus ③: pulling a voice out of the brain — where BMI stands',
    bodyJa: '名前を思い出して口に出す。'
        'この当たり前の一連が病気で断たれたとき、'
        '**脳と機械をつなぐ（BMI／BCI）**という道が現実に動き始めています。\n\n'
        '🗣️ **2025年：その場で声になる**\n'
        '筋萎縮性側索硬化症（ALS）で発話が困難になった男性の脳（腹側運動前野）に'
        '256本の微小電極を入れ、神経活動から**遅延なく音声を合成する**装置が報告されました。\n\n'
        '注目すべきは、文字にしなかった点です。'
        '文字起こしでは抑揚も声色も落ちてしまう。'
        'この研究では音韻の中身に加えて**パラ言語的な特徴**まで読み出し、'
        '本人がリアルタイムで抑揚を変えたり、短いメロディを歌ったりできました。'
        '「何を言ったか」だけでなく「どう言ったか」が戻ってきたわけです。\n\n'
        '🤫 **同じ2025年：内なる声も読めてしまう**\n'
        '別のチームは、声に出さない**内言（inner speech）**が運動野にはっきり表れており、'
        '想像した文をリアルタイムで解読できることを4人の参加者で示しました。'
        '実際に話そうとするのは疲れるので、これは朗報でもあります。\n\n'
        'ただし同じ論文は、私的な内言の一部も解読され得ることを確かめたうえで、'
        '**意図しない内言を装置が読まないための防止策**まで併せて示しています。'
        'できることの報告と、してはいけないことへの手当てが同じ論文に載っている。'
        'この分野の作法として、なかなか誠実な形だと思います。\n\n'
        '🌌 **そして「マインドアップロード」**\n'
        'ここから先は、はっきり分けて読んでください。\n\n'
        '上の2つは**査読を通った実験結果**です。'
        '一方、意識や記憶をまるごと計算機に移すという構想は、'
        '現時点では**実証された技術ではなく、思考実験に近い**位置にあります。'
        '読み出せているのは運動野から出ていく「発話の指令」であって、'
        'その人の記憶や主観そのものではありません。\n\n'
        'そして、より根っこの問いが残ります。'
        '仮に神経のつながりを完全に写し取れたとして、'
        '**そのコピーに「感じ」は宿るのか**。\n\n'
        'これは前のページで見た**意識のハードプロブレム**そのものです。'
        '統合情報理論（IIT）のように「意識は物理的な統合構造そのもの」と考えるなら、'
        '別の基盤に移した写しが同じ意識になる保証はありません。'
        '対してグローバル・ワークスペース理論のように機能的な放送とみなすなら、'
        '同じ働きを再現できれば同じ、という筋も立ちます。'
        '2025年の敵対的検証でも、**どちらにも軍配は上がりませんでした**。\n\n'
        '🎯 だから、いまのところ\n'
        '名前を覚えるいちばん確実な方法は、'
        '残念ながら（そして少し痛快なことに）**自分の海馬に何度も通すこと**です。'
        'アップロードを待つより、今日もう1周したほうが早い。\n\n'
        '🔬 出典（PubMedより）\n'
        '・Wairagkar, M., Card, N. S., et al. (2025). An instantaneous voice-synthesis '
        'neuroprosthesis. Nature, 644(8075), 145–152. doi:10.1038/s41586-025-09127-3\n'
        '・Kunz, E. M., Abramovich Krasa, B., et al. (2025). Inner speech in motor cortex and '
        'implications for speech neuroprostheses. Cell, 188(17), 4658–4673. '
        'doi:10.1016/j.cell.2025.06.015\n'
        '・Rosenfeld, J. V. (2024). Neurosurgery and the Brain-Computer Interface. '
        'Advances in Experimental Medicine and Biology, 1462, 513–527. '
        'doi:10.1007/978-3-031-64892-2_32\n\n'
        '※いずれも臨床研究・総説であり、大半の装置は実験段階です。'
        'マインドアップロードについては、確立した科学的裏づけのある技術ではないことを'
        'あらためて明記します。',
    bodyEn: 'Recalling a name and saying it out loud. When illness severs that chain, '
        '**brain-machine interfaces** are now a real avenue.\n\n'
        '🗣️ **2025: voice, instantly**\n'
        '256 microelectrodes were implanted in the ventral precentral gyrus of a man with ALS '
        'and severe dysarthria, and his voice was **synthesized instantaneously** from neural '
        'activity.\n\n'
        'Notably, they did not go via text — transcription drops prosody and timbre. Alongside '
        'phonemic content they decoded **paralinguistic features**, letting him change '
        'intonation in real time and sing short melodies. Not just what he said, but how.\n\n'
        '🤫 **Also 2025: inner speech is legible too**\n'
        'Another team showed **inner speech** is robustly represented in motor cortex and that '
        'imagined sentences can be decoded in real time, across four participants. Since '
        'physically attempting speech is fatiguing, that is good news.\n\n'
        'The same paper confirmed some private inner speech could be decoded — and presented '
        '**safeguards preventing a BCI from decoding it unintentionally**. Capability and '
        'restraint published together; a decent norm for the field.\n\n'
        '🌌 **And "mind uploading"**\n'
        'Read this part separately. The two results above are **peer-reviewed experiments**. '
        'Transferring a mind wholesale into a computer is, today, **closer to a thought '
        'experiment than a demonstrated technology**. What is being read out is the outgoing '
        'motor command for speech — not memories, not subjectivity.\n\n'
        'And the deeper question remains: if you copied every connection perfectly, '
        '**would the copy feel anything?** That is the hard problem from the earlier page. '
        'Under IIT, a copy on a different substrate is not guaranteed the same consciousness. '
        'Under a workspace view, reproducing the function might suffice. The 2025 adversarial '
        'test **crowned neither**.\n\n'
        '🎯 So, for now\n'
        'The most reliable way to learn a name is — annoyingly and rather pleasingly — '
        'to run it through your own hippocampus again. Faster than waiting for the upload.\n\n'
        '🔬 Sources (via PubMed)\n'
        '・Wairagkar, M., Card, N. S., et al. (2025). An instantaneous voice-synthesis '
        'neuroprosthesis. Nature, 644(8075), 145–152. doi:10.1038/s41586-025-09127-3\n'
        '・Kunz, E. M., Abramovich Krasa, B., et al. (2025). Inner speech in motor cortex and '
        'implications for speech neuroprostheses. Cell, 188(17), 4658–4673. '
        'doi:10.1016/j.cell.2025.06.015\n'
        '・Rosenfeld, J. V. (2024). Neurosurgery and the Brain-Computer Interface. '
        'Advances in Experimental Medicine and Biology, 1462, 513–527. '
        'doi:10.1007/978-3-031-64892-2_32\n\n'
        '※ Most such devices remain experimental. Mind uploading in particular is not an '
        'established technology with scientific backing.',
    gradient: [Color(0xFFE3F6FF), Color(0xFFEDE4FF)],
  ),
  MemoryTipPage(
    emoji: '👅',
    titleJa: 'なぜ「顔は分かるのに名前だけ出ない」のか',
    titleEn: 'Why the face comes back but the name does not',
    bodyJa: 'あの人だと分かっているのに名前だけ出てこない——この状態は「舌先現象（tip-of-the-tongue）」と'
        '呼ばれ、1966年から実験的に研究されてきました。頭文字や音の数など「部分的な情報」だけが'
        '出てくることが多いと報告されています。\n\n'
        'なぜ名前だけが落ちるのか。ひとつの説明が「伝達不足（transmission deficit）」仮説です。'
        '人の名前は、意味とのつながりが薄く、その名前だけに通じる音の経路を1本たどるしかない。'
        'そのため経路が弱っていると、意味は思い出せても音が出てこない、と考えられています。\n\n'
        '💡 だからこそ「意味づけ」が効きます。田中さん→田んぼ、のように名前に意味の道をもう1本'
        '足しておくと、片方が詰まってももう片方から辿り着ける、という発想です。\n\n'
        '🔬 出典: Brown & McNeill (1966), Journal of Verbal Learning and Verbal Behavior ／ '
        'Burke, MacKay, Worthley & Wade (1991), Journal of Memory and Language',
    bodyEn: 'You know exactly who they are, but the name will not come. This is the '
        '“tip-of-the-tongue” state, studied experimentally since 1966. People in this state often '
        'recover partial information — the first letter, the number of syllables — but not the word.\n\n'
        'Why do names in particular fail? One account is the “transmission deficit” hypothesis: a person’s '
        'name has thin semantic connections and only one dedicated route to its sounds. If that route is '
        'weak, meaning can be retrieved while the sounds stay out of reach.\n\n'
        '💡 That is why adding meaning helps. Giving a name a second, semantic path means that when one '
        'route is blocked, the other may still get you there.\n\n'
        '🔬 Sources: Brown & McNeill (1966), Journal of Verbal Learning and Verbal Behavior; '
        'Burke, MacKay, Worthley & Wade (1991), Journal of Memory and Language',
    gradient: [Color(0xFFFFF0E3), Color(0xFFFFE8F2)],
  ),
  MemoryTipPage(
    emoji: '😰',
    titleJa: '緊張すると名前が飛ぶのは、気のせいではない',
    titleEn: 'Blanking under pressure is not just in your head',
    bodyJa: '大事な場面ほど名前が出てこない。これは性格の問題というより、ストレスホルモンが'
        '「思い出す」はたらきを邪魔している可能性が指摘されています。\n\n'
        'ストレス下で分泌されるコルチゾールを投与した実験では、**新しく覚える力よりも、すでに覚えた'
        'ことを取り出す力のほうが落ちた**という報告があります。つまり、覚えていないのではなく'
        '「出せない」状態になりうる、ということです。\n\n'
        '💡 対策として研究で挙げられるのは、①事前に何度も思い出しておく（自動化しておく）'
        '②その場で深呼吸などをして立て直す時間をつくる、といった方向です。\n\n'
        '⚠️ 効果の大きさには個人差があり、ここに書いたことは治療や診断の助言ではありません。\n\n'
        '🔬 出典: Kuhlmann, Piel & Wolf (2005), The Journal of Neuroscience ／ '
        'Het, Ramlow & Wolf (2005), Psychoneuroendocrinology',
    bodyEn: 'The bigger the moment, the more likely the name vanishes. Research suggests this is less '
        'about personality than about stress hormones interfering with retrieval itself.\n\n'
        'In studies where cortisol was administered, **retrieval of already-learned material was impaired '
        'more than the ability to learn new material**. In other words, the memory may be there — you just '
        'cannot get it out at that moment.\n\n'
        '💡 Directions suggested by this work: (1) rehearse retrieval beforehand until it is automatic, '
        'and (2) give yourself a beat to settle before you speak.\n\n'
        '⚠️ Effects vary between people, and none of this is medical advice.\n\n'
        '🔬 Sources: Kuhlmann, Piel & Wolf (2005), The Journal of Neuroscience; '
        'Het, Ramlow & Wolf (2005), Psychoneuroendocrinology',
    gradient: [Color(0xFFE8F0FF), Color(0xFFFFF3E0)],
  ),
  MemoryTipPage(
    emoji: '🌏',
    titleJa: '「みんな同じ顔に見える」には名前がある',
    titleEn: 'There is a name for “they all look alike to me”',
    bodyJa: '見慣れないグループの顔は区別しにくい——これは「他人種効果（cross-race effect）」として'
        '長く研究されてきた現象です。39年ぶんの研究をまとめた解析では、自分と同じ人種の顔のほうが'
        '正しく再認されやすく、見慣れない人種の顔では誤認が増える傾向が報告されています。\n\n'
        '原因として有力なのは「経験の差」です。ふだん多く接している顔ほど、その集団の中で個人を'
        '見分けるのに役立つ特徴に注意が向くようになる、と説明されています。逆に言えば、'
        '**練習で縮められる可能性がある**ということでもあります。\n\n'
        '💡 顔を「グループ」でなく「その人固有の特徴」で見るクセをつけるのがコツ。'
        'このアプリでいろいろな顔を反復するのは、その練習そのものです。\n\n'
        '🔬 出典: Meissner & Brigham (2001), Psychology, Public Policy, and Law ／ '
        'Young, Hugenberg, Bernstein & Sacco (2012), Personality and Social Psychology Review',
    bodyEn: 'Faces from an unfamiliar group can be harder to tell apart. This is the long-studied '
        '“cross-race effect”. A meta-analysis covering 39 years of research reported better recognition '
        'for own-race faces and more false identifications for less familiar groups.\n\n'
        'The leading explanation is experience: the more you see a given kind of face, the more your '
        'attention tunes to the features that actually distinguish individuals within it. Which also '
        'means **practice may narrow the gap**.\n\n'
        '💡 The trick is to look for what is specific to this person rather than to the group. '
        'Repeatedly working through varied faces here is exactly that practice.\n\n'
        '🔬 Sources: Meissner & Brigham (2001), Psychology, Public Policy, and Law; '
        'Young, Hugenberg, Bernstein & Sacco (2012), Personality and Social Psychology Review',
    gradient: [Color(0xFFE3FFF4), Color(0xFFE8ECFF)],
  ),
  MemoryTipPage(
    emoji: '🗣',
    titleJa: '名前を呼ぶと、関係が変わる',
    titleEn: 'Saying someone’s name changes the relationship',
    bodyJa: '''名前を覚えるのは、記憶力の問題であると同時に「相手への態度」の問題でもあります。\n\n大学の生物学の授業を対象にした研究では、**教員が自分の名前を知っていると学生が感じていると、授業への参加意欲や「自分はここにいてよい」という感覚が高い**という関連が報告されています。名前を呼ばれること自体が、その場に受け入れられている合図として働くようです。\n\n脳の反応としても、自分の名前は特別に扱われている可能性が示されています。自分の名前を聞いたときには、他人の名前を聞いたときと比べて前頭部や側頭部の活動が強まったという報告があります。\n\nさらに、人は自分の名前に使われている文字を好みやすいという「ネームレター効果」も、くり返し検証されてきました。\n\n💼 仕事なら「〇〇さん、ここどう思いますか？」の一言。\n🏫 学校なら、あいさつのときに名前をつけて呼ぶだけ。\nどちらも、覚えていなければできないことです。\n\n⚠️ ここで挙げたのは関連の報告であり、「名前を呼べば必ず好かれる」と言えるものではありません。\n\n🔬 出典: Cooper ほか (2017), CBE—Life Sciences Education 16(1) ／ Carmody & Lewis (2006), Brain Research 1116(1) ／ Nuttin (1985), European Journal of Social Psychology 15(3)'''
        ,
    bodyEn: '''Remembering names is partly a memory skill and partly an attitude toward the other person.\n\nIn a study of university biology courses, students who felt their instructor knew their name reported higher engagement and a stronger sense of belonging. Being called by name seems to act as a signal of acceptance.\n\nBrain responses point the same way: hearing one’s own name has been reported to produce stronger frontal and temporal activity than hearing other names.\n\nThere is also the well-replicated “name-letter effect” — people tend to prefer the letters that appear in their own name.\n\n💼 At work: “What do you think, [name]?”\n🏫 At school: just add their name to your greeting.\nNeither is possible if you have not remembered it.\n\n⚠️ These are reported associations, not a guarantee that using names makes people like you.\n\n🔬 Sources: Cooper et al. (2017), CBE—Life Sciences Education 16(1); Carmody & Lewis (2006), Brain Research 1116(1); Nuttin (1985), European Journal of Social Psychology 15(3)''',
    gradient: [Color(0xFFFFF0E3), Color(0xFFE3F4FF)],
  ),
  MemoryTipPage(
    emoji: '🌳',
    titleJa: '苗字の由来をたどると、名前は覚えやすくなる',
    titleEn: 'Tracing a surname’s origin makes it easier to remember',
    bodyJa: '''記憶研究でくり返し確かめられているのは、**意味を深く処理したものほど残る**ということです（処理水準）。ただの音として覚えるより、意味の道を1本足したほうが後から取り出しやすくなります。\n\n苗字は、この「意味づけ」の材料が最初から入っています。\n\n・地形から来たもの … 山田＝山あいの田、川上＝川の上流\n・方角や位置 … 東、西村、中島\n・職や役目から来たもの … 服部、犬養\n\n「渡辺さん」に会ったら〈渡し場のほとり〉を思い浮かべる。それだけで、音だけの記憶から意味のある像に変わります。\n\n🔎 由来を調べるなら「苗字由来ネット」などの姓氏データベースが手軽です。諸説あるものも多いので、**正解探しではなく覚えるための手がかり**と割り切るのがコツです。\n\n💡 このアプリの「おまかせで名前をつける」は、実際に多い苗字から選んでいます。由来を想像しながら覚えてみてください。\n\n🔬 出典: Craik & Lockhart (1972), Journal of Verbal Learning and Verbal Behavior 11(6) ／ Craik & Tulving (1975), Journal of Experimental Psychology: General 104(3)'''
        ,
    bodyEn: '''Memory research keeps finding the same thing: **the more deeply you process meaning, the better it sticks** (levels of processing). Adding one semantic path beats memorizing a bare sound.\n\nJapanese surnames come with that material built in:\n\n・From landscape — Yamada (mountain rice field), Kawakami (upper river)\n・From direction — Higashi (east), Nishimura (west village)\n・From occupation — Hattori, Inukai\n\nMeet a “Watanabe” and picture a river crossing. The sound becomes an image with meaning.\n\n🔎 Surname databases make origins easy to look up. Many have competing theories, so treat them as **memory hooks, not facts to get right**.\n\n🔬 Sources: Craik & Lockhart (1972), Journal of Verbal Learning and Verbal Behavior 11(6); Craik & Tulving (1975), Journal of Experimental Psychology: General 104(3)''',
    gradient: [Color(0xFFE8FFE9), Color(0xFFFFF6D8)],
  ),
  MemoryTipPage(
    emoji: '📜',
    titleJa: 'なぜ日本人はみんな苗字を持っているのか',
    titleEn: 'Why everyone in Japan has a surname',
    bodyJa: '''日本人が今のかたちで苗字を名乗るようになったのは、実はそれほど昔ではありません。\n\n・1870年（明治3年）平民苗字許容令 … 平民も苗字を名乗って**よい**とされた\n・1875年（明治8年）平民苗字必称義務令 … 名乗ることが**義務**になった\n・1898年（明治31年）明治民法・戸籍法 … 「家」を単位とする戸籍が整えられた\n\nつまり全国民が苗字を持つ制度は約150年の歴史です。それ以前も屋号や通称は使われていましたが、公式の登録ではありませんでした。\n\n📄 自分のルーツをたどるなら戸籍がいちばん確実です。**除籍謄本・改製原戸籍**をさかのぼると、先祖の氏名・生年月日・続柄・本籍地（住所）・婚姻や死亡の年月日まで記載されています。明治期の戸籍まで届けば、150年ほど前の家族構成が分かることもあります。\n\n⚠️ 戸籍は誰でも取れるわけではありません。戸籍法により、請求できるのは**本人・配偶者・直系の親族（親、祖父母、子、孫など）**が原則です。兄弟姉妹や親戚の戸籍は、正当な理由の説明が必要になります。保存期間の経過で廃棄されている場合もあります。\n\n💡 先祖の名前を知ると、自分の苗字が急に「意味のあるもの」に変わります。それは覚えるための強い手がかりにもなります。\n\n🔬 出典: 平民苗字必称義務令（明治8年太政官布告第22号）／ 戸籍法（昭和22年法律第224号）第10条・第10条の2'''
        ,
    bodyEn: '''Universal surnames in Japan are a surprisingly recent institution.\n\n・1870 — commoners were *permitted* to use surnames\n・1875 — using one became *compulsory*\n・1898 — the Meiji Civil Code and Family Register Act built the household register system\n\nSo the system is only about 150 years old.\n\n📄 Japanese family registers (koseki) let you trace ancestors: names, dates of birth, relationships, registered addresses, marriages and deaths — sometimes back to the Meiji era.\n\n⚠️ Access is legally restricted. Under the Family Register Act, requests are limited in principle to the person, their spouse, and direct ascendants/descendants. Older records may also have been discarded after their retention period.\n\n🔬 Sources: Compulsory Surname Edict of 1875; Family Register Act (Act No. 224 of 1947), Articles 10 and 10-2''',
    gradient: [Color(0xFFFFF3E0), Color(0xFFEFE8FF)],
  ),
  MemoryTipPage(
    emoji: '🧓',
    titleJa: '脳トレと認知症：わかっていること、いないこと',
    titleEn: 'Brain training and dementia: what is and isn’t established',
    bodyJa: '''「脳トレで認知症を予防できるか」は、期待も誤解も多いテーマです。研究で言えるところまでを正直に書きます。\n\n**言えること**\n・高齢者を対象にした大規模な認知トレーニング試験では、訓練した課題そのものの成績は向上し、その効果が数年後まで残ったと報告されています\n・生活習慣（運動・食事・血管リスク管理・認知トレーニング）を組み合わせた介入で、認知機能の低下がゆるやかだったとする試験があります\n・専門家委員会は、難聴・社会的孤立・低教育・高血圧などを**修正可能なリスク要因**として挙げています\n\n**言えないこと**\n・特定のゲームをすれば認知症にならない、とは示されていません\n・訓練した課題以外へ効果が広く波及する（遠転移）かどうかは、今も議論が続いています\n\n💡 このアプリで言えるのはここまでです。ただ、名前を覚えて人と話す行為は「社会的なつながり」に関わります。孤立はリスク要因として挙げられているので、**人と関わり続ける口実として使う**のは理にかなっています。\n\n⚠️ これは診断・治療・予防の助言ではありません。心配なことがあれば医療機関にご相談ください。\n\n🔬 出典: Ball ほか (2002), JAMA 288(18) ／ Rebok ほか (2014), Journal of the American Geriatrics Society 62(1) ／ Ngandu ほか (2015), The Lancet 385(9984) ／ Livingston ほか (2020), The Lancet 396(10248)'''
        ,
    bodyEn: '''Can brain training prevent dementia? Here is what the research supports — and what it does not.\n\n**Supported**\n・Large trials in older adults found gains on the trained tasks, with effects detectable years later\n・Multi-domain lifestyle programmes (exercise, diet, vascular risk management, cognitive training) have been associated with slower cognitive decline\n・Expert commissions list hearing loss, social isolation, low education and hypertension among **modifiable risk factors**\n\n**Not supported**\n・No specific game has been shown to prevent dementia\n・Whether benefits transfer beyond the trained task remains debated\n\n💡 What we can say: remembering names and talking with people relates to social connection, and isolation is listed as a risk factor. Using this as a reason to stay socially engaged is reasonable.\n\n⚠️ This is not medical advice. Please consult a healthcare professional with any concerns.\n\n🔬 Sources: Ball et al. (2002), JAMA 288(18); Rebok et al. (2014), JAGS 62(1); Ngandu et al. (2015), The Lancet 385(9984); Livingston et al. (2020), The Lancet 396(10248)''',
    gradient: [Color(0xFFE3F0FF), Color(0xFFFFE8F0)],
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
  MemoryShortTip(
    '🔗 名前をバラバラの音でなく「ひとかたまりの意味」にまとめると思い出しやすいとされる',
    '🔗 Bundle a name into one meaningful unit (not loose sounds) to aid retrieval',
    source: "O'Rourke & de Diego Balaguer (2019), Neuroscience & Biobehavioral Reviews",
  ),
  MemoryShortTip(
    '🔁 顔と名前の結びつきは、くり返し練習で身につく手続き記憶として保たれやすいとされる',
    '🔁 Face–name links can be built as procedural memory that repetition keeps well',
    source: 'Tak & Hong (2014), Geriatric Nursing',
  ),
  MemoryShortTip(
    '😴 覚えたら眠るのがコツ。睡眠中の脳波の連携が、その日の記憶を選んで強めていると考えられている',
    '😴 Sleep after learning — coupled sleep rhythms are thought to selectively strengthen the day’s memories',
    source: 'Staresina (2024), Trends in Cognitive Sciences',
  ),
  MemoryShortTip(
    '🛏️ 7〜9時間の睡眠と規則的な就寝リズムは、記憶の定着を支える土台とされる',
    '🛏️ 7–9 hours of sleep on a regular schedule is described as the foundation for consolidation',
    source: 'Baranwal, Yu & Siegel (2023), Progress in Cardiovascular Diseases',
  ),
  MemoryShortTip(
    '☕ 寝る前のカフェイン・お酒・強い光は睡眠を分断し、記憶の定着に不利になりうる',
    '☕ Late caffeine, alcohol and bright light fragment sleep, which can work against consolidation',
    source: 'Baranwal, Yu & Siegel (2023), Progress in Cardiovascular Diseases',
  ),
];
