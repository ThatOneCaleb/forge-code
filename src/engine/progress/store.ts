import { create } from "zustand";
import { persist } from "zustand/middleware";
import type { Language } from "../types";
import { emptyStreak, recordSolve, todayISO, type StreakState } from "./streak";
import { submitScore } from "../../lib/leaderboard-api";

function pushScore(playerSeed: string, handle: string, solved: string[], streak: StreakState) {
  if (!handle) return;
  submitScore({ player_seed: playerSeed, handle, stars: solved.length, best_streak: streak.best });
}

/** Stable random id used to seed each player's unique puzzle inputs. */
function makePlayerSeed(): string {
  return Math.random().toString(36).slice(2) + Date.now().toString(36);
}

interface ProgressState {
  /** Seeds per-player puzzle generation; stable across sessions. */
  playerSeed: string;
  /** Display name chosen by the player. */
  handle: string;
  /** Solved challenge ids. */
  solved: string[];
  /** Read (completed) lesson ids. */
  readLessons: string[];
  streak: StreakState;
  /** Preferred language, remembered across sessions. */
  language: Language;
  /** Per-challenge, per-language code drafts. */
  drafts: Record<string, Partial<Record<Language, string>>>;

  isSolved: (id: string) => boolean;
  markSolved: (id: string) => void;
  markLessonRead: (id: string) => void;
  /** New random inputs for every generated puzzle. */
  reroll: () => void;
  setLanguage: (lang: Language) => void;
  setHandle: (handle: string) => void;
  setDraft: (id: string, lang: Language, code: string) => void;
  getDraft: (id: string, lang: Language) => string | undefined;
  reset: () => void;
}

export const useProgress = create<ProgressState>()(
  persist(
    (set, get) => ({
      playerSeed: makePlayerSeed(),
      handle: "",
      solved: [],
      readLessons: [],
      streak: emptyStreak,
      language: "python",
      drafts: {},

      isSolved: (id) => get().solved.includes(id),

      markSolved: (id) =>
        set((state) => {
          const alreadySolved = state.solved.includes(id);
          const newSolved = alreadySolved ? state.solved : [...state.solved, id];
          const newStreak = alreadySolved ? state.streak : recordSolve(state.streak, todayISO());
          if (!alreadySolved) pushScore(state.playerSeed, state.handle, newSolved, newStreak);
          return { solved: newSolved, streak: newStreak };
        }),

      markLessonRead: (id) =>
        set((state) =>
          state.readLessons.includes(id)
            ? state
            : { readLessons: [...state.readLessons, id] },
        ),

      reroll: () => set({ playerSeed: makePlayerSeed() }),

      setLanguage: (language) => set({ language }),
      setHandle: (handle) => {
        const s = get();
        set({ handle });
        pushScore(s.playerSeed, handle, s.solved, s.streak);
      },

      setDraft: (id, lang, code) =>
        set((state) => ({
          drafts: { ...state.drafts, [id]: { ...state.drafts[id], [lang]: code } },
        })),

      getDraft: (id, lang) => get().drafts[id]?.[lang],

      reset: () =>
        set({
          solved: [],
          readLessons: [],
          streak: emptyStreak,
          drafts: {},
          playerSeed: makePlayerSeed(),
        }),
    }),
    {
      name: "forge-code-progress",
      version: 1,
    },
  ),
);
