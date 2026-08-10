import { create } from "zustand";
import { persist } from "zustand/middleware";
import type { Language } from "../types";
import { emptyStreak, recordSolve, todayISO, type StreakState } from "./streak";

/** Stable random id used to seed each player's unique puzzle inputs. */
function makePlayerSeed(): string {
  return Math.random().toString(36).slice(2) + Date.now().toString(36);
}

interface ProgressState {
  /** Seeds per-player puzzle generation; stable across sessions. */
  playerSeed: string;
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
  setDraft: (id: string, lang: Language, code: string) => void;
  getDraft: (id: string, lang: Language) => string | undefined;
  reset: () => void;
}

export const useProgress = create<ProgressState>()(
  persist(
    (set, get) => ({
      playerSeed: makePlayerSeed(),
      solved: [],
      readLessons: [],
      streak: emptyStreak,
      language: "python",
      drafts: {},

      isSolved: (id) => get().solved.includes(id),

      markSolved: (id) =>
        set((state) => {
          const alreadySolved = state.solved.includes(id);
          return {
            solved: alreadySolved ? state.solved : [...state.solved, id],
            // Streak only advances the first time a NEW rung is solved.
            streak: alreadySolved ? state.streak : recordSolve(state.streak, todayISO()),
          };
        }),

      markLessonRead: (id) =>
        set((state) =>
          state.readLessons.includes(id)
            ? state
            : { readLessons: [...state.readLessons, id] },
        ),

      reroll: () => set({ playerSeed: makePlayerSeed() }),

      setLanguage: (language) => set({ language }),

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
