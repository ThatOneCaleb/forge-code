import XCTest

/// Verifies the new single-mission challenge screen renders: navigate to the
/// Robotics tab, open the "Signal Rocket" challenge (which places the rocket +
/// launcher 3D models on the field), and exercise the attachment picker.
/// Screenshots are written to /tmp/r_mission/ for fallback extraction.
@MainActor
final class RoboticsMissionShot: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = true
    }

    func testMissionScreen() {
        let app = XCUIApplication()
        app.launch()

        var n = 0
        func shot(_ name: String) {
            let s = XCUIScreen.main.screenshot()
            let a = XCTAttachment(screenshot: s)
            a.lifetime = .keepAlways; a.name = name; add(a)
            n += 1
            let dir = "/tmp/r_mission"
            try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
            try? s.pngRepresentation.write(to: URL(fileURLWithPath: "\(dir)/\(String(format: "%02d", n))-\(name).png"))
        }

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 25) else { shot("NoTabBar"); return }

        let roboticsTab = tabBar.buttons["Robotics"]
        if roboticsTab.waitForExistence(timeout: 4) {
            roboticsTab.tap()
        } else if tabBar.buttons["More"].waitForExistence(timeout: 4) {
            tabBar.buttons["More"].tap()
            let cell = app.tables.cells.staticTexts["Robotics"]
            if cell.waitForExistence(timeout: 5) { cell.tap() }
        }

        sleep(4)
        shot("01-RoboticsList")

        // Open the Signal Rocket challenge (has the rocket/launcher models).
        let card = app.staticTexts["Signal Rocket"].firstMatch
        if card.waitForExistence(timeout: 6) {
            card.tap()
        } else {
            shot("01b-NoSignalRocket"); return
        }

        sleep(6)
        shot("02-MissionField")

        // Select the Launch Tool attachment chip.
        let launchTool = app.buttons["Launch Tool, selected"].firstMatch
        let launchToolUnsel = app.staticTexts["Launch Tool"].firstMatch
        if launchToolUnsel.waitForExistence(timeout: 4) {
            launchToolUnsel.tap()
            sleep(1)
            shot("03-LaunchToolSelected")
        } else if launchTool.exists {
            shot("03-LaunchToolAlready")
        } else {
            shot("03-NoAttachmentChip")
        }
    }
}
