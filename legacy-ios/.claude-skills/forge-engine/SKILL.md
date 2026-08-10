---
name: forge-engine
description: Use when writing or changing Forge Code's simulator engine or text interpreter — the grid simulator, robot state, command/block AST, program execution, the Java-like lexer/parser, code renderer, or their unit tests. Apply when working under Sources/ForgeCodeEngine.
---

## What This Skill Does

A reference skill (no output of its own) that keeps Forge Code's engine and interpreter **pure, deterministic, and test-first**. Apply it whenever editing anything under `Sources/ForgeCodeEngine/` or `Tests/ForgeCodeEngineTests/`. It encodes the rules from `CLAUDE.md` §6–§7 so engine work stays consistent across sessions.

## Hard rules

1. **Purity — the engine must NOT import SwiftUI, SwiftData, or UIKit.** Only Swift stdlib. `import Foundation` is allowed *only* in the content loader (`LessonLibrary`) for `Bundle.module`/JSON. The lexer/parser/simulator use stdlib only. If you're tempted to import an Apple UI framework here, the logic belongs in the app layer, not the engine.

2. **One AST, two front-ends.** Blocks and text **both compile to the same `Command`/`Program` AST**. There is exactly one execution path (`Simulator`). Never build a parallel interpreter for text vs blocks. This shared AST is what makes mode-toggling and two-way reflection work — treat it as the spine.

3. **Determinism & value types.** Given the same `Program` + `Challenge`, `Simulator.run` always returns the same `ExecutionResult`. Engine state is `struct`/`enum` value types. No global mutable state, no randomness, no clocks.

4. **Test-first.** Every engine/interpreter behavior gets a unit test *before or with* the code, and `swift test` must stay green. If you can't test it in isolation, it's in the wrong layer.

## The model (keep these shapes stable)

- **Coordinates:** origin `(0,0)` bottom-left; `+y` up. `turnLeft` = CCW, `turnRight` = CW. `up.delta = (0,+1)`, `down (0,-1)`, `left (-1,0)`, `right (+1,0)`.
- **`Command`** (indirect enum): `move`, `turnLeft`, `turnRight`, `repeatBlock(count, body:[Command])`, `ifWallAhead(body:[Command])`. `CommandKind` (raw `move/turnLeft/turnRight/repeat/if`) enumerates allowed-command sets.
- **`Program`**: `commands:[Command]`; `blockCount` = total recursive node count (each command node counts 1, including `repeat`/`if`, plus their bodies).
- **`Challenge`**: `grid`, `start:RobotState`, `goal:Position`, `allowedCommands:[CommandKind]`, `maxBlocks:Int?`.
- **`ExecutionResult`**: `outcome` (`success` | `failure(FailureReason)`) + `frames:[RobotState]` where `frames[0]` is the start and one frame is appended per atomic step (the UI plays this back — the engine computes it).

## Execution rules (`Simulator.run`)

- Reject up front if `program.blockCount > challenge.maxBlocks` → `.ranOutOfBlocks`.
- Execute recursively; `repeat(n)` runs the body `n` times; `if(wallAhead())` runs its body once when the cell ahead is off-grid or an obstacle.
- **Step budget** (default 1000): increment a counter on every atomic step (each move/turn) **and each loop iteration**, and fail with `.tooManySteps` if exceeded. This guards runaway and empty loops.
- `move` into an obstacle → `.hitWall`; off the grid → `.wentOffGrid`; stop immediately, keep frames so far.
- Success only when the final position equals the goal; otherwise `.didNotReachGoal`.
- `Simulator` does **not** police `allowedCommands` — that's the palette/parser's job (UI authoring concern). Keep the simulator focused on execution.

## Interpreter rules

- Grammar is **exactly**: `move();`, `turnLeft();`, `turnRight();`, `repeat(n){ … }` (n a positive int literal, clamp 1…100), `if (wallAhead()){ … }`. No `else`, variables, expressions, operators, or extra conditions. **Do not extend the grammar without explicit user approval.**
- Errors are `ParseError` values with a **kid-friendly `message`** and line/column — never raw compiler jargon. One clear, actionable message at the first problem; don't dump a wall of errors.
- `CodeRenderer` turns `Program` → clean 4-space-indented text (block→text). Round-trip invariant: `parse(render(p)) == p` for any valid `p`. On a text parse error, preserve the last valid block state and surface the friendly error — never destroy the kid's work.

## When adding a feature here
1. Write/extend the unit test that pins the behavior.
2. Implement in the smallest pure type that owns it.
3. Run `swift build` then `swift test`; keep both clean.
4. If the behavior is user-facing content (a lesson), use the `/add-lesson` skill instead.

## Forward-compat (differentiator #5, robotics)
The Robotics track is stubbed in the MVP, but keep the command/challenge model general enough to later express robotics conditions/sensors beyond `wallAhead()`. Prefer extensible enum shapes over hard-coded assumptions — but do not build robotics commands yet.
