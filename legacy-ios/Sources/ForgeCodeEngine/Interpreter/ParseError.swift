/// A kid-friendly parse failure with a source location.
///
/// Never surface raw compiler jargon: `message` is written for an
/// 8–15 year old and points at the first problem.
public struct ParseError: Error, Hashable, Sendable {
    public enum Kind: Hashable, Sendable {
        case missingSemicolon
        case unmatchedBrace
        case unknownCommand(String)
        case repeatMissingNumber
        case repeatCountOutOfRange(Int)
        case unexpectedCharacter(Character)
        case unexpectedEnd
        case expectedToken(String)
    }

    public let kind: Kind
    /// 1-based line of the problem.
    public let line: Int
    /// 1-based column of the problem.
    public let column: Int

    public init(kind: Kind, line: Int, column: Int) {
        self.kind = kind
        self.line = line
        self.column = column
    }

    /// An encouraging, actionable explanation for a young coder.
    public var message: String {
        switch kind {
        case .missingSemicolon:
            return "Looks like you forgot a semicolon `;` at the end of line \(line)."
        case .unmatchedBrace:
            return "This brace on line \(line) doesn't have a matching partner. Check your `{` and `}`."
        case let .unknownCommand(name):
            return "I don't recognize `\(name)()`. Try `move()`, `turnLeft()`, or `turnRight()`."
        case .repeatMissingNumber:
            return "`repeat` needs a number, like `repeat(3) { ... }`."
        case let .repeatCountOutOfRange(value):
            return "`repeat(\(value))` is out of range. Use a whole number from 1 to 100."
        case let .unexpectedCharacter(character):
            return "I got confused by `\(character)` on line \(line). Check your typing there."
        case .unexpectedEnd:
            return "Your code ended sooner than I expected. Did you leave something unfinished?"
        case let .expectedToken(what):
            return "I expected \(what) on line \(line), but found something else."
        }
    }
}
