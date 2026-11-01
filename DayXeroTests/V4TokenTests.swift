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

    /// Decision 25: on cream-ink grounds, light-mode tiles are navy at 20% over the ground.
    @Test func tilesOnCreamInkGroundsClearContrast() {
        func over(_ ground: UInt32) -> UInt32 {
            let navy: UInt32 = 0x1E1A3A
            return [16, 8, 0].reduce(0) { sum, shift in
                let g = Double((ground >> shift) & 0xFF), n = Double((navy >> shift) & 0xFF)
                return sum | (UInt32((g * 0.8 + n * 0.2).rounded()) << shift)
            }
        }
        for ground in DX.Ground.allCases where ground.spec.inkLight == 0xFFF8EE {
            let tile = over(ground.spec.light)
            #expect(Contrast.ratio(tile, ground.spec.inkLight) >= 4.5, "\(ground) ink")
            #expect(Contrast.ratio(tile, ground.spec.mutedLight) >= 4.5, "\(ground) muted")
        }
    }

    /// Button(role: .destructive) with quiet or secondary styles draws red that clears 4.5:1, in light and dark.
    @Test func destructiveQuietAndSecondaryButtonsAreRedAndReadable() {
        let red = (light: DX.ButtonColors.destructiveLight, dark: DX.ButtonColors.destructiveDark)
        // The reading ground and the reading surfaces a destructive button sits on.
        let reading = DX.Ground.reading.spec
        for (name, bg) in [("reading", reading.light), ("surface", 0xF1EBE2), ("raised", 0xFFFFFF)] as [(String, UInt32)] {
            #expect(Contrast.ratio(red.light, bg) >= 4.5, "light on \(name): \(Contrast.ratio(red.light, bg))")
        }
        for (name, bg) in [("reading", reading.dark), ("surface", 0x1B1747), ("raised", 0x2A255F)] as [(String, UInt32)] {
            #expect(Contrast.ratio(red.dark, bg) >= 4.5, "dark on \(name): \(Contrast.ratio(red.dark, bg))")
        }
        for kind in [DX.ButtonKind.quiet, .secondary] {
            #expect(DX.ButtonColors.make(kind, on: .reading, dark: false, destructive: true).foreground == red.light)
            #expect(DX.ButtonColors.make(kind, on: .reading, dark: true, destructive: true).foreground == red.dark)
            #expect(DX.ButtonColors.make(kind, on: .reading, dark: false, destructive: false).foreground == reading.inkLight)
        }
        // Primary keeps its own colours.
        #expect(DX.ButtonColors.make(.primary, on: .reading, dark: false, destructive: true).foreground == 0xFFF8EE)
        // On any ground, whatever a destructive quiet button draws still clears 4.5:1.
        for ground in DX.Ground.allCases {
            for dark in [false, true] {
                let fg = DX.ButtonColors.make(.quiet, on: ground, dark: dark, destructive: true).foreground
                let bg = dark ? ground.spec.dark : ground.spec.light
                #expect(Contrast.ratio(fg, bg) >= 4.5, "\(ground) dark: \(dark)")
            }
        }
    }

    @Test func sevenTypeSizesWithA12PointFloor() {
        #expect(DX.TypeStep.allCases.count == 7)
        #expect(Set(DX.TypeStep.allCases.map(\.size)).count == 7)
        #expect(DX.TypeStep.allCases.allSatisfy { $0.size >= 12 })
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
        #expect(DX.Move.Hold.dayXeroCommit == 3)
        #expect(DX.Move.Hold.quitDay == 1.5)
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
