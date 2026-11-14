import DayXeroCore
import PhotosUI
import SwiftUI

// MARK: Shared pieces

/// A section label above a group of controls (kit `.lbl`: 700 14 pt ink, 20 pt above).
struct OnboardingSection<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).dxFace(.body, 14, weight: 700).foregroundStyle(Onb.ink)
            content()
        }
        .padding(.top, 8)
    }
}

/// The kit chip (`.chip`): 44 pt, radius 14, the ground's card; chosen, the warm tint with a 2 pt edge and bold words,
/// and a quick 1.1 bump as it lands (`.chip.land`).
struct OnbChipFace: View {
    let text: String
    let isOn: Bool
    var fill = false
    var side: CGFloat = 16
    var height: CGFloat = 44
    let land: Int
    private let motion = MotionPolicy()

    var body: some View {
        let g = DX.Ground.apricot
        let shape = RoundedRectangle(cornerRadius: DX.Layout.chipRadius, style: .continuous)
        Text(verbatim: text)
            .dxFace(.body, 15, weight: isOn ? 700 : 600)
            .foregroundStyle(g.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, fill ? 8 : side)
            .frame(maxWidth: fill ? .infinity : nil, minHeight: height)
            .background(isOn ? g.selTint : g.card, in: shape)
            .overlay { if isOn { shape.strokeBorder(g.selEdge, lineWidth: 2) } else { shape.strokeBorder(Onb.chipLine, lineWidth: 1) } }
            .contentShape(shape)
            .animation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.25), value: isOn)
            .phaseAnimator([1.0, 1.1, 1.0], trigger: land) { view, scale in
                view.scaleEffect(motion.reduce ? 1 : scale)
            } animation: { scale in
                scale == 1.1 ? .timingCurve(0.3, 1.4, 0.5, 1, duration: 0.21) : .timingCurve(0.3, 1.4, 0.5, 1, duration: 0.31)
            }
    }
}

/// Equal-width chips in a row: one choice from a few (kit `.chips.even`).
struct OnboardingSegments<Value: Hashable>: View {
    let options: [Value]
    let isSelected: (Value) -> Bool
    let title: (Value) -> String
    let select: (Value) -> Void
    @State private var taps = 0
    @State private var landed: [Value: Int] = [:]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.self) { option in
                let on = isSelected(option)
                Button {
                    taps += 1
                    if !on { landed[option, default: 0] += 1 }
                    select(option)
                } label: {
                    OnbChipFace(text: title(option), isOn: on, fill: true, land: landed[option] ?? 0)
                }
                .buttonStyle(.dxPress)
                .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
            }
        }
        // One haptic per tap: a trigger on each chip's `on` fired for the chip leaving and the chip arriving.
        .sensoryFeedback(DX.Haptic.select, trigger: taps)
    }
}

/// A kit chip in a wrapping row.
struct OnboardingChip: View {
    let text: String
    let isOn: Bool
    let action: () -> Void
    @State private var taps = 0
    @State private var land = 0

    var body: some View {
        Button {
            taps += 1
            if !isOn { land += 1 }
            action()
        } label: {
            OnbChipFace(text: text, isOn: isOn, land: land)
        }
        .buttonStyle(.dxPress)
        .sensoryFeedback(DX.Haptic.select, trigger: taps)
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
    }
}

/// The money card (004): the yearly cost as the hero, counting to each new figure, with Xero pleased beside a small
/// paper coin pile (the top coin drops in again when the figure changes), and the daily cost under a hairline.
struct BaselineMoneyCard: View {
    let lead: String
    let yearly: Decimal
    let yearLine: String
    let daily: String
    let currency: String
    @State private var drops = 0

    var body: some View {
        let g = DX.Ground.apricot
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: lead).dxType(.footnote).foregroundStyle(g.muted)
                    CountingText(NSDecimalNumber(decimal: yearly).doubleValue, from: NSDecimalNumber(decimal: yearly).doubleValue,
                                 delay: 0, duration: 0.7) { v in
                        Decimal(v.rounded()).formatted(.currency(code: currency).precision(.fractionLength(0)))
                    }
                    .dxType(.display)
                    .monospacedDigit()
                    .foregroundStyle(g.ink)
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .padding(.top, 4).padding(.bottom, 2)
                    Text(verbatim: yearLine).dxType(.footnote).foregroundStyle(g.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                ZStack(alignment: .topTrailing) {
                    XeroView(mood: .hello, stage: 0, points: 80)
                        .padding(.top, 6)
                    CoinPile(drops: drops)
                        .frame(maxHeight: .infinity, alignment: .bottomLeading)
                        .padding(.bottom, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(width: 112, height: 100)
                .accessibilityHidden(true)
            }
            (Text(verbatim: daily).dxRun(15, weight: 700).foregroundStyle(g.ink) + Text(" Yours again from Quit Day."))
                .dxType(.footnote).foregroundStyle(g.muted)
                .padding(.top, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .top) { Rectangle().fill(g.line).frame(height: 1) }
                .padding(.top, 14)
        }
        .padding(.top, 22).padding(.bottom, 20).padding(.leading, 20).padding(.trailing, 16)
        .background(g.card, in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous).strokeBorder(Onb.chipLine, lineWidth: 1))
        .padding(.top, 12)
        .onChange(of: yearly) { drops += 1 }
        .accessibilityElement(children: .combine)
    }
}

/// Three flat paper-cut coins in a pile; the top one drops 18 pt into place (420 ms settle) from 1.1 s, and again
/// whenever `drops` changes.
private struct CoinPile: View {
    let drops: Int
    @State private var landed = false
    @Environment(\.colorScheme) private var scheme
    private let motion = MotionPolicy()

    var body: some View {
        let shadow = scheme == .dark ? Color.black.opacity(0.55) : Color(red: 120 / 255, green: 52 / 255, blue: 24 / 255).opacity(0.26)
        ZStack(alignment: .topLeading) {
            coin(12, 33).shadow(color: shadow, radius: 1, y: 1.6)
            coin(27, 33).shadow(color: shadow, radius: 1, y: 1.6)
            coin(19.5, 17.5).shadow(color: shadow, radius: 1, y: 1.6)
                .opacity(landed || motion.reduce ? 1 : 0)
                .offset(y: landed || motion.reduce ? 0 : -18)
        }
        .frame(width: 40, height: 46, alignment: .topLeading)
        .task(id: drops) {
            landed = false
            try? await Task.sleep(for: .seconds(drops == 0 ? 1.1 : 0.05))
            withAnimation(DX.Move.settle.speed(0.9 / 0.42)) { landed = true }
        }
    }

    private func coin(_ cx: CGFloat, _ cy: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Circle().fill(Color(hex: 0xF5B83D)).frame(width: 21, height: 21).offset(x: cx + 1.3 - 10.5, y: cy + 1 - 10.5)
            Circle().fill(Color(hex: 0xFFD966)).frame(width: 21, height: 21).offset(x: cx - 10.5, y: cy - 10.5)
            Circle().stroke(Color(hex: 0xF5B83D), lineWidth: 1.6).frame(width: 12.8, height: 12.8).offset(x: cx - 6.4, y: cy - 6.4)
            Path { p in
                p.addArc(center: CGPoint(x: cx, y: cy), radius: 8, startAngle: .degrees(199), endAngle: .degrees(249), clockwise: false)
            }
            .stroke(Color(hex: 0xFFF3C4), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        }
        .frame(width: 40, height: 46, alignment: .topLeading)
    }
}

// v4 has no emoji (design doc §4): chips show the plain titles.
extension Trigger {
    var chipTitle: String { String(localized: title) }
}

extension Obstacle {
    var chipTitle: String { String(localized: title) }
}

extension FirstUse {
    var chipTitle: String { String(localized: title) }
}

extension NRTType {
    var chipTitle: String {
        switch self {
        case .patch: String(localized: "Patch")
        case .gum: String(localized: "Gum")
        case .lozenge: String(localized: "Lozenge")
        case .inhaler: String(localized: "Spray or inhaler")
        }
    }
}

// MARK: Screens 3–4: baselines

struct BaselineScreen: View {
    @Bindable var model: OnboardingModel
    let product: Product
    @State private var customPrice = false

    private var draft: Binding<BaselineDraft> {
        Binding(get: { model.baseline(for: product) }, set: { model.setBaseline($0, for: product) })
    }

    private var nextTitle: LocalizedStringKey {
        let products = model.orderedProducts
        if let i = products.firstIndex(of: product), i + 1 < products.count {
            return products[i + 1] == .vape ? "Next: your vape" : "Next: \(String(localized: products[i + 1].title).lowercased())"
        }
        return product == .vape ? "Calculate my baseline" : "Continue"
    }

    var body: some View {
        OnboardingScaffold(title: title, subtitle: subtitle, model: model, continueTitle: nextTitle) {
            Group {
                switch product {
                case .cigarettes: cigarettes
                case .vape: vape
                case .pouches: pouches
                }
            }
            .dxArrive(2)
            if let money { money.dxArrive(5) }
        }
        .onAppear {
            // A price typed in a region we have no presets for, or one that isn't a preset, opens the field.
            customPrice = presets.isEmpty || (draft.wrappedValue.price.map { !presets.contains($0) } ?? false)
        }
    }

    // MARK: Per product

    @ViewBuilder private var cigarettes: some View {
        AmountStepper(value: draft.unitsPerDay, step: 1, unitLine: String(localized: "cigarettes a day"))
        VStack(alignment: .leading, spacing: 10) {
            // "Price of a pack of 20": the pack size is a quiet menu on the number (10, 20 or loose).
            Menu {
                ForEach([20.0, 10.0, 1.0], id: \.self) { size in
                    Button(size == 1 ? String(localized: "Loose cigarettes") : String(localized: "Packs of \(Int(size))")) { setPackSize(size) }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(buysSingles ? "Price of one cigarette" : "Price of a pack of \(Int(draft.wrappedValue.unitsPerPurchase))")
                    DXIcon(.down, size: 12, weight: 2.6).opacity(0.6)
                }
                .dxFace(.body, 14, weight: 700)
                .foregroundStyle(Onb.ink)
                .contentShape(Rectangle())
            }
            .accessibilityHint(Text("Changes the pack size"))
            priceChips
        }
        .padding(.top, 8)
    }

    @ViewBuilder private var vape: some View {
        OnboardingSegments(options: [false, true], isSelected: { draft.wrappedValue.byPuffs == $0 },
                           title: { $0 ? String(localized: "By daily puffs") : String(localized: "By pods or disposables") }) {
            draft.wrappedValue.byPuffs = $0
        }
        if draft.wrappedValue.byPuffs {
            AmountStepper(value: draft.unitsPerDay, step: 10, unitLine: String(localized: "puffs a day"))
        } else {
            AmountStepper(value: draft.podsPerWeek, step: VapeUsage.podsStep, unitLine: String(localized: "pods or disposables a week"))
        }
        OnboardingSection(title: "Nicotine strength (check your pod or box)") {
            DXFlowLayout {
                ForEach([9.0, 20, 30, 50], id: \.self) { mg in
                    OnboardingChip(text: Self.vapeStrengthTitle(mg), isOn: draft.wrappedValue.strengthMg == mg) { draft.wrappedValue.strengthMg = mg }
                }
                OnboardingChip(text: String(localized: "Not sure"), isOn: draft.wrappedValue.strengthMg == nil) { draft.wrappedValue.strengthMg = nil }
            }
        }
        OnboardingSection(title: "Price of one") {
            if let vapePreset = PricePresets.vape(currency: model.currencyCode), !customPrice {
                PriceStepper(price: draft.price, step: vapePreset.step, currency: model.currencyCode)
            } else {
                priceField
            }
        }
        OnboardingSection(title: "Puffs in one") {
            OnboardingSegments(options: [600.0, 1500, 5000], isSelected: { draft.wrappedValue.unitsPerPurchase == $0 },
                               title: { $0 == 5000 ? "5,000+" : $0.formatted(.number) }) { draft.wrappedValue.puffsPerPod = $0 }
        }
    }

    @ViewBuilder private var pouches: some View {
        AmountStepper(value: draft.unitsPerDay, step: 1, unitLine: String(localized: "pouches a day"))
        OnboardingSection(title: "Strength") {
            DXFlowLayout {
                ForEach([3.0, 6, 11, 15], id: \.self) { mg in
                    OnboardingChip(text: mg == 15 ? "15+ mg" : "\(Int(mg)) mg", isOn: draft.wrappedValue.strengthMg == mg) { draft.wrappedValue.strengthMg = mg }
                }
                OnboardingChip(text: String(localized: "Not sure"), isOn: draft.wrappedValue.strengthMg == nil) { draft.wrappedValue.strengthMg = nil }
            }
        }
        OnboardingSection(title: "Price of a can") {
            priceChips
            OnboardingSegments(options: [15.0, 20, 24], isSelected: { draft.wrappedValue.unitsPerPurchase == $0 },
                               title: { String(localized: "\(Int($0)) a can") }) { draft.wrappedValue.unitsPerPurchase = $0 }
        }
    }

    // MARK: Price

    private var presets: [Decimal] {
        switch product {
        case .cigarettes: PricePresets.pack(currency: model.currencyCode, size: draft.wrappedValue.unitsPerPurchase)
        case .vape: PricePresets.vape(currency: model.currencyCode).map { [$0.price] } ?? []
        case .pouches: PricePresets.can(currency: model.currencyCode)
        }
    }

    @ViewBuilder private var priceChips: some View {
        if !presets.isEmpty {
            OnboardingSegments(options: presets.map(Optional.some) + [nil],
                               isSelected: { $0 == nil ? customPrice : (!customPrice && draft.wrappedValue.price == $0) },
                               title: { $0.map { $0.formatted(.currency(code: model.currencyCode).precision(.fractionLength(0...2))) } ?? String(localized: "Other") }) { value in
                if let value {
                    customPrice = false
                    draft.wrappedValue.price = value
                } else {
                    customPrice = true
                }
            }
        }
        if customPrice || presets.isEmpty { priceField }
    }

    private var priceField: some View {
        TextField("", value: draft.price, format: .currency(code: model.currencyCode),
                  prompt: Text(Decimal(0), format: .currency(code: model.currencyCode)).foregroundStyle(Onb.muted))
            .keyboardType(.decimalPad)
            .dxType(.body)
            .foregroundStyle(Onb.ink)
            .padding(.horizontal, DX.Space.m)
            .frame(minHeight: 48)
            .background(Onb.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Onb.hairline))
            .accessibilityLabel(Text(priceLabel))
    }

    /// A pack size change keeps the price per cigarette roughly where it was, by moving to the matching preset.
    private func setPackSize(_ size: Double) {
        let old = draft.wrappedValue
        draft.wrappedValue.unitsPerPurchase = size
        let newPresets = PricePresets.pack(currency: model.currencyCode, size: size)
        if !customPrice, let price = old.price, let index = PricePresets.pack(currency: model.currencyCode, size: old.unitsPerPurchase).firstIndex(of: price),
           index < newPresets.count {
            draft.wrappedValue.price = newPresets[index]
        } else if !customPrice, newPresets.count == 3 {
            draft.wrappedValue.price = newPresets[1]
        }
    }

    private var buysSingles: Bool { product == .cigarettes && draft.wrappedValue.unitsPerPurchase == 1 }

    private var priceLabel: LocalizedStringKey {
        switch product {
        case .cigarettes: buysSingles ? "Price of one cigarette" : "Price of a pack"
        case .vape: "Price of one"
        case .pouches: "Price of a can"
        }
    }

    // MARK: Copy

    /// The money card: "At $8 a pack, that's $1,752 a year on cigarettes alone", and the daily cost.
    private var money: BaselineMoneyCard? {
        let d = draft.wrappedValue
        guard let yearly = d.yearlyCost, let price = d.price else { return nil }
        let currency = model.currencyCode
        let each = price.formatted(.currency(code: currency).precision(.fractionLength(0...2)))
        let perDay = yearly / 365
        let whole = NSDecimalNumber(decimal: perDay).doubleValue.rounded() == NSDecimalNumber(decimal: perDay).doubleValue
        let day = perDay.formatted(.currency(code: currency).precision(.fractionLength(whole ? 0 : 2)))
        let lead: String, line: String
        switch product {
        case .cigarettes:
            lead = buysSingles ? String(localized: "At \(each) each, that's") : String(localized: "At \(each) a pack, that's")
            line = String(localized: "a year on cigarettes alone")
        case .vape:
            lead = String(localized: "At \(each) each, that's")
            line = String(localized: "a year on vaping alone")
        case .pouches:
            lead = String(localized: "At \(each) a can, that's")
            line = String(localized: "a year on pouches alone")
        }
        return BaselineMoneyCard(lead: lead, yearly: yearly, yearLine: line, daily: String(localized: "\(day) a day."), currency: currency)
    }

    static func vapeStrengthTitle(_ mg: Double) -> String {
        mg < 20 ? String(localized: "0.6–1.2% · Low") : String(localized: "\(Int(mg / 10))% · \(Int(mg)) mg")
    }

    private var title: LocalizedStringKey {
        switch product {
        case .cigarettes: "How much do you smoke?"
        case .vape: "Tell me about your vape"
        case .pouches: "How many pouches a day?"
        }
    }

    private var subtitle: LocalizedStringKey {
        switch product {
        case .vape: "Vape strength varies up to 5×. This sets your real nicotine load."
        default: "A rough guess is fine. You can change it later."
        }
    }
}

/// The kit stepper card (004): outlined − and + of one weight, the number as a 44 pt display figure that rolls up as it
/// changes, the unit under it. A press reads as a quick fill and a spring bump. VoiceOver adjusts it with swipe up and down.
private struct AmountStepper: View {
    @Binding var value: Double
    let step: Double
    /// What the number counts, e.g. "cigarettes a day" or "pods a week".
    let unitLine: String

    private var valueText: String { value.formatted(.number.precision(.fractionLength(0...1))) }

    var body: some View {
        HStack(spacing: 12) {
            StepperButton(icon: .minus, label: "Fewer") { value = max(step, value - step) }
            VStack(spacing: 0) {
                Text(verbatim: valueText)
                    .dxFace(.display, 44, weight: 800, tracking: -1.2)
                    .monospacedDigit()
                    .foregroundStyle(Onb.ink)
                    .contentTransition(.numericText(value: value))
                    .animation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.32), value: value)
                Text(verbatim: unitLine).dxType(.footnote).foregroundStyle(Onb.muted)
            }
            .frame(maxWidth: .infinity)
            StepperButton(icon: .plus, label: "More") { value += step }
        }
        .padding(.vertical, 24).padding(.horizontal, 16)
        .background(DX.Ground.apricot.card, in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous).strokeBorder(Onb.chipLine, lineWidth: 1))
        .sensoryFeedback(DX.Haptic.select, trigger: value)
        .accessibilityElement()
        .accessibilityLabel(Text("Amount"))
        .accessibilityValue(Text(verbatim: "\(valueText) \(unitLine)"))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value += step
            case .decrement: value = max(step, value - step)
            @unknown default: break
            }
        }
    }
}

/// − or +: 52 pt, outlined with a 2 pt ring at 40% ink; a press fills it briefly and bumps it (520 ms spring).
private struct StepperButton: View {
    let icon: DX.Icon
    let label: LocalizedStringKey
    let action: () -> Void
    @State private var presses = 0
    private let motion = MotionPolicy()

    var body: some View {
        Button {
            presses += 1
            action()
        } label: {
            DXIcon(icon, size: 22)
                .foregroundStyle(Onb.ink)
                .frame(width: 52, height: 52)
                .overlay(Circle().strokeBorder(Onb.ink.opacity(0.4), lineWidth: 2))
                .phaseAnimator([0.0, 1.0, 0.0], trigger: presses) { view, p in
                    view.background(Onb.ink.opacity(0.12 * p), in: Circle())
                        .scaleEffect(motion.reduce ? 1 : 1 + 0.18 * p)
                } animation: { p in
                    p == 1 ? .timingCurve(0.3, 1.4, 0.5, 1, duration: 0.2) : .timingCurve(0.2, 0.7, 0.2, 1, duration: 0.32)
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }
}

/// A price with − and +, for things that have one usual price (a pod or disposable), in the same card.
private struct PriceStepper: View {
    @Binding var price: Decimal?
    let step: Decimal
    let currency: String

    var body: some View {
        HStack(spacing: 12) {
            StepperButton(icon: .minus, label: "Less") { price = max(step, (price ?? step) - step) }
            Text(price ?? 0, format: .currency(code: currency).precision(.fractionLength(0...2)))
                .dxFace(.display, 32, weight: 800, tracking: -1)
                .monospacedDigit()
                .foregroundStyle(Onb.ink)
                .contentTransition(.numericText())
                .frame(maxWidth: .infinity)
            StepperButton(icon: .plus, label: "More") { price = (price ?? 0) + step }
        }
        .padding(.vertical, 16).padding(.horizontal, 16)
        .background(DX.Ground.apricot.card, in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous).strokeBorder(Onb.chipLine, lineWidth: 1))
        .sensoryFeedback(DX.Haptic.select, trigger: price)
        .accessibilityElement()
        .accessibilityLabel(Text("Price of one"))
        .accessibilityValue(Text(price ?? 0, format: .currency(code: currency)))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: price = (price ?? 0) + step
            case .decrement: price = max(step, (price ?? step) - step)
            @unknown default: break
            }
        }
    }
}

// MARK: Screen 5: the baseline in one place

struct BaselineSummaryScreen: View {
    let model: OnboardingModel
    private let motion = MotionPolicy()
    @State private var grown = false
    @State private var landed = false

    private var money: Decimal { model.moneyPerDay * 365 }
    private var total: Int { Int(NicotineEstimate.cigarettes(mg: model.nicotinePerDay).rounded()) }

    /// One part of the total: what a product adds, in cigarettes.
    private struct Part: Identifiable {
        let product: Product
        let cigarettes: Int
        let line: String
        var id: Product { product }
    }

    var body: some View {
        OnboardingScaffold(title: "Your baseline", subtitle: subtitle, trayLabel: nil, model: model) {
            card.dxArrive(2)
            HStack(spacing: 12) {
                XeroView(mood: .calm, stage: 0, points: 60)
                    .dxBob()
                    .frame(width: 60, height: 60)
                    .accessibilityHidden(true)
                Text("Estimates from your answers. Change them any time.")
                    .dxType(.footnote).foregroundStyle(Onb.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 4)
            .padding(.top, 6)
            .dxArrive(3)
        }
        .sensoryFeedback(.impact(weight: .light, intensity: 0.5), trigger: landed) { _, done in done }
        .task {
            try? await Task.sleep(for: .milliseconds(400))
            grown = true
            try? await Task.sleep(for: .milliseconds(750))
            landed = true
        }
    }

    private var subtitle: LocalizedStringKey {
        if model.products.contains(.vape) {
            return model.products.count > 1
                ? "A vape never burns out, so it's easy to underestimate. We'll bring both down together."
                : "A vape never burns out, so it's easy to underestimate."
        }
        return model.products.count > 1 ? "Seeing it in one place is the first step. We'll bring them down together."
            : "Seeing it in one place is the first step."
    }

    /// Each product's share of the total; the first reads as its own count, the rest as "more from".
    private var parts: [Part] {
        var out: [Part] = []
        for product in model.orderedProducts {
            let d = model.baseline(for: product)
            let mg = NicotineEstimate.mgPerDay(product, unitsPerDay: d.unitsPerDay, strength: d.strengthMg)
            let n = Int(NicotineEstimate.cigarettes(mg: mg).rounded())
            let first = out.isEmpty
            let line: String = switch product {
            case .cigarettes:
                first ? String(localized: "cigarettes you smoke") : String(localized: "more from \(Int(d.unitsPerDay)) cigarettes")
            case .vape:
                first ? String(localized: "from about \(Int(d.unitsPerDay.rounded())) vape puffs")
                    : String(localized: "more from about \(Int(d.unitsPerDay.rounded())) vape puffs")
            case .pouches:
                first ? String(localized: "from \(Int(d.unitsPerDay)) pouches") : String(localized: "more from \(Int(d.unitsPerDay)) pouches")
            }
            out.append(Part(product: product, cigarettes: n, line: line))
        }
        return out
    }

    private func color(_ product: Product) -> Color {
        switch product {
        case .cigarettes: Onb.ink
        case .vape: DX.Fill.coral
        case .pouches: Color(hex: 0x3FB37F)
        }
    }

    private var card: some View {
        let g = DX.Ground.apricot
        let parts = parts
        let sum = max(parts.reduce(0) { $0 + $1.cigarettes }, 1)
        return VStack(alignment: .leading, spacing: 0) {
            Text("Your nicotine, counted in cigarettes").dxType(.footnote).foregroundStyle(g.muted)
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                CountingText(Double(total), from: 0, delay: 0.3, duration: 0.85) { "\(Int($0.rounded()))" }
                    .dxFace(.display, 92, weight: 800, tracking: -3)
                    .monospacedDigit()
                    .foregroundStyle(g.ink)
                    .lineLimit(1).minimumScaleFactor(0.5)
                    .padding(.vertical, -10)
                Text("a day").dxType(.title).foregroundStyle(g.ink)
            }
            .padding(.top, 10).padding(.bottom, 22)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(total) cigarettes' worth of nicotine a day"))
            // The split: each product's share, growing left to right in turn.
            GeometryReader { proxy in
                let gaps = CGFloat(max(parts.count - 1, 0)) * 4
                HStack(spacing: 4) {
                    ForEach(Array(parts.enumerated()), id: \.element.id) { i, part in
                        Capsule().fill(color(part.product))
                            .frame(width: max(12, (proxy.size.width - gaps) * CGFloat(part.cigarettes) / CGFloat(sum)))
                            .scaleEffect(x: grown || motion.reduce ? 1 : 0.001, anchor: .leading)
                            .animation(motion.reduce ? nil : DX.Move.settle.speed(0.9 / 0.7).delay(Double(i) * 0.12), value: grown)
                    }
                }
            }
            .frame(height: 12)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(parts.enumerated()), id: \.element.id) { i, part in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Circle().fill(color(part.product)).frame(width: 9, height: 9).offset(y: -1)
                        (Text(verbatim: "\(part.cigarettes)").dxRun(15, weight: 700) + Text(verbatim: " " + part.line))
                            .dxType(.footnote).foregroundStyle(g.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .opacity(grown || motion.reduce ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.5 + Double(i) * 0.12), value: grown)
                }
            }
            .padding(.top, 18)
            HStack(alignment: .top, spacing: 14) {
                costCell(value: money, money: true, line: String(localized: "a year"))
                Rectangle().fill(g.line).frame(width: 1)
                if model.hoursPerYear >= 1 {
                    costCell(value: Decimal(Int(model.hoursPerYear.rounded())), money: false, line: String(localized: "of smoke breaks"))
                } else {
                    costCell(value: money * 5, money: true, line: String(localized: "in 5 years"))
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 18)
            .overlay(alignment: .top) { Rectangle().fill(g.line).frame(height: 1) }
            .padding(.top, 22)
        }
        .padding(.top, 28).padding(.bottom, 24).padding(.horizontal, 22)
        .background(g.card, in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous).strokeBorder(Onb.chipLine, lineWidth: 1))
        .padding(.top, 8)
    }

    private func costCell(value: Decimal, money: Bool, line: String) -> some View {
        let currency = model.currencyCode
        return VStack(alignment: .leading, spacing: 2) {
            CountingText(NSDecimalNumber(decimal: value).doubleValue, from: 0, delay: 0.3, duration: 0.85) { v in
                money ? Decimal(v.rounded()).formatted(.currency(code: currency).precision(.fractionLength(0)))
                    : String(localized: "\(Int(v.rounded())) hours")
            }
            .dxFace(.display, 24, weight: 800, tracking: -0.5)
            .monospacedDigit()
            .foregroundStyle(Onb.ink)
            .lineLimit(1).minimumScaleFactor(0.7)
            Text(verbatim: line).dxType(.footnote).foregroundStyle(Onb.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

// MARK: Screen 6: mornings and triggers

/// v5 (006): moments and feelings as kit chips at natural widths in balanced rows, with Xero's count card.
///
/// Motion (006): question, the two labelled chip groups and the count card arrive in reading order (600 ms, 90 ms
/// stagger). A pick takes the warm tint and outline with a 520 ms spring bump (1.1) and a selection haptic; the count
/// names what's picked.
struct TriggersScreen: View {
    @Bindable var model: OnboardingModel

    private static let moments: [[Trigger]] = [[.morning, .meals, .work], [.coffee, .driving, .alcohol, .evening]]
    private static let feelings: [[Trigger]] = [[.stress, .boredom, .lowMood], [.anxiety, .social, .other]]

    var body: some View {
        OnboardingScaffold(title: "When do cravings hit hardest?",
                           subtitle: "Choose the moments and feelings that set them off. As many as you like.",
                           model: model) {
            group("Moments in your day", Self.moments).dxArrive(2)
            group("Feelings and people", Self.feelings).padding(.top, 6).dxArrive(3)
            HStack(spacing: 12) {
                XeroView(mood: .hello, stage: 0, points: 56)
                    .frame(width: 56, height: 56)
                    .accessibilityHidden(true)
                countLine
                    .dxType(.footnote).foregroundStyle(Onb.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .animation(.easeInOut(duration: 0.25), value: model.triggers)
            }
            .padding(.leading, 10).padding(.trailing, 16).padding(.vertical, 8)
            .background(DX.Ground.apricot.card, in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous).strokeBorder(Onb.chipLine, lineWidth: 1))
            .padding(.top, 4)
            .accessibilityElement(children: .combine)
            .dxArrive(4)
        }
    }

    private func group(_ label: LocalizedStringKey, _ rows: [[Trigger]]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label).dxFace(.body, 14, weight: 600).foregroundStyle(Onb.muted)
            // Hand-balanced rows at natural widths; at large text sizes they wrap instead.
            ViewThatFits(in: .horizontal) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(rows.indices, id: \.self) { r in
                        HStack(spacing: 8) { ForEach(rows[r], id: \.self) { chip($0) } }
                    }
                }
                DXFlowLayout { ForEach(rows.flatMap { $0 }, id: \.self) { chip($0) } }
            }
        }
    }

    private func chip(_ trigger: Trigger) -> some View {
        TriggerChip(text: trigger == .other ? String(localized: "Other") : trigger.chipTitle, isOn: model.triggers.contains(trigger)) {
            if model.triggers.contains(trigger) { model.triggers.remove(trigger) } else { model.triggers.insert(trigger) }
        }
    }

    /// "2 picked. Coffee and stress. I'll check in around them."
    private var countLine: Text {
        let order = (Self.moments + Self.feelings).flatMap { $0 }
        let picked = order.filter(model.triggers.contains).map { $0 == .other ? String(localized: "other moments") : String(localized: $0.title).lowercased() }
        guard !picked.isEmpty else { return Text("Pick any that apply. I'll check in around them.") }
        var names = picked.count <= 3 ? BaselineScreenCopy.list(picked) : String(localized: "\(picked.prefix(2).joined(separator: ", ")) and \(picked.count - 2) more")
        names = names.prefix(1).uppercased() + names.dropFirst()
        return Text("\(picked.count) picked.").dxRun(15, weight: 700) + Text(verbatim: " \(names). ") + Text("I'll check in around them.")
    }
}

/// A trigger chip: the kit chip at its natural width, 48 pt tall with 12 pt sides (006).
private struct TriggerChip: View {
    let text: String
    let isOn: Bool
    let action: () -> Void
    @State private var taps = 0
    @State private var land = 0

    var body: some View {
        Button {
            taps += 1
            if !isOn { land += 1 }
            action()
        } label: {
            OnbChipFace(text: text, isOn: isOn, side: 12, height: 48, land: land)
                .fixedSize()
        }
        .buttonStyle(.dxPress)
        .sensoryFeedback(DX.Haptic.select, trigger: taps)
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
    }
}

/// "a, b and c".
enum BaselineScreenCopy {
    static func list(_ items: [String]) -> String {
        guard items.count > 1 else { return items.first ?? "" }
        return String(localized: "\(items.dropLast().joined(separator: ", ")) and \(items.last ?? "")")
    }
}

// MARK: Screen 7: name and reason

/// v5 (007): the name, the reason in a white field with its own coral focus ring and a count, a paper heart sticker once
/// it's written, and "+" chips that add to it.
struct PersonalScreen: View {
    @Bindable var model: OnboardingModel
    @State private var photoItem: PhotosPickerItem?
    @FocusState private var focus: Field?
    @State private var added = 0

    private enum Field { case name, why }
    static let limit = 120

    /// Starter phrases: the chip, and the sentence it adds.
    private var starters: [(chip: String, sentence: String)] {
        [
            (String(localized: "Save money"), String(localized: "Save money.")),
            (String(localized: "Breathe easier"), String(localized: "Breathe easier.")),
            (String(localized: "More energy"), String(localized: "Have more energy.")),
            (String(localized: "For my family"), String(localized: "Be there for my family.")),
        ]
    }

    var body: some View {
        // "Skip for now" goes on without a name or reason (S27.10); saving stores none, and the app says "you".
        OnboardingScaffold(title: "Make this yours", subtitle: "When a craving hits, I'll show you your reason. It stays on this phone.",
                           model: model, skipTitle: "Skip for now") {
            VStack(alignment: .leading, spacing: 8) {
                label("First name or nickname")
                TextField("", text: $model.name, prompt: Text("Your name").foregroundStyle(Onb.muted))
                    .textContentType(.givenName)
                    .submitLabel(.next)
                    .focused($focus, equals: .name)
                    .onSubmit { focus = .why }
                    .dxFace(.body, 16, weight: 500)
                    .modifier(FieldStyle(focused: focus == .name))
                    .accessibilityLabel(Text("Your name"))
            }
            .padding(.top, 4)
            .dxArrive(2)
            VStack(alignment: .leading, spacing: 8) {
                label(whyTitle).padding(.top, 12)
                ZStack(alignment: .bottomTrailing) {
                    TextField("", text: $model.why.text, prompt: Text("In your own words").foregroundStyle(Onb.muted), axis: .vertical)
                        .lineLimit(2...5)
                        .focused($focus, equals: .why)
                        .dxFace(.body, 17, weight: 600)
                        .padding(.bottom, 16)
                        .modifier(FieldStyle(focused: focus == .why, reason: true))
                        .accessibilityLabel(Text("Why you're quitting"))
                    Text(verbatim: "\(model.why.text.count) / \(Self.limit)")
                        .dxFace(.body, 13, weight: 500).foregroundStyle(Onb.muted)
                        .monospacedDigit()
                        .padding(.trailing, 14).padding(.bottom, 10)
                        .accessibilityHidden(true)
                }
                .overlay(alignment: .topTrailing) {
                    if focus != .why && !model.why.text.trimmingCharacters(in: .whitespaces).isEmpty {
                        PaperHeart()
                            .frame(width: 38, height: 38)
                            .rotationEffect(.degrees(10))
                            .offset(x: 8, y: -14)
                            .transition(.scale(scale: 0.4).combined(with: .opacity))
                            .accessibilityHidden(true)
                    }
                }
                .animation(.timingCurve(0.3, 1.4, 0.5, 1, duration: 0.62), value: focus == .why)
                .onChange(of: model.why.text) { _, text in
                    if text.count > Self.limit { model.why.text = String(text.prefix(Self.limit)) }
                }
            }
            .dxArrive(3)
            VStack(alignment: .leading, spacing: 8) {
                label("Add to your reason").padding(.top, 12)
                DXFlowLayout {
                    ForEach(starters.indices, id: \.self) { index in
                        AddChip(text: starters[index].chip) { add(starters[index].sentence) }
                    }
                }
            }
            .dxArrive(5)
            // Read here: PhotosPicker's label closure isn't on the main actor.
            let photo = model.why.photo
            PhotosPicker(selection: $photoItem, matching: .images) {
                HStack(spacing: 10) {
                    if let data = photo, let image = UIImage(data: data) {
                        Image(uiImage: image).resizable().scaledToFill()
                            .frame(width: 28, height: 28).clipShape(Circle())
                    } else {
                        Image(systemName: "heart").font(.system(size: 16, weight: .semibold)).foregroundStyle(DX.Fill.coral)
                    }
                    Text(photo == nil ? "Add a photo of who it's for" as LocalizedStringKey : "Photo added. Tap to change it")
                        .font(DX.Typeface4.swiftUIFont(.body, size: 15, weight: 600)).foregroundStyle(Onb.ink)
                }
                .frame(minHeight: 44)
            }
            .padding(.top, 4)
            .dxArrive(6)
            .onChange(of: photoItem) { _, item in
                Task {
                    if let item, let data = try? await item.loadTransferable(type: Data.self) { model.why.photo = data }
                }
            }
        }
    }

    private func label(_ text: LocalizedStringKey) -> some View {
        Text(text).dxFace(.body, 14, weight: 700).foregroundStyle(Onb.ink)
    }

    private var whyTitle: LocalizedStringKey {
        let name = model.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Why are you quitting?" : "Why are you quitting, \(name)?"
    }

    /// Appends the sentence to the reason (kept within the limit).
    private func add(_ sentence: String) {
        let text = model.why.text.trimmingCharacters(in: .whitespaces)
        guard !text.contains(sentence) else { return }
        let joined = text.isEmpty ? sentence : "\(text) \(sentence)"
        model.why.text = String(joined.prefix(Self.limit))
    }
}

/// "+ Save money": a kit chip with a coral plus, natural width, 46 pt; a 520 ms spring as it adds.
private struct AddChip: View {
    let text: String
    let action: () -> Void
    @State private var land = 0
    private let motion = MotionPolicy()

    var body: some View {
        Button {
            land += 1
            action()
        } label: {
            HStack(spacing: 6) {
                DXIcon(.plus, size: 16, weight: 2.6).foregroundStyle(DX.Fill.coral)
                Text(verbatim: text).dxFace(.body, 15, weight: 600).foregroundStyle(Onb.ink).lineLimit(1)
            }
            .padding(.leading, 12).padding(.trailing, 14)
            .frame(minHeight: 46)
            .background(DX.Ground.apricot.card, in: RoundedRectangle(cornerRadius: DX.Layout.chipRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DX.Layout.chipRadius, style: .continuous).strokeBorder(Onb.chipLine, lineWidth: 1))
            .phaseAnimator([1.0, 1.1, 1.0], trigger: land) { view, scale in
                view.scaleEffect(motion.reduce ? 1 : scale)
            } animation: { scale in
                scale == 1.1 ? .timingCurve(0.3, 1.4, 0.5, 1, duration: 0.21) : .timingCurve(0.3, 1.4, 0.5, 1, duration: 0.31)
            }
        }
        .buttonStyle(.dxPress)
        .sensoryFeedback(DX.Haptic.select, trigger: land)
        .accessibilityLabel(Text("Add \(text) to your reason"))
    }
}

/// The paper-cut heart sticker on the reason's corner (007).
private struct PaperHeart: View {
    var body: some View {
        ZStack {
            Grid40("M20 34 C11 28.5 5 23 5 15.8 C5 11 8.6 7.5 13 7.5 C16 7.5 18.4 9.2 20 11.4 C21.6 9.2 24 7.5 27 7.5 C31.4 7.5 35 11 35 15.8 C35 23 29 28.5 20 34 Z")
                .fill(DX.Fill.cream)
                .shadow(color: Color(red: 120 / 255, green: 52 / 255, blue: 24 / 255).opacity(0.26), radius: 1, y: 1.6)
            Grid40("M20 30.6 C12.6 26 8.4 21.6 8.4 16 C8.4 12.8 10.8 10.6 13.6 10.6 C16.2 10.6 18.2 12.2 20 15 C21.8 12.2 23.8 10.6 26.4 10.6 C29.2 10.6 31.6 12.8 31.6 16 C31.6 21.6 27.4 26 20 30.6 Z")
                .fill(Color(hex: 0xFF7155))
            Grid40("M12.4 15.4 C12.8 13.8 13.8 13 15.2 12.9")
                .stroke(Color(hex: 0xFFB09C), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
    }
}

private struct Grid40: Shape {
    let d: String
    init(_ d: String) { self.d = d }
    func path(in rect: CGRect) -> Path {
        SVGPath.path(d).applying(CGAffineTransform(scaleX: rect.width / 40, y: rect.height / 40)).offsetBy(dx: rect.minX, dy: rect.minY)
    }
}

/// The kit field on apricot: white with a 1 pt line at 16% ink (the card in dark), radius 16; the reason field takes a
/// 2 pt coral focus ring with a soft halo (never the ink selection outline).
private struct FieldStyle: ViewModifier {
    let focused: Bool
    var reason = false

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        content
            .foregroundStyle(Onb.ink)
            .padding(.horizontal, 16).padding(.vertical, 14)
            .frame(minHeight: 52, alignment: .topLeading)
            .background(Color(light: 0xFFFFFF, dark: 0x182034), in: shape)
            .overlay {
                if focused && reason {
                    shape.strokeBorder(DX.Fill.coral, lineWidth: 2)
                        .background(shape.stroke(DX.Fill.coral.opacity(0.22), lineWidth: 8).padding(-2))
                } else {
                    shape.strokeBorder(Color(light: (0x1E1A3A, 0.16), dark: (0xFFFFFF, 0.12)), lineWidth: focused ? 1.5 : 1)
                }
            }
            .animation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.3), value: focused)
    }
}


// MARK: Screen 8: what gets in the way

/// What tends to get in the way (S27.10). The answers shape the plan (`Obstacle.planLine`).
///
/// v5 (008): the chips in 006's pattern (natural widths, rows of three, three and two), then what each pick adds: one row
/// per pick, the obstacle on the left and the tool on the right; a new row settles in (700 ms) as it's picked.
struct ObstaclesScreen: View {
    @Bindable var model: OnboardingModel
    private let motion = MotionPolicy()

    private static let rows: [[Obstacle]] = [[.irritability, .social, .hunger], [.weight, .sleep, .restlessness], [.focus, .motivation]]

    var body: some View {
        OnboardingScaffold(title: "What usually gets in the way?",
                           subtitle: "Pick any that might trip you up after Quit Day. I'll plan for each.",
                           model: model, skipTitle: "Skip for now") {
            ViewThatFits(in: .horizontal) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Self.rows.indices, id: \.self) { r in
                        HStack(spacing: 8) { ForEach(Self.rows[r], id: \.self) { chip($0) } }
                    }
                }
                DXFlowLayout { ForEach(Self.rows.flatMap { $0 }, id: \.self) { chip($0) } }
            }
            .padding(.top, 2)
            .dxArrive(2)
            let picked = Self.rows.flatMap { $0 }.filter(model.obstacles.contains)
            if !picked.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    (Text("\(picked.count) picked.").dxRun(15, weight: 700).foregroundStyle(Onb.ink) + Text(" Here's what each one adds"))
                        .dxType(.footnote).foregroundStyle(Onb.muted)
                    DXList(on: .apricot) {
                        ForEach(picked, id: \.self) { obstacle in
                            ObstacleRow(obstacle: obstacle)
                                .transition(.asymmetric(insertion: .offset(y: 48).combined(with: .opacity), removal: .opacity))
                        }
                    }
                }
                .padding(.top, 6)
                .transition(.opacity)
                .dxArrive(3)
            }
        }
        .animation(motion.animation(DX.Move.settle.speed(0.9 / 0.7)), value: model.obstacles)
    }

    private func chip(_ obstacle: Obstacle) -> some View {
        TriggerChip(text: String(localized: obstacle.title), isOn: model.obstacles.contains(obstacle)) {
            if model.obstacles.contains(obstacle) { model.obstacles.remove(obstacle) } else { model.obstacles.insert(obstacle) }
        }
    }
}

/// "Irritability → 1-minute reset", with the tool's art in a 40 pt tile.
private struct ObstacleRow: View {
    let obstacle: Obstacle

    var body: some View {
        HStack(spacing: 12) {
            art
                .frame(width: 40, height: 40)
                .background(DX.Ground.apricot.card2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(obstacle.title).dxFace(.body, 15, weight: 500).foregroundStyle(Onb.muted).lineLimit(1)
                Image(systemName: "arrow.right").font(.system(size: 13, weight: .bold)).foregroundStyle(Onb.ink)
                if let tool = obstacle.tool {
                    Text(tool).dxFace(.display, 16, weight: 700, tracking: -0.2).foregroundStyle(Onb.ink).lineLimit(1).minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .frame(minHeight: 64)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var art: some View {
        switch obstacle {
        case .irritability: ToolArt(kind: .reset)
        case .social: ToolArt(kind: .talk)
        default:
            DXIcon(icon, size: 22).foregroundStyle(Onb.ink)
        }
    }

    private var icon: DX.Icon {
        switch obstacle {
        case .hunger: .drop
        case .weight: .leaf
        case .sleep: .moon
        case .restlessness: .hand
        case .focus: .eye
        case .motivation: .heart
        case .cravings: .wave
        case .stress: .sun
        default: .sparkle
        }
    }
}

/// The two paper-cut tool objects from 008, on a 32 × 32 grid: a sun-timer for the reset, two speech bubbles for what to say.
private struct ToolArt: View {
    enum Kind { case reset, talk }
    let kind: Kind
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let shadow = scheme == .dark ? Color.black.opacity(0.55) : Color(red: 120 / 255, green: 52 / 255, blue: 24 / 255).opacity(0.24)
        ZStack {
            switch kind {
            case .reset:
                ZStack {
                    p("M14.3 2 h3.4 a1.8 1.8 0 0 1 1.8 1.8 v.8 a1.8 1.8 0 0 1 -1.8 1.8 h-3.4 a1.8 1.8 0 0 1 -1.8 -1.8 v-.8 a1.8 1.8 0 0 1 1.8 -1.8 z").fill(Color(hex: 0xFF7155))
                    p("M17.8 2 h.3 a1.4 1.4 0 0 1 1.4 1.4 v1.6 a1.4 1.4 0 0 1 -1.4 1.4 h-.3 a1.4 1.4 0 0 1 -1.4 -1.4 v-1.6 a1.4 1.4 0 0 1 1.4 -1.4 z").fill(Color(hex: 0xE85A3E))
                }.shadow(color: shadow, radius: 1, y: 1.6)
                ZStack {
                    p("M16 6.7 a11.8 11.8 0 1 1 0 23.6 a11.8 11.8 0 1 1 0 -23.6 z").fill(Color(hex: 0xFFF8EE))
                    p("M22.5 8.6 A11.8 11.8 0 0 1 16 30.3 A13 13 0 0 0 22.5 8.6 Z").fill(Color(hex: 0xEFE1CF))
                }.shadow(color: shadow, radius: 1, y: 1.6)
                p("M16 18.5 V9.4 A9.1 9.1 0 0 1 24.9 16.6 Z").fill(Color(hex: 0xFFC93C)).shadow(color: shadow, radius: 1, y: 1.6)
                p("M7.6 15 C8.4 12.6 10 10.8 12.2 9.8").stroke(.white, style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                p("M16 16.4 a2.1 2.1 0 1 1 0 4.2 a2.1 2.1 0 1 1 0 -4.2 z").fill(Color(hex: 0x1E1A3A))
            case .talk:
                ZStack {
                    p("M6 5 h14 a4.5 4.5 0 0 1 4.5 4.5 v6 a4.5 4.5 0 0 1 -4.5 4.5 h-8 l-5 4 v-4 h-1 a4.5 4.5 0 0 1 -4.5 -4.5 v-6 a4.5 4.5 0 0 1 4.5 -4.5 z").fill(Color(hex: 0xFF7155))
                    p("M20.5 5.2 a4.5 4.5 0 0 1 4 4.3 v6 a4.5 4.5 0 0 1 -4.5 4.5 h-2 c2.4 -.6 3.6 -2.4 3.6 -4.6 v-6 c0 -1.8 -.4 -3.2 -1.1 -4.2 z").fill(Color(hex: 0xE85A3E))
                    p("M4.6 12 C4.8 9.6 5.8 8.2 7.6 7.6").stroke(Color(hex: 0xFFB09C), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                }.shadow(color: shadow, radius: 1, y: 1.6)
                ZStack {
                    p("M16.5 13 h10 a3.6 3.6 0 0 1 3.6 3.6 v5 a3.6 3.6 0 0 1 -3.6 3.6 h-.8 v3.8 l-4.6 -3.8 h-4.6 a3.6 3.6 0 0 1 -3.6 -3.6 v-5 a3.6 3.6 0 0 1 3.6 -3.6 z").fill(Color(hex: 0xFFF8EE))
                    p("M13 21.6 c.4 2 1.8 3.4 3.8 3.6 h4.4 l1.2 1 h-5.9 a3.6 3.6 0 0 1 -3.5 -3.6 z").fill(Color(hex: 0xEFE1CF))
                }.shadow(color: shadow, radius: 1, y: 1.6)
                ForEach([18.4, 21.6, 24.8], id: \.self) { x in
                    Circle().fill(Color(hex: 0xFF7155)).frame(width: 2.7, height: 2.7).position(x: x, y: 19.2)
                }
            }
        }
        .frame(width: 32, height: 32)
        .scaleEffect(30 / 32)
        .frame(width: 30, height: 30)
        .accessibilityHidden(true)
    }

    private func p(_ d: String) -> Grid32 { Grid32(d: d) }
}

private struct Grid32: Shape {
    let d: String
    func path(in rect: CGRect) -> Path {
        SVGPath.path(d).applying(CGAffineTransform(scaleX: rect.width / 32, y: rect.height / 32)).offsetBy(dx: rect.minX, dy: rect.minY)
    }
}

// MARK: Screen 9: nicotine replacement

/// v5 (009): one short evidence line with a Sources link (the citations open in a sheet), and three option rows. The
/// first shares its card with the product chips, which unfold inside it when it's picked (420 ms settle); picked
/// products fill with a warm tint and a small tick, never a second outline.
struct NRTScreen: View {
    @Bindable var model: OnboardingModel
    private let motion = MotionPolicy()
    @State private var sources = false

    var body: some View {
        OnboardingScaffold(title: "Want to use nicotine replacement?", subtitle: nil, model: model) {
            VStack(alignment: .leading, spacing: 2) {
                Text("It raises your odds of quitting by 50 to 60%. A patch plus a faster form works best.")
                    .dxType(.body).foregroundStyle(Onb.muted)
                    .fixedSize(horizontal: false, vertical: true)
                Button { sources = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle").font(.system(size: 14, weight: .semibold))
                        Text("Sources").underline()
                    }
                    .dxFace(.body, 13, weight: 600)
                    .foregroundStyle(Onb.muted)
                    .frame(minHeight: 32)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Sources: Cochrane reviews, 2018 and 2019"))
            }
            .padding(.top, -14)
            .dxArrive(1)
            usingCard.padding(.top, 8).dxArrive(3)
            OnbOptionCard("I'd like to try it", detail: "I'll help you plan it with a pharmacist", minHeight: 72,
                          isSelected: model.nrtInterest == .wantIt) { model.nrtInterest = .wantIt }
                .dxArrive(4)
            OnbOptionCard("Not for me", detail: "Behavioral prep only", minHeight: 72,
                          isSelected: model.nrtInterest == .notInterested) { model.nrtInterest = .notInterested }
                .dxArrive(5)
            // S27.6: pregnancy changes the advice (behavioural support first; NRT only with a midwife or doctor).
            VStack(alignment: .leading, spacing: 8) {
                Text("Pregnant or breastfeeding?").dxFace(.body, 14, weight: 600).foregroundStyle(Onb.muted)
                HStack(spacing: 8) {
                    ForEach(PregnancyAnswer.allCases, id: \.self) { answer in
                        OnboardingChip(text: answer.chipTitle, isOn: model.pregnancy == answer) { model.setPregnancy(answer) }
                    }
                }
                if model.pregnancy == .yes {
                    Text(verbatim: PregnancyAnswer.caution)
                        .dxType(.footnote).foregroundStyle(Onb.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                }
            }
            .padding(.top, 10)
            .dxArrive(6)
        }
        .animation(motion.animation(DX.Move.settle.speed(0.9 / 0.42)), value: model.nrtInterest)
        .animation(motion.animation(DX.Move.settle), value: model.pregnancy)
        .sheet(isPresented: $sources) { NRTSourcesSheet().presentationDetents([.medium]) }
    }

    /// "Yes, I'm already using it" and its product chips share one card; picked, the whole card takes the selection.
    private var usingCard: some View {
        let g = DX.Ground.apricot
        let on = model.nrtInterest == .using
        let shape = RoundedRectangle(cornerRadius: DX.Layout.optionRadius, style: .continuous)
        return VStack(alignment: .leading, spacing: 0) {
            Button { model.nrtInterest = .using } label: {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Yes, I'm already using it").dxFace(.display, 17, weight: 700).foregroundStyle(Onb.ink)
                        Text("Pick all you use").dxType(.footnote).foregroundStyle(Onb.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    DXRadio(isOn: on, ground: g)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .frame(minHeight: 72)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .sensoryFeedback(DX.Haptic.select, trigger: on)
            .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
            if on {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    ForEach(NRTType.allCases, id: \.self) { type in
                        NRTFormatChip(text: type.chipTitle, isOn: model.nrtFormats.contains(type)) {
                            if model.nrtFormats.contains(type) { model.nrtFormats.remove(type) } else { model.nrtFormats.insert(type) }
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 16)
                .transition(.opacity)
            }
        }
        .background(on ? g.selTint : g.card, in: shape)
        .overlay(shape.strokeBorder(on ? g.selEdge : g.line, lineWidth: on ? 2 : 1))
        .clipShape(shape)
        .animation(DX.Move.arrive.speed(2.4), value: on)
    }
}

/// A nested pick inside the selected card: a filled warm tint and a small tick, no outline.
private struct NRTFormatChip: View {
    let text: String
    let isOn: Bool
    let action: () -> Void
    @State private var taps = 0

    var body: some View {
        let g = DX.Ground.apricot
        let shape = RoundedRectangle(cornerRadius: DX.Layout.chipRadius, style: .continuous)
        Button {
            taps += 1
            action()
        } label: {
            HStack(spacing: 6) {
                if isOn { DXIcon(.check, size: 16, weight: 3).padding(.leading, -4) }
                Text(verbatim: text).lineLimit(1).minimumScaleFactor(0.8)
            }
            .dxFace(.body, 15, weight: isOn ? 700 : 600)
            .foregroundStyle(g.ink)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(isOn ? Color(light: 0xFFC4A0, dark: 0x3A3A44) : g.card, in: shape)
            .overlay { if !isOn { shape.strokeBorder(g.line, lineWidth: 1) } }
            .animation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.25), value: isOn)
        }
        .buttonStyle(.dxPress)
        .sensoryFeedback(DX.Haptic.select, trigger: taps)
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
    }
}

/// The citations behind 009's line, and the note about stop-smoking medicines.
private struct NRTSourcesSheet: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Sources").dxType(.title).foregroundStyle(Onb.ink).padding(.top, 28)
            ForEach([HealthSources.nrtCochrane2018, HealthSources.nrtCombinationCochrane2019], id: \.url) { source in
                Link(destination: source.url) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "doc.text").foregroundStyle(Onb.muted)
                        Text(source.label).dxType(.footnote).underline().foregroundStyle(Onb.ink).multilineTextAlignment(.leading)
                    }
                }
            }
            Text("Always follow the product label. Stop-smoking medicines such as varenicline or cytisine help too: ask a pharmacist or doctor what suits you.")
                .dxType(.footnote).foregroundStyle(Onb.muted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal, DX.Layout.gutter)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dxGround(.apricot)
    }
}
