import { Link } from "react-router-dom";
import type { Track } from "../../engine/types";
import { CHALLENGES } from "../../content/challenges";
import { pathForTrack } from "../../content/path";
import { itemStatus } from "../../engine/progress/path";
import { useProgress } from "../../engine/progress/store";
import { ChallengeArt } from "../../components/ui/challenge-art";
import { Sprocket } from "../../components/ui/sprocket";
import { Scroller } from "../../components/ui/scroller";

// ─── Static ───────────────────────────────────────────────────────────────────

interface ActMeta { beforeId: string; roman: string; title: string }

const GAUNTLET_ACTS: ActMeta[] = [
  { beforeId: "is-prime",            roman: "I",   title: "Relighting the Core" },
  { beforeId: "rucksack-priorities", roman: "II",  title: "The Waking Deep" },
  { beforeId: "sealed-vault",        roman: "III", title: "The Endgame" },
  { beforeId: "hazard-descent",      roman: "IV",  title: "The Hidden Layer" },
  { beforeId: "regrowth",            roman: "V",   title: "The Last Forge" },
];

// ─── Act divider ─────────────────────────────────────────────────────────────

function ActHeader({ act, isGauntlet }: { act: ActMeta; isGauntlet: boolean }) {
  return (
    <div style={{
      display: "flex",
      alignItems: "baseline",
      gap: 10,
      padding: "22px 0 8px",
    }}>
      <span style={{
        fontFamily: '"Chakra Petch", sans-serif',
        fontWeight: 900,
        fontSize: 10,
        letterSpacing: "0.2em",
        color: isGauntlet ? "#C2440C" : "#0E7490",
        textTransform: "uppercase",
      }}>
        Act {act.roman}
      </span>
      <span style={{
        fontFamily: '"IBM Plex Sans", sans-serif',
        fontWeight: 500,
        fontSize: 12,
        color: "rgba(152,160,173,0.5)",
      }}>
        {act.title}
      </span>
    </div>
  );
}

// ─── Row ──────────────────────────────────────────────────────────────────────

function PathRow({ item, status, challengeIdx }: {
  item: ReturnType<typeof pathForTrack>[number];
  status: "complete" | "unlocked" | "locked";
  challengeIdx: number;
}) {
  const isLesson = item.kind === "lesson";
  const locked = status === "locked";
  const done = status === "complete";

  const title = item.kind === "lesson" ? item.lesson.title : item.challenge.title;
  const concept = item.kind === "lesson" ? item.lesson.concept : item.challenge.concept;
  const href = item.kind === "lesson" ? `/lesson/${item.id}` : `/challenge/${item.id}`;
  const artId = item.kind === "challenge" ? item.challenge.id : "";

  const accentHex = isLesson ? "#0E7490" : "#B83C0A";

  const row = (
    <div
      className="forge-row"
      data-locked={locked}
      style={{
        display: "grid",
        gridTemplateColumns: "22px 36px 1fr auto",
        alignItems: "center",
        gap: "0 10px",
        padding: "8px 2px",
        opacity: locked ? 0.3 : 1,
        cursor: locked ? "default" : "pointer",
        position: "relative",
        borderBottom: "1px solid rgba(32,46,68,0.08)",
        borderRadius: 4,
      }}
    >
      {/* Index */}
      <span style={{
        fontFamily: '"JetBrains Mono", monospace',
        fontSize: 9,
        fontWeight: 700,
        color: done ? accentHex : "rgba(32,46,68,0.2)",
        letterSpacing: "0.04em",
        textAlign: "right",
      }}>
        {isLesson ? "L" : String(challengeIdx).padStart(2, "0")}
      </span>

      {/* Art */}
      <div style={{ opacity: done ? 0.45 : locked ? 0.3 : 1, display: "flex", alignItems: "center", justifyContent: "center" }}>
        {isLesson
          ? <Sprocket size={28} mood={done ? "happy" : "neutral"} />
          : <ChallengeArt id={artId} size={30} />
        }
      </div>

      {/* Text */}
      <div style={{ minWidth: 0 }}>
        <div style={{
          fontFamily: '"IBM Plex Sans", sans-serif',
          fontWeight: 600,
          fontSize: 13,
          color: done ? "rgba(32,46,68,0.35)" : "#202e44",
          letterSpacing: "0.004em",
          whiteSpace: "nowrap",
          overflow: "hidden",
          textOverflow: "ellipsis",
        }}>
          {title}
        </div>
        <div style={{
          fontFamily: '"IBM Plex Mono", monospace',
          fontSize: 9,
          color: "rgba(32,46,68,0.4)",
          marginTop: 2,
          letterSpacing: "0.03em",
          whiteSpace: "nowrap",
          overflow: "hidden",
          textOverflow: "ellipsis",
        }}>
          {concept}
        </div>
      </div>

      {/* Right meta */}
      <div style={{ display: "flex", alignItems: "center", gap: 8, flexShrink: 0 }}>
        {isLesson && (
          <span style={{
            fontFamily: '"IBM Plex Mono", monospace',
            fontSize: 9,
            color: `${accentHex}88`,
            letterSpacing: "0.1em",
            textTransform: "uppercase",
          }}>
            lsn
          </span>
        )}
        {done
          ? <svg width="11" height="11" viewBox="0 0 11 11" fill="none">
              <path d="M2 5.5L4.5 8L9 3" stroke={accentHex} strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          : !locked && <svg width="6" height="6" viewBox="0 0 6 6" fill="none">
              <circle cx="3" cy="3" r="2.5" stroke="rgba(32,46,68,0.2)" strokeWidth="1" />
            </svg>
        }
      </div>

      {/* Hover accent bar */}
      <div className="forge-row-accent" style={{
        position: "absolute",
        left: -2,
        top: "15%",
        bottom: "15%",
        width: 2,
        borderRadius: 2,
        background: accentHex,
        opacity: 0,
        transition: "opacity 100ms",
      }} />
    </div>
  );

  if (locked) return row;
  return <Link to={href} style={{ display: "block", textDecoration: "none", color: "inherit" }}>{row}</Link>;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

export function PathScreen({ track }: { track: Track }) {
  const solvedList = useProgress((s) => s.solved);
  const readLessons = useProgress((s) => s.readLessons);
  const complete = new Set([...solvedList, ...readLessons]);

  const path = pathForTrack(track);
  const trackChallenges = CHALLENGES.filter((c) => c.track === track);
  const solvedCount = trackChallenges.filter((c) => solvedList.includes(c.id)).length;
  const pct = trackChallenges.length > 0
    ? Math.round((solvedCount / trackChallenges.length) * 100)
    : 0;

  const isGauntlet = track === "gauntlet";
  const accentHex = isGauntlet ? "#C2440C" : "#0E7490";
  const accentBright = isGauntlet ? "#EA580C" : "#0891B2";

  let challengeIdx = 0;

  return (
    <>
      <style>{`
        .forge-row:not([data-locked=true]):hover { background: rgba(42,45,51,0.06); }
        .forge-row:not([data-locked=true]):hover .forge-row-accent { opacity: 1 !important; }
      `}</style>

      <div
        style={{
          height: "calc(100vh - 56px)",
          display: "flex",
          flexDirection: "column",
          padding: "0 40px",
          background: "transparent",
        }}
      >

        {/* ── Header ── */}
        <div style={{ marginBottom: 24, paddingTop: 40, flexShrink: 0 }}>
          <p style={{
            fontFamily: '"IBM Plex Mono", monospace',
            fontSize: 9,
            fontWeight: 700,
            letterSpacing: "0.26em",
            textTransform: "uppercase",
            color: accentHex,
            marginBottom: 8,
          }}>
            {isGauntlet ? "The Gauntlet" : "Academy"}
          </p>
          <div style={{ display: "flex", alignItems: "flex-end", justifyContent: "space-between", gap: 16 }}>
            <h1 style={{
              fontFamily: '"Chakra Petch", sans-serif',
              fontWeight: 900,
              fontSize: "2rem",
              color: "#202e44",
              letterSpacing: "-0.03em",
              lineHeight: 1,
              margin: 0,
            }}>
              {isGauntlet ? "Forge Campaign" : "Learn to Code"}
            </h1>
            <div style={{ textAlign: "right", flexShrink: 0 }}>
              <p style={{
                fontFamily: '"Chakra Petch", sans-serif',
                fontWeight: 900,
                fontSize: "1.3rem",
                color: accentBright,
                letterSpacing: "-0.02em",
                lineHeight: 1,
                margin: "0 0 5px",
              }}>
                {solvedCount}<span style={{ fontSize: "0.7rem", color: "rgba(32,46,68,0.3)", fontWeight: 400, marginLeft: 2 }}>/{trackChallenges.length}</span>
              </p>
              <div style={{ width: 100, height: 2, background: "rgba(32,46,68,0.12)", borderRadius: 1 }}>
                <div style={{
                  height: "100%",
                  width: `${pct}%`,
                  background: `linear-gradient(to right, ${accentHex}, ${accentBright})`,
                  borderRadius: 1,
                  boxShadow: `0 0 6px ${accentHex}60`,
                  transition: "width 500ms cubic-bezier(0.22,1,0.36,1)",
                }} />
              </div>
            </div>
          </div>
        </div>

        {/* ── Scroller: full remaining height, transparent so gradient shows through ── */}
        <Scroller
          hideScrollbar
          size={64}
          style={{
            flex: 1,
            minHeight: 0,
            padding: "0 2px",
          }}
        >
          {path.map((item, i) => {
            const act = isGauntlet ? GAUNTLET_ACTS.find((a) => a.beforeId === item.id) : undefined;
            const status = itemStatus(i, path, complete);
            if (item.kind === "challenge") challengeIdx++;

            return (
              <div key={item.id}>
                {act && <ActHeader act={act} isGauntlet={isGauntlet} />}
                <PathRow item={item} status={status} challengeIdx={challengeIdx} />
              </div>
            );
          })}
          <div style={{ height: 40 }} />
        </Scroller>

      </div>
    </>
  );
}
