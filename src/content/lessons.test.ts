import { describe, expect, it } from "vitest";
import { gradeOutput } from "../engine/runner/grade";
import { CHALLENGES } from "./challenges";
import { LESSONS } from "./lessons";

function runJsSolution(source: string, input: string): string {
  const factory = new Function(
    `"use strict";\n${source}\n;return typeof solve === "function" ? solve : null;`,
  );
  const solve = factory() as ((t: string) => unknown) | null;
  if (typeof solve !== "function") throw new Error("no solve() defined");
  const out = solve(input);
  return out === undefined || out === null ? "" : String(out);
}

const challengeIds = new Set(CHALLENGES.map((c) => c.id));

describe("lesson integrity", () => {
  it("has unique ids that don't collide with challenge ids", () => {
    const ids = new Set(LESSONS.map((l) => l.id));
    expect(ids.size).toBe(LESSONS.length);
    for (const l of LESSONS) expect(challengeIds.has(l.id)).toBe(false);
  });

  it("anchors every lesson before a real challenge", () => {
    for (const l of LESSONS) {
      expect(challengeIds.has(l.before), `${l.id}: unknown anchor ${l.before}`).toBe(true);
    }
  });

  it("gives every lesson body + a runnable example in both languages", () => {
    for (const l of LESSONS) {
      expect(l.body.trim().length).toBeGreaterThan(0);
      expect(l.example.code.python).toContain("solve");
      expect(l.example.code.javascript).toContain("solve");
    }
  });

  it("every lesson's JS example runs to its expected answer", () => {
    for (const l of LESSONS) {
      const got = runJsSolution(l.example.code.javascript, l.example.input);
      expect(
        gradeOutput(got, l.example.expected).correct,
        `${l.id}: example expected "${l.example.expected}", got "${got}"`,
      ).toBe(true);
    }
  });
});
