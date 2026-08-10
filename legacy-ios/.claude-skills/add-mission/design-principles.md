# Mission design principles — what makes a mission *innovative*

Supporting reference for the `/add-mission` skill. **Read this before designing any mission.**
The bar: a mission should stand next to the inventiveness of real competitive-robotics field
challenges — a *problem to be cracked*, not a procedure to be followed. (Inspiration is
conceptual only: never copy or name FLL/FIRST/LEGO/REV missions, themes, or art.)

## The core test
Before authoring, answer these four. If any answer is "no," redesign:
1. **Is there more than one sensible way to attempt it?** (route choice, objective choice,
   technique choice)
2. **Does the *best* solution require a small insight** that isn't stated in the brief?
3. **Does the required mechanism matter** — would a drive-only program provably score below
   success?
4. **Would two kids compare scores and argue strategy afterward?** If there's nothing to argue
   about, it's a task, not a challenge.

## Principle 0 — Every mission has a headline point value that tracks difficulty
Like a real competition field, each mission is *worth* a fixed, legible number of points, and
harder missions are worth more. **The scale (mission's total available points = sum of its
objective points):**

| Difficulty | Mission value | Feels like |
|---|---|---|
| 1 | **10 pts** | drive somewhere, lower the arm |
| 2 | **20 pts** | first pickup / first detection |
| 3 | **30 pts** | pickup + matched deposit, an obstacle that matters |
| 4 | **40 pts** | sensor navigation (distance/line), portfolio choice |
| 5 | **50 pts** | multi-item ordering, precision + budget pressure |

Objectives *within* a mission split its value (e.g. a 30-pt mission = 10 pickup + 15 deposit +
5 bonus). A 15-mission field then has a **season total** (~450 pts) kids can chase across
missions — easy ones are quick wins, the 50-pointers are the bragging rights. Never give an
easy mission a big value or bury a hard mission at 10 pts.

## Principle 1 — Pose problems, never procedures (STRICT)
The brief states the *goal*, the *points*, and the *constraint* — never the route, the API
calls, **or which mechanism/sensor/technique to use**. Discovering that the distance sensor,
a line-follow loop, or the arm solves the problem *is the learning* — kids get there in blocks
or code on their own.
- ❌ "Drive forward 80, lower the arm, close the gripper."
- ❌ "Use the arm and gripper to grab it." / "Use your color sensor to read the pad." /
  "A while-loop with the distance sensor is safest."
- ✅ "The power cell sits behind the pipe rack. Get it into the charging bay — the direct
  path is blocked."
- ✅ "Stop exactly one robot-length from the shelf without touching it."
Naming the *outcome* is fine ("get the crate into the blue depot", "headquarters needs proof
the shipment pad is blue"); naming the *tool or method* is not. Same rule for objective
`description` strings: describe what counts, not how to do it. Hints, if the app ever adds
them, are a separate layer — never the brief.

## Principle 2 — Strategy portfolios (the biggest innovation lever)
Use `scoreThreshold` / `allRequiredAndScore` with **more points available than the threshold**
(e.g. a 40-pt mission that succeeds at 25). Objectives get different point values reflecting
risk and difficulty. Now the kid must *choose a portfolio*: safe-and-slow low scorers vs one
risky high scorer. Different kids succeed with different objective sets — that's real challenge
design. At difficulty 4–5, most missions should work this way (threshold ≈ 60–70% of the
mission's value from Principle 0).

## Principle 3 — Risk/reward geometry
Place value behind risk: the 40-point item sits in a narrow gap between obstacles (tight with
`footprintRadius`), past a corridor where dead reckoning drifts, or deep in a corner that costs
budget to reach. The 15-point item sits in the open. Geometry *is* the difficulty dial — use
exact numbers (gap width vs robot footprint, `pickupRadius` vs approach angle, zone size vs
overshoot tolerance).

## Principle 4 — At least two viable routes
Design the world so ≥2 meaningfully different solutions exist — e.g. a short dead-reckoning
path (fast, fragile) vs a longer line-follow or wall-referenced path (reliable). Verify the
canonical solution in the test; **describe the alternates in the report and catalog**. A world
where only one exact sequence can possibly work is over-constrained — that's a maze, not a
mission.

## Principle 5 — Sensor techniques as discoveries
The best missions quietly *teach a competition technique* because it's the winning approach:
- **Wall-squaring:** drive until `wallAhead()` to kill accumulated heading/position error, then
  make the precise move from a known reference.
- **Line acquisition:** drive to a line, then follow it with `lineLeft()/lineRight()` for
  repeatable navigation to a far target.
- **Sensor-gated approach:** creep with `while (distance() > n)` instead of a blind fixed
  drive, so an obstacle's exact position stops mattering.
- **Color waypointing:** confirm location mid-run with `detectColorInZone` pads.
Design tolerances so the naive dead-reckon version is *possible but uncomfortable* at
difficulty 3+, and the sensor version is clearly better.

## Principle 6 — Combos, ordering, and interference
Objectives should interact:
- **Combo routes:** place objectives so one clever path chains 2–3 of them in a single trip.
- **Ordering puzzles:** an item physically blocks a corridor — pick it up and **drop it
  elsewhere** (`gripper.open()` outside a deposit zone drops in place — a supported, powerful
  mechanic) to clear your own path.
- **Sorting:** multiple items × color/type-matched deposit zones (`acceptsItemType`, colors)
  — wrong bin = no points.
- **Return-to-base:** `reachZone` scores the **final** pose — a required "end in the home zone"
  objective forces a return trip and turns one-way routes into loops.

## Principle 7 — Efficiency pressure
Use the mission's optional `maxActions` cap to make wastefulness fail: a generous cap at
difficulty 1–2, a tight one at 4–5 where the natural solution needs loops/functions and a
smart route. Say the cap in the brief ("Your robot has energy for 60 moves"). Never set it so
tight that only the canonical solution fits — leave headroom for alternates (rule of thumb:
canonical solution ≤ 70% of cap).

## Difficulty calibration (1–5)
| Diff | Value | Feels like | Mechanics |
|---|---|---|---|
| 1 | 10 | First drive | drive + turns, one `reachZone`/`reachPose`, generous zones |
| 2 | 20 | First grab | one pickup or one detection; arm/gripper required; simple geometry |
| 3 | 30 | Real mission | pickup+deposit combos, color matching, sensor-gated moves, an obstacle that matters |
| 4 | 40 | Strategy | portfolio scoring, 2+ routes, line-follow or wall-square clearly best, tight-ish `maxActions` |
| 5 | 50 | Signature | multi-item interference/ordering, precision geometry, budget pressure, several defensible portfolios |

## Anti-patterns (redesign if you see these)
- Solvable by one straight drive at difficulty ≥2.
- Brief that names API calls or dictates steps.
- Two missions on the same field with the same shape ("fetch X to bin Y" again with new ids).
- Points that don't track difficulty (the risky objective worth less than the safe one, or a
  mission value that breaks the Principle 0 scale).
- A world so tight only the canonical program can succeed.
- Every objective `isRequired` under `allRequired` at difficulty 4–5 (kills strategy choice).
- Scoring achievable without the mission's stated star mechanism.

## Report requirements (adds to the /add-mission report)
For each mission also include **Strategy notes**: the intended insight, at least one alternate
approach and its trade-off, and why the point values are set the way they are. These notes go
into `docs/robotics-missions.md` so the catalog reads like a real season guide.
