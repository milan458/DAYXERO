import DayXeroCore
import Foundation
import Testing
import UIKit

struct V4TokenTests {
    /// Every ink and muted pair on every ground clears 4.5:1 in light and dark.
    @Test func everyGroundPairClearsContrast() {
        for ground in DX.Ground.allCases {
            let s = ground.spec
            let pairs: [(String, UInt32, UInt32)] = [
                ("ink light", s.light, s.inkLight),
                ("muted light", s.light, s.mutedLight),
                ("ink dark", s.dark, s.inkDark),
                ("muted dark", s.dark, s.mutedDark),
            ]
            for (name, bg, fg) in pairs {
                #expect(Contrast.ratio(bg, fg) >= 4.5, "\(ground) \(name): \(Contrast.ratio(bg, fg))")
            }
        }
    }

    @Test func contrastMatchesKnownValues() {
        #expect(abs(Contrast.ratio(0x000000, 0xFFFFFF) - 21) < 0.01)
        // Ink on coral, from the brand board.
        #expect(abs(Contrast.ratio(0xFF7A55, 0x1E1A3A) - 6.46) < 0.01)
    }

    /// QW7: one green. Text pairs clear 4.5:1; ticks, dots and the road (non-text) clear 3:1.
    @Test func theOneGreenClearsContrastWhereverItIsUsed() {
        let light = DX.Fill.greenLight, dark = DX.Fill.greenDark
        let text: [(String, UInt32, UInt32)] = [
            ("cream on the lesson card", 0xFFF8EE, light),
            ("green on the cream reading ground", light, DX.Ground.reading.spec.light),
            ("green on a white card", light, 0xFFFFFF),
            ("green on the night reading ground", dark, DX.Ground.reading.spec.dark),
            ("green on a night card", dark, 0x182034),
        ]
        for (name, a, b) in text { #expect(Contrast.ratio(a, b) >= 4.5, "\(name): \(Contrast.ratio(a, b))") }
        let marks: [(String, UInt32, UInt32)] = [
            ("tick on lilac", light, DX.Ground.lilac.spec.light),
            ("tick on sky", light, DX.Ground.sky.spec.light),
            ("road on mint", light, DX.Ground.mint.spec.light),
            ("road on night mint", dark, DX.Ground.mint.spec.dark),
            ("tick on an ink chip", dark, 0x1E1A3A),
        ]
        for (name, a, b) in marks { #expect(Contrast.ratio(a, b) >= 3, "\(name): \(Contrast.ratio(a, b))") }
        #expect(abs(Contrast.ratio(0xFFF8EE, light) - 5.98) < 0.01)
    }

    /// v5: the done green (#1F9D63) is for discs and ticks only: a white tick on it, and the disc on every ground,
    /// clear 3:1.
    @Test func theDoneGreenClearsNonTextContrast() {
        let done = DX.Fill.doneHex
        #expect(done == 0x1F9D63)
        #expect(Contrast.ratio(0xFFFFFF, done) >= 3)
        // Ocean light (#1F3C8C) is 2.9:1: the kit sets the tick there on its card, not the ground.
        for ground in [DX.Ground.reading, .violet] {
            #expect(Contrast.ratio(done, ground.spec.light) >= 3, "\(ground) light")
        }
        for ground in DX.Ground.allCases {
            #expect(Contrast.ratio(done, ground.spec.dark) >= 3, "\(ground) dark")
        }
    }

    /// Composites an RGBA token over a solid ground.
    private func over(_ token: DX.Ground.Tokens.RGBA, _ ground: UInt32) -> UInt32 {
        DX.Ground.mix(token.hex, token.alpha, over: ground)
    }

    /// v5: words on every ground's card clear 4.5:1, in both modes, and the card separates from its ground: by
    /// 1.15:1 (the kit's tonal cards) or, where no fill can, with the hairline.
    @Test func cardsSeparateFromTheirGround() {
        for ground in DX.Ground.allCases {
            let s = ground.spec
            for dark in [false, true] {
                let t = ground.tokens(dark: dark)
                let bg = dark ? s.dark : s.light
                let card = over(t.card, bg)
                let ink = dark ? s.inkDark : s.inkLight, muted = dark ? s.mutedDark : s.mutedLight
                #expect(t.hairline || Contrast.ratio(card, bg) >= 1.15, "\(ground) dark \(dark): \(Contrast.ratio(card, bg))")
                #expect(Contrast.ratio(card, ink) >= 4.5, "\(ground) dark \(dark) ink on card")
                #expect(Contrast.ratio(card, muted) >= 4.5, "\(ground) dark \(dark) muted on card")
                #expect(Contrast.ratio(t.btn, t.btnFg) >= 4.5, "\(ground) dark \(dark) button")
                #expect(Contrast.ratio(over(t.selTint, card), ink) >= 4.5, "\(ground) dark \(dark) ink on selection")
            }
        }
    }

    /// v5 selection: a warm tint and a coral edge in light, an apricot edge on the dark navy, cream on ocean and night.
    @Test func selectionTokensFollowTheKit() {
        #expect(DX.Ground.reading.tokens(dark: false).selEdge == 0xF26A45)
        #expect(DX.Ground.reading.tokens(dark: false).selTint.hex == DX.Ground.mix(0xFFB27A, 0.2, over: 0xFFFFFF))
        #expect(DX.Ground.apricot.tokens(dark: true).selEdge == 0xFFB27A)
        #expect(DX.Ground.apricot.tokens(dark: true).selTint.hex == DX.Ground.mix(0xFFC89A, 0.15, over: 0x182034))
        for dark in [false, true] {
            #expect(DX.Ground.ocean.tokens(dark: dark).selEdge == 0xFFF8EE)
            #expect(DX.Ground.violet.tokens(dark: dark).selEdge == DX.Ground.violet.tokens(dark: dark).sel)
        }
    }

    /// v5: seven grounds in use; dark mode is one navy except ocean and night; the retired ones draw their survivor.
    @Test func groundsInUseAndRetiredOnesResolve() {
        #expect(DX.Ground.allCases == [.apricot, .mint, .ocean, .violet, .reading, .table, .sun])
        for ground in [DX.Ground.apricot, .mint, .reading, .table, .sun] { #expect(ground.spec.dark == 0x0E1322) }
        #expect(DX.Ground.violet.spec.light == 0x0F1B33 && DX.Ground.ocean.spec.light == 0x1F3C8C)
        let retired: [(DX.Ground, DX.Ground)] = [(.coral, .apricot), (.sky, .reading), (.lilac, .reading), (.mist, .reading),
                                                 (.periwinkle, .reading), (.lime, .mint)]
        for (old, survivor) in retired {
            #expect(old.resolved == survivor)
            #expect(old.spec.light == survivor.spec.light && old.spec.dark == survivor.spec.dark)
            #expect(old.spec.inkLight == survivor.spec.inkLight && old.spec.mutedDark == survivor.spec.mutedDark)
        }
        #expect(DX.Ground.allCases.allSatisfy { $0.resolved == $0 })
    }

    /// Button(role: .destructive) with quiet or secondary styles draws red that clears 4.5:1, in light and dark.
    @Test func destructiveButtonsAreRedAndReadable() throws {
        let red = (light: DX.ButtonColors.destructiveLight, dark: DX.ButtonColors.destructiveDark)
        // The reading ground and the reading surfaces a destructive button sits on.
        let reading = DX.Ground.reading.spec
        for (name, bg) in [("reading", reading.light), ("surface", 0xF1EBE2), ("raised", 0xFFFFFF)] as [(String, UInt32)] {
            #expect(Contrast.ratio(red.light, bg) >= 4.5, "light on \(name): \(Contrast.ratio(red.light, bg))")
        }
        for (name, bg) in [("reading", reading.dark), ("surface", 0x212A41), ("raised", 0x182034)] as [(String, UInt32)] {
            #expect(Contrast.ratio(red.dark, bg) >= 4.5, "dark on \(name): \(Contrast.ratio(red.dark, bg))")
        }
        for kind in [DX.ButtonKind.quiet, .secondary] {
            #expect(DX.ButtonColors.make(kind, on: .reading, dark: false, destructive: true).foreground == red.light)
            #expect(DX.ButtonColors.make(kind, on: .reading, dark: true, destructive: true).foreground == red.dark)
            #expect(DX.ButtonColors.make(kind, on: .reading, dark: false, destructive: false).foreground == reading.inkLight)
        }
        // A destructive primary is filled red with readable words, on every ground and in both modes (S27.20).
        for ground in DX.Ground.allCases {
            for dark in [false, true] {
                let c = DX.ButtonColors.make(.primary, on: ground, dark: dark, destructive: true)
                let bg = try #require(c.background)
                #expect(bg == (dark ? DX.ButtonColors.destructiveFillDark : DX.ButtonColors.destructiveFillLight))
                #expect(Contrast.ratio(c.foreground, bg) >= 4.5, "\(ground) dark: \(dark)")
            }
        }
        #expect(DX.ButtonColors.make(.primary, on: .reading, dark: false, destructive: false).foreground == 0xFFF8EE)
        // On any ground, whatever a destructive quiet button draws still clears 4.5:1.
        for ground in DX.Ground.allCases {
            for dark in [false, true] {
                let fg = DX.ButtonColors.make(.quiet, on: ground, dark: dark, destructive: true).foreground
                let bg = dark ? ground.spec.dark : ground.spec.light
                #expect(Contrast.ratio(fg, bg) >= 4.5, "\(ground) dark: \(dark)")
            }
        }
    }

    @Test func sevenTypeSizesWithA13PointFloor() {
        #expect(DX.TypeStep.allCases.count == 7)
        #expect(DX.TypeStep.allCases.map(\.size) == [40, 32, 24, 19, 16, 15, 13])
        #expect(DX.TypeStep.allCases.allSatisfy { $0.size >= 13 })
    }

    @Test func v5LayoutAndMotion() {
        #expect(DX.Layout.gutter == 22 && DX.Layout.cardRadius == 22 && DX.Layout.optionRadius == 18)
        #expect(DX.Layout.fieldRadius == 16 && DX.Layout.chipRadius == 14 && DX.Layout.tabBarRadius == 28 && DX.Layout.sheetRadius == 30)
        #expect(DX.Size.buttonHeight == 58 && DX.Layout.buttonHeight == 58)
        #expect(DX.Move.stamp == 0.62 && DX.Move.floatUp == 1.4 && DX.Move.shine == 1.4 && DX.Move.bob == 5)
    }

    @MainActor @Test func variableFacesRegisterAndResolve() {
        DX.Typeface4.register()
        #expect(DX.Typeface4.isAvailable)
        let font = DX.TypeStep.title.uiFont()
        #expect(font.fontName.hasPrefix("BricolageGrotesque"))
        #expect(DX.TypeStep.body.uiFont().fontName.hasPrefix("DMSans"))
    }

    @MainActor @Test func typeScalesWithDynamicType() {
        DX.Typeface4.register()
        let base = DX.TypeStep.body.uiFont(sizeCategory: .large).pointSize
        let big = DX.TypeStep.body.uiFont(sizeCategory: .accessibilityExtraExtraExtraLarge).pointSize
        #expect(base == 16)
        #expect(big > base)
    }

    @Test func holdsAndCharacterSizes() {
        // One hold duration everywhere (S27.20).
        #expect(DX.Move.hold == 1)
        #expect(DX.CharacterSize.allCases.map(\.rawValue) == [40, 88, 140, 200])
        #expect(DX.CharacterSize.maxPerScreen == 2)
    }

    @Test func breathRunsFourInSixOut() {
        #expect(DX.Move.breath(at: 0) < 0.001)
        #expect(abs(DX.Move.breath(at: 4) - 1) < 0.001)
        #expect(DX.Move.breath(at: 2) > 0.4 && DX.Move.breath(at: 2) < 0.6)
        #expect(DX.Move.breath(at: 10) < 0.001)
        #expect(abs(DX.Move.breath(at: 14) - 1) < 0.001)
    }
}
