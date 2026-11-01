import DayXeroCore
import SwiftData
import SwiftUI

/// Water on Today (S27.12, 1 Nov 2026): one row, "Water · 3 of 8 glasses", with a + that logs the usual drink.
/// It replaces the water card, the full-screen tracker and the weight-based goal sheet: hydration is a small
/// comfort during withdrawal, not a second app inside a quit app. The stored goal keeps its default (8 glasses).
struct WaterRow: View {
    let profile: UserProfile
    let now: Date

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
        let glasses = WaterFormat.glasses(total)
        let goalGlasses = max(goal / WaterGoal.glassMl, 1)

        HStack(spacing: 10) {
            Image(systemName: "drop").font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DX.Ground.reading.ink)
                .frame(width: 22, height: 22)
                .accessibilityHidden(true)
            Text("Water · \(glasses) of \(goalGlasses) glasses")
                .dxType(.body).foregroundStyle(DX.Ground.reading.ink)
                .contentTransition(.numericText())
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("today.water.count")
            Button {
                WaterLog.log(drink, source: .app, in: context)
                logged += 1
                Analytics.track(.waterLogged(source: WaterSource.app.rawValue, drink: drink.rawValue))
            } label: {
                Image(systemName: "plus").font(.system(size: 15, weight: .bold))
                    .foregroundStyle(DX.Ground.reading.ink)
                    .frame(width: 44, height: 44)
                    .background(DX.Fill.surface, in: Circle())
                    .overlay(Circle().strokeBorder(DX.Fill.hairline))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Log \(Text(drink.name))"))
            .accessibilityIdentifier("today.water.add")
        }
        .padding(.leading, 14).padding(.trailing, 8).padding(.vertical, 4)
        .background(DX.Fill.raised, in: RoundedRectangle(cornerRadius: DX.Layout.smallCardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DX.Layout.smallCardRadius, style: .continuous).strokeBorder(DX.Fill.hairline))
        .accessibilityElement(children: .contain)
        .sensoryFeedback(.impact(weight: .medium), trigger: logged)
    }
}
