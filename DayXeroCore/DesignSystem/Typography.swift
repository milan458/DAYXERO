import CoreText
import SwiftUI

/// Type scale. Each style is Inter at the methodology's size, scaling with Dynamic Type
/// relative to the matching system text style.
public extension DX {
    enum Typeface {
        public static let regular = "Inter-Regular"
        public static let medium = "Inter-Medium"
        public static let semibold = "Inter-SemiBold"
        public static let bold = "Inter-Bold"
        /// The Bio-Orb's numeral (S6.7).
        public static let extraBold = "Inter-ExtraBold"
        /// The Bio-Orb's cycle row and badge (S6.7).
        public static let mono = "JetBrainsMono-SemiBold"

        /// Registers the bundled Inter and JetBrains Mono faces. Call once at launch in the app and in each extension.
        public static func register() {
            guard !registered else { return }
            let bundle = Bundle(for: BundleToken.self)
            for name in [regular, medium, semibold, bold, extraBold, mono] {
                // A missing face falls back to the system font rather than crashing.
                guard let url = bundle.url(forResource: name, withExtension: "ttf") else { continue }
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
            registered = true
        }

        nonisolated(unsafe) private static var registered = false
    }

    enum TextStyle: CaseIterable, Sendable {
        case hero, heroDenominator, title, cardHeading, body, subtitle, micro, button

        var face: String {
            switch self {
            case .hero, .title: Typeface.bold
            case .cardHeading, .micro, .button: Typeface.semibold
            case .heroDenominator, .body, .subtitle: Typeface.regular
            }
        }

        var size: CGFloat {
            switch self {
            case .hero: 36
            case .heroDenominator: 20
            case .title: 26
            case .cardHeading: 17
            case .body: 16
            case .subtitle: 13
            case .micro: 11
            case .button: 16
            }
        }

        var relativeTo: Font.TextStyle {
            switch self {
            case .hero: .largeTitle
            case .heroDenominator: .title3
            case .title: .title
            case .cardHeading: .headline
            case .body: .body
            case .subtitle: .footnote
            case .micro: .caption2
            case .button: .callout
            }
        }

        /// Tracking in points at the base size (methodology gives em values).
        var tracking: CGFloat {
            switch self {
            case .hero: -0.03 * size
            case .title: -0.02 * size
            case .cardHeading, .button: -0.01 * size
            case .micro: 0.1 * size
            default: 0
            }
        }

        public var font: Font { .custom(face, size: size, relativeTo: relativeTo) }
    }
}

private final class BundleToken {}

public extension View {
    /// Applies a DayXero text style: face, Dynamic Type scaling, tracking and, for micro labels, uppercase.
    /// Pass `color` to override the style's default colour; a later `.foregroundStyle` won't, because
    /// the innermost style wins in SwiftUI.
    func dxText(_ style: DX.TextStyle, color: Color? = nil) -> some View {
        modifier(DXTextModifier(style: style, color: color))
    }
}

private struct DXTextModifier: ViewModifier {
    let style: DX.TextStyle
    let color: Color?

    func body(content: Content) -> some View {
        content
            .font(style.font)
            .tracking(style.tracking)
            .textCase(style == .micro ? .uppercase : nil)
            .foregroundStyle(color ?? defaultColor)
            .monospacedDigit()
    }

    private var defaultColor: Color {
        switch style {
        case .subtitle: DX.Palette.text2
        case .micro: DX.Palette.muted
        case .heroDenominator: DX.Palette.faint
        default: DX.Palette.text
        }
    }
}
