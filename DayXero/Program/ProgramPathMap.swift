import DayXeroCore
import SwiftUI

/// One phase of the program as stepping stones across the water, bottom to top (canvas "Prep progress & rewards",
/// board 01): done stones ticked on a walked path, today's in coral with a pulsing ring and Xero standing on it, later
/// ones locked, and the island with its flag at the far shore. Done and locked stones carry a pill with their number
/// and title; today's (or the next one waiting) carries a card with when it is and how long.
///
/// Drawn on the mockup's 390-point-wide grid and scaled to the width. The water, sun, clouds and flag run on one
/// clock; with Reduce Motion the clock stops and Xero rests.
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

    let stops: [Stop]
    let ground: DX.Ground
    /// Xero's growth stage (`CrewGrowth.stage`).
    var stage = 1
    /// A line by the island, such as the Quit Day's date during prep.
    var chip: String?
    let onTap: (Stop) -> Void

    private let motion = MotionPolicy()

    private nonisolated static let gridWidth: CGFloat = 390
    /// Sky above the first wave, on the grid.
    private nonisolated static let shore: Double = 110
    private nonisolated static let island = CGPoint(x: 253, y: 100)
    private static let leftX: [CGFloat] = [140, 120, 150, 130]
    private static let rightX: [CGFloat] = [290, 270, 290, 280]

    var body: some View {
        let points = Self.points(count: stops.count)
        let gridHeight = Self.height(count: stops.count)
        let todayIndex = stops.firstIndex { $0.kind == .today }
        let firstOpen = stops.firstIndex { $0.kind != .done }
        // Where Xero stands: today's stone, else the next one waiting, else the island once the phase is done.
        let standing = todayIndex ?? firstOpen
        let doneCount = stops.prefix(while: { $0.kind == .done }).count
        let moving = !motion.reduce
        GeometryReader { proxy in
            let k = proxy.size.width / Self.gridWidth
            ZStack(alignment: .topLeading) {
                TimelineView(.animation(paused: !moving)) { timeline in
                    let time = moving ? timeline.date.timeIntervalSinceReferenceDate : 0
                    Canvas { context, size in
                        context.scaleBy(x: size.width / Self.gridWidth, y: size.width / Self.gridWidth)
                        Self.draw(&context, time: time, points: points, done: doneCount, allDone: standing == nil, height: gridHeight)
                    }
                }
                .accessibilityHidden(true)

                if let chip {
                    Text(verbatim: chip)
                        .dxType(.caption)
                        .foregroundStyle(DX.Fill.navy)
                        .lineLimit(1).minimumScaleFactor(0.7)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(DX.Fill.cream, in: Capsule())
                        .shadow(color: Color(hex: 0x0F6E43).opacity(0.12), radius: 9, y: 6)
                        .frame(maxWidth: 170 * k, alignment: .leading)
                        .offset(x: 20 * k, y: 80 * k)
                        .accessibilityHidden(true)
                }

                ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                    let p = CGPoint(x: points[index].x * k, y: points[index].y * k)
                    let focused = index == standing
                    label(stop, number: index + 1, focused: focused, at: p, width: proxy.size.width, k: k)
                    Button { onTap(stop) } label: { stone(stop, current: focused, k: k) }
                        .buttonStyle(.plain)
                        .modifier(Bob(delay: Double(index) * 0.35))
                        .position(p)
                        .accessibilityLabel(Text(verbatim: stop.title))
                        .accessibilityValue(Text(verbatim: stop.accessibility))
                        .accessibilityHint(Text("Shows this session"))
                }

                // Xero: 64 points on the grid, feet on the stone. Moving to a new stone, he hops.
                let feet = standing.map { CGPoint(x: points[$0].x, y: points[$0].y + 1) } ?? CGPoint(x: Self.island.x + 28, y: Self.island.y + 2)
                let hop: CGFloat = motion.reduce ? 0 : -56 * k
                XeroView(mood: .hello, stage: stage, points: 64 * k)
                    .keyframeAnimator(initialValue: CGFloat(0), trigger: standing) { view, lift in
                        view.offset(y: lift)
                    } keyframes: { _ in
                        KeyframeTrack {
                            CubicKeyframe(hop, duration: 0.36)
                            CubicKeyframe(0, duration: 0.44)
                        }
                    }
                    .position(x: feet.x * k, y: (feet.y - 61 + 32) * k)
                    .animation(motion.animation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.8)), value: standing)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .aspectRatio(Self.gridWidth / gridHeight, contentMode: .fit)
        // The sky runs up behind the title and the phase track, and under the status bar.
        .background(alignment: .top) { ProgressScene.sky.padding(.top, -1000) }
    }

    // MARK: Layout

    /// The grid's height for this many stones: sky and island, then 40 points a stone.
    private static func height(count: Int) -> CGFloat {
        146 + CGFloat(max(count, 1) - 1) * 40 + 38
    }

    /// The stones' centres on the grid, first at the bottom, alternating left and right.
    private static func points(count: Int) -> [CGPoint] {
        let bottom = height(count: count) - 38
        return (0..<count).map { i in
            let x = i.isMultiple(of: 2) ? leftX[(i / 2) % leftX.count] : rightX[(i / 2) % rightX.count]
            return CGPoint(x: x, y: bottom - CGFloat(i) * 40)
        }
    }

    // MARK: Drawing

    private nonisolated static func draw(_ ctx: inout GraphicsContext, time t: Double, points: [CGPoint], done: Int, allDone: Bool, height: CGFloat) {
        let bottom = Double(height)
        // Sky: the sun and two clouds, then the island at the far shore.
        ProgressScene.sun(&ctx, x: 314, y: 40, radius: 24, time: t)
        ProgressScene.cloud(&ctx, x: 24 + 24 * (2 * ProgressScene.swing(t, 14) - 1), y: 58, scale: 74.0 / 70, color: ProgressScene.cloudWhite)
        ProgressScene.cloud(&ctx, x: 150 - 24 * (2 * ProgressScene.swing(t, 18) - 1), y: 22, scale: 50.0 / 70, color: ProgressScene.cloudWhite)
        ProgressScene.islandAndFlag(&ctx, at: island, halfWidth: 80, time: t)

        // Water: the back band from the shore down, the front band (the screen's own mint) over its lower part.
        ctx.fill(ProgressScene.water(top: shore, amplitude: 6, wavelength: 130, shift: t / 18 * 390, bottom: bottom),
                 with: .color(ProgressScene.backWater))
        ctx.fill(ProgressScene.water(top: shore + (bottom - shore) * 0.47, amplitude: 7, wavelength: 195, shift: t / 10 * 390, bottom: bottom),
                 with: .color(DX.Ground.mint.background))
        // Ripples drifting with the front band.
        let ripple = Color(light: 0x7FCFA2, dark: 0x2A6B52)
        let drift = (t / 10 * 390).truncatingRemainder(dividingBy: 390)
        let marks: [(x: Double, y: Double)] = [(24, 0.18), (330, 0.42), (40, 0.7), (220, 0.93), (200, 0.06)]
        for base in marks {
            let y = shore + 24 + (bottom - shore - 40) * base.y
            for copy in 0..<2 {
                let x = base.x - drift + Double(copy) * 390
                var mark = Path()
                mark.move(to: CGPoint(x: x, y: y))
                mark.addQuadCurve(to: CGPoint(x: x + 16, y: y), control: CGPoint(x: x + 8, y: y - 6))
                mark.addQuadCurve(to: CGPoint(x: x + 32, y: y), control: CGPoint(x: x + 24, y: y + 6))
                ctx.stroke(mark, with: .color(ripple), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
        }

        // The path: solid where it's been walked, dotted ahead to the island.
        guard !points.isEmpty else { return }
        let walked = Array(points.prefix(max(done, 1))) + (allDone ? [island] : [])
        if !allDone {
            let ahead = Array(points.suffix(from: max(done - 1, 0))) + [island]
            ctx.stroke(ProgressScene.polyline(ahead), with: .color(Color(hex: 0xFFF8EE)),
                       style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [2, 8]))
        }
        if walked.count > 1 {
            ctx.stroke(ProgressScene.polyline(walked), with: .color(Color(hex: 0x0F6E43).opacity(0.55)),
                       style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
        }
    }

    // MARK: Stones and labels

    /// A stone, 64 × 22 on the grid, inside a 44-point touch target: cream with a tick when done, coral with a pulsing
    /// ring where Xero stands, clear with a lock (or a star for the phase's last) when it comes later.
    private func stone(_ stop: Stop, current: Bool, k: CGFloat) -> some View {
        let done = stop.kind == .done
        let hot = stop.kind == .today
        let fill: Color = done ? DX.Fill.cream : hot ? Color(hex: 0xFF7A55) : Color.white.opacity(0.55)
        let border: Color = done ? Color(hex: 0x0F6E43) : hot ? DX.Fill.cream : Color.white.opacity(0.8)
        let edge: Color = done ? Color(hex: 0x0B5634) : hot ? Color(hex: 0xD9572F) : Color(hex: 0x0F6E43).opacity(0.18)
        return ZStack {
            if current { PulseRing() }
            Ellipse().fill(edge).offset(y: 4 * k)
            Ellipse().fill(fill)
            Ellipse().strokeBorder(border, lineWidth: 2)
            if done {
                Image(systemName: "checkmark").font(.system(size: 11 * k, weight: .black)).foregroundStyle(Color(hex: 0x0F6E43))
            } else if !hot {
                Image(systemName: stop.kind == .goal ? "star.fill" : stop.needsUpgrade ? "lock.open.fill" : "lock.fill")
                    .font(.system(size: 9 * k, weight: .bold)).foregroundStyle(Color(hex: 0x24493A))
            }
        }
        .frame(width: 64 * k, height: 22 * k)
        .frame(minWidth: 64 * k, minHeight: 44)
        .contentShape(Rectangle())
    }

    /// The pill or card beside a stone, on whichever side has the room.
    @ViewBuilder
    private func label(_ stop: Stop, number: Int, focused: Bool, at p: CGPoint, width: CGFloat, k: CGFloat) -> some View {
        let right = p.x < width / 2
        let gap = 40 * k
        let room = max(right ? width - p.x - gap - 12 : p.x - gap - 12, 60)
        Group {
            if focused {
                VStack(alignment: .leading, spacing: 1) {
                    Text(verbatim: stop.kind == .today ? String(localized: "Today · \(stop.minutes) min") : stop.accessibility)
                        .dxType(.caption).textCase(.uppercase).foregroundStyle(Color(hex: 0xB23A1E))
                    Text(verbatim: stop.title)
                        .font(DX.Typeface4.swiftUIFont(.display, size: 15, weight: 800))
                        .foregroundStyle(DX.Fill.navy)
                }
                .lineLimit(1).minimumScaleFactor(0.7)
                .padding(.horizontal, 11).padding(.vertical, 7)
                .background(DX.Fill.cream, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .shadow(color: Color(hex: 0x0F6E43).opacity(0.18), radius: 11, y: 8)
                .dxArrive(1)
            } else {
                let done = stop.kind == .done
                Text(verbatim: "\(number) · \(stop.title)")
                    .font(DX.Typeface4.swiftUIFont(.body, size: 12.5, weight: 700))
                    .foregroundStyle(done ? DX.Fill.cream : DX.Fill.navy)
                    .lineLimit(1).minimumScaleFactor(0.75)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(done ? DX.Fill.navy : DX.Fill.cream.opacity(0.8), in: Capsule())
            }
        }
        .frame(width: room, alignment: right ? .leading : .trailing)
        .position(x: right ? p.x + gap + room / 2 : p.x - gap - room / 2, y: p.y - (focused ? 4 : 0))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A stone bobbing 2 pt on a 3 s cycle, each a little behind the one before. Still with Reduce Motion.
private struct Bob: ViewModifier {
    let delay: Double
    @State private var down = false
    private let motion = MotionPolicy()

    func body(content: Content) -> some View {
        content
            .offset(y: down ? 2 : 0)
            .onAppear {
                guard !motion.reduce, !down else { return }
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(delay)) { down = true }
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
