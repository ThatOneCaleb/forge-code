import SwiftUI
import ForgeCodeEngine

/// Whether the mission editor is showing drag-in blocks or raw code text.
enum RoboticsEditorMode: Equatable {
    case blocks
    case text
}

// MARK: - Robotics block model
//
// A UI-side block tree for the robotics tier. It serialises to the robotics
// mini-language *text* (which the existing parser/interpreter already runs), so
// blocks and text share one execution path — no engine changes required.

/// Comparison operators available on the distance sensor hexagon.
enum RCompareOp: String, CaseIterable, Hashable {
    case less, lessEqual, greater, greaterEqual

    var symbol: String {
        switch self {
        case .less: return "<"
        case .lessEqual: return "≤"
        case .greater: return ">"
        case .greaterEqual: return "≥"
        }
    }
    var code: String {
        switch self {
        case .less: return "<"
        case .lessEqual: return "<="
        case .greater: return ">"
        case .greaterEqual: return ">="
        }
    }
}

/// Colours the colour sensor can test for.
enum RSenseColor: String, CaseIterable, Hashable {
    case red, blue, green
}

/// Direction dropdown on the move block.
enum MoveDir: String, CaseIterable, Hashable {
    case forward, backward
    var label: String { self == .forward ? "forward" : "backward" }
    var icon: String { self == .forward ? "arrow.up" : "arrow.down" }
}

/// Unit dropdown on the move block (SPIKE offers cm / in / rotations / seconds…).
enum MoveUnit: String, CaseIterable, Hashable {
    case tiles, cm, rotations, seconds
    var label: String { rawValue }
    /// Centimetres per unit (rotations/seconds are approximated for the sim).
    var cmPerUnit: Double {
        switch self {
        case .tiles:     return 30
        case .cm:        return 1
        case .rotations: return 20
        case .seconds:   return 20
        }
    }
}

/// Direction dropdown on the turn block.
enum TurnDir: String, CaseIterable, Hashable {
    case left, right
    var label: String { rawValue }
    var icon: String { self == .left ? "arrow.uturn.left" : "arrow.uturn.right" }
}

/// A boolean condition — rendered as a light-blue sensor hexagon.
enum RCond: Hashable {
    case distance(op: RCompareOp, cm: Double)   // the adjustable distance sensor
    case wallAhead
    case colorIs(RSenseColor)
    case lineLeft
    case lineRight
    case holding
    case alwaysTrue

    var code: String {
        switch self {
        case let .distance(op, cm): return "distance() \(op.code) \(Int(cm))"
        case .wallAhead:            return "wallAhead()"
        case let .colorIs(c):       return "color() == \"\(c.rawValue)\""
        case .lineLeft:             return "lineLeft()"
        case .lineRight:            return "lineRight()"
        case .holding:              return "gripper.isHolding()"
        case .alwaysTrue:           return "true"
        }
    }

    var icon: String {
        switch self {
        case .distance:  return "ruler"
        case .wallAhead: return "arrow.up.to.line.compact"
        case .colorIs:   return "paintpalette.fill"
        case .lineLeft, .lineRight: return "road.lanes"
        case .holding:   return "hand.raised.fill"
        case .alwaysTrue: return "infinity"
        }
    }

    /// Short label for the hexagon (excluding the adjustable distance parts,
    /// which the view renders with live controls).
    var label: String {
        switch self {
        case .distance:  return "distance"
        case .wallAhead: return "wall ahead?"
        case let .colorIs(c): return "colour is \(c.rawValue)"
        case .lineLeft:  return "line on left?"
        case .lineRight: return "line on right?"
        case .holding:   return "holding?"
        case .alwaysTrue: return "forever"
        }
    }
}

/// A statement block. `repeat`/`while`/`if` are C-blocks that wrap a body.
indirect enum RBlock: Hashable {
    case stepForward                               // move forward one tile, no number
    case move(dir: MoveDir, amount: Int, unit: MoveUnit)   // SPIKE-style adjustable move
    case turn(dir: TurnDir, degrees: Int)                  // SPIKE-style adjustable turn
    case armRaise
    case armLower
    case armTo(Double)
    case gripperOpen
    case gripperClose
    case wait(Double)                              // milliseconds
    case returnHome
    case repeatN(count: Int, body: [RBlock])
    case whileC(cond: RCond, body: [RBlock])
    case ifC(cond: RCond, body: [RBlock])

    var isContainer: Bool {
        switch self {
        case .repeatN, .whileC, .ifC: return true
        default: return false
        }
    }

    /// The single numeric value a block carries, if any (for stepper editing).
    var number: Double? {
        switch self {
        case let .armTo(v), let .wait(v): return v
        default: return nil
        }
    }
}

// MARK: - Serializer

enum RBlockSerializer {
    static func code(_ blocks: [RBlock]) -> String {
        guard !blocks.isEmpty else { return "// Snap blocks to build your program\n" }
        return blocks.map { line($0, indent: 0) }.joined(separator: "\n") + "\n"
    }

    private static func body(_ blocks: [RBlock], indent: Int) -> String {
        if blocks.isEmpty {
            return String(repeating: "  ", count: indent) + "// (empty)"
        }
        return blocks.map { line($0, indent: indent) }.joined(separator: "\n")
    }

    private static func line(_ b: RBlock, indent: Int) -> String {
        let pad = String(repeating: "  ", count: indent)
        func n(_ v: Double) -> String { String(Int(v.rounded())) }
        switch b {
        case .stepForward:          return "\(pad)drive.forward(30);"
        case let .move(dir, amount, unit):
            let cm = Int((Double(amount) * unit.cmPerUnit).rounded())
            return dir == .forward ? "\(pad)drive.forward(\(cm));" : "\(pad)drive.backward(\(cm));"
        case let .turn(dir, deg):
            return dir == .left ? "\(pad)drive.turnLeft(\(deg));" : "\(pad)drive.turnRight(\(deg));"
        case .armRaise:             return "\(pad)arm.raise();"
        case .armLower:             return "\(pad)arm.lower();"
        case let .armTo(v):         return "\(pad)arm.moveTo(\(n(v)));"
        case .gripperOpen:          return "\(pad)gripper.open();"
        case .gripperClose:         return "\(pad)gripper.close();"
        case let .wait(v):          return "\(pad)wait(\(n(v)));"
        case .returnHome:           return "\(pad)returnHome();"
        case let .repeatN(count, bd):
            return "\(pad)repeat(\(count)) {\n\(body(bd, indent: indent + 1))\n\(pad)}"
        case let .whileC(cond, bd):
            return "\(pad)while (\(cond.code)) {\n\(body(bd, indent: indent + 1))\n\(pad)}"
        case let .ifC(cond, bd):
            return "\(pad)if (\(cond.code)) {\n\(body(bd, indent: indent + 1))\n\(pad)}"
        }
    }
}

// MARK: - Editor state (index-path tree API)

/// Holds the block tree and the current drop target. Mirrors the beginner
/// tier's path model: `[]` = top level, `[i]` = body of container i, deeper nests.
@Observable
@MainActor
final class RoboticsBlockEditor {
    var blocks: [RBlock] = []
    var insertionPath: [Int] = []

    var generatedCode: String { RBlockSerializer.code(blocks) }

    func insert(_ block: RBlock, atBody path: [Int]) {
        Self.mutateBody(&blocks, at: path[...]) { $0.append(block) }
        if block.isContainer, let body = Self.body(in: blocks, at: path[...]) {
            insertionPath = path + [body.count - 1]
        }
    }

    func delete(atNode path: [Int]) {
        guard let idx = path.last else { return }
        Self.mutateBody(&blocks, at: path.dropLast()[...]) {
            if $0.indices.contains(idx) { $0.remove(at: idx) }
        }
        normalizeInsertionPath()
    }

    func move(inBody path: [Int], from: Int, to: Int) {
        Self.mutateBody(&blocks, at: path[...]) {
            guard $0.indices.contains(from) else { return }
            $0.move(fromOffsets: IndexSet([from]), toOffset: max(0, min($0.count, to)))
        }
    }

    /// Replace the single node at `path` by transforming it.
    func updateNode(atNode path: [Int], _ transform: @escaping (RBlock) -> RBlock) {
        guard let idx = path.last else { return }
        Self.mutateBody(&blocks, at: path.dropLast()[...]) {
            if $0.indices.contains(idx) { $0[idx] = transform($0[idx]) }
        }
    }

    func setNumber(atNode path: [Int], _ value: Double) {
        updateNode(atNode: path) {
            switch $0 {
            case .armTo: return .armTo(max(0, min(180, value)))
            case .wait:  return .wait(max(0, value))
            default:     return $0
            }
        }
    }

    func setMoveDir(atNode path: [Int], _ d: MoveDir) {
        updateNode(atNode: path) {
            if case let .move(_, a, u) = $0 { return .move(dir: d, amount: a, unit: u) }
            return $0
        }
    }
    func setMoveUnit(atNode path: [Int], _ u: MoveUnit) {
        updateNode(atNode: path) {
            if case let .move(d, a, _) = $0 { return .move(dir: d, amount: a, unit: u) }
            return $0
        }
    }
    func setMoveAmount(atNode path: [Int], _ a: Int) {
        updateNode(atNode: path) {
            if case let .move(d, _, u) = $0 { return .move(dir: d, amount: max(1, min(20, a)), unit: u) }
            return $0
        }
    }
    func setTurnDir(atNode path: [Int], _ d: TurnDir) {
        updateNode(atNode: path) {
            if case let .turn(_, deg) = $0 { return .turn(dir: d, degrees: deg) }
            return $0
        }
    }
    func setTurnDegrees(atNode path: [Int], _ deg: Int) {
        updateNode(atNode: path) {
            if case .turn(let d, _) = $0 { return .turn(dir: d, degrees: max(15, min(360, deg))) }
            return $0
        }
    }

    func setRepeatCount(atNode path: [Int], _ count: Int) {
        guard let idx = path.last else { return }
        Self.mutateBody(&blocks, at: path.dropLast()[...]) {
            guard $0.indices.contains(idx), case let .repeatN(_, body) = $0[idx] else { return }
            $0[idx] = .repeatN(count: max(1, min(50, count)), body: body)
        }
    }

    func setCondition(atNode path: [Int], _ cond: RCond) {
        guard let idx = path.last else { return }
        Self.mutateBody(&blocks, at: path.dropLast()[...]) {
            guard $0.indices.contains(idx) else { return }
            switch $0[idx] {
            case let .whileC(_, body): $0[idx] = .whileC(cond: cond, body: body)
            case let .ifC(_, body):    $0[idx] = .ifC(cond: cond, body: body)
            default: break
            }
        }
    }

    func clear() {
        blocks = []
        insertionPath = []
    }

    func normalizeInsertionPath() {
        if Self.body(in: blocks, at: insertionPath[...]) == nil { insertionPath = [] }
    }

    // MARK: Tree helpers

    private static func mutateBody(_ blocks: inout [RBlock],
                                   at path: ArraySlice<Int>,
                                   _ mutate: (inout [RBlock]) -> Void) {
        guard let first = path.first else { mutate(&blocks); return }
        guard blocks.indices.contains(first) else { return }
        switch blocks[first] {
        case let .repeatN(count, body):
            var b = body; mutateBody(&b, at: path.dropFirst(), mutate)
            blocks[first] = .repeatN(count: count, body: b)
        case let .whileC(cond, body):
            var b = body; mutateBody(&b, at: path.dropFirst(), mutate)
            blocks[first] = .whileC(cond: cond, body: b)
        case let .ifC(cond, body):
            var b = body; mutateBody(&b, at: path.dropFirst(), mutate)
            blocks[first] = .ifC(cond: cond, body: b)
        default:
            break
        }
    }

    static func body(in blocks: [RBlock], at path: ArraySlice<Int>) -> [RBlock]? {
        guard let first = path.first else { return blocks }
        guard blocks.indices.contains(first) else { return nil }
        switch blocks[first] {
        case let .repeatN(_, childBody): return body(in: childBody, at: path.dropFirst())
        case let .whileC(_, childBody):  return body(in: childBody, at: path.dropFirst())
        case let .ifC(_, childBody):     return body(in: childBody, at: path.dropFirst())
        default: return nil
        }
    }
}
