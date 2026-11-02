import DayXeroCore
import StoreKit
import SwiftUI

/// Legal links shown on Welcome, every paywall and Settings (S15.4, S27.1). Apple requires both on any
/// screen that sells a subscription. Optional so a build without a policy still compiles; it is always set.
enum AppLinks {
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacy: URL? = URL(string: "https://dayxero.app/privacy/")
}

/// The full paywall (S3.1–S3.6), opened from "See all plans", Settings, Program and Today. There is no paywall
/// after onboarding (decision 15, S27.2): the close button is always there and nothing here is a first run.
struct PaywallView: View {
    let name: String
    let quitDay: Date
    @State var model: PaywallModel
    let onClose: () -> Void
    /// Called as a purchase or restore starts, before the person can turn Pro.
    var onPurchaseStarted: () -> Void = {}

    @State private var showBilling = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// At accessibility text sizes the footer scrolls with the content instead of being pinned,
    /// so the charge line and button are never squeezed or truncated.
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        ZStack(alignment: .top) {
            switch model.phase {
            case .loading, .ready, .purchasing:
                main
            case .failed:
                failed
            case .pending:
                PaywallMessage(systemImage: "clock", tint: .accent, title: "Waiting for approval",
                               message: "Your purchase needs approval (for example, Ask to Buy). We'll unlock everything as soon as it goes through.",
                               button: "Back to my day", action: onClose)
            case .unlocked:
                PaywallMessage(systemImage: "checkmark", tint: .sage, title: allSetTitle,
                               message: unlockedMessage, button: "Back to my day",
                               action: onClose)
                    .sensoryFeedback(DX.Haptic.commit, trigger: model.phase)
            }
            if let notice = model.notice {
                NoticeBanner(text: notice) { model.notice = nil }
                    .padding(.horizontal, DX.Space.s)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(DX.Move.animation(DX.Move.settle, reduceMotion: reduceMotion), value: model.phase)
        .animation(DX.Move.animation(DX.Move.settle, reduceMotion: reduceMotion), value: model.notice != nil)
        .background(Read4.background.ignoresSafeArea())
        .task {
            // Before Quit Day the trial waits for the Quit Day offer (decisions 15 and 23).
            model.trialOpensOn = quitDay
            await model.load()
        }
        .sheet(isPresented: $showBilling) { BillingSheet().presentationDetents([.medium, .large]) }
    }

    private var unlockedMessage: LocalizedStringKey {
        if let end = model.trialEndDate, model.selectedOption?.trialDays != nil {
            return model.canRemind
                ? "Your free trial runs until \(end, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated)). We'll remind you \(reminderLead) before it ends."
                : "Your free trial runs until \(end, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))."
        }
        if model.isBeforeQuitDay { return "The full program is unlocked. Let's get you ready for Quit Day." }
        return "The full program is unlocked."
    }

    /// "Milan, your plan is ready", or "Your plan is ready" when there's no name to use.
    static func readyTitle(name: String) -> String {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? String(localized: "Your plan is ready") : String(localized: "\(name), your plan is ready")
    }

    private var allSetTitle: LocalizedStringKey {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty { return "You're all set" }
        return "You're all set, \(name)"
    }

    /// Before Quit Day: when the free trial opens, in place of the plan that carries it.
    @ViewBuilder
    private var heldTrialNote: some View {
        if let days = model.heldTrialDays {
            Text("Your \(days)-day free trial opens on your Quit Day, \(quitDay, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated)).")
                .dxFont(14, weight: 400, style: .footnote)
                .foregroundStyle(Read4.muted)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Main

    private var main: some View {
        VStack(spacing: 0) {
            header.padding(.horizontal, DX.Space.m).padding(.top, DX.Space.xs).dxReadableColumn()
            ScrollView {
                VStack(alignment: .leading, spacing: DX.Space.xs) {
                    Text(verbatim: Self.readyTitle(name: name)).v4Text(.title).accessibilityAddTraits(.isHeader)
                    Text("Everything for your \(quitDay, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated)) Quit Day.")
                        .v4Text(.subtitle)
                    VStack(alignment: .leading, spacing: 7) {
                        included("All of prep, Quit week and 4 weeks after")
                        included("Insights on your triggers")
                        included("NRT planner, health timeline, share cards")
                    }
                    .padding(.top, DX.Space.s)
                    Text("Always free: your counter and Craving SOS.")
                        .dxFont(14, weight: 400, style: .footnote).foregroundStyle(Read4.muted)
                        .padding(.bottom, DX.Space.s)
                    plans
                    if typeSize.isAccessibilitySize {
                        footer.padding(.top, DX.Space.l)
                    }
                }
                .padding(.horizontal, DX.Space.m)
                .dxReadableColumn()
                .padding(.top, DX.Space.m)
                .padding(.bottom, typeSize.isAccessibilitySize ? DX.Space.xl : 0)
            }
            if !typeSize.isAccessibilitySize {
                footer
                    .padding(.horizontal, DX.Space.m)
                    .dxReadableColumn()
                    .padding(.bottom, DX.Space.xs)
            }
        }
    }

    /// "2 days" or "the day", matching when the reminder actually comes.
    private var reminderLead: String {
        guard let end = model.trialEndDate, TrialReminder.leadDays(trialEndsAt: end, now: .now) == 2 else {
            return String(localized: "the day")
        }
        return String(localized: "2 days")
    }

    private var header: some View {
        HStack {
            Button {
                model.dismissed()
                onClose()
            } label: {
                Image(systemName: "xmark").font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Read4.muted)
                    .frame(width: 36, height: 36)
                    .background(Read4.card, in: Circle())
                    .overlay(Circle().strokeBorder(Read4.hairline))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Close and continue with the free version"))
            Spacer()
            Button("Restore purchases") {
                onPurchaseStarted()
                Task { await model.restore() }
            }
                .dxFont(14, weight: 500, style: .footnote)
                .foregroundStyle(Read4.muted)
                .buttonStyle(.plain)
        }
        .frame(minHeight: 44)
    }

    private func included(_ text: LocalizedStringKey) -> some View {
        Label {
            Text(text).dxFont(14, weight: 400, style: .subheadline).foregroundStyle(Read4.ink)
        } icon: {
            Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundStyle(Read4.accent)
        }
    }

    @ViewBuilder
    private var plans: some View {
        VStack(spacing: DX.Space.xs) {
            if model.plans.isEmpty, model.heldTrialDays == nil {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Read4.surface).frame(height: 60)
                }
                .accessibilityHidden(true)
            } else {
                ForEach(model.plans) { option in
                    PlanRow(option: option, isSelected: model.selected == option.plan, savingPercent: model.annualSavingPercent) {
                        model.select(option.plan)
                    }
                }
            }
            heldTrialNote
        }
        .padding(.top, DX.Space.xs)
    }

    private var footer: some View {
        VStack(spacing: DX.Space.xs) {
            if let option = model.selectedOption {
                chargeLine(option)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            Button {
                onPurchaseStarted()
                Task { await model.purchase() }
            } label: {
                if model.phase == .purchasing {
                    ProgressView().tint(Read4.onInk)
                } else {
                    Text(ctaTitle)
                }
            }
            .buttonStyle(.dx(.primary, on: .reading))
            .disabled(model.phase != .ready)
            .accessibilityIdentifier("paywall.cta")
            terms
        }
    }

    private func chargeLine(_ option: PlanOption) -> some View {
        Group {
            switch option.plan {
            case .annual:
                if let end = model.trialEndDate {
                    Text("Free until \(Text(end, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated)).bold()), then \(option.priceText) a year.")
                    + (model.canRemind ? Text("\nWe'll remind you \(reminderLead) before.") : Text(""))
                } else {
                    Text("\(Text("\(option.priceText) today").bold()), then every year until you cancel.")
                }
            case .monthly:
                Text("\(Text("\(option.priceText) today").bold()), then every month until you cancel.")
            case .lifetime:
                Text("\(Text("\(option.priceText) once.").bold()) No subscription, nothing to cancel.")
            }
        }
        .dxFont(14, weight: 400, style: .footnote)
        .foregroundStyle(Read4.muted)
    }

    private var ctaTitle: LocalizedStringKey {
        guard let option = model.selectedOption else { return "Loading prices…" }
        switch option.plan {
        case .annual:
            if let days = option.trialDays { return "Start my \(days)-day free trial" }
            return "Subscribe for \(option.priceText) a year"
        case .monthly: return "Subscribe for \(option.priceText) a month"
        case .lifetime: return "Buy lifetime for \(option.priceText)"
        }
    }

    private var terms: some View {
        VStack(spacing: 2) {
            if model.selected != .lifetime {
                Text("Cancel in Settings › Apple ID › Subscriptions.").multilineTextAlignment(.center)
            }
            // One centred line when it fits, stacked when text is large.
            ViewThatFits {
                HStack(spacing: 6) { termsLinks(separators: true) }
                VStack(spacing: 4) { termsLinks(separators: false) }
            }
        }
        .dxFont(12, weight: 400, style: .caption2)
        .foregroundStyle(Read4.muted)
        .tint(Read4.muted)
    }

    @ViewBuilder
    private func termsLinks(separators: Bool) -> some View {
        Button("How billing works") { showBilling = true }.buttonStyle(.plain).underline()
        if separators { Text(verbatim: "·") }
        Link("Terms", destination: AppLinks.terms).underline()
        if let privacy = AppLinks.privacy {
            if separators { Text(verbatim: "·") }
            Link("Privacy", destination: privacy).underline()
        }
    }

    // MARK: Failed

    private var failed: some View {
        VStack(spacing: 0) {
            header.padding(.horizontal, DX.Space.m).padding(.top, DX.Space.xs).dxReadableColumn()
            Spacer()
            V4StateView(.error, systemImage: "exclamationmark.circle", title: "Couldn't reach the App Store",
                        message: "Check your connection and try again. Your prep week, your counter and Craving SOS work without it.",
                        actionTitle: "Try again") { Task { await model.load() } }
            Spacer()
            Button("Continue with free") {
                model.dismissed()
                onClose()
            }
            .buttonStyle(.dx(.quiet, on: .reading))
            .padding(.bottom, DX.Space.xs)
        }
    }
}

private struct PlanRow: View {
    let option: PlanOption
    let isSelected: Bool
    let savingPercent: Int?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DX.Space.s) {
                ZStack {
                    Circle().strokeBorder(isSelected ? .clear : Read4.faint, lineWidth: 1.5)
                    if isSelected {
                        Circle().fill(Read4.accent)
                        Circle().fill(Color.black).frame(width: 7, height: 7)
                    }
                }
                .frame(width: 20, height: 20)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).dxFont(16, weight: 600, style: .body).foregroundStyle(Read4.ink)
                    Text(detail).v4Text(.subtitle)
                }
                Spacer(minLength: DX.Space.xs)
                VStack(alignment: .trailing, spacing: 1) {
                    Text(verbatim: option.priceText).dxFont(16, weight: 700, style: .body)
                        .monospacedDigit().foregroundStyle(Read4.ink)
                    Text(period).dxFont(12, weight: 500, style: .caption2).foregroundStyle(Read4.muted)
                }
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 14)
            .background(Read4.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(isSelected ? Read4.accent : Read4.hairline, lineWidth: isSelected ? 1.5 : 1)
            )
            .overlay(alignment: .topTrailing) {
                if let days = option.trialDays {
                    Text(savingPercent.map { "\(days) DAYS FREE · SAVE \($0)%" as LocalizedStringKey } ?? "\(days) DAYS FREE")
                        .dxFont(12, weight: 700, style: .caption2)
                        .tracking(0.4)
                        .foregroundStyle(DX.Fill.cream)
                        .padding(.vertical, 3).padding(.horizontal, 8)
                        .background(Read4.accent, in: Capsule())
                        .offset(x: -14, y: -9)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(DX.Haptic.select, trigger: isSelected)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var title: LocalizedStringKey {
        switch option.plan {
        case .annual: "Yearly"
        case .monthly: "Monthly"
        case .lifetime: "Lifetime"
        }
    }

    private var detail: LocalizedStringKey {
        switch option.plan {
        case .annual:
            if let perMonth = option.perMonthText {
                // With a trial, the badge carries the saving.
                if let savingPercent, option.trialDays == nil { return "\(perMonth) a month · save \(savingPercent)%" }
                return "\(perMonth) a month"
            }
            return "Billed yearly"
        case .monthly: return "Cancel anytime"
        case .lifetime: return "Pay once"
        }
    }

    private var period: LocalizedStringKey {
        switch option.plan {
        case .annual: "per year"
        case .monthly: "per month"
        case .lifetime: "one time"
        }
    }
}

/// Full-screen confirmation used for "unlocked" and "waiting for approval".
private struct PaywallMessage: View {
    enum Tint { case sage, accent }
    let systemImage: String
    let tint: Tint
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let button: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        VStack(spacing: DX.Space.s) {
            Spacer()
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(tint == .sage ? DX.Fill.cream : Read4.accent)
                .frame(width: 76, height: 76)
                .background(tint == .sage ? Read4.accent : Read4.accentSoft, in: Circle())
                .accessibilityHidden(true)
            Text(title).v4Text(.title).multilineTextAlignment(.center)
            Text(message).v4Text(.subtitle).multilineTextAlignment(.center)
            Spacer()
            Button(button, action: action).buttonStyle(.dx(.primary, on: .reading))
        }
        .padding(.horizontal, DX.Space.l)
        .dxReadableColumn()
        .padding(.bottom, DX.Space.xs)
    }
}

private struct NoticeBanner: View {
    let text: LocalizedStringResource
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.circle").foregroundStyle(Read4.amber)
            Text(text).dxFont(14, weight: 400, style: .footnote).foregroundStyle(Read4.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onDismiss) {
                Image(systemName: "xmark").font(.system(size: 11, weight: .semibold)).foregroundStyle(Read4.muted)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Dismiss"))
        }
        .padding(DX.Space.s)
        .background(Read4.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Read4.hairline))
        .shadow(color: Color.black.opacity(0.15), radius: 16, y: 8)
        .accessibilityElement(children: .combine)
    }
}

/// "How billing works" (S3.4): cancelling in two taps, trial, refunds.
struct BillingSheet: View {
    @State private var manage = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DX.Space.xs) {
                Text("How billing works").v4Text(.title).dxFont(24, weight: 700, style: .title2)
                Text("Plain and simple. Apple handles every payment.").v4Text(.subtitle)
                Text("Cancel in two taps").v4Text(.micro).padding(.top, DX.Space.m)
                step(1, "Tap **Manage subscription** below")
                step(2, "Tap **Cancel subscription**")
                Text("Free trial").v4Text(.micro).padding(.top, DX.Space.s)
                Text("Cancel any time before it ends and you pay nothing. We'll remind you 2 days before.").v4Text(.subtitle)
                Text("Refunds").v4Text(.micro).padding(.top, DX.Space.s)
                Text("Refunds go through Apple. You can request one at reportaproblem.apple.com.").v4Text(.subtitle)
                Button("Manage subscription") { manage = true }
                    .buttonStyle(.v4Secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, DX.Space.m)
            }
            .padding(DX.Space.l)
        }
        .background(Read4.background.ignoresSafeArea())
        .manageSubscriptionsSheet(isPresented: $manage)
    }

    private func step(_ number: Int, _ text: LocalizedStringKey) -> some View {
        HStack(spacing: 10) {
            Text(verbatim: "\(number)")
                .dxFont(12, weight: 700, style: .caption2)
                .foregroundStyle(Read4.ink)
                .frame(width: 24, height: 24)
                .background(Read4.surface, in: Circle())
            Text(text).dxFont(14, weight: 400, style: .footnote).foregroundStyle(Read4.ink)
        }
        .accessibilityElement(children: .combine)
    }
}
