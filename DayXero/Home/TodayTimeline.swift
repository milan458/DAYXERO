import DayXeroCore
import SwiftUI

// Today's lower half (v5, cook/site/screens/015, 017): the one card that matters now, the prep countdown as stamps,
// the day's log, then the rest of the day as quiet lists under their section headers. Done steps carry a green tick;
// the one step that matters now is the focus card, so it isn't repeated in the lists.
//
// Motion (017): the pinned header slides down as the scene scrolls away; the Now card's art band holds still while
// Xero breathes; the counts count up when they change and the +1 floats up; the Later rows arrive with a 90ms stagger.

// MARK: Sections

enum TodayNode: Equatable {
    case done
    /// The step under way.
    case now
    case later
    /// Quit Day ahead.
    case quitDay
    /// A milestone ahead after Quit Day.
    case milestone
}

/// A section of the day: a 19 pt header and its rows in one quiet list (kit `.later-list`): the card at 60% with a
/// hairline, rows split by hairlines.
struct TodaySection<Content: View>: View {
    let title: String
    var index = 0
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(verbatim: title)
                .dxFace(.display, 19, weight: 700, tracking: -0.2)
                .foregroundStyle(TodayInk.ink)
                .padding(.leading, 2)
                .accessibilityAddTraits(.isHeader)
            Group(subviews: content) { rows in
                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { i, row in
                        if i > 0 { Rectangle().fill(TodayInk.line).frame(height: 1) }
                        row
                    }
                }
            }
            .background(TodayInk.card.opacity(0.6), in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous).strokeBorder(TodayInk.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
        }
        .dxArrive(index)
    }
}

/// A step in a section: done steps lead with the green tick; others draw their own icon.
struct TodayStep<Content: View>: View {
    let node: TodayNode
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 12) {
            if node == .done {
                DXIconShape(d: DX.Icon.check.d)
                    .stroke(.white, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                    .frame(width: 14, height: 14)
                    .frame(width: 24, height: 24)
                    .background(DX.Fill.done, in: Circle())
                    .padding(.leading, 16)
                    .accessibilityHidden(true)
            }
            content.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// A finished step: "Morning pledge … Done · 8:12".
struct TodayDoneRow: View {
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: DX.Space.xs) {
            Text(verbatim: title).dxFace(.display, 16, weight: 700).foregroundStyle(TodayInk.muted)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(verbatim: detail).dxType(.caption).foregroundStyle(DX.Fill.green)
                .lineLimit(1).fixedSize()
        }
        .padding(.trailing, 16)
        .padding(.vertical, 10)
        .frame(minHeight: 56)
        .accessibilityElement(children: .combine)
    }
}

/// A row in a section (kit `.lrow`): an optional icon, a 16 pt bold title and a caption, and what a tap does.
struct TodayRowCard: View {
    var glyph: LogGlyph?
    var icon: DX.Icon?
    /// A small line above the title: "Happening now".
    var eyebrow: String?
    let title: String
    var detail: String?
    var trailing: String?
    var detailColor: Color = TodayInk.muted
    var showsChevron = false
    let action: (() -> Void)?

    var body: some View {
        let content = HStack(spacing: 14) {
            if let glyph {
                LogIcon(glyph: glyph)
            } else if let icon {
                DXIcon(icon, size: 22).foregroundStyle(TodayInk.muted)
            }
            VStack(alignment: .leading, spacing: 3) {
                if let eyebrow {
                    Text(verbatim: eyebrow).dxType(.caption).foregroundStyle(TodayInk.muted)
                }
                Text(verbatim: title).dxFace(.display, 16, weight: 700).foregroundStyle(TodayInk.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail {
                    Text(verbatim: detail).dxFace(.body, 13, weight: 500).foregroundStyle(detailColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let trailing {
                Text(verbatim: trailing).dxType(.caption).foregroundStyle(TodayInk.muted)
            }
            if showsChevron {
                DXIcon(.chev, size: 18).foregroundStyle(TodayInk.muted)
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 14)
        .padding(.vertical, 10)
        .frame(minHeight: 62)
        .contentShape(Rectangle())
        if let action {
            Button(action: action) { content }
                .buttonStyle(.dxPress)
                .accessibilityElement(children: .combine)
        } else {
            content.accessibilityElement(children: .combine)
        }
    }
}

/// What's ahead at the end of the day: Quit Day (the Day Xero coin waiting) or the next milestone (its badge, next).
struct TodayAheadRow: View {
    let text: String
    let isQuitDay: Bool
    let milestone: Int?

    var body: some View {
        HStack(spacing: 14) {
            Group {
                if isQuitDay {
                    DXBadge(.xero, state: .next(nil), size: 32)
                } else {
                    DXBadge(.day, n: milestone ?? 0, state: .next(nil), size: 32)
                }
            }
            .environment(\.dxGround, .apricot)
            Text(verbatim: text)
                .dxFace(.display, 16, weight: 700)
                .foregroundStyle(isQuitDay ? TodayInk.coralText : TodayInk.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(minHeight: 62)
        .accessibilityElement(children: .combine)
    }
}

// MARK: Cards

/// The cream card every Today block sits on (kit 015/016 `.card` with `--lift`).
struct TodayCard: ViewModifier {
    var radius: CGFloat = DX.Layout.cardRadius

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .background {
                shape.fill(TodayInk.card)
                    .shadow(color: TodayInk.shadow, radius: 13, y: 10)
            }
            .overlay(shape.strokeBorder(TodayInk.line, lineWidth: 1))
    }
}

extension View {
    func todayCard(radius: CGFloat = DX.Layout.cardRadius) -> some View { modifier(TodayCard(radius: radius)) }
}

// MARK: Focus card

/// The one card that matters now.
/// - Session (015): the kicker and title on the left, one small Start button on the right.
/// - Recovery (017, the Now card): a paper-cut morning band with Xero breathing, the kicker and title over it.
/// - Check-in and wind-down (018): on the night card, with the kicker, the title and one full-width cream button.
struct TodayFocusCard<Accessory: View>: View {
    enum Art: Equatable {
        case session
        case quitDay
        case checkIn
        case windDown
        case recovery(id: String)
    }

    let art: Art
    let kicker: String
    let title: String
    var detail: String?
    var button: String?
    var showsPlay = false
    var crewStage = 1
    let action: (() -> Void)?
    @ViewBuilder var accessory: Accessory

    var body: some View {
        switch art {
        case .session, .quitDay: session
        case .recovery: recovery
        case .checkIn, .windDown: night
        }
    }

    // 015: kicker, title, Start.
    private var session: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: kicker).dxType(.footnote).foregroundStyle(TodayInk.muted)
                Text(verbatim: title).dxType(.headline).foregroundStyle(TodayInk.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                if let detail {
                    Text(verbatim: detail).dxType(.caption).foregroundStyle(TodayInk.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let button, let action {
                Button(action: action) {
                    HStack(spacing: 8) {
                        if showsPlay { DXIcon(.play, size: 16, weight: 1.5, filled: true) }
                        Text(verbatim: button)
                    }
                }
                .buttonStyle(.dx(.small, on: .apricot))
                .fixedSize()
            }
        }
        .padding(.vertical, 16)
        .padding(.leading, 20)
        .padding(.trailing, 16)
        .todayCard()
        .accessibilityElement(children: .combine)
        .modifier(TapAction(action: button == nil ? action : nil))
    }

    // 017: the Now card's art band, then whatever rows belong with it.
    private var recovery: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                MorningBand().frame(height: 172)
                XeroView(mood: .breathe, stage: crewStage, size: .card)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 14)
                    .padding(.top, 62)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: kicker).dxFace(.body, 14, weight: 500).foregroundStyle(TodayInk.muted)
                    Text(verbatim: title).dxFace(.display, 23, weight: 800, tracking: -0.6).foregroundStyle(TodayInk.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    if let detail {
                        Text(verbatim: detail).dxType(.caption).foregroundStyle(TodayInk.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(width: 214, alignment: .leading)
                .padding(18)
            }
            .contentShape(Rectangle())
            .modifier(TapAction(action: action))
            .accessibilityElement(children: .combine)
            accessory
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .todayCard(radius: 26)
    }

    // 018: the night card.
    private var night: some View {
        let ground = DX.Ground.violet
        return VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: kicker).dxType(.footnote).foregroundStyle(ground.muted)
                Text(verbatim: title).dxType(.headline).foregroundStyle(ground.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                if let detail {
                    Text(verbatim: detail).dxType(.footnote).foregroundStyle(ground.muted)
                }
            }
            accessory
            if let button, let action {
                Button(action: action) {
                    HStack(spacing: 10) {
                        DXIcon(.moon, size: 20)
                        Text(verbatim: button)
                    }
                }
                .buttonStyle(.dx(.primary, on: .violet))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ground.card, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(ground.line, lineWidth: 1))
        .shadow(color: .black.opacity(0.3), radius: 12, y: 10)
        .environment(\.colorScheme, .dark)
    }
}

extension TodayFocusCard where Accessory == EmptyView {
    init(art: Art, kicker: String, title: String, detail: String? = nil, button: String? = nil, showsPlay: Bool = false,
         crewStage: Int = 1, action: (() -> Void)?) {
        self.init(art: art, kicker: kicker, title: title, detail: detail, button: button, showsPlay: showsPlay,
                  crewStage: crewStage, action: action) { EmptyView() }
    }
}

private struct TapAction: ViewModifier {
    let action: (() -> Void)?

    func body(content: Content) -> some View {
        if let action {
            Button(action: action) { content }.buttonStyle(.dxPress).accessibilityAddTraits(.isButton)
        } else {
            content
        }
    }
}

/// The Now card's paper-cut morning (kit 016/017 `#nscene`): a pale sky, a low sun with a glow, three hills with a rim.
struct MorningBand: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let dark = scheme == .dark
        Canvas { ctx, size in
            let s0: UInt32 = dark ? 0x1A2442 : 0xFFF6EA, s1: UInt32 = dark ? 0x2B3052 : 0xFFE9D2, s2: UInt32 = dark ? 0x5A4558 : 0xFFD3A8
            let sun: UInt32 = dark ? 0xFFB877 : 0xFFC93C, glow: UInt32 = dark ? 0xFFB877 : 0xFFD27A
            let h1: UInt32 = dark ? 0x2C3A60 : 0xFFC796, h2: UInt32 = dark ? 0x22304F : 0xFFAE73, h3: UInt32 = dark ? 0x182034 : 0xFFFCF7
            let rim = dark ? Color(hex: 0xF6E7C1).opacity(0.18) : Color.white.opacity(0.55)
            let sh = dark ? Color.black.opacity(0.45) : Color(hex: 0x8A3A12).opacity(0.16)
            ctx.scaleBy(x: size.width / 346, y: size.height / 172)
            ctx.fill(Path(CGRect(x: 0, y: 0, width: 346, height: 172)), with: .linearGradient(
                Gradient(stops: [.init(color: Color(hex: s0), location: 0), .init(color: Color(hex: s1), location: 0.6),
                                 .init(color: Color(hex: s2), location: 1)]),
                startPoint: .zero, endPoint: CGPoint(x: 0, y: 172)))
            ctx.fill(Path(ellipseIn: CGRect(x: 142, y: 64, width: 108, height: 108)), with: .radialGradient(
                Gradient(colors: [Color(hex: glow).opacity(0.55), Color(hex: glow).opacity(0)]),
                center: CGPoint(x: 196, y: 118), startRadius: 0, endRadius: 54))
            ctx.fill(Path(ellipseIn: CGRect(x: 176, y: 98, width: 40, height: 40)), with: .color(Color(hex: sun)))
            var lifted = ctx
            lifted.addFilter(.shadow(color: sh, radius: 3, y: -2))
            lifted.fill(SVGPath.path("M0 128 C50 114 100 112 150 120 C200 128 250 116 300 108 C320 105 334 106 346 108 V172 H0Z"), with: .color(Color(hex: h1)))
            lifted.fill(SVGPath.path("M0 146 C40 136 90 134 140 140 C180 145 210 146 240 140 C270 134 300 126 346 128 V172 H0Z"), with: .color(Color(hex: h2)))
            ctx.stroke(SVGPath.path("M0 146 C40 136 90 134 140 140 C180 145 210 146 240 140 C270 134 300 126 346 128"), with: .color(rim), lineWidth: 1.5)
            lifted.fill(SVGPath.path("M0 158 C60 152 120 154 176 156 C214 157 236 148 260 142 C290 135 320 138 346 144 V172 H0Z"), with: .color(Color(hex: h3)))
        }
        .accessibilityHidden(true)
    }
}

// MARK: Prep countdown (015)

/// The one meter during prep: "4 days to Quit Day" (counting down from 7) and the quit date, then a stamp per prep
/// session: done ones stamped, today's open slot breathing its coral outline, the rest in dashed rings, and the
/// Day Xero coin waiting at the end.
struct TodayPrepStamps: View {
    let daysToQuit: Int
    let quitDate: String
    let done: Int
    let total: Int
    /// Today's open session, if one is waiting (1-based).
    let current: Int?
    @State private var landed = false
    private let motion = MotionPolicy()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Group {
                    if daysToQuit == 0 {
                        Text("Quit Day is today")
                    } else if daysToQuit == 1 {
                        Text("1 day to Quit Day")
                    } else {
                        CountingText(Double(daysToQuit), from: Double(max(total, daysToQuit)), delay: 0.6) { value in
                            String(localized: "\(Int(value.rounded())) days to Quit Day")
                        }
                    }
                }
                .dxFace(.display, 17, weight: 700, tracking: -0.2)
                .foregroundStyle(TodayInk.ink)
                Spacer(minLength: 8)
                Text(verbatim: quitDate).dxType(.footnote).foregroundStyle(TodayInk.muted)
            }
            .padding(.horizontal, 2)
            HStack(alignment: .top, spacing: 0) {
                ForEach(1...max(total, 1), id: \.self) { n in
                    slot(n)
                    Spacer(minLength: 0)
                }
                VStack(spacing: 7) {
                    DXBadge(.xero, state: .next(nil), size: 50)
                    Text(verbatim: "Day Xero").dxType(.caption).fontWeight(.bold).foregroundStyle(TodayInk.ink).fixedSize()
                }
                .frame(width: 50)
                .padding(.top, -1)
                .padding(.trailing, 6)
            }
        }
        .padding(.top, 16)
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
        .todayCard()
        .environment(\.dxGround, .apricot)
        .sensoryFeedback(.impact(weight: .light), trigger: landed)
        .task {
            try? await Task.sleep(for: .seconds(motion.reduce ? 0 : 1.45))
            landed = true
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Prep \(done) of \(total) done"))
    }

    @ViewBuilder
    private func slot(_ n: Int) -> some View {
        let isNow = n == current
        VStack(spacing: 7) {
            ZStack {
                if n <= done {
                    DXBadge(.prep, size: 34)
                    Text(verbatim: "\(n)").dxFace(.display, 15, weight: 800, tracking: -0.3).foregroundStyle(Color(hex: 0x1E1A3A))
                } else if isNow {
                    NowRing()
                    Circle().fill(TodayInk.card).overlay(Circle().strokeBorder(TodayInk.coral, lineWidth: 2.5))
                    Text(verbatim: "\(n)").dxFace(.display, 15, weight: 800, tracking: -0.3).foregroundStyle(TodayInk.ink)
                } else {
                    DXBadge(.prep, state: .next(nil), size: 34)
                    Text(verbatim: "\(n)").dxFace(.display, 15, weight: 800).foregroundStyle(TodayInk.ink.opacity(0.8))
                }
            }
            .frame(width: 34, height: 34)
            .padding(.vertical, 7)
            .modifier(StampArrive(index: n, earned: n <= done))
            if isNow {
                Text("Today").dxFace(.body, 13, weight: 700).foregroundStyle(TodayInk.coralText).fixedSize()
            }
        }
        .frame(width: 34)
    }
}

/// Earned stamps rise in one by one from 640 ms, 90 ms apart, no spring.
private struct StampArrive: ViewModifier {
    let index: Int
    let earned: Bool

    func body(content: Content) -> some View {
        if earned { content.dxArrive(index, delay: 0.64) } else { content }
    }
}

/// Today's open slot breathes its coral outline (2.4 s loop).
private struct NowRing: View {
    private let motion = MotionPolicy()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: motion.reduce)) { timeline in
            let k = motion.reduce ? 0 : (1 - cos(2 * .pi * timeline.date.timeIntervalSinceReferenceDate / 2.4)) / 2
            Circle()
                .strokeBorder(TodayInk.coral, lineWidth: 2)
                .padding(-5)
                .scaleEffect(1 + 0.08 * k)
                .opacity(0.4 - 0.3 * k)
        }
        .accessibilityHidden(true)
    }
}

// MARK: Night ticks (018)

/// The last seven nights under the check-in: a tick for each night checked in, tonight in a gold ring.
struct TodayNightTicks: View {
    struct Night: Identifiable {
        let date: Date
        let done: Bool
        let isTonight: Bool
        var id: Date { date }
    }

    let nights: [Night]

    var body: some View {
        let ground = DX.Ground.violet
        HStack(spacing: 0) {
            ForEach(Array(nights.enumerated()), id: \.element.id) { index, night in
                VStack(spacing: 8) {
                    ZStack {
                        if night.done {
                            Circle().fill(Color(hex: 0xF3E7CC))
                            DXIconShape(d: DX.Icon.check.d)
                                .stroke(Color(hex: 0x0F1B33), style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                                .frame(width: 14, height: 14)
                        } else if night.isTonight {
                            Circle().strokeBorder(Color(hex: 0xFFD37A), lineWidth: 2.5).padding(-4)
                            Circle().fill(ground.card2)
                            Circle().strokeBorder(Color(hex: 0xF3E7CC).opacity(0.7), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3])).padding(3)
                            Text(verbatim: night.date.formatted(.dateTime.day())).dxFace(.display, 13, weight: 800).foregroundStyle(ground.ink)
                        } else {
                            Circle().strokeBorder(ground.ink.opacity(0.25), lineWidth: 2)
                        }
                    }
                    .frame(width: 30, height: 30)
                    .dxPop(index, delay: 0.5)
                    Text(verbatim: night.date.formatted(.dateTime.weekday(.abbreviated)))
                        .dxType(.caption)
                        .foregroundStyle(night.isTonight ? Color(hex: 0xFFD37A) : ground.muted)
                        .fontWeight(night.isTonight ? .bold : .semibold)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 14)
        .overlay(alignment: .top) { Rectangle().fill(ground.line).frame(height: 1) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(nights.filter(\.done).count) of \(nights.count) nights"))
    }
}

// MARK: Session

/// Today's program session, from `ProgramToday`: the focus card, or a row in the day's list when another card has
/// the focus. It only draws; Today owns opening the session, so the session survives the card moving at 6 PM.
struct TodaySessionCard: View {
    enum Style { case focus, row }

    let today: ProgramToday
    let style: Style
    var crewStage = 1
    let onOpen: (String) -> Void
    let onUnlock: (String, String) -> Void

    var body: some View {
        switch today.kind {
        case let .open(id, inProgress, needsUpgrade):
            let kicker = today.isCatchUp ? String(localized: "Catch up · \(today.label) · \(today.minutes) min")
                : String(localized: "\(today.label) · \(today.minutes) min")
            let detail: String? = needsUpgrade ? nil
                : today.prepRunsOver ? String(localized: "Prep catch-up, whenever you like. It never holds back Day Xero.")
                : inProgress ? String(localized: "Xero saved your place.") : nil
            let button: String = needsUpgrade ? String(localized: "Unlock") : inProgress ? String(localized: "Continue") : String(localized: "Start")
            let action = { if needsUpgrade { onUnlock(id, today.title) } else { onOpen(id) } }
            Group {
                switch style {
                case .focus:
                    TodayFocusCard(art: id == ProgramV2Access.offerAfter ? .quitDay : .session, kicker: kicker, title: today.title,
                                   detail: detail, button: button, showsPlay: !needsUpgrade, crewStage: crewStage, action: action)
                case .row:
                    TodayRowCard(icon: .play, title: "\(today.label) · \(today.title)", detail: "\(today.minutes) min", trailing: button,
                                 showsChevron: true, action: action)
                }
            }
            .accessibilityHint(needsUpgrade ? Text("Shows how to unlock it") : Text(inProgress ? "Continues the session" : "Starts the session"))
            .accessibilityIdentifier("today.lesson")
        case let .waiting(next):
            switch style {
            case .focus:
                TodayFocusCard(art: .session, kicker: today.mission == nil ? String(localized: "Up next") : String(localized: "Today's mission"),
                               title: today.mission ?? next, detail: today.mission == nil ? nil : next, crewStage: crewStage,
                               action: nil)
            case .row:
                TodayRowCard(icon: .clock, title: today.mission ?? next, detail: today.mission == nil ? nil : next, action: nil)
            }
        case .complete:
            switch style {
            case .focus:
                TodayFocusCard(art: .session, kicker: String(localized: "Program complete"),
                               title: String(localized: "Replay any session."), crewStage: crewStage, action: nil)
            case .row:
                EmptyView()
            }
        }
    }
}
