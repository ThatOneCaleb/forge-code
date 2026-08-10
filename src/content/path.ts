import type { Challenge, Lesson, PathItem, Track } from "../engine/types";
import { CHALLENGES } from "./challenges";
import { LESSONS, LESSONS_BY_ID } from "./lessons";

const lessonsByAnchor = new Map<string, Lesson[]>();
for (const lesson of LESSONS) {
  const arr = lessonsByAnchor.get(lesson.before) ?? [];
  arr.push(lesson);
  lessonsByAnchor.set(lesson.before, arr);
}

/**
 * Build one track's path.
 * - Academy: a lesson is inserted (and gates) before every challenge.
 * - Gauntlet: challenges only (they gate each other); their lessons are
 *   OPTIONAL and surfaced as "learn the technique" links, not path items.
 */
function buildPath(track: Track): PathItem[] {
  const challenges = CHALLENGES.filter((c) => c.track === track).sort((a, b) => a.order - b.order);
  const items: PathItem[] = [];
  let order = 0;
  for (const challenge of challenges) {
    if (track === "academy") {
      for (const lesson of lessonsByAnchor.get(challenge.id) ?? []) {
        items.push({ kind: "lesson", id: lesson.id, order: ++order, lesson });
      }
    }
    items.push({ kind: "challenge", id: challenge.id, order: ++order, challenge });
  }
  return items;
}

export const ACADEMY_PATH: PathItem[] = buildPath("academy");
export const GAUNTLET_PATH: PathItem[] = buildPath("gauntlet");

export function pathForTrack(track: Track): PathItem[] {
  return track === "academy" ? ACADEMY_PATH : GAUNTLET_PATH;
}

/** The path a challenge lives on. */
export function pathForChallenge(challenge: Challenge): PathItem[] {
  return pathForTrack(challenge.track);
}

/** The path a lesson lives on (its anchor challenge's track). Academy only. */
export function pathForLesson(lesson: Lesson): PathItem[] {
  const anchor = CHALLENGES.find((c) => c.id === lesson.before);
  return pathForTrack(anchor?.track ?? "academy");
}

export function indexInPath(path: PathItem[], id: string): number {
  return path.findIndex((item) => item.id === id);
}

/** An optional technique lesson attached to a Gauntlet challenge, if any. */
export function optionalLessonFor(challengeId: string): Lesson | undefined {
  const first = lessonsByAnchor.get(challengeId)?.[0];
  if (!first) return undefined;
  const anchor = CHALLENGES.find((c) => c.id === challengeId);
  return anchor?.track === "gauntlet" ? LESSONS_BY_ID[first.id] : undefined;
}
