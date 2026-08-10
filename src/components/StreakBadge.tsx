import { useProgress } from "../engine/progress/store";
import { activeStreak, todayISO } from "../engine/progress/streak";

/** The live streak, pinned in the header. Flame flickers while the run is alive. */
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
