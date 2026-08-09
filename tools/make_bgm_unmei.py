# -*- coding: utf-8 -*-
"""🎵 ベートーヴェン交響曲第5番「運命」第1楽章から、ホーム用のループを作る。

■ 出所とライセンス（**消さないこと**）
- 曲: Ludwig van Beethoven, Symphony No.5 in C minor, Op.67, 1st mov.
  作曲者の没後100年以上。**楽曲そのものはパブリックドメイン。**
- 録音: Skidmore College orchestra（Musopen 経由）
  **録音も著作権者によりパブリックドメインとして公開されている。**
  加えて「表示すれば任意の用途に使ってよい」とされているので、
  アプリ内の音楽クレジットに演奏者名を出す。
- 取得元: Wikimedia Commons
  https://commons.wikimedia.org/wiki/File:Ludwig_van_Beethoven_-_symphony_no._5_in_c_minor,_op._67_-_i._allegro_con_brio.ogg

■ なぜ切るのか
元の録音は 8分20秒・8.8MB ある。ホーム画面で流すだけなのに
それを丸ごと積むと、音声だけで38MBあった容量削減の意味が消える。
**冒頭の主題だけ**を切り出し、前後をフェードしてループにする。

■ 使いかた
  pip install numpy soundfile lameenc
  python tools/make_bgm_unmei.py

  → assets/audio/beethoven_5th.mp3

⚠️ ffmpeg は使わない（環境に無い）。soundfile で読み、lameenc で書く。
"""

import os
import urllib.request

import lameenc
import numpy as np
import soundfile as sf

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
CACHE = os.path.join(HERE, '.beethoven5.ogg')
OUT = os.path.join(ROOT, 'assets', 'audio', 'beethoven_5th.mp3')

SRC_URL = ('https://upload.wikimedia.org/wikipedia/commons/e/e6/'
           'Ludwig_van_Beethoven_-_symphony_no._5_in_c_minor%2C_'
           'op._67_-_i._allegro_con_brio.ogg')

# 切り出す範囲（秒）。冒頭の「ジャジャジャジャーン」から第1主題まで。
# ⚠️ ここを伸ばすとそのぶん容量が増える。90秒で約1MB。
START = 0.0
END = 88.0

# 出口のフェード。ぶつ切りだとループの継ぎ目で「プツッ」と鳴る。
FADE_IN = 0.05
FADE_OUT = 3.0

BITRATE = 96  # kbps。オーケストラは96で十分もつ。64だと濁る。


def main():
    if not os.path.exists(CACHE):
        print('録音を取得中…')
        req = urllib.request.Request(
            SRC_URL, headers={'User-Agent': 'nanimonjya-dev/1.0'})
        with urllib.request.urlopen(req) as r, open(CACHE, 'wb') as f:
            f.write(r.read())

    data, rate = sf.read(CACHE, dtype='float32', always_2d=True)
    print(f'元: {len(data) / rate:.1f}秒 {rate}Hz {data.shape[1]}ch')

    clip = data[int(START * rate):int(END * rate)].copy()

    # フェード
    n_in = int(FADE_IN * rate)
    n_out = int(FADE_OUT * rate)
    clip[:n_in] *= np.linspace(0, 1, n_in)[:, None]
    clip[-n_out:] *= np.linspace(1, 0, n_out)[:, None]

    # 音量をそろえる。BGMなので効果音より小さめ（-3dBFS ピーク）。
    peak = float(np.abs(clip).max())
    if peak > 0:
        clip *= (10 ** (-3 / 20)) / peak

    # 44.1kHz に落とす。48kHz のままでも鳴るが、mp3 が少し大きくなる。
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
    enc.set_quality(2)  # 2 = 高音質より少し速い。差は聞き取れない
    mp3 = enc.encode(pcm.tobytes()) + enc.flush()
    with open(OUT, 'wb') as f:
        f.write(mp3)

    print(f'書き出した: {OUT}')
    print(f'{len(mp3) / 1048576:.2f} MB / {len(clip) / rate:.1f}秒 '
          f'/ {BITRATE}kbps')


if __name__ == '__main__':
    main()
