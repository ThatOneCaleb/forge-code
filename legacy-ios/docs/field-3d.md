# 3D Field Mode — "Field Missions" (major feature, phased)

> Design doc for the 3D **FLL-inspired** field mode. Referenced by [CLAUDE.md](../CLAUDE.md). This is a big, multi-phase feature added *after* the 2D core loop shipped. Build it in slices; keep each slice compiling and screenshot-verified.

## Vision
A **3D simulated field** the kid programs a robot to drive across, completing **missions** for points — the feel of **FIRST LEGO League** (season-themed mats + mission models), but with **original, "FLL-inspired" themes and art** (NOT reproductions of real FLL/FIRST/LEGO designs). Same block/text coding paradigm as the rest of the app.

## Decisions (confirmed with user)
- **Go for real 3D** (not just 2D themed).
- **Original FLL-inspired fields only** — do NOT copy actual FLL seasons, field art, mission models, or the FLL/FIRST/LEGO marks. This keeps App Store release safe. Each "season" is our own themed world (e.g. "Reef Rescue", "Sky Harbor") with our own mission set.

## Tech
- **RealityKit via `RealityView`** (SwiftUI, iOS 18+; we target iOS 17 but gate the 3D screen to iOS 18+ / feature-flag). Renders in the iOS Simulator on Apple Silicon (Metal). **Fallback: SceneKit** (`UIViewRepresentable`) if RealityKit rendering in the sim proves unreliable — the agent picks whichever reliably renders + screenshots.
- **No third-party packages.** Field + robot + mission markers built from primitive geometry / our own USDZ or programmatic meshes. Kid-safe, on-device, no networking.

## Architecture (reuse the tested engine)
- **Keep `ForgeCodeEngine` as the logic core.** Phase 1 reuses the existing `Challenge`/`Simulator` (grid + the five commands) and just renders it in **3D** — the robot's `ExecutionResult.frames` (grid cells + facing) map to 3D world transforms. No engine rewrite to get a 3D field on screen.
- **Missions (Phase 2 engine extension):** add a `Mission` model to the engine — multiple objective zones (ordered or any-order), each worth points; success = objectives met within block/step budget. Still the five commands, still pure/deterministic/tested. This is what makes it feel FLL-hard.
- Coordinate mapping: engine grid `(x,y)` → world `(x, 0, -y)` (y-up world, field on X/Z plane); facing → Y-rotation. Reuse the same frame-playback pattern as the 2D `SimulatorViewModel`.

## Phases
- **Phase 1a — 3D renders (first slice):** `Field3DView` shows a themed rectangular mat, grid reference, obstacles, goal marker, and a **robot entity that animates through `ExecutionResult.frames` in 3D**. A standalone preview screen loads a challenge, hit Run → robot drives in 3D. *Goal: prove the 3D tech + playback, screenshot it.*
- **Phase 1b — Field track in-app:** a "Field" tab/section listing 3D field challenges; tapping opens the 3D field with the block/text editor driving it (reuse the editor from `LessonView`).
- **Phase 2 — Missions + scoring:** engine `Mission` model (multi-objective + points), a scoreboard, several missions per themed field. This delivers the FLL-style difficulty.
- **Phase 3 — More seasons + richer robot:** additional original themed fields; optionally a continuous-movement/sensor model (would extend the command set — a deliberate, separate scope decision, do NOT do implicitly).

## Hero-model assets (hybrid visual direction — robotics Match field)
The robotics **Match** field (`App/Features/Robotics/RoboticsFieldScene.swift`) renders with high-fidelity **procedural** SceneKit geometry (full PBR + HDR/bloom/SSAO + environment map + procedural mat/wood textures). Per the user's **hybrid** decision (see memory `robotics-3d-visual-direction`), it also supports **bundled USDZ "hero" models** for extra detail, loaded via `RoboticsHeroAssets` with **graceful procedural fallback** — no code change needed to adopt one.

Drop-in convention (`RoboticsHeroAssets.swift`):
- Place `.usdz` / `.usdc` / `.scn` files in the app bundle, either in a `RoboticsHeroModels/` folder reference or loose (both searched).
- **Rover:** `rover.usdz`. Rig it facing local **−Z** (forward = north), ~0.6–0.7 units wide (auto-fitted on import). For arm/gripper articulation during playback, include a child node named **`ArmPivot`** (rotates on local X) and, under it, **`GripperPivot`** whose first two child nodes are the jaws (local X nudged to open/close). Missing rig names → model still drives, articulation just stays static.
- **Props:** `prop_<type>.usdz` (e.g. `prop_crate`, `prop_sample`, `prop_barrel`, `prop_core`), auto-fitted to pickable size.
- **Licensing/safety (hard):** kid-safe + properly licensed for the App Store kids category, original / FLL-*inspired* only — no FLL/FIRST/LEGO/REV IP. This is the only sanctioned amendment to "no external assets."

## Guardrails carried forward
- Kid-safe: no networking/accounts/analytics/IAP/third-party SDKs.
- Original art/themes only — no FLL/FIRST/LEGO IP.
- Engine stays pure/deterministic/tested; 3D lives in the app layer.
- Don't expand the interpreter grammar without explicit sign-off (Phase 3 note).

## Verification
Each slice: build for the iOS Simulator SDK, run on a booted sim, and **screenshot** the 3D field (via UI test attachment + `xcresulttool export`, the pattern already used for 2D screens). Don't claim it renders without a screenshot.
