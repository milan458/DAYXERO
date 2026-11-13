import DayXeroCore
import SwiftData
import SwiftUI

/// Motion (021): Quiet tier, no springs. The paper-cut sea card builds back to front while Jelli (calm) settles down
/// into the water (900ms), then keeps a slow bob, half in the sea. The title and the progress note arrive with a 90ms
/// stagger, then the if-then line and its option rows settle in one by one (120ms apart); the chosen row carries the
/// kit's warm selection and its tick. On Save the button turns to its done state and a soft success haptic plays.
///
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
    private let motion = MotionPolicy()

    /// Step 1 was telling us (SOS or the log), so the plan is step 2 of 3 and "Plan saved" is step 3.
    enum Stage: Int, CaseIterable {
        case talk = 2, done = 3, what = 4
    }

    @Environment(\.modelContext) private var context
    @Environment(Entitlement.self) private var entitlement: Entitlement?
    @Query(filter: #Predicate<LogEntry> { $0.kindRaw == "slip" }) private var slips: [LogEntry]
    @State private var showPaywall = false
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
                    .dxType(.caption)
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
        .dxGround(.reading, paint: false)
        .animation(motion.animation(DX.Move.settle), value: stage)
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
                if stage == .what { stage = plansUnlocked ? .done : .talk } else { onDone() }
            } label: {
                DXIcon(stage == .what ? .back : .close, size: 20, weight: 2.4)
                    .frame(width: 44, height: 44)
                    .background(ground.card2, in: Circle())
            }
            .buttonStyle(.dxPress)
            .accessibilityLabel(stage == .what ? Text("Back") : Text("Close. The slip is saved."))
            HStack(spacing: 5) {
                ForEach(1...3, id: \.self) { i in
                    Capsule().fill(i <= min(stage.rawValue, 3) ? ground.ink : ground.track).frame(height: 6)
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
                    // v5 (021): Jelli half in a paper-cut sea, then the title.
                    SlipSeaCard()
                        .frame(height: 178)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("With Jelli").dxType(.footnote).foregroundStyle(ground.muted)
                        // Plain title: the hand-drawn mark is kept for celebrations (S27.15).
                        Text("Thanks for\ntelling me.")
                            .dxType(.title)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                    }
                    .padding(.top, 6)
                    .dxArrive(0)
                    Text(talkLine)
                        .dxType(.body)
                        .foregroundStyle(ground.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .dxArrive(1)
                    if !plansUnlocked {
                        // MON-01: the slip is logged and nothing resets for everyone; the if-then plan is paid.
                        LockedFeatureCard(title: "Plan for next time",
                                          line: "If-then slip plans come with the full program: pick what set it off and what you'll do instead, and it's on Craving SOS next time.") {
                            showPaywall = true
                        }
                        .dxArrive(2)
                        if offersFreshStart, !freshStartDismissed { freshStart.dxArrive(3) }
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("What set it off?").dxType(.headline)
                            TriggerPicker(mine: profile?.triggers ?? [], selection: $trigger)
                            Text("If it's \(situation), then I'll…")
                                .dxType(.headline)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 8)
                            VStack(spacing: 10) {
                                ForEach(Array(suggestions.enumerated()), id: \.element) { index, idea in
                                    ThenOption(text: idea, isOn: !writingOwn && action == idea) {
                                        action = idea
                                        writingOwn = false
                                    }
                                    .dxSettle(index, delay: 0.3)
                                }
                                ThenOption(text: String(localized: "write my own"), isOn: writingOwn) { writingOwn = true }
                                if writingOwn {
                                    TextField("", text: $ownAction, prompt: Text("go for a run").foregroundStyle(ground.muted))
                                        .textFieldStyle(.dx)
                                        .accessibilityLabel(Text("Then I'll"))
                                }
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel(Text("Then I will"))
                        }
                        .dxArrive(2)
                    }
                }
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.top, 14)
                .padding(.bottom, DX.Space.m)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
            VStack(spacing: 4) {
                if plansUnlocked {
                    Button("Save my plan") { savePlan() }
                        .buttonStyle(.dx(.primary, on: .reading))
                        .disabled(chosenAction == nil)
                    Button("Not now", action: onDone)
                        .buttonStyle(.dx(.quiet, on: .reading))
                } else {
                    Button("Done", action: onDone)
                        .buttonStyle(.dx(.primary, on: .reading))
                    if entry != nil {
                        Button("Add what happened · optional") { stage = .what }
                            .buttonStyle(.dx(.quiet, on: .reading))
                    }
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .padding(.horizontal, DX.Layout.buttonGutter)
            .padding(.bottom, DX.Space.xs)
            .dxArrive(4)
        }
        .fullProgramPaywall(isPresented: $showPaywall, profile: profile)
        .onChange(of: trigger) { _, _ in
            // A different trigger has its own ideas; keep a plan they wrote themselves.
            if !writingOwn, let action, !suggestions.contains(action) { self.action = nil }
        }
    }

    /// The if-then planner is part of the full program (MON-01). The practice run inside the paid Day 28 session
    /// always has it.
    private var plansUnlocked: Bool {
        practice || FullProgram.has(.ifThenPlanner, isPro: entitlement?.isPro ?? Entitlement.isProNow)
    }

    private var talkLine: String {
        let base = isPrep
            ? String(localized: "Logged. Prep is for learning your patterns, and this helps.")
            : String(localized: "Waves come and go. Nothing resets: your days since Quit Day and Xero's sky stay just as they are.")
        return plansUnlocked ? base + " " + String(localized: "Let's make a plan for next time.") : base
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
                            Text("Your plan").dxType(.caption).foregroundStyle(ground.muted)
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
            Text("From Jelli").dxType(.caption).foregroundStyle(ground.muted)
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
        Text(text).dxType(.footnote).foregroundStyle(ground.muted).padding(.top, DX.Space.s)
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
        // Without the planner there's no "Plan saved" to go back to (MON-01).
        if plansUnlocked { stage = .done } else { onDone() }
    }
}

/// One "then I'll…" choice: the kit option row with its radio and the warm selection.
private struct ThenOption: View {
    let text: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        DXOptionRow(Text(verbatim: text), isOn: isOn, on: .reading, action: action)
    }
}

/// Jelli half in a paper-cut sea (021): the sea horizon, Jelli settling into the water between the back waves and
/// the front one, then a slow bob.
struct SlipSeaCard: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let dark = scheme == .dark
        ZStack(alignment: .bottom) {
            HorizonScene(.sea, clarity: 90, fit: .bottom)
            JelliView(mood: .calm, stage: 2, points: 140)
                .frame(width: 140, height: 140)
                .dxBob(4, period: 6)
                .dxSettle()
                .offset(y: 14)
            Canvas { ctx, size in
                ctx.scaleBy(x: size.width / 346, y: size.height / 60)
                ctx.fill(SVGPath.path("M0 22 C40 8 80 8 120 20 S200 34 240 18 S310 6 346 16 V60 H0Z"),
                         with: .color(Color(hex: dark ? 0x13295F : 0x3A68C8)))
                ctx.stroke(SVGPath.path("M0 22 C40 8 80 8 120 20 S200 34 240 18 S310 6 346 16"),
                           with: .color(.white.opacity(dark ? 0.15 : 0.45)), lineWidth: 1.5)
                ctx.fill(SVGPath.path("M0 42 C50 32 110 34 170 40 S280 46 346 36 V60 H0Z"),
                         with: .color(Color(hex: dark ? 0x0E1F4C : 0x2A50AA)))
            }
            .frame(height: 60)
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}

/// "If it's …, then I'll …" as saved. Shown on Home for the rest of that day, and after a lesson.
struct PlanCard: View {
    let situation: String
    let action: String
    var title: LocalizedStringKey = "Your plan"
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        // The two answers are bold runs inside the sentence, so they need `.font` (a Text), not `.dxFont` (a view).
        let strong = DX.Typeface4.scaledFont(16, weight: 600, style: .body, dynamicTypeSize: typeSize)
        V4Card(padding: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title).v4Text(.subtitle)
                Text("If it's \(Text(verbatim: situation).font(strong)), then I'll \(Text(verbatim: action).font(strong))")
                    .dxFont(16, weight: 400, style: .body)
                    .foregroundStyle(Read4.ink)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}
