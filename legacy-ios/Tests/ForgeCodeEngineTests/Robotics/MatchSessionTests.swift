import Testing
@testable import ForgeCodeEngine

/// The multi-launch match loop (`MatchSession`): shared token pool + move budget
/// across launches, the "failed to return home" token penalty, mission-score
/// accumulation, and budget exhaustion.
@Suite("MatchSession — multi-launch loop")
struct MatchSessionTests {

    private func loaded() throws -> (FieldWorld, Match, [Mission]) {
        let world = try #require(try RoboticsLibrary.field(id: "field_arena"))
        let match = try #require(try RoboticsLibrary.match(id: "match_mars_outpost"))
        let all   = try RoboticsLibrary.missions()
        let byId  = Dictionary(all.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let ms    = match.missionIds.compactMap { byId[$0] }
        return (world, match, ms)
    }

    @Test("fresh session starts with full tokens, full budget, rover in base")
    func freshSession() throws {
        let (w, m, ms) = try loaded()
        let s = MatchSession(world: w, match: m, missions: ms)
        #expect(s.tokensRemaining == m.startingTokens)
        #expect(s.movesRemaining == m.moveBudget)
        #expect(s.roverInBase)
        #expect(s.launchCount == 0)
        #expect(s.canLaunch)
    }

    @Test("a launch that ends outside base costs one token (failed to return home)")
    func awayFinishCostsToken() throws {
        let (w, m, ms) = try loaded()
        var s = MatchSession(world: w, match: m, missions: ms)
        // Drive straight north out of base and stop there.
        let launch = s.launch(program: "drive.forward(60);",
                              startPose: w.resolvedHomePose)
        #expect(launch.endedInBase == false)
        #expect(launch.homePenaltyApplied == true)
        #expect(s.tokensRemaining == m.startingTokens - 1)
        #expect(s.roverInBase == false)
        #expect(s.movesRemaining < m.moveBudget)   // budget was consumed
    }

    @Test("a launch that ends inside base keeps all tokens")
    func homeFinishKeepsTokens() throws {
        let (w, m, ms) = try loaded()
        var s = MatchSession(world: w, match: m, missions: ms)
        // A tiny nudge that stays inside base (base_camp is y 8…50).
        let launch = s.launch(program: "drive.forward(3);",
                              startPose: w.resolvedHomePose)
        #expect(launch.endedInBase == true)
        #expect(launch.homePenaltyApplied == false)
        #expect(s.tokensRemaining == m.startingTokens)
        #expect(s.roverInBase == true)
    }

    @Test("move budget is shared and drains across launches")
    func budgetSharedAcrossLaunches() throws {
        let (w, m, ms) = try loaded()
        var s = MatchSession(world: w, match: m, missions: ms)
        s.launch(program: "drive.forward(3);", startPose: w.resolvedHomePose)
        let afterFirst = s.movesRemaining
        s.launch(program: "drive.forward(3);", startPose: w.resolvedHomePose)
        #expect(s.movesRemaining < afterFirst, "second launch drains the shared budget further")
        #expect(s.launchCount == 2)
    }

    @Test("aggregate never loses a mission scored in an earlier launch")
    func missionScoreAccumulates() throws {
        let (w, m, ms) = try loaded()
        var s = MatchSession(world: w, match: m, missions: ms)
        // Launch 1: a program that scores nothing.
        s.launch(program: "drive.forward(3);", startPose: w.resolvedHomePose)
        let base = s.aggregate.missionPoints
        // Launch 2: also scores nothing — aggregate mission points must not drop.
        s.launch(program: "drive.forward(3);", startPose: w.resolvedHomePose)
        #expect(s.aggregate.missionPoints >= base)
        // Aggregate lists every mission in the match.
        #expect(s.aggregate.perMission.count == m.missionIds.count)
        // Total = mission points + token bonus.
        #expect(s.aggregate.totalScore
                == s.aggregate.missionPoints + s.aggregate.tokensRemaining * m.pointsPerToken)
    }

    @Test("tokens never go negative even after repeated away finishes")
    func tokensFloorAtZero() throws {
        let (w, m, ms) = try loaded()
        var s = MatchSession(world: w, match: m, missions: ms)
        for _ in 0..<(m.startingTokens + 3) {
            s.launch(program: "drive.forward(60);", startPose: w.resolvedHomePose)
        }
        #expect(s.tokensRemaining == 0)
        #expect(s.aggregate.tokenPoints == 0)
    }
}
