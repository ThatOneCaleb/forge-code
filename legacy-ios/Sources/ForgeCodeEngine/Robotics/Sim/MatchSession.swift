/// A multi-launch match attempt — the FLL-style loop.
///
/// A real field round is not one program: the kid runs the rover, brings it back
/// to base, re-places/re-angles it, swaps intent, and launches again — as many
/// times as the shared "time" (move budget) allows. Missions already scored stay
/// scored; precision tokens are a shared pool; and **if the rover ends a launch
/// stuck or outside base, it costs a token** ("failed to return home").
///
/// `MatchSession` layers that loop on top of the single-launch `runMatch`
/// primitive. It is a pure value type: deterministic, no UI, fully testable.
///
/// Model note: each launch runs on a fresh copy of the field (items/mechanisms
/// reset), and a mission's score for the attempt is the **best** it reached in
/// any single launch — our match missions are each completable in one launch.
/// The rover's *position* is what carries between launches; the field does not.
public struct MatchSession: Sendable {

    // MARK: - Fixed content
    public let world:    FieldWorld
    public let match:    Match
    public let missions: [Mission]

    // MARK: - Cumulative state
    /// Precision tokens left in the shared pool.
    public private(set) var tokensRemaining: Int
    /// Move budget ("time") left across all launches.
    public private(set) var movesRemaining: Int
    /// Best scored entry seen per mission id, across all launches.
    public private(set) var bestByMission: [String: MissionMatchEntry]
    /// Every launch run so far, in order.
    public private(set) var launches: [MatchLaunch]
    /// Where the rover currently sits (end of the last launch, or base initially).
    public private(set) var roverPose: Pose

    /// Is the rover currently inside base (so the next launch needs no rescue)?
    public var roverInBase: Bool { world.isInHomeArea(roverPose.position) }
    /// Can another launch still be run? (budget not exhausted)
    public var canLaunch: Bool { movesRemaining > 0 }
    /// How many launches have been run.
    public var launchCount: Int { launches.count }

    // MARK: - Init
    public init(world: FieldWorld, match: Match, missions: [Mission]) {
        self.world           = world
        self.match           = match
        self.missions        = missions
        self.tokensRemaining = match.startingTokens
        self.movesRemaining  = match.moveBudget
        self.bestByMission   = [:]
        self.launches        = []
        self.roverPose       = world.resolvedHomePose
    }

    // MARK: - Launch

    /// Run one launch from `startPose` (clamped into base) with `attachment`.
    /// Mutates the session: spends move budget + tokens, merges mission scores,
    /// and applies the return-home penalty if the rover ends outside base.
    @discardableResult
    public mutating func launch(
        program:    String,
        startPose:  Pose,
        attachment: RobotAttachment = .none,
        simulator:  RoboticsSimulator = RoboticsSimulator()
    ) -> MatchLaunch {
        let start = world.clampToHomeArea(startPose)
        let robot = RobotModel(pose: start, armAngle: 0,
                               isGripperOpen: true, attachment: attachment)

        // Give this launch the remaining shared pool as its budget/tokens.
        var launchMatch = match
        launchMatch.moveBudget     = max(0, movesRemaining)
        launchMatch.startingTokens = tokensRemaining

        let run = simulator.runMatch(program: program, world: world,
                                     match: launchMatch, missions: missions, robot: robot)

        // Tokens after any in-program returnHome() spends.
        var tokens = run.result.tokensRemaining
        let finalPose = run.snapshots.last?.pose ?? start
        let endedInBase = world.isInHomeArea(finalPose.position)
        var penalty = false
        if !endedInBase {                       // stuck / didn't drive home → −1
            tokens = max(0, tokens - 1)
            penalty = true
        }

        tokensRemaining = tokens
        movesRemaining  = max(0, movesRemaining - run.result.actionsUsed)
        roverPose       = finalPose

        // Merge best-per-mission (keep the higher score seen for each mission).
        for entry in run.result.perMission {
            if let prev = bestByMission[entry.missionId], prev.score >= entry.score { continue }
            bestByMission[entry.missionId] = entry
        }

        let launch = MatchLaunch(
            run:                run,
            startPose:          start,
            attachment:         attachment,
            endedInBase:        endedInBase,
            homePenaltyApplied: penalty,
            tokensAfter:        tokensRemaining,
            movesAfter:         movesRemaining
        )
        launches.append(launch)
        return launch
    }

    // MARK: - Aggregate score

    /// The attempt's cumulative score so far: best mission points across launches
    /// plus the shared token bonus.
    public var aggregate: MatchResult {
        let perMission = match.missionIds.map { id in
            bestByMission[id]
                ?? MissionMatchEntry(missionId: id, metObjectiveIds: [], score: 0, success: false)
        }
        let missionPoints = perMission.reduce(0) { $0 + $1.score }
        let tokenPoints   = tokensRemaining * match.pointsPerToken
        return MatchResult(
            perMission:      perMission,
            missionPoints:   missionPoints,
            tokensRemaining: tokensRemaining,
            tokenPoints:     tokenPoints,
            totalScore:      missionPoints + tokenPoints,
            actionsUsed:     match.moveBudget - movesRemaining,
            budgetRemaining: movesRemaining
        )
    }
}

// MARK: - MatchLaunch

/// The outcome of one launch inside a `MatchSession`.
public struct MatchLaunch: Equatable, Sendable {
    /// The underlying single-launch run (snapshots for playback + its scoring).
    public var run:                MatchRun
    /// The (clamped-to-base) pose the rover started this launch from.
    public var startPose:          Pose
    /// The attachment mounted for this launch.
    public var attachment:         RobotAttachment
    /// Did the rover finish inside base?
    public var endedInBase:        Bool
    /// Was the −1 "failed to return home" token penalty applied?
    public var homePenaltyApplied: Bool
    /// Shared token pool after this launch.
    public var tokensAfter:        Int
    /// Shared move budget after this launch.
    public var movesAfter:         Int

    public init(run: MatchRun, startPose: Pose, attachment: RobotAttachment,
                endedInBase: Bool, homePenaltyApplied: Bool,
                tokensAfter: Int, movesAfter: Int) {
        self.run                = run
        self.startPose          = startPose
        self.attachment         = attachment
        self.endedInBase        = endedInBase
        self.homePenaltyApplied = homePenaltyApplied
        self.tokensAfter        = tokensAfter
        self.movesAfter         = movesAfter
    }
}
