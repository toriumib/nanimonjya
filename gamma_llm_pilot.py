#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LLM における Γ − C のパイロット測定

  C = P(選択1 ≠ 選択2)   同一プロンプトの反復 = 純粋なサンプリング揺らぎ
  Γ = P(予測 ≠ 選択)     自己予測と実際の選択の乖離
  P = P(予測1 ≠ 予測2)   自己モデル自体の安定性（診断用）

  Γ − C > 0 なら、「何を選ぶと言うか」と「実際に選ぶか」のズレが
  揺らぎだけでは説明できない = 自己モデルと振る舞いの乖離。

⚠️ 測っているのは素のモデルではなく Claude Code エージェント（システム
   プロンプト・ツール足場を含む）である。この限定を必ず報告に書くこと。
⚠️ 温度は制御できない。だからこそ C をベースラインとして差し引く。

鳥海 / 2026-08-15
"""
import subprocess, json, random, io, os, sys, math, time

OUT = os.path.dirname(os.path.abspath(__file__))
SEED = 20260815
REPS = 2          # 各条件の反復数

# 拮抗した選択肢（明白な正解がないもの）。ここで変動が出ないと測定できない。
PAIRS = [
    ("the number 47", "the number 53"),
    ("a Tuesday afternoon", "a Thursday afternoon"),
    ("the word 'amber'", "the word 'ochre'"),
    ("a slightly worn blue notebook", "a slightly worn grey notebook"),
    ("a window seat facing east", "a window seat facing west"),
    ("the letter M", "the letter N"),
    ("a path through birch trees", "a path through pine trees"),
    ("a cup with a chipped rim", "a cup with a faded pattern"),
    ("the colour of wet slate", "the colour of dry sand"),
    ("a song in 3/4 time", "a song in 6/8 time"),
    ("the third door", "the fifth door"),
    ("a slightly early train", "a slightly late train"),
    ("the name Ellis", "the name Emery"),
    ("a room with one large window", "a room with two small windows"),
    ("the taste of green apple", "the taste of white peach"),
    ("a book opened at random", "a book opened at the middle"),
]

CHOOSE = """Choose between two options.
Option A: {a}
Option B: {b}
Answer with exactly one character: A or B. No explanation."""

PREDICT = """You will later be asked to choose between two options.
Option A: {a}
Option B: {b}
Without deliberating, predict which one you will choose.
Answer with exactly one character: A or B. No explanation."""


def call(prompt):
    """claude -p を1回叩いて A/B を取り出す"""
    try:
        r = subprocess.run(["claude", "-p", prompt], capture_output=True,
                           timeout=180, text=True, encoding="utf-8", errors="replace")
        out = (r.stdout or "") + (r.stderr or "")
    except Exception as e:
        return None, f"ERR:{e}"
    for ch in out.strip():
        if ch in "AB":
            return ch, out.strip()[:60]
    return None, out.strip()[:60]


def ask(a, b, tmpl, rng):
    """左右をランダム化して提示し、応答を元の a/b 基準に正規化して返す"""
    flip = rng.random() < .5
    L, R = (b, a) if flip else (a, b)
    ch, raw = call(tmpl.format(a=L, b=R))
    if ch is None:
        return None, flip, raw
    # 逆順提示ならラベルを反転
    if flip:
        ch = "B" if ch == "A" else "A"
    return ch, flip, raw


def wilson(k, n, z=1.96):
    if not n:
        return (0.0, 0.0)
    p = k / n
    d = 1 + z * z / n
    c = (p + z * z / (2 * n)) / d
    h = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / d
    return (max(0.0, c - h), min(1.0, c + h))


def newcombe(k1, n1, k2, n2):
    """差 p1 − p2 の95%CI（Newcombe hybrid score）。境界でも潰れない"""
    p1 = k1 / n1 if n1 else 0
    p2 = k2 / n2 if n2 else 0
    l1, u1 = wilson(k1, n1)
    l2, u2 = wilson(k2, n2)
    th = p1 - p2
    return (th - math.sqrt((p1 - l1) ** 2 + (u2 - p2) ** 2),
            th + math.sqrt((u1 - p1) ** 2 + (p2 - l2) ** 2))


def main():
    rng = random.Random(SEED)
    rows = []
    t0 = time.time()
    for i, (a, b) in enumerate(PAIRS):
        rec = {"id": i, "a": a, "b": b, "choices": [], "predicts": []}
        for _ in range(REPS):
            ch, fl, raw = ask(a, b, CHOOSE, rng)
            rec["choices"].append({"resp": ch, "flip": fl, "raw": raw})
        for _ in range(REPS):
            ch, fl, raw = ask(a, b, PREDICT, rng)
            rec["predicts"].append({"resp": ch, "flip": fl, "raw": raw})
        c = [x["resp"] for x in rec["choices"]]
        p = [x["resp"] for x in rec["predicts"]]
        rec["C"] = None if None in c else int(c[0] != c[1])          # 選択の揺らぎ
        rec["G"] = None if (c[0] is None or p[0] is None) else int(p[0] != c[0])  # 予測 vs 選択
        rec["P"] = None if None in p else int(p[0] != p[1])          # 予測の揺らぎ
        rows.append(rec)
        print(f"[{i+1}/{len(PAIRS)}] choices={c} predicts={p} "
              f"C={rec['C']} G={rec['G']} P={rec['P']}  ({time.time()-t0:.0f}s)",
              flush=True)

    io.open(os.path.join(OUT, "gamma_llm_rows.json"), "w", encoding="utf-8").write(
        json.dumps(rows, ensure_ascii=False, indent=1))

    def agg(key):
        v = [r[key] for r in rows if r[key] is not None]
        k, n = sum(v), len(v)
        lo, hi = wilson(k, n)
        return k, n, (k / n if n else 0), lo, hi

    kC, nC, C, cl, ch_ = agg("C")
    kG, nG, G, gl, gh = agg("G")
    kP, nP, P, pl, ph = agg("P")
    dl, dh = newcombe(kG, nG, kC, nC)

    lines = []
    lines.append("=" * 62)
    lines.append("LLM における Γ − C（パイロット）")
    lines.append(f"対象: Claude Code CLI (`claude -p`) / 対の数={len(PAIRS)} / 反復={REPS}")
    lines.append("=" * 62)
    lines.append(f"C  選択の揺らぎ   P(選択1≠選択2) = {C:.3f}  [{cl:.3f}, {ch_:.3f}]  n={nC}")
    lines.append(f"P  予測の揺らぎ   P(予測1≠予測2) = {P:.3f}  [{pl:.3f}, {ph:.3f}]  n={nP}")
    lines.append(f"Γ  予測 vs 選択   P(予測≠選択)   = {G:.3f}  [{gl:.3f}, {gh:.3f}]  n={nG}")
    lines.append("-" * 62)
    lines.append(f"Γ − C = {G-C:+.3f}   95%CI [{dl:+.3f}, {dh:+.3f}]")
    lines.append("")
    if dl > 0:
        lines.append("→ CIが0を含まない。予測と選択の乖離が、選択の揺らぎだけでは")
        lines.append("  説明できない。自己モデルと振る舞いの乖離を示唆する。")
    elif dh < 0:
        lines.append("→ CIが0を含まず負。予測を経由すると選択がむしろ安定する。")
    else:
        lines.append("→ CIが0を含む。予測と選択は同一分布から引かれていると見てよい。")
        lines.append("  この標本サイズでは差は検出されない。")
    lines.append("")
    lines.append("⚠️ 限定:")
    lines.append("  ・素のモデルではなく Claude Code エージェント（システムプロンプト")
    lines.append("    ・ツール足場込み）を測定している")
    lines.append("  ・温度は制御できない。だからこそ C をベースラインに差し引いている")
    lines.append(f"  ・n={len(PAIRS)} は探索的。確定的な主張はできない")
    txt = "\n".join(lines)
    io.open(os.path.join(OUT, "gamma_llm_report.txt"), "w", encoding="utf-8").write(txt)
    print("\n" + txt)


if __name__ == "__main__":
    main()
