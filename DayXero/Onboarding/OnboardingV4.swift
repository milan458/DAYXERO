import DayXeroCore
import SwiftUI

/// v4 onboarding palette. Question content sits in an answer tray on the reading surface
/// (white in light, #2A255F in dark), so it uses the reading ground's ink and muted colours.
enum Onb {
    static let ink = DX.Ground.reading.ink
    static let muted = DX.Ground.reading.muted
    static let raised = DX.Fill.raised
    static let surface = DX.Fill.surface
    /// Text on an ink-filled chip.
    static let onInk = DX.Ground.reading.background
    static let hairline = Color(light: (0x1E1A3A, 0.12), dark: (0xFFFFFF, 0.14))
    static let accent = DX.Fill.green
    static let accentSoft = Color(light: (0x0F6E43, 0.12), dark: (0x2FD08A, 0.16))

    /// The ground each step sits on (design doc §10, F01–F07).
    static func ground(for step: OnboardingStep) -> DX.Ground {
        switch step {
        case .welcome, .quitDay, .trial: .apricot
        case .building, .reveal: .mint
        default: .lilac
        }
    }
}

/// The answer tray: the reading surface the controls sit on, under Xero's question.
struct AnswerTrayCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("YOUR ANSWER").dxType(.caption).foregroundStyle(Onb.muted)
                .accessibilityHidden(true)
            content()
        }
        .foregroundStyle(Onb.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Onb.raised, in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
    }
}

/// Xero's message bubble: left-aligned, radius 20 20 20 4.
struct XeroBubble: View {
    let text: Text
    var large = false

    var body: some View {
        text
            .dxType(large ? .headline : .body)
            .foregroundStyle(DX.Ground.lilac.ink)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(DX.Fill.cardOnColour, in: UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 4,
                                                                         bottomTrailingRadius: 20, topTrailingRadius: 20,
                                                                         style: .continuous))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 24)
    }
}

/// v4 progress bar: green fill on a soft track.
struct OnbProgressBar: View {
    let value: Double
    let ground: DX.Ground

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(ground.ink.opacity(0.14))
                Capsule().fill(DX.Fill.green).frame(width: proxy.size.width * min(1, max(0, value)))
            }
        }
        .frame(height: 8)
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
    let isSelected: Bool
    let action: () -> Void

    init(_ title: LocalizedStringResource, detail: LocalizedStringResource? = nil, systemImage: String? = nil,
         isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.detail = detail
        self.systemImage = systemImage
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(isSelected ? Onb.onInk : Onb.ink)
                        .frame(width: 40, height: 40)
                        .background(isSelected ? Onb.ink : Onb.raised, in: Circle())
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).dxType(.headline).foregroundStyle(Onb.ink)
                    if let detail { Text(detail).dxType(.footnote).foregroundStyle(Onb.muted) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? DX.Fill.green : Onb.hairline)
                    .accessibilityHidden(true)
            }
            .padding(14)
            .frame(minHeight: 64)
            .background(Onb.surface, in: RoundedRectangle(cornerRadius: DX.Layout.answerChipRadius + 4, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DX.Layout.answerChipRadius + 4, style: .continuous)
                .strokeBorder(isSelected ? Onb.ink : .clear, lineWidth: 2))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(DX.Haptic.select, trigger: isSelected)
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
        case .micro: content.dxType(.caption).textCase(.uppercase).foregroundStyle(Onb.muted)
        case .heroDenominator: content.dxType(.headline).foregroundStyle(Onb.muted).monospacedDigit()
        }
    }
}
