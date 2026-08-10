---
name: forge-robotics
description: Use when writing or changing ForgeCode's robotics tier engine — the new mini-language (lexer/parser/AST/interpreter with variables, functions, expressions), the robot/world/mission simulator, the Spark-MAX-flavored robot API, or their tests. Apply when working under Sources/ForgeCodeEngine/Robotics.
---

## What This Skill Does

A reference skill (no output of its own) that keeps ForgeCode's **robotics tier engine** pure, deterministic, and test-first. Apply it whenever editing anything under `Sources/ForgeCodeEngine/Robotics/` or `Tests/ForgeCodeEngineTests/Robotics/`. It encodes the rules from the approved robotics plan and [docs/robotics-engine.md](../../../docs/robotics-engine.md). This is the **advanced tier** — it deliberately goes beyond the beginner grid engine's "5 commands only" rule; the beginner tier (`forge-engine`) is unchanged and must keep working.

## Hard rules
1. **Purity.** No `import SwiftUI/SwiftData/UIKit` anywhere in `Robotics/`. Stdlib only; `import Foundation` only in the mission-content loader. Deterministic value types.
2. **Coexist, don't break.** This is a *new, separate* engine alongside the grid `ForgeCodeEngine`. Do NOT modify or regress the beginner tier (Code Basics grid + 5 commands). Reuse the old interpreter only as a *reference pattern*, not by extending its fixed grammar.
3. **One AST, two front-ends.** The robotics language has a single AST produced by **both** the text parser and (later) the block editor — one interpreter, one execution path. Never fork block vs text execution.
4. **Deterministic & action-based.** Same program + same `FieldWorld` ⇒ same `RoboticsRun`, always. Actions complete deterministically (`drive.forward(30)`, `arm.moveTo(90)`) — **no** real-time physics loop, no randomness, no wall-clock. Continuous `Double` coordinates (`Vec2`/`Pose`), not the Int grid.
5. **Budget everything.** The interpreter enforces an instruction/step budget (guards runaway loops/recursion); the simulator caps actions. Exceeding → a friendly failure, never a hang.
6. **Test-first.** Every language feature, API call, sensor, and scoring rule gets a unit test, and `swift test` stays green (including the existing beginner-tier tests — no regressions).

## The model (keep these shapes stable)
- **Language** (`Robotics/Lang/`): `RValue` (number/bool/string); `RLexer`/`RToken`; `RAST` (expr: literal, variable, binary/unary, call, memberCall like `drive.forward(x)`; stmt: varDecl, assign, if/else, while, for, funcDef, return, exprStmt, block); `RParser` (recursive-descent + precedence); `RInterpreter` (scoped environments, user functions + recursion); `RParseError`/`RRuntimeError` with **teen-friendly** messages + line/col.
- **Robot API — Spark-MAX-*flavored*, original** (`Robotics/Sim/RobotAPI.swift`): drivetrain `drive.forward(cm)/backward/turnLeft(deg)/turnRight(deg)`, `drive.distance()/heading()`; `arm.moveTo(deg)/raise/lower/angle()`; `gripper.open()/close()/isHolding()`; sensors `distance()`, `color()`/`color.isRed()…`, `lineLeft()/lineRight()`, `gyro()`, `limitSwitch()`, `wallAhead()`; `wait(ms)`, `print(x)`. Extend thoughtfully; keep names consistent.
- **World & sim** (`Robotics/Sim/`): `Vec2`, `Pose`; `RobotModel` (drivetrain+encoders, arm angle, gripper+held object); `FieldWorld` (bounds + items, deposit zones, obstacles, lines, colored regions); `Mission` (objectives + points + success rule); `RoboticsSimulator.run(program:world:) -> RoboticsRun`; `RoboticsRun` = ordered `[RobotSnapshot]` (pose, armAngle, gripper, heldObjectId, world-object states) + event/sensor log + `MissionResult` (objectives met, score). The UI plays back `RoboticsRun`; the engine computes it.

## Guardrails
- **Original + FLL-*inspired* only** — no FLL/FIRST/LEGO/REV names, art, or marks in code, comments, or content.
- Audience is **advanced elementary → high school** — capable but legible; friendly errors, never punishing.
- Robotics mechanics live here; the 3D view/blocks/editor live in the app layer. Authoring mission *content* is the `/add-mission` skill's job.

## When adding a feature
1. Write/extend the test that pins the behavior. 2. Implement in the smallest pure type. 3. `swift build` + `swift test` green (new + existing). 4. If it's mission content, use `/add-mission` instead.
