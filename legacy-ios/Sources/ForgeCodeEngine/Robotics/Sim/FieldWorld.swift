/// The static field layout for a robotics mission.
///
/// A `FieldWorld` describes the physical environment: bounds, pickable items,
/// deposit zones, obstacles, line sensors, colored regions. It is value-typed
/// and purely descriptive — the simulator keeps a *mutable copy* of item states.
/// No Foundation dependency (content is loaded by `RoboticsLibrary`).

// MARK: - Geometric primitives

/// An axis-aligned rectangle in field coordinates (cm).
public struct FieldRect: Equatable, Hashable, Sendable {
    public var x:      Double   // left edge
    public var y:      Double   // bottom edge
    public var width:  Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x; self.y = y; self.width = width; self.height = height
    }

    public func contains(_ point: Vec2) -> Bool {
        point.x >= x && point.x <= x + width &&
        point.y >= y && point.y <= y + height
    }

    /// Centre of the rect.
    public var centre: Vec2 { Vec2(x: x + width / 2, y: y + height / 2) }
}

/// A circle in field coordinates (cm).
public struct FieldCircle: Equatable, Hashable, Sendable {
    public var centre: Vec2
    public var radius: Double

    public init(centre: Vec2, radius: Double) {
        self.centre = centre; self.radius = radius
    }

    public func contains(_ point: Vec2) -> Bool {
        centre.distance(to: point) <= radius
    }
}

// MARK: - FieldItem

/// A pickable object in the field.
public struct FieldItem: Equatable, Hashable, Sendable {
    public var id:       String
    public var position: Vec2
    /// Optional semantic colour ("red", "blue", "green", etc.) read by the color sensor.
    public var color:    String?
    /// Optional logical type tag ("cube", "ball", etc.) for mission scripting.
    public var type:     String?
    /// Pickup radius: the robot gripper must be within this distance (cm).
    public var pickupRadius: Double

    public init(id: String, position: Vec2, color: String? = nil,
                type: String? = nil, pickupRadius: Double = 15) {
        self.id = id; self.position = position; self.color = color
        self.type = type; self.pickupRadius = pickupRadius
    }
}

// MARK: - FieldZone

public enum ZoneKind: String, Equatable, Hashable, Sendable {
    case deposit        // items can be dropped here
    case detection      // color/sensor detection area
    case goal           // robot must reach this zone
}

/// A rectangular zone used for deposit, detection, or goal-reaching.
public struct FieldZone: Equatable, Hashable, Sendable {
    public var id:             String
    public var kind:           ZoneKind
    public var rect:           FieldRect
    /// Optional colour associated with this zone (for detectColorInZone objectives).
    public var color:          String?
    /// Optional type of item accepted here (nil = accepts any).
    public var acceptsItemType: String?

    public init(id: String, kind: ZoneKind, rect: FieldRect,
                color: String? = nil, acceptsItemType: String? = nil) {
        self.id = id; self.kind = kind; self.rect = rect
        self.color = color; self.acceptsItemType = acceptsItemType
    }
}

// MARK: - FieldObstacle

/// A rectangular obstacle the robot cannot enter (collision detection).
public struct FieldObstacle: Equatable, Hashable, Sendable {
    public var id:   String
    public var rect: FieldRect

    public init(id: String, rect: FieldRect) {
        self.id = id; self.rect = rect
    }
}

// MARK: - FieldLine

/// A polyline the line-follower sensors read.
public struct FieldLine: Equatable, Hashable, Sendable {
    public var id:     String
    public var points: [Vec2]
    /// Width of the line (cm); sensors within half-width count as on-line.
    public var width:  Double

    public init(id: String, points: [Vec2], width: Double = 2.5) {
        self.id = id; self.points = points; self.width = width
    }
}

// MARK: - FieldMechanism

/// How a mechanism is activated by the robot.
public enum MechanismTrigger: String, Equatable, Hashable, Sendable {
    /// Robot drives its centre within `triggerRadius` of the mechanism (a push/bump).
    case bump
    /// Robot lowers the arm (≥ pickup threshold) with its centre within `triggerRadius`.
    case armPress
    /// Robot closes the gripper (a grab/pull) with the arm lowered and its centre
    /// within `triggerRadius` — used to pry a buried object loose from the ground.
    case gripperPull
}

/// The visual/gameplay archetype of a mechanism (drives the 3D reaction).
public enum MechanismKind: String, Equatable, Hashable, Sendable {
    case lever      // tips over when pressed
    case gate       // slides open — can unlock (remove) a linked obstacle
    case platform   // rises when activated
    case launcher   // a launch lever: trips → a rocket lifts off the pad
    case excavator  // a buried sample: pull it up out of the ground to study it
}

/// An interactive field model: the robot triggers it, it changes state (recorded
/// in the run trace for the UI to animate), optionally scores via an
/// `activateMechanism` objective, and can unlock a linked obstacle (a gate
/// opening a blocked corridor). One-way: once activated it stays activated.
public struct FieldMechanism: Equatable, Hashable, Sendable {
    public var id:            String
    public var kind:          MechanismKind
    public var position:      Vec2
    public var trigger:       MechanismTrigger
    /// Activation distance from robot centre to `position` (cm). Small radii
    /// (< ~12) demand precise driving/arm placement — the "hard" missions.
    public var triggerRadius: Double
    /// Obstacle id removed from the world when this mechanism activates
    /// (e.g. a gate bar blocking a corridor). nil = purely scoring/visual.
    public var unlocksObstacleId: String?
    /// If set, the rover must have this exact attachment mounted for the
    /// mechanism to fire — the "bring the right tool" decision. nil = any tool.
    public var requiredAttachment: RobotAttachment?

    public init(id: String, kind: MechanismKind, position: Vec2,
                trigger: MechanismTrigger, triggerRadius: Double = 22,
                unlocksObstacleId: String? = nil,
                requiredAttachment: RobotAttachment? = nil) {
        self.id = id; self.kind = kind; self.position = position
        self.trigger = trigger; self.triggerRadius = triggerRadius
        self.unlocksObstacleId = unlocksObstacleId
        self.requiredAttachment = requiredAttachment
    }
}

// MARK: - ColoredRegion

/// A rectangular region the color sensor reads as a specific colour.
public struct ColoredRegion: Equatable, Hashable, Sendable {
    public var id:    String
    public var rect:  FieldRect
    public var color: String    // "red", "blue", "green", "yellow", etc.

    public init(id: String, rect: FieldRect, color: String) {
        self.id = id; self.rect = rect; self.color = color
    }
}

// MARK: - FieldWorld

/// The complete static description of a field.
public struct FieldWorld: Equatable, Sendable {
    public var id:             String
    public var name:           String
    public var widthCm:        Double
    public var heightCm:       Double
    public var items:          [FieldItem]
    public var zones:          [FieldZone]
    public var obstacles:      [FieldObstacle]
    public var lines:          [FieldLine]
    public var coloredRegions: [ColoredRegion]
    /// Interactive mechanisms (levers, gates, platforms) the robot can activate.
    public var mechanisms:     [FieldMechanism]

    /// The match start pose and `returnHome()` teleport target.
    ///
    /// Loader default rule (applied when absent from JSON):
    ///   1. Centre of the zone with id `"base_camp"` (field_arena), heading north (0°).
    ///   2. Centre of the zone with id `"home_base"` (field_warehouse), heading north (0°).
    ///   3. Fallback: south-centre of the field `(widthCm/2, 10)`, heading north (0°).
    ///
    /// An explicit `homePose` in JSON always overrides this derivation.
    public var homePose:       Pose?

    public init(
        id:             String,
        name:           String,
        widthCm:        Double,
        heightCm:       Double,
        items:          [FieldItem]       = [],
        zones:          [FieldZone]       = [],
        obstacles:      [FieldObstacle]   = [],
        lines:          [FieldLine]       = [],
        coloredRegions: [ColoredRegion]   = [],
        mechanisms:     [FieldMechanism]  = [],
        homePose:       Pose?             = nil
    ) {
        self.id             = id
        self.name           = name
        self.widthCm        = widthCm
        self.heightCm       = heightCm
        self.items          = items
        self.zones          = zones
        self.obstacles      = obstacles
        self.lines          = lines
        self.coloredRegions = coloredRegions
        self.mechanisms     = mechanisms
        self.homePose       = homePose
    }

    /// Resolved home pose: explicit `homePose` if set, otherwise derived from
    /// well-known home/base zones, or the south-centre fallback.
    ///
    /// This is the value `returnHome()` and `runMatch` use; callers should
    /// prefer `resolvedHomePose` over reading `homePose` directly.
    public var resolvedHomePose: Pose {
        if let explicit = homePose { return explicit }
        // 1. base_camp (Mars Outpost)
        if let zone = zones.first(where: { $0.id == "base_camp" }) {
            return Pose(position: zone.rect.centre, headingDegrees: 0)
        }
        // 2. home_base (Cargo Command)
        if let zone = zones.first(where: { $0.id == "home_base" }) {
            return Pose(position: zone.rect.centre, headingDegrees: 0)
        }
        // 3. Fallback: south-centre of the field, heading north
        return Pose(position: Vec2(x: widthCm / 2, y: 10), headingDegrees: 0)
    }

    // MARK: - Bounds

    public var bounds: FieldRect { FieldRect(x: 0, y: 0, width: widthCm, height: heightCm) }

    public func isInBounds(_ point: Vec2) -> Bool { bounds.contains(point) }

    // MARK: - Home area (base)

    /// The rectangular base/home area a run starts in. Like a real field, the
    /// rover may be placed *anywhere inside this box, at any heading*, before a
    /// launch. Derived from the well-known home zone; nil if the field has none.
    public var homeArea: FieldRect? {
        zones.first(where: { $0.id == "base_camp" })?.rect
        ?? zones.first(where: { $0.id == "home_base" })?.rect
    }

    /// Is `position` inside the base area? (Fields without a base accept anywhere.)
    public func isInHomeArea(_ position: Vec2) -> Bool {
        guard let area = homeArea else { return true }
        return area.contains(position)
    }

    /// Clamp a chosen start position back inside the base area so a run can never
    /// begin out of bounds. Heading is unchanged. No-op if the field has no base.
    public func clampToHomeArea(_ pose: Pose) -> Pose {
        guard let area = homeArea else { return pose }
        let cx = min(max(pose.position.x, area.x), area.x + area.width)
        let cy = min(max(pose.position.y, area.y), area.y + area.height)
        return Pose(position: Vec2(x: cx, y: cy), headingDegrees: pose.headingDegrees)
    }

    // MARK: - Lookup helpers

    public func item(id: String)      -> FieldItem?      { items.first      { $0.id == id } }
    public func zone(id: String)      -> FieldZone?      { zones.first      { $0.id == id } }
    public func obstacle(id: String)  -> FieldObstacle?  { obstacles.first  { $0.id == id } }
    public func mechanism(id: String) -> FieldMechanism? { mechanisms.first { $0.id == id } }
}
