import XCTest

/// The whole journey on a real build (S16.1): onboarding → prep → Day Xero → first week → maintenance.
/// The hard paywall follows onboarding (16 Nov 2026): the run starts the free trial there on the mock store.
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
        tapSettled(app, "Get started")
        // How it works: prep, Day Xero, four weeks. Nothing to answer.
        snap(app, "01b-how-it-works")
        tapSettled(app, "Continue")
        tap(button(app, "Disposables"), timeout: 10)
        snap(app, "02-products")
        tapSettled(app, "Continue")
        // Good company: the vaping figure. Nothing to answer.
        XCTAssert(app.staticTexts["adults who vape intend to quit"].waitForExistence(timeout: 5), "Good company didn't follow the products")
        snap(app, "02b-good-company")
        tapSettled(app, "Continue")
        // The vape baseline starts on the region's usual price, so it can go straight on.
        snap(app, "03-baseline")
        tapSettled(app, "Calculate my baseline")
        XCTAssert(app.staticTexts["Your nicotine, counted in cigarettes"].waitForExistence(timeout: 5), "Baseline summary didn't appear")
        tapSettled(app, "Continue")
        // What works: medicine plus support. Nothing to answer.
        snap(app, "03a-what-works")
        tapSettled(app, "Build my plan")
        tap(button(app, "Coffee"))
        tapSettled(app, "Continue")
        // Craving SOS, for the trigger just picked.
        XCTAssert(app.staticTexts["In for 4, out for 6."].waitForExistence(timeout: 5), "The SOS screen didn't follow the triggers")
        snap(app, "03b-craving-sos")
        tapSettled(app, "Continue")
        // Name, then the reason: submitting the name moves to the reason field.
        let name = app.textFields.firstMatch
        XCTAssert(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Sam\n")
        app.typeText("Breathe easier")
        tapSettled(app, "Continue")
        tap(button(app, "Irritability"))
        tapSettled(app, "Continue")
        // On a small iPhone "Not for me" sits under the pinned Continue button, so a tap there hit Continue instead.
        let notForMe = button(app, "Not for me")
        XCTAssert(notForMe.waitForExistence(timeout: 5))
        scrollIntoView(app, notForMe)
        tap(notForMe)
        tapSettled(app, "Continue")
        // Your day: the morning pledge and the night check-in.
        snap(app, "03c-your-day")
        tapSettled(app, "Continue")
        // F04 Day Xero: hold for 1.5 s.
        snap(app, "04-quit-day")
        let hold = app.buttons["onboarding.hold"]
        XCTAssert(hold.waitForExistence(timeout: 5))
        hold.press(forDuration: 2.2)
        // The hold hands over to Continue once Day Xero is set (010).
        tapSettled(app, "Continue")
        // F06 the plan is ready: nothing is charged on it. (The "plan builds" screen before it was removed, 19 Nov 2026.)
        XCTAssert(app.buttons["Start my prep week"].waitForExistence(timeout: 10), "Plan screen didn't appear")
        snap(app, "05-plan")
        tapSettled(app, "Start my prep week")
        // F07 reminders: allowing asks for notifications.
        snap(app, "05b-reminders")
        tapSettled(app, "Yes, remind me")
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if springboard.alerts.buttons["Allow"].waitForExistence(timeout: 5) { springboard.alerts.buttons["Allow"].tap() }
        // The first-run paywall: start the free trial, then "You're all set" leads on.
        // Paywall v2: what you'll keep and everything in Pro come before the offer.
        let cta = app.buttons["paywall.cta"]
        for page in 1...2 where !cta.exists {
            let next = app.buttons["paywall.continue"]
            guard next.waitForExistence(timeout: 10) else { break }
            snap(app, "06-paywall-page\(page)")
            tapWhenStill(app, next, name: "Paywall continue")
            // Let the next page take the last one's place before looking for its button.
            RunLoop.current.run(until: .now.addingTimeInterval(1))
        }
        XCTAssert(cta.waitForExistence(timeout: 10), "The paywall didn't follow onboarding")
        snap(app, "06-paywall")
        tapWhenStill(app, cta, name: "Start trial")
        tapSettled(app, "Start")
        // Prep 1 opens by itself after the paywall; close it to reach Home.
        let closeLesson = button(app, "Your place is saved")
        XCTAssert(closeLesson.waitForExistence(timeout: 10), "Prep day 1 didn't open after onboarding")
        snap(app, "06b-day1")
        tapWhenStill(app, closeLesson, name: "Close lesson")
        // Closing Prep 1 unplayed leaves it undone and on Today's card, whatever the hour (QW1).
        XCTAssert(app.descendants(matching: .any)["today.lesson"].waitForExistence(timeout: 10),
                  "Prep 1 left Today's card after it was closed")
        let undone = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@ OR label BEGINSWITH %@", "Prep: 0 of", "Prep 0 of")).firstMatch
        XCTAssert(undone.waitForExistence(timeout: 5), "Prep 1 was counted as done without being played")

        // Prep Home (S4): log a use, ride out a craving, visit each tab. The use cell's label opens the log (UX-05).
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
        // A use after Day Xero is a slip: talked through, and nothing resets (S8).
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
        // v5: Settings opens from the gear on Progress.
        tap(app.buttons["Progress"].firstMatch)
        tap(app.buttons["Settings"].firstMatch)
        snap(app, "32-settings")
        tap(app.buttons["Close"].firstMatch)
        XCTAssert(app.buttons["Craving SOS"].waitForExistence(timeout: 5))
    }

    /// Every tap on water's +1 logs a glass straight away, quick taps or slow (S21.2). Since UX-07 water is the left
    /// bento cell on Today ("7 / 9 glasses"); its count's label still reads "Water · 3 of 8 glasses".
    func testWaterRowLogsEveryTap() {
        let app = launch(["-dx.homeScenario", "day3", "-dx.store", "pro"])
        let row = app.staticTexts["today.water.count"]
        let add = app.buttons["today.water.add"]
        // Today fits without scrolling; on a small screen, scroll until the cell is on screen.
        // Clear of the floating tab bar too: a tap under it would land on a tab.
        let tabTop = app.buttons["Today"].firstMatch.frame.minY - 12
        for _ in 0..<4 where !(add.exists && add.isHittable && add.frame.maxY < tabTop) {
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

    /// Every calm tool opens and closes without the app going down. Box breathing and the longer out-breath run on the
    /// Bio-Orb and crashed on open (1 Nov 2026); this keeps the four on the shelf (v5, 056) honest.
    func testEveryCalmToolOpens() {
        let app = launch(["-dx.homeScenario", "day3", "-dx.store", "pro", "-dx.openCalmList", "YES"])
        XCTAssert(app.staticTexts["Calm tools"].waitForExistence(timeout: 10), "The calm tools list didn't open")
        for title in ["Box breathing", "Grounding", "Notice the urge", "Wind down"] {
            let row = button(app, title)
            XCTAssert(row.waitForExistence(timeout: 5), "No \"\(title)\" row")
            // v5: the tools are a grid of tall cards, so the last ones sit below the fold.
            scrollIntoView(app, row)
            tapWhenStill(app, row, name: title)
            let stop = app.buttons["Close"].firstMatch
            XCTAssert(stop.waitForExistence(timeout: 10), "\"\(title)\" didn't open")
            // Let the orb draw and its clock tick for a moment before checking the app is still up.
            RunLoop.current.run(until: .now.addingTimeInterval(2))
            XCTAssertEqual(app.state, .runningForeground, "The app went down opening \"\(title)\"")
            snap(app, "50-calm-\(title.lowercased().filter { $0.isLetter || $0.isNumber })")
            tapWhenStill(app, stop, name: "Close")
            XCTAssert(app.staticTexts["Calm tools"].waitForExistence(timeout: 5), "\"\(title)\" didn't close")
        }
    }

    /// The store's Wind down screen, opened straight from launch. On iPhone Duo's inner display the phone lies on its
    /// side, so the calm list's swipe can't bring Wind down into view; this takes the same shot without the list.
    func testStoreWindDown() {
        let app = launch(["-dx.homeScenario", "day3", "-dx.store", "pro", "-dx.openCalm", "longerOutBreath"])
        let stop = app.buttons["Close"].firstMatch
        XCTAssert(stop.waitForExistence(timeout: 10), "Wind down didn't open")
        RunLoop.current.run(until: .now.addingTimeInterval(2))
        XCTAssertEqual(app.state, .runningForeground, "The app went down opening Wind down")
        snap(app, "50-calm-winddown")
    }

    // MARK: Steps

    private func rideOutCraving(_ app: XCUIApplication) {
        tap(app.buttons["Craving SOS"])
        // F13: Jelli's session, with "It passed" on screen from the start (no countdown).
        XCTAssert(app.buttons["It passed"].waitForExistence(timeout: 5))
        snap(app, "sos-session")
        tap(app.buttons["It passed"])
        XCTAssert(app.staticTexts["You rode it out"].waitForExistence(timeout: 5))
        tap(app.buttons["Back to my day"])
        XCTAssert(app.buttons["Craving SOS"].waitForExistence(timeout: 5))
    }

    private func visitTabs(_ app: XCUIApplication, prefix: String) {
        for tab in ["Program", "Progress", "Today"] {
            tap(app.buttons[tab].firstMatch)
            // Let the tab cross-fade finish; the Program road plays in for about 2.6 s (today's stamp at 1.25 s,
            // the locked stops and hills from 1.3 s, the tease row at 2.1 s), so wait that out before the shot.
            RunLoop.current.run(until: .now.addingTimeInterval(tab == "Program" ? 3 : 1))
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
    /// Swipes the page up until the element's centre is on screen (at most five swipes).
    private func scrollIntoView(_ app: XCUIApplication, _ element: XCUIElement) {
        let screen = app.windows.firstMatch.frame.insetBy(dx: 0, dy: 120)
        for _ in 0..<5 where !screen.contains(CGPoint(x: element.frame.midX, y: element.frame.midY)) {
            app.swipeUp(velocity: .slow)
        }
    }

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
        if !settled {
            // What the small-iPhone leg needs to show: where the button was, whether it moved or stayed disabled.
            snap(app, "unsettled-\(name)-line\(line)")
        }
        XCTAssert(settled, "\"\(name)\" never settled on screen (line \(line): frame \(element.frame), last \(last), enabled \(element.isEnabled), screen \(screen))", file: file, line: line)
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
            let file = URL(fileURLWithPath: dir).appendingPathComponent("\(test)-\(name).png")
            if ProcessInfo.processInfo.environment["DX_HOST_SHOTS"] == "1" {
                // iPhone Duo open: XCUITest reads only the cover display, which is off, so its shot is black.
                // Leave a request and let the runner take the shot of the inner display (devices.yml).
                let request = file.deletingPathExtension().appendingPathExtension("req")
                try? Data().write(to: request)
                let deadline = Date().addingTimeInterval(20)
                while FileManager.default.fileExists(atPath: request.path), Date() < deadline {
                    RunLoop.current.run(until: .now.addingTimeInterval(0.25))
                }
            } else {
                try? shot.pngRepresentation.write(to: file)
            }
        }
    }
}
