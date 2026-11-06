import DayXeroCore
import SwiftData
import SwiftUI

/// One program v2 session, a step at a time (handoff 4.2): intro, before-audio activities, the lesson (the 90-second
/// card stack, or the audio; MON-04), the activities, today's mission, then the completion moment. Every change is
/// saved, so closing and reopening resumes exactly there; closing never asks "are you sure".
struct SessionFlowView: View {
    let sessionId: String
    let profile: UserProfile
    /// Replays show saved answers, never change unlock state, never re-run commits and don't count as finishing.
    var isReplay = false

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    private let motion = MotionPolicy()

    @State private var steps: [FlowStep] = []
    /// Program v3: which card each step belongs to (nil for the hand, mission and completion).
    @State private var owners: [String?] = []
    /// Program v3: where "Play" on the hand picks up.
    @State private var resume = 1
    @State private var index = 0
    @State private var record: SessionRecord?
    @State private var completed = false
    /// Read the card stack or listen to the recording (MON-04). Reading is the default.
    @AppStorage(LessonFormat.key) private var lessonFormat = LessonFormat.read.rawValue

    enum FlowStep: Hashable {
        case intro, beat(String), cards, audio, mission, completion
        /// Program v3: the day's hand, a card's own screen, and the "card played" screen after it.
        case hand, card(String), played(String)
    }

    private var store: ProgramStore { ProgramStore(context: context, profile: profile) }
    private var session: ProgramContent.Session? { store.content?.session(sessionId) }

    var body: some View {
        VStack(spacing: 0) {
            if let session, steps.indices.contains(index) {
                if showsHeader(steps[index]) { header(session) }
                stepView(steps[index], session: session)
                    .id(steps[index])
                    .transition(motion.reduce ? .opacity : .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                                       removal: .opacity))
            }
        }
        .padding(.horizontal, DX.Layout.gutter)
        .dxReadableColumn()
        .padding(.top, DX.Space.s)
        .padding(.bottom, DX.Space.xs)
        .foregroundStyle(Read4.ink)
        .background(stepGround.background.ignoresSafeArea())
        .animation(motion.animation(DX.Move.settle), value: stepGround)
        .animation(motion.animation(DX.Move.settle), value: index)
        .onAppear(perform: start)
    }

    /// The deck's own screens carry their close button; beats keep the lesson bar.
    private func showsHeader(_ step: FlowStep) -> Bool {
        switch step {
        case .completion, .hand, .card, .played: false
        default: true
        }
    }

    /// Most steps are on the reading ground. Day Xero's hold (Q1) is on apricot and its completion (Q2) on sun.
    /// The deck: the hand, reveal, myth and played screens on violet, a listen or activity on its card's ground,
    /// a day's recap on sun.
    private var stepGround: DX.Ground {
        guard let session, steps.indices.contains(index) else { return .reading }
        switch steps[index] {
        case .hand, .played:
            return .violet
        case let .card(id):
            return session.deck?.first { $0.id == id }?.screenGround ?? .violet
        case .completion where session.isDeck && session.id != ProgramV2Access.offerAfter:
            return .sun
        case let .beat(id):
            return session.everyBeat.first { $0.id == id }?.sets == "quit_timestamp" ? .apricot : .reading
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
        if session.isDeck { startDeck(session); return }
        let ctx = context(for: session)
        let visible = { (beats: [Beat]) in beats.filter { ctx.shows($0) }.map { FlowStep.beat($0.id) } }
        // The lesson sits where the audio always did (MON-04): the 90-second card stack by default, or the recording
        // for someone who chose "Listen instead". No recording in the bundle, no audio step (S27.14): the cards carry
        // the lesson. With a recording, Continue still waits for the audio to end.
        let lesson = Self.lessonStep(hasCards: !(session.cards ?? []).isEmpty,
                                     hasAudio: ProgramAudioStep.hasRecording(session, ctx: ctx),
                                     format: LessonFormat(rawValue: lessonFormat) ?? .read)
        let before: [FlowStep] = [.intro] + visible(session.beatsBeforeAudio)
        var built: [FlowStep] = before + (lesson.map { [$0] } ?? []) + visible(session.beatsAfterAudio)
        if session.mission != nil { built.append(.mission) }
        built.append(.completion)
        steps = built
        let firstAfterAudio = before.count + (lesson == nil ? 0 : 1)
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
            case "cards": .cards
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

    // MARK: The deck (program v3)

    /// The cards held for later (P3's guided use), from saved answers.
    private func heldCards(_ session: ProgramContent.Session) -> Set<String> {
        Set((session.deck ?? []).filter { $0.canSaveForLater && store.answer(Self.laterKey($0.id)) != nil }.map(\.id))
    }

    static func laterKey(_ cardId: String) -> String { "\(cardId).later" }

    /// The hand, then each card: its before-beats, its own screen, its beats and the played screen; then the mission
    /// and the recap.
    private func deckSteps(_ session: ProgramContent.Session) -> (steps: [FlowStep], owners: [String?]) {
        let ctx = context(for: session)
        var built: [FlowStep] = [.hand]
        var owned: [String?] = [nil]
        for card in session.playOrder(savedForLater: heldCards(session)) {
            let cardSteps: [FlowStep] = card.before.filter { ctx.shows($0) }.map { .beat($0.id) } + [.card(card.id)]
                + card.beats.filter { ctx.shows($0) }.map { .beat($0.id) } + [.played(card.id)]
            built += cardSteps
            owned += cardSteps.map { _ in card.id }
        }
        if session.mission != nil { built.append(.mission); owned.append(nil) }
        built.append(.completion); owned.append(nil)
        return (built, owned)
    }

    private func startDeck(_ session: ProgramContent.Session) {
        let deck = deckSteps(session)
        steps = deck.steps
        owners = deck.owners
        let record = store.open(session, firstStepAfterAudio: 1)
        self.record = record
        index = 0
        if isReplay || record.completedAt != nil {
            resume = 1
        } else {
            resume = min(max(record.currentStep, 1), steps.count - 1)
        }
        #if DEBUG
        if UserDefaults.standard.object(forKey: "dx.sessionStep") != nil {
            index = min(max(UserDefaults.standard.integer(forKey: "dx.sessionStep"), 0), steps.count - 1)
        }
        #endif
        Analytics.track(isReplay || record.completedAt != nil ? .programReplayStarted(sessionId: session.id)
                        : .programSessionStarted(sessionId: session.id, variant: context(for: session).variant.rawValue))
    }

    /// "Play" on the hand: picks up where the person left off.
    private func playFromHand() {
        index = min(max(resume, 1), steps.count - 1)
        saveStep()
        finishIfCompletion()
    }

    /// "Later" on a played card: closes, and the next open starts at the next card.
    private func later() {
        if !isReplay, let record, record.completedAt == nil {
            record.currentStep = min(index + 1, steps.count - 1)
            try? context.save()
        }
        dismiss()
    }

    /// P3's guided use, saved for later: it and the cards that wait for it move after the rest, and the next card opens.
    private func saveForLater(_ cardId: String, session: ProgramContent.Session) {
        store.save(Self.laterKey(cardId), .text("later"), session: session.id)
        let playedBefore = Set(owners.prefix(index).compactMap { $0 })
        let deck = deckSteps(session)
        steps = deck.steps
        owners = deck.owners
        let next = deck.owners.indices.first { i in
            guard let owner = deck.owners[i] else { return i > 0 }
            return !playedBefore.contains(owner) && !heldCards(session).contains(owner)
                && !(session.deck?.first { $0.id == cardId }?.laterTakes.contains(owner) ?? false)
        } ?? steps.count - 1
        index = next
        resume = next
        saveStep()
    }

    /// Cards whose played screen comes before where the person is.
    private func playedCards() -> Set<String> {
        if record?.completedAt != nil, !isReplay { return Set(owners.compactMap { $0 }) }
        var done = Set<String>()
        for (i, step) in steps.enumerated() where i < resume {
            if case let .played(id) = step { done.insert(id) }
        }
        return done
    }

    private func saveStep() {
        if !isReplay, let record, record.completedAt == nil, index > 0 {
            record.currentStep = index
            try? context.save()
        }
    }

    private func finishIfCompletion() {
        if steps.indices.contains(index), steps[index] == .completion, !isReplay, record?.completedAt == nil, let session {
            store.complete(session.id)
            completed = true
            let minutes = Int(Date.now.timeIntervalSince(record?.startedAt ?? .now) / 60)
            Analytics.track(.programSessionCompleted(sessionId: session.id, minutesBucket: Analytics.minutesBucket(minutes)))
        }
    }

    /// Which lesson step a session gets (MON-04): cards unless the person chose to listen and there's a recording.
    static func lessonStep(hasCards: Bool, hasAudio: Bool, format: LessonFormat) -> FlowStep? {
        switch (hasCards, hasAudio) {
        case (true, true): format == .listen ? .audio : .cards
        case (true, false): .cards
        case (false, true): .audio
        case (false, false): nil
        }
    }

    /// "Listen instead" or "Read it instead": swaps the lesson step in place and remembers the choice for next time.
    private func switchLesson(to step: FlowStep) {
        guard steps.indices.contains(index), steps[index] == .cards || steps[index] == .audio else { return }
        lessonFormat = (step == .audio ? LessonFormat.listen : .read).rawValue
        steps[index] = step
    }

    private func advance() {
        guard index + 1 < steps.count else { dismiss(); return }
        index += 1
        saveStep()
        finishIfCompletion()
    }

    /// Back is offered on every step after the first, except straight after a commit: going back over a hold would
    /// let someone redo it, and holds such as Day Xero's set a timestamp. The completion screen has no header.
    static func canGoBack(from index: Int, in steps: [FlowStep], beats: [Beat]) -> Bool {
        guard index > 0, steps.indices.contains(index), steps[index] != .completion else { return false }
        if case let .beat(id) = steps[index - 1], beats.first(where: { $0.id == id })?.type == .commit { return false }
        return true
    }

    private func goBack() {
        guard let session, Self.canGoBack(from: index, in: steps, beats: allBeats(session)) else { return }
        index -= 1
        saveStep()
    }

    /// The Back action for a step's own "go back" link, or nil where Back isn't offered.
    private func backAction(_ session: ProgramContent.Session) -> (() -> Void)? {
        guard Self.canGoBack(from: index, in: steps, beats: allBeats(session)) else { return nil }
        return { goBack() }
    }

    private func allBeats(_ session: ProgramContent.Session) -> [Beat] {
        session.everyBeat
    }

    private func close() {
        // The hand is step 0: closing there keeps the place saved further in.
        if !isReplay, let record, index > 0 || !(session?.isDeck ?? false) { record.currentStep = index; try? context.save() }
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
            if Self.canGoBack(from: index, in: steps, beats: allBeats(session)) {
                Button(action: goBack) {
                    Image(systemName: "chevron.left").font(.system(size: 16, weight: .bold)).foregroundStyle(Read4.ink)
                        .frame(width: 44, height: 44)
                        .background(Read4.surface, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Back"))
                .accessibilityIdentifier("program.session.back")
                .transition(.opacity)
            }
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
            SessionIntro(session: session, variant: ctx.variant, isReplay: isReplay, reads: steps.contains(.cards), onBegin: advance)
        case let .beat(id):
            if let beat = allBeats(session).first(where: { $0.id == id }) {
                BeatScreen(beat: beat, ctx: ctx, onDone: advance, onBack: backAction(session))
            }
        case .cards:
            CardStackStep(session: session, ctx: ctx, canListen: ProgramAudioStep.hasRecording(session, ctx: ctx),
                          onListen: { switchLesson(to: .audio) }, onDone: advance)
        case .audio:
            VStack(spacing: DX.Space.xs) {
                if !(session.cards ?? []).isEmpty {
                    Button { switchLesson(to: .cards) } label: {
                        Label("Read it in \(ProgramContent.cardStackSeconds) seconds instead", systemImage: "rectangle.stack")
                            .dxFont(14, weight: 600, style: .footnote)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Read4.accent)
                    .frame(maxWidth: .infinity, minHeight: DX.Layout.touchTarget, alignment: .leading)
                }
                ProgramAudioStep(session: session, ctx: ctx, record: record, onDone: advance)
            }
        case .mission:
            if let mission = session.mission {
                MissionCard(mission: mission, ctx: ctx) {
                    if !isReplay { store.missionShown(session.id) }
                    advance()
                }
            }
        case .completion:
            SessionCompletion(session: session, ctx: ctx, isReplay: isReplay, onDone: { dismiss() })
        case .hand:
            let order = session.playOrder(savedForLater: heldCards(session))
            DeckHandView(session: session, ctx: ctx, cards: order, played: playedCards(),
                         next: owners.indices.contains(resume) ? owners[resume] : nil,
                         onPlay: playFromHand, onClose: close)
        case let .card(id):
            if let place = deckPosition(id, in: session) {
                DeckCardScreen(card: place.card, position: place.position, total: place.total, session: session, ctx: ctx,
                               onDone: advance, onClose: close,
                               onSaveForLater: place.card.canSaveForLater && !isReplay ? { saveForLater(id, session: session) } : nil)
            }
        case let .played(id):
            if let place = deckPosition(id, in: session) {
                DeckCardPlayedView(card: place.card, position: place.position, total: place.total,
                                   next: nextCard(after: id, in: session), ctx: ctx, onNext: advance, onLater: later)
            }
        }
    }

    /// A card, its place in the day's play order (1-based) and the number of cards.
    private func deckPosition(_ id: String, in session: ProgramContent.Session) -> (card: DeckCard, position: Int, total: Int)? {
        let order = session.playOrder(savedForLater: heldCards(session))
        guard let i = order.firstIndex(where: { $0.id == id }) else { return nil }
        return (order[i], i + 1, order.count)
    }

    /// The card played after this one, nil after the last.
    private func nextCard(after id: String, in session: ProgramContent.Session) -> DeckCard? {
        let order = session.playOrder(savedForLater: heldCards(session))
        guard let i = order.firstIndex(where: { $0.id == id }), order.indices.contains(i + 1) else { return nil }
        return order[i + 1]
    }
}

// MARK: - Intro

struct SessionIntro: View {
    let session: ProgramContent.Session
    let variant: ProgramVariant
    let isReplay: Bool
    /// The lesson is the 90-second card stack rather than the audio (MON-04).
    var reads = false
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
                        if reads {
                            // MON-04: the read version's own length, not the audio's. "3 min · 90-second read" read as two
                            // different lengths for one session (QW4); the card stack says its own 90 seconds.
                            if session.mission != nil {
                                Label("\(session.readMinutes()) min · A short read, a few activities and today's mission",
                                      systemImage: "rectangle.stack")
                            } else {
                                Label("\(session.readMinutes()) min · A short read and a few activities",
                                      systemImage: "rectangle.stack")
                            }
                        } else if session.mission != nil {
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
            // The header already says Replay; the button just starts it (QW4).
            Button(isReplay ? "Start" : "Begin", action: onBegin)
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
/// only when it ends (no skipping). A session without a recording has no audio step at all (S27.14), so the fallback
/// below only shows if a recording disappears between building the steps and reaching this one.
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
        Self.bundledURL(name, ctx: ctx)
    }

    private static func bundledURL(_ name: String, ctx: BeatContext) -> URL? {
        let base = (name as NSString).deletingPathExtension, ext = (name as NSString).pathExtension
        return Bundle.main.url(forResource: base, withExtension: ext, subdirectory: ctx.store.content?.audio.folder)
            ?? Bundle.main.url(forResource: base, withExtension: ext)
    }

    /// Whether the recording for the person's version of this session is in the bundle.
    static func hasRecording(_ session: ProgramContent.Session, ctx: BeatContext) -> Bool {
        ctx.store.hasRecording(session)
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
                noRecording
            }
        }
    }

    /// Only reached if the recording vanished after the steps were built: the title and Continue, no promises.
    private var noRecording: some View {
        VStack(alignment: .leading, spacing: DX.Space.m) {
            Text(verbatim: session.title.resolve(ctx.variant) ?? "").v4Text(.title)
            Button("Continue", action: onDone).buttonStyle(.dx(.primary, on: .reading)).dynamicTypeSize(...DynamicTypeSize.accessibility1)
            Spacer(minLength: 0)
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
        // Top-anchored, with Xero at card size and "Got it" right under the card (S27.14).
        VStack(alignment: .leading, spacing: DX.Space.m) {
            XeroView(mood: .hello, size: .card)
                .accessibilityHidden(true)
                .padding(.top, DX.Space.m)
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
            Button("Got it", action: onDone)
                .buttonStyle(.dx(.primary, on: .reading))
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            Spacer(minLength: 0)
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

    private let motion = MotionPolicy()
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

    /// After the last free session (Prep 3), for someone without the full program: "Prep 4 starts the full program…".
    private var opensFullProgram: String? {
        guard FullProgram.isFree(sessionId: session.id), let next = ctx.store.content?.session(after: session.id),
              ProgramV2Access.needsUpgrade(next.id, isPro: entitlement.isPro) else { return nil }
        return String(localized: "\(next.label) starts the full program. You can try it free for \(FullProgram.trialDays) days.")
    }

    private var clarity: Int {
        let profile = ctx.store.profile
        let stats = ProgressStats(quitDay: profile.quitDay, baselines: [], clock: DayClock(boundaryHour: profile.dayBoundaryHour))
        return stats.isPrep(at: .now) ? CrewGrowth.prepClarity : CrewGrowth.clarity(daysClear: stats.daysClear(at: .now))
    }

    var body: some View {
        if session.id == ProgramV2Access.offerAfter, !isReplay {
            dayXeroDone
        } else if session.isDeck {
            DeckRecapView(session: session, ctx: ctx, isReplay: isReplay, next: next, opensFullProgram: opensFullProgram, onDone: onDone)
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
                        .scaleEffect(shown || motion.reduce ? 1 : DX.Move.celebrateFromScale)
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
                        StatTile(value: Double(snap.daysClear), label: snap.daysClear == 1 ? String(localized: "day since Quit Day") : String(localized: "days since Quit Day"),
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
            withAnimation(motion.animation(DX.Move.celebrate)) { shown = true }
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
                            .offset(y: shown || motion.reduce ? -4 : 30)
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
                    if let opensFullProgram, !isReplay {
                        // MON-01: the end of the free taste says what comes next, before the paywall does.
                        Text(opensFullProgram).dxType(.footnote).foregroundStyle(Read4.muted)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
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
            withAnimation(motion.animation(DX.Move.settle)) { shown = true }
        }
    }
}
