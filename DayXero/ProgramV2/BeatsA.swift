import DayXeroCore
import SwiftUI

// Program v2 activities, part one: stat reveal, quiz, choice, sliders, reflect, flip cards (handoff 5.1–5.7).

// MARK: - stat_reveal

struct StatRevealBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                        .font(.custom(DX.Typeface.semibold, size: 28, relativeTo: .title)).tracking(-0.5)
                        .foregroundStyle(i == lines.count - 1 ? DX.Palette.accentInk : DX.Palette.text)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(i < shown ? 1 : 0)
                        .offset(y: i < shown || reduceMotion ? 0 : 10)
                }
            }
            .padding(.top, DX.Space.xxl)
            .accessibilityElement(children: .combine)
        }
        .task {
            if reduceMotion || ctx.isReplay { shown = lines.count; return }
            for i in lines.indices {
                try? await Task.sleep(for: .seconds(i == 0 ? 0.3 : 0.6))
                withAnimation(DX.Motion.glide) { shown = i + 1 }
            }
        }
    }
}

// MARK: - quiz

/// Teaches, never grades: the right answer is shown in sage with its name in words, their pick in a neutral outline.
/// No red, no ✗, no "wrong", no retries, no score.
struct QuizBeat: View {
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
                                        .font(.custom(DX.Typeface.bold, size: 11, relativeTo: .caption2)).tracking(0.8).textCase(.uppercase)
                                        .foregroundStyle(isRight ? DX.Palette.accentInk : DX.Palette.muted)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(picked != nil)
                    .accessibilityAddTraits(isPick ? .isSelected : [])
                }
                if picked != nil, !ctx.text(beat.feedback).isEmpty {
                    BeatFeedback(text: ctx.text(beat.feedback)).padding(.top, DX.Space.xs)
                }
            }
        }
        .sensoryFeedback(DX.Haptic.commit, trigger: rightHaptic)
        .onAppear {
            if case let .text(id)? = ctx.recorded(beat) { picked = id }
        }
    }

    private func pick(_ option: Beat.Option) {
        guard picked == nil else { return }
        withAnimation(DX.Motion.morph) { picked = option.id }
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

    private var ready: Bool {
        let count = selected.count + (otherOn && !other.trimmingCharacters(in: .whitespaces).isEmpty ? 1 : 0)
        if let limit { return count == limit }
        return count > 0
    }

    /// The chosen option's own feedback wins over the activity's.
    private var feedback: String? {
        guard ready else { return nil }
        if let own = options.first(where: { selected.contains($0.id) })?.feedback, !beat.multi { return own }
        let general = ctx.text(beat.feedback)
        return general.isEmpty ? nil : general
    }

    var body: some View {
        BeatFrame(beat: beat, canContinue: ready, onContinue: finish, onSkip: { ctx.finish(beat, skipped: true); onDone() }) {
            VStack(alignment: .leading, spacing: 10) {
                BeatPrompt(text: ctx.text(beat.prompt))
                if beat.multi {
                    if let limit {
                        Text("\(selected.count) of \(limit) picked").font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .body))
                            .foregroundStyle(DX.Palette.accentInk)
                    }
                    DXFlowLayout(spacing: 8) {
                        ForEach(options) { option in
                            let on = selected.contains(option.id)
                            BeatChip(text: option.text, on: on, muted: !on && limit.map { selected.count >= $0 } == true) { toggle(option.id) }
                        }
                    }
                } else {
                    ForEach(options) { option in
                        Button { selectSingle(option.id) } label: { OptionRow(text: option.text, selected: selected.contains(option.id)) }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(selected.contains(option.id) ? .isSelected : [])
                    }
                }
                if beat.allowOther {
                    Button { selectOther() } label: {
                        OptionRow(text: String(localized: "Something else"), selected: otherOn) {
                            if otherOn {
                                TextField("Your own", text: $other)
                                    .font(.custom(DX.Typeface.medium, size: 16, relativeTo: .body))
                                    .padding(12)
                                    .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                if let feedback { BeatFeedback(text: feedback).padding(.top, DX.Space.xs) }
                if let footer = beat.footer.map({ ctx.text($0) }), !footer.isEmpty {
                    Text(verbatim: footer).dxText(.subtitle).padding(.top, DX.Space.xs)
                }
            }
        }
        .sensoryFeedback(DX.Haptic.select, trigger: selected)
        .sensoryFeedback(.impact(weight: .light), trigger: fullHaptic)
        .onAppear(perform: restore)
    }

    private func toggle(_ id: String) {
        if let i = selected.firstIndex(of: id) {
            selected.remove(at: i)
        } else if let limit, selected.count + (otherOn ? 1 : 0) >= limit {
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
        BeatFrame(beat: beat, onContinue: next) {
            VStack(alignment: .leading, spacing: DX.Space.l) {
                BeatPrompt(text: ctx.text(beat.prompt))
                if comparing, let earlier {
                    CompareValues(labels: beat.compareLabels ?? ["Before", "After"], first: earlier, second: Int(value))
                    HStack {
                        Text(verbatim: "0 · \(ctx.text(beat.minLabel))")
                        Spacer()
                        Text(verbatim: "10 · \(ctx.text(beat.maxLabel))")
                    }
                    .dxText(.subtitle)
                } else {
                    BeatSlider(value: $value, minLabel: ctx.text(beat.minLabel), maxLabel: ctx.text(beat.maxLabel), large: true)
                        .padding(.top, DX.Space.l)
                }
                // Feedback shows once the value is set: after the comparison when there is one.
                if comparing || (earlier == nil && touched), !ctx.text(beat.feedback).isEmpty {
                    BeatFeedback(text: ctx.text(beat.feedback))
                }
            }
        }
        .onChange(of: value) { touched = true }
        .onAppear {
            if case let .number(n)? = ctx.answer(beat.saveAs) { value = Double(n) }
        }
    }

    private func next() {
        if !comparing, earlier != nil {
            ctx.save(beat.saveAs, .number(Int(value)))
            withAnimation(DX.Motion.glide) { comparing = true }
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
            Text(verbatim: label).dxText(.micro).foregroundStyle(highlight ? DX.Palette.accentInk : DX.Palette.muted)
            Text(verbatim: "\(value)").font(.custom(DX.Typeface.bold, size: 56, relativeTo: .largeTitle)).tracking(-1.5)
                .foregroundStyle(DX.Palette.text)
        }
        .padding(DX.Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(highlight ? DX.Palette.accentSoft : DX.Palette.surface2, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
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
                Text(verbatim: "\(Int(value))").font(.custom(DX.Typeface.bold, size: 84, relativeTo: .largeTitle)).tracking(-3)
                    .foregroundStyle(DX.Palette.text)
                    .contentTransition(.numericText(value: value))
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
            }
            Slider(value: $value, in: 0...10, step: 1)
                .tint(DX.Palette.accentInk)
                .accessibilityValue(Text(verbatim: "\(Int(value)) of 10, \(minLabel) to \(maxLabel)"))
            HStack {
                Text(verbatim: minLabel)
                Spacer()
                Text(verbatim: maxLabel)
            }
            .font(.custom(DX.Typeface.regular, size: 14, relativeTo: .footnote))
            .foregroundStyle(DX.Palette.text2)
            .accessibilityHidden(true)
        }
        .sensoryFeedback(DX.Haptic.select, trigger: Int(value))
    }
}

// MARK: - slider_group

struct SliderGroupBeat: View {
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
                            Text(verbatim: item.label).font(.custom(DX.Typeface.semibold, size: 16, relativeTo: .body))
                            Spacer()
                            Text(verbatim: "\(Int(values[item.saveAs] ?? 5))").font(.custom(DX.Typeface.bold, size: 22, relativeTo: .title3))
                        }
                        .foregroundStyle(DX.Palette.text)
                        BeatSlider(value: Binding(get: { values[item.saveAs] ?? 5 }, set: { values[item.saveAs] = $0 }),
                                   minLabel: item.minLabel, maxLabel: item.maxLabel)
                    }
                    .padding(DX.Space.m)
                    .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(DX.Palette.hairline))
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
            withAnimation(DX.Motion.glide) { done = true }
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
                            Text(verbatim: guide).font(.custom(DX.Typeface.regular, size: 13, relativeTo: .footnote))
                                .foregroundStyle(DX.Palette.text2)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(DX.Palette.surface2, in: Capsule())
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
                    Text("\(entries.count) of \(beat.maxEntries ?? 1)").dxText(.subtitle)
                    ForEach(Array(entries.enumerated()), id: \.offset) { i, entry in
                        HStack {
                            TextField("", text: Binding(get: { entries.indices.contains(i) ? entries[i] : "" },
                                                        set: { if entries.indices.contains(i) { entries[i] = String($0.prefix(limit)) } }))
                                .font(.custom(DX.Typeface.regular, size: 16, relativeTo: .body))
                            Button { entries.remove(at: i) } label: {
                                Image(systemName: "xmark").font(.system(size: 12, weight: .semibold)).foregroundStyle(DX.Palette.muted)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text("Remove \(entry)"))
                        }
                        .padding(.leading, DX.Space.m)
                        .frame(minHeight: 54)
                        .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(DX.Palette.hairline))
                    }
                    if entries.count < (beat.maxEntries ?? 1) {
                        TextField(ctx.text(beat.placeholder), text: $draft)
                            .font(.custom(DX.Typeface.regular, size: 16, relativeTo: .body))
                            .padding(.horizontal, DX.Space.m)
                            .frame(minHeight: 54)
                            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(DX.Palette.faint, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])))
                            .submitLabel(.done)
                            .onSubmit(addDraft)
                            .focused($focused)
                    }
                } else {
                    TextField(ctx.text(beat.placeholder), text: $draft, axis: .vertical)
                        .lineLimit(beat.length == .long ? 8...14 : 2...4)
                        .font(.custom(DX.Typeface.regular, size: 16, relativeTo: .body))
                        .padding(DX.Space.m)
                        .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(focused ? DX.Palette.accentInk : DX.Palette.hairline, lineWidth: 1.5))
                        .focused($focused)
                        .onChange(of: draft) { _, text in if text.count > limit { draft = String(text.prefix(limit)) } }
                    Text(verbatim: "\(draft.count) / \(limit.formatted())").dxText(.subtitle).frame(maxWidth: .infinity, alignment: .trailing)
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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                Text("\(seen.count) of \(cards.count) flipped").font(.custom(DX.Typeface.semibold, size: 14, relativeTo: .footnote))
                    .foregroundStyle(DX.Palette.text2)
                ForEach(Array(cards.enumerated()), id: \.offset) { i, card in
                    FlipCard(front: card.front, back: card.back, flipped: flipped.contains(i), reduceMotion: reduceMotion) {
                        withAnimation(reduceMotion ? DX.Motion.reduced : .spring(response: 0.5, dampingFraction: 0.8)) {
                            if flipped.contains(i) { flipped.remove(i) } else { flipped.insert(i) }
                        }
                        seen.insert(i)
                    }
                }
                if let footer = beat.footer.map({ ctx.text($0) }), !footer.isEmpty {
                    Text(verbatim: footer).dxText(.subtitle).padding(.top, DX.Space.xs)
                }
            }
        }
        .sensoryFeedback(DX.Haptic.select, trigger: flipped)
    }
}

struct FlipCard: View {
    let front: String
    let back: String
    let flipped: Bool
    let reduceMotion: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                face(back: false).opacity(flipped ? 0 : 1)
                face(back: true).opacity(flipped ? 1 : 0)
                    .rotation3DEffect(.degrees(reduceMotion ? 0 : 180), axis: (0, 1, 0))
            }
            .rotation3DEffect(.degrees(flipped && !reduceMotion ? 180 : 0), axis: (0, 1, 0), perspective: 0.6)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: flipped ? "\(front). \(back)" : front))
        .accessibilityHint(Text(flipped ? "Turns the card back" : "Turns the card over"))
    }

    private func face(back isBack: Bool) -> some View {
        VStack(alignment: .leading, spacing: DX.Space.xs) {
            if isBack {
                Text(verbatim: front).dxText(.micro).foregroundStyle(DX.Palette.accentInk)
                Text(verbatim: back).font(.custom(DX.Typeface.regular, size: 16, relativeTo: .body)).foregroundStyle(DX.Palette.text)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(verbatim: front).font(.custom(DX.Typeface.semibold, size: 20, relativeTo: .title3)).foregroundStyle(DX.Palette.text)
                    .fixedSize(horizontal: false, vertical: true)
                Label("Tap to flip", systemImage: "arrow.triangle.2.circlepath").font(.custom(DX.Typeface.regular, size: 13, relativeTo: .footnote))
                    .foregroundStyle(DX.Palette.muted)
            }
        }
        .padding(DX.Space.m)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .background(isBack ? DX.Palette.accentSoft : DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(isBack ? .clear : DX.Palette.hairline))
    }
}
