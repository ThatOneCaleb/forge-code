/// The robot's position and facing at a moment in time.
///
/// A value type: each atomic step produces a new `RobotState`, and the
/// ordered sequence of states forms the animation trace.
public struct RobotState: Codable, Hashable, Sendable {
    public var position: Position
    public var facing: Direction

    public init(position: Position, facing: Direction) {
        self.position = position
        self.facing = facing
    }

    /// The cell directly in front of the robot in its current facing.
    public var cellAhead: Position {
        let d = facing.delta
        return Position(x: position.x + d.dx, y: position.y + d.dy)
    }

    /// A copy advanced one cell in the current facing direction.
    public func movedForward() -> RobotState {
        RobotState(position: cellAhead, facing: facing)
    }

    /// A copy rotated 90° counter-clockwise.
    public func turnedLeft() -> RobotState {
        RobotState(position: position, facing: facing.turnedLeft())
    }

    /// A copy rotated 90° clockwise.
    public func turnedRight() -> RobotState {
        RobotState(position: position, facing: facing.turnedRight())
    }
}
