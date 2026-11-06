import DayXeroCore
import SwiftUI

// Program v3, second build (6 Nov 2026): the activities the prep days asked for that the beats couldn't do yet.
// The body map, the 0–10 dial and the timed hold for Prep 5's control test, a practice run of Craving SOS for
// Day Xero, and the same questions for each trigger in Prep 2.

// MARK: - Body map

/// "Where do you feel it?" on a simple figure. Places on the figure are buttons; options with no place on it
/// ("I can't place it") sit underneath as chips. Saves the chosen places' words as a list, like a multi choice.
struct BodyMapBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    @State private var selected: Set<String> = []

    /// Where each known place sits on the figure, as a fraction of its frame.
    static let spots: [String: UnitPoint] = [
        "head": UnitPoint(x: 0.5, y: 0.09), "mouth": UnitPoint(x: 0.5, y: 0.17), "throat": UnitPoint(x: 0.5, y: 0.25),
        "chest": UnitPoint(x: 0.5, y: 0.37), "stomach": UnitPoint(x: 0.5, y: 0.52), "hands": UnitPoint(x: 0.13, y: 0.56),
        "legs": UnitPoint(x: 0.5, y: 0.82),
    ]

    static let defaultOptions: [Beat.Option] = [
        .init(id: "head", text: String(localized: "Head")), .init(id: "throat", text: String(localized: "Throat")),
        .init(id: "chest", text: String(localized: "Chest")), .init(id: "stomach", text: String(localized: "Stomach")),
        .init(id: "hands", text: String(localized: "Hands")), .init(id: "legs", text: String(localized: "Legs")),
        .init(id: "unsure", text: String(localized: "I can't place it")),
    ]

    private var options: [Beat.Option] { beat.options?.resolve(ctx.variant) ?? Self.defaultOptions }
    private var onFigure: [Beat.Option] { options.filter { Self.spots[$0.id] != nil } }
    private var offFigure: [Beat.Option] { options.filter { Self.spots[$0.id] == nil } }

    var body: some View {
        BeatFrame(beat: beat, canContinue: !selected.isEmpty || beat.optional, onContinue: finish,
                  onSkip: { ctx.finish(beat, skipped: true); onDone() }) {
            BeatPrompt(text: ctx.text(beat.prompt))
            if let footer = beat.footer {
                Text(verbatim: ctx.text(footer)).dxType(.footnote).foregroundStyle(Read4.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            figure
                .frame(maxWidth: .infinity)
                .padding(.vertical, DX.Space.s)
            if !offFigure.isEmpty {
                DXFlowLayout(spacing: 8) {
                    ForEach(offFigure) { option in
                        BeatChip(text: option.text, on: selected.contains(option.id)) { toggle(option.id) }
                    }
                }
            }
        }
        .onAppear(perform: restore)
    }

    private var figure: some View {
        let width: CGFloat = 220, height: CGFloat = 330
        return ZStack {
            // A plain figure: head, body, arms and legs in the reading ground's inset fill.
            Group {
                Circle().frame(width: 58, height: 58).position(x: width / 2, y: 34)
                RoundedRectangle(cornerRadius: 30, style: .continuous).frame(width: 96, height: 130).position(x: width / 2, y: 140)
                Capsule().frame(width: 26, height: 120).rotationEffect(.degrees(14)).position(x: 50, y: 150)
                Capsule().frame(width: 26, height: 120).rotationEffect(.degrees(-14)).position(x: width - 50, y: 150)
                Capsule().frame(width: 30, height: 120).position(x: width / 2 - 22, y: 262)
                Capsule().frame(width: 30, height: 120).position(x: width / 2 + 22, y: 262)
            }
            .foregroundStyle(Read4.surface)
            .accessibilityHidden(true)
            ForEach(onFigure) { option in
                let spot = Self.spots[option.id] ?? .center
                let on = selected.contains(option.id)
                Button { toggle(option.id) } label: {
                    Text(verbatim: option.text)
                        .dxFont(14, weight: on ? 700 : 600, style: .footnote)
                        .foregroundStyle(on ? Read4.background : Read4.ink)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 36)
                        .background(on ? Read4.accent : Read4.card, in: Capsule())
                        .overlay(Capsule().strokeBorder(on ? Read4.accent : Read4.hairline, lineWidth: 1))
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
                .position(x: spot.x * width, y: spot.y * height)
            }
        }
        .frame(width: width, height: height)
    }

    private func toggle(_ id: String) {
        if selected.contains(id) { selected.remove(id) } else { selected.insert(id) }
    }

    private func restore() {
        guard selected.isEmpty, let saved = ctx.answer(beat.saveAs)?.lines, !saved.isEmpty else { return }
        selected = Set(options.filter { saved.contains($0.text) }.map(\.id))
    }

    private func finish() {
        let texts = options.filter { selected.contains($0.id) }.map(\.text)
        ctx.save(beat.saveAs, .list(texts))
        ctx.finish(beat, value: .list(texts))
        onDone()
    }
}

// MARK: - 0–10 dial

/// A big number from 0 to 10 with minus and plus, and the eleven steps underneath to tap. Saves a number, so it
/// compares with a slider's answer or another dial's ("From 7 to 4").
struct ScaleBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    @State private var value = 5
    @State private var touched = false
    private let motion = MotionPolicy()

    private var earlier: Int? {
        if case let .number(n)? = ctx.answer(beat.compareWith) { return n }
        return nil
    }

    var body: some View {
        BeatFrame(beat: beat, onContinue: finish, onSkip: { ctx.finish(beat, skipped: true); onDone() }) {
            BeatPrompt(text: ctx.text(beat.prompt))
            HStack(spacing: 22) {
                stepButton("minus", label: "Less") { set(value - 1) }
                Text(verbatim: "\(value)")
                    .dxFont(88, weight: 800, style: .largeTitle)
                    .monospacedDigit()
                    .foregroundStyle(Read4.ink)
                    .frame(minWidth: 120)
                    .contentTransition(motion.reduce ? ContentTransition.identity : .numericText())
                    .accessibilityHidden(true)
                stepButton("plus", label: "More") { set(value + 1) }
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: ctx.text(beat.prompt)))
            .accessibilityValue(Text("\(value) out of 10"))
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: set(value + 1)
                case .decrement: set(value - 1)
                @unknown default: break
                }
            }
            HStack(spacing: 4) {
                ForEach(0...10, id: \.self) { step in
                    Button { set(step) } label: {
                        Circle()
                            .fill(step <= value ? Read4.accent : Read4.surface)
                            .frame(width: 22, height: 22)
                            .frame(maxWidth: .infinity, minHeight: 36)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .accessibilityHidden(true)
            HStack {
                Text(verbatim: ctx.text(beat.minLabel)).dxType(.footnote).foregroundStyle(Read4.muted)
                Spacer(minLength: DX.Space.s)
                Text(verbatim: ctx.text(beat.maxLabel)).dxType(.footnote).foregroundStyle(Read4.muted)
                    .multilineTextAlignment(.trailing)
            }
            if touched || ctx.isReplay {
                if let earlier {
                    Text(verbatim: compareLine(earlier)).dxType(.headline).foregroundStyle(Read4.ink)
                        .padding(.top, DX.Space.xs)
                }
                if let feedback = beat.feedback {
                    BeatFeedback(text: ctx.text(feedback))
                }
            }
        }
        .onAppear {
            if case let .number(saved)? = ctx.answer(beat.saveAs) { value = min(max(saved, 0), 10) }
        }
    }

    private func compareLine(_ before: Int) -> String {
        if before == value { return String(localized: "It's still \(value). That's fine too.") }
        return String(localized: "From \(before) to \(value).")
    }

    private func stepButton(_ symbol: String, label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 22, weight: .bold))
                .foregroundStyle(Read4.ink)
                .frame(width: 60, height: 60)
                .background(Read4.surface, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }

    private func set(_ new: Int) {
        let clamped = min(max(new, 0), 10)
        withAnimation(motion.animation(DX.Move.settle)) { value = clamped }
        touched = true
    }

    private func finish() {
        ctx.save(beat.saveAs, .number(value))
        ctx.finish(beat, value: .number(value))
        onDone()
    }
}

// MARK: - Timed hold

/// "Picture it. Stay with it for 15 seconds." A ring empties as the seconds pass; Continue appears at the end.
struct TimedHoldBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    @State private var left = 0
    @State private var started = false
    private let motion = MotionPolicy()

    private var total: Int { max(beat.holdSeconds ?? 15, 1) }
    private var done: Bool { left <= 0 }

    var body: some View {
        BeatFrame(beat: beat, canContinue: done || ctx.isReplay, onContinue: { ctx.finish(beat); onDone() },
                  onSkip: { ctx.finish(beat, skipped: true); onDone() }) {
            BeatPrompt(text: ctx.text(beat.title ?? beat.prompt))
            if let body = beat.body {
                Text(verbatim: ctx.text(body)).dxType(.body).foregroundStyle(Read4.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ZStack {
                Circle().stroke(Read4.surface, lineWidth: 10)
                Circle()
                    .trim(from: 0, to: CGFloat(left) / CGFloat(total))
                    .stroke(Read4.accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(motion.reduce ? nil : .linear(duration: 1), value: left)
                Text(verbatim: done ? String(localized: "Done") : "\(left)")
                    .dxFont(44, weight: 800, style: .largeTitle)
                    .monospacedDigit()
                    .foregroundStyle(Read4.ink)
            }
            .frame(width: 180, height: 180)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DX.Space.m)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(done ? String(localized: "Done") : String(localized: "\(left) seconds left")))
            if done, let feedback = beat.feedback {
                BeatFeedback(text: ctx.text(feedback))
            }
        }
        .task {
            // Counts down once, a second at a time; leaving the screen cancels it.
            guard !started, !ctx.isReplay else { return }
            started = true
            left = total
            while left > 0 {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                left -= 1
            }
        }
    }
}

// MARK: - Craving SOS practice

/// Day Xero: a run through Craving SOS before the first real craving. It opens SOS in practice mode, which saves
/// nothing, starts no Lock Screen timer and never opens the slip talk-through.
struct SOSPracticeBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    @State private var showing = false
    @State private var tried = false

    var body: some View {
        BeatFrame(beat: beat, canContinue: tried || beat.optional || ctx.isReplay,
                  onContinue: { ctx.finish(beat); onDone() }, onSkip: { ctx.finish(beat, skipped: true); onDone() }) {
            BeatPrompt(text: ctx.text(beat.title ?? beat.prompt))
            if let body = beat.body {
                Text(verbatim: ctx.text(body)).dxType(.body).foregroundStyle(Read4.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button {
                showing = true
            } label: {
                Label(beat.label.map { ctx.text($0) } ?? String(localized: "Try a practice run"), systemImage: "water.waves")
            }
            .buttonStyle(.dx(.secondary, on: .reading))
            .padding(.top, DX.Space.s)
            .accessibilityIdentifier("program.sosPractice")
            if tried {
                Label(String(localized: "Practised. You know where it is now."), systemImage: "checkmark")
                    .dxType(.footnote).foregroundStyle(Read4.accent)
            }
        }
        .fullScreenCover(isPresented: $showing) {
            CravingSOSView(profile: ctx.store.profile, source: "practice", practice: true) {
                showing = false
                tried = true
            }
        }
    }
}

// MARK: - The same questions for each item

/// Prep 2: for each trigger the person picked, when it happens, where they are and what they feel just before.
/// One screen per item; saves one line per item ("Coffee: Morning · At home · Restless").
struct PerItemBeat: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    @State private var index = 0
    /// item index → question id → chosen option ids.
    @State private var picks: [Int: [String: Set<String>]] = [:]

    private var items: [String] { ctx.answer(beat.optionsFrom)?.lines ?? [] }
    private var questions: [Beat.Question] { beat.questions ?? [] }

    var body: some View {
        if items.isEmpty {
            BeatFrame(beat: beat, onContinue: { ctx.finish(beat, skipped: true); onDone() }) {
                BeatPrompt(text: String(localized: "Nothing to map yet"))
                Text(String(localized: "Pick a few moments first, and they'll each get a screen here."))
                    .dxType(.body).foregroundStyle(Read4.muted)
            }
        } else {
            let item = items[min(index, items.count - 1)]
            BeatFrame(beat: beat, canContinue: ready(index), onContinue: next,
                      onSkip: { ctx.finish(beat, skipped: true); onDone() }) {
                Text(verbatim: String(localized: "\(index + 1) of \(items.count) · \(item)").uppercased())
                    .dxType(.caption).foregroundStyle(Read4.accent)
                ForEach(questions, id: \.id) { question in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(verbatim: prompt(question, item: item))
                            .dxFont(20, weight: 700, style: .title3)
                            .foregroundStyle(Read4.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                        DXFlowLayout(spacing: 8) {
                            ForEach(question.options.resolve(ctx.variant) ?? []) { option in
                                BeatChip(text: option.text, on: chosen(question.id).contains(option.id)) {
                                    toggle(option.id, question: question)
                                }
                            }
                        }
                    }
                    .padding(.bottom, DX.Space.s)
                }
            }
            .id(index)
        }
    }

    private func prompt(_ question: Beat.Question, item: String) -> String {
        let raw = question.prompt.resolve(ctx.variant) ?? ""
        return ctx.text(Varied<String>.same(raw.replacingOccurrences(of: "{item}", with: item.lowercased())))
    }

    private func chosen(_ question: String) -> Set<String> { picks[index]?[question] ?? [] }

    private func ready(_ i: Int) -> Bool {
        questions.allSatisfy { !(picks[i]?[$0.id] ?? []).isEmpty } || beat.optional
    }

    private func toggle(_ option: String, question: Beat.Question) {
        var current = picks[index] ?? [:]
        var set = current[question.id] ?? []
        if question.multi ?? true {
            if set.contains(option) { set.remove(option) } else { set.insert(option) }
        } else {
            set = set.contains(option) ? [] : [option]
        }
        current[question.id] = set
        picks[index] = current
    }

    private func next() {
        if index + 1 < items.count {
            index += 1
            return
        }
        let lines = items.enumerated().map { (i, item) -> String in
            let parts = questions.map { question -> String in
                let options = question.options.resolve(ctx.variant) ?? []
                let ids = picks[i]?[question.id] ?? []
                return options.filter { ids.contains($0.id) }.map(\.text).joined(separator: ", ")
            }
            .filter { !$0.isEmpty }
            return parts.isEmpty ? item : "\(item): \(parts.joined(separator: " · "))"
        }
        ctx.save(beat.saveAs, .list(lines))
        ctx.finish(beat, value: .list(lines))
        onDone()
    }
}
