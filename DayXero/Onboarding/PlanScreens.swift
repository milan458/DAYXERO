import DayXeroCore
import SwiftUI

// MARK: Quit Day calendar ("Pick another date" on F04)

/// Weeks from this one to the last allowed Quit Day. Prep days are tinted as one track that runs into Quit Day.
struct QuitDayCalendar: View {
    @Binding var quitDay: Date
    let today: Date
    let range: ClosedRange<Date>
    let calendar: Calendar

    private var days: [Date] {
        let start = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let endWeek = calendar.dateInterval(of: .weekOfYear, for: range.upperBound)
        let end = endWeek.map { $0.end } ?? range.upperBound
        var all: [Date] = []
        var day = start
        while day < end {
            all.append(day)
            day = calendar.date(byAdding: .day, value: 1, to: day) ?? end
        }
        return all
    }

    private var weekdays: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    private var header: String {
        let first = today.formatted(.dateTime.month(.abbreviated))
        let last = range.upperBound.formatted(.dateTime.month(.abbreviated).year())
        return calendar.isDate(today, equalTo: range.upperBound, toGranularity: .month) ? last : "\(first) – \(last)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(verbatim: header).dxFont(15, weight: 600, style: .headline).foregroundStyle(Onb.ink)
                Spacer()
                legend(Onb.accent, "Prep")
                legend(Onb.accent, "Quit Day")
            }
            .accessibilityElement(children: .combine)
            HStack(spacing: 0) {
                ForEach(Array(weekdays.enumerated()), id: \.offset) { _, symbol in
                    Text(verbatim: symbol).dxFont(11, weight: 600, style: .caption2)
                        .foregroundStyle(Onb.muted).frame(maxWidth: .infinity)
                }
            }
            .accessibilityHidden(true)
            let all = days
            ForEach(0..<(all.count / 7), id: \.self) { week in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { column in
                        cell(all[week * 7 + column], column: column)
                    }
                }
            }
        }
        .padding(DX.Space.m)
        .background(Onb.raised, in: RoundedRectangle(cornerRadius: DX.Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DX.Radius.card, style: .continuous).strokeBorder(Onb.hairline))
    }

    private func legend(_ color: Color, _ title: LocalizedStringKey) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(title).dxFont(12, weight: 400, style: .caption1).foregroundStyle(Onb.muted)
        }
        .padding(.leading, DX.Space.s)
    }

    private func isPrep(_ day: Date) -> Bool { day >= today && day < calendar.startOfDay(for: quitDay) }

    @ViewBuilder
    private func cell(_ day: Date, column: Int) -> some View {
        let quit = calendar.isDate(day, inSameDayAs: quitDay)
        let prep = isPrep(day)
        let selectable = range.contains(day)
        let isToday = calendar.isDate(day, inSameDayAs: today)
        let previous = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        let next = calendar.date(byAdding: .day, value: 1, to: day) ?? day
        let startsRun = column == 0 || !isPrep(previous)
        let endsRun = column == 6 || !isPrep(next)
        Button {
            quitDay = day
        } label: {
            ZStack {
                if prep {
                    UnevenRoundedRectangle(topLeadingRadius: startsRun ? 20 : 0, bottomLeadingRadius: startsRun ? 20 : 0,
                                           bottomTrailingRadius: endsRun ? 20 : 0, topTrailingRadius: endsRun ? 20 : 0, style: .continuous)
                        .fill(Onb.accentSoft)
                }
                if quit {
                    Circle().fill(Onb.accent).frame(width: 40, height: 40)
                        .shadow(color: Onb.accent.opacity(0.6), radius: 10)
                } else if isToday {
                    Circle().strokeBorder(Onb.accent, lineWidth: 1.5).frame(width: 34, height: 34)
                }
                Text(day, format: .dateTime.day())
                    .dxFont(15, weight: quit || prep || isToday ? 700 : 400, style: .body)
                    .foregroundStyle(quit ? Onb.onInk : (prep ? Onb.ink : (selectable ? Onb.muted : Onb.muted)))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!selectable)
        .sensoryFeedback(DX.Haptic.select, trigger: quit)
        .accessibilityLabel(Text(day, format: .dateTime.weekday(.wide).day().month(.wide)))
        .accessibilityValue(Text(quit ? "Quit Day" : (prep ? (isToday ? "Today, prep day" : "Prep day") : "")))
        .accessibilityAddTraits(quit ? [.isButton, .isSelected] : .isButton)
    }
}
