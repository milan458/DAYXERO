import DayXeroCore
import SwiftUI

/// Notice the urge (v5, 059): one painted scene, the urge as a long low swell on the sea, and Jelli riding it up to the
/// crest and down onto calm water. The one prompt above the scene walks through it.
///
/// Motion (059): the sky and the layered sea fade in (600 ms); the urge line draws edge to edge over 2.4 s as the swell
/// fills in under it, then the three points and their labels fade in. Jelli, seated on the line, rides it for 12 s
/// (slow ease) up to the crest and down, settling where the swell ends; the It peaks tag fades out (700 ms) as she
/// nears the crest and back in once she has passed. The prompt cross-fades every 3 s (600 ms). No springs, and no
/// haptic until It's passing is tapped.
struct CalmUrgeView: View {
    /// Starts at the end of the ride (debug stills).
    var still = false
    let onClose: () -> Void
    let onPassing: () -> Void
    let onMoreHelp: () -> Void

    private let ground = DX.Ground.reading
    private let motion = MotionPolicy()
    @State private var start = Date.now

    static let prompts: [(at: Double, text: LocalizedStringKey)] = [
        (0, "Notice where you feel it."),
        (3, "It rises. You do not have to act."),
        (6, "This is the peak. Breathe out slowly."),
        (9, "Watch it fall away."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                DXIconButton(.close, label: "Close", action: onClose)
                Text("Notice the urge").dxType(.headline).foregroundStyle(ground.ink)
                    .frame(maxWidth: .infinity)
                    .dxArrive(0)
                Color.clear.frame(width: 44, height: 1)
            }
            .frame(height: 52)
            .padding(.horizontal, -6)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

            TimelineView(.animation(minimumInterval: 1.0 / 60, paused: still || motion.reduce)) { timeline in
                let e = still || motion.reduce ? 20 : timeline.date.timeIntervalSince(start)
                VStack(spacing: 0) {
                    prompt(e)
                        .padding(.top, 34)
                        .dxArrive(2)
                    UrgeScene(elapsed: e)
                        .padding(.top, 18)
                        .dxArrive(3)
                    Spacer(minLength: 16)
                }
            }

            VStack(spacing: 4) {
                Button("It's passing", action: onPassing)
                    .buttonStyle(.dx(.primary, on: ground))
                    .dxArrive(4)
                Button("I need more help", action: onMoreHelp)
                    .buttonStyle(.dx(.quiet, on: ground))
                    .dxArrive(5)
            }
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
        // The scene starts drawing when it comes on screen.
        .onAppear { start = .now }
    }

    /// The single prompt: each line fades out and up (600 ms), then the next fades in.
    private func prompt(_ e: Double) -> some View {
        let index = Self.prompts.lastIndex { e >= $0.at } ?? 0
        let at = Self.prompts[index].at
        let shown: Int
        let fade: Double
        if index > 0, e < at + 0.6 {
            shown = index - 1
            fade = 1 - (e - at) / 0.6
        } else if index > 0, e < at + 1.2 {
            shown = index
            fade = (e - at - 0.6) / 0.6
        } else {
            shown = index
            fade = 1
        }
        let out = shown < index
        return Text(Self.prompts[shown].text)
            .dxFace(.display, 28, weight: 800, tracking: -0.6)
            .foregroundStyle(ground.ink)
            .multilineTextAlignment(.center)
            .lineSpacing(2)
            .opacity(fade)
            .offset(y: out ? -8 * (1 - fade) : -8 * (1 - fade))
            .frame(maxWidth: .infinity, minHeight: 72)
            .padding(.horizontal, 6)
            .accessibilityAddTraits(.updatesFrequently)
    }
}

/// The scene card, on the mockup's 346 × 410 stage scaled to the column's width.
private struct UrgeScene: View {
    let elapsed: Double
    @Environment(\.colorScheme) private var scheme

    static let stage = CGSize(width: 346, height: 410)
    /// The ride, the swell's rise, crest and fall (kit `R`).
    static let ride = "M-6 300 C 54 300 100 200 164 200 C 226 200 256 300 300 300"
    /// The urge line, the ride running on to the right edge over calm water (kit `U`).
    static let line = ride + " C 320 300 336 301 352 301"
    static let points: [CGPoint] = [CGPoint(x: 108, y: 223.4), CGPoint(x: 164, y: 200), CGPoint(x: 226, y: 235.2)]

    var body: some View {
        GeometryReader { geo in
            let s = geo.size.width / Self.stage.width
            ZStack(alignment: .topLeading) {
                scene
                labels
                rider
            }
            .frame(width: Self.stage.width, height: Self.stage.height, alignment: .topLeading)
            .scaleEffect(s, anchor: .topLeading)
        }
        .aspectRatio(Self.stage.width / Self.stage.height, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .accessibilityElement()
        .accessibilityLabel(Text("The urge as a wave: it rises, it peaks, it passes."))
    }

    private func ramp(_ delay: Double, _ duration: Double = 0.7) -> Double {
        min(max((elapsed - delay) / duration, 0), 1)
    }

    private var palette: (sky: (UInt32, UInt32), swell: (UInt32, UInt32), sea: [(UInt32, UInt32)], crest: UInt32, line: UInt32, ring: UInt32) {
        scheme == .dark
            ? ((0x0E1E46, 0x1E3A72), (0x2A4C92, 0x203E7C), [(0x2A4C92, 0x203E7C), (0x1D3870, 0x16305F), (0x132A58, 0x0E2149)], 0xA8C2FF, 0xFFF8EE, 0x26457F)
            : ((0xBFDDFF, 0xEAF4FF), (0x4F93FA, 0x3F84F2), [(0x4F93FA, 0x3F84F2), (0x2F72F2, 0x2766E0), (0x1F55D0, 0x1A4BC0)], 0xFFFFFF, 0x1E1A3A, 0xFFF8EE)
    }

    private var scene: some View {
        let c = palette
        let dark = scheme == .dark
        let drawn = Self.ease(ramp(0.3, 2.4))
        return ZStack(alignment: .topLeading) {
            Canvas { ctx, _ in
                ctx.fill(Path(CGRect(origin: .zero, size: Self.stage)),
                         with: .linearGradient(CalmPaint.vertical(c.sky.0, c.sky.1), startPoint: .zero, endPoint: CGPoint(x: 0, y: 410)))
                if dark {
                    CalmPaint.stars(&ctx, [(40, 40, 1.7), (92, 76, 1.2), (290, 52, 1.7), (318, 120, 1.2), (24, 150, 1.7), (226, 30, 1.2)], opacity: 0.8)
                } else {
                    var a = ctx
                    a.opacity = 0.9
                    a.fill(CalmPaint.ellipse(282, 56, 30, 10), with: .color(.white))
                    a.fill(CalmPaint.ellipse(268, 49, 15, 11), with: .color(.white))
                    var b = ctx
                    b.opacity = 0.7
                    b.addFilter(.blur(radius: 1.6))
                    b.fill(CalmPaint.ellipse(62, 112, 28, 8), with: .color(.white))
                    b.fill(CalmPaint.ellipse(74, 105, 14, 9), with: .color(.white))
                    b.fill(CalmPaint.ellipse(52, 108, 10, 7), with: .color(.white))
                }
            }
            // The swell fills in under the line.
            Canvas { ctx, _ in
                ctx.fill(SVGPath.path(Self.line + " V410 H-10Z"),
                         with: .linearGradient(Gradient(stops: [.init(color: Color(hex: c.swell.0), location: 0.25),
                                                                .init(color: Color(hex: c.swell.1), location: 1)]),
                                               startPoint: CGPoint(x: 0, y: 200), endPoint: CGPoint(x: 0, y: 410)))
            }
            .opacity(ramp(0.9))
            SVGShape(d: Self.line)
                .trim(from: 0, to: drawn)
                .stroke(Color(hex: c.line), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            Canvas { ctx, _ in
                for p in Self.points {
                    let dot = CalmPaint.circle(p.x, p.y, 6.5)
                    ctx.fill(dot, with: .color(Color(hex: c.line)))
                    ctx.stroke(dot, with: .color(Color(hex: c.ring)), lineWidth: 3)
                }
            }
            .opacity(ramp(1.3))
            // The layered sea in front.
            Canvas { ctx, _ in
                let bands = [
                    "M-10 322 C 50 308 110 312 170 322 C 240 334 300 314 356 310",
                    "M-10 352 C 60 340 120 342 190 354 C 260 366 310 346 356 342",
                    "M-10 382 C 70 370 140 374 210 384 C 280 394 330 378 356 374",
                ]
                for (i, d) in bands.enumerated() {
                    ctx.fill(SVGPath.path(d + " V410 H-10Z"),
                             with: .linearGradient(CalmPaint.vertical(c.sea[i].0, c.sea[i].1), startPoint: CGPoint(x: 0, y: 300 + 30 * Double(i)),
                                                   endPoint: CGPoint(x: 0, y: 410)))
                    ctx.stroke(SVGPath.path(d), with: .color(Color(hex: c.crest).opacity(dark ? 0.16 : 0.28)), lineWidth: 2)
                }
            }
            .opacity(ramp(0.6))
        }
        .frame(width: Self.stage.width, height: Self.stage.height)
    }

    private var labels: some View {
        let ride = min(max(elapsed / 12, 0), 1)
        // It peaks steps aside while Jelli crosses the crest, then comes back.
        let peak: Double = switch ride {
        case ..<0.30: 1
        case ..<0.36: 1 - (ride - 0.30) / 0.06
        case ..<0.66: 0
        case ..<0.72: (ride - 0.66) / 0.06
        default: 1
        }
        return ZStack(alignment: .topLeading) {
            Color.clear
            // Each tag is pinned by one edge: It rises ends 12 px left of its dot, It peaks sits 18 px above the crest,
            // It passes starts 12 px right of its dot.
            UrgeTag(text: "It rises").fixedSize()
                .frame(width: 0, height: 0, alignment: .trailing)
                .position(x: 96, y: 211)
            UrgeTag(text: "It peaks").fixedSize()
                .frame(width: 0, height: 0, alignment: .bottom)
                .position(x: 164, y: 182)
                .opacity(peak)
            UrgeTag(text: "It passes").fixedSize()
                .frame(width: 0, height: 0, alignment: .leading)
                .position(x: 238, y: 223)
        }
        .frame(width: Self.stage.width, height: Self.stage.height, alignment: .topLeading)
        .opacity(ramp(1.3))
        .accessibilityHidden(true)
    }

    /// Jelli on the line (its tentacle tips on it), riding from x 44 to x 300 over 12 s.
    private var rider: some View {
        let p = Self.track.point(Self.ease2(min(max(elapsed / 12, 0), 1)))
        return JelliView(mood: .calm, stage: 1, points: 80)
            .frame(width: 80, height: 80)
            .position(x: p.x, y: p.y - 80 * 0.43)
            .frame(width: Self.stage.width, height: Self.stage.height)
            .opacity(ramp(1.2))
            .accessibilityHidden(true)
    }

    static func ease(_ x: Double) -> Double { 1 - pow(1 - x, 3) }
    /// The ride's slow ease (cubic-bezier(.4, 0, .6, 1), close enough).
    static func ease2(_ x: Double) -> Double { x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2 }

    /// The ride, sampled once: lengths along it, from x 44 to x 300.
    static let track = RideTrack(SVGPath.path(ride), from: 44, to: 300)
}

/// A path sampled into points, for placing something a given way along it between two x positions.
struct RideTrack: Sendable {
    let points: [CGPoint]
    let lengths: [CGFloat]
    let start: CGFloat
    let end: CGFloat

    init(_ path: Path, from x0: CGFloat, to x1: CGFloat) {
        var pts: [CGPoint] = []
        let n = 400
        for i in 0...n {
            if let p = path.trimmedPath(from: 0, to: max(CGFloat(i) / CGFloat(n), 0.0001)).currentPoint { pts.append(p) }
        }
        var lens: [CGFloat] = [0]
        for i in 1..<pts.count { lens.append(lens[i - 1] + hypot(pts[i].x - pts[i - 1].x, pts[i].y - pts[i - 1].y)) }
        points = pts
        lengths = lens
        start = lens[pts.firstIndex { $0.x >= x0 } ?? 0]
        end = lens[pts.firstIndex { $0.x >= x1 } ?? (pts.count - 1)]
    }

    func point(_ f: Double) -> CGPoint {
        let target = start + (end - start) * f
        guard let i = lengths.firstIndex(where: { $0 >= target }), i > 0 else { return points.first ?? .zero }
        let t = (target - lengths[i - 1]) / max(lengths[i] - lengths[i - 1], 0.0001)
        return CGPoint(x: points[i - 1].x + (points[i].x - points[i - 1].x) * t, y: points[i - 1].y + (points[i].y - points[i - 1].y) * t)
    }
}

/// A path from SVG path data, as a shape (so it can be trimmed and animated).
struct SVGShape: Shape {
    let d: String
    func path(in rect: CGRect) -> Path { SVGPath.path(d) }
}

/// A cream tag on the scene: It rises, It peaks, It passes.
private struct UrgeTag: View {
    let text: LocalizedStringKey

    var body: some View {
        Text(text)
            .dxFace(.body, 14, weight: 700)
            .foregroundStyle(Color(hex: 0x1E1A3A))
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(hex: 0xFFF8EE), in: Capsule())
            .shadow(color: Color(red: 20 / 255, green: 30 / 255, blue: 70 / 255).opacity(0.12), radius: 4, y: 2)
            .dynamicTypeSize(...DynamicTypeSize.large)
    }
}
