import SwiftUI

/// Reads SVG path data (`d` attributes) into a SwiftUI `Path`, so the crew is drawn from
/// the canvas files' own path strings rather than re-traced by hand.
/// Supports M L H V C S Q T A Z in absolute and relative forms, with implicit repeats.
/// Elliptical arcs (A) are converted to cubic curves, as the icon paths use them.
public enum SVGPath {
    public static func path(_ d: String) -> Path {
        var reader = Reader(tokens: tokenize(d))
        return reader.read()
    }

    enum Token: Equatable {
        case command(Character)
        case number(CGFloat)
    }

    static func tokenize(_ d: String) -> [Token] {
        var tokens: [Token] = []
        var number = ""
        func flush() {
            if let value = Double(number) { tokens.append(.number(CGFloat(value))) }
            number = ""
        }
        for ch in d {
            if ch.isLetter && ch != "e" && ch != "E" {
                flush()
                tokens.append(.command(ch))
            } else if ch == "-" || ch == "+" {
                // A sign starts a new number unless it follows an exponent.
                if let last = number.last, last == "e" || last == "E" {
                    number.append(ch)
                } else {
                    flush()
                    number.append(ch)
                }
            } else if ch == "." {
                if number.contains(".") && !number.contains("e") { flush() }
                number.append(ch)
            } else if ch.isNumber || ch == "e" || ch == "E" {
                number.append(ch)
            } else {
                flush()
            }
        }
        flush()
        return tokens
    }

    /// SVG endpoint arc → centre form → cubic segments of at most 90° (SVG 1.1 appendix F.6).
    static func addArc(to path: inout Path, from p0: CGPoint, to p1: CGPoint, rx rxIn: CGFloat, ry ryIn: CGFloat,
                       rotation: CGFloat, largeArc: Bool, sweep: Bool) {
        let rx = abs(rxIn), ry = abs(ryIn)
        guard rx > 0, ry > 0, p0 != p1 else {
            path.addLine(to: p1)
            return
        }
        let phi = Double(rotation) * .pi / 180
        let cosPhi = cos(phi), sinPhi = sin(phi)
        let dx = Double(p0.x - p1.x) / 2, dy = Double(p0.y - p1.y) / 2
        let x1 = cosPhi * dx + sinPhi * dy
        let y1 = -sinPhi * dx + cosPhi * dy
        var rxd = Double(rx), ryd = Double(ry)
        let lambda = (x1 * x1) / (rxd * rxd) + (y1 * y1) / (ryd * ryd)
        if lambda > 1 {
            rxd *= lambda.squareRoot()
            ryd *= lambda.squareRoot()
        }
        let num = rxd * rxd * ryd * ryd - rxd * rxd * y1 * y1 - ryd * ryd * x1 * x1
        let den = rxd * rxd * y1 * y1 + ryd * ryd * x1 * x1
        var coef = den > 0 ? (max(0, num) / den).squareRoot() : 0
        if largeArc == sweep { coef = -coef }
        let cxp = coef * rxd * y1 / ryd
        let cyp = -coef * ryd * x1 / rxd
        let cx = cosPhi * cxp - sinPhi * cyp + Double(p0.x + p1.x) / 2
        let cy = sinPhi * cxp + cosPhi * cyp + Double(p0.y + p1.y) / 2

        func angle(_ ux: Double, _ uy: Double, _ vx: Double, _ vy: Double) -> Double {
            let a = atan2(ux * vy - uy * vx, ux * vx + uy * vy)
            return a
        }
        let theta1 = angle(1, 0, (x1 - cxp) / rxd, (y1 - cyp) / ryd)
        var delta = angle((x1 - cxp) / rxd, (y1 - cyp) / ryd, (-x1 - cxp) / rxd, (-y1 - cyp) / ryd)
        if !sweep && delta > 0 { delta -= 2 * .pi }
        if sweep && delta < 0 { delta += 2 * .pi }

        let segments = max(1, Int((abs(delta) / (.pi / 2)).rounded(.up)))
        let step = delta / Double(segments)
        let k = 4.0 / 3.0 * tan(step / 4)
        func point(_ t: Double) -> (Double, Double) {
            let x = rxd * cos(t), y = ryd * sin(t)
            return (cosPhi * x - sinPhi * y + cx, sinPhi * x + cosPhi * y + cy)
        }
        func derivative(_ t: Double) -> (Double, Double) {
            let x = -rxd * sin(t), y = ryd * cos(t)
            return (cosPhi * x - sinPhi * y, sinPhi * x + cosPhi * y)
        }
        var t = theta1
        for i in 0..<segments {
            let t2 = t + step
            let a = point(t), b = point(t2)
            let da = derivative(t), db = derivative(t2)
            let c1 = CGPoint(x: a.0 + k * da.0, y: a.1 + k * da.1)
            let c2 = CGPoint(x: b.0 - k * db.0, y: b.1 - k * db.1)
            // Land exactly on the endpoint to avoid drift.
            let end = i == segments - 1 ? p1 : CGPoint(x: b.0, y: b.1)
            path.addCurve(to: end, control1: c1, control2: c2)
            t = t2
        }
    }

    struct Reader {
        let tokens: [Token]
        var index = 0
        var path = Path()
        var current = CGPoint.zero
        var start = CGPoint.zero
        var lastControl: CGPoint?
        var lastQuad: CGPoint?

        init(tokens: [Token]) { self.tokens = tokens }

        var hasNumber: Bool {
            guard index < tokens.count, case .number = tokens[index] else { return false }
            return true
        }

        mutating func number() -> CGFloat {
            guard index < tokens.count, case let .number(value) = tokens[index] else { return 0 }
            index += 1
            return value
        }

        mutating func point(relative: Bool) -> CGPoint {
            let x = number(), y = number()
            return relative ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
        }

        mutating func read() -> Path {
            var command: Character = "M"
            while index < tokens.count {
                if case let .command(c) = tokens[index] {
                    command = c
                    index += 1
                } else if !hasNumber {
                    index += 1
                    continue
                }
                let relative = command.isLowercase
                switch command.uppercased().first ?? "M" {
                case "M":
                    let p = point(relative: relative)
                    path.move(to: p)
                    current = p
                    start = p
                    lastControl = nil; lastQuad = nil
                    // Further pairs after a moveto are linetos.
                    command = relative ? "l" : "L"
                case "L":
                    let p = point(relative: relative)
                    path.addLine(to: p)
                    current = p
                    lastControl = nil; lastQuad = nil
                case "H":
                    let x = number()
                    current = CGPoint(x: relative ? current.x + x : x, y: current.y)
                    path.addLine(to: current)
                    lastControl = nil; lastQuad = nil
                case "V":
                    let y = number()
                    current = CGPoint(x: current.x, y: relative ? current.y + y : y)
                    path.addLine(to: current)
                    lastControl = nil; lastQuad = nil
                case "C":
                    let c1 = point(relative: relative)
                    let c2 = point(relative: relative)
                    let p = point(relative: relative)
                    path.addCurve(to: p, control1: c1, control2: c2)
                    current = p
                    lastControl = c2; lastQuad = nil
                case "S":
                    let c1 = lastControl.map { CGPoint(x: 2 * current.x - $0.x, y: 2 * current.y - $0.y) } ?? current
                    let c2 = point(relative: relative)
                    let p = point(relative: relative)
                    path.addCurve(to: p, control1: c1, control2: c2)
                    current = p
                    lastControl = c2; lastQuad = nil
                case "Q":
                    let c = point(relative: relative)
                    let p = point(relative: relative)
                    path.addQuadCurve(to: p, control: c)
                    current = p
                    lastQuad = c; lastControl = nil
                case "T":
                    let c = lastQuad.map { CGPoint(x: 2 * current.x - $0.x, y: 2 * current.y - $0.y) } ?? current
                    let p = point(relative: relative)
                    path.addQuadCurve(to: p, control: c)
                    current = p
                    lastQuad = c; lastControl = nil
                case "Z":
                    path.closeSubpath()
                    current = start
                    lastControl = nil; lastQuad = nil
                    // Numbers straight after a close start a new subpath.
                    command = relative ? "m" : "M"
                case "A":
                    let rx = number(), ry = number(), rotation = number()
                    let largeArc = number() != 0, sweep = number() != 0
                    let p = point(relative: relative)
                    SVGPath.addArc(to: &path, from: current, to: p, rx: rx, ry: ry,
                                   rotation: rotation, largeArc: largeArc, sweep: sweep)
                    current = p
                    lastControl = nil; lastQuad = nil
                default:
                    index += 1
                }
            }
            return path
        }
    }
}
