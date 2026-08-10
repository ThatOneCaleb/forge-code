import SwiftUI
import ForgeCodeEngine

/// Drives a single Challenge that runs on the **robotics engine** (via
/// `RoboticsChallengeBridge`) with the FLL block editor and 3D field playback.
/// Owns all engine interaction and records completion through `ProgressService`,
/// so the Challenges ladder keeps its stars / unlock / streak behaviour.
@Observable
@MainActor
final class ChallengeRoboticsViewModel {

    // MARK: Content
    let lesson: Lesson
    let world:  FieldWorld
    let mission: Mission

    // MARK: Collaborators
    private let kid: Kid
    private let progressService: ProgressService
    private let onComplete: () -> Void

    // MARK: Editor
    let blockEditor = RoboticsBlockEditor()

    // MARK: Run state
    var runState: MatchRunState = .idle
    var run: RoboticsRun?
    var errorMessage: String?
    var showHint = false
    var didWin = false

    /// The pose drawn on the 2D board; animated through the run's snapshots.
    var displayedPose: Pose

    /// Gems the rover has driven over so far (drives the pop animation + chime).
    var collectedGemIds: Set<String> = []
    /// 1…3 rating shown in the win celebration.
    var starRating: Int = 3
    /// Whether this is a superHard challenge (bigger celebration).
    var isSuperHard: Bool { lesson.challenge.difficulty == .superHard }
    var gemsCollected: Int { collectedGemIds.count }

    private let sim = RoboticsSimulator()

    init(lesson: Lesson, kid: Kid, progressService: ProgressService,
         onComplete: @escaping () -> Void) {
        self.lesson = lesson
        self.kid = kid
        self.progressService = progressService
        self.onComplete = onComplete
        let bridged = RoboticsChallengeBridge.make(
            from: lesson.challenge,
            order: lesson.order,
            id: "challenge_\(lesson.order)",
            title: lesson.title,
            brief: lesson.goalDescription)
        self.world = bridged.world
        self.mission = bridged.mission
        self.displayedPose = bridged.world.resolvedHomePose
    }

    // MARK: Derived
    var goalDescription: String { lesson.goalDescription }
    var hintText: String {
        lesson.hintText ?? "Drive one cell with drive.forward(30). A 90° turn faces the next direction."
    }
    var alreadyCompleted: Bool { kid.completedLessonIDs.contains(lesson.id) }

    // MARK: Run
    func run(reduceMotion: Bool = false) async {
        guard runState != .running else { return }
        errorMessage = nil
        showHint = false
        blockEditor.normalizeInsertionPath()

        let program = blockEditor.generatedCode
        let robot = RobotModel(pose: world.resolvedHomePose)
        let result = sim.run(program: program, world: world, robot: robot, mission: mission)
        self.run = result
        runState = .running
        displayedPose = world.resolvedHomePose
        collectedGemIds = []

        // Friendly failure messaging (mirrors RoboticsMissionViewModel).
        if let failure = result.failureKind {
            switch failure {
            case .runtimeError(let msg):     errorMessage = msg
            case .stepBudgetExceeded:        errorMessage = "Your program ran too long — is a loop stuck?"
            case .actionBudgetExceeded:      errorMessage = "That used too many moves — try a shorter path."
            case .collision:                 errorMessage = "The rover bumped a wall and stopped. Steer around it!"
            case .outOfBounds:               errorMessage = "The rover drove off the field. Check your distances."
            }
        }

        await playback(result.snapshots,
                       teleportFrames: Self.teleportFrames(result.sensorLog),
                       reduceMotion: reduceMotion)

        let won = result.missionResult?.success == true
        didWin = won
        if won {
            starRating = Self.rating(blocks: blockEditor.blocks, gems: world.items.count)
            try? progressService.completeLesson(lesson, for: kid)
        } else {
            if errorMessage == nil {
                errorMessage = "So close — the rover didn't reach the goal zone."
            }
            SFX.play(SFX.fail)
        }
        runState = .done
    }

    /// A generous 1–3 efficiency rating: fewer blocks = more stars.
    private static func rating(blocks: [RBlock], gems: Int) -> Int {
        let used = count(blocks)
        let par = gems * 3 + 8
        if used <= par { return 3 }
        if used <= par * 3 / 2 { return 2 }
        return 1
    }
    private static func count(_ blocks: [RBlock]) -> Int {
        blocks.reduce(0) { acc, b in
            switch b {
            case let .repeatN(_, body), let .whileC(_, body), let .ifC(_, body):
                return acc + 1 + count(body)
            default: return acc + 1
            }
        }
    }

    func reset() {
        runState = .idle
        run = nil
        errorMessage = nil
        showHint = false
        didWin = false
        displayedPose = world.resolvedHomePose
        collectedGemIds = []
    }

    func finish() { onComplete() }

    // MARK: Playback — animate the 2D pose through the run's snapshots.
    private func playback(_ snapshots: [RobotSnapshot],
                          teleportFrames: Set<Int>,
                          reduceMotion: Bool) async {
        guard snapshots.count > 1 else { return }
        var prev = snapshots[0].pose
        displayedPose = prev
        collectGems(on: prev, to: prev)   // gems under the start tile
        for i in 1..<snapshots.count {
            let next = snapshots[i].pose
            let teleport = teleportFrames.contains(i)
            if reduceMotion || teleport {
                displayedPose = next
            } else {
                let dur = Self.duration(from: prev, to: next)
                withAnimation(.easeInOut(duration: dur)) { displayedPose = next }
                try? await Task.sleep(for: .seconds(dur))
            }
            collectGems(on: prev, to: next)
            prev = next
        }
    }

    /// Pop any gems whose position lies on the segment the rover just drove.
    private func collectGems(on a: Pose, to b: Pose) {
        for item in world.items where !collectedGemIds.contains(item.id) {
            if Self.distanceToSegment(item.position, a: a.position, b: b.position) <= 16 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    _ = collectedGemIds.insert(item.id)
                }
                SFX.play(SFX.collect)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }

    private static func distanceToSegment(_ p: Vec2, a: Vec2, b: Vec2) -> Double {
        let abx = b.x - a.x, aby = b.y - a.y
        let apx = p.x - a.x, apy = p.y - a.y
        let len2 = abx * abx + aby * aby
        if len2 == 0 { return a.distance(to: p) }
        let t = min(max((apx * abx + apy * aby) / len2, 0), 1)
        return Vec2(x: a.x + t * abx, y: a.y + t * aby).distance(to: p)
    }

    /// Time for one snapshot step: proportional to distance driven / angle turned.
    private static func duration(from a: Pose, to b: Pose) -> Double {
        let dist = a.position.distance(to: b.position)              // cm
        var dAng = abs(a.headingDegrees - b.headingDegrees)
        if dAng > 180 { dAng = 360 - dAng }
        let t = dist * 0.010 + dAng * 0.0035
        return min(max(t, 0.12), 1.1)
    }

    private static func teleportFrames(_ log: [SensorEvent]) -> Set<Int> {
        Set(log.compactMap { if case .returnHome = $0.kind { return $0.frameIndex } else { return nil } })
    }
}
