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
        tapSettled(app, "Continue")
        let name = app.textFields.firstMatch
        XCTAssert(name.waitForExistence(timeout: 5))
        name.tap()
        // Submit from the keyboard: its return key is also labelled "Continue", so tapping by label finds two.
        name.typeText("Sam\n")
        tap(button(app, "Disposables"))
        snap(app, "02-products")
        tapSettled(app, "Continue")
        // Baseline: the price commits when focus moves to the next field.
        let price = app.textFields.element(boundBy: 0)
        XCTAssert(price.waitForExistence(timeout: 5))
        price.tap()
        price.typeText("8.5")
        app.textFields.element(boundBy: 1).tap()
        snap(app, "03-baseline")
        tapSettled(app, "Continue")
        for _ in 0..<3 { tapSettled(app, "Skip") }   // triggers, reasons, past attempts
        snap(app, "04-quit-day")
        tap(button(app, "as Quit Day"))
        tapSettled(app, "Skip")                       // NRT
        XCTAssert(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Quit Day is")).firstMatch.waitForExistence(timeout: 15), "Plan reveal didn't appear")
        snap(app, "05-reveal")
        tapSettled(app, "Continue")
        tapSettled(app, "Not now")                    // reminders

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
        tap(button(app, "Vaped"))
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
        tap(button(app, "Vaped"))
        XCTAssert(app.staticTexts["Thanks for telling us"].waitForExistence(timeout: 5))
        snap(app, "21-slip")
        tapSettled(app, "Not now")
        XCTAssert(app.buttons["Craving SOS"].waitForExistence(timeout: 5))
        visitTabs(app, prefix: "22-day3")
    }

    /// A slip or a craving opened straight from a widget or Siri shows its page, not a blank sheet (S18.18).
    func testWidgetOpensSlipAndCravingLog() {
        let app = launch(["-dx.homeScenario", "day3", "-dx.store", "pro"])
        XCTAssert(app.buttons["Craving SOS"].waitForExistence(timeout: 10))
        app.open(URL(string: "dayxero://log/slip")!)
        XCTAssert(app.staticTexts["Thanks for telling us"].waitForExistence(timeout: 5), "The slip screen didn't appear")
        snap(app, "23-widget-slip")
        tapSettled(app, "Not now")
        XCTAssert(app.buttons["Craving SOS"].waitForExistence(timeout: 5))
        app.open(URL(string: "dayxero://log/craving")!)
        XCTAssert(app.buttons["Save"].waitForExistence(timeout: 5), "The craving log didn't appear")
        snap(app, "24-widget-craving")
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
        // The Bio-Orb session: Pause and Coach me on screen, the outcomes in the session menu until time's up.
        XCTAssert(app.buttons["Breathing guide"].waitForExistence(timeout: 5))
        XCTAssert(app.buttons["Coach me"].exists)
        snap(app, "sos-session")
        tap(app.buttons["Session options"])
        tap(app.buttons["It passed"])
        XCTAssert(app.staticTexts["Craving ridden out"].waitForExistence(timeout: 5))
        tap(app.buttons["Done"])
        XCTAssert(app.buttons["Craving SOS"].waitForExistence(timeout: 5))
    }

    private func visitTabs(_ app: XCUIApplication, prefix: String) {
        for tab in ["Program", "Progress", "Today"] {
            tap(app.buttons[tab].firstMatch)
            RunLoop.current.run(until: .now.addingTimeInterval(1))   // let the tab cross-fade finish
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

    /// Taps the button with this label once exactly one is on screen and it has stopped moving, so a step's
    /// slide-in or a sheet growing to full height has finished. A tap mid-slide can miss.
    private func tapSettled(_ app: XCUIApplication, _ label: String, file: StaticString = #filePath, line: UInt = #line) {
        let query = app.buttons.matching(NSPredicate(format: "label == %@", label))
        let deadline = Date.now.addingTimeInterval(10)
        while query.count != 1, Date.now < deadline { RunLoop.current.run(until: .now.addingTimeInterval(0.2)) }
        XCTAssertEqual(query.count, 1, "Expected one \"\(label)\" button", file: file, line: line)
        let button = query.element
        var last = CGRect.null
        let still = Date.now.addingTimeInterval(5)
        while Date.now < still {
            let frame = button.frame
            if frame == last, !frame.isEmpty { break }
            last = frame
            RunLoop.current.run(until: .now.addingTimeInterval(0.3))
        }
        let enabled = NSPredicate(format: "isEnabled == true AND isHittable == true")
        let wait = XCTNSPredicateExpectation(predicate: enabled, object: button)
        XCTAssertEqual(XCTWaiter().wait(for: [wait], timeout: 5), .completed, "\"\(label)\" never became tappable", file: file, line: line)
        button.tap()
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
