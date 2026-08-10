import Testing
@testable import ForgeCodeEngine

@Suite("RLexer — tokenisation")
struct RLexerTests {

    private func tokenize(_ source: String) throws -> [RToken] {
        var lexer = RLexer(source)
        return try lexer.tokenize()
    }

    private func kinds(_ source: String) throws -> [RToken.Kind] {
        try tokenize(source).map { $0.kind }
    }

    // MARK: - Literals

    @Test("Integers become number tokens")
    func integerLiteral() throws {
        let ks = try kinds("42")
        #expect(ks == [.number(42), .endOfFile])
    }

    @Test("Decimal number is parsed correctly")
    func decimalLiteral() throws {
        let ks = try kinds("3.14")
        #expect(ks == [.number(3.14), .endOfFile])
    }

    @Test("String literal is tokenized without quotes")
    func stringLiteral() throws {
        let ks = try kinds("\"hello\"")
        #expect(ks == [.string("hello"), .endOfFile])
    }

    @Test("true and false become keyword tokens")
    func boolLiterals() throws {
        #expect(try kinds("true")  == [.kwTrue, .endOfFile])
        #expect(try kinds("false") == [.kwFalse, .endOfFile])
    }

    // MARK: - Identifiers vs keywords

    @Test("Identifiers remain as identifier tokens")
    func identifierToken() throws {
        let ks = try kinds("myVar")
        #expect(ks == [.identifier("myVar"), .endOfFile])
    }

    @Test("Keywords are correctly classified")
    func keywords() throws {
        let pairs: [(String, RToken.Kind)] = [
            ("var",    .kwVar),
            ("if",     .kwIf),
            ("else",   .kwElse),
            ("while",  .kwWhile),
            ("for",    .kwFor),
            ("repeat", .kwRepeat),
            ("func",   .kwFunc),
            ("return", .kwReturn),
        ]
        for (text, expected) in pairs {
            let ks = try kinds(text)
            #expect(ks.first == expected, "'\(text)' should lex as \(expected)")
        }
    }

    // MARK: - Operators

    @Test("Two-character operators are correctly tokenized")
    func twoCharOps() throws {
        let cases: [(String, RToken.Kind)] = [
            ("==", .equalEqual), ("!=", .bangEqual),
            ("<=", .lessEqual),  (">=", .greaterEqual),
            ("&&", .ampAmp),     ("||", .pipePipe)
        ]
        for (text, expected) in cases {
            let ks = try kinds(text)
            #expect(ks.first == expected)
        }
    }

    @Test("Single-character operators are tokenized correctly")
    func singleCharOps() throws {
        let ks = try kinds("+ - * / % = < > !")
        let expected: [RToken.Kind] = [
            .plus, .minus, .star, .slash, .percent, .equal, .less, .greater, .bang, .endOfFile
        ]
        #expect(ks == expected)
    }

    // MARK: - Punctuation

    @Test("Punctuation tokens are produced")
    func punctuation() throws {
        let ks = try kinds("( ) { } ; , .")
        let expected: [RToken.Kind] = [
            .leftParen, .rightParen, .leftBrace, .rightBrace,
            .semicolon, .comma, .dot, .endOfFile
        ]
        #expect(ks == expected)
    }

    // MARK: - Comments and whitespace

    @Test("Line comments are skipped")
    func lineComments() throws {
        let ks = try kinds("42 // this is a comment\n99")
        #expect(ks == [.number(42), .number(99), .endOfFile])
    }

    @Test("Whitespace and newlines are skipped")
    func whitespace() throws {
        let ks = try kinds("  \t\n  42  \n  ")
        #expect(ks == [.number(42), .endOfFile])
    }

    // MARK: - Line/column tracking

    @Test("Line numbers are tracked correctly across newlines")
    func lineTracking() throws {
        let tokens = try tokenize("var\nx")
        #expect(tokens[0].line == 1)
        #expect(tokens[1].line == 2)
    }

    // MARK: - Errors

    @Test("Unterminated string throws RParseError")
    func unterminatedString() {
        #expect(throws: RParseError.self) {
            var lexer = RLexer("\"unterminated")
            _ = try lexer.tokenize()
        }
    }

    @Test("Unexpected character throws RParseError")
    func unexpectedCharacter() {
        #expect(throws: RParseError.self) {
            var lexer = RLexer("@")
            _ = try lexer.tokenize()
        }
    }

    @Test("Single ampersand throws (not &&)")
    func singleAmpersand() {
        #expect(throws: RParseError.self) {
            var lexer = RLexer("&")
            _ = try lexer.tokenize()
        }
    }

    // MARK: - Complex source

    @Test("A typical robot program tokenizes without error")
    func complexSource() throws {
        let source = """
        var x = 10;
        if (distance() < 20) {
            drive.forward(x);
        }
        """
        let tokens = try tokenize(source)
        #expect(!tokens.isEmpty)
        #expect(tokens.last?.kind == .endOfFile)
    }
}
