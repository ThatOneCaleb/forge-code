import type { Challenge } from "../types";

/**
 * Ladder unlock rule: the first rung is always open; every other rung opens
 * once the rung immediately before it (by `order`) has been solved.
 */
export function isUnlocked(
  challenge: Challenge,
  solved: ReadonlySet<string>,
  ladder: readonly Challenge[],
): boolean {
  if (challenge.order <= 1) return true;
  const prev = ladder.find((c) => c.order === challenge.order - 1);
  return prev ? solved.has(prev.id) : true;
}

/** The next unsolved, unlocked rung — where "Continue" should send the player. */
export function nextChallenge(
  solved: ReadonlySet<string>,
  ladder: readonly Challenge[],
): Challenge | undefined {
  const ordered = [...ladder].sort((a, b) => a.order - b.order);
  return ordered.find((c) => !solved.has(c.id) && isUnlocked(c, solved, ordered));
}

export type RungStatus = "solved" | "unlocked" | "locked";

export function rungStatus(
  challenge: Challenge,
  solved: ReadonlySet<string>,
  ladder: readonly Challenge[],
): RungStatus {
  if (solved.has(challenge.id)) return "solved";
  return isUnlocked(challenge, solved, ladder) ? "unlocked" : "locked";
}
