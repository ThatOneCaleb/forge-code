# robotics-engine.md — ForgeCode Robotics Tier (advanced) engine spec

**Source of truth for the robotics-tier engine.** Read this before touching anything under
`Sources/ForgeCodeEngine/Robotics/` or authoring a mission. Companion to the `forge-robotics`
skill (conventions) and `/add-mission` (content). This tier **coexists with** and does **not**
replace the beginner grid engine (Code Basics, 5 commands) — that stays as the young-kid on-ramp.

## Why this tier exists
Turn ForgeCode into a real **robotics programming simulator**: a robot with a **drivetrain, an
arm + gripper, and sensors**, programmed in a **real mini-language** (variables, math/logic,
loops, functions), completing **FLL-style field missions** by actually *using* those mechanisms.
API is **flavored after CAN Spark MAX / FRC** (familiar concepts + naming) but **100% original**
— no FLL/FIRST/LEGO/REV names, art, themes, or marks anywhere.

Audience: **advanced elementary → middle → high school.** Capable but legible; friendly,
never-punishing errors. A newcomer should be able to read a solution and understand it.

## Scale goals (what the engine must comfortably support — content is R4)
- **Multiple fields** (distinct themed worlds), each a reusable `FieldWorld`.
- **≥15 missions per field**, ordered into a progression from "drive to a spot" → multi-objective
  arm/sensor tasks. Missions reference a field by id; many missions share one field.
- **Interactive by requirement:** a mission's points must *require* the intended mechanism
  (arm/gripper/sensor), so a trivial drive-only path can't score full marks.
- The model must stay cheap to author (JSON) and cheap to verify (`swift test`), because there
  will be a lot of it. Keep worlds/missions data-driven, not code.

## Non-negotiables (from forge-robotics)
1. **Purity.** No `import SwiftUI/SwiftData/UIKit` in `Robotics/`. Stdlib only; `import Foundation`
   only in the mission-content loader. Deterministic value types.
2. **Coexist, don't break.** Additive tier. Do NOT modify/regress the beginner grid engine or its
   existing tests. Reuse the old interpreter only as a *reference pattern*.
3. **One AST, two front-ends.** A single robotics AST produced by both the text parser and (later)
   the block editor. One interpreter, one execution path. Never fork block vs text execution.
4. **Deterministic & action-based.** Same program + same `FieldWorld` ⇒ identical `RoboticsRun`.
   Actions complete deterministically (`drive.forward(30)`, `arm.moveTo(90)`). **No** real-time
   physics loop, **no** randomness, **no** wall-clock. Continuous `Double` coordinates
   (`Vec2`/`Pose`) in **centimetres**, not the Int grid.
5. **Budget everything.** Interpreter enforces an instruction/step budget (guards runaway
   loops/recursion); simulator caps actions. Exceeding → a friendly failure, never a hang.
6. **Test-first.** Every language feature, API call, sensor, and scoring rule gets a unit test.
   `swift test` stays green including the existing beginner-tier tests.

## The language (Robotics/Lang/)
A small, C/Java-flavored scripting language (on-ramp to real robot code). Reference syntax:

```
// variables (dynamically typed values: number, bool, string)
var count = 3
var target = distance()

// arithmetic + logic + comparison, standard precedence
var half = count / 2 + 1
if (distance() < 15 && !gripper.isHolding()) {
    arm.lower()
    gripper.close()
}

// loops
while (distance() > 10) { drive.forward(2) }
for (var i = 0; i < count; i = i + 1) { drive.forward(25); drive.turnRight(90) }
repeat (4) { drive.forward(50); drive.turnRight(90) }   // sugar; keeps a bridge to the beginner tier

// functions (+ recursion, within budget)
func square(side) {
    for (var i = 0; i < 4; i = i + 1) { drive.forward(side); drive.turnRight(90) }
}
square(30)
```

Types & nodes:
- `RValue`: `.number(Double)`, `.bool(Bool)`, `.string(String)` (+ a `.void`/none for statements).
- `RToken`/`RLexer`: identifiers, number/string literals, operators
  (`+ - * / %  == != < <= > >=  && || !  =`), punctuation (`() {} ; , .`), `//` line comments.
- `RAST`:
  - **Expr:** literal, variable, binary, unary, `call(name, args)` (free funcs like `distance()`,
    `print(x)`, `wait(ms)`), `memberCall(object, method, args)` (`drive.forward(x)`,
    `gripper.isHolding()`), and member/property reads where needed (`drive.heading()` is a
    memberCall with no args — prefer method-call form to keep it uniform).
  - **Stmt:** varDecl, assign, if/else, while, for, `repeat`, funcDef, return, exprStmt, block.
- `RParser`: recursive-descent + precedence climbing. `RParseError` with **teen-friendly** message
  + line/col (e.g. "I expected a `)` to close this `if` condition on line 4").
- `RInterpreter`: lexically-scoped environments, user functions + recursion, a global scope with
  the robot API bound in. Deterministic. Instruction/step budget → `RRuntimeError` (also friendly,
  e.g. "Your program ran too many steps — is a loop never finishing?").

## Robot API — Spark-MAX-*flavored*, original (Robotics/Sim/RobotAPI.swift)
Bound into the interpreter as callable members. All motion is **action-based** (completes in the
sim deterministically). Distances in **cm**, angles in **degrees**, heading 0° = +Y (field
"north"), positive turn = clockwise (document precisely in code and keep consistent).

- **Drivetrain:** `drive.forward(cm)`, `drive.backward(cm)`, `drive.turnLeft(deg)`,
  `drive.turnRight(deg)`; readbacks `drive.distance()` (cumulative encoder cm), `drive.heading()`.
- **Arm:** `arm.moveTo(deg)`, `arm.raise()`, `arm.lower()`, `arm.angle()`.
  (Arm angle gates pickup/deposit — e.g. must be lowered near an item to grab it.)
- **Gripper:** `gripper.open()`, `gripper.close()`, `gripper.isHolding()`.
  Closing while positioned at a pickable item (arm in range) grabs it; opening over a deposit
  zone releases it there.
- **Sensors (read the world at call time):** `distance()` (forward range to nearest
  obstacle/wall, cm), `color()` → string + `color.isRed()/isBlue()/isGreen()` helpers,
  `lineLeft()`/`lineRight()` (bool, on a line marking), `gyro()` (= heading), `limitSwitch()`
  (arm/gripper hard stop or contact), `wallAhead()` (bool convenience).
- **Utility:** `wait(ms)` (advances the trace, no motion), `print(x)` (to the run's log).

Extend thoughtfully and keep names consistent. If a mission needs a capability the API lacks,
**that's an engine change here (deliberate + tested)** — never faked in content.

## World, robot, mission, run (Robotics/Sim/)
- `Vec2(x,y: Double)`, `Pose(position: Vec2, headingDegrees: Double)`.
- `RobotModel`: pose + encoders (cumulative distance, heading), arm angle, gripper open/closed +
  `heldObjectId`. A footprint radius for collision. Continuous.
- `FieldWorld`: `id`, `name`, bounds (width×height cm), and objects:
  - **items** (pickable): id, position, optional color/type.
  - **zones** (target/deposit/detection): id, rect or circle, kind, optional required color.
  - **obstacles/walls**: rects the robot can't overlap (collision → friendly failure or blocked
    move; document which).
  - **lines**: polylines the line sensors read.
  - **coloredRegions**: rects/tiles the color sensor reads.
- `Mission`: `id`, `fieldId`, `title`, kid-facing brief, ordered `objectives` (each: id, kind,
  target ref, points, human description) + a **success rule** (e.g. "score ≥ threshold" or "all
  required objectives met"). Objective kinds at minimum: reachPose/reachZone, pickUpItem,
  depositItemInZone, detectColorInZone, armToAngle. Scoring is **unambiguous**.
- `RoboticsSimulator.run(program:world:mission?:) -> RoboticsRun`:
  interprets the program with the API bound to a `RobotModel` over the `FieldWorld`, deterministic.
  Handles collision + budget with friendly failures.
- `RoboticsRun`: ordered `[RobotSnapshot]` keyframes (pose, armAngle, gripper, heldObjectId,
  world-object states at that frame) + an event/sensor log + optional `MissionResult`
  (objectives met, score, success bool, failure reason). **The UI plays back `RoboticsRun`; the
  engine computes it** — the UI never re-simulates.

## Match layer — "make it a real Field" (Robotics/Sim/ + Content/)
A **Match** turns individual missions into a competitive field round: **one program, run once,
scores many missions at once, on a move budget, with precision tokens.** This is the model the R2
UI plays. It sits *above* missions and reuses their scoring — it does not replace them.

- **`Match`** (`Sim/Match.swift`, value type + Codable-loaded): `id`, `fieldId`, `name`,
  kid-facing brief, **`missionIds: [String]`** (a *curated* subset of that field's missions that
  coexist cleanly in one run — NOT necessarily all 15; avoid heavy objective overlap that would
  double-count), **`moveBudget: Int`** (the match "length" — total robot actions allowed for the
  whole run; this is how "you have N minutes" is expressed deterministically), `startingTokens:
  Int` (default **6**), `pointsPerToken: Int` (default **10**). Optional `parScore`.
- **Precision tokens + rescue-to-home.** New API action **`returnHome()`**: teleports the robot to
  the field's home pose, **spends 1 precision token** (floored at 0), costs **1 action** from the
  move budget, and keeps any held item (you carried it home). It's the strategic "relaunch from
  base" — spend points to reset accumulated error or get unstuck. Token bonus at the end =
  `remainingTokens × pointsPerToken` (6→60, 5→50 … per the design).
- **Collision policy differs by mode.** Single-mission runs keep today's behavior: collision =
  friendly hard-fail (`.failRun`, existing tests unchanged). **Match runs use
  `.blockAndContinue`:** a move that would hit an obstacle stops the robot flush against it and
  execution continues — so a bot can get "stuck" against a rock and the program can `returnHome()`
  to recover (−1 token). Implement as a `collisionPolicy` on the run, one execution path, default
  `.failRun`.
- **Home pose.** Add an optional **`homePose: Pose?`** to `FieldWorld` (default: centre of the
  field's base/home goal zone — `base_camp` on Mars Outpost, `home_base` on Cargo Command — else
  the south-centre edge). It's the match start pose and the `returnHome()` target.
- **`RoboticsSimulator.runMatch(program:world:match:) -> MatchRun`**: runs the program once
  (block-and-continue, budget = `match.moveBudget`, tokens tracked), then scores **each** included
  mission with the existing per-mission `scoreMission` against the final state, and assembles a
  **`MatchResult`**: `perMission: [(missionId, metObjectiveIds, score, success)]`, `missionPoints`
  (sum), `tokensRemaining`, `tokenPoints`, `totalScore` (= missionPoints + tokenPoints),
  `actionsUsed` / `budgetRemaining`, and an ordered keyframe trace (same `RobotSnapshot` model, so
  the UI plays it back exactly like a single run). Deterministic: same program + world + match ⇒
  identical `MatchRun`.
- **Content** (`Content/robotics_matches.json` + loader, added as a `.process` resource): seed
  **1 match per field** — a curated 5–6-mission showcase with a sensible `moveBudget` and 6 tokens.
  A test runs a known-good program and asserts the exact `MatchResult` (mission breakdown + token
  bonus + total), plus a negative (running out of budget, or a token spent lowering the bonus).
  Authoring more matches is later content work (a `/add-match`-style flow), not this slice.

## Content (Robotics/Content/)
- `robotics_missions.json` (+ `robotics_fields.json` if fields are split out) decoded by a
  `RoboticsLibrary`-style loader (the only place `import Foundation` is allowed in this tier).
  Add these as SwiftPM `resources` in `Package.swift` (`.process(...)`).
- R1 seeds only **1–2 fields + 2–3 missions** — just enough to test the pipeline end-to-end.
  The full **multiple fields × ≥15 missions** content is **R4** via `/add-mission` /
  `mission-designer`. Design the schema now so that scale is pure data-entry later.

## Tests (Tests/ForgeCodeEngineTests/Robotics/)
- **Language:** lexer, precedence, if/else, while, for, repeat, functions + recursion, scoping,
  friendly parse + runtime errors, budget stops a runaway loop.
- **Robot actions:** drive distance/turn heading accuracy; arm angle; gripper pick/place flips
  `heldObjectId` and world item state.
- **Sensors:** distance/color/line/gyro/limit read the world correctly from known poses.
- **Mission scoring:** a known-good program solves a seed mission → success + expected score;
  a negative case (skip the pickup) → lower score / failure.
- **Determinism:** same program + world ⇒ identical `RoboticsRun` (compare snapshots/score).
- Existing **beginner-tier tests stay green** — no regressions.

## Phases (this doc drives R1; later slices append)
- **R1 (now):** everything above — pure engine, no UI. Verifiable with `swift test`.
- **R2:** 3D playable mission screen (SceneKit) — text editor + Run → play `RoboticsRun` +
  mission result; renders arm/gripper/items. Screenshot-verified.
- **R3:** block editor v2 — categorized palette (Drive, Arm, Gripper, Sensors, Control, Logic,
  Math, Variables, Functions) ↔ the same AST.
- **R4:** content + progression — multiple fields, ≥15 verified missions each, a robotics lesson
  track teaching the API progressively; more sensors/mechanisms as needed.
- **R5:** Mac Catalyst fast-follow.

## Guardrails carried forward
- Original + FLL-*inspired* only — no FLL/FIRST/LEGO/REV IP or marks in code, comments, content.
- Kid/teen-safe: no networking/accounts/analytics/IAP/third-party SDKs. Local, on-device.
- Engine stays pure/deterministic/tested; 3D view, blocks, and editor live in the app layer.
