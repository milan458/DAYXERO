import DayXeroCore
import SwiftUI

/// The v4 reading tier (cream in light, navy #0E0B2B in dark): lessons, Program and Progress.
/// Moved screens use these instead of the old `DX.Palette` until Phase 8 removes it.
enum Read4 {
    static let ground = DX.Ground.reading
    static let background = DX.Ground.reading.background
    static let ink = DX.Ground.reading.ink
    static let muted = DX.Ground.reading.muted
    /// Decorative only (unselected rings, dividers); never for text.
    static let faint = Color(light: (0x1E1A3A, 0.38), dark: (0xFFF8EE, 0.38))
    static let hairline = Color(light: (0x1E1A3A, 0.12), dark: (0xFFFFFF, 0.14))
    static let track = Color(light: (0x1E1A3A, 0.12), dark: (0xFFFFFF, 0.16))
    /// Cards on the reading ground.
    static let card = DX.Fill.raised
    /// Inset fills: chips, fields, quiet rows.
    static let surface = DX.Fill.surface
    static let accent = DX.Fill.green
    static let accentSoft = Color(light: (0x0F6E43, 0.12), dark: (0x2FD08A, 0.16))
    /// Text on an ink fill.
    static let onInk = DX.Ground.reading.background
    /// Warnings and "coming soon": 5.1:1 on cream, 8.6:1 on navy.
    static let amber = Color(light: 0x8A5E0E, dark: 0xE5A93C)
}

extension View {
    /// The old text styles mapped onto the seven v4 steps, in reading colours.
    func v4Text(_ style: DX.TextStyle, color: Color? = nil) -> some View {
        modifier(V4TextModifier(style: style, color: color))
    }

    /// A card on the reading ground: raised fill, radius 18 (or as given), no outline.
    func v4Card(padding: CGFloat = DX.Space.m, radius: CGFloat = DX.Layout.smallCardRadius) -> some View {
        self.padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Read4.card, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

private struct V4TextModifier: ViewModifier {
    let style: DX.TextStyle
    let color: Color?

    func body(content: Content) -> some View {
        switch style {
        case .hero: content.dxType(.display).foregroundStyle(color ?? Read4.ink).monospacedDigit()
        case .title: content.dxType(.title).foregroundStyle(color ?? Read4.ink)
        case .cardHeading, .button: content.dxType(.headline).foregroundStyle(color ?? Read4.ink)
        case .body: content.dxType(.body).foregroundStyle(color ?? Read4.ink)
        case .subtitle: content.dxType(.footnote).foregroundStyle(color ?? Read4.muted)
        case .micro: content.dxType(.caption).textCase(.uppercase).foregroundStyle(color ?? Read4.muted)
        case .heroDenominator: content.dxType(.headline).foregroundStyle(color ?? Read4.muted).monospacedDigit()
        }
    }
}

/// `DXCard`'s v4 replacement with the same shape of call.
struct V4Card<Content: View>: View {
    var padding: CGFloat = DX.Space.l
    @ViewBuilder let content: () -> Content

    var body: some View {
        content().v4Card(padding: padding)
    }
}

/// The v4 secondary on the reading ground: a surface pill with ink text, 58 pt.
struct V4SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .dxFont(16, weight: 600, style: .body)
            .foregroundStyle(Read4.ink)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: DX.Layout.buttonHeight)
            .background(Read4.surface, in: Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

extension ButtonStyle where Self == V4SecondaryButtonStyle {
    static var v4Secondary: V4SecondaryButtonStyle { V4SecondaryButtonStyle() }
}

/// The v4 progress bar on the reading ground: green on a soft track, 8 pt.
struct V4ProgressBar: View {
    let value: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Read4.track)
                Capsule().fill(Read4.accent).frame(width: proxy.size.width * min(1, max(0, value)))
            }
        }
        .frame(height: 8)
        .accessibilityElement()
        .accessibilityValue(Text("\(Int((min(1, max(0, value)) * 100).rounded())) percent"))
    }
}
