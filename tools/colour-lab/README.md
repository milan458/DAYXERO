# Colour Lab

A page for choosing the app's colours and fonts on real screenshots. It recolours 32 screens (dark mode, and light mode for the 21 that CI shoots in light) live: the sage → moss → deep gradient, the canvas and the text colour, for one screen, a selection, or all of them. It lists the Swift colour literals that would change. A Type tab rebuilds four screens in HTML so fonts can be compared next to the real screenshots.

```bash
pip install pillow numpy scipy
git fetch origin ci-screens
npm run colour-lab:build   # writes screens/ from the latest CI screenshots (iPhone 6.3")
npm run colour-lab         # http://localhost:4330
```

- `build.py` picks the screens (edit `SCREENS`; a light shot named `<name>-light` is picked up automatically), converts them to lossless WebP, and writes each screen's text layer: the local background and ink coverage of every text or icon pixel, so text colour can change without touching white buttons. It also scans the Swift code at the screenshots' commit for colours in the brand hue band.
- `index.html` does the recolouring in a WebGL shader. `recolour()` in the same file is the identical maths in JavaScript, used for the colour readout and the code export. Rendering reads pixels back from WebGL and recovers when the browser drops the graphics context.
- The hosted copy keeps the working look, saved looks and the final pick in its database, so Claude can read the final look and apply it to `DayXeroCore/DesignSystem/Colors.swift`, `Typography.swift` and the hard-coded gradients.
