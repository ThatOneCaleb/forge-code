import Testing
@testable import ForgeCodeEngine

/// Engine tests for the interactive mechanism system: triggers (bump/armPress),
/// one-way activation, trace recording, gate obstacle-unlock, and the
/// `activateMechanism` objective.
@Suite("Field mechanisms (levers, gates, platforms)")
struct MechanismTests {

    private let sim = RoboticsSimulator()

    /// 200×200 test world: a bump lever mid-field, an armPress platform east,
    /// and a gate north whose activation removes the `gate_bar` obstacle
    /// blocking the corridor to `north_zone`.
    private func world() -> FieldWorld {
        FieldWorld(
            id: "field_mech_test", name: "Mechanism Test", widthCm: 200, heightCm: 200,
            zones: [
                FieldZone(id: "north_zone", kind: .goal,
                          rect: FieldRect(x: 80, y: 170, width: 40, height: 25))
            ],
            obstacles: [
                // Bar spanning the corridor at y 140-150, x 60-140
                FieldObstacle(id: "gate_bar", rect: FieldRect(x: 60, y: 140, width: 80, height: 10))
            ],
            mechanisms: [
                FieldMechanism(id: "mech_lever", kind: .lever,
                               position: Vec2(x: 100, y: 80), trigger: .bump),
                FieldMechanism(id: "mech_platform", kind: .platform,
                               position: Vec2(x: 160, y: 20), trigger: .armPress),
                // Gate switch on the west side; opening it removes gate_bar
                FieldMechanism(id: "mech_gate", kind: .gate,
                               position: Vec2(x: 30, y: 120), trigger: .bump,
                               unlocksObstacleId: "gate_bar")
            ],
            homePose: Pose(position: Vec2(x: 100, y: 20), headingDegrees: 0)
        )
    }

    private func robot() -> RobotModel {
        RobotModel(pose: Pose(position: Vec2(x: 100, y: 20), headingDegrees: 0),
                   armAngle: 0, isGripperOpen: true)
    }

    // MARK: - Bump trigger

    @Test("bump mechanism activates when driven into range, records trace")
    func bumpActivates() {
        // Drive north from (100,20) to (100,62) — within 22cm of lever at (100,80)
        let run = sim.run(program: "drive.forward(42);", world: world(), robot: robot())
        #expect(run.failureKind == nil)
        let final = run.finalSnapshot
        #expect(final?.mechanismStates.first { $0.id == "mech_lever" }?.isActivated == true)
        // Sensor log has the activation event with a valid frame index
        let events = run.sensorLog.compactMap { e -> String? in
            if case let .mechanismActivated(id) = e.kind { return id }
            return nil
        }
        #expect(events == ["mech_lever"])
        // Initial snapshot shows it un-activated
        #expect(run.snapshots.first?.mechanismStates.first { $0.id == "mech_lever" }?.isActivated == false)
    }

    @Test("bump mechanism does NOT activate from far away")
    func bumpOutOfRange() {
        let run = sim.run(program: "drive.forward(20);", world: world(), robot: robot())
        #expect(run.finalSnapshot?.mechanismStates.first { $0.id == "mech_lever" }?.isActivated == false)
    }

    @Test("activation is one-way and fires only once")
    func oneWay() {
        // Bump the lever, drive away, come back — still exactly one event
        let run = sim.run(
            program: "drive.forward(42); drive.backward(30); drive.forward(30);",
            world: world(), robot: robot())
        let events = run.sensorLog.filter {
            if case .mechanismActivated = $0.kind { return true }
            return false
        }
        #expect(events.count == 1)
    }

    // MARK: - armPress trigger

    @Test("armPress requires the arm lowered within range")
    func armPressGating() {
        // Robot near platform at (160,20): drive east from home
        let w = world()
        let program = """
        drive.turnRight(90);
        drive.forward(50);
        arm.lower();
        """
        let run = sim.run(program: program, world: w, robot: robot())
        #expect(run.finalSnapshot?.mechanismStates.first { $0.id == "mech_platform" }?.isActivated == true)

        // Same route WITHOUT lowering the arm → not activated (drive is bump-blind to armPress)
        let run2 = sim.run(program: "drive.turnRight(90); drive.forward(50);",
                           world: w, robot: robot())
        #expect(run2.finalSnapshot?.mechanismStates.first { $0.id == "mech_platform" }?.isActivated == false)
    }

    // MARK: - Gate unlock

    @Test("gate mechanism removes its linked obstacle, opening the corridor")
    func gateUnlocksObstacle() {
        let w = world()
        // WITHOUT opening the gate: driving north into the bar collides
        let blocked = sim.run(program: "drive.forward(160);", world: w, robot: robot())
        if case .collision(let obsId)? = blocked.failureKind {
            #expect(obsId == "gate_bar")
        } else {
            Issue.record("Expected collision with gate_bar, got \(String(describing: blocked.failureKind))")
        }

        // WITH the gate opened first: same corridor is clear all the way north
        let program = """
        drive.turnLeft(90);
        drive.forward(55);
        drive.turnRight(90);
        drive.forward(95);
        drive.turnRight(90);
        drive.forward(55);
        drive.turnLeft(90);
        drive.forward(65);
        """
        // Route: west to (45,20)? Actually: home (100,20) → west 55 → (45,20) heading W…
        // turnLeft from north = west; forward 55 → (45,20); turnRight → north; forward 95 → (45,115)
        // near gate switch (30,120): distance ≈ 15.8 ≤ 22 → gate opens, bar removed.
        // turnRight → east; forward 55 → (100,115); turnLeft → north; forward 65 → (100,180) inside north_zone.
        let open = sim.run(program: program, world: w, robot: robot())
        #expect(open.failureKind == nil,
                "Corridor should be clear after gate unlock, got \(String(describing: open.failureKind))")
        #expect(open.finalSnapshot?.mechanismStates.first { $0.id == "mech_gate" }?.isActivated == true)
        #expect((open.finalSnapshot?.pose.position.y ?? 0) > 165)
    }

    // MARK: - Objective scoring

    @Test("activateMechanism objective scores and gates success")
    func objectiveScoring() {
        let w = world()
        let mission = Mission(
            id: "m_test_mech", fieldId: w.id, title: "Tip the Lever",
            brief: "Tip the field lever, then return home.",
            objectives: [
                MissionObjective(id: "obj_lever", kind: .activateMechanism, points: 15,
                                 description: "Lever tipped",
                                 targetMechanismId: "mech_lever", isRequired: true)
            ],
            successRule: .allRequired, difficulty: 2
        )
        let win = sim.run(program: "drive.forward(42);", world: w, robot: robot(), mission: mission)
        #expect(win.missionResult?.success == true)
        #expect(win.missionResult?.score == 15)

        let lose = sim.run(program: "drive.forward(10);", world: w, robot: robot(), mission: mission)
        #expect(lose.missionResult?.success == false)
        #expect(lose.missionResult?.score == 0)
    }

    // MARK: - Loader

    @Test("loader decodes mechanisms and activateMechanism objectives from JSON")
    func loaderDecodes() throws {
        // The shipped Mars Outpost field carries mechanisms (added with this feature).
        let w = try #require(try RoboticsLibrary.field(id: "field_arena"))
        #expect(!w.mechanisms.isEmpty, "field_arena should ship at least one mechanism")
        for mech in w.mechanisms {
            #expect(!mech.id.isEmpty)
            #expect(mech.triggerRadius > 0)
            if let obsId = mech.unlocksObstacleId {
                #expect(w.obstacle(id: obsId) != nil,
                        "unlocksObstacleId '\(obsId)' must reference a real obstacle")
            }
        }
    }
}
