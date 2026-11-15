import DayXeroCore
import SwiftUI

/// The breath pacer (v5): a soft disc that swells on the in-breath and settles on the out-breath inside a still
/// ring, with the phase's words and its seconds in the centre and the breath count under it. It paces any of the
/// breathing patterns (box, 4-7-8, the slow out-breath) and takes the Bio-Orb's place in the Wind down tool and in a
/// session's breathing step.
///
/// Motion: the disc eases between sizes over each phase (still with Reduce Motion, where only the words change);
/// the seconds count down; a light haptic marks each change of phase.
struct BreathPacerPanel: View {
    let pattern: String
    let cycles: Int?
    /// Called when the person taps Continue after the last breath.
    let onFinished: () -> Void

    @State private var started: Date?
    @State private var pausedAt: Double = 0
    @State private var playing = false
    @State private var step = 0
    @Environment(\.dxGround) private var ground
    private let motion = MotionPolicy()

    init(pattern: String, cycles: Int? = nil, onFinished: @escaping () -> Void) {
        self.pattern = pattern
        self.cycles = cycles
        self.onFinished = onFinished
    }

    private var spec: OrbData.Pattern { OrbData.bundled.pattern(pattern) }

    /// The phases that have time in them, in breathing order.
    private var phases: [(phase: BreathPhase, seconds: Double)] {
        BreathPhase.allCases.compactMap { phase in
            let seconds = spec.seconds(phase)
            return seconds > 0 ? (phase, Double(seconds)) : nil
        }
    }

    private var cycle: Double { max(phases.reduce(0) { $0 + $1.seconds }, 1) }
    private var count: Int { max(cycles ?? spec.recommendedCycles, 1) }
    private var total: Double { cycle * Double(count) }

    /// Where the breath is at `elapsed`: which phase, the seconds left in it, and how full the disc is (0.55 to 1).
    private func place(at elapsed: Double) -> (index: Int, phase: BreathPhase, left: Double, fill: Double) {
        let items = phases
        guard !items.isEmpty else { return (0, .inhale, 0, 0.55) }
        let sips = items.contains { $0.phase == .topUp }
        var time = elapsed >= total ? cycle : elapsed.truncatingRemainder(dividingBy: cycle)
        var size = 0.55
        for (i, item) in items.enumerated() {
            let target: Double
            if item.phase == .inhale {
                target = sips ? 0.9 : 1
            } else if item.phase == .topUp {
                target = 1
            } else if item.phase == .exhale {
                target = 0.55
            } else {
                target = size
            }
            if time < item.seconds || i == items.count - 1 {
                let k = min(max(time / item.seconds, 0), 1)
                let eased = k * k * (3 - 2 * k)
                return (i, item.phase, max(item.seconds - time, 0), size + (target - size) * eased)
            }
            time -= item.seconds
            size = target
        }
        return (0, .inhale, 0, 0.55)
    }

    private func words(_ phase: BreathPhase) -> String {
        if phase == .inhale { return String(localized: "Breathe in") }
        if phase == .topUp { return String(localized: "A little more") }
        if phase == .exhale { return String(localized: "Breathe out") }
        return String(localized: "Hold")
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !playing)) { timeline in
            let elapsed = min(playing ? pausedAt + timeline.date.timeIntervalSince(started ?? timeline.date) : pausedAt, total)
            let done = elapsed >= total
            let now = place(at: elapsed)
            let breath = min(Int(elapsed / cycle) + 1, count)
            let waiting = !playing && pausedAt == 0
            VStack(spacing: 18) {
                Text(verbatim: "\(spec.name) · \(spec.counts)").dxType(.caption).foregroundStyle(ground.muted)
                ZStack {
                    Circle().strokeBorder(ground.track, lineWidth: 6)
                    Circle().fill(ground.selTint)
                        .overlay(Circle().strokeBorder(ground.selEdge.opacity(0.35), lineWidth: 2))
                        .scaleEffect(motion.reduce ? 0.8 : now.fill)
                    VStack(spacing: 2) {
                        Text(verbatim: done ? String(localized: "Nicely done") : waiting ? String(localized: "Ready when you are") : words(now.phase))
                            .dxType(.headline).foregroundStyle(ground.ink)
                            .multilineTextAlignment(.center)
                        if !done, !waiting {
                            Text(verbatim: "\(Int(now.left.rounded(.up)))")
                                .dxFace(.display, 34, weight: 700).monospacedDigit()
                                .foregroundStyle(ground.ink)
                        }
                    }
                    .padding(.horizontal, 36)
                }
                .frame(width: 240, height: 240)
                .accessibilityElement(children: .combine)
                Text(verbatim: done ? String(localized: "\(count) of \(count) breaths") : String(localized: "Breath \(breath) of \(count)"))
                    .dxType(.footnote).foregroundStyle(ground.muted)
                controls(done: done)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DX.Space.m)
            .onChange(of: now.index) { _, index in step = index }
            .onChange(of: done) { _, finished in
                if finished {
                    playing = false
                    pausedAt = total
                }
            }
        }
        .sensoryFeedback(.impact(weight: .light, intensity: 0.6), trigger: step)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .onDisappear { playing = false }
    }

    @ViewBuilder
    private func controls(done: Bool) -> some View {
        if done {
            VStack(spacing: 8) {
                Button(String(localized: "Continue"), action: onFinished)
                    .buttonStyle(.dx(.primary, on: ground))
                Button(String(localized: "Again")) {
                    pausedAt = 0
                    started = .now
                    playing = true
                }
                .buttonStyle(.dx(.quiet, on: ground))
            }
        } else {
            Button(playing ? String(localized: "Pause") : pausedAt > 0 ? String(localized: "Resume") : String(localized: "Start"), action: toggle)
                .buttonStyle(.dx(.primary, on: ground))
        }
    }

    private func toggle() {
        if playing {
            pausedAt = min(pausedAt + Date.now.timeIntervalSince(started ?? .now), total)
            playing = false
        } else {
            started = .now
            playing = true
        }
    }
}
