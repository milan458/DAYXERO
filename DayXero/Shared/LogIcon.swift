import DayXeroCore
import SwiftUI

/// The log icon family (4 Nov 2026): a soft circle in the thing's own colour with a simple glyph in a deeper shade of
/// it. One source for every place a product or a log shows an icon, so a pouch looks the same on Today, in the log
/// sheet, in Recent logs and in onboarding. Before this, each screen picked its own SF Symbol and they disagreed.
enum LogGlyph: String, CaseIterable, Sendable {
    case cigarette, puff, pouch, water, urge, craving, pledge, slip, kept

    static func product(_ product: Product) -> LogGlyph {
        switch product {
        case .cigarettes: .cigarette
        case .vape: .puff
        case .pouches: .pouch
        }
    }

    /// The circle behind the glyph.
    var chip: Color {
        switch self {
        case .cigarette: Color(light: 0xFFE3CC, dark: 0x3B2622)
        case .puff: Color(light: 0xE7E1FF, dark: 0x241C52)
        case .pouch: Color(light: 0xFFE0E8, dark: 0x3B1A2A)
        case .water: Color(light: 0xDCEBFF, dark: 0x0F2550)
        case .urge: Color(light: 0xDDE5FF, dark: 0x0B1A4A)
        case .craving: Color(light: 0xFFE0D6, dark: 0x3B1A14)
        case .pledge: Color(light: 0xFFE9B0, dark: 0x3A3110)
        // A slip is neutral, never red: nothing resets.
        case .slip: Color(light: 0xF1EBE2, dark: 0x2A255F)
        case .kept: Color(light: 0xDFF3E4, dark: 0x0F2A22)
        }
    }

    /// The glyph's ink: the chip's hue, deeper in light mode and lighter in dark.
    var ink: Color {
        switch self {
        case .cigarette: Color(light: 0x4A2A1A, dark: 0xFFC38A)
        case .puff: Color(light: 0x4A3E7A, dark: 0xC9BFF2)
        case .pouch: Color(light: 0x7A2E45, dark: 0xFFB3C1)
        case .water: Color(light: 0x24406E, dark: 0xB9D6FF)
        case .urge: Color(light: 0x2A52DB, dark: 0x9DB4FF)
        case .craving: Color(light: 0xB23A1E, dark: 0xFF9F85)
        case .pledge: Color(light: 0x5A4A10, dark: 0xFFD966)
        case .slip: Color(light: 0x5E5975, dark: 0xE0C8E8)
        case .kept: Color(light: 0x0F6E43, dark: 0x2FD08A)
        }
    }

    enum Paint {
        case stroke(CGFloat, dash: [CGFloat] = [])
        case fill
        /// Fill at an opacity of the ink.
        case wash(Double)
    }

    enum Tint {
        case ink
        /// The chip's own colour, for a highlight cut into the glyph.
        case chip
        case fixed(UInt32)
    }

    struct Part {
        let d: String
        let paint: Paint
        var tint: Tint = .ink
    }

    /// Drawn on a 24 × 24 grid.
    var parts: [Part] {
        switch self {
        case .cigarette:
            [Part(d: "M2.5 14h14v4h-14z", paint: .stroke(1.8)),
             Part(d: "M2.5 14h4.5v4H2.5z", paint: .fill),
             Part(d: "M16.5 14h3.5v4h-3.5z", paint: .fill, tint: .fixed(0xFF7155)),
             Part(d: "M19.2 11c0-1.5-1.6-1.8-1.6-3.3s1.6-1.7 1.6-3.2", paint: .stroke(1.8))]
        case .puff:
            [Part(d: "M10 9h4a2 2 0 0 1 2 2v8.5a2 2 0 0 1-2 2h-4a2 2 0 0 1-2-2V11a2 2 0 0 1 2-2z", paint: .stroke(1.8)),
             Part(d: "M10.2 9V6.6h3.6V9", paint: .stroke(1.8)),
             Part(d: "M11.3 12.4h1.4a1 1 0 0 1 1 1v2.2a1 1 0 0 1-1 1h-1.4a1 1 0 0 1-1-1v-2.2a1 1 0 0 1 1-1z", paint: .fill,
                  tint: .fixed(0x8E7CF0)),
             Part(d: "M7.2 3.8a1.4 1.4 0 1 0 2.8 0a1.4 1.4 0 1 0-2.8 0 M11.1 2.9a1.1 1.1 0 1 0 2.2 0a1.1 1.1 0 1 0-2.2 0 "
                     + "M14.3 3.9a1.3 1.3 0 1 0 2.6 0a1.3 1.3 0 1 0-2.6 0", paint: .stroke(1.5))]
        case .pouch:
            [Part(d: Self.pillow, paint: .wash(0.16)),
             Part(d: Self.pillow, paint: .stroke(1.8)),
             Part(d: "M6.6 10.1c2.6-.8 8.2-.8 10.8 0 .6 1.7.6 4.1 0 5.8-2.6.8-8.2.8-10.8 0-.6-1.7-.6-4.1 0-5.8z",
                  paint: .stroke(1.1, dash: [1.3, 1.5]))]
        case .water:
            [Part(d: "M12 3s7 7.6 7 12a7 7 0 0 1-14 0c0-4.4 7-12 7-12z", paint: .fill),
             Part(d: "M9 14.5a3.2 3.2 0 0 0 2.2 3", paint: .stroke(1.6), tint: .chip)]
        case .urge:
            [Part(d: "M3 9.5c3-3.5 6-3.5 9 0s6 3.5 9 0 M3 15.5c3-3.5 6-3.5 9 0s6 3.5 9 0", paint: .stroke(2.2))]
        case .craving:
            [Part(d: "M12 2.8c1.2 3.6 5.2 5.4 5.2 10.2a5.2 5.2 0 0 1-10.4 0c0-2.5 1.3-3.9 2.5-5 .1 1.6.8 2.7 1.9 3.1.1-3.2-.5-5.6.8-8.3z",
                  paint: .fill),
             Part(d: "M12 13.5c1.2 1 2 2 2 3.2a2 2 0 0 1-4 0c0-1.2.8-2.2 2-3.2z", paint: .fill, tint: .fixed(0xFFD966))]
        case .pledge:
            [Part(d: "M7.8 12a4.2 4.2 0 1 0 8.4 0a4.2 4.2 0 1 0-8.4 0", paint: .fill),
             Part(d: "M12 2.5v2.2 M12 19.3v2.2 M4.6 4.6l1.6 1.6 M17.8 17.8l1.6 1.6 M2.5 12h2.2 M19.3 12h2.2 M4.6 19.4l1.6-1.6 "
                     + "M17.8 6.2l1.6-1.6", paint: .stroke(1.9))]
        case .slip:
            [Part(d: Self.heart, paint: .wash(0.16)),
             Part(d: Self.heart, paint: .stroke(1.8))]
        case .kept:
            [Part(d: "M5.5 7.5a6.5 2.8 0 1 0 13 0a6.5 2.8 0 1 0-13 0 "
                     + "M5.5 7.5v4.5c0 1.5 2.9 2.8 6.5 2.8s6.5-1.3 6.5-2.8V7.5 M5.5 12v4.5c0 1.5 2.9 2.8 6.5 2.8s6.5-1.3 6.5-2.8V12",
                  paint: .stroke(1.8))]
        }
    }

    private static let pillow = "M4.5 8.2c3-1.4 12-1.4 15 0 1.2 2.5 1.2 7.1 0 9.6-3 1.4-12 1.4-15 0-1.2-2.5-1.2-7.1 0-9.6z"
    private static let heart = "M12 20s-7.2-4.5-7.2-9.8A4 4 0 0 1 12 7.8a4 4 0 0 1 7.2 2.4C19.2 15.5 12 20 12 20z"
}

/// A log icon: the glyph in its circle. 30 pt on Today and in Recent logs, 40 to 44 pt in rows, 64 pt in onboarding.
struct LogIcon: View {
    let glyph: LogGlyph
    var size: CGFloat = 30

    var body: some View {
        Canvas { context, canvas in
            let scale = canvas.width / 24
            let transform = CGAffineTransform(scaleX: scale, y: scale)
            for part in glyph.parts {
                let path = SVGPath.path(part.d).applying(transform)
                let color: Color = switch part.tint {
                case .ink: glyph.ink
                case .chip: glyph.chip
                case let .fixed(hex): Color(hex: hex)
                }
                switch part.paint {
                case let .stroke(width, dash):
                    context.stroke(path, with: .color(color),
                                   style: StrokeStyle(lineWidth: width * scale, lineCap: .round, lineJoin: .round,
                                                      dash: dash.map { $0 * scale }))
                case .fill:
                    context.fill(path, with: .color(color))
                case let .wash(opacity):
                    context.fill(path, with: .color(color.opacity(opacity)))
                }
            }
        }
        .frame(width: size * 0.56, height: size * 0.56)
        .frame(width: size, height: size)
        .background(glyph.chip, in: Circle())
        .accessibilityHidden(true)
    }
}
