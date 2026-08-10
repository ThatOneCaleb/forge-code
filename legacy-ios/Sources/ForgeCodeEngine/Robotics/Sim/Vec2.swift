/// A 2-D position in continuous centimetre space.
///
/// +X = field "east", +Y = field "north". Heading 0° points along +Y.
/// No Foundation dependency.
public struct Vec2: Equatable, Hashable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    /// The zero vector / origin.
    public static let zero = Vec2(x: 0, y: 0)

    /// Euclidean distance to another point (cm).
    public func distance(to other: Vec2) -> Double {
        let dx = other.x - x
        let dy = other.y - y
        return (dx * dx + dy * dy).squareRoot()
    }

    // MARK: - Arithmetic conveniences

    public static func + (lhs: Vec2, rhs: Vec2) -> Vec2 {
        Vec2(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    public static func - (lhs: Vec2, rhs: Vec2) -> Vec2 {
        Vec2(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    public static func * (lhs: Vec2, rhs: Double) -> Vec2 {
        Vec2(x: lhs.x * rhs, y: lhs.y * rhs)
    }
}
