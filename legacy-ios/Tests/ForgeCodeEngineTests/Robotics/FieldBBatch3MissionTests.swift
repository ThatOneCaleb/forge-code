import Testing
@testable import ForgeCodeEngine

/// End-to-end tests for the four Batch-3 missions on the Mars Outpost field
/// (field_arena, 300×300 cm).
///
/// Field layout quick-reference (heading 0°=north=+Y, CW-positive):
///   Obstacles
///     boulder_W       x:100-114, y:128-198
///     boulder_N       x:114-178, y:184-198
///     boulder_S       x:114-178, y:126-140
///     crater_rim      x:38-102,  y:154-168
///     boulder_scatter x:168-190, y:62-84
///   Key zones
///     launch_pad      x:120-180, y:268-295   (goal)
///     base_camp       x:108-192, y:8-50      (goal)
///     beacon_pad      x:10-65,   y:50-105    (detection)
///     solar_pad       x:220-280, y:45-100    (detection)
///     bay_beta        x:233-295, y:228-290   (deposit, core)
///     relay_station   x:5-45,    y:168-213   (deposit, cell)
///   Key items
///     rock_beta  (235,218) blue/sample,  pickupRadius 14
///     core_delta (150,162) green/core,   pickupRadius 14  — INSIDE boulder ring
///     rock_omega (30,35)   red/sample,   pickupRadius 14
///   Colored regions
///     solar_tile   x:220-280, y:45-100   yellow
///     beacon_tile  x:10-65,   y:50-105   orange
///
/// East-gap geometry (ring entry):
///   Gap spans x>178, y:140-184 (height 44 cm).
///   Gap centre y = 162 (= core_delta y).
///   With footprintRadius 18: clearance from boulder_S (y=140) = 162-140=22 > 18 ✓
///                             clearance from boulder_N (y=184) = 184-162=22 > 18 ✓
@Suite("Batch-3 Mars Outpost missions (blue-courier, core-extraction, rockslide-detour, dark-side-survey)")
struct FieldBBatch3MissionTests {

    // MARK: - Shared helpers

    private func world() throws -> FieldWorld {
        try #require(try RoboticsLibrary.field(id: "field_arena"))
    }

    private let sim = RoboticsSimulator()

    // =========================================================================
    // MARK: - Mission 9: mission_blue_courier  (diff 3, 30 pts)
    // =========================================================================
    //
    // rock_beta at (235,218); bay_beta: x:233-295, y:228-290, deposit.
    // Optional bonus: detectColorInZone solar_pad "yellow" (5 pts).
    //
    // Strategy A (east corridor with solar bonus):
    //   Start (150,20) heading north.
    //   1. turnRight(90)  → east (90°)
    //   2. forward(85)    → (235,20)   [scatter y:62-84, y=20<62 ✓]
    //   3. turnLeft(90)   → north (0°)
    //   4. forward(52)    → (235,72)   [scatter x:168-190, x=235>190 ✓; solar_pad ✓]
    //   5. color()        → "yellow" from solar_tile ✓; detectColorInZone solar_pad ✓
    //   6. forward(146)   → (235,218)  [= rock_beta; boulder_S/N x:114-178, x=235>178 ✓]
    //   7. arm.lower(); gripper.close() → pick rock_beta ✓
    //   8. arm.raise()
    //   9. forward(22)    → (235,240)  [bay_beta x:233-295, y:228-290 ✓]
    //  10. gripper.open() → deposit rock_beta in bay_beta ✓
    //   Score: 10(pickup)+15(deposit)+5(solar)=30 pts. allRequired (pickup+deposit) ✓.
    //
    // Strategy B (west approach, no bonus):
    //   Start (150,20) heading north.
    //   1. turnLeft(90)   → west (270°)
    //   2. forward(115)   → (35,20)    [x=35<38: crater_rim x-range clear ✓]
    //   3. turnRight(90)  → north (0°) [270+90=360=0°]
    //   4. forward(200)   → (35,220)   [x=35<38: crater_rim y:154-168 clear ✓]
    //   5. turnRight(90)  → east (90°)
    //   6. forward(200)   → (235,220)  [y=220>198: above all ring obstacles ✓; rock_beta dist=2≤14 ✓]
    //   7. arm.lower(); gripper.close() → pick rock_beta ✓
    //   8. arm.raise()
    //   9. turnLeft(90)   → north (0°) [90-90=0°]
    //  10. forward(10)    → (235,230)  [bay_beta ✓]
    //  11. gripper.open() → deposit ✓
    //   Score: 10+15=25 pts. allRequired ✓ (no solar bonus).
    //
    // Negative: pickup without deposit (rock held, not deposited).
    //
    // Objectives:
    //   obj_bc_pickup  pickUpItem rock_beta                10 pts  required
    //   obj_bc_deposit depositItemInZone bay_beta          15 pts  required
    //   obj_bc_solar   detectColorInZone solar_pad yellow   5 pts  optional
    //   Total = 30 pts. successRule: allRequired.

    @Test("mission_blue_courier — loads with correct metadata")
    func blueCourierLoads() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_blue_courier"))
        #expect(m.difficulty == 3)
        #expect(m.totalPossiblePoints == 30)
        #expect(m.objectives.count == 3)
        #expect(m.objectives.filter { $0.isRequired }.count == 2)
        let pickup = m.objectives.first { $0.kind == .pickUpItem }
        #expect(pickup?.targetItemId == "rock_beta")
        #expect(pickup?.isRequired == true)
        let deposit = m.objectives.first { $0.kind == .depositItemInZone }
        #expect(deposit?.targetItemId == "rock_beta")
        #expect(deposit?.targetZoneId == "bay_beta")
        #expect(deposit?.isRequired == true)
        let solar = m.objectives.first { $0.kind == .detectColorInZone }
        #expect(solar?.targetZoneId == "solar_pad")
        #expect(solar?.expectedColor == "yellow")
        #expect(solar?.isRequired == false)
        #expect(m.fieldId == "field_arena")
    }

    @Test("mission_blue_courier — Strategy A (east corridor + solar bonus) scores 30 pts and succeeds")
    func blueCourierStrategyA() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_blue_courier"))
        // Start (150,20) heading north.
        // East 85 → (235,20); north 52 → (235,72): inside solar_pad (x:220-280, y:45-100).
        // color() → "yellow" from solar_tile ✓.
        // north 146 → (235,218): rock_beta (dist=0). Pick up.
        // north 22 → (235,240): inside bay_beta (x:233-295, y:228-290). Deposit.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnRight(90);
        drive.forward(85);
        drive.turnLeft(90);
        drive.forward(52);
        color();
        drive.forward(146);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.forward(22);
        gripper.open();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "East corridor + solar bonus should succeed; failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 30,
                "Expected 30 pts (10+15+5), got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_bc_pickup") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_bc_deposit") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_bc_solar") == true)
        // Confirm final position inside bay_beta (x:233-295, y:228-290)
        let finalPos = run.finalSnapshot?.pose.position
        #expect((finalPos?.x ?? 0) >= 233 && (finalPos?.x ?? 0) <= 295,
                "Final x \(finalPos?.x ?? -1) should be in bay_beta x-range 233-295")
        #expect((finalPos?.y ?? 0) >= 228 && (finalPos?.y ?? 0) <= 290,
                "Final y \(finalPos?.y ?? -1) should be in bay_beta y-range 228-290")
    }

    @Test("mission_blue_courier — Strategy B (west approach, no bonus) scores 25 pts and succeeds")
    func blueCourierStrategyB() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_blue_courier"))
        // Start (150,20) heading north.
        // West 115 → (35,20): x=35<38, west of crater_rim x-range.
        // North 200 → (35,220): x=35<38, crater_rim (y:154-168) x-range clear.
        // East 200 → (235,220): y=220>198, above all ring obstacles. rock_beta dist=2≤14.
        // Turn north, forward 10 → (235,230): inside bay_beta. Deposit.
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
        drive.forward(200);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.turnLeft(90);
        drive.forward(10);
        gripper.open();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "West approach should succeed; failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 25,
                "Expected 25 pts (10+15, no solar bonus), got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_bc_pickup") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_bc_deposit") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_bc_solar") == false)
    }

    @Test("mission_blue_courier — pickup without deposit scores 10 pts and fails allRequired")
    func blueCourierPickupOnlyFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_blue_courier"))
        // Start on rock_beta, pick it up, never deposit.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 235, y: 218), headingDegrees: 0),
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
        #expect(run.missionResult?.metObjectiveIds.contains("obj_bc_pickup") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_bc_deposit") == false)
    }

    @Test("mission_blue_courier — drive-only program scores 0 and fails")
    func blueCourierDriveOnlyFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_blue_courier"))
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
    // MARK: - Mission 10: mission_core_extraction  (diff 4, 40 pts)
    // =========================================================================
    //
    // core_delta at (150,162) — INSIDE the boulder ring.
    // East gap: x>178, y:140-184 (height 44 cm). Entry centre y=162.
    // footprintRadius 18 used in all tests for realistic collision geometry.
    //
    // Gap clearance at y=162 with footprintRadius=18:
    //   boulder_S bottom y=140: 162-140=22 > 18 ✓
    //   boulder_N top   y=184: 184-162=22 > 18 ✓
    //   boulder_W east  x=114: at center x=150, clearance=150-114=36 > 18 ✓
    //
    // Strategy A — dead-reckoning entry (deliver + no home, 35 pts):
    //   Start (150,20) heading north, footprintRadius=18.
    //   1.  turnRight(90)   → east (90°)
    //   2.  forward(105)    → (255,20)   [scatter y:62-84, y=20<62 ✓]
    //   3.  turnLeft(90)    → north (0°)
    //   4.  forward(142)    → (255,162)  [x=255>190: scatter clear; ring clear ✓]
    //   5.  turnLeft(90)    → west (270°)
    //   6.  forward(105)    → (150,162)  [gap y=162; leading_edge=(132,162): boulder_W x:100-114 (132>114 ✓)]
    //   7.  arm.lower(); gripper.close() → pick core_delta (dist=0≤14) ✓
    //   8.  arm.raise()
    //   9.  turnRight(180)  → east (90°) [270+180=450=90°]
    //  10.  forward(105)    → (255,162)  [exit east through gap; boulder_W is to the west ✓]
    //  11.  turnRight(90)   → south (180°)
    //  12.  forward(42)     → (255,120)  [y=120<126: south of boulder_S; x=255>178: clear ✓]
    //  13.  turnRight(90)   → west (270°)
    //  14.  forward(235)    → (20,120)   [y=120<128: below boulder_W y-range; y<154: crater_rim clear ✓]
    //  15.  turnRight(90)   → north (0°)
    //  16.  forward(80)     → (20,200)   [x=20<38: crater_rim x-range clear ✓; relay_station ✓]
    //  17.  gripper.open()  → deposit core_delta in relay_station ✓
    //   Score: 20(pickup)+15(deposit)=35 pts ≥ 26. Success!
    //
    // Strategy A extended (deliver + home, 40 pts):
    //   After step 17, continue:
    //  18.  turnRight(180)  → south (180°)
    //  19.  forward(180)    → (20,20)    [x=20<38: crater_rim clear ✓]
    //  20.  turnLeft(90)    → east (90°) [180-90=90°]
    //  21.  forward(130)    → (150,20)   [scatter y:62-84, y=20<62 ✓; base_camp ✓]
    //   Score: 20+15+5=40 pts. Success!
    //
    // Strategy B — distance()-gated entry (same delivery route, sensor technique):
    //   After reaching (255,162) heading west, approach core_delta using distance():
    //   while (distance() > 36) { drive.forward(3); }
    //   distance() west from (255,162) = 255-114 = 141 cm initially.
    //   Loop stops when distance() ≤ 36, i.e., robot center at x≈150 ✓.
    //   Then arm/gripper sequence and same exit route.
    //
    // Negative: straight-north approach collides with boulder_S.
    //   From (150,20) heading north, forward(90):
    //   center_y=110, leading_edge=(150,128): boulder_S x:114-178 ✓, y:126-140 (128∈✓). COLLISION.
    //
    // Objectives:
    //   obj_ce_pickup   pickUpItem core_delta              20 pts  optional
    //   obj_ce_deposit  depositItemInZone relay_station    15 pts  optional
    //   obj_ce_home     reachZone base_camp                 5 pts  optional
    //   Total = 40 pts. successRule: scoreThreshold 26.

    @Test("mission_core_extraction — loads with correct metadata")
    func coreExtractionLoads() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_core_extraction"))
        #expect(m.difficulty == 4)
        #expect(m.totalPossiblePoints == 40)
        #expect(m.objectives.count == 3)
        #expect(m.objectives.filter { $0.isRequired }.count == 0)
        let pickup = m.objectives.first { $0.kind == .pickUpItem }
        #expect(pickup?.targetItemId == "core_delta")
        #expect(pickup?.points == 20)
        let deposit = m.objectives.first { $0.kind == .depositItemInZone }
        #expect(deposit?.targetItemId == "core_delta")
        #expect(deposit?.targetZoneId == "relay_station")
        #expect(deposit?.points == 15)
        let home = m.objectives.first { $0.kind == .reachZone }
        #expect(home?.targetZoneId == "base_camp")
        #expect(home?.points == 5)
        #expect(m.fieldId == "field_arena")
        if case let .scoreThreshold(t) = m.successRule { #expect(t == 26) }
    }

    @Test("mission_core_extraction — Strategy A dead-reckoning entry (pickup+deposit=35 pts) succeeds")
    func coreExtractionStrategyA() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_core_extraction"))
        // footprintRadius=18 for realistic gap collision geometry.
        // Route: east to (255,20), north to (255,162), west through gap to (150,162).
        // Pick up core_delta. Turn east, exit gap to (255,162).
        // South to (255,120) below boulder_S, west to (20,120) below crater_rim,
        // north to (20,200) inside relay_station. Deposit.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true,
            footprintRadius: 18
        )
        let program = """
        drive.turnRight(90);
        drive.forward(105);
        drive.turnLeft(90);
        drive.forward(142);
        drive.turnLeft(90);
        drive.forward(105);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.turnRight(180);
        drive.forward(105);
        drive.turnRight(90);
        drive.forward(42);
        drive.turnRight(90);
        drive.forward(235);
        drive.turnRight(90);
        drive.forward(80);
        gripper.open();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "Dead-reckoning entry + delivery should succeed; failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 35,
                "Expected 35 pts (20+15), got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ce_pickup") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ce_deposit") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ce_home") == false)
        // Confirm final position inside relay_station (x:5-45, y:168-213)
        let finalPos = run.finalSnapshot?.pose.position
        #expect((finalPos?.x ?? 0) >= 5 && (finalPos?.x ?? 0) <= 45,
                "Final x \(finalPos?.x ?? -1) should be in relay_station x-range 5-45")
        #expect((finalPos?.y ?? 0) >= 168 && (finalPos?.y ?? 0) <= 213,
                "Final y \(finalPos?.y ?? -1) should be in relay_station y-range 168-213")
    }

    @Test("mission_core_extraction — Strategy A extended (pickup+deposit+home=40 pts) succeeds")
    func coreExtractionStrategyAWithHome() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_core_extraction"))
        // Same as Strategy A but continues after deposit to return to base_camp.
        // After deposit at (20,200): south 180 → (20,20); east 130 → (150,20) = base_camp.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true,
            footprintRadius: 18
        )
        let program = """
        drive.turnRight(90);
        drive.forward(105);
        drive.turnLeft(90);
        drive.forward(142);
        drive.turnLeft(90);
        drive.forward(105);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.turnRight(180);
        drive.forward(105);
        drive.turnRight(90);
        drive.forward(42);
        drive.turnRight(90);
        drive.forward(235);
        drive.turnRight(90);
        drive.forward(80);
        gripper.open();
        drive.turnRight(180);
        drive.forward(180);
        drive.turnLeft(90);
        drive.forward(130);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "Full run with home return should succeed; failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 40,
                "Expected 40 pts (20+15+5), got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ce_pickup") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ce_deposit") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ce_home") == true)
        // Confirm final position inside base_camp (x:108-192, y:8-50)
        let finalPos = run.finalSnapshot?.pose.position
        #expect((finalPos?.x ?? 0) >= 108 && (finalPos?.x ?? 0) <= 192,
                "Final x \(finalPos?.x ?? -1) should be in base_camp x-range 108-192")
        #expect((finalPos?.y ?? 0) >= 8 && (finalPos?.y ?? 0) <= 50,
                "Final y \(finalPos?.y ?? -1) should be in base_camp y-range 8-50")
    }

    @Test("mission_core_extraction — Strategy B distance()-gated ring entry scores 35 pts and succeeds")
    func coreExtractionStrategyB() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_core_extraction"))
        // Strategy B: use distance() sensor to gauge ring depth instead of fixed cm.
        // At (255,162) heading west: distance() = 255-114 = 141 cm to boulder_W.
        // while (distance() > 36) { drive.forward(3); } stops at x≈150 (dist=36 = 150-114).
        // Same exit and delivery route as Strategy A.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true,
            footprintRadius: 18
        )
        let program = """
        drive.turnRight(90);
        drive.forward(105);
        drive.turnLeft(90);
        drive.forward(142);
        drive.turnLeft(90);
        while (distance() > 36) { drive.forward(3); }
        arm.lower();
        gripper.close();
        arm.raise();
        drive.turnRight(180);
        drive.forward(105);
        drive.turnRight(90);
        drive.forward(42);
        drive.turnRight(90);
        drive.forward(235);
        drive.turnRight(90);
        drive.forward(80);
        gripper.open();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "Distance-gated entry should succeed; failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 35,
                "Expected 35 pts (20+15), got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ce_pickup") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ce_deposit") == true)
    }

    @Test("mission_core_extraction — straight-north approach collides with boulder_S")
    func coreExtractionStraightNorthCollides() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_core_extraction"))
        // Robot at (150,20) heading north. forward(90) → center_y=110.
        // Leading edge = (150, 110+18) = (150, 128). boulder_S x:114-178 ✓, y:126-140 ✓. COLLISION.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0),
            footprintRadius: 18
        )
        let run = sim.run(program: "drive.forward(90);",
                          world: w, robot: robot, mission: m)
        #expect(run.failureKind != nil,
                "Straight north approach should collide with boulder_S")
        if case let .collision(obsId) = run.failureKind {
            #expect(obsId == "boulder_S", "Expected boulder_S collision, got \(obsId)")
        }
        #expect(run.missionResult?.success == false)
    }

    @Test("mission_core_extraction — pickup only (no deposit) scores 20 pts and fails threshold")
    func coreExtractionPickupOnlyFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_core_extraction"))
        // Start at east gap entrance, enter ring, pick up core_delta, never deposit.
        // 20 pts < 26 threshold → fails.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 255, y: 162), headingDegrees: 270),
            armAngle: 0, isGripperOpen: true,
            footprintRadius: 18
        )
        let program = """
        drive.forward(105);
        arm.lower();
        gripper.close();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "Pickup without deposit should not reach 26-pt threshold")
        #expect(run.missionResult?.score == 20,
                "Should score 20 pts for pickup only; got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ce_pickup") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ce_deposit") == false)
    }

    // =========================================================================
    // MARK: - Mission 11: mission_rockslide_detour  (diff 4, 40 pts, maxActions 30)
    // =========================================================================
    //
    // The main north track (x=150) passes through boulder_S (y:126-140) and
    // boulder_N (y:184-198) — a straight-north drive collides with boulder_S.
    // Objective: reach launch_pad; bonus points from solar_pad or beacon_pad.
    //
    // Strategy A (east route, solar bonus, 32 pts):
    //   Start (150,20) heading north.
    //   1. turnRight(90) → east (90°)
    //   2. forward(85)   → (235,20)   [scatter y:62-84, y=20<62 ✓]
    //   3. turnLeft(90)  → north (0°)
    //   4. forward(52)   → (235,72)   [solar_pad x:220-280, y:45-100 ✓; scatter x:168-190, x=235>190 ✓]
    //   5. color()       → "yellow" from solar_tile ✓
    //   6. forward(203)  → (235,275)  [all obstacles x:114-178, x=235>178 ✓]
    //   7. turnLeft(90)  → west (270°)
    //   8. forward(85)   → (150,275)  [launch_pad x:120-180 ✓, y:268-295 ✓]
    //   Score: solar(12)+launch(20)=32 pts ≥ 26. Actions: 7 (color free). 7/30=23% ✓.
    //
    // Strategy B (west route, beacon bonus, 28 pts):
    //   Start (150,20) heading north.
    //   1. turnLeft(90)   → west (270°)
    //   2. forward(110)   → (40,20)    [scatter y<62 ✓]
    //   3. turnRight(90)  → north (0°) [270+90=360=0°]
    //   4. forward(55)    → (40,75)    [beacon_pad x:10-65, y:50-105 ✓; crater_rim y:154-168, y=75<154 ✓]
    //   5. color()        → "orange" from beacon_tile ✓
    //   6. turnRight(180) → south (180°)
    //   7. forward(55)    → (40,20)
    //   8. turnLeft(90)   → east (90°) [180-90=90°]
    //   9. forward(195)   → (235,20)   [scatter y:62-84, y=20<62 ✓]
    //  10. turnLeft(90)   → north (0°)
    //  11. forward(255)   → (235,275)  [x=235>190: scatter clear; ring clear ✓]
    //  12. turnLeft(90)   → west (270°)
    //  13. forward(85)    → (150,275)  [launch_pad ✓]
    //   Score: beacon(8)+launch(20)=28 pts ≥ 26. Actions: 12. 12/30=40% ✓.
    //
    // Negative: straight north from (150,20) collides with boulder_S.
    //
    // Objectives:
    //   obj_rd2_launch  reachZone launch_pad                  20 pts  optional
    //   obj_rd2_solar   detectColorInZone solar_pad yellow     12 pts  optional
    //   obj_rd2_beacon  detectColorInZone beacon_pad orange     8 pts  optional
    //   Total = 40 pts. successRule: scoreThreshold 26. maxActions: 30.

    @Test("mission_rockslide_detour — loads with correct metadata")
    func rockslideDetourLoads() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_rockslide_detour"))
        #expect(m.difficulty == 4)
        #expect(m.totalPossiblePoints == 40)
        #expect(m.objectives.count == 3)
        #expect(m.objectives.filter { $0.isRequired }.count == 0)
        #expect(m.maxActions == 30)
        let launch = m.objectives.first { $0.kind == .reachZone }
        #expect(launch?.targetZoneId == "launch_pad")
        #expect(launch?.points == 20)
        let solar = m.objectives.first { $0.id == "obj_rd2_solar" }
        #expect(solar?.targetZoneId == "solar_pad")
        #expect(solar?.expectedColor == "yellow")
        let beacon = m.objectives.first { $0.id == "obj_rd2_beacon" }
        #expect(beacon?.targetZoneId == "beacon_pad")
        #expect(beacon?.expectedColor == "orange")
        #expect(m.fieldId == "field_arena")
        if case let .scoreThreshold(t) = m.successRule { #expect(t == 26) }
    }

    @Test("mission_rockslide_detour — Strategy A (east route + solar) scores 32 pts and succeeds")
    func rockslideDetourStrategyA() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_rockslide_detour"))
        // East to (235,20), north to (235,72): solar detect.
        // North to (235,275), west to (150,275): inside launch_pad.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnRight(90);
        drive.forward(85);
        drive.turnLeft(90);
        drive.forward(52);
        color();
        drive.forward(203);
        drive.turnLeft(90);
        drive.forward(85);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "East route + solar should succeed; failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 32,
                "Expected 32 pts (20+12), got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_rd2_launch") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_rd2_solar") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_rd2_beacon") == false)
        // Confirm final position inside launch_pad (x:120-180, y:268-295)
        let finalPos = run.finalSnapshot?.pose.position
        #expect((finalPos?.x ?? 0) >= 120 && (finalPos?.x ?? 0) <= 180,
                "Final x \(finalPos?.x ?? -1) should be in launch_pad x-range 120-180")
        #expect((finalPos?.y ?? 0) >= 268 && (finalPos?.y ?? 0) <= 295,
                "Final y \(finalPos?.y ?? -1) should be in launch_pad y-range 268-295")
    }

    @Test("mission_rockslide_detour — Strategy B (west route + beacon) scores 28 pts and succeeds")
    func rockslideDetourStrategyB() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_rockslide_detour"))
        // West to (40,20), north to (40,75): beacon detect.
        // South to (40,20), east to (235,20), north to (235,275), west to (150,275): launch_pad.
        // Must go south before east to avoid scatter (y:62-84) at y=75.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnLeft(90);
        drive.forward(110);
        drive.turnRight(90);
        drive.forward(55);
        color();
        drive.turnRight(180);
        drive.forward(55);
        drive.turnLeft(90);
        drive.forward(195);
        drive.turnLeft(90);
        drive.forward(255);
        drive.turnLeft(90);
        drive.forward(85);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "West route + beacon should succeed; failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 28,
                "Expected 28 pts (20+8), got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_rd2_launch") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_rd2_beacon") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_rd2_solar") == false)
    }

    @Test("mission_rockslide_detour — straight-north drive collides with boulder_S and fails")
    func rockslideDetourStraightNorthCollides() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_rockslide_detour"))
        // Drive straight north at x=150 with default footprintRadius=0 (centre-point).
        // At center_y=126, the centre point enters boulder_S (x:114-178, y:126-140). COLLISION.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0)
        )
        let run = sim.run(program: "drive.forward(280);",
                          world: w, robot: robot, mission: m)
        #expect(run.failureKind != nil,
                "Straight north at x=150 should collide with boulder_S")
        if case let .collision(obsId) = run.failureKind {
            #expect(obsId == "boulder_S", "Expected boulder_S, got \(obsId)")
        }
        #expect(run.missionResult?.success == false)
    }

    @Test("mission_rockslide_detour — reaching launch_pad alone (20 pts) fails 26-pt threshold")
    func rockslideDetourLaunchOnlyFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_rockslide_detour"))
        // Reach launch_pad without any detection bonus: 20 pts < 26 → fails.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0)
        )
        let program = """
        drive.turnRight(90);
        drive.forward(85);
        drive.turnLeft(90);
        drive.forward(255);
        drive.turnLeft(90);
        drive.forward(85);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "Launch only (20 pts) should not reach 26-pt threshold")
        #expect(run.missionResult?.score == 20,
                "Should score 20 pts for launch only; got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_rd2_launch") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_rd2_solar") == false)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_rd2_beacon") == false)
    }

    // =========================================================================
    // MARK: - Mission 12: mission_dark_side_survey  (diff 4, 40 pts, maxActions 35)
    // =========================================================================
    //
    // Three optional science targets + required base_camp return.
    // Portfolio: base(6,required) + choose ≥18 pts from beacon(12), solar(12), rock(10).
    //
    // Portfolio options (all must include base_camp):
    //   beacon+solar+base = 30 ✓;  solar+rock+base = 28 ✓;  beacon+rock+base = 28 ✓
    //   Fail: solar+base=18 ✗;  beacon+base=18 ✗;  rock+base=16 ✗
    //
    // Strategy A (east-first sweep, solar+beacon+base, 30 pts):
    //   Start (150,20) heading north.
    //   1. turnRight(90)   → east (90°)
    //   2. forward(85)     → (235,20)   [scatter y:62-84, y=20<62 ✓]
    //   3. turnLeft(90)    → north (0°)
    //   4. forward(52)     → (235,72)   [solar_pad ✓; scatter x:168-190, x=235>190 ✓]
    //   5. color()         → "yellow" ✓; detectColorInZone solar_pad ✓
    //   6. turnRight(180)  → south (180°)
    //   7. forward(52)     → (235,20)
    //   8. turnRight(90)   → west (270°) [180+90=270°]
    //   9. forward(195)    → (40,20)    [scatter y:62-84, y=20<62 ✓]
    //  10. turnRight(90)   → north (0°) [270+90=360=0°]
    //  11. forward(55)     → (40,75)   [beacon_pad x:10-65, y:50-105 ✓; crater_rim y<154 ✓]
    //  12. color()         → "orange" ✓; detectColorInZone beacon_pad ✓
    //  13. turnRight(180)  → south (180°)
    //  14. forward(55)     → (40,20)
    //  15. turnLeft(90)    → east (90°) [180-90=90°]
    //  16. forward(110)    → (150,20)  [base_camp x:108-192, y:8-50 ✓]
    //   Score: solar(12)+beacon(12)+base(6)=30 ≥ 24. Actions: 14. 14/35=40% ✓.
    //
    // Strategy B (west-first, rock+beacon+solar+base, 40 pts):
    //   Start (150,20) heading north.
    //   1. turnLeft(90)    → west (270°)
    //   2. forward(120)    → (30,20)   [scatter y<62 ✓; x=30<38: crater_rim x-range clear ✓]
    //   3. turnRight(90)   → north (0°) [270+90=360=0°]
    //   4. forward(15)     → (30,35)   [= rock_omega (dist=0≤14); y=35<154: clear ✓]
    //   5. arm.lower(); gripper.close() → pick rock_omega ✓
    //   6. arm.raise()
    //   7. forward(40)     → (30,75)   [beacon_pad x:10-65, y:50-105 ✓; crater_rim y<154 ✓]
    //   8. color()         → "orange" from beacon_tile ✓
    //   9. turnRight(180)  → south (180°)
    //  10. forward(55)     → (30,20)
    //  11. turnLeft(90)    → east (90°) [180-90=90°]
    //  12. forward(205)    → (235,20)  [scatter y:62-84, y=20<62 ✓]
    //  13. turnLeft(90)    → north (0°) [90-90=0°]
    //  14. forward(52)     → (235,72)  [solar_pad ✓]
    //  15. color()         → "yellow" ✓
    //  16. turnRight(180)  → south (180°)
    //  17. forward(52)     → (235,20)
    //  18. turnRight(90)   → west (270°) [180+90=270°]
    //  19. forward(85)     → (150,20)  [base_camp ✓]
    //   Score: rock(10)+beacon(12)+solar(12)+base(6)=40. Actions: 18. 18/35=51% ✓.
    //
    // Negative: solar+base only (18 pts) fails allRequiredAndScore(24).
    //
    // Objectives:
    //   obj_dss_beacon  detectColorInZone beacon_pad orange  12 pts  optional
    //   obj_dss_solar   detectColorInZone solar_pad yellow   12 pts  optional
    //   obj_dss_rock    pickUpItem rock_omega                10 pts  optional
    //   obj_dss_home    reachZone base_camp                   6 pts  required
    //   Total = 40 pts. successRule: allRequiredAndScore 24. maxActions: 35.

    @Test("mission_dark_side_survey — loads with correct metadata")
    func darkSideSurveyLoads() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_dark_side_survey"))
        #expect(m.difficulty == 4)
        #expect(m.totalPossiblePoints == 40)
        #expect(m.objectives.count == 4)
        #expect(m.objectives.filter { $0.isRequired }.count == 1)
        #expect(m.maxActions == 35)
        let beaconObj = m.objectives.first { $0.id == "obj_dss_beacon" }
        #expect(beaconObj?.targetZoneId == "beacon_pad")
        #expect(beaconObj?.expectedColor == "orange")
        #expect(beaconObj?.isRequired == false)
        let solarObj = m.objectives.first { $0.id == "obj_dss_solar" }
        #expect(solarObj?.targetZoneId == "solar_pad")
        #expect(solarObj?.expectedColor == "yellow")
        #expect(solarObj?.isRequired == false)
        let rockObj = m.objectives.first { $0.id == "obj_dss_rock" }
        #expect(rockObj?.targetItemId == "rock_omega")
        #expect(rockObj?.isRequired == false)
        let homeObj = m.objectives.first { $0.kind == .reachZone }
        #expect(homeObj?.targetZoneId == "base_camp")
        #expect(homeObj?.isRequired == true)
        #expect(m.fieldId == "field_arena")
        if case let .allRequiredAndScore(t) = m.successRule { #expect(t == 24) }
    }

    @Test("mission_dark_side_survey — Strategy A (east-first, solar+beacon+base=30 pts) succeeds")
    func darkSideSurveyStrategyA() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_dark_side_survey"))
        // East to solar_pad, detect yellow, south, west to beacon_pad, detect orange,
        // south, east to base_camp. Score: solar(12)+beacon(12)+base(6)=30.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnRight(90);
        drive.forward(85);
        drive.turnLeft(90);
        drive.forward(52);
        color();
        drive.turnRight(180);
        drive.forward(52);
        drive.turnRight(90);
        drive.forward(195);
        drive.turnRight(90);
        drive.forward(55);
        color();
        drive.turnRight(180);
        drive.forward(55);
        drive.turnLeft(90);
        drive.forward(110);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "East-first sweep should succeed; failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 30,
                "Expected 30 pts (12+12+6), got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_dss_solar") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_dss_beacon") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_dss_rock") == false)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_dss_home") == true)
        // Confirm final position inside base_camp (x:108-192, y:8-50)
        let finalPos = run.finalSnapshot?.pose.position
        #expect((finalPos?.x ?? 0) >= 108 && (finalPos?.x ?? 0) <= 192,
                "Final x \(finalPos?.x ?? -1) should be in base_camp x-range 108-192")
        #expect((finalPos?.y ?? 0) >= 8 && (finalPos?.y ?? 0) <= 50,
                "Final y \(finalPos?.y ?? -1) should be in base_camp y-range 8-50")
    }

    @Test("mission_dark_side_survey — Strategy B (west-first, rock+beacon+solar+base=40 pts) succeeds")
    func darkSideSurveyStrategyB() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_dark_side_survey"))
        // West to rock_omega, pick up; north to beacon_pad, detect orange;
        // south, east to solar_pad, detect yellow; south, west to base_camp.
        // Score: rock(10)+beacon(12)+solar(12)+base(6)=40.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnLeft(90);
        drive.forward(120);
        drive.turnRight(90);
        drive.forward(15);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.forward(40);
        color();
        drive.turnRight(180);
        drive.forward(55);
        drive.turnLeft(90);
        drive.forward(205);
        drive.turnLeft(90);
        drive.forward(52);
        color();
        drive.turnRight(180);
        drive.forward(52);
        drive.turnRight(90);
        drive.forward(85);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "West-first sweep with rock pickup should succeed; failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 40,
                "Expected 40 pts (10+12+12+6), got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_dss_rock") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_dss_beacon") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_dss_solar") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_dss_home") == true)
    }

    @Test("mission_dark_side_survey — solar+base only (18 pts) fails allRequiredAndScore threshold")
    func darkSideSurveySolarOnlyFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_dark_side_survey"))
        // Detect solar, return to base_camp. Score: solar(12)+base(6)=18 < 24 → fails.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnRight(90);
        drive.forward(85);
        drive.turnLeft(90);
        drive.forward(52);
        color();
        drive.turnRight(180);
        drive.forward(52);
        drive.turnRight(90);
        drive.forward(85);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "Solar+base (18 pts) should not reach 24-pt threshold")
        #expect(run.missionResult?.score == 18,
                "Should score 18 pts (solar+base); got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_dss_solar") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_dss_home") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_dss_beacon") == false)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_dss_rock") == false)
    }

    @Test("mission_dark_side_survey — missing base_camp return fails allRequiredAndScore regardless of score")
    func darkSideSurveyNoHomeFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_dark_side_survey"))
        // Detect both pads (24 pts) but never return to base_camp (required) → fails.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnRight(90);
        drive.forward(85);
        drive.turnLeft(90);
        drive.forward(52);
        color();
        drive.turnRight(180);
        drive.forward(52);
        drive.turnRight(90);
        drive.forward(195);
        drive.turnRight(90);
        drive.forward(55);
        color();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "Missing base_camp (required) should fail even with 24 detection pts")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_dss_solar") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_dss_beacon") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_dss_home") == false)
    }
}
