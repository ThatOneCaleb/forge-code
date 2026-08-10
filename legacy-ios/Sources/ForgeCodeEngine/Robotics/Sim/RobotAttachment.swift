/// A tool the kid bolts onto the rover *before a run* to change what it can do.
///
/// Attachments are the "choose the right tool for the job" decision — a core
/// problem-solving beat. They are deterministic and purely descriptive: the
/// simulator reads the mounted attachment when deciding whether a mechanism
/// activates and how far the rover can reach. No Foundation dependency.
///
/// Design rules kept deliberately small and legible for kids:
///   • `.none`          — the bare gripper. Handles ordinary pickups & bumps.
///   • `.reachExtender` — a longer arm. Adds `reachBonus` cm to trigger/pickup
///                        reach, for targets that are awkward to line up on.
///   • `.fineHook`      — a slim hook. The ONLY tool that can pull a buried
///                        sample out of the ground (an `.excavator` mechanism).
///   • `.launchTool`    — a pusher tip. The ONLY tool that can trip a rocket
///                        launch lever (a `.launcher` mechanism).
///
/// A mission can *require* a specific attachment (`FieldMechanism.requiredAttachment`).
/// Bringing the wrong tool means the mechanism simply will not fire — the kid has
/// to reason about which attachment the mission needs, then still drive precisely.
public enum RobotAttachment: String, Equatable, Hashable, Sendable, CaseIterable {
    case none
    case reachExtender
    case fineHook
    case launchTool

    /// Extra reach (cm) this attachment adds to mechanism trigger radii and
    /// item pickup radii. Only `.reachExtender` extends reach; the specialist
    /// tools trade reach for the ability to work a specific mechanism.
    public var reachBonus: Double {
        switch self {
        case .reachExtender: return 12
        case .none, .fineHook, .launchTool: return 0
        }
    }

    /// Short kid-facing name for pickers/HUD.
    public var displayName: String {
        switch self {
        case .none:          return "Standard Gripper"
        case .reachExtender: return "Reach Extender"
        case .fineHook:      return "Fine Hook"
        case .launchTool:    return "Launch Tool"
        }
    }

    /// One-line hint about when to pick it (never names the mission's answer).
    public var blurb: String {
        switch self {
        case .none:          return "Balanced. Grabs cargo and bumps switches."
        case .reachExtender: return "Reaches farther — for targets that are hard to line up."
        case .fineHook:      return "A slim hook for prying things loose from the ground."
        case .launchTool:    return "A firm pusher tip for tripping stiff launch levers."
        }
    }
}
