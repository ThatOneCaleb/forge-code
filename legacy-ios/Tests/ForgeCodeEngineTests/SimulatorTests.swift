import Testing
@testable import ForgeCodeEngine

@Suite("Simulator execution")
struct SimulatorTests {

    /// An open grid challenge with the robot in the middle, facing up,
    /// and a generous block budget. Goal defaults to somewhere reachable.
    private func openChallenge(
        start: RobotState,
        goal: Position,
        width: Int = 6,
        height: Int = 6,
        obstacles: Set<Position> = [],
        maxBlocks: Int? = nil
    ) -> Challenge {
        Challenge(
            grid: Grid(width: width, height: height, obstacles: obstacles),
            start: start,
            goal: goal,
            allowedCommands: CommandKind.allCases,
            maxBlocks: maxBlocks
        )
    }

    private let sim = Simulator()

    // MARK: - Single-command effects

    @Test("move advances in each of the four facings")
    func moveInAllDirections() {
        let cases: [(Direction, Position)] = [
            (.up, Position(x: 2, y: 3)),
            (.down, Position(x: 2, y: 1)),
            (.left, Position(x: 1, y: 2)),
            (.right, Position(x: 3, y: 2))
        ]
        for (facing, expected) in cases {
            let start = RobotState(position: Position(x: 2, y: 2), facing: facing)
            let challenge = openChallenge(start: start, goal: expected)
            let result = sim.run(program: Program(commands: [.move]), challenge: challenge)
            #expect(result.isSuccess)
            #expect(result.frames.last?.position == expected)
        }
    }

    @Test("turnLeft and turnRight rotate the robot in place")
    func turns() {
        let start = RobotState(position: Position(x: 2, y: 2), facing: .up)
        let challenge = openChallenge(start: start, goal: Position(x: 2, y: 2))

        let left = sim.run(program: Program(commands: [.turnLeft]), challenge: challenge)
        #expect(left.frames.last?.facing == .left)
        #expect(left.frames.last?.position == Position(x: 2, y: 2))

        let right = sim.run(program: Program(commands: [.turnRight]), challenge: challenge)
        #expect(right.frames.last?.facing == .right)
    }

    // MARK: - Crashes

    @Test("moving into an obstacle reports hitWall and keeps frames")
    func hitWall() {
        let start = RobotState(position: Position(x: 2, y: 2), facing: .up)
        let wall = Position(x: 2, y: 3)
        let challenge = openChallenge(start: start, goal: Position(x: 0, y: 0), obstacles: [wall])
        let result = sim.run(program: Program(commands: [.move]), challenge: challenge)
        #expect(result.outcome == .failure(.hitWall(at: wall)))
        // No frame is appended for the failed move; only the start remains.
        #expect(result.frames == [start])
    }

    @Test("moving off the edge reports wentOffGrid")
    func offGrid() {
        let start = RobotState(position: Position(x: 0, y: 0), facing: .down)
        let challenge = openChallenge(start: start, goal: Position(x: 0, y: 0))
        let result = sim.run(program: Program(commands: [.move]), challenge: challenge)
        #expect(result.outcome == .failure(.wentOffGrid(to: Position(x: 0, y: -1))))
        #expect(result.frames == [start])
    }

    // MARK: - repeat

    @Test("repeat runs its body exactly n times")
    func repeatCount() {
        let start = RobotState(position: Position(x: 0, y: 0), facing: .right)
        let challenge = openChallenge(start: start, goal: Position(x: 3, y: 0))
        let program = Program(commands: [.repeatBlock(count: 3, body: [.move])])
        let result = sim.run(program: program, challenge: challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == Position(x: 3, y: 0))
    }

    @Test("nested repeat multiplies iterations")
    func nestedRepeat() {
        // Outer 2 × inner 3 = 6 moves to the right.
        let start = RobotState(position: Position(x: 0, y: 0), facing: .right)
        let challenge = openChallenge(start: start, goal: Position(x: 6, y: 0), width: 8)
        let program = Program(commands: [
            .repeatBlock(count: 2, body: [.repeatBlock(count: 3, body: [.move])])
        ])
        let result = sim.run(program: program, challenge: challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == Position(x: 6, y: 0))
    }

    // MARK: - if(wallAhead())

    @Test("if(wallAhead()) runs body when a wall is directly ahead")
    func ifWallTrue() {
        // Facing an obstacle: the if turns the robot away.
        let start = RobotState(position: Position(x: 2, y: 2), facing: .up)
        let wall = Position(x: 2, y: 3)
        let challenge = openChallenge(start: start, goal: Position(x: 2, y: 2), obstacles: [wall])
        let program = Program(commands: [.ifWallAhead(body: [.turnRight])])
        let result = sim.run(program: program, challenge: challenge)
        #expect(result.frames.last?.facing == .right)
    }

    @Test("if(wallAhead()) skips body when the path is clear")
    func ifWallFalse() {
        let start = RobotState(position: Position(x: 2, y: 2), facing: .up)
        let challenge = openChallenge(start: start, goal: Position(x: 2, y: 2))
        let program = Program(commands: [.ifWallAhead(body: [.turnRight])])
        let result = sim.run(program: program, challenge: challenge)
        // Facing unchanged; body was skipped, so only the start frame exists.
        #expect(result.frames == [start])
        #expect(result.frames.last?.facing == .up)
    }

    @Test("if(wallAhead()) is true at the grid edge")
    func ifWallAtEdge() {
        let start = RobotState(position: Position(x: 0, y: 0), facing: .down)
        let challenge = openChallenge(start: start, goal: Position(x: 0, y: 0))
        let program = Program(commands: [.ifWallAhead(body: [.turnLeft])])
        let result = sim.run(program: program, challenge: challenge)
        #expect(result.frames.last?.facing == start.facing.turnedLeft())
    }

    // MARK: - Budgets

    @Test("blockCount over maxBlocks fails up front without executing")
    func ranOutOfBlocks() {
        let start = RobotState(position: Position(x: 0, y: 0), facing: .right)
        let challenge = openChallenge(start: start, goal: Position(x: 3, y: 0), maxBlocks: 2)
        let program = Program(commands: [.move, .move, .move]) // 3 > 2
        let result = sim.run(program: program, challenge: challenge)
        #expect(result.outcome == .failure(.ranOutOfBlocks(limit: 2, used: 3)))
        // Nothing executed: only the start frame.
        #expect(result.frames == [start])
    }

    @Test("an empty infinite-ish loop trips the step budget")
    func tooManySteps() {
        let start = RobotState(position: Position(x: 0, y: 0), facing: .up)
        let challenge = openChallenge(start: start, goal: Position(x: 0, y: 0))
        // repeat(100){ repeat(100){ turnLeft } } = 10_000 turns > 1000 budget.
        let program = Program(commands: [
            .repeatBlock(count: 100, body: [.repeatBlock(count: 100, body: [.turnLeft])])
        ])
        let smallSim = Simulator(stepBudget: 1000)
        let result = smallSim.run(program: program, challenge: challenge)
        #expect(result.outcome == .failure(.tooManySteps(limit: 1000)))
    }

    @Test("reaching the goal succeeds; stopping elsewhere reports didNotReachGoal")
    func goalCheck() {
        let start = RobotState(position: Position(x: 0, y: 0), facing: .right)
        let win = openChallenge(start: start, goal: Position(x: 1, y: 0))
        #expect(sim.run(program: Program(commands: [.move]), challenge: win).isSuccess)

        let lose = openChallenge(start: start, goal: Position(x: 5, y: 5))
        let result = sim.run(program: Program(commands: [.move]), challenge: lose)
        #expect(result.outcome == .failure(.didNotReachGoal(finalPosition: Position(x: 1, y: 0))))
    }

    // MARK: - Frame trace

    @Test("frames[0] is the start and one frame is appended per atomic step")
    func frameTrace() {
        let start = RobotState(position: Position(x: 0, y: 0), facing: .up)
        let challenge = openChallenge(start: start, goal: Position(x: 0, y: 2))
        // turnRight (no move needed for goal, but exercises turn + moves)
        let program = Program(commands: [.move, .move])
        let result = sim.run(program: program, challenge: challenge)
        #expect(result.frames.count == 3) // start + 2 moves
        #expect(result.frames[0] == start)
        #expect(result.frames[1].position == Position(x: 0, y: 1))
        #expect(result.frames[2].position == Position(x: 0, y: 2))
    }

    @Test("same program + challenge is deterministic")
    func determinism() {
        let start = RobotState(position: Position(x: 0, y: 0), facing: .right)
        let challenge = openChallenge(start: start, goal: Position(x: 2, y: 0))
        let program = Program(commands: [.move, .move])
        let a = sim.run(program: program, challenge: challenge)
        let b = sim.run(program: program, challenge: challenge)
        #expect(a == b)
    }
}
