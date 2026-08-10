# Data Models — Forge Code

> Detail doc referenced by [CLAUDE.md](../CLAUDE.md). Static content = `Codable` value types (in the engine package). Mutable user data = SwiftData `@Model` (in the app).

## Engine / content models (Codable value types, `Sources/ForgeCodeEngine/`)
- **`Position`** — `x: Int, y: Int`. `Hashable`, `Codable`.
- **`Direction`** — enum `up | down | left | right` (raw strings). Turn + delta helpers.
- **`Grid`** — `width`, `height`, `obstacles: Set<Position>`.
- **`RobotState`** — `position: Position`, `facing: Direction`.
- **`Command`** — indirect enum: `move`, `turnLeft`, `turnRight`, `repeatBlock(count, body)`, `ifWallAhead(body)`. `Program` = `[Command]` + `blockCount`. *(The AST is `Equatable`/`Sendable` but intentionally NOT `Codable` — it's never serialized; only `CommandKind` is, via `Challenge.allowedCommands`.)*
- **`Challenge`** — `grid`, `start: RobotState`, `goal: Position`, `allowedCommands: [CommandKind]`, `maxBlocks: Int?`.
- **`Lesson`** (`Codable`, static content) — `id`, `track`, `order`, `title`, `introText`, `goalDescription`, `challenge`, `hintText: String?`.

## App / user models (SwiftData `@Model`, added with the app target)
- **`Kid`** — `id`, `name`, `ageBand`, `joinedDate`, `completedLessonIDs`, `earnedBadgeIDs`, `currentStreak`, `lastOpenedDate`. **MVP: a single local kid; no multi-profile.**
- **`Badge`** — `id`, `lessonID`, `kidID`, `dateEarned`, `track`.
- **`BuildLogEntry`** — `id`, `kidID`, `date`, `noteText`, `photoFilename: String?`, `tag` (`coding` | `robotics` | `other`).

## Rules
- **Photos:** the image file is written to the app's Documents directory; only the **filename/relative path** is stored in `BuildLogEntry.photoFilename`. Never store raw image blobs in SwiftData.
- **Streak logic:** update `currentStreak` from `lastOpenedDate` (consecutive calendar days). Keep it a **small testable function**, not scattered across views.
- **Forward-compat (differentiator #1):** model a kid's progress/badges/log as cleanly queryable data so a future mentor/parent visibility layer can read/share it. Don't bury state in view-local state.
- **Persistence split:** static lessons load from bundled JSON via the engine's `LessonLibrary`; user data lives in SwiftData. The engine never imports SwiftData.
