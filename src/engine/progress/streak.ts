// Pure, deterministic streak logic. Dates are handled as YYYY-MM-DD strings so
// the rules are timezone-stable and trivially testable.

export interface StreakState {
  /** Length of the current consecutive-day run. */
  current: number;
  /** Best run ever achieved. */
  best: number;
  /** Date (YYYY-MM-DD) of the most recent solve, or null if never solved. */
  lastSolvedDate: string | null;
}

export const emptyStreak: StreakState = { current: 0, best: 0, lastSolvedDate: null };

/** Today's local date as YYYY-MM-DD. */
export function todayISO(now: Date = new Date()): string {
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, "0");
  const d = String(now.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

/** Whole-day difference between two YYYY-MM-DD dates (b - a). */
export function dayDiff(a: string, b: string): number {
  const da = Date.parse(a + "T00:00:00Z");
  const db = Date.parse(b + "T00:00:00Z");
  return Math.round((db - da) / 86_400_000);
}

/**
 * Record a solve on `today`. Same-day solves don't change the streak; a solve
 * the day after extends it; any longer gap restarts it at 1.
 */
export function recordSolve(state: StreakState, today: string): StreakState {
  if (state.lastSolvedDate === today) return state; // already counted today

  let current: number;
  if (state.lastSolvedDate && dayDiff(state.lastSolvedDate, today) === 1) {
    current = state.current + 1;
  } else {
    current = 1;
  }
  return {
    current,
    best: Math.max(state.best, current),
    lastSolvedDate: today,
  };
}

/**
 * The streak to *display* today. The stored `current` is only "alive" if the
 * last solve was today or yesterday; otherwise the run has lapsed to 0.
 */
export function activeStreak(state: StreakState, today: string): number {
  if (!state.lastSolvedDate) return 0;
  const gap = dayDiff(state.lastSolvedDate, today);
  return gap <= 1 ? state.current : 0;
}
