import DayXeroCore
import SwiftUI

/// What an activity needs: the person's wording, their saved answers and somewhere to save new ones.
@MainActor
struct BeatContext {
    let store: ProgramStore
    let session: ProgramContent.Session
    let variant: ProgramVariant
    let nrtActive: Bool
    let placeholders: ProgramPlaceholders
    let isReplay: Bool

    /// The person's version of a string, with numbers filled in and anything unknown left out.
    func text(_ value: Varied<String>?) -> String {
        value?.resolve(variant).map { placeholders.fillDropping($0) } ?? ""
    }

    func answer(_ key: String?) -> ProgramAnswerValue? { key.flatMap { store.answer($0) } }

    /// Saves an answer. Replays may edit answers too; the change shows everywhere it's used.
    func save(_ key: String?, _ value: ProgramAnswerValue) {
        guard let key else { return }
        store.save(key, value, session: session.id)
    }

    /// The value saved on the activity itself (quiz and scenario picks), for replays.
    func recorded(_ beat: Beat) -> ProgramAnswerValue? {
        store.beatRecord(session: session.id, beat: beat.id)?.value
    }

    func finish(_ beat: Beat, skipped: Bool = false, value: ProgramAnswerValue? = nil) {
        guard !isReplay else { return }
        store.finishBeat(session: session.id, beat: beat.id, skipped: skipped, value: value)
        Analytics.track(.programBeatCompleted(sessionId: session.id, beatId: beat.id, type: beat.type.rawValue, skipped: skipped))
    }

    /// Whether an activity is shown at all: its NRT condition holds, and a note or card set has something to show.
    func shows(_ beat: Beat) -> Bool {
        switch beat.showIf {
        case .nrtActive?: if !nrtActive { return false }
        case .nrtNotActive?: if nrtActive { return false }
        case nil: break
        }
        if beat.type == .note, beat.skipIfEmpty, answer(beat.textFrom)?.isEmpty ?? true { return false }
        return true
    }
}

/// The frame every activity shares (handoff 5): its content, then Continue, and Skip for optional ones.
struct BeatFrame<Content: View>: View {
    let beat: Beat
    var canContinue = true
    var continueTitle: LocalizedStringKey = "Continue"
    let onContinue: () -> Void
    var onSkip: (() -> Void)?
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: DX.Space.xs) {
            ScrollView {
                content()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, DX.Space.m)
            }
            .scrollBounceBehavior(.basedOnSize)
            Button(continueTitle, action: onContinue)
                .buttonStyle(.dxPrimary)
                .disabled(!canContinue)
            if beat.optional, let onSkip {
                Button("Skip", action: onSkip).buttonStyle(.dxQuiet)
            }
        }
    }
}

/// The prompt at the top of most activities.
struct BeatPrompt: View {
    let text: String
    var eyebrow: LocalizedStringKey?

    var body: some View {
        VStack(alignment: .leading, spacing: DX.Space.xs) {
            if let eyebrow { Text(eyebrow).dxText(.micro).foregroundStyle(DX.Palette.accentInk) }
            if !text.isEmpty {
                Text(verbatim: text)
                    .font(.custom(DX.Typeface.bold, size: 24, relativeTo: .title2)).tracking(-0.4)
                    .foregroundStyle(DX.Palette.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }
        }
        .padding(.bottom, DX.Space.xs)
    }
}

/// The soft feedback panel. Announced to VoiceOver when it appears.
struct BeatFeedback: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkle").foregroundStyle(DX.Palette.accentInk).accessibilityHidden(true)
            Text(verbatim: text).font(.custom(DX.Typeface.regular, size: 15, relativeTo: .body)).foregroundStyle(DX.Palette.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DX.Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DX.Palette.surface2, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onAppear { AccessibilityNotification.Announcement(text).post() }
    }
}

/// An option row: a radio circle and its text, selected in sage.
struct OptionRow<Detail: View>: View {
    let text: String
    var selected = false
    var outlined = false
    var dimmed = false
    let detail: () -> Detail

    init(text: String, selected: Bool = false, outlined: Bool = false, dimmed: Bool = false, @ViewBuilder detail: @escaping () -> Detail) {
        self.text = text
        self.selected = selected
        self.outlined = outlined
        self.dimmed = dimmed
        self.detail = detail
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().strokeBorder(selected ? .clear : DX.Palette.faint, lineWidth: outlined ? 6 : 1.5)
                if selected {
                    Circle().fill(DX.Palette.accentInk)
                    Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundStyle(DX.Palette.canvas)
                }
            }
            .frame(width: 24, height: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: text).font(.custom(DX.Typeface.medium, size: 16, relativeTo: .body)).foregroundStyle(DX.Palette.text)
                    .fixedSize(horizontal: false, vertical: true)
                detail()
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 14).padding(.horizontal, DX.Space.m)
        .frame(minHeight: 56)
        .background(selected ? DX.Palette.accentSoft : DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .strokeBorder(selected ? DX.Palette.accentInk : outlined ? DX.Palette.faint : DX.Palette.hairline, lineWidth: selected || outlined ? 1.5 : 1))
        .opacity(dimmed ? 0.5 : 1)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

extension OptionRow where Detail == EmptyView {
    init(text: String, selected: Bool = false, outlined: Bool = false, dimmed: Bool = false) {
        self.init(text: text, selected: selected, outlined: outlined, dimmed: dimmed) { EmptyView() }
    }
}

/// A chip that can be on or off.
struct BeatChip: View {
    let text: String
    let on: Bool
    var muted = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(verbatim: text)
                .font(.custom(on ? DX.Typeface.semibold : DX.Typeface.medium, size: 15, relativeTo: .body))
                .foregroundStyle(DX.Palette.text)
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .background(on ? DX.Palette.accentSoft : DX.Palette.surface1, in: Capsule())
                .overlay(Capsule().strokeBorder(on ? DX.Palette.accentInk : DX.Palette.hairline, lineWidth: on ? 1.5 : 1))
                .opacity(muted ? 0.45 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

/// The routing from an activity's type to its screen.
struct BeatScreen: View {
    let beat: Beat
    let ctx: BeatContext
    let onDone: () -> Void

    var body: some View {
        Group {
            switch beat.type {
            case .statReveal: StatRevealBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .quiz: QuizBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .choice: ChoiceBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .slider: SliderBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .sliderGroup: SliderGroupBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .reflect: ReflectBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .tapReveal: TapRevealBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .planBuilder: PlanBuilderBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .checklist: ChecklistBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .breathe: BreatheBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .commit: CommitBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .scenario: ScenarioBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .note: NoteBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .info: InfoBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .share: ShareBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .nrtChoice: NRTChoiceBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .nrtStepdown: NRTStepdownBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .slipDebriefPractice: SlipPracticeBeat(beat: beat, ctx: ctx, onDone: onDone)
            case .planCard: PlanCardBeat(beat: beat, ctx: ctx, onDone: onDone)
            }
        }
    }
}
