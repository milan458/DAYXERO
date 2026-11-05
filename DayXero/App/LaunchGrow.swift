import DayXeroCore
import SwiftUI

/// The opening animation (brand canvas, "Opening animation"). The forest wordmark grows from the bottom up:
/// grass, trunk, leaves from where the trunk splits outward, highlights, then "Day" and "ero" slide out from
/// behind the tree. It holds for a second and fades into the app. It always plays to the end; there's no skip.
/// The static launch screen is the same paper colour, so nothing jumps between the two.
struct LaunchGrowOverlay: View {
    let onFinished: @MainActor () -> Void
    private let motion = MotionPolicy()
    @State private var start: Date?

    var body: some View {
        let timing = motion.reduce ? LaunchGrowTiming.reduced : .full
        TimelineView(.animation) { context in
            let t = start.map { context.date.timeIntervalSince($0) } ?? 0
            let fade = timing.fade(at: t)
            ZStack {
                ForestGrowColors.paper.ignoresSafeArea()
                ForestWordmark(size: 68, time: motion.reduce ? 10 : t)
                    .opacity(motion.reduce ? Ease.progress(t, from: 0, to: 0.3) : 1)
            }
            .opacity(1 - fade)
            .scaleEffect(1 + 0.04 * fade)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "DayXero"))
        .onAppear { if start == nil { start = .now } }
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
        return !ProcessInfo.processInfo.arguments.contains { $0.hasPrefix("-dx.") }
        #else
        return true
        #endif
    }
}

/// Grow 1.6 s, hold 1 s, fade 0.4 s. With Reduce Motion the whole wordmark fades in over 0.3 s instead.
struct LaunchGrowTiming {
    let fadeStart: Double
    let end: Double

    static let full = LaunchGrowTiming(fadeStart: 2.6, end: 3.0)
    static let reduced = LaunchGrowTiming(fadeStart: 1.3, end: 1.7)

    func fade(at t: Double) -> Double { Ease.progress(t, from: fadeStart, to: end) }
}

enum ForestGrowColors {
    static let paper = Color(hex: 0xF6F0E6)
    static let ink = Color(hex: 0x1E1A3A)
    static let dark = Color(hex: 0x2F5E46)
    static let mid = Color(hex: 0x4F8A5E)
    static let light = Color(hex: 0x9CCB8E)
    static let trunk = Color(hex: 0x7A4E36)
}

/// "Day", the leafy X tree, "ero", drawn at `time` seconds into the grow. Any time past 1.6 s is the finished mark.
struct ForestWordmark: View {
    let size: CGFloat
    let time: Double

    var body: some View {
        let words = Ease.progress(time, from: 1.12, to: 1.58)
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            word("Day")
                .offset(x: 0.32 * size * (1 - words))
                .opacity(words)
            ForestTree(time: time)
                .frame(width: (size * 0.67).rounded(), height: (size * 0.98).rounded())
                .alignmentGuide(.firstTextBaseline) { $0.height - 0.26 * size }
                .padding(.leading, 0.03 * size)
                .padding(.trailing, 0.01 * size)
            word("ero")
                .offset(x: -0.32 * size * (1 - words))
                .opacity(words)
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private func word(_ text: String) -> some View {
        Text(verbatim: text)
            .font(DX.Typeface4.swiftUIFont(.display, size: size, weight: 800))
            .tracking(-0.03 * size)
            .foregroundStyle(ForestGrowColors.ink)
            .fixedSize()
    }
}

/// The leafy X: ground, trunk, two diagonal rows of dark leaves, a lighter layer, highlights.
/// Coordinates are the brand canvas's 100 × 146 view box.
struct ForestTree: View {
    let time: Double

    var body: some View {
        // Leaves overshoot their circles while they pop, so draw with a little room around the frame.
        let pad: CGFloat = 6
        Canvas { context, size in
            let k = (size.width - 2 * pad) / 100
            context.translateBy(x: pad, y: pad)
            context.scaleBy(x: k, y: k)

            let ground = Ease.progress(time, from: 0.15, to: 0.42)
            if ground > 0 {
                let rx = 24 * ground
                context.opacity = ground
                context.fill(Path(ellipseIn: CGRect(x: 50 - rx, y: 133, width: 2 * rx, height: 12)), with: .color(ForestGrowColors.mid))
                context.opacity = 1
            }

            let trunk = Ease.progress(time, from: 0.28, to: 0.72)
            if trunk > 0 {
                var c = context
                c.translateBy(x: 0, y: 138)
                c.scaleBy(x: 1, y: trunk)
                c.translateBy(x: 0, y: -138)
                c.fill(Self.trunk, with: .color(ForestGrowColors.trunk))
            }

            for leaf in ForestLeaf.all {
                let scale = leaf.scale(at: time)
                guard scale > 0 else { continue }
                let r = leaf.r * scale
                context.fill(Path(ellipseIn: CGRect(x: leaf.x - r, y: leaf.y - r, width: 2 * r, height: 2 * r)),
                             with: .color(leaf.layer.color))
            }
        }
        .padding(-pad)
        .accessibilityHidden(true)
    }

    private static let trunk: Path = {
        var p = Path()
        p.move(to: CGPoint(x: 46, y: 58))
        p.addCurve(to: CGPoint(x: 41, y: 138), control1: CGPoint(x: 47, y: 92), control2: CGPoint(x: 45, y: 118))
        p.addLine(to: CGPoint(x: 59, y: 138))
        p.addCurve(to: CGPoint(x: 54, y: 58), control1: CGPoint(x: 55, y: 118), control2: CGPoint(x: 53, y: 92))
        p.closeSubpath()
        return p
    }()
}

struct ForestLeaf {
    enum Layer {
        case dark, mid, light
        var color: Color {
            switch self {
            case .dark: ForestGrowColors.dark
            case .mid: ForestGrowColors.mid
            case .light: ForestGrowColors.light
            }
        }
    }

    let layer: Layer
    let x: CGFloat
    let y: CGFloat
    let r: CGFloat
    let start: Double
    let duration: Double
    let overshoot: CGFloat

    /// 0 before the leaf pops, up past 1 at 60 % of its pop, then settles at 1.
    func scale(at t: Double) -> CGFloat {
        let split = start + duration * 0.6
        if t <= start { return 0 }
        if t < split { return overshoot * Ease.progress(t, from: start, to: split) }
        return overshoot + (1 - overshoot) * Ease.progress(t, from: split, to: start + duration)
    }

    private static let dark: [(CGFloat, CGFloat, CGFloat)] = [
        (14, 13.5, 12.5), (23, 23.8, 11), (32, 34, 11), (41, 44.2, 11), (50, 54.5, 13), (59, 64.8, 11), (68, 75, 11),
        (77, 85.2, 11), (86, 95.5, 12.5), (86, 13.5, 12.5), (77, 23.8, 11), (68, 34, 11), (59, 44.2, 11),
        (41, 64.8, 11), (32, 75, 11), (23, 85.2, 11), (14, 95.5, 12.5),
    ]
    private static let mid: [(CGFloat, CGFloat, CGFloat)] = [
        (12.5, 10.5, 9), (21.5, 20.8, 7.9), (30.5, 31, 7.9), (39.5, 41.2, 7.9), (48.5, 51.5, 9.4), (57.5, 61.8, 7.9),
        (66.5, 72, 7.9), (75.5, 82.2, 7.9), (84.5, 92.5, 9), (84.5, 10.5, 9), (75.5, 20.8, 7.9), (66.5, 31, 7.9),
        (57.5, 41.2, 7.9), (39.5, 61.8, 7.9), (30.5, 72, 7.9), (21.5, 82.2, 7.9), (12.5, 92.5, 9),
    ]
    private static let light: [(CGFloat, CGFloat, CGFloat)] = [
        (10.5, 7.5, 2.6), (28.5, 28, 2.6), (46.5, 48.5, 2.6), (64.5, 69, 2.6), (82.5, 89.5, 2.6), (82.5, 7.5, 2.6),
        (64.5, 28, 2.6), (28.5, 69, 2.6), (10.5, 89.5, 2.6),
    ]

    /// Nearest the split in the trunk (50, 56) pops first. Dark leaves, then the lighter layer, then highlights.
    static let all: [ForestLeaf] = {
        func distance(_ x: CGFloat, _ y: CGFloat) -> Double { Double(hypot(x - 50, y - 56)) }
        let far = dark.map { distance($0.0, $0.1) }.max() ?? 1
        func make(_ list: [(CGFloat, CGFloat, CGFloat)], _ layer: Layer, base: Double, spread: Double,
                  duration: Double, overshoot: CGFloat) -> [ForestLeaf] {
            list.map { x, y, r in
                ForestLeaf(layer: layer, x: x, y: y, r: r, start: base + spread * distance(x, y) / far,
                           duration: duration, overshoot: overshoot)
            }
        }
        return make(dark, .dark, base: 0.62, spread: 0.5, duration: 0.3, overshoot: 1.18)
            + make(mid, .mid, base: 0.72, spread: 0.5, duration: 0.28, overshoot: 1.12)
            + make(light, .light, base: 1.08, spread: 0.3, duration: 0.2, overshoot: 1.4)
    }()
}

/// The canvas's cubic-bezier(.3, .7, .4, 1), applied between two times.
enum Ease {
    private static let curve = UnitCurve.bezier(startControlPoint: UnitPoint(x: 0.3, y: 0.7),
                                                endControlPoint: UnitPoint(x: 0.4, y: 1))

    static func progress(_ t: Double, from a: Double, to b: Double) -> Double {
        guard t > a else { return 0 }
        guard t < b else { return 1 }
        return curve.value(at: (t - a) / (b - a))
    }
}
