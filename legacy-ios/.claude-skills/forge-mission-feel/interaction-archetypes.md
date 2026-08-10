# Interaction archetypes — the palette a mission picks from

Supporting reference for [`forge-mission-feel`](SKILL.md). Pick **one or more** of these per mission; the higher the difficulty, the more (or the more combined) the interactions. Inspiration is competitive-robotics field challenges — **conceptual only, never named or copied.** Framings below are ForgeCode-original for our two worlds (**Cargo Command** warehouse, **Mars Outpost**).

## How to read this
Each archetype lists:
- **The interaction** — what the robot physically does.
- **Reactive?** — whether it inherently drives a *reactive model* (Pillar 1). "Input-only" archetypes must be **paired** with a reactive one for a difficulty-3+ / signature mission.
- **Engine mapping** — the objective kind(s) it uses. Existing kinds: `reachZone`, `reachPose`, `pickUpItem`, `depositItemInZone`, `detectColorInZone`, `armToAngle` (see `Sources/ForgeCodeEngine/Robotics/Sim/Mission.swift`). Planned kind for reactive models: **`activateMechanism`** (a field `Mechanism` with an activation trigger + scored state change, recorded in the run trace).
- **3D reaction** — what animates in `RoboticsFieldScene` on the action frame.

---

## 1. Transport / deliver
- **Interaction:** grab an object and carry it to a target bay/zone; release it there.
- **Reactive?** Input-only by default — the *delivery* becomes reactive when the bay responds (see reaction). Pair a bare carry with a reacting bay for signature missions.
- **Engine mapping:** `pickUpItem` + `depositItemInZone` (color/type-matched via `acceptsItemType`). Optional `activateMechanism` on the bay.
- **3D reaction:** carried item **rides the gripper**; on deposit the bay **lights up / a door slides / an indicator flips to green**. Cargo Command: a shipping bay roll-door. Mars Outpost: a habitat airlock glow.

## 2. Push / sweep-clear
- **Interaction:** shove one or more loose objects **out of a region** (clear a pad, sweep debris off a route) without picking them up.
- **Reactive?** Yes — the objects move and the cleared area changes state.
- **Engine mapping:** a `Mechanism`/region whose "cleared" state is scored via `activateMechanism` (region empty of the pushed items); or model the swept objects as items whose position leaving a region scores.
- **3D reaction:** the pushed objects **slide/scatter** ahead of the rover; the revealed pad **brightens** or a marking appears. Mars Outpost: brush regolith off a solar pad → the pad's cells light. Cargo Command: shove pallets off a lane → lane arrows turn green.

## 3. Lift / raise
- **Interaction:** get under or hook a hinged structure and **raise it** (an arm-push or drive-under-then-lift).
- **Reactive?** Yes — the signature reactive archetype.
- **Engine mapping:** `activateMechanism` (a lift `Mechanism` toggled when the arm reaches an angle within the model's region); may combine with `armToAngle`.
- **3D reaction:** the structure **rotates up about a hinge** / a platform **rises on its posts**, eased over ~0.5 s. Cargo Command: raise a loading-dock ramp. Mars Outpost: raise a collapsed antenna mast upright.

## 4. Flip / restore-upright
- **Interaction:** nudge a tilted or toppled model **back to its upright/home configuration.**
- **Reactive?** Yes.
- **Engine mapping:** `activateMechanism` (a two-state `Mechanism`: toppled → upright, triggered by contact/arm push from the correct side).
- **3D reaction:** the model **swings from tilted to standing** and settles. Mars Outpost: stand a knocked-over marker beacon back up. Cargo Command: right a tipped stack frame.

## 5. Tip / lever-activate
- **Interaction:** push a lever, slider, or button; **operate a mechanism** that then releases or reveals something.
- **Reactive?** Yes — and it can **cascade** (activating the lever releases an item to then transport → combos, design-principles Principle 6).
- **Engine mapping:** `activateMechanism` (lever) optionally chained to a released `FieldItem` you then `pickUpItem`/`depositItemInZone`.
- **3D reaction:** lever **tips**, and its consequence plays — a **hatch opens**, a **cell drops into reach**, a **gauge swings**. Cargo Command: pull a release lever → a crate rolls out of a chute. Mars Outpost: press a console → a sample tray extends.

## 6. Precision-place / mark
- **Interaction:** place or align an object (or the robot itself) **exactly** at one or more marked spots; don't disturb neighbors.
- **Reactive?** Input-heavy but reactive when each placement **registers** (a marker seats and lights). Precision-token discipline (don't disturb others) is part of the challenge.
- **Engine mapping:** `reachPose` / `armToAngle` for precise placement; `depositItemInZone` into tight zones; ties into the match **precision-token** system.
- **3D reaction:** placed marker **clicks into a socket and lights**; a wrong/loose placement stays dim. Mars Outpost: plant survey flags at study sites. Cargo Command: align a container onto its exact footprint outline.

---

## Combining archetypes (difficulty ladder)
- **Diff 1–2:** one archetype, generous tolerance (a single transport, or one lever tip).
- **Diff 3:** one reactive archetype **+** a transport, or a matched/sorted delivery whose bay reacts.
- **Diff 4–5:** **chain/cascade** — a lever (5) *releases* an item you then transport (1) into a reacting bay, under budget/precision pressure, with ≥2 viable routes. This is where a single run tells a real story.

Every mechanism mission must still satisfy the **DoD gate** in [SKILL.md](SKILL.md) and the **challenge test** in [`../add-mission/design-principles.md`](../add-mission/design-principles.md).
