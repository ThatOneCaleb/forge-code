/// Why a run failed. Each case carries a kid-friendly `message`.
public enum FailureReason: Hashable, Sendable {
    /// Moved into an obstacle at the given cell.
    case hitWall(at: Position)
    /// Moved off the edge of the grid to the given (out-of-bounds) cell.
    case wentOffGrid(to: Position)
    /// The program uses more blocks than the lesson allows.
    case ranOutOfBlocks(limit: Int, used: Int)
    /// The program ran too long (guards runaway/empty loops).
    case tooManySteps(limit: Int)
    /// The robot stopped somewhere other than the goal.
    case didNotReachGoal(finalPosition: Position)
    /// The robot reached the goal but did not collect all required items.
    case didNotCollectAll(collected: Int, required: Int)

    /// An encouraging, actionable explanation for an 8–15 year old.
    public var message: String {
        switch self {
        case let .hitWall(at):
            return "Ouch! The robot bumped into a wall at (\(at.x), \(at.y)). Try steering around it."
        case let .wentOffGrid(to):
            return "The robot walked off the edge toward (\(to.x), \(to.y)). Keep it on the grid!"
        case let .ranOutOfBlocks(limit, used):
            return "That used \(used) blocks, but this puzzle allows only \(limit). Can you find a shorter way?"
        case let .tooManySteps(limit):
            return "The robot kept going for over \(limit) steps. Check for a loop that never stops."
        case let .didNotReachGoal(finalPosition):
            return "So close! The robot stopped at (\(finalPosition.x), \(finalPosition.y)) instead of the goal."
        case let .didNotCollectAll(collected, required):
            return "The robot reached the goal but only collected \(collected) of \(required) items. Try picking them all up first!"
        }
    }
}

/// The high-level result of a run.
public enum ExecutionOutcome: Hashable, Sendable {
    case success
    case failure(FailureReason)
}

/// The full result of running a program against a challenge.
///
/// `frames[0]` is the start state; one frame is appended per atomic step
/// (each `move`/turn). The UI plays these back; the engine computes them.
///
/// `itemsCollected` holds the ids of every item picked up during the run.
/// `moveStepsUsed` counts move steps (mud cells count double; ice slides
/// count as 1 regardless). `starRating` is `nil` when no `parMoves` is set.
public struct ExecutionResult: Hashable, Sendable {
    public var outcome: ExecutionOutcome
    public var frames: [RobotState]
    /// IDs of items collected during the run, in collection order.
    public var itemsCollected: Set<String>
    /// Total move steps charged during the run (mud double, ice single).
    public var moveStepsUsed: Int
    /// 0–3 star rating against `Challenge.parMoves`; `nil` if no par set.
    public var starRating: Int?

    public init(
        outcome: ExecutionOutcome,
        frames: [RobotState],
        itemsCollected: Set<String> = [],
        moveStepsUsed: Int = 0,
        starRating: Int? = nil
    ) {
        self.outcome = outcome
        self.frames = frames
        self.itemsCollected = itemsCollected
        self.moveStepsUsed = moveStepsUsed
        self.starRating = starRating
    }

    /// Whether the run reached the goal (and met all other success criteria).
    public var isSuccess: Bool {
        if case .success = outcome { return true }
        return false
    }
}
