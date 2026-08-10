# Architecture, Tech Stack & Conventions — Forge Code

> Detail doc referenced by [CLAUDE.md](../CLAUDE.md). Covers the stack, folder layout, layering rules, coding conventions, and build/test commands.

## Tech stack & setup
- **Language:** Swift (latest stable), **SwiftUI** for all UI.
- **Minimum deployment target:** iOS **17.0** (enables SwiftData + Observation `@Observable`).
- **Xcode project:** app target + unit test target (+ optional UI test target). **Phone-first, portrait** (v1 is phone-only; just don't crash on iPad/landscape).
- **No third-party dependencies.** No CocoaPods, no analytics/crash SDKs. Apple frameworks only. The only local package dependency is `ForgeCodeEngine` (this repo's engine).
- **Persistence (decided — don't re-litigate):**
  - **Static lesson content** → bundled JSON, decoded via `Codable`. Content lives in data, not hardcoded in views.
  - **Mutable user data** (`Kid`, `Badge`, `BuildLogEntry`) → **SwiftData**.
  - **Photos** → written to the app's Documents directory; store the **filename/relative path** in SwiftData, never the raw image blob.
  - **Engine + interpreter must NOT depend on SwiftData, SwiftUI, or the file system** — plain Swift value types, unit-testable in isolation.
- **Privacy:** no data leaves the device. App Privacy questionnaire → "no data collected." `PhotosPicker` needs no photo-library permission prompt for read-only selection.

## Repo layout (current)
The engine ships as a **pure SwiftPM package at the repo root**, testable now via `swift test`. The Xcode app (added later) consumes it as a local package.

```
Forge Code/
├─ CLAUDE.md                         // lean always-on overview + doc map
├─ docs/                             // detailed reference (this folder)
├─ Package.swift                     // ForgeCodeEngine package manifest
├─ Sources/ForgeCodeEngine/          // PURE Swift — no SwiftUI/SwiftData/UIKit
│  ├─ Geometry.swift                 // Position, Direction
│  ├─ Grid.swift
│  ├─ RobotState.swift
│  ├─ Command.swift                  // Command AST + CommandKind + Program
│  ├─ Challenge.swift
│  ├─ ExecutionResult.swift          // FailureReason, ExecutionOutcome, frames
│  ├─ Simulator.swift
│  ├─ Interpreter/                   // Token, Lexer, Parser, ParseError, CodeRenderer
│  └─ Content/                       // Lesson, LessonLibrary, code_basics.json
├─ Tests/ForgeCodeEngineTests/       // the critical suite (engine + interpreter + lessons)
└─ (later, needs Xcode) ForgeCodeApp/
   ├─ App/                           // ForgeCodeApp.swift (@main, ModelContainer), RootView.swift
   ├─ Models/                        // Kid, Badge, BuildLogEntry (@Model)
   ├─ Persistence/                   // LessonStore, ProgressService
   ├─ Features/                      // LessonMap, Lesson, Badges, BuildLog, Placeholders
   └─ Resources/                     // Assets.xcassets
```

## Layering rules
- **Engine layer** (`Sources/ForgeCodeEngine/`): zero imports of SwiftUI/SwiftData/UIKit. `import Foundation` only in the content loader (`LessonLibrary`). Deterministic value types.
- **Blocks and text compile to the same `Command`/`Program` AST.** One execution path (`Simulator`). Never build two parallel interpreters.
- **View layer** (`Features/`): views observe an `@Observable` view-model; they never touch the engine internals or the SwiftData `ModelContext` directly. The view-model calls the engine + services.
- **Service layer** (`Persistence/`): `LessonStore` loads content via the engine's `LessonLibrary`; `ProgressService` reads/writes `Kid`/`Badge` via `ModelContext`. Streak logic is a small testable function, not scattered in views.

## Coding conventions
- Follow Swift API Design Guidelines; match existing file style.
- `@Observable` view-models over legacy `ObservableObject`.
- Keep views small; **no game/engine logic in SwiftUI view bodies.**
- Value types (`struct`/`enum`) for engine + content; reference types only where identity or SwiftData requires it.
- Name for a domain reader; comments explain *why*, not *what*.
- No force-unwraps in shipping paths; handle decode/parse failures with kid-friendly fallbacks.

## Build & test commands

**Engine package (works now — no Xcode needed):**
```bash
swift build
swift test        # run after every change to the engine; must stay green
```

**iOS app (requires full Xcode installed):**
```bash
xcodebuild -scheme ForgeCode -destination 'platform=iOS Simulator,name=iPhone 16' build
xcodebuild -scheme ForgeCode -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## Environment constraint (as of setup)
- Machine has **Swift 6.2 + git**, but only **Command Line Tools — full Xcode is NOT installed.**
- So: the pure engine + interpreter build/test now via SwiftPM. The **SwiftUI/SwiftData app and any `.xcodeproj`/simulator work require full Xcode** — install it from the App Store before that phase.
