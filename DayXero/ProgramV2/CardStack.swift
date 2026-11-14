import DayXeroCore
import SwiftUI

/// How a session's lesson is taken: the 90-second card stack (MON-04, the default) or the recording.
/// The choice sticks across sessions; a session without a recording always reads.
enum LessonFormat: String {
    case read, listen

    static let key = "dx.lessonFormat"

    /// The person's choice, reading by default.
    static var current: LessonFormat {
        UserDefaults.standard.string(forKey: key).flatMap(LessonFormat.init(rawValue:)) ?? .read
    }
}

/// The 90-second read (MON-04, v5 034): the session's ideas as a short stack of cards. Each card is dealt face down
/// and turns over to show its art, its line and the idea behind it; "Next card" moves on, and the last card's button
/// says "Your turn". Swipes move too. Under Reduce Motion the cards cross-fade instead of flipping.
struct CardStackStep: View {
    let session: ProgramContent.Session
    let ctx: BeatContext
    /// A recording exists, so "Listen instead" can show (now on the intro, 033).
    let canListen: Bool
    let onListen: () -> Void
    var onClose: () -> Void = {}
    let onDone: () -> Void

    private let motion = MotionPolicy()
    @State private var index = 0
    @State private var turned = false

    private var cards: [(front: String, back: String)] {
        (session.cards ?? []).map { (ctx.text($0.front), ctx.text($0.back)) }
    }

    var body: some View {
        let cards = cards
        VStack(spacing: 0) {
            DeckNavRow(total: max(cards.count, 1), current: index + 1, sub: 1, onClose: onClose)
            if cards.indices.contains(index) {
                ScrollView {
                    stack(cards)
                        .padding(.top, 8)
                        .padding(.horizontal, DX.Layout.gutter)
                        .padding(.bottom, DX.Space.m)
                }
                .padding(.horizontal, -DX.Layout.gutter)
                .scrollBounceBehavior(.basedOnSize)
                Button(index + 1 < cards.count ? "Next card" : "Your turn") { next(count: cards.count) }
                    .buttonStyle(.dx(.primary, on: .table))
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                    .accessibilityIdentifier("cards.next")
                    .padding(.top, 10)
            } else {
                // A session with no cards never builds this step; this only guards a content change mid-session.
                Spacer(minLength: 0)
                Button("Continue", action: onDone).buttonStyle(.dx(.primary, on: .table))
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: turned) { _, now in now }
        .task(id: index) {
            turned = false
            try? await Task.sleep(for: .milliseconds(motion.reduce ? 0 : 450))
            withAnimation(motion.reduce ? .easeInOut(duration: 0.2) : .timingCurve(0.2, 0.8, 0.2, 1, duration: 0.8)) { turned = true }
        }
    }

    /// The card, with the stack's edges peeking out under it.
    private func stack(_ cards: [(front: String, back: String)]) -> some View {
        let card = cards[index]
        let left = cards.count - index - 1
        return ZStack(alignment: .top) {
            ForEach(Array((0..<min(left, 2)).reversed()), id: \.self) { depth in
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(DX.Ground.table.card)
                    .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(DX.Ground.table.line))
                    .padding(.horizontal, CGFloat(depth + 1) * 10)
                    .offset(y: CGFloat(depth + 1) * 9)
                    .accessibilityHidden(true)
                    .dxFade(delay: Double(1 - depth) * 0.08)
            }
            LessonCard(session: session, ctx: ctx, front: card.front, back: card.back, turned: turned)
                .id(index)
                .transition(motion.reduce ? .opacity : .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                                   removal: .move(edge: .leading).combined(with: .opacity)))
                .gesture(
                    DragGesture(minimumDistance: 24).onEnded { drag in
                        if drag.translation.width < -60 { next(count: cards.count) }
                        if drag.translation.width > 60, index > 0 { go(to: index - 1) }
                    }
                )
        }
        .padding(.bottom, 20)
    }

    private func next(count: Int) {
        if index + 1 < count { go(to: index + 1) } else { onDone() }
    }

    private func go(to next: Int) {
        withAnimation(motion.animation(DX.Move.settle)) { index = next }
    }
}

/// One card (034): face down it shows the lesson's name; turned over, the art runs full-bleed across the top, then the
/// line and the idea behind it.
private struct LessonCard: View {
    let session: ProgramContent.Session
    let ctx: BeatContext
    let front: String
    let back: String
    let turned: Bool
    private let motion = MotionPolicy()

    var body: some View {
        face.modifier(LessonFlip(angle: turned ? 0 : 180, isRear: false))
            .overlay { rear.modifier(LessonFlip(angle: turned ? 0 : 180, isRear: true)) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(front). \(back)"))
    }

    private var face: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottom) {
                HorizonScene(.path, clarity: 60, fit: .bottom)
                XeroView(mood: .hello, stage: 0, points: 120)
                    .offset(y: turned || motion.reduce ? -4 : 40)
                    .animation(DX.Move.settle.delay(0.7), value: turned)
            }
            .frame(height: 230)
            .clipped()
            VStack(alignment: .leading, spacing: 12) {
                Text(verbatim: front).dxType(.title).foregroundStyle(DX.Ground.table.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(verbatim: back)
                    .dxFace(.body, 16, weight: 700)
                    .foregroundStyle(DX.Ground.table.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 12)
                    .overlay(alignment: .leading) { Capsule().fill(DX.Fill.coral).frame(width: 3) }
            }
            .padding(.horizontal, 18).padding(.top, 18).padding(.bottom, 22)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DX.Ground.table.card)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(DX.Ground.table.line))
        .shadow(color: Color(red: 60 / 255, green: 40 / 255, blue: 20 / 255).opacity(0.12), radius: 12, y: 10)
    }

    private var rear: some View {
        VStack(alignment: .leading, spacing: 4) {
            Spacer()
            Text(verbatim: "\(session.label) \(String(localized: "lesson"))").dxType(.footnote).foregroundStyle(DX.Ground.table.muted)
            Text(verbatim: session.title.resolve(ctx.variant) ?? "").dxType(.title).foregroundStyle(DX.Ground.table.ink)
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .background(LinearGradient(colors: [Color(hex: 0xFFE2C6), Color(hex: 0xFFC38A)], startPoint: .top, endPoint: .bottom),
                    in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}

/// The turn: the rear shows until halfway, then the face, so it reads as one card turning over.
private struct LessonFlip: ViewModifier, Animatable {
    nonisolated var animatableData: Double
    let isRear: Bool

    init(angle: Double, isRear: Bool) {
        animatableData = angle
        self.isRear = isRear
    }

    func body(content: Content) -> some View {
        let angle = animatableData
        content
            .rotation3DEffect(.degrees(isRear ? angle - 180 : angle), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
            .opacity(isRear ? (angle > 90 ? 1 : 0) : (angle <= 90 ? 1 : 0))
    }
}
