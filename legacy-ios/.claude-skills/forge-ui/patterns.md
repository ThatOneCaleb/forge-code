# Forge Code — SwiftUI Component Patterns

Concrete, adaptable SwiftUI sketches for the app's screens. Referenced by the `forge-ui` skill. **These are starting points to adapt, not drop-in final code** — they're written against the real `ForgeCodeEngine` types (`Grid`, `Position`, `Direction`, `RobotState`, `Command`, `Program`, `ExecutionResult`, `Parser`, `CodeRenderer`). Requires full Xcode to compile. iOS 17+ (`@Observable`, `PhotosPicker`).

## ⚠️ Coordinate flip (read first)
The engine uses **origin bottom-left, +y up**. SwiftUI screen coordinates are **origin top-left, +y down**. When rendering, flip the row:
```swift
// engine (x,y) → grid row/col for layout
let col = pos.x
let row = (grid.height - 1) - pos.y   // flip Y for screen
```
Facing → rotation for the robot sprite (0° = pointing up on screen):
```swift
extension Direction {
    var screenRotation: Angle {
        switch self {
        case .up: .degrees(0); case .right: .degrees(90)
        case .down: .degrees(180); case .left: .degrees(270)
        }
    }
}
```

---

## 1. Grid board + robot (`GridBoardView`)
Draws the grid, obstacles, goal, and the robot at a given `RobotState`. Pure render of engine state — no logic.
```swift
struct GridBoardView: View {
    let grid: Grid
    let goal: Position
    let robot: RobotState

    var body: some View {
        GeometryReader { geo in
            let cell = min(geo.size.width / CGFloat(grid.width),
                           geo.size.height / CGFloat(grid.height))
            ZStack(alignment: .topLeading) {
                // cells
                ForEach(0..<grid.height, id: \.self) { row in
                    ForEach(0..<grid.width, id: \.self) { col in
                        let p = Position(x: col, y: (grid.height - 1) - row)
                        Rectangle()
                            .fill(grid.isObstacle(p) ? Color.gray : Color(.secondarySystemBackground))
                            .frame(width: cell, height: cell)
                            .border(Color(.systemGray4))
                            .overlay { if p == goal { Image(systemName: "flag.checkered").font(.title2) } }
                            .offset(x: CGFloat(col) * cell, y: CGFloat(row) * cell)
                    }
                }
                // robot
                RobotSprite()
                    .frame(width: cell * 0.8, height: cell * 0.8)
                    .rotationEffect(robot.facing.screenRotation)
                    .offset(x: CGFloat(robot.position.x) * cell + cell * 0.1,
                            y: CGFloat((grid.height - 1) - robot.position.y) * cell + cell * 0.1)
                    .animation(.easeInOut(duration: 0.28), value: robot)   // smooth step-to-step
            }
        }
        .aspectRatio(CGFloat(grid.width) / CGFloat(grid.height), contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel("Grid \(grid.width) by \(grid.height). Robot at column \(robot.position.x), row \(robot.position.y), facing \(robot.facing).")
    }
}

struct RobotSprite: View {   // swap for real art later
    var body: some View {
        Image(systemName: "location.north.circle.fill")
            .resizable().scaledToFit().foregroundStyle(.tint)
    }
}
```

---

## 2. Animation playback (`SimulatorViewModel`)
The engine computes the whole `frames` trace; the UI just plays it back step-by-step. Keep timing readable and respect Reduce Motion.
```swift
@Observable
final class SimulatorViewModel {
    let lesson: Lesson
    var displayedRobot: RobotState
    var mode: EditorMode = .blocks           // .blocks | .text
    var program = Program(commands: [])
    var codeText = ""
    var parseError: ParseError?
    var result: ResultState = .idle          // .idle | .running | .success | .failure(String)
    private let sim = Simulator()

    init(lesson: Lesson) {
        self.lesson = lesson
        self.displayedRobot = lesson.challenge.start
    }

    func run() async {
        parseError = nil
        // In text mode, parse first; keep last valid program on error.
        if mode == .text {
            do { program = try Parser.parse(codeText) }
            catch let e as ParseError { parseError = e; return }
            catch { return }
        }
        let outcome = sim.run(program: program, challenge: lesson.challenge)
        result = .running
        for frame in outcome.frames {
            displayedRobot = frame
            try? await Task.sleep(for: .milliseconds(300))   // readable pace
        }
        switch outcome.outcome {
        case .success: result = .success
        case .failure(let reason): result = .failure(reason.message)   // friendly, from engine
        }
    }

    func reset() { displayedRobot = lesson.challenge.start; result = .idle }
    func syncTextFromBlocks() { codeText = CodeRenderer.render(program) }  // block → text
}
enum EditorMode { case blocks, text }
enum ResultState: Equatable { case idle, running, success, failure(String) }
```

---

## 3. Mode toggle (block ↔ text) — two views of ONE program
```swift
Picker("Mode", selection: $vm.mode) {
    Text("Blocks").tag(EditorMode.blocks)
    Text("Code").tag(EditorMode.text)
}
.pickerStyle(.segmented)
.onChange(of: vm.mode) { _, newMode in
    if newMode == .text { vm.syncTextFromBlocks() }        // render blocks → text
    // switching to blocks: re-parse on next run; preserve last valid blocks on error
}
```

## 4. Code editor + friendly error banner
```swift
struct CodeEditorView: View {
    @Bindable var vm: SimulatorViewModel
    var body: some View {
        VStack(alignment: .leading) {
            TextEditor(text: $vm.codeText)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 160)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
            if let e = vm.parseError {
                Label(e.message, systemImage: "lightbulb")   // NEVER raw compiler text
                    .font(.callout).foregroundStyle(.orange)
                    .padding(8).background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    .accessibilityLabel("Hint: \(e.message)")
            }
        }
    }
}
```

## 5. Block palette + block
Map a UI `BlockType` 1:1 onto engine `Command`s so blocks compile to the same AST. Offer only `lesson.challenge.allowedCommands`.
```swift
enum BlockType: String, CaseIterable {
    case move, turnLeft, turnRight, repeatN, ifWall
    var kind: CommandKind { … }        // for filtering by allowedCommands
    var label: String { … }; var icon: String { … }
}
// Palette: big tappable chips, ≥44pt, drag or tap-to-append into the program.
```

## 6. Run controls + result overlay
```swift
Button { Task { await vm.run() } } label: {
    Label("Run", systemImage: "play.fill").font(.title3.bold())
        .frame(maxWidth: .infinity).frame(height: 56)      // big target
}
.buttonStyle(.borderedProminent)
.disabled(vm.result == .running)

// Success: celebratory + prompt to log. Failure: gentle + Try again + Hint.
.overlay {
    switch vm.result {
    case .success:
        ResultCard(title: "You did it! 🎉", tint: .green,
                   primary: ("Add to Build Log", { /* prompt entry */ }),
                   secondary: ("Next lesson", { /* advance */ }))
            .task { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    case .failure(let msg):
        ResultCard(title: msg, tint: .orange,               // friendly message
                   primary: ("Try again", { vm.reset() }),
                   secondary: ("Hint", { /* show lesson.hintText */ }))
    default: EmptyView()
    }
}
```

## 7. Lesson map node
```swift
struct LessonNode: View {
    let lesson: Lesson; let isUnlocked: Bool; let isCompleted: Bool
    var body: some View {
        VStack {
            Image(systemName: isCompleted ? "checkmark.seal.fill"
                                : isUnlocked ? "play.circle.fill" : "lock.fill")
                .font(.system(size: 44))                     // large, tappable
            Text(lesson.title).font(.headline)
        }
        .foregroundStyle(isUnlocked ? .primary : .secondary)
        .opacity(isUnlocked ? 1 : 0.5)
        .accessibilityLabel("\(lesson.title). \(isCompleted ? "Completed" : isUnlocked ? "Unlocked" : "Locked").")
    }
}
```

## Accessibility checklist (per screen, before "done")
- Every control has an `.accessibilityLabel`; grid + robot expose position/facing.
- Works at the largest Dynamic Type size (no clipping/overlap).
- Color is never the only signal (pair with icon/text/shape).
- `@Environment(\.accessibilityReduceMotion)` → skip/shorten the robot animation and success effects.
- Touch targets ≥ 44×44 pt.
