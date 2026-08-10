import { useEffect, useState } from "react";
import { useProgress } from "../../engine/progress/store";
import { Reveal } from "../../components/motion";
import { Sprocket } from "../../components/ui/sprocket";
import { fetchLeaderboard } from "../../lib/leaderboard-api";

interface Row {
  rank: number;
  handle: string;
  stars: number;
  bestStreak: number;
  you: boolean;
}

export function CompeteScreen() {
  const solvedList = useProgress((s) => s.solved);
  const streak = useProgress((s) => s.streak);
  const handle = useProgress((s) => s.handle);

  const yourStars = solvedList.length;
  const yourStreak = streak.best;

  const [rows, setRows] = useState<Row[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchLeaderboard().then((data) => {
      // Merge remote rows with local "you" row
      const remote = data.filter((r) => !handle || r.handle !== handle);
      const all = handle
        ? [{ handle, stars: yourStars, best_streak: yourStreak }, ...remote]
        : remote;

      const sorted = all
        .sort((a, b) => b.stars - a.stars || b.best_streak - a.best_streak)
        .map((r, i) => ({
          rank: i + 1,
          handle: r.handle,
          stars: r.stars,
          bestStreak: r.best_streak,
          you: r.handle === handle && !!handle,
        }));

      setRows(sorted);
      setLoading(false);
    });
  }, [handle, yourStars, yourStreak]);

  const yourRow = rows.find((r) => r.you);
  const yourRank = yourRow?.rank ?? rows.length + 1;

  return (
    <div className="mx-auto max-w-3xl flex flex-col gap-8 px-6 py-10 lg:px-8">

      {/* ── Header ── */}
      <div className="flex items-start gap-5">
        <div className="shrink-0 mt-1">
          <Sprocket size={48} mood={yourRank <= 3 ? "happy" : "neutral"} />
        </div>
        <div className="flex-1">
          <p className="font-mono text-[11px] font-bold uppercase tracking-[0.28em] text-ember">Compete</p>
          <div className="mt-1 flex items-baseline gap-3">
            <h1 className="font-display text-3xl font-black tracking-tight" style={{ color: "#202e44" }}>The Ranked Forge</h1>
          </div>
          <p className="mt-1 text-sm" style={{ color: "rgba(32,46,68,0.55)" }}>
            Live rankings across all players. Solve more challenges to climb.
          </p>
        </div>
      </div>

      {/* ── Your rank card ── */}
      {yourRow && (
        <div
          className="relative overflow-hidden rounded-2xl border p-6"
          style={{ background: "rgba(255,255,255,0.6)", borderColor: "rgba(194,68,12,0.2)" }}
        >
          <div className="absolute inset-x-0 top-0 h-px" style={{ background: "linear-gradient(90deg, rgba(234,88,12,0.6), transparent)" }} />
          <div className="flex items-center gap-5">
            <div>
              <p className="font-mono text-[10px] font-bold uppercase tracking-wider text-ember">your rank</p>
              <p className="font-display font-black leading-none text-ember" style={{ fontSize: "clamp(3rem,8vw,4.5rem)" }}>
                #{yourRank}
              </p>
            </div>
            <div className="h-16 w-px" style={{ background: "rgba(32,46,68,0.15)" }} />
            <div className="flex gap-8">
              <div>
                <p className="font-mono text-[10px] uppercase tracking-wider" style={{ color: "rgba(32,46,68,0.4)" }}>Stars</p>
                <p className="mt-0.5 font-display text-2xl font-bold" style={{ color: "#202e44" }}>{yourStars}</p>
              </div>
              <div>
                <p className="font-mono text-[10px] uppercase tracking-wider" style={{ color: "rgba(32,46,68,0.4)" }}>Best streak</p>
                <p className="mt-0.5 font-display text-2xl font-bold" style={{ color: "#202e44" }}>{yourStreak}</p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ── Leaderboard ── */}
      <Reveal delay={0.05}>
        {loading ? (
          <div className="text-center py-12 font-mono text-sm" style={{ color: "rgba(32,46,68,0.35)" }}>
            Loading rankings...
          </div>
        ) : rows.length === 0 ? (
          <div className="text-center py-12 font-mono text-sm" style={{ color: "rgba(32,46,68,0.35)" }}>
            No scores yet — be the first to solve a challenge.
          </div>
        ) : (
          <div className="flex flex-col gap-2">
            {rows.map((row, i) => (
              <div
                key={row.handle}
                className="flex items-center gap-4 rounded-xl border px-5 py-3.5"
                style={{
                  background: row.you ? "rgba(194,68,12,0.06)" : "rgba(255,255,255,0.55)",
                  borderColor: row.you ? "rgba(194,68,12,0.25)" : "rgba(32,46,68,0.1)",
                  boxShadow: row.you ? "0 0 20px -8px rgba(194,68,12,0.2)" : "none",
                }}
              >
                <span
                  className="w-8 shrink-0 font-display text-lg font-black"
                  style={{ color: i === 0 ? "#D97706" : i === 1 ? "#64748B" : i === 2 ? "#92400E" : "rgba(32,46,68,0.35)" }}
                >
                  {row.rank}
                </span>

                <div
                  className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full font-display text-sm font-bold"
                  style={{
                    background: row.you ? "rgba(194,68,12,0.15)" : `hsl(${(row.handle.charCodeAt(0) * 47) % 360}, 40%, 75%)`,
                    color: row.you ? "#C2440C" : "#202e44",
                  }}
                >
                  {row.handle[0]?.toUpperCase()}
                </div>

                <span className="flex-1 font-display text-sm font-semibold" style={{ color: row.you ? "#C2440C" : "#202e44" }}>
                  {row.handle}{row.you && " (you)"}
                </span>

                <div className="flex items-center gap-5">
                  <div className="text-right">
                    <p className="font-mono text-[10px]" style={{ color: "rgba(32,46,68,0.4)" }}>stars</p>
                    <p className="font-mono text-sm font-bold" style={{ color: row.you ? "#C2440C" : "#202e44" }}>{row.stars}</p>
                  </div>
                  <div className="text-right">
                    <p className="font-mono text-[10px]" style={{ color: "rgba(32,46,68,0.4)" }}>streak</p>
                    <p className="font-mono text-sm font-bold" style={{ color: row.you ? "#C2440C" : "#202e44" }}>{row.bestStreak}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </Reveal>
    </div>
  );
}
