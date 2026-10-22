import DayXeroCore
import PhotosUI
import SwiftUI

struct BaselineScreen: View {
    @Bindable var model: OnboardingModel
    let product: Product

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
            return "Next: \(String(localized: products[i + 1].title).lowercased())"
        }
        return "Continue"
    }

    var body: some View {
        OnboardingScaffold(title: title, subtitle: "A rough guess is fine. You can change it later.",
                           eyebrow: eyebrow, model: model, continueTitle: nextTitle) {
            AmountStepper(value: draft.unitsPerDay, step: step, product: product)

            if product == .pouches {
                Text("Strength").dxText(.micro).padding(.top, DX.Space.xs)
                DXFlowLayout {
                    ForEach([3.0, 6.0, 11.0, 15.0], id: \.self) { mg in
                        strengthChip(mg == 15 ? "15+ mg" : "\(Int(mg)) mg", value: mg)
                    }
                    strengthChip("Not sure", value: nil)
                }
            }

            HStack(alignment: .top, spacing: DX.Space.xs) {
                LabeledField(label: "Price") {
                    TextField("", value: draft.price, format: .currency(code: model.currencyCode),
                              prompt: Text(Decimal(0), format: .currency(code: model.currencyCode)).foregroundStyle(DX.Palette.faint))
                        .keyboardType(.decimalPad)
                }
                LabeledField(label: perPurchaseLabel) {
                    HStack {
                        TextField("", value: draft.unitsPerPurchase, format: .number)
                            .keyboardType(.numberPad)
                        Text(purchaseUnit).dxText(.subtitle)
                    }
                }
            }
            .padding(.top, DX.Space.xs)
            if let price = draft.wrappedValue.price, price <= 0 {
                Text("Add what one costs so we can show the money you keep.")
                    .font(DX.TextStyle.subtitle.font)
                    .foregroundStyle(DX.Palette.terracotta)
            }

            Text(yearsLabel).dxText(.micro).padding(.top, DX.Space.xs)
            DXFlowLayout {
                ForEach(YearsOfUse.allCases) { years in
                    DXChip(LocalizedStringKey(String(localized: years.title)), isOn: Binding(
                        get: { draft.wrappedValue.years == years },
                        set: { if $0 { draft.wrappedValue.years = years } }
                    ))
                }
            }
        }
    }

    private var eyebrow: LocalizedStringKey {
        let (index, count) = position
        let name = String(localized: product.title)
        return count > 1 ? "\(name) · \(index) of \(count)" : "\(name)"
    }

    private func strengthChip(_ title: LocalizedStringKey, value: Double?) -> some View {
        DXChip(title, isOn: Binding(
            get: { draft.wrappedValue.strengthMg == value },
            set: { if $0 { draft.wrappedValue.strengthMg = value } }
        ))
    }

    private var title: LocalizedStringKey {
        switch product {
        case .cigarettes: "How many cigarettes a day?"
        case .vape: "How much do you vape a day?"
        case .pouches: "How many pouches a day?"
        }
    }

    private var step: Double {
        product == .vape ? 10 : 1
    }

    private var perPurchaseLabel: LocalizedStringKey {
        switch product {
        case .cigarettes: "Cigarettes in a pack"
        case .vape: "Puffs in one"
        case .pouches: "Pouches in a can"
        }
    }

    private var purchaseUnit: LocalizedStringKey {
        switch product {
        case .cigarettes: "per pack"
        case .vape: "per pod"
        case .pouches: "per can"
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
    let product: Product

    private var unitLine: String {
        String(localized: "\(String(localized: product.unit)) a day")
    }

    var body: some View {
        HStack {
            button("minus") { value = max(step, value - step) }
            Spacer()
            VStack(spacing: 0) {
                Text(Int(value), format: .number).dxText(.hero).contentTransition(.numericText())
                Text(unitLine).font(.custom(DX.Typeface.medium, size: 12, relativeTo: .caption)).foregroundStyle(DX.Palette.muted)
            }
            Spacer()
            button("plus") { value += step }
        }
        .padding(DX.Space.xs)
        .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(DX.Palette.hairline))
        .sensoryFeedback(DX.Haptic.select, trigger: value)
        .accessibilityElement()
        .accessibilityLabel(Text("Amount per day"))
        .accessibilityValue(Text("\(Int(value)) \(unitLine)"))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value += step
            case .decrement: value = max(step, value - step)
            @unknown default: break
            }
        }
    }

    private func button(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 16, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(DX.Palette.surface2, in: Circle())
                .foregroundStyle(DX.Palette.text)
        }
        .buttonStyle(.plain)
    }
}

private struct LabeledField<Field: View>: View {
    let label: LocalizedStringKey
    @ViewBuilder let field: () -> Field

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).dxText(.micro)
            field()
                .font(DX.TextStyle.body.font)
                .foregroundStyle(DX.Palette.text)
                .padding(.horizontal, DX.Space.m)
                .frame(minHeight: 48)
                .background(DX.Palette.surface2, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(DX.Palette.hairline))
        }
        .frame(maxWidth: .infinity)
    }
}

struct TriggersScreen: View {
    @Bindable var model: OnboardingModel

    var body: some View {
        OnboardingScaffold(title: "When do cravings hit?",
                           subtitle: "We'll plan around these and check in at the right moments.",
                           model: model) {
            Text("Situations").dxText(.micro)
            DXFlowLayout {
                ForEach(Trigger.allCases, id: \.self) { DXSetChip($0.title, value: $0, selection: $model.triggers) }
            }
            Text("Time of day").dxText(.micro).padding(.top, DX.Space.s)
            DXFlowLayout {
                ForEach(TimeOfDay.allCases, id: \.self) { DXSetChip($0.title, value: $0, selection: $model.cravingTimes) }
            }
        }
    }
}

struct ReasonsScreen: View {
    @Bindable var model: OnboardingModel
    @State private var draft = ""
    @State private var photoItem: PhotosPickerItem?
    @FocusState private var focused: Bool

    private let starters: [(LocalizedStringResource, LocalizedStringResource)] = [
        ("Money", "Spend the money on something I actually want"),
        ("Health", "Feel healthier and breathe easier"),
        ("Family", "Be there for my family"),
        ("Fitness", "Get fitter without running out of breath"),
        ("Freedom", "Stop planning my day around nicotine"),
    ]

    var body: some View {
        OnboardingScaffold(title: "Why do you want to quit?",
                           subtitle: "In your own words. We'll show these back to you on hard days.",
                           model: model) {
            ForEach($model.reasons) { $reason in
                HStack(spacing: 10) {
                    if let data = reason.photo, let image = UIImage(data: data) {
                        Image(uiImage: image).resizable().scaledToFill()
                            .frame(width: 44, height: 44).clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .accessibilityHidden(true)
                    }
                    TextField("", text: $reason.text, axis: .vertical)
                        .font(DX.TextStyle.body.font).foregroundStyle(DX.Palette.text)
                    Button { model.reasons.removeAll { $0.id == reason.id } } label: {
                        Image(systemName: "xmark").font(.system(size: 12, weight: .semibold)).foregroundStyle(DX.Palette.muted)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Remove reason"))
                }
                .padding(10)
                .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(DX.Palette.hairline))
            }

            TextField("", text: $draft, prompt: Text(model.reasons.isEmpty ? "e.g. More energy for the kids" : "Add another reason…")
                .foregroundStyle(DX.Palette.faint), axis: .vertical)
                .font(DX.TextStyle.body.font).foregroundStyle(DX.Palette.text)
                .focused($focused)
                .submitLabel(.done)
                .onSubmit(addDraft)
                .onChange(of: focused) { _, isFocused in if !isFocused { addDraft() } }
                .padding(14)
                .frame(minHeight: 76, alignment: .topLeading)
                .background(DX.Palette.surface2, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(focused ? DX.Palette.sage.opacity(0.8) : DX.Palette.hairline))
                .accessibilityLabel(Text("Reason"))

            if model.reasons.isEmpty {
                Text("Need a starting point?").dxText(.micro).padding(.top, DX.Space.xs)
                DXFlowLayout {
                    ForEach(starters, id: \.0.key) { title, sentence in
                        Button(String(localized: title)) { draft = String(localized: sentence); focused = true }
                            .font(.custom(DX.Typeface.regular, size: 14, relativeTo: .subheadline))
                            .foregroundStyle(DX.Palette.text2)
                            .padding(.vertical, 9).padding(.horizontal, 18)
                            .background(DX.Palette.surface2, in: Capsule())
                            .buttonStyle(.plain)
                    }
                }
            }

            PhotosPicker(selection: $photoItem, matching: .images) {
                VStack(spacing: 4) {
                    Image(systemName: "camera").font(.system(size: 18))
                    Text("Add a photo that reminds you").font(DX.TextStyle.subtitle.font)
                    Text("Optional · stays on this phone").font(.custom(DX.Typeface.regular, size: 11, relativeTo: .caption2))
                        .foregroundStyle(DX.Palette.muted)
                }
                .foregroundStyle(DX.Palette.text2)
                .frame(maxWidth: .infinity, minHeight: 92)
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(DX.Palette.faint, style: StrokeStyle(lineWidth: 1, dash: [4, 4])))
            }
            .padding(.top, DX.Space.xxs)
            .onChange(of: photoItem) { _, item in
                Task { await attach(item) }
            }
        }
    }

    private func addDraft() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        model.reasons.append(ReasonDraft(text: text))
        draft = ""
    }

    /// Attaches the photo to the most recent reason, creating one from the draft if needed.
    private func attach(_ item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return }
        addDraft()
        if model.reasons.isEmpty {
            model.reasons.append(ReasonDraft(text: "", photo: data))
        } else {
            model.reasons[model.reasons.count - 1].photo = data
        }
        photoItem = nil
    }
}

struct PastAttemptsScreen: View {
    @Bindable var model: OnboardingModel

    var body: some View {
        OnboardingScaffold(title: "Have you tried to quit before?",
                           subtitle: "Every attempt teaches something. This helps us pick what to focus on.",
                           model: model) {
            DXFlowLayout {
                ForEach(PastAttempts.allCases, id: \.self) { option in
                    DXChip(LocalizedStringKey(String(localized: option.title)), isOn: Binding(
                        get: { model.pastAttempts == option },
                        set: { if $0 { model.pastAttempts = option } }
                    ))
                }
            }
            if model.pastAttempts != nil, model.pastAttempts != .notYet {
                Text("What got in the way?").dxText(.micro).padding(.top, DX.Space.s)
                DXFlowLayout {
                    ForEach(Obstacle.allCases, id: \.self) { DXSetChip($0.title, value: $0, selection: $model.obstacles) }
                }
            }
        }
    }
}

struct QuitDayScreen: View {
    @Bindable var model: OnboardingModel

    var body: some View {
        OnboardingScaffold(title: "Pick your Quit Day",
                           subtitle: "Until then, use as normal while you prepare. On Quit Day, you stop.") {
            DatePicker("Quit Day", selection: $model.quitDay, in: model.quitDayRange, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(DX.Palette.accentInk)
                .labelsHidden()
                .padding(DX.Space.xs)
                .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: DX.Radius.card, style: .continuous))
            Button { model.quitDay = model.recommendedQuitDay } label: {
                HStack(alignment: .top, spacing: DX.Space.xs) {
                    Image(systemName: "star").foregroundStyle(DX.Palette.accentInk)
                    (Text("Recommended: \(model.recommendedQuitDay, format: .dateTime.weekday(.wide).day().month(.abbreviated)).")
                        .font(.custom(DX.Typeface.semibold, size: 13, relativeTo: .footnote)).foregroundStyle(DX.Palette.text)
                     + Text(" A week to prepare, with your usual routine.").font(DX.TextStyle.subtitle.font).foregroundStyle(DX.Palette.text2))
                        .multilineTextAlignment(.leading)
                }
                .padding(DX.Space.s)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(DX.Palette.hairline))
            }
            .buttonStyle(.plain)
        } footer: {
            Button("Set \(model.quitDay, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated)) as Quit Day") { model.next() }
                .buttonStyle(.dxPrimary)
                .disabled(!model.canContinue)
        }
    }
}

struct NRTScreen: View {
    @Bindable var model: OnboardingModel

    var body: some View {
        OnboardingScaffold(title: "Want to use nicotine replacement?",
                           subtitle: "Research shows patches, gum, lozenges and inhalers can make quitting easier. We'll help you plan around the label.") {
            Link(destination: HealthSources.nrtCochrane2018.url) {
                Label {
                    Text(HealthSources.nrtCochrane2018.label)
                } icon: {
                    Image(systemName: "doc.text.magnifyingglass")
                }
                .font(.custom(DX.Typeface.medium, size: 12, relativeTo: .caption))
                .foregroundStyle(DX.Palette.accentInk)
            }
            .accessibilityHint(Text("Opens the study summary"))
            DXOptionCard("I'm already using it", isSelected: model.nrtInterest == .using) { model.nrtInterest = .using }
            DXOptionCard("I'd like to", detail: "We'll suggest talking to a pharmacist", isSelected: model.nrtInterest == .wantIt) {
                model.nrtInterest = .wantIt
            }
            DXOptionCard("Not for me", isSelected: model.nrtInterest == .notInterested) { model.nrtInterest = .notInterested }
        } footer: {
            Text("Follow the product label and ask a pharmacist or doctor.")
                .dxText(.subtitle).multilineTextAlignment(.center).frame(maxWidth: .infinity)
            ContinueButton(title: "Continue", model: model)
        }
    }
}
