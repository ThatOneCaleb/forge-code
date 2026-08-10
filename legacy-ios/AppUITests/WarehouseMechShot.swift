import XCTest

/// Part D verification for Cargo Command (field_warehouse): capture the NEW
/// warehouse-styled reactive mechanisms rendering in 3D — the roll-up bay door,
/// the ribbed dock-leveler, and the yellow/black release lever + roller chute —
/// and drive "Open the Bay" so the roll-up door is caught LIFTING on activation
/// (geometry + reaction in a single flow).
///
/// PNGs are written directly to /tmp/w_screenshots/ so they survive the
/// Xcode-27-beta "Failed to terminate" teardown bug.
@MainActor
final class WarehouseMechShot: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = true
    }

    private var shotCount = 0
    private func shot(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let a = XCTAttachment(screenshot: screenshot)
        a.lifetime = .keepAlways
        a.name = name
        add(a)
        shotCount += 1
        let outDir = "/tmp/w_screenshots"
        try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
        let path = "\(outDir)/\(String(format: "%02d", shotCount))-\(name).png"
        try? screenshot.pngRepresentation.write(to: URL(fileURLWithPath: path))
    }

    /// Open the Robotics tab (it lives under the "More" overflow).
    private func openRobotics(_ app: XCUIApplication) {
        let tabBar = app.tabBars.firstMatch
        _ = tabBar.waitForExistence(timeout: 25)
        if tabBar.buttons["Robotics"].waitForExistence(timeout: 3) {
            tabBar.buttons["Robotics"].tap()
        } else if tabBar.buttons["More"].waitForExistence(timeout: 5) {
            tabBar.buttons["More"].tap()
            let cell = app.tables.cells.staticTexts["Robotics"]
            if cell.waitForExistence(timeout: 5) { cell.tap() }
        }
        sleep(3)
    }

    /// Open a challenge mission by title, scrolling the ladder into view first.
    private func openMission(_ app: XCUIApplication, _ title: String) -> Bool {
        let cell = app.staticTexts[title].firstMatch
        var tries = 0
        while !cell.exists && tries < 4 { app.swipeUp(); tries += 1 }
        guard cell.waitForExistence(timeout: 3) else { return false }
        cell.tap()
        sleep(5)   // let the SceneKit field build + settle
        return true
    }

    func testWarehouseBayDoorReacts() {
        let app = XCUIApplication()
        app.launch()

        openRobotics(app)
        shot("W-01-ChallengeList")

        guard openMission(app, "Open the Bay") else { shot("W-02-BayMissing"); return }
        shot("W-02-Bay-AtRest")   // roll-up door + dock-leveler + lever/chute at rest

        // Inject the verified bay-door program, then Run and catch the door lifting.
        let editor = app.textViews.firstMatch
        guard editor.waitForExistence(timeout: 6) else { shot("W-03-NoEditor"); return }
        editor.tap()
        editor.press(forDuration: 1.2)
        let selectAll = app.menuItems["Select All"]
        if selectAll.waitForExistence(timeout: 3) { selectAll.tap() }
        editor.typeText("""
        drive.forward(100);
        drive.turnRight(90);
        drive.forward(90);
        drive.forward(20);
        """)
        shot("W-03-ProgramEntered")

        // Dismiss the keyboard and Run.
        if app.buttons["Return"].exists { app.buttons["Return"].tap() }
        app.swipeUp()   // scroll controls into view / dismiss keyboard
        let run = app.buttons["Run mission program"]
        guard run.waitForExistence(timeout: 5) else { shot("W-04-NoRun"); return }
        run.tap()

        // The rover now DRIVES the corridor (time scales with distance, ~2 s total)
        // instead of teleporting. Fire rapid sub-second captures to catch it partway
        // along the path — proof of real driving, not snapping to the end pose.
        for i in 0..<7 {
            usleep(450_000)   // 0.45 s
            shot("W-1\(i)-Driving")
        }
        sleep(3)
        shot("W-20-Result")
    }
}
