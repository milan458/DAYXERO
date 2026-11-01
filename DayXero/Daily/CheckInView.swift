import DayXeroCore
import SwiftData
import SwiftUI

/// F16 Evening check-in (violet, with Glim): how today went, the waves from today's SOS, a mood, then rest.
/// About a minute; it never changes days clear (S11.2). Prep week asks how prep went instead of clear day or slip.
struct CheckInView: View {
    let profile: UserProfile
    let onDone: () -> Void

    enum Stage {
        case form, slip, plan, done
    }

    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \LogEntry.timestamp, order: .reverse) private var logs: [LogEntry]
    @State private var stage = Stage.form
    @State private var clearDay = true
    @State private var mindful = true
    @State private var cravings: Int?
    @State private var editingCravings = false
    @State private var mood: CheckInMood?
    @State private var note = ""
    @State private var addingNote = false
    @State private var slipEntry: LogEntry?
    @State private var showDayEnd = false
    @State private var saved = false
    @State private var shown = false

    private let ground = DX.Ground.violet

    var body: some View {
        Group {
            switch stage {
            case .form: form
            case .slip: SlipFlow(entry: slipEntry, profile: profile, startInTalkThrough: true) { stage = .done }
            case .plan: TomorrowPlan(profile: profile, trigger: commonTrigger) { stage = .done }
            case .done: WindDownView(profile: profile, savedJustNow: true, onClose: onDone)
            }
        }
        .sensoryFeedback(DX.Haptic.commit, trigger: saved)
        .sheet(isPresented: $showDayEnd) {
            DayEndSettings(profile: profile).presentationDetents([.large])
        }
        .onAppear {
            #if DEBUG
            if UserDefaults.standard.bool(forKey: "dx.checkInDone") { stage = .done }
            #endif
        }
    }

    // MARK: F16

    private var form: some View {
        let today = todaysLogs
        let logged = today.filter { $0.kind == .craving }
        let ridden = logged.filter { $0.outcome == .passed }.count
        let count = cravings ?? logged.count
        let rode = min(ridden, count)
        let hard = !prep && count > 0 && rode < count
        return VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ZStack(alignment: .bottom) {
                        HeroScene(.night, clarity: clarity, height: 250, edge: ground.background)
                        GlimView(mood: mood == .good || mood == .proud ? .cheer : .calm,
                                 stage: CrewGrowth.stage(daysClear: stats.daysClear(at: .now)), size: .scene)
                            .offset(y: shown || reduceMotion ? -10 : -50)
                            .opacity(shown ? 1 : 0)
                            .accessibilityHidden(true)
                    }
                    .overlay(alignment: .topTrailing) {
                        Button(action: onDone) {
                            Image(systemName: "xmark").font(.system(size: 18, weight: .bold))
                                .foregroundStyle(DX.Fill.navy)
                                .frame(width: 44, height: 44)
                                .background(DX.Fill.cream.opacity(0.85), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("Close"))
                        .padding(.trailing, 10).padding(.top, 50)
                    }
                    .padding(.horizontal, -DX.Layout.gutter)
                    .ignoresSafeArea(edges: .top)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(verbatim: eyebrow).dxFont(14, weight: 700, style: .footnote).foregroundStyle(ground.muted)
                        Text(verbatim: headline(count: count, rode: rode)).dxType(.large).foregroundStyle(ground.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                        Text(verbatim: line(count: count, rode: rode)).dxType(.body).foregroundStyle(ground.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .dxArrive(3)
                    if prep {
                        prepChoice.dxArrive(4)
                        usedToday(today).dxArrive(4)
                    } else {
                        dayChoice(slipLogged: today.contains { $0.kind == .slip }).dxArrive(4)
                    }
                    wavesRow(count: count, logged: logged.count, rode: rode).dxArrive(5)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("How are you feeling tonight?").dxFont(16, weight: 700, style: .body).foregroundStyle(ground.ink)
                        MoodPicker(selection: $mood, ground: ground)
                    }
                    .padding(14)
                    .background(DX.Fill.onColourCard(for: ground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .dxArrive(6)
                    noteField.dxArrive(7)
                }
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.bottom, DX.Space.m)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
            VStack(spacing: 6) {
                Button(hard ? "Make a plan for tomorrow" : prep ? "Save prep day \(prepDay) check-in" : "Save and rest") {
                    save(defaultCount: logged.count, slipLogged: today.contains { $0.kind == .slip }, plan: hard)
                }
                .buttonStyle(.dx(.primary, on: ground))
                .disabled(mood == nil)
                Button { showDayEnd = true } label: {
                    Text("Your day ends at \(DayEndSettings.label(profile.dayBoundaryHour)) · \(Text("change").underline())")
                        .dxType(.footnote).foregroundStyle(ground.muted)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
            }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .padding(.horizontal, DX.Layout.buttonGutter)
            .padding(.bottom, DX.Space.xs)
        }
        .dxReadableColumn()
        .background(ground.background.ignoresSafeArea())
        .onAppear {
            withAnimation(DX.Move.animation(DX.Move.settle, reduceMotion: reduceMotion)) { shown = true }
        }
    }

    /// "Sunday check-in · Day 3", or the prep day.
    private var eyebrow: String {
        // The day the check-in counts for: before the day boundary it's still the evening just lived.
        let weekday = DailyRhythm(clock: DayClock(boundaryHour: profile.dayBoundaryHour)).day(at: .now).formatted(.dateTime.weekday(.wide))
        if prep { return String(localized: "Prep day \(prepDay) check-in · \(stats.daysUntilQuitDay(at: .now)) days to Quit Day") }
        let day = DayClock(boundaryHour: profile.dayBoundaryHour).days(fromDate: profile.quitDay, to: .now) + 1
        return day > 0 ? String(localized: "\(weekday) check-in · Day \(day)") : String(localized: "\(weekday) check-in")
    }

    /// The headline follows the day: no waves, every wave ridden out, or a hard one (design doc §10, F16).
    private func headline(count: Int, rode: Int) -> String {
        if prep { return String(localized: "How did your prep go today?") }
        if count == 0 { return String(localized: "A quiet day. Those count too.") }
        if rode == count { return String(localized: "\(rode) of \(count) waves. All yours.") }
        return String(localized: "Today was hard. You're still here.")
    }

    private func line(count: Int, rode: Int) -> String {
        if prep { return String(localized: "Using normally is part of prep week. No guilt, just noticing.") }
        if count == 0 { return String(localized: "No waves today. Your brain is learning that nothing is missing.") }
        if rode == count { return String(localized: "Each one you ride out makes the next a little quieter.") }
        if let trigger = commonTrigger {
            return String(localized: "You rode \(rode) of \(count). Want one small plan for \(String(localized: trigger.situation)) tomorrow?")
        }
        return String(localized: "You rode \(rode) of \(count). Want one small plan for tomorrow?")
    }

    /// "From today's SOS: 3 of 3 waves ridden out · Edit". Edit opens a stepper for cravings that weren't logged.
    private func wavesRow(count: Int, logged: Int, rode: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Group {
                    if logged == 0 && cravings == nil {
                        Text("No cravings logged today")
                    } else {
                        Text("From today's SOS: \(Text("\(rode) of \(count) waves ridden out").fontWeight(.bold))")
                    }
                }
                .dxType(.footnote).foregroundStyle(ground.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                Button(editingCravings ? "Done" : logged == 0 && cravings == nil ? "Add" : "Edit") {
                    withAnimation(DX.Move.animation(DX.Move.settle, reduceMotion: reduceMotion)) { editingCravings.toggle() }
                }
                .dxFont(14, weight: 700, style: .footnote)
                .foregroundStyle(ground.ink)
                .frame(minWidth: 44, minHeight: 44)
            }
            if editingCravings {
                HStack {
                    stepButton("minus", label: "Fewer") { cravings = max(count - 1, 0) }
                    Spacer()
                    Text(verbatim: "\(count)").dxType(.title).foregroundStyle(ground.ink).monospacedDigit()
                        .accessibilityLabel(Text("\(count) cravings today"))
                    Spacer()
                    stepButton("plus", label: "More") { cravings = count + 1 }
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 4)
        .background(DX.Fill.onColourCard(for: ground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func stepButton(_ icon: String, label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 16, weight: .bold)).foregroundStyle(ground.ink)
                .frame(width: 44, height: 44)
                .background(DX.Fill.onColourCard(for: ground), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }

    /// Clear day or a slip. A slip with nothing logged opens the talk-through after saving; nothing resets.
    private func dayChoice(slipLogged: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                choice(String(localized: "Clear day"), on: clearDay) { clearDay = true }
                choice(String(localized: "Had a slip"), on: !clearDay) { clearDay = false }
            }
            if !clearDay {
                Text(slipLogged ? "You've already logged it. Nothing resets." : "We'll help you log it after this. Nothing resets.")
                    .dxType(.footnote).foregroundStyle(ground.muted)
            }
        }
    }

    private var prepChoice: some View {
        HStack(spacing: 8) {
            choice(String(localized: "Mindful, noticed my triggers"), on: mindful) { mindful = true }
            choice(String(localized: "Mostly autopilot"), on: !mindful) { mindful = false }
        }
    }

    /// V4Chip's look, with the width inside the background so each chip fills its half of the row.
    private func choice(_ title: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(verbatim: title)
                .dxFont(16, weight: 600, style: .body)
                .foregroundStyle(on ? Color(hex: 0x4A3596) : ground.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(on ? DX.Fill.cream : DX.Fill.onColourCard(for: ground),
                            in: RoundedRectangle(cornerRadius: DX.Layout.answerChipRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(DX.Haptic.select, trigger: on)
        .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
    }

    /// Prep week: what was used today, per product, with steppers for anything not logged at the time.
    private func usedToday(_ today: [LogEntry]) -> some View {
        VStack(spacing: 6) {
            ForEach(profile.products.map(\.product), id: \.self) { product in
                let uses = today.filter { $0.kind != .craving && $0.product == product }
                HStack {
                    Text(verbatim: String(localized: product.unit).localizedCapitalized)
                        .dxFont(16, weight: 600, style: .body).foregroundStyle(ground.ink)
                    Spacer()
                    stepButton("minus", label: "One fewer") { if let last = uses.first { UseLog.undo(last, in: context) } }
                        .disabled(uses.isEmpty)
                    Text(verbatim: uses.count.formatted()).dxType(.headline).foregroundStyle(ground.ink).frame(minWidth: 36)
                    stepButton("plus", label: "One more") { UseLog.log(product, in: context) }
                }
                .padding(.horizontal, 14).padding(.vertical, 4)
                .background(DX.Fill.onColourCard(for: ground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .accessibilityElement(children: .contain)
                .accessibilityLabel(Text("\(uses.count) \(Text(product.unit)) today"))
            }
        }
    }

    @ViewBuilder
    private var noteField: some View {
        if addingNote {
            TextField("", text: $note, prompt: Text(prep ? "My 4 pm one didn't really help the stress" : "Busy day at work, coffee was hard")
                .foregroundStyle(ground.muted), axis: .vertical)
                .lineLimit(2...4)
                .dxType(.body)
                .foregroundStyle(ground.ink)
                .padding(14)
                .background(DX.Fill.onColourCard(for: ground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .accessibilityLabel(Text("Anything to remember"))
        } else {
            Button { addingNote = true } label: {
                Label("Anything to remember? · optional", systemImage: "square.and.pencil")
                    .dxType(.footnote).foregroundStyle(ground.ink).frame(minHeight: 44)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Data

    private var stats: ProgressStats {
        ProgressStats(quitDay: profile.quitDay, baselines: [], clock: DayClock(boundaryHour: profile.dayBoundaryHour))
    }

    private var prep: Bool { stats.isPrep(at: .now) }

    private var prepDay: Int {
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        return max(clock.days(fromDate: profile.createdAt, to: .now) + 1, 1)
    }

    private var clarity: Int { prep ? CrewGrowth.prepClarity : CrewGrowth.clarity(daysClear: stats.daysClear(at: .now)) }

    private var todaysLogs: [LogEntry] {
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        let today = clock.day(containing: .now)
        return logs.prefix(200).filter { clock.day(containing: $0.timestamp) == today }
    }

    /// Today's most common trigger, for "a plan for after coffee tomorrow".
    private var commonTrigger: Trigger? {
        let triggers = todaysLogs.filter { $0.kind == .craving || $0.kind == .slip }.compactMap(\.trigger)
        let counts = Dictionary(triggers.map { ($0, 1) }, uniquingKeysWith: +)
        return counts.max { $0.value < $1.value }?.key ?? profile.triggers.first
    }

    /// The four drawn faces are stored on the five-point scale: Rough low, Okay okay, Good good, Proud great (decision 27).
    private var storedMood: Mood {
        switch mood {
        case .rough: .low
        case .good: .good
        case .proud: .great
        case .okay, nil: .okay
        }
    }

    private func save(defaultCount: Int, slipLogged: Bool, plan: Bool) {
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        let prep = prep
        context.insert(CheckIn(day: clock.day(containing: .now), mood: storedMood, cravingCount: cravings ?? defaultCount,
                               note: note.isEmpty ? nil : note, clearDay: prep ? true : clearDay,
                               prepMindful: prep ? mindful : nil))
        try? context.save()
        saved.toggle()
        DailyReminders.refresh(in: context)
        // "Had a slip" with nothing logged today: log it and open the talk-through (S8).
        if !prep, !clearDay, !slipLogged, let product = profile.primaryProduct?.product {
            slipEntry = UseLog.log(product, in: context)
            Analytics.track(.slipLogged(source: "checkin"))
            stage = .slip
        } else {
            stage = plan ? .plan : .done
        }
    }
}

/// "Make a plan for tomorrow" after a hard day: one if-then plan, saved where Today and SOS show it.
struct TomorrowPlan: View {
    let profile: UserProfile
    let onDone: () -> Void
    @Environment(\.modelContext) private var context
    @State private var trigger: Trigger?
    @State private var action: String?

    init(profile: UserProfile, trigger: Trigger?, onDone: @escaping () -> Void) {
        self.profile = profile
        self.onDone = onDone
        _trigger = State(initialValue: trigger)
    }

    private let ground = DX.Ground.violet

    var body: some View {
        let situation = String(localized: (trigger ?? .other).situation)
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("One small plan").dxType(.caption).textCase(.uppercase).foregroundStyle(ground.muted)
                    MarkedTitle(String(localized: "For "), marking: String(localized: "tomorrow"), color: DX.Mark.color(on: ground))
                        .dxType(.large).foregroundStyle(ground.ink)
                    Text("What's most likely to set it off?").dxFont(16, weight: 700, style: .body).foregroundStyle(ground.ink)
                    TriggerPicker(mine: profile.triggers, selection: $trigger, fill: DX.Fill.onColourCard(for: ground), ink: ground.ink,
                                  selectedFill: DX.Fill.cream, selectedInk: Color(hex: 0x4A3596))
                    Text("If it's \(situation), then I'll…").dxFont(19, weight: 700, style: .headline).foregroundStyle(ground.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach((trigger ?? .other).nextTimeSuggestions.map { String(localized: $0) }, id: \.self) { idea in
                        V4Chip(text: idea, isOn: action == idea, fill: DX.Fill.onColourCard(for: ground), ink: ground.ink,
                               selectedFill: DX.Fill.cream, selectedInk: Color(hex: 0x4A3596)) { action = idea }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.top, DX.Space.xl)
            }
            .scrollBounceBehavior(.basedOnSize)
            VStack(spacing: 4) {
                Button("Save my plan") {
                    guard let action else { return }
                    context.insert(IfThenPlan(situation: situation, action: action))
                    try? context.save()
                    onDone()
                }
                .buttonStyle(.dx(.primary, on: ground))
                .disabled(action == nil)
                Button("Not tonight", action: onDone).buttonStyle(.dx(.quiet, on: ground))
            }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .padding(.horizontal, DX.Layout.buttonGutter)
            .padding(.bottom, DX.Space.xs)
        }
        .dxReadableColumn()
        .background(ground.background.ignoresSafeArea())
        .onChange(of: trigger) { _, _ in action = nil }
    }
}

/// When "today" ends (S11.3). Days clear, lessons and check-ins all follow it.
struct DayEndSettings: View {
    let profile: UserProfile
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: DX.Space.xs) {
            Text("When does your day end?").v4Text(.title).padding(.top, DX.Space.xl)
            Text("Up late? A check-in before this time still counts for the day you've just had.").v4Text(.subtitle)
                .padding(.bottom, DX.Space.s)
            ForEach(DailyRhythm.boundaryChoices, id: \.self) { hour in
                OnbOptionCard(LocalizedStringResource(stringLiteral: Self.label(hour)),
                             detail: hour == 4 ? "Default" : hour == 6 ? "For night shifts and late finishes" : nil,
                             isSelected: profile.dayBoundaryHour == hour) {
                    profile.dayBoundaryHour = hour
                    try? context.save()
                    DailyReminders.refresh(in: context)
                }
            }
            Spacer()
            Text("Days clear, lessons and check-ins all follow this.").v4Text(.subtitle).frame(maxWidth: .infinity)
            Button("Done") { dismiss() }.buttonStyle(.dx(.primary, on: .reading))
        }
        .padding(.horizontal, DX.Space.m)
        .dxReadableColumn()
        .padding(.bottom, DX.Space.xs)
        .background(Read4.background.ignoresSafeArea())
    }

    static func label(_ hour: Int) -> String {
        if hour == 0 { return String(localized: "midnight") }
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now
        return date.formatted(.dateTime.hour())
    }
}
