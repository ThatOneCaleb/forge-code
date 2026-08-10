# Screens & Core Loop — Forge Code

> Detail doc referenced by [CLAUDE.md](../CLAUDE.md), the `forge-ui` skill, and the `/scaffold-app` skill. Requires full Xcode to build/run.

## Core user loop
Lesson Map → tap next unlocked lesson → intro + goal shown → simulator workspace (block palette **or** text editor, toggle between them) → **Run** → robot animates step-by-step → **success** (badge + streak update, prompt to add a build log entry) **or retry** → back to the map with the next lesson highlighted.

## Screens (build in this order)
1. **Lesson Map** — Code Basics as a path of lesson nodes, locked/unlocked from `completedLessonIDs`. Access to Robotics Concepts (placeholder), Badges, and Build Log from here (tabs or nav).
2. **Lesson / Simulator** — *the priority screen.* Intro text + goal; block palette + grid view; **mode toggle (block ↔ text)**; **Run** button; success/fail state; **Hint** button. Make the grid render clearly and the animation smooth. The Run animation is **playback of the engine's `ExecutionResult.frames`** at a readable per-step pace.
3. **Badge Shelf** — grid of earned badges; locked/greyed placeholders for unearned ones.
4. **Build Log** — list of entries (date, note, photo thumbnail if present) + an **Add Entry** screen (text field, `PhotosPicker`, tag picker). Always accessible; **not tied to lesson progression**.

**Placeholders:** Robotics Concepts, Mentor, Parent — each a simple "Coming soon" screen. No real functionality.

## UX & accessibility (see the `forge-ui` skill for the full checklist)
- **Big touch targets** (≥44pt), generous spacing, high contrast — for kids on shared/older devices.
- **Dynamic Type** support (layouts reflow, no clipping) and **VoiceOver** labels on every interactive control (grid, robot, blocks, Run).
- **Color is never the only signal** — pair with icon/text/shape. Respect Reduce Motion.
- **Success = celebratory** (animation + haptic), then a gentle prompt to add a Build Log entry.
- **Failure = gentle + actionable:** never "wrong". Show the engine's `FailureReason.message` or interpreter's `ParseError.message`, always offer **Try again** + **Hint**.

## Architecture boundary (see [architecture.md](architecture.md))
- Views observe an `@Observable` view-model; **no engine/game logic in view bodies.**
- The view-model calls the pure engine (`Simulator`, `Parser`, `CodeRenderer`) and services (`ProgressService`, `LessonStore`). Views never touch `ModelContext` directly.
- **Block ↔ text toggle** shows two views of one `Program`: to text via `CodeRenderer`, to blocks via re-parse; preserve the kid's work on a parse error.
