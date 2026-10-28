import DayXeroCore
import SwiftUI

/// Screen 1 (S22): the promise, a restore link for returning buyers, and the 18+ confirmation in the footer.
/// The rolling hills behind it are drawn by OnboardingFlow so they run to the screen's bottom edge.
struct WelcomeScreen: View {
    let model: OnboardingModel
    @Environment(Entitlement.self) private var entitlement
    @State private var restoreNote: LocalizedStringKey?
    @State private var restoring = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(DX.Palette.sage).frame(width: 9, height: 9)
                    Text("DayXero").font(.custom(DX.Typeface.bold, size: 16, relativeTo: .headline))
                }
                .foregroundStyle(DX.Palette.text)
                .accessibilityElement(children: .combine)
                Spacer()
                Button("Restore") { Task { await restore() } }
                    .font(.custom(DX.Typeface.medium, size: 14, relativeTo: .subheadline))
                    .foregroundStyle(DX.Palette.text2)
                    .buttonStyle(.plain)
                    .disabled(restoring)
                    .accessibilityLabel(Text("Restore purchases"))
            }
            Label("Evidence-based 7-day protocol", systemImage: "checkmark.shield")
                .font(.custom(DX.Typeface.medium, size: 12, relativeTo: .caption))
                .foregroundStyle(DX.Palette.accentInk)
                .padding(.vertical, 6).padding(.horizontal, 12)
                .background(DX.Palette.accentSoft, in: Capsule())
                .padding(.top, 40)
            VStack(alignment: .leading, spacing: 0) {
                Text("Don't quit today.").foregroundStyle(DX.Palette.text)
                Text("Quit on your Quit Day.").foregroundStyle(DX.Palette.accentInk)
            }
            .font(.custom(DX.Typeface.bold, size: 34, relativeTo: .largeTitle))
            .tracking(-1.1)
            .minimumScaleFactor(0.8)
            .padding(.top, DX.Space.m)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            Text("A 7-day preparation program for cigarettes, vapes and pouches. Keep using normally while we rewire your triggers, then stop on the day you choose.")
                .font(.custom(DX.Typeface.regular, size: 16, relativeTo: .body))
                .foregroundStyle(DX.Palette.text2)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, DX.Space.s)
            if let restoreNote {
                Text(restoreNote).dxText(.subtitle).padding(.top, DX.Space.s)
            }
            Spacer()
            Button("Build my plan") { model.next() }.buttonStyle(.dxPrimary)
            Text("Takes 2 minutes · Private on this phone · By continuing you confirm you are 18+")
                .font(.custom(DX.Typeface.regular, size: 12, relativeTo: .caption))
                .foregroundStyle(DX.Palette.text2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, DX.Space.s)
        }
        .padding(.horizontal, DX.Space.l)
        .dxReadableColumn()
        .padding(.top, DX.Space.xs)
        .padding(.bottom, DX.Space.xs)
    }

    /// Someone who bought before (new phone, reinstall) gets Pro back now; the paywall is skipped after setup.
    private func restore() async {
        restoring = true
        defer { restoring = false }
        do {
            if try await entitlement.store.restore() {
                entitlement.grant()
                restoreNote = "Your purchase is restored. Set up your plan and everything is unlocked."
            } else {
                restoreNote = "No purchases found for this Apple ID."
            }
        } catch {
            restoreNote = "Couldn't reach the App Store. You can restore later in Settings."
        }
    }
}

/// Rolling moss hills behind the welcome screen (S22): three layers drifting past each other like Home's header,
/// with a dotted path along the middle ridge to a flag on Quit Day. Flat colours, so it works in both themes.
struct Hills: View {
    /// The flag's date; no flag when nil.
    var quitDay: Date? = nil
    var still = false

    /// One hill: its resting height (share of the height), swell, waviness, drift speed (radians a second) and phase.
    private struct Layer {
        let base: CGFloat
        let color: Color
        let amp: CGFloat
        let k: CGFloat
        let speed: CGFloat
        let phase: CGFloat
    }

    private static let layers: [Layer] = [
        Layer(base: 0.30, color: Color(light: 0xDFE3CF, dark: 0x1D2410), amp: 0.06, k: 1.6, speed: 0.34, phase: 0.4),
        Layer(base: 0.47, color: Color(light: 0xC9D0A8, dark: 0x2C3816), amp: 0.05, k: 2.1, speed: -0.44, phase: 2.0),
        Layer(base: 0.68, color: Color(light: 0xBCC388, dark: 0x43511C), amp: 0.04, k: 2.6, speed: 0.55, phase: 4.1),
    ]

    var body: some View {
        TimelineView(.animation(paused: still)) { timeline in
            let t = still ? 0 : CGFloat(timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 10_000))
            Canvas { context, size in
                for (index, layer) in Self.layers.enumerated() {
                    context.fill(hill(size) { y(layer, x: $0, width: size.width, height: size.height, t: t) }, with: .color(layer.color))
                    if index == 1, let quitDay { drawPath(&context, size: size, layer: layer, t: t, quitDay: quitDay) }
                }
            }
        }
        .accessibilityHidden(true)
    }

    /// The ridge height at x: two sines at different speeds, so the hills swell and settle rather than slide.
    private func y(_ layer: Layer, x: CGFloat, width: CGFloat, height: CGFloat, t: CGFloat) -> CGFloat {
        let u = x / max(width, 1) * .pi
        let wave = sin(u * layer.k + t * layer.speed + layer.phase) + 0.45 * cos(u * layer.k * 1.7 - t * layer.speed * 0.6)
        return height * (layer.base + layer.amp * wave)
    }

    private func hill(_ size: CGSize, top: (CGFloat) -> CGFloat) -> Path {
        Path { p in
            p.move(to: CGPoint(x: 0, y: size.height))
            var x: CGFloat = 0
            while x <= size.width + 4 {
                p.addLine(to: CGPoint(x: x, y: top(x)))
                x += 4
            }
            p.addLine(to: CGPoint(x: size.width + 4, y: size.height))
            p.closeSubpath()
        }
    }

    private func drawPath(_ context: inout GraphicsContext, size: CGSize, layer: Layer, t: CGFloat, quitDay: Date) {
        let flagX = size.width * 0.8
        let lift: CGFloat = 14
        var trail = Path()
        var x: CGFloat = 0
        trail.move(to: CGPoint(x: 0, y: y(layer, x: 0, width: size.width, height: size.height, t: t) + lift))
        while x <= flagX {
            // The path climbs from just under the ridge to the flag's foot.
            let rise = lift * (1 - x / flagX)
            trail.addLine(to: CGPoint(x: x, y: y(layer, x: x, width: size.width, height: size.height, t: t) + rise))
            x += 4
        }
        var glow = context
        glow.addFilter(.shadow(color: DX.Palette.sage.opacity(0.9), radius: 6))
        glow.stroke(trail, with: .color(DX.Palette.accentInk), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [0.5, 7]))

        let foot = CGPoint(x: flagX, y: y(layer, x: flagX, width: size.width, height: size.height, t: t))
        var pole = Path()
        pole.move(to: foot)
        pole.addLine(to: CGPoint(x: foot.x, y: foot.y - 28))
        context.stroke(pole, with: .color(DX.Palette.accentInk), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
        var flag = Path()
        flag.move(to: CGPoint(x: foot.x, y: foot.y - 28))
        flag.addLine(to: CGPoint(x: foot.x + 15, y: foot.y - 28))
        flag.addLine(to: CGPoint(x: foot.x + 11, y: foot.y - 22.5))
        flag.addLine(to: CGPoint(x: foot.x + 15, y: foot.y - 17))
        flag.addLine(to: CGPoint(x: foot.x, y: foot.y - 17))
        context.fill(flag, with: .color(DX.Palette.sage))

        let label = context.resolve(Text("Day Xero · \(quitDay, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))")
            .font(.custom(DX.Typeface.semibold, size: 12, relativeTo: .caption))
            .foregroundStyle(DX.Palette.accentInk))
        let textSize = label.measure(in: size)
        let tag = CGRect(x: min(foot.x - textSize.width + 6, size.width - textSize.width - 28), y: foot.y - 64,
                         width: textSize.width + 20, height: textSize.height + 10)
        let capsule = Path(roundedRect: tag, cornerRadius: tag.height / 2)
        context.fill(capsule, with: .color(DX.Palette.canvas))
        context.stroke(capsule, with: .color(DX.Palette.accentInk), lineWidth: 1)
        context.draw(label, at: CGPoint(x: tag.midX, y: tag.midY))
    }
}

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
                    Image(systemName: "lightbulb").font(.system(size: 16, weight: .light)).foregroundStyle(DX.Palette.accentInk)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dual use detected").font(.custom(DX.Typeface.semibold, size: 14, relativeTo: .subheadline))
                            .foregroundStyle(DX.Palette.accentInk)
                        Text("Quitting more than one together needs its own approach. We'll sync them all in your prep plan.")
                            .dxText(.subtitle).fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 14).padding(.horizontal, DX.Space.m)
                .background(DX.Palette.accentSoft, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(DX.Palette.sage.opacity(0.7), style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
                .padding(.top, DX.Space.s)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .accessibilityElement(children: .combine)
            }
        }
        .animation(DX.Motion.animation(DX.Motion.glide, reduceMotion: reduceMotion), value: model.products.count > 1)
    }

    private func product(_ product: Product, title: LocalizedStringResource, detail: LocalizedStringResource, icon: String) -> some View {
        DXOptionCard(title, detail: detail, systemImage: icon, isSelected: model.products.contains(product)) {
            if model.products.contains(product) { model.products.remove(product) } else { model.products.insert(product) }
        }
    }
}
