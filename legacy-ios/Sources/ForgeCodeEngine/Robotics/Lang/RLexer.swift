/// Tokenizes robotics mini-language source text into `[RToken]`.
///
/// Handles: identifiers/keywords, decimal number literals, double-quoted
/// string literals, all operators (including two-character ones), punctuation,
/// and `//` line comments. No Foundation dependency.
public struct RLexer: Sendable {
    private let chars: [Character]
    private var index: Int = 0
    private var line: Int = 1
    private var column: Int = 1

    public init(_ source: String) {
        self.chars = Array(source)
    }

    private var isAtEnd: Bool { index >= chars.count }

    private func peek(_ offset: Int = 0) -> Character? {
        let i = index + offset
        guard i < chars.count else { return nil }
        return chars[i]
    }

    @discardableResult
    private mutating func advance() -> Character {
        let c = chars[index]
        index += 1
        if c == "\n" { line += 1; column = 1 } else { column += 1 }
        return c
    }

    private mutating func match(_ expected: Character) -> Bool {
        guard peek() == expected else { return false }
        advance()
        return true
    }

    // MARK: - Public entry point

    /// Tokenize the entire source. Throws `RParseError` on unexpected input.
    public mutating func tokenize() throws -> [RToken] {
        var tokens: [RToken] = []
        while true {
            skipWhitespaceAndComments()
            guard !isAtEnd else {
                tokens.append(RToken(kind: .endOfFile, line: line, column: column))
                return tokens
            }
            let startLine = line
            let startCol  = column
            let c = advance()

            switch c {
            // Single-character punctuation
            case "(": tokens.append(tok(.leftParen,  startLine, startCol))
            case ")": tokens.append(tok(.rightParen, startLine, startCol))
            case "{": tokens.append(tok(.leftBrace,  startLine, startCol))
            case "}": tokens.append(tok(.rightBrace, startLine, startCol))
            case ";": tokens.append(tok(.semicolon,  startLine, startCol))
            case ",": tokens.append(tok(.comma,      startLine, startCol))
            case ".": tokens.append(tok(.dot,        startLine, startCol))
            case "+": tokens.append(tok(.plus,       startLine, startCol))
            case "-": tokens.append(tok(.minus,      startLine, startCol))
            case "*": tokens.append(tok(.star,       startLine, startCol))
            case "/": tokens.append(tok(.slash,      startLine, startCol))
            case "%": tokens.append(tok(.percent,    startLine, startCol))

            // One-or-two character operators
            case "=":
                tokens.append(tok(match("=") ? .equalEqual : .equal, startLine, startCol))
            case "!":
                tokens.append(tok(match("=") ? .bangEqual  : .bang,  startLine, startCol))
            case "<":
                tokens.append(tok(match("=") ? .lessEqual  : .less,  startLine, startCol))
            case ">":
                tokens.append(tok(match("=") ? .greaterEqual : .greater, startLine, startCol))
            case "&":
                guard match("&") else {
                    throw RParseError(kind: .unexpectedCharacter(c), line: startLine, column: startCol)
                }
                tokens.append(tok(.ampAmp, startLine, startCol))
            case "|":
                guard match("|") else {
                    throw RParseError(kind: .unexpectedCharacter(c), line: startLine, column: startCol)
                }
                tokens.append(tok(.pipePipe, startLine, startCol))

            // String literal
            case "\"":
                tokens.append(try lexString(startLine: startLine, startCol: startCol))

            default:
                if c.isWholeNumber {
                    tokens.append(lexNumber(c, startLine: startLine, startCol: startCol))
                } else if c.isLetter || c == "_" {
                    tokens.append(lexIdentifier(c, startLine: startLine, startCol: startCol))
                } else {
                    throw RParseError(kind: .unexpectedCharacter(c), line: startLine, column: startCol)
                }
            }
        }
    }

    // MARK: - Helpers

    private func tok(_ kind: RToken.Kind, _ line: Int, _ col: Int) -> RToken {
        RToken(kind: kind, line: line, column: col)
    }

    private mutating func skipWhitespaceAndComments() {
        while let c = peek() {
            if c == " " || c == "\t" || c == "\r" || c == "\n" {
                advance()
            } else if c == "/" && peek(1) == "/" {
                // Line comment: consume until newline
                while let ch = peek(), ch != "\n" { advance() }
            } else {
                break
            }
        }
    }

    private mutating func lexNumber(_ first: Character, startLine: Int, startCol: Int) -> RToken {
        var text = String(first)
        while let c = peek(), c.isWholeNumber { text.append(advance()) }
        if peek() == ".", let next = peek(1), next.isWholeNumber {
            text.append(advance()) // consume "."
            while let c = peek(), c.isWholeNumber { text.append(advance()) }
        }
        let value = Double(text) ?? 0
        return RToken(kind: .number(value), line: startLine, column: startCol)
    }

    private mutating func lexString(startLine: Int, startCol: Int) throws -> RToken {
        var text = ""
        while let c = peek(), c != "\"" {
            if c == "\n" || isAtEnd {
                throw RParseError(kind: .unterminatedString, line: startLine, column: startCol)
            }
            text.append(advance())
        }
        if isAtEnd {
            throw RParseError(kind: .unterminatedString, line: startLine, column: startCol)
        }
        advance() // closing "
        return RToken(kind: .string(text), line: startLine, column: startCol)
    }

    private mutating func lexIdentifier(_ first: Character, startLine: Int, startCol: Int) -> RToken {
        var text = String(first)
        while let c = peek(), c.isLetter || c.isWholeNumber || c == "_" {
            text.append(advance())
        }
        let kind: RToken.Kind = keyword(text) ?? .identifier(text)
        return RToken(kind: kind, line: startLine, column: startCol)
    }

    private func keyword(_ text: String) -> RToken.Kind? {
        switch text {
        case "var":    return .kwVar
        case "if":     return .kwIf
        case "else":   return .kwElse
        case "while":  return .kwWhile
        case "for":    return .kwFor
        case "repeat": return .kwRepeat
        case "func":   return .kwFunc
        case "return": return .kwReturn
        case "true":   return .kwTrue
        case "false":  return .kwFalse
        default:       return nil
        }
    }
}
