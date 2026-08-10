import SwiftUI
import ForgeCodeEngine

// MARK: - Run state

enum MatchRunState: Equatable {
    case idle       // ready for the next launch / run
    case running    // a launch/run is executing / animating
    case launched   // a match launch just finished (between-launch state)
    case done       // a single-mission run finished (mission screen)
    case error(String)
}

// MARK: - RoboticsMatchViewModel

/// View-model for `RoboticsMatchView` — a **multi-launch** match attempt
/// (FLL-style). The kid runs a program, the rover drives out, then must come
/// back to base to launch again; a shared pool of precision tokens and a shared
/// move budget carry across launches, and a launch that ends stuck / outside
/// base costs a token. All engine work goes through a pure `MatchSession`.
@Observable
@MainActor
final class RoboticsMatchViewModel {

    // MARK: - Content
    let match:    Match
    let world:    FieldWorld
    let missions: [Mission]

    // MARK: - Session (the multi-launch loop)
    private(set) var session: MatchSession

    // MARK: - Editor / setup
    var programText: String
    var errorMessage: String?
    var selectedAttachment: RobotAttachment = .none

    // Start placement for the *next* launch (anywhere in base, any heading).
    var startX: Double
    var startY: Double
    var startHeading: Double
    var homeArea: FieldRect? { world.homeArea }
    var startPose: Pose {
        world.clampToHomeArea(
            Pose(position: Vec2(x: startX, y: startY), headingDegrees: startHeading))
    }

    // MARK: - Run state
    var runState: MatchRunState = .idle
    var lastLaunch: MatchLaunch?
    var showScoreboard = false

    // MARK: - Scene
    var scene: RoboticsFieldScene?

    // MARK: - Init
    init(match: Match, world: FieldWorld, missions: [Mission]) {
        self.match    = match
        self.world    = world
        self.missions = missions
        self.session  = MatchSession(world: world, match: match, missions: missions)
        self.programText = Self.starterProgram(for: match)
        let hp = world.resolvedHomePose
        self.startX = hp.position.x
        self.startY = hp.position.y
        self.startHeading = hp.headingDegrees
    }

    private static func starterProgram(for match: Match) -> String {
        """
        // Launch \u{2192} drive out, score missions, then drive back into base.
        // If the rover ends outside base it costs 1 precision token!
        // drive.forward(cm), drive.turnLeft(deg), drive.turnRight(deg),
        // arm.lower(), arm.raise(), gripper.close(), gripper.open()
        drive.forward(30);
        """
    }

    // MARK: - Derived HUD
    var tokensRemaining: Int { session.tokensRemaining }
    var movesRemaining:  Int { session.movesRemaining }
    var movesUsed:       Int { match.moveBudget - session.movesRemaining }
    var launchNumber:    Int { session.launchCount + 1 }
    var canLaunch:       Bool { session.canLaunch }
    var aggregate: MatchResult { session.aggregate }

    // MARK: - Launch
    func launch(reduceMotion: Bool = false) async {
        guard runState != .running, session.canLaunch else { return }
        errorMessage = nil
        runState = .running

        let result = session.launch(program: programText,
                                    startPose: startPose,
                                    attachment: selectedAttachment)
        lastLaunch = result

        if let failure = result.run.failureKind {
            switch failure {
            case .runtimeError(let msg):
                errorMessage = msg
                if result.run.snapshots.count <= 1 {
                    runState = .error(msg)
                    return
                }
            case .stepBudgetExceeded(let limit):
                errorMessage = "Your program ran too many steps (\(limit)). Is a loop stuck?"
            case .actionBudgetExceeded:
                errorMessage = "You ran out of moves mid-launch — the match budget is shared across launches."
            case .collision(let obsId):
                errorMessage = "Your rover bumped \"\(obsId)\" and stopped. It's not in base — that cost a token."
            case .outOfBounds:
                errorMessage = "Your rover drove off the field! Check your distances."
            }
        }

        // Play back this launch on a fresh field.
        scene?.reset()
        await playback(result.run.snapshots,
                       teleportFrames: Self.teleportFrames(result.run.sensorLog),
                       reduceMotion: reduceMotion)
        runState = .launched

        // Out of budget → the attempt is over; show the final scoreboard.
        if !session.canLaunch {
            showScoreboard = true
        }
    }

    /// End the attempt now and show the aggregate scoreboard.
    func finishMatch() { showScoreboard = true }

    /// Full reset — start a brand-new attempt.
    func newAttempt() {
        session = MatchSession(world: world, match: match, missions: missions)
        programText  = Self.starterProgram(for: match)
        errorMessage = nil
        lastLaunch   = nil
        showScoreboard = false
        runState = .idle
        let hp = world.resolvedHomePose
        startX = hp.position.x; startY = hp.position.y; startHeading = hp.headingDegrees
        scene?.reset()
    }

    /// Reset just the default start placement.
    func resetStartPose() {
        let hp = world.resolvedHomePose
        startX = hp.position.x; startY = hp.position.y; startHeading = hp.headingDegrees
    }

    /// Frame indices produced by a genuine `returnHome()` — the only real teleports.
    private static func teleportFrames(_ log: [SensorEvent]) -> Set<Int> {
        Set(log.compactMap { if case .returnHome = $0.kind { return $0.frameIndex } else { return nil } })
    }

    // MARK: - Playback
    private func playback(_ snapshots: [RobotSnapshot],
                          teleportFrames: Set<Int>,
                          reduceMotion: Bool) async {
        guard let scene else { return }
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            scene.play(snapshots: snapshots, teleportFrames: teleportFrames) { _ in
            } completion: {
                cont.resume()
            }
        }
    }

    // MARK: - Scoreboard helpers
    var beatPar: Bool {
        guard let par = match.parScore else { return false }
        return aggregate.totalScore >= par
    }

    func missionTitle(for id: String) -> String {
        missions.first { $0.id == id }?.title ?? id
    }

    /// Points newly scored in the most recent launch (for the between-launch note).
    var lastLaunchPoints: Int {
        lastLaunch?.run.result.missionPoints ?? 0
    }
}
