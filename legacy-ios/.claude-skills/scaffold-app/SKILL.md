---
name: scaffold-app
description: Use when someone asks to scaffold the Forge Code iOS app, create the Xcode project, set up the SwiftUI app target, wire up SwiftData models and navigation, or stand up the initial screens. Requires full Xcode installed.
argument-hint: (no args) — run once to create the app target
disable-model-invocation: true
---

## What This Skill Does

Scaffolds the **Forge Code** iOS SwiftUI app target that consumes the pure `ForgeCodeEngine` package: SwiftData models, app entry + navigation, and the four MVP screens plus three placeholders. This is the phase that turns the tested engine into a runnable app.

Read `CLAUDE.md` §4 (tech stack), §5 (folder structure), §9 (data models), §10 (screens) before starting.

## PRECONDITION — check first
- **Full Xcode must be installed.** Verify: `xcodebuild -version`. If it errors with "requires Xcode, but active developer directory is a CommandLineTools instance", **STOP** and tell the user to install Xcode from the App Store and run `sudo xcode-select -s /Applications/Xcode.app`. Do not attempt to hand-generate a `.xcodeproj`.
- The **engine package must build and its tests pass** (`swift test`) before wiring UI on top of it. If it doesn't, fix the engine first (see `forge-engine` skill).

## Target configuration
- iOS **17.0** minimum, SwiftUI lifecycle, Swift latest.
- **Phone-only, portrait** for v1 (don't configure iPad/landewscape beyond not crashing).
- Product/display name **"Forge Code"**; bundle identifier and code identifiers use `ForgeCode`.
- **No third-party dependencies.** The app depends only on Apple frameworks + the local `ForgeCodeEngine` package.

## Steps

1. **Verify precondition** (Xcode present, engine tests green). Report and stop if not met.
2. **Create the app target** (`ForgeCode`) with a unit test target, and add the local `ForgeCodeEngine` package as a dependency of the app.
3. **SwiftData models** (`Models/`) per CLAUDE.md §9 — `Kid`, `Badge`, `BuildLogEntry` as `@Model` (single-profile). Set up the `ModelContainer` in `ForgeCodeApp`. Photos stored in Documents; store only the filename in `BuildLogEntry`.
4. **Services** (`Persistence/`): `LessonStore` (loads lessons via the engine's `LessonLibrary`) and `ProgressService` (reads/writes `Kid` progress, badges, streak via `ModelContext`). Put streak logic in a small testable function, not in views.
5. **Navigation** (`App/RootView.swift`): tabs or nav for Lesson Map, Badges, Build Log, and placeholders.
6. **Screens** (`Features/`) — build in this order, applying the `forge-ui` skill for every one:
   1. **Lesson Map** — Code Basics as locked/unlocked nodes from `completedLessonIDs`.
   2. **Lesson / Simulator** — intro + goal, block palette + grid view, **block↔text toggle**, Run (plays `ExecutionResult.frames`), success/fail, Hint. This is the priority screen.
   3. **Badge Shelf** — earned badges + greyed placeholders.
   4. **Build Log** — list + Add Entry (text, `PhotosPicker`, tag).
   7. **Placeholders** — Robotics Concepts, Mentor, Parent: simple "Coming soon" screens only.
7. **Build & run** on an iPhone simulator; verify the core loop end-to-end (map → lesson → run → success → badge/streak → back to map). Use the `/run` or `/verify` skills to confirm behavior.
8. **Report** what was created, how to open/run it, and the state of the core loop.

## Guardrails
- Do NOT build Mentor/Parent/Robotics functionality — placeholders only (CLAUDE.md §2).
- Do NOT add networking, accounts, analytics, IAP, or AI features.
- Keep engine logic in the package; the app only renders state and calls the engine/services (no game logic in view bodies).
- Model `Kid` progress/badges/log as cleanly queryable data so the future mentor/parent visibility layer (differentiator #1) is easy to add later.
- If any step needs a scope decision beyond the MVP, stop and ask the user.

## Notes
- The engine package already lives at the repo root (`Sources/ForgeCodeEngine`, `Tests/ForgeCodeEngineTests`) and is buildable via `swift test`. The Xcode app references it as a local package dependency; do not duplicate engine code into the app target.
