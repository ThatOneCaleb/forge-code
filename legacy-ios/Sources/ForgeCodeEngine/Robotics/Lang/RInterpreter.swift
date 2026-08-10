/// Tree-walking interpreter for the robotics mini-language.
///
/// Features:
/// - Lexically-scoped environments (parent-chain lookup)
/// - User-defined functions + recursion
/// - A global scope pre-loaded with the robot API bindings
/// - Instruction/step budget (guards runaway loops/infinite recursion)
/// - Deterministic: same program + same API callbacks ⇒ same outputs
///
/// The robot API is injected as closures via `RobotAPIBindings`, keeping
/// the interpreter itself free of any robot-world knowledge.

// MARK: - Environment

/// A single scope frame. Looks up the parent chain on miss.
final class REnvironment {
    private var values: [String: RValue] = [:]
    private let parent: REnvironment?

    init(parent: REnvironment? = nil) {
        self.parent = parent
    }

    func define(_ name: String, value: RValue) {
        values[name] = value
    }

    func get(_ name: String) throws -> RValue {
        if let v = values[name] { return v }
        if let p = parent { return try p.get(name) }
        throw RRuntimeError(kind: .undefinedVariable(name))
    }

    func set(_ name: String, value: RValue) throws {
        if values[name] != nil {
            values[name] = value
            return
        }
        if let p = parent {
            try p.set(name, value: value)
            return
        }
        throw RRuntimeError(kind: .undefinedVariable(name))
    }
}

// MARK: - User-defined function representation

struct RFunction {
    let params: [String]
    let body: [RStmt]
    let closure: REnvironment   // captured lexical scope
}

// MARK: - Robot API bindings

/// All robot API callbacks injected into the interpreter.
/// Each call site matches a free-function name or a `object.method` pair.
/// Return value is `RValue` (or `.void` for side-effect-only calls).
public struct RobotAPIBindings {
    // Free functions
    public var distance:     () throws -> RValue   = { .number(0) }
    public var color:        () throws -> RValue   = { .string("") }
    public var lineLeft:     () throws -> RValue   = { .bool(false) }
    public var lineRight:    () throws -> RValue   = { .bool(false) }
    public var gyro:         () throws -> RValue   = { .number(0) }
    public var limitSwitch:  () throws -> RValue   = { .bool(false) }
    public var wallAhead:    () throws -> RValue   = { .bool(false) }
    public var wait:         (_ ms: Double) throws -> RValue = { _ in .void }
    public var print_:       (_ x: RValue) throws -> RValue  = { _ in .void }

    // drive.*
    public var driveForward:  (_ cm: Double) throws -> RValue = { _ in .void }
    public var driveBackward: (_ cm: Double) throws -> RValue = { _ in .void }
    public var driveTurnLeft: (_ deg: Double) throws -> RValue = { _ in .void }
    public var driveTurnRight:(_ deg: Double) throws -> RValue = { _ in .void }
    public var driveDistance: () throws -> RValue = { .number(0) }
    public var driveHeading:  () throws -> RValue = { .number(0) }

    // arm.*
    public var armMoveTo: (_ deg: Double) throws -> RValue = { _ in .void }
    public var armRaise:  () throws -> RValue = { .void }
    public var armLower:  () throws -> RValue = { .void }
    public var armAngle:  () throws -> RValue = { .number(0) }

    // gripper.*
    public var gripperOpen:      () throws -> RValue = { .void }
    public var gripperClose:     () throws -> RValue = { .void }
    public var gripperIsHolding: () throws -> RValue = { .bool(false) }

    // color.*
    public var colorIsRed:   () throws -> RValue = { .bool(false) }
    public var colorIsBlue:  () throws -> RValue = { .bool(false) }
    public var colorIsGreen: () throws -> RValue = { .bool(false) }

    /// Teleports the robot to the field's home pose, spending 1 precision token
    /// (in a match context). No-args free function: `returnHome()`.
    public var returnHome: () throws -> RValue = { .void }

    public init() {}
}

// MARK: - Return signal (internal control flow)

private struct ReturnSignal: Error {
    let value: RValue
}

// MARK: - Interpreter

public struct RInterpreter {

    /// Maximum interpreter steps before aborting (guards infinite loops).
    public let stepBudget: Int

    private var steps: Int = 0
    private var api: RobotAPIBindings

    public init(stepBudget: Int = 50_000, api: RobotAPIBindings = RobotAPIBindings()) {
        self.stepBudget = stepBudget
        self.api        = api
    }

    // MARK: - Public entry point

    /// Execute an `RProgram`. Returns `.void` on normal completion, or throws
    /// `RRuntimeError` (or `RParseError` if `source` is provided and fails).
    public mutating func execute(_ program: RProgram) throws {
        let global = REnvironment()
        try executeStatements(program.statements, env: global)
    }

    /// Convenience: parse then execute.
    public mutating func run(source: String) throws {
        let program = try RParser.parse(source)
        try execute(program)
    }

    // MARK: - Statement execution

    private mutating func executeStatements(_ stmts: [RStmt], env: REnvironment) throws {
        for stmt in stmts {
            try executeStatement(stmt, env: env)
        }
    }

    private mutating func executeStatement(_ stmt: RStmt, env: REnvironment) throws {
        try tickBudget(line: nil)

        switch stmt {
        case let .varDecl(name, init_, _, _):
            let val = try evalExpr(init_, env: env)
            env.define(name, value: val)

        case let .assign(name, value, line, col):
            let val = try evalExpr(value, env: env)
            do {
                try env.set(name, value: val)
            } catch let err as RRuntimeError {
                throw RRuntimeError(kind: err.kind, line: line, column: col)
            }

        case let .ifStmt(cond, thenB, elseB, _, _):
            let condVal = try evalExpr(cond, env: env)
            if condVal.isTruthy {
                let child = REnvironment(parent: env)
                try executeStatements(thenB, env: child)
            } else if let eb = elseB {
                let child = REnvironment(parent: env)
                try executeStatements(eb, env: child)
            }

        case let .whileStmt(cond, body, _, _):
            while true {
                try tickBudget(line: nil)
                let condVal = try evalExpr(cond, env: env)
                guard condVal.isTruthy else { break }
                let child = REnvironment(parent: env)
                try executeStatements(body, env: child)
            }

        case let .forStmt(initS, cond, stepS, body, _, _):
            let loopEnv = REnvironment(parent: env)
            try executeStatement(initS, env: loopEnv)
            while true {
                try tickBudget(line: nil)
                let condVal = try evalExpr(cond, env: loopEnv)
                guard condVal.isTruthy else { break }
                let child = REnvironment(parent: loopEnv)
                try executeStatements(body, env: child)
                // step runs in loopEnv so it can update the loop var
                try executeStatement(stepS, env: loopEnv)
            }

        case let .repeatStmt(countExpr, body, line, col):
            let countVal = try evalExpr(countExpr, env: env)
            guard let n = countVal.asNumber, n > 0, n == n.rounded() else {
                throw RRuntimeError(kind: .typeMismatch(expected: "positive integer", got: countVal.displayString),
                                    line: line, column: col)
            }
            let iterations = Int(n)
            for _ in 0 ..< iterations {
                try tickBudget(line: nil)
                let child = REnvironment(parent: env)
                try executeStatements(body, env: child)
            }

        case let .funcDef(name, params, body, _, _):
            let fn = RFunction(params: params, body: body, closure: env)
            env.define(name, value: .void)   // placeholder so recursive refs resolve
            // Store as a special opaque value via a class box
            functionTable[name] = fn

        case let .returnStmt(value, _, _):
            let retVal = try value.map { try evalExpr($0, env: env) } ?? .void
            throw ReturnSignal(value: retVal)

        case let .exprStmt(expr, _, _):
            _ = try evalExpr(expr, env: env)

        case let .block(stmts):
            let child = REnvironment(parent: env)
            try executeStatements(stmts, env: child)
        }
    }

    // Function table lives outside the environment (it's a separate namespace
    // so that functions aren't storable as first-class values — keeps the
    // language simple for kids and avoids needing to box closures in RValue).
    private var functionTable: [String: RFunction] = [:]

    // MARK: - Expression evaluation

    private mutating func evalExpr(_ expr: RExpr, env: REnvironment) throws -> RValue {
        switch expr {
        case let .literal(v):
            return v

        case let .variable(name, line, col):
            do {
                return try env.get(name)
            } catch let err as RRuntimeError {
                throw RRuntimeError(kind: err.kind, line: line, column: col)
            }

        case let .binary(left, op, right, line, col):
            // Short-circuit &&/||
            if op == .and {
                let l = try evalExpr(left, env: env)
                if !l.isTruthy { return .bool(false) }
                let r = try evalExpr(right, env: env)
                return .bool(r.isTruthy)
            }
            if op == .or {
                let l = try evalExpr(left, env: env)
                if l.isTruthy { return .bool(true) }
                let r = try evalExpr(right, env: env)
                return .bool(r.isTruthy)
            }
            let lv = try evalExpr(left, env: env)
            let rv = try evalExpr(right, env: env)
            return try applyBinary(op, lv, rv, line: line, col: col)

        case let .unary(op, operand, line, col):
            let val = try evalExpr(operand, env: env)
            switch op {
            case .negate:
                guard let n = val.asNumber else {
                    throw RRuntimeError(kind: .typeMismatch(expected: "number", got: val.displayString),
                                        line: line, column: col)
                }
                return .number(-n)
            case .not:
                return .bool(!val.isTruthy)
            }

        case let .call(name, args, line, col):
            let evaledArgs = try args.map { try evalExpr($0, env: env) }
            return try callFreeFunction(name, args: evaledArgs, line: line, col: col)

        case let .memberCall(object, method, args, line, col):
            let evaledArgs = try args.map { try evalExpr($0, env: env) }
            return try callMember(object: object, method: method, args: evaledArgs,
                                  line: line, col: col)
        }
    }

    // MARK: - Binary operator application

    private func applyBinary(_ op: RBinaryOp, _ lv: RValue, _ rv: RValue,
                              line: Int, col: Int) throws -> RValue {
        switch op {
        case .add:
            // string concatenation OR numeric add
            if case let .string(ls) = lv {
                return .string(ls + rv.displayString)
            }
            if let ln = lv.asNumber, let rn = rv.asNumber { return .number(ln + rn) }
            throw RRuntimeError(kind: .typeMismatch(expected: "two numbers or strings",
                                                    got: "\(lv.displayString) + \(rv.displayString)"),
                                line: line, column: col)
        case .subtract:
            let (ln, rn) = try requireNumbers(lv, rv, op: "-", line: line, col: col)
            return .number(ln - rn)
        case .multiply:
            let (ln, rn) = try requireNumbers(lv, rv, op: "*", line: line, col: col)
            return .number(ln * rn)
        case .divide:
            let (ln, rn) = try requireNumbers(lv, rv, op: "/", line: line, col: col)
            if rn == 0 { throw RRuntimeError(kind: .divisionByZero, line: line, column: col) }
            return .number(ln / rn)
        case .modulo:
            let (ln, rn) = try requireNumbers(lv, rv, op: "%", line: line, col: col)
            if rn == 0 { throw RRuntimeError(kind: .divisionByZero, line: line, column: col) }
            return .number(ln.truncatingRemainder(dividingBy: rn))
        case .equalEqual:
            return .bool(rvalueEqual(lv, rv))
        case .bangEqual:
            return .bool(!rvalueEqual(lv, rv))
        case .less:
            let (ln, rn) = try requireNumbers(lv, rv, op: "<", line: line, col: col)
            return .bool(ln < rn)
        case .lessEqual:
            let (ln, rn) = try requireNumbers(lv, rv, op: "<=", line: line, col: col)
            return .bool(ln <= rn)
        case .greater:
            let (ln, rn) = try requireNumbers(lv, rv, op: ">", line: line, col: col)
            return .bool(ln > rn)
        case .greaterEqual:
            let (ln, rn) = try requireNumbers(lv, rv, op: ">=", line: line, col: col)
            return .bool(ln >= rn)
        case .and, .or:
            // Handled at call site (short-circuit); shouldn't reach here.
            return .bool(lv.isTruthy && rv.isTruthy)
        }
    }

    private func requireNumbers(_ lv: RValue, _ rv: RValue, op: String,
                                 line: Int, col: Int) throws -> (Double, Double) {
        guard let ln = lv.asNumber, let rn = rv.asNumber else {
            throw RRuntimeError(kind: .typeMismatch(expected: "two numbers for `\(op)`",
                                                    got: "\(lv.displayString) and \(rv.displayString)"),
                                line: line, column: col)
        }
        return (ln, rn)
    }

    private func rvalueEqual(_ a: RValue, _ b: RValue) -> Bool {
        switch (a, b) {
        case let (.number(x), .number(y)): return x == y
        case let (.bool(x),   .bool(y)):   return x == y
        case let (.string(x), .string(y)): return x == y
        case (.void, .void):               return true
        default:                           return false
        }
    }

    // MARK: - Budget

    private mutating func tickBudget(line: Int?) throws {
        steps += 1
        if steps > stepBudget {
            throw RRuntimeError(kind: .stepBudgetExceeded(limit: stepBudget), line: line)
        }
    }

    // MARK: - Free function dispatch

    private mutating func callFreeFunction(_ name: String, args: [RValue],
                                           line: Int, col: Int) throws -> RValue {
        switch name {
        case "distance":    return try api.distance()
        case "color":       return try api.color()
        case "lineLeft":    return try api.lineLeft()
        case "lineRight":   return try api.lineRight()
        case "gyro":        return try api.gyro()
        case "limitSwitch": return try api.limitSwitch()
        case "wallAhead":   return try api.wallAhead()

        case "wait":
            let ms = try requireSingleNumber(args, funcName: "wait", line: line, col: col)
            return try api.wait(ms)

        case "print":
            guard args.count == 1 else {
                throw RRuntimeError(kind: .wrongArgumentCount(funcName: "print", expected: 1, got: args.count),
                                    line: line, column: col)
            }
            return try api.print_(args[0])

        case "returnHome":
            try requireNoArgs(args, funcName: "returnHome", line: line, col: col)
            return try api.returnHome()

        default:
            // Look up user-defined function
            if let fn = functionTable[name] {
                return try callUserFunction(fn, name: name, args: args, line: line, col: col)
            }
            throw RRuntimeError(kind: .undefinedFunction(name), line: line, column: col)
        }
    }

    // MARK: - Member function dispatch

    private mutating func callMember(object: String, method: String, args: [RValue],
                                     line: Int, col: Int) throws -> RValue {
        switch (object, method) {
        // drive.*
        case ("drive", "forward"):
            let cm = try requireSingleNumber(args, funcName: "drive.forward", line: line, col: col)
            return try api.driveForward(cm)
        case ("drive", "backward"):
            let cm = try requireSingleNumber(args, funcName: "drive.backward", line: line, col: col)
            return try api.driveBackward(cm)
        case ("drive", "turnLeft"):
            let deg = try requireSingleNumber(args, funcName: "drive.turnLeft", line: line, col: col)
            return try api.driveTurnLeft(deg)
        case ("drive", "turnRight"):
            let deg = try requireSingleNumber(args, funcName: "drive.turnRight", line: line, col: col)
            return try api.driveTurnRight(deg)
        case ("drive", "distance"):
            try requireNoArgs(args, funcName: "drive.distance", line: line, col: col)
            return try api.driveDistance()
        case ("drive", "heading"):
            try requireNoArgs(args, funcName: "drive.heading", line: line, col: col)
            return try api.driveHeading()

        // arm.*
        case ("arm", "moveTo"):
            let deg = try requireSingleNumber(args, funcName: "arm.moveTo", line: line, col: col)
            return try api.armMoveTo(deg)
        case ("arm", "raise"):
            try requireNoArgs(args, funcName: "arm.raise", line: line, col: col)
            return try api.armRaise()
        case ("arm", "lower"):
            try requireNoArgs(args, funcName: "arm.lower", line: line, col: col)
            return try api.armLower()
        case ("arm", "angle"):
            try requireNoArgs(args, funcName: "arm.angle", line: line, col: col)
            return try api.armAngle()

        // gripper.*
        case ("gripper", "open"):
            try requireNoArgs(args, funcName: "gripper.open", line: line, col: col)
            return try api.gripperOpen()
        case ("gripper", "close"):
            try requireNoArgs(args, funcName: "gripper.close", line: line, col: col)
            return try api.gripperClose()
        case ("gripper", "isHolding"):
            try requireNoArgs(args, funcName: "gripper.isHolding", line: line, col: col)
            return try api.gripperIsHolding()

        // color.*
        case ("color", "isRed"):
            try requireNoArgs(args, funcName: "color.isRed", line: line, col: col)
            return try api.colorIsRed()
        case ("color", "isBlue"):
            try requireNoArgs(args, funcName: "color.isBlue", line: line, col: col)
            return try api.colorIsBlue()
        case ("color", "isGreen"):
            try requireNoArgs(args, funcName: "color.isGreen", line: line, col: col)
            return try api.colorIsGreen()

        default:
            throw RRuntimeError(kind: .undefinedMember(object: object, member: method),
                                 line: line, column: col)
        }
    }

    // MARK: - User function call

    private mutating func callUserFunction(_ fn: RFunction, name: String,
                                           args: [RValue], line: Int, col: Int) throws -> RValue {
        guard args.count == fn.params.count else {
            throw RRuntimeError(kind: .wrongArgumentCount(funcName: name,
                                                          expected: fn.params.count,
                                                          got: args.count),
                                line: line, column: col)
        }
        let callEnv = REnvironment(parent: fn.closure)
        for (param, arg) in zip(fn.params, args) {
            callEnv.define(param, value: arg)
        }
        do {
            try executeStatements(fn.body, env: callEnv)
        } catch let ret as ReturnSignal {
            return ret.value
        }
        return .void
    }

    // MARK: - Argument helpers

    private func requireSingleNumber(_ args: [RValue], funcName: String,
                                     line: Int, col: Int) throws -> Double {
        guard args.count == 1 else {
            throw RRuntimeError(kind: .wrongArgumentCount(funcName: funcName, expected: 1, got: args.count),
                                line: line, column: col)
        }
        guard let n = args[0].asNumber else {
            throw RRuntimeError(kind: .typeMismatch(expected: "number", got: args[0].displayString),
                                line: line, column: col)
        }
        return n
    }

    private func requireNoArgs(_ args: [RValue], funcName: String,
                               line: Int, col: Int) throws {
        guard args.isEmpty else {
            throw RRuntimeError(kind: .wrongArgumentCount(funcName: funcName, expected: 0, got: args.count),
                                line: line, column: col)
        }
    }
}
