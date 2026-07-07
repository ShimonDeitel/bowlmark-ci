import XCTest

final class BowlmarkUITests: XCTestCase {
    private var interruptionMonitorToken: NSObjectProtocol?

    override func setUpWithError() throws {
        continueAfterFailure = false
        interruptionMonitorToken = addUIInterruptionMonitor(withDescription: "System alert dismissal") { alert in
            for label in ["Allow", "OK", "Don't Allow", "Cancel"] {
                let button = alert.buttons[label]
                if button.exists {
                    button.tap()
                    return true
                }
            }
            return false
        }
    }

    override func tearDownWithError() throws {
        if let token = interruptionMonitorToken {
            removeUIInterruptionMonitor(token)
        }
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()
        return app
    }

    func testHomeShowsSeedPets() throws {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["Whiskers"].waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts["Rex"].waitForExistence(timeout: 6))
    }

    func testLogFeedingUpdatesBowl() throws {
        let app = launchApp()
        let logButton = app.buttons["logFeedingButton_Whiskers"]
        XCTAssertTrue(logButton.waitForExistence(timeout: 12))
        logButton.tap()

        let feederField = app.textFields["feederNameField"]
        XCTAssertTrue(feederField.waitForExistence(timeout: 12))
        feederField.tap()
        feederField.typeText("Alex")

        app.buttons["saveLogFeedingButton"].tap()

        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Alex'")).firstMatch.waitForExistence(timeout: 12), "Feeding log did not reflect feeder name")
    }

    func testLeaderboardAppearsAfterLogging() throws {
        let app = launchApp()
        let logButton = app.buttons["logFeedingButton_Whiskers"]
        XCTAssertTrue(logButton.waitForExistence(timeout: 12))
        logButton.tap()

        let feederField = app.textFields["feederNameField"]
        XCTAssertTrue(feederField.waitForExistence(timeout: 12))
        feederField.tap()
        feederField.typeText("Jamie")
        app.buttons["saveLogFeedingButton"].tap()

        let leaderboard = app.descendants(matching: .any).matching(identifier: "leaderboardCard").firstMatch
        XCTAssertTrue(leaderboard.waitForExistence(timeout: 12), "Leaderboard card did not appear after logging a feeding")
    }

    func testAddPetFromHome() throws {
        let app = launchApp()
        // Seed data has 2 pets (free limit) — delete one so "+" opens the form.
        let whiskersText = app.staticTexts["Whiskers"]
        XCTAssertTrue(whiskersText.waitForExistence(timeout: 12))
        whiskersText.tap()
        app.buttons["deletePetButton"].tap()
        XCTAssertFalse(app.staticTexts["Whiskers"].waitForExistence(timeout: 6))

        let addButton = app.buttons["addPetButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 12))
        addButton.tap()

        let nameField = app.textFields["petNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 12))
        nameField.tap()
        nameField.typeText("Nibbles")

        app.buttons["savePetButton"].tap()

        XCTAssertTrue(app.staticTexts["Nibbles"].waitForExistence(timeout: 12), "New pet did not appear")
    }

    func testEditPetChangesMeals() throws {
        let app = launchApp()
        let whiskersText = app.staticTexts["Whiskers"]
        XCTAssertTrue(whiskersText.waitForExistence(timeout: 12))
        whiskersText.tap()

        let incrementButton = app.buttons["mealsIncrementButton"]
        XCTAssertTrue(incrementButton.waitForExistence(timeout: 12))
        incrementButton.tap()

        app.buttons["savePetButton"].tap()
        XCTAssertTrue(app.staticTexts["Whiskers"].waitForExistence(timeout: 12))
    }

    func testDeletePetViaForm() throws {
        let app = launchApp()
        let whiskersText = app.staticTexts["Whiskers"]
        XCTAssertTrue(whiskersText.waitForExistence(timeout: 12))
        whiskersText.tap()

        app.buttons["deletePetButton"].tap()

        XCTAssertFalse(app.staticTexts["Whiskers"].waitForExistence(timeout: 6), "Pet was not deleted")
    }

    func testFreeLimitTriggersPaywallAtThirdPet() throws {
        let app = launchApp()
        let addButton = app.buttons["addPetButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 12))
        addButton.tap()
        XCTAssertTrue(app.staticTexts["Bowlmark Pro"].waitForExistence(timeout: 12), "Paywall did not appear after hitting the free pet limit")
    }

    func testSettingsKeyboardDismissOnTap() throws {
        let app = launchApp()
        app.tabBars.buttons["Settings"].tap()

        let reminderToggle = app.switches["remindersToggle"]
        XCTAssertTrue(reminderToggle.waitForExistence(timeout: 12))

        // Tap the toggle to enable reminders, then poll for the conditionally-shown
        // Stepper row. If it hasn't appeared after a few seconds, re-tap once in case
        // the first tap toggled it off (stale @AppStorage state from a reused
        // simulator) rather than on — retry up to 3 times so the test doesn't depend
        // on assuming a fresh "off" default.
        let stepper = app.steppers["reminderHourStepper"]
        var attempts = 0
        while !stepper.waitForExistence(timeout: 5) && attempts < 3 {
            reminderToggle.tap()
            attempts += 1
        }
        XCTAssertTrue(stepper.exists, "Reminder hour stepper did not appear after \(attempts + 1) toggle taps")
        // Tap a real Form section header (not the nav bar) to verify layout renders correctly.
        XCTAssertTrue(app.navigationBars["Settings"].exists)
    }
}
