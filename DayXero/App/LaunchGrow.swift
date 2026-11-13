import DayXeroCore
import SwiftUI

/// The opening animation (v5, cook/site/screens/000-launch): a 2.4 s paper-cut sunrise. The hills rise back to front,
/// the sun climbs into the valley and its rings open, the wordmark assembles letter by letter with the coral underline
/// under "Xero", and Xero rises from behind the front hill to land under the sun. It holds, then fades into the app.
/// It always plays to the end; there's no skip. The static launch screen is the same apricot, so nothing jumps.
///
/// Motion (000): 0-1000ms back hill rises 220px (settle); 140-1140ms mid hill rises 260px; 280-1280ms front hill rises
/// 300px, then the two near layers follow at 360ms and 440ms (each paper layer casts a soft shadow up onto the one
/// behind). 250-1750ms the sun climbs 240px into the valley (ease-out), its two paper rings open from 0.6 to 1 at
/// 800-1900ms (dark mode: no rings; a warm amber glow opens behind the disc, which stops 72px higher at 84% size, and
/// seven faint stars fade in across the top band). 700-1720ms the wordmark assembles: 7 letters, 60ms stagger, each
/// rises 40px with a 6deg tilt and blur 6px to sharp on a soft spring (660ms). 1560-2010ms the coral underline draws
/// under Xero. 1500-2340ms Xero rises 170px from behind the front hill on a soft overshoot and lands under the sun;
/// soft impact haptic at 2300ms. 600-2000ms two paper-cut clouds slide in 36px from the sides and fade up. Holds the
/// final frame.
struct LaunchGrowOverlay: View {
    let onFinished: @MainActor () -> Void
    private let motion = MotionPolicy()
    @State private var start: Date?
    @State private var landed = false

    var body: some View {
        let timing = motion.reduce ? LaunchGrowTiming.reduced : .full
        TimelineView(.animation) { context in
            let t = motion.reduce ? 10 : start.map { context.date.timeIntervalSince($0) } ?? 0
            let fade = timing.fade(at: start.map { context.date.timeIntervalSince($0) } ?? 0)
            LaunchScene(t: t)
                .opacity(motion.reduce ? Ease.progress(start.map { context.date.timeIntervalSince($0) } ?? 0, from: 0, to: 0.3) : 1)
                .opacity(1 - fade)
                .scaleEffect(1 + 0.04 * fade)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "DayXero"))
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.6), trigger: landed)
        .onAppear { if start == nil { start = .now } }
        .task {
            try? await Task.sleep(for: .seconds(motion.reduce ? 0 : LaunchTimeline.xeroLands))
            landed = true
        }
        .task {
            try? await Task.sleep(for: .seconds(timing.end))
            onFinished()
        }
    }

    /// Cold starts only: RootView owns the flag, so coming back from the background doesn't replay it.
    /// Tests, screenshots and seeded scenarios (`-dx.` arguments) open straight into the app.
    static var shouldPlay: Bool {
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil { return false }
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-dx.launch") { return true }
        return !ProcessInfo.processInfo.arguments.contains { $0.hasPrefix("-dx.") }
        #else
        return true
        #endif
    }
}

/// The sunrise runs 2.4 s, holds 0.6 s, then fades over 0.4 s. With Reduce Motion the finished scene fades in over
/// 0.3 s and holds instead.
struct LaunchGrowTiming {
    let fadeStart: Double
    let end: Double

    static let full = LaunchGrowTiming(fadeStart: 3.0, end: 3.4)
    static let reduced = LaunchGrowTiming(fadeStart: 1.3, end: 1.7)

    func fade(at t: Double) -> Double { Ease.progress(t, from: fadeStart, to: end) }
}

/// Where each layer is at a moment of the sunrise (kit 000 timeline), in the kit's 390-wide points.
enum LaunchTimeline {
    static let duration = 2.4
    static let xeroLands = 2.3

    /// How far a hill still has to rise: back 220 from 0 s, mid 260 from 0.14 s, front 300 from 0.28 s, the near
    /// layers 300 from 0.36 s and 0.44 s; each over 1 s on the settle curve.
    static func hill(_ index: Int, at t: Double) -> CGFloat {
        let (delay, rise): (Double, CGFloat) = [(0, 220), (0.14, 260), (0.28, 300), (0.36, 300), (0.44, 300)][index]
        return rise * CGFloat(1 - Ease.settle(t, from: delay, to: delay + 1))
    }

    static func sun(at t: Double) -> CGFloat { 240 * CGFloat(1 - Ease.sun(t, from: 0.25, to: 1.75)) }
    static func ring(_ delay: Double, at t: Double) -> Double { Ease.settle(t, from: delay, to: delay + 1.1) }
    static func letter(_ n: Int, at t: Double) -> Double { Ease.spring(t, from: 0.7 + Double(n) * 0.06, to: 0.7 + Double(n) * 0.06 + 0.66) }
    static func underline(at t: Double) -> Double { Ease.progress(t, from: 1.56, to: 2.01) }
    static func xero(at t: Double) -> Double { Ease.overshoot(t, from: 1.5, to: 2.34) }
    static func cloud(_ delay: Double, at t: Double) -> Double { Ease.settle(t, from: delay, to: delay + 1.4) }
    static func star(_ delay: Double, at t: Double) -> Double { Ease.progress(t, from: delay, to: delay + 0.9) }
}

/// The sunrise at time `t`, laid out from the bottom of the screen in the kit's 390 × 844 space.
struct LaunchScene: View {
    let t: Double
    @Environment(\.colorScheme) private var scheme

    private struct Palette {
        let back, mid, front, near, base, edge, edgeLow, cloud, cloudShade, lift: Color
        let sunA, sunB: Color
    }

    private var palette: Palette {
        scheme == .dark
            ? Palette(back: Color(hex: 0x4B5889), mid: Color(hex: 0x37436F), front: Color(hex: 0x29335C), near: Color(hex: 0x1D2647),
                      base: Color(hex: 0x141B36), edge: .clear, edgeLow: .clear, cloud: Color(hex: 0x34416F),
                      cloudShade: .black.opacity(0.35), lift: .black.opacity(0.5), sunA: Color(hex: 0xFFE2A0), sunB: Color(hex: 0xF3A14A))
            : Palette(back: Color(hex: 0xFFD2A2), mid: Color(hex: 0xFFE6CA), front: Color(hex: 0xF7A578), near: Color(hex: 0xF39466),
                      base: Color(hex: 0xEC8456), edge: .white.opacity(0.6), edgeLow: Color(hex: 0xFFECD6).opacity(0.5),
                      cloud: Color(hex: 0xFFE9D2), cloudShade: Color(hex: 0x96461E).opacity(0.16), lift: Color(hex: 0x782C14).opacity(0.13),
                      sunA: Color(hex: 0xFFF4C9), sunB: Color(hex: 0xFFC93C))
    }

    static let hills: [(top: CGFloat, d: String)] = [
        (420, "M0 96 C56 64 118 74 150 146 C170 196 222 204 242 160 C276 86 334 60 390 82 L390 404 L0 404 Z"),
        (420, "M0 204 C56 170 116 176 158 216 C182 240 214 246 238 228 C282 190 336 172 390 192 L390 404 L0 404 Z"),
        (440, "M0 292 C58 270 112 256 196 254 C280 252 334 272 390 288 L390 404 L0 404 Z"),
        (440, "M0 262 C38 248 86 254 132 284 C186 318 258 326 314 300 C346 285 370 278 390 280 L390 404 L0 404 Z"),
        (440, "M0 344 C52 324 112 324 172 340 C238 358 306 342 390 300 L390 404 L0 404 Z"),
    ]

    var body: some View {
        let dark = scheme == .dark
        let p = palette
        GeometryReader { proxy in
            let s = proxy.size.width / 390
            // The scene is anchored to the bottom; the kit's y 0 sits this far above the top of the screen.
            let top = proxy.size.height - 844 * s
            ZStack(alignment: .topLeading) {
                if dark {
                    LinearGradient(stops: [.init(color: Color(hex: 0x0B1020), location: 0), .init(color: Color(hex: 0x10172C), location: 0.4),
                                           .init(color: Color(hex: 0x1A2346), location: 0.72), .init(color: Color(hex: 0x222C55), location: 1)],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(height: max(0, top + 560 * s))
                    stars(s: s, top: top)
                }
                sun(s: s, top: top, dark: dark, p: p)
                cloud(width: 124, x: 14, y: 412, from: -36, delay: 0.6, s: s, top: top, p: p)
                cloud(width: 92, x: 390 - 16 - 92, y: 384, from: 36, delay: 0.76, s: s, top: top, p: p)
                hill(0, fill: p.back, edge: p.edge, s: s, top: top, p: p)
                hill(1, fill: p.mid, edge: p.edge, s: s, top: top, p: p)
                XeroView(mood: .hello, stage: 1, points: 200 * s)
                    .frame(width: 200 * s, height: 200 * s)
                    .offset(x: 95 * s, y: top + (495 + 170 * CGFloat(1 - LaunchTimeline.xero(at: t))) * s)
                    .opacity(t >= 1.5 ? 1 : 0)
                hill(2, fill: p.front, edge: p.edge, s: s, top: top, p: p)
                hill(3, fill: p.near, edge: p.edgeLow, s: s, top: top, p: p)
                hill(4, fill: p.base, edge: p.edgeLow, s: s, top: top, p: p)
                wordmark(s: s, dark: dark)
                    .frame(width: proxy.size.width)
                    .offset(y: top + 250 * s)
            }
        }
        // Dark: below the sky band the air keeps its last colour behind the hills.
        .background(scheme == .dark ? Color(hex: 0x222C55) : DX.Ground.apricot.background)
        .ignoresSafeArea()
    }

    private func hill(_ i: Int, fill: Color, edge: Color, s: CGFloat, top: CGFloat, p: Palette) -> some View {
        let layer = Self.hills[i]
        return Canvas { ctx, size in
            ctx.scaleBy(x: s, y: s)
            let path = SVGPath.path(layer.d)
            var lifted = ctx
            lifted.addFilter(.shadow(color: p.lift, radius: scheme == .dark ? 9 : 4, y: scheme == .dark ? -4 : -2))
            lifted.fill(path, with: .color(fill))
            let ridge = SVGPath.path(String(layer.d.prefix { $0 != "L" }))
            ctx.stroke(ridge, with: .color(edge), lineWidth: 2)
        }
        .frame(width: 390 * s, height: 404 * s)
        .offset(y: top + (layer.top + LaunchTimeline.hill(i, at: t)) * s)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func sun(s: CGFloat, top: CGFloat, dark: Bool, p: Palette) -> some View {
        let climb = LaunchTimeline.sun(at: t)
        let y = top + (352 + 176 + climb - (dark ? 72 : 0)) * s
        let scale: CGFloat = dark ? 0.84 : 1
        ZStack {
            if dark {
                Circle().fill(RadialGradient(stops: [.init(color: Color(hex: 0xFFB862).opacity(0.7), location: 0),
                                                     .init(color: Color(hex: 0xF7A04E).opacity(0.32), location: 0.42),
                                                     .init(color: Color(hex: 0xE88A45).opacity(0.09), location: 0.72),
                                                     .init(color: Color(hex: 0xE07F40).opacity(0), location: 1)],
                                             center: .center, startRadius: 0, endRadius: 170 * s))
                    .frame(width: 340 * s, height: 340 * s)
                    .scaleEffect(0.6 + 0.4 * LaunchTimeline.ring(0.8, at: t))
                    .opacity(LaunchTimeline.ring(0.8, at: t))
            } else {
                Circle().fill(Color(hex: 0xFFECC8).opacity(0.32)).frame(width: 252 * s, height: 252 * s)
                    .scaleEffect(0.6 + 0.4 * LaunchTimeline.ring(0.9, at: t)).opacity(LaunchTimeline.ring(0.9, at: t))
                Circle().fill(Color(hex: 0xFFF0CD).opacity(0.55)).frame(width: 196 * s, height: 196 * s)
                    .scaleEffect(0.6 + 0.4 * LaunchTimeline.ring(0.8, at: t)).opacity(LaunchTimeline.ring(0.8, at: t))
            }
            Circle().fill(RadialGradient(colors: [p.sunA, p.sunB], center: UnitPoint(x: 0.4, y: 0.34), startRadius: 0, endRadius: 98 * s))
                .frame(width: 136 * s, height: 136 * s)
            if dark {
                Circle().stroke(Color(hex: 0xFFEFC4).opacity(0.7), lineWidth: 2).frame(width: 134 * s, height: 134 * s)
            }
        }
        .scaleEffect(scale)
        .position(x: 195 * s, y: y)
    }

    private func cloud(width: CGFloat, x: CGFloat, y: CGFloat, from: CGFloat, delay: Double, s: CGFloat, top: CGFloat, p: Palette) -> some View {
        let k = LaunchTimeline.cloud(delay, at: t)
        return Canvas { ctx, size in
            ctx.scaleBy(x: size.width / 108, y: size.height / 42)
            var shaded = ctx
            shaded.addFilter(.shadow(color: p.cloudShade, radius: 1.5, y: 2))
            shaded.fill(SVGPath.path("M10 40 C2 40 0 30 9 27 C8 17 20 11 30 16 C35 4 56 1 64 14 C72 8 86 11 88 23 C99 22 106 31 100 40 Z"),
                        with: .color(p.cloud))
        }
        .frame(width: width * s, height: width * 42 / 108 * s)
        .offset(x: (x + from * CGFloat(1 - k)) * s, y: top + y * s)
        .opacity(k)
    }

    private func stars(s: CGFloat, top: CGFloat) -> some View {
        let list: [(CGFloat, CGFloat, CGFloat, Double, Double)] = [(62, 96, 1.5, 0.55, 0.2), (148, 72, 1.1, 0.4, 0.32), (236, 128, 1.3, 0.45, 0.44),
                                                                (318, 84, 1.7, 0.6, 0.26), (352, 176, 1.1, 0.38, 0.52), (34, 198, 1.2, 0.4, 0.38),
                                                                (112, 158, 1, 0.32, 0.6)]
        return ZStack(alignment: .topLeading) {
            ForEach(Array(list.enumerated()), id: \.offset) { _, star in
                Circle().fill(Color(hex: 0xF3E9D6))
                    .frame(width: star.2 * 2, height: star.2 * 2)
                    .opacity(star.3 * LaunchTimeline.star(star.4, at: t))
                    .offset(x: star.0 * s - star.2, y: star.1 * s - star.2)
            }
        }
    }

    private func wordmark(s: CGFloat, dark: Bool) -> some View {
        let letters = Array("DayXero")
        let ink = dark ? Color(hex: 0xFFF8EE) : Color(hex: 0x1E1A3A)
        return HStack(spacing: -2.6 * s) {
            ForEach(Array(letters.enumerated()), id: \.offset) { n, ch in
                let k = LaunchTimeline.letter(n, at: t)
                Text(verbatim: String(ch))
                    .font(Font(DX.Typeface4.font(.display, size: 70 * s, weight: 800) as CTFont))
                    .foregroundStyle(ink)
                    .opacity(min(1, k / 0.45))
                    .blur(radius: 6 * max(0, 1 - k / 0.45))
                    .scaleEffect(0.92 + 0.08 * k, anchor: UnitPoint(x: 0.5, y: 0.9))
                    .rotationEffect(.degrees(-6 * (1 - k)), anchor: UnitPoint(x: 0.5, y: 0.9))
                    .offset(y: 40 * s * CGFloat(1 - k))
                    .overlay(alignment: .bottomLeading) {
                        if n == 3 {
                            // The coral underline under "Xero", drawn left to right.
                            GeometryReader { _ in
                                SVGPathShape(d: "M4 11 C40 4 92 5 124 8 C154 10 178 12 196 5", box: CGSize(width: 200, height: 18))
                                    .trim(from: 0, to: LaunchTimeline.underline(at: t))
                                    .stroke(dark ? Color(hex: 0xFF8A65) : Color(hex: 0xFF7A55),
                                            style: StrokeStyle(lineWidth: 5.5 * s, lineCap: .round))
                                    .frame(width: 150 * s, height: 18 * s)
                            }
                            .frame(width: 150 * s, height: 18 * s)
                            .offset(x: -2 * s, y: 15 * s)
                        }
                    }
            }
        }
        .accessibilityHidden(true)
    }
}

/// An SVG path in its own box, stretched to the frame.
struct SVGPathShape: Shape {
    let d: String
    let box: CGSize
    func path(in rect: CGRect) -> Path {
        SVGPath.path(d).applying(CGAffineTransform(scaleX: rect.width / box.width, y: rect.height / box.height))
            .offsetBy(dx: rect.minX, dy: rect.minY)
    }
}

/// The kit's curves, applied between two times.
enum Ease {
    private static let curve = UnitCurve.bezier(startControlPoint: UnitPoint(x: 0.3, y: 0.7), endControlPoint: UnitPoint(x: 0.4, y: 1))
    private static let settleCurve = UnitCurve.bezier(startControlPoint: UnitPoint(x: 0.2, y: 0.8), endControlPoint: UnitPoint(x: 0.2, y: 1))
    private static let sunCurve = UnitCurve.bezier(startControlPoint: UnitPoint(x: 0.25, y: 0.75), endControlPoint: UnitPoint(x: 0.25, y: 1))
    /// cubic-bezier(.3, 1.3, .5, 1) and (.3, 1.25, .5, 1): soft springs that overshoot a little.
    private static let springCurve = UnitCurve.bezier(startControlPoint: UnitPoint(x: 0.3, y: 1.3), endControlPoint: UnitPoint(x: 0.5, y: 1))
    private static let overshootCurve = UnitCurve.bezier(startControlPoint: UnitPoint(x: 0.3, y: 1.25), endControlPoint: UnitPoint(x: 0.5, y: 1))

    private static func apply(_ c: UnitCurve, _ t: Double, _ a: Double, _ b: Double) -> Double {
        guard t > a else { return 0 }
        guard t < b else { return 1 }
        return c.value(at: (t - a) / (b - a))
    }

    static func progress(_ t: Double, from a: Double, to b: Double) -> Double { apply(curve, t, a, b) }
    static func settle(_ t: Double, from a: Double, to b: Double) -> Double { apply(settleCurve, t, a, b) }
    static func sun(_ t: Double, from a: Double, to b: Double) -> Double { apply(sunCurve, t, a, b) }
    static func spring(_ t: Double, from a: Double, to b: Double) -> Double { apply(springCurve, t, a, b) }
    static func overshoot(_ t: Double, from a: Double, to b: Double) -> Double { apply(overshootCurve, t, a, b) }
}
