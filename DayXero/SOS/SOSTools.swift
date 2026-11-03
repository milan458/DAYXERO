import AVFoundation
import DayXeroCore
import SwiftUI

// Jelli's SOS as an intervention (2 Nov 2026): breathing first (CHAR-01), then something for the hands (CHAR-02),
// then sensory tricks (CHAR-03).

// MARK: CHAR-01 Physiological sigh

/// The opening 30 seconds: three physiological sighs. Jelli swells on the breath in, swells a little more on the
/// second sip and settles on the long breath out; one subtitle line fades from cue to cue, the voice says the same
/// words, and a Core Haptics ramp runs under each phase. All four follow one schedule (`SOSSigh`), so they stay in step.
struct SOSSighIntro: View {
    let stage: Int
    let onFinished: () -> Void

    private let motion = MotionPolicy()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("dx.sosHaptics") private var hapticsOn = true
    @AppStorage("dx.voiceGuidance") private var voiceOn = true
    @State private var phase: BreathPhase?
    @State private var cycle = 1
    @State private var scale = SOSSigh.scale(after: .exhale)
    @State private var haptics = OrbHaptics()
    @State private var voice = CueVoice()
    @State private var shown = false

    private let pattern = OrbData.bundled.pattern(SOSSigh.patternId)

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(SOSColors.glow)
                    .frame(width: 230, height: 230)
                    .scaleEffect(motion.breathes ? scale : 1)
                JelliView(mood: .breathe, stage: stage, size: .hero)
                    .scaleEffect(motion.breathes ? scale : 1)
                    .opacity(shown ? 1 : 0)
            }
            .frame(height: 250)
            .accessibilityHidden(true)
            // One fading subtitle line, synced to the voice: no box, no pill. Only the words cross-fade on a phase
            // change; on the whole stack, that 0.5 s animation overrode each phase's own length, so Jelli and the glow
            // snapped to size and then sat still (QW2). The three cycle dots read as pager dots, so they went; the
            // count lives in the subtitle's value for VoiceOver.
            ZStack {
                Text(verbatim: phase.map(SOSSigh.cue) ?? String(localized: "Let's breathe together first"))
                    .dxType(.title)
                    .foregroundStyle(SOSColors.cream)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .id(phase.map(SOSSigh.cue) ?? "")
                    .transition(.opacity)
            }
            .frame(maxWidth: .infinity, minHeight: 64)
            .animation(motion.animation(.easeInOut(duration: 0.5)), value: phase)
            .accessibilityElement(children: .combine)
            .accessibilityValue(phase == nil ? Text(verbatim: "") : Text("Sigh \(cycle) of \(SOSSigh.cycles)"))
            .accessibilityAddTraits(.updatesFrequently)
            Button("Skip to riding it out") { finish() }
                .dxFont(14, weight: 600, style: .footnote)
                .foregroundStyle(SOSColors.ocean.muted)
                .frame(minHeight: DX.Layout.touchTarget)
        }
        .task { await run() }
        .onDisappear(perform: tearDown)
        .onChange(of: scenePhase) { _, now in
            // Leaving the app mid-sigh: go straight to riding it out rather than talking to an empty room.
            if now == .background { finish() }
        }
    }

    private func run() async {
        withAnimation(motion.animation(DX.Move.settle)) { shown = true }
        try? await Task.sleep(for: .seconds(0.8))
        for step in SOSSigh.steps(pattern) {
            guard !Task.isCancelled else { return }
            phase = step.phase
            cycle = step.cycle
            withAnimation(.easeInOut(duration: Double(step.seconds))) { scale = SOSSigh.scale(after: step.phase) }
            if hapticsOn { haptics.play(step.phase, pattern: pattern) }
            if SOSSigh.isSpoken(step.phase) {
                let cue = SOSSigh.cue(step.phase)
                // Jelli's voice is part of the full program (MON-01); free, the cue is the subtitle and haptics.
                if VoiceCoaching.speaks(voiceOn) {
                    voice.say(cue)
                } else {
                    AccessibilityNotification.Announcement(cue).post()
                }
            }
            try? await Task.sleep(for: .seconds(Double(step.seconds)))
        }
        guard !Task.isCancelled else { return }
        finish()
    }

    private func finish() {
        tearDown()
        onFinished()
    }

    private func tearDown() {
        voice.stop()
        haptics.stop()
    }
}

/// Says one short cue at a time with on-device speech, ducking other audio. Nothing goes to a server.
@MainActor
final class CueVoice {
    private let synthesizer = AVSpeechSynthesizer()

    func say(_ text: String) {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.44
        utterance.pitchMultiplier = 0.95
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

// MARK: CHAR-02 Hold to feel

/// Something for the hands: hold a finger on the pad and a slow heartbeat pulses under it while bubbles swirl out
/// from the touch and drift up. Moving the finger lifts the pulse and stirs more bubbles. Nothing to win, nothing to
/// finish: a fidget.
struct HoldToFeelPad: View {
    private let motion = MotionPolicy()
    @AppStorage("dx.sosHaptics") private var hapticsOn = true
    @State private var field = BubbleField()
    @State private var haptics = HapticPlayer()
    @State private var touching = false

    var body: some View {
        let still = motion.reduce
        TimelineView(.animation(minimumInterval: 1 / 60)) { timeline in
            Canvas { context, size in
                field.step(now: timeline.date, still: still)
                field.draw(in: &context, now: timeline.date, still: still)
            }
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
        .background(SOSColors.solid, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            VStack(spacing: 4) {
                Image(systemName: "hand.point.up.left.fill").font(.system(size: 22, weight: .semibold))
                Text("Hold to feel").dxFont(16, weight: 700, style: .body)
                Text("Something for your hands").dxType(.footnote).foregroundStyle(SOSColors.ocean.muted)
            }
            .foregroundStyle(SOSColors.cream)
            .opacity(touching ? 0 : 1)
            .animation(.easeOut(duration: 0.3), value: touching)
            .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !touching {
                        touching = true
                        if hapticsOn { haptics.startPulse() }
                    }
                    let speed = field.move(to: value.location, at: .now)
                    if hapticsOn { haptics.setPulse(strength: min(speed / 600, 1)) }
                }
                .onEnded { _ in
                    touching = false
                    field.lift()
                    haptics.stop()
                }
        )
        .onDisappear { haptics.shutDown() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Hold to feel"))
        .accessibilityHint(Text("Touch and hold for a slow pulse and swirling bubbles"))
        .accessibilityAddTraits(.allowsDirectInteraction)
    }
}

/// The pad's bubbles. A plain class, stepped and drawn inside the canvas each frame, so moving bubbles never
/// re-render the view around them.
final class BubbleField {
    struct Bubble {
        let born: Date
        let origin: CGPoint
        let angle: Double
        let spin: Double
        let radius: Double
    }

    private(set) var bubbles: [Bubble] = []
    private var touch: CGPoint?
    private var lastSpawn = Date.distantPast
    private var lastMove: (point: CGPoint, time: Date)?
    static let life = 1.8

    /// Moves the touch; returns its speed in points a second.
    func move(to point: CGPoint, at time: Date) -> Double {
        defer { lastMove = (point, time); touch = point }
        guard let last = lastMove else { return 0 }
        let dt = max(time.timeIntervalSince(last.time), 1 / 120)
        let speed = hypot(point.x - last.point.x, point.y - last.point.y) / dt
        // A quick swipe stirs extra bubbles.
        if speed > 400 { spawn(at: point, now: time) }
        return speed
    }

    func lift() {
        touch = nil
        lastMove = nil
    }

    func step(now: Date, still: Bool) {
        if let touch, now.timeIntervalSince(lastSpawn) > (still ? 0.25 : 0.07) { spawn(at: touch, now: now) }
        bubbles.removeAll { now.timeIntervalSince($0.born) > Self.life }
    }

    private func spawn(at point: CGPoint, now: Date) {
        lastSpawn = now
        guard bubbles.count < 90 else { return }
        bubbles.append(Bubble(born: now, origin: point, angle: .random(in: 0..<(2 * .pi)),
                              spin: .random(in: 1.2...2.6) * (Bool.random() ? 1 : -1), radius: .random(in: 3...9)))
    }

    func draw(in context: inout GraphicsContext, now: Date, still: Bool) {
        for bubble in bubbles {
            let age = now.timeIntervalSince(bubble.born) / Self.life
            let p: CGPoint
            if still {
                p = bubble.origin
            } else {
                // Out in a widening spiral, drifting up as it goes.
                let turn = bubble.angle + bubble.spin * age * 2.2
                let reach = 14 + 60 * age
                p = CGPoint(x: bubble.origin.x + cos(turn) * reach, y: bubble.origin.y + sin(turn) * reach * 0.7 - 50 * age)
            }
            let r = bubble.radius * (0.6 + 0.6 * age)
            let rect = CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)
            let alpha = (1 - age) * 0.85
            context.stroke(Path(ellipseIn: rect), with: .color(SOSColors.cream.opacity(alpha)), lineWidth: 1.4)
            context.fill(Path(ellipseIn: rect.insetBy(dx: r * 0.45, dy: r * 0.45).offsetBy(dx: -r * 0.25, dy: -r * 0.25)),
                         with: .color(SOSColors.cream.opacity(alpha * 0.5)))
        }
    }
}

// MARK: CHAR-03 Sensory tricks

/// One of the sensory tricks: something sharp to feel, taste or pull on while the wave passes.
struct SensoryTrick: Identifiable {
    let id: String
    let systemImage: String
    let title: LocalizedStringKey
    let detail: LocalizedStringKey

    static var all: [SensoryTrick] { [
        SensoryTrick(id: "fizzy", systemImage: "bubbles.and.sparkles",
                     title: "Ice-cold fizzy water through a straw",
                     detail: "The cold and the bubbles give your mouth something sharp to notice."),
        SensoryTrick(id: "candy", systemImage: "circle.hexagongrid",
                     title: "A strong sour or mint sweet",
                     detail: "A big taste crowds the craving out for a few minutes."),
        SensoryTrick(id: "straw", systemImage: "wind",
                     title: "Breathe through a narrow straw",
                     detail: "The pull feels like a draw, with nothing in it. Slow breaths in, long breaths out."),
    ] }
}

/// The row that opens the drawer, under the break menu.
struct SensoryTricksButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles").font(.system(size: 17, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .background(SOSColors.cream.opacity(0.14), in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sensory tricks").dxFont(16, weight: 700, style: .body)
                    Text("Cold, sour, or a straw").dxType(.footnote).foregroundStyle(SOSColors.ocean.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.up").font(.system(size: 13, weight: .bold)).accessibilityHidden(true)
            }
            .foregroundStyle(SOSColors.cream)
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(SOSColors.solid, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("Opens three quick things to try"))
    }
}

/// The drawer: three tricks to try, on the ocean.
struct SensoryTricksSheet: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DX.Space.s) {
            Text("Sensory tricks").dxType(.title).foregroundStyle(SOSColors.cream)
                .accessibilityAddTraits(.isHeader)
            Text("Give your senses something stronger than the craving.")
                .dxType(.body).foregroundStyle(SOSColors.ocean.muted)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(SensoryTrick.all) { trick in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: trick.systemImage).font(.system(size: 18, weight: .semibold))
                        .frame(width: 40, height: 40)
                        .background(SOSColors.cream.opacity(0.14), in: Circle())
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(trick.title).dxFont(16, weight: 700, style: .body)
                        Text(trick.detail).dxType(.footnote).foregroundStyle(SOSColors.ocean.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .foregroundStyle(SOSColors.cream)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SOSColors.solid, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.horizontal, DX.Layout.gutter)
        .padding(.top, DX.Space.xl)
        .padding(.bottom, DX.Space.m)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(SOSColors.ocean.background)
    }
}
