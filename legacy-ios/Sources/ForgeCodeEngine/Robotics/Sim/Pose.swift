/// The robot's position + heading in the field coordinate system.
///
/// Coordinate convention (document once here, respected everywhere):
/// - Position in centimetres: +X = east, +Y = north.
/// - headingDegrees: 0° points along +Y (north). Increases clockwise:
///   90° = east, 180° = south, 270° = west.
///   CW-positive heading with 0° pointing north — a common robot-gyro convention.
///
/// No Foundation dependency.
public struct Pose: Equatable, Hashable, Sendable {
    public var position:       Vec2
    public var headingDegrees: Double   // 0° = north, CW positive, [0, 360)

    public init(position: Vec2, headingDegrees: Double) {
        self.position       = position
        self.headingDegrees = headingDegrees.normalised
    }

    /// The default starting pose: origin, facing north.
    public static let origin = Pose(position: .zero, headingDegrees: 0)

    // MARK: - Movement helpers

    /// Advance the position forward by `cm` along the current heading.
    public mutating func moveForward(cm: Double) {
        position = position + headingVector * cm
    }

    /// Turn clockwise by `degrees` (right turn).
    public mutating func turnRight(degrees: Double) {
        headingDegrees = (headingDegrees + degrees).normalised
    }

    /// Turn counter-clockwise by `degrees` (left turn).
    public mutating func turnLeft(degrees: Double) {
        headingDegrees = (headingDegrees - degrees).normalised
    }

    // MARK: - Derived

    /// Unit vector pointing in the direction the robot faces.
    /// heading 0° → (0,1); heading 90° → (1,0); heading 180° → (0,-1).
    public var headingVector: Vec2 {
        let rad = headingDegrees * .pi / 180
        return Vec2(x: rSin(rad), y: rCos(rad))
    }
}

// MARK: - Normalise helper

private extension Double {
    /// Wrap to [0, 360).
    var normalised: Double {
        let m = self.truncatingRemainder(dividingBy: 360)
        return m < 0 ? m + 360 : m
    }
}
