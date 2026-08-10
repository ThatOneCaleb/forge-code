import Testing
@testable import ForgeCodeEngine

/// Tests for the JSON-driven content layer: fields, missions, and end-to-end
/// pipeline (JSON → FieldWorld/Mission → RoboticsSimulator → RoboticsRun).
@Suite("RoboticsLibrary content loading & seed missions")
struct RoboticsContentTests {

    // MARK: - Field loading

    @Test("RoboticsLibrary loads at least 2 seed fields")
    func loadsFields() throws {
        let fields = try RoboticsLibrary.fields()
        #expect(fields.count >= 2)
    }

    @Test("Cargo Command field has expected id and items")
    func warehouseField() throws {
        let field = try RoboticsLibrary.field(id: "field_warehouse")
        #expect(field != nil)
        #expect(field?.name == "Cargo Command")
        #expect(field?.items.count ?? 0 >= 2)
        let hasRedCrate = field?.items.contains { $0.id == "crate_A" } == true
        #expect(hasRedCrate)
    }

    @Test("Mars Outpost field has expected id, name, and 300x300 bounds")
    func arenaField() throws {
        let field = try RoboticsLibrary.field(id: "field_arena")
        #expect(field != nil)
        #expect(field?.name == "Mars Outpost")
        #expect(field?.widthCm == 300)
        #expect(field?.heightCm == 300)
    }

    @Test("Mars Outpost field has correct element counts")
    func marsOutpostElementCounts() throws {
        let field = try #require(try RoboticsLibrary.field(id: "field_arena"))
        #expect(field.items.count == 7, "Expected 7 sample/core/cell items")
        #expect(field.zones.count == 7, "Expected 7 zones (2 bays + 2 pads + launch + base_camp + relay)")
        #expect(field.obstacles.count == 6, "Expected 6 obstacles (boulder ring x3 + crater_rim + scatter + nook_gate_bar)")
        #expect(field.lines.count == 3, "Expected 3 rover track polylines")
        #expect(field.coloredRegions.count == 4, "Expected 4 colored regions")
    }

    @Test("Mars Outpost field has named landmark items and zones")
    func marsOutpostLandmarks() throws {
        let field = try #require(try RoboticsLibrary.field(id: "field_arena"))
        // Key items
        #expect(field.items.contains { $0.id == "core_delta" && $0.type == "core" })
        #expect(field.items.contains { $0.id == "rock_alpha" && $0.color == "red" })
        #expect(field.items.contains { $0.id == "cell_ion" && $0.type == "cell" })
        // Key zones
        #expect(field.zones.contains { $0.id == "base_camp" })
        #expect(field.zones.contains { $0.id == "bay_alpha" && $0.acceptsItemType == "sample" })
        #expect(field.zones.contains { $0.id == "solar_pad" && $0.kind == .detection })
        #expect(field.zones.contains { $0.id == "relay_station" && $0.acceptsItemType == "cell" })
        // Signature obstacles
        #expect(field.obstacles.contains { $0.id == "boulder_W" })
        #expect(field.obstacles.contains { $0.id == "crater_rim" })
        #expect(field.obstacles.contains { $0.id == "boulder_scatter" })
        // Rover tracks
        #expect(field.lines.contains { $0.id == "track_base_to_relay" })
        #expect(field.lines.contains { $0.id == "track_main_north" })
    }

    @Test("Fields have valid bounds (widthCm > 0, heightCm > 0)")
    func fieldBoundsValid() throws {
        let fields = try RoboticsLibrary.fields()
        for field in fields {
            #expect(field.widthCm > 0, "Field \(field.id) widthCm must be > 0")
            #expect(field.heightCm > 0, "Field \(field.id) heightCm must be > 0")
        }
    }

    @Test("Fields have non-empty ids and names")
    func fieldIdentifiers() throws {
        let fields = try RoboticsLibrary.fields()
        for field in fields {
            #expect(!field.id.isEmpty)
            #expect(!field.name.isEmpty)
        }
    }

    // MARK: - Mission loading

    @Test("RoboticsLibrary loads at least 3 seed missions")
    func loadsMissions() throws {
        let missions = try RoboticsLibrary.missions()
        #expect(missions.count >= 3)
    }

    @Test("Each mission references a valid fieldId")
    func missionFieldRefs() throws {
        let missions = try RoboticsLibrary.missions()
        let fieldIds = try Set(RoboticsLibrary.fields().map { $0.id })
        for mission in missions {
            #expect(fieldIds.contains(mission.fieldId),
                    "Mission \(mission.id) references unknown fieldId '\(mission.fieldId)'")
        }
    }

    @Test("Missions have non-empty titles and briefs")
    func missionText() throws {
        let missions = try RoboticsLibrary.missions()
        for m in missions {
            #expect(!m.title.isEmpty)
            #expect(!m.brief.isEmpty)
        }
    }

    @Test("All mission objectives have positive point values")
    func missionObjectivePoints() throws {
        let missions = try RoboticsLibrary.missions()
        for m in missions {
            for obj in m.objectives {
                #expect(obj.points > 0, "Objective \(obj.id) in mission \(m.id) must have > 0 points")
            }
        }
    }

    @Test("Fetch-red-crate mission has required arm+gripper objectives")
    func fetchRedCrateMission() throws {
        let mission = try RoboticsLibrary.mission(id: "mission_fetch_red_crate")
        #expect(mission != nil)
        let pickupObj  = mission?.objectives.first { $0.kind == .pickUpItem }
        let depositObj = mission?.objectives.first { $0.kind == .depositItemInZone }
        #expect(pickupObj  != nil, "Must have a pickUpItem objective")
        #expect(depositObj != nil, "Must have a depositItemInZone objective")
        #expect(pickupObj?.isRequired  == true)
        #expect(depositObj?.isRequired == true)
    }

    // MARK: - End-to-end: seed mission 1 (reach goal)

    @Test("Seed mission 'reach goal' succeeds with a correct drive program")
    func seedMissionReachGoalSuccess() throws {
        let world = try #require(try RoboticsLibrary.field(id: "field_warehouse"))
        let mission = try #require(try RoboticsLibrary.mission(id: "mission_reach_goal"))

        let sim = RoboticsSimulator()
        // Start at (120,10) heading north and drive into the goal zone at (100-140, 100-140)
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 120, y: 10), headingDegrees: 0)
        )
        let run = sim.run(program: "drive.forward(110);", world: world, robot: robot, mission: mission)
        #expect(run.missionResult?.success == true)
        #expect(run.missionResult?.score == 10)
    }

    @Test("Seed mission 'reach goal' fails when robot doesn't reach the zone")
    func seedMissionReachGoalFail() throws {
        let world = try #require(try RoboticsLibrary.field(id: "field_warehouse"))
        let mission = try #require(try RoboticsLibrary.mission(id: "mission_reach_goal"))
        let sim = RoboticsSimulator()
        let robot = RobotModel(pose: Pose(position: Vec2(x: 120, y: 10), headingDegrees: 0))
        // Only drive 30 cm — doesn't reach the goal zone at y≥100
        let run = sim.run(program: "drive.forward(30);", world: world, robot: robot, mission: mission)
        #expect(run.missionResult?.success == false)
    }

    // MARK: - End-to-end: seed mission 2 (fetch red crate — requires arm+gripper)

    @Test("Seed mission 'fetch red crate' fails with drive-only program (score = 0)")
    func seedMissionFetchCrateDriveOnly() throws {
        let world = try #require(try RoboticsLibrary.field(id: "field_warehouse"))
        let mission = try #require(try RoboticsLibrary.mission(id: "mission_fetch_red_crate"))
        let sim = RoboticsSimulator()
        let robot = RobotModel(pose: Pose(position: Vec2(x: 120, y: 10), headingDegrees: 0))
        // Drive-only: never uses arm/gripper
        let run = sim.run(program: "drive.forward(50);", world: world, robot: robot, mission: mission)
        #expect(run.missionResult?.success == false)
        #expect(run.missionResult?.score == 0)
        #expect(run.missionResult?.metObjectiveIds.isEmpty == true)
    }

    @Test("Seed mission 'fetch red crate' awards pickup points with arm+gripper")
    func seedMissionFetchCratePickup() throws {
        let world = try #require(try RoboticsLibrary.field(id: "field_warehouse"))
        let mission = try #require(try RoboticsLibrary.mission(id: "mission_fetch_red_crate"))
        let sim = RoboticsSimulator()
        // crate_A is at (60,180). Start robot at (60,165) heading north, arm raised.
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 60, y: 165), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        // Drive to crate, lower arm, close gripper (pickup)
        let program = """
        drive.forward(15);
        arm.lower();
        gripper.close();
        """
        let run = sim.run(program: program, world: world, robot: robot, mission: mission)
        let picked = run.missionResult?.metObjectiveIds.contains("obj_pickup_red")
        #expect(picked == true, "Should have picked up the crate")
        #expect((run.missionResult?.score ?? 0) >= 8)
    }

    // MARK: - End-to-end: full run mission (score threshold)

    /// Verified solution for mission_full_run (scoreThreshold: 20).
    ///
    /// Field geometry used (field_warehouse / Cargo Command, 240×240 cm):
    ///   red_tile / color_sensor_zone : x:80-120, y:80-120
    ///   shelf_1 obstacle             : x:90-150, y:130-150  (centre-point collision)
    ///   crate_A (red, pickupRadius 15): (60, 180)
    ///   depot_red                    : x:10-60, y:10-60
    ///
    /// Route (start (100,10) heading north):
    ///   1. forward 80 cm  → (100, 90)  [inside color_sensor_zone + red_tile]
    ///   2. color.isRed()  → logs .color("red") → satisfies obj_detect_red (8 pts)
    ///   3. turnLeft 90°   → heading 270° (west)
    ///   4. forward 40 cm  → (60, 90)   [clear of shelf at x:90+]
    ///   5. turnRight 90°  → heading 0° (north)
    ///   6. forward 90 cm  → (60, 180)  [at crate_A; x=60 avoids shelf x:90-150]
    ///   7. arm.lower(); gripper.close() → picks up crate_A (10 pts)
    ///   8. arm.raise()
    ///   9. turnRight 180° → heading 180° (south)
    ///  10. forward 170 cm → (60, 10)
    ///  11. turnRight 90°  → heading 270° (west)
    ///  12. forward 25 cm  → (35, 10)   [inside depot_red x:10-60, y:10-60]
    ///  13. gripper.open() → deposits crate_A in depot_red (12 pts)
    ///
    /// Total = 8 + 10 + 12 = 30 pts ≥ threshold 20 → success = true.
    @Test("Full run mission succeeds with verified solution (30 pts, threshold 20)")
    func seedMissionFullRunSuccess() throws {
        let world = try #require(try RoboticsLibrary.field(id: "field_warehouse"))
        let mission = try #require(try RoboticsLibrary.mission(id: "mission_full_run"))
        let sim = RoboticsSimulator()
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 100, y: 10), headingDegrees: 0),
            armAngle: 0, isGripperOpen: true
        )
        let program = """
        drive.forward(80);
        color.isRed();
        drive.turnLeft(90);
        drive.forward(40);
        drive.turnRight(90);
        drive.forward(90);
        arm.lower();
        gripper.close();
        arm.raise();
        drive.turnRight(180);
        drive.forward(170);
        drive.turnRight(90);
        drive.forward(25);
        gripper.open();
        """
        let run = sim.run(program: program, world: world, robot: robot, mission: mission)
        #expect(run.missionResult?.success == true,
                "Verified solution should score ≥ 20 pts and succeed")
        #expect((run.missionResult?.score ?? 0) >= 20,
                "Expected ≥ 20 pts, got \(run.missionResult?.score ?? -1)")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_detect_red") == true,
                "Should satisfy detectColorInZone objective via color.isRed()")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_pickup_crate") == true,
                "Should satisfy pickUpItem objective")
        #expect(run.missionResult?.metObjectiveIds.contains("obj_deposit_crate") == true,
                "Should satisfy depositItemInZone objective")
    }

    @Test("Full run mission fails with drive-only program (score = 0, below threshold)")
    func seedMissionFullRunDriveOnlyFails() throws {
        let world = try #require(try RoboticsLibrary.field(id: "field_warehouse"))
        let mission = try #require(try RoboticsLibrary.mission(id: "mission_full_run"))
        let sim = RoboticsSimulator()
        let robot = RobotModel(
            pose: Pose(position: Vec2(x: 100, y: 10), headingDegrees: 0)
        )
        // Drive-only program: never uses arm, gripper, or color sensor
        let run = sim.run(program: "drive.forward(80);", world: world, robot: robot, mission: mission)
        #expect(run.missionResult?.success == false,
                "Drive-only should not reach the 20 pt threshold")
        #expect((run.missionResult?.score ?? 999) == 0,
                "Drive-only should score 0 (no detection, no pickup, no deposit)")
    }

    // MARK: - SHOULD-FIX 5: unknown enum strings throw decoding errors

    @Test("Unknown zone kind string throws LoadError during decoding")
    func unknownZoneKindThrows() throws {
        // Build minimal JSON with a zone that has an invalid kind string.
        let badFieldJSON = """
        [{
            "id": "bad_field", "name": "Bad", "widthCm": 100, "heightCm": 100,
            "zones": [{ "id": "z1", "kind": "unknownKind",
                        "rect": { "x": 0, "y": 0, "width": 10, "height": 10 } }]
        }]
        """.data(using: .utf8)!
        #expect(throws: (any Error).self) {
            try RoboticsLibrary.decodeFields(from: badFieldJSON)
        }
    }

    @Test("Unknown objective kind string throws LoadError during decoding")
    func unknownObjectiveKindThrows() throws {
        let badMissionJSON = """
        [{
            "id": "bad_m", "fieldId": "f", "title": "T", "brief": "B",
            "successRule": { "type": "allRequired" },
            "objectives": [{ "id": "o1", "kind": "badKind", "points": 10,
                             "description": "D" }]
        }]
        """.data(using: .utf8)!
        #expect(throws: (any Error).self) {
            try RoboticsLibrary.decodeMissions(from: badMissionJSON)
        }
    }

    @Test("Unknown successRule type throws LoadError during decoding")
    func unknownSuccessRuleThrows() throws {
        let badMissionJSON = """
        [{
            "id": "bad_m2", "fieldId": "f", "title": "T", "brief": "B",
            "successRule": { "type": "badRuleType" },
            "objectives": [{ "id": "o1", "kind": "reachZone", "points": 10,
                             "description": "D" }]
        }]
        """.data(using: .utf8)!
        #expect(throws: (any Error).self) {
            try RoboticsLibrary.decodeMissions(from: badMissionJSON)
        }
    }

    // MARK: - difficulty field

    @Test("Seed missions have expected difficulty values (1, 2, 3)")
    func seedMissionDifficulties() throws {
        let reach  = try #require(try RoboticsLibrary.mission(id: "mission_reach_goal"))
        let fetch  = try #require(try RoboticsLibrary.mission(id: "mission_fetch_red_crate"))
        let full   = try #require(try RoboticsLibrary.mission(id: "mission_full_run"))
        #expect(reach.difficulty == 1)
        #expect(fetch.difficulty == 2)
        #expect(full.difficulty  == 3)
    }

    @Test("Mission JSON without 'difficulty' key defaults to 1")
    func difficultyDefaultsToOne() throws {
        let json = """
        [{
            "id": "m_no_diff", "fieldId": "f", "title": "T", "brief": "B",
            "successRule": { "type": "allRequired" },
            "objectives": [{ "id": "o1", "kind": "reachZone", "points": 10,
                             "description": "D", "targetZoneId": "z" }]
        }]
        """.data(using: .utf8)!
        let missions = try RoboticsLibrary.decodeMissions(from: json)
        #expect(missions.first?.difficulty == 1)
    }

    @Test("Mission JSON with difficulty 0 is clamped to 1")
    func difficultyClampedBelow() throws {
        let json = """
        [{
            "id": "m_diff_low", "fieldId": "f", "title": "T", "brief": "B",
            "difficulty": 0,
            "successRule": { "type": "allRequired" },
            "objectives": [{ "id": "o1", "kind": "reachZone", "points": 10,
                             "description": "D", "targetZoneId": "z" }]
        }]
        """.data(using: .utf8)!
        let missions = try RoboticsLibrary.decodeMissions(from: json)
        #expect(missions.first?.difficulty == 1, "difficulty 0 should be clamped to 1")
    }

    @Test("Mission JSON with difficulty 99 is clamped to 5")
    func difficultyClampedAbove() throws {
        let json = """
        [{
            "id": "m_diff_high", "fieldId": "f", "title": "T", "brief": "B",
            "difficulty": 99,
            "successRule": { "type": "allRequired" },
            "objectives": [{ "id": "o1", "kind": "reachZone", "points": 10,
                             "description": "D", "targetZoneId": "z" }]
        }]
        """.data(using: .utf8)!
        let missions = try RoboticsLibrary.decodeMissions(from: json)
        #expect(missions.first?.difficulty == 5, "difficulty 99 should be clamped to 5")
    }

    @Test("Mission JSON with in-range difficulty 3 decodes exactly")
    func difficultyInRangeDecodes() throws {
        let json = """
        [{
            "id": "m_diff_3", "fieldId": "f", "title": "T", "brief": "B",
            "difficulty": 3,
            "successRule": { "type": "allRequired" },
            "objectives": [{ "id": "o1", "kind": "reachZone", "points": 10,
                             "description": "D", "targetZoneId": "z" }]
        }]
        """.data(using: .utf8)!
        let missions = try RoboticsLibrary.decodeMissions(from: json)
        #expect(missions.first?.difficulty == 3)
    }

    // MARK: - maxActions field

    @Test("Mission JSON with 'maxActions' key decodes the value")
    func maxActionsDecodes() throws {
        let json = """
        [{
            "id": "m_capped", "fieldId": "f", "title": "T", "brief": "B",
            "maxActions": 10,
            "successRule": { "type": "allRequired" },
            "objectives": [{ "id": "o1", "kind": "reachZone", "points": 10,
                             "description": "D", "targetZoneId": "z" }]
        }]
        """.data(using: .utf8)!
        let missions = try RoboticsLibrary.decodeMissions(from: json)
        #expect(missions.first?.maxActions == 10)
    }

    @Test("Mission JSON without 'maxActions' key yields nil")
    func maxActionsNilWhenAbsent() throws {
        let json = """
        [{
            "id": "m_uncapped", "fieldId": "f", "title": "T", "brief": "B",
            "successRule": { "type": "allRequired" },
            "objectives": [{ "id": "o1", "kind": "reachZone", "points": 10,
                             "description": "D", "targetZoneId": "z" }]
        }]
        """.data(using: .utf8)!
        let missions = try RoboticsLibrary.decodeMissions(from: json)
        #expect(missions.first?.maxActions == nil)
    }

    @Test("Original seed missions have nil maxActions (no per-mission cap by default)")
    func seedMissionsHaveNoMaxActions() throws {
        // The three original R1 seed missions were designed without action caps.
        // Batch-1/2 missions may intentionally carry a maxActions for efficiency pressure.
        let originalSeedIds: Set<String> = [
            "mission_reach_goal", "mission_fetch_red_crate", "mission_full_run"
        ]
        let missions = try RoboticsLibrary.missions()
        for mission in missions where originalSeedIds.contains(mission.id) {
            #expect(mission.maxActions == nil,
                    "Original seed mission '\(mission.id)' should not have a maxActions cap")
        }
    }

    // MARK: - Determinism with loaded content

    @Test("Same program + loaded world produces identical run (determinism)")
    func deterministicWithLoadedContent() throws {
        let world = try #require(try RoboticsLibrary.field(id: "field_warehouse"))
        let mission = try #require(try RoboticsLibrary.mission(id: "mission_reach_goal"))
        let sim = RoboticsSimulator()
        let robot = RobotModel(pose: Pose(position: Vec2(x: 120, y: 10), headingDegrees: 0))
        let prog = "drive.forward(110);"
        let run1 = sim.run(program: prog, world: world, robot: robot, mission: mission)
        let run2 = sim.run(program: prog, world: world, robot: robot, mission: mission)
        #expect(run1 == run2)
    }
}
