import Testing
@testable import ForgeCodeEngine

/// End-to-end tests for the three Batch-4 missions on the Mars Outpost field
/// (field_arena, 300×300 cm).  These are the final three missions that complete
/// the 15-mission Field B ladder.
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
///     bay_alpha       x:5-67,    y:228-290   (deposit, sample)
///     bay_beta        x:233-295, y:228-290   (deposit, core)
///     relay_station   x:5-45,    y:168-213   (deposit, cell)
///     solar_pad       x:220-280, y:45-100    (detection)
///     beacon_pad      x:10-65,   y:50-105    (detection)
///   Key items
///     rock_alpha  (75,220)   red/sample,  pickupRadius 14
///     core_delta  (150,162)  green/core,  pickupRadius 14  — INSIDE boulder ring
///     core_zeta   (248,38)   blue/core,   pickupRadius 14
///     cell_ion    (255,152)  green/cell,  pickupRadius 14
///   Colored regions
///     solar_tile  x:220-280, y:45-100   yellow
///     beacon_tile x:10-65,   y:50-105   orange
///
/// East-gap geometry (ring entry, footprintRadius=18):
///   Gap spans x>178, y:140-184 (height 44 cm), centre y=162.
///   boulder_S southern face y=140: clearance 162-140=22 > 18 ✓
///   boulder_N northern face y=184: clearance 184-162=22 > 18 ✓
///   boulder_W eastern face  x=114: at center x=150, clearance=150-114=36 > 18 ✓
@Suite("Batch-4 Mars Outpost missions (precision-landing, sample-sort, grand-expedition)")
struct FieldBBatch4MissionTests {

    // MARK: - Shared helpers

    private func world() throws -> FieldWorld {
        try #require(try RoboticsLibrary.field(id: "field_arena"))
    }

    private let sim = RoboticsSimulator()

    // =========================================================================
    // MARK: - Mission 13: mission_precision_landing  (diff 4, 40 pts, maxActions 25)
    // =========================================================================
    //
    // The rover must FINISH within 10 cm of point (150,270) on the launch pad
    // AND end with arm at 30° (±5°).  An optional solar scan (+10 pts) is the
    // third-point source that lifts the run above the 26-pt threshold.
    //
    // reachPose target: (150,270), tol=10.  Launch_pad rect: x:120-180, y:268-295.
    //   (150,270) is inside launch_pad. Nearest "comfortable" finish: (150,275)
    //   → distance = 5 cm ≤ 10 ✓.
    //
    // Strategy A — east corridor + solar (score 40 pts):
    //   Start (150,20) heading north (0°).
    //   1. turnRight(90)  → east (90°)
    //   2. forward(85)    → (235,20)   [scatter y:62-84; y=20<62 ✓]
    //   3. turnLeft(90)   → north (0°) [90-90=0°]
    //   4. forward(52)    → (235,72)   [solar_pad x:220-280 (235∈✓), y:45-100 (72∈✓);
    //                                    scatter x:168-190: x=235>190 ✓]
    //   5. color()        → "yellow" from solar_tile; detectColorInZone solar_pad ✓ (+10)
    //   6. forward(203)   → (235,275)  [all ring obstacles x:114-178; x=235>178 ✓]
    //   7. turnLeft(90)   → west (270°) [0-90=-90=270°]
    //   8. forward(85)    → (150,275)  [y=275; launch_pad x:120-180 (150∈✓), y:268-295 (275∈✓) ✓;
    //                                    dist to (150,270) = |275-270| = 5 cm ≤ 10 ✓]
    //   9. arm.moveTo(30) → arm=30°   [|30-30|=0 ≤ 5° ✓]
    //   Score: land(20)+arm(10)+solar(10)=40 pts. Actions: 9. 9/25=36% ✓.
    //
    // Strategy B — west corridor, no solar (score 30 pts ≥ 26):
    //   Start (150,20) heading north (0°).
    //   1. turnLeft(90)   → west (270°)
    //   2. forward(115)   → (35,20)    [x=35<38: crater_rim x:38-102 west of range ✓]
    //   3. turnRight(90)  → north (0°) [270+90=360=0°]
    //   4. forward(255)   → (35,275)   [x=35<38: crater_rim y:154-168 clear ✓;
    //                                    boulder_W x:100-114: x=35<100 ✓]
    //   5. turnRight(90)  → east (90°) [0+90=90°]
    //   6. forward(115)   → (150,275)  [dist to (150,270)=5 ✓; launch_pad ✓]
    //   7. arm.moveTo(30) → arm=30°   ✓
    //   Score: land(20)+arm(10)=30 pts ≥ 26. Actions: 7. 7/25=28% ✓.
    //
    // Negative (arm bypass closed): east corridor + solar detect + land on mark, but arm stays at 0°.
    //   reachPose met (+20), solar met (+10) = 30 pts.  obj_pl_arm required but NOT met → success==false.
    //   Before the fix this scored 30 ≥ 26 and passed. After the fix it must fail.
    //
    // Objectives (total 40 pts, successRule: allRequiredAndScore 26):
    //   obj_pl_land   reachPose (150,270) tol=10   20 pts  optional
    //   obj_pl_arm    armToAngle 30°                10 pts  REQUIRED
    //   obj_pl_solar  detectColorInZone solar_pad   10 pts  optional

    @Test("mission_precision_landing — loads with correct metadata")
    func precisionLandingLoads() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_precision_landing"))
        #expect(m.difficulty == 4)
        #expect(m.totalPossiblePoints == 40)
        #expect(m.objectives.count == 3)
        // obj_pl_arm is now required — bypass fix
        #expect(m.objectives.filter { $0.isRequired }.count == 1)
        #expect(m.objectives.first { $0.id == "obj_pl_arm" }?.isRequired == true)
        #expect(m.maxActions == 25)
        let landObj = m.objectives.first { $0.id == "obj_pl_land" }
        #expect(landObj?.kind == .reachPose)
        #expect(landObj?.targetX == 150)
        #expect(landObj?.targetY == 270)
        #expect(landObj?.toleranceCm == 10)
        #expect(landObj?.points == 20)
        let armObj = m.objectives.first { $0.id == "obj_pl_arm" }
        #expect(armObj?.kind == .armToAngle)
        #expect(armObj?.targetAngle == 30)
        #expect(armObj?.points == 10)
        let solarObj = m.objectives.first { $0.id == "obj_pl_solar" }
        #expect(solarObj?.kind == .detectColorInZone)
        #expect(solarObj?.targetZoneId == "solar_pad")
        #expect(solarObj?.expectedColor == "yellow")
        #expect(solarObj?.points == 10)
        #expect(m.fieldId == "field_arena")
        // successRule is now allRequiredAndScore — bypass fix
        if case let .allRequiredAndScore(t) = m.successRule { #expect(t == 26) }
    }

    @Test("mission_precision_landing — Strategy A (east corridor + solar) scores 40 pts and succeeds")
    func precisionLandingStrategyA() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_precision_landing"))
        // East 85 → (235,20); north 52 → (235,72): solar_pad ✓, color() → "yellow".
        // North 203 → (235,275); west 85 → (150,275): launch_pad ✓.
        // dist to (150,270) = 5 cm ≤ 10 ✓.  arm.moveTo(30) ✓.
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
        arm.moveTo(30);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "East corridor + solar should succeed; failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 40,
                "Expected 40 pts (20+10+10), got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_pl_land") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_pl_arm") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_pl_solar") == true)
        // Confirm final position within 10 cm of (150,270)
        let finalPos = run.finalSnapshot?.pose.position ?? Vec2(x: -999, y: -999)
        let dist = finalPos.distance(to: Vec2(x: 150, y: 270))
        #expect(dist <= 10,
                "Final position (\(finalPos.x),\(finalPos.y)) should be within 10 cm of (150,270); dist=\(dist)")
        // Confirm arm angle within 5° of 30°
        let armAngle = run.finalSnapshot?.armAngle ?? -1
        #expect(abs(armAngle - 30) <= 5,
                "Arm angle \(armAngle) should be within 5° of 30°")
    }

    @Test("mission_precision_landing — Strategy B (west corridor, no solar) scores 30 pts and succeeds")
    func precisionLandingStrategyB() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_precision_landing"))
        // West 115 → (35,20): x=35<38 clears crater_rim ✓.
        // North 255 → (35,275): x=35<38, clears crater_rim (y:154-168) ✓.
        // East 115 → (150,275): launch_pad ✓, dist to (150,270) = 5 ✓.
        // arm.moveTo(30) ✓.  Score: land(20)+arm(10) = 30 ≥ 26.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.turnLeft(90);
        drive.forward(115);
        drive.turnRight(90);
        drive.forward(255);
        drive.turnRight(90);
        drive.forward(115);
        arm.moveTo(30);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "West corridor should succeed; failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 30,
                "Expected 30 pts (20+10, no solar), got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_pl_land") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_pl_arm") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_pl_solar") == false)
        // Confirm precision
        let finalPos = run.finalSnapshot?.pose.position ?? Vec2(x: -999, y: -999)
        let dist = finalPos.distance(to: Vec2(x: 150, y: 270))
        #expect(dist <= 10,
                "West corridor final position (\(finalPos.x),\(finalPos.y)) should be within 10 cm of touchdown mark; dist=\(dist)")
    }

    @Test("mission_precision_landing — correct position but wrong arm angle (0°) scores 20 pts and fails threshold")
    func precisionLandingWrongArmFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_precision_landing"))
        // Reach (150,275) without calling arm.moveTo(30); arm stays at 0° (|0-30|=30 > 5°).
        // land(20) met, arm(10) not met → 20 pts < 26 → fails.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
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
                "Wrong arm angle (0°) should not reach 26-pt threshold")
        #expect(run.missionResult?.score == 20,
                "Should score 20 pts (land only); got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_pl_land") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_pl_arm") == false)
    }

    @Test("mission_precision_landing — arm correct but position off by 20 cm fails reachPose tolerance")
    func precisionLandingOffTargetFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_precision_landing"))
        // End at (170,275): dist to (150,270) = sqrt(20²+5²) ≈ 20.6 > 10 → reachPose fails.
        // arm.moveTo(30) earns 10 pts. No land objective → 10 pts < 26 → fails threshold.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        // Drive east a bit more so we end at x=170 (still inside launch_pad zone, but off the 10cm mark)
        let program = """
        drive.turnRight(90);
        drive.forward(85);
        drive.turnLeft(90);
        drive.forward(255);
        drive.turnLeft(90);
        drive.forward(65);
        arm.moveTo(30);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "Position 20 cm off target should fail reachPose and not reach 26-pt threshold")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_pl_land") == false,
                "20 cm off target should not satisfy 10 cm tolerance")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_pl_arm") == true,
                "Arm at 30° should still be met")
        #expect(run.missionResult?.score == 10,
                "Should score 10 pts (arm only); got \(run.missionResult?.score ?? -1)")
    }

    @Test("mission_precision_landing — arm bypass closed: solar + land without arm (30 pts) now fails")
    func precisionLandingArmBypassClosed() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_precision_landing"))
        // This test validates the BLOCKER fix: before the fix, obj_pl_arm was optional and
        // successRule was scoreThreshold(26), so solar(10)+land(20)=30 ≥ 26 passed with no arm.
        // After the fix, obj_pl_arm is required — the arm objective MUST be met.
        //
        // Route: east corridor + solar detect + finish on touchdown mark. Arm left at 0°.
        //   1. turnRight(90) → east (90°)
        //   2. forward(85)   → (235,20)  [scatter y:62-84, y=20<62 ✓]
        //   3. turnLeft(90)  → north (0°)
        //   4. forward(52)   → (235,72)  [solar_pad x:220-280, y:45-100 ✓]
        //   5. color()       → "yellow"  [detectColorInZone solar_pad ✓ (+10)]
        //   6. forward(203)  → (235,275) [x=235>178: all ring obstacles clear ✓]
        //   7. turnLeft(90)  → west (270°)
        //   8. forward(85)   → (150,275) [launch_pad x:120-180, y:268-295 ✓]
        //      dist to (150,270) = |275-270| = 5 cm ≤ 10 ✓  → obj_pl_land met (+20)
        //      arm stays at 0°  → obj_pl_arm NOT met (required)
        //   Score = solar(10)+land(20) = 30 pts, but allRequiredAndScore requires arm → success==false.
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
        #expect(run.missionResult?.success == false,
                "Solar + land without arm (30 pts) must fail because obj_pl_arm is required; score=\(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.score == 30,
                "Should accumulate 30 pts (solar 10 + land 20) but not succeed; got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_pl_solar") == true,
                "Solar objective should be met")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_pl_land") == true,
                "Land objective should be met")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_pl_arm") == false,
                "Arm objective must NOT be met (arm stayed at 0°)")
    }

    // =========================================================================
    // MARK: - Mission 14: mission_sample_sort  (diff 5, 50 pts, maxActions 40)
    // =========================================================================
    //
    // Three sorting pairs available (only two needed to hit threshold 33):
    //   Pair A: rock_alpha(75,220) → bay_alpha     = pickup(7)+deposit(10) = 17 pts
    //   Pair B: core_zeta(248,38)  → bay_beta      = pickup(7)+deposit(10) = 17 pts
    //   Pair C: cell_ion(255,152)  → relay_station = pickup(6)+deposit(10) = 16 pts
    //   Total = 50 pts. Threshold = 33.
    //   A+B=34 ✓, A+C=33 ✓, B+C=33 ✓.
    //
    // Strategy A — west-first order (Pair A then Pair B, 34 pts):
    //   Start (150,20) heading north (0°).
    //   1. turnLeft(90)   → west (270°)
    //   2. forward(115)   → (35,20)    [x=35<38: crater_rim clear ✓]
    //   3. turnRight(90)  → north (0°) [270+90=360=0°]
    //   4. forward(200)   → (35,220)   [x=35<38: crater_rim y:154-168 clear ✓]
    //   5. turnRight(90)  → east (90°) [0+90=90°]
    //   6. forward(40)    → (75,220)   = rock_alpha ✓
    //   7. arm.lower()
    //   8. gripper.close()  → pick rock_alpha (+7)
    //   9. arm.raise()
    //  10. turnRight(180)  → west (270°) [90+180=270°]
    //  11. forward(30)     → (45,220)   [bay_alpha x:5-67 (45∈✓)]
    //  12. turnRight(90)   → north (0°) [270+90=360=0°]
    //  13. forward(50)     → (45,270)   [bay_alpha y:228-290 (270∈✓) ✓]
    //  14. gripper.open()  → deposit rock_alpha in bay_alpha ✓ (+10)
    //      [now at (45,270) heading north (0°)]
    //  15. turnRight(90)   → east (90°) [0+90=90°]
    //  16. forward(203)    → (248,270)  [y=270>198: all ring/scatter obstacles clear ✓]
    //  17. turnRight(90)   → south (180°) [90+90=180°]
    //  18. forward(232)    → (248,38)   = core_zeta ✓ [x=248>190: scatter clear ✓]
    //  19. arm.lower()
    //  20. gripper.close()  → pick core_zeta (+7)
    //  21. arm.raise()
    //  22. turnRight(180)   → north (0°) [180+180=360=0°]
    //  23. forward(232)     → (248,270)  [bay_beta x:233-295 (248∈✓), y:228-290 (270∈✓) ✓]
    //  24. gripper.open()   → deposit core_zeta in bay_beta ✓ (+10)
    //   Score: rock_pickup(7)+bay_alpha(10)+core_pickup(7)+bay_beta(10) = 34 pts. Actions=24. 24/40=60% ✓.
    //
    // Strategy B — east-first order (Pair B then Pair A, 34 pts):
    //   Start (150,20) heading north (0°).
    //   1. turnRight(90)  → east (90°)
    //   2. forward(98)    → (248,20)   [y=20<62: scatter clear ✓]
    //   3. turnLeft(90)   → north (0°) [90-90=0°]
    //   4. forward(18)    → (248,38)   = core_zeta ✓ [x=248>190: scatter clear ✓]
    //   5. arm.lower()
    //   6. gripper.close()  → pick core_zeta (+7)
    //   7. arm.raise()
    //   8. forward(232)   → (248,270)  [bay_beta x:233-295 (248∈✓), y:228-290 (270∈✓) ✓]
    //   9. gripper.open()   → deposit core_zeta in bay_beta ✓ (+10)
    //      [now at (248,270) heading north (0°)]
    //  10. turnRight(180)  → south (180°) [0+180=180°]
    //  11. forward(50)     → (248,220)  [y=270-50=220; obstacles clear at x=248>190 ✓]
    //  12. turnRight(90)   → west (270°) [180+90=270°]
    //  13. forward(173)    → (75,220)   = rock_alpha ✓ [y=220>198: all ring obstacles clear ✓]
    //  14. arm.lower()
    //  15. gripper.close()  → pick rock_alpha (+7)
    //  16. arm.raise()
    //      [at (75,220) heading west (270°)]
    //  17. forward(30)     → (45,220)   [bay_alpha x:5-67 (45∈✓)]
    //  18. turnRight(90)   → north (0°) [270+90=360=0°]
    //  19. forward(50)     → (45,270)   [bay_alpha y:228-290 (270∈✓) ✓]
    //  20. gripper.open()  → deposit rock_alpha in bay_alpha ✓ (+10)
    //   Score: core_pickup(7)+bay_beta(10)+rock_pickup(7)+bay_alpha(10) = 34 pts. Actions=20. 20/40=50% ✓.
    //
    // Negative: Pair A only (rock_alpha→bay_alpha = 17 pts) < 33 → fails threshold.
    //
    // Objectives (total 50 pts, successRule: scoreThreshold 33, maxActions 40):
    //   obj_ss_pickup_a   pickUpItem rock_alpha               7 pts  optional
    //   obj_ss_deposit_a  depositItemInZone rock_alpha→bay_alpha  10 pts  optional  (A=17)
    //   obj_ss_pickup_b   pickUpItem core_zeta               7 pts  optional
    //   obj_ss_deposit_b  depositItemInZone core_zeta→bay_beta    10 pts  optional  (B=17)
    //   obj_ss_pickup_c   pickUpItem cell_ion                6 pts  optional
    //   obj_ss_deposit_c  depositItemInZone cell_ion→relay_station 10 pts optional (C=16)

    @Test("mission_sample_sort — loads with correct metadata")
    func sampleSortLoads() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_sample_sort"))
        #expect(m.difficulty == 5)
        #expect(m.totalPossiblePoints == 50)
        #expect(m.objectives.count == 6)
        #expect(m.objectives.filter { $0.isRequired }.count == 0)
        #expect(m.maxActions == 40)
        let pickupA = m.objectives.first { $0.id == "obj_ss_pickup_a" }
        #expect(pickupA?.targetItemId == "rock_alpha")
        #expect(pickupA?.points == 7)
        let depositA = m.objectives.first { $0.id == "obj_ss_deposit_a" }
        #expect(depositA?.targetItemId == "rock_alpha")
        #expect(depositA?.targetZoneId == "bay_alpha")
        #expect(depositA?.points == 10)
        let pickupB = m.objectives.first { $0.id == "obj_ss_pickup_b" }
        #expect(pickupB?.targetItemId == "core_zeta")
        #expect(pickupB?.points == 7)
        let depositB = m.objectives.first { $0.id == "obj_ss_deposit_b" }
        #expect(depositB?.targetItemId == "core_zeta")
        #expect(depositB?.targetZoneId == "bay_beta")
        #expect(depositB?.points == 10)
        let pickupC = m.objectives.first { $0.id == "obj_ss_pickup_c" }
        #expect(pickupC?.targetItemId == "cell_ion")
        #expect(pickupC?.points == 6)
        let depositC = m.objectives.first { $0.id == "obj_ss_deposit_c" }
        #expect(depositC?.targetItemId == "cell_ion")
        #expect(depositC?.targetZoneId == "relay_station")
        #expect(depositC?.points == 10)
        #expect(m.fieldId == "field_arena")
        if case let .scoreThreshold(t) = m.successRule { #expect(t == 33) }
    }

    @Test("mission_sample_sort — Strategy A (west-first: rock_alpha then core_zeta) scores 34 pts and succeeds")
    func sampleSortStrategyA() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_sample_sort"))
        // Pair A: west to (35,20), north to (35,220), east to (75,220)=rock_alpha.
        //   Pick up; reverse west to (45,220), north to (45,270)=bay_alpha; deposit.
        // Pair B: east to (248,270), south to (248,38)=core_zeta.
        //   Pick up; north to (248,270)=bay_beta; deposit.
        // Score: rock_pickup(7)+bay_alpha(10)+core_pickup(7)+bay_beta(10) = 34 ≥ 33.
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
        drive.forward(50);
        gripper.open();
        drive.turnRight(90);
        drive.forward(203);
        drive.turnRight(90);
        drive.forward(232);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.turnRight(180);
        drive.forward(232);
        gripper.open();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "West-first sort (Pair A then B) should succeed; failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 34,
                "Expected 34 pts (7+10+7+10), got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ss_pickup_a") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ss_deposit_a") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ss_pickup_b") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ss_deposit_b") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ss_pickup_c") == false)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ss_deposit_c") == false)
        // Confirm final position inside bay_beta (x:233-295, y:228-290)
        let finalPos = run.finalSnapshot?.pose.position
        #expect((finalPos?.x ?? 0) >= 233 && (finalPos?.x ?? 0) <= 295,
                "Final x \(finalPos?.x ?? -1) should be inside bay_beta x-range 233-295")
        #expect((finalPos?.y ?? 0) >= 228 && (finalPos?.y ?? 0) <= 290,
                "Final y \(finalPos?.y ?? -1) should be inside bay_beta y-range 228-290")
    }

    @Test("mission_sample_sort — Strategy B (east-first: core_zeta then rock_alpha) scores 34 pts and succeeds")
    func sampleSortStrategyB() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_sample_sort"))
        // Pair B: east to (248,20), north to (248,38)=core_zeta.
        //   Pick up; north to (248,270)=bay_beta; deposit.
        // Pair A: south to (248,220), west to (75,220)=rock_alpha.
        //   Pick up; continue west to (45,220), north to (45,270)=bay_alpha; deposit.
        // Score: core_pickup(7)+bay_beta(10)+rock_pickup(7)+bay_alpha(10) = 34 ≥ 33.
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
        drive.forward(232);
        gripper.open();
        drive.turnRight(180);
        drive.forward(50);
        drive.turnRight(90);
        drive.forward(173);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.forward(30);
        drive.turnRight(90);
        drive.forward(50);
        gripper.open();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "East-first sort (Pair B then A) should succeed; failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 34,
                "Expected 34 pts (7+10+7+10), got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ss_pickup_b") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ss_deposit_b") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ss_pickup_a") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ss_deposit_a") == true)
        // Confirm final position inside bay_alpha (x:5-67, y:228-290)
        let finalPos = run.finalSnapshot?.pose.position
        #expect((finalPos?.x ?? 0) >= 5 && (finalPos?.x ?? 0) <= 67,
                "Final x \(finalPos?.x ?? -1) should be inside bay_alpha x-range 5-67")
        #expect((finalPos?.y ?? 0) >= 228 && (finalPos?.y ?? 0) <= 290,
                "Final y \(finalPos?.y ?? -1) should be inside bay_alpha y-range 228-290")
    }

    @Test("mission_sample_sort — Pair A only (rock_alpha→bay_alpha = 17 pts) fails 33-pt threshold")
    func sampleSortPairAOnlyFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_sample_sort"))
        // Only complete Pair A: pickup rock_alpha + deposit in bay_alpha = 17 pts < 33.
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
        drive.forward(50);
        gripper.open();
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == false,
                "Pair A only (17 pts) should not reach 33-pt threshold")
        #expect(run.missionResult?.score == 17,
                "Should score 17 pts (7+10); got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ss_pickup_a") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ss_deposit_a") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ss_pickup_b") == false)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ss_deposit_b") == false)
    }

    // =========================================================================
    // MARK: - Mission 15: mission_grand_expedition  (diff 5, 50 pts, maxActions 40)
    // =========================================================================
    //
    // The Mars capstone.  Two winning portfolios, one WITH the boulder-ring
    // extraction (Core Delta) and one WITHOUT (safer multi-objective sweep).
    //
    // Point structure (total 50 pts, successRule: allRequiredAndScore 33):
    //   obj_ge_ring     pickUpItem core_delta                  9 pts  optional
    //   obj_ge_deliver  depositItemInZone core_delta→bay_beta  8 pts  optional  (ring pair=17)
    //   obj_ge_solar    detectColorInZone solar_pad yellow     12 pts optional
    //   obj_ge_beacon   detectColorInZone beacon_pad orange    10 pts optional
    //   obj_ge_sample   pickUpItem rock_alpha                   6 pts optional
    //   obj_ge_home     reachZone base_camp                     5 pts REQUIRED
    //   Total=50, threshold=33.
    //
    //   Portfolio A (ring+deliver+solar+home) = 9+8+12+5 = 34 ✓
    //   Portfolio B (solar+beacon+sample+home) = 12+10+6+5 = 33 ✓
    //   Fail: solar+beacon+home only = 12+10+5 = 27 < 33 ✗
    //
    // Portfolio A — ring extraction path (footprintRadius=18):
    //   Start (150,20) heading north (0°), footprintRadius=18.
    //   1. turnRight(90)  → east (90°)
    //   2. forward(105)   → (255,20)   [scatter y:62-84; y=20<62 ✓]
    //   3. turnLeft(90)   → north (0°) [90-90=0°]
    //   4. forward(142)   → (255,162)  [scatter x=255>190 ✓; ring: x=255>178 ✓]
    //   5. turnLeft(90)   → west (270°) [0-90=-90=270°]
    //   6. forward(105)   → (150,162)  = core_delta [gap entry: leading_edge_x=150-18=132;
    //                                    boulder_W east edge x=114; 132>114 ✓;
    //                                    boulder_S clearance: 162-140=22>18 ✓;
    //                                    boulder_N clearance: 184-162=22>18 ✓]
    //   7. arm.lower()
    //   8. gripper.close()  → pick core_delta (+9)
    //   9. arm.raise()
    //      [at (150,162) heading west (270°)]
    //  10. turnRight(180)  → east (90°) [270+180=450=90°]
    //  11. forward(105)    → (255,162)  [exit gap east ✓]
    //  12. turnRight(90)   → south (180°) [90+90=180°]
    //  13. forward(90)     → (255,72)   [solar_pad x:220-280 (255∈✓), y:45-100 (72∈✓) ✓;
    //                                    scatter: x=255>190 ✓]
    //  14. color()         → "yellow"; detectColorInZone solar_pad ✓ (+12)
    //  15. turnRight(180)  → north (0°) [180+180=360=0°]
    //  16. forward(200)    → (255,272)  [bay_beta x:233-295 (255∈✓), y:228-290 (272∈✓) ✓;
    //                                    scatter: x=255>190 ✓]
    //  17. gripper.open()  → deposit core_delta in bay_beta ✓ (+8)
    //      [at (255,272) heading north (0°)]
    //  18. turnRight(180)  → south (180°) [0+180=180°]
    //  19. forward(252)    → (255,20)   [y=272-252=20; scatter: x=255>190 ✓]
    //  20. turnRight(90)   → west (270°) [180+90=270°]
    //  21. forward(105)    → (150,20)   → base_camp x:108-192 (150∈✓), y:8-50 (20∈✓) ✓ (+5)
    //   Score: ring(9)+deliver(8)+solar(12)+home(5) = 34 pts. Motor actions=21. 21/40=52% ✓.
    //
    // Portfolio B — non-ring sweep (no footprintRadius needed):
    //   Start (150,20) heading north (0°).
    //   1. turnRight(90)   → east (90°)
    //   2. forward(85)     → (235,20)   [scatter y=20<62 ✓]
    //   3. turnLeft(90)    → north (0°) [90-90=0°]
    //   4. forward(52)     → (235,72)   [solar_pad ✓; scatter x=235>190 ✓]
    //   5. color()         → "yellow" (+12)
    //   6. turnRight(180)  → south (180°) [0+180=180°]
    //   7. forward(52)     → (235,20)
    //   8. turnRight(90)   → west (270°) [180+90=270°]
    //   9. forward(195)    → (40,20)    [scatter y=20<62 ✓]
    //  10. turnRight(90)   → north (0°) [270+90=360=0°]
    //  11. forward(55)     → (40,75)    [beacon_pad x:10-65 (40∈✓), y:50-105 (75∈✓) ✓;
    //                                    crater_rim y:154-168; y=75<154 ✓]
    //  12. color()         → "orange" (+10)
    //      [at (40,75) heading north (0°)]
    //  13. turnLeft(90)    → west (270°) [0-90=-90=270°]
    //  14. forward(5)      → (35,75)    [x=35<38: west of crater_rim x:38-102 ✓]
    //  15. turnRight(90)   → north (0°) [270+90=360=0°]
    //  16. forward(145)    → (35,220)   [x=35<38: crater_rim (y:154-168) clear ✓;
    //                                    boulder_W x:100-114: x=35<100 ✓]
    //  17. turnRight(90)   → east (90°) [0+90=90°]
    //  18. forward(40)     → (75,220)   = rock_alpha ✓ [y=220>198: boulder_N top clear ✓]
    //  19. arm.lower()
    //  20. gripper.close() → pick rock_alpha (+6)
    //  21. arm.raise()
    //      [at (75,220) heading east (90°)]
    //  22. turnRight(180)  → west (270°) [90+180=270°]
    //  23. forward(40)     → (35,220)
    //  24. turnLeft(90)    → south (180°) [270-90=180°]
    //  25. forward(200)    → (35,20)    [x=35<38: crater_rim clear ✓]
    //  26. turnLeft(90)    → east (90°) [180-90=90°]
    //  27. forward(115)    → (150,20)   → base_camp ✓ (+5)
    //   Score: solar(12)+beacon(10)+sample(6)+home(5) = 33 pts. Motor actions=27. 27/40=67.5% ✓.
    //
    // Negative: solar+beacon+home only (12+10+5=27 pts) fails allRequiredAndScore(33).

    @Test("mission_grand_expedition — loads with correct metadata")
    func grandExpeditionLoads() throws {
        let m = try #require(try RoboticsLibrary.mission(id: "mission_grand_expedition"))
        #expect(m.difficulty == 5)
        #expect(m.totalPossiblePoints == 50)
        #expect(m.objectives.count == 6)
        #expect(m.objectives.filter { $0.isRequired }.count == 1)
        #expect(m.maxActions == 40)
        let ringObj = m.objectives.first { $0.id == "obj_ge_ring" }
        #expect(ringObj?.targetItemId == "core_delta")
        #expect(ringObj?.points == 9)
        #expect(ringObj?.isRequired == false)
        let deliverObj = m.objectives.first { $0.id == "obj_ge_deliver" }
        #expect(deliverObj?.targetItemId == "core_delta")
        #expect(deliverObj?.targetZoneId == "bay_beta")
        #expect(deliverObj?.points == 8)
        let solarObj = m.objectives.first { $0.id == "obj_ge_solar" }
        #expect(solarObj?.targetZoneId == "solar_pad")
        #expect(solarObj?.expectedColor == "yellow")
        #expect(solarObj?.points == 12)
        let beaconObj = m.objectives.first { $0.id == "obj_ge_beacon" }
        #expect(beaconObj?.targetZoneId == "beacon_pad")
        #expect(beaconObj?.expectedColor == "orange")
        #expect(beaconObj?.points == 10)
        let sampleObj = m.objectives.first { $0.id == "obj_ge_sample" }
        #expect(sampleObj?.targetItemId == "rock_alpha")
        #expect(sampleObj?.points == 6)
        let homeObj = m.objectives.first { $0.id == "obj_ge_home" }
        #expect(homeObj?.targetZoneId == "base_camp")
        #expect(homeObj?.isRequired == true)
        #expect(homeObj?.points == 5)
        #expect(m.fieldId == "field_arena")
        if case let .allRequiredAndScore(t) = m.successRule { #expect(t == 33) }
    }

    @Test("mission_grand_expedition — Portfolio A (ring extraction + solar + home) scores 34 pts and succeeds")
    func grandExpeditionPortfolioA() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_grand_expedition"))
        // footprintRadius=18 for realistic ring-entry collision geometry.
        // East to (255,20), north to (255,162), west through gap to (150,162): pick core_delta.
        // Turn east, exit gap to (255,162), south to (255,72): solar detect.
        // North to (255,272): deposit core_delta in bay_beta.
        // South to (255,20), west to (150,20): base_camp.
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
        drive.forward(90);
        color();
        drive.turnRight(180);
        drive.forward(200);
        gripper.open();
        drive.turnRight(180);
        drive.forward(252);
        drive.turnRight(90);
        drive.forward(105);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "Ring extraction portfolio should succeed; failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 34,
                "Expected 34 pts (9+8+12+5), got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ge_ring") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ge_deliver") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ge_solar") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ge_home") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ge_beacon") == false)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ge_sample") == false)
        // Confirm base_camp arrival (x:108-192, y:8-50)
        let finalPos = run.finalSnapshot?.pose.position
        #expect((finalPos?.x ?? 0) >= 108 && (finalPos?.x ?? 0) <= 192,
                "Final x \(finalPos?.x ?? -1) should be in base_camp x-range 108-192")
        #expect((finalPos?.y ?? 0) >= 8 && (finalPos?.y ?? 0) <= 50,
                "Final y \(finalPos?.y ?? -1) should be in base_camp y-range 8-50")
    }

    @Test("mission_grand_expedition — Portfolio B (non-ring sweep: solar+beacon+rock_alpha+home) scores 33 pts and succeeds")
    func grandExpeditionPortfolioB() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_grand_expedition"))
        // No ring — default footprintRadius.
        // East to solar_pad, detect yellow (+12).
        // South, west to beacon_pad, detect orange (+10).
        // West to x=35, north to (35,220), east to (75,220)=rock_alpha, pick up (+6).
        // West to (35,220), south to (35,20), east to (150,20): base_camp ✓ (+5).
        // Score: solar(12)+beacon(10)+sample(6)+home(5) = 33 ≥ 33.
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
        drive.turnLeft(90);
        drive.forward(5);
        drive.turnRight(90);
        drive.forward(145);
        drive.turnRight(90);
        drive.forward(40);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.turnRight(180);
        drive.forward(40);
        drive.turnLeft(90);
        drive.forward(200);
        drive.turnLeft(90);
        drive.forward(115);
        """
        let run = sim.run(program: program, world: w, robot: robot, mission: m)
        #expect(run.missionResult?.success == true,
                "Non-ring sweep should succeed; failure=\(run.missionResult?.failureReason ?? "none"), runFailure=\(String(describing: run.failureKind))")
        #expect(run.missionResult?.score == 33,
                "Expected 33 pts (12+10+6+5), got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ge_solar") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ge_beacon") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ge_sample") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ge_home") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ge_ring") == false)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ge_deliver") == false)
        // Confirm base_camp arrival (x:108-192, y:8-50)
        let finalPos = run.finalSnapshot?.pose.position
        #expect((finalPos?.x ?? 0) >= 108 && (finalPos?.x ?? 0) <= 192,
                "Final x \(finalPos?.x ?? -1) should be in base_camp x-range 108-192")
        #expect((finalPos?.y ?? 0) >= 8 && (finalPos?.y ?? 0) <= 50,
                "Final y \(finalPos?.y ?? -1) should be in base_camp y-range 8-50")
    }

    @Test("mission_grand_expedition — solar+beacon+home only (27 pts) fails allRequiredAndScore threshold")
    func grandExpeditionInsufficientSweepFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_grand_expedition"))
        // Detect solar + beacon + return to base_camp.
        // Score: solar(12)+beacon(10)+home(5) = 27 < 33 → fails allRequiredAndScore.
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
        #expect(run.missionResult?.success == false,
                "Solar+beacon+home (27 pts) should not reach 33-pt threshold")
        #expect(run.missionResult?.score == 27,
                "Should score 27 pts (12+10+5); got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ge_solar") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ge_beacon") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ge_home") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ge_ring") == false)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ge_sample") == false)
    }

    @Test("mission_grand_expedition — missing base_camp (required) fails allRequiredAndScore regardless of score")
    func grandExpeditionNoHomeFails() throws {
        let w = try world()
        let m = try #require(try RoboticsLibrary.mission(id: "mission_grand_expedition"))
        // Detect solar+beacon (22 pts) but never return to base_camp (required) → fails.
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
                "Missing required base_camp should fail even with solar+beacon detected")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ge_solar") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ge_beacon") == true)
        #expect(run.missionResult?.metObjectiveIds.contains("obj_ge_home") == false)
    }
}
