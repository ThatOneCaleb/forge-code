/// An item placed on the grid. Items are auto-collected when the robot
/// moves onto their cell.
public struct GridItem: Codable, Hashable, Sendable {
    /// Unique identifier within the challenge, e.g. `"gem-1"`.
    public let id: String
    /// Cell on which the item sits.
    public let position: Position
    /// What kind of item this is.
    public let kind: GridItemKind

    public init(id: String, position: Position, kind: GridItemKind) {
        self.id = id
        self.position = position
        self.kind = kind
    }
}

/// The variety of a `GridItem`.
public enum GridItemKind: String, Codable, Hashable, Sendable {
    /// Auto-collected when the robot steps on the cell; counts toward
    /// `Challenge.collectGoal`.
    case collectible
    /// Auto-collected; models a key that may unlock a door in future lessons.
    case key
}
