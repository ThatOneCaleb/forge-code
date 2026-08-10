import Testing
@testable import ForgeCodeEngine

/// Verified-solution + negative tests for the three attachment-gated /
/// precision mechanism missions on Mars Outpost (field_arena):
///
///   mission_signal_rocket     (d3, 35 pts) — launchTool + tight launcher lever
///   mission_buried_sample     (d4, 40 pts) — fineHook + gripper-pull excavator
///   mission_precision_gauntlet(d5, 50 pts) — launcher + 7 cm rock-pocket pose + home
///
/// These missions exist to teach the "bring the right tool" decision and to
/// demand precise navigation/placement — the hard, growth-stretching end of the
/// difficulty ladder. Each proves a working solution AND that the mission fails
/// with the wrong attachment or an imprecise approach.
@Suite("Precision & attachment mechanism missions (Mars Outpost)")
struct MechanismPrecisionMissionTests {

    private let sim = RoboticsSimulator()

    private func world() throws -> FieldWorld {
        try #require(try RoboticsLibrary.field(id: "field_arena"))
    }

    /// Rover at base_camp centre (150, 29), heading north, with a chosen attachment.
    private func robot(_ attachment: RobotAttachment) -> RobotModel {
        RobotModel(pose: Pose(position: Vec2(x: 150, y: 29), headingDegrees: 0),
                   armAngle: 0, isGripperOpen: true, attachment: attachment)
    }

    // =========================================================================
    // MARK: mission_signal_rocket (d3, 35 pts) — launchTool + tight launcher
    // =========================================================================
    //
    // Launcher lever at (150,256), radius 11, armPress, requires launchTool.
    // A straight north drive at x=150 is blocked by boulder_S/boulder_N, so the
    // route detours up the clean x=210 highway, west to the lever, then home.

    @Test("mission_signal_rocket — launchTool solution launches the rocket and scores 35")
    func signalRocketSuccess() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_signal_rocket"))
        let program = """
        drive.turnRight(90);
        drive.forward(60);
        drive.turnLeft(90);
        drive.forward(227);
        drive.turnLeft(90);
        drive.forward(60);
        arm.lower();
        arm.raise();
        drive.turnRight(180);
        drive.forward(60);
        drive.turnRight(90);
        drive.forward(227);
        drive.turnRight(90);
        drive.forward(60);
        """
        let run = sim.run(program: program, world: try world(),
                          robot: robot(.launchTool), mission: m)
        #expect(run.failureKind == nil,
                "got \(String(describing: run.failureKind))")
        #expect(run.missionResult?.success == true)
        #expect(run.missionResult?.score == 35)
        #expect(run.missionResult?.metObjectiveIds == ["obj_sr_launch", "obj_sr_home"])
        #expect(run.sensorLog.contains {
            if case .mechanismActivated("mech_rocket_launch") = $0.kind { return true }
            return false
        })
    }

    @Test("mission_signal_rocket — wrong attachment never trips the lever (fails)")
    func signalRocketWrongToolFails() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_signal_rocket"))
        // Identical route, but a Standard Gripper cannot trip the launch lever.
        let program = """
        drive.turnRight(90);
        drive.forward(60);
        drive.turnLeft(90);
        drive.forward(227);
        drive.turnLeft(90);
        drive.forward(60);
        arm.lower();
        arm.raise();
        drive.turnRight(180);
        drive.forward(60);
        drive.turnRight(90);
        drive.forward(227);
        drive.turnRight(90);
        drive.forward(60);
        """
        let run = sim.run(program: program, world: try world(),
                          robot: robot(.none), mission: m)
        #expect(run.missionResult?.success == false, "no launchTool → lever stays put")
        #expect(run.missionResult?.metObjectiveIds == ["obj_sr_home"])
        #expect(run.finalSnapshot?.mechanismStates
            .first { $0.id == "mech_rocket_launch" }?.isActivated == false)
    }

    // =========================================================================
    // MARK: mission_buried_sample (d4, 40 pts) — fineHook + gripper-pull
    // =========================================================================
    //
    // Excavator at (255,195), radius 10, gripperPull, requires fineHook. The
    // rover must arrive within 10 cm, lower the arm, and close the gripper to
    // pry the sample loose — then return home.

    @Test("mission_buried_sample — fineHook solution frees the sample and scores 40")
    func buriedSampleSuccess() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_buried_sample"))
        let program = """
        drive.turnRight(90);
        drive.forward(105);
        drive.turnLeft(90);
        drive.forward(166);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.turnRight(180);
        drive.forward(166);
        drive.turnRight(90);
        drive.forward(105);
        """
        let run = sim.run(program: program, world: try world(),
                          robot: robot(.fineHook), mission: m)
        #expect(run.failureKind == nil,
                "got \(String(describing: run.failureKind))")
        #expect(run.missionResult?.success == true)
        #expect(run.missionResult?.score == 40)
        #expect(run.missionResult?.metObjectiveIds == ["obj_bs_pull", "obj_bs_home"])
        #expect(run.sensorLog.contains {
            if case .mechanismActivated("mech_core_probe") = $0.kind { return true }
            return false
        })
    }

    @Test("mission_buried_sample — grabbing with the arm up cannot pry it loose (fails)")
    func buriedSampleArmUpFails() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_buried_sample"))
        // Correct tool + position, but the arm never lowers — no leverage.
        let program = """
        drive.turnRight(90);
        drive.forward(105);
        drive.turnLeft(90);
        drive.forward(166);
        gripper.close();
        drive.turnRight(180);
        drive.forward(166);
        drive.turnRight(90);
        drive.forward(105);
        """
        let run = sim.run(program: program, world: try world(),
                          robot: robot(.fineHook), mission: m)
        #expect(run.missionResult?.success == false)
        #expect(run.finalSnapshot?.mechanismStates
            .first { $0.id == "mech_core_probe" }?.isActivated == false)
    }

    @Test("mission_buried_sample — wrong attachment cannot free the sample (fails)")
    func buriedSampleWrongToolFails() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_buried_sample"))
        let program = """
        drive.turnRight(90);
        drive.forward(105);
        drive.turnLeft(90);
        drive.forward(166);
        arm.lower();
        gripper.close();
        """
        let run = sim.run(program: program, world: try world(),
                          robot: robot(.none), mission: m)
        #expect(run.missionResult?.success == false, "no fineHook → sample stays buried")
        #expect(run.finalSnapshot?.mechanismStates
            .first { $0.id == "mech_core_probe" }?.isActivated == false)
    }

    // =========================================================================
    // MARK: mission_precision_gauntlet (d5, 50 pts) — the brutal one
    // =========================================================================
    //
    // Launch the rocket (launchTool, r11), then thread into the rock pocket at
    // (150,162) and come to rest within 7 cm — walls on all sides. Every
    // straight line to the pocket is blocked; the route detours up x=195, west
    // onto the lever, back to x=195, south into the corridor, then west into the
    // pocket where the rover finishes.

    @Test("mission_precision_gauntlet — full solution scores 50 and succeeds")
    func precisionGauntletSuccess() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_precision_gauntlet"))
        let program = """
        drive.turnRight(90);
        drive.forward(45);
        drive.turnLeft(90);
        drive.forward(227);
        drive.turnLeft(90);
        drive.forward(45);
        arm.lower();
        arm.raise();
        drive.turnRight(180);
        drive.forward(45);
        drive.turnRight(90);
        drive.forward(94);
        drive.turnRight(90);
        drive.forward(45);
        """
        let run = sim.run(program: program, world: try world(),
                          robot: robot(.launchTool), mission: m)
        #expect(run.failureKind == nil,
                "got \(String(describing: run.failureKind))")
        #expect(run.missionResult?.success == true)
        #expect(run.missionResult?.score == 50)
        #expect(run.missionResult?.metObjectiveIds
            == ["obj_pg_launch", "obj_pg_pocket"])
    }

    @Test("mission_precision_gauntlet — landing 10 cm off the pocket misses it (fails)")
    func precisionGauntletImpreciseFails() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_precision_gauntlet"))
        // Same route, but the final pocket approach stops 10 cm short (35 not 45):
        // the launcher fires, but the 7 cm pocket is missed → mission fails.
        let program = """
        drive.turnRight(90);
        drive.forward(45);
        drive.turnLeft(90);
        drive.forward(227);
        drive.turnLeft(90);
        drive.forward(45);
        arm.lower();
        arm.raise();
        drive.turnRight(180);
        drive.forward(45);
        drive.turnRight(90);
        drive.forward(94);
        drive.turnRight(90);
        drive.forward(35);
        """
        let run = sim.run(program: program, world: try world(),
                          robot: robot(.launchTool), mission: m)
        #expect(run.missionResult?.success == false, "10 cm off a 7 cm pocket → miss")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_pg_pocket") == false)
    }
}
