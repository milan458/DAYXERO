import DayXeroCore
import SwiftUI

/// One phase of the program as a road (v5, cook/site/screens/022): one paper-cut ribbon straight down the left from the
/// first session to the phase's last, with a stamp on it per session (done ones stamped, later ones in dashed rings),
/// today's session a dark scalloped seal with a play button and the up-next card beside it, and the last stop a coin
/// rising on the horizon over two sage hills. Titles sit to the right of each stamp.
///
/// Motion (022): the header and its progress line arrive (600ms, 90ms stagger). The road, one continuous paper-cut
/// ribbon from Prep 1 to the Day Xero coin, fades in (600ms), then its finished stretch fills prep-orange from the top
/// to today's stamp (1100ms, ease); Prep 1 to 3 stamps and their rows arrive as the fill reaches each one (about 360ms
/// apart). Today's Prep 4 play stamp lands as the fill arrives (600ms arrive, no spring) with the up-next card beside
/// it, then the stamp breathes a soft pulse ring every 2.4s. Prep 5 to 7 (dashed rings on cream) fade in, the dotted
/// guide fades in along the road to the horizon, the two hills rise 24px into place back to front (100ms apart,
/// 900ms), and the Day Xero coin rises onto the horizon like a sunrise (1100ms settle) while the warm glow behind it
/// brightens (1.2s) and its label fades in. Last, the locked 'Weeks 1 to 4' row arrives on the hill (600ms). Light
/// haptic when the fill reaches today.
struct ProgramPathMap: View {
    struct Stop: Identifiable {
        enum Kind { case done, today, locked, goal }
        let id: String
        let title: String
        /// "Prep 1 · Fri · done", "Today · Prep 4 · 5 cards · 28 min", "Prep 5 · opens Tue".
        let kicker: String
        let kind: Kind
        let minutes: Int
        let needsUpgrade: Bool
        let accessibility: String
    }

    /// The next phase, waiting on the horizon at the road's end (022: the Day Xero coin under the prep week).
    struct Goal {
        let title: String
        let isDayXero: Bool
        /// The date under the title ("Fri, Nov 6").
        var subtitle: String?
    }

    let stops: [Stop]
    let ground: DX.Ground
    var goal: Goal?
    let onTap: (Stop) -> Void
    @State private var filled = false
    @State private var reached = false
    private let motion = MotionPolicy()

    /// The road's column, the gap between stamps (today's gets more room), and the goal's drop onto the horizon.
    private let x: CGFloat = 36
    private let step: CGFloat = 54
    private let todayGap: CGFloat = 64
    static let road = Color(light: 0xCBEBD8, dark: 0x34526B)
    /// 022: neutral text on the plan page (no green).
    static let muted = Color(light: 0x5E5975, dark: 0xB3BACC)
    static let roadEdge = Color(light: (0x24493A, 0.16), dark: (0x000000, 0.5))
    static let roadDone = Color(light: 0xFFAE73, dark: 0xC27A4E)

    /// Road slots: every stop, plus the goal when there is one; without a goal the last stop is the coin.
    private var slots: Int { stops.count + (goal == nil ? 0 : 1) }

    var body: some View {
        let ys = yPositions()
        let last = goal == nil ? stops.count - 1 : stops.count
        let goalY = (ys.last ?? 0)
        let height = goalY + 30
        let todayIndex = stops.firstIndex { $0.kind == .today }
        let doneUpTo = todayIndex ?? (stops.lastIndex { $0.kind == .done } ?? -1)
        GeometryReader { proxy in
            let width = proxy.size.width
            let goalX = min(128, width * 0.36)
            let points = roadPoints(ys: ys, goalX: goalX)
            ZStack(alignment: .topLeading) {
                // The warm glow where Day Xero rises, brightening as the coin comes up.
                if goal != nil {
                    HorizonGlow()
                        .frame(width: width + 2 * DX.Layout.gutter, height: 280)
                        .offset(x: -DX.Layout.gutter, y: goalY - 162)
                        .dxFade(delay: 1.8)
                        .accessibilityHidden(true)
                }
                ProgramHill(layer: .back, top: goalY - 14)
                    .frame(width: width + 2 * DX.Layout.gutter, height: height + 700)
                    .offset(x: -DX.Layout.gutter)
                    .modifier(HillRise(delay: 1.5))
                    .accessibilityHidden(true)
                Group {
                    SplineShape(points: points, from: 0, to: points.count - 1)
                        .stroke(Self.roadEdge, style: StrokeStyle(lineWidth: 56, lineCap: .round, lineJoin: .round))
                        .offset(y: 3)
                    SplineShape(points: points, from: 0, to: points.count - 1)
                        .stroke(Self.road, style: StrokeStyle(lineWidth: 52, lineCap: .round, lineJoin: .round))
                }
                .dxFade(delay: 0.15)
                .accessibilityHidden(true)
                if doneUpTo > 0 {
                    // The finished stretch fills prep-orange from the top to today's stamp (1100 ms).
                    SplineShape(points: points, from: 0, to: doneUpTo)
                        .trim(from: 0, to: filled || motion.reduce ? 1 : 0)
                        .stroke(Self.roadDone, style: StrokeStyle(lineWidth: 52, lineCap: .round, lineJoin: .round))
                        .accessibilityHidden(true)
                }
                SplineShape(points: points, from: max(doneUpTo, 0) + 1, to: points.count - 1)
                    .stroke(ground.ink.opacity(0.4), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [1, 10]))
                    .dxFade(delay: 1.3)
                    .accessibilityHidden(true)

                if let goal {
                    ZStack {
                        if goal.isDayXero {
                            DXBadge(.xero, state: .next(nil), size: 76)
                        } else {
                            DXBadge(.day, state: .next(nil), size: 76)
                        }
                    }
                    .frame(width: 76, height: 76)
                    .shadow(color: Color(red: 150 / 255, green: 90 / 255, blue: 20 / 255).opacity(0.24), radius: 6, y: 6)
                    .position(x: goalX, y: goalY)
                    .modifier(CoinRise())
                    .accessibilityElement()
                    .accessibilityLabel(Text(verbatim: [goal.title, goal.subtitle].compactMap { $0 }.joined(separator: ", ")))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(verbatim: goal.title).dxFace(.display, 20, weight: 700, tracking: -0.2).foregroundStyle(ground.ink)
                        if let subtitle = goal.subtitle {
                            Text(verbatim: subtitle).dxFace(.body, 14, weight: 600).foregroundStyle(Self.muted)
                        }
                    }
                    .fixedSize()
                    .frame(width: max(width - goalX - 52, 10), alignment: .leading)
                    .position(x: goalX + 52 + max(width - goalX - 52, 10) / 2, y: goalY - 4)
                    .dxFade(delay: 1.9)
                    .accessibilityHidden(true)
                }
                ProgramHill(layer: .front, top: goalY - 14)
                    .frame(width: width + 2 * DX.Layout.gutter, height: height + 700)
                    .offset(x: -DX.Layout.gutter)
                    .modifier(HillRise(delay: 1.6))
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                    let isGoal = goal == nil && index == last && stops.count > 1
                    let p = isGoal ? CGPoint(x: goalX, y: goalY) : CGPoint(x: x, y: ys[index])
                    Button { onTap(stop) } label: { node(stop, number: index + 1, isGoal: isGoal) }
                        .buttonStyle(.dxPress)
                        .position(p)
                        .modifier(StopArrive(index: index, kind: stop.kind, isGoal: isGoal))
                        .accessibilityLabel(Text(verbatim: "\(stop.kicker). \(stop.title)"))
                        .accessibilityValue(Text(verbatim: stop.accessibility))
                        .accessibilityHint(Text("Shows this session"))
                    label(stop, isGoal: isGoal, at: p, width: width)
                        .modifier(StopArrive(index: index, kind: stop.kind, isGoal: isGoal, label: true))
                }
            }
        }
        .frame(height: height)
        .sensoryFeedback(.impact(weight: .light), trigger: reached) { _, now in now }
        .onAppear {
            guard !filled else { return }
            withAnimation(motion.animation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 1.1)).delay(0.3)) { filled = true }
            Task {
                try? await Task.sleep(for: .seconds(1.4))
                reached = doneUpTo > 0
            }
        }
    }

    /// Top-down: stamps 54 pt apart, today's 64 pt from its neighbours; the goal 62 pt under the last stamp.
    private func yPositions() -> [CGFloat] {
        var ys: [CGFloat] = []
        var y: CGFloat = 30
        for i in 0..<slots {
            if i > 0 {
                let kind = i < stops.count ? stops[i].kind : .goal
                let aroundToday = kind == .today || stops[i - 1].kind == .today
                y += i == slots - 1 && slots > 1 ? 62 : aroundToday ? todayGap : step
            }
            ys.append(y)
        }
        return ys
    }

    private func roadPoints(ys: [CGFloat], goalX: CGFloat) -> [CGPoint] {
        guard slots > 1 else { return ys.map { CGPoint(x: x, y: $0) } }
        var pts = ys.dropLast().map { CGPoint(x: x, y: $0) }
        let goalY = ys.last ?? 0
        pts.append(CGPoint(x: x + 2, y: goalY - 32))
        pts.append(CGPoint(x: x + 28, y: goalY - 5))
        pts.append(CGPoint(x: goalX - 24, y: goalY))
        // The goal is the last index on the road; the extra sweep points sit between the last stamp and it.
        return pts
    }

    @ViewBuilder
    private func node(_ stop: Stop, number: Int, isGoal: Bool) -> some View {
        if isGoal {
            ZStack {
                DXBadge(.xero, state: stop.kind == .done ? .earned : .next(nil), size: 76)
            }
            .frame(width: 76, height: 76)
        } else {
            switch stop.kind {
            case .done:
                ZStack {
                    // kit `.stamp`: a 3 pt ring of the page round each stamp, so it sits on the road like a seal.
                    Circle().fill(Color(light: 0xFBF6EC, dark: 0x0E1322)).frame(width: 48, height: 48)
                    DXBadge(.prep, size: 42)
                    Text(verbatim: "\(number)").dxFace(.display, 17, weight: 800, tracking: -0.3).foregroundStyle(Color(hex: 0x1E1A3A))
                }
            case .today:
                TodaySeal()
            case .locked, .goal:
                ZStack {
                    Circle().fill(Color(light: 0xFBF6EC, dark: 0x0E1322)).frame(width: 48, height: 48)
                    Circle().fill(Color(light: 0xFFFFFF, dark: 0x212A41)).frame(width: 42, height: 42)
                    DXBadge(.prep, state: .next(nil), size: 42)
                    if stop.needsUpgrade {
                        DXIcon(.lock, size: 14, weight: 2.4).foregroundStyle(ground.ink)
                    } else {
                        Text(verbatim: "\(number)").dxFace(.display, 17, weight: 800).foregroundStyle(ground.ink.opacity(0.8))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func label(_ stop: Stop, isGoal: Bool, at p: CGPoint, width: CGFloat) -> some View {
        if isGoal {
            Text(verbatim: stop.title)
                .dxFace(.display, 20, weight: 700, tracking: -0.2)
                .foregroundStyle(ground.ink)
                .fixedSize()
                .position(x: p.x + 52 + 50, y: p.y - 4)
                .accessibilityHidden(true)
        } else if stop.kind == .today {
            // The up-next card beside today's stamp, with a small pointer toward it.
            let left = p.x + 50
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: stop.kicker).dxFace(.body, 13, weight: 600).foregroundStyle(DX.Ground.reading.muted)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Text(verbatim: stop.title).dxType(.headline).foregroundStyle(DX.Ground.reading.ink)
                    .lineLimit(2).minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14).padding(.bottom, 15)
            .frame(width: width - left, alignment: .leading)
            .background(alignment: .leading) {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color(light: 0xFFFFFF, dark: 0x182034))
                        .frame(width: 14, height: 14).rotationEffect(.degrees(45)).offset(x: -6)
                    RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color(light: 0xFFFFFF, dark: 0x182034))
                }
                .shadow(color: Color(light: (0x24493A, 0.12), dark: (0x000000, 0)), radius: 11, y: 8)
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color(light: (0xFFFFFF, 0), dark: (0xFFFFFF, 0.12)), lineWidth: 1)
                }
            }
            .position(x: left + (width - left) / 2, y: p.y)
            .accessibilityHidden(true)
        } else {
            let left = p.x + 40
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: stop.kicker).dxFace(.body, 13, weight: 600).foregroundStyle(Self.muted)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Text(verbatim: stop.title)
                    .dxFace(.body, 15, weight: stop.kind == .done ? 500 : 600)
                    .foregroundStyle(stop.kind == .done ? Self.muted : ground.ink)
                    .lineLimit(1).minimumScaleFactor(0.85)
            }
            .frame(width: width - left, alignment: .leading)
            .position(x: left + (width - left) / 2, y: p.y)
            .accessibilityHidden(true)
        }
    }
}

/// Today's stamp: a 68 pt scalloped seal in the button colour with a play mark, breathing a soft pulse ring (2.4 s).
private struct TodaySeal: View {
    @Environment(\.colorScheme) private var scheme
    private let motion = MotionPolicy()

    var body: some View {
        let t = DX.Ground.reading.tokens(dark: scheme == .dark)
        ZStack {
            TimelineView(.animation(minimumInterval: 1 / 30, paused: motion.reduce)) { timeline in
                let k = motion.reduce ? 0 : (timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2.4)) / 2.4
                Circle().stroke(Color(hex: t.btn).opacity(0.35 * (1 - k)), lineWidth: 2)
                    .frame(width: 68, height: 68)
                    .scaleEffect(1 + 0.3 * k)
            }
            SealShape().fill(Color(hex: t.btn)).frame(width: 68, height: 68)
            Circle().stroke(Color(hex: t.btnFg).opacity(0.28), style: StrokeStyle(lineWidth: 1.4, dash: [2, 3.4]))
                .frame(width: 52, height: 52)
            DXIcon(.play, size: 26, weight: 1.5, filled: true).foregroundStyle(Color(hex: t.btnFg)).offset(x: 2)
        }
        .frame(width: 68, height: 68)
    }
}

/// A disc ringed with 18 small round scallops (kit 022 `seal(50, 50, 41, 18, 8.4)`), in a 100 × 100 box.
private struct SealShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 100
        var p = Path()
        p.addEllipse(in: CGRect(x: (50 - 41) * s, y: (50 - 41) * s, width: 82 * s, height: 82 * s))
        for i in 0..<18 {
            let a = 2 * Double.pi * Double(i) / 18 - .pi / 2
            let cx = 50 + 41 * cos(a), cy = 50 + 41 * sin(a)
            p.addEllipse(in: CGRect(x: (cx - 8.4) * s, y: (cy - 8.4) * s, width: 16.8 * s, height: 16.8 * s))
        }
        return p.offsetBy(dx: rect.minX, dy: rect.minY)
    }
}

/// Done stamps arrive as the fill reaches them (about 360 ms apart from 300 ms); today's lands at 1.25 s; later ones
/// fade in at 1.4 s; the goal rises onto the horizon (1.1 s settle).
private struct StopArrive: ViewModifier {
    let index: Int
    let kind: ProgramPathMap.Stop.Kind
    let isGoal: Bool
    var label = false

    func body(content: Content) -> some View {
        if isGoal {
            content.modifier(CoinRise())
        } else {
            switch kind {
            case .done: content.dxArrive(0, delay: 0.3 + Double(index) * 0.36 + (label ? 0.06 : 0))
            case .today: content.dxArrive(0, delay: 1.25)
            case .locked, .goal: content.dxFade(delay: label ? 1.45 : 1.4)
            }
        }
    }
}

/// The coin rises onto the horizon like a sunrise: 40 pt up and in, 1100 ms settle, from 1.75 s.
private struct CoinRise: ViewModifier {
    @State private var up = false
    private let motion = MotionPolicy()

    func body(content: Content) -> some View {
        content
            .offset(y: up || motion.reduce ? 0 : 40)
            .opacity(up || motion.reduce ? 1 : 0)
            .onAppear {
                withAnimation(motion.animation(DX.Move.settle.speed(0.9 / 1.1)).delay(1.75)) { up = true }
            }
    }
}

/// A hill rises 24 pt into place (900 ms settle).
private struct HillRise: ViewModifier {
    let delay: Double
    @State private var up = false
    private let motion = MotionPolicy()

    func body(content: Content) -> some View {
        content
            .offset(y: up || motion.reduce ? 0 : 24)
            .opacity(up || motion.reduce ? 1 : 0)
            .onAppear { withAnimation(motion.animation(DX.Move.settle).delay(delay)) { up = true } }
    }
}

/// A Catmull-Rom spline through `points[from...to]`, as a shape, so its stroke can be trimmed and animated.
private struct SplineShape: Shape {
    let points: [CGPoint]
    let from: Int
    let to: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard from >= 0, to < points.count, from <= to else { return path }
        path.move(to: points[from])
        guard from < to else { return path }
        for i in from..<to {
            let p0 = points[max(i - 1, 0)], p1 = points[i], p2 = points[i + 1], p3 = points[min(i + 2, points.count - 1)]
            let c1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
            let c2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
            path.addCurve(to: p2, control1: c1, control2: c2)
        }
        return path
    }
}

/// The warm glow where Day Xero rises (kit 022 `.glow`): a soft radial pool round the coin and a faint band on the horizon.
private struct HorizonGlow: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let a = scheme == .dark ? 0.3 : 0.66
        let glow = scheme == .dark ? Color(red: 1, green: 176 / 255, blue: 104 / 255) : Color(red: 1, green: 172 / 255, blue: 80 / 255)
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                LinearGradient(stops: [.init(color: glow.opacity(0), location: 0.34), .init(color: glow.opacity(a * 0.45), location: 0.56),
                                       .init(color: glow.opacity(0), location: 0.66)], startPoint: .top, endPoint: .bottom)
                Ellipse()
                    .fill(RadialGradient(stops: [.init(color: glow.opacity(a), location: 0), .init(color: glow.opacity(a * 0.35), location: 0.55),
                                                 .init(color: glow.opacity(0), location: 1)], center: .center, startRadius: 0, endRadius: 200))
                    .frame(width: 400, height: 300)
                    .position(x: 150 * proxy.size.width / 390, y: 162)
            }
        }
    }
}

/// One of the two sage hills the road runs into (kit 022 `.hill.b` and `.hill.f`), drawn from `top`.
struct ProgramHill: View {
    enum Layer { case back, front }
    let layer: Layer
    let top: CGFloat
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let dark = scheme == .dark
        Canvas { ctx, size in
            let sx = size.width / 390
            func y(_ v: CGFloat) -> CGFloat { top + (v - 548) }
            let fill = layer == .back ? Color(hex: dark ? 0x1E3646 : 0xE4E6D2) : Color(hex: dark ? 0x172B3A : 0xD2D9BE)
            let rim = dark ? Color(hex: 0xC8E1EB).opacity(0.14) : Color.white.opacity(0.7)
            let sh = dark ? Color.black.opacity(0.5) : Color(hex: 0x464828).opacity(0.18)
            var edge = Path()
            if layer == .back {
                edge.move(to: CGPoint(x: 0, y: y(576)))
                edge.addCurve(to: CGPoint(x: 170 * sx, y: y(562)), control1: CGPoint(x: 50 * sx, y: y(562)), control2: CGPoint(x: 110 * sx, y: y(556)))
                edge.addCurve(to: CGPoint(x: 340 * sx, y: y(554)), control1: CGPoint(x: 230 * sx, y: y(568)), control2: CGPoint(x: 290 * sx, y: y(564)))
                edge.addCurve(to: CGPoint(x: 390 * sx, y: y(548)), control1: CGPoint(x: 362 * sx, y: y(550)), control2: CGPoint(x: 378 * sx, y: y(548)))
            } else {
                edge.move(to: CGPoint(x: 0, y: y(600)))
                edge.addCurve(to: CGPoint(x: 180 * sx, y: y(586)), control1: CGPoint(x: 60 * sx, y: y(588)), control2: CGPoint(x: 120 * sx, y: y(582)))
                edge.addCurve(to: CGPoint(x: 390 * sx, y: y(580)), control1: CGPoint(x: 240 * sx, y: y(590)), control2: CGPoint(x: 300 * sx, y: y(596)))
            }
            var area = edge
            area.addLine(to: CGPoint(x: size.width, y: size.height)); area.addLine(to: CGPoint(x: 0, y: size.height)); area.closeSubpath()
            var lifted = ctx
            lifted.addFilter(.shadow(color: sh, radius: 5, y: -3))
            lifted.fill(area, with: .color(fill))
            ctx.stroke(edge, with: .color(rim), lineWidth: 1.5)
        }
    }
}

/// Each session's illustration from the kit (decision 31).
enum ProgramArt {
    static func kind(for sessionId: String) -> KitArt.Kind {
        switch sessionId {
        case "P1": .dawn
        case "P2": .cup
        case "P3": .eye
        case "P4": .breath
        case "P5": .sea
        case "P6": .heart
        case "P7": .night
        case "DX": .flower
        case "W1D1": .glass
        case "W1D2": .clouds
        case "W1D3": .sprout
        case "W1D4": .sparkle
        case "W1D5": .night
        case "W1D6": .tag
        case "W1D7": .peak
        case "W2S1": .clouds
        case "W2S2": .night
        case "W2S4": .dawn
        case "W2S3": .peak
        case "W3S1": .anchor
        case "W3S2": .sea
        case "W3S3": .sprout
        case "W4S1": .heart
        case "W4S2": .shield
        case "W4S3": .flower
        // Boosters after graduation (S27.18).
        case "B45": .sea
        case "B60": .anchor
        case "B90": .peak
        default: .dawn
        }
    }
}
