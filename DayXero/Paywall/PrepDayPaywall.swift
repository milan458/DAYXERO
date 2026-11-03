import DayXeroCore
import SwiftUI

/// The prep-day paywall (BET-1, signed off in the Screen Lab on 3 Nov 2026): a free user reads a prep session's intro
/// and first two cards, then this. The ✕ shows straight away. Closing it ends the day's session on Xero's "Two more
/// cards tomorrow"; buying or starting the trial carries on into the rest of the session. Reaching it counts as the
/// day's prep, so the next prep session opens tomorrow (`ProgramStore.preview`).
struct PrepDayPaywall: View {
    let session: ProgramContent.Session
    let ctx: BeatContext
    /// Buying or restoring here: carry on into the rest of the session.
    let onUnlocked: () -> Void
    /// Done after closing: back to where the session was opened from.
    let onDone: () -> Void

    @Environment(Entitlement.self) private var entitlement
    @State private var closed = false

    private var profile: UserProfile { ctx.store.profile }

    private var eyebrow: String {
        let title = session.title.resolve(ctx.variant) ?? ""
        return title.isEmpty ? session.label : "\(session.label) · \(title)"
    }

    var body: some View {
        if closed {
            afterClose
        } else {
            PaywallView(name: profile.name, quitDay: profile.quitDay, model: model(), onClose: {
                if entitlement.isPro { onUnlocked() } else { closed = true }
            }, context: .prepDay(eyebrow: eyebrow))
        }
    }

    private func model() -> PaywallModel {
        let model = PaywallModel(store: entitlement.store, entitlement: entitlement)
        model.boundaryHour = profile.dayBoundaryHour
        return model
    }

    // MARK: After ✕

    /// The next session, and whether it's another prep session (more free cards) or the full program.
    private var next: ProgramContent.Session? { ctx.store.content?.session(after: session.id) }

    private var lastPrep: Bool {
        guard let next else { return true }
        return !FullProgram.isPreviewable(sessionId: next.id)
    }

    private var nextLine: String? {
        guard let next else { return nil }
        if lastPrep { return String(localized: "Day Xero is part of the full program.") }
        return switch ctx.store.state(of: next.id) {
        case .available, .inProgress: String(localized: "\(next.label) is open now.")
        case .scheduled(.tomorrow): String(localized: "\(next.label) opens tomorrow.")
        default: nil
        }
    }

    private var afterClose: some View {
        VStack(spacing: DX.Space.s) {
            Text(verbatim: eyebrow).v4Text(.micro).frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: DX.Space.m)
            XeroView(mood: .calm, stage: 1, size: .scene).accessibilityHidden(true)
            CrewBubble(lastPrep
                       ? String(localized: "That was the last prep day. Your counter and Craving SOS stay free, whatever you choose.")
                       : String(localized: "Two more cards tomorrow. I'll keep your place."),
                       on: .reading, tail: .up, size: .callout, order: 0, start: 0.3)
                .accessibilityAddTraits(.isHeader)
            if let nextLine {
                Text(verbatim: nextLine).v4Text(.subtitle).multilineTextAlignment(.center)
            }
            Spacer(minLength: DX.Space.m)
            Button("Done", action: onDone)
                .buttonStyle(.dx(.primary, on: .reading))
            Button("See plans") { closed = false }
                .buttonStyle(.dx(.quiet, on: .reading))
        }
        .padding(.horizontal, DX.Layout.gutter)
        .dxReadableColumn()
        .padding(.top, DX.Space.s)
        .padding(.bottom, DX.Space.xs)
        .foregroundStyle(Read4.ink)
    }
}
