/// A competitive field round: one program, run once, scores many missions at
/// once, on a move budget, with precision tokens.
///
/// A `Match` is the top-level object the R2 UI plays. It sits *above* individual
/// `Mission`s and reuses their scoring — it does not replace them.
///
/// - `missionIds`: a *curated* subset of the field's missions that coexist
///   cleanly in one run. Not necessarily all missions on the field; avoid heavy
///   objective overlap that would double-count the same physical action.
/// - `moveBudget`: the match "length" expressed deterministically — total robot
///   actions allowed for the whole run. Running out ends the run gracefully and
///   scores whatever was completed; it is NOT a hard fail.
/// - `startingTokens`: precision tokens available at the start. Spending one
///   (via `returnHome()`) resets accumulated navigation error at the cost of
///   `pointsPerToken` points from the final token bonus.
/// - `pointsPerToken`: points earned per unspent token at run end. Default 10.
/// - `parScore`: optional target total score shown to the kid as the "par" goal.
///   Purely informational; does not affect simulation logic.
///
/// No Foundation dependency (JSON decoding is in `RoboticsLibrary`).
public struct Match: Equatable, Sendable {

    public var id:             String
    public var fieldId:        String
    public var name:           String
    /// Short kid-facing description shown before the run.
    public var brief:          String
    /// Ordered list of mission ids included in this match.
    public var missionIds:     [String]
    /// Total robot actions allowed for the whole run.
    public var moveBudget:     Int
    /// Precision tokens available at the start (default 6).
    public var startingTokens: Int
    /// Points per unspent token at run end (default 10).
    public var pointsPerToken: Int
    /// Optional kid-facing par score (informational only).
    public var parScore:       Int?

    public init(
        id:             String,
        fieldId:        String,
        name:           String,
        brief:          String,
        missionIds:     [String],
        moveBudget:     Int,
        startingTokens: Int    = 6,
        pointsPerToken: Int    = 10,
        parScore:       Int?   = nil
    ) {
        self.id             = id
        self.fieldId        = fieldId
        self.name           = name
        self.brief          = brief
        self.missionIds     = missionIds
        self.moveBudget     = moveBudget
        self.startingTokens = startingTokens
        self.pointsPerToken = pointsPerToken
        self.parScore       = parScore
    }
}
