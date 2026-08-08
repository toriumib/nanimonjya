# -*- coding: utf-8 -*-
"""📊 GA4 / AdMob のエクスポートを読んで、毎週見る数字だけを出す。

■ なぜ作ったか
レポートを読むたびに、CSVを開いて電卓を叩いて表を作り直していた。
**毎回おなじ計算をしている**ので、そこだけ機械にやらせる。
人がやるのは「数字を見て何を直すか決める」ところだけでよい。

■ 使いかた

  1. GA4 と AdMob からCSVをエクスポートして、1つのフォルダに入れる
  2. python tools/analyze_reports.py <フォルダ>
  3. 前回の実行結果との差が出る

  例: python tools/analyze_reports.py ~/Downloads

■ 読み込むファイル（名前で判別する。日本語名のままでよい）

  - イベント名を含むCSV        … イベント数・ユーザー数
  - Firebase の概要 を含むCSV  … 維持率・バージョン・国
  - admob を含むCSV            … 収益（⚠️ UTF-16タブ区切り）

⚠️ **見つからないファイルは黙って飛ばす。**
   エクスポートの粒度は毎回変わるので、全部そろっている前提にしない。

■ 履歴
実行のたびに `tools/.report_history.json` に追記する。
次に走らせたとき、前回からの増減を出すために使う。
このファイルは生データではなく集計後の数字だけなので、コミットしてよい。
"""

import csv
import io
import json
import os
import sys
from datetime import datetime

HERE = os.path.dirname(os.path.abspath(__file__))
HISTORY = os.path.join(HERE, '.report_history.json')

# 目標値。ANALYTICS_REVIEW.md の 4.4 と合わせる。
# ⚠️ ここを直したら、あちらの表も直すこと。
TARGETS = {
    'first_open_to_game': (0.70, '初回起動 → 初回ゲーム開始'),
    'game_completion': (0.60, 'ゲーム完走率'),
    'tab_reach': (0.40, 'タブ到達率'),
    'rewarded_show_rate': (0.10, 'リワード表示率'),
    'exceptions_per_user': (1.0, 'app_exception / ユーザー（低いほどよい）'),
}
# 小さいほどよい指標
LOWER_IS_BETTER = {'exceptions_per_user'}


def _read_text(path):
    """UTF-8 でも UTF-16 でも読む。AdMob のCSVは UTF-16 タブ区切り。"""
    raw = open(path, 'rb').read()
    for enc in ('utf-8-sig', 'utf-16', 'cp932'):
        try:
            return raw.decode(enc)
        except UnicodeDecodeError:
            continue
    return raw.decode('utf-8', errors='replace')


def _rows(text, delim=','):
    """`#` で始まる注記行を落として、表の行だけ返す。"""
    out = []
    for r in csv.reader(io.StringIO(text), delimiter=delim):
        if not r or (r[0].startswith('#')):
            continue
        out.append(r)
    return out


def parse_events(path):
    """イベント名,イベント数,総ユーザー数… の表を {name: (count, users)} に。"""
    events = {}
    for r in _rows(_read_text(path)):
        if len(r) < 3 or r[0] in ('イベント名', 'Event name'):
            continue
        try:
            events[r[0]] = (int(float(r[1])), int(float(r[2])))
        except ValueError:
            continue
    return events


def parse_admob(path):
    """AdMob のレポートを {フォーマット: {...}} に。

    ⚠️ 列名は日本語で、環境によって化ける。**位置で読む。**
    広告ユニット / フォーマット / 収益 / eCPM / リクエスト / マッチ率 /
    一致したリクエスト / 表示率 / 表示回数 …
    """
    out = {}
    rows = _rows(_read_text(path), delim='\t')
    if not rows:
        return out
    for r in rows[1:]:
        if len(r) < 9 or not r[1].strip():
            continue
        def num(i):
            try:
                return float(r[i].replace('%', '').replace(',', '').strip())
            except (ValueError, IndexError):
                return 0.0
        out[r[1].strip()] = {
            'revenue': num(2),
            'requests': num(4),
            'shown': num(8),
            'show_rate': num(7) / 100 if num(7) else 0.0,
        }
    return out


def find(folder, *needles):
    """名前に [needles] のどれかを含むファイルを新しい順に返す。"""
    hits = []
    for f in os.listdir(folder):
        low = f.lower()
        if not low.endswith('.csv'):
            continue
        if any(n.lower() in low for n in needles):
            hits.append(os.path.join(folder, f))
    return sorted(hits, key=os.path.getmtime, reverse=True)


def build(folder):
    m = {}

    ev_files = find(folder, 'イベント名', 'events')
    if ev_files:
        ev = parse_events(ev_files[0])
        m['_events'] = ev

        def users(name):
            return ev.get(name, (0, 0))[1]

        def count(name):
            return ev.get(name, (0, 0))[0]

        first = users('first_open')
        m['first_open_users'] = first
        m['game_start_users'] = users('game_start')
        m['tab_users'] = users('feature_open')
        if first:
            m['first_open_to_game'] = users('game_start') / first
            m['tab_reach'] = users('feature_open') / first
            m['uninstall_rate'] = users('app_remove') / first
        if count('game_start'):
            m['game_completion'] = count('game_end') / count('game_start')
        if users('app_exception'):
            m['exceptions_per_user'] = \
                count('app_exception') / users('app_exception')
        # 新しく入れたイベントが届いているか
        m['_new_events'] = {
            k: ev.get(k, (0, 0))
            for k in ('ad_load_requested', 'ad_shown', 'ad_skipped',
                      'face_memo_open', 'face_memo_added', 'avatar_editor_done',
                      'read_open', 'read_page', 'recall_start',
                      'spaced_review_done', 'first_game_started', 'mode_pick')
        }

    ad_files = [f for f in os.listdir(folder) if 'admob' in f.lower()]
    if ad_files:
        ad = parse_admob(os.path.join(folder, sorted(ad_files)[0]))
        m['_admob'] = ad
        m['ad_revenue'] = round(sum(v['revenue'] for v in ad.values()), 2)
        for name, v in ad.items():
            if v['requests'] and ('リワード' in name or 'ewarded' in name) \
                    and 'インタース' not in name and 'nterstitial' not in name:
                m['rewarded_show_rate'] = v['shown'] / v['requests']
    return m


def pct(x):
    return f'{x * 100:.1f}%'


def main():
    # ⚠️ 日本語Windowsの端末は cp932 なので、絵文字を print すると落ちる。
    #    出力を UTF-8 に固定する。
    try:
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    except Exception:
        pass
    folder = sys.argv[1] if len(sys.argv) > 1 else \
        os.path.join(os.path.expanduser('~'), 'Downloads')
    if not os.path.isdir(folder):
        raise SystemExit(f'フォルダが無い: {folder}')

    m = build(folder)
    if not m:
        raise SystemExit(f'読めるCSVが無かった: {folder}')

    hist = []
    if os.path.exists(HISTORY):
        try:
            hist = json.load(open(HISTORY, encoding='utf-8'))
        except Exception:
            hist = []
    prev = hist[-1] if hist else {}

    print(f'\n=== {datetime.now():%Y-%m-%d} / {folder} ===\n')

    print('■ 毎週見る数字')
    for key, (target, label) in TARGETS.items():
        cur = m.get(key)
        if cur is None:
            print(f'  {label:<34} —（データなし）')
            continue
        shown = f'{cur:.1f}' if key in LOWER_IS_BETTER else pct(cur)
        goal = f'{target:.1f}' if key in LOWER_IS_BETTER else pct(target)
        ok = cur <= target if key in LOWER_IS_BETTER else cur >= target
        mark = '✅' if ok else '⚠️'
        delta = ''
        if key in prev and prev[key] is not None:
            d = cur - prev[key]
            if abs(d) > 1e-9:
                arrow = '↑' if d > 0 else '↓'
                delta = (f'  （前回比 {arrow}{abs(d):.1f}）'
                         if key in LOWER_IS_BETTER
                         else f'  （前回比 {arrow}{pct(abs(d))}）')
        print(f'  {mark} {label:<32} {shown:>7}  目標 {goal}{delta}')

    if 'ad_revenue' in m:
        print(f'\n■ 広告収益  ${m["ad_revenue"]}')
        for name, v in m.get('_admob', {}).items():
            per = v['revenue'] / v['shown'] if v['shown'] else 0
            print(f'    {name:<24} ${v["revenue"]:>6.2f}  '
                  f'{int(v["requests"]):>5}ロード → {int(v["shown"]):>5}表示  '
                  f'1表示 ${per:.4f}')

    new = m.get('_new_events', {})
    if new:
        print('\n■ 新しく入れたイベントが届いているか')
        for k, (c, u) in new.items():
            mark = '✅' if c else '—'
            print(f'    {mark} {k:<22} {c:>5}件 / {u:>4}人')

    # 履歴に追記（生データは残さない）
    snap = {k: v for k, v in m.items() if not k.startswith('_')}
    snap['date'] = datetime.now().strftime('%Y-%m-%d')
    hist.append(snap)
    json.dump(hist, open(HISTORY, 'w', encoding='utf-8'),
              ensure_ascii=False, indent=1)
    print(f'\n履歴を書いた: {HISTORY}（{len(hist)}件目）\n')


if __name__ == '__main__':
    main()
