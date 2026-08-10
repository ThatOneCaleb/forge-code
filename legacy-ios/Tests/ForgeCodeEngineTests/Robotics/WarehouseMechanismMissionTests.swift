import Testing
@testable import ForgeCodeEngine

/// Verified-solution + negative tests for the four reactive-mechanism missions
/// that bring **Cargo Command** (field_warehouse) up to the `forge-mission-feel`
/// experience bar — every one drives a model that visibly reacts:
///
///   mission_bay_door         (d2, 25 pts) — bump the roll-up bay door open, park inside
///   mission_dock_lift        (d3, 32 pts) — ready the dock ramp + deliver the red crate
///   mission_chute_release    (d4, 40 pts) — trip the chute lever + run the freed crate home
///   mission_warehouse_gauntlet(d5, 50 pts) — chute → deposit → bay door → precision park
///
/// Each proves a working solution AND a negative: skipping the mechanism trigger
/// (no bump / no arm-press) leaves the reactive model un-activated and fails the
/// `allRequired` rule — proving a drive-only program provably can't score it.
@Suite("Warehouse reactive-mechanism missions (Cargo Command)")
struct WarehouseMechanismMissionTests {

    private let sim = RoboticsSimulator()

    private func world() throws -> FieldWorld {
        try #require(try RoboticsLibrary.field(id: "field_warehouse"))
    }

    /// Rover at home_base centre (120, 20), heading north, standard gripper.
    private func robot() -> RobotModel {
        RobotModel(pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0),
                   armAngle: 0, isGripperOpen: true)
    }

    private func activated(_ run: RoboticsRun, _ id: String) -> Bool {
        run.sensorLog.contains {
            if case .mechanismActivated(id) = $0.kind { return true }
            return false
        }
    }

    // =========================================================================
    // MARK: mission_bay_door (d2, 25 pts) — roll-up gate + park inside
    // =========================================================================
    // Gate at (214,114), radius 16, bump; the sealed east bay (216..238) is blocked
    // by the door bar (x212..217) until the bump opens it. Drive the central y=120
    // corridor (clear of rack_2 below / shelf_2 above), bump the gate ending at the
    // door, then roll the last stretch into the bay.

    @Test("mission_bay_door — solution opens the bay and parks inside for 25")
    func bayDoorSuccess() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_bay_door"))
        let program = """
        drive.forward(100);
        drive.turnRight(90);
        drive.forward(90);
        drive.forward(20);
        """
        let run = sim.run(program: program, world: try world(), robot: robot(), mission: m)
        #expect(run.failureKind == nil, "got \(String(describing: run.failureKind))")
        #expect(run.missionResult?.success == true)
        #expect(run.missionResult?.score == 25)
        #expect(activated(run, "mech_bay_door"))
    }

    @Test("mission_bay_door — opening the door but not entering the bay fails allRequired")
    func bayDoorNoEntryFails() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_bay_door"))
        let program = """
        drive.forward(100);
        drive.turnRight(90);
        drive.forward(90);
        """
        let run = sim.run(program: program, world: try world(), robot: robot(), mission: m)
        #expect(run.missionResult?.success == false)
        #expect(activated(run, "mech_bay_door"))     // door opened…
        #expect(run.missionResult?.score == 15)       // …but the reach objective is unmet
    }

    // =========================================================================
    // MARK: mission_dock_lift (d3, 32 pts) — dock ramp + crate delivery
    // =========================================================================
    // Platform at (45,110), armPress. Ready it, then fetch crate_A (60,180) to
    // depot_red (10..60, 10..60).

    @Test("mission_dock_lift — solution readies the dock and delivers the crate for 32")
    func dockLiftSuccess() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_dock_lift"))
        let program = """
        drive.turnLeft(90);
        drive.forward(75);
        drive.turnRight(90);
        drive.forward(90);
        arm.lower();
        arm.raise();
        drive.forward(70);
        drive.turnRight(90);
        drive.forward(15);
        arm.lower();
        gripper.close();
        drive.turnRight(90);
        drive.forward(145);
        drive.turnRight(90);
        drive.forward(25);
        gripper.open();
        """
        let run = sim.run(program: program, world: try world(), robot: robot(), mission: m)
        #expect(run.failureKind == nil, "got \(String(describing: run.failureKind))")
        #expect(run.missionResult?.success == true)
        #expect(run.missionResult?.score == 32)
        #expect(activated(run, "mech_dock_ramp"))
    }

    @Test("mission_dock_lift — same route without the arm-press never readies the dock (fails)")
    func dockLiftNoRampFails() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_dock_lift"))
        let program = """
        drive.turnLeft(90);
        drive.forward(75);
        drive.turnRight(90);
        drive.forward(90);
        drive.forward(70);
        drive.turnRight(90);
        drive.forward(15);
        arm.lower();
        gripper.close();
        drive.turnRight(90);
        drive.forward(145);
        drive.turnRight(90);
        drive.forward(25);
        gripper.open();
        """
        let run = sim.run(program: program, world: try world(), robot: robot(), mission: m)
        #expect(run.missionResult?.success == false)
        #expect(activated(run, "mech_dock_ramp") == false)
    }

    // =========================================================================
    // MARK: mission_chute_release (d4, 40 pts) — lever cascade → transport
    // =========================================================================
    // Lever at (85,155), armPress; the freed crate_R sits in the chute at (85,180).
    // Trip the lever, collect crate_R, deliver to depot_red.

    @Test("mission_chute_release — solution trips the chute and delivers the crate for 40")
    func chuteReleaseSuccess() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_chute_release"))
        let program = """
        drive.turnLeft(90);
        drive.forward(35);
        drive.turnRight(90);
        drive.forward(135);
        arm.lower();
        arm.raise();
        drive.forward(25);
        arm.lower();
        gripper.close();
        drive.turnLeft(90);
        drive.forward(50);
        drive.turnLeft(90);
        drive.forward(145);
        gripper.open();
        """
        let run = sim.run(program: program, world: try world(), robot: robot(), mission: m)
        #expect(run.failureKind == nil, "got \(String(describing: run.failureKind))")
        #expect(run.missionResult?.success == true)
        #expect(run.missionResult?.score == 40)
        #expect(activated(run, "mech_release_lever"))
    }

    @Test("mission_chute_release — skipping the lever leaves the cascade unscored (fails)")
    func chuteReleaseNoLeverFails() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_chute_release"))
        let program = """
        drive.turnLeft(90);
        drive.forward(35);
        drive.turnRight(90);
        drive.forward(135);
        drive.forward(25);
        arm.lower();
        gripper.close();
        drive.turnLeft(90);
        drive.forward(50);
        drive.turnLeft(90);
        drive.forward(145);
        gripper.open();
        """
        let run = sim.run(program: program, world: try world(), robot: robot(), mission: m)
        #expect(run.missionResult?.success == false)
        #expect(activated(run, "mech_release_lever") == false)
    }

    // =========================================================================
    // MARK: mission_warehouse_gauntlet (d5, 50 pts) — the full floor in one run
    // =========================================================================
    // Chute lever → deliver crate_R to depot_red → break the bay door → park
    // dead-centre in the bay (227,114) within 10 cm. One continuous route.

    @Test("mission_warehouse_gauntlet — full solution scores the whole floor for 50")
    func gauntletSuccess() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_warehouse_gauntlet"))
        let program = """
        drive.turnLeft(90);
        drive.forward(35);
        drive.turnRight(90);
        drive.forward(135);
        arm.lower();
        arm.raise();
        drive.forward(25);
        arm.lower();
        gripper.close();
        drive.turnLeft(90);
        drive.forward(50);
        drive.turnLeft(90);
        drive.forward(145);
        gripper.open();
        drive.turnRight(180);
        drive.forward(85);
        drive.turnRight(90);
        drive.forward(175);
        drive.forward(18);
        """
        let run = sim.run(program: program, world: try world(), robot: robot(), mission: m)
        #expect(run.failureKind == nil, "got \(String(describing: run.failureKind))")
        #expect(run.missionResult?.success == true)
        #expect(run.missionResult?.score == 50)
        #expect(activated(run, "mech_release_lever"))
        #expect(activated(run, "mech_bay_door"))
    }

    @Test("mission_warehouse_gauntlet — stopping after the delivery misses the bay (fails)")
    func gauntletNoBayFails() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_warehouse_gauntlet"))
        // The chute + delivery leg only; never breaks into the bay or parks.
        let program = """
        drive.turnLeft(90);
        drive.forward(35);
        drive.turnRight(90);
        drive.forward(135);
        arm.lower();
        arm.raise();
        drive.forward(25);
        arm.lower();
        gripper.close();
        drive.turnLeft(90);
        drive.forward(50);
        drive.turnLeft(90);
        drive.forward(145);
        gripper.open();
        """
        let run = sim.run(program: program, world: try world(), robot: robot(), mission: m)
        #expect(run.missionResult?.success == false)
        #expect(activated(run, "mech_bay_door") == false)
    }
}
