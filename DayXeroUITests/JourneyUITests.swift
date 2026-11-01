import XCTest

/// The whole journey on a real build (S16.1): onboarding → prep → Quit Day → first week → maintenance.
/// The paywall now follows Day Xero (decision 23), so it is no longer part of the onboarding run.
/// The clock can't move forward in a UI test, so the later stages launch with a seeded scenario.
/// Each step saves a screenshot: as a test attachment, and to $DX_SHOTS when CI sets it (S16.2).
@MainActor
final class JourneyUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testOnboardingPaywallAndPrep() {
        let app = launch(["-dx.store", "mock"])

        // F01: one breath first; Skip appears after one 10 s cycle.
        snap(app, "00-breathe")
        let skip = app.buttons["Skip"]
        XCTAssert(skip.waitForExistence(timeout: 15), "Breathe screen never offered Skip")
        tapWhenStill(app, skip, name: "Skip")
        // F02 Welcome: the 18+ confirmation is the footer.
        snap(app, "01-welcome")
        tap(app.buttons["Get started"])
        tap(button(app, "Disposables"))
        snap(app, "02-products")
        tapSettled(app, "Continue")
        // The vape baseline starts on the region's usual price, so it can go straight on.
        snap(app, "03-baseline")
        tapSettled(app, "Calculate my baseline")
        XCTAssert(app.staticTexts["Total daily nicotine load"].waitForExistence(timeout: 5) ||
                  app.staticTexts["TOTAL DAILY NICOTINE LOAD"].exists, "Baseline summary didn't appear")
        tapSettled(app, "Continue")
        tap(button(app, "6–30 min"))
        tap(button(app, "Coffee"))
        tapSettled(app, "Continue")
        // Name, then the reason: submitting the name moves to the reason field.
        let name = app.textFields.firstMatch
        XCTAssert(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Sam\n")
        app.typeText("Breathe easier")
        tapSettled(app, "Save my reason")
        tap(button(app, "First time"))
        tapSettled(app, "Continue")
        tap(button(app, "Not for me"))
        tapSettled(app, "Continue")
        // F04 Quit Day: hold for 1.5 s.
        snap(app, "04-quit-day")
        let hold = app.buttons["onboarding.hold"]
        XCTAssert(hold.waitForExistence(timeout: 5))
        hold.press(forDuration: 2.2)
        // F05 the plan builds, then F06 the plan is ready: prep week is free, nothing is charged.
        tapSettled(app, "See my plan")
        XCTAssert(app.staticTexts["Your plan is ready"].waitForExistence(timeout: 10), "Plan screen didn't appear")
        snap(app, "05-plan")
        tapSettled(app, "Start my prep week")
        // F07 reminders: allowing asks for notifications.
        snap(app, "05b-reminders")
        tapSettled(app, "Yes, remind me")
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if springboard.alerts.buttons["Allow"].waitForExistence(timeout: 5) { springboard.alerts.buttons["Allow"].tap() }
        // No paywall after onboarding (decision 15): Prep 1 opens by itself; close it to reach Home.
        let closeLesson = button(app, "Your place is saved")
        XCTAssert(closeLesson.waitForExistence(timeout: 10), "Prep day 1 didn't open after onboarding")
        snap(app, "06b-day1")
        tapWhenStill(app, closeLesson, name: "Close lesson")

        // Prep Home (S4): log a use, ride out a craving, visit each tab.
        XCTAssert(app.buttons["Craving SOS"].waitForExistence(timeout: 10))
        snap(app, "07-home-prep")
        tap(button(app, "Log"))
        let vaped = logSheetRow(app, "vape")
        tapWhenStill(app, vaped, name: "Vaped")
        // A use during prep is just counted: the sheet closes.
        XCTAssert(vaped.waitForNonExistence(timeout: 5), "The log sheet didn't close")
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
        tapWhenStill(app, logSheetRow(app, "vape"), name: "Vaped")
        XCTAssert(app.staticTexts["Thanks for telling me."].waitForExistence(timeout: 5))
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
        XCTAssert(app.staticTexts["Thanks for telling me."].waitForExistence(timeout: 5), "The slip screen didn't appear")
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

    /// Every tap on the water row's + logs a glass straight away, quick taps or slow (S21.2). Since S27.12 water is one
    /// row on Today ("Water · 3 of 8 glasses"), not a tracker, so the count is read from the row's label.
    func testWaterRowLogsEveryTap() {
        let app = launch(["-dx.homeScenario", "day3", "-dx.store", "pro"])
        let row = app.staticTexts["today.water.count"]
        let add = app.buttons["today.water.add"]
        // The row sits under Your day; scroll until it's on screen.
        for _ in 0..<4 where !(add.exists && add.isHittable) {
            app.scrollViews.firstMatch.swipeUp()
            RunLoop.current.run(until: .now.addingTimeInterval(0.6))
        }
        XCTAssert(row.waitForExistence(timeout: 10), "No water row")
        XCTAssert(add.waitForExistence(timeout: 5), "No + on the water row")
        snap(app, "40-water-row-start")
        var glasses = glassCount(row)
        for tapNumber in 1...6 {
            let quick = tapNumber <= 3
            add.tap()
            RunLoop.current.run(until: .now.addingTimeInterval(quick ? 0.4 : 1.2))
            let nowGlasses = glassCount(row)
            XCTAssertEqual(nowGlasses, glasses + 1, "Tap \(tapNumber) didn't log a glass")
            glasses = nowGlasses
        }
        snap(app, "41-water-row-after")
    }

    // MARK: Steps

    private func rideOutCraving(_ app: XCUIApplication) {
        tap(app.buttons["Craving SOS"])
        // F13: Jelli's session, with "It passed" on screen from the start (no countdown).
        XCTAssert(app.buttons["It passed"].waitForExistence(timeout: 5))
        XCTAssert(app.buttons["Still strong"].exists)
        snap(app, "sos-session")
        tap(app.buttons["It passed"])
        XCTAssert(app.staticTexts["You rode it out."].waitForExistence(timeout: 5))
        tap(app.buttons["Back to my day"])
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

    /// Taps the button with this label once exactly one is on screen, enabled and still (see `tapWhenStill`).
    private func tapSettled(_ app: XCUIApplication, _ label: String, file: StaticString = #filePath, line: UInt = #line) {
        let query = app.buttons.matching(NSPredicate(format: "label == %@", label))
        let deadline = Date.now.addingTimeInterval(10)
        while query.count != 1, Date.now < deadline { RunLoop.current.run(until: .now.addingTimeInterval(0.2)) }
        XCTAssertEqual(query.count, 1, "Expected one \"\(label)\" button", file: file, line: line)
        tapWhenStill(app, query.element, name: label, file: file, line: line)
    }

    /// Taps an element once it's enabled and has stopped moving, so a step's slide-in or a sheet growing to full
    /// height has finished: a tap mid-slide can miss. It taps the element's centre rather than asking XCUITest
    /// whether it's hittable, which on iOS 27 can fail outright while a sheet resizes.
    private func tapWhenStill(_ app: XCUIApplication, _ element: XCUIElement, name: String,
                              file: StaticString = #filePath, line: UInt = #line) {
        let screen = app.windows.firstMatch.frame
        var last = CGRect.null
        var settled = false
        let deadline = Date.now.addingTimeInterval(10)
        while Date.now < deadline {
            let frame = element.frame
            if frame == last, !frame.isEmpty, screen.contains(CGPoint(x: frame.midX, y: frame.midY)), element.isEnabled {
                settled = true
                break
            }
            last = frame
            RunLoop.current.run(until: .now.addingTimeInterval(0.3))
        }
        XCTAssert(settled, "\"\(name)\" never settled on screen", file: file, line: line)
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    /// The log sheet's row for a product ("vape", "cigarettes", "pouches"), once the sheet is up. Home's prep rows
    /// have the same names, so it's found by the sheet's identifier.
    private func logSheetRow(_ app: XCUIApplication, _ product: String, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let row = app.buttons["log.use.\(product)"]
        XCTAssert(row.waitForExistence(timeout: 5), "No \"\(product)\" row in the log sheet", file: file, line: line)
        return row
    }

    /// "1.25 of 2.0 litres, 5 of 8 glasses" → 5.
    /// "3" from the water row's "Water · 3 of 8 glasses" (its label, or its value where VoiceOver puts it there).
    private func glassCount(_ element: XCUIElement) -> Int {
        let value = element.label + " " + (element.value as? String ?? "")
        guard let range = value.range(of: #"(\d+) of \d+ glasses"#, options: .regularExpression) else { return -1 }
        return Int(value[range].prefix { $0.isNumber }) ?? -1
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
