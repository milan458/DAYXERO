import SwiftUI

/// The illustration kit (decision 31): flat shapes in 2–3 tones with a soft glow, drawn from the
/// "Final screens" canvas's `Art.dc.html`. Two layers: the ground and its bleed layers (sky, sea, hills,
/// rings) fill the panel and are clipped by its corners; the subject is scaled into a square safe area
/// inset at least 12% from every edge, so it is never cut off at any panel size.
public struct KitArt: View {
    public enum Kind: String, CaseIterable, Sendable {
        case dawn, sea, sprout, night, breath, peak, sparkle, clouds, flower
        case cup, eye, glass, heart
        case box, outbreath, grounding, tag, anchor
        case berry, lungs, lips, shield
    }

    let kind: Kind
    let cornerRadius: CGFloat
    let animate: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(_ kind: Kind, cornerRadius: CGFloat = 28, animate: Bool = true) {
        self.kind = kind
        self.cornerRadius = cornerRadius
        self.animate = animate
    }

    public var body: some View {
        let moving = animate && !reduceMotion
        let kind = kind, radius = cornerRadius
        TimelineView(.animation(paused: !moving)) { timeline in
            Canvas { ctx, size in
                KitDraw.draw(&ctx, kind: kind, size: size, radius: radius, time: timeline.date.timeIntervalSinceReferenceDate, on: moving)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .accessibilityHidden(true)
    }
}

/// Drawing for `KitArt`. Coordinates follow `Art.dc.html`: layers in a 200 × 140 space (slice),
/// subjects in a 100 × 100 space (meet, inside the safe area).
enum KitDraw {
    struct Spec {
        let top: UInt32
        let bottom: UInt32
        var layers: [Layer] = []
        var hills: (UInt32, UInt32) = (0x3E9E6A, 0x2F8A5A)
    }

    enum Layer { case rings, pulse, sea, hill, floor }

    static let cream: UInt32 = 0xFFF8EE
    static let ink: UInt32 = 0x1E1A3A
    static let sun: UInt32 = 0xFFD966

    static func spec(_ kind: KitArt.Kind) -> Spec {
        switch kind {
        case .dawn: Spec(top: 0xFF7A55, bottom: 0xFFC38A, layers: [.rings])
        case .sea: Spec(top: 0x2A52DB, bottom: 0x9CCBFF, layers: [.sea])
        case .sprout: Spec(top: 0x6FCB98, bottom: 0x9FE3BC, layers: [.hill], hills: (0x3E9E6A, 0x2F8A5A))
        case .night: Spec(top: 0x2A1C6E, bottom: 0x4A3596, layers: [.hill], hills: (0x1E1458, 0x2A1C6E))
        case .breath: Spec(top: 0x2A52DB, bottom: 0x5B7FF0, layers: [.pulse])
        case .peak: Spec(top: 0xFF8FB8, bottom: 0xFFC3D8)
        case .sparkle: Spec(top: 0xFFC94A, bottom: 0xFFD966, layers: [.rings])
        case .clouds: Spec(top: 0x4A3596, bottom: 0x8E73F0)
        case .flower: Spec(top: 0xFF7A55, bottom: 0xFFA46B)
        case .cup: Spec(top: 0xFFA46B, bottom: 0xFFC38A, layers: [.rings])
        case .eye: Spec(top: 0x8E73F0, bottom: 0xB9A6FF, layers: [.rings])
        case .glass: Spec(top: 0x5B7FF0, bottom: 0x9CCBFF, layers: [.rings])
        case .heart: Spec(top: 0xFF7A55, bottom: 0xFF8FB8, layers: [.rings])
        case .box: Spec(top: 0xFFC94A, bottom: 0xFFD966)
        case .outbreath: Spec(top: 0x6FCB98, bottom: 0x9FE3BC)
        case .grounding: Spec(top: 0x3E9E6A, bottom: 0x6FCB98)
        case .tag: Spec(top: 0xFF8FB8, bottom: 0xFFB3CF)
        case .anchor: Spec(top: 0xFFA46B, bottom: 0xFFC38A, layers: [.floor], hills: (0xE8894A, 0xE8894A))
        case .berry: Spec(top: 0xFFD966, bottom: 0xFFE59A, layers: [.rings])
        case .lungs: Spec(top: 0x5B7FF0, bottom: 0x9CCBFF, layers: [.rings])
        case .lips: Spec(top: 0xFFC3D8, bottom: 0xFFE1EC, layers: [.rings])
        case .shield: Spec(top: 0x3E9E6A, bottom: 0x6FCB98, layers: [.rings])
        }
    }

    /// The subject's safe square: inset at least 12% of the short side, and never less than 30% of the corner radius.
    static func safeArea(_ size: CGSize, radius: CGFloat) -> CGRect {
        let inset = max((min(size.width, size.height) * 0.12).rounded(), (radius * 0.3).rounded(), 6)
        let side = max(min(size.width, size.height) - inset * 2, 1)
        return CGRect(x: (size.width - side) / 2, y: (size.height - side) / 2, width: side, height: side)
    }

    static func draw(_ ctx: inout GraphicsContext, kind: KitArt.Kind, size: CGSize, radius: CGFloat, time t: Double, on: Bool) {
        let s = spec(kind)
        ctx.fill(Path(CGRect(origin: .zero, size: size)),
                 with: .linearGradient(Gradient(colors: [Color(hex: s.top), Color(hex: s.bottom)]), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))

        // Layers: 200 × 140, scaled to fill (slice) and centred.
        var layer = ctx
        let scale = max(size.width / 200, size.height / 140)
        layer.translateBy(x: (size.width - 200 * scale) / 2, y: (size.height - 140 * scale) / 2)
        layer.scaleBy(x: scale, y: scale)
        for l in s.layers { drawLayer(&layer, l, spec: s, t: t, on: on) }

        // Subject: 100 × 100, scaled into the safe square.
        var subject = ctx
        let safe = safeArea(size, radius: radius)
        subject.translateBy(x: safe.minX, y: safe.minY)
        subject.scaleBy(x: safe.width / 100, y: safe.height / 100)
        drawSubject(&subject, kind, bottom: s.bottom, t: t, on: on)
    }

    // MARK: Helpers

    static func c(_ hex: UInt32, _ opacity: Double = 1) -> Color { Color(hex: hex).opacity(opacity) }

    static func fill(_ ctx: inout GraphicsContext, _ d: String, _ hex: UInt32, _ opacity: Double = 1) {
        ctx.fill(SVGPath.path(d), with: .color(c(hex, opacity)))
    }

    static func fill(_ ctx: inout GraphicsContext, _ path: Path, _ hex: UInt32, _ opacity: Double = 1) {
        ctx.fill(path, with: .color(c(hex, opacity)))
    }

    static func stroke(_ ctx: inout GraphicsContext, _ d: String, _ hex: UInt32, _ width: CGFloat, dash: [CGFloat] = [], phase: CGFloat = 0, opacity: Double = 1) {
        ctx.stroke(SVGPath.path(d), with: .color(c(hex, opacity)),
                   style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round, dash: dash, dashPhase: phase))
    }

    static func circle(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
    }

    static func glow(_ ctx: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat) {
        ctx.fill(circle(x, y, r), with: .radialGradient(Gradient(colors: [c(0xFFF4C2, 0.9), c(0xFFF4C2, 0)]),
                                                        center: CGPoint(x: x, y: y), startRadius: 0, endRadius: r))
    }

    /// A four-point star centred at (x, y), the canvas's sparkle mark.
    static func star(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) -> String {
        let k = r * 0.25
        return "M\(x) \(y - r) L\(x + k) \(y - k) L\(x + r) \(y) L\(x + k) \(y + k) L\(x) \(y + r) L\(x - k) \(y + k) L\(x - r) \(y) L\(x - k) \(y - k) Z"
    }

    static func track(_ values: [Double], _ times: [Double]? = nil, _ duration: Double, t: Double, on: Bool) -> Double {
        ArtTrack(scalars: values, times: times, duration: duration).scalar(at: t, animate: on)
    }

    /// 0…1 through a loop of `duration` seconds (0 when still).
    static func phase(_ t: Double, _ duration: Double, offset: Double = 0, on: Bool) -> Double {
        guard on else { return 0 }
        let x = (t + offset) / duration
        return x - x.rounded(.down)
    }

    static func wave(_ y: CGFloat, from: CGFloat, step: CGFloat, count: Int, depth: CGFloat, bottom: CGFloat) -> String {
        var d = "M\(from) \(y) Q\(from + step / 2) \(y - depth) \(from + step) \(y)"
        for i in 2...count { d += " T\(from + step * CGFloat(i)) \(y)" }
        return d + " V\(bottom) H\(from) Z"
    }

    // MARK: Layers

    static func drawLayer(_ ctx: inout GraphicsContext, _ layer: Layer, spec: Spec, t: Double, on: Bool) {
        switch layer {
        case .rings:
            fill(&ctx, circle(100, 150, 150), 0xFFFFFF, 0.08)
            fill(&ctx, circle(100, 150, 110), 0xFFFFFF, 0.10)
            fill(&ctx, circle(100, 150, 72), 0xFFFFFF, 0.12)
        case .pulse:
            for begin in [0.0, 2.5] {
                let p = on ? phase(t, 5, offset: -begin, on: on) : 0
                let r = 40 + 55 * p
                ctx.stroke(circle(100, 70, r), with: .color(c(0xFFFFFF, 0.22 * (1 - p))), lineWidth: 10)
            }
        case .sea:
            var back = ctx
            back.translateBy(x: -60 * phase(t, 6, on: on), y: 0)
            fill(&back, wave(104, from: -10, step: 30, count: 10, depth: 8, bottom: 150), 0x7F9CF5)
            var front = ctx
            front.translateBy(x: -60 + 60 * phase(t, 4.5, on: on), y: 0)
            fill(&front, wave(118, from: -70, step: 30, count: 10, depth: 8, bottom: 150), 0x2A52DB)
        case .hill:
            fill(&ctx, Path(ellipseIn: CGRect(x: 40 - 140, y: 160 - 44, width: 280, height: 88)), spec.hills.0)
            fill(&ctx, Path(ellipseIn: CGRect(x: 190 - 120, y: 168 - 46, width: 240, height: 92)), spec.hills.1)
        case .floor:
            fill(&ctx, "M0 122 Q50 112 100 120 T200 116 V140 H0 Z", spec.hills.0)
        }
    }

    // MARK: Subjects

    static func drawSubject(_ ctx: inout GraphicsContext, _ kind: KitArt.Kind, bottom: UInt32, t: Double, on: Bool) {
        let twinkle = track([1, 0.3, 1], nil, 2.6, t: t, on: on)
        switch kind {
        case .dawn:
            glow(&ctx, 50, 62, 34)
            fill(&ctx, circle(50, track([66, 58, 66], nil, 7, t: t, on: on), 20), sun)
            fill(&ctx, "M14 86 a8 8 0 0 1 12 -8 a10 10 0 0 1 18 2 a7 7 0 0 1 8 6 Z", cream)
            fill(&ctx, star(80, 24, 8), cream, twinkle)

        case .sea:
            glow(&ctx, 74, 28, 20)
            fill(&ctx, circle(74, 28, 12), sun)
            fill(&ctx, star(22, 27, 7), cream, twinkle)
            var crest = ctx
            crest.translateBy(x: 0, y: track([0, -3, 0], nil, 3, t: t, on: on))
            fill(&crest, "M28 76 C34 62 50 58 58 64 C50 64 44 70 42 80 Z", cream)
            fill(&crest, circle(62, 62, 2.5), cream)
            fill(&crest, circle(68, 58, 2), cream)

        case .sprout:
            glow(&ctx, 74, 28, 20)
            fill(&ctx, circle(74, 28, 12), sun)
            var plant = ctx
            plant.translateBy(x: 46, y: 92)
            plant.rotate(by: .degrees(track([-3, 3, -3], nil, 5, t: t, on: on)))
            stroke(&plant, "M0 0 L0 -56", 0x0F6E43, 5)
            fill(&plant, "M0 -30 C-6 -44 -26 -48 -32 -40 C-24 -30 -10 -28 0 -30 Z", 0x9FE3BC)
            fill(&plant, "M0 -40 C8 -54 30 -56 36 -46 C28 -36 10 -36 0 -40 Z", 0xC6F2D8)
            fill(&plant, circle(0, -60, 7), 0xFF8FB8)

        case .night:
            glow(&ctx, 58, 40, 30)
            fill(&ctx, "M62 18 A24 24 0 1 0 80 52 A19 19 0 1 1 62 18 Z", 0xFFF1C2)
            fill(&ctx, circle(20, 26, 2), cream, track([1, 0.2, 1], nil, 2.4, t: t, on: on))
            fill(&ctx, circle(30, 56, 1.6), cream, track([0.2, 1, 0.2], nil, 3, t: t, on: on))
            fill(&ctx, star(18, 76, 6), sun, track([1, 0.3, 1], nil, 2.8, t: t, on: on))

        case .breath:
            let times = [0, 0.4, 1.0]
            fill(&ctx, circle(50, 50, track([22, 34, 22], times, 10, t: t, on: on)), 0xFFFFFF, 0.18)
            fill(&ctx, circle(50, 50, track([14, 24, 14], times, 10, t: t, on: on)), 0xFFFFFF, 0.35)
            fill(&ctx, circle(50, 50, 9), 0xFFFFFF)
            fill(&ctx, star(82, 24, 7), sun)

        case .peak:
            glow(&ctx, 26, 26, 16)
            fill(&ctx, circle(26, 26, 9), sun)
            fill(&ctx, "M4 96 L36 52 L66 96 Z", 0x6C4FD8)
            fill(&ctx, "M30 96 L66 34 L100 96 Z", 0x8E73F0)
            fill(&ctx, "M66 34 L100 96 L80 96 Z", 0x6C4FD8, 0.6)
            fill(&ctx, "M60 44 L66 34 L72 44 L68 42 L66 46 L63 42 Z", cream)
            stroke(&ctx, "M66 46 C62 60 70 70 60 86", cream, 2.5, dash: [3, 4], phase: CGFloat(14 * (1 - phase(t, 1.6, on: on))))
            stroke(&ctx, "M66 34 L66 16", ink, 2.5)
            flag(&ctx, pole: CGPoint(x: 67, y: 17), d: "M67 17 L80 21 L67 26 Z", hex: 0xFF7A55, t: t, on: on)

        case .sparkle:
            fill(&ctx, circle(46, 54, 34), 0xFFF1C2, 0.55)
            var big = ctx
            let k = track([0.9, 1.05, 0.9], nil, 3, t: t, on: on)
            big.translateBy(x: 46, y: 54)
            big.scaleBy(x: k, y: k)
            fill(&big, "M0 -28 C3 -8 8 -3 28 0 C8 3 3 8 0 28 C-3 8 -8 3 -28 0 C-8 -3 -3 -8 0 -28 Z", cream)
            fill(&ctx, "M82 22 C83 28 85 30 91 31 C85 32 83 34 82 40 C81 34 79 32 73 31 C79 30 81 28 82 22 Z", 0xFF7A55, track([1, 0.4, 1], nil, 2.2, t: t, on: on))
            fill(&ctx, "M18 80 C19 84 20 85 24 86 C20 87 19 88 18 92 C17 88 16 87 12 86 C16 85 17 84 18 80 Z", 0xFF8FB8)

        case .clouds:
            glow(&ctx, 30, 28, 16)
            fill(&ctx, circle(30, 28, 9), sun)
            var drift = ctx
            drift.translateBy(x: track([-3, 3, -3], nil, 8, t: t, on: on), y: 0)
            fill(&drift, "M14 84 C12 72 26 66 34 72 C38 58 60 58 64 72 C74 66 88 72 86 84 Z", 0x9CCBFF)
            fill(&drift, "M40 84 C40 76 50 72 56 77 C60 70 74 70 76 78 C82 76 90 80 88 84 Z", 0x6E94F0)

        case .flower:
            stroke(&ctx, "M50 84 C40 90 30 96 22 100", 0x3E9E6A, 5)
            fill(&ctx, "M34 92 C24 80 10 82 8 90 C16 98 28 98 34 92 Z", 0x3E9E6A)
            var head = ctx
            head.translateBy(x: 54, y: 48)
            var petals = head
            petals.rotate(by: .degrees(360 * phase(t, 40, on: on)))
            for (x, y) in [(0.0, -22.0), (21, -7), (13, 18), (-13, 18), (-21, -7)] {
                fill(&petals, circle(x, y, 14), cream)
            }
            fill(&head, circle(0, 0, 12), 0xFFC94A)
            fill(&head, circle(-3, -3, 4), 0xFFE59A)

        case .cup:
            for begin in [0.0, 1.3] {
                let p = phase(t, 2.6, offset: -begin, on: on)
                var steam = ctx
                steam.translateBy(x: 0, y: on ? 6 - 9 * p : 0)
                let opacity = on ? (p < 0.5 ? p * 2 : (1 - p) * 2) : 0.7
                stroke(&steam, begin == 0 ? "M36 34 C34 24 42 20 40 12" : "M52 34 C50 24 58 20 56 12", cream, 3, opacity: opacity)
            }
            stroke(&ctx, "M70 50 C84 50 84 72 68 72", cream, 5)
            fill(&ctx, "M22 42 L72 42 L68 80 Q66 88 58 88 L36 88 Q28 88 26 80 Z", cream)
            stroke(&ctx, "M24 52 L71 52", 0xFF7A55, 6)
            fill(&ctx, Path(ellipseIn: CGRect(x: 15, y: 88, width: 64, height: 8)), ink, 0.15)

        case .eye:
            eye(&ctx, iris: 0x4A3596)
            let lid = track([0, 0, 1, 0, 0], [0, 0.9, 0.95, 0.98, 1], 4.5, t: t, on: on)
            if lid > 0.01 {
                var l = ctx
                l.translateBy(x: 50, y: 50)
                l.scaleBy(x: 1, y: lid)
                fill(&l, "M-41 0 C-25 -27 25 -27 41 0 C25 27 -25 27 -41 0 Z", bottom)
            }

        case .glass:
            let shape = "M30 18 L70 18 L65 84 Q64 88 60 88 L40 88 Q36 88 35 84 Z"
            stroke(&ctx, "M60 6 L54 50", 0xFF7A55, 5)
            fill(&ctx, shape, cream, 0.92)
            var inside = ctx
            inside.clip(to: SVGPath.path(shape))
            var water = inside
            water.translateBy(x: -30 * phase(t, 2.6, on: on), y: 0)
            fill(&water, wave(50, from: 10, step: 15, count: 7, depth: 5, bottom: 95), 0x2A52DB)
            let p = phase(t, 2.2, on: on)
            fill(&inside, circle(46, on ? 82 - 26 * p : 76, 2.5), cream, on ? 1 - p : 1)

        case .heart:
            fill(&ctx, circle(50, 52, 34), 0xFFFFFF, 0.18)
            var h = ctx
            let k = track([1, 1.1, 1, 1.05, 1, 1], [0, 0.12, 0.24, 0.36, 0.5, 1], 1.6, t: t, on: on)
            h.translateBy(x: 50, y: 54)
            h.scaleBy(x: k, y: k)
            fill(&h, "M0 26 C-28 8 -32 -12 -20 -22 C-10 -30 -2 -24 0 -16 C2 -24 10 -30 20 -22 C32 -12 28 8 0 26 Z", cream)
            stroke(&h, "M-16 -12 C-14 -16 -10 -18 -6 -17", 0xFF7A55, 3)

        case .box:
            ctx.stroke(Path(roundedRect: CGRect(x: 22, y: 22, width: 56, height: 56), cornerRadius: 6), with: .color(c(ink)), lineWidth: 4)
            // In, hold, out, hold: one side every 4 seconds, starting bottom-left and going up.
            let p = phase(t, 16, on: on) * 4
            let side = Int(p), f = CGFloat(p - Double(side))
            let point: CGPoint = switch side {
            case 0: CGPoint(x: 22, y: 78 - 56 * f)
            case 1: CGPoint(x: 22 + 56 * f, y: 22)
            case 2: CGPoint(x: 78, y: 22 + 56 * f)
            default: CGPoint(x: 78 - 56 * f, y: 78)
            }
            fill(&ctx, circle(point.x, point.y, 7), 0xFF7A55)

        case .outbreath:
            // In 4, hold 7, out 8.
            let times = [0, 0.21, 0.58, 1.0]
            fill(&ctx, circle(50, 50, track([14, 30, 30, 14], times, 19, t: t, on: on)), cream)
            let wind = on ? track([0, 0, 0, 1, 0], [0, 0.21, 0.58, 0.75, 1], 19, t: t, on: on) : 1
            stroke(&ctx, "M66 40 C74 40 78 36 84 36", 0x0F6E43, 3.5, opacity: wind)
            stroke(&ctx, "M68 52 C76 52 80 56 88 56", 0x0F6E43, 3.5, opacity: wind)

        case .grounding:
            fill(&ctx, "M14 42 C28 22 72 22 86 42 C72 62 28 62 14 42 Z", cream)
            fill(&ctx, circle(50, 42, 11), 0x0F6E43)
            fill(&ctx, circle(50, 42, 4.5), ink)
            // Five senses, lit one by one.
            let lit = on ? Int(phase(t, 6, on: on) * 6) : 5
            for i in 0..<5 {
                fill(&ctx, circle(22 + CGFloat(i) * 14, 80, 5), cream, i < lit ? 1 : 0.25)
            }

        case .tag:
            var float = ctx
            float.translateBy(x: 0, y: track([8, -6, 8], nil, 6, t: t, on: on))
            fill(&float, "M22 50 C14 50 12 36 22 34 C22 22 40 18 46 28 C54 18 74 22 72 36 C84 36 84 52 72 52 L30 52 Z", cream)
            fill(&float, circle(26, 62, 4), cream)
            fill(&float, circle(18, 72, 2.5), cream)
            var label = float
            label.translateBy(x: 58, y: 46)
            label.rotate(by: .degrees(18))
            fill(&label, "M0 0 L22 0 L28 7 L22 14 L0 14 Z", 0xFFD966)
            fill(&label, circle(21, 7, 2), ink)

        case .anchor:
            var a = ctx
            a.translateBy(x: 50, y: 20)
            a.rotate(by: .degrees(track([-6, 6, -6], nil, 5, t: t, on: on)))
            a.stroke(circle(0, 6, 6), with: .color(c(ink)), lineWidth: 5)
            stroke(&a, "M0 12 L0 64", ink, 5)
            stroke(&a, "M-14 26 L14 26", ink, 5)
            stroke(&a, "M-24 50 C-22 62 -12 66 0 66 C12 66 22 62 24 50", ink, 5)

        case .berry:
            var b = ctx
            b.translateBy(x: 50, y: 56)
            b.rotate(by: .degrees(track([-5, 5, -5], nil, 4, t: t, on: on)))
            fill(&b, "M0 30 C-26 18 -30 -6 -18 -16 C-10 -22 -4 -20 0 -18 C4 -20 10 -22 18 -16 C30 -6 26 18 0 30 Z", 0xFF5A5F)
            for (x, y) in [(-10.0, -4.0), (6, -6), (-4, 8), (12, 6), (2, 18)] { fill(&b, circle(x, y, 2), 0xFFE59A) }
            fill(&b, "M-14 -20 C-8 -30 -2 -28 0 -20 C2 -28 8 -30 14 -20 C6 -16 -6 -16 -14 -20 Z", 0x3E9E6A)
            fill(&ctx, star(80, 24, 7), cream, track([1, 0.3, 1], nil, 2.4, t: t, on: on))

        case .lungs:
            stroke(&ctx, "M50 18 L50 46", cream, 5)
            var l = ctx
            let k = track([0.92, 1.06, 0.92], [0, 0.4, 1], 5, t: t, on: on)
            l.translateBy(x: 50, y: 58)
            l.scaleBy(x: k, y: k)
            fill(&l, "M-5 -14 C-14 -22 -32 -16 -36 6 C-40 28 -30 36 -16 32 C-8 30 -5 22 -5 12 Z", cream)
            fill(&l, "M5 -14 C14 -22 32 -16 36 6 C40 28 30 36 16 32 C8 30 5 22 5 12 Z", cream)

        case .lips:
            var l = ctx
            let k = track([1, 1.06, 1], nil, 3, t: t, on: on)
            l.translateBy(x: 50, y: 52)
            l.scaleBy(x: k, y: k)
            fill(&l, "M-34 0 C-24 -16 -10 -18 0 -10 C10 -18 24 -16 34 0 C22 -2 10 -2 0 2 C-10 -2 -22 -2 -34 0 Z", 0xFF5A5F)
            fill(&l, "M-34 0 C-22 -2 -10 -2 0 2 C10 -2 22 -2 34 0 C26 18 -26 18 -34 0 Z", 0xFF7A80)
            stroke(&l, "M-14 8 C-8 10 -2 10 2 10", cream, 3)

        case .shield:
            fill(&ctx, "M50 12 L80 24 L80 50 C80 70 66 84 50 90 C34 84 20 70 20 50 L20 24 Z", cream)
            var h = ctx
            let k = track([1, 1.1, 1, 1, 1], [0, 0.15, 0.3, 0.6, 1], 2, t: t, on: on)
            h.translateBy(x: 50, y: 52)
            h.scaleBy(x: k, y: k)
            fill(&h, "M0 16 C-16 6 -18 -6 -11 -12 C-6 -16 -1 -13 0 -9 C1 -13 6 -16 11 -12 C18 -6 16 6 0 16 Z", 0x2F7A52)
        }
    }

    static func eye(_ ctx: inout GraphicsContext, iris: UInt32) {
        fill(&ctx, "M10 50 C26 24 74 24 90 50 C74 76 26 76 10 50 Z", cream)
        fill(&ctx, circle(50, 50, 15), iris)
        fill(&ctx, circle(50, 50, 6), ink)
        fill(&ctx, circle(55, 45, 3), cream)
    }

    /// A pennant that waves on its pole: skew around the pole's x.
    static func flag(_ ctx: inout GraphicsContext, pole: CGPoint, d: String, hex: UInt32, t: Double, on: Bool) {
        let angle = track([0, -5, 0, 4, 0], nil, 2.4, t: t, on: on) * .pi / 180
        var f = ctx
        f.concatenate(CGAffineTransform(a: 1, b: CGFloat(tan(angle)), c: 0, d: 1, tx: 0, ty: -pole.x * CGFloat(tan(angle))))
        fill(&f, d, hex)
    }
}
