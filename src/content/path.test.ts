import { describe, expect, it } from "vitest";
import { ACADEMY_PATH, GAUNTLET_PATH } from "./path";
import { LESSONS } from "./lessons";
import { CHALLENGES } from "./challenges";
import { isUnlocked, itemStatus, nextItem } from "../engine/progress/path";

const academyChallenges = CHALLENGES.filter((c) => c.track === "academy");
const gauntletChallenges = CHALLENGES.filter((c) => c.track === "gauntlet");

describe("track assembly", () => {
  it("Academy path has a lesson before every challenge", () => {
    for (let i = 0; i < ACADEMY_PATH.length; i++) {
      const item = ACADEMY_PATH[i];
      if (item.kind !== "challenge") continue;
      const prev = ACADEMY_PATH[i - 1];
      expect(prev, `${item.id} has no preceding item`).toBeTruthy();
      expect(prev.kind, `${item.id} is not preceded by a lesson`).toBe("lesson");
    }
  });

  it("Academy path contains all academy challenges", () => {
    const ids = new Set(ACADEMY_PATH.filter((p) => p.kind === "challenge").map((p) => p.id));
    for (const c of academyChallenges) expect(ids.has(c.id)).toBe(true);
  });

  it("Gauntlet path is challenges only (lessons are optional, off-path)", () => {
    expect(GAUNTLET_PATH.every((p) => p.kind === "challenge")).toBe(true);
    const ids = new Set(GAUNTLET_PATH.map((p) => p.id));
    for (const c of gauntletChallenges) expect(ids.has(c.id)).toBe(true);
  });

  it("every lesson anchors before a real challenge", () => {
    const challengeIds = new Set(CHALLENGES.map((c) => c.id));
    for (const l of LESSONS) expect(challengeIds.has(l.before)).toBe(true);
  });
});

describe("per-track unlock rules", () => {
  it("opens only the first item of each track with no progress", () => {
    const none = new Set<string>();
    expect(nextItem(ACADEMY_PATH, none)?.id).toBe(ACADEMY_PATH[0].id);
    expect(nextItem(GAUNTLET_PATH, none)?.id).toBe(GAUNTLET_PATH[0].id);
    expect(isUnlocked(1, ACADEMY_PATH, none)).toBe(false);
  });

  it("an Academy lesson gates its challenge until read", () => {
    const li = ACADEMY_PATH.findIndex((p) => p.kind === "lesson");
    const lesson = ACADEMY_PATH[li];
    const before = new Set(ACADEMY_PATH.slice(0, li).map((p) => p.id));
    expect(itemStatus(li, ACADEMY_PATH, before)).toBe("unlocked");
    expect(itemStatus(li + 1, ACADEMY_PATH, before)).toBe("locked");
    const read = new Set([...before, lesson.id]);
    expect(itemStatus(li + 1, ACADEMY_PATH, read)).toBe("unlocked");
  });
});
