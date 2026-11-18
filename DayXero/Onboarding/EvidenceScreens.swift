import DayXeroCore
import SwiftUI

// The evidence story's own screens (18 Nov 2026, canvas page "Evidence story"). They ask nothing, except the
// pregnancy question, which moved here from the NRT screen.

/// The dock under an evidence screen: one primary button over the ground's fade.
private struct EvDock: View {
    let title: LocalizedStringKey
    let model: OnboardingModel

    var body: some View {
        ContinueButton(title: title, model: model)
            .padding(.horizontal, DX.Layout.buttonGutter)
            .dxReadableColumn()
            .padding(.top, 28)
            .padding(.bottom, DX.Space.xs)
            .background {
                let g = DX.Ground.apricot.background
                LinearGradient(stops: [.init(color: g.opacity(0), location: 0), .init(color: g, location: 0.34)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea(edges: .bottom)
            }
    }
}

// MARK: Good company · after Products

/// "2 in 3 people who smoke want to quit": the dawn in a disc with Xero, the number, one small Xero per person (the
/// ones who don't want to quit are greyed), and the line under it. People who vape get the vaping figure; for pouches
/// there's no number to give, so there's a welcome instead.
///
/// Motion: the disc pops in, Xero settles, then the number, the row of Xeros (60 ms apart), the lines and the source.
struct GoodCompanyScreen: View {
    let model: OnboardingModel
    @State private var research = false
    @Environment(\.colorScheme) private var scheme
    private let motion = MotionPolicy()

    private struct Copy {
        var stat: (of: Int, total: Int)? = nil
        let line: LocalizedStringKey
        let sub: LocalizedStringKey
        var source: LocalizedStringKey? = nil
    }

    private var copy: Copy {
        switch model.evidenceProduct {
        case .cigarettes:
            Copy(stat: (2, 3), line: "people who smoke want to quit",
                 sub: "Wanting to stop is the normal thing. Staying stopped is the hard part, so that is what we will plan for.",
                 source: "CDC, 2022 survey of US adults")
        case .vape:
            Copy(stat: (6, 10), line: "adults who vape intend to quit",
                 sub: "You are in good company. Research on quitting vapes is still early, so when a fact comes from smoking research, I will say so.",
                 source: "US PATH Study, 2017 to 2018")
        case .pouches:
            Copy(line: "Good to have you here",
                 sub: "Research on quitting pouches is still thin. When a fact comes from smoking research, I will say so, and the rest of your plan is built from your own answers.")
        }
    }

    var body: some View {
        let copy = self.copy
        return GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    disc.dxPop(delay: 0.1)
                    if let stat = copy.stat {
                        Text("\(stat.of) in \(stat.total)")
                            .dxFace(.display, 76, weight: 800, tracking: -3)
                            .foregroundStyle(Onb.ink)
                            .lineLimit(1).minimumScaleFactor(0.6)
                            .padding(.top, 14)
                            .accessibilityAddTraits(.isHeader)
                            .dxArrive(1)
                        people(stat).padding(.top, 2)
                        Text(copy.line)
                            .dxFace(.display, 26, weight: 800, tracking: -0.7)
                            .foregroundStyle(Onb.ink)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 28)
                            .padding(.top, 8)
                            .dxArrive(3)
                    } else {
                        Text(copy.line)
                            .dxFace(.display, 30, weight: 800, tracking: -0.9)
                            .foregroundStyle(Onb.ink)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 26)
                            .accessibilityAddTraits(.isHeader)
                            .dxArrive(1)
                    }
                    Text(copy.sub)
                        .dxType(.body).foregroundStyle(Onb.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 14)
                        .dxArrive(4)
                    if let source = copy.source {
                        EvSourceLink(text: source) { research = true }
                            .padding(.top, 10)
                            .dxArrive(5)
                    }
                }
                .padding(.horizontal, 26)
                .padding(.vertical, 12)
                .dxReadableColumn()
                .frame(minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { EvDock(title: "Continue", model: model) }
        .researchSheet(isPresented: $research, product: model.evidenceProduct)
    }

    /// The dawn in a 248 pt disc, a soft halo low behind Xero, and Xero standing in front.
    private var disc: some View {
        let dark = scheme == .dark
        return ZStack(alignment: .topLeading) {
            Group {
                if dark {
                    NightSky(dawn: true, animate: !motion.reduce,
                             options: .init(sunAt: 0.5, sunScale: 0, sunLift: 10, softSun: true, stars: false, fade: true))
                } else {
                    HorizonScene(.dawn, clarity: 100, fit: .bottom, animate: !motion.reduce,
                                 sun: .init(x: 250, radius: 0, drop: -10, clouds: false))
                }
            }
            .frame(width: 248, height: 248)
            .background(Color(light: 0xFFD3A6, dark: 0x1F2950))
            .overlay(alignment: .topLeading) {
                Circle()
                    .fill(RadialGradient(colors: [dark ? Color(hex: 0xFFB060).opacity(0.42) : Color(hex: 0xFFF6CE).opacity(0.85), .clear],
                                         center: .center, startRadius: 0, endRadius: 110))
                    .frame(width: 220, height: 220)
                    .offset(x: 14, y: 52)
            }
            .clipShape(Circle())
            .overlay { if dark { Circle().strokeBorder(Color.white.opacity(0.14), lineWidth: 1.5) } }
            .shadow(color: dark ? Color(hex: 0xFF965A).opacity(0.1) : Color(hex: 0xBE5428).opacity(0.2), radius: 16, y: dark ? 0 : 12)
            Ellipse()
                .fill(RadialGradient(colors: [dark ? Color.black.opacity(0.55) : Color(hex: 0x50140A).opacity(0.35), .clear],
                                     center: .center, startRadius: 0, endRadius: 48))
                .frame(width: 96, height: 15)
                .offset(x: 70, y: 204)
            XeroView(mood: .hello, stage: 0, points: 120, animate: !motion.reduce)
                .shadow(color: dark ? Color(hex: 0xFFAA5A).opacity(0.45) : Ev.cream.opacity(0.95), radius: dark ? 8 : 2.5,
                        x: dark ? 4 : 0, y: dark ? -2 : 0)
                .shadow(color: dark ? .clear : Color(hex: 0x781E0A).opacity(0.22), radius: 10, y: 6)
                .frame(width: 120, height: 120)
                .offset(x: 58, y: 96)
                .dxSettle(delay: 0.35)
        }
        .frame(width: 248, height: 248)
        .accessibilityHidden(true)
    }

    /// One small Xero per person; the ones past the count are greyed.
    private func people(_ stat: (of: Int, total: Int)) -> some View {
        let dark = scheme == .dark
        let size: CGFloat = stat.total > 5 ? 30 : 60
        return HStack(spacing: stat.total > 5 ? 2 : 4) {
            ForEach(0..<stat.total, id: \.self) { i in
                XeroView(mood: .hello, stage: 0, points: size, animate: false)
                    .frame(width: size, height: size)
                    .saturation(i < stat.of ? 1 : 0)
                    .brightness(i < stat.of ? 0 : (dark ? 0.05 : 0.2))
                    .contrast(i < stat.of ? 1 : (dark ? 0.8 : 0.6))
                    .opacity(i < stat.of ? 1 : (dark ? 0.5 : 0.6))
                    .dxPop(0, delay: 0.5 + Double(i) * 0.06)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: What works · after Your baseline

/// "Two things change the odds": Xero holding a patch in one hand and a speech bubble in the other, the two
/// ingredients named under them, and what trials found when people combined them. The line under the card says
/// plainly that the support in those trials came from trained advisers and that DayXero itself hasn't been trialled.
///
/// Motion: the title, the card, then Xero settles with the patch and the bubble popping in at his hands.
struct WhatWorksScreen: View {
    let model: OnboardingModel
    @State private var research = false
    @Environment(\.colorScheme) private var scheme
    private let motion = MotionPolicy()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Two things")
                    MarkedTitle(String(localized: "change the "), marking: String(localized: "odds"), color: DX.Mark.color(on: .apricot))
                }
                .dxType(.large).foregroundStyle(Onb.ink)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Two things change the odds"))
                .accessibilityAddTraits(.isHeader)
                .dxArrive(0)
                card.padding(.top, 22).dxArrive(1)
                VStack(spacing: 8) {
                    Text("That support came from trained advisers, not an app. DayXero uses the same two ingredients and hasn’t been tested in a clinical trial itself.")
                    if model.evidenceIsFromSmoking {
                        Text("Those trials were in people quitting cigarettes. For vapes and pouches the research is still early.")
                    }
                }
                .dxFace(.body, 14, weight: 500).foregroundStyle(Onb.muted)
                .lineSpacing(3)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .dxArrive(3)
            }
            .padding(.horizontal, DX.Layout.gutter)
            .dxReadableColumn()
            .padding(.top, DX.Space.m)
            .padding(.bottom, DX.Space.m)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) { EvDock(title: "Build my plan", model: model) }
        .researchSheet(isPresented: $research, product: model.evidenceProduct)
    }

    private var card: some View {
        VStack(spacing: 0) {
            art
            HStack(alignment: .top, spacing: 30) {
                ingredient("A stop-smoking\nmedicine", "Like a nicotine patch or gum")
                ingredient("Steady\nsupport", "A plan, a daily check-in, help in the moment")
            }
            .padding(.top, 12)
            Rectangle().fill(Ev.line).frame(height: 1).padding(.vertical, 12)
            VStack(spacing: 4) {
                (Text("about ").dxRun(22, weight: 700, family: .display) + Text(verbatim: "80%"))
                    .dxFace(.display, 46, weight: 800, tracking: -1.6)
                    .foregroundStyle(Onb.ink)
                Text("more likely to quit").dxFace(.display, 19, weight: 700, tracking: -0.3).foregroundStyle(Onb.ink)
                Text("in trials, when people combined the two, compared with brief advice or lighter support")
                    .dxFace(.body, 14, weight: 500).foregroundStyle(Onb.muted)
                    .lineSpacing(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
            .accessibilityElement(children: .combine)
            EvSourceLink(text: "Cochrane review of 52 trials, 2016") { research = true }
                .padding(.top, 6)
        }
        .padding(.top, 14).padding(.horizontal, 16).padding(.bottom, 4)
        .frame(maxWidth: .infinity)
        .evCard(radius: 24)
    }

    /// Xero in front of a low sun, a patch in his left hand and a ticked speech bubble in his right.
    private var art: some View {
        ZStack(alignment: .top) {
            UnevenRoundedRectangle(topLeadingRadius: 108, topTrailingRadius: 108)
                .fill(Color(light: 0xFFE9B8, dark: 0x2A3554))
                .frame(width: 216, height: 108)
                .offset(y: 28)
            XeroView(mood: .hello, stage: 0, points: 134, animate: !motion.reduce, pose: .hold)
                .frame(width: 134, height: 134)
                .offset(y: 2)
                .dxSettle(delay: 0.3)
            EvIllo(kind: .patch, size: 74).offset(x: -91, y: 22).dxPop(delay: 0.7)
            EvIllo(kind: .bubble, size: 74).offset(x: 91, y: 20).dxPop(delay: 0.85)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 136, alignment: .top)
        .accessibilityElement()
        .accessibilityLabel(Text("Xero holding a nicotine patch in one hand and a speech bubble in the other"))
    }

    private func ingredient(_ title: LocalizedStringKey, _ detail: LocalizedStringKey) -> some View {
        VStack(spacing: 3) {
            Text(title).dxFace(.display, 17, weight: 700, tracking: -0.2).foregroundStyle(Onb.ink)
            Text(detail).dxFace(.body, 13, weight: 500).foregroundStyle(Onb.muted).lineSpacing(2)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: Pregnant or breastfeeding · after nicotine replacement

/// One question before nicotine replacement is planned (S27.6). It used to be three small chips under the NRT
/// options; it now has its own step, shown unless the answer there was "Not for me". "Yes" brings the caution: talk
/// to a midwife or doctor first.
struct PregnancyScreen: View {
    @Bindable var model: OnboardingModel
    @Environment(\.dynamicTypeSize) private var typeSize
    private let motion = MotionPolicy()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .bottom, spacing: 8) {
                    Text("Pregnant or\nbreastfeeding?")
                        .dxType(.large).foregroundStyle(Onb.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .dxArrive(0)
                    if !typeSize.isAccessibilitySize {
                        XeroView(mood: .calm, stage: 0, points: 84, animate: !motion.reduce)
                            .frame(width: 84, height: 84)
                            .padding(.trailing, 4).padding(.bottom, -6)
                            .dxSettle(delay: 0.2)
                            .accessibilityHidden(true)
                    }
                }
                Text("One quick question before we plan nicotine replacement.")
                    .dxType(.body).foregroundStyle(Onb.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
                    .dxArrive(1)
                VStack(spacing: 8) {
                    ForEach(Array(PregnancyAnswer.allCases.enumerated()), id: \.element) { i, answer in
                        EvAnswerRow(title: answer.chipTitle, isOn: model.pregnancy == answer) { model.setPregnancy(answer) }
                            .dxArrive(2 + i)
                    }
                }
                .padding(.top, 20)
                if model.pregnancy == .yes {
                    Text(verbatim: PregnancyAnswer.caution)
                        .dxFace(.body, 15, weight: 600).foregroundStyle(Onb.ink)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 14).padding(.horizontal, 4)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, DX.Layout.gutter)
            .dxReadableColumn()
            .padding(.top, DX.Space.m)
            .padding(.bottom, DX.Space.m)
            .animation(motion.animation(DX.Move.settle), value: model.pregnancy)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) { EvDock(title: "Continue", model: model) }
    }
}

/// A plain answer row: the title on the card; picked, it fills with ink and takes the coral tick.
struct EvAnswerRow: View {
    let title: String
    let isOn: Bool
    let action: () -> Void
    @State private var taps = 0

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        Button {
            taps += 1
            action()
        } label: {
            HStack(spacing: 10) {
                Text(verbatim: title)
                    .dxFace(.display, 17, weight: 700, tracking: -0.2)
                    .foregroundStyle(isOn ? Ev.selFg : Onb.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                EvTick(isOn: isOn)
            }
            .padding(.horizontal, 18).padding(.vertical, 8)
            .frame(minHeight: 60)
            .background(isOn ? Ev.sel : Ev.card, in: shape)
            .overlay { if !isOn { shape.strokeBorder(Ev.ring, lineWidth: 1) } }
            .contentShape(shape)
            .animation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.25), value: isOn)
        }
        .buttonStyle(.dxPress)
        .sensoryFeedback(DX.Haptic.select, trigger: taps)
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
    }
}

/// The coral disc with a cream tick on a picked row; nothing when it isn't picked.
struct EvTick: View {
    let isOn: Bool

    var body: some View {
        EvGlyph(d: "M5 12.5 L10 17 L19 7", size: 14, weight: 3.6)
            .foregroundStyle(Ev.cream)
            .frame(width: 26, height: 26)
            .background(Ev.badge, in: Circle())
            .opacity(isOn ? 1 : 0)
            .scaleEffect(isOn ? 1 : 0.6)
            .animation(.timingCurve(0.3, 1.4, 0.5, 1, duration: 0.3), value: isOn)
    }
}
