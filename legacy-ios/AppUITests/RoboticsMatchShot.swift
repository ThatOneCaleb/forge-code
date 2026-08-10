import XCTest

/// R2 verification: navigate to the Robotics tab, open a match, run the pre-seeded
/// starter program, and capture screenshots. Screenshots are saved both as XCTAttachments
/// AND written directly to /tmp/ so they survive the "Failed to terminate" teardown
/// bug in Xcode 27 beta.
@MainActor
final class RoboticsMatchShot: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = true
    }

    func testRoboticsMatchScreenshots() {
        let app = XCUIApplication()
        app.launch()

        var shotCount = 0

        func shot(_ name: String) {
            let screenshot = XCUIScreen.main.screenshot()
            // XCTAttachment (may not survive teardown failure)
            let a = XCTAttachment(screenshot: screenshot)
            a.lifetime = .keepAlways
            a.name = name
            add(a)
            // Also write PNG directly to /tmp/r_screenshots/ for fallback extraction
            shotCount += 1
            let outDir = "/tmp/r_screenshots"
            try? FileManager.default.createDirectory(
                atPath: outDir, withIntermediateDirectories: true)
            let path = "\(outDir)/\(String(format: "%02d", shotCount))-\(name).png"
            try? screenshot.pngRepresentation.write(to: URL(fileURLWithPath: path))
        }

        // Wait for tab bar
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 25) else {
            shot("R2-00-NoTabBar")
            return
        }
        shot("R2-00-AppLoaded")

        // Navigate to the Robotics tab
        let roboticsTab = tabBar.buttons["Robotics"]
        if roboticsTab.waitForExistence(timeout: 4) {
            roboticsTab.tap()
        } else {
            let moreBtn = tabBar.buttons["More"]
            if moreBtn.waitForExistence(timeout: 5) {
                moreBtn.tap()
                let roboticsCell = app.tables.cells.staticTexts["Robotics"]
                if roboticsCell.waitForExistence(timeout: 5) {
                    roboticsCell.tap()
                }
            }
        }

        sleep(5)
        shot("R2-01-MatchList")

        // Tap the first available match card
        // Match cards are NavigationLink rows — look for staticText or cells
        let knownNames = ["Mars Outpost Expedition Match", "Cargo Command Season Match"]
        var tapped = false
        for name in knownNames {
            // Try staticText (the card title)
            let el = app.staticTexts[name].firstMatch
            if el.waitForExistence(timeout: 3) {
                el.tap()
                tapped = true
                break
            }
        }
        if !tapped {
            // Fallback: any cell in the list
            let cells = app.cells.allElementsBoundByIndex
            for cell in cells where !cell.label.isEmpty {
                cell.tap()
                tapped = true
                break
            }
        }
        if !tapped {
            // Final fallback: any link element
            for el in app.links.allElementsBoundByIndex where !el.label.isEmpty {
                el.tap()
                tapped = true
                break
            }
        }
        guard tapped else {
            shot("R2-01b-NoMatch")
            return
        }

        sleep(6)
        shot("R2-02-MatchField")

        // Tap the Launch button (multi-launch match: label starts with "Launch").
        var launched = false
        for btn in app.buttons.allElementsBoundByIndex {
            if btn.label.hasPrefix("Launch") && btn.isEnabled {
                btn.tap(); launched = true; break
            }
        }
        if !launched {
            shot("R2-03-NoLaunchButton"); return
        }

        sleep(2)
        shot("R2-03-Launching")

        sleep(20)
        shot("R2-04-AfterLaunch")   // between-launch banner + updated HUD

        // Finish the match to see the aggregate scoreboard.
        let finish = app.buttons["Finish match and see the final score"]
        if finish.waitForExistence(timeout: 6) {
            finish.tap()
            sleep(2)
            shot("R2-05-Scoreboard")
        } else {
            shot("R2-05-NoFinish")
        }
    }
}
