import { rankedBoard } from "../../content/leaderboard";
import { useProgress } from "../../engine/progress/store";
import { Reveal } from "../../components/motion";
import { Sprocket } from "../../components/ui/sprocket";

export function CompeteScreen() {
  const solvedList = useProgress((s) => s.solved);
  const streak = useProgress((s) => s.streak);
  const board = rankedBoard({ stars: solvedList.length, bestStreak: streak.best });
  const yourRow = board.find((r) => r.you);
  const yourRank = yourRow?.rank ?? board.length;

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
            <span className="rounded-full border border-ember/40 bg-ember/10 px-3 py-0.5 font-mono text-xs text-ember-bright">
              live ladder coming soon
            </span>
          </div>
          <p className="mt-1 text-sm" style={{ color: "rgba(32,46,68,0.55)" }}>
            Real ranked play with accounts is being forged. For now, here's your practice standing.
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
                <p className="mt-0.5 font-display text-2xl font-bold" style={{ color: "#202e44" }}>{yourRow.stars}</p>
              </div>
              <div>
                <p className="font-mono text-[10px] uppercase tracking-wider" style={{ color: "rgba(32,46,68,0.4)" }}>Best streak</p>
                <p className="mt-0.5 font-display text-2xl font-bold" style={{ color: "#202e44" }}>{yourRow.bestStreak}</p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ── Leaderboard ── */}
      <Reveal delay={0.05}>
        <div className="flex flex-col gap-2">
          {board.map((row, i) => (
            <div
              key={row.handle}
              className="flex items-center gap-4 rounded-xl border px-5 py-3.5"
              style={{
                background: row.you ? "rgba(194,68,12,0.06)" : "rgba(255,255,255,0.55)",
                borderColor: row.you ? "rgba(194,68,12,0.25)" : "rgba(32,46,68,0.1)",
                boxShadow: row.you ? "0 0 20px -8px rgba(194,68,12,0.2)" : "none",
              }}
            >
              {/* Rank */}
              <span
                className="w-8 shrink-0 font-display text-lg font-black"
                style={{ color: i === 0 ? "#D97706" : i === 1 ? "#64748B" : i === 2 ? "#92400E" : "rgba(32,46,68,0.35)" }}
              >
                {row.rank}
              </span>

              {/* Avatar circle */}
              <div
                className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full font-display text-sm font-bold"
                style={{
                  background: row.you
                    ? "rgba(194,68,12,0.15)"
                    : `hsl(${(row.handle.charCodeAt(0) * 47) % 360}, 40%, 75%)`,
                  color: row.you ? "#C2440C" : "#202e44",
                }}
              >
                {row.you ? "Y" : row.handle[0].toUpperCase()}
              </div>

              {/* Name */}
              <span className="flex-1 font-display text-sm font-semibold" style={{ color: row.you ? "#C2440C" : "#202e44" }}>
                {row.you ? "You" : row.handle}
              </span>

              {/* Stats */}
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
      </Reveal>
    </div>
  );
}
