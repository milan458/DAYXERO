import DayXeroCore
import SwiftUI

// Program v3 (6 Nov 2026): the prep days and Day Xero as a hand of five cards. Mockups F1–F9 in design/program-deck:
// the hand (F1), a listen (F2), the reveal grid with Go deeper (F3), myth or fact (F4), an activity (F5), the card
// played (F6) and the day's recap (F7). SessionFlowView walks the steps; these are the screens.

extension DeckCard.Format {
    /// The label on the card's face.
    var label: String {
        switch self {
        case .listen: String(localized: "Listen")
        case .reveal: String(localized: "Reveal")
        case .myth: String(localized: "Myth or fact")
        case .activity: String(localized: "Try")
        case .breathe: String(localized: "Breathe")
        }
    }

    var symbol: String {
        switch self {
        case .listen: "headphones"
        case .reveal: "questionmark"
        case .myth: "circle.lefthalf.filled"
        case .activity: "pencil"
        case .breathe: "wind"
        }
    }
}

extension DeckCard {
    /// The ground the card's own screen sits on.
    var screenGround: DX.Ground {
        switch format {
        case .reveal, .myth: return .violet
        case .listen: return ground.flatMap(DX.Ground.init(rawValue:)) ?? .apricot
        case .activity: return ground.flatMap(DX.Ground.init(rawValue:)) ?? .mint
        case .breathe: return ground.flatMap(DX.Ground.init(rawValue:)) ?? .sky
        }
    }

    /// The colour of the card's face in the hand.
    var faceGround: DX.Ground {
        switch format {
        case .reveal: .sky
        case .myth: .sun
        case .breathe: .sky
        case .listen: screenGround == .violet ? .violet : .apricot
        case .activity: screenGround
        }
    }

    /// "Card 2 of 5 · Reveal · 5 min".
    func eyebrow(position: Int, of total: Int) -> String {
        String(localized: "Card \(position) of \(total) · \(format.label) · \(minutes) min").uppercased()
    }
}

/// The close button every deck screen carries in its top corner.
struct DeckCloseButton: View {
    let ground: DX.Ground
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark").font(.system(size: 16, weight: .bold)).foregroundStyle(ground.ink)
                .frame(width: 44, height: 44)
                .background(DX.Fill.onColourCard(for: ground), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Close. Your place is saved."))
    }
}

/// The top line of a deck screen: close, an eyebrow, and an optional trailing note.
struct DeckTopBar: View {
    let ground: DX.Ground
    let eyebrow: String
    var trailing: String?
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            DeckCloseButton(ground: ground, action: onClose)
            Text(verbatim: eyebrow).dxType(.caption).foregroundStyle(ground.muted)
                .lineLimit(2).frame(maxWidth: .infinity, alignment: .leading)
            if let trailing {
                Text(verbatim: trailing).dxFont(14, weight: 700, style: .footnote).foregroundStyle(ground.ink)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .padding(.bottom, DX.Space.s)
    }
}

// MARK: - F1 Today's hand

struct DeckHandView: View {
    let session: ProgramContent.Session
    let ctx: BeatContext
    let cards: [DeckCard]
    let played: Set<String>
    /// The card the next tap plays, nil when every card is played.
    let next: String?
    /// "6:00 PM" while the next card is an evening card that hasn't opened yet.
    var waitingUntil: String?
    let onPlay: () -> Void
    let onClose: () -> Void

    @State private var selected: String?
    private let ground = DX.Ground.violet
    private let motion = MotionPolicy()

    private var focus: DeckCard? {
        let id = selected ?? next ?? cards.last?.id
        return cards.first { $0.id == id }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DeckTopBar(ground: ground, eyebrow: "\(session.label) · \(String(localized: "Today's hand"))".uppercased(),
                       trailing: String(localized: "\(played.count) of \(cards.count) played"), onClose: onClose)
            Text(verbatim: ctx.text(session.title)).dxType(.large).foregroundStyle(ground.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(verbatim: ctx.text(session.subtitle)).dxType(.body).foregroundStyle(ground.muted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
            fan
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .padding(.top, DX.Space.s)
            if let focus {
                info(focus)
            }
            Spacer(minLength: DX.Space.s)
            if let waitingUntil, let next, let index = cards.firstIndex(where: { $0.id == next }) {
                // Evening cards open at 6 pm; the day keeps its place until then.
                Label(String(localized: "Card \(index + 1) opens at \(waitingUntil). Your place is saved."), systemImage: "moon.stars")
                    .dxType(.footnote).foregroundStyle(ground.ink)
                    .frame(maxWidth: .infinity, minHeight: DX.Layout.touchTarget)
                    .padding(.horizontal, 12)
                    .background(Color(hex: 0x2A1C6E), in: Capsule())
                    .accessibilityIdentifier("program.deck.waiting")
            } else {
                Button(action: onPlay) { Text(verbatim: ctaTitle) }
                    .buttonStyle(.dx(.primary, on: ground))
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                    .accessibilityIdentifier("program.deck.play")
            }
        }
        .foregroundStyle(ground.ink)
    }

    private var ctaTitle: String {
        guard let next, let index = cards.firstIndex(where: { $0.id == next }) else {
            return ctx.isReplay ? String(localized: "Start again") : String(localized: "Finish the day")
        }
        if ctx.isReplay { return String(localized: "Start again") }
        return played.isEmpty ? String(localized: "Play the first card") : String(localized: "Play card \(index + 1)")
    }

    private var fan: some View {
        let count = cards.count
        return ZStack {
            ForEach(Array(cards.enumerated()), id: \.element.id) { i, card in
                let mid = Double(count - 1) / 2
                let angle = (Double(i) - mid) * 13
                let isFocus = card.id == focus?.id
                Button {
                    withAnimation(motion.animation(DX.Move.settle)) { selected = card.id }
                } label: {
                    face(card, number: i + 1)
                }
                .buttonStyle(.plain)
                .rotationEffect(.degrees(angle), anchor: UnitPoint(x: 0.5, y: 1.6))
                .offset(y: isFocus ? -40 : 0)
                .zIndex(isFocus ? 10 : Double(i))
                .accessibilityLabel(Text(verbatim: label(card, number: i + 1)))
                .accessibilityAddTraits(isFocus ? .isSelected : [])
            }
        }
        .padding(.top, 50)
    }

    private func label(_ card: DeckCard, number: Int) -> String {
        let state = played.contains(card.id) ? String(localized: "played") : (card.id == next ? String(localized: "next") : "")
        return [String(localized: "Card \(number)"), card.format.label, ctx.text(card.title), state].filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    private func face(_ card: DeckCard, number: Int) -> some View {
        let face = card.faceGround
        let done = played.contains(card.id)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(verbatim: card.format.label.uppercased()).dxFont(12, weight: 800, style: .caption2)
                Spacer(minLength: 0)
                if done { Image(systemName: "checkmark").font(.system(size: 14, weight: .heavy)) }
            }
            Spacer(minLength: 0)
            Image(systemName: card.format.symbol).font(.system(size: 30, weight: .bold)).frame(maxWidth: .infinity)
            Spacer(minLength: 0)
            Text(verbatim: ctx.text(card.title)).dxFont(14, weight: 700, style: .footnote).lineLimit(3)
                .multilineTextAlignment(.leading)
            Text(verbatim: String(localized: "\(card.minutes) min")).dxFont(12, weight: 700, style: .caption2)
        }
        .foregroundStyle(face.ink)
        .padding(12)
        .frame(width: 126, height: 184)
        .background(face.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            if card.id == focus?.id {
                RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(DX.Ground.sun.background, lineWidth: 4)
            }
        }
        .shadow(color: .black.opacity(0.28), radius: 12, x: 0, y: 8)
        .opacity(done && card.id != focus?.id ? 0.85 : 1)
    }

    private func info(_ card: DeckCard) -> some View {
        let number = (cards.firstIndex { $0.id == card.id } ?? 0) + 1
        let state = played.contains(card.id) ? String(localized: "Played") : (card.id == next ? String(localized: "Next") : String(localized: "Later today"))
        return VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: "\(card.eyebrow(position: number, of: cards.count)) · \(state.uppercased())")
                .dxType(.caption).foregroundStyle(DX.Ground.sun.background)
            Text(verbatim: ctx.text(card.title)).dxType(.headline).foregroundStyle(ground.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let intro = card.intro {
                Text(verbatim: ctx.text(intro)).dxType(.footnote).foregroundStyle(ground.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(hex: 0x2A1C6E), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - A card's own screen

struct DeckCardScreen: View {
    let card: DeckCard
    let position: Int
    let total: Int
    let session: ProgramContent.Session
    let ctx: BeatContext
    let onDone: () -> Void
    let onClose: () -> Void
    /// Set for a card the person may save for later (P3's guided use).
    var onSaveForLater: (() -> Void)?

    var body: some View {
        switch card.format {
        case .listen:
            DeckListenView(card: card, position: position, total: total, session: session, ctx: ctx,
                           onDone: onDone, onClose: onClose, onSaveForLater: onSaveForLater)
        case .reveal:
            DeckRevealView(card: card, position: position, total: total, ctx: ctx, onDone: onDone, onClose: onClose)
        case .myth:
            DeckMythView(card: card, position: position, total: total, ctx: ctx, onDone: onDone, onClose: onClose)
        case .activity, .breathe:
            DeckActivityIntro(card: card, position: position, total: total, ctx: ctx, onDone: onDone, onClose: onClose)
        }
    }
}

// MARK: - F2 Listen

/// The listen card. Until the recordings are in the bundle it shows the script to read, chapter by chapter, with a
/// note that the audio is on its way. With a recording, it plays with captions, and the button waits for the end.
struct DeckListenView: View {
    let card: DeckCard
    let position: Int
    let total: Int
    let session: ProgramContent.Session
    let ctx: BeatContext
    let onDone: () -> Void
    let onClose: () -> Void
    var onSaveForLater: (() -> Void)?

    @State private var finished = false
    @State private var reading = false

    private var ground: DX.Ground { card.screenGround }

    private var recording: URL? {
        guard let naming = ctx.store.content?.audio else { return nil }
        let name = naming.file(session: card.audioKey, variant: session.audio.pick(for: ctx.variant, nrtActive: ctx.nrtActive))
        let base = (name as NSString).deletingPathExtension, ext = (name as NSString).pathExtension
        return Bundle.main.url(forResource: base, withExtension: ext, subdirectory: naming.folder)
            ?? Bundle.main.url(forResource: base, withExtension: ext)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DeckTopBar(ground: ground, eyebrow: card.eyebrow(position: position, of: total), onClose: onClose)
            if let recording, !reading {
                VStack(spacing: DX.Space.s) {
                    LessonAudioStep(title: ctx.text(card.title),
                                    narrator: LessonNarrator(segments: captions, url: recording, seconds: Double(card.minutes * 60)),
                                    startAt: 0, onPosition: { _ in }, onFinish: { finished = true })
                    Button(String(localized: "Read it instead")) { reading = true }
                        .buttonStyle(.dx(.quiet, on: ground))
                }
                .frame(maxHeight: .infinity)
            } else {
                script
            }
            buttons(hasRecording: recording != nil && !reading)
        }
        .foregroundStyle(ground.ink)
    }

    /// The script as captions for the recording: one segment per paragraph, spread over the track.
    private var captions: [(start: Double, text: String)] {
        let paragraphs = (card.script?.chapters ?? []).flatMap { ProgramInline.paragraphs(ctx.text($0.text), ctx.variant) }
        let seconds = Double(card.minutes * 60)
        let total = max(paragraphs.reduce(0) { $0 + $1.count }, 1)
        var start = 0.0
        return paragraphs.map { p in
            defer { start += seconds * Double(p.count) / Double(total) }
            return (start, p)
        }
    }

    private var script: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DX.Space.s) {
                Text(verbatim: ctx.text(card.title)).dxType(.large).foregroundStyle(ground.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                if let intro = card.intro {
                    Text(verbatim: ctx.text(intro)).dxType(.body).foregroundStyle(ground.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if recording == nil {
                    Label(String(localized: "The audio is on its way. Read it for now."), systemImage: "headphones")
                        .dxFont(14, weight: 700, style: .footnote)
                        .foregroundStyle(ground.ink)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(DX.Fill.onColourCard(for: ground), in: Capsule())
                }
                ForEach(Array((card.script?.chapters ?? []).enumerated()), id: \.offset) { i, chapter in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(verbatim: String(localized: "Chapter \(i + 1)").uppercased()).dxType(.caption).foregroundStyle(ground.muted)
                        Text(verbatim: chapter.title).dxType(.headline).foregroundStyle(ground.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        ForEach(Array(ProgramInline.paragraphs(ctx.text(chapter.text), ctx.variant).enumerated()), id: \.offset) { _, paragraph in
                            Text(verbatim: paragraph).dxFont(18, weight: 450, style: .body).foregroundStyle(ground.ink)
                                .lineSpacing(5)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.top, DX.Space.s)
                }
                if let after = card.after {
                    Text(verbatim: ctx.text(after)).dxType(.title).foregroundStyle(ground.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, DX.Space.m)
                }
            }
            .padding(.bottom, DX.Space.m)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func buttons(hasRecording: Bool) -> some View {
        VStack(spacing: 8) {
            if !hasRecording || finished || ctx.isReplay {
                Button(action: onDone) { Text(verbatim: ctx.text(card.commit)) }
                    .buttonStyle(.dx(.primary, on: ground))
                    .accessibilityIdentifier("program.deck.commit")
            }
            if let onSaveForLater, !ctx.isReplay {
                Button(String(localized: "Save it for later"), action: onSaveForLater)
                    .buttonStyle(.dx(.quiet, on: ground))
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .padding(.top, DX.Space.s)
    }
}

// MARK: - F3 Reveal

struct DeckRevealView: View {
    let card: DeckCard
    let position: Int
    let total: Int
    let ctx: BeatContext
    let onDone: () -> Void
    let onClose: () -> Void

    @State private var open: Set<Int> = []
    @State private var deeper: Int?
    private let ground = DX.Ground.violet
    private let motion = MotionPolicy()

    /// The person's own triggers first (Prep 2 shows four of six), from onboarding.
    private var reveals: [DeckCard.Reveal] { card.reveals(forTriggers: ctx.store.profile.triggersRaw) }
    private var allOpen: Bool { open.count >= reveals.count || ctx.isReplay }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DeckTopBar(ground: ground, eyebrow: card.eyebrow(position: position, of: total),
                       trailing: String(localized: "\(open.count) of \(reveals.count)"), onClose: onClose)
            ScrollView {
                VStack(alignment: .leading, spacing: DX.Space.s) {
                    Text(verbatim: ctx.text(card.title)).dxType(.title).foregroundStyle(ground.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text(verbatim: card.intro.map { ctx.text($0) } ?? String(localized: "Guess the answer first. Then turn the card over."))
                        .dxType(.footnote).foregroundStyle(ground.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(Array(reveals.enumerated()), id: \.offset) { i, reveal in
                            tile(reveal, index: i)
                        }
                    }
                    .padding(.top, 6)
                }
                .padding(.bottom, DX.Space.m)
            }
            .scrollBounceBehavior(.basedOnSize)
            VStack(spacing: 8) {
                if allOpen {
                    Button(action: onDone) { Text(verbatim: ctx.text(card.commit)) }
                        .buttonStyle(.dx(.primary, on: ground))
                        .accessibilityIdentifier("program.deck.commit")
                } else {
                    Text(String(localized: "Turn over every card to go on"))
                        .dxType(.footnote).foregroundStyle(ground.muted)
                        .frame(maxWidth: .infinity, minHeight: DX.Layout.touchTarget)
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .padding(.top, DX.Space.s)
        }
        .foregroundStyle(ground.ink)
        .sheet(item: Binding(get: { deeper.map(DeeperIndex.init) }, set: { deeper = $0?.id })) { item in
            deeperSheet(reveals[item.id], index: item.id)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private struct DeeperIndex: Identifiable { let id: Int }

    @ViewBuilder
    private func tile(_ reveal: DeckCard.Reveal, index: Int) -> some View {
        let isOpen = open.contains(index) || ctx.isReplay
        let face = DX.Ground.sky
        if isOpen {
            VStack(alignment: .leading, spacing: 8) {
                Text(verbatim: ctx.text(reveal.front)).dxFont(12, weight: 700, style: .caption2).foregroundStyle(face.muted)
                    .fixedSize(horizontal: false, vertical: true)
                Text(verbatim: ctx.text(reveal.answer)).dxFont(16, weight: 700, style: .callout).foregroundStyle(face.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Button { deeper = index } label: {
                    Text(String(localized: "Go deeper")).dxFont(14, weight: 700, style: .footnote)
                        .frame(maxWidth: .infinity, minHeight: DX.Layout.touchTarget)
                        .foregroundStyle(DX.Ground.violet.ink)
                        .background(Color(hex: 0x1E1A3A), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 240, alignment: .topLeading)
            .background(face.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .transition(motion.reduce ? .opacity : .scale(scale: 0.92).combined(with: .opacity))
        } else {
            Button {
                withAnimation(motion.animation(DX.Move.settle)) { _ = open.insert(index) }
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    Text(verbatim: String(localized: "Question \(index + 1)").uppercased())
                        .dxFont(12, weight: 700, style: .caption2).foregroundStyle(DX.Ground.sun.background)
                    Text(verbatim: ctx.text(reveal.front)).dxFont(18, weight: 800, style: .headline).foregroundStyle(ground.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Text(String(localized: "Turn over")).dxFont(14, weight: 700, style: .footnote).foregroundStyle(ground.ink)
                        .frame(maxWidth: .infinity, minHeight: DX.Layout.touchTarget)
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(ground.ink.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [6, 5])))
                }
                .padding(14)
                .frame(maxWidth: .infinity, minHeight: 240, alignment: .topLeading)
                .background(Color(hex: 0x2A1C6E), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: String(localized: "Question \(index + 1): \(ctx.text(reveal.front)). Turn over")))
        }
    }

    private func deeperSheet(_ reveal: DeckCard.Reveal, index: Int) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DX.Space.s) {
                Text(verbatim: String(localized: "Go deeper · Question \(index + 1)").uppercased()).dxType(.caption).foregroundStyle(Read4.muted)
                Text(verbatim: ctx.text(reveal.front)).dxType(.title).foregroundStyle(Read4.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(verbatim: ctx.text(reveal.deeper)).dxFont(17, weight: 400, style: .body).foregroundStyle(Read4.ink)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                if let keep = reveal.keep {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "Keep in mind")).dxType(.caption).textCase(.uppercase).foregroundStyle(Read4.muted)
                        Text(verbatim: ctx.text(keep)).dxType(.headline).foregroundStyle(Read4.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .v4Card()
                }
                if let source = reveal.source {
                    Text(verbatim: String(localized: "Source: \(ctx.text(source))")).dxType(.footnote).foregroundStyle(Read4.muted)
                }
            }
            .padding(DX.Layout.gutter)
            .padding(.top, DX.Space.m)
        }
        .background(Read4.background.ignoresSafeArea())
    }
}

// MARK: - F4 Myth or fact

struct DeckMythView: View {
    let card: DeckCard
    let position: Int
    let total: Int
    let ctx: BeatContext
    let onDone: () -> Void
    let onClose: () -> Void

    @State private var index = 0
    @State private var pick: DeckCard.Statement.Answer?
    private let ground = DX.Ground.violet
    private let motion = MotionPolicy()

    private var statements: [DeckCard.Statement] { card.statements ?? [] }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DeckTopBar(ground: ground, eyebrow: card.eyebrow(position: position, of: total),
                       trailing: statements.isEmpty ? nil : String(localized: "\(index + 1) of \(statements.count)"), onClose: onClose)
            if statements.indices.contains(index) {
                statementCard(statements[index])
                    .id(index)
                    .transition(motion.reduce ? .opacity : .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
            }
            buttons
        }
        .foregroundStyle(ground.ink)
        .animation(motion.animation(DX.Move.settle), value: index)
        .animation(motion.animation(DX.Move.settle), value: pick)
    }

    private func truth(_ statement: DeckCard.Statement) -> DeckCard.Statement.Answer {
        statement.answer.resolve(ctx.variant) ?? .myth
    }

    private func statementCard(_ statement: DeckCard.Statement) -> some View {
        let answered = pick != nil
        let face: DX.Ground = !answered ? .sun : (truth(statement) == .fact ? .sky : truth(statement) == .myth ? .apricot : .sun)
        return ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(verbatim: String(localized: "Statement \(index + 1) of \(statements.count)").uppercased())
                    .dxType(.caption).foregroundStyle(face.muted)
                Text(verbatim: "\u{201C}\(ctx.text(statement.text))\u{201D}")
                    .dxFont(answered ? 24 : 32, weight: 800, style: .title1).foregroundStyle(face.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let pick {
                    HStack(spacing: 8) {
                        Text(verbatim: verdictLabel(truth(statement)))
                            .dxFont(14, weight: 800, style: .footnote).foregroundStyle(Color(hex: 0xFFF8EE))
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Color(hex: 0x1E1A3A), in: Capsule())
                        Text(verbatim: called(pick, statement)).dxFont(14, weight: 700, style: .footnote).foregroundStyle(face.muted)
                    }
                    Text(verbatim: ctx.text(statement.verdict)).dxType(.headline).foregroundStyle(face.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(verbatim: ctx.text(statement.explanation)).dxType(.body).foregroundStyle(face.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if let source = statement.source {
                        Text(verbatim: String(localized: "Source: \(ctx.text(source))")).dxType(.footnote).foregroundStyle(face.muted)
                    }
                } else {
                    Text(String(localized: "What do you think? Some are partly true."))
                        .dxType(.footnote).foregroundStyle(face.muted)
                        .padding(.top, DX.Space.s)
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(face.background, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.25), radius: 18, x: 0, y: 12)
            .padding(.vertical, 8)
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxHeight: .infinity)
    }

    private func verdictLabel(_ answer: DeckCard.Statement.Answer) -> String {
        switch answer {
        case .myth: String(localized: "Myth")
        case .fact: String(localized: "Fact")
        case .partly: String(localized: "Partly true")
        }
    }

    private func called(_ pick: DeckCard.Statement.Answer, _ statement: DeckCard.Statement) -> String {
        let truth = truth(statement)
        if truth == .partly { return String(localized: "Either answer works here") }
        return pick == truth ? String(localized: "You called it") : String(localized: "Most people think so at first")
    }

    private var buttons: some View {
        VStack(spacing: 8) {
            if pick == nil {
                HStack(spacing: 12) {
                    Button { pick = .myth } label: { Label(String(localized: "Myth"), systemImage: "chevron.left") }
                        .buttonStyle(.dx(.secondary, on: ground))
                    Button { pick = .fact } label: { Label(String(localized: "Fact"), systemImage: "chevron.right") }
                        .buttonStyle(.dx(.secondary, on: ground))
                }
            } else if index + 1 < statements.count {
                Button(String(localized: "Next statement")) {
                    index += 1
                    pick = nil
                }
                .buttonStyle(.dx(.primary, on: ground))
            } else {
                Button(action: onDone) { Text(verbatim: ctx.text(card.commit)) }
                    .buttonStyle(.dx(.primary, on: ground))
                    .accessibilityIdentifier("program.deck.commit")
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .padding(.top, DX.Space.s)
    }
}

// MARK: - F5 An activity's opening

/// A try or breathe card opens on its title and what it asks, then its beats run with the usual frame.
struct DeckActivityIntro: View {
    let card: DeckCard
    let position: Int
    let total: Int
    let ctx: BeatContext
    let onDone: () -> Void
    let onClose: () -> Void

    private var ground: DX.Ground { card.screenGround }

    var body: some View {
        VStack(alignment: .leading, spacing: DX.Space.s) {
            DeckTopBar(ground: ground, eyebrow: card.eyebrow(position: position, of: total), onClose: onClose)
            Spacer(minLength: 0)
            Image(systemName: card.format.symbol).font(.system(size: 40, weight: .bold)).foregroundStyle(ground.ink)
                .frame(width: 88, height: 88)
                .background(DX.Fill.onColourCard(for: ground), in: Circle())
                .accessibilityHidden(true)
            Text(verbatim: ctx.text(card.title)).dxType(.large).foregroundStyle(ground.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if let intro = card.intro {
                Text(verbatim: ctx.text(intro)).dxType(.body).foregroundStyle(ground.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Button(String(localized: "Start"), action: onDone)
                .buttonStyle(.dx(.primary, on: ground))
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                .accessibilityIdentifier("program.deck.start")
        }
        .foregroundStyle(ground.ink)
    }
}

// MARK: - F6 Card played

struct DeckCardPlayedView: View {
    let card: DeckCard
    let position: Int
    let total: Int
    let next: DeckCard?
    /// "6:00 PM" when the next card is an evening card that hasn't opened yet.
    var nextOpensAt: String?
    let ctx: BeatContext
    let onNext: () -> Void
    let onLater: () -> Void

    @State private var rating: String?
    @State private var landed = false
    private let ground = DX.Ground.violet
    private let motion = MotionPolicy()
    static let ratings = ["Not for me", "Okay", "Good", "Really helped"]

    /// An activity's own words are its button here; a listen, reveal or myth already said them.
    private var activity: Bool { card.format == .activity || card.format == .breathe }

    var body: some View {
        VStack(spacing: DX.Space.s) {
            HStack {
                Text(verbatim: String(localized: "\(position) of \(total) played").uppercased()).dxType(.caption).foregroundStyle(ground.muted)
                Spacer()
            }
            ScrollView {
                VStack(spacing: DX.Space.s) {
                    face
                        .padding(.top, DX.Space.m)
                    Text(String(localized: "Card played")).dxType(.title).foregroundStyle(ground.ink)
                        .accessibilityAddTraits(.isHeader)
                    if !activity {
                        Text(verbatim: String(localized: "You said: \u{201C}\(ctx.text(card.commit))\u{201D}"))
                            .dxType(.body).foregroundStyle(ground.muted)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    ratingRow
                    if let next {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 10, style: .continuous).fill(next.faceGround.background)
                                .frame(width: 40, height: 56)
                                .overlay(Image(systemName: next.format.symbol).foregroundStyle(next.faceGround.ink))
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(verbatim: String(localized: "Next · \(next.format.label) · \(next.minutes) min").uppercased())
                                    .dxType(.caption).foregroundStyle(ground.muted)
                                Text(verbatim: ctx.text(next.title)).dxType(.headline).foregroundStyle(ground.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.top, DX.Space.s)
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            VStack(spacing: 8) {
                if let nextOpensAt {
                    // The evening card waits for the evening: the place is saved and the hand says when.
                    Text(verbatim: String(localized: "The next card opens at \(nextOpensAt). It's meant for the evening."))
                        .dxType(.footnote).foregroundStyle(ground.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Button(String(localized: "Back to my day"), action: onLater)
                        .buttonStyle(.dx(.primary, on: ground))
                        .accessibilityIdentifier("program.deck.later")
                } else {
                    Button(action: onNext) { Text(verbatim: primaryTitle) }
                        .buttonStyle(.dx(.primary, on: ground))
                        .accessibilityIdentifier("program.deck.next")
                    if next != nil {
                        Button(String(localized: "Later. Back to my hand"), action: onLater)
                            .buttonStyle(.dx(.quiet, on: ground))
                    }
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
        .foregroundStyle(ground.ink)
        .sensoryFeedback(.success, trigger: landed)
        .onAppear {
            if case let .text(saved)? = ctx.answer("\(card.id).rating") { rating = saved }
            withAnimation(motion.animation(DX.Move.celebrate)) { landed = true }
        }
    }

    private var primaryTitle: String {
        if activity { return ctx.text(card.commit) }
        return next == nil ? String(localized: "See today's recap") : String(localized: "Play the next card")
    }

    private var face: some View {
        let g = card.faceGround
        return VStack(alignment: .leading, spacing: 6) {
            Text(verbatim: card.format.label.uppercased()).dxFont(12, weight: 800, style: .caption2)
            Spacer(minLength: 0)
            Image(systemName: "checkmark").font(.system(size: 44, weight: .heavy)).frame(maxWidth: .infinity)
            Spacer(minLength: 0)
            Text(verbatim: ctx.text(card.title)).dxFont(14, weight: 700, style: .footnote).lineLimit(3)
        }
        .foregroundStyle(g.ink)
        .padding(14)
        .frame(width: 140, height: 204)
        .background(g.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(DX.Ground.sun.background, lineWidth: 4))
        .rotationEffect(.degrees(landed || motion.reduce ? -6 : -14))
        .scaleEffect(landed || motion.reduce ? 1 : 1.08)
        .accessibilityHidden(true)
    }

    private var ratingRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "How was this card? Optional")).dxFont(14, weight: 700, style: .footnote).foregroundStyle(ground.muted)
            HStack(spacing: 8) {
                ForEach(Self.ratings, id: \.self) { value in
                    let on = rating == value
                    Button {
                        rating = value
                        ctx.save("\(card.id).rating", .text(value))
                    } label: {
                        Text(LocalizedStringKey(value)).dxFont(13, weight: 700, style: .caption1)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .foregroundStyle(on ? Color(hex: 0x1E1A3A) : ground.ink)
                            .background(on ? DX.Ground.sun.background : DX.Fill.onColourCard(for: ground),
                                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
        }
        .padding(14)
        .background(Color(hex: 0x2A1C6E), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.top, DX.Space.s)
    }
}

// MARK: - F7 The day's recap

struct DeckRecapView: View {
    let session: ProgramContent.Session
    let ctx: BeatContext
    let isReplay: Bool
    /// "Next: Prep 2 · …, tomorrow", from the completion screen's own logic.
    let next: String?
    /// MON-01's line after the last free day.
    let opensFullProgram: String?
    let onDone: () -> Void

    @State private var shown = false
    private let ground = DX.Ground.sun
    private let motion = MotionPolicy()

    private var statLines: [String] {
        (session.recap?.statLines ?? []).compactMap { $0.resolve(ctx.variant) }
            .compactMap { ctx.placeholders.fill(ProgramInline.resolve($0, ctx.variant)) }
    }

    var body: some View {
        VStack(spacing: DX.Space.m) {
            ScrollView {
                VStack(alignment: .leading, spacing: DX.Space.m) {
                    HStack(spacing: 6) {
                        ForEach(Array((session.deck ?? []).enumerated()), id: \.offset) { i, card in
                            Image(systemName: "checkmark").font(.system(size: 18, weight: .heavy))
                                .foregroundStyle(card.faceGround.ink)
                                .frame(width: 46, height: 64)
                                .background(card.faceGround == .sun ? DX.Fill.raised : card.faceGround.background,
                                            in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .scaleEffect(shown || motion.reduce ? 1 : 0.8)
                                .opacity(shown || motion.reduce ? 1 : 0)
                                .animation(motion.animation(DX.Move.celebrate).delay(Double(i) * 0.09), value: shown)
                        }
                    }
                    .accessibilityHidden(true)
                    .padding(.top, DX.Space.s)
                    Text(verbatim: String(localized: "\(session.label), done.")).dxType(.large).foregroundStyle(ground.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text(verbatim: ctx.text(session.completionText)).dxType(.body).foregroundStyle(ground.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if let learned = session.recap?.learned, !learned.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(String(localized: "What you learned today")).dxType(.caption).textCase(.uppercase).foregroundStyle(ground.muted)
                            ForEach(Array(learned.enumerated()), id: \.offset) { i, line in
                                HStack(alignment: .firstTextBaseline, spacing: 10) {
                                    Text(verbatim: "\(i + 1)").dxFont(13, weight: 800, style: .caption1)
                                        .foregroundStyle(DX.Ground.sun.background)
                                        .frame(width: 24, height: 24)
                                        .background(Color(hex: 0x1E1A3A), in: Circle())
                                    Text(verbatim: ctx.text(line)).dxType(.body).foregroundStyle(ground.ink)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    if !statLines.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(statLines, id: \.self) { line in
                                Text(verbatim: line).dxType(.headline).foregroundStyle(ground.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(DX.Fill.onColourCard(for: ground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                    if let mission = session.mission {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(String(localized: "For the rest of today")).dxType(.caption).textCase(.uppercase).foregroundStyle(Read4.muted)
                            Text(verbatim: ctx.text(mission.text)).dxType(.headline).foregroundStyle(Read4.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(DX.Fill.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                    if !isReplay, let tomorrow = session.recap?.tomorrow {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "Tomorrow")).dxType(.caption).textCase(.uppercase).foregroundStyle(ground.muted)
                            Text(verbatim: ctx.text(tomorrow)).dxType(.body).foregroundStyle(ground.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    if let next, !isReplay {
                        Label(next, systemImage: "calendar").dxType(.footnote).foregroundStyle(ground.ink)
                    }
                    if let opensFullProgram, !isReplay {
                        Text(opensFullProgram).dxType(.footnote).foregroundStyle(ground.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            Button(isReplay ? String(localized: "Done") : String(localized: "See you tomorrow"), action: onDone)
                .buttonStyle(.dx(.primary, on: ground))
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
        .foregroundStyle(ground.ink)
        .sensoryFeedback(.success, trigger: shown)
        .onAppear { shown = true }
    }
}
