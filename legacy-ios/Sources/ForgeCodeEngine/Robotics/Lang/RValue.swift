/// The runtime value type for the robotics mini-language.
///
/// Dynamically typed: a value is a number, bool, string, or void (the
/// non-value returned by statements). No Foundation dependency.
public enum RValue: Equatable, Sendable {
    case number(Double)
    case bool(Bool)
    case string(String)
    case void

    // MARK: - Convenience coercions (interpreter uses these)

    /// Returns the numeric value, or nil if not a number.
    public var asNumber: Double? {
        if case let .number(n) = self { return n }
        return nil
    }

    /// Returns the boolean value, or nil if not a bool.
    public var asBool: Bool? {
        if case let .bool(b) = self { return b }
        return nil
    }

    /// Returns the string value, or nil if not a string.
    public var asString: String? {
        if case let .string(s) = self { return s }
        return nil
    }

    /// Truthiness: numbers are truthy when non-zero; strings when non-empty;
    /// bools directly; void is always falsy.
    public var isTruthy: Bool {
        switch self {
        case let .number(n): return n != 0
        case let .bool(b):   return b
        case let .string(s): return !s.isEmpty
        case .void:          return false
        }
    }

    /// A user-visible description for `print(x)`.
    public var displayString: String {
        switch self {
        case let .number(n):
            // Show integers without decimals; show a decimal only when needed.
            if n == n.rounded() && !n.isInfinite {
                return String(Int(n))
            }
            return String(n)
        case let .bool(b):   return b ? "true" : "false"
        case let .string(s): return s
        case .void:          return ""
        }
    }
}
