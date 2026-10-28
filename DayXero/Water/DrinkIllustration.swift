import DayXeroCore
import SwiftUI

/// A small drawing of each drink (S21.3), from the signed-off drink illustrations board: white line work on the
/// Water page's black, with the drink's own colour inside. Drawn on a 34 × 34 grid.
struct DrinkIllustration: View {
    let drink: Drink
    var size: CGFloat = 30

    var body: some View {
        Canvas { context, canvas in
            context.scaleBy(x: canvas.width / 34, y: canvas.height / 34)
            Self.draw(drink, in: &context)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private static let line = Color.white.opacity(0.85)
    private static let water = Color(hex: 0x7DBBF2)
    private static let foam = Color(hex: 0xEAF5FF)

    private static func draw(_ drink: Drink, in c: inout GraphicsContext) {
        let stroke = StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round)
        switch drink {
        case .glass:
            c.fill(path { p in
                p.move(to: pt(10.2, 16)); p.addLine(to: pt(23.8, 16)); p.addLine(to: pt(23, 28))
                p.addQuadCurve(to: pt(21.6, 29.2), control: pt(22.8, 29.2)); p.addLine(to: pt(12.4, 29.2))
                p.addQuadCurve(to: pt(11, 28), control: pt(11.2, 29.2)); p.closeSubpath()
            }, with: .color(water))
            c.stroke(path { p in
                p.move(to: pt(10.2, 16)); p.addQuadCurve(to: pt(17, 16), control: pt(13.6, 14.6))
                p.addQuadCurve(to: pt(23.8, 16), control: pt(20.4, 17.4))
            }, with: .color(foam), lineWidth: 1)
            c.stroke(path { p in
                p.move(to: pt(9, 7)); p.addLine(to: pt(25, 7)); p.addLine(to: pt(23, 28))
                p.addQuadCurve(to: pt(20.8, 30), control: pt(22.8, 30)); p.addLine(to: pt(13.2, 30))
                p.addQuadCurve(to: pt(11, 28), control: pt(11.2, 30)); p.closeSubpath()
            }, with: .color(line), style: stroke)
        case .bottle:
            c.fill(Path(roundedRect: CGRect(x: 14, y: 3, width: 6, height: 4), cornerRadius: 1.2), with: .color(line))
            c.fill(path { p in
                p.move(to: pt(11.9, 18)); p.addLine(to: pt(22.1, 18)); p.addLine(to: pt(22.1, 28))
                p.addQuadCurve(to: pt(20, 30.1), control: pt(22.1, 30.1)); p.addLine(to: pt(14, 30.1))
                p.addQuadCurve(to: pt(11.9, 28), control: pt(11.9, 30.1)); p.closeSubpath()
            }, with: .color(water))
            c.stroke(path { p in p.move(to: pt(14, 21)); p.addLine(to: pt(14, 27)) },
                     with: .color(foam.opacity(0.8)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
            c.stroke(path { p in
                p.move(to: pt(14.5, 7)); p.addLine(to: pt(14.5, 10)); p.addQuadCurve(to: pt(11, 16), control: pt(11, 12))
                p.addLine(to: pt(11, 28)); p.addQuadCurve(to: pt(14, 31), control: pt(11, 31)); p.addLine(to: pt(20, 31))
                p.addQuadCurve(to: pt(23, 28), control: pt(23, 31)); p.addLine(to: pt(23, 16))
                p.addQuadCurve(to: pt(19.5, 10), control: pt(23, 12)); p.addLine(to: pt(19.5, 7))
            }, with: .color(line), style: stroke)
        case .tea:
            c.stroke(path { p in
                p.move(to: pt(12, 5)); p.addQuadCurve(to: pt(12, 9), control: pt(10.5, 7)); p.addQuadCurve(to: pt(12, 13), control: pt(13.5, 11))
                p.move(to: pt(17, 4)); p.addQuadCurve(to: pt(17, 8), control: pt(15.5, 6)); p.addQuadCurve(to: pt(17, 12), control: pt(18.5, 10))
            }, with: .color(.white.opacity(0.55)), style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
            c.fill(path { p in
                p.move(to: pt(7, 18)); p.addLine(to: pt(23, 18)); p.addLine(to: pt(23, 22))
                p.addQuadCurve(to: pt(17, 28), control: pt(23, 28)); p.addLine(to: pt(13, 28))
                p.addQuadCurve(to: pt(7, 22), control: pt(7, 28)); p.closeSubpath()
            }, with: .color(Color(hex: 0xD9A35B)))
            c.stroke(path { p in
                p.move(to: pt(6, 16)); p.addLine(to: pt(24, 16)); p.addLine(to: pt(24, 22))
                p.addQuadCurve(to: pt(17, 29), control: pt(24, 29)); p.addLine(to: pt(13, 29))
                p.addQuadCurve(to: pt(6, 22), control: pt(6, 29)); p.closeSubpath()
                p.move(to: pt(24, 18.5)); p.addLine(to: pt(26, 18.5)); p.addQuadCurve(to: pt(29, 21.5), control: pt(29, 18.5))
                p.addQuadCurve(to: pt(26, 24.5), control: pt(29, 24.5)); p.addLine(to: pt(23.5, 24.5))
            }, with: .color(line), style: stroke)
            c.stroke(path { p in p.move(to: pt(5, 31)); p.addLine(to: pt(25, 31)) },
                     with: .color(.white.opacity(0.5)), style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
        case .sparkling:
            c.fill(path { p in
                p.move(to: pt(11.6, 12)); p.addLine(to: pt(22.4, 12)); p.addLine(to: pt(21.9, 29))
                p.addQuadCurve(to: pt(20.6, 30.2), control: pt(21.8, 30.2)); p.addLine(to: pt(13.4, 30.2))
                p.addQuadCurve(to: pt(12.1, 29), control: pt(12.2, 30.2)); p.closeSubpath()
            }, with: .color(Color(hex: 0xA9D2F7)))
            for (x, y, r) in [(15.0, 25.0, 1.3), (19.0, 20.0, 1.1), (16.5, 16.0, 0.9), (19.5, 27.0, 0.8)] {
                c.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r)), with: .color(.white))
            }
            c.stroke(path { p in
                p.move(to: pt(11, 5)); p.addLine(to: pt(23, 5)); p.addLine(to: pt(22, 29))
                p.addQuadCurve(to: pt(19.9, 31), control: pt(21.9, 31)); p.addLine(to: pt(14.1, 31))
                p.addQuadCurve(to: pt(12, 29), control: pt(12.1, 31)); p.closeSubpath()
            }, with: .color(line), style: stroke)
        }
    }

    private static func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }
    private static func path(_ build: (inout Path) -> Void) -> Path {
        var p = Path()
        build(&p)
        return p
    }
}
