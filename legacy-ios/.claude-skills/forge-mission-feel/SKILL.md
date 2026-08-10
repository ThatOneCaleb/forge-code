---
name: forge-mission-feel
description: Use when designing, building, animating, or reviewing any ForgeCode robotics mission, mission mechanism, or the 3D Match/Field scene (RoboticsFieldScene, RoboticsMatchView) — the bar for how interactive and visually polished a mission must feel. Apply whenever a mission or the 3D field is created, changed, or judged "done."
---

## What This Skill Does

Sets the **experience bar** for ForgeCode robotics missions: how *interactive* and how *visually polished* a mission must feel before it ships. It is the missing third leg next to the two bars we already have —

| Bar | Skill / doc | Question it answers |
|---|---|---|
| **Challenge / design** | [`add-mission/design-principles.md`](../add-mission/design-principles.md) | Is it a good *problem*? |
| **3D tech** | [`docs/field-3d.md`](../../../docs/field-3d.md) | *How* do we render + rig it? |
| **Experience / feel** *(this skill)* | — | Does the robot *do something* and does a **model visibly react** — beautifully? |

Apply it whenever you touch a mission (`Sources/ForgeCodeEngine/Robotics/Content/`), a field mechanism, or the 3D scene (`App/Features/Robotics/`). It is **always-on** reference guidance.

## The bar (memorize this)

> **Every mission must feel like a competition mission model: the robot does something, and a model on the field visibly reacts — rendered as a believable, kid-legible 3D moment.**

Inspiration is competitive-robotics field challenges, **conceptual only**. Never copy or name any real season, mission, model, theme, mark, or product. Our worlds are ours (Cargo Command warehouse, Mars Outpost).

## Pillar 1 — Interactivity: reactive models

Our missions are already interactive on the *input* side (the robot drives, the arm lifts, the gripper grabs). What has been missing is the *output* side: **nothing on the field reacts.** That is the gap this pillar closes.

A **reactive model** is a field mechanism with all three of:
1. **An activation trigger** — the robot causes it: contact with the model, an arm push within its region, a gripper action, or delivery into it. (Not "the robot merely passes nearby.")
2. **A state change that affects scoring** — activating it is *why* points are earned; a drive-only program provably can't trigger it.
3. **An animated 3D response** — the model *moves*: a lever tips, a platform rises, a hatch flips open, a gate drops, a beacon lights. The reaction is the payoff the kid came for.

**Rule of the pillar:** anything past a trivial *drive-and-detect* mission ships **at least one reactive element.** A bare pickup/deposit is a legitimate interaction but is **not sufficient on its own** for a difficulty-3+ or "signature" mission — pair it with a model that reacts (the deposit *triggers* a bay door; the retrieved core *powers up* a console). Pick the reaction from the [archetype palette](interaction-archetypes.md).

Engine note: reactive models are represented by a field `Mechanism` + an `activateMechanism`-style objective whose activation is recorded in the run trace/snapshots so the 3D scene can animate it on the exact action frame. Keep the engine **pure/deterministic/tested** ([`forge-robotics`](../forge-robotics/SKILL.md)); the animation is a UI concern that *plays back* the trace, never re-simulates.

## Pillar 2 — Visual fidelity

The scene must read like a polished competition table at a glance. The current `RoboticsFieldScene` already establishes the floor for this (PBR + studio lighting + environment map + printed-mat texture + full-frame hero camera + the rover scaled up as the visible hero). Hold that line and extend it to mechanisms:

- **Full-frame hero framing** — the field fills the view; the rover is unmistakably the hero, never a distant speck.
- **Legible at a glance** — every zone, item, and mechanism is distinguishable by **shape + color + label**, not color alone (colorblind-safe; matches [`forge-ui`](../forge-ui/SKILL.md)).
- **Readable motion** — mechanism animations are **eased** (`.easeInEaseOut`), paced to be *seen* (~0.3–0.6 s), and clearly caused by the robot's action. No instant state pops, no jitter.
- **Materials match the world** — a mechanism looks like it belongs to Cargo Command (industrial, painted metal) or Mars Outpost (dusty, technical), reusing the scene's `pbrMaterial` + filmic palette helpers.
- **Reduce Motion** — every reaction has a graceful non-animated form (snap to final state, optional soft fade); never gate scoring or comprehension on motion.
- **Celebratory success** — completion fires the `forge-ui` feedback rules (celebration + haptic + scoreboard). Winning feels good; failure stays gentle.

## Choreography — the robot↔model beat

Interactions must read as a little four-beat story, timed so the cause is obvious:

1. **Approach** — rover drives to the model; arm/gripper visibly articulate as it prepares.
2. **Act** — the triggering action happens *at* the model (contact / arm push / gripper release), on a specific trace frame.
3. **React** — the model animates its response on that same frame window; carried items **ride the gripper**, deposit zones **light up**, levers **tip**, platforms **rise**.
4. **Feedback** — HUD/token/score update reflects it immediately; on final success, celebrate.

If a viewer watching the playback can't tell *what the robot did* and *what changed because of it*, the choreography fails — fix it before calling the work done.

## Definition of Done (HARD GATE)

A mission or 3D change is **not done** until every box is true. This gate is in addition to the challenge test in [`design-principles.md`](../add-mission/design-principles.md) — both must pass.

- [ ] **Reactive element present** — the mission ships ≥1 reactive model (trigger + scoring state-change + animation), unless it is an intentionally trivial difficulty-1 drive-and-detect.
- [ ] **Interaction reads in a still** — a single screenshot of the key moment makes the robot↔model cause-and-effect obvious.
- [ ] **Rover is the legible hero** — clearly visible, correctly resting on the mat, arm/gripper articulating.
- [ ] **Motion is eased + paced** — reactions are animated, not instant; caused-by-robot is unmistakable.
- [ ] **Reduce Motion path works** — the scene is fully understandable and scorable with motion off.
- [ ] **Success feedback fires** — celebration + score/scoreboard update on completion.
- [ ] **Engine stays pure** — new sim state is deterministic + covered by a passing test and a negative test (`swift test`).
- [ ] **Original-IP check** — no FLL/FIRST/LEGO/REV/season/product names in briefs, ids, art, comments, or tests; the brief still poses the *outcome only* (design-principles Principle 1).
- [ ] **Screenshot-verified on the sim** — captured via the `RoboticsMatchShot` UITest → `/tmp/r_screenshots` (or the match capture harness). Never claim it renders without a screenshot.

## How this skill relates to its siblings

- This skill = **experience / feel** (interactivity + fidelity).
- [`add-mission/design-principles.md`](../add-mission/design-principles.md) = **challenge / design** (is it a good problem, points, portfolios). A mission must pass *both*.
- [`docs/field-3d.md`](../../../docs/field-3d.md) = **3D tech**: rendering, the coordinate/heading mapping, and the **hero-asset drop-in** (`RoboticsHeroAssets`, `rover.usdz` / `prop_*.usdz` with procedural fallback).
- [`forge-ui`](../forge-ui/SKILL.md) = accessibility + feedback rules the fidelity pillar leans on.
- [`forge-robotics`](../forge-robotics/SKILL.md) = engine purity/determinism the reactive-model state must respect.

## Where to start

1. Pick the interaction(s) from [interaction-archetypes.md](interaction-archetypes.md).
2. Design the *problem* to the challenge bar (design-principles.md).
3. Model the reactive mechanism in the engine (pure + tested), recording activation in the trace.
4. Animate the reaction in `RoboticsFieldScene` (eased playback of the trace; Reduce-Motion fallback).
5. Run the DoD gate above and screenshot-verify before declaring it done.
