/*
 * COMMIT STAR — 章（ステージ）定義
 * 各章 = 「新しい技（コマンド）を覚えると、行ける場所と取れる財宝が増える」
 */
const ITEMS = {
  'star.dat':  { icon: '✦', label: '星の欠片' },
  'moon.dat':  { icon: '☾', label: '月の記憶' },
  'sun.dat':   { icon: '☀', label: '陽の紋章' },
  'wing.dat':  { icon: '❖', label: '翼の設計図' },
  'key.dat':   { icon: '⚿', label: '原初の鍵' },
  'gate.cfg':  { icon: '⛨', label: 'ゲート制御' },
  'core.dat':  { icon: '◈', label: '時空炉心' },
  'echo.dat':  { icon: '≋', label: '残響記録' }
};

const ALL_CARDS = {
  status:  { label: 'status',  insert: 'status',                desc: 'いまの状態を見る' },
  add:     { label: 'add',     insert: 'add ',                  desc: '荷台に乗せる' },
  addAll:  { label: 'add .',   insert: 'add .',                 desc: '全部まとめて乗せる' },
  commit:  { label: 'commit',  insert: 'commit -m "',           desc: '記録結晶にする' },
  log:     { label: 'log',     insert: 'log',                   desc: '記録をさかのぼる' },
  branch:  { label: 'branch',  insert: 'branch ',               desc: '世界線を分岐' },
  switch:  { label: 'switch',  insert: 'switch ',               desc: '世界線を移動' },
  switchC: { label: 'switch -c', insert: 'switch -c ',          desc: '作って移動' },
  checkout:{ label: 'checkout',insert: 'checkout ',             desc: '過去の一点へ飛ぶ' },
  merge:   { label: 'merge',   insert: 'merge ',                desc: '世界線を融合' },
  resolve: { label: 'resolve', insert: 'resolve ',              desc: '干渉を収束させる' },
  reset:   { label: 'reset --hard', insert: 'reset --hard ',    desc: '時間を巻き戻す' },
  reflog:  { label: 'reflog',  insert: 'reflog',                desc: '星の記録をたどる' },
  cherry:  { label: 'cherry-pick', insert: 'cherry-pick ',      desc: '成果だけ持ち帰る' },
  revert:  { label: 'revert',  insert: 'revert ',               desc: '打ち消す記録を積む' },
  stash:   { label: 'stash',   insert: 'stash',                 desc: '亜空間ポケットへ' },
  stashPop:{ label: 'stash pop', insert: 'stash pop',           desc: 'ポケットから戻す' },
  help:    { label: 'help',    insert: 'help',                  desc: '技の一覧' }
};

const STAGES = [
  // ------------------------------------------------------------------ CH.1
  {
    ch: 'CH.1',
    name: '記録の間',
    learn: 'add / commit / status',
    reward: 3,
    story: [
      'ようこそ、時渡り。オレは相棒AI「コミット」だ。',
      'この遺跡では、<b>記録した瞬間だけが永遠になる</b>。記録しなかったものは、次の時間ジャンプで消える。',
      '足元に3つの財宝が落ちてる。まず<b>転送ゲートの荷台に乗せて（add）</b>、<b>記録結晶にしろ（commit）</b>。'
    ],
    mission: '3つの財宝すべてを荷台に乗せ、1つの記録結晶として残せ。',
    cards: ['status', 'add', 'addAll', 'commit', 'log', 'help'],
    hints: [
      'まず status。いま何が「荷台に乗っていない」か分かる。',
      'add star.dat のように名前を指定する。add . なら全部いっぺんに乗る。',
      '最後に commit -m "はじまりの記録" 。荷台の中身がそのまま結晶になる。'
    ],
    setup: function (repo) {
      repo.work = {
        'star.dat': 'きらめく星の欠片',
        'moon.dat': '夜を渡る月の記憶',
        'sun.dat': '陽の紋章'
      };
      repo.index = {};
    },
    goal: function (repo) {
      const id = GitEngine.headCommitId(repo);
      if (!id) return false;
      const f = repo.commits[id].files;
      return 'star.dat' in f && 'moon.dat' in f && 'sun.dat' in f;
    },
    clear: '記録は残った。これでお前は、いつでもこの瞬間に戻ってこられる。'
  },

  // ------------------------------------------------------------------ CH.2
  {
    ch: 'CH.2',
    name: '時渡りの回廊',
    learn: 'log / checkout / HEAD',
    reward: 2,
    story: [
      '遺跡の最初期に「原初の鍵」があったらしい。今の時間には、もう無い。',
      '<b>HEAD</b>はお前の意識がいる時点だ。これを過去に動かせば、その時代の世界がまるごと再現される。',
      'まず <b>log</b> で座標を調べろ。そして <b>checkout &lt;座標&gt;</b> で飛べ。──ただし、帰りを忘れるな。'
    ],
    mission: '原初の鍵があった時代へ飛び、確認したら世界線 main へ帰還せよ。',
    cards: ['log', 'checkout', 'switch', 'status', 'help'],
    hints: [
      'log を打つと [座標] が並ぶ。いちばん古いのが最初の記録だ。',
      'checkout a1b2c3 のように、log に出た座標をそのまま打てばいい。',
      '帰るときは switch main 。ブランチに戻ると HEAD が世界線に固定される。'
    ],
    setup: function (repo) {
      GitEngine.seed(repo, [
        { msg: '遺跡、起動', files: { 'key.dat': '原初の鍵', 'star.dat': 'きらめく星の欠片' } },
        { msg: '鍵は封印された', files: { 'star.dat': 'きらめく星の欠片', 'moon.dat': '夜を渡る月の記憶' } },
        { msg: '陽の紋章を発掘', files: { 'star.dat': 'きらめく星の欠片', 'moon.dat': '夜を渡る月の記憶', 'sun.dat': '陽の紋章' } }
      ]);
      this.data = { visited: false };
    },
    goal: function (repo) {
      if (!this.data) this.data = { visited: false };
      // key.dat が見えている状態で detached HEAD になったことがあるか
      if (repo.head.type === 'detached' && 'key.dat' in repo.work) this.data.visited = true;
      return this.data.visited && repo.head.type === 'branch' && repo.head.name === 'main';
    },
    clear: '見たか。過去は消えてない、ただ「今いる場所」が違うだけだ。'
  },

  // ------------------------------------------------------------------ CH.3
  {
    ch: 'CH.3',
    name: '分岐の樹海',
    learn: 'branch / switch',
    reward: 3,
    story: [
      '失敗すると遺跡が崩れる実験をやる。──本編の歴史でやるのは自殺行為だ。',
      'そこで<b>世界線を分ける（branch）</b>。分けた先で何をしても、元の世界線は無傷だ。',
      '新しい世界線を作って飛び込み、そこで「翼の設計図」を記録しろ。'
    ],
    mission: 'main 以外の世界線を作ってそこへ移り、wing.dat を含む記録を1つ残せ。',
    cards: ['branch', 'switchC', 'switch', 'add', 'commit', 'log', 'status'],
    hints: [
      'switch -c wing なら「作る」と「移る」が一度に済む。',
      'branch wing → switch wing でも同じことができる。',
      '移ったら add wing.dat → commit -m "翼の設計図" 。'
    ],
    setup: function (repo) {
      GitEngine.seed(repo, [
        { msg: '遺跡、起動', files: { 'star.dat': 'きらめく星の欠片' } },
        { msg: '月の記憶を確保', files: { 'star.dat': 'きらめく星の欠片', 'moon.dat': '夜を渡る月の記憶' } }
      ]);
      repo.work['wing.dat'] = '空を渡るための設計図';
      this.data = { base: repo.branches.main };
    },
    goal: function (repo) {
      if (repo.head.type !== 'branch' || repo.head.name === 'main') return false;
      const id = repo.branches[repo.head.name];
      if (!id) return false;
      const mainId = repo.branches.main;
      return ('wing.dat' in repo.commits[id].files) && !GitEngine.isAncestor(repo, id, mainId);
    },
    clear: '本編は無傷だ。<b>分けてから作る</b>──これが遺跡探索の基本作法だ。'
  },

  // ------------------------------------------------------------------ CH.4
  {
    ch: 'CH.4',
    name: '融合塔',
    learn: 'merge（fast-forward / 3-way）',
    reward: 4,
    story: [
      '別世界線の成果は、そのままでは本編に存在しない。<b>融合（merge）</b>して初めて現実になる。',
      'main には無い記録が wing にある。main に戻って、wing を取り込め。',
      '分岐後に main 側が動いていなければ<b>早送り（fast-forward）</b>、両方動いていれば<b>3方向融合</b>だ。'
    ],
    mission: '世界線 main に戻り、wing の成果を融合せよ。',
    cards: ['switch', 'merge', 'log', 'status', 'branch'],
    hints: [
      'まず switch main で本編に戻る。',
      'merge wing 。取り込む側に立ってから、取り込む相手の名前を指定する。',
      'log を見ると、main の先端が wing に追いついているのが分かる。'
    ],
    setup: function (repo) {
      GitEngine.seed(repo, [
        { msg: '遺跡、起動', files: { 'star.dat': 'きらめく星の欠片' } },
        { msg: '月の記憶を確保', files: { 'star.dat': 'きらめく星の欠片', 'moon.dat': '夜を渡る月の記憶' } }
      ]);
      const base = repo.branches.main;
      const c = GitEngine.makeCommit(repo, '翼の設計図', [base], {
        'star.dat': 'きらめく星の欠片', 'moon.dat': '夜を渡る月の記憶', 'wing.dat': '空を渡るための設計図'
      });
      repo.branches.wing = c.id;
      GitEngine.pushReflog(repo, c.id, 'commit: 翼の設計図');
      repo.head = { type: 'branch', name: 'wing', id: null };
      repo.work = GitEngine.headFiles(repo);
      repo.index = GitEngine.headFiles(repo);
    },
    goal: function (repo) {
      const m = repo.branches.main, w = repo.branches.wing;
      return !!m && !!w && GitEngine.isAncestor(repo, w, m);
    },
    clear: '融合完了。分けた世界は、必ず戻せる。'
  },

  // ------------------------------------------------------------------ CH.5
  {
    ch: 'CH.5',
    name: '干渉領域',
    learn: 'コンフリクト解決',
    reward: 6,
    boss: true,
    story: [
      '警告。ゲート制御<b>ぜんぶ同じ場所</b>を、2つの世界線が別々に書き換えてる。',
      '<b>これは機械には決められない</b>。片方は人間の判断、片方はAIの判断。どちらを現実にするかは、お前が決めろ。',
      'main に立って shadow を融合しろ。干渉が起きたら resolve で選び、add → commit で確定させろ。'
    ],
    mission: '世界線 shadow を融合し、時空干渉を収束させて融合記録を残せ。',
    cards: ['merge', 'resolve', 'add', 'commit', 'status', 'log', 'switch'],
    hints: [
      'まず merge shadow 。干渉が起きるが、それは失敗じゃない。',
      'resolve gate.cfg ours / theirs / both のどれかを選ぶ。both は両方を残す判断だ。',
      '選んだら add gate.cfg → commit -m "ゲートの答え" で融合記録が確定する。'
    ],
    setup: function (repo) {
      GitEngine.seed(repo, [
        { msg: 'ゲート発見', files: { 'gate.cfg': 'ゲート設定：閉', 'core.dat': '時空炉心' } }
      ]);
      const base = repo.branches.main;
      const ours = GitEngine.makeCommit(repo, '人の判断：開放', [base],
        { 'gate.cfg': 'ゲート設定：開放（人の判断）', 'core.dat': '時空炉心' });
      repo.branches.main = ours.id;
      GitEngine.pushReflog(repo, ours.id, 'commit: 人の判断：開放');
      const theirs = GitEngine.makeCommit(repo, 'AIの判断：封鎖', [base],
        { 'gate.cfg': 'ゲート設定：封鎖（AIの判断）', 'core.dat': '時空炉心' });
      repo.branches.shadow = theirs.id;
      repo.head = { type: 'branch', name: 'main', id: null };
      repo.work = GitEngine.headFiles(repo);
      repo.index = GitEngine.headFiles(repo);
    },
    goal: function (repo) {
      const id = repo.branches.main;
      if (!id || repo.merge) return false;
      return repo.commits[id].parents.length >= 2;
    },
    clear: '干渉は<b>バグじゃない</b>。「2人が同じ場所を本気で考えた」という証拠だ。'
  },

  // ------------------------------------------------------------------ CH.6
  {
    ch: 'CH.6',
    name: '消滅の谷',
    learn: 'reset --hard / reflog',
    reward: 10,
    boss: true,
    story: [
      '──っ、来る！ 敵は<b>時間そのものを巻き戻す</b>。',
      '……やられた。3つの記録が、どこからも見えなくなった。ログにも残っていない。',
      'だが諦めるな。遺跡には<b>星の記録（reflog）</b>がある。<b>お前のHEADが通った座標を、全部覚えてる</b>。'
    ],
    mission: 'reflog で失われた座標を見つけ出し、reset --hard でその時間まで戻せ。',
    cards: ['reflog', 'reset', 'log', 'status', 'switch'],
    hints: [
      'log には出ない。log は「今の先端から辿れる記録」しか見せないからだ。reflog を打て。',
      'reflog の一覧で、消える直前にいた座標を探す。HEAD@{1} あたりが怪しい。',
      'reset --hard <その座標> 。または reset --hard HEAD@{1} でもいい。'
    ],
    setup: function (repo) {
      GitEngine.seed(repo, [
        { msg: '谷へ到達', files: { 'star.dat': 'きらめく星の欠片' } },
        { msg: '時空炉心を確保', files: { 'star.dat': 'きらめく星の欠片', 'core.dat': '時空炉心' } },
        { msg: '残響記録を解読', files: { 'star.dat': 'きらめく星の欠片', 'core.dat': '時空炉心', 'echo.dat': '残響記録' } },
        { msg: '陽の紋章を再発見', files: { 'star.dat': 'きらめく星の欠片', 'core.dat': '時空炉心', 'echo.dat': '残響記録', 'sun.dat': '陽の紋章' } }
      ]);
      const lost = repo.branches.main;
      // 敵の攻撃＝ reset --hard HEAD~3
      GitEngine.exec(repo, 'reset --hard HEAD~3');
      repo.events = [];
      this.data = { lost: lost };
    },
    goal: function (repo) {
      return !!this.data && repo.branches.main === this.data.lost;
    },
    clear: 'Gitは<b>基本的に、何も捨てていない</b>。見失っただけだ。……覚えとけ、これは現実でもお前を救う。'
  },

  // ------------------------------------------------------------------ CH.7
  {
    ch: 'CH.7',
    name: '禁術書庫',
    learn: 'cherry-pick / revert',
    reward: 8,
    story: [
      '最終試練だ。滅んだ世界線 <b>ruin</b> に、「時空炉心」だけが残ってる。世界線ごと取り込むと、災厄も一緒に来る。',
      '<b>cherry-pick</b> ── 記録を1つだけ選んで、今の世界線に持ち帰る術だ。',
      'そして持ち帰った後、要らない記録は <b>revert</b> で打ち消せ。<b>歴史は消さない。打ち消す記録を、新しく積む</b>。'
    ],
    mission: 'ruin の「時空炉心」だけを main に持ち帰り、災厄の記録は revert で打ち消せ。',
    cards: ['log', 'cherry', 'revert', 'switch', 'status', 'merge'],
    hints: [
      'switch ruin → log で座標を確認 → switch main で戻ってくる。',
      'cherry-pick <炉心の座標> 。ruin にいるときではなく、main にいるときに撃つ。',
      '災厄（curse）が現実に混ざったら revert <その座標> 。消すのではなく、打ち消す。'
    ],
    setup: function (repo) {
      GitEngine.seed(repo, [
        { msg: '書庫へ到達', files: { 'star.dat': 'きらめく星の欠片' } }
      ]);
      const base = repo.branches.main;
      const c1 = GitEngine.makeCommit(repo, '時空炉心を発掘', [base],
        { 'star.dat': 'きらめく星の欠片', 'core.dat': '時空炉心' });
      const c2 = GitEngine.makeCommit(repo, '災厄が混入した', [c1.id],
        { 'star.dat': 'きらめく星の欠片', 'core.dat': '時空炉心', 'curse.dat': '災厄コード' });
      repo.branches.ruin = c2.id;
      this.data = { core: c1.id };
    },
    goal: function (repo) {
      const id = repo.branches.main;
      if (!id) return false;
      const f = repo.commits[id].files;
      return ('core.dat' in f) && !('curse.dat' in f) && repo.commits[id].seq > 1;
    },
    clear: '過去を否定せず、前に進む。──それが、歴史を扱う者の作法だ。'
  }
];

if (typeof module !== 'undefined' && module.exports) module.exports = { STAGES: STAGES, ITEMS: ITEMS, ALL_CARDS: ALL_CARDS };
