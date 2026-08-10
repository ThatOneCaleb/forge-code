import Testing
@testable import ForgeCodeEngine

/// End-to-end tests for the four Batch-1 missions on the Mars Outpost field
/// (field_arena, 300×300 cm).
///
/// Field layout quick-reference (heading 0°=north=+Y, CW-positive):
///   Obstacles
///     boulder_W      x:100-114, y:128-198
///     boulder_N      x:114-178, y:184-198
///     boulder_S      x:114-178, y:126-140
///     crater_rim     x:38-102,  y:154-168
///     boulder_scatter x:168-190, y:62-84
///   Key zones
///     launch_pad     x:120-180, y:268-295   (goal)
///     base_camp      x:108-192, y:8-50      (goal)
///     beacon_pad     x:10-65,   y:50-105    (detection)
///     solar_pad      x:220-280, y:45-100    (detection)
///     bay_alpha      x:5-67,    y:228-290   (deposit, sample)
///   Key items
///     rock_alpha     (75,220)   red/sample, pickupRadius 14
///   Colored regions
///     solar_tile     x:220-280, y:45-100    yellow
///     beacon_tile    x:10-65,   y:50-105    orange
@Suite("Batch-1 Mars Outpost missions (first-traverse, beacon-salute, first-sample, solar-checkin)")
struct FieldBMissionTests {

    // MARK: - Shared helpers

    private func world() throws -> FieldWorld {
        try #require(try RoboticsLibrary.field(id: "field_arena"))
    }

    private let sim = RoboticsSimulator()

    // =========================================================================
    // MARK: - Mission 1: mission_first_traverse  (diff 1, 10 pts)
    // =========================================================================
    //
    // Route (start (150,20) heading north — inside base_camp x:108-192,y:8-50):
    //   Direct north at x=150 is blocked by boulder_S (x:114-178,y:126-140).
    //   East detour: stay at x=195, which clears ALL ring obstacles and scatter.
    //
    //   1. drive.turnRight(90)  → heading 90° (east)
    //   2. drive.forward(45)    → (195,20)   [y=20<62, clears boulder_scatter y:62-84 ✓]
    //   3. drive.turnLeft(90)   → heading 0° (north)
    //   4. drive.forward(255)   → (195,275)  [x=195: boulder_scatter x:168-190 (195>190 ✓);
    //                                          boulder_S/N x:114-178 (195>178 ✓);
    //                                          boulder_W x:100-114 (195>114 ✓);
    //                                          crater_rim x:38-102 (195>102 ✓). All clear ✓]
    //   5. drive.turnLeft(90)   → heading 270° (west)
    //   6. drive.forward(45)    → (150,275)  [y=275, no obstacles. launch_pad x:120-180 (✓),
    //                                          y:268-295 (275 ✓). Inside launch_pad ✓]
    //   7. arm.moveTo(45)       → arm=45°    [armToAngle 45°: |45-45|=0 ≤ 5° ✓]
    //   Total actions: 7
    //
    // Objectives:
    //   obj_ft_launch   reachZone launch_pad   7 pts  required
    //   obj_ft_signal   armToAngle 45°          3 pts  required
    //   Total = 10 pts. successRule: allRequired.

    @Test("mission_first_traverse — loads with correct metadata")
    func firstTraverseLoads() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_first_traverse"))
        #expect(m.difficulty == 1)
        #expect(m.totalPossiblePoints == 10)
        #expect(m.objectives.count == 2)
        #expect(m.objectives.filter { $0.isRequired }.count == 2)
        #expect(m.objectives.first { $0.kind == .reachZone }?.targetZoneId == "launch_pad")
        #expect(m.objectives.first { $0.kind == .armToAngle }?.targetAngle == 45)
        #expect(m.fieldId == "field_arena")
    }

    @Test("mission_first_traverse — verified solution scores 10 pts and succeeds")
    func firstTraverseSuccess() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_first_traverse"))
        // Start: (150,20) heading north (0°).
        // East to x=195 (clears boulder ring east edge x=178 and scatter east edge x=190).
        // North to y=275 (well past ring; launch_pad y:268-295).
        // West 45 to x=150 (inside launch_pad x:120-180).
        // arm.moveTo(45) — arrival signal.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnRight(90);
        drive.forward(45);
        drive.turnLeft(90);
        drive.forward(255);
        drive.turnLeft(90);
        drive.forward(45);
        arm.moveTo(45);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "7-action east-detour solution should succeed; failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 10,
                "Expected 10 pts (7+3), got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ft_launch") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ft_signal") == true)
        // Confirm final position is inside launch_pad (x:120-180, y:268-295)
        let finalPos = run.finalSnapshot?.pose.position
        #expect((finalPos?.x ?? 0) >= 120 && (finalPos?.x ?? 0) <= 180,
                "Final x \(finalPos?.x ?? -1) should be in launch_pad x-range 120-180")
        #expect((finalPos?.y ?? 0) >= 268 && (finalPos?.y ?? 0) <= 295,
                "Final y \(finalPos?.y ?? -1) should be in launch_pad y-range 268-295")
        // Confirm arm angle
        #expect(abs((run.finalSnapshot?.armAngle ?? -1) - 45) <= 5)
    }

    @Test("mission_first_traverse — drive-only (no arm call) reaches launch_pad but fails armToAngle")
    func firstTraverseDriveOnlyFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_first_traverse"))
        // Same route but omit arm.moveTo(45) — obj_ft_signal not met.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnRight(90);
        drive.forward(45);
        drive.turnLeft(90);
        drive.forward(255);
        drive.turnLeft(90);
        drive.forward(45);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "Missing arm signal should fail allRequired")
        #expect(run.missionResult?.score == 7,
                "Should score 7 pts for reachZone only; got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ft_launch") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ft_signal") == false)
    }

    @Test("mission_first_traverse — wrong arm angle (90°) fails armToAngle objective")
    func firstTraverseWrongAngleFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_first_traverse"))
        // Reach launch_pad but set arm to 90° (45° away from target 45° — outside 5° tol).
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnRight(90);
        drive.forward(45);
        drive.turnLeft(90);
        drive.forward(255);
        drive.turnLeft(90);
        drive.forward(45);
        arm.moveTo(90);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "Arm at 90° is 45° away from target 45° — outside tolerance, should fail")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ft_signal") == false)
        #expect(run.missionResult?.score == 7,
                "Should score 7 pts for reachZone only; got \(run.missionResult?.score ?? -1)")
    }

    @Test("mission_first_traverse — naive straight-north drive collides with boulder_S")
    func firstTraverseStraightNorthCollides() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_first_traverse"))
        // Drive straight north at x=150: boulder_S x:114-178, y:126-140 blocks the path.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0)
        )
        let run = sim.run(program: "drive.forward(280);",
                           world: w, robot: robot, mission: m)
        // Engine should report a collision before reaching launch_pad.
        #expect(run.failureKind != nil,
                "Straight-north drive at x=150 should collide with boulder_S")
        if case let .collision(obsId) = run.failureKind {
            #expect(obsId == "boulder_S", "Expected boulder_S collision, got \(obsId)")
        }
        #expect(run.missionResult?.success == false)
    }

    // =========================================================================
    // MARK: - Mission 2: mission_beacon_salute  (diff 1, 10 pts)
    // =========================================================================
    //
    // Route (start (150,20) heading north — inside base_camp):
    //   beacon_pad is at x:10-65, y:50-105 (SW area).
    //   Clean west-then-north route stays well clear of all obstacles.
    //
    //   1. drive.turnLeft(90)   → heading 270° (west)
    //   2. drive.forward(110)   → (40,20)   [y=20, no obstacles going west ✓]
    //   3. drive.turnRight(90)  → heading 0° (north)   [270°+90°=360°=0°]
    //   4. drive.forward(55)    → (40,75)   [x=40: crater_rim x:38-102 (x=40∈[38,102]!)
    //                                         but crater_rim y:154-168; y=75<154 ✓. Clear.
    //                                         boulder_W x:100-114 (x=40<100 ✓). Clear ✓]
    //                                        beacon_pad x:10-65 (40 ✓), y:50-105 (75 ✓) ✓
    //   5. arm.moveTo(60)       → arm=60°   [armToAngle 60°: |60-60|=0 ≤ 5° ✓]
    //   Total actions: 5
    //
    // Obstacle clearance note:
    //   x=40 is inside crater_rim's x-range (38-102) but crater_rim y-range is 154-168.
    //   Robot travels from y=20 to y=75 — never reaches y=154. crater_rim is not hit.
    //
    // Objectives:
    //   obj_bs_reach   reachZone beacon_pad   6 pts  required
    //   obj_bs_arm     armToAngle 60°          4 pts  required
    //   Total = 10 pts. successRule: allRequired.

    @Test("mission_beacon_salute — loads with correct metadata")
    func beaconSaluteLoads() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_beacon_salute"))
        #expect(m.difficulty == 1)
        #expect(m.totalPossiblePoints == 10)
        #expect(m.objectives.count == 2)
        #expect(m.objectives.filter { $0.isRequired }.count == 2)
        #expect(m.objectives.first { $0.kind == .reachZone }?.targetZoneId == "beacon_pad")
        #expect(m.objectives.first { $0.kind == .armToAngle }?.targetAngle == 60)
        #expect(m.fieldId == "field_arena")
    }

    @Test("mission_beacon_salute — verified solution scores 10 pts and succeeds")
    func beaconSaluteSuccess() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_beacon_salute"))
        // Start: (150,20) heading north (0°).
        // West 110 → (40,20); north 55 → (40,75).
        // (40,75): beacon_pad x:10-65, y:50-105. x=40 ✓, y=75 ✓.
        // crater_rim (x:38-102,y:154-168): x=40 is in range but y=75 < 154, never entered. ✓
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnLeft(90);
        drive.forward(110);
        drive.turnRight(90);
        drive.forward(55);
        arm.moveTo(60);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "5-action solution should succeed; failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 10,
                "Expected 10 pts (6+4), got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_bs_reach") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_bs_arm") == true)
        // Confirm final position is inside beacon_pad (x:10-65, y:50-105)
        let finalPos = run.finalSnapshot?.pose.position
        #expect((finalPos?.x ?? 0) >= 10 && (finalPos?.x ?? 0) <= 65,
                "Final x \(finalPos?.x ?? -1) should be in beacon_pad x-range 10-65")
        #expect((finalPos?.y ?? 0) >= 50 && (finalPos?.y ?? 0) <= 105,
                "Final y \(finalPos?.y ?? -1) should be in beacon_pad y-range 50-105")
        #expect(abs((run.finalSnapshot?.armAngle ?? -1) - 60) <= 5)
    }

    @Test("mission_beacon_salute — reaching beacon_pad without arm call fails allRequired")
    func beaconSaluteNoArmFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_beacon_salute"))
        // West and north to beacon_pad but omit arm.moveTo(60).
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnLeft(90);
        drive.forward(110);
        drive.turnRight(90);
        drive.forward(55);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "Missing arm call should fail allRequired")
        #expect(run.missionResult?.score == 6,
                "Should score 6 pts for reachZone only; got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_bs_reach") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_bs_arm") == false)
    }

    @Test("mission_beacon_salute — wrong arm angle (0°) fails armToAngle objective")
    func beaconSaluteWrongAngleFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_beacon_salute"))
        // Arrive at beacon_pad but arm stays at 0° (|0-60|=60 > 5°).
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 40, y: 75), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        // Just the arm call with wrong angle
        let run = sim.run(program: "arm.moveTo(0);", world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "Arm at 0° (60° away from target 60°) should fail armToAngle objective")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_bs_arm") == false)
    }

    // =========================================================================
    // MARK: - Mission 3: mission_first_sample  (diff 2, 20 pts)
    // =========================================================================
    //
    // rock_alpha at (75,220); bay_alpha: x:5-67, y:228-290, deposit, acceptsItemType: sample.
    //
    // Route B — canonical (start (150,20) heading north):
    //   Detour west to x=35 (clear of crater_rim x:38-102 at x=35<38), drive north,
    //   then east to the rock, pick up, come back west, north into bay_alpha.
    //
    //   1. drive.turnLeft(90)   → heading 270° (west)
    //   2. drive.forward(115)   → (35,20)   [x=35<38 → clear of crater_rim ✓; no obst at y=20 ✓]
    //   3. drive.turnRight(90)  → heading 0° (north)   [270°+90°=360°=0°]
    //   4. drive.forward(200)   → (35,220)  [x=35<38: crater_rim y:154-168 → x=35<38 ✓.
    //                                         boulder_W x:100-114 (x=35<100 ✓). All clear ✓]
    //   5. drive.turnRight(90)  → heading 90° (east)   [0°+90°=90°]
    //   6. drive.forward(40)    → (75,220)  [= rock_alpha. y=220<228 (above bay_alpha) ✓;
    //                                         no obstacles at y=220 going east ✓]
    //   7. arm.lower()          → arm=90°   [isArmLowered: 90°≥60° ✓]
    //   8. gripper.close()      → picks rock_alpha (dist=0 ≤ 14cm) ✓
    //   9. arm.raise()          → arm=0°
    //  10. drive.turnRight(180) → heading 270° (west)   [90°+180°=270°]
    //  11. drive.forward(30)    → (45,220)  [x=45∈[5,67] ✓; y=220<228 not in bay_alpha yet]
    //  12. drive.turnRight(90)  → heading 0° (north)   [270°+90°=360°=0°]
    //  13. drive.forward(30)    → (45,250)  [bay_alpha: x=45∈[5,67] ✓, y=250∈[228,290] ✓]
    //  14. gripper.open()       → deposits rock_alpha in bay_alpha ✓
    //   Total actions: 14
    //
    // Route A — alternate (east detour, 18 actions):
    //   East to x=195 (clear ring/scatter), north to y=215 (past ring's y=198 top),
    //   west to x=75 (at y=215, below bay_alpha at y=228), north to y=220, pick up,
    //   back west then north into bay_alpha.
    //
    // Obstacle clearances (Route B):
    //   Step 2 (y=20, west to x=35): no obstacles in south strip. ✓
    //   Step 4 (x=35, north to y=220): x=35<38 → crater_rim (x:38-102) never overlapped ✓;
    //     boulder_W x:100-114 (x=35<100 ✓). Clear all the way.
    //   Step 6 (y=220, east to x=75): crater_rim y:154-168 (y=220>168 ✓); all ring obs y≤198 ✓.
    //   Steps 11-13 (approach bay_alpha): no obstacles at x:35-75, y:220-250. ✓
    //
    // Objectives:
    //   obj_fsa_pickup   pickUpItem rock_alpha          8 pts  required
    //   obj_fsa_deposit  depositItemInZone bay_alpha   12 pts  required
    //   Total = 20 pts. successRule: allRequired.

    @Test("mission_first_sample — loads with correct metadata")
    func firstSampleLoads() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_first_sample"))
        #expect(m.difficulty == 2)
        #expect(m.totalPossiblePoints == 20)
        #expect(m.objectives.count == 2)
        #expect(m.objectives.filter { $0.isRequired }.count == 2)
        let pickupObj = m.objectives.first { $0.kind == .pickUpItem }
        #expect(pickupObj?.targetItemId == "rock_alpha")
        let depositObj = m.objectives.first { $0.kind == .depositItemInZone }
        #expect(depositObj?.targetItemId == "rock_alpha")
        #expect(depositObj?.targetZoneId == "bay_alpha")
        #expect(m.fieldId == "field_arena")
    }

    @Test("mission_first_sample — canonical Route B scores 20 pts and succeeds")
    func firstSampleRouteB() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_first_sample"))
        // Start: (150,20) heading north.
        // West to x=35 (below crater_rim x-range 38-102), north to y=220, east to rock_alpha.
        // Back west to x=45 (inside bay_alpha x-range 5-67), north into bay_alpha, deposit.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnLeft(90);
        drive.forward(115);
        drive.turnRight(90);
        drive.forward(200);
        drive.turnRight(90);
        drive.forward(40);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.turnRight(180);
        drive.forward(30);
        drive.turnRight(90);
        drive.forward(30);
        gripper.open();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "14-action Route B solution should succeed; failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 20,
                "Expected 20 pts (8+12), got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_fsa_pickup") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_fsa_deposit") == true)
    }

    @Test("mission_first_sample — alternate Route A (east detour) also scores 20 pts")
    func firstSampleRouteA() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_first_sample"))
        // Start: (150,20) heading north.
        // East to x=195 (clears ring and scatter), north to y=215 (past boulder_N top y=198),
        // west to x=75 (y=215<228 → above bay_alpha; clear of ring at y=215>198),
        // north to y=220 (= rock_alpha y), arm.lower/gripper.close/arm.raise.
        // Then: turnRight(180) → south; forward(8) → (75,212). Need to be in bay_alpha:
        //   x=75>67, must go west first.
        // turnRight(90) → west (180°+90°=270°); forward(30) → (45,212).
        // turnRight(90) → north (270°+90°=0°); forward(20) → (45,232).
        //   bay_alpha: x=45∈[5,67] ✓, y=232∈[228,290] ✓. ✓
        // gripper.open() → deposit ✓.
        // Obstacle check west from (195,215) to (75,215):
        //   boulder_N x:114-178, y:184-198. y=215>198 ✓. Clear.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnRight(90);
        drive.forward(45);
        drive.turnLeft(90);
        drive.forward(195);
        drive.turnLeft(90);
        drive.forward(120);
        drive.turnRight(90);
        drive.forward(5);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.turnRight(180);
        drive.forward(8);
        drive.turnRight(90);
        drive.forward(30);
        drive.turnRight(90);
        drive.forward(20);
        gripper.open();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "Route A (east detour) should also succeed; failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 20,
                "Expected 20 pts, got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_fsa_pickup") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_fsa_deposit") == true)
    }

    @Test("mission_first_sample — drive-only program scores 0 and fails")
    func firstSampleDriveOnlyFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_first_sample"))
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0)
        )
        let run = sim.run(program: "drive.turnLeft(90); drive.forward(115);",
                           world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "Drive-only cannot satisfy pickup or deposit objectives")
        #expect(run.missionResult?.score == 0,
                "Expected 0 pts; got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.isEmpty == true)
    }

    @Test("mission_first_sample — pickup without deposit scores 8 pts and fails allRequired")
    func firstSamplePickupOnlyFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_first_sample"))
        // Position robot directly on rock_alpha, pick it up, never deposit.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 75, y: 220), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        arm.lower();
        gripper.close();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "Pickup without deposit should fail allRequired")
        #expect(run.missionResult?.score == 8,
                "Should score 8 pts for pickup only; got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_fsa_pickup") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_fsa_deposit") == false)
    }

    // =========================================================================
    // MARK: - Mission 4: mission_solar_checkin  (diff 2, 20 pts)
    // =========================================================================
    //
    // solar_pad: x:220-280, y:45-100, detection zone.
    // solar_tile: x:220-280, y:45-100, colored region, color "yellow".
    // base_camp: x:108-192, y:8-50, goal zone.
    //
    // Route (start (150,20) heading north):
    //   Go east at y=20 to x=250 (clears boulder_scatter at y=20<62),
    //   north to y=72 (inside solar_pad; x=250>190 → scatter clear),
    //   call color() → reads "yellow" from solar_tile → detectColorInZone met ✓,
    //   return south then west to (150,20) → inside base_camp ✓.
    //
    //   1. drive.turnRight(90)  → heading 90° (east)
    //   2. drive.forward(100)   → (250,20)   [y=20<62: clears boulder_scatter y:62-84 ✓]
    //   3. drive.turnLeft(90)   → heading 0° (north)   [90°-90°=0°]
    //   4. drive.forward(52)    → (250,72)   [x=250>190: clears boulder_scatter x:168-190 ✓;
    //                                          solar_pad x:220-280 (250 ✓), y:45-100 (72 ✓) ✓]
    //   5. color()              → reads "yellow" (solar_tile at (250,72)) ✓
    //                             logs .color("yellow"); detectColorInZone expectedColor "yellow" met ✓
    //   6. drive.turnRight(180) → heading 180° (south)   [0°+180°=180°]
    //   7. drive.forward(52)    → (250,20)   [x=250>190: scatter clear ✓]
    //   8. drive.turnRight(90)  → heading 270° (west)    [180°+90°=270°]
    //   9. drive.forward(100)   → (150,20)   [y=20<62: scatter clear ✓;
    //                                          base_camp x:108-192 (150 ✓), y:8-50 (20 ✓) ✓]
    //   Total actions: 9  (color() is a sensor read — does NOT consume an action budget slot;
    //                       it calls the binding directly without checkActionBudget)
    //
    // Route B (north-east variant): east to x=240, north to y=72. Both land inside solar_pad.
    //
    // Obstacle clearances:
    //   Step 2 (y=20, east x=150→250): boulder_scatter y:62-84 (y=20<62 ✓). ✓
    //   Step 4 (x=250, north y=20→72): boulder_scatter x:168-190 (x=250>190 ✓). ✓
    //   Step 7 (x=250, south y=72→20): same as step 4. ✓
    //   Step 9 (y=20, west x=250→150): same as step 2. ✓
    //
    // Objectives:
    //   obj_sc_detect  detectColorInZone solar_pad expectedColor "yellow"  12 pts  required
    //   obj_sc_base    reachZone base_camp                                   8 pts  required
    //   Total = 20 pts. successRule: allRequired.

    @Test("mission_solar_checkin — loads with correct metadata")
    func solarCheckinLoads() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_solar_checkin"))
        #expect(m.difficulty == 2)
        #expect(m.totalPossiblePoints == 20)
        #expect(m.objectives.count == 2)
        #expect(m.objectives.filter { $0.isRequired }.count == 2)
        let detectObj = m.objectives.first { $0.kind == .detectColorInZone }
        #expect(detectObj?.targetZoneId == "solar_pad")
        #expect(detectObj?.expectedColor == "yellow")
        let reachObj = m.objectives.first { $0.kind == .reachZone }
        #expect(reachObj?.targetZoneId == "base_camp")
        #expect(m.fieldId == "field_arena")
    }

    @Test("mission_solar_checkin — verified solution scores 20 pts and succeeds")
    func solarCheckinSuccess() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_solar_checkin"))
        // Start: (150,20) heading north.
        // East 100 → (250,20); north 52 → (250,72): inside solar_pad (x:220-280,y:45-100).
        // color() reads "yellow" from solar_tile → detectColorInZone met.
        // South 52 → (250,20); west 100 → (150,20): inside base_camp (x:108-192,y:8-50).
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnRight(90);
        drive.forward(100);
        drive.turnLeft(90);
        drive.forward(52);
        color();
        drive.turnRight(180);
        drive.forward(52);
        drive.turnRight(90);
        drive.forward(100);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "Verified solar check-in solution should succeed; failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 20,
                "Expected 20 pts (12+8), got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_sc_detect") == true,
                "color() inside solar_pad reading 'yellow' should satisfy detectColorInZone")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_sc_base") == true,
                "Final pose (150,20) should be inside base_camp")
        // Confirm robot ended inside base_camp
        let finalPos = run.finalSnapshot?.pose.position
        #expect((finalPos?.x ?? 0) >= 108 && (finalPos?.x ?? 0) <= 192,
                "Final x \(finalPos?.x ?? -1) should be in base_camp x-range 108-192")
        #expect((finalPos?.y ?? 0) >= 8 && (finalPos?.y ?? 0) <= 50,
                "Final y \(finalPos?.y ?? -1) should be in base_camp y-range 8-50")
    }

    @Test("mission_solar_checkin — skipping color detection scores only 8 pts and fails")
    func solarCheckinSkipDetectionFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_solar_checkin"))
        // Go to solar_pad area and return to base_camp, but never call color() sensor.
        // reachZone base_camp met (8 pts) but detectColorInZone not met → allRequired fails.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0)
        )
        let program = """
        drive.turnRight(90);
        drive.forward(100);
        drive.turnLeft(90);
        drive.forward(52);
        drive.turnRight(180);
        drive.forward(52);
        drive.turnRight(90);
        drive.forward(100);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "Missing color detection should fail allRequired")
        #expect(run.missionResult?.score == 8,
                "Should score 8 pts for base_camp only; got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_sc_detect") == false)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_sc_base") == true)
    }

    @Test("mission_solar_checkin — detecting color but not returning to base_camp fails reachZone")
    func solarCheckinNoReturnFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_solar_checkin"))
        // Reach solar_pad and scan, but do not return to base_camp.
        // detectColorInZone met (12 pts) but reachZone base_camp not met → allRequired fails.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0)
        )
        let program = """
        drive.turnRight(90);
        drive.forward(100);
        drive.turnLeft(90);
        drive.forward(52);
        color();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "Not returning to base_camp should fail allRequired")
        #expect(run.missionResult?.score == 12,
                "Should score 12 pts for detection only; got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_sc_detect") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_sc_base") == false)
    }

    // =========================================================================
    // MARK: - Mission 5: mission_relay_delivery  (diff 2, 20 pts)
    // =========================================================================
    //
    // cell_ion at (255,152). relay_station: x:5-45, y:168-213, deposit, cell.
    //
    // Key obstacle geometry between cell_ion and relay_station:
    //   boulder_W  x:100-114, y:128-198 — blocks a direct west drive at y=152
    //   crater_rim x:38-102,  y:154-168 — blocks north approach at x:38-102
    //
    // Canonical route (south arc — clears both):
    //   From (150,20) heading north (0°):
    //   1. turnRight(90)  → heading 90° (east)
    //   2. forward(105)   → (255,20)   [y=20<62: scatter clear ✓]
    //   3. turnLeft(90)   → heading 0° (north)
    //   4. forward(132)   → (255,152)  [x=255>190: scatter clear ✓; = cell_ion ✓]
    //   5. arm.lower()    → arm=90°
    //   6. gripper.close()→ picks cell_ion (dist=0≤14) ✓
    //   7. arm.raise()    → arm=0°
    //   8. turnRight(180) → heading 180° (south)  [0+180=180]
    //   9. forward(32)    → (255,120)  [y=120<126: below boulder_S y:126-140 ✓;
    //                                    y=120<128: below boulder_W y:128-198 ✓; x=255>178 ✓]
    //  10. turnRight(90)  → heading 270° (west)   [180+90=270]
    //  11. forward(235)   → (20,120)   [y=120<128: boulder_W clear ✓;
    //                                    y=120<154: crater_rim y:154-168 clear ✓]
    //  12. turnRight(90)  → heading 0° (north)    [270+90=360=0]
    //  13. forward(70)    → (20,190)   [x=20<38: crater_rim x:38-102 clear ✓;
    //                                    relay: x:5-45 (20∈✓), y:168-213 (190∈✓) ✓]
    //  14. gripper.open() → deposits cell_ion in relay_station ✓
    //
    // Alternate route (north arc — go north first, loop west above boulder_N):
    //   East to x=255, north past all obstacles to y=215, west to x=20, south to y=190.
    //   Also valid; more actions but avoids the southward detour.
    //
    // Objectives:
    //   obj_rd_pickup   pickUpItem cell_ion           8 pts  required
    //   obj_rd_deposit  depositItemInZone relay_station 12 pts required
    //   Total = 20 pts. successRule: allRequired.

    @Test("mission_relay_delivery — loads with correct metadata")
    func relayDeliveryLoads() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_relay_delivery"))
        #expect(m.difficulty == 2)
        #expect(m.totalPossiblePoints == 20)
        #expect(m.objectives.count == 2)
        #expect(m.objectives.filter { $0.isRequired }.count == 2)
        let pickupObj = m.objectives.first { $0.kind == .pickUpItem }
        #expect(pickupObj?.targetItemId == "cell_ion")
        let depositObj = m.objectives.first { $0.kind == .depositItemInZone }
        #expect(depositObj?.targetItemId == "cell_ion")
        #expect(depositObj?.targetZoneId == "relay_station")
        #expect(m.fieldId == "field_arena")
    }

    @Test("mission_relay_delivery — canonical south-arc route scores 20 pts and succeeds")
    func relayDeliverySuccess() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_relay_delivery"))
        // Start: (150,20) heading north.
        // East 105 → (255,20); north 132 → (255,152): pick up cell_ion.
        // South 32 → (255,120): below boulder_W south edge (y=128) ✓.
        // West 235 → (20,120): y=120<128, clears boulder_W; y=120<154, clears crater_rim ✓.
        // North 70 → (20,190): x=20<38, clears crater_rim x-range; inside relay_station ✓.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnRight(90);
        drive.forward(105);
        drive.turnLeft(90);
        drive.forward(132);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.turnRight(180);
        drive.forward(32);
        drive.turnRight(90);
        drive.forward(235);
        drive.turnRight(90);
        drive.forward(70);
        gripper.open();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "South-arc route should succeed; failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 20,
                "Expected 20 pts (8+12), got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_rd_pickup") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_rd_deposit") == true)
        // Confirm final position inside relay_station (x:5-45, y:168-213)
        let finalPos = run.finalSnapshot?.pose.position
        #expect((finalPos?.x ?? 0) >= 5 && (finalPos?.x ?? 0) <= 45,
                "Final x \(finalPos?.x ?? -1) should be in relay_station x-range 5-45")
        #expect((finalPos?.y ?? 0) >= 168 && (finalPos?.y ?? 0) <= 213,
                "Final y \(finalPos?.y ?? -1) should be in relay_station y-range 168-213")
    }

    @Test("mission_relay_delivery — pickup without deposit scores 8 pts and fails")
    func relayDeliveryPickupOnlyFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_relay_delivery"))
        // Position robot on cell_ion, pick up, but never reach relay_station.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 255, y: 152), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        arm.lower();
        gripper.close();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "Pickup without deposit should fail allRequired")
        #expect(run.missionResult?.score == 8,
                "Should score 8 pts for pickup only; got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_rd_pickup") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_rd_deposit") == false)
    }

    @Test("mission_relay_delivery — drive-only program scores 0 and fails")
    func relayDeliveryDriveOnlyFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_relay_delivery"))
        // Drive somewhere without touching cell_ion — neither objective met.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0)
        )
        let run = sim.run(program: "drive.forward(50);",
                           world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false)
        #expect(run.missionResult?.score == 0)
        #expect(run.missionResult?.metObjectiveIds.isEmpty == true)
    }

    // =========================================================================
    // MARK: - Mission 6: mission_crater_detour  (diff 3, 30 pts)
    // =========================================================================
    //
    // rock_gamma at (52,185). bay_alpha: x:5-67, y:228-290, deposit, sample.
    // beacon_pad: x:10-65, y:50-105, detection zone. beacon_tile: orange.
    //
    // Insight: the path from south to rock_gamma is bisected by crater_rim
    //   (x:38-102, y:154-168). Direct north at x:38-102 hits the rim.
    //   Slip must be x<38 (far-west approach) or east of boulder_W (x>114).
    //
    // Canonical route (far-west slip — x=35, west of crater_rim x≥38):
    //   1. turnLeft(90)   → heading 270° (west)
    //   2. forward(115)   → (35,20)   [x=35<38: west of crater_rim ✓]
    //   3. turnRight(90)  → heading 0° (north)    [270+90=360=0]
    //   4. forward(40)    → (35,60)   [x=35<38: crater_rim (x:38+) never crossed ✓;
    //                                   beacon_pad x:10-65 (35∈✓), y:50-105 (60∈✓) ✓]
    //   5. color()        → "orange" from beacon_tile ✓; detectColorInZone beacon_pad met ✓
    //   6. forward(125)   → (35,185)  [x=35<38: crater_rim y:154-168 never crossed ✓;
    //                                   boulder_W x:100-114 (x=35<100 ✓) ✓]
    //   7. turnRight(90)  → heading 90° (east)    [0+90=90]
    //   8. forward(17)    → (52,185)  [y=185: boulder_N x:114-178, y:184-198 (x=52<114 ✓) ✓;
    //                                   = rock_gamma ✓]
    //   9. arm.lower()    → arm=90°
    //  10. gripper.close()→ picks rock_gamma (dist=0≤14) ✓
    //  11. arm.raise()    → arm=0°
    //  12. turnLeft(90)   → heading 0° (north)    [90-90=0]
    //  13. forward(65)    → (52,250)  [x=52: boulder_N x:114-178 (x=52<114 ✓);
    //                                   bay_alpha x:5-67 (52∈✓), y:228-290 (250∈✓) ✓]
    //  14. gripper.open() → deposits rock_gamma in bay_alpha ✓
    //
    // Alternate route (east-around — stay east of boulder ring):
    //   East to x=195, north to y=215 (above boulder_N top y=198), west to x=52,
    //   south to y=185, pick up, north to bay_alpha. More actions but avoids the
    //   far-west detour; does not pass through beacon_pad (bonus not scored).
    //
    // Objectives:
    //   obj_cd_pickup   pickUpItem rock_gamma          10 pts  required
    //   obj_cd_deposit  depositItemInZone bay_alpha     15 pts  required
    //   obj_cd_beacon   detectColorInZone beacon_pad     5 pts  optional
    //   Total = 30 pts. successRule: allRequired (delivery pair only).

    @Test("mission_crater_detour — loads with correct metadata")
    func craterDetourLoads() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_crater_detour"))
        #expect(m.difficulty == 3)
        #expect(m.totalPossiblePoints == 30)
        #expect(m.objectives.count == 3)
        // Delivery pair is required; bonus is not
        #expect(m.objectives.filter { $0.isRequired }.count == 2)
        let pickupObj = m.objectives.first { $0.kind == .pickUpItem }
        #expect(pickupObj?.targetItemId == "rock_gamma")
        #expect(pickupObj?.isRequired == true)
        let depositObj = m.objectives.first { $0.kind == .depositItemInZone }
        #expect(depositObj?.targetItemId == "rock_gamma")
        #expect(depositObj?.targetZoneId == "bay_alpha")
        #expect(depositObj?.isRequired == true)
        let bonusObj = m.objectives.first { $0.kind == .detectColorInZone }
        #expect(bonusObj?.targetZoneId == "beacon_pad")
        #expect(bonusObj?.expectedColor == "orange")
        #expect(bonusObj?.isRequired == false)
        #expect(m.fieldId == "field_arena")
    }

    @Test("mission_crater_detour — far-west route with beacon bonus scores 30 pts and succeeds")
    func craterDetourFarWestFullScore() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_crater_detour"))
        // Start: (150,20) heading north.
        // West 115 → (35,20): x=35<38, west of crater_rim x-range.
        // North 40 → (35,60): inside beacon_pad (x:10-65 ✓, y:50-105 ✓).
        // color() → "orange" from beacon_tile ✓.
        // North 125 → (35,185): x=35<38, clears crater_rim at y:154-168 ✓.
        // East 17 → (52,185): = rock_gamma; boulder_N (x:114-178) x=52<114 ✓.
        // arm.lower/gripper.close → pick up; arm.raise.
        // North 65 → (52,250): bay_alpha x:5-67 (52∈✓), y:228-290 (250∈✓).
        // gripper.open → deposit rock_gamma in bay_alpha ✓.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnLeft(90);
        drive.forward(115);
        drive.turnRight(90);
        drive.forward(40);
        color();
        drive.forward(125);
        drive.turnRight(90);
        drive.forward(17);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.turnLeft(90);
        drive.forward(65);
        gripper.open();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "Far-west route with beacon bonus should succeed; failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 30,
                "Expected 30 pts (10+15+5), got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_cd_pickup") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_cd_deposit") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_cd_beacon") == true)
    }

    @Test("mission_crater_detour — delivery without beacon bonus scores 25 pts but still succeeds")
    func craterDetourNoBonus() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_crater_detour"))
        // Same far-west slip but skip the color() call — bonus not earned.
        // Required pair still met → allRequired success at 25 pts.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnLeft(90);
        drive.forward(115);
        drive.turnRight(90);
        drive.forward(165);
        drive.turnRight(90);
        drive.forward(17);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.turnLeft(90);
        drive.forward(65);
        gripper.open();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "Delivery without bonus should still succeed (allRequired = delivery pair only)")
        #expect(run.missionResult?.score == 25,
                "Expected 25 pts (10+15), got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_cd_pickup") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_cd_deposit") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_cd_beacon") == false)
    }

    @Test("mission_crater_detour — pickup only (no deposit) scores 10 pts and fails")
    func craterDetourPickupOnlyFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_crater_detour"))
        // Start on rock_gamma, pick up but never deposit.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 52, y: 185), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        arm.lower();
        gripper.close();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "Pickup without deposit should fail allRequired")
        #expect(run.missionResult?.score == 10,
                "Should score 10 pts for pickup only; got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_cd_pickup") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_cd_deposit") == false)
    }

    // =========================================================================
    // MARK: - Mission 7: mission_deep_field_run  (diff 3, 30 pts)
    // =========================================================================
    //
    // core_zeta at (248,38). solar_pad: x:220-280, y:45-100 (solar_tile yellow).
    // bay_beta: x:233-295, y:228-290, deposit, acceptsItemType "core".
    //
    // Deposit gating note: gripper.open() deposits in the first deposit zone
    // whose rect contains the robot — NO type/color enforcement at the API level.
    // depositItemInZone objective checks depositLog[itemId]==zoneId. So robot must
    // physically be inside bay_beta when gripper.open() is called.
    //
    // Canonical route (east corridor — entirely east of obstacle field):
    //   Start (150,20) heading north (0°):
    //   1. turnRight(90)  → heading 90° (east)
    //   2. forward(98)    → (248,20)  [y=20<62: scatter clear ✓]
    //   3. turnLeft(90)   → heading 0° (north)   [90-90=0]
    //   4. forward(18)    → (248,38)  [x=248>190 ✓; = core_zeta ✓]
    //   5. arm.lower()    → arm=90°
    //   6. gripper.close()→ picks core_zeta (dist=0≤14) ✓
    //   7. arm.raise()    → arm=0°
    //   8. forward(34)    → (248,72)  [x=248>190: scatter (y:62-84) clear ✓;
    //                                   solar_pad x:220-280 (248∈✓), y:45-100 (72∈✓) ✓]
    //   9. color()        → "yellow" from solar_tile ✓; detectColorInZone solar_pad met ✓
    //  10. forward(188)   → (248,260) [x=248>190: scatter (y<84) clear (y>84 by step 10 ✓);
    //                                   bay_beta x:233-295 (248∈✓), y:228-290 (260∈✓) ✓]
    //  11. gripper.open() → deposits core_zeta in bay_beta ✓
    //
    // Chain insight: core_zeta is near the south-east start; solar_pad is on the
    // same north corridor at x≈248; bay_beta is at the north end of that corridor.
    // One straight east-side run chains all three objectives with no backtracking.
    //
    // Alternate route: pick up core_zeta, detour west to hit solar_pad from the
    // south, then come east and north to bay_beta. More actions, same score.
    //
    // Objectives:
    //   obj_dfr_pickup  pickUpItem core_zeta           10 pts  required
    //   obj_dfr_solar   detectColorInZone solar_pad     5 pts  required
    //   obj_dfr_deposit depositItemInZone bay_beta      15 pts  required
    //   Total = 30 pts. successRule: allRequired.

    @Test("mission_deep_field_run — loads with correct metadata")
    func deepFieldRunLoads() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_deep_field_run"))
        #expect(m.difficulty == 3)
        #expect(m.totalPossiblePoints == 30)
        #expect(m.objectives.count == 3)
        #expect(m.objectives.filter { $0.isRequired }.count == 3)
        let pickupObj = m.objectives.first { $0.kind == .pickUpItem }
        #expect(pickupObj?.targetItemId == "core_zeta")
        let solarObj = m.objectives.first { $0.kind == .detectColorInZone }
        #expect(solarObj?.targetZoneId == "solar_pad")
        #expect(solarObj?.expectedColor == "yellow")
        let depositObj = m.objectives.first { $0.kind == .depositItemInZone }
        #expect(depositObj?.targetItemId == "core_zeta")
        #expect(depositObj?.targetZoneId == "bay_beta")
        #expect(m.fieldId == "field_arena")
    }

    @Test("mission_deep_field_run — canonical east-corridor route scores 30 pts and succeeds")
    func deepFieldRunSuccess() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_deep_field_run"))
        // Start: (150,20) heading north.
        // East 98 → (248,20); north 18 → (248,38): pick up core_zeta.
        // North 34 → (248,72): inside solar_pad (x:220-280, y:45-100); color() → "yellow" ✓.
        // North 188 → (248,260): inside bay_beta (x:233-295, y:228-290); gripper.open → deposit ✓.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnRight(90);
        drive.forward(98);
        drive.turnLeft(90);
        drive.forward(18);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.forward(34);
        color();
        drive.forward(188);
        gripper.open();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "East-corridor chain should succeed; failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 30,
                "Expected 30 pts (10+5+15), got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_dfr_pickup") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_dfr_solar") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_dfr_deposit") == true)
        // Confirm final position inside bay_beta (x:233-295, y:228-290)
        let finalPos = run.finalSnapshot?.pose.position
        #expect((finalPos?.x ?? 0) >= 233 && (finalPos?.x ?? 0) <= 295,
                "Final x \(finalPos?.x ?? -1) should be in bay_beta x-range 233-295")
        #expect((finalPos?.y ?? 0) >= 228 && (finalPos?.y ?? 0) <= 290,
                "Final y \(finalPos?.y ?? -1) should be in bay_beta y-range 228-290")
    }

    @Test("mission_deep_field_run — skipping solar scan scores 25 pts and fails allRequired")
    func deepFieldRunSkipSolarFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_deep_field_run"))
        // Same corridor route but omit color() — solar objective not met → allRequired fails.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnRight(90);
        drive.forward(98);
        drive.turnLeft(90);
        drive.forward(18);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.forward(222);
        gripper.open();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "Missing solar scan should fail allRequired")
        #expect(run.missionResult?.score == 25,
                "Should score 25 pts (pickup+deposit, no solar); got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_dfr_pickup") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_dfr_solar") == false)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_dfr_deposit") == true)
    }

    @Test("mission_deep_field_run — drive-only program scores 0 and fails")
    func deepFieldRunDriveOnlyFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_deep_field_run"))
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0)
        )
        let run = sim.run(program: "drive.forward(100);",
                           world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false)
        #expect(run.missionResult?.score == 0)
        #expect(run.missionResult?.metObjectiveIds.isEmpty == true)
    }

    // =========================================================================
    // MARK: - Mission 8: mission_ring_scout  (diff 3, 30 pts)
    // =========================================================================
    //
    // Boulder ring geometry:
    //   boulder_W: x:100-114, y:128-198 (west wall)
    //   boulder_N: x:114-178, y:184-198 (north wall)
    //   boulder_S: x:114-178, y:126-140 (south wall)
    //   East gap:  open at x>178, y:140-184 (gap height 44 cm)
    //   Gap centre: (178+, 162)
    //
    // Mission: stop rover within 14 cm of (190,162) — east gap mouth — with arm at 45°.
    //
    // Canonical route (east detour then west approach):
    //   Start (150,20) heading north (0°):
    //   1. turnRight(90)  → heading 90° (east)
    //   2. forward(105)   → (255,20)  [y=20<62: scatter clear ✓]
    //   3. turnLeft(90)   → heading 0° (north)   [90-90=0]
    //   4. forward(142)   → (255,162) [x=255>190: scatter (y:62-84) clear ✓;
    //                                   gap y:140-184 (162∈✓) — east of ring ✓]
    //   5. turnLeft(90)   → heading 270° (west)  [0-90=270]
    //   6. forward(65)    → (190,162) [y=162: gap y:140-184 (162∈✓);
    //                                   x=190>178: outside ring's east edge ✓;
    //                                   dist to boulder_W face (x=114): 76 cm — not reached ✓]
    //   7. arm.moveTo(45) → arm=45°   ✓
    //
    // reachPose: target (190,162), tol 14 cm; final pos (190,162), dist=0 ≤ 14 ✓.
    // armToAngle: target 45°; final arm=45°, |45-45|=0 ≤ 5° ✓.
    //
    // Sensor-gated alternate: from (255,162) heading west, use
    //   while (distance() > 76) { drive.forward(5); }
    //   distance() = 255-114=141 cm at start; stops when ≤76 → robot at (255-65)=190. ✓
    //   Uses more actions but is robust to dead-reckoning error.
    //
    // Obstacle clearances:
    //   Step 2 (y=20, east): boulder_scatter y:62-84 (y=20<62 ✓). ✓
    //   Step 4 (x=255, north): scatter x:168-190 (x=255>190 ✓). ✓
    //   Step 6 (y=162, west): gap at y:140-184 (162∈✓); stop at x=190 > ring east edge x=178. ✓
    //
    // Objectives:
    //   obj_rs_approach  reachPose (190,162) tol 14 cm   20 pts  required
    //   obj_rs_survey    armToAngle 45°                   10 pts  required
    //   Total = 30 pts. successRule: allRequired.

    @Test("mission_ring_scout — loads with correct metadata")
    func ringScoutLoads() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_ring_scout"))
        #expect(m.difficulty == 3)
        #expect(m.totalPossiblePoints == 30)
        #expect(m.objectives.count == 2)
        #expect(m.objectives.filter { $0.isRequired }.count == 2)
        let poseObj = m.objectives.first { $0.kind == .reachPose }
        #expect(poseObj?.targetX == 190)
        #expect(poseObj?.targetY == 162)
        #expect(poseObj?.toleranceCm == 14)
        #expect(poseObj?.isRequired == true)
        let armObj = m.objectives.first { $0.kind == .armToAngle }
        #expect(armObj?.targetAngle == 45)
        #expect(armObj?.isRequired == true)
        #expect(m.fieldId == "field_arena")
    }

    @Test("mission_ring_scout — canonical approach scores 30 pts and succeeds")
    func ringScoutSuccess() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_ring_scout"))
        // Start: (150,20) heading north.
        // East 105 → (255,20); north 142 → (255,162).
        // West 65 → (190,162): just outside boulder ring's east gap (ring ends at x=178).
        // arm.moveTo(45): survey position ✓.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnRight(90);
        drive.forward(105);
        drive.turnLeft(90);
        drive.forward(142);
        drive.turnLeft(90);
        drive.forward(65);
        arm.moveTo(45);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "7-action approach should succeed; failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 30,
                "Expected 30 pts (20+10), got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_rs_approach") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_rs_survey") == true)
        // Confirm final position within 14 cm of (190,162)
        let finalPos = run.finalSnapshot?.pose.position
        let dx = (finalPos?.x ?? 0) - 190
        let dy = (finalPos?.y ?? 0) - 162
        let dist = (dx*dx + dy*dy).squareRoot()
        #expect(dist <= 14,
                "Final pos (\(finalPos?.x ?? -1),\(finalPos?.y ?? -1)) should be within 14 cm of (190,162); dist=\(dist)")
        #expect(abs((run.finalSnapshot?.armAngle ?? -1) - 45) <= 5)
    }

    @Test("mission_ring_scout — stopping too far east (x=215) fails reachPose")
    func ringScoutTooFarEastFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_ring_scout"))
        // Robot stops at (215,162): distance to target (190,162) = 25 > 14 cm → reachPose fails.
        // arm.moveTo(45) succeeds but reachPose doesn't → allRequired fails.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnRight(90);
        drive.forward(105);
        drive.turnLeft(90);
        drive.forward(142);
        drive.turnLeft(90);
        drive.forward(40);
        arm.moveTo(45);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "Stopping at x=215 is 25 cm from target — outside 14 cm tolerance, should fail")
        #expect(run.missionResult?.score == 10,
                "Should score 10 pts for arm only; got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_rs_approach") == false)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_rs_survey") == true)
    }

    @Test("mission_ring_scout — correct position but wrong arm angle (90°) fails armToAngle")
    func ringScoutWrongAngleFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_ring_scout"))
        // Reach (190,162) but arm at 90° — |90-45|=45 > 5° tolerance.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 190, y: 162), headingDegrees: 270),
            armAngle: 0, isGripperOpen: true
        )
        let run = sim.run(program: "arm.moveTo(90);", world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "Arm at 90° is 45° from target — outside 5° tolerance, should fail")
        #expect(run.missionResult?.score == 20,
                "Should score 20 pts for reachPose only; got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_rs_approach") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_rs_survey") == false)
    }
}
