# Product Vision & Scope — Forge Code

> Detail doc referenced by [CLAUDE.md](../CLAUDE.md). Covers *why* the product exists, who it's for, and exactly what is / isn't in the MVP.

## What we're building
A **free iOS app (SwiftUI)** — a **coding & robotics learning companion for kids ages ~8–15**, built for the **STEM Greenhouse** outreach program and its real pilot group. It teaches coding and robotics concepts and **works with or without a physical robot**. Kids progress through lessons, solve grid-based challenges by writing programs (in blocks *or* text), earn badges, and keep a personal build log. Usable **solo or in a mentor-led session**.

Built for **App Store release**, so quality, stability, accessibility, and App Review compliance matter — but the MVP is deliberately small. Build the core loop well before adding breadth.

## The differentiators (what makes this worth building)
Most are post-MVP, but **every MVP decision must protect the path to them.**
1. **Mentor + parent visibility layer.** Dashboards, a shared build log, progress someone else can see. *MVP: stubbed screens — but model a kid's progress/badges/log as cleanly queryable, shareable data. Don't bury state in view-local state.*
2. **Resource-scarce by design.** Works with **zero hardware** as a first-class mode, not "also works without a robot" as an afterthought. The full learning arc must be complete and satisfying on just an iPhone.
3. **Dual block/text mode as a real on-ramp to Java-like syntax.** Not block coding with a toy text view bolted on — a genuine bridge from blocks into real, readable code. The shared AST and faithful two-way reflection are the product's spine.
4. **Tied to a real program with a real pilot (STEM Greenhouse).** Credibility, not a concept demo. Bias toward reliability and clarity — things that work in a room full of kids over flashy-but-fragile features.
5. **Bridges coding into robotics-specific concepts**, not just abstract programming. *MVP: Robotics track stubbed — but keep the engine's command/challenge model general enough to later express robotics ideas (sensors/conditions beyond `wallAhead()`).*

## Guiding principles
- **Engine first, UI second.** The engine + interpreter are pure, dependency-free Swift, fully unit-tested, and verified *before* any UI is wired up.
- **Kid-safe by default.** No accounts, no networking, no data collection, no third-party SDKs. Local, on-device.
- **One correct core loop beats ten half-built screens.** Depth over breadth.
- **Friendly, never punishing.** Errors, failures, and hints are encouraging and age-appropriate.

## Users
| User | In this MVP | Notes |
|------|-------------|-------|
| **Kid** | ✅ Full experience | Primary user. No login. Lessons, badges, build log. |
| **Mentor** | 🔲 Placeholder only | "Coming soon". Future: visibility into a kid's progress. |
| **Parent** | 🔲 Placeholder only | "Coming soon". Future: progress visibility. |

The kid's core experience requires **no login and no account**. Everything local/on-device.

## MVP scope

### Build fully
- **Kid experience only** (the primary user).
- **"Code Basics" track**, fully playable: Move & Turn → Sequences → Loops → Conditionals → Variables (light touch) → Capstone.
- **Simulator engine** (grid-based, Tier 1) with **both block and text mode** driving the same challenge, toggleable, with cross-reflection.
- **Text interpreter** for the constrained Java-like syntax with friendly errors.
- **Four screens**: Lesson Map, Lesson/Simulator, Badge Shelf, Build Log (list + add entry).
- **Local persistence** of kid progress, badges, and build log entries.

### Stub only ("Coming soon" placeholders)
- **Robotics Concepts** track — locked/placeholder lesson list.
- **Mentor** view and **Parent** view — one placeholder screen each.

### Do NOT build yet
- ❌ No backend, accounts, login, or networking of any kind.
- ❌ No Mentor Dashboard / Parent View functionality (placeholders only).
- ❌ No AI features.
- ❌ No monetization / paywall / IAP / ads.
- ❌ No Robotics lesson content, and no Code Basics lessons beyond the first ~6.
- ❌ No physical robot connectivity (Bluetooth/BLE) — must be fully usable with no robot.

**If a request pulls scope beyond the above, flag it and confirm before building.**

## Definition of done (MVP)
- [ ] Engine + interpreter fully unit-tested and green.
- [ ] All 6 Code Basics lessons solvable in **both** block and text mode, with working mode-toggle reflection.
- [ ] Friendly errors for common text mistakes.
- [ ] Progress, badges, streak, and build log persist across launches.
- [ ] Photo attach works via `PhotosPicker`, thumbnails render, images stored in Documents (path in SwiftData).
- [ ] Robotics / Mentor / Parent placeholders present and clearly "Coming soon."
- [ ] No networking, accounts, third-party SDKs, or data collection.
- [ ] Basic accessibility: Dynamic Type, VoiceOver labels, sufficient contrast.
- [ ] App builds clean and runs on iPhone simulator without warnings in core paths.
