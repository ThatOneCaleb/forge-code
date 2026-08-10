import Testing
@testable import ForgeCodeEngine

/// The base/home area rules: a run may start anywhere inside base at any heading,
/// and a chosen start is clamped back inside if it strays out.
@Suite("Home area (base placement)")
struct HomeAreaTests {

    private func arena() throws -> FieldWorld {
        try #require(try RoboticsLibrary.field(id: "field_arena"))
    }

    @Test("field_arena resolves base_camp as its home area")
    func homeAreaResolved() throws {
        let w = try arena()
        let area = try #require(w.homeArea)
        // base_camp rect: x108 y8 w84 h42
        #expect(area.x == 108 && area.y == 8 && area.width == 84 && area.height == 42)
    }

    @Test("points inside base are in the home area; points outside are not")
    func containment() throws {
        let w = try arena()
        #expect(w.isInHomeArea(Vec2(x: 150, y: 29)))   // centre
        #expect(w.isInHomeArea(Vec2(x: 110, y: 10)))   // near corner, inside
        #expect(!w.isInHomeArea(Vec2(x: 150, y: 120)))  // far north, outside
        #expect(!w.isInHomeArea(Vec2(x: 20, y: 29)))   // west, outside
    }

    @Test("a start pose outside base is clamped back to the base edge, heading kept")
    func clamping() throws {
        let w = try arena()
        let chosen = Pose(position: Vec2(x: 300, y: 300), headingDegrees: 135)
        let clamped = w.clampToHomeArea(chosen)
        #expect(clamped.position.x == 192)   // 108 + 84
        #expect(clamped.position.y == 50)    // 8 + 42
        #expect(clamped.headingDegrees == 135)
    }

    @Test("a custom in-base start pose + heading runs correctly")
    func customStartPoseRuns() throws {
        let w = try arena()
        // Start pushed to the NE corner of base, facing east, then drive east.
        let start = w.clampToHomeArea(Pose(position: Vec2(x: 188, y: 45), headingDegrees: 90))
        let robot = RobotModel(pose: start, armAngle: 0, isGripperOpen: true)
        let run = RoboticsSimulator().run(program: "drive.forward(10);", world: w, robot: robot)
        #expect(run.failureKind == nil)
        // Moved +10 in x (east) from the clamped start.
        let end = try #require(run.finalSnapshot).pose.position
        #expect(abs(end.x - 198) < 0.001)
        #expect(abs(end.y - 45) < 0.001)
    }
}
