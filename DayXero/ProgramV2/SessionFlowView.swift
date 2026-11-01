import DayXeroCore
import SwiftData
import SwiftUI

/// One program v2 session, a step at a time (handoff 4.2): intro, before-audio activities, the audio,
/// the activities, today's mission, then the completion moment. Every change is saved, so closing and
/// reopening resumes exactly there; closing never asks "are you sure".
struct SessionFlowView: View {
    let sessionId: String
    let profile: UserProfile
    /// Replays show saved answers, never change unlock state, never re-run commits and don't count as finishing.
    var isReplay = false

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var steps: [FlowStep] = []
    @State private var index = 0
    @State private var record: SessionRecord?
    @State private var completed = false

    enum FlowStep: Hashable {
        case intro, beat(String), audio, mission, completion
    }

    private var store: ProgramStore { ProgramStore(context: context, profile: profile) }
    private var session: ProgramContent.Session? { store.content?.session(sessionId) }

    var body: some View {
        VStack(spacing: 0) {
            if let session, steps.indices.contains(index) {
                if steps[index] != .completion { header(session) }
                stepView(steps[index], session: session)
                    .id(steps[index])
                    .transition(reduceMotion ? .opacity : .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                                       removal: .opacity))
            }
        }
        .padding(.horizontal, DX.Layout.gutter)
        .dxReadableColumn()
        .padding(.top, DX.Space.s)
        .padding(.bottom, DX.Space.xs)
        .foregroundStyle(Read4.ink)
        .background(stepGround.background.ignoresSafeArea())
        .animation(DX.Move.animation(DX.Move.settle, reduceMotion: reduceMotion), value: stepGround)
        .animation(DX.Move.animation(DX.Move.settle, reduceMotion: reduceMotion), value: index)
        .onAppear(perform: start)
    }

    /// Most steps are on the reading ground. Day Xero's hold (Q1) is on apricot and its completion (Q2) on sun.
    private var stepGround: DX.Ground {
        guard let session, steps.indices.contains(index) else { return .reading }
        switch steps[index] {
        case let .beat(id):
            return session.beats.first { $0.id == id }?.sets == "quit_timestamp" ? .apricot : .reading
        case .completion:
            let finale = session.beats.contains { $0.sets == "graduated_at" }
            return session.id == ProgramV2Access.offerAfter || (finale && !isReplay) ? .sun : .reading
        default:
            return .reading
        }
    }

    // MARK: Steps

    private func start() {
        guard let session, steps.isEmpty else { return }
        let ctx = context(for: session)
        let visible = { (beats: [Beat]) in beats.filter { ctx.shows($0) }.map { FlowStep.beat($0.id) } }
        var built: [FlowStep] = [.intro] + visible(session.beatsBeforeAudio) + [.audio] + visible(session.beatsAfterAudio)
        if session.mission != nil { built.append(.mission) }
        built.append(.completion)
        steps = built
        let firstAfterAudio = (built.firstIndex(of: .audio) ?? 0) + 1
        let record = store.open(session, firstStepAfterAudio: firstAfterAudio)
        self.record = record
        // A replay starts at the beginning; a finished session opened normally is a replay too.
        if isReplay || record.completedAt != nil {
            index = 0
        } else {
            index = min(record.currentStep, built.count - 1)
        }
        #if DEBUG
        if UserDefaults.standard.object(forKey: "dx.sessionStep") != nil {
            index = min(max(UserDefaults.standard.integer(forKey: "dx.sessionStep"), 0), built.count - 1)
        }
        // Screenshots of one step by name: -dx.sessionBeat W1D2.3, or intro, audio, mission, completion.
        if let name = UserDefaults.standard.string(forKey: "dx.sessionBeat") {
            let step: FlowStep = switch name {
            case "intro": .intro
            case "audio": .audio
            case "mission": .mission
            case "completion": .completion
            default: .beat(name)
            }
            if let found = built.firstIndex(of: step) { index = found }
        }
        #endif
        Analytics.track(isReplay || record.completedAt != nil ? .programReplayStarted(sessionId: session.id)
                        : .programSessionStarted(sessionId: session.id, variant: ctx.variant.rawValue))
    }

    private func advance() {
        guard index + 1 < steps.count else { dismiss(); return }
        index += 1
        if !isReplay, let record, record.completedAt == nil {
            record.currentStep = index
            try? context.save()
        }
        if steps[index] == .completion, !isReplay, record?.completedAt == nil, let session {
            store.complete(session.id)
            completed = true
            let minutes = Int(Date.now.timeIntervalSince(record?.startedAt ?? .now) / 60)
            Analytics.track(.programSessionCompleted(sessionId: session.id, minutesBucket: Analytics.minutesBucket(minutes)))
        }
    }

    private func close() {
        if !isReplay, let record { record.currentStep = index; try? context.save() }
        dismiss()
    }

    func context(for session: ProgramContent.Session) -> BeatContext {
        BeatContext(store: store, session: session, variant: store.variant, nrtActive: store.nrtActive(),
                    placeholders: store.placeholders(), isReplay: isReplay)
    }

    // MARK: Chrome

    /// The lesson bar: close ("Your place is saved."), a green bar over the steps, and Xero's avatar.
    private func header(_ session: ProgramContent.Session) -> some View {
        HStack(spacing: 12) {
            Button(action: close) {
                Image(systemName: "xmark").font(.system(size: 16, weight: .bold)).foregroundStyle(Read4.ink)
                    .frame(width: 44, height: 44)
                    .background(Read4.surface, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(isReplay ? "Close" : "Close. Your place is saved."))
            V4ProgressBar(value: Double(index + 1) / Double(max(steps.count, 1)))
                .accessibilityLabel(Text("\(session.label), step \(index + 1) of \(steps.count)"))
            if isReplay {
                Text("Replay").dxType(.caption).textCase(.uppercase)
                    .foregroundStyle(Read4.muted)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Read4.surface, in: Capsule())
            }
            XeroView(mood: .hello, stage: 1, size: .avatar, animate: false)
                .background(DX.Ground.apricot.background, in: Circle())
                .clipShape(Circle())
                .accessibilityHidden(true)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .padding(.bottom, DX.Space.s)
    }

    @ViewBuilder
    private func stepView(_ step: FlowStep, session: ProgramContent.Session) -> some View {
        let ctx = context(for: session)
        switch step {
        case .intro:
            SessionIntro(session: session, variant: ctx.variant, isReplay: isReplay, onBegin: advance)
        case let .beat(id):
            if let beat = (session.beats + (session.mission?.followUp ?? [])).first(where: { $0.id == id }) {
                BeatScreen(beat: beat, ctx: ctx, onDone: advance)
            }
        case .audio:
            ProgramAudioStep(session: session, ctx: ctx, record: record, onDone: advance)
        case .mission:
            if let mission = session.mission {
                MissionCard(mission: mission, ctx: ctx) {
                    if !isReplay { store.missionShown(session.id) }
                    advance()
                }
            }
        case .completion:
            SessionCompletion(session: session, ctx: ctx, isReplay: isReplay, onDone: { dismiss() })
        }
    }
}

// MARK: - Intro

struct SessionIntro: View {
    let session: ProgramContent.Session
    let variant: ProgramVariant
    let isReplay: Bool
    let onBegin: () -> Void

    @Environment(\.modelContext) private var context

    /// P1: the path at the sky's clarity, Xero 140, the session's label, title and subtitle.
    var body: some View {
        VStack(spacing: DX.Space.m) {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ZStack(alignment: .bottom) {
                        HorizonScene(.path, clarity: clarity, fit: .bottom)
                        XeroView(mood: .hello, stage: 1, size: .scene).offset(y: -4)
                    }
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
                    .padding(.bottom, DX.Space.s)
                    .accessibilityHidden(true)
                    .dxArrive(0)
                    Text(verbatim: eyebrow).dxType(.caption).foregroundStyle(Read4.muted).dxArrive(1)
                    Text(verbatim: session.title.resolve(variant) ?? "")
                        .dxType(.large)
                        .foregroundStyle(Read4.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .dxArrive(1)
                    Text(verbatim: session.subtitle.resolve(variant) ?? "").dxType(.body).foregroundStyle(Read4.muted).dxArrive(2)
                    // Only a session with a mission promises one (Graduation has none).
                    Group {
                        if session.mission != nil {
                            Label("\(session.durationMinutes) min · Audio, activities and today's mission", systemImage: "headphones")
                        } else {
                            Label("\(session.durationMinutes) min · Audio and activities", systemImage: "headphones")
                        }
                    }
                    .dxType(.footnote).foregroundStyle(Read4.ink)
                    .dxArrive(2)
                    if let hint = session.listenHint?.resolve(variant) {
                        Label(hint, systemImage: "clock")
                            .dxType(.footnote).foregroundStyle(Read4.ink)
                            .v4Card()
                            .padding(.top, DX.Space.xs)
                            .dxArrive(3)
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            Button(isReplay ? "Replay" : "Begin", action: onBegin)
                .buttonStyle(.dx(.primary, on: .reading))
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
    }

    /// "SUN 8 NOV · DAY 2": today's date and the session's label.
    private var eyebrow: String {
        "\(Date.now.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))) · \(session.label)".uppercased()
    }

    private var clarity: Int {
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return CrewGrowth.prepClarity }
        let stats = ProgressStats(quitDay: profile.quitDay, baselines: [], clock: DayClock(boundaryHour: profile.dayBoundaryHour))
        return stats.isPrep(at: .now) ? CrewGrowth.prepClarity : CrewGrowth.clarity(daysClear: stats.daysClear(at: .now))
    }
}

// MARK: - Audio

/// The guided audio. With a recording in the bundle it plays with the cloud wave and captions, and Continue appears
/// only when it ends (no skipping). Until the recordings arrive it shows "Audio coming soon" and lets the session go on.
struct ProgramAudioStep: View {
    let session: ProgramContent.Session
    let ctx: BeatContext
    let record: SessionRecord?
    let onDone: () -> Void

    @Environment(\.modelContext) private var context
    @State private var finished = false

    struct Transcript: Decodable {
        struct Segment: Decodable { let start: Double; let end: Double; let text: String }
        let segments: [Segment]
    }

    private var variantName: String { session.audio.pick(for: ctx.variant, nrtActive: ctx.nrtActive) }

    private func bundled(_ name: String) -> URL? {
        let base = (name as NSString).deletingPathExtension, ext = (name as NSString).pathExtension
        return Bundle.main.url(forResource: base, withExtension: ext, subdirectory: ctx.store.content?.audio.folder)
            ?? Bundle.main.url(forResource: base, withExtension: ext)
    }

    private var narrator: LessonNarrator? {
        guard let naming = ctx.store.content?.audio,
              let audio = bundled(naming.file(session: session.id, variant: variantName)) else { return nil }
        let segments: [(start: Double, text: String)] = bundled(naming.transcript(session: session.id, variant: variantName))
            .flatMap { try? Data(contentsOf: $0) }
            .flatMap { try? JSONDecoder().decode(Transcript.self, from: $0) }?
            .segments.map { ($0.start, $0.text) } ?? []
        let seconds = Double(session.durationMinutes * 60)
        return LessonNarrator(segments: segments.isEmpty ? [(0, session.title.resolve(ctx.variant) ?? "")] : segments,
                              url: audio, seconds: seconds)
    }

    var body: some View {
        VStack(spacing: DX.Space.s) {
            if let narrator {
                LessonAudioStep(title: session.title.resolve(ctx.variant) ?? "", narrator: narrator,
                                startAt: ctx.isReplay ? 0 : record?.audioPosition ?? 0,
                                onPosition: { seconds in
                                    guard !ctx.isReplay, let record else { return }
                                    record.audioPosition = seconds
                                    record.audioVariant = variantName
                                    try? context.save()
                                },
                                onFinish: { finished = true })
                    .frame(maxHeight: .infinity)
                if finished || ctx.isReplay {
                    Button("Continue", action: onDone).buttonStyle(.dx(.primary, on: .reading)).dynamicTypeSize(...DynamicTypeSize.accessibility1)
                }
            } else {
                comingSoon
            }
        }
    }

    private var comingSoon: some View {
        VStack(spacing: DX.Space.m) {
            Text(verbatim: session.title.resolve(ctx.variant) ?? "").v4Text(.title).multilineTextAlignment(.center)
            XeroBreathRing(playing: false)
                .frame(height: 200)
            Label("Audio coming soon", systemImage: "headphones")
                .dxFont(14, weight: 700, style: .footnote)
                .foregroundStyle(Read4.amber)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Read4.amber.opacity(0.12), in: Capsule())
            Text("The guided audio for this session is on its way. Everything after it works now, so carry on.")
                .v4Text(.subtitle).multilineTextAlignment(.center)
            Spacer()
            Button("Continue", action: onDone).buttonStyle(.dx(.primary, on: .reading)).dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
        .onAppear {
            guard !ctx.isReplay, let record else { return }
            record.audioVariant = variantName
            try? context.save()
        }
    }
}

// MARK: - Mission

/// P5: the mission on an apricot card (Xero's colour), then "Got it".
struct MissionCard: View {
    let mission: ProgramContent.Mission
    let ctx: BeatContext
    let onDone: () -> Void

    var body: some View {
        let ground = DX.Ground.apricot
        VStack(spacing: DX.Space.m) {
            Spacer()
            VStack(alignment: .leading, spacing: 12) {
                Text("Today's mission").dxType(.caption).textCase(.uppercase).foregroundStyle(ground.muted)
                Text(verbatim: ctx.text(mission.text))
                    .dxType(.title)
                    .foregroundStyle(ground.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(mission.followUp == nil ? "It stays on your Today card until the next session."
                     : "When you log it, we'll ask two quick questions. It stays on your Today card until the next session.")
                    .dxType(.footnote)
                    .foregroundStyle(ground.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous)
                    .fill(ground.background)
                    .shadow(color: .black.opacity(0.12), radius: 0, x: 0, y: 5)
            }
            .accessibilityElement(children: .combine)
            .dxArrive(0)
            Spacer()
            Button("Got it", action: onDone)
                .buttonStyle(.dx(.primary, on: .reading))
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
    }
}

// MARK: - Completion

/// P6: "DAY 2 DONE", the completion line and what comes next. Settle only: a lesson is not a milestone.
struct SessionCompletion: View {
    let session: ProgramContent.Session
    let ctx: BeatContext
    let isReplay: Bool
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(Entitlement.self) private var entitlement
    @AppStorage("dx.dayXeroOfferShown") private var dayXeroOfferShown = false
    @State private var shown = false
    @State private var showOffer = false

    private var next: String? {
        guard let next = ctx.store.content?.session(after: session.id) else { return nil }
        let title = next.title.resolve(ctx.variant) ?? ""
        return switch ctx.store.state(of: next.id) {
        case .available, .inProgress: String(localized: "Next: \(next.label) · \(title), ready now")
        case .scheduled(.tomorrow): String(localized: "Next: \(next.label) · \(title), tomorrow")
        case let .scheduled(.dayXero(date)): String(localized: "Day Xero is \(date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))")
        case let .scheduled(.quitDay(days)): String(localized: "Next session on Day \(ProgramUnlock.counterDay(daysSinceQuit: days))")
        default: nil
        }
    }

    private var clarity: Int {
        let profile = ctx.store.profile
        let stats = ProgressStats(quitDay: profile.quitDay, baselines: [], clock: DayClock(boundaryHour: profile.dayBoundaryHour))
        return stats.isPrep(at: .now) ? CrewGrowth.prepClarity : CrewGrowth.clarity(daysClear: stats.daysClear(at: .now))
    }

    var body: some View {
        if session.id == ProgramV2Access.offerAfter, !isReplay {
            dayXeroDone
        } else if session.beats.contains(where: { $0.sets == "graduated_at" }), !isReplay {
            // F18: the graduation session ends on the finale, the only screen with confetti.
            FinaleView(profile: ctx.store.profile, label: session.label, onDone: onDone)
        } else {
            lessonDone
        }
    }

    /// Q2 You're on Day Xero (sun). Day 1 is a milestone, so Xero enters with Celebrate and cheers; no confetti.
    /// Continue leads to the offer (Q3) once, for anyone without the full program (decision 23).
    private var dayXeroDone: some View {
        let ground = DX.Ground.sun
        let snap = HomeSnapshot(profile: ctx.store.profile, isPro: entitlement.isPro, now: .now)
        let code = snap.currencyCode
        return VStack(spacing: DX.Space.m) {
            ScrollView {
                VStack(spacing: 12) {
                    XeroView(mood: shown ? .cheer : .hello, stage: 1, size: .hero)
                        .scaleEffect(shown || reduceMotion ? 1 : DX.Move.celebrateFromScale)
                        .opacity(shown ? 1 : 0)
                        .frame(height: 220, alignment: .bottom)
                        .accessibilityHidden(true)
                    Text(verbatim: ctx.text(session.completionText))
                        .dxType(.large).foregroundStyle(ground.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    if let mission = session.mission {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Today's mission").dxType(.caption).textCase(.uppercase).foregroundStyle(ground.muted)
                            Text(verbatim: ctx.text(mission.text)).dxType(.body).foregroundStyle(ground.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(DX.Fill.onColourCard(for: ground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                    HStack(spacing: 8) {
                        StatTile(value: Double(snap.daysClear), label: snap.daysClear == 1 ? String(localized: "day clear") : String(localized: "days clear"),
                                 ground: ground)
                        if let counter = snap.counters.first {
                            let avoided: String = switch counter.product {
                            case .cigarettes: String(localized: "not smoked")
                            case .vape: String(localized: "puffs not taken")
                            case .pouches: String(localized: "pouches not used")
                            }
                            StatTile(value: Double(counter.avoided), label: avoided, ground: ground)
                        }
                        StatTile(value: NSDecimalNumber(decimal: snap.moneyKept).doubleValue, label: String(localized: "kept"), ground: ground,
                                 format: { Decimal($0).formatted(.currency(code: code).precision(.fractionLength(2))) })
                    }
                }
                .padding(.top, DX.Space.l)
            }
            .scrollBounceBehavior(.basedOnSize)
            Button("Continue") {
                if !entitlement.isPro, !dayXeroOfferShown {
                    dayXeroOfferShown = true
                    showOffer = true
                } else {
                    onDone()
                }
            }
            .buttonStyle(.dx(.primary, on: ground))
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
        .sensoryFeedback(.success, trigger: shown)
        .onAppear {
            withAnimation(DX.Move.animation(DX.Move.celebrate, reduceMotion: reduceMotion)) { shown = true }
        }
        .fullScreenCover(isPresented: $showOffer, onDismiss: onDone) {
            QuitDayOffer(profile: ctx.store.profile) { showOffer = false }
        }
    }

    private var lessonDone: some View {
        VStack(spacing: DX.Space.m) {
            ScrollView {
                VStack(spacing: 10) {
                    ZStack(alignment: .bottom) {
                        HorizonScene(.path, clarity: clarity, fit: .bottom)
                        XeroView(mood: .calm, stage: 1, size: .scene)
                            .offset(y: shown || reduceMotion ? -4 : 30)
                            .opacity(shown ? 1 : 0)
                    }
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
                    .accessibilityHidden(true)
                    .padding(.top, DX.Space.m)
                    Text("\(session.label) done").dxType(.caption).textCase(.uppercase).foregroundStyle(Read4.muted)
                        .padding(.top, DX.Space.s)
                    Text(verbatim: ctx.text(session.completionText))
                        .dxType(.large)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Read4.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    if let next, !isReplay {
                        Label(next, systemImage: "calendar")
                            .dxType(.footnote).foregroundStyle(Read4.ink)
                            .v4Card()
                            .padding(.top, DX.Space.s)
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            Button("Done", action: onDone)
                .buttonStyle(.dx(.primary, on: .reading))
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
        .sensoryFeedback(.success, trigger: shown)
        .onAppear {
            withAnimation(DX.Move.animation(DX.Move.settle, reduceMotion: reduceMotion)) { shown = true }
        }
    }
}
