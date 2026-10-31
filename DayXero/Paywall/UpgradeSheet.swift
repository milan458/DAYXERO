import DayXeroCore
import SwiftUI

/// The free tier's upgrade point (S3.5): shown when someone taps the next locked program day.
/// Same honest terms as the paywall, one plan up front, all plans one tap away.
struct UpgradeSheet: View {
    let dayTitle: String
    @State var model: PaywallModel
    let showAllPlans: () -> Void
    let onUnlocked: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DX.Space.xs) {
            Text("Keep going with \(dayTitle)").v4Text(.title).dxFont(24, weight: 700, style: .title2)
            Text("You finished Day 1. The full program takes you through Quit Day and the four weeks after.")
                .v4Text(.subtitle)
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
            } else {
                ProgressView().frame(maxWidth: .infinity).padding(.vertical, DX.Space.l)
            }
            Button("See all plans", action: showAllPlans).buttonStyle(.dx(.quiet, on: .reading)).frame(maxWidth: .infinity)
        }
        .padding(DX.Space.l)
        .task { await model.load() }
        .background(Read4.background.ignoresSafeArea())
    }
}
