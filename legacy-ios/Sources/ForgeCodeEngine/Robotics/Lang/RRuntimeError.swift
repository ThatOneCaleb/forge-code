/// A teen-friendly runtime failure from the robotics interpreter.
///
/// Includes a source location when available, and a message written for a
/// young programmer — never punishing, always actionable.
public struct RRuntimeError: Error, Equatable, Hashable, Sendable {

    public enum Kind: Equatable, Hashable, Sendable {
        case undefinedVariable(String)
        case undefinedFunction(String)
        case typeMismatch(expected: String, got: String)
        case divisionByZero
        case stepBudgetExceeded(limit: Int)
        case actionBudgetExceeded(limit: Int)
        case returnOutsideFunction
        case wrongArgumentCount(funcName: String, expected: Int, got: Int)
        case notCallable(String)
        case undefinedMember(object: String, member: String)
        case custom(String)
    }

    public let kind: Kind
    /// 1-based line of the call site (nil when not tracked).
    public let line: Int?
    /// 1-based column of the call site (nil when not tracked).
    public let column: Int?

    public init(kind: Kind, line: Int? = nil, column: Int? = nil) {
        self.kind   = kind
        self.line   = line
        self.column = column
    }

    /// An encouraging, actionable explanation for a young coder.
    public var message: String {
        let loc = line.map { " (line \($0))" } ?? ""
        switch kind {
        case let .undefinedVariable(name):
            return "I don't know what `\(name)` is\(loc). Did you declare it with `var`?"
        case let .undefinedFunction(name):
            return "I don't recognise the function `\(name)`\(loc). Check your spelling."
        case let .typeMismatch(expected, got):
            return "I expected \(expected) here\(loc), but got \(got) instead."
        case .divisionByZero:
            return "Whoops — you divided by zero\(loc). The denominator can't be zero."
        case let .stepBudgetExceeded(limit):
            return "Your program ran for \(limit) steps and still wasn't done — is a loop never finishing?"
        case let .actionBudgetExceeded(limit):
            return "Your robot performed \(limit) actions. Try breaking the task into smaller steps."
        case .returnOutsideFunction:
            return "`return` can only be used inside a function\(loc)."
        case let .wrongArgumentCount(name, expected, got):
            return "The function `\(name)` needs \(expected) argument(s), but you gave it \(got)\(loc)."
        case let .notCallable(name):
            return "`\(name)` is not a function\(loc)."
        case let .undefinedMember(object, member):
            return "I don't recognise `\(object).\(member)`\(loc). Check the robot API reference."
        case let .custom(msg):
            return msg + loc
        }
    }
}
