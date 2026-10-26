# DayXero Bio-Orb — Component Spec (final)

Owner: Milan · Visual and motion signed off: 24 Oct 2026 · Platform: iOS 18+, SwiftUI
Used in: Section 6 (Craving SOS) and Section 12 (Stress and anxiety toolkit)
Reference: `reference/bio-orb-preview.html`. This is the browser preview Milan signed off. Open it in Safari to see the exact look and motion.

This file replaces the earlier "DayXero AI Bio-Orb" prompt, its JSON payload and its SwiftUI reference code. Don't use any of those. Where this spec and the preview differ (copy, labels, badge timing, end states), this spec wins. Where DESIGN_METHODOLOGY.md conflicts with this spec, flag it to Milan; don't silently change the orb.

---

## 0. How this fits the handoff plan

- Add these tasks to the tracker under Section 6, with the note "from DAYXERO_BIO_ORB_SPEC.md":
  - **S6.7** Build `BioOrbView` + `OrbEngine` per this spec.
  - **S6.8** Add the orb (full and mini, all states) to the S1.4 component gallery.
  - **S6.9** Wire the orb into the SOS screen (3-minute session, S6.3 outcomes).
  - **S12.4** Reuse the orb for the breathing exercises in the stress toolkit.
  - **S6.10 (`blocked`)** Milan to confirm the coach copy and labels in section 9.
- The orb's look and motion are already signed off, so you don't need fresh orb mockups. The SOS and toolkit *screens* around it still go through the normal Section 6 and 12 mockup gate.
- The voice is scripted lines read by on-device text-to-speech (`AVSpeechSynthesizer`). It is **not** the AI coach, which stays out of scope for v1. Nothing in this component calls a server.

---

## 1. Anatomy (back to front)

There is no bezel, no housing, no recessed well, no hairline border and no highlight arc. The orb is a glowing ring floating on the black screen with a dark lens in its centre. Don't add any circle outlines.

| # | Layer | Blend |
|---|---|---|
| 1 | Moss halo (soft glow that breathes with the ring) | normal |
| 2 | Four plasma rings | **screen** |
| 3 | Dark centre lens with a feathered edge | normal |
| 4 | Readout text (label, numeral, cycle row with waveform bars) | normal |

Below the orb: the transcript pill. Below that, the screen's own controls.

Background: pure black `#000000`.

---

## 2. Geometry

`S` = orb size in points. **Full = 320**, **Mini = 180**. If the container is narrower, `S = min(target, containerWidth − 36)`.

```
centre       = (S/2, S/2)
ringBaseR    = S × 0.3432 × breathScale        // 0.3432 = 0.44 × 0.78
haloInnerR   = ringBaseR × 0.40
haloOuterR   = ringBaseR × 1.25
lensR        = ringBaseR × 0.80
lensDrawR    = lensR × 1.06                    // the gradient feathers out to here
```

Drawing can extend past `S` (glow, halo at inhale). Don't clip the canvas to a circle; give the orb's frame room or allow overflow.

---

## 3. Layers in detail

### 3.1 Moss halo
A filled circle of radius `haloOuterR`, with a radial gradient centred on the orb from `haloInnerR` to `haloOuterR`:

| stop | colour |
|---|---|
| 0.00 | `#43511C` @ 0.42 |
| 0.70 | `#BCC388` @ 0.18 |
| 1.00 | `#BCC388` @ 0.00 |

Inside `haloInnerR` the first colour fills (the lens covers it anyway). No clipping.

### 3.2 Plasma rings
Four closed paths, each with 120 segments (121 points, then close), stroked with **screen** blending and round joins.

| Layer | Role | Stroke colour | Width full / mini | Glow colour | Glow full / mini | amp | freq1 | freq2 | speed | radiusMult |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | Moss sub-aura | `#43511C` @ 0.75 | 24 / 14 | `#BCC388` | 18 / 10 | 5.5 | 3 | 5 | +1.1 | 1.030 |
| 1 | Outer sage wave | `#BCC388` @ 0.65 | 12 / 7 | `#BCC388` | 12 / 6 | 4.2 | 4 | 7 | −1.5 | 1.000 |
| 2 | Talking harmonic | `#BCC388` @ 0.90 | 5.5 / 3.5 | `#BCC388` | 6 / 3 | 3.2 | 5 | 9 | +2.2 | 0.985 |
| 3 | White filament | `#FFFFFF` @ 0.92 | 2.6 / 1.8 | `#FFFFFF` | 3 / 1 | 2.4 | 6 | 11 | −2.6 | 0.975 |

For each layer `idx` and vertex `i` in `0...120`:

```
θ          = (i / 120) × 2π
speechMod  = (sin(T × 11 + idx) × 0.5 + 0.5) × E
w1 = sin(θ × freq1 + T × speed)        × amp        × (0.4 + speechMod)
w2 = cos(θ × freq2 − T × speed × 1.3)  × (amp × 0.6) × speechMod
w3 = sin(θ × 2 + T × 0.7)              × 2
r  = ringBaseR × radiusMult + w1 + w2 + w3
point = centre + (cos θ, sin θ) × r
lineWidth = width × (1 + E × 0.22)
```

`T` is `orbTime` and `E` is the smoothed speech energy (section 4).

**The glow is a shadow, not a blurred stroke.** The preview uses canvas `shadowBlur`: a crisp line with a soft halo around it. In SwiftUI, use `GraphicsContext.addFilter(.shadow(color: glowColour, radius: …))` on a copy of the context for each ring, or draw a blurred copy first and the crisp stroke on top. Don't blur the stroke itself, because the bright core is part of the look. Canvas `shadowBlur` is about 2σ, so start the SwiftUI shadow radius at glow ÷ 2 and match it side by side with the preview.

### 3.3 Dark centre lens
Drawn after the rings with normal blending. A filled circle of radius `lensDrawR` with a radial gradient **centred on the orb**:

| stop | colour |
|---|---|
| 0.00 | `#10160A` |
| 0.55 | `#070A04` |
| 0.90 | `#040602` @ 1.0 |
| 1.00 | `#040602` @ 0.0 |

No stroke, no highlight arc. The feathered edge is what keeps the inner rings from showing.

### 3.4 Readout (centred)
A centred vertical stack, centred on the orb. It is a **fixed size**: it doesn't scale with the breath and doesn't move. Every line is horizontally centred.

The label row and the cycle row are the **same height** and sit at the **same gap** from the numeral, so the numeral is exactly halfway between them. Measure the gap from the top and bottom of the digits (cap height), not from the text frame. Check by overlaying a screenshot on the preview.

| Element | Full | Mini |
|---|---|---|
| Label, e.g. `4 seconds · inhale` | Inter Medium 12pt, row height 14, `#BCC388` @ 0.85, lowercase | 8.5pt, row height 10 |
| Gap | 8 | 4 |
| Numeral (breathing: seconds left in phase) | Inter ExtraBold 48pt, white, tracking −0.02em, tabular digits | 24pt |
| Numeral (SOS: `mm:ss` of the session) | Inter ExtraBold 40pt | 19pt |
| Gap | 8 | 4 |
| Cycle row: `CYCLE 1 OF 4` + bars, centred as one group | JetBrains Mono SemiBold 10pt, uppercase, tracking 0.06em, white @ 0.40, row height 14; 6pt between text and bars | 7pt, tracking 0.03em, row height 10; 4pt gap |
| Waveform bars | 4 bars, 2.5pt wide, 2pt apart, corner radius 2, max height 12; colours alternate `#BCC388`, `#FFFFFF`, `#BCC388`, `#FFFFFF` | 2pt wide, max height 7 |

The label shows the **phase length**, not the countdown: `4 seconds · inhale`, `7 seconds · hold`, `8 seconds · exhale`.

Bar height per frame, for bar `b` in `0...3`:
```
h = 3 + (maxH − 3) × min(1, E × 1.2) × (0.35 + 0.65 × |sin(T × k + b × 1.3)|)
k = 6.5 while the coach is speaking, otherwise 2.2
```

Fonts: bundle Inter (500, 800) and JetBrains Mono (600). Both are under the SIL Open Font License, so include the licence files.

The whole stack must stay inside the lens at the smallest breath scale (0.82). The sizes above were checked for that, so don't increase them.

### 3.5 Transcript pill
- Sits 24pt below the orb. Full width of the content column.
- Background `#FFFFFF`, corner radius 28, padding top 11, right 12, bottom 11, left 16. Grows to fit the text.
- Status dot: 8pt black circle. While the coach is speaking it pulses 0.85 → 1.25 → 0.85 over 1s, ease-in-out; static at 0.85 under Reduce Motion.
- Transcript: 12pt semibold, black. **Wraps; never truncate.** Coaching lines are about 140 characters.
- Badge: JetBrains Mono SemiBold 9pt, black text on `#BCC388`, capsule, padding 4 × 8. Text per section 9.
- Announce transcript changes to VoiceOver (live region behaviour).

---

## 4. Animation engine (per frame)

Put all animated state in a reference type (`@Observable final class OrbEngine`) and advance it **once per frame** from `TimelineView(.animation)` using the real time since the last frame. Draw with `Canvas`.

Hard rules (each one was a bug in the old reference code):
1. **Don't use `withAnimation` for the breath scale.** `Canvas` reads the final value straight away, so the rings snap. Ease the scale per frame as below.
2. **Don't use the absolute date as `orbTime`.** It advances 0.035 per 60fps frame (2.1 per second). Using seconds makes everything move at half speed.
3. **Smooth the speech energy.** Don't feed the raw syllable wave to the rings.
4. Normalise by frame time so 120Hz ProMotion devices move at the same speed as 60Hz ones.

```
dt = min(now − last, 0.050)              // seconds; clamp after stalls
k  = dt / (1/60)

orbTime += 0.035 × k

target = scaleTargets[pattern][phase]
if phase == .hold { target += sin(orbTime × 2.5) × 0.015 }
if sosFinished    { target = 0.86 }
breathScale += (target − breathScale) × (1 − pow(1 − 0.035, k))

syllable = coachSpeaking
         ? 0.45 + |sin(orbTime × 4.8) × cos(orbTime × 2.3)| × 0.65
         : 0.22 + sin(orbTime × 1.5) × 0.08
E += (syllable − E) × (1 − pow(1 − 0.12, k))

initial: breathScale = 0.90, E = 0.30, orbTime = 0
```

Plus a short **phase ripple**: for 2.2s after every phase change, treat `coachSpeaking` as true **for the motion only** (rings and bars), not for the badge or dot. See section 5.

Mutating the engine inside the `TimelineView` closure is fine as long as it isn't `@State` being written during `body`. Advance the engine in a method the closure calls and read the values back.

### Reduce Motion
- The ring waves are off: `r = ringBaseR × radiusMult` (no w1, w2 or w3).
- `E` is fixed at 0.10 for line widths. Bars sit still at 4pt.
- The breath scale still eases, because the expanding and contracting ring is the breathing instruction. It's slow and not decorative.
- `TimelineView` can drop to `.animation(minimumInterval: 1/30)`.

---

## 5. Session logic

### Phases
Order: Inhale → Hold → Exhale → Rest, skipping any phase with 0 seconds. When it wraps back to Inhale, `cycle += 1`.

Ticks every 1 second (drive this from the same clock as the engine, not a separate `Timer` on the main run loop). Each tick: `remaining −= 1`; at 0, go to the next phase and set `remaining` to the new phase's length.

On phase change:
- Start the 2.2s motion ripple.
- If no coaching line is playing, set the transcript to `phaseScripts[phase][cycle % count]`.
- Play that phase's haptic (section 6).
- Post a VoiceOver announcement: "Inhale, 4 seconds".

### Breathing exercise (Section 12)
- Starts on Inhale, cycle 1, with the transcript `phaseScripts.Inhale[0]`.
- Ends after `recommendedCycles` complete. Hold the ring at 0.86, show the label `done`, the numeral `✓` and the transcript `Nice work. You finished {N} cycles.` Then show the screen's done or repeat actions (from Section 12 mockups). It doesn't loop forever.

### Craving SOS (Section 6)
- Session length 180s (S6.1). The numeral shows `mm:ss` of the session; the label still shows the phase.
- The pattern defaults to `wave`; the user can change it.
- Coaching lines fire automatically at 180s left (`sos_start`), 90s left (`mid_session`) and 30s left (`near_completion`).
- At 0: stop, hold the ring at 0.86, label `urge surfed`, numeral `00:00`, transcript `Three minutes done. Did the craving pass?` Then show the S6.3 outcomes (It passed / I slipped / Ping a friend).
- Log the session per S6.6.

### Coaching lines
- Tapping the orb, or the coach button, plays the next line in rotation.
- While a line is active: `coachSpeaking = true`, the transcript shows the line and **isn't overwritten by phase changes**, the badge shows the speaking label and the dot pulses.
- A line ends when speech finishes (`didFinish` / `didCancel`). If voice is off, it ends after `durationSeconds` and shows as a caption only.
- Starting a new line cancels the current one.

### Lifecycle
- The session starts when the screen appears (SOS) or when the user taps Start (toolkit). Don't start it in `init`.
- On disappear, or when `scenePhase` leaves `.active`: pause the clock, stop speech, stop haptics. On return: resume paused, with a Resume control. The Live Activity (S6.4) is separate and keeps its own countdown.

---

## 6. Voice and haptics

### Voice (`AVSpeechSynthesizer`)
- Voice `en-US`, `rate` 0.46 (on the AVSpeech scale; the preview's 0.92 is the Web Speech scale), `pitchMultiplier` 0.96.
- Before speaking: `AVAudioSession` category `.playback`, mode `.spokenAudio`, options `[.duckOthers]`, so it plays with the silent switch on. Deactivate with `.notifyOthersOnDeactivation` when a line ends.
- A "Voice guidance" toggle in Settings (add to S15.1), default **on**. When it's off, lines show as captions with the same timing.

### Haptics (Core Haptics)
- Per phase: one continuous event lasting the phase, intensity ramping from `intensityStart` to `intensityEnd` (use a `CHHapticParameterCurve`), with the phase's `sharpness`. All values are in the data file.
- SOS (S6.2): stretch the haptic gradually as the session goes on, so later cycles feel slower. Multiply event intensity by `1 − 0.3 × progress`.
- Set `resetHandler` and `stoppedHandler` on the engine and restart it; it stops when the app backgrounds.
- Respect the app's haptics setting. Skip on hardware without haptics.

---

## 7. Accessibility

- The orb is one accessibility element, label "Breathing guide", value like "Inhale, 3 seconds left, cycle 1 of 4" (SOS: "Inhale, 2 minutes 45 seconds left"), hint "Double-tap to hear a coaching line".
- Reduce Motion: section 4.
- Dynamic Type: the readout inside the orb is fixed-size because it's part of a graphic, and the VoiceOver value carries the same information. The transcript pill and buttons use Dynamic Type.
- Contrast: the cycle row at white @ 0.40 on the lens is about 3.7:1. If the S15.5 contrast pass needs 4.5:1, raise it to @ 0.55 (about 6:1). That's an approved fallback.

---

## 8. Data file — `DayXero/Resources/breathing_orb_data.json`

Load everything from this file; don't hardcode it.

```json
{
  "version": "2.0.0",
  "tokens": {
    "canvasBlack": "#000000",
    "sage": "#BCC388",
    "moss": "#43511C",
    "porcelain": "#FFFFFF",
    "lensGradient": [
      { "stop": 0.00, "hex": "#10160A", "alpha": 1.0 },
      { "stop": 0.55, "hex": "#070A04", "alpha": 1.0 },
      { "stop": 0.90, "hex": "#040602", "alpha": 1.0 },
      { "stop": 1.00, "hex": "#040602", "alpha": 0.0 }
    ],
    "haloGradient": [
      { "stop": 0.00, "hex": "#43511C", "alpha": 0.42 },
      { "stop": 0.70, "hex": "#BCC388", "alpha": 0.18 },
      { "stop": 1.00, "hex": "#BCC388", "alpha": 0.00 }
    ]
  },
  "geometry": {
    "sizeFull": 320,
    "sizeMini": 180,
    "ringBaseFactor": 0.3432,
    "haloInner": 0.40,
    "haloOuter": 1.25,
    "lensFactor": 0.80,
    "lensFeather": 1.06,
    "vertices": 120
  },
  "motion": {
    "orbTimeStepPerFrame": 0.035,
    "breathDampingPerFrame": 0.035,
    "speechDampingPerFrame": 0.12,
    "holdShimmerAmp": 0.015,
    "holdShimmerFreq": 2.5,
    "phaseRippleSeconds": 2.2,
    "finishedScale": 0.86,
    "initialBreathScale": 0.90,
    "initialSpeechEnergy": 0.30
  },
  "plasmaLayers": [
    { "id": "moss_sub_aura",           "hex": "#43511C", "opacity": 0.75, "widthFull": 24.0, "widthMini": 14.0, "glowHex": "#BCC388", "glowFull": 18.0, "glowMini": 10.0, "amp": 5.5, "freq1": 3, "freq2": 5,  "speed": 1.1,  "radiusMult": 1.030 },
    { "id": "outer_sage_wave",         "hex": "#BCC388", "opacity": 0.65, "widthFull": 12.0, "widthMini": 7.0,  "glowHex": "#BCC388", "glowFull": 12.0, "glowMini": 6.0,  "amp": 4.2, "freq1": 4, "freq2": 7,  "speed": -1.5, "radiusMult": 1.000 },
    { "id": "talking_harmonic_ring",   "hex": "#BCC388", "opacity": 0.90, "widthFull": 5.5,  "widthMini": 3.5,  "glowHex": "#BCC388", "glowFull": 6.0,  "glowMini": 3.0,  "amp": 3.2, "freq1": 5, "freq2": 9,  "speed": 2.2,  "radiusMult": 0.985 },
    { "id": "white_specular_filament", "hex": "#FFFFFF", "opacity": 0.92, "widthFull": 2.6,  "widthMini": 1.8,  "glowHex": "#FFFFFF", "glowFull": 3.0,  "glowMini": 1.0,  "amp": 2.4, "freq1": 6, "freq2": 11, "speed": -2.6, "radiusMult": 0.975 }
  ],
  "readout": {
    "full": { "labelSize": 12, "rowHeight": 14, "gap": 8, "heroSize": 48, "heroSizeSOS": 40, "cycleSize": 10, "cycleTracking": 0.06, "barWidth": 2.5, "barMaxHeight": 12, "barGap": 2, "cycleToBars": 6 },
    "mini": { "labelSize": 8.5, "rowHeight": 10, "gap": 4, "heroSize": 24, "heroSizeSOS": 19, "cycleSize": 7, "cycleTracking": 0.03, "barWidth": 2.0, "barMaxHeight": 7, "barGap": 2, "cycleToBars": 4 },
    "labelOpacity": 0.85,
    "cycleOpacity": 0.40
  },
  "sos": {
    "sessionSeconds": 180,
    "defaultPattern": "wave",
    "coachingTriggers": { "sos_start": 180, "mid_session": 90, "near_completion": 30 }
  },
  "breathingPatterns": [
    {
      "id": "box",
      "name": "Box breathing",
      "counts": "4·4·4·4",
      "subtitle": "Even counts to steady your focus",
      "recommendedCycles": 4,
      "phases": { "Inhale": 4, "Hold": 4, "Exhale": 4, "Rest": 4 },
      "scaleTargets": { "Inhale": 1.12, "Hold": 1.14, "Exhale": 0.84, "Rest": 0.82 },
      "haptics": {
        "Inhale": { "intensityStart": 0.30, "intensityEnd": 0.85, "sharpness": 0.40 },
        "Hold":   { "intensityStart": 0.25, "intensityEnd": 0.25, "sharpness": 0.20 },
        "Exhale": { "intensityStart": 0.80, "intensityEnd": 0.15, "sharpness": 0.15 },
        "Rest":   { "intensityStart": 0.00, "intensityEnd": 0.00, "sharpness": 0.10 }
      }
    },
    {
      "id": "478",
      "name": "Deep calm",
      "counts": "4·7·8",
      "subtitle": "A long exhale to help you settle",
      "recommendedCycles": 4,
      "phases": { "Inhale": 4, "Hold": 7, "Exhale": 8, "Rest": 0 },
      "scaleTargets": { "Inhale": 1.12, "Hold": 1.15, "Exhale": 0.82, "Rest": 0.82 },
      "haptics": {
        "Inhale": { "intensityStart": 0.35, "intensityEnd": 0.90, "sharpness": 0.45 },
        "Hold":   { "intensityStart": 0.30, "intensityEnd": 0.20, "sharpness": 0.20 },
        "Exhale": { "intensityStart": 0.85, "intensityEnd": 0.10, "sharpness": 0.10 },
        "Rest":   { "intensityStart": 0.00, "intensityEnd": 0.00, "sharpness": 0.10 }
      }
    },
    {
      "id": "wave",
      "name": "Wave riding",
      "counts": "5·2·5·2",
      "subtitle": "Ride the urge like a wave",
      "recommendedCycles": 6,
      "phases": { "Inhale": 5, "Hold": 2, "Exhale": 5, "Rest": 2 },
      "scaleTargets": { "Inhale": 1.14, "Hold": 1.14, "Exhale": 0.84, "Rest": 0.84 },
      "haptics": {
        "Inhale": { "intensityStart": 0.25, "intensityEnd": 0.75, "sharpness": 0.30 },
        "Hold":   { "intensityStart": 0.40, "intensityEnd": 0.40, "sharpness": 0.25 },
        "Exhale": { "intensityStart": 0.75, "intensityEnd": 0.20, "sharpness": 0.15 },
        "Rest":   { "intensityStart": 0.10, "intensityEnd": 0.10, "sharpness": 0.10 }
      }
    }
  ],
  "labels": {
    "badgeSpeaking": "COACH SPEAKING",
    "badgeIdle": "PACING BREATH",
    "coachButton": "Coach me",
    "pause": "Pause",
    "resume": "Resume",
    "start": "Start",
    "breathingDoneLabel": "done",
    "breathingDoneTranscript": "Nice work. You finished {N} cycles.",
    "sosDoneLabel": "urge surfed",
    "sosDoneTranscript": "Three minutes done. Did the craving pass?"
  },
  "phaseScripts": {
    "Inhale": [
      "Inhale slowly through your nose... watch the sage ring expand.",
      "Draw clean air deep into your lower ribs... let the wave rise.",
      "Breathe in slowly... let your shoulders drop."
    ],
    "Hold": [
      "Hold gently at the crest... notice the sensation without fighting it.",
      "Pause in stillness... a craving is a wave, and waves pass.",
      "Suspend the breath... your streak and progress are completely safe."
    ],
    "Exhale": [
      "Exhale softly... release the tension from your jaw and shoulders.",
      "Let the urge dissolve into the dark moss core... you are in control.",
      "Breathe out slowly... longer than you breathed in."
    ],
    "Rest": [
      "Rest at zero... steady and calm, zero guilt.",
      "Notice the calm between waves... you rode it out."
    ]
  },
  "coachingLines": [
    {
      "id": "urge_peak",
      "trigger": "sos_start",
      "durationSeconds": 12,
      "text": "I'm right here with you. Cravings rise, peak and fade, usually within a few minutes. Let's ride this one together—inhale slowly with the sage light."
    },
    {
      "id": "act_notice_and_name",
      "trigger": "mid_session",
      "durationSeconds": 15,
      "text": "Notice where you feel the urge—maybe tightness in your chest or restless hands. Name it gently. You don't need nicotine to make it pass."
    },
    {
      "id": "proof_you_can",
      "trigger": "near_completion",
      "durationSeconds": 10,
      "text": "You're nearly through it. Every craving you ride out is proof you can do it again. Stay with the glowing ring a little longer."
    }
  ]
}
```

---

## 9. Open decision for Milan (add as `blocked` task S6.10, then build with the defaults above)

The data file above uses revised wording. Milan's original wording is listed here so he can pick either. **Build with the revised wording until Milan answers.** Changing it later is a JSON edit only.

**Labels.** The original said "AI". This is scripted on-device speech, and the AI coach is out of scope for v1, so "AI" would be inaccurate.

| Where | Original | Revised (default) |
|---|---|---|
| Badge while speaking | `AI SPEAKING` | `COACH SPEAKING` |
| Coach button | `Talk to AI Coach` | `Coach me` |

**Health claims.** The handoff requires conservative claims (part 1) and no clinical claims in the toolkit (S12.3). Pouch users don't inhale smoke, so lines about lungs and carbon monoxide don't apply to them.

| Line | Original | Revised (default) |
|---|---|---|
| Inhale 3 | Breathe in clarity... your nervous system is recalibrating. | Breathe in slowly... let your shoulders drop. |
| Hold 2 | Pause in stillness... a craving is only a passing neurochemical wave. | Pause in stillness... a craving is a wave, and waves pass. |
| Exhale 3 | Breathe out slowly... every second lowers your heart rate. | Breathe out slowly... longer than you breathed in. |
| Rest 1 | Rest at zero... clean lungs, steady pulse, zero guilt. | Rest at zero... steady and calm, zero guilt. |
| SOS start | …This craving peaks at 90 seconds and then fades away… | …Cravings rise, peak and fade, usually within a few minutes… |
| Near completion | Every breath you take right now is clearing carbon monoxide and restoring your cilia. Stay with the glowing ring for three more cycles. | You're nearly through it. Every craving you ride out is proof you can do it again. Stay with the glowing ring a little longer. (Three cycles don't fit in the last 30 seconds.) |
| Pattern subtitles | Autonomic Focus & Craving Reset / Parasympathetic Down-Regulation (90s Urge Peak) / Continuous Sinusoidal Urge Surfing | Even counts to steady your focus / A long exhale to help you settle / Ride the urge like a wave |

---

## 10. What's deliberately not in this component

- The outer bezel, its shadows and rim highlights. Removed by Milan on 24 Oct 2026.
- The recessed cavity well. Removed.
- The lens hairline border and the top-left highlight arc. Removed.
- Right-aligned readout with 18% right padding and `.offset(x: 34)`. Replaced by the centred stack.
- Any network call, LLM or live speech recognition.

---

## 11. Done when

- [ ] Full and mini orbs match `reference/bio-orb-preview.html` side by side: ring thickness, glow, wave speed, breath timing, centred readout. Record a screen capture of each next to the preview and attach it to the tracker task.
- [ ] Wave speed is the same on a 60Hz and a 120Hz device.
- [ ] No visible circle outlines other than the plasma ring, at every breath scale.
- [ ] The readout stays inside the lens at breath scale 0.82, at full and mini sizes, in both breathing and SOS modes.
- [ ] Coaching lines aren't overwritten by phase changes. The badge shows the speaking label only while a line is active.
- [ ] Voice plays with the silent switch on. Voice guidance off shows captions.
- [ ] Haptics follow the per-phase curves and recover after backgrounding.
- [ ] Reduce Motion, VoiceOver value and announcements all work.
- [ ] Breathing ends after `recommendedCycles`. SOS ends at 3:00 and hands off to the S6.3 outcomes.
- [ ] Holds 60fps (120 on ProMotion) on the oldest supported device with all four rings. Profile with Instruments.
- [ ] All values come from `breathing_orb_data.json`.
