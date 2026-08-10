# robotics-missions.md — ForgeCode mission catalog

> Auto-derived from `robotics_missions.json` / `robotics_fields.json` / `robotics_matches.json`.
> Every mission ships with a machine-verified solution test (+ negative test); diff-4/5 missions
> have **two** proven winning strategies. Points scale with difficulty (d1=10 … d5=50). JSON array
> order is the intended progression. A **Match** is one timed run scoring a curated set of a field's
> missions + 6 precision tokens (×10 pts) — see [robotics-engine.md](robotics-engine.md).

## Cargo Command (`field_warehouse`) — 15 missions · season total 460 pts

| # | Mission | Diff | Pts | Success rule | Required mechanisms |
|---|---------|:----:|:---:|--------------|---------------------|
| 1 | **Navigate to Base** | 1 | 10 | allRequired | drive |
| 2 | **Fetch the Red Crate** | 2 | 20 | allRequired | arm, arm+gripper |
| 3 | **Full Warehouse Run** | 3 | 30 | scoreThreshold 20 | arm+gripper, color sensor |
| 4 | **Signal the Tower** | 1 | 10 | allRequired | arm, drive |
| 5 | **Green Barrel Express** | 2 | 20 | allRequired | arm+gripper |
| 6 | **Color Scout** | 2 | 20 | allRequired | color sensor, drive |
| 7 | **Corridor Courier** | 3 | 30 | allRequired | arm+gripper, color sensor |
| 8 | **Double Dispatch** | 3 | 30 | allRequired | arm+gripper |
| 9 | **Shelf Inspection** | 3 | 30 | allRequired | arm, precision |
| 10 | **Track Finder** | 4 | 40 | allRequiredAndScore 26 · cap 45 | arm+gripper, color sensor |
| 11 | **Gap Gambit** | 4 | 40 | scoreThreshold 28 · cap 35 | arm+gripper, drive |
| 12 | **Night Shift** | 4 | 40 | scoreThreshold 26 · cap 40 | arm+gripper, drive |
| 13 | **Clear the Lane** | 4 | 40 | scoreThreshold 26 · cap 40 | arm+gripper, drive |
| 14 | **Triple Manifest** | 5 | 50 | scoreThreshold 33 · cap 42 | arm+gripper, color sensor, drive |
| 15 | **Grand Circuit** | 5 | 50 | scoreThreshold 33 · cap 25 | arm+gripper, color sensor, drive, precision |

## Mars Outpost (`field_arena`) — 15 missions · season total 460 pts

| # | Mission | Diff | Pts | Success rule | Required mechanisms |
|---|---------|:----:|:---:|--------------|---------------------|
| 1 | **First Traverse** | 1 | 10 | allRequired | arm, drive |
| 2 | **Beacon Salute** | 1 | 10 | allRequired | arm, drive |
| 3 | **First Sample** | 2 | 20 | allRequired | arm+gripper |
| 4 | **Solar Check-In** | 2 | 20 | allRequired | color sensor, drive |
| 5 | **Relay Delivery** | 2 | 20 | allRequired | arm+gripper |
| 6 | **Crater Detour** | 3 | 30 | allRequired | arm+gripper, color sensor |
| 7 | **Deep Field Run** | 3 | 30 | allRequired | arm+gripper, color sensor |
| 8 | **Ring Scout** | 3 | 30 | allRequired | arm, precision |
| 9 | **Blue Courier** | 3 | 30 | allRequired | arm+gripper, color sensor |
| 10 | **Core Extraction** | 4 | 40 | scoreThreshold 26 | arm+gripper, drive |
| 11 | **Rockslide Detour** | 4 | 40 | scoreThreshold 26 · cap 30 | color sensor, drive |
| 12 | **Dark Side Survey** | 4 | 40 | allRequiredAndScore 24 · cap 35 | arm+gripper, color sensor, drive |
| 13 | **Precision Landing** | 4 | 40 | allRequiredAndScore 26 · cap 25 | arm, color sensor, precision |
| 14 | **Sample Sort** | 5 | 50 | scoreThreshold 33 · cap 40 | arm+gripper |
| 15 | **Grand Expedition** | 5 | 50 | allRequiredAndScore 33 · cap 40 | arm+gripper, color sensor, drive |

## Reactive-mechanism challenge missions

Single-mission challenges (surfaced in the Robotics tab's **Challenge Missions** ladder) where a
model on the field visibly reacts to the rover — the `forge-mission-feel` experience bar. Each ships
a machine-verified solution + a negative test proving the mechanism is required. Briefs stay
outcome-only (never name the mechanism or route — the kid discovers it).

### Cargo Command (`field_warehouse`) — reactive ladder

| Mission | Diff | Pts | Reactive model (reaction) | Objectives |
|---------|:----:|:---:|---------------------------|------------|
| **Open the Bay** | 2 | 25 | roll-up bay **door** (gate lifts on its rails) | bump the door open → park inside the east bay |
| **Load the Dock** | 3 | 32 | dock-leveler **ramp** (ribbed deck rises) | arm-press the dock → fetch the red crate → deposit at red depot |
| **Chute Release** | 4 | 40 | release **lever** + roller chute (crate rolls out) | arm-press the lever → collect the freed crate → deliver to red depot |
| **Warehouse Gauntlet** | 5 | 50 | lever + roll-up door (cascade) | lever → deposit → open the door → precision-park dead-centre in the bay |

### Mars Outpost (`field_arena`) — reactive ladder

| Mission | Diff | Pts | Reactive model (reaction) |
|---------|:----:|:---:|---------------------------|
| **Drill Wakeup** | 2 | — | arm-press **lever** |
| **Storage Nook Breakthrough** | 3 | — | **gate** unlocks a blocked lane |
| **Signal Rocket** | 3 | — | **launcher** (rocket blasts off; needs launchTool) |
| **Buried Sample** | 4 | — | **excavator** (gripper-pull frees a buried sample; needs fineHook) |
| **Precision Gauntlet** | 5 | — | launcher + a 7 cm rock pocket |

## Matches (seed showcases)

| Match | Field | Missions | Move budget | Tokens |
|-------|-------|:--------:|:-----------:|:------:|
| **Cargo Command Season Match** | Cargo Command | 6 | 60 | 6 |
| **Mars Outpost Expedition Match** | Mars Outpost | 6 | 60 | 6 |

Each season match includes one reactive-mechanism mission so the timed run showcases a model in
motion (Cargo → *Open the Bay*; Mars → *Storage Nook Breakthrough*).

