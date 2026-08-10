import XCTest

final class SolveScreenshots: XCTestCase {
    func testSolveMoveAndTurn() throws {
        let app = XCUIApplication()
        app.launch()

        func shot(_ name: String) {
            let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            a.lifetime = .keepAlways
            a.name = name
            add(a)
        }
        func tap(_ label: String) {
            let b = app.buttons[label]
            if b.waitForExistence(timeout: 4) { b.tap(); usleep(600_000) }
        }

        _ = app.staticTexts["Move & Turn"].waitForExistence(timeout: 20)
        app.staticTexts["Move & Turn"].tap()
        sleep(2)

        // Canonical solution: turnRight(); move(); move();
        tap("Turn Right")
        tap("Move")
        tap("Move")
        shot("08-Program-Built")

        // Run and let the animation + success state play out.
        tap("Run")
        sleep(5)
        shot("09-Success")
    }
}
