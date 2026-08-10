/// The robot's full state at any moment during a simulation run.
///
/// All values are deterministic; the simulator mutates a `RobotModel`
/// as it executes the program. No Foundation dependency.
public struct RobotModel: Equatable, Sendable {

    // MARK: - Drivetrain

    /// Current pose (position + heading). Continuous double coordinates in cm.
    public var pose: Pose

    /// Cumulative distance driven forward (cm). Increases on forward, decreases on backward.
    public var encoderDistance: Double

    /// Cumulative signed heading accumulated by turns (degrees). Same as pose.headingDegrees
    /// at start but might exceed 360 for multi-turn tracking if desired; here we mirror
    /// pose.headingDegrees for simplicity (mirrors pose heading).
    public var encoderHeading: Double { pose.headingDegrees }

    // MARK: - Arm

    /// Arm angle in degrees. 0° = fully raised / horizontal; 90° = fully lowered (default down).
    /// Convention: higher angle = more lowered. Range [0, 180].
    public var armAngle: Double

    /// Convenience: is the arm considered "lowered" (within pickup range)?
    /// Pickup is allowed when armAngle ≥ `armLoweredThreshold`.
    public static let armLoweredThreshold: Double = 60  // degrees
    public static let armRaisedAngle:      Double = 0
    public static let armLoweredAngle:     Double = 90

    public var isArmLowered: Bool { armAngle >= RobotModel.armLoweredThreshold }

    // MARK: - Gripper

    /// Whether the gripper jaws are open.
    public var isGripperOpen: Bool

    /// The id of the world item currently held, if any.
    public var heldObjectId: String?

    public var isHolding: Bool { heldObjectId != nil }

    // MARK: - Physical footprint

    /// Robot circular footprint radius (cm) used for collision detection.
    public var footprintRadius: Double

    // MARK: - Attachment

    /// The tool bolted on for this run. Chosen by the kid before running; the
    /// simulator reads it to gate attachment-locked mechanisms and to extend
    /// reach. See `RobotAttachment`.
    public var attachment: RobotAttachment

    // MARK: - Init

    public init(
        pose:            Pose   = .origin,
        encoderDistance: Double = 0,
        armAngle:        Double = 0,        // starts raised
        isGripperOpen:   Bool   = true,
        heldObjectId:    String? = nil,
        footprintRadius: Double = 0,         // 0 = centre-point only; set > 0 to enable body collision
        attachment:      RobotAttachment = .none
    ) {
        self.pose            = pose
        self.encoderDistance = encoderDistance
        self.armAngle        = armAngle
        self.isGripperOpen   = isGripperOpen
        self.heldObjectId    = heldObjectId
        self.footprintRadius = footprintRadius
        self.attachment      = attachment
    }
}
