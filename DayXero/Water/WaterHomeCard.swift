import DayXeroCore
import SwiftData
import SwiftUI

/// Water on Home (S7.8): the mini pill, today's glasses and a one-tap +1 of the last chosen drink.
/// Tap the card (or long-press) to open the tracker.
struct WaterHomeCard: View {
    let profile: UserProfile
    let now: Date
    let onOpen: () -> Void

    @Environment(\.modelContext) private var context
    @Query(sort: \WaterEntry.timestamp) private var entries: [WaterEntry]
    @Query private var waterProfiles: [WaterProfile]
    @State private var logged = 0

    var body: some View {
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        let todays = WaterDay.entries(entries, on: clock.day(containing: now), clock: clock)
        let total = todays.reduce(0) { $0 + $1.countedMl }
        let goal = waterProfiles.first?.effectiveGoalMl ?? WaterGoal.skippedMl
        let drink = waterProfiles.first?.selectedDrink ?? .glass
        let units = waterProfiles.first?.units ?? .default()
        let reached = total >= goal

        HStack(spacing: DX.Space.s) {
            Button(action: onOpen) {
                HStack(spacing: DX.Space.s) {
                    WaterPillView(level: Double(total) / Double(goal), drink: todays.last?.drink ?? .glass, reached: reached, size: .mini)
                        .environment(\.colorScheme, .dark)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Water").dxText(.micro)
                        Text(reached ? "Goal reached. Nice." : "\(WaterFormat.glasses(total)) of \(goal / WaterGoal.glassMl) glasses")
                            .font(.custom(DX.Typeface.semibold, size: 16, relativeTo: .body))
                            .foregroundStyle(DX.Palette.text)
                        Text(verbatim: "\(WaterFormat.amount(total, units: units)) / \(WaterFormat.amount(goal, units: units)) \(WaterFormat.unit(units))")
                            .dxText(.subtitle)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .simultaneousGesture(LongPressGesture().onEnded { _ in onOpen() })
            .accessibilityElement(children: .combine)
            .accessibilityHint(Text("Opens the water tracker"))

            Button {
                WaterLog.log(drink, source: .app, in: context)
                logged += 1
                Analytics.track(.waterLogged(source: WaterSource.app.rawValue, drink: drink.rawValue))
            } label: {
                Text("+1").font(.custom(DX.Typeface.bold, size: 15, relativeTo: .body))
                    .foregroundStyle(DX.Palette.onAccent)
                    .frame(minWidth: 52, minHeight: 40)
                    .background(DX.Palette.sage, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Log \(Text(drink.name))"))
        }
        .padding(14)
        .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(DX.Palette.hairline))
        .sensoryFeedback(.impact(weight: .medium), trigger: logged)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }
}
