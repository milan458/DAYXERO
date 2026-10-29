#!/usr/bin/env python3
"""Build the Colour Lab's screens and colour list from the latest CI screenshots.

Reads the PNGs on the ci-screens branch (pushed by the iOS workflow), writes lossless
WebP thumbnails and full-size screens to tools/colour-lab/screens/, and scans the Swift
sources at the commit those screenshots were built from for brand-gradient colours.

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

from PIL import Image

HERE = Path(__file__).resolve().parent
OUT = HERE / "screens"
THUMB = (402, 874)

# (screenshot name on ci-screens, label, section). Dark mode, iPhone 6.3".
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

# The brand ramp the lab recolours: hue band in OKLCH degrees (matches the page's defaults).
BAND_CENTER, BAND_REACH = 122, 38
SWIFT_DIRS = ["DayXero", "DayXeroCore", "DayXeroWidgets", "WidgetViews", "Intents"]


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

    OUT.mkdir(exist_ok=True)
    screens = []
    for name, label, section in SCREENS:
        im = Image.open(io.BytesIO(git("show", f"{args.ref}:{name}.png", binary=True))).convert("RGB")
        im.save(OUT / f"{name}.webp", "WEBP", lossless=True, method=6)
        im.resize(THUMB, Image.LANCZOS).save(OUT / f"{name}.thumb.webp", "WEBP", lossless=True, method=6)
        screens.append({"id": name, "label": label, "section": section, "size": list(im.size)})
        print(f"  {name}  {im.size[0]}x{im.size[1]}")

    data = {
        "build": {"sha": sha, "date": date, "device": "iPhone 6.3-inch simulator", "appearance": "dark"},
        "screens": screens,
        "codeColours": brand_colours(sha),
    }
    (OUT / "screens.json").write_text(json.dumps(data, indent=1) + "\n")
    print(f"{len(screens)} screens and {len(data['codeColours'])} code colours from {sha} -> {OUT}")


if __name__ == "__main__":
    main()
