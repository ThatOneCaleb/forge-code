---
name: add-mission
description: Use when someone asks to add a robotics mission, create an FLL-style challenge, author a field mission, or design a robot task with the arm/gripper/sensors for ForgeCode's robotics tier.
argument-hint: [concept] e.g. "arm-pickup" or "line-follow-deposit"
disable-model-invocation: true
---

## What This Skill Does

Authors a new **robotics mission** for ForgeCode's advanced tier end-to-end: a field world (objects/zones/obstacles), scored objectives, a **verified** solution program in the robotics language, and a passing test that proves the mission is solvable and scores as intended. **Never ship a mission that hasn't been proven solvable + correctly scored by the simulator.**

Read the `forge-robotics` skill, [docs/robotics-engine.md](../../../docs/robotics-engine.md), **and [design-principles.md](design-principles.md) (required — the innovation bar: strategy portfolios, risk/reward geometry, multiple routes, sensor techniques, anti-patterns)** before starting. **Experience bar (required too): [`forge-mission-feel`](../forge-mission-feel/SKILL.md)** — reactive models (the robot acts, a model visibly reacts) + 3D fidelity + its Definition-of-Done gate. Missions live in `Sources/ForgeCodeEngine/Robotics/Content/robotics_missions.json`, decoded into `Mission`/`FieldWorld` and run by `RoboticsSimulator`.

## Inputs
- `$1` = the mission concept/skill it teaches (e.g. `arm-pickup`, `line-follow`, `sensor-sort`, `multi-objective`). If missing, ask the user for the concept and difficulty.

## Coordinate + model rules (must match the engine)
Continuous field: `Vec2(x,y)` in cm, origin at a documented corner; `Pose` = position + `headingDegrees`. The robot drives by distance and turns by degrees (action-based, deterministic). Sensors read the `FieldWorld` at call time. See `forge-robotics` for the API surface.

## Steps
1. **Confirm intent.** Restate the concept, target difficulty (advanced-elementary → high-school), and where it fits (mission order/track). Pick a stable `id`.
2. **Design the world.** Field size; robot start `Pose`; place items (pickable), deposit/target zones, obstacles/walls, lines, colored regions. Choose which mechanisms the mission *requires* (drivetrain, arm, gripper, specific sensors) so it teaches the concept.
3. **Define objectives + scoring.** List `Mission` objectives (e.g. pick up item A, deposit at zone Z, detect red, reach pose) with points and the success rule. Keep scoring unambiguous.
4. **Write the canonical solution program** in the robotics language (using the real API), then **run it mentally/step-by-step in your report**, confirming it completes the objectives, doesn't collide/leave the field, and stays within the action/step budget.
5. **Author the mission JSON** in `robotics_missions.json`, matching the existing schema exactly.
6. **Add a test** in `Tests/ForgeCodeEngineTests/Robotics/`: parse the canonical solution with the robotics parser, run it through `RoboticsSimulator` against the mission's world, and assert the `MissionResult` = success with the expected objectives met + score. Add at least one negative case (e.g. skipping the pickup) asserting the expected lower score / failure.
7. **Run `swift test`** and confirm green (new + existing suites). If the simulator disagrees with your reasoning, trust the engine, fix the design, re-run.
8. **Report**: the mission id/title, world summary, objectives + scoring, the verified solution program, **Strategy notes** (the intended insight, ≥1 alternate approach + trade-off, point-value rationale — see design-principles.md), and the `swift test` result.

## Notes / guardrails
- **Never add a mission without a verified solution + passing test.** Solvability + correct scoring are non-negotiable.
- Make the required mechanisms the *point* of the mission (don't let a trivial drive-only path score full points if the mission is about the arm/sensors).
- **Original + FLL-*inspired* only** — no FLL/FIRST/LEGO/REV names, themes, art, or mission reproductions. Invent our own themes.
- Don't invent new API/grammar just for a mission — if a mission needs a capability the engine lacks, STOP and confirm with the user (that's a `forge-robotics` engine change, not content).
- Engine-only; testable with `swift test` (no Xcode needed).
