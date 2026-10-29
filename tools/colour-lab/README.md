# Colour Lab

A page for choosing the app's colour gradient on real screenshots. It recolours the sage → moss → deep ramp (and the dark canvas) of 32 dark-mode screens live, for one screen, a selection, or all of them, and lists the Swift colour literals that would change.

```bash
git fetch origin ci-screens
npm run colour-lab:build   # writes screens/ from the latest CI screenshots (iPhone 6.3", dark)
npm run colour-lab         # http://localhost:4330
```

- `build.py` picks the screens (edit `SCREENS` to change the set), converts them to lossless WebP, and scans the Swift code at the screenshots' commit for colours in the brand hue band.
- `index.html` does the recolouring in a WebGL shader. `transfer()` in the same file is the identical maths in JavaScript, used for the colour readout and the code export.
- The hosted copy keeps the working look, saved looks and the final pick in its database, so Claude can read the final look and apply it to `DayXeroCore/DesignSystem/Colors.swift` and the hard-coded gradients.
