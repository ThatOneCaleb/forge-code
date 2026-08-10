import { supabase } from "./supabase";

export interface ScoreRow {
  player_seed: string;
  handle: string;
  stars: number;
  best_streak: number;
}

export async function submitScore(row: ScoreRow): Promise<void> {
  await supabase.from("scores").upsert(row, { onConflict: "player_seed" });
}

/** Returns true if the handle is already taken by a different player. */
export async function isHandleTaken(handle: string, playerSeed: string): Promise<boolean> {
  const { data } = await supabase
    .from("scores")
    .select("player_seed")
    .eq("handle", handle)
    .neq("player_seed", playerSeed)
    .limit(1);
  return (data?.length ?? 0) > 0;
}

export async function fetchLeaderboard(): Promise<Omit<ScoreRow, "player_seed">[]> {
  const { data } = await supabase
    .from("scores")
    .select("handle, stars, best_streak")
    .order("stars", { ascending: false })
    .order("best_streak", { ascending: false })
    .limit(100);
  return data ?? [];
}

// ── Daily leaderboard ──────────────────────────────────────────────────────

export interface DailyScoreRow {
  date: string;
  handle: string;
  player_seed: string;
  time_seconds: number;
}

export async function submitDailyScore(row: DailyScoreRow): Promise<void> {
  await supabase.from("daily_scores").upsert(row, { onConflict: "date,player_seed" });
}

export async function fetchDailyLeaderboard(date: string): Promise<{ handle: string; time_seconds: number }[]> {
  const { data } = await supabase
    .from("daily_scores")
    .select("handle, time_seconds")
    .eq("date", date)
    .order("time_seconds", { ascending: true })
    .limit(25);
  return data ?? [];
}
