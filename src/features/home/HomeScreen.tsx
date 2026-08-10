import { useRef, useState } from "react";
import { Link } from "react-router-dom";
import type { PathItem } from "../../engine/types";
import { CHALLENGES } from "../../content/challenges";
import { pathForTrack } from "../../content/path";
import { nextItem } from "../../engine/progress/path";
import { useProgress } from "../../engine/progress/store";
import { activeStreak, todayISO } from "../../engine/progress/streak";
import { CountUp } from "../../components/motion";
import { GrainOverlay } from "../../components/ui/grain-overlay";
import { EmberField } from "../../components/ui/ember-field";
import heroBg from "../../assets/hero-bg.jpeg";

const ACADEMY_PREVIEW = [
  { n: "01", title: "Hello, Forge" },
  { n: "02", title: "Sum Two" },
  { n: "03", title: "Even or Odd" },
  { n: "04", title: "Absolute Difference" },
  { n: "05", title: "Shout" },
  { n: "06", title: "Reverse It" },
];

const GAUNTLET_ACTS = [
  "Relighting the Core",
  "The Waking Deep",
  "The Endgame",
  "The Hidden Layer",
  "The Last Forge",
];

function hrefFor(item: PathItem) {
  return item.kind === "lesson" ? `/lesson/${item.id}` : `/challenge/${item.id}`;
}

export function HomeScreen() {
  const solvedList = useProgress((s) => s.solved);
  const readLessons = useProgress((s) => s.readLessons);
  const streak = useProgress((s) => s.streak);
  const complete = new Set([...solvedList, ...readLessons]);
  const days = activeStreak(streak, todayISO());
  const done = solvedList.length;

  const academyPath = pathForTrack("academy");
  const gauntletPath = pathForTrack("gauntlet");
  const academyChallenges = CHALLENGES.filter((c) => c.track === "academy");
  const gauntletChallenges = CHALLENGES.filter((c) => c.track === "gauntlet");
  const academySolved = academyChallenges.filter((c) => solvedList.includes(c.id)).length;
  const gauntletSolved = gauntletChallenges.filter((c) => solvedList.includes(c.id)).length;
  const academyNext = nextItem(academyPath, complete);
  const gauntletNext = nextItem(gauntletPath, complete);
  const academyStarted = academySolved > 0;
  const gauntletStarted = gauntletSolved > 0;

  return (
    <div className="flex flex-col">

      {/* ── Hero ── */}
      <section className="relative overflow-hidden border-b border-border">
        {/* Background image, kept cool and visible; only darkened where the headline sits */}
        <div aria-hidden className="pointer-events-none absolute inset-0">
          <div style={{ position: "absolute", inset: 0, backgroundImage: `url(${heroBg})`, backgroundSize: "cover", backgroundPosition: "center", opacity: 0.9, filter: "blur(1.3px)", transform: "scale(1.06)" }} />
          {/* darken the left for headline readability, let the image stay visible on the right */}
          <div style={{ position: "absolute", inset: 0, background: "linear-gradient(90deg, rgba(9,11,15,0.94) 0%, rgba(9,11,15,0.6) 44%, rgba(9,11,15,0.12) 100%)" }} />
          {/* short blend into the page at the very bottom */}
          <div style={{ position: "absolute", inset: 0, background: "linear-gradient(0deg, rgba(42,45,51,0.97) 0%, rgba(42,45,51,0) 16%)" }} />
        </div>
        {/* Ambient radial glows */}
        <div aria-hidden className="pointer-events-none absolute inset-0">
          <div style={{ position: "absolute", inset: 0, background: "radial-gradient(ellipse 900px 600px at 80% 110%, rgba(234,88,12,0.11), transparent)" }} />
          <div style={{ position: "absolute", inset: 0, background: "radial-gradient(ellipse 700px 400px at -10% -20%, rgba(74,144,196,0.07), transparent)" }} />
        </div>
        <EmberField />
        <GrainOverlay opacity={0.035} />
        <div className="relative mx-auto max-w-6xl px-6 lg:px-8" style={{ zIndex: 2 }}>
          <div className="grid items-center gap-12 pt-16 pb-16 lg:grid-cols-[1.05fr_0.95fr] lg:gap-4 lg:pt-24 lg:pb-24">

            {/* Headline */}
            <div>
              <p className="mb-6 font-mono text-[11px] font-bold uppercase tracking-[0.3em] text-ember">
                Forge Code
              </p>
              <h1
                className="font-display font-black leading-[0.9]"
                style={{ fontSize: "clamp(2.75rem, 6.4vw, 6rem)", letterSpacing: "-0.03em" }}
              >
                <span className="text-text">Learn to code.</span>
                <br />
                <span className="text-dim" style={{ fontSize: "0.72em" }}>Solve real </span>
                <span className="text-ember" style={{ fontSize: "0.72em", textShadow: "0 0 45px rgba(234,88,12,0.55)" }}>puzzles.</span>
              </h1>
              <p className="mt-7 max-w-md text-[1rem] text-dim" style={{ lineHeight: 1.7 }}>
                Guided lessons for beginners. Puzzle challenges for pros.
              </p>
              <div className="mt-8 flex flex-wrap items-center gap-3">
                {academyNext && (
                  <Link
                    to={hrefFor(academyNext)}
                    className="rounded-full bg-steel px-6 py-2.5 font-display text-sm font-semibold text-bg transition-opacity hover:opacity-85"
                    style={{ boxShadow: "0 4px 20px -4px rgba(74,144,196,0.5), 0 0 0 1px rgba(74,144,196,0.3)" }}
                  >
                    {academyStarted ? "Continue Academy" : "Start Academy"}
                  </Link>
                )}
                {gauntletNext && (
                  <Link
                    to={hrefFor(gauntletNext)}
                    className="rounded-full border border-ember px-6 py-2.5 font-display text-sm font-semibold text-ember transition-colors hover:bg-ember hover:text-bg"
                    style={{ boxShadow: "0 4px 20px -4px rgba(234,88,12,0.3)" }}
                  >
                    {gauntletStarted ? "Continue Gauntlet" : "Enter the Gauntlet"}
                  </Link>
                )}
              </div>
            </div>

            {/* Product preview — bleeds off the right edge, slightly tilted */}
            <div className="relative lg:-mr-40 xl:-mr-64">
              <div
                className="overflow-hidden rounded-xl border border-border shadow-card"
                style={{ transform: "rotate(-1.4deg)" }}
              >
                <EditorMockup />
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── Tracks ── gradient card showcase ── */}
      <section className="relative overflow-hidden border-b border-border">
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0"
          style={{ background: "radial-gradient(ellipse 800px 500px at 12% 0%, rgba(74,144,196,0.05), transparent), radial-gradient(ellipse 900px 500px at 90% 100%, rgba(234,88,12,0.08), transparent)" }}
        />
        <div className="relative mx-auto max-w-6xl px-6 py-20 lg:px-8 lg:py-28">
          <div className="grid gap-8 lg:grid-cols-12 lg:gap-10">

            {/* Academy */}
            <div className="lg:col-span-5">
              <GradientCard accent="steel">
                <div className="flex h-full flex-col p-7">
                  <p className="font-mono text-[11px] font-bold uppercase tracking-[0.25em] text-steel-dim">Academy</p>
                  <h2 className="mt-3 font-display text-3xl font-black tracking-tight" style={{ color: "#202e44" }}>Learn to Code</h2>
                  <p className="mt-3 text-sm" style={{ lineHeight: 1.7, color: "rgba(32,46,68,0.6)" }}>
                    A lesson before every challenge. Clear explanations, runnable examples, and a path
                    built for complete beginners.
                  </p>

                  <div className="mt-6 flex flex-col">
                    {ACADEMY_PREVIEW.slice(0, 5).map((c) => (
                      <div key={c.n} className="flex items-baseline gap-3 border-t py-2 first:border-0" style={{ borderColor: "rgba(32,46,68,0.1)" }}>
                        <span className="w-6 shrink-0 font-mono text-xs tabular-nums" style={{ color: "rgba(32,46,68,0.3)" }}>{c.n}</span>
                        <span className="font-display text-sm font-semibold" style={{ color: "#202e44" }}>{c.title}</span>
                      </div>
                    ))}
                    <div className="border-t pt-2" style={{ borderColor: "rgba(32,46,68,0.1)" }}>
                      <span className="font-mono text-xs" style={{ color: "rgba(32,46,68,0.45)" }}>
                        + {academyChallenges.length - 5} more challenges
                      </span>
                    </div>
                  </div>

                  <div className="mt-auto pt-6">
                    <div className="flex items-center justify-between font-mono text-xs" style={{ color: "rgba(32,46,68,0.45)" }}>
                      <span>{academySolved} / {academyChallenges.length} solved</span>
                    </div>
                    <div className="mt-1.5 h-1 overflow-hidden rounded-full" style={{ background: "rgba(32,46,68,0.1)" }}>
                      <div
                        className="h-full rounded-full bg-steel transition-[width] duration-700"
                        style={{ width: `${Math.max(Math.round((academySolved / academyChallenges.length) * 100), 2)}%` }}
                      />
                    </div>
                    <div className="mt-5 flex items-center gap-4">
                      {academyNext && (
                        <Link to={hrefFor(academyNext)} className="font-display text-sm font-semibold text-steel hover:text-steel-dim">
                          {academyStarted ? "Continue" : "Start"} →
                        </Link>
                      )}
                      <Link to="/academy" className="font-mono text-xs" style={{ color: "rgba(32,46,68,0.45)" }}>
                        View all {academyChallenges.length}
                      </Link>
                    </div>
                  </div>
                </div>
              </GradientCard>
            </div>

            {/* Gauntlet — wider, pushed down to stagger */}
            <div className="lg:col-span-6 lg:col-start-7 lg:mt-20">
              <GradientCard accent="ember">
                <div className="flex h-full flex-col p-8">
                  <div className="flex items-start justify-between gap-4">
                    <div>
                      <p className="font-mono text-[11px] font-bold uppercase tracking-[0.25em] text-ember-bright">The Gauntlet</p>
                      <h2 className="mt-3 font-display text-4xl font-black tracking-tight" style={{ color: "#202e44" }}>The Story Campaign</h2>
                    </div>
                    <span
                      aria-hidden
                      className="select-none font-display font-black leading-none text-ember/15"
                      style={{ fontSize: "clamp(3rem, 6vw, 5rem)" }}
                    >
                      V
                    </span>
                  </div>
                  <p className="mt-3 max-w-md text-sm" style={{ lineHeight: 1.7, color: "rgba(32,46,68,0.6)" }}>
                    Five acts, ramping from hard to brutal. Per-player puzzle inputs, so no two
                    runs are the same.
                  </p>

                  <div className="mt-6 grid gap-x-6 sm:grid-cols-2">
                    {GAUNTLET_ACTS.map((title, i) => (
                      <div key={i} className="flex items-baseline gap-3 border-t py-2" style={{ borderColor: "rgba(32,46,68,0.1)" }}>
                        <span className="w-7 shrink-0 font-display text-lg font-black leading-none text-ember/45">
                          {["I", "II", "III", "IV", "V"][i]}
                        </span>
                        <span className="font-display text-sm font-semibold" style={{ color: "#202e44" }}>{title}</span>
                      </div>
                    ))}
                  </div>

                  <div className="mt-auto pt-6">
                    <div className="flex items-center justify-between font-mono text-xs" style={{ color: "rgba(32,46,68,0.45)" }}>
                      <span>{gauntletSolved} / {gauntletChallenges.length} solved</span>
                    </div>
                    <div className="mt-1.5 h-1 overflow-hidden rounded-full" style={{ background: "rgba(32,46,68,0.1)" }}>
                      <div
                        className="h-full rounded-full bg-ember transition-[width] duration-700"
                        style={{ width: `${Math.max(Math.round((gauntletSolved / gauntletChallenges.length) * 100), 2)}%` }}
                      />
                    </div>
                    <div className="mt-5 flex items-center gap-4">
                      {gauntletNext && (
                        <Link to={hrefFor(gauntletNext)} className="font-display text-sm font-semibold text-ember hover:text-ember-bright">
                          {gauntletStarted ? "Continue" : "Enter"} →
                        </Link>
                      )}
                      <Link to="/gauntlet" className="font-mono text-xs" style={{ color: "rgba(32,46,68,0.45)" }}>
                        View all {gauntletChallenges.length}
                      </Link>
                    </div>
                  </div>
                </div>
              </GradientCard>
            </div>
          </div>
        </div>
      </section>

      {/* ── Stats ── centered readout over a faint oversized watermark ── */}
      <section className="relative overflow-hidden" style={{ background: "rgba(32,46,68,0.04)" }}>
        <div className="absolute inset-x-0 top-0 h-px" style={{ background: "linear-gradient(90deg, transparent, rgba(234,88,12,0.2), transparent)" }} />
        {/* faint oversized wordmark for depth */}
        <div aria-hidden className="pointer-events-none absolute inset-0 flex items-center justify-center">
          <span
            className="select-none font-display font-black leading-none"
            style={{ fontSize: "clamp(7rem, 22vw, 19rem)", letterSpacing: "-0.05em", color: "rgba(32,46,68,0.04)" }}
          >
            FORGE
          </span>
        </div>
        <div className="relative mx-auto max-w-4xl px-6 py-20 text-center lg:py-24">
          <p className="font-mono text-[11px] font-bold uppercase tracking-[0.35em] text-ember">
            Your forge, so far
          </p>
          <div className="mt-10 flex items-stretch justify-center divide-x" style={{ borderColor: "rgba(32,46,68,0.12)" }}>
            <StatBig value={<CountUp value={done} />} label="solved" />
            <StatBig value={<CountUp value={days} />} suffix={days === 1 ? "day" : "days"} label="streak" />
            <StatBig value={<CountUp value={CHALLENGES.length} />} label="challenges" />
          </div>
        </div>
      </section>
    </div>
  );
}

function GradientCard({
  children,
  accent,
}: {
  children: React.ReactNode;
  accent: "steel" | "ember";
}) {
  const ref = useRef<HTMLDivElement>(null);
  const [pos, setPos] = useState({ x: 0, y: 0 });
  const [hovered, setHovered] = useState(false);

  const isSteel = accent === "steel";
  const rgb = isSteel ? "74,144,196" : "234,88,12";
  const borderColor = isSteel ? "rgba(74,144,196,0.5)" : "rgba(234,88,12,0.55)";
  const backGrad = isSteel
    ? "linear-gradient(135deg, rgba(74,144,196,0.22) 0%, rgba(74,144,196,0.06) 100%)"
    : "linear-gradient(135deg, rgba(234,88,12,0.22) 0%, rgba(234,88,12,0.06) 100%)";

  function handleMouseMove(e: React.MouseEvent<HTMLDivElement>) {
    if (!ref.current) return;
    const r = ref.current.getBoundingClientRect();
    setPos({ x: e.clientX - r.left, y: e.clientY - r.top });
  }

  return (
    <div className="relative h-full" style={{ isolation: "isolate" }}>
      {/* Skewed back-panel — the "gradient card showcase" signature element */}
      <div
        aria-hidden
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: "1.25rem",
          background: backGrad,
          transform: "skewX(-2deg) skewY(1.5deg) translate(8px, 10px)",
          filter: "blur(3px)",
          opacity: hovered ? 0.9 : 0.55,
          transition: "opacity 350ms ease, transform 350ms cubic-bezier(0.34,1.56,0.64,1)",
          zIndex: -1,
        }}
      />
      {/* Main card */}
      <div
        ref={ref}
        onMouseMove={handleMouseMove}
        onMouseEnter={() => setHovered(true)}
        onMouseLeave={() => setHovered(false)}
        className="relative h-full overflow-hidden rounded-2xl border backdrop-blur-sm"
        style={{
          background: "rgba(255,255,255,0.65)",
          borderColor: hovered ? borderColor : "rgba(32,46,68,0.1)",
          borderTopColor: borderColor,
          borderTopWidth: "2px",
          transform: hovered ? "translateY(-4px)" : "translateY(0)",
          transition: "transform 350ms cubic-bezier(0.34,1.56,0.64,1), border-color 250ms ease, box-shadow 250ms ease",
          boxShadow: hovered
            ? `0 20px 60px -12px rgba(${rgb},0.2), 0 4px 16px -4px rgba(0,0,0,0.08)`
            : "0 4px 24px -8px rgba(0,0,0,0.08)",
        }}
      >
        {/* Radial glow following the cursor */}
        <div
          aria-hidden
          style={{
            position: "absolute",
            width: 380,
            height: 380,
            borderRadius: "50%",
            background: `radial-gradient(circle, rgba(${rgb},0.14) 0%, transparent 68%)`,
            left: pos.x - 190,
            top: pos.y - 190,
            pointerEvents: "none",
            opacity: hovered ? 1 : 0,
            transition: "opacity 250ms ease",
          }}
        />
        {children}
      </div>
    </div>
  );
}

/** Decorative code editor mockup */
function EditorMockup() {
  return (
    <div className="flex h-[340px] overflow-hidden" style={{ background: "#11100E" }}>
      {/* Left panel: challenge description */}
      <div className="hidden w-[340px] shrink-0 flex-col border-r border-border p-6 lg:flex" style={{ background: "#14120F" }}>
        <p className="mb-1 font-mono text-[9px] font-bold uppercase tracking-[0.2em] text-steel">
          teaches: variables
        </p>
        <p className="mb-4 font-mono text-[10px] font-bold uppercase tracking-[0.12em] text-locked">
          Academy · Challenge 01
        </p>
        <p className="text-[13px] leading-relaxed text-text">
          The Forge's greeting system is offline. Write a function that takes a name as input and
          returns a greeting: <span className="font-mono text-ember text-[11px]">Hello, [name]!</span>
        </p>
        <div className="mt-5 border-t border-border pt-4">
          <p className="font-mono text-[9px] font-bold uppercase tracking-[0.15em] text-dim mb-2">Your input</p>
          <p className="font-mono text-[11px] text-steel-dim">Ada</p>
        </div>
        <div className="mt-5 border-t border-border pt-4">
          <div className="flex items-center justify-between">
            <p className="font-mono text-[9px] font-bold uppercase tracking-[0.15em] text-dim">Hints</p>
            <button className="font-mono text-[10px] text-ember">reveal 0/2</button>
          </div>
        </div>
      </div>

      {/* Right panel: code editor */}
      <div className="flex flex-1 flex-col">
        {/* Editor toolbar */}
        <div className="flex items-center justify-between border-b border-border px-4 py-2" style={{ background: "#161410" }}>
          <div className="flex gap-1.5">
            <div className="flex gap-1 rounded border border-border bg-bg/50 p-0.5">
              <span className="rounded px-2.5 py-0.5 font-mono text-[11px] font-semibold text-bg" style={{ background: "#EA580C" }}>Python</span>
              <span className="px-2.5 py-0.5 font-mono text-[11px] text-dim">JavaScript</span>
            </div>
          </div>
          <span className="font-mono text-[10px] text-dim">reset code</span>
        </div>

        {/* Code area — syntax highlighted */}
        <div className="flex flex-1 overflow-hidden font-mono text-[12px] leading-[1.7]" style={{ background: "#1B1410" }}>
          {/* Gutter */}
          <div className="select-none border-r border-border px-3 pt-3 text-right text-[11px]" style={{ color: "#5A4E44", minWidth: "2.8rem", background: "#161009" }}>
            {[1, 2, 3, 4, 5, 6, 7, 8].map((n) => <div key={n}>{n}</div>)}
          </div>
          {/* Code */}
          <div className="flex-1 p-3 pl-4">
            <div>
              <span style={{ color: "#C792EA" }}>def </span>
              <span style={{ color: "#82AAFF" }}>solve</span>
              <span style={{ color: "#89DDFF" }}>(</span>
              <span style={{ color: "#FFCB6B" }}>text</span>
              <span style={{ color: "#89DDFF" }}>):</span>
            </div>
            <div>
              <span className="pl-5" style={{ color: "#546E7A" }}># text is the puzzle input</span>
            </div>
            <div>
              <span className="pl-5" style={{ color: "#546E7A" }}># return your answer as a string</span>
            </div>
            <div className="pl-5">
              <span style={{ color: "#C792EA" }}>name </span>
              <span style={{ color: "#89DDFF" }}>= </span>
              <span style={{ color: "#FFCB6B" }}>text</span>
              <span style={{ color: "#89DDFF" }}>.</span>
              <span style={{ color: "#82AAFF" }}>strip</span>
              <span style={{ color: "#89DDFF" }}>()</span>
            </div>
            <div>
              <span className="pl-5" style={{ color: "#C792EA" }}>return </span>
              <span style={{ color: "#C3E88D" }}>f"Hello, </span>
              <span style={{ color: "#89DDFF" }}>{"{"}name{"}"}</span>
              <span style={{ color: "#C3E88D" }}>!"</span>
            </div>
            <div className="mt-1" />
          </div>
        </div>

        {/* Run bar + output */}
        <div className="border-t border-border" style={{ background: "#14120F" }}>
          <div className="flex items-center gap-3 px-4 py-2.5">
            <button className="rounded-md px-5 py-1.5 font-display text-[13px] font-semibold text-bg" style={{ background: "#EA580C" }}>
              Run
            </button>
          </div>
          <div className="border-t border-border px-4 py-3" style={{ background: "#161410" }}>
            <div className="flex items-center gap-2">
              <span className="font-display text-[13px] font-semibold" style={{ color: "#22C55E" }}>Correct!</span>
            </div>
            <div className="mt-1.5 grid gap-0.5 font-mono text-[11px]">
              <div className="flex gap-2">
                <span className="w-24 shrink-0" style={{ color: "#8C7A6A" }}>your answer</span>
                <span style={{ color: "#22C55E" }}>Hello, Ada!</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function StatBig({
  value,
  suffix,
  label,
}: {
  value: React.ReactNode;
  suffix?: string;
  label: string;
}) {
  return (
    <div className="flex flex-col items-center px-6 sm:px-12">
      <p className="font-display font-black leading-none" style={{ fontSize: "clamp(2.5rem, 6vw, 4.75rem)", color: "#202e44" }}>
        {value}
        {suffix && <span className="ml-1 font-bold" style={{ fontSize: "0.38em", color: "rgba(32,46,68,0.45)" }}>{suffix}</span>}
      </p>
      <div className="mt-4 h-px w-7 rounded-full bg-ember/50" />
      <p className="mt-2.5 font-mono text-[10px] font-bold uppercase tracking-[0.22em]" style={{ color: "rgba(32,46,68,0.45)" }}>{label}</p>
    </div>
  );
}
