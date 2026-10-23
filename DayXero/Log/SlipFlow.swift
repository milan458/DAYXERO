import DayXeroCore
import SwiftData
import SwiftUI

/// After a slip: a supportive note, then an optional one-minute talk-through that ends in an if-then plan (S8).
/// The slip is already saved when this opens; every step only adds details. Nothing resets.
struct SlipFlow: View {
    /// The slip being talked through. nil only if saving failed; the screens still work.
    let entry: LogEntry?
    let profile: UserProfile?
    let onDone: () -> Void
    /// Start straight at the talk-through, for a slip reopened from Progress.
    var startInTalkThrough = false

    enum Stage: Int, CaseIterable {
        case acknowledge, what, trigger, plan, done
    }

    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<LogEntry> { $0.kindRaw == "slip" }) private var slips: [LogEntry]
    @State private var stage = Stage.acknowledge
    @State private var product: Product?
    @State private var amount: SlipAmount?
    @State private var when = Slips.When.justNow
    @State private var trigger: Trigger?
    @State private var mood: Mood?
    @State private var action: String?
    @State private var ownAction = ""
    @State private var writingOwn = false
    @State private var showNRT = false
    @State private var savedFeedback = false
    private let loggedAt: Date

    init(entry: LogEntry?, profile: UserProfile?, startInTalkThrough: Bool = false, onDone: @escaping () -> Void) {
        self.entry = entry
        self.profile = profile
        self.startInTalkThrough = startInTalkThrough
        self.onDone = onDone
        loggedAt = entry?.timestamp ?? .now
        var start = startInTalkThrough ? Stage.what : .acknowledge
        #if DEBUG
        if let raw = UserDefaults.standard.string(forKey: "dx.slipStage"),
           let debug = Stage.allCases.first(where: { "\($0)" == raw }) { start = debug }
        #endif
        _stage = State(initialValue: start)
    }

    var body: some View {
        VStack(spacing: 0) {
            if stage != .acknowledge { progress }
            switch stage {
            case .acknowledge: acknowledge
            case .what: what
            case .trigger: triggerStep
            case .plan: plan
            case .done: done
            }
        }
        .padding(.horizontal, DX.Space.m)
        .padding(.bottom, DX.Space.xs)
        .dxCanvas()
        .animation(DX.Motion.animation(DX.Motion.glide, reduceMotion: false), value: stage)
        .sensoryFeedback(DX.Haptic.commit, trigger: savedFeedback)
        .onAppear(perform: prefill)
        .fullScreenCover(isPresented: $showNRT) {
            if let profile { NRTSetupView(profile: profile) { showNRT = false } }
        }
    }

    // MARK: Steps

    private var acknowledge: some View {
        VStack(spacing: DX.Space.s) {
            ScrollView {
                VStack(spacing: DX.Space.s) {
                    icon("heart").padding(.top, DX.Space.xxl)
                    Text("Thanks for telling us").dxText(.title).multilineTextAlignment(.center)
                    Text(isPrep ? String(localized: "Logged. Prep is for learning your patterns, and this helps.")
                         : String(localized: "A slip is one moment, not a restart. Your \(daysClear) days clear stay as they are."))
                        .dxText(.subtitle).multilineTextAlignment(.center)
                    DXCard(padding: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("One minute, if you have it").dxText(.micro)
                            Text("Three quick questions so we can plan for next time.")
                                .font(DX.TextStyle.subtitle.font).foregroundStyle(DX.Palette.text)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, DX.Space.l)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            // Capped so the buttons leave room for the message at the largest text sizes.
            VStack(spacing: DX.Space.s) {
                Button("Talk it through · 1 min") { stage = .what }.buttonStyle(.dxPrimary)
                Button("Not now", action: onDone).buttonStyle(.dxQuiet)
            }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
    }

    private var what: some View {
        step(title: "What happened?", subtitle: "No judgement, just the facts so we can plan.", button: "Next", next: .trigger) {
            if products.count > 1 {
                label("What did you have?")
                DXFlowLayout {
                    ForEach(products, id: \.self) { p in DXSetChip(p.title, value: p, selection: single($product)) }
                }
            }
            label("How much?")
            HStack(spacing: DX.Space.xs) {
                amountOption(.aLittle, title: product == .cigarettes ? "A few drags" : product == .pouches ? "Briefly" : "A few puffs", detail: "one moment")
                amountOption(.one, title: product == .cigarettes ? "One" : product == .pouches ? "One pouch" : "One session", detail: "a sitting")
                amountOption(.more, title: "More", detail: "a few times")
            }
            label("When?")
            DXFlowLayout {
                ForEach(Slips.When.allCases, id: \.self) { w in
                    DXChip(whenTitle(w), isOn: Binding(get: { when == w }, set: { if $0 { when = w } }))
                }
            }
        }
    }

    private var triggerStep: some View {
        step(title: "What set it off?", subtitle: "Pick the closest one.", button: "Next", next: .plan) {
            DXFlowLayout {
                ForEach(orderedTriggers, id: \.self) { t in DXSetChip(t.title, value: t, selection: single($trigger)) }
            }
            label("How were you feeling?", optional: true)
            DXFlowLayout {
                ForEach(Mood.allCases, id: \.self) { m in DXSetChip(m.title, value: m, selection: single($mood)) }
            }
        }
    }

    private var plan: some View {
        let situation = String(localized: (trigger ?? .other).situation)
        return step(title: "One thing to try next time", subtitle: "Make a plan for the next time it's \(situation).",
                    button: "Save my plan", next: .done, skippable: false, enabled: chosenAction != nil) {
            DXCard(padding: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    DXFlowLayout(spacing: 6) { Text("If it's"); slot(situation, filled: true) }
                    DXFlowLayout(spacing: 6) { Text("then I'll"); slot(chosenAction ?? String(localized: "choose one"), filled: chosenAction != nil) }
                }
                .font(.custom(DX.Typeface.regular, size: 16, relativeTo: .body))
                .foregroundStyle(DX.Palette.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .combine)
            label("Then I'll…")
            DXFlowLayout {
                ForEach((trigger ?? .other).nextTimeSuggestions.map { String(localized: $0) }, id: \.self) { idea in
                    DXChip(LocalizedStringKey(idea), isOn: Binding(get: { !writingOwn && action == idea },
                                                                   set: { if $0 { action = idea; writingOwn = false } }))
                }
                DXChip("write my own", isOn: Binding(get: { writingOwn }, set: { writingOwn = $0 }))
            }
            if writingOwn {
                DXTextField("Then I'll…", prompt: "go for a run", text: $ownAction)
            }
        }
    }

    private var done: some View {
        VStack(spacing: DX.Space.s) {
            ScrollView {
                VStack(spacing: DX.Space.s) {
                    icon("checkmark").padding(.top, DX.Space.xl)
                    Text("Plan saved").dxText(.title)
                    Text("Every slip shows you something about your cravings. Now you've got a plan for this one.")
                        .dxText(.subtitle).multilineTextAlignment(.center)
                    if let action = entry?.nextTime ?? chosenAction {
                        PlanCard(situation: String(localized: (trigger ?? .other).situation), action: action)
                    }
                    HStack(spacing: DX.Space.xs) {
                        Image(systemName: "checkmark").foregroundStyle(DX.Palette.accentInk)
                        Text(isPrep ? String(localized: "Prep carries on as planned.")
                             : String(localized: "Still Day \(daysClear) clear. Nothing has changed on Home."))
                            .font(DX.TextStyle.subtitle.font).foregroundStyle(DX.Palette.text)
                        Spacer(minLength: 0)
                    }
                    .padding(14)
                    .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(DX.Palette.hairline))
                    if Slips.isToughDay(slipsToday: slipsToday) { toughDay }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            Button("Back to Today", action: onDone).buttonStyle(.dxPrimary)
        }
    }

    /// From the third slip in a day: NRT or another look at the plan, never starting over.
    private var toughDay: some View {
        DXCard(padding: 14) {
            VStack(alignment: .leading, spacing: DX.Space.xs) {
                Text("It's been a tough day. That happens, especially early on. Want to look at NRT options, or go over your plan again?")
                    .font(DX.TextStyle.subtitle.font).foregroundStyle(DX.Palette.text)
                ViewThatFits {
                    HStack(spacing: DX.Space.xs) { nrtButton; replanButton }
                    VStack(spacing: DX.Space.xs) { nrtButton; replanButton }
                }
            }
        }
    }

    private var nrtButton: some View {
        Button { showNRT = true } label: { Text("Look at NRT").frame(maxWidth: .infinity) }.buttonStyle(.dxSecondary)
    }

    private var replanButton: some View {
        Button { stage = .plan } label: { Text("Go over my plan").frame(maxWidth: .infinity) }.buttonStyle(.dxSecondary)
    }

    // MARK: Pieces

    private var progress: some View {
        VStack(spacing: DX.Space.s) {
            HStack(spacing: 4) {
                ForEach(1...3, id: \.self) { i in
                    Capsule().fill(i <= min(stage.rawValue, 3) ? DX.Palette.text : DX.Palette.track).frame(height: 4)
                }
            }
            .accessibilityHidden(true)
            HStack {
                Button(action: onDone) {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .semibold)).foregroundStyle(DX.Palette.text2)
                        .frame(width: 36, height: 36)
                        .background(DX.Palette.surface1, in: Circle())
                        .overlay(Circle().strokeBorder(DX.Palette.hairline))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Close. The slip is saved."))
                Spacer()
                if stage != .done { Text("\(stage.rawValue) of 3").dxText(.micro) }
                Spacer()
                if stage == .what || stage == .trigger {
                    Button("Skip") { advance() }.font(.custom(DX.Typeface.semibold, size: 13, relativeTo: .footnote))
                        .foregroundStyle(DX.Palette.text2).frame(width: 36)
                } else {
                    Color.clear.frame(width: 36, height: 36)
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .padding(.top, DX.Space.l)
        .padding(.bottom, DX.Space.s)
    }

    private func step(title: LocalizedStringKey, subtitle: LocalizedStringKey, button: LocalizedStringKey, next: Stage,
                      skippable: Bool = true, enabled: Bool = true, @ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: DX.Space.s) {
            ScrollView {
                VStack(alignment: .leading, spacing: DX.Space.xs) {
                    Text(title).dxText(.title)
                    Text(subtitle).dxText(.subtitle).padding(.bottom, DX.Space.s)
                    content()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            Button(button) { advance() }
                .buttonStyle(.dxPrimary)
                .disabled(!enabled)
        }
    }

    private func label(_ text: LocalizedStringKey, optional: Bool = false) -> some View {
        Group {
            if optional {
                Text("\(Text(text)) \(Text("· optional").foregroundStyle(DX.Palette.faint))")
            } else {
                Text(text)
            }
        }
        .dxText(.micro)
        .padding(.top, DX.Space.s)
    }

    private func icon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 30, weight: name == "checkmark" ? .bold : .regular))
            .foregroundStyle(DX.Palette.accentInk)
            .frame(width: 76, height: 76)
            .background(DX.Palette.accentSoft, in: Circle())
            .accessibilityHidden(true)
    }

    private func amountOption(_ value: SlipAmount, title: LocalizedStringKey, detail: LocalizedStringKey) -> some View {
        let on = amount == value
        return Button { amount = on ? nil : value } label: {
            VStack(spacing: 2) {
                Text(title).font(.custom(DX.Typeface.semibold, size: 13, relativeTo: .footnote)).foregroundStyle(DX.Palette.text)
                Text(detail).font(.custom(DX.Typeface.regular, size: 11, relativeTo: .caption2)).foregroundStyle(DX.Palette.text2)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 64)
            .padding(.horizontal, 6)
            .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(on ? DX.Palette.accentInk : DX.Palette.hairline, lineWidth: on ? 1.5 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func slot(_ text: String, filled: Bool) -> some View {
        Text(verbatim: text)
            .font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .body))
            .foregroundStyle(filled ? DX.Palette.onPrimary : DX.Palette.text2)
            .padding(.vertical, 3).padding(.horizontal, 12)
            .background(filled ? DX.Palette.primary : .clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(filled ? .clear : DX.Palette.faint, style: StrokeStyle(lineWidth: 1, dash: [3, 3])))
    }

    private func whenTitle(_ w: Slips.When) -> LocalizedStringKey {
        switch w {
        case .justNow: "Just now"
        case .earlierToday: "Earlier today"
        case .yesterday: "Yesterday"
        }
    }

    // MARK: Data

    private var products: [Product] {
        (profile?.products ?? []).sorted { ($0.isPrimary ? 0 : 1) < ($1.isPrimary ? 0 : 1) }.map(\.product)
    }

    private var orderedTriggers: [Trigger] {
        let mine = profile?.triggers ?? []
        return mine + Trigger.allCases.filter { !mine.contains($0) }
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

    private func single<T: Hashable>(_ value: Binding<T?>) -> Binding<Set<T>> {
        Binding(
            get: { value.wrappedValue.map { [$0] } ?? [] },
            set: { new in
                let old = value.wrappedValue
                value.wrappedValue = new.first { $0 != old } ?? (old.map(new.contains) == true ? old : nil)
            }
        )
    }

    private func prefill() {
        guard let entry else { return }
        product = entry.product ?? products.first
        amount = entry.amount
        trigger = entry.trigger
        mood = entry.mood
        if let next = entry.nextTime {
            if (entry.trigger ?? .other).nextTimeSuggestions.map({ String(localized: $0) }).contains(next) {
                action = next
            } else {
                ownAction = next
                writingOwn = true
            }
        }
        #if DEBUG
        if UserDefaults.standard.string(forKey: "dx.slipStage") != nil {
            amount = amount ?? .one
            trigger = trigger ?? profile?.triggers.first
            mood = mood ?? .meh
            if stage == .plan || stage == .done { action = action ?? (trigger ?? .other).nextTimeSuggestions.first.map { String(localized: $0) } }
        }
        #endif
    }

    /// Saves what's been answered so far and moves on. Every step is optional except choosing a plan to save it.
    private func advance() {
        guard let entry else {
            stage = Stage(rawValue: stage.rawValue + 1) ?? .done
            return
        }
        switch stage {
        case .what:
            entry.productRaw = (product ?? entry.product)?.rawValue
            entry.amount = amount
            entry.timestamp = Slips.time(when, loggedAt: loggedAt, clock: clock)
            stage = .trigger
        case .trigger:
            entry.triggerRaw = trigger?.rawValue
            entry.mood = mood
            stage = .plan
        case .plan:
            guard let chosen = chosenAction else { return }
            entry.nextTime = chosen
            context.insert(IfThenPlan(situation: String(localized: (trigger ?? .other).situation), action: chosen))
            savedFeedback.toggle()
            stage = .done
        case .acknowledge, .done:
            break
        }
        try? context.save()
    }
}

/// "If it's …, then I'll …" as saved. Shown when a plan is made, on Home for the rest of that day, and in Craving SOS.
struct PlanCard: View {
    let situation: String
    let action: String
    var title: LocalizedStringKey = "Your plan"

    var body: some View {
        DXCard(padding: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title).dxText(.micro)
                Text("If it's \(Text(verbatim: situation).font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .body))), then I'll \(Text(verbatim: action).font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .body)))")
                    .font(.custom(DX.Typeface.regular, size: 15, relativeTo: .body))
                    .foregroundStyle(DX.Palette.text)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}
