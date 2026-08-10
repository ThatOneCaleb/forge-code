/// AST node types for the robotics mini-language.
///
/// One AST shared by the text parser and (later) the block editor.
/// The interpreter walks these nodes directly — there is one execution path.

// MARK: - Expressions

/// An expression that produces an `RValue` when evaluated.
public indirect enum RExpr: Sendable {
    /// A literal number, bool, or string: `42`, `true`, `"hello"`.
    case literal(RValue)

    /// A variable read: `count`.
    case variable(name: String, line: Int, column: Int)

    /// Binary operation: `a + b`, `x < 10`, `p && q`.
    case binary(left: RExpr, op: RBinaryOp, right: RExpr, line: Int, column: Int)

    /// Unary operation: `-x`, `!flag`.
    case unary(op: RUnaryOp, operand: RExpr, line: Int, column: Int)

    /// Free-function call: `distance()`, `print(x)`, `wait(200)`.
    case call(name: String, args: [RExpr], line: Int, column: Int)

    /// Member method call: `drive.forward(30)`, `gripper.isHolding()`.
    case memberCall(object: String, method: String, args: [RExpr], line: Int, column: Int)
}

// MARK: - Binary operators

public enum RBinaryOp: Equatable, Sendable {
    case add, subtract, multiply, divide, modulo
    case equalEqual, bangEqual
    case less, lessEqual, greater, greaterEqual
    case and, or
}

// MARK: - Unary operators

public enum RUnaryOp: Equatable, Sendable {
    case negate  // -
    case not     // !
}

// MARK: - Statements

/// A statement that produces a side effect (or defines structure).
public indirect enum RStmt: Sendable {
    /// Variable declaration: `var x = expr`.
    case varDecl(name: String, initializer: RExpr, line: Int, column: Int)

    /// Assignment to an existing variable: `x = expr`.
    case assign(name: String, value: RExpr, line: Int, column: Int)

    /// `if (cond) { then } else { else }`  (else is optional).
    case ifStmt(condition: RExpr, thenBranch: [RStmt], elseBranch: [RStmt]?, line: Int, column: Int)

    /// `while (cond) { body }`.
    case whileStmt(condition: RExpr, body: [RStmt], line: Int, column: Int)

    /// C-style `for (varDecl; cond; step) { body }`.
    /// `init` is stored as a `varDecl` stmt; `step` is an `assign` stmt.
    case forStmt(
        initStmt: RStmt,
        condition: RExpr,
        stepStmt: RStmt,
        body: [RStmt],
        line: Int, column: Int
    )

    /// `repeat (n) { body }` — beginner-friendly sugar; n must be a positive literal.
    case repeatStmt(count: RExpr, body: [RStmt], line: Int, column: Int)

    /// Function definition: `func square(side) { ... }`.
    case funcDef(name: String, params: [String], body: [RStmt], line: Int, column: Int)

    /// `return expr` or bare `return`.
    case returnStmt(value: RExpr?, line: Int, column: Int)

    /// An expression used as a statement (for its side effects): `drive.forward(30);`.
    case exprStmt(expr: RExpr, line: Int, column: Int)

    /// A block of statements: `{ stmt* }`.  Used internally; the parser
    /// normally inlines these into the containing node.
    case block([RStmt])
}

// MARK: - Program

/// The top-level container: an ordered list of statements.
public struct RProgram: Sendable {
    public let statements: [RStmt]
    public init(statements: [RStmt]) {
        self.statements = statements
    }
}
