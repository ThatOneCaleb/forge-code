// Pure, framework-free core types. No React, no DOM assumptions here.

import type { Rng } from "./rng";

export type Language = "python" | "javascript";

/** The two learning tracks. Academy = kids/learn (lesson before every challenge);
 *  Gauntlet = Advent-of-Code-hard generated puzzles (optional technique lessons). */
export type Track = "academy" | "gauntlet";

/** A concrete puzzle: the input handed to solve(), and the answer it must produce. */
export interface PuzzleInstance {
  input: string;
  expected: string;
}

export const LANGUAGES: Language[] = ["python", "javascript"];

export const LANGUAGE_LABELS: Record<Language, string> = {
  python: "Python",
  javascript: "JavaScript",
};

/**
 * A single rung on the curriculum ladder.
 * The player writes a `solve(text)` function; `text` is `input`, and the
 * function's return value (stringified) is compared to `expected`.
 */
export interface Challenge {
  id: string;
  /** Which track this challenge belongs to. */
  track: Track;
  /** 1-based position in the ordered ladder. Difficulty is non-decreasing in this order. */
  order: number;
  title: string;
  topic: string;
  /** 1..5 — must never decrease as `order` increases. */
  difficulty: number;
  /** The one new idea this rung introduces. */
  concept: string;
  /** Narrative beat: a character's problem that advances the Forge story. */
  story: string;
  /** AoC-style problem statement (plain text, newlines preserved). */
  prompt: string;
  /**
   * The worked-example input handed to `solve(text)`. For generated challenges
   * this is the small example shown in the prompt; the player's real puzzle
   * comes from `generate`.
   */
  input: string;
  /** The answer for `input` (compared after normalization). */
  expected: string;
  /**
   * Optional per-player puzzle generator (Advent-of-Code style). When present,
   * each player gets a unique input + its computed answer, seeded stably to them.
   */
  generate?: (rng: Rng) => PuzzleInstance;
  starterCode: Record<Language, string>;
  /** Reference solution per language. JS solutions are executed by the ladder-integrity test. */
  solution: Record<Language, string>;
  hints: string[];
}

/** Result of executing user code in a worker. */
export interface RunResult {
  ok: boolean;
  /** Stringified return value of `solve(text)`. */
  output: string;
  /** Captured stdout / console.log lines, for the player to debug with. */
  logs: string[];
  error?: string;
  durationMs: number;
}

/** Result of comparing a RunResult's output to the expected answer. */
export interface GradeResult {
  correct: boolean;
  expected: string;
  got: string;
}

/** A small pre-filled, working demo the learner runs inside a lesson. */
export interface LessonExample {
  prompt: string;
  input: string;
  expected: string;
  /** Working code per language — pre-loaded so Run shows it succeed. */
  code: Record<Language, string>;
}

/**
 * A teaching page that sits between challenges on the path. Read-and-continue,
 * with a runnable example that demonstrates the concept.
 */
export interface Lesson {
  id: string;
  title: string;
  topic: string;
  concept: string;
  /** Id of the challenge this lesson is inserted directly before. */
  before: string;
  /** Teaching text. Supports `## heading`, `- bullet`, and ```lang fenced``` code. */
  body: string;
  example: LessonExample;
}

/** One node on the unified learning path: either a lesson or a challenge. */
export type PathItem =
  | { kind: "lesson"; id: string; order: number; lesson: Lesson }
  | { kind: "challenge"; id: string; order: number; challenge: Challenge };

