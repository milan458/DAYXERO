import DayXeroCore
import SwiftData
import SwiftUI
import UIKit

/// The Toolkit tab: everyday craving defence in one place. Your reasons, water (sipping is a good stand-in for the
/// hand-to-mouth habit), Craving SOS and the calm tools.
struct ToolkitView: View {
    let profile: UserProfile

    @Environment(SOSRouter.self) private var sos
    @State private var showWater: Bool
    @State private var showCalmList: Bool
    @State private var openTool: CalmTool?
    @State private var reasonIndex = 0

    init(profile: UserProfile, openWater: Bool = false) {
        self.profile = profile
        let defaults = UserDefaults.standard
        _showWater = State(initialValue: openWater)
        _showCalmList = State(initialValue: defaults.bool(forKey: "dx.openCalmList") || defaults.string(forKey: "dx.openCalm") != nil)
    }

    var body: some View {
        TimelineView(.everyMinute) { timeline in
            ScrollView {
                VStack(alignment: .leading, spacing: DX.Space.xs) {
                    Text("For any moment").dxText(.micro)
                    Text("Toolkit").dxText(.title).accessibilityAddTraits(.isHeader)
                        .padding(.bottom, DX.Space.xs)
                    reasonCard
                    sosCard
                    WaterHomeCard(profile: profile, now: timeline.date, onOpen: { showWater = true })
                    HStack {
                        Text("Calm tools").dxText(.micro)
                        Spacer()
                        Text("Free, always").dxText(.subtitle)
                    }
                    .padding(.top, DX.Space.s)
                    ForEach(CalmTool.allCases) { tool in
                        Button { openTool = tool } label: { CalmToolRow(tool: tool) }.buttonStyle(.plain)
                    }
                    HelpLine().padding(.top, DX.Space.s)
                }
                .padding(.horizontal, DX.Space.m)
                .dxReadableColumn()
                .padding(.top, DX.Space.xl)
                .padding(.bottom, DX.Space.l)
            }
        }
        .fullScreenCover(isPresented: $showWater) {
            WaterTrackerView(profile: profile, onClose: { showWater = false })
        }
        .fullScreenCover(isPresented: $showCalmList) {
            CalmToolsView(onClose: { showCalmList = false }, startSOS: { sos.open(source: "calm") })
        }
        .fullScreenCover(item: $openTool) { tool in
            CalmToolPlayer(tool: tool) { backToSOS in
                openTool = nil
                if backToSOS { sos.open(source: "calm") }
            }
        }
    }

    // MARK: Your why

    private var reasons: [Reason] {
        profile.reasons.sorted { $0.createdAt < $1.createdAt }
    }

    @ViewBuilder
    private var reasonCard: some View {
        if !reasons.isEmpty {
            let reason = reasons[reasonIndex % reasons.count]
            Button {
                withAnimation(DX.Motion.animation(DX.Motion.glide, reduceMotion: false)) { reasonIndex += 1 }
            } label: {
                HStack(alignment: .top, spacing: DX.Space.s) {
                    if let data = reason.photo, let image = UIImage(data: data) {
                        Image(uiImage: image).resizable().scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .accessibilityHidden(true)
                    } else {
                        Image(systemName: "heart").font(.system(size: 20)).foregroundStyle(DX.Palette.accentInk)
                            .frame(width: 48, height: 48).background(DX.Palette.accentSoft, in: Circle())
                            .accessibilityHidden(true)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your why").dxText(.micro)
                        Text(verbatim: reason.text)
                            .font(.custom(DX.Typeface.semibold, size: 17, relativeTo: .body)).foregroundStyle(DX.Palette.text)
                            .multilineTextAlignment(.leading)
                            .contentTransition(.opacity)
                        if reasons.count > 1 {
                            Text("Tap for another · \(reasonIndex % reasons.count + 1) of \(reasons.count)").dxText(.subtitle)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(DX.Space.m)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(DX.Palette.hairline))
            }
            .buttonStyle(.plain)
            .disabled(reasons.count < 2)
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: Craving SOS

    private var sosCard: some View {
        Button { sos.open(source: "toolkit") } label: {
            HStack(spacing: DX.Space.s) {
                Image(systemName: "flame").font(.system(size: 18, weight: .semibold)).foregroundStyle(DX.Palette.onAccent)
                    .frame(width: 48, height: 48).background(DX.Palette.sage, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ride out a craving").font(.custom(DX.Typeface.semibold, size: 16, relativeTo: .body))
                        .foregroundStyle(DX.Palette.text)
                    Text("3 minutes with the breathing orb. Most cravings pass by then.").dxText(.subtitle)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: DX.Space.xs)
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(DX.Palette.muted)
            }
            .padding(14)
            .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(DX.Palette.sage.opacity(0.45)))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("Opens Craving SOS"))
    }
}
