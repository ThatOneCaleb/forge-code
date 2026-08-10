import type { GradeResult, RunResult } from "../types";

/** Normalize an answer for comparison: unify newlines, trim trailing space per line, trim ends. */
export function normalize(s: string): string {
  return s
    .replace(/\r\n/g, "\n")
    .replace(/[ \t]+$/gm, "")
    .replace(/\n+$/,"")
    .trim();
}

/** Compare a produced answer to the expected answer. Pure + deterministic. */
export function gradeOutput(output: string, expected: string): GradeResult {
  return {
    correct: normalize(output) === normalize(expected),
    expected,
    got: output,
  };
}

/** Convenience: grade a full RunResult (a failed run is never correct). */
export function gradeRun(result: RunResult, expected: string): GradeResult {
  if (!result.ok) return { correct: false, expected, got: result.output };
  return gradeOutput(result.output, expected);
}
