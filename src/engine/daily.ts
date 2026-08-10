import { DAILY_CHALLENGES, DAILY_LAUNCH_DATE } from "../content/daily-challenges";
import type { DailyChallenge } from "../content/daily-challenges";
import { makeRng, hashSeed } from "./rng";

export type { DailyChallenge };

const LAUNCH_MS = new Date(DAILY_LAUNCH_DATE + "T00:00:00Z").getTime();
const DAY_MS = 1000 * 60 * 60 * 24;

/** How many days since launch (0 = launch day). */
export function daysSinceLaunch(): number {
  return Math.floor((Date.now() - LAUNCH_MS) / DAY_MS);
}

/** ISO date string for a given day index. */
export function dateForDay(dayIndex: number): string {
  return new Date(LAUNCH_MS + dayIndex * DAY_MS).toISOString().slice(0, 10);
}

/** Today's ISO date (UTC). */
export function todayDateString(): string {
  return dateForDay(daysSinceLaunch());
}

/** Today's challenge. Always the same for everyone on the same UTC day. */
export function getTodayChallenge(): DailyChallenge {
  const idx = daysSinceLaunch() % DAILY_CHALLENGES.length;
  return DAILY_CHALLENGES[idx];
}

/** Get a specific day's challenge (for viewing past days). */
export function getChallengeForDay(dayIndex: number): DailyChallenge | null {
  if (dayIndex < 0 || dayIndex >= DAILY_CHALLENGES.length) return null;
  return DAILY_CHALLENGES[dayIndex % DAILY_CHALLENGES.length];
}

/** Generate this player's specific input for a daily challenge. */
export function dailyInstance(challenge: DailyChallenge, dateStr: string, playerSeed: string) {
  const rng = makeRng(hashSeed(`daily:${dateStr}:${playerSeed}`));
  return challenge.generate(rng);
}
