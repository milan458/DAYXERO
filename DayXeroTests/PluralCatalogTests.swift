@testable import DayXero
import Foundation
import Testing

/// Counts read "1 day", not "1 days": each count string has English plural forms in its String Catalog.
struct PluralCatalogTests {
    /// The repo root, found from this file. The catalog JSON is read from the source tree.
    static let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    static let catalogs = [
        "DayXero/Resources/Localizable.xcstrings",
        "DayXeroCore/Resources/Localizable.xcstrings",
        "DayXeroWidgets/Localizable.xcstrings",
    ]
    static let sourcesAvailable = catalogs.allSatisfy { FileManager.default.fileExists(atPath: root.appendingPathComponent($0).path) }

    /// The widget extension, embedded in the app that hosts these tests.
    static var widgetBundle: Bundle? {
        Bundle.main.builtInPlugInsURL.flatMap { Bundle(url: $0.appendingPathComponent("DayXeroWidgets.appex")) }
    }

    static let english = Locale(identifier: "en_US")

    private static func strings(_ path: String) throws -> [String: Any] {
        let data = try Data(contentsOf: root.appendingPathComponent(path))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["sourceLanguage"] as? String == "en")
        return try #require(json["strings"] as? [String: Any])
    }

    /// One plural block: both forms present, each with a translated value.
    private static func checkPlural(_ variations: Any?, other expectedOther: String?, _ place: String) {
        guard let plural = (variations as? [String: Any])?["plural"] as? [String: Any] else {
            Issue.record("\(place) has no plural variations")
            return
        }
        for form in ["one", "other"] {
            let unit = (plural[form] as? [String: Any])?["stringUnit"] as? [String: Any]
            #expect(unit?["state"] as? String == "translated", "\(place) is missing \(form)")
            #expect((unit?["value"] as? String)?.isEmpty == false, "\(place) has an empty \(form)")
        }
        if let expectedOther {
            let other = ((plural["other"] as? [String: Any])?["stringUnit"] as? [String: Any])?["value"] as? String
            #expect(other == expectedOther, "\(place): other should read like the source text")
        }
    }

    @Test(.enabled(if: PluralCatalogTests.sourcesAvailable, "Needs the source tree"), arguments: PluralCatalogTests.catalogs)
    func everyPluralHasOneAndOther(_ path: String) throws {
        let strings = try Self.strings(path)
        #expect(!strings.isEmpty, "\(path) has no strings")
        for (key, value) in strings {
            let entry = try #require(value as? [String: Any])
            let en = try #require((entry["localizations"] as? [String: Any])?["en"] as? [String: Any], "\(key) has no English")
            if let variations = en["variations"] {
                Self.checkPlural(variations, other: key, "\(path): \(key)")
            }
            if let substitutions = en["substitutions"] as? [String: Any] {
                let template = try #require((en["stringUnit"] as? [String: Any])?["value"] as? String)
                for (name, raw) in substitutions {
                    let sub = try #require(raw as? [String: Any])
                    #expect(template.contains("#@\(name)@"), "\(key) doesn't use \(name)")
                    #expect(Self.allPositional(template), "\(key): \"\(template)\" mixes a plural placeholder with unnumbered ones")
                    #expect(sub["argNum"] as? Int != nil, "\(key): \(name) has no argNum")
                    #expect(sub["formatSpecifier"] as? String == "lld", "\(key): \(name) isn't an integer")
                    Self.checkPlural(sub["variations"], other: nil, "\(path): \(key) / \(name)")
                }
            }
        }
    }

    /// With a plural placeholder (`%#@arg1@`) in the text, every placeholder needs its argument number (`%1$#@arg1@`,
    /// `%2$@`). Unnumbered ones after a plural placeholder read the wrong argument: "%#@arg1@ · %@" read an integer as
    /// a string and crashed the breathing orb and the vape baseline summary on device (1 Nov 2026).
    static func allPositional(_ template: String) -> Bool {
        let placeholder = /%(\d+\$)?(#@\w+@|[-+ 0#]*\d*(\.\d+)?(ll|l|h|hh|q|z|t|j)?[@dDiuUxXoOfeEgGcCsSp])/
        let found = template.replacingOccurrences(of: "%%", with: "").matches(of: placeholder)
        return found.count < 2 || found.allSatisfy { $0.output.1 != nil }
    }

    /// The strings that put a value after a count: each reads its own argument (S27 crash fix, 1 Nov 2026).
    @Test func valuesAfterACountReadTheirOwnArgument() {
        #expect(String(localized: "\(4) seconds · \("inhale")", locale: Self.english) == "4 seconds · inhale")
        #expect(String(localized: "\(1) seconds · \("hold")", locale: Self.english) == "1 second · hold")
        #expect(String(localized: "~\(85) vape puffs at \("2%")", locale: Self.english) == "~85 vape puffs at 2%")
        #expect(String(localized: "\(7) days free, then \("$29.99") a year", locale: Self.english) == "7 days free, then $29.99 a year")
        #expect(String(localized: "\(8) pouches at \(6) mg", locale: Self.english) == "8 pouches at 6 mg")
        #expect(String(localized: "\("Inhale"), \(3) seconds left, cycle \(2) of \(4)", locale: Self.english)
            == "Inhale, 3 seconds left, cycle 2 of 4")
        #expect(String(localized: "\(7) DAYS FREE · SAVE \(40)%", locale: Self.english) == "7 DAYS FREE · SAVE 40%")
    }

    @Test func appLookupsUseTheSingular() {
        #expect(String(localized: "In \(1) days", locale: Self.english) == "In 1 day")
        #expect(String(localized: "In \(2) days", locale: Self.english) == "In 2 days")
        #expect(String(localized: "\(1) days since Quit Day", locale: Self.english) == "1 day since Quit Day")
        #expect(String(localized: "Every \(1) hours", locale: Self.english) == "Every 1 hour")
        #expect(String(localized: "\(1) of \(1) waves. All yours.", locale: Self.english) == "1 of 1 wave. All yours.")
        #expect(String(localized: "\(2) of \(3) waves. All yours.", locale: Self.english) == "2 of 3 waves. All yours.")
        // Counts filled into JSON text and built in code.
        #expect(String(localized: "\(1) days", locale: Self.english) == "1 day")
        #expect(String(localized: "\(1) cravings", locale: Self.english) == "1 craving")
        #expect(String(localized: "\(3) cravings", locale: Self.english) == "3 cravings")
        #expect(String(localized: "\(1) cycles", locale: Self.english) == "1 cycle")
        #expect(String(localized: "\(1) cigarettes not smoked", locale: Self.english) == "1 cigarette not smoked")
        #expect(String(localized: "\(1) puffs a day", locale: Self.english) == "1 puff a day")
    }

    @Test(.enabled(if: PluralCatalogTests.widgetBundle != nil, "Needs the embedded widget extension"))
    func widgetLookupsUseTheSingular() throws {
        let bundle = try #require(Self.widgetBundle)
        #expect(String(localized: "Day Xero in \(1) days", bundle: bundle, locale: Self.english) == "Day Xero in 1 day")
        #expect(String(localized: "Day Xero in \(3) days", bundle: bundle, locale: Self.english) == "Day Xero in 3 days")
        #expect(String(localized: "Water, \(1) of \(1) glasses. Log a glass.", bundle: bundle, locale: Self.english)
            == "Water, 1 of 1 glass. Log a glass.")
    }
}
