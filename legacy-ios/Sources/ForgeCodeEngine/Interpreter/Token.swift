/// A lexical token produced by the `Lexer`, tagged with its source
/// location so the parser can build friendly, located errors.
struct Token: Equatable {
    enum Kind: Equatable {
        case identifier(String)   // move, turnLeft, repeat, if, wallAhead, ...
        case number(Int)          // 3
        case leftParen            // (
        case rightParen           // )
        case leftBrace            // {
        case rightBrace           // }
        case semicolon            // ;
        case endOfFile
    }

    let kind: Kind
    /// 1-based line where the token begins.
    let line: Int
    /// 1-based column where the token begins.
    let column: Int
}
