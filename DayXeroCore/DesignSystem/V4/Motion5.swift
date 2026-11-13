import SwiftUI

/// v5 motion modifiers (kit.css "motion"). Each plays once on appear; with Reduce Motion (or `.dxReduceMotion(true)`)
/// each renders its final state with at most the short reduced fade. Ambient loops (bob, breathe) stand still.
///
/// - `dxArrive(i)`: rise 18 pt and fade, 600 ms, 90 ms stagger (Move.swift).
/// - `dxSettle(i)`: rise 48 pt and fade, 900 ms, 120 ms stagger. Characters entering, plan rows.
/// - `dxPop(i)`: from 0.4 and -8°, spring, 700 ms, 110 ms stagger. Celebrations only.
/// - `dxStamp(i)`: from 1.8× and -14° through 0.92, spring, 620 ms, 140 ms stagger. Badges and stamps.
/// - `dxFade(delay)`: opacity, 700 ms.
/// - `dxBob()`: 6 pt up and back over 5 s, forever.
/// - `dxShine(delay)`: a light sweep across, 1.4 s, once.
/// - `dxBump(trigger)`: 1.18× and back, 520 ms spring, on each change.
/// - `DXFloatUp("+1")`: rises 34 pt and fades over 1.4 s.

private struct EntranceModifier: ViewModifier {
    enum Kind { case settle, pop, stamp, fade }
    let kind: Kind
    let index: Int
    let delay: Double
    @State private var shown = false
    private let motion = MotionPolicy()

    func body(content: Content) -> some View {
        let done = shown || motion.reduce
        content
            .opacity(shown ? 1 : 0)
            .offset(y: kind == .settle && !done ? DX.Move.settleRise : 0)
            .scaleEffect(done ? 1 : kind == .pop ? 0.4 : kind == .stamp ? 1.8 : 1)
            .rotationEffect(.degrees(done ? 0 : kind == .pop ? -8 : kind == .stamp ? -14 : 0))
            .onAppear {
                guard !shown else { return }
                if motion.reduce {
                    withAnimation(DX.Move.reduced) { shown = true }
                    return
                }
                let start = delay + Double(index) * stagger
                withAnimation(animation.delay(start)) { shown = true }
            }
    }

    private var stagger: Double {
        switch kind {
        case .settle: DX.Move.settleStagger
        case .pop: DX.Move.popStagger
        case .stamp: DX.Move.stampStagger
        case .fade: 0
        }
    }

    private var animation: Animation {
        switch kind {
        case .settle: DX.Move.settle
        case .pop: DX.Move.pop
        // The stamp lands past 1 (0.92 at 55%) and settles: a firm spring gives the same beat.
        case .stamp: .spring(response: DX.Move.stamp * 0.75, dampingFraction: 0.55)
        case .fade: DX.Move.fade
        }
    }
}

/// Arrive with an extra delay (kit `--d`).
private struct ArriveDelayModifier: ViewModifier {
    let index: Int
    let delay: Double
    @State private var shown = false
    private let motion = MotionPolicy()

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || motion.reduce ? 0 : DX.Move.arriveRise)
            .onAppear {
                guard !shown else { return }
                let animation = motion.animation(DX.Move.arrive)
                withAnimation(animation.delay(motion.reduce ? 0 : delay + Double(index) * DX.Move.arriveStagger)) { shown = true }
            }
    }
}

private struct BobModifier: ViewModifier {
    let amplitude: CGFloat
    let period: Double
    private let motion = MotionPolicy()

    func body(content: Content) -> some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: motion.reduce)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let phase = motion.reduce ? 0 : (1 - cos(2 * .pi * t / period)) / 2
            content.offset(y: -amplitude * phase)
        }
    }
}

private struct ShineModifier: ViewModifier {
    let delay: Double
    @State private var x: CGFloat = -1.2
    private let motion = MotionPolicy()

    func body(content: Content) -> some View {
        content
            .overlay {
                if !motion.reduce {
                    GeometryReader { proxy in
                        LinearGradient(stops: [
                            .init(color: .white.opacity(0), location: 0.4),
                            .init(color: .white.opacity(0.55), location: 0.5),
                            .init(color: .white.opacity(0), location: 0.6),
                        ], startPoint: UnitPoint(x: 0, y: 0.2), endPoint: UnitPoint(x: 1, y: 0.8))
                        .frame(width: proxy.size.width * 1.4, height: proxy.size.height * 1.4)
                        .offset(x: proxy.size.width * x - proxy.size.width * 0.2, y: -proxy.size.height * 0.2)
                    }
                    .mask(content)
                    .allowsHitTesting(false)
                }
            }
            .onAppear {
                guard !motion.reduce else { return }
                withAnimation(.timingCurve(0.2, 0.7, 0.2, 1, duration: DX.Move.shine).delay(delay)) { x = 1.2 }
            }
    }
}

private struct BumpModifier<T: Equatable>: ViewModifier {
    let trigger: T
    private let motion = MotionPolicy()

    func body(content: Content) -> some View {
        content.phaseAnimator([1.0, 1.18, 1.0], trigger: trigger) { view, scale in
            view.scaleEffect(motion.reduce ? 1 : scale)
        } animation: { scale in
            scale == 1.18 ? .timingCurve(0.3, 1.4, 0.5, 1, duration: DX.Move.bump * 0.4)
                : .timingCurve(0.3, 1.4, 0.5, 1, duration: DX.Move.bump * 0.6)
        }
    }
}

public extension View {
    func dxArrive(_ index: Int, delay: Double) -> some View {
        modifier(ArriveDelayModifier(index: index, delay: delay))
    }

    func dxSettle(_ index: Int = 0, delay: Double = 0) -> some View {
        modifier(EntranceModifier(kind: .settle, index: index, delay: delay))
    }

    func dxPop(_ index: Int = 0, delay: Double = 0) -> some View {
        modifier(EntranceModifier(kind: .pop, index: index, delay: delay))
    }

    func dxStamp(_ index: Int = 0, delay: Double = 0) -> some View {
        modifier(EntranceModifier(kind: .stamp, index: index, delay: delay))
    }

    func dxFade(delay: Double = 0) -> some View {
        modifier(EntranceModifier(kind: .fade, index: 0, delay: delay))
    }

    func dxBob(_ amplitude: CGFloat = DX.Move.bobRise, period: Double = DX.Move.bob) -> some View {
        modifier(BobModifier(amplitude: amplitude, period: period))
    }

    func dxShine(delay: Double = 0.6) -> some View {
        modifier(ShineModifier(delay: delay))
    }

    func dxBump<T: Equatable>(_ trigger: T) -> some View {
        modifier(BumpModifier(trigger: trigger))
    }
}

/// A small "+1" that floats up 34 pt and fades (kit `.float-up`), once each time `trigger` changes. Hidden with
/// Reduce Motion: the number itself carries the change.
public struct DXFloatUp<T: Equatable>: View {
    let text: String
    let trigger: T
    let delay: Double
    @State private var run = 0
    private let motion = MotionPolicy()

    public init(_ text: String, trigger: T, delay: Double = 0) {
        self.text = text
        self.trigger = trigger
        self.delay = delay
    }

    public var body: some View {
        Text(verbatim: text)
            .dxFace(.display, 17, weight: 800)
            .foregroundStyle(DX.Fill.green)
            .keyframeAnimator(initialValue: FloatFrame(), trigger: run) { view, f in
                view.opacity(f.opacity).scaleEffect(f.scale).offset(y: f.y)
            } keyframes: { _ in
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(0, duration: delay)
                    LinearKeyframe(1, duration: 0.28)
                    LinearKeyframe(1, duration: 0.7)
                    LinearKeyframe(0, duration: 0.42)
                }
                KeyframeTrack(\.y) {
                    LinearKeyframe(8, duration: delay)
                    CubicKeyframe(0, duration: 0.28)
                    CubicKeyframe(-34, duration: 1.12)
                }
                KeyframeTrack(\.scale) {
                    LinearKeyframe(0.8, duration: delay)
                    CubicKeyframe(1.05, duration: 0.28)
                    CubicKeyframe(1, duration: 1.12)
                }
            }
            .opacity(motion.reduce || run == 0 ? 0 : 1)
            .onAppear { if !motion.reduce { run += 1 } }
            .onChange(of: trigger) { if !motion.reduce { run += 1 } }
            .accessibilityHidden(true)
    }
}

struct FloatFrame {
    var opacity: Double = 0
    var y: CGFloat = 8
    var scale: CGFloat = 0.8
}
