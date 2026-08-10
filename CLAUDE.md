# CLAUDE.md — Forge Code (web)

An **Advent-of-Code-style coding-challenge game** for the browser, split into **two
independent tracks**:
- **Academy** (`/academy`) — a **story-free "learn to code"** track: a lesson before every
  easy practice challenge (difficulty ≤ 3). For brand-new coders and kids.
- **Gauntlet** (`/gauntlet`) — the **story campaign** (all acts, difficulty ≥ 4), ramping
  from tricky to Advent-of-Code-brutal, with **per-player generated inputs** and optional
  "technique" lessons.

The two tracks share nothing structurally (separate paths + progress); stars, streak, and
profile are shown across both. Plus a ranked-ladder stub.

> Guiding lesson (from the abandoned iOS app, see `docs/LEARNINGS.md`): prove one
> tiny loop is genuinely fun and get it on screen fast, then build depth.

## Stack
- **Vite + React + TypeScript**, Tailwind v4, React Router, Zustand (persisted to `localStorage`).
- **Code runs client-side in Web Workers**: JavaScript (native) + Python (Pyodide from CDN). No backend.
- Editor: CodeMirror via `@uiw/react-codemirror`. Motion: Framer Motion. Juice: `canvas-confetti`.
- Look: **"Molten Terminal"** — Chakra Petch / IBM Plex Sans / JetBrains Mono, ember-on-iron theme.

## The contract
Every challenge asks the player to define **`solve(text)`** — `text` is the puzzle input
string; the return value (stringified) is compared to `expected` after normalization. Same
contract in both languages.

## Per-player puzzles (Advent-of-Code style)
Hard challenges give **each player a unique input** via an optional `generate(rng)` that
returns `{ input, expected }`, seeded stably per player (`playerSeed:challengeId`,
`src/engine/rng.ts`). The generator computes the answer as it builds the input. The static
`input`/`expected` on a challenge are the **worked example** shown in the prompt. Never
hardcode a generated answer; never commit large static inputs (generate at runtime).

## Architecture (engine-first — keep the core pure & framework-free)
- `src/engine/types.ts` — `Challenge`, `Lesson`, `PathItem`, `PuzzleInstance`, `RunResult`, `GradeResult`, `Language`.
- `src/engine/rng.ts` — seeded PRNG (`makeRng`, `puzzleRng`, `hashSeed`).
- `src/engine/runner/` — `pythonWorker.ts`, `jsWorker.ts`, `index.ts` (`runCode` + 10s timeout), `grade.ts` (pure compare).
- `src/engine/progress/` — `path.ts` (unlock/next over lessons+challenges), `ladder.ts` (challenge-only helpers), `streak.ts`, `store.ts` (Zustand + persist: solved, readLessons, playerSeed, streak, drafts).
- `src/content/` — `challenges.ts` (`SPECS` ladder + `STORY_INTRO`), `lessons.ts`, `path.ts` (interleaves lessons before their anchor challenge), `skillTree.ts`, `leaderboard.ts`.
- `src/features/` — `home/ ladder/ challenge/ lesson/ compete/ profile/`. `src/components/` — Editor, OutputPanel, StreakBadge, DifficultyPill, Celebration, motion helpers.

## Tracks & paths
- Each `Challenge` has a `track` set by difficulty in `src/content/challenges.ts`: **`difficulty ≤ 3 → academy`**, else **`gauntlet`** (`ACADEMY_MAX_DIFFICULTY`). The ladder is non-decreasing, so Academy is a clean easy prefix and Gauntlet the harder suffix.
- `src/content/path.ts` builds `ACADEMY_PATH` (a lesson before every challenge — gating) and `GAUNTLET_PATH` (challenges only; their anchored lessons become **optional** technique links via `optionalLessonFor`). `pathForTrack`, `pathForChallenge`, `pathForLesson` resolve the right path.
- Story (`story` field, `STORY_INTRO`) is shown **only in the Gauntlet**. Academy is practice.

## Content rules (see the **forge-content** skill for the full bar)
- Ladder is **monotonically non-decreasing in difficulty** (1–10). Each challenge introduces **one** new `concept`; Gauntlet ones carry a `story` beat (**forge-story** skill = the canon).
- **Gauntlet d6+ are AoC-grade** and ship a per-player `generate`. Academy stays genuinely easy.
- A **lesson** (`src/content/lessons.ts`) is a teaching page + a pre-filled runnable example, anchored `before` a challenge id.
- Adding content is **data-only** (append a `RungSpec` / `Lesson`). Every challenge ships JS+Py reference solutions; the **JS** one is executed by tests and must match the example AND (for generators) the generated answer across seeds. Big generated inputs (e.g. packing) live in generators under `src/content/generators/`.

## Authoring skills
- **/add-challenge** `[difficulty] [concept]` — author one verified rung (generator for d6+), runs tests until green.
- **/add-lesson** `[before-challenge-id] [concept]` — author one verified lesson with a runnable example.
- **forge-content** (auto) — the content model + difficulty bar. **forge-story** (auto) — the story bible + continuity.

## Commands
- `npm run dev` — dev server (http://localhost:5173).
- `npm test` — Vitest: grade, streak, ladder, path, lesson-integrity, ladder-integrity (incl. generator cross-checks).
- `npm run build` — typecheck + production build (also verifies worker bundling).

## Guardrails
- Keep execution **client-side**; no code is sent to a server. (Pyodide loads its runtime once from CDN.)
- Keep the **engine pure** and tested; UI reads from it, never the reverse.
- Never report content "done" on red/skipped tests.

## UI / Visual Design Rules — Anti-Generic (MANDATORY)
**Invoke the `frontend-design` skill before writing any frontend/UI code, every session.**

The Molten Terminal look must feel hand-crafted, not AI-generic. Enforce these on every UI change:

- **Colors:** Never use default Tailwind palette (indigo-500, blue-600, etc.). Derive everything from the ember-on-iron brand palette.
- **Shadows:** Never flat `shadow-md`. Use layered, color-tinted shadows with low opacity.
- **Typography:** Never the same font for headings and body. Chakra Petch for display, IBM Plex Sans for body, JetBrains Mono for code. Apply tight tracking (`-0.03em`) on large headings, generous line-height (`1.7`) on body.
- **Gradients:** Layer multiple radial gradients. Add grain/texture via SVG noise filter for depth.
- **Animations:** Only animate `transform` and `opacity`. Never `transition-all`. Use spring-style easing.
- **Interactive states:** Every clickable element needs hover, focus-visible, and active states. No exceptions.
- **Depth:** Surfaces must have a layering system (base → elevated → floating) — nothing sits at the same z-plane.
- **Spacing:** Intentional, consistent spacing tokens — not random Tailwind steps.
- **Images/media:** Add gradient overlays and color treatment layers where applicable.

**Hard rules:**
- Do not use `transition-all`
- Do not use default Tailwind blue/indigo as a primary color
- Do not ship a screen without verifying it in the browser (`npm run dev`) — type-checking alone is not enough

## Status
Two tracks live: **Academy** (14 easy challenges, each preceded by a lesson; 28 lessons total)
and **Gauntlet** (27 story challenges across **five acts**, d4→d10). Acts I–III ramp to the
**Under the Trees** polyomino-packing puzzle; **Act IV (The Hidden Layer)** and **Act V (Finish
What They Started)** extend the d10 endgame with Dijkstra weighted shortest path, node-network
traversal, a seat cellular automaton, pair-frequency exponential growth, Chinese-Remainder
cycle alignment, and the modular-arithmetic **Founders' Engine** finale. Per-player generators
on every Gauntlet puzzle (dial vault, rucksack, RPS, Caesar, brackets, RLE, regions, VM, maze,
reactor, packing, hazard-descent, instruction-ribbon, settling-lattice, regrowth,
beacon-alignment, founders-engine). Two optional technique lessons for the new acts
(`l-dijkstra`, `l-cycle-align`). Molten Terminal visual pass, Home (two track cards) / Academy /
Gauntlet / Challenge / Lesson / Profile / Compete stub.
**36 tests green.**
**Next:** grow both tracks (via /add-challenge, /add-lesson); ranked-ladder backend. Old iOS
app archived under `legacy-ios/` (its iOS-only skills under `legacy-ios/.claude-skills/`).
