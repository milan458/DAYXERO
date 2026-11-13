import SwiftUI

/// v4 grounds (design/handoff/tokens.json → "grounds"). Colour follows the character:
/// apricot is Xero, ocean is Jelli, violet is Glim. Every ink and muted pair here
/// clears 4.5:1 in both modes; `V4TokenTests` checks it.
///
/// v5 (14 Nov 2026, cook/site/kit/kit.css is the source of truth): one ground per meaning. Apricot is Xero and your
/// days, mint your plan, ocean Jelli and SOS only, night (the `violet` case, renamed in meaning only) Glim's evenings,
/// reading the work, table the prep session, and sun for celebrations only. Dark mode is one neutral navy, #0E1322,
/// except ocean and night. Sky retired into reading.
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
        /// v5: the prep session "hand" (warm cream in light, the dark card table in dark).
        case table
        /// What's changing: the body timeline (decision 31).
        case lime
        /// Your patterns: when cravings hit and top triggers (decision 31).
        case mist
        /// Calm tools (decision 31).
        case periwinkle

        /// The grounds in use (v5). Retired cases resolve to one of these.
        public static let allCases: [Ground] = [.apricot, .mint, .ocean, .violet, .reading, .table, .sun]

        /// The ground this one draws as: itself, or for a retired case its survivor
        /// (coral → apricot; sky, lilac, mist, periwinkle → reading; lime → mint).
        public var resolved: Ground {
            switch self {
            case .coral: .apricot
            case .sky, .lilac, .mist, .periwinkle: .reading
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
            // v5 dark: one low-saturation navy for every ground but ocean and night.
            let midnight: UInt32 = 0x0E1322
            let mutedNight: UInt32 = 0xB3BACC
            switch self {
            case .apricot: return Spec(light: 0xFFC38A, dark: midnight, inkLight: navy, inkDark: cream, mutedLight: 0x4A2810, mutedDark: mutedNight)
            case .mint: return Spec(light: 0xD3F0DF, dark: midnight, inkLight: navy, inkDark: cream, mutedLight: 0x24493A, mutedDark: mutedNight)
            // Ocean's flat colour is the bottom of its lit-sea gradient (`DX.Ground.oceanGradient`).
            case .ocean: return Spec(light: 0x1F3C8C, dark: 0x0A1638, inkLight: cream, inkDark: cream, mutedLight: 0xD3DDF7, mutedDark: 0xB9C9FF)
            // Night ("midnight meadow"), Glim's evenings. Kept as `violet` so call sites compile.
            case .violet: return Spec(light: 0x0F1B33, dark: 0x0A1326, inkLight: 0xF6EFE2, inkDark: 0xF6EFE2, mutedLight: 0xAEB8D3, mutedDark: 0xA3ADC8)
            case .sun: return Spec(light: 0xFFD966, dark: midnight, inkLight: navy, inkDark: cream, mutedLight: 0x5A4A10, mutedDark: mutedNight)
            case .reading: return Spec(light: 0xFBF7F1, dark: midnight, inkLight: navy, inkDark: cream, mutedLight: 0x5E5975, mutedDark: mutedNight)
            case .table: return Spec(light: 0xF6F0E6, dark: midnight, inkLight: navy, inkDark: cream, mutedLight: 0x5E5975, mutedDark: mutedNight)
            case .coral, .lilac, .sky, .lime, .mist, .periwinkle: return resolved.spec
            }
        }

        /// v5 per-ground surface tokens (kit.css `--card --card-2 --line --btn --btn-fg --track --mark --sel`), as
        /// (hex, alpha) pairs so tests can composite them.
        public struct Tokens: Sendable {
            public typealias RGBA = (hex: UInt32, alpha: Double)
            public let card: RGBA
            public let card2: RGBA
            public let line: RGBA
            public let btn: UInt32
            public let btnFg: UInt32
            public let track: RGBA
            public let mark: UInt32
            /// The selected control's solid fill and its words (radio dots, reply bubbles).
            public let sel: UInt32
            public let selFg: UInt32
            /// Selection: a warm tint fill and a 2 pt edge.
            public let selTint: RGBA
            public let selEdge: UInt32
            /// True where cards need the 1 pt hairline to separate from the ground (reading, table, and every dark ground).
            public let hairline: Bool
        }

        /// `color-mix(in srgb, top a%, base)` as a solid colour.
        public static func mix(_ top: UInt32, _ alpha: Double, over base: UInt32) -> UInt32 {
            [16, 8, 0].reduce(0) { sum, shift in
                let b = Double((base >> shift) & 0xFF), t = Double((top >> shift) & 0xFF)
                return sum | (UInt32((b * (1 - alpha) + t * alpha).rounded()) << shift)
            }
        }

        public func tokens(dark: Bool) -> Tokens {
            let g = resolved
            let s = g.spec
            let cream: UInt32 = 0xFFF8EE, ink: UInt32 = 0x1E1A3A
            let lightTint = (Self.mix(0xFFB27A, 0.2, over: 0xFFFFFF), 1.0)
            switch (g, dark) {
            case (.ocean, false):
                return Tokens(card: (0x2A4A9E, 1), card2: (0x2F52AA, 1), line: (0xFFFFFF, 0.18), btn: cream, btnFg: 0x1F3C8C,
                              track: (0xFFFFFF, 0.22), mark: 0xFFD966, sel: cream, selFg: 0x1F3C8C,
                              selTint: (Self.mix(cream, 0.14, over: 0x2A4A9E), 1), selEdge: cream, hairline: false)
            case (.ocean, true):
                return Tokens(card: (0x152A6A, 1), card2: (0x1B3378, 1), line: (0xFFFFFF, 0.18), btn: cream, btnFg: 0x0A1638,
                              track: (0xFFFFFF, 0.22), mark: 0xFFD966, sel: cream, selFg: 0x0A1638,
                              selTint: (Self.mix(cream, 0.14, over: 0x152A6A), 1), selEdge: cream, hairline: true)
            case (.violet, false):
                return Tokens(card: (0x17243F, 1), card2: (0x1E2D4C, 1), line: (0xFFFFFF, 0.12), btn: 0xF3E7CC, btnFg: 0x0F1B33,
                              track: (0xFFFFFF, 0.16), mark: 0xFFD37A, sel: 0xF3E7CC, selFg: 0x0F1B33,
                              selTint: (Self.mix(cream, 0.14, over: 0x17243F), 1), selEdge: 0xF3E7CC, hairline: true)
            case (.violet, true):
                return Tokens(card: (0x121D35, 1), card2: (0x182540, 1), line: (0xFFFFFF, 0.12), btn: 0xEADDC0, btnFg: 0x0A1326,
                              track: (0xFFFFFF, 0.16), mark: 0xFFD37A, sel: 0xEADDC0, selFg: 0x0A1326,
                              selTint: (Self.mix(cream, 0.14, over: 0x121D35), 1), selEdge: 0xEADDC0, hairline: true)
            case (_, true):
                // One neutral navy; selection is a warm apricot lift with an apricot edge.
                let mark: UInt32 = g == .mint ? 0x9FE3BC : (g == .table ? 0xFFD966 : 0xFF8A65)
                return Tokens(card: (0x182034, 1), card2: (0x212A41, 1), line: (0xFFFFFF, 0.12), btn: cream, btnFg: 0x0E1322,
                              track: (0xFFFFFF, 0.14), mark: mark, sel: cream, selFg: g == .reading ? ink : 0x0E1322,
                              selTint: (Self.mix(0xFFC89A, 0.15, over: 0x182034), 1), selEdge: 0xFFB27A, hairline: true)
            case (.reading, false), (.table, false):
                return Tokens(card: (0xFFFFFF, 1), card2: (g == .table ? 0xEDE5D8 : 0xF1EBE2, 1), line: (ink, 0.12), btn: ink, btnFg: cream,
                              track: (ink, 0.12), mark: g == .table ? 0xFFD966 : 0xFF7A55, sel: ink, selFg: cream,
                              selTint: lightTint, selEdge: 0xF26A45, hairline: true)
            default:
                // Apricot, mint, sun: white cards at 92%, card-2 is the ground mixed 38% into white.
                return Tokens(card: (0xFFFFFF, 0.92), card2: (Self.mix(s.light, 0.38, over: 0xFFFFFF), 1), line: (ink, 0.12),
                              btn: ink, btnFg: cream, track: (ink, 0.14), mark: 0xFF7A55, sel: ink, selFg: cream,
                              selTint: lightTint, selEdge: 0xF26A45, hairline: false)
            }
        }

        private func adaptive(_ pick: (Tokens) -> Tokens.RGBA) -> Color {
            let l = pick(tokens(dark: false)), d = pick(tokens(dark: true))
            return Color(light: (l.hex, l.alpha), dark: (d.hex, d.alpha))
        }

        private func adaptive(_ pick: (Tokens) -> UInt32) -> Color {
            Color(light: pick(tokens(dark: false)), dark: pick(tokens(dark: true)))
        }

        public var card: Color { adaptive { $0.card } }
        public var card2: Color { adaptive { $0.card2 } }
        public var line: Color { adaptive { $0.line } }
        public var btn: Color { adaptive { $0.btn } }
        public var btnFg: Color { adaptive { $0.btnFg } }
        public var track: Color { adaptive { $0.track } }
        public var mark: Color { adaptive { $0.mark } }
        public var sel: Color { adaptive { $0.sel } }
        public var selFg: Color { adaptive { $0.selFg } }
        public var selTint: Color { adaptive { $0.selTint } }
        public var selEdge: Color { adaptive { $0.selEdge } }

        /// Ocean is a lit sea: a top glow over a three-stop gradient whose bottom is the flat ground colour, so docks
        /// and fades match (kit.css, last ocean rule).
        public static var oceanGradient: LinearGradient {
            LinearGradient(stops: [
                .init(color: Color(light: 0x3A68C8, dark: 0x13295F), location: 0),
                .init(color: Color(light: 0x2A50AA, dark: 0x0E1F4C), location: 0.45),
                .init(color: Color(light: 0x1F3C8C, dark: 0x0A1638), location: 1),
            ], startPoint: .top, endPoint: .bottom)
        }

        public var background: Color { Color(light: spec.light, dark: spec.dark) }
        public var ink: Color { Color(light: spec.inkLight, dark: spec.inkDark) }
        public var muted: Color { Color(light: spec.mutedLight, dark: spec.mutedDark) }
    }

    /// Surfaces and fills shared across grounds.
    enum Fill {
        /// Reading-ground cards.
        /// v5: the reading ground's card-2 and card (dark: the one neutral navy's #212A41 and #182034).
        public static let surface = Color(light: 0xF1EBE2, dark: 0x212A41)
        public static let raised = Color(light: 0xFFFFFF, dark: 0x182034)
        /// Cards laid on a coloured ground. S27.13: white at 90% (light) and 13% (dark), so a card separates from
        /// every light ground by at least 1.3:1. Was cream at 70% and white at 10%, which nearly vanished.
        /// v5: white at 92% in light; the solid #182034 card in dark, which carries `hairline`.
        public static let cardOnColour = Color(light: (0xFFFFFF, cardLightAlpha), dark: (0x182034, 1))
        public static let cardLightAlpha = 0.92
        public static let cardDarkAlpha = 0.13
        /// Navy over the cream-ink grounds (ocean, violet) in light mode. 44% keeps violet's card at 1.31:1 from the
        /// ground and cream ink above 9:1 (the lab draws 42%, which is 1.296:1 on violet).
        public static let cardNavyAlpha = 0.44
        /// A hairline round cards, for the cream reading ground, where no fill can separate a card by 1.3:1.
        public static let hairline = Color(light: (0x1E1A3A, 0.12), dark: (0xFFFFFF, 0.12))

        /// Card on colour for a given ground (decision 25, S27.13). Ocean and violet keep cream ink in light mode,
        /// so a light card would wash the text out: in light they get a navy tint instead.
        /// v5: the ground's own `--card` token (ocean #2A4A9E, night #17243F, white 92% on day grounds).
        public static func onColourCard(for ground: DX.Ground) -> Color {
            ground.resolved.card
        }
        /// The one "good" green (QW7, option A, 3 Nov 2026): every green in the UI comes from these tokens. Light
        /// replaced #1FA971, which failed contrast with white; dark is the bright green that reads on night grounds.
        public static let greenLight: UInt32 = 0x0F6E43
        public static let greenDark: UInt32 = 0x2FD08A
        /// Success words: "+1", "Done" labels. Text-safe (4.5:1) in both modes.
        public static let green = Color(light: greenLight, dark: greenDark)
        /// v5 done green: tick discs, the hold button's done check, done stops. Non-text only (3:1 against white
        /// ticks and every ground); words in green use `green`.
        public static let doneHex: UInt32 = 0x1F9D63
        public static let done = Color(hex: doneHex)
        /// v5 ink and cream.
        public static let ink = Color(hex: 0x1E1A3A)
        public static let coral = Color(hex: 0xFF7A55)
        public static let sunYellow = Color(hex: 0xFFD966)
        /// Ticks on an ink chip or a filled control, in either mode: the deep green vanishes on ink.
        public static let greenOnDark = Color(hex: greenDark)
        /// The lesson card's fill. Deep green in both modes, so its cream text holds 5.98:1.
        public static let lessonCard = Color(hex: greenLight)
        /// A soft green wash: prep days on the calendar, quiet success badges.
        public static let greenSoft = Color(light: (greenLight, 0.12), dark: (greenDark, 0.16))
        /// Ocean secondary button. Never translucent white.
        public static let oceanSecondary = Color(light: 0x1D3A9E, dark: 0x1B2C66)
        public static let navy = Color(hex: 0x1E1A3A)
        public static let cream = Color(hex: 0xFFF8EE)
        public static let confetti: [Color] = [0xFF7A55, 0x2A52DB, 0x4A3596, greenLight, 0xFF8FB8, 0xFFF8EE].map { Color(hex: $0) }
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
