#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Gamma experiment — 自己予測ギャップ Γ が価値差 ΔV の関数かを検定する

三つの被験系を同一の刺激で比較する:
  ARM-H  hash  : 価値関数を持たない決定論的自己参照エージェント（対照群）
  ARM-L  llm   : 大規模言語モデル（思考連鎖を σ とする）
  ARM-P  human : 人間（別途 Web 実験）

中心的予測:
  価値関数を持つ系でのみ Γ は ΔV の減少関数になる。
  ハッシュ群では Γ は ΔV に依存しない（平坦）。

使い方:
  python gamma_experiment.py hash                 # 対照群（APIキー不要）
  python gamma_experiment.py llm --key sk-...     # LLM群
  python gamma_experiment.py analyze              # 解析と作図

鳥海 2026-08-15
"""

import hashlib, json, io, os, sys, argparse, random, math
from collections import defaultdict

OUT_DIR = os.path.dirname(os.path.abspath(__file__))


# ══════════════════════════════════════════════════════════════════
# 刺激: ΔV 全域にわたる二肢対
# ══════════════════════════════════════════════════════════════════

def build_stimuli(n_pairs=300, seed=20260815):
    """
    各対に外的に割り当てた主観価値 V(a), V(b) を持たせる。
    ΔV = |V(a) - V(b)| が 0〜100 の全域に分布するよう構成する。

    重要: ハッシュ群にとって V は「見えない」。V は解析側の変数であり、
    エージェントの入力ではない。ゆえにハッシュ群で Γ が ΔV に依存したら、
    それは実装の誤りか偶然である。
    """
    rng = random.Random(seed)
    stim = []
    for i in range(n_pairs):
        va = rng.uniform(0, 100)
        # ΔV を一様に散らす
        target_d = rng.uniform(0, 60)
        vb = va - target_d if rng.random() < .5 else va + target_d
        vb = max(0.0, min(100.0, vb))
        stim.append({
            "id": i,
            "a": f"option_A_{i}",
            "b": f"option_B_{i}",
            "Va": round(va, 2),
            "Vb": round(vb, 2),
            "dV": round(abs(va - vb), 2),
        })
    return stim


# ══════════════════════════════════════════════════════════════════
# ARM-H: ハッシュエージェント（対照群）
# ══════════════════════════════════════════════════════════════════

class HashAgent:
    """
    鳥海構成 (v18 §5.1) の忠実な実装。
    f_0(L,O) = O[ H(L ‖ O) mod |O| ]
    f_m(L,O) = O[ H(L ‖ trace(f_{m-1}) ‖ O) mod |O| ]

    乱数を一切使わない。価値関数を持たない。
    """

    def __init__(self):
        self.log = []                      # 追記専用ログ L

    def _h(self, payload):
        return int(hashlib.sha256(payload.encode("utf-8")).hexdigest(), 16)

    def _simulate(self, options, depth, max_depth):
        """自己シミュレーション σ。ログに痕跡を書く。"""
        if depth >= max_depth:
            return
        self.log.append(f"sim_enter:d{depth}")
        self._simulate(options, depth + 1, max_depth)
        self.log.append(f"sim_exit:d{depth}")

    def choose(self, options, k):
        self.log.append("trial_start")
        snapshot = list(self.log)          # σ を走らせる前の状態
        self._simulate(options, 0, k)      # k>0 ならログが伸びる
        okey = "|".join(options)

        prediction = options[self._h("".join(snapshot) + okey) % len(options)]
        choice     = options[self._h("".join(self.log) + okey) % len(options)]

        self.log.append(f"commit:{choice}")
        return prediction, choice


def run_hash(stim, k_values=(0, 1, 2, 5), reps=1):
    rows = []
    for k in k_values:
        agent = HashAgent()                # k ごとに新しいエージェント
        for _ in range(reps):
            for s in stim:
                opts = [s["a"], s["b"]]
                pred, cho = agent.choose(opts, k)
                rows.append({
                    "arm": "hash", "k": k, "id": s["id"], "dV": s["dV"],
                    "prediction": pred, "choice": cho,
                    "gap": int(pred != cho),
                })
    return rows


# ══════════════════════════════════════════════════════════════════
# ARM-L: LLM（思考連鎖を σ とする）
# ══════════════════════════════════════════════════════════════════

PROMPT_PREDICT = """You will later be asked to choose between two options.

Option A: {a}
Option B: {b}

Right now, without deliberating, predict which one you will choose.
Answer with exactly one character: A or B."""

PROMPT_CHOOSE_K0 = """Choose between two options.

Option A: {a}
Option B: {b}

Answer with exactly one character: A or B."""

PROMPT_CHOOSE_K1 = """Choose between two options.

Option A: {a}
Option B: {b}

First reason step by step about which you prefer and why.
Then on the final line write exactly: ANSWER: A   or   ANSWER: B"""


def call_anthropic(api_key, model, prompt, max_tokens=1024):
    """温度0固定。ここを 0 以外にすると Γ ではなく標本抽出を測ることになる。"""
    import requests
    r = requests.post(
        "https://api.anthropic.com/v1/messages",
        headers={
            "x-api-key": api_key,
            "anthropic-version": "2023-06-01",
            "content-type": "application/json",
        },
        json={
            "model": model,
            "max_tokens": max_tokens,
            "temperature": 0,                     # ★ 必須
            "messages": [{"role": "user", "content": prompt}],
        },
        timeout=120,
    )
    r.raise_for_status()
    d = r.json()
    return "".join(b.get("text", "") for b in d.get("content", []))


def parse_ab(text):
    t = text.strip()
    if "ANSWER:" in t:
        t = t.split("ANSWER:")[-1].strip()
    for ch in t:
        if ch in "AB":
            return ch
    return None


def run_llm(stim, api_key, model, k_values=(0, 1), limit=None):
    """
    ⚠️ 設計上の要点

      1. 温度0固定。温度>0の不一致は乱数であり Γ ではない。
         ★ 2026-08-15 実測: Claude Code CLI (`claude -p`) は温度0ではない。
           拮抗した選択肢（"the number 47" vs "53"）で同一プロンプト3回が
           B,A,B と揺れた。ゆえに CLI 経由では本実験は実施できない。
           API を temperature=0 で直接叩くこと。

      2. 予測と選択は完全に別の呼び出し。文脈を持ち越さない
         （持ち越すと自己参照ではなく単なる記憶参照になる）

      3. k=0 は即答、k=1 は思考連鎖つき。σ = 思考連鎖トレース

      4. ★位置バイアスのカウンターバランス（必須）
         2026-08-15 実測: 左右を入れ替えても常に B を選ぶ項目があった
         （"a Tuesday afternoon" vs "a Thursday afternoon"）。
         内容ではなく位置で選んでいる。各対を正順・逆順の両方で提示し、
         逆順では応答ラベルを反転して集計する。
    """
    rows = []
    use = stim[:limit] if limit else stim
    for s in use:
        for order in ("fwd", "rev"):
            a, b = (s["a"], s["b"]) if order == "fwd" else (s["b"], s["a"])

            def norm(ch):
                """逆順提示ではラベルを反転し、常に元の a/b 基準に揃える"""
                if ch is None:
                    return None
                if order == "fwd":
                    return ch
                return "B" if ch == "A" else "A"

            # 予測 f^(0): 熟慮なしの自己予測
            pred = norm(parse_ab(call_anthropic(
                api_key, model,
                PROMPT_PREDICT.format(a=a, b=b), max_tokens=8)))

            for k in k_values:
                tpl = PROMPT_CHOOSE_K0 if k == 0 else PROMPT_CHOOSE_K1
                mt = 8 if k == 0 else 1024
                cho = norm(parse_ab(call_anthropic(
                    api_key, model, tpl.format(a=a, b=b), max_tokens=mt)))
                if pred is None or cho is None:
                    continue
                rows.append({
                    "arm": "llm", "model": model, "k": k, "id": s["id"],
                    "order": order, "dV": s["dV"],
                    "prediction": pred, "choice": cho,
                    "gap": int(pred != cho),
                })
            print(f"  [{s['id']}/{order}] pred={pred}", flush=True)
    return rows


def position_bias(rows):
    """
    位置バイアスの診断。
    正順と逆順で「同じ内容」を選んでいるか（内容一貫）、
    それとも「同じ位置」を選んでいるか（位置バイアス）を見る。

    ラベル正規化後、fwd と rev の選択が一致 → 内容一貫
                    不一致                 → 位置バイアス
    """
    byid = defaultdict(dict)
    for r in rows:
        if r.get("order"):
            byid[(r["id"], r["k"])][r["order"]] = r["choice"]
    agree = tot = 0
    for _, d in byid.items():
        if "fwd" in d and "rev" in d:
            tot += 1
            agree += int(d["fwd"] == d["rev"])
    if not tot:
        return None
    lo, hi = wilson(agree, tot)
    return {"n": tot, "content_consistent": agree / tot, "ci": (lo, hi)}


# ══════════════════════════════════════════════════════════════════
# 解析
# ══════════════════════════════════════════════════════════════════

def wilson(k, n, z=1.96):
    """Wilson 信頼区間。比率の CI は必ずこれで出す（正規近似は端で壊れる）"""
    if n == 0:
        return (0.0, 0.0)
    p = k / n
    d = 1 + z * z / n
    c = (p + z * z / (2 * n)) / d
    h = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / d
    return (max(0.0, c - h), min(1.0, c + h))


def logistic_dV(rs):
    """
    gap ~ Bernoulli(logit^-1(b0 + b1 * dV)) を最尤推定する。
    b1 が ΔV 依存性の主要指標。

      b1 < 0 かつ CI が 0 を含まない → Γ は ΔV の減少関数（価値比較の署名）
      CI が 0 を含む                 → ΔV 依存性なし（ハッシュ群の予測）

    両端ビンの比較より、こちらを主解析とする。
    """
    import numpy as np
    from scipy import optimize, stats

    x = np.array([r["dV"] for r in rs], float)
    y = np.array([r["gap"] for r in rs], float)
    if len(set(y)) < 2:                       # 全部0 or 全部1
        return {"b1": 0.0, "ci": (float("nan"),) * 2, "p": float("nan"),
                "note": "gap に分散がないため推定不能（Γ=0 または Γ=1）"}

    X = np.column_stack([np.ones_like(x), x])

    def nll(b):
        z = X @ b
        # log(1+e^z) を安定に評価する（z が大きいときの overflow 回避）
        log1pexp = np.maximum(z, 0) + np.log1p(np.exp(-np.abs(z)))
        return -np.sum(y * z - log1pexp)

    res = optimize.minimize(nll, np.zeros(2), method="BFGS")
    b = res.x
    p = 1 / (1 + np.exp(-(X @ b)))
    W = p * (1 - p)
    try:
        cov = np.linalg.inv(X.T @ (X * W[:, None]))
        se = math.sqrt(cov[1, 1])
    except np.linalg.LinAlgError:
        return {"b1": b[1], "ci": (float("nan"),) * 2, "p": float("nan"),
                "note": "共分散行列が特異"}
    z = b[1] / se if se > 0 else 0.0
    return {
        "b1": float(b[1]),
        "ci": (float(b[1] - 1.96 * se), float(b[1] + 1.96 * se)),
        "p": float(2 * (1 - stats.norm.cdf(abs(z)))),
        "note": "",
    }


def analyze(rows, bins=6):
    out = []
    by_arm_k = defaultdict(list)
    for r in rows:
        by_arm_k[(r["arm"], r.get("model", "-"), r["k"])].append(r)

    for (arm, model, k), rs in sorted(by_arm_k.items()):
        n = len(rs)
        g = sum(x["gap"] for x in rs)
        lo, hi = wilson(g, n)
        out.append({
            "arm": arm, "model": model, "k": k, "n": n,
            "gamma": g / n if n else 0.0, "ci": (lo, hi),
            "logit": logistic_dV(rs),
            "bins": [],
        })
        # ΔV ビンごとの Γ
        mx = max((x["dV"] for x in rs), default=1) or 1
        w = mx / bins
        for b in range(bins):
            sel = [x for x in rs if b * w <= x["dV"] < (b + 1) * w
                   or (b == bins - 1 and x["dV"] == mx)]
            if not sel:
                continue
            bn, bg = len(sel), sum(x["gap"] for x in sel)
            blo, bhi = wilson(bg, bn)
            out[-1]["bins"].append({
                "range": (round(b * w, 1), round((b + 1) * w, 1)),
                "n": bn, "gamma": bg / bn, "ci": (blo, bhi),
            })
    return out


def report(res):
    lines = []
    for r in res:
        tag = f"{r['arm']}" + (f"/{r['model']}" if r["model"] != "-" else "")
        lines.append(f"\n{'='*66}")
        lines.append(f"ARM={tag}   k={r['k']}   n={r['n']}")
        lines.append(f"  Γ = {r['gamma']:.4f}   95%CI [{r['ci'][0]:.4f}, {r['ci'][1]:.4f}]")
        lines.append(f"  {'ΔV range':>14} | {'n':>4} | {'Γ':>7} | 95% CI")
        lines.append(f"  {'-'*14}-+------+---------+------------------")
        for b in r["bins"]:
            lines.append(
                f"  {str(b['range']):>14} | {b['n']:>4} | {b['gamma']:>7.4f} | "
                f"[{b['ci'][0]:.3f}, {b['ci'][1]:.3f}]")
        # 主解析: ロジスティック回帰の傾き
        L = r["logit"]
        if L.get("note"):
            lines.append(f"  [主解析] {L['note']}")
        else:
            sig = "0を含まない → ΔV依存あり" if (L["ci"][0] > 0) == (L["ci"][1] > 0) \
                  else "0を含む → ΔV依存なし"
            lines.append(
                f"  [主解析] logit傾き b1 = {L['b1']:+.5f}  "
                f"95%CI [{L['ci'][0]:+.5f}, {L['ci'][1]:+.5f}]  p={L['p']:.3f}")
            lines.append(f"           → {sig}")
            lines.append(f"           予測: 価値関数を持つ系では b1<0、ハッシュでは b1≈0")
    return "\n".join(lines)


# ══════════════════════════════════════════════════════════════════

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("mode", choices=["hash", "llm", "analyze"])
    ap.add_argument("--key", default=os.environ.get("ANTHROPIC_API_KEY"))
    ap.add_argument("--model", default="claude-sonnet-5")
    ap.add_argument("--pairs", type=int, default=300)
    ap.add_argument("--limit", type=int, default=None)
    a = ap.parse_args()

    stim = build_stimuli(a.pairs)

    if a.mode == "hash":
        rows = run_hash(stim)
        p = os.path.join(OUT_DIR, "gamma_rows_hash.json")
    elif a.mode == "llm":
        if not a.key:
            sys.exit("APIキーが要ります: --key sk-... または ANTHROPIC_API_KEY")
        rows = run_llm(stim, a.key, a.model, limit=a.limit)
        p = os.path.join(OUT_DIR, "gamma_rows_llm.json")
    else:
        rows = []
        for f in ("gamma_rows_hash.json", "gamma_rows_llm.json"):
            fp = os.path.join(OUT_DIR, f)
            if os.path.exists(fp):
                rows += json.load(io.open(fp, encoding="utf-8"))
        if not rows:
            sys.exit("データがありません。先に hash / llm を実行してください")
        print(report(analyze(rows)))
        return

    io.open(p, "w", encoding="utf-8").write(
        json.dumps(rows, ensure_ascii=False, indent=1))
    print(f"saved {len(rows)} rows -> {p}")
    print(report(analyze(rows)))


if __name__ == "__main__":
    main()
