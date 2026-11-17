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
    private let motion = MotionPolicy()
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
            case .done: CheckInSavedView(profile: profile, onClose: onDone)
            }
        }
        .sensoryFeedback(DX.Haptic.commit, trigger: saved)
        .sheet(isPresented: $showDayEnd) {
            DayEndSettings(profile: profile, onClose: { showDayEnd = false }).presentationDetents([.large])
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
                    // v5 (054): Glim floats in the midnight meadow; the close button sits top-left.
                    ZStack(alignment: .bottom) {
                        NightSky(moon: CGPoint(x: 330, y: 110))
                            .frame(height: 290)
                        GlimView(mood: mood == .good || mood == .proud ? .cheer : .calm,
                                 stage: CrewGrowth.stage(daysClear: stats.daysClear(at: .now)), points: 200)
                            .dxBob()
                            .offset(y: shown || motion.reduce ? -24 : -64)
                            .opacity(shown ? 1 : 0)
                            .accessibilityHidden(true)
                    }
                    .overlay(alignment: .topLeading) {
                        Button(action: onDone) {
                            DXIcon(.close, size: 20, weight: 2.4)
                                .foregroundStyle(ground.ink)
                                .frame(width: 44, height: 44)
                                .background(ground.card2, in: Circle())
                        }
                        .buttonStyle(.dxPress)
                        .accessibilityLabel(Text("Close"))
                        .padding(.leading, 16).padding(.top, 54)
                    }
                    .padding(.horizontal, -DX.Layout.gutter)
                    .ignoresSafeArea(edges: .top)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(verbatim: eyebrow).dxFont(14, weight: 700, style: .footnote).foregroundStyle(ground.muted)
                        Text(verbatim: headline(count: count, rode: rode)).dxType(.title).foregroundStyle(ground.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                        Text(verbatim: line(count: count, rode: rode)).dxType(.footnote).foregroundStyle(ground.muted)
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
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How are you feeling tonight?").dxType(.headline).foregroundStyle(ground.ink)
                        MoonPicker(selection: $mood)
                    }
                    .padding(.top, 6)
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
            }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .padding(.horizontal, DX.Layout.buttonGutter)
            .padding(.bottom, DX.Space.xs)
        }
        .dxReadableColumn()
        .background(ground.background.ignoresSafeArea())
        .onAppear {
            withAnimation(motion.animation(DX.Move.settle)) { shown = true }
        }
    }

    /// "Sunday check-in · Day 3", or the prep day.
    private var eyebrow: String {
        // The day the check-in counts for: before the day boundary it's still the evening just lived.
        let weekday = DailyRhythm(clock: DayClock(boundaryHour: profile.dayBoundaryHour)).day(at: .now).formatted(.dateTime.weekday(.wide))
        if prep { return String(localized: "Prep day \(prepDay) check-in · \(stats.daysUntilQuitDay(at: .now)) days to Quit Day") }
        let day = DayClock(boundaryHour: profile.dayBoundaryHour).days(fromDate: profile.quitDay, to: .now) + 1
        return day > 0 ? String(localized: "\(weekday) check-in, Day \(day)") : String(localized: "\(weekday) check-in")
    }

    /// The headline follows the day: no waves, every wave ridden out, or a hard one (design doc §10, F16).
    private func headline(count: Int, rode: Int) -> String {
        if prep { return String(localized: "How did your prep go today?") }
        if count == 0 { return String(localized: "A quiet day. Those count too.") }
        if rode == count { return count == 1 ? String(localized: "1 wave today.\nHow was the rest of the day?")
                                             : String(localized: "\(count) waves today.\nHow was the rest of the day?") }
        return String(localized: "Today was hard. You're still here.")
    }

    private func line(count: Int, rode: Int) -> String {
        if prep { return String(localized: "Using normally is part of prep week. No guilt, just noticing.") }
        if count == 0 { return String(localized: "No waves today. Your brain is learning that nothing is missing.") }
        if rode == count { return String(localized: "Every wave makes the next a little quieter.") }
        if let trigger = commonTrigger {
            return String(localized: "You rode \(rode) of \(count). Want one small plan for \(String(localized: trigger.situation)) tomorrow?")
        }
        return String(localized: "You rode \(rode) of \(count). Want one small plan for tomorrow?")
    }

    /// Today's waves (054): the wave tile, when the last one was, and an outlined Edit pill. Edit opens a stepper for
    /// cravings that weren't logged.
    private func wavesRow(count: Int, logged: Int, rode: Int) -> some View {
        let last = todaysLogs.first { $0.kind == .craving }?.timestamp
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                DXIcon(.wave, size: 22).foregroundStyle(ground.ink)
                    .frame(width: 44, height: 44)
                    .background(ground.card2, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(cravings == nil ? "Today's waves" : "\(count) waves today").dxFont(16, weight: 700, style: .body).foregroundStyle(ground.ink)
                    Group {
                        if let last, cravings == nil {
                            Text("Last one at \(last.formatted(date: .omitted, time: .shortened))")
                        } else if logged == 0 && cravings == nil {
                            Text("None logged today")
                        } else {
                            Text("\(rode) ridden out")
                        }
                    }
                    .dxType(.footnote).foregroundStyle(ground.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button(editingCravings ? "Done" : logged == 0 && cravings == nil ? "Add" : "Edit") {
                    withAnimation(motion.animation(DX.Move.settle)) { editingCravings.toggle() }
                }
                .dxFont(15, weight: 700, style: .subheadline)
                .foregroundStyle(ground.ink)
                .padding(.horizontal, 16)
                .frame(minHeight: 36)
                .overlay(Capsule().strokeBorder(ground.ink.opacity(0.4), lineWidth: 1.5))
                .frame(minHeight: 44)
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
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(DX.Fill.onColourCard(for: ground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(ground.line, lineWidth: 1))
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
            HStack(spacing: 4) {
                choice(String(localized: "Clear day"), on: clearDay) { clearDay = true }
                choice(String(localized: "Had a slip"), on: !clearDay) { clearDay = false }
            }
            .padding(4)
            .background(ground.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(ground.line, lineWidth: 1))
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

    /// v5 (054): a segment in the night card's track; the chosen one is the lifted card-2 tile.
    private func choice(_ title: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(verbatim: title)
                .dxFace(.body, 15, weight: on ? 700 : 600)
                .foregroundStyle(on ? ground.ink : ground.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(on ? ground.card2.opacity(1) : Color.clear,
                            in: RoundedRectangle(cornerRadius: DX.Layout.chipRadius, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: DX.Layout.chipRadius, style: .continuous)
                    .strokeBorder(on ? ground.ink.opacity(0.12) : .clear, lineWidth: 1))
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
                .accessibilityLabel(Text(verbatim: usedTodayLabel(product, uses.count)))
            }
        }
    }

    /// "1 cigarette today", "3 puffs today".
    private func usedTodayLabel(_ product: DayXeroCore.Product, _ count: Int) -> String {
        switch product {
        case .cigarettes: String(localized: "\(count) cigarettes today")
        case .vape: String(localized: "\(count) puffs today")
        case .pouches: String(localized: "\(count) pouches today")
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
                HStack(spacing: 6) { DXIcon(.note, size: 16); Text("Anything to remember? · optional") }
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
                    Text("One small plan").dxType(.caption).foregroundStyle(ground.muted)
                    // Plain title: the hand-drawn mark is kept for celebrations (S27.15).
                    Text("For tomorrow")
                        .dxType(.large).foregroundStyle(ground.ink)
                        .accessibilityAddTraits(.isHeader)
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

/// When "today" ends (S11.3). Days since Quit Day, lessons and check-ins all follow it. The check-in's "When does your
/// day end?" and Settings › Day ends at both open this one view (S27.14).
struct DayEndSettings: View {
    let profile: UserProfile
    /// From the check-in it opens as a sheet, closed with the X.
    var onClose: (() -> Void)?
    @Environment(\.modelContext) private var context
    @State private var chosen = 0
    private let ground = DX.Ground.reading

    var body: some View {
        SettingsPage("When your day ends", lead: Text("Up late? A check-in before this time still counts for the day you just had."),
                     leading: onClose == nil ? .back : .close, onLeading: onClose) {
            VStack(spacing: 10) {
                ForEach(Array(DailyRhythm.boundaryChoices.enumerated()), id: \.element) { i, hour in
                    DXOptionRow(Text(verbatim: hour == 0 ? String(localized: "Midnight") : Self.label(hour)),
                                detail: detail(hour), isOn: profile.dayBoundaryHour == hour) {
                        guard profile.dayBoundaryHour != hour else { return }
                        profile.dayBoundaryHour = hour
                        try? context.save()
                        DailyReminders.refresh(in: context)
                        chosen += 1
                    }
                    .dxArrive(2 + i)
                }
            }
            .padding(.top, 18)
            DayEndTimeline(hour: profile.dayBoundaryHour)
                .padding(.top, 16)
                .dxArrive(6)
        }
        .sensoryFeedback(.success, trigger: chosen)
        .animation(DX.Move.settle, value: profile.dayBoundaryHour)
    }

    private func detail(_ hour: Int) -> Text? {
        switch hour {
        case 4: Text("Default, fits most late nights")
        case 6: Text("For night shifts and late finishes")
        default: nil
        }
    }

    static func label(_ hour: Int) -> String {
        if hour == 0 { return String(localized: "midnight") }
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now
        return date.formatted(.dateTime.hour())
    }
}

/// Where a late check-in lands (063): Thursday runs from 8 PM on past midnight to the day's end, the 1:30 check-in
/// sits on it, and Friday starts at the end tick.
private struct DayEndTimeline: View {
    let hour: Int
    private let ground = DX.Ground.reading

    var body: some View {
        let late = hour >= 2
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                GlimView(mood: .hello, stage: 1, points: 44)
                    .frame(width: 56, height: 56)
                    .background(Color(hex: 0x1E2A4E), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Group {
                    if late {
                        Text("A check-in at 1:30 AM still counts for Thursday. Friday starts at \(DayEndSettings.label(hour)).")
                    } else {
                        Text("A check-in at 1:30 AM counts for Friday. Friday starts at midnight.")
                    }
                }
                .dxType(.body).foregroundStyle(ground.ink)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)
            }
            GeometryReader { geo in
                let w = geo.size.width
                let b = CGFloat(4 + hour) / 12
                let ci: CGFloat = 5.5 / 12
                let accent = Color(light: 0xD9542E, dark: 0xFF9A72)
                ZStack(alignment: .topLeading) {
                    Capsule().fill(ground.track).frame(width: w, height: 4).offset(y: 36)
                    Capsule().fill(ground.ink).frame(width: w * b, height: 4).offset(y: 36)
                    Rectangle().fill(ground.muted).frame(width: 1.5, height: 10).offset(x: w / 3 - 0.75, y: 33)
                    Rectangle().fill(ground.ink).frame(width: 3, height: 20).offset(x: w * b - 1.5, y: 28)
                    Circle().fill(Color.white).overlay(Circle().strokeBorder(Color(hex: 0xF7894F), lineWidth: 4))
                        .frame(width: 20, height: 20)
                        .offset(x: w * ci - 10, y: 28)
                    label("Thursday", x: 0, anchor: .leading, w: w, y: 0)
                    label("1:30 check-in", x: w * ci, anchor: .center, w: w, y: 0, color: accent)
                    // Friday sits at its start unless the check-in's label is in the way, then at the end.
                    label("Friday", x: abs(b - ci) < 0.2 ? w : w * b, anchor: abs(b - ci) < 0.2 ? .trailing : .leading, w: w, y: 0)
                    label("8 PM", x: 0, anchor: .leading, w: w, y: 56)
                    label("Midnight", x: w / 3, anchor: .center, w: w, y: 56)
                    if hour > 0 { label(LocalizedStringKey(DayEndSettings.label(hour)), x: w * b, anchor: .center, w: w, y: 56) }
                    label("8 AM", x: w, anchor: .trailing, w: w, y: 56)
                }
                .animation(DX.Move.settle, value: hour)
            }
            .frame(height: 76)
        }
        .padding(18)
        .background(ground.card2, in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func label(_ text: LocalizedStringKey, x: CGFloat, anchor: HorizontalAlignment, w: CGFloat, y: CGFloat,
                       color: Color? = nil) -> some View {
        Text(text).dxFont(15, weight: 600, style: .footnote).foregroundStyle(color ?? ground.muted).fixedSize()
            .alignmentGuide(.leading) { d in
                switch anchor {
                case .center: d.width / 2 - x
                case .trailing: d.width - x
                default: -x
                }
            }
            .offset(y: y)
    }
}


/// The four moons (054), drawn by the same code as the craving log (042): each on its own tile, the chosen one lifted
/// with a cream edge and tilted up a touch.
private struct MoonPicker: View {
    @Binding var selection: CheckInMood?
    private let ground = DX.Ground.violet

    var body: some View {
        HStack(spacing: 8) {
            ForEach(CheckInMood.allCases, id: \.self) { mood in
                let on = selection == mood
                Button { selection = mood } label: {
                    VStack(spacing: 8) {
                        MoodMoon(mood: mood)
                            .frame(width: 48, height: 48)
                            .rotationEffect(.degrees(on ? -6 : 0))
                            .offset(y: on ? -2 : 0)
                        Text(mood.label).dxFont(15, weight: on ? 700 : 600, style: .subheadline)
                            .foregroundStyle(ground.ink)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(on ? ground.card2 : DX.Fill.onColourCard(for: ground),
                                in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(on ? Color(hex: 0xF3E7CC) : ground.line, lineWidth: on ? 2 : 1))
                    .animation(DX.Move.settle, value: on)
                }
                .buttonStyle(.dxPress)
                .sensoryFeedback(DX.Haptic.select, trigger: on)
                .accessibilityLabel(Text(mood.label))
                .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
            }
        }
    }
}

/// Check-in saved (v5, 055): the night badge stamps into its gold ring with Glim cheering on a small hill beside it,
/// "Rest well, Sam. See you tomorrow.", the bar to the next night badge, the calm row, and Good night.
struct CheckInSavedView: View {
    let profile: UserProfile
    let onClose: () -> Void
    @Query private var checkIns: [CheckIn]
    @State private var breathing = false
    @State private var stamped = false
    private let ground = DX.Ground.violet
    private let motion = MotionPolicy()
    private static let badges = [7, 14, 30, 60, 100, 180, 365]

    var body: some View {
        let nights = max(checkIns.count, 1)
        let earned = Self.badges.contains(nights)
        let next = Self.badges.first { $0 > nights } ?? nights
        let previous = Self.badges.last { $0 <= nights } ?? 0
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    hero(nights: nights, earned: earned)
                    HStack(spacing: 8) {
                        DXCheck(size: 20, color: DX.Fill.green, tick: .white, calm: true, delay: 1.2)
                        Text(earned ? "Check-in saved. New badge earned." : "Check-in saved.")
                            .dxType(.footnote).foregroundStyle(ground.muted)
                    }
                    .dxArrive(2)
                    VStack(spacing: 0) {
                        MarkedTitle(String(localized: "Rest "), marking: String(localized: "well"),
                                    trail: profile.name.isEmpty ? "." : String(localized: ", \(profile.name)."),
                                    color: DX.Mark.color(on: .violet))
                        Text("See you tomorrow.")
                    }
                    .dxType(.large)
                    .foregroundStyle(ground.ink)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isHeader)
                    .dxArrive(3)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Next badge: \(next) nights").dxType(.headline).foregroundStyle(ground.ink)
                            Spacer()
                            Text(progressWord(nights - previous, of: next - previous)).dxType(.footnote).foregroundStyle(ground.muted)
                        }
                        NightBar(value: Double(nights - previous) / Double(max(next - previous, 1)))
                    }
                    .padding(18)
                    .background(DX.Fill.onColourCard(for: ground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .padding(.top, 22)
                    .dxArrive(4)
                    Button { breathing = true } label: {
                        HStack(spacing: 12) {
                            DXIcon(.moon, size: 22).foregroundStyle(ground.ink)
                                .frame(width: 44, height: 44)
                                .background(ground.card2, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("If tonight feels restless").dxFont(16, weight: 700, style: .body).foregroundStyle(ground.ink)
                                Text("Slow breathing with Glim, 3 min").dxType(.footnote).foregroundStyle(ground.muted)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            DXIcon(.chev, size: 18).foregroundStyle(ground.muted)
                        }
                        .padding(14)
                        .background(DX.Fill.onColourCard(for: ground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.dxPress)
                    .padding(.top, 12)
                    .dxArrive(5)
                }
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.bottom, 20)
            }
            .scrollBounceBehavior(.basedOnSize)
            Button("Good night", action: onClose)
                .buttonStyle(.dx(.primary, on: ground))
                .padding(.horizontal, DX.Layout.buttonGutter)
                .padding(.bottom, DX.Space.xs)
                .dxArrive(6)
        }
        .dxReadableColumn()
        .background(ground.background.ignoresSafeArea())
        .overlay(alignment: .topLeading) {
            DXIconButton(.close, label: "Close", action: onClose)
                .padding(.leading, 16)
                .padding(.top, 8)
        }
        .environment(\.colorScheme, .dark)
        .dxGround(.violet)
        .fullScreenCover(isPresented: $breathing) { GlimBreathingView { breathing = false } }
        .sensoryFeedback(.success, trigger: stamped)
        .task {
            try? await Task.sleep(for: .seconds(motion.reduce ? 0 : 1.1))
            stamped = true
        }
    }

    private func hero(nights: Int, earned: Bool) -> some View {
        ZStack {
            NightSky(moon: CGPoint(x: -300, y: -300)).frame(height: 360).padding(.horizontal, -DX.Layout.gutter)
            Ellipse().fill(.black.opacity(0.28)).frame(width: 150, height: 22).blur(radius: 8)
                .offset(y: 102).dxFade(delay: 0.4)
            DXBadge(.night, n: nights, state: earned ? .earned : .next(nil), size: 156)
                .shadow(color: .black.opacity(0.35), radius: 10, y: 8)
                .dxShine(delay: 1.75)
                .dxStamp(delay: 1.1)
                .offset(y: 20)
            DXFloatUp("+1", trigger: stamped, delay: 0.15)
                .dxFace(.display, 20, weight: 800)
                .foregroundStyle(Color(hex: 0xFFD37A))
                .offset(x: 70, y: -60)
            ZStack(alignment: .bottom) {
                Canvas { ctx, size in
                    ctx.scaleBy(x: size.width / 124, y: size.height / 32)
                    ctx.fill(SVGPath.path("M0 32 C14 16 36 6 62 6 C88 6 110 16 124 32Z"), with: .color(Color(hex: 0x1C2744)))
                    ctx.stroke(SVGPath.path("M9 24 C22 12 40 6 62 6 C84 6 102 12 115 24"), with: .color(Color(hex: 0xF6E7C1).opacity(0.3)), lineWidth: 1.5)
                }
                .frame(width: 124, height: 32)
                .dxFade(delay: 0.3)
                GlimView(mood: .cheer, stage: 1, points: 110)
                    .dxBob()
                    .dxSettle(delay: 0.2)
                    .padding(.bottom, 18)
            }
            .offset(x: 128, y: 96)
            .accessibilityHidden(true)
        }
        .frame(height: 360)
        .padding(.top, -60)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(nights) nights checked in"))
    }

    private func progressWord(_ done: Int, of total: Int) -> String {
        let p = Double(done) / Double(max(total, 1))
        if p >= 0.5 && p < 0.6 { return String(localized: "Halfway") }
        let left = total - done
        return left == 1 ? String(localized: "1 to go") : String(localized: "\(left) to go")
    }
}

/// The bar to the next night badge (055): cream on the track, sweeping in on arrival.
private struct NightBar: View {
    let value: Double
    @State private var shown = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.14))
                Capsule().fill(Color(hex: 0xF3E7CC)).frame(width: geo.size.width * (shown ? min(max(value, 0.03), 1) : 0))
            }
        }
        .frame(height: 8)
        .onAppear { withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.9).delay(0.6)) { shown = true } }
        .accessibilityHidden(true)
    }
}
