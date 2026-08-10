import Testing
import Foundation
@testable import ForgeCodeEngine

// MARK: - Helpers

/// Builds a grid of the given size with optional obstacles, terrain, and items.
private func makeGrid(
    width: Int = 6,
    height: Int = 6,
    obstacles: Set<Position> = [],
    terrain: [Position: TerrainKind] = [:],
    items: [GridItem] = []
) -> Grid {
    Grid(width: width, height: height, obstacles: obstacles, terrain: terrain, items: items)
}

/// Builds a challenge from a grid, placing the robot at `start` and the goal
/// at `goal`. All commands allowed; no block budget by default.
private func makeChallenge(
    grid: Grid,
    start: RobotState,
    goal: Position,
    collectGoal: Int? = nil,
    parMoves: Int? = nil
) -> Challenge {
    Challenge(
        grid: grid,
        start: start,
        goal: goal,
        allowedCommands: CommandKind.allCases,
        collectGoal: collectGoal,
        parMoves: parMoves
    )
}

// MARK: - Ice terrain

@Suite("Ice terrain")
struct IceTerrainTests {

    private let sim = Simulator()

    @Test("Robot on ice slides 2 cells forward when both clear")
    func iceSlidesTwo() {
        // Robot at (0,0) facing right. Ice at (1,0). (2,0) is clear.
        // After move(): lands on (1,0), ice triggers slide to (2,0).
        let grid = makeGrid(
            width: 6, height: 6,
            terrain: [Position(x: 1, y: 0): .ice]
        )
        let start = RobotState(position: Position(x: 0, y: 0), facing: .right)
        let challenge = makeChallenge(grid: grid, start: start, goal: Position(x: 2, y: 0))
        let result = sim.run(program: Program(commands: [.move]), challenge: challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == Position(x: 2, y: 0))
    }

    @Test("Robot on ice stops at 1 cell when the slide cell is an obstacle")
    func iceBlockedByObstacle() {
        // Ice at (1,0), obstacle at (2,0). Slide is blocked → robot stays at (1,0).
        let grid = makeGrid(
            width: 6, height: 6,
            obstacles: [Position(x: 2, y: 0)],
            terrain: [Position(x: 1, y: 0): .ice]
        )
        let start = RobotState(position: Position(x: 0, y: 0), facing: .right)
        let challenge = makeChallenge(grid: grid, start: start, goal: Position(x: 1, y: 0))
        let result = sim.run(program: Program(commands: [.move]), challenge: challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == Position(x: 1, y: 0))
    }

    @Test("Robot on ice stops at 1 cell when the slide cell is OOB")
    func iceBlockedByEdge() {
        // Grid 3 wide. Ice at (2,0) (right edge). Slide would go to (3,0) — OOB.
        let grid = makeGrid(
            width: 3, height: 3,
            terrain: [Position(x: 2, y: 0): .ice]
        )
        let start = RobotState(position: Position(x: 1, y: 0), facing: .right)
        let challenge = makeChallenge(grid: grid, start: start, goal: Position(x: 2, y: 0))
        let result = sim.run(program: Program(commands: [.move]), challenge: challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == Position(x: 2, y: 0))
    }

    @Test("Ice does not apply recursively on the slide destination cell")
    func iceNotRecursive() {
        // Ice at (1,0) AND at (2,0). Robot should land on (2,0) after 1 move
        // but should NOT then slide again to (3,0).
        let grid = makeGrid(
            width: 6, height: 6,
            terrain: [
                Position(x: 1, y: 0): .ice,
                Position(x: 2, y: 0): .ice
            ]
        )
        let start = RobotState(position: Position(x: 0, y: 0), facing: .right)
        // Goal at (2,0); if recursive slide happened the robot would be at (3+,0).
        let challenge = makeChallenge(grid: grid, start: start, goal: Position(x: 2, y: 0))
        let result = sim.run(program: Program(commands: [.move]), challenge: challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == Position(x: 2, y: 0))
    }
}

// MARK: - Mud terrain

@Suite("Mud terrain")
struct MudTerrainTests {

    private let sim = Simulator()

    @Test("Moving through mud costs 2 move-steps")
    func mudCostsTwo() {
        let grid = makeGrid(terrain: [Position(x: 1, y: 0): .mud])
        let start = RobotState(position: Position(x: 0, y: 0), facing: .right)
        let challenge = makeChallenge(grid: grid, start: start, goal: Position(x: 1, y: 0))
        let result = sim.run(program: Program(commands: [.move]), challenge: challenge)
        #expect(result.isSuccess)
        #expect(result.moveStepsUsed == 2)
    }

    @Test("Moving through normal terrain costs 1 move-step")
    func normalCostsOne() {
        let grid = makeGrid()
        let start = RobotState(position: Position(x: 0, y: 0), facing: .right)
        let challenge = makeChallenge(grid: grid, start: start, goal: Position(x: 1, y: 0))
        let result = sim.run(program: Program(commands: [.move]), challenge: challenge)
        #expect(result.isSuccess)
        #expect(result.moveStepsUsed == 1)
    }

    @Test("Mixed mud and normal terrain accumulates correctly")
    func mudAndNormalMixed() {
        // Two moves: normal (1,0) then mud (2,0) → total 3 steps
        let grid = makeGrid(terrain: [Position(x: 2, y: 0): .mud])
        let start = RobotState(position: Position(x: 0, y: 0), facing: .right)
        let challenge = makeChallenge(grid: grid, start: start, goal: Position(x: 2, y: 0))
        let result = sim.run(program: Program(commands: [.move, .move]), challenge: challenge)
        #expect(result.isSuccess)
        #expect(result.moveStepsUsed == 3)
    }
}

// MARK: - Conveyor terrain

@Suite("Conveyor terrain")
struct ConveyorTerrainTests {

    private let sim = Simulator()

    @Test("Conveyor pushes robot one cell in conveyor direction after landing")
    func conveyorPushes() {
        // Robot at (0,0) facing right. Conveyor north at (1,0).
        // After move(): lands on (1,0), conveyor pushes to (1,1).
        let grid = makeGrid(terrain: [Position(x: 1, y: 0): .conveyorNorth])
        let start = RobotState(position: Position(x: 0, y: 0), facing: .right)
        let challenge = makeChallenge(grid: grid, start: start, goal: Position(x: 1, y: 1))
        let result = sim.run(program: Program(commands: [.move]), challenge: challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == Position(x: 1, y: 1))
    }

    @Test("Conveyor at grid edge — robot stays put, no failure")
    func conveyorAtEdge() {
        // Conveyor pushes south from (1,0) — target would be (1,-1) which is OOB.
        // Robot stays at (1,0).
        let grid = makeGrid(terrain: [Position(x: 1, y: 0): .conveyorSouth])
        let start = RobotState(position: Position(x: 0, y: 0), facing: .right)
        let challenge = makeChallenge(grid: grid, start: start, goal: Position(x: 1, y: 0))
        let result = sim.run(program: Program(commands: [.move]), challenge: challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == Position(x: 1, y: 0))
    }

    @Test("Conveyor pushed into obstacle — robot stays put, no failure")
    func conveyorBlockedByObstacle() {
        // Conveyor east at (1,0), obstacle at (2,0). Robot stays at (1,0).
        let grid = makeGrid(
            obstacles: [Position(x: 2, y: 0)],
            terrain: [Position(x: 1, y: 0): .conveyorEast]
        )
        let start = RobotState(position: Position(x: 0, y: 0), facing: .right)
        let challenge = makeChallenge(grid: grid, start: start, goal: Position(x: 1, y: 0))
        let result = sim.run(program: Program(commands: [.move]), challenge: challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == Position(x: 1, y: 0))
    }

    @Test("Conveyor west pushes the robot one cell to the left")
    func conveyorWest() {
        // Robot at (0,1) facing up. Conveyor west at (0,2).
        // After move(): lands on (0,2), conveyor pushes west to (-1,2) — OOB → stays.
        // Use a scenario where push succeeds: conveyor at (2,0), robot approaches from left.
        let grid = makeGrid(terrain: [Position(x: 2, y: 0): .conveyorWest])
        let start = RobotState(position: Position(x: 1, y: 0), facing: .right)
        // After move to (2,0), conveyor pushes west to (1,0).
        let challenge = makeChallenge(grid: grid, start: start, goal: Position(x: 1, y: 0))
        let result = sim.run(program: Program(commands: [.move]), challenge: challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == Position(x: 1, y: 0))
    }

    @Test("Conveyor does not apply recursively on the push destination")
    func conveyorNotRecursive() {
        // Conveyor north at (1,0) AND at (1,1). After move to (1,0), push to (1,1).
        // The conveyor at (1,1) must NOT push again to (1,2).
        let grid = makeGrid(
            terrain: [
                Position(x: 1, y: 0): .conveyorNorth,
                Position(x: 1, y: 1): .conveyorNorth
            ]
        )
        let start = RobotState(position: Position(x: 0, y: 0), facing: .right)
        let challenge = makeChallenge(grid: grid, start: start, goal: Position(x: 1, y: 1))
        let result = sim.run(program: Program(commands: [.move]), challenge: challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == Position(x: 1, y: 1))
    }
}

// MARK: - Portal terrain

@Suite("Portal terrain")
struct PortalTerrainTests {

    private let sim = Simulator()

    @Test("Robot stepping on portal A teleports to portal B position")
    func portalTeleports() {
        // Portal "A" at (1,0) and (4,4). Robot moves into (1,0) → teleports to (4,4).
        let grid = makeGrid(
            terrain: [
                Position(x: 1, y: 0): .portal("A"),
                Position(x: 4, y: 4): .portal("A")
            ]
        )
        let start = RobotState(position: Position(x: 0, y: 0), facing: .right)
        let challenge = makeChallenge(grid: grid, start: start, goal: Position(x: 4, y: 4))
        let result = sim.run(program: Program(commands: [.move]), challenge: challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == Position(x: 4, y: 4))
    }

    @Test("Portal with no matching partner treats cell as normal")
    func portalNoMatch() {
        // Only one portal "X" at (1,0). Robot lands on it — no teleport.
        let grid = makeGrid(terrain: [Position(x: 1, y: 0): .portal("X")])
        let start = RobotState(position: Position(x: 0, y: 0), facing: .right)
        // Goal at (1,0) — robot should be there after the move without moving elsewhere.
        let challenge = makeChallenge(grid: grid, start: start, goal: Position(x: 1, y: 0))
        let result = sim.run(program: Program(commands: [.move]), challenge: challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == Position(x: 1, y: 0))
    }

    @Test("Facing is preserved after portal teleport")
    func portalPreservesFacing() {
        let grid = makeGrid(
            terrain: [
                Position(x: 1, y: 0): .portal("B"),
                Position(x: 3, y: 3): .portal("B")
            ]
        )
        let start = RobotState(position: Position(x: 0, y: 0), facing: .right)
        let challenge = makeChallenge(grid: grid, start: start, goal: Position(x: 3, y: 3))
        let result = sim.run(program: Program(commands: [.move]), challenge: challenge)
        #expect(result.frames.last?.facing == .right)
    }
}

// MARK: - Collectibles

@Suite("Collectible items")
struct CollectibleTests {

    private let sim = Simulator()

    @Test("Robot walking over an item auto-collects it")
    func autoCollect() {
        let gem = GridItem(id: "gem-1", position: Position(x: 1, y: 0), kind: .collectible)
        let grid = makeGrid(items: [gem])
        let start = RobotState(position: Position(x: 0, y: 0), facing: .right)
        let challenge = makeChallenge(grid: grid, start: start, goal: Position(x: 1, y: 0))
        let result = sim.run(program: Program(commands: [.move]), challenge: challenge)
        #expect(result.isSuccess)
        #expect(result.itemsCollected.contains("gem-1"))
    }

    @Test("Challenge with collectGoal: success only when all collected AND at goal")
    func collectGoalSuccess() {
        let gem1 = GridItem(id: "gem-1", position: Position(x: 1, y: 0), kind: .collectible)
        let gem2 = GridItem(id: "gem-2", position: Position(x: 2, y: 0), kind: .collectible)
        let grid = makeGrid(items: [gem1, gem2])
        let start = RobotState(position: Position(x: 0, y: 0), facing: .right)
        // Goal at (3,0); collectGoal = 2. Program collects both gems then reaches goal.
        let challenge = makeChallenge(
            grid: grid,
            start: start,
            goal: Position(x: 3, y: 0),
            collectGoal: 2
        )
        let program = Program(commands: [.move, .move, .move])
        let result = sim.run(program: program, challenge: challenge)
        #expect(result.isSuccess)
        #expect(result.itemsCollected.count == 2)
    }

    @Test("Challenge with collectGoal: failure if at goal but items missing")
    func collectGoalFailureItemsMissing() {
        let gem = GridItem(id: "gem-1", position: Position(x: 3, y: 0), kind: .collectible)
        let grid = makeGrid(items: [gem])
        let start = RobotState(position: Position(x: 0, y: 0), facing: .right)
        // Goal at (1,0); collectGoal = 1. Gem is at (3,0) — unreachable with 1 move.
        let challenge = makeChallenge(
            grid: grid,
            start: start,
            goal: Position(x: 1, y: 0),
            collectGoal: 1
        )
        let program = Program(commands: [.move])
        let result = sim.run(program: program, challenge: challenge)
        #expect(!result.isSuccess)
        #expect(result.itemsCollected.isEmpty)
        if case let .failure(reason) = result.outcome,
           case let .didNotCollectAll(collected, required) = reason {
            #expect(collected == 0)
            #expect(required == 1)
        } else {
            Issue.record("Expected didNotCollectAll failure")
        }
    }

    @Test("Key item auto-collected the same way as collectible")
    func keyAutoCollect() {
        let key = GridItem(id: "key-1", position: Position(x: 1, y: 0), kind: .key)
        let grid = makeGrid(items: [key])
        let start = RobotState(position: Position(x: 0, y: 0), facing: .right)
        let challenge = makeChallenge(grid: grid, start: start, goal: Position(x: 1, y: 0))
        let result = sim.run(program: Program(commands: [.move]), challenge: challenge)
        #expect(result.isSuccess)
        #expect(result.itemsCollected.contains("key-1"))
    }

    @Test("Item on ice slide destination is auto-collected")
    func iceSlideCollectsItem() {
        // Ice at (1,0). Gem at (2,0) — the slide destination.
        let gem = GridItem(id: "gem-slide", position: Position(x: 2, y: 0), kind: .collectible)
        let grid = makeGrid(
            terrain: [Position(x: 1, y: 0): .ice],
            items: [gem]
        )
        let start = RobotState(position: Position(x: 0, y: 0), facing: .right)
        let challenge = makeChallenge(grid: grid, start: start, goal: Position(x: 2, y: 0))
        let result = sim.run(program: Program(commands: [.move]), challenge: challenge)
        #expect(result.isSuccess)
        #expect(result.itemsCollected.contains("gem-slide"))
    }

    @Test("Item on conveyor push destination is auto-collected")
    func conveyorCollectsItem() {
        // Conveyor north at (1,0). Gem at (1,1) — the push destination.
        let gem = GridItem(id: "gem-conv", position: Position(x: 1, y: 1), kind: .collectible)
        let grid = makeGrid(
            terrain: [Position(x: 1, y: 0): .conveyorNorth],
            items: [gem]
        )
        let start = RobotState(position: Position(x: 0, y: 0), facing: .right)
        let challenge = makeChallenge(grid: grid, start: start, goal: Position(x: 1, y: 1))
        let result = sim.run(program: Program(commands: [.move]), challenge: challenge)
        #expect(result.isSuccess)
        #expect(result.itemsCollected.contains("gem-conv"))
    }
}

// MARK: - Efficiency / star rating

@Suite("Efficiency star rating")
struct StarRatingTests {

    private let sim = Simulator()

    @Test("3 stars when moveStepsUsed == parMoves exactly")
    func threeStarsExact() {
        let grid = makeGrid()
        let start = RobotState(position: Position(x: 0, y: 0), facing: .right)
        // 2 normal moves → moveStepsUsed = 2; par = 2 → 3 stars
        let challenge = makeChallenge(
            grid: grid,
            start: start,
            goal: Position(x: 2, y: 0),
            parMoves: 2
        )
        let result = sim.run(program: Program(commands: [.move, .move]), challenge: challenge)
        #expect(result.isSuccess)
        #expect(result.starRating == 3)
    }

    @Test("2 stars when moveStepsUsed is within 1.5x par (e.g. 1.4x)")
    func twoStars() {
        // par = 5, used = 7 → 7 <= 5*1.5 = 7.5 → 2 stars
        // Robot moves 7 steps on a 10-wide grid.
        let grid = makeGrid(width: 10, height: 3)
        let start = RobotState(position: Position(x: 0, y: 0), facing: .right)
        let challenge = makeChallenge(
            grid: grid,
            start: start,
            goal: Position(x: 7, y: 0),
            parMoves: 5
        )
        let program = Program(commands: [.repeatBlock(count: 7, body: [.move])])
        let result = sim.run(program: program, challenge: challenge)
        #expect(result.isSuccess)
        #expect(result.moveStepsUsed == 7)
        #expect(result.starRating == 2)
    }

    @Test("1 star when over 1.5x par but still successful")
    func oneStar() {
        // par = 3, used = 5 → 5 > 3*1.5 = 4.5 → 1 star
        let grid = makeGrid(width: 10, height: 3)
        let start = RobotState(position: Position(x: 0, y: 0), facing: .right)
        let challenge = makeChallenge(
            grid: grid,
            start: start,
            goal: Position(x: 5, y: 0),
            parMoves: 3
        )
        let program = Program(commands: [.repeatBlock(count: 5, body: [.move])])
        let result = sim.run(program: program, challenge: challenge)
        #expect(result.isSuccess)
        #expect(result.moveStepsUsed == 5)
        #expect(result.starRating == 1)
    }

    @Test("0 stars on failure even when par is set")
    func zeroStarsOnFailure() {
        // Robot crashes into a wall. Even though par is set, result is 0 stars.
        let grid = makeGrid(obstacles: [Position(x: 1, y: 0)])
        let start = RobotState(position: Position(x: 0, y: 0), facing: .right)
        let challenge = makeChallenge(
            grid: grid,
            start: start,
            goal: Position(x: 2, y: 0),
            parMoves: 5
        )
        let result = sim.run(program: Program(commands: [.move]), challenge: challenge)
        #expect(!result.isSuccess)
        // starRating is only set on success path; nil on failure.
        #expect(result.starRating == nil)
    }

    @Test("starRating is nil when no parMoves is set")
    func noParNoRating() {
        let grid = makeGrid()
        let start = RobotState(position: Position(x: 0, y: 0), facing: .right)
        let challenge = makeChallenge(grid: grid, start: start, goal: Position(x: 1, y: 0))
        let result = sim.run(program: Program(commands: [.move]), challenge: challenge)
        #expect(result.isSuccess)
        #expect(result.starRating == nil)
    }

    @Test("Mud cells count double toward move-step cost for star rating")
    func mudCountsDoubleForPar() {
        // par = 2, one move through mud = 2 steps → 3 stars (exactly on par)
        let grid = makeGrid(terrain: [Position(x: 1, y: 0): .mud])
        let start = RobotState(position: Position(x: 0, y: 0), facing: .right)
        let challenge = makeChallenge(
            grid: grid,
            start: start,
            goal: Position(x: 1, y: 0),
            parMoves: 2
        )
        let result = sim.run(program: Program(commands: [.move]), challenge: challenge)
        #expect(result.isSuccess)
        #expect(result.moveStepsUsed == 2)
        #expect(result.starRating == 3)
    }
}

// MARK: - Backward compatibility

@Suite("Backward compatibility")
struct BackwardCompatibilityTests {

    private let sim = Simulator()

    @Test("Grid without terrain or items still works as before")
    func gridDefaultsEmpty() {
        let grid = Grid(width: 6, height: 6, obstacles: [])
        #expect(grid.terrain.isEmpty)
        #expect(grid.items.isEmpty)
    }

    @Test("Challenge without collectGoal or parMoves defaults to nil")
    func challengeDefaultsNil() {
        let grid = Grid(width: 6, height: 6)
        let challenge = Challenge(
            grid: grid,
            start: RobotState(position: Position(x: 0, y: 0), facing: .up),
            goal: Position(x: 0, y: 1),
            allowedCommands: CommandKind.allCases
        )
        #expect(challenge.collectGoal == nil)
        #expect(challenge.parMoves == nil)
    }

    @Test("ExecutionResult isSuccess still works when no terrain features used")
    func resultIsSuccess() {
        let grid = Grid(width: 6, height: 6)
        let start = RobotState(position: Position(x: 0, y: 0), facing: .right)
        let challenge = Challenge(
            grid: grid,
            start: start,
            goal: Position(x: 1, y: 0),
            allowedCommands: CommandKind.allCases
        )
        let result = sim.run(program: Program(commands: [.move]), challenge: challenge)
        #expect(result.isSuccess)
        #expect(result.itemsCollected.isEmpty)
        #expect(result.moveStepsUsed == 1)
        #expect(result.starRating == nil)
    }

    @Test("Grid Codable round-trip with terrain and items")
    func gridCodableRoundTrip() throws {
        let grid = Grid(
            width: 4,
            height: 4,
            obstacles: [Position(x: 1, y: 1)],
            terrain: [
                Position(x: 2, y: 0): .ice,
                Position(x: 0, y: 2): .portal("A")
            ],
            items: [GridItem(id: "g1", position: Position(x: 3, y: 3), kind: .collectible)]
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(grid)
        let decoded = try JSONDecoder().decode(Grid.self, from: data)
        #expect(decoded == grid)
    }

    @Test("Grid Codable decodes legacy JSON without terrain or items keys")
    func gridDecodesLegacyJSON() throws {
        // Minimal JSON that older code would have produced (no terrain/items keys).
        let json = """
        {
          "width": 6,
          "height": 6,
          "obstacles": [{"x": 2, "y": 3}]
        }
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(Grid.self, from: json)
        #expect(decoded.width == 6)
        #expect(decoded.height == 6)
        #expect(decoded.obstacles == [Position(x: 2, y: 3)])
        #expect(decoded.terrain.isEmpty)
        #expect(decoded.items.isEmpty)
    }

    @Test("TerrainKind Codable round-trips for all simple cases")
    func terrainKindCodable() throws {
        let cases: [TerrainKind] = [
            .normal, .ice, .mud,
            .conveyorNorth, .conveyorSouth, .conveyorEast, .conveyorWest,
            .portal("Z")
        ]
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for kind in cases {
            let data = try encoder.encode(kind)
            let decoded = try decoder.decode(TerrainKind.self, from: data)
            #expect(decoded == kind)
        }
    }
}
