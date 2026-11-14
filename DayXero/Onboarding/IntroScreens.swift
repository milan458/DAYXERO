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

/// Screen 2 (S22, v5 003): what they use, as checkbox rows with paper-cut product art, and Xero's note with the count.
///
/// Motion (003): question and helper arrive (600 ms, 90 ms stagger), then the three rows and the note in order. A pick
/// fills and ticks the checkbox, tints the row and dips it to .97 (520 ms spring); the note's count changes while Xero
/// bobs beside it. Selection haptic on each pick.
struct ProductsScreen: View {
    @Bindable var model: OnboardingModel

    var body: some View {
        OnboardingScaffold(title: "What are you leaving behind?",
                           subtitle: "Pick everything you use now. I'll set up a counter for each one.",
                           model: model) {
            product(.cigarettes, title: "Cigarettes", detail: "Manufactured or roll-ups").dxArrive(2)
            product(.vape, title: "Vape", detail: "Disposables, pods or tanks").dxArrive(3)
            product(.pouches, title: "Nicotine pouches", detail: "Zyn, Velo, snus").dxArrive(4)
            // v5 (003): Xero's note on the cream card, with the count.
            HStack(alignment: .center, spacing: 12) {
                XeroView(mood: .hello, stage: 0, points: 88)
                    .dxBob()
                    .frame(width: 88, height: 88)
                    .accessibilityHidden(true)
                note
                    .dxType(.body)
                    .foregroundStyle(Onb.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.25), value: model.products.count)
            }
            .padding(.leading, 14).padding(.trailing, 20).padding(.vertical, 18)
            .background(Color(light: 0xFFF8EE, dark: 0x182034), in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous).strokeBorder(Onb.hairline))
            .padding(.top, 4)
            .accessibilityElement(children: .combine)
            .dxArrive(5)
        }
    }

    private var note: Text {
        let n = model.products.count
        let bold = Text("\(n) picked.").dxRun(16, weight: 700)
        switch n {
        case 0: return Text("Pick all you use. Lots of people use more than one.")
        case 1: return bold + Text(" Lots of people use more than one. Pick them all.")
        default: return bold + Text(" Lots of people use both. I'll plan for each.")
        }
    }

    private func product(_ product: Product, title: LocalizedStringResource, detail: LocalizedStringResource) -> some View {
        OnbOptionCard(title, detail: detail, art: product, multi: true, minHeight: 84, isSelected: model.products.contains(product)) {
            if model.products.contains(product) { model.products.remove(product) } else { model.products.insert(product) }
        }
    }
}
