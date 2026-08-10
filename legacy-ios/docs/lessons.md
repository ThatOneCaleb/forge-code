# Lesson Content — Code Basics — Forge Code

> Detail doc referenced by [CLAUDE.md](../CLAUDE.md) and the `/add-lesson` skill. The 6 Code Basics lessons, their challenge definitions, and **verified** canonical solutions.

Content lives in `Sources/ForgeCodeEngine/Content/code_basics.json`, decoded into `Lesson`. Progression is linear; a lesson unlocks when the previous is completed. Intros are short (2–4 sentences), encouraging, written for an 8–15 year old. Coordinate system per [engine-spec.md](engine-spec.md): origin bottom-left, `+y` up.

## Design rules
- Keep `allowedCommands` **minimal** so the target concept is the point of the lesson.
- Set `maxBlocks` so brute-force is blocked and the taught concept is the efficient path.
- **Never ship a lesson without a verified solution and a passing test** (`/add-lesson` enforces this).
- Variables lesson stays **conceptual via `repeat(n)`** — no grammar extension.

## The 6 lessons (all grid 6×6; solutions hand-verified)

| # | Title | Start | Goal | Obstacles | Allowed | maxBlocks | Verified solution |
|---|-------|-------|------|-----------|---------|-----------|-------------------|
| 1 | **Move & Turn** | (0,0) ↑ | (2,0) | — | move, turnLeft, turnRight | 4 | `turnRight(); move(); move();` |
| 2 | **Sequences** | (0,0) ↑ | (2,2) | — | move, turnLeft, turnRight | 6 | `move(); move(); turnRight(); move(); move();` |
| 3 | **Loops** | (0,0) → | (5,0) | — | move, repeat | 2 | `repeat(5){ move(); }` |
| 4 | **Conditionals** | (0,0) → | (2,2) | (3,0) | all | 6 | `repeat(4){ if(wallAhead()){ turnLeft(); } move(); }` |
| 5 | **Variables (light touch)** | (0,0) → | (4,0) | — | move, repeat | 2 | `repeat(4){ move(); }` |
| 6 | **Capstone** | (0,0) ↑ | (3,3) | (4,2) | all | 10 | `move(); move(); turnRight(); repeat(3){ move(); } if(wallAhead()){ turnLeft(); } move();` |

↑ = facing up, → = facing right.

## What each lesson teaches
1. **Move & Turn** — the run loop + the two modes; one turn then move.
2. **Sequences** — order matters; a longer multi-step path. Introduce `maxBlocks` gently.
3. **Loops** — `repeat(n)`; `maxBlocks 2` makes the loop the only way (manual 5 moves = 5 blocks > 2).
4. **Conditionals** — `if(wallAhead())`; the obstacle at (3,0) means naive "move forward" crashes, motivating the turn.
5. **Variables (light touch)** — frame the `repeat` count as a value you can change; conceptual only.
6. **Capstone** — combines sequence + loop + conditional; the `if` prevents crashing into the obstacle at (4,2). Earns a special badge.

## Verified trace — Capstone (example of the required verification)
Start (0,0) facing up:
1. `move` → (0,1) · 2. `move` → (0,2) · 3. `turnRight` → facing right · 4. `repeat(3){move}` → (1,2)→(2,2)→(3,2) · 5. `if(wallAhead())`: cell ahead (4,2) is an obstacle → true → `turnLeft` → facing up · 6. `move` → (3,3) = **goal**. `blockCount` = 8 ≤ 10. ✅

## Adding more lessons
Use `/add-lesson [track] [concept]`. It designs the challenge, writes a verified solution, adds a passing test, and runs `swift test`. See the `add-lesson` skill.
