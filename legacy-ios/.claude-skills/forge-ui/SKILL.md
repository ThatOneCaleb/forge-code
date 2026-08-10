---
name: forge-ui
description: Use when building or changing any Forge Code SwiftUI screen or component — the Lesson Map, simulator/grid view, block palette, code editor, Badge Shelf, Build Log, add-entry form, or placeholder screens. Apply when working under the app's Features layer.
---

## What This Skill Does

A skill for building **kid-friendly, accessible, reliable** SwiftUI in Forge Code. Apply whenever creating or editing views/components (the `Features/` layer). It encodes the conventions below plus the product's "works in a room full of kids" constraint (differentiator #4). Full detail in [docs/screens.md](../../../docs/screens.md).

## Concrete component patterns → [patterns.md](patterns.md)
Before building the Lesson/Simulator screen (grid + robot, block palette, code editor, run/animation, result overlay) or the Lesson Map, **read [patterns.md](patterns.md)** in this skill folder — it has adaptable SwiftUI sketches wired to the real `ForgeCodeEngine` types, including the **critical engine→screen Y-coordinate flip** (engine is +y up; SwiftUI is +y down) and the animation-playback view-model. Adapt them; don't paste blindly.

## Audience & tone
Users are **kids ages ~8–15**, often in a mentor-led session, sometimes with no robot. UI must be legible, forgiving, and encouraging. Never punishing, never jargon-y.

## Interaction & accessibility rules
- **Big touch targets** (≥ 44pt), generous spacing, high contrast. Assume small hands and shared/older devices.
- **Support Dynamic Type** — no fixed font sizes that clip; layouts reflow. Test at large accessibility sizes.
- **VoiceOver labels** on every interactive control (`.accessibilityLabel`, meaningful values). The grid, robot, blocks, and Run button all need clear labels.
- **Color is never the only signal** — pair color with icon/text/shape (colorblind-safe).
- Respect **Reduce Motion**: keep success animations celebratory but degrade gracefully.

## Feedback rules (the emotional core)
- **Success = celebratory:** animation + haptic (`.success` feedback), badge/streak update, then a gentle prompt to add a Build Log entry. Make winning feel good.
- **Failure = gentle + actionable:** never "wrong". Show the friendly reason (from the engine's `FailureReason.message` or interpreter `ParseError.message`), always offer **Try again** and the **Hint** button. Failure is a normal step, not a dead end.
- **Text-mode errors** use the interpreter's kid-friendly messages verbatim; never surface raw parser output.

## Architecture rules (match CLAUDE.md §5, §11)
- **No engine/game logic in view bodies.** Views observe an `@Observable` view-model; the view-model calls the pure engine (`Simulator`, `Parser`, `CodeRenderer`). Views render state and play back the engine's `frames` trace.
- Views never touch the SwiftData `ModelContext` directly — go through a service (`ProgressService`). Keep views small and composable.
- The **Run animation is playback** of `ExecutionResult.frames`, stepped at a readable pace (not too fast). Timing is a UI concern; the trace comes from the engine.
- **Block ↔ text toggle** shows two views of one `Program`. Toggling to text uses `CodeRenderer`; toggling to blocks re-parses. Preserve the kid's work on a parse error.

## Design defaults
- Phone-first, **portrait** (v1 is phone-only — don't invest in iPad/landscape, just don't break).
- Prefer system components and SF Symbols; keep a small, consistent palette. Distinctive but calm — this is a learning tool used repeatedly, not a one-off landing page.
- Photos in Build Log use `PhotosPicker` (no permission prompt for read-only selection); store the file in Documents and keep only the path in SwiftData.

## Guardrails
- **No networking, no third-party SDKs, no analytics** in any view (privacy: no data collection). If a screen seems to need the network, stop — it's out of MVP scope.
- Robotics / Mentor / Parent screens are **"Coming soon" placeholders only** — do not build their real functionality.
- Don't hardcode lesson content in views; content comes from `Lesson`/`LessonLibrary`.
- Requires **full Xcode** to build/run (SwiftUI + iOS simulator). If only Command Line Tools are installed, you can write the code but flag that it can't be compiled/previewed until Xcode is installed.

## When building a screen
1. Define/extend an `@Observable` view-model that exposes state + intents and calls the engine/services.
2. Build the view from small subviews; wire accessibility labels as you go.
3. Handle the three states explicitly: idle/working, success, failure(+hint).
4. Check Dynamic Type (largest size) and VoiceOver before considering it done.
