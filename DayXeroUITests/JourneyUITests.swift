import XCTest

/// The whole journey on a real build (S16.1): onboarding → paywall → prep → Quit Day → first week → maintenance.
/// The clock can't move forward in a UI test, so the later stages launch with a seeded scenario.
/// Each step saves a screenshot: as a test attachment, and to $DX_SHOTS when CI sets it (S16.2).
@MainActor
final class JourneyUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testOnboardingPaywallAndPrep() {
        let app = launch(["-dx.store", "mock"])

        // Onboarding (S2)
        snap(app, "01-welcome")
        tap(app.buttons["Build my plan"])
        tap(button(app, "18 or older"))
        tap(app.buttons["Continue"])
        let name = app.textFields.firstMatch
        XCTAssert(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Sam")
        tap(app.buttons["Continue"])
        tap(button(app, "Disposables"))
        snap(app, "02-products")
        tap(app.buttons["Continue"])
        // Baseline: the price commits when focus moves to the next field.
        let price = app.textFields.element(boundBy: 0)
        XCTAssert(price.waitForExistence(timeout: 5))
        price.tap()
        price.typeText("8.5")
        app.textFields.element(boundBy: 1).tap()
        snap(app, "03-baseline")
        tap(app.buttons["Continue"])
        for _ in 0..<3 { tap(app.buttons["Skip"]) }   // triggers, reasons, past attempts
        snap(app, "04-quit-day")
        tap(button(app, "as Quit Day"))
        tap(app.buttons["Skip"])                       // NRT
        let reveal = app.buttons["Continue"]
        XCTAssert(reveal.waitForExistence(timeout: 15), "Plan reveal didn't appear")
        snap(app, "05-reveal")
        reveal.tap()
        tap(app.buttons["Not now"])                    // reminders

        // Paywall (S3), against the mock store
        let cta = app.buttons["paywall.cta"]
        XCTAssert(cta.waitForExistence(timeout: 10))
        snap(app, "06-paywall")
        tap(cta)
        tap(app.buttons["Start prep day 1"], timeout: 10)

        // Prep Home (S4): log a use, ride out a craving, visit each tab.
        XCTAssert(app.buttons["Craving SOS"].waitForExistence(timeout: 10))
        snap(app, "07-home-prep")
        tap(button(app, "Log"))
        tap(button(app, "Puff session"))
        rideOutCraving(app)
        visitTabs(app, prefix: "08-prep")
    }

    func testQuitDay() {
        let app = launch(["-dx.homeScenario", "quitday", "-dx.store", "pro"])
        XCTAssert(app.buttons["Craving SOS"].waitForExistence(timeout: 10))
        snap(app, "10-home-quitday")
        rideOutCraving(app)
    }

    func testFirstWeekSlip() {
        let app = launch(["-dx.homeScenario", "day3", "-dx.store", "pro"])
        XCTAssert(app.buttons["Craving SOS"].waitForExistence(timeout: 10))
        snap(app, "20-home-day3")
        // A use after Quit Day is a slip: talked through, and nothing resets (S8).
        tap(button(app, "Log"))
        tap(button(app, "Puff session"))
        XCTAssert(app.staticTexts["Thanks for telling us"].waitForExistence(timeout: 5))
        snap(app, "21-slip")
        tap(app.buttons["Not now"])
        XCTAssert(app.buttons["Craving SOS"].waitForExistence(timeout: 5))
        visitTabs(app, prefix: "22-day3")
    }

    func testMaintenance() {
        let app = launch(["-dx.homeScenario", "day12", "-dx.store", "pro"])
        XCTAssert(app.buttons["Craving SOS"].waitForExistence(timeout: 10))
        snap(app, "30-home-day12")
        visitTabs(app, prefix: "31-day12")
        tap(app.buttons["Profile and settings"])
        snap(app, "32-settings")
        tap(app.buttons["Done"])
        XCTAssert(app.buttons["Craving SOS"].waitForExistence(timeout: 5))
    }

    // MARK: Steps

    private func rideOutCraving(_ app: XCUIApplication) {
        tap(app.buttons["Craving SOS"])
        let passed = app.buttons["It passed"]
        XCTAssert(passed.waitForExistence(timeout: 5))
        snap(app, "sos-session")
        passed.tap()
        XCTAssert(app.staticTexts["Craving ridden out"].waitForExistence(timeout: 5))
        tap(app.buttons["Done"])
        XCTAssert(app.buttons["Craving SOS"].waitForExistence(timeout: 5))
    }

    private func visitTabs(_ app: XCUIApplication, prefix: String) {
        for tab in ["Program", "Progress", "Today"] {
            tap(app.buttons[tab].firstMatch)
            snap(app, "\(prefix)-\(tab.lowercased())")
        }
    }

    // MARK: Helpers

    private func launch(_ arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-dx.uiTest", "YES"] + arguments
        app.launch()
        return app
    }

    private func button(_ app: XCUIApplication, _ text: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch
    }

    private func tap(_ element: XCUIElement, timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssert(element.waitForExistence(timeout: timeout), "Missing \(element)", file: file, line: line)
        element.tap()
    }

    private func snap(_ app: XCUIApplication, _ name: String) {
        let shot = app.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = "\(name)-\(testRun?.test.name ?? "")"
        attachment.lifetime = .keepAlways
        add(attachment)
        if let dir = ProcessInfo.processInfo.environment["DX_SHOTS"], !dir.isEmpty {
            let test = (testRun?.test.name ?? "test").filter { $0.isLetter || $0.isNumber }
            try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
            try? shot.pngRepresentation.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(test)-\(name).png"))
        }
    }
}
