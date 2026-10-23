@testable import DayXero
import DayXeroCore
import Foundation
import SwiftData
import Testing

@MainActor
struct SettingsTests {
    @Test func usageDataIsOptInInTheEU() {
        #expect(!AnalyticsConsent.defaultValue(region: "DE"))
        #expect(!AnalyticsConsent.defaultValue(region: "fr"))
        #expect(!AnalyticsConsent.defaultValue(region: "NO"))
        #expect(AnalyticsConsent.defaultValue(region: "US"))
        #expect(AnalyticsConsent.defaultValue(region: "AU"))
        #expect(AnalyticsConsent.defaultValue(region: nil))
    }

    @Test func exportIsOneReadableJSONFile() throws {
        let context = ModelContext(try DataStore.makeContainer(inMemory: true))
        let profile = UserProfile(name: "Milan", quitDay: .now, currencyCode: "USD")
        context.insert(profile)
        profile.products.append(ProductUse(product: .vape, isPrimary: true, unitsPerDay: 200, pricePerPurchase: 8.5, unitsPerPurchase: 600))
        profile.reasons.append(Reason(text: "Run with Aria"))
        let entry = LogEntry(kind: .craving, timestamp: .now, trigger: .coffee)
        context.insert(entry)
        context.insert(CheckIn(day: .now, mood: .good, cravingCount: 2))
        try context.save()
        let url = try #require(DataTools.export(context: context, profile: profile))
        let object = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
        let json = try #require(object)
        #expect((json["logs"] as? [[String: Any]])?.first?["trigger"] as? String == "coffee")
        #expect(((json["profile"] as? [String: Any])?["reasons"] as? [String]) == ["Run with Aria"])
        #expect((json["checkIns"] as? [Any])?.count == 1)
    }

    @Test func appearanceMapsToAColourScheme() {
        #expect(AppearanceSetting.automatic.colorScheme == nil)
        #expect(AppearanceSetting.dark.colorScheme == .dark)
    }
}
