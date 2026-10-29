import DayXeroCore
import SwiftData
import SwiftUI

/// Water on Home (S7.8): one of the logging cards (S24), beside a single product or the third one. Today's glasses,
/// the mini pill, and a one-tap log of the last chosen drink. Tap the top of the card to open the tracker.
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
        let reached = total >= goal

        VStack(alignment: .leading, spacing: 10) {
            Button(action: onOpen) {
                HStack(alignment: .top, spacing: DX.Space.xs) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: DX.Space.xs) {
                            Image(systemName: "drop").font(.system(size: 13, weight: .light)).foregroundStyle(Color(hex: 0x54A4FF))
                                .frame(width: 28, height: 28).background(Color(hex: 0x3D8BF2, opacity: 0.18), in: Circle())
                            Text("Water today").font(.custom(DX.Typeface.semibold, size: 13, relativeTo: .footnote))
                                .foregroundStyle(DX.Palette.text2)
                        }
                        // One unit on Home; litres are in the Water tab (S18.10).
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(WaterFormat.glasses(total), format: .number).font(.custom(DX.Typeface.bold, size: 28, relativeTo: .title))
                                .foregroundStyle(DX.Palette.text).contentTransition(.numericText())
                            Text(reached ? "goal reached" as LocalizedStringKey : "of \(goal / WaterGoal.glassMl) glasses")
                                .font(.custom(DX.Typeface.regular, size: 12, relativeTo: .caption)).foregroundStyle(DX.Palette.muted)
                        }
                    }
                    Spacer(minLength: 0)
                    WaterPillView(level: Double(total) / Double(goal), drink: todays.last?.drink ?? .glass, reached: reached, size: .mini)
                        .environment(\.colorScheme, .dark)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint(Text("Opens the water tracker"))
            Spacer(minLength: 0)
            Button {
                WaterLog.log(drink, source: .app, in: context)
                logged += 1
                Analytics.track(.waterLogged(source: WaterSource.app.rawValue, drink: drink.rawValue))
            } label: {
                Text("+ Log water").font(.custom(DX.Typeface.semibold, size: 13, relativeTo: .footnote)).foregroundStyle(DX.Palette.text)
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(DX.Palette.surface2, in: Capsule())
                    .overlay(Capsule().strokeBorder(DX.Palette.hairline))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Log \(Text(drink.name))"))
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(DX.Palette.hairline))
        .sensoryFeedback(.impact(weight: .medium), trigger: logged)
    }
}
