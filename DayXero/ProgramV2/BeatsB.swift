import DayXeroCore
import SwiftUI

// Program v2 activities, part two: plans, checklists, breathing, commit, scenario, note, info, share,
// NRT, slip practice and the plan card (handoff 5.8–5.19).

// MARK: - plan_builder

/// "If …, then I will …" lines. The "if" half is free text, prefilled when the prompt sets it.
struct PlanBuilderBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    @State private var plans: [ProgramAnswerValue.PlanLine] = []
    @State private var situation = ""
    @State private var action = ""
    @State private var typingOwn = false

    /// "If today gets hard, then I will…" sets the situation to "today gets hard".
    private var promptSituation: String {
        let prompt = ctx.text(beat.prompt)
        guard prompt.hasPrefix("If "), let range = prompt.range(of: ", then I will") else { return "" }
        return String(prompt[prompt.index(prompt.startIndex, offsetBy: 3)..<range.lowerBound])
    }

    private var canAdd: Bool {
        !situation.trimmingCharacters(in: .whitespaces).isEmpty && !action.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        BeatFrame(beat: beat, canContinue: !plans.isEmpty || canAdd, onContinue: finish) {
            VStack(alignment: .leading, spacing: DX.Space.s) {
                BeatPrompt(text: ctx.text(beat.prompt))
                ForEach(Array(plans.enumerated()), id: \.offset) { i, plan in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Plan \(i + 1)").v4Text(.micro).foregroundStyle(Read4.accent)
                            Text(verbatim: ProgramAnswerValue.plans([plan]).lines.first ?? "")
                                .dxFont(16, weight: 400, style: .body).foregroundStyle(Read4.ink)
                        }
                        Spacer()
                        Button { plans.remove(at: i) } label: {
                            Image(systemName: "xmark").font(.system(size: 12, weight: .semibold)).foregroundStyle(Read4.muted)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("Remove plan \(i + 1)"))
                    }
                    .padding(DX.Space.m)
                    .background(Read4.accentSoft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Plan \(plans.count + 1)").v4Text(.micro)
                    Text("If").dxFont(14, weight: 600, style: .footnote).foregroundStyle(Read4.ink)
                    TextField("what happens", text: $situation)
                        .dxFont(16, weight: 500, style: .body)
                        .padding(12)
                        .background(Read4.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    Text("Then I will").dxFont(14, weight: 600, style: .footnote).foregroundStyle(Read4.ink)
                    DXFlowLayout(spacing: 8) {
                        ForEach(beat.suggestions ?? [], id: \.self) { suggestion in
                            BeatChip(text: suggestion, on: !typingOwn && action == suggestion) {
                                typingOwn = false
                                action = suggestion
                            }
                        }
                        BeatChip(text: String(localized: "Type my own"), on: typingOwn) {
                            typingOwn = true
                            action = ""
                        }
                    }
                    if typingOwn {
                        TextField("what you'll do", text: $action)
                            .dxFont(16, weight: 500, style: .body)
                            .padding(12)
                            .background(Read4.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(DX.Space.m)
                .background(Read4.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Read4.hairline))
                Button(action: addPlan) {
                    Label("Add another plan", systemImage: "plus").dxFont(16, weight: 600, style: .body)
                        .foregroundStyle(Read4.accent).frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .disabled(!canAdd)
            }
        }
        .onAppear {
            if case let .plans(saved)? = ctx.answer(beat.saveAs) { plans = saved }
            situation = promptSituation
        }
    }

    private func addPlan() {
        guard canAdd else { return }
        plans.append(.init(situation: situation.trimmingCharacters(in: .whitespaces), action: action.trimmingCharacters(in: .whitespaces)))
        situation = promptSituation
        action = ""
        typingOwn = false
    }

    private func finish() {
        addPlan()
        ctx.save(beat.saveAs, .plans(plans))
        ctx.finish(beat)
        onDone()
    }
}

// MARK: - checklist

/// Tap to tick. Continue is always on: what's left unticked isn't a failure, and carries over where a later list asks.
struct ChecklistBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    @State private var ticked: Set<String> = []

    private var items: [String] { beat.checklist?.resolve(ctx.variant) ?? [] }

    /// Items left unticked on the earlier list this one carries over from.
    private var carried: [String] {
        guard let key = beat.carryOverFrom,
              let source = ctx.store.content?.sessions.flatMap(\.beats).first(where: { $0.saveAs == key }),
              let all = source.checklist?.resolve(ctx.variant) else { return [] }
        let done = Set(ctx.answer(key)?.lines ?? [])
        return all.filter { !done.contains($0) }
    }

    var body: some View {
        BeatFrame(beat: beat, onContinue: finish) {
            VStack(alignment: .leading, spacing: 10) {
                BeatPrompt(text: ctx.text(beat.title))
                if !carried.isEmpty {
                    Text("Still open from before").v4Text(.micro)
                    ForEach(carried, id: \.self) { row($0) }
                    Text("Tonight").v4Text(.micro).padding(.top, DX.Space.xs)
                } else {
                    Text("Tick what you've done. The rest can wait.").v4Text(.subtitle)
                }
                ForEach(items, id: \.self) { row($0) }
                if let footer = beat.footer.map({ ctx.text($0) }), !footer.isEmpty {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "battery.100.bolt").foregroundStyle(Color(light: 0x8A5E0E, dark: 0xE5A93C)).accessibilityHidden(true)
                        Text(verbatim: footer).dxFont(14, weight: 400, style: .footnote).foregroundStyle(Read4.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(DX.Space.s)
                    .background(Read4.amber.opacity(0.18), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .sensoryFeedback(DX.Haptic.select, trigger: ticked)
        .onAppear { ticked = Set(ctx.answer(beat.saveAs)?.lines ?? []) }
    }

    private func row(_ item: String) -> some View {
        let on = ticked.contains(item)
        return Button {
            if on { ticked.remove(item) } else { ticked.insert(item) }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(on ? .clear : Read4.faint, lineWidth: 1.5)
                    if on {
                        RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Read4.accent)
                        Image(systemName: "checkmark").font(.system(size: 13, weight: .bold)).foregroundStyle(Read4.background)
                    }
                }
                .frame(width: 26, height: 26)
                Text(verbatim: item).dxFont(16, weight: 500, style: .body)
                    .foregroundStyle(on ? Read4.muted : Read4.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 12).padding(.horizontal, DX.Space.m)
            .frame(minHeight: 56)
            .background(Read4.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Read4.hairline))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? [.isSelected] : [])
        .accessibilityValue(Text(on ? "Done" : "Not done"))
    }

    private func finish() {
        // Everything ticked, carried items included, so a later carry-over sees them as done.
        ctx.save(beat.saveAs, .list((carried + items).filter { ticked.contains($0) }))
        if let key = beat.carryOverFrom {
            let previous = Set(ctx.answer(key)?.lines ?? [])
            ctx.save(key, .list(Array(previous.union(carried.filter { ticked.contains($0) })).sorted()))
        }
        ctx.finish(beat)
        onDone()
    }
}

// MARK: - breathe

/// The Bio-Orb for a set number of cycles, voice off: the session audio just played.
struct BreatheBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    @AppStorage("dx.voiceGuidance") private var voiceOn = true
    @State private var savedVoice: Bool?

    var body: some View {
        VStack(spacing: DX.Space.s) {
            Text(verbatim: ctx.text(beat.label)).dxFont(19, weight: 600, style: .title3)
                .foregroundStyle(Read4.ink).multilineTextAlignment(.center)
            OrbBreathingPanel(pattern: beat.pattern ?? "box", cycles: beat.cycles) {
                ctx.finish(beat)
                onDone()
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .onAppear {
            savedVoice = voiceOn
            voiceOn = false
        }
        .onDisappear { if let savedVoice { voiceOn = savedVoice } }
    }
}

// MARK: - commit

/// Press and hold: a ring fills over a few seconds with rising haptics; let go early and it drains back with no message.
/// VoiceOver gets a "Commit" action instead of holding. On replay it shows when it was done.
struct CommitBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress = 0.0
    @State private var pressing = false
    @State private var doneAt: Date?
    @State private var pulse = 0

    private var seconds: Double { Double(beat.holdSeconds ?? 2) }

    var body: some View {
        VStack(spacing: DX.Space.l) {
            Spacer()
            Text(verbatim: doneAt == nil ? ctx.text(beat.text) : String(localized: "Committed."))
                .dxFont(24, weight: 700, style: .title2)
                .multilineTextAlignment(.center)
                .foregroundStyle(Read4.ink)
            ZStack {
                Circle().stroke(Read4.track, lineWidth: 13)
                Circle().trim(from: 0, to: doneAt == nil ? progress : 1)
                    .stroke(Read4.accent, style: StrokeStyle(lineWidth: 13, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                if let doneAt {
                    VStack(spacing: 6) {
                        Image(systemName: "checkmark").font(.system(size: 40, weight: .semibold)).foregroundStyle(Read4.accent)
                        Text("Done on").dxFont(16, weight: 600, style: .body)
                        Text(doneAt, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated)).v4Text(.subtitle)
                    }
                    .frame(width: 184, height: 184)
                    .background(Read4.accentSoft, in: Circle())
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "hand.point.up.left").font(.system(size: 28))
                        Text(pressing ? "Keep holding" : "Press and hold").dxFont(16, weight: 600, style: .body)
                    }
                    .foregroundStyle(Read4.onInk)
                    .frame(width: 184, height: 184)
                    .background(Read4.ink, in: Circle())
                    .scaleEffect(pressing && !reduceMotion ? 0.96 : 1)
                    .onLongPressGesture(minimumDuration: seconds, maximumDistance: 40) {
                        commit()
                    } onPressingChanged: { down in
                        pressing = down
                        withAnimation(down ? .linear(duration: seconds) : .easeOut(duration: 0.3)) { progress = down ? 1 : 0 }
                    }
                }
            }
            .frame(width: 210, height: 210)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: ctx.text(beat.text)))
            .accessibilityValue(Text(doneAt == nil ? "Not done" : "Done"))
            .accessibilityAction(named: Text("Commit")) { commit() }
            Text(doneAt == nil ? "\(Int(seconds)) seconds" : "").v4Text(.subtitle)
            Spacer()
            if doneAt != nil {
                Button("Continue", action: onDone).buttonStyle(.dx(.primary, on: .reading))
            }
        }
        .sensoryFeedback(.impact(weight: .medium, intensity: 0.4 + 0.15 * Double(pulse)), trigger: pulse)
        .sensoryFeedback(DX.Haptic.commit, trigger: doneAt)
        .task(id: pressing) {
            // Haptics rise while the ring fills.
            pulse = 0
            while pressing, !Task.isCancelled, pulse < 4 {
                try? await Task.sleep(for: .seconds(seconds / 4))
                if pressing { pulse += 1 }
            }
        }
        .onAppear {
            if case let .date(date)? = ctx.recorded(beat) { doneAt = date }
            else if let key = beat.sets, case let .date(date)? = ctx.answer(key) { doneAt = date }
        }
    }

    private func commit() {
        guard doneAt == nil else { return }
        let now = Date.now
        doneAt = now
        pressing = false
        guard !ctx.isReplay else { return }
        if let key = beat.sets { ctx.store.commit(key, at: now) }
        if beat.sets == "graduated_at", let quit = ctx.store.profile.progress?.quitTimestamp {
            Analytics.track(.programGraduated(daysSinceQuit: ctx.store.clock.calendar.dateComponents([.day], from: quit, to: now).day ?? 0))
        }
        ctx.finish(beat, value: .date(now))
    }
}

// MARK: - scenario

/// Every option is valid: the pick stays highlighted and its own feedback shows. Nothing is marked right.
struct ScenarioBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    @State private var picked: String?

    private var options: [Beat.Option] { beat.options?.resolve(ctx.variant) ?? [] }

    var body: some View {
        BeatFrame(beat: beat, canContinue: picked != nil, onContinue: {
            ctx.finish(beat, value: picked.map { .text($0) })
            onDone()
        }) {
            VStack(alignment: .leading, spacing: 10) {
                BeatPrompt(text: ctx.text(beat.prompt), eyebrow: "Picture it")
                ForEach(options) { option in
                    Button { withAnimation(DX.Move.settle) { picked = option.id } } label: {
                        OptionRow(text: option.text, selected: picked == option.id, dimmed: picked != nil && picked != option.id)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(picked == option.id ? .isSelected : [])
                }
                if let feedback = options.first(where: { $0.id == picked })?.feedback {
                    BeatFeedback(text: feedback).padding(.top, DX.Space.xs).id(picked)
                }
            }
        }
        .sensoryFeedback(DX.Haptic.select, trigger: picked)
        .onAppear { if case let .text(id)? = ctx.recorded(beat) { picked = id } }
    }
}

// MARK: - note

/// A saved answer as a quiet card; the highlighted item first and emphasised.
struct NoteBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    private var lines: (highlight: String?, rest: [String]) {
        let all = ctx.answer(beat.textFrom)?.lines ?? []
        guard let key = beat.highlightFrom, case let .text(top)? = ctx.answer(key), !top.isEmpty else { return (nil, all) }
        return (top, all.filter { $0 != top })
    }

    var body: some View {
        BeatFrame(beat: beat, onContinue: { ctx.finish(beat); onDone() }) {
            VStack(alignment: .leading, spacing: DX.Space.s) {
                Spacer(minLength: DX.Space.xl)
                Text(verbatim: ctx.text(beat.title)).v4Text(.micro)
                VStack(alignment: .leading, spacing: DX.Space.m) {
                    if let top = lines.highlight {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Matters most").v4Text(.micro).foregroundStyle(Read4.accent)
                            Text(verbatim: top).dxFont(24, weight: 700, style: .title2)
                                .foregroundStyle(Read4.ink)
                        }
                        if !lines.rest.isEmpty { Divider() }
                    }
                    ForEach(lines.rest, id: \.self) { line in
                        Text(verbatim: line).dxFont(16, weight: 400, style: .body).foregroundStyle(Read4.ink)
                    }
                }
                .padding(DX.Space.l)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(beat.id.hasPrefix("DX") ? Read4.accentSoft : Read4.card,
                            in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Read4.hairline))
            }
        }
    }
}

// MARK: - info

struct InfoBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    var body: some View {
        BeatFrame(beat: beat, onContinue: { ctx.finish(beat); onDone() }) {
            VStack(alignment: .leading, spacing: DX.Space.s) {
                Spacer(minLength: DX.Space.xl)
                VStack(alignment: .leading, spacing: DX.Space.s) {
                    Image(systemName: "heart").font(.system(size: 30)).foregroundStyle(Read4.accent).accessibilityHidden(true)
                    Text(verbatim: ctx.text(beat.title)).dxFont(24, weight: 700, style: .title2)
                        .foregroundStyle(Read4.ink).accessibilityAddTraits(.isHeader)
                    Text(verbatim: ctx.text(beat.body)).dxFont(16, weight: 400, style: .body)
                        .foregroundStyle(Read4.ink).fixedSize(horizontal: false, vertical: true)
                    if beat.link == "helplines" { HelpLine() }
                }
                .padding(DX.Space.l)
                .background(Read4.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Read4.hairline))
            }
        }
    }
}

// MARK: - share

/// Always optional. A support message opens the share sheet with editable text; milestone cards are images with
/// nothing personal on them unless switched on.
struct ShareBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    @State private var message = ""
    @State private var quote: String?

    private var days: Int {
        switch beat.cardType {
        case "milestone_7": 7
        case "milestone_14": 14
        case "milestone_21": 21
        default: 30
        }
    }

    /// Sentences from the saved letter, for the graduation card's optional quote.
    private var sentences: [String] {
        guard let key = beat.quoteFrom else { return [] }
        let text = ctx.answer(key)?.lines.joined(separator: " ") ?? ""
        return text.split(whereSeparator: { ".!?".contains($0) }).map { $0.trimmingCharacters(in: .whitespaces) }.filter { $0.count > 3 }
    }

    private var card: Image? {
        let renderer = ImageRenderer(content: ShareCard(days: days, extras: quote.map { ["“\($0).”"] } ?? [], look: .dark)
            .frame(width: 1080, height: 1080))
        renderer.scale = 1
        return renderer.uiImage.map(Image.init(uiImage:))
    }

    var body: some View {
        BeatFrame(beat: beat, canContinue: true, continueTitle: "Done", onContinue: { ctx.finish(beat); onDone() },
                  onSkip: { ctx.finish(beat, skipped: true); onDone() }) {
            VStack(alignment: .leading, spacing: DX.Space.s) {
                if beat.cardType == "support_message" {
                    BeatPrompt(text: String(localized: "Give someone a heads-up?"))
                    Text("A message from a friend helps more than you'd think. Change it however you like.").v4Text(.subtitle)
                    TextField("", text: $message, axis: .vertical)
                        .lineLimit(4...8)
                        .dxFont(16, weight: 400, style: .body)
                        .padding(DX.Space.m)
                        .background(Read4.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Read4.accent, lineWidth: 1.5))
                    ShareLink(item: message) {
                        Label("Send it", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.v4Secondary)
                } else {
                    BeatPrompt(text: String(localized: "Share it, if you like"))
                    if let card {
                        card.resizable().scaledToFit().frame(maxWidth: 260)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel(Text("Share card: \(days) days nicotine-free"))
                        if !sentences.isEmpty {
                            Text("Add a line from your note").v4Text(.micro).padding(.top, DX.Space.xs)
                            ForEach(sentences.prefix(4), id: \.self) { sentence in
                                BeatChip(text: sentence, on: quote == sentence) { quote = quote == sentence ? nil : sentence }
                            }
                        }
                        ShareLink(item: card, preview: SharePreview(Text("DayXero"), image: card)) {
                            Label("Share", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.v4Secondary)
                    }
                }
            }
        }
        .onAppear { message = ctx.text(beat.prefill) }
    }
}

// MARK: - nrt_choice

/// Option cards with the safety text always showing. "Set it up" and "Step down first" open the co-pilot and come back here.
struct NRTChoiceBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    @State private var picked: String?
    @State private var showSetup = false
    @State private var showTaper = false

    private var options: [Beat.Option] { beat.options?.resolve(ctx.variant) ?? [] }

    var body: some View {
        BeatFrame(beat: beat, canContinue: picked != nil, onContinue: finish) {
            VStack(alignment: .leading, spacing: 10) {
                BeatPrompt(text: String(localized: "Want nicotine replacement for the first weeks?"))
                ForEach(options) { option in
                    Button { pick(option.id) } label: {
                        OptionRow(text: option.text, selected: picked == option.id)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(picked == option.id ? .isSelected : [])
                }
                SafetyNote(text: ctx.text(beat.safetyText)).padding(.top, DX.Space.xs)
            }
        }
        .fullScreenCover(isPresented: $showSetup) { NRTSetupView(profile: ctx.store.profile) { showSetup = false } }
        .fullScreenCover(isPresented: $showTaper) { TaperSetupView(profile: ctx.store.profile) { showTaper = false } }
        .onAppear { if case let .text(id)? = ctx.answer(beat.saveAs) { picked = id } }
    }

    private func pick(_ id: String) {
        picked = id
        if id == "setup" { showSetup = true }
        if id == "taper" { showTaper = true }
    }

    private func finish() {
        if let picked { ctx.save(beat.saveAs, .text(picked)) }
        ctx.finish(beat)
        onDone()
    }
}

struct SafetyNote: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle").foregroundStyle(Read4.muted).accessibilityHidden(true)
            Text(verbatim: text).dxFont(14, weight: 400, style: .footnote).foregroundStyle(Read4.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DX.Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Read4.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - nrt_stepdown

/// Shown only with an active NRT plan. Opens the co-pilot, which plans the label's step-down and sets reminders.
struct NRTStepdownBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    @State private var showPlanner = false

    var body: some View {
        BeatFrame(beat: beat, onContinue: { ctx.finish(beat); onDone() }) {
            VStack(alignment: .leading, spacing: DX.Space.s) {
                BeatPrompt(text: ctx.text(beat.title))
                Text(verbatim: ctx.text(beat.body)).v4Text(.subtitle)
                Button { showPlanner = true } label: {
                    Label("Plan my step-down", systemImage: "calendar").frame(maxWidth: .infinity)
                }
                .buttonStyle(.v4Secondary)
                SafetyNote(text: ctx.text(beat.safetyText))
            }
        }
        .fullScreenCover(isPresented: $showPlanner) { NRTSetupView(profile: ctx.store.profile) { showPlanner = false } }
    }
}

// MARK: - slip_debrief_practice

/// Runs the real slip debrief in practice mode: the same questions, a "Practice" tag, nothing logged.
struct SlipPracticeBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    @State private var practising = false
    @State private var practised = false

    var body: some View {
        BeatFrame(beat: beat, canContinue: practised || ctx.isReplay, onContinue: { ctx.finish(beat); onDone() }) {
            VStack(alignment: .leading, spacing: DX.Space.m) {
                Spacer(minLength: DX.Space.xl)
                BeatPrompt(text: ctx.text(practised ? beat.outro : beat.intro))
                if !practised {
                    Button { practising = true } label: {
                        Label("Start the practice", systemImage: "figure.walk.motion").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.v4Secondary)
                    Text("Nothing here is logged as a slip.").v4Text(.subtitle)
                }
            }
        }
        .fullScreenCover(isPresented: $practising) {
            SlipFlow(entry: nil, profile: ctx.store.profile, practice: true) {
                practising = false
                practised = true
            }
        }
    }
}

// MARK: - plan_card

/// One tall card with each saved part of the plan, editable in place. Private by default; can be saved as an image.
struct PlanCardBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    @State private var editing: String?
    @State private var draft = ""
    @State private var refresh = 0

    static func heading(_ key: String) -> String {
        switch key {
        case "identity_statement": String(localized: "Who I am now")
        case "primary_reason": String(localized: "Why I'm doing this")
        case "no_line": String(localized: "My no-line")
        case "rough_day_plan": String(localized: "On a rough day")
        case "heavy_day_plan": String(localized: "If something big goes wrong")
        case "bad_day_line": String(localized: "My hard-day line")
        case "break_menu": String(localized: "My breaks")
        case "wind_down": String(localized: "My wind-down")
        default: key.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    /// Who I am first, then the rest in the file's order; empty ones hidden.
    private var rows: [(key: String, lines: [String])] {
        _ = refresh
        let keys = (beat.fields ?? []).sorted { a, _ in a == "identity_statement" }
        return keys.compactMap { key in
            let lines = ctx.answer(key)?.lines ?? []
            return lines.isEmpty ? nil : (key, lines)
        }
    }

    private var image: Image? {
        let card = PlanCardImage(rows: rows.map { (Self.heading($0.key), $0.lines) })
        let renderer = ImageRenderer(content: card.frame(width: 1080))
        renderer.scale = 1
        return renderer.uiImage.map(Image.init(uiImage:))
    }

    var body: some View {
        BeatFrame(beat: beat, onContinue: { ctx.finish(beat); onDone() }) {
            VStack(alignment: .leading, spacing: DX.Space.s) {
                BeatPrompt(text: ctx.text(beat.title))
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { i, row in
                        if i > 0 { Divider() }
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(verbatim: Self.heading(row.key)).v4Text(.micro).foregroundStyle(Read4.accent)
                                ForEach(row.lines, id: \.self) { line in
                                    Text(verbatim: line)
                                        .dxFont(row.key == "identity_statement" ? 19 : 16, weight: row.key == "identity_statement" ? 700 : 400, style: .body)
                                        .foregroundStyle(Read4.ink)
                                }
                            }
                            Spacer()
                            if beat.editable, isEditable(row.key) {
                                Button { startEditing(row.key) } label: {
                                    Image(systemName: "pencil").foregroundStyle(Read4.muted).frame(width: 44, height: 44)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(Text("Edit \(Self.heading(row.key))"))
                            }
                        }
                        .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, DX.Space.m)
                .background(Read4.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Read4.hairline))
                if let image {
                    ShareLink(item: image, preview: SharePreview(Text("My plan"), image: image)) {
                        Label("Save to Photos or share", systemImage: "photo").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.v4Secondary)
                }
            }
        }
        .sheet(item: Binding(get: { editing.map(EditKey.init) }, set: { editing = $0?.key })) { item in
            NavigationStack {
                Form {
                    TextField(Self.heading(item.key), text: $draft, axis: .vertical).lineLimit(2...8)
                    if case .list? = ctx.answer(item.key) { Text("One per line.").v4Text(.subtitle) }
                }
                .navigationTitle(Self.heading(item.key))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { editing = nil } }
                    ToolbarItem(placement: .confirmationAction) { Button("Save") { saveEdit(item.key) } }
                }
            }
            .presentationDetents([.medium])
        }
    }

    struct EditKey: Identifiable {
        let key: String
        var id: String { key }
    }

    private func isEditable(_ key: String) -> Bool {
        switch ctx.answer(key) {
        case .text?, .list?: true
        default: false
        }
    }

    private func startEditing(_ key: String) {
        draft = ctx.answer(key)?.lines.joined(separator: "\n") ?? ""
        editing = key
    }

    private func saveEdit(_ key: String) {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        switch ctx.answer(key) {
        case .list?: ctx.save(key, .list(text.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }))
        default: ctx.save(key, .text(text))
        }
        editing = nil
        refresh += 1
    }
}

/// The plan card as an image, for Photos. Nothing on it but the plan and the wordmark.
struct PlanCardImage: View {
    let rows: [(String, [String])]

    var body: some View {
        VStack(alignment: .leading, spacing: 36) {
            Text(verbatim: "DayXero · My plan").dxFont(44, weight: 800, style: .title1).foregroundStyle(Color(hex: 0xFFC38A))
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                VStack(alignment: .leading, spacing: 10) {
                    Text(verbatim: row.0.uppercased()).dxFont(26, weight: 700, style: .caption1).tracking(2)
                        .foregroundStyle(Color(hex: 0xFFC38A))
                    ForEach(row.1, id: \.self) { line in
                        Text(verbatim: line).dxFont(40, weight: 500, style: .body).foregroundStyle(DX.Fill.cream)
                    }
                }
            }
        }
        .padding(80)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DX.Fill.navy)
    }
}
