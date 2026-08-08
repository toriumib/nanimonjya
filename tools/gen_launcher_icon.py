# -*- coding: utf-8 -*-
"""🎨 ランチャーアイコンを描く（女性の顔・文字なし）。

画像編集ソフトを使わず、コードで描いて書き出す。
色や配置を直したくなったら、この1ファイルを直して回せばよい。

■ 方針
落ち着いた美人画の雰囲気に寄せる。参考にしたのは大正〜昭和初期の
油彩の人物画のような、**温かく彩度の低い色調と、ボブの量感**。
（特定の作品を写したものではない。色の置きかたと空気感だけを借りている）

- 顔は縦長の卵形。丸顔にすると幼くなる
- 目は伏し目がち・切れ長。上まぶたを濃く太くするのがいちばん効く
- 口は小さく。大きいと子ども向けの絵になる
- 首は長めに取る。ここが短いと一気に野暮ったくなる
- 髪は真っ黒にしない。赤みのある焦茶にすると肌となじむ

■ 文字は入れない
以前は「なまえがお」を焼き込んでいたが、やめた。
ランチャーはアイコンのすぐ下にアプリ名を出すので二重になるうえ、
文字ぶんの余白を取ると顔が小さくなって、48dpでは何も見えなくなる。

■ きれいに出すための要点
**4倍で描いてから縮める（スーパーサンプリング）。**
PIL の描画はアンチエイリアスが効かない。原寸で描くと輪郭が階段状に
ギザつく。4倍で描いて LANCZOS で縮めると滑らかになる。
影は「ぼかした楕円」を重ねて作る。線で描くと絵が硬くなる。

出力:
  assets/images/launcher/icon_ios.png                  1024 全面（アルファ無し）
  assets/images/launcher/icon_adaptive_background.png  1024 背景だけ
  assets/images/launcher/icon_adaptive_foreground.png  1024 顔だけ（透過）

⚠️ Android のアダプティブアイコンは、外周がまるく切り取られる。
   中央 66% ほどしか確実に見えないので、前景はそこへ収める。

使い方:
  python tools/gen_launcher_icon.py
  dart run flutter_launcher_icons
"""

import os
from PIL import Image, ImageDraw, ImageFilter

S = 1024          # 出力の一辺
SS = 4            # スーパーサンプリング倍率
W = S * SS        # 内部で描く一辺

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(HERE, "assets", "images", "launcher")

# ── 配色（温かい低彩度）──
BG_TOP = (216, 170, 140)      # 焼けた土
BG_BOTTOM = (174, 122, 100)
SKIN = (244, 217, 197)
SKIN_SHADE = (215, 174, 151)
SKIN_DEEP = (188, 141, 120)
HAIR = (60, 39, 45)           # 赤みのある焦茶
HAIR_LIGHT = (106, 72, 76)
CLOTH = (238, 231, 220)       # 生成りのブラウス
CLOTH_SHADE = (204, 192, 178)
BROW = (94, 64, 60)
LASH = (46, 30, 33)
LIP = (176, 96, 90)


def _grad(size, top, bottom):
    g = Image.new("RGB", (1, size), top)
    px = g.load()
    for y in range(size):
        t = y / (size - 1)
        px[0, y] = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
    return g.resize((size, size))


def _soft(layer, radius):
    """ぼかす。影とチークはこれで作る。"""
    return layer.filter(ImageFilter.GaussianBlur(radius))


def draw_background(w):
    img = _grad(w, BG_TOP, BG_BOTTOM).convert("RGBA")
    # 中央にだけ光を当てる。均一に塗ると平らに見える。
    glow = Image.new("RGBA", (w, w), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse(
        [w * 0.10, w * 0.00, w * 0.90, w * 0.82],
        fill=(255, 238, 220, 92))
    img.alpha_composite(_soft(glow, w * 0.06))
    return img


def draw_person(img, cx, cy, r):
    """[r] は顔の横半径。[cy] は顔の中心。

    ⚠️ パーツを足すほど汚くなる。一度、二重の線・下まぶた・瞳の
       ハイライト・髪のつや・額の落ち影を全部入れたら、顔が
       線だらけになって別人になった。**引き算で作る。**
    """
    w = img.size[0]

    def layer():
        return Image.new("RGBA", (w, w), (0, 0, 0, 0))

    # ── 肩と衣。なで肩に。四角い板にすると人形に見える。
    sh = cy + r * 1.34          # 肩。低くすると首が伸びて棒に見える
    body = layer()
    b = ImageDraw.Draw(body)
    b.ellipse([cx - r * 2.75, sh, cx + r * 2.75, sh + r * 3.2], fill=CLOTH)
    # 襟もとの影。⚠️ 大きくぼかすと、肩の後ろに灰色の雲が浮く。
    shade = layer()
    ImageDraw.Draw(shade).ellipse(
        [cx - r * 0.44, sh - r * 0.02, cx + r * 0.44, sh + r * 0.30],
        fill=CLOTH_SHADE + (120,))
    body.alpha_composite(_soft(shade, r * 0.07))
    img.alpha_composite(body)

    # ── 首。細く。太いと男性的になり、四角いと棒に見える。
    neck = layer()
    ImageDraw.Draw(neck).rounded_rectangle(
        [cx - r * 0.245, cy + r * 0.70, cx + r * 0.245, sh + r * 0.26],
        radius=r * 0.20, fill=SKIN_SHADE)
    # あごの落ち影。首を暗くすると、顔が前に出る。
    ns = layer()
    ImageDraw.Draw(ns).ellipse(
        [cx - r * 0.32, cy + r * 0.88, cx + r * 0.32, cy + r * 1.30],
        fill=SKIN_DEEP + (145,))
    neck.alpha_composite(_soft(ns, r * 0.07))
    img.alpha_composite(neck)

    # ── 髪（後ろ）。顔よりひと回り大きく取って量感を出す。
    hair = layer()
    h = ImageDraw.Draw(hair)
    h.ellipse([cx - r * 1.30, cy - r * 1.30, cx + r * 1.30, cy + r * 0.92],
              fill=HAIR)
    # 毛先。あごの高さで内へ入る。左右で高さを変えると自然。
    h.ellipse([cx - r * 1.22, cy + r * 0.10, cx - r * 0.42, cy + r * 1.20],
              fill=HAIR)
    h.ellipse([cx + r * 0.46, cy + r * 0.04, cx + r * 1.26, cy + r * 1.10],
              fill=HAIR)
    img.alpha_composite(hair)

    # ── 顔。縦長の卵形。
    face = layer()
    ImageDraw.Draw(face).ellipse(
        [cx - r, cy - r * 1.06, cx + r, cy + r * 1.26], fill=SKIN)
    img.alpha_composite(face)

    # 輪郭の内側だけ、うっすら沈める。丸みが出る。
    sh_l = layer()
    s2 = ImageDraw.Draw(sh_l)
    # 下半分を強めに。ここを効かせると、あごが細く見える。
    # ⚠️ 濃く広く入れると、頬にくすんだ大きなシミが出る。薄く、外周だけ。
    s2.ellipse([cx - r * 1.06, cy + r * 0.16, cx - r * 0.66, cy + r * 1.16],
               fill=SKIN_SHADE + (95,))
    s2.ellipse([cx + r * 0.66, cy + r * 0.16, cx + r * 1.06, cy + r * 1.16],
               fill=SKIN_SHADE + (95,))
    img.alpha_composite(_soft(sh_l, r * 0.10))

    # 中央のハイライト。額から鼻すじを明るくすると、顔が立体になる。
    hi = layer()
    ImageDraw.Draw(hi).ellipse(
        [cx - r * 0.40, cy - r * 0.70, cx + r * 0.40, cy + r * 0.62],
        fill=(255, 242, 228, 105))
    img.alpha_composite(_soft(hi, r * 0.16))

    # ── 前髪。楕円の下辺（弧）を使う。
    #    ⚠️ pieslice で切ると底が直線になり、ヘルメットに見える。
    #    ⚠️ まゆまで覆うと顔が黒く潰れる。額を三分の一は残す。
    fr = layer()
    fd = ImageDraw.Draw(fr)
    fd.ellipse([cx - r * 1.06, cy - r * 1.40, cx + r * 1.06, cy - r * 0.56],
               fill=HAIR)
    # 分け目。片側だけ長く垂らして左右を崩す
    fd.ellipse([cx - r * 1.14, cy - r * 1.30, cx - r * 0.04, cy - r * 0.30],
               fill=HAIR)
    fd.ellipse([cx + r * 0.42, cy - r * 1.26, cx + r * 1.16, cy - r * 0.42],
               fill=HAIR)
    img.alpha_composite(fr)

    # ── 目。伏し目がち。**線は上まぶた1本だけ。**
    ey = cy + r * 0.26
    ew = r * 0.29            # 目の横半径
    dx = r * 0.46            # 中心からの間隔
    lw = max(1, int(r * 0.050))
    eyes = layer()
    e = ImageDraw.Draw(eyes)
    for sx in (-1, 1):
        ex = cx + sx * dx
        # 瞳を先に置き、上からまぶたで半分隠す＝伏し目。
        e.ellipse([ex - ew * 0.42, ey - ew * 0.34,
                   ex + ew * 0.42, ey + ew * 0.50], fill=LASH)
        # 上まぶた。ゆるい ⌒。ここを濃く太くするのがいちばん効く。
        e.arc([ex - ew, ey - ew * 0.72, ex + ew, ey + ew * 0.34],
              186, 356, fill=LASH, width=lw)
        # まぶたの弧より上を肌で塗り戻し、瞳の上側を隠す。
        # bbox は弧とそろえること。ずらすと瞳が全部消えるか、全部出る。
        e.pieslice([ex - ew, ey - ew * 0.72, ex + ew, ey + ew * 0.34],
                   180, 360, fill=SKIN)
        e.arc([ex - ew, ey - ew * 0.72, ex + ew, ey + ew * 0.34],
              186, 356, fill=LASH, width=lw)
        # 目じりを少し跳ね上げる
        e.line([(ex + sx * ew * 0.90, ey - ew * 0.20),
                (ex + sx * ew * 1.26, ey - ew * 0.46)],
               fill=LASH, width=lw)
    img.alpha_composite(eyes)

    # まゆ。細く長く、ゆるい弧。肌になじむ色で。
    br = layer()
    bd = ImageDraw.Draw(br)
    for sx in (-1, 1):
        bx = cx + sx * dx
        by = ey - r * 0.34
        bd.arc([bx - r * 0.30, by - r * 0.12, bx + r * 0.30, by + r * 0.18],
               198, 342, fill=BROW + (200,), width=int(r * 0.026))
    img.alpha_composite(_soft(br, r * 0.014))

    # ── ほお。ぼかした楕円。輪郭を出さない。
    ch = layer()
    cd = ImageDraw.Draw(ch)
    for sx in (-1, 1):
        cd.ellipse([cx + sx * r * 0.56 - r * 0.26, ey + r * 0.22,
                    cx + sx * r * 0.56 + r * 0.26, ey + r * 0.48],
                   fill=(218, 138, 118, 78))
    img.alpha_composite(_soft(ch, r * 0.11))

    # ── 鼻。影をひとつ置くだけ。線を引くと硬い。
    no = layer()
    ImageDraw.Draw(no).ellipse(
        [cx - r * 0.085, ey + r * 0.30, cx + r * 0.085, ey + r * 0.46],
        fill=SKIN_DEEP + (140,))
    img.alpha_composite(_soft(no, r * 0.04))

    # ── 口。小さく。大きいと子ども向けの絵になる。
    mo = layer()
    md = ImageDraw.Draw(mo)
    mw = r * 0.145
    my = ey + r * 0.70
    md.chord([cx - mw, my - mw * 0.30, cx + mw, my + mw * 1.00],
             0, 180, fill=LIP + (225,))
    md.arc([cx - mw * 1.05, my - mw * 0.72, cx + mw * 1.05, my + mw * 0.40],
           14, 166, fill=(146, 76, 72, 200), width=max(1, int(r * 0.020)))
    img.alpha_composite(_soft(mo, r * 0.014))

    # ── イヤリング。小さな光のアクセント。
    er = layer()
    ed = ImageDraw.Draw(er)
    for sx in (-1, 1):
        ed.ellipse([cx + sx * r * 0.96 - r * 0.05, cy + r * 0.56,
                    cx + sx * r * 0.96 + r * 0.05, cy + r * 0.66],
                   fill=(230, 205, 158))
    img.alpha_composite(er)


def _down(img):
    """4倍で描いたものを実寸へ。ここで輪郭が滑らかになる。"""
    return img.resize((S, S), Image.LANCZOS)


def main():
    os.makedirs(OUT, exist_ok=True)

    # ① iOS / 全面。文字が無いぶん顔を大きく取れる。
    ios = draw_background(W)
    draw_person(ios, W * 0.50, W * 0.400, W * 0.205)
    _down(ios).convert("RGB").save(os.path.join(OUT, "icon_ios.png"))

    # ② Android アダプティブ・背景
    _down(draw_background(W)).convert("RGB").save(
        os.path.join(OUT, "icon_adaptive_background.png"))

    # ③ Android アダプティブ・前景（透過）。中央66%に収める。
    fg = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    draw_person(fg, W * 0.50, W * 0.445, W * 0.190)
    _down(fg).save(os.path.join(OUT, "icon_adaptive_foreground.png"))

    print("wrote 3 files to", OUT)


if __name__ == "__main__":
    main()
