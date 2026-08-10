import Testing
@testable import ForgeCodeEngine

@Suite("Parser — valid grammar")
struct ParserValidTests {

    @Test("each leaf command parses to its AST node")
    func leaves() throws {
        #expect(try Parser.parse("move();").commands == [.move])
        #expect(try Parser.parse("turnLeft();").commands == [.turnLeft])
        #expect(try Parser.parse("turnRight();").commands == [.turnRight])
    }

    @Test("a sequence parses in order")
    func sequence() throws {
        let program = try Parser.parse("turnRight(); move(); move();")
        #expect(program.commands == [.turnRight, .move, .move])
    }

    @Test("repeat parses count and body")
    func repeatBlock() throws {
        let program = try Parser.parse("repeat(3) { move(); turnRight(); }")
        #expect(program.commands == [.repeatBlock(count: 3, body: [.move, .turnRight])])
    }

    @Test("if(wallAhead()) parses its body")
    func ifWall() throws {
        let program = try Parser.parse("if (wallAhead()) { turnLeft(); }")
        #expect(program.commands == [.ifWallAhead(body: [.turnLeft])])
    }

    @Test("nested blocks parse")
    func nested() throws {
        let source = """
        repeat(2) {
            if (wallAhead()) {
                turnRight();
            }
            move();
        }
        """
        let program = try Parser.parse(source)
        #expect(program.commands == [
            .repeatBlock(count: 2, body: [
                .ifWallAhead(body: [.turnRight]),
                .move
            ])
        ])
    }

    @Test("whitespace and newlines are insignificant")
    func whitespace() throws {
        let a = try Parser.parse("move();move();")
        let b = try Parser.parse("  move( ) ;\n\n  move ( ) ;  ")
        #expect(a == b)
    }

    @Test("repeat count is clamped-valid at the range edges 1 and 100")
    func repeatEdges() throws {
        #expect(try Parser.parse("repeat(1){ move(); }").commands
                == [.repeatBlock(count: 1, body: [.move])])
        #expect(try Parser.parse("repeat(100){ move(); }").commands
                == [.repeatBlock(count: 100, body: [.move])])
    }
}

@Suite("Parser — friendly errors")
struct ParserErrorTests {

    private func expectError(_ source: String, _ predicate: (ParseError) -> Bool) {
        do {
            _ = try Parser.parse(source)
            Issue.record("Expected a ParseError but parsing succeeded.")
        } catch let error as ParseError {
            #expect(predicate(error), "Unexpected error kind: \(error.kind) — \(error.message)")
        } catch {
            Issue.record("Expected a ParseError, got \(error).")
        }
    }

    @Test("missing semicolon")
    func missingSemicolon() {
        expectError("move()\nmove();") { error in
            if case .missingSemicolon = error.kind { return error.line == 1 }
            return false
        }
    }

    @Test("unmatched opening brace")
    func unmatchedOpenBrace() {
        expectError("repeat(2) { move();") { error in
            if case .unmatchedBrace = error.kind { return true }
            return false
        }
    }

    @Test("unmatched closing brace at top level")
    func unmatchedCloseBrace() {
        expectError("move(); }") { error in
            if case .unmatchedBrace = error.kind { return true }
            return false
        }
    }

    @Test("unknown command")
    func unknownCommand() {
        expectError("jump();") { error in
            if case let .unknownCommand(name) = error.kind {
                return name == "jump" && error.line == 1
            }
            return false
        }
    }

    @Test("repeat without a number")
    func repeatMissingNumber() {
        expectError("repeat() { move(); }") { error in
            if case .repeatMissingNumber = error.kind { return true }
            return false
        }
    }

    @Test("repeat count out of range")
    func repeatOutOfRange() {
        expectError("repeat(0) { move(); }") { error in
            if case let .repeatCountOutOfRange(value) = error.kind { return value == 0 }
            return false
        }
        expectError("repeat(101) { move(); }") { error in
            if case let .repeatCountOutOfRange(value) = error.kind { return value == 101 }
            return false
        }
    }

    @Test("unexpected character")
    func unexpectedCharacter() {
        expectError("move(); @") { error in
            if case let .unexpectedCharacter(c) = error.kind { return c == "@" }
            return false
        }
    }

    @Test("expected token — a block must open with a brace")
    func expectedOpeningBrace() {
        expectError("repeat(3) move();") { error in
            if case .expectedToken = error.kind { return true }
            return false
        }
    }

    @Test("expected token — if only accepts wallAhead() as its condition")
    func ifConditionMustBeWallAhead() {
        expectError("if (5) { move(); }") { error in
            if case .expectedToken = error.kind { return true }
            return false
        }
    }

    @Test("error location is reported")
    func errorLocation() {
        expectError("move();\nmove();\njump();") { error in
            error.line == 3
        }
    }
}
