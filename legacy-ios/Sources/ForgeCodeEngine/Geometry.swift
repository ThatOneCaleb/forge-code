/// A cell coordinate on the grid.
///
/// Origin `(0, 0)` is the bottom-left; `x` increases to the right and
/// `y` increases upward.
public struct Position: Codable, Hashable, Sendable {
    public var x: Int
    public var y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

/// The four cardinal directions the robot can face.
public enum Direction: String, Codable, Hashable, Sendable, CaseIterable {
    case up
    case down
    case left
    case right

    /// The direction reached by turning 90° counter-clockwise.
    public func turnedLeft() -> Direction {
        switch self {
        case .up: return .left
        case .left: return .down
        case .down: return .right
        case .right: return .up
        }
    }

    /// The direction reached by turning 90° clockwise.
    public func turnedRight() -> Direction {
        switch self {
        case .up: return .right
        case .right: return .down
        case .down: return .left
        case .left: return .up
        }
    }

    /// The `(dx, dy)` offset applied to a position when moving one cell
    /// forward in this direction.
    public var delta: (dx: Int, dy: Int) {
        switch self {
        case .up: return (0, 1)
        case .down: return (0, -1)
        case .left: return (-1, 0)
        case .right: return (1, 0)
        }
    }
}
