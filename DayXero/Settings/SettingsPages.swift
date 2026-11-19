import DayXeroCore
import StoreKit
import SwiftData
import SwiftUI
import UIKit
import WidgetKit

// MARK: - What you use (065)

/// What you use (v5, 065): what being free keeps, a year and a day; the products as checkboxes; one usual-day group
/// per product, each headed by its small icon. The hero recounts live after every change.
struct ProductsSettingsView: View {
    let profile: UserProfile
    @Environment(\.modelContext) private var context
    @State private var shake = 0
    private let ground = DX.Ground.reading
    private let order: [DayXeroCore.Product] = [.cigarettes, .vape, .pouches]

    var body: some View {
        SettingsPage("What you use", lead: Text("This sets money kept and your counters.")) {
            hero.padding(.top, 18).dxArrive(2)
            SettingsSection("You use", top: 22, index: 3)
            DXList {
                ForEach(order, id: \.self) { product in
                    let use = profile.products.first { $0.product == product }
                    Button { toggle(product) } label: {
                        HStack(spacing: 12) {
                            SettingsTile(d: icon(product).d, size: 34)
                            Text(product.title).dxFont(16, weight: 600, style: .body).foregroundStyle(ground.ink)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            DXRadio(isOn: use != nil, multi: true, ground: ground)
                        }
                        .padding(.horizontal, 12)
                        .frame(minHeight: 50)
                        .background(use != nil ? ground.selTint : .clear)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.dxPress)
                    .accessibilityAddTraits(use != nil ? .isSelected : [])
                }
            }
            .accessibilityLabel(Text("You use, choose any"))
            .modifier(Shake(trigger: shake))
            .dxArrive(4)
            ForEach(Array(sorted.enumerated()), id: \.element.persistentModelID) { i, use in
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 6) {
                        DXIcon(icon(use.product), size: 18)
                        Text(groupTitle(use.product))
                    }
                    .dxFont(14, weight: 600, style: .footnote)
                    .foregroundStyle(ground.muted)
                    .padding(.horizontal, 4)
                    .padding(.top, 22)
                    .padding(.bottom, 8)
                    UsualDayCard(use: use, currencyCode: profile.currencyCode)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .dxArrive(5 + i)
            }
        }
        .animation(DX.Move.settle, value: profile.products.map(\.productRaw))
        .sensoryFeedback(.warning, trigger: shake)
    }

    private var sorted: [ProductUse] {
        profile.products.sorted { a, b in (order.firstIndex(of: a.product) ?? 0) < (order.firstIndex(of: b.product) ?? 0) }
    }

    /// Being free keeps: a year, big; a day on the label line.
    private var hero: some View {
        let perDay = profile.products.reduce(Decimal(0)) { sum, use in
            sum + Baseline(product: use.product, unitsPerDay: use.unitsPerDay, pricePerPurchase: use.pricePerPurchase,
                           unitsPerPurchase: use.unitsPerPurchase).costPerDay
        }
        let day = NSDecimalNumber(decimal: perDay).doubleValue
        let code = profile.currencyCode
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Being free keeps").foregroundStyle(ground.muted)
                Spacer()
                Text("\(day.rounded().formatted(.currency(code: code).precision(.fractionLength(0)))) a day")
                    .foregroundStyle(ground.ink)
            }
            .dxType(.footnote)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                CountingText(day * 365, delay: 0.2) { v in v.formatted(.currency(code: code).precision(.fractionLength(0))) }
                    .dxFace(.display, 40, weight: 800, tracking: -0.8)
                    .foregroundStyle(ground.ink)
                    .id(Int(day * 365))
                Text("a year").dxType(.headline).foregroundStyle(ground.ink)
            }
        }
        .dxCard(on: .reading)
        .accessibilityElement(children: .combine)
    }

    private func icon(_ product: DayXeroCore.Product) -> DX.Icon {
        switch product {
        case .cigarettes: .cig
        case .vape: .vape
        case .pouches: .pouch
        }
    }

    private func groupTitle(_ product: DayXeroCore.Product) -> LocalizedStringKey {
        switch product {
        case .cigarettes: "Cigarettes on a usual day"
        case .vape: "Vape on a usual day"
        case .pouches: "Pouches on a usual day"
        }
    }

    private func toggle(_ product: DayXeroCore.Product) {
        if let use = profile.products.first(where: { $0.product == product }) {
            guard profile.products.count > 1 else { shake += 1; return }
            let wasPrimary = use.isPrimary
            profile.products.removeAll { $0 === use }
            context.delete(use)
            if wasPrimary { profile.products.first?.isPrimary = true }
        } else {
            let use = ProductUse(product: product, isPrimary: profile.products.isEmpty,
                                 unitsPerDay: product == .vape ? VapeUsage.puffsPerDay(podsPerWeek: 2, puffsPerPod: 600) : 10,
                                 pricePerPurchase: 10, unitsPerPurchase: product == .vape ? 600 : 20)
            profile.products.append(use)
        }
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

/// One product's usual day (065): a stepper for how much, and the price field that opens the decimal keypad.
private struct UsualDayCard: View {
    @Bindable var use: ProductUse
    let currencyCode: String
    @Environment(\.modelContext) private var context
    @State private var price = ""
    @FocusState private var editing: Bool
    private let ground = DX.Ground.reading

    var body: some View {
        DXList {
            HStack {
                Text(amountLabel).dxFont(16, weight: 600, style: .body).foregroundStyle(ground.ink)
                Spacer()
                HStack(spacing: 6) {
                    step(.minus, label: "Less") { change(-1) }
                    Text(verbatim: amountText).dxFace(.display, 17, weight: 800).foregroundStyle(ground.ink)
                        .monospacedDigit()
                        .frame(minWidth: 48)
                        .contentTransition(.numericText())
                    step(.plus, label: "More") { change(1) }
                }
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 56)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(amountLabel))
            .accessibilityValue(Text(verbatim: amountText))
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: change(1)
                case .decrement: change(-1)
                @unknown default: break
                }
            }
            HStack {
                Text(priceLabel).dxFont(16, weight: 600, style: .body).foregroundStyle(ground.ink)
                Spacer()
                TextField("0.00", text: $price)
                    .keyboardType(.decimalPad)
                    .focused($editing)
                    .multilineTextAlignment(.trailing)
                    .dxFace(.display, 17, weight: 800)
                    .foregroundStyle(ground.ink)
                    .padding(.horizontal, 12)
                    .frame(width: 104, height: 40)
                    .background(ground.card2, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .strokeBorder(editing ? ground.selEdge : ground.ink.opacity(0.12), lineWidth: editing ? 2 : 1)
                    }
                    .accessibilityLabel(Text(priceLabel))
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 56)
        }
        .onAppear { price = format(use.pricePerPurchase) }
        .onChange(of: editing) { _, now in
            guard !now else { return }
            if let value = Decimal(string: price.filter { "0123456789.,".contains($0) }.replacingOccurrences(of: ",", with: ".")), value > 0 {
                use.pricePerPurchase = value
                save()
            }
            price = format(use.pricePerPurchase)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { editing = false }
            }
        }
    }

    private func step(_ icon: DX.Icon, label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            DXIcon(icon, size: 16, weight: 2.6).foregroundStyle(ground.ink)
                .frame(width: 36, height: 36)
                .background(ground.card2, in: Circle())
        }
        .buttonStyle(.dxPress)
        .accessibilityLabel(Text(label))
    }

    private var amountLabel: LocalizedStringKey {
        switch use.product {
        case .vape: "Pods a week"
        case .cigarettes, .pouches: "A day"
        }
    }

    private var amountText: String {
        use.product == .vape ? VapeUsage.format(use.podsPerWeek) : "\(Int(use.unitsPerDay))"
    }

    private var priceLabel: LocalizedStringKey {
        switch use.product {
        case .cigarettes: use.unitsPerPurchase <= 1 ? "Price of one cigarette" : "Price of a pack of \(Int(use.unitsPerPurchase))"
        case .vape: "Price of a pod"
        case .pouches: "Price of a can of \(Int(use.unitsPerPurchase))"
        }
    }

    private func change(_ by: Int) {
        if use.product == .vape {
            use.podsPerWeek = min(max(use.podsPerWeek + Double(by) * VapeUsage.podsStep, VapeUsage.podsStep), 100)
        } else {
            use.unitsPerDay = min(max(use.unitsPerDay + Double(by), 1), 2000)
        }
        save()
    }

    private func save() {
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func format(_ value: Decimal) -> String {
        value.formatted(.currency(code: currencyCode).precision(.fractionLength(2)))
    }
}

// MARK: - Quit Day (066)

/// Your Quit Day (v5, 066): the date as a calendar leaf beside the days free and the bar to the next badge; the first
/// week, Day Xero's sun then a disc a day; and a calm way to change it that confirms before any date wheel.
struct QuitDaySettingsView: View {
    let profile: UserProfile
    @State private var changing = false
    private let ground = DX.Ground.reading

    var body: some View {
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        let stats = ProgressStats(quitDay: profile.quitDay, baselines: [], clock: clock)
        let prep = stats.isPrep(at: .now)
        SettingsPage("Your Quit Day", lead: Text(prep ? "The day you stop. Your prep days lead up to it." : "The day you stopped. It all counts from here.")) {
            hero(stats: stats, prep: prep).padding(.top, 18).dxArrive(2)
            if !prep { week(stats: stats).padding(.top, 12).dxArrive(3) }
            change(prep: prep).padding(.top, 12).dxArrive(4)
        }
        .sheet(isPresented: $changing) {
            QuitDayChanger(profile: profile, prep: prep)
        }
    }

    private func hero(stats: ProgressStats, prep: Bool) -> some View {
        let date = profile.quitDay
        let days = prep ? stats.daysUntilQuitDay(at: .now) : stats.daysClear(at: .now)
        let next = Milestones.next(after: days)
        return HStack(alignment: .center, spacing: 16) {
            VStack(spacing: 0) {
                Text(date.formatted(.dateTime.month(.wide))).dxType(.caption).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 26)
                    .background(Color(light: 0x1E1A3A, dark: 0x2E3A62))
                Text(date.formatted(.dateTime.day())).dxFace(.display, 34, weight: 800).foregroundStyle(ground.ink)
                    .padding(.top, 6)
                Text(date.formatted(.dateTime.weekday(.wide))).dxType(.caption).foregroundStyle(ground.muted)
                    .padding(.bottom, 8)
            }
            .frame(width: 84)
            .background(ground.card2)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    CountingText(Double(days), delay: 0.3, duration: 0.9) { "\(Int($0.rounded()))" }
                        .dxFace(.display, 40, weight: 800, tracking: -0.8).foregroundStyle(ground.ink)
                    Text(days == 1 ? "day" : "days").dxType(.headline).foregroundStyle(ground.ink)
                }
                Text(prep ? "until Quit Day" : "free since \(date.formatted(.dateTime.month(.abbreviated).day()))")
                    .dxType(.footnote).foregroundStyle(ground.muted)
                if !prep, let next {
                    BadgeBar(value: Double(days) / Double(max(next, 1)))
                        .padding(.top, 8)
                    Text("\(next - days) days to your \(next)-day badge").dxType(.caption).foregroundStyle(ground.ink)
                        .padding(.top, 6)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .dxCardChrome(on: .reading)
        .accessibilityElement(children: .combine)
    }

    /// The first week: Day Xero's sun stamps in, then a disc a day, ending on today's ring.
    private func week(stats: ProgressStats) -> some View {
        let quit = profile.quitDay
        let today = stats.daysClear(at: .now)
        let cal = Calendar.current
        let last = cal.date(byAdding: .day, value: 6, to: quit) ?? quit
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your first week").dxType(.footnote).foregroundStyle(ground.muted)
                Spacer()
                Text("\(quit.formatted(.dateTime.month(.abbreviated).day())) to \(last.formatted(.dateTime.day()))")
                    .dxType(.caption).foregroundStyle(ground.muted)
            }
            HStack(spacing: 8) {
                SunMark().frame(width: 30, height: 30).dxStamp(0, delay: 0.6)
                Text("Day Xero").dxFont(15, weight: 700, style: .subheadline).foregroundStyle(ground.ink)
                Text(quit.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                    .dxType(.footnote).foregroundStyle(ground.muted)
            }
            HStack(spacing: 0) {
                ForEach(1...7, id: \.self) { n in
                    let date = cal.date(byAdding: .day, value: n - 1, to: quit) ?? quit
                    let isToday = n == today
                    VStack(spacing: 4) {
                        ZStack {
                            if n <= today {
                                Circle().fill(Color(light: 0xFFC08F, dark: 0xF2A26E))
                            } else {
                                Circle().strokeBorder(ground.muted.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                            }
                            if isToday { Circle().strokeBorder(ground.ink, lineWidth: 2.5).padding(-4) }
                            Text(verbatim: "\(n)").dxFace(.display, 15, weight: 800)
                                .foregroundStyle(n <= today ? Color(hex: 0x1E1A3A) : ground.muted)
                        }
                        .frame(width: 34, height: 34)
                        Text(isToday ? String(localized: "Today") : date.formatted(.dateTime.weekday(.abbreviated).day()))
                            .dxFont(12, weight: isToday ? 700 : 600, style: .caption2)
                            .foregroundStyle(isToday ? ground.ink : ground.muted)
                            .lineLimit(1).minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .dxPop(n, delay: 0.7 + Double(n) * 0.11)
                }
            }
        }
        .padding(16)
        .dxCardChrome(on: .reading)
        .accessibilityElement(children: .combine)
    }

    private func change(prep: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Need to change it?").dxType(.headline).foregroundStyle(ground.ink)
            Text(prep ? "Pick any day in the next 30. Your prep days adjust to fit."
                      : "A slip does not start you over. A new date restarts the day count only. Badges, lessons and logs stay.")
                .dxType(.footnote).foregroundStyle(ground.muted)
                .fixedSize(horizontal: false, vertical: true)
            Button("Choose a new date") { changing = true }
                .buttonStyle(.dx(.ghost, on: .reading))
                .padding(.top, 6)
        }
        .padding(18)
        .dxCardChrome(on: .reading)
    }
}

/// The slim bar toward the next badge (066): coral on the track, filling on arrival.
private struct BadgeBar: View {
    let value: Double
    @State private var shown = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(DX.Ground.reading.track)
                Capsule().fill(Color(hex: 0xF7894F)).frame(width: geo.size.width * (shown ? min(max(value, 0.04), 1) : 0))
            }
        }
        .frame(height: 6)
        .onAppear { withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.9).delay(0.3)) { shown = true } }
        .accessibilityHidden(true)
    }
}

/// Day Xero's small sun (066).
private struct SunMark: View {
    var body: some View {
        Canvas { ctx, size in
            ctx.scaleBy(x: size.width / 30, y: size.height / 30)
            for i in 0..<12 {
                var g = ctx
                g.translateBy(x: 15, y: 15)
                g.rotate(by: .degrees(Double(i) * 30))
                g.fill(Path(roundedRect: CGRect(x: -1, y: -14, width: 2, height: 4.5), cornerRadius: 1), with: .color(Color(hex: 0xF5B83D)))
            }
            ctx.fill(CalmPaint.circle(15, 15, 8), with: .color(Color(hex: 0xFFD45E)))
        }
        .accessibilityHidden(true)
    }
}

/// Choosing a new Quit Day: after Quit Day a calm confirm comes first, then the date (066).
private struct QuitDayChanger: View {
    let profile: UserProfile
    let prep: Bool
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var confirmed = false
    @State private var date = Date.now
    private let ground = DX.Ground.reading

    var body: some View {
        let today = Calendar.current.startOfDay(for: .now)
        let latest = Calendar.current.date(byAdding: .day, value: 30, to: today) ?? today
        let range: ClosedRange<Date> = DemoMode.isOn
            ? (Calendar.current.date(byAdding: .year, value: -2, to: today) ?? today)...(Calendar.current.date(byAdding: .year, value: 1, to: today) ?? today)
            : prep ? (Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today)...latest : today...latest
        VStack(alignment: .leading, spacing: 12) {
            if prep || confirmed || DemoMode.isOn {
                Text("Pick your Quit Day").dxType(.title).foregroundStyle(ground.ink)
                DatePicker("Quit Day", selection: $date, in: range, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(Color(hex: 0xF26A45))
                Button("Use \(date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))") { save() }
                    .buttonStyle(.dx(.primary, on: .reading))
            } else {
                Text("Start counting again?").dxType(.title).foregroundStyle(ground.ink)
                Text("A new date restarts the day count only. Badges, lessons, logs and plans all stay.")
                    .dxType(.body).foregroundStyle(ground.muted)
                Spacer(minLength: 8)
                Button("Choose a date") { withAnimation(DX.Move.settle) { confirmed = true } }
                    .buttonStyle(.dx(.primary, on: .reading))
                Button("Keep my Quit Day") { dismiss() }
                    .buttonStyle(.dx(.quiet, on: .reading))
            }
        }
        .padding(.horizontal, DX.Layout.gutter)
        .padding(.top, 28)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(ground.background.ignoresSafeArea())
        .presentationDetents(prep || confirmed || DemoMode.isOn ? [.large] : [.height(300)])
        .presentationCornerRadius(32)
        .dxGround(.reading)
        .onAppear {
            date = min(max(profile.quitDay, range.lowerBound), range.upperBound)
        }
    }

    private func save() {
        let wasPast = !prep
        profile.quitDay = Calendar.current.startOfDay(for: date)
        try? context.save()
        if wasPast { UserDefaults.standard.removeObject(forKey: CelebratedMilestones.key) }
        DailyReminders.refresh(in: context)
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}

// MARK: - Currency (067)

/// Currency (v5, 067): the line that amounts aren't converted, under the title; search; one list with your region's
/// first, then the common ones; More currencies opens A to Z.
struct CurrencySettingsView: View {
    let profile: UserProfile
    @State private var search = ""

    var body: some View {
        let query = search.trimmingCharacters(in: .whitespaces)
        let codes = query.isEmpty ? CurrencyRows.common(current: profile.currencyCode)
                                  : Array(CurrencyChoice.codes().filter { CurrencyRows.matches($0, query) }.prefix(40))
        SettingsPage("Currency", lead: Text("Used for money kept and your prices. Switching does not convert the amounts.")) {
            SearchField(text: $search).padding(.top, 18).dxArrive(2)
            CurrencyRows(profile: profile, codes: codes, more: query.isEmpty)
                .padding(.top, 14)
                .animation(.easeInOut(duration: 0.2), value: codes)
                .dxArrive(3)
        }
    }
}

/// Every currency, A to Z (067's More currencies).
struct AllCurrenciesView: View {
    let profile: UserProfile

    var body: some View {
        SettingsPage("All currencies", lead: Text("A to Z. Switching does not convert the amounts.")) {
            CurrencyRows(profile: profile, codes: CurrencyChoice.codes().sorted { CurrencyChoice.name($0) < CurrencyChoice.name($1) }, more: false)
                .padding(.top, 18)
        }
    }
}

private struct SearchField: View {
    @Binding var text: String
    private let ground = DX.Ground.reading

    var body: some View {
        HStack(spacing: 10) {
            DXIcon(.search, size: 18, weight: 2.4).foregroundStyle(ground.muted)
            TextField("Search currencies", text: $text)
                .dxType(.body)
                .foregroundStyle(ground.ink)
                .autocorrectionDisabled()
                .submitLabel(.search)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(ground.card, in: RoundedRectangle(cornerRadius: DX.Layout.fieldRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DX.Layout.fieldRadius, style: .continuous).strokeBorder(ground.ink.opacity(0.16), lineWidth: 1.5)
        }
    }
}

private struct CurrencyRows: View {
    let profile: UserProfile
    let codes: [String]
    let more: Bool
    @Environment(\.modelContext) private var context
    @Environment(Entitlement.self) private var entitlement
    private let ground = DX.Ground.reading

    static func common(current: String) -> [String] {
        var list = [CurrencyChoice.defaultCode()]
        if !list.contains(current) { list.append(current) }
        for code in ["USD", "GBP", "EUR", "CAD", "AUD", "INR"] where !list.contains(code) { list.append(code) }
        return list
    }

    /// The short symbol for the tile: the common ones as people write them (C$, A$), others from the locale.
    static func symbol(_ code: String) -> String {
        switch code {
        case "USD": "$"
        case "GBP": "£"
        case "EUR": "€"
        case "CAD": "C$"
        case "AUD": "A$"
        case "INR": "₹"
        case "JPY": "¥"
        default: CurrencyChoice.symbol(code)
        }
    }

    static func matches(_ code: String, _ query: String) -> Bool {
        code.localizedCaseInsensitiveContains(query) || CurrencyChoice.name(code).localizedCaseInsensitiveContains(query)
    }

    var body: some View {
        DXList {
            ForEach(codes, id: \.self) { code in
                let on = code == profile.currencyCode
                Button { choose(code) } label: {
                    HStack(spacing: 12) {
                        Text(verbatim: Self.symbol(code))
                            .font(.system(size: Self.symbol(code).count > 2 ? 13 : 17, weight: .heavy, design: .rounded))
                            .foregroundStyle(ground.ink)
                            .lineLimit(1).minimumScaleFactor(0.6)
                            .frame(width: 40, height: 40)
                            .background(ground.card2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: CurrencyChoice.name(code)).dxFont(16, weight: 600, style: .body).foregroundStyle(ground.ink)
                            Text(verbatim: code).dxType(.footnote).foregroundStyle(ground.muted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        DXRadio(isOn: on, ground: ground)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(on ? ground.selTint : .clear)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.dxPress)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
            if more {
                NavigationLink(value: SettingsSheet.Page.allCurrencies) {
                    HStack(spacing: 8) {
                        Text("More currencies").dxFont(16, weight: 600, style: .body).foregroundStyle(ground.ink)
                        Spacer()
                        Text("A to Z").dxFont(15, weight: 500, style: .subheadline).foregroundStyle(ground.muted)
                        DXIcon(.chev, size: 18).foregroundStyle(ground.muted)
                    }
                    .padding(.horizontal, 16)
                    .frame(minHeight: 56)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.dxPress)
            }
        }
        .sensoryFeedback(.success, trigger: profile.currencyCode)
    }

    private func choose(_ code: String) {
        guard code != profile.currencyCode else { return }
        profile.currencyCode = code
        try? context.save()
        WidgetSync.refresh(in: context, isPro: entitlement.isPro)
        Analytics.track(.currencyChanged(code: code))
    }
}

// MARK: - Subscription (068)

/// Subscription (v5, 068): the plan card (the dawn window, the plan's name and Active, the price, when it renews and
/// the one mention of Apple ID), what you get, then Manage in the App Store and Restore purchases.
struct SubscriptionSettingsView: View {
    let profile: UserProfile
    @Environment(Entitlement.self) private var entitlement
    @State private var current: CurrentPlan?
    @State private var plans: [PlanOption] = []
    @State private var manage = false
    @State private var restoring = false
    @State private var restored: Bool?
    @State private var showPaywall = false
    private let ground = DX.Ground.reading

    var body: some View {
        SettingsPage("Subscription", lead: Text(entitlement.isPro ? "Everything in DayXero is open to you." : "The full program is waiting for you.")) {
            planCard.padding(.top, 18).dxArrive(2)
            perks.padding(.top, 12).dxArrive(3)
        } dock: {
            DXActionDock {
                if entitlement.isPro {
                    if current?.plan != .lifetime {
                        Button("Manage in the App Store") { manage = true }
                            .buttonStyle(.dx(.ghost, on: .reading))
                            .dxArrive(4)
                    }
                } else {
                    Button("Unlock the full program") { unlock() }
                        .buttonStyle(.dx(.primary, on: .reading))
                        .dxArrive(4)
                }
                Button { restore() } label: {
                    HStack(spacing: 6) {
                        if restoring { ProgressView().controlSize(.small) }
                        if restored == true { DXIcon(.check, size: 16, weight: 2.8) }
                        Text(restored == false ? "No purchases found" : "Restore purchases")
                    }
                }
                .buttonStyle(.dx(.quiet, on: .reading))
                .disabled(restoring)
                .dxArrive(5)
            }
        }
        .task {
            current = await entitlement.store.currentPlan()
            plans = (try? await entitlement.store.loadPlans()) ?? []
        }
        .manageSubscriptionsSheet(isPresented: $manage)
        .dxCover(isPresented: $showPaywall) {
            PaywallView(name: profile.name, quitDay: profile.quitDay,
                        model: PaywallModel(store: entitlement.store, entitlement: entitlement),
                        onClose: { showPaywall = false })
        }
    }

    private var option: PlanOption? { current.flatMap { c in plans.first { $0.plan == c.plan } } }

    private var planCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 14) {
                SettingsDawn(size: 64, xero: 40, corner: 16)
                VStack(alignment: .leading, spacing: 6) {
                    Text(verbatim: planTitle).dxType(.title).foregroundStyle(ground.ink)
                    HStack(spacing: 6) {
                        Circle().fill(entitlement.isPro ? Color(hex: 0xF26A45) : ground.muted).frame(width: 6, height: 6)
                        Text(entitlement.isPro ? "Active" : "Free").dxType(.caption)
                    }
                    .foregroundStyle(entitlement.isPro ? Color(light: 0xB4502E, dark: 0xFFB08A) : ground.muted)
                    .padding(.horizontal, 10)
                    .frame(height: 26)
                    .background(entitlement.isPro ? Color(light: 0xFFE3CC, dark: 0x4A2E26) : ground.card2, in: Capsule())
                }
            }
            if let option, let current {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(verbatim: option.priceText).dxFace(.display, 34, weight: 800, tracking: -0.6).foregroundStyle(ground.ink)
                    Text(unit(current.plan)).dxType(.headline).foregroundStyle(ground.ink)
                }
                .padding(.top, 14)
                if let perMonth = option.perMonthText, current.plan == .annual {
                    Text("About \(perMonth) a month").dxType(.footnote).foregroundStyle(ground.muted)
                }
                if let date = current.renews {
                    Rectangle().fill(ground.line).frame(height: 1).padding(.top, 14)
                    HStack {
                        Text(current.willRenew ? "Renews" : "Ends").dxType(.footnote).foregroundStyle(ground.muted)
                        Spacer()
                        Text(date.formatted(date: .abbreviated, time: .omitted)).dxFont(15, weight: 700, style: .subheadline)
                            .foregroundStyle(ground.ink)
                    }
                    .padding(.top, 12)
                    .dxFade(delay: 0.45)
                }
                Text("Change or cancel any time in Settings > Apple ID.").dxType(.caption).foregroundStyle(ground.muted)
                    .padding(.top, 12)
                    .dxFade(delay: 0.54)
            } else if !entitlement.isPro {
                Text("Craving SOS stays free. The full program adds your prep week, every lesson and the NRT plan.")
                    .dxType(.footnote).foregroundStyle(ground.muted)
                    .padding(.top, 14)
            }
        }
        .padding(18)
        .dxCardChrome(on: .reading)
        .accessibilityElement(children: .combine)
    }

    private var perks: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What you get").dxType(.headline).foregroundStyle(ground.ink).padding(.bottom, 2)
            ForEach(Array(perkRows.enumerated()), id: \.offset) { i, row in
                HStack(spacing: 12) {
                    SettingsTile(d: row.0.d)
                    Text(row.1).dxType(.footnote).foregroundStyle(ground.ink)
                }
                .dxFade(delay: 0.5 + Double(i) * 0.09)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dxCardChrome(on: .reading)
    }

    private var perkRows: [(DX.Icon, LocalizedStringKey)] {
        [(.sun, "Your prep week and your plan"), (.wave, "Craving SOS, any time"),
         (.note, "Daily lessons and evening check-ins"), (.medal, "Badges and money kept")]
    }

    private var planTitle: String {
        guard let plan = current?.plan else { return entitlement.isPro ? "DayXero Pro" : "DayXero Free" }
        return switch plan {
        case .annual: String(localized: "DayXero Yearly")
        case .quarterly: String(localized: "DayXero 3 months")
        case .monthly: String(localized: "DayXero Monthly")
        case .lifetime: String(localized: "DayXero Lifetime")
        }
    }

    private func unit(_ plan: Plan) -> LocalizedStringKey {
        switch plan {
        case .annual: "a year"
        case .quarterly: "every 3 months"
        case .monthly: "a month"
        case .lifetime: "once"
        }
    }

    private func unlock() {
        Paywalls.present(.upgradeFromSettings) { outcome in
            switch outcome {
            case .fallback: showPaywall = true
            case .unlocked: entitlement.grantFromElsewhere()
            case .closed: break
            }
        }
    }

    private func restore() {
        Task {
            restoring = true
            restored = nil
            let found = (try? await entitlement.store.restore()) ?? false
            Analytics.track(.purchasesRestored(success: found))
            if found { entitlement.grantFromElsewhere() }
            current = await entitlement.store.currentPlan()
            restoring = false
            restored = found
        }
    }
}

// MARK: - Privacy (069)

/// Privacy and your data (v5, 069): it stays on this phone; the usage switch, export and the policy; then deleting
/// everything, held for two seconds on its own sheet.
struct PrivacySettingsView: View {
    let profile: UserProfile
    let onDeleteAll: () -> Void
    @Environment(\.modelContext) private var context
    @State private var shareUsage = AnalyticsConsent.isOn
    @State private var exportURL: URL?
    @State private var confirmDelete = false
    private let ground = DX.Ground.reading

    var body: some View {
        SettingsPage("Privacy and your data", lead: Text("No account, no ads, no selling. Here is exactly what happens.")) {
            lead.padding(.top, 18).dxArrive(2)
            DXList {
                SettingsSwitchRow("Share anonymous usage", icon: .chart,
                                  detail: Text("Counts like “lesson started”. Never your words."), isOn: $shareUsage)
                Button { exportURL = DataTools.export(context: context, profile: profile) } label: {
                    SettingsRow("Export my data", icon: .share, detail: Text("A file you can keep or move"), minHeight: 66)
                }
                .buttonStyle(.dxPress)
                if let privacy = AppLinks.privacy {
                    Link(destination: privacy) {
                        SettingsRow("Privacy policy", icon: .shield, detail: Text("Purchases go through Apple and RevenueCat"), minHeight: 66)
                    }
                    .buttonStyle(.dxPress)
                }
            }
            .padding(.top, 16)
            .dxArrive(3)
            VStack(alignment: .leading, spacing: 6) {
                Text("Delete all my data").dxType(.headline).foregroundStyle(ground.ink)
                Text("Erases your plan, days, badges and notes from this phone. This cannot be undone.")
                    .dxType(.footnote).foregroundStyle(ground.muted)
                    .fixedSize(horizontal: false, vertical: true)
                Rectangle().fill(ground.line).frame(height: 1).padding(.top, 10).padding(.horizontal, -18)
                Button("Delete everything…") { confirmDelete = true }
                    .dxFont(16, weight: 700, style: .body)
                    .foregroundStyle(Color(light: 0xC2410C, dark: 0xFF8A6B))
                    .padding(.top, 8)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dxCardChrome(on: .reading)
            .padding(.top, 16)
            .dxArrive(4)
        }
        .onChange(of: shareUsage) { _, on in AnalyticsConsent.set(on) }
        .sensoryFeedback(.warning, trigger: confirmDelete) { _, now in now }
        .sheet(isPresented: $confirmDelete) {
            DeleteEverythingSheet(onDelete: {
                confirmDelete = false
                onDeleteAll()
            })
        }
        .sheet(item: Binding(get: { exportURL.map(ExportFile.init) }, set: { if $0 == nil { exportURL = nil } })) { file in
            ShareSheet(items: [file.url])
        }
    }

    private var lead: some View {
        HStack(spacing: 14) {
            ZStack(alignment: .top) {
                SettingsDawn(size: 56, height: 84, xero: 34, corner: 9)
                Capsule().fill(Color(light: 0x1E1A3A, dark: 0x0B1022)).frame(width: 18, height: 5).padding(.top, 4)
            }
            .padding(3)
            .background(Color(light: 0x1E1A3A, dark: 0x0B1022), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text("It stays on this phone").dxType(.headline).foregroundStyle(ground.ink)
                Text("Your plan, reasons, logs and notes never leave this iPhone.")
                    .dxType(.footnote).foregroundStyle(ground.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .dxCardChrome(on: .reading)
        .accessibilityElement(children: .combine)
    }
}

private struct ExportFile: Identifiable {
    let url: URL
    var id: URL { url }
}

/// Delete everything (069): only a full two-second hold erases the data.
private struct DeleteEverythingSheet: View {
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    private let ground = DX.Ground.reading

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Delete everything?").dxType(.title).foregroundStyle(ground.ink)
            Text("This removes your plan, logs, check-ins and progress from this iPhone. It can't be undone. Your subscription isn't affected.")
                .dxType(.body).foregroundStyle(ground.muted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            HoldButton(String(localized: "Hold to delete everything"), done: String(localized: "Deleted"), duration: 2, on: .reading) {
                onDelete()
            }
            .frame(height: DX.Layout.buttonHeight)
            Button("Keep my data") { dismiss() }
                .buttonStyle(.dx(.quiet, on: .reading))
        }
        .padding(.horizontal, DX.Layout.gutter)
        .padding(.top, 28)
        .padding(.bottom, 10)
        .background(ground.background.ignoresSafeArea())
        .presentationDetents([.height(330)])
        .presentationCornerRadius(32)
        .dxGround(.reading)
    }
}

// MARK: - Health information

/// The health disclaimer (S15.6): educational support, not medical treatment.
struct HealthInfoView: View {
    static var oneLine: LocalizedStringKey { "DayXero offers education and support. It isn't medical treatment." }
    private let ground = DX.Ground.reading

    var body: some View {
        SettingsPage("Health information", lead: Text("What DayXero is, and what it isn't.")) {
            VStack(spacing: 0) {
                item(.heart, "Support, not treatment",
                     "DayXero offers education and support to help you stop using nicotine. It isn't medical treatment, and it doesn't replace advice from a doctor or pharmacist.")
                item(.patch, "Before you use NRT",
                     "If you're pregnant, have a health condition or take other medication, talk to a doctor or pharmacist first.")
                item(.note, "Every fact has a source", "Health facts in the app name their sources, and you can open each one.")
                item(.people, "If you're struggling",
                     "If you're struggling with your mood, or in crisis, contact a doctor or your local emergency number.")
            }
            .dxCardChrome(on: .reading)
            .padding(.top, 18)
            .dxArrive(2)
        }
    }

    private func item(_ icon: DX.Icon, _ title: LocalizedStringKey, _ body: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            SettingsTile(d: icon.d)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).dxFont(16, weight: 600, style: .body).foregroundStyle(ground.ink)
                Text(body).dxType(.footnote).foregroundStyle(ground.muted).fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Help, about, sound and display

struct HelpSettingsView: View {
    var body: some View {
        SettingsPage("Help and contact", lead: Text("Questions, ideas or something not working? We read every message.")) {
            DXList {
                if let mail = URL(string: "mailto:hello@dayxero.in") {
                    Link(destination: mail) {
                        SettingsRow(Text("Email us"), icon: SettingsGlyph.mail, detail: Text(verbatim: "hello@dayxero.in"), minHeight: 66)
                    }
                    .buttonStyle(.dxPress)
                }
                Link(destination: AppLinks.writeReview) {
                    SettingsRow(Text("Rate DayXero"), icon: SettingsGlyph.star, detail: Text("A rating helps other people find it"), minHeight: 66)
                }
                .buttonStyle(.dxPress)
                NavigationLink(value: SettingsSheet.Page.health) {
                    SettingsRow("Health information", icon: .heart, detail: Text("Support, not treatment"), minHeight: 66)
                }
                .buttonStyle(.dxPress)
            }
            .padding(.top, 18)
            .dxArrive(2)
            Text("In crisis? Contact your local emergency number.")
                .dxType(.caption).foregroundStyle(DX.Ground.reading.muted)
                .padding(.horizontal, 4)
                .padding(.top, 10)
                .dxArrive(3)
        }
    }
}

struct AboutSettingsView: View {
    static var version: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0" }
    static var build: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "" }

    var body: some View {
        SettingsPage("About", lead: Text("DayXero \(Self.version) (\(Self.build))")) {
            DXList {
                Link(destination: AppLinks.terms) { SettingsRow(Text("Terms of use"), icon: SettingsGlyph.doc) }
                    .buttonStyle(.dxPress)
                if let privacy = AppLinks.privacy {
                    Link(destination: privacy) { SettingsRow("Privacy policy", icon: .shield) }
                        .buttonStyle(.dxPress)
                }
            }
            .padding(.top, 18)
            .dxArrive(2)
        }
    }
}

/// Sound and display: appearance, breathing haptics, Jelli's voice and what widgets show.
struct DisplaySettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(Entitlement.self) private var entitlement
    @AppStorage("dx.sosHaptics") private var haptics = true
    @AppStorage("dx.voiceGuidance") private var voiceGuidance = true
    @AppStorage(WidgetSync.privacyKey) private var widgetPrivacy = false
    @AppStorage(WidgetSync.privacyHomeKey) private var widgetPrivacyHome = false
    @AppStorage(AppearanceSetting.key) private var appearance = AppearanceSetting.automatic.rawValue
    private let ground = DX.Ground.reading

    var body: some View {
        SettingsPage("Sound and display", lead: Text("How DayXero looks, sounds and feels.")) {
            DXList {
                Menu {
                    Picker(selection: $appearance) {
                        ForEach(AppearanceSetting.allCases, id: \.rawValue) { Text($0.title).tag($0.rawValue) }
                    } label: { EmptyView() }
                } label: {
                    SettingsRow(Text("Appearance"), icon: SettingsGlyph.display,
                                value: Text((AppearanceSetting(rawValue: appearance) ?? .automatic).title))
                }
                .buttonStyle(.dxPress)
                SettingsSwitchRow("Breathing haptics", icon: .wave, detail: Text("Other haptics follow System Haptics"), isOn: $haptics)
                SettingsSwitchRow("Voice guidance", icon: .headphones,
                                  detail: entitlement.isPro ? Text("Jelli talks you through SOS") : Text("Comes with the full program"),
                                  isOn: $voiceGuidance)
            }
            .padding(.top, 18)
            .dxArrive(2)
            SettingsSection("Widgets", index: 3)
            DXList {
                SettingsSwitchRow("Private on the Lock Screen", icon: .eye,
                                  detail: Text("Hides money and the word nicotine"), isOn: $widgetPrivacy)
                if widgetPrivacy {
                    SettingsSwitchRow("Home Screen too", icon: .home, isOn: $widgetPrivacyHome)
                }
            }
            .dxArrive(4)
            Text("To add Craving SOS to your Lock Screen, long-press it, tap Customize, then swap the torch or camera button for Craving SOS.")
                .dxType(.caption).foregroundStyle(ground.muted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)
                .padding(.top, 10)
                .dxArrive(5)
        }
        .onChange(of: widgetPrivacy) { WidgetSync.refresh(in: context, isPro: entitlement.isPro) }
        .onChange(of: widgetPrivacyHome) { WidgetSync.refresh(in: context, isPro: entitlement.isPro) }
    }
}
