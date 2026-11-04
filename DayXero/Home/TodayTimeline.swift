import DayXeroCore
import SwiftUI

// Today's lower half (Today redesign, 4 Nov 2026): the focus card under the sky, then the day as a timeline:
// Morning, Through the day, Evening, and what's next. Done steps shrink to ticked lines; the one step that matters
// now is the focus card, so it isn't repeated in the list.

/// Colours for the lower half. All of them follow the colour scheme, so the night's forced dark mode turns them.
enum TodayInk {
    static let card = Color(light: 0xFFFFFF, dark: 0x1B1747)
    static let ink = DX.Ground.reading.ink
    static let muted = DX.Ground.reading.muted
    static let page = DX.Ground.reading.background
    static let line = Color(light: (0x1E1A3A, 0.2), dark: (0xFFF8EE, 0.25))
    static let later = Color(light: 0xB8AFA3, dark: 0x5E5992)
    /// The evening check-in waiting for 6 PM.
    static let waiting = Color(light: 0xEEEAF8, dark: 0x241C52)
    static let waitingInk = Color(light: 0x4A3E7A, dark: 0xC9BFF2)
    static let recovery = Color(light: 0xDFF3E4, dark: 0x0F2A22)
    static let recoveryInk = Color(light: 0x24493A, dark: 0xA9D9C0)
    static let shadow = Color(light: (0x4A2A1A, 0.08), dark: (0x000000, 0))
}

// MARK: Timeline

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

/// The timeline: a dashed line down the left with a node per step.
struct TodayTimeline<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) { content }
            .background(alignment: .topLeading) {
                Line()
                    .stroke(TodayInk.line, style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
                    .frame(width: 2)
                    .padding(.leading, 11)
                    .padding(.vertical, 12)
                    .accessibilityHidden(true)
            }
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            return path
        }
    }
}

/// "Morning", "Through the day", "Evening".
struct TodaySectionLabel: View {
    let text: String

    var body: some View {
        Text(verbatim: text)
            .dxFont(13, weight: 700, style: .footnote)
            .foregroundStyle(TodayInk.muted)
            .padding(.leading, 40)
            .padding(.top, DX.Space.xs)
            .accessibilityAddTraits(.isHeader)
    }
}

/// A step on the timeline: its node on the line, its content to the right.
struct TodayStep<Content: View>: View {
    let node: TodayNode
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            nodeView
                .frame(width: 24, height: 36)
                .accessibilityHidden(true)
            content.frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var nodeView: some View {
        switch node {
        case .done:
            Image(systemName: "checkmark").font(.system(size: 11, weight: .heavy)).foregroundStyle(Color(hex: 0xFFF8EE))
                .frame(width: 24, height: 24).background(DX.Fill.green, in: Circle())
        case .now:
            Circle().fill(TodayInk.page).frame(width: 26, height: 26)
                .overlay(Circle().strokeBorder(TodayInk.ink, lineWidth: 3))
        case .later:
            Circle().fill(TodayInk.page).frame(width: 20, height: 20)
                .overlay(Circle().strokeBorder(TodayInk.later, lineWidth: 2))
        case .quitDay, .milestone:
            Image(systemName: "flag.fill").font(.system(size: 11, weight: .bold)).foregroundStyle(Color(hex: 0xFFF8EE))
                .frame(width: 24, height: 24)
                .background(node == .quitDay ? Color(hex: 0xFF7155) : DX.Fill.green, in: Circle())
        }
    }
}

/// A finished step: "Morning pledge … Done · 8:12".
struct TodayDoneRow: View {
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: DX.Space.xs) {
            Text(verbatim: title).dxFont(16, weight: 600, style: .body).foregroundStyle(TodayInk.muted)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(verbatim: detail).dxFont(13, weight: 700, style: .footnote).foregroundStyle(DX.Fill.green)
                .lineLimit(1).fixedSize()
        }
        .frame(minHeight: 36)
        .accessibilityElement(children: .combine)
    }
}

/// A row card on the timeline: an optional log icon, a title and a quieter line, and what a tap does.
struct TodayRowCard: View {
    var glyph: LogGlyph?
    /// A small line above the title: "Happening now".
    var eyebrow: String?
    let title: String
    var detail: String?
    var trailing: String?
    var fill: Color = TodayInk.card
    var detailColor: Color = TodayInk.muted
    var showsChevron = false
    let action: (() -> Void)?

    var body: some View {
        let content = HStack(spacing: DX.Space.s) {
            if let glyph { LogIcon(glyph: glyph) }
            VStack(alignment: .leading, spacing: 2) {
                if let eyebrow {
                    Text(verbatim: eyebrow).dxFont(13, weight: 600, style: .footnote).foregroundStyle(TodayInk.recoveryInk)
                }
                Text(verbatim: title).dxFont(16, weight: 600, style: .body).foregroundStyle(TodayInk.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail {
                    Text(verbatim: detail).dxFont(13, weight: 500, style: .footnote).foregroundStyle(detailColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let trailing {
                Text(verbatim: trailing).dxFont(13, weight: 600, style: .footnote).foregroundStyle(TodayInk.muted)
            }
            if showsChevron {
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(TodayInk.muted)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minHeight: 56)
        .background(fill, in: RoundedRectangle(cornerRadius: DX.Layout.smallCardRadius, style: .continuous))
        .contentShape(Rectangle())
        if let action {
            Button(action: action) { content }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
        } else {
            content.accessibilityElement(children: .combine)
        }
    }
}

// MARK: Focus card

/// The one card under the sky: today's session, the evening check-in, winding down, or what's changing in the body.
/// White by day, the night surface after 6 PM, with a small arch of art on the left and one full-width button.
struct TodayFocusCard: View {
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
    var buttonFill: Color = DX.Fill.lessonCard
    var showsPlay = false
    var crewStage = 1
    let action: (() -> Void)?

    var body: some View {
        let card = VStack(alignment: .leading, spacing: DX.Space.s) {
            HStack(alignment: .center, spacing: 14) {
                artView
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: kicker).dxFont(14, weight: 600, style: .footnote).foregroundStyle(TodayInk.muted)
                    Text(verbatim: title).dxFont(21, weight: 800, style: .title3).foregroundStyle(TodayInk.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    if let detail {
                        Text(verbatim: detail).dxFont(14, weight: 500, style: .footnote).foregroundStyle(TodayInk.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let button {
                HStack(spacing: DX.Space.xs) {
                    if showsPlay { Image(systemName: "play.fill").font(.system(size: 13, weight: .bold)) }
                    Text(verbatim: button).dxFont(17, weight: 700, style: .body)
                }
                .foregroundStyle(Color(hex: 0xFFF8EE))
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(buttonFill, in: Capsule())
                .accessibilityHidden(true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous)
                .fill(TodayInk.card)
                .shadow(color: TodayInk.shadow, radius: 12, y: 8)
        }
        if let action {
            Button(action: action) { card }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
        } else {
            card.accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private var artView: some View {
        switch art {
        case let .recovery(id):
            HealthBadge(id: id, state: .underWay(0), size: 72, showsRing: false)
                .frame(width: 72, height: 84)
                .accessibilityHidden(true)
        default:
            ZStack(alignment: .bottomLeading) {
                UnevenRoundedRectangle(topLeadingRadius: 36, bottomLeadingRadius: 0, bottomTrailingRadius: 0,
                                       topTrailingRadius: 36, style: .continuous)
                    .fill(LinearGradient(colors: archColors, startPoint: .top, endPoint: .bottom))
                archSky
                crew
                    .frame(width: 52, height: 52)
                    .offset(x: 6, y: 4)
            }
            .frame(width: 72, height: 84)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 36, bottomLeadingRadius: 0, bottomTrailingRadius: 0,
                                              topTrailingRadius: 36, style: .continuous))
            .accessibilityHidden(true)
        }
    }

    private var archColors: [Color] {
        switch art {
        case .session: [Color(hex: 0x9FE3AE), Color(hex: 0x2FA262)]
        case .quitDay: [Color(hex: 0xFF9D6E), Color(hex: 0xE85A3E)]
        case .checkIn: [Color(hex: 0x2A1C6E), Color(hex: 0x6B4FD8)]
        case .windDown, .recovery: [Color(hex: 0x0E0B2B), Color(hex: 0x2A1C6E)]
        }
    }

    @ViewBuilder
    private var archSky: some View {
        switch art {
        case .session, .quitDay:
            Circle().fill(Color(hex: 0xFFE27A)).frame(width: 16, height: 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 16).padding(.trailing, 14)
        case .checkIn, .windDown, .recovery:
            Image(systemName: "moon.fill").font(.system(size: 16)).foregroundStyle(Color(hex: 0xFFE9A8))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 14).padding(.trailing, 14)
        }
    }

    @ViewBuilder
    private var crew: some View {
        switch art {
        case .session, .quitDay:
            XeroView(mood: art == .quitDay ? .cheer : .hello, stage: crewStage, points: 52, animate: false)
        default:
            GlimView(mood: .calm, stage: crewStage, points: 52, animate: false)
        }
    }
}

// MARK: Session

/// Today's program session, from `ProgramToday`: the focus card, or a row on the timeline when another card has the
/// focus. It only draws; Today owns opening the session, so the session survives the card moving at 6 PM.
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
                    TodayRowCard(title: "\(today.label) · \(today.title)", detail: "\(today.minutes) min", trailing: button,
                                 action: action)
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
                TodayRowCard(title: today.mission ?? next, detail: today.mission == nil ? nil : next, action: nil)
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
