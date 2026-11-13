import SwiftUI

/// Glim's evenings, "midnight meadow" (kit.js `DX.nightSky`): a three-stop sky, a moon with a halo (or, `dawn`, a
/// low pre-dawn sun glow), twelve twinkling stars, three hills and four drifting fireflies, fading into the night
/// ground at the bottom. Drawn in the kit's 390 × 430 space and stretched to the frame. Light mode is dusk (slate to
/// a muted rose horizon); dark mode is midnight. With Reduce Motion the stars and fireflies hold still.
public struct NightSky: View {
    let dawn: Bool
    let moon: CGPoint?
    let animate: Bool
    @Environment(\.colorScheme) private var scheme
    private let motion = MotionPolicy()

    /// `moon` is in the frame's own points (kit `moonX`, `moonY`); nil puts it 54 pt in from the right at 55% height.
    public init(dawn: Bool = false, moon: CGPoint? = nil, animate: Bool = true) {
        self.dawn = dawn
        self.moon = moon
        self.animate = animate
    }

    static let stars: [(Double, Double)] = [(0.15, 0.09), (0.38, 0.07), (0.64, 0.15), (0.82, 0.05), (0.1, 0.26), (0.51, 0.22),
                                            (0.9, 0.28), (0.28, 0.35), (0.74, 0.4), (0.05, 0.47), (0.46, 0.14), (0.95, 0.16)]
    static let fireflies: [(Double, Double)] = [(0.18, 320), (0.3, 352), (0.77, 346), (0.88, 312)]

    public var body: some View {
        let dark = scheme == .dark
        let moving = animate && !motion.reduce
        let dawn = dawn, moonPoint = moon
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !moving)) { timeline in
            let t = moving ? timeline.date.timeIntervalSinceReferenceDate : 0
            Canvas { ctx, size in
                Self.draw(&ctx, size: size, dark: dark, dawn: dawn, moon: moonPoint, t: t, moving: moving)
            }
        }
        .accessibilityHidden(true)
    }

    static func draw(_ ctx: inout GraphicsContext, size: CGSize, dark: Bool, dawn: Bool, moon: CGPoint?, t: Double, moving: Bool) {
        let w = size.width, h = size.height
        let sx = w / 390
        func hy(_ y: Double) -> CGFloat { CGFloat(y / 430) * h }
        let sky: [UInt32] = dawn ? [0x0D1630, 0x24335C, 0x5B5578] : dark ? [0x08101F, 0x111D38, 0x22315A] : [0x1E2B55, 0x3E4C7E, 0xA88A98]
        let hills: [UInt32] = dark ? [0x16233F, 0x0F1A31, 0x0A1326] : [0x2A3A62, 0x1C2A4D, 0x0F1B33]
        let ground: UInt32 = dark ? 0x0A1326 : 0x0F1B33
        let moonColor = Color(hex: 0xF6E7C1), glow = Color(hex: 0xFFD37A)
        let rect = CGRect(origin: .zero, size: size)

        ctx.fill(Path(rect), with: .linearGradient(
            Gradient(stops: [.init(color: Color(hex: sky[0]), location: 0), .init(color: Color(hex: sky[1]), location: 0.55),
                             .init(color: Color(hex: sky[2]), location: 1)]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))

        if dawn {
            let c = CGPoint(x: w * 0.5, y: hy(300)), r = 96 * sx
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)), with: .radialGradient(
                Gradient(stops: [.init(color: Color(hex: 0xFFD27A).opacity(0.55), location: 0),
                                 .init(color: Color(hex: 0xFFB25E).opacity(0.22), location: 0.35),
                                 .init(color: Color(hex: 0xFFB25E).opacity(0), location: 1)]),
                center: c, startRadius: 0, endRadius: r))
            let sr = 22 * sx
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - sr, y: c.y - sr, width: 2 * sr, height: 2 * sr)), with: .color(Color(hex: 0xFFD27A)))
        } else {
            let m = moon ?? CGPoint(x: w - 54, y: h * 0.55)
            ctx.fill(Path(ellipseIn: CGRect(x: m.x - 70, y: m.y - 70, width: 140, height: 140)), with: .radialGradient(
                Gradient(colors: [moonColor.opacity(0.32), moonColor.opacity(0)]), center: m, startRadius: 0, endRadius: 70))
            ctx.fill(Path(ellipseIn: CGRect(x: m.x - 20, y: m.y - 20, width: 40, height: 40)), with: .color(moonColor))
        }

        for (i, star) in stars.enumerated() where !dawn || i % 2 == 0 {
            let r: CGFloat = i % 3 == 0 ? 1.8 : 1.2
            let hi = i % 2 == 1 ? 0.5 : 0.85, lo = i % 2 == 1 ? 0.15 : 0.35
            let period = 1.6 + Double(i % 5) * 0.35
            let opacity = moving ? lo + (hi - lo) * (0.5 + 0.5 * cos(2 * .pi * t / period)) : hi
            let p = CGPoint(x: star.0 * w, y: star.1 * h)
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r)), with: .color(.white.opacity(opacity)))
        }

        func hill(_ d: (CGFloat) -> Path, _ color: UInt32) { ctx.fill(d(0), with: .color(Color(hex: color))) }
        hill({ _ in
            var p = Path()
            p.move(to: CGPoint(x: 0, y: hy(300)))
            p.addCurve(to: CGPoint(x: 210 * sx, y: hy(296)), control1: CGPoint(x: 70 * sx, y: hy(270)), control2: CGPoint(x: 140 * sx, y: hy(282)))
            p.addCurve(to: CGPoint(x: w, y: hy(270)), control1: CGPoint(x: 280 * sx, y: hy(310)), control2: CGPoint(x: 330 * sx, y: hy(300)))
            p.addLine(to: CGPoint(x: w, y: h)); p.addLine(to: CGPoint(x: 0, y: h)); p.closeSubpath()
            return p
        }, hills[0])
        hill({ _ in
            var p = Path()
            p.move(to: CGPoint(x: 0, y: hy(340)))
            p.addCurve(to: CGPoint(x: 250 * sx, y: hy(332)), control1: CGPoint(x: 90 * sx, y: hy(316)), control2: CGPoint(x: 170 * sx, y: hy(340)))
            p.addCurve(to: CGPoint(x: w, y: hy(326)), control1: CGPoint(x: 330 * sx, y: hy(324)), control2: CGPoint(x: 350 * sx, y: hy(318)))
            p.addLine(to: CGPoint(x: w, y: h)); p.addLine(to: CGPoint(x: 0, y: h)); p.closeSubpath()
            return p
        }, hills[1])
        hill({ _ in
            var p = Path()
            p.move(to: CGPoint(x: 0, y: hy(380)))
            p.addCurve(to: CGPoint(x: 240 * sx, y: hy(378)), control1: CGPoint(x: 80 * sx, y: hy(368)), control2: CGPoint(x: 160 * sx, y: hy(386)))
            p.addCurve(to: CGPoint(x: w, y: hy(372)), control1: CGPoint(x: 320 * sx, y: hy(370)), control2: CGPoint(x: 350 * sx, y: hy(366)))
            p.addLine(to: CGPoint(x: w, y: h)); p.addLine(to: CGPoint(x: 0, y: h)); p.closeSubpath()
            return p
        }, hills[2])

        if !dawn {
            for (i, fly) in fireflies.enumerated() {
                let period = 5.0 + Double(i)
                let k = moving ? (1 - cos(2 * .pi * t / period)) / 2 : 0
                let c = CGPoint(x: fly.0 * w + (i % 2 == 1 ? 6 : -6) * k, y: hy(fly.1) - 8 * k)
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - 9, y: c.y - 9, width: 18, height: 18)), with: .radialGradient(
                    Gradient(colors: [glow.opacity(0.9), glow.opacity(0)]), center: c, startRadius: 0, endRadius: 9))
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - 1.8, y: c.y - 1.8, width: 3.6, height: 3.6)), with: .color(glow))
            }
        }

        let fade = CGRect(x: 0, y: h - 70, width: w, height: 70)
        ctx.fill(Path(fade), with: .linearGradient(Gradient(colors: [Color(hex: ground).opacity(0), Color(hex: ground)]),
                                                   startPoint: CGPoint(x: 0, y: fade.minY), endPoint: CGPoint(x: 0, y: fade.maxY)))
    }
}
