---
name: bulk-grid-challenges
description: Use when someone asks to add, generate, or bulk-author VexCode beginner grid challenges — multiple puzzle levels with verified solutions, hints, and passing Swift tests. Also use when asked to fill the challenge tab, generate challenge content, or add difficulty-tiered grid puzzles to the Challenges track.
argument-hint: "[zone|easy|hard|superHard] [count]"
disable-model-invocation: true
---

## What This Skill Does

Authors N verified VexCode beginner-tier grid challenges following the **Homescapes-style Vex Academy mechanic schedule**:
- Designs valid grid layouts (obstacles, terrain, items, start, goal) for the correct zone/phase
- Traces every solution step-by-step before writing any code
- Writes verified solution programs using the 5-command engine + terrain/collectible mechanics
- Appends entries to `Sources/VexCodeEngine/Content/challenges.json`
- Adds positive + negative Swift tests to `Tests/VexCodeEngineTests/LessonLibraryTests.swift`
- Updates the `all.count` assertion in `challengesDecodes()`
- Runs `swift test --filter ChallengesTrackTests` then full `swift test` and fixes failures

## Context — Read These First

1. `Sources/VexCodeEngine/Content/challenges.json` — existing entries (find max order)
2. `Tests/VexCodeEngineTests/LessonLibraryTests.swift` — existing test patterns
3. `Sources/VexCodeEngine/Challenge.swift` — `Challenge` struct
4. `Sources/VexCodeEngine/ChallengeDifficulty.swift` — `ChallengeDifficulty` enum: `.easy`, `.hard`, `.superHard`
5. `Sources/VexCodeEngine/TerrainKind.swift` — terrain types
6. `Sources/VexCodeEngine/GridItem.swift` — item types
7. `docs/engine-spec.md` — simulator rules

## Story Context — Vex Academy

Every challenge is a mission briefing for **Vex**, a robot cadet at the Vex Academy — a space station that trains robots to navigate dangerous planets.

- `introText`: mission briefing from Academy command (2–3 sentences, tense/exciting)
- `goalDescription`: what Vex must do to complete the mission (one sentence)
- `hintText`: Academy training tip — approach, not code (one sentence)
- Zone flavor: The Grid = training room, Crystal Caves = gem-lit tunnels, Frozen Wastes = ice planet, Circuit City = neon factory floor

## Engine Rules

**Coordinate system** — origin (0,0) = bottom-left:
- `"up"` → y+1 | `"down"` → y-1 | `"right"` → x+1 | `"left"` → x-1
- Valid: 0 ≤ x < width, 0 ≤ y < height
- Hitting an obstacle or going out of bounds = `hitWall` failure

**Five commands:**
```
move()              — advance 1 cell (fails on wall/obstacle/OOB)
turnLeft()          — 90° CCW: up→left→down→right→up
turnRight()         — 90° CW:  up→right→down→left→up
repeat(n){ ... }    — loop body n times
if(wallAhead()){ .. } — execute body only if next cell is blocked
```

**Terrain mechanics (Simulator applies automatically after each move):**
- `ice` — robot slides 1 extra cell in same direction if the landing cell is clear; collectibles on slide-target are also picked up
- `mud` — costs 2 move-steps instead of 1 (counts double against parMoves)
- `conveyorNorth/South/East/West` — pushes robot 1 cell in conveyor direction after landing (if target is clear)
- `portal(id)` — landing on one portal teleports to the other portal with the same id

**Collectibles:**
- `kind: "collectible"` items are auto-picked up when robot lands on their cell
- `collectGoal: N` in challenge → robot must collect ≥ N items for `isSuccess = true`
- `parMoves` → star rating: 3 stars if ≤ par, 2 if ≤ par×1.5, 1 if over but successful

**Block counting** (for `maxBlocks`):
- `move()` / `turnLeft()` / `turnRight()` = 1 block each
- `repeat(n){ body }` = 1 (repeat) + body count
- `if(wallAhead()){ body }` = 1 (if) + body count

## Two Independent Tracks — Story and Puzzles

**Story (spots) and puzzle mechanics are completely separate.** The spot = story/base-camp location (changes every ~250 challenges). The mechanic = what the puzzle uses (own schedule below). They do not affect each other.

- All 100 challenges in this build are **Spot 1 — Landing Zone** story-wise.
- Puzzle mechanics follow the schedule below, regardless of story spot.

## Mechanic Schedule (puzzle track — independent of story)

**Mechanics stack.** Each new phase adds ON TOP of all previous mechanics.

### Phase 1 — Navigation (orders 1–35)
No terrain, no items. Pure grid navigation with all 5 commands.
- Orders 1–25: **DONE. Do not touch.**
- **Orders 26–35**: Complete navigation arc. Complex mazes, nested loops, wall sensing required.
  - 26(easy), 27(easy), 28(hard), 29(easy), 30(hard), 31(easy), 32(hard), 33(superHard), 34(easy), 35(superHard)

### Phase 2 — + Collectibles (orders 36–70)
Navigation + `collectGoal` + `parMoves`. Stacked on top of navigation.
- **Order 36**: INTRO — `easy`. 6×6, 1 gem, open path. `collectGoal: 1`. "First energy crystal in the sim."
- Orders 37–70: navigation + collectibles, scattered difficulty.
  - SuperHard spikes: 42, 48, 54, 60, 66, 70
  - Easy breathing challenge after every spike (43, 49, 55, 61, 67, 71)
  - All challenges: `collectGoal ≥ 1`, `parMoves` set

### Phase 3 — + Ice terrain (orders 71–100)
Navigation + collectibles + ice. Stacked on top of all previous.
- **Order 71**: INTRO — `easy`. 6×6, 1 ice tile, gem at slide destination. Trace the slide.
- Orders 72–100: navigation + collectibles + ice, scattered difficulty.
  - SuperHard spikes: 76, 82, 88, 95, 100
  - Grids scale up to 28×28 by challenge 95+

### Phase 4 — + Mud terrain (orders 101–130+) — *Future content drop*
### Phase 5 — + Conveyors (orders 131–160+) — *Future content drop*

## Scattered Difficulty Rules (CRITICAL — read carefully)

The game feels like Homescapes: **overall trend up, locally scattered**.

1. **Mechanic intro challenges are ALWAYS `easy`** — tiny grid, single mechanic instance, clear solution.
2. **The 2–3 challenges after each intro are `easy`** — ease the player into the mechanic.
3. **`superHard` spikes at positions listed above** — genuinely hard. Large grids, tight block budgets.
4. **After every `superHard` spike: one `easy` challenge** — breathing room.
5. **All other positions: mix of `easy` and `hard`** — never monotonic.
6. **Later phases' `superHard` must be harder than earlier phases'** — phase 1 super-hard < phase 2 < phase 3.

## Grid Size Guidelines by Difficulty

| difficulty  | Grid size       | Obstacles | maxBlocks | Notes                                         |
|-------------|-----------------|-----------|-----------|-----------------------------------------------|
| easy        | 6×6 – 10×10    | 0–3       | 2–8       | One clear approach; short solution            |
| hard        | 10×10 – 16×16  | 3–12      | 8–20      | Maze navigation; nested loops required        |
| superHard   | 16×16 – 32×32  | 12–60+    | 18–55     | Brutal; ≥18 blocks; tight budget; wall sensing|

## Steps

1. **Find starting order** — read `challenges.json`, find max `order`. New challenges start at max+1.

2. **Determine zone and applicable mechanics** from the schedule above.

3. **Design each challenge:**
   a. Assign difficulty tier per the scatter pattern
   b. Pick grid size and obstacle count for that difficulty
   c. Place terrain cells and items if applicable to the zone
   d. **Trace the entire solution** — every (x,y,facing) step, including terrain effects
      - Ice: note the slide target explicitly
      - Mud: count 2 steps in parMoves
      - Conveyor: note the push direction
   e. Derive the solution program from the trace
   f. Count blocks → set `maxBlocks` (easy: +1 slack; hard+: exact or +1)
   g. Count move-steps for `parMoves` (mud = 2, all others = 1 per move)
   h. Write zone-flavored `introText` + `goalDescription` + `hintText`

4. **Verify every challenge before writing:**
   ```
   (SX,SY)[facing] → move → (X,Y)[facing] [ice→slide to (X2,Y2)] → ...
   ```
   Confirm final position == goal AND itemsCollected.count ≥ collectGoal (if set).
   **If any step is uncertain, redesign. Never guess.**

5. **Append to `challenges.json`** — never overwrite existing entries.

6. **Update `challengesDecodes()` test** — change `#expect(all.count == OLD)` to new total.

7. **Add tests** — positive + negative per challenge.

8. **Run `swift test --filter ChallengesTrackTests`** — all green. Fix failures.

9. **Run `swift test`** — full suite must stay green (baseline: 480 tests).

## JSON Schema

```json
{
  "id": "challenge-N",
  "track": "challenges",
  "order": N,
  "title": "Short Evocative Title",
  "introText": "2–3 sentences. Mission briefing. Zone-flavored. Kid-friendly.",
  "goalDescription": "One sentence: what Vex must accomplish.",
  "hintText": "One sentence. The approach, not the code.",
  "challenge": {
    "grid": {
      "width": W,
      "height": H,
      "obstacles": [{ "x": X, "y": Y }],
      "terrain": {
        "3,2": "ice",
        "4,2": "mud",
        "5,0": "conveyorNorth",
        "1,1": { "type": "portal", "id": "A" },
        "7,7": { "type": "portal", "id": "A" }
      },
      "items": [
        { "id": "gem-1", "position": { "x": 3, "y": 4 }, "kind": "collectible" }
      ]
    },
    "start": { "position": { "x": SX, "y": SY }, "facing": "up|down|left|right" },
    "goal": { "x": GX, "y": GY },
    "allowedCommands": ["move", "turnLeft", "turnRight", "repeat", "if"],
    "maxBlocks": B,
    "collectGoal": N,
    "parMoves": P,
    "difficulty": "easy|hard|superHard"
  }
}
```

**Omit** `terrain`, `items`, `collectGoal`, `parMoves` when not used (Zone 1 navigation challenges). `difficulty` is required for all new challenges (orders 26+).

## Test Template

```swift
// MARK: Challenge N — [Title] ([Zone], [difficulty])

@Test("challenge N ([Title]) canonical solution reaches the goal within maxBlocks")
func challengeNSolution() throws {
    let c = try challenge(N)
    #expect(c.title == "[Title]")
    // Verified trace from (SX,SY)[facing]:
    //   step 1: (x,y)[dir] → command → (x2,y2)[dir2] [terrain effect if any]
    //   ...
    // blockCount = [breakdown] = TOTAL ≤ MAXBLOCKS
    // parMoves = P, moveStepsUsed = M → starRating = S
    let program = try Parser.parse("""
        [solution program]
        """)
    #expect(program.blockCount <= (c.challenge.maxBlocks ?? .max))
    let result = Simulator().run(program: program, challenge: c.challenge)
    #expect(result.isSuccess)
    #expect(result.frames.last?.position == c.challenge.goal)
    // If collectGoal set:
    // #expect(result.itemsCollected.count >= c.challenge.collectGoal ?? 0)
}

@Test("challenge N naive straight-line attempt fails")
func challengeNNaiveFails() throws {
    let c = try challenge(N)
    let program = try Parser.parse("move()\nmove()\nmove()")
    let result = Simulator().run(program: program, challenge: c.challenge)
    #expect(!result.isSuccess)
}
```

## Guardrails

- **Never write a solution without tracing step-by-step.** Terrain slides/pushes must be traced explicitly.
- **Intro challenges must be trivially easy** — single mechanic instance, tiny grid, open path.
- **`superHard` challenges must require ≥18 blocks** — if shorter, make the grid bigger and harder.
- **`collectGoal` must be reachable** — every required item must be on a cell the robot can reach.
- Start, goal, and item positions must not be obstacle cells or out of bounds.
- `id` strings and `order` values must be unique and sequential.
- Do not duplicate grid layouts from existing challenges.
- Zone intro challenges (orders 31, 61, 76, 91) must be `easy` — no exceptions.
- After adding all challenges, run `swift test` and fix any failures before reporting done.
- **`difficulty` is required for every challenge with order ≥ 26.**
