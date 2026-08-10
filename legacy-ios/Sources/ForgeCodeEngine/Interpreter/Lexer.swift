/// Turns source text into a stream of `Token`s using only the standard
/// library (no Foundation). Tracks line/column for friendly errors.
struct Lexer {
    private let scalars: [Character]
    private var index: Int = 0
    private var line: Int = 1
    private var column: Int = 1

    init(_ source: String) {
        self.scalars = Array(source)
    }

    private var isAtEnd: Bool { index >= scalars.count }

    private func peek() -> Character? {
        isAtEnd ? nil : scalars[index]
    }

    private mutating func advance() -> Character {
        let c = scalars[index]
        index += 1
        if c == "\n" {
            line += 1
            column = 1
        } else {
            column += 1
        }
        return c
    }

    /// Tokenize the whole source, terminating with `.endOfFile`.
    mutating func tokenize() throws -> [Token] {
        var tokens: [Token] = []
        while true {
            skipWhitespace()
            let startLine = line
            let startColumn = column
            guard let c = peek() else {
                tokens.append(Token(kind: .endOfFile, line: startLine, column: startColumn))
                return tokens
            }

            switch c {
            case "(":
                _ = advance()
                tokens.append(Token(kind: .leftParen, line: startLine, column: startColumn))
            case ")":
                _ = advance()
                tokens.append(Token(kind: .rightParen, line: startLine, column: startColumn))
            case "{":
                _ = advance()
                tokens.append(Token(kind: .leftBrace, line: startLine, column: startColumn))
            case "}":
                _ = advance()
                tokens.append(Token(kind: .rightBrace, line: startLine, column: startColumn))
            case ";":
                _ = advance()
                tokens.append(Token(kind: .semicolon, line: startLine, column: startColumn))
            default:
                if c.isNumber {
                    tokens.append(lexNumber(line: startLine, column: startColumn))
                } else if c.isLetter || c == "_" {
                    tokens.append(lexIdentifier(line: startLine, column: startColumn))
                } else {
                    throw ParseError(kind: .unexpectedCharacter(c), line: startLine, column: startColumn)
                }
            }
        }
    }

    private mutating func skipWhitespace() {
        while let c = peek(), c == " " || c == "\t" || c == "\n" || c == "\r" {
            _ = advance()
        }
    }

    private mutating func lexNumber(line: Int, column: Int) -> Token {
        var digits = ""
        while let c = peek(), c.isNumber {
            digits.append(advance())
        }
        // `digits` is non-empty and all ASCII digits by construction.
        let value = Int(digits) ?? Int.max
        return Token(kind: .number(value), line: line, column: column)
    }

    private mutating func lexIdentifier(line: Int, column: Int) -> Token {
        var name = ""
        while let c = peek(), c.isLetter || c.isNumber || c == "_" {
            name.append(advance())
        }
        return Token(kind: .identifier(name), line: line, column: column)
    }
}
