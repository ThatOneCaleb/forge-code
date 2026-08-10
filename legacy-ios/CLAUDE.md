# CLAUDE.md — Forge Code

Lean always-on guide. This file is the map; **detailed specs live in [`docs/`](docs/)** — read the relevant doc before doing that kind of work.

## What we're building
**Forge Code** — a free iOS/SwiftUI **coding & robotics learning app for kids ~8–15**, built for the **STEM Greenhouse** pilot. Works with or without a physical robot. Kids solve grid challenges by writing programs in **blocks *or* text** (same underlying engine), earn badges, and keep a build log. Built for **App Store release**; MVP is deliberately small. (Display name "Forge Code"; code identifiers use `ForgeCode`.)

**At a glance:** SwiftUI · iOS 17+ · SwiftData for user data + bundled JSON for lessons · pure-Swift engine (no UI deps) · no backend, no third-party packages.

**Core loop:** Lesson Map → tap next unlocked lesson → intro + goal → block/text workspace → **Run** (robot animates) → success (badge + streak, prompt a build-log entry) or retry → back to map, next lesson highlighted. Full detail in [screens.md](docs/screens.md).

## Differentiators (keep in view — every MVP decision must protect these)
1. **Mentor + parent visibility layer** (stubbed now; model progress/badges/log as cleanly queryable, shareable data).
2. **Resource-scarce by design** — complete, satisfying on an iPhone with **zero hardware**, not as a fallback.
3. **Dual block/text mode as a real on-ramp to Java-like syntax** — the shared AST + faithful two-way reflection is the spine.
4. **Real program, real pilot (STEM Greenhouse)** — reliability and clarity over flashy-but-fragile.
5. **Bridges coding into robotics concepts** (stubbed; keep the engine model general enough to extend later).

## Scope at a glance
- **Build fully:** Kid experience · Code Basics track (6 lessons) · grid simulator with block+text modes · text interpreter · Lesson Map, Lesson/Simulator, Badge Shelf, Build Log · local persistence.
- **Stub only:** Robotics Concepts, Mentor, Parent — "Coming soon" screens.
- **Audience & tone:** kids ~8–15, often mentor-led, maybe no robot. Legible, forgiving, encouraging — success feels great, failure is gentle + a hint. Never jargon-y or punishing.

## Guiding principles
- **Engine first, UI second.** Pure, dependency-free, fully tested engine before any UI.
- **Kid-safe by default.** No accounts, networking, data collection, or third-party SDKs. Local, on-device.
- **One correct core loop beats ten half-built screens.**
- **Friendly, never punishing.** Encouraging, age-appropriate errors/hints.

## Hard guardrails — do NOT build (flag & confirm if a request crosses these)
- ❌ No backend, accounts, login, or networking of any kind.
- ❌ No Mentor/Parent/Robotics functionality — **"Coming soon" placeholders only.**
- ❌ No AI, no monetization/paywall/IAP/ads, no robot/BLE connectivity.
- ❌ No interpreter grammar beyond the fixed five commands (`move`, `turnLeft`, `turnRight`, `repeat`, `if(wallAhead())`).
- ❌ No lessons beyond the first ~6 Code Basics until the core loop works.

## Resolved decisions (don't re-litigate)
1. **Name:** "Forge Code" (code identifiers `ForgeCode`). 2. **Variables:** conceptual only, via `repeat(n)` — no grammar extension. 3. **Profiles:** single local kid. 4. **Layout:** phone-only, portrait for v1.

## 📚 Documentation map (`docs/`)
| Doc | Read it when… |
|-----|---------------|
| [product-vision.md](docs/product-vision.md) | You need the full scope, users, differentiators, or definition of done. |
| [architecture.md](docs/architecture.md) | Working on layout, layering, conventions, or build/test commands. |
| [engine-spec.md](docs/engine-spec.md) | Touching the simulator engine or text interpreter. **Source of truth.** |
| [lessons.md](docs/lessons.md) | Authoring/verifying lessons; the 6 Code Basics lessons + solutions. |
| [data-models.md](docs/data-models.md) | Touching data models (engine value types or SwiftData `@Model`s). |
| [screens.md](docs/screens.md) | Building any SwiftUI screen or the core loop. |
| [field-3d.md](docs/field-3d.md) | Building the 3D FLL-inspired **Field Mode** (major phased feature; original art only, no FLL/FIRST/LEGO IP). |
| [robotics-engine.md](docs/robotics-engine.md) | Touching the **advanced robotics tier** engine (real mini-language + robot/world/mission sim + **Match layer**). **Source of truth for that tier.** |
| [robotics-missions.md](docs/robotics-missions.md) | The mission + match **catalog** (30 verified missions across 2 fields + seed matches). Auto-derived from the content JSON. |

## 🛠 Project skills (`.claude/skills/`)
- **`/add-lesson [track] [concept]`** — author a verified new lesson (challenge JSON + solution + passing test). Engine-only; `swift test`.
- **`/scaffold-app`** — stand up the Xcode app target, SwiftData, navigation, screens + placeholders. **Requires full Xcode.**
- **`/add-mission [concept]`** — author a verified robotics mission (world + objectives + scoring + solution program + passing test). Advanced tier; `swift test`.
- **`/bulk-grid-challenges [d1|d2|d3|d4|d5] [count]`** — bulk-author N verified beginner grid challenges at a target difficulty tier; appends to `challenges.json` + adds tests; runs `swift test` before reporting done.
- **`forge-engine`** (auto) — keeps the beginner grid engine/interpreter pure, deterministic, test-first.
- **`forge-robotics`** (auto) — keeps the advanced robotics engine/language pure, deterministic, action-based, test-first (applies under `Sources/ForgeCodeEngine/Robotics/`).
- **`forge-ui`** (auto) — kid-friendly, accessible SwiftUI conventions.
- **`forge-mission-feel`** (auto) — the **experience bar** for robotics missions + the 3D field: reactive models (the robot acts, a model visibly reacts) + 3D visual fidelity, with a hard Definition-of-Done. Complements `add-mission` (challenge design) and `field-3d.md` (3D tech).

## 🤖 Subagents (`.claude/agents/`) — delegate focused work here
- **engine-dev** — implements/tests the pure Swift beginner grid engine + interpreter.
- **robotics-engine-dev** — implements/tests the advanced robotics language + robot/world/mission simulator.
- **swiftui-dev** — builds SwiftUI screens (needs Xcode).
- **lesson-designer** — designs + verifies beginner lessons (follows `/add-lesson`).
- **mission-designer** — designs + verifies robotics missions (follows `/add-mission`).
- **ios-code-reviewer** — read-only review against the guardrails above (knows both tiers).

## Environment (as of setup)
**Swift 6.2 + git present, but only Command Line Tools — full Xcode NOT installed.** So the **engine builds/tests now** via `swift build` / `swift test`; the **SwiftUI app + `/scaffold-app` need full Xcode** (install from the App Store first). Build order: engine + interpreter (with tests) → lessons → app UI.

## Current status
**Beginner tier DONE & running.** `ForgeCodeEngine` engine + interpreter + content + **10 Code Basics lessons + 5 Challenges** (each verified). Full SwiftUI app scaffolded and running on the iOS 27 sim (Lesson Map, Lesson/Simulator with block+text, Badges, Build Log, Challenges, 3D Field Phase 1a). Full Xcode installed → stock `swift test` works.
**Robotics tier — R1 + content + Match layer + R2 DONE & reviewed (ship).** Pure-Swift **advanced tier** under `Sources/ForgeCodeEngine/Robotics/`: a real mini-language (variables, math/logic, if/while/for/repeat, functions + recursion, friendly errors, step budget) + robot/world/mission simulator (drivetrain, arm, gripper, sensors — a Spark-MAX-*flavored but original* action API) + `RoboticsRun` trace + mission scoring, all deterministic.
- **Content: 30 verified missions across 2 fields** — *Cargo Command* (`field_warehouse`) + *Mars Outpost* (`field_arena`), each a balanced 2/3/4/4/2 difficulty ladder (d1=10…d5=50 pts, 460 pts/field). Every mission ships a machine-verified solution + negative test; every diff-4/5 mission has **two** proven winning strategies. Briefs are **outcome-only** (Principle 1: never name the sensor/mechanism/route — the kid discovers it). Catalog: [robotics-missions.md](docs/robotics-missions.md); design bar: `.claude/skills/add-mission/design-principles.md`.
- **Match layer** — a real FLL-style round: one program, run once, scores a curated set of a field's missions at once, on a **move/energy budget** ("time", deterministic), with **6 precision tokens** (×10 = 60 pts; `returnHome()` rescues a stuck rover to base for −1 token; collisions block-and-continue in matches). `RoboticsSimulator.runMatch → MatchRun/MatchResult`. 1 seed match per field.
- **R2 UI DONE** — playable **Robotics Match screen** (`App/Features/Robotics/`): SceneKit continuous-coordinate field (zones/obstacles/items/lines + robot with animated arm/gripper), code editor + Run → plays the `MatchRun` back, live token-pip + move-budget HUD, per-mission + token match scoreboard. Wired into the Robotics tab. Screenshot-verified on the iPhone 17 sim.
- **R2.5 — reactive mechanisms + attachments + precision ladder + single-mission play (DONE).** Robot **attachments** (`.reachExtender`/`.fineHook`/`.launchTool`, gate mechanisms + extend reach); new mechanism kinds **`.launcher`** (rocket blasts off) + **`.excavator`** (`gripperPull` — pull a buried sample) with 3D reactions; 3 new **difficulty-laddered** Mars missions (d3 Signal Rocket → d5 Precision Gauntlet, tight trigger radii / 7cm pose) that teach *critical thinking* — deliberately spanning easy→brutal. New **`RoboticsMissionView`** single-mission screen with an **attachment picker** + **start-pose control** (place the rover anywhere in base at any heading — `FieldWorld.homeArea`/`clampToHomeArea`); Robotics tab lists a curated Challenge-Missions ladder above Season Matches. Screenshot-verified on iPhone 17 sim.
- **R2.6 — Cargo Command reactive parity (DONE).** Warehouse brought up to the Mars `forge-mission-feel` bar: **3 warehouse-styled reactive mechanisms** — a **roll-up bay door** (gate lifts on its rails), a ribbed **dock-leveler ramp** (platform), and a yellow/black **release lever + roller chute** — reusing the existing engine kinds (no new grammar). **4 difficulty-laddered warehouse missions** (d2 *Open the Bay* → d5 *Warehouse Gauntlet*), each with a machine-verified solution + negative test. Cargo Season Match now includes *Open the Bay* (6 missions, mirroring Mars); both fields' reactive ladders surface in the Challenge-Missions list. Screenshot-verified on iPhone 17 sim (`WarehouseMechShot` UITest → *Open the Bay* plays 25/25 in-app; multi-launch Mars match also re-verified via `RoboticsMatchShot`).
- **R2.7 — Real driving motion + match screen setup parity (DONE).** `RoboticsFieldScene.play()` fully rewritten: distance-proportional drive duration (14 units/sec, clamped 0.22–1.4 s/frame), angle-proportional turn duration (240 deg/sec), arm + wheels synced per frame. Teleport reserved only for genuine `returnHome()` events (detected via `SensorEventKind.returnHome` in sensorLog). Start-pose + attachment picker now gated on `runState == .idle || .launched` on the match screen (was always-visible).
- **407 tests green** via `swift test` (77 beginner + 330 robotics). Beginner tier untouched.
**Next up:** R3 block editor v2 (drag-drop block canvas for robotics tier, mapped to same AST as text); 100-challenge ladder in the Challenges tab (beginner grid puzzles d1→d5, animated heat-map cards, unlock burst, completion particles, streak bar); more season matches + progressive robotics lesson track; R5 Mac Catalyst. Nice-to-have: richer 3D art; 2nd proven strategy per warehouse d4/d5. Update this line as the build progresses.

## Working agreement
Build engine-first and verify with tests before UI. Ask before generating large amounts of code if a requirement is ambiguous or would expand grammar/scope. When you make a technical decision, record it in the relevant `docs/` file (and here if it's a top-level decision) so future sessions don't re-litigate it.
