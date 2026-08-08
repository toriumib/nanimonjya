# -*- coding: utf-8 -*-
"""🎨 ランチャーアイコンを描く（OL風の女性 ＋「なまえがお」）。

画像編集ソフトを使わず、コードで描いて書き出す。
色や配置を直したくなったら、この1ファイルを直して回せばよい。

■ 方針（今風のOL）
アプリの中身が「会社・学校で会った人の顔と名前を覚える」なので、
アイコンも**働いている人**に寄せる。
- 髪はワンレンのボブ。毛先だけ内に入れる
- 紺のジャケット＋白いインナー。襟をV字に見せる
- 配色は生成りとテラコッタ。ピンク×クリームだと子ども向けに見える
- 目は開ける。伏し目や笑顔で目を閉じると、小さいサイズで顔が消える

出力:
  assets/images/launcher/icon_ios.png                  1024 全面（アルファ無し）
  assets/images/launcher/icon_adaptive_background.png  1024 背景だけ
  assets/images/launcher/icon_adaptive_foreground.png  1024 顔と文字（透過）

⚠️ Android のアダプティブアイコンは、外周がまるく切り取られる。
   中央 66% ほどしか確実に見えないので、前景はそこへ収める。

使い方:
  python tools/gen_launcher_icon.py
  dart run flutter_launcher_icons
"""

import os
from PIL import Image, ImageDraw, ImageFont

S = 1024  # 出力の一辺
HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(HERE, "assets", "images", "launcher")
FONT = os.path.join(HERE, "assets", "fonts", "ZenMaruGothic-Bold.ttf")

# ── 配色（今風・低彩度）──
BG_TOP = (255, 246, 238)      # 生成り
BG_BOTTOM = (247, 226, 213)   # うすいテラコッタ
SKIN = (250, 222, 200)
SKIN_SHADE = (236, 199, 174)
HAIR = (58, 44, 40)           # 黒に近いこげ茶
HAIR_SHINE = (120, 96, 86)
JACKET = (43, 56, 82)         # 紺
JACKET_DARK = (32, 43, 65)
BLOUSE = (252, 252, 250)
CHEEK = (231, 150, 133)
LIP = (198, 96, 84)
LINE = (62, 48, 44)
TEXT = (43, 56, 82)           # 紺（背景から浮く）
TEXT_EDGE = (255, 255, 255)


def _vertical_gradient(size, top, bottom):
    """上から下へのグラデーション。べた塗りより奥行きが出る。"""
    g = Image.new("RGB", (1, size), top)
    px = g.load()
    for y in range(size):
        t = y / (size - 1)
        px[0, y] = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
    return g.resize((size, size))


def draw_background():
    img = _vertical_gradient(S, BG_TOP, BG_BOTTOM).convert("RGBA")
    d = ImageDraw.Draw(img, "RGBA")
    # 大きく薄い円をひとつだけ。柄を増やすと安っぽくなる。
    d.ellipse([S * 0.10, S * 0.10, S * 0.90, S * 0.90],
              fill=(255, 255, 255, 46))
    return img


def draw_person(img, cx, cy, r, with_text, text_px):
    """OL風の女性。[r] は顔の横半径。"""
    d = ImageDraw.Draw(img, "RGBA")

    # ── 肩・ジャケット（顔より先に描く）
    # ⚠️ 下に伸ばしすぎると文字と重なる。肩は「見える」だけで足りる。
    sh_top = cy + r * 1.06
    d.rounded_rectangle(
        [cx - r * 1.95, sh_top, cx + r * 1.95, sh_top + r * 1.05],
        radius=r * 0.50, fill=JACKET)
    # 白いインナーをV字に
    d.polygon([
        (cx - r * 0.44, sh_top - r * 0.06),
        (cx, sh_top + r * 0.62),
        (cx + r * 0.44, sh_top - r * 0.06),
    ], fill=BLOUSE)
    # ジャケットの襟
    d.polygon([
        (cx - r * 0.50, sh_top - r * 0.08),
        (cx - r * 0.04, sh_top + r * 0.64),
        (cx - r * 0.90, sh_top + r * 0.44),
    ], fill=JACKET_DARK)
    d.polygon([
        (cx + r * 0.50, sh_top - r * 0.08),
        (cx + r * 0.04, sh_top + r * 0.64),
        (cx + r * 0.90, sh_top + r * 0.44),
    ], fill=JACKET_DARK)

    # 首
    d.rounded_rectangle(
        [cx - r * 0.25, cy + r * 0.62, cx + r * 0.25, sh_top + r * 0.10],
        radius=r * 0.12, fill=SKIN_SHADE)

    # ── 髪。
    #
    # ⚠️ **顔の横に別部品の髪を重ねない**。
    #    細長い楕円を顔の両脇に置くと、そのぶん顔が縦に切り取られて
    #    輪郭が角ばり、お面のように見える（一度そうなった）。
    #    髪は「顔よりひと回り大きい影」として後ろに1枚だけ置き、
    #    顔をその上に描く。framing は自然にできる。

    # 後ろ髪（ボブ）。顔よりひと回り大きい楕円。
    d.ellipse([cx - r * 1.26, cy - r * 1.22, cx + r * 1.26, cy + r * 0.96],
              fill=HAIR)
    # 毛先。あごの高さで内へ入れる
    for sx in (-1, 1):
        d.ellipse([cx + sx * r * 0.96 - r * 0.26, cy + r * 0.44,
                   cx + sx * r * 0.96 + r * 0.26, cy + r * 0.98], fill=HAIR)

    # ── 顔（きれいな楕円のまま見せる）
    d.ellipse([cx - r, cy - r * 1.00, cx + r, cy + r * 1.12], fill=SKIN)

    # ── 前髪。
    #
    # ⚠️ pieslice(180,360) は**下辺が一直線**になる。
    #    額を横一文字に切る形なので、ヘルメットをかぶって見える。
    #    楕円を使えば下辺が弧になり、生え際が丸くつながる。
    d.ellipse([cx - r * 1.04, cy - r * 1.34, cx + r * 1.04, cy - r * 0.30],
              fill=HAIR)
    # ワンレンの流れ。片側だけ低く垂らして、左右を非対称にする。
    # 左右対称のままだと、おかっぱに見えて「今風」から遠い。
    d.ellipse([cx - r * 1.06, cy - r * 1.20, cx + r * 0.22, cy - r * 0.06],
              fill=HAIR)
    # つや
    d.arc([cx - r * 0.60, cy - r * 1.06, cx + r * 0.30, cy - r * 0.46],
          204, 316, fill=HAIR_SHINE, width=int(r * 0.075))

    # ── 目
    ew = r * 0.16
    ey = cy + r * 0.14
    for sx in (-1, 1):
        ex = cx + sx * r * 0.40
        d.arc([ex - ew * 1.30, ey - ew * 1.20, ex + ew * 1.30, ey + ew * 1.00],
              200, 340, fill=LINE, width=int(r * 0.050))
        d.ellipse([ex - ew * 0.68, ey - ew * 0.50,
                   ex + ew * 0.68, ey + ew * 0.80], fill=LINE)
        d.ellipse([ex - ew * 0.40, ey - ew * 0.26,
                   ex - ew * 0.06, ey + ew * 0.08], fill=(255, 255, 255, 235))
        d.line([(ex + sx * ew * 1.34, ey - ew * 0.50),
                (ex + sx * ew * 1.78, ey - ew * 0.86)],
               fill=LINE, width=int(r * 0.038))

    # まゆ。**細く、ゆるい弧**。太い直線だと怒って見える。
    for sx in (-1, 1):
        bx = cx + sx * r * 0.40
        by = ey - r * 0.32
        d.arc([bx - r * 0.20, by - r * 0.10, bx + r * 0.20, by + r * 0.14],
              195, 345, fill=(112, 88, 78), width=int(r * 0.034))

    # ほお
    for sx in (-1, 1):
        d.ellipse([cx + sx * r * 0.60 - r * 0.16, ey + r * 0.18,
                   cx + sx * r * 0.60 + r * 0.16, ey + r * 0.38],
                  fill=CHEEK + (64,))

    # 鼻
    d.line([(cx, ey + r * 0.26), (cx + r * 0.05, ey + r * 0.34)],
           fill=(198, 158, 138), width=int(r * 0.040))

    # 口
    mw = r * 0.17
    my = ey + r * 0.52
    d.arc([cx - mw, my - mw * 0.75, cx + mw, my + mw * 0.95],
          12, 168, fill=LIP, width=int(r * 0.058))

    # イヤリング
    for sx in (-1, 1):
        d.ellipse([cx + sx * r * 0.90 - r * 0.055, cy + r * 0.52,
                   cx + sx * r * 0.90 + r * 0.055, cy + r * 0.63],
                  fill=(226, 196, 140))

    if not with_text:
        return

    # ── 文字「なまえがお」
    font = ImageFont.truetype(FONT, text_px)
    label = "なまえがお"
    ty = cy + r * 2.62
    for dx in range(-8, 9, 4):
        for dy in range(-8, 9, 4):
            if dx or dy:
                d.text((cx + dx, ty + dy), label, font=font,
                       fill=TEXT_EDGE, anchor="mm")
    d.text((cx, ty), label, font=font, fill=TEXT, anchor="mm")


def main():
    os.makedirs(OUT, exist_ok=True)

    # ① iOS / 全面。角丸はOS側が切るので、四隅まで背景を敷く。
    ios = draw_background()
    draw_person(ios, S * 0.50, S * 0.36, S * 0.200,
                with_text=True, text_px=int(S * 0.118))
    ios.convert("RGB").save(os.path.join(OUT, "icon_ios.png"))

    # ② Android アダプティブ・背景
    draw_background().convert("RGB").save(
        os.path.join(OUT, "icon_adaptive_background.png"))

    # ③ Android アダプティブ・前景（透過）。
    #    外周は切られるので、中央66%に収まるよう小さめに置く。
    fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    draw_person(fg, S * 0.50, S * 0.385, S * 0.150,
                with_text=True, text_px=int(S * 0.090))
    fg.save(os.path.join(OUT, "icon_adaptive_foreground.png"))

    print("wrote 3 files to", OUT)


if __name__ == "__main__":
    main()
