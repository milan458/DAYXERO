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
