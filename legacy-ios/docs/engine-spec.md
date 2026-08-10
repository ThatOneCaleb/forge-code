# Engine & Interpreter Spec — Forge Code

> Detail doc referenced by [CLAUDE.md](../CLAUDE.md) and the `forge-engine` skill. This is the source of truth for the simulator engine and text interpreter. **Build and unit-test this before any UI.**

## Simulator (Tier 1 — grid-based, NOT physics)

### Grid
- Fixed 2D grid, default **6×6** (lesson-configurable).
- **Coordinate system:** origin `(0,0)` at **bottom-left**; `x` increases right, `y` increases up. "Up" facing = `+y`.
- A cell is empty or an **obstacle** (wall). Moving into an obstacle or off the grid edge is a **crash** (failure).

### Robot state
- `position: (x, y)` and `facing: Direction ∈ {up, down, left, right}`.
- Direction deltas: `up (0,+1)`, `down (0,-1)`, `left (-1,0)`, `right (+1,0)`.
- `turnLeft` = 90° counter-clockwise (CCW), `turnRight` = 90° clockwise (CW). Move advances one cell in the facing direction.

### Command / AST types
- `move()` — advance one cell forward.
- `turnLeft()` — rotate 90° CCW.
- `turnRight()` — rotate 90° CW.
- `repeat(n) { ... }` — run the body `n` times (n a positive integer; clamp to a sane max, ≤ 100).
- `if (wallAhead()) { ... }` — run the body once if the cell directly ahead is an obstacle or off-grid.

Model as an **indirect enum** so `repeat`/`if` nest bodies. This same AST is produced by **both** the block editor and the text parser. `Program` wraps `[Command]` and exposes `blockCount` = total recursive node count (each command node counts 1, including `repeat`/`if`, plus their bodies).

### Challenge definition (drives everything; lives in lesson JSON)
- grid size (width × height)
- robot start position + start facing
- goal position (single target cell for MVP)
- obstacle positions (array)
- `allowedCommands` (subset of the five — e.g. Move & Turn disallows `repeat`/`if`)
- optional `maxBlocks` (max blocks/commands allowed)
- optional hint text (lives on `Lesson`, not `Challenge`)

### Execution & results (`Simulator.run(program:challenge:)`)
- Produces an **ordered trace of frames** (robot state after each atomic step) so the UI can animate. **Engine computes the trace; UI plays it back.** `frames[0]` is the start state.
- Reject up front if `program.blockCount > maxBlocks` → `.ranOutOfBlocks`.
- **Step budget** (default 1000): increment a counter on every atomic step (each move/turn) **and each loop iteration**; exceed → `.tooManySteps`. Guards runaway/empty loops.
- `move` into an obstacle → `.hitWall(at:)`; off-grid → `.wentOffGrid(to:)`. Stop immediately, keep frames so far.
- `if(wallAhead())` true when the cell ahead is off-grid or an obstacle.
- **Success** = final position equals the goal (no crash, within blocks + step budget). Otherwise `.didNotReachGoal(finalPosition:)`.
- **Deterministic & pure:** same program + challenge ⇒ same result, always. This is what makes it testable.
- `Simulator` does **not** police `allowedCommands` — that's the palette/parser's job.

### Failure reasons (each carries a kid-friendly `message`)
`hitWall`, `wentOffGrid`, `ranOutOfBlocks`, `tooManySteps`, `didNotReachGoal`.

### Required tests (before UI)
- Each command's effect on robot state (move in every direction, both turns).
- Wall/edge crash detection.
- `repeat` runs the body exactly n times; nested `repeat`.
- `if(wallAhead())` true and false branches.
- `maxBlocks` and step-budget enforcement.
- Each of the 6 lessons: a known solution → `.success`; a known-bad program → the expected failure reason.

---

## Text interpreter (constrained Java-like syntax)

Write a **small custom lexer + parser**. **Do NOT embed a real Java compiler or any language runtime.** It parses only the grammar below and produces the same `Program`/`Command` AST as the block editor.

### Grammar (exactly this — no more)
```java
move();
turnLeft();
turnRight();
repeat(3) {
    move();
    turnRight();
}
if (wallAhead()) {
    turnRight();
}
```
- Leaf statements end with `;`.
- `repeat(n)` takes a positive integer literal (clamp 1…100) and a `{ ... }` body.
- `if (wallAhead())` takes a `{ ... }` body. `wallAhead()` is the **only** condition. **No `else`.**
- Whitespace/newlines insignificant. Blocks nest.
- **No** variables, expressions, operators, function definitions, or other conditions. The Variables lesson is conceptual via `repeat(n)` — **do not extend the grammar without explicit user approval.**

### Friendly error handling (kid-facing)
Never surface raw compiler errors. Errors are `ParseError` values with a **kid-friendly `message`** and, where possible, line/column. Tone examples:
- Missing semicolon → "Looks like you forgot a semicolon `;` at the end of line 3."
- Unmatched brace → "This `{` on line 2 doesn't have a matching `}`."
- Unknown command → "I don't recognize `jump()`. Try `move()`, `turnLeft()`, or `turnRight()`."
- `repeat` without a number → "`repeat` needs a number, like `repeat(3) { ... }`."

Aim for **one** clear, actionable message at the first problem — don't dump a wall of errors.

### Cross-mode reflection
- **Block → text:** `CodeRenderer` turns a `Program` into clean, 4-space-indented text.
- **Text → block:** parse to `Program`, then the block editor renders it. On a parse error, **keep the last valid block state** and show the friendly error — never destroy the kid's work.
- Toggling feels like two views of one program, not two separate programs.

### Required tests
- Each valid construct parses to the correct AST.
- Round-trip: `parse(render(program)) == program` for representative programs.
- Each error class produces the expected friendly `ParseError` with correct location.
