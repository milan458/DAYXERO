import DayXeroCore
import SwiftUI

/// A breathing exercise on the Bio-Orb for the stress toolkit (S12.4): Start, then Pause or Resume and Coach me,
/// ending after the pattern's recommended cycles with Continue or Again.
struct OrbBreathingPanel: View {
    let pattern: String
    /// Called when the person taps Continue after the last cycle.
    let onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("dx.sosHaptics") private var hapticsOn = true
    @AppStorage("dx.voiceGuidance") private var voiceOn = true
    @State private var engine: OrbEngine
    @State private var clock = OrbClock()
    @State private var coach = OrbCoach()
    @State private var haptics = OrbHaptics()
    @State private var started = false
    @State private var paused = false
    @State private var finished = false

    init(pattern: String, onFinished: @escaping () -> Void) {
        self.pattern = pattern
        self.onFinished = onFinished
        _engine = State(initialValue: OrbEngine(mode: .breathing, pattern: pattern))
    }

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 24) {
                    Text(verbatim: "\(engine.pattern.name) · \(engine.pattern.counts)").dxText(.micro)
                        .padding(.top, DX.Space.s)
                    BioOrbView(engine: engine, side: BioOrbView.side(mini: false, available: geo.size.width), onTap: coachMe)
                    OrbCaption(engine: engine)
                    controls
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, DX.Space.m)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(Color.black.ignoresSafeArea())
        // The orb is specified for a black canvas; keep this part dark even in light mode.
        .environment(\.colorScheme, .dark)
        .onAppear(perform: appear)
        .onDisappear(perform: tearDown)
        .onChange(of: scenePhase) { _, phase in
            if phase == .background, started, !finished { pause() }
        }
    }

    @ViewBuilder
    private var controls: some View {
        let labels = engine.data.labels
        ViewThatFits {
            HStack(spacing: 10) { primaryButton(labels); secondaryButton(labels) }
            VStack(spacing: 10) { primaryButton(labels); secondaryButton(labels) }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    @ViewBuilder
    private func primaryButton(_ labels: OrbData.Labels) -> some View {
        if finished {
            Button(action: onFinished) { Label("Continue", systemImage: "checkmark") }
                .buttonStyle(OrbPanelButtonStyle(kind: .porcelain))
        } else if !started {
            Button(action: start) { Label(labels.start, systemImage: "play.fill") }
                .buttonStyle(OrbPanelButtonStyle(kind: .porcelain))
        } else {
            Button {
                if paused { resume() } else { pause() }
            } label: {
                Label(paused ? labels.resume : labels.pause, systemImage: paused ? "play.fill" : "pause.fill")
            }
            .buttonStyle(OrbPanelButtonStyle(kind: .porcelain))
        }
    }

    @ViewBuilder
    private func secondaryButton(_ labels: OrbData.Labels) -> some View {
        if finished {
            Button(action: again) { Label("Again", systemImage: "arrow.counterclockwise") }
                .buttonStyle(OrbPanelButtonStyle(kind: .moss))
        } else {
            Button(action: coachMe) { Label(labels.coachButton, systemImage: "waveform") }
                .buttonStyle(OrbPanelButtonStyle(kind: .moss))
        }
    }

    // MARK: Flow

    private func appear() {
        wire(engine)
        #if DEBUG
        let elapsed = UserDefaults.standard.integer(forKey: "dx.calmElapsed")
        if elapsed > 0 {
            start()
            engine.skip(seconds: elapsed)
        }
        #endif
    }

    private func wire(_ engine: OrbEngine) {
        clock.attach(engine, reduceMotion: reduceMotion)
        coach.attach(engine)
        engine.onEvent = { event in
            switch event {
            case let .phaseChanged(phase):
                if hapticsOn { haptics.play(phase, pattern: engine.pattern) }
                AccessibilityNotification.Announcement(
                    String(localized: "\(String(localized: String.LocalizationValue(phase.rawValue))), \(engine.pattern.seconds(phase)) seconds")).post()
            case let .coach(trigger):
                if let line = engine.data.coachingLine(trigger: trigger) { coach.play(line, voice: voiceOn) }
            case .finished:
                coach.stop()
                haptics.stop()
                finished = true
            }
        }
    }

    private func start() {
        started = true
        paused = false
        engine.start()
        // The first phase starts now, so its haptic does too.
        if hapticsOn { haptics.play(.inhale, pattern: engine.pattern) }
    }

    private func pause() {
        paused = true
        engine.pause()
        coach.stop()
        haptics.stop()
    }

    private func resume() {
        paused = false
        engine.start()
    }

    private func again() {
        let next = OrbEngine(mode: .breathing, pattern: pattern)
        engine.onEvent = nil
        engine = next
        wire(next)
        finished = false
        start()
    }

    private func coachMe() {
        coach.play(engine.nextLine(), voice: voiceOn)
    }

    private func tearDown() {
        coach.stop()
        haptics.stop()
        clock.stop()
        engine.pause()
    }
}

/// Porcelain for the main action, moss for the second, as on the SOS screen.
struct OrbPanelButtonStyle: ButtonStyle {
    enum Kind { case porcelain, moss }
    let kind: Kind

    func makeBody(configuration: Configuration) -> some View {
        let tokens = OrbData.bundled.tokens
        return configuration.label
            .labelStyle(OrbPanelLabel())
            .font(.custom(DX.Typeface.bold, size: 13, relativeTo: .subheadline))
            .foregroundStyle(kind == .porcelain ? Color.black : Color(orbHex: tokens.sage))
            .padding(.vertical, 14).padding(.horizontal, 20)
            .background(kind == .porcelain ? Color(orbHex: tokens.porcelain) : Color(orbHex: tokens.moss), in: Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

private struct OrbPanelLabel: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon.font(.system(size: 12, weight: .bold))
            configuration.title
        }
    }
}
