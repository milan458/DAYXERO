import DayXeroCore
import SwiftUI

/// A milestone's illustration as a round badge, for lists and small spots: the crew collage (`MilestoneCollage`,
/// CHAR-05) cropped to a circle on a soft panel. Reached gets a check, under way a progress ring, ahead goes grey
/// and still. Every screen that shows the health timeline draws it with `HealthBadge` or `MilestoneCollage`.
struct HealthBadge: View {
    /// A health-timeline item id (health-timeline.json). Unknown ids get a sparkle.
    let id: String
    /// Reached gets a check, under way a progress ring, ahead goes grey and still.
    var state: HealthTimeline.State = .underWay(0)
    var size: CGFloat = 48
    /// The ring round an under-way change; off where the card shows its own progress.
    var showsRing = true

    var body: some View {
        let ahead = state == .ahead
        ZStack {
            Circle().fill(Self.panel)
            // Drawn at the badge's own size and centred, in its compact form, so the circle doesn't cut objects into
            // stray shapes (QW9). It used to be 112% and nudged, which clipped the right-hand objects.
            MilestoneCollage(id: id, size: size, animate: !ahead && size >= 72, compact: true)
                .grayscale(ahead ? 1 : 0)
                .opacity(ahead ? 0.55 : 1)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            if showsRing, case .underWay(let progress) = state {
                Circle()
                    .trim(from: 0, to: CGFloat(max(progress, 0.03)))
                    .stroke(Read4.accent, style: StrokeStyle(lineWidth: max(2, size / 22), lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(-size * 0.09)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if state == .done {
                let d = max(size * 0.36, 14)
                Image(systemName: "checkmark")
                    .font(.system(size: d * 0.5, weight: .heavy))
                    .foregroundStyle(Read4.onInk)
                    .frame(width: d, height: d)
                    .background(Read4.accent, in: Circle())
                    .overlay(Circle().strokeBorder(Read4.card, lineWidth: 2))
                    .offset(x: d * 0.15, y: d * 0.15)
            }
        }
        .accessibilityHidden(true)
    }

    /// The warm panel behind the collage, as on the canvas; deep violet in dark mode.
    static let panel = Color(light: 0xF5F0EA, dark: 0x221D4F)

    /// A soft wash in the colour of the realm the change belongs to: Xero's dawn for the body, Jelli's sea for
    /// withdrawal and cravings, Glim's dusk for the night.
    static func tint(for id: String) -> Color {
        switch MilestoneDrawing.hue(id) {
        case .dawn: Color(light: (0xFFE6BF, 1), dark: (0xFF7E5A, 0.18))
        case .sea: Color(light: (0xD3EEFF, 1), dark: (0x5AA9FF, 0.18))
        case .night: Color(light: (0xE8E0FF, 1), dark: (0x7A5CE0, 0.22))
        }
    }
}

/// The milestone ids with a drawing, and the SVG path reader the collage is drawn with.
enum MilestoneDrawing {
    static let ids = ["heart-rate", "carbon-monoxide", "circulation", "coughing", "heart-attack", "mouth-cancer",
                      "lung-cancer", "heart-disease", "withdrawal-start", "nicotine-gone", "withdrawal-peak", "mood",
                      "cravings-fade", "taste", "fresh-breath", "lips", "skin-glow", "hair", "even-tone", "sleep",
                      // What many people notice, weeks 2 to 6 (CLIN-01).
                      "flat-days", "clearer-head", "rewards-return"]

    /// Whose realm a change belongs to: Xero's dawn, Jelli's sea or Glim's night.
    enum Hue { case dawn, sea, night }

    static func hue(_ id: String) -> Hue {
        switch id {
        case "withdrawal-start", "nicotine-gone", "withdrawal-peak", "cravings-fade": .sea
        case "mood", "sleep", "flat-days": .night
        default: .dawn
        }
    }

    // MARK: SVG path data

    private enum Token { case command(Character), number(CGFloat) }

    /// Absolute SVG path data, as the kit's drawings are written: M L H V C S Q T Z.
    static func svg(_ d: String) -> Path {
        var tokens: [Token] = []
        var number = ""
        func endNumber() {
            if let v = Double(number) { tokens.append(.number(CGFloat(v))) }
            number = ""
        }
        for ch in d {
            if ch.isLetter {
                endNumber()
                tokens.append(.command(ch))
            } else if ch == "-" {
                endNumber()
                number = "-"
            } else if ch.isNumber || ch == "." {
                number.append(ch)
            } else {
                endNumber()
            }
        }
        endNumber()

        var path = Path()
        var i = 0
        var command: Character = "M"
        var previous: Character = "M"
        var current = CGPoint.zero
        var control = CGPoint.zero
        func next() -> CGFloat {
            defer { i += 1 }
            if case .number(let v) = tokens[i] { return v }
            return 0
        }
        func point() -> CGPoint {
            let x = next()
            return CGPoint(x: x, y: next())
        }
        func reflected() -> CGPoint { CGPoint(x: 2 * current.x - control.x, y: 2 * current.y - control.y) }

        while i < tokens.count {
            if case .command(let c) = tokens[i] {
                command = c
                i += 1
                if c == "Z" {
                    path.closeSubpath()
                    previous = c
                    continue
                }
            }
            guard i < tokens.count, case .number = tokens[i] else { continue }
            switch command {
            case "M":
                current = point()
                path.move(to: current)
                command = "L"
            case "L":
                current = point()
                path.addLine(to: current)
            case "H":
                current.x = next()
                path.addLine(to: current)
            case "V":
                current.y = next()
                path.addLine(to: current)
            case "C":
                let c1 = point(), c2 = point()
                current = point()
                path.addCurve(to: current, control1: c1, control2: c2)
                control = c2
            case "S":
                let c1 = previous == "C" || previous == "S" ? reflected() : current
                let c2 = point()
                current = point()
                path.addCurve(to: current, control1: c1, control2: c2)
                control = c2
            case "Q":
                let c1 = point()
                current = point()
                path.addQuadCurve(to: current, control: c1)
                control = c1
            case "T":
                let c1 = previous == "Q" || previous == "T" ? reflected() : current
                current = point()
                path.addQuadCurve(to: current, control: c1)
                control = c1
            default:
                i += 1
            }
            previous = command
        }
        return path
    }
}

#if DEBUG
/// Every illustration in its three states, for review (`-dx.illustrationGallery YES`).
struct MilestoneIllustrationGallery: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DX.Space.m) {
                Text("Your body · CHAR-05 crew collage").v4Text(.micro)
                Text("Health illustrations").v4Text(.title)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: DX.Space.s)], spacing: DX.Space.m) {
                    ForEach(MilestoneDrawing.ids + ["sparkle"], id: \.self) { id in
                        VStack(spacing: 6) {
                            HealthBadge(id: id, state: .underWay(0.6), size: 72, showsRing: false)
                            Text(verbatim: id).v4Text(.subtitle).lineLimit(1).minimumScaleFactor(0.7)
                        }
                    }
                }
                Text("Reached · under way · ahead").v4Text(.micro)
                HStack(spacing: DX.Space.l) {
                    HealthBadge(id: "mood", state: .done, size: 56)
                    HealthBadge(id: "mood", state: .underWay(0.8), size: 56)
                    HealthBadge(id: "mood", state: .ahead, size: 56)
                }
                .padding(.leading, DX.Space.xs)
            }
            .padding(.horizontal, DX.Space.m)
            .padding(.top, DX.Space.xl)
            .padding(.bottom, DX.Space.xxl)
        }
        .background(Read4.background.ignoresSafeArea())
    }
}
#endif
