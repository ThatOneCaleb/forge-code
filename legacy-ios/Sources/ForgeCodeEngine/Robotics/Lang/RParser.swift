/// Recursive-descent parser for the robotics mini-language.
///
/// Produces an `RProgram` (a list of `RStmt` nodes containing `RExpr` nodes).
/// One AST shared by both the text front-end and the (future) block editor.
/// No Foundation dependency.
///
/// Precedence (low → high):
///   OR  →  AND  →  Equality  →  Comparison  →  Addition  →
///   Multiplication  →  Unary  →  Call/Member  →  Primary
public struct RParser {

    private let tokens: [RToken]
    private var pos: Int = 0

    // MARK: - Entry point

    public init(_ source: String) throws {
        var lexer = RLexer(source)
        self.tokens = try lexer.tokenize()
    }

    /// Parse the entire source into an `RProgram`.
    public static func parse(_ source: String) throws -> RProgram {
        var p = try RParser(source)
        return try p.parseProgram()
    }

    // MARK: - Cursor

    private var current: RToken { tokens[pos] }
    private var isAtEnd: Bool {
        if case .endOfFile = current.kind { return true }
        return false
    }

    @discardableResult
    private mutating func advance() -> RToken {
        let t = tokens[pos]
        if pos < tokens.count - 1 { pos += 1 }
        return t
    }

    private func peek(_ offset: Int = 0) -> RToken {
        let i = pos + offset
        guard i < tokens.count else { return tokens[tokens.count - 1] }
        return tokens[i]
    }

    private mutating func check(_ kind: RToken.Kind) -> Bool { current.kind == kind }

    @discardableResult
    private mutating func consume(_ kind: RToken.Kind, expected: String) throws -> RToken {
        guard current.kind == kind else {
            throw RParseError(kind: .expectedToken(expected), line: current.line, column: current.column)
        }
        return advance()
    }

    // MARK: - Program

    private mutating func parseProgram() throws -> RProgram {
        var stmts: [RStmt] = []
        while !isAtEnd {
            if case .rightBrace = current.kind {
                throw RParseError(kind: .unmatchedBrace, line: current.line, column: current.column)
            }
            stmts.append(try parseStatement())
        }
        return RProgram(statements: stmts)
    }

    // MARK: - Statements

    private mutating func parseStatement() throws -> RStmt {
        let t = current
        switch t.kind {
        case .kwVar:    return try parseVarDecl()
        case .kwIf:     return try parseIf()
        case .kwWhile:  return try parseWhile()
        case .kwFor:    return try parseFor()
        case .kwRepeat: return try parseRepeat()
        case .kwFunc:   return try parseFuncDef()
        case .kwReturn: return try parseReturn()
        case .leftBrace:
            let stmts = try parseBlock()
            return .block(stmts)
        default:
            return try parseExprOrAssignStmt()
        }
    }

    /// `var name = expr ;`
    private mutating func parseVarDecl() throws -> RStmt {
        let t = advance() // consume 'var'
        guard case let .identifier(name) = current.kind else {
            throw RParseError(kind: .expectedToken("a variable name after `var`"),
                              line: current.line, column: current.column)
        }
        _ = advance()
        try consume(.equal, expected: "`=` after variable name")
        let init_ = try parseExpr()
        try expectSemicolon()
        return .varDecl(name: name, initializer: init_, line: t.line, column: t.column)
    }

    /// `if (cond) { then } [else { else }]`
    private mutating func parseIf() throws -> RStmt {
        let t = advance() // consume 'if'
        try consume(.leftParen, expected: "`(` after `if`")
        let cond = try parseExpr()
        try consume(.rightParen, expected: "`)` to close the `if` condition")
        let thenB = try parseBlock()
        var elseB: [RStmt]? = nil
        if case .kwElse = current.kind {
            advance()
            if case .kwIf = current.kind {
                elseB = [try parseIf()]
            } else {
                elseB = try parseBlock()
            }
        }
        return .ifStmt(condition: cond, thenBranch: thenB, elseBranch: elseB,
                       line: t.line, column: t.column)
    }

    /// `while (cond) { body }`
    private mutating func parseWhile() throws -> RStmt {
        let t = advance() // consume 'while'
        try consume(.leftParen, expected: "`(` after `while`")
        let cond = try parseExpr()
        try consume(.rightParen, expected: "`)` to close the `while` condition")
        let body = try parseBlock()
        return .whileStmt(condition: cond, body: body, line: t.line, column: t.column)
    }

    /// `for (var i = 0; i < n; i = i + 1) { body }`
    private mutating func parseFor() throws -> RStmt {
        let t = advance() // consume 'for'
        try consume(.leftParen, expected: "`(` after `for`")

        // Init: must be a var decl (without trailing semi consumed yet — we handle it inside)
        let initStmt = try parseVarDeclNoSemi()
        try consume(.semicolon, expected: "`;` after the initializer in `for`")

        let cond = try parseExpr()
        try consume(.semicolon, expected: "`;` after the condition in `for`")

        let step = try parseAssignNoSemi()
        try consume(.rightParen, expected: "`)` to close the `for` header")

        let body = try parseBlock()
        return .forStmt(initStmt: initStmt, condition: cond, stepStmt: step, body: body,
                        line: t.line, column: t.column)
    }

    /// `repeat (expr) { body }`
    private mutating func parseRepeat() throws -> RStmt {
        let t = advance() // consume 'repeat'
        try consume(.leftParen, expected: "`(` after `repeat`")
        let countTok = current
        let count = try parseExpr()
        // If the count is a literal number we can catch non-positive values at parse time.
        if case let .literal(.number(n)) = count, n <= 0 {
            throw RParseError(kind: .repeatRequiresPositiveNumber,
                              line: countTok.line, column: countTok.column)
        }
        try consume(.rightParen, expected: "`)` after the repeat count")
        let body = try parseBlock()
        return .repeatStmt(count: count, body: body, line: t.line, column: t.column)
    }

    /// `func name(param, ...) { body }`
    private mutating func parseFuncDef() throws -> RStmt {
        let t = advance() // consume 'func'
        guard case let .identifier(name) = current.kind else {
            throw RParseError(kind: .expectedToken("a function name after `func`"),
                              line: current.line, column: current.column)
        }
        advance()
        try consume(.leftParen, expected: "`(` after function name")
        var params: [String] = []
        if current.kind != .rightParen {
            repeat {
                if case .comma = current.kind { advance() }
                guard case let .identifier(p) = current.kind else {
                    throw RParseError(kind: .expectedToken("a parameter name"),
                                      line: current.line, column: current.column)
                }
                params.append(p)
                advance()
            } while current.kind == .comma
        }
        try consume(.rightParen, expected: "`)` after parameter list")
        let body = try parseBlock()
        return .funcDef(name: name, params: params, body: body, line: t.line, column: t.column)
    }

    /// `return [expr] ;`
    private mutating func parseReturn() throws -> RStmt {
        let t = advance() // consume 'return'
        var value: RExpr? = nil
        if current.kind != .semicolon {
            value = try parseExpr()
        }
        try expectSemicolon()
        return .returnStmt(value: value, line: t.line, column: t.column)
    }

    /// An expression statement or an assignment: `expr ;`  /  `name = expr ;`
    private mutating func parseExprOrAssignStmt() throws -> RStmt {
        let t = current
        let expr = try parseExpr()
        // If followed by `=` it's an assignment (only simple var names allowed as LHS)
        if case .equal = current.kind {
            advance() // consume '='
            guard case let .variable(name, vLine, vCol) = expr else {
                throw RParseError(kind: .invalidAssignmentTarget, line: t.line, column: t.column)
            }
            let rhs = try parseExpr()
            try expectSemicolon()
            return .assign(name: name, value: rhs, line: vLine, column: vCol)
        }
        try expectSemicolon()
        return .exprStmt(expr: expr, line: t.line, column: t.column)
    }

    // MARK: - Helper: var decl without consuming the trailing semicolon

    private mutating func parseVarDeclNoSemi() throws -> RStmt {
        let t = advance() // consume 'var'
        guard case let .identifier(name) = current.kind else {
            throw RParseError(kind: .expectedToken("a variable name after `var`"),
                              line: current.line, column: current.column)
        }
        _ = advance()
        try consume(.equal, expected: "`=` after variable name")
        let init_ = try parseExpr()
        return .varDecl(name: name, initializer: init_, line: t.line, column: t.column)
    }

    /// Parse `name = expr` (for the step clause of a for loop) without semicolon.
    private mutating func parseAssignNoSemi() throws -> RStmt {
        let t = current
        guard case let .identifier(name) = current.kind else {
            throw RParseError(kind: .expectedToken("a variable name for the step"),
                              line: current.line, column: current.column)
        }
        advance()
        try consume(.equal, expected: "`=` in the step of `for`")
        let rhs = try parseExpr()
        return .assign(name: name, value: rhs, line: t.line, column: t.column)
    }

    // MARK: - Block

    private mutating func parseBlock() throws -> [RStmt] {
        let open = try consume(.leftBrace, expected: "`{` to open a block")
        var stmts: [RStmt] = []
        while !isAtEnd {
            if case .rightBrace = current.kind {
                advance()
                return stmts
            }
            stmts.append(try parseStatement())
        }
        throw RParseError(kind: .unmatchedBrace, line: open.line, column: open.column)
    }

    // MARK: - Expression precedence climbing

    private mutating func parseExpr() throws -> RExpr {
        try parseOr()
    }

    private mutating func parseOr() throws -> RExpr {
        var left = try parseAnd()
        while case .pipePipe = current.kind {
            let t = advance()
            let right = try parseAnd()
            left = .binary(left: left, op: .or, right: right, line: t.line, column: t.column)
        }
        return left
    }

    private mutating func parseAnd() throws -> RExpr {
        var left = try parseEquality()
        while case .ampAmp = current.kind {
            let t = advance()
            let right = try parseEquality()
            left = .binary(left: left, op: .and, right: right, line: t.line, column: t.column)
        }
        return left
    }

    private mutating func parseEquality() throws -> RExpr {
        var left = try parseComparison()
        while true {
            let t = current
            let op: RBinaryOp
            switch t.kind {
            case .equalEqual: op = .equalEqual
            case .bangEqual:  op = .bangEqual
            default: return left
            }
            advance()
            let right = try parseComparison()
            left = .binary(left: left, op: op, right: right, line: t.line, column: t.column)
        }
    }

    private mutating func parseComparison() throws -> RExpr {
        var left = try parseAddition()
        while true {
            let t = current
            let op: RBinaryOp
            switch t.kind {
            case .less:         op = .less
            case .lessEqual:    op = .lessEqual
            case .greater:      op = .greater
            case .greaterEqual: op = .greaterEqual
            default: return left
            }
            advance()
            let right = try parseAddition()
            left = .binary(left: left, op: op, right: right, line: t.line, column: t.column)
        }
    }

    private mutating func parseAddition() throws -> RExpr {
        var left = try parseMultiplication()
        while true {
            let t = current
            let op: RBinaryOp
            switch t.kind {
            case .plus:  op = .add
            case .minus: op = .subtract
            default: return left
            }
            advance()
            let right = try parseMultiplication()
            left = .binary(left: left, op: op, right: right, line: t.line, column: t.column)
        }
    }

    private mutating func parseMultiplication() throws -> RExpr {
        var left = try parseUnary()
        while true {
            let t = current
            let op: RBinaryOp
            switch t.kind {
            case .star:    op = .multiply
            case .slash:   op = .divide
            case .percent: op = .modulo
            default: return left
            }
            advance()
            let right = try parseUnary()
            left = .binary(left: left, op: op, right: right, line: t.line, column: t.column)
        }
    }

    private mutating func parseUnary() throws -> RExpr {
        let t = current
        switch t.kind {
        case .bang:
            advance()
            let operand = try parseUnary()
            return .unary(op: .not, operand: operand, line: t.line, column: t.column)
        case .minus:
            advance()
            let operand = try parseUnary()
            return .unary(op: .negate, operand: operand, line: t.line, column: t.column)
        default:
            return try parseCallMember()
        }
    }

    /// Handles: primary [ `.` identifier `(` args `)` ]*
    /// and free-function calls: identifier `(` args `)`.
    private mutating func parseCallMember() throws -> RExpr {
        var expr = try parsePrimary()
        // Handle member access chains: expr.method(args)
        while case .dot = current.kind {
            advance() // consume '.'
            guard case let .identifier(member) = current.kind else {
                throw RParseError(kind: .expectedToken("a method name after `.`"),
                                  line: current.line, column: current.column)
            }
            let memberTok = advance()
            // Must be a call
            try consume(.leftParen, expected: "`(` after `\(member)` — member accesses must be calls")
            let args = try parseArgList()
            try consume(.rightParen, expected: "`)` to close the argument list")

            // Unwrap the object name from the expression
            guard case let .variable(objName, _, _) = expr else {
                throw RParseError(kind: .unexpectedToken("chained member calls are not supported"),
                                  line: memberTok.line, column: memberTok.column)
            }
            expr = .memberCall(object: objName, method: member, args: args,
                               line: memberTok.line, column: memberTok.column)
        }
        return expr
    }

    private mutating func parsePrimary() throws -> RExpr {
        let t = current
        switch t.kind {
        case let .number(n):
            advance()
            return .literal(.number(n))
        case let .string(s):
            advance()
            return .literal(.string(s))
        case .kwTrue:
            advance()
            return .literal(.bool(true))
        case .kwFalse:
            advance()
            return .literal(.bool(false))
        case let .identifier(name):
            advance()
            // Check if this is a function call
            if case .leftParen = current.kind {
                advance() // consume '('
                let args = try parseArgList()
                try consume(.rightParen, expected: "`)` to close the argument list for `\(name)`")
                return .call(name: name, args: args, line: t.line, column: t.column)
            }
            return .variable(name: name, line: t.line, column: t.column)
        case .leftParen:
            advance() // consume '('
            let inner = try parseExpr()
            try consume(.rightParen, expected: "`)` to close the parentheses")
            return inner
        case .endOfFile:
            throw RParseError(kind: .unexpectedEnd, line: t.line, column: t.column)
        default:
            throw RParseError(kind: .unexpectedToken(tokenDescription(t)),
                              line: t.line, column: t.column)
        }
    }

    /// Parse a comma-separated argument list (up to but not including the closing `)`).
    private mutating func parseArgList() throws -> [RExpr] {
        var args: [RExpr] = []
        if current.kind == .rightParen { return args }
        args.append(try parseExpr())
        while case .comma = current.kind {
            advance()
            args.append(try parseExpr())
        }
        return args
    }

    // MARK: - Terminals

    private mutating func expectSemicolon() throws {
        guard case .semicolon = current.kind else {
            let prev = pos > 0 ? tokens[pos - 1] : tokens[0]
            throw RParseError(kind: .missingSemicolon, line: prev.line, column: prev.column)
        }
        advance()
    }

    private func tokenDescription(_ t: RToken) -> String {
        switch t.kind {
        case let .identifier(s): return s
        case let .number(n):     return String(n)
        case let .string(s):     return "\"\(s)\""
        case .kwVar:    return "var"
        case .kwIf:     return "if"
        case .kwElse:   return "else"
        case .kwWhile:  return "while"
        case .kwFor:    return "for"
        case .kwRepeat: return "repeat"
        case .kwFunc:   return "func"
        case .kwReturn: return "return"
        case .kwTrue:   return "true"
        case .kwFalse:  return "false"
        case .plus:     return "+"
        case .minus:    return "-"
        case .star:     return "*"
        case .slash:    return "/"
        case .percent:  return "%"
        case .equal:    return "="
        case .equalEqual: return "=="
        case .bangEqual:  return "!="
        case .less:       return "<"
        case .lessEqual:  return "<="
        case .greater:    return ">"
        case .greaterEqual: return ">="
        case .ampAmp:   return "&&"
        case .pipePipe: return "||"
        case .bang:     return "!"
        case .leftParen:  return "("
        case .rightParen: return ")"
        case .leftBrace:  return "{"
        case .rightBrace: return "}"
        case .semicolon:  return ";"
        case .comma:      return ","
        case .dot:        return "."
        case .endOfFile:  return "<end of file>"
        }
    }
}
