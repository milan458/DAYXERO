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

        // Onboarding (S22): the 18+ confirmation is the welcome screen's footer.
        snap(app, "01-welcome")
        tap(app.buttons["Build my plan"])
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
        snap(app, "04-quit-day")
        let hold = app.buttons["onboarding.hold"]
        XCTAssert(hold.waitForExistence(timeout: 5))
        hold.press(forDuration: 2.2)
        XCTAssert(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Quit Day is")).firstMatch.waitForExistence(timeout: 15), "Plan reveal didn't appear")
        snap(app, "05-reveal")
        tapSettled(app, "Continue")
        tapSettled(app, "Maybe later")               // reminders

        // Paywall (S3), against the mock store
        let cta = app.buttons["paywall.cta"]
        XCTAssert(cta.waitForExistence(timeout: 10))
        // The button is disabled until the plans have loaded; a tap before that does nothing.
        let loaded = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isEnabled == true"), object: cta)
        XCTAssertEqual(XCTWaiter().wait(for: [loaded], timeout: 10), .completed, "The paywall's plans never loaded")
        snap(app, "06-paywall")
        tapWhenStill(app, cta, name: "paywall.cta")
        // Starting the trial asks for notifications, for the reminder the day before it ends (S3.9).
        let allow = XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.buttons["Allow"]
        if allow.waitForExistence(timeout: 5) { allow.tap() }
        tapSettled(app, "Start prep day 1")

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

    /// Every tap on Log raises the water straight away, quick taps or slow (S21.2): Milan saw it sit still and
    /// then jump up by all the taps at once. Reads the amount from VoiceOver and the water's height from the pixels.
    func testWaterRisesOnEveryTap() {
        let app = launch(["-dx.homeScenario", "day3", "-dx.store", "pro"])
        XCTAssert(app.buttons["Craving SOS"].waitForExistence(timeout: 10))
        tap(app.buttons["Water"].firstMatch)
        let pill = app.descendants(matching: .any)["Water today"]
        XCTAssert(pill.waitForExistence(timeout: 5), "No water pill")
        // "Log 250 ml", or "Log 8 fl oz" where the simulator's region uses US units.
        let log = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Log 250 ml' OR label CONTAINS[c] 'Log 8 fl oz'")).firstMatch
        XCTAssert(log.waitForExistence(timeout: 5), "No Log button")
        RunLoop.current.run(until: .now.addingTimeInterval(1))
        // Very large text can still push Log under the dock; scroll it clear so a tap can't land on a tab.
        if log.frame.maxY > app.buttons["Craving SOS"].frame.minY - 4 {
            app.scrollViews.firstMatch.swipeUp()
            RunLoop.current.run(until: .now.addingTimeInterval(1))
        }
        snap(app, "40-water-start")
        var glasses = glassCount(pill)
        var height = liquidHeight(app, pill)
        for tapNumber in 1...6 {
            let quick = tapNumber <= 3
            log.tap()
            RunLoop.current.run(until: .now.addingTimeInterval(quick ? 0.4 : 1.2))
            snap(app, "41-water-tap-\(tapNumber)")
            let nowGlasses = glassCount(pill)
            XCTAssertEqual(nowGlasses, glasses + 1, "Tap \(tapNumber) didn't log a glass")
            glasses = nowGlasses
            // The pixel check needs the whole pill on screen; small phones scroll it partly away to reach Log.
            if let before = height, let after = liquidHeight(app, pill) {
                XCTAssertGreaterThan(after, before + 0.04, "The water didn't rise after tap \(tapNumber) (\(before) → \(after))")
                height = after
            } else {
                height = nil
            }
        }
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
    private func glassCount(_ pill: XCUIElement) -> Int {
        let value = pill.value as? String ?? ""
        guard let range = value.range(of: #"(\d+) of \d+ glasses"#, options: .regularExpression) else { return -1 }
        return Int(value[range].prefix { $0.isNumber }) ?? -1
    }

    /// How much of the pill is blue water, 0...1, read down one column clear of the glass highlight; nil when the
    /// pill isn't wholly on screen.
    private func liquidHeight(_ app: XCUIApplication, _ pill: XCUIElement) -> Double? {
        guard app.windows.firstMatch.frame.contains(pill.frame), let image = pill.screenshot().image.cgImage else { return nil }
        let w = image.width, h = image.height
        var pixels = [UInt8](repeating: 0, count: w * h * 4)
        let drawn: Bool = pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(data: buffer.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
            return true
        }
        guard drawn else { return nil }
        let x = w * 62 / 100
        var blue = 0
        for y in 0..<h {
            let i = (y * w + x) * 4
            let r = Int(pixels[i]), b = Int(pixels[i + 2])
            if b > 90, b > r + 15 { blue += 1 }
        }
        return Double(blue) / Double(h)
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
