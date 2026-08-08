# -*- coding: utf-8 -*-
"""🎨 ランチャーアイコンを描く（笑った女の子の顔 ＋「なまえがお」）。

画像編集ソフトを使わず、コードで描いて書き出す。
色や配置を直したくなったら、この1ファイルを直して回せばよい。

出力:
  assets/images/launcher/icon_ios.png                  1024 全面（アルファ無し）
  assets/images/launcher/icon_adaptive_background.png  1024 背景だけ
  assets/images/launcher/icon_adaptive_foreground.png  1024 顔と文字（透過）

⚠️ Android のアダプティブアイコンは、外周がまるく切り取られる。
   中央 66% ほどしか確実に見えないので、前景はそこへ収める。

使い方:
  python tools/gen_launcher_icon.py
  flutter pub run flutter_launcher_icons
"""

import os
from PIL import Image, ImageDraw, ImageFont

S = 1024  # 出力の一辺
HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(HERE, "assets", "images", "launcher")
FONT = os.path.join(HERE, "assets", "fonts", "ZenMaruGothic-Bold.ttf")

# ── 配色 ──
BG_TOP = (255, 214, 232)      # うすいピンク
BG_BOTTOM = (255, 246, 216)   # クリーム
SKIN = (255, 226, 200)
SKIN_SHADE = (247, 205, 175)
HAIR = (92, 58, 44)           # こげ茶
HAIR_LIGHT = (126, 84, 64)
CHEEK = (255, 150, 160)
LINE = (74, 52, 40)
TEXT = (233, 74, 122)         # 濃いピンク
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
    # ふわっとした白い円。顔の邪魔をしないよう、小さく薄く四隅に置く。
    for cx, cy, r, a in [(0.12, 0.14, 0.075, 55), (0.88, 0.12, 0.055, 48),
                         (0.92, 0.60, 0.065, 42), (0.08, 0.58, 0.048, 40)]:
        d.ellipse(
            [S * (cx - r), S * (cy - r), S * (cx + r), S * (cy + r)],
            fill=(255, 255, 255, a),
        )
    return img


def draw_face(img, cx, cy, r, with_text, text_px):
    """笑った女の子の顔。[r] は顔の横半径。

    描く順番が大事。後ろ髪 → 顔 → 前髪 → 目鼻口、の順に重ねる。
    """
    d = ImageDraw.Draw(img, "RGBA")

    # ── ツインテール（顔の後ろ。耳の位置より下に置くと「けもの耳」に見えない）
    for sx in (-1, 1):
        d.ellipse([cx + sx * r * 1.10 - r * 0.30, cy - r * 0.10,
                   cx + sx * r * 1.10 + r * 0.30, cy + r * 0.86], fill=HAIR)
        d.ellipse([cx + sx * r * 1.12 - r * 0.15, cy + r * 0.06,
                   cx + sx * r * 1.12 + r * 0.15, cy + r * 0.34],
                  fill=HAIR_LIGHT)

    # ── 後ろ髪
    d.ellipse([cx - r * 1.12, cy - r * 1.22, cx + r * 1.12, cy + r * 0.72],
              fill=HAIR)

    # ── 顔
    d.ellipse([cx - r, cy - r * 0.95, cx + r, cy + r * 1.05], fill=SKIN)

    # ── 前髪。
    #    髪の楕円の「上半分」を切り出すと、下辺がまっすぐな
    #    ぱっつん前髪になる。楕円の縦中心を額の高さに合わせる。
    bang_bottom = cy - r * 0.22          # 前髪の下端＝額の線
    bang_h = r * 1.05                    # 上へどれだけ伸ばすか
    d.pieslice([cx - r * 1.06, bang_bottom - bang_h,
                cx + r * 1.06, bang_bottom + bang_h],
               180, 360, fill=HAIR)
    # 前髪の両端を下へ丸く垂らす。
    # 直線で切りっぱなしにすると額が四角く見え、ヘルメットのようになる。
    # ⚠️ 内側に寄せすぎると目にかぶる。目の外側で止めること。
    for sx in (-1, 1):
        d.ellipse([cx + sx * r * 0.74 - r * 0.30, bang_bottom - r * 0.40,
                   cx + sx * r * 0.74 + r * 0.30, bang_bottom + r * 0.16],
                  fill=HAIR)
    # 横に落ちるおくれ毛（顔の輪郭に沿わせる）
    for sx in (-1, 1):
        d.ellipse([cx + sx * r * 0.86 - r * 0.26, cy - r * 0.62,
                   cx + sx * r * 0.86 + r * 0.26, cy + r * 0.46], fill=HAIR)
    # 髪のつや
    d.arc([cx - r * 0.60, cy - r * 1.02, cx + r * 0.22, cy - r * 0.42],
          205, 315, fill=(255, 255, 255, 105), width=int(r * 0.085))

    # ── 目（笑って閉じた ^ ^）
    ew = r * 0.26
    ey = cy + r * 0.16
    for sx in (-1, 1):
        ex = cx + sx * r * 0.40
        d.arc([ex - ew, ey - ew * 0.95, ex + ew, ey + ew * 1.05],
              200, 340, fill=LINE, width=int(r * 0.085))

    # ── ほお（目の下、口の横）
    for sx in (-1, 1):
        d.ellipse([cx + sx * r * 0.60 - r * 0.17, ey + r * 0.16,
                   cx + sx * r * 0.60 + r * 0.17, ey + r * 0.44],
                  fill=CHEEK + (110,))

    # ── 口（開いたにっこり。舌を入れると一気に「笑った顔」になる）
    mw = r * 0.22
    my = cy + r * 0.52
    d.chord([cx - mw, my - mw * 0.85, cx + mw, my + mw * 1.15],
            0, 180, fill=LINE)
    d.chord([cx - mw * 0.60, my + mw * 0.10, cx + mw * 0.60, my + mw * 1.10],
            0, 180, fill=CHEEK)

    if not with_text:
        return

    # ── 文字「なまえがお」
    font = ImageFont.truetype(FONT, text_px)
    label = "なまえがお"
    ty = cy + r * 1.46
    # 白フチ（背景に負けないように）
    for dx in range(-9, 10, 3):
        for dy in range(-9, 10, 3):
            if dx or dy:
                d.text((cx + dx, ty + dy), label, font=font,
                       fill=TEXT_EDGE, anchor="mm")
    d.text((cx, ty), label, font=font, fill=TEXT, anchor="mm")


def main():
    os.makedirs(OUT, exist_ok=True)

    # ① iOS / 全面。角丸はOS側が切るので、四隅まで背景を敷く。
    ios = draw_background()
    draw_face(ios, S * 0.50, S * 0.40, S * 0.225,
              with_text=True, text_px=int(S * 0.125))
    ios.convert("RGB").save(os.path.join(OUT, "icon_ios.png"))

    # ② Android アダプティブ・背景
    draw_background().convert("RGB").save(
        os.path.join(OUT, "icon_adaptive_background.png"))

    # ③ Android アダプティブ・前景（透過）。
    #    外周は切られるので、中央66%に収まるよう顔と文字を小さめに置く。
    fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    draw_face(fg, S * 0.50, S * 0.425, S * 0.170,
              with_text=True, text_px=int(S * 0.094))
    fg.save(os.path.join(OUT, "icon_adaptive_foreground.png"))

    print("wrote 3 files to", OUT)


if __name__ == "__main__":
    main()
