import SwiftUI

/// A line a crew member says (BET-3, signed off by Milan in the Screen Lab on 3 Nov 2026).
///
/// Radius 20 with one 4 pt corner pointing at whoever speaks, or a small point on top when the speaker is above. Card
/// on colour on colour grounds, solid cream over art, white with a hairline on the reading ground. Bubbles arrive in
/// order: typing dots for 0.4 s, then the line rises in (Arrive), 1.2 s apart; earlier ones stay. With motion reduced
/// they're all there at once. Nothing on a screen waits for them.
public struct CrewBubble: View {
    public enum Tail: Sendable {
        /// The speaker is on the left, level with the bubble's bottom.
        case bottomLeading
        /// The speaker is on the left, level with the bubble's top.
        case topLeading
        /// The speaker is above: a small point on the top edge.
        case up
    }

    public enum Fill: Sendable {
        /// From the ground: card on colour, or white with a hairline on the reading ground.
        case auto
        /// Solid cream, for bubbles over art (Welcome's sky).
        case cream
    }

    public enum Size: Sendable {
        /// 16 pt body.
        case line
        /// 19 pt headline, for a first line that greets.
        case callout
        /// 24 pt title, for a line that is the screen's heading.
        case title
    }

    /// Seconds between bubbles, and the typing dots before each.
    public static let gap: Double = 1.2
    public static let typing: Double = 0.4

    let text: String
    let ground: DX.Ground
    let tail: Tail
    let size: Size
    let fill: Fill
    /// When it arrives, counted in bubbles from `start`: 0 first. nil shows it at once.
    let order: Int?
    let start: Double

    private enum Phase { case waiting, typing, shown }
    @State private var phase: Phase = .waiting
    private let motion = MotionPolicy()

    public init(_ text: String, on ground: DX.Ground, tail: Tail = .bottomLeading, size: Size = .line, fill: Fill = .auto,
                order: Int? = 0, start: Double = 0.4) {
        self.text = text
        self.ground = ground
        self.tail = tail
        self.size = size
        self.fill = fill
        self.order = order
        self.start = start
    }

    public var body: some View {
        Text(verbatim: text)
            .dxType(size == .title ? .title : size == .callout ? .headline : .body)
            .multilineTextAlignment(tail == .up ? .center : .leading)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(ink)
            .opacity(phase == .shown ? 1 : 0)
            .padding(.horizontal, size == .title ? 16 : 14)
            .padding(.vertical, size == .title ? 12 : 10)
            .background {
                ZStack(alignment: .top) {
                    shape.fill(background)
                    if ground.resolved == .reading, fill == .auto { shape.strokeBorder(DX.Fill.hairline) }
                    if tail == .up {
                        RoundedRectangle(cornerRadius: 3, style: .continuous).fill(background)
                            .frame(width: 14, height: 14).rotationEffect(.degrees(45)).offset(y: -6)
                    }
                }
            }
            .overlay {
                if phase == .typing { dots }
            }
            .opacity(phase == .waiting ? 0 : 1)
            .offset(y: phase == .waiting && !motion.reduce ? DX.Move.arriveRise : 0)
            .frame(maxWidth: .infinity, alignment: tail == .up ? .center : .leading)
            .task { await arrive() }
    }

    private var shape: UnevenRoundedRectangle {
        switch tail {
        case .bottomLeading: UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 4, bottomTrailingRadius: 20, topTrailingRadius: 20, style: .continuous)
        case .topLeading: UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: 20, bottomTrailingRadius: 20, topTrailingRadius: 20, style: .continuous)
        case .up: UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 20, bottomTrailingRadius: 20, topTrailingRadius: 20, style: .continuous)
        }
    }

    private var background: Color {
        if fill == .cream { return Color(light: 0xFFF8EE, dark: 0x2A255F) }
        return ground.resolved == .reading ? DX.Fill.raised : DX.Fill.onColourCard(for: ground)
    }

    private var ink: Color {
        fill == .cream ? Color(light: 0x1E1A3A, dark: 0xFFF8EE) : ground.ink
    }

    private var dots: some View {
        HStack(spacing: 5) {
            ForEach([0.6, 0.4, 0.25], id: \.self) { o in
                Circle().fill(ink.opacity(o)).frame(width: 7, height: 7)
            }
        }
        .accessibilityHidden(true)
    }

    private func arrive() async {
        guard let order, !motion.reduce else {
            phase = .shown
            return
        }
        let at = start + Double(order) * Self.gap
        try? await Task.sleep(for: .seconds(max(at - Self.typing, 0)))
        withAnimation(motion.animation(DX.Move.arrive)) { phase = .typing }
        try? await Task.sleep(for: .seconds(Self.typing))
        withAnimation(motion.animation(DX.Move.arrive)) { phase = .shown }
    }
}

/// A crew member with their lines beside them, bottom-aligned so the tails meet the art. VoiceOver reads it as one
/// passage: "Jelli says: …".
public struct CrewSpeech<Speaker: View>: View {
    public struct Line: Sendable {
        let text: String
        let size: CrewBubble.Size

        public init(_ text: String, size: CrewBubble.Size = .line) {
            self.text = text
            self.size = size
        }
    }

    let name: String
    let lines: [Line]
    let ground: DX.Ground
    let tail: CrewBubble.Tail
    let firstOrder: Int?
    let alignment: VerticalAlignment
    let speaker: Speaker

    /// - Parameters:
    ///   - name: who speaks, for VoiceOver.
    ///   - firstOrder: when the first line arrives, in bubbles; nil shows them all at once.
    ///   - alignment: `.bottom` for an avatar beside the last line, `.top` for card-size art beside the first.
    public init(_ name: String, lines: [Line], on ground: DX.Ground, tail: CrewBubble.Tail = .bottomLeading, firstOrder: Int? = 0,
                alignment: VerticalAlignment = .bottom, @ViewBuilder speaker: () -> Speaker) {
        self.name = name
        self.lines = lines
        self.ground = ground
        self.tail = tail
        self.firstOrder = firstOrder
        self.alignment = alignment
        self.speaker = speaker()
    }

    public var body: some View {
        HStack(alignment: alignment, spacing: 10) {
            speaker.accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(lines.enumerated()), id: \.offset) { i, line in
                    CrewBubble(line.text, on: ground, tail: tail, size: line.size, order: firstOrder.map { $0 + i })
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: String(localized: "\(name) says: \(lines.map(\.text).joined(separator: " "))")))
    }
}
