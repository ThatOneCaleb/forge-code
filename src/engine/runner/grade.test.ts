import { describe, expect, it } from "vitest";
import { gradeOutput, gradeRun, normalize } from "./grade";

describe("normalize", () => {
  it("trims ends and trailing per-line whitespace", () => {
    expect(normalize("  hi  ")).toBe("hi");
    expect(normalize("a  \nb\t\n")).toBe("a\nb");
  });
  it("unifies CRLF to LF", () => {
    expect(normalize("a\r\nb")).toBe("a\nb");
  });
});

describe("gradeOutput", () => {
  it("matches ignoring surrounding whitespace", () => {
    expect(gradeOutput("55", "55").correct).toBe(true);
    expect(gradeOutput(" 55\n", "55").correct).toBe(true);
  });
  it("rejects wrong answers", () => {
    expect(gradeOutput("54", "55").correct).toBe(false);
  });
});

describe("gradeRun", () => {
  it("is never correct when the run failed", () => {
    const r = gradeRun({ ok: false, output: "55", logs: [], durationMs: 1 }, "55");
    expect(r.correct).toBe(false);
  });
});
