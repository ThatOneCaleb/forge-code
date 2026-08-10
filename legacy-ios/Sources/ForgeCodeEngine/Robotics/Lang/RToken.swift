/// A lexical token from the robotics mini-language source.
/// Tagged with a source location for friendly error messages.
public struct RToken: Equatable, Sendable {

    // MARK: - Kind

    public enum Kind: Equatable, Sendable {
        // Literals
        case number(Double)
        case string(String)

        // Identifiers & keywords
        case identifier(String)
        case kwVar
        case kwIf
        case kwElse
        case kwWhile
        case kwFor
        case kwRepeat
        case kwFunc
        case kwReturn
        case kwTrue
        case kwFalse

        // Operators
        case plus          // +
        case minus         // -
        case star          // *
        case slash         // /
        case percent       // %
        case equalEqual    // ==
        case bangEqual     // !=
        case less          // <
        case lessEqual     // <=
        case greater       // >
        case greaterEqual  // >=
        case ampAmp        // &&
        case pipePipe      // ||
        case bang          // !
        case equal         // =

        // Punctuation
        case leftParen     // (
        case rightParen    // )
        case leftBrace     // {
        case rightBrace    // }
        case semicolon     // ;
        case comma         // ,
        case dot           // .

        case endOfFile
    }

    public let kind: Kind
    /// 1-based line where the token begins.
    public let line: Int
    /// 1-based column where the token begins.
    public let column: Int

    public init(kind: Kind, line: Int, column: Int) {
        self.kind = kind
        self.line = line
        self.column = column
    }
}
