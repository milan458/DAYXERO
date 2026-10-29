import SwiftUI

/// Day state in the week strip. There is deliberately no "slip" state: slips never change the streak visual.
public enum DXDayState: Sendable {
    case prep, clear, today, upcoming
    /// Quit Day while it's still ahead: outlined so it stands out in the strip.
    case quitDay
}

public struct DXWeekDay: Identifiable, Sendable {
    public let date: Date
    public let state: DXDayState
    public var id: Date { date }

    public init(date: Date, state: DXDayState) {
        self.date = date
        self.state = state
    }
}

public struct DXWeekStrip: View {
    let days: [DXWeekDay]

    public init(days: [DXWeekDay]) {
        self.days = days
    }

    public var body: some View {
        HStack(spacing: 6) {
            ForEach(days) { day in
                VStack(spacing: DX.Space.xs) {
                    Text(day.date, format: .dateTime.weekday(.abbreviated))
                        .font(.custom(DX.Typeface.regular, size: 11, relativeTo: .caption2))
                        .foregroundStyle(DX.Palette.muted)
                    bubble(day)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(day.date, format: .dateTime.weekday(.wide).day().month()))
                .accessibilityValue(Text(stateLabel(day.state)))
            }
        }
        // A compact visual: it keeps its layout at accessibility sizes; VoiceOver reads each day in full.
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
    }

    @ViewBuilder
    private func bubble(_ day: DXWeekDay) -> some View {
        let number = Text(day.date, format: .dateTime.day())
            .font(.custom(day.state == .today ? DX.Typeface.bold : DX.Typeface.semibold, size: 14, relativeTo: .subheadline))
            .monospacedDigit()
            // 40 pt circles, shrinking to 26 pt so a week still fits a narrow window such as iPhone Duo's cover
            // beside the side dock (S18.13).
            .frame(minWidth: 26, idealWidth: DX.Size.dayBubble, maxWidth: DX.Size.dayBubble,
                   minHeight: 26, idealHeight: DX.Size.dayBubble, maxHeight: DX.Size.dayBubble)
            .aspectRatio(1, contentMode: .fit)
        switch day.state {
        case .clear:
            number.foregroundStyle(DX.Palette.onAccent).background(DX.Palette.sage, in: Circle())
        case .today:
            number.foregroundStyle(DX.Palette.onPrimary).background(DX.Palette.primary, in: Circle())
        case .upcoming:
            number.foregroundStyle(DX.Palette.muted).background(DX.Palette.surface2, in: Circle())
        case .prep:
            number.foregroundStyle(DX.Palette.accentInk)
                .overlay(Circle().strokeBorder(DX.Palette.accentInk, style: StrokeStyle(lineWidth: 1, dash: [3, 3])))
        case .quitDay:
            number.foregroundStyle(DX.Palette.text)
                .background(DX.Palette.surface2, in: Circle())
                .overlay(Circle().strokeBorder(DX.Palette.text, lineWidth: 1.5))
        }
    }

    private func stateLabel(_ state: DXDayState) -> LocalizedStringKey {
        switch state {
        case .prep: "Prep day"
        case .clear: "Clear day"
        case .today: "Today"
        case .upcoming: "Upcoming"
        case .quitDay: "Quit Day"
        }
    }
}

/// Capsule list row with swipe actions (sage = done, amber = edit, terracotta = delete).
public struct DXListRow<Leading: View>: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    @ViewBuilder let leading: () -> Leading

    public init(_ title: LocalizedStringKey, subtitle: LocalizedStringKey, @ViewBuilder leading: @escaping () -> Leading) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading
    }

    public var body: some View {
        HStack(spacing: 14) {
            leading()
                .frame(width: 44, height: 44)
                .background(DX.Palette.surface1, in: Circle())
                .overlay(Circle().strokeBorder(DX.Palette.hairline))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).dxText(.cardHeading).font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .subheadline))
                Text(subtitle).dxText(.subtitle)
            }
            Spacer(minLength: 0)
            Circle().fill(DX.Palette.accentInk).frame(width: 8, height: 8).accessibilityHidden(true)
        }
        .padding(.leading, DX.Space.xs)
        .padding(.trailing, 14)
        .frame(minHeight: 64)
        .background(DX.Palette.surface1, in: Capsule())
        .overlay(Capsule().strokeBorder(DX.Palette.hairline))
        .accessibilityElement(children: .combine)
    }
}

/// Swipe-action tints for List rows.
public extension DX.Palette {
    static let actionDone = sage
    static let actionEdit = amber
    static let actionDelete = terracotta
}
