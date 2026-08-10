import Testing
@testable import ForgeCodeEngine

/// Tests for the robot sim: actions, sensors, missions, determinism.
@Suite("RoboticsSimulator — actions, sensors, missions")
struct RoboticsSimTests {

    // MARK: - Test world factory

    /// A simple open field, 300×300 cm, no obstacles.
    private func openField() -> FieldWorld {
        FieldWorld(id: "test_open", name: "Open", widthCm: 300, heightCm: 300)
    }

    /// A field with one obstacle rectangle in the way.
    private func fieldWithObstacle() -> FieldWorld {
        FieldWorld(
            id: "test_obs", name: "Obstacle",
            widthCm: 300, heightCm: 300,
            obstacles: [FieldObstacle(id: "wall", rect: FieldRect(x: 50, y: 50, width: 100, height: 20))]
        )
    }

    /// A field with one pickable item and one deposit zone.
    private func fieldWithItem() -> FieldWorld {
        FieldWorld(
            id: "test_item", name: "Item",
            widthCm: 300, heightCm: 300,
            items: [FieldItem(id: "box", position: Vec2(x: 150, y: 150),
                              color: "red", type: "crate", pickupRadius: 15)],
            zones: [FieldZone(id: "depot", kind: .deposit,
                              rect: FieldRect(x: 10, y: 10, width: 60, height: 60))],
            coloredRegions: [ColoredRegion(id: "red_tile",
                                            rect: FieldRect(x: 140, y: 140, width: 30, height: 30),
                                            color: "red")]
        )
    }

    /// A field with a line the robot can follow.
    private func fieldWithLine() -> FieldWorld {
        FieldWorld(
            id: "test_line", name: "Line",
            widthCm: 300, heightCm: 300,
            lines: [FieldLine(id: "track",
                              points: [Vec2(x: 150, y: 0), Vec2(x: 150, y: 300)],
                              width: 5)]
        )
    }

    private let sim = RoboticsSimulator()

    // MARK: - Drive actions

    @Test("drive.forward(cm) advances position along heading")
    func driveForward() {
        // Robot starts at (150,0) facing north (0°), drives 50 cm
        let robot = RobotModel(pose: Pose(position: Vec2(x: 150, y: 0), headingDegrees: 0))
        let run = sim.run(program: "drive.forward(50);", world: openField(), robot: robot)
        #expect(run.completed)
        let finalPos = run.finalSnapshot?.pose.position
        #expect(abs((finalPos?.y ?? 0) - 50) < 1.0, "Expected y ≈ 50, got \(finalPos?.y ?? -1)")
        #expect(abs((finalPos?.x ?? 0) - 150) < 0.5)
    }

    @Test("drive.backward(cm) moves in the opposite direction")
    func driveBackward() {
        let robot = RobotModel(pose: Pose(position: Vec2(x: 150, y: 100), headingDegrees: 0))
        let run = sim.run(program: "drive.backward(30);", world: openField(), robot: robot)
        #expect(run.completed)
        let finalY = run.finalSnapshot?.pose.position.y ?? 0
        #expect(abs(finalY - 70) < 1.0)
    }

    @Test("drive.turnRight(90) changes heading to 90°")
    func turnRight90() {
        let robot = RobotModel(pose: Pose(position: Vec2(x: 150, y: 150), headingDegrees: 0))
        let run = sim.run(program: "drive.turnRight(90);", world: openField(), robot: robot)
        #expect(run.completed)
        let heading = run.finalSnapshot?.pose.headingDegrees ?? -1
        #expect(abs(heading - 90) < 0.01)
    }

    @Test("drive.turnLeft(90) changes heading to 270°")
    func turnLeft90() {
        let robot = RobotModel(pose: Pose(position: Vec2(x: 150, y: 150), headingDegrees: 0))
        let run = sim.run(program: "drive.turnLeft(90);", world: openField(), robot: robot)
        #expect(run.completed)
        let heading = run.finalSnapshot?.pose.headingDegrees ?? -1
        #expect(abs(heading - 270) < 0.01)
    }

    @Test("drive.distance() returns cumulative encoder distance")
    func encoderDistance() {
        let robot = RobotModel(pose: Pose(position: Vec2(x: 10, y: 10), headingDegrees: 0))
        let run = sim.run(
            program: "drive.forward(30); var d = drive.distance(); print(d);",
            world: openField(), robot: robot
        )
        #expect(run.completed)
        // The print event in sensor log should show ~30
        let prints = run.sensorLog.compactMap { e -> String? in
            if case let .print_(s) = e.kind { return s }
            return nil
        }
        #expect(prints.count == 1)
        #expect(abs((Double(prints[0]) ?? 0) - 30) < 1.0)
    }

    @Test("drive.heading() returns current heading in degrees")
    func encoderHeading() {
        let robot = RobotModel(pose: Pose(position: Vec2(x: 150, y: 150), headingDegrees: 0))
        let run = sim.run(
            program: "drive.turnRight(45); var h = drive.heading(); print(h);",
            world: openField(), robot: robot
        )
        let prints = run.sensorLog.compactMap { e -> String? in
            if case let .print_(s) = e.kind { return s }
            return nil
        }
        #expect(prints.count == 1)
        #expect(abs((Double(prints[0]) ?? 0) - 45) < 0.1)
    }

    @Test("Driving out-of-bounds creates a failure run")
    func outOfBounds() {
        let robot = RobotModel(pose: Pose(position: Vec2(x: 150, y: 290), headingDegrees: 0))
        let run = sim.run(program: "drive.forward(50);", world: openField(), robot: robot)
        #expect(run.failureKind == .outOfBounds)
    }

    @Test("Collision with obstacle creates a failure run")
    func collision() {
        // Start just below the obstacle (x=150, y=48) heading north (into obstacle at y=50)
        let robot = RobotModel(pose: Pose(position: Vec2(x: 100, y: 48), headingDegrees: 0))
        let run = sim.run(program: "drive.forward(30);", world: fieldWithObstacle(), robot: robot)
        if case .collision = run.failureKind { /* expected */ }
        else {
            Issue.record("Expected collision failure, got \(String(describing: run.failureKind))")
        }
    }

    // MARK: - Arm actions

    @Test("arm.moveTo(90) sets arm to 90 degrees")
    func armMoveTo() {
        let robot = RobotModel(pose: .origin)
        let run = sim.run(program: "arm.moveTo(90);", world: openField(), robot: robot)
        #expect(run.completed)
        #expect(abs((run.finalSnapshot?.armAngle ?? -1) - 90) < 0.01)
    }

    @Test("arm.raise() sets arm to 0 degrees")
    func armRaise() {
        let robot = RobotModel(pose: .origin, armAngle: 90)
        let run = sim.run(program: "arm.raise();", world: openField(), robot: robot)
        #expect(abs((run.finalSnapshot?.armAngle ?? -1) - 0) < 0.01)
    }

    @Test("arm.lower() sets arm to 90 degrees")
    func armLower() {
        let robot = RobotModel(pose: .origin, armAngle: 0)
        let run = sim.run(program: "arm.lower();", world: openField(), robot: robot)
        #expect(abs((run.finalSnapshot?.armAngle ?? -1) - 90) < 0.01)
    }

    @Test("arm.angle() returns current arm angle")
    func armAngle() {
        let robot = RobotModel(pose: .origin, armAngle: 45)
        let run = sim.run(
            program: "var a = arm.angle(); print(a);",
            world: openField(), robot: robot
        )
        let prints = run.sensorLog.compactMap { e -> String? in
            if case let .print_(s) = e.kind { return s }
            return nil
        }
        #expect(prints.count == 1)
        #expect(abs((Double(prints[0]) ?? 0) - 45) < 0.1)
    }

    // MARK: - Gripper pick/place

    @Test("gripper.close() with arm lowered picks up nearby item")
    func gripperPickup() {
        // Position robot at (150,150) — item is at (150,150)
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 150), headingDegrees: 0),
            armAngle: 90,   // arm lowered
            isGripperOpen: true
        )
        let run = sim.run(program: "gripper.close();", world: fieldWithItem(), robot: robot)
        #expect(run.completed)
        #expect(run.finalSnapshot?.heldObjectId == "box")
        // Item state should be held
        let boxState = run.finalSnapshot?.itemStates.first { $0.id == "box" }
        #expect(boxState?.isHeld == true)
    }

    @Test("gripper.close() with arm raised does NOT pick up item")
    func gripperNoPickupArmRaised() {
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 150), headingDegrees: 0),
            armAngle: 0,    // arm raised — should prevent pickup
            isGripperOpen: true
        )
        let run = sim.run(program: "gripper.close();", world: fieldWithItem(), robot: robot)
        #expect(run.completed)
        #expect(run.finalSnapshot?.heldObjectId == nil)
    }

    @Test("gripper.open() over deposit zone deposits the item")
    func gripperDeposit() {
        // Robot at depot centre (40,40), holding the box
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 40, y: 40), headingDegrees: 0),
            armAngle: 90,
            isGripperOpen: false,
            heldObjectId: "box"
        )
        // Use a world where item is already held (heldObjectId set on robot)
        let world = FieldWorld(
            id: "test_deposit", name: "Deposit", widthCm: 300, heightCm: 300,
            items: [FieldItem(id: "box", position: Vec2(x: 150, y: 150))],
            zones: [FieldZone(id: "depot", kind: .deposit,
                              rect: FieldRect(x: 10, y: 10, width: 60, height: 60))]
        )
        let run = sim.run(program: "gripper.open();", world: world, robot: robot)
        #expect(run.completed)
        #expect(run.finalSnapshot?.heldObjectId == nil)
        let boxState = run.finalSnapshot?.itemStates.first { $0.id == "box" }
        #expect(boxState?.inZoneId == "depot")
    }

    @Test("gripper.isHolding() reflects held-object state")
    func gripperIsHolding() {
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 150), headingDegrees: 0),
            armAngle: 90,
            isGripperOpen: true,
            heldObjectId: nil
        )
        // After closing gripper on item, isHolding() should be true
        let run = sim.run(
            program: """
            gripper.close();
            var holding = gripper.isHolding();
            print(holding);
            """,
            world: fieldWithItem(), robot: robot
        )
        let prints = run.sensorLog.compactMap { e -> String? in
            if case let .print_(s) = e.kind { return s }
            return nil
        }
        #expect(prints == ["true"])
    }

    // MARK: - Sensors

    @Test("distance() reports a forward range to a boundary wall")
    func distanceSensor() {
        // Robot at (150,50) facing north; boundary is at y=300, so ~250 cm away
        let robot = RobotModel(pose: Pose(position: Vec2(x: 150, y: 50), headingDegrees: 0))
        let run = sim.run(program: "var d = distance(); print(d);", world: openField(), robot: robot)
        let prints = run.sensorLog.compactMap { e -> String? in
            if case let .print_(s) = e.kind { return s }
            return nil
        }
        let d = Double(prints.first ?? "0") ?? 0
        #expect(d > 200 && d <= 300, "Expected ~250, got \(d)")
    }

    @Test("color() returns the colour of the region the robot is standing in")
    func colorSensor() {
        // Robot at (150,150) which is in the red_tile region
        let robot = RobotModel(pose: Pose(position: Vec2(x: 150, y: 150), headingDegrees: 0))
        let run = sim.run(program: "var c = color(); print(c);", world: fieldWithItem(), robot: robot)
        let prints = run.sensorLog.compactMap { e -> String? in
            if case let .print_(s) = e.kind { return s }
            return nil
        }
        #expect(prints.first == "red")
    }

    @Test("color.isRed() returns true in a red region")
    func colorIsRed() {
        let robot = RobotModel(pose: Pose(position: Vec2(x: 150, y: 150), headingDegrees: 0))
        let run = sim.run(program: "var r = color.isRed(); print(r);", world: fieldWithItem(), robot: robot)
        let prints = run.sensorLog.compactMap { e -> String? in
            if case let .print_(s) = e.kind { return s }
            return nil
        }
        #expect(prints.first == "true")
    }

    @Test("color() returns empty string when not on a coloured region")
    func colorEmpty() {
        // Robot far from any coloured region
        let robot = RobotModel(pose: Pose(position: Vec2(x: 5, y: 5), headingDegrees: 0))
        let run = sim.run(program: "var c = color(); print(c);", world: openField(), robot: robot)
        let prints = run.sensorLog.compactMap { e -> String? in
            if case let .print_(s) = e.kind { return s }
            return nil
        }
        #expect(prints.first == "")
    }

    @Test("lineLeft() returns true when left sensor is on a line")
    func lineLeft() {
        // Robot at x=163 facing north; left sensor is at x≈151 (which is on the line at x=150)
        let robot = RobotModel(pose: Pose(position: Vec2(x: 163, y: 150), headingDegrees: 0))
        let run = sim.run(program: "var l = lineLeft(); print(l);", world: fieldWithLine(), robot: robot)
        let prints = run.sensorLog.compactMap { e -> String? in
            if case let .print_(s) = e.kind { return s }
            return nil
        }
        // Left sensor is 12 cm to the left when facing north: x = 163 - 12 = 151, on the line at 150 ± 2.5
        #expect(prints.first == "true", "Left sensor at x≈151 should be on the line at x=150, width=5")
    }

    @Test("lineRight() returns false when right sensor is off the line")
    func lineRight() {
        // Robot at x=163 facing north; right sensor is at x≈175 (off line)
        let robot = RobotModel(pose: Pose(position: Vec2(x: 163, y: 150), headingDegrees: 0))
        let run = sim.run(program: "var r = lineRight(); print(r);", world: fieldWithLine(), robot: robot)
        let prints = run.sensorLog.compactMap { e -> String? in
            if case let .print_(s) = e.kind { return s }
            return nil
        }
        #expect(prints.first == "false")
    }

    @Test("gyro() returns current heading in degrees")
    func gyro() {
        let robot = RobotModel(pose: Pose(position: Vec2(x: 150, y: 150), headingDegrees: 45))
        let run = sim.run(program: "var g = gyro(); print(g);", world: openField(), robot: robot)
        let prints = run.sensorLog.compactMap { e -> String? in
            if case let .print_(s) = e.kind { return s }
            return nil
        }
        #expect(abs((Double(prints.first ?? "0") ?? 0) - 45) < 0.1)
    }

    @Test("limitSwitch() is true when arm is at lower limit")
    func limitSwitch() {
        let robot = RobotModel(pose: .origin, armAngle: 90)  // fully lowered = at limit
        let run = sim.run(program: "var s = limitSwitch(); print(s);", world: openField(), robot: robot)
        let prints = run.sensorLog.compactMap { e -> String? in
            if case let .print_(s) = e.kind { return s }
            return nil
        }
        #expect(prints.first == "true")
    }

    @Test("wallAhead() returns true when very close to a boundary")
    func wallAhead() {
        // Robot at y=282, facing north; boundary at y=300, distance ~18 cm < 25 threshold
        let robot = RobotModel(pose: Pose(position: Vec2(x: 150, y: 282), headingDegrees: 0))
        let run = sim.run(program: "var w = wallAhead(); print(w);", world: openField(), robot: robot)
        let prints = run.sensorLog.compactMap { e -> String? in
            if case let .print_(s) = e.kind { return s }
            return nil
        }
        #expect(prints.first == "true")
    }

    @Test("wallAhead() returns false when far from any obstacle")
    func wallAheadFalse() {
        let robot = RobotModel(pose: Pose(position: Vec2(x: 150, y: 50), headingDegrees: 0))
        let run = sim.run(program: "var w = wallAhead(); print(w);", world: openField(), robot: robot)
        let prints = run.sensorLog.compactMap { e -> String? in
            if case let .print_(s) = e.kind { return s }
            return nil
        }
        #expect(prints.first == "false")
    }

    // MARK: - Per-mission maxActions cap

    /// A minimal mission that carries only a maxActions cap (no objectives matter here —
    /// we're testing that the budget fires from the mission field, not from scoring).
    private func cappedMission(maxActions: Int) -> Mission {
        Mission(
            id: "m_capped", fieldId: "test_open",
            title: "Capped", brief: "Tight budget",
            objectives: [],
            successRule: .allRequired,
            maxActions: maxActions
        )
    }

    @Test("Mission maxActions=3 causes a 4-action program to fail with actionBudgetExceeded")
    func missionMaxActionsTooManyFails() {
        // The simulator itself has a generous budget (500), but the mission caps at 3.
        let robot = RobotModel(pose: Pose(position: Vec2(x: 10, y: 10), headingDegrees: 0))
        let mission = cappedMission(maxActions: 3)
        // 4 actions: forward, turnRight, forward, turnLeft
        let program = "drive.forward(5); drive.turnRight(90); drive.forward(5); drive.turnLeft(90);"
        let run = sim.run(program: program, world: openField(), robot: robot, mission: mission)
        if case .actionBudgetExceeded = run.failureKind { /* expected */ }
        else {
            Issue.record("Expected actionBudgetExceeded from mission maxActions=3, got \(String(describing: run.failureKind))")
        }
    }

    @Test("Mission maxActions=10 allows a 4-action program to complete")
    func missionMaxActionsGenerousSucceeds() {
        let robot = RobotModel(pose: Pose(position: Vec2(x: 10, y: 10), headingDegrees: 0))
        let mission = cappedMission(maxActions: 10)
        // Same 4 actions — well within budget of 10
        let program = "drive.forward(5); drive.turnRight(90); drive.forward(5); drive.turnLeft(90);"
        let run = sim.run(program: program, world: openField(), robot: robot, mission: mission)
        #expect(run.completed, "4 actions should complete within maxActions=10")
    }

    @Test("Mission maxActions nil leaves simulator actionBudget unchanged")
    func missionMaxActionsNilUsesSimBudget() {
        // Use a simulator with a tight budget (3 actions) but mission.maxActions == nil.
        // A 4-action program should still fail from the simulator budget, not the mission cap.
        let tightSim = RoboticsSimulator(stepBudget: 100_000, actionBudget: 3)
        let robot = RobotModel(pose: Pose(position: Vec2(x: 10, y: 10), headingDegrees: 0))
        // mission has no maxActions → effective budget = simulator's 3
        let mission = Mission(
            id: "m_nil", fieldId: "test_open", title: "No cap", brief: "Uses sim budget",
            objectives: [], successRule: .allRequired
            // maxActions defaults to nil
        )
        let program = "drive.forward(5); drive.turnRight(90); drive.forward(5); drive.turnLeft(90);"
        let run = tightSim.run(program: program, world: openField(), robot: robot, mission: mission)
        if case .actionBudgetExceeded = run.failureKind { /* expected */ }
        else {
            Issue.record("Expected actionBudgetExceeded from sim budget=3 with nil maxActions, got \(String(describing: run.failureKind))")
        }
    }

    @Test("Mission maxActions takes effect as min(simBudget, maxActions)")
    func missionMaxActionsIsMin() {
        // Simulator budget = 500, mission maxActions = 2. Effective = min(500,2) = 2.
        // A 3-action program should fail.
        let robot = RobotModel(pose: Pose(position: Vec2(x: 10, y: 10), headingDegrees: 0))
        let mission = cappedMission(maxActions: 2)
        let program = "drive.forward(5); drive.turnRight(90); drive.forward(5);"
        let run = sim.run(program: program, world: openField(), robot: robot, mission: mission)
        if case .actionBudgetExceeded = run.failureKind { /* expected */ }
        else {
            Issue.record("Expected actionBudgetExceeded (effective budget=2), got \(String(describing: run.failureKind))")
        }
    }

    // MARK: - Action budget

    @Test("Action budget exceeded produces actionBudgetExceeded failure")
    func actionBudget() {
        let smallSim = RoboticsSimulator(stepBudget: 100_000, actionBudget: 5)
        let robot = RobotModel(pose: Pose(position: Vec2(x: 150, y: 50), headingDegrees: 0))
        let run = smallSim.run(
            program: "while (true) { drive.forward(1); }",
            world: openField(), robot: robot
        )
        if case .actionBudgetExceeded = run.failureKind { /* expected */ }
        else {
            Issue.record("Expected actionBudgetExceeded, got \(String(describing: run.failureKind))")
        }
    }

    // MARK: - Keyframe trace

    @Test("First snapshot is the initial robot state")
    func firstSnapshot() {
        let robot = RobotModel(pose: Pose(position: Vec2(x: 50, y: 50), headingDegrees: 0))
        let run = sim.run(program: "drive.forward(20);", world: openField(), robot: robot)
        #expect(run.snapshots.count >= 2)
        // First snapshot should match initial robot pose
        let first = run.snapshots[0]
        #expect(abs(first.pose.position.x - 50) < 0.01)
        #expect(abs(first.pose.position.y - 50) < 0.01)
    }

    @Test("Each drive action adds at least one snapshot")
    func snapshotCount() {
        let robot = RobotModel(pose: Pose(position: Vec2(x: 10, y: 10), headingDegrees: 0))
        let run = sim.run(
            program: "drive.forward(10); drive.turnRight(90); drive.forward(10);",
            world: openField(), robot: robot
        )
        // Should have: initial + 3 action snapshots = 4
        #expect(run.snapshots.count >= 4)
    }

    // MARK: - Determinism

    @Test("Same program + world always produces identical RoboticsRun")
    func determinism() {
        let robot = RobotModel(pose: Pose(position: Vec2(x: 50, y: 50), headingDegrees: 0))
        let world = openField()
        let prog = "drive.forward(30); drive.turnRight(90); drive.forward(20);"
        let run1 = sim.run(program: prog, world: world, robot: robot)
        let run2 = sim.run(program: prog, world: world, robot: robot)
        #expect(run1 == run2)
    }

    // MARK: - Mission: reach-zone

    @Test("Mission 'reach goal zone' succeeds when robot drives to zone")
    func missionReachZone() {
        let goalZone = FieldZone(id: "goal", kind: .goal,
                                 rect: FieldRect(x: 90, y: 90, width: 60, height: 60))
        let world = FieldWorld(id: "m", name: "M", widthCm: 300, heightCm: 300,
                               zones: [goalZone])
        let mission = Mission(
            id: "m1", fieldId: "m", title: "Reach Goal", brief: "Go to the goal",
            objectives: [
                MissionObjective(id: "o1", kind: .reachZone, points: 50, description: "Reach goal",
                                 targetZoneId: "goal", isRequired: true)
            ],
            successRule: .allRequired
        )
        let robot = RobotModel(pose: Pose(position: Vec2(x: 120, y: 10), headingDegrees: 0))
        let run = sim.run(program: "drive.forward(110);", world: world, robot: robot, mission: mission)
        #expect(run.missionResult?.success == true)
        #expect(run.missionResult?.score == 50)
        #expect(run.missionResult?.metObjectiveIds.contains("o1") == true)
    }

    @Test("Mission 'reach goal zone' fails when robot stops short")
    func missionReachZoneFail() {
        let goalZone = FieldZone(id: "goal", kind: .goal,
                                 rect: FieldRect(x: 90, y: 90, width: 60, height: 60))
        let world = FieldWorld(id: "m", name: "M", widthCm: 300, heightCm: 300,
                               zones: [goalZone])
        let mission = Mission(
            id: "m1", fieldId: "m", title: "Reach Goal", brief: "Go to the goal",
            objectives: [
                MissionObjective(id: "o1", kind: .reachZone, points: 50, description: "Reach goal",
                                 targetZoneId: "goal", isRequired: true)
            ],
            successRule: .allRequired
        )
        let robot = RobotModel(pose: Pose(position: Vec2(x: 120, y: 10), headingDegrees: 0))
        // Only drive 20 cm — won't reach y=90
        let run = sim.run(program: "drive.forward(20);", world: world, robot: robot, mission: mission)
        #expect(run.missionResult?.success == false)
        #expect(run.missionResult?.score == 0)
    }

    // MARK: - Mission: arm + gripper required

    @Test("Full pickup+deposit mission succeeds with arm+gripper program")
    func missionPickupDeposit() {
        // Item at (150, 150). Depot zone at (10,10)–(70,70), centre ≈ (40,40).
        // Strategy: robot starts at item position facing west (270°).
        //   1. Lower arm + close gripper → pick up box.
        //   2. Raise arm.
        //   3. Turn left (south→east... wait, facing west: turnLeft → south)
        //   Actually facing 270° (west): turnRight(90°) → facing 0° (north) is wrong.
        //   Simplest: turn to face south (180°) then backward to go north.
        //   Facing west (270°): drive.forward moves west (-x direction).
        //   x=150, y=150 facing west: drive forward 110 → x=40, y=150
        //   then turn right → facing north (0°): drive forward 110 → y=260 (wrong!)
        //   Better: start at (150,150) facing south (180°):
        //     forward 110 → y = 150-110 = 40, x=150 (moving south)
        //     turn right → facing west (270°): forward 110 → x = 150-110 = 40, y=40
        //     gripper.open() at (40,40) which is in depot zone → deposit!
        let world = fieldWithItem()
        let mission = Mission(
            id: "mFull", fieldId: "test_item", title: "Fetch & Deposit", brief: "Use arm and gripper",
            objectives: [
                MissionObjective(id: "oPickup", kind: .pickUpItem, points: 30,
                                 description: "Pick up box", targetItemId: "box", isRequired: true),
                MissionObjective(id: "oDeposit", kind: .depositItemInZone, points: 50,
                                 description: "Deposit in depot", targetZoneId: "depot",
                                 targetItemId: "box", isRequired: true)
            ],
            successRule: .allRequired
        )
        // Robot at (150,150), facing south (180°), arm raised, gripper open
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 150, y: 150), headingDegrees: 180),
            armAngle: 0, isGripperOpen: true
        )
        // Lower arm → close gripper (picks up box at (150,150))
        // Raise arm → drive forward 110 (south→ y=40) → turnRight → facing west
        // drive forward 110 (west → x=40) → at (40,40) inside depot zone → open gripper
        let program = """
        arm.lower();
        gripper.close();
        arm.raise();
        drive.forward(110);
        drive.turnRight(90);
        drive.forward(110);
        gripper.open();
        """
        let run = sim.run(program: program, world: world, robot: robot, mission: mission)
        let picked = run.missionResult?.metObjectiveIds.contains("oPickup")
        let deposited = run.missionResult?.metObjectiveIds.contains("oDeposit")
        #expect(picked == true, "Should have picked up the box")
        #expect(deposited == true, "Should have deposited the box in the depot zone")
        #expect(run.missionResult?.success == true)
    }

    @Test("Drive-only program cannot score the arm+gripper objectives")
    func missionPickupRequiresArm() {
        let world = fieldWithItem()
        let mission = Mission(
            id: "mFull", fieldId: "test_item", title: "Fetch & Deposit", brief: "Use arm and gripper",
            objectives: [
                MissionObjective(id: "oPickup", kind: .pickUpItem, points: 30,
                                 description: "Pick up box", targetItemId: "box", isRequired: true),
                MissionObjective(id: "oDeposit", kind: .depositItemInZone, points: 50,
                                 description: "Deposit in depot", targetZoneId: "depot",
                                 targetItemId: "box", isRequired: true)
            ],
            successRule: .allRequired
        )
        let robot = RobotModel(pose: Pose(position: Vec2(x: 40, y: 40), headingDegrees: 0))
        // Drive-only: never touches arm/gripper
        let run = sim.run(program: "drive.forward(10);", world: world, robot: robot, mission: mission)
        #expect(run.missionResult?.success == false, "Drive-only should not satisfy arm+gripper objectives")
        #expect(run.missionResult?.score == 0)
    }

    // MARK: - Mission: score threshold

    @Test("Score threshold mission passes when score is high enough")
    func missionScoreThreshold() {
        let world = FieldWorld(id: "t", name: "T", widthCm: 300, heightCm: 300,
                               zones: [FieldZone(id: "z", kind: .goal,
                                                  rect: FieldRect(x: 10, y: 10, width: 200, height: 200))])
        let mission = Mission(
            id: "ms", fieldId: "t", title: "Score 30", brief: "Reach the zone",
            objectives: [
                MissionObjective(id: "o1", kind: .reachZone, points: 50,
                                 description: "Go to zone", targetZoneId: "z")
            ],
            successRule: .scoreThreshold(30)
        )
        let robot = RobotModel(pose: Pose(position: Vec2(x: 100, y: 10), headingDegrees: 0))
        let run = sim.run(program: "drive.forward(50);", world: world, robot: robot, mission: mission)
        #expect(run.missionResult?.success == true)
    }

    // MARK: - Mission: armToAngle objective

    @Test("armToAngle objective is met when arm reaches target angle")
    func missionArmToAngle() {
        let world = openField()
        let mission = Mission(
            id: "mArm", fieldId: "test_open", title: "Arm Test", brief: "Lower the arm",
            objectives: [
                MissionObjective(id: "oArm", kind: .armToAngle, points: 20,
                                 description: "Lower arm to 90°", targetAngle: 90, isRequired: true)
            ],
            successRule: .allRequired
        )
        let robot = RobotModel(pose: .origin, armAngle: 0)
        let run = sim.run(program: "arm.moveTo(90);", world: world, robot: robot, mission: mission)
        #expect(run.missionResult?.success == true)
        #expect(run.missionResult?.metObjectiveIds.contains("oArm") == true)
    }

    // MARK: - Sensor log

    @Test("print() statements appear in sensor log")
    func printLog() {
        let robot = RobotModel(pose: .origin)
        let run = sim.run(program: #"print("hi");"#, world: openField(), robot: robot)
        let printEvents = run.sensorLog.filter {
            if case .print_ = $0.kind { return true }
            return false
        }
        #expect(printEvents.count == 1)
        if case let .print_(msg) = printEvents[0].kind {
            #expect(msg == "hi")
        }
    }

    // MARK: - SHOULD-FIX 1: drive.forward(0) / backward(0) are no-ops

    @Test("drive.forward(0) leaves the robot pose unchanged")
    func driveForwardZeroIsNoOp() {
        let robot = RobotModel(pose: Pose(position: Vec2(x: 50, y: 50), headingDegrees: 0))
        let run = sim.run(program: "drive.forward(0);", world: openField(), robot: robot)
        #expect(run.completed)
        let finalPos = run.finalSnapshot?.pose.position
        #expect(abs((finalPos?.x ?? -1) - 50) < 0.01, "x should be unchanged")
        #expect(abs((finalPos?.y ?? -1) - 50) < 0.01, "y should be unchanged")
    }

    @Test("drive.backward(0) leaves the robot pose unchanged")
    func driveBackwardZeroIsNoOp() {
        let robot = RobotModel(pose: Pose(position: Vec2(x: 50, y: 50), headingDegrees: 0))
        let run = sim.run(program: "drive.backward(0);", world: openField(), robot: robot)
        #expect(run.completed)
        let finalPos = run.finalSnapshot?.pose.position
        #expect(abs((finalPos?.x ?? -1) - 50) < 0.01, "x should be unchanged")
        #expect(abs((finalPos?.y ?? -1) - 50) < 0.01, "y should be unchanged")
    }

    // MARK: - SHOULD-FIX 2: footprint radius blocks edge-entry even when centre is clear

    @Test("Robot with footprint radius is blocked before centre enters obstacle")
    func footprintRadiusBlocksEdgeEntry() {
        // Obstacle at x:90-110, y:50-70. Robot centre at (100, 30) facing north with
        // footprintRadius=18. After 1 cm the lead edge is at y=30+1+18=49, still clear.
        // After 2 cm the lead edge is at y=30+2+18=50, entering the obstacle — collision
        // fires while centre is at y=32, well outside the obstacle rect.
        let obstacle = FieldObstacle(id: "block", rect: FieldRect(x: 90, y: 50, width: 20, height: 20))
        let world = FieldWorld(id: "fp_test", name: "FP", widthCm: 300, heightCm: 300,
                               obstacles: [obstacle])
        // Robot with non-zero footprint
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 100, y: 30), headingDegrees: 0),
            footprintRadius: 18
        )
        let run = sim.run(program: "drive.forward(30);", world: world, robot: robot)
        // Should fail with collision even though the centre hasn't entered the obstacle
        if case .collision = run.failureKind { /* expected */ }
        else {
            Issue.record("Expected collision from footprint edge, got \(String(describing: run.failureKind))")
        }
        // Final centre position should be well below the obstacle (y < 50)
        let finalY = run.finalSnapshot?.pose.position.y ?? 999
        #expect(finalY < 50, "Centre should stop before entering obstacle; got y=\(finalY)")
    }

    // MARK: - SHOULD-FIX 3: color.isRed() logs sensor event → detectColorInZone

    @Test("color.isRed() satisfies detectColorInZone objective (same as color())")
    func colorIsRedSatisfiesDetectObjective() {
        // Field with a red region and a detection zone at the same location.
        let world = FieldWorld(
            id: "color_test", name: "Color", widthCm: 300, heightCm: 300,
            zones: [FieldZone(id: "detect_zone", kind: .detection,
                              rect: FieldRect(x: 80, y: 80, width: 40, height: 40))],
            coloredRegions: [ColoredRegion(id: "red_region",
                                            rect: FieldRect(x: 80, y: 80, width: 40, height: 40),
                                            color: "red")]
        )
        let mission = Mission(
            id: "m_color", fieldId: "color_test", title: "Detect Red", brief: "Find the red zone",
            objectives: [
                MissionObjective(id: "obj_detect", kind: .detectColorInZone, points: 25,
                                 description: "Detect red in zone",
                                 targetZoneId: "detect_zone", expectedColor: "red", isRequired: true)
            ],
            successRule: .allRequired
        )
        // Robot inside the zone, uses color.isRed() — not color() — to detect the tile
        let robot = RobotModel(pose: Pose(position: Vec2(x: 100, y: 100), headingDegrees: 0))
        let run = sim.run(program: "var r = color.isRed();", world: world, robot: robot, mission: mission)
        #expect(run.missionResult?.success == true,
                "color.isRed() should satisfy detectColorInZone just like color() does")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_detect") == true)
    }
}
