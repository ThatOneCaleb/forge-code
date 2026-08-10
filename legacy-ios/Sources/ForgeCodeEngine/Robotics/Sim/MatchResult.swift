/// The scored outcome of a `runMatch(...)` call.
///
/// No Foundation dependency.

// MARK: - Per-mission breakdown

/// The scoring outcome for one mission included in a match.
public struct MissionMatchEntry: Equatable, Sendable {
    /// The mission that was scored.
    public var missionId:      String
    /// Objectives that were met during the run.
    public var metObjectiveIds: Set<String>
    /// Points earned from this mission.
    public var score:          Int
    /// Whether the mission's own success rule was satisfied.
    public var success:        Bool

    public init(missionId: String, metObjectiveIds: Set<String>,
                score: Int, success: Bool) {
        self.missionId       = missionId
        self.metObjectiveIds = metObjectiveIds
        self.score           = score
        self.success         = success
    }
}

// MARK: - MatchResult

/// The complete scored result of a match run.
///
/// `totalScore = missionPoints + tokenPoints`
///
/// Token bonus: `tokensRemaining × match.pointsPerToken`. Spending a token via
/// `returnHome()` reduces this bonus by one `pointsPerToken` increment.
public struct MatchResult: Equatable, Sendable {
    /// Per-mission breakdown (in match.missionIds order).
    public var perMission:     [MissionMatchEntry]
    /// Sum of all per-mission scores.
    public var missionPoints:  Int
    /// Precision tokens left at run end (0 … match.startingTokens).
    public var tokensRemaining: Int
    /// `tokensRemaining × match.pointsPerToken`.
    public var tokenPoints:    Int
    /// `missionPoints + tokenPoints`.
    public var totalScore:     Int
    /// Number of actions consumed during the run.
    public var actionsUsed:    Int
    /// `match.moveBudget - actionsUsed` (may be 0 if budget was exhausted).
    public var budgetRemaining: Int

    public init(
        perMission:      [MissionMatchEntry],
        missionPoints:   Int,
        tokensRemaining: Int,
        tokenPoints:     Int,
        totalScore:      Int,
        actionsUsed:     Int,
        budgetRemaining: Int
    ) {
        self.perMission      = perMission
        self.missionPoints   = missionPoints
        self.tokensRemaining = tokensRemaining
        self.tokenPoints     = tokenPoints
        self.totalScore      = totalScore
        self.actionsUsed     = actionsUsed
        self.budgetRemaining = budgetRemaining
    }
}

// MARK: - MatchRun

/// The full output of one `runMatch(...)` call.
///
/// Carries the same `[RobotSnapshot]` keyframe trace as a `RoboticsRun` so the
/// UI can play it back identically. The `MatchResult` carries the scoring
/// breakdown. Same program + world + match ⇒ identical `MatchRun`.
public struct MatchRun: Equatable, Sendable {
    /// Ordered keyframes (first = initial state before any action).
    public var snapshots:   [RobotSnapshot]
    /// Sensor reads + print events in order.
    public var sensorLog:   [SensorEvent]
    /// The scored match outcome.
    public var result:      MatchResult
    /// Set when the run terminated early (budget exhausted or runtime error).
    /// Budget exhaustion sets this but is NOT a hard failure — scoring still runs.
    public var failureKind: RunFailureKind?

    public init(
        snapshots:   [RobotSnapshot],
        sensorLog:   [SensorEvent],
        result:      MatchResult,
        failureKind: RunFailureKind? = nil
    ) {
        self.snapshots   = snapshots
        self.sensorLog   = sensorLog
        self.result      = result
        self.failureKind = failureKind
    }

    /// Whether the run completed without any engine-level failure.
    public var completed: Bool { failureKind == nil }
}
