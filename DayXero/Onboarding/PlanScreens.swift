import DayXeroCore
import SwiftUI
import UserNotifications

/// A short "building your plan" moment before the reveal.
struct BuildingScreen: View {
    let model: OnboardingModel
    @State private var done = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var lines: [String] {
        let names = ListFormatter.localizedString(byJoining: model.orderedProducts.map { String(localized: $0.title).lowercased() })
        return [
            String(localized: "Your \(names) program"),
            String(localized: "Prep until \(model.quitDay.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))"),
            String(localized: "Your money and milestones"),
        ]
    }

    var body: some View {
        VStack(spacing: DX.Space.l) {
            Spacer()
            ProgressView()
                .controlSize(.large)
                .tint(DX.Palette.accentInk)
            Text("Building your plan, \(model.name)").dxText(.title).multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: DX.Space.xs) {
                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    Label {
                        Text(line).dxText(.subtitle)
                    } icon: {
                        Image(systemName: index < done ? "checkmark" : "circle")
                            .foregroundStyle(index < done ? DX.Palette.accentInk : DX.Palette.faint)
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, DX.Space.l)
        .accessibilityElement(children: .combine)
        .task {
            for i in 1...lines.count {
                try? await Task.sleep(for: .milliseconds(reduceMotion ? 250 : 600))
                done = i
            }
            try? await Task.sleep(for: .milliseconds(300))
            model.next()
        }
    }
}

struct PlanRevealScreen: View {
    let model: OnboardingModel
    let onContinue: () -> Void

    var body: some View {
        OnboardingScaffold(title: "Quit Day is \(model.quitDay.formatted(.dateTime.weekday(.wide))), \(model.name)",
                           eyebrow: "Your plan") {
            DXGlassCard {
                VStack(alignment: .leading, spacing: DX.Space.xxs) {
                    Text("Money you'll keep in a year").dxText(.micro)
                    Text(model.stats.moneyPerYear, format: .currency(code: model.currencyCode).precision(.fractionLength(0)))
                        .dxText(.hero)
                    Text("Based on what you told us you spend").dxText(.subtitle)
                }
            }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: DX.Space.xs), GridItem(.flexible())], spacing: DX.Space.xs) {
                ForEach(model.orderedProducts, id: \.self) { product in
                    DXCard(padding: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(Text(product.unit)) a day").dxText(.micro)
                            Text("\(Int(model.baseline(for: product).unitsPerDay)) → 0").dxText(.cardHeading)
                                .font(.custom(DX.Typeface.bold, size: 18, relativeTo: .headline))
                        }
                    }
                }
            }
            DXCard(padding: 14) {
                VStack(alignment: .leading, spacing: DX.Space.xs) {
                    Text(PlanTimeline.isLong(prepDays: model.prepDays) ? "Up to Quit Day" : "Your week ahead").dxText(.micro)
                    ForEach(timeline, id: \.date) { item in
                        HStack(spacing: 10) {
                            Text(item.badge)
                                .font(.custom(DX.Typeface.bold, size: 11, relativeTo: .caption2))
                                .foregroundStyle(item.isQuitDay ? DX.Palette.onPrimary : DX.Palette.accentInk)
                                .frame(width: 26, height: 26)
                                .background(item.isQuitDay ? DX.Palette.primary : DX.Palette.accentSoft, in: Circle())
                            Text(item.title)
                                .font(.custom(item.isQuitDay ? DX.Typeface.semibold : DX.Typeface.regular, size: 13, relativeTo: .footnote))
                                .foregroundStyle(item.isMore ? DX.Palette.text2 : DX.Palette.text)
                            Spacer()
                            if !item.isMore {
                                // Past the first week the weekday alone would be ambiguous, so Quit Day shows its date.
                                let full = item.isQuitDay && PlanTimeline.isLong(prepDays: model.prepDays)
                                Text(item.date, format: full ? Date.FormatStyle.dateTime.weekday(.abbreviated).day().month(.abbreviated)
                                                             : Date.FormatStyle.dateTime.weekday(.abbreviated))
                                    .dxText(.subtitle)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            // The one-line health disclaimer, before the paywall (S15.6).
            Text(HealthInfoView.oneLine).dxText(.subtitle).frame(maxWidth: .infinity).multilineTextAlignment(.center)
        } footer: {
            Button("Continue", action: onContinue).buttonStyle(.dxPrimary)
        }
    }

    private struct TimelineItem {
        let date: Date
        let badge: String
        let title: String
        let isQuitDay: Bool
        let isMore: Bool
    }

    /// The days from today to Quit Day (Day 1 starts today), never skipping one silently.
    /// Lesson titles arrive with the ported content.
    private var timeline: [TimelineItem] {
        let today = Calendar.current.startOfDay(for: .now)
        return PlanTimeline.items(prepDays: model.prepDays, today: today).map { item in
            switch item.kind {
            case let .prep(n):
                TimelineItem(date: item.date, badge: "\(n)", title: String(localized: "Prep day \(n)"), isQuitDay: false, isMore: false)
            case let .morePrep(count):
                TimelineItem(date: item.date, badge: "…", title: String(localized: "+\(count) more prep days"), isQuitDay: false, isMore: true)
            case .quitDay:
                TimelineItem(date: item.date, badge: "Q", title: String(localized: "Quit Day"), isQuitDay: true, isMore: false)
            case let .clear(n):
                TimelineItem(date: item.date, badge: "\(n)", title: String(localized: "Day \(n) clear"), isQuitDay: false, isMore: false)
            }
        }
    }
}

struct RemindersScreen: View {
    let onDone: () -> Void
    @State private var asking = false

    var body: some View {
        OnboardingScaffold(title: "A nudge when it helps",
                           subtitle: "Each day's lesson, your Quit Day countdown and milestones. Never guilt, and you choose the times.") {
            Image(systemName: "bell")
                .font(.system(size: 30))
                .foregroundStyle(DX.Palette.accentInk)
                .frame(width: 76, height: 76)
                .background(DX.Palette.accentSoft, in: Circle())
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityHidden(true)
            preview(title: "Day 2 is ready", body: "Your next lesson is waiting.", time: "9:00")
            preview(title: "3 days until Quit Day", body: "You've finished every prep day so far.", time: "Tue")
        } footer: {
            Button("Turn on reminders") {
                asking = true
                Task {
                    _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                    onDone()
                }
            }
            .buttonStyle(.dxPrimary)
            .disabled(asking)
            Button("Not now", action: onDone).buttonStyle(.dxQuiet)
        }
    }

    private func preview(title: LocalizedStringKey, body: LocalizedStringKey, time: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Color.black)
                .frame(width: 34, height: 34)
                .overlay(Circle().fill(DX.Palette.sage).frame(width: 10, height: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.custom(DX.Typeface.semibold, size: 13, relativeTo: .footnote)).foregroundStyle(DX.Palette.text)
                Text(body).dxText(.subtitle)
            }
            Spacer()
            Text(verbatim: time).font(.custom(DX.Typeface.regular, size: 11, relativeTo: .caption2)).foregroundStyle(DX.Palette.muted)
        }
        .padding(DX.Space.s)
        .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(DX.Palette.hairline))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Example reminder: \(Text(title))"))
    }
}
