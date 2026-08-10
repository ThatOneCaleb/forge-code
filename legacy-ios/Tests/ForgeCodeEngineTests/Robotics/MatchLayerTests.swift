import Testing
@testable import ForgeCodeEngine

/// Tests for the Match layer: Match model, FieldWorld.homePose, returnHome() API,
/// collision blockAndContinue policy, runMatch(...), and MatchResult scoring.
@Suite("Match layer — Match, MatchRun, returnHome, collision policy, homePose")
struct MatchLayerTests {

    // MARK: - Helpers

    private let sim = RoboticsSimulator()

    /// Open 300×300 field with no obstacles or zones.
    private func openField() -> FieldWorld {
        FieldWorld(id: "open", name: "Open", widthCm: 300, heightCm: 300)
    }

    /// Field with a single rectangular obstacle.
    private func fieldWithObstacle() -> FieldWorld {
        FieldWorld(
            id: "obs", name: "Obs", widthCm: 300, heightCm: 300,
            obstacles: [FieldObstacle(id: "wall",
                                      rect: FieldRect(x: 100, y: 100, width: 100, height: 20))]
        )
    }

    /// A minimal warehouse-style field with goal and home zones.
    private func warehouseStyleField() -> FieldWorld {
        FieldWorld(
            id: "wh", name: "Warehouse Style", widthCm: 240, heightCm: 240,
            zones: [
                FieldZone(id: "goal_zone", kind: .goal,
                          rect: FieldRect(x: 100, y: 100, width: 40, height: 40)),
                FieldZone(id: "home_base", kind: .goal,
                          rect: FieldRect(x: 95, y: 5, width: 50, height: 30))
            ]
        )
    }

    /// A minimal arena-style field with base_camp zone.
    private func arenaStyleField() -> FieldWorld {
        FieldWorld(
            id: "arena", name: "Arena Style", widthCm: 300, heightCm: 300,
            zones: [
                FieldZone(id: "base_camp", kind: .goal,
                          rect: FieldRect(x: 108, y: 8, width: 84, height: 42))
            ]
        )
    }

    // MARK: - Match model

    @Test("Match initialises with correct default values")
    func matchDefaults() {
        let m = Match(
            id: "m1", fieldId: "f1", name: "Test", brief: "Brief",
            missionIds: ["a", "b"], moveBudget: 50
        )
        #expect(m.startingTokens == 6)
        #expect(m.pointsPerToken == 10)
        #expect(m.parScore == nil)
    }

    @Test("Match stores custom token configuration")
    func matchCustomTokens() {
        let m = Match(
            id: "m2", fieldId: "f1", name: "T", brief: "B",
            missionIds: [], moveBudget: 30,
            startingTokens: 4, pointsPerToken: 15, parScore: 120
        )
        #expect(m.startingTokens == 4)
        #expect(m.pointsPerToken == 15)
        #expect(m.parScore == 120)
    }

    @Test("Match is Equatable")
    func matchEquatable() {
        let m1 = Match(id: "x", fieldId: "f", name: "N", brief: "B",
                       missionIds: ["a"], moveBudget: 10)
        let m2 = Match(id: "x", fieldId: "f", name: "N", brief: "B",
                       missionIds: ["a"], moveBudget: 10)
        #expect(m1 == m2)
    }

    // MARK: - FieldWorld.homePose (resolvedHomePose)

    @Test("resolvedHomePose uses explicit homePose when set")
    func homePoseExplicit() {
        let explicitPose = Pose(position: Vec2(x: 55, y: 75), headingDegrees: 90)
        var world = openField()
        world.homePose = explicitPose
        #expect(world.resolvedHomePose == explicitPose)
    }

    @Test("resolvedHomePose falls back to base_camp zone centre heading north")
    func homePoseBaseCamp() {
        let world = arenaStyleField()
        // base_camp: x:108, y:8, w:84, h:42 → centre (150, 29)
        let hp = world.resolvedHomePose
        #expect(abs(hp.position.x - 150) < 0.01)
        #expect(abs(hp.position.y - 29) < 0.01)
        #expect(abs(hp.headingDegrees - 0) < 0.01)
    }

    @Test("resolvedHomePose falls back to home_base zone centre heading north")
    func homePoseHomeBase() {
        let world = warehouseStyleField()
        // home_base: x:95, y:5, w:50, h:30 → centre (120, 20)
        let hp = world.resolvedHomePose
        #expect(abs(hp.position.x - 120) < 0.01)
        #expect(abs(hp.position.y - 20) < 0.01)
        #expect(abs(hp.headingDegrees - 0) < 0.01)
    }

    @Test("resolvedHomePose falls back to south-centre when no named zones present")
    func homePoseFallback() {
        // openField has no zones, no explicit homePose
        let world = openField()
        let hp = world.resolvedHomePose
        #expect(abs(hp.position.x - 150) < 0.01, "x should be widthCm/2 = 150")
        #expect(abs(hp.position.y - 10) < 0.01, "y should be 10 (south-centre)")
        #expect(abs(hp.headingDegrees - 0) < 0.01)
    }

    @Test("Explicit homePose in JSON overrides derived default for both seed fields")
    func homePoseLoadedFields() throws {
        // Seed fields have no explicit homePose → derived from zones
        let warehouse = try #require(try RoboticsLibrary.field(id: "field_warehouse"))
        let arena     = try #require(try RoboticsLibrary.field(id: "field_arena"))
        // Both have nil explicit homePose (not in JSON)
        #expect(warehouse.homePose == nil)
        #expect(arena.homePose == nil)
        // But resolvedHomePose derives from named zones
        let whp = warehouse.resolvedHomePose
        // home_base: x:95, y:5, w:50, h:30 → centre (120, 20)
        #expect(abs(whp.position.x - 120) < 0.01)
        #expect(abs(whp.position.y - 20) < 0.01)
        let ahp = arena.resolvedHomePose
        // base_camp: x:108, y:8, w:84, h:42 → centre (150, 29)
        #expect(abs(ahp.position.x - 150) < 0.01)
        #expect(abs(ahp.position.y - 29) < 0.01)
    }

    // MARK: - returnHome() API

    @Test("returnHome() teleports robot to resolvedHomePose")
    func returnHomeTeleports() {
        let world = warehouseStyleField()
        // Start far from home
        let robot = RobotModel(pose: Pose(position: Vec2(x: 200, y: 200), headingDegrees: 90))
        let run = sim.run(program: "returnHome();", world: world, robot: robot)
        #expect(run.completed)
        let finalPose = run.finalSnapshot?.pose
        // home_base centre = (120, 20)
        #expect(abs((finalPose?.position.x ?? -1) - 120) < 0.01)
        #expect(abs((finalPose?.position.y ?? -1) - 20) < 0.01)
    }

    @Test("returnHome() costs 1 action from the budget")
    func returnHomeCostsAction() {
        // Use a 1-action budget — returnHome() alone should exhaust it.
        let tightSim = RoboticsSimulator(stepBudget: 50_000, actionBudget: 1)
        let world = warehouseStyleField()
        let robot = RobotModel(pose: Pose(position: Vec2(x: 100, y: 100), headingDegrees: 0))
        // 2 actions: returnHome + forward → should fail after returnHome succeeds
        let run = tightSim.run(
            program: "returnHome(); drive.forward(10);",
            world: world, robot: robot
        )
        if case .actionBudgetExceeded = run.failureKind { /* expected */ }
        else {
            Issue.record("Expected actionBudgetExceeded from budget=1 with 2 actions, got \(String(describing: run.failureKind))")
        }
        // returnHome() did execute (robot moved to home pose)
        let finalPose = run.finalSnapshot?.pose
        #expect(abs((finalPose?.position.x ?? -1) - 120) < 0.01,
                "Robot should be at home_base x=120 after returnHome()")
    }

    @Test("returnHome() keeps any held item (item stays in gripper after teleport)")
    func returnHomeKeepsHeldItem() {
        // World with an item and a home zone
        let world = FieldWorld(
            id: "held_test", name: "Held", widthCm: 300, heightCm: 300,
            items: [FieldItem(id: "box", position: Vec2(x: 150, y: 150), pickupRadius: 15)],
            zones: [FieldZone(id: "home_base", kind: .goal,
                              rect: FieldRect(x: 10, y: 10, width: 50, height: 50))]
        )
        // Robot starts at item, picks it up, then returns home
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 150), headingDegrees: 0),
            armAngle: 90, isGripperOpen: true
        )
        let program = """
        gripper.close();
        returnHome();
        """
        let run = sim.run(program: program, world: world, robot: robot)
        #expect(run.completed)
        // Robot should be at home_base centre (35, 35) and still holding the box
        let snap = run.finalSnapshot
        #expect(snap?.heldObjectId == "box", "Robot should still hold box after returnHome()")
        #expect(abs((snap?.pose.position.x ?? -1) - 35) < 0.01,
                "Robot should be at home_base centre x=35")
    }

    @Test("returnHome() records a returnHome event in the sensor log")
    func returnHomeLogsEvent() {
        let world = warehouseStyleField()
        let robot = RobotModel(pose: Pose(position: Vec2(x: 50, y: 50), headingDegrees: 0))
        let run = sim.run(program: "returnHome();", world: world, robot: robot)
        let homeEvents = run.sensorLog.filter {
            if case .returnHome = $0.kind { return true }
            return false
        }
        #expect(homeEvents.count == 1, "Should have exactly 1 returnHome sensor event")
    }

    @Test("returnHome() in single-mission run has no token effect (no bookkeeping)")
    func returnHomeSingleMissionNoTokens() {
        // In a single-mission run, returnHome() works as a teleport with 0 token side-effects.
        // We verify it completes and the run does not fail.
        let world = warehouseStyleField()
        let robot = RobotModel(pose: Pose(position: Vec2(x: 150, y: 150), headingDegrees: 0))
        let run = sim.run(program: "returnHome(); returnHome(); returnHome();", world: world, robot: robot)
        #expect(run.completed, "Multiple returnHome() calls in single-mission run should not fail")
    }

    // MARK: - Collision policy

    @Test("Default single-mission run uses .failRun: collision terminates the run")
    func collisionFailRun() {
        // Obstacle at x:100-200, y:100-120. Robot at (150,80) heading north drives into it.
        let robot = RobotModel(pose: Pose(position: Vec2(x: 150, y: 80), headingDegrees: 0))
        let run = sim.run(program: "drive.forward(60);", world: fieldWithObstacle(), robot: robot)
        if case .collision = run.failureKind { /* expected */ }
        else {
            Issue.record("Expected collision failure in default .failRun mode, got \(String(describing: run.failureKind))")
        }
        // Run should have terminated before reaching y=160
        let finalY = run.finalSnapshot?.pose.position.y ?? 0
        #expect(finalY < 100, "Robot should be stopped before the obstacle")
    }

    @Test(".blockAndContinue: colliding drive stops robot and next statement runs")
    func collisionBlockAndContinue() {
        // Run via runMatch which uses .blockAndContinue.
        // Obstacle at y:100-120. Robot starts at (150,80) heading north.
        // drive.forward(60) would hit obstacle → stops at ~y=99.
        // Then print("reached") should still execute.
        let world = fieldWithObstacle()
        let match = Match(
            id: "test_m", fieldId: "obs", name: "Test", brief: "B",
            missionIds: [], moveBudget: 20
        )
        let robot = RobotModel(pose: Pose(position: Vec2(x: 150, y: 80), headingDegrees: 0))
        let program = """
        drive.forward(60);
        print("reached");
        """
        let matchRun = sim.runMatch(program: program, world: world, match: match,
                                    missions: [], robot: robot)
        // Run should NOT have a collision failure (it was absorbed)
        if let fk = matchRun.failureKind, case .collision = fk {
            Issue.record("blockAndContinue should not produce a collision failure")
        }
        // The print should appear in the sensor log (next statement ran)
        let prints = matchRun.sensorLog.compactMap { e -> String? in
            if case let .print_(s) = e.kind { return s }
            return nil
        }
        #expect(prints.contains("reached"),
                "Statement after blocked drive should still execute in .blockAndContinue mode")
        // Robot should be stopped before the obstacle
        let finalY = matchRun.snapshots.last?.pose.position.y ?? 0
        #expect(finalY < 100, "Robot should be stopped before obstacle at y=100")
    }

    @Test(".blockAndContinue: robot gets 'stuck' against obstacle and can returnHome() to recover")
    func collisionBlockAndRecoverWithReturnHome() {
        // Obstacle at y:100-120 in warehouseStyleField (which also has home_base).
        let world = FieldWorld(
            id: "recover_test", name: "Recover", widthCm: 300, heightCm: 300,
            zones: [FieldZone(id: "home_base", kind: .goal,
                              rect: FieldRect(x: 95, y: 5, width: 50, height: 30))],
            obstacles: [FieldObstacle(id: "wall",
                                      rect: FieldRect(x: 50, y: 100, width: 200, height: 20))]
        )
        let match = Match(
            id: "recover_m", fieldId: "recover_test", name: "Recover", brief: "B",
            missionIds: [], moveBudget: 20, startingTokens: 3
        )
        let robot = RobotModel(pose: Pose(position: Vec2(x: 150, y: 60), headingDegrees: 0))
        // Drive into obstacle → blocked, then returnHome() to recover
        let program = """
        drive.forward(80);
        returnHome();
        """
        let matchRun = sim.runMatch(program: program, world: world, match: match,
                                    missions: [], robot: robot)
        // No failure
        if let fk = matchRun.failureKind {
            Issue.record("Expected no failure, got \(fk)")
        }
        // Robot should be at home_base centre (120, 20) after returnHome()
        let finalPose = matchRun.snapshots.last?.pose
        #expect(abs((finalPose?.position.x ?? -1) - 120) < 0.01)
        #expect(abs((finalPose?.position.y ?? -1) - 20) < 0.01)
        // returnHome() spent 1 token: 3-1=2 remaining
        #expect(matchRun.result.tokensRemaining == 2,
                "1 token should be spent by returnHome(); 3-1=2 remaining")
        #expect(matchRun.result.tokenPoints == 20, "2 tokens × 10 pts = 20")
    }

    // MARK: - returnHome() token bookkeeping in match context

    @Test("returnHome() in match context spends 1 token")
    func returnHomeSpendsToken() {
        let world = warehouseStyleField()
        let match = Match(
            id: "token_m", fieldId: "wh", name: "Token", brief: "B",
            missionIds: [], moveBudget: 20, startingTokens: 4, pointsPerToken: 15
        )
        let robot = RobotModel(pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0))
        let matchRun = sim.runMatch(program: "returnHome();", world: world, match: match,
                                    missions: [], robot: robot)
        #expect(matchRun.result.tokensRemaining == 3, "4 - 1 = 3 tokens remaining")
        #expect(matchRun.result.tokenPoints == 45, "3 × 15 = 45 token points")
    }

    @Test("returnHome() floored at 0 tokens (never goes negative)")
    func returnHomeTokenFloor() {
        let world = warehouseStyleField()
        let match = Match(
            id: "zero_token_m", fieldId: "wh", name: "Zero", brief: "B",
            missionIds: [], moveBudget: 30, startingTokens: 2, pointsPerToken: 10
        )
        let robot = RobotModel(pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0))
        // Call returnHome() 5 times — tokens floor at 0
        let program = """
        returnHome();
        returnHome();
        returnHome();
        returnHome();
        returnHome();
        """
        let matchRun = sim.runMatch(program: program, world: world, match: match,
                                    missions: [], robot: robot)
        #expect(matchRun.result.tokensRemaining == 0, "Tokens should floor at 0")
        #expect(matchRun.result.tokenPoints == 0)
    }

    // MARK: - MatchResult.swift types

    @Test("MissionMatchEntry is Equatable")
    func missionMatchEntryEquatable() {
        let e1 = MissionMatchEntry(missionId: "m", metObjectiveIds: ["o1"], score: 10, success: true)
        let e2 = MissionMatchEntry(missionId: "m", metObjectiveIds: ["o1"], score: 10, success: true)
        #expect(e1 == e2)
    }

    @Test("MatchResult and MatchRun are Equatable")
    func matchResultEquatable() {
        let r1 = MatchResult(perMission: [], missionPoints: 0, tokensRemaining: 6,
                             tokenPoints: 60, totalScore: 60, actionsUsed: 0, budgetRemaining: 50)
        let r2 = MatchResult(perMission: [], missionPoints: 0, tokensRemaining: 6,
                             tokenPoints: 60, totalScore: 60, actionsUsed: 0, budgetRemaining: 50)
        #expect(r1 == r2)
    }

    // MARK: - runMatch: known-good program on field_warehouse seed match

    /// Verified program for match_cargo_command:
    ///
    /// Start: home_base centre (120, 20), heading north.
    ///   - goal_zone: x:100-140, y:100-140
    ///   - shelf_1 obstacle: x:90-150, y:130-150 (robot path at x=120 hits at y=130)
    ///
    /// Program:
    ///   drive.forward(100) → (120, 120)  [in goal_zone ✓; stops before shelf_1 at y=130]
    ///   arm.moveTo(45)     → arm = 45°
    ///
    /// Expected scoring:
    ///   mission_reach_goal:       obj_reach_goal met (goal_zone) → 10pts, success=true
    ///   mission_arm_handshake:    obj_reach_checkin (goal_zone) + obj_arm_signal (45°) → 10pts, success=true
    ///   mission_fetch_red_crate:  no objectives met → 0pts, success=false
    ///   mission_color_scout:      no objectives met → 0pts, success=false
    ///   mission_green_barrel_quickwin: no objectives met → 0pts, success=false
    ///
    ///   missionPoints=20, tokensRemaining=6, tokenPoints=60, totalScore=80
    ///   actionsUsed=2, budgetRemaining=58
    @Test("runMatch warehouse: known-good 2-action program scores exactly 80 pts")
    func runMatchWarehouseKnownGood() throws {
        let world    = try #require(try RoboticsLibrary.field(id: "field_warehouse"))
        let match    = try #require(try RoboticsLibrary.match(id: "match_cargo_command"))
        let missions = try match.missionIds.compactMap { try RoboticsLibrary.mission(id: $0) }
        #expect(missions.count == match.missionIds.count, "All match missions should load")

        // Start at home_base centre
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.forward(100);
        arm.moveTo(45);
        """
        let matchRun = sim.runMatch(
            program: program, world: world, match: match, missions: missions, robot: robot
        )

        #expect(matchRun.completed, "Run should complete without failure")

        let r = matchRun.result
        #expect(r.missionPoints  == 20, "Expected 20 mission points")
        #expect(r.tokensRemaining == 6, "No tokens spent")
        #expect(r.tokenPoints    == 60, "6 × 10 = 60 token points")
        #expect(r.totalScore     == 80, "20 + 60 = 80 total score")
        #expect(r.actionsUsed    == 2,  "2 actions: forward + arm.moveTo")
        #expect(r.budgetRemaining == 58, "60 - 2 = 58 remaining")

        // Per-mission breakdown
        let pm = r.perMission
        #expect(pm.count == 6, "6 missions in match")

        // mission_bay_door needs a gate bump + bay entry; this 2-action program
        // never reaches the east bay, so it scores 0 and success=false.
        let bayDoor = pm.first { $0.missionId == "mission_bay_door" }
        #expect(bayDoor?.score   == 0)
        #expect(bayDoor?.success == false)

        let reachGoal = pm.first { $0.missionId == "mission_reach_goal" }
        #expect(reachGoal?.score   == 10)
        #expect(reachGoal?.success == true)
        #expect(reachGoal?.metObjectiveIds.contains("obj_reach_goal") == true)

        let armHandshake = pm.first { $0.missionId == "mission_arm_handshake" }
        #expect(armHandshake?.score   == 10)
        #expect(armHandshake?.success == true)
        #expect(armHandshake?.metObjectiveIds.contains("obj_reach_checkin") == true)
        #expect(armHandshake?.metObjectiveIds.contains("obj_arm_signal")    == true)

        let fetchRed = pm.first { $0.missionId == "mission_fetch_red_crate" }
        #expect(fetchRed?.score   == 0)
        #expect(fetchRed?.success == false)

        let colorScout = pm.first { $0.missionId == "mission_color_scout" }
        #expect(colorScout?.score == 0)

        let barrel = pm.first { $0.missionId == "mission_green_barrel_quickwin" }
        #expect(barrel?.score == 0)
    }

    /// Token-spent variant: same program with one returnHome() prepended.
    ///
    /// returnHome() teleports to (120,20) [already there], spends 1 token.
    /// Everything else identical → missionPoints=20, tokensRemaining=5,
    /// tokenPoints=50, totalScore=70.
    @Test("runMatch warehouse: returnHome() spends 1 token → totalScore drops by pointsPerToken")
    func runMatchWarehouseReturnHomeDropsToken() throws {
        let world    = try #require(try RoboticsLibrary.field(id: "field_warehouse"))
        let match    = try #require(try RoboticsLibrary.match(id: "match_cargo_command"))
        let missions = try match.missionIds.compactMap { try RoboticsLibrary.mission(id: $0) }

        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        returnHome();
        drive.forward(100);
        arm.moveTo(45);
        """
        let matchRun = sim.runMatch(
            program: program, world: world, match: match, missions: missions, robot: robot
        )

        let r = matchRun.result
        #expect(r.missionPoints  == 20, "Same mission objectives met")
        #expect(r.tokensRemaining == 5,  "1 token spent by returnHome()")
        #expect(r.tokenPoints    == 50,  "5 × 10 = 50")
        #expect(r.totalScore     == 70,  "20 + 50 = 70 (10 pts less than no-token-spend)")
        #expect(r.actionsUsed    == 3,   "returnHome + forward + arm.moveTo = 3")
    }

    /// Budget-exhaustion variant: moveBudget=1 means drive.forward(100) uses the last
    /// action; arm.moveTo(45) triggers actionBudgetExceeded before executing.
    /// Scoring still runs against partial state: robot is at (120,120), arm at 0°.
    ///
    /// Expected:
    ///   mission_reach_goal:    in goal_zone → 10pts, success=true
    ///   mission_arm_handshake: in goal_zone (6pts) but arm=0°≠45° → success=false, 6pts
    ///   others: 0pts
    ///   missionPoints=16, tokens=6, tokenPoints=60, totalScore=76
    @Test("runMatch warehouse: budget exhaustion ends gracefully, partial score applied")
    func runMatchWarehouseBudgetExhausted() throws {
        let world    = try #require(try RoboticsLibrary.field(id: "field_warehouse"))
        let match    = try #require(try RoboticsLibrary.match(id: "match_cargo_command"))
        let missions = try match.missionIds.compactMap { try RoboticsLibrary.mission(id: $0) }

        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )

        // Create a tight-budget match (moveBudget=1): drive.forward succeeds, arm.moveTo fails.
        let tightMatch = Match(
            id:             match.id,
            fieldId:        match.fieldId,
            name:           match.name,
            brief:          match.brief,
            missionIds:     match.missionIds,
            moveBudget:     1,
            startingTokens: match.startingTokens,
            pointsPerToken: match.pointsPerToken,
            parScore:       match.parScore
        )

        let program = """
        drive.forward(100);
        arm.moveTo(45);
        """
        let matchRun = sim.runMatch(
            program: program, world: world, match: tightMatch, missions: missions, robot: robot
        )

        // Should have actionBudgetExceeded failure but still be scored
        if case .actionBudgetExceeded = matchRun.failureKind { /* expected */ }
        else {
            Issue.record("Expected actionBudgetExceeded failure, got \(String(describing: matchRun.failureKind))")
        }

        let r = matchRun.result
        // robot at (120,120) in goal_zone, arm at 0°
        #expect(r.missionPoints == 16,
                "reach_goal(10) + arm_handshake partial(6) = 16; expected 16, got \(r.missionPoints)")
        #expect(r.tokensRemaining == 6)
        #expect(r.tokenPoints    == 60)
        #expect(r.totalScore     == 76, "16 + 60 = 76")
        #expect(r.budgetRemaining == 0)

        let reachGoal = r.perMission.first { $0.missionId == "mission_reach_goal" }
        #expect(reachGoal?.success == true)

        let armHandshake = r.perMission.first { $0.missionId == "mission_arm_handshake" }
        #expect(armHandshake?.success == false, "arm=0° fails the required arm signal objective")
        #expect(armHandshake?.score == 6, "Only the reach-zone objective (6pts) is met")
    }

    // MARK: - runMatch: known-good program on field_arena seed match

    /// Verified program for match_mars_outpost:
    ///
    /// Start: base_camp centre (150, 29), heading north.
    ///   East path avoids all ring obstacles (x=250 clears boulder_scatter x:168-190).
    ///   solar_pad: x:220-280, y:45-100. solar_tile: same bounds, color "yellow".
    ///
    /// Heading trace:
    ///   start:              heading 0° (north)
    ///   turnRight(90):      heading 90° (east)
    ///   forward(100):       (250, 29) — clears boulder_scatter (y:62-84; y=29<62) ✓
    ///   turnLeft(90):       heading 0° (north)
    ///   forward(16):        (250, 45) — inside solar_pad (x:220-280, y:45-100) ✓
    ///   color():            "yellow" from solar_tile — sensor, no action cost
    ///   turnRight(180):     heading 180° (south)
    ///   forward(16):        (250, 29)
    ///   turnRight(90):      heading 270° (west)   ← right from south to face west
    ///   forward(100):       (150, 29) — inside base_camp (x:108-192, y:8-50) ✓
    ///
    /// Expected scoring against match_mars_outpost missions:
    ///   mission_first_traverse:  launch_pad — robot not there → 0pts
    ///   mission_beacon_salute:   beacon_pad — robot not there → 0pts
    ///   mission_first_sample:    no pickup → 0pts
    ///   mission_solar_checkin:   color "yellow" in solar_pad (12pts) + robot in base_camp (8pts) → 20pts, success=true
    ///   mission_relay_delivery:  no pickup → 0pts
    ///
    ///   missionPoints=20, tokensRemaining=6, tokenPoints=60, totalScore=80
    ///   actionsUsed=8 (6 drive + 2 turns; color() is a sensor, not an action)
    @Test("runMatch mars outpost: solar check-in program scores exactly 80 pts")
    func runMatchMarsOutpostKnownGood() throws {
        let world    = try #require(try RoboticsLibrary.field(id: "field_arena"))
        let match    = try #require(try RoboticsLibrary.match(id: "match_mars_outpost"))
        let missions = try match.missionIds.compactMap { try RoboticsLibrary.mission(id: $0) }
        #expect(missions.count == match.missionIds.count)

        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 29), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        // Heading trace:
        //   turnRight(90) → east; forward(100) → (250,29)
        //   turnLeft(90)  → north; forward(16) → (250,45) [in solar_pad]
        //   color()       → "yellow" [sensor, no action]
        //   turnRight(180) → south; forward(16) → (250,29)
        //   turnRight(90)  → west; forward(100) → (150,29) [in base_camp]
        let program = """
        drive.turnRight(90);
        drive.forward(100);
        drive.turnLeft(90);
        drive.forward(16);
        color();
        drive.turnRight(180);
        drive.forward(16);
        drive.turnRight(90);
        drive.forward(100);
        """
        let matchRun = sim.runMatch(
            program: program, world: world, match: match, missions: missions, robot: robot
        )

        #expect(matchRun.completed, "Run should complete without failure")

        let r = matchRun.result
        #expect(r.missionPoints  == 20, "Only mission_solar_checkin scores: 20pts")
        #expect(r.tokensRemaining == 6)
        #expect(r.tokenPoints    == 60)
        #expect(r.totalScore     == 80, "20 + 60 = 80")
        #expect(r.actionsUsed    == 8,
                "8 drive/turn actions (color() is a sensor); got \(r.actionsUsed)")

        let solarCheckin = r.perMission.first { $0.missionId == "mission_solar_checkin" }
        #expect(solarCheckin?.success == true)
        #expect(solarCheckin?.score   == 20)
        #expect(solarCheckin?.metObjectiveIds.contains("obj_sc_detect") == true)
        #expect(solarCheckin?.metObjectiveIds.contains("obj_sc_base")   == true)

        // Other missions should score 0
        let noScore = r.perMission.filter { $0.missionId != "mission_solar_checkin" }
        for entry in noScore {
            #expect(entry.score == 0, "\(entry.missionId) should score 0 with this program")
        }
    }

    /// Token-spent variant on Mars Outpost.
    @Test("runMatch mars outpost: returnHome() prepended drops totalScore by pointsPerToken")
    func runMatchMarsOutpostReturnHomeDropsToken() throws {
        let world    = try #require(try RoboticsLibrary.field(id: "field_arena"))
        let match    = try #require(try RoboticsLibrary.match(id: "match_mars_outpost"))
        let missions = try match.missionIds.compactMap { try RoboticsLibrary.mission(id: $0) }

        // Start at base_camp centre (150,29) heading north
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 29), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        returnHome();
        drive.turnRight(90);
        drive.forward(100);
        drive.turnLeft(90);
        drive.forward(16);
        color();
        drive.turnRight(180);
        drive.forward(16);
        drive.turnRight(90);
        drive.forward(100);
        """
        let matchRun = sim.runMatch(
            program: program, world: world, match: match, missions: missions, robot: robot
        )

        let r = matchRun.result
        #expect(r.missionPoints  == 20)
        #expect(r.tokensRemaining == 5, "1 token spent by returnHome()")
        #expect(r.tokenPoints    == 50, "5 × 10 = 50")
        #expect(r.totalScore     == 70, "20 + 50 = 70")
        #expect(r.actionsUsed    == 9, "returnHome + 8 drive/turn actions = 9")
    }

    /// Budget-exhaustion variant on Mars Outpost.
    @Test("runMatch mars outpost: budget exhaustion ends gracefully and scores partial")
    func runMatchMarsOutpostBudgetExhausted() throws {
        let world    = try #require(try RoboticsLibrary.field(id: "field_arena"))
        let match    = try #require(try RoboticsLibrary.match(id: "match_mars_outpost"))
        let missions = try match.missionIds.compactMap { try RoboticsLibrary.mission(id: $0) }

        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 29), headingDegrees: 0)
        )

        // moveBudget=3: turnRight + forward + turnLeft succeed; drive.forward(16) fails.
        // Robot ends at (250, 29), heading north — not in any scoring zone.
        let tightMatch = Match(
            id:             match.id,
            fieldId:        match.fieldId,
            name:           match.name,
            brief:          match.brief,
            missionIds:     match.missionIds,
            moveBudget:     3,
            startingTokens: match.startingTokens,
            pointsPerToken: match.pointsPerToken,
            parScore:       match.parScore
        )

        let program = """
        drive.turnRight(90);
        drive.forward(100);
        drive.turnLeft(90);
        drive.forward(16);
        color();
        drive.turnRight(180);
        drive.forward(16);
        drive.turnRight(90);
        drive.forward(100);
        """
        let matchRun = sim.runMatch(
            program: program, world: world, match: tightMatch, missions: missions, robot: robot
        )

        // Should have budget failure
        if case .actionBudgetExceeded = matchRun.failureKind { /* expected */ }
        else {
            Issue.record("Expected actionBudgetExceeded, got \(String(describing: matchRun.failureKind))")
        }

        let r = matchRun.result
        // Budget=3: turnRight(90) + forward(100) + turnLeft(90) succeed;
        // forward(16) triggers budget exceeded (actionCount=4 > 3).
        // Robot at (250,29): not in solar_pad (needs y≥45), not in base_camp (needs x≤192).
        #expect(r.missionPoints == 0, "No objectives met at (250,29) with budget=3")
        #expect(r.tokensRemaining == 6)
        #expect(r.totalScore     == 60, "0 mission + 60 token = 60")
        #expect(r.budgetRemaining == 0)
    }

    // MARK: - Determinism

    @Test("Same program + world + match ⇒ identical MatchRun (determinism)")
    func matchRunDeterminism() throws {
        let world    = try #require(try RoboticsLibrary.field(id: "field_warehouse"))
        let match    = try #require(try RoboticsLibrary.match(id: "match_cargo_command"))
        let missions = try match.missionIds.compactMap { try RoboticsLibrary.mission(id: $0) }

        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 20), headingDegrees: 0)
        )
        let program = "drive.forward(100); arm.moveTo(45);"

        let run1 = sim.runMatch(program: program, world: world, match: match,
                                missions: missions, robot: robot)
        let run2 = sim.runMatch(program: program, world: world, match: match,
                                missions: missions, robot: robot)
        #expect(run1 == run2, "runMatch should be fully deterministic")
    }

    @Test("Determinism: snapshots and sensor log are identical across two runs")
    func matchRunDeterminismTrace() throws {
        let world    = try #require(try RoboticsLibrary.field(id: "field_arena"))
        let match    = try #require(try RoboticsLibrary.match(id: "match_mars_outpost"))
        let missions = try match.missionIds.compactMap { try RoboticsLibrary.mission(id: $0) }

        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 29), headingDegrees: 0)
        )
        let program = """
        drive.turnRight(90);
        drive.forward(50);
        returnHome();
        """

        let run1 = sim.runMatch(program: program, world: world, match: match,
                                missions: missions, robot: robot)
        let run2 = sim.runMatch(program: program, world: world, match: match,
                                missions: missions, robot: robot)
        #expect(run1.snapshots == run2.snapshots, "Snapshots must be identical")
        #expect(run1.sensorLog == run2.sensorLog, "Sensor log must be identical")
        #expect(run1.result    == run2.result,    "MatchResult must be identical")
    }

    // MARK: - Content loader

    @Test("RoboticsLibrary loads seed matches")
    func loadsMatches() throws {
        let matches = try RoboticsLibrary.matches()
        #expect(matches.count >= 2, "Expected at least 2 seed matches")
    }

    @Test("Cargo Command seed match has expected field and 6 missions")
    func cargoCommandMatchContent() throws {
        let match = try #require(try RoboticsLibrary.match(id: "match_cargo_command"))
        #expect(match.fieldId == "field_warehouse")
        // 5 original + mission_bay_door (reactive roll-up gate mission)
        #expect(match.missionIds.count == 6)
        #expect(match.moveBudget == 60)
        #expect(match.startingTokens == 6)
        #expect(match.pointsPerToken == 10)
        #expect(match.parScore == 100)
    }

    @Test("Mars Outpost seed match has expected field and 6 missions")
    func marsOutpostMatchContent() throws {
        let match = try #require(try RoboticsLibrary.match(id: "match_mars_outpost"))
        #expect(match.fieldId == "field_arena")
        // 5 original + mission_storage_nook (mechanism gate mission)
        #expect(match.missionIds.count == 6)
        #expect(match.moveBudget == 60)
        #expect(match.startingTokens == 6)
        #expect(match.pointsPerToken == 10)
    }

    @Test("All seed match missionIds reference valid missions")
    func matchMissionIdsValid() throws {
        let matches  = try RoboticsLibrary.matches()
        let allIds   = Set(try RoboticsLibrary.missions().map { $0.id })
        for match in matches {
            for mId in match.missionIds {
                #expect(allIds.contains(mId),
                        "Match '\(match.id)' references unknown mission '\(mId)'")
            }
        }
    }

    @Test("All seed match fieldIds reference valid fields")
    func matchFieldIdsValid() throws {
        let matches  = try RoboticsLibrary.matches()
        let fieldIds = Set(try RoboticsLibrary.fields().map { $0.id })
        for match in matches {
            #expect(fieldIds.contains(match.fieldId),
                    "Match '\(match.id)' references unknown fieldId '\(match.fieldId)'")
        }
    }
}
