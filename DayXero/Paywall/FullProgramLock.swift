import DayXeroCore
import SwiftUI

/// A paid feature's place for someone on the free tier (MON-01): what it does, and one way to the paywall. The free
/// part of the screen around it keeps working.
struct LockedFeatureCard: View {
    let title: LocalizedStringKey
    let line: LocalizedStringKey
    var ground: DX.Ground = .reading
    let onUnlock: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DX.Space.xs) {
            Label {
                Text(title).dxFont(16, weight: 700, style: .headline).foregroundStyle(ground.ink)
            } icon: {
                Image(systemName: "lock.fill").font(.system(size: 13, weight: .bold)).foregroundStyle(ground.ink)
            }
            Text(line).dxFont(14, weight: 400, style: .footnote).foregroundStyle(ground.muted)
                .fixedSize(horizontal: false, vertical: true)
            Button("Unlock the full program", action: onUnlock)
                .buttonStyle(.dx(.secondary, on: ground))
                .padding(.top, DX.Space.xxs)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ground == .reading ? DX.Fill.raised : DX.Fill.onColourCard(for: ground),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

extension View {
    /// DayXero's paywall over this view, for a locked feature (MON-01). Does nothing without an entitlement in the
    /// environment, so a screen shown above the app's environment can't crash on it.
    func fullProgramPaywall(isPresented: Binding<Bool>, profile: UserProfile?) -> some View {
        modifier(FullProgramPaywall(isPresented: isPresented, profile: profile))
    }
}

private struct FullProgramPaywall: ViewModifier {
    @Binding var isPresented: Bool
    let profile: UserProfile?
    @Environment(Entitlement.self) private var entitlement: Entitlement?

    func body(content: Content) -> some View {
        content.fullScreenCover(isPresented: $isPresented) {
            if let entitlement {
                PaywallView(name: profile?.name ?? "", quitDay: profile?.quitDay ?? .now,
                            model: PaywallModel(store: entitlement.store, entitlement: entitlement),
                            onClose: { isPresented = false })
            }
        }
    }
}
