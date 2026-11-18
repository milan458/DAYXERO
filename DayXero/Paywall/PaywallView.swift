import DayXeroCore
import StoreKit
import SwiftData
import SwiftUI

/// Legal links shown on Welcome, every paywall and Settings (S15.4, S27.1). Apple requires both on any
/// screen that sells a subscription. Optional so a build without a policy still compiles; it is always set.
enum AppLinks {
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacy: URL? = URL(string: "https://dayxero.app/privacy/")
    /// DayXero's App Store page, opened on its "Write a Review" sheet (Apple ID 6822799921).
    static let writeReview = URL(string: "https://apps.apple.com/app/id6822799921?action=write-review")!
}

/// The paywall (S3.1–S3.6): after onboarding with no way round it, and with a close button from Settings, Program,
/// Today and the locked features. Its pages are `PaywallOffer` (Paywall v2, 18 Nov 2026); this view holds the states
/// around them: failed, waiting for approval, unlocked.
/// `PW` is the apricot palette those states and the billing sheet still use.
enum PW {
    static let ground = DX.Ground.apricot
    static let background = DX.Ground.apricot.background
    static let ink = DX.Ground.apricot.ink
    static let muted = DX.Ground.apricot.muted
    static let card = DX.Ground.apricot.card
    static let surface = DX.Ground.apricot.card2
    static let hairline = DX.Ground.apricot.line
    static let faint = DX.Ground.apricot.ink.opacity(0.38)
    static let accent = Color(hex: 0xFF7A55)
    static let accentSoft = DX.Ground.apricot.selTint
    static let onInk = Color(light: 0xFFF8EE, dark: 0x0E1322)
    static let amber = Read4.amber
}

struct PaywallView: View {
    let name: String
    let quitDay: Date
    @State var model: PaywallModel
    let onClose: () -> Void
    /// Called as a purchase or restore starts, before the person can turn Pro.
    var onPurchaseStarted: () -> Void = {}
    /// The person's spend for the price anchor, where there's no profile yet (onboarding). Otherwise it's the profile's.
    var spend: PaywallModel.Spend?
    /// False for the hard paywall: no close button and no "continue with free".
    var closable = true

    @Query private var profiles: [UserProfile]

    @State private var showBilling = false
    private let motion = MotionPolicy()

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
                               button: closable ? "Back to my day" : "Back to the plans",
                               action: leavePending)
            case .unlocked:
                PaywallMessage(systemImage: "checkmark", tint: .sage, title: allSetTitle,
                               message: unlockedMessage, button: closable ? "Back to my day" : "Start",
                               action: onClose)
                    .sensoryFeedback(DX.Haptic.commit, trigger: model.phase)
            }
            if let notice = model.notice {
                NoticeBanner(text: notice) { model.notice = nil }
                    .padding(.horizontal, DX.Space.s)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(motion.animation(DX.Move.settle), value: model.phase)
        .animation(motion.animation(DX.Move.settle), value: model.notice != nil)
        .background((showsOffer ? PW2.background : PW.background).ignoresSafeArea())
        .task {
            model.quitDay = quitDay
            model.spend = spend ?? PaywallModel.Spend(profile: profiles.first)
            await model.load()
        }
        .sheet(isPresented: $showBilling) { BillingSheet().presentationDetents([.medium, .large]) }
    }

    private var showsOffer: Bool {
        switch model.phase {
        case .loading, .ready, .purchasing: true
        case .failed, .pending, .unlocked: false
        }
    }

    /// From "Waiting for approval": back to the app, or on the hard paywall back to the plans.
    private func leavePending() {
        if closable {
            onClose()
        } else {
            Task { await model.load() }
        }
    }

    private var unlockedMessage: LocalizedStringKey {
        if let end = model.trialEndDate, model.selectedOption?.trialDays != nil {
            return model.canRemind
                ? "Your free trial runs until \(end, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated)). Prep 1 to 3 open one a day. We'll remind you \(reminderLead) before it ends."
                : "Your free trial runs until \(end, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated)). Prep 1 to 3 open one a day."
        }
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

    // MARK: Main

    /// Paywall v2: what you'll keep, everything in Pro, the offer (`PaywallOffer`).
    private var main: some View {
        PaywallOffer(name: name, quitDay: quitDay, model: model, spend: spend ?? PaywallModel.Spend(profile: profiles.first),
                     closable: closable,
                     onClose: {
                         model.dismissed()
                         onClose()
                     },
                     onPurchaseStarted: onPurchaseStarted)
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
            if closable {
            Button {
                model.dismissed()
                onClose()
            } label: {
                DXIcon(.back, size: 20, weight: 2.4)
                    .foregroundStyle(PW.ink)
                    .frame(width: 44, height: 44)
                    .background(PW.surface, in: Circle())
            }
            .buttonStyle(.dxPress)
            .accessibilityLabel(Text("Close"))
            }
            Spacer()
        }
        .frame(height: 52)
    }

    // MARK: Failed

    private var failed: some View {
        VStack(spacing: 0) {
            header.padding(.horizontal, DX.Layout.gutter).padding(.top, DX.Space.xs).dxReadableColumn()
            Spacer()
            V4StateView(.error, systemImage: "exclamationmark.circle", title: "Couldn't reach the App Store",
                        message: "Check your connection and try again.",
                        actionTitle: "Try again") { Task { await model.load() } }
            Spacer()
            if closable {
                Button("Close") {
                    model.dismissed()
                    onClose()
                }
                .buttonStyle(.dx(.quiet, on: .apricot))
                .padding(.bottom, DX.Space.xs)
            }
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
                .foregroundStyle(tint == .sage ? DX.Fill.cream : PW.accent)
                .frame(width: 76, height: 76)
                .background(tint == .sage ? PW.accent : PW.accentSoft, in: Circle())
                .accessibilityHidden(true)
            Text(title).dxType(.title).foregroundStyle(DX.Ground.reading.ink).multilineTextAlignment(.center)
            Text(message).dxType(.footnote).foregroundStyle(DX.Ground.reading.muted).multilineTextAlignment(.center)
            Spacer()
            Button(button, action: action).buttonStyle(.dx(.primary, on: .apricot))
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
            Image(systemName: "exclamationmark.circle").foregroundStyle(PW.amber)
            Text(text).dxFace(.body, 14, weight: 400).foregroundStyle(PW.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onDismiss) {
                DXIcon(.close, size: 11, weight: 2.6).foregroundStyle(PW.muted)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Dismiss"))
        }
        .padding(DX.Space.s)
        .background(PW.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(PW.hairline))
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
                Text("How billing works").dxType(.title).foregroundStyle(DX.Ground.reading.ink).dxFace(.display, 24, weight: 700)
                Text("Plain and simple. Apple handles every payment.").dxType(.footnote).foregroundStyle(DX.Ground.reading.muted)
                Text("Cancel in two taps").dxType(.caption).foregroundStyle(DX.Ground.reading.muted).padding(.top, DX.Space.m)
                step(1, "Tap **Manage subscription** below")
                step(2, "Tap **Cancel subscription**")
                Text("Free trial").dxType(.caption).foregroundStyle(DX.Ground.reading.muted).padding(.top, DX.Space.s)
                Text("Cancel any time before it ends and you pay nothing. We'll remind you 2 days before.").dxType(.footnote).foregroundStyle(DX.Ground.reading.muted)
                Text("Refunds").dxType(.caption).foregroundStyle(DX.Ground.reading.muted).padding(.top, DX.Space.s)
                Text("Refunds go through Apple. You can request one at reportaproblem.apple.com.").dxType(.footnote).foregroundStyle(DX.Ground.reading.muted)
                Button("Manage subscription") { manage = true }
                    .buttonStyle(.dx(.ghost, on: .reading))
                    .frame(maxWidth: .infinity)
                    .padding(.top, DX.Space.m)
            }
            .padding(DX.Space.l)
        }
        .background(PW.background.ignoresSafeArea())
        .manageSubscriptionsSheet(isPresented: $manage)
    }

    private func step(_ number: Int, _ text: LocalizedStringKey) -> some View {
        HStack(spacing: 10) {
            Text(verbatim: "\(number)")
                .dxFace(.body, 12, weight: 700)
                .foregroundStyle(PW.ink)
                .frame(width: 24, height: 24)
                .background(PW.surface, in: Circle())
            Text(text).dxFace(.body, 14, weight: 400).foregroundStyle(PW.ink)
        }
        .accessibilityElement(children: .combine)
    }
}

/// "Costs 8 days of smoking" with where the number comes from (MON-03).
struct PriceAnchorLine: View {
    let anchor: PriceAnchor
    var ground: DX.Ground = .reading

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: Self.title(anchor)).dxFace(.body, 16, weight: 700).foregroundStyle(ground.ink)
            Text("A year of the full program, against what you told us you spend.")
                .dxFace(.body, 12, weight: 400).foregroundStyle(ground.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 10).padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ground == .reading ? PW.accentSoft : DX.Fill.onColourCard(for: ground),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    /// "Costs 8 days of smoking", "Costs 1 day of vaping", "Costs 12 days of nicotine" for more than one product.
    static func title(_ anchor: PriceAnchor) -> String {
        let n = anchor.days
        switch anchor.habit {
        case .smoking: return n == 1 ? String(localized: "Costs 1 day of smoking") : String(localized: "Costs \(n) days of smoking")
        case .vaping: return n == 1 ? String(localized: "Costs 1 day of vaping") : String(localized: "Costs \(n) days of vaping")
        case .pouches: return n == 1 ? String(localized: "Costs 1 day of pouches") : String(localized: "Costs \(n) days of pouches")
        case .nicotine: return n == 1 ? String(localized: "Costs 1 day of nicotine") : String(localized: "Costs \(n) days of nicotine")
        }
    }
}
