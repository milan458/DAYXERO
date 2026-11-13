import SwiftUI

/// The kit progress ring (kit.js `ring`): a track and an arc from 12 o'clock that sweeps from empty to `p` on
/// appear (1.4 s settle curve after 250 ms), with an optional white dot on the arc's end that fades in at 900 ms.
public struct DXRing: View {
    let p: Double
    let size: CGFloat
    let stroke: CGFloat
    let color: Color?
    let track: Color?
    let dot: Bool
    @State private var shown = false
    @Environment(\.dxGround) private var ground
    private let motion = MotionPolicy()

    public init(p: Double, size: CGFloat = 220, stroke: CGFloat = 14, color: Color? = nil, track: Color? = nil, dot: Bool = false) {
        self.p = min(1, max(0, p))
        self.size = size
        self.stroke = stroke
        self.color = color
        self.track = track
        self.dot = dot
    }

    public var body: some View {
        let arc = color ?? ground.resolved.ink
        let value = shown || motion.reduce ? p : 0
        ZStack {
            Circle().stroke(track ?? ground.resolved.track, lineWidth: stroke)
            Circle()
                .trim(from: 0, to: value)
                .stroke(arc, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if dot {
                let r = (size - stroke) / 2
                let a = 2 * Double.pi * p - .pi / 2
                Circle()
                    .fill(.white)
                    .overlay(Circle().strokeBorder(arc, lineWidth: stroke * 0.35))
                    .frame(width: stroke * 1.5, height: stroke * 1.5)
                    .offset(x: r * cos(a), y: r * sin(a))
                    .opacity(shown || motion.reduce ? 1 : 0)
                    .animation(motion.animation(DX.Move.fade.delay(0.9)), value: shown)
            }
        }
        .padding(stroke / 2)
        .frame(width: size, height: size)
        .onAppear {
            guard !shown else { return }
            withAnimation(motion.animation(DX.Move.ring)) { shown = true }
        }
        .accessibilityElement()
        .accessibilityValue(Text("\(Int((p * 100).rounded())) percent"))
    }
}

/// The completion check (kit.js `check`): the disc pops (or fades, `calm`), then the tick draws 320 ms later.
public struct DXCheck: View {
    let size: CGFloat
    let color: Color
    let tick: Color
    let calm: Bool
    let delay: Double
    @State private var disc = false
    @State private var drawn = false
    private let motion = MotionPolicy()

    public init(size: CGFloat = 96, color: Color = DX.Fill.done, tick: Color = .white, calm: Bool = false, delay: Double = 0) {
        self.size = size
        self.color = color
        self.tick = tick
        self.calm = calm
        self.delay = delay
    }

    public var body: some View {
        let s = size / 100
        ZStack {
            Circle().fill(color)
                .frame(width: 92 * s, height: 92 * s)
                .scaleEffect(disc || calm || motion.reduce ? 1 : 0.4)
                .rotationEffect(.degrees(disc || calm || motion.reduce ? 0 : -8))
                .opacity(disc ? 1 : 0)
            CheckTick()
                .trim(from: 0, to: drawn ? 1 : 0)
                .stroke(tick, style: StrokeStyle(lineWidth: 9 * s, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
        .onAppear {
            if motion.reduce { disc = true; drawn = true; return }
            withAnimation((calm ? DX.Move.fade : DX.Move.pop).delay(delay)) { disc = true }
            withAnimation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.42).delay(delay + 0.32)) { drawn = true }
        }
        .accessibilityElement()
        .accessibilityLabel(Text("Done"))
    }
}

/// The tick `M30 52l13 13 28-30` in a 100 × 100 box.
struct CheckTick: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 100
        var p = Path()
        p.move(to: CGPoint(x: 30 * s, y: 52 * s))
        p.addLine(to: CGPoint(x: 43 * s, y: 65 * s))
        p.addLine(to: CGPoint(x: 71 * s, y: 35 * s))
        return p.offsetBy(dx: rect.minX, dy: rect.minY)
    }
}
