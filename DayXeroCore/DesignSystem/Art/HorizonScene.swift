import SwiftUI

/// The five v4 skies (dawn, dusk, path, sea, night), drawn from `Horizon2.dc.html` in its
/// 400 × 300 space. `clarity` 0–100 clears the haze as days clear go up
/// (`CrewGrowth.clarity(daysClear:)`). The paper-grain overlay is not drawn yet.
public enum HorizonKind: String, CaseIterable, Sendable {
    case dawn, dusk, path, sea, night
}

public struct HorizonScene: View {
    public enum Fit: Sendable { case top, middle, bottom }

    let kind: HorizonKind
    let clarity: Int
    let fit: Fit
    let animate: Bool
    @State private var appeared = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(_ kind: HorizonKind, clarity: Int = 100, fit: Fit = .middle, animate: Bool = true) {
        self.kind = kind
        self.clarity = min(100, max(0, clarity))
        self.fit = fit
        self.animate = animate
    }

    public var body: some View {
        let moving = animate && !reduceMotion
        let kind = kind, clarity = clarity, fit = fit, appeared = appeared
        TimelineView(.animation(paused: !moving)) { timeline in
            Canvas { ctx, size in
                // preserveAspectRatio "xMid… slice": cover, centred horizontally.
                let scale = max(size.width / 400, size.height / 300)
                let dx = (size.width - 400 * scale) / 2
                let slack = size.height - 300 * scale
                let dy: CGFloat = switch fit {
                case .top: 0
                case .middle: slack / 2
                case .bottom: slack
                }
                ctx.translateBy(x: dx, y: dy)
                ctx.scaleBy(x: scale, y: scale)
                let t = timeline.date.timeIntervalSinceReferenceDate
                let sinceAppear = timeline.date.timeIntervalSince(appeared)
                Horizon.draw(&ctx, kind: kind, clarity: clarity, time: t, sinceAppear: sinceAppear, animate: moving)
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }
}

/// Hero2: a horizon with a curved paper edge in the screen's ground colour along the bottom.
public struct HeroScene: View {
    let kind: HorizonKind
    let clarity: Int
    let height: CGFloat
    let edge: Color
    let animate: Bool

    public init(_ kind: HorizonKind, clarity: Int = 100, height: CGFloat = 300, edge: Color, animate: Bool = true) {
        self.kind = kind
        self.clarity = clarity
        self.height = height
        self.edge = edge
        self.animate = animate
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            HorizonScene(kind, clarity: clarity, fit: .bottom, animate: animate)
            PaperEdge()
                .fill(edge)
                .frame(height: 54)
                .shadow(color: Color(hex: 0x1A0B2E).opacity(0.26), radius: 6, x: 0, y: -4)
        }
        .frame(height: height)
        .clipped()
        .accessibilityHidden(true)
    }
}

/// The curve "M0 h-30 C110 h-54 280 h-54 390 h-30 L390 h L0 h Z", scaled to the width.
struct PaperEdge: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 390
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY - 30))
        p.addCurve(to: CGPoint(x: rect.minX + 390 * sx, y: rect.maxY - 30),
                   control1: CGPoint(x: rect.minX + 110 * sx, y: rect.maxY - 54),
                   control2: CGPoint(x: rect.minX + 280 * sx, y: rect.maxY - 54))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

enum Horizon {
    static func linear(_ stops: [(Double, UInt32)]) -> Gradient {
        Gradient(stops: stops.map { Gradient.Stop(color: Color(hex: $0.1), location: $0.0) })
    }

    static let dawnSky = linear([(0, 0xFF7E5A), (0.55, 0xFFB877), (1, 0xFFE6BF)])
    static let daySky = linear([(0, 0x5AA9FF), (1, 0xD3EEFF)])
    static let duskSky = linear([(0, 0x7A5CE0), (0.6, 0xE58BB8), (1, 0xFFC59A)])
    static let nightSky = linear([(0, 0x180F52), (1, 0x5A3CC4)])
    static let sun = linear([(0, 0xFFF6C8), (1, 0xFFC23A)])
    static let glow = Gradient(stops: [.init(color: .white.opacity(0.75), location: 0), .init(color: .white.opacity(0), location: 1)])
    static let sheen = Gradient(stops: [.init(color: .white.opacity(0.22), location: 0), .init(color: .white.opacity(0), location: 0.35)])

    static func sky(_ ctx: inout GraphicsContext, _ gradient: Gradient) {
        ctx.fill(Path(CGRect(x: 0, y: 0, width: 400, height: 300)),
                 with: .linearGradient(gradient, startPoint: .zero, endPoint: CGPoint(x: 0, y: 300)))
    }

    /// The sun's radial gradient sits up and left (cx 0.38, cy 0.32, r 0.75 of the bounding box).
    static func sunDisc(_ ctx: inout GraphicsContext, _ cx: Double, _ cy: Double, _ r: Double) {
        let center = CGPoint(x: cx - r + 0.38 * 2 * r, y: cy - r + 0.32 * 2 * r)
        ctx.fill(Crew.circle(cx, cy, r), with: .radialGradient(sun, center: center, startRadius: 0, endRadius: 0.75 * 2 * r))
    }

    static func glowDisc(_ ctx: inout GraphicsContext, _ cx: Double, _ cy: Double, _ r: Double, opacity: Double) {
        var g = ctx
        g.opacity = opacity
        g.fill(Crew.circle(cx, cy, r), with: .radialGradient(glow, center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: r))
    }

    /// A paper layer with the upward "lift" shadow.
    static func layer(_ ctx: inout GraphicsContext, _ d: String, _ hex: UInt32) {
        var l = ctx
        l.addFilter(.shadow(color: Color(hex: 0x1A0B2E).opacity(0.22), radius: 4, x: 0, y: -3))
        l.fill(SVGPath.path(d), with: .color(Color(hex: hex)))
    }

    static func clouds(_ ctx: inout GraphicsContext, _ ellipses: [(Double, Double, Double, Double)], _ hex: UInt32,
                       opacity: Double, period: Double, time: Double, animate: Bool) {
        let drift = ArtTrack(scalars: [0, 22, 0], duration: period).scalar(at: time, animate: animate)
        var c = ctx
        c.opacity = opacity
        c.addFilter(.blur(radius: 4))
        c.translateBy(x: drift, y: 0)
        for e in ellipses { c.fill(Crew.ellipse(e.0, e.1, e.2, e.3), with: .color(Color(hex: hex))) }
    }

    static func twinkle(_ time: Double, period: Double, begin: Double = 0, animate: Bool) -> Double {
        animate ? ArtTrack(scalars: [0.25, 1, 0.25], duration: period, begin: begin).scalar(at: time) : 1
    }

    static func draw(_ ctx: inout GraphicsContext, kind: HorizonKind, clarity: Int, time t: Double, sinceAppear: Double, animate on: Bool) {
        let fog = 1 - Double(clarity) / 100
        let haze: UInt32 = kind == .night ? 0x8E80C9 : (kind == .dusk ? 0xE9D6F0 : 0xF3ECE3)
        func hazeRect(_ opacity: Double) {
            guard opacity > 0 else { return }
            ctx.fill(Path(CGRect(x: 0, y: 0, width: 400, height: 300)), with: .color(Color(hex: haze).opacity(opacity)))
        }
        let pulse = on ? ArtTrack(scalars: [120, 140, 120], duration: 6).scalar(at: t) : 130

        switch kind {
        case .dawn:
            sky(&ctx, dawnSky)
            glowDisc(&ctx, 200, 168, pulse, opacity: 0.6)
            let sunY = 168 + (fog * 20).rounded()
            // The sun rises 60 pt over 2.6 s when the scene appears, then stays.
            let rise = on ? ArtTrack.cubic(sinceAppear / 2.6, 0.2, 0.7, 0.2, 1) : 1
            sunDisc(&ctx, 200, sunY + 60 * (1 - rise), 70)
            clouds(&ctx, [(70, 86, 46, 14), (98, 74, 28, 14), (330, 62, 40, 12)], 0xFFF4E6, opacity: 0.85, period: 24, time: t, animate: on)
            hazeRect(fog * 0.7)
            layer(&ctx, "M0 192 C60 162 120 172 180 187 C250 204 320 172 400 166 L400 300 L0 300 Z", 0xFF9D6E)
            let middle = "M0 222 C80 196 150 206 220 224 C290 240 350 216 400 206 L400 300 L0 300 Z"
            layer(&ctx, middle, 0xFF7A55)
            layer(&ctx, "M0 252 C70 233 140 241 210 256 C280 271 340 251 400 243 L400 300 L0 300 Z", 0xE85A3E)
            layer(&ctx, "M0 282 C90 267 180 273 260 283 C320 291 360 285 400 279 L400 300 L0 300 Z", 0xC2402A)
            ctx.fill(SVGPath.path(middle), with: .linearGradient(sheen, startPoint: CGPoint(x: 0, y: 196), endPoint: CGPoint(x: 0, y: 300)))
            var star = ctx
            star.opacity = twinkle(t, period: 2.2, animate: on)
            star.fill(SVGPath.path("M330 34 Q330 46 342 46 Q330 46 330 58 Q330 46 318 46 Q330 46 330 34 Z"), with: .color(Color(hex: 0xFFF8EE)))

        case .dusk:
            sky(&ctx, duskSky)
            glowDisc(&ctx, 300, 190, 110, opacity: 0.45)
            ctx.fill(Crew.circle(300, 196, 44), with: .color(Color(hex: 0xFFB86B)))
            clouds(&ctx, [(90, 80, 52, 14), (120, 68, 30, 14)], 0xFFE0EE, opacity: 0.8, period: 26, time: t, animate: on)
            for (x, y, r, period, begin) in [(70.0, 40.0, 1.6, 1.9, 0.0), (200, 30, 1.4, 2.6, 0.7)] {
                ctx.fill(Crew.circle(x, y, r), with: .color(Color(hex: 0xFFF8EE).opacity(twinkle(t, period: period, begin: begin, animate: on))))
            }
            hazeRect(fog * 0.7)
            layer(&ctx, "M0 196 C70 170 140 178 200 192 C270 208 330 180 400 172 L400 300 L0 300 Z", 0xB572C9)
            layer(&ctx, "M0 228 C90 202 160 212 230 230 C300 246 350 222 400 214 L400 300 L0 300 Z", 0x8E55BF)
            layer(&ctx, "M0 258 C80 238 150 246 220 262 C290 278 350 258 400 250 L400 300 L0 300 Z", 0x6A3AA8)
            layer(&ctx, "M0 286 C90 272 160 278 240 288 C310 296 360 290 400 284 L400 300 L0 300 Z", 0x4A2588)

        case .path:
            sky(&ctx, daySky)
            glowDisc(&ctx, 300, 78, 70, opacity: 0.6)
            sunDisc(&ctx, 300, 78, 30)
            clouds(&ctx, [(80, 70, 50, 15), (110, 58, 30, 15), (370, 130, 40, 12)], 0xFFFFFF, opacity: 0.9, period: 22, time: t, animate: on)
            hazeRect(fog * 0.7)
            layer(&ctx, "M0 176 C70 150 140 158 200 172 C270 188 330 160 400 150 L400 300 L0 300 Z", 0x9FE3AE)
            ctx.fill(SVGPath.path("M70 168 L78 146 L86 168 Z M92 166 L98 150 L104 166 Z"), with: .color(Color(hex: 0x3FA868)))
            let middle = "M0 210 C90 184 160 194 230 212 C300 228 350 204 400 196 L400 300 L0 300 Z"
            layer(&ctx, middle, 0x5CC984)
            layer(&ctx, "M0 246 C80 226 150 234 220 250 C290 266 350 246 400 238 L400 300 L0 300 Z", 0x2FA262)
            ctx.fill(SVGPath.path("M176 300 C188 282 236 272 228 256 C222 244 202 236 206 224 L212 224 C212 236 236 244 242 258 C252 278 216 288 224 300 Z"),
                     with: .color(Color(hex: 0xFFF1D2)))
            layer(&ctx, "M0 284 C90 270 160 276 240 286 C310 294 360 288 400 282 L400 300 L0 300 Z", 0x1E7A4B)
            ctx.fill(SVGPath.path(middle), with: .linearGradient(sheen, startPoint: CGPoint(x: 0, y: 184), endPoint: CGPoint(x: 0, y: 300)))

        case .sea:
            sky(&ctx, daySky)
            let seaPulse = on ? ArtTrack(scalars: [120, 140, 120], duration: 10).scalar(at: t) : 130
            glowDisc(&ctx, 110, 96, seaPulse, opacity: 0.6)
            sunDisc(&ctx, 110, 96, 34)
            clouds(&ctx, [(300, 64, 56, 15), (330, 52, 30, 14)], 0xFFFFFF, opacity: 0.9, period: 20, time: t, animate: on)
            hazeRect(fog * 0.7)
            func wave(_ values: [[Double]], _ period: Double, _ draw: (inout GraphicsContext) -> Void) {
                let o = ArtTrack(values, duration: period).value(at: t, animate: on)
                var w = ctx
                w.translateBy(x: o[0], y: o[1])
                draw(&w)
            }
            let a: [[Double]] = [[0, 0], [-18, 2], [0, 0]]
            let b: [[Double]] = [[0, 0], [20, -3], [0, 0]]
            let c: [[Double]] = [[0, 0], [-26, 3], [0, 0]]
            wave(a, 7) { layer(&$0, "M-40 176 C10 166 60 172 110 168 C180 162 260 170 440 164 L440 300 L-40 300 Z", 0x9CCBFF) }
            wave(b, 5) { layer(&$0, "M-40 206 C20 190 70 196 120 208 C180 222 240 196 300 194 C350 193 400 198 440 202 L440 300 L-40 300 Z", 0x5A9DFF) }
            wave(c, 6) {
                layer(&$0, "M-40 240 C10 222 60 226 110 240 C160 254 210 230 260 228 C320 226 380 234 440 240 L440 300 L-40 300 Z", 0x2F72F2)
                $0.fill(SVGPath.path("M90 236 C102 222 122 220 132 232 C120 230 110 234 104 242 Z"), with: .color(Color(hex: 0xFFF8EE)))
            }
            wave(b, 8) { layer(&$0, "M-40 276 C20 262 80 266 140 276 C200 286 260 268 440 272 L440 300 L-40 300 Z", 0x1C4FCC) }
            let bubbleY = on ? ArtTrack(scalars: [270, 170], duration: 5).scalar(at: t) : 260
            ctx.fill(Crew.circle(300, bubbleY, 3), with: .color(.white.opacity(0.7)))

        case .night:
            sky(&ctx, nightSky)
            let stars: [(Double, Double, Double, Double, Double)] = [
                (60, 40, 1.8, 2, 0), (150, 24, 1.4, 2.7, 0.4), (230, 60, 1.6, 1.8, 1), (360, 110, 1.4, 2.4, 0.2), (30, 120, 1.2, 3, 0.9),
            ]
            for (x, y, r, period, begin) in stars {
                ctx.fill(Crew.circle(x, y, r), with: .color(Color(hex: 0xFFF8EE).opacity(twinkle(t, period: period, begin: begin, animate: on))))
            }
            glowDisc(&ctx, 290, 80, 70, opacity: 0.35)
            ctx.fill(SVGPath.path("M290 46 A34 34 0 1 0 322 98 A28 28 0 1 1 290 46 Z"), with: .color(Color(hex: 0xFFF1C2)))
            hazeRect(fog * 0.7)
            layer(&ctx, "M0 184 C70 158 140 166 200 180 C270 196 330 168 400 160 L400 300 L0 300 Z", 0x5A3CC4)
            layer(&ctx, "M0 218 C90 192 160 202 230 220 C300 236 350 212 400 204 L400 300 L0 300 Z", 0x432AA6)
            layer(&ctx, "M0 252 C80 232 150 240 220 256 C290 272 350 252 400 244 L400 300 L0 300 Z", 0x2F1C84)
            layer(&ctx, "M0 284 C90 270 160 276 240 286 C310 294 360 288 400 282 L400 300 L0 300 Z", 0x1C1160)
            // Fireflies drift together.
            let fly = ArtTrack([[0, 0], [14, -10], [-8, -4], [0, 0]], duration: 9).value(at: t, animate: on)
            var f = ctx
            f.translateBy(x: fly[0], y: fly[1])
            let yellow = Color(hex: 0xFFE27A)
            for (x, y, r, halo, period, begin) in [(96.0, 230.0, 3.0, 8.0, 1.6, 0.0), (300, 250, 2.5, 7, 2.1, 0.5), (190, 214, 2, 0, 1.3, 0.2)] {
                f.fill(Crew.circle(x, y, r), with: .color(yellow.opacity(twinkle(t, period: period, begin: begin, animate: on))))
                if halo > 0 { f.fill(Crew.circle(x, y, halo), with: .color(yellow.opacity(0.25))) }
            }
        }
        hazeRect(fog * 0.35)
    }
}
