import DayXeroCore
import SwiftData
import SwiftUI

/// NRT setup (S9.1, S9.2, S9.4): what you use, the schedule printed on your pack, then reminders.
/// DayXero never chooses a dose. Label schedules are offered only as starting points to match against the pack.
struct NRTSetupView: View {
    let profile: UserProfile
    let onDone: () -> Void

    struct Draft: Identifiable, Equatable {
        let type: NRTType
        var presetID: String?
        /// Gum and lozenges: the strength on the pack; label steps change how often, not the strength.
        var strength: Double = 2
        var steps: [PlanStep] = []
        var id: NRTType { type }
    }

    enum Stage: Hashable {
        case intro, products, schedule(Int), plan(Int), reminders
    }

    @Environment(\.modelContext) private var context
    @State private var stage = Stage.intro
    @State private var chosen: [NRTType] = []
    @State private var drafts: [Draft] = []
    @State private var country: LabelCountry? = LabelCountry(region: Locale.current.region?.identifier)
    @State private var startDate: Date
    @State private var dailyOn = true
    @State private var dailyTime: Date
    @State private var stepRemindersOn = true
    @State private var pieceHours: Int?
    @State private var editing: EditingStep?
    @State private var saved = false

    struct EditingStep: Identifiable {
        let draft: Int
        let index: Int
        var id: String { "\(draft)-\(index)" }
    }

    init(profile: UserProfile, onDone: @escaping () -> Void) {
        self.profile = profile
        self.onDone = onDone
        // Starts on Quit Day, or today if that's passed.
        let quit = Calendar.current.startOfDay(for: profile.quitDay)
        _startDate = State(initialValue: max(quit, Calendar.current.startOfDay(for: .now)))
        _dailyTime = State(initialValue: Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: .now) ?? .now)
        #if DEBUG
        if let raw = UserDefaults.standard.string(forKey: "dx.nrtStage") {
            let patch = Draft(type: .patch, presetID: nil)
            _chosen = State(initialValue: [.patch])
            _drafts = State(initialValue: [patch])
            if LabelCountry(region: Locale.current.region?.identifier) == nil { _country = State(initialValue: .us) }
            switch raw {
            case "products": _stage = State(initialValue: .products)
            case "schedule": _stage = State(initialValue: .schedule(0))
            case "plan":
                var withPlan = patch
                withPlan.presetID = "us-patch-10"
                withPlan.steps = NRTLabels.preset(id: "us-patch-10")?.steps ?? []
                _drafts = State(initialValue: [withPlan])
                _country = State(initialValue: .us)
                _stage = State(initialValue: .plan(0))
            case "reminders": _stage = State(initialValue: .reminders)
            default: break
            }
        }
        #endif
    }

    var body: some View {
        NavigationStack {
            Group {
                switch stage {
                case .intro: intro
                case .products: products
                case let .schedule(i): schedule(i)
                case let .plan(i): plan(i)
                case .reminders: reminders
                }
            }
            .padding(.horizontal, DX.Space.m)
            .dxReadableColumn()
            .padding(.bottom, DX.Space.xs)
            .background(Read4.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { back() } label: { Image(systemName: stage == .intro ? "xmark" : "chevron.left") }
                        .accessibilityLabel(Text(stage == .intro ? "Close" : "Back"))
                }
                if let label = progressLabel {
                    ToolbarItem(placement: .principal) { Text(label).v4Text(.micro) }
                }
            }
        }
        .sensoryFeedback(DX.Haptic.commit, trigger: saved)
        .sheet(item: $editing) { item in
            // The step may be gone while the sheet closes after "Remove this step".
            if drafts.indices.contains(item.draft), drafts[item.draft].steps.indices.contains(item.index) {
                StepEditor(type: drafts[item.draft].type, initial: drafts[item.draft].steps[item.index],
                           onSave: { step in
                               if drafts[item.draft].steps.indices.contains(item.index) { drafts[item.draft].steps[item.index] = step }
                           },
                           onDelete: drafts[item.draft].steps.count > 1 ? {
                               editing = nil
                               drafts[item.draft].steps.remove(at: item.index)
                           } : nil)
                    .presentationDetents([.medium])
            }
        }
    }

    // MARK: Stages

    private var intro: some View {
        page(button: "Set up my NRT", action: { stage = .products }) {
            Text("Keep your NRT on track").v4Text(.title)
            Text("Tell us what's on your pack. We'll remind you to change patches and when each step down is due.").v4Text(.subtitle)
            V4Card {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Why it's worth it").v4Text(.micro)
                    Text("People who use NRT are 50–60% more likely to quit than people who don't.")
                        .dxFont(16, weight: 600, style: .body).foregroundStyle(Read4.ink)
                    SourceLink(source: HealthSources.nrtCochrane2018)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, DX.Space.s)
            LabelNotice()
        } secondary: {
            Button("Not using NRT yet? Ask a pharmacist", action: onDone).buttonStyle(.dx(.quiet, on: .reading))
        }
    }

    private var products: some View {
        page(button: "Next", enabled: !chosen.isEmpty, action: startSchedules) {
            Text("What are you using?").v4Text(.title)
            Text("Pick up to two, as your pharmacist or doctor suggested, or as on your pack.").v4Text(.subtitle)
            VStack(spacing: DX.Space.xs) {
                ForEach(NRTType.allCases, id: \.self) { type in
                    OnbOptionCard(type.title, detail: detail(type), systemImage: icon(type), isSelected: chosen.contains(type)) {
                        if let i = chosen.firstIndex(of: type) { chosen.remove(at: i) }
                        else if chosen.count < 2 { chosen.append(type) }
                    }
                }
            }
            .padding(.top, DX.Space.s)
            if chosen.count == 2 {
                Text("Using two together? Only if a pharmacist or doctor suggested it.").v4Text(.subtitle)
            }
        }
    }

    private func schedule(_ i: Int) -> some View {
        let draft = drafts[i]
        let presets = NRTLabels.presets(for: draft.type, country: country)
        return page(button: "Use this schedule", enabled: draft.presetID != nil || !draft.steps.isEmpty, action: { confirmSchedule(i) }) {
            Text(draft.type == .patch ? "Which schedule is on your pack?" : "What does your pack say?").v4Text(.title)
            Text("Labels differ by brand and country. Pick the one that matches, or enter your own.").v4Text(.subtitle)
            DXFlowLayout {
                ForEach(LabelCountry.allCases, id: \.self) { c in
                    V4ToggleChip(LocalizedStringKey(String(localized: c.title)), isOn: Binding(get: { country == c }, set: { if $0 { switchCountry(c, for: i) } }))
                }
                V4ToggleChip("Elsewhere", isOn: Binding(get: { country == nil }, set: { if $0 { switchCountry(nil, for: i) } }))
            }
            .padding(.top, DX.Space.xs)
            if draft.type == .gum || draft.type == .lozenge {
                Text("Strength on your pack").v4Text(.micro).padding(.top, DX.Space.s)
                HStack(spacing: DX.Space.xs) {
                    ForEach([2.0, 4.0], id: \.self) { mg in
                        V4ToggleChip(LocalizedStringKey(NRTReminderPlan.strength(mg)),
                               isOn: Binding(get: { drafts[i].strength == mg }, set: { if $0 { drafts[i].strength = mg } }))
                    }
                }
            }
            VStack(spacing: DX.Space.xs) {
                ForEach(presets) { preset in
                    presetCard(preset, selected: draft.presetID == preset.id) { choose(preset, for: i) }
                }
                presetCard(nil, selected: draft.presetID == nil && !draft.steps.isEmpty) {
                    drafts[i].presetID = nil
                    drafts[i].steps = [PlanStep(strengthMg: NRTLabels.strengths(for: draft.type).first ?? 0, weeks: 4)]
                }
            }
            .padding(.top, DX.Space.s)
            if let preset = presets.first(where: { $0.id == draft.presetID }) {
                if let note = preset.labelNote {
                    Text(note).v4Text(.subtitle)
                }
                SourceLink(source: preset.source)
            }
            LabelNotice()
        }
    }

    private func plan(_ i: Int) -> some View {
        let draft = drafts[i]
        let schedule = StepSchedule(startDate: startDate, steps: draft.steps, clock: clock)
        return page(button: i + 1 < drafts.count ? "Next product" : "Next: reminders", enabled: !draft.steps.isEmpty, action: {
            stage = i + 1 < drafts.count ? .schedule(i + 1) : .reminders
        }) {
            Text("Your \(String(localized: draft.type.title).lowercased()) plan").v4Text(.title)
            Text("From your pack's label. Tap a step to change it.").v4Text(.subtitle)
            DatePicker("Starting", selection: $startDate, displayedComponents: .date)
                .dxFont(14, weight: 400, style: .footnote)
                .padding(.top, DX.Space.xs)
            V4Card(padding: 14) {
                VStack(spacing: 0) {
                    ForEach(schedule.spans, id: \.index) { span in
                        Button { editing = EditingStep(draft: i, index: span.index) } label: {
                            StepRow(span: span, type: draft.type, highlighted: span.index == 0)
                        }
                        .buttonStyle(.plain)
                        if span.index < schedule.spans.count - 1 { Divider().overlay(Read4.hairline) }
                    }
                }
            }
            Button {
                let last = drafts[i].steps.last
                drafts[i].steps.append(PlanStep(strengthMg: last?.strengthMg ?? 0, weeks: 2))
            } label: { Label("Add a step", systemImage: "plus") }
                .buttonStyle(.dx(.quiet, on: .reading))
            LabelNotice()
        }
    }

    private var reminders: some View {
        page(button: "Done", action: save) {
            Text("Reminders").v4Text(.title)
            Text("So you don't have to remember.").v4Text(.subtitle)
            VStack(spacing: DX.Space.xs) {
                V4Card(padding: 14) {
                    VStack(alignment: .leading, spacing: DX.Space.xs) {
                        Toggle(isOn: $dailyOn) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(chosen.contains(.patch) ? "Fresh patch" : "Daily reminder").dxFont(16, weight: 600, style: .body)
                                Text("Every day").v4Text(.subtitle)
                            }
                        }
                        if dailyOn {
                            DatePicker("Time", selection: $dailyTime, displayedComponents: .hourAndMinute)
                                .dxFont(14, weight: 400, style: .footnote)
                        }
                    }
                }
                V4Card(padding: 14) {
                    Toggle(isOn: $stepRemindersOn) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Step-down days").dxFont(16, weight: 600, style: .body)
                            Text("The evening before each step").v4Text(.subtitle)
                        }
                    }
                }
                if chosen.contains(.gum) || chosen.contains(.lozenge) {
                    V4Card(padding: 14) {
                        VStack(alignment: .leading, spacing: DX.Space.xs) {
                            Toggle(isOn: Binding(get: { pieceHours != nil }, set: { pieceHours = $0 ? 2 : nil })) {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Time for a piece").dxFont(16, weight: 600, style: .body)
                                    Text("8am to 10pm, as often as your label says").v4Text(.subtitle)
                                }
                            }
                            if let hours = pieceHours {
                                Stepper("Every \(hours) hours", value: Binding(get: { hours }, set: { pieceHours = $0 }), in: 1...8)
                                    .dxFont(14, weight: 400, style: .footnote)
                            }
                        }
                    }
                }
            }
            .padding(.top, DX.Space.s)
            .tint(Read4.accent)
            LabelNotice()
        }
    }

    // MARK: Pieces

    private func page(button: LocalizedStringKey, enabled: Bool = true, action: @escaping () -> Void,
                      @ViewBuilder content: () -> some View, @ViewBuilder secondary: () -> some View = { EmptyView() }) -> some View {
        VStack(spacing: DX.Space.xs) {
            ScrollView {
                VStack(alignment: .leading, spacing: DX.Space.xs) { content() }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, DX.Space.s)
            }
            .scrollBounceBehavior(.basedOnSize)
            Button(button, action: action).buttonStyle(.dx(.primary, on: .reading)).disabled(!enabled)
            secondary()
        }
    }

    private func presetCard(_ preset: NRTPreset?, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: DX.Space.s) {
                VStack(alignment: .leading, spacing: 2) {
                    (preset.map { Text($0.title) } ?? Text("My pack says something else"))
                        .dxFont(16, weight: 600, style: .body).foregroundStyle(Read4.ink)
                    Text(preset.map(summary) ?? String(localized: "Enter each step yourself")).v4Text(.subtitle)
                }
                Spacer(minLength: DX.Space.xs)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(selected ? Read4.accent : Read4.faint)
            }
            .padding(14)
            .background(Read4.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(selected ? Read4.accent : Read4.hairline, lineWidth: selected ? 1.5 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func summary(_ preset: NRTPreset) -> String {
        preset.steps.map { step in
            let what = step.note ?? NRTReminderPlan.strength(step.strengthMg)
            return String(localized: "\(what) × \(step.weeks) wk")
        }
        .joined(separator: ", ")
    }

    private var progressLabel: LocalizedStringKey? {
        switch stage {
        case .intro: nil
        case .products: "What you use"
        case let .schedule(i), let .plan(i): drafts.count > 1 ? "\(String(localized: drafts[i].type.title)) · \(i + 1) of \(drafts.count)" : "Your plan"
        case .reminders: "Reminders"
        }
    }

    private var clock: DayClock { DayClock(boundaryHour: profile.dayBoundaryHour) }

    private func detail(_ type: NRTType) -> LocalizedStringResource {
        switch type {
        case .patch: "Worn all day, changed daily"
        case .gum: "Chew and park"
        case .lozenge: "Dissolves slowly"
        case .inhaler: "Puff on a cartridge"
        }
    }

    private func icon(_ type: NRTType) -> String { NRTCard.icon(type) }

    // MARK: Flow

    private func startSchedules() {
        drafts = chosen.map { type in drafts.first { $0.type == type } ?? Draft(type: type) }
        stage = .schedule(0)
    }

    /// Picking a label copies its steps straight away, so the plan always shows the card that's ticked.
    private func choose(_ preset: NRTPreset, for i: Int) {
        drafts[i].presetID = preset.id
        drafts[i].steps = steps(of: preset, strength: drafts[i].strength)
    }

    /// A new country clears any label from the old one; steps typed in by hand are kept.
    private func switchCountry(_ c: LabelCountry?, for i: Int) {
        country = c
        if drafts[i].presetID != nil {
            drafts[i].presetID = nil
            drafts[i].steps = []
        }
    }

    private func steps(of preset: NRTPreset, strength: Double) -> [PlanStep] {
        preset.steps.map { step in
            var copy = step
            if copy.strengthMg == 0 { copy.strengthMg = strength }
            return copy
        }
    }

    private func confirmSchedule(_ i: Int) {
        // Gum and lozenge strength can change after the label was picked.
        if let preset = NRTLabels.preset(id: drafts[i].presetID) {
            drafts[i].steps = steps(of: preset, strength: drafts[i].strength)
        }
        stage = .plan(i)
    }

    private func back() {
        switch stage {
        case .intro: onDone()
        case .products: stage = .intro
        case let .schedule(i): stage = i == 0 ? .products : .plan(i - 1)
        case let .plan(i): stage = .schedule(i)
        case .reminders: stage = .plan(max(drafts.count - 1, 0))
        }
    }

    private func save() {
        let minute = Calendar.current.component(.hour, from: dailyTime) * 60 + Calendar.current.component(.minute, from: dailyTime)
        for draft in drafts where !draft.steps.isEmpty {
            let plan = NRTPlan(type: draft.type, startDate: startDate, steps: draft.steps, presetID: draft.presetID,
                               dailyReminderMinute: dailyOn ? minute : nil,
                               pieceReminderHours: draft.type == .gum || draft.type == .lozenge ? pieceHours : nil,
                               stepReminders: stepRemindersOn)
            profile.nrtPlans.append(plan)
        }
        try? context.save()
        saved.toggle()
        Task {
            await NRTReminders.requestPermissionIfNeeded()
            NRTReminders.refresh(profile: profile)
        }
        onDone()
    }
}

/// One step: strength (or how often, for gum and lozenges), dates and length.
struct StepRow: View {
    let span: StepSchedule.Span
    let type: NRTType?
    var highlighted = false
    var done = false

    var body: some View {
        HStack(spacing: DX.Space.s) {
            Text(verbatim: "\(span.index + 1)")
                .dxFont(12, weight: 700, style: .caption1)
                .foregroundStyle(done ? DX.Fill.cream : highlighted ? Read4.onInk : Read4.muted)
                .frame(width: 32, height: 32)
                .background(done ? Read4.accent : highlighted ? Read4.ink : Read4.track, in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: title).dxFont(16, weight: 600, style: .body).foregroundStyle(Read4.ink)
                Text(verbatim: dates).v4Text(.subtitle)
            }
            Spacer(minLength: DX.Space.xs)
            Text("^[\(span.step.weeks) week](inflect: true)").v4Text(.subtitle)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var title: String {
        let mg = NRTReminderPlan.strength(span.step.strengthMg)
        if let note = span.step.note { return "\(mg) · \(note)" }
        return mg
    }

    private var dates: String {
        let last = Calendar.current.date(byAdding: .day, value: -1, to: span.end) ?? span.end
        let format = Date.FormatStyle.dateTime.weekday(.abbreviated).day().month(.abbreviated)
        return "\(span.start.formatted(format)) – \(last.formatted(format))"
    }
}

/// Edit one step: strength and weeks, as printed on the pack. Works on a copy, so removing a step can't
/// leave the sheet pointing at a step that's gone.
struct StepEditor: View {
    let type: NRTType?
    let onSave: (PlanStep) -> Void
    var onDelete: (() -> Void)?
    @State private var step: PlanStep
    @Environment(\.dismiss) private var dismiss

    init(type: NRTType?, initial: PlanStep, onSave: @escaping (PlanStep) -> Void, onDelete: (() -> Void)? = nil) {
        self.type = type
        self.onSave = onSave
        self.onDelete = onDelete
        _step = State(initialValue: initial)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DX.Space.s) {
            Text("Edit step").v4Text(.title).padding(.top, DX.Space.l)
            Text("Strength").v4Text(.micro)
            DXFlowLayout {
                ForEach(strengths, id: \.self) { mg in
                    V4ToggleChip(LocalizedStringKey(NRTReminderPlan.strength(mg)),
                           isOn: Binding(get: { step.strengthMg == mg }, set: { if $0 { step.strengthMg = mg } }))
                }
            }
            Stepper("^[\(step.weeks) week](inflect: true)", value: $step.weeks, in: 1...24)
                .dxFont(16, weight: 600, style: .body)
            LabelNotice()
            Spacer()
            Button("Done") {
                onSave(step)
                dismiss()
            }
            .buttonStyle(.dx(.primary, on: .reading))
            if let onDelete {
                Button("Remove this step", role: .destructive) {
                    dismiss()
                    onDelete()
                }
                .buttonStyle(.dx(.quiet, on: .reading))
            }
        }
        .padding(.horizontal, DX.Space.m)
        .dxReadableColumn()
        .padding(.bottom, DX.Space.xs)
        .background(Read4.background.ignoresSafeArea())
    }

    private var strengths: [Double] {
        if let type { return NRTLabels.strengths(for: type) }
        return [12, 9, 8, 6, 4, 3, 2, 1.5, 1]
    }
}

/// "Follow the label…" on every NRT screen (S9.2).
struct LabelNotice: View {
    var body: some View {
        HStack(alignment: .top, spacing: DX.Space.xs) {
            Image(systemName: "info.circle").foregroundStyle(Color(light: 0xB07A14, dark: 0xE5A93C))
            Text("Follow the label on your pack and ask a pharmacist or doctor. DayXero doesn't give dosing advice.")
                .dxFont(14, weight: 400, style: .footnote).foregroundStyle(Read4.ink)
        }
        .padding(DX.Space.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Read4.amber.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Read4.amber.opacity(0.35)))
        .padding(.top, DX.Space.s)
        .accessibilityElement(children: .combine)
    }
}

struct SourceLink: View {
    let source: HealthSource

    var body: some View {
        Link(destination: source.url) {
            Text(source.label).dxFont(14, weight: 400, style: .footnote).underline().foregroundStyle(Read4.accent)
        }
    }
}
