# -*- coding: utf-8 -*-
"""🏆 勝利のときに流す曲を、短いループに切り出す。

■ なぜ切るのか
元ファイルは3〜8分・4〜11MBある。勝利画面で流すだけなので、
**いちばん聞かせたい20秒**だけを切って軽くする。
音声の総量は一度38MB→20MBまで削ってあるので、ここで戻さない。

■ ⚠️ 切り出す位置は耳で決めるしかない
下の [TRACKS] の `start` を直して回し直す。
私（開発者以外）は音を聴けないので、**ずれていたら直してほしい**。

■ 出所とライセンス（**必ず埋めること**）
`credit` に演奏者と出所を書く。空のまま本番へ出さない。
楽曲そのものが著作権切れでも、**録音には別の権利がある**。

■ 使いかた
  pip install numpy soundfile lameenc
  python tools/make_victory_bgm.py

  元ファイルは tools/.victory_src/ に置く（gitignore 済み）。
"""

import os
import sys

import lameenc
import numpy as np
import soundfile as sf

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SRC_DIR = os.path.join(HERE, '.victory_src')
OUT_DIR = os.path.join(ROOT, 'assets', 'audio')

LENGTH = 20.0  # 切り出す秒数
FADE_IN = 0.08
FADE_OUT = 2.5
BITRATE = 96

# (元ファイル名, 出力名, 開始秒, クレジット)
#
# ⚠️ start は耳で合わせる値。いまは「たぶんここ」で置いてある。
TRACKS = [
    ('Pomp_and_Circumstance,_Op._39_-_No._1_-_United_States_Army_Band.mp3',
     'victory_pomp.mp3', 110.0,
     'Elgar / United States Army Band（米国政府作成物・パブリックドメイン）'),
    ('Beethoven-Symphony-No5-1st-2019-AR2.mp3',
     'victory_beethoven.mp3', 0.0,
     '⚠️ 録音の出所が未確認'),
    ('gunkan1.mp3',
     'victory_gunkan.mp3', 0.0,
     '⚠️ 録音の出所が未確認'),
    ('March_of_the_Volunteers_instrumental.ogg',
     'victory_march.mp3', 0.0,
     '⚠️ 中華人民共和国の国歌。録音の出所が未確認'),
]


def build(src, out, start, length=LENGTH):
    data, rate = sf.read(src, dtype='float32', always_2d=True)
    i = int(start * rate)
    clip = data[i:i + int(length * rate)].copy()
    if len(clip) == 0:
        raise SystemExit(f'切り出せない（start が長すぎる）: {src}')

    n_in = min(len(clip), int(FADE_IN * rate))
    n_out = min(len(clip), int(FADE_OUT * rate))
    clip[:n_in] *= np.linspace(0, 1, n_in)[:, None]
    clip[-n_out:] *= np.linspace(1, 0, n_out)[:, None]

    peak = float(np.abs(clip).max())
    if peak > 0:
        clip *= (10 ** (-3 / 20)) / peak  # -3dBFS にそろえる

    target = 44100
    if rate != target:
        idx = np.linspace(0, len(clip) - 1, int(len(clip) * target / rate))
        clip = np.stack(
            [np.interp(idx, np.arange(len(clip)), clip[:, c])
             for c in range(clip.shape[1])], axis=1).astype(np.float32)
        rate = target

    pcm = (np.clip(clip, -1, 1) * 32767).astype(np.int16)
    enc = lameenc.Encoder()
    enc.set_bit_rate(BITRATE)
    enc.set_in_sample_rate(rate)
    enc.set_channels(pcm.shape[1])
    enc.set_quality(2)
    mp3 = enc.encode(pcm.tobytes()) + enc.flush()
    with open(out, 'wb') as f:
        f.write(mp3)
    return len(mp3)


def main():
    # ⚠️ 日本語Windowsの端末は cp932。絵文字を print すると落ちる。
    try:
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    except Exception:
        pass
    if not os.path.isdir(SRC_DIR):
        raise SystemExit(f'元ファイルを置く場所がない: {SRC_DIR}')
    total = 0
    for name, out, start, credit in TRACKS:
        src = os.path.join(SRC_DIR, name)
        if not os.path.exists(src):
            print(f'  飛ばす（元ファイル無し）: {name}')
            continue
        size = build(src, os.path.join(OUT_DIR, out), start)
        total += size
        print(f'  {out:<24} {size / 1024:6.0f} KB  ({start:.0f}s〜)  {credit}')
    print(f'\n合計 {total / 1048576:.2f} MB')


if __name__ == '__main__':
    main()
