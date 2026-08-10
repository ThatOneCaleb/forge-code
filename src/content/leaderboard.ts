/**
 * Mock leaderboard for the ranked-ladder stub. This is the exact shape a future
 * backend endpoint will return, so wiring real data later is a drop-in swap.
 */
export interface LeaderboardEntry {
  rank: number;
  handle: string;
  stars: number;
  bestStreak: number;
  /** True for the local player's row. */
  you?: boolean;
}

export interface Season {
  id: string;
  name: string;
  /** ISO date the season ends. */
  endsOn: string;
  entries: LeaderboardEntry[];
}

/** Placeholder rivals. Replace `SEASON.entries` with a fetch() when the backend lands. */
export const MOCK_RIVALS: Omit<LeaderboardEntry, "rank">[] = [
  { handle: "circuit_sage", stars: 24, bestStreak: 12 },
  { handle: "byte_forge", stars: 22, bestStreak: 9 },
  { handle: "loopwright", stars: 19, bestStreak: 7 },
  { handle: "nullsmith", stars: 17, bestStreak: 6 },
  { handle: "ada_jr", stars: 14, bestStreak: 5 },
  { handle: "sprocket_fan", stars: 11, bestStreak: 4 },
  { handle: "recursor", stars: 8, bestStreak: 3 },
  { handle: "greenhorn", stars: 4, bestStreak: 2 },
];

export const SEASON: Omit<Season, "entries"> = {
  id: "s1",
  name: "Season 1 · The Forge",
  endsOn: "2026-12-25",
};

/** Rank the player in among the mock rivals by stars, then best streak. */
export function rankedBoard(you: { stars: number; bestStreak: number }): LeaderboardEntry[] {
  const rows = [...MOCK_RIVALS, { ...you, handle: "you", you: true }];
  rows.sort((a, b) => b.stars - a.stars || b.bestStreak - a.bestStreak);
  return rows.map((r, i) => ({ ...r, rank: i + 1 }));
}
