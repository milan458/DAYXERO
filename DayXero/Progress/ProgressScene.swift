import DayXeroCore
import SwiftUI

/// The scene at the top of Progress (canvas "Prep progress & rewards", boards 04 and 05): drifting water, a sun, two
/// clouds, the Quit Day island with its flag, and the prep days as stepping stones leading to it. Xero stands on
/// today's stone during prep and on the island from Quit Day on.
///
/// Drawn on the mockup's 390 × 193 grid and scaled to the width. Everything that moves is driven by one clock, with
/// the mockup's periods; with Reduce Motion the clock stops and the scene rests.
struct ProgressScene: View {
    /// Prep days done, or nil from Quit Day on (every stone ticked, Xero on the island).
    let prepDone: Int?
    let prepTotal: Int
    /// Xero's growth stage (`CrewGrowth.stage`).
    let stage: Int
    /// The line in the chip: Quit Day's date in prep, the sky's clarity after.
    let chip: String

    private let motion = MotionPolicy()

    static let sky = Color(light: 0xE4F7EC, dark: 0x10233F)
    nonisolated static let grid = CGSize(width: 390, height: 193)

    var body: some View {
        let moving = !motion.reduce
        let stones = Self.stones(count: prepTotal)
        let done = prepDone.map { min(max($0, 0), stones.count) } ?? stones.count
        let onIsland = prepDone == nil || done >= stones.count
        GeometryReader { proxy in
            let k = proxy.size.width / Self.grid.width
            // Xero's feet sit at y 190 of his 200-point drawing; 64 points wide on the grid.
            let feet = onIsland ? CGPoint(x: 346, y: 91) : CGPoint(x: stones[done].x, y: stones[done].y + 2)
            ZStack(alignment: .topLeading) {
                TimelineView(.animation(paused: !moving)) { timeline in
                    let time = moving ? timeline.date.timeIntervalSinceReferenceDate : 0
                    Canvas { context, size in
                        context.scaleBy(x: size.width / Self.grid.width, y: size.width / Self.grid.width)
                        Self.draw(&context, time: time, stones: stones, done: done, allDone: onIsland, sunX: onIsland ? 264 : 338)
                    }
                }
                XeroView(mood: .hello, stage: stage, points: 64 * k)
                    .position(x: feet.x * k, y: (feet.y - 61 + 32) * k)
                Text(verbatim: chip)
                    .dxType(.caption)
                    .foregroundStyle(DX.Fill.navy)
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(DX.Fill.cream, in: Capsule())
                    .shadow(color: Color(hex: 0x0F6E43).opacity(0.12), radius: 9, y: 6)
                    .frame(maxWidth: 230 * k, alignment: .leading)
                    .offset(x: 16 * k, y: 52 * k)
                    .dxArrive(1)
            }
        }
        .aspectRatio(Self.grid.width / Self.grid.height, contentMode: .fit)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 36, bottomTrailingRadius: 36, topTrailingRadius: 0,
                                          style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: chip))
    }

    /// The stones' centres on the grid: a zigzag from the near shore up to the island.
    nonisolated static func stones(count: Int) -> [CGPoint] {
        let n = max(count, 1)
        return (0..<n).map { i in
            let f = n == 1 ? 0.5 : Double(i) / Double(n - 1)
            return CGPoint(x: 38 + 258 * f, y: 161 - 56 * f + (i.isMultiple(of: 2) ? 6 : -6))
        }
    }

    // MARK: Drawing

    private nonisolated static let island = CGPoint(x: 318, y: 89)

    /// 0 → 1 → 0 over `period`, eased at both ends (CSS ease-in-out, there and back).
    nonisolated static func swing(_ time: Double, _ period: Double, delay: Double = 0) -> Double {
        0.5 - 0.5 * cos(2 * .pi * (time - delay) / period)
    }

    private nonisolated static func draw(_ ctx: inout GraphicsContext, time t: Double, stones: [CGPoint], done: Int, allDone: Bool, sunX: Double) {
        let cream = Color(hex: 0xFFF8EE), green = Color(hex: 0x0F6E43), coral = Color(hex: 0xFF7A55)

        sun(&ctx, x: sunX, y: 32, radius: 19.5, time: t)
        // Clouds: 24 pt either way, 7 s and 9 s a pass, in opposite directions.
        cloud(&ctx, x: 30 + 24 * (2 * swing(t, 14) - 1), y: 22, scale: 74.0 / 70, color: cloudWhite)
        cloud(&ctx, x: 176 - 24 * (2 * swing(t, 18) - 1), y: 8, scale: 50.0 / 70, color: cloudWhite)
        islandAndFlag(&ctx, at: island, halfWidth: 60, time: t)

        // Water: two bands drifting left, 390 pt every 18 s and every 10 s.
        ctx.fill(water(top: 97, amplitude: 6, wavelength: 130, shift: t / 18 * 390), with: .color(backWater))
        ctx.fill(water(top: 164, amplitude: 7, wavelength: 195, shift: t / 10 * 390), with: .color(Color(light: 0x9FE3BC, dark: 0x165C40)))

        // The path: solid where it's been walked, dotted ahead.
        let walked = Array(stones.prefix(max(done, 1))) + (allDone ? [island] : [])
        if !allDone {
            let ahead = Array(stones.suffix(from: max(done - 1, 0))) + [island]
            ctx.stroke(polyline(ahead), with: .color(cream), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [2, 8]))
        }
        if walked.count > 1 {
            ctx.stroke(polyline(walked), with: .color(green.opacity(0.55)), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
        }

        // Stones: each floats 2 pt on a 3 s cycle, 0.35 s behind the one before.
        for (i, stone) in stones.enumerated() {
            let isDone = i < done, isCurrent = i == done && !allDone
            let p = (x: Double(stone.x), y: Double(stone.y))
            let y = p.y + 2 * swing(t, 3, delay: Double(i) * 0.35)
            if isCurrent {
                // A coral ring that grows from 0.85 to 1.8 and fades, every 1.8 s.
                let f = (t / 1.8).truncatingRemainder(dividingBy: 1)
                let eased = 1 - pow(1 - f, 2)
                let s = 0.85 + 0.95 * eased
                ctx.stroke(ellipse(p.x, y, 22 * s, 8 * s), with: .color(coral.opacity(0.9 * (1 - eased))), lineWidth: 2)
            }
            let edge: Color = isDone ? Color(hex: 0x0B5634) : isCurrent ? Color(hex: 0xD9572F) : green.opacity(0.18)
            let fill: Color = isDone ? cream : isCurrent ? coral : .white.opacity(0.55)
            let border: Color = isDone ? green : isCurrent ? cream : .white.opacity(0.8)
            ctx.fill(ellipse(p.x, y + 3, 22, 8), with: .color(edge))
            ctx.fill(ellipse(p.x, y, 22, 8), with: .color(fill))
            ctx.stroke(ellipse(p.x, y, 21, 7), with: .color(border), lineWidth: 2)
            if isDone {
                var tick = Path()
                tick.move(to: CGPoint(x: p.x - 3.2, y: y))
                tick.addLine(to: CGPoint(x: p.x - 0.9, y: y + 2.3))
                tick.addLine(to: CGPoint(x: p.x + 3.2, y: y - 2.3))
                ctx.stroke(tick, with: .color(green), style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
            }
        }
    }

    nonisolated static let cloudWhite = Color(light: (0xFFFFFF, 1), dark: (0xFFFFFF, 0.35))
    nonisolated static let backWater = Color(light: 0xB5EBCB, dark: 0x1C4B3C)

    /// The sun: bobs 5 pt over 4 s, inside a dashed ring.
    nonisolated static func sun(_ ctx: inout GraphicsContext, x: Double, y: Double, radius: Double, time t: Double) {
        let yellow = Color(hex: 0xFFD966)
        let cy = y - 5 * swing(t, 4)
        ctx.fill(circle(x, cy, radius), with: .color(yellow))
        ctx.stroke(circle(x, cy, radius * 1.25), with: .color(yellow), style: StrokeStyle(lineWidth: 1.6, lineCap: .butt, dash: [2.4, 4.9]))
    }

    /// The Quit Day island: sand, a pole, a coral flag that flutters (skew -9° and squeeze to 85% from the pole, every
    /// 1.6 s) and two twinkles. `at` is the centre of the sand.
    nonisolated static func islandAndFlag(_ ctx: inout GraphicsContext, at c: CGPoint, halfWidth: Double, time t: Double) {
        let k = halfWidth / 60
        let cx = Double(c.x), cy = Double(c.y)
        ctx.fill(ellipse(cx, cy, halfWidth, 10 * k), with: .color(Color(light: 0xFFE3B8, dark: 0xB89766)))
        let poleX = cx - 6 * k
        var pole = Path()
        pole.move(to: CGPoint(x: poleX, y: cy - 42 * k))
        pole.addLine(to: CGPoint(x: poleX, y: cy - 2 * k))
        ctx.stroke(pole, with: .color(Color(light: 0x1E1A3A, dark: 0xFFF8EE)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        let flutter = swing(t, 1.6)
        var flag = ctx
        flag.translateBy(x: poleX + 1, y: cy - 41 * k)
        flag.concatenate(CGAffineTransform(a: 1 - 0.15 * flutter, b: tan(-9 * .pi / 180) * flutter, c: 0, d: 1, tx: 0, ty: 0))
        var pennant = Path()
        pennant.move(to: .zero)
        pennant.addLine(to: CGPoint(x: 25 * k, y: 7 * k))
        pennant.addLine(to: CGPoint(x: 0, y: 15 * k))
        pennant.closeSubpath()
        flag.fill(pennant, with: .color(Color(hex: 0xFF7A55)))
        twinkle(&ctx, x: cx - 40 * k, y: cy - 15 * k, size: 7 * k, phase: swing(t, 1.8), color: Color(hex: 0xFFD966))
        twinkle(&ctx, x: cx + 43 * k, y: cy - 18 * k, size: 5.5 * k, phase: swing(t, 2.2, delay: 0.6), color: .white)
    }

    nonisolated static func circle(_ x: Double, _ y: Double, _ r: Double) -> Path {
        ellipse(x, y, r, r)
    }

    nonisolated static func ellipse(_ x: Double, _ y: Double, _ rx: Double, _ ry: Double) -> Path {
        Path(ellipseIn: CGRect(x: x - rx, y: y - ry, width: 2 * rx, height: 2 * ry))
    }

    nonisolated static func polyline(_ points: [CGPoint]) -> Path {
        var path = Path()
        path.addLines(points)
        return path
    }

    /// A band of water from a sine-waved top edge down past the bottom of the scene.
    nonisolated static func water(top: Double, amplitude: Double, wavelength: Double, shift: Double, bottom: Double = 193) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: bottom + 20))
        var x = 0.0
        while x <= grid.width + 4 {
            path.addLine(to: CGPoint(x: x, y: top - amplitude * sin(2 * .pi * (x + shift) / wavelength)))
            x += 4
        }
        path.addLine(to: CGPoint(x: grid.width + 4, y: bottom + 20))
        path.closeSubpath()
        return path
    }

    /// The mockup's cloud, drawn on its own 70 × 24 grid.
    nonisolated static func cloud(_ ctx: inout GraphicsContext, x: Double, y: Double, scale: Double, color: Color) {
        var g = ctx
        g.translateBy(x: x, y: y)
        g.scaleBy(x: scale, y: scale)
        var path = Path(roundedRect: CGRect(x: 4, y: 12, width: 62, height: 10), cornerRadius: 5)
        path.addEllipse(in: CGRect(x: 6, y: 8, width: 20, height: 14))
        path.addEllipse(in: CGRect(x: 22, y: 0, width: 30, height: 22))
        path.addEllipse(in: CGRect(x: 42, y: 5, width: 22, height: 17))
        g.fill(path, with: .color(color))
    }

    /// A four-point star that swells from half size and brightens.
    nonisolated static func twinkle(_ ctx: inout GraphicsContext, x: Double, y: Double, size: Double, phase: Double, color: Color) {
        var g = ctx
        g.translateBy(x: x, y: y)
        let s = size * (0.5 + 0.5 * phase)
        var star = Path()
        star.move(to: CGPoint(x: 0, y: -s))
        star.addQuadCurve(to: CGPoint(x: s, y: 0), control: .zero)
        star.addQuadCurve(to: CGPoint(x: 0, y: s), control: .zero)
        star.addQuadCurve(to: CGPoint(x: -s, y: 0), control: .zero)
        star.addQuadCurve(to: CGPoint(x: 0, y: -s), control: .zero)
        g.fill(star, with: .color(color.opacity(0.3 + 0.7 * phase)))
    }
}

/// Grows in once, when it first appears: from a scale (and, with `fades`, from clear) to rest. Used for the bars,
/// the heat map's cells and the reached milestones. With Reduce Motion it shows at rest.
struct GrowIn: ViewModifier {
    var x: CGFloat = 1
    var y: CGFloat = 1
    var anchor: UnitPoint = .center
    var fades = false
    var animation: Animation = DX.Move.settle
    var delay: Double = 0
    @State private var shown = false
    private let motion = MotionPolicy()

    func body(content: Content) -> some View {
        let rest = shown || motion.reduce
        content
            .scaleEffect(x: rest ? 1 : x, y: rest ? 1 : y, anchor: anchor)
            .opacity(shown || !fades ? 1 : 0)
            .onAppear {
                guard !shown else { return }
                withAnimation(motion.animation(animation).delay(motion.reduce ? 0 : delay)) { shown = true }
            }
    }
}

extension View {
    /// The mockup's "pop": from 50% and clear, with a small overshoot, in 0.35 s.
    func dxPopIn(delay: Double = 0, from scale: CGFloat = 0.5) -> some View {
        modifier(GrowIn(x: scale, y: scale, fades: true, animation: .timingCurve(0.3, 1.5, 0.5, 1, duration: 0.35), delay: delay))
    }

    /// A bar growing to its value from one edge.
    func dxGrowIn(from anchor: UnitPoint, delay: Double = 0) -> some View {
        modifier(GrowIn(x: anchor == .leading ? 0.001 : 1, y: anchor == .bottom ? 0.001 : 1, anchor: anchor, delay: delay))
    }
}

/// The soft coral glow that breathes round the day's main button (the mockup's `glow`): out to 9 pt and gone, then
/// back, every 2 s. Off with Reduce Motion.
struct GlowPulse: ViewModifier {
    @State private var out = false
    private let motion = MotionPolicy()

    func body(content: Content) -> some View {
        content
            .background {
                Capsule()
                    .stroke(Color(hex: 0xFF7A55).opacity(motion.reduce ? 0 : out ? 0 : 0.45), lineWidth: out ? 18 : 0)
                    .accessibilityHidden(true)
            }
            .onAppear {
                guard !motion.reduce, !out else { return }
                withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) { out = true }
            }
    }
}

/// The ring that pulses round "next": grows from 0.85 to 1.8 and fades, every 1.8 s. Still with Reduce Motion.
struct PulseRing: View {
    var color = Color(hex: 0xFF7A55)
    @State private var out = false
    private let motion = MotionPolicy()

    var body: some View {
        Ellipse()
            .strokeBorder(color, lineWidth: 2)
            .scaleEffect(out ? 1.8 : 0.85)
            .opacity(motion.reduce ? 0 : out ? 0 : 0.9)
            .onAppear {
                guard !motion.reduce else { return }
                withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) { out = true }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
