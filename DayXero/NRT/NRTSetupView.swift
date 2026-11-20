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
        /// Patches (CLIN-03): off at bedtime (16 hours) instead of on overnight (24).
        var offAtBedtime = false
        var id: NRTType { type }
    }

    enum Stage: Hashable {
        case intro, products, schedule(Int), plan(Int), reminders
    }

    @Environment(\.modelContext) private var context
    @Environment(Entitlement.self) private var entitlement: Entitlement?
    @State private var showPaywall = false
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
    @State private var finishing = false
    @State private var shake = 0
    @Environment(\.openURL) private var openURL

    struct EditingStep: Identifiable {
        let draft: Int
        let index: Int
        var id: String { "\(draft)-\(index)" }
    }

    init(profile: UserProfile, onDone: @escaping () -> Void) {
        self.profile = profile
        self.onDone = onDone
        // Starts on Day Xero, or today if that's passed.
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
            case "reminders":
                var withPlan = patch
                withPlan.presetID = "us-patch-10"
                withPlan.steps = NRTLabels.preset(id: "us-patch-10")?.steps ?? []
                _drafts = State(initialValue: [withPlan])
                _stage = State(initialValue: .reminders)
            default: break
            }
        }
        #endif
    }

    private let ground = DX.Ground.reading

    var body: some View {
        VStack(spacing: 0) {
            nav
            Group {
                switch stage {
                case .intro: intro
                case .products: products
                case let .schedule(i): schedule(i)
                case let .plan(i): plan(i)
                case .reminders: reminders
                }
            }
            .frame(maxHeight: .infinity)
        }
        .dxReadableColumn()
        .dxGround(ground)
        .toggleStyle(.dx)
        .sensoryFeedback(DX.Haptic.commit, trigger: saved)
        .sensoryFeedback(.success, trigger: finishing)
        .fullProgramPaywall(isPresented: $showPaywall, profile: profile)
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

    /// v5: the leading control, then the step segments (one per screen after the intro).
    private var nav: some View {
        HStack(spacing: 12) {
            DXIconButton(stage == .intro ? .close : .back, label: stage == .intro ? "Close" : "Back") { back() }
            if let current = stepIndex {
                // Kit `.steps` here: every segment up to this screen is on, none half-way.
                HStack(spacing: 5) {
                    ForEach(0..<stepCount, id: \.self) { i in
                        Capsule().fill(i <= current ? ground.ink : ground.track).frame(height: 6)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: current)
                .accessibilityElement()
                .accessibilityLabel(Text(progressLabel ?? ""))
                .accessibilityValue(Text("Step \(current + 1) of \(stepCount)"))
            } else {
                Spacer()
            }
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .padding(.top, 8)
    }

    /// One segment for what you use, two per product (schedule and plan) and one for reminders.
    private var stepCount: Int { 2 + 2 * max(chosen.count, 1) }

    private var stepIndex: Int? {
        switch stage {
        case .intro: nil
        case .products: 0
        case let .schedule(i): 1 + 2 * i
        case let .plan(i): 2 + 2 * i
        case .reminders: stepCount - 1
        }
    }

    // MARK: Stages

    /// The NRT scheduler is part of the full program (MON-01). Every way in lands here, so the intro is the one lock;
    /// the facts on it stay free, and plans already made keep their reminders.
    private var schedulerUnlocked: Bool {
        FullProgram.has(.nrtScheduler, isPro: entitlement?.isPro ?? Entitlement.isProNow)
    }

    /// 047: why NRT helps, the evidence as two bars, and what works best.
    private var intro: some View {
        let g = ground
        return page(button: schedulerUnlocked ? "Set up my NRT" : "Unlock the full program",
                    action: { if schedulerUnlocked { stage = .products } else { showPaywall = true } }) {
            Text("Why nicotine replacement helps").dxType(.large).foregroundStyle(g.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .dxArrive(0)
            Text("Nicotine replacement therapy (NRT) eases cravings while you unlearn the habit.")
                .dxType(.body).foregroundStyle(g.muted)
                .padding(.top, 10)
                .dxArrive(1)
            if !schedulerUnlocked {
                HStack(spacing: 6) { DXIcon(.lock, size: 16); Text("The 12-week NRT schedule comes with the full program.") }
                    .dxType(.footnote).foregroundStyle(g.ink)
                    .padding(.top, 12)
            }
            if PregnancyAnswer.stored == .yes {
                // S27.6: answered "Yes" to pregnant or breastfeeding in onboarding.
                HStack(alignment: .top, spacing: 10) {
                    DXIcon(.heart, size: 20).foregroundStyle(g.mark)
                    Text(verbatim: PregnancyAnswer.caution).dxType(.footnote).foregroundStyle(g.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .dxCard(flat: true, tight: true)
                .accessibilityElement(children: .combine)
                .padding(.top, 16)
            }
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    CountingText(60, from: 50, prefix: String(localized: "50 to "), suffix: "%")
                        .dxFace(.display, 46, weight: 800, tracking: -1.6)
                        .foregroundStyle(g.ink)
                        .accessibilityLabel(Text("50 to 60%"))
                    Text("more likely to quit than going without.").dxFace(.body, 17, weight: 500).foregroundStyle(g.ink)
                    NRTEvidenceBars()
                    SourceLink(source: HealthSources.nrtCochrane2018)
                }
                .padding(.top, 4)
                .dxCard()
                .dxArrive(2)
                // S27.6: combination NRT is the best-evidenced option (Cochrane 2023, RR 1.27, high certainty).
                HStack(spacing: 16) {
                    XeroView(mood: .hello, stage: 0, points: 92)
                        .dxBob()
                        .frame(width: 112, height: 112)
                        .background(Color(light: 0xFFEBDB, dark: 0x212A41), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .dxSettle(delay: 0.6)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("What works best").dxType(.footnote).foregroundStyle(g.muted)
                        Text("A patch plus a faster form beats either alone.")
                            .dxFace(.display, 17, weight: 700).foregroundStyle(g.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        SourceLink(source: HealthSources.nrtCombinationCochrane2023)
                    }
                }
                .padding(.vertical, -4)
                .padding(.leading, -4)
                .dxCard()
                .dxArrive(3)
                Text("Stop-smoking medicines such as varenicline or cytisine also work. Ask a pharmacist or doctor if they suit you.")
                    .dxType(.footnote).foregroundStyle(g.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
                    .dxArrive(4)
            }
            .padding(.top, 20)
        } secondary: {
            HStack(spacing: 6) {
                Text("Not using NRT yet?").foregroundStyle(g.muted)
                Button {
                    if let url = URL(string: "https://maps.apple.com/?q=pharmacy") { openURL(url) }
                } label: {
                    Text("Find a pharmacist").dxRun(15, weight: 700).foregroundStyle(g.ink)
                        .underline(color: g.mark)
                }
                .buttonStyle(.plain)
            }
            .dxFace(.body, 15, weight: 500)
            .frame(minHeight: 40)
            .dxArrive(6)
        }
    }

    /// 048: what you use, up to two, with Xero's how-to for the latest pick.
    private var products: some View {
        let g = ground
        return page(button: "Next: your schedule", enabled: !chosen.isEmpty, reason: "Pick what you use to go on.", action: startSchedules) {
            Text("What are you using?").dxType(.title).foregroundStyle(g.ink)
                .accessibilityAddTraits(.isHeader)
                .dxArrive(0)
            (Text("Pick up to two. ") + Text("\(chosen.count) of 2 picked").dxRun(15, weight: 600).foregroundStyle(g.ink))
                .dxType(.footnote).foregroundStyle(g.muted)
                .modifier(Shake(trigger: shake))
                .padding(.top, 8)
                .dxArrive(1)
            VStack(spacing: 10) {
                ForEach(Array(NRTType.allCases.enumerated()), id: \.element) { i, type in
                    let on = chosen.contains(type)
                    DXOptionRow(Text(type.title), detail: Text(detail(type)), isOn: on, action: { toggle(type) }) {
                        NRTGlyphTile(glyph: NRTGlyph(type), selected: on)
                    }
                    .dxArrive(2 + i)
                }
            }
            .padding(.top, 22)
            HStack(spacing: 10) {
                XeroView(mood: .hello, stage: 0, points: 56)
                    .dxBob()
                    .frame(width: 64, height: 64)
                    .accessibilityHidden(true)
                tip
                    .dxType(.footnote).foregroundStyle(g.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.25), value: chosen.last)
            }
            .padding(.leading, 8).padding(.trailing, 16).padding(.vertical, 10)
            .background(Color(light: 0xF1EBE2, dark: 0x212A41), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.top, 16)
            .dxArrive(7)
        }
    }

    /// Xero's how-to for the product picked last, or the combination tip before anything is picked.
    private var tip: Text {
        let bold = { (s: LocalizedStringKey) in Text(s).dxRun(15, weight: 700).foregroundStyle(ground.ink) }
        switch chosen.last {
        case .patch: return bold("Patch:") + Text(" put a new patch on a clean, hairless spot each morning.")
        case .gum: return bold("Gum:") + Text(" chew slowly until it tingles, then park it between your cheek and gum.")
        case .lozenge: return bold("Lozenge:") + Text(" let it dissolve slowly. Don't chew or swallow it.")
        case .inhaler: return bold("Inhaler:") + Text(" puff little and often, like sipping a drink.")
        case nil: return Text("A patch plus a faster form works best.")
        }
    }

    /// 049: the schedules printed on packs in your country, each with its step-down shape.
    private func schedule(_ i: Int) -> some View {
        let g = ground
        let draft = drafts[i]
        let presets = NRTLabels.presets(for: draft.type, country: country)
        return page(button: "Use this schedule", enabled: draft.presetID != nil || !draft.steps.isEmpty,
                    reason: "Tick the schedule that's on your pack.", action: { confirmSchedule(i) }) {
            Text(draft.type == .patch ? "Which schedule is on your pack?" : "What does your pack say?")
                .dxType(.title).foregroundStyle(g.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .dxArrive(0)
            HStack(spacing: 6) {
                Text("Labels differ by country. Yours:").dxType(.footnote).foregroundStyle(g.muted)
                countryPill(for: i)
            }
            .padding(.top, 8)
            .dxArrive(1)
            if draft.type == .gum || draft.type == .lozenge {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Strength on your pack").dxType(.footnote).foregroundStyle(g.muted)
                    HStack(spacing: 8) {
                        ForEach([2.0, 4.0], id: \.self) { mg in
                            DXChip(verbatim: NRTReminderPlan.strength(mg), isOn: drafts[i].strength == mg) { drafts[i].strength = mg }
                        }
                    }
                }
                .padding(.top, 16)
                .dxArrive(2)
            }
            VStack(spacing: 12) {
                ForEach(Array(presets.enumerated()), id: \.element.id) { n, preset in
                    scheduleRow(Text(preset.title), detail: presetDetail(preset), shape: StairGlyph.shape(for: preset.steps),
                                selected: draft.presetID == preset.id) { choose(preset, for: i) }
                        .dxArrive(3 + n)
                }
                scheduleRow(Text("Something else"), detail: Text("Enter your own steps"), shape: [],
                            selected: draft.presetID == nil && !draft.steps.isEmpty) {
                    drafts[i].presetID = nil
                    drafts[i].steps = [PlanStep(strengthMg: NRTLabels.strengths(for: draft.type).first ?? 0, weeks: 4)]
                }
                .dxArrive(3 + presets.count)
            }
            .padding(.top, 24)
            HStack(spacing: 10) {
                DXIcon(.note, size: 20)
                Text("The steps are listed on the side of the box.")
            }
            .dxType(.footnote).foregroundStyle(g.muted)
            .padding(.horizontal, 4)
            .padding(.top, 20)
            .dxArrive(8)
            if let preset = presets.first(where: { $0.id == draft.presetID }) {
                VStack(alignment: .leading, spacing: 2) {
                    if let note = preset.labelNote {
                        Text(note).dxType(.caption).foregroundStyle(g.muted).fixedSize(horizontal: false, vertical: true)
                    }
                    SourceLink(source: preset.source)
                }
                .padding(.horizontal, 4)
                .padding(.top, 8)
            }
        }
    }

    private func countryPill(for i: Int) -> some View {
        Menu {
            ForEach(LabelCountry.allCases, id: \.self) { c in
                Button { switchCountry(c, for: i) } label: {
                    if country == c { Label { Text(c.title) } icon: { Image(systemName: "checkmark") } } else { Text(c.title) }
                }
            }
            Button { switchCountry(nil, for: i) } label: {
                if country == nil { Label("Elsewhere", systemImage: "checkmark") } else { Text("Elsewhere") }
            }
        } label: {
            HStack(spacing: 4) {
                (country.map { Text($0.title) } ?? Text("Elsewhere")).dxFace(.body, 14, weight: 700)
                DXIcon(.down, size: 14, weight: 2.4)
            }
            .foregroundStyle(ground.ink)
            .padding(.leading, 11).padding(.trailing, 8)
            .frame(height: 28)
            .background(ground.card, in: Capsule())
            .overlay(Capsule().strokeBorder(ground.line, lineWidth: 1))
            .frame(minHeight: DX.Layout.touchTarget)
            .contentShape(Rectangle())
        }
        .accessibilityLabel(Text("Country: \(country.map { String(localized: $0.title) } ?? String(localized: "Elsewhere")). Change"))
    }

    /// The weeks in bold, then the strengths (or, for gum and lozenges, that the pieces get fewer).
    private func presetDetail(_ preset: NRTPreset) -> Text {
        let weeks = Self.list(preset.steps.map { "\($0.weeks)" })
        let first = preset.steps.count == 1 ? Text("\(weeks) weeks") : Text("\(weeks) weeks")
        let mg = preset.steps.allSatisfy { $0.strengthMg > 0 }
            ? Text(verbatim: Self.list(preset.steps.map { $0.strengthMg.formatted(.number.precision(.fractionLength(0...1))) }) + " mg")
            : Text("Fewer pieces each step")
        return first.dxRun(14, weight: 700).foregroundStyle(ground.ink) + Text(verbatim: "\n") + mg
    }

    /// "6, 2 and 2".
    static func list(_ items: [String]) -> String {
        guard items.count > 1 else { return items.first ?? "" }
        return String(localized: "\(items.dropLast().joined(separator: ", ")) and \(items.last ?? "")")
    }

    private func scheduleRow(_ title: Text, detail: Text, shape: [(weeks: Int, height: Double)], selected: Bool,
                             action: @escaping () -> Void) -> some View {
        let g = ground
        let rect = RoundedRectangle(cornerRadius: DX.Layout.optionRadius, style: .continuous)
        return Button(action: action) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    title.dxFace(.display, 17, weight: 700).foregroundStyle(g.ink)
                    detail.dxFace(.body, 14, weight: 500).foregroundStyle(g.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                StairGlyph(steps: shape, selected: selected).padding(.trailing, 6)
                DXRadio(isOn: selected, ground: g)
            }
            .padding(.leading, 16).padding(.trailing, 14).padding(.vertical, 12)
            .frame(minHeight: 90)
            .background(selected ? g.selTint : g.card, in: rect)
            .overlay { rect.strokeBorder(selected ? g.selEdge : g.line, lineWidth: selected ? 2 : 1) }
            .contentShape(rect)
            .animation(DX.Move.arrive.speed(2.4), value: selected)
        }
        .buttonStyle(.dxPress)
        .sensoryFeedback(DX.Haptic.select, trigger: selected)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    /// 050: the plan as a step chart, compact date rows to edit, and (patches) what to do at night.
    private func plan(_ i: Int) -> some View {
        let g = ground
        let draft = drafts[i]
        let schedule = StepSchedule(startDate: startDate, steps: draft.steps, clock: clock)
        let weeks = draft.steps.reduce(0) { $0 + $1.weeks }
        return page(button: i + 1 < drafts.count ? "Next product" : "Use this plan", enabled: !draft.steps.isEmpty, action: {
            stage = i + 1 < drafts.count ? .schedule(i + 1) : .reminders
        }) {
            Text("Your \(String(localized: draft.type.title).lowercased()) plan").dxType(.title).foregroundStyle(g.ink)
                .accessibilityAddTraits(.isHeader)
                .dxArrive(0)
            Text("From your pack's label. Tap a step to change it.").dxType(.footnote).foregroundStyle(g.muted)
                .padding(.top, 8)
                .dxArrive(1)
            if !draft.steps.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("^[\(weeks) week](inflect: true), \(Self.spelled(draft.steps.count)) \(draft.steps.count == 1 ? String(localized: "step") : String(localized: "steps"))")
                        .dxFace(.display, 19, weight: 700).foregroundStyle(g.ink)
                    // Tapping the date opens the picker to move the start.
                    Text("From \(startDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))")
                        .dxType(.footnote).foregroundStyle(g.muted)
                        .underline(color: g.line)
                        .overlay {
                            DatePicker("Starting", selection: $startDate, displayedComponents: .date)
                                .labelsHidden()
                                .colorMultiply(.clear)
                        }
                    NRTStepChart(steps: draft.steps).id(draft.steps.map(\.weeks) + draft.steps.map { Int($0.strengthMg * 10) })
                }
                .padding(.top, 0)
                .padding(.bottom, -4)
                .dxCard()
                .padding(.top, 16)
                .dxArrive(2)
            }
            DXList {
                ForEach(schedule.spans, id: \.index) { span in
                    Button { editing = EditingStep(draft: i, index: span.index) } label: {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(NRTPalette.tint(span.index))
                                .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous).strokeBorder(NRTPalette.edge, lineWidth: 1.5))
                                .frame(width: 12, height: 12)
                            Text(verbatim: StepRow.title(span))
                                .dxFace(.display, 16, weight: 700).foregroundStyle(g.ink)
                                .lineLimit(1).minimumScaleFactor(0.7)
                                .frame(minWidth: 48, alignment: .leading)
                                .fixedSize(horizontal: span.step.note == nil, vertical: false)
                            Text(verbatim: StepRow.dates(span, separator: String(localized: "to")))
                                .dxFace(.body, 15, weight: 500).foregroundStyle(g.muted)
                                .lineLimit(1).minimumScaleFactor(0.7)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            DXIcon(.chev, size: 18).foregroundStyle(g.muted).padding(.leading, -4)
                        }
                        .padding(.horizontal, 16)
                        .frame(minHeight: 48)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityHint(Text("Change this step"))
                    .dxSettle(3 + span.index)
                }
            }
            .padding(.top, 14)
            Button {
                let last = drafts[i].steps.last
                drafts[i].steps.append(PlanStep(strengthMg: last?.strengthMg ?? 0, weeks: 2))
            } label: {
                HStack(spacing: 6) { DXIcon(.plus, size: 16, weight: 2.4); Text("Add a step") }
            }
            .buttonStyle(.dx(.ghostSmall, on: .reading))
            .padding(.top, 8)
            if draft.type == .patch {
                PatchNightChoice(offAtBedtime: $drafts[i].offAtBedtime).padding(.top, 20).dxArrive(6)
            }
            if draft.type == .gum {
                ChewAndParkGuide().padding(.top, 20).dxArrive(6)
            }
        }
    }

    /// "three".
    static func spelled(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = n <= 10 ? .spellOut : .decimal
        return f.string(from: n as NSNumber) ?? "\(n)"
    }

    /// 051: the reminders, each with its time, a preview of the notification, and the flow's one dosing note.
    private var reminders: some View {
        let g = ground
        let first = drafts.compactMap { StepSchedule(startDate: startDate, steps: $0.steps, clock: clock).end }.max()
        let range = first.map { end in
            let last = Calendar.current.date(byAdding: .day, value: -1, to: end) ?? end
            let f = Date.FormatStyle.dateTime.month(.abbreviated).day()
            return "\(startDate.formatted(f)) to \(last.formatted(f))"
        } ?? ""
        return page(button: "Done", done: finishing, action: finish) {
            Text("Reminders that help").dxType(.title).foregroundStyle(g.ink)
                .accessibilityAddTraits(.isHeader)
                .dxArrive(0)
            Text(verbatim: reminderLead(range: range)).dxType(.footnote).foregroundStyle(g.muted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
                .dxArrive(1)
            VStack(spacing: 16) {
                reminderCard(glyph: NRTGlyph(chosen.contains(.patch) ? NRTGlyph.Kind.patch : (chosen.first.map { NRTGlyph($0).kind } ?? .patch)),
                             title: chosen.contains(.patch) ? "Fresh patch" : "Daily reminder", detail: "Every day", isOn: $dailyOn) {
                    timeRow { timePill($dailyTime) }
                }
                .dxArrive(3)
                reminderCard(glyph: NRTGlyph(.steps), title: "Step-down days", detail: "Evening before each step", isOn: $stepRemindersOn) {
                    timeRow { timeText(hour: NRTReminderPlan.eveningHour) }
                }
                .dxArrive(4)
                if chosen.contains(.gum) || chosen.contains(.lozenge) {
                    reminderCard(glyph: NRTGlyph(chosen.contains(.gum) ? NRTGlyph.Kind.gum : .lozenge), title: "Time for a piece",
                                 detail: "8am to 10pm, as often as your label says",
                                 isOn: Binding(get: { pieceHours != nil }, set: { pieceHours = $0 ? 2 : nil })) {
                        if let hours = pieceHours {
                            Stepper(value: Binding(get: { hours }, set: { pieceHours = $0 }), in: 1...8) {
                                Text("Every ^[\(hours) hour](inflect: true)").dxType(.footnote).foregroundStyle(g.muted)
                            }
                            .frame(minHeight: 60)
                        }
                    }
                    .dxArrive(5)
                }
            }
            .padding(.top, 28)
            if let preview = notificationPreview {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What you'll see").dxType(.footnote).foregroundStyle(g.muted)
                    HStack(spacing: 12) {
                        XeroView(mood: .hello, stage: 0, points: 34, animate: false)
                            .frame(width: 40, height: 40)
                            .background(Color(hex: 0xFFC38A))
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                            .dxBump(finishing)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(verbatim: "DayXero").foregroundStyle(g.ink)
                                Spacer()
                                Text(verbatim: preview.time).foregroundStyle(g.muted)
                            }
                            .dxType(.caption)
                            Text(verbatim: preview.title).dxRun(15, weight: 700)
                                .dxType(.footnote).foregroundStyle(g.ink)
                            Text(verbatim: preview.body)
                                .dxType(.footnote).foregroundStyle(g.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, 14).padding(.vertical, 15)
                    .background(g.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(g.line, lineWidth: 1))
                    .shadow(color: Color(light: (0x1E1A3A, 0.10), dark: (0x000000, 0.35)), radius: 12, y: 8)
                    .accessibilityElement(children: .combine)
                }
                .padding(.top, 34)
                .dxArrive(5)
            }
            HStack(spacing: 8) {
                DXIcon(.shield, size: 16)
                Text("Dosing comes from your pack's label, not DayXero.").fixedSize(horizontal: false, vertical: true)
            }
            .dxType(.caption).foregroundStyle(g.muted)
            .padding(.top, 20)
            .dxArrive(6)
        }
    }

    private func reminderLead(range: String) -> String {
        let weeks = drafts.map { $0.steps.reduce(0) { $0 + $1.weeks } }.max() ?? 0
        if drafts.count == 1, let type = drafts.first?.type {
            return String(localized: "For your \(weeks)-week \(String(localized: type.title).lowercased()) plan, \(range).")
        }
        return String(localized: "For your NRT plans, \(range).")
    }

    private var notificationPreview: (title: String, body: String, time: String)? {
        let time = { (d: Date) in d.formatted(.dateTime.hour().minute()) }
        if dailyOn {
            if chosen.contains(.patch) {
                return (String(localized: "Fresh patch time"), String(localized: "Swap today's patch. Follow the label on your pack."), time(dailyTime))
            }
            let type = chosen.first.map { String(localized: $0.title).lowercased() } ?? ""
            return (String(localized: "Your \(type) plan"), String(localized: "Keep some with you today. Follow the label on your pack."), time(dailyTime))
        }
        if stepRemindersOn, let at = Calendar.current.date(bySettingHour: NRTReminderPlan.eveningHour, minute: 0, second: 0, of: .now) {
            return (String(localized: "Tomorrow: your next step"), String(localized: "Check your pack's label."), time(at))
        }
        return nil
    }

    private func reminderCard(glyph: NRTGlyph, title: LocalizedStringKey, detail: LocalizedStringKey, isOn: Binding<Bool>,
                              @ViewBuilder sub: () -> some View) -> some View {
        let g = ground
        return VStack(spacing: 0) {
            Toggle(isOn: isOn.animation(.easeInOut(duration: 0.25))) {
                HStack(spacing: 14) {
                    NRTGlyphTile(glyph: NRTGlyph(glyph.kind, size: 28), tile: 46)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).dxFace(.display, 17, weight: 700).foregroundStyle(g.ink)
                        Text(detail).dxType(.footnote).foregroundStyle(g.muted)
                    }
                }
            }
            .frame(minHeight: 74)
            if isOn.wrappedValue {
                Rectangle().fill(g.line).frame(height: 1)
                sub()
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 6)
        .background(g.card, in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous).strokeBorder(g.line, lineWidth: 1))
    }

    private func timeRow(@ViewBuilder trailing: () -> some View) -> some View {
        HStack {
            Text("Time").dxType(.footnote).foregroundStyle(ground.muted)
            Spacer()
            trailing()
        }
        .frame(minHeight: 60)
    }

    /// The kit's time pill; the system picker sits on top of it, invisible, so a tap opens the wheel.
    private func timePill(_ time: Binding<Date>) -> some View {
        timeLabel(time.wrappedValue.formatted(.dateTime.hour().minute()))
            .overlay {
                DatePicker("Time", selection: time, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .colorMultiply(.clear)
            }
    }

    private func timeText(hour: Int) -> some View {
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now
        return timeLabel(date.formatted(.dateTime.hour().minute()))
    }

    private func timeLabel(_ text: String) -> some View {
        Text(verbatim: text)
            .dxFace(.display, 16, weight: 700)
            .monospacedDigit()
            .foregroundStyle(ground.ink)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(ground.card2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: Pieces

    /// A screen: the scrolling content and the dock. `reason` says why the button is off (S27.20); it shows under
    /// the button while `enabled` is false. `done` turns the button into its done state (a green check, same ink).
    private func page(button: LocalizedStringKey, enabled: Bool = true, reason: LocalizedStringKey? = nil, done: Bool = false,
                      action: @escaping () -> Void,
                      @ViewBuilder content: () -> some View, @ViewBuilder secondary: () -> some View = { EmptyView() }) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) { content() }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DX.Layout.gutter)
                    .padding(.top, 14)
                    .padding(.bottom, DX.Space.m)
            }
            .scrollBounceBehavior(.basedOnSize)
            DXActionDock {
                Group {
                    if let reason {
                        primary(button, done: done, action: action).disabled(!enabled)
                            .dxDisabledReason(reason, shown: !enabled)
                    } else {
                        primary(button, done: done, action: action).disabled(!enabled)
                    }
                }
                .dxArrive(5)
                secondary()
            }
            .padding(.top, -36)
        }
    }

    private func primary(_ title: LocalizedStringKey, done: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if done {
                    DXIcon(.check, size: 18, weight: 2.6)
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(DX.Fill.done, in: Circle())
                        .transition(.scale.combined(with: .opacity))
                }
                Text(title)
            }
            .animation(.timingCurve(0.3, 1.4, 0.5, 1, duration: 0.4), value: done)
        }
        .buttonStyle(.dx(.primary, on: .reading))
    }

    private var progressLabel: String? {
        switch stage {
        case .intro: nil
        case .products: String(localized: "What you use")
        case let .schedule(i), let .plan(i):
            drafts.count > 1 ? String(localized: "\(String(localized: drafts[i].type.title)), \(i + 1) of \(drafts.count)") : String(localized: "Your plan")
        case .reminders: String(localized: "Reminders")
        }
    }

    private var clock: DayClock { DayClock(boundaryHour: profile.dayBoundaryHour) }

    private func detail(_ type: NRTType) -> LocalizedStringResource {
        switch type {
        case .patch: "Worn all day, changed daily"
        case .gum: "Chew, then park it"
        case .lozenge: "Dissolves slowly in your mouth"
        case .inhaler: "Puff on a cartridge"
        }
    }

    /// Up to two; a third tap shakes the count instead.
    private func toggle(_ type: NRTType) {
        if let i = chosen.firstIndex(of: type) { chosen.remove(at: i) }
        else if chosen.count < 2 { chosen.append(type) }
        else { shake += 1 }
    }

    /// Done shows its check first, then saves.
    private func finish() {
        guard !finishing else { return }
        finishing = true
        Task {
            try? await Task.sleep(for: .milliseconds(650))
            save()
        }
    }

    // MARK: Flow

    private func startSchedules() {
        drafts = chosen.map { type in drafts.first { $0.type == type } ?? Draft(type: type) }
        stage = .schedule(0)
    }

    /// Picking a label copies its steps straight away, so the plan always shows the card that's ticked.
    private func choose(_ preset: NRTPreset, for i: Int) {
        drafts[i].presetID = preset.id
        drafts[i].steps = steps(of: preset, strength: drafts[i].strength)
        // A 16-hour pack is worn from morning to bedtime.
        if drafts[i].type == .patch { drafts[i].offAtBedtime = preset.id.contains("patch-16") }
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
            if draft.type == .patch { plan.offAtBedtime = draft.offAtBedtime }
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

    private var title: String { Self.title(span) }

    private var dates: String { Self.dates(span, separator: "–") }

    static func title(_ span: StepSchedule.Span) -> String {
        let mg = NRTReminderPlan.strength(span.step.strengthMg)
        if let note = span.step.note { return span.step.strengthMg > 0 ? "\(mg) · \(note)" : note }
        return mg
    }

    /// "Fri, Nov 6 to Thu, Dec 17": the last day is the day before the next step.
    static func dates(_ span: StepSchedule.Span, separator: String) -> String {
        let last = Calendar.current.date(byAdding: .day, value: -1, to: span.end) ?? span.end
        let format = Date.FormatStyle.dateTime.weekday(.abbreviated).day().month(.abbreviated)
        return "\(span.start.formatted(format)) \(separator) \(last.formatted(format))"
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
            Text("Edit step").dxType(.title).foregroundStyle(DX.Ground.reading.ink).padding(.top, DX.Space.l)
            Text("Strength").dxType(.footnote).foregroundStyle(DX.Ground.reading.muted)
            DXFlowLayout {
                ForEach(strengths, id: \.self) { mg in
                    DXChip(verbatim: NRTReminderPlan.strength(mg), isOn: step.strengthMg == mg) { step.strengthMg = mg }
                }
            }
            Stepper(value: $step.weeks, in: 1...24) {
                Text("^[\(step.weeks) week](inflect: true)").dxFace(.display, 17, weight: 700)
            }
            .padding(.top, DX.Space.xs)
            Text("Match the steps on your pack's label.").dxType(.caption).foregroundStyle(DX.Ground.reading.muted)
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
        .padding(.horizontal, DX.Layout.gutter)
        .dxReadableColumn()
        .padding(.bottom, DX.Space.xs)
        .dxGround(.reading)
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
    @Environment(\.dxGround) private var ground

    var body: some View {
        Link(destination: source.url) {
            Text(source.label).dxType(.caption).underline().foregroundStyle(ground.resolved.muted)
                .multilineTextAlignment(.leading)
        }
        // A 44 pt target, as every tappable thing has (S27.20).
        .frame(minHeight: DX.Layout.touchTarget, alignment: .leading)
        .contentShape(Rectangle())
    }
}

/// Patches at night (CLIN-03): on overnight (24 hours) or off at bedtime (16). Picking off at bedtime adds a
/// "Patch off for the night" reminder 16 hours after the fresh-patch time. v5 (050): a label, one helper line, two chips.
struct PatchNightChoice: View {
    @Binding var offAtBedtime: Bool
    @Environment(\.dxGround) private var ground

    var body: some View {
        let g = ground.resolved
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("At night").dxFace(.display, 17, weight: 700).foregroundStyle(g.ink)
                    .accessibilityAddTraits(.isHeader)
                Text("Some people get vivid dreams with a patch overnight.")
                    .dxFace(.body, 13.5, weight: 500).foregroundStyle(g.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 8) {
                DXChip("Keep it on", isOn: !offAtBedtime) { offAtBedtime = false }
                    .accessibilityHint(Text("Worn for 24 hours"))
                DXChip("Take it off at bedtime", isOn: offAtBedtime) { offAtBedtime = true }
                    .accessibilityHint(Text("Worn for 16 hours"))
            }
        }
    }
}

/// "Chew and park" (CLIN-03): how nicotine gum is meant to be used, in four steps and one tip.
struct ChewAndParkGuide: View {
    @Environment(\.dxGround) private var ground

    var body: some View {
        let g = ground.resolved
        VStack(alignment: .leading, spacing: 14) {
            Text("How to use it: chew and park").dxFace(.display, 17, weight: 700).foregroundStyle(g.ink)
            ForEach(Array(NRTUseGuide.chewAndPark.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text(verbatim: "\(index + 1)")
                        .dxFace(.body, 13, weight: 700)
                        .foregroundStyle(g.selFg)
                        .frame(width: 26, height: 26)
                        .background(g.sel, in: Circle())
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(step.title).dxFace(.display, 16, weight: 700).foregroundStyle(g.ink)
                        Text(step.detail).dxType(.footnote).foregroundStyle(g.muted).fixedSize(horizontal: false, vertical: true)
                    }
                }
                .accessibilityElement(children: .combine)
            }
            HStack(alignment: .top, spacing: 10) {
                NRTGlyph(NRTGlyph.Kind.gum, size: 24)
                Text(NRTUseGuide.chewAndParkTip).dxType(.footnote).foregroundStyle(g.muted).fixedSize(horizontal: false, vertical: true)
            }
        }
        .dxCard()
    }
}

/// A third pick shakes the "1 of 2 picked" count instead of selecting.
struct Shake: ViewModifier {
    let trigger: Int
    private let motion = MotionPolicy()

    func body(content: Content) -> some View {
        content.phaseAnimator([0.0, -6, 6, -4, 4, 0], trigger: trigger) { view, x in
            view.offset(x: motion.reduce ? 0 : x)
        } animation: { _ in .linear(duration: 0.06) }
    }
}
