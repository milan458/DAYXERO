import DayXeroCore
import SwiftUI

/// A coloured action card on Today (F08): kicker, 19 pt title, 14 pt line, and a chevron in a 44 pt circle.
/// Cream text on every fill: ocean 6.0:1, lesson green 6.4:1, Glim violet 13:1, night 16:1.
struct ColourCard: View {
    let kicker: String
    let title: String
    let detail: String?
    let fill: Color
    var chevron = true
    let action: (() -> Void)?

    var body: some View {
        let content = HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: kicker.uppercased()).dxType(.caption)
                Text(verbatim: title).dxType(.headline).fixedSize(horizontal: false, vertical: true)
                if let detail { Text(verbatim: detail).dxType(.footnote).fixedSize(horizontal: false, vertical: true) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if chevron, action != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .heavy))
                    .frame(width: 44, height: 44)
                    .background(DX.Fill.cream.opacity(0.2), in: Circle())
                    .accessibilityHidden(true)
            }
        }
        .foregroundStyle(DX.Fill.cream)
        .padding(16)
        .background {
            // The lip shadow sits on the card shape only, so text is never doubled.
            RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous)
                .fill(fill)
                .shadow(color: .black.opacity(0.14), radius: 0, x: 0, y: 5)
        }
        if let action {
            Button(action: action) { content }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
        } else {
            content.accessibilityElement(children: .combine)
        }
    }

    static let ocean = Color(hex: 0x2A52DB)
    static let lesson = Color(hex: 0x0F6E43)
    static let glim = Color(hex: 0x2A1C6E)
    static let night = Color(hex: 0x0E0B2B)
}

/// The top card when it isn't the lesson: the usual wave, Glim's check-in, or winding down.
struct TodayTopCardV4: View {
    let card: TodayTopCard
    /// A plan they've saved for this wave's trigger, if any.
    let plan: IfThenPlan?
    let onSOS: () -> Void
    let onCheckIn: () -> Void
    let onWindDown: () -> Void

    var body: some View {
        switch card {
        case let .wave(wave):
            ColourCard(kicker: waveKicker(wave.trigger),
                       title: String(localized: "Usually comes around \(time(wave.minuteOfDay))"),
                       detail: plan.map { String(localized: "Your plan: \($0.action). Jelli is ready if the wave comes.") }
                           ?? String(localized: "Jelli is ready if the wave comes."),
                       fill: ColourCard.ocean, action: onSOS)
                .accessibilityHint(Text("Opens Craving SOS"))
        case .checkIn:
            ColourCard(kicker: String(localized: "With Glim · 1 min"), title: String(localized: "How was today, really?"),
                       detail: String(localized: "One question, then rest."), fill: ColourCard.glim, action: onCheckIn)
        case .windDown:
            ColourCard(kicker: String(localized: "Wind down"), title: String(localized: "Can't sleep? Breathe with Glim"),
                       detail: String(localized: "A slow breath, then rest."), fill: ColourCard.night, action: onWindDown)
        case .lesson:
            EmptyView()
        }
    }

    private func time(_ minuteOfDay: Int) -> String {
        let date = Calendar.current.date(bySettingHour: minuteOfDay / 60, minute: minuteOfDay % 60, second: 0, of: .now) ?? .now
        return date.formatted(date: .omitted, time: .shortened)
    }

    /// "Your coffee wave", or "Your usual wave" when no one trigger stands out.
    private func waveKicker(_ trigger: Trigger?) -> String {
        switch trigger {
        case .coffee: String(localized: "Your coffee wave")
        case .stress: String(localized: "Your stress wave")
        case .meals: String(localized: "Your after-meal wave")
        case .morning: String(localized: "Your morning wave")
        case .alcohol: String(localized: "Your drinking wave")
        case .boredom: String(localized: "Your boredom wave")
        case .work: String(localized: "Your work-break wave")
        case .driving: String(localized: "Your driving wave")
        case .phone: String(localized: "Your phone wave")
        case .social: String(localized: "Your social wave")
        case .other, nil: String(localized: "Your usual wave")
        }
    }
}

/// "Your day" (F08): the pledge, today's session and the evening check-in, each with a green dot when done.
struct YourDayList: View {
    struct Row: Identifiable {
        let id: String
        let label: String
        let meta: String
        let done: Bool
        let action: (() -> Void)?
    }

    let rows: [Row]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("YOUR DAY").dxType(.caption).foregroundStyle(DX.Ground.reading.muted)
                .padding(.top, 12).padding(.bottom, 2)
                .accessibilityAddTraits(.isHeader)
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                if index > 0 { Rectangle().fill(DX.Ground.reading.ink.opacity(0.1)).frame(height: 1) }
                if let action = row.action {
                    Button(action: action) { line(row) }.buttonStyle(.plain)
                } else {
                    line(row)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 4)
        .background(DX.Fill.raised, in: RoundedRectangle(cornerRadius: DX.Layout.smallCardRadius, style: .continuous))
    }

    private func line(_ row: Row) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(row.done ? DX.Fill.cream : .clear)
                .frame(width: 22, height: 22)
                .background(row.done ? DX.Fill.green : DX.Ground.reading.ink.opacity(0.16), in: Circle())
                .accessibilityHidden(true)
            Text(verbatim: row.label).dxType(.body).foregroundStyle(DX.Ground.reading.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(verbatim: row.meta).dxType(.footnote).foregroundStyle(DX.Ground.reading.muted)
            if row.action != nil {
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold))
                    .foregroundStyle(DX.Ground.reading.muted).accessibilityHidden(true)
            }
        }
        .frame(minHeight: 48)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(row.label), \(row.done ? String(localized: "done") : row.meta)"))
        .accessibilityAddTraits(row.action != nil ? .isButton : [])
    }
}
