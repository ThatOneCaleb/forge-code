import Testing
@testable import ForgeCodeEngine

@Suite("CodeRenderer & round-trip")
struct CodeRendererTests {

    @Test("leaf commands render one per line with semicolons")
    func leaves() {
        let program = Program(commands: [.turnRight, .move, .move])
        #expect(CodeRenderer.render(program) == "turnRight();\nmove();\nmove();")
    }

    @Test("repeat renders with 4-space indentation")
    func repeatIndent() {
        let program = Program(commands: [.repeatBlock(count: 3, body: [.move])])
        let expected = """
        repeat(3) {
            move();
        }
        """
        #expect(CodeRenderer.render(program) == expected)
    }

    @Test("nested blocks indent progressively")
    func nested() {
        let program = Program(commands: [
            .repeatBlock(count: 2, body: [
                .ifWallAhead(body: [.turnLeft]),
                .move
            ])
        ])
        let expected = """
        repeat(2) {
            if (wallAhead()) {
                turnLeft();
            }
            move();
        }
        """
        #expect(CodeRenderer.render(program) == expected)
    }

    // MARK: - Round-trip invariant

    private let samples: [Program] = [
        Program(commands: [.move]),
        Program(commands: [.turnRight, .move, .move]),
        Program(commands: [.repeatBlock(count: 5, body: [.move])]),
        Program(commands: [.ifWallAhead(body: [.turnLeft]), .move]),
        Program(commands: [
            .move, .move, .turnRight,
            .repeatBlock(count: 3, body: [.move]),
            .ifWallAhead(body: [.turnLeft]),
            .move
        ]),
        Program(commands: [
            .repeatBlock(count: 4, body: [
                .ifWallAhead(body: [.turnLeft]),
                .move
            ])
        ])
    ]

    @Test("parse(render(program)) == program for representative programs")
    func roundTrip() throws {
        for program in samples {
            let text = CodeRenderer.render(program)
            let reparsed = try Parser.parse(text)
            #expect(reparsed == program, "Round-trip failed for:\n\(text)")
        }
    }
}
