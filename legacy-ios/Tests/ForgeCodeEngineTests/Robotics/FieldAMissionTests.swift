import Testing
@testable import ForgeCodeEngine

/// End-to-end tests for the four Batch-1 missions on the Cargo Command field
/// (field_warehouse, 240×240 cm).
///
/// Field layout quick-reference (heading 0°=north=+Y, CW-positive):
///   Obstacles
///     shelf_1   x:90-150,  y:130-150
///     shelf_2   x:190-240, y:130-150
///     rack_1    x:160-180, y:155-230
///     rack_2    x:160-180, y:50-115
///   Key items
///     barrel_1  (210, 185)  green barrel,  pickupRadius 15
///     crate_C   (210,  75)  blue crate,    pickupRadius 15
///   Key zones
///     goal_zone       x:100-140, y:100-140   (goal)
///     depot_green     x:10-60,   y:180-230   (deposit, accepts barrel)
///     depot_blue      x:180-230, y:10-60     (deposit, accepts crate)
///     detection_east  x:185-230, y:55-95     (detection)
///     home_base       x:95-145,  y:5-35      (goal)
///   Colored regions
///     blue_tile       x:185-230, y:55-95
@Suite("Batch-1 Cargo Command missions (arm-handshake, green-barrel, color-scout, corridor-courier)")
struct FieldAMissionTests {

    // MARK: - Shared helpers

    private func world() throws -> FieldWorld {
        try #require(try RoboticsLibrary.field(id: "field_warehouse"))
    }

    private let sim = RoboticsSimulator()

    // =========================================================================
    // MARK: - Mission 1: mission_arm_handshake  (diff 1, 10 pts)
    // =========================================================================
    //
    // Route (start (120,20) heading north):
    //   1. drive.forward(100)  → (120,120)  [inside goal_zone x:100-140,y:100-140] ✓
    //                                        [y=120 < 130 = shelf_1 bottom → clear of shelf_1]
    //   2. arm.moveTo(45)      → arm=45°   [armToAngle obj: |45-45|=0 ≤ 5] ✓
    //   Total robot actions: 2
    //
    // Obstacle clearance:
    //   shelf_1 is x:90-150, y:130-150. Robot travels along x=120, y=20→120.
    //   y never reaches 130, so shelf_1 is never entered. Clear ✓.
    //
    // Objectives:
    //   obj_reach_checkin  reachZone goal_zone   6 pts  required
    //   obj_arm_signal     armToAngle 45°         4 pts  required
    //   Total = 10 pts. successRule: allRequired.

    @Test("mission_arm_handshake — loads with correct metadata")
    func armHandshakeLoads() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_arm_handshake"))
        #expect(m.difficulty == 1)
        #expect(m.totalPossiblePoints == 10)
        #expect(m.objectives.count == 2)
        #expect(m.objectives.first { $0.kind == .reachZone } != nil)
        #expect(m.objectives.first { $0.kind == .armToAngle } != nil)
    }

    @Test("mission_arm_handshake — verified solution scores 10 pts and succeeds")
    func armHandshakeSuccess() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_arm_handshake"))
        // Start: (120,20) heading north (0°).
        // drive.forward(100) → (120,120); inside goal_zone (x:100-140,y:100-140). ✓
        //   y=120 < 130 = shelf_1 bottom (y:130-150) → shelf_1 not entered. ✓
        // arm.moveTo(45) → arm angle = 45°; |45-45|=0 ≤ 5° tolerance. ✓
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.forward(100);
        arm.moveTo(45);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "Verified 2-action solution should succeed; runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 10,
                "Expected 10 pts (6+4), got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_reach_checkin") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_arm_signal") == true)
        // Confirm final position is inside goal_zone
        let finalPos = run.finalSnapshot?.pose.position
        #expect((finalPos?.x ?? 0) >= 100 && (finalPos?.x ?? 0) <= 140)
        #expect((finalPos?.y ?? 0) >= 100 && (finalPos?.y ?? 0) <= 140)
        // Confirm arm angle
        #expect(abs((run.finalSnapshot?.armAngle ?? -1) - 45) <= 5)
    }

    @Test("mission_arm_handshake — drive-only (no arm call) fails: reachZone met but armToAngle not met")
    func armHandshakeDriveOnlyFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_arm_handshake"))
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        // Drive to goal_zone (100 cm clears shelf_1 at y:130-150) but never move the arm.
        let run = sim.run(program: "drive.forward(100);", world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "Missing armToAngle should fail allRequired rule")
        #expect(run.missionResult?.score == 6,
                "Should score 6 pts for reachZone only")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_reach_checkin") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_arm_signal") == false)
    }

    @Test("mission_arm_handshake — wrong arm angle (arm at 90°) fails armToAngle objective")
    func armHandshakeWrongAngleFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_arm_handshake"))
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        // Drive to zone (100 cm), but move arm to 90° (fully lowered) — 45° away, outside 5° tolerance.
        let program = """
        drive.forward(100);
        arm.moveTo(90);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "arm at 90° is 45° away from target 45° — outside tolerance, should fail")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_arm_signal") == false)
    }

    // =========================================================================
    // MARK: - Mission 2: mission_green_barrel_quickwin  (diff 2, 20 pts)
    // =========================================================================
    //
    // Route (start (185,20) heading north):
    //   barrel_1 is at (210,185). depot_green is x:10-60, y:180-230.
    //   x=185 is the clear "east-of-rack_2, west-of-shelf_2" corridor:
    //     rack_2  x:160-180 → x=185 clears east edge
    //     shelf_2 x:190-240 → x=185 clears west edge
    //
    //   1. drive.forward(165)  → (185,185)  [clear corridor, no obstacles at x=185]
    //   2. drive.turnRight(90) → heading 90° (east)
    //   3. drive.forward(25)   → (210,185)  [barrel_1; y=185>150 clears shelf_2]
    //   4. arm.lower()         → arm=90°
    //   5. gripper.close()     → picks up barrel_1 (dist=0 ≤ 15 cm) ✓
    //   6. arm.raise()         → arm=0°
    //   7. drive.turnRight(90) → heading 180° (south)
    //   8. drive.forward(32)   → (210,153)  [y<155 clears rack_1 top; y>150 clears shelf_2]
    //   9. drive.turnRight(90) → heading 270° (west)
    //  10. drive.forward(175)  → (35,153)   [y=153 clears rack_1(y≥155), rack_2(y≤115),
    //                                         shelf_1(y≤150) — all below or above y=153]
    //  11. drive.turnRight(90) → heading 0° (north)  [from 270°, +90° = 360°=0°]
    //  12. drive.forward(30)   → (35,183)   [depot_green x:10-60,y:180-230; x=35✓,y=183✓]
    //  13. gripper.open()      → deposits barrel_1 into depot_green ✓
    //   Total robot actions: 13
    //
    // Obstacle clearance at each segment:
    //   Seg 1 (x=185, y=20→185): rack_2 x:160-180 (x=185>180 ✓); shelf_2 x:190-240 (x=185<190 ✓);
    //     rack_1 x:160-180 (x=185>180 ✓). All clear.
    //   Seg 3 (y=185, x=185→210): rack_1 x:160-180 (x>180 ✓); shelf_2 y:130-150 (y=185>150 ✓). Clear.
    //   Seg 8 (x=210, y=185→153): shelf_2 y:130-150 (y≥153>150 ✓); rack_1 y:155-230 (x=210>180 ✓). Clear.
    //   Seg 10 (y=153, x=210→35): rack_1 y:155-230 (y=153<155 ✓); rack_2 y:50-115 (y=153>115 ✓);
    //     shelf_1 y:130-150 (y=153>150 ✓). All clear.
    //   Seg 12 (x=35, y=153→183): no obstacles at x=35. Clear.
    //
    // Objectives:
    //   obj_pickup_barrel1  pickUpItem barrel_1    10 pts  required
    //   obj_deposit_barrel1 depositItemInZone       10 pts  required
    //   Total = 20 pts. successRule: allRequired.

    @Test("mission_green_barrel_quickwin — loads with correct metadata")
    func greenBarrelLoads() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_green_barrel_quickwin"))
        #expect(m.difficulty == 2)
        #expect(m.totalPossiblePoints == 20)
        #expect(m.objectives.count == 2)
        #expect(m.objectives.filter { $0.isRequired }.count == 2)
    }

    @Test("mission_green_barrel_quickwin — verified solution scores 20 pts and succeeds")
    func greenBarrelSuccess() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_green_barrel_quickwin"))
        // Start: (185,20) heading north.
        // The x=185 corridor is clear of all four obstacles (see route notes above).
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 185, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.forward(165);
        drive.turnRight(90);
        drive.forward(25);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.turnRight(90);
        drive.forward(32);
        drive.turnRight(90);
        drive.forward(175);
        drive.turnRight(90);
        drive.forward(30);
        gripper.open();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "Verified 13-action solution should succeed")
        #expect(run.missionResult?.score == 20,
                "Expected 20 pts (10+10), got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_pickup_barrel1") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_deposit_barrel1") == true)
    }

    @Test("mission_green_barrel_quickwin — drive-only program scores 0 and fails")
    func greenBarrelDriveOnlyFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_green_barrel_quickwin"))
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 185, y: 20), headingDegrees: 0)
        )
        // Just drive north — no arm/gripper interaction.
        let run = sim.run(program: "drive.forward(50);", world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "Drive-only cannot meet pickUpItem or depositItemInZone objectives")
        #expect(run.missionResult?.score == 0,
                "Expected 0 pts; got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.isEmpty == true)
    }

    @Test("mission_green_barrel_quickwin — pickup without deposit scores 10 pts and fails allRequired")
    func greenBarrelPickupOnlyFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_green_barrel_quickwin"))
        // Position the robot directly on barrel_1; pick it up but never deposit it.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 210, y: 185), headingDegrees: 0),
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
                "Should score 10 pts for pickup only")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_pickup_barrel1") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_deposit_barrel1") == false)
    }

    // =========================================================================
    // MARK: - Mission 3: mission_color_scout  (diff 2, 20 pts)
    // =========================================================================
    //
    // Route (start (120,20) heading north):
    //   Goal: reach detection_east (x:185-230, y:55-95) and call color.isBlue(),
    //         then finish inside home_base (x:95-145, y:5-35).
    //
    //   blue_tile colored region: x:185-230, y:55-95  (same rect as detection_east)
    //
    //   1. drive.turnRight(90)  → heading 90° (east)
    //   2. drive.forward(90)    → (210,20)   [y=20 < 50, clears rack_2(y:50-115); depot_blue
    //                                          is a zone, not an obstacle]
    //   3. drive.turnLeft(90)   → heading 0° (north)  [from 90°, -90°=0°]
    //   4. drive.forward(55)    → (210,75)   [x=210>180 clears rack_2(x:160-180);
    //                                          y=75 inside detection_east(x:185-230,y:55-95) ✓]
    //      color.isBlue()       → logs .color("blue"); robot at (210,75) inside
    //                              detection_east rect → detectColorInZone obj met ✓
    //   5. drive.turnRight(180) → heading 180° (south)
    //   6. drive.forward(55)    → (210,20)   [y=75-55=20; x=210 clear of rack_2]
    //   7. drive.turnRight(90)  → heading 270° (west)
    //   8. drive.forward(90)    → (120,20)   [y=20<50 clears rack_2(y:50-115)]
    //      Final pose (120,20): home_base x:95-145,y:5-35 → x=120✓,y=20✓ → reachZone ✓
    //   Total robot actions: 8
    //
    // Obstacle clearance:
    //   Seg 2 (y=20, x=120→210): rack_2 y:50-115 (y=20<50 ✓); shelf_2 is y:130-150 (y=20 ✓).
    //   Seg 4 (x=210, y=20→75): rack_2 x:160-180 (x=210>180 ✓); shelf_2 x:190-240,y:130-150
    //     (y=75<130 ✓ — we never reach that y). All clear.
    //   Seg 6 (x=210, y=75→20): reverse of seg 4. Clear.
    //   Seg 8 (y=20, x=210→120): same as seg 2 reversed. Clear.
    //
    // Objectives:
    //   obj_detect_blue  detectColorInZone detection_east expectedColor blue  12 pts  required
    //   obj_return_home  reachZone home_base                                   8 pts  required
    //   Total = 20 pts. successRule: allRequired.

    @Test("mission_color_scout — loads with correct metadata")
    func colorScoutLoads() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_color_scout"))
        #expect(m.difficulty == 2)
        #expect(m.totalPossiblePoints == 20)
        let detectObj = m.objectives.first { $0.kind == .detectColorInZone }
        #expect(detectObj != nil)
        #expect(detectObj?.expectedColor == "blue")
        #expect(detectObj?.targetZoneId == "detection_east")
        let reachObj = m.objectives.first { $0.kind == .reachZone }
        #expect(reachObj?.targetZoneId == "home_base")
    }

    @Test("mission_color_scout — verified solution scores 20 pts and succeeds")
    func colorScoutSuccess() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_color_scout"))
        // Start: (120,20) heading north (0°). Inside home_base at start, but reachZone
        // checks FINAL pose — the run ends at (120,20) after the return trip, which
        // is also inside home_base. ✓
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0)
        )
        let program = """
        drive.turnRight(90);
        drive.forward(90);
        drive.turnLeft(90);
        drive.forward(55);
        color.isBlue();
        drive.turnRight(180);
        drive.forward(55);
        drive.turnRight(90);
        drive.forward(90);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "Verified 8-action solution should succeed; failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 20,
                "Expected 20 pts (12+8), got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_detect_blue") == true,
                "color.isBlue() inside detection_east should satisfy detectColorInZone")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_return_home") == true,
                "Final pose (120,20) should be inside home_base")
        // Confirm robot ended inside home_base
        let finalPos = run.finalSnapshot?.pose.position
        #expect((finalPos?.x ?? 0) >= 95 && (finalPos?.x ?? 0) <= 145,
                "Final x \(finalPos?.x ?? -1) should be in home_base x:95-145")
        #expect((finalPos?.y ?? 0) >= 5 && (finalPos?.y ?? 0) <= 35,
                "Final y \(finalPos?.y ?? -1) should be in home_base y:5-35")
    }

    @Test("mission_color_scout — skipping color detection scores only 8 pts and fails")
    func colorScoutSkipDetectionFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_color_scout"))
        // Drive to detection zone but never call a color sensor — then return.
        // reachZone home_base will be met but detectColorInZone will not.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0)
        )
        let program = """
        drive.turnRight(90);
        drive.forward(90);
        drive.turnLeft(90);
        drive.forward(55);
        drive.turnRight(180);
        drive.forward(55);
        drive.turnRight(90);
        drive.forward(90);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "Missing detection should fail allRequired")
        #expect(run.missionResult?.score == 8,
                "Should score 8 pts for home_base only; got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_detect_blue") == false)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_return_home") == true)
    }

    @Test("mission_color_scout — reaching detection zone but not returning fails reachZone")
    func colorScoutNoReturnFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_color_scout"))
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0)
        )
        // Go to detection zone and scan, but do not return to home_base.
        let program = """
        drive.turnRight(90);
        drive.forward(90);
        drive.turnLeft(90);
        drive.forward(55);
        color.isBlue();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "Missing home_base return should fail allRequired")
        #expect(run.missionResult?.score == 12,
                "Should score 12 pts for detection only; got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_detect_blue") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_return_home") == false)
    }

    // =========================================================================
    // MARK: - Mission 4: mission_corridor_courier  (diff 3, 30 pts)
    // =========================================================================
    //
    // crate_C is at (210,75) — east of rack_2 (x:160-180, y:50-115).
    // The direct path from the west (e.g. heading east at y=75) passes through rack_2. Blocked.
    // Insight: route east at y<50 (south of rack_2), then north to crate_C.
    //
    // depot_blue: x:180-230, y:10-60.  blue_tile / detection_east: x:185-230, y:55-95.
    //
    // Route (start (120,20) heading north):
    //   1. drive.turnRight(90)  → heading 90° (east)                   [action 1]
    //   2. drive.forward(90)    → (210,20)  [y=20<50 clears rack_2]    [action 2]
    //   3. drive.turnLeft(90)   → heading 0° (north)  [90-90=0]        [action 3]
    //   4. drive.forward(55)    → (210,75)  [x=210>180 clears rack_2;  [action 4]
    //                                         (210,75) inside detection_east ✓]
    //      color.isBlue()  → bonus 5 pts ✓ (sensor, not counted against action budget)
    //   5. arm.lower()          → arm=90°                               [action 5]
    //   6. gripper.close()      → picks up crate_C (dist=0 ≤ 15) ✓     [action 6]
    //   7. arm.raise()          → arm=0°                                [action 7]
    //   8. drive.turnRight(180) → heading 180° (south)                  [action 8]
    //   9. drive.forward(45)    → (210,30)  [y=75-45=30;               [action 9]
    //                                         depot_blue x:180-230,y:10-60; x=210✓,y=30✓]
    //  10. gripper.open()       → deposits crate_C in depot_blue ✓      [action 10]
    //
    //   Total robot actions: 10
    //
    // Obstacle clearance:
    //   Seg 2 (y=20, x=120→210): rack_2 y:50-115 (y=20<50 ✓).
    //   Seg 4 (x=210, y=20→75): rack_2 x:160-180 (x=210>180 ✓).
    //     shelf_2 x:190-240, y:130-150 — y only reaches 75, never enters y:130-150. ✓
    //   Seg 9 (x=210, y=75→30): heading south (decreasing y). At x=210:
    //     rack_2 x:160-180 (x=210>180 ✓); shelf_2 y:130-150 (y≤75<130 ✓). Clear.
    //     depot_blue zone at y:10-60 — zone, not obstacle. ✓
    //
    // Objectives:
    //   obj_pickup_crate_c    pickUpItem crate_C            10 pts  required
    //   obj_deposit_crate_c   depositItemInZone depot_blue  15 pts  required
    //   obj_detect_blue_bonus detectColorInZone detection_east blue  5 pts  optional
    //   Total = 30 pts. successRule: allRequired (required objs = pickup + deposit = 25 pts min).

    @Test("mission_corridor_courier — loads with correct metadata")
    func corridorCourierLoads() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_corridor_courier"))
        #expect(m.difficulty == 3)
        #expect(m.totalPossiblePoints == 30)
        #expect(m.maxActions == nil, "No per-mission action cap on this mission")
        #expect(m.objectives.count == 3)
        let required = m.objectives.filter { $0.isRequired }
        let optional = m.objectives.filter { !$0.isRequired }
        #expect(required.count == 2)
        #expect(optional.count == 1)
        #expect(required.map { $0.points }.reduce(0, +) == 25)
    }

    @Test("mission_corridor_courier — verified solution with bonus scores 30 pts and succeeds")
    func corridorCourierFullSuccess() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_corridor_courier"))
        // Start: (120,20) heading north.
        // Route uses east-side detour (south of rack_2) to reach crate_C.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnRight(90);
        drive.forward(90);
        drive.turnLeft(90);
        drive.forward(55);
        color.isBlue();
        arm.lower();
        gripper.close();
        arm.raise();
        drive.turnRight(180);
        drive.forward(45);
        gripper.open();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "10-action solution (within maxActions=20) should succeed; failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 30,
                "Expected 30 pts (10+15+5), got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_pickup_crate_c") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_deposit_crate_c") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_detect_blue_bonus") == true)
    }

    @Test("mission_corridor_courier — solution without bonus scores 25 pts and still succeeds")
    func corridorCourierNoBonus() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_corridor_courier"))
        // Same route but skip color.isBlue() — allRequired only needs pickup + deposit.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnRight(90);
        drive.forward(90);
        drive.turnLeft(90);
        drive.forward(55);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.turnRight(180);
        drive.forward(45);
        gripper.open();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "Required objectives met → success even without bonus")
        #expect(run.missionResult?.score == 25,
                "Expected 25 pts (10+15), got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_detect_blue_bonus") == false)
    }

    @Test("mission_corridor_courier — drive-only program scores 0 and fails")
    func corridorCourierDriveOnlyFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_corridor_courier"))
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0)
        )
        // Drive toward crate_C area but never use arm or gripper.
        let run = sim.run(program: "drive.turnRight(90); drive.forward(90);",
                           world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "Drive-only cannot satisfy pickup or deposit objectives")
        #expect(run.missionResult?.score == 0)
        #expect(run.missionResult?.metObjectiveIds.isEmpty == true)
    }

    @Test("mission_corridor_courier — pickup succeeds but missing deposit fails allRequired")
    func corridorCourierPickupOnlyFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_corridor_courier"))
        // Position robot directly on crate_C; pick it up but do not deposit it.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 210, y: 75), headingDegrees: 0),
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
        #expect(run.missionResult?.metObjectiveIds.contains("obj_pickup_crate_c") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_deposit_crate_c") == false)
    }

    // =========================================================================
    // MARK: - Mission 5: mission_double_dispatch  (diff 3, 30 pts)
    // =========================================================================
    //
    // Two-crate sorting run: crate_B (blue, 120,180) → depot_blue; crate_A (red, 60,180) → depot_red.
    // Obstacle insight: direct north drive from (120,20) at x=120 hits shelf_1 (x:90-150,y:130-150).
    // Must route at x=155 (just east of shelf_1 right edge x=150) to bypass.
    //
    // Canonical route (start 120,20 heading north, footprintRadius=0):
    //  1. turnRight(90)        → east
    //  2. forward(35)          → (155,20)          [x=155>150, east of shelf_1]
    //  3. turnLeft(90)         → north
    //  4. forward(160)         → (155,180)          [x=155 clear of all obstacles]
    //  5. turnLeft(90)         → west
    //  6. forward(35)          → (120,180)          [crate_B at (120,180)]
    //  7. arm.lower()          → arm=90°
    //  8. gripper.close()      → picks crate_B (dist=0≤15) ✓
    //  9. arm.raise()          → arm=0°
    // 10. turnLeft(90)         → south              [from west 270° → -90° = 180°]
    // 11. turnLeft(90)         → east               [180° → 90°]
    // 12. forward(35)          → (155,180)
    // 13. turnRight(90)        → south
    // 14. forward(160)         → (155,20)           [x=155 corridor, clear]
    // 15. turnLeft(90)         → east
    // 16. forward(50)          → (205,20)
    // 17. gripper.open()       → deposits crate_B in depot_blue (x:180-230,y:10-60) ✓
    // 18. turnRight(180)       → west
    // 19. forward(145)         → (60,20)
    // 20. turnRight(90)        → north              [from west 270° → +90° = 0°]
    // 21. forward(160)         → (60,180)           [crate_A at (60,180), x=60<90 clear]
    // 22. arm.lower()
    // 23. gripper.close()      → picks crate_A (dist=0≤15) ✓
    // 24. arm.raise()
    // 25. turnRight(180)       → south
    // 26. forward(160)         → (60,20)
    // 27. gripper.open()       → deposits crate_A in depot_red (x:10-60,y:10-60) ✓
    //   Total: 27 actions. Score=30. allRequired → success.
    //
    // Obstacle clearance:
    //   x=155 corridor: shelf_1 right edge x=150 (155>150 ✓); rack_2 left edge x=160 (155<160 ✓).
    //   y=20 eastward: rack_2 y:50-115 (y=20<50 ✓).
    //   x=60 northward: shelf_1 x:90-150 (60<90 ✓); rack_1/2 x:160-180 (60<160 ✓).
    //
    // Wrong-bin negative: deposit crate_A in depot_blue → depositItemInZone obj refs depot_red,
    //   so obj_dd_deposit_a not met → allRequired fails.

    @Test("mission_double_dispatch — loads with correct metadata")
    func doubleDispatchLoads() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_double_dispatch"))
        #expect(m.difficulty == 3)
        #expect(m.totalPossiblePoints == 30)
        #expect(m.objectives.count == 4)
        #expect(m.objectives.filter { $0.isRequired }.count == 4)
        #expect(m.objectives.first { $0.id == "obj_dd_deposit_b" }?.targetZoneId == "depot_blue")
        #expect(m.objectives.first { $0.id == "obj_dd_deposit_a" }?.targetZoneId == "depot_red")
    }

    @Test("mission_double_dispatch — verified solution scores 30 pts and succeeds")
    func doubleDispatchSuccess() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_double_dispatch"))
        // Start: (120,20) heading north.
        // Route detours east to x=155 (just outside shelf_1 right edge x=150) to reach crate_B,
        // then returns south via same corridor before going east to depot_blue.
        // crate_A is west at x=60, approach is clear of all obstacles.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnRight(90);
        drive.forward(35);
        drive.turnLeft(90);
        drive.forward(160);
        drive.turnLeft(90);
        drive.forward(35);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.turnLeft(90);
        drive.turnLeft(90);
        drive.forward(35);
        drive.turnRight(90);
        drive.forward(160);
        drive.turnLeft(90);
        drive.forward(50);
        gripper.open();
        drive.turnRight(180);
        drive.forward(145);
        drive.turnRight(90);
        drive.forward(160);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.turnRight(180);
        drive.forward(160);
        gripper.open();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "27-action sorting solution should succeed; failure=\(run.missionResult?.failureReason ?? "none")")
        #expect(run.missionResult?.score == 30,
                "Expected 30 pts, got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_dd_pickup_b") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_dd_deposit_b") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_dd_pickup_a") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_dd_deposit_a") == true)
    }

    @Test("mission_double_dispatch — depositing crate_B in depot_red fails wrong-bin objective")
    func doubleDispatchWrongBinFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_double_dispatch"))
        // Place robot directly on crate_B and deposit it in depot_red (wrong bin).
        // obj_dd_deposit_b expects depot_blue; deposit in depot_red → that obj not met.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 180), headingDegrees: 180),
            armAngle: 0, isGripperOpen: true
        )
        // Pick crate_B at (120,180), drive south to y=20, then west to (35,20) → depot_red.
        let program = """
        arm.lower();
        gripper.close();
        arm.raise();
        drive.forward(160);
        drive.turnLeft(90);
        drive.forward(85);
        gripper.open();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "Depositing blue crate in red depot should fail allRequired")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_dd_deposit_b") == false,
                "deposit_b expects depot_blue; deposit in depot_red should not satisfy it")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_dd_pickup_b") == true,
                "Pickup should still be credited")
    }

    @Test("mission_double_dispatch — picking only one crate fails allRequired")
    func doubleDispatchPartialFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_double_dispatch"))
        // Pick and deliver only crate_A — crate_B objectives unmet → allRequired fails.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 60, y: 180), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        arm.lower();
        gripper.close();
        arm.raise();
        drive.turnRight(180);
        drive.forward(160);
        gripper.open();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "Only one crate delivered → allRequired fails (crate_B objectives missing)")
        #expect(run.missionResult?.score == 13,
                "Expected 13 pts (6 pickup_a + 7 deposit_a); got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_dd_pickup_a") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_dd_deposit_a") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_dd_pickup_b") == false)
    }

    // =========================================================================
    // MARK: - Mission 6: mission_shelf_inspection  (diff 3, 30 pts)
    // =========================================================================
    //
    // Sensor-gated approach: robot drives north using distance() sensor loop.
    // shelf_1 south face at y=130. Loop: while (distance() > 20) { drive.forward(5); }
    // Robot stops when distance ≤ 20 → y ≈ 110 (130 - 20 = 110).
    //
    // Step-by-step:
    //   distance() at y=20  → 110 > 20 → forward(5) → y=25
    //   distance() at y=25  → 105 > 20 → forward(5) → y=30
    //   ... (17 more iterations) ...
    //   distance() at y=105 →  25 > 20 → forward(5) → y=110
    //   distance() at y=110 →  20      → 20 > 20 = false → exit loop
    //   arm.moveTo(90) → arm=90°
    //   Final: (120,110), arm=90°.
    //   reachPose (120,110) toleranceCm=15: dist=0≤15 ✓  18 pts
    //   armToAngle 90°: |90-90|=0≤5    ✓  12 pts
    //   Total 30 pts. allRequired → success.
    //   Total actions: 18 forward(5) + 1 arm.moveTo = 19 actions.
    //
    // Distance sensor implementation: heading north (0°), ray shoots +Y; shelf_1 hit at y=130,
    //   distance = 130 - robot.y (for x=120 where shelf_1 x-range [90,150] contains 120).
    //
    // Negative: pure drive.forward(50) stops at y=70, dist to (120,110)=40>15 → reachPose fails.

    @Test("mission_shelf_inspection — loads with correct metadata")
    func shelfInspectionLoads() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_shelf_inspection"))
        #expect(m.difficulty == 3)
        #expect(m.totalPossiblePoints == 30)
        #expect(m.objectives.count == 2)
        let standoffObj = m.objectives.first { $0.id == "obj_si_standoff" }
        #expect(standoffObj?.kind == .reachPose)
        #expect(standoffObj?.targetX == 120)
        #expect(standoffObj?.targetY == 110)
        #expect(standoffObj?.toleranceCm == 15)
        let armObj = m.objectives.first { $0.id == "obj_si_arm" }
        #expect(armObj?.kind == .armToAngle)
        #expect(armObj?.targetAngle == 90)
        #expect(m.objectives.filter { $0.isRequired }.count == 2)
    }

    @Test("mission_shelf_inspection — sensor-loop solution scores 30 pts and succeeds")
    func shelfInspectionSuccess() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_shelf_inspection"))
        // Start: (120,20) heading north. shelf_1 south face at y=130.
        // distance() returns 130-y when heading north at x=120 (in shelf_1 x-range 90-150).
        // Loop exits when distance()=20 → robot y=110. arm.moveTo(90) completes inspection.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        while (distance() > 20) {
            drive.forward(5);
        }
        arm.moveTo(90);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "Sensor-loop solution should succeed; failure=\(run.missionResult?.failureReason ?? "none")")
        #expect(run.missionResult?.score == 30,
                "Expected 30 pts (18+12), got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_si_standoff") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_si_arm") == true)
        let finalPos = run.finalSnapshot?.pose.position
        #expect(abs((finalPos?.x ?? -1) - 120) <= 1,
                "Robot should end at x≈120; got \(finalPos?.x ?? -1)")
        #expect(abs((finalPos?.y ?? -1) - 110) <= 1,
                "Robot should end at y≈110; got \(finalPos?.y ?? -1)")
        #expect(abs((run.finalSnapshot?.armAngle ?? -1) - 90) <= 5,
                "Arm should be at 90°")
    }

    @Test("mission_shelf_inspection — short blind drive fails reachPose")
    func shelfInspectionBlindDriveFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_shelf_inspection"))
        // drive.forward(50) → robot at y=70. Distance to target (120,110) = 40 > 15.
        // reachPose fails; armToAngle also not attempted → score=0, fail.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0)
        )
        let run = sim.run(program: "drive.forward(50);", world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "Short blind drive should not reach standoff zone — reachPose fails")
        #expect(run.missionResult?.score == 0,
                "Expected 0 pts; got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_si_standoff") == false)
    }

    @Test("mission_shelf_inspection — correct position but wrong arm angle fails armToAngle")
    func shelfInspectionWrongArmFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_shelf_inspection"))
        // Approach correctly but raise arm to 45° (not 90°) — |45-90|=45>5 → armToAngle fails.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0)
        )
        let program = """
        while (distance() > 20) {
            drive.forward(5);
        }
        arm.moveTo(45);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "Wrong arm angle (45°, not 90°) should fail armToAngle objective")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_si_standoff") == true,
                "Standoff reached via sensor loop should still score")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_si_arm") == false,
                "arm at 45° is 45° away from 90° — outside 5° tolerance")
        #expect(run.missionResult?.score == 18,
                "Expected 18 pts for standoff only; got \(run.missionResult?.score ?? -1)")
    }

    // =========================================================================
    // MARK: - Mission 7: mission_track_finder  (diff 4, 40 pts)
    // =========================================================================
    //
    // Line-sensor loop drives robot north from (120,20) until the right-side
    // sensor detects the east fork of the guide line (guide_line_east, y=120
    // horizontal segment, x:120-170). Then calls color.isRed() to log a sensor
    // event inside color_sensor_zone (x:80-120, y:80-120, red_tile overlay).
    //
    // lineRight() geometry (heading north, right sensor at x+12 = 132):
    //   guide_line_east segment from (120,120)→(170,120): horizontal at y=120.
    //   Sensor (132,y): distance to segment = |y-120| (since x=132∈[120,170]).
    //   Fires when |y-120| ≤ 1.5; first triggered at robot y=120 (step 20).
    //   Loop exits. Robot at (120,120).
    //
    // color.isRed() at (120,120):
    //   color_sensor_zone: x:80-120,y:80-120. (120,120): x=120≤120 ✓, y=120≤120 ✓. Inside.
    //   red_tile: x:80-120,y:80-120. colorAtPosition(120,120) = "red". ✓
    //   detectColorInZone obj_tf_scan satisfied (required, 10 pts).
    //
    // Post-scan route to crate_A (60,180):
    //   turnLeft(90) → west; forward(60) → (60,120); turnRight(90) → north;
    //   forward(60) → (60,180); arm.lower(); gripper.close() [picks crate_A] ✓; arm.raise()
    //
    // Without deposit: obj_tf_scan (10) + obj_tf_pickup (18) = 28 pts.
    //   allRequiredAndScore(26): scan required ✓; 28≥26 ✓. Success.
    //
    // With deposit: drive south from (60,180) to (60,20), gripper.open() → depot_red ✓.
    //   Score = 40 pts.
    //
    // maxActions=45. With scan+pickup: ~28 actions (62%). With deposit: ~31 (69%).
    //
    // Negative: scan only (10 pts, required met but 10 < 26 threshold) → fail.

    @Test("mission_track_finder — loads with correct metadata")
    func trackFinderLoads() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_track_finder"))
        #expect(m.difficulty == 4)
        #expect(m.totalPossiblePoints == 40)
        #expect(m.maxActions == 45)
        #expect(m.objectives.count == 3)
        let required = m.objectives.filter { $0.isRequired }
        #expect(required.count == 1, "Only scan obj is required")
        #expect(required.first?.id == "obj_tf_scan")
        let scanObj = m.objectives.first { $0.id == "obj_tf_scan" }
        #expect(scanObj?.kind == .detectColorInZone)
        #expect(scanObj?.targetZoneId == "color_sensor_zone")
        #expect(scanObj?.expectedColor == "red")
        let depositObj = m.objectives.first { $0.id == "obj_tf_deposit" }
        #expect(depositObj?.targetZoneId == "depot_red")
        #expect(depositObj?.targetItemId == "crate_A")
    }

    @Test("mission_track_finder — line-loop + scan + pickup scores 28 pts")
    func trackFinderScanAndPickup() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_track_finder"))
        // while loop drives north to y=120 (right sensor hits guide_line_east junction).
        // color.isRed() at (120,120): inside color_sensor_zone (x:80-120,y:80-120) → red. ✓
        // Then goes west+north to crate_A at (60,180) and picks it up.
        // Required scan met (10 pts) + pickup (18 pts) = 28 pts ≥ 26 threshold → success.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        while (!lineRight()) {
            drive.forward(5);
        }
        color.isRed();
        drive.turnLeft(90);
        drive.forward(60);
        drive.turnRight(90);
        drive.forward(60);
        arm.lower();
        gripper.close();
        arm.raise();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "Scan + pickup (28 pts ≥ 26 threshold) should succeed; failure=\(run.missionResult?.failureReason ?? "none")")
        #expect(run.missionResult?.score == 28,
                "Expected 28 pts (10+18); got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_tf_scan") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_tf_pickup") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_tf_deposit") == false)
    }

    @Test("mission_track_finder — full solution with deposit scores 40 pts")
    func trackFinderFullScore() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_track_finder"))
        // Full run: line-loop north → scan → go to crate_A → pick up → deposit in depot_red.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        while (!lineRight()) {
            drive.forward(5);
        }
        color.isRed();
        drive.turnLeft(90);
        drive.forward(60);
        drive.turnRight(90);
        drive.forward(60);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.turnRight(180);
        drive.forward(160);
        gripper.open();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "Full solution should succeed; failure=\(run.missionResult?.failureReason ?? "none")")
        #expect(run.missionResult?.score == 40,
                "Expected 40 pts, got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_tf_scan") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_tf_pickup") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_tf_deposit") == true)
        // Verify robot ended inside depot_red (x:10-60, y:10-60)
        let finalPos = run.finalSnapshot?.pose.position
        #expect((finalPos?.x ?? -1) >= 10 && (finalPos?.x ?? -1) <= 60,
                "Final x should be in depot_red x-range")
        #expect((finalPos?.y ?? -1) >= 10 && (finalPos?.y ?? -1) <= 60,
                "Final y should be in depot_red y-range")
    }

    @Test("mission_track_finder — scan only (10 pts) fails allRequiredAndScore(26) threshold")
    func trackFinderScanOnlyFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_track_finder"))
        // Scan required objective met (10 pts) but below the 26-pt score threshold → fail.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0)
        )
        let program = """
        while (!lineRight()) {
            drive.forward(5);
        }
        color.isRed();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "Scan alone (10 pts) is below the 26-pt threshold — should fail")
        #expect(run.missionResult?.score == 10,
                "Expected 10 pts for scan only; got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_tf_scan") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_tf_pickup") == false)
    }

    // =========================================================================
    // MARK: - Mission 8: mission_gap_gambit  (diff 4, 40 pts)
    // =========================================================================
    //
    // Retrieve cell_1 (170,130) from the E/W gap (x:150-190) between shelf_1 and shelf_2.
    // Route: S-shaped path via the x=185 N-S corridor → west into gap → north to cell.
    // footprintRadius=10 (tight-gap test; the 40-cm E/W gap provides 20cm clearance either side).
    //
    // Approach geometry (heading north at x=185, then west to x=170, then north to y=130):
    //   x=185 N-S corridor: east of rack_1/2 (x≤180), west of shelf_2 (x≥190). Clear full height.
    //   At y=120 heading west to x=170: probe (x-10,120). rack_2 y:50-115 (120>115) ✓.
    //   At x=170 heading north to y=130: probe (170,y+10). shelf_1/2 x not in 170 range ✓.
    //
    // Exit geometry (fp=10, heading south from y=130):
    //   From y=130 heading south: probe (170,120). rack_2 top y=115 (120>115) ✓.
    //   Drive south 4cm to y=126: probe (170,116). Still above rack_2. ✓
    //   Turn east, forward 15 → (185,126). probe (195,126). shelf_2 y:130-150 (126<130) ✓.
    //   Turn south, forward 106 → (185,20). Corridor clear. ✓
    //   Turn east, forward 20 → (205,20). Deposit in depot_blue ✓.
    //
    // scoreThreshold(28): pickup(18)+deposit(15)=33≥28 → success.
    // With home return: 33+7=40 pts.
    // maxActions=35. Canonical without home: 21 actions (60%). With home: 23 actions (66%).
    //
    // Negative: skipping exit south step (drive.forward(4)) → robot at (170,130) turns east
    //   immediately; probe (180,130) — rack_1 x:160-180, y:155-230 — y=130<155 → CLEAR
    //   actually. Let probe be (170+10,130)=(180,130). rack_1: y=130<155. shelf_2: x=180<190. Clear.
    //   Hm — the tighter negative: drive straight north instead of S-path → hits rack_2 probe.

    @Test("mission_gap_gambit — loads with correct metadata")
    func gapGambitLoads() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_gap_gambit"))
        #expect(m.difficulty == 4)
        #expect(m.totalPossiblePoints == 40)
        #expect(m.maxActions == 35)
        #expect(m.objectives.count == 3)
        // scoreThreshold — no required objectives
        #expect(m.objectives.filter { $0.isRequired }.count == 0)
        let pickupObj = m.objectives.first { $0.id == "obj_gg_pickup" }
        #expect(pickupObj?.targetItemId == "cell_1")
        let depositObj = m.objectives.first { $0.id == "obj_gg_deposit" }
        #expect(depositObj?.targetZoneId == "depot_blue")
    }

    @Test("mission_gap_gambit — canonical S-path solution scores 33 pts (pickup+deposit)")
    func gapGambitPickupAndDeposit() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_gap_gambit"))
        // Start: (120,20) heading north. footprintRadius=10.
        // S-path: east to x=185 corridor → north to y=120 → west to x=170 → north to y=130.
        // Exit: south 4cm to y=126 → east to x=185 → south to y=20 → east 20cm → deposit in depot_blue.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true,
            footprintRadius: 10
        )
        let program = """
        drive.turnRight(90);
        drive.forward(65);
        drive.turnLeft(90);
        drive.forward(100);
        drive.turnLeft(90);
        drive.forward(15);
        drive.turnRight(90);
        drive.forward(10);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.turnRight(180);
        drive.forward(4);
        drive.turnLeft(90);
        drive.forward(15);
        drive.turnRight(90);
        drive.forward(106);
        drive.turnLeft(90);
        drive.forward(20);
        gripper.open();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "S-path solution should succeed; failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 33,
                "Expected 33 pts (18+15); got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_gg_pickup") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_gg_deposit") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_gg_home") == false)
    }

    @Test("mission_gap_gambit — full solution with home return scores 40 pts")
    func gapGambitFullScore() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_gap_gambit"))
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true,
            footprintRadius: 10
        )
        let program = """
        drive.turnRight(90);
        drive.forward(65);
        drive.turnLeft(90);
        drive.forward(100);
        drive.turnLeft(90);
        drive.forward(15);
        drive.turnRight(90);
        drive.forward(10);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.turnRight(180);
        drive.forward(4);
        drive.turnLeft(90);
        drive.forward(15);
        drive.turnRight(90);
        drive.forward(106);
        drive.turnLeft(90);
        drive.forward(20);
        gripper.open();
        drive.turnRight(180);
        drive.forward(85);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "Full solution should succeed; failure=\(run.missionResult?.failureReason ?? "none")")
        #expect(run.missionResult?.score == 40,
                "Expected 40 pts (18+15+7); got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_gg_home") == true)
        let finalPos = run.finalSnapshot?.pose.position
        #expect((finalPos?.x ?? -1) >= 95 && (finalPos?.x ?? -1) <= 145,
                "Final x should be in home_base x-range (95-145)")
        #expect((finalPos?.y ?? -1) >= 5 && (finalPos?.y ?? -1) <= 35,
                "Final y should be in home_base y-range (5-35)")
    }

    @Test("mission_gap_gambit — drive straight north hits rack_2 and fails")
    func gapGambitStraightNorthFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_gap_gambit"))
        // Naive attempt: start at (170,20), drive straight north toward cell_1.
        // At x=170, rack_2 (x:160-180, y:50-115) blocks the path.
        // With fp=10, probe (170,y+10) enters rack_2 when robot y+10 ∈ [50,115]
        // i.e., robot y = 40 → probe y=50 → collision. Run terminates with collision.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 170, y: 20), headingDegrees: 0),
            footprintRadius: 10
        )
        let run = sim.run(program: "drive.forward(150);",
                           world: w, robot: robot, mission: m)
        #expect(run.failureKind != nil,
                "Straight-north drive at x=170 should collide with rack_2")
        if case let .collision(obsId) = run.failureKind {
            #expect(obsId == "rack_2", "Expected collision with rack_2, got \(obsId)")
        }
        #expect(run.missionResult?.success == false,
                "Collision run cannot satisfy pickup objective")
        #expect(run.missionResult?.score == 0)
    }

    // =========================================================================
    // MARK: - Mission 9: mission_night_shift  (diff 4, 40 pts)
    // =========================================================================
    //
    // barrel_3 at (205,210) — deep south-east pocket, east of rack_1 (x:160-180)
    // and south of shelf_2 (y:130-150 at x:190-240).
    // The only north-south corridor to the pocket: x=185 (between rack_1 east
    // edge x=180 and shelf_2 west edge x=190). Clearance = 5 cm each side.
    //
    // Two viable strategies share the same x=185 corridor but differ in HOW the
    // robot finds it:
    //
    // Strategy A — wall-reference (reliable):
    //   Drive east to near the east wall (wallAhead stops the robot at x≈215),
    //   step west 30 cm to x=185, then navigate the corridor north.
    //   No fixed east-distance needed — wall-square kills accumulated error.
    //   Actions: 1+1+7(loop)+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1 ≈ 22
    //   Score: pickup(16) + deposit(18) = 34 pts ≥ 26 → success (no home).
    //
    // Strategy B — dead-reckoning + home bonus (efficient):
    //   drive east exactly 65 cm → x=185, drive north 190 cm, east 20 cm,
    //   pick up, return via west and north to depot_green, then return home.
    //   Actions: 22 total.  Score: 16+18+6 = 40 pts ≥ 26 → success.
    //
    // Obstacle clearances (both strategies, x=185 corridor):
    //   rack_1   x:160-180 → x=185 > 180 ✓
    //   shelf_2  x:190-240 → x=185 < 190 ✓
    //   rack_2   x:160-180 → x=185 > 180 ✓  (all y values)
    //   West run at y=20: rack_2 y:50-115 → y=20 < 50 ✓
    //   North at x=45: shelf_1 x:90-150 → x=45 < 90 ✓
    //
    // Negative: pickup only (no deposit) → 16 < 26 → fail.
    //
    // maxActions=40.  A: 22/40=55 %.  B: 22/40=55 %.

    @Test("mission_night_shift — loads with correct metadata")
    func nightShiftLoads() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_night_shift"))
        #expect(m.difficulty == 4)
        #expect(m.totalPossiblePoints == 40)
        #expect(m.maxActions == 40)
        #expect(m.objectives.count == 3)
        #expect(m.objectives.filter { $0.isRequired }.count == 0)
        let scoreRule: Bool
        if case .scoreThreshold(let t) = m.successRule { scoreRule = (t == 26) } else { scoreRule = false }
        #expect(scoreRule, "successRule should be scoreThreshold(26)")
        #expect(m.objectives.first { $0.id == "obj_ns_pickup" }?.targetItemId == "barrel_3")
        #expect(m.objectives.first { $0.id == "obj_ns_deposit" }?.targetZoneId == "depot_green")
    }

    @Test("mission_night_shift — strategy A: wall-reference route scores 34 pts")
    func nightShiftStrategyA() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_night_shift"))
        // Start: (120,20) heading north.
        // Drive east 60 cm → (180,20); loop forward(5) until wallAhead() (7 iterations → x=215).
        // Step west 30 → (185,20).  North 190 → (185,210).  East 20 → (205,210): barrel_3.
        // arm.lower / gripper.close / arm.raise.
        // Return via same corridor: west 20, south 190, then west 140 to x=45, north 185 to (45,205).
        // gripper.open() at (45,205): depot_green x:10-60, y:180-230 ✓.
        // Total 22 actions; no home return. Score 16+18=34 ≥ 26 → success.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        // Drive east 90 cm first to get close to wall, then let the wall-reference
        // loop do a short final approach (2 iterations of forward(5) → stops at x=220),
        // then step west 35 cm to land at x=185, the safe corridor.
        let program = """
        drive.turnRight(90);
        drive.forward(90);
        while (!wallAhead()) {
            drive.forward(5);
        }
        drive.turnRight(180);
        drive.forward(35);
        drive.turnRight(90);
        drive.forward(190);
        drive.turnRight(90);
        drive.forward(20);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.turnRight(180);
        drive.forward(20);
        drive.turnLeft(90);
        drive.forward(190);
        drive.turnRight(90);
        drive.forward(140);
        drive.turnRight(90);
        drive.forward(185);
        gripper.open();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "Wall-reference strategy A should succeed (34 pts ≥ 26); failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 34,
                "Expected 34 pts (16+18); got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ns_pickup") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ns_deposit") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ns_home") == false)
    }

    @Test("mission_night_shift — strategy B: dead-reckoning + home scores 40 pts")
    func nightShiftStrategyB() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_night_shift"))
        // Start: (120,20) heading north.
        // East 65 → (185,20).  North 190 → (185,210).  East 20 → (205,210): barrel_3.
        // arm.lower / gripper.close / arm.raise.
        // West 20 → (185,210).  South 190 → (185,20).  West 125 → (60,20).
        // North 185 → (60,205).  gripper.open() in depot_green ✓.
        // South 185 → (60,20).  East 60 → (120,20): home_base ✓.
        // Total 22 actions (10 drive + 3 arm + 9 drive + gripper pair).
        // Score: 16+18+6 = 40 pts → success.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnRight(90);
        drive.forward(65);
        drive.turnLeft(90);
        drive.forward(190);
        drive.turnRight(90);
        drive.forward(20);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.turnRight(180);
        drive.forward(20);
        drive.turnLeft(90);
        drive.forward(190);
        drive.turnRight(90);
        drive.forward(125);
        drive.turnRight(90);
        drive.forward(185);
        gripper.open();
        drive.turnRight(180);
        drive.forward(185);
        drive.turnLeft(90);
        drive.forward(60);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "Dead-reckoning + home strategy B should succeed (40 pts ≥ 26); failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 40,
                "Expected 40 pts (16+18+6); got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ns_pickup") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ns_deposit") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ns_home") == true)
        let finalPos = run.finalSnapshot?.pose.position
        #expect((finalPos?.x ?? -1) >= 95 && (finalPos?.x ?? -1) <= 145,
                "Final x should be in home_base x-range")
        #expect((finalPos?.y ?? -1) >= 5 && (finalPos?.y ?? -1) <= 35,
                "Final y should be in home_base y-range")
    }

    @Test("mission_night_shift — pickup only (no deposit) scores 16 pts and fails")
    func nightShiftPickupOnlyFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_night_shift"))
        // Position robot at barrel_3, pick it up but do not deposit it.
        // 16 pts < 26 threshold → fail.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 205, y: 210), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        arm.lower();
        gripper.close();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "Pickup without deposit (16 pts) is below 26 threshold — should fail")
        #expect(run.missionResult?.score == 16,
                "Expected 16 pts for pickup only; got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ns_pickup") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ns_deposit") == false)
    }

    // =========================================================================
    // MARK: - Mission 10: mission_clear_the_lane  (diff 4, 40 pts)
    // =========================================================================
    //
    // crate_B (120,180) sits in the lane at the same northing as crate_A (60,180).
    // Carrying one item at a time forces a choice: clear crate_B first (route
    // through the x=155 corridor, deliver to depot_blue, then fetch crate_A),
    // or skip crate_B and take the short direct route to crate_A.
    //
    // Field layout reminder:
    //   shelf_1  x:90-150, y:130-150  — blocks direct north drive at x=120
    //   rack_2   x:160-180, y:50-115  — corridor constraint
    //   depot_blue  x:180-230, y:10-60
    //   depot_red   x:10-60,   y:10-60
    //   home_base   x:95-145,  y:5-35
    //
    // Strategy A — clear then fetch (score 34 pts):
    //   1. From (120,20): east 35 → (155,20); north 160 → (155,180); west 35 → (120,180).
    //   2. arm.lower / gripper.close / arm.raise: picks crate_B.
    //   3. West 31 → (89,180); south 160 → (89,20); east 111 → (200,20).
    //      gripper.open() at (200,20) in depot_blue ✓.
    //   4. West 140 → (60,20); north 160 → (60,180); east 5 ...
    //      Actually approach direct: west 145 → (55,20); north 160 → (55,180);
    //      east 5 → (60,180); arm.lower / gripper.close / arm.raise: picks crate_A.
    //   5. South 160 → (60,20); gripper.open() in depot_red ✓.
    //   Total 27 actions. Score: 10+12+12 = 34 pts ≥ 26 → success.
    //
    //   Obstacle clearances:
    //     North at x=155: shelf_1 x:90-150 (155>150 ✓); rack_2 x:160-180 (155<160 ✓).
    //     South at x=89: shelf_1 x:90-150 (89<90 ✓).
    //     East at y=20: rack_2 y:50-115 (20<50 ✓).
    //     North at x=55: shelf_1 x:90-150 (55<90 ✓).
    //
    // Strategy B — skip crate_B, fetch crate_A + home (score 30 pts):
    //   1. West 60 → (60,20); north 160 → (60,180): picks crate_A.
    //   2. South 160 → (60,20): deposits in depot_red ✓.
    //   3. East 60 → (120,20): home_base ✓.
    //   Total 12 actions. Score: 12+12+6 = 30 pts ≥ 26 → success.
    //
    // Negative: crate_B only → 10 pts < 26 → fail.
    //
    // maxActions=40.  A: 27/40=67.5 %.  B: 12/40=30 %.

    @Test("mission_clear_the_lane — loads with correct metadata")
    func clearTheLaneLoads() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_clear_the_lane"))
        #expect(m.difficulty == 4)
        #expect(m.totalPossiblePoints == 40)
        #expect(m.maxActions == 40)
        #expect(m.objectives.count == 4)
        #expect(m.objectives.filter { $0.isRequired }.count == 0)
        let scoreRule: Bool
        if case .scoreThreshold(let t) = m.successRule { scoreRule = (t == 26) } else { scoreRule = false }
        #expect(scoreRule, "successRule should be scoreThreshold(26)")
        #expect(m.objectives.first { $0.id == "obj_cl_relocate" }?.targetZoneId == "depot_blue")
        #expect(m.objectives.first { $0.id == "obj_cl_deposit_a" }?.targetZoneId == "depot_red")
    }

    @Test("mission_clear_the_lane — strategy A: clear crate_B then fetch crate_A scores 34 pts")
    func clearTheLaneStrategyA() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_clear_the_lane"))
        // Start: (120,20) heading north.
        // Phase 1: reach crate_B via x=155 detour (east of shelf_1, west of rack_2).
        //   east 35 → (155,20); north 160 → (155,180); west 35 → (120,180).
        //   arm.lower; gripper.close → crate_B. arm.raise.
        // Phase 2: deliver crate_B to depot_blue.
        //   west 31 → (89,180) [just west of shelf_1 left edge x=90];
        //   south 160 → (89,20); east 111 → (200,20); gripper.open → depot_blue ✓.
        // Phase 3: fetch crate_A at (60,180) → depot_red.
        //   west 145 → (55,20); north 160 → (55,180); east 5 → (60,180).
        //   arm.lower; gripper.close → crate_A. arm.raise.
        //   south 160 → (60,20); gripper.open → depot_red ✓.
        // Score: 10 (relocate) + 12 (pickup_a) + 12 (deposit_a) = 34 ≥ 26 → success.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnRight(90);
        drive.forward(35);
        drive.turnLeft(90);
        drive.forward(160);
        drive.turnLeft(90);
        drive.forward(35);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.forward(31);
        drive.turnLeft(90);
        drive.forward(160);
        drive.turnLeft(90);
        drive.forward(111);
        gripper.open();
        drive.turnRight(180);
        drive.forward(145);
        drive.turnRight(90);
        drive.forward(160);
        drive.turnRight(90);
        drive.forward(5);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.turnRight(90);
        drive.forward(160);
        gripper.open();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "Clear-then-fetch strategy A should succeed (34 pts ≥ 26); failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 34,
                "Expected 34 pts (10+12+12); got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_cl_relocate") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_cl_pickup_a") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_cl_deposit_a") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_cl_home") == false)
    }

    @Test("mission_clear_the_lane — strategy B: skip crate_B, fetch crate_A + home scores 30 pts")
    func clearTheLaneStrategyB() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_clear_the_lane"))
        // Start: (120,20) heading north.
        // Skip crate_B entirely. West 60 → (60,20); north 160 → (60,180).
        // arm.lower; gripper.close → crate_A. arm.raise.
        // south 160 → (60,20); gripper.open → depot_red ✓.
        // east 60 → (120,20): home_base (x:95-145, y:5-35) ✓.
        // Score: 12 (pickup_a) + 12 (deposit_a) + 6 (home) = 30 ≥ 26 → success.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnLeft(90);
        drive.forward(60);
        drive.turnRight(90);
        drive.forward(160);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.turnRight(180);
        drive.forward(160);
        gripper.open();
        drive.turnLeft(90);
        drive.forward(60);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "Skip-crate-B strategy B should succeed (30 pts ≥ 26); failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 30,
                "Expected 30 pts (12+12+6); got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_cl_relocate") == false)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_cl_pickup_a") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_cl_deposit_a") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_cl_home") == true)
        let finalPos = run.finalSnapshot?.pose.position
        #expect((finalPos?.x ?? -1) >= 95 && (finalPos?.x ?? -1) <= 145,
                "Final x should be in home_base x-range; got \(finalPos?.x ?? -1)")
        #expect((finalPos?.y ?? -1) >= 5 && (finalPos?.y ?? -1) <= 35,
                "Final y should be in home_base y-range; got \(finalPos?.y ?? -1)")
    }

    @Test("mission_clear_the_lane — crate_B only (10 pts) fails scoreThreshold(26)")
    func clearTheLaneCrateBOnlyFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_clear_the_lane"))
        // Place robot at (155,20) heading north — x=155 corridor (east of shelf_1
        // right edge x=150, west of rack_2 left edge x=160) is clear all the way north.
        // Drive north 160 → (155,180), west 35 → (120,180): crate_B.
        // Pick up crate_B. Return south via same x=155 corridor. Deposit in depot_blue.
        // Score: 10 pts only (no crate_A touched) — far below 26 threshold → fail.
        // Start at (155,20) heading north — x=155 corridor is clear of all obstacles.
        // north 160→(155,180); west 35→(120,180): crate_B.  arm.lower/close/raise.
        // Heading is now west (270°). turnLeft(90)→south(180°); north 160 from (120,...)
        // would hit shelf_1, so instead: east 35→(155,180); south 160→(155,20);
        // east 50→(205,20): depot_blue (x:180-230,y:10-60). gripper.open.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 155, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.forward(160);
        drive.turnLeft(90);
        drive.forward(35);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.turnRight(180);
        drive.forward(35);
        drive.turnRight(90);
        drive.forward(160);
        drive.turnLeft(90);
        drive.forward(50);
        gripper.open();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "crate_B only (10 pts) is below 26 threshold — should fail")
        #expect(run.missionResult?.score == 10,
                "Expected 10 pts for relocate only; got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_cl_relocate") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_cl_pickup_a") == false)
    }

    // =========================================================================
    // MARK: - Mission 11: mission_triple_manifest  (diff 5, 50 pts)
    // =========================================================================
    //
    // Three jobs; pick the portfolio that reaches 33 pts.
    // Total available: barrel_3 delivery (12+14=26) + crate_A delivery (8+7=15)
    //                + east detection (5) + home (4) = 50 pts.
    //
    // Strategy A — barrel_3 delivery + crate_A delivery (41 pts, 27 actions):
    //   barrel_3 at (205,210) → depot_green via x=185 corridor.
    //   After deposit at (45,205): east 15 → (60,205); south 25 → (60,180): crate_A.
    //   arm.lower/gripper.close/arm.raise; south 160 → (60,20); gripper.open → depot_red ✓.
    //
    // Strategy B — barrel_3 delivery + detection_east + home (35 pts, 29 actions):
    //   After barrel_3 deposit at (45,205): south 185 → (45,20); east 165 → (210,20);
    //   north 65 → (210,85): inside detection_east (x:185-230,y:55-95). color.isBlue() ✓.
    //   south 65 → (210,20); west 90 → (120,20): home_base ✓.
    //
    // Obstacle clearances (unique to these strategies):
    //   barrel_3 route: x=185 corridor — verified in Night Shift above.
    //   crate_A approach at x=60: shelf_1 x:90-150 (60<90 ✓). ✓
    //   East at y=20: rack_2 y:50-115 (y=20<50 ✓). ✓
    //   North to (210,85): rack_2 x:160-180 (210>180 ✓); shelf_2 y:130-150 (85<130 ✓). ✓
    //
    // Negative: barrel_3 delivery only (26 pts) < 33 → fail.
    //
    // maxActions=42.  A: 27/42=64 %.  B: 29/42=69 %.

    @Test("mission_triple_manifest — loads with correct metadata")
    func tripleManifestLoads() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_triple_manifest"))
        #expect(m.difficulty == 5)
        #expect(m.totalPossiblePoints == 50)
        #expect(m.maxActions == 42)
        #expect(m.objectives.count == 6)
        #expect(m.objectives.filter { $0.isRequired }.count == 0)
        let scoreRule: Bool
        if case .scoreThreshold(let t) = m.successRule { scoreRule = (t == 33) } else { scoreRule = false }
        #expect(scoreRule, "successRule should be scoreThreshold(33)")
        #expect(m.objectives.first { $0.id == "obj_tm_pickup_b3" }?.targetItemId == "barrel_3")
        #expect(m.objectives.first { $0.id == "obj_tm_deposit_b3" }?.targetZoneId == "depot_green")
        #expect(m.objectives.first { $0.id == "obj_tm_detect" }?.expectedColor == "blue")
    }

    @Test("mission_triple_manifest — strategy A: both deliveries scores 41 pts")
    func tripleManifestStrategyA() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_triple_manifest"))
        // Start: (120,20) heading north.
        // Phase 1: barrel_3 (205,210) → depot_green via x=185 corridor.
        //   east 65→(185,20); north 190→(185,210); east 20→(205,210).
        //   arm.lower; gripper.close; arm.raise.
        //   west 20→(185,210); south 190→(185,20); west 140→(45,20); north 185→(45,205).
        //   gripper.open → depot_green ✓.
        // Phase 2: crate_A (60,180) → depot_red.
        //   east 15→(60,205); south 25→(60,180).
        //   arm.lower; gripper.close; arm.raise.
        //   south 160→(60,20); gripper.open → depot_red (x:10-60,y:10-60) ✓.
        // Score: 12+14+8+7 = 41 ≥ 33 → success.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnRight(90);
        drive.forward(65);
        drive.turnLeft(90);
        drive.forward(190);
        drive.turnRight(90);
        drive.forward(20);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.turnRight(180);
        drive.forward(20);
        drive.turnLeft(90);
        drive.forward(190);
        drive.turnRight(90);
        drive.forward(140);
        drive.turnRight(90);
        drive.forward(185);
        gripper.open();
        drive.turnRight(90);
        drive.forward(15);
        drive.turnRight(90);
        drive.forward(25);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.forward(160);
        gripper.open();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "Both-deliveries strategy A should succeed (41 pts ≥ 33); failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 41,
                "Expected 41 pts (12+14+8+7); got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_tm_pickup_b3") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_tm_deposit_b3") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_tm_pickup_a") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_tm_deposit_a") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_tm_detect") == false)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_tm_home") == false)
    }

    @Test("mission_triple_manifest — strategy B: barrel_3 delivery + detection + home scores 35 pts")
    func tripleManifestStrategyB() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_triple_manifest"))
        // Start: (120,20) heading north.
        // Phase 1: barrel_3 → depot_green (same 18 actions as strategy A, ending at (45,205) north).
        // Phase 2: go to detection_east.
        //   south 185→(45,20); east 165→(210,20); north 65→(210,85).
        //   (210,85) inside detection_east (x:185-230,y:55-95) ✓ and blue_tile ✓.
        //   color.isBlue() → detects "blue" ✓.
        // Phase 3: return to home_base.
        //   south 65→(210,20); west 90→(120,20): home_base ✓.
        // Score: 12+14+5+4 = 35 ≥ 33 → success.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnRight(90);
        drive.forward(65);
        drive.turnLeft(90);
        drive.forward(190);
        drive.turnRight(90);
        drive.forward(20);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.turnRight(180);
        drive.forward(20);
        drive.turnLeft(90);
        drive.forward(190);
        drive.turnRight(90);
        drive.forward(140);
        drive.turnRight(90);
        drive.forward(185);
        gripper.open();
        drive.turnRight(180);
        drive.forward(185);
        drive.turnLeft(90);
        drive.forward(165);
        drive.turnLeft(90);
        drive.forward(65);
        color.isBlue();
        drive.turnRight(180);
        drive.forward(65);
        drive.turnRight(90);
        drive.forward(90);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "barrel_3+detection+home strategy B should succeed (35 pts ≥ 33); failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 35,
                "Expected 35 pts (12+14+5+4); got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_tm_pickup_b3") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_tm_deposit_b3") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_tm_detect") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_tm_home") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_tm_pickup_a") == false)
        let finalPos = run.finalSnapshot?.pose.position
        #expect((finalPos?.x ?? -1) >= 95 && (finalPos?.x ?? -1) <= 145,
                "Final x should be in home_base x-range; got \(finalPos?.x ?? -1)")
        #expect((finalPos?.y ?? -1) >= 5 && (finalPos?.y ?? -1) <= 35,
                "Final y should be in home_base y-range; got \(finalPos?.y ?? -1)")
    }

    @Test("mission_triple_manifest — barrel_3 delivery only (26 pts) fails scoreThreshold(33)")
    func tripleManifestBarrel3OnlyFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_triple_manifest"))
        // barrel_3 pickup (12) + deposit (14) = 26 pts < 33 → fail.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnRight(90);
        drive.forward(65);
        drive.turnLeft(90);
        drive.forward(190);
        drive.turnRight(90);
        drive.forward(20);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.turnRight(180);
        drive.forward(20);
        drive.turnLeft(90);
        drive.forward(190);
        drive.turnRight(90);
        drive.forward(140);
        drive.turnRight(90);
        drive.forward(185);
        gripper.open();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "barrel_3 delivery only (26 pts) is below 33 threshold — should fail")
        #expect(run.missionResult?.score == 26,
                "Expected 26 pts (12+14); got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_tm_pickup_b3") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_tm_deposit_b3") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_tm_pickup_a") == false)
    }

    // =========================================================================
    // MARK: - Mission 12: mission_grand_circuit  (diff 5, 50 pts)
    // =========================================================================
    //
    // The season finale — four skills in one run, two finishing options.
    // crate_C is at (210,75), conveniently inside detection_east/blue_tile, but
    // that's the EAST detection.  The RED detection is at color_sensor_zone
    // (x:80-120,y:80-120) + red_tile (same rect) — robot must visit there first.
    //
    // Key insight: from (120,100) inside color_sensor_zone, going north to y=120
    // then east to x=210 then south to y=75 reaches crate_C in ~5 moves.
    // Then straight south to depot_blue, then home_base or precision standoff.
    //
    // Strategy A — detect + pickup + deposit + home (40 pts, 14 actions):
    //   north 80→(120,100): color_sensor_zone ✓; color.isRed() ✓.
    //   north 20→(120,120); east 90→(210,120); south 45→(210,75): crate_C.
    //   arm.lower/gripper.close/arm.raise.
    //   south 55→(210,20): depot_blue ✓. gripper.open.
    //   west 90→(120,20): home_base ✓.
    //   Score: 8+10+12+10 = 40 ≥ 33 → success.
    //
    //   Obstacle clearances:
    //     North at x=120 to y=120: shelf_1 y:130-150 (y=120<130 ✓).
    //     East at y=120: rack_2 y:50-115 (y=120>115 ✓); rack_1 y:155-230 (y=120<155 ✓);
    //                    shelf_2 y:130-150 (y=120<130 ✓). ALL CLEAR.
    //     South at x=210 from y=120→75: rack_2 x:160-180 (210>180 ✓). ✓
    //     South at x=210 from y=75→20: same. ✓
    //     West at y=20: rack_2 y:50-115 (y=20<50 ✓). ✓
    //
    // Strategy B — detect + pickup + deposit + precision (40 pts, 17 actions):
    //   Steps 1-12 identical to A.  Instead of going home:
    //   west 90→(120,20); north 90→(120,110): reachPose (120,110) toleranceCm=12 ✓.
    //   Score: 8+10+12+10 = 40 ≥ 33 → success.
    //
    // Negative: detect + home only (8+10=18 pts) < 33 → fail.
    //
    // maxActions=25.  A: 14/25=56 %.  B: 17/25=68 %.
    // The func-based canonical is the natural "approach" pattern:
    //   func scanAndPickup() { north, color.isRed(), north, east, south, arm, grip }

    @Test("mission_grand_circuit — loads with correct metadata")
    func grandCircuitLoads() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_grand_circuit"))
        #expect(m.difficulty == 5)
        #expect(m.totalPossiblePoints == 50)
        #expect(m.maxActions == 25)
        #expect(m.objectives.count == 5)
        #expect(m.objectives.filter { $0.isRequired }.count == 0)
        let scoreRule: Bool
        if case .scoreThreshold(let t) = m.successRule { scoreRule = (t == 33) } else { scoreRule = false }
        #expect(scoreRule, "successRule should be scoreThreshold(33)")
        let detectObj = m.objectives.first { $0.id == "obj_gc_detect" }
        #expect(detectObj?.targetZoneId == "color_sensor_zone")
        #expect(detectObj?.expectedColor == "red")
        let precisionObj = m.objectives.first { $0.id == "obj_gc_precision" }
        #expect(precisionObj?.targetX == 120)
        #expect(precisionObj?.targetY == 110)
        #expect(precisionObj?.toleranceCm == 12)
    }

    @Test("mission_grand_circuit — strategy A: detect + pickup + deposit + home scores 40 pts")
    func grandCircuitStrategyA() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_grand_circuit"))
        // Start: (120,20) heading north.
        // north 80 → (120,100): inside color_sensor_zone (x:80-120,y:80-120) ✓.
        // color.isRed() → red_tile at (120,100) reads "red" ✓.
        // north 20 → (120,120); east 90 → (210,120); south 45 → (210,75): crate_C.
        //   obstacle check east at y=120: rack_2 y:50-115 (120>115 ✓); shelf_2 y:130-150 (120<130 ✓). ✓
        // arm.lower; gripper.close → crate_C. arm.raise.
        // south 55 → (210,20): depot_blue (x:180-230,y:10-60) ✓. gripper.open.
        // west 90 → (120,20): home_base (x:95-145,y:5-35) ✓.
        // 14 actions total (well within maxActions=25).
        // Score: 8+10+12+10 = 40 ≥ 33 → success.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.forward(80);
        color.isRed();
        drive.forward(20);
        drive.turnRight(90);
        drive.forward(90);
        drive.turnRight(90);
        drive.forward(45);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.forward(55);
        gripper.open();
        drive.turnRight(90);
        drive.forward(90);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "detect+pickup+deposit+home strategy A should succeed (40 pts ≥ 33); failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 40,
                "Expected 40 pts (8+10+12+10); got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_gc_detect") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_gc_pickup") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_gc_deposit") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_gc_home") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_gc_precision") == false)
        let finalPos = run.finalSnapshot?.pose.position
        #expect((finalPos?.x ?? -1) >= 95 && (finalPos?.x ?? -1) <= 145,
                "Final x should be in home_base x-range; got \(finalPos?.x ?? -1)")
        #expect((finalPos?.y ?? -1) >= 5 && (finalPos?.y ?? -1) <= 35,
                "Final y should be in home_base y-range; got \(finalPos?.y ?? -1)")
    }

    @Test("mission_grand_circuit — strategy B: detect + pickup + deposit + precision scores 40 pts")
    func grandCircuitStrategyB() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_grand_circuit"))
        // Same first 11 actions as strategy A (detect, pickup, deposit at depot_blue).
        // Then instead of driving west to home_base:
        //   west 90 → (120,20); north 90 → (120,110).
        //   reachPose (120,110) toleranceCm=12: dist=0 ≤ 12 ✓.
        //   At x=120, north from y=20: shelf_1 y:130-150 (y=110<130 ✓). ✓
        // 17 actions total.
        // Score: 8+10+12+10 = 40 ≥ 33 → success.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.forward(80);
        color.isRed();
        drive.forward(20);
        drive.turnRight(90);
        drive.forward(90);
        drive.turnRight(90);
        drive.forward(45);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.forward(55);
        gripper.open();
        drive.turnRight(90);
        drive.forward(90);
        drive.turnRight(90);
        drive.forward(90);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "detect+pickup+deposit+precision strategy B should succeed (40 pts ≥ 33); failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 40,
                "Expected 40 pts (8+10+12+10); got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_gc_detect") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_gc_pickup") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_gc_deposit") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_gc_precision") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_gc_home") == false)
        let finalPos = run.finalSnapshot?.pose.position
        #expect(abs((finalPos?.x ?? -1) - 120) <= 1,
                "Final x should be ≈120; got \(finalPos?.x ?? -1)")
        #expect(abs((finalPos?.y ?? -1) - 110) <= 1,
                "Final y should be ≈110; got \(finalPos?.y ?? -1)")
    }

    @Test("mission_grand_circuit — detect + home only (18 pts) fails scoreThreshold(33)")
    func grandCircuitDetectAndHomeOnlyFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_grand_circuit"))
        // Detect red at color_sensor_zone then go straight to home_base.
        // No pickup or deposit. Score: 8 (detect) + 10 (home) = 18 < 33 → fail.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.forward(80);
        color.isRed();
        drive.turnRight(180);
        drive.forward(80);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "detect+home only (18 pts) is below 33 threshold — should fail")
        #expect(run.missionResult?.score == 18,
                "Expected 18 pts (8+10); got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_gc_detect") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_gc_home") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_gc_pickup") == false)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_gc_deposit") == false)
    }
}
