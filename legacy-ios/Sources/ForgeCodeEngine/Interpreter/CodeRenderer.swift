/// Renders a `Program` back into clean, 4-space-indented text that the
/// parser round-trips: `parse(render(p)) == p` for any valid `p`.
public struct CodeRenderer {
    private static let indentUnit = "    " // 4 spaces

    public init() {}

    public func render(_ program: Program) -> String {
        var lines: [String] = []
        renderCommands(program.commands, depth: 0, into: &lines)
        return lines.joined(separator: "\n")
    }

    /// Convenience static entry point.
    public static func render(_ program: Program) -> String {
        CodeRenderer().render(program)
    }

    private func renderCommands(_ commands: [Command], depth: Int, into lines: inout [String]) {
        let indent = String(repeating: Self.indentUnit, count: depth)
        for command in commands {
            switch command {
            case .move:
                lines.append("\(indent)move();")
            case .turnLeft:
                lines.append("\(indent)turnLeft();")
            case .turnRight:
                lines.append("\(indent)turnRight();")
            case let .repeatBlock(count, body):
                lines.append("\(indent)repeat(\(count)) {")
                renderCommands(body, depth: depth + 1, into: &lines)
                lines.append("\(indent)}")
            case let .ifWallAhead(body):
                lines.append("\(indent)if (wallAhead()) {")
                renderCommands(body, depth: depth + 1, into: &lines)
                lines.append("\(indent)}")
            }
        }
    }
}
