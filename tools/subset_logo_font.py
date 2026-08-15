# -*- coding: utf-8 -*-
"""🅰 画面に出す文字だけに絞ったフォントを作る。

■ なぜ要るか
日本語フォントは全字入りで数MBある。使うのが十数文字でも、
そのまま同梱すると容量を食う（音声を19MB削った意味が消える）。
**出す文字だけ**に絞れば数十KBで済む。

以前はロゴを `google_fonts` で**実行時にダウンロード**していたが、
圏外だと fonts.gstatic.com の名前解決に失敗して例外になり、
Crashlytics がそれ1件で埋まっていた。同梱すれば起きない。

■ 使いかた
  pip install fonttools
  python tools/subset_logo_font.py

  → assets/fonts/ に絞りこんだ .ttf を書き出す

■ ⚠️ 出す文言を変えたら、必ずこれを回すこと
入っていない文字は**豆腐（□）**になる。
ロゴの文字は arb の `appTitle` から自動で拾うが、
**お祝いの文言は下の [CELEBRATION_TEXT] に手で書く**。

■ ライセンス
どちらも SIL Open Font License 1.1。サブセット（改変）と再配布が
認められている。ライセンス文を `assets/fonts/OFL-*.txt` に同梱すること。
"""

import json
import os
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
FONTS = os.path.join(ROOT, 'assets', 'fonts')
BASE = 'https://raw.githubusercontent.com/google/fonts/main/ofl/'

# 英数字と記号。入れても数百バイトなので、まとめて入れておく。
#
# ⚠️ **全角の記号を忘れないこと。** 日本語のUIでは「！」「？」は全角で書く。
#    半角の `!` だけ入れていて、画面には `！` を出していたため、
#    そこだけ豆腐（□）になっていた。
COMMON = ('ABCDEFGHIJKLMNOPQRSTUVWXYZ'
          'abcdefghijklmnopqrstuvwxyz'
          '0123456789 !?%.,:/+-×'
          '！？％．，：・ー〜（）「」、。…'
          '　')  # 全角スペース

# 🎉 お祝い演出に出る文字。
#
# ⚠️ **ここに無い文字は豆腐になる。**
#    celebration.dart や name_call_screen.dart の文言を変えたら追記すること。
CELEBRATION_TEXT = (
    'カードゲット'
    'れんぞく'
    'すごい'
    'かんぺき'
    'クリア'
    'おめでとう'
    'がゲット'
    'ぜんぶ正解'
    'あなたの勝ち'
    'ひきわけ'
    'さいこう'
    'ラスト'
    'まい'
    'のこり'
    'P'
    'がゲット'
    'が正解'
    '言えた'
    'とった'
)

# family名 → (googleフォントのディレクトリ, ファイル名, 出力名, 文字)
TARGETS = {
    'MochiyPopOne': ('mochiypopone', 'MochiyPopOne-Regular.ttf',
                     'MochiyPopOne-Logo.ttf', None),  # None = arb から拾う
    'DelaGothicOne': ('delagothicone', 'DelaGothicOne-Regular.ttf',
                      'DelaGothicOne-Pop.ttf', CELEBRATION_TEXT),
}


def logo_texts():
    """arb から appTitle を拾う。ロゴに出るのはこれだけ。"""
    out = []
    for name in ('app_jp.arb', 'app_en.arb'):
        path = os.path.join(ROOT, 'lib', 'l10n', name)
        if not os.path.exists(path):
            continue
        with open(path, encoding='utf-8') as f:
            data = json.load(f)
        if data.get('appTitle'):
            out.append(data['appTitle'])
    return ''.join(out)


def build(family, dirname, srcname, outname, text):
    from fontTools import subset

    src = os.path.join(HERE, f'.{srcname}')
    if not os.path.exists(src):
        print(f'  元フォントを取得中… {srcname}')
        urllib.request.urlretrieve(BASE + dirname + '/' + srcname, src)

    license_out = os.path.join(FONTS, f'OFL-{family}.txt')
    if not os.path.exists(license_out):
        urllib.request.urlretrieve(BASE + dirname + '/OFL.txt', license_out)

    chars = ''.join(sorted(set((text or logo_texts()) + COMMON)))
    opts = subset.Options()
    opts.layout_features = ['*']
    opts.notdef_outline = True
    opts.recalc_bounds = True
    font = subset.load_font(src, opts)
    sub = subset.Subsetter(options=opts)
    sub.populate(text=chars)
    sub.subset(font)
    out = os.path.join(FONTS, outname)
    subset.save_font(font, out, opts)

    before, after = os.path.getsize(src), os.path.getsize(out)
    print(f'  {family}: {len(chars)}字 / '
          f'{before:,} → {after:,} バイト（{before // after}分の1）')


def main():
    try:
        import fontTools  # noqa: F401
    except ImportError:
        raise SystemExit('fonttools がない。 pip install fonttools')
    for family, (d, src, out, text) in TARGETS.items():
        build(family, d, src, out, text)
    print('できた:', FONTS)


if __name__ == '__main__':
    main()
