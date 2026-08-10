import { describe, expect, it } from "vitest";
import { activeStreak, dayDiff, emptyStreak, recordSolve } from "./streak";

describe("dayDiff", () => {
  it("counts whole days between dates", () => {
    expect(dayDiff("2026-08-08", "2026-08-09")).toBe(1);
    expect(dayDiff("2026-08-08", "2026-08-08")).toBe(0);
    expect(dayDiff("2026-08-01", "2026-08-08")).toBe(7);
  });
  it("handles month boundaries", () => {
    expect(dayDiff("2026-01-31", "2026-02-01")).toBe(1);
  });
});

describe("recordSolve", () => {
  it("starts a streak at 1 on the first solve", () => {
    const s = recordSolve(emptyStreak, "2026-08-08");
    expect(s.current).toBe(1);
    expect(s.best).toBe(1);
    expect(s.lastSolvedDate).toBe("2026-08-08");
  });

  it("is a no-op for a second solve on the same day", () => {
    let s = recordSolve(emptyStreak, "2026-08-08");
    s = recordSolve(s, "2026-08-08");
    expect(s.current).toBe(1);
  });

  it("extends the streak on consecutive days", () => {
    let s = recordSolve(emptyStreak, "2026-08-08");
    s = recordSolve(s, "2026-08-09");
    s = recordSolve(s, "2026-08-10");
    expect(s.current).toBe(3);
    expect(s.best).toBe(3);
  });

  it("resets after a gap but keeps the best", () => {
    let s = recordSolve(emptyStreak, "2026-08-08");
    s = recordSolve(s, "2026-08-09"); // current 2
    s = recordSolve(s, "2026-08-15"); // big gap → reset
    expect(s.current).toBe(1);
    expect(s.best).toBe(2);
  });
});

describe("activeStreak", () => {
  it("shows the run when the last solve was today or yesterday", () => {
    const s = recordSolve(emptyStreak, "2026-08-08");
    expect(activeStreak(s, "2026-08-08")).toBe(1);
    expect(activeStreak(s, "2026-08-09")).toBe(1);
  });
  it("lapses to 0 once more than a day has passed", () => {
    const s = recordSolve(emptyStreak, "2026-08-08");
    expect(activeStreak(s, "2026-08-10")).toBe(0);
  });
});
