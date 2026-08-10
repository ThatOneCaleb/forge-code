/// Recursive-descent parser for the fixed Forge Code grammar. Produces the
/// same `Program`/`Command` AST as the block editor. Standard library only.
///
/// Grammar (exactly this — do not extend):
/// ```
/// program    := statement*
/// statement  := leaf | repeatStmt | ifStmt
/// leaf       := ("move" | "turnLeft" | "turnRight") "(" ")" ";"
/// repeatStmt := "repeat" "(" NUMBER ")" "{" statement* "}"
/// ifStmt     := "if" "(" "wallAhead" "(" ")" ")" "{" statement* "}"
/// ```
public struct Parser {
    /// Inclusive clamp range for a `repeat` count.
    static let repeatRange = 1...100

    private let tokens: [Token]
    private var position: Int = 0

    public init(_ source: String) throws {
        var lexer = Lexer(source)
        self.tokens = try lexer.tokenize()
    }

    /// Parse the source into a `Program`, throwing a friendly `ParseError`
    /// at the first problem.
    public static func parse(_ source: String) throws -> Program {
        var parser = try Parser(source)
        return try parser.parseProgram()
    }

    // MARK: - Token cursor

    private var current: Token { tokens[position] }

    private func isAtEnd() -> Bool {
        if case .endOfFile = current.kind { return true }
        return false
    }

    private mutating func advance() -> Token {
        let token = tokens[position]
        if position < tokens.count - 1 { position += 1 }
        return token
    }

    // MARK: - Grammar

    private mutating func parseProgram() throws -> Program {
        var commands: [Command] = []
        while !isAtEnd() {
            // A stray closing brace at top level has no opener.
            if case .rightBrace = current.kind {
                throw ParseError(kind: .unmatchedBrace, line: current.line, column: current.column)
            }
            commands.append(try parseStatement())
        }
        return Program(commands: commands)
    }

    private mutating func parseStatement() throws -> Command {
        guard case let .identifier(name) = current.kind else {
            if isAtEnd() {
                throw ParseError(kind: .unexpectedEnd, line: current.line, column: current.column)
            }
            throw ParseError(
                kind: .unexpectedCharacter(firstCharacter(of: current)),
                line: current.line,
                column: current.column
            )
        }

        switch name {
        case "move":
            return try parseLeaf(name: name, command: .move)
        case "turnLeft":
            return try parseLeaf(name: name, command: .turnLeft)
        case "turnRight":
            return try parseLeaf(name: name, command: .turnRight)
        case "repeat":
            return try parseRepeat()
        case "if":
            return try parseIf()
        default:
            throw ParseError(kind: .unknownCommand(name), line: current.line, column: current.column)
        }
    }

    /// `<name> "(" ")" ";"`
    private mutating func parseLeaf(name: String, command: Command) throws -> Command {
        _ = advance() // identifier
        try expectLeftParen()
        try expectRightParen()
        try expectSemicolon()
        return command
    }

    /// `"repeat" "(" NUMBER ")" "{" statement* "}"`
    private mutating func parseRepeat() throws -> Command {
        _ = advance() // repeat
        try expectLeftParen()

        guard case let .number(raw) = current.kind else {
            throw ParseError(kind: .repeatMissingNumber, line: current.line, column: current.column)
        }
        let numberToken = advance()
        guard Parser.repeatRange.contains(raw) else {
            throw ParseError(
                kind: .repeatCountOutOfRange(raw),
                line: numberToken.line,
                column: numberToken.column
            )
        }

        try expectRightParen()
        let body = try parseBlock()
        return .repeatBlock(count: raw, body: body)
    }

    /// `"if" "(" "wallAhead" "(" ")" ")" "{" statement* "}"`
    private mutating func parseIf() throws -> Command {
        _ = advance() // if
        try expectLeftParen()

        guard case let .identifier(cond) = current.kind, cond == "wallAhead" else {
            if case let .identifier(other) = current.kind {
                throw ParseError(kind: .unknownCommand(other), line: current.line, column: current.column)
            }
            throw ParseError(
                kind: .expectedToken("`wallAhead()`"),
                line: current.line,
                column: current.column
            )
        }
        _ = advance() // wallAhead
        try expectLeftParen()
        try expectRightParen()
        try expectRightParen()

        let body = try parseBlock()
        return .ifWallAhead(body: body)
    }

    /// `"{" statement* "}"`
    private mutating func parseBlock() throws -> [Command] {
        guard case .leftBrace = current.kind else {
            throw ParseError(
                kind: .expectedToken("a `{` to open a block"),
                line: current.line,
                column: current.column
            )
        }
        let openBrace = advance()

        var body: [Command] = []
        while true {
            if case .rightBrace = current.kind {
                _ = advance()
                return body
            }
            if isAtEnd() {
                // Opened a block that never closes.
                throw ParseError(kind: .unmatchedBrace, line: openBrace.line, column: openBrace.column)
            }
            body.append(try parseStatement())
        }
    }

    // MARK: - Terminals

    private mutating func expectLeftParen() throws {
        guard case .leftParen = current.kind else {
            throw ParseError(kind: .expectedToken("a `(`"), line: current.line, column: current.column)
        }
        _ = advance()
    }

    private mutating func expectRightParen() throws {
        guard case .rightParen = current.kind else {
            throw ParseError(kind: .expectedToken("a `)`"), line: current.line, column: current.column)
        }
        _ = advance()
    }

    private mutating func expectSemicolon() throws {
        guard case .semicolon = current.kind else {
            // Report at the end of the previous token's line — that's where
            // the kid expected to type `;`.
            let prev = tokens[max(0, position - 1)]
            throw ParseError(kind: .missingSemicolon, line: prev.line, column: prev.column)
        }
        _ = advance()
    }

    /// Best-effort character to name in an "unexpected" error.
    private func firstCharacter(of token: Token) -> Character {
        switch token.kind {
        case .leftParen: return "("
        case .rightParen: return ")"
        case .leftBrace: return "{"
        case .rightBrace: return "}"
        case .semicolon: return ";"
        case let .number(n): return "\(n)".first ?? "?"
        case let .identifier(s): return s.first ?? "?"
        case .endOfFile: return " "
        }
    }
}
