import DayXeroCore
import SwiftUI

/// F08 Today's header (design doc §10): the ground and the crew member follow the time of day,
/// the sky clears with days clear, and three tiles count up. Morning and afternoon are Xero's
/// (apricot); evening and night are Glim's (violet).
struct TodayHeaderV4: View {
    let snap: HomeSnapshot
    let name: String
    let now: Date
    let onSettings: () -> Void

    enum Slot {
        case morning, afternoon, evening, night

        /// The same hours as HomeSnapshot.greeting.
        init(_ date: Date, calendar: Calendar = .current) {
            switch calendar.component(.hour, from: date) {
            case 5..<12: self = .morning
            case 12..<17: self = .afternoon
            case 17..<22: self = .evening
            default: self = .night
            }
        }

        var ground: DX.Ground { self == .morning || self == .afternoon ? .apricot : .violet }

        var scene: HorizonKind {
            switch self {
            case .morning: .dawn
            case .afternoon: .path
            case .evening: .dusk
            case .night: .night
            }
        }
    }

    private var slot: Slot {
        #if DEBUG
        switch UserDefaults.standard.string(forKey: "dx.todaySlot") {
        case "morning": return .morning
        case "afternoon": return .afternoon
        case "evening": return .evening
        case "night": return .night
        default: break
        }
        #endif
        return Slot(now)
    }

    private var greeting: String {
        let named = !name.isEmpty
        return switch slot {
        case .morning: named ? String(localized: "Morning, \(name).") : String(localized: "Morning.")
        case .afternoon: named ? String(localized: "Afternoon, \(name).") : String(localized: "Afternoon.")
        case .evening: named ? String(localized: "Evening, \(name).") : String(localized: "Evening.")
        case .night: named ? String(localized: "Still up, \(name)?") : String(localized: "Still up?")
        }
    }

    /// "Sun 8 Nov · Day 3", using the app's own day count.
    private var dateLine: String {
        let date = now.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        let day: String = switch snap.phase {
        case .prep: String(localized: "Prep day \(snap.prepDayNumber) of \(snap.prepTotal)")
        case .quitDay: String(localized: "Quit Day")
        case let .quitWeek(day): String(localized: "Day \(day)")
        case let .after(days): days == 1 ? String(localized: "1 day clear") : String(localized: "\(days) days clear")
        }
        return "\(date) · \(day)"
    }

    private var clarity: Int {
        if case .prep = snap.phase { return CrewGrowth.prepClarity }
        return CrewGrowth.clarity(daysClear: snap.daysClear)
    }

    var body: some View {
        let ground = slot.ground
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottom) {
                HeroScene(slot.scene, clarity: clarity, height: 210, edge: ground.background)
                Group {
                    if ground == .apricot {
                        XeroView(mood: .hello, stage: CrewGrowth.stage(daysClear: snap.daysClear), size: .scene)
                    } else {
                        GlimView(mood: slot == .night ? .sleepy : .calm, stage: CrewGrowth.stage(daysClear: snap.daysClear), size: .scene)
                    }
                }
                .offset(y: -6)
                .accessibilityHidden(true)
            }
            .overlay(alignment: .topTrailing) {
                Button(action: onSettings) {
                    Text(verbatim: String(name.prefix(1)).uppercased())
                        .dxType(.headline)
                        .foregroundStyle(DX.Fill.navy)
                        .frame(width: 44, height: 44)
                        .background(DX.Fill.cream.opacity(0.9), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Profile and settings"))
                .padding(12)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: dateLine).dxType(.caption).textCase(.uppercase).foregroundStyle(ground.muted)
                Text(verbatim: greeting).dxType(.large).foregroundStyle(ground.ink)
                    .accessibilityAddTraits(.isHeader)
            }
            .padding(.horizontal, 18)
            .padding(.top, 4)
            HStack(spacing: 8) { tiles(ground) }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 14)
        }
        .background(ground.background)
        .clipShape(RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
    }

    @ViewBuilder
    private func tiles(_ ground: DX.Ground) -> some View {
        let code = snap.currencyCode
        // Kept is shown to the cent, as the counter rounds it down (decision 17); yearly sums to the unit.
        let cents: (Double) -> String = { Decimal($0).formatted(.currency(code: code).precision(.fractionLength(2))) }
        let money: (Double) -> String = { Decimal($0).formatted(.currency(code: code).precision(.fractionLength(0))) }
        if case .prep = snap.phase {
            StatTile(value: Double(snap.prepDone), label: String(localized: "of \(snap.prepTotal) prep done"), ground: ground)
            StatTile(value: Double(max(snap.prepTotal - snap.prepDayNumber + 1, 0)), label: String(localized: "days to Quit Day"), ground: ground)
            StatTile(value: NSDecimalNumber(decimal: snap.moneyPerYear).doubleValue, label: String(localized: "to keep a year"),
                     ground: ground, format: money)
        } else {
            StatTile(value: Double(snap.daysClear), label: snap.daysClear == 1 ? String(localized: "day clear") : String(localized: "days clear"),
                     ground: ground)
            if let counter = snap.counters.first {
                StatTile(value: Double(counter.avoided), label: avoidedLabel(counter.product), ground: ground)
            }
            StatTile(value: NSDecimalNumber(decimal: snap.moneyKept).doubleValue, label: String(localized: "kept"), ground: ground, format: cents)
        }
    }

    private func avoidedLabel(_ product: Product) -> String {
        switch product {
        case .cigarettes: String(localized: "not smoked")
        case .vape: String(localized: "puffs not taken")
        case .pouches: String(localized: "pouches not used")
        }
    }
}
