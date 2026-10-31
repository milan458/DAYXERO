import DayXeroCore
import SwiftData
import SwiftUI

/// "Personalise goal" from the Water tab (S18.5): weight, a normal day, climate, then the goal with how we got
/// there and Adjust. It used to be three onboarding screens; it's one optional screen now, and height isn't asked.
struct WaterGoalSheet: View {
    let profile: WaterProfile
    let onClose: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(Entitlement.self) private var entitlement
    @State private var draft: WaterGoalDraft

    init(profile: WaterProfile, onClose: @escaping () -> Void) {
        self.profile = profile
        self.onClose = onClose
        _draft = State(initialValue: WaterGoalDraft(profile: profile))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        unitToggle
                        weight.padding(.top, DX.Space.xs)
                        heading("A normal day").padding(.top, DX.Space.s)
                        ForEach(WaterActivity.allCases, id: \.self) { choiceCard($0) }
                        heading("Where you live, most days are").padding(.top, DX.Space.s)
                        climate
                        goal.padding(.top, DX.Space.m)
                        Text("An estimate, not medical advice. If a doctor has told you to limit fluids, use their number instead.")
                            .dxFont(12, weight: 500, style: .caption1)
                            .foregroundStyle(Read4.muted)
                            .lineSpacing(3)
                            .padding(.top, DX.Space.xs)
                    }
                    .padding(.horizontal, DX.Space.m)
                    .dxReadableColumn()
                    .padding(.top, DX.Space.s)
                    .padding(.bottom, DX.Space.xl)
                }
                Button("Save goal", action: save)
                    .buttonStyle(.dx(.primary, on: .reading))
                    .padding(.horizontal, DX.Space.m)
                    .dxReadableColumn()
                    .padding(.bottom, DX.Space.xs)
            }
            .background(Read4.background.ignoresSafeArea())
            .navigationTitle(Text("Your water goal"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", action: onClose)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: draft.goalMl)
        .sensoryFeedback(.selection, trigger: draft.activity)
    }

    // MARK: Parts

    private func heading(_ text: LocalizedStringKey) -> some View {
        Text(text).dxFont(14, weight: 600, style: .subheadline).foregroundStyle(Read4.muted)
            .accessibilityAddTraits(.isHeader)
    }

    private var unitToggle: some View {
        HStack(spacing: 0) {
            ForEach([WaterUnits.metric, .imperial], id: \.self) { units in
                let on = draft.units == units
                Button(units == .metric ? "kg · L" : "lb · fl oz") { draft.units = units }
                    .dxFont(14, weight: 600, style: .footnote)
                    .foregroundStyle(on ? Read4.onInk : Read4.muted)
                    .padding(.horizontal, 16)
                    .frame(minHeight: 34)
                    .background(on ? Read4.ink : .clear, in: Capsule())
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(3)
        .background(Read4.surface, in: Capsule())
        .sensoryFeedback(.selection, trigger: draft.units)
    }

    private var weight: some View {
        VStack(alignment: .leading, spacing: 4) {
            heading("Weight")
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(verbatim: weightText).dxFont(48, weight: 800, style: .largeTitle)
                    .tracking(-1.4).monospacedDigit().foregroundStyle(Read4.ink)
                Text(verbatim: draft.units == .metric ? "kg" : "lb")
                    .dxFont(16, weight: 600, style: .body).foregroundStyle(Read4.muted)
            }
            .accessibilityHidden(true)
            Group {
                if draft.units == .metric {
                    RulerPicker(value: $draft.weightKg, range: 35...200, step: 1, pointsPerStep: 14, minorEvery: 1,
                                majorEvery: 10, label: { "\(Int($0))" }, accessibilityLabel: "Weight",
                                accessibilityValue: { "\(Int($0)) kilograms" })
                } else {
                    RulerPicker(value: pounds, range: 77...441, step: 1, pointsPerStep: 7, minorEvery: 2, majorEvery: 10,
                                label: { "\(Int($0))" }, accessibilityLabel: "Weight",
                                accessibilityValue: { "\(Int($0)) pounds" })
                }
            }
            .padding(.top, 8)
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lock").font(.system(size: 14, weight: .semibold)).foregroundStyle(Read4.accent)
                    .padding(.top, 2)
                    .accessibilityHidden(true)
                Text("Only used for your water goal. Stays on your phone.")
                    .dxFont(14, weight: 500, style: .footnote)
                    .foregroundStyle(Read4.muted)
            }
            .padding(.top, DX.Space.xs)
        }
    }

    private var weightText: String {
        draft.units == .metric ? "\(Int(draft.weightKg.rounded()))" : "\(Int((draft.weightKg / WaterGoal.kgPerLb).rounded()))"
    }

    /// The imperial view of the metric weight, in whole pounds.
    private var pounds: Binding<Double> {
        Binding(get: { (draft.weightKg / WaterGoal.kgPerLb).rounded() }, set: { draft.weightKg = WaterGoal.kilograms(pounds: $0) })
    }

    private func choiceCard(_ activity: WaterActivity) -> some View {
        let on = draft.activity == activity
        return Button { draft.activity = activity } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(activity.title).dxFont(16, weight: 600, style: .body).foregroundStyle(Read4.ink)
                    Text(subtitle(activity)).dxFont(14, weight: 500, style: .footnote).foregroundStyle(Read4.muted)
                }
                Spacer(minLength: 0)
                if on {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 22))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(DX.Fill.cream, Read4.accent)
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, 16).padding(.horizontal, 18)
            .background(on ? Read4.accent.opacity(0.12) : Read4.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(on ? Read4.accent : Read4.hairline, lineWidth: on ? 2 : 1))
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

    private var climate: some View {
        HStack(spacing: 10) {
            ForEach(WaterClimate.allCases, id: \.self) { climate in
                let on = draft.climate == climate
                Button { draft.climate = climate } label: {
                    Text(climate.title).dxFont(16, weight: 600, style: .body)
                        .foregroundStyle(Read4.ink)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(on ? Read4.accent.opacity(0.12) : Read4.card, in: Capsule())
                        .overlay(Capsule().strokeBorder(on ? Read4.accent : Read4.hairline, lineWidth: on ? 2 : 1))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }

    /// The goal, how we got there, and the Adjust stepper.
    private var goal: some View {
        let b = draft.breakdown
        let goal = draft.goalMl
        let units = draft.units
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(verbatim: WaterFormat.amount(goal, units: units))
                    .dxFont(48, weight: 800, style: .largeTitle).tracking(-1.4)
                    .foregroundStyle(Read4.ink)
                    .contentTransition(.numericText())
                Text(verbatim: WaterFormat.unit(units)).dxFont(16, weight: 600, style: .body)
                    .foregroundStyle(Read4.muted)
                Spacer(minLength: 0)
                Text("\(goal / WaterGoal.glassMl) glasses a day").dxFont(16, weight: 600, style: .body)
                    .foregroundStyle(Read4.muted)
            }
            .accessibilityElement(children: .combine)
            VStack(spacing: 0) {
                row("Base for \(weightText) \(units == .metric ? "kg" : "lb")", litres(b.baseMl, units), divider: true)
                if b.activityMl > 0 {
                    row(draft.activity == .veryActive ? "Very active days" : "Workouts most days", "+" + litres(b.activityMl, units), divider: true)
                }
                if b.climateMl > 0 { row("Hot or humid days", "+" + litres(b.climateMl, units), divider: true) }
                row("Rounded to full glasses", litres(b.goalMl, units), divider: draft.override != nil)
                if draft.override != nil { row("Your adjustment", litres(goal, units), divider: false) }
            }
            .padding(.vertical, 4).padding(.horizontal, 16)
            .background(Read4.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            HStack {
                Text("Adjust").dxFont(16, weight: 600, style: .body).foregroundStyle(Read4.muted)
                Spacer()
                stepButton("minus", label: "One glass less") { draft.adjust(by: -1) }
                Text("\(goal / WaterGoal.glassMl) glasses").dxFont(16, weight: 600, style: .body)
                    .foregroundStyle(Read4.ink)
                    .frame(minWidth: 64)
                stepButton("plus", label: "One glass more") { draft.adjust(by: 1) }
            }
            .accessibilityElement(children: .contain)
        }
    }

    private func litres(_ ml: Int, _ units: WaterUnits) -> String {
        units == .metric ? String(format: "%.2f L", Double(ml) / 1000) : "\(Int((Double(ml) / WaterFormat.mlPerFlOz).rounded())) fl oz"
    }

    private func row(_ label: LocalizedStringKey, _ value: String, divider: Bool) -> some View {
        HStack {
            Text(label).foregroundStyle(Read4.muted)
            Spacer()
            Text(verbatim: value).fontWeight(.semibold).foregroundStyle(Read4.ink)
        }
        .dxFont(16, weight: 400, style: .body)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) { if divider { Rectangle().fill(Read4.hairline).frame(height: 0.5) } }
        .accessibilityElement(children: .combine)
    }

    private func stepButton(_ symbol: String, label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 18, weight: .semibold)).foregroundStyle(Read4.ink)
                .frame(width: 44, height: 44)
                .background(Read4.surface, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }

    private func save() {
        draft.apply(to: profile)
        try? context.save()
        WidgetSync.refresh(in: context, isPro: entitlement.isPro)
        Analytics.track(.waterGoalSet(source: draft.override != nil ? "override" : "calculated",
                                      goalBucket: "\(draft.goalMl / 500 * 500)"))
        onClose()
    }
}

/// A horizontal ruler with a sage centre line: drag to pick, snapping to whole steps with a tick of haptics.
/// Only sideways drags move it, so scrolling the screen past the ruler can't change the value (S18.1).
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
    /// The current drag started mostly up or down: it's a scroll, so the ruler ignores it.
    @State private var ignoringDrag = false

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
                    context.draw(Text(verbatim: label(v)).font(DX.Typeface4.swiftUIFont(.body, size: 12, weight: 600)).foregroundStyle(.primary.opacity(0.4)),
                                 at: CGPoint(x: x, y: 48))
                }
            }
            var centre = Path()
            centre.move(to: CGPoint(x: mid, y: 8))
            centre.addLine(to: CGPoint(x: mid, y: 40))
            context.stroke(centre, with: .color(Read4.accent), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
        .frame(height: 54)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 8)
                .onChanged { drag in
                    if dragStart == nil, !ignoringDrag, abs(drag.translation.height) > abs(drag.translation.width) {
                        ignoringDrag = true
                    }
                    guard !ignoringDrag else { return }
                    let start = dragStart ?? value
                    dragStart = start
                    let moved = -Double(drag.translation.width / pointsPerStep) * step
                    value = min(max(((start + moved) / step).rounded() * step, range.lowerBound), range.upperBound)
                }
                .onEnded { _ in
                    dragStart = nil
                    ignoringDrag = false
                }
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
