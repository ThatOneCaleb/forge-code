/// A single puzzle: the grid, where the robot starts, where it must end,
/// which commands the authoring UI allows, and an optional block budget.
///
/// This drives execution and lives in lesson JSON. The `Simulator` reads
/// `grid`, `start`, `goal`, `maxBlocks`, `collectGoal`, and `parMoves`;
/// `allowedCommands` is a UI/authoring concern the simulator does not police.
public struct Challenge: Codable, Hashable, Sendable {
    public var grid: Grid
    public var start: RobotState
    public var goal: Position
    public var allowedCommands: [CommandKind]
    public var maxBlocks: Int?
    /// Number of items the robot must collect for the run to succeed.
    /// `nil` means no collection requirement.
    public var collectGoal: Int?
    /// Move-step par for efficiency star rating. `nil` means no rating.
    public var parMoves: Int?
    /// Difficulty for UI badge and boss-level indicators. `nil` for legacy challenges.
    public var difficulty: ChallengeDifficulty?
    /// Mechanic concept being introduced. Triggers a Commander Atlas tutorial popup the first time
    /// the player opens a challenge with this tag. `nil` means no popup.
    public var conceptIntro: String?

    public init(
        grid: Grid,
        start: RobotState,
        goal: Position,
        allowedCommands: [CommandKind],
        maxBlocks: Int? = nil,
        collectGoal: Int? = nil,
        parMoves: Int? = nil,
        difficulty: ChallengeDifficulty? = nil,
        conceptIntro: String? = nil
    ) {
        self.grid = grid
        self.start = start
        self.goal = goal
        self.allowedCommands = allowedCommands
        self.maxBlocks = maxBlocks
        self.collectGoal = collectGoal
        self.parMoves = parMoves
        self.difficulty = difficulty
        self.conceptIntro = conceptIntro
    }
}
