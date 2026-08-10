import Testing
@testable import ForgeCodeEngine

@Suite("Geometry & Direction")
struct GeometryTests {

    @Test("Direction deltas match the coordinate convention")
    func deltas() {
        #expect(Direction.up.delta == (0, 1))
        #expect(Direction.down.delta == (0, -1))
        #expect(Direction.left.delta == (-1, 0))
        #expect(Direction.right.delta == (1, 0))
    }

    @Test("turnedLeft cycles counter-clockwise")
    func turnLeftCycle() {
        #expect(Direction.up.turnedLeft() == .left)
        #expect(Direction.left.turnedLeft() == .down)
        #expect(Direction.down.turnedLeft() == .right)
        #expect(Direction.right.turnedLeft() == .up)
    }

    @Test("turnedRight cycles clockwise")
    func turnRightCycle() {
        #expect(Direction.up.turnedRight() == .right)
        #expect(Direction.right.turnedRight() == .down)
        #expect(Direction.down.turnedRight() == .left)
        #expect(Direction.left.turnedRight() == .up)
    }

    @Test("Four left turns return to start")
    func fourLefts() {
        var d = Direction.up
        for _ in 0..<4 { d = d.turnedLeft() }
        #expect(d == .up)
    }
}

@Suite("Grid bounds & obstacles")
struct GridTests {

    @Test("contains checks bounds inclusively from 0")
    func contains() {
        let grid = Grid(width: 6, height: 6)
        #expect(grid.contains(Position(x: 0, y: 0)))
        #expect(grid.contains(Position(x: 5, y: 5)))
        #expect(!grid.contains(Position(x: 6, y: 0)))
        #expect(!grid.contains(Position(x: 0, y: 6)))
        #expect(!grid.contains(Position(x: -1, y: 0)))
    }

    @Test("isObstacle and isBlocked")
    func obstacles() {
        let wall = Position(x: 2, y: 2)
        let grid = Grid(width: 6, height: 6, obstacles: [wall])
        #expect(grid.isObstacle(wall))
        #expect(grid.isBlocked(wall))
        #expect(!grid.isBlocked(Position(x: 1, y: 1)))
        // Off-grid is blocked even without an obstacle there.
        #expect(grid.isBlocked(Position(x: 6, y: 6)))
    }
}

@Suite("RobotState transitions")
struct RobotStateTests {

    @Test("cellAhead reflects facing")
    func cellAhead() {
        let r = RobotState(position: Position(x: 2, y: 2), facing: .up)
        #expect(r.cellAhead == Position(x: 2, y: 3))
        #expect(r.turnedRight().cellAhead == Position(x: 3, y: 2))
    }

    @Test("movedForward advances one cell without changing facing")
    func moveForward() {
        let r = RobotState(position: Position(x: 1, y: 1), facing: .right)
        let next = r.movedForward()
        #expect(next.position == Position(x: 2, y: 1))
        #expect(next.facing == .right)
    }
}
