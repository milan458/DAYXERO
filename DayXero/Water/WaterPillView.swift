import DayXeroCore
import SwiftUI

/// The signed-off pill water tracker (S7.6), built to `reference/water/water-pill-preview.html`.
/// Full 200 × 340; mini 56 × 96 (everything scaled, no ticks, glow or bubbles).
/// Drawn per frame from real elapsed time, so waves and bubbles move the same at 60Hz and 120Hz.
struct WaterPillView: View {
    enum Size { case full, mini }

    /// Today's counted ml over the goal; the liquid caps at full.
    let level: Double
    /// The most recently logged drink sets the liquid's colours.
    let drink: Drink
    let reached: Bool
    var size: Size = .full

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var fill = LevelAnimation()

    private var scale: CGFloat { size == .full ? 1 : 56.0 / 200.0 }
    private var width: CGFloat { 200 * scale }
    private var height: CGFloat { 340 * scale }

    var body: some View {
        ZStack {
            if size == .full {
                // Sage glow, brighter once the goal is reached.
                EllipticalGradient(colors: [Color(hex: 0xBCC388, opacity: 0.22), Color(hex: 0xBCC388, opacity: 0)])
                    .frame(width: 280, height: 380)
                    .opacity(reached ? 1 : 0.35)
                    .animation(.easeInOut(duration: 0.6), value: reached)
                    .allowsHitTesting(false)
            }
            TimelineView(.animation(paused: false)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                Canvas { context, canvas in
                    draw(in: &context, size: canvas, time: t)
                }
            }
            .frame(width: width, height: height)
            .clipShape(Capsule())
            Capsule()
                .strokeBorder(Color.white.opacity(0.75), lineWidth: max(2 * scale, 1))
                .frame(width: width, height: height)
            if size == .full { ticks }
        }
        .frame(width: width, height: height)
        .onAppear { fill.jump(to: clampedLevel) }
        .onChange(of: clampedLevel) { _, new in
            fill.animate(to: new, now: Date.now.timeIntervalSinceReferenceDate, reduceMotion: reduceMotion)
        }
    }

    private var clampedLevel: Double { min(max(level, 0), 1) }

    /// Three marks just outside the right edge at 25%, 50% and 75%.
    private var ticks: some View {
        ForEach([85.0, 170.0, 255.0], id: \.self) { top in
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.white.opacity(0.35))
                .frame(width: 8, height: 2)
                .position(x: 200 + 14 - 4, y: top + 1)
        }
        .frame(width: 200, height: 340)
        .accessibilityHidden(true)
    }

    // MARK: Drawing

    private func draw(in context: inout GraphicsContext, size canvas: CGSize, time t: TimeInterval) {
        let s = scale
        let w = canvas.width, h = canvas.height
        context.fill(Path(CGRect(origin: .zero, size: canvas)), with: .color(Color(hex: 0x0C0F08)))

        let level = fill.value(at: t)
        let top = h * (1 - level)
        let colours = drink.gradient
        let topColour = Color(hex: colours.top)
        let still = reduceMotion

        if level > 0 {
            // Back wave: 8 pt above the surface, 45%, scrolling right 260 pt every 4.5 s.
            let backShift = still ? -65 * s : (-260 + 260 * phase(t, 4.5)) * s
            context.fill(wave(baseline: top - 8 * s, amplitude: 6 * s, shift: backShift, width: w, bottom: h, scale: s),
                         with: .color(topColour.opacity(0.45)))
            // The liquid, its gradient spanning just the liquid's height.
            let liquid = Path(CGRect(x: 0, y: top, width: w, height: h - top))
            context.fill(liquid, with: .linearGradient(Gradient(colors: [topColour, Color(hex: colours.bottom)]),
                                                       startPoint: CGPoint(x: 0, y: top), endPoint: CGPoint(x: 0, y: h)))
            // Front wave: baseline on the surface, scrolling left 260 pt every 3 s.
            let frontShift = still ? 0 : -260 * phase(t, 3) * s
            context.fill(wave(baseline: top, amplitude: 7 * s, shift: frontShift, width: w, bottom: h, scale: s),
                         with: .color(topColour))

            // Bubbles rise through the liquid and never show above its surface.
            if size == .full, !still {
                var inLiquid = context
                inLiquid.clip(to: liquid)
                for bubble in bubbles {
                    guard let (rise, opacity) = bubble.state(at: t) else { continue }
                    let d = bubble.diameter
                    let rect = CGRect(x: bubble.x, y: h - bubble.start - d - rise, width: d, height: d)
                    inLiquid.fill(Path(ellipseIn: rect), with: .color(.white.opacity(opacity)))
                }
            }
        }

        // The glass highlight sits above the liquid.
        let highlight = CGRect(x: 26 * s, y: 40 * s, width: 12 * s, height: 230 * s)
        context.fill(Path(roundedRect: highlight, cornerRadius: 6 * s), with: .color(.white.opacity(0.14)))
    }

    /// A wave filled down to the bottom, from quadratic curves like the reference SVG (wavelength 130).
    private func wave(baseline: CGFloat, amplitude: CGFloat, shift: CGFloat, width: CGFloat, bottom: CGFloat, scale s: CGFloat) -> Path {
        let half = 65 * s
        var path = Path()
        var x = shift
        path.move(to: CGPoint(x: x, y: baseline))
        var up = true
        while x < width + half {
            // A quadratic's peak is half its control offset, so the control sits at twice the amplitude.
            let control = CGPoint(x: x + half / 2, y: baseline + (up ? -2 : 2) * amplitude)
            x += half
            path.addQuadCurve(to: CGPoint(x: x, y: baseline), control: control)
            up.toggle()
        }
        path.addLine(to: CGPoint(x: x, y: bottom))
        path.addLine(to: CGPoint(x: shift, y: bottom))
        path.closeSubpath()
        return path
    }

    private func phase(_ t: TimeInterval, _ period: Double) -> CGFloat {
        CGFloat(t.truncatingRemainder(dividingBy: period) / period)
    }

    private var bubbles: [Bubble] {
        var list = [
            Bubble(diameter: 7, x: 48, start: 10, cycle: 3.2, delay: 0, peak: 0.7),
            Bubble(diameter: 5, x: 120, start: 30, cycle: 4.1, delay: 1.2, peak: 0.6),
            Bubble(diameter: 4, x: 150, start: 6, cycle: 3.6, delay: 2.1, peak: 0.6),
        ]
        if drink == .sparkling {
            list += [
                Bubble(diameter: 5, x: 78, start: 14, cycle: 3.0, delay: 0.6, peak: 0.6),
                Bubble(diameter: 3, x: 98, start: 4, cycle: 3.8, delay: 1.8, peak: 0.6),
                Bubble(diameter: 4, x: 166, start: 20, cycle: 4.4, delay: 2.7, peak: 0.6),
            ]
        }
        return list
    }
}

/// One rising bubble: up 300 pt with ease-in, fading in over the first 15% and out by the end.
private struct Bubble {
    let diameter: CGFloat
    let x: CGFloat
    let start: CGFloat
    let cycle: Double
    let delay: Double
    let peak: Double

    func state(at t: TimeInterval) -> (rise: CGFloat, opacity: Double)? {
        // Seconds since this bubble's first start, on a clock shared by every pill.
        let local = t.truncatingRemainder(dividingBy: 3600) - delay
        guard local >= 0 else { return nil }
        let p = local.truncatingRemainder(dividingBy: cycle) / cycle
        let rise = 300 * CGFloat(CubicBezier.easeIn.y(atX: p))
        let opacity = p < 0.15 ? peak * (p / 0.15) : peak * (1 - (p - 0.15) / 0.85)
        return (rise, opacity)
    }
}

/// The fill level's 0.9 s change on the reference's curve (0.22, 1, 0.36, 1); 0.25 s ease under Reduce Motion.
struct LevelAnimation {
    private var from = 0.0
    private var to = 0.0
    private var start = 0.0
    private var duration = 0.0
    private var curve = CubicBezier.fill

    mutating func jump(to level: Double) {
        from = level
        to = level
        duration = 0
    }

    mutating func animate(to level: Double, now: TimeInterval, reduceMotion: Bool) {
        from = value(at: now)
        to = level
        start = now
        duration = reduceMotion ? 0.25 : 0.9
        curve = reduceMotion ? .ease : .fill
    }

    func value(at t: TimeInterval) -> Double {
        guard duration > 0 else { return to }
        let p = min(max((t - start) / duration, 0), 1)
        return from + (to - from) * curve.y(atX: p)
    }
}

/// A CSS-style cubic-bezier timing curve.
struct CubicBezier {
    let x1, y1, x2, y2: Double

    static let fill = CubicBezier(x1: 0.22, y1: 1, x2: 0.36, y2: 1)
    static let easeIn = CubicBezier(x1: 0.42, y1: 0, x2: 1, y2: 1)
    static let easeOut = CubicBezier(x1: 0, y1: 0, x2: 0.58, y2: 1)
    static let ease = CubicBezier(x1: 0.25, y1: 0.1, x2: 0.25, y2: 1)

    func y(atX x: Double) -> Double {
        if x <= 0 { return 0 }
        if x >= 1 { return 1 }
        // Solve for t where bx(t) = x (Newton, then bisection as a fallback), then return by(t).
        var t = x
        for _ in 0..<8 {
            let err = bx(t) - x
            if abs(err) < 1e-6 { return by(t) }
            let d = dbx(t)
            if abs(d) < 1e-6 { break }
            t -= err / d
        }
        var lo = 0.0, hi = 1.0
        t = x
        for _ in 0..<30 {
            let v = bx(t)
            if abs(v - x) < 1e-6 { break }
            if v < x { lo = t } else { hi = t }
            t = (lo + hi) / 2
        }
        return by(t)
    }

    private func bx(_ t: Double) -> Double { 3 * (1 - t) * (1 - t) * t * x1 + 3 * (1 - t) * t * t * x2 + t * t * t }
    private func by(_ t: Double) -> Double { 3 * (1 - t) * (1 - t) * t * y1 + 3 * (1 - t) * t * t * y2 + t * t * t }
    private func dbx(_ t: Double) -> Double { 3 * (1 - t) * (1 - t) * x1 + 6 * (1 - t) * t * (x2 - x1) + 3 * t * t * (1 - x2) }
}

/// A still pill for Live Activities, which ignore custom animation: outline and a flat sage fill.
struct WaterPillGlyph: View {
    let level: Double
    var width: CGFloat = 16

    var body: some View {
        let height = width * 1.7
        ZStack(alignment: .bottom) {
            Capsule().fill(Color(hex: 0x0C0F08))
            Rectangle().fill(Color(hex: 0xBCC388)).frame(height: height * min(max(level, 0), 1))
        }
        .frame(width: width, height: height)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.75), lineWidth: 1.5))
    }
}
