import DayXeroCore
import SwiftData
import SwiftUI

/// An NRT plan in Program and on Progress (S9.5, S19.6): current step, progress through it, and when the next step starts.
struct NRTCard: View {
    let plan: NRTPlan
    let clock: DayClock
    let now: Date
    /// Progress shows every step; Home shows only the current one.
    var showAllSteps = false
    @Environment(\.modelContext) private var context

    var body: some View {
        let schedule = StepSchedule(startDate: plan.startDate, steps: plan.steps, clock: clock)
        let current = schedule.current(at: now)
        V4Card(padding: 14) {
            VStack(alignment: .leading, spacing: DX.Space.xs) {
                HStack(spacing: DX.Space.s) {
                    Image(systemName: Self.icon(plan.type))
                        .font(.system(size: 17))
                        .foregroundStyle(Read4.accent)
                        .frame(width: 38, height: 38)
                        .background(Read4.accentSoft, in: Circle())
                    // The product's icon says it's NRT; the line says what this week is (S18.10).
                    VStack(alignment: .leading, spacing: 1) {
                        Text(verbatim: headline(schedule, current: current))
                            .dxFont(16, weight: 600, style: .body).foregroundStyle(Read4.ink)
                    }
                }
                if let current {
                    let stepDays = max(current.step.weeks * 7, 1)
                    let into = (clock.calendar.dateComponents([.day], from: current.start, to: clock.day(containing: now)).day ?? 0) + 1
                    V4ProgressBar(value: Double(into) / Double(stepDays))
                    HStack {
                        Text("Day \(into) of \(stepDays)")
                        Spacer()
                        if let next = schedule.next(after: current) {
                            Text("\(NRTReminderPlan.strength(next.step.strengthMg)) from \(next.start.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))")
                        } else {
                            Text("Last step")
                        }
                    }
                    .v4Text(.subtitle)
                    if let note = current.step.note { Text(verbatim: note).v4Text(.subtitle) }
                    if plan.type == .patch, !showAllSteps { patchCheck }
                } else if !schedule.hasStarted(at: now), let start = schedule.start {
                    Text("Starts \(start.formatted(.dateTime.weekday(.wide).day().month()))").v4Text(.subtitle)
                } else {
                    Text("Plan finished. Well done for seeing it through.").v4Text(.subtitle)
                }
                if showAllSteps {
                    VStack(spacing: 0) {
                        ForEach(schedule.spans, id: \.index) { span in
                            StepRow(span: span, type: plan.type, highlighted: span == current, done: clock.day(containing: now) >= span.end)
                        }
                    }
                    .padding(.top, DX.Space.xxs)
                    Text("Follow the label on your pack and ask a pharmacist or doctor.").v4Text(.subtitle)
                }
            }
        }
    }

    private func headline(_ schedule: StepSchedule, current: StepSchedule.Span?) -> String {
        let type = String(localized: plan.type.title).lowercased()
        guard let current else { return String(localized: "\(NRTReminderPlan.strength(plan.steps.first?.strengthMg ?? 0)) \(type)") }
        return String(localized: "\(NRTReminderPlan.strength(current.step.strengthMg)) \(type) · Step \(current.index + 1) of \(schedule.spans.count)")
    }

    /// "Patch on today": a one-tap check that also silences today's reminder.
    private var patchCheck: some View {
        let done = plan.lastCheckedDay.map { clock.day(containing: $0) == clock.day(containing: now) } ?? false
        return Button {
            plan.lastCheckedDay = done ? nil : now
            try? context.save()
            NRTReminders.refresh(profile: try? context.fetch(FetchDescriptor<UserProfile>()).first)
        } label: {
            Label(done ? "Patch on today" : "Mark patch on", systemImage: done ? "checkmark.circle.fill" : "circle")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.v4Secondary)
        .sensoryFeedback(DX.Haptic.select, trigger: done)
        .accessibilityAddTraits(done ? .isSelected : [])
    }

    static func icon(_ type: NRTType) -> String {
        switch type {
        case .patch: "bandage"
        case .gum: "square.grid.2x2"
        case .lozenge: "capsule"
        case .inhaler: "lungs"
        }
    }
}

/// The optional pouch taper on Home during prep (S9.3, S9.5).
struct TaperCard: View {
    let taper: PouchTaper
    let clock: DayClock
    let now: Date

    var body: some View {
        let schedule = StepSchedule(startDate: taper.startDate, steps: taper.steps, clock: clock)
        V4Card(padding: 14) {
            VStack(alignment: .leading, spacing: DX.Space.xs) {
                Text("Your pouch taper").v4Text(.cardHeading)
                if let current = schedule.current(at: now) {
                    Text("\(NRTReminderPlan.strength(current.step.strengthMg)) this week · step \(current.index + 1) of \(schedule.spans.count)")
                        .dxFont(16, weight: 600, style: .body).foregroundStyle(Read4.ink)
                    if let next = schedule.next(after: current) {
                        Text("\(NRTReminderPlan.strength(next.step.strengthMg)) from \(next.start.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))").v4Text(.subtitle)
                    } else {
                        Text("Then Quit Day").v4Text(.subtitle)
                    }
                } else if let start = schedule.start, !schedule.hasStarted(at: now) {
                    Text("Starts \(start.formatted(.dateTime.weekday(.wide).day().month()))")
                        .dxFont(16, weight: 600, style: .body).foregroundStyle(Read4.ink)
                } else {
                    Text("Taper done. Quit Day is next.").dxFont(16, weight: 600, style: .body)
                        .foregroundStyle(Read4.ink)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// A quiet invitation on Home for people who said they use NRT or would like to, or who use pouches in prep.
struct NRTInviteRow: View {
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DX.Space.s) {
                Image(systemName: systemImage).font(.system(size: 16, weight: .semibold)).foregroundStyle(DX.Ground.reading.ink)
                    .frame(width: 40, height: 40).background(DX.Fill.surface, in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).dxFont(16, weight: 700, style: .body).foregroundStyle(DX.Ground.reading.ink)
                    Text(detail).dxType(.footnote).foregroundStyle(DX.Ground.reading.muted)
                }
                Spacer(minLength: DX.Space.xs)
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(DX.Ground.reading.muted)
                    .accessibilityHidden(true)
            }
            .padding(14)
            .background(DX.Fill.raised, in: RoundedRectangle(cornerRadius: DX.Layout.smallCardRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

/// The optional pouch-strength taper (S9.3). It ends the day before Quit Day and only runs if it fits;
/// moving Quit Day to make room is the person's choice, never automatic.
struct TaperSetupView: View {
    let profile: UserProfile
    let onDone: () -> Void

    @Environment(\.modelContext) private var context
    @State private var steps: [PlanStep]
    @State private var editing: Int?
    @State private var remindersOn = true
    @State private var saved = false

    init(profile: UserProfile, onDone: @escaping () -> Void) {
        self.profile = profile
        self.onDone = onDone
        let start = profile.products.first { $0.product == .pouches }?.strengthMg ?? 6
        _steps = State(initialValue: profile.pouchTaper?.steps ?? PouchTaperPlan.suggestedSteps(from: start))
    }

    var body: some View {
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        let fits = PouchTaperPlan.fits(steps: steps, quitDay: profile.quitDay, now: .now, clock: clock)
        let start = PouchTaperPlan.startDate(steps: steps, quitDay: profile.quitDay, clock: clock)
        let schedule = StepSchedule(startDate: fits ? start : clock.day(containing: .now), steps: steps, clock: clock)
        VStack(spacing: DX.Space.xs) {
            HStack {
                Button(action: onDone) { Image(systemName: "xmark") }
                    .buttonStyle(.v4Icon).accessibilityLabel(Text("Close"))
                Spacer()
                Text("Optional").v4Text(.micro)
                Spacer()
                Color.clear.frame(width: 44, height: 1)
            }
            .padding(.top, DX.Space.s)
            ScrollView {
                VStack(alignment: .leading, spacing: DX.Space.xs) {
                    Text("Step down your pouches").v4Text(.title)
                    Text("Lower the strength before Quit Day, so stopping feels smaller.").v4Text(.subtitle)
                    StrengthBars(steps: steps)
                    V4Card(padding: 14) {
                        VStack(spacing: 0) {
                            ForEach(schedule.spans, id: \.index) { span in
                                Button { editing = span.index } label: { StepRow(span: span, type: nil, highlighted: span.index == 0) }
                                    .buttonStyle(.plain)
                            }
                        }
                    }
                    if fits {
                        Text("Ends the day before Quit Day, \(profile.quitDay.formatted(.dateTime.weekday(.wide).day().month())).").v4Text(.subtitle)
                    } else {
                        fitNotice(clock: clock)
                    }
                    Toggle("Remind me the evening before each step", isOn: $remindersOn)
                        .dxFont(14, weight: 400, style: .footnote)
                        .tint(Read4.accent)
                        .padding(.top, DX.Space.xs)
                    Text("Pouches aren't NRT, so there's no label for this. It's a plan you set; change any step to suit the strengths you can buy.")
                        .v4Text(.subtitle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            Button("Save my taper") { save(start: start) }.buttonStyle(.dx(.primary, on: .reading)).disabled(!fits)
                .dxDisabledReason("Shorten the steps or move Quit Day first.", shown: !fits)
            if profile.pouchTaper != nil {
                Button("Remove the taper", role: .destructive) {
                    profile.pouchTaper = nil
                    try? context.save()
                    NRTReminders.refresh(profile: profile)
                    onDone()
                }
                .buttonStyle(.dx(.quiet, on: .reading))
            }
        }
        .padding(.horizontal, DX.Space.m)
        .dxReadableColumn()
        .padding(.bottom, DX.Space.xs)
        .background(Read4.background.ignoresSafeArea())
        .sensoryFeedback(DX.Haptic.commit, trigger: saved)
        .sheet(item: Binding(get: { editing.map { EditIndex(id: $0) } }, set: { editing = $0?.id })) { item in
            if steps.indices.contains(item.id) {
                StepEditor(type: nil, initial: steps[item.id],
                           onSave: { step in if steps.indices.contains(item.id) { steps[item.id] = step } },
                           onDelete: steps.count > 1 ? { editing = nil; steps.remove(at: item.id) } : nil)
                    .presentationDetents([.medium])
            }
        }
    }

    private struct EditIndex: Identifiable { let id: Int }

    /// When the taper doesn't fit: shorten it, or move Quit Day yourself. Nothing moves on its own.
    private func fitNotice(clock: DayClock) -> some View {
        let newQuit = PouchTaperPlan.quitDayToFit(steps: steps, now: .now, clock: clock)
        return V4Card(padding: 14) {
            VStack(alignment: .leading, spacing: DX.Space.xs) {
                Text("This taper needs \(steps.reduce(0) { $0 + $1.weeks }) weeks, and Quit Day is sooner than that.")
                    .dxFont(14, weight: 400, style: .footnote).foregroundStyle(Read4.ink)
                Text("Shorten the steps, or move Quit Day if you'd like the full taper.").v4Text(.subtitle)
                Button("Move Quit Day to \(newQuit.formatted(.dateTime.weekday(.abbreviated).day().month()))") {
                    profile.quitDay = newQuit
                    try? context.save()
                }
                .buttonStyle(.v4Secondary)
            }
        }
    }

    private func save(start: Date) {
        if let taper = profile.pouchTaper {
            taper.startDate = start
            taper.steps = steps
            taper.stepReminders = remindersOn
        } else {
            profile.pouchTaper = PouchTaper(startDate: start, steps: steps, stepReminders: remindersOn)
        }
        try? context.save()
        saved.toggle()
        Task {
            if remindersOn { await NRTReminders.requestPermissionIfNeeded() }
            NRTReminders.refresh(profile: profile)
        }
        onDone()
    }
}

private struct StrengthBars: View {
    let steps: [PlanStep]

    var body: some View {
        let most = max(steps.map(\.strengthMg).max() ?? 1, 1)
        V4Card(padding: 14) {
            VStack(alignment: .leading, spacing: DX.Space.xs) {
                Text("Strength by step").v4Text(.cardHeading)
                HStack(alignment: .bottom, spacing: DX.Space.xs) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(i == 0 ? Read4.accent : Read4.track)
                                .frame(height: max(6, 72 * step.strengthMg / most))
                            Text(verbatim: NRTReminderPlan.strength(step.strengthMg)).v4Text(.subtitle)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3).fill(Read4.track).frame(height: 3)
                        Text("Quit Day").v4Text(.subtitle).lineLimit(1).minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 100, alignment: .bottom)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
