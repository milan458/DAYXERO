import DayXeroCore
import SwiftData
import SwiftUI

/// After a slip (F15, quiet tier on the reading ground): Jelli thanks them, nothing resets, and one
/// if-then plan for next time. What happened (product, amount, when) is optional, after the plan.
/// The slip is already saved when this opens; every step only adds details.
struct SlipFlow: View {
    /// The slip being talked through. nil only if saving failed; the screens still work.
    let entry: LogEntry?
    let profile: UserProfile?
    let onDone: () -> Void
    /// Opened again later (Progress, the check-in). The same screens; kept for the call sites.
    var startInTalkThrough = false
    /// Program v2's Day 27 rehearsal: the same screens with a "Practice" tag, and nothing logged.
    var practice = false

    /// Step 1 was telling us (SOS or the log), so the plan is step 2 of 3 and "Plan saved" is step 3.
    enum Stage: Int, CaseIterable {
        case talk = 2, done = 3, what = 4
    }

    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<LogEntry> { $0.kindRaw == "slip" }) private var slips: [LogEntry]
    @State private var stage = Stage.talk
    @State private var product: Product?
    @State private var amount: SlipAmount?
    @State private var when = Slips.When.justNow
    @State private var trigger: Trigger?
    @State private var action: String?
    @State private var ownAction = ""
    @State private var writingOwn = false
    @State private var showNRT = false
    @State private var showQuitDay = false
    @State private var freshStartDismissed = false
    @State private var savedFeedback = false
    private let loggedAt: Date

    private let ground = DX.Ground.reading

    init(entry: LogEntry?, profile: UserProfile?, startInTalkThrough: Bool = false, practice: Bool = false,
         onDone: @escaping () -> Void) {
        self.entry = practice ? nil : entry
        self.profile = profile
        self.startInTalkThrough = startInTalkThrough
        self.practice = practice
        self.onDone = onDone
        loggedAt = entry?.timestamp ?? .now
        var start = Stage.talk
        #if DEBUG
        if let raw = UserDefaults.standard.string(forKey: "dx.slipStage"),
           let debug = Stage.allCases.first(where: { "\($0)" == raw }) { start = debug }
        #endif
        _stage = State(initialValue: start)
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            if practice {
                Label("Practice · nothing is logged", systemImage: "figure.walk.motion")
                    .dxType(.caption).textCase(.uppercase)
                    .foregroundStyle(ground.muted)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .overlay(Capsule().strokeBorder(ground.muted, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])))
                    .padding(.top, DX.Space.xs)
            }
            switch stage {
            case .talk: talk
            case .what: what
            case .done: done
            }
        }
        .foregroundStyle(ground.ink)
        .background(ground.background.ignoresSafeArea())
        .animation(DX.Move.animation(DX.Move.settle, reduceMotion: false), value: stage)
        .sensoryFeedback(DX.Haptic.commit, trigger: savedFeedback)
        .onAppear(perform: prefill)
        .fullScreenCover(isPresented: $showNRT) {
            if let profile { NRTSetupView(profile: profile) { showNRT = false } }
        }
        .sheet(isPresented: $showQuitDay) {
            // Settings › Quit Day sets the new date; logs, plans and history are untouched.
            if let profile { SettingsSheet(profile: profile, start: .quitDay) }
        }
    }

    // MARK: Top bar: close, and the three-step bar

    private var topBar: some View {
        HStack(spacing: 10) {
            Button {
                if stage == .what { stage = .done } else { onDone() }
            } label: {
                Image(systemName: stage == .what ? "chevron.left" : "xmark")
                    .font(.system(size: 18, weight: .bold))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(stage == .what ? Text("Back") : Text("Close. The slip is saved."))
            HStack(spacing: 6) {
                ForEach(1...3, id: \.self) { i in
                    Capsule().fill(i <= min(stage.rawValue, 3) ? ground.ink : DX.Fill.surface).frame(height: 6)
                }
            }
            .accessibilityElement()
            .accessibilityLabel(Text("Step \(min(stage.rawValue, 3)) of 3"))
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 10)
        .padding(.top, DX.Space.xs)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    // MARK: F15 Thanks, nothing resets, and a plan

    private var talk: some View {
        let situation = String(localized: (trigger ?? .other).situation)
        return VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 14) {
                        JelliView(mood: .calm, stage: 2, size: .card)
                            .frame(width: 88, height: 88)
                            .background(DX.Ground.ocean.background, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("With Jelli").dxFont(14, weight: 700, style: .footnote).foregroundStyle(ground.muted)
                            // Plain title: the hand-drawn mark is kept for celebrations (S27.15).
                            Text("Thanks for\ntelling me.")
                                .dxType(.large)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityAddTraits(.isHeader)
                        }
                    }
                    .dxArrive(0)
                    Text(isPrep
                         ? String(localized: "Logged. Prep is for learning your patterns, and this helps. Let's make a plan for next time.")
                         : String(localized: "Waves come and go. Nothing resets: your days since Quit Day and Xero's sky stay just as they are. Let's make a plan for next time."))
                        .dxType(.body)
                        .foregroundStyle(ground.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .dxArrive(1)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What set it off?").dxFont(16, weight: 700, style: .body)
                        TriggerPicker(mine: profile?.triggers ?? [], selection: $trigger)
                        Text("If it's \(situation), then I'll…")
                            .dxFont(19, weight: 700, style: .headline)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 4)
                        VStack(spacing: 8) {
                            ForEach(suggestions, id: \.self) { idea in
                                ThenOption(text: idea, isOn: !writingOwn && action == idea) {
                                    action = idea
                                    writingOwn = false
                                }
                            }
                            ThenOption(text: String(localized: "write my own"), isOn: writingOwn) { writingOwn = true }
                            if writingOwn {
                                TextField("", text: $ownAction, prompt: Text("go for a run").foregroundStyle(ground.muted))
                                    .dxFont(16, weight: 500, style: .body)
                                    .padding(.horizontal, 14)
                                    .frame(minHeight: 48)
                                    .background(DX.Fill.surface, in: RoundedRectangle(cornerRadius: DX.Layout.answerChipRadius, style: .continuous))
                                    .accessibilityLabel(Text("Then I'll"))
                            }
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel(Text("Then I will"))
                    }
                    .padding(16)
                    .background(DX.Fill.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: Color(light: (0x1E1A3A, 0.07), dark: (0x000000, 0)), radius: 11, y: 8)
                    .dxArrive(2)
                }
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.top, 14)
                .padding(.bottom, DX.Space.m)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
            VStack(spacing: 4) {
                Button("Save my plan") { savePlan() }
                    .buttonStyle(.dx(.primary, on: .reading))
                    .disabled(chosenAction == nil)
                Button("Not now", action: onDone)
                    .buttonStyle(.dx(.quiet, on: .reading))
            }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .padding(.horizontal, DX.Layout.buttonGutter)
            .padding(.bottom, DX.Space.xs)
            .dxArrive(4)
        }
        .onChange(of: trigger) { _, _ in
            // A different trigger has its own ideas; keep a plan they wrote themselves.
            if !writingOwn, let action, !suggestions.contains(action) { self.action = nil }
        }
    }

    // MARK: Plan saved

    private var done: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Plan saved").dxType(.large).accessibilityAddTraits(.isHeader).dxArrive(0)
                    Text("Every slip shows you something about your cravings. Now you've got a plan for this one.")
                        .dxType(.body).foregroundStyle(ground.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .dxArrive(1)
                    if let action = entry?.nextTime ?? chosenAction {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("YOUR PLAN").dxType(.caption).foregroundStyle(ground.muted)
                            Text("If it's \(String(localized: (trigger ?? .other).situation)), then I'll \(action).")
                                .dxFont(19, weight: 700, style: .headline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .dxReadingCard(radius: 22)
                        .accessibilityElement(children: .combine)
                        .dxArrive(2)
                    }
                    Label {
                        Text(isPrep ? String(localized: "Prep carries on as planned.")
                             : String(localized: "Still Day \(daysClear) since your Quit Day. Nothing resets."))
                            .dxType(.footnote)
                    } icon: {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(DX.Fill.green)
                    }
                    .dxArrive(3)
                    if Slips.isToughDay(slipsToday: slipsToday) { toughDay.dxArrive(4) }
                    if offersFreshStart, !freshStartDismissed { freshStart.dxArrive(5) }
                }
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.top, DX.Space.l)
                .padding(.bottom, DX.Space.m)
            }
            .scrollBounceBehavior(.basedOnSize)
            VStack(spacing: 4) {
                Button("Back to Today", action: onDone)
                    .buttonStyle(.dx(.primary, on: .reading))
                if entry != nil {
                    Button("Add what happened · optional") { stage = .what }
                        .buttonStyle(.dx(.quiet, on: .reading))
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .padding(.horizontal, DX.Layout.buttonGutter)
            .padding(.bottom, DX.Space.xs)
        }
    }

    /// From the third slip in a day: NRT or another look at the plan, never starting over.
    private var toughDay: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("It's been a tough day. That happens, especially early on. A patch plus gum or a lozenge takes the edge off better than one alone. Want to look at NRT, or go over your plan again?")
                .dxType(.footnote)
                .fixedSize(horizontal: false, vertical: true)
            ViewThatFits {
                HStack(spacing: 8) { nrtButton; replanButton }
                VStack(spacing: 8) { nrtButton; replanButton }
            }
        }
        .dxReadingCard(radius: 22)
    }

    /// After slips on 4 of the last 7 days (S27.9): Jelli offers a fresh Quit Day. Picking one keeps every log;
    /// "Keep going as I am" just hides the card.
    private var freshStart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FROM JELLI").dxType(.caption).foregroundStyle(ground.muted)
            Text("You've slipped on four of the last seven days. That's information, not failure. Want to pick a fresh Quit Day? Everything you've learned and logged stays.")
                .dxType(.footnote)
                .fixedSize(horizontal: false, vertical: true)
            ViewThatFits {
                HStack(spacing: 8) { freshPickButton; freshKeepButton }
                VStack(alignment: .leading, spacing: 8) { freshPickButton; freshKeepButton }
            }
        }
        .dxReadingCard(radius: 22)
    }

    private var freshPickButton: some View {
        V4Chip(text: String(localized: "Pick a fresh Quit Day"), isOn: false, fill: DX.Fill.raised, ink: DX.Ground.reading.ink) {
            showQuitDay = true
        }
    }

    private var freshKeepButton: some View {
        V4Chip(text: String(localized: "Keep going as I am"), isOn: false, fill: DX.Fill.raised, ink: DX.Ground.reading.ink) {
            freshStartDismissed = true
        }
    }

    // The card is DX.Fill.surface, so its chips sit on DX.Fill.raised to stand out (reading ink clears 4.5:1 on it).
    private var nrtButton: some View {
        V4Chip(text: String(localized: "Look at NRT"), isOn: false, fill: DX.Fill.raised, ink: DX.Ground.reading.ink) { showNRT = true }
    }

    private var replanButton: some View {
        V4Chip(text: String(localized: "Go over my plan"), isOn: false, fill: DX.Fill.raised, ink: DX.Ground.reading.ink) { stage = .talk }
    }

    // MARK: What happened (optional)

    private var what: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("What happened?").dxType(.large).accessibilityAddTraits(.isHeader)
                    Text("No judgement, just the facts so we can plan.").dxType(.body).foregroundStyle(ground.muted)
                    if products.count > 1 {
                        label("What did you have?")
                        DXFlowLayout(spacing: 8) {
                            ForEach(products, id: \.self) { p in
                                V4Chip(text: String(localized: p.title), isOn: product == p) { product = p }
                            }
                        }
                    }
                    label("How much?")
                    DXFlowLayout(spacing: 8) {
                        V4Chip(text: amountTitle(.aLittle), isOn: amount == .aLittle) { amount = amount == .aLittle ? nil : .aLittle }
                        V4Chip(text: amountTitle(.one), isOn: amount == .one) { amount = amount == .one ? nil : .one }
                        V4Chip(text: String(localized: "More"), isOn: amount == .more) { amount = amount == .more ? nil : .more }
                    }
                    label("When?")
                    DXFlowLayout(spacing: 8) {
                        ForEach(Slips.When.allCases, id: \.self) { w in
                            V4Chip(text: whenTitle(w), isOn: when == w) { when = w }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.top, DX.Space.l)
                .padding(.bottom, DX.Space.m)
                // Save sits right under the last row of chips, not pinned to the bottom (S27.14).
                Button("Save") { saveDetails() }
                    .buttonStyle(.dx(.primary, on: .reading))
                    .padding(.horizontal, DX.Layout.buttonGutter)
                    .padding(.bottom, DX.Space.xl)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    // MARK: Pieces

    private func label(_ text: LocalizedStringKey) -> some View {
        Text(text).dxType(.caption).textCase(.uppercase).foregroundStyle(ground.muted).padding(.top, DX.Space.s)
    }

    private func amountTitle(_ value: SlipAmount) -> String {
        switch value {
        case .aLittle: product == .cigarettes ? String(localized: "A few drags") : product == .pouches ? String(localized: "Briefly") : String(localized: "A few puffs")
        case .one: product == .cigarettes ? String(localized: "One") : product == .pouches ? String(localized: "One pouch") : String(localized: "One session")
        case .more: String(localized: "More")
        }
    }

    private func whenTitle(_ w: Slips.When) -> String {
        switch w {
        case .justNow: String(localized: "Just now")
        case .earlierToday: String(localized: "Earlier today")
        case .yesterday: String(localized: "Yesterday")
        }
    }

    // MARK: Data

    private var suggestions: [String] {
        (trigger ?? .other).nextTimeSuggestions.map { String(localized: $0) }
    }

    private var products: [Product] {
        (profile?.products ?? []).sorted { ($0.isPrimary ? 0 : 1) < ($1.isPrimary ? 0 : 1) }.map(\.product)
    }

    private var chosenAction: String? {
        if writingOwn {
            let text = ownAction.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : text
        }
        return action
    }

    private var clock: DayClock { DayClock(boundaryHour: profile?.dayBoundaryHour ?? 4) }

    private var stats: ProgressStats? {
        profile.map { ProgressStats(quitDay: $0.quitDay, baselines: [], clock: clock) }
    }

    private var isPrep: Bool { stats?.isPrep(at: .now) ?? false }
    private var daysClear: Int { stats?.daysClear(at: .now) ?? 0 }

    private var slipsToday: Int {
        Slips.count(onDayOf: .now, timestamps: slips.map(\.timestamp), clock: clock)
    }

    /// Practice runs never offer it, and neither does prep.
    private var offersFreshStart: Bool {
        guard !practice, !isPrep, let profile else { return false }
        return Slips.offersFreshStart(timestamps: slips.map(\.timestamp), quitDay: profile.quitDay, now: .now, clock: clock)
    }

    private func prefill() {
        product = entry?.product ?? products.first
        guard let entry else { return }
        amount = entry.amount
        trigger = entry.trigger
        if let next = entry.nextTime {
            if (entry.trigger ?? .other).nextTimeSuggestions.map({ String(localized: $0) }).contains(next) {
                action = next
            } else {
                ownAction = next
                writingOwn = true
            }
        }
        #if DEBUG
        if UserDefaults.standard.string(forKey: "dx.slipStage") != nil || UserDefaults.standard.string(forKey: "dx.sosOutcome") != nil {
            trigger = trigger ?? profile?.triggers.first
            if action == nil, !writingOwn {
                let ideas = (trigger ?? .other).nextTimeSuggestions.map { String(localized: $0) }
                action = ideas.count > 2 ? ideas[2] : ideas.first
            }
            amount = amount ?? .one
        }
        #endif
    }

    /// Saves the trigger and the plan. Choosing a plan is the only thing this flow asks for.
    private func savePlan() {
        guard let chosen = chosenAction else { return }
        if let entry {
            entry.triggerRaw = trigger?.rawValue
            entry.nextTime = chosen
            context.insert(IfThenPlan(situation: String(localized: (trigger ?? .other).situation), action: chosen))
            try? context.save()
        }
        savedFeedback.toggle()
        stage = .done
    }

    private func saveDetails() {
        if let entry {
            entry.productRaw = (product ?? entry.product)?.rawValue
            entry.amount = amount
            entry.timestamp = Slips.time(when, loggedAt: loggedAt, clock: clock)
            try? context.save()
        }
        stage = .done
    }
}

/// One "then I'll…" choice as a radio row: ink when chosen, with a green dot.
private struct ThenOption: View {
    let text: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(verbatim: text)
                    .dxFont(16, weight: 600, style: .body)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                Circle()
                    .strokeBorder(isOn ? DX.Fill.green : DX.Ground.reading.muted, lineWidth: isOn ? 6 : 2)
                    .background(Circle().fill(isOn ? Color(hex: 0x2FD08A) : .clear))
                    .frame(width: 22, height: 22)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(isOn ? DX.Ground.reading.background : DX.Ground.reading.ink)
            .padding(.horizontal, 14).padding(.vertical, 12)
            .frame(minHeight: 48)
            .background(isOn ? DX.Ground.reading.ink : DX.Fill.surface,
                        in: RoundedRectangle(cornerRadius: DX.Layout.answerChipRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(DX.Haptic.select, trigger: isOn)
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
    }
}

/// "If it's …, then I'll …" as saved. Shown on Home for the rest of that day, and after a lesson.
struct PlanCard: View {
    let situation: String
    let action: String
    var title: LocalizedStringKey = "Your plan"

    var body: some View {
        V4Card(padding: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title).v4Text(.subtitle)
                Text("If it's \(Text(verbatim: situation).dxFont(16, weight: 600, style: .body)), then I'll \(Text(verbatim: action).dxFont(16, weight: 600, style: .body))")
                    .dxFont(16, weight: 400, style: .body)
                    .foregroundStyle(Read4.ink)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}
