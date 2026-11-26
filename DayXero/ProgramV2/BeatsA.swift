import DayXeroCore
import SwiftUI

// Program v2 activities, part one: stat reveal, quiz, choice, sliders, reflect, flip cards (handoff 5.1–5.7).

// MARK: - stat_reveal

struct StatRevealBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    private let motion = MotionPolicy()
    @State private var shown = 0

    /// Lines whose numbers can't all be filled are dropped, never shown with braces.
    private var lines: [String] {
        (beat.lines ?? []).compactMap { $0.resolve(ctx.variant) }.compactMap { ctx.placeholders.fill($0) }
    }

    var body: some View {
        BeatFrame(beat: beat, canContinue: shown >= lines.count, onContinue: { ctx.finish(beat); onDone() }) {
            VStack(alignment: .leading, spacing: DX.Space.l) {
                ForEach(Array(lines.enumerated()), id: \.offset) { i, line in
                    Text(verbatim: line)
                        .dxFace(.display, 32, weight: 600)
                        .foregroundStyle(i == lines.count - 1 ? DX.Ground.table.ink : DX.Ground.table.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(i < shown ? 1 : 0)
                        .offset(y: i < shown || motion.reduce ? 0 : 10)
                }
            }
            .padding(.top, DX.Space.xxl)
            .accessibilityElement(children: .combine)
        }
        .task {
            if motion.reduce || ctx.isReplay { shown = lines.count; return }
            for i in lines.indices {
                try? await Task.sleep(for: .seconds(i == 0 ? 0.3 : 0.6))
                withAnimation(DX.Move.settle) { shown = i + 1 }
            }
        }
    }
}

// MARK: - quiz

/// Teaches, never grades: the right answer is shown in sage with its name in words, their pick in a neutral outline.
/// No red, no ✗, no "wrong", no retries, no score.
struct QuizBeat: View {
    private let motion = MotionPolicy()
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    @State private var picked: String?
    @State private var rightHaptic = false

    private var options: [Beat.Option] { beat.options?.resolve(ctx.variant) ?? [] }

    var body: some View {
        BeatFrame(beat: beat, canContinue: picked != nil, onContinue: finish, onSkip: { ctx.finish(beat, skipped: true); onDone() }) {
            VStack(alignment: .leading, spacing: 10) {
                BeatPrompt(text: ctx.text(beat.prompt), eyebrow: "Quick check")
                ForEach(options) { option in
                    let isRight = option.id == beat.correctId
                    let isPick = option.id == picked
                    Button { pick(option) } label: {
                        if picked == nil {
                            OptionRow(text: option.text)
                        } else {
                            OptionRow(text: option.text, selected: isRight, outlined: isPick && !isRight, dimmed: !isRight && !isPick) {
                                if isRight || isPick {
                                    Text(isRight ? (isPick ? "Your pick · correct answer" : "Correct answer") : "Your pick")
                                        .dxFace(.body, 12, weight: 700).tracking(0.8)
                                        .foregroundStyle(isRight ? DX.Ground.table.ink : DX.Ground.table.muted)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(picked != nil)
                    .accessibilityAddTraits(isPick ? .isSelected : [])
                }
                if let picked, !ctx.text(beat.feedback).isEmpty {
                    BeatFeedback(text: Self.feedback(ctx.text(beat.feedback), right: picked == beat.correctId)).padding(.top, DX.Space.xs)
                }
            }
        }
        .sensoryFeedback(DX.Haptic.commit, trigger: rightHaptic)
        .onAppear {
            if case let .text(id)? = ctx.recorded(beat) { picked = id }
        }
    }

    /// The feedback is written for the right answer ("Right. That's the battery…"). After a different pick it opens
    /// with "Not quite." instead, so a wrong answer never hears "Right." (S27.14).
    static func feedback(_ text: String, right: Bool) -> String {
        guard !right else { return text }
        var rest = text
        for opener in ["Right. ", "Right, ", "Right! ", "Correct. ", "Yes. ", "Exactly. "] where rest.hasPrefix(opener) {
            rest = String(rest.dropFirst(opener.count))
            break
        }
        return String(localized: "Not quite.") + " " + rest
    }

    private func pick(_ option: Beat.Option) {
        guard picked == nil else { return }
        withAnimation(motion.animation(DX.Move.settle)) { picked = option.id }
        let right = option.id == beat.correctId
        if right { rightHaptic.toggle() }
        if !ctx.isReplay { Analytics.track(.programQuizAnswered(beatId: beat.id, firstTryCorrect: right)) }
    }

    private func finish() {
        ctx.finish(beat, value: picked.map { .text($0) })
        onDone()
    }
}

// MARK: - choice

struct ChoiceBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void
    var onBack: (() -> Void)?

    @State private var selected: [String] = []
    @State private var other = ""
    @State private var otherOn = false
    @State private var fullHaptic = false

    private static let otherID = "__other"

    /// The options, or ones built from a saved list (P1.3 picks from your reasons).
    private var options: [Beat.Option] {
        if let from = beat.optionsFrom {
            return (ctx.answer(from)?.lines ?? []).map { Beat.Option(text: $0) }
        }
        return beat.options?.resolve(ctx.variant) ?? []
    }

    private var limit: Int? { beat.pick }

    /// Options built from a saved list that's empty (P1.3 when no reason was written): nothing to pick, so the beat
    /// says so, offers the way back to add one, and lets them carry on instead of leaving Continue disabled.
    private var nothingToPick: Bool { beat.optionsFrom != nil && options.isEmpty && !beat.allowOther }

    private var ready: Bool {
        if nothingToPick { return true }
        let count = selected.count + (otherOn && !other.trimmingCharacters(in: .whitespaces).isEmpty ? 1 : 0)
        if let limit { return count == limit }
        return count > 0
    }

    /// The chosen option's own feedback wins over the activity's, for one pick or several ("Not much yet").
    private var feedback: String? {
        guard ready else { return nil }
        if let own = options.first(where: { selected.contains($0.id) && $0.feedback != nil })?.feedback { return own }
        let general = ctx.text(beat.feedback)
        return general.isEmpty ? nil : general
    }

    var body: some View {
        BeatFrame(beat: beat, canContinue: ready, onContinue: finish, onSkip: { ctx.finish(beat, skipped: true); onDone() }) {
            VStack(alignment: .leading, spacing: 10) {
                BeatPrompt(text: ctx.text(beat.prompt))
                if nothingToPick {
                    emptyState
                } else if beat.multi {
                    // v5 (026): chips hug their words in left-aligned rows; at the cap a new pick releases the oldest.
                    DXFlowLayout(spacing: 8) {
                        ForEach(Array(options.enumerated()), id: \.element.id) { i, option in
                            BeatChip(text: option.text, on: selected.contains(option.id)) { toggle(option.id) }
                                .dxArrive(0, delay: 0.27 + Double(i) * 0.045)
                        }
                        if beat.allowOther {
                            Button { selectOther() } label: {
                                HStack(spacing: 6) {
                                    DXIcon(.plus, size: 16, weight: 2.6).foregroundStyle(DX.Fill.coral)
                                    Text("Add your own").dxFace(.body, 15, weight: 600).foregroundStyle(DX.Ground.table.ink)
                                }
                                .padding(.leading, 12).padding(.trailing, 14)
                                .frame(minHeight: 44)
                                .overlay(RoundedRectangle(cornerRadius: DX.Layout.chipRadius, style: .continuous)
                                    .strokeBorder(otherOn ? DX.Ground.table.selEdge : DX.Ground.table.ink.opacity(0.28),
                                                  style: StrokeStyle(lineWidth: otherOn ? 2 : 1.4, dash: otherOn ? [] : [4, 3])))
                                .background(otherOn ? DX.Ground.table.selTint : .clear, in: RoundedRectangle(cornerRadius: DX.Layout.chipRadius, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    if beat.allowOther && otherOn {
                        TextField("Your own", text: $other)
                            .dxFace(.body, 16, weight: 500)
                            .padding(14)
                            .background(DX.Ground.table.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(DX.Ground.table.line, lineWidth: 1))
                    }
                    if beat.saveAs == "stress_triggers" { planSoFar.padding(.top, 14) }
                } else {
                    // v5 (027): each option with its small paper-cut spot, a detail line and the Recommended pill.
                    ForEach(Array(options.enumerated()), id: \.element.id) { i, option in
                        Button { selectSingle(option.id) } label: {
                            OptionRow(text: option.text, selected: selected.contains(option.id)) {
                                if option.detail != nil || option.recommended == true {
                                    HStack(spacing: 8) {
                                        if let detail = option.detail {
                                            Text(verbatim: detail).dxType(.footnote).foregroundStyle(DX.Ground.table.muted)
                                        }
                                        if option.recommended == true {
                                            Text("Recommended").dxFace(.body, 11, weight: 700)
                                                .foregroundStyle(DX.Ground.table.ink)
                                                .padding(.horizontal, 7).frame(height: 18)
                                                .overlay(Capsule().strokeBorder(DX.Ground.table.ink.opacity(0.7), lineWidth: 1))
                                        }
                                    }
                                }
                            } leading: {
                                ChoiceSpot(id: option.id)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selected.contains(option.id) ? .isSelected : [])
                        .dxSettle(0, delay: 0.27 + Double(i) * 0.12)
                    }
                }
                if beat.allowOther && !beat.multi {
                    Button { selectOther() } label: {
                        OptionRow(text: String(localized: "Something else"), selected: otherOn) {
                            if otherOn {
                                TextField("Your own", text: $other)
                                    .dxFace(.body, 16, weight: 500)
                                    .padding(12)
                                    .background(DX.Ground.table.card2, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                if let feedback { BeatFeedback(text: feedback).padding(.top, DX.Space.xs) }
                if let footer = beat.footer.map({ ctx.text($0) }), !footer.isEmpty {
                    Text(verbatim: footer).dxType(.footnote).foregroundStyle(DX.Ground.table.muted).padding(.top, DX.Space.xs)
                }
            }
        }
        .sensoryFeedback(DX.Haptic.select, trigger: selected)
        .sensoryFeedback(.impact(weight: .light), trigger: fullHaptic)
        .onAppear(perform: restore)
    }

    /// "Your plan so far" (026): each pick writes itself into a "When …, I'll ____" line, left blank for the next step.
    private var planSoFar: some View {
        let picked = options.filter { selected.contains($0.id) }.map { $0.text.prefix(1).lowercased() + $0.text.dropFirst() }
        return VStack(alignment: .leading, spacing: 10) {
            Text("Your plan so far").dxType(.caption).foregroundStyle(DX.Ground.table.muted)
            ForEach(0..<2, id: \.self) { i in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    if i < picked.count {
                        (Text("When ") + Text(verbatim: picked[i]).dxRun(15, weight: 700) + Text(", I'll"))
                            .contentTransition(.opacity)
                    } else {
                        Text("When ") + Text(verbatim: "…").dxRun(15, weight: 700) + Text(", I'll")
                    }
                    Rectangle().fill(DX.Ground.table.ink.opacity(0.35)).frame(width: 74, height: 1.5).offset(y: -2)
                }
                .dxType(.footnote).foregroundStyle(DX.Ground.table.ink)
                .animation(.easeInOut(duration: 0.3), value: picked)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DX.Ground.table.card, in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous).strokeBorder(DX.Ground.table.line, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .dxArrive(8)
    }

    private var fromReasons: Bool { beat.optionsFrom == "reasons" }

    private var emptyMessage: LocalizedStringKey {
        if fromReasons { return "You haven't written a reason yet. Go back and add one, and it'll show up here to pick." }
        return "There's nothing here to pick yet. Go back and add something first."
    }

    private var emptyBackTitle: LocalizedStringKey {
        if fromReasons { return "Add a reason" }
        return "Go back"
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: DX.Space.s) {
            Text(emptyMessage)
                .dxFace(.body, 16, weight: 400)
                .foregroundStyle(DX.Ground.table.muted)
                .fixedSize(horizontal: false, vertical: true)
            if let onBack {
                Button(action: onBack) {
                    HStack(spacing: 6) {
                        DXIcon(.back, size: 16)
                        Text(emptyBackTitle)
                    }
                }
                .buttonStyle(.dx(.secondary, on: .reading))
                .accessibilityIdentifier("program.choice.back")
            }
        }
    }

    private func toggle(_ id: String) {
        if let i = selected.firstIndex(of: id) {
            selected.remove(at: i)
        } else if let limit, selected.count + (otherOn ? 1 : 0) >= limit {
            // At the cap a new pick releases the oldest, so the screen never blocks (026).
            if !selected.isEmpty { selected.removeFirst() } else { otherOn = false }
            selected.append(id)
            fullHaptic.toggle()
        } else {
            selected.append(id)
        }
    }

    private func selectSingle(_ id: String) {
        selected = [id]
        otherOn = false
    }

    private func selectOther() {
        if beat.multi {
            otherOn.toggle()
        } else {
            selected = []
            otherOn = true
        }
    }

    private func restore() {
        guard let saved = ctx.answer(beat.saveAs) ?? ctx.recorded(beat) else { return }
        let texts = saved.lines
        selected = options.filter { texts.contains($0.text) }.map(\.id)
        let unmatched = texts.filter { t in !options.contains { $0.text == t } }
        if beat.allowOther, let own = unmatched.first { other = own; otherOn = true }
    }

    private func finish() {
        // Nothing was picked because there was nothing to pick: record it as skipped rather than saving an empty answer.
        if nothingToPick {
            ctx.finish(beat, skipped: true)
            onDone()
            return
        }
        var texts = options.filter { selected.contains($0.id) }.map(\.text)
        if otherOn, !other.trimmingCharacters(in: .whitespaces).isEmpty { texts.append(other.trimmingCharacters(in: .whitespaces)) }
        let value: ProgramAnswerValue = beat.multi ? .list(texts) : .text(texts.first ?? "")
        ctx.save(beat.saveAs, value)
        ctx.finish(beat, value: beat.saveAs == nil ? value : nil)
        onDone()
    }
}

extension Beat.Option {
    /// An option made from a saved line, its text doubling as its ID.
    init(text: String) {
        self.init(id: text, text: text, feedback: nil)
    }
}

// MARK: - slider

/// 0–10 with a haptic per step. With `compareWith`, Continue shows both values side by side, with no comment on the difference.
struct SliderBeat: View {
    private let motion = MotionPolicy()
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    @State private var value = 5.0
    @State private var comparing = false
    @State private var touched = false

    private var earlier: Int? {
        if case let .number(n)? = ctx.answer(beat.compareWith) { return n }
        return nil
    }

    var body: some View {
        BeatFrame(beat: beat, continueTitle: comparing ? "Continue" : "That's about right", onContinue: next) {
            VStack(alignment: .leading, spacing: DX.Space.l) {
                BeatPrompt(text: ctx.text(beat.prompt))
                if comparing, let earlier {
                    CompareValues(labels: beat.compareLabels ?? ["Before", "After"], first: earlier, second: Int(value))
                    HStack {
                        Text(verbatim: "0 · \(ctx.text(beat.minLabel))")
                        Spacer()
                        Text(verbatim: "10 · \(ctx.text(beat.maxLabel))")
                    }
                    .dxType(.footnote).foregroundStyle(DX.Ground.table.muted)
                    if !ctx.text(beat.feedback).isEmpty { BeatFeedback(text: ctx.text(beat.feedback)) }
                } else {
                    // v5 (028): the reading as one unit: the number, the calm-to-tense track, and Xero with his line.
                    VStack(spacing: 18) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(verbatim: "\(Int(value))")
                                .dxFace(.display, 96, weight: 800, tracking: -3)
                                .monospacedDigit()
                                .contentTransition(.numericText(value: value))
                            Text(verbatim: "/10").dxFace(.display, 24, weight: 800).foregroundStyle(DX.Ground.table.muted)
                        }
                        .foregroundStyle(DX.Ground.table.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, -14)
                        TensionTrack(value: $value, minLabel: ctx.text(beat.minLabel), maxLabel: ctx.text(beat.maxLabel))
                        HStack(alignment: .center, spacing: 10) {
                            XeroView(mood: Int(value) <= 3 ? .calm : .hello, stage: 0, points: 112)
                                .animation(.easeInOut(duration: 0.15), value: Int(value) <= 3)
                                .accessibilityHidden(true)
                            Text(verbatim: line)
                                .dxType(.footnote).foregroundStyle(DX.Ground.table.ink)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 14).padding(.vertical, 12)
                                .background(DX.Ground.table.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(DX.Ground.table.line, lineWidth: 1))
                                .contentTransition(.opacity)
                                .animation(.easeInOut(duration: 0.2), value: Int(value))
                                .dxArrive(6)
                        }
                        .padding(.top, 8)
                    }
                    .dxFade(delay: 0.27)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: Int(value))
        .onChange(of: value) { if settled { touched = true } }
        .task {
            if case let .number(n)? = ctx.answer(beat.saveAs) { value = Double(n); settled = true; return }
            // The thumb glides up from Calm to the middle while the number counts with it.
            guard !motion.reduce else { settled = true; return }
            value = 0
            try? await Task.sleep(for: .milliseconds(400))
            for v in 1...5 {
                withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.22)) { value = Double(v) }
                try? await Task.sleep(for: .milliseconds(220))
            }
            settled = true
        }
    }

    @State private var settled = false

    /// Xero's line for where the reading sits: the beat's own feedback, or a word for a tension check.
    private var line: String {
        let n = Int(value)
        let feedback = ctx.text(beat.feedback)
        if !feedback.isEmpty && touched { return feedback }
        return switch n {
        case 0...3: String(localized: "A calm \(n). Let's see what a few minutes of breathing does.")
        case 4...6: String(localized: "An honest \(n). Let's see what five minutes of breathing does.")
        default: String(localized: "A tense \(n). Five minutes of breathing can take the edge off.")
        }
    }

    private func next() {
        if !comparing, earlier != nil {
            ctx.save(beat.saveAs, .number(Int(value)))
            withAnimation(motion.animation(DX.Move.settle)) { comparing = true }
            return
        }
        ctx.save(beat.saveAs, .number(Int(value)))
        ctx.finish(beat)
        onDone()
    }
}

struct CompareValues: View {
    let labels: [String]
    let first: Int
    let second: Int

    var body: some View {
        HStack(spacing: DX.Space.s) {
            box(labels.first ?? "", first, highlight: false)
            box(labels.count > 1 ? labels[1] : "", second, highlight: true)
        }
        .accessibilityElement(children: .combine)
    }

    private func box(_ label: String, _ value: Int, highlight: Bool) -> some View {
        VStack(alignment: .leading, spacing: DX.Space.xs) {
            Text(verbatim: label).dxType(.caption).foregroundStyle(DX.Ground.table.muted).foregroundStyle(highlight ? DX.Ground.table.ink : DX.Ground.table.muted)
            Text(verbatim: "\(value)").dxFace(.display, 40, weight: 700)
                .foregroundStyle(DX.Ground.table.ink)
        }
        .padding(DX.Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(highlight ? DX.Ground.table.selTint : DX.Ground.table.card2, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

/// A 0–10 slider with its value shown, end labels and a selection haptic per step. VoiceOver adjusts it by swiping.
struct BeatSlider: View {
    @Binding var value: Double
    let minLabel: String
    let maxLabel: String
    var large = false

    var body: some View {
        VStack(spacing: DX.Space.s) {
            if large {
                Text(verbatim: "\(Int(value))").dxFace(.display, 40, weight: 700)
                    .foregroundStyle(DX.Ground.table.ink)
                    .contentTransition(.numericText(value: value))
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
            }
            Slider(value: $value, in: 0...10, step: 1)
                .tint(DX.Ground.table.sel)
                .accessibilityValue(Text(verbatim: "\(Int(value)) of 10, \(minLabel) to \(maxLabel)"))
            HStack {
                Text(verbatim: minLabel)
                Spacer()
                Text(verbatim: maxLabel)
            }
            .dxFace(.body, 14, weight: 400)
            .foregroundStyle(DX.Ground.table.muted)
            .accessibilityHidden(true)
        }
        .sensoryFeedback(DX.Haptic.select, trigger: Int(value))
    }
}

// MARK: - slider_group

struct SliderGroupBeat: View {
    private let motion = MotionPolicy()
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    @State private var values: [String: Double] = [:]
    @State private var done = false

    var body: some View {
        BeatFrame(beat: beat, onContinue: finish) {
            VStack(alignment: .leading, spacing: DX.Space.s) {
                BeatPrompt(text: ctx.text(beat.prompt))
                ForEach(beat.sliders ?? [], id: \.saveAs) { item in
                    VStack(alignment: .leading, spacing: DX.Space.xs) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(verbatim: item.label).dxFace(.body, 16, weight: 600)
                            Spacer()
                            Text(verbatim: "\(Int(values[item.saveAs] ?? 5))").dxFace(.display, 24, weight: 700)
                        }
                        .foregroundStyle(DX.Ground.table.ink)
                        BeatSlider(value: Binding(get: { values[item.saveAs] ?? 5 }, set: { values[item.saveAs] = $0 }),
                                   minLabel: item.minLabel, maxLabel: item.maxLabel)
                    }
                    .padding(DX.Space.m)
                    .background(DX.Ground.table.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(DX.Ground.table.line))
                }
                if done, !ctx.text(beat.feedback).isEmpty { BeatFeedback(text: ctx.text(beat.feedback)) }
            }
        }
        .onAppear {
            for item in beat.sliders ?? [] {
                if case let .number(n)? = ctx.answer(item.saveAs) { values[item.saveAs] = Double(n) }
            }
        }
    }

    private func finish() {
        for item in beat.sliders ?? [] { ctx.save(item.saveAs, .number(Int(values[item.saveAs] ?? 5))) }
        if !done, !ctx.text(beat.feedback).isEmpty {
            withAnimation(motion.animation(DX.Move.settle)) { done = true }
            return
        }
        ctx.finish(beat)
        onDone()
    }
}

// MARK: - reflect

struct ReflectBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    @State private var entries: [String] = []
    @State private var draft = ""
    @FocusState private var focused: Bool

    private var isList: Bool { (beat.maxEntries ?? 1) > 1 }
    private var limit: Int { beat.length == .long ? 1000 : 140 }

    var body: some View {
        BeatFrame(beat: beat, onContinue: finish, onSkip: { ctx.finish(beat, skipped: true); onDone() }) {
            VStack(alignment: .leading, spacing: 10) {
                BeatPrompt(text: ctx.text(beat.prompt))
                if let guides = beat.guidePrompts {
                    DXFlowLayout(spacing: 6) {
                        ForEach(guides, id: \.self) { guide in
                            Text(verbatim: guide).dxFace(.body, 14, weight: 400)
                                .foregroundStyle(DX.Ground.table.muted)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(DX.Ground.table.card2, in: Capsule())
                        }
                    }
                }
                if let chips = beat.chips {
                    DXFlowLayout(spacing: 8) {
                        ForEach(chips, id: \.self) { chip in
                            BeatChip(text: chip, on: draft.contains(chip)) { insert(chip) }
                        }
                    }
                }
                if isList {
                    Text("\(entries.count) of \(beat.maxEntries ?? 1)").dxType(.footnote).foregroundStyle(DX.Ground.table.muted)
                    ForEach(Array(entries.enumerated()), id: \.offset) { i, entry in
                        HStack {
                            TextField("", text: Binding(get: { entries.indices.contains(i) ? entries[i] : "" },
                                                        set: { if entries.indices.contains(i) { entries[i] = String($0.prefix(limit)) } }))
                                .dxFace(.body, 16, weight: 400)
                            Button { entries.remove(at: i) } label: {
                                DXIcon(.close, size: 12, weight: 2.6).foregroundStyle(DX.Ground.table.muted)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text("Remove \(entry)"))
                        }
                        .padding(.leading, DX.Space.m)
                        .frame(minHeight: 54)
                        .background(DX.Ground.table.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(DX.Ground.table.line))
                    }
                    if entries.count < (beat.maxEntries ?? 1) {
                        TextField(ctx.text(beat.placeholder), text: $draft)
                            .dxFace(.body, 16, weight: 400)
                            .padding(.horizontal, DX.Space.m)
                            .frame(minHeight: 54)
                            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(DX.Ground.table.line, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])))
                            .submitLabel(.done)
                            .onSubmit(addDraft)
                            .focused($focused)
                    }
                } else {
                    TextField(ctx.text(beat.placeholder), text: $draft, axis: .vertical)
                        .lineLimit(beat.length == .long ? 8...14 : 2...4)
                        .dxFace(.body, 16, weight: 400)
                        .padding(DX.Space.m)
                        .background(DX.Ground.table.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(focused ? DX.Ground.table.selEdge : DX.Ground.table.line, lineWidth: 1.5))
                        .focused($focused)
                        .onChange(of: draft) { _, text in if text.count > limit { draft = String(text.prefix(limit)) } }
                    Text(verbatim: "\(draft.count) / \(limit.formatted())").dxType(.footnote).foregroundStyle(DX.Ground.table.muted).frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .onAppear(perform: prefill)
    }

    private func prefill() {
        let saved = ctx.answer(beat.saveAs) ?? ctx.answer(beat.prefillFrom)
        if isList {
            entries = saved?.lines ?? []
        } else if let line = saved?.lines.joined(separator: "\n") {
            draft = line
        }
    }

    private func insert(_ chip: String) {
        if draft.contains(chip) { return }
        draft = draft.isEmpty ? chip : draft.trimmingCharacters(in: .whitespaces) + (draft.hasSuffix(".") ? " " : ". ") + chip
    }

    private func addDraft() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        entries.append(String(text.prefix(limit)))
        draft = ""
        focused = true
    }

    private func finish() {
        if isList {
            addDraft()
            let lines = entries.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            if !lines.isEmpty { ctx.save(beat.saveAs, .list(lines)) }
        } else {
            let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty { ctx.save(beat.saveAs, .text(text)) }
        }
        ctx.finish(beat)
        onDone()
    }
}

// MARK: - tap_reveal

/// Flip cards. Continue enables once each has been turned. Under Reduce Motion they cross-fade instead of flipping.
struct TapRevealBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    private let motion = MotionPolicy()
    @State private var flipped: Set<Int> = []
    @State private var seen: Set<Int> = []

    /// Cards with something on the back; a card whose saved answer is empty is hidden.
    private var cards: [(front: String, back: String)] {
        (beat.cards ?? []).compactMap { card in
            if let key = card.backFrom {
                let lines = ctx.answer(key)?.lines ?? []
                return lines.isEmpty ? nil : (card.front, lines.joined(separator: "\n"))
            }
            return card.back.map { (card.front, $0) }
        }
    }

    var body: some View {
        BeatFrame(beat: beat, canContinue: ctx.isReplay || seen.count >= cards.count, onContinue: { ctx.finish(beat); onDone() }) {
            VStack(alignment: .leading, spacing: DX.Space.s) {
                if let title = beat.title.map({ ctx.text($0) }), !title.isEmpty { BeatPrompt(text: title) }
                Text("\(seen.count) of \(cards.count) turned over").dxFace(.body, 14, weight: 600)
                    .foregroundStyle(DX.Ground.table.muted)
                ForEach(Array(cards.enumerated()), id: \.offset) { i, card in
                    FlipCard(front: card.front, back: card.back, flipped: flipped.contains(i), reduceMotion: motion.reduce) {
                        withAnimation(motion.animation(.spring(response: 0.5, dampingFraction: 0.8))) {
                            if flipped.contains(i) { flipped.remove(i) } else { flipped.insert(i) }
                        }
                        seen.insert(i)
                    }
                }
                if let footer = beat.footer.map({ ctx.text($0) }), !footer.isEmpty {
                    Text(verbatim: footer).dxType(.footnote).foregroundStyle(DX.Ground.table.muted).padding(.top, DX.Space.xs)
                }
            }
        }
        .sensoryFeedback(DX.Haptic.select, trigger: flipped)
    }
}

/// A flip card (v5, after the lesson cards of 034). Face down it is an apricot card with the question and "Turn over";
/// turned over, a white card with the question small and the answer beside a coral rule. It turns as one card, and
/// cross-fades with Reduce Motion.
struct FlipCard: View {
    let front: String
    let back: String
    let flipped: Bool
    let reduceMotion: Bool
    let action: () -> Void

    private var angle: Double { flipped ? 0 : 180 }

    var body: some View {
        Button(action: action) {
            answer.modifier(LessonFlip(angle: angle, isRear: false))
                .overlay { question.modifier(LessonFlip(angle: angle, isRear: true)) }
                .shadow(color: Color(red: 60 / 255, green: 40 / 255, blue: 20 / 255).opacity(0.1), radius: 8, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: flipped ? "\(front). \(back)" : front))
        .accessibilityHint(Text(flipped ? "Turns the card back" : "Turns the card over"))
    }

    /// Turned over: the question, small, and the answer.
    private var answer: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(verbatim: front).dxType(.caption).foregroundStyle(DX.Ground.table.muted)
                .fixedSize(horizontal: false, vertical: true)
            Text(verbatim: back).dxFace(.body, 16, weight: 600).foregroundStyle(DX.Ground.table.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 12)
                .overlay(alignment: .leading) { Capsule().fill(DX.Fill.coral).frame(width: 3) }
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
        .background(DX.Ground.table.card, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(DX.Ground.table.line))
    }

    /// Face down: the question on apricot. The ink is fixed, because the card is apricot in light and dark.
    private var question: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: front).dxFace(.display, 19, weight: 700).foregroundStyle(Color(hex: 0x1E1A3A))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                DXIcon(.card, size: 16)
                Text("Turn over")
            }
            .dxFace(.body, 14, weight: 700)
            .foregroundStyle(Color(hex: 0x4A2810))
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(LinearGradient(colors: [Color(hex: 0xFFE2C6), Color(hex: 0xFFC38A)], startPoint: .top, endPoint: .bottom),
                    in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}

/// The calm-to-tense track (028): calm blue to coral, a white thumb, eleven short ticks under it and the two ends.
struct TensionTrack: View {
    @Binding var value: Double
    let minLabel: String
    let maxLabel: String

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { proxy in
                let w = proxy.size.width
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LinearGradient(colors: [Color(hex: 0x9CCBFF), Color(hex: 0xFFB27F), Color(hex: 0xFF7A55)], startPoint: .leading, endPoint: .trailing))
                        .frame(height: 10)
                    Circle().fill(.white)
                        .overlay(Circle().strokeBorder(DX.Ground.table.ink.opacity(0.15), lineWidth: 1))
                        .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
                        .frame(width: 30, height: 30)
                        .offset(x: (w - 30) * value / 10)
                }
                .frame(height: 30)
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0).onChanged { g in
                    // Typed step by step: Xcode 26 (the iOS 18 CI leg) finds `*` ambiguous in the one-line form.
                    let along: Double = Double(g.location.x - 15) / Double(max(w - 30, 1))
                    value = min(max((along * 10).rounded(), 0), 10)
                })
            }
            .frame(height: 30)
            HStack(spacing: 0) {
                ForEach(0...10, id: \.self) { i in
                    Capsule().fill(DX.Ground.table.ink.opacity(0.22)).frame(width: 2, height: 6)
                    if i < 10 { Spacer(minLength: 0) }
                }
            }
            .padding(.horizontal, 14)
            HStack {
                Text(verbatim: minLabel).foregroundStyle(Color(light: 0x2F6FCC, dark: 0x9CCBFF))
                Spacer()
                Text(verbatim: maxLabel).foregroundStyle(Color(light: 0xD9542E, dark: 0xFF8A65))
            }
            .dxFace(.body, 13, weight: 700)
        }
        .accessibilityElement()
        .accessibilityLabel(Text(verbatim: "\(minLabel) to \(maxLabel)"))
        .accessibilityValue(Text("\(Int(value)) of 10"))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = min(value + 1, 10)
            case .decrement: value = max(value - 1, 0)
            @unknown default: break
            }
        }
    }
}
