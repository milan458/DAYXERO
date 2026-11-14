import DayXeroCore
import SwiftUI

// MARK: - Shared painting helpers

/// Small painting helpers for the calm scenes (v5, 056-060), in the mockups' own SVG coordinates.
enum CalmPaint {
    static func gradient(_ stops: [(Double, UInt32)]) -> Gradient {
        Gradient(stops: stops.map { .init(color: Color(hex: $0.1), location: $0.0) })
    }

    /// A vertical gradient: two stops, or three with the middle one at 60% (kit `grad`).
    static func vertical(_ a: UInt32, _ b: UInt32, _ c: UInt32? = nil) -> Gradient {
        if let c { return gradient([(0, a), (0.6, b), (1, c)]) }
        return gradient([(0, a), (1, b)])
    }

    static func circle(_ x: Double, _ y: Double, _ r: Double) -> Path {
        Path(ellipseIn: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r))
    }

    static func ellipse(_ x: Double, _ y: Double, _ rx: Double, _ ry: Double) -> Path {
        Path(ellipseIn: CGRect(x: x - rx, y: y - ry, width: 2 * rx, height: 2 * ry))
    }

    /// A soft radial glow: `color` at `opacity` in the middle, clear at the edge.
    static func glow(_ ctx: inout GraphicsContext, _ x: Double, _ y: Double, _ r: Double, _ hex: UInt32, _ opacity: Double,
                     mid: (Double, Double)? = nil) {
        var stops: [Gradient.Stop] = [.init(color: Color(hex: hex).opacity(opacity), location: 0)]
        if let mid { stops.append(.init(color: Color(hex: hex).opacity(mid.1), location: mid.0)) }
        stops.append(.init(color: Color(hex: hex).opacity(0), location: 1))
        ctx.fill(circle(x, y, r), with: .radialGradient(Gradient(stops: stops), center: CGPoint(x: x, y: y), startRadius: 0, endRadius: r))
    }

    /// White stars, every other one dimmer (kit `stars`).
    static func stars(_ ctx: inout GraphicsContext, _ points: [(Double, Double, Double)], opacity: Double) {
        for (i, p) in points.enumerated() {
            ctx.fill(circle(p.0, p.1, p.2), with: .color(.white.opacity(i % 2 == 1 ? opacity * 0.6 : opacity)))
        }
    }

    static func fill(_ ctx: inout GraphicsContext, _ d: String, _ hex: UInt32, opacity: Double = 1) {
        ctx.fill(SVGPath.path(d), with: .color(Color(hex: hex).opacity(opacity)))
    }
}

// MARK: - The sea window

/// The sea seen through the Box breathing window, the done disc and the Box tile (v5, 056, 057, 060).
/// Light: the kit sea with a flat sun and no grain, without the white crescent in the water; its waves drift.
/// Dark: the night sea, the low sun off to the left, layered water and a soft sea floor.
struct CalmSea: View {
    var animate = true
    @Environment(\.colorScheme) private var scheme
    private let motion = MotionPolicy()

    var body: some View {
        let on = animate && motion.breathes
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !on || scheme == .dark)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                if scheme == .dark { Self.night(&ctx, size) } else { Self.day(&ctx, size, t: on ? t : nil) }
            }
        }
        .accessibilityHidden(true)
    }

    /// The kit sea (viewBox 400 × 300), cropped to fill the frame from the middle.
    static func day(_ ctx: inout GraphicsContext, _ size: CGSize, t: Double?) {
        let k = max(size.width / 400, size.height / 300)
        ctx.translateBy(x: (size.width - 400 * k) / 2, y: (size.height - 300 * k) / 2)
        ctx.scaleBy(x: k, y: k)
        ctx.fill(Path(CGRect(x: 0, y: 0, width: 400, height: 300)),
                 with: .linearGradient(CalmPaint.vertical(0x5AA9FF, 0xD3EEFF), startPoint: .zero, endPoint: CGPoint(x: 0, y: 300)))
        func swing(_ amp: Double, _ period: Double) -> Double {
            guard let t else { return 0 }
            return amp * (1 - cos(2 * .pi * t / period)) / 2
        }
        CalmPaint.glow(&ctx, 110, 96, 130 + swing(10, 10) * 2 - 10, 0xFFFFFF, 0.45)
        ctx.fill(CalmPaint.circle(110, 96, 34), with: .color(Color(hex: 0xFFCB4A)))
        do {
            var c = ctx
            c.opacity = 0.9
            c.addFilter(.blur(radius: 4))
            c.translateBy(x: swing(22, 20), y: 0)
            c.fill(CalmPaint.ellipse(300, 64, 56, 15), with: .color(.white))
            c.fill(CalmPaint.ellipse(330, 52, 30, 14), with: .color(.white))
        }
        func layer(_ d: String, _ hex: UInt32, dx: Double, dy: Double) {
            var l = ctx
            l.translateBy(x: dx, y: dy)
            l.addFilter(.shadow(color: Color(hex: 0x1A0B2E).opacity(0.22), radius: 4, x: 0, y: -3))
            l.fill(SVGPath.path(d), with: .color(Color(hex: hex)))
        }
        layer("M-40 176 C10 166 60 172 110 168 C180 162 260 170 440 164 L440 300 L-40 300 Z", 0x9CCBFF,
              dx: -swing(18, 7), dy: swing(2, 7))
        layer("M-40 206 C20 190 70 196 120 208 C180 222 240 196 300 194 C350 193 400 198 440 202 L440 300 L-40 300 Z", 0x5A9DFF,
              dx: swing(20, 5), dy: -swing(3, 5))
        layer("M-40 240 C10 222 60 226 110 240 C160 254 210 230 260 228 C320 226 380 234 440 240 L440 300 L-40 300 Z", 0x2F72F2,
              dx: -swing(26, 6), dy: swing(3, 6))
        layer("M-40 276 C20 262 80 266 140 276 C200 286 260 268 440 272 L440 300 L-40 300 Z", 0x1C4FCC,
              dx: swing(20, 8), dy: -swing(3, 8))
        if let t {
            let y = 270 - 100 * (t.truncatingRemainder(dividingBy: 5) / 5)
            ctx.fill(CalmPaint.circle(300, y, 3), with: .color(.white.opacity(0.7)))
        }
    }

    /// The night sea (viewBox 260 × 260), cropped to fill the frame from the middle.
    static func night(_ ctx: inout GraphicsContext, _ size: CGSize) {
        let k = max(size.width, size.height) / 260
        ctx.translateBy(x: (size.width - 260 * k) / 2, y: (size.height - 260 * k) / 2)
        ctx.scaleBy(x: k, y: k)
        ctx.fill(Path(CGRect(x: 0, y: 0, width: 260, height: 260)),
                 with: .linearGradient(CalmPaint.vertical(0x0C1838, 0x1A2C5C, 0x2E4680), startPoint: .zero, endPoint: CGPoint(x: 0, y: 260)))
        CalmPaint.stars(&ctx, [(150, 30, 1.6), (214, 58, 1.2), (112, 70, 1.1), (236, 22, 1.4), (184, 100, 1), (24, 24, 1.2)], opacity: 0.8)
        var glow = ctx
        glow.fill(CalmPaint.circle(52, 84, 64), with: .radialGradient(Gradient(stops: [
            .init(color: Color(hex: 0xFFD27A).opacity(0.42), location: 0),
            .init(color: Color(hex: 0xFFB25E).opacity(0.12), location: 0.5),
            .init(color: Color(hex: 0xFFB25E).opacity(0), location: 1),
        ]), center: CGPoint(x: 52, y: 84), startRadius: 0, endRadius: 64))
        ctx.fill(CalmPaint.circle(52, 84, 21), with: .color(Color(hex: 0xFFD27A)))
        ctx.fill(SVGPath.path("M0 150 C60 144 120 153 180 147 S 240 144 260 148 V260 H0Z"),
                 with: .linearGradient(CalmPaint.vertical(0x2A52A6, 0x173372), startPoint: CGPoint(x: 0, y: 144), endPoint: CGPoint(x: 0, y: 260)))
        ctx.fill(CalmPaint.ellipse(54, 163, 30, 4), with: .color(Color(hex: 0xFFD27A).opacity(0.22)))
        ctx.fill(CalmPaint.ellipse(54, 163, 14, 2.2), with: .color(Color(hex: 0xFFE2A6).opacity(0.4)))
        CalmPaint.fill(&ctx, "M0 184 C60 174 130 188 190 178 S 245 174 260 178 V260 H0Z", 0x1A3A80, opacity: 0.75)
        ctx.stroke(SVGPath.path("M0 184 C60 174 130 188 190 178 S 245 174 260 178"),
                   with: .color(Color(hex: 0x9DB8FF).opacity(0.18)), lineWidth: 2)
        ctx.fill(SVGPath.path("M0 228 C50 216 100 224 150 218 S 228 212 260 220 V260 H0Z"),
                 with: .linearGradient(CalmPaint.vertical(0x3E5590, 0x2C3F74), startPoint: CGPoint(x: 0, y: 212), endPoint: CGPoint(x: 0, y: 260)))
        ctx.fill(CalmPaint.ellipse(206, 236, 11, 4.5), with: .color(Color(hex: 0x566CA6)))
        ctx.fill(CalmPaint.ellipse(44, 240, 7, 3), with: .color(Color(hex: 0x566CA6)))
    }
}

// MARK: - The four tool tiles (056)

/// One tool tile's scene, 164 high, drawn on the mockup's 167-wide stage and stretched to the tile's width.
/// Each tile has its own palette (ocean blue, apricot dawn, a dusk sea, midnight); dark mode keeps them darker.
/// Its cast member settles in `castDelay` after the tile arrives and keeps an idle loop.
struct CalmTileArt: View {
    let tool: CalmTool
    var castDelay: Double = 0
    @Environment(\.colorScheme) private var scheme
    private let motion = MotionPolicy()

    static let height: CGFloat = 164
    private static let stage: CGFloat = 167

    var body: some View {
        GeometryReader { geo in
            let sx = geo.size.width / Self.stage
            ZStack(alignment: .topLeading) {
                backdrop(sx: sx)
                cast(sx: sx)
            }
        }
        .frame(height: Self.height)
        .clipped()
        .accessibilityHidden(true)
    }

    // MARK: Backdrops

    @ViewBuilder
    private func backdrop(sx: CGFloat) -> some View {
        let dark = scheme == .dark
        switch tool {
        case .boxBreathing:
            BoxTileTrack(sx: sx, dark: dark)
        default:
            Canvas { ctx, size in
                ctx.scaleBy(x: sx, y: 1)
                let w = Self.stage
                switch tool {
                case .grounding: Self.dawn(&ctx, w: w, dark: dark)
                case .noticeAndName: Self.dusk(&ctx, w: w, dark: dark)
                default: Self.midnight(&ctx, w: w, dark: dark)
                }
            }
        }
    }

    private static func sky(_ ctx: inout GraphicsContext, _ g: Gradient, w: Double) {
        ctx.fill(Path(CGRect(x: 0, y: 0, width: w, height: 164)), with: .linearGradient(g, startPoint: .zero, endPoint: CGPoint(x: 0, y: 164)))
    }

    /// Grounding: apricot dawn (light), a warm pre-dawn (dark). The stage sits 32 down.
    private static func dawn(_ ctx: inout GraphicsContext, w: Double, dark: Bool) {
        if dark {
            sky(&ctx, CalmPaint.vertical(0x1C1A2A, 0x4A2E2A, 0x8A4A30), w: w)
            ctx.translateBy(x: 0, y: 32)
            CalmPaint.stars(&ctx, [(22, 20, 1.2), (60, 6, 1.2), (146, 14, 1.4), (104, 26, 1.2)], opacity: 0.6)
            CalmPaint.glow(&ctx, 124, 88, 46, 0xFFB86E, 0.55, mid: (0.45, 0.18))
            ctx.fill(CalmPaint.circle(124, 88, 14), with: .color(Color(hex: 0xFFC27A)))
            CalmPaint.fill(&ctx, "M0 98 C40 86 80 90 167 102 V132 H0Z", 0x4A2C24)
            CalmPaint.fill(&ctx, "M0 114 C50 104 110 108 167 116 V132 H0Z", 0x33201C)
        } else {
            sky(&ctx, CalmPaint.vertical(0xFFE6BF, 0xFFCB95), w: w)
            ctx.translateBy(x: 0, y: 32)
            ctx.fill(CalmPaint.circle(124, 44, 38), with: .color(Color(hex: 0xFFF1C9).opacity(0.7)))
            ctx.fill(CalmPaint.circle(124, 44, 24), with: .color(Color(hex: 0xFFD966)))
            CalmPaint.fill(&ctx, "M0 98 C40 86 80 90 167 102 V132 H0Z", 0xFFA068)
            ctx.stroke(SVGPath.path("M0 98 C40 86 80 90 167 102"), with: .color(Color(hex: 0xFFC08A)), lineWidth: 2)
            CalmPaint.fill(&ctx, "M0 114 C50 104 110 108 167 116 V132 H0Z", 0xF98C5C)
            ctx.fill(CalmPaint.ellipse(58, 92, 23, 3.6), with: .color(Color(hex: 0xB8532C).opacity(0.32)))
        }
    }

    /// Notice the urge: a dusk sea, a low sun beside a long low swell. The stage sits 32 down.
    private static func dusk(_ ctx: inout GraphicsContext, w: Double, dark: Bool) {
        let swell = "M0 110 C36 110 50 76 84 76 S 132 110 167 110"
        if dark {
            sky(&ctx, CalmPaint.vertical(0x0C1C30, 0x1F3D55, 0x6A5548), w: w)
            ctx.translateBy(x: 0, y: 32)
            CalmPaint.stars(&ctx, [(20, 18, 1.2), (44, 40, 1.2), (150, 16, 1.4), (128, 44, 1.2)], opacity: 0.6)
            CalmPaint.glow(&ctx, 138, 80, 22, 0xFFC27A, 0.45)
            ctx.fill(CalmPaint.circle(138, 80, 8), with: .color(Color(hex: 0xFFC27A)))
            CalmPaint.fill(&ctx, swell + " V132 H0Z", 0x244A72)
        } else {
            sky(&ctx, CalmPaint.vertical(0x5F95AE, 0xCDBBA6, 0xF8C9A2), w: w)
            ctx.translateBy(x: 0, y: 32)
            CalmPaint.glow(&ctx, 138, 80, 22, 0xFFF1C9, 0.8)
            ctx.fill(CalmPaint.circle(138, 80, 8), with: .color(Color(hex: 0xFFD97A)))
            CalmPaint.fill(&ctx, swell + " V132 H0Z", 0x2F5E8E)
        }
        ctx.stroke(SVGPath.path(swell), with: .color(Color(hex: 0xFFF8EE)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        CalmPaint.fill(&ctx, "M0 120 C40 115 90 118 167 115 V132 H0Z", dark ? 0x183656 : 0x244C7A)
    }

    /// Wind down: night blue with the moon, and two dark hills. The stage sits 32 down.
    private static func midnight(_ ctx: inout GraphicsContext, w: Double, dark: Bool) {
        sky(&ctx, dark ? CalmPaint.vertical(0x08101F, 0x16244A, 0x22315A) : CalmPaint.vertical(0x0B1430, 0x1B2B55, 0x2C3D6A), w: w)
        ctx.translateBy(x: 0, y: 32)
        CalmPaint.stars(&ctx, [(18, 20, 1.2), (46, 40, 1.2), (84, 14, 1.5), (104, 44, 1.2), (150, 70, 1.2), (20, 70, 1.4)], opacity: 0.85)
        CalmPaint.glow(&ctx, 130, 34, 30, 0xF6E7C1, 0.3)
        // The moon: a disc with a bite out of its upper right (the kit's moon glyph at 1.6×).
        var moon = ctx
        moon.clip(to: CalmPaint.circle(139.6, 28.8, 12), options: .inverse)
        moon.fill(CalmPaint.circle(132, 36.4, 12), with: .color(Color(hex: 0xF6E7C1)))
        CalmPaint.fill(&ctx, "M0 102 C40 92 90 96 167 106 V132 H0Z", 0x1C2C4E)
        CalmPaint.fill(&ctx, "M0 116 C50 108 110 112 167 118 V132 H0Z", 0x132240)
    }

    // MARK: Cast

    @ViewBuilder
    private func cast(sx: CGFloat) -> some View {
        let on = motion.breathes
        switch tool {
        case .boxBreathing:
            // Jelli breathes in the sea window.
            ZStack(alignment: .topLeading) {
                CalmSea()
                JelliView(mood: .breathe, stage: 1, points: 70, animate: on)
                    .offset(x: 5, y: 6)
                    .dxSettle(0, delay: castDelay)
            }
            .frame(width: 80, height: 80, alignment: .topLeading)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .offset(x: 43.5 * sx, y: 42)
        case .grounding:
            JelliView(mood: .calm, stage: 1, points: 84, animate: on)
                .offset(x: 16 * sx, y: scheme == .dark ? 49 : 47)
                .dxSettle(0, delay: castDelay)
        case .noticeAndName:
            JelliView(mood: .calm, stage: 1, points: 76, animate: on)
                .offset(x: 46 * sx, y: 37)
                .dxSettle(0, delay: castDelay)
        default:
            GlimView(mood: .sleepy, stage: 1, points: 82, animate: on)
                .offset(x: 24 * sx, y: 58)
                .dxSettle(0, delay: castDelay)
        }
    }
}

/// The Box tile's ocean blue, with one track round the window: the faint frame, the lit side that steps on at each corner,
/// and the dot walking it at the breathing pace (16 s a round). The stage sits 16 down.
private struct BoxTileTrack: View {
    let sx: CGFloat
    let dark: Bool
    private let motion = MotionPolicy()

    /// The track, from the bottom of the left side, up and round (kit `T`).
    static let track = "M38 99 V33 Q38 21 50 21 H117 Q129 21 129 33 V99 Q129 111 117 111 H50 Q38 111 38 99Z"

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !motion.breathes)) { timeline in
            // The loop starts 2 s in, so the dot is already on its way (kit `begin="-2s"`).
            let t = motion.breathes ? timeline.date.timeIntervalSinceReferenceDate + 2 : 0
            let around = t.truncatingRemainder(dividingBy: 16) / 16
            Canvas { ctx, size in
                ctx.scaleBy(x: sx, y: 1)
                ctx.fill(Path(CGRect(x: 0, y: 0, width: 167, height: 164)),
                         with: .linearGradient(dark ? CalmPaint.vertical(0x22409A, 0x0F2366) : CalmPaint.vertical(0x3A63E0, 0x1F3C8C),
                                               startPoint: .zero, endPoint: CGPoint(x: 0, y: 164)))
                ctx.translateBy(x: 0, y: 16)
                CalmPaint.stars(&ctx, [(18, 22, 1.2), (148, 18, 1.4), (150, 112, 1.2), (16, 104, 1.5)], opacity: 0.55)
                let path = SVGPath.path(Self.track)
                let cream = Color(hex: 0xFFF8EE)
                ctx.stroke(path, with: .color(cream.opacity(0.38)), lineWidth: 2.5)
                let side = floor(around * 4) / 4
                ctx.stroke(path.trimmedPath(from: side, to: side + 0.25), with: .color(cream),
                           style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                let dot = motion.breathes ? path.trimmedPath(from: 0, to: max(around, 0.0001)).currentPoint ?? CGPoint(x: 38, y: 66)
                    : CGPoint(x: 38, y: 66)
                ctx.fill(CalmPaint.circle(dot.x, dot.y, 5.5), with: .color(cream))
            }
        }
    }
}
