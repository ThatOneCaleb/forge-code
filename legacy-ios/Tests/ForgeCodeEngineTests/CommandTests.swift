import Testing
@testable import ForgeCodeEngine

@Suite("Command & Program counting")
struct CommandTests {

    @Test("leaf commands count as one node")
    func leafNodeCount() {
        #expect(Command.move.nodeCount == 1)
        #expect(Command.turnLeft.nodeCount == 1)
        #expect(Command.turnRight.nodeCount == 1)
    }

    @Test("repeat/if count themselves plus their body")
    func blockNodeCount() {
        // repeat node (1) + two moves (2) = 3
        #expect(Command.repeatBlock(count: 3, body: [.move, .move]).nodeCount == 3)
        // if node (1) + one turn (1) = 2
        #expect(Command.ifWallAhead(body: [.turnRight]).nodeCount == 2)
    }

    @Test("blockCount sums the whole program recursively")
    func programBlockCount() {
        let program = Program(commands: [
            .move,                                              // 1
            .repeatBlock(count: 2, body: [                      // 1
                .move,                                          // 1
                .ifWallAhead(body: [.turnLeft])                 // 1 + 1
            ])
        ])
        #expect(program.blockCount == 5)
    }

    @Test("CommandKind raw values match the JSON vocabulary")
    func commandKindRaws() {
        #expect(CommandKind.move.rawValue == "move")
        #expect(CommandKind.turnLeft.rawValue == "turnLeft")
        #expect(CommandKind.turnRight.rawValue == "turnRight")
        #expect(CommandKind.repeatBlock.rawValue == "repeat")
        #expect(CommandKind.ifWallAhead.rawValue == "if")
    }

    @Test("command kind maps back from the AST node")
    func kindMapping() {
        #expect(Command.repeatBlock(count: 1, body: []).kind == .repeatBlock)
        #expect(Command.ifWallAhead(body: []).kind == .ifWallAhead)
    }
}
