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
        '🧠 「ビジネス特訓」は、出会って→時間をおいて→思い出す、というこの流れそのもの。\n\n'
        '🔬 出典: Roediger & Karpicke (2006), Psychological Science ／ '
        'Morris, Fritz ほか (2005), Applied Cognitive Psychology ／ '
        'Cepeda ほか (2006), Psychological Bulletin',
    bodyEn: 'Recalling something beats rereading it — the well-replicated “testing effect”. '
        'For a name you want to keep, try to retrieve it instead of just reviewing it.\n\n'
        'Spacing your recalls at growing gaps (right away → minutes later → again later) is reported to '
        'help names last even longer (spaced practice).\n\n'
        '🧠 Biz Training is exactly this loop: meet → let time pass → recall.\n\n'
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
        '・ビジネス特訓の「時間をおく → 思い出す」の間は、わざと空けてあります\n'
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
        '・The gap in Biz Training between “time passes” and “recall” is deliberate\n'
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
