import Foundation

/// Loads bundled robotics field and mission content from JSON.
///
/// This is the ONLY file in the Robotics tier allowed to `import Foundation`.
/// Everything it returns is a pure value type with no Foundation dependency.
public enum RoboticsLibrary {

    // MARK: - Load error

    public enum LoadError: Error, CustomStringConvertible {
        case resourceNotFound(String)
        case decodingFailed(String, underlying: Error)

        public var description: String {
            switch self {
            case let .resourceNotFound(name):
                return "Could not find bundled robotics resource \(name)."
            case let .decodingFailed(name, underlying):
                return "Could not decode \(name): \(underlying)"
            }
        }
    }

    // MARK: - Public API

    /// Load all seed fields from `robotics_fields.json`.
    public static func fields() throws -> [FieldWorld] {
        let raw = try loadRaw(resource: "robotics_fields")
        return try decodeFields(from: raw)
    }

    /// Load all seed missions from `robotics_missions.json`.
    public static func missions() throws -> [Mission] {
        let raw = try loadRaw(resource: "robotics_missions")
        return try decodeMissions(from: raw)
    }

    /// Load all seed matches from `robotics_matches.json`.
    public static func matches() throws -> [Match] {
        let raw = try loadRaw(resource: "robotics_matches")
        return try decodeMatches(from: raw)
    }

    /// Find a specific field by id.
    public static func field(id: String) throws -> FieldWorld? {
        try fields().first { $0.id == id }
    }

    /// Find a specific mission by id.
    public static func mission(id: String) throws -> Mission? {
        try missions().first { $0.id == id }
    }

    /// Find a specific match by id.
    public static func match(id: String) throws -> Match? {
        try matches().first { $0.id == id }
    }

    // MARK: - Raw JSON loading

    private static func loadRaw(resource: String) throws -> Data {
        guard let url = Bundle.module.url(forResource: resource, withExtension: "json") else {
            throw LoadError.resourceNotFound("\(resource).json")
        }
        do {
            return try Data(contentsOf: url)
        } catch {
            throw LoadError.decodingFailed("\(resource).json", underlying: error)
        }
    }

    // MARK: - Decoders

    /// Internal so tests can exercise JSON validation via `@testable import`.
    static func decodeMatches(from data: Data) throws -> [Match] {
        do {
            let raws = try JSONDecoder().decode([RawMatch].self, from: data)
            return raws.map { $0.toMatch() }
        } catch let err as LoadError {
            throw err
        } catch {
            throw LoadError.decodingFailed("robotics_matches.json", underlying: error)
        }
    }

    /// Internal so tests can exercise JSON validation via `@testable import`.
    static func decodeFields(from data: Data) throws -> [FieldWorld] {
        do {
            let raws = try JSONDecoder().decode([RawField].self, from: data)
            return try raws.map { try $0.toFieldWorld() }
        } catch let err as LoadError {
            throw err
        } catch {
            throw LoadError.decodingFailed("robotics_fields.json", underlying: error)
        }
    }

    /// Internal so tests can exercise JSON validation via `@testable import`.
    static func decodeMissions(from data: Data) throws -> [Mission] {
        do {
            let raws = try JSONDecoder().decode([RawMission].self, from: data)
            return try raws.map { try $0.toMission() }
        } catch let err as LoadError {
            throw err
        } catch {
            throw LoadError.decodingFailed("robotics_missions.json", underlying: error)
        }
    }
}

// MARK: - Raw Codable types (JSON → value types)

// Vec2
private struct RawVec2: Codable {
    var x: Double
    var y: Double
    func toVec2() -> Vec2 { Vec2(x: x, y: y) }
}

// FieldRect
private struct RawRect: Codable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    func toFieldRect() -> FieldRect { FieldRect(x: x, y: y, width: width, height: height) }
}

// FieldItem
private struct RawItem: Codable {
    var id: String
    var position: RawVec2
    var color: String?
    var type: String?
    var pickupRadius: Double?

    func toFieldItem() -> FieldItem {
        FieldItem(id: id, position: position.toVec2(),
                  color: color, type: type,
                  pickupRadius: pickupRadius ?? 15)
    }
}

// FieldZone
private struct RawZone: Codable {
    var id: String
    var kind: String
    var rect: RawRect
    var color: String?
    var acceptsItemType: String?

    func toFieldZone() throws -> FieldZone {
        guard let kind = ZoneKind(rawValue: self.kind) else {
            throw RoboticsLibrary.LoadError.decodingFailed(
                "robotics_fields.json",
                underlying: NSError(domain: "RoboticsLibrary", code: 10,
                                    userInfo: [NSLocalizedDescriptionKey:
                                        "Unknown zone kind '\(self.kind)' for zone '\(id)'"])
            )
        }
        return FieldZone(id: id, kind: kind, rect: rect.toFieldRect(),
                         color: color, acceptsItemType: acceptsItemType)
    }
}

// FieldObstacle
private struct RawObstacle: Codable {
    var id: String
    var rect: RawRect
    func toFieldObstacle() -> FieldObstacle {
        FieldObstacle(id: id, rect: rect.toFieldRect())
    }
}

// FieldLine
private struct RawLine: Codable {
    var id: String
    var points: [RawVec2]
    var width: Double?
    func toFieldLine() -> FieldLine {
        FieldLine(id: id, points: points.map { $0.toVec2() }, width: width ?? 2.5)
    }
}

// ColoredRegion
private struct RawColoredRegion: Codable {
    var id: String
    var rect: RawRect
    var color: String
    func toColoredRegion() -> ColoredRegion {
        ColoredRegion(id: id, rect: rect.toFieldRect(), color: color)
    }
}

// FieldMechanism
private struct RawMechanism: Codable {
    var id: String
    var kind: String
    var position: RawVec2
    var trigger: String
    var triggerRadius: Double?
    var unlocksObstacleId: String?
    var requiredAttachment: String?

    func toFieldMechanism() throws -> FieldMechanism {
        guard let kind = MechanismKind(rawValue: self.kind) else {
            throw RoboticsLibrary.LoadError.decodingFailed(
                "robotics_fields.json",
                underlying: NSError(domain: "RoboticsLibrary", code: 12,
                                    userInfo: [NSLocalizedDescriptionKey:
                                        "Unknown mechanism kind '\(self.kind)' for mechanism '\(id)'"])
            )
        }
        guard let trigger = MechanismTrigger(rawValue: self.trigger) else {
            throw RoboticsLibrary.LoadError.decodingFailed(
                "robotics_fields.json",
                underlying: NSError(domain: "RoboticsLibrary", code: 13,
                                    userInfo: [NSLocalizedDescriptionKey:
                                        "Unknown mechanism trigger '\(self.trigger)' for mechanism '\(id)'"])
            )
        }
        var required: RobotAttachment? = nil
        if let raw = requiredAttachment {
            guard let a = RobotAttachment(rawValue: raw) else {
                throw RoboticsLibrary.LoadError.decodingFailed(
                    "robotics_fields.json",
                    underlying: NSError(domain: "RoboticsLibrary", code: 14,
                                        userInfo: [NSLocalizedDescriptionKey:
                                            "Unknown requiredAttachment '\(raw)' for mechanism '\(id)'"])
                )
            }
            required = a
        }
        return FieldMechanism(id: id, kind: kind, position: position.toVec2(),
                              trigger: trigger, triggerRadius: triggerRadius ?? 22,
                              unlocksObstacleId: unlocksObstacleId,
                              requiredAttachment: required)
    }
}

// Pose
private struct RawPose: Codable {
    var x: Double
    var y: Double
    var headingDegrees: Double
    func toPose() -> Pose {
        Pose(position: Vec2(x: x, y: y), headingDegrees: headingDegrees)
    }
}

// FieldWorld
private struct RawField: Codable {
    var id: String
    var name: String
    var widthCm: Double
    var heightCm: Double
    var items: [RawItem]?
    var zones: [RawZone]?
    var obstacles: [RawObstacle]?
    var lines: [RawLine]?
    var coloredRegions: [RawColoredRegion]?
    var mechanisms: [RawMechanism]?
    /// Optional explicit home pose. When absent, `FieldWorld.resolvedHomePose` derives
    /// it from well-known zones or falls back to the south-centre edge.
    var homePose: RawPose?

    func toFieldWorld() throws -> FieldWorld {
        FieldWorld(
            id:             id,
            name:           name,
            widthCm:        widthCm,
            heightCm:       heightCm,
            items:          (items ?? []).map { $0.toFieldItem() },
            zones:          try (zones ?? []).map { try $0.toFieldZone() },
            obstacles:      (obstacles ?? []).map { $0.toFieldObstacle() },
            lines:          (lines ?? []).map { $0.toFieldLine() },
            coloredRegions: (coloredRegions ?? []).map { $0.toColoredRegion() },
            mechanisms:     try (mechanisms ?? []).map { try $0.toFieldMechanism() },
            homePose:       homePose?.toPose()
        )
    }
}

// Mission
private struct RawObjective: Codable {
    var id: String
    var kind: String
    var points: Int
    var description: String
    var targetZoneId: String?
    var targetItemId: String?
    var targetAngle: Double?
    var targetX: Double?
    var targetY: Double?
    var toleranceCm: Double?
    var expectedColor: String?
    var targetMechanismId: String?
    var isRequired: Bool?

    func toMissionObjective() throws -> MissionObjective {
        guard let kind = ObjectiveKind(rawValue: self.kind) else {
            throw RoboticsLibrary.LoadError.decodingFailed(
                "robotics_missions.json",
                underlying: NSError(domain: "RoboticsLibrary", code: 11,
                                    userInfo: [NSLocalizedDescriptionKey:
                                        "Unknown objective kind '\(self.kind)' for objective '\(id)'"])
            )
        }
        return MissionObjective(
            id:            id,
            kind:          kind,
            points:        points,
            description:   description,
            targetZoneId:  targetZoneId,
            targetItemId:  targetItemId,
            targetAngle:   targetAngle,
            targetX:       targetX,
            targetY:       targetY,
            toleranceCm:   toleranceCm,
            expectedColor: expectedColor,
            targetMechanismId: targetMechanismId,
            isRequired:    isRequired ?? false
        )
    }
}

private struct RawSuccessRule: Codable {
    var type: String
    var value: Int?
}

private struct RawMission: Codable {
    var id: String
    var fieldId: String
    var title: String
    var brief: String
    var successRule: RawSuccessRule
    var objectives: [RawObjective]
    /// Optional in JSON; defaults to 1 and is clamped to 1–5 by `Mission.init`.
    var difficulty: Int?
    /// Optional in JSON; nil means no per-mission cap (simulator's own budget applies).
    var maxActions: Int?

    func toMission() throws -> Mission {
        let rule: MissionSuccessRule
        switch successRule.type {
        case "allRequired":
            rule = .allRequired
        case "scoreThreshold":
            guard let v = successRule.value else {
                throw RoboticsLibrary.LoadError.decodingFailed(
                    "robotics_missions.json",
                    underlying: NSError(domain: "RoboticsLibrary",
                                        code: 1,
                                        userInfo: [NSLocalizedDescriptionKey:
                                            "scoreThreshold needs a value"])
                )
            }
            rule = .scoreThreshold(v)
        case "allRequiredAndScore":
            guard let v = successRule.value else {
                throw RoboticsLibrary.LoadError.decodingFailed(
                    "robotics_missions.json",
                    underlying: NSError(domain: "RoboticsLibrary",
                                        code: 2,
                                        userInfo: [NSLocalizedDescriptionKey:
                                            "allRequiredAndScore needs a value"])
                )
            }
            rule = .allRequiredAndScore(v)
        default:
            throw RoboticsLibrary.LoadError.decodingFailed(
                "robotics_missions.json",
                underlying: NSError(domain: "RoboticsLibrary", code: 12,
                                    userInfo: [NSLocalizedDescriptionKey:
                                        "Unknown successRule type '\(successRule.type)' for mission '\(id)'"])
            )
        }
        return Mission(
            id:          id,
            fieldId:     fieldId,
            title:       title,
            brief:       brief,
            objectives:  try objectives.map { try $0.toMissionObjective() },
            successRule: rule,
            difficulty:  difficulty ?? 1,
            maxActions:  maxActions
        )
    }
}

// Match
private struct RawMatch: Codable {
    var id:             String
    var fieldId:        String
    var name:           String
    var brief:          String
    var missionIds:     [String]
    var moveBudget:     Int
    var startingTokens: Int?
    var pointsPerToken: Int?
    var parScore:       Int?

    func toMatch() -> Match {
        Match(
            id:             id,
            fieldId:        fieldId,
            name:           name,
            brief:          brief,
            missionIds:     missionIds,
            moveBudget:     moveBudget,
            startingTokens: startingTokens ?? 6,
            pointsPerToken: pointsPerToken ?? 10,
            parScore:       parScore
        )
    }
}
