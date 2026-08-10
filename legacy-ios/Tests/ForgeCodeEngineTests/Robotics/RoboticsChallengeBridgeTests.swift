import Testing
@testable import ForgeCodeEngine

@Suite("Robotics challenge bridge")
struct RoboticsChallengeBridgeTests {

    private func challenge(_ diff: ChallengeDifficulty? = .hard) -> Challenge {
        Challenge(grid: Grid(width: 8, height: 8, obstacles: []),
                  start: RobotState(position: Position(x: 0, y: 0), facing: .up),
                  goal: Position(x: 7, y: 7),
                  allowedCommands: [.move], difficulty: diff)
    }

    @Test("generated board scales with order and always has crystals + walls")
    func scaling() {
        let a = RoboticsChallengeBridge.generate(order: 1)
        let b = RoboticsChallengeBridge.generate(order: 60)
        #expect(a.size >= 10)
        #expect(b.size > a.size)          // later challenges are bigger
        #expect(b.gems.count >= a.gems.count)
        #expect(!a.walls.isEmpty)
        #expect(a.gems.count >= 1)
    }

    @Test("every crystal and the goal are reachable from the start")
    func solvable() {
        for order in [1, 7, 25, 48, 100] {
            let l = RoboticsChallengeBridge.generate(order: order)
            let reachable = RoboticsChallengeBridge.floodFill(
                from: l.start, size: l.size, walls: l.walls)
            #expect(reachable.contains(l.goal), "goal unreachable at order \(order)")
            for g in l.gems {
                #expect(reachable.contains(g), "gem \(g) unreachable at order \(order)")
            }
            // start/goal never walled
            #expect(!l.walls.contains(l.start))
            #expect(!l.walls.contains(l.goal))
        }
    }

    @Test("generation is deterministic for a given order")
    func deterministic() {
        let a = RoboticsChallengeBridge.generate(order: 42)
        let b = RoboticsChallengeBridge.generate(order: 42)
        #expect(a.walls == b.walls)
        #expect(a.gems == b.gems)
        #expect(a.size == b.size)
    }

    @Test("world + mission wire up: goal zone required, gems scored via visitTile")
    func worldMission() {
        let (world, mission) = RoboticsChallengeBridge.make(
            from: challenge(), order: 20, id: "c20", title: "T", brief: "B")
        #expect(world.zone(id: "goal_zone") != nil)
        #expect(world.items.count == mission.objectives.filter { $0.kind == .visitTile }.count)
        #expect(mission.objectives.contains { $0.kind == .reachZone && $0.isRequired })
        // A run that only sits still fails (doesn't reach goal / collect).
        let idle = RoboticsSimulator().run(program: "wait(1);", world: world,
                                           robot: RobotModel(pose: world.resolvedHomePose),
                                           mission: mission)
        #expect(idle.missionResult?.success == false)
    }

    @Test("driving over a crystal scores its visitTile objective")
    func visitScores() {
        // Tiny deterministic world: one gem straight ahead of the rover.
        let world = FieldWorld(
            id: "cx", name: "x", widthCm: 150, heightCm: 150,
            items: [FieldItem(id: "gem_0", position: Vec2(x: 15, y: 45))],
            zones: [FieldZone(id: "goal_zone", kind: .goal,
                              rect: FieldRect(x: 0, y: 60, width: 30, height: 30))],
            homePose: Pose(position: Vec2(x: 15, y: 15), headingDegrees: 0))
        let mission = Mission(
            id: "cx", fieldId: "cx", title: "T", brief: "B",
            objectives: [
                MissionObjective(id: "reach_goal", kind: .reachZone, points: 0,
                                 description: "goal", targetZoneId: "goal_zone", isRequired: true),
                MissionObjective(id: "gem_0", kind: .visitTile, points: 1,
                                 description: "gem", targetX: 15, targetY: 45, toleranceCm: 16)
            ],
            successRule: .allRequiredAndScore(1))
        let run = RoboticsSimulator().run(
            program: "drive.forward(60);", world: world,
            robot: RobotModel(pose: world.resolvedHomePose), mission: mission)
        #expect(run.missionResult?.success == true)
        #expect(run.missionResult?.metObjectiveIds.contains("gem_0") == true)
    }
}
