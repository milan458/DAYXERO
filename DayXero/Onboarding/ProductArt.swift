import DayXeroCore
import SwiftUI

/// The paper-cut product objects from the kit (003): flat cut pieces in Xero's own materials, a crescent side shade,
/// one highlight stroke and a short paper shadow under each piece. Drawn on a 44 × 44 grid.
struct ProductArt: View {
    let product: Product
    var size: CGFloat = 42
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let dark = scheme == .dark
        let shadow = dark ? Color.black.opacity(0.55) : Color(red: 120 / 255, green: 52 / 255, blue: 24 / 255).opacity(0.24)
        ZStack {
            switch product {
            case .cigarettes: cigarette(dark: dark)
            case .vape: vape
            case .pouches: pouch
            }
        }
        .compositingGroup()
        .frame(width: 44, height: 44)
        .scaleEffect(size / 44)
        .frame(width: size, height: size)
        .environment(\.artShadow, shadow)
        .accessibilityHidden(true)
    }

    private func cigarette(dark: Bool) -> some View {
        let r = Art44.rotation(-34, 22, 25)
        return ZStack {
            Art44("M36.6 12 C32.2 9.8 40.2 7.4 35.6 3.2")
                .stroke(dark ? Color(hex: 0x7E89AA) : Color(hex: 0xD0B6A6), style: StrokeStyle(lineWidth: 2.8, lineCap: .round))
                .paperShadow()
            ZStack {
                ZStack {
                    Art44(rect: CGRect(x: 3, y: 20, width: 38, height: 10), r).fill(Color(hex: 0xFFFDF8))
                    Art44(rect: CGRect(x: 3, y: 26.4, width: 38, height: 4), r).fill(Color(hex: 0xEFE1CF))
                    Art44(rect: CGRect(x: 3, y: 20, width: 12, height: 10), r).fill(Color(hex: 0xFFAE73))
                    Art44(rect: CGRect(x: 3, y: 26.4, width: 12, height: 4), r).fill(Color(hex: 0xF29055))
                    Art44(rect: CGRect(x: 35, y: 20, width: 6, height: 10), r).fill(Color(hex: 0xFF7155))
                    Art44(rect: CGRect(x: 35, y: 26.4, width: 6, height: 4), r).fill(Color(hex: 0xE85A3E))
                }
                .clipShape(Art44(rect: CGRect(x: 3, y: 20, width: 38, height: 10), radius: 3, r))
                Art44(ellipse: CGRect(x: 36.7, y: 22.5, width: 3.8, height: 3.8), r).fill(Color(hex: 0xFFC93C))
                Art44("M17.5 22.6 H29", r).stroke(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
            }
            .compositingGroup()
            .paperShadow()
        }
    }

    private var vape: some View {
        let r = Art44.rotation(10, 22, 22)
        return ZStack {
            Art44("M17.5 3.5 h9 a1.6 1.6 0 0 1 1.6 1.8 l-.9 6.2 h-10.4 l-.9 -6.2 a1.6 1.6 0 0 1 1.6 -1.8 z", r)
                .fill(Color(hex: 0x1E1A3A)).paperShadow()
            ZStack {
                Art44(rect: CGRect(x: 12.5, y: 10, width: 19, height: 31), radius: 7, r).fill(Color(hex: 0xFF7155))
                Art44("M25.5 10.4 a7 7 0 0 1 6 6.9 v16.6 a7 7 0 0 1 -7 7 h-2 c3.6 -1.4 5 -4.4 5 -7.6 v-16.2 c0 -3 -.7 -5.2 -2 -6.7 z", r)
                    .fill(Color(hex: 0xE85A3E))
                Art44("M15.6 19 c0 -3 1 -5 2.8 -6", r).stroke(Color(hex: 0xFFB09C), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                Art44(rect: CGRect(x: 16.5, y: 16, width: 8, height: 13.5), radius: 4, r).fill(Color(hex: 0xFFF8EE))
                Art44("M16.5 23 c2.2 -1.1 5 .9 8 -.2 v2.7 a4 4 0 0 1 -4 4 a4 4 0 0 1 -4 -4 z", r).fill(Color(hex: 0xBFD7FF))
                Art44(ellipse: CGRect(x: 18.3, y: 32.8, width: 4.4, height: 4.4), r).fill(Color(hex: 0xFFC93C))
            }
            .compositingGroup()
            .paperShadow()
        }
    }

    private var pouch: some View {
        let r = Art44.rotation(-16, 31, 33)
        return ZStack {
            ZStack {
                Art44(ellipse: CGRect(x: 4.5, y: 5, width: 30, height: 30)).fill(Color(hex: 0x2E9A69))
                Art44(ellipse: CGRect(x: 4.6, y: 5.2, width: 27.2, height: 27.2)).fill(Color(hex: 0x3FB37F))
                Art44(ellipse: CGRect(x: 9.6, y: 10.2, width: 17.2, height: 17.2)).stroke(Color(hex: 0x9FE3BC), lineWidth: 2.2)
                Art44("M8.4 15 c1.2 -3.6 4 -6.2 7.6 -7").stroke(Color(hex: 0xC9F0D8), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
            }
            .compositingGroup()
            .paperShadow()
            ZStack {
                Art44(rect: CGRect(x: 22.5, y: 27, width: 17, height: 11), r).fill(Color(hex: 0xFFFDF8))
                Art44(rect: CGRect(x: 22.5, y: 34.2, width: 17, height: 4), r).fill(Color(hex: 0xEFE1CF))
            }
            .clipShape(Art44(rect: CGRect(x: 22.5, y: 27, width: 17, height: 11), radius: 5.5, r))
            .paperShadow()
        }
    }
}

private struct ArtShadowKey: EnvironmentKey {
    static let defaultValue = Color.black.opacity(0.2)
}

extension EnvironmentValues {
    fileprivate var artShadow: Color {
        get { self[ArtShadowKey.self] }
        set { self[ArtShadowKey.self] = newValue }
    }
}

private struct PaperShadow: ViewModifier {
    @Environment(\.artShadow) private var color
    func body(content: Content) -> some View { content.shadow(color: color, radius: 1, x: 0, y: 1.6) }
}

private extension View {
    func paperShadow() -> some View { modifier(PaperShadow()) }
}

/// A path on the 44 × 44 art grid, drawn at its own size (the art is scaled as a whole).
struct Art44: Shape {
    let base: Path

    init(_ d: String, _ t: CGAffineTransform = .identity) { base = SVGPath.path(d).applying(t) }
    init(rect: CGRect, radius: CGFloat = 0, _ t: CGAffineTransform = .identity) {
        base = (radius > 0 ? Path(roundedRect: rect, cornerRadius: radius) : Path(rect)).applying(t)
    }
    init(ellipse: CGRect, _ t: CGAffineTransform = .identity) { base = Path(ellipseIn: ellipse).applying(t) }

    static func rotation(_ degrees: Double, _ cx: CGFloat, _ cy: CGFloat) -> CGAffineTransform {
        CGAffineTransform(translationX: cx, y: cy).rotated(by: degrees * .pi / 180).translatedBy(x: -cx, y: -cy)
    }

    func path(in rect: CGRect) -> Path {
        base.applying(CGAffineTransform(scaleX: rect.width / 44, y: rect.height / 44)).offsetBy(dx: rect.minX, dy: rect.minY)
    }
}
