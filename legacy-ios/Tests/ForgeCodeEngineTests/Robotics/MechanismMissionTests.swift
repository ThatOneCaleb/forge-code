import Testing
@testable import ForgeCodeEngine

/// Verified-solution + negative tests for the two mechanism missions on
/// Mars Outpost (field_arena):
///   mission_drill_wakeup    (d2, 20 pts) — armPress lever + return home
///   mission_ridge_gate_rush (d3, 30 pts) — bump gate unlocks a blocked lane
@Suite("Mechanism missions (Mars Outpost)")
struct MechanismMissionTests {

    private let sim = RoboticsSimulator()

    private func world() throws -> FieldWorld {
        try #require(try RoboticsLibrary.field(id: "field_arena"))
    }

    /// Match start: base_camp centre (150, 29), heading north.
    private func robot() -> RobotModel {
        RobotModel(pose: Pose(position: Vec2(x: 150, y: 29), headingDegrees: 0),
                   armAngle: 0, isGripperOpen: true)
    }

    // =========================================================================
    // MARK: mission_drill_wakeup (d2, 20 pts)
    // =========================================================================
    //
    // Route: west 80 → (70,29); north 96 → (70,125), 15 cm from the drill lever
    // at (70,140) [≤ 22 trigger radius]; arm.lower() → armPress activates;
    // arm.raise(); 180 → south 96 → (70,29); east 80 → (150,29) in base_camp.
    // Clearances: x=70 lane stops at y=125, crater_rim starts y=154. ✓

    @Test("mission_drill_wakeup — verified solution scores 20 and succeeds")
    func drillWakeupSuccess() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_drill_wakeup"))
        let program = """
        drive.turnLeft(90);
        drive.forward(80);
        drive.turnRight(90);
        drive.forward(96);
        arm.lower();
        arm.raise();
        drive.turnRight(180);
        drive.forward(96);
        drive.turnLeft(90);
        drive.forward(80);
        """
        let run = sim.run(program: program, world: try world(), robot: robot(), mission: m)
        #expect(run.failureKind == nil)
        #expect(run.missionResult?.success == true)
        #expect(run.missionResult?.score == 20)
        #expect(run.missionResult?.metObjectiveIds == ["obj_dw_drill", "obj_dw_home"])
        // The activation frame exists for UI playback
        #expect(run.sensorLog.contains {
            if case .mechanismActivated("mech_drill_lever") = $0.kind { return true }
            return false
        })
    }

    @Test("mission_drill_wakeup — same route without the arm scores only the return leg")
    func drillWakeupNoArmFails() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_drill_wakeup"))
        let program = """
        drive.turnLeft(90);
        drive.forward(80);
        drive.turnRight(90);
        drive.forward(96);
        drive.turnRight(180);
        drive.forward(96);
        drive.turnLeft(90);
        drive.forward(80);
        """
        let run = sim.run(program: program, world: try world(), robot: robot(), mission: m)
        #expect(run.missionResult?.success == false, "Drill never activated → mission fails")
        #expect(run.missionResult?.metObjectiveIds == ["obj_dw_home"])
    }

    // =========================================================================
    // MARK: mission_storage_nook (d3, 30 pts)
    // =========================================================================
    //
    // nook_gate_bar seals the storage nook mouth at x:68-102, y:240-250. The
    // gate switch (bump) sits at (85,225), just south of the mouth.
    // Route (all lanes verified clear of obstacles):
    //   west 125 → (25,29); north 196 → (25,225) [x=25 clears crater_rim x:38-102]
    //   east 60 → (85,225) — bump opens the gate, bar removed
    //   north 47 → (85,272) inside the nook, within 20 cm of target (85,272).

    @Test("mission_storage_nook — verified solution opens the gate and scores 30")
    func storageNookSuccess() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_storage_nook"))
        let program = """
        drive.turnLeft(90);
        drive.forward(125);
        drive.turnRight(90);
        drive.forward(196);
        drive.turnRight(90);
        drive.forward(60);
        drive.turnLeft(90);
        drive.forward(47);
        """
        let run = sim.run(program: program, world: try world(), robot: robot(), mission: m)
        #expect(run.failureKind == nil,
                "Nook should open after the gate bump, got \(String(describing: run.failureKind))")
        #expect(run.missionResult?.success == true)
        #expect(run.missionResult?.score == 30)
        #expect(run.missionResult?.metObjectiveIds == ["obj_sn_gate", "obj_sn_park"])
        #expect(run.sensorLog.contains {
            if case .mechanismActivated("mech_nook_gate") = $0.kind { return true }
            return false
        })
    }

    @Test("mission_storage_nook — missing the switch leaves the gate shut and scores 0")
    func storageNookMissedSwitchFails() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_storage_nook"))
        // Stops the east leg 30 cm short of the switch (outside the 22 cm trigger
        // radius), then heads north OUTSIDE the nook mouth — gate never opens,
        // park target never reached.
        let program = """
        drive.turnLeft(90);
        drive.forward(125);
        drive.turnRight(90);
        drive.forward(196);
        drive.turnRight(90);
        drive.forward(30);
        drive.turnLeft(90);
        drive.forward(47);
        """
        let run = sim.run(program: program, world: try world(), robot: robot(), mission: m)
        #expect(run.missionResult?.success == false)
        #expect(run.missionResult?.score == 0)
        #expect(run.finalSnapshot?.mechanismStates.first { $0.id == "mech_nook_gate" }?.isActivated == false)
    }
}
