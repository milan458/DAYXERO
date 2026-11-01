import DayXeroCore
import PhotosUI
import SwiftUI

// MARK: Shared pieces

/// A section label above a group of controls.
struct OnboardingSection<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).onbText(.micro)
            content()
        }
        .padding(.top, DX.Space.s)
    }
}

/// Equal-width chips in a row: one choice from a few (S22). v4 answer chips: 48 pt, radius 14.
struct OnboardingSegments<Value: Hashable>: View {
    let options: [Value]
    let isSelected: (Value) -> Bool
    let title: (Value) -> String
    let select: (Value) -> Void

    var body: some View {
        HStack(spacing: DX.Space.xs) {
            ForEach(options, id: \.self) { option in
                let on = isSelected(option)
                Button { select(option) } label: {
                    Text(verbatim: title(option))
                        .dxFont(14, weight: on ? 700 : 500, style: .subheadline)
                        .foregroundStyle(on ? Onb.onInk : Onb.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(on ? Onb.ink : Onb.surface,
                                    in: RoundedRectangle(cornerRadius: DX.Layout.answerChipRadius, style: .continuous))
                }
                .buttonStyle(.plain)
                .sensoryFeedback(DX.Haptic.select, trigger: on)
                .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
            }
        }
    }
}

/// A v4 answer chip (no emoji): 48 pt tall, radius 14, ink when chosen.
struct OnboardingChip: View {
    let text: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(verbatim: text)
                .dxFont(14, weight: isOn ? 700 : 500, style: .subheadline)
                .foregroundStyle(isOn ? Onb.onInk : Onb.ink)
                .padding(.horizontal, 16)
                .frame(minHeight: 48)
                .background(isOn ? Onb.ink : Onb.surface,
                            in: RoundedRectangle(cornerRadius: DX.Layout.answerChipRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(DX.Haptic.select, trigger: isOn)
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
    }
}

/// A one-line summary of money and nicotine as the numbers change.
struct LiveSummary: View {
    let systemImage: String
    let text: String

    var body: some View {
        Label {
            Text(verbatim: text).dxFont(14, weight: 600, style: .footnote)
        } icon: {
            Image(systemName: systemImage).font(.system(size: 14, weight: .semibold))
        }
        .foregroundStyle(Onb.accent)
        .padding(.vertical, 12).padding(.horizontal, DX.Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Onb.accentSoft, in: RoundedRectangle(cornerRadius: DX.Layout.answerChipRadius, style: .continuous))
        .contentTransition(.numericText())
        .padding(.top, DX.Space.s)
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

    private var position: (Int, Int) {
        let products = model.orderedProducts
        return ((products.firstIndex(of: product) ?? 0) + 1, products.count)
    }

    private var nextTitle: LocalizedStringKey {
        let products = model.orderedProducts
        if let i = products.firstIndex(of: product), i + 1 < products.count {
            return products[i + 1] == .vape ? "Next: your vape" : "Next: \(String(localized: products[i + 1].title).lowercased())"
        }
        return product == .vape ? "Calculate my baseline" : "Continue"
    }

    var body: some View {
        OnboardingScaffold(title: title, subtitle: subtitle, eyebrow: eyebrow, model: model, continueTitle: nextTitle) {
            switch product {
            case .cigarettes: cigarettes
            case .vape: vape
            case .pouches: pouches
            }
            years
            if let summary { LiveSummary(systemImage: "creditcard", text: summary) }
        }
        .onAppear {
            // A price typed in a region we have no presets for, or one that isn't a preset, opens the field.
            customPrice = presets.isEmpty || (draft.wrappedValue.price.map { !presets.contains($0) } ?? false)
        }
    }

    // MARK: Per product

    @ViewBuilder private var cigarettes: some View {
        AmountStepper(value: draft.unitsPerDay, step: 1, unitLine: String(localized: "cigarettes a day"))
        OnboardingSection(title: buysSingles ? "Price of one cigarette" : "Pack price and size") {
            priceChips
            OnboardingSegments(options: [10.0, 20.0, 1.0], isSelected: { draft.wrappedValue.unitsPerPurchase == $0 },
                               title: { $0 == 1 ? String(localized: "Loose") : String(localized: "\(Int($0)) pack") }) { size in
                setPackSize(size)
            }
        }
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

    private var years: some View {
        OnboardingSection(title: yearsLabel) {
            OnboardingSegments(options: YearsOfUse.allCases, isSelected: { draft.wrappedValue.years == $0 },
                               title: { String(localized: $0.title) }) { draft.wrappedValue.years = $0 }
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
                               title: { $0.map { $0.formatted(.currency(code: model.currencyCode).precision(.fractionLength(0...2))) } ?? String(localized: "Custom") }) { value in
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

    /// "₹91,250 a year · about 12 mg nicotine a day".
    private var summary: String? {
        let d = draft.wrappedValue
        guard let yearly = d.yearlyCost else { return nil }
        let money = yearly.formatted(.currency(code: model.currencyCode).precision(.fractionLength(0)))
        let mg = Int(NicotineEstimate.mgPerDay(product, unitsPerDay: d.unitsPerDay, strength: d.strengthMg).rounded())
        return String(localized: "\(money) a year · about \(mg) mg nicotine a day")
    }

    static func vapeStrengthTitle(_ mg: Double) -> String {
        mg < 20 ? String(localized: "0.6–1.2% · Low") : String(localized: "\(Int(mg / 10))% · \(Int(mg)) mg")
    }

    private var eyebrow: LocalizedStringKey {
        let (index, count) = position
        let name = String(localized: product.title)
        return count > 1 ? "\(name) · step \(index) of \(count)" : "\(name)"
    }

    private var title: LocalizedStringKey {
        switch product {
        case .cigarettes: "How much do you smoke?"
        case .vape: "Tell us about your vape"
        case .pouches: "How many pouches a day?"
        }
    }

    private var subtitle: LocalizedStringKey {
        switch product {
        case .vape: "Vape strength varies up to 5×. This sets your real nicotine load."
        default: "A rough estimate is fine, with zero judgement. You can change it any time."
        }
    }

    private var yearsLabel: LocalizedStringKey {
        switch product {
        case .cigarettes: "How long have you smoked?"
        case .vape: "How long have you vaped?"
        case .pouches: "How long have you used pouches?"
        }
    }
}

/// Big centred number with − and + buttons. VoiceOver adjusts it with swipe up and down.
private struct AmountStepper: View {
    @Binding var value: Double
    let step: Double
    /// What the number counts, e.g. "cigarettes a day" or "pods a week".
    let unitLine: String

    private var valueText: String { value.formatted(.number.precision(.fractionLength(0...1))) }

    var body: some View {
        HStack {
            button("minus", primary: false) { value = max(step, value - step) }
            Spacer()
            VStack(spacing: 0) {
                Text(verbatim: valueText).onbText(.hero).contentTransition(.numericText())
                Text(verbatim: unitLine).dxFont(13, weight: 400, style: .caption1).foregroundStyle(Onb.muted)
            }
            Spacer()
            button("plus", primary: true) { value += step }
        }
        .padding(DX.Space.m)
        .background(Onb.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Onb.hairline))
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

    private func button(_ symbol: String, primary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 17, weight: .semibold))
                .frame(width: 48, height: 48)
                .background(primary ? Onb.ink : Onb.surface, in: Circle())
                .overlay(Circle().strokeBorder(primary ? .clear : Onb.hairline))
                .foregroundStyle(primary ? Onb.onInk : Onb.ink)
        }
        .buttonStyle(.plain)
    }
}

/// A price with − and +, for things that have one usual price (a pod or disposable).
private struct PriceStepper: View {
    @Binding var price: Decimal?
    let step: Decimal
    let currency: String

    var body: some View {
        HStack {
            round("minus", primary: false) { price = max(step, (price ?? step) - step) }
            Spacer()
            Text(price ?? 0, format: .currency(code: currency).precision(.fractionLength(0...2)))
                .dxFont(24, weight: 700, style: .title2)
                .foregroundStyle(Onb.ink)
                .contentTransition(.numericText())
            Spacer()
            round("plus", primary: true) { price = (price ?? 0) + step }
        }
        .padding(DX.Space.s)
        .background(Onb.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Onb.hairline))
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

    private func round(_ symbol: String, primary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 15, weight: .semibold))
                .frame(width: 40, height: 40)
                .background(primary ? Onb.ink : Onb.surface, in: Circle())
                .foregroundStyle(primary ? Onb.onInk : Onb.ink)
        }
        .buttonStyle(.plain)
    }
}

// MARK: Screen 5: the baseline in one place

struct BaselineSummaryScreen: View {
    let model: OnboardingModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var money: Decimal { model.moneyPerDay * 365 }
    private var cigarettes: Double { NicotineEstimate.cigarettes(mg: model.nicotinePerDay) }

    var body: some View {
        OnboardingScaffold(title: "Here's what your body processes every day",
                           subtitle: model.products.contains(.vape)
                               ? "Most people underestimate vaping, because a vape never burns out like a cigarette."
                               : "Seeing it in one place is the first step.",
                           eyebrow: "Your baseline", trayLabel: nil, model: model) {
            hero
            HStack(spacing: DX.Space.s) {
                tile(systemImage: "creditcard", label: "Yours to keep",
                     value: money.formatted(.currency(code: model.currencyCode).precision(.fractionLength(0))),
                     detail: String(localized: "\(model.moneyPerDay.formatted(.currency(code: model.currencyCode).precision(.fractionLength(0)))) a day, every year"))
                if model.hoursPerYear >= 1 {
                    tile(systemImage: "hourglass", label: "Time you'll get back",
                         value: String(localized: "\(Int(model.hoursPerYear.rounded())) hours"),
                         detail: String(localized: "\(Int((model.hoursPerYear / 24).rounded())) full days a year"))
                } else {
                    tile(systemImage: "calendar", label: "In 5 years",
                         value: (money * 5).formatted(.currency(code: model.currencyCode).precision(.fractionLength(0))),
                         detail: String(localized: "At today's prices"))
                }
            }
            HStack(alignment: .top, spacing: DX.Space.s) {
                Image(systemName: "calendar").font(.system(size: 16, weight: .light)).foregroundStyle(Onb.accent)
                Text("Nothing changes yet. In prep week you use as normal while you learn the skills, then you stop on your Quit Day.")
                    .onbText(.subtitle).fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Onb.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Onb.hairline))
            Text("Rough estimates for comparison, from about 1 mg of nicotine absorbed per cigarette (Benowitz and Jacob, 1984). Real intake varies with your product and how you use it.")
                .dxFont(11, weight: 400, style: .caption2).foregroundStyle(Onb.muted)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: DX.Space.s) {
            Text("Total daily nicotine load").onbText(.micro)
            HStack(alignment: .firstTextBaseline, spacing: DX.Space.xs) {
                Text(verbatim: "≈ \(Int(cigarettes.rounded()))")
                    .dxFont(48, weight: 800, style: .largeTitle).tracking(-1.4)
                    .foregroundStyle(Onb.accent)
                Text(cigarettes.rounded() == 1 ? "cigarette a day" as LocalizedStringKey : "cigarettes a day")
                    .dxFont(17, weight: 500, style: .headline).foregroundStyle(.white)
            }
            .accessibilityElement(children: .combine)
            ForEach(model.orderedProducts, id: \.self) { product in
                let d = model.baseline(for: product)
                let mg = NicotineEstimate.mgPerDay(product, unitsPerDay: d.unitsPerDay, strength: d.strengthMg)
                HStack(spacing: DX.Space.s) {
                    Image(systemName: icon(product)).font(.system(size: 16, weight: .light)).foregroundStyle(Onb.accent)
                        .frame(width: 36, height: 36).background(Color.white.opacity(0.1), in: Circle())
                    VStack(alignment: .leading, spacing: 1) {
                        Text(verbatim: line(product, d)).dxFont(14, weight: 600, style: .subheadline).foregroundStyle(.white)
                        Text(verbatim: product == .cigarettes
                             ? String(localized: "About \(Int(mg.rounded())) mg nicotine absorbed")
                             : String(localized: "About \(Int(NicotineEstimate.cigarettes(mg: mg).rounded())) cigarettes’ worth of nicotine"))
                            .dxFont(12, weight: 400, style: .caption1).foregroundStyle(.white.opacity(0.6))
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(DX.Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DX.Fill.navy, in: RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
        // Navy in both themes, so its colours resolve as dark.
        .environment(\.colorScheme, .dark)
    }

    private func line(_ product: Product, _ d: BaselineDraft) -> String {
        switch product {
        case .cigarettes: return String(localized: "\(Int(d.unitsPerDay)) cigarettes")
        case .vape:
            let puffs = Int(d.unitsPerDay.rounded())
            guard let mg = d.strengthMg else { return String(localized: "~\(puffs) vape puffs") }
            return String(localized: "~\(puffs) vape puffs at \(BaselineScreen.vapeStrengthTitle(mg).components(separatedBy: " · ").first ?? "")")
        case .pouches:
            return d.strengthMg.map { String(localized: "\(Int(d.unitsPerDay)) pouches at \(Int($0)) mg") } ?? String(localized: "\(Int(d.unitsPerDay)) pouches")
        }
    }

    private func icon(_ product: Product) -> String {
        switch product {
        case .cigarettes: "smoke"
        case .vape: "wind"
        case .pouches: "capsule"
        }
    }

    private func tile(systemImage: String, label: LocalizedStringKey, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: systemImage).font(.system(size: 14, weight: .light)).foregroundStyle(Onb.accent)
                .frame(width: 32, height: 32).background(Onb.accentSoft, in: Circle())
            Text(label).onbText(.micro)
            Text(verbatim: value).dxFont(22, weight: 700, style: .title2).foregroundStyle(Onb.ink)
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(verbatim: detail).dxFont(12, weight: 400, style: .caption1).foregroundStyle(Onb.muted)
        }
        .padding(DX.Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Onb.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Onb.hairline))
        .accessibilityElement(children: .combine)
    }
}

// MARK: Screen 6: mornings and triggers

struct TriggersScreen: View {
    @Bindable var model: OnboardingModel

    var body: some View {
        OnboardingScaffold(title: "When do cravings hit hardest?",
                           subtitle: "We'll time your prep check-ins and defences around your biggest moments.",
                           model: model) {
            OnboardingSection(title: "How soon after waking do you first use?") {
                VStack(spacing: DX.Space.xs) {
                    OnboardingSegments(options: [FirstUse.withinFive, .withinThirty], isSelected: { model.firstUse == $0 },
                                       title: \.chipTitle) { model.firstUse = $0 }
                    OnboardingSegments(options: [FirstUse.withinHour, .later], isSelected: { model.firstUse == $0 },
                                       title: \.chipTitle) { model.firstUse = $0 }
                }
            }
            OnboardingSection(title: "What sets you off? Pick any that apply") {
                DXFlowLayout {
                    ForEach(Trigger.allCases, id: \.self) { trigger in
                        OnboardingChip(text: trigger.chipTitle, isOn: model.triggers.contains(trigger)) {
                            if model.triggers.contains(trigger) { model.triggers.remove(trigger) } else { model.triggers.insert(trigger) }
                        }
                    }
                }
            }
            if model.firstUse?.isEarly == true {
                Label("Using within 30 minutes of waking is a strong sign of dependence. We plan your mornings first.", systemImage: "clock")
                    .dxType(.footnote).foregroundStyle(Onb.muted)
                    .padding(.top, DX.Space.s)
            }
        }
    }
}

// MARK: Screen 7: name and reason

struct PersonalScreen: View {
    @Bindable var model: OnboardingModel
    @State private var photoItem: PhotosPickerItem?
    @FocusState private var focus: Field?

    private enum Field { case name, why }

    /// Starter phrases: the chip, and the sentence it adds.
    private var starters: [(chip: String, sentence: String)] {
        let yearly = model.moneyPerDay * 365
        let money = yearly.formatted(.currency(code: model.currencyCode).precision(.fractionLength(0)).notation(.compactName))
        return [
            (String(localized: "Save \(money) a year"), String(localized: "Keep the \(money) a year I spend on nicotine.")),
            (String(localized: "Breathe easier"), String(localized: "Breathe easier.")),
            (String(localized: "Be there for family"), String(localized: "Be there for my family.")),
            (String(localized: "More energy"), String(localized: "Have more energy every day.")),
            (String(localized: "Break the chain"), String(localized: "Stop planning my day around nicotine.")),
        ]
    }

    var body: some View {
        OnboardingScaffold(title: "Make this personal", subtitle: "Your name and your reason. Both stay on this phone.",
                           model: model, continueTitle: "Save my reason") {
            OnboardingSection(title: "First name or nickname") {
                TextField("", text: $model.name, prompt: Text("Your name").foregroundStyle(Onb.muted))
                    .textContentType(.givenName)
                    .submitLabel(.next)
                    .focused($focus, equals: .name)
                    .onSubmit { focus = .why }
                    .modifier(FieldStyle(focused: focus == .name))
                    .accessibilityLabel(Text("Your name"))
            }
            OnboardingSection(title: whyTitle) {
                TextField("", text: $model.why.text, prompt: Text("Write it in your own words, or tap a reason below").foregroundStyle(Onb.muted),
                          axis: .vertical)
                    .lineLimit(3...6)
                    .focused($focus, equals: .why)
                    .modifier(FieldStyle(focused: focus == .why, minHeight: 96))
                    .accessibilityLabel(Text("Why you're quitting"))
                Text("When a craving hits, we'll show you this.").dxFont(12, weight: 400, style: .caption1)
                    .foregroundStyle(Onb.muted)
            }
            OnboardingSection(title: "Tap to add to your reason") {
                DXFlowLayout {
                    ForEach(starters.indices, id: \.self) { index in
                        let starter = starters[index]
                        OnboardingChip(text: starter.chip, isOn: model.why.text.contains(starter.sentence)) { toggle(starter.sentence) }
                    }
                }
            }
            // Read here: PhotosPicker's label closure isn't on the main actor.
            let photo = model.why.photo
            PhotosPicker(selection: $photoItem, matching: .images) {
                HStack(spacing: DX.Space.s) {
                    if let data = photo, let image = UIImage(data: data) {
                        Image(uiImage: image).resizable().scaledToFill()
                            .frame(width: 40, height: 40).clipShape(Circle())
                    } else {
                        Image(systemName: "camera").font(.system(size: 16, weight: .light)).foregroundStyle(Onb.accent)
                            .frame(width: 40, height: 40).background(Onb.accentSoft, in: Circle())
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(photo == nil ? "Add a photo of who you're doing this for" as LocalizedStringKey : "Photo added. Tap to change it")
                            .font(DX.Typeface4.swiftUIFont(.body, size: 14, weight: 600)).foregroundStyle(Onb.ink)
                        Text("Optional · stays on this phone").font(DX.Typeface4.swiftUIFont(.body, size: 12, weight: 400))
                            .foregroundStyle(Onb.muted)
                    }
                    .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                }
                .padding(14)
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Onb.muted, style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
            }
            .padding(.top, DX.Space.s)
            .onChange(of: photoItem) { _, item in
                Task {
                    if let item, let data = try? await item.loadTransferable(type: Data.self) { model.why.photo = data }
                }
            }
        }
    }

    private var whyTitle: LocalizedStringKey {
        let name = model.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Why are you quitting?" : "Why are you quitting, \(name)?"
    }

    private func toggle(_ sentence: String) {
        var text = model.why.text
        if text.contains(sentence) {
            text = text.replacingOccurrences(of: sentence, with: "").replacingOccurrences(of: "  ", with: " ")
        } else {
            text = text.trimmingCharacters(in: .whitespaces).isEmpty ? sentence : "\(text.trimmingCharacters(in: .whitespaces)) \(sentence)"
        }
        model.why.text = text.trimmingCharacters(in: .whitespaces)
    }
}

private struct FieldStyle: ViewModifier {
    let focused: Bool
    var minHeight: CGFloat = 52

    func body(content: Content) -> some View {
        content
            .dxType(.body)
            .foregroundStyle(Onb.ink)
            .padding(.horizontal, 18).padding(.vertical, 14)
            .frame(minHeight: minHeight, alignment: .topLeading)
            .background(Onb.surface, in: RoundedRectangle(cornerRadius: DX.Layout.answerChipRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DX.Layout.answerChipRadius, style: .continuous)
                .strokeBorder(focused ? Onb.accent : Onb.hairline, lineWidth: focused ? 1.5 : 1))
    }
}

// MARK: Screen 8: past attempts and confidence

struct PastAttemptsScreen: View {
    @Bindable var model: OnboardingModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        OnboardingScaffold(title: "Have you tried to quit before?",
                           subtitle: "Every attempt is data, not failure. Tell us what tripped you up so we can block it this time.",
                           model: model) {
            OnboardingSection(title: "Past attempts") {
                OnboardingSegments(options: PastAttempts.allCases, isSelected: { model.pastAttempts == $0 },
                                   title: { $0 == .notYet ? String(localized: "First time") : String(localized: $0.title) }) {
                    model.pastAttempts = $0
                    if $0 == .notYet { model.obstacles = [] }
                }
            }
            if model.pastAttempts != nil, model.pastAttempts != .notYet {
                OnboardingSection(title: "What got in the way most?") {
                    DXFlowLayout {
                        ForEach(Obstacle.allCases, id: \.self) { obstacle in
                            OnboardingChip(text: obstacle.chipTitle, isOn: model.obstacles.contains(obstacle)) {
                                if model.obstacles.contains(obstacle) { model.obstacles.remove(obstacle) } else { model.obstacles.insert(obstacle) }
                            }
                        }
                    }
                }
                .transition(.opacity)
            }
            OnboardingSection(title: "How confident do you feel right now?") {
                Slider(value: $model.confidence, in: 0...10, step: 1)
                    .tint(Onb.accent)
                    .sensoryFeedback(DX.Haptic.select, trigger: model.confidence)
                    .accessibilityLabel(Text("Confidence"))
                    .accessibilityValue(Text("\(Int(model.confidence)) out of 10"))
                HStack {
                    Text("Nervous · 0")
                    Spacer()
                    Text("Ready · 10")
                }
                .dxFont(12, weight: 400, style: .caption1).foregroundStyle(Onb.muted)
                .accessibilityHidden(true)
                HStack(spacing: 10) {
                    Text(verbatim: "\(Int(model.confidence))/10")
                        .dxFont(15, weight: 700, style: .subheadline).foregroundStyle(Onb.accent)
                        .contentTransition(.numericText())
                    Text(feedback).dxType(.footnote).foregroundStyle(Onb.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 12).padding(.horizontal, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Onb.accentSoft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .accessibilityElement(children: .combine)
            }
        }
        .animation(DX.Move.animation(DX.Move.settle, reduceMotion: reduceMotion), value: model.pastAttempts)
    }

    private var feedback: LocalizedStringKey {
        switch model.confidence {
        case ..<4: "Nervous is normal. Prep is built for exactly this."
        case ..<7: "Totally normal. That's why we prepare first."
        default: "Great. Prep turns that into a plan."
        }
    }
}

// MARK: Screen 9: nicotine replacement

struct NRTScreen: View {
    @Bindable var model: OnboardingModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        OnboardingScaffold(title: "Want to use nicotine replacement?",
                           subtitle: "Patches, gum and lozenges make quitting more likely by smoothing out physical withdrawal.") {
            Link(destination: HealthSources.nrtCochrane2018.url) {
                Label {
                    Text(HealthSources.nrtCochrane2018.label)
                } icon: {
                    Image(systemName: "doc.text").font(.system(size: 12, weight: .light))
                }
                .dxFont(12, weight: 500, style: .caption1)
                .foregroundStyle(Onb.muted)
                .padding(.vertical, 6).padding(.horizontal, 12)
                .background(Onb.surface, in: Capsule())
                .overlay(Capsule().strokeBorder(Onb.hairline))
            }
            .accessibilityHint(Text("Opens the study summary"))
            VStack(alignment: .leading, spacing: 0) {
                OnbOptionCard("Yes, I'm already using it", detail: model.nrtInterest == .using ? "Tell us what you use" : nil,
                             isSelected: model.nrtInterest == .using) { model.nrtInterest = .using }
                if model.nrtInterest == .using {
                    DXFlowLayout {
                        ForEach(NRTType.allCases, id: \.self) { type in
                            OnboardingChip(text: type.chipTitle, isOn: model.nrtFormats.contains(type)) {
                                if model.nrtFormats.contains(type) { model.nrtFormats.remove(type) } else { model.nrtFormats.insert(type) }
                            }
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.top, 10)
                    .transition(.opacity)
                }
            }
            OnbOptionCard("I'd like to try it", detail: "We'll suggest talking to a pharmacist", isSelected: model.nrtInterest == .wantIt) {
                model.nrtInterest = .wantIt
            }
            OnbOptionCard("Not for me", detail: "Behavioural prep only", isSelected: model.nrtInterest == .notInterested) {
                model.nrtInterest = .notInterested
            }
            Text("Always follow the product label, and check with a pharmacist or doctor.")
                .dxFont(12, weight: 400, style: .caption1).foregroundStyle(Onb.muted)
                .padding(.top, DX.Space.xs)
        } footer: {
            ContinueButton(title: "Continue", model: model)
        }
        .animation(DX.Move.animation(DX.Move.settle, reduceMotion: reduceMotion), value: model.nrtInterest)
    }
}
