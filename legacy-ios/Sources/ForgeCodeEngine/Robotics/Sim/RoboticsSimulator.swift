/// Runs a robotics program against a world (+ optional mission) and produces
/// a deterministic `RoboticsRun`.
///
/// Same program + same world ⇒ same `RoboticsRun`, always.
/// No Foundation dependency.
public struct RoboticsSimulator {

    // MARK: - Configuration

    /// Maximum interpreter steps (guards runaway loops / infinite recursion).
    public let stepBudget:   Int
    /// Maximum robot actions (drive/arm/gripper calls) per run.
    public let actionBudget: Int

    public init(stepBudget: Int = 50_000, actionBudget: Int = 500) {
        self.stepBudget   = stepBudget
        self.actionBudget = actionBudget
    }

    // MARK: - Run

    /// Execute `program` (source text) against `world`, optionally scored
    /// against `mission`. Returns a deterministic `RoboticsRun`.
    public func run(
        program:  String,
        world:    FieldWorld,
        robot:    RobotModel  = RobotModel(),
        mission:  Mission?    = nil
    ) -> RoboticsRun {

        // 1. Parse
        let parsedProgram: RProgram
        do {
            parsedProgram = try RParser.parse(program)
        } catch let err as RParseError {
            // Parse failure → return a run with just the initial snapshot + error
            let initialSnap = RobotSnapshot(
                pose: robot.pose, armAngle: robot.armAngle,
                isGripperOpen: robot.isGripperOpen, heldObjectId: robot.heldObjectId,
                itemStates: world.items.map { ItemState(id: $0.id, position: $0.position) }
            )
            return RoboticsRun(snapshots: [initialSnap], sensorLog: [],
                               failureKind: .runtimeError(err.message))
        } catch {
            let initialSnap = RobotSnapshot(
                pose: robot.pose, armAngle: robot.armAngle,
                isGripperOpen: robot.isGripperOpen, heldObjectId: robot.heldObjectId,
                itemStates: world.items.map { ItemState(id: $0.id, position: $0.position) }
            )
            return RoboticsRun(snapshots: [initialSnap], sensorLog: [],
                               failureKind: .runtimeError("Something went wrong while setting up your program. Check for typos and try again."))
        }

        // 2. Build sim state + API bindings.
        // If the mission has a per-mission action cap, use the stricter of the two budgets.
        let effectiveActionBudget: Int
        if let missionCap = mission?.maxActions {
            effectiveActionBudget = min(actionBudget, missionCap)
        } else {
            effectiveActionBudget = actionBudget
        }
        // Single-mission runs use .failRun (collision is a hard fail). No token bookkeeping.
        let state = RobotAPIFactory.SimState(
            robot: robot, world: world, actionBudget: effectiveActionBudget,
            collisionPolicy: .failRun, startingTokens: nil
        )
        let bindings = RobotAPIFactory.makeBindings(state: state)
        var interp = RInterpreter(stepBudget: stepBudget, api: bindings)

        // 3. Execute
        var runFailure: RunFailureKind? = nil
        do {
            try interp.execute(parsedProgram)
        } catch let err as RRuntimeError {
            switch err.kind {
            case let .stepBudgetExceeded(limit):
                runFailure = .stepBudgetExceeded(limit: limit)
            case let .actionBudgetExceeded(limit):
                runFailure = .actionBudgetExceeded(limit: limit)
            default:
                runFailure = .runtimeError(err.message)
            }
        } catch let actionErr as RobotAPIFactory.SimActionError {
            switch actionErr {
            case let .collision(obsId):
                runFailure = .collision(obstacleId: obsId)
            case .outOfBounds:
                runFailure = .outOfBounds
            case let .actionBudgetExceeded(limit):
                runFailure = .actionBudgetExceeded(limit: limit)
            }
        } catch {
            runFailure = .runtimeError("Your program encountered an unexpected problem. Double-check your logic and try again.")
        }

        // 4. Score mission (if provided)
        let missionResult = mission.map { scoreMission($0, state: state, world: world) }

        return RoboticsRun(
            snapshots:     state.snapshots,
            sensorLog:     state.sensorLog,
            missionResult: missionResult,
            failureKind:   runFailure
        )
    }

    // MARK: - Match run

    /// Execute `program` once against `world` under match rules, then score
    /// every mission listed in `match.missionIds` against the final state.
    ///
    /// Match rules differ from single-mission runs in three ways:
    ///   1. **Collision policy** = `.blockAndContinue`: a colliding move stops the
    ///      robot flush against the obstacle and execution continues. A budget-
    ///      exhausted run ends gracefully and is still scored.
    ///   2. **Move budget** = `match.moveBudget`. Running out is NOT a hard fail —
    ///      whatever was completed is scored.
    ///   3. **Precision tokens** start at `match.startingTokens`; each `returnHome()`
    ///      call spends 1 token (floor 0). Token bonus = remaining × pointsPerToken.
    ///
    /// Deterministic: same program + world + match ⇒ identical `MatchRun`.
    ///
    /// Full match run: executes the program and scores against the provided missions.
    ///
    /// This is the primary API. Supply the `Mission` objects that correspond to
    /// `match.missionIds` (load them from `RoboticsLibrary` or construct inline).
    /// Missions not found in `missions` array are scored as 0 pts / not successful.
    public func runMatch(
        program:  String,
        world:    FieldWorld,
        match:    Match,
        missions: [Mission],
        robot:    RobotModel = RobotModel()
    ) -> MatchRun {

        // 1. Parse
        let parsedProgram: RProgram
        do {
            parsedProgram = try RParser.parse(program)
        } catch let err as RParseError {
            let initialSnap = RobotSnapshot(
                pose: robot.pose, armAngle: robot.armAngle,
                isGripperOpen: robot.isGripperOpen, heldObjectId: robot.heldObjectId,
                itemStates: world.items.map { ItemState(id: $0.id, position: $0.position) }
            )
            return emptyMatchRun(
                snapshots: [initialSnap],
                match: match,
                failureKind: .runtimeError(err.message)
            )
        } catch {
            let initialSnap = RobotSnapshot(
                pose: robot.pose, armAngle: robot.armAngle,
                isGripperOpen: robot.isGripperOpen, heldObjectId: robot.heldObjectId,
                itemStates: world.items.map { ItemState(id: $0.id, position: $0.position) }
            )
            return emptyMatchRun(
                snapshots: [initialSnap],
                match: match,
                failureKind: .runtimeError("Something went wrong setting up the match. Check for typos and try again.")
            )
        }

        // 2. Build state with match settings.
        let state = RobotAPIFactory.SimState(
            robot: robot, world: world,
            actionBudget: match.moveBudget,
            collisionPolicy: .blockAndContinue,
            startingTokens: match.startingTokens
        )
        let bindings = RobotAPIFactory.makeBindings(state: state)
        var interp = RInterpreter(stepBudget: stepBudget, api: bindings)

        // 3. Execute
        var runFailure: RunFailureKind? = nil
        do {
            try interp.execute(parsedProgram)
        } catch let err as RRuntimeError {
            switch err.kind {
            case let .stepBudgetExceeded(limit):
                runFailure = .stepBudgetExceeded(limit: limit)
            case let .actionBudgetExceeded(limit):
                // Budget exhaustion in a match: graceful end, still score.
                runFailure = .actionBudgetExceeded(limit: limit)
            default:
                runFailure = .runtimeError(err.message)
            }
        } catch let actionErr as RobotAPIFactory.SimActionError {
            switch actionErr {
            case let .collision(obsId):
                runFailure = .collision(obstacleId: obsId)
            case .outOfBounds:
                runFailure = .outOfBounds
            case let .actionBudgetExceeded(limit):
                runFailure = .actionBudgetExceeded(limit: limit)
            }
        } catch {
            runFailure = .runtimeError("Your program hit an unexpected problem during the match. Check your logic and try again.")
        }

        // 4. Score each mission in match order.
        var missionPoints = 0
        let missionById = Dictionary(missions.map { ($0.id, $0) }, uniquingKeysWith: { f, _ in f })
        let perMission: [MissionMatchEntry] = match.missionIds.map { missionId in
            guard let mission = missionById[missionId] else {
                return MissionMatchEntry(
                    missionId: missionId,
                    metObjectiveIds: [],
                    score: 0,
                    success: false
                )
            }
            let result = scoreMission(mission, state: state, world: world)
            missionPoints += result.score
            return MissionMatchEntry(
                missionId: missionId,
                metObjectiveIds: result.metObjectiveIds,
                score: result.score,
                success: result.success
            )
        }

        // 5. Token bonus.
        let tokens = state.tokensRemaining ?? match.startingTokens
        let tokenPoints = tokens * match.pointsPerToken
        let totalScore = missionPoints + tokenPoints

        let result = MatchResult(
            perMission:      perMission,
            missionPoints:   missionPoints,
            tokensRemaining: tokens,
            tokenPoints:     tokenPoints,
            totalScore:      totalScore,
            actionsUsed:     state.actionCount,
            budgetRemaining: max(0, match.moveBudget - state.actionCount)
        )
        return MatchRun(
            snapshots:   state.snapshots,
            sensorLog:   state.sensorLog,
            result:      result,
            failureKind: runFailure
        )
    }

    /// Builds a zero-score `MatchRun` for early exits (parse failure).
    private func emptyMatchRun(snapshots: [RobotSnapshot], match: Match,
                               failureKind: RunFailureKind) -> MatchRun {
        let tokenPoints = match.startingTokens * match.pointsPerToken
        let result = MatchResult(
            perMission:      match.missionIds.map {
                MissionMatchEntry(missionId: $0, metObjectiveIds: [], score: 0, success: false)
            },
            missionPoints:   0,
            tokensRemaining: match.startingTokens,
            tokenPoints:     tokenPoints,
            totalScore:      tokenPoints,
            actionsUsed:     0,
            budgetRemaining: match.moveBudget
        )
        return MatchRun(snapshots: snapshots, sensorLog: [], result: result,
                        failureKind: failureKind)
    }

    // MARK: - Mission scoring

    private func scoreMission(_ mission: Mission, state: RobotAPIFactory.SimState,
                               world: FieldWorld) -> MissionResult {
        var metIds: Set<String> = []
        var totalScore = 0

        let finalRobot = state.robot
        _ = state.snapshots.last  // finalSnap reserved for future UI hints

        for obj in mission.objectives {
            if objectiveMet(obj, state: state, mission: mission, finalRobot: finalRobot) {
                metIds.insert(obj.id)
                totalScore += obj.points
            }
        }

        // Evaluate success rule
        let success: Bool
        var failureReason: String? = nil

        switch mission.successRule {
        case .allRequired:
            let requiredIds = Set(mission.objectives.filter { $0.isRequired }.map { $0.id })
            let missingRequired = requiredIds.subtracting(metIds)
            success = missingRequired.isEmpty
            if !success {
                let descriptions = mission.objectives
                    .filter { missingRequired.contains($0.id) }
                    .map { $0.description }
                failureReason = "Not all required objectives were met. Still needed: \(descriptions.joined(separator: ", "))."
            }
        case let .scoreThreshold(threshold):
            success = totalScore >= threshold
            if !success {
                failureReason = "Score \(totalScore) didn't reach the target of \(threshold) points."
            }
        case let .allRequiredAndScore(threshold):
            let requiredIds = Set(mission.objectives.filter { $0.isRequired }.map { $0.id })
            let missingRequired = requiredIds.subtracting(metIds)
            success = missingRequired.isEmpty && totalScore >= threshold
            if !success {
                if !missingRequired.isEmpty {
                    let descriptions = mission.objectives
                        .filter { missingRequired.contains($0.id) }
                        .map { $0.description }
                    failureReason = "Not all required objectives were met. Still needed: \(descriptions.joined(separator: ", "))."
                } else {
                    failureReason = "Score \(totalScore) didn't reach the target of \(threshold) points."
                }
            }
        }

        return MissionResult(metObjectiveIds: metIds, score: totalScore,
                             success: success, failureReason: failureReason)
    }

    private func objectiveMet(
        _ obj: MissionObjective,
        state: RobotAPIFactory.SimState,
        mission: Mission,
        finalRobot: RobotModel
    ) -> Bool {
        switch obj.kind {

        case .reachZone:
            guard let zoneId = obj.targetZoneId,
                  let zone = state.world.zone(id: zoneId) else { return false }
            return zone.rect.contains(finalRobot.pose.position)

        case .reachPose:
            guard let tx = obj.targetX, let ty = obj.targetY else { return false }
            let target = Vec2(x: tx, y: ty)
            let tol = obj.toleranceCm ?? 20
            return finalRobot.pose.position.distance(to: target) <= tol

        case .pickUpItem:
            guard let itemId = obj.targetItemId else { return false }
            // Objective met if: (a) robot is currently holding it, or
            // (b) it was ever held (check deposit log or item is in a zone)
            if finalRobot.heldObjectId == itemId { return true }
            // Check if it was deposited somewhere
            if state.depositLog[itemId] != nil { return true }
            // Check item state: if it's in a zone, it was picked and deposited
            if let itemState = state.itemStates[itemId], itemState.inZoneId != nil { return true }
            return false

        case .depositItemInZone:
            guard let itemId = obj.targetItemId,
                  let zoneId = obj.targetZoneId else { return false }
            return state.depositLog[itemId] == zoneId

        case .detectColorInZone:
            guard let zoneId = obj.targetZoneId,
                  let expectedColor = obj.expectedColor else { return false }
            // Check sensor log for a color reading that occurred while in zone
            guard let zone = state.world.zone(id: zoneId) else { return false }
            for (_, event) in state.sensorLog.enumerated() {
                if case let .color(colorValue) = event.kind,
                   colorValue.lowercased() == expectedColor.lowercased() {
                    // Find the snapshot for this frame index
                    let snapIdx = event.frameIndex
                    if snapIdx < state.snapshots.count {
                        let pos = state.snapshots[snapIdx].pose.position
                        if zone.rect.contains(pos) { return true }
                    }
                }
            }
            return false

        case .armToAngle:
            guard let targetAngle = obj.targetAngle else { return false }
            let tolerance = 5.0  // degrees
            return abs(finalRobot.armAngle - targetAngle) <= tolerance

        case .activateMechanism:
            guard let mechId = obj.targetMechanismId else { return false }
            return state.mechanismStates[mechId] == true

        case .visitTile:
            guard let tx = obj.targetX, let ty = obj.targetY else { return false }
            let target = Vec2(x: tx, y: ty)
            let tol = obj.toleranceCm ?? 18
            let poses = state.snapshots.map { $0.pose.position }
            guard !poses.isEmpty else { return false }
            // A drive records only start/end snapshots, so test each straight
            // segment of the path, not just the vertices.
            for i in poses.indices {
                if poses[i].distance(to: target) <= tol { return true }
                if i + 1 < poses.count,
                   Self.distanceToSegment(target, a: poses[i], b: poses[i + 1]) <= tol {
                    return true
                }
            }
            return false
        }
    }

    /// Perpendicular distance from point `p` to segment `a`–`b`.
    private static func distanceToSegment(_ p: Vec2, a: Vec2, b: Vec2) -> Double {
        let abx = b.x - a.x, aby = b.y - a.y
        let apx = p.x - a.x, apy = p.y - a.y
        let len2 = abx * abx + aby * aby
        if len2 == 0 { return a.distance(to: p) }
        let t = min(max((apx * abx + apy * aby) / len2, 0), 1)
        let closest = Vec2(x: a.x + t * abx, y: a.y + t * aby)
        return closest.distance(to: p)
    }
}
