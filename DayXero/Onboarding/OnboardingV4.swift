import DayXeroCore
import SwiftUI

/// v5 onboarding palette (cook/site/screens/001-014): every question sits on Xero's apricot (the one navy in dark),
/// answers are kit option rows on the ground's card, so ink and muted come from the apricot ground.
enum Onb {
    static let ink = DX.Ground.apricot.ink
    static let muted = DX.Ground.apricot.muted
    static let raised = DX.Ground.apricot.card
    static let surface = DX.Ground.apricot.card2
    /// Text on an ink-filled chip.
    static let onInk = DX.Ground.reading.background
    static let hairline = Color(light: (0x1E1A3A, 0.12), dark: (0xFFFFFF, 0.14))
    static let accent = DX.Fill.green
    static let accentSoft = DX.Fill.greenSoft

    /// The ground each step sits on (design doc §10, F01–F07).
    static func ground(for step: OnboardingStep) -> DX.Ground {
        // v5: every onboarding mockup, from the breath to the trial, sits on apricot.
        _ = step
        return .apricot
    }
}

/// The answers under the question (v5): no tray and no "YOUR ANSWER" eyebrow; the option rows and chips sit on the
/// ground in one 10 pt column (kit `.answers`). `label` is kept for call sites and no longer drawn.
struct AnswerTrayCard<Content: View>: View {
    var label: LocalizedStringKey? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            content()
        }
        .foregroundStyle(Onb.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Xero's message bubble: left-aligned, radius 20 20 20 4.
struct XeroBubble: View {
    let text: Text
    var large = false
    /// Card on colour on the lilac chat ground. On the cream reading ground pass `DX.Fill.surface` and a hairline,
    /// or the bubble disappears into the page.
    var fill: Color = DX.Ground.apricot.card
    var border: Color = DX.Ground.apricot.line

    var body: some View {
        let shape = UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 4,
                                           bottomTrailingRadius: 20, topTrailingRadius: 20, style: .continuous)
        text
            .dxType(large ? .headline : .body)
            .foregroundStyle(Onb.ink)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(fill, in: shape)
            .overlay(shape.stroke(border, lineWidth: 1))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 24)
    }
}

/// The onboarding progress (v5 kit `.progress.sun`): the ink on the track with the sun riding its end.
struct OnbProgressBar: View {
    let value: Double
    let ground: DX.Ground

    var body: some View {
        DXProgress(value, sun: true)
            .environment(\.dxGround, ground)
        .accessibilityElement()
        .accessibilityLabel(Text("Setup progress"))
        .accessibilityValue(Text("\(Int((value * 100).rounded())) percent"))
    }
}

/// A v4 option card on the answer tray: icon circle, title, detail, tick when chosen.
struct OnbOptionCard: View {
    let title: LocalizedStringResource
    let detail: LocalizedStringResource?
    let systemImage: String?
    /// A product's log icon (4 Nov 2026), in place of a symbol: the same icon the product has everywhere else.
    let glyph: LogGlyph?
    let isSelected: Bool
    let action: () -> Void
    /// One selection haptic per tap, on the card tapped (a trigger on `isSelected` fired twice in a single-choice group).
    @State private var taps = 0

    init(_ title: LocalizedStringResource, detail: LocalizedStringResource? = nil, systemImage: String? = nil,
         glyph: LogGlyph? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.detail = detail
        self.systemImage = systemImage
        self.glyph = glyph
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        // v5 kit `.opt` with a 52 pt art tile: the ground's card, a hairline; chosen, the warm tint, a 2 pt edge and the
        // filled radio with a tick.
        let g = DX.Ground.apricot
        let shape = RoundedRectangle(cornerRadius: DX.Layout.optionRadius, style: .continuous)
        Button {
            taps += 1
            action()
        } label: {
            HStack(spacing: 14) {
                if let glyph {
                    LogIcon(glyph: glyph, size: 40)
                        .frame(width: 52, height: 52)
                        .background(g.card2, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(Onb.ink)
                        .frame(width: 52, height: 52)
                        .background(g.card2, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).dxType(.headline).foregroundStyle(Onb.ink)
                    if let detail { Text(detail).dxType(.footnote).foregroundStyle(Onb.muted) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                DXRadio(isOn: isSelected, ground: g)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(minHeight: 64)
            .background(isSelected ? g.selTint : g.card, in: shape)
            .overlay(shape.strokeBorder(isSelected ? g.selEdge : g.line, lineWidth: isSelected ? 2 : 1))
            .contentShape(Rectangle())
            .animation(DX.Move.arrive.speed(2.4), value: isSelected)
        }
        .buttonStyle(.dxPress)
        .sensoryFeedback(DX.Haptic.select, trigger: taps)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

/// Maps the old text styles onto the v4 steps inside onboarding.
extension View {
    func onbText(_ style: DX.TextStyle) -> some View {
        modifier(OnbTextModifier(style: style))
    }
}

private struct OnbTextModifier: ViewModifier {
    let style: DX.TextStyle

    func body(content: Content) -> some View {
        switch style {
        case .hero: content.dxType(.large).foregroundStyle(Onb.ink).monospacedDigit()
        case .title: content.dxType(.title).foregroundStyle(Onb.ink)
        case .cardHeading, .button: content.dxType(.headline).foregroundStyle(Onb.ink)
        case .body: content.dxType(.body).foregroundStyle(Onb.ink)
        case .subtitle: content.dxType(.footnote).foregroundStyle(Onb.muted)
        case .micro: content.dxType(.caption).foregroundStyle(Onb.muted)
        case .heroDenominator: content.dxType(.headline).foregroundStyle(Onb.muted).monospacedDigit()
        }
    }
}
