import SwiftUI

/// Reads SVG path data (`d` attributes) into a SwiftUI `Path`, so the crew is drawn from
/// the canvas files' own path strings rather than re-traced by hand.
/// Supports M L H V C S Q T Z in absolute and relative forms, with implicit repeats.
/// Arcs (A) are not used by the crew and are skipped.
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
                    // Not used by the crew: consume the seven arguments and draw a line.
                    for _ in 0..<5 { _ = number() }
                    let p = point(relative: relative)
                    path.addLine(to: p)
                    current = p
                default:
                    index += 1
                }
            }
            return path
        }
    }
}
