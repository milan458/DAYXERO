#!/usr/bin/env python3
"""Build the Colour Lab's screens and colour list from the latest CI screenshots.

Reads the PNGs on the ci-screens branch (pushed by the iOS workflow) and writes, for each
dark screen and its light counterpart when CI shot one:

    <name>.webp / <name>.thumb.webp          the screenshot (lossless), full size and 1/3
    <name>.ink.webp / <name>.ink.thumb.webp  its text layer, see ink_layer()

It also scans the Swift sources at the commit those screenshots were built from for
brand-gradient colours. Needs Pillow, numpy and scipy.

    git fetch origin ci-screens
    python3 tools/colour-lab/build.py            # or: npm run colour-lab:build
"""
import argparse
import io
import json
import math
import re
import subprocess
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

HERE = Path(__file__).resolve().parent
OUT = HERE / "screens"
REDUCE = 3  # thumbnails are 1/3 size: 402 x 874 from 1206 x 2622

# (dark screenshot on ci-screens, label, section). iPhone 6.3".
SCREENS = [
    ("onb-welcome-dark", "Welcome", "Onboarding"),
    ("onb-products-dark", "What you use", "Onboarding"),
    ("onb-baseline_cigarettes-dark", "Cigarettes", "Onboarding"),
    ("onb-baseline_vape-dark", "Vape", "Onboarding"),
    ("onb-baseline_summary-dark", "Your baseline", "Onboarding"),
    ("onb-triggers-dark", "Triggers", "Onboarding"),
    ("onb-personal-dark", "Make it personal", "Onboarding"),
    ("onb-past_attempts-dark", "Past attempts", "Onboarding"),
    ("onb-nrt-dark", "Nicotine replacement", "Onboarding"),
    ("onb-quit_day-dark", "Quit Day", "Onboarding"),
    ("onb-reveal-dark", "Plan reveal", "Onboarding"),
    ("onb-trial-dark", "Free trial", "Onboarding"),
    ("pw-firstrun-dark", "First run", "Paywall"),
    ("pw-annual-dark", "Plan ready", "Paywall"),
    ("pw-unlocked-dark", "Unlocked", "Paywall"),
    ("home-prep-dark", "Prep week", "Today"),
    ("home-quitday-dark", "Quit Day", "Today"),
    ("home-day3-dark", "Day 3", "Today"),
    ("prog-tab-dark", "Program", "Program"),
    ("lesson-audio-dark", "Audio lesson", "Program"),
    ("sos-session-dark", "Craving SOS", "SOS"),
    ("sos-passed-dark", "Wave survived", "SOS"),
    ("prog-progress-dark", "Progress", "Progress"),
    ("health-smoking-dark", "Your body", "Progress"),
    ("ms-moment-dark", "Milestone", "Progress"),
    ("slip-plan-dark", "Slip plan", "Log"),
    ("nrt-plan-dark", "Patch plan", "Log"),
    ("daily-pledge-dark", "Daily pledge", "Daily"),
    ("toolkit-dark", "Toolkit", "Daily"),
    ("water-tracker-dark", "Water", "Daily"),
    ("set-main-dark", "Settings", "Settings"),
    ("widgets-home", "Widgets", "Settings"),
]
# Light shots named differently from "<name>-light".
LIGHT_ALIASES = {"onb-trial-dark": "onb-trial-mock-light"}

# The brand ramp the lab recolours: hue band in OKLCH degrees (matches the page's defaults).
BAND_CENTER, BAND_REACH = 122, 38
SWIFT_DIRS = ["DayXero", "DayXeroCore", "DayXeroWidgets", "WidgetViews", "Intents"]

# Text layer. The kernel is wider than any text stroke at 3x and narrower than chips and buttons.
KERNEL = 45
STATUS_BAR = 140                                 # rows of system status bar, never app text
LIGHT_INK = np.array([0x11, 0x14, 0x0A]) / 255   # DX.Palette.text in light mode


def git(*args, binary=False):
    out = subprocess.run(["git", *args], cwd=HERE.parent.parent, check=True, capture_output=True).stdout
    return out if binary else out.decode()


def oklch(hexv):
    def lin(c):
        c /= 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (lin((hexv >> s) & 255) for s in (16, 8, 0))
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s
    a = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s
    bb = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
    return L, math.hypot(a, bb), math.degrees(math.atan2(bb, a)) % 360


def ink_layer(rgb, dark_mode):
    """Split text and icons from what's behind them: rgb ~= B + a * (ink - B).

    Ink is white on dark screens and DX.Palette.text on light ones. B is the local background
    (a morphological opening or closing removes thin strokes), a the ink coverage. Coloured
    text, solid fills in the ink colour (buttons, chips, switch knobs) and the status bar get a = 0.
    Dark-mode text is always white; in light mode some screens (SOS, Water) stay dark.
    """
    lum = rgb @ np.array([0.2126, 0.7152, 0.0722])
    dark_ui = dark_mode or bool(np.median(lum) < 0.35)
    ink = np.ones(3) if dark_ui else LIGHT_INK
    op = ndi.grey_opening if dark_ui else ndi.grey_closing
    B = np.stack([op(rgb[..., c], size=(KERNEL, KERNEL)) for c in range(3)], -1)
    d = ink - B
    dd = (d * d).sum(-1)
    a = np.clip(((rgb - B) * d).sum(-1) / np.maximum(dd, 1e-4), 0, 1)
    resid = np.linalg.norm(rgb - B - a[..., None] * d, axis=-1)
    ok = (a > 0.04) & (resid < 0.035 + 0.05 * a) & (dd > 0.04)

    neutral = (rgb.max(-1) - rgb.min(-1)) < 0.09
    solid = neutral & ((lum > 0.55) if dark_ui else (lum < 0.25))
    lab, n = ndi.label(solid)
    fill = np.zeros(n + 1, bool)
    if n:
        area = np.bincount(lab.ravel())
        for i, sl in enumerate(ndi.find_objects(lab), 1):
            h, w = sl[0].stop - sl[0].start, sl[1].stop - sl[1].start
            fill[i] = area[i] > 15000 or (area[i] > 2500 and area[i] / (h * w) > 0.75)
    # Fill holes so letter counters inside a white chip count as chip, not text.
    fills = ndi.binary_dilation(ndi.binary_fill_holes(fill[lab]), iterations=4)
    a = np.where(ok & ~fills, a, 0)
    a[:STATUS_BAR] = 0
    return np.where(a[..., None] > 0, B, rgb), a, dark_ui


def save_ink(B, a, path):
    """Background colour and coverage side by side (no alpha channel, so browsers can't premultiply it)."""
    B = np.where(a[..., None] > 0, B, 0)
    img = np.concatenate([B, np.repeat(a[..., None], 3, -1)], 1)
    Image.fromarray(np.round(img * 255).astype(np.uint8)).save(path, "WEBP", lossless=True, method=4)


def write_screen(name, png, dark_mode):
    im = Image.open(io.BytesIO(png)).convert("RGB")
    im.save(OUT / f"{name}.webp", "WEBP", lossless=True, method=4)
    thumb = im.reduce(REDUCE)
    thumb.save(OUT / f"{name}.thumb.webp", "WEBP", lossless=True, method=4)

    rgb = np.asarray(im, dtype=np.float32) / 255
    B, a, dark_ui = ink_layer(rgb, dark_mode)
    save_ink(B, a, OUT / f"{name}.ink.webp")
    # Thumbnail layer: box averages, matching Image.reduce on the screenshot.
    h, w = (rgb.shape[0] // REDUCE) * REDUCE, (rgb.shape[1] // REDUCE) * REDUCE
    box = lambda x: x[:h, :w].reshape(h // REDUCE, REDUCE, w // REDUCE, REDUCE, *x.shape[2:]).mean((1, 3))
    save_ink(box(B), box(a), OUT / f"{name}.ink.thumb.webp")
    return {"file": name, "ui": "dark" if dark_ui else "light", "size": list(im.size)}


def brand_colours(sha):
    """Every 0xRRGGBB literal in the app's Swift code that sits in the sage/moss hue band."""
    found = []
    grep = git("grep", "-n", "-E", "0x[0-9A-Fa-f]{6}", sha, "--", *[f"{d}/*.swift" for d in SWIFT_DIRS])
    for row in grep.splitlines():
        _, path, line, code = row.split(":", 3)
        for m in re.finditer(r"0x([0-9A-Fa-f]{6})\b(?:\s*,\s*(?:opacity:\s*)?([01](?:\.\d+)?)(?![\dx]))?", code):
            hexv = int(m.group(1), 16)
            L, C, h = oklch(hexv)
            dist = abs((h - BAND_CENTER + 180) % 360 - 180)
            if C < 0.004 or dist > BAND_REACH:
                continue
            name = re.search(r"(?:let|var)\s+(\w+)\s*=", code) or re.search(r"case\s+\.(\w+)", code)
            side = re.findall(r"\b(light|dark):", code[:m.start()])
            found.append({
                "file": path, "line": int(line), "hex": f"#{m.group(1).upper()}",
                "alpha": float(m.group(2)) if m.group(2) else None,
                "name": name.group(1) if name else None,
                "appearance": side[-1] if side else None,
                "code": code.strip()[:160],
            })
    return found


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--ref", default="origin/ci-screens", help="branch holding the CI screenshots")
    args = ap.parse_args()

    subject = git("log", "-1", "--format=%s", args.ref).strip()
    date = git("log", "-1", "--format=%cI", args.ref).strip()
    sha = re.search(r"for ([0-9a-f]{7,})", subject).group(1)
    available = set(git("ls-tree", "--name-only", args.ref).split())

    OUT.mkdir(exist_ok=True)
    screens = []
    for name, label, section in SCREENS:
        light = LIGHT_ALIASES.get(name, name.replace("-dark", "-light"))
        entry = {"id": name, "label": label, "section": section,
                 "dark": write_screen(name, git("show", f"{args.ref}:{name}.png", binary=True), True),
                 "light": None}
        if light != name and f"{light}.png" in available:
            entry["light"] = write_screen(light, git("show", f"{args.ref}:{light}.png", binary=True), False)
        screens.append(entry)
        print(f"  {name:32s} light: {entry['light']['file'] if entry['light'] else '-'}")

    data = {
        "build": {"sha": sha, "date": date, "device": "iPhone 6.3-inch simulator"},
        "screens": screens,
        "codeColours": brand_colours(sha),
    }
    (OUT / "screens.json").write_text(json.dumps(data, indent=1) + "\n")
    lights = sum(1 for s in screens if s["light"])
    print(f"{len(screens)} screens ({lights} with light mode) and {len(data['codeColours'])} code colours from {sha} -> {OUT}")


if __name__ == "__main__":
    main()
