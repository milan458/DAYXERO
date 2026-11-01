import SwiftUI

/// The hand-drawn mark on one word of a screen title (decision 32): a loose underline, or a loop
/// around the word. One per screen, in the title only; the title reads the same without it.
/// It draws in once with Arrive; with Reduce Motion it is simply there.
public extension DX {
    enum Mark: Sendable {
        case underline
        case circle

        /// Coral on light grounds, cream on saturated ones, sun on ocean and violet (the canvas's choices).
        public static func color(on ground: DX.Ground) -> Color {
            switch ground {
            case .ocean, .violet: Color(light: 0xFFD966, dark: 0xFFD966)
            case .apricot, .coral, .sun, .periwinkle: Color(light: 0xFFF8EE, dark: 0xFF7A55)
            default: Color(hex: 0xFF7A55)
            }
        }
    }
}

/// The mark's stroke, stretched to the word's frame like the canvas's `preserveAspectRatio="none"` SVGs.
struct MarkShape: Shape {
    let mark: DX.Mark

    func path(in rect: CGRect) -> Path {
        switch mark {
        case .underline:
            return SVGPath.path("M3 10 C40 4 90 5 122 7 C152 9 178 11 197 4")
                .applying(CGAffineTransform(translationX: rect.minX, y: rect.minY).scaledBy(x: rect.width / 200, y: rect.height / 16))
        case .circle:
            return SVGPath.path("M72 5 C40 -1 4 8 3 26 C2 44 52 49 82 41 C99 35 101 15 85 7 C77 3 64 3 56 5")
                .applying(CGAffineTransform(translationX: rect.minX, y: rect.minY).scaledBy(x: rect.width / 100, y: rect.height / 50))
        }
    }
}

struct EmphasisModifier: ViewModifier {
    let mark: DX.Mark
    let color: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drawn = false

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    let w = proxy.size.width, h = proxy.size.height
                    switch mark {
                    case .underline:
                        MarkShape(mark: .underline)
                            .trim(from: 0, to: drawn ? 1 : 0)
                            .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: w + 4, height: 12)
                            .offset(x: -2, y: h - 4)
                    case .circle:
                        MarkShape(mark: .circle)
                            .trim(from: 0, to: drawn ? 1 : 0)
                            .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: w + 20, height: h + 8)
                            .offset(x: -10, y: -4)
                    }
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
            .onAppear {
                if reduceMotion { drawn = true; return }
                withAnimation(.easeOut(duration: 0.6).delay(0.35)) { drawn = true }
            }
    }
}

public extension View {
    /// Marks this word with the hand-drawn underline or loop. Apply it to the one word's `Text`.
    func dxMark(_ mark: DX.Mark = .underline, color: Color) -> some View {
        modifier(EmphasisModifier(mark: mark, color: color))
    }
}

/// A screen title with one marked word: "Your" + "patterns", or "What's" / "changing" on two lines.
public struct MarkedTitle: View {
    let lead: String
    let word: String
    let trail: String
    let mark: DX.Mark
    let color: Color
    let stacked: Bool
    /// The whole title as one plain string, for VoiceOver and UI tests.
    let spoken: String

    public init(_ lead: String = "", marking word: String, trail: String = "", mark: DX.Mark = .underline, color: Color, stacked: Bool = false) {
        self.spoken = stacked && !lead.isEmpty && !lead.hasSuffix(" ") ? lead + " " + word + trail : lead + word + trail
        // A space at the join would hang at the line's edge and collapse; a no-break space keeps the gap.
        self.lead = lead.hasSuffix(" ") ? String(lead.dropLast()) + "\u{00A0}" : lead
        self.word = word
        self.trail = trail.hasPrefix(" ") ? "\u{00A0}" + String(trail.dropFirst()) : trail
        self.mark = mark
        self.color = color
        self.stacked = stacked
    }

    public var body: some View {
        Group {
            if stacked {
                VStack(alignment: .leading, spacing: 0) {
                    if !lead.isEmpty { Text(verbatim: lead).lineLimit(1).minimumScaleFactor(0.6) }
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text(verbatim: word).lineLimit(1).minimumScaleFactor(0.6).dxMark(mark, color: color)
                        if !trail.isEmpty { Text(verbatim: trail).lineLimit(1).minimumScaleFactor(0.6) }
                    }
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    if !lead.isEmpty { Text(verbatim: lead).lineLimit(1).minimumScaleFactor(0.6) }
                    Text(verbatim: word).lineLimit(1).minimumScaleFactor(0.6).dxMark(mark, color: color)
                    if !trail.isEmpty { Text(verbatim: trail).lineLimit(1).minimumScaleFactor(0.6) }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: spoken))
        .accessibilityAddTraits([.isHeader, .isStaticText])
    }
}
