/// A robotics mission: a set of objectives on a specific field that the robot
/// must complete by programming the robot API.
///
/// Missions are data-driven (decoded from JSON) and reference a `FieldWorld`
/// by id. Scoring is unambiguous — each objective has a fixed point value, and
/// the success rule states whether all required objectives must be met, or
/// whether a score threshold is sufficient.
///
/// No Foundation dependency (JSON decoding is in `RoboticsLibrary`).

// MARK: - Objective kinds

public enum ObjectiveKind: String, Equatable, Hashable, Sendable {
    /// Robot pose falls within a given zone rect at run end.
    case reachZone
    /// Robot pose is within `toleranceCm` of a target position at run end.
    case reachPose
    /// Robot picks up a specific item (gripper closes on it).
    case pickUpItem
    /// Robot deposits an item in a specific zone.
    case depositItemInZone
    /// Color sensor reads the specified colour while inside a zone.
    case detectColorInZone
    /// Arm angle reaches (or exceeds) the target angle.
    case armToAngle
    /// A field mechanism (lever/gate/platform) was activated during the run.
    case activateMechanism
    /// The robot's path passed within `toleranceCm` of a target position at any
    /// point during the run (used for "drive over the collectible" objectives).
    case visitTile
}

// MARK: - Objective

public struct MissionObjective: Equatable, Hashable, Sendable {
    /// Unique id within the mission.
    public var id:          String
    public var kind:        ObjectiveKind
    /// Points awarded when this objective is met.
    public var points:      Int
    /// Human-readable description shown to the kid.
    public var description: String

    // Reference fields (only the relevant one(s) for each kind are non-nil):
    /// Target zone id (reachZone, depositItemInZone, detectColorInZone).
    public var targetZoneId:  String?
    /// Target item id (pickUpItem, depositItemInZone).
    public var targetItemId:  String?
    /// Target arm angle (armToAngle).
    public var targetAngle:   Double?
    /// Target position (reachPose).
    public var targetX:       Double?
    public var targetY:       Double?
    /// Tolerance in cm for reachPose.
    public var toleranceCm:   Double?
    /// Expected colour string for detectColorInZone.
    public var expectedColor: String?
    /// Target mechanism id (activateMechanism).
    public var targetMechanismId: String?
    /// Whether this objective must be met for the mission to succeed
    /// (independent of the success threshold).
    public var isRequired:    Bool

    public init(
        id:           String,
        kind:         ObjectiveKind,
        points:       Int,
        description:  String,
        targetZoneId: String? = nil,
        targetItemId: String? = nil,
        targetAngle:  Double? = nil,
        targetX:      Double? = nil,
        targetY:      Double? = nil,
        toleranceCm:  Double? = nil,
        expectedColor:String? = nil,
        targetMechanismId: String? = nil,
        isRequired:   Bool    = false
    ) {
        self.id           = id
        self.kind         = kind
        self.points       = points
        self.description  = description
        self.targetZoneId = targetZoneId
        self.targetItemId = targetItemId
        self.targetAngle  = targetAngle
        self.targetX      = targetX
        self.targetY      = targetY
        self.toleranceCm  = toleranceCm
        self.expectedColor = expectedColor
        self.targetMechanismId = targetMechanismId
        self.isRequired   = isRequired
    }
}

// MARK: - Success rule

public enum MissionSuccessRule: Equatable, Hashable, Sendable {
    /// All objectives marked `isRequired == true` must be met.
    case allRequired
    /// Total score must reach this threshold.
    case scoreThreshold(Int)
    /// Either: all required AND score threshold.
    case allRequiredAndScore(Int)
}

// MARK: - Mission

public struct Mission: Equatable, Sendable {
    public var id:          String
    public var fieldId:     String
    public var title:       String
    /// Short kid-facing brief shown before the run.
    public var brief:       String
    public var objectives:  [MissionObjective]
    public var successRule: MissionSuccessRule

    /// Progression difficulty, 1 (easiest) through 5 (hardest).
    ///
    /// Values outside that range are **clamped**: a JSON value of 0 becomes 1,
    /// a value of 9 becomes 5. This is pure metadata for the UI/progression
    /// layer and does not affect simulation correctness.
    public var difficulty: Int

    /// Optional per-mission action cap. When non-nil, the simulator uses
    /// `min(simulator.actionBudget, maxActions)` as the effective action budget
    /// for this mission, enabling efficiency-pressure challenges.
    /// When nil, the simulator's own `actionBudget` applies unchanged.
    public var maxActions: Int?

    /// Total possible points (computed).
    public var totalPossiblePoints: Int { objectives.reduce(0) { $0 + $1.points } }

    public init(
        id:          String,
        fieldId:     String,
        title:       String,
        brief:       String,
        objectives:  [MissionObjective],
        successRule: MissionSuccessRule = .allRequired,
        difficulty:  Int  = 1,
        maxActions:  Int? = nil
    ) {
        self.id          = id
        self.fieldId     = fieldId
        self.title       = title
        self.brief       = brief
        self.objectives  = objectives
        self.successRule = successRule
        self.difficulty  = min(5, max(1, difficulty))
        self.maxActions  = maxActions
    }
}

// MARK: - Mission result

/// The scored outcome of a simulation run against a mission.
public struct MissionResult: Equatable, Sendable {
    /// Which objective ids were met during the run.
    public var metObjectiveIds: Set<String>
    /// Total points earned.
    public var score: Int
    /// Whether the mission was successfully completed.
    public var success: Bool
    /// Short friendly reason when not successful.
    public var failureReason: String?

    public init(metObjectiveIds: Set<String>, score: Int, success: Bool,
                failureReason: String? = nil) {
        self.metObjectiveIds = metObjectiveIds
        self.score           = score
        self.success         = success
        self.failureReason   = failureReason
    }
}
