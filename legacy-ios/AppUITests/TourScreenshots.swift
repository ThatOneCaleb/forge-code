import XCTest

final class TourScreenshots: XCTestCase {
    func testTour() throws {
        let app = XCUIApplication()
        app.launch()

        func shot(_ name: String) {
            let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            a.lifetime = .keepAlways
            a.name = name
            add(a)
        }
        func back() {
            let b = app.navigationBars.buttons.firstMatch
            if b.exists { b.tap(); sleep(1) }
        }

        // 1. Lesson Map
        _ = app.staticTexts["Move & Turn"].waitForExistence(timeout: 20)
        shot("01-LessonMap")

        // 2. Lesson — Blocks mode
        app.staticTexts["Move & Turn"].tap()
        sleep(2)
        shot("02-Lesson-Blocks")

        // 3. Lesson — Code mode
        if app.buttons["Code"].waitForExistence(timeout: 3) {
            app.buttons["Code"].tap(); sleep(1); shot("03-Lesson-Code")
        } else if app.segmentedControls.buttons["Code"].exists {
            app.segmentedControls.buttons["Code"].tap(); sleep(1); shot("03-Lesson-Code")
        }
        back()

        // 4. Challenges tab
        if app.tabBars.buttons["Challenges"].waitForExistence(timeout: 3) {
            app.tabBars.buttons["Challenges"].tap(); sleep(1); shot("04-Challenges")
            // 5. Open a challenge grid
            let card = app.staticTexts["Staircase Sprint"]
            if card.waitForExistence(timeout: 3) {
                card.tap(); sleep(2); shot("05-Challenge-Grid"); back()
            }
        }

        // 6. Badges
        if app.tabBars.buttons["Badges"].exists {
            app.tabBars.buttons["Badges"].tap(); sleep(1); shot("06-Badges")
        }

        // 7. Build Log
        if app.tabBars.buttons["Build Log"].exists {
            app.tabBars.buttons["Build Log"].tap(); sleep(1); shot("07-BuildLog")
        }
    }
}
