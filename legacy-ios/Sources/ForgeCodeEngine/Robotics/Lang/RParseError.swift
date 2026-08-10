/// A teen-friendly parse failure with a source location.
///
/// Never surface raw compiler jargon — messages are written for an 8–15 year
/// old and point at the first problem encountered.
public struct RParseError: Error, Equatable, Hashable, Sendable {

    public enum Kind: Equatable, Hashable, Sendable {
        case unexpectedCharacter(Character)
        case unterminatedString
        case unexpectedToken(String)   // description of what was found
        case expectedToken(String)     // description of what was expected
        case unknownVariable(String)
        case invalidAssignmentTarget
        case missingCondition
        case missingSemicolon
        case unmatchedBrace
        case repeatRequiresPositiveNumber
        case tooManyArguments(funcName: String, expected: Int, got: Int)
        case unexpectedEnd
    }

    public let kind: Kind
    /// 1-based line of the problem.
    public let line: Int
    /// 1-based column of the problem.
    public let column: Int

    public init(kind: Kind, line: Int, column: Int) {
        self.kind   = kind
        self.line   = line
        self.column = column
    }

    /// An encouraging, actionable explanation for a young coder.
    public var message: String {
        switch kind {
        case let .unexpectedCharacter(c):
            return "I got confused by `\(c)` on line \(line). Check your typing there."
        case .unterminatedString:
            return "I found a string that never closes on line \(line). Add a `\"` at the end."
        case let .unexpectedToken(what):
            return "I didn't expect `\(what)` here on line \(line). Check the code just before it."
        case let .expectedToken(what):
            return "I expected \(what) on line \(line), but found something else."
        case let .unknownVariable(name):
            return "I don't recognise the name `\(name)` on line \(line). Did you declare it with `var`?"
        case .invalidAssignmentTarget:
            return "You can only assign a value to a variable, not to an expression (line \(line))."
        case .missingCondition:
            return "I expected a condition inside `(...)` on line \(line). Something like `distance() < 20`."
        case .missingSemicolon:
            return "Looks like you forgot a semicolon `;` at the end of line \(line)."
        case .unmatchedBrace:
            return "This brace on line \(line) doesn't have a matching partner. Check your `{` and `}`."
        case .repeatRequiresPositiveNumber:
            return "`repeat` needs a positive number, like `repeat(4) { ... }` (line \(line))."
        case let .tooManyArguments(name, expected, got):
            return "The function `\(name)` takes \(expected) argument(s), but you gave it \(got) (line \(line))."
        case .unexpectedEnd:
            return "Your code ended sooner than I expected on line \(line). Did you leave something unfinished?"
        }
    }
}
