import DayXeroCore
import SwiftData
import SwiftUI
import UIKit

/// Craving SOS (F13–F15): Xero hands over to Jelli on the ocean, the person breathes 4 in, 6 out
/// and the time they've ridden counts up. No countdown and no prediction line (design doc §10).
/// Opens straight into the session, with nothing to load first.
struct CravingSOSView: View {
    /// nil before onboarding is finished; the session still works.
    let profile: UserProfile?
    let source: String
    let onClose: () -> Void

    enum Stage: String {
        case session, passed, slipped
    }

    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("dx.sosHaptics") private var hapticsOn = true
    @Query(filter: #Predicate<LogEntry> { $0.kindRaw == "craving" }) private var cravings: [LogEntry]

    @State private var startedAt: Date
    @State private var endedAt: Date?
    @State private var stage = Stage.session
    /// Set when the session ends, so Home can ask a mission's question once SOS has closed.
    @State private var ended = false
    @State private var began = false
    @State private var jelliIn = false
    @State private var celebrate = false
    @State private var slipFeedback = false
    @State private var showCalmTools = false
    /// Taps on the reason card, to step to the next reason.
    @State private var reasonSkip = 0

    /// How long the Lock Screen and Dynamic Island stay fresh. The time ridden counts up, so this is no countdown.
    private static let liveActivitySeconds = 3600.0

    init(profile: UserProfile?, source: String, onClose: @escaping () -> Void) {
        self.profile = profile
        self.source = source
        self.onClose = onClose
        var start = Date.now
        #if DEBUG
        start = start.addingTimeInterval(-Double(UserDefaults.standard.integer(forKey: "dx.sosElapsed")))
        #endif
        _startedAt = State(initialValue: start)
    }

    var body: some View {
        ZStack {
            switch stage {
            case .session: sessionView
            case .passed: PassedView(profile: profile, startedAt: startedAt, endedAt: endedAt ?? .now,
                                     ridden: ridden, onDone: close)
            case .slipped: slippedView
            }
        }
        .onAppear(perform: begin)
        .onDisappear {
            if ended { NotificationCenter.default.post(name: .dxSOSEnded, object: nil) }
        }
        .onChange(of: scenePhase) { _, phase in
            // "It passed" on the Lock Screen already saved the craving; show the same screen as in the app.
            if phase == .active, SOSState.consumeFinishedOutside() == .passed, stage == .session {
                endedAt = .now
                ended = true
                stage = .passed
                celebrate.toggle()
            }
        }
        .fullScreenCover(isPresented: $showCalmTools) {
            CalmToolsView(onClose: { showCalmTools = false }, fromSOS: true)
        }
        .sensoryFeedback(DX.Haptic.commit, trigger: celebrate)
        .sensoryFeedback(DX.Haptic.gentle, trigger: slipFeedback)
    }

    // MARK: F13 Session

    private var sessionView: some View {
        let ground = SOSColors.ocean
        return ZStack {
            ground.background.ignoresSafeArea()
            SOSWater().ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(spacing: 14) {
                        JelliView(mood: .breathe, stage: CrewGrowth.stage(daysClear: daysClear), size: .hero)
                            .offset(x: jelliIn || reduceMotion ? 0 : 90)
                            .opacity(jelliIn ? 1 : 0)
                            .frame(height: 220)
                            .accessibilityHidden(true)
                        SOSBreathWords()
                            .foregroundStyle(SOSColors.cream)
                        riddenLine
                            .dxArrive(5)
                        if let reason = currentReason {
                            SOSReasonCard(reason: reason, canAdvance: reasons.count > 1) { reasonSkip += 1 }
                                .padding(.top, 10)
                                .dxArrive(6)
                        }
                    }
                    .padding(.horizontal, DX.Layout.gutter)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
                .scrollBounceBehavior(.basedOnSize)
                actions
                    .dxArrive(7)
            }
            .dxReadableColumn(avoidingFold: false)
        }
        .sosBreathHaptics(hapticsOn && stage == .session)
    }

    private var topBar: some View {
        HStack {
            HandOverChip(String(localized: "Xero passed you to Jelli")) {
                // The chip's avatar slot is 28 pt; draw Xero at that size so nothing spills.
                XeroView(mood: .calm, stage: 1, points: 28, animate: false)
                    .frame(width: 28, height: 28)
                    .background(DX.Ground.apricot.background, in: Circle())
                    .clipShape(Circle())
            }
            Spacer()
            Button(action: close) {
                Image(systemName: "xmark").font(.system(size: 18, weight: .bold))
                    .foregroundStyle(SOSColors.cream)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Close"))
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .padding(.leading, 14).padding(.trailing, 10)
        .padding(.top, 4)
        .frame(minHeight: 48)
    }

    /// "Most cravings pass within a few minutes. Ride it with me. You've ridden 0:52." The time counts up.
    private var riddenLine: some View {
        TimelineView(.periodic(from: startedAt, by: 1)) { timeline in
            let seconds = max(0, Int(timeline.date.timeIntervalSince(startedAt)))
            let clock = String(format: "%d:%02d", seconds / 60, seconds % 60)
            Text("Most cravings pass within a few minutes. Ride it with me. \(Text("You've ridden \(clock).").fontWeight(.bold).foregroundStyle(SOSColors.cream))")
                .dxType(.body)
                .foregroundStyle(SOSColors.ocean.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12)
        }
    }

    private var actions: some View {
        VStack(spacing: 8) {
            // Side by side, or stacked when the text is too large for one row.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) { passedButton; strongButton.fixedSize(horizontal: true, vertical: false) }
                VStack(spacing: 8) { passedButton; strongButton.frame(maxWidth: .infinity) }
            }
            HStack(spacing: 6) {
                ShareLink(item: String(localized: "Having a craving right now. Could you talk for five minutes?")) {
                    Text("Text a friend")
                }
                .buttonStyle(QuietLink())
                Text(verbatim: "·").foregroundStyle(SOSColors.ocean.muted).accessibilityHidden(true)
                Button("I slipped") { finish(.slipped) }
                    .buttonStyle(QuietLink())
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .padding(.horizontal, DX.Layout.gutter)
        .padding(.bottom, DX.Space.xs)
    }

    private var passedButton: some View {
        Button("It passed") { finish(.passed) }
            .buttonStyle(.dx(.primary, on: .ocean))
            .lineLimit(1)
    }

    /// More help when the wave is strong: the calm tools (decision 26).
    private var strongButton: some View {
        Button("Still strong") { showCalmTools = true }
            .buttonStyle(SolidPill())
            .lineLimit(1)
    }

    // MARK: Your why

    private var reasons: [Reason] {
        (profile?.reasons ?? []).sorted { $0.createdAt < $1.createdAt }
    }

    /// Reasons with a photo first, a different one each session; a tap moves to the next.
    private var currentReason: Reason? {
        let reasons = reasons
        return DailyRhythm.reasonIndex(hasPhoto: reasons.map { $0.photo != nil }, dayNumber: cravings.count + reasonSkip).map { reasons[$0] }
    }

    private var daysClear: Int { Self.clearDays(profile: profile, at: .now) }

    /// Days clear for the crew's stage; 0 during prep or without a profile.
    static func clearDays(profile: UserProfile?, at now: Date) -> Int {
        guard let profile else { return 0 }
        let stats = ProgressStats(quitDay: profile.quitDay, baselines: [], clock: DayClock(boundaryHour: profile.dayBoundaryHour))
        return stats.isPrep(at: now) ? 0 : stats.daysClear(at: now)
    }

    /// Jelli's stage (tokens.json → characters.props.stage) from the person's real days clear.
    static func crewStage(profile: UserProfile?, at now: Date) -> Int {
        CrewGrowth.stage(daysClear: clearDays(profile: profile, at: now))
    }

    /// Waves ridden out so far, not counting this one.
    private var ridden: Int {
        cravings.filter { $0.outcome == .passed && $0.timestamp != startedAt }.count
    }

    // MARK: F15 I slipped

    private var slippedView: some View {
        SlipFlow(entry: CravingLog.entry(startedAt: startedAt, in: context), profile: profile, onDone: onClose)
    }

    // MARK: Flow

    private func begin() {
        guard !began else { return }
        began = true
        _ = SOSState.consumeFinishedOutside()
        SOSState.startedAt = startedAt
        Task { await SOSLiveActivity.start(startedAt: startedAt, endsAt: startedAt.addingTimeInterval(Self.liveActivitySeconds)) }
        Analytics.track(.cravingSessionStarted(source: source))
        withAnimation(DX.Move.animation(DX.Move.settle.delay(0.2), reduceMotion: reduceMotion)) { jelliIn = true }
        #if DEBUG
        switch UserDefaults.standard.string(forKey: "dx.sosOutcome") {
        case "passed": finish(.passed)
        case "slipped": finish(.slipped)
        default: break
        }
        #endif
    }

    private func close() {
        if stage == .session { finish(.closed) } else { onClose() }
    }

    private func finish(_ outcome: CravingOutcome) {
        let end = Date.now
        CravingLog.record(outcome, startedAt: startedAt, endedAt: end, in: context)
        SOSState.startedAt = nil
        Task { await SOSLiveActivity.endAll() }
        Analytics.track(.cravingSessionEnded(outcome: outcome.rawValue, seconds: Int(end.timeIntervalSince(startedAt))))
        ended = true
        endedAt = end
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

/// F14 Passed, on the sky: Jelli cheers (Celebrate), the waves tile ticks up with a "+1",
/// an optional trigger, and the hand back to Xero.
private struct PassedView: View {
    let profile: UserProfile?
    let startedAt: Date
    let endedAt: Date
    /// Waves ridden out before this one.
    let ridden: Int
    let onDone: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var trigger: Trigger?
    @State private var shown = false
    @State private var bumped = false

    private let ground = SOSColors.sky

    var body: some View {
        ZStack {
            ground.background.ignoresSafeArea()
            RisingBubbles().ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 10) {
                        JelliView(mood: .cheer, stage: CravingSOSView.crewStage(profile: profile, at: endedAt), size: .hero)
                            .scaleEffect(shown || reduceMotion ? 1 : DX.Move.celebrateFromScale)
                            .offset(y: shown || reduceMotion ? 0 : 60)
                            .opacity(shown ? 1 : 0)
                            .frame(height: 230, alignment: .bottom)
                            .accessibilityHidden(true)
                        Text("You rode it out.")
                            .dxType(.large)
                            .foregroundStyle(ground.ink)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                            .dxArrive(3)
                        Text("That wave lasted \(lasted). Each one you ride makes the next a little quieter.")
                            .dxType(.body)
                            .foregroundStyle(ground.muted)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 8)
                            .dxArrive(4)
                        wavesTile.padding(.top, 6).dxArrive(5)
                        triggerCard.dxArrive(7)
                        handBack.dxArrive(8)
                    }
                    .padding(.horizontal, DX.Layout.gutter)
                    .padding(.top, DX.Space.m)
                    .padding(.bottom, DX.Space.m)
                }
                .scrollBounceBehavior(.basedOnSize)
                Button("Back to my day") {
                    CravingLog.annotate(startedAt: startedAt, trigger: trigger, intensity: nil, in: context)
                    onDone()
                }
                .buttonStyle(.dx(.primary, on: .sky))
                .padding(.horizontal, DX.Layout.buttonGutter)
                .padding(.bottom, DX.Space.xs)
                .dxArrive(9)
            }
            .dxReadableColumn()
        }
        .task {
            withAnimation(DX.Move.animation(DX.Move.celebrate, reduceMotion: reduceMotion)) { shown = true }
            try? await Task.sleep(for: .seconds(reduceMotion ? 0 : 1.2))
            withAnimation(DX.Move.animation(DX.Move.celebrate, reduceMotion: reduceMotion)) { bumped = true }
        }
    }

    /// "2 minutes, 10 seconds".
    private var lasted: String {
        let seconds = max(1, Int(endedAt.timeIntervalSince(startedAt).rounded()))
        let units: Set<Duration.UnitsFormatStyle.Unit> = seconds >= 60 ? [.minutes, .seconds] : [.seconds]
        return Duration.seconds(seconds).formatted(.units(allowed: units, width: .wide))
    }

    private var wavesTile: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(verbatim: "\(bumped ? ridden + 1 : ridden)")
                        .dxType(.large)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text(verbatim: "+1")
                        .dxFont(16, weight: 700, style: .body)
                        .foregroundStyle(DX.Fill.green)
                        .opacity(bumped ? 1 : 0)
                        .scaleEffect(bumped ? 1 : 0.5)
                        .offset(y: bumped ? 0 : 8)
                        .accessibilityHidden(true)
                }
                Text("waves ridden out").dxType(.footnote).foregroundStyle(ground.muted)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(ground.ink)
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(SOSColors.skyCard, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(ridden + 1) waves ridden out"))
    }

    private var triggerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What set it off? \(Text("· optional").fontWeight(.medium).foregroundStyle(ground.muted))")
                .dxFont(16, weight: 700, style: .body)
                .foregroundStyle(ground.ink)
            TriggerPicker(mine: profile?.triggers ?? [], selection: $trigger,
                          fill: SOSColors.skyChip, ink: ground.ink,
                          selectedFill: ground.ink, selectedInk: ground.background)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(SOSColors.skyCard, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    /// The hand back: Xero's avatar and one line in Xero's voice.
    private var handBack: some View {
        HStack(spacing: 10) {
            XeroView(mood: .cheer, stage: 1, size: .avatar, animate: false)
                .background(DX.Ground.apricot.background, in: Circle())
                .clipShape(Circle())
                .accessibilityHidden(true)
            Text("Back to Xero. I rose a little while you were out.")
                .dxType(.footnote)
                .foregroundStyle(ground.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

/// "Still strong": the solid ocean fill, cream text, 58 pt.
private struct SolidPill: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .dxFont(16, weight: 600, style: .body)
            .foregroundStyle(SOSColors.cream)
            .padding(.horizontal, 18)
            .frame(minHeight: DX.Layout.buttonHeight)
            .background(SOSColors.solid, in: Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// The quiet row under the actions: "Text a friend · I slipped".
private struct QuietLink: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .dxFont(14, weight: 600, style: .footnote)
            .foregroundStyle(SOSColors.cream)
            .padding(.horizontal, 10)
            .frame(minHeight: DX.Layout.touchTarget)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
