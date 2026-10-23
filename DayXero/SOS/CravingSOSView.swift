import DayXeroCore
import SwiftData
import SwiftUI
import UIKit

/// Craving SOS (S6.1–S6.3): about three minutes of guided breathing and an urge-surfing countdown, with the
/// person's own reasons, then how it went. Opens straight into the session, with nothing to load first.
struct CravingSOSView: View {
    /// nil before onboarding is finished; the session still works, just without reasons.
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
    @Query(filter: #Predicate<LogEntry> { $0.kindRaw == "craving" }) private var cravings: [LogEntry]
    @Query(sort: \IfThenPlan.createdAt, order: .reverse) private var plans: [IfThenPlan]

    @State private var startedAt: Date
    @State private var roundStartedAt: Date
    @State private var stage = Stage.session
    @State private var began = false
    @State private var reasonSkip = 0
    @State private var haptics = BreathHaptics()
    @State private var celebrate = false
    @State private var slipFeedback = false
    @State private var trigger: Trigger?
    @State private var strength = 5
    @State private var strengthTouched = false
    /// Calm tools pause the countdown (S12.2); the round resumes where it left off.
    @State private var pausedAt: Date?

    init(profile: UserProfile?, source: String, onClose: @escaping () -> Void) {
        self.profile = profile
        self.source = source
        self.onClose = onClose
        var start = Date.now
        #if DEBUG
        start = start.addingTimeInterval(-UserDefaults.standard.double(forKey: "dx.sosElapsed"))
        #endif
        _startedAt = State(initialValue: start)
        _roundStartedAt = State(initialValue: start)
    }

    var body: some View {
        ZStack {
            DX.Palette.canvas.ignoresSafeArea()
            RadialGradient(colors: [DX.Palette.accentSoft, .clear], center: UnitPoint(x: 0.5, y: 0.3),
                           startRadius: 0, endRadius: 440)
                .ignoresSafeArea()
                .opacity(stage == .session || stage == .timeUp ? 1 : 0)
            switch stage {
            case .session, .timeUp: sessionView
            case .passed: passedView
            case .slipped: slippedView
            }
        }
        .onAppear(perform: begin)
        .task(id: stage) {
            if stage == .session { await tick() }
        }
        .onChange(of: scenePhase) { _, phase in
            // "It passed" on the Lock Screen already saved the craving; show the same screen as in the app.
            if phase == .active, SOSState.consumeFinishedOutside() == .passed, stage == .session || stage == .timeUp {
                haptics.stop()
                stage = .passed
            }
        }
        .fullScreenCover(isPresented: Binding(get: { pausedAt != nil }, set: { if !$0 { resume() } })) {
            CalmToolsView(onClose: { resume() }, fromSOS: true)
        }
        .sensoryFeedback(DX.Haptic.commit, trigger: celebrate)
        .sensoryFeedback(DX.Haptic.gentle, trigger: slipFeedback)
    }

    // MARK: Session

    private var sessionView: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1.0 / 30, paused: stage != .session)) { timeline in
            let now = timeline.date
            let elapsed = now.timeIntervalSince(startedAt)
            let roundElapsed = stage == .timeUp ? CravingWave.roundLength : now.timeIntervalSince(roundStartedAt)
            let breath = CravingWave.breath(at: elapsed)
            let reason = currentReason(elapsed: elapsed)
            let photo = stage == .session ? reason?.photo.flatMap(UIImage.init(data:)) : nil
            VStack(spacing: 0) {
                topBar(stage == .timeUp ? "Three minutes done" : "Riding it out")
                ScrollView {
                    VStack(spacing: DX.Space.s) {
                        if let photo, let reason {
                            pill(breath, roundElapsed: roundElapsed)
                            photoCard(photo, text: reason.text)
                            dots
                            caption(roundElapsed: roundElapsed)
                        } else {
                            orb(breath, roundElapsed: roundElapsed)
                            if stage == .timeUp {
                                Text("How's the craving now?").dxText(.title).multilineTextAlignment(.center).padding(.top, DX.Space.s)
                                Text("However it went, you gave it three minutes. That counts.").dxText(.subtitle)
                                    .multilineTextAlignment(.center)
                            } else {
                                caption(roundElapsed: roundElapsed)
                                if let reason { reasonCard(reason) }
                                dots
                                // The latest if-then plan, from a lesson or a slip talk-through (S5, S8.2).
                                if let plan = plans.first {
                                    PlanCard(situation: plan.situation, action: plan.action).padding(.top, DX.Space.xxs)
                                }
                            }
                        }
                    }
                    .padding(.vertical, DX.Space.xs)
                }
                .scrollBounceBehavior(.basedOnSize)
                outcomes
            }
            .padding(.horizontal, DX.Space.m)
            .padding(.bottom, DX.Space.xs)
        }
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
                Button("Calm tools", systemImage: "wind") { pausedAt = .now; haptics.stop() }
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
        .padding(.bottom, DX.Space.s)
    }

    private func orb(_ breath: CravingWave.Breath, roundElapsed: TimeInterval) -> some View {
        let done = stage == .timeUp
        return ZStack {
            Circle()
                .fill(RadialGradient(colors: [DX.Palette.sage.opacity(0.6), DX.Palette.sage.opacity(0.22), .clear],
                                     center: UnitPoint(x: 0.5, y: 0.42), startRadius: 0, endRadius: 108))
                .scaleEffect(reduceMotion || done ? 0.86 : 0.72 + 0.28 * breath.scale)
            Circle().stroke(DX.Palette.track, lineWidth: 3)
            Circle()
                .trim(from: 0, to: CravingWave.fraction(roundElapsed: roundElapsed))
                .stroke(DX.Palette.text, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text(done ? "You rode it out" : cue(breath.phase))
                    .font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .callout))
                Text(verbatim: clock(done ? CravingWave.roundLength : CravingWave.remaining(roundElapsed: roundElapsed)))
                    .font(.custom(DX.Typeface.bold, size: 40, relativeTo: .largeTitle)).monospacedDigit()
                Text(done ? "done" : "left").font(.custom(DX.Typeface.regular, size: 11, relativeTo: .caption2))
                    .foregroundStyle(DX.Palette.muted)
            }
            .foregroundStyle(DX.Palette.text)
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        }
        .frame(width: 210, height: 210)
        .padding(.top, DX.Space.xxs)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(done ? "You rode it out" : cue(breath.phase)))
        .accessibilityValue(Text("\(clock(CravingWave.remaining(roundElapsed: roundElapsed))) left"))
    }

    private func pill(_ breath: CravingWave.Breath, roundElapsed: TimeInterval) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "wind").font(.system(size: 12))
            Text("\(Text(cue(breath.phase))) · \(clock(CravingWave.remaining(roundElapsed: roundElapsed))) left")
        }
        .font(.custom(DX.Typeface.medium, size: 12, relativeTo: .caption))
        .foregroundStyle(DX.Palette.text2)
        .padding(.vertical, 6).padding(.horizontal, 10)
        .background(DX.Palette.surface1, in: Capsule())
        .overlay(Capsule().strokeBorder(DX.Palette.hairline))
    }

    private func photoCard(_ image: UIImage, text: String) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: 260)
            .overlay(LinearGradient(colors: [.black.opacity(0.65), .clear], startPoint: .bottom, endPoint: .center))
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Why you're doing this").dxText(.micro, color: .white.opacity(0.75))
                    Text(text).font(.custom(DX.Typeface.bold, size: 19, relativeTo: .title3)).foregroundStyle(.white)
                }
                .padding(DX.Space.m)
            }
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .onTapGesture { reasonSkip += 1 }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(Text("Shows your next reason"))
    }

    private func reasonCard(_ reason: Reason) -> some View {
        Button { reasonSkip += 1 } label: {
            HStack(spacing: DX.Space.s) {
                Group {
                    if let image = reason.photo.flatMap(UIImage.init(data:)) {
                        Image(uiImage: image).resizable().scaledToFill()
                    } else {
                        Image(systemName: "heart").font(.system(size: 18)).foregroundStyle(DX.Palette.accentInk)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(DX.Palette.accentSoft)
                    }
                }
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Why you're doing this").dxText(.micro)
                    Text(reason.text).font(.custom(DX.Typeface.semibold, size: 14, relativeTo: .subheadline))
                        .foregroundStyle(DX.Palette.text)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(10)
            .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(DX.Palette.hairline))
        }
        .buttonStyle(.plain)
        .padding(.top, DX.Space.xs)
        .accessibilityHint(Text("Shows your next reason"))
    }

    @ViewBuilder
    private var dots: some View {
        if reasons.count > 1 {
            let current = CravingWave.reasonIndex(elapsed: Date.now.timeIntervalSince(startedAt), count: reasons.count)
                .map { ($0 + reasonSkip) % reasons.count }
            HStack(spacing: 4) {
                ForEach(reasons.indices, id: \.self) { i in
                    Circle().fill(i == current ? DX.Palette.text : DX.Palette.track).frame(width: 5, height: 5)
                }
            }
            .accessibilityHidden(true)
        }
    }

    private func caption(roundElapsed: TimeInterval) -> some View {
        Text(CravingWave.isPastPeak(roundElapsed: roundElapsed)
             ? "It's past its peak. Keep breathing slowly."
             : "Urges rise, peak and fall, like a wave. You don't have to fight it, just let it pass.")
            .dxText(.subtitle)
            .multilineTextAlignment(.center)
            .padding(.horizontal, DX.Space.xs)
            .padding(.top, DX.Space.xs)
    }

    private var outcomes: some View {
        VStack(spacing: DX.Space.xs) {
            Button { finish(.passed) } label: { Text("It passed").frame(maxWidth: .infinity) }
                .buttonStyle(.dxSage)
            if stage == .timeUp {
                Button(action: anotherRound) { Text("Another three minutes").frame(maxWidth: .infinity) }
                    .buttonStyle(.dxSecondary)
            }
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
                    Text("Craving ridden out").dxText(.title).multilineTextAlignment(.center)
                    Text(count > 1 ? "That's \(count) this week. Each one makes the next a little easier."
                         : "That's your first this week. Each one makes the next a little easier.")
                        .dxText(.subtitle).multilineTextAlignment(.center)
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

    private var reasons: [Reason] {
        (profile?.reasons ?? []).sorted { $0.createdAt < $1.createdAt }
    }

    private func currentReason(elapsed: TimeInterval) -> Reason? {
        CravingWave.reasonIndex(elapsed: elapsed, count: reasons.count).map { reasons[($0 + reasonSkip) % reasons.count] }
    }

    private func cue(_ phase: CravingWave.Phase) -> LocalizedStringKey {
        phase == .breatheIn ? "Breathe in" : "Breathe out"
    }

    private func clock(_ seconds: TimeInterval) -> String {
        Duration.seconds(seconds.rounded(.up)).formatted(.time(pattern: .minuteSecond))
    }

    private func begin() {
        guard !began else { return }
        began = true
        _ = SOSState.consumeFinishedOutside()
        SOSState.startedAt = startedAt
        let start = startedAt, ends = roundStartedAt.addingTimeInterval(CravingWave.roundLength)
        Task { await SOSLiveActivity.start(startedAt: start, endsAt: ends) }
        Analytics.track(.cravingSessionStarted(source: source))
        #if DEBUG
        switch UserDefaults.standard.string(forKey: "dx.sosOutcome") {
        case "passed": finish(.passed)
        case "slipped": finish(.slipped)
        default: break
        }
        #endif
    }

    /// Keeps time: ends the round, plays a haptic pulse at the start of each breath, and reads cues to VoiceOver.
    private func tick() async {
        var lastBreath = -1
        var lastPhase: CravingWave.Phase?
        while !Task.isCancelled, stage == .session {
            if pausedAt != nil {
                try? await Task.sleep(for: .milliseconds(200))
                continue
            }
            let now = Date.now
            if CravingWave.remaining(roundElapsed: now.timeIntervalSince(roundStartedAt)) <= 0 {
                haptics.stop()
                stage = .timeUp
                return
            }
            let breath = CravingWave.breath(at: now.timeIntervalSince(startedAt))
            if breath.index != lastBreath {
                if lastBreath >= 0, hapticsOn { haptics.play(inhale: breath.inhaleSeconds, exhale: breath.exhaleSeconds) }
                lastBreath = breath.index
            }
            if breath.phase != lastPhase {
                if lastPhase != nil, UIAccessibility.isVoiceOverRunning {
                    AccessibilityNotification.Announcement(breath.phase == .breatheIn ? String(localized: "Breathe in") : String(localized: "Breathe out")).post()
                }
                lastPhase = breath.phase
            }
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    private func resume() {
        guard let paused = pausedAt else { return }
        let gap = Date.now.timeIntervalSince(paused)
        roundStartedAt = roundStartedAt.addingTimeInterval(gap)
        pausedAt = nil
        let ends = roundStartedAt.addingTimeInterval(CravingWave.roundLength)
        Task { await SOSLiveActivity.update(endsAt: ends) }
    }

    private func anotherRound() {
        roundStartedAt = .now
        stage = .session
        let ends = roundStartedAt.addingTimeInterval(CravingWave.roundLength)
        Task { await SOSLiveActivity.update(endsAt: ends) }
    }

    private func close() {
        if stage == .session || stage == .timeUp { finish(.closed) } else { onClose() }
    }

    private func finish(_ outcome: CravingOutcome) {
        let end = Date.now
        CravingLog.record(outcome, startedAt: startedAt, endedAt: end, in: context)
        SOSState.startedAt = nil
        haptics.stop()
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
