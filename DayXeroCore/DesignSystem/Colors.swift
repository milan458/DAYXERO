import SwiftUI
import UIKit

/// Colour tokens from DESIGN_METHODOLOGY.md (dark) plus the approved light palette.
/// Every token resolves per trait collection, so views follow the system or the in-app appearance setting.
public enum DX {}

public extension DX {
    enum Palette {
        // Fixed brand colours, identical in both themes.
        public static let sage = Color(hex: 0xBCC388)
        public static let moss = Color(hex: 0x43511C)
        public static let amber = Color(hex: 0xE5A93C)
        public static let terracotta = Color(hex: 0xC85A54)

        // Theme-aware roles.
        public static let canvas = Color(light: 0xF3F4EE, dark: 0x000000)
        public static let surface1 = Color(light: 0xFFFFFF, dark: 0x121212)
        public static let surface2 = Color(light: 0xECEEE4, dark: 0x161616)
        public static let surface3 = Color(light: 0xE2E5D8, dark: 0x1C1C1E)

        /// The single focal colour: primary buttons, active tab, today.
        public static let primary = Color(light: 0x11140A, dark: 0xFFFFFF)
        public static let onPrimary = Color(light: 0xFFFFFF, dark: 0x000000)
        /// Text on sage, amber and other fixed light fills.
        public static let onAccent = Color(hex: 0x000000)

        /// Sage used as text, strokes and progress (darker in light so it stays readable).
        public static let accentInk = Color(light: 0x55621F, dark: 0xBCC388)
        public static let accentSoft = Color(light: (0xBCC388, 0.45), dark: (0x43511C, 0.5))

        public static let text = Color(light: 0x11140A, dark: 0xFFFFFF)
        public static let text2 = Color(light: (0x11140A, 0.66), dark: (0xFFFFFF, 0.60))
        /// Raised from the methodology's 0.35 to pass WCAG AA for small text.
        public static let muted = Color(light: (0x11140A, 0.56), dark: (0xFFFFFF, 0.50))
        public static let faint = Color(light: (0x11140A, 0.38), dark: (0xFFFFFF, 0.35))
        public static let track = Color(light: (0x11140A, 0.12), dark: (0xFFFFFF, 0.12))

        public static let hairline = Color(light: (0x11140A, 0.09), dark: (0xFFFFFF, 0.08))
        public static let glassHighlight = Color(light: (0xFFFFFF, 0.9), dark: (0xFFFFFF, 0.16))
        public static let glassStart = Color(light: (0xBCC388, 0.55), dark: (0x43511C, 0.35))
        public static let glassEnd = Color(light: (0xFFFFFF, 0.85), dark: (0x141414, 0.65))
        public static let shadow = Color(light: (0x11140A, 0.18), dark: (0x000000, 0.6))
    }
}

public extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    init(light: UInt32, dark: UInt32) {
        self.init(light: (light, 1), dark: (dark, 1))
    }

    init(light: (UInt32, Double), dark: (UInt32, Double)) {
        self.init(uiColor: UIColor { traits in
            let (hex, alpha) = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(hex: hex, alpha: alpha)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: Double) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}
