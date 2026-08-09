# -*- coding: utf-8 -*-
"""🅰 ロゴ用フォントを、必要な文字だけに絞って書き出す。

■ なぜ要るか
ロゴ（ホーム画面のタイトル）は Mochiy Pop One という書体で出している。
以前は `google_fonts` パッケージで**実行時に fonts.gstatic.com から
ダウンロード**していたが、圏外だと名前解決に失敗して例外になる。
ホーム画面は全員が通るので、Crashlytics がこれ1件で埋まっていた。

同梱すれば起きない。ただし日本語フォントは全字入りで **5.16MB** ある。
ロゴに出るのは数文字なので、**その文字だけに絞る**（約25KB）。

■ 使いかた

  pip install fonttools
  python tools/subset_logo_font.py

  → assets/fonts/MochiyPopOne-Logo.ttf を作り直す

■ ⚠️ ロゴの文言を変えたら、必ずこれを回すこと
入っていない文字は**豆腐（□）**になる。
文字は `lib/l10n/app_jp.arb` / `app_en.arb` の `appTitle` から取っている。

■ ライセンス
Mochiy Pop One は SIL Open Font License 1.1。
サブセット（改変）と再配布が認められている。
ライセンス文は `assets/fonts/OFL-MochiyPopOne.txt` に同梱すること。
"""

import json
import os
import re
import sys
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, 'assets', 'fonts', 'MochiyPopOne-Logo.ttf')
LICENSE_OUT = os.path.join(ROOT, 'assets', 'fonts', 'OFL-MochiyPopOne.txt')

BASE = ('https://raw.githubusercontent.com/google/fonts/main/ofl/'
        'mochiypopone/')

# ロゴ以外にも使いたくなったとき用の予備。英数字は入れても数百バイト。
EXTRA = ('ABCDEFGHIJKLMNOPQRSTUVWXYZ'
         'abcdefghijklmnopqrstuvwxyz'
         '0123456789 !?・ー〜')


def logo_texts():
    """arb から appTitle を拾う。ロゴに出るのはこれだけ。"""
    out = []
    for name in ('app_jp.arb', 'app_en.arb'):
        path = os.path.join(ROOT, 'lib', 'l10n', name)
        if not os.path.exists(path):
            continue
        with open(path, encoding='utf-8') as f:
            # arb にはコメント用の `@` キーが混ざるので json で読む
            data = json.load(f)
        title = data.get('appTitle')
        if title:
            out.append(title)
    return out


def main():
    try:
        from fontTools import subset
    except ImportError:
        raise SystemExit('fonttools がない。 pip install fonttools')

    titles = logo_texts()
    if not titles:
        raise SystemExit('appTitle が見つからない')
    chars = ''.join(sorted(set(''.join(titles) + EXTRA)))
    print('ロゴの文字:', ' / '.join(titles))
    print('入れる字数:', len(chars))

    src = os.path.join(HERE, '.MochiyPopOne-Regular.ttf')
    if not os.path.exists(src):
        print('元フォントを取得中…')
        urllib.request.urlretrieve(BASE + 'MochiyPopOne-Regular.ttf', src)
    if not os.path.exists(LICENSE_OUT):
        urllib.request.urlretrieve(BASE + 'OFL.txt', LICENSE_OUT)

    opts = subset.Options()
    opts.layout_features = ['*']
    opts.notdef_outline = True
    opts.recalc_bounds = True
    font = subset.load_font(src, opts)
    sub = subset.Subsetter(options=opts)
    sub.populate(text=chars)
    sub.subset(font)
    subset.save_font(font, OUT, opts)

    before = os.path.getsize(src)
    after = os.path.getsize(OUT)
    print(f'{before:,} → {after:,} バイト（{before / after:.0f}分の1）')
    print('書き出した:', OUT)


if __name__ == '__main__':
    sys.exit(main())
