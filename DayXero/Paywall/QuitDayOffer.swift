import DayXeroCore
import SwiftData
import SwiftUI

/// Q3 Quit Day offer (cream, serious tier): shown once after the Day Xero session to anyone without the full
/// program (decision 23). Prices, trial length and the plan list come from the store; nothing is charged today
/// when there's a trial. Closing keeps the free version: the counter, Craving SOS and prep.
struct QuitDayOffer: View {
    let profile: UserProfile
    let onClose: () -> Void

    @Environment(Entitlement.self) private var entitlement
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model: PaywallModel?
    @State private var showBilling = false

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .foregroundStyle(Read4.ink)
        .background(Read4.background.ignoresSafeArea())
        .task {
            let model = PaywallModel(store: entitlement.store, entitlement: entitlement)
            self.model = model
            await model.load()
        }
        .sheet(isPresented: $showBilling) { BillingSheet().presentationDetents([.medium, .large]) }
    }

    @ViewBuilder
    private func content(_ model: PaywallModel) -> some View {
        switch model.phase {
        case .unlocked:
            message(icon: "checkmark", title: "You're all set",
                    line: model.trialEndDate.map { end in
                        String(localized: "Your free trial runs until \(end.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))). Week 1 is ready when it opens.")
                    } ?? String(localized: "The full program is unlocked. Week 1 is ready when it opens."),
                    button: "Back to my day")
        case .pending:
            message(icon: "clock", title: "Waiting for approval",
                    line: String(localized: "Your purchase needs approval (for example, Ask to Buy). We'll unlock everything as soon as it goes through."),
                    button: "Back to my day")
        case .failed:
            message(icon: "wifi.slash", title: "Couldn't load the plans",
                    line: String(localized: "Check your connection and try again. Everything free keeps working."),
                    button: "Not now")
        case .loading, .ready, .purchasing:
            offer(model)
        }
    }

    // MARK: Offer

    private func offer(_ model: PaywallModel) -> some View {
        VStack(spacing: 0) {
            HStack {
                XeroView(mood: .calm, stage: 1, size: .avatar, animate: false)
                    .background(DX.Ground.apricot.background, in: Circle())
                    .clipShape(Circle())
                    .accessibilityHidden(true)
                Spacer()
                Button {
                    model.dismissed()
                    onClose()
                } label: {
                    Image(systemName: "xmark").font(.system(size: 16, weight: .bold)).foregroundStyle(Read4.ink)
                        .frame(width: 44, height: 44)
                        .background(Read4.surface, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Close and continue with the free version"))
            }
            .padding(.horizontal, DX.Layout.gutter)
            .padding(.top, DX.Space.xs)
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(verbatim: headline).dxType(.large).accessibilityAddTraits(.isHeader).dxArrive(0)
                    Text(verbatim: line(model)).dxType(.body).foregroundStyle(Read4.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .dxArrive(1)
                    VStack(alignment: .leading, spacing: 8) {
                        included("Quit week and 4 weeks after")
                        included("Insights on your triggers")
                        included("NRT planner, health timeline, share cards")
                        Text("Always free: your counter and Craving SOS.").dxType(.footnote).foregroundStyle(Read4.muted)
                            .padding(.top, 2)
                    }
                    .v4Card()
                    .dxArrive(2)
                    plans(model).dxArrive(3)
                    if let option = model.selectedOption, option.trialDays != nil, let end = model.trialEndDate {
                        timeline(option: option, end: end).dxArrive(4)
                    }
                }
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.top, DX.Space.s)
                .padding(.bottom, DX.Space.m)
            }
            .scrollBounceBehavior(.basedOnSize)
            footer(model)
        }
        .dxReadableColumn()
        .overlay(alignment: .top) {
            if let notice = model.notice {
                Text(notice).dxType(.footnote).foregroundStyle(DX.Fill.cream)
                    .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                    .background(DX.Fill.navy, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.horizontal, DX.Layout.gutter)
                    .onTapGesture { model.notice = nil }
            }
        }
    }

    private var headline: String {
        switch nextState {
        case .available?, .inProgress?: String(localized: "Week 1 is ready")
        default: String(localized: "Week 1 starts tomorrow")
        }
    }

    /// "Day 1, Look after the basics, opens on Sat 7 Nov. Try the full program free for 3 days."
    private func line(_ model: PaywallModel) -> String {
        let store = ProgramStore(context: context, profile: profile)
        let opens: String
        if let next = store.content?.session(after: ProgramV2Access.offerAfter) {
            let title = next.title.resolve(store.variant) ?? ""
            switch nextState {
            case .available?, .inProgress?: opens = String(localized: "\(next.label), \(title), is ready now.")
            case .scheduled(.tomorrow)?:
                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
                opens = String(localized: "\(next.label), \(title), opens on \(tomorrow.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))).")
            default: opens = String(localized: "\(next.label), \(title), opens soon.")
            }
        } else {
            opens = ""
        }
        let trial = model.plans.first { $0.plan == .annual }?.trialDays
        let offer = trial.map { String(localized: "Try the full program free for \($0) days.") }
            ?? String(localized: "Unlock the full program to keep going.")
        return [opens, offer].filter { !$0.isEmpty }.joined(separator: " ")
    }

    private var nextState: ProgramUnlock.State? {
        let store = ProgramStore(context: context, profile: profile)
        return store.content?.session(after: ProgramV2Access.offerAfter).map { store.state(of: $0.id) }
    }

    private func included(_ text: LocalizedStringKey) -> some View {
        Label {
            Text(text).dxType(.body)
        } icon: {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Read4.accent)
        }
    }

    // MARK: Plans

    @ViewBuilder
    private func plans(_ model: PaywallModel) -> some View {
        if model.plans.isEmpty {
            ProgressView().frame(maxWidth: .infinity, minHeight: 120)
        } else {
            VStack(spacing: 8) {
                ForEach(model.plans.filter { $0.plan != .lifetime }) { option in
                    planCard(option, model: model)
                }
                if let lifetime = model.plans.first(where: { $0.plan == .lifetime }) {
                    Button { model.select(.lifetime) } label: {
                        Text("Pay once · \(lifetime.priceText)")
                            .dxFont(14, weight: model.selected == .lifetime ? 700 : 600, style: .footnote)
                            .underline(model.selected == .lifetime)
                            .foregroundStyle(Read4.ink)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(model.selected == .lifetime ? [.isButton, .isSelected] : .isButton)
                }
            }
        }
    }

    private func planCard(_ option: PlanOption, model: PaywallModel) -> some View {
        let on = model.selected == option.plan
        return Button { model.select(option.plan) } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: on ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 22)).foregroundStyle(on ? Read4.accent : Read4.faint)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    if option.plan == .annual, let days = option.trialDays {
                        Text(model.annualSavingPercent.map { "\(days) DAYS FREE · SAVE \($0)%" as LocalizedStringKey } ?? "\(days) DAYS FREE")
                            .dxType(.caption).foregroundStyle(Read4.accent)
                    }
                    Text(option.plan == .annual ? "Yearly" : "Monthly").dxType(.headline)
                    Text(option.plan == .annual ? (option.perMonthText.map { "\($0) a month" } ?? "") : String(localized: "Billed today · Cancel anytime"))
                        .dxType(.footnote).foregroundStyle(Read4.muted)
                }
                Spacer(minLength: 0)
                Text(option.plan == .annual ? "\(option.priceText)/yr" : "\(option.priceText)/mo")
                    .dxType(.headline).monospacedDigit()
            }
            .padding(14)
            .background(Read4.card, in: RoundedRectangle(cornerRadius: DX.Layout.smallCardRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DX.Layout.smallCardRadius, style: .continuous)
                .strokeBorder(on ? Read4.ink : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
    }

    /// Today unlocked and nothing charged; the reminder; the first charge unless cancelled.
    private func timeline(option: PlanOption, end: Date) -> some View {
        let lead = TrialReminder.leadDays(trialEndsAt: end, now: .now)
        let remind = Calendar.current.date(byAdding: .day, value: -lead, to: end) ?? end
        let date: (Date) -> String = { $0.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)) }
        return VStack(alignment: .leading, spacing: 0) {
            step(String(localized: "Today"), String(localized: "The full program unlocks. Nothing charged."), first: true)
            step(date(remind), String(localized: "We remind you before the trial ends."))
            step(date(end), String(localized: "\(option.priceText) unless you cancel."), last: true)
        }
        .v4Card()
        .accessibilityElement(children: .combine)
    }

    private func step(_ when: String, _ what: String, first: Bool = false, last: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Rectangle().fill(first ? .clear : Read4.track).frame(width: 2, height: 6)
                Circle().fill(first ? Read4.accent : Read4.track).frame(width: 12, height: 12)
                Rectangle().fill(last ? .clear : Read4.track).frame(width: 2).frame(maxHeight: .infinity)
            }
            .frame(width: 12)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: when).dxFont(14, weight: 700, style: .footnote)
                Text(verbatim: what).dxType(.footnote).foregroundStyle(Read4.muted).fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, last ? 0 : 12)
        }
    }

    // MARK: Footer

    private func footer(_ model: PaywallModel) -> some View {
        VStack(spacing: 4) {
            Button {
                Task { await model.purchase() }
            } label: {
                if model.phase == .purchasing { ProgressView() } else { Text(cta(model)) }
            }
            .buttonStyle(.dx(.primary, on: .reading))
            .disabled(model.selectedOption == nil || model.phase == .purchasing)
            Button("Not now") {
                model.dismissed()
                onClose()
            }
            .buttonStyle(.dx(.quiet, on: .reading))
            ViewThatFits {
                HStack(spacing: 6) { links(model, separators: true) }
                VStack(spacing: 4) { links(model, separators: false) }
            }
            .dxType(.caption)
            .foregroundStyle(Read4.muted)
            .tint(Read4.muted)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .padding(.horizontal, DX.Layout.buttonGutter)
        .padding(.bottom, DX.Space.xs)
    }

    @ViewBuilder
    private func links(_ model: PaywallModel, separators: Bool) -> some View {
        Button("Restore purchases") { Task { await model.restore() } }.buttonStyle(.plain).underline()
        if separators { Text(verbatim: "·") }
        Button("How billing works") { showBilling = true }.buttonStyle(.plain).underline()
        if separators { Text(verbatim: "·") }
        Link("Terms", destination: AppLinks.terms).underline()
        if let privacy = AppLinks.privacy {
            if separators { Text(verbatim: "·") }
            Link("Privacy", destination: privacy).underline()
        }
    }

    private func cta(_ model: PaywallModel) -> LocalizedStringKey {
        guard let option = model.selectedOption else { return "Loading prices…" }
        switch option.plan {
        case .annual:
            if let days = option.trialDays { return "Start my \(days)-day free trial" }
            return "Subscribe for \(option.priceText) a year"
        case .monthly: return "Subscribe for \(option.priceText) a month"
        case .lifetime: return "Buy lifetime for \(option.priceText)"
        }
    }

    // MARK: Messages

    private func message(icon: String, title: LocalizedStringKey, line: String, button: LocalizedStringKey) -> some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: icon).font(.system(size: 30, weight: .bold)).foregroundStyle(Read4.accent)
                .frame(width: 76, height: 76).background(Read4.accentSoft, in: Circle())
                .accessibilityHidden(true)
            Text(title).dxType(.large).multilineTextAlignment(.center).accessibilityAddTraits(.isHeader)
            Text(verbatim: line).dxType(.body).foregroundStyle(Read4.muted).multilineTextAlignment(.center)
            Spacer()
            Button(button, action: onClose).buttonStyle(.dx(.primary, on: .reading))
        }
        .padding(.horizontal, DX.Layout.buttonGutter)
        .padding(.bottom, DX.Space.xs)
        .dxReadableColumn()
    }
}
