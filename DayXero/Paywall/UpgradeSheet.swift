import DayXeroCore
import SwiftData
import SwiftUI

/// The free tier's upgrade point (S3.5): shown when someone without the full program taps a program session; none is
/// free (16 Nov 2026). Same honest terms as the paywall, one plan up front, both plans one tap away. The 3-day trial
/// is sold here whenever the Day Xero is, with the price in the person's own habit (MON-03).
struct UpgradeSheet: View {
    let dayTitle: String
    @State var model: PaywallModel
    let showAllPlans: () -> Void
    let onUnlocked: () -> Void

    @Query private var profiles: [UserProfile]

    var body: some View {
        VStack(alignment: .leading, spacing: DX.Space.xs) {
            Text("Unlock \(dayTitle)").dxType(.title).foregroundStyle(DX.Ground.reading.ink).dxFace(.display, 24, weight: 700)
            Text("It's part of the full program: your prep days, your Day Xero launch kit and Weeks 1 to 4.")
                .dxType(.footnote).foregroundStyle(DX.Ground.reading.muted)
            if let option = model.plans.first(where: { $0.plan == .annual }), let anchor = model.anchor(for: option) {
                PriceAnchorLine(anchor: anchor).padding(.top, DX.Space.s)
            }
            if let option = model.plans.first(where: { $0.plan == .annual }) ?? model.plans.first {
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.plan == .annual ? "Yearly" : "Full program")
                        .dxFace(.body, 16, weight: 600).foregroundStyle(DX.Ground.reading.ink)
                    if let end = model.trialEndDate, option.trialDays != nil {
                        Text("Free until \(end, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated)), then \(option.priceText) a year")
                            .dxType(.footnote).foregroundStyle(DX.Ground.reading.muted)
                    } else {
                        Text(verbatim: option.priceText).dxType(.footnote).foregroundStyle(DX.Ground.reading.muted)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DX.Ground.reading.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(DX.Ground.reading.selEdge, lineWidth: 1.5))
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
                Text("Couldn't reach the App Store. Check your connection and try again.").dxType(.footnote).foregroundStyle(DX.Ground.reading.muted)
            } else if model.phase == .loading {
                ProgressView().frame(maxWidth: .infinity).padding(.vertical, DX.Space.l)
            }
            if model.selectedOption?.trialDays != nil {
                Text("During the free trial, Prep 1 to 3 open one a day. The rest opens when the trial ends.")
                    .dxType(.footnote).foregroundStyle(DX.Ground.reading.muted)
                    .padding(.top, DX.Space.xs)
            }
            Button("See all plans", action: showAllPlans).buttonStyle(.dx(.quiet, on: .reading)).frame(maxWidth: .infinity)
            // Every screen that sells a subscription links Terms and Privacy (S27.1).
            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    Link("Terms", destination: AppLinks.terms).underline()
                    if let privacy = AppLinks.privacy {
                        Text(verbatim: "·")
                        Link("Privacy", destination: privacy).underline()
                    }
                }
            }
            .dxFace(.body, 12, weight: 400)
            .foregroundStyle(DX.Ground.reading.muted)
            .tint(DX.Ground.reading.muted)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
        }
        .padding(DX.Space.l)
        .task {
            model.quitDay = profiles.first?.quitDay
            model.spend = PaywallModel.Spend(profile: profiles.first)
            await model.load()
        }
        .background(DX.Ground.reading.background.ignoresSafeArea())
    }
}
