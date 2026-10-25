import DayXeroCore
import SwiftUI

/// Water goal onboarding (S2.14), signed off as drawn in `reference/water/WOnbBody.html`, `WOnbDay.html` and `WOnbGoal.html`.

/// Screen 1 · Your body: units, then height and weight on ruler pickers.
struct WaterBodyScreen: View {
    @Bindable var model: OnboardingModel

    var body: some View {
        OnboardingScaffold(title: "A few basics so we can size your goal.", eyebrow: "YOUR WATER GOAL") {
            unitToggle
            measurement(label: "Height", value: heightText, unit: model.waterUnits == .metric ? "cm" : nil) {
                if model.waterUnits == .metric {
                    RulerPicker(value: $model.heightCm, range: 120...220, step: 1, pointsPerStep: 7, minorEvery: 2,
                                majorEvery: 10, label: { "\(Int($0))" }, accessibilityLabel: "Height",
                                accessibilityValue: { "\(Int($0)) centimetres" })
                } else {
                    RulerPicker(value: inches, range: 48...87, step: 1, pointsPerStep: 10, minorEvery: 1, majorEvery: 12,
                                label: { "\(Int($0) / 12)′" }, accessibilityLabel: "Height",
                                accessibilityValue: { "\(Int($0) / 12) feet \(Int($0) % 12) inches" })
                }
            }
            .padding(.top, DX.Space.xs)
            measurement(label: "Weight", value: weightText, unit: model.waterUnits == .metric ? "kg" : "lb") {
                if model.waterUnits == .metric {
                    RulerPicker(value: $model.weightKg, range: 35...200, step: 1, pointsPerStep: 14, minorEvery: 1,
                                majorEvery: 10, label: { "\(Int($0))" }, accessibilityLabel: "Weight",
                                accessibilityValue: { "\(Int($0)) kilograms" })
                } else {
                    RulerPicker(value: pounds, range: 77...441, step: 1, pointsPerStep: 7, minorEvery: 2, majorEvery: 10,
                                label: { "\(Int($0))" }, accessibilityLabel: "Weight",
                                accessibilityValue: { "\(Int($0)) pounds" })
                }
            }
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lock").font(.system(size: 14, weight: .semibold)).foregroundStyle(DX.Palette.accentInk)
                    .padding(.top, 2)
                    .accessibilityHidden(true)
                Text("Only used to estimate your water goal. Stays on your phone. We never show you a BMI score.")
                    .font(.custom(DX.Typeface.medium, size: 13, relativeTo: .footnote))
                    .foregroundStyle(DX.Palette.text2)
                    .lineSpacing(3)
            }
            .padding(.top, DX.Space.s)
        } footer: {
            ContinueButton(title: "Continue", model: model)
            Button("Skip, use 8 glasses") { model.skipWater() }
                .font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .body))
                .foregroundStyle(DX.Palette.text2)
                .frame(minHeight: 40)
        }
    }

    private var unitToggle: some View {
        HStack(spacing: 0) {
            ForEach([WaterUnits.metric, .imperial], id: \.self) { units in
                let on = model.waterUnits == units
                Button(units == .metric ? "cm · kg" : "ft · lb") { model.waterUnits = units }
                    .font(.custom(DX.Typeface.semibold, size: 13, relativeTo: .footnote))
                    .foregroundStyle(on ? DX.Palette.onPrimary : DX.Palette.text2)
                    .padding(.horizontal, 16)
                    .frame(minHeight: 34)
                    .background(on ? DX.Palette.primary : .clear, in: Capsule())
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(3)
        .background(DX.Palette.surface2, in: Capsule())
        .sensoryFeedback(.selection, trigger: model.waterUnits)
    }

    private func measurement<Ruler: View>(label: LocalizedStringKey, value: String, unit: String?,
                                          @ViewBuilder ruler: () -> Ruler) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.custom(DX.Typeface.semibold, size: 14, relativeTo: .subheadline)).foregroundStyle(DX.Palette.text2)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(verbatim: value).font(.custom(DX.Typeface.extraBold, size: 48, relativeTo: .largeTitle))
                    .tracking(-1.4).monospacedDigit().foregroundStyle(DX.Palette.text)
                if let unit {
                    Text(verbatim: unit).font(.custom(DX.Typeface.semibold, size: 17, relativeTo: .body)).foregroundStyle(DX.Palette.muted)
                }
            }
            .accessibilityHidden(true)
            ruler().padding(.top, 8)
        }
        .padding(.top, DX.Space.s)
    }

    private var heightText: String {
        if model.waterUnits == .metric { return "\(Int(model.heightCm.rounded()))" }
        let total = Int((model.heightCm / 2.54).rounded())
        return "\(total / 12)′ \(total % 12)″"
    }

    private var weightText: String {
        model.waterUnits == .metric ? "\(Int(model.weightKg.rounded()))" : "\(Int((model.weightKg / WaterGoal.kgPerLb).rounded()))"
    }

    /// Imperial views of the metric values; whole inches and pounds.
    private var inches: Binding<Double> {
        Binding(get: { (model.heightCm / 2.54).rounded() }, set: { model.heightCm = $0 * 2.54 })
    }

    private var pounds: Binding<Double> {
        Binding(get: { (model.weightKg / WaterGoal.kgPerLb).rounded() }, set: { model.weightKg = WaterGoal.kilograms(pounds: $0) })
    }
}

/// Screen 2 · Your day: activity and climate.
struct WaterDayScreen: View {
    @Bindable var model: OnboardingModel

    var body: some View {
        OnboardingScaffold(title: "How active is a normal day for you?", eyebrow: "YOUR WATER GOAL") {
            ForEach(WaterActivity.allCases, id: \.self) { activity in
                choiceCard(activity)
            }
            Text("Where you live, most days are").font(.custom(DX.Typeface.semibold, size: 14, relativeTo: .subheadline))
                .foregroundStyle(DX.Palette.text2)
                .padding(.top, DX.Space.s)
            HStack(spacing: 10) {
                ForEach(WaterClimate.allCases, id: \.self) { climate in
                    let on = model.waterClimate == climate
                    Button { model.waterClimate = climate } label: {
                        Text(climate.title).font(.custom(DX.Typeface.semibold, size: 16, relativeTo: .body))
                            .foregroundStyle(DX.Palette.text)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(on ? DX.Palette.sage.opacity(0.12) : DX.Palette.surface1, in: Capsule())
                            .overlay(Capsule().strokeBorder(on ? DX.Palette.sage : DX.Palette.hairline, lineWidth: on ? 2 : 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
        } footer: {
            ContinueButton(title: "See my goal", model: model)
        }
        .sensoryFeedback(.selection, trigger: model.waterActivity)
    }

    private func choiceCard(_ activity: WaterActivity) -> some View {
        let on = model.waterActivity == activity
        return Button { model.waterActivity = activity } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(activity.title).font(.custom(DX.Typeface.semibold, size: 17, relativeTo: .body)).foregroundStyle(DX.Palette.text)
                    Text(subtitle(activity)).font(.custom(DX.Typeface.medium, size: 13, relativeTo: .footnote)).foregroundStyle(DX.Palette.text2)
                }
                Spacer(minLength: 0)
                if on {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 22))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(DX.Palette.onAccent, DX.Palette.sage)
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, 16).padding(.horizontal, 18)
            .background(on ? DX.Palette.sage.opacity(0.12) : DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(on ? DX.Palette.sage : DX.Palette.hairline, lineWidth: on ? 2 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func subtitle(_ activity: WaterActivity) -> LocalizedStringKey {
        switch activity {
        case .mostlySitting: "Desk, studies, driving"
        case .onMyFeet: "Walking, standing at work"
        case .worksOut: "Gym, runs, sport, 30+ min"
        case .veryActive: "Physical job or training hard daily"
        }
    }
}

/// Screen 3 · Your water goal: the full pill, the goal, how we got there, and Adjust.
struct WaterGoalScreen: View {
    @Bindable var model: OnboardingModel

    var body: some View {
        let b = model.waterBreakdown
        let goal = model.waterGoalMl
        let units = model.waterUnits
        OnboardingScaffold(title: "Your water goal") {
            HStack(spacing: 20) {
                WaterPillView(level: 1, drink: .glass, reached: true)
                    .scaleEffect(0.6)
                    .frame(width: 132, height: 214)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("YOUR DAILY GOAL").font(.custom(DX.Typeface.mono, size: 11, relativeTo: .caption2)).tracking(0.8)
                        .foregroundStyle(DX.Palette.accentInk)
                    (Text(verbatim: WaterFormat.amount(goal, units: units))
                        .font(.custom(DX.Typeface.extraBold, size: 56, relativeTo: .largeTitle)).tracking(-2)
                     + Text(verbatim: " \(WaterFormat.unit(units))")
                        .font(.custom(DX.Typeface.extraBold, size: 24, relativeTo: .title2)).foregroundStyle(DX.Palette.muted))
                        .foregroundStyle(DX.Palette.text)
                        .contentTransition(.numericText())
                    Text("about \(goal / WaterGoal.glassMl) glasses").font(.custom(DX.Typeface.semibold, size: 16, relativeTo: .body))
                        .foregroundStyle(DX.Palette.text2)
                }
                .accessibilityElement(children: .combine)
            }
            Text("HOW WE GOT THERE").font(.custom(DX.Typeface.mono, size: 10, relativeTo: .caption2)).tracking(0.8)
                .foregroundStyle(DX.Palette.muted)
                .padding(.top, DX.Space.m)
            VStack(spacing: 0) {
                row("Base for \(weightLabel)", litres(b.baseMl, units), divider: true)
                if b.activityMl > 0 { row(activityLine, "+" + litres(b.activityMl, units), divider: true) }
                if b.climateMl > 0 { row("Hot or humid days", "+" + litres(b.climateMl, units), divider: true) }
                row("Rounded to full glasses", litres(b.goalMl, units), divider: model.waterGoalOverride != nil)
                if model.waterGoalOverride != nil { row("Your adjustment", litres(goal, units), divider: false) }
            }
            .padding(.vertical, 4).padding(.horizontal, 16)
            .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            HStack {
                Text("Adjust").font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .body)).foregroundStyle(DX.Palette.text2)
                Spacer()
                stepButton("minus", label: "One glass less") { adjust(-1) }
                Text("\(goal / WaterGoal.glassMl) glasses").font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .body))
                    .foregroundStyle(DX.Palette.text)
                    .frame(minWidth: 64)
                stepButton("plus", label: "One glass more") { adjust(1) }
            }
            .padding(.top, DX.Space.xs)
            .accessibilityElement(children: .contain)
            Text("An estimate, not medical advice. If a doctor has told you to limit fluids, use their number instead.")
                .font(.custom(DX.Typeface.medium, size: 12, relativeTo: .caption))
                .foregroundStyle(DX.Palette.muted)
                .lineSpacing(3)
                .padding(.top, DX.Space.xs)
        } footer: {
            ContinueButton(title: "Set my goal", model: model)
        }
        .sensoryFeedback(.selection, trigger: goal)
    }

    private var weightLabel: String {
        model.waterUnits == .metric ? "\(Int(model.weightKg.rounded())) kg" : "\(Int((model.weightKg / WaterGoal.kgPerLb).rounded())) lb"
    }

    private var activityLine: LocalizedStringKey {
        model.waterActivity == .veryActive ? "Very active days" : "Workouts most days"
    }

    private func litres(_ ml: Int, _ units: WaterUnits) -> String {
        units == .metric ? String(format: "%.2f L", Double(ml) / 1000) : "\(Int((Double(ml) / WaterFormat.mlPerFlOz).rounded())) fl oz"
    }

    private func adjust(_ glasses: Int) {
        model.waterGoalOverride = WaterGoal.adjusted(model.waterGoalMl, by: glasses)
        if model.waterGoalOverride == model.waterBreakdown.goalMl { model.waterGoalOverride = nil }
    }

    private func row(_ label: LocalizedStringKey, _ value: String, divider: Bool) -> some View {
        HStack {
            Text(label).foregroundStyle(DX.Palette.text2)
            Spacer()
            Text(verbatim: value).fontWeight(.semibold).foregroundStyle(DX.Palette.text)
        }
        .font(.custom(DX.Typeface.regular, size: 15, relativeTo: .body))
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) { if divider { Rectangle().fill(DX.Palette.hairline).frame(height: 0.5) } }
        .accessibilityElement(children: .combine)
    }

    private func stepButton(_ symbol: String, label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 18, weight: .semibold)).foregroundStyle(DX.Palette.text)
                .frame(width: 44, height: 44)
                .background(DX.Palette.surface2, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }
}

/// A horizontal ruler with a sage centre line: drag to pick, snapping to whole steps with a tick of haptics.
struct RulerPicker: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let pointsPerStep: CGFloat
    /// A tick every this many steps.
    let minorEvery: Int
    /// A taller tick and a label every this many steps.
    let majorEvery: Int
    let label: (Double) -> String
    let accessibilityLabel: LocalizedStringKey
    let accessibilityValue: (Double) -> String

    @State private var dragStart: Double?

    var body: some View {
        Canvas { context, size in
            let mid = size.width / 2
            let first = Int(((value - Double(mid / pointsPerStep) * step) / step).rounded(.down)) - 1
            let last = Int(((value + Double(mid / pointsPerStep) * step) / step).rounded(.up)) + 1
            for i in first...last {
                let v = Double(i) * step
                guard range.contains(v), i % minorEvery == 0 || i % majorEvery == 0 else { continue }
                let x = mid + CGFloat((v - value) / step) * pointsPerStep
                let major = i % majorEvery == 0
                let half = majorEvery >= 2 && i % (majorEvery / 2) == 0
                let top: CGFloat = major ? 16 : half ? 20 : 24
                var tick = Path()
                tick.move(to: CGPoint(x: x, y: top))
                tick.addLine(to: CGPoint(x: x, y: 34))
                context.stroke(tick, with: .color(.primary.opacity(0.28)), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                if major {
                    context.draw(Text(verbatim: label(v)).font(.custom(DX.Typeface.mono, fixedSize: 9)).foregroundStyle(.primary.opacity(0.4)),
                                 at: CGPoint(x: x, y: 48))
                }
            }
            var centre = Path()
            centre.move(to: CGPoint(x: mid, y: 8))
            centre.addLine(to: CGPoint(x: mid, y: 40))
            context.stroke(centre, with: .color(DX.Palette.sage), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
        .frame(height: 54)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { drag in
                    let start = dragStart ?? value
                    dragStart = start
                    let moved = -Double(drag.translation.width / pointsPerStep) * step
                    value = min(max(((start + moved) / step).rounded() * step, range.lowerBound), range.upperBound)
                }
                .onEnded { _ in dragStart = nil }
        )
        .sensoryFeedback(.selection, trigger: value)
        .accessibilityElement()
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityValue(Text(accessibilityValue(value)))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = min(value + step, range.upperBound)
            case .decrement: value = max(value - step, range.lowerBound)
            @unknown default: break
            }
        }
    }
}
