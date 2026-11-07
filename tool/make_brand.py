"""Generates the TakaTally brand mark and every icon surface it feeds.

Run from the project root:  python tool/make_brand.py

The mark is a five-stroke tally: four lime strokes with one gold stroke
crossing them. It reads as "count" at 16 px and is deliberately nothing
like the circled currency glyph used by other taka apps.

Outputs:
  assets/images/app_icon.png                 1024  legacy launcher icon
  assets/images/app_icon_foreground.png      1024  adaptive foreground (alpha)
  assets/images/app_icon_monochrome.png      1024  Android 13 themed icon (alpha)
  android/app/src/main/res/drawable-*/splash_logo.png
  web/favicon.png
  web/icons/Icon-192.png / Icon-512.png
  web/icons/Icon-maskable-192.png / Icon-maskable-512.png
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
IMAGES = ROOT / "assets" / "images"
WEB_ICONS = ROOT / "web" / "icons"
RES = ROOT / "android" / "app" / "src" / "main" / "res"

FOREST = (23, 63, 46)
FOREST_DEEP = (14, 42, 30)
FOREST_LIGHT = (32, 82, 59)
LIME = (199, 243, 107)
GOLD = (241, 199, 91)

SS = 4  # supersample factor for clean curves


# --------------------------------------------------------------------------
# helpers
# --------------------------------------------------------------------------


def linear_gradient(size: int, top, bottom, angle: float = 135.0) -> Image.Image:
    """Directional gradient rendered small, then scaled up."""
    small = 256
    layer = Image.new("RGB", (small, small))
    draw = ImageDraw.Draw(layer)
    rad = math.radians(angle)
    dx, dy = math.cos(rad), math.sin(rad)
    # Projection range across the square.
    projs = [
        x * dx + y * dy
        for x in (0, small)
        for y in (0, small)
    ]
    lo, hi = min(projs), max(projs)
    for y in range(small):
        for x in range(small):
            t = ((x * dx + y * dy) - lo) / (hi - lo)
            layer.putpixel(
                (x, y),
                tuple(round(top[i] + (bottom[i] - top[i]) * t) for i in range(3)),
            )
    return layer.resize((size, size), Image.BICUBIC).convert("RGBA")


def radial_glow(size: int, centre, radius, colour, alpha) -> Image.Image:
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    x, y = centre
    draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=(*colour, alpha))
    return layer.filter(ImageFilter.GaussianBlur(radius * 0.55))


def dot_texture(size: int, colour, alpha, spacing: int, dot: float) -> Image.Image:
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    for y in range(0, size, spacing):
        for x in range(0, size, spacing):
            draw.ellipse((x, y, x + dot, y + dot), fill=(*colour, alpha))
    return layer


def rounded_mask(size: int, radius: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size - 1, size - 1), radius=radius, fill=255
    )
    return mask


def cap_line(draw: ImageDraw.ImageDraw, start, end, width: int, fill) -> None:
    """Line with clean round caps."""
    draw.line((*start, *end), fill=fill, width=width)
    r = width / 2
    for x, y in (start, end):
        draw.ellipse((x - r, y - r, x + r, y + r), fill=fill)


# --------------------------------------------------------------------------
# the mark
# --------------------------------------------------------------------------


def draw_tally(
    draw: ImageDraw.ImageDraw,
    size: int,
    *,
    origin=(0.0, 0.0),
    scale=1.0,
    bar_colour=LIME,
    slash_colour=GOLD,
    shadow: bool = False,
    monochrome=None,
) -> None:
    """Draw the five-stroke tally inside a size x size box."""
    unit = size * scale
    ox = origin[0] * size + (size - unit) / 2
    oy = origin[1] * size + (size - unit) / 2

    def px(x: float, y: float) -> tuple[float, float]:
        return ox + x * unit, oy + y * unit

    bar_w = unit * 0.078
    bar_h = unit * 0.415
    centre_y = 0.505
    centres = (0.343, 0.446, 0.549, 0.652)
    slash = ((0.292, 0.286), (0.708, 0.724))  # (x1, y1) -> (x2, y2)

    bars = (
        bar_colour if monochrome is None else monochrome,
        bar_colour if monochrome is None else monochrome,
        bar_colour if monochrome is None else monochrome,
        bar_colour if monochrome is None else monochrome,
    )
    slash_fill = slash_colour if monochrome is None else monochrome

    if shadow:
        off = unit * 0.014
        for index, cx in enumerate(centres):
            x, y = px(cx, centre_y)
            draw.rounded_rectangle(
                (
                    x - bar_w / 2 + off,
                    y - bar_h / 2 + off,
                    x + bar_w / 2 + off,
                    y + bar_h / 2 + off,
                ),
                radius=bar_w / 2,
                fill=(*FOREST_DEEP, 58),
            )
        cap_line(
            draw,
            px(slash[0][0] + 0.014, slash[0][1] + 0.014),
            px(slash[1][0] + 0.014, slash[1][1] + 0.014),
            round(bar_w),
            (*FOREST_DEEP, 58),
        )

    for index, cx in enumerate(centres):
        x, y = px(cx, centre_y)
        draw.rounded_rectangle(
            (x - bar_w / 2, y - bar_h / 2, x + bar_w / 2, y + bar_h / 2),
            radius=bar_w / 2,
            fill=bars[index] + ((255,) if len(bars[index]) == 3 else ()),
        )

    cap_line(
        draw,
        px(*slash[0]),
        px(*slash[1]),
        round(bar_w),
        slash_fill + ((255,) if len(slash_fill) == 3 else ()),
    )


# --------------------------------------------------------------------------
# surfaces
# --------------------------------------------------------------------------


def build_legacy_icon() -> Path:
    size = 1024
    big = size * SS
    canvas = linear_gradient(big, FOREST_LIGHT, FOREST_DEEP, angle=128.0)
    canvas.alpha_composite(radial_glow(big, (big * 0.80, big * 0.16), big * 0.46, LIME, 64))
    canvas.alpha_composite(radial_glow(big, (big * 0.12, big * 0.92), big * 0.40, GOLD, 26))
    canvas.alpha_composite(dot_texture(big, (255, 255, 255), 12, SS * 29, SS * 1.5))

    draw = ImageDraw.Draw(canvas)
    draw_tally(draw, big, scale=1.16, shadow=True)

    canvas.putalpha(rounded_mask(big, round(big * 0.215)))
    icon = canvas.resize((size, size), Image.LANCZOS)
    path = IMAGES / "app_icon.png"
    icon.save(path, "PNG", optimize=True)
    return path


def build_foreground() -> Path:
    size = 1024
    big = size * SS
    canvas = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    draw_tally(draw, big, scale=0.90)
    foreground = canvas.resize((size, size), Image.LANCZOS)
    path = IMAGES / "app_icon_foreground.png"
    foreground.save(path, "PNG", optimize=True)
    return path


def build_monochrome() -> Path:
    size = 1024
    big = size * SS
    canvas = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    draw_tally(draw, big, scale=0.90, monochrome=(255, 255, 255))
    monochrome = canvas.resize((size, size), Image.LANCZOS)
    path = IMAGES / "app_icon_monochrome.png"
    monochrome.save(path, "PNG", optimize=True)
    return path


def build_splash() -> list[Path]:
    paths: list[Path] = []
    for folder, pixels in (
        ("drawable-mdpi", 108),
        ("drawable-hdpi", 162),
        ("drawable-xhdpi", 216),
        ("drawable-xxhdpi", 324),
        ("drawable-xxxhdpi", 432),
    ):
        big = pixels * SS
        canvas = Image.new("RGBA", (big, big), (0, 0, 0, 0))
        draw = ImageDraw.Draw(canvas)
        draw_tally(draw, big, scale=1.0)
        splash = canvas.resize((pixels, pixels), Image.LANCZOS)
        target = RES / folder / "splash_logo.png"
        target.parent.mkdir(parents=True, exist_ok=True)
        splash.save(target, "PNG", optimize=True)
        paths.append(target)
    return paths


def build_web_icon(pixels: int, maskable: bool) -> Image.Image:
    big = pixels * SS
    canvas = linear_gradient(big, FOREST_LIGHT, FOREST_DEEP, angle=128.0)
    canvas.alpha_composite(radial_glow(big, (big * 0.80, big * 0.16), big * 0.46, LIME, 64))
    canvas.alpha_composite(dot_texture(big, (255, 255, 255), 12, SS * 29, SS * 1.5))
    draw = ImageDraw.Draw(canvas)
    # Maskable icons keep the mark inside the 80% safe circle.
    draw_tally(draw, big, scale=0.95 if maskable else 1.14)
    if maskable:
        canvas.putalpha(rounded_mask(big, 0))
    else:
        canvas.putalpha(rounded_mask(big, round(big * 0.215)))
    return canvas.resize((pixels, pixels), Image.LANCZOS)


def build_web() -> list[Path]:
    WEB_ICONS.mkdir(parents=True, exist_ok=True)
    paths: list[Path] = []
    for pixels, maskable in (
        (192, False),
        (512, False),
        (192, True),
        (512, True),
    ):
        suffix = "-maskable" if maskable else ""
        path = WEB_ICONS / f"Icon{suffix}-{pixels}.png"
        build_web_icon(pixels, maskable).save(path, "PNG", optimize=True)
        paths.append(path)

    favicon = build_web_icon(64, False).resize((32, 32), Image.LANCZOS)
    path = ROOT / "web" / "favicon.png"
    favicon.save(path, "PNG", optimize=True)
    paths.append(path)
    return paths


def main() -> None:
    outputs = [
        build_legacy_icon(),
        build_foreground(),
        build_monochrome(),
        *build_splash(),
        *build_web(),
    ]
    for path in outputs:
        print(f"brand  {path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
