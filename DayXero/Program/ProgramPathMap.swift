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
        let kind: Kind
        let minutes: Int
        let needsUpgrade: Bool
        let accessibility: String
    }

    /// The next phase, waiting on the horizon at the road's end (022: the Day Xero coin under the prep week).
    struct Goal {
        let title: String
        let isDayXero: Bool
    }

    let stops: [Stop]
    let ground: DX.Ground
    var goal: Goal?
    let onTap: (Stop) -> Void
    @State private var filled = false
    private let motion = MotionPolicy()

    /// The road's column, the gap between stamps (today's gets more room), and the goal's drop onto the horizon.
    private let x: CGFloat = 36
    private let step: CGFloat = 54
    private let todayGap: CGFloat = 64
    static let road = Color(light: 0xCBEBD8, dark: 0x34526B)
    static let roadEdge = Color(light: (0x24493A, 0.16), dark: (0x000000, 0.5))
    static let roadDone = Color(light: 0xFFAE73, dark: 0xC27A4E)

    /// Road slots: every stop, plus the goal when there is one; without a goal the last stop is the coin.
    private var slots: Int { stops.count + (goal == nil ? 0 : 1) }

    var body: some View {
        let ys = yPositions()
        let last = goal == nil ? stops.count - 1 : stops.count
        let goalY = (ys.last ?? 0)
        let height = goalY + 90
        let todayIndex = stops.firstIndex { $0.kind == .today }
        let doneUpTo = todayIndex ?? (stops.lastIndex { $0.kind == .done } ?? -1)
        GeometryReader { proxy in
            let width = proxy.size.width
            let goalX = min(140, width * 0.36)
            let points = roadPoints(ys: ys, goalX: goalX)
            ZStack(alignment: .topLeading) {
                ProgramHills(top: goalY - 20)
                    .frame(width: width + 2 * DX.Layout.gutter, height: height + 60)
                    .offset(x: -DX.Layout.gutter)
                    .accessibilityHidden(true)
                Canvas { ctx, _ in
                    guard points.count > 1 else { return }
                    let road = spline(points, 0, slots - 1)
                    var edge = ctx
                    edge.translateBy(x: 0, y: 3)
                    edge.stroke(road, with: .color(Self.roadEdge), style: StrokeStyle(lineWidth: 56, lineCap: .round, lineJoin: .round))
                    ctx.stroke(road, with: .color(Self.road), style: StrokeStyle(lineWidth: 52, lineCap: .round, lineJoin: .round))
                    if doneUpTo > 0 {
                        ctx.stroke(spline(points, 0, doneUpTo).trimmedPath(from: 0, to: filled || motion.reduce ? 1 : 0),
                                   with: .color(Self.roadDone), style: StrokeStyle(lineWidth: 52, lineCap: .round, lineJoin: .round))
                    }
                    ctx.stroke(spline(points, max(doneUpTo, 0) + 1, slots - 1), with: .color(ground.ink.opacity(0.4)),
                               style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [1, 10]))
                }
                .animation(motion.animation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 1.1)), value: filled)
                .accessibilityHidden(true)

                if let goal {
                    ZStack {
                        goalGlow
                        if goal.isDayXero {
                            DXBadge(.xero, state: .next(nil), size: 76)
                        } else {
                            DXBadge(.day, state: .next(nil), size: 76)
                        }
                    }
                    .frame(width: 76, height: 76)
                    .position(x: goalX, y: goalY)
                    .dxSettle(delay: 1.3)
                    .accessibilityElement()
                    .accessibilityLabel(Text(verbatim: goal.title))
                    Text(verbatim: goal.title)
                        .dxType(.headline)
                        .foregroundStyle(ground.ink)
                        .fixedSize()
                        .position(x: goalX + 50 + 50, y: goalY - 4)
                        .dxFade(delay: 1.9)
                        .accessibilityHidden(true)
                }
                ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                    let isGoal = goal == nil && index == last && stops.count > 1
                    let p = isGoal ? CGPoint(x: goalX, y: goalY) : CGPoint(x: x, y: ys[index])
                    Button { onTap(stop) } label: { node(stop, number: index + 1, isGoal: isGoal) }
                        .buttonStyle(.dxPress)
                        .position(p)
                        .modifier(StopArrive(index: index, kind: stop.kind, isGoal: isGoal))
                        .accessibilityLabel(Text(verbatim: stop.title))
                        .accessibilityValue(Text(verbatim: stop.accessibility))
                        .accessibilityHint(Text("Shows this session"))
                    label(stop, isGoal: isGoal, at: p, width: width)
                        .modifier(StopArrive(index: index, kind: stop.kind, isGoal: isGoal))
                }
            }
        }
        .frame(height: height)
        .sensoryFeedback(.impact(weight: .light), trigger: filled)
        .onAppear {
            guard !filled else { return }
            withAnimation(motion.animation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 1.1)).delay(0.15)) { filled = true }
        }
    }

    private var goalGlow: some View {
        Circle()
            .fill(RadialGradient(colors: [Color(light: (0xFFAC50, 0.5), dark: (0xFFB068, 0.3)), .clear],
                                 center: .center, startRadius: 0, endRadius: 70))
            .frame(width: 150, height: 150)
            .allowsHitTesting(false)
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

    /// A Catmull-Rom spline through the points `from`...`to` (road indices map to stops; the last stop is the end).
    private func spline(_ all: [CGPoint], _ fromStop: Int, _ toStop: Int) -> Path {
        let lastStop = slots - 1
        let from = fromStop
        let to = toStop >= lastStop ? all.count - 1 : toStop
        var path = Path()
        guard from < all.count, to < all.count, from <= to else { return path }
        path.move(to: all[from])
        guard from < to else { return path }
        for i in from..<to {
            let p0 = all[max(i - 1, 0)], p1 = all[i], p2 = all[i + 1], p3 = all[min(i + 2, all.count - 1)]
            let c1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
            let c2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
            path.addCurve(to: p2, control1: c1, control2: c2)
        }
        return path
    }

    @ViewBuilder
    private func node(_ stop: Stop, number: Int, isGoal: Bool) -> some View {
        if isGoal {
            ZStack {
                goalGlow
                DXBadge(.xero, state: stop.kind == .done ? .earned : .next(nil), size: 76)
            }
            .frame(width: 76, height: 76)
        } else {
            switch stop.kind {
            case .done:
                ZStack {
                    DXBadge(.prep, size: 42)
                    Text(verbatim: "\(number)").dxFace(.display, 17, weight: 800, tracking: -0.3).foregroundStyle(Color(hex: 0x1E1A3A))
                }
            case .today:
                TodaySeal()
            case .locked, .goal:
                ZStack {
                    Circle().fill(Color(light: 0xFBF6EC, dark: 0x182034)).frame(width: 42, height: 42)
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
                .dxType(.headline)
                .foregroundStyle(ground.ink)
                .fixedSize()
                .position(x: p.x + 50 + 60, y: p.y - 4)
                .accessibilityHidden(true)
        } else if stop.kind == .today {
            let left = p.x + 42
            VStack(alignment: .leading, spacing: 2) {
                Text("Today · \(stop.minutes) min").dxType(.caption).foregroundStyle(DX.Ground.reading.muted)
                Text(verbatim: stop.title).dxType(.headline).foregroundStyle(DX.Ground.reading.ink)
                    .lineLimit(2).minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(width: width - left, alignment: .leading)
            .background(Color(light: 0xFFFFFF, dark: 0x182034), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color(light: (0x24493A, 0.12), dark: (0x000000, 0.3)), radius: 10, y: 6)
            .position(x: left + (width - left) / 2, y: p.y)
            .accessibilityHidden(true)
        } else {
            let left = p.x + 40
            Text(verbatim: stop.title)
                .dxFace(stop.kind == .done ? .body : .body, 15, weight: stop.kind == .done ? 500 : 600)
                .foregroundStyle(stop.kind == .done ? ground.muted : ground.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
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

    func body(content: Content) -> some View {
        if isGoal {
            content.dxSettle(delay: 1.3)
        } else {
            switch kind {
            case .done: content.dxArrive(0, delay: 0.3 + Double(index) * 0.36)
            case .today: content.dxArrive(0, delay: 1.25)
            case .locked, .goal: content.dxFade(delay: 1.4)
            }
        }
    }
}

/// The two sage hills the road runs into (kit 022 `.hill.b` and `.hill.f`), drawn from `top`.
struct ProgramHills: View {
    let top: CGFloat
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let dark = scheme == .dark
        Canvas { ctx, size in
            let sx = size.width / 390
            func y(_ v: CGFloat) -> CGFloat { top + (v - 548) }
            let back = Color(hex: dark ? 0x1E3646 : 0xE4E6D2), front = Color(hex: dark ? 0x172B3A : 0xD2D9BE)
            let rim = dark ? Color(hex: 0xC8E1EB).opacity(0.14) : Color.white.opacity(0.7)
            let sh = dark ? Color.black.opacity(0.5) : Color(hex: 0x464828).opacity(0.18)
            var b = Path()
            b.move(to: CGPoint(x: 0, y: y(576)))
            b.addCurve(to: CGPoint(x: 170 * sx, y: y(562)), control1: CGPoint(x: 50 * sx, y: y(562)), control2: CGPoint(x: 110 * sx, y: y(556)))
            b.addCurve(to: CGPoint(x: 340 * sx, y: y(554)), control1: CGPoint(x: 230 * sx, y: y(568)), control2: CGPoint(x: 290 * sx, y: y(564)))
            b.addCurve(to: CGPoint(x: 390 * sx, y: y(548)), control1: CGPoint(x: 362 * sx, y: y(550)), control2: CGPoint(x: 378 * sx, y: y(548)))
            var bFill = b
            bFill.addLine(to: CGPoint(x: size.width, y: size.height)); bFill.addLine(to: CGPoint(x: 0, y: size.height)); bFill.closeSubpath()
            var lifted = ctx
            lifted.addFilter(.shadow(color: sh, radius: 5, y: -3))
            lifted.fill(bFill, with: .color(back))
            ctx.stroke(b, with: .color(rim), lineWidth: 1.5)
            var f = Path()
            f.move(to: CGPoint(x: 0, y: y(600)))
            f.addCurve(to: CGPoint(x: 180 * sx, y: y(586)), control1: CGPoint(x: 60 * sx, y: y(588)), control2: CGPoint(x: 120 * sx, y: y(582)))
            f.addCurve(to: CGPoint(x: 390 * sx, y: y(580)), control1: CGPoint(x: 240 * sx, y: y(590)), control2: CGPoint(x: 300 * sx, y: y(596)))
            var fFill = f
            fFill.addLine(to: CGPoint(x: size.width, y: size.height)); fFill.addLine(to: CGPoint(x: 0, y: size.height)); fFill.closeSubpath()
            lifted.fill(fFill, with: .color(front))
            ctx.stroke(f, with: .color(rim), lineWidth: 1.5)
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
