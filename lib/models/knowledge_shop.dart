/// 🧠 記憶の殿堂 — コインでアンロックできるプレミアム読み物。
///
/// 記憶術・脳科学の研究知見をわかりやすくまとめた記事。
/// 1記事ずつコインで買って読む。買った記事はマイページから再読できる。
class KnowledgeArticle {
  final String id;
  final String emoji;
  final String titleJa;
  final String titleEn;
  final String bodyJa;
  final String bodyEn;
  final int cost;
  /// 出典（研究の著者・年・誌名・doi）
  final String sourceJa;
  final String sourceEn;

  const KnowledgeArticle({
    required this.id,
    required this.emoji,
    required this.titleJa,
    required this.titleEn,
    required this.bodyJa,
    required this.bodyEn,
    required this.cost,
    required this.sourceJa,
    required this.sourceEn,
  });

  String title(bool ja) => ja ? titleJa : titleEn;
  String body(bool ja) => ja ? bodyJa : bodyEn;
  String source(bool ja) => ja ? sourceJa : sourceEn;
}

const List<KnowledgeArticle> kKnowledgeArticles = [
  KnowledgeArticle(
    id: 'spacing',
    emoji: '⏰',
    titleJa: 'なぜ復習は「あとで」が効くのか',
    titleEn: 'Why spacing works: the science of "later"',
    cost: 120,
    bodyJa: '''「覚えたあと、すぐに復習するより、少し間をあけたほうがよく定着する」——
これはスペーシング効果（分散学習効果）と呼ばれ、記憶研究のなかでも最も再現性の高い知見のひとつです。

Ebbinghaus（1885）が最初に報告してから100年以上、数えきれない研究で確認されています。Cepedaら（2006）のメタ分析では、最適な間隔は「覚えたい期間の10〜20%」だとされています。つまり1週間後に思い出したいなら、1日あけて復習するのが最も効率的。

ペタネームでは「名刺覚え」でこれを使っています。出会ったあと意図的に時間を置いてから、もう一度思い出す——これが定着の鍵です。

⚡ 実践のコツ:
• 今日覚えたことは、明日もう一度思い出す
• 間隔を少しずつ広げていく（1日後→3日後→1週間後）
• 思い出すたびに記憶は強くなる（「検索練習効果」）''',
    bodyEn: '''"Reviewing after a gap works better than reviewing immediately" — this is the spacing effect, one of the most robust findings in memory research.

First reported by Ebbinghaus (1885), it has been confirmed in countless studies. Cepeda et al. (2006) found in a meta-analysis that the optimal spacing is about 10-20% of the desired retention interval — if you want to remember something for a week, review it 1 day later.

PetaName uses this in Card Memory training: you meet someone, time deliberately passes, then you try to recall them.

⚡ Practical tips:
• Review today's learning tomorrow
• Gradually expand the gap (1 day → 3 days → 1 week)
• Each recall attempt strengthens the memory (the "testing effect")''',
    sourceJa: '出典: Cepeda NJ, Pashler H, Vul E, Wixted JT, Rohrer D (2006). Distributed practice in verbal recall tasks. Psychological Bulletin, 132(3), 354-380.',
    sourceEn: 'Source: Cepeda NJ, Pashler H, Vul E, Wixted JT, Rohrer D (2006). Distributed practice in verbal recall tasks. Psychological Bulletin, 132(3), 354-380.',
  ),
  KnowledgeArticle(
    id: 'testing',
    emoji: '🧪',
    titleJa: '思い出すこと自体が、最強の勉強法',
    titleEn: 'Why recalling IS the best way to learn',
    cost: 120,
    bodyJa: '''「テストは成績をつけるもの」と思われがちですが、じつは「テストを受けること自体」が記憶を強くします。これが検索練習効果（testing effect）です。

Roediger & Karpicke（2006）の実験では、同じ内容を「くり返し読んだグループ」と「一度読んでテストしたグループ」を比較。1週間後のテストでは、テストを受けたグループのほうがはるかに多く覚えていました。くり返し読むより、**思い出そうとすることが記憶を強くする**のです。

ペタネームの「なまえコール」は、まさにこれ。顔が出たら名前を思い出す——その行為そのものが、記憶を鍛えています。

⚡ 実践のコツ:
• 答えを見る前に、まず「思い出そう」としてみる
• 間違えてもいい。思い出そうとした努力が大事
• 正解したときの「思い出せた！」が一番の強化になる''',
    bodyEn: '''Tests aren't just for grading — the act of taking a test strengthens memory. This is the testing effect.

Roediger & Karpicke (2006) compared groups who "re-read" material vs. "read once then tested." A week later, the tested group remembered far more. Trying to recall is what strengthens memory.

PetaName's Name Call mode is exactly this: a face appears, you try to recall the name — that act itself trains your memory.

⚡ Practical tips:
• Try to recall before looking at the answer
• Getting it wrong is fine — the effort of retrieval is what matters
• The "I got it!" moment is the strongest reinforcer''',
    sourceJa: '出典: Roediger HL, Karpicke JD (2006). Test-enhanced learning: Taking memory tests improves long-term retention. Psychological Science, 17(3), 249-255.',
    sourceEn: 'Source: Roediger HL, Karpicke JD (2006). Test-enhanced learning. Psychological Science, 17(3), 249-255.',
  ),
  KnowledgeArticle(
    id: 'sleep',
    emoji: '😴',
    titleJa: '覚えたら、眠る——睡眠と記憶の科学',
    titleEn: 'Sleep on it: how sleep consolidates memory',
    cost: 150,
    bodyJa: '''「一晩寝たら覚えていた」——これは偶然ではありません。睡眠は記憶の定着に決定的な役割を果たしています。

Staresinaら（2024, Trends in Cognitive Sciences）の総説によると、睡眠中に脳では「徐波（slow wave）→睡眠紡錘波（spindle）→海馬リップル（ripple）」という3つの波が連携して、その日に覚えたことを長期記憶へ転送しています。このプロセスは「システム固定化」と呼ばれ、ノンレム睡眠（深い眠り）のときに特に活発です。

Baranwalら（2023）は睡眠衛生（寝る前のスマホを控える・カフェインを避ける・規則的な時間に寝る）が記憶固定化を助けると報告しています。

⚡ 実践のコツ:
• 大事なことを覚えた日は、いつもより30分早く寝る
• 寝る直前にスマホを見ない（ブルーライトがメラトニンを抑える）
• 寝る前にその日覚えた顔と名前を軽く思い出してみる''',
    bodyEn: '''"I slept on it and remembered" — this is no accident. Sleep plays a decisive role in memory consolidation.

Staresina et al. (2024, Trends in Cognitive Sciences) describe how during sleep, the brain coordinates slow waves, sleep spindles, and hippocampal ripples to transfer the day's learning into long-term memory — a process called systems consolidation, especially active during deep non-REM sleep.

Baranwal et al. (2023) report that sleep hygiene (avoiding screens before bed, limiting caffeine, consistent bedtimes) supports memory consolidation.

⚡ Practical tips:
• On days you learn something important, go to bed 30 minutes earlier
• Avoid phone screens right before sleep (blue light suppresses melatonin)
• Briefly review the faces and names you learned that day before sleeping''',
    sourceJa: '出典: Staresina BP et al. (2024). How coupled slow oscillations, spindles and ripples coordinate memory consolidation. Trends in Cognitive Sciences, 29(1), 74-86.\nBaranwal N, Yu PK, Siegel NS (2023). Sleep physiology, pathophysiology, and sleep hygiene. Progress in Cardiovascular Diseases, 77, 59-69.',
    sourceEn: 'Source: Staresina BP et al. (2024). Trends in Cognitive Sciences, 29(1), 74-86.\nBaranwal N et al. (2023). Progress in Cardiovascular Diseases, 77, 59-69.',
  ),
  KnowledgeArticle(
    id: 'baker',
    emoji: '🥖',
    titleJa: 'ベイカーさんとパン屋さん——名前記憶の不思議',
    titleEn: 'Baker / baker: why names are uniquely hard to remember',
    cost: 100,
    bodyJa: '''「顔は覚えているのに名前が出てこない」——これはあなたの記憶力が悪いからではありません。人間の脳の仕組みの問題です。

McWeenyら（1987）の古典的な実験で、同じ人物の写真を見せて「この人の名字はBakerさんです」「この人はパン屋（baker）です」と説明したところ、「パン屋」のほうがはるかによく覚えられました。これが「ベイカー（Baker）／ベイカー（baker）錯誤」です。

理由は、名前が「意味のないラベル」だから。人の名前は、その人についての情報を何も運んでいません。「鈴木さん」という名前からは「鈴＋木」以上の情報は得られません。一方「パン屋さん」は、その人の姿や行動を連想させます。

💡 だからこそ、ペタネームでは「名前を映像に変える」「タグをつける」ことを勧めています。名前をただのラベルから意味のある情報に変えれば、ぐっと覚えやすくなります。''',
    bodyEn: '''"I remember the face but not the name" — this is not a personal failing. It's how human brains work.

McWeeny et al. (1987) showed people the same face and told some "his surname is Baker" and others "he is a baker." People remembered "baker" far better. This is the Baker/baker paradox.

The reason: names are arbitrary labels. "Baker" as a name tells you nothing about the person, while "baker" as a profession conjures images of bread, an apron, early mornings.

💡 That's why PetaName encourages turning names into images and using tags — transforming names from empty labels into meaningful information makes them far easier to remember.''',
    sourceJa: '出典: McWeeny KH, Young AW, Hay DC, Ellis AW (1987). Putting names to faces. British Journal of Psychology, 78(2), 143-149.',
    sourceEn: 'Source: McWeeny KH et al. (1987). Putting names to faces. British Journal of Psychology, 78(2), 143-149.',
  ),
  KnowledgeArticle(
    id: 'self',
    emoji: '🪞',
    titleJa: '「自分ごと」にすると忘れない',
    titleEn: 'Make it personal: the self-reference effect',
    cost: 100,
    bodyJa: '''「この人は、自分とどこか似ている」「この人の出身地、行ったことある」——
こんなふうに自分と結びつけた情報は、驚くほどよく覚えています。

Rogersら（1977）が発見した「自己関連づけ効果」です。情報を自分に関連づけて処理すると、そうでない場合より記憶成績がはっきり上がります。自分に関係する情報は、脳が「大事だ」と判断して優先的に処理するからです。

Craik & Tulving（1975）の「処理水準理論」でも同じことが言われています。深く考えた情報ほど残りやすい。名前だけをリピートするより、その人の顔を見て「この人、◯◯に似てるな」と考えたほうが、ずっと深く処理していることになります。

💡 ペタネームでの使いかた:
• 名前をつけるとき「自分の知っている◯◯さんと同じ名字だ」と考える
• 趣味を見て「自分も好きだ」と思ったら、それだけで記憶に残りやすくなる''',
    bodyEn: '''"This person reminds me of..." — information connected to yourself is remarkably well remembered.

Rogers et al. (1977) discovered the self-reference effect: processing information in relation to yourself reliably boosts memory. Your brain flags self-relevant information as important.

Craik & Tulving's (1975) levels-of-processing theory says the same: deeper processing leads to better retention. Instead of just repeating a name, looking at a face and thinking "they look like my cousin" is much deeper processing.

💡 How to use this in PetaName:
• When naming someone, connect them to someone you already know
• If you notice a shared hobby, that alone makes the memory stick''',
    sourceJa: '出典: Rogers TB, Kuiper NA, Kirker WS (1977). Self-reference and the encoding of personal information. Journal of Personality and Social Psychology, 35(9), 677-688.\nCraik FIM, Tulving E (1975). Depth of processing and the retention of words. Journal of Experimental Psychology: General, 104(3), 268-294.',
    sourceEn: 'Source: Rogers TB et al. (1977). Journal of Personality and Social Psychology, 35(9), 677-688. / Craik FIM, Tulving E (1975). Journal of Experimental Psychology: General, 104(3), 268-294.',
  ),
];

KnowledgeArticle knowledgeArticleById(String id) => kKnowledgeArticles.firstWhere(
      (a) => a.id == id,
      orElse: () => kKnowledgeArticles.first,
    );
