import DayXeroCore
import SwiftUI

struct WelcomeScreen: View {
    let model: OnboardingModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Circle().fill(DX.Palette.sage).frame(width: 9, height: 9)
                Text("DayXero").font(.custom(DX.Typeface.bold, size: 16, relativeTo: .headline))
            }
            .foregroundStyle(DX.Palette.text)
            .accessibilityElement(children: .combine)
            VStack(alignment: .leading, spacing: 0) {
                Text("Don't quit today.").foregroundStyle(DX.Palette.text)
                Text("Quit on your Quit Day.").foregroundStyle(DX.Palette.accentInk)
            }
            .font(.custom(DX.Typeface.bold, size: 38, relativeTo: .largeTitle))
            .tracking(-1.3)
            .padding(.top, 28)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            Text("A 7-day program for cigarettes, vapes and pouches. Keep using while you prepare, then quit on a day you choose.")
                .dxText(.subtitle)
                .font(.custom(DX.Typeface.regular, size: 15, relativeTo: .body))
                .padding(.top, DX.Space.s)
            Spacer()
            Button("Build my plan") { model.next() }.buttonStyle(.dxPrimary)
            Text("Takes about 3 minutes").dxText(.subtitle).frame(maxWidth: .infinity).padding(.top, DX.Space.xs)
        }
        .padding(.horizontal, DX.Space.l)
        .padding(.top, DX.Space.xxl)
        .padding(.bottom, DX.Space.xs)
        .background(alignment: .bottom) {
            Hills()
                .frame(height: 380)
                .ignoresSafeArea(edges: .bottom)
                .accessibilityHidden(true)
        }
    }
}

/// Rolling moss hills: the methodology's organic topography, flat so it works in both themes.
private struct Hills: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                hill(w, h, [0.42, 0.27, 0.36, 0.25, 0.30], Color(light: 0xDFE3CF, dark: 0x1D2410))
                hill(w, h, [0.58, 0.47, 0.52, 0.43, 0.46], Color(light: 0xC9D0A8, dark: 0x2C3816))
                hill(w, h, [0.74, 0.67, 0.71, 0.63, 0.65], Color(light: 0xBCC388, dark: 0x43511C))
            }
        }
    }

    private func hill(_ w: CGFloat, _ h: CGFloat, _ ys: [CGFloat], _ color: Color) -> some View {
        Path { p in
            p.move(to: CGPoint(x: 0, y: h * ys[0]))
            p.addCurve(to: CGPoint(x: w * 0.55, y: h * ys[2]),
                       control1: CGPoint(x: w * 0.22, y: h * ys[1]), control2: CGPoint(x: w * 0.38, y: h * ys[1] + 30))
            p.addCurve(to: CGPoint(x: w, y: h * ys[4]),
                       control1: CGPoint(x: w * 0.72, y: h * ys[3]), control2: CGPoint(x: w * 0.88, y: h * ys[3]))
            p.addLine(to: CGPoint(x: w, y: h))
            p.addLine(to: CGPoint(x: 0, y: h))
            p.closeSubpath()
        }
        .fill(color)
    }
}

struct AgeScreen: View {
    @Bindable var model: OnboardingModel

    var body: some View {
        OnboardingScaffold(title: "Are you 18 or older?",
                           subtitle: "DayXero is built for adults. This keeps the program and its advice right for you.",
                           model: model) {
            DXOptionCard("Yes, I'm 18 or older", isSelected: model.isAdult == true) { model.isAdult = true }
            DXOptionCard("No, I'm under 18", isSelected: model.isAdult == false) { model.isAdult = false }
        }
    }
}

/// Youth support links shown to under-18s. Placeholders until Milan confirms services and URLs (S2.2).
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
        OnboardingScaffold(title: "Wanting to quit is a great call",
                           subtitle: "DayXero is for adults, but there's free support made for people your age.") {
            ForEach(YouthResource.all) { resource in
                if let url = resource.url {
                    Link(destination: url) { row(resource, external: true) }.buttonStyle(.plain)
                } else {
                    row(resource, external: false)
                }
            }
        } footer: {
            Text("You can also talk to a parent, school nurse or doctor.")
                .dxText(.subtitle).multilineTextAlignment(.center).frame(maxWidth: .infinity)
        }
    }

    private func row(_ resource: YouthResource, external: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(resource.title).font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .body)).foregroundStyle(DX.Palette.text)
                Text(resource.detail).dxText(.subtitle)
            }
            Spacer()
            if external {
                Image(systemName: "arrow.up.right").foregroundStyle(DX.Palette.muted)
            }
        }
        .padding(14)
        .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(DX.Palette.hairline))
        .accessibilityElement(children: .combine)
    }
}

struct NameScreen: View {
    @Bindable var model: OnboardingModel
    @FocusState private var focused: Bool

    var body: some View {
        OnboardingScaffold(title: "What should we call you?",
                           subtitle: "Just a first name or nickname. It stays on this phone.",
                           model: model) {
            TextField("", text: $model.name, prompt: Text("Your name").foregroundStyle(DX.Palette.faint))
                .font(DX.TextStyle.body.font)
                .foregroundStyle(DX.Palette.text)
                .textContentType(.givenName)
                .submitLabel(.continue)
                .focused($focused)
                .onSubmit { if model.canContinue { model.next() } }
                .padding(.horizontal, 18)
                .frame(minHeight: DX.Size.inputHeight)
                .background(DX.Palette.surface2, in: RoundedRectangle(cornerRadius: DX.Radius.input, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DX.Radius.input, style: .continuous)
                        .strokeBorder(focused ? DX.Palette.sage.opacity(0.8) : DX.Palette.hairline)
                )
                .accessibilityLabel(Text("Your name"))
        }
        .onAppear { focused = true }
    }
}

struct ProductsScreen: View {
    @Bindable var model: OnboardingModel

    var body: some View {
        OnboardingScaffold(title: "What do you use?",
                           subtitle: "Pick everything that applies. Each one gets its own counter.",
                           model: model) {
            product(.cigarettes, detail: "Including roll-ups", icon: "smoke")
            product(.vape, detail: "Disposables, pods or tanks", icon: "wind")
            product(.pouches, detail: "Zyn, Velo and others", icon: "capsule")
            Text("Already using").dxText(.micro).padding(.top, DX.Space.xs)
            DXOptionCard("Nicotine replacement", detail: "Patch, gum, lozenge or inhaler", systemImage: "cross.case",
                         isSelected: model.usesNRT) { model.usesNRT.toggle() }
        }
    }

    private func product(_ product: Product, detail: LocalizedStringResource, icon: String) -> some View {
        DXOptionCard(product.title, detail: detail, systemImage: icon, isSelected: model.products.contains(product)) {
            if model.products.contains(product) { model.products.remove(product) } else { model.products.insert(product) }
        }
    }
}
