import type { PathItem } from "../types";

export type ItemStatus = "complete" | "unlocked" | "locked";

/**
 * Path unlock rule (generalizes the challenge-only ladder): the first item is
 * always open; every other item opens once the one before it is complete.
 * `complete` is the merged set of solved challenge ids and read lesson ids.
 */
export function isUnlocked(
  index: number,
  path: readonly PathItem[],
  complete: ReadonlySet<string>,
): boolean {
  if (index <= 0) return true;
  const prev = path[index - 1];
  return prev ? complete.has(prev.id) : true;
}

export function itemStatus(
  index: number,
  path: readonly PathItem[],
  complete: ReadonlySet<string>,
): ItemStatus {
  const item = path[index];
  if (item && complete.has(item.id)) return "complete";
  return isUnlocked(index, path, complete) ? "unlocked" : "locked";
}

/** The first incomplete, unlocked item — where "Continue" should send the player. */
export function nextItem(
  path: readonly PathItem[],
  complete: ReadonlySet<string>,
): PathItem | undefined {
  for (let i = 0; i < path.length; i++) {
    if (!complete.has(path[i].id) && isUnlocked(i, path, complete)) return path[i];
  }
  return undefined;
}
