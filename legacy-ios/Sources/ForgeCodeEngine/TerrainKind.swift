/// The terrain type of a grid cell. Cells not explicitly listed in
/// `Grid.terrain` are implicitly `.normal`.
///
/// `portal` carries a string identifier; two portals with the same id form a
/// linked pair — entering one teleports the robot to the other.
public enum TerrainKind: Hashable, Sendable {
    case normal
    case ice
    case mud
    case conveyorNorth
    case conveyorSouth
    case conveyorEast
    case conveyorWest
    case portal(String)
}

// MARK: - Codable

extension TerrainKind: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case id
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .normal:
            var c = encoder.singleValueContainer()
            try c.encode("normal")
        case .ice:
            var c = encoder.singleValueContainer()
            try c.encode("ice")
        case .mud:
            var c = encoder.singleValueContainer()
            try c.encode("mud")
        case .conveyorNorth:
            var c = encoder.singleValueContainer()
            try c.encode("conveyorNorth")
        case .conveyorSouth:
            var c = encoder.singleValueContainer()
            try c.encode("conveyorSouth")
        case .conveyorEast:
            var c = encoder.singleValueContainer()
            try c.encode("conveyorEast")
        case .conveyorWest:
            var c = encoder.singleValueContainer()
            try c.encode("conveyorWest")
        case let .portal(id):
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode("portal", forKey: .type)
            try c.encode(id, forKey: .id)
        }
    }

    public init(from decoder: Decoder) throws {
        // Try the keyed container first (for portal), then fall back to a
        // plain string for the simple cases.
        if let keyed = try? decoder.container(keyedBy: CodingKeys.self),
           let type = try? keyed.decode(String.self, forKey: .type),
           type == "portal",
           let id = try? keyed.decode(String.self, forKey: .id) {
            self = .portal(id)
            return
        }
        let raw = try decoder.singleValueContainer().decode(String.self)
        switch raw {
        case "normal":         self = .normal
        case "ice":            self = .ice
        case "mud":            self = .mud
        case "conveyorNorth":  self = .conveyorNorth
        case "conveyorSouth":  self = .conveyorSouth
        case "conveyorEast":   self = .conveyorEast
        case "conveyorWest":   self = .conveyorWest
        default:
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Unknown TerrainKind: \(raw)"
            )
        }
    }
}
