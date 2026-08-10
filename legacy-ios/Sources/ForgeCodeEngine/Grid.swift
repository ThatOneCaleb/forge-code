/// A fixed 2D grid of cells. Cells are empty unless listed in `obstacles`.
///
/// Coordinates follow the engine convention: origin `(0, 0)` bottom-left,
/// valid `x` in `0..<width`, valid `y` in `0..<height`.
///
/// `terrain` is a sparse map — cells not listed are implicitly `.normal`.
/// `items` holds collectibles and keys placed on the grid.
public struct Grid: Hashable, Sendable {
    public var width: Int
    public var height: Int
    public var obstacles: Set<Position>
    /// Sparse terrain map. Cells absent from this map are `.normal`.
    public var terrain: [Position: TerrainKind]
    /// Items placed on the grid (collectibles, keys, etc.).
    public var items: [GridItem]

    public init(
        width: Int,
        height: Int,
        obstacles: Set<Position> = [],
        terrain: [Position: TerrainKind] = [:],
        items: [GridItem] = []
    ) {
        self.width = width
        self.height = height
        self.obstacles = obstacles
        self.terrain = terrain
        self.items = items
    }

    /// Whether the position lies within the grid bounds.
    public func contains(_ position: Position) -> Bool {
        position.x >= 0 && position.x < width
            && position.y >= 0 && position.y < height
    }

    /// Whether the position holds an obstacle (wall).
    public func isObstacle(_ position: Position) -> Bool {
        obstacles.contains(position)
    }

    /// Whether the position is impassable: off the grid or an obstacle.
    public func isBlocked(_ position: Position) -> Bool {
        !contains(position) || isObstacle(position)
    }
}

// MARK: - Codable

extension Grid: Codable {
    /// Wire format for a single terrain entry in the JSON array.
    private struct TerrainEntry: Codable {
        var x: Int
        var y: Int
        var kind: TerrainKind
    }

    private enum CodingKeys: String, CodingKey {
        case width
        case height
        case obstacles
        case terrain
        case items
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
        try container.encode(obstacles, forKey: .obstacles)
        let entries = terrain.map { TerrainEntry(x: $0.key.x, y: $0.key.y, kind: $0.value) }
        try container.encode(entries, forKey: .terrain)
        try container.encode(items, forKey: .items)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        width = try container.decode(Int.self, forKey: .width)
        height = try container.decode(Int.self, forKey: .height)
        obstacles = try container.decode(Set<Position>.self, forKey: .obstacles)

        // Terrain and items are optional in JSON for backward compatibility.
        let entries = try container.decodeIfPresent([TerrainEntry].self, forKey: .terrain) ?? []
        terrain = Dictionary(uniqueKeysWithValues: entries.map {
            (Position(x: $0.x, y: $0.y), $0.kind)
        })
        items = try container.decodeIfPresent([GridItem].self, forKey: .items) ?? []
    }
}
