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
        case .breathe: String(localized: "Try")
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
    /// v5 (023-031): the session sits on the table; reveal and myth read in the table's ink on their coloured card.
    var screenGround: DX.Ground {
        switch format {
        case .reveal, .myth: return .table
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

    /// v5: the card's colour on the table, in the hand and as its own screen's card (kit 023: listen apricot, reveal
    /// blue, myth coral, try green, breathe blue; deep versions of each in dark).
    /// v5 (023): one colour per card type, shared by every session screen. Listen apricot, Try mint, Reveal sky, Myth
    /// or fact rose; the plan card takes the plan's honey (the gold of the 029 medal and the 031 mission), so the two
    /// Try cards never read as twins. Dark deepens each a step.
    var faceColor: Color {
        switch format {
        case .listen: Color(light: 0xFFC38A, dark: 0xF3B47E)
        case .breathe: Color(light: 0x9FE3BC, dark: 0x8FD3AD)
        case .reveal: Color(light: 0x9CCBFF, dark: 0x8EBBEC)
        case .myth: Color(light: 0xFFB9A6, dark: 0xEFA894)
        case .activity: Color(light: 0xFFDB85, dark: 0xF5CF78)
        }
    }

    /// The back of the card in the hand (dark: a dusk tint of its colour, so only the front card glows).
    var backColor: Color {
        switch format {
        case .listen: Color(light: 0xFFC38A, dark: 0x93684E)
        case .breathe: Color(light: 0x9FE3BC, dark: 0x5A8574)
        case .reveal: Color(light: 0x9CCBFF, dark: 0x5A7698)
        case .myth: Color(light: 0xFFB9A6, dark: 0x92675F)
        case .activity: Color(light: 0xFFDB85, dark: 0x947043)
        }
    }

    /// Words on a card face: the table's ink.
    var faceInk: Color { DX.Ground.table.ink }

    /// "Card 2 of 5 · Reveal · 5 min".
    func eyebrow(position: Int, of total: Int) -> String {
        String(localized: "Card \(position) of \(total) · \(format.label) · \(minutes) min")
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

// MARK: - F1 Today's hand (v5, 023)

/// Today's hand: the title and length, the prep stamps so far, the other cards standing level behind (icons only), and
/// the card to play drawn out in front.
///
/// Motion (023): title, line and stamps arrive (600 ms, 90 ms stagger). The back cards deal in from below one by one
/// (760 ms settle each, 120 ms apart, from 300 ms); the front card rises level in front of them (900 ms at 820 ms) and,
/// on a Listen card, Xero in his headphones settles in front of its sun (700 ms at 1.2 s) and sways to the music. The
/// button arrives last. A light haptic as each card lands, a medium one for the front card.
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

    @State private var dealt = 0
    @State private var front = false
    @Environment(\.colorScheme) private var scheme
    private let ground = DX.Ground.table
    private let motion = MotionPolicy()

    private var focus: DeckCard? { cards.first { $0.id == (next ?? cards.last?.id) } }

    private var prepNumber: Int? {
        guard session.phaseId == "prep" else { return nil }
        return Int(session.label.filter(\.isNumber))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                DXIconButton(.close, label: "Close. Your place is saved.", action: onClose)
                Spacer()
                if !played.isEmpty {
                    Text("\(played.count) of \(cards.count) played").dxType(.footnote).foregroundStyle(ground.muted)
                }
            }
            .frame(height: 52)
            .padding(.horizontal, -6)
            VStack(alignment: .leading, spacing: 6) {
                Text(verbatim: ctx.text(session.title)).dxType(.large).foregroundStyle(ground.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .dxArrive(0)
                Text(verbatim: lengthLine).dxType(.footnote).foregroundStyle(ground.muted)
                    .dxArrive(1)
            }
            .padding(.top, 8)
            if let n = prepNumber {
                HStack(spacing: 8) {
                    ForEach(1...max(n, 1), id: \.self) { i in
                        DXBadge(.prep, n: i, state: i < n ? .earned : .next(nil), size: 46)
                    }
                    Text("Today").dxType(.footnote).foregroundStyle(ground.muted).padding(.leading, 8)
                }
                .padding(.top, 18)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Prep stamps: \(n - 1) earned, \(session.label) today"))
                .dxArrive(2)
            }
            fan
                .frame(maxWidth: .infinity)
                .frame(height: 420, alignment: .top)
                .padding(.top, prepNumber == nil ? 40 : 26)
            Spacer(minLength: 0)
            Group {
                if let waitingUntil, let next, let index = cards.firstIndex(where: { $0.id == next }) {
                    // Evening cards open at 6 pm; the day keeps its place until then.
                    Label(String(localized: "Card \(index + 1) opens at \(waitingUntil). Your place is saved."), systemImage: "moon.stars")
                        .dxType(.footnote).foregroundStyle(ground.ink)
                        .frame(maxWidth: .infinity, minHeight: DX.Layout.touchTarget)
                        .padding(.horizontal, 12)
                        .background(DX.Ground.table.card, in: Capsule())
                        .accessibilityIdentifier("program.deck.waiting")
                } else {
                    Button(action: onPlay) { Text(verbatim: ctaTitle) }
                        .buttonStyle(.dx(.primary, on: ground))
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                        .accessibilityIdentifier("program.deck.play")
                }
            }
            .dxArrive(0, delay: 1.6)
        }
        .foregroundStyle(ground.ink)
        .sensoryFeedback(.impact(weight: .light), trigger: dealt)
        .sensoryFeedback(.impact(weight: .medium), trigger: front) { _, now in now }
        .task {
            guard !motion.reduce else { dealt = 4; front = true; return }
            try? await Task.sleep(for: .milliseconds(300 + 600))
            for _ in 0..<min(cards.count - 1, 4) {
                dealt += 1
                try? await Task.sleep(for: .milliseconds(120))
            }
            try? await Task.sleep(for: .milliseconds(200))
            front = true
        }
    }

    /// "Prep 4 · 5 cards · about 28 min".
    private var lengthLine: String {
        let minutes = cards.reduce(0) { $0 + $1.minutes }
        let count = String(AttributedString(localized: "^[\(cards.count) card](inflect: true)").characters)
        return "\(session.label) · \(count) · \(String(localized: "about \(minutes) min"))"
    }

    private var ctaTitle: String {
        guard let next, let index = cards.firstIndex(where: { $0.id == next }) else {
            return ctx.isReplay ? String(localized: "Start again") : String(localized: "Finish the day")
        }
        if ctx.isReplay { return String(localized: "Start again") }
        return String(localized: "Play card \(index + 1)")
    }

    /// Four cards standing level behind (the outer two a step lower), the focus card drawn out in front.
    private var fan: some View {
        let back = cards.filter { $0.id != focus?.id }.prefix(4)
        let xs: [CGFloat] = [-113, -38, 38, 113], ys: [CGFloat] = [16, 0, 0, 16]
        return ZStack(alignment: .top) {
            ForEach(Array(back.enumerated()), id: \.element.id) { k, card in
                backCard(card)
                    .offset(x: xs[min(k, 3)], y: ys[min(k, 3)])
                    .modifier(Deal(index: k))
            }
            if let focus {
                frontCard(focus)
                    .padding(.top, 100)
                    .modifier(Lift())
            }
        }
        .frame(width: 310)
    }

    private func backCard(_ card: DeckCard) -> some View {
        let number = (cards.firstIndex { $0.id == card.id } ?? 0) + 1
        return VStack {
            // The icon on a soft spot (dark: the card's bright colour, so the icon still reads as the card's).
            DeckGlyph(card: card).frame(width: 19, height: 19).foregroundStyle(DX.Fill.navy)
                .frame(width: 36, height: 36)
                .background(scheme == .dark ? card.faceColor : Color(hex: 0x1E1A3A).opacity(0.1), in: Circle())
            if played.contains(card.id) {
                DXIcon(.check, size: 16, weight: 3).foregroundStyle(DX.Fill.navy).padding(.top, 4)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 14)
        .frame(width: 84, height: 196)
        .background(card.backColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color(light: (0x3C2814, 0.12), dark: (0x000000, 0.42)), radius: 9, y: 8)
        .accessibilityElement()
        .accessibilityLabel(Text(verbatim: label(card, number: number)))
    }

    private func frontCard(_ card: DeckCard) -> some View {
        let number = (cards.firstIndex { $0.id == card.id } ?? 0) + 1
        return VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottom) {
                LinearGradient(colors: [card.format == .listen ? Color(light: 0xFFD6AC, dark: 0xF7C595) : card.faceColor, card.faceColor],
                               startPoint: .top, endPoint: .bottom)
                if card.format == .listen {
                    Circle()
                        .fill(RadialGradient(colors: [Color(hex: 0xFFE48A), Color(hex: 0xFFD35E), Color(hex: 0xFFC94F)],
                                             center: .center, startRadius: 0, endRadius: 76))
                        .frame(width: 152, height: 152)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .padding(.top, 20)
                    XeroView(mood: .calm, stage: 0, points: 158, pose: .headphones)
                        .dxBob()
                        .offset(y: 7)
                        .dxSettle(delay: 1.2)
                } else {
                    DeckGlyph(card: card)
                        .frame(width: 56, height: 56)
                        .foregroundStyle(DX.Fill.navy)
                        .frame(width: 112, height: 112)
                        .background(Color(hex: 0xFFFFFF).opacity(0.45), in: Circle())
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(height: 180)
            .clipped()
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 7) {
                    DeckGlyph(card: card).frame(width: 17, height: 17)
                    Text(verbatim: "\(card.format.label) · \(String(localized: "\(card.minutes) min"))")
                }
                .dxFace(.body, 14, weight: 600)
                .foregroundStyle(Color(hex: 0x3A2410))
                Text(verbatim: ctx.text(card.title))
                    .dxFace(.display, 26, weight: 800, tracking: -0.5)
                    .foregroundStyle(DX.Fill.navy)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 16).padding(.horizontal, 20).padding(.bottom, 22)
        }
        .frame(width: 284)
        .background(card.faceColor)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Color(light: (0x3C2814, 0.10), dark: (0x000000, 0.45)), radius: 2, y: 2)
        .shadow(color: Color(light: (0x3C2814, 0.16), dark: (0x000000, 0.45)), radius: 12, y: 14)
        .shadow(color: Color(light: (0x3C2814, 0.20), dark: (0x000000, 0.55)), radius: 25, y: 30)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: label(card, number: number)))
    }

    private func label(_ card: DeckCard, number: Int) -> String {
        let state = played.contains(card.id) ? String(localized: "played") : (card.id == next ? String(localized: "next") : "")
        return [String(localized: "Card \(number)"), card.format.label, ctx.text(card.title), state].filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    /// A back card deals in from below and stands in its place (760 ms settle, 120 ms apart, from 300 ms).
    private struct Deal: ViewModifier {
        let index: Int
        @State private var in_ = false
        private let motion = MotionPolicy()

        func body(content: Content) -> some View {
            content
                .offset(y: in_ || motion.reduce ? 0 : 420)
                .opacity(in_ || motion.reduce ? 1 : 0)
                .onAppear {
                    withAnimation(motion.animation(DX.Move.settle.speed(0.9 / 0.76)).delay(0.3 + Double(index) * 0.12)) { in_ = true }
                }
        }
    }

    /// The front card rises level in front (900 ms settle at 820 ms).
    private struct Lift: ViewModifier {
        @State private var up = false
        private let motion = MotionPolicy()

        func body(content: Content) -> some View {
            content
                .offset(y: up || motion.reduce ? 0 : 300)
                .opacity(up || motion.reduce ? 1 : 0)
                .onAppear { withAnimation(motion.animation(DX.Move.settle).delay(0.82)) { up = true } }
        }
    }
}

/// One glyph per card type (023): Listen headphones, Try a hand, Reveal an eye, Myth or fact a question mark, the plan
/// card a spark.
struct DeckGlyph: View {
    let card: DeckCard

    var body: some View {
        switch card.format {
        case .listen: DXIcon(.headphones, size: 24, weight: 2.4).scaledToFit()
        case .breathe: DXIcon(.hand, size: 24, weight: 2.4).scaledToFit()
        case .reveal: DXIcon(.eye, size: 24, weight: 2.4).scaledToFit()
        case .myth:
            ZStack {
                GridShape(d: "M8.6 8.6a3.5 3.5 0 116.2 2.2c-.9 1-2.8 1.7-2.8 3.6v.4", grid: 24)
                    .stroke(style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                GridShape(d: "M12 18.6h.01", grid: 24).stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
        case .activity:
            ZStack {
                GridShape(d: "M12 2.8c.7 4.9 2.3 6.6 7.4 7.4-5.1.8-6.7 2.5-7.4 7.4-.7-4.9-2.3-6.6-7.4-7.4 5.1-.8 6.7-2.5 7.4-7.4z", grid: 24).fill()
                GridShape(d: "M16.8 18.4a1.8 1.8 0 103.6 0 1.8 1.8 0 10-3.6 0z", grid: 24).fill()
            }
        }
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

// MARK: - F2 Listen (v5, 024)

/// The card's place in the day (kit `.steps`): one segment per card, played ones full, the current one filling as a
/// sliver with its own progress. `label` sits beside it ("Card 5 · Step 1 of 3").
struct DeckStepBar: View {
    let total: Int
    /// 1-based.
    let current: Int
    /// The current card's own progress, 0...1.
    var sub: Double = 0
    var label: String?
    @Environment(\.dxGround) private var ground

    var body: some View {
        let g = ground.resolved
        HStack(spacing: 10) {
            HStack(spacing: 5) {
                ForEach(1...max(total, 1), id: \.self) { i in
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(g.track)
                            if i < current {
                                Capsule().fill(g.ink)
                            } else if i == current {
                                UnevenRoundedRectangle(topLeadingRadius: 3, bottomLeadingRadius: 3, bottomTrailingRadius: 1,
                                                       topTrailingRadius: 1)
                                    .fill(g.ink)
                                    .frame(width: max(min(12, proxy.size.width), proxy.size.width * min(max(sub, 0), 1)))
                            }
                        }
                    }
                    .frame(height: 6)
                }
            }
            .animation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.5), value: sub)
            if let label {
                Text(verbatim: label).dxFace(.body, 13, weight: 600).foregroundStyle(g.muted).lineLimit(1).fixedSize()
            }
        }
        .accessibilityElement()
        .accessibilityLabel(Text(verbatim: label ?? String(localized: "Card \(current) of \(total)")))
    }
}

/// The deck screens' nav row: the close button, then the step bar.
struct DeckNavRow: View {
    let total: Int
    let current: Int
    var sub: Double = 0
    var label: String?
    var onBack: (() -> Void)?
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            DXIconButton(.close, label: "Close. Your place is saved.", action: onClose)
            if let onBack { DXIconButton(.back, label: "Back", action: onBack) }
            DeckStepBar(total: total, current: current, sub: sub, label: label)
        }
        .frame(height: 52)
        .padding(.horizontal, -6)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

/// When each paragraph of a listen card's transcript starts in its recording (`tx_<card>_<variant>.json`).
private struct ListenTimings: Decodable {
    let paragraphs: [Double]
}

/// The listen card (024): an apricot player with Xero in his headphones before the sun, a waveform with the playhead,
/// the times and the controls. It plays the recording, or reads the script aloud until the recordings are in. Read opens
/// the transcript under the controls.
///
/// Motion (024): the player rises into place (900 ms) while the bar arrives; Xero settles before the sun and sways to
/// the audio. The waveform bars grow from the centre line left to right (48 bars, 16 ms apart, 420 ms each); at 1.2 s
/// play starts and the played ink and the playhead sweep with playback, the elapsed time counts, and the card's segment
/// fills. While it plays the dock holds a quiet "Skip to next card"; at 80% it crossfades into "Next card" (300 ms,
/// light haptic).
struct DeckListenView: View {
    let card: DeckCard
    let position: Int
    let total: Int
    let session: ProgramContent.Session
    let ctx: BeatContext
    let onDone: () -> Void
    let onClose: () -> Void
    var onSaveForLater: (() -> Void)?

    @State private var narrator: LessonNarrator?
    @State private var reading = false
    @State private var grown = false
    @State private var unlocked = false
    /// When each paragraph of the transcript starts in the recording, in seconds. Empty without a recording.
    @State private var starts: [Double] = []
    @Environment(\.colorScheme) private var scheme
    private let motion = MotionPolicy()

    private var recording: URL? {
        guard let naming = ctx.store.content?.audio else { return nil }
        let name = naming.file(session: card.audioKey, variant: session.audio.pick(for: ctx.variant, nrtActive: ctx.nrtActive))
        let base = (name as NSString).deletingPathExtension, ext = (name as NSString).pathExtension
        return Bundle.main.url(forResource: base, withExtension: ext, subdirectory: naming.folder)
            ?? Bundle.main.url(forResource: base, withExtension: ext)
    }

    private var paragraphs: [String] {
        (card.script?.chapters ?? []).flatMap { ProgramInline.paragraphs(ctx.text($0.text), ctx.variant) }
    }

    /// The recording's paragraph timings (`tx_P1_5_smoking.json`, beside the audio), or nothing when the file is
    /// missing or was made for a different script.
    private func loadStarts() -> [Double] {
        guard let naming = ctx.store.content?.audio else { return [] }
        let name = naming.transcript(session: card.audioKey, variant: session.audio.pick(for: ctx.variant, nrtActive: ctx.nrtActive))
        let base = (name as NSString).deletingPathExtension, ext = (name as NSString).pathExtension
        guard let url = Bundle.main.url(forResource: base, withExtension: ext, subdirectory: naming.folder)
                ?? Bundle.main.url(forResource: base, withExtension: ext),
              let data = try? Data(contentsOf: url),
              let timings = try? JSONDecoder().decode(ListenTimings.self, from: data),
              timings.paragraphs.count == paragraphs.count else { return [] }
        return timings.paragraphs
    }

    var body: some View {
        let dark = scheme == .dark
        let ink = dark ? DX.Fill.cream : DX.Fill.navy
        TimelineView(.animation(minimumInterval: 1 / 20, paused: !(narrator?.playing ?? false))) { timeline in
            let elapsed = narrator?.elapsed(at: timeline.date) ?? 0
            let length = max(narrator?.total ?? Double(card.minutes * 60), 1)
            let p = min(max(elapsed / length, 0), 1)
            let speaking: Int? = starts.isEmpty ? nil : starts.lastIndex(where: { $0 <= elapsed + 0.05 })
            VStack(spacing: 0) {
                DeckNavRow(total: total, current: position, sub: p, onClose: { narrator?.stop(); onClose() })
                    .dxArrive(0)
                ScrollViewReader { reader in
                    ScrollView {
                        VStack(spacing: 0) {
                            art(dark: dark)
                            VStack(alignment: .leading, spacing: 0) {
                                HStack(spacing: 8) {
                                    DXIcon(.headphones, size: 18)
                                    Text(verbatim: "\(card.format.label) · \(String(localized: "\(card.minutes) min"))")
                                    Spacer()
                                    Button {
                                        withAnimation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.32)) { reading.toggle() }
                                    } label: {
                                        HStack(spacing: 6) {
                                            DXIcon(.text, size: 17)
                                            Text(reading ? "Hide" : "Read")
                                        }
                                        .foregroundStyle(ink)
                                        .frame(height: 32)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityValue(Text(reading ? "Transcript shown" : ""))
                                }
                                .dxFace(.body, 14, weight: 600)
                                .foregroundStyle(dark ? Color(hex: 0xE9DCCB) : Color(hex: 0x3A2410))
                                Text(verbatim: ctx.text(card.title))
                                    .dxType(.title).foregroundStyle(ink)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.top, 10)
                                    .accessibilityAddTraits(.isHeader)
                                Waveform(progress: p, grown: grown, ink: ink, face: dark ? Color(hex: 0x222D54) : card.faceColor)
                                    .frame(height: 52)
                                    .padding(.top, 16)
                                    .accessibilityElement()
                                    .accessibilityLabel(Text("Playback"))
                                    .accessibilityValue(Text("\(Self.clock(elapsed)) of \(Self.clock(length))"))
                                HStack {
                                    Text(verbatim: Self.clock(elapsed)).monospacedDigit()
                                    Spacer()
                                    Text(verbatim: Self.clock(length)).monospacedDigit()
                                }
                                .dxType(.caption)
                                .foregroundStyle(dark ? Color(hex: 0xE9DCCB) : Color(hex: 0x3A2410))
                                .padding(.top, 8)
                                HStack(spacing: 34) {
                                    SkipButton(forward: false, ink: ink) { narrator?.skip(-15) }
                                    Button { narrator?.toggle() } label: {
                                        DXIcon((narrator?.playing ?? false) ? .pause : .play, size: 26, weight: 2.4, filled: !(narrator?.playing ?? false))
                                            .foregroundStyle(dark ? DX.Fill.navy : DX.Fill.cream)
                                            .offset(x: (narrator?.playing ?? false) ? 0 : 2)
                                            .frame(width: 64, height: 64)
                                            .background(dark ? Color(hex: 0xFFC38A) : DX.Fill.navy, in: Circle())
                                            .shadow(color: dark ? .black.opacity(0.35) : Color(hex: 0x1E1A3A).opacity(0.22), radius: 8, y: 6)
                                    }
                                    .buttonStyle(.dxPress)
                                    .accessibilityLabel(Text((narrator?.playing ?? false) ? "Pause" : "Play"))
                                    SkipButton(forward: true, ink: ink) { narrator?.skip(15) }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 12)
                                if reading {
                                    VStack(alignment: .leading, spacing: 12) {
                                        ForEach(Array(paragraphs.enumerated()), id: \.offset) { i, paragraph in
                                            Text(verbatim: paragraph).dxFace(.body, 17, weight: 450).foregroundStyle(ink)
                                                .lineSpacing(4)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .opacity(speaking == nil || speaking == i ? 1 : 0.5)
                                                .animation(motion.reduce ? nil : .easeInOut(duration: 0.3), value: speaking)
                                                .id("paragraph-\(i)")
                                        }
                                    }
                                    .padding(.top, 18)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .padding(.top, 18).padding(.horizontal, 20).padding(.bottom, 24)
                        }
                        .background(face(dark: dark))
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .shadow(color: dark ? .black.opacity(0.45) : Color(red: 60 / 255, green: 40 / 255, blue: 20 / 255).opacity(0.14), radius: 15, y: 16)
                        .padding(.top, 6)
                        .dxSettle()
                        .padding(.bottom, 28)
                        .padding(.horizontal, DX.Layout.gutter)
                    }
                    .padding(.horizontal, -DX.Layout.gutter)
                    .scrollBounceBehavior(.basedOnSize)
                    .scrollIndicators(.hidden)
                    // The transcript follows the voice: the paragraph being spoken stays in view.
                    .onChange(of: speaking) { _, now in
                        guard reading, let now else { return }
                        withAnimation(motion.reduce ? nil : .easeInOut(duration: 0.4)) { reader.scrollTo("paragraph-\(now)", anchor: .center) }
                    }
                }
                gate(open: unlocked || p >= 0.8 || ctx.isReplay || (narrator?.finished ?? false))
                    .padding(.top, 8)
                    .dxArrive(6)
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: unlocked) { _, now in now }
        .onAppear {
            guard narrator == nil else { return }
            let transcript = paragraphs.joined(separator: " ")
            let audio = recording
            let n = LessonNarrator(transcript: transcript, url: audio, seconds: card.minutes * 60)
            starts = audio == nil ? [] : loadStarts()
            n.onFinish = { unlocked = true }
            narrator = n
            withAnimation(motion.reduce ? nil : .linear(duration: 0.01).delay(0.2)) { grown = true }
            Task {
                try? await Task.sleep(for: .seconds(1.2))
                if !Task.isCancelled, !ctx.isReplay { narrator?.play() }
            }
        }
        .onDisappear { narrator?.stop() }
    }

    /// Light: apricot, warm toward the top. Dark: the same player at deep dusk with a warm glow behind the sun.
    @ViewBuilder private func face(dark: Bool) -> some View {
        if dark {
            ZStack {
                LinearGradient(stops: [.init(color: Color(hex: 0x27325C), location: 0), .init(color: Color(hex: 0x1C2547), location: 0.58),
                                       .init(color: Color(hex: 0x19223F), location: 1)], startPoint: .top, endPoint: .bottom)
                RadialGradient(colors: [Color(red: 247 / 255, green: 170 / 255, blue: 108 / 255).opacity(0.3), .clear],
                               center: UnitPoint(x: 0.5, y: 0.32), startRadius: 0, endRadius: 220)
            }
        } else {
            card.faceColor
        }
    }

    private func art(dark: Bool) -> some View {
        ZStack(alignment: .bottom) {
            if !dark {
                LinearGradient(colors: [Color(hex: 0xFFD6AC), card.faceColor], startPoint: .top, endPoint: .bottom)
            }
            Circle()
                .fill(dark ? RadialGradient(colors: [Color(hex: 0xF9C083), Color(hex: 0xF2A766), Color(hex: 0xEC9A5E)], center: .center, startRadius: 0, endRadius: 120)
                      : RadialGradient(colors: [Color(hex: 0xFFE48A), Color(hex: 0xFFD35E), Color(hex: 0xFFC94F)], center: .center, startRadius: 0, endRadius: 120))
                .frame(width: 240, height: 240)
                .shadow(color: dark ? Color(red: 247 / 255, green: 168 / 255, blue: 106 / 255).opacity(0.3) : Color(red: 1, green: 214 / 255, blue: 94 / 255).opacity(0.55),
                        radius: dark ? 45 : 30)
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 38)
            XeroView(mood: .calm, stage: 0, points: 226, pose: .headphones)
                .dxBob()
                .offset(y: 9)
                .dxSettle(2)
        }
        .frame(height: 334)
        .clipped()
        .accessibilityHidden(true)
    }

    /// While it plays, a quiet skip; from 80% (or once played), the solid button.
    private func gate(open: Bool) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Button(String(localized: "Skip to next card")) { narrator?.stop(); onDone() }
                    .dxFace(.body, 15, weight: 600)
                    .foregroundStyle(DX.Ground.table.muted)
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                    .opacity(open ? 0 : 1)
                    .allowsHitTesting(!open)
                    .accessibilityHidden(open)
                Button(String(localized: "Next card")) { narrator?.stop(); onDone() }
                    .buttonStyle(.dx(.primary, on: .table))
                    .opacity(open ? 1 : 0)
                    .allowsHitTesting(open)
                    .accessibilityHidden(!open)
                    .accessibilityIdentifier("program.deck.commit")
            }
            .animation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.3), value: open)
            if let onSaveForLater, !ctx.isReplay {
                Button(String(localized: "Save it for later")) { narrator?.stop(); onSaveForLater() }
                    .buttonStyle(.dx(.quiet, on: .table))
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    static func clock(_ seconds: Double) -> String {
        let s = max(Int(seconds.rounded(.down)), 0)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

/// 48 bars: the base in a soft ink, the played part in full ink, a playhead with a knob riding its end. The bars grow
/// from the centre line left to right as the card arrives.
private struct Waveform: View {
    let progress: Double
    let grown: Bool
    let ink: Color
    let face: Color
    private let motion = MotionPolicy()

    private static let heights: [CGFloat] = (0..<48).map { i in
        let x = Double(i)
        return CGFloat(0.28 + 0.72 * abs(sin(x * 0.61) * 0.6 + sin(x * 0.23 + 1) * 0.4))
    }

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width, h = proxy.size.height
            let bar = (w - 47 * 3) / 48
            ZStack(alignment: .leading) {
                bars(w: w, h: h, bar: bar, color: ink.opacity(0.28))
                bars(w: w, h: h, bar: bar, color: ink)
                    .mask(alignment: .leading) { Rectangle().frame(width: w * progress) }
                Capsule().fill(ink).frame(width: 2, height: h + 8)
                    .overlay {
                        Circle().fill(ink).frame(width: 16, height: 16)
                            .overlay(Circle().stroke(face, lineWidth: 3))
                            .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
                    }
                    .offset(x: w * progress - 1)
            }
        }
    }

    private func bars(w: CGFloat, h: CGFloat, bar: CGFloat, color: Color) -> some View {
        HStack(spacing: 3) {
            ForEach(0..<48, id: \.self) { i in
                Capsule().fill(color)
                    .frame(width: bar, height: h * Self.heights[i])
                    .scaleEffect(y: grown || motion.reduce ? 1 : 0.08)
                    .animation(motion.reduce ? nil : DX.Move.settle.speed(0.9 / 0.42).delay(Double(i) * 0.016), value: grown)
            }
        }
        .frame(height: h)
    }
}

/// Back or forward 15 seconds: a circular arrow with the 15 inside.
struct SkipButton: View {
    let forward: Bool
    let ink: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                ZStack {
                    GridShape(d: "M7.8 8.3A13 13 0 1 1 4.2 19.8", grid: 34)
                    GridShape(d: "M7.8 2.5v5.8h5.8", grid: 34)
                }
                .foregroundStyle(.clear)
                .overlay {
                    ZStack {
                        GridShape(d: "M7.8 8.3A13 13 0 1 1 4.2 19.8", grid: 34).stroke(ink, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                        GridShape(d: "M7.8 2.5v5.8h5.8", grid: 34).stroke(ink, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                    }
                }
                .frame(width: 34, height: 34)
                .scaleEffect(x: forward ? -1 : 1)
                Text(verbatim: "15").dxFace(.body, 11, weight: 700, tracking: -0.3).foregroundStyle(ink).padding(.top, 1)
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(forward ? "Forward 15 seconds" : "Back 15 seconds"))
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
    private let ground = DX.Ground.table
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
                        .foregroundStyle(ground.btnFg)
                        .background(ground.btn, in: Capsule())
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
                    Text(verbatim: String(localized: "Question \(index + 1)"))
                        .dxFont(13, weight: 700, style: .caption2).foregroundStyle(ground.muted)
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
                .background(DX.Ground.table.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: String(localized: "Question \(index + 1): \(ctx.text(reveal.front)). Turn over")))
        }
    }

    private func deeperSheet(_ reveal: DeckCard.Reveal, index: Int) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DX.Space.s) {
                Text(verbatim: String(localized: "Go deeper · Question \(index + 1)")).dxType(.caption).foregroundStyle(Read4.muted)
                Text(verbatim: ctx.text(reveal.front)).dxType(.title).foregroundStyle(Read4.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(verbatim: ctx.text(reveal.deeper)).dxFont(17, weight: 400, style: .body).foregroundStyle(Read4.ink)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                if let keep = reveal.keep {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "Keep in mind")).dxType(.caption).foregroundStyle(Read4.muted)
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
    private let ground = DX.Ground.table
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
                Text(verbatim: String(localized: "Statement \(index + 1) of \(statements.count)"))
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

// MARK: - F6 Card played (v5, 025)

/// A card, done: it flips over to its back, a paper sun with a check, and the day moves on.
///
/// Motion (025): the card lifts from below and flips over (1100 ms settle) to its back, landing with a slight tilt; at
/// 1.1 s the rays fan out from the disc (500 ms, 30 ms apart) and an ink check draws across the sun (420 ms, success
/// haptic); dark mode pools a warm glow under it. The card's segment fills to full at 1.3 s. Title and line arrive,
/// then "How was it?" and its three quiet chips; Up next and the button arrive last.
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
    @State private var flipped = false
    @State private var stamped = false
    @State private var full = false
    @Environment(\.colorScheme) private var scheme
    private let ground = DX.Ground.table
    private let motion = MotionPolicy()
    static let ratings = ["Helpful", "Just okay", "Not for me"]

    var body: some View {
        VStack(spacing: 0) {
            DeckNavRow(total: total, current: position, sub: full ? 1 : 0.14, onClose: onLater)
            ScrollView {
                VStack(spacing: 0) {
                    ZStack {
                        if scheme == .dark {
                            Ellipse()
                                .fill(RadialGradient(stops: [.init(color: Color(red: 247 / 255, green: 170 / 255, blue: 108 / 255).opacity(0.4), location: 0),
                                                             .init(color: Color(red: 247 / 255, green: 170 / 255, blue: 108 / 255).opacity(0.16), location: 0.55),
                                                             .init(color: .clear, location: 1)], center: .center, startRadius: 0, endRadius: 190))
                                .frame(width: 380, height: 250)
                                .offset(y: 88)
                                .dxFade(delay: 1.1)
                        }
                        flipCard
                    }
                    .frame(height: 336)
                    .padding(.top, 6)
                    VStack(spacing: 8) {
                        Text(verbatim: doneTitle).dxType(.large).foregroundStyle(ground.ink)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                        Text(verbatim: ctx.text(card.title)).dxType(.footnote).foregroundStyle(ground.muted)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 22)
                    .dxArrive(0, delay: 0.9)
                    VStack(spacing: 9) {
                        Text("How was it?").dxFace(.body, 13, weight: 500).foregroundStyle(ground.muted)
                        HStack(spacing: 8) {
                            ForEach(Self.ratings, id: \.self) { value in
                                ratingChip(value)
                            }
                        }
                    }
                    .padding(.top, 26)
                    .dxArrive(2, delay: 0.9)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            VStack(spacing: 10) {
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
                    if let next { upNext(next).dxArrive(3, delay: 0.9) }
                    Button(action: onNext) { Text(verbatim: primaryTitle) }
                        .buttonStyle(.dx(.primary, on: ground))
                        .accessibilityIdentifier("program.deck.next")
                        .dxArrive(4, delay: 0.9)
                }
            }
            .padding(.top, 10)
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
        .foregroundStyle(ground.ink)
        .sensoryFeedback(.success, trigger: stamped) { _, now in now }
        .onAppear {
            if case let .text(saved)? = ctx.answer("\(card.id).rating") { rating = saved }
            guard !motion.reduce else { flipped = true; stamped = true; full = true; return }
            withAnimation(DX.Move.settle.speed(0.9 / 1.1).delay(0.15)) { flipped = true }
            Task {
                try? await Task.sleep(for: .seconds(1.1))
                stamped = true
                try? await Task.sleep(for: .seconds(0.2))
                withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.5)) { full = true }
            }
        }
    }

    /// "First card, done".
    private var doneTitle: String {
        let f = NumberFormatter()
        f.numberStyle = .ordinal
        f.numberStyle = .spellOut
        let ordinal: String = switch position {
        case 1: String(localized: "First")
        case 2: String(localized: "Second")
        case 3: String(localized: "Third")
        case 4: String(localized: "Fourth")
        case 5: String(localized: "Fifth")
        default: String(localized: "Card \(position)")
        }
        return position == total && total > 1 ? String(localized: "Last card, done") : String(localized: "\(ordinal) card, done")
    }

    private var primaryTitle: String {
        guard let next else { return String(localized: "See today's recap") }
        _ = next
        return String(localized: "Play card \(position + 1)")
    }

    private var flipCard: some View {
        ZStack {
            front.modifier(FlipFace(angle: flipped ? 180 : 0, back: false))
            back.modifier(FlipFace(angle: flipped ? 180 : 0, back: true))
        }
        .frame(width: 226, height: 302)
        .rotationEffect(.degrees(flipped ? 4 : 0))
        .scaleEffect(flipped || motion.reduce ? 1 : 1.2)
        .offset(y: flipped || motion.reduce ? 0 : 320)
        .accessibilityElement()
        .accessibilityLabel(Text(verbatim: "\(card.format.label), \(ctx.text(card.title)), done"))
    }

    private var front: some View {
        VStack(alignment: .leading, spacing: 0) {
            DeckGlyph(card: card).frame(width: 20, height: 20)
                .frame(width: 36, height: 36)
                .background(Color(hex: 0x1E1A3A).opacity(0.1), in: Circle())
            Text(verbatim: card.format.label).dxFace(.display, 17, weight: 700).padding(.top, 10)
            Text(verbatim: String(localized: "\(card.minutes) min")).dxType(.caption).opacity(0.7)
            Spacer()
        }
        .foregroundStyle(DX.Fill.navy)
        .padding(18)
        .frame(width: 226, height: 302, alignment: .topLeading)
        .background(card.faceColor, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: scheme == .dark ? .black.opacity(0.5) : Color(red: 60 / 255, green: 40 / 255, blue: 20 / 255).opacity(0.18), radius: 17, y: 18)
    }

    /// The back: the card's own colour, a crisp paper sun with twelve rays and an ink check, a cream band naming it.
    private var back: some View {
        ZStack(alignment: .bottom) {
            card.faceColor
            GeometryReader { proxy in
                let s = proxy.size.width / 196
                ZStack {
                    ForEach(0..<12, id: \.self) { i in
                        let a = Double(i) * .pi / 6
                        Path { p in
                            p.move(to: CGPoint(x: 98 + 58 * cos(a), y: 106 + 58 * sin(a)))
                            p.addLine(to: CGPoint(x: 98 + 76 * cos(a), y: 106 + 76 * sin(a)))
                        }
                        .stroke(Color(hex: 0xFFF1D6), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .scaleEffect(stamped || motion.reduce ? 1 : 0.3, anchor: UnitPoint(x: (98 + 67 * cos(a)) / 196, y: (106 + 67 * sin(a)) / 262))
                        .opacity(stamped || motion.reduce ? 1 : 0)
                        .animation(DX.Move.settle.speed(0.9 / 0.5).delay(Double(i) * 0.03), value: stamped)
                    }
                    Circle().fill(Color(hex: 0xFFF1D6)).frame(width: 92, height: 92).position(x: 98, y: 106)
                    Path { p in
                        p.move(to: CGPoint(x: 77, y: 107)); p.addLine(to: CGPoint(x: 91, y: 121)); p.addLine(to: CGPoint(x: 118, y: 92))
                    }
                    .trim(from: 0, to: stamped || motion.reduce ? 1 : 0)
                    .stroke(Color(hex: 0x1E1A3A), style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round))
                    .animation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.42), value: stamped)
                }
                .frame(width: 196, height: 262)
                .scaleEffect(s, anchor: .topLeading)
            }
            HStack(spacing: 8) {
                DeckGlyph(card: card).frame(width: 17, height: 17)
                Text(verbatim: "\(card.format.label) · \(String(localized: "\(card.minutes) min"))")
            }
            .dxFace(.body, 14, weight: 600)
            .foregroundStyle(DX.Fill.navy)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Color(light: 0xFFF8EE, dark: 0xE9DCC6))
        }
        .frame(width: 226, height: 302)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: scheme == .dark ? .black.opacity(0.5) : Color(red: 60 / 255, green: 40 / 255, blue: 20 / 255).opacity(0.18), radius: 17, y: 18)
    }

    private func ratingChip(_ value: String) -> some View {
        let on = rating == value
        return Button {
            rating = value
            ctx.save("\(card.id).rating", .text(value))
        } label: {
            Text(LocalizedStringKey(value))
                .dxFace(.body, 14, weight: on ? 700 : 500)
                .foregroundStyle(ground.ink.opacity(on ? 1 : 0.82))
                .padding(.horizontal, 14)
                .frame(minHeight: 36)
                .background(on ? ground.selTint : .clear, in: Capsule())
                .overlay(Capsule().strokeBorder(on ? ground.selEdge : Color(light: (0x1E1A3A, 0.16), dark: (0xFFF8EE, 0.16)),
                                                lineWidth: on ? 2 : 1))
                .frame(minHeight: DX.Layout.touchTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(DX.Haptic.select, trigger: on)
        .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
    }

    private func upNext(_ next: DeckCard) -> some View {
        HStack(spacing: 12) {
            NextSpot(card: next)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: "\(String(localized: "Up next")) · \(next.format.label) · \(String(localized: "\(next.minutes) min"))")
                    .dxType(.caption).foregroundStyle(ground.muted)
                Text(verbatim: ctx.text(next.title)).dxFace(.body, 15, weight: 600).foregroundStyle(ground.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4).padding(.bottom, 4)
        .accessibilityElement(children: .combine)
    }
}

/// Shows the front face up to 90° of the turn and the back face after it, so the card reads as one flipping card.
private struct FlipFace: ViewModifier, Animatable {
    /// The turn in degrees. Nonisolated so it can satisfy `Animatable` under Swift 6.
    nonisolated var animatableData: Double
    let back: Bool

    init(angle: Double, back: Bool) {
        animatableData = angle
        self.back = back
    }

    func body(content: Content) -> some View {
        let angle = animatableData
        content
            .rotation3DEffect(.degrees(back ? angle - 180 : angle), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
            .opacity(back ? (angle >= 90 ? 1 : 0) : (angle < 90 ? 1 : 0))
    }
}

/// The next card's small paper-cut spot (025): for a Try card two breaths over a mint hill; otherwise its glyph on its
/// colour. Ringed so it holds on cream.
private struct NextSpot: View {
    let card: DeckCard
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let dark = scheme == .dark
        ZStack {
            if card.format == .breathe {
                (dark ? Color(hex: 0x1E2C52) : Color(hex: 0xA9E6C4))
                GridShape(d: "M0 35 C12 30 30 34 48 30 V48 H0z", grid: 48).fill(dark ? Color(hex: 0x2C4A55) : Color(hex: 0x6FCB98))
                GridShape(d: "M0 42 C16 38 32 43 48 39 V48 H0z", grid: 48).fill(dark ? Color(hex: 0x22394A) : Color(hex: 0x4FB883))
                GridShape(d: "M7 13h18c4.5 0 6-6 1.5-6.4-3-.3-3.6 3.4-1.2 4", grid: 48)
                    .stroke(dark ? Color(hex: 0xE6DCCB) : .white, style: StrokeStyle(lineWidth: 2.3, lineCap: .round))
                GridShape(d: "M12 22h22c4.5 0 6 6 1.5 6.4-3 .3-3.6-3.4-1.2-4", grid: 48)
                    .stroke(dark ? Color(hex: 0xE6DCCB) : .white, style: StrokeStyle(lineWidth: 2.3, lineCap: .round))
            } else {
                card.faceColor
                DeckGlyph(card: card).frame(width: 20, height: 20).foregroundStyle(DX.Fill.navy)
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(dark ? Color(hex: 0x9FE3BC).opacity(0.38) : Color(hex: 0x1F6E48).opacity(0.3), lineWidth: 1.5))
        .accessibilityHidden(true)
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
    private let ground = DX.Ground.table
    private let motion = MotionPolicy()

    /// "P4" → 4: the prep stamp the day earns (032).
    private var prepNumber: Int? {
        guard session.id.hasPrefix("P") else { return nil }
        return Int(session.id.dropFirst())
    }

    private var statLines: [String] {
        (session.recap?.statLines ?? []).compactMap { $0.resolve(ctx.variant) }
            .compactMap { ctx.placeholders.fill(ProgramInline.resolve($0, ctx.variant)) }
    }

    @State private var stamped = false
    @State private var counted = false
    @State private var cheer = false
    @Environment(\.colorScheme) private var scheme

    /// v5 (032): rays fan out behind the day's medal and turn slowly; the medal stamps in and shines; Xero settles
    /// beside it, cheering, and bumps at 1.5 s. Title and line arrive; the shelf's earned stamps pop in left to right,
    /// today's lands with a stamp and a shine (medium haptic) while the count ticks up; the waiting stamps and the Day
    /// Xero medal fade in last.
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                DXIconButton(.close, label: "Close", action: onDone)
                Spacer()
            }
            .frame(height: 52)
            .padding(.horizontal, -6)
            ScrollView {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 310)
                        .overlay(alignment: .top) { hero }
                    VStack(spacing: 8) {
                        MarkedTitle("\(session.label) ", marking: String(localized: "done"), trail: ".", color: DX.Mark.color(on: .table))
                            .dxType(.large).foregroundStyle(ground.ink)
                            .accessibilityAddTraits(.isHeader)
                        Text(verbatim: line).dxType(.body).foregroundStyle(ground.muted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    .dxArrive(6)
                    if let n = prepNumber { shelf(n).padding(.top, 34).dxArrive(8) }
                }
                .padding(.horizontal, DX.Layout.gutter)
            }
            .padding(.horizontal, -DX.Layout.gutter)
            .scrollBounceBehavior(.basedOnSize)
            VStack(spacing: 8) {
                if let opensFullProgram {
                    Text(verbatim: opensFullProgram).dxType(.footnote).foregroundStyle(ground.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Button(action: onDone) { Text(verbatim: buttonTitle) }
                    .buttonStyle(.dx(.primary, on: ground))
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                    .accessibilityIdentifier("program.deck.done")
            }
            .padding(.top, 10)
            .dxArrive(12)
        }
        .foregroundStyle(ground.ink)
        .sensoryFeedback(.impact(weight: .medium), trigger: counted) { _, now in now }
        .task {
            guard !motion.reduce else { stamped = true; counted = true; return }
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.timingCurve(0.3, 1.4, 0.5, 1, duration: DX.Move.stamp)) { stamped = true }
            try? await Task.sleep(for: .milliseconds(1200))
            cheer.toggle()
            try? await Task.sleep(for: .milliseconds(650))
            withAnimation(.easeOut(duration: 0.4)) { counted = true }
        }
    }

    /// "4 days to Day Xero · 3 preps to go".
    private var line: String {
        let profile = ctx.store.profile
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        let days = max(clock.calendar.dateComponents([.day], from: clock.day(containing: .now), to: clock.startOfDate(profile.quitDay)).day ?? 0, 0)
        var parts: [String] = []
        if days > 0 { parts.append(String(AttributedString(localized: "^[\(days) day](inflect: true) to Day Xero").characters)) }
        if let n = prepNumber, n < 7 { parts.append(String(AttributedString(localized: "^[\(7 - n) prep](inflect: true) to go").characters)) }
        if parts.isEmpty, let next { parts.append(next) }
        return parts.joined(separator: " · ")
    }

    private var buttonTitle: String {
        if isReplay { return String(localized: "Done") }
        if let next, next.contains(String(localized: "ready now")) { return String(localized: "Back to my day") }
        return String(localized: "See you tomorrow")
    }

    /// The paper rays (open where Xero stands), the day's medal and Xero cheering beside it on one ground shadow.
    private var hero: some View {
        ZStack(alignment: .topLeading) {
            SlowRays(color: scheme == .dark ? Color(hex: 0xE8B24A) : Color(hex: 0xF9C23C))
                .frame(width: 320, height: 320)
                .offset(x: 12)
            Ellipse()
                .fill(RadialGradient(colors: [scheme == .dark ? Color.black.opacity(0.5) : Color(hex: 0x1E1A3A).opacity(0.18), .clear],
                                     center: .center, startRadius: 0, endRadius: 145))
                .frame(width: 290, height: 28)
                .offset(x: 80, y: 250)
                .dxFade(delay: 0.3)
            Group {
                if let n = prepNumber {
                    DXBadge(.prep, n: n, size: 180)
                } else {
                    DXBadge(.day, n: session.label.filter(\.isNumber), size: 180)
                }
            }
            .frame(width: 180, height: 180)
            .scaleEffect(stamped || motion.reduce ? 1 : 1.8)
            .rotationEffect(.degrees(stamped || motion.reduce ? 0 : -14))
            .opacity(stamped || motion.reduce ? 1 : 0)
            .offset(x: 82, y: 70)
            XeroView(mood: .cheer, stage: 0, points: 104)
                .dxBump(cheer)
                .offset(x: 274, y: 156)
                .dxSettle(4)
        }
        .frame(width: 390, alignment: .topLeading)
        .frame(maxWidth: .infinity)
        .accessibilityElement()
        .accessibilityLabel(Text("\(session.label) done. Xero cheers beside your new stamp."))
    }

    /// The shelf: stamps 1 to 7 (earned, today's landing with a stamp, the rest waiting) and Day Xero at the end.
    private func shelf(_ n: Int) -> some View {
        let profile = ctx.store.profile
        return VStack(spacing: 14) {
            HStack(spacing: 5) {
                ForEach(1...7, id: \.self) { i in
                    Group {
                        if i < n {
                            DXBadge(.prep, n: i, size: 36).dxPop(0, delay: 1.5 + Double(i) * 0.11)
                        } else if i == n {
                            DXBadge(.prep, n: i, size: 36)
                                .scaleEffect(counted || motion.reduce ? 1 : 1.8)
                                .opacity(counted || motion.reduce ? 1 : 0)
                        } else {
                            DXBadge(.prep, n: i, state: .next(nil), size: 36).dxFade(delay: 2.4)
                        }
                    }
                }
                Spacer(minLength: 0)
                DXBadge(.xero, state: .next(nil), size: 54)
                    .opacity(scheme == .dark ? 0.7 : 1)
                    .dxFade(delay: 2.5)
            }
            .padding(.bottom, 12)
            .overlay(alignment: .bottom) { Rectangle().fill(ground.line).frame(height: 1.5) }
            Text("\(counted ? n : n - 1) of 7 stamped · Day Xero on \(profile.quitDay.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))")
                .dxFace(.body, 14, weight: 600).foregroundStyle(ground.muted)
                .contentTransition(.numericText())
        }
        .accessibilityElement(children: .combine)
    }
}

/// Sixteen paper rays round the medal, long and short in turn, left open where Xero stands; they grow out from the
/// centre (500 ms, 25 ms apart, from 300 ms), then turn very slowly (26 s a turn).
private struct SlowRays: View {
    let color: Color
    @State private var grown = false
    private let motion = MotionPolicy()

    var body: some View {
        TimelineView(.animation(paused: motion.reduce)) { timeline in
            let turn = motion.reduce ? 0 : timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 26) / 26 * 360
            ZStack {
                ForEach(Array((0..<16).filter { !(4...9).contains($0) }), id: \.self) { i in
                    let a = (Double(i) * 22.5 - 90) * .pi / 180
                    let r1: CGFloat = i % 2 == 1 ? 118 : 134
                    Path { p in
                        p.move(to: CGPoint(x: 160 + 100 * cos(a), y: 160 + 100 * sin(a)))
                        p.addLine(to: CGPoint(x: 160 + r1 * cos(a), y: 160 + r1 * sin(a)))
                    }
                    .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .scaleEffect(grown || motion.reduce ? 1 : 0.6, anchor: .center)
                    .opacity(grown || motion.reduce ? 1 : 0)
                    .animation(DX.Move.settle.speed(0.9 / 0.5).delay(0.3 + Double(i) * 0.025), value: grown)
                }
            }
            .frame(width: 320, height: 320)
            .shadow(color: Color(hex: 0x1A0B2E).opacity(0.08), radius: 0.8, y: 1)
            .rotationEffect(.degrees(turn))
        }
        .onAppear { grown = true }
        .accessibilityHidden(true)
    }
}
