/*
 * COMMIT STAR — Git モデルのシミュレータ
 *
 * 本物の git は動かさず、コミットDAG / refs / HEAD / index / working tree を
 * 自前で持つ。教育ゲームでは「いつでも巻き戻せる」「内部状態を全部見せられる」
 * ことが最優先なので、実装を自前に寄せている。
 */
const GitEngine = (function () {
  'use strict';

  const HEX = '0123456789abcdef';

  function createRepo() {
    return {
      commits: {},              // id -> {id, msg, parents:[id], files:{name:content}, seq}
      branches: { main: null }, // name -> commit id (null = 未生成のブランチ)
      head: { type: 'branch', name: 'main', id: null },
      index: {},                // ステージング（スナップショット）
      work: {},                 // 作業ツリー
      reflog: [],               // {id, action}
      stash: [],
      tags: {},
      merge: null,              // {branch, commit, conflicts:[name], base}
      seq: 0,
      events: []                // ステージ達成判定用のログ
    };
  }

  function shortId(repo) {
    let s;
    do {
      s = '';
      for (let i = 0; i < 6; i++) s += HEX[(Math.random() * 16) | 0];
    } while (repo.commits[s]);
    return s;
  }

  function headCommitId(repo) {
    return repo.head.type === 'branch' ? repo.branches[repo.head.name] : repo.head.id;
  }

  function commitFiles(repo, id) {
    return id && repo.commits[id] ? Object.assign({}, repo.commits[id].files) : {};
  }

  function headFiles(repo) {
    return commitFiles(repo, headCommitId(repo));
  }

  function pushReflog(repo, id, action) {
    repo.reflog.push({ id: id, action: action });
  }

  function makeCommit(repo, msg, parents, files) {
    const id = shortId(repo);
    repo.commits[id] = {
      id: id,
      msg: msg,
      parents: parents.filter(Boolean),
      files: Object.assign({}, files),
      seq: ++repo.seq
    };
    return repo.commits[id];
  }

  /** ステージ初期化用: コミットを一気に積む */
  function seed(repo, list) {
    // list: [{msg, files}] を main に直列で積む
    let parent = headCommitId(repo);
    list.forEach(function (c) {
      const co = makeCommit(repo, c.msg, [parent], c.files);
      parent = co.id;
      repo.branches[repo.head.name] = co.id;
      pushReflog(repo, co.id, 'commit: ' + c.msg);
    });
    repo.index = headFiles(repo);
    repo.work = headFiles(repo);
    return parent;
  }

  // ---------- rev の解決 ----------
  function resolveRev(repo, rev) {
    if (!rev) return null;
    rev = rev.trim();
    if (rev === 'HEAD') return headCommitId(repo);

    let m = /^HEAD([~^])(\d*)$/.exec(rev);
    if (m) {
      const n = m[2] === '' ? 1 : parseInt(m[2], 10);
      let id = headCommitId(repo);
      for (let i = 0; i < n; i++) {
        if (!id) return null;
        id = repo.commits[id].parents[0] || null;
      }
      return id;
    }
    m = /^HEAD@\{(\d+)\}$/.exec(rev);
    if (m) {
      const idx = repo.reflog.length - 1 - parseInt(m[1], 10);
      return idx >= 0 && repo.reflog[idx] ? repo.reflog[idx].id : null;
    }
    if (Object.prototype.hasOwnProperty.call(repo.branches, rev)) return repo.branches[rev];
    if (repo.tags[rev]) return repo.tags[rev];

    const hit = Object.keys(repo.commits).filter(function (id) { return id.indexOf(rev) === 0; });
    return hit.length === 1 ? hit[0] : null;
  }

  /** ファイル名のゆるい解決（"star" -> "star.dat"） */
  function resolveFile(repo, name) {
    const pool = new Set(Object.keys(repo.work).concat(Object.keys(repo.index), Object.keys(headFiles(repo))));
    if (pool.has(name)) return name;
    const hit = Array.from(pool).filter(function (f) { return f.indexOf(name) === 0; });
    return hit.length === 1 ? hit[0] : null;
  }

  function ancestors(repo, id) {
    const seen = new Set();
    const st = [id];
    while (st.length) {
      const c = st.pop();
      if (!c || seen.has(c)) continue;
      seen.add(c);
      repo.commits[c].parents.forEach(function (p) { st.push(p); });
    }
    return seen;
  }

  function mergeBase(repo, a, b) {
    if (!a || !b) return null;
    const A = ancestors(repo, a);
    const seen = new Set();
    const st = [b];
    let best = null;
    while (st.length) {
      const c = st.pop();
      if (!c || seen.has(c)) continue;
      seen.add(c);
      if (A.has(c)) {
        if (!best || repo.commits[c].seq > repo.commits[best].seq) best = c;
        continue;
      }
      repo.commits[c].parents.forEach(function (p) { st.push(p); });
    }
    return best;
  }

  function isAncestor(repo, a, b) {
    if (!a) return true;
    return ancestors(repo, b).has(a);
  }

  // ---------- 出力ヘルパ ----------
  function out(s) { return { t: 'out', s: s }; }
  function err(s) { return { t: 'err', s: s }; }
  function sys(s) { return { t: 'sys', s: s }; }
  function ok(lines) { return { ok: true, lines: lines }; }
  function ng(lines) { return { ok: false, lines: lines }; }

  function tokenize(line) {
    const re = /"([^"]*)"|'([^']*)'|(\S+)/g;
    const t = [];
    let m;
    while ((m = re.exec(line)) !== null) t.push(m[1] !== undefined ? m[1] : (m[2] !== undefined ? m[2] : m[3]));
    return t;
  }

  function sameFiles(a, b) {
    const ka = Object.keys(a), kb = Object.keys(b);
    if (ka.length !== kb.length) return false;
    return ka.every(function (k) { return a[k] === b[k]; });
  }

  // ---------- 各コマンド ----------
  function cmdStatus(repo) {
    const hf = headFiles(repo);
    const lines = [];
    lines.push(out(repo.head.type === 'branch'
      ? 'ブランチ ' + repo.head.name + ' にいます'
      : '⚠ どのブランチにも属していません（detached HEAD @ ' + repo.head.id + '）'));

    if (repo.merge) {
      lines.push(err('マージ進行中: ' + repo.merge.branch + ' を取り込み中'));
      if (repo.merge.conflicts.length) {
        lines.push(err('未解決の干渉: ' + repo.merge.conflicts.join(', ')));
      }
    }

    const staged = Object.keys(repo.index).filter(function (f) { return repo.index[f] !== hf[f]; })
      .concat(Object.keys(hf).filter(function (f) { return !(f in repo.index); }));
    const dirty = Object.keys(repo.work).filter(function (f) { return repo.work[f] !== repo.index[f]; });

    lines.push(out('— 荷台（ステージ済み） —'));
    lines.push(staged.length ? out('  ' + staged.join(', ')) : out('  （なし）'));
    lines.push(out('— まだ荷台に乗っていない —'));
    lines.push(dirty.length ? out('  ' + dirty.join(', ')) : out('  （なし）'));
    return ok(lines);
  }

  function cmdAdd(repo, args) {
    if (!args.length) return ng([err('何を荷台に乗せますか？  例: add star.dat / add .')]);
    if (args[0] === '.' || args[0] === '-A' || args[0] === '*') {
      repo.index = Object.assign({}, repo.work);
      if (repo.merge) repo.merge.conflicts = repo.merge.conflicts.filter(function (f) {
        return /<<<<<<</.test(repo.work[f] || '');
      });
      repo.events.push({ cmd: 'add', all: true });
      return ok([out('作業ツリーの全てを荷台に乗せた')]);
    }
    const done = [];
    for (const a of args) {
      const f = resolveFile(repo, a);
      if (!f) return ng([err('そんなデータは見当たらない: ' + a)]);
      if (!(f in repo.work)) return ng([err('作業ツリーに存在しない: ' + f)]);
      if (repo.merge && repo.merge.conflicts.indexOf(f) >= 0) {
        if (/<<<<<<</.test(repo.work[f])) return ng([err(f + ' はまだ干渉したままだ。resolve で選択してから乗せろ')]);
        repo.merge.conflicts = repo.merge.conflicts.filter(function (x) { return x !== f; });
      }
      repo.index[f] = repo.work[f];
      done.push(f);
    }
    repo.events.push({ cmd: 'add', files: done });
    return ok([out('荷台に乗せた: ' + done.join(', '))]);
  }

  function cmdCommit(repo, args) {
    let msg = null;
    for (let i = 0; i < args.length; i++) {
      if (args[i] === '-m' || args[i] === '--message') { msg = args[i + 1]; break; }
      if (msg === null && args[i][0] !== '-') msg = args[i];
    }
    if (!msg) return ng([err('記録には名前が要る。  commit -m "メッセージ"')]);

    if (repo.merge && repo.merge.conflicts.length) {
      return ng([err('まだ干渉が残っている: ' + repo.merge.conflicts.join(', '))]);
    }

    const hf = headFiles(repo);
    if (!repo.merge && sameFiles(repo.index, hf)) {
      return ng([err('荷台が空だ（前回の記録から変化がない）。add でデータを乗せろ')]);
    }

    const parents = repo.merge
      ? [headCommitId(repo), repo.merge.commit]
      : [headCommitId(repo)];
    const c = makeCommit(repo, msg, parents, repo.index);

    if (repo.head.type === 'branch') repo.branches[repo.head.name] = c.id;
    else repo.head.id = c.id;

    repo.work = Object.assign({}, repo.index);
    const wasMerge = !!repo.merge;
    repo.merge = null;
    pushReflog(repo, c.id, 'commit: ' + msg);
    repo.events.push({ cmd: 'commit', id: c.id, merge: wasMerge });

    return ok([sys('★ 記録結晶が生成された  [' + c.id + '] ' + msg + (wasMerge ? '（融合記録）' : ''))]);
  }

  function cmdLog(repo) {
    const start = headCommitId(repo);
    if (!start) return ok([out('まだ記録はない')]);
    const seen = new Set();
    const st = [start];
    const list = [];
    while (st.length) {
      const c = st.pop();
      if (!c || seen.has(c)) continue;
      seen.add(c);
      list.push(repo.commits[c]);
      repo.commits[c].parents.forEach(function (p) { st.push(p); });
    }
    list.sort(function (a, b) { return b.seq - a.seq; });
    return ok(list.map(function (c) {
      const refs = Object.keys(repo.branches).filter(function (b) { return repo.branches[b] === c.id; });
      return out('[' + c.id + '] ' + c.msg + (refs.length ? '  ←' + refs.join(',') : ''));
    }));
  }

  function cmdBranch(repo, args) {
    if (!args.length) {
      return ok(Object.keys(repo.branches).map(function (b) {
        return out((repo.head.type === 'branch' && repo.head.name === b ? '* ' : '  ') + b +
          ' → ' + (repo.branches[b] || '（記録なし）'));
      }));
    }
    const name = args[0];
    if (repo.branches[name] !== undefined) return ng([err('その世界線はもうある: ' + name)]);
    repo.branches[name] = headCommitId(repo);
    repo.events.push({ cmd: 'branch', name: name });
    return ok([sys('世界線を分岐させた: ' + name)]);
  }

  function checkoutTo(repo, target, wantBranch) {
    // 本物の git と同じく、まだ記録していない変更は移動先へ持ち越す。
    // （持ち越さないと「作りかけを別世界線に移す」という基本動作が成立しない）
    const before = headFiles(repo);
    const carriedWork = {};
    Object.keys(repo.work).forEach(function (n) {
      if (repo.work[n] !== before[n]) carriedWork[n] = repo.work[n];
    });
    const carriedIndex = {};
    Object.keys(repo.index).forEach(function (n) {
      if (repo.index[n] !== before[n]) carriedIndex[n] = repo.index[n];
    });
    const removedWork = Object.keys(before).filter(function (n) { return !(n in repo.work); });

    if (wantBranch) {
      repo.head = { type: 'branch', name: target, id: null };
    } else {
      repo.head = { type: 'detached', name: null, id: target };
    }
    const files = headFiles(repo);
    repo.work = Object.assign({}, files, carriedWork);
    repo.index = Object.assign({}, files, carriedIndex);
    removedWork.forEach(function (n) { delete repo.work[n]; });
    repo.merge = null;
    pushReflog(repo, headCommitId(repo), 'checkout: ' + target);
  }

  function cmdSwitch(repo, args, allowDetached) {
    if (args[0] === '-c' || args[0] === '-b') {
      const name = args[1];
      if (!name) return ng([err('新しい世界線の名前を指定しろ')]);
      if (repo.branches[name] !== undefined) return ng([err('その世界線はもうある: ' + name)]);
      repo.branches[name] = headCommitId(repo);
      checkoutTo(repo, name, true);
      repo.events.push({ cmd: 'branch', name: name });
      repo.events.push({ cmd: 'switch', to: name, detached: false });
      return ok([sys('世界線 ' + name + ' を作って飛び込んだ')]);
    }
    const target = args[0];
    if (!target) return ng([err('行き先を指定しろ')]);

    if (repo.branches[target] !== undefined) {
      checkoutTo(repo, target, true);
      repo.events.push({ cmd: 'switch', to: target, detached: false });
      return ok([sys('世界線 ' + target + ' に移動した')]);
    }
    const id = resolveRev(repo, target);
    if (!id) return ng([err('その座標は存在しない: ' + target)]);
    if (!allowDetached) return ng([err('switch はブランチ専用だ。過去の一点へ飛ぶなら checkout ' + target)]);

    checkoutTo(repo, id, false);
    repo.events.push({ cmd: 'switch', to: id, detached: true });
    return ok([
      sys('時空座標 ' + id + ' に降り立った'),
      err('⚠ detached HEAD ── どの世界線にも属していない。ここで記録しても、戻れば見失う')
    ]);
  }

  function cmdMerge(repo, args) {
    const name = args[0];
    if (!name) return ng([err('どの世界線を融合する？  merge <ブランチ名>')]);
    const theirs = resolveRev(repo, name);
    if (!theirs) return ng([err('その世界線は無い: ' + name)]);
    if (repo.merge) return ng([err('すでに融合処理中だ')]);
    if (repo.head.type !== 'branch') return ng([err('detached HEAD では融合できない。先にブランチへ戻れ')]);

    const ours = headCommitId(repo);
    if (!ours) return ng([err('こちらに記録が無い')]);
    if (isAncestor(repo, theirs, ours)) return ok([out('すでに取り込み済みだ（何も起きない）')]);

    if (isAncestor(repo, ours, theirs)) {
      // fast-forward
      repo.branches[repo.head.name] = theirs;
      const f = commitFiles(repo, theirs);
      repo.work = Object.assign({}, f);
      repo.index = Object.assign({}, f);
      pushReflog(repo, theirs, 'merge ' + name + ': fast-forward');
      repo.events.push({ cmd: 'merge', ff: true, branch: name });
      return ok([sys('⏩ 早送り融合（fast-forward）── 分岐していないので、そのまま追いついた')]);
    }

    const base = mergeBase(repo, ours, theirs);
    const B = commitFiles(repo, base);
    const O = commitFiles(repo, ours);
    const T = commitFiles(repo, theirs);
    const names = Array.from(new Set(Object.keys(B).concat(Object.keys(O), Object.keys(T))));
    const result = {};
    const conflicts = [];

    names.forEach(function (n) {
      const b = B[n], o = O[n], t = T[n];
      if (o === t) { if (o !== undefined) result[n] = o; return; }
      if (b === o) { if (t !== undefined) result[n] = t; return; }
      if (b === t) { if (o !== undefined) result[n] = o; return; }
      conflicts.push(n);
      result[n] = '<<<<<<< ' + (repo.head.name) + '\n' + (o || '') + '\n=======\n' + (t || '') + '\n>>>>>>> ' + name;
    });

    if (!conflicts.length) {
      const c = makeCommit(repo, 'merge ' + name, [ours, theirs], result);
      repo.branches[repo.head.name] = c.id;
      repo.work = Object.assign({}, result);
      repo.index = Object.assign({}, result);
      pushReflog(repo, c.id, 'merge ' + name);
      repo.events.push({ cmd: 'merge', ff: false, branch: name, id: c.id });
      return ok([sys('✦ 3方向融合に成功 ── 両方の世界線の成果が1つになった  [' + c.id + ']')]);
    }

    repo.merge = { branch: name, commit: theirs, conflicts: conflicts.slice(), base: base, ours: O, theirs: T };
    repo.work = Object.assign({}, result);
    repo.index = Object.assign({}, O);
    repo.events.push({ cmd: 'merge', conflict: true, branch: name });
    return ng([
      err('⚡ 時空干渉が発生した！ ' + conflicts.join(', ')),
      out('同じ場所に2つの現実が重なっている。どちらを残すか決めろ。'),
      out('  resolve <ファイル> ours   … こちらの現実を残す'),
      out('  resolve <ファイル> theirs … 相手の現実を残す'),
      out('  resolve <ファイル> both   … 両方を併記する'),
      out('決めたら  add <ファイル>  →  commit -m "..."  で融合を確定させろ。')
    ]);
  }

  function cmdResolve(repo, args) {
    if (!repo.merge) return ng([err('いま干渉は起きていない')]);
    const f = resolveFile(repo, args[0] || '');
    const how = args[1];
    if (!f || repo.merge.conflicts.indexOf(f) < 0) return ng([err('干渉しているのは: ' + repo.merge.conflicts.join(', '))]);
    if (['ours', 'theirs', 'both'].indexOf(how) < 0) return ng([err('ours / theirs / both のどれかを選べ')]);

    const o = repo.merge.ours[f] || '';
    const t = repo.merge.theirs[f] || '';
    repo.work[f] = how === 'ours' ? o : how === 'theirs' ? t : (o + ' ＋ ' + t);
    repo.events.push({ cmd: 'resolve', file: f, how: how });
    return ok([sys('干渉を収束させた（' + how + '）: ' + f), out('→ add ' + f + ' で荷台に乗せろ')]);
  }

  function cmdReset(repo, args) {
    const hard = args.indexOf('--hard') >= 0;
    const rev = args.filter(function (a) { return a[0] !== '-'; })[0];
    if (!hard) return ng([err('このプロトタイプでは reset --hard <座標> のみ扱う')]);
    const id = resolveRev(repo, rev);
    if (!id) return ng([err('その座標は存在しない: ' + rev)]);

    if (repo.head.type === 'branch') repo.branches[repo.head.name] = id;
    else repo.head.id = id;
    const f = commitFiles(repo, id);
    repo.work = Object.assign({}, f);
    repo.index = Object.assign({}, f);
    repo.merge = null;
    pushReflog(repo, id, 'reset --hard ' + rev);
    repo.events.push({ cmd: 'reset', id: id });
    return ok([err('☠ 時間を ' + id + ' まで巻き戻した。先にあった記録は、どこからも見えなくなった。')]);
  }

  function cmdReflog(repo) {
    if (!repo.reflog.length) return ok([out('星の記録は空だ')]);
    const lines = [];
    for (let i = repo.reflog.length - 1; i >= 0; i--) {
      const e = repo.reflog[i];
      const n = repo.reflog.length - 1 - i;
      lines.push(out('[' + (e.id || '------') + '] HEAD@{' + n + '}: ' + e.action));
    }
    lines.push(sys('★ 星の記録は、消えたはずの座標を覚えている。reset --hard <座標> で戻れる。'));
    repo.events.push({ cmd: 'reflog' });
    return ok(lines);
  }

  function cmdCherryPick(repo, args) {
    const id = resolveRev(repo, args[0]);
    if (!id) return ng([err('その記録は存在しない: ' + args[0])]);
    const c = repo.commits[id];
    const parent = commitFiles(repo, c.parents[0]);
    const next = Object.assign({}, headFiles(repo));
    Object.keys(c.files).forEach(function (n) {
      if (c.files[n] !== parent[n]) next[n] = c.files[n];
    });
    Object.keys(parent).forEach(function (n) { if (!(n in c.files)) delete next[n]; });

    const nc = makeCommit(repo, c.msg + '（持ち帰り）', [headCommitId(repo)], next);
    if (repo.head.type === 'branch') repo.branches[repo.head.name] = nc.id; else repo.head.id = nc.id;
    repo.work = Object.assign({}, next);
    repo.index = Object.assign({}, next);
    pushReflog(repo, nc.id, 'cherry-pick: ' + c.msg);
    repo.events.push({ cmd: 'cherry-pick', from: id, id: nc.id });
    return ok([sys('✦ 別の世界線から成果だけを持ち帰った  [' + nc.id + '] ' + c.msg)]);
  }

  function cmdRevert(repo, args) {
    const id = resolveRev(repo, args[0]);
    if (!id) return ng([err('その記録は存在しない: ' + args[0])]);
    const c = repo.commits[id];
    const parent = commitFiles(repo, c.parents[0]);
    const next = Object.assign({}, headFiles(repo));
    Object.keys(c.files).forEach(function (n) {
      if (c.files[n] !== parent[n]) {
        if (parent[n] === undefined) delete next[n]; else next[n] = parent[n];
      }
    });
    Object.keys(parent).forEach(function (n) { if (!(n in c.files)) next[n] = parent[n]; });

    const nc = makeCommit(repo, 'revert: ' + c.msg, [headCommitId(repo)], next);
    if (repo.head.type === 'branch') repo.branches[repo.head.name] = nc.id; else repo.head.id = nc.id;
    repo.work = Object.assign({}, next);
    repo.index = Object.assign({}, next);
    pushReflog(repo, nc.id, 'revert: ' + c.msg);
    repo.events.push({ cmd: 'revert', of: id, id: nc.id });
    return ok([sys('↺ 歴史は消さず、打ち消す記録を新しく積んだ  [' + nc.id + ']')]);
  }

  function cmdStash(repo, args) {
    if (args[0] === 'pop' || args[0] === 'apply') {
      if (!repo.stash.length) return ng([err('亜空間ポケットは空だ')]);
      const s = repo.stash.pop();
      repo.work = Object.assign({}, s);
      repo.events.push({ cmd: 'stash-pop' });
      return ok([sys('亜空間ポケットから荷物を取り出した')]);
    }
    const hf = headFiles(repo);
    if (sameFiles(repo.work, hf)) return ng([err('しまうものが無い')]);
    repo.stash.push(Object.assign({}, repo.work));
    repo.work = Object.assign({}, hf);
    repo.index = Object.assign({}, hf);
    repo.events.push({ cmd: 'stash' });
    return ok([sys('作業中の荷物を亜空間ポケットにしまった（作業ツリーは記録どおりに戻った）')]);
  }

  function cmdTag(repo, args) {
    if (!args[0]) return ok(Object.keys(repo.tags).map(function (t) { return out(t + ' → ' + repo.tags[t]); }));
    repo.tags[args[0]] = headCommitId(repo);
    repo.events.push({ cmd: 'tag', name: args[0] });
    return ok([sys('記念碑を建てた: ' + args[0])]);
  }

  const HELP = [
    'status                     いまの状態を見る',
    'add <データ> / add .       転送ゲートの荷台に乗せる',
    'commit -m "メッセージ"     荷台の中身を記録結晶にする',
    'log                        記録をさかのぼって見る',
    'branch <名前>              世界線を分岐させる',
    'switch <世界線> / -c <名>  世界線を移動 / 作って移動',
    'checkout <座標>            過去の一点へ飛ぶ（detached HEAD）',
    'merge <世界線>             世界線を融合する',
    'resolve <file> ours|theirs|both   干渉を収束させる',
    'cherry-pick <座標>         他の世界線の成果だけ持ち帰る',
    'revert <座標>              歴史を消さずに打ち消す',
    'reset --hard <座標>        時間を巻き戻す（危険）',
    'reflog                     星の記録＝消えた座標をたどる',
    'stash / stash pop          荷物を亜空間ポケットへ',
    'tag <名前>                 記念碑を建てる'
  ];

  function exec(repo, line) {
    const raw = (line || '').trim();
    if (!raw) return ok([]);
    let t = tokenize(raw);
    if (t[0] === 'git') t = t.slice(1);
    const cmd = (t[0] || '').toLowerCase();
    const args = t.slice(1);

    switch (cmd) {
      case 'help': case '?': return ok(HELP.map(out));
      case 'status': case 'st': return cmdStatus(repo);
      case 'add': return cmdAdd(repo, args);
      case 'commit': return cmdCommit(repo, args);
      case 'log': return cmdLog(repo);
      case 'branch': return cmdBranch(repo, args);
      case 'switch': return cmdSwitch(repo, args, false);
      case 'checkout': return cmdSwitch(repo, args, true);
      case 'merge': return cmdMerge(repo, args);
      case 'resolve': return cmdResolve(repo, args);
      case 'reset': return cmdReset(repo, args);
      case 'reflog': return cmdReflog(repo);
      case 'cherry-pick': case 'cherrypick': return cmdCherryPick(repo, args);
      case 'revert': return cmdRevert(repo, args);
      case 'stash': return cmdStash(repo, args);
      case 'tag': return cmdTag(repo, args);
      case 'clear': return { ok: true, lines: [], clear: true };
      default:
        return ng([err('未知のコマンド: ' + cmd), out('help で使える技の一覧が出る')]);
    }
  }

  const api = {
    createRepo: createRepo,
    seed: seed,
    exec: exec,
    headCommitId: headCommitId,
    headFiles: headFiles,
    commitFiles: commitFiles,
    resolveRev: resolveRev,
    makeCommit: makeCommit,
    pushReflog: pushReflog,
    ancestors: ancestors,
    isAncestor: isAncestor,
    mergeBase: mergeBase,
    HELP: HELP
  };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  return api;
})();
