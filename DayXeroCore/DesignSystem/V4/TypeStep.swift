import CoreText
import SwiftUI
import UIKit

/// v4 type: seven sizes, 12 pt minimum (tokens.json → "type").
/// Bricolage Grotesque (one variable file) for display, DM Sans (variable) for body.
public extension DX {
    enum TypeStep: String, CaseIterable, Sendable {
        case display, large, title, headline, body, footnote, caption

        public enum Family: Sendable { case display, body }

        public var family: Family {
            switch self {
            case .display, .large, .title, .headline: .display
            case .body, .footnote, .caption: .body
            }
        }

        /// Base size in points before Dynamic Type.
        public var size: CGFloat {
            switch self {
            case .display: 40
            case .large: 32
            case .title: 24
            case .headline: 19
            case .body: 16
            case .footnote: 14
            case .caption: 12
            }
        }

        public var weight: CGFloat {
            switch self {
            case .display, .large, .title: 800
            case .headline, .caption: 700
            case .footnote: 500
            case .body: 400
            }
        }

        /// Tracking in points at the base size.
        public var tracking: CGFloat {
            switch self {
            case .display: -1.2
            case .large: -1.0
            case .title: -0.6
            case .caption: 0.8
            default: 0
            }
        }

        /// Extra line spacing in points (line height minus font size).
        public var lineSpacing: CGFloat {
            switch self {
            case .display: size * 0.02
            case .large: size * 0.08
            case .body: size * 0.5
            default: 0
            }
        }

        public var textStyle: UIFont.TextStyle {
            switch self {
            case .display, .large: .largeTitle
            case .title: .title2
            case .headline: .headline
            case .body: .body
            case .footnote: .footnote
            case .caption: .caption1
            }
        }

        /// The UIFont at a given Dynamic Type size, with weight and optical size set on the variable axes.
        public func uiFont(sizeCategory: UIContentSizeCategory = .large) -> UIFont {
            let traits = UITraitCollection(preferredContentSizeCategory: sizeCategory)
            let scaled = UIFontMetrics(forTextStyle: textStyle).scaledValue(for: size, compatibleWith: traits)
            return Typeface4.font(family, size: scaled, weight: weight)
        }

        public func font(sizeCategory: UIContentSizeCategory = .large) -> Font {
            Font(uiFont(sizeCategory: sizeCategory) as CTFont)
        }
    }

    /// Registration and construction for the two variable faces.
    enum Typeface4 {
        public static let displayFile = "BricolageGrotesque-Variable"
        public static let bodyFile = "DMSans-Variable"
        /// PostScript names of each file's default instance.
        public static let displayName = "BricolageGrotesque-96ptExtraBold"
        public static let bodyName = "DMSans-9ptRegular"

        static let wght = 0x7767_6874 // 'wght'
        static let opsz = 0x6F70_737A // 'opsz'

        /// Registers both faces. Call once at launch in the app and in each extension.
        public static func register() {
            guard !registered else { return }
            let bundle = Bundle(for: V4BundleToken.self)
            for name in [displayFile, bodyFile] {
                // A missing face falls back to the system font rather than crashing.
                guard let url = bundle.url(forResource: name, withExtension: "ttf") else { continue }
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
            registered = true
        }

        nonisolated(unsafe) private static var registered = false

        public static func font(_ family: TypeStep.Family, size: CGFloat, weight: CGFloat) -> UIFont {
            let name = family == .display ? displayName : bodyName
            // Optical size follows the point size, clamped to each file's axis range.
            let optical = family == .display ? min(max(size, 12), 96) : min(max(size, 9), 40)
            let variation: [Int: CGFloat] = [wght: weight, opsz: optical]
            let descriptor = UIFontDescriptor(fontAttributes: [
                .name: name,
                UIFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String): variation,
            ])
            return UIFont(descriptor: descriptor, size: size)
        }

        /// True once both faces resolve to themselves rather than a fallback.
        public static var isAvailable: Bool {
            [displayName, bodyName].allSatisfy { UIFont(name: $0, size: 12) != nil }
        }
    }
}

/// Applies a v4 type step: face, Dynamic Type scaling, tracking and line spacing.
public struct TypeStepModifier: ViewModifier {
    let step: DX.TypeStep
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public func body(content: Content) -> some View {
        content
            .font(step.font(sizeCategory: UIContentSizeCategory(dynamicTypeSize)))
            .tracking(step.tracking)
            .lineSpacing(step.lineSpacing)
    }
}

public extension View {
    func dxType(_ step: DX.TypeStep) -> some View {
        modifier(TypeStepModifier(step: step))
    }
}

private final class V4BundleToken {}

/// A v4 face at an explicit size and weight, for places that sit between the seven steps while
/// screens move over (never below 12 pt). Display face from 19 pt bold up, DM Sans otherwise.
public struct DXFontModifier: ViewModifier {
    let size: CGFloat
    let weight: CGFloat
    let style: UIFont.TextStyle
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public func body(content: Content) -> some View {
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(dynamicTypeSize))
        let base = max(12, size)
        let scaled = UIFontMetrics(forTextStyle: style).scaledValue(for: base, compatibleWith: traits)
        let family: DX.TypeStep.Family = base >= 19 && weight >= 700 ? .display : .body
        return content.font(Font(DX.Typeface4.font(family, size: scaled, weight: weight) as CTFont))
    }
}

public extension View {
    func dxFont(_ size: CGFloat, weight: CGFloat = 400, style: UIFont.TextStyle = .body) -> some View {
        modifier(DXFontModifier(size: size, weight: weight, style: style))
    }
}
