import SwiftUI
import ForgeCodeEngine

/// Editor mode: block palette or text code editor.
enum EditorMode: Equatable {
    case blocks
    case text
}

/// The overall run state.
enum ResultState: Equatable {
    case idle
    case running
    case success
    case failure(String)
}

/// View-model for the Lesson / Simulator screen.
///
/// Owns all engine interactions: running the program, playing back frames,
/// toggling between block and text modes, and tracking parse errors.
/// Views observe this object and never call the engine directly.
@Observable
@MainActor
final class SimulatorViewModel {
    let lesson: Lesson
    var displayedRobot: RobotState
    var mode: EditorMode = .blocks
    var program = Program(commands: [])
    var codeText = ""
    var parseError: ParseError?
    var result: ResultState = .idle
    var showHint = false
    var showBuildLogPrompt = false

    /// The body a new palette block will drop into. `[]` = top level;
    /// `[2]` = the body of the top-level container at index 2; deeper paths nest.
    var insertionPath: [Int] = []

    private let simulator = Simulator()

    init(lesson: Lesson) {
        self.lesson = lesson
        self.displayedRobot = lesson.challenge.start
    }

    // MARK: - Run

    /// Parse (in text mode), simulate, and animate the result frame by frame.
    func run(reduceMotion: Bool = false) async {
        guard result != .running else { return }
        parseError = nil
        showHint = false

        if mode == .text {
            do {
                program = try Parser.parse(codeText)
            } catch let e as ParseError {
                parseError = e
                return
            } catch {
                return
            }
        }

        let executionResult = simulator.run(program: program, challenge: lesson.challenge)
        result = .running

        let stepDuration: Duration = reduceMotion ? .milliseconds(0) : .milliseconds(300)
        for frame in executionResult.frames {
            displayedRobot = frame
            if !reduceMotion {
                try? await Task.sleep(for: stepDuration)
            }
        }

        switch executionResult.outcome {
        case .success:
            result = .success
            showBuildLogPrompt = true
        case .failure(let reason):
            result = .failure(reason.message)
        }
    }

    // MARK: - Reset

    func reset() {
        displayedRobot = lesson.challenge.start
        result = .idle
        showHint = false
        showBuildLogPrompt = false
        parseError = nil
    }

    // MARK: - Block editor (index-path tree API)
    //
    // A "container path" identifies a body to mutate: `[]` is the top-level
    // program, `[i]` is the body of the container at top index i, `[i, j]`
    // nests one level deeper, and so on. A "node path" is a container path
    // plus a trailing index that points at one command inside that body.

    /// Insert a command at the end of the body identified by `path`.
    /// If the command is itself a container, retarget insertion into its body.
    func insert(_ command: Command, atBody path: [Int]) {
        Self.mutateBody(&program.commands, at: path[...]) { $0.append(command) }
        switch command {
        case .repeatBlock, .ifWallAhead:
            if let body = Self.body(in: program.commands, at: path[...]) {
                insertionPath = path + [body.count - 1]
            }
        default:
            break
        }
    }

    /// Delete the command at a full node path (last element = index in its body).
    func delete(atNode path: [Int]) {
        guard let idx = path.last else { return }
        let parent = Array(path.dropLast())
        Self.mutateBody(&program.commands, at: parent[...]) {
            if $0.indices.contains(idx) { $0.remove(at: idx) }
        }
        normalizeInsertionPath()
    }

    /// Reorder within a single body.
    func move(inBody path: [Int], from: Int, to: Int) {
        Self.mutateBody(&program.commands, at: path[...]) {
            guard $0.indices.contains(from) else { return }
            let clamped = max(0, min($0.count, to))
            $0.move(fromOffsets: IndexSet([from]), toOffset: clamped)
        }
    }

    /// Update a `repeat` block's count at a full node path.
    func updateRepeatCount(atNode path: [Int], count: Int) {
        guard let idx = path.last else { return }
        let parent = Array(path.dropLast())
        Self.mutateBody(&program.commands, at: parent[...]) {
            guard $0.indices.contains(idx),
                  case let .repeatBlock(_, body) = $0[idx] else { return }
            $0[idx] = .repeatBlock(count: max(1, min(20, count)), body: body)
        }
    }

    /// Flip a placed `turn` block between left and right (the direction dropdown).
    func toggleTurnDirection(atNode path: [Int]) {
        guard let idx = path.last else { return }
        let parent = Array(path.dropLast())
        Self.mutateBody(&program.commands, at: parent[...]) {
            guard $0.indices.contains(idx) else { return }
            switch $0[idx] {
            case .turnLeft:  $0[idx] = .turnRight
            case .turnRight: $0[idx] = .turnLeft
            default: break
            }
        }
    }

    func clearProgram() {
        program = Program(commands: [])
        codeText = ""
        parseError = nil
        insertionPath = []
    }

    /// Reset the insertion target to top level if it no longer points at a
    /// valid, still-a-container body (e.g. after a delete).
    func normalizeInsertionPath() {
        if Self.body(in: program.commands, at: insertionPath[...]) == nil {
            insertionPath = []
        }
    }

    // MARK: Tree helpers

    /// Mutate the body array reachable by `path`, rebuilding containers along the way.
    private static func mutateBody(_ commands: inout [Command],
                                   at path: ArraySlice<Int>,
                                   _ mutate: (inout [Command]) -> Void) {
        guard let first = path.first else { mutate(&commands); return }
        guard commands.indices.contains(first) else { return }
        switch commands[first] {
        case let .repeatBlock(count, body):
            var b = body
            mutateBody(&b, at: path.dropFirst(), mutate)
            commands[first] = .repeatBlock(count: count, body: b)
        case let .ifWallAhead(body):
            var b = body
            mutateBody(&b, at: path.dropFirst(), mutate)
            commands[first] = .ifWallAhead(body: b)
        default:
            break
        }
    }

    /// Read the body reachable by `path`, or nil if the path doesn't land on a container.
    static func body(in commands: [Command], at path: ArraySlice<Int>) -> [Command]? {
        guard let first = path.first else { return commands }
        guard commands.indices.contains(first) else { return nil }
        switch commands[first] {
        case let .repeatBlock(_, childBody): return body(in: childBody, at: path.dropFirst())
        case let .ifWallAhead(childBody):    return body(in: childBody, at: path.dropFirst())
        default:                             return nil
        }
    }

    // MARK: - Mode toggle

    /// Called when switching to text mode: render current blocks as code.
    func syncTextFromBlocks() {
        codeText = CodeRenderer.render(program)
    }

    /// Called when switching back to blocks: attempt to re-parse text.
    /// On parse error, preserve the last valid block program.
    func syncBlocksFromText() {
        do {
            program = try Parser.parse(codeText)
            parseError = nil
        } catch let e as ParseError {
            // Keep the previous block program; show the error.
            parseError = e
        } catch {
            // Swallow unexpected errors; keep last valid program.
        }
    }

    // MARK: - Computed helpers

    var allowedCommandKinds: [CommandKind] {
        lesson.challenge.allowedCommands
    }

    var hintText: String {
        lesson.hintText ?? "Think about what path the robot needs to take step by step."
    }

    var blockCount: Int {
        program.blockCount
    }

    var maxBlocks: Int? {
        lesson.challenge.maxBlocks
    }
}
