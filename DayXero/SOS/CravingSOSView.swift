import DayXeroCore
import SwiftData
import SwiftUI
import UIKit

/// Craving SOS (S6.1–S6.3, S6.9): three minutes riding the urge with the Bio-Orb, then how it went.
/// Opens straight into the session, with nothing to load first.
struct CravingSOSView: View {
    /// nil before onboarding is finished; the session still works.
    let profile: UserProfile?
    let source: String
    let onClose: () -> Void

    enum Stage: String {
        case session, timeUp, passed, slipped
    }

    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("dx.sosHaptics") private var hapticsOn = true
    @AppStorage("dx.voiceGuidance") private var voiceOn = true
    /// The breathing pattern, wave riding unless the person picks another (spec §5).
    @AppStorage("dx.sosPattern") private var patternID = OrbData.bundled.sos.defaultPattern
    @Query(filter: #Predicate<LogEntry> { $0.kindRaw == "craving" }) private var cravings: [LogEntry]

    @State private var startedAt: Date
    @State private var stage = Stage.session
    @State private var began = false
    @State private var engine: OrbEngine
    @State private var clock = OrbClock()
    @State private var coach = OrbCoach()
    @State private var haptics = OrbHaptics()
    /// Paused by the person, or because the app left the foreground; Resume carries on.
    @State private var paused = false
    @State private var celebrate = false
    @State private var slipFeedback = false
    @State private var trigger: Trigger?
    @State private var strength = 5
    @State private var strengthTouched = false
    @State private var showCalmTools = false

    init(profile: UserProfile?, source: String, onClose: @escaping () -> Void) {
        self.profile = profile
        self.source = source
        self.onClose = onClose
        let pattern = UserDefaults.standard.string(forKey: "dx.sosPattern") ?? OrbData.bundled.sos.defaultPattern
        let engine = OrbEngine(mode: .sos(seconds: OrbData.bundled.sos.sessionSeconds), pattern: pattern)
        var start = Date.now
        #if DEBUG
        let elapsed = UserDefaults.standard.integer(forKey: "dx.sosElapsed")
        start = start.addingTimeInterval(-Double(elapsed))
        engine.skip(seconds: elapsed)
        #endif
        _engine = State(initialValue: engine)
        _startedAt = State(initialValue: start)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            switch stage {
            case .session, .timeUp: sessionView
            case .passed: passedView
            case .slipped: slippedView
            }
        }
        // The orb is specified for a pure black canvas, so the whole SOS stays dark.
        .preferredColorScheme(.dark)
        .onAppear(perform: begin)
        .onDisappear(perform: tearDown)
        .onChange(of: scenePhase) { _, phase in
            // "It passed" on the Lock Screen already saved the craving; show the same screen as in the app.
            if phase == .active, SOSState.consumeFinishedOutside() == .passed, stage == .session || stage == .timeUp {
                tearDown()
                stage = .passed
            } else if phase == .background, stage == .session {
                // Only a real background pauses: pulling down Control Center or a notification shouldn't.
                pause()
            }
        }
        .onChange(of: hapticsOn) { _, on in if !on { haptics.stop() } }
        .fullScreenCover(isPresented: $showCalmTools) {
            CalmToolsView(onClose: { showCalmTools = false }, fromSOS: true)
        }
        .sensoryFeedback(DX.Haptic.commit, trigger: celebrate)
        .sensoryFeedback(DX.Haptic.gentle, trigger: slipFeedback)
    }

    // MARK: Session

    private var sessionView: some View {
        VStack(spacing: 0) {
            topBar(stage == .timeUp ? "Three minutes done" : "Riding it out")
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 24) {
                        BioOrbView(engine: engine, side: BioOrbView.side(mini: false, available: geo.size.width), onTap: coachMe)
                            .padding(.top, DX.Space.l)
                        OrbTranscriptPill(engine: engine)
                        if stage == .session { controls }
                        if stage == .session, passedMinute { earlyWin }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, DX.Space.m)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            if stage == .timeUp { outcomes }
        }
        .padding(.horizontal, DX.Space.m)
        .padding(.bottom, DX.Space.xs)
    }

    private func topBar(_ title: LocalizedStringKey) -> some View {
        HStack {
            Button(action: close) {
                Image(systemName: "xmark").font(.system(size: 13, weight: .semibold)).foregroundStyle(DX.Palette.text2)
                    .frame(width: 36, height: 36)
                    .background(DX.Palette.surface1, in: Circle())
                    .overlay(Circle().strokeBorder(DX.Palette.hairline))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Close"))
            Spacer()
            Text(title).dxText(.micro)
            Spacer()
            Menu {
                if stage == .session {
                    Button("It passed", systemImage: "checkmark") { finish(.passed) }
                    Button("I slipped", systemImage: "arrow.uturn.backward") { finish(.slipped) }
                    Divider()
                    Picker(selection: Binding(get: { patternID }, set: { choosePattern($0) })) {
                        ForEach(OrbData.bundled.breathingPatterns) { p in
                            Text("\(p.name) · \(p.counts)").tag(p.id)
                        }
                    } label: {
                        Label("Breathing pattern", systemImage: "wind")
                    }
                    Button("Calm tools", systemImage: "leaf") { pause(); showCalmTools = true }
                }
                Toggle("Voice guidance", isOn: $voiceOn)
                Toggle("Haptics", isOn: $hapticsOn)
            } label: {
                Image(systemName: "ellipsis").font(.system(size: 14, weight: .semibold)).foregroundStyle(DX.Palette.text2)
                    .frame(width: 36, height: 36)
                    .background(DX.Palette.surface1, in: Circle())
                    .overlay(Circle().strokeBorder(DX.Palette.hairline))
            }
            .accessibilityLabel(Text("Session options"))
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .padding(.top, DX.Space.xs)
    }

    /// Pause or Resume, and Coach me (spec §5, labels from the data file).
    private var controls: some View {
        let labels = engine.data.labels
        return ViewThatFits {
            HStack(spacing: 10) { pauseButton(labels); coachButton(labels) }
            VStack(spacing: 10) { pauseButton(labels); coachButton(labels) }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    private func pauseButton(_ labels: OrbData.Labels) -> some View {
        Button {
            if paused { resume() } else { pause() }
        } label: {
            Label(paused ? labels.resume : labels.pause, systemImage: paused ? "play.fill" : "pause.fill")
        }
        .buttonStyle(OrbButtonStyle(kind: .porcelain))
    }

    private func coachButton(_ labels: OrbData.Labels) -> some View {
        Button(action: coachMe) {
            Label(labels.coachButton, systemImage: "waveform")
        }
        .buttonStyle(OrbButtonStyle(kind: .moss))
    }

    /// After the first minute the wave is usually past its peak: one tap logs the win without waiting for the end.
    private var passedMinute: Bool {
        engine.data.sos.sessionSeconds - engine.session.sosRemaining >= 60
    }

    private var earlyWin: some View {
        Button { finish(.passed) } label: {
            Label("It's passing · log as ridden out", systemImage: "checkmark")
                .font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .body))
                .foregroundStyle(DX.Palette.onAccent)
                .padding(.horizontal, 18).frame(minHeight: 46)
                .background(DX.Palette.sage, in: Capsule())
        }
        .buttonStyle(.plain)
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    private var outcomes: some View {
        VStack(spacing: DX.Space.xs) {
            Button { finish(.passed) } label: { Text("Log as ridden out (+1)").frame(maxWidth: .infinity) }
                .buttonStyle(.dxSage)
            Button(action: anotherRound) { Text("Another three minutes").frame(maxWidth: .infinity) }
                .buttonStyle(.dxSecondary)
            ViewThatFits {
                HStack(spacing: DX.Space.xs) { slippedButton; pingButton }
                VStack(spacing: DX.Space.xs) { slippedButton; pingButton }
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .padding(.top, DX.Space.xs)
    }

    private var slippedButton: some View {
        Button { finish(.slipped) } label: { Text("I slipped").frame(maxWidth: .infinity) }
            .buttonStyle(.dxSecondary)
    }

    private var pingButton: some View {
        ShareLink(item: String(localized: "Having a craving right now. Could you talk for five minutes? 🙏")) {
            Text("Ping a friend").frame(maxWidth: .infinity)
        }
        .buttonStyle(.dxSecondary)
    }

    // MARK: It passed

    private var passedView: some View {
        let count = CravingStats.passedThisWeek(cravings, now: .now)
        return VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: DX.Space.s) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(DX.Palette.onAccent)
                        .frame(width: 92, height: 92)
                        .background(DX.Palette.sage, in: Circle())
                        .accessibilityHidden(true)
                        .padding(.top, DX.Space.xl)
                    Text(wonTitle).dxText(.title).multilineTextAlignment(.center)
                    Text("The craving peaked and passed, and you're still here. Each wave you ride out makes the next one a little quieter.")
                        .dxText(.subtitle).multilineTextAlignment(.center)
                    Text(count > 1 ? "+1 ridden out · \(count) this week" : "+1 ridden out · your first this week")
                        .font(.custom(DX.Typeface.semibold, size: 13, relativeTo: .footnote))
                        .foregroundStyle(DX.Palette.accentInk)
                        .multilineTextAlignment(.center)
                    HStack(spacing: 6) {
                        ForEach(0..<7, id: \.self) { i in
                            Circle().fill(i < count ? DX.Palette.sage : DX.Palette.track).frame(width: 22, height: 22)
                        }
                    }
                    .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: DX.Space.xs) {
                        Text("What set it off? \(Text("· optional").foregroundStyle(DX.Palette.faint))").dxText(.micro)
                        DXFlowLayout {
                            ForEach(orderedTriggers, id: \.self) { t in
                                DXSetChip(t.title, value: t, selection: singleTrigger)
                            }
                        }
                        DXCravingSlider(value: $strength)
                            .frame(height: 110)
                            .padding(.top, DX.Space.s)
                            .onChange(of: strength) { strengthTouched = true }
                    }
                    .padding(.top, DX.Space.l)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            Button("Done") {
                CravingLog.annotate(startedAt: startedAt, trigger: trigger, intensity: strengthTouched ? strength : nil, in: context)
                onClose()
            }
            .buttonStyle(.dxPrimary)
            .padding(.top, DX.Space.xs)
        }
        .padding(.horizontal, DX.Space.m)
        .padding(.bottom, DX.Space.xs)
    }

    private var wonTitle: String {
        if let name = profile?.name, !name.isEmpty { return String(localized: "Wave survived, \(name).") }
        return String(localized: "Wave survived.")
    }

    /// The person's onboarding triggers first, then the rest.
    private var orderedTriggers: [Trigger] {
        let mine = profile?.triggers ?? []
        return mine + Trigger.allCases.filter { !mine.contains($0) }
    }

    private var singleTrigger: Binding<Set<Trigger>> {
        Binding(
            get: { trigger.map { [$0] } ?? [] },
            set: { new in trigger = new.first { $0 != trigger } ?? (trigger.map(new.contains) == true ? trigger : nil) }
        )
    }

    // MARK: I slipped

    private var slippedView: some View {
        SlipFlow(entry: CravingLog.entry(startedAt: startedAt, in: context), profile: profile, onDone: onClose)
    }

    // MARK: Flow

    private func begin() {
        guard !began else { return }
        began = true
        _ = SOSState.consumeFinishedOutside()
        SOSState.startedAt = startedAt
        wire(engine)
        Task { await SOSLiveActivity.start(startedAt: startedAt, endsAt: endsAt) }
        Analytics.track(.cravingSessionStarted(source: source))
        if engine.session.finished {
            stage = .timeUp
        } else {
            engine.start()
        }
        #if DEBUG
        switch UserDefaults.standard.string(forKey: "dx.sosOutcome") {
        case "passed": finish(.passed)
        case "slipped": finish(.slipped)
        default: break
        }
        #endif
    }

    /// Connects the engine to the display clock, the voice and the haptics.
    private func wire(_ engine: OrbEngine) {
        clock.attach(engine, reduceMotion: reduceMotion)
        coach.attach(engine)
        engine.onEvent = { event in
            switch event {
            case let .phaseChanged(phase):
                let pattern = engine.pattern
                if hapticsOn {
                    let total = Double(engine.data.sos.sessionSeconds)
                    haptics.play(phase, pattern: pattern, progress: (total - Double(engine.session.sosRemaining)) / total)
                }
                AccessibilityNotification.Announcement(
                    String(localized: "\(String(localized: String.LocalizationValue(phase.rawValue))), \(pattern.seconds(phase)) seconds")).post()
            case let .coach(trigger):
                if let line = engine.data.coachingLine(trigger: trigger) { coach.play(line, voice: voiceOn) }
            case .finished:
                coach.stop()
                haptics.stop()
                stage = .timeUp
            }
        }
    }

    private var endsAt: Date { Date.now.addingTimeInterval(Double(engine.session.sosRemaining)) }

    private func coachMe() {
        coach.play(engine.nextLine(), voice: voiceOn)
    }

    private func choosePattern(_ id: String) {
        patternID = id
        engine.switchPattern(to: id)
    }

    private func pause() {
        guard stage == .session else { return }
        paused = true
        engine.pause()
        coach.stop()
        haptics.stop()
    }

    private func resume() {
        paused = false
        engine.start()
        Task { await SOSLiveActivity.update(endsAt: endsAt) }
    }

    private func anotherRound() {
        let next = OrbEngine(mode: .sos(seconds: engine.data.sos.sessionSeconds), pattern: patternID)
        engine.onEvent = nil
        engine = next
        wire(next)
        paused = false
        stage = .session
        next.start()
        Task { await SOSLiveActivity.update(endsAt: endsAt) }
    }

    private func tearDown() {
        coach.stop()
        haptics.stop()
        clock.stop()
        engine.pause()
    }

    private func close() {
        if stage == .session || stage == .timeUp { finish(.closed) } else { onClose() }
    }

    private func finish(_ outcome: CravingOutcome) {
        let end = Date.now
        CravingLog.record(outcome, startedAt: startedAt, endedAt: end, in: context)
        SOSState.startedAt = nil
        tearDown()
        Task { await SOSLiveActivity.endAll() }
        Analytics.track(.cravingSessionEnded(outcome: outcome.rawValue, seconds: Int(end.timeIntervalSince(startedAt))))
        switch outcome {
        case .passed:
            stage = .passed
            celebrate.toggle()
        case .slipped:
            Analytics.track(.slipLogged(source: "sos"))
            stage = .slipped
            slipFeedback.toggle()
        case .closed, .pingedFriend:
            onClose()
        }
    }
}

/// The orb screen's two buttons: porcelain for Pause and Resume, moss for Coach me.
private struct OrbButtonStyle: ButtonStyle {
    enum Kind { case porcelain, moss }
    let kind: Kind

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(OrbButtonLabel())
            .font(.custom(DX.Typeface.bold, size: 13, relativeTo: .subheadline))
            .foregroundStyle(kind == .porcelain ? Color.black : Color(orbHex: OrbData.bundled.tokens.sage))
            .padding(.vertical, 14).padding(.horizontal, 20)
            .background(kind == .porcelain ? Color(orbHex: OrbData.bundled.tokens.porcelain) : Color(orbHex: OrbData.bundled.tokens.moss), in: Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

private struct OrbButtonLabel: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon.font(.system(size: 12, weight: .bold))
            configuration.title
        }
    }
}
