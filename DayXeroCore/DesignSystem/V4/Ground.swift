import SwiftUI

/// v4 grounds (design/handoff/tokens.json → "grounds"). Colour follows the character:
/// apricot is Xero, ocean is Jelli, violet is Glim. Every ink and muted pair here
/// clears 4.5:1 in both modes; `V4TokenTests` checks it.
///
/// S27.13 (1 Nov 2026): six grounds plus sun. Twelve read as decoration; six can be learned, each with one job:
/// apricot = Xero's day, mint = your plan, ocean = Jelli and SOS, sky = relief, Xero's questions, patterns and calm,
/// violet = Glim's evening, reading = the work, and sun for celebrations only. The retired cases (coral, lilac, lime,
/// mist, periwinkle) stay so existing call sites compile, but draw their survivor's colours (`resolved`) and are left
/// out of `allCases`.
public extension DX {
    enum Ground: String, CaseIterable, Sendable {
        /// First breath, beginnings. Brand use pending decision 18.
        case coral
        /// Xero: days, pledge, Quit Day, welcome, reminders.
        case apricot
        /// Talking with Xero (chat) only.
        case lilac
        /// Your plan.
        case mint
        /// Jelli: SOS, cravings.
        case ocean
        /// Relief after a wave.
        case sky
        /// Glim: evenings, nights.
        case violet
        /// Celebrations only (Passed, milestones, finale).
        case sun
        /// Program, lesson, progress, slip.
        case reading
        /// What's changing: the body timeline (decision 31).
        case lime
        /// Your patterns: when cravings hit and top triggers (decision 31).
        case mist
        /// Calm tools (decision 31).
        case periwinkle

        /// The grounds in use (S27.13). Retired cases resolve to one of these.
        public static let allCases: [Ground] = [.apricot, .mint, .ocean, .sky, .violet, .reading, .sun]

        /// The ground this one draws as: itself, or for a retired case its survivor
        /// (coral → apricot; lilac, mist, periwinkle → sky; lime → mint).
        public var resolved: Ground {
            switch self {
            case .coral: .apricot
            case .lilac, .mist, .periwinkle: .sky
            case .lime: .mint
            default: self
            }
        }

        /// Raw hex values, kept separate from `Color` so tests can check contrast.
        public struct Spec: Sendable {
            public let light: UInt32
            public let dark: UInt32
            public let inkLight: UInt32
            public let inkDark: UInt32
            public let mutedLight: UInt32
            public let mutedDark: UInt32
        }

        public var spec: Spec {
            if resolved != self { return resolved.spec }
            let cream: UInt32 = 0xFFF8EE
            let navy: UInt32 = 0x1E1A3A
            let plum: UInt32 = 0x241433
            switch self {
            case .coral: return Spec(light: 0xFF7A55, dark: plum, inkLight: navy, inkDark: cream, mutedLight: 0x3B1A24, mutedDark: 0xE0C8E8)
            case .apricot: return Spec(light: 0xFFC38A, dark: plum, inkLight: navy, inkDark: cream, mutedLight: 0x4A2A1A, mutedDark: 0xE0C8E8)
            case .lilac: return Spec(light: 0xD9CCFF, dark: 0x1C1640, inkLight: navy, inkDark: cream, mutedLight: 0x4A3E7A, mutedDark: 0xC9BFF2)
            case .mint: return Spec(light: 0x9FE3BC, dark: 0x0F2A22, inkLight: navy, inkDark: cream, mutedLight: 0x24493A, mutedDark: 0xA9D9C0)
            case .ocean: return Spec(light: 0x2A52DB, dark: 0x0B1A4A, inkLight: cream, inkDark: cream, mutedLight: 0xE3EAFF, mutedDark: 0xB9C9FF)
            case .sky: return Spec(light: 0x9CCBFF, dark: 0x0F2550, inkLight: navy, inkDark: cream, mutedLight: 0x24406E, mutedDark: 0xB9D6FF)
            case .violet: return Spec(light: 0x4A3596, dark: 0x140E3A, inkLight: cream, inkDark: cream, mutedLight: 0xD2C8FF, mutedDark: 0xB8B3D9)
            case .sun: return Spec(light: 0xFFD966, dark: plum, inkLight: navy, inkDark: cream, mutedLight: 0x5A4A10, mutedDark: 0xE0C8E8)
            case .reading: return Spec(light: 0xFBF7F1, dark: 0x0E0B2B, inkLight: navy, inkDark: cream, mutedLight: 0x5E5975, mutedDark: 0xB8B3D9)
            case .lime: return Spec(light: 0xC1F07A, dark: 0x0F2A22, inkLight: navy, inkDark: cream, mutedLight: 0x33470F, mutedDark: 0xA9D9C0)
            case .mist: return Spec(light: 0xC9D6FF, dark: 0x0B1A4A, inkLight: navy, inkDark: cream, mutedLight: 0x24406E, mutedDark: 0xB9C9FF)
            case .periwinkle: return Spec(light: 0xB4C4FF, dark: 0x140E3A, inkLight: navy, inkDark: cream, mutedLight: 0x24406E, mutedDark: 0xB8B3D9)
            }
        }

        public var background: Color { Color(light: spec.light, dark: spec.dark) }
        public var ink: Color { Color(light: spec.inkLight, dark: spec.inkDark) }
        public var muted: Color { Color(light: spec.mutedLight, dark: spec.mutedDark) }
    }

    /// Surfaces and fills shared across grounds.
    enum Fill {
        /// Reading-ground cards.
        public static let surface = Color(light: 0xF1EBE2, dark: 0x1B1747)
        public static let raised = Color(light: 0xFFFFFF, dark: 0x2A255F)
        /// Cards laid on a coloured ground. S27.13: white at 90% (light) and 13% (dark), so a card separates from
        /// every light ground by at least 1.3:1. Was cream at 70% and white at 10%, which nearly vanished.
        public static let cardOnColour = Color(light: (0xFFFFFF, cardLightAlpha), dark: (0xFFFFFF, cardDarkAlpha))
        public static let cardLightAlpha = 0.90
        public static let cardDarkAlpha = 0.13
        /// Navy over the cream-ink grounds (ocean, violet) in light mode. 44% keeps violet's card at 1.31:1 from the
        /// ground and cream ink above 9:1 (the lab draws 42%, which is 1.296:1 on violet).
        public static let cardNavyAlpha = 0.44
        /// A hairline round cards, for the cream reading ground, where no fill can separate a card by 1.3:1.
        public static let hairline = Color(light: (0x1E1A3A, 0.12), dark: (0xFFFFFF, 0.14))

        /// Card on colour for a given ground (decision 25, S27.13). Ocean and violet keep cream ink in light mode,
        /// so a light card would wash the text out: in light they get a navy tint instead.
        public static func onColourCard(for ground: DX.Ground) -> Color {
            ground.spec.inkLight == 0xFFF8EE ? Color(light: (0x1E1A3A, cardNavyAlpha), dark: (0xFFFFFF, cardDarkAlpha)) : cardOnColour
        }
        /// Success fill. Light value replaced #1FA971, which failed contrast with white.
        public static let green = Color(light: 0x0F6E43, dark: 0x2FD08A)
        /// Ocean secondary button. Never translucent white.
        public static let oceanSecondary = Color(light: 0x1D3A9E, dark: 0x1B2C66)
        public static let navy = Color(hex: 0x1E1A3A)
        public static let cream = Color(hex: 0xFFF8EE)
        public static let confetti: [Color] = [0xFF7A55, 0x2A52DB, 0x4A3596, 0x0F6E43, 0xFF8FB8, 0xFFF8EE].map { Color(hex: $0) }
    }
}

/// WCAG 2 contrast, used by the token tests.
public enum Contrast {
    public static func luminance(_ hex: UInt32) -> Double {
        func channel(_ value: UInt32) -> Double {
            let c = Double(value & 0xFF) / 255
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(hex >> 16) + 0.7152 * channel(hex >> 8) + 0.0722 * channel(hex)
    }

    public static func ratio(_ a: UInt32, _ b: UInt32) -> Double {
        let la = luminance(a), lb = luminance(b)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }
}
