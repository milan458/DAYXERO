import DayXeroCore
import StoreKit
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
    /// Program v3: a replay of this one card. It opens on the card and closes after its played screen, so the cards
    /// after it stay as they are.
    var startCard: String?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    private let motion = MotionPolicy()

    @State private var steps: [FlowStep] = []
    /// Program v3: which card each step belongs to (nil for the hand, mission and completion).
    @State private var owners: [String?] = []
    /// Program v3: where "Play" on the hand picks up.
    @State private var resume = 1
    @State private var index = 0
    @State private var record: SessionRecord?
    @State private var completed = false
    /// Program v3: where a one-card replay starts; Back doesn't go before it.
    @State private var firstStep = 0
    /// Program v3: a played card picked on the hand, replayed on its own.
    @State private var replaying: SessionOpen?
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
                    .modifier(DeckCardPanel(color: panelColor))
                    .id(steps[index])
                    .transition(motion.reduce ? .opacity : .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                                       removal: .opacity))
            }
        }
        .padding(.horizontal, DX.Layout.gutter)
        .dxReadableColumn()
        .padding(.top, DX.Space.s)
        .padding(.bottom, DX.Space.xs)
        .foregroundStyle(stepGround.ink)
        .background(pageGround.background.ignoresSafeArea())
        .environment(\.dxGround, stepGround)
        .animation(motion.animation(DX.Move.settle), value: stepGround)
        .animation(motion.animation(DX.Move.settle), value: index)
        .onAppear(perform: start)
        .dxCover(item: $replaying) { item in
            SessionFlowView(sessionId: item.id, profile: profile, isReplay: true, startCard: item.card)
                .captureShielded()
        }
    }

    /// Program v3: this is a replay of one card.
    private var replaysOneCard: Bool { isReplay && startCard != nil && firstStep > 0 }

    /// The deck's own screens carry their close button; beats keep the lesson bar.
    private func showsHeader(_ step: FlowStep) -> Bool {
        switch step {
        case .completion, .hand, .card, .played, .mission, .intro, .cards: false
        default: true
        }
    }

    /// v5 (023-032): the session is played on the table ground, and each card's own screen sits on its coloured
    /// card (`DeckCardPanel`). Day Xero's hold (Q1) stays on apricot and its completion and the finale on sun.
    private var stepGround: DX.Ground {
        guard let session, steps.indices.contains(index) else { return .table }
        switch steps[index] {
        case .hand, .played:
            return .table
        case let .card(id):
            let card = session.deck?.first { $0.id == id }
            return card?.format == .listen ? .table : card?.screenGround ?? .table
        case .completion where session.isDeck && session.id != ProgramV2Access.offerAfter:
            return .table
        case let .beat(id):
            return session.everyBeat.first { $0.id == id }?.sets == "quit_timestamp" ? .apricot : .table
        case .completion:
            let finale = session.beats.contains { $0.sets == "graduated_at" }
            return session.id == ProgramV2Access.offerAfter || (finale && !isReplay) ? .sun : .table
        default:
            return .table
        }
    }

    /// The page behind a card's own screen is the table; the card carries the colour.
    private var pageGround: DX.Ground {
        guard let session, steps.indices.contains(index), case .card = steps[index] else { return stepGround }
        _ = session
        return .table
    }

    /// A card's own screen sits on its coloured card (kit 024).
    private var panelColor: Color? {
        guard let session, steps.indices.contains(index), case let .card(id) = steps[index],
              let card = session.deck?.first(where: { $0.id == id }) else { return nil }
        // v5 (024): the listen card is its own player on the table, not a screen on a coloured panel.
        return card.format == .listen ? nil : card.faceColor
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
        // One card replayed on its own: straight to its first step.
        if isReplay, let startCard, let first = owners.firstIndex(of: startCard) {
            index = first
            firstStep = first
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

    /// "or listen instead" on the intro (033): the lesson ahead becomes the recording, remembered for next time.
    private func listenFromIntro() {
        if let i = steps.firstIndex(of: .cards) {
            lessonFormat = LessonFormat.listen.rawValue
            steps[i] = .audio
        }
        advance()
    }

    private func advance() {
        guard index + 1 < steps.count else { dismiss(); return }
        if replaysOneCard, case let .played(id) = steps[index], id == startCard { dismiss(); return }
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
        guard let session, Self.canGoBack(from: index, in: steps, beats: allBeats(session)),
              !(replaysOneCard && index <= firstStep) else { return }
        index -= 1
        saveStep()
    }

    /// The Back action for a step's own "go back" link, or nil where Back isn't offered.
    private func backAction(_ session: ProgramContent.Session) -> (() -> Void)? {
        guard Self.canGoBack(from: index, in: steps, beats: allBeats(session)), !(replaysOneCard && index <= firstStep) else { return nil }
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
    @ViewBuilder
    private func header(_ session: ProgramContent.Session) -> some View {
        if session.isDeck, let place = deckBeatPlace(session) {
            // v5 (026-030): close, the day's card bar with this card filling by its steps, "Card 5 · Step 1 of 3",
            // then the card's mint tag.
            VStack(alignment: .leading, spacing: 14) {
                DeckNavRow(total: place.total, current: place.position, sub: Double(place.step) / Double(max(place.steps, 1)),
                           label: String(localized: "Card \(place.position) · Step \(place.step) of \(place.steps)"), onClose: close)
                HStack(spacing: 6) {
                    DeckGlyph(card: place.card).frame(width: 14, height: 14)
                    Text(verbatim: place.tag)
                }
                .dxFace(.body, 13, weight: 700)
                .foregroundStyle(Color(hex: 0x1E1A3A))
                .padding(.horizontal, 10)
                .frame(height: 26)
                .background(Color(light: 0xB8EBCD, dark: 0x8FD3AD), in: Capsule())
                .dxArrive(0)
                .id(place.card.id)
            }
            .padding(.bottom, 12)
        } else {
            legacyHeader(session)
        }
    }

    /// Where a deck beat sits: its card, the card's place in the day, and the beat's step among the card's own steps.
    private func deckBeatPlace(_ session: ProgramContent.Session) -> (card: DeckCard, position: Int, total: Int, step: Int, steps: Int, tag: String)? {
        guard owners.indices.contains(index), let owner = owners[index], let place = deckPosition(owner, in: session) else { return nil }
        let own = steps.indices.filter { owners.indices.contains($0) && owners[$0] == owner }.filter {
            if case .beat = steps[$0] { true } else { false }
        }
        guard let k = own.firstIndex(of: index) else { return nil }
        let ctx = context(for: session)
        let title = ctx.text(place.card.title)
        let tag = place.card.format == .breathe || place.card.format == .listen
            ? "\(title) · \(String(localized: "\(place.card.minutes) min"))" : title
        return (place.card, place.position, place.total, k + 1, own.count, tag)
    }

    private func legacyHeader(_ session: ProgramContent.Session) -> some View {
        HStack(spacing: 12) {
            Button(action: close) {
                DXIcon(.close, size: 20, weight: 2.4).foregroundStyle(stepGround.ink)
                    .frame(width: 44, height: 44)
                    .background(stepGround.card2, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(isReplay ? "Close" : "Close. Your place is saved."))
            if Self.canGoBack(from: index, in: steps, beats: allBeats(session)) {
                Button(action: goBack) {
                    DXIcon(.back, size: 20, weight: 2.4).foregroundStyle(stepGround.ink)
                        .frame(width: 44, height: 44)
                        .background(stepGround.card2, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Back"))
                .accessibilityIdentifier("program.session.back")
                .transition(.opacity)
            }
            // Segments for a short session (kit 027), the bar for a long one.
            Group {
                if steps.count <= 8 {
                    DXSteps(count: max(steps.count, 1), current: index)
                } else {
                    DXProgress(Double(index + 1) / Double(max(steps.count, 1)))
                }
            }
                .accessibilityLabel(Text("\(session.label), step \(index + 1) of \(steps.count)"))
            if isReplay {
                Text("Replay").dxType(.caption)
                    .foregroundStyle(stepGround.muted)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(stepGround.card2, in: Capsule())
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .padding(.bottom, DX.Space.s)
    }

    @ViewBuilder
    private func stepView(_ step: FlowStep, session: ProgramContent.Session) -> some View {
        let ctx = context(for: session)
        switch step {
        case .intro:
            SessionIntro(session: session, variant: ctx.variant, isReplay: isReplay, reads: steps.contains(.cards), onBegin: advance,
                         onListen: steps.contains(.cards) && ProgramAudioStep.hasRecording(session, ctx: ctx)
                            ? { listenFromIntro() } : nil,
                         onClose: close)
        case let .beat(id):
            if let beat = allBeats(session).first(where: { $0.id == id }) {
                BeatScreen(beat: beat, ctx: ctx, onDone: advance, onBack: backAction(session))
            }
        case .cards:
            CardStackStep(session: session, ctx: ctx, canListen: ProgramAudioStep.hasRecording(session, ctx: ctx),
                          onListen: { switchLesson(to: .audio) }, onClose: close, onDone: advance)
        case .audio:
            VStack(spacing: DX.Space.xs) {
                if !(session.cards ?? []).isEmpty {
                    Button { switchLesson(to: .cards) } label: {
                        HStack(spacing: 6) {
                            DXIcon(.text, size: 17)
                            Text("Read it in \(ProgramContent.cardStackSeconds) seconds instead")
                        }
                        .dxFace(.body, 14, weight: 600)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(stepGround.ink)
                    .frame(maxWidth: .infinity, minHeight: DX.Layout.touchTarget, alignment: .leading)
                }
                ProgramAudioStep(session: session, ctx: ctx, record: record, onDone: advance)
            }
        case .mission:
            if let mission = session.mission {
                MissionCard(mission: mission, ctx: ctx, learned: (session.recap?.learned ?? []).map { ctx.text($0) },
                            total: session.deck?.count ?? 5, onClose: close) {
                    if !isReplay { store.missionShown(session.id) }
                    advance()
                }
            }
        case .completion:
            SessionCompletion(session: session, ctx: ctx, isReplay: isReplay, onDone: {
                // A rating is asked for as Prep 1 and Day Xero close, the first time each is finished.
                if completed, let moment = ReviewAsk.moment(forSession: session.id) {
                    ReviewPrompt.ask(moment, joined: profile.createdAt, request: requestReview)
                }
                dismiss()
            })
        case .hand:
            let order = session.playOrder(savedForLater: heldCards(session))
            DeckHandView(session: session, ctx: ctx, cards: order, played: playedCards(),
                         next: owners.indices.contains(resume) ? owners[resume] : nil,
                         waitingUntil: owners.indices.contains(resume) ? opensLater(owners[resume], in: session) : nil,
                         replayable: Self.deckProgress(session, store: store)?.played ?? [],
                         onReplay: { replaying = SessionOpen(id: session.id, isReplay: true, card: $0) },
                         onPlay: playFromHand, onClose: close)
        case let .card(id):
            if let place = deckPosition(id, in: session) {
                DeckCardScreen(card: place.card, position: place.position, total: place.total, session: session, ctx: ctx,
                               onDone: advance, onClose: close,
                               onSaveForLater: place.card.canSaveForLater && !isReplay ? { saveForLater(id, session: session) } : nil)
            }
        case let .played(id):
            if let place = deckPosition(id, in: session) {
                let alone = replaysOneCard && id == startCard
                let next = alone ? nil : nextCard(after: id, in: session)
                DeckCardPlayedView(card: place.card, position: place.position, total: place.total,
                                   next: next, nextOpensAt: alone ? nil : opensLater(next?.id, in: session),
                                   doneLabel: alone ? String(localized: "Done") : nil,
                                   ctx: ctx, onNext: advance, onLater: alone ? { dismiss() } : later)
            }
        }
    }

    /// A card, its place in the day's play order (1-based) and the number of cards.
    private func deckPosition(_ id: String, in session: ProgramContent.Session) -> (card: DeckCard, position: Int, total: Int)? {
        let order = session.playOrder(savedForLater: heldCards(session))
        guard let i = order.firstIndex(where: { $0.id == id }) else { return nil }
        return (order[i], i + 1, order.count)
    }

    /// "6:00 PM" when this card is an evening card that hasn't opened yet; nil when it can be played now.
    /// Replays never wait.
    private func opensLater(_ id: String?, in session: ProgramContent.Session, now: Date = .now) -> String? {
        guard !isReplay, let id, let card = session.deck?.first(where: { $0.id == id }), let hour = card.opensAt else { return nil }
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "dx.deckOpenAll") { return nil }
        #endif
        let calendar = Calendar.current
        guard !card.isOpen(hour: calendar.component(.hour, from: now), boundaryHour: profile.dayBoundaryHour) else { return nil }
        let opens = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now) ?? now
        return opens.formatted(date: .omitted, time: .shortened)
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

    var onListen: (() -> Void)?
    var onClose: () -> Void = {}

    /// v5 (033): close, the lesson's art, "Day 7 lesson · 3 min", the title and line, what's inside, and Begin with
    /// "or listen instead" under it.
    var body: some View {
        let g = DX.Ground.table
        VStack(spacing: 0) {
            HStack {
                DXIconButton(.close, label: isReplay ? "Close" : "Close. Your place is saved.", action: onClose)
                Spacer()
            }
            .frame(height: 52)
            .padding(.horizontal, -6)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack(alignment: .bottom) {
                        HorizonScene(.path, clarity: clarity, fit: .bottom)
                        XeroView(mood: .hello, stage: 0, size: .scene).offset(y: -4).dxBob()
                    }
                    .frame(height: 196)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .accessibilityHidden(true)
                    .dxFade()
                    Text(verbatim: meta).dxType(.footnote).foregroundStyle(g.muted)
                        .padding(.top, 22)
                        .dxArrive(1)
                    Text(verbatim: session.title.resolve(variant) ?? "")
                        .dxType(.large)
                        .foregroundStyle(g.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.top, 6)
                        .dxArrive(2)
                    Text(verbatim: session.subtitle.resolve(variant) ?? "").dxType(.body).foregroundStyle(g.muted)
                        .padding(.top, 6)
                        .dxArrive(3)
                    inside.padding(.top, 18)
                }
                .padding(.bottom, DX.Space.m)
            }
            .scrollBounceBehavior(.basedOnSize)
            VStack(spacing: 6) {
                // The header already says Replay; the button just starts it (QW4).
                Button(isReplay ? "Start" : "Begin", action: onBegin)
                    .buttonStyle(.dx(.primary, on: .table))
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                if let onListen {
                    Button(action: onListen) {
                        HStack(spacing: 6) {
                            DXIcon(.headphones, size: 16, weight: 2.4)
                            Text("or listen instead")
                        }
                        .dxFace(.body, 14, weight: 600)
                        .foregroundStyle(g.ink.opacity(0.85))
                        .frame(minHeight: 36)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 10)
            .dxArrive(7)
        }
    }

    /// "Day 7 lesson · 3 min".
    private var meta: String {
        let minutes = reads ? session.readMinutes() : session.durationMinutes
        return "\(session.label) \(String(localized: "lesson")) · \(String(localized: "\(minutes) min"))"
    }

    /// What's inside (033): the read, the activities, today's mission, each with a small paper spot.
    private var inside: some View {
        let g = DX.Ground.table
        let cards = session.cards?.count ?? 0
        var rows: [(DX.Icon, String, String)] = []
        if reads {
            rows.append((.text, String(localized: "A short read"),
                         cards > 0 ? String(AttributedString(localized: "^[\(cards) card](inflect: true), about 2 min").characters) : String(localized: "About 2 min")))
        } else {
            rows.append((.headphones, String(localized: "A short listen"), String(localized: "\(session.durationMinutes) min, read by Xero")))
        }
        if !session.beats.isEmpty { rows.append((.hand, String(localized: "A few activities"), String(localized: "Quick taps, about 1 min"))) }
        if session.mission != nil { rows.append((.flame, String(localized: "Today's mission"), String(localized: "One small thing to try today"))) }
        return VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { i, row in
                HStack(spacing: 12) {
                    DXIcon(row.0, size: 17, weight: 2.4).foregroundStyle(Color(hex: 0x1E1A3A))
                        .frame(width: 34, height: 34)
                        .background(LinearGradient(colors: [Color(hex: 0xFFE2C6), Color(hex: 0xFFC38A)], startPoint: .top, endPoint: .bottom),
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(verbatim: row.1).dxFace(.display, 15, weight: 700).foregroundStyle(g.ink)
                        Text(verbatim: row.2).dxType(.caption).foregroundStyle(g.muted)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12).padding(.vertical, 9)
                .overlay(alignment: .top) { if i > 0 { Rectangle().fill(g.line).frame(height: 1) } }
                .dxArrive(4 + i)
            }
        }
        .background(g.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(g.line, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    /// "SUN 8 NOV · DAY 2": today's date and the session's label.
    private var eyebrow: String {
        "\(Date.now.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))) · \(session.label)"
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
                LessonAudioStep(title: session.title.resolve(ctx.variant) ?? "",
                                subtitle: String(localized: "\(session.label) lesson"), narrator: narrator,
                                startAt: ctx.isReplay ? 0 : record?.audioPosition ?? 0,
                                onPosition: { seconds in
                                    guard !ctx.isReplay, let record else { return }
                                    record.audioPosition = seconds
                                    record.audioVariant = variantName
                                    try? context.save()
                                },
                                onFinish: { finished = true }, onDone: onDone)
                    .frame(maxHeight: .infinity)
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

/// The day's mission (v5, 031): the heading, the honey mission card with Xero climbing up behind it and gripping its
/// top edge, what you learned today as stamped rows, a link to log tonight, and "I'll try it".
///
/// Motion (031): the heading arrives; the card rises in (900 ms settle); Xero climbs up behind it (900 ms at 360 ms) and
/// his hands land on the edge (700 ms spring at 1.15 s, light haptic). The card's words arrive inside it, then the
/// learned rows one by one with their stamps, then the link and the button.
struct MissionCard: View {
    let mission: ProgramContent.Mission
    let ctx: BeatContext
    var learned: [String] = []
    var total = 5
    var onClose: () -> Void = {}
    let onDone: () -> Void

    @Environment(LogRouter.self) private var log: LogRouter?
    @State private var gripped = false
    private let ground = DX.Ground.table

    var body: some View {
        VStack(spacing: 0) {
            DeckNavRow(total: total, current: total + 1, onClose: onClose)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Your mission for today").dxType(.title).foregroundStyle(ground.ink)
                        .accessibilityAddTraits(.isHeader)
                        .dxArrive(0)
                    ZStack(alignment: .topTrailing) {
                        // Xero climbs up behind the card: his head and shoulders over the top edge.
                        XeroView(mood: .hello, stage: 0, points: 118)
                            .frame(width: 118, height: 78, alignment: .top)
                            .clipped()
                            .offset(x: -18, y: -66)
                            .dxSettle(3)
                            .accessibilityHidden(true)
                        missionCard
                        // ...and his two hands grip the card's top edge.
                        HStack(spacing: 46) {
                            Capsule().fill(Color(hex: 0xFF7155)).frame(width: 20, height: 13)
                            Capsule().fill(Color(hex: 0xFF7155)).frame(width: 20, height: 13)
                        }
                        .shadow(color: Color(hex: 0xE85A3E).opacity(0.5), radius: 0, y: 2)
                        .offset(x: -27, y: -6)
                        .scaleEffect(gripped ? 1 : 0.4)
                        .opacity(gripped ? 1 : 0)
                        .accessibilityHidden(true)
                    }
                    .padding(.top, 74)
                    if !learned.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What you learned today").dxType(.headline).foregroundStyle(ground.ink)
                                .dxArrive(6)
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(Array(learned.enumerated()), id: \.offset) { i, line in
                                    HStack(alignment: .top, spacing: 12) {
                                        ZStack {
                                            GridShape(d: DXBadge.scallop(cx: 12, cy: 12, r: 11.5, n: 10, a: 1.4), grid: 24).fill(Color(hex: 0xFF9A5C))
                                            DXIcon(.check, size: 12, weight: 3.2).foregroundStyle(.white)
                                        }
                                        .frame(width: 22, height: 22)
                                        Text(verbatim: line).dxType(.footnote).foregroundStyle(ground.ink)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(.vertical, 12)
                                    .overlay(alignment: .top) { if i > 0 { Rectangle().fill(ground.line).frame(height: 1) } }
                                    .dxArrive(7 + i)
                                }
                            }
                            .padding(.horizontal, 16)
                            .background(ground.card, in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous).strokeBorder(ground.line, lineWidth: 1))
                        }
                        .padding(.top, 26)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, DX.Space.m)
                .padding(.horizontal, DX.Layout.gutter)
            }
            .padding(.horizontal, -DX.Layout.gutter)
            .scrollBounceBehavior(.basedOnSize)
            VStack(spacing: 6) {
                if mission.logType != nil, let log {
                    Button {
                        onDone()
                        log.open(.menu)
                    } label: {
                        HStack(spacing: 4) {
                            Text("If you do use, log it tonight")
                            DXIcon(.chev, size: 14, weight: 2.6)
                        }
                        .dxFace(.body, 15, weight: 600)
                        .foregroundStyle(ground.ink.opacity(0.85))
                        .frame(minHeight: 40)
                    }
                    .buttonStyle(.plain)
                    .dxArrive(10)
                }
                Button("I'll try it", action: onDone)
                    .buttonStyle(.dx(.primary, on: .table))
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                    .dxArrive(11)
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: gripped) { _, now in now }
        .task {
            try? await Task.sleep(for: .seconds(1.15))
            withAnimation(.timingCurve(0.3, 1.4, 0.5, 1, duration: 0.7)) { gripped = true }
        }
    }

    /// The honey card: the 029 medal's gold, its pale face to its face gold, with the gold rim.
    private var missionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's mission").dxFace(.body, 14, weight: 600).foregroundStyle(Color(hex: 0x5A3A0A))
                .dxArrive(2)
            Text(verbatim: ctx.text(mission.text))
                .dxType(.title)
                .foregroundStyle(DX.Fill.navy)
                .fixedSize(horizontal: false, vertical: true)
                .dxArrive(3)
            Text(mission.followUp == nil ? "It stays on your Today card until the next session."
                 : "When you log it, we'll ask two quick questions. It stays on your Today card until the next session.")
                .dxType(.footnote)
                .foregroundStyle(Color(hex: 0x5A3A0A))
                .fixedSize(horizontal: false, vertical: true)
                .dxArrive(4)
        }
        .padding(.horizontal, 20).padding(.top, 24).padding(.bottom, 22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [Color(hex: 0xFFF1C2), Color(hex: 0xFFD966)], startPoint: .top, endPoint: .bottom),
                    in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous).strokeBorder(Color(hex: 0xF5B83D), lineWidth: 2))
        .shadow(color: Color(red: 150 / 255, green: 100 / 255, blue: 20 / 255).opacity(0.18), radius: 12, y: 10)
        .accessibilityElement(children: .combine)
        .dxSettle()
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
        case let .scheduled(.trialEnds(date)):
            String(localized: "Next: \(next.label) · \(title), after your free trial, on \(date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))")
        default: nil
        }
    }

    /// After a free session, for someone without the full program. No session is free now (16 Nov 2026), so this
    /// stays nil; kept for the recap's layout should a free taste come back.
    private var opensFullProgram: String? {
        guard FullProgram.isFree(sessionId: session.id), let next = ctx.store.content?.session(after: session.id),
              ProgramV2Access.needsUpgrade(next.id, isPro: entitlement.isPro) else { return nil }
        return String(localized: "\(next.label) starts the full program. You can try it free for \(FullProgram.trialDays) days.")
    }

    var body: some View {
        if session.id == ProgramV2Access.offerAfter, !isReplay {
            dayXeroDone
        } else if !session.isDeck, session.beats.contains(where: { $0.sets == "graduated_at" }), !isReplay {
            // F18: the graduation session ends on the finale, the only screen with confetti.
            FinaleView(profile: ctx.store.profile, label: session.label, onDone: onDone)
        } else {
            // v5 (032): every other day, prep or after, closes on the medal, the rays and Xero cheering.
            DeckRecapView(session: session, ctx: ctx, isReplay: isReplay, next: next, opensFullProgram: opensFullProgram, onDone: onDone)
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
                    // v5 (032, 039): the Day Xero medal stamps in before its rays, Xero cheering beside it.
                    ZStack {
                        SlowRays(color: Color(light: 0xFFF3C4, dark: 0xE8B24A))
                            .frame(width: 300, height: 300)
                        DXBadge(.xero, size: 150)
                            .scaleEffect(shown || motion.reduce ? 1 : 1.8)
                            .rotationEffect(.degrees(shown || motion.reduce ? 0 : -14))
                            .opacity(shown ? 1 : 0)
                        XeroView(mood: .cheer, stage: 0, points: 96)
                            .offset(x: 112, y: 62)
                            .dxSettle(2)
                    }
                    .frame(height: 250)
                    .accessibilityHidden(true)
                    Text(verbatim: ctx.text(session.completionText))
                        .dxType(.large).foregroundStyle(ground.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    if let mission = session.mission {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Today's mission").dxType(.caption).foregroundStyle(ground.muted)
                            Text(verbatim: ctx.text(mission.text)).dxType(.body).foregroundStyle(ground.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(DX.Fill.onColourCard(for: ground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                    HStack(spacing: 8) {
                        StatTile(value: Double(snap.daysClear), label: snap.daysClear == 1 ? String(localized: "day since Day Xero") : String(localized: "days since Day Xero"),
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
        .dxCover(isPresented: $showOffer, onDismiss: onDone) {
            QuitDayOffer(profile: ctx.store.profile) { showOffer = false }
        }
    }
}

/// A card's own screen on its coloured card (v5, kit 024): radius 28, a soft lift; nothing for other steps.
private struct DeckCardPanel: ViewModifier {
    let color: Color?

    func body(content: Content) -> some View {
        if let color {
            content
                .padding(16)
                .background(color, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .shadow(color: Color(light: (0x4A2810, 0.14), dark: (0x000000, 0.4)), radius: 14, y: 10)
                .padding(.bottom, 6)
        } else {
            content
        }
    }
}

extension SessionFlowView {
    /// A deck session's cards in the order they're played, which are finished and which is next, for Today's
    /// program list (20 Nov 2026). It walks the same steps as `deckSteps` and counts a card as played once its
    /// "played" screen is behind the saved step, as `playedCards` does.
    @MainActor
    static func deckProgress(_ session: ProgramContent.Session, store: ProgramStore)
        -> (cards: [DeckCard], played: Set<String>, next: String?)? {
        guard let deck = session.deck, !deck.isEmpty else { return nil }
        let held = Set(deck.filter { $0.canSaveForLater && store.answer(laterKey($0.id)) != nil }.map(\.id))
        let order = session.playOrder(savedForLater: held)
        let record = store.record(session.id)
        if record?.completedAt != nil { return (order, Set(order.map(\.id)), nil) }
        let ctx = BeatContext(store: store, session: session, variant: store.variant, nrtActive: store.nrtActive(),
                              placeholders: store.placeholders(), isReplay: false)
        let resume = max(record?.currentStep ?? 1, 1)
        // Step 0 is the hand; each card then takes its before-beats, its own screen, its beats and its played screen.
        var index = 1
        var played = Set<String>()
        var next: String?
        for card in order {
            let count = card.before.filter { ctx.shows($0) }.count + 1 + card.beats.filter { ctx.shows($0) }.count + 1
            if index + count - 1 < resume {
                played.insert(card.id)
            } else if next == nil {
                next = card.id
            }
            index += count
        }
        return (order, played, next)
    }
}
