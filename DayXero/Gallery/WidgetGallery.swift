#if DEBUG
import DayXeroCore
import SwiftUI
import WidgetKit

/// Every widget at its real size in each rendering mode, for side-by-side checks against `reference/widgets/`
/// (`-dx.widgetGallery home|clear|lock|private|standby|states`). Debug builds only.
struct WidgetGallery: View {
    let page: String
    private let sample = WidgetSnapshot.sample()

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                switch page {
                case "clear": home(.accented)
                case "lock": lock(sample)
                case "private": lock(privateSample)
                case "standby": standBy
                case "states": states
                default: home(.fullColor)
                }
            }
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity)
        }
        .background(background.ignoresSafeArea())
        .environment(\.colorScheme, .dark)
    }

    private var background: some View {
        Group {
            switch page {
            case "clear":
                LinearGradient(colors: [Color(hex: 0x5E7487), Color(hex: 0xC48A62), Color(hex: 0x7B6AA0)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case "standby": Color.black
            default:
                RadialGradient(colors: [Color(hex: 0x3A4A1A), Color(hex: 0x0E110B)], center: .topTrailing, startRadius: 40, endRadius: 700)
            }
        }
    }

    private var privateSample: WidgetSnapshot {
        var s = sample
        s.privacyMode = true
        return s
    }

    private func home(_ mode: WidgetRenderingMode) -> some View {
        VStack(spacing: 18) {
            HStack(spacing: 18) {
                tile(.small, mode) { DayCounterWidgetView(snapshot: sample, family: .systemSmall, mode: mode) }
                tile(.small, mode) { SOSWidgetView(snapshot: sample, family: .systemSmall, mode: mode) }
            }
            tile(.medium, mode) { TodayWidgetView(snapshot: sample, mode: mode) }
            HStack(spacing: 18) {
                tile(.small, mode) { WaterWidgetView(snapshot: sample, family: .systemSmall, mode: mode) }
                tile(.small, mode) { ForecastWidgetView(snapshot: sample, family: .systemSmall, mode: mode, date: .now) }
            }
        }
    }

    private func lock(_ s: WidgetSnapshot) -> some View {
        VStack(spacing: 14) {
            DayCounterWidgetView(snapshot: s, family: .accessoryInline, mode: .vibrant)
                .font(.system(size: 17, weight: .semibold))
            Text(Date.now, format: .dateTime.hour().minute()).font(.system(size: 86, weight: .bold)).foregroundStyle(.white.opacity(0.92))
            HStack(spacing: 12) {
                ForecastWidgetView(snapshot: s, family: .accessoryRectangular, mode: .vibrant, date: .now)
                    .frame(width: 158, height: 72)
                    .padding(.horizontal, 10)
                    .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                WaterWidgetView(snapshot: s, family: .accessoryCircular, mode: .vibrant).frame(width: 72, height: 72)
                SOSWidgetView(snapshot: s, family: .accessoryCircular, mode: .vibrant).frame(width: 72, height: 72)
            }
        }
        .foregroundStyle(.white)
    }

    private var standBy: some View {
        HStack(spacing: 20) {
            DayCounterWidgetView(snapshot: sample, family: .systemSmall, mode: .fullColor, standBy: true)
                .frame(width: 430, height: 340)
        }
        .rotationEffect(.degrees(0))
        .scaleEffect(0.82)
    }

    /// Phase and empty states (S17.12).
    private var states: some View {
        var before = sample
        before.phase = .beforeDay1
        before.nextWindow = nil
        var prep = sample
        prep.phase = .prep
        prep.prepDay = 3
        prep.daysUntilQuitDay = 4
        var quitDay = sample
        quitDay.daysFree = 1
        var noWindow = sample
        noWindow.nextWindow = nil
        return VStack(spacing: 18) {
            HStack(spacing: 18) {
                tile(.small, .fullColor) { DayCounterWidgetView(snapshot: before, family: .systemSmall, mode: .fullColor) }
                tile(.small, .fullColor) { DayCounterWidgetView(snapshot: prep, family: .systemSmall, mode: .fullColor) }
            }
            HStack(spacing: 18) {
                tile(.small, .fullColor) { DayCounterWidgetView(snapshot: quitDay, family: .systemSmall, mode: .fullColor) }
                tile(.small, .fullColor) { ForecastWidgetView(snapshot: noWindow, family: .systemSmall, mode: .fullColor, date: .now) }
            }
            tile(.medium, .fullColor) { TodayWidgetView(snapshot: noWindow, mode: .fullColor) }
            tile(.small, .fullColor) { ForecastWidgetView(snapshot: before, family: .systemSmall, mode: .fullColor, date: .now) }
        }
    }

    private enum Size { case small, medium }

    private func tile<Content: View>(_ size: Size, _ mode: WidgetRenderingMode, @ViewBuilder _ content: () -> Content) -> some View {
        content()
            .frame(width: size == .small ? 170 : 364, height: 170)
            .background(mode == .fullColor ? WidgetTone.background : Color.white.opacity(0.16),
                        in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(mode == .fullColor ? .clear : .white.opacity(0.35), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
#endif
