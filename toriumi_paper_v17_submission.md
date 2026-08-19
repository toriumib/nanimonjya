# 決定論から運命論は導けない

## MacKay の論理的非決定性の定量化と、自由意志論争の公共的帰結

# Determinism Without Fatalism

## Quantifying MacKay's Logical Indeterminacy and Its Consequences for the Public Free-Will Debate

**鳥海健悟 (Kengo Toriumi)**
toriumikengo@gmail.com
2026-08-15 — 投稿用草稿 v17

**投稿先候補**: *Philosophy and the Mind Sciences*（査読つきOA、掲載料なし）
**代替**: *Neuroscience of Consciousness* (Oxford), *Frontiers in Psychology: Consciousness Research*

---

## Abstract

Popular arguments against free will (Sapolsky 2023; Harris 2012) establish, at most, causal determinism. Their public reception, however, is fatalistic: readers conclude that deliberation is pointless. We argue that this inference is invalid, and we make the invalidity precise. Using interventionist causal semantics (Pearl 2009), fatalism is the claim that the distribution of outcomes is invariant under intervention on deliberation, $P(O \mid do(D{=}d))$ independent of $d$. Determinism carries no such implication; on the contrary, determinism asserts that causes reliably produce effects, so if deliberation is a cause, deliberation reliably matters. The intervention literature — implementation intentions, cognitive reappraisal, imposed delay — reports non-null effects, which falsifies fatalism directly. We further note that leading hard determinists are committed to the denial of fatalism by their own reform advocacy.

We then revisit MacKay's (1960) demonstration that a physically determinate brain can be unpredictable in principle to any predictor whose prediction can reach the agent, and we give MacKay's argument an operational measure: the self-prediction gap $\Gamma$, the probability that an agent's pre-deliberation self-prediction differs from its post-deliberation choice. We provide a deterministic, randomness-free computational instantiation exhibiting $\Gamma(k{=}0)=0$ and $\Gamma(k{\ge}1)>0$, and we are explicit that this establishes only the non-emptiness of the category "deterministic yet self-unpredictable" — it establishes nothing about human beings. We specify what would have to be measured in humans, and what would falsify the account.

We claim no resolution of the free-will problem, no account of phenomenal consciousness, and no thermodynamic observable.

**Keywords**: fatalism, determinism, interventionist causation, logical indeterminacy, MacKay, self-prediction, epiphenomenalism

---

## 1. 序論 — 論争の公共的帰結

### 1.1 問題

Sapolsky (2023) *Determined*、Harris (2012) *Free Will* をはじめとする自由意志否定論は、一般読者に広く届いた。だが、届いた内容は著者の論証とは異なる。

論証が確立するのは、せいぜい**因果的決定論**である。読者が受け取るのは**運命論**——「どうせ決まっているなら、考えても무駄だ」である。

この受け取りかたは論理的に不当である。本稿はその不当性を形式的に示す。

### 1.2 三つの主張を区別する

議論の混乱の大半は、次の三つの混同から生じている。

| | 主張 | 本稿の立場 |
|---|---|---|
| **決定論 (determinism)** | 状態と法則から次状態が一意に定まる | **中立**。肯定も否定もしない |
| **予測可能性 (predictability)** | ある系が他の系の未来を確実に予測できる | **偽**（§4、MacKay 1960） |
| **運命論 (fatalism)** | 何をしようと結果は変わらない | **偽**（§3、経験的に反証済み） |

三者は独立である。とくに**決定論と運命論は両立しない**——というより、決定論はむしろ運命論を否定する方向に働く。決定論とは「原因が結果を確実に生む」という主張だからである。熟慮が原因であるならば、決定論のもとで熟慮は結果を**確実に**変える。

### 1.3 本稿の構成と貢献

- **§3**: 運命論を介入主義的因果の言語で定式化し、既存の介入研究がそれを反証していることを示す。あわせて、ハード決定論の主唱者自身が、その社会改革論において運命論を否定していることを指摘する。
- **§4**: MacKay (1960) の論理的非決定性を再訪し、**その独創性を正しく帰属させた上で**、操作的尺度 $\Gamma$ を与える。
- **§5**: $\Gamma$ の計算機実装を示し、**それが何を示さないか**を明示する。
- **§6**: Libet パラダイムと後続研究との関係を整理する。
- **§7**: 人間での測定計画と反証条件。
- **§8**: 限界。

**本稿が主張しないこと**を先に述べる。自由意志問題の解決、現象的意識の説明、新たな物理量の発見——いずれも主張しない。

---

## 2. 先行研究と本稿の位置

### 2.1 MacKay (1960) — 本稿の直接の先行研究

D. M. MacKay の "On the Logical Indeterminacy of a Free Choice" (*Mind* 69(273), 31-40) は、本稿の中心的洞察をすでに含んでいる。**この事実を最初に明記する。**

MacKay の議論の骨子：

1. **決定論に対して中立である**。p.32:
   > 「これらすべては、脳過程の物理的決定性を否定する（あるいは肯定する）必要をわれわれに一切課さない」

2. **予測の伝達が予測対象を変えるため、予測計算は完了しない**。p.32:
   > 「彼の予測が成功するためには、その定式化と伝達が私の脳に及ぼすであろう関連効果を織り込まねばならない。しかしそれらの効果は、予測自体がすでに既知でない限り一般には計算できず、したがって厳密な計算は一般に完了しえない」

3. **決定論的でありながら原理的に予測不能でありうる**。p.33:
   > 「私の脳は、動作において物理的に決定的でありながら、なお原理的に予測不能でありうる」

4. **確実性は観測者に相対的である**。p.33:
   > 「真理・信頼性・確実性は、それ単独で命題に帰属させることはできず、Pを抱いている人との関係におけるPにのみ帰属する」

5. **量子的非決定性による自由意志の擁護を拒絶する**。p.31:
   > 「そのような不確定性を『自由』にとって本質的とみなすのは、見当違いであり、かつ不道徳である」

MacKay 自身は Popper (1950) の計算機械の限界に関する分析を、類似の論理的状況として引用している（p.32）。

**本稿の $\Gamma$ は、MacKay の(2)(3)の定量化である。概念的新規性はない。** 本稿が加えるのは、尺度・実装・実験プロトコル、および§3の運命論の形式的分離である。

### 2.2 両立論の系譜

Dennett (1984, 2003) は、決定論が「不可避性」を含意しないこと、および回避可能性が決定論的世界で増大しうることを論じた。本稿の§3は、Dennett の主張を介入主義的因果の語彙で書き直したものと見なしうる。

List (2019) は、エージェント水準の様相が物理水準に還元されないことを論じる。MacKay の観測者相対性（上記(4)）と本稿の $\Gamma(A \to A) \ne \Gamma(B \to A)$ は、List の枠組みにおける水準相対性の一例である。

Carroll (2016) の詩的自然主義は、ミクロの決定性とマクロ水準の記述の実在性が両立するとする立場であり、本稿の前提と整合的である。

Kane (1996) は自由意志に量子的非決定性を要求する。**本稿はこれを要求しない。** §5の実装は乱数を一切用いない。この点で本稿は MacKay の立場（上記(5)）を継承し、Kane と袂を分かつ。

### 2.3 本稿が使わないもの

以下は本稿の論証に用いない。理由を明記する。

- **Penrose-Lucas のゲーデル論法**: Putnam, Feferman, Chalmers らによる反論に決定的な応答がない。**そして本稿の論証はこれを必要としない**——§5の実装は計算可能な決定論的関数である。非計算性を要求しないことは、本稿の前提の頑健性を高める。
- **Orch-OR / 微小管の量子過程**: 脳温でのデコヒーレンス時間に関する批判 (Tegmark 2000) への応答が不十分であり、かつ本稿の論証に不要である。
- **熱力学的定式化**: 著者は以前、自己予測の失敗に Landauer 原理を適用する定式化を試みた。これは撤回する。Landauer 束縛は論理的非可逆操作（消去）に適用されるが、当該構成に消去は現れない (Bennett 1973)。また Still et al. (2012) の予測熱力学定理は「系から駆動信号へのフィードバックが無いこと」を明示的に仮定しており（同論文 p.1）、自己参照系には適用できない。**自己参照系の熱力学的定式化は未解決問題であり、本稿はこれを扱わない。**

---

## 3. 運命論の形式化と反証

### 3.1 定式化

介入主義的因果 (Pearl 2009) の語彙を用いる。熟慮過程を $D$、行動的帰結を $O$ とする。

**定義 3.1（運命論）**
$$\forall d_1, d_2 \in \mathcal{D}: \quad P\bigl(O \mid do(D{=}d_1)\bigr) = P\bigl(O \mid do(D{=}d_2)\bigr)$$

すなわち「熟慮に外的に介入して中身を変えても、帰結の分布は不変である」。これが「何をしようと結果は同じ」の厳密形である。

**定義 3.2（決定論）**
$$s_{t+1} = F(s_t), \quad F\ \text{は一意}$$

**命題 3.3** 定義3.1と定義3.2は論理的に独立である。

*論証.* 決定論は $D$ が $O$ の因果的祖先であることと矛盾しない。むしろ $D \to O$ の経路が存在する決定論的系では、$D$ への介入は $O$ を確実に変える。逆に、非決定論的な系でも $D$ が $O$ に接続していなければ運命論は真でありうる。ゆえに両者に含意関係はない。∎

### 3.2 因果図による対比

運命論が要求する構造と、実際の構造は異なる。

```
運命論:      背景要因 ─────────────────→ O
                └──→ D  （Oへの経路なし）

両立論:      背景要因 ──→ D ──→ O
```

運命論は「$D$ を経由しない経路のみが $O$ を決める」と主張する。これは $D$ から $O$ への因果効果がゼロであるという**経験的主張**であり、定義や形而上学の問題ではない。

### 3.3 反証

$D$ への介入が $O$ を変えることは、確立した介入研究が繰り返し報告している。

| 介入 | 操作の対象 | 報告されている効果 |
|---|---|---|
| 実行意図 (implementation intentions) | 「もしXならYする」の事前形成 | 目標達成率の上昇【要検証：最新メタ分析の効果量】 |
| 認知的再評価 (reappraisal) | 刺激の解釈の教示 | 情動反応・神経反応の変化【要検証】 |
| 遅延の強制 (cooling-off) | 判断前の時間挿入 | 衝動的選択の減少【要検証】 |

運命論が真であれば、これらの効果はすべてゼロでなければならない。効果はゼロではない。**ゆえに運命論は偽である。**

⚠️ 投稿前に、上記3行それぞれについて最新のメタ分析を引用し、効果量と信頼区間を記載すること。「効果がある」ではなく「効果量 $d$ = ○○ [95%CI]」と書く。ここが本稿の中心的経験的根拠であり、二次資料や記憶による記述は許されない。

### 3.4 「熟慮自体が決定されている」への応答

予想される反論：$D$ が $O$ を変えるとしても、$D$ 自体が遺伝・環境・生理状態によって決定されている。ゆえに結局すべては決まっている。

**応答**: これは決定論の再主張であり、運命論の擁護ではない。$D$ が因果連鎖の内部にあることと、$D$ が $O$ の原因であることは両立する。後者は前者を前提とすらしている。

比喩的に言えば、温度計の示す値が物理法則によって決まっていることは、温度計が温度を測っていないことを意味しない。**因果的に決定されていることと、因果的に効いていることは、両立する。**

### 3.5 ハード決定論者の内的整合性

本節は本稿でもっとも直接的な論点である。

Sapolsky (2023) は自由意志を否定すると同時に、刑罰制度の抜本的改革を主張する。改革が意味を持つのは、**環境や制度への介入が人間の行動的帰結を変える場合に限られる**。すなわち Sapolsky は、介入が帰結を変えることを前提としている。

同様に、Harris (2012) は自由意志の否定が人生観を改善すると論じる。その論証もまた、信念（熟慮の産物）が帰結を変えることを前提とする。

**したがって、主要なハード決定論者は運命論を否定している。** 彼らが否定するのは自由意志の形而上学的概念であって、熟慮の因果的効力ではない。

この観察の帰結は次のとおりである。**自由意志否定論の一般読者への影響——「考えても無駄だ」——は、否定論者自身の立場によって支持されていない。** 本稿はこの乖離の是正を目的とする。

---

## 4. MacKay の論理的非決定性の定量化

### 4.1 MacKay の議論の再構成

MacKay の中心的洞察を形式化する。エージェント $A$ の状態を $s$、決定関数を $f$、自己シミュレーション（熟慮）を $\sigma$ とする。$\sigma$ は $f$ を内部で呼び出し、その痕跡 $\text{trace}(\sigma(s))$ が状態に追加される。

$$f(s) = g\bigl(s \oplus \text{trace}(\sigma(s))\bigr)$$

$f$ が両辺に現れる。これは通常の関数定義ではなく**不動点方程式**である。

MacKay が散文で述べたのはこれである——予測の計算はそれ自身の結果を入力として要求するため、一般に完了しない。

### 4.2 自己予測ギャップ $\Gamma$

**定義 4.1** $f^{(0)}(s)$ を熟慮前の自己予測、$f^{(k)}(s)$ を $k$ 回の自己シミュレーション後の選択とする。

$$\Gamma := P\bigl[f^{(0)}(s) \ne f^{(k)}(s)\bigr]$$

**$\Gamma$ の解釈について、慎重に述べる。**

$\Gamma$ は「自由意志」の定義**ではない**。著者の以前の草稿は $\Gamma > 0$ を自由意志と同一視したが、これは論点先取であり撤回する。「予測不能性」を「自由」と定義した上で予測不能性を示しても、その定義を認めない対話者には何も伝わらない。

本稿における $\Gamma$ の役割は限定的かつ具体的である：

> $\Gamma > 0$ は、**自己シミュレーション $\sigma$ が状態を変化させたことの指標**である。

これは随伴現象説に対する反論として機能する（§6.3）。自由意志の証明としては機能しない。**用途を絞ることで、$\Gamma$ は論点先取から解放される。**

### 4.3 観測者相対性

MacKay の「Pを抱いている人との関係におけるP」は、次のように書ける。

$$\Gamma(A \to A) \ne \Gamma(B \to A)$$

エージェント $A$ 自身にとっての自己予測可能性と、外部観測者 $B$ にとっての $A$ の予測可能性は、異なる量である。MacKay が示したのは、$B$ の予測が $A$ に到達しうる限り、$B$ の確実性もまた条件付きにとどまるということである。

---

## 5. 計算機実装 — 何を示し、何を示さないか

### 5.1 構成

決定論的・乱数不使用のエージェントを構成する。$H$ を暗号学的ハッシュ関数（SHA-256）、$L$ を追記専用ログ、$\mathcal{O}$ を選択肢集合とする。

$$f_0(L, \mathcal{O}) = \mathcal{O}\bigl[H(L \parallel \mathcal{O}) \bmod |\mathcal{O}|\bigr]$$
$$f_m(L, \mathcal{O}) = \mathcal{O}\bigl[H(L \parallel \text{trace}(f_{m-1}) \parallel \mathcal{O}) \bmod |\mathcal{O}|\bigr]$$

$k=0$ ではトレースが書かれず、予測と選択は同一状態から計算される。ゆえに $\Gamma(0) = 0$。$k \ge 1$ ではトレースが状態を変え、$H$ をランダムオラクルと見なせば $\Gamma \to 1 - 1/|\mathcal{O}|$。

### 5.2 この結果の自明性について（重要）

**$\Gamma(k \ge 1) \approx 1 - 1/|\mathcal{O}|$ は自明である。** これはハッシュ関数の雪崩効果の帰結であり、$H(x)$ と $H(x \parallel y)$ が独立であるという設計上の性質から直ちに従う。実験を要しない。

**この自明性を、本稿は欠点ではなく前提として扱う。**

理由：本実装の役割は「$\Gamma$ が大きい」ことを発見することではない。**「決定論的・乱数ゼロでありながら自己予測が構造的に失敗する系」というカテゴリが空でないことを、構成的に示すこと**である。その目的に対しては、効果が自明であるほうがよい。自明であるとは、効果が実装の細部に依存しないということだからである。

Pereboom (2001) の「決定論かランダムか」という二分法に対して、本実装は第三の選択肢が論理的に可能であることを示す。それ以上でも以下でもない。

### 5.3 明示的な制限

**この実装は、人間について何も示さない。**

- 人間が自己参照的決定系であるかは、経験的問題であり未検証である
- 人間の $\Gamma$ が0でないかは、測定されていない
- $\Gamma$ の大きさが「自由の度合い」に対応するかは、独立の議論を要する

以前の草稿はこの実装を「自由意志の構成的証明」と呼んだ。**その表現は撤回する。**

---

## 6. Libet パラダイムとの関係

### 6.1 標準的な議論

Libet et al. (1983) は、準備電位 (RP) が意識的意図の報告に約0.35秒先行することを示した。標準的解釈は「脳が意識に先んじて決定している」であり、Sapolsky を含む否定論者はこれに依拠する。

### 6.2 後続研究による修正

この解釈は、後続研究によってすでに修正されている。

- **Schurger et al. (2012)**: RP は「決定信号」ではなく、確率的変動が閾値に到達する蓄積過程として説明できる（accumulator model）。Gavenas, Schurger et al. (2024) はこの線を発展させている。【要検証：2024年論文の書誌情報と結論の正確な範囲】
- **Veto 可能性**: 準備電位の発生後も、行動の直前まで意識的な中止が可能であるとする報告がある。【⚠️ 要検証：著者は以前 Haynes (2016) を典拠としたが、これは学術論文ではなく報道記事に基づく可能性がある。原典を特定できない場合、本節から削除すること】

⚠️ **投稿前の必須作業**: 6.2の各主張について査読論文の原典を特定し、主張の範囲を原文に合わせて限定すること。報道記事・二次資料・記憶による記述は本節から排除する。特定できない主張は削除する。

### 6.3 随伴現象説への含意

随伴現象説は、意識的熟慮が因果的効力を持たないとする。

$\Gamma > 0$ は、$\sigma$（自己シミュレーション）が状態を変えたことを意味する。状態が変わらなければ、予測と選択は一致するからである。ゆえに $\Gamma > 0$ は $\sigma$ の因果的効力の指標となる。

**ただし、これは計算機実装における $\Gamma$ についての主張である。** 人間の熟慮が因果的効力を持つかは、§7の実験と§3の介入研究によって扱われるべき経験的問題である。

---

## 7. 実験計画と反証条件

### 7.1 E-A: 運命論の直接検定（最優先）

- **仮説**: $P(O \mid do(D{=}d_1)) \ne P(O \mid do(D{=}d_2))$
- **設計**: 熟慮過程への介入（熟慮時間の操作、選択肢の明示的列挙、実行意図の形成）を無作為割付し、行動的帰結の分布を比較する
- **反証条件**: 効果量がゼロと区別できない
- **実施可能性**: オンライン実験で実施可能。所属機関を要しない
- **必須手続き**: OSF等への事前登録（プレレジストレーション）

### 7.2 E-B: 人間における $\Gamma$ の測定

- **設計**: 二肢選択課題。①「自分はどちらを選ぶと思うか」を予測させる ②実際に選択させる。$\Gamma$ = 不一致率。熟慮時間を操作して $\Gamma$ の変化を見る
- **予測**: 熟慮時間の増大に伴い $\Gamma$ 増大。時間圧下（反射的条件）で $\Gamma$ 低下
- **反証条件**: $\Gamma$ が熟慮時間に依存しない
- **⚠️ 主要な交絡**: 被験者が自分の予測を意図的に裏切る動機を持つと $\Gamma$ が人工的に上昇する。予測を記録するが本人に再提示しない条件を必ず設けること。この交絡の統制は本実験の成否を決める

### 7.3 E-C: 自己参照処理への干渉（将来）

内側前頭前皮質への一時的干渉が $\Gamma$ を低下させるかを検定する。倫理審査と設備を要するため、本稿では計画のみを示す。

### 7.4 反証条件の一覧

| # | 条件 | 影響を受ける主張 |
|---|---|---|
| 1 | 熟慮への介入が帰結分布を変えない | §3。**本稿の中心的主張が崩れる** |
| 2 | $\Gamma$ が熟慮の深さに依存しない | §4, §6.3 |
| 3 | 自己参照の除去が $\Gamma$ を変化させない | §5 |

**条件1が最重要である。** 単一の事前登録実験で決着し、既存手法のみで実施できる。

---

## 8. 限界

本稿が**証明していないこと**を明示する。

1. **決定論の真偽**。本稿は中立である。
2. **人間が自己参照的決定系であること**。E-Bによる検証を要する経験的問題である。
3. **$\Gamma > 0$ が道徳的責任を含意すること**。本稿は責任論に踏み込まない。物理的・計算論的記述と規範的判断は別の問題である。
4. **現象的意識（クオリア）の説明**。なぜ熟慮に主観的な質感が伴うのかは、本稿の射程外である。Nagel (1974) が定式化した一人称視点の還元不可能性は、本稿によって解消されない。IIT も GWT もこれを解決していない。
5. **自己参照系の熱力学**。§2.3で述べたとおり、著者の以前の試みは撤回された。未解決問題である。
6. **概念的新規性**。§2.1で述べたとおり、本稿の中心的洞察は MacKay (1960) に既出である。本稿の寄与は定量化・実装・実験計画・§3の形式化に限られる。

---

## 9. 結論

1. 決定論・予測可能性・運命論は三つの異なる主張であり、これらの混同が自由意志論争の公共的受容を歪めている。
2. 運命論は介入主義的因果の語彙で定式化でき、その定式化のもとで**経験的に反証される**。ハード決定論の主唱者自身が、その改革論において運命論を否定している。
3. MacKay (1960) が示した論理的非決定性は、自己予測ギャップ $\Gamma$ として操作化でき、決定論的・乱数不使用の系で構成的に実現できる。ただしこれは当該カテゴリの非空性を示すにとどまり、人間について何も示さない。
4. 検証すべき中心的経験的問いは、「自由意志は存在するか」ではなく「**熟慮への介入は帰結を変えるか**」である。

自由意志の形而上学的問題は、本稿によって解決されない。しかし、**その問題の未解決を理由に「考えても無駄だ」と結論することは、誤りである**。この誤りの是正が本稿の目的である。

---

## References

⚠️ **すべての文献について、投稿前に原典で書誌情報を確認すること。【要検証】の項目は未確認である。**

Bennett, C. H. (1973). Logical reversibility of computation. *IBM Journal of Research and Development*, 17(6), 525-532.

Carroll, S. (2016). *The Big Picture: On the Origins of Life, Meaning, and the Universe Itself*. Dutton.

Dennett, D. C. (1984). *Elbow Room: The Varieties of Free Will Worth Wanting*. MIT Press.

Dennett, D. C. (2003). *Freedom Evolves*. Viking.

Harris, S. (2012). *Free Will*. Free Press.

Kane, R. (1996). *The Significance of Free Will*. Oxford University Press.

Libet, B., Gleason, C. A., Wright, E. W., & Pearl, D. K. (1983). Time of conscious intention to act in relation to onset of cerebral activity. *Brain*, 106(3), 623-642.

List, C. (2019). *Why Free Will Is Real*. Harvard University Press.

MacKay, D. M. (1960). On the logical indeterminacy of a free choice. *Mind*, 69(273), 31-40. ✅ **原典確認済 (2026-08-15)**

Nagel, T. (1974). What is it like to be a bat? *The Philosophical Review*, 83(4), 435-450.

Pearl, J. (2009). *Causality: Models, Reasoning, and Inference* (2nd ed.). Cambridge University Press.

Pereboom, D. (2001). *Living Without Free Will*. Cambridge University Press.

Popper, K. R. (1950). Indeterminism in quantum physics and in classical physics. *British Journal for the Philosophy of Science*, 1(2), 117-133. 【要検証】※ MacKay (1960) p.32 が同様の論理的状況として言及

Sapolsky, R. M. (2023). *Determined: A Science of Life Without Free Will*. Penguin Press.

Schurger, A., Sitt, J. D., & Dehaene, S. (2012). An accumulator model for spontaneous neural activity prior to self-initiated movement. *PNAS*, 109(42), E2904-E2913. 【要検証】

Still, S., Sivak, D. A., Bell, A. J., & Crooks, G. E. (2012). Thermodynamics of prediction. *Physical Review Letters*, 109(12), 120604. ✅ **原典確認済 (2026-08-15)** ※ §2.3の適用不可の根拠として引用

Wegner, D. M. (2002). *The Illusion of Conscious Will*. MIT Press.

---

## 付録: 投稿までの作業手順

本稿は**まだ投稿できない**。以下を完了させること。順序が重要である。

### 第1段階: 経験的根拠の確定（§3.3）
- [ ] 実行意図・認知的再評価・遅延効果について、最新のメタ分析を特定する
- [ ] 各効果量と95%信頼区間を本文に記載する
- [ ] 効果の頑健性への批判（出版バイアス、再現性）にも触れる

### 第2段階: §6の浄化
- [ ] Schurger et al. (2012) および後続研究の原典を読み、主張の範囲を原文に合わせる
- [ ] Veto 効果の典拠を特定する。**査読論文が特定できなければ §6.2 から削除する**

### 第3段階: 先行研究の精読
- [ ] Dennett *Freedom Evolves*、List *Why Free Will Is Real* を読み、差別化を明示する
- [ ] Popper (1950) の原典を確認する

### 第4段階: 実験
- [ ] E-A を OSF に事前登録する
- [ ] E-A を実施し、実データを §7 に記載する

### 第5段階: 投稿
- [ ] 英訳する（*Philosophy and the Mind Sciences* は英文のみ）
- [ ] 投稿規定に合わせて整形する
- [ ] カバーレターに、本稿が MacKay (1960) の定量化であることを明記する

### 禁止事項
- [ ] 「2000年の論争に終止符」「世界初」「構成的証明」「査読突破」の類の表現を一切使わない
- [ ] 原典未確認の文献を引用しない
- [ ] 【要検証】が1つでも残っている状態で投稿しない
