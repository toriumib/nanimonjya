# -*- coding: utf-8 -*-
"""🔊 効果音をコードで合成して書き出す。

■ なぜ合成するのか
配布素材を拾ってくると、出所とライセンスを管理し続けることになる。
アイコン（`gen_launcher_icon.py`）と同じで、**コードから作れば
出所が明確**で、あとから微調整もできる。

■ 気持ちよく鳴らすための要点（どれも実際に効く）

1. **立ち上がりを速く、減衰を長く。** 減衰が短いと「プツ」と鳴って安っぽい
2. **倍音を混ぜる。** 正弦波だけだと電子音になる。
   2倍・3倍を弱く足すと楽器っぽくなる
3. **音を重ねる。** 単音より和音。ゲットや勝利は上行のアルペジオにする
4. **最後を必ずフェードする。** 波形が途中で切れると「バツッ」と鳴る
5. **音量をそろえる。** 効果音ごとにピークが違うと、うるさい音だけ目立つ

■ 使いかた
  pip install numpy
  python tools/gen_sfx.py            # 既定の案を書き出す
  python tools/gen_sfx.py --variants # 案を3つずつ tools/sfx_preview/ に出す

⚠️ **音は聴いて選ぶしかない。** `--variants` で候補を出して、
   気に入ったものを `assets/audio/` へコピーする。
"""

import argparse
import os
import wave

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, 'assets', 'audio')
PREVIEW = os.path.join(HERE, 'sfx_preview')

RATE = 44100

# 音名 → 周波数。ドレミで書けるようにしておくと、あとで直しやすい。
def note(name: str) -> float:
    names = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11}
    step = names[name[0]]
    if len(name) > 2 and name[1] == '#':
        step += 1
        octave = int(name[2])
    else:
        octave = int(name[1])
    # A4 = 440Hz
    return 440.0 * (2 ** ((step - 9) / 12 + (octave - 4)))


def tone(freq, dur, *, harmonics=(1.0, 0.35, 0.14), attack=0.004, decay=None,
         wobble=0.0):
    """1音つくる。[harmonics] は倍音の強さ（1倍・2倍・3倍…）。"""
    n = int(dur * RATE)
    t = np.arange(n) / RATE
    wave_ = np.zeros(n)
    for i, amp in enumerate(harmonics, start=1):
        f = freq * i
        if wobble:
            # ほんの少し揺らすと、機械っぽさが減る
            f = f * (1 + wobble * np.sin(2 * np.pi * 5.5 * t))
        wave_ += amp * np.sin(2 * np.pi * f * t)
    wave_ /= sum(harmonics)

    # 立ち上がりは速く、減衰は長く
    env = np.ones(n)
    a = max(1, int(attack * RATE))
    env[:a] = np.linspace(0, 1, a)
    d = decay if decay is not None else dur
    env *= np.exp(-np.arange(n) / (d * RATE / 3.2))
    return wave_ * env


def sparkle(dur, *, seed=0, density=26, low=1800, high=5200):
    """きらめき。高い音をぱらぱら重ねる。"""
    rng = np.random.default_rng(seed)
    n = int(dur * RATE)
    out = np.zeros(n)
    for _ in range(density):
        f = rng.uniform(low, high)
        start = int(rng.uniform(0, dur * 0.55) * RATE)
        length = int(rng.uniform(0.04, 0.11) * RATE)
        end = min(n, start + length)
        # ⚠️ 長さは秒ではなくサンプル数で合わせる。秒から作り直すと
        #    丸め誤差で1サンプルずれて、代入で落ちる。
        seg = tone(f, (end - start) / RATE, harmonics=(1.0,), decay=0.06)
        k = min(len(seg), end - start)
        out[start:start + k] += seg[:k] * 0.16
    return out


def mix(*parts):
    """長さの違う波を重ねる。"""
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[:len(p)] += p
    return out


def place(total_dur, items):
    """(開始秒, 波) を並べる。"""
    n = int(total_dur * RATE)
    out = np.zeros(n)
    for start, w in items:
        i = int(start * RATE)
        end = min(n, i + len(w))
        out[i:end] += w[:end - i]
    return out


def finish(x, peak=0.82):
    """音量をそろえて、終わりをフェードする。

    ⚠️ **最後のフェードを省かない。** 波形が途中で切れると
       「バツッ」というクリック音が乗る。
    """
    m = float(np.abs(x).max())
    if m > 0:
        x = x / m * peak
    fade = min(len(x), int(0.02 * RATE))
    x[-fade:] *= np.linspace(1, 0, fade)
    return x


def save(path, x):
    pcm = (np.clip(x, -1, 1) * 32767).astype('<i2')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(pcm.tobytes())
    return os.path.getsize(path)


# ── 効果音の中身 ─────────────────────────────────

def sfx_get(variant=0):
    """🎴 カードを取った。上行の3音＋きらめき。"""
    seqs = [
        ['C5', 'E5', 'G5'],       # 明るい長三和音
        ['E5', 'G5', 'C6'],       # もう少し高くて派手
        ['C5', 'G5', 'C6'],       # 抜けがよい
    ]
    seq = seqs[variant % len(seqs)]
    gap = 0.055
    return finish(mix(
        place(0.62, [(i * gap, tone(note(nm), 0.42, decay=0.30))
                     for i, nm in enumerate(seq)]),
        sparkle(0.62, seed=variant) * 0.7,
    ))


def sfx_correct(variant=0):
    """⭕ 正解。短く、上がる2音。"""
    pairs = [('E5', 'A5'), ('G5', 'C6'), ('C5', 'G5')]
    a, b = pairs[variant % len(pairs)]
    return finish(place(0.34, [
        (0.0, tone(note(a), 0.20, decay=0.14)),
        (0.075, tone(note(b), 0.26, decay=0.20)),
    ]), peak=0.7)


def sfx_victory(variant=0):
    """🏆 勝利。和音＋上行＋きらめき。1.2秒。"""
    chords = [
        ['C5', 'E5', 'G5', 'C6'],
        ['F4', 'A4', 'C5', 'F5'],
        ['G4', 'B4', 'D5', 'G5'],
    ]
    ch = chords[variant % len(chords)]
    items = [(i * 0.075, tone(note(nm), 1.05, decay=0.75))
             for i, nm in enumerate(ch)]
    # 締めのオクターブ上
    items.append((0.34, tone(note(ch[-1]) * 2, 0.85, decay=0.6) * 0.5))
    return finish(mix(
        place(1.25, items),
        sparkle(1.25, seed=10 + variant, density=40) * 0.9,
    ))


def sfx_fanfare(variant=0):
    """📣 ファンファーレ。4音の上行。"""
    seqs = [
        ['G4', 'C5', 'E5', 'G5'],
        ['C5', 'F5', 'A5', 'C6'],
        ['E5', 'G5', 'C6', 'E6'],
    ]
    seq = seqs[variant % len(seqs)]
    return finish(place(0.95, [
        (i * 0.11, tone(note(nm), 0.55, decay=0.38, wobble=0.002))
        for i, nm in enumerate(seq)
    ]))


BUILDERS = {
    'get': sfx_get,
    'correct': sfx_correct,
    'victory': sfx_victory,
    'fanfare': sfx_fanfare,
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--variants', action='store_true',
                    help='案を3つずつ tools/sfx_preview/ に書き出す')
    ap.add_argument('--pick', default='',
                    help='例: get=1,victory=2 のように案を指定して本番へ')
    args = ap.parse_args()

    if args.variants:
        os.makedirs(PREVIEW, exist_ok=True)
        for name, fn in BUILDERS.items():
            for v in range(3):
                p = os.path.join(PREVIEW, f'{name}_{v}.wav')
                print(f'{save(p, fn(v)):>8,} B  {p}')
        print('\n聴いてから --pick で選んでください。'
              ' 例: python tools/gen_sfx.py --pick get=1,victory=2')
        return

    picks = {}
    for kv in filter(None, args.pick.split(',')):
        k, v = kv.split('=')
        picks[k.strip()] = int(v)

    for name, fn in BUILDERS.items():
        v = picks.get(name, 0)
        p = os.path.join(OUT, f'{name}.wav')
        print(f'{save(p, fn(v)):>8,} B  {name}.wav（案{v}）')


if __name__ == '__main__':
    main()
