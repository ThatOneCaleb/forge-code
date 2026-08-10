import { describe, expect, it } from "vitest";
import { CHALLENGES } from "../../content/challenges";
import { isUnlocked, nextChallenge, rungStatus } from "./ladder";

const ladder = CHALLENGES;

describe("ladder unlock rules", () => {
  it("opens the first rung with no progress", () => {
    expect(isUnlocked(ladder[0], new Set(), ladder)).toBe(true);
  });

  it("keeps later rungs locked until the previous is solved", () => {
    expect(isUnlocked(ladder[1], new Set(), ladder)).toBe(false);
    expect(isUnlocked(ladder[1], new Set([ladder[0].id]), ladder)).toBe(true);
  });

  it("nextChallenge points at the first unsolved unlocked rung", () => {
    expect(nextChallenge(new Set(), ladder)?.id).toBe(ladder[0].id);
    const solved = new Set([ladder[0].id, ladder[1].id]);
    expect(nextChallenge(solved, ladder)?.id).toBe(ladder[2].id);
  });

  it("reports rung status", () => {
    const solved = new Set([ladder[0].id]);
    expect(rungStatus(ladder[0], solved, ladder)).toBe("solved");
    expect(rungStatus(ladder[1], solved, ladder)).toBe("unlocked");
    expect(rungStatus(ladder[2], solved, ladder)).toBe("locked");
  });
});
