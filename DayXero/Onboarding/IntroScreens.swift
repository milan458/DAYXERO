import DayXeroCore
import SwiftUI

/// Youth support links for anyone who said they were under 18 in an earlier version (the flag persists).
/// Placeholders until Milan confirms services and URLs (S2.2).
struct YouthResource: Identifiable {
    let id: String
    let title: LocalizedStringResource
    let detail: LocalizedStringResource
    let url: URL?

    static let all: [YouthResource] = [
        YouthResource(id: "us", title: "Youth quit support (US)", detail: "Free text-message program", url: nil),
        YouthResource(id: "uk", title: "Youth quit support (UK)", detail: "Free local stop smoking service", url: nil),
        YouthResource(id: "au-ca", title: "Youth quit support (AU, CA)", detail: "Free quitline", url: nil),
    ]
}

struct UnderAgeScreen: View {
    var body: some View {
        // This screen sits on the cream reading ground, so Xero's bubbles take a surface fill and a hairline
        // (navy ink on #F1EBE2 is well over 4.5:1) instead of the cream card on colour, which vanished into it.
        OnboardingScaffold(title: "Wanting to quit is a great call",
                           subtitle: "DayXero is for adults, but there's free support made for people your age.",
                           bubbleFill: DX.Fill.surface, bubbleBorder: Onb.hairline) {
            ForEach(YouthResource.all) { resource in
                if let url = resource.url {
                    Link(destination: url) { row(resource, external: true) }.buttonStyle(.plain)
                } else {
                    row(resource, external: false)
                }
            }
        } footer: {
            Text("You can also talk to a parent, school nurse or doctor.")
                .onbText(.subtitle).multilineTextAlignment(.center).frame(maxWidth: .infinity)
        }
    }

    private func row(_ resource: YouthResource, external: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(resource.title).dxFont(15, weight: 600, style: .body).foregroundStyle(Onb.ink)
                Text(resource.detail).onbText(.subtitle)
            }
            Spacer()
            if external {
                Image(systemName: "arrow.up.right").foregroundStyle(Onb.muted)
            }
        }
        .padding(14)
        .background(Onb.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Onb.hairline))
        .accessibilityElement(children: .combine)
    }
}

/// Screen 2 (S22): what they use, with a note when it's more than one.
struct ProductsScreen: View {
    @Bindable var model: OnboardingModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        OnboardingScaffold(title: "What are we leaving behind?",
                           subtitle: "Pick everything you use now. We'll set up your counters and biology for each one.",
                           model: model) {
            product(.cigarettes, title: "Cigarettes", detail: "Manufactured or roll-ups", icon: "smoke")
            product(.vape, title: "Vape or e-cigarette", detail: "Disposables, pods or refillable tanks", icon: "wind")
            product(.pouches, title: "Nicotine pouches or snus", detail: "Zyn, Velo or other oral pouches", icon: "capsule")
            if model.products.count > 1 {
                HStack(alignment: .top, spacing: DX.Space.s) {
                    Image(systemName: "lightbulb").font(.system(size: 16, weight: .light)).foregroundStyle(Onb.accent)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dual use detected").dxFont(14, weight: 600, style: .subheadline)
                            .foregroundStyle(Onb.accent)
                        Text("Quitting more than one together needs its own approach. We'll sync them all in your prep plan.")
                            .onbText(.subtitle).fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 14).padding(.horizontal, DX.Space.m)
                .background(Onb.accentSoft, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Onb.accent.opacity(0.7), style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
                .padding(.top, DX.Space.s)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .accessibilityElement(children: .combine)
            }
        }
        .animation(DX.Move.animation(DX.Move.settle, reduceMotion: reduceMotion), value: model.products.count > 1)
    }

    private func product(_ product: Product, title: LocalizedStringResource, detail: LocalizedStringResource, icon: String) -> some View {
        OnbOptionCard(title, detail: detail, systemImage: icon, isSelected: model.products.contains(product)) {
            if model.products.contains(product) { model.products.remove(product) } else { model.products.insert(product) }
        }
    }
}
