import XCTest

/// Phase 1a verification: tap the Field tab, run the 3D animation,
/// capture a screenshot to confirm the field renders.
final class FieldShot: XCTestCase {
    func testField3DScreenshot() {
        let app = XCUIApplication()
        app.launch()

        // Wait for the app to finish loading (Kid seeding + tab bar).
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 20), "Tab bar should appear")

        // The Field tab may be in the "More" overflow when there are >4 tabs.
        // Try direct first; if absent, go through More.
        let fieldTabDirect = tabBar.buttons["Field"]
        if fieldTabDirect.waitForExistence(timeout: 3) {
            fieldTabDirect.tap()
        } else {
            // Open the More menu
            let moreButton = tabBar.buttons["More"]
            XCTAssertTrue(moreButton.waitForExistence(timeout: 5), "More button should be present in tab bar")
            moreButton.tap()

            // In the More table, tap the Field row
            let fieldCell = app.tables.cells.staticTexts["Field"]
            XCTAssertTrue(fieldCell.waitForExistence(timeout: 5), "Field entry should appear in More list")
            fieldCell.tap()
        }

        // Wait for the 3D scene to initialize Metal rendering and settle.
        // SceneKit on the Simulator takes a moment to warm up after first load.
        sleep(4)

        // Capture the field before running.
        let beforeAttachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        beforeAttachment.name = "Field3D-initial"
        beforeAttachment.lifetime = .keepAlways
        add(beforeAttachment)

        // Tap Run — the button is labeled "Run program" in accessibility.
        let runButton = app.buttons["Run program"]
        XCTAssertTrue(runButton.waitForExistence(timeout: 5), "Run button should be visible")
        runButton.tap()

        // Wait for the animation to complete (~12 steps × 0.3 s + buffer).
        sleep(5)

        // Capture the field after animation.
        let afterAttachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        afterAttachment.name = "Field3D"
        afterAttachment.lifetime = .keepAlways
        add(afterAttachment)
    }
}
