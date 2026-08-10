/// The shared AST node for both the block editor and the text parser.
///
/// `repeat`/`if` nest child commands, so this is an `indirect enum`.
public indirect enum Command: Hashable, Sendable {
    case move
    case turnLeft
    case turnRight
    case repeatBlock(count: Int, body: [Command])
    case ifWallAhead(body: [Command])

    /// The kind of this command, ignoring any nested body or count.
    public var kind: CommandKind {
        switch self {
        case .move: return .move
        case .turnLeft: return .turnLeft
        case .turnRight: return .turnRight
        case .repeatBlock: return .repeatBlock
        case .ifWallAhead: return .ifWallAhead
        }
    }

    /// Total node count for this command: itself plus its whole subtree.
    public var nodeCount: Int {
        switch self {
        case .move, .turnLeft, .turnRight:
            return 1
        case let .repeatBlock(_, body):
            return 1 + body.reduce(0) { $0 + $1.nodeCount }
        case let .ifWallAhead(body):
            return 1 + body.reduce(0) { $0 + $1.nodeCount }
        }
    }
}

/// The vocabulary of command kinds, used for `allowedCommands` sets.
public enum CommandKind: String, Codable, Hashable, Sendable, CaseIterable {
    case move = "move"
    case turnLeft = "turnLeft"
    case turnRight = "turnRight"
    case repeatBlock = "repeat"
    case ifWallAhead = "if"
}

/// A whole program: a top-level command list plus a derived block count.
public struct Program: Hashable, Sendable {
    public var commands: [Command]

    public init(commands: [Command]) {
        self.commands = commands
    }

    /// Total recursive node count across every command, including the
    /// `repeat`/`if` nodes themselves and everything in their bodies.
    public var blockCount: Int {
        commands.reduce(0) { $0 + $1.nodeCount }
    }
}
