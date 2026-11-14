import DayXeroCore
import SwiftData
import SwiftUI

/// After a slip (v5, 043-046, quiet tier on the reading ground): Jelli thanks them and shows what they still have
/// (nothing resets), then one if-then plan for next time, then "Plan saved". What happened (product, amount, when) is
/// optional, after the plan. The slip is already saved when this opens; every step only adds details. Calm, no springs.
struct SlipFlow: View {
    /// The slip being talked through. nil only if saving failed; the screens still work.
    let entry: LogEntry?
    let profile: UserProfile?
    let onDone: () -> Void
    /// Opened again later (Progress, the check-in): straight to the plan.
    var startInTalkThrough = false
    /// Program v2's Day 27 rehearsal: the same screens with a "Practice" tag, and nothing logged.
    var practice = false
    private let motion = MotionPolicy()

    /// Thanks is step 1 of 3, the plan step 2, "Plan saved" step 3; what happened is an optional step after it.
    enum Stage: Int, CaseIterable {
        case thanks = 1, talk = 2, done = 3, what = 4
    }

    @Environment(\.modelContext) private var context
    @Environment(Entitlement.self) private var entitlement: Entitlement?
    @Environment(SOSRouter.self) private var sos: SOSRouter?
    @Query(filter: #Predicate<LogEntry> { $0.kindRaw == "slip" }) private var slips: [LogEntry]
    @State private var showPaywall = false
    @State private var stage = Stage.thanks
    @State private var product: Product?
    @State private var amount: SlipAmount?
    @State private var when = Slips.When.justNow
    @State private var trigger: Trigger?
    @State private var action: String?
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
        var start = startInTalkThrough ? Stage.talk : Stage.thanks
        #if DEBUG
        if let raw = UserDefaults.standard.string(forKey: "dx.slipStage"),
           let debug = Stage.allCases.first(where: { "\($0)" == raw }) { start = debug }
        #endif
        _stage = State(initialValue: start)
    }

    var body: some View {
        VStack(spacing: 0) {
            if stage != .what && stage != .done { topBar }
            if practice {
                Label("Practice · nothing is logged", systemImage: "figure.walk.motion")
                    .dxType(.caption)
                    .foregroundStyle(ground.muted)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .overlay(Capsule().strokeBorder(ground.muted, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])))
                    .padding(.top, DX.Space.xs)
            }
            Group {
                switch stage {
                case .thanks: thanks
                case .talk: talk
                case .what: what
                case .done: done
                }
            }
            .id(stage)
            .transition(.opacity)
        }
        .foregroundStyle(ground.ink)
        .background(ground.background.ignoresSafeArea())
        .dxGround(.reading, paint: false)
        .animation(motion.animation(.easeInOut(duration: 0.3)), value: stage)
        .sensoryFeedback(DX.Haptic.commit, trigger: savedFeedback)
        .onAppear(perform: prefill)
        .fullScreenCover(isPresented: $showNRT) {
            if let profile { NRTSetupView(profile: profile) { showNRT = false } }
        }
        .sheet(isPresented: $showQuitDay) {
            // Settings › Quit Day sets the new date; logs, plans and history are untouched.
            if let profile { SettingsSheet(profile: profile, start: .quitDay) }
        }
        .fullProgramPaywall(isPresented: $showPaywall, profile: profile)
    }

    // MARK: Top bar: close, and the three-step bar

    private var topBar: some View {
        HStack(spacing: 12) {
            DXIconButton(.close, label: "Close. The slip is saved.", action: onDone)
            HStack(spacing: 5) {
                ForEach(1...3, id: \.self) { i in
                    Capsule().fill(i <= stage.rawValue ? ground.ink : ground.track).frame(height: 6)
                }
            }
            .accessibilityElement()
            .accessibilityLabel(Text("Step \(stage.rawValue) of 3"))
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private func dock<A: View>(@ViewBuilder _ buttons: () -> A) -> some View {
        VStack(spacing: 4) { buttons() }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .padding(.horizontal, DX.Layout.buttonGutter)
            .padding(.bottom, DX.Space.xs)
    }

    // MARK: 043 Thanks, and what you still have

    private var thanks: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SlipSeaCard()
                        .frame(height: 266)
                        .accessibilityHidden(true)
                        .dxArrive(0, delay: 0)
                    Text("Thanks for telling me.")
                        .dxType(.large)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.top, 28)
                        .dxArrive(1, delay: 0)
                    Text(isPrep ? String(localized: "Logged. Prep is for learning your patterns, and this helps.")
                         : String(localized: "Nothing resets. Here's what you still have."))
                        .dxType(.body).foregroundStyle(ground.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 10)
                        .dxArrive(2, delay: 0)
                    if !isPrep, let profile {
                        HStack(alignment: .top, spacing: 10) {
                            SinceQuitTile(quitDay: profile.quitDay, days: daysClear).dxArrive(3, delay: 0)
                            SkyTile(clarity: CrewGrowth.clarity(daysClear: daysClear)).dxArrive(4, delay: 0)
                        }
                        .padding(.top, 24)
                        Text("Slips don't cloud it.")
                            .dxType(.footnote).foregroundStyle(ground.muted)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 14)
                            .dxArrive(5, delay: 0)
                    }
                }
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.top, 10)
                .padding(.bottom, DX.Space.m)
            }
            .scrollBounceBehavior(.basedOnSize)
            dock {
                Button("Make a one-minute plan") { stage = .talk }
                    .buttonStyle(.dx(.primary, on: .reading))
                    .dxArrive(6, delay: 0)
                Button("Not now", action: onDone)
                    .buttonStyle(.dx(.quiet, on: .reading))
                    .dxArrive(7, delay: 0)
            }
        }
    }

    // MARK: 044 The moment and what to do instead

    private var talk: some View {
        let situation = String(localized: (trigger ?? .other).situation)
        return VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center, spacing: 12) {
                        Text("Pick the moment and what to do instead.")
                            .dxType(.title)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .dxArrive(0, delay: 0)
                        JelliSeaDisc(size: 84).dxSettle(delay: 0.2)
                    }
                    .padding(.top, 14)
                    if !plansUnlocked {
                        // MON-01: the slip is logged and nothing resets for everyone; the if-then plan is paid.
                        LockedFeatureCard(title: "Plan for next time",
                                          line: "If-then slip plans come with the full program: pick what set it off and what you'll do instead, and it's on Craving SOS next time.") {
                            showPaywall = true
                        }
                        .padding(.top, 26)
                        .dxArrive(2, delay: 0)
                        if offersFreshStart, !freshStartDismissed { freshStart.padding(.top, 12).dxArrive(3, delay: 0) }
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What set it off?").dxType(.headline).dxArrive(2, delay: 0)
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible())], spacing: 8) {
                                ForEach(triggerChoices, id: \.self) { t in triggerChip(t) }
                            }
                            .dxArrive(3, delay: 0)
                        }
                        .padding(.top, 26)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("If it's \(situation), then I'll...")
                                .dxType(.headline)
                                .fixedSize(horizontal: false, vertical: true)
                                .dxArrive(4, delay: 0)
                            VStack(spacing: 8) {
                                ForEach(Array(suggestions.enumerated()), id: \.element) { index, idea in
                                    ThenOption(text: idea, isOn: action == idea) { action = idea }
                                        .dxArrive(5 + index, delay: 0)
                                }
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel(Text("Then I will"))
                            if let sos {
                                HStack(spacing: 6) {
                                    Text("Craving right now?").dxFont(15, weight: 500, style: .subheadline).foregroundStyle(ground.muted)
                                    Button {
                                        onDone()
                                        sos.open(source: "slip")
                                    } label: {
                                        Text("Open Craving SOS").dxFont(15, weight: 700, style: .subheadline)
                                            .foregroundStyle(ground.ink)
                                            .padding(.bottom, 3)
                                            .overlay(alignment: .bottom) { Capsule().fill(DX.Mark.color(on: .reading)).frame(height: 2) }
                                            .frame(minHeight: 36)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.top, 6)
                                .dxArrive(8, delay: 0)
                            }
                        }
                        .padding(.top, 26)
                    }
                }
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.bottom, DX.Space.m)
            }
            .scrollBounceBehavior(.basedOnSize)
            dock {
                if plansUnlocked {
                    Button("Save my plan") { savePlan() }
                        .buttonStyle(.dx(.primary, on: .reading))
                        .disabled(action == nil)
                        .dxArrive(10, delay: 0)
                    Button("Not now", action: onDone)
                        .buttonStyle(.dx(.quiet, on: .reading))
                        .dxArrive(11, delay: 0)
                } else {
                    Button("Done", action: onDone)
                        .buttonStyle(.dx(.primary, on: .reading))
                    if entry != nil {
                        Button("Add what happened") { stage = .what }
                            .buttonStyle(.dx(.quiet, on: .reading))
                    }
                }
            }
        }
        .onChange(of: trigger) { _, _ in
            // A different trigger has its own ideas.
            if let action, !suggestions.contains(action) { self.action = nil }
        }
    }

    /// Three triggers (yours first) and "Something else".
    private var triggerChoices: [Trigger] {
        var head: [Trigger] = []
        for t in (profile?.triggers ?? []) + [.coffee, .stress, .meals] where t != .other && !head.contains(t) { head.append(t) }
        var list = Array(head.prefix(3))
        if let trigger, trigger != .other, !list.contains(trigger) { list[list.count - 1] = trigger }
        return list + [.other]
    }

    private func triggerTitle(_ t: Trigger) -> String {
        switch t {
        case .meals: String(localized: "After a meal")
        case .other: String(localized: "Something else")
        default: String(localized: t.title)
        }
    }

    /// The chosen trigger is an outline only, so the chosen plan row is the screen's one filled selection.
    private func triggerChip(_ t: Trigger) -> some View {
        let on = trigger == t
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        return Button { trigger = t } label: {
            Text(verbatim: triggerTitle(t)).dxFont(15, weight: 600, style: .subheadline).foregroundStyle(ground.ink)
                .lineLimit(1).minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(ground.card, in: shape)
                .overlay(shape.strokeBorder(on ? ground.selEdge : ground.line, lineWidth: on ? 2 : 1))
                .contentShape(shape)
        }
        .buttonStyle(.dxPress)
        .sensoryFeedback(DX.Haptic.select, trigger: on)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    /// The if-then planner is part of the full program (MON-01). The practice run inside the paid Day 28 session
    /// always has it.
    private var plansUnlocked: Bool {
        practice || FullProgram.has(.ifThenPlanner, isPro: entitlement?.isPro ?? Entitlement.isProNow)
    }

    // MARK: 046 Plan saved

    private var done: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    JelliDoneDisc()
                        .frame(width: 188, height: 188)
                        .padding(.top, 44)
                        .accessibilityHidden(true)
                    MarkedTitle("Plan ", marking: String(localized: "saved"), color: DX.Mark.color(on: .reading))
                        .dxType(.large)
                        .padding(.top, 40)
                        .dxArrive(2, delay: 0)
                    Text("Every slip shows you something.\nNow you have a plan for this one.")
                        .dxType(.body).foregroundStyle(ground.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 7)
                        .dxArrive(3, delay: 0)
                    if let action = entry?.nextTime ?? action {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 7) {
                                PlanPathGlyph().frame(width: 18, height: 18)
                                Text(verbatim: planFor)
                            }
                            .dxType(.footnote).foregroundStyle(ground.muted)
                            Text("If it's \(String(localized: (trigger ?? .other).situation)), then I'll \(action).")
                                .dxFont(17, weight: 600, style: .body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .dxCardChrome(on: .reading)
                        .accessibilityElement(children: .combine)
                        .padding(.top, 26)
                        .dxSettle(4, delay: 0.2)
                    }
                    HStack(spacing: 10) {
                        if !isPrep { DXBadge(.day, n: daysClear, size: 36) }
                        Group {
                            if isPrep {
                                Text("Prep carries on as planned.")
                            } else {
                                Text("\(Text("Still Day \(daysClear).").foregroundStyle(ground.ink).font(DX.Typeface4.swiftUIFont(.body, size: 15, weight: 700))) Nothing resets.")
                            }
                        }
                        .dxType(.footnote).foregroundStyle(ground.muted)
                    }
                    .padding(.top, 18)
                    .dxArrive(7, delay: 0)
                    if Slips.isToughDay(slipsToday: slipsToday) { toughDay.padding(.top, 18) }
                    if offersFreshStart, !freshStartDismissed { freshStart.padding(.top, 12) }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.bottom, DX.Space.m)
            }
            .scrollBounceBehavior(.basedOnSize)
            dock {
                Button("Back to Today", action: onDone)
                    .buttonStyle(.dx(.primary, on: .reading))
                    .dxArrive(8, delay: 0)
                if entry != nil {
                    Button("Add what happened") { stage = .what }
                        .buttonStyle(.dx(.quiet, on: .reading))
                        .dxArrive(9, delay: 0)
                }
            }
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
        .frame(maxWidth: .infinity, alignment: .leading)
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
        .frame(maxWidth: .infinity, alignment: .leading)
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

    // MARK: 045 What happened (optional)

    private var what: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("What happened?").dxType(.title).accessibilityAddTraits(.isHeader)
                                .dxArrive(1, delay: 0)
                            Text("No judgement. Just the facts,\nso the plan fits.").dxType(.footnote).foregroundStyle(ground.muted)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 8)
                                .dxArrive(2, delay: 0)
                            HStack(spacing: 6) {
                                DXIcon(.lock, size: 16)
                                Text("Only you see this.")
                            }
                            .dxType(.footnote).foregroundStyle(ground.muted)
                            .padding(.top, 8)
                            .dxArrive(3, delay: 0)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        JelliSeaDisc(size: 84).dxSettle(delay: 0.2)
                    }
                    VStack(alignment: .leading, spacing: 46) {
                        if products.count > 1 {
                            question("What did you have?", options: products.map { p in
                                (String(localized: p.title).capitalizedFirst, product == p, { product = p })
                            })
                            .dxArrive(4, delay: 0)
                        }
                        question("How much?", options: SlipAmount.allCases.map { a in
                            (amountTitle(a), amount == a, { amount = amount == a ? nil : a })
                        })
                        .dxArrive(5, delay: 0)
                        question("When?", options: Slips.When.allCases.map { w in
                            (whenTitle(w), when == w, { when = w })
                        })
                        .dxArrive(6, delay: 0)
                    }
                    .padding(.top, 40)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.top, 20)
                .padding(.bottom, DX.Space.m)
            }
            .scrollBounceBehavior(.basedOnSize)
            dock {
                Button("Save") { saveDetails() }
                    .buttonStyle(.dx(.primary, on: .reading))
                    .dxArrive(7, delay: 0)
                Button("Skip") { if plansUnlocked { stage = .done } else { onDone() } }
                    .buttonStyle(.dx(.quiet, on: .reading))
                    .dxArrive(8, delay: 0)
            }
        }
    }

    private func question(_ title: LocalizedStringKey, options: [(String, Bool, () -> Void)]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).dxFace(.display, 17, weight: 700, tracking: -0.2).accessibilityAddTraits(.isHeader)
            HStack(spacing: 8) {
                ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                    let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
                    Button(action: option.2) {
                        Text(verbatim: option.0).dxFont(15, weight: 600, style: .subheadline).foregroundStyle(ground.ink)
                            .lineLimit(1).minimumScaleFactor(0.75)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(option.1 ? ground.selTint : ground.card, in: shape)
                            .overlay(shape.strokeBorder(option.1 ? ground.selEdge : ground.line, lineWidth: option.1 ? 2 : 1))
                            .contentShape(shape)
                    }
                    .buttonStyle(.dxPress)
                    .sensoryFeedback(DX.Haptic.select, trigger: option.1)
                    .accessibilityAddTraits(option.1 ? .isSelected : [])
                }
            }
        }
    }

    private func amountTitle(_ value: SlipAmount) -> String {
        switch value {
        case .aLittle: product == .cigarettes ? String(localized: "A few drags") : product == .pouches ? String(localized: "Briefly") : String(localized: "A few puffs")
        case .one: product == .cigarettes ? String(localized: "One") : product == .pouches ? String(localized: "One pouch") : String(localized: "Session")
        case .more: String(localized: "More")
        }
    }

    private func whenTitle(_ w: Slips.When) -> String {
        switch w {
        case .justNow: String(localized: "Just now")
        case .earlierToday: String(localized: "Earlier")
        case .yesterday: String(localized: "Yesterday")
        }
    }

    // MARK: Data

    /// "Your plan for coffee"; "Your plan for next time" without a trigger.
    private var planFor: String {
        guard let trigger, trigger != .other else { return String(localized: "Your plan for next time") }
        let name = trigger == .meals ? String(localized: "meals") : String(localized: trigger.title).lowercased()
        return String(localized: "Your plan for \(name)")
    }

    /// Up to three ideas for the moment; Craving SOS has its own link under them.
    private var suggestions: [String] {
        let all = (trigger ?? .other).nextTimeSuggestions.map { String(localized: $0) }
        return Array(all.filter { !$0.localizedCaseInsensitiveContains("Craving SOS") }.prefix(3))
    }

    private var products: [Product] {
        (profile?.products ?? []).sorted { ($0.isPrimary ? 0 : 1) < ($1.isPrimary ? 0 : 1) }.map(\.product)
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
        action = entry.nextTime
        #if DEBUG
        if UserDefaults.standard.string(forKey: "dx.slipStage") != nil || UserDefaults.standard.string(forKey: "dx.sosOutcome") != nil {
            trigger = trigger ?? profile?.triggers.first
            if action == nil {
                let ideas = suggestions
                action = ideas.count > 2 ? ideas[2] : ideas.first
            }
            amount = amount ?? .one
        }
        #endif
    }

    /// Saves the trigger and the plan. Choosing a plan is the only thing this flow asks for.
    private func savePlan() {
        guard let chosen = action else { return }
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

private extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}

/// One "then I'll…" choice (044): a peach duotone glyph tile, the idea, and the radio; chosen, the kit's warm
/// selection with its tick, and the tile turns white so it holds on the tint.
private struct ThenOption: View {
    let text: String
    let isOn: Bool
    let action: () -> Void
    private let ground = DX.Ground.reading

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        Button(action: action) {
            HStack(spacing: 12) {
                ThenGlyph(kind: ThenGlyph.Kind(text))
                    .frame(width: 26, height: 26)
                    .frame(width: 40, height: 40)
                    .background(isOn ? Color(light: 0xFFFFFF, dark: 0x2A3350) : ground.card2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Text(verbatim: text.prefix(1).uppercased() + text.dropFirst())
                    .dxFont(16, weight: 600, style: .body).foregroundStyle(ground.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                DXRadio(isOn: isOn, ground: .reading)
                    .scaleEffect(isOn ? 1 : 0.92)
            }
            .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 16))
            .frame(minHeight: 60)
            .background(isOn ? ground.selTint : ground.card, in: shape)
            .overlay(shape.strokeBorder(isOn ? ground.selEdge : ground.line, lineWidth: isOn ? 2 : 1))
            .contentShape(shape)
        }
        .buttonStyle(.dxPress)
        .animation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.52), value: isOn)
        .sensoryFeedback(DX.Haptic.select, trigger: isOn)
        .accessibilityLabel(Text(verbatim: text))
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

/// The duotone glyphs on the plan rows (044): a soft peach fill under an ink line.
private struct ThenGlyph: View {
    enum Kind {
        case shoe, mug, pin, wave

        init(_ text: String) {
            let t = text.lowercased()
            if t.contains("walk") || t.contains("run") || t.contains("move") || t.contains("stretch") { self = .shoe }
            else if t.contains("tea") || t.contains("water") || t.contains("drink") || t.contains("coffee") || t.contains("snack") || t.contains("eat") { self = .mug }
            else if t.contains("somewhere") || t.contains("outside") || t.contains("room") || t.contains("place") || t.contains("leave") { self = .pin }
            else { self = .wave }
        }
    }

    let kind: Kind
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Canvas { ctx, size in
            ctx.scaleBy(x: size.width / 24, y: size.height / 24)
            let dark = scheme == .dark
            let acc = Color(hex: dark ? 0xF39A62 : 0xFFB27F), acc2 = Color(hex: dark ? 0xFFD3B4 : 0xFFD9BF)
            let ink = DX.Ground.reading.ink
            let line = StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round)
            switch kind {
            case .shoe:
                ctx.fill(SVGPath.path("M2.8 17.2v-4.6c0-.8.7-1.3 1.4-1.1l3.3.9 1.9-3.6c.3-.6 1.1-.8 1.6-.4l1.3.9c.8 2 2.5 3.2 4.9 3.7l2.2.5c1.6.4 2.6 1.7 2.6 3.3v.4z"), with: .color(acc))
                ctx.fill(SVGPath.path("M2.8 17.2h18.4v1.3c0 .5-.4.9-.9.9H3.7a.9.9 0 01-.9-.9z"), with: .color(acc2))
                ctx.stroke(SVGPath.path("M2.8 17.2v-4.6c0-.8.7-1.3 1.4-1.1l3.3.9 1.9-3.6c.3-.6 1.1-.8 1.6-.4l1.3.9c.8 2 2.5 3.2 4.9 3.7l2.2.5c1.6.4 2.6 1.7 2.6 3.3v1.9c0 .5-.4.9-.9.9H3.7a.9.9 0 01-.9-.9zM2.8 17.2h18.4M9.6 10.6l1.7 1M8.7 12.3l1.7 1"), with: .color(ink), style: line)
            case .mug:
                ctx.fill(SVGPath.path("M5 9.5h11v6a4 4 0 01-4 4H9a4 4 0 01-4-4z"), with: .color(acc))
                ctx.stroke(SVGPath.path("M5 9.5h11v6a4 4 0 01-4 4H9a4 4 0 01-4-4zM16 11h1.4a2.6 2.6 0 010 5.2H16"), with: .color(ink), style: line)
                ctx.stroke(SVGPath.path("M8.6 3.6c-.9 1 .9 1.8 0 2.8M12.2 3.6c-.9 1 .9 1.8 0 2.8"), with: .color(ink.opacity(0.55)), style: line)
            case .pin:
                ctx.fill(CalmPaint.ellipse(12, 20.6, 5, 1.4), with: .color(acc2.opacity(0.7)))
                let pin = SVGPath.path("M12 20s-6.2-5.4-6.2-10.3a6.2 6.2 0 0112.4 0C18.2 14.6 12 20 12 20z")
                ctx.fill(pin, with: .color(acc))
                ctx.stroke(pin, with: .color(ink), style: line)
                let dot = CalmPaint.circle(12, 9.8, 2.4)
                ctx.fill(dot, with: .color(DX.Ground.reading.card))
                ctx.stroke(dot, with: .color(ink), style: line)
            case .wave:
                ctx.fill(SVGPath.path("M2.5 13.2c2.4-2.6 4.8-2.6 7.2 0s4.8 2.6 7.2 0c1.6-1.7 3.2-2.2 4.6-1.6v5.2a2.2 2.2 0 01-2.2 2.2H4.7a2.2 2.2 0 01-2.2-2.2z"), with: .color(acc))
                ctx.stroke(SVGPath.path("M2.5 13.2c2.4-2.6 4.8-2.6 7.2 0s4.8 2.6 7.2 0c1.6-1.7 3.2-2.2 4.6-1.6M2.5 7.4c2.4-2.6 4.8-2.6 7.2 0s4.8 2.6 7.2 0c1.6-1.7 3.2-2.2 4.6-1.6"), with: .color(ink), style: line)
            }
        }
        .accessibilityHidden(true)
    }
}

/// "Your plan for coffee": a small path from a start dot to a goal ring.
private struct PlanPathGlyph: View {
    var body: some View {
        Canvas { ctx, size in
            ctx.scaleBy(x: size.width / 24, y: size.height / 24)
            let c = DX.Ground.reading.muted
            ctx.stroke(SVGPath.path("M6.5 17.5 C11 17.5 8 11 12.5 11 S15.5 6.5 17.5 6.5"), with: .color(c), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
            ctx.fill(CalmPaint.circle(5, 18, 2.2), with: .color(c))
            ctx.stroke(CalmPaint.circle(19, 6, 2.6), with: .color(c), lineWidth: 2.2)
        }
        .accessibilityHidden(true)
    }
}

/// "Since Quit Day · 7 days" with the Day Xero sun and a tick per day (043).
private struct SinceQuitTile: View {
    let quitDay: Date
    let days: Int
    private let ground = DX.Ground.reading

    var body: some View {
        let ticks = min(max(days, 0), 9)
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                DXIcon(.calendar, size: 16, weight: 2.4)
                Text("Since Quit Day")
            }
            .dxType(.caption).foregroundStyle(ground.muted)
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                CountingText(Double(days), duration: 0.85) { String(Int($0.rounded())) }
                Text(verbatim: " " + (days == 1 ? String(localized: "day") : String(localized: "days")))
            }
            .dxFace(.display, 34, weight: 800, tracking: -0.5)
            .foregroundStyle(ground.ink)
            .lineLimit(1).minimumScaleFactor(0.7)
            HStack(spacing: 3) {
                tick(sun: true).dxFade(delay: 0.5)
                ForEach(0..<ticks, id: \.self) { i in
                    tick(today: i == ticks - 1).dxFade(delay: 0.5 + Double(i + 1) * 0.06)
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
        .dxCardChrome(on: .reading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Since Quit Day, \(days) days"))
    }

    @ViewBuilder
    private func tick(sun: Bool = false, today: Bool = false) -> some View {
        ZStack {
            if sun {
                Circle().fill(Color(hex: 0xFFD966))
                DXIcon(.sun, size: 10, weight: 2.6).foregroundStyle(Color(hex: 0x1E1A3A))
            } else if today {
                Circle().fill(ground.card).overlay(Circle().strokeBorder(ground.ink, lineWidth: 1.5))
                DXIcon(.check, size: 10, weight: 3.4).foregroundStyle(ground.ink)
            } else {
                Circle().fill(ground.card2)
                DXIcon(.check, size: 9, weight: 2.8).foregroundStyle(ground.ink.opacity(0.85))
            }
        }
        .frame(width: 14, height: 14)
    }
}

/// "Xero's sky · 40% clear" on solid cream, a tiny picture of the sky fading in from the lower right, its cloud bank
/// sliding right to show the clear part (043).
private struct SkyTile: View {
    let clarity: Int
    @State private var slid = false
    @Environment(\.colorScheme) private var scheme
    private let ground = DX.Ground.reading
    private let motion = MotionPolicy()

    var body: some View {
        let dark = scheme == .dark
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                DXIcon(.sun, size: 16, weight: 2.4)
                Text("Xero's sky")
            }
            .dxType(.caption).foregroundStyle(ground.muted)
            CountingText(Double(clarity), duration: 0.85) { "\(Int($0.rounded()))%" }
                .dxFace(.display, 34, weight: 800, tracking: -0.5)
                .foregroundStyle(ground.ink)
            Text("clear").dxType(.caption).foregroundStyle(ground.muted)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
        .background {
            ZStack {
                (dark ? ground.card : Color(hex: 0xFFF8EE))
                Canvas { ctx, size in
                    let k = max(size.width / 168, size.height / 116)
                    ctx.translateBy(x: size.width - 168 * k, y: (size.height - 116 * k) / 2)
                    ctx.scaleBy(x: k, y: k)
                    ctx.fill(Path(CGRect(x: 0, y: 0, width: 168, height: 116)), with: .linearGradient(
                        Gradient(colors: [Color(hex: dark ? 0x16234A : 0xBFDDF4), Color(hex: dark ? 0x3A4A7A : 0xFCEBD2)]),
                        startPoint: .zero, endPoint: CGPoint(x: 0, y: 116)))
                    ctx.translateBy(x: slid ? 0 : -60, y: 0)
                    let cl2 = Color(hex: dark ? 0x46588C : 0xEEF3FA), cl = Color(hex: dark ? 0x56689C : 0xFFFFFF)
                    for (x, y, r) in [(84.0, 106.0, 13.0), (106, 97, 18), (132, 99, 16), (158, 102, 16)] { ctx.fill(CalmPaint.circle(x, y, r), with: .color(cl2)) }
                    ctx.fill(Path(CGRect(x: 70, y: 106, width: 104, height: 14)), with: .color(cl2))
                    for (x, y, r) in [(116.0, 111.0, 11.0), (138, 104, 14), (161, 109, 12)] { ctx.fill(CalmPaint.circle(x, y, r), with: .color(cl)) }
                    ctx.fill(Path(CGRect(x: 104, y: 111, width: 70, height: 8)), with: .color(cl))
                    ctx.fill(Path(roundedRect: CGRect(x: 140, y: 44, width: 40, height: 12), cornerRadius: 6), with: .color(cl2))
                    ctx.fill(CalmPaint.circle(154, 44, 7.5), with: .color(cl2))
                    ctx.fill(CalmPaint.circle(166, 42, 9), with: .color(cl2))
                }
                .mask(RadialGradient(stops: [.init(color: .black, location: 0.3), .init(color: .black.opacity(0.5), location: 0.56),
                                             .init(color: .clear, location: 0.8)],
                                     center: UnitPoint(x: 1, y: 0.66), startRadius: 0, endRadius: 150))
                .dxFade(delay: 0.3)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous).strokeBorder(ground.line, lineWidth: 1))
        .onAppear {
            if motion.reduce { slid = true; return }
            withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.9).delay(0.3)) { slid = true }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Xero's sky, \(clarity)% clear"))
    }
}

/// Jelli in her own small sea disc next to a title (044, 045).
struct JelliSeaDisc: View {
    let size: CGFloat
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let dark = scheme == .dark
        ZStack(alignment: .top) {
            LinearGradient(colors: [Color(hex: dark ? 0x1C2A55 : 0xCFE5F7), Color(hex: dark ? 0x33477A : 0xEAF2F8)], startPoint: .top, endPoint: .bottom)
            JelliView(mood: .calm, stage: 1, points: size)
                .frame(width: size, height: size)
                .dxBob(3, period: 6)
                .offset(y: -6 * size / 84)
            Canvas { ctx, s in
                ctx.scaleBy(x: s.width / 84, y: s.height / 34)
                CalmPaint.fill(&ctx, "M0 12 C14 6 26 6 42 11 S70 16 84 9 V34 H0Z", dark ? 0x2F4F8F : 0x8FC0EC)
                CalmPaint.fill(&ctx, "M0 22 C16 17 30 18 44 22 S70 26 84 20 V34 H0Z", dark ? 0x1B356A : 0x4A8FDB)
            }
            .frame(height: 24 * size / 84)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }
}

/// The done beat (046): Jelli cheering in her sea disc, her bell on the waterline and her tentacles under a
/// translucent front wave; an apricot check pops on the disc's upper-right rim and its tick draws.
private struct JelliDoneDisc: View {
    @Environment(\.colorScheme) private var scheme
    @State private var ticked = false
    private let motion = MotionPolicy()

    var body: some View {
        let dark = scheme == .dark
        ZStack(alignment: .topTrailing) {
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [Color(hex: dark ? 0x1C2A55 : 0xCFE5F7), Color(hex: dark ? 0x33477A : 0xEAF2F8)], startPoint: .top, endPoint: .bottom)
                Canvas { ctx, s in
                    ctx.translateBy(x: 0, y: s.height - 82)
                    ctx.scaleBy(x: s.width / 188, y: 82 / 70)
                    CalmPaint.fill(&ctx, "M0 24 C30 14 60 14 94 22 S156 32 188 20 V70 H0Z", dark ? 0x3A5A9A : 0x8FC0EC)
                    CalmPaint.fill(&ctx, "M0 46 C34 38 64 39 96 45 S158 52 188 42 V70 H0Z", dark ? 0x2A4A8A : 0x4A8FDB)
                }
                JelliView(mood: .cheer, stage: 1, points: 156)
                    .frame(width: 156, height: 156)
                    .dxBob(3, period: 6)
                    .dxSettle(delay: 0.2)
                    .offset(x: 16, y: 38)
                Canvas { ctx, s in
                    ctx.translateBy(x: 0, y: s.height - 58)
                    ctx.scaleBy(x: s.width / 188, y: 58 / 50)
                    CalmPaint.fill(&ctx, "M0 14 C30 6 62 7 96 13 S158 20 188 10 V50 H0Z", dark ? 0x22417F : 0x3F82D2, opacity: dark ? 0.7 : 0.62)
                    ctx.stroke(SVGPath.path("M0 14 C30 6 62 7 96 13 S158 20 188 10"), with: .color(Color(hex: dark ? 0x9FB8EA : 0xEAF5FF).opacity(dark ? 0.4 : 0.55)), lineWidth: 2)
                }
            }
            .frame(width: 188, height: 188)
            .clipShape(Circle())
            .dxFade()
            ZStack {
                Circle().fill(Color(hex: 0xFFB070))
                DXIconShape(d: DX.Icon.check.d)
                    .trim(from: 0, to: ticked ? 1 : 0)
                    .stroke(Color(hex: 0x1E1A3A), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .frame(width: 20, height: 20)
            }
            .frame(width: 40, height: 40)
            .background(Circle().fill(DX.Ground.reading.background).padding(-4))
            .dxPop(delay: 0.5)
            .offset(x: -6, y: 8)
        }
        .sensoryFeedback(DX.Haptic.commit, trigger: ticked)
        .onAppear {
            if motion.reduce { ticked = true; return }
            withAnimation(.easeOut(duration: 0.42).delay(0.82)) { ticked = true }
        }
    }
}

/// The sea card on 043: a soft sky with the sun and a drifting cloud, the back waves, Jelli settling onto the water
/// between them and the front waves, then a slow bob. Dark: a warm low sun with a soft glow, never a ringed disc.
struct SlipSeaCard: View {
    @Environment(\.colorScheme) private var scheme
    @State private var drift = false
    private let motion = MotionPolicy()

    var body: some View {
        let dark = scheme == .dark
        GeometryReader { proxy in
            let k = max(proxy.size.width / 346, proxy.size.height / 224)
            let dx = (proxy.size.width - 346 * k) / 2, dy = (proxy.size.height - 224 * k) / 2
            ZStack(alignment: .bottom) {
                Canvas { ctx, _ in
                    ctx.translateBy(x: dx, y: dy)
                    ctx.scaleBy(x: k, y: k)
                    ctx.fill(Path(CGRect(x: 0, y: 0, width: 346, height: 224)), with: .linearGradient(
                        Gradient(colors: [Color(hex: dark ? 0x1C2A55 : 0xCBE4F6), Color(hex: dark ? 0x33477A : 0xF4EEE4)]),
                        startPoint: .zero, endPoint: CGPoint(x: 0, y: 224)))
                    if dark {
                        ctx.fill(CalmPaint.circle(262, 58, 74), with: .radialGradient(Gradient(stops: [
                            .init(color: Color(hex: 0xFFD27A).opacity(0.78), location: 0),
                            .init(color: Color(hex: 0xFFB24E).opacity(0.3), location: 0.4),
                            .init(color: Color(hex: 0xFFB24E).opacity(0), location: 1),
                        ]), center: CGPoint(x: 262, y: 58), startRadius: 0, endRadius: 74))
                        ctx.fill(CalmPaint.circle(262, 58, 24), with: .color(Color(hex: 0xFFC864)))
                    } else {
                        ctx.fill(CalmPaint.circle(262, 58, 46), with: .color(Color(hex: 0xFFE7B0).opacity(0.5 * 0.35)))
                        ctx.fill(CalmPaint.circle(262, 58, 36), with: .color(Color(hex: 0xFFE7B0).opacity(0.5)))
                        ctx.fill(CalmPaint.circle(262, 58, 28), with: .color(Color(hex: 0xF7C46A)))
                        ctx.fill(CalmPaint.circle(262, 58, 24), with: .color(Color(hex: 0xFFD98A)))
                    }
                    var cloud = ctx
                    cloud.translateBy(x: drift ? 14 : 0, y: 0)
                    let c = Color(hex: dark ? 0x4A5D92 : 0xFFFBF4)
                    cloud.fill(Path(roundedRect: CGRect(x: 56, y: 45, width: 66, height: 17), cornerRadius: 8.5), with: .color(c))
                    for (x, y, r) in [(75.0, 45.0, 11.0), (94, 41, 14.5), (111, 48, 8.5)] { cloud.fill(CalmPaint.circle(x, y, r), with: .color(c)) }
                    var waves = ctx
                    waves.addFilter(.shadow(color: Color(hex: 0x10204A).opacity(0.22), radius: 2.4, x: 0, y: -2))
                    CalmPaint.fill(&waves, "M0 110 C40 98 80 98 120 108 S200 122 240 108 S318 94 346 104 V240 H0Z", dark ? 0x3A5A9A : 0xA9D0F0)
                    CalmPaint.fill(&waves, "M0 140 C50 126 92 128 132 138 S222 152 262 138 S322 126 346 134 V240 H0Z", dark ? 0x2F4F8F : 0x78B3E8)
                }
                JelliView(mood: .calm, stage: 1, points: 176)
                    .frame(width: 176, height: 176)
                    .dxBob(4, period: 6)
                    .dxSettle(delay: 0.2)
                    .padding(.bottom, 14)
                Canvas { ctx, _ in
                    ctx.translateBy(x: dx, y: dy)
                    ctx.scaleBy(x: k, y: k)
                    var waves = ctx
                    waves.addFilter(.shadow(color: Color(hex: 0x10204A).opacity(0.26), radius: 2.6, x: 0, y: -2))
                    CalmPaint.fill(&waves, "M0 178 C36 166 76 166 112 176 S190 190 232 178 S310 164 346 174 V240 H0Z", dark ? 0x26437E : 0x4A8FDB)
                    ctx.stroke(SVGPath.path("M60 172 q10-5 20 0 M250 174 q10-5 20 0"), with: .color(Color(hex: 0xFFF8EE).opacity(dark ? 0.5 : 0.85)),
                               style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    CalmPaint.fill(&waves, "M0 204 C50 194 100 196 150 204 S250 214 346 200 V240 H0Z", dark ? 0x1B356A : 0x2F6FC4)
                }
                .allowsHitTesting(false)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .onAppear {
            guard motion.breathes else { return }
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) { drift = true }
        }
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
