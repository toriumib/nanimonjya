#!/usr/bin/env python3
"""
Generate OGP (Open Graph Protocol) image for social media sharing.
Creates a 1200×630 PNG optimized for Twitter Cards, Facebook, LINE, and Discord.

Usage:
  pip install Pillow
  python scripts/generate_ogp.py

Output: web/icons/ogp-image.png
"""

import os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

PROJECT_ROOT = Path(__file__).resolve().parent.parent
OUTPUT = PROJECT_ROOT / "web" / "icons" / "ogp-image.png"
ICON = PROJECT_ROOT / "web" / "icons" / "Icon-512.png"

W, H = 1200, 630
BG_COLOR = "#4A90D9"
ACCENT_COLOR = "#FFF9EC"
TEXT_COLOR = "#FFFFFF"

def find_font(size: int) -> ImageFont.FreeTypeFont:
    """Find an available Japanese-capable TrueType font."""
    candidates = [
        "C:\\Windows\\Fonts\\meiryo.ttc",
        "C:\\Windows\\Fonts\\msgothic.ttc",
        "/System/Library/Fonts/Helvetica.ttc",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]
    for path in candidates:
        if os.path.exists(path):
            return ImageFont.truetype(path, size=size)
    return ImageFont.load_default()


def main():
    img = Image.new("RGB", (W, H), BG_COLOR)
    draw = ImageDraw.Draw(img)

    # --- App icon ---
    icon_size = 140
    if ICON.exists():
        icon = Image.open(ICON).convert("RGBA")
        icon = icon.resize((icon_size, icon_size), Image.LANCZOS)
        # Rounded corners mask
        mask = Image.new("L", (icon_size, icon_size), 0)
        mask_draw = ImageDraw.Draw(mask)
        mask_draw.rounded_rectangle([0, 0, icon_size, icon_size], radius=32, fill=255)
        img.paste(icon, (60, (H - icon_size) // 2), mask if icon.mode == "RGBA" else None)
    else:
        print(f"Warning: {ICON} not found, skipping icon.")

    # --- Text ---
    font_title = find_font(56)
    font_subtitle = find_font(28)
    font_small = find_font(22)

    text_x = 60 + icon_size + 40 if ICON.exists() else 80
    max_text_w = W - text_x - 60

    # Wrap helper
    def draw_wrapped(draw, text, font, max_w, y, color, line_spacing=8):
        lines = []
        words = text.split()
        current = ""
        for word in words:
            test = f"{current} {word}".strip()
            bbox = draw.textbbox((0, 0), test, font=font)
            if bbox[2] - bbox[0] <= max_w:
                current = test
            else:
                if current:
                    lines.append(current)
                current = word
        if current:
            lines.append(current)
        for line in lines:
            draw.text((text_x, y), line, fill=color, font=font)
            y += font.size + line_spacing
        return y

    y = 150
    draw.text((text_x, y), "PetaName", fill=ACCENT_COLOR, font=font_title)
    y += font_title.size + 12

    draw.text(
        (text_x, y),
        "Face & Name Memory Training",
        fill=TEXT_COLOR,
        font=font_subtitle,
    )
    y += font_subtitle.size + 24

    # Tagline
    taglines = [
        "Never forget a name again.",
        "Train your memory with real faces, backed by cognitive science.",
        "Free on Android & Web.",
    ]
    for tag in taglines:
        draw.text((text_x, y), tag, fill=TEXT_COLOR, font=font_small)
        y += font_small.size + 6

    # --- Bottom bar ---
    draw.rectangle([0, H - 60, W, H], fill="#2c5f8a")
    font_bottom = find_font(20)
    draw.text(
        (40, H - 44),
        "petaname.web.app  ·  Google Play: com.nanimonjya",
        fill="#CCDDE8",
        font=font_bottom,
    )

    # --- Save ---
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(str(OUTPUT), "PNG", optimize=True)
    print(f"OGP image saved to: {OUTPUT}")


if __name__ == "__main__":
    main()
