import DayXeroCore
import SwiftUI

/// A small, slowly looping drawing for each change on the health timeline (S19.5), shown in Home's milestone row.
/// Drawn in code in sage on the theme's soft accent, so it follows light and dark; still with Reduce Motion.
struct MilestoneIllustration: View {
    /// A health-timeline item id (health-timeline.json). Unknown ids get a sparkle.
    let id: String
    var size: CGFloat = 40

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { timeline in
            // One loop every four seconds; 0...1.
            let p = reduceMotion ? 0.25 : timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 4) / 4
            Canvas { context, canvas in
                let inset = canvas.width * 0.22
                let r = CGRect(origin: .zero, size: canvas).insetBy(dx: inset, dy: inset)
                MilestoneDrawing.draw(id, in: r, phase: p, context: &context)
            }
        }
        .frame(width: size, height: size)
        .background(DX.Palette.accentSoft, in: Circle())
        .accessibilityHidden(true)
    }
}

/// The drawings, in a unit box. `phase` runs 0...1 and loops.
enum MilestoneDrawing {
    static let ids = ["heart-rate", "carbon-monoxide", "circulation", "coughing", "heart-attack", "mouth-cancer",
                      "lung-cancer", "heart-disease", "withdrawal-start", "nicotine-gone", "withdrawal-peak", "mood",
                      "cravings-fade"]

    static func draw(_ id: String, in r: CGRect, phase p: Double, context c: inout GraphicsContext) {
        let ink = GraphicsContext.Shading.color(DX.Palette.accentInk)
        let line = StrokeStyle(lineWidth: max(r.width * 0.09, 1.2), lineCap: .round, lineJoin: .round)
        let wave = sin(p * 2 * .pi)
        switch id {
        case "heart-rate":
            // A heart that beats, with a pulse running under it.
            c.fill(heart(in: scaled(r.offsetBy(dx: 0, dy: -r.height * 0.12), by: 0.62 + 0.06 * max(wave, 0))), with: ink)
            c.stroke(pulse(in: CGRect(x: r.minX, y: r.maxY - r.height * 0.28, width: r.width, height: r.height * 0.28), phase: p),
                     with: ink, style: line)
        case "carbon-monoxide":
            // Bubbles rising and clearing.
            for i in 0..<3 {
                let f = (p + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                let d = r.width * (0.34 - 0.08 * CGFloat(i))
                let x = r.minX + r.width * [0.3, 0.68, 0.48][i]
                let y = r.maxY - CGFloat(f) * r.height
                var bubble = c
                bubble.opacity = 1 - f
                bubble.stroke(Path(ellipseIn: CGRect(x: x - d / 2, y: y - d / 2, width: d, height: d)), with: ink, style: line)
            }
        case "circulation":
            // A vessel with the flow moving along it.
            let path = sinePath(in: r, amplitude: 0.18, cycles: 1, phase: 0)
            c.stroke(path, with: .color(DX.Palette.accentInk.opacity(0.35)), style: line)
            var flow = line
            flow.dash = [r.width * 0.14, r.width * 0.2]
            flow.dashPhase = -CGFloat(p) * r.width * 0.68
            c.stroke(path, with: ink, style: flow)
        case "coughing":
            // Lungs breathing easily.
            c.stroke(lungs(in: scaled(r, by: 0.88 + 0.08 * wave)), with: ink, style: line)
        case "heart-attack":
            // A heart held in a shield.
            c.stroke(shield(in: r), with: ink, style: line)
            c.fill(heart(in: scaled(r, by: 0.42 + 0.04 * wave)), with: ink)
        case "mouth-cancer":
            // A clear voice: arcs spreading out.
            c.fill(Path(ellipseIn: CGRect(x: r.minX, y: r.midY - r.height * 0.1, width: r.width * 0.2, height: r.height * 0.2)), with: ink)
            for i in 0..<3 {
                let f = (p + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                var arc = c
                arc.opacity = 1 - f
                let radius = r.width * (0.25 + 0.6 * CGFloat(f))
                arc.stroke(Path { $0.addArc(center: CGPoint(x: r.minX + r.width * 0.1, y: r.midY), radius: radius,
                                            startAngle: .degrees(-40), endAngle: .degrees(40), clockwise: false) },
                           with: ink, style: line)
            }
        case "lung-cancer":
            // Lungs with a leaf growing.
            c.stroke(lungs(in: scaled(r, by: 0.9)), with: ink, style: line)
            c.fill(leaf(in: CGRect(x: r.midX - r.width * 0.06, y: r.minY - r.height * 0.12, width: r.width * 0.32,
                                   height: r.height * 0.32 * (0.85 + 0.15 * CGFloat(wave)))), with: ink)
        case "heart-disease":
            // A whole heart with a leaf.
            c.stroke(heart(in: scaled(r, by: 0.82)), with: ink, style: line)
            c.fill(leaf(in: CGRect(x: r.midX + r.width * 0.05, y: r.minY - r.height * 0.1, width: r.width * 0.34,
                                   height: r.height * 0.34)).applying(rotation(CGFloat(wave) * 0.12, around: CGPoint(x: r.midX, y: r.minY + r.height * 0.2))),
                   with: ink)
        case "withdrawal-start":
            // A wave starting to rise.
            c.stroke(sinePath(in: r, amplitude: 0.08 + 0.18 * CGFloat(p), cycles: 1.5, phase: p), with: ink, style: line)
        case "nicotine-gone":
            // A molecule fading out and back.
            var mol = c
            mol.opacity = 0.35 + 0.65 * (0.5 + 0.5 * cos(p * 2 * .pi))
            let center = CGPoint(x: r.midX, y: r.midY)
            let hex = Path { path in
                for k in 0..<6 {
                    let a = Double(k) / 6 * 2 * .pi
                    let pt = CGPoint(x: center.x + r.width * 0.32 * CGFloat(cos(a)), y: center.y + r.width * 0.32 * CGFloat(sin(a)))
                    if k == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
                }
                path.closeSubpath()
            }
            mol.stroke(hex, with: ink, style: line)
            for k in [0, 2, 4] {
                let a = Double(k) / 6 * 2 * .pi
                let pt = CGPoint(x: center.x + r.width * 0.32 * CGFloat(cos(a)), y: center.y + r.width * 0.32 * CGFloat(sin(a)))
                let d = r.width * 0.2
                mol.fill(Path(ellipseIn: CGRect(x: pt.x - d / 2, y: pt.y - d / 2, width: d, height: d)), with: ink)
            }
        case "withdrawal-peak":
            // A wave cresting.
            c.stroke(sinePath(in: r, amplitude: 0.3, cycles: 1, phase: p), with: ink, style: line)
        case "mood":
            // The sun coming out from behind a cloud.
            let sun = CGRect(x: r.minX, y: r.minY, width: r.width * 0.55, height: r.width * 0.55)
            c.fill(Path(ellipseIn: sun), with: ink)
            for k in 0..<8 {
                let a = Double(k) / 8 * 2 * .pi + p * .pi / 4
                let inner = r.width * 0.36, outer = r.width * 0.46
                c.stroke(Path { $0.move(to: CGPoint(x: sun.midX + inner * CGFloat(cos(a)), y: sun.midY + inner * CGFloat(sin(a))))
                                $0.addLine(to: CGPoint(x: sun.midX + outer * CGFloat(cos(a)), y: sun.midY + outer * CGFloat(sin(a)))) },
                         with: ink, style: line)
            }
            let drift = CGFloat(wave) * r.width * 0.08
            c.fill(cloud(in: CGRect(x: r.minX + r.width * 0.28 + drift, y: r.midY, width: r.width * 0.72, height: r.height * 0.42)),
                   with: .color(DX.Palette.accentInk.opacity(0.6)))
        case "cravings-fade":
            // Waves calming, each smaller than the last.
            for i in 0..<3 {
                let band = CGRect(x: r.minX, y: r.minY + r.height * CGFloat(i) * 0.33, width: r.width, height: r.height * 0.34)
                var w = c
                w.opacity = 1 - 0.28 * Double(i)
                w.stroke(sinePath(in: band, amplitude: 0.4 * (1 - 0.35 * CGFloat(i)), cycles: 1.5, phase: p), with: ink, style: line)
            }
        default:
            // A sparkle that twinkles.
            c.fill(sparkle(in: scaled(r, by: 0.85 + 0.12 * wave)), with: ink)
        }
    }

    // MARK: Shapes

    static func scaled(_ r: CGRect, by factor: Double) -> CGRect {
        let f = CGFloat(factor)
        return CGRect(x: r.midX - r.width * f / 2, y: r.midY - r.height * f / 2, width: r.width * f, height: r.height * f)
    }

    static func heart(in r: CGRect) -> Path {
        Path { p in
            let w = r.width, h = r.height
            p.move(to: CGPoint(x: r.midX, y: r.maxY))
            p.addCurve(to: CGPoint(x: r.minX, y: r.minY + h * 0.3),
                       control1: CGPoint(x: r.midX - w * 0.1, y: r.maxY - h * 0.15), control2: CGPoint(x: r.minX, y: r.minY + h * 0.6))
            p.addArc(center: CGPoint(x: r.minX + w * 0.25, y: r.minY + h * 0.3), radius: w * 0.25,
                     startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            p.addArc(center: CGPoint(x: r.minX + w * 0.75, y: r.minY + h * 0.3), radius: w * 0.25,
                     startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            p.addCurve(to: CGPoint(x: r.midX, y: r.maxY),
                       control1: CGPoint(x: r.maxX, y: r.minY + h * 0.6), control2: CGPoint(x: r.midX + w * 0.1, y: r.maxY - h * 0.15))
            p.closeSubpath()
        }
    }

    /// A heartbeat trace drawing itself across, then starting again.
    static func pulse(in r: CGRect, phase: Double) -> Path {
        Path { p in
            let points: [(CGFloat, CGFloat)] = [(0, 0.6), (0.3, 0.6), (0.4, 0.1), (0.5, 1), (0.6, 0.4), (0.7, 0.6), (1, 0.6)]
            p.move(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.6))
            for (x, y) in points.dropFirst() {
                p.addLine(to: CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height))
            }
        }
        .trimmedPath(from: 0, to: min(1, 0.15 + CGFloat(phase) * 1.1))
    }

    static func sinePath(in r: CGRect, amplitude: CGFloat, cycles: CGFloat, phase: Double) -> Path {
        Path { p in
            let steps = 24
            for i in 0...steps {
                let f = CGFloat(i) / CGFloat(steps)
                let y = r.midY + sin((f * cycles + CGFloat(phase)) * 2 * .pi) * amplitude * r.height
                let pt = CGPoint(x: r.minX + f * r.width, y: y)
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
        }
    }

    static func lungs(in r: CGRect) -> Path {
        Path { p in
            let w = r.width, h = r.height
            // Windpipe.
            p.move(to: CGPoint(x: r.midX, y: r.minY))
            p.addLine(to: CGPoint(x: r.midX, y: r.minY + h * 0.38))
            // Left lobe.
            p.move(to: CGPoint(x: r.midX - w * 0.08, y: r.minY + h * 0.3))
            p.addCurve(to: CGPoint(x: r.midX - w * 0.1, y: r.maxY),
                       control1: CGPoint(x: r.minX - w * 0.05, y: r.minY + h * 0.2), control2: CGPoint(x: r.minX - w * 0.05, y: r.maxY + h * 0.05))
            p.closeSubpath()
            // Right lobe.
            p.move(to: CGPoint(x: r.midX + w * 0.08, y: r.minY + h * 0.3))
            p.addCurve(to: CGPoint(x: r.midX + w * 0.1, y: r.maxY),
                       control1: CGPoint(x: r.maxX + w * 0.05, y: r.minY + h * 0.2), control2: CGPoint(x: r.maxX + w * 0.05, y: r.maxY + h * 0.05))
            p.closeSubpath()
        }
    }

    static func leaf(in r: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: r.minX, y: r.maxY))
            p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY), control: CGPoint(x: r.minX, y: r.minY))
            p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY), control: CGPoint(x: r.maxX, y: r.maxY))
            p.closeSubpath()
        }
    }

    static func shield(in r: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: r.midX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.18))
            p.addQuadCurve(to: CGPoint(x: r.midX, y: r.maxY), control: CGPoint(x: r.maxX, y: r.maxY - r.height * 0.15))
            p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.18), control: CGPoint(x: r.minX, y: r.maxY - r.height * 0.15))
            p.closeSubpath()
        }
    }

    static func cloud(in r: CGRect) -> Path {
        Path { p in
            p.addRoundedRect(in: CGRect(x: r.minX, y: r.midY, width: r.width, height: r.height / 2), cornerSize: CGSize(width: r.height / 4, height: r.height / 4))
            p.addEllipse(in: CGRect(x: r.minX + r.width * 0.15, y: r.minY + r.height * 0.15, width: r.width * 0.4, height: r.height * 0.7))
            p.addEllipse(in: CGRect(x: r.minX + r.width * 0.4, y: r.minY, width: r.width * 0.45, height: r.height * 0.85))
        }
    }

    static func sparkle(in r: CGRect) -> Path {
        Path { p in
            let c = CGPoint(x: r.midX, y: r.midY), w = r.width / 2, k = r.width * 0.12
            p.move(to: CGPoint(x: c.x, y: c.y - w))
            p.addQuadCurve(to: CGPoint(x: c.x + w, y: c.y), control: CGPoint(x: c.x + k, y: c.y - k))
            p.addQuadCurve(to: CGPoint(x: c.x, y: c.y + w), control: CGPoint(x: c.x + k, y: c.y + k))
            p.addQuadCurve(to: CGPoint(x: c.x - w, y: c.y), control: CGPoint(x: c.x - k, y: c.y + k))
            p.addQuadCurve(to: CGPoint(x: c.x, y: c.y - w), control: CGPoint(x: c.x - k, y: c.y - k))
            p.closeSubpath()
        }
    }

    static func rotation(_ angle: CGFloat, around point: CGPoint) -> CGAffineTransform {
        CGAffineTransform(translationX: point.x, y: point.y).rotated(by: angle).translatedBy(x: -point.x, y: -point.y)
    }
}

#if DEBUG
/// Every illustration, large, for review (`-dx.illustrationGallery YES`), with the moss header above them.
struct MilestoneIllustrationGallery: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DX.Space.m) {
                Text("Home · S19").dxText(.micro)
                Text("Milestone illustrations").dxText(.title)
                MossWaveHeader(cravingsToday: 2, usualCravings: 6, nextCraving: nil, now: .now, onLog: {})
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: DX.Space.s)], spacing: DX.Space.m) {
                    ForEach(MilestoneDrawing.ids + ["sparkle"], id: \.self) { id in
                        VStack(spacing: 6) {
                            MilestoneIllustration(id: id, size: 72)
                            Text(verbatim: id).dxText(.subtitle).lineLimit(1).minimumScaleFactor(0.7)
                        }
                    }
                }
            }
            .padding(.horizontal, DX.Space.m)
            .padding(.top, DX.Space.xl)
        }
        .dxCanvas()
    }
}
#endif
