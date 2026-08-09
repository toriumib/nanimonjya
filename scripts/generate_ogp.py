#!/usr/bin/env python3
"""
Generate OGP (Open Graph Protocol) image for social media sharing.
Creates a 1200x630 PNG optimized for Twitter Cards, Facebook, LINE, and Discord.

Design: Clean card-style layout with app icon, bold title, gradient BG,
and feature pills. Reads well at small sizes (social feeds).

Usage:
  pip install Pillow
  python scripts/generate_ogp.py

Output: web/icons/ogp-image.png
"""

import math
import os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

PROJECT_ROOT = Path(__file__).resolve().parent.parent
OUTPUT = PROJECT_ROOT / "web" / "icons" / "ogp-image.png"
ICON = PROJECT_ROOT / "web" / "icons" / "Icon-512.png"

W, H = 1200, 630
TOP_COLOR = (58, 123, 213)
BOTTOM_COLOR = (30, 60, 110)
ACCENT = (255, 249, 236)
WHITE = (255, 255, 255)

FONT_DIR = Path("C:/Windows/Fonts")


def find_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    candidates = [
        FONT_DIR / ("meiryob.ttc" if bold else "meiryo.ttc"),
        FONT_DIR / ("segoeuib.ttf" if bold else "segoeui.ttf"),
        FONT_DIR / ("arialbd.ttf" if bold else "arial.ttf"),
    ]
    for path in candidates:
        if path.exists():
            try:
                return ImageFont.truetype(str(path), size=size)
            except Exception:
                continue
    return ImageFont.load_default()


def draw_gradient(draw, w, h):
    for y in range(h):
        t = y / h
        r = int(TOP_COLOR[0] + (BOTTOM_COLOR[0] - TOP_COLOR[0]) * t)
        g = int(TOP_COLOR[1] + (BOTTOM_COLOR[1] - TOP_COLOR[1]) * t)
        b = int(TOP_COLOR[2] + (BOTTOM_COLOR[2] - TOP_COLOR[2]) * t)
        draw.line([(0, y), (w, y)], fill=(r, g, b))


def rounded_rect_mask(size, radius):
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle([0, 0, size, size], radius=radius, fill=255)
    return mask


def draw_pill(img, draw, x, y, text, font, bg_alpha=60):
    """Draw a rounded pill. Returns pill width for layout chaining."""
    pad_x, pad_y = 16, 8
    bbox = draw.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    rw, rh = tw + pad_x * 2, th + pad_y * 2
    r = rh // 2

    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    overlay_d = ImageDraw.Draw(overlay)
    overlay_d.rounded_rectangle(
        [x, y, x + rw, y + rh], radius=r, fill=(255, 255, 255, bg_alpha)
    )
    img.paste(overlay, (0, 0), overlay)

    draw.text((x + pad_x, y + pad_y - 1), text, fill=WHITE, font=font)
    return rw


def main():
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Gradient background
    draw_gradient(draw, W, H)

    # Subtle radial glow behind icon
    glow_size = 280
    glow = Image.new("RGBA", (glow_size, glow_size), (0, 0, 0, 0))
    glow_d = ImageDraw.Draw(glow)
    for r in range(glow_size // 2, 0, -3):
        a = int(30 * (r / (glow_size // 2)))
        glow_d.ellipse(
            [glow_size // 2 - r, glow_size // 2 - r,
             glow_size // 2 + r, glow_size // 2 + r],
            fill=(255, 255, 255, a),
        )
    img.paste(glow, (70 - glow_size // 2 + 70, H // 2 - glow_size // 2), glow)

    # App icon with rounded corners
    icon_size = 140
    icon_x, icon_y = 70, (H - icon_size) // 2
    if ICON.exists():
        icon = Image.open(ICON).convert("RGBA")
        icon = icon.resize((icon_size, icon_size), Image.LANCZOS)
        mask = rounded_rect_mask(icon_size, 32)
        img.paste(icon, (icon_x, icon_y), mask)

    # Text layout
    text_x = icon_x + icon_size + 48

    font_title = find_font(58, bold=True)
    font_sub = find_font(27, bold=True)
    font_body = find_font(22)
    font_pill = find_font(18, bold=True)
    font_url = find_font(19, bold=True)

    y = 130

    # Title line 1 + line 2 (accent color for impact)
    draw.text((text_x, y), "Never forget a name again.", fill=WHITE, font=font_title)
    y += font_title.size + 24

    draw.text(
        (text_x, y),
        "Face & name memory training game",
        fill=(255, 255, 255, 210),
        font=font_sub,
    )
    y += font_sub.size + 26

    # Feature pills
    pills_r1 = ["Real face photos", "Backed by science", "2-4 players"]
    px = text_x
    for pill in pills_r1:
        pw = draw_pill(img, draw, px, y, pill, font_pill, bg_alpha=45)
        px += pw + 10
    y += 44

    pills_r2 = ["Business card OCR", "Avatar builder", "Online ranked"]
    px = text_x
    for pill in pills_r2:
        pw = draw_pill(img, draw, px, y, pill, font_pill, bg_alpha=45)
        px += pw + 10
    y += 52

    # Bottom tagline
    draw.text(
        (text_x, y),
        "Free on Android & Web. No account needed.",
        fill=(255, 255, 255, 190),
        font=font_body,
    )

    # Bottom bar
    bar_h = 56
    draw.rectangle([0, H - bar_h, W, H], fill=(20, 40, 75, 235))
    url_text = "petaname.web.app   -   Get it on Google Play"
    bbox = draw.textbbox((0, 0), url_text, font=font_url)
    tw = bbox[2] - bbox[0]
    draw.text(
        ((W - tw) // 2, H - bar_h + (bar_h - font_url.size) // 2 - 2),
        url_text,
        fill=(200, 215, 230),
        font=font_url,
    )

    # Save as RGB PNG
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    final = Image.new("RGB", (W, H), (30, 60, 110))
    final.paste(img, (0, 0), img)
    final.save(str(OUTPUT), "PNG", optimize=True)
    print(f"OGP image saved to: {OUTPUT}")


if __name__ == "__main__":
    main()
