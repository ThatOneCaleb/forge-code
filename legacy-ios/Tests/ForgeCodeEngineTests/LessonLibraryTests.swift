import Testing
@testable import ForgeCodeEngine

@Suite("LessonLibrary content")
struct LessonLibraryTests {

    @Test("code_basics.json decodes and contains lesson 1")
    func decodes() throws {
        let lessons = try LessonLibrary.codeBasics()
        #expect(!lessons.isEmpty)

        let lesson1 = try #require(lessons.first { $0.order == 1 })
        #expect(lesson1.title == "Move & Turn")
        #expect(lesson1.track == .codeBasics)
        #expect(lesson1.challenge.grid.width == 6)
        #expect(lesson1.challenge.grid.height == 6)
        #expect(lesson1.challenge.start.position == Position(x: 0, y: 0))
        #expect(lesson1.challenge.start.facing == .up)
        #expect(lesson1.challenge.goal == Position(x: 2, y: 0))
        #expect(lesson1.challenge.maxBlocks == 4)
        #expect(!lesson1.introText.isEmpty)
        #expect(!lesson1.goalDescription.isEmpty)
        #expect(lesson1.hintText != nil)
    }

    @Test("lesson 1 canonical solution reaches the goal within maxBlocks")
    func canonicalSolution() throws {
        let lessons = try LessonLibrary.codeBasics()
        let lesson1 = try #require(lessons.first { $0.order == 1 })

        // The verified solution from docs/lessons.md.
        let program = try Parser.parse("turnRight(); move(); move();")
        #expect(program.blockCount <= (lesson1.challenge.maxBlocks ?? .max))

        let result = Simulator().run(program: program, challenge: lesson1.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == lesson1.challenge.goal)
    }

    // Helper: fetch a lesson by order or fail the test.
    private func lesson(_ order: Int) throws -> Lesson {
        let lessons = try LessonLibrary.codeBasics()
        return try #require(lessons.first { $0.order == order })
    }

    @Test("lesson 2 (Sequences) canonical solution reaches the goal within maxBlocks")
    func lesson2Solution() throws {
        let lesson = try lesson(2)
        #expect(lesson.title == "Sequences")

        let program = try Parser.parse("move(); move(); turnRight(); move(); move();")
        #expect(program.blockCount <= (lesson.challenge.maxBlocks ?? .max))

        let result = Simulator().run(program: program, challenge: lesson.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == lesson.challenge.goal)
    }

    @Test("lesson 3 (Loops) canonical solution reaches the goal within maxBlocks")
    func lesson3Solution() throws {
        let lesson = try lesson(3)
        #expect(lesson.title == "Loops")

        let program = try Parser.parse("repeat(5){ move(); }")
        #expect(program.blockCount <= (lesson.challenge.maxBlocks ?? .max))

        let result = Simulator().run(program: program, challenge: lesson.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == lesson.challenge.goal)
    }

    @Test("lesson 4 (Conditionals) canonical solution reaches the goal within maxBlocks")
    func lesson4Solution() throws {
        let lesson = try lesson(4)
        #expect(lesson.title == "Conditionals")

        let program = try Parser.parse("repeat(4){ if(wallAhead()){ turnLeft(); } move(); }")
        #expect(program.blockCount <= (lesson.challenge.maxBlocks ?? .max))

        let result = Simulator().run(program: program, challenge: lesson.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == lesson.challenge.goal)
    }

    @Test("lesson 4 naive solution without the if crashes into the wall")
    func lesson4NaiveFails() throws {
        let lesson = try lesson(4)

        // Same forward march, but no conditional turn: crashes at (3, 0).
        let program = try Parser.parse("repeat(4){ move(); }")
        let result = Simulator().run(program: program, challenge: lesson.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 3, y: 0))))
    }

    @Test("lesson 5 (Variables) canonical solution reaches the goal within maxBlocks")
    func lesson5Solution() throws {
        let lesson = try lesson(5)
        #expect(lesson.title == "Variables")

        let program = try Parser.parse("repeat(4){ move(); }")
        #expect(program.blockCount <= (lesson.challenge.maxBlocks ?? .max))

        let result = Simulator().run(program: program, challenge: lesson.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == lesson.challenge.goal)
    }

    @Test("lesson 5 wrong repeat count stops short of the goal")
    func lesson5WrongCountFails() throws {
        let lesson = try lesson(5)

        // The "variable" (repeat count) matters: 3 lands one cell short.
        let program = try Parser.parse("repeat(3){ move(); }")
        let result = Simulator().run(program: program, challenge: lesson.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.didNotReachGoal(finalPosition: Position(x: 3, y: 0))))
    }

    @Test("lesson 6 (Capstone) canonical solution reaches the goal within maxBlocks")
    func lesson6Solution() throws {
        let lesson = try lesson(6)
        #expect(lesson.title == "Capstone")

        let program = try Parser.parse(
            "move(); move(); turnRight(); repeat(3){ move(); } if(wallAhead()){ turnLeft(); } move();"
        )
        #expect(program.blockCount <= (lesson.challenge.maxBlocks ?? .max))

        let result = Simulator().run(program: program, challenge: lesson.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == lesson.challenge.goal)
    }

    @Test("lesson 6 naive solution without the if crashes into the wall")
    func lesson6NaiveFails() throws {
        let lesson = try lesson(6)

        // Drop the conditional turn: the last move slams into the wall at (4, 2).
        let program = try Parser.parse(
            "move(); move(); turnRight(); repeat(3){ move(); } move();"
        )
        let result = Simulator().run(program: program, challenge: lesson.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 4, y: 2))))
    }

    // MARK: - Code Basics lessons 7-10

    @Test("lesson 7 (Longer Path) canonical solution reaches the goal within maxBlocks")
    func lesson7Solution() throws {
        let lesson = try lesson(7)
        #expect(lesson.title == "Longer Path")

        // Verified trace: (0,0)↑ → up×3 → (0,3)↑ → turnRight → right×4 → (4,3) GOAL
        // blockCount = 3 moves + 1 turn + 4 moves = 8 ≤ 9
        let program = try Parser.parse(
            "move(); move(); move(); turnRight(); move(); move(); move(); move();"
        )
        #expect(program.blockCount <= (lesson.challenge.maxBlocks ?? .max))

        let result = Simulator().run(program: program, challenge: lesson.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == lesson.challenge.goal)
    }

    @Test("lesson 7 going straight without turning stops short")
    func lesson7NaiveFails() throws {
        let lesson = try lesson(7)

        // Going straight up from (0,0) lands at (0,4) not (4,3) and hits the top wall.
        let program = try Parser.parse(
            "move(); move(); move(); move(); move(); move();"
        )
        let result = Simulator().run(program: program, challenge: lesson.challenge)
        #expect(!result.isSuccess)
    }

    @Test("lesson 8 (Repeat and Turn) canonical solution reaches the goal within maxBlocks")
    func lesson8Solution() throws {
        let lesson = try lesson(8)
        #expect(lesson.title == "Repeat and Turn")

        // Verified trace: (0,0)→ → right×5 → (5,0)→ → turnLeft → up×5 → (5,5) GOAL
        // blockCount = repeat(5)=2 + turnLeft=1 + repeat(5)=2 = 5 ≤ 5
        let program = try Parser.parse(
            "repeat(5){ move(); } turnLeft(); repeat(5){ move(); }"
        )
        #expect(program.blockCount <= (lesson.challenge.maxBlocks ?? .max))

        let result = Simulator().run(program: program, challenge: lesson.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == lesson.challenge.goal)
    }

    @Test("lesson 8 brute-force manual moves exceed maxBlocks")
    func lesson8BruteForceFails() throws {
        let lesson = try lesson(8)

        // 5 + 1 + 5 = 11 individual blocks > maxBlocks 5
        let program = try Parser.parse(
            "move(); move(); move(); move(); move(); turnLeft(); move(); move(); move(); move(); move();"
        )
        let result = Simulator().run(program: program, challenge: lesson.challenge)
        #expect(!result.isSuccess)
        if case .failure(.ranOutOfBlocks) = result.outcome { } else {
            Issue.record("Expected ranOutOfBlocks, got \(result.outcome)")
        }
    }

    @Test("lesson 9 (Around the Block) canonical solution reaches the goal within maxBlocks")
    func lesson9Solution() throws {
        let lesson = try lesson(9)
        #expect(lesson.title == "Around the Block")

        // Verified trace: (0,0)→ → turnLeft → up×4 → (0,4)↑ → turnRight → right×5 → (5,4) GOAL
        // blockCount = turnLeft=1 + repeat(4)=2 + turnRight=1 + repeat(5)=2 = 6 ≤ 6
        let program = try Parser.parse(
            "turnLeft(); repeat(4){ move(); } turnRight(); repeat(5){ move(); }"
        )
        #expect(program.blockCount <= (lesson.challenge.maxBlocks ?? .max))

        let result = Simulator().run(program: program, challenge: lesson.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == lesson.challenge.goal)
    }

    @Test("lesson 9 going right first crashes into the wall at (3, 0)")
    func lesson9RightFirstCrashes() throws {
        let lesson = try lesson(9)

        // Heading right from (0,0) immediately hits the obstacle at (3, 0).
        let program = try Parser.parse(
            "repeat(5){ move(); }"
        )
        let result = Simulator().run(program: program, challenge: lesson.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 3, y: 0))))
    }

    @Test("lesson 10 (Mini Maze) canonical solution reaches the goal within maxBlocks")
    func lesson10Solution() throws {
        let lesson = try lesson(10)
        #expect(lesson.title == "Mini Maze")

        // Verified trace:
        //   (0,0)↑ → up×3 → (0,3)↑ → turnRight
        //   → right×7 → (7,3)→ → turnLeft
        //   → up×4 → (7,7) GOAL
        // blockCount = repeat(3)=2 + turnRight=1 + repeat(7)=2 + turnLeft=1 + repeat(4)=2 = 8 ≤ 8
        let program = try Parser.parse(
            "repeat(3){ move(); } turnRight(); repeat(7){ move(); } turnLeft(); repeat(4){ move(); }"
        )
        #expect(program.blockCount <= (lesson.challenge.maxBlocks ?? .max))

        let result = Simulator().run(program: program, challenge: lesson.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == lesson.challenge.goal)
    }

    @Test("lesson 10 going straight up hits the horizontal barrier")
    func lesson10StraightUpCrashes() throws {
        let lesson = try lesson(10)

        // Going straight up from (0,0) hits the obstacle at (0,4).
        let program = try Parser.parse(
            "repeat(5){ move(); }"
        )
        let result = Simulator().run(program: program, challenge: lesson.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 0, y: 4))))
    }
}

// MARK: - Challenges track

@Suite("Challenges track content")
struct ChallengesTrackTests {

    private func challenge(_ order: Int) throws -> Lesson {
        let all = try LessonLibrary.challenges()
        return try #require(all.first { $0.order == order })
    }

    @Test("challenges.json decodes and contains 65 puzzles")
    func challengesDecodes() throws {
        let all = try LessonLibrary.challenges()
        #expect(all.count == 85)
        #expect(all.allSatisfy { $0.track == .challenges })
        // Sorted by order
        let orders = all.map(\.order)
        #expect(orders == orders.sorted())
    }

    // MARK: Challenge 1 — Staircase Sprint

    @Test("challenge 1 (Staircase Sprint) canonical solution reaches the goal within maxBlocks")
    func challenge1Solution() throws {
        let c = try challenge(1)
        #expect(c.title == "Staircase Sprint")

        // Verified trace from (0,0)↑ (4 iterations):
        //   iter 1: move→(0,1)↑, turnRight→→, move→(1,1)→, turnLeft→↑
        //   iter 2: move→(1,2)↑, turnRight→→, move→(2,2)→, turnLeft→↑
        //   iter 3: move→(2,3)↑, turnRight→→, move→(3,3)→, turnLeft→↑
        //   iter 4: move→(3,4)↑, turnRight→→, move→(4,4)→, turnLeft→↑  END=(4,4) GOAL
        // blockCount = repeat(4)=1 + move=1 + turnRight=1 + move=1 + turnLeft=1 = 5 ≤ 5
        let program = try Parser.parse(
            "repeat(4){ move(); turnRight(); move(); turnLeft(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))

        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 1 manual staircase exceeds maxBlocks")
    func challenge1ManualFails() throws {
        let c = try challenge(1)

        // Manual 16 blocks > 5
        let program = try Parser.parse(
            "move(); turnRight(); move(); turnLeft(); move(); turnRight(); move(); turnLeft(); move(); turnRight(); move(); turnLeft(); move(); turnRight(); move(); turnLeft();"
        )
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        if case .failure(.ranOutOfBlocks) = result.outcome { } else {
            Issue.record("Expected ranOutOfBlocks, got \(result.outcome)")
        }
    }

    // MARK: Challenge 2 — The Long Way Around

    @Test("challenge 2 (The Long Way Around) canonical solution reaches the goal within maxBlocks")
    func challenge2Solution() throws {
        let c = try challenge(2)
        #expect(c.title == "The Long Way Around")

        // Verified trace from (0,0)↑:
        //   up×7 → (0,7)↑ → turnRight → right×7 → (7,7)→ → turnRight → down×7 → (7,0)↓ GOAL
        // blockCount = repeat(7)=2 + turnRight=1 + repeat(7)=2 + turnRight=1 + repeat(7)=2 = 8 ≤ 8
        let program = try Parser.parse(
            "repeat(7){ move(); } turnRight(); repeat(7){ move(); } turnRight(); repeat(7){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))

        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 2 going right first crashes into a wall")
    func challenge2RightFirstCrashes() throws {
        let c = try challenge(2)

        // Turning right then moving hits the obstacle at (1, 0).
        let program = try Parser.parse(
            "turnRight(); move();"
        )
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 1, y: 0))))
    }

    // MARK: Challenge 3 — Nested Square

    @Test("challenge 3 (Nested Square) canonical solution reaches the goal within maxBlocks")
    func challenge3Solution() throws {
        let c = try challenge(3)
        #expect(c.title == "Nested Square")

        // Verified trace from (0,2)→:
        //   iter 1: move×2→(2,2)→, turnLeft→(2,2)↑
        //   iter 2: move×2→(2,4)↑, turnLeft→(2,4)←
        //   iter 3: move×2→(0,4)←, turnLeft→(0,4)↓   END=(0,4) GOAL
        // blockCount = repeat(3)=1 + repeat(2)=1 + move=1 + turnLeft=1 = 4 ≤ 4
        let program = try Parser.parse(
            "repeat(3){ repeat(2){ move(); } turnLeft(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))

        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 3 flat loop without nesting cannot fit in maxBlocks")
    func challenge3FlatLoopFails() throws {
        let c = try challenge(3)

        // A flat sequence needs more blocks than allowed.
        // move×2+turnLeft + move×2+turnLeft + move×2+turnLeft = 9 blocks > 4
        let program = try Parser.parse(
            "move(); move(); turnLeft(); move(); move(); turnLeft(); move(); move(); turnLeft();"
        )
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        if case .failure(.ranOutOfBlocks) = result.outcome { } else {
            Issue.record("Expected ranOutOfBlocks, got \(result.outcome)")
        }
    }

    // MARK: Challenge 4 — Dodge the Wall

    @Test("challenge 4 (Dodge the Wall) canonical solution reaches the goal within maxBlocks")
    func challenge4Solution() throws {
        let c = try challenge(4)
        #expect(c.title == "Dodge the Wall")

        // Verified trace from (0,0)↑, obstacle at (0,3):
        //   iter 1: (0,1) clear → move→(0,1)↑
        //   iter 2: (0,2) clear → move→(0,2)↑
        //   iter 3: (0,3) OBSTACLE → turnRight→(0,2)→, move→(1,2)→
        //   iter 4: (2,2) clear → move→(2,2)→
        //   iter 5: (3,2) clear → move→(3,2)→  GOAL
        // blockCount = repeat(5)=1 + if=1 + turnRight=1 + move=1 = 4 ≤ 4
        let program = try Parser.parse(
            "repeat(5){ if(wallAhead()){ turnRight(); } move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))

        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 4 going straight up without conditional crashes into the wall")
    func challenge4StraightCrashes() throws {
        let c = try challenge(4)

        // Moving straight up hits the obstacle at (0, 3).
        let program = try Parser.parse(
            "move(); move(); move(); move();"
        )
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 0, y: 3))))
    }

    // MARK: Challenge 5 — The Gauntlet

    @Test("challenge 5 (The Gauntlet) canonical solution reaches the goal within maxBlocks")
    func challenge5Solution() throws {
        let c = try challenge(5)
        #expect(c.title == "The Gauntlet")

        // Verified trace from (0,0)→, obstacles col-3 y=0-2 and row-4 x=0-6:
        //   move→(1,0)→, move→(2,0)→
        //   turnLeft→(2,0)↑
        //   repeat(3){move}: (2,1),(2,2),(2,3)↑
        //   if(wallAhead()): (2,4) is obstacle → turnRight→(2,3)→
        //   repeat(5){move}: (3,3),(4,3),(5,3),(6,3),(7,3)→
        //     [(3,3) is clear — col-3 wall only covers y=0-2]
        //     [(7,3) is clear — row-4 wall only covers x=0-6; col-7 has no obstacles]
        //   turnLeft→(7,3)↑
        //   repeat(4){move}: (7,4),(7,5),(7,6),(7,7)↑ GOAL
        //     [(7,4) is clear — row-4 wall only covers x=0-6]
        // blockCount = 1+1+1+2+2+2+1+2 = 12 ≤ 12
        let program = try Parser.parse("""
            move(); move(); turnLeft();
            repeat(3){ move(); }
            if(wallAhead()){ turnRight(); }
            repeat(5){ move(); }
            turnLeft();
            repeat(4){ move(); }
            """
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))

        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 5 going right first crashes into the column-3 wall")
    func challenge5RightFirstCrashes() throws {
        let c = try challenge(5)

        // Going straight right from (0,0) hits the obstacle at (3, 0).
        let program = try Parser.parse(
            "repeat(4){ move(); }"
        )
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 3, y: 0))))
    }

    // MARK: Challenge 6 — Straight to the Top

    @Test("challenge 6 (Straight to the Top) canonical solution reaches the goal within maxBlocks")
    func challenge6Solution() throws {
        let c = try challenge(6)
        #expect(c.title == "Straight to the Top")
        // Verified trace from (0,0)↑:
        //   move×7: (0,1)↑,(0,2)↑,(0,3)↑,(0,4)↑,(0,5)↑,(0,6)↑,(0,7)↑ = GOAL
        // blockCount = repeat(7)=1 + move=1 = 2 ≤ 4
        let program = try Parser.parse("repeat(7){ move(); }")
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 6 brute-force manual moves exceed maxBlocks")
    func challenge6BruteForceFails() throws {
        let c = try challenge(6)
        // 7 individual moves = 7 blocks > maxBlocks 4
        let program = try Parser.parse(
            "move(); move(); move(); move(); move(); move(); move();"
        )
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        if case .failure(.ranOutOfBlocks) = result.outcome { } else {
            Issue.record("Expected ranOutOfBlocks, got \(result.outcome)")
        }
    }

    // MARK: Challenge 7 — Full Speed Ahead

    @Test("challenge 7 (Full Speed Ahead) canonical solution reaches the goal within maxBlocks")
    func challenge7Solution() throws {
        let c = try challenge(7)
        #expect(c.title == "Full Speed Ahead")
        // Verified trace from (0,0)→:
        //   move×8: (1,0)→,(2,0)→,(3,0)→,(4,0)→,(5,0)→,(6,0)→,(7,0)→,(8,0)→ = GOAL
        // blockCount = repeat(8)=1 + move=1 = 2 ≤ 4
        let program = try Parser.parse("repeat(8){ move(); }")
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 7 wrong repeat count stops short of goal")
    func challenge7WrongCountFails() throws {
        let c = try challenge(7)
        // repeat(7) lands at (7,0), not (8,0)
        let program = try Parser.parse("repeat(7){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.didNotReachGoal(finalPosition: Position(x: 7, y: 0))))
    }

    // MARK: Challenge 8 — L-Turn

    @Test("challenge 8 (L-Turn) canonical solution reaches the goal within maxBlocks")
    func challenge8Solution() throws {
        let c = try challenge(8)
        #expect(c.title == "L-Turn")
        // Verified trace from (0,0)↑:
        //   move×5: (0,1)↑,(0,2)↑,(0,3)↑,(0,4)↑,(0,5)↑
        //   turnRight → (0,5)→
        //   move×5: (1,5)→,(2,5)→,(3,5)→,(4,5)→,(5,5)→ = GOAL
        // blockCount = repeat(5)=2 + turnRight=1 + repeat(5)=2 = 5 ≤ 6
        let program = try Parser.parse(
            "repeat(5){ move(); } turnRight(); repeat(5){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 8 going right without turning misses the goal")
    func challenge8NoTurnFails() throws {
        let c = try challenge(8)
        // Moving right from (0,0) instead of up never reaches (5,5)
        let program = try Parser.parse("repeat(5){ move(); } turnLeft(); repeat(4){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 9 — Corner to Corner

    @Test("challenge 9 (Corner to Corner) canonical solution reaches the goal within maxBlocks")
    func challenge9Solution() throws {
        let c = try challenge(9)
        #expect(c.title == "Corner to Corner")
        // Verified trace from (0,0)→:
        //   move×9: (1,0)→...(9,0)→
        //   turnLeft → (9,0)↑
        //   move×9: (9,1)↑...(9,9)↑ = GOAL
        // blockCount = repeat(9)=2 + turnLeft=1 + repeat(9)=2 = 5 ≤ 6
        let program = try Parser.parse(
            "repeat(9){ move(); } turnLeft(); repeat(9){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 9 turning wrong way misses the goal")
    func challenge9WrongTurnFails() throws {
        let c = try challenge(9)
        // Turning right instead of left after crossing goes off-grid
        let program = try Parser.parse(
            "repeat(9){ move(); } turnRight(); repeat(9){ move(); }"
        )
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 10 — Diagonal March

    @Test("challenge 10 (Diagonal March) canonical solution reaches the goal within maxBlocks")
    func challenge10Solution() throws {
        let c = try challenge(10)
        #expect(c.title == "Diagonal March")
        // Verified trace from (0,0)↑ (4 iterations):
        //   iter1: move→(0,1)↑, turnRight→→, move→(1,1)→, turnLeft→↑
        //   iter2: move→(1,2)↑, turnRight→→, move→(2,2)→, turnLeft→↑
        //   iter3: move→(2,3)↑, turnRight→→, move→(3,3)→, turnLeft→↑
        //   iter4: move→(3,4)↑, turnRight→→, move→(4,4)→, turnLeft→↑ END=(4,4) GOAL
        // blockCount = repeat(4)=1 + move=1 + turnRight=1 + move=1 + turnLeft=1 = 5 ≤ 5
        let program = try Parser.parse(
            "repeat(4){ move(); turnRight(); move(); turnLeft(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 10 flat manual moves exceed maxBlocks")
    func challenge10ManualFails() throws {
        let c = try challenge(10)
        // 4×(move+turnRight+move+turnLeft) = 16 blocks > maxBlocks 5
        let program = try Parser.parse(
            "move(); turnRight(); move(); turnLeft(); move(); turnRight(); move(); turnLeft(); move(); turnRight(); move(); turnLeft(); move(); turnRight(); move(); turnLeft();"
        )
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        if case .failure(.ranOutOfBlocks) = result.outcome { } else {
            Issue.record("Expected ranOutOfBlocks, got \(result.outcome)")
        }
    }

    // MARK: Challenge 11 — Wall Detour

    @Test("challenge 11 (Wall Detour) canonical solution reaches the goal within maxBlocks")
    func challenge11Solution() throws {
        let c = try challenge(11)
        #expect(c.title == "Wall Detour")
        // Verified trace from (0,0)↑, obstacle at (0,4):
        //   move×3: (0,1)↑,(0,2)↑,(0,3)↑  [stop before (0,4) obstacle]
        //   turnRight → (0,3)→
        //   move×6: (1,3)→,(2,3)→,(3,3)→,(4,3)→,(5,3)→,(6,3)→ = GOAL
        // blockCount = repeat(3)=2 + turnRight=1 + repeat(6)=2 = 5 ≤ 6
        let program = try Parser.parse(
            "repeat(3){ move(); } turnRight(); repeat(6){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 11 going straight up crashes into the wall")
    func challenge11StraightCrashes() throws {
        let c = try challenge(11)
        // Moving straight up hits obstacle at (0,4)
        let program = try Parser.parse("repeat(5){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 0, y: 4))))
    }

    // MARK: Challenge 12 — Decoy Walls

    @Test("challenge 12 (Decoy Walls) canonical solution reaches the goal within maxBlocks")
    func challenge12Solution() throws {
        let c = try challenge(12)
        #expect(c.title == "Decoy Walls")
        // Verified trace from (0,0)↑, obstacles at (6,0),(6,1),(6,2):
        //   move×5: (0,1)↑,(0,2)↑,(0,3)↑,(0,4)↑,(0,5)↑
        //   turnRight → (0,5)→
        //   move×5: (1,5)→,(2,5)→,(3,5)→,(4,5)→,(5,5)→ = GOAL
        //   [obstacles at x=6 are never in the path]
        // blockCount = repeat(5)=2 + turnRight=1 + repeat(5)=2 = 5 ≤ 6
        let program = try Parser.parse(
            "repeat(5){ move(); } turnRight(); repeat(5){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 12 going right first and crossing x=6 crashes")
    func challenge12RightFirstCrashes() throws {
        let c = try challenge(12)
        // Turning right and going right 7 steps from (0,0)↑ hits obstacle at (6,0)
        let program = try Parser.parse("turnRight(); repeat(7){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 6, y: 0))))
    }

    // MARK: Challenge 13 — Tall Tower

    @Test("challenge 13 (Tall Tower) canonical solution reaches the goal within maxBlocks")
    func challenge13Solution() throws {
        let c = try challenge(13)
        #expect(c.title == "Tall Tower")
        // Verified trace from (0,0)↑, obstacles at (3,0),(3,1):
        //   move×9: (0,1)↑...(0,9)↑
        //   turnRight → (0,9)→
        //   move×3: (1,9)→,(2,9)→,(3,9)→ = GOAL
        //   [obstacles at (3,0) and (3,1) are not in path]
        // blockCount = repeat(9)=2 + turnRight=1 + repeat(3)=2 = 5 ≤ 6
        let program = try Parser.parse(
            "repeat(9){ move(); } turnRight(); repeat(3){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 13 going right first crashes into the bottom obstacle")
    func challenge13RightFirstCrashes() throws {
        let c = try challenge(13)
        // Turning right and going right 3 hits obstacle at (3,0)
        let program = try Parser.parse("turnRight(); repeat(4){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 3, y: 0))))
    }

    // MARK: Challenge 14 — Wide Open

    @Test("challenge 14 (Wide Open) canonical solution reaches the goal within maxBlocks")
    func challenge14Solution() throws {
        let c = try challenge(14)
        #expect(c.title == "Wide Open")
        // Verified trace from (0,0)→:
        //   move×9: (1,0)→...(9,0)→
        //   turnLeft → (9,0)↑
        //   move×6: (9,1)↑,(9,2)↑,(9,3)↑,(9,4)↑,(9,5)↑,(9,6)↑ = GOAL
        // blockCount = repeat(9)=2 + turnLeft=1 + repeat(6)=2 = 5 ≤ 6
        let program = try Parser.parse(
            "repeat(9){ move(); } turnLeft(); repeat(6){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 14 wrong turn direction misses the goal")
    func challenge14WrongTurnFails() throws {
        let c = try challenge(14)
        // Turning right instead of left after crossing goes downward (off-grid)
        let program = try Parser.parse(
            "repeat(9){ move(); } turnRight(); repeat(6){ move(); }"
        )
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 15 — Obstacle Island

    @Test("challenge 15 (Obstacle Island) canonical solution reaches the goal within maxBlocks")
    func challenge15Solution() throws {
        let c = try challenge(15)
        #expect(c.title == "Obstacle Island")
        // Verified trace from (0,0)↑, obstacles at (3,3),(3,4),(3,5):
        //   move×7: (0,1)↑,(0,2)↑,(0,3)↑,(0,4)↑,(0,5)↑,(0,6)↑,(0,7)↑
        //   turnRight → (0,7)→
        //   move×7: (1,7)→,(2,7)→,(3,7)→,(4,7)→,(5,7)→,(6,7)→,(7,7)→ = GOAL
        //   [obstacles at x=3,y=3-5 are not in path at y=7]
        // blockCount = repeat(7)=2 + turnRight=1 + repeat(7)=2 = 5 ≤ 7
        let program = try Parser.parse(
            "repeat(7){ move(); } turnRight(); repeat(7){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 15 going through the island crashes")
    func challenge15ThroughIslandCrashes() throws {
        let c = try challenge(15)
        // (0,0)↑ → turnRight → right×3 → (3,0)→ → turnLeft → up×4 → hits obstacle at (3,3)
        let program = try Parser.parse(
            "turnRight(); repeat(3){ move(); } turnLeft(); repeat(4){ move(); }"
        )
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 3, y: 3))))
    }

    // MARK: Challenge 16 — Column Bypass

    @Test("challenge 16 (Column Bypass) canonical solution reaches the goal within maxBlocks")
    func challenge16Solution() throws {
        let c = try challenge(16)
        #expect(c.title == "Column Bypass")
        // Verified trace from (0,0)→, obstacles at (5,0),(5,1),(5,2):
        //   move×4: (1,0)→,(2,0)→,(3,0)→,(4,0)→
        //   turnLeft → (4,0)↑
        //   move×5: (4,1)↑,(4,2)↑,(4,3)↑,(4,4)↑,(4,5)↑
        //   turnRight → (4,5)→
        //   move×5: (5,5)→,(6,5)→,(7,5)→,(8,5)→,(9,5)→ = GOAL
        //   [obstacles at x=5,y=0-2 never touched — path at x=5 is at y=5]
        // blockCount = repeat(4)=2 + turnLeft=1 + repeat(5)=2 + turnRight=1 + repeat(5)=2 = 8 ≤ 8
        let program = try Parser.parse(
            "repeat(4){ move(); } turnLeft(); repeat(5){ move(); } turnRight(); repeat(5){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 16 going straight right hits the column wall")
    func challenge16StraightCrashes() throws {
        let c = try challenge(16)
        // Going right 6 from (0,0) hits obstacle at (5,0)
        let program = try Parser.parse("repeat(6){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 5, y: 0))))
    }

    // MARK: Challenge 17 — Triple L

    @Test("challenge 17 (Triple L) canonical solution reaches the goal within maxBlocks")
    func challenge17Solution() throws {
        let c = try challenge(17)
        #expect(c.title == "Triple L")
        // Verified trace from (0,0)↑:
        //   move×5: (0,1)↑...(0,5)↑
        //   turnRight → (0,5)→
        //   move×10: (1,5)→...(10,5)→
        //   turnLeft → (10,5)↑
        //   move×5: (10,6)↑...(10,10)↑ = GOAL
        // blockCount = repeat(5)=2 + turnRight=1 + repeat(10)=2 + turnLeft=1 + repeat(5)=2 = 8 ≤ 8
        let program = try Parser.parse(
            "repeat(5){ move(); } turnRight(); repeat(10){ move(); } turnLeft(); repeat(5){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 17 manual moves exceed maxBlocks")
    func challenge17ManualFails() throws {
        let c = try challenge(17)
        // 5+1+10+1+5 = 22 individual blocks > maxBlocks 8
        let program = try Parser.parse(
            "move(); move(); move(); move(); move(); turnRight(); move(); move(); move(); move(); move();"
        )
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        if case .failure(.ranOutOfBlocks) = result.outcome { } else {
            Issue.record("Expected ranOutOfBlocks, got \(result.outcome)")
        }
    }

    // MARK: Challenge 18 — U-Turn

    @Test("challenge 18 (U-Turn) canonical solution reaches the goal within maxBlocks")
    func challenge18Solution() throws {
        let c = try challenge(18)
        #expect(c.title == "U-Turn")
        // Verified trace from (0,0)↑, obstacles at (0,4),(0,5),(0,6):
        //   move×3: (0,1)↑,(0,2)↑,(0,3)↑  [stop before (0,4) obstacle]
        //   turnRight → (0,3)→
        //   move×5: (1,3)→,(2,3)→,(3,3)→,(4,3)→,(5,3)→
        //   turnRight → (5,3)↓
        //   move×3: (5,2)↓,(5,1)↓,(5,0)↓ = GOAL
        // blockCount = repeat(3)=2 + turnRight=1 + repeat(5)=2 + turnRight=1 + repeat(3)=2 = 8 ≤ 8
        let program = try Parser.parse(
            "repeat(3){ move(); } turnRight(); repeat(5){ move(); } turnRight(); repeat(3){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 18 going straight up crashes into the wall")
    func challenge18StraightCrashes() throws {
        let c = try challenge(18)
        // Moving straight up from (0,0) hits obstacle at (0,4)
        let program = try Parser.parse("repeat(5){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 0, y: 4))))
    }

    // MARK: Challenge 19 — Grand Cross

    @Test("challenge 19 (Grand Cross) canonical solution reaches the goal within maxBlocks")
    func challenge19Solution() throws {
        let c = try challenge(19)
        #expect(c.title == "Grand Cross")
        // Verified trace from (0,0)→, obstacles at (5,5),(5,6):
        //   move×11: (1,0)→...(11,0)→
        //   turnLeft → (11,0)↑
        //   move×11: (11,1)↑...(11,11)↑ = GOAL
        //   [path goes along y=0 then x=11 — no obstacles there]
        // blockCount = repeat(11)=2 + turnLeft=1 + repeat(11)=2 = 5 ≤ 7
        let program = try Parser.parse(
            "repeat(11){ move(); } turnLeft(); repeat(11){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 19 going through the middle hits the decoy wall")
    func challenge19MiddleCrashes() throws {
        let c = try challenge(19)
        // Going right 5 then up 5 hits obstacle at (5,5)
        let program = try Parser.parse(
            "repeat(5){ move(); } turnLeft(); repeat(6){ move(); }"
        )
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 5, y: 5))))
    }

    // MARK: Challenge 20 — Mid-Row Blocker

    @Test("challenge 20 (Mid-Row Blocker) canonical solution reaches the goal within maxBlocks")
    func challenge20Solution() throws {
        let c = try challenge(20)
        #expect(c.title == "Mid-Row Blocker")
        // Verified trace from (0,5)→, obstacles at (5,4),(5,5),(5,6):
        //   turnLeft → (0,5)↑
        //   move×2: (0,6)↑,(0,7)↑
        //   turnRight → (0,7)→
        //   move×10: (1,7)→...(10,7)→
        //   turnRight → (10,7)↓
        //   move×2: (10,6)↓,(10,5)↓ = GOAL
        //   [obstacles at x=5,y=4-6 never touched at y=7]
        // blockCount = 1 + repeat(2)=2 + 1 + repeat(10)=2 + 1 + repeat(2)=2 = 9 ≤ 9
        let program = try Parser.parse(
            "turnLeft(); repeat(2){ move(); } turnRight(); repeat(10){ move(); } turnRight(); repeat(2){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 20 going straight right crashes into the mid-row blocker")
    func challenge20StraightCrashes() throws {
        let c = try challenge(20)
        // Going straight right hits obstacle at (5,5)
        let program = try Parser.parse("repeat(6){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 5, y: 5))))
    }

    // MARK: Challenge 21 — Side Step

    @Test("challenge 21 (Side Step) canonical solution reaches the goal within maxBlocks")
    func challenge21Solution() throws {
        let c = try challenge(21)
        #expect(c.title == "Side Step")
        // Verified trace from (0,0)↑, obstacles at (5,3),(5,4),(5,5):
        //   move×2: (0,1)↑,(0,2)↑
        //   turnRight → (0,2)→
        //   move×10: (1,2)→...(10,2)→
        //   turnLeft → (10,2)↑
        //   move×8: (10,3)↑...(10,10)↑ = GOAL
        //   [obstacles at x=5,y=3-5 — path at y=2 is clear]
        // blockCount = repeat(2)=2 + turnRight=1 + repeat(10)=2 + turnLeft=1 + repeat(8)=2 = 8 ≤ 8
        let program = try Parser.parse(
            "repeat(2){ move(); } turnRight(); repeat(10){ move(); } turnLeft(); repeat(8){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 21 going straight up and then right hits the column")
    func challenge21ColumnCrashes() throws {
        let c = try challenge(21)
        // Going up 3 then right 5 hits obstacle at (5,3)
        let program = try Parser.parse(
            "repeat(3){ move(); } turnRight(); repeat(6){ move(); }"
        )
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 5, y: 3))))
    }

    // MARK: Challenge 22 — Wall Bypass

    @Test("challenge 22 (Wall Bypass) canonical solution reaches the goal within maxBlocks")
    func challenge22Solution() throws {
        let c = try challenge(22)
        #expect(c.title == "Wall Bypass")
        // Verified trace from (0,0)→, obstacles at (6,0),(6,1),(6,2),(6,3):
        //   move×5: (1,0)→...(5,0)→
        //   turnLeft → (5,0)↑
        //   move×6: (5,1)↑...(5,6)↑
        //   turnRight → (5,6)→
        //   move×6: (6,6)→,(7,6)→,(8,6)→,(9,6)→,(10,6)→,(11,6)→ = GOAL
        //   [obstacles at x=6,y=0-3 — path at x=6 is at y=6, clear]
        // blockCount = repeat(5)=2 + turnLeft=1 + repeat(6)=2 + turnRight=1 + repeat(6)=2 = 8 ≤ 8
        let program = try Parser.parse(
            "repeat(5){ move(); } turnLeft(); repeat(6){ move(); } turnRight(); repeat(6){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 22 going straight right hits the bottom wall")
    func challenge22StraightCrashes() throws {
        let c = try challenge(22)
        // Going right 7 from (0,0) hits obstacle at (6,0)
        let program = try Parser.parse("repeat(7){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 6, y: 0))))
    }

    // MARK: Challenge 23 — High Road

    @Test("challenge 23 (High Road) canonical solution reaches the goal within maxBlocks")
    func challenge23Solution() throws {
        let c = try challenge(23)
        #expect(c.title == "High Road")
        // Verified trace from (0,0)↑, obstacles at (3,3),(3,4),(3,5),(3,6):
        //   move×11: (0,1)↑...(0,11)↑
        //   turnRight → (0,11)→
        //   move×6: (1,11)→,(2,11)→,(3,11)→,(4,11)→,(5,11)→,(6,11)→ = GOAL
        //   [obstacles at x=3,y=3-6 — path at y=11 is clear]
        // blockCount = repeat(11)=2 + turnRight=1 + repeat(6)=2 = 5 ≤ 7
        let program = try Parser.parse(
            "repeat(11){ move(); } turnRight(); repeat(6){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 23 going through the column pillar crashes")
    func challenge23PillarCrashes() throws {
        let c = try challenge(23)
        // Going right 3 then up 4 hits obstacle at (3,3)
        let program = try Parser.parse(
            "turnRight(); repeat(3){ move(); } turnLeft(); repeat(4){ move(); }"
        )
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 3, y: 3))))
    }

    // MARK: Challenge 24 — Drop and Run

    @Test("challenge 24 (Drop and Run) canonical solution reaches the goal within maxBlocks")
    func challenge24Solution() throws {
        let c = try challenge(24)
        #expect(c.title == "Drop and Run")
        // Verified trace from (0,11)→, obstacles at (5,7-11):
        //   turnRight → (0,11)↓
        //   move×11: (0,10)↓,(0,9)↓,...,(0,0)↓
        //   turnLeft → (0,0)→
        //   move×11: (1,0)→,...,(11,0)→ = GOAL
        //   [path stays at x=0 going down, then y=0 going right — no obstacles]
        // blockCount = turnRight=1 + repeat(11)=2 + turnLeft=1 + repeat(11)=2 = 6 ≤ 8
        let program = try Parser.parse(
            "turnRight(); repeat(11){ move(); } turnLeft(); repeat(11){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 24 going right along the top hits the tall column")
    func challenge24TopCrashes() throws {
        let c = try challenge(24)
        // Going right from (0,11) hits obstacle at (5,11)
        let program = try Parser.parse("repeat(6){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 5, y: 11))))
    }

    // MARK: Challenge 25 — Gap Finder

    @Test("challenge 25 (Gap Finder) canonical solution reaches the goal within maxBlocks")
    func challenge25Solution() throws {
        let c = try challenge(25)
        #expect(c.title == "Gap Finder")
        // Verified trace from (0,0)↑, obstacles at (3,6),(4,6),(5,6),(6,6),(7,6),(8,6):
        //   move×7: (0,1)↑...(0,7)↑  [left gap — obstacles start at x=3]
        //   turnRight → (0,7)→
        //   move×9: (1,7)→...(9,7)→  [above the wall at y=7]
        //   turnLeft → (9,7)↑
        //   move×4: (9,8)↑,(9,9)↑,(9,10)↑,(9,11)↑
        //   turnRight → (9,11)→
        //   move×2: (10,11)→,(11,11)→ = GOAL
        // blockCount = repeat(7)=2 + 1 + repeat(9)=2 + 1 + repeat(4)=2 + 1 + repeat(2)=2 = 11 ≤ 11
        let program = try Parser.parse(
            "repeat(7){ move(); } turnRight(); repeat(9){ move(); } turnLeft(); repeat(4){ move(); } turnRight(); repeat(2){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 25 going through the wall at y=6 crashes")
    func challenge25WallCrashes() throws {
        let c = try challenge(25)
        // Going right 3 then up 6 and right again hits the wall at (3,6)
        let program = try Parser.parse(
            "turnRight(); repeat(3){ move(); } turnLeft(); repeat(7){ move(); }"
        )
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 3, y: 6))))
    }

    // MARK: Challenge 26 — Launch Pad Approach (easy)

    @Test("challenge 26 (Launch Pad Approach) canonical solution reaches the goal within maxBlocks")
    func challenge26Solution() throws {
        let c = try challenge(26)
        #expect(c.title == "Launch Pad Approach")
        // Verified trace from (0,0)↑:
        //   up×4: (0,1)↑,(0,2)↑,(0,3)↑,(0,4)↑
        //   turnRight → (0,4)→
        //   right×5: (1,4)→,(2,4)→,(3,4)→,(4,4)→,(5,4)→ = GOAL
        //   obstacle at (0,6) never in path
        // blockCount = repeat(4)=2 + turnRight=1 + repeat(5)=2 = 5 ≤ 6
        let program = try Parser.parse(
            "repeat(4){ move(); } turnRight(); repeat(5){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 26 going straight up hits the sensor post obstacle")
    func challenge26StraightCrashes() throws {
        let c = try challenge(26)
        // Going straight up 7 steps hits obstacle at (0,6)
        let program = try Parser.parse("repeat(7){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 0, y: 6))))
    }

    // MARK: Challenge 27 — Sensor Array Run (easy)

    @Test("challenge 27 (Sensor Array Run) canonical solution reaches the goal within maxBlocks")
    func challenge27Solution() throws {
        let c = try challenge(27)
        #expect(c.title == "Sensor Array Run")
        // Verified trace from (0,0)→:
        //   right×7: (1,0)→,...,(7,0)→
        //   turnLeft → (7,0)↑
        //   up×5: (7,1)↑,...,(7,5)↑ = GOAL
        //   obstacle at (8,0) never in path
        // blockCount = repeat(7)=2 + turnLeft=1 + repeat(5)=2 = 5 ≤ 6
        let program = try Parser.parse(
            "repeat(7){ move(); } turnLeft(); repeat(5){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 27 going right 8 steps hits the sensor array obstacle")
    func challenge27SensorCrashes() throws {
        let c = try challenge(27)
        // Going right 9 from (0,0) hits obstacle at (8,0)
        let program = try Parser.parse("repeat(9){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 8, y: 0))))
    }

    // MARK: Challenge 28 — Double Barrier Breach (hard)

    @Test("challenge 28 (Double Barrier Breach) canonical solution reaches the goal within maxBlocks")
    func challenge28Solution() throws {
        let c = try challenge(28)
        #expect(c.title == "Double Barrier Breach")
        // Verified trace from (0,0)↑, col-5 y=0-5, row-7 at x=7,8,10-13 (gap at x=9):
        //   up×6: (0,1)↑,...,(0,6)↑  [col-5 at x=5, not x=0]
        //   turnRight → (0,6)→
        //   right×9: (1,6)→,...,(9,6)→  [(5,6) clear: col-5 only y=0-5; (7,6) clear: row-7 at y=7]
        //   turnLeft → (9,6)↑
        //   up×4: (9,7)↑,(9,8)↑,(9,9)↑,(9,10)↑ = GOAL  [(9,7) clear: row-7 skips x=9]
        // blockCount = repeat(6)=2 + turnRight=1 + repeat(9)=2 + turnLeft=1 + repeat(4)=2 = 8 ≤ 9
        let program = try Parser.parse(
            "repeat(6){ move(); } turnRight(); repeat(9){ move(); } turnLeft(); repeat(4){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 28 going straight up only 5 then right hits the col-5 barrier")
    func challenge28Col5Crashes() throws {
        let c = try challenge(28)
        // Going up 4 then right hits col-5 at (5,4)
        let program = try Parser.parse(
            "repeat(4){ move(); } turnRight(); repeat(6){ move(); }"
        )
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 5, y: 4))))
    }

    // MARK: Challenge 29 — Rooftop Descent (easy)

    @Test("challenge 29 (Rooftop Descent) canonical solution reaches the goal within maxBlocks")
    func challenge29Solution() throws {
        let c = try challenge(29)
        #expect(c.title == "Rooftop Descent")
        // Verified trace from (0,8)↓:
        //   down×5: (0,7)↓,(0,6)↓,(0,5)↓,(0,4)↓,(0,3)↓
        //   turnLeft → (0,3)→
        //   right×6: (1,3)→,...,(6,3)→ = GOAL
        // blockCount = repeat(5)=2 + turnLeft=1 + repeat(6)=2 = 5 ≤ 6
        let program = try Parser.parse(
            "repeat(5){ move(); } turnLeft(); repeat(6){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 29 going down too many steps goes off the grid")
    func challenge29TooManyStepsFails() throws {
        let c = try challenge(29)
        // Going down 9 from (0,8) goes off-grid at (0,-1)
        let program = try Parser.parse("repeat(9){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 30 — Three-Leg Relay (hard)

    @Test("challenge 30 (Three-Leg Relay) canonical solution reaches the goal within maxBlocks")
    func challenge30Solution() throws {
        let c = try challenge(30)
        #expect(c.title == "Three-Leg Relay")
        // Verified trace from (0,0)→, row-6 at x=0-5, col-10 at y=0-3:
        //   right×6: (1,0)→,...,(6,0)→
        //   turnLeft → (6,0)↑
        //   up×6: (6,1)↑,...,(6,6)↑  [(6,6) clear: row-6 at x=0-5]
        //   turnRight → (6,6)→
        //   right×6: (7,6)→,...,(12,6)→  [(10,6) clear: col-10 only y=0-3]
        //   turnLeft → (12,6)↑
        //   up×3: (12,7)↑,(12,8)↑,(12,9)↑ = GOAL
        // blockCount = repeat(6)=2+1+repeat(6)=2+1+repeat(6)=2+1+repeat(3)=2 = 11 ≤ 12
        let program = try Parser.parse(
            "repeat(6){ move(); } turnLeft(); repeat(6){ move(); } turnRight(); repeat(6){ move(); } turnLeft(); repeat(3){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 30 going straight right then up hits the debris wall")
    func challenge30DebrisWallCrashes() throws {
        let c = try challenge(30)
        // Going up from (0,0) hits the debris wall at (0,6)
        let program = try Parser.parse("turnLeft(); repeat(7){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 0, y: 6))))
    }

    // MARK: Challenge 31 — Corner Sprint (easy)

    @Test("challenge 31 (Corner Sprint) canonical solution reaches the goal within maxBlocks")
    func challenge31Solution() throws {
        let c = try challenge(31)
        #expect(c.title == "Corner Sprint")
        // Verified trace from (0,0)→:
        //   right×8: (1,0)→,...,(8,0)→
        //   turnLeft → (8,0)↑
        //   up×6: (8,1)↑,...,(8,6)↑ = GOAL
        // blockCount = repeat(8)=2 + turnLeft=1 + repeat(6)=2 = 5 ≤ 6
        let program = try Parser.parse(
            "repeat(8){ move(); } turnLeft(); repeat(6){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 31 wrong turn direction misses the goal")
    func challenge31WrongTurnFails() throws {
        let c = try challenge(31)
        // Turning right instead of left goes off-grid downward
        let program = try Parser.parse(
            "repeat(8){ move(); } turnRight(); repeat(6){ move(); }"
        )
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 32 — Canyon Crossing (hard)

    @Test("challenge 32 (Canyon Crossing) canonical solution reaches the goal within maxBlocks")
    func challenge32Solution() throws {
        let c = try challenge(32)
        #expect(c.title == "Canyon Crossing")
        // Verified trace from (0,0)→, row-5 at x=5-13, col-9 at y=0-4:
        //   right×4: (1,0)→,(2,0)→,(3,0)→,(4,0)→
        //   turnLeft → (4,0)↑
        //   up×6: (4,1)↑,...,(4,6)↑  [(4,5) clear: row-5 starts at x=5]
        //   turnRight → (4,6)→
        //   right×7: (5,6)→,...,(11,6)→  [(9,6) clear: col-9 only y=0-4]
        //   turnLeft → (11,6)↑
        //   up×3: (11,7)↑,(11,8)↑,(11,9)↑ = GOAL
        // blockCount = repeat(4)=2+1+repeat(6)=2+1+repeat(7)=2+1+repeat(3)=2 = 11 ≤ 12
        let program = try Parser.parse(
            "repeat(4){ move(); } turnLeft(); repeat(6){ move(); } turnRight(); repeat(7){ move(); } turnLeft(); repeat(3){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 32 going straight right hits the row-5 barrier")
    func challenge32StraightCrashes() throws {
        let c = try challenge(32)
        // Going right 6 then up 5 hits row-5 barrier at (6,5)
        let program = try Parser.parse(
            "repeat(6){ move(); } turnLeft(); repeat(6){ move(); }"
        )
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 6, y: 5))))
    }

    // MARK: Challenge 33 — Storm Runner (superHard)

    @Test("challenge 33 (Storm Runner) canonical solution reaches the goal within maxBlocks")
    func challenge33Solution() throws {
        let c = try challenge(33)
        #expect(c.title == "Storm Runner")
        // Verified trace from (0,0)↑, 20×20:
        //   up×5: (0,1)↑,...,(0,5)↑  [obstacle (0,6) blocks further]
        //   turnRight → (0,5)→
        //   right×4: (1,5)→,(2,5)→,(3,5)→,(4,5)→  [col-5 at (5,5) blocks]
        //   turnLeft → (4,5)↑
        //   up×6: (4,6)↑,...,(4,11)↑  [col-5 at x=5, not x=4]
        //   turnRight → (4,11)→
        //   right×7: (5,11)→,...,(11,11)→  [(5,11) clear: col-5 only y=0-10]
        //   turnRight → (11,11)↓
        //   down×4: (11,10)↓,(11,9)↓,(11,8)↓,(11,7)↓  [col-11 obstacle y=12+]
        //   turnLeft → (11,7)→
        //   right×7: (12,7)→,...,(18,7)→  [(12,7) clear: col-12 only y=0-6]
        //   turnLeft → (18,7)↑
        //   up×12: (18,8)↑,...,(18,19)↑ = GOAL
        // blockCount = 2+1+2+1+2+1+2+1+2+1+2+1+2 = 20 ≤ 21
        let program = try Parser.parse("""
            repeat(5){ move(); } turnRight();
            repeat(4){ move(); } turnLeft();
            repeat(6){ move(); } turnRight();
            repeat(7){ move(); } turnRight();
            repeat(4){ move(); } turnLeft();
            repeat(7){ move(); } turnLeft();
            repeat(12){ move(); }
            """)
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 33 going straight up hits the col-0 obstacle")
    func challenge33StraightCrashes() throws {
        let c = try challenge(33)
        // Going straight up 7 from (0,0) hits obstacle at (0,6)
        let program = try Parser.parse("repeat(7){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 0, y: 6))))
    }

    // MARK: Challenge 34 — Calm After the Storm (easy)

    @Test("challenge 34 (Calm After the Storm) canonical solution reaches the goal within maxBlocks")
    func challenge34Solution() throws {
        let c = try challenge(34)
        #expect(c.title == "Calm After the Storm")
        // Verified trace from (0,0)↑:
        //   up×8: (0,1)↑,...,(0,8)↑
        //   turnRight → (0,8)→
        //   right×4: (1,8)→,(2,8)→,(3,8)→,(4,8)→ = GOAL
        // blockCount = repeat(8)=2 + turnRight=1 + repeat(4)=2 = 5 ≤ 6
        let program = try Parser.parse(
            "repeat(8){ move(); } turnRight(); repeat(4){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 34 wrong count stops short of goal")
    func challenge34WrongCountFails() throws {
        let c = try challenge(34)
        // up 7 lands at (0,7) not (0,8); goal not reachable
        let program = try Parser.parse(
            "repeat(7){ move(); } turnRight(); repeat(4){ move(); }"
        )
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.didNotReachGoal(finalPosition: Position(x: 4, y: 7))))
    }

    // MARK: Challenge 35 — The Grand Maze (superHard)

    @Test("challenge 35 (The Grand Maze) canonical solution reaches the goal within maxBlocks")
    func challenge35Solution() throws {
        let c = try challenge(35)
        #expect(c.title == "The Grand Maze")
        // Verified trace from (0,0)→, 18×18, obstacles: (0,5), col-10 y=0-1,
        //   row-9 at x=6-12, col-13 at y=9-15:
        //   right×6: (1,0)→,...,(6,0)→
        //   turnLeft → (6,0)↑
        //   up×4: (6,1)↑,...,(6,4)↑
        //   turnRight → (6,4)→
        //   right×3: (7,4)→,(8,4)→,(9,4)→
        //   turnRight → (9,4)↓
        //   down×2: (9,3)↓,(9,2)↓
        //   turnLeft → (9,2)→
        //   right×3: (10,2)→,(11,2)→,(12,2)→  [(10,2) clear: col-10 only y=0-1]
        //   turnLeft → (12,2)↑
        //   up×6: (12,3)↑,...,(12,8)↑  [(12,9) is obstacle: row-9 at x=12]
        //   turnRight → (12,8)→
        //   right×5: (13,8)→,...,(17,8)→  [(13,8) clear: col-13 only y=9-15]
        //   turnLeft → (17,8)↑
        //   up×7: (17,9)↑,...,(17,15)↑ = GOAL  [col-13 at x=13, not x=17]
        // blockCount = 2+1+2+1+2+1+2+1+2+1+2+1+2+1+2 = 22 ≤ 23
        let program = try Parser.parse("""
            repeat(6){ move(); } turnLeft();
            repeat(4){ move(); } turnRight();
            repeat(3){ move(); } turnRight();
            repeat(2){ move(); } turnLeft();
            repeat(3){ move(); } turnLeft();
            repeat(6){ move(); } turnRight();
            repeat(5){ move(); } turnLeft();
            repeat(7){ move(); }
            """)
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
    }

    @Test("challenge 35 going straight right hits the col-10 obstacle")
    func challenge35StraightFails() throws {
        let c = try challenge(35)
        // Going right from (0,0) hits the col-10 obstacle at (10,0)
        let program = try Parser.parse("repeat(11){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 10, y: 0))))
    }

    // MARK: Challenge 36 — First Crystal (easy, collectible intro)

    @Test("challenge 36 (First Crystal) canonical solution reaches goal and collects gem")
    func challenge36Solution() throws {
        let c = try challenge(36)
        #expect(c.title == "First Crystal")
        // Verified trace from (0,0)→:
        //   right×4: (1,0)→,(2,0)→[gem collected],(3,0)→,(4,0)→ = GOAL
        // blockCount = repeat(4)=2 ≤ 4; parMoves=4
        let program = try Parser.parse("repeat(4){ move(); }")
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 36 stopping early misses the gem and goal")
    func challenge36NaiveFails() throws {
        let c = try challenge(36)
        // Only moving 1 step reaches (1,0) — gem and goal not collected
        let program = try Parser.parse("move();")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 37 — Twin Pickup (easy)

    @Test("challenge 37 (Twin Pickup) canonical solution collects both gems")
    func challenge37Solution() throws {
        let c = try challenge(37)
        #expect(c.title == "Twin Pickup")
        // Verified trace from (0,0)↑:
        //   up×3: (0,1)↑,(0,2)↑,(0,3)↑[gem1]
        //   turnRight → (0,3)→
        //   right×3: (1,3)→,(2,3)→,(3,3)→
        //   turnLeft → (3,3)↑
        //   up×2: (3,4)↑,(3,5)↑[gem2] = GOAL
        // blockCount = 2+1+2+1+2 = 8 ≤ 10; parMoves = 3+3+2=8
        let program = try Parser.parse(
            "repeat(3){ move(); } turnRight(); repeat(3){ move(); } turnLeft(); repeat(2){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 37 going straight up misses gem-2 and goal")
    func challenge37NaiveFails() throws {
        let c = try challenge(37)
        let program = try Parser.parse("repeat(6){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 38 — Barrier Harvest (hard)

    @Test("challenge 38 (Barrier Harvest) canonical solution collects 2 gems and reaches goal")
    func challenge38Solution() throws {
        let c = try challenge(38)
        #expect(c.title == "Barrier Harvest")
        // Verified trace from (0,0)→, row-5 barrier x=0-3:
        //   right×4: (1,0)→,(2,0)→,(3,0)→,(4,0)→[gem1]
        //   turnLeft → (4,0)↑
        //   up×6: (4,1)↑,...,(4,6)↑[gem2]  [(4,5) clear: barrier x=0-3 only]
        //   turnRight → (4,6)→
        //   right×4: (5,6)→,(6,6)→,(7,6)→,(8,6)→
        //   turnLeft → (8,6)↑
        //   up×3: (8,7)↑,(8,8)↑,(8,9)↑ = GOAL  [gem3 at (8,4) not collected, but collectGoal=2 met]
        // blockCount = 2+1+2+1+2+1+2 = 11 ≤ 14
        let program = try Parser.parse(
            "repeat(4){ move(); } turnLeft(); repeat(6){ move(); } turnRight(); repeat(4){ move(); } turnLeft(); repeat(3){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 38 going straight up hits the row-5 barrier")
    func challenge38NaiveFails() throws {
        let c = try challenge(38)
        // Start facing right; turn left to face up then hit the row-5 barrier at (0,5)
        let program = try Parser.parse("turnLeft(); repeat(6){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 0, y: 5))))
    }

    // MARK: Challenge 39 — Gem at the Summit (easy)

    @Test("challenge 39 (Gem at the Summit) canonical solution collects gem at goal")
    func challenge39Solution() throws {
        let c = try challenge(39)
        #expect(c.title == "Gem at the Summit")
        // Verified trace from (0,0)↑:
        //   up×5: (0,1)↑,...,(0,5)↑
        //   turnRight → (0,5)→
        //   right×5: (1,5)→,...,(5,5)→[gem] = GOAL
        // blockCount = 2+1+2 = 5 ≤ 6
        let program = try Parser.parse(
            "repeat(5){ move(); } turnRight(); repeat(5){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 39 stopping one short misses both gem and goal")
    func challenge39NaiveFails() throws {
        let c = try challenge(39)
        let program = try Parser.parse("repeat(5){ move(); } turnRight(); repeat(4){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 40 — Column Cache (hard)

    @Test("challenge 40 (Column Cache) canonical solution collects all 3 gems")
    func challenge40Solution() throws {
        let c = try challenge(40)
        #expect(c.title == "Column Cache")
        // Verified trace from (0,0)→, col-4 y=0-8:
        //   right×3: (1,0)→,(2,0)→,(3,0)→[gem1]
        //   turnLeft → (3,0)↑
        //   up×9: (3,1)↑,...,(3,9)↑[gem2]  [(4,8) is obstacle but we're at x=3]
        //   turnRight → (3,9)→
        //   right×7: (4,9)→,...,(10,9)→[gem3] = GOAL  [(4,9) clear: col-4 only y=0-8]
        // blockCount = 2+1+2+1+2 = 8 ≤ 9; parMoves = 3+9+7 = 19
        let program = try Parser.parse(
            "repeat(3){ move(); } turnLeft(); repeat(9){ move(); } turnRight(); repeat(7){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 40 going right more than 3 hits the col-4 obstacle")
    func challenge40NaiveFails() throws {
        let c = try challenge(40)
        let program = try Parser.parse("repeat(5){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 4, y: 0))))
    }

    // MARK: Challenge 41 — Four-Corner Sweep (hard)

    @Test("challenge 41 (Four-Corner Sweep) canonical solution collects 4 gems and reaches goal")
    func challenge41Solution() throws {
        let c = try challenge(41)
        #expect(c.title == "Four-Corner Sweep")
        // Verified trace from (0,0)↑, col-7 y=0-3:
        //   up×4: (0,1)↑,...,(0,4)↑[gem1]
        //   turnRight → (0,4)→
        //   right×6: (1,4)→,...,(6,4)→[gem2]  [(7,4) clear: col-7 only y=0-3]
        //   turnLeft → (6,4)↑
        //   up×6: (6,5)↑,...,(6,10)↑[gem3]
        //   turnRight → (6,10)→
        //   right×4: (7,10)→,(8,10)→,(9,10)→,(10,10)→[gem4] = GOAL
        // blockCount = 2+1+2+1+2+1+2 = 11 ≤ 12; parMoves = 4+6+6+4 = 20
        let program = try Parser.parse(
            "repeat(4){ move(); } turnRight(); repeat(6){ move(); } turnLeft(); repeat(6){ move(); } turnRight(); repeat(4){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 41 going straight up hits no obstacles but misses gems and goal")
    func challenge41NaiveFails() throws {
        let c = try challenge(41)
        let program = try Parser.parse("repeat(10){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 42 — Crystal Storm (superHard)

    @Test("challenge 42 (Crystal Storm) canonical solution collects all 9 gems")
    func challenge42Solution() throws {
        let c = try challenge(42)
        #expect(c.title == "Crystal Storm")
        // Verified trace from (0,0)↑, 20×20:
        //   up×3=(0,3)[g1], turnRight, right×3=(3,3)[g2]
        //   turnLeft, up×5=(3,8)[g3], turnRight, right×5=(8,8)[g4]
        //   turnRight, down×5=(8,3)[g5], turnLeft, right×4=(12,3)[g6]
        //   turnLeft, up×8=(12,11)[g7], turnRight, right×5=(17,11)[g8]
        //   turnRight, down×6=(17,5)[g9] = GOAL
        // blockCount = 9×2 + 8 = 26 ≤ 27; parMoves = 3+3+5+5+5+4+8+5+6 = 44
        let program = try Parser.parse("""
            repeat(3){ move(); } turnRight();
            repeat(3){ move(); } turnLeft();
            repeat(5){ move(); } turnRight();
            repeat(5){ move(); } turnRight();
            repeat(5){ move(); } turnLeft();
            repeat(4){ move(); } turnLeft();
            repeat(8){ move(); } turnRight();
            repeat(5){ move(); } turnRight();
            repeat(6){ move(); }
            """)
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 42 going straight up hits the col-0 barrier obstacle")
    func challenge42NaiveFails() throws {
        let c = try challenge(42)
        let program = try Parser.parse("repeat(5){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 0, y: 4))))
    }

    // MARK: Challenge 43 — Quick Recovery (easy)

    @Test("challenge 43 (Quick Recovery) canonical solution collects gem and reaches goal")
    func challenge43Solution() throws {
        let c = try challenge(43)
        #expect(c.title == "Quick Recovery")
        // Verified trace from (0,0)→:
        //   right×5: (1,0)→,...,(5,0)→
        //   turnLeft → (5,0)↑
        //   up×2: (5,1)↑,(5,2)↑[gem] = GOAL
        // blockCount = 2+1+2 = 5 ≤ 6
        let program = try Parser.parse(
            "repeat(5){ move(); } turnLeft(); repeat(2){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 43 wrong turn direction misses gem and goal")
    func challenge43NaiveFails() throws {
        let c = try challenge(43)
        let program = try Parser.parse("repeat(5){ move(); } turnRight(); repeat(2){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 44 — Dual Deposit (easy)

    @Test("challenge 44 (Dual Deposit) canonical solution collects both gems")
    func challenge44Solution() throws {
        let c = try challenge(44)
        #expect(c.title == "Dual Deposit")
        // Verified trace from (0,0)↑:
        //   up×3: (0,1)↑,(0,2)↑,(0,3)↑[gem1]
        //   turnRight → (0,3)→
        //   right×7: (1,3)→,...,(7,3)→[gem2] = GOAL
        // blockCount = 2+1+2 = 5 ≤ 6; parMoves = 3+7 = 10
        let program = try Parser.parse(
            "repeat(3){ move(); } turnRight(); repeat(7){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 44 going right first misses gem-1 and stops short of goal")
    func challenge44NaiveFails() throws {
        let c = try challenge(44)
        let program = try Parser.parse("repeat(7){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 45 — Blocked Bounty (hard)

    @Test("challenge 45 (Blocked Bounty) canonical solution collects all 3 gems")
    func challenge45Solution() throws {
        let c = try challenge(45)
        #expect(c.title == "Blocked Bounty")
        // Verified trace from (0,0)→, col-6 y=0-5:
        //   right×5: (1,0)→,...,(5,0)→[gem1]
        //   turnLeft → (5,0)↑
        //   up×6: (5,1)↑,...,(5,6)↑[gem2]  [(6,6) clear: col-6 only y=0-5]
        //   turnRight → (5,6)→
        //   right×5: (6,6)→,...,(10,6)→[gem3] = GOAL  [(6,6) clear ✓]
        // blockCount = 2+1+2+1+2 = 8 ≤ 9; parMoves = 5+6+5 = 16
        let program = try Parser.parse(
            "repeat(5){ move(); } turnLeft(); repeat(6){ move(); } turnRight(); repeat(5){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 45 going right 7 hits the col-6 wall obstacle")
    func challenge45NaiveFails() throws {
        let c = try challenge(45)
        let program = try Parser.parse("repeat(7){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 6, y: 0))))
    }

    // MARK: Challenge 46 — Vertical Vault (easy)

    @Test("challenge 46 (Vertical Vault) canonical solution collects both gems")
    func challenge46Solution() throws {
        let c = try challenge(46)
        #expect(c.title == "Vertical Vault")
        // Verified trace from (0,0)→:
        //   right×4: (1,0)→,...,(4,0)→[gem1]
        //   turnLeft → (4,0)↑
        //   up×8: (4,1)↑,...,(4,8)↑[gem2] = GOAL
        // blockCount = 2+1+2 = 5 ≤ 6; parMoves=4+8=12
        let program = try Parser.parse(
            "repeat(4){ move(); } turnLeft(); repeat(8){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 46 going right only reaches gem-1 but not the goal")
    func challenge46NaiveFails() throws {
        let c = try challenge(46)
        let program = try Parser.parse("repeat(4){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 47 — Zigzag Haul (hard)

    @Test("challenge 47 (Zigzag Haul) canonical solution collects 4 gems and reaches goal")
    func challenge47Solution() throws {
        let c = try challenge(47)
        #expect(c.title == "Zigzag Haul")
        // Verified trace from (0,0)↑, col-9 y=0-4:
        //   up×5: (0,1)↑,...,(0,5)↑[gem1]
        //   turnRight → (0,5)→
        //   right×8: (1,5)→,...,(8,5)→[gem2]  [(9,5) clear: col-9 only y=0-4]
        //   turnLeft → (8,5)↑
        //   up×5: (8,6)↑,...,(8,10)↑[gem3]
        //   turnRight → (8,10)→
        //   right×4: (9,10)→,(10,10)→,(11,10)→,(12,10)→[gem4] = GOAL
        // blockCount = 2+1+2+1+2+1+2 = 11 ≤ 12; parMoves = 5+8+5+4=22
        let program = try Parser.parse(
            "repeat(5){ move(); } turnRight(); repeat(8){ move(); } turnLeft(); repeat(5){ move(); } turnRight(); repeat(4){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 47 going straight up misses the goal")
    func challenge47NaiveFails() throws {
        let c = try challenge(47)
        let program = try Parser.parse("repeat(11){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 48 — Spiral Siege (superHard)

    @Test("challenge 48 (Spiral Siege) canonical solution collects 7+ gems and reaches goal")
    func challenge48Solution() throws {
        let c = try challenge(48)
        #expect(c.title == "Spiral Siege")
        // Verified trace from (0,0)↑, 20×20:
        //   up×3=(0,3)[g1], turnRight, right×5=(5,3)[g2]  [col-6 at y=0-2 → (6,3) clear]
        //   turnLeft, up×6=(5,9)[g3], turnRight, right×5=(10,9)[g4]  [(11,9) clear: col-11 y=0-3]
        //   turnRight, down×5=(10,4)[g5], turnLeft, right×4=(14,4)[g6]  [(11,4) clear: col-11 y=0-3]
        //   turnLeft, up×6=(14,10)[g7], turnRight, right×4=(18,10)[g8]  [(15,10) clear: col-15 y=11+]
        //   turnRight, down×6=(18,4)[g9]=GOAL  [col-19 at x=19 ✓]
        // blockCount = 9×2+8 = 26 ≤ 27; parMoves = 3+5+6+5+5+4+6+4+6 = 44
        let program = try Parser.parse("""
            repeat(3){ move(); } turnRight();
            repeat(5){ move(); } turnLeft();
            repeat(6){ move(); } turnRight();
            repeat(5){ move(); } turnRight();
            repeat(5){ move(); } turnLeft();
            repeat(4){ move(); } turnLeft();
            repeat(6){ move(); } turnRight();
            repeat(4){ move(); } turnRight();
            repeat(6){ move(); }
            """)
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 48 going straight up hits the col-0 barrier")
    func challenge48NaiveFails() throws {
        let c = try challenge(48)
        let program = try Parser.parse("repeat(5){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 0, y: 4))))
    }

    // MARK: Challenge 49 — Gem Drop (easy)

    @Test("challenge 49 (Gem Drop) canonical solution collects gem and reaches goal")
    func challenge49Solution() throws {
        let c = try challenge(49)
        #expect(c.title == "Gem Drop")
        // Verified trace from (0,0)→:
        //   right×3: (1,0)→,(2,0)→,(3,0)→
        //   turnLeft → (3,0)↑
        //   up×3: (3,1)↑,(3,2)↑,(3,3)↑[gem] = GOAL
        // blockCount = 2+1+2 = 5 ≤ 6
        let program = try Parser.parse(
            "repeat(3){ move(); } turnLeft(); repeat(3){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 49 wrong turn direction misses the goal")
    func challenge49NaiveFails() throws {
        let c = try challenge(49)
        let program = try Parser.parse("repeat(3){ move(); } turnRight(); repeat(3){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 50 — High and Low (easy)

    @Test("challenge 50 (High and Low) canonical solution collects both gems and reaches goal")
    func challenge50Solution() throws {
        let c = try challenge(50)
        #expect(c.title == "High and Low")
        // Verified trace from (0,0)↑:
        //   up×5: (0,1)↑,...,(0,5)↑[gem1]
        //   turnRight → (0,5)→
        //   right×6: (1,5)→,...,(6,5)→
        //   turnLeft → (6,5)↑
        //   up×2: (6,6)↑,(6,7)↑[gem2] = GOAL
        // blockCount = 2+1+2+1+2 = 8 ≤ 9; parMoves = 5+6+2=13
        let program = try Parser.parse(
            "repeat(5){ move(); } turnRight(); repeat(6){ move(); } turnLeft(); repeat(2){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 50 going straight up stops short of goal")
    func challenge50NaiveFails() throws {
        let c = try challenge(50)
        let program = try Parser.parse("repeat(7){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 51 — Descent Cache (hard)

    @Test("challenge 51 (Descent Cache) canonical solution collects 4 gems and reaches goal")
    func challenge51Solution() throws {
        let c = try challenge(51)
        #expect(c.title == "Descent Cache")
        // Verified trace from (0,0)→, col-7 y=0-6:
        //   right×6: (1,0)→,...,(6,0)→[gem1]  [(7,0) IS in col-7 obstacle: stops at x=6]
        //   turnLeft → (6,0)↑
        //   up×7: (6,1)↑,...,(6,7)↑[gem2]  [col-7 at x=7, not x=6]
        //   turnRight → (6,7)→
        //   right×5: (7,7)→,...,(11,7)→[gem3]  [(7,7) clear: col-7 only y=0-6]
        //   turnRight → (11,7)↓
        //   down×5: (11,6)↓,...,(11,2)↓[gem4] = GOAL
        // blockCount = 2+1+2+1+2+1+2 = 11 ≤ 12; parMoves = 6+7+5+5=23
        let program = try Parser.parse(
            "repeat(6){ move(); } turnLeft(); repeat(7){ move(); } turnRight(); repeat(5){ move(); } turnRight(); repeat(5){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 51 going right 7 hits the col-7 obstacle")
    func challenge51NaiveFails() throws {
        let c = try challenge(51)
        let program = try Parser.parse("repeat(8){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 7, y: 0))))
    }

    // MARK: Challenge 52 — Summit Sweep (hard)

    @Test("challenge 52 (Summit Sweep) canonical solution collects all 3 gems and reaches summit")
    func challenge52Solution() throws {
        let c = try challenge(52)
        #expect(c.title == "Summit Sweep")
        // Verified trace from (0,0)↑, col-9 y=0-5:
        //   up×6: (0,1)↑,...,(0,6)↑[gem1]
        //   turnRight → (0,6)→
        //   right×8: (1,6)→,...,(8,6)→[gem2]  [(9,6) clear: col-9 only y=0-5]
        //   turnLeft → (8,6)↑
        //   up×6: (8,7)↑,...,(8,12)↑[gem3] = GOAL
        // blockCount = 2+1+2+1+2 = 8 ≤ 9; parMoves = 6+8+6=20
        let program = try Parser.parse(
            "repeat(6){ move(); } turnRight(); repeat(8){ move(); } turnLeft(); repeat(6){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 52 going right 9 steps hits the col-9 obstacle")
    func challenge52NaiveFails() throws {
        let c = try challenge(52)
        let program = try Parser.parse("turnRight(); repeat(10){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 9, y: 0))))
    }

    // MARK: Challenge 53 — Corner Crystals (easy)

    @Test("challenge 53 (Corner Crystals) canonical solution collects both gems")
    func challenge53Solution() throws {
        let c = try challenge(53)
        #expect(c.title == "Corner Crystals")
        // Verified trace from (0,0)→:
        //   right×4: (1,0)→,...,(4,0)→[gem1]
        //   turnLeft → (4,0)↑
        //   up×6: (4,1)↑,...,(4,6)↑[gem2] = GOAL
        // blockCount = 2+1+2 = 5 ≤ 6; parMoves=4+6=10
        let program = try Parser.parse(
            "repeat(4){ move(); } turnLeft(); repeat(6){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 53 turning right instead of left misses the goal")
    func challenge53NaiveFails() throws {
        let c = try challenge(53)
        let program = try Parser.parse("repeat(4){ move(); } turnRight(); repeat(6){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 54 — Deepspace Spiral (superHard)

    @Test("challenge 54 (Deepspace Spiral) canonical solution collects 7+ gems and reaches goal")
    func challenge54Solution() throws {
        let c = try challenge(54)
        #expect(c.title == "Deepspace Spiral")
        // Verified trace from (0,0)→, 20×20:
        //   right×5=(5,0)[g1], turnLeft→↑
        //   up×7=(5,7)[g2]  [col-6 y=0-6 blocks (6,x) only]
        //   turnRight→→, right×5=(10,7)[g3]  [(6,7) clear: col-6 y=0-6; (11,7) clear: col-11 y=0-1]
        //   turnRight→↓, down×5=(10,2)[g4]
        //   turnLeft→→, right×4=(14,2)[g5]  [(11,2) clear: col-11 y=0-1; (15,2) clear: col-15 y=0-1]
        //   turnLeft→↑, up×8=(14,10)[g6]  [col-15 y=11+ blocks above, y=10 clear]
        //   turnRight→→, right×4=(18,10)[g7]  [(15,10) clear: col-15 y=11+; (19,10) clear: col-19 y=0-13 IS obstacle!]
        //   turnLeft→↑, up×4=(18,14)[g8]=GOAL
        // Note: (19,10) is in col-19 y=0-13 obstacle; robot at x=18 is fine ✓
        // blockCount = 8×2+7 = 23 ≤ 25; parMoves = 5+7+5+5+4+8+4+4=42
        let program = try Parser.parse("""
            repeat(5){ move(); } turnLeft();
            repeat(7){ move(); } turnRight();
            repeat(5){ move(); } turnRight();
            repeat(5){ move(); } turnLeft();
            repeat(4){ move(); } turnLeft();
            repeat(8){ move(); } turnRight();
            repeat(4){ move(); } turnLeft();
            repeat(4){ move(); }
            """)
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 54 going straight right hits the col-6 obstacle")
    func challenge54NaiveFails() throws {
        let c = try challenge(54)
        let program = try Parser.parse("repeat(7){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 6, y: 0))))
    }

    // MARK: Challenge 55 — Diamond Cross (easy)

    @Test("challenge 55 (Diamond Cross) canonical solution collects the gem at goal")
    func challenge55Solution() throws {
        let c = try challenge(55)
        #expect(c.title == "Diamond Cross")
        // Verified trace from (0,0)↑:
        //   up×4: (0,1)↑,...,(0,4)↑
        //   turnRight → (0,4)→
        //   right×4: (1,4)→,...,(4,4)→[gem] = GOAL
        // blockCount = 2+1+2 = 5 ≤ 6
        let program = try Parser.parse(
            "repeat(4){ move(); } turnRight(); repeat(4){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 55 wrong count stops short of gem and goal")
    func challenge55NaiveFails() throws {
        let c = try challenge(55)
        let program = try Parser.parse("repeat(4){ move(); } turnRight(); repeat(3){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 56 — Waypoint Rush (easy)

    @Test("challenge 56 (Waypoint Rush) canonical solution collects both gems")
    func challenge56Solution() throws {
        let c = try challenge(56)
        #expect(c.title == "Waypoint Rush")
        // Verified trace from (0,0)↑:
        //   up×4: (0,1)↑,...,(0,4)↑[gem1]
        //   turnRight → (0,4)→
        //   right×6: (1,4)→,...,(6,4)→[gem2] = GOAL
        // blockCount = 2+1+2 = 5 ≤ 6
        let program = try Parser.parse(
            "repeat(4){ move(); } turnRight(); repeat(6){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 56 going right without climbing misses gem-1 and goal")
    func challenge56NaiveFails() throws {
        let c = try challenge(56)
        let program = try Parser.parse("repeat(6){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 57 — Pillar Bypass Haul (hard)

    @Test("challenge 57 (Pillar Bypass Haul) canonical solution collects all 3 gems")
    func challenge57Solution() throws {
        let c = try challenge(57)
        #expect(c.title == "Pillar Bypass Haul")
        // Verified trace from (0,0)→, col-8 y=0-7:
        //   right×7: (1,0)→,...,(7,0)→[gem1]  [(8,0) IS in col-8 obstacle: stops at x=7]
        //   turnLeft → (7,0)↑
        //   up×8: (7,1)↑,...,(7,8)↑[gem2]  [(8,8) clear: col-8 only y=0-7]
        //   turnRight → (7,8)→
        //   right×5: (8,8)→,...,(12,8)→[gem3] = GOAL
        // blockCount = 2+1+2+1+2 = 8 ≤ 9; parMoves = 7+8+5=20
        let program = try Parser.parse(
            "repeat(7){ move(); } turnLeft(); repeat(8){ move(); } turnRight(); repeat(5){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 57 going right 8 hits the pillar obstacle")
    func challenge57NaiveFails() throws {
        let c = try challenge(57)
        let program = try Parser.parse("repeat(9){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 8, y: 0))))
    }

    // MARK: Challenge 58 — Center Stone (easy)

    @Test("challenge 58 (Center Stone) canonical solution collects gem and reaches goal")
    func challenge58Solution() throws {
        let c = try challenge(58)
        #expect(c.title == "Center Stone")
        // Verified trace from (0,0)→:
        //   right×4: (1,0)→,...,(4,0)→
        //   turnLeft → (4,0)↑
        //   up×4: (4,1)↑,...,(4,4)↑[gem] = GOAL
        // blockCount = 2+1+2 = 5 ≤ 6
        let program = try Parser.parse(
            "repeat(4){ move(); } turnLeft(); repeat(4){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 58 going straight right misses goal and gem")
    func challenge58NaiveFails() throws {
        let c = try challenge(58)
        let program = try Parser.parse("repeat(4){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 59 — Horseshoe Run (hard)

    @Test("challenge 59 (Horseshoe Run) canonical solution collects 4 gems and reaches goal")
    func challenge59Solution() throws {
        let c = try challenge(59)
        #expect(c.title == "Horseshoe Run")
        // Verified trace from (0,0)↑, col-10 y=0-10:
        //   up×5: (0,1)↑,...,(0,5)↑[gem1]
        //   turnRight → (0,5)→
        //   right×9: (1,5)→,...,(9,5)→[gem2]  [(10,5) IS in col-10: stops at x=9]
        //   turnLeft → (9,5)↑
        //   up×6: (9,6)↑,...,(9,11)↑[gem3]
        //   turnLeft → (9,11)←
        //   left×5: (8,11)←,...,(4,11)←[gem4] = GOAL
        // blockCount = 2+1+2+1+2+1+2 = 11 ≤ 12; parMoves = 5+9+6+5=25
        let program = try Parser.parse(
            "repeat(5){ move(); } turnRight(); repeat(9){ move(); } turnLeft(); repeat(6){ move(); } turnLeft(); repeat(5){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 59 going straight right 10 hits the col-10 pillar")
    func challenge59NaiveFails() throws {
        let c = try challenge(59)
        let program = try Parser.parse("repeat(5){ move(); } turnRight(); repeat(11){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 10, y: 5))))
    }

    // MARK: Challenge 60 — Vortex Loop (superHard)

    @Test("challenge 60 (Vortex Loop) canonical solution collects 7+ gems and reaches goal")
    func challenge60Solution() throws {
        let c = try challenge(60)
        #expect(c.title == "Vortex Loop")
        // Verified trace from (0,0)↑, 20×20:
        //   up×4=(0,4)[g1]  [col-0 y=5+ blocks]
        //   turnRight, right×6=(6,4)[g2]  [col-7 y=0-3 → (7,4) clear]
        //   turnLeft, up×6=(6,10)[g3]
        //   turnRight, right×6=(12,10)[g4]  [col-13 y=5-9 → (13,10) clear]
        //   turnRight, down×8=(12,2)[g5]
        //   turnLeft, right×4=(16,2)[g6]  [col-13 y=5-9 → (13,2) clear; col-17 y=0-1 → (17,2) clear]
        //   turnLeft, up×6=(16,8)[g7]  [col-17 y=0-1 below]
        //   turnRight, right×2=(18,8)[g8]=GOAL  [col-19 y=0-7 → (19,8) clear]
        // blockCount = 8×2+7 = 23 ≤ 25; parMoves = 4+6+6+6+8+4+6+2=42
        let program = try Parser.parse("""
            repeat(4){ move(); } turnRight();
            repeat(6){ move(); } turnLeft();
            repeat(6){ move(); } turnRight();
            repeat(6){ move(); } turnRight();
            repeat(8){ move(); } turnLeft();
            repeat(4){ move(); } turnLeft();
            repeat(6){ move(); } turnRight();
            repeat(2){ move(); }
            """)
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 60 going straight up hits the col-0 barrier")
    func challenge60NaiveFails() throws {
        let c = try challenge(60)
        let program = try Parser.parse("repeat(6){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 0, y: 5))))
    }

    // MARK: Challenge 61 — Soft Landing (easy)

    @Test("challenge 61 (Soft Landing) canonical solution collects gem and reaches goal")
    func challenge61Solution() throws {
        let c = try challenge(61)
        #expect(c.title == "Soft Landing")
        // Verified trace from (0,0)→:
        //   right×6: (1,0)→,...,(6,0)→
        //   turnLeft → (6,0)↑
        //   up×3: (6,1)↑,(6,2)↑,(6,3)↑[gem] = GOAL
        // blockCount = 2+1+2 = 5 ≤ 6
        let program = try Parser.parse(
            "repeat(6){ move(); } turnLeft(); repeat(3){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 61 going up first stops short of goal")
    func challenge61NaiveFails() throws {
        let c = try challenge(61)
        let program = try Parser.parse("repeat(3){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 62 — Crescent Sweep (hard)

    @Test("challenge 62 (Crescent Sweep) canonical solution collects 3+ gems and reaches goal")
    func challenge62Solution() throws {
        let c = try challenge(62)
        #expect(c.title == "Crescent Sweep")
        // Verified trace from (0,0)↑, col-9 y=0-5:
        //   up×6: (0,1)↑,...,(0,6)↑[gem1]
        //   turnRight → (0,6)→
        //   right×8: (1,6)→,...,(8,6)→[gem2]  [(9,6) clear: col-9 only y=0-5]
        //   turnLeft → (8,6)↑
        //   up×6: (8,7)↑,...,(8,12)↑[gem3]
        //   turnLeft → (8,12)←
        //   left×3: (7,12)←,(6,12)←,(5,12)←[gem4] = GOAL
        // blockCount = 2+1+2+1+2+1+2 = 11 ≤ 12; parMoves = 6+8+6+3=23
        let program = try Parser.parse(
            "repeat(6){ move(); } turnRight(); repeat(8){ move(); } turnLeft(); repeat(6){ move(); } turnLeft(); repeat(3){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 62 going straight right 9 hits the col-9 obstacle")
    func challenge62NaiveFails() throws {
        let c = try challenge(62)
        let program = try Parser.parse("turnRight(); repeat(10){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 9, y: 0))))
    }

    // MARK: Challenge 63 — Split Path (easy)

    @Test("challenge 63 (Split Path) canonical solution collects both gems")
    func challenge63Solution() throws {
        let c = try challenge(63)
        #expect(c.title == "Split Path")
        // Verified trace from (0,0)→:
        //   right×3: (1,0)→,(2,0)→,(3,0)→[gem1]
        //   turnLeft → (3,0)↑
        //   up×7: (3,1)↑,...,(3,7)↑[gem2] = GOAL
        // blockCount = 2+1+2 = 5 ≤ 6; parMoves = 3+7=10
        let program = try Parser.parse(
            "repeat(3){ move(); } turnLeft(); repeat(7){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 63 going straight right misses goal")
    func challenge63NaiveFails() throws {
        let c = try challenge(63)
        let program = try Parser.parse("repeat(3){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 64 — Omega Loop (hard)

    @Test("challenge 64 (Omega Loop) canonical solution collects all 4 gems and reaches goal")
    func challenge64Solution() throws {
        let c = try challenge(64)
        #expect(c.title == "Omega Loop")
        // Verified trace from (0,0)↑, col-11 y=0-10:
        //   up×6: (0,1)↑,...,(0,6)↑[gem1]
        //   turnRight → (0,6)→
        //   right×10: (1,6)→,...,(10,6)→[gem2]  [(11,6) IS in col-11: stops at x=10]
        //   turnLeft → (10,6)↑
        //   up×5: (10,7)↑,...,(10,11)↑[gem3]  [(11,11) clear: col-11 only y=0-10]
        //   turnLeft → (10,11)←
        //   left×8: (9,11)←,...,(2,11)←[gem4] = GOAL
        // blockCount = 2+1+2+1+2+1+2 = 11 ≤ 12; parMoves = 6+10+5+8=29
        let program = try Parser.parse(
            "repeat(6){ move(); } turnRight(); repeat(10){ move(); } turnLeft(); repeat(5){ move(); } turnLeft(); repeat(8){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 64 going right 11 hits the col-11 pillar")
    func challenge64NaiveFails() throws {
        let c = try challenge(64)
        let program = try Parser.parse("repeat(6){ move(); } turnRight(); repeat(12){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 11, y: 6))))
    }

    // MARK: Challenge 65 — Step Collector (easy)

    @Test("challenge 65 (Step Collector) canonical solution collects both gems and reaches goal")
    func challenge65Solution() throws {
        let c = try challenge(65)
        #expect(c.title == "Step Collector")
        // Verified trace from (0,0)↑:
        //   up×3: (0,1)↑,(0,2)↑,(0,3)↑
        //   turnRight → (0,3)→
        //   right×4: (1,3)→,...,(4,3)→[gem1]
        //   turnLeft → (4,3)↑
        //   up×5: (4,4)↑,...,(4,8)↑[gem2] = GOAL
        // blockCount = 2+1+2+1+2 = 8 ≤ 9; parMoves = 3+4+5=12
        let program = try Parser.parse(
            "repeat(3){ move(); } turnRight(); repeat(4){ move(); } turnLeft(); repeat(5){ move(); }"
        )
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 65 going straight up misses the gems and goal")
    func challenge65NaiveFails() throws {
        let c = try challenge(65)
        let program = try Parser.parse("repeat(8){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 66 — Nebula Harvest (superHard)

    @Test("challenge 66 (Nebula Harvest) canonical solution collects 8 gems and reaches goal")
    func challenge66Solution() throws {
        let c = try challenge(66)
        #expect(c.title == "Nebula Harvest")
        // Verified trace from (0,0)↑, 18×18 grid:
        //   up×4: (0,4)↑[gem1]  [col-0 y=5 blocks further]
        //   turnRight → (0,4)→
        //   right×5: (5,4)→[gem2]  [(6,4) clear — col-6 y=0-3 only]
        //   turnLeft → (5,4)↑
        //   up×5: (5,9)↑[gem3]
        //   turnRight → (5,9)→
        //   right×5: (10,9)→[gem4]  [(11,9) clear — col-11 y=0-1 only]
        //   turnRight → (10,9)↓
        //   down×7: (10,2)↓[gem5]
        //   turnLeft → (10,2)→
        //   right×5: (15,2)→[gem6]  [(16,2) clear — col-16 y=0 only]
        //   turnLeft → (15,2)↑
        //   up×5: (15,7)↑[gem7]
        //   turnRight → (15,7)→
        //   move: (16,7)→[gem8] = GOAL
        // blockCount = 2+1+2+1+2+1+2+1+2+1+2+1+2+1+1 = 22 ≤ 25; parMoves = 4+5+5+5+7+5+5+1=37
        let program = try Parser.parse("""
            repeat(4){ move(); } turnRight(); repeat(5){ move(); } turnLeft();
            repeat(5){ move(); } turnRight(); repeat(5){ move(); } turnRight();
            repeat(7){ move(); } turnLeft(); repeat(5){ move(); } turnLeft();
            repeat(5){ move(); } turnRight(); move();
            """)
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 66 going straight up hits the col-0 obstacle")
    func challenge66NaiveFails() throws {
        let c = try challenge(66)
        let program = try Parser.parse("repeat(6){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 0, y: 5))))
    }

    // MARK: Challenge 67 — Rest Stop (easy)

    @Test("challenge 67 (Rest Stop) canonical solution collects the gem and reaches goal")
    func challenge67Solution() throws {
        let c = try challenge(67)
        #expect(c.title == "Rest Stop")
        // Verified trace from (0,0)→:
        //   right×5: (5,0)→
        //   turnLeft → (5,0)↑
        //   up×4: (5,4)↑[gem1] = GOAL
        // blockCount = 2+1+2 = 5 ≤ 6; parMoves = 5+4=9
        let program = try Parser.parse("repeat(5){ move(); } turnLeft(); repeat(4){ move(); }")
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 67 going straight right misses the gem and goal")
    func challenge67NaiveFails() throws {
        let c = try challenge(67)
        let program = try Parser.parse("repeat(6){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 68 — Angled Approach (easy)

    @Test("challenge 68 (Angled Approach) canonical solution collects both gems and reaches goal")
    func challenge68Solution() throws {
        let c = try challenge(68)
        #expect(c.title == "Angled Approach")
        // Verified trace from (0,0)↑:
        //   turnRight → (0,0)→
        //   right×5: (5,0)→[gem1]
        //   turnLeft → (5,0)↑
        //   up×7: (5,7)↑[gem2] = GOAL
        // blockCount = 1+2+1+2 = 6 ≤ 7; parMoves = 5+7=12
        let program = try Parser.parse("turnRight(); repeat(5){ move(); } turnLeft(); repeat(7){ move(); }")
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 68 going straight up misses both gems and goal")
    func challenge68NaiveFails() throws {
        let c = try challenge(68)
        let program = try Parser.parse("repeat(8){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 69 — Box Route (hard)

    @Test("challenge 69 (Box Route) canonical solution collects 4 gems and reaches goal")
    func challenge69Solution() throws {
        let c = try challenge(69)
        #expect(c.title == "Box Route")
        // Verified trace from (0,0)→, col-7 y=0-8:
        //   right×6: (6,0)→[gem1]  [(7,0) col-7 blocked]
        //   turnLeft → (6,0)↑
        //   up×9: (6,9)↑[gem2]
        //   turnRight → (6,9)→
        //   right×6: (12,9)→[gem3]  [(7,9) clear — col-7 y=0-8 only]
        //   turnRight → (12,9)↓
        //   down×5: (12,4)↓[gem4] = GOAL
        // blockCount = 2+1+2+1+2+1+2 = 11 ≤ 12; parMoves = 6+9+6+5=26
        let program = try Parser.parse("""
            repeat(6){ move(); } turnLeft(); repeat(9){ move(); }
            turnRight(); repeat(6){ move(); } turnRight(); repeat(5){ move(); }
            """)
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 69 going straight right hits the col-7 barrier")
    func challenge69NaiveFails() throws {
        let c = try challenge(69)
        let program = try Parser.parse("repeat(8){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 7, y: 0))))
    }

    // MARK: Challenge 70 — Cosmic Spiral (superHard)

    @Test("challenge 70 (Cosmic Spiral) canonical solution collects 9 gems and reaches goal")
    func challenge70Solution() throws {
        let c = try challenge(70)
        #expect(c.title == "Cosmic Spiral")
        // Verified trace from (0,0)↑, 22×22 grid:
        //   up×5: (0,5)↑[gem1]  [col-0 y=6-11 blocks further]
        //   turnRight → (0,5)→
        //   right×7: (7,5)→[gem2]  [(8,5) clear — col-8 y=0-4 only]
        //   turnLeft → (7,5)↑
        //   up×7: (7,12)↑[gem3]
        //   turnRight → (7,12)→
        //   right×7: (14,12)→[gem4]  [(15,12) clear — col-15 y=4-11 only]
        //   turnRight → (14,12)↓
        //   down×10: (14,2)↓[gem5]
        //   turnLeft → (14,2)→
        //   right×5: (19,2)→[gem6]  [(20,2) col-20 y=0-9 blocked]
        //   turnLeft → (19,2)↑
        //   up×8: (19,10)↑[gem7]  [(20,10) clear — col-20 y=0-9 only]
        //   turnRight → (19,10)→
        //   right×2: (21,10)→[gem8]
        //   turnRight → (21,10)↓
        //   down×3: (21,7)↓[gem9] = GOAL
        // blockCount = 9×2 + 8 = 26 ≤ 27; parMoves = 5+7+7+7+10+5+8+2+3=54
        let program = try Parser.parse("""
            repeat(5){ move(); } turnRight(); repeat(7){ move(); } turnLeft();
            repeat(7){ move(); } turnRight(); repeat(7){ move(); } turnRight();
            repeat(10){ move(); } turnLeft(); repeat(5){ move(); } turnLeft();
            repeat(8){ move(); } turnRight(); repeat(2){ move(); } turnRight();
            repeat(3){ move(); }
            """)
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 70 going straight up hits the col-0 obstacle")
    func challenge70NaiveFails() throws {
        let c = try challenge(70)
        let program = try Parser.parse("repeat(7){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 0, y: 6))))
    }

    // MARK: Challenge 71 — Ice Rink Intro (easy)

    @Test("challenge 71 (Ice Rink Intro) one move slides across ice to collect gem and reach goal")
    func challenge71Solution() throws {
        let c = try challenge(71)
        #expect(c.title == "Ice Rink Intro")
        // Verified trace from (0,0)→:
        //   move: land (1,0)[ice] → slide to (2,0)[gem1] = GOAL
        // blockCount = 1 ≤ 2; parMoves = 1
        let program = try Parser.parse("move();")
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 71 not moving at all fails to reach goal")
    func challenge71NaiveFails() throws {
        let c = try challenge(71)
        let program = try Parser.parse("turnLeft();")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 72 — Ice Skip (easy)

    @Test("challenge 72 (Ice Skip) canonical solution slides through both ice patches to reach goal")
    func challenge72Solution() throws {
        let c = try challenge(72)
        #expect(c.title == "Ice Skip")
        // Verified trace from (0,0)→:
        //   move×1: (1,0)→
        //   move×2: (2,0)[ice] → slide (3,0)→
        //   move×3: (4,0)→
        //   move×4: (5,0)[ice] → slide (6,0)[gem1]→
        //   move×5: (7,0)→ = GOAL
        // blockCount = 2 ≤ 4; parMoves = 5
        let program = try Parser.parse("repeat(5){ move(); }")
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 72 stopping after 3 moves fails to reach goal")
    func challenge72NaiveFails() throws {
        let c = try challenge(72)
        let program = try Parser.parse("repeat(3){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 73 — Slick Harvest (hard)

    @Test("challenge 73 (Slick Harvest) canonical solution slides to both gems and reaches goal")
    func challenge73Solution() throws {
        let c = try challenge(73)
        #expect(c.title == "Slick Harvest")
        // Verified trace from (0,0)↑:
        //   up×4: (0,1)(0,2)(0,3)(0,4)[ice] → slide (0,5)[gem1]
        //   turnRight → (0,5)→
        //   right×6: (1,5)(2,5)(3,5)(4,5)(5,5)(6,5)[ice] → slide (7,5)[gem2]
        //   right×2: (8,5)(9,5) = GOAL
        // blockCount = 2+1+2+2 = 7 ≤ 8; parMoves = 4+6+2=12
        let program = try Parser.parse("repeat(4){ move(); } turnRight(); repeat(6){ move(); } repeat(2){ move(); }")
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 73 going straight up without turning misses the goal")
    func challenge73NaiveFails() throws {
        let c = try challenge(73)
        let program = try Parser.parse("repeat(6){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 74 — Ice Dash (easy)

    @Test("challenge 74 (Ice Dash) canonical solution rides ice slide to collect gem and reach goal")
    func challenge74Solution() throws {
        let c = try challenge(74)
        #expect(c.title == "Ice Dash")
        // Verified trace from (0,0)↑:
        //   up×3: (0,1)(0,2)(0,3)↑
        //   turnRight → (0,3)→
        //   right×5: (1,3)(2,3)(3,3)[ice]→slide(4,3)(5,3)(6,3)[gem1] = GOAL
        //   (ice at (3,3) slides to (4,3), then 2 more moves to (6,3))
        // blockCount = 2+1+2 = 5 ≤ 7; parMoves = 3+5=8
        let program = try Parser.parse("repeat(3){ move(); } turnRight(); repeat(5){ move(); }")
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 74 going straight up without turning misses the goal")
    func challenge74NaiveFails() throws {
        let c = try challenge(74)
        let program = try Parser.parse("repeat(6){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 75 — Frozen Corridor (hard)

    @Test("challenge 75 (Frozen Corridor) canonical solution rides three ice slides to collect all gems and reach goal")
    func challenge75Solution() throws {
        let c = try challenge(75)
        #expect(c.title == "Frozen Corridor")
        // Verified trace from (0,0)→:
        //   right×3: (1,0)(2,0)(3,0)[ice]→slide(4,0)[gem1]
        //   right×4: (5,0)(6,0)(7,0)(8,0)→
        //   turnLeft → (8,0)↑
        //   up×4: (8,1)(8,2)(8,3)(8,4)[ice]→slide(8,5)[gem2]
        //   move: (8,6)↑
        //   turnRight → (8,6)→
        //   right×3: (9,6)(10,6)(11,6)[ice]→slide(12,6)[gem3] = GOAL
        // blockCount = 2+2+1+2+1+1+2 = 11 ≤ 14; parMoves = 3+4+4+1+3=15
        let program = try Parser.parse("""
            repeat(3){ move(); } repeat(4){ move(); } turnLeft();
            repeat(4){ move(); } move(); turnRight();
            repeat(3){ move(); }
            """)
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 75 going straight right without turning misses the goal")
    func challenge75NaiveFails() throws {
        let c = try challenge(75)
        let program = try Parser.parse("repeat(8){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 76 — Frozen Spiral (superHard)

    @Test("challenge 76 (Frozen Spiral) canonical solution collects 8 gems via two ice slides and reaches goal")
    func challenge76Solution() throws {
        let c = try challenge(76)
        #expect(c.title == "Frozen Spiral")
        // Verified trace from (0,0)→, ice at (3,0) and (17,3):
        //   right×3: (1,0)(2,0)(3,0)[ice]→slide(4,0)[g1]
        //   turnLeft → ↑
        //   up×6: (4,1)...(4,6)[g2]  [(4,7) blocked]
        //   turnRight → →
        //   right×5: (5,6)...(9,6)[g3]
        //   turnLeft → ↑
        //   up×4: (9,7)...(9,10)[g4]  [(9,11) blocked]
        //   turnRight → →
        //   right×5: (10,10)...(14,10)[g5]  [(15,10) blocked]
        //   turnRight → ↓
        //   down×7: (14,9)...(14,3)[g6]
        //   turnLeft → →
        //   right×3: (15,3)(16,3)(17,3)[ice]→slide(18,3)[g7]  [(19,3) blocked]
        //   turnLeft → ↑
        //   up×3: (18,4)(18,5)(18,6)[g8] = GOAL
        // blockCount = 8×2 + 7 = 23 ≤ 25; parMoves = 3+6+5+4+5+7+3+3=36
        let program = try Parser.parse("""
            repeat(3){ move(); } turnLeft(); repeat(6){ move(); } turnRight();
            repeat(5){ move(); } turnLeft(); repeat(4){ move(); } turnRight();
            repeat(5){ move(); } turnRight(); repeat(7){ move(); } turnLeft();
            repeat(3){ move(); } turnLeft(); repeat(3){ move(); }
            """)
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 76 going straight up without any turns fails to reach goal")
    func challenge76NaiveFails() throws {
        let c = try challenge(76)
        let program = try Parser.parse("repeat(6){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 77 — Gentle Glide (easy)

    @Test("challenge 77 (Gentle Glide) two moves slide Vex to crystal and goal")
    func challenge77Solution() throws {
        let c = try challenge(77)
        #expect(c.title == "Gentle Glide")
        // Verified trace from (0,0)↑, ice at (0,2):
        //   up×2: (0,1)(0,2)[ice]→slide(0,3)[gem1] = GOAL
        // blockCount = 2 ≤ 3; parMoves = 2
        let program = try Parser.parse("repeat(2){ move(); }")
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 77 moving only once fails to reach goal")
    func challenge77NaiveFails() throws {
        let c = try challenge(77)
        let program = try Parser.parse("move();")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 78 — Double Drift (easy)

    @Test("challenge 78 (Double Drift) six moves slide through both ice patches to collect both gems and reach goal")
    func challenge78Solution() throws {
        let c = try challenge(78)
        #expect(c.title == "Double Drift")
        // Verified trace from (0,0)→, ice at (2,0) and (5,0):
        //   move×1: (1,0)
        //   move×2: (2,0)[ice]→slide(3,0)[gem1]
        //   move×3: (4,0)
        //   move×4: (5,0)[ice]→slide(6,0)[gem2]
        //   move×5: (7,0)
        //   move×6: (8,0) = GOAL
        // blockCount = 2 ≤ 3; parMoves = 6
        let program = try Parser.parse("repeat(6){ move(); }")
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 78 stopping after three moves fails to reach goal")
    func challenge78NaiveFails() throws {
        let c = try challenge(78)
        let program = try Parser.parse("repeat(3){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 79 — Ice Chain (hard)

    @Test("challenge 79 (Ice Chain) canonical solution chains three ice slides to collect all gems and reach goal")
    func challenge79Solution() throws {
        let c = try challenge(79)
        #expect(c.title == "Ice Chain")
        // Verified trace from (0,0)↑, ice at (0,4), (5,9), (7,9):
        //   up×4: (0,1)...(0,4)[ice]→slide(0,5)[gem1]
        //   move: (0,6)
        //   turnRight → →
        //   right×4: (1,6)...(4,6)
        //   turnLeft → ↑
        //   up×3: (4,7)(4,8)(4,9)
        //   turnRight → →
        //   move: (5,9)[ice]→slide(6,9)[gem2]
        //   move: (7,9)[ice]→slide(8,9)[gem3]
        //   move: (9,9)
        //   move: (10,9) = GOAL
        // blockCount = 2+1+1+2+1+2+1+1+1+1+1 = 14 ≤ 14; parMoves = 4+1+4+3+4=16
        let program = try Parser.parse("""
            repeat(4){ move(); } move(); turnRight(); repeat(4){ move(); }
            turnLeft(); repeat(3){ move(); } turnRight(); move(); move(); move(); move();
            """)
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 79 going straight up misses the gems and goal")
    func challenge79NaiveFails() throws {
        let c = try challenge(79)
        let program = try Parser.parse("repeat(8){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 80 — Short Slide (easy)

    @Test("challenge 80 (Short Slide) four moves hit ice then one more reaches goal")
    func challenge80Solution() throws {
        let c = try challenge(80)
        #expect(c.title == "Short Slide")
        // Verified trace from (0,0)→, ice at (4,0):
        //   right×4: (1,0)(2,0)(3,0)(4,0)[ice]→slide(5,0)[gem1]
        //   move: (6,0) = GOAL
        // blockCount = 2+1 = 3 ≤ 4; parMoves = 5
        let program = try Parser.parse("repeat(4){ move(); } move();")
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 80 stopping after three moves fails to reach goal")
    func challenge80NaiveFails() throws {
        let c = try challenge(80)
        let program = try Parser.parse("repeat(3){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 81 — Triple Ice Run (hard)

    @Test("challenge 81 (Triple Ice Run) canonical solution rides three ice slides to collect all gems and reach goal")
    func challenge81Solution() throws {
        let c = try challenge(81)
        #expect(c.title == "Triple Ice Run")
        // Verified trace from (0,0)↑, ice at (0,4), (5,5), (6,8):
        //   up×4: (0,1)...(0,4)[ice]→slide(0,5)[gem1]
        //   turnRight → →
        //   right×5: (1,5)...(5,5)[ice]→slide(6,5)[gem2]
        //   turnLeft → ↑
        //   up×3: (6,6)(6,7)(6,8)[ice]→slide(6,9)[gem3]
        //   turnRight → →
        //   right×4: (7,9)(8,9)(9,9)(10,9) = GOAL
        // blockCount = 2+1+2+1+2+1+2 = 11 ≤ 14; parMoves = 4+5+3+4=16
        let program = try Parser.parse("""
            repeat(4){ move(); } turnRight(); repeat(5){ move(); }
            turnLeft(); repeat(3){ move(); } turnRight(); repeat(4){ move(); }
            """)
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 81 going straight up misses the gems and goal")
    func challenge81NaiveFails() throws {
        let c = try challenge(81)
        let program = try Parser.parse("repeat(8){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 82 — Blizzard Run (superHard)

    @Test("challenge 82 (Blizzard Run) canonical solution spirals through two ice slides to collect 8 gems and reach goal")
    func challenge82Solution() throws {
        let c = try challenge(82)
        #expect(c.title == "Blizzard Run")
        // Verified trace from (0,0)↑, ice at (16,3) and (18,12):
        //   up×5: (0,5)[gem1]  [(0,6) blocked]
        //   turnRight → →
        //   right×6: (6,5)[gem2]
        //   turnLeft → ↑
        //   up×6: (6,11)[gem3]
        //   turnRight → →
        //   right×7: (13,11)[gem4]  [(14,11) blocked]
        //   turnRight → ↓
        //   down×8: (13,3)[gem5]
        //   turnLeft → →
        //   right×3: (14,3)(15,3)(16,3)[ice]→slide(17,3)[gem6]
        //   turnLeft → ↑
        //   up×9: (17,12)[gem7]  [(17,13) blocked]
        //   turnRight → →
        //   move: (18,12)[ice]→slide(19,12)[gem8] = GOAL
        // blockCount = 8×2 + 7 = 22 ≤ 25; parMoves = 5+6+6+7+8+3+9+1=45
        let program = try Parser.parse("""
            repeat(5){ move(); } turnRight(); repeat(6){ move(); } turnLeft();
            repeat(6){ move(); } turnRight(); repeat(7){ move(); } turnRight();
            repeat(8){ move(); } turnLeft(); repeat(3){ move(); } turnLeft();
            repeat(9){ move(); } turnRight(); move();
            """)
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 82 going straight up hits the col-0 obstacle")
    func challenge82NaiveFails() throws {
        let c = try challenge(82)
        let program = try Parser.parse("repeat(7){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
        #expect(result.outcome == .failure(.hitWall(at: Position(x: 0, y: 6))))
    }

    // MARK: Challenge 83 — Quick Frost (easy)

    @Test("challenge 83 (Quick Frost) two moves slide Vex to crystal and goal")
    func challenge83Solution() throws {
        let c = try challenge(83)
        #expect(c.title == "Quick Frost")
        // Verified trace from (0,0)→, ice at (2,0):
        //   right×2: (1,0)(2,0)[ice]→slide(3,0)[gem1] = GOAL
        // blockCount = 2 ≤ 3; parMoves = 2
        let program = try Parser.parse("repeat(2){ move(); }")
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 83 moving only once fails to reach goal")
    func challenge83NaiveFails() throws {
        let c = try challenge(83)
        let program = try Parser.parse("move();")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 84 — Drift and Dash (easy)

    @Test("challenge 84 (Drift and Dash) three moves hit ice then two more reach goal")
    func challenge84Solution() throws {
        let c = try challenge(84)
        #expect(c.title == "Drift and Dash")
        // Verified trace from (0,0)→, ice at (3,0):
        //   right×3: (1,0)(2,0)(3,0)[ice]→slide(4,0)[gem1]
        //   move: (5,0)
        //   move: (6,0) = GOAL
        // blockCount = 2+1+1 = 4 ≤ 5; parMoves = 5
        let program = try Parser.parse("repeat(3){ move(); } move(); move();")
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 84 moving only three times lands on gem but not the goal")
    func challenge84NaiveFails() throws {
        let c = try challenge(84)
        let program = try Parser.parse("repeat(3){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }

    // MARK: Challenge 85 — Ice Lane Gems (hard)

    @Test("challenge 85 (Ice Lane Gems) canonical solution collects all three gems via two ice slides and reaches goal")
    func challenge85Solution() throws {
        let c = try challenge(85)
        #expect(c.title == "Ice Lane Gems")
        // Verified trace from (0,0)↑, ice at (0,5) and (9,7):
        //   up×5: (0,1)...(0,5)[ice]→slide(0,6)[gem1]
        //   turnRight → →
        //   right×8: (1,6)...(8,6)[gem2]
        //   turnLeft → ↑
        //   move: (8,7)
        //   turnRight → →
        //   move: (9,7)[ice]→slide(10,7)[gem3] = GOAL
        // blockCount = 2+1+2+1+1+1+1 = 9 ≤ 12; parMoves = 5+8+1+1=15
        let program = try Parser.parse("repeat(5){ move(); } turnRight(); repeat(8){ move(); } turnLeft(); move(); turnRight(); move();")
        #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(result.isSuccess)
        #expect(result.frames.last?.position == c.challenge.goal)
        #expect(result.itemsCollected.count >= (c.challenge.collectGoal ?? 0))
    }

    @Test("challenge 85 going straight up misses the gems and goal")
    func challenge85NaiveFails() throws {
        let c = try challenge(85)
        let program = try Parser.parse("repeat(8){ move(); }")
        let result = Simulator().run(program: program, challenge: c.challenge)
        #expect(!result.isSuccess)
    }
}
