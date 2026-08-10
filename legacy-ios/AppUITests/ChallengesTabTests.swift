import XCTest

final class ChallengesTabTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testChallengesTabExistsAndLoads() throws {
        // Wait for the app to finish seeding the Kid (ProgressView disappears)
        let learnTab = app.tabBars.buttons["Learn"]
        XCTAssertTrue(learnTab.waitForExistence(timeout: 15), "Learn tab should appear")

        // Challenges tab must be present
        let challengesTab = app.tabBars.buttons["Challenges"]
        XCTAssertTrue(challengesTab.exists, "Challenges tab must exist in tab bar")

        // Tap it
        challengesTab.tap()

        // Navigation title "Challenges" should appear
        let navBar = app.navigationBars["Challenges"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 5), "Challenges navigation bar should appear")

        // "Bonus Challenges" header text should be present
        let header = app.staticTexts["Bonus Challenges"]
        XCTAssertTrue(header.waitForExistence(timeout: 5), "Bonus Challenges header should be visible")

        // Capture a screenshot as evidence
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Challenges-Tab-Loaded"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
