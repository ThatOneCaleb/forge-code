/// The complete, ordered output of a `RoboticsSimulator.run(...)` call.
///
/// The UI plays back a `RoboticsRun`; the engine computes it deterministically.
/// No Foundation dependency.

// MARK: - World item state snapshot

/// Tracks the state of a single pickable item for one keyframe.
public struct ItemState: Equatable, Sendable {
    public var id:         String
    /// nil = item is on the field at its original position; non-nil = in a zone or held.
    public var position:   Vec2?
    /// Whether the item is currently held by the gripper.
    public var isHeld:     Bool
    /// Zone id the item was deposited into, if any.
    public var inZoneId:   String?

    public init(id: String, position: Vec2?, isHeld: Bool = false, inZoneId: String? = nil) {
        self.id       = id
        self.position = position
        self.isHeld   = isHeld
        self.inZoneId = inZoneId
    }
}

// MARK: - Sensor log entry

public enum SensorEventKind: Equatable, Sendable {
    case distance(Double)
    case color(String)
    case lineLeft(Bool)
    case lineRight(Bool)
    case gyro(Double)
    case limitSwitch(Bool)
    case wallAhead(Bool)
    case print_(String)
    case wait(Double)
    /// Robot was teleported to the given pose via `returnHome()`.
    case returnHome(Pose)
    /// A field mechanism was activated (lever tipped, gate opened, platform raised).
    case mechanismActivated(String)
}

// MARK: - Mechanism state snapshot

/// Tracks one mechanism's activation state for one keyframe.
public struct MechanismState: Equatable, Sendable {
    public var id:          String
    public var isActivated: Bool

    public init(id: String, isActivated: Bool) {
        self.id = id; self.isActivated = isActivated
    }
}

public struct SensorEvent: Equatable, Sendable {
    public var frameIndex: Int
    public var kind:       SensorEventKind

    public init(frameIndex: Int, kind: SensorEventKind) {
        self.frameIndex = frameIndex
        self.kind       = kind
    }
}

// MARK: - RobotSnapshot

/// The robot + world state at one discrete step.
public struct RobotSnapshot: Equatable, Sendable {
    public var pose:        Pose
    public var armAngle:    Double
    public var isGripperOpen: Bool
    public var heldObjectId:  String?
    /// States of all field items at this frame.
    public var itemStates:  [ItemState]
    /// States of all field mechanisms at this frame (empty when the field has none).
    public var mechanismStates: [MechanismState]

    public init(pose: Pose, armAngle: Double, isGripperOpen: Bool,
                heldObjectId: String?, itemStates: [ItemState],
                mechanismStates: [MechanismState] = []) {
        self.pose            = pose
        self.armAngle        = armAngle
        self.isGripperOpen   = isGripperOpen
        self.heldObjectId    = heldObjectId
        self.itemStates      = itemStates
        self.mechanismStates = mechanismStates
    }
}

// MARK: - Failure reason

public enum RunFailureKind: Equatable, Sendable {
    case collision(obstacleId: String)
    case outOfBounds
    case stepBudgetExceeded(limit: Int)
    case actionBudgetExceeded(limit: Int)
    case runtimeError(String)
}

// MARK: - RoboticsRun

/// The full output of one simulation run.
public struct RoboticsRun: Equatable, Sendable {
    /// Ordered keyframes (first = initial state before any action).
    public var snapshots:    [RobotSnapshot]
    /// Sensor reads + print events in order.
    public var sensorLog:    [SensorEvent]
    /// Set when run against a `Mission`.
    public var missionResult: MissionResult?
    /// Set when the run terminated early due to an error or budget exceeded.
    public var failureKind:  RunFailureKind?

    public init(snapshots:    [RobotSnapshot],
                sensorLog:    [SensorEvent],
                missionResult: MissionResult? = nil,
                failureKind:  RunFailureKind? = nil) {
        self.snapshots     = snapshots
        self.sensorLog     = sensorLog
        self.missionResult = missionResult
        self.failureKind   = failureKind
    }

    /// Whether the run completed without an engine-level failure.
    public var completed: Bool { failureKind == nil }

    /// Final snapshot (last keyframe).
    public var finalSnapshot: RobotSnapshot? { snapshots.last }
}
