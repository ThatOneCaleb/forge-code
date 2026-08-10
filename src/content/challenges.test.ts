import { describe, expect, it } from "vitest";
import { gradeOutput } from "../engine/runner/grade";
import { makeRng } from "../engine/rng";
import { CHALLENGES } from "./challenges";

/** Execute a JS `solve(text)` source the same way the worker does, in-process. */
function runJsSolution(source: string, input: string): string {
  const factory = new Function(
    `"use strict";\n${source}\n;return typeof solve === "function" ? solve : null;`,
  );
  const solve = factory() as ((t: string) => unknown) | null;
  if (typeof solve !== "function") throw new Error("no solve() defined");
  const out = solve(input);
  return out === undefined || out === null ? "" : String(out);
}

describe("ladder integrity", () => {
  it("has sequential 1-based order with no gaps", () => {
    CHALLENGES.forEach((c, i) => expect(c.order).toBe(i + 1));
  });

  it("has unique ids", () => {
    const ids = new Set(CHALLENGES.map((c) => c.id));
    expect(ids.size).toBe(CHALLENGES.length);
  });

  it("never decreases in difficulty along the ladder", () => {
    for (let i = 1; i < CHALLENGES.length; i++) {
      expect(CHALLENGES[i].difficulty).toBeGreaterThanOrEqual(CHALLENGES[i - 1].difficulty);
    }
  });

  it("every Gauntlet challenge has a per-player generator (no hardcodable static answer)", () => {
    for (const c of CHALLENGES) {
      if (c.track !== "gauntlet") continue;
      expect(typeof c.generate, `${c.id} is missing a generator`).toBe("function");
    }
  });

  it("generated inputs are large (many items), like Advent of Code", () => {
    for (const c of CHALLENGES) {
      if (!c.generate) continue;
      const { input } = c.generate(makeRng(3));
      // A real puzzle, not a single value: many lines or a big block of text.
      const big = input.length > 120 || input.split("\n").length >= 12;
      expect(big, `${c.id}: generated input looks too small (${input.length} chars)`).toBe(true);
    }
  });

  it("gives every rung the required content", () => {
    for (const c of CHALLENGES) {
      expect(c.title).toBeTruthy();
      expect(c.prompt).toBeTruthy();
      expect(c.concept).toBeTruthy();
      expect(c.story).toBeTruthy();
      expect(c.hints.length).toBeGreaterThan(0);
      expect(c.starterCode.python).toContain("solve");
      expect(c.starterCode.javascript).toContain("solve");
      expect(c.solution.python).toContain("solve");
      expect(c.solution.javascript).toContain("solve");
    }
  });

  it("every JavaScript reference solution produces the expected answer (worked example)", () => {
    for (const c of CHALLENGES) {
      const got = runJsSolution(c.solution.javascript, c.input);
      expect(
        gradeOutput(got, c.expected).correct,
        `${c.id}: expected "${c.expected}", got "${got}"`,
      ).toBe(true);
    }
  });

  it("every generator agrees with its reference solution, across seeds", () => {
    for (const c of CHALLENGES) {
      if (!c.generate) continue;
      for (const seed of [1, 42, 1337, 99999]) {
        const instance = c.generate(makeRng(seed));
        expect(instance.input.length, `${c.id}: empty generated input`).toBeGreaterThan(0);
        const got = runJsSolution(c.solution.javascript, instance.input);
        expect(
          gradeOutput(got, instance.expected).correct,
          `${c.id} seed ${seed}: generator said "${instance.expected}", solver got "${got}"`,
        ).toBe(true);
      }
    }
  });

  it("generators are deterministic for a given seed", () => {
    for (const c of CHALLENGES) {
      if (!c.generate) continue;
      const a = c.generate(makeRng(7));
      const b = c.generate(makeRng(7));
      expect(a.input, `${c.id}: not deterministic`).toBe(b.input);
      expect(a.expected).toBe(b.expected);
    }
  });
});
