import DayXeroCore
import SwiftData
import SwiftUI
import UIKit

// The Evening tab is gone (S27.11, 1 Nov 2026): its check-in card and wind-down now come up on Today in the evening
// and at night, and the calm tools open from Today and Craving SOS. Wind down stays here: it follows a saved check-in.

/// F17 Wind down (violet, Glim). After a check-in it opens with "Check-in saved / Rest well."; as the Evening tab
/// it leads with tonight's check-in when there hasn't been one.
struct WindDownView: View {
    let profile: UserProfile
    /// Shown straight after saving a check-in, with Done.
    let savedJustNow: Bool
    let onClose: (() -> Void)?
    var showWater: (() -> Void)?
    var startSOS: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var checkIns: [CheckIn]
    @State private var openTool: CalmTool?
    @State private var breathing = false
    @State private var checkingIn = false
    @State private var reasonIndex = 0
    @State private var shown = false

    private let ground = DX.Ground.violet

    /// Box breathing first and the longer out-breath (4-7-8) last, as the design asks.
    private static let order: [CalmTool] = [.boxBreathing, .grounding, .noticeAndName, .dropAnchor, .longerOutBreath]

    var body: some View {
        TimelineView(.everyMinute) { timeline in
            let now = timeline.date
            let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
            let checkedIn = DailyRhythm(clock: clock).hasCheckedIn(checkIns.map(\.day), at: now)
            let stats = ProgressStats(quitDay: profile.quitDay, baselines: [], clock: clock)
            let prep = stats.isPrep(at: now)
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ZStack(alignment: .bottom) {
                            HeroScene(.night, clarity: prep ? CrewGrowth.prepClarity : CrewGrowth.clarity(daysClear: stats.daysClear(at: now)),
                                      height: 240, edge: ground.background)
                            GlimView(mood: .sleepy, stage: CrewGrowth.stage(daysClear: prep ? 0 : stats.daysClear(at: now)), size: .scene)
                                .offset(y: shown || reduceMotion ? -10 : -40)
                                .opacity(shown ? 1 : 0)
                                .accessibilityHidden(true)
                        }
                        .padding(.horizontal, -DX.Layout.gutter)
                        .ignoresSafeArea(edges: .top)
                        header(checkedIn: checkedIn).dxArrive(3)
                        if !checkedIn && !savedJustNow {
                            ColourCard(kicker: String(localized: "With Glim · 1 min"), title: String(localized: "How was today, really?"),
                                       detail: String(localized: "One question, then rest."), fill: ColourCard.glim) { checkingIn = true }
                                .dxArrive(4)
                        }
                        tonight.dxArrive(5)
                        tools.dxArrive(6)
                        if !savedJustNow { extras(now: now).dxArrive(7) }
                        helpLine.dxArrive(8)
                    }
                    .padding(.horizontal, DX.Layout.gutter)
                    .padding(.bottom, DX.Space.l)
                }
                .scrollBounceBehavior(.basedOnSize)
                if let onClose {
                    Button("Done", action: onClose)
                        .buttonStyle(.dx(.primary, on: ground))
                        .padding(.horizontal, DX.Layout.buttonGutter)
                        .padding(.bottom, DX.Space.xs)
                }
            }
            .dxReadableColumn()
        }
        .foregroundStyle(ground.ink)
        .background(ground.background.ignoresSafeArea())
        .onAppear {
            withAnimation(DX.Move.animation(DX.Move.settle, reduceMotion: reduceMotion)) { shown = true }
        }
        .fullScreenCover(item: $openTool) { tool in
            CalmToolPlayer(tool: tool) { backToSOS in
                openTool = nil
                if backToSOS { startSOS?() }
            }
        }
        .fullScreenCover(isPresented: $breathing) {
            GlimBreathingView { breathing = false }
        }
        .fullScreenCover(isPresented: $checkingIn) {
            CheckInView(profile: profile) { checkingIn = false }
        }
    }

    private func header(checkedIn: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(checkedIn || savedJustNow ? "Check-in saved" : "Evening")
                .dxFont(14, weight: 700, style: .footnote).foregroundStyle(ground.muted)
            Text(checkedIn || savedJustNow ? "Rest well." : "Wind down with Glim.")
                .dxType(.large).foregroundStyle(ground.ink)
                .accessibilityAddTraits(.isHeader)
            Text(checkedIn || savedJustNow
                 ? "Tomorrow's pledge will be here in the morning. If tonight feels restless, breathe with me."
                 : "A slow breath, a calm tool, then rest. I'm here if tonight feels restless.")
                .dxType(.body).foregroundStyle(ground.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The tool for tonight: slow breathing with Glim, on the same 4 in, 6 out rhythm as SOS.
    private var tonight: some View {
        Button { breathing = true } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("For tonight · 3 min").dxType(.caption).textCase(.uppercase).foregroundStyle(Color(hex: 0x4A3596))
                    Text("Slow breathing with Glim").dxType(.headline).foregroundStyle(DX.Fill.navy)
                    Text("In for 4, out for 6. The same rhythm as SOS.").dxType(.footnote).foregroundStyle(Color(hex: 0x3A2A7A))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "play.fill").font(.system(size: 16, weight: .bold)).foregroundStyle(DX.Fill.cream)
                    .frame(width: 44, height: 44)
                    .background(Color(hex: 0x4A3596), in: Circle())
                    .accessibilityHidden(true)
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous)
                    .fill(DX.Fill.cream)
                    .shadow(color: .black.opacity(0.14), radius: 0, x: 0, y: 5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    private var tools: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(Self.order.enumerated()), id: \.element) { index, tool in
                if index > 0 { Rectangle().fill(ground.ink.opacity(0.14)).frame(height: 1) }
                Button { openTool = tool } label: {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tool.title).dxFont(16, weight: 700, style: .body).foregroundStyle(ground.ink)
                            Text(tool.detail).dxType(.footnote).foregroundStyle(ground.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(tool.minutes) min").dxType(.caption).foregroundStyle(ground.muted)
                    }
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.horizontal, 14)
        .background(DX.Fill.onColourCard(for: ground), in: RoundedRectangle(cornerRadius: DX.Layout.smallCardRadius, style: .continuous))
    }

    /// One of their reasons (tap for the next) and today's water, both kept from the old Toolkit.
    @ViewBuilder
    private func extras(now: Date) -> some View {
        let reasons = profile.reasons.sorted { $0.createdAt < $1.createdAt }
        if !reasons.isEmpty {
            let reason = reasons[reasonIndex % reasons.count]
            Button { reasonIndex += 1 } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your reason").dxType(.caption).textCase(.uppercase).foregroundStyle(ground.muted)
                        Text(verbatim: reason.text).dxFont(19, weight: 700, style: .headline).foregroundStyle(ground.ink)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if let data = reason.photo, let image = UIImage(data: data) {
                        Image(uiImage: image).resizable().scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .accessibilityHidden(true)
                    }
                }
                .padding(14)
                .background(DX.Fill.onColourCard(for: ground), in: RoundedRectangle(cornerRadius: DX.Layout.smallCardRadius, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(reasons.count < 2)
            .accessibilityElement(children: .combine)
            .accessibilityHint(reasons.count > 1 ? Text("Shows your next reason") : Text(verbatim: ""))
        }
        if let showWater {
            Button(action: showWater) {
                HStack {
                    Label("Water", systemImage: "drop").dxFont(16, weight: 700, style: .body).foregroundStyle(ground.ink)
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(ground.muted)
                        .accessibilityHidden(true)
                }
                .padding(14)
                .frame(minHeight: 48)
                .background(DX.Fill.onColourCard(for: ground), in: RoundedRectangle(cornerRadius: DX.Layout.smallCardRadius, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    /// The plain line pointing to professional help (S12.3).
    private var helpLine: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("These tools aren't a substitute for professional help. If things feel like too much, \(Text("[find a helpline near you](https://findahelpline.com)").underline()).")
                .dxType(.footnote)
                .foregroundStyle(ground.muted)
                .tint(ground.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, DX.Space.xs)
    }
}

/// Slow breathing with Glim: 4 in, 6 out, for about three minutes. It ends when they want; the time counts up.
struct GlimBreathingView: View {
    let onDone: () -> Void
    @State private var startedAt = Date.now
    @AppStorage("dx.sosHaptics") private var hapticsOn = true

    private let ground = DX.Ground.violet

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Spacer()
                Button(action: onDone) {
                    Image(systemName: "xmark").font(.system(size: 18, weight: .bold)).foregroundStyle(ground.ink)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Close"))
            }
            Spacer()
            GlimView(mood: .breathe, stage: 1, size: .hero).accessibilityHidden(true)
            BreathingWords().foregroundStyle(ground.ink)
            TimelineView(.periodic(from: startedAt, by: 1)) { timeline in
                let seconds = max(0, Int(timeline.date.timeIntervalSince(startedAt)))
                Text(seconds >= 180 ? String(localized: "Three minutes. Rest well.")
                     : String(format: "%d:%02d", seconds / 60, seconds % 60))
                    .dxType(.body).foregroundStyle(ground.muted).monospacedDigit()
            }
            Spacer()
            Button("Done", action: onDone)
                .buttonStyle(.dx(.primary, on: ground))
        }
        .padding(.horizontal, DX.Layout.buttonGutter)
        .padding(.bottom, DX.Space.xs)
        .dxReadableColumn()
        .background(ground.background.ignoresSafeArea())
        .sosBreathHaptics(hapticsOn)
    }
}
