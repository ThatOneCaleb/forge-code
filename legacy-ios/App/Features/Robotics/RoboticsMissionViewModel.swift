import SwiftUI
import ForgeCodeEngine

// MARK: - RoboticsMissionViewModel

/// View-model for `RoboticsMissionView` — a single-mission challenge (as opposed
/// to a full match). Owns all engine interaction; the view never touches the
/// simulator directly.
///
/// The key extra beat over a match is the **attachment picker**: the kid bolts a
/// tool onto the rover *before* running, and the simulator gates certain
/// mechanisms on the right tool. Choosing it is part of the puzzle.
@Observable
@MainActor
final class RoboticsMissionViewModel {

    // MARK: - Content
    let mission: Mission
    let world:   FieldWorld

    // MARK: - Editor
    var programText: String
    var errorMessage: String?

    /// Block vs text editing. Blocks serialise into `programText` before a run.
    var editorMode: RoboticsEditorMode = .blocks
    let blockEditor = RoboticsBlockEditor()

    /// Render the current block tree into `programText`.
    func syncTextFromBlocks() {
        programText = blockEditor.generatedCode
    }

    // MARK: - Attachment
    /// The tool the kid has bolted on for this run.
    var selectedAttachment: RobotAttachment = .none

    // MARK: - Start placement (anywhere inside base, any heading)
    var startX: Double
    var startY: Double
    var startHeading: Double   // degrees, 0 = north

    /// The base rectangle the rover may be placed inside (nil = anywhere).
    var homeArea: FieldRect? { world.homeArea }

    /// Chosen start pose, always clamped inside the base area.
    var startPose: Pose {
        world.clampToHomeArea(
            Pose(position: Vec2(x: startX, y: startY), headingDegrees: startHeading))
    }

    // MARK: - Run state
    var runState: MatchRunState = .idle
    var run: RoboticsRun?

    // MARK: - Scene
    var scene: RoboticsFieldScene?

    // MARK: - Init
    init(mission: Mission, world: FieldWorld) {
        self.mission = mission
        self.world   = world
        self.programText = Self.starter(for: mission)
        let hp = world.resolvedHomePose
        self.startX = hp.position.x
        self.startY = hp.position.y
        self.startHeading = hp.headingDegrees
    }

    private static func starter(for mission: Mission) -> String {
        """
        // \(mission.title)
        // The rover starts at base, facing north.
        // Pick a tool above if the mission needs one, then write your program.
        // drive.forward(cm), drive.turnLeft(deg), drive.turnRight(deg),
        // arm.lower(), arm.raise(), gripper.close(), gripper.open()
        drive.forward(30);
        """
    }

    // MARK: - Derived
    var missionResult: MissionResult? { run?.missionResult }
    var totalPossible: Int { mission.totalPossiblePoints }

    /// Objective rows for the scoreboard, paired with whether they were met.
    func objectiveRows() -> [(objective: MissionObjective, met: Bool)] {
        let met = missionResult?.metObjectiveIds ?? []
        return mission.objectives.map { ($0, met.contains($0.id)) }
    }

    // MARK: - Run
    func run(reduceMotion: Bool = false) async {
        guard runState != .running else { return }
        errorMessage = nil
        // In block mode the source of truth is the block tree.
        if editorMode == .blocks { syncTextFromBlocks() }
        runState = .running

        let robot = RobotModel(
            pose: startPose,
            armAngle: 0,
            isGripperOpen: true,
            attachment: selectedAttachment
        )

        let sim = RoboticsSimulator()
        let result = sim.run(program: programText, world: world,
                             robot: robot, mission: mission)
        self.run = result

        if let failure = result.failureKind {
            switch failure {
            case .runtimeError(let msg):
                if result.snapshots.count <= 1 {
                    errorMessage = msg
                    runState = .error(msg)
                    return
                }
                errorMessage = msg
            case .stepBudgetExceeded(let limit):
                errorMessage = "Your program ran too many steps (\(limit)). Is a loop stuck?"
            case .actionBudgetExceeded(let limit):
                errorMessage = "You used all \(limit) moves — the run ended early."
            case .collision(let obsId):
                errorMessage = "Your rover bumped into \"\(obsId)\" and stopped. Try a different route!"
            case .outOfBounds:
                errorMessage = "Your rover drove off the field! Check your distances."
            }
        }

        await playback(result.snapshots,
                       teleportFrames: Self.teleportFrames(result.sensorLog),
                       reduceMotion: reduceMotion)
        runState = .done
    }

    /// Frame indices produced by a genuine `returnHome()` — the only real teleports.
    private static func teleportFrames(_ log: [SensorEvent]) -> Set<Int> {
        Set(log.compactMap { if case .returnHome = $0.kind { return $0.frameIndex } else { return nil } })
    }

    // MARK: - Reset
    func reset() {
        runState = .idle
        run = nil
        errorMessage = nil
        scene?.reset()
    }

    // MARK: - Playback
    private func playback(_ snapshots: [RobotSnapshot],
                          teleportFrames: Set<Int>,
                          reduceMotion: Bool) async {
        guard let scene else {
            return
        }
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            scene.play(snapshots: snapshots, teleportFrames: teleportFrames) { _ in
                // no live HUD counters for single missions
            } completion: {
                cont.resume()
            }
        }
    }

    // MARK: - Scoreboard helpers
    var didSucceed: Bool { missionResult?.success == true }
    var score: Int { missionResult?.score ?? 0 }

    var failureNote: String? {
        guard let kind = run?.failureKind else { return nil }
        switch kind {
        case .actionBudgetExceeded: return "Move budget used up."
        case .collision:            return "Rover got stuck on an obstacle."
        case .outOfBounds:          return "Rover drove off the field."
        case .stepBudgetExceeded:   return "Program ran too many steps."
        case .runtimeError(let m):  return m
        }
    }
}
