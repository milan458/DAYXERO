import DayXeroCore
import SwiftData
import SwiftUI

/// The water tracker (S7.7), signed off as drawn in `reference/water/water-pill-preview.html`:
/// header and streak, today's amount, the pill, the drink picker, Log and Undo, then today's drinks.
struct WaterTrackerView: View {
    let profile: UserProfile
    /// Shown as a close button when the tracker opens over the Toolkit tab or Home.
    var onClose: (() -> Void)?

    @Environment(\.modelContext) private var context
    @Query(sort: \WaterEntry.timestamp) private var entries: [WaterEntry]
    @Query private var waterProfiles: [WaterProfile]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var logged = 0
    @State private var goalHit = false
    @State private var floatText: String?
    @State private var floatID = 0
    @State private var customDrink: Drink?
    @State private var customAmount = ""

    var body: some View {
        let water = waterProfile
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        let today = clock.day(containing: .now)
        let todays = WaterDay.entries(entries, on: today, clock: clock)
        let total = todays.reduce(0) { $0 + $1.countedMl }
        let goal = water?.effectiveGoalMl ?? WaterGoal.skippedMl
        let units = water?.units ?? .default()
        let reached = total >= goal
        let selected = water?.selectedDrink ?? .glass
        let last = todays.last?.drink ?? .glass
        let streak = WaterDay.streak(entries, goalMl: goal, clock: clock)

        ScrollView {
            VStack(spacing: 0) {
                // The header and big numbers are part of the drawing; they stop growing where they'd wrap.
                // VoiceOver reads the same information from the pill.
                Group {
                    header(streak: streak)
                    readout(total: total, goal: goal, units: units, reached: reached)
                        .padding(.top, 18)
                }
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                WaterPillView(level: Double(total) / Double(goal), drink: last, reached: reached)
                    .padding(.top, 18)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("Water today"))
                    .accessibilityValue(Text(accessibilityValue(total: total, goal: goal)))
                    .accessibilityAdjustableAction { direction in
                        if direction == .increment { log(selected, goal: goal, before: total) }
                    }
                drinkPicker(selected: selected, units: units)
                    .padding(.top, 22)
                logButton(selected, units: units, goal: goal, before: total)
                    .padding(.top, 16)
                Button("Undo last") { undo(today: today, clock: clock) }
                    .font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .body))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(height: 40)
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .opacity(todays.isEmpty ? 0 : 1)
                    .disabled(todays.isEmpty)
                todayList(todays, units: units)
                    .padding(.top, DX.Space.l)
            }
            .padding(.horizontal, 24)
            .padding(.top, DX.Space.l)
            .padding(.bottom, DX.Space.l)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color.black.ignoresSafeArea())
        .environment(\.colorScheme, .dark)
        .sensoryFeedback(.impact(weight: .medium), trigger: logged)
        .sensoryFeedback(.success, trigger: goalHit)
        .onAppear(perform: ensureProfile)
        .alert("Custom amount", isPresented: Binding(get: { customDrink != nil }, set: { if !$0 { customDrink = nil } })) {
            TextField(units == .metric ? "ml" : "fl oz", text: $customAmount).keyboardType(.numberPad)
            Button("Log") {
                if let drink = customDrink, let value = Double(customAmount), value > 0 {
                    let ml = units == .metric ? Int(value) : Int((value * WaterFormat.mlPerFlOz).rounded())
                    log(drink, amount: min(ml, 2000), goal: goal, before: total)
                }
                customDrink = nil
                customAmount = ""
            }
            Button("Cancel", role: .cancel) { customDrink = nil; customAmount = "" }
        } message: {
            Text("How much \(Text(customDrink?.name ?? Drink.glass.name).foregroundStyle(.primary))?")
        }
    }

    // MARK: Parts

    private func header(streak: Int) -> some View {
        HStack {
            Text("Water")
                .font(.custom(DX.Typeface.extraBold, size: 28, relativeTo: .largeTitle))
                .tracking(-0.5)
                .foregroundStyle(.white)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if streak > 0 {
                Text(verbatim: "\(streak)-DAY STREAK")
                    .font(.custom(DX.Typeface.mono, size: 11, relativeTo: .caption2))
                    .tracking(0.6)
                    .foregroundStyle(Color(hex: 0xBCC388))
                    .padding(.vertical, 6).padding(.horizontal, 10)
                    .background(Color(hex: 0xBCC388, opacity: 0.12), in: Capsule())
                    .accessibilityLabel(Text("\(streak) day water streak"))
            }
            if let onClose {
                Button(action: onClose) { Image(systemName: "xmark") }
                    .buttonStyle(.dxIcon)
                    .accessibilityLabel(Text("Close"))
                    .padding(.leading, DX.Space.xxs)
            }
        }
    }

    private func readout(total: Int, goal: Int, units: WaterUnits, reached: Bool) -> some View {
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(verbatim: WaterFormat.amount(total, units: units))
                    .font(.custom(DX.Typeface.extraBold, size: 54, relativeTo: .largeTitle))
                    .tracking(-2)
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text(verbatim: "/ \(WaterFormat.amount(goal, units: units)) \(WaterFormat.unit(units))")
                    .font(.custom(DX.Typeface.semibold, size: 20, relativeTo: .title3))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .overlay(alignment: .topTrailing) { floatLabel.offset(x: 64, y: -10) }
            Text(reached ? "Goal reached. Nice." : "\(WaterFormat.glasses(total)) of \(goal / WaterGoal.glassMl) glasses")
                .font(.custom(DX.Typeface.semibold, size: 14, relativeTo: .subheadline))
                .foregroundStyle(reached ? Color(hex: 0xBCC388) : .white.opacity(0.6))
        }
        .accessibilityElement(children: .combine)
    }

    /// "+250 ml" rising from +10 to −46 pt over 1.1 s, fading in by 20% and out by the end.
    @ViewBuilder
    private var floatLabel: some View {
        if let floatText {
            PhaseAnimator([0.0, 0.2, 1.0], trigger: floatID) { p in
                Text(verbatim: floatText)
                    .font(.custom(DX.Typeface.extraBold, size: 18, relativeTo: .headline))
                    .foregroundStyle(Color(hex: 0xBCC388))
                    .fixedSize()
                    .offset(y: reduceMotion ? 0 : 10 - 56 * p)
                    .opacity(p == 0 ? 0 : p <= 0.2 ? 1 : (p >= 1 ? 0 : 1 - (p - 0.2) / 0.8))
            } animation: { p in
                p == 0.2 ? .easeOut(duration: 0.22) : p == 1.0 ? .easeOut(duration: 0.88) : nil
            }
            .id(floatID)
            .accessibilityHidden(true)
        }
    }

    private func drinkPicker(selected: Drink, units: WaterUnits) -> some View {
        HStack(spacing: 8) {
            ForEach(Drink.allCases) { drink in
                let on = drink == selected
                Button { waterProfile?.selectedDrink = drink; try? context.save() } label: {
                    VStack(spacing: 2) {
                        Text(drink.name).font(.custom(DX.Typeface.semibold, size: 14, relativeTo: .subheadline))
                        Text(verbatim: WaterFormat.size(drink.ml, units: units))
                            .font(.custom(DX.Typeface.medium, size: 12, relativeTo: .caption))
                            .opacity(0.65)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 62)
                    .background(on ? Color(hex: 0xBCC388, opacity: 0.12) : Color.white.opacity(0.04),
                                in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(on ? Color(hex: 0xBCC388) : Color.white.opacity(0.12), lineWidth: on ? 2 : 1))
                }
                .buttonStyle(.plain)
                .simultaneousGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in customDrink = drink })
                .accessibilityAddTraits(on ? [.isSelected] : [])
                .accessibilityHint(Text("Long-press to log a custom amount"))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Drink"))
    }

    private func logButton(_ drink: Drink, units: WaterUnits, goal: Int, before: Int) -> some View {
        Button { log(drink, goal: goal, before: before) } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus").font(.system(size: 16, weight: .bold))
                Text("Log \(WaterFormat.size(drink.ml, units: units))")
                    .font(.custom(DX.Typeface.semibold, size: 17, relativeTo: .body))
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(Color(hex: 0xBCC388), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func todayList(_ todays: [WaterEntry], units: WaterUnits) -> some View {
        if !todays.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Text("Today").font(.custom(DX.Typeface.semibold, size: 13, relativeTo: .footnote))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.bottom, DX.Space.xs)
                ForEach(todays.reversed()) { entry in
                    HStack {
                        Text(entry.timestamp, format: .dateTime.hour().minute())
                            .font(.custom(DX.Typeface.medium, size: 14, relativeTo: .subheadline))
                            .foregroundStyle(.white.opacity(0.55))
                            .frame(width: 72, alignment: .leading)
                        Text(entry.drink.name).font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .body)).foregroundStyle(.white)
                        Spacer()
                        Text(verbatim: WaterFormat.size(entry.amountMl, units: units))
                            .font(.custom(DX.Typeface.medium, size: 14, relativeTo: .subheadline))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.vertical, 12)
                    .overlay(alignment: .bottom) { Rectangle().fill(.white.opacity(0.08)).frame(height: 1) }
                    .contentShape(Rectangle())
                    .contextMenu {
                        Button("Delete", systemImage: "trash", role: .destructive) { delete(entry) }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityAction(named: Text("Delete")) { delete(entry) }
                }
            }
        }
    }

    // MARK: Data

    private var waterProfile: WaterProfile? { waterProfiles.first }

    private func accessibilityValue(total: Int, goal: Int) -> String {
        String(localized: "\(WaterFormat.amount(total, units: .metric)) of \(WaterFormat.amount(goal, units: .metric)) litres, \(WaterFormat.glasses(total)) of \(goal / WaterGoal.glassMl) glasses")
    }

    /// People who skipped water onboarding (or onboarded before it existed) start on 2 L.
    private func ensureProfile() {
        guard waterProfiles.isEmpty else { return }
        context.insert(WaterProfile(units: .default()))
        try? context.save()
    }

    private func log(_ drink: Drink, amount: Int? = nil, goal: Int, before: Int) {
        let entry = WaterLog.log(drink, amountMl: amount, source: .app, in: context)
        floatText = "+\(WaterFormat.size(entry.amountMl, units: waterProfile?.units ?? .metric))"
        floatID += 1
        logged += 1
        if before < goal, before + entry.countedMl >= goal {
            goalHit.toggle()
            Analytics.track(.waterGoalMet)
        }
        Analytics.track(.waterLogged(source: WaterSource.app.rawValue, drink: drink.rawValue))
    }

    private func undo(today: Date, clock: DayClock) {
        WaterLog.undoLast(today: today, clock: clock, in: context)
    }

    private func delete(_ entry: WaterEntry) {
        context.delete(entry)
        try? context.save()
    }
}
