import type { Challenge } from "../engine/types";
import { CHALLENGES } from "./challenges";

/** A topic node on the skill tree, derived from the challenge ladder. */
export interface SkillNode {
  topic: string;
  /** Topics that come earlier in the ladder (soft prerequisites). */
  prereqs: string[];
  challengeIds: string[];
  /** First difficulty seen in this topic — used for ordering/labels. */
  minDifficulty: number;
}

/**
 * Derive the skill tree from the ladder: topics in first-appearance order, each
 * depending on the topic before it. Data-only — new challenges extend it free.
 */
function buildSkillTree(ladder: readonly Challenge[]): SkillNode[] {
  const order: string[] = [];
  const byTopic = new Map<string, Challenge[]>();
  for (const c of [...ladder].sort((a, b) => a.order - b.order)) {
    if (!byTopic.has(c.topic)) {
      byTopic.set(c.topic, []);
      order.push(c.topic);
    }
    byTopic.get(c.topic)!.push(c);
  }
  return order.map((topic, i) => {
    const challenges = byTopic.get(topic)!;
    return {
      topic,
      prereqs: i === 0 ? [] : [order[i - 1]],
      challengeIds: challenges.map((c) => c.id),
      minDifficulty: Math.min(...challenges.map((c) => c.difficulty)),
    };
  });
}

export const SKILL_TREE: SkillNode[] = buildSkillTree(CHALLENGES);

/** Progress for one skill node given the set of solved challenge ids. */
export function nodeProgress(
  node: SkillNode,
  solved: ReadonlySet<string>,
): { solved: number; total: number; complete: boolean } {
  const count = node.challengeIds.filter((id) => solved.has(id)).length;
  return { solved: count, total: node.challengeIds.length, complete: count === node.challengeIds.length };
}
