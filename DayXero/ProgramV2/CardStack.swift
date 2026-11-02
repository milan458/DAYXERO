import DayXeroCore
import SwiftUI

/// How a session's lesson is taken: the 90-second card stack (MON-04, the default) or the recording.
/// The choice sticks across sessions; a session without a recording always reads.
enum LessonFormat: String {
    case read, listen

    static let key = "dx.lessonFormat"
}

/// The 90-second read (MON-04): the session's ideas as a short stack of cards, in place of the audio. Tap a card (or
/// "Turn it over") to see the idea behind the line on the front, then move to the next. "Listen instead" swaps in the
/// recording when the bundle has one. Under Reduce Motion the cards cross-fade instead of flipping and sliding.
struct CardStackStep: View {
    let session: ProgramContent.Session
    let ctx: BeatContext
    /// A recording exists, so "Listen instead" can show.
    let canListen: Bool
    let onListen: () -> Void
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var index = 0
    @State private var flipped = false
    @State private var turned: Set<Int> = []

    private var cards: [(front: String, back: String)] {
        (session.cards ?? []).map { (ctx.text($0.front), ctx.text($0.back)) }
    }

    var body: some View {
        let cards = cards
        VStack(alignment: .leading, spacing: DX.Space.s) {
            HStack(alignment: .firstTextBaseline) {
                Label("\(ProgramContent.cardStackSeconds)-second read", systemImage: "rectangle.stack")
                    .dxFont(14, weight: 600, style: .footnote).foregroundStyle(Read4.muted)
                Spacer(minLength: DX.Space.xs)
                if canListen {
                    Button(action: onListen) {
                        Label("Listen instead", systemImage: "headphones").dxFont(14, weight: 600, style: .footnote)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Read4.accent)
                    .frame(minHeight: DX.Layout.touchTarget)
                }
            }
            if cards.indices.contains(index) {
                stack(cards)
                    .frame(maxHeight: .infinity, alignment: .top)
                dots(count: cards.count)
                Button(buttonTitle(count: cards.count)) { primary(count: cards.count) }
                    .buttonStyle(.dx(.primary, on: .reading))
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                    .accessibilityIdentifier("cards.next")
            } else {
                // A session with no cards never builds this step; this only guards a content change mid-session.
                Spacer(minLength: 0)
                Button("Continue", action: onDone).buttonStyle(.dx(.primary, on: .reading))
            }
        }
        .sensoryFeedback(DX.Haptic.select, trigger: flipped)
        .sensoryFeedback(DX.Haptic.select, trigger: index)
    }

    // MARK: The stack

    /// The current card, with the next two peeking out underneath so it reads as a stack.
    private func stack(_ cards: [(front: String, back: String)]) -> some View {
        let card = cards[index]
        let left = cards.count - index - 1
        return ZStack(alignment: .top) {
            ForEach(Array((0..<min(left, 2)).reversed()), id: \.self) { depth in
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Read4.card)
                    .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(Read4.hairline))
                    .padding(.horizontal, CGFloat(depth + 1) * 10)
                    .offset(y: CGFloat(depth + 1) * 10)
                    .accessibilityHidden(true)
            }
            StackCard(number: index + 1, front: card.front, back: card.back, flipped: flipped, reduceMotion: reduceMotion) {
                turn()
            }
            .id(index)
            .transition(reduceMotion ? .opacity : .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                               removal: .move(edge: .leading).combined(with: .opacity)))
            .gesture(
                DragGesture(minimumDistance: 24).onEnded { drag in
                    if drag.translation.width < -60 { primary(count: cards.count) }
                    if drag.translation.width > 60, index > 0 { go(to: index - 1) }
                }
            )
        }
        .padding(.bottom, 20)
    }

    private func dots(count: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Capsule().fill(i <= index ? Read4.ink : Read4.track)
                    .frame(width: i == index ? 18 : 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Card \(index + 1) of \(count)"))
    }

    // MARK: Moving through

    private func buttonTitle(count: Int) -> LocalizedStringKey {
        if !flipped && !ctx.isReplay && !turned.contains(index) { return "Turn it over" }
        return index + 1 < count ? "Next card" : "Continue"
    }

    /// Turn the card first; once it's been turned (or on a replay), move on.
    private func primary(count: Int) {
        if !flipped && !ctx.isReplay && !turned.contains(index) {
            turn()
        } else if index + 1 < count {
            go(to: index + 1)
        } else {
            onDone()
        }
    }

    private func turn() {
        withAnimation(reduceMotion ? DX.Move.reduced : .spring(response: 0.5, dampingFraction: 0.8)) { flipped.toggle() }
        turned.insert(index)
    }

    private func go(to next: Int) {
        withAnimation(DX.Move.animation(DX.Move.settle, reduceMotion: reduceMotion)) {
            index = next
            flipped = false
        }
    }
}

/// One card of the stack: the line on the front, the idea on the back.
private struct StackCard: View {
    let number: Int
    let front: String
    let back: String
    let flipped: Bool
    let reduceMotion: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                face(back: false).opacity(flipped ? 0 : 1)
                face(back: true).opacity(flipped ? 1 : 0)
                    .rotation3DEffect(.degrees(reduceMotion ? 0 : 180), axis: (0, 1, 0))
            }
            .rotation3DEffect(.degrees(flipped && !reduceMotion ? 180 : 0), axis: (0, 1, 0), perspective: 0.6)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: flipped ? "\(front). \(back)" : front))
        .accessibilityHint(Text(flipped ? "Turns the card back" : "Turns the card over"))
    }

    private func face(back isBack: Bool) -> some View {
        VStack(alignment: .leading, spacing: DX.Space.s) {
            Text(verbatim: "\(number)").dxFont(14, weight: 700, style: .footnote)
                .foregroundStyle(isBack ? Read4.accent : Read4.muted)
            if isBack {
                Text(verbatim: front).dxFont(14, weight: 600, style: .footnote).foregroundStyle(Read4.accent)
                    .fixedSize(horizontal: false, vertical: true)
                Text(verbatim: back).dxFont(22, weight: 600, style: .title3).foregroundStyle(Read4.ink)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(verbatim: front).dxFont(26, weight: 700, style: .title2).foregroundStyle(Read4.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: DX.Space.s)
                Label("Tap to turn it over", systemImage: "arrow.triangle.2.circlepath")
                    .dxFont(14, weight: 400, style: .footnote).foregroundStyle(Read4.muted)
            }
        }
        .padding(DX.Space.l)
        .frame(maxWidth: .infinity, minHeight: 260, alignment: .topLeading)
        .background(isBack ? Read4.accentSoft : Read4.card, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(isBack ? .clear : Read4.hairline))
    }
}
