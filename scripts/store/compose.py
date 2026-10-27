#!/usr/bin/env python3
"""App Store screenshots (S16.3, S18.16): real app screens under the approved captions.

The look follows the signed-off set on the S16 page (planning/mockups/S16/launch.html): an eyebrow and a headline
on top, alternating dark moss and sage backgrounds, and the app's screen in a dark frame that runs off the bottom.

    python3 scripts/store/compose.py <raw dir> <out dir> <set> [<set> ...]

<raw dir> holds one PNG per screen, named after the keys in SCREENS (home.png, sos.png, ...), captured from the
simulator. Each set is a size from SIZES; the iPhone sets read <raw>/iphone, the iPhone Duo ones <raw>/duo-cover and
<raw>/duo-inner. Output: <out dir>/<set>/<nn>-<key>.png, RGB with no alpha, as App Store Connect requires.
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

FONTS = os.path.join(os.path.dirname(__file__), "..", "..", "DayXeroCore", "Resources", "Fonts")

# key, eyebrow, headline, style ("d" dark moss, "s" sage). Copy approved by Milan on the S16 page.
SCREENS = [
    ("home", "DayXero", "Quit nicotine, one day at a time", "d"),
    ("sos", "Craving SOS", "Ride out a craving in three minutes", "s"),
    ("program", "Daily program", "Short daily lessons that build real skills", "d"),
    ("slip", "No resets", "A slip is one moment, not a restart", "s"),
    ("insights", "Insights", "See your patterns, then plan around them", "d"),
    ("nrt", "Smoking, vaping, pouches", "One app for every kind of nicotine", "s"),
]

# set: (width, height, raw folder). From App Store Connect's screenshot specifications.
SIZES = {
    "iphone-6.9": (1320, 2868, "iphone"),
    "iphone-6.3": (1206, 2622, "iphone"),
    "duo-cover": (1398, 2034, "duo-cover"),
    "duo-inner": (2007, 2853, "duo-inner"),
}

MOSS_TOP, MOSS_BOTTOM = (0x3A, 0x47, 0x19), (0x0A, 0x0C, 0x06)
SAGE_TOP, SAGE_BOTTOM = (0xE4, 0xE8, 0xCC), (0xBC, 0xC3, 0x88)
INK = (0x11, 0x14, 0x0A)
FRAME = (0x26, 0x26, 0x26)


def font(name, size):
    return ImageFont.truetype(os.path.join(FONTS, name), size)


def background(w, h, style):
    if style == "s":
        # Light sage, a little lighter at the top.
        mask = Image.linear_gradient("L").resize((w, h))
        return Image.composite(Image.new("RGB", (w, h), SAGE_BOTTOM), Image.new("RGB", (w, h), SAGE_TOP), mask)
    # Dark: a moss glow from the top centre fading to near-black by 70% of the way down.
    base = Image.new("RGB", (w, h), MOSS_BOTTOM)
    glow = Image.new("RGB", (w, h), MOSS_TOP)
    gw, gh = int(w * 2.4), int(h * 1.4)
    radial = Image.radial_gradient("L").resize((gw, gh))
    mask = Image.new("L", (w, h), 255)
    mask.paste(radial, ((w - gw) // 2, -gh // 2))
    return Image.composite(base, glow, mask)


def wrap(draw, text, face, width):
    lines, line = [], ""
    for word in text.split():
        trial = f"{line} {word}".strip()
        if draw.textlength(trial, font=face) <= width or not line:
            line = trial
        else:
            lines.append(line)
            line = word
    lines.append(line)
    return lines


def tracked(draw, xy, text, face, fill, tracking):
    """Draws text letter by letter with extra spacing, centred on xy[0]."""
    widths = [draw.textlength(c, font=face) for c in text]
    total = sum(widths) + tracking * (len(text) - 1)
    x = xy[0] - total / 2
    for c, cw in zip(text, widths):
        draw.text((x, xy[1]), c, font=face, fill=fill)
        x += cw + tracking


def compose(raw, w, h, eyebrow, headline, style):
    canvas = background(w, h, style)
    draw = ImageDraw.Draw(canvas)
    ink = (255, 255, 255) if style == "d" else INK
    quiet = (255, 255, 255, 153) if style == "d" else (17, 20, 10, 153)
    # Type sized to the width, but held back on short canvases such as iPhone Duo's cover.
    unit = min(w, h * 0.46)
    small = font("Inter-SemiBold.ttf", round(unit * 0.040))
    big = font("Inter-Bold.ttf", round(unit * 0.085))

    y = round(h * 0.045)
    overlay = Image.new("RGBA", (w, h))
    tracked(ImageDraw.Draw(overlay), (w / 2, y), eyebrow.upper(), small, quiet, unit * 0.040 * 0.1)
    canvas.paste(overlay, (0, 0), overlay)
    y += round(unit * 0.040 * 1.9)
    for line in wrap(draw, headline, big, w * 0.84):
        draw.text((w / 2, y), line, font=big, fill=ink, anchor="ma")
        y += round(unit * 0.085 * 1.15)
    y += round(unit * 0.06)

    # The screen in a dark frame with rounded top corners, running off the bottom edge: at least 81% of the width,
    # and wider if that's what it takes for the screen to reach the bottom (up to 92%).
    border = round(w * 0.81 * 0.035)
    reach_w = (h - y - border) * raw.width / raw.height + 2 * border
    frame_w = round(min(max(w * 0.81, reach_w), w * 0.92))
    radius = round(frame_w * 0.15)
    inner_w = frame_w - 2 * border
    screen = raw.convert("RGB").resize((inner_w, round(raw.height * inner_w / raw.width)), Image.LANCZOS)
    x = (w - frame_w) // 2
    # A screen too short to reach the bottom even at 92% ends in rounded corners, like the whole phone.
    bottom = h + radius if y + border + screen.height >= h else y + 2 * border + screen.height
    draw.rounded_rectangle((x, y, x + frame_w, bottom), radius=radius, fill=FRAME)
    mask = Image.new("L", screen.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, screen.width - 1, screen.height - 1 + (radius if bottom > h else 0)),
                                           radius=radius - border, fill=255)
    canvas.paste(screen, (x + border, y + border), mask)
    return canvas.convert("RGB")


def main():
    if len(sys.argv) < 4:
        sys.exit(__doc__)
    raw_dir, out_dir, sets = sys.argv[1], sys.argv[2], sys.argv[3:]
    missing = []
    for name in sets:
        w, h, folder = SIZES[name]
        os.makedirs(os.path.join(out_dir, name), exist_ok=True)
        for i, (key, eyebrow, headline, style) in enumerate(SCREENS, 1):
            path = os.path.join(raw_dir, folder, f"{key}.png")
            if not os.path.exists(path):
                missing.append(path)
                continue
            image = compose(Image.open(path), w, h, eyebrow, headline, style)
            assert image.size == (w, h) and image.mode == "RGB"
            image.save(os.path.join(out_dir, name, f"{i:02d}-{key}.png"))
            print(f"{name}/{i:02d}-{key}.png")
    if missing:
        sys.exit("Missing raw screens:\n" + "\n".join(missing))


if __name__ == "__main__":
    main()
