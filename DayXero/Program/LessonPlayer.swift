import DayXeroCore
import SwiftData
import SwiftUI

/// Plays one program day, a step at a time (S5.4). Saves your place on close; records completion at the end.
struct LessonPlayer: View {
    let day: ProgramDayID
    let profile: UserProfile
    /// Replaying the last finished day after a break (S5.7).
    var isReplay = false

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(Entitlement.self) private var entitlement
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var content: LessonContent?
    @State private var index = 0
    @State private var finished = false
    // Exercise and check-in answers
    @State private var ifThenAction: String?
    @State private var weekRating = 0.3
    @State private var challengeDays: Set<Int> = []
    @State private var nextChallenge: String?

    var body: some View {
        VStack(spacing: 0) {
            if let content {
                segments(count: content.steps.count)
                if finished {
                    LessonComplete(day: day, title: content.title, profile: profile, isReplay: isReplay) { dismiss() }
                } else {
                    topBar(content)
                    if case .audio = content.steps[index] {
                        // The audio step splits the screen into wave and captions, so it takes the full height instead of scrolling.
                        stepBody(content)
                            .frame(maxHeight: .infinity)
                    } else {
                        ScrollView { stepBody(content) }
                    }
                    footer(content)
                }
            }
        }
        .padding(.horizontal, DX.Space.l)
        .dxReadableColumn()
        .padding(.top, DX.Space.s)
        .padding(.bottom, DX.Space.xs)
        .background(Read4.background.ignoresSafeArea())
        .animation(DX.Motion.animation(DX.Move.settle, reduceMotion: reduceMotion), value: index)
        .animation(DX.Motion.animation(DX.Move.settle, reduceMotion: reduceMotion), value: finished)
        .onAppear(perform: start)
        .accessibilityAction(named: Text("Next step")) { advance() }
    }

    private func stepBody(_ content: LessonContent) -> some View {
        step(content.steps[index])
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, DX.Space.s)
            .id(index)
            .transition(reduceMotion ? .opacity : .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                               removal: .opacity))
    }

    // MARK: Chrome

    private func segments(count: Int) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<count, id: \.self) { i in
                Capsule().fill(i < (finished ? count : index + 1) ? Read4.ink : Read4.track).frame(height: 4)
            }
        }
        .padding(.bottom, DX.Space.s)
        .accessibilityHidden(true)
    }

    private func topBar(_ content: LessonContent) -> some View {
        HStack {
            Button {
                ProgramState.saveStep(index, for: day)
                dismiss()
            } label: {
                Image(systemName: "xmark").font(.system(size: 13, weight: .semibold)).foregroundStyle(Read4.muted)
                    .frame(width: 36, height: 36)
                    .background(Read4.card, in: Circle())
                    .overlay(Circle().strokeBorder(Read4.hairline))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Close. Your place is saved."))
            Spacer()
            Text("\(stepLabel) · \(index + 1) of \(content.steps.count)").v4Text(.micro)
            Spacer()
            if content.placeholder { PlaceholderTag() } else { Color.clear.frame(width: 36, height: 36) }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .padding(.bottom, DX.Space.xs)
    }

    private var stepLabel: String {
        switch day.phase {
        case .prep: String(localized: "Prep day \(day.index)")
        case .quit: String(localized: "Day \(day.index)")
        case .maintenance: String(localized: "Week \(day.index + 1) check-in")
        }
    }

    @ViewBuilder
    private func footer(_ content: LessonContent) -> some View {
        let step = content.steps[index]
        VStack(spacing: DX.Space.xs) {
            Button(nextTitle(step, isLast: index == content.steps.count - 1)) { advance() }
                .buttonStyle(.dx(.primary, on: .reading))
                .disabled(!canAdvance(step))
        }
        .padding(.top, DX.Space.xs)
    }

    private func nextTitle(_ step: LessonStep, isLast: Bool) -> LocalizedStringKey {
        if case .ifThen = step { return "Save my plan" }
        if case .audio = step, let content, content.steps.indices.contains(index + 1), case .ifThen = content.steps[index + 1] {
            return "Skip to the exercise"
        }
        return isLast ? "Finish" : "Next"
    }

    private func canAdvance(_ step: LessonStep) -> Bool {
        switch step {
        case .ifThen: ifThenAction != nil
        case .nextChallenge: nextChallenge != nil
        default: true
        }
    }

    // MARK: Steps

    @ViewBuilder
    private func step(_ step: LessonStep) -> some View {
        switch step {
        case let .reading(lead, body, notes):
            VStack(alignment: .leading, spacing: DX.Space.m) {
                Text(lead).dxFont(24, weight: 700, style: .title1)
                    .foregroundStyle(Read4.ink).accessibilityAddTraits(.isHeader)
                Text(body).dxFont(19, weight: 400, style: .body).lineSpacing(5)
                    .foregroundStyle(Read4.ink)
                ForEach(otherProducts, id: \.self) { product in
                    if let note = notes[product.rawValue] { NoteCallout(product: product, text: note) }
                }
            }
        case let .audio(title, subtitle, file, seconds, transcript):
            LessonAudioStep(title: title, subtitle: subtitle, file: file, seconds: seconds, transcript: transcript) {
                // When the audio ends, the lesson moves on to its exercise by itself.
                if content?.steps.indices.contains(index) == true, case .audio = content?.steps[index] { advance() }
            }
        case let .ifThen(title, subtitle, actions):
            IfThenStep(title: title, subtitle: subtitle, situation: situation, actions: actions, selection: $ifThenAction)
        case .weekRating:
            VStack(alignment: .leading, spacing: DX.Space.xs) {
                Text("How was this week?").v4Text(.title)
                Text("A quick look back, then one thing to try next week.").v4Text(.subtitle)
                V4Card {
                    VStack(alignment: .leading, spacing: DX.Space.s) {
                        Text("Cravings this week").v4Text(.cardHeading)
                        Slider(value: $weekRating, in: 0...1).tint(Read4.accent)
                            .accessibilityValue(Text(weekRating < 0.34 ? "Easy" : weekRating < 0.67 ? "Mixed" : "Tough"))
                        HStack { Text("Easy"); Spacer(); Text("Tough") }.v4Text(.subtitle)
                    }
                }
                .padding(.top, DX.Space.m)
            }
        case let .challengeReview(challenge):
            VStack(alignment: .leading, spacing: DX.Space.xs) {
                Text("Last week's challenge").v4Text(.title)
                Text("\(challenge). Tap the days you did it.").v4Text(.subtitle)
                V4Card {
                    HStack(spacing: 4) {
                        ForEach(0..<7, id: \.self) { i in
                            let on = challengeDays.contains(i)
                            Button {
                                if on { challengeDays.remove(i) } else { challengeDays.insert(i) }
                            } label: {
                                VStack(spacing: 4) {
                                    Text(Calendar.current.veryShortStandaloneWeekdaySymbols[(Calendar.current.firstWeekday - 1 + i) % 7])
                                        .v4Text(.subtitle)
                                    ZStack {
                                        Circle().strokeBorder(on ? .clear : Read4.faint, lineWidth: 1.5)
                                        if on {
                                            Circle().fill(Read4.accent)
                                            Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundStyle(DX.Fill.cream)
                                        }
                                    }
                                    .frame(width: 32, height: 32)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(on ? .isSelected : [])
                        }
                    }
                }
                .padding(.top, DX.Space.m)
            }
        case let .nextChallenge(options):
            VStack(alignment: .leading, spacing: DX.Space.xs) {
                Text("One thing for next week").v4Text(.title)
                Text("Pick a small challenge. We'll ask how it went next week.").v4Text(.subtitle)
                VStack(spacing: DX.Space.xs) {
                    ForEach(options, id: \.self) { option in
                        DXOptionCard(LocalizedStringResource(stringLiteral: option), isSelected: nextChallenge == option) { nextChallenge = option }
                    }
                }
                .padding(.top, DX.Space.m)
            }
        }
    }

    private var otherProducts: [Product] {
        let primary = profile.primaryProduct?.product
        return profile.products.map(\.product).filter { $0 != primary }
    }

    /// The if-then situation, from the person's own triggers.
    private var situation: String {
        String(localized: (profile.triggers.first ?? .other).situation)
    }

    // MARK: Flow

    private func start() {
        let lesson = LessonLibrary.lesson(for: day, product: profile.primaryProduct?.product ?? .cigarettes)
        content = lesson
        index = min(ProgramState.savedStep(for: day), max(lesson.steps.count - 1, 0))
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "dx.lessonFinishedPreview") { complete(); return }
        if let action = UserDefaults.standard.string(forKey: "dx.ifThenPreview") { ifThenAction = action }
        #endif
        profile.progress?.lastActiveAt = .now
        try? context.save()
        Analytics.track(.programDayStarted(day: day.description))
    }

    private func advance() {
        guard let content, !finished else { return }
        let step = content.steps[index]
        if case .ifThen = step, let action = ifThenAction {
            context.insert(IfThenPlan(situation: situation, action: action))
        }
        if index + 1 < content.steps.count {
            index += 1
        } else {
            complete()
        }
    }

    private func complete() {
        if profile.progress == nil { profile.progress = ProgramProgress() }
        guard let progress = profile.progress else { return }
        if isReplay {
            progress.replayDay = nil
        } else if !progress.completedDayIDs.contains(day) {
            progress.completions.append(DayCompletion(day: day))
            Analytics.track(.programDayCompleted(day: day.description))
        }
        if day.phase == .maintenance {
            context.insert(WeeklyCheckIn(week: day.index + 1, cravingRating: weekRating,
                                         challengeDays: challengeDays.sorted(), nextChallenge: nextChallenge))
        }
        progress.lastActiveAt = .now
        try? context.save()
        ProgramState.saveStep(0, for: day)
        finished = true
    }
}

struct PlaceholderTag: View {
    var body: some View {
        Text("Placeholder")
            .dxFont(12, weight: 700, style: .caption2)
            .tracking(0.6)
            .textCase(.uppercase)
            .foregroundStyle(Color(light: 0xB07A14, dark: 0xE5A93C))
            .padding(.vertical, 3).padding(.horizontal, 8)
            .background(Read4.amber.opacity(0.18), in: Capsule())
            .accessibilityLabel(Text("Placeholder content"))
    }
}

private struct NoteCallout: View {
    let product: Product
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(heading).v4Text(.micro, color: Read4.accent)
            Text(text).dxFont(14, weight: 400, style: .footnote).foregroundStyle(Read4.ink)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Read4.accentSoft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var heading: LocalizedStringKey {
        switch product {
        case .cigarettes: "If you also smoke"
        case .vape: "If you also vape"
        case .pouches: "If you also use pouches"
        }
    }
}

private struct IfThenStep: View {
    let title: String
    let subtitle: String
    let situation: String
    let actions: [String]
    @Binding var selection: String?

    var body: some View {
        VStack(alignment: .leading, spacing: DX.Space.xs) {
            Text(title).v4Text(.title)
            Text(subtitle).v4Text(.subtitle)
            V4Card {
                VStack(alignment: .leading, spacing: 6) {
                    DXFlowLayout(spacing: 6) { Text("If it's"); slot(situation, filled: true) }
                    DXFlowLayout(spacing: 6) { Text("then I'll"); slot(selection ?? String(localized: "choose one"), filled: selection != nil) }
                }
                .dxFont(16, weight: 400, style: .body)
                .foregroundStyle(Read4.ink)
            }
            .padding(.top, DX.Space.m)
            .accessibilityElement(children: .combine)
            Text("Then I'll…").v4Text(.micro).padding(.top, DX.Space.s)
            DXFlowLayout {
                ForEach(actions, id: \.self) { action in
                    DXChip(LocalizedStringKey(action), isOn: Binding(get: { selection == action }, set: { if $0 { selection = action } }))
                }
            }
        }
    }

    private func slot(_ text: String, filled: Bool) -> some View {
        Text(verbatim: text)
            .dxFont(14, weight: filled ? 600 : 400, style: .subheadline)
            .foregroundStyle(filled ? Read4.onInk : Read4.muted)
            .padding(.vertical, 3).padding(.horizontal, 10)
            .background {
                // A rounded rectangle, not a capsule, so wrapped text at large sizes stays readable.
                if filled {
                    RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Read4.ink)
                } else {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Read4.faint, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }
            }
    }
}

/// The end of a lesson: success, progress so far, and what's next (S5.4).
private struct LessonComplete: View {
    let day: ProgramDayID
    let title: String
    let profile: UserProfile
    let isReplay: Bool
    let onDone: () -> Void
    @Environment(Entitlement.self) private var entitlement
    @State private var celebrated = false

    var body: some View {
        let state = ProgramState(profile: profile, isPro: entitlement.isPro)
        let next = state.schedule.featuredDay(completed: state.completed)
        VStack(spacing: DX.Space.s) {
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(DX.Fill.cream)
                .frame(width: 96, height: 96)
                .background(Read4.accent, in: Circle())
                .accessibilityHidden(true)
            Text(isReplay ? "Welcome back" : "\(title) done").v4Text(.title).multilineTextAlignment(.center)
            Text(summary(state)).v4Text(.subtitle).multilineTextAlignment(.center)
            if let next {
                let content = state.lesson(next)
                V4Card(padding: 14) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(content.title).v4Text(.cardHeading)
                        let when = opens(state.availability(next), upgrade: state.needsUpgrade(next))
                        Text(verbatim: when.isEmpty ? String(localized: "Next · \(state.position(next))")
                                                    : String(localized: "Next · \(state.position(next)) · \(when)")).v4Text(.subtitle)
                    }
                }
                .padding(.top, DX.Space.s)
            }
            Spacer()
            Button("Back to Today", action: onDone).buttonStyle(.dx(.primary, on: .reading))
        }
        .sensoryFeedback(DX.Haptic.commit, trigger: celebrated)
        .onAppear { celebrated = true }
    }

    private func summary(_ state: ProgramState) -> String {
        if isReplay { return String(localized: "You're back on track. The next lesson is open.") }
        switch day.phase {
        case .prep:
            let done = state.completed.filter { $0.phase == .prep }.count
            return String(localized: "\(done) of \(state.schedule.prepDays) prep days done.")
        case .quit:
            let done = state.completed.filter { $0.phase == .quit }.count
            return String(localized: "\(done) of \(ProgramSchedule.quitWeekDays) quit-week lessons done.")
        case .maintenance:
            return String(localized: "Check-in saved. See you next week.")
        }
    }

    private func opens(_ availability: ProgramSchedule.Availability, upgrade: Bool) -> String {
        if upgrade { return String(localized: "Part of the full program") }
        switch availability {
        case let .opensOn(date):
            return Calendar.current.isDateInTomorrow(date) ? String(localized: "Opens tomorrow morning")
                : String(localized: "Opens \(date.formatted(.dateTime.weekday(.wide)))")
        case .available: return String(localized: "Ready now")
        case .completed, .locked: return ""
        }
    }
}

extension ProgramView {
    /// The first program's day to open. Program v2 opens sessions with `SessionOpen`.
    struct LessonOpen: Identifiable {
        let day: ProgramDayID
        let isReplay: Bool
        var id: String { day.description + (isReplay ? "-replay" : "") }
    }
}
