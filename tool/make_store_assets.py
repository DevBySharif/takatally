"""Builds the Google Play Store artwork from the app's own screenshots.

Run from the project root:  python tool/make_store_assets.py

Outputs:
  store/icon-512.png
  store/feature-graphic-1024x500.png
  store/screenshots/01..08-*.png        (1080x1920, English captions)
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
SHOTS = ROOT / "screenshots"
OUT = ROOT / "store"
SHOT_OUT = OUT / "screenshots"
FONTS = ROOT / "assets" / "fonts"
IMAGES = ROOT / "assets" / "images"

CREAM = (246, 242, 232)
CREAM_SOFT = (250, 247, 239)
FOREST = (23, 63, 46)
FOREST_DEEP = (14, 42, 31)
LIME = (199, 243, 107)
LIME_SOFT = (234, 246, 205)
GOLD = (240, 194, 106)
INK_SOFT = (92, 107, 98)

CANVAS = (1080, 1920)
SHOT_WIDTH = 780
SHOT_HEIGHT = 1688


def font(weight: int, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONTS / f"Manrope-{weight}.ttf"), size)


def vertical_gradient(size: tuple[int, int], top, bottom) -> Image.Image:
    width, height = size
    strip = Image.new("RGB", (1, height))
    for y in range(height):
        t = y / max(height - 1, 1)
        strip.putpixel(
            (0, y),
            tuple(round(top[i] + (bottom[i] - top[i]) * t) for i in range(3)),
        )
    return strip.resize(size, Image.BILINEAR).convert("RGBA")


def glow(size: tuple[int, int], centre, radius, colour, alpha) -> Image.Image:
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    x, y = centre
    draw.ellipse(
        (x - radius, y - radius, x + radius, y + radius),
        fill=(*colour, alpha),
    )
    return layer.filter(ImageFilter.GaussianBlur(radius // 3))


def dotted(size: tuple[int, int], colour, alpha, spacing=26, dot=1.6) -> Image.Image:
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    for y in range(0, size[1], spacing):
        for x in range(0, size[0], spacing):
            draw.ellipse(
                (x, y, x + dot, y + dot),
                fill=(*colour, alpha),
            )
    return layer


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size[0] - 1, size[1] - 1),
        radius=radius,
        fill=255,
    )
    return mask


def draw_tracked(
    draw: ImageDraw.ImageDraw,
    xy: tuple[int, int],
    text: str,
    text_font: ImageFont.FreeTypeFont,
    fill,
    tracking: float,
) -> int:
    x, y = xy
    for char in text:
        draw.text((x, y), char, font=text_font, fill=fill)
        x += draw.textlength(char, font=text_font) + tracking
    return x


def compose_screenshot(source: Path, headline: str, index: int) -> Path:
    canvas = vertical_gradient(CANVAS, CREAM_SOFT, (240, 245, 222))
    canvas.alpha_composite(glow(CANVAS, (980, 180), 430, LIME, 90))
    canvas.alpha_composite(glow(CANVAS, (60, 1860), 420, GOLD, 40))
    canvas.alpha_composite(dotted(CANVAS, FOREST, 14, spacing=28, dot=1.5))

    draw = ImageDraw.Draw(canvas)

    # Caption block ---------------------------------------------------------
    draw_tracked(
        draw,
        (68, 66),
        "TAKA COUNTER",
        font(700, 20),
        (23, 63, 46, 190),
        4.6,
    )
    draw.rounded_rectangle((68, 104, 128, 112), radius=4, fill=(*LIME, 255))
    draw.multiline_text(
        (66, 136),
        headline,
        font=font(800, 62),
        fill=(*FOREST, 255),
        spacing=14,
    )

    # Screenshot card -------------------------------------------------------
    shot = Image.open(source).convert("RGB").resize(
        (SHOT_WIDTH, SHOT_HEIGHT), Image.LANCZOS
    )
    top = 356
    card_height = CANVAS[1] - top
    scale = card_height / SHOT_HEIGHT
    shot = shot.resize((round(SHOT_WIDTH * scale), card_height), Image.LANCZOS)
    radius = 30
    mask = rounded_mask(shot.size, radius)

    shadow = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        (
            (CANVAS[0] - shot.width) // 2 - 2,
            top - 2,
            (CANVAS[0] + shot.width) // 2 + 2,
            CANVAS[1] + 6,
        ),
        radius=radius,
        fill=(*FOREST_DEEP, 70),
    )
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(26)))

    x = (CANVAS[0] - shot.width) // 2
    canvas.paste(shot, (x, top), mask)
    draw.rounded_rectangle(
        (x, top, x + shot.width - 1, CANVAS[1] - 1),
        radius=radius,
        outline=(*FOREST, 26),
        width=2,
    )

    SHOT_OUT.mkdir(parents=True, exist_ok=True)
    name = f"{index:02d}-{source.stem.split('_', 1)[-1].replace('_', '-')}.png"
    path = SHOT_OUT / name
    canvas.convert("RGB").save(path, "PNG", optimize=True)
    return path


def build_icon() -> Path:
    OUT.mkdir(parents=True, exist_ok=True)
    icon = Image.open(IMAGES / "app_icon.png").convert("RGBA")
    icon.resize((512, 512), Image.LANCZOS).save(
        OUT / "icon-512.png", "PNG", optimize=True
    )
    return OUT / "icon-512.png"


def build_feature() -> Path:
    size = (1024, 500)
    canvas = vertical_gradient(size, FOREST_DEEP, (30, 74, 54))
    canvas.alpha_composite(glow(size, (900, 90), 320, LIME, 60))
    canvas.alpha_composite(glow(size, (120, 460), 260, GOLD, 28))
    canvas.alpha_composite(dotted(size, (255, 255, 255), 16, spacing=24, dot=1.4))

    draw = ImageDraw.Draw(canvas)
    draw.text((812, 84), "৳", font=font(800, 340), fill=(*LIME, 26))

    icon = Image.open(IMAGES / "app_icon.png").convert("RGBA").resize(
        (150, 150), Image.LANCZOS
    )
    icon_mask = rounded_mask(icon.size, 34)
    canvas.paste(icon, (100, 175), icon_mask)

    draw.text((282, 158), "Taka Counter", font=font(800, 66), fill=(255, 255, 255, 255))
    draw.text(
        (284, 244),
        "Cash counting, made calm.",
        font=font(600, 26),
        fill=(*LIME, 255),
    )
    draw.text(
        (284, 292),
        "Offline  ·  Private  ·  Made for Bangladesh",
        font=font(500, 19),
        fill=(255, 255, 255, 150),
    )
    draw.rounded_rectangle(
        (284, 336, 546, 380),
        radius=22,
        fill=(255, 255, 255, 22),
        outline=(255, 255, 255, 40),
        width=1,
    )
    draw.text(
        (306, 347),
        "No ads. No account.",
        font=font(700, 17),
        fill=(*LIME, 235),
    )

    path = OUT / "feature-graphic-1024x500.png"
    canvas.convert("RGB").save(path, "PNG", optimize=True)
    return path


SCREENS = [
    ("01_home_light", "Every taka,\nclear at a glance."),
    ("02_counter", "One count,\nall your entries."),
    ("03_add_entry", "Type it.\nSkip the taps."),
    ("07_note_counter_filled", "Notes and coins,\ncounted your way."),
    ("17_breakdown", "Know exactly\nwhat's inside."),
    ("04_history", "Past counts,\none tap away."),
    ("15_voucher", "Hand over a\nclean voucher."),
    ("16_settings_data", "Offline by design.\nYours by default."),
]


def main() -> None:
    icon = build_icon()
    feature = build_feature()
    print(f"icon     {icon.relative_to(ROOT)}")
    print(f"feature  {feature.relative_to(ROOT)}")
    for index, (stem, headline) in enumerate(SCREENS, start=1):
        output = compose_screenshot(SHOTS / f"{stem}.png", headline, index)
        print(f"screen   {output.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
