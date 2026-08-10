/// Turns a Challenge slot into a robotics `FieldWorld` + `Mission` for the
/// tile board. The original grid puzzles are a gentle beginner curriculum, so
/// instead of bridging them faithfully (which stays easy) this **generates a
/// difficulty-scaled puzzle from the challenge order**: a bigger board, more
/// scattered walls, and more crystals to collect as the number climbs. Layouts
/// are deterministic (seeded by order) and guaranteed solvable (every crystal
/// and the goal are reachable from the start).
public enum RoboticsChallengeBridge {

    /// Centimetres per grid tile. `drive.forward(30)` = one tile.
    public static let cellCm: Double = 30

    // MARK: - Entry point

    public static func make(from challenge: Challenge,
                            order: Int,
                            id: String,
                            title: String,
                            brief: String) -> (world: FieldWorld, mission: Mission) {
        let layout = generate(order: order)
        return (world(layout, id: id, name: title),
                mission(layout, id: id, title: title, brief: brief,
                        difficulty: challenge.difficulty))
    }

    // MARK: - Layout

    struct Layout {
        let size: Int
        let start: Position
        let goal: Position
        let walls: Set<Position>
        let gems: [Position]
    }

    static func generate(order: Int) -> Layout {
        var rng = SplitMix64(seed: UInt64(order &* 2654435761 &+ 101))
        // Board grows with progress; even #1 is a real 10×10 puzzle.
        let size = min(10 + order / 4, 26)
        let density = min(0.13 + Double(order) * 0.0018, 0.32)
        let gemCount = min(1 + order / 9, 9)

        let start = Position(x: 0, y: 0)
        let goal  = Position(x: size - 1, y: size - 1)

        // Scatter walls.
        var walls: Set<Position> = []
        for y in 0..<size {
            for x in 0..<size {
                let p = Position(x: x, y: y)
                if p == start || p == goal { continue }
                if Double(rng.nextUnit()) < density { walls.insert(p) }
            }
        }

        // Scatter crystals on open cells.
        var gems: [Position] = []
        var attempts = 0
        while gems.count < gemCount && attempts < gemCount * 40 {
            attempts += 1
            let p = Position(x: Int(rng.next(upTo: UInt64(size))),
                             y: Int(rng.next(upTo: UInt64(size))))
            if p == start || p == goal || walls.contains(p) || gems.contains(p) { continue }
            gems.append(p)
        }

        // Guarantee solvability: carve an L-corridor from start to any target
        // that isn't reachable yet, then re-check.
        var targets = gems + [goal]
        var guard0 = 0
        while guard0 < 64 {
            guard0 += 1
            let reachable = floodFill(from: start, size: size, walls: walls)
            let unreached = targets.filter { !reachable.contains($0) }
            if unreached.isEmpty { break }
            for t in unreached { carveL(from: start, to: t, walls: &walls) }
        }
        _ = targets  // (kept for readability)
        return Layout(size: size, start: start, goal: goal, walls: walls, gems: gems)
    }

    // MARK: - World / Mission

    static func world(_ l: Layout, id: String, name: String) -> FieldWorld {
        let dim = Double(l.size) * cellCm
        let obstacles = l.walls.map {
            FieldObstacle(id: "wall_\($0.x)_\($0.y)", rect: cellRect($0))
        }
        let items = l.gems.enumerated().map { idx, pos in
            FieldItem(id: "gem_\(idx)", position: cellCentre(pos),
                      type: "crystal", pickupRadius: 15)
        }
        let goalZone = FieldZone(id: "goal_zone", kind: .goal, rect: cellRect(l.goal))
        let home = Pose(position: cellCentre(l.start), headingDegrees: 0)  // facing north
        return FieldWorld(id: id, name: name, widthCm: dim, heightCm: dim,
                          items: items, zones: [goalZone], obstacles: obstacles,
                          homePose: home)
    }

    static func mission(_ l: Layout, id: String, title: String, brief: String,
                        difficulty: ChallengeDifficulty?) -> Mission {
        let collectNeeded = l.gems.count
        var objectives: [MissionObjective] = [
            MissionObjective(id: "reach_goal", kind: .reachZone,
                             points: collectNeeded > 0 ? 0 : 10,
                             description: "Steer the rover into the goal zone",
                             targetZoneId: "goal_zone", isRequired: true)
        ]
        for (idx, pos) in l.gems.enumerated() {
            let c = cellCentre(pos)
            objectives.append(MissionObjective(
                id: "gem_\(idx)", kind: .visitTile, points: 1,
                description: "Drive over the crystal",
                targetX: c.x, targetY: c.y, toleranceCm: 16))
        }
        let rule: MissionSuccessRule = collectNeeded > 0
            ? .allRequiredAndScore(collectNeeded) : .allRequired
        return Mission(id: id, fieldId: id, title: title, brief: brief,
                       objectives: objectives, successRule: rule,
                       difficulty: difficultyValue(difficulty))
    }

    // MARK: - Grid helpers

    static func cellCentre(_ p: Position) -> Vec2 {
        Vec2(x: Double(p.x) * cellCm + cellCm / 2, y: Double(p.y) * cellCm + cellCm / 2)
    }
    static func cellRect(_ p: Position) -> FieldRect {
        FieldRect(x: Double(p.x) * cellCm, y: Double(p.y) * cellCm, width: cellCm, height: cellCm)
    }
    static func difficultyValue(_ d: ChallengeDifficulty?) -> Int {
        switch d { case .easy: return 1; case .hard: return 3; case .superHard: return 5; case .none: return 2 }
    }

    // MARK: - Connectivity

    /// 4-connected flood fill of open cells from `start`.
    static func floodFill(from start: Position, size: Int, walls: Set<Position>) -> Set<Position> {
        var seen: Set<Position> = [start]
        var stack = [start]
        while let p = stack.popLast() {
            for n in [Position(x: p.x+1, y: p.y), Position(x: p.x-1, y: p.y),
                      Position(x: p.x, y: p.y+1), Position(x: p.x, y: p.y-1)] {
                guard n.x >= 0, n.y >= 0, n.x < size, n.y < size,
                      !walls.contains(n), !seen.contains(n) else { continue }
                seen.insert(n); stack.append(n)
            }
        }
        return seen
    }

    /// Remove walls along an L-shaped path from `a` to `b`.
    static func carveL(from a: Position, to b: Position, walls: inout Set<Position>) {
        var x = a.x, y = a.y
        while x != b.x { x += x < b.x ? 1 : -1; walls.remove(Position(x: x, y: y)) }
        while y != b.y { y += y < b.y ? 1 : -1; walls.remove(Position(x: x, y: y)) }
    }
}

// MARK: - Deterministic RNG

struct SplitMix64 {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
    /// A value in [0, upTo).
    mutating func next(upTo n: UInt64) -> UInt64 { n == 0 ? 0 : next() % n }
    /// A value in [0, 1).
    mutating func nextUnit() -> Double { Double(next() >> 11) * (1.0 / 9007199254740992.0) }
}
