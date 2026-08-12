import { useProgress } from "../engine/progress/store";
import { activeStreak, todayISO } from "../engine/progress/streak";
import { CHALLENGES } from "../content/challenges";
import { EmberCoin } from "./EmberCoin";

/** The live streak, pinned in the header. */
export function StreakBadge() {
  const streak = useProgress((s) => s.streak);
  const days = activeStreak(streak, todayISO());
  const alive = days > 0;

  return (
    <div
      title={alive ? `${days}-day streak · best ${streak.best}` : "Solve a challenge to start a streak"}
      className="flex items-center gap-1.5 rounded-full border px-3 py-1 font-mono text-sm"
      style={alive
        ? { borderColor: "rgba(234,88,12,0.35)", background: "rgba(234,88,12,0.1)", color: "#C2440C" }
        : { borderColor: "rgba(32,46,68,0.2)", background: "rgba(32,46,68,0.06)", color: "#4A5568" }
      }
    >
      <span className="font-bold">{days}</span>
      <span style={{ color: "#4A5568" }}>day streak</span>
    </div>
  );
}

function computeEmbers(solved: string[]): number {
  const solvedSet = new Set(solved);
  return CHALLENGES.reduce(
    (total, c) => total + (solvedSet.has(c.id) ? c.difficulty * 5 : 0),
    0,
  );
}

/** Ember count badge — lives in the header next to streak. */
export function EmberBadge() {
  const solved = useProgress((s) => s.solved);
  const embers = computeEmbers(solved);
  const hasEmbers = embers > 0;

  return (
    <div
      title={`${embers} embers earned`}
      className="flex items-center gap-1.5 rounded-full border px-2.5 py-1"
      style={
        hasEmbers
          ? { borderColor: "rgba(234,88,12,0.35)", background: "rgba(234,88,12,0.08)" }
          : { borderColor: "rgba(32,46,68,0.2)", background: "rgba(32,46,68,0.06)" }
      }
    >
      <EmberCoin size={16} />
      <span
        style={{
          fontFamily: '"Chakra Petch", sans-serif',
          fontSize: 13,
          fontWeight: 700,
          color: hasEmbers ? "#EA580C" : "#4A5568",
          letterSpacing: "-0.01em",
        }}
      >
        {embers}
      </span>
    </div>
  );
}

export { computeEmbers };
