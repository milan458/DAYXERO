import DayXeroCore
import SwiftData
import SwiftUI

/// The free tier's upgrade point (S3.5): shown when someone taps a locked session, first Prep 4 after the free taste of
/// Prep 1 to 3 (MON-01). Same honest terms as the paywall, one plan up front, all plans one tap away. The 7-day trial
/// is sold here whenever the Quit Day is, with the price in the person's own habit (MON-03).
struct UpgradeSheet: View {
    let dayTitle: String
    @State var model: PaywallModel
    let showAllPlans: () -> Void
    let onUnlocked: () -> Void

    @Query private var profiles: [UserProfile]

    var body: some View {
        VStack(alignment: .leading, spacing: DX.Space.xs) {
            Text("Keep going with \(dayTitle)").v4Text(.title).dxFont(24, weight: 700, style: .title2)
            Text("The full program carries on from here: your Day Xero launch kit, Weeks 1 to 4, and every prep session in full.")
                .v4Text(.subtitle)
            if let option = model.plans.first(where: { $0.plan == .annual }), let anchor = model.anchor(for: option) {
                PriceAnchorLine(anchor: anchor).padding(.top, DX.Space.s)
            }
            if let option = model.plans.first(where: { $0.plan == .annual }) ?? model.plans.first {
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.plan == .annual ? "Yearly" : "Full program")
                        .dxFont(16, weight: 600, style: .body).foregroundStyle(Read4.ink)
                    if let end = model.trialEndDate, option.trialDays != nil {
                        Text("Free until \(end, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated)), then \(option.priceText) a year")
                            .v4Text(.subtitle)
                    } else {
                        Text(verbatim: option.priceText).v4Text(.subtitle)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Read4.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Read4.accent, lineWidth: 1.5))
                .padding(.top, DX.Space.s)
                .onAppear { model.select(option.plan) }

                Button {
                    Task {
                        await model.purchase()
                        if model.phase == .unlocked { onUnlocked() }
                    }
                } label: {
                    if let days = option.trialDays {
                        Text("Start my free \(days) days")
                    } else {
                        Text("Unlock for \(option.priceText)")
                    }
                }
                .buttonStyle(.dx(.primary, on: .reading))
                .disabled(model.phase != .ready)
                .padding(.top, DX.Space.s)
            } else if model.phase == .failed {
                Text("Couldn't reach the App Store. Check your connection and try again.").v4Text(.subtitle)
            } else if model.phase == .loading {
                ProgressView().frame(maxWidth: .infinity).padding(.vertical, DX.Space.l)
            }
            if let days = model.trialEndsAfterQuitDay, days > 0 {
                Text(days == 1 ? "That's the day after your Quit Day, so Day Xero is covered." : "That's \(days) days after your Quit Day, so Day Xero is covered.")
                    .v4Text(.subtitle)
                    .padding(.top, DX.Space.xs)
            }
            Button("See all plans", action: showAllPlans).buttonStyle(.dx(.quiet, on: .reading)).frame(maxWidth: .infinity)
            // Every screen that sells a subscription names what stays free and links Terms and Privacy (S27.2, S27.1).
            VStack(spacing: 2) {
                Text(FreeLine.text)
                HStack(spacing: 6) {
                    Link("Terms", destination: AppLinks.terms).underline()
                    if let privacy = AppLinks.privacy {
                        Text(verbatim: "·")
                        Link("Privacy", destination: privacy).underline()
                    }
                }
            }
            .dxFont(12, weight: 400, style: .caption2)
            .foregroundStyle(Read4.muted)
            .tint(Read4.muted)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
        }
        .padding(DX.Space.l)
        .task {
            model.quitDay = profiles.first?.quitDay
            model.spend = PaywallModel.Spend(profile: profiles.first)
            await model.load()
        }
        .background(Read4.background.ignoresSafeArea())
    }
}
