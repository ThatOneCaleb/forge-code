# Learnings — Forge Code (kids coding game)

A candid retrospective captured before pivoting to a new direction. The goal: keep the reusable knowledge and avoid repeating the mistakes.

## What this app was
A free iOS/SwiftUI coding-and-robotics learning game for kids ~8–15 (STEM Greenhouse pilot). Kids solved grid/rover puzzles by snapping block code (FLL/SPIKE-style) or text. It grew a pure-Swift engine (beginner grid + advanced robotics tier), a block editor, procedurally difficulty-scaled challenges, and a "Forge Academy" base-building meta-layer.

## The core lesson (most important)
**A coding-puzzle app is not a *game* until it has juice + a reward loop + heart. We built deep mechanics before establishing a fun hook, and the result was mechanically rich but "boring."**

Order that would have worked better:
1. **Prove the fun first.** One tiny loop with real juice (satisfying feedback, sound, celebration) + a reason to care (a character/goal) — validate that *solving feels good* before building 100 challenges or a second engine tier.
2. Then deepen mechanics only in service of that validated fun.

Corollaries we learned the hard way:
- **Engagement can't be retrofitted onto dry puzzles.** "Navigate a robot to a goal" is inherently flat without juice, variety, and stakes. We kept polishing mechanics while the user kept (correctly) saying "boring" — the missing thing was the *game wrapper*, not more block features.
- **Block richness must match what the simulated world can actually do.** FLL SPIKE has 50–100+ blocks because it drives a real robot (motors, lights, sound, hub display, sensors). A simple tile-rover sim only supports ~15–20 meaningful behaviors. Promising a 50-block SPIKE clone on that engine would mean dozens of fake/no-op blocks — bad for kids. Match the palette to the world (or expand the world first).
- **Faithfully "bridging" a gentle beginner curriculum keeps it easy.** Difficulty (and fun) must be *designed*, not inherited.
- **Iterating "make X better" without a validated core = churn.** Many rounds of block/field/difficulty tweaks never fixed the real problem.

## What worked well (keep doing)
- **Pure, dependency-free, test-first engine.** `swift test` gave fast, reliable iteration (600+ tests). Keeping game logic out of SwiftUI paid off constantly.
- **Deploy to a real device early.** The moment it was on the user's iPhone, feedback got sharper and honest ("this feels flat"). Do this in the first hour of any app.
- **SwiftUI shape-art (no external assets).** Characters, blocks, academy modules, robot — all built from `Path`/`Shape`. Fast, tweakable, no asset pipeline.
- **The "world that grows" (academy) was the first thing that felt like a game** — a home base that fills in as you earn stars. Meta-progression gives every reward a destination. Lead with this kind of loop next time.

## Reusable tech assets (portable to the next app)
- **On-device deploy recipe (free Apple ID):**
  - `project.yml` carries `CODE_SIGN_STYLE: Automatic`, `CODE_SIGN_IDENTITY: "Apple Development"`, `DEVELOPMENT_TEAM: <teamID>` so `xcodegen generate` doesn't wipe signing.
  - Device build: `xcodebuild -project X.xcodeproj -scheme X -configuration Debug -destination 'id=<ECID>' -allowProvisioningUpdates build`
  - Install/launch: `xcrun devicectl device install app --device <UDID> <App.app>` then `xcrun devicectl device process launch --device <UDID> <bundleid>`
  - Developer Mode toggle on the phone only appears *after* Xcode first talks to the device. Free-signed apps need the user to Trust the developer cert once (Settings → General → VPN & Device Management), and expire after 7 days.
  - Orientation & Info.plist are generated from `project.yml` (`info.properties`) — edit there, not `App/Info.plist`.
- **Juice kit** (`App/Features/Challenges/ChallengeJuice.swift`): `SFX` (system sounds via AudioToolbox), `Confetti`, `CelebrationOverlay`, `BuildBurst`, plus haptics (`UINotificationFeedbackGenerator`, `UIImpactFeedbackGenerator`). Drop-in game feel with zero assets.
- **Block editor architecture** (if any future app needs blocks): `ForgeBlockKit` (puzzle-connector `Shape`s, C-blocks, hex booleans), an index-path tree model for nesting, drag-to-reorder via measured frames + a `PreferenceKey`, and a "serialize blocks → language text" bridge so blocks and text share one execution path.
- **2D board renderer** (`ChallengeBoardView`): a clean SwiftUI `Canvas` tile board with an animated sprite driven by `withAnimation` through snapshot poses — much simpler/prettier than SceneKit for a grid game, and no lighting-glare problems.
- **Robotics engine** (`Sources/ForgeCodeEngine/Robotics/`): a real mini-language (lexer/parser/AST/interpreter, variables, if/while/for, functions) + a deterministic robot/world/mission simulator with sensors and scoring. Solid if a future app wants real programmable simulation.

## Engagement principles (from research, worth reusing)
- **Juice / game feel:** every action → instant satisfying sensory feedback (particles, sound, squash/stretch, screen response). This is the difference between a toy people love and one they abandon.
- **Layered reward loops:** a *core loop* (moment-to-moment), a *meta loop* (a world/collection that grows), and a *social/competitive loop*. Small rewards every 30–90s, big ones every ~10 min.
- **Flow:** difficulty tuned to just-right; scattered, not monotonic.
- **Heart:** characters and a world with personality (codeSpark's Foos, Kodable's fuzzballs) are what actually entrance kids — and clever writing is what pulls adults in.

## Current code state at pivot
- App builds and runs on device up through the "academy + juice" work, EXCEPT: a mid-refactor of the SPIKE-style Move/Turn blocks was left unfinished (`RBlock.move(dir,amount,unit)` / `.turn(dir,degrees)` model exists, but the inline dropdown views `MoveBlockView`/`TurnBlockView` were not built, and `MoveUnit` was just expanded) — so the project is temporarily non-compiling on that path. Nothing here is worth finishing given the pivot; noted only so it isn't mistaken for a bug.
- 605 engine tests pass except one pre-existing stale content-count assertion (`LessonLibraryTests.swift:288`), unrelated to any of this work.
