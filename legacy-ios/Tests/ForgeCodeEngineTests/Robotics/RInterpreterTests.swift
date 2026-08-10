import Testing
@testable import ForgeCodeEngine

/// Tests for the robotics mini-language interpreter (no robot/world needed).
/// Uses a test helper that collects print() output so tests can assert on it.
@Suite("RInterpreter — language semantics")
struct RInterpreterTests {

    // MARK: - Helpers

    /// Run source and collect all print() calls. Returns the list of printed strings.
    private func runCollectPrints(_ source: String, stepBudget: Int = 50_000) throws -> [String] {
        var printed: [String] = []
        var api = RobotAPIBindings()
        api.print_ = { val in
            printed.append(val.displayString)
            return .void
        }
        var interp = RInterpreter(stepBudget: stepBudget, api: api)
        try interp.run(source: source)
        return printed
    }

    // MARK: - Variables and arithmetic

    @Test("Variable declaration and read-back")
    func varDeclAndRead() throws {
        let out = try runCollectPrints("var x = 7; print(x);")
        #expect(out == ["7"])
    }

    @Test("Arithmetic with correct precedence (2 + 3 * 4 = 14)")
    func arithmetic() throws {
        let out = try runCollectPrints("var r = 2 + 3 * 4; print(r);")
        #expect(out == ["14"])
    }

    @Test("Unary negation")
    func unaryNeg() throws {
        let out = try runCollectPrints("var r = -5; print(r);")
        #expect(out == ["-5"])
    }

    @Test("String concatenation with +")
    func stringConcat() throws {
        let out = try runCollectPrints(#"var s = "hello" + " world"; print(s);"#)
        #expect(out == ["hello world"])
    }

    @Test("Modulo operator")
    func modulo() throws {
        let out = try runCollectPrints("var r = 10 % 3; print(r);")
        #expect(out == ["1"])
    }

    @Test("Division by zero throws RRuntimeError")
    func divisionByZero() {
        #expect(throws: RRuntimeError.self) {
            _ = try runCollectPrints("var r = 1 / 0;")
        }
    }

    // MARK: - Boolean logic

    @Test("Logical && — both true")
    func logicalAnd() throws {
        let out = try runCollectPrints("var r = true && true; print(r);")
        #expect(out == ["true"])
    }

    @Test("Logical && short-circuits on false")
    func logicalAndShortCircuit() throws {
        let out = try runCollectPrints("var r = false && true; print(r);")
        #expect(out == ["false"])
    }

    @Test("Logical || — one true is enough")
    func logicalOr() throws {
        let out = try runCollectPrints("var r = false || true; print(r);")
        #expect(out == ["true"])
    }

    @Test("Logical not flips bool")
    func logicalNot() throws {
        let out = try runCollectPrints("var r = !false; print(r);")
        #expect(out == ["true"])
    }

    // MARK: - Scoping

    @Test("Inner scope can read outer variable")
    func scopeRead() throws {
        let out = try runCollectPrints("""
        var x = 10;
        if (true) { print(x); }
        """)
        #expect(out == ["10"])
    }

    @Test("Variable declared in inner scope not visible outside")
    func scopeIsolation() {
        #expect(throws: RRuntimeError.self) {
            _ = try runCollectPrints("""
            if (true) { var inner = 5; }
            print(inner);
            """)
        }
    }

    @Test("Assignment modifies the outer binding")
    func scopeAssign() throws {
        let out = try runCollectPrints("""
        var x = 1;
        if (true) { x = 99; }
        print(x);
        """)
        #expect(out == ["99"])
    }

    // MARK: - if / else

    @Test("if branch taken when condition is true")
    func ifTrue() throws {
        let out = try runCollectPrints("""
        if (1 < 2) { print("yes"); } else { print("no"); }
        """)
        #expect(out == ["yes"])
    }

    @Test("else branch taken when condition is false")
    func ifFalse() throws {
        let out = try runCollectPrints("""
        if (1 > 2) { print("yes"); } else { print("no"); }
        """)
        #expect(out == ["no"])
    }

    // MARK: - while loop

    @Test("while loop runs body until condition false")
    func whileLoop() throws {
        let out = try runCollectPrints("""
        var i = 0;
        while (i < 3) { print(i); i = i + 1; }
        """)
        #expect(out == ["0", "1", "2"])
    }

    @Test("while loop body skipped when condition starts false")
    func whileSkipped() throws {
        let out = try runCollectPrints("""
        var i = 10;
        while (i < 3) { print("never"); }
        print("done");
        """)
        #expect(out == ["done"])
    }

    // MARK: - for loop

    @Test("for loop runs exactly n iterations")
    func forLoop() throws {
        let out = try runCollectPrints("""
        for (var i = 0; i < 4; i = i + 1) { print(i); }
        """)
        #expect(out == ["0", "1", "2", "3"])
    }

    // MARK: - repeat

    @Test("repeat runs body exactly n times")
    func repeatStmt() throws {
        let out = try runCollectPrints("""
        var count = 0;
        repeat (3) { count = count + 1; }
        print(count);
        """)
        #expect(out == ["3"])
    }

    // MARK: - Functions

    @Test("User function is called and returns void by default")
    func funcCallVoid() throws {
        let out = try runCollectPrints("""
        func greet() { print("hello"); }
        greet();
        """)
        #expect(out == ["hello"])
    }

    @Test("User function with parameters and return value")
    func funcWithReturn() throws {
        let out = try runCollectPrints("""
        func add(a, b) { return a + b; }
        var r = add(3, 4);
        print(r);
        """)
        #expect(out == ["7"])
    }

    @Test("Recursive function (factorial)")
    func recursion() throws {
        let out = try runCollectPrints("""
        func fact(n) {
            if (n <= 1) { return 1; }
            return n * fact(n - 1);
        }
        print(fact(5));
        """)
        #expect(out == ["120"])
    }

    @Test("Function captures its definition scope (closure)")
    func closure() throws {
        let out = try runCollectPrints("""
        var x = 10;
        func getX() { return x; }
        x = 20;
        print(getX());
        """)
        // x is in the global scope; getX looks up the chain → sees updated value
        #expect(out == ["20"])
    }

    @Test("Calling undefined function throws RRuntimeError")
    func undefinedFunction() {
        #expect(throws: RRuntimeError.self) {
            _ = try runCollectPrints("noSuchFunction();")
        }
    }

    @Test("Wrong argument count throws RRuntimeError")
    func wrongArgCount() {
        #expect(throws: RRuntimeError.self) {
            _ = try runCollectPrints("""
            func f(a) { return a; }
            f(1, 2);
            """)
        }
    }

    // MARK: - Budget

    @Test("Step budget stops a runaway loop and throws RRuntimeError")
    func stepBudget() {
        let err = #expect(throws: RRuntimeError.self) {
            _ = try runCollectPrints("while (true) { var x = 1; }", stepBudget: 100)
        }
        if let err = err {
            if case .stepBudgetExceeded = err.kind { /* expected */ } else {
                Issue.record("Expected stepBudgetExceeded, got: \(err.kind)")
            }
        }
    }

    @Test("Step budget error message is teen-friendly")
    func stepBudgetMessage() {
        do {
            _ = try runCollectPrints("while (true) { var x = 1; }", stepBudget: 50)
        } catch let err as RRuntimeError {
            #expect(err.message.lowercased().contains("steps") ||
                    err.message.lowercased().contains("loop"))
        } catch {
            Issue.record("Expected RRuntimeError")
        }
    }

    // MARK: - Runtime errors (friendly messages)

    @Test("Undefined variable error is teen-friendly")
    func undefinedVarMessage() {
        do {
            _ = try runCollectPrints("print(undeclaredVar);")
        } catch let err as RRuntimeError {
            #expect(!err.message.isEmpty)
            #expect(err.message.lowercased().contains("var") ||
                    err.message.lowercased().contains("declare") ||
                    err.message.lowercased().contains("recognis"))
        } catch {
            Issue.record("Expected RRuntimeError")
        }
    }
}
