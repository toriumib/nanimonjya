import 'package:flutter/widgets.dart';

/// 📚 コインで読める読み物。
///
/// **タイトルと導入（[leadJa]）は最初から読める**。本文だけがコインで開く。
/// 何が書いてあるか分からないものにコインは払えないので、
/// 「何の話か」「読むと何が分かるか」までは先に見せる。
///
/// 中身の方針（`memory_tips.dart` と同じ）:
/// - 文章は**完全オリジナル**。外部記事の写しは禁止
/// - 医療・認知機能への**断定は禁止**。「〜と報告されている」で止める
/// - 出典は**実在する研究・教科書・公的機関**のみ。著者・年・掲載誌まで書く
///
/// ⚠️ 出典の巻号・DOI・URLは、公開前に必ず原典で確かめること。
///    ここに書いてあるのは著者・年・誌名までを基本にしてある。
class PremiumArticle {
  final String id; // 保存キー（買った記事の記録に使う）
  final String emoji;
  final int cost; // 開くのに必要なコイン
  final String titleJa;
  final String titleEn;

  /// 買う前に読める導入。
  final String leadJa;
  final String leadEn;

  final String bodyJa;
  final String bodyEn;

  /// 出典（著者・年・誌名）。本文といっしょに開く。
  final List<String> sources;

  final List<Color> gradient;

  const PremiumArticle({
    required this.id,
    required this.emoji,
    required this.cost,
    required this.titleJa,
    required this.titleEn,
    required this.leadJa,
    required this.leadEn,
    required this.bodyJa,
    required this.bodyEn,
    required this.sources,
    required this.gradient,
  });

  String title(bool ja) => ja ? titleJa : titleEn;
  String lead(bool ja) => ja ? leadJa : leadEn;
  String body(bool ja) => ja ? bodyJa : bodyEn;
}

const List<PremiumArticle> kPremiumArticles = [
  // ── 記憶の仕組み ──
  PremiumArticle(
    id: 'a01_where',
    emoji: '🧠',
    cost: 120,
    titleJa: '覚えたことは、頭のどこに残るのか',
    titleEn: 'Where does a memory actually live?',
    leadJa: '「記憶力」というひとつの力があるわけではありません。'
        '種類ごとに担当する場所が違う、という話から始めます。',
    leadEn:
        'There is no single "memory ability". Different kinds of memory rely on different systems.',
    bodyJa: '''記憶はひとかたまりの能力ではなく、いくつかの系統に分かれていると考えられています。

**出来事の記憶と、体で覚えた記憶は別**
「きのう誰に会ったか」のように、いつ・どこで、を伴う記憶と、自転車の乗り方のように体が覚えている記憶は、別の仕組みで支えられていると報告されています。前者は**海馬**を含む内側側頭葉が要になり、後者は基底核や小脳が関わるとされます。

このことがはっきりしたきっかけの一つが、てんかんの治療で内側側頭葉を切除した患者H.M.の報告です。彼は新しい出来事をほとんど覚えられなくなった一方で、練習した運動の腕前は上がっていきました。「覚えられない」のに「うまくなる」——記憶が一枚岩ではないことを示した例として、教科書に載り続けています。

**海馬は保管庫ではなく、まとめ役**
海馬が壊れると古い記憶まで全部消えるわけではありません。新しい出来事を結びつけて登録し、時間をかけて大脳皮質側に落とし込んでいく（**固定化**）中継ぎ役だと考えられています。だから「さっきのことは忘れたのに、昔のことは覚えている」が起こります。

**名前を覚えるときに使っているのはどこか**
顔と名前を結びつけるのは、出来事の記憶に近い働きです。**それ自体に意味がない情報（名前）を、別の情報（顔）に結びつける**という、海馬がいちばん苦手そうで、いちばん得意な仕事です。

🎯 だからこのアプリは
・**間をあけて思い出す**形にしています（固定化には時間がいるため）
・寝る前の一回りをすすめています（睡眠中に固定化が進むと報告されているため）''',
    bodyEn:
        '''Memory is not one ability but several systems.\n\nEpisodic memory ("who did I meet yesterday") depends on the medial temporal lobe including the **hippocampus**, while skill memory such as riding a bike relies on other structures. The patient H.M., who had medial temporal lobe tissue removed to treat epilepsy, could barely form new episodic memories yet still improved at practised motor tasks — a classic demonstration that memory is not a single thing.\n\nThe hippocampus is better described as a binder than a warehouse: it registers new associations and, over time, they become supported by the cortex (**consolidation**). Linking a meaningless label (a name) to a face is exactly this kind of binding job.''',
    sources: [
      'Scoville, W. B., & Milner, B. (1957). Loss of recent memory after bilateral hippocampal lesions. Journal of Neurology, Neurosurgery & Psychiatry, 20(1).',
      'Squire, L. R. (2004). Memory systems of the brain: A brief history and current perspective. Neurobiology of Learning and Memory, 82(3).',
      'Kandel, E. R. ほか. Principles of Neural Science（教科書）.',
    ],
    gradient: [Color(0xFFE3F0FF), Color(0xFFF3E8FF)],
  ),

  PremiumArticle(
    id: 'a02_forget',
    emoji: '📉',
    cost: 120,
    titleJa: '忘却曲線——忘れるのは、あなたの努力不足ではない',
    titleEn: 'The forgetting curve: forgetting is not a personal failing',
    leadJa: '人は覚えた直後からどんどん忘れます。'
        'これは異常ではなく既定の動作で、そこを前提に手を打つと変わります。',
    leadEn:
        'Forgetting starts immediately and steeply. That is the default, not a defect — and it changes what you should do.',
    bodyJa: '''19世紀の終わり、エビングハウスは自分自身を実験台にして、無意味な音節を覚えては時間をおいて測り直す、という記録を取り続けました。そこから見えたのが、**覚えた直後にいちばん急に落ち、そのあとゆるやかになる**という形です。

ここで大事なのは、落ち方の「形」よりも次の2つです。

**① 落ちるのが普通である**
1日たって半分以上思い出せなくても、記憶力が悪いわけではありません。何もしなければそうなる、というだけです。「忘れた自分」を責めるのは、対策としては何も生みません。

**② 思い出し直すと、次の落ち方がゆるくなる**
同じ材料をもう一度覚え直すと、2回目以降は落ちにくくなります。エビングハウス自身が「節約率」——覚え直すのにかかる手間が減ること——として測っていました。**1回で完璧に覚える**のではなく、**落ちかけたところで拾い直す**のが現実的な戦い方です。

**忘却は「消えた」とは限らない**
思い出せないことと、痕跡が消えていることは別だと考えられています。手がかりがそろえば出てくることがあるからです。名前が出てこないときに「顔は分かるのに」となるのは、まさに**取り出しの失敗**です。

🎯 だからこのアプリは
・まちがえた人を**翌日以降にもう一度**出します
・その場でもう1周させるより、間をあけるほうを選んでいます''',
    bodyEn:
        '''Ebbinghaus, experimenting on himself in the late 1800s, showed that retention drops steeply right after learning and then flattens.\n\nTwo points matter more than the exact shape. First, this decline is the default — failing to recall after a day is not a sign of a bad memory. Second, relearning gets cheaper each time; Ebbinghaus measured this as "savings". The practical strategy is not to learn something perfectly once, but to catch it again as it starts to fade.\n\nAlso, failing to retrieve does not prove the trace is gone. "I know the face but not the name" is a retrieval failure, not necessarily erasure.''',
    sources: [
      'Ebbinghaus, H. (1885). Über das Gedächtnis（『記憶について』）.',
      'Wixted, J. T. (2004). The psychology and neuroscience of forgetting. Annual Review of Psychology, 55.',
      'Tulving, E., & Thomson, D. M. (1973). Encoding specificity and retrieval processes in episodic memory. Psychological Review, 80(5).',
    ],
    gradient: [Color(0xFFFFF0E3), Color(0xFFFFE3EE)],
  ),

  // ── 名前を覚える ──
  PremiumArticle(
    id: 'a03_baker',
    emoji: '🥖',
    cost: 150,
    titleJa: 'なぜ「顔は分かるのに名前が出ない」のか',
    titleEn: 'Why the face comes back but the name does not',
    leadJa: '職業なら思い出せるのに、名前だけ出てこない。'
        'この偏りには名前がついていて、理由も見当がついています。',
    leadEn:
        'You can recall their job but not their name. This lopsidedness has a name — and an explanation.',
    bodyJa: '''同じ人物の写真に「パン屋さん」という職業を添えた場合と、「ベイカーさん」という名字を添えた場合で、あとから思い出せる率を比べた実験があります。**同じ音なのに、職業のほうがよく思い出せた**と報告されました。これは**ベイカー／ベイカー錯誤**と呼ばれています。

**なぜ名前だけ不利なのか**

① **名前には意味がない**
「パン屋」なら、店・小麦・朝の匂い、と勝手に連想が伸びます。「ベイカーさん」は、その人を指す以外に何の意味も持ちません。つながる先がない情報は、あとで手繰る糸がありません。

② **名前は取り出しの最後尾にある**
顔を見てから「知っている人だ」→「仕事関係の人だ」→「営業の人だ」→「名前は…」という順で出てくる、という筋道が提案されています。名前は一番奥にあるので、途中で止まると出てきません。「顔は分かるのに」が起きるのはここです。

③ **名前は代わりが利かない**
「ええと、あの、パン関係の」でも会話は進みますが、名前は当てるか外すかしかありません。

**では、どうするか**
効くとされているのは、**意味の無い名前に、無理やり意味の道をつける**ことです。
・名前から絵にできるものを探す（「加藤」→ カツ、など）
・その絵を、顔の目立つ特徴に結びつける
・声に出して一度呼ぶ

奇妙な連想でかまいません。**思い出せる糸が1本増えること**が目的です。

🎯 だからこのアプリは
・名簿づくりで**顔の特徴を一言タグにする**練習を挟んでいます
・4択ではなく「顔を見て名前を言う」形を主にしています''',
    bodyEn:
        '''In a classic study, the same face was easier to remember when a word was given as an occupation ("baker") than as a surname ("Baker") — the **Baker/baker paradox**.\n\nThree reasons are usually offered. A name carries no meaning, so nothing else connects to it. Names also sit at the end of the retrieval chain — face → familiar → context → occupation → name — so a stall anywhere upstream leaves you with "I know the face". And unlike a job, a name has no usable approximation.\n\nThe practical answer is to give the meaningless label a meaning: turn the name into an image, tie that image to a distinctive feature of the face, and say it out loud once.''',
    sources: [
      'McWeeny, K. H., Young, A. W., Hay, D. C., & Ellis, A. W. (1987). Putting names to faces. British Journal of Psychology, 78(2).',
      'Cohen, G. (1990). Why is it difficult to put names to faces? British Journal of Psychology, 81(3).',
      'Bruce, V., & Young, A. (1986). Understanding face recognition. British Journal of Psychology, 77(3).',
    ],
    gradient: [Color(0xFFFFF6D8), Color(0xFFFFE3E3)],
  ),

  PremiumArticle(
    id: 'a04_retrieval',
    emoji: '🎯',
    cost: 150,
    titleJa: '読み返すより、思い出すほうが残る',
    titleEn: 'Retrieving beats re-reading',
    leadJa: 'もう一度読む、線を引く、まとめ直す。'
        'どれも手ごたえはあるのに、残り方では負けると報告されています。',
    leadEn:
        'Re-reading and highlighting feel productive. On later tests, they lose.',
    bodyJa: '''同じ時間をかけるなら、**読み返す**のと**思い出す**のとどちらが残るか。この比較は繰り返し行われていて、多くの場合**思い出すほう**に軍配が上がると報告されています。

**手ごたえと結果が食い違う**
やっかいなのは、読み返すほうが**その場では分かった気がする**ことです。すらすら読めるので「もう覚えた」と感じます。一方、思い出そうとするのは詰まるし、間違えるし、気分が悪い。ところが1週間後に測ると逆転している——この**手ごたえと成果のズれ**が、勉強法を選び間違える原因になります。

概念マップを作り込むより、いったん閉じて思い出したほうが後の成績が良かった、という報告もあります。

**なぜ効くのか**
思い出す行為そのものが、その記憶を作り直していると考えられています。取り出す道を一度通ると、その道が通りやすくなる。だから**テストは測定であると同時に、練習でもある**わけです。

**やり方**
・教材を閉じて、白紙に書き出す
・人の名前なら、名簿を見ずに顔から言ってみる
・間違えたら、そこで答えを見る（**間違えてから見る**のが大事）

学習法を横断的に評価した総説でも、**思い出す練習**と**間隔をあけること**は、有効性の評価が高い部類に入るとされています。

🎯 だからこのアプリは
・「見て覚える」より「顔を見て答える」を主にしています
・まちがえた直後に正解を見せています''',
    bodyEn:
        '''Given the same amount of time, testing yourself generally beats re-reading on later retention.\n\nThe trap is that re-reading feels better in the moment — fluent text feels learned. Retrieval feels effortful and error-prone, yet wins a week later. This mismatch between felt fluency and actual retention is why people pick the weaker method.\n\nRetrieval appears to modify the memory itself: using a retrieval route makes that route easier next time. A test is therefore not only a measurement but a form of practice.''',
    sources: [
      'Roediger, H. L., & Karpicke, J. D. (2006). Test-enhanced learning. Psychological Science, 17(3).',
      'Karpicke, J. D., & Blunt, J. R. (2011). Retrieval practice produces more learning than elaborative studying with concept mapping. Science, 331(6018).',
      'Dunlosky, J. ほか (2013). Improving students\' learning with effective learning techniques. Psychological Science in the Public Interest, 14(1).',
    ],
    gradient: [Color(0xFFE8FFF0), Color(0xFFE3F0FF)],
  ),

  PremiumArticle(
    id: 'a05_spacing',
    emoji: '📆',
    cost: 150,
    titleJa: 'まとめてやらない——間隔をあけるとなぜ残るのか',
    titleEn: 'Spacing it out: why gaps help',
    leadJa: '同じ回数やるなら、1日に詰めるより何日かに散らすほうが残ります。'
        'どれくらいあければいいかにも、目安があります。',
    leadEn:
        'Same number of repetitions, spread across days, retains better. There is even a rule of thumb for the gap.',
    bodyJa: '''総復習の回数が同じでも、**1日に詰め込む**より**何日かに分ける**ほうが後々よく残る、という現象は古くから知られていて、多数の実験をまとめた総説でも一貫した効果として整理されています。

**どれくらいあけるか**
「いつまで覚えていたいか」で変わるとされます。**目標までの期間が長いほど、間隔も長く取るほうがよい**という関係が報告されています。1週間後のテストなら1〜2日おき、半年後まで持たせたいなら数週間おき、といった具合です。

**なぜ効くのか**
はっきり一つには決まっていませんが、有力な説明のひとつは「**少し忘れかけたところで思い出すのがいちばん効く**」というものです。すらすら出てくる状態でもう一度やっても、取り出しの練習になりません。逆に完全に忘れてからでは、思い出せません。**その中間**が狙い目になります。

これは「難しいほうがよい」という考え方の一例で、**望ましい困難**と呼ばれます。楽に感じる勉強ほど残らない、という居心地の悪い話でもあります。

**現実的な組み立て**
・その日のうちに1回
・翌日にもう1回
・数日あけて1回
・以後は間隔を広げていく

完璧である必要はありません。**間があいてから思い出す**という形さえ守れば、細かい日数のずれは大きな問題にならないとされています。

🎯 だからこのアプリは
・まちがえた人を**日をあらためて**出します
・毎日の通知は「昨日覚えた人」を思い出す合図にしています''',
    bodyEn:
        '''For the same number of repetitions, spreading them across days retains better than massing them — a finding consistent across a large body of experiments.\n\nHow long a gap? Roughly, the longer you need to remember it, the longer the gap should be. The common explanation is that retrieval is most useful when the memory has partly faded: fluent recall gives no practice, total forgetting gives no retrieval. The middle is the target — an example of a **desirable difficulty**.\n\nA workable schedule: once today, once tomorrow, once a few days later, then widen.''',
    sources: [
      'Cepeda, N. J., Pashler, H., Vul, E., Wixted, J. T., & Rohrer, D. (2006). Distributed practice in verbal recall tasks. Psychological Bulletin, 132(3).',
      'Bjork, R. A., & Bjork, E. L. (1992). A new theory of disuse and an old theory of stimulus fluctuation.',
      'Dunlosky, J. ほか (2013). Psychological Science in the Public Interest, 14(1).',
    ],
    gradient: [Color(0xFFEFE3FF), Color(0xFFE3F5FF)],
  ),

  PremiumArticle(
    id: 'a06_sleep',
    emoji: '😴',
    cost: 150,
    titleJa: '眠っている間に、記憶は選ばれて固められる',
    titleEn: 'Sleep decides what stays',
    leadJa: '寝ないで覚えるのは、覚えた端から捨てているようなものかもしれません。'
        '睡眠と記憶の関係は、いま最も研究が厚い分野の一つです。',
    leadEn:
        'Studying without sleeping may mean discarding as you go. Sleep and memory is one of the most active areas in the field.',
    bodyJa: '''覚えたあとに眠ると、起きて過ごした場合より後の成績がよい——この方向の報告は多く、睡眠が記憶の**固定化**に関わることは広く受け入れられています。

**「休んだから」だけではない**
単に邪魔が入らないから、という説明では足りないと考えられています。睡眠中に、起きているとき活動した神経の並びが**もう一度なぞられる**ような現象が動物実験で観察されており、覚えたことを能動的に作り直しているのではないか、と議論されています。

**深い眠りと、浅い眠りで役割が違うらしい**
出来事の記憶には、深いノンレム睡眠が関わるという報告が多くあります。一方で技能の記憶にはレム睡眠が関わる、という整理もされています。どちらか一方ではなく、**ひと晩を通した組み合わせ**が要るという見方が有力です。

**選ばれる、ということ**
眠っている間、覚えたことが等しく残るわけではありません。**あとで使うと分かっているもの**が優先されるらしい、という報告があります。「明日テストがある」と思って寝たほうが残りやすい、という話です。

**現実的にできること**
・覚えたい日は、寝る前に一度だけ思い出す
・徹夜でまとめて覚えるのは、費用対効果が悪い
・睡眠不足そのものが、覚える側（記銘）にも響くとされています

⚠️ 効果には個人差があり、ここに書いたことが誰にでも同じように当てはまるわけではありません。眠りの悩みが続く場合は医療機関にご相談ください。

🎯 だからこのアプリは
・通知の時刻を自分で選べるようにしています（寝る前に置く人が多いため）''',
    bodyEn:
        '''Sleeping after learning generally leads to better later performance than staying awake, and sleep is widely accepted as involved in **consolidation**.\n\nIt is not merely the absence of interference. Patterns of neural activity from waking experience appear to be replayed during sleep, suggesting active reprocessing. Deep non-REM sleep is often linked to episodic memory, REM to skills; a full night combining both seems to matter.\n\nWhat is retained is also selective — material expected to be needed later appears to be prioritised.\n\n⚠️ Effects vary between people. If sleep problems persist, please consult a medical professional.''',
    sources: [
      'Diekelmann, S., & Born, J. (2010). The memory function of sleep. Nature Reviews Neuroscience, 11(2).',
      'Rasch, B., & Born, J. (2013). About sleep\'s role in memory. Physiological Reviews, 93(2).',
      '厚生労働省 e-ヘルスネット「睡眠と健康」（公的機関の解説）.',
    ],
    gradient: [Color(0xFFE3E8FF), Color(0xFF1B2A4A)],
  ),

  PremiumArticle(
    id: 'a07_chunk',
    emoji: '🧩',
    cost: 130,
    titleJa: '一度に持てる「かたまり」は、思ったより少ない',
    titleEn: 'You hold fewer chunks than you think',
    leadJa: '電話番号が覚えられないのは、能力の問題ではなく容量の問題です。'
        'ただし、かたまりの作り方は変えられます。',
    leadEn:
        'A phone number is hard because of capacity, not ability — but you can change how you chunk.',
    bodyJa: '''頭の中で一度に扱える情報の数には限りがある、という考え方は古くからあります。よく引かれるのが「7±2」ですが、その後の検討では、まとめ方を封じると**4前後**まで下がるという整理もされています。

**大事なのは「数」ではなく「かたまり」**
限界があるのは**要素の数**ではなく**かたまり（チャンク）の数**だとされます。だから、
・0 9 0 1 2 3 4 5 6 7 8（11個）
・090／1234／5678（3個）
は、同じ数字でも負担が違います。

**知識があるほど、大きなかたまりが作れる**
将棋や囲碁の熟練者が盤面を一目で覚えられるのは、記憶力そのものが違うのではなく、**意味のあるまとまりとして見えている**からだと説明されます（でたらめに並べた盤面では差が小さくなる、という報告があります）。数字の記憶で驚異的な成績を出した学生の記録もありますが、彼は数字を**陸上競技のタイム**として意味づけていました。

つまり、覚える力を上げるというより、**手持ちの知識に結びつけて、かたまりを大きくする**のが現実的です。

**名前に応用すると**
・氏名をバラバラの音として扱わない
・「知っている人・地名・言葉」に寄せる
・会社名＋名前＋肩書を**ひとかたまり**として扱う

🎯 だからこのアプリは
・名刺覚えで、名前だけでなく会社名や肩書もセットで出しています''',
    bodyEn:
        '''There is a limit to how much you can hold at once. The famous figure is "7±2", though later work suggests around 4 when grouping is prevented.\n\nWhat is limited is the number of **chunks**, not raw items — which is why 090/1234/5678 is easier than eleven separate digits. Experts form larger chunks because material is meaningful to them; a student who reached extraordinary digit spans was mapping numbers onto running times.\n\nSo the practical move is not "improve memory" but "connect to what you already know so the chunks get bigger".''',
    sources: [
      'Miller, G. A. (1956). The magical number seven, plus or minus two. Psychological Review, 63(2).',
      'Cowan, N. (2001). The magical number 4 in short-term memory. Behavioral and Brain Sciences, 24(1).',
      'Baddeley, A. D., & Hitch, G. (1974). Working memory.',
      'Ericsson, K. A., Chase, W. G., & Faloon, S. (1980). Acquisition of a memory skill. Science, 208(4448).',
    ],
    gradient: [Color(0xFFFFF3E3), Color(0xFFE3FFF6)],
  ),

  PremiumArticle(
    id: 'a08_self',
    emoji: '🪞',
    cost: 130,
    titleJa: '自分に引きつけたことは、なぜか忘れない',
    titleEn: 'What you relate to yourself, you keep',
    leadJa: '「自分に当てはまるか」を一度考えるだけで、'
        'あとの思い出しやすさが変わると報告されています。',
    leadEn:
        'Simply asking "does this describe me?" changes how well it is later recalled.',
    bodyJa: '''同じ単語について、①字の形を見る ②音を考える ③意味を考える ④**自分に当てはまるか**考える——という違う作業をさせてから、抜き打ちで思い出してもらう実験があります。多くの場合、**④がいちばんよく思い出せた**と報告されています。

**深く処理するほど残る**
そもそも、字面より音、音より意味、と**深く扱うほど残る**という考え方があります（処理水準）。自分に引きつけるのは、その中でもとりわけ強い、というのがこの話です。自分という参照先は情報が多く、結びつけ先が豊富だからだと説明されます。

**名前に使うなら**
・「この人、自分の友達の〇〇に似ている」
・「自分の出身地と同じ地名の名字だ」
・「この人と自分の共通点はなにか」

どれも**その人の情報を、自分の側の情報に結びつける**やり方です。事実である必要はなく、**自分にとって取り出しやすい糸**であれば構いません。

**やってはいけないこと**
相手を覚えるための連想を、口に出さないこと。失礼になり得ますし、口に出さなくても記憶の効果は変わりません。

🎯 だからこのアプリは
・名簿に「自分との関係」「出会った場所」を書ける欄を置いています''',
    bodyEn:
        '''When people judge words in different ways — appearance, sound, meaning, or **whether it describes them** — the self-referent judgement typically produces the best later recall.\n\nThis fits the broader idea that deeper processing retains better, with the self offering an unusually rich set of connections.\n\nFor names: "looks like my friend", "same surname as my hometown", "what do we have in common?" — anything that ties their information to yours. It does not need to be true, only retrievable. Just keep the association to yourself; some are not polite to say out loud.''',
    sources: [
      'Rogers, T. B., Kuiper, N. A., & Kirker, W. S. (1977). Self-reference and the encoding of personal information. Journal of Personality and Social Psychology, 35(9).',
      'Craik, F. I. M., & Tulving, E. (1975). Depth of processing and the retention of words in episodic memory. JEP: General, 104(3).',
    ],
    gradient: [Color(0xFFFFE8F3), Color(0xFFEFE3FF)],
  ),

  PremiumArticle(
    id: 'a09_loci',
    emoji: '🏛',
    cost: 160,
    titleJa: '場所法は、脳の使い方そのものを変えるらしい',
    titleEn: 'The method of loci seems to change how the brain is used',
    leadJa: '記憶術の代表格である「場所法」。'
        '訓練した人の脳を測った研究から、何が起きているのかが見えてきています。',
    leadEn:
        'Brain imaging of people trained in the method of loci hints at what is actually changing.',
    bodyJa: '''覚えたいものを、よく知っている場所（自宅の玄関、廊下、台所…）に順に置いていき、あとでその道順を歩いて回収する——これが**場所法**です。古代から伝わる技法ですが、近年は脳の側からも調べられています。

**訓練で「つなぎ方」が変わる**
記憶術の訓練を受けた人と、競技記憶の選手の脳活動を比べた研究では、**もともとの構造が特別だったというより、活動のつながり方が競技者に近づいていった**という方向の報告がされています。特別な脳の持ち主だけの技ではない、という点が重要です。

**場所を覚えることと、脳**
空間の記憶に海馬が関わることは古くから知られており、複雑な道を覚え続ける職業の人で海馬の一部に違いが見られたという報告もあります。場所法が効くのは、**もともと得意な空間の枠組みに、苦手な情報を乗せている**からだと説明されます。

**名前に使うなら（名前＋イメージ）**
名前を絵にして、顔の目立つ特徴に置く、という方法が古くから試されています。実験でも、この手順を教えた群のほうが名前の再生がよかったと報告されています。
・名前を音の似た物に変える（「山田」→ 山＋田んぼ）
・顔の一番目立つところに、その絵を大きく置く
・その絵を一度、頭の中で動かす

**ただし**
場所法は**順番のあるものを大量に覚える**のに向いています。日常会話の中でとっさに使うには練習が要ります。まずは「名前を絵にする」だけでも十分です。

🎯 だからこのアプリは
・記憶術トレーニングで、タグ付け→連想の手順を毎回はさんでいます''',
    bodyEn:
        '''In the **method of loci**, you place items along a familiar route and later walk it to collect them.\n\nWhen people were trained in mnemonic techniques, their brain connectivity patterns shifted toward those seen in memory competitors — suggesting this is trainable rather than innate. Spatial memory is a strength the technique borrows: you hang hard-to-hold information on a framework you already navigate well.\n\nFor names, converting a name into an image and attaching it to a distinctive facial feature has been tested experimentally, with better name recall than untrained controls.''',
    sources: [
      'Dresler, M. ほか (2017). Mnemonic training reshapes brain networks to support superior memory. Neuron, 93(5).',
      'Maguire, E. A. ほか (2000). Navigation-related structural change in the hippocampi of taxi drivers. PNAS, 97(8).',
      'Morris, P. E., Jones, S., & Hampson, P. (1978). An imagery mnemonic for the learning of people\'s names. British Journal of Psychology, 69(3).',
    ],
    gradient: [Color(0xFFFFF6E3), Color(0xFFE3EEFF)],
  ),

  // ── 年をとってからの記憶・家族 ──
  PremiumArticle(
    id: 'a10_family',
    emoji: '👵',
    cost: 180,
    titleJa: '孫の名前と暮らしを、覚えておくために',
    titleEn: 'Keeping your grandchildren\'s names and lives in mind',
    leadJa: '年齢とともに出てきにくくなるのは、まず固有名詞です。'
        '仕組みが分かれば、打てる手はいくつもあります。',
    leadEn:
        'Proper names are usually the first to become hard to retrieve with age. Knowing why suggests what to do.',
    bodyJa: '''「顔は分かるし、誰の子かも分かる。名前だけ出てこない」——これは年齢とともによく起きます。理由は前に書いたとおりで、**名前は意味を持たず、取り出しの最後尾にある**からです。年齢の影響は、この一番もろいところに先に出ます。

**まず、知っておきたいこと**
一度覚えた顔と名前は、意外なほど長く残るという報告があります。卒業アルバムを使った研究では、卒業から何十年たっても、**顔と名前を結びつける課題の成績が高く保たれていた**とされています。「全部消える」わけではありません。

**やりやすい手立て**

**① 名前を「意味のあるかたまり」にする**
「ゆうと」だけでなく「◯◯（娘）のところの、サッカーのゆうと」。関係と特徴をつけて、ひとかたまりにします。

**② 写真に、その場で名前と一言を書く**
あとで見返すためというより、**書くときに一度思い出す**ことに意味があります。

**③ 会う前に、思い出してから会う**
玄関を開ける前に「今日は誰と誰が来る」と口に出す。読み返しではなく思い出しになります。

**④ 会ったあと、その日の夜に一度**
間をあけて思い出すほうが残ります。寝る前が組み込みやすい時間帯です。

**⑤ 名簿を作っておく**
顔写真・名前・読み方・誕生日・好きなもの。**書いた本人が作る**のが大事で、作る作業そのものが記憶の作業になります。

**⑥ 出てこないとき、無理に絞り出さない**
出ない名前を力ずくで探し続けると、かえって出にくくなることがあると報告されています。いったん離れて、あとで戻るほうが出てくることがあります。

⚠️ 物忘れが以前より明らかに増えた、日常生活に支障が出ている、といった場合は、**このアプリで対処しようとせず**医療機関にご相談ください。ここに書いたのは日常の工夫であって、診断や治療ではありません。認知症の危険因子と予防については、公的機関や国際的な委員会の報告が公開されています。

🎯 だからこのアプリは
・自分の写真で名簿を作れるようにしています（18項目・端末内保存）
・登録した人を、間をあけて出題します''',
    bodyEn:
        '''"I know the face, I know whose child it is — just not the name." Proper names are meaningless labels sitting at the end of the retrieval chain, so age tends to show there first.\n\nWorth knowing: once learned, face–name links can last remarkably long. Studies using school yearbooks found matching performance held up decades after graduation.\n\nPractical steps: bundle the name with relationship and a detail; write the name on the photo (the value is in recalling as you write); recall who is coming before you open the door; recall once again that evening; build your own roster; and if a name will not come, step away rather than forcing it.\n\n⚠️ If forgetfulness has clearly increased or affects daily life, please consult a medical professional rather than relying on an app. This is everyday practice, not diagnosis or treatment.''',
    sources: [
      'Bahrick, H. P., Bahrick, P. O., & Wittlinger, R. P. (1975). Fifty years of memory for names and faces. JEP: General, 104(1).',
      'Cohen, G. (1990). Why is it difficult to put names to faces? British Journal of Psychology, 81(3).',
      'Livingston, G. ほか. Lancet Commission on dementia prevention, intervention, and care（認知症の危険因子に関する国際委員会報告）.',
      'National Institute on Aging (NIA, 米国国立老化研究所) の一般向け解説.',
      '厚生労働省の認知症に関する情報ページ（公的機関）.',
    ],
    gradient: [Color(0xFFFFEFE3), Color(0xFFFFF9E3)],
  ),
];
