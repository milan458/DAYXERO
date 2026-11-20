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
    @State private var showGumGuide = false

    var body: some View {
        let schedule = StepSchedule(startDate: plan.startDate, steps: plan.steps, clock: clock)
        let current = schedule.current(at: now)
        V4Card(padding: 14) {
            VStack(alignment: .leading, spacing: DX.Space.xs) {
                HStack(spacing: DX.Space.s) {
                    DXIcon(plan.type == .inhaler ? .lungs : .patch, size: 20)
                        .foregroundStyle(DX.Ground.reading.ink)
                        .frame(width: 40, height: 40)
                        .background(DX.Ground.reading.card2, in: Circle())
                        .accessibilityHidden(true)
                    // The product's icon says it's NRT; the line says what this week is (S18.10).
                    VStack(alignment: .leading, spacing: 1) {
                        Text(verbatim: headline(schedule, current: current))
                            .dxFace(.body, 16, weight: 600).foregroundStyle(DX.Ground.reading.ink)
                    }
                }
                if let current {
                    let stepDays = max(current.step.weeks * 7, 1)
                    let into = (clock.calendar.dateComponents([.day], from: current.start, to: clock.day(containing: now)).day ?? 0) + 1
                    DXProgress(Double(into) / Double(stepDays))
                    HStack {
                        Text("Day \(into) of \(stepDays)")
                        Spacer()
                        if let next = schedule.next(after: current) {
                            Text("\(NRTReminderPlan.strength(next.step.strengthMg)) from \(next.start.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))")
                        } else {
                            Text("Last step")
                        }
                    }
                    .dxType(.footnote).foregroundStyle(DX.Ground.reading.muted)
                    if let note = current.step.note { Text(verbatim: note).dxType(.footnote).foregroundStyle(DX.Ground.reading.muted) }
                    if plan.type == .patch, !showAllSteps { patchCheck }
                    if plan.type == .patch { bedtimeToggle }
                    if plan.type == .gum {
                        Button { showGumGuide = true } label: {
                            HStack(spacing: 8) {
                                DXIcon(.note, size: 18)
                                Text("How to chew and park")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.dx(.ghost, on: .reading))
                    }
                } else if !schedule.hasStarted(at: now), let start = schedule.start {
                    Text("Starts \(start.formatted(.dateTime.weekday(.wide).day().month()))").dxType(.footnote).foregroundStyle(DX.Ground.reading.muted)
                } else {
                    Text("Plan finished. Well done for seeing it through.").dxType(.footnote).foregroundStyle(DX.Ground.reading.muted)
                }
                if showAllSteps {
                    VStack(spacing: 0) {
                        ForEach(schedule.spans, id: \.index) { span in
                            StepRow(span: span, type: plan.type, highlighted: span == current, done: clock.day(containing: now) >= span.end)
                        }
                    }
                    .padding(.top, DX.Space.xxs)
                    Text("Follow the label on your pack and ask a pharmacist or doctor.").dxType(.footnote).foregroundStyle(DX.Ground.reading.muted)
                }
            }
        }
        .sheet(isPresented: $showGumGuide) {
            ScrollView {
                VStack(alignment: .leading, spacing: DX.Space.s) {
                    Text("Chew and park").dxType(.title).foregroundStyle(DX.Ground.reading.ink).padding(.top, DX.Space.l)
                    ChewAndParkGuide()
                    LabelNotice()
                }
                .padding(.horizontal, DX.Layout.gutter)
                .dxReadableColumn()
            }
            .background(DX.Ground.reading.background.ignoresSafeArea())
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private func headline(_ schedule: StepSchedule, current: StepSchedule.Span?) -> String {
        let type = String(localized: plan.type.title).lowercased()
        guard let current else { return String(localized: "\(NRTReminderPlan.strength(plan.steps.first?.strengthMg ?? 0)) \(type)") }
        return String(localized: "\(NRTReminderPlan.strength(current.step.strengthMg)) \(type) · Step \(current.index + 1) of \(schedule.spans.count)")
    }

    /// CLIN-03: 16 hours (off at bedtime) or 24 (on overnight). Switching it reschedules the "patch off" reminder.
    private var bedtimeToggle: some View {
        Toggle(isOn: Binding(get: { plan.offAtBedtime }, set: { off in
            plan.offAtBedtime = off
            try? context.save()
            NRTReminders.refresh(profile: try? context.fetch(FetchDescriptor<UserProfile>()).first)
        })) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Off at bedtime").dxFace(.body, 16, weight: 600).foregroundStyle(DX.Ground.reading.ink)
                Text(plan.offAtBedtime ? "16 hours a day. Helps if dreams or sleep are disturbed." as LocalizedStringKey : "On overnight, 24 hours a day")
                    .dxType(.footnote).foregroundStyle(DX.Ground.reading.muted)
            }
        }
        .tint(DX.Ground.reading.sel)
    }

    /// "Patch on today": a one-tap check that also silences today's reminder.
    private var patchCheck: some View {
        let done = plan.lastCheckedDay.map { clock.day(containing: $0) == clock.day(containing: now) } ?? false
        return Button {
            plan.lastCheckedDay = done ? nil : now
            try? context.save()
            NRTReminders.refresh(profile: try? context.fetch(FetchDescriptor<UserProfile>()).first)
        } label: {
            HStack(spacing: 8) {
                DXIcon(.check, size: 18, weight: 2.6).opacity(done ? 1 : 0.3)
                Text(done ? "Patch on today" as LocalizedStringKey : "Mark patch on")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.dx(.ghost, on: .reading))
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
                Text("Your pouch taper").dxType(.headline).foregroundStyle(DX.Ground.reading.ink)
                if let current = schedule.current(at: now) {
                    Text("\(NRTReminderPlan.strength(current.step.strengthMg)) this week · step \(current.index + 1) of \(schedule.spans.count)")
                        .dxFace(.body, 16, weight: 600).foregroundStyle(DX.Ground.reading.ink)
                    if let next = schedule.next(after: current) {
                        Text("\(NRTReminderPlan.strength(next.step.strengthMg)) from \(next.start.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))").dxType(.footnote).foregroundStyle(DX.Ground.reading.muted)
                    } else {
                        Text("Then Day Xero").dxType(.footnote).foregroundStyle(DX.Ground.reading.muted)
                    }
                } else if let start = schedule.start, !schedule.hasStarted(at: now) {
                    Text("Starts \(start.formatted(.dateTime.weekday(.wide).day().month()))")
                        .dxFace(.body, 16, weight: 600).foregroundStyle(DX.Ground.reading.ink)
                } else {
                    Text("Taper done. Day Xero is next.").dxFace(.body, 16, weight: 600)
                        .foregroundStyle(DX.Ground.reading.ink)
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
                    Text(title).dxFace(.body, 16, weight: 700).foregroundStyle(DX.Ground.reading.ink)
                    Text(detail).dxType(.footnote).foregroundStyle(DX.Ground.reading.muted)
                }
                Spacer(minLength: DX.Space.xs)
                DXIcon(.chev, size: 14, weight: 2.6).foregroundStyle(DX.Ground.reading.muted)
                    .accessibilityHidden(true)
            }
            .padding(14)
            .background(DX.Fill.raised, in: RoundedRectangle(cornerRadius: DX.Layout.smallCardRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

/// The optional pouch-strength taper (S9.3). It ends the day before Day Xero and only runs if it fits;
/// moving Day Xero to make room is the person's choice, never automatic.
/// v5 (052): when it doesn't fit, the conflict is the title, and the chart shows where Day Xero falls in it.
struct TaperSetupView: View {
    let profile: UserProfile
    let onDone: () -> Void

    @Environment(\.modelContext) private var context
    @State private var steps: [PlanStep]
    @State private var editing: Int?
    @State private var remindersOn = true
    @State private var saved = false
    private let motion = MotionPolicy()
    private let ground = DX.Ground.reading

    init(profile: UserProfile, onDone: @escaping () -> Void) {
        self.profile = profile
        self.onDone = onDone
        let start = profile.products.first { $0.product == .pouches }?.strengthMg ?? 6
        _steps = State(initialValue: profile.pouchTaper?.steps ?? PouchTaperPlan.suggestedSteps(from: start))
    }

    var body: some View {
        let g = ground
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        let fits = PouchTaperPlan.fits(steps: steps, quitDay: profile.quitDay, now: .now, clock: clock)
        let start = PouchTaperPlan.startDate(steps: steps, quitDay: profile.quitDay, clock: clock)
        let schedule = StepSchedule(startDate: fits ? start : clock.day(containing: .now), steps: steps, clock: clock)
        let weeks = steps.reduce(0) { $0 + $1.weeks }
        let most = max(steps.map(\.strengthMg).max() ?? 1, 0.1)
        VStack(spacing: 0) {
            HStack {
                DXIconButton(.close, label: "Close", action: onDone)
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .padding(.top, 8)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Group {
                        if fits {
                            Text("Step down your pouches")
                        } else {
                            Text("Your taper needs ^[\(weeks) week](inflect: true)")
                        }
                    }
                    .dxType(.title).foregroundStyle(g.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .dxArrive(0)
                    Group {
                        if fits {
                            Text("Lower the strength before Day Xero, so stopping feels smaller. It ends the day before Day Xero, \(profile.quitDay.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())).")
                        } else {
                            Text("Day Xero is in ^[\(daysToQuit(clock)) day](inflect: true). Stepping your pouches down first makes stopping feel smaller.")
                        }
                    }
                    .dxType(.footnote).foregroundStyle(g.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                    .dxArrive(1)
                    TaperChart(schedule: schedule, quitDay: profile.quitDay, fits: fits, clock: clock)
                        .padding(.top, -2)
                        .padding(.bottom, -2)
                        .dxCard()
                        .padding(.top, 22)
                        .dxArrive(3)
                    DXList {
                        ForEach(schedule.spans, id: \.index) { span in
                            Button { editing = span.index } label: {
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(NRTPalette.bar)
                                        .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous).strokeBorder(NRTPalette.taperEdge, lineWidth: 1.5))
                                        .frame(width: 10, height: max(12, 30 * span.step.strengthMg / most))
                                        .frame(height: 30)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(verbatim: NRTReminderPlan.strength(span.step.strengthMg))
                                            .dxFace(.display, 16, weight: 700).foregroundStyle(g.ink)
                                        Text(verbatim: StepRow.dates(span, separator: String(localized: "to")))
                                            .dxType(.footnote).foregroundStyle(g.muted)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    DXIcon(.chev, size: 18).foregroundStyle(g.muted).padding(.leading, -4)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 8)
                                .frame(minHeight: 52)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityElement(children: .combine)
                            .accessibilityHint(Text("Change this step"))
                            .dxSettle(4 + span.index)
                        }
                    }
                    .padding(.top, 16)
                    Toggle(isOn: $remindersOn) {
                        HStack(spacing: 14) {
                            NRTGlyphTile(glyph: NRTGlyph(.steps, size: 28), tile: 46)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Step-down reminders").dxFace(.display, 17, weight: 700).foregroundStyle(g.ink)
                                Text("The evening before each step").dxType(.footnote).foregroundStyle(g.muted)
                            }
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(g.card, in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous).strokeBorder(g.line, lineWidth: 1))
                    .padding(.top, 16)
                    .dxArrive(7)
                    Text("Pouches aren't NRT, so there's no label for this. It's a plan you set; change any step to suit the strengths you can buy.")
                        .dxType(.caption).foregroundStyle(g.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 4)
                        .padding(.top, 14)
                        .dxArrive(7)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.top, 14)
                .padding(.bottom, DX.Space.m)
            }
            .scrollBounceBehavior(.basedOnSize)
            DXActionDock {
                if fits {
                    Button("Save my taper") { save(start: start) }
                        .buttonStyle(.dx(.primary, on: .reading))
                        .dxArrive(8)
                    if profile.pouchTaper != nil {
                        Button("Remove the taper", role: .destructive) {
                            profile.pouchTaper = nil
                            try? context.save()
                            NRTReminders.refresh(profile: profile)
                            onDone()
                        }
                        .buttonStyle(.dx(.quiet, on: .reading))
                    }
                } else {
                    // Nothing moves on its own: moving Day Xero is a choice, and so is shortening the steps.
                    let newQuit = PouchTaperPlan.quitDayToFit(steps: steps, now: .now, clock: clock)
                    Button("Move Day Xero to \(newQuit.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))") {
                        withAnimation(motion.animation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.7))) {
                            profile.quitDay = newQuit
                        }
                        try? context.save()
                    }
                    .buttonStyle(.dx(.primary, on: .reading))
                    .dxArrive(8)
                    Button("Shorten the steps instead") { editing = max(steps.count - 1, 0) }
                        .buttonStyle(.dx(.quiet, on: .reading))
                        .dxArrive(9)
                }
            }
            .padding(.top, -36)
        }
        .dxReadableColumn()
        .dxGround(ground)
        .toggleStyle(.dx)
        .sensoryFeedback(DX.Haptic.commit, trigger: saved)
        .sensoryFeedback(.warning, trigger: fits) { _, now in !now }
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

    private func daysToQuit(_ clock: DayClock) -> Int {
        max(clock.calendar.dateComponents([.day], from: clock.day(containing: .now), to: clock.startOfDate(profile.quitDay)).day ?? 0, 0)
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
