/* COMMIT STAR — 画面まわり（DOM / SVGグラフ描画 / 章進行） */
(function () {
  'use strict';

  const $ = function (id) { return document.getElementById(id); };

  const G = {
    stageIndex: 0,
    repo: null,
    stage: null,
    treasures: 0,
    hintIndex: 0,
    known: new Set(),   // すでに描画済みのコミットid（新規だけアニメさせる）
    cleared: false
  };

  // ---------------------------------------------------------------- ターミナル
  function print(text, cls) {
    const term = $('term');
    const div = document.createElement('div');
    div.className = 'l-' + (cls || 'out');
    div.innerHTML = text;
    term.appendChild(div);
    term.scrollTop = term.scrollHeight;
  }
  function clearTerm() { $('term').innerHTML = ''; }

  function esc(s) {
    return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }

  // ---------------------------------------------------------------- 相棒セリフ
  function say(html) { $('bubble').innerHTML = html; }

  // ---------------------------------------------------------------- 状態パネル
  function itemRow(name, content, cls) {
    const meta = ITEMS[name] || { icon: '▪', label: '' };
    const conflicted = /<<<<<<</.test(content || '');
    return '<div class="item ' + (conflicted ? 'conflict' : (cls || '')) + '">' +
      '<span class="ic">' + meta.icon + '</span>' +
      '<span class="nm">' + esc(name) + '</span>' +
      '<span class="lb">' + (conflicted ? '⚡干渉中' : esc(meta.label)) + '</span>' +
      '</div>';
  }

  function renderState() {
    const repo = G.repo;
    const hf = GitEngine.headFiles(repo);
    const headId = GitEngine.headCommitId(repo);

    let hb = '';
    if (repo.head.type === 'branch') {
      hb += '世界線 <span class="hb-branch">' + esc(repo.head.name) + '</span><br>';
    } else {
      hb += '<span class="hb-detached">⚠ detached HEAD</span><br>';
    }
    hb += '座標 <span class="hb-hash">' + (headId || '（記録なし）') + '</span>';
    if (headId) hb += '<br><span class="dim">' + esc(repo.commits[headId].msg) + '</span>';
    if (repo.merge) hb += '<br><span class="hb-detached">融合処理中 ← ' + esc(repo.merge.branch) + '</span>';
    $('headBox').innerHTML = hb;

    const work = Object.keys(repo.work);
    $('workBox').innerHTML = work.length
      ? work.map(function (n) {
          return itemRow(n, repo.work[n], repo.work[n] !== repo.index[n] ? 'new' : '');
        }).join('')
      : '<div class="empty">（空）</div>';

    const idx = Object.keys(repo.index);
    $('indexBox').innerHTML = idx.length
      ? idx.map(function (n) {
          return itemRow(n, repo.index[n], repo.index[n] !== hf[n] ? 'new' : '');
        }).join('')
      : '<div class="empty">（荷台は空）</div>';

    renderConflict();
  }

  function renderConflict() {
    const box = $('conflictBox');
    const repo = G.repo;
    if (!repo.merge || !repo.merge.conflicts.length) { box.classList.add('hidden'); return; }
    box.classList.remove('hidden');
    let h = '<h3>⚡ 時空干渉 — どちらを現実にする？</h3>';
    repo.merge.conflicts.forEach(function (f) {
      h += '<div class="cf-file">' + esc(f) + '</div>';
      h += '<div class="cf-side">ours: ' + esc(repo.merge.ours[f] || '（無し）') + '</div>';
      h += '<div class="cf-side">theirs: ' + esc(repo.merge.theirs[f] || '（無し）') + '</div>';
      h += '<div class="cf-btns">' +
        '<button class="btn-ghost" data-res="' + esc(f) + '|ours">ours</button>' +
        '<button class="btn-ghost" data-res="' + esc(f) + '|theirs">theirs</button>' +
        '<button class="btn-ghost" data-res="' + esc(f) + '|both">both</button>' +
        '</div>';
    });
    box.innerHTML = h;
    Array.prototype.forEach.call(box.querySelectorAll('button[data-res]'), function (b) {
      b.addEventListener('click', function () {
        const p = b.getAttribute('data-res').split('|');
        run('resolve ' + p[0] + ' ' + p[1]);
      });
    });
  }

  // ---------------------------------------------------------------- グラフ
  const LANE_W = 34, ROW_H = 46, PAD_X = 22, PAD_Y = 26, TEXT_X = 0;

  function layout(repo) {
    const ids = Object.keys(repo.commits).sort(function (a, b) {
      return repo.commits[b].seq - repo.commits[a].seq;
    });
    const lanes = [];
    const pos = {};

    ids.forEach(function (id, row) {
      let lane = -1;
      lanes.forEach(function (v, i) {
        if (v === id) { if (lane < 0) lane = i; else lanes[i] = null; }
      });
      if (lane < 0) {
        lane = lanes.indexOf(null);
        if (lane < 0) { lane = lanes.length; lanes.push(null); }
      }
      pos[id] = { row: row, lane: lane };

      const ps = repo.commits[id].parents;
      lanes[lane] = ps[0] || null;
      for (let i = 1; i < ps.length; i++) {
        if (lanes.indexOf(ps[i]) >= 0) continue;
        let l = lanes.indexOf(null);
        if (l < 0) { l = lanes.length; lanes.push(null); }
        lanes[l] = ps[i];
      }
    });
    return { pos: pos, ids: ids, laneCount: Math.max(1, lanes.length) };
  }

  function svgEl(tag, attrs) {
    const e = document.createElementNS('http://www.w3.org/2000/svg', tag);
    Object.keys(attrs).forEach(function (k) { e.setAttribute(k, attrs[k]); });
    return e;
  }

  function renderGraph() {
    const repo = G.repo;
    const svg = $('graph');
    svg.innerHTML = '';
    const L = layout(repo);

    if (!L.ids.length) {
      svg.setAttribute('width', 320);
      svg.setAttribute('height', 80);
      const t = svgEl('text', { x: 16, y: 44, class: 'g-empty' });
      t.textContent = 'まだ記録結晶はない — commit で最初の記録を作れ';
      svg.appendChild(t);
      return;
    }

    const laneArea = PAD_X + L.laneCount * LANE_W;
    let width = Math.max(520, laneArea + 320);
    const height = PAD_Y * 2 + L.ids.length * ROW_H;
    svg.setAttribute('width', width);
    svg.setAttribute('height', height);
    svg.setAttribute('viewBox', '0 0 ' + width + ' ' + height);

    const cx = function (lane) { return PAD_X + lane * LANE_W; };
    const cy = function (row) { return PAD_Y + row * ROW_H; };

    // エッジ
    L.ids.forEach(function (id) {
      const c = repo.commits[id];
      const p0 = L.pos[id];
      c.parents.forEach(function (pid, i) {
        const p1 = L.pos[pid];
        if (!p1) return;
        const x0 = cx(p0.lane), y0 = cy(p0.row), x1 = cx(p1.lane), y1 = cy(p1.row);
        const d = 'M' + x0 + ' ' + y0 +
          ' C' + x0 + ' ' + (y0 + ROW_H * 0.55) + ', ' + x1 + ' ' + (y1 - ROW_H * 0.55) + ', ' + x1 + ' ' + y1;
        svg.appendChild(svgEl('path', { d: d, class: 'edge' + (i > 0 ? ' merge' : '') }));
      });
    });

    const headId = GitEngine.headCommitId(repo);
    let maxRight = width;

    // ノード
    L.ids.forEach(function (id) {
      const c = repo.commits[id];
      const p = L.pos[id];
      const x = cx(p.lane), y = cy(p.row);
      const isMerge = c.parents.length > 1;
      const isHead = id === headId;
      const isNew = !G.known.has(id);
      G.known.add(id);

      const g = svgEl('g', { class: 'node-core' + (isNew ? ' node-new' : '') });
      if (isHead) {
        g.appendChild(svgEl('circle', {
          cx: x, cy: y, r: 13, fill: 'none',
          stroke: repo.head.type === 'detached' ? '#ff6b7d' : '#35e2ff',
          'stroke-width': 1.2, opacity: .7
        }));
      }
      g.appendChild(svgEl('circle', {
        cx: x, cy: y, r: isMerge ? 8 : 6.5,
        fill: isMerge ? '#ff54c8' : (isHead ? '#ffcf5c' : '#35e2ff')
      }));
      svg.appendChild(g);

      const hash = svgEl('text', { x: laneArea, y: y + 4, class: 'g-hash' });
      hash.textContent = id;
      svg.appendChild(hash);

      const msg = svgEl('text', { x: laneArea + 62, y: y + 4, class: 'g-msg' });
      msg.textContent = c.msg.length > 18 ? c.msg.slice(0, 17) + '…' : c.msg;
      svg.appendChild(msg);

      // ref バッジ（日本語は字幅が読めないので実測してから置く）
      const refs = Object.keys(repo.branches).filter(function (b) { return repo.branches[b] === id; });
      if (repo.head.type === 'detached' && id === headId) refs.push('HEAD');
      let msgW = 0;
      try { msgW = msg.getComputedTextLength(); } catch (e) { msgW = c.msg.length * 11; }
      let bx = laneArea + 62 + msgW + 12;
      refs.forEach(function (r) {
        const w = r.length * 7 + 12;
        const isHeadRef = (repo.head.type === 'branch' && repo.head.name === r) || r === 'HEAD';
        svg.appendChild(svgEl('rect', {
          x: bx, y: y - 9, width: w, height: 17, rx: 5,
          fill: isHeadRef ? '#ffcf5c' : '#35e2ff', opacity: isHeadRef ? 1 : .75
        }));
        const t = svgEl('text', { x: bx + 6, y: y + 3.5, class: 'g-ref' });
        t.textContent = r;
        svg.appendChild(t);
        bx += w + 6;
      });
      if (bx + 12 > maxRight) maxRight = bx + 12;
    });

    if (maxRight > width) {
      width = maxRight;
      svg.setAttribute('width', width);
      svg.setAttribute('viewBox', '0 0 ' + width + ' ' + height);
    }
  }

  // ---------------------------------------------------------------- ミッション
  function renderMission() {
    const s = G.stage;
    let h = '<span class="learn">習得: ' + esc(s.learn) + '</span>';
    h += '<div class="goal">' + s.mission + '</div>';
    h += '<div class="done">報酬: ✦ ' + s.reward + '</div>';
    $('missionBox').innerHTML = h;
    $('chapterNo').textContent = s.ch;
    $('stageName').textContent = s.name + (s.boss ? '  ⚔ BOSS' : '');
  }

  function renderCards() {
    const box = $('cards');
    box.innerHTML = '';
    (G.stage.cards || []).forEach(function (key) {
      const c = ALL_CARDS[key];
      if (!c) return;
      const b = document.createElement('button');
      b.className = 'card';
      b.type = 'button';
      b.innerHTML = esc(c.label) + '<small>' + esc(c.desc) + '</small>';
      b.addEventListener('click', function () {
        const input = $('cmdInput');
        input.value = c.insert;
        input.focus();
        if (/\s$|"$/.test(c.insert)) {
          input.setSelectionRange(c.insert.length, c.insert.length);
        } else {
          run(c.insert);
        }
      });
      box.appendChild(b);
    });
  }

  function renderAll() {
    renderState();
    renderGraph();
  }

  // ---------------------------------------------------------------- 章進行
  function loadStage(i) {
    G.stageIndex = i;
    G.stage = STAGES[i];
    G.repo = GitEngine.createRepo();
    G.hintIndex = 0;
    G.known = new Set();
    G.cleared = false;

    if (G.stage.setup) G.stage.setup.call(G.stage, G.repo);
    // 初期状態のノードはアニメさせない
    Object.keys(G.repo.commits).forEach(function (id) { G.known.add(id); });

    clearTerm();
    print('── ' + G.stage.ch + '　' + esc(G.stage.name) + ' ──', 'sys');
    G.stage.story.forEach(function (line) { print(line, 'story'); });
    print('help でいつでも技の一覧が見られる。', 'out');

    say(G.stage.story[G.stage.story.length - 1]);
    renderMission();
    renderCards();
    renderAll();
    $('cmdInput').focus();
    try { localStorage.setItem('cs_stage', String(i)); } catch (e) { /* noop */ }
  }

  function checkGoal() {
    if (G.cleared) return;
    let done = false;
    try { done = !!G.stage.goal.call(G.stage, G.repo); } catch (e) { done = false; }
    if (!done) return;
    G.cleared = true;
    G.treasures += G.stage.reward;
    $('treasureCount').textContent = G.treasures;
    try { localStorage.setItem('cs_treasure', String(G.treasures)); } catch (e) { /* noop */ }

    setTimeout(function () {
      $('clearSub').innerHTML = G.stage.clear;
      $('clearLoot').textContent = '財宝 ✦ +' + G.stage.reward;
      const last = G.stageIndex >= STAGES.length - 1;
      $('btnNext').textContent = last ? 'サンドボックスで自由に遊ぶ' : '次の章へ';
      $('clearOverlay').classList.remove('hidden');
    }, 600);
  }

  function nextStage() {
    $('clearOverlay').classList.add('hidden');
    if (G.stageIndex >= STAGES.length - 1) {
      startSandbox();
    } else {
      loadStage(G.stageIndex + 1);
    }
  }

  function startSandbox() {
    G.stage = {
      ch: 'FREE', name: 'サンドボックス', learn: 'すべての技', reward: 0,
      mission: '好きなだけ試せ。すべてのコマンドが使える。',
      cards: Object.keys(ALL_CARDS),
      story: ['ここは実験場だ。壊しても誰も困らない。<b>reset --hard</b> も <b>reflog</b> も好きに撃て。'],
      hints: ['help で全部の技が出る。', 'branch → commit → merge の流れを自分で組み立ててみろ。'],
      setup: function (repo) {
        GitEngine.seed(repo, [{ msg: '実験場、起動', files: { 'star.dat': 'きらめく星の欠片' } }]);
        repo.work['echo.dat'] = '残響記録';
      },
      goal: function () { return false; },
      clear: ''
    };
    G.repo = GitEngine.createRepo();
    G.stage.setup(G.repo);
    G.known = new Set(Object.keys(G.repo.commits));
    G.cleared = false;
    G.hintIndex = 0;
    clearTerm();
    print('── FREE　サンドボックス ──', 'sys');
    G.stage.story.forEach(function (l) { print(l, 'story'); });
    say(G.stage.story[0]);
    renderMission();
    renderCards();
    renderAll();
  }

  // ---------------------------------------------------------------- 実行
  function run(line) {
    if (!line || !line.trim()) return;
    print(esc(line), 'cmd');
    const res = GitEngine.exec(G.repo, line);
    if (res.clear) { clearTerm(); return; }
    (res.lines || []).forEach(function (l) { print(esc(l.s), l.t); });
    renderAll();
    checkGoal();
  }

  // ---------------------------------------------------------------- 起動
  function boot() {
    $('bootStart').addEventListener('click', function () {
      $('boot').classList.add('gone');
      setTimeout(function () { $('boot').style.display = 'none'; $('cmdInput').focus(); }, 500);
    });

    $('cmdForm').addEventListener('submit', function (e) {
      e.preventDefault();
      const input = $('cmdInput');
      const v = input.value;
      input.value = '';
      run(v);
    });

    $('btnHint').addEventListener('click', function () {
      const hints = G.stage.hints || [];
      if (!hints.length) return;
      const h = hints[Math.min(G.hintIndex, hints.length - 1)];
      G.hintIndex = Math.min(G.hintIndex + 1, hints.length - 1);
      say('💡 ' + h);
      print('💡 ' + h, 'sys');
    });

    $('btnRestart').addEventListener('click', function () {
      if (G.stage && G.stage.ch === 'FREE') { startSandbox(); return; }
      loadStage(G.stageIndex);
    });

    $('btnNext').addEventListener('click', nextStage);

    $('btnMap').addEventListener('click', function () {
      const list = $('mapList');
      list.innerHTML = '';
      STAGES.forEach(function (s, i) {
        const b = document.createElement('button');
        b.innerHTML = '<span class="mch">' + s.ch + '</span>' + esc(s.name) +
          (s.boss ? ' ⚔' : '') + '<span class="mlearn">習得: ' + esc(s.learn) + '</span>';
        b.addEventListener('click', function () {
          $('mapOverlay').classList.add('hidden');
          loadStage(i);
        });
        list.appendChild(b);
      });
      const b = document.createElement('button');
      b.innerHTML = '<span class="mch">FREE</span>サンドボックス<span class="mlearn">全コマンド開放</span>';
      b.addEventListener('click', function () {
        $('mapOverlay').classList.add('hidden');
        startSandbox();
      });
      list.appendChild(b);
      $('mapOverlay').classList.remove('hidden');
    });
    $('btnMapClose').addEventListener('click', function () { $('mapOverlay').classList.add('hidden'); });

    let saved = 0, savedT = 0;
    try {
      saved = parseInt(localStorage.getItem('cs_stage') || '0', 10) || 0;
      savedT = parseInt(localStorage.getItem('cs_treasure') || '0', 10) || 0;
    } catch (e) { /* noop */ }
    G.treasures = savedT;
    $('treasureCount').textContent = G.treasures;
    loadStage(Math.min(saved, STAGES.length - 1));
  }

  document.addEventListener('DOMContentLoaded', boot);
})();
