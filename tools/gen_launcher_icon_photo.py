# -*- coding: utf-8 -*-
"""📷 写真からランチャーアイコンを作る。**現在使っているのはこちら。**

手描き版は `gen_launcher_icon.py`（コードで顔を描く方）に残してある。
写真に差し替えたので、ふだんはこのファイルだけ回せばよい。

■ Android アダプティブアイコンの寸法（ここを間違えると顔が切れる）
レイヤーは 108dp 四方だが、**実際に見えるのは中央 72dp＝66.7% だけ**。
外周 18dp はマスクと視差ぶんの余白で、どの端末でも表示されない。

  1024 * 72/108 = 682.7px  ← ここに顔が収まっていないと切れる

なので「見せたい正方形」をそのまま 1024 にするのではなく、
**1.5倍に広げた正方形を 1024 にする**。すると見せたい部分が
ちょうど中央 683px に来る。

■ 元写真からはみ出すぶん
1.5倍に広げると元写真の外に出る。外周は**どうせ見えない**ので、
端のピクセルを引き伸ばして埋めている（`ImageOps.expand` ではなく
クロップ＋リサイズで端を複製）。ここに凝る必要はない。

■ 加工
そのまま貼ると、白い壁紙のランチャーで輪郭が消える。
- 少しだけ暖色に寄せる（青を落とす）
- コントラストと彩度を軽く上げる
- **周辺減光を入れる**。これが無いと、丸く切り抜かれたときに
  右側の白飛びが背景と溶けて、輪郭が分からなくなる

出力:
  assets/images/launcher/icon_ios.png                  1024 全面（アルファ無し）
  assets/images/launcher/icon_adaptive_background.png  1024 下地
  assets/images/launcher/icon_adaptive_foreground.png  1024 写真（全面）
  web/icons/*.png, web/favicon.png

使い方:
  python tools/gen_launcher_icon_photo.py
  dart run flutter_launcher_icons
"""

import os
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

S = 1024
SAFE = 72 / 108          # アダプティブアイコンで見える割合

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(HERE, "assets", "images", "launcher")
WEB = os.path.join(HERE, "web")

SRC = os.path.join(
    HERE, "assets", "images", "launcher", "src_portrait.webp")

# 顔の中心と、見せたい正方形の一辺（元写真のピクセル）。
# ここだけ触れば構図を変えられる。
FACE_CX, FACE_CY, FACE_S = 345, 305, 620


def _crop_square(im, cx, cy, size):
    """[cx,cy] を中心に一辺 [size] で切る。はみ出したぶんは端を複製する。"""
    w, h = im.size
    x0, y0 = cx - size // 2, cy - size // 2
    canvas = Image.new("RGB", (size, size))

    # 元写真に収まる範囲
    sx0, sy0 = max(0, x0), max(0, y0)
    sx1, sy1 = min(w, x0 + size), min(h, y0 + size)
    inner = im.crop((sx0, sy0, sx1, sy1))
    canvas.paste(inner, (sx0 - x0, sy0 - y0))

    # はみ出したぶんを端の1列/1行で埋める。見えない場所なので雑でよい。
    if sx0 - x0 > 0:
        edge = inner.crop((0, 0, 1, inner.height))
        canvas.paste(edge.resize((sx0 - x0, inner.height)), (0, sy0 - y0))
    if x0 + size - sx1 > 0:
        edge = inner.crop((inner.width - 1, 0, inner.width, inner.height))
        canvas.paste(edge.resize((x0 + size - sx1, inner.height)),
                     (sx1 - x0, sy0 - y0))
    if sy0 - y0 > 0:
        band = canvas.crop((0, sy0 - y0, size, sy0 - y0 + 1))
        canvas.paste(band.resize((size, sy0 - y0)), (0, 0))
    if y0 + size - sy1 > 0:
        band = canvas.crop((0, sy1 - y0 - 1, size, sy1 - y0))
        canvas.paste(band.resize((size, y0 + size - sy1)), (0, sy1 - y0))
    return canvas


def _grade(im):
    """色を整える。やりすぎると肌が不自然になるので、どれも軽く。"""
    im = ImageEnhance.Color(im).enhance(1.12)
    im = ImageEnhance.Contrast(im).enhance(1.08)
    im = ImageEnhance.Brightness(im).enhance(1.02)
    # 暖色へ。青チャンネルを少しだけ落とす。
    r, g, b = im.split()
    b = b.point(lambda v: int(v * 0.965))
    r = r.point(lambda v: min(255, int(v * 1.015)))
    return Image.merge("RGB", (r, g, b))


def _vignette(im, strength=0.30):
    """周辺減光。丸く切り抜かれたときに輪郭を出すために要る。"""
    w, h = im.size
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).ellipse(
        [w * 0.02, h * 0.02, w * 0.98, h * 0.98], fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(w * 0.13))
    dark = ImageEnhance.Brightness(im).enhance(1 - strength)
    return Image.composite(im, dark, mask)


def main():
    if not os.path.exists(SRC):
        raise SystemExit(f"元写真がない: {SRC}")
    photo = Image.open(SRC).convert("RGB")

    # ① iOS / ストア用。角まで見えるので、少し引いた構図にする。
    ios = _crop_square(photo, FACE_CX, FACE_CY + 20, 700)
    ios = _vignette(_grade(ios.resize((S, S), Image.LANCZOS)), 0.26)
    ios.save(os.path.join(OUT, "icon_ios.png"))

    # ② アダプティブ前景。**1.5倍に広げてから 1024 にする**（冒頭の説明）。
    outer = int(FACE_S / SAFE)
    fg = _crop_square(photo, FACE_CX, FACE_CY, outer)
    fg = _vignette(_grade(fg.resize((S, S), Image.LANCZOS)), 0.30)
    fg.convert("RGBA").save(
        os.path.join(OUT, "icon_adaptive_foreground.png"))

    # ③ アダプティブ背景。前景が全面を覆うので、ふだんは見えない。
    #    端末が前景を縮めたときに透ける下地として、髪の色を置いておく。
    Image.new("RGB", (S, S), (168, 122, 92)).save(
        os.path.join(OUT, "icon_adaptive_background.png"))

    # ④ Web
    for path, n in [("icons/Icon-192.png", 192), ("icons/Icon-512.png", 512),
                    ("icons/Icon-maskable-192.png", 192),
                    ("icons/Icon-maskable-512.png", 512),
                    ("favicon.png", 32)]:
        ios.resize((n, n), Image.LANCZOS).save(os.path.join(WEB, path))

    print("wrote launcher + web icons")


if __name__ == "__main__":
    main()
