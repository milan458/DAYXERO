import SwiftUI

/// The lesson player's wave: translucent layers of cloud-like terrain receding into depth, with a softer
/// terrain hanging below the horizon. It rolls sideways all the time and swells with the voice.
struct CloudWave: View {
    enum Form { case sine, square, sawtooth, triangle }

    var form: Form = .sine
    /// How loud the voice is at a moment, 0 to 1.
    let level: (Date) -> Double
    let playing: Bool

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var motion = Motion()

    /// How full the cloud sits before play and while paused: visible and drifting, not a flat line.
    static let restingLevel = 0.45

    /// Time and a smoothed level carried from frame to frame.
    final class Motion {
        var time = 0.0
        var level = 0.3
        var last: Date?

        func advance(to now: Date, playing: Bool, target: Double, settle: Bool) -> (time: Double, level: Double) {
            let dt = min(max(now.timeIntervalSince(last ?? now), 0), 0.05)
            last = now
            time += dt * (playing ? 1 : 0.35)
            level = settle ? target : level + (target - level) * min(1, dt * 9)
            return (time, level)
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60, paused: reduceMotion)) { timeline in
            let target = playing ? (reduceMotion ? 0.6 : level(timeline.date)) : CloudWave.restingLevel
            let frame = motion.advance(to: timeline.date, playing: playing, target: target, settle: reduceMotion)
            let dark = scheme == .dark
            Canvas { context, size in
                CloudWave.draw(in: &context, size: size, form: form, time: frame.time, level: frame.level, dark: dark)
            }
        }
        .drawingGroup()
        .accessibilityHidden(true)
    }

    // MARK: Drawing

    private static let components: [(kx: Double, kz: Double, speed: Double, amp: Double)] = [
        (2.2, 0.9, 0.55, 1.0), (4.1, -1.7, -0.8, 0.75), (7.3, 2.6, 1.2, 0.5),
        (12.9, -3.9, 1.7, 0.32), (21.7, 5.3, -2.1, 0.14), (34.1, -7.7, 2.6, 0.07),
    ]

    private static func wave(_ form: Form, _ p: Double) -> Double {
        switch form {
        case .sine: return sin(p)
        case .square: return tanh(5 * sin(p))
        case .sawtooth: let q = (p / (2 * .pi)).truncatingRemainder(dividingBy: 1); return 2 * (q < 0 ? q + 1 : q) - 1
        case .triangle: return 2 / .pi * asin(sin(p))
        }
    }

    /// Height of the terrain at x (0…1 across) and z (1 at the back, 0 at the front), 0…1.
    private static func field(_ form: Form, x: Double, z: Double, t: Double, seed: Double) -> Double {
        var h = 0.0, sum = 0.0
        for (i, c) in components.enumerated() {
            h += c.amp * wave(form, 2 * .pi * (c.kx * x + c.kz * z) - c.speed * t * 2 + seed * Double(i + 1) * 1.7)
            sum += c.amp
        }
        return (h / sum + 1) / 2
    }

    private static func gauss(_ u: Double, _ c: Double, _ w: Double) -> Double {
        let z = (u - c) / w
        return exp(-z * z)
    }

    private static func smooth(_ values: [Double], radius: Int) -> [Double] {
        values.indices.map { i in
            let lo = max(i - radius, 0), hi = min(i + radius, values.count - 1)
            return values[lo...hi].reduce(0, +) / Double(hi - lo + 1)
        }
    }

    private static func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double) -> Color {
        Color(.sRGB, red: r / 255, green: g / 255, blue: b / 255, opacity: a)
    }

    private struct Row {
        let x0: Double, span: Double, base: Double, lowerBase: Double, front: Double
        let top: [Double], bottom: [Double]
    }

    static func draw(in context: inout GraphicsContext, size: CGSize, form: Form, time t: Double, level: Double, dark: Bool) {
        let W = size.width, H = size.height
        guard W > 0, H > 0 else { return }
        let body = dark ? (28.0, 58.0, 255.0) : (40.0, 70.0, 235.0)
        let rim = dark ? (190.0, 180.0, 255.0) : (60.0, 80.0, 220.0)
        let deep = dark ? (40.0, 50.0, 255.0) : (60.0, 70.0, 230.0)
        let y0 = H * 0.62, up = H * 0.64, down = H * 0.4
        let rows = 36, points = 80
        // A pale canvas needs denser layers to read as a cloud; on black the layers add up into glow.
        let boost = dark ? 1.0 : 1.7

        // Two swells of energy travel across, one each way.
        let wrap = { (v: Double) in v - floor(v) }
        let p1 = wrap(t * 0.07), p2 = 1 - wrap(t * 0.05 + 0.4)

        var built: [Row] = []
        for k in 0..<rows {
            let z = 1 - Double(k) / Double(rows - 1)
            let span = W * 0.9 * (1 - 0.2 * z), x0 = (W - span) / 2
            let base = y0 - z * 14, hs = 1 - 0.3 * z
            let depth = 0.55 + 0.45 * sin(.pi * (0.2 + 0.8 * z))
            var top: [Double] = [], bottom: [Double] = []
            for j in 0...points {
                let u = Double(j) / Double(points)
                let s = sin(.pi * u)
                // Steep at the very edge, so each end finishes in a rounded mound instead of a point.
                let edge = pow(s, 0.32) * (0.75 + 0.25 * s)
                let swell = 0.72 + 0.28 * min(1.2, gauss(u, 0.15 + 0.7 * p1, 0.16) + gauss(u, 0.15 + 0.7 * p2, 0.14))
                let a = field(form, x: u, z: z, t: t, seed: 0.3)
                let b = field(form, x: u, z: z, t: t * 0.8, seed: 2.9)
                let amp = level * edge * swell * depth
                // A thin, dense base everywhere, with billowing tops above it.
                top.append((0.07 + 0.93 * pow(a, 1.45)) * up * hs * amp)
                bottom.append((0.04 + 0.96 * pow(b, 2.1)) * down * hs * amp)
            }
            top = smooth(smooth(top, radius: 3), radius: 2)
            bottom = smooth(smooth(bottom, radius: 3), radius: 2)
            top[0] = 0; top[points] = 0; bottom[0] = 0; bottom[points] = 0
            built.append(Row(x0: x0, span: span, base: base, lowerBase: y0 + z * 6, front: 1 - z, top: top, bottom: bottom))
        }

        func upper(_ r: Row) -> Path {
            Path { p in
                p.move(to: CGPoint(x: r.x0, y: r.base))
                for j in 0...points { p.addLine(to: CGPoint(x: r.x0 + r.span * Double(j) / Double(points), y: r.base - r.top[j])) }
                p.addLine(to: CGPoint(x: r.x0 + r.span, y: r.base))
                p.closeSubpath()
            }
        }
        func lower(_ r: Row) -> Path {
            Path { p in
                p.move(to: CGPoint(x: r.x0, y: r.lowerBase))
                for j in 0...points { p.addLine(to: CGPoint(x: r.x0 + r.span * Double(j) / Double(points), y: r.lowerBase + r.bottom[j])) }
                p.addLine(to: CGPoint(x: r.x0 + r.span, y: r.lowerBase))
                p.closeSubpath()
            }
        }
        func ridge(_ r: Row) -> Path {
            Path { p in
                for j in 0...points {
                    let pt = CGPoint(x: r.x0 + r.span * Double(j) / Double(points), y: r.base - r.top[j])
                    if j == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                }
            }
        }

        context.blendMode = dark ? .plusLighter : .normal

        // Halo, breathing with the voice.
        let halo = Gradient(colors: [rgb(body.0, body.1, body.2, dark ? 0.12 + 0.1 * level : 0.05 + 0.05 * level),
                                     rgb(body.0, body.1, body.2, 0)])
        context.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .radialGradient(halo, center: CGPoint(x: W / 2, y: y0), startRadius: 0, endRadius: W * 0.55))

        // Glow: every third layer, blurred, under the sharp layers.
        context.drawLayer { glow in
            glow.addFilter(.blur(radius: 10))
            glow.blendMode = dark ? .plusLighter : .normal
            for (k, r) in built.enumerated() where k % 3 == 0 {
                glow.fill(upper(r), with: .color(rgb(body.0, body.1, body.2, (dark ? 0.012 + 0.02 * r.front : 0.014 + 0.018 * r.front) * 2.1 * boost)))
                glow.fill(lower(r), with: .color(rgb(deep.0, deep.1, deep.2, (dark ? 0.01 + 0.014 * r.front : 0.01 + 0.012 * r.front) * 2.1 * boost)))
            }
        }

        for (k, r) in built.enumerated() {
            let f = r.front
            context.fill(upper(r), with: .color(rgb(body.0, body.1, body.2, (dark ? 0.012 + 0.02 * f : 0.014 + 0.018 * f) * 1.15 * boost)))
            let edge = f > 0.55 ? rim : body
            context.stroke(ridge(r), with: .color(rgb(edge.0, edge.1, edge.2, dark ? 0.025 + 0.12 * f * f : 0.025 + 0.1 * f * f)),
                           lineWidth: 0.7)
            context.fill(lower(r), with: .color(rgb(deep.0, deep.1, deep.2, (dark ? 0.01 + 0.014 * f : 0.01 + 0.012 * f) * 1.15 * boost)))
            if k % 2 == 0 {
                let hanging = Path { p in
                    for j in 0...points {
                        let pt = CGPoint(x: r.x0 + r.span * Double(j) / Double(points), y: r.lowerBase + r.bottom[j])
                        if j == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                    }
                }
                context.stroke(hanging, with: .color(rgb(body.0, body.1, body.2, (dark ? 0.08 : 0.07) * f)), lineWidth: 0.6)
            }
        }

        // The horizon.
        let line = Gradient(stops: [.init(color: rgb(rim.0, rim.1, rim.2, 0), location: 0),
                                    .init(color: rgb(rim.0, rim.1, rim.2, dark ? 0.55 : 0.35), location: 0.5),
                                    .init(color: rgb(rim.0, rim.1, rim.2, 0), location: 1)])
        context.fill(Path(CGRect(x: W * 0.04, y: y0 - 0.6, width: W * 0.92, height: 1.2)),
                     with: .linearGradient(line, startPoint: CGPoint(x: 0, y: y0), endPoint: CGPoint(x: W, y: y0)))
    }
}
