import DayXeroCore
import SwiftData
import SwiftUI
import UIKit

/// Craving SOS (F13–F15): Xero hands over to Jelli on the ocean, the person breathes 4 in, 6 out
/// and the time they've ridden counts up. No countdown and no prediction line (design doc §10).
/// Opens straight into the session, with nothing to load first.
///
/// Motion (019): Calm, no springs. Jelli and the single pacer ring (with its soft glow) fade up together and breathe
/// as one: 4s in (scale up), 6s out (scale down), looping. The ring shows the breath: a cream arc sweeps round the
/// ring from the top over the 4s in-breath while a soft inner fill swells behind Jelli, then the arc unwinds and the
/// fill ebbs over the 6s out-breath. The breath word under Jelli crossfades in 600ms between 'Breathe in' and 'and
/// out' in time with the breath. The ride timer counts up from 0:00 each second. The quiet reason line, the button and
/// the two quiet text buttons (Text a friend, I slipped) arrive with a slow 90ms stagger. Touching and holding Jelli
/// gives a soft rhythmic haptic at the breath pace.
///
/// Motion (020): The completion beat, gentle. The pacer ring from SOS closes and the check seals it: a cream knockout
/// disc fades in with the sun disc inside it (500ms, at 900ms) and the ink tick draws (420ms). Jelli settles in
/// cheering (900ms). Title and line fade up and the yellow underline under 'out' draws in. At 900ms the wave count
/// rolls up by one while a '+1' floats up beside it (spring, the only one on the screen). At 1.3s the wave medallion
/// fades in (700ms, no spring) and its progress ring extends toward the next wave badge. The button and the quiet
/// text button arrive last. Success haptic with the +1.
struct CravingSOSView: View {
    /// nil before onboarding is finished; the session still works.
    let profile: UserProfile?
    let source: String
    /// Program v3, Day Xero: a practice run before the first real craving. It logs nothing, starts no Live Activity,
    /// never opens the slip talk-through and doesn't count as a wave ridden.
    var practice = false
    let onClose: () -> Void

    enum Stage: String {
        case session, passed, slipped
        /// Practice runs end here instead: nothing was saved.
        case practicePassed, practiceSlipped
    }

    @Environment(\.modelContext) private var context
    private let motion = MotionPolicy()
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
    /// The opening three physiological sighs (CHAR-01); the rest of the session arrives after them.
    @State private var sighing: Bool
    @State private var showTricks = false

    /// How long the Lock Screen and Dynamic Island stay fresh. The time ridden counts up, so this is no countdown.
    private static let liveActivitySeconds = 3600.0

    init(profile: UserProfile?, source: String, practice: Bool = false, onClose: @escaping () -> Void) {
        self.profile = profile
        self.source = source
        self.practice = practice
        self.onClose = onClose
        var start = Date.now
        #if DEBUG
        start = start.addingTimeInterval(-Double(UserDefaults.standard.integer(forKey: "dx.sosElapsed")))
        #endif
        _startedAt = State(initialValue: start)
        var sigh = true
        #if DEBUG
        // Screenshots of a session already under way, or of its outcome, skip the opening sighs.
        let defaults = UserDefaults.standard
        if defaults.integer(forKey: "dx.sosElapsed") >= 30 || defaults.string(forKey: "dx.sosOutcome") != nil
            || defaults.bool(forKey: "dx.sosSkipSigh") {
            sigh = false
        }
        #endif
        _sighing = State(initialValue: sigh)
    }

    var body: some View {
        ZStack {
            switch stage {
            case .session: sessionView
            case .passed: PassedView(profile: profile, startedAt: startedAt, endedAt: endedAt ?? .now,
                                     ridden: ridden, menu: menu, onDone: close)
            case .slipped: slippedView
            case .practicePassed: SOSPracticeEnd(passed: true, onDone: onClose)
            case .practiceSlipped: SOSPracticeEnd(passed: false, onDone: onClose)
            }
        }
        .onAppear(perform: begin)
        .onDisappear {
            if ended, !practice { NotificationCenter.default.post(name: .dxSOSEnded, object: nil) }
        }
        .onChange(of: scenePhase) { _, phase in
            // "It passed" on the Lock Screen already saved the craving; show the same screen as in the app.
            if !practice, phase == .active, SOSState.consumeFinishedOutside() == .passed, stage == .session {
                endedAt = .now
                ended = true
                stage = .passed
                celebrate.toggle()
            }
        }
        .fullScreenCover(isPresented: $showCalmTools) {
            CalmToolsView(onClose: { showCalmTools = false }, fromSOS: true)
        }
        .sheet(isPresented: $showTricks) { SensoryTricksSheet() }
        .sensoryFeedback(DX.Haptic.commit, trigger: celebrate)
        .sensoryFeedback(DX.Haptic.gentle, trigger: slipFeedback)
    }

    // MARK: F13 Session

    private var sessionView: some View {
        ZStack {
            SOSSea().ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(spacing: 14) {
                        if sighing {
                            // Breathing first (CHAR-01): three sighs, about 30 seconds, then riding it out.
                            SOSSighIntro(stage: CrewGrowth.stage(daysClear: daysClear)) {
                                withAnimation(motion.animation(DX.Move.settle)) { sighing = false }
                            }
                        } else {
                            ridingItOut
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
        .dxGround(.ocean, paint: false)
        .sosBreathHaptics(hapticsOn && stage == .session && !sighing)
    }

    /// After the sighs: Jelli on 4 in, 6 out, the time ridden, their why, then something for the hands (CHAR-02),
    /// the break menu, and the sensory tricks (CHAR-03).
    @ViewBuilder
    private var ridingItOut: some View {
        SOSPacer(diameter: 276) {
            JelliView(mood: .breathe, stage: CrewGrowth.stage(daysClear: daysClear), points: 190)
                .frame(width: 190, height: 190)
        }
        .opacity(jelliIn ? 1 : 0)
        .padding(.top, 18)
        .modifier(HoldJelli())
        .accessibilityHidden(true)
        SOSBreathWords()
            .foregroundStyle(SOSColors.cream)
            .padding(.top, 10)
        helperLines
            .dxArrive(5)
        // Their why comes first, above the fold, before the break menu (UX-06).
        if let reason = currentReason {
            SOSReasonCard(reason: reason, canAdvance: reasons.count > 1) { reasonSkip += 1 }
                .padding(.top, 6)
                .dxArrive(6)
        }
        SOSBreakMenuCard(items: menu.isEmpty ? starterBreaks : menu, isOwn: !menu.isEmpty,
                         buildingDay: buildingDayLabel, fastActingNRT: hasFastActingNRT)
            .dxArrive(7)
        SensoryTricksButton { showTricks = true }
            .dxArrive(7)
    }

    private var topBar: some View {
        HStack {
            // v5: the leading control top-left (kit `.icon-btn` on the ocean's card-2).
            Button(action: close) {
                DXIcon(.close, size: 20, weight: 2.4)
                    .foregroundStyle(SOSColors.cream)
                    .frame(width: 44, height: 44)
                    .background(SOSColors.ocean.card2, in: Circle())
            }
            .buttonStyle(.dxPress)
            .accessibilityLabel(Text("Close"))
            Spacer()
            if practice {
                Text("Practice run · nothing is saved")
                    .dxFont(13, weight: 700, style: .footnote)
                    .foregroundStyle(SOSColors.ocean.background)
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(SOSColors.cream, in: Capsule())
                    .accessibilityIdentifier("sos.practice")
            }
            if !practice, !sighing {
                // "Riding it · 3:12": the ride timer, counting up each second (019).
                TimelineView(.periodic(from: startedAt, by: 1)) { timeline in
                    let seconds = max(0, Int(timeline.date.timeIntervalSince(startedAt)))
                    Text("Riding it · \(String(format: "%d:%02d", seconds / 60, seconds % 60))")
                        .dxFont(14, weight: 700, style: .footnote)
                        .monospacedDigit()
                        .foregroundStyle(SOSColors.cream)
                        .padding(.horizontal, 14)
                        .frame(height: 36)
                        .background(SOSColors.ocean.card2, in: Capsule())
                        .accessibilityLabel(Text("Riding it, \(seconds / 60) minutes \(seconds % 60) seconds"))
                }
                .dxFade(delay: 0.2)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .frame(minHeight: 48)
    }

    /// The helper lines under the breath word (019): for the first breath only, then they fade out at 10 s.
    private var helperLines: some View {
        TimelineView(.periodic(from: startedAt, by: 1)) { timeline in
            let early = timeline.date.timeIntervalSince(startedAt) < 10
            VStack(spacing: 2) {
                Text("Most cravings pass in a few minutes.")
                Text("Hold Jelli to feel the pace.")
            }
            .dxType(.footnote)
            .foregroundStyle(SOSColors.ocean.muted)
            .multilineTextAlignment(.center)
            .opacity(early ? 1 : 0)
            .animation(.easeOut(duration: 1.2), value: early)
            .accessibilityHidden(!early)
        }
    }

    private var actions: some View {
        VStack(spacing: 8) {
            // Side by side, or stacked when the text is too large for one row.
            // v5: one primary; "Still strong" is the outlined second choice beside it.
            passedButton
            HStack(spacing: 18) {
                ShareLink(item: String(localized: "Having a craving right now. Could you talk for five minutes?")) {
                    Text("Text a friend")
                }
                .buttonStyle(QuietLink())
                Rectangle().fill(SOSColors.ocean.muted.opacity(0.5)).frame(width: 1, height: 22).accessibilityHidden(true)
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

    // MARK: Break menu (S27.18)

    private var store: ProgramStore? { profile.map { ProgramStore(context: context, profile: $0) } }

    /// The person's break menu, most helpful first; empty until the program saves one.
    private var menu: [String] {
        guard let store else { return [] }
        return BreakMenu.ordered(BreakMenu.items(menu: store.answer(BreakMenu.menuKey)?.lines ?? [],
                                                 move: Self.text(store.answer(BreakMenu.moveKey))),
                                 helped: cravings.compactMap(\.helped))
    }

    /// Before a menu exists: three of the program's own suggestions from the session that builds it.
    private var starterBreaks: [String] { Self.suggestedBreaks(store: store) }

    /// "Day 9", the day the menu-building session opens.
    private var buildingDayLabel: String? { store?.content?.session(BreakMenu.buildingSessionId)?.label }

    /// Gum, a lozenge or an inhaler, from onboarding or an NRT plan.
    private var hasFastActingNRT: Bool {
        guard let profile else { return false }
        return BreakMenu.hasFastActingNRT(profile.nrtFormats + profile.nrtPlans.compactMap { NRTType(rawValue: $0.typeRaw) })
    }

    static func text(_ value: ProgramAnswerValue?) -> String? {
        if case let .text(text)? = value, !text.isEmpty { return text }
        return nil
    }

    static func suggestedBreaks(store: ProgramStore?) -> [String] {
        let fallback = [String(localized: "Step outside"), String(localized: "Glass of water"), String(localized: "2 minutes of breathing")]
        guard let store, let session = store.content?.session(BreakMenu.buildingSessionId),
              let beat = session.everyBeat.first(where: { $0.saveAs == BreakMenu.menuKey }),
              let options = beat.options?.resolve(store.variant) else { return fallback }
        let picked = ["outside", "water", "breathe"].compactMap { id in options.first { $0.id == id }?.text }
        return picked.count == 3 ? picked : fallback
    }

    // MARK: Your why

    private var reasons: [Reason] {
        (profile?.reasons ?? []).sorted { $0.createdAt < $1.createdAt }
    }

    /// Their onboarding "Why" opens every session (UX-06); a tap steps through the rest, photos first.
    private var currentReason: Reason? {
        let reasons = reasons
        guard let why = reasons.first else { return nil }
        let rest = reasons.dropFirst()
        let order = [why] + rest.filter { $0.photo != nil } + rest.filter { $0.photo == nil }
        return order[reasonSkip % order.count]
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
        SOSSlipPlan(entry: CravingLog.entry(startedAt: startedAt, in: context), profile: profile, onDone: onClose)
    }

    // MARK: Flow

    private func begin() {
        guard !began else { return }
        began = true
        if practice {
            withAnimation(motion.animation(DX.Move.settle.delay(0.2))) { jelliIn = true }
            return
        }
        _ = SOSState.consumeFinishedOutside()
        SOSState.startedAt = startedAt
        Task { await SOSLiveActivity.start(startedAt: startedAt, endsAt: startedAt.addingTimeInterval(Self.liveActivitySeconds)) }
        Analytics.track(.cravingSessionStarted(source: source))
        withAnimation(motion.animation(DX.Move.settle.delay(0.2))) { jelliIn = true }
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
        if practice {
            // A practice run saves nothing and opens nothing; it only shows what would happen.
            switch outcome {
            case .passed: stage = .practicePassed; celebrate.toggle()
            case .slipped: stage = .practiceSlipped
            case .closed, .pingedFriend: onClose()
            }
            return
        }
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
    /// The break menu, most helpful first (S27.18); empty before the program saves one.
    let menu: [String]
    let onDone: () -> Void

    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<LogEntry> { $0.kindRaw == "craving" }) private var cravings: [LogEntry]
    private let motion = MotionPolicy()
    @State private var trigger: Trigger?
    @State private var helped: String?
    @State private var shown = false
    @State private var bumped = false
    @State private var asking = false

    private let ground = SOSColors.sky

    var body: some View {
        ZStack {
            SOSSea().ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 10) {
                        sealedRing
                            .padding(.top, 12)
                        MarkedTitle("You rode it ", marking: String(localized: "out"), color: DX.Mark.color(on: .ocean))
                            .dxType(.large)
                            .foregroundStyle(ground.ink)
                            .padding(.top, 10)
                            .dxFade(delay: 0.3)
                        Text("\(lasted), start to finish. Each one you ride makes the next quieter.")
                            .dxType(.body)
                            .foregroundStyle(ground.muted)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 8)
                            .dxFade(delay: 0.45)
                        wavesTile.padding(.top, 16).dxFade(delay: 0.6)
                    }
                    .padding(.horizontal, DX.Layout.gutter)
                    .padding(.top, DX.Space.m)
                    .padding(.bottom, DX.Space.m)
                }
                .scrollBounceBehavior(.basedOnSize)
                Button("Back to my day") {
                    CravingLog.annotate(startedAt: startedAt, trigger: trigger, intensity: nil, helped: helped, in: context)
                    onDone()
                }
                .buttonStyle(.dx(.primary, on: .ocean))
                .padding(.horizontal, DX.Layout.buttonGutter)
                .dxArrive(9)
                // The optional trigger (and what helped) on its own sheet (020).
                Button(trigger == nil ? "What set it off?" : "Set off by \(Text(trigger!.title).bold())") { asking = true }
                    .buttonStyle(QuietLink())
                    .padding(.bottom, DX.Space.xs)
                    .dxArrive(10)
            }
            .dxReadableColumn()
        }
        .dxGround(.ocean, paint: false)
        .sensoryFeedback(DX.Haptic.commit, trigger: bumped)
        .sheet(isPresented: $asking) {
            ScrollView {
                VStack(spacing: 12) {
                    triggerCard
                    if !menu.isEmpty { helpedCard }
                    Button("Done") { asking = false }
                        .buttonStyle(.dx(.primary, on: .ocean))
                        .padding(.top, 4)
                }
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.top, 24)
            }
            .background(SOSSea().ignoresSafeArea())
            .presentationDetents([.medium, .large])
            .presentationCornerRadius(32)
            .dxGround(.ocean, paint: false)
        }
        .task {
            withAnimation(motion.animation(DX.Move.settle)) { shown = true }
            try? await Task.sleep(for: .seconds(motion.reduce ? 0 : 0.9))
            withAnimation(motion.animation(DX.Move.count)) { bumped = true }
        }
    }

    /// The pacer, closed, with the check sealing the top gap and Jelli cheering inside (020).
    private var sealedRing: some View {
        SOSPacer(diameter: 230, closed: true) {
            JelliView(mood: .cheer, stage: CravingSOSView.crewStage(profile: profile, at: endedAt), points: 170)
                .frame(width: 170, height: 170)
                .dxSettle()
        }
        .overlay(alignment: .top) {
            ZStack {
                Circle().fill(Color(hex: 0xFFF8EE)).frame(width: 46, height: 46)
                DXCheck(size: 36, color: Color(hex: 0xFFD966), tick: Color(hex: 0x1E1A3A), calm: true, delay: 0.9)
            }
            .offset(y: -23)
        }
        .accessibilityHidden(true)
    }

    /// "2 minutes, 10 seconds".
    private var lasted: String {
        let seconds = max(1, Int(endedAt.timeIntervalSince(startedAt).rounded()))
        let units: Set<Duration.UnitsFormatStyle.Unit> = seconds >= 60 ? [.minutes, .seconds] : [.seconds]
        return Duration.seconds(seconds).formatted(.units(allowed: units, width: .wide))
    }

    /// The waves card (020): the wave medallion inside a ring toward the next wave badge, the count rolling up by one
    /// with a "+1" floating beside it.
    private var wavesTile: some View {
        let count = ridden + 1
        let next = [1, 10, 25, 50, 100].first { $0 > count } ?? max(count, 1)
        let previous = [0, 1, 10, 25, 50, 100].last { $0 < next } ?? 0
        let p = Double(count - previous) / Double(max(next - previous, 1))
        let day = DayClock(boundaryHour: profile?.dayBoundaryHour ?? 4)
        let today = max(1, cravings.filter { $0.outcome == .passed && day.day(containing: $0.timestamp) == day.day(containing: endedAt) }.count)
        return HStack(spacing: 18) {
            ZStack {
                DXRing(p: p, size: 104, stroke: 6, color: Color(hex: 0xFFF8EE), track: Color.white.opacity(0.22))
                ZStack {
                    Circle().fill(Color(hex: 0xF5B83D)).frame(width: 80, height: 80)
                    Circle().fill(Color(hex: 0xFFF4DE)).frame(width: 66, height: 66)
                    WaveCore().frame(width: 66, height: 66).clipShape(Circle())
                }
            }
            .frame(width: 104, height: 104)
            .dxFade(delay: 1.3)
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    CountingText(Double(count), from: Double(ridden), delay: 0.9, duration: 0.6) { String(Int($0.rounded())) }
                        .dxFace(.display, 40, weight: 800, tracking: -1.2)
                    DXFloatUp("+1", trigger: bumped, delay: 0.9)
                }
                Text(count == 1 ? "wave ridden out" : "waves ridden out").dxType(.footnote).foregroundStyle(ground.muted)
                Text("\(today) today").dxType(.footnote).foregroundStyle(ground.muted)
                if next > count {
                    Rectangle().fill(SOSColors.ocean.line).frame(height: 1).padding(.vertical, 8)
                    Text(next - count == 1 ? "1 more to your \(next)-wave badge" : "\(next - count) more to your \(next)-wave badge")
                        .dxFont(15, weight: 700, style: .subheadline)
                        .foregroundStyle(ground.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(ground.ink)
        .padding(18)
        .background(SOSColors.skyCard.opacity(0.7), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(SOSColors.ocean.line, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(count) waves ridden out"))
    }

    /// "What helped?": the break menu plus "Just breathing" (S27.18). The pick is saved on this craving and puts that
    /// break first on the menu next time.
    private var helpedCard: some View {
        let options = menu + [String(localized: "Just breathing")]
        return VStack(alignment: .leading, spacing: 10) {
            Text("What helped? \(Text("· optional").fontWeight(.medium).foregroundStyle(ground.muted))")
                .dxFont(16, weight: 700, style: .body)
                .foregroundStyle(ground.ink)
            DXFlowLayout(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    V4Chip(text: option, isOn: helped == option, fill: SOSColors.skyChip, ink: ground.ink,
                           selectedFill: ground.ink, selectedInk: ground.background) {
                        helped = helped == option ? nil : option
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("What helped"))
            if let helped, menu.contains(helped) {
                Text("\(helped) will show first next time.")
                    .dxType(.footnote).foregroundStyle(ground.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(SOSColors.skyCard.opacity(0.7), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(SOSColors.ocean.line, lineWidth: 1))
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
        .background(SOSColors.skyCard.opacity(0.7), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(SOSColors.ocean.line, lineWidth: 1))
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


/// The end of a practice run (program v3, Day Xero): what the real thing would do, and that nothing was saved.
struct SOSPracticeEnd: View {
    let passed: Bool
    let onDone: () -> Void

    private let ground = SOSColors.sky

    var body: some View {
        ZStack {
            SOSSea().ignoresSafeArea()
            VStack(spacing: DX.Space.m) {
                Spacer(minLength: 0)
                JelliView(mood: passed ? .cheer : .calm, stage: 1, size: .scene)
                    .accessibilityHidden(true)
                Text(passed ? "That's the whole move." : "Nothing resets. Ever.")
                    .dxType(.large).foregroundStyle(ground.ink)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text(passed
                     ? "In a real wave, \"It passed\" counts it as ridden out and asks what helped. This was practice, so nothing was saved."
                     : "In a real wave, \"I slipped\" opens a short, kind talk-through and a plan for next time. Your days and milestones never change. This was practice, so nothing was saved.")
                    .dxType(.body).foregroundStyle(ground.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Button("Back to Day Xero", action: onDone)
                    .buttonStyle(.dx(.primary, on: .ocean))
                    .accessibilityIdentifier("sos.practice.done")
            }
            .padding(.horizontal, DX.Layout.gutter)
            .padding(.bottom, DX.Space.xs)
            .dxReadableColumn(avoidingFold: false)
        }
        .dxGround(.ocean, paint: false)
    }
}

/// The lit sea every SOS screen sits on (kit ocean): a top glow over the three-stop gradient.
struct SOSSea: View {
    var body: some View {
        ZStack {
            DX.Ground.oceanGradient
            RadialGradient(colors: [Color(light: (0xFFFFFF, 0.2), dark: (0xA0BEFF, 0.10)), .clear],
                           center: UnitPoint(x: 0.5, y: -0.08), startRadius: 0, endRadius: 420)
        }
    }
}

/// The wave medallion's core: two waves on cream (kit wave badge, no numeral).
private struct WaveCore: View {
    var body: some View {
        Canvas { ctx, size in
            ctx.scaleBy(x: size.width / 100, y: size.height / 100)
            ctx.fill(SVGPath.path("M0 58c8-7 16-7 24 0s16 7 24 0 16-7 24 0 16-7 28 0v42H0z"), with: .color(Color(hex: 0x5C7FF0)))
            ctx.fill(SVGPath.path("M0 72c8-6 16-6 24 0s16 6 24 0 16-6 24 0 16-6 28 0v28H0z"), with: .color(Color(hex: 0x2A52DB)))
        }
    }
}
