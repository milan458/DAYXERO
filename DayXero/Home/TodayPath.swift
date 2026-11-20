import DayXeroCore
import SwiftUI

// Today during prep (20 Nov 2026, canvas "DayXero Home: the path"): the prep week drawn as stepping stones climbing
// the dunes to Day Xero's sun on the horizon, with Xero standing on today's stone (Glim, lit, after 6 PM). Tapping a
// stone opens that day's card in the sheet below. It replaces the prep scene, the greeting's line and the 1 to 7
// stamps card; after Day Xero, Today keeps its own scene (`TodayHero`).

/// One prep day's stone.
struct TodayPathStone: Identifiable, Equatable {
    enum State: Equatable { case done, today, ahead }
    /// Its place on the path, from 0.
    let id: Int
    let state: State
    /// VoiceOver: "Prep 3, Sun 22 Nov, today".
    let label: String
}

struct TodayPathHero: View {
    /// After 6 PM: Glim and the moon. The colours follow the colour scheme, which Home turns dark at night.
    let night: Bool
    /// "Sun, 22 Nov".
    let dateLine: String
    let greeting: String
    let profileInitial: String?
    let stones: [TodayPathStone]
    /// The stone the character stands on.
    let crew: Int
    /// The stone whose day is open in the sheet; `stones.count` is Day Xero.
    let selected: Int?
    /// VoiceOver for the sun: "Day Xero, Fri 27 Nov".
    let dayXeroLabel: String
    /// VoiceOver for the scene: "Prep: 2 of 7 sessions done".
    let summary: String
    let crewStage: Int
    let topInset: CGFloat
    let onStone: (Int) -> Void
    let onProfile: () -> Void

    @Environment(\.colorScheme) private var scheme
    private let motion = MotionPolicy()

    /// Stones on the 390 pt canvas, nearest first: centre and radii. The far ones shrink with the distance.
    private static let spots: [(x: CGFloat, y: CGFloat, rx: CGFloat, ry: CGFloat)] = [
        (112, 400, 46, 15), (296, 360, 40, 13), (172, 306, 38, 13), (290, 274, 27, 9),
        (200, 252, 21, 7), (286, 236, 16, 5.5), (214, 222, 12, 4),
    ]
    private static let sun = CGPoint(x: 262, y: 204)
    /// The scene's height under the status bar; the sheet below overlaps its last 28 pt.
    static let sceneHeight: CGFloat = 420

    private struct Palette {
        let sky1, sky2, dune1, dune2, dune3, trail, ink, muted: Color
        let doneFill, doneEdge, todayFill, todayEdge, aheadFill, aheadEdge, under: Color
    }

    private var palette: Palette {
        if scheme == .dark {
            Palette(sky1: Color(hex: 0x0C1730), sky2: Color(hex: 0x1B2C55), dune1: Color(hex: 0x182A52), dune2: Color(hex: 0x142446),
                    dune3: Color(hex: 0x111E3C), trail: Color(hex: 0xC8D2FF).opacity(0.22), ink: Color(hex: 0xF6EFE2),
                    muted: Color(hex: 0xC9D2EA), doneFill: Color(hex: 0xF6D08A), doneEdge: Color(hex: 0x5FD39A),
                    todayFill: Color(hex: 0x2A3A66), todayEdge: Color(hex: 0xFFD37A), aheadFill: Color(hex: 0xAAB4E6).opacity(0.22),
                    aheadEdge: Color(hex: 0xAEB8D3), under: Color.black.opacity(0.25))
        } else {
            Palette(sky1: Color(hex: 0xFF8A62), sky2: Color(hex: 0xFFB877), dune1: Color(hex: 0xFF9D6E), dune2: Color(hex: 0xF78558),
                    dune3: Color(hex: 0xEC6D4C), trail: Color(hex: 0xFFF8EE).opacity(0.6), ink: Color(hex: 0x1E1A3A),
                    muted: Color(hex: 0x4A2810), doneFill: Color(hex: 0xFFC38A), doneEdge: Color(hex: 0x1E7A4B),
                    todayFill: Color(hex: 0xFFF8EE), todayEdge: Color(hex: 0xFF7A55), aheadFill: Color(hex: 0xFFF8EE).opacity(0.78),
                    aheadEdge: Color(hex: 0x7A3A22), under: Color(hex: 0x782814).opacity(0.22))
        }
    }

    var body: some View {
        let pal = palette
        let height = topInset + Self.sceneHeight
        // Canvas y 62 (the date line) sits just under the status bar.
        let base = topInset - 54
        return GeometryReader { proxy in
            let w = proxy.size.width
            // Wider phones spread the path a little; the stones keep their size.
            let spread = min(max(w / 390, 0.9), 1.3)
            let at = { (x: CGFloat, y: CGFloat) in CGPoint(x: w / 2 + (x - 195) * spread, y: base + y) }
            let shown = Array(stones.prefix(Self.spots.count))
            let points = shown.indices.map { at(Self.spots[$0].x, Self.spots[$0].y) }
            let sun = at(Self.sun.x, Self.sun.y)
            ZStack(alignment: .topLeading) {
                LinearGradient(stops: [.init(color: pal.sky1, location: 0), .init(color: pal.sky2, location: min((base + 206) / height, 1))],
                               startPoint: .top, endPoint: .bottom)
                    .accessibilityElement()
                    .accessibilityLabel(Text(verbatim: summary))
                if night {
                    MoonShape().fill(Color(hex: 0xFFE9A8)).frame(width: 40, height: 40)
                        .position(x: w - 56, y: base + 164)
                        .accessibilityHidden(true)
                }
                Group {
                    // Day Xero's sun, half risen behind the far dune.
                    Circle().fill(RadialGradient(colors: [Color(hex: 0xFFF6C8).opacity(scheme == .dark ? 0.3 : 0.85), Color(hex: 0xFFF6C8).opacity(0)],
                                                 center: .center, startRadius: 0, endRadius: 50))
                        .frame(width: 100, height: 100).position(sun)
                    Circle().fill(Color(hex: 0xFFC23A).opacity(scheme == .dark ? 0.7 : 1))
                        .frame(width: 48, height: 48).position(sun)
                    DuneShape(curve: 0).fill(pal.dune1).frame(width: w, height: 300).offset(y: base + 200)
                    DuneShape(curve: 1).fill(pal.dune2).frame(width: w, height: 300).offset(y: base + 200)
                    DuneShape(curve: 2).fill(pal.dune3).frame(width: w, height: 300).offset(y: base + 200)
                    Path { path in
                        guard let first = points.first else { return }
                        path.move(to: first)
                        for point in points.dropFirst() { path.addLine(to: point) }
                        path.addLine(to: CGPoint(x: sun.x, y: sun.y + 6))
                    }
                    .stroke(pal.trail, style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round))
                }
                .accessibilityHidden(true)

                Text("DAY XERO")
                    .dxFace(.body, 11, weight: 700, tracking: 1.2)
                    .foregroundStyle(pal.ink)
                    .position(x: sun.x, y: sun.y - 34)
                    .accessibilityHidden(true)
                Button { onStone(stones.count) } label: {
                    Circle().strokeBorder(pal.ink, lineWidth: selected == stones.count ? 3 : 0)
                        .frame(width: 52, height: 52)
                        .frame(width: 52, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .position(x: sun.x, y: sun.y - 4)
                .accessibilityLabel(Text(verbatim: dayXeroLabel))
                .accessibilityAddTraits(selected == stones.count ? .isSelected : [])

                ForEach(shown) { stone in
                    let spot = Self.spots[stone.id]
                    self.stone(stone, rx: spot.rx, ry: spot.ry, pal: pal)
                        .position(points[stone.id])
                }

                if points.indices.contains(crew) {
                    Group {
                        if night {
                            GlimView(mood: .hello, stage: crewStage, points: 84, animate: !motion.reduce)
                                .frame(width: 84, height: 84)
                                .position(x: points[crew].x, y: points[crew].y - 50)
                        } else {
                            XeroView(mood: .hello, stage: crewStage, points: 84, animate: !motion.reduce)
                                .frame(width: 84, height: 84)
                                .position(x: points[crew].x, y: points[crew].y - 38)
                        }
                    }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .center, spacing: 12) {
                        Text(verbatim: dateLine)
                            .dxFace(.body, 14, weight: 600)
                            .foregroundStyle(pal.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Button(action: onProfile) {
                            Group {
                                if let profileInitial {
                                    Text(verbatim: profileInitial).dxFace(.display, 17, weight: 800)
                                } else {
                                    DXIcon(.people, size: 20)
                                }
                            }
                            .foregroundStyle(Color(light: 0xFFF8EE, dark: 0x0E1322))
                            .frame(width: 44, height: 44)
                            .background(Color(light: 0x1E1A3A, dark: 0xF3E7CC), in: Circle())
                        }
                        .buttonStyle(.dxPress)
                        .accessibilityLabel(Text("Profile and settings"))
                    }
                    Text(verbatim: greeting)
                        .dxType(.large)
                        .foregroundStyle(pal.ink)
                        .lineLimit(2).minimumScaleFactor(0.7)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                }
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.top, topInset + 2)
                .dxArrive(0)
            }
        }
        .frame(height: height)
        .clipped()
    }

    /// A stone: done ones solid with a green edge, today's cream with a coral edge, the ones ahead dashed. The stone
    /// the character stands on, and the one whose day is open, carry an ink ring.
    private func stone(_ stone: TodayPathStone, rx: CGFloat, ry: CGFloat, pal: Palette) -> some View {
        let picked = selected == stone.id
        let ringed = picked || stone.id == crew
        let fill: Color = switch stone.state {
        case .done: pal.doneFill
        case .today: pal.todayFill
        case .ahead: pal.aheadFill
        }
        let edge: Color = switch stone.state {
        case .done: pal.doneEdge
        case .today: pal.todayEdge
        case .ahead: pal.aheadEdge
        }
        let dash: [CGFloat] = stone.state == .ahead ? [4, 4] : []
        return Button { onStone(stone.id) } label: {
            ZStack {
                Ellipse().fill(pal.under).frame(width: rx * 2, height: ry * 2).offset(y: 5)
                Ellipse().fill(fill).frame(width: rx * 2, height: ry * 2)
                Ellipse().strokeBorder(edge, style: StrokeStyle(lineWidth: stone.state == .ahead ? 2 : 2.5, dash: dash))
                    .frame(width: rx * 2, height: ry * 2)
                if ringed {
                    Ellipse().strokeBorder(pal.ink, lineWidth: 2.5).frame(width: rx * 2 + 10, height: ry * 2 + 10)
                }
            }
            .frame(width: max(rx * 2 + 10, 44), height: max(ry * 2 + 10, 30))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: stone.label))
        .accessibilityAddTraits(picked ? .isSelected : [])
    }
}

/// One dune's top edge across the scene, on a 390 × 300 box stretched to the frame.
private struct DuneShape: Shape {
    let curve: Int

    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 390, sy = rect.height / 300
        let p = { (x: CGFloat, y: CGFloat) in CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy) }
        var path = Path()
        switch curve {
        case 0:
            path.move(to: p(0, 10))
            path.addCurve(to: p(200, 8), control1: p(70, 2), control2: p(130, 14))
            path.addCurve(to: p(390, 6), control1: p(270, 2), control2: p(330, 12))
        case 1:
            path.move(to: p(0, 62))
            path.addCurve(to: p(250, 58), control1: p(90, 48), control2: p(170, 70))
            path.addCurve(to: p(390, 54), control1: p(310, 50), control2: p(350, 60))
        default:
            path.move(to: p(0, 136))
            path.addCurve(to: p(270, 132), control1: p(80, 122), control2: p(180, 146))
            path.addCurve(to: p(390, 130), control1: p(320, 126), control2: p(360, 134))
        }
        path.addLine(to: p(390, 300))
        path.addLine(to: p(0, 300))
        path.closeSubpath()
        return path
    }
}

/// A crescent moon.
private struct MoonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let disc = Path(ellipseIn: rect)
        let bite = Path(ellipseIn: rect.offsetBy(dx: rect.width * 0.3, dy: -rect.height * 0.14))
        return disc.subtracting(bite)
    }
}

// MARK: Week strip

/// The prep week in one row, always at the top of the sheet (20 Nov 2026): each day's name ("FRI", "TODAY", and
/// "XERO" for Day Xero) over a mark for where it stands: a green pill once its session is done, a soft one for today,
/// an outline for the days ahead and a dashed ring for Day Xero. Tapping a day opens its card.
struct TodayWeekStrip: View {
    struct Item: Identifiable {
        let id: Int
        let label: String
        let state: TodayPathStone.State
        let isToday: Bool
        let isDayXero: Bool
        let accessibility: String
    }

    let items: [Item]
    /// The day whose card is open.
    let selected: Int?
    let onTap: (Int) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(items) { item in
                let picked = selected == item.id
                Button { onTap(item.id) } label: {
                    VStack(spacing: 7) {
                        Text(verbatim: item.label.uppercased())
                            .dxFace(.body, 11, weight: 700, tracking: 0.6)
                            .foregroundStyle(item.isToday ? TodayInk.coralText : picked ? TodayInk.ink : TodayInk.muted)
                            .lineLimit(1).minimumScaleFactor(0.7)
                        mark(item)
                            .frame(height: 12)
                        Capsule().fill(picked ? TodayInk.ink : Color.clear).frame(width: 18, height: 2)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: item.accessibility))
                .accessibilityAddTraits(picked ? .isSelected : [])
            }
        }
        .padding(.horizontal, 2)
    }

    @ViewBuilder
    private func mark(_ item: Item) -> some View {
        if item.isDayXero {
            Circle().strokeBorder(TodayInk.coral, style: StrokeStyle(lineWidth: 2, dash: [2.5, 2.5])).frame(width: 12, height: 12)
        } else {
            switch item.state {
            case .done:
                Capsule().fill(DX.Fill.done).frame(width: item.isToday ? 22 : 16, height: 7)
            case .today:
                Capsule().fill(DX.Fill.done.opacity(0.45)).frame(width: 22, height: 7)
            case .ahead:
                Capsule().strokeBorder(TodayInk.muted, lineWidth: 1.5).frame(width: 14, height: 8)
            }
        }
    }
}

// MARK: Day card

/// One day of the prep week as a card: the date, the day's name, how much of it is done, and each thing on it. Today's
/// rows carry their buttons; a finished day shows what was done, with the session to replay; a day ahead shows what
/// will open.
struct TodayDayCard: View {
    struct Row: Identifiable {
        enum Mark { case done, open, locked }
        let id: String
        let mark: Mark
        let title: String
        let detail: String
        var action: String?
        /// The filled button: the one thing to do next.
        var primary = false
        var run: (() -> Void)?
    }

    /// "TODAY · SUN 22 NOV" or "TUE 24 NOV".
    let kicker: String
    let isToday: Bool
    /// "Prep 3", "Day Xero".
    let name: String
    let rows: [Row]

    var body: some View {
        let done = rows.filter { $0.mark == .done }.count
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: kicker)
                    .dxFace(.body, 12, weight: 700, tracking: 1)
                    .foregroundStyle(isToday ? TodayInk.coralText : TodayInk.muted)
                Text(verbatim: name)
                    .dxFace(.display, 23, weight: 800, tracking: -0.5)
                    .foregroundStyle(TodayInk.ink)
                    .accessibilityAddTraits(.isHeader)
            }
            HStack(spacing: 5) {
                ForEach(rows.indices, id: \.self) { i in
                    Capsule().fill(i < done ? DX.Fill.done : TodayInk.ink.opacity(0.12)).frame(height: 5)
                }
            }
            .accessibilityElement()
            .accessibilityLabel(Text("\(done) of \(rows.count) done"))
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { i, row in
                    if i > 0 { Rectangle().fill(TodayInk.line).frame(height: 1) }
                    self.row(row)
                }
            }
        }
        .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .todayCard()
        .environment(\.dxGround, .apricot)
    }

    private func row(_ row: Row) -> some View {
        HStack(spacing: 12) {
            mark(row.mark)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: row.title)
                    .dxFace(.body, 16, weight: 600)
                    .foregroundStyle(TodayInk.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(verbatim: row.detail)
                    .dxFace(.body, 13, weight: 500)
                    .foregroundStyle(row.mark == .done ? Color(light: 0x1E7A4B, dark: 0x7FE0AE) : TodayInk.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            if let action = row.action, let run = row.run {
                Button(action: run) { Text(verbatim: action) }
                    .buttonStyle(.dx(row.primary ? .small : .ghostSmall, on: .apricot))
                    .frame(height: 44)
                    .fixedSize()
            }
        }
        .padding(.vertical, 11)
        .frame(minHeight: 56)
    }

    @ViewBuilder
    private func mark(_ mark: Row.Mark) -> some View {
        switch mark {
        case .done:
            DXIconShape(d: DX.Icon.check.d)
                .stroke(.white, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                .frame(width: 14, height: 14)
                .frame(width: 26, height: 26)
                .background(DX.Fill.done, in: Circle())
                .accessibilityLabel(Text("Done"))
        case .open:
            Circle().strokeBorder(TodayInk.muted, lineWidth: 2).frame(width: 26, height: 26)
                .accessibilityLabel(Text("To do"))
        case .locked:
            Circle().strokeBorder(TodayInk.muted, style: StrokeStyle(lineWidth: 2, dash: [3, 4])).frame(width: 26, height: 26)
                .accessibilityLabel(Text("Not open yet"))
        }
    }
}
