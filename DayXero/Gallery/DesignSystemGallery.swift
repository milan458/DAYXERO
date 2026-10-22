import DayXeroCore
import SwiftUI

/// Section 1 deliverable: every token and component on one scrollable screen, in both themes.
struct DesignSystemGallery: View {
    @State private var appearance: ColorScheme? = nil
    @State private var chips: [String: Bool] = ["Cigarettes": true, "Vape": true, "Pouches": false, "Already using NRT": false]
    @State private var amount = ""
    @State private var intensity = 5
    @State private var tab = "today"

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: DX.Space.xxxl) {
                    header
                    colours
                    type
                    buttons
                    chipsAndInputs
                    cards
                    DXCard { DXCravingSlider(value: $intensity) }
                    DXCard { DXWeekStrip(days: Self.sampleWeek) }
                    rows
                    DXTimerBanner("Craving wave", endDate: .now.addingTimeInterval(CravingSession.length))
                    states
                }
                .padding(.horizontal, DX.Space.m)
                .padding(.top, DX.Space.xl)
                .padding(.bottom, 140)
            }
            DXDock(
                items: [
                    DXDockItem(id: "today", title: "Today", systemImage: "house"),
                    DXDockItem(id: "program", title: "Program", systemImage: "book.closed"),
                    DXDockItem(id: "progress", title: "Progress", systemImage: "chart.bar"),
                ],
                selection: $tab,
                sosAction: {}
            )
            .padding(.bottom, DX.Space.xs)
        }
        .dxCanvas()
        .preferredColorScheme(appearance)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DX.Space.s) {
            Text("Section 1 · design system").dxText(.micro)
            Text("DayXero").dxText(.title)
            Picker("Appearance", selection: $appearance) {
                Text("System").tag(ColorScheme?.none)
                Text("Dark").tag(ColorScheme?.some(.dark))
                Text("Light").tag(ColorScheme?.some(.light))
            }
            .pickerStyle(.segmented)
        }
    }

    private var colours: some View {
        section("Colour") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: DX.Space.s)], spacing: DX.Space.s) {
                swatch("Canvas", DX.Palette.canvas)
                swatch("Primary", DX.Palette.primary)
                swatch("Sage", DX.Palette.sage)
                swatch("Sage ink", DX.Palette.accentInk)
                swatch("Moss", DX.Palette.moss)
                swatch("Surface 1", DX.Palette.surface1)
                swatch("Surface 2", DX.Palette.surface2)
                swatch("Surface 3", DX.Palette.surface3)
                swatch("Amber", DX.Palette.amber)
                swatch("Terracotta", DX.Palette.terracotta)
            }
        }
    }

    private var type: some View {
        section("Type") {
            DXFraction(3, of: 7, unit: "days")
            Text("Your Quit Day plan").dxText(.title)
            Text("Day 3 · Riding out the urge").dxText(.cardHeading)
            Text("Rode out a craving 2h ago").dxText(.subtitle)
            Text("Money kept").dxText(.micro)
            Text("Start today's lesson").dxText(.button)
        }
    }

    private var buttons: some View {
        section("Buttons") {
            Button("Commit to my Quit Day") {}.buttonStyle(.dxPrimary)
            Button("Disabled") {}.buttonStyle(.dxPrimary).disabled(true)
            HStack(spacing: DX.Space.s) {
                Button("Skip for now") {}.buttonStyle(.dxSecondary)
                Button("It passed") {}.buttonStyle(.dxSage)
                Button("Not now") {}.buttonStyle(.dxQuiet)
            }
            HStack(spacing: DX.Space.s) {
                Button {} label: { Image(systemName: "gearshape").accessibilityLabel(Text("Settings")) }
                    .buttonStyle(.dxIcon)
                Button {} label: { Image(systemName: "plus").accessibilityLabel(Text("Add")) }
                    .buttonStyle(DXFABStyle(.primary))
                Button {} label: { Image(systemName: "flame").accessibilityLabel(Text("Craving SOS")) }
                    .buttonStyle(DXFABStyle(.sage))
            }
        }
    }

    private var chipsAndInputs: some View {
        section("Chips & inputs") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DX.Space.xs) {
                    ForEach(["Cigarettes", "Vape", "Pouches", "Already using NRT"], id: \.self) { name in
                        DXChip(LocalizedStringKey(name), isOn: Binding(
                            get: { chips[name] ?? false },
                            set: { chips[name] = $0 }
                        ))
                    }
                }
            }
            DXTextField("Puffs per day", prompt: "e.g. 200", text: $amount)
                .keyboardType(.numberPad)
        }
    }

    private var cards: some View {
        section("Cards & progress") {
            DXGlassCard {
                VStack(alignment: .leading, spacing: DX.Space.xxs) {
                    Text("Days clear").dxText(.micro)
                    DXFraction(3, of: 7)
                    Text("Day 4 unlocks when you finish today").dxText(.subtitle)
                    DXMetric("Program", value: "43%", progress: 0.43, tint: .primary).padding(.top, DX.Space.m)
                }
            }
            DXCard {
                VStack(spacing: DX.Space.m) {
                    DXMetric("Money kept", value: "$42.50", progress: 0.62)
                    DXMetric("Puffs not taken", value: "1,840", progress: 0.8)
                    DXMetric("Cravings ridden out", value: "12", progress: 0.35)
                }
            }
            DXCapsuleCard {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Next milestone").dxText(.micro)
                        Text("One full week clear · in 4 days").dxText(.cardHeading)
                    }
                    Spacer()
                    Image(systemName: "drop")
                        .foregroundStyle(DX.Palette.accentInk)
                        .frame(width: 44, height: 44)
                        .background(DX.Palette.accentSoft, in: Circle())
                        .accessibilityHidden(true)
                }
            }
        }
    }

    private var rows: some View {
        section("List row") {
            List {
                DXListRow("Morning craving", subtitle: "8:12 · after coffee") {
                    Image(systemName: "sun.max").foregroundStyle(DX.Palette.text)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
                .swipeActions {
                    Button("Delete", systemImage: "xmark") {}.tint(DX.Palette.actionDelete)
                    Button("Edit", systemImage: "pencil") {}.tint(DX.Palette.actionEdit)
                    Button("Rode it out", systemImage: "checkmark") {}.tint(DX.Palette.actionDone)
                }
            }
            .listStyle(.plain)
            .scrollDisabled(true)
            .frame(height: 64)
        }
    }

    private var states: some View {
        section("Empty, loading, error") {
            DXCard {
                VStack(alignment: .leading, spacing: DX.Space.s) {
                    Text("Loading").dxText(.micro)
                    DXSkeleton(width: 120, height: 14)
                    DXSkeleton(width: 220, height: 28)
                    DXSkeleton(height: 6)
                }
            }
            DXCard {
                DXStateView(.empty, systemImage: "chart.bar", title: "Insights need a week",
                            message: "Log cravings as they come. Your patterns show up here after 7 days.")
            }
            DXCard {
                DXStateView(.error, systemImage: "exclamationmark.circle", title: "Couldn't load your plan",
                            message: "Nothing's lost. Your progress is saved on this phone.",
                            actionTitle: "Try again", action: {})
            }
        }
    }

    private func section<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DX.Space.m) {
            Text(title).dxText(.title).accessibilityAddTraits(.isHeader)
            content()
        }
    }

    private func swatch(_ name: LocalizedStringKey, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: DX.Space.xs) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(color)
                .frame(height: 56)
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(DX.Palette.hairline))
            Text(name).dxText(.subtitle).lineLimit(1).minimumScaleFactor(0.5)
        }
        .accessibilityElement(children: .combine)
    }

    private static var sampleWeek: [DXWeekDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let states: [DXDayState] = [.prep, .prep, .clear, .clear, .clear, .today, .upcoming]
        return states.enumerated().map { offset, state in
            DXWeekDay(date: calendar.date(byAdding: .day, value: offset - 5, to: today) ?? today, state: state)
        }
    }
}

#Preview("Dark") {
    DesignSystemGallery().preferredColorScheme(.dark)
}

#Preview("Light") {
    DesignSystemGallery().preferredColorScheme(.light)
}

#Preview("Largest text") {
    DesignSystemGallery().environment(\.dynamicTypeSize, .accessibility3)
}
