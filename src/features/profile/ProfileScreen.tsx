import { useEffect, useRef } from "react";
import { Link } from "react-router-dom";
import {
  Code2,
  BookOpen,
  Trophy,
  Zap,
  Shuffle,
  Map,
  GraduationCap,
  Swords,
  Calendar,
  CheckCircle,
  Sparkles,
  Star,
  ArrowRight,
  TrendingUp,
  Flame,
} from "lucide-react";
import {
  motion,
  useScroll,
  useTransform,
  useInView,
  useSpring,
} from "framer-motion";
import { useProgress } from "../../engine/progress/store";
import { CHALLENGES } from "../../content/challenges";
import { activeStreak, todayISO } from "../../engine/progress/streak";
import { EmberCoin } from "../../components/EmberCoin";
import { computeEmbers } from "../../components/StreakBadge";

const TOTAL = CHALLENGES.length;
const ACADEMY_CHALLENGES = CHALLENGES.filter((c) => c.track === "academy");
const GAUNTLET_CHALLENGES = CHALLENGES.filter((c) => c.track === "gauntlet");
const ACADEMY_COUNT = ACADEMY_CHALLENGES.length;
const GAUNTLET_COUNT = GAUNTLET_CHALLENGES.length;

const RANKS = [
  "",
  "Apprentice",
  "Journeyman",
  "Artisan",
  "Forger",
  "Smith",
  "Master Smith",
  "Grandmaster",
];

function computeLevel(solvedCount: number) {
  const level = Math.min(Math.floor(Math.sqrt(solvedCount)) + 1, 7);
  const levelStart = (level - 1) ** 2;
  const levelEnd = level < 7 ? level ** 2 : TOTAL;
  const progress =
    levelEnd === levelStart
      ? 1
      : Math.min((solvedCount - levelStart) / (levelEnd - levelStart), 1);
  const toNext = Math.max(0, levelEnd - solvedCount);
  const rank = RANKS[Math.min(level, RANKS.length - 1)];
  return { level, rank, progress, toNext, levelStart, levelEnd };
}

// ─── XP Bar ───────────────────────────────────────────────────────────────────

function XPBar({ progress }: { progress: number }) {
  return (
    <div
      style={{
        height: 5,
        background: "rgba(255,255,255,0.08)",
        borderRadius: 3,
        overflow: "hidden",
        position: "relative",
      }}
    >
      <motion.div
        initial={{ width: 0 }}
        animate={{ width: `${Math.round(progress * 100)}%` }}
        transition={{ duration: 1.4, ease: [0.25, 0.46, 0.45, 0.94], delay: 0.4 }}
        style={{
          height: "100%",
          background: "linear-gradient(90deg, #C2440C, #EA580C, #FB923C)",
          borderRadius: 3,
          boxShadow: "0 0 10px rgba(234,88,12,0.9), 0 0 3px rgba(251,146,60,0.7)",
          position: "relative",
        }}
      >
        {/* Shimmer sweep */}
        <motion.div
          animate={{ x: ["-100%", "200%"] }}
          transition={{ duration: 1.8, delay: 1.2, ease: "easeInOut" }}
          style={{
            position: "absolute",
            inset: 0,
            background: "linear-gradient(90deg, transparent, rgba(255,255,255,0.35), transparent)",
            width: "50%",
          }}
        />
      </motion.div>
    </div>
  );
}

// ─── Track Pills ──────────────────────────────────────────────────────────────

function TrackBar({
  label,
  solved,
  total,
  color,
}: {
  label: string;
  solved: number;
  total: number;
  color: string;
}) {
  const pct = total === 0 ? 0 : solved / total;
  return (
    <div style={{ flex: 1, minWidth: 0 }}>
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "baseline",
          marginBottom: 4,
        }}
      >
        <span
          style={{
            fontFamily: '"Chakra Petch", sans-serif',
            fontSize: 9,
            fontWeight: 600,
            color: "rgba(233,234,238,0.45)",
            letterSpacing: "0.15em",
            textTransform: "uppercase",
          }}
        >
          {label}
        </span>
        <span
          style={{
            fontFamily: '"JetBrains Mono", monospace',
            fontSize: 10,
            color: "rgba(233,234,238,0.4)",
          }}
        >
          {solved}/{total}
        </span>
      </div>
      <div
        style={{
          height: 3,
          background: "rgba(255,255,255,0.07)",
          borderRadius: 2,
          overflow: "hidden",
        }}
      >
        <motion.div
          initial={{ width: 0 }}
          animate={{ width: `${pct * 100}%` }}
          transition={{ duration: 1.2, ease: "easeOut", delay: 0.6 }}
          style={{
            height: "100%",
            background: color,
            borderRadius: 2,
            boxShadow: `0 0 6px ${color}80`,
          }}
        />
      </div>
    </div>
  );
}

// ─── Game HUD ─────────────────────────────────────────────────────────────────

function GameHUD() {
  const solved = useProgress((s) => s.solved);
  const handle = useProgress((s) => s.handle);
  const streak = useProgress((s) => s.streak);

  const solvedSet = new Set(solved);
  const solvedCount = solved.length;
  const embers = computeEmbers(solved);
  const { level, rank, progress, toNext } = computeLevel(solvedCount);
  const currentStreak = activeStreak(streak, todayISO());
  const academySolved = ACADEMY_CHALLENGES.filter((c) => solvedSet.has(c.id)).length;
  const gauntletSolved = GAUNTLET_CHALLENGES.filter((c) => solvedSet.has(c.id)).length;
  const nextChallenge = CHALLENGES.find((c) => !solvedSet.has(c.id));

  return (
    <div style={{ background: "#111318", borderBottom: "1px solid rgba(234,88,12,0.12)", position: "relative", overflow: "hidden" }}>

      {/* Giant ghost level number — the editorial anchor */}
      <div
        aria-hidden="true"
        style={{
          position: "absolute",
          right: -8,
          bottom: -24,
          fontFamily: '"Press Start 2P", monospace',
          fontSize: "clamp(120px, 20vw, 220px)",
          fontWeight: 400,
          color: "#EA580C",
          opacity: 0.055,
          lineHeight: 1,
          userSelect: "none",
          pointerEvents: "none",
          letterSpacing: "-0.02em",
        }}
      >
        {level}
      </div>

      {/* Ember atmosphere */}
      <div style={{ position: "absolute", top: 0, left: "30%", width: 400, height: "100%", background: "radial-gradient(ellipse at 50% 0%, rgba(234,88,12,0.07) 0%, transparent 70%)", pointerEvents: "none" }} />

      <div style={{ maxWidth: 1152, margin: "0 auto", padding: "36px 32px 32px", position: "relative" }}>

        {/* Top row: name left, stats right */}
        <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", marginBottom: 20 }}>

          {/* Left: name + rank */}
          <motion.div initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.45 }}>
            <div style={{ fontFamily: '"Pixelify Sans", sans-serif', fontSize: "clamp(22px, 3.5vw, 36px)", fontWeight: 700, color: "#E9EAEE", lineHeight: 1, letterSpacing: "0.01em", marginBottom: 6 }}>
              {handle || "Anonymous"}
            </div>
            <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
              <span style={{ fontFamily: '"JetBrains Mono", monospace', fontSize: 11, color: "#EA580C", letterSpacing: "0.12em", textTransform: "uppercase" }}>
                {rank}
              </span>
              <span style={{ width: 3, height: 3, borderRadius: "50%", background: "rgba(234,88,12,0.4)", display: "inline-block" }} />
              <span style={{ fontFamily: '"JetBrains Mono", monospace', fontSize: 11, color: "rgba(233,234,238,0.3)", letterSpacing: "0.06em" }}>
                lvl {level}
              </span>
            </div>
          </motion.div>

          {/* Right: stat pills */}
          <motion.div initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.45, delay: 0.1 }} style={{ display: "flex", gap: 10, alignItems: "center", flexWrap: "wrap", justifyContent: "flex-end" }}>
            <div style={{ display: "flex", alignItems: "center", gap: 6, background: "rgba(255,255,255,0.04)", border: "1px solid rgba(255,255,255,0.07)", borderRadius: 8, padding: "7px 12px" }}>
              <Flame style={{ width: 13, height: 13, color: currentStreak > 0 ? "#FB923C" : "rgba(233,234,238,0.2)" }} />
              <span style={{ fontFamily: '"Pixelify Sans", sans-serif', fontSize: 15, fontWeight: 700, color: currentStreak > 0 ? "#FB923C" : "rgba(233,234,238,0.2)" }}>{currentStreak}</span>
              <span style={{ fontFamily: '"JetBrains Mono", monospace', fontSize: 10, color: "rgba(233,234,238,0.25)" }}>streak</span>
            </div>
            <div style={{ display: "flex", alignItems: "center", gap: 6, background: "rgba(255,255,255,0.04)", border: "1px solid rgba(255,255,255,0.07)", borderRadius: 8, padding: "7px 12px" }}>
              <EmberCoin size={14} />
              <span style={{ fontFamily: '"Pixelify Sans", sans-serif', fontSize: 15, fontWeight: 700, color: embers > 0 ? "#FB923C" : "rgba(233,234,238,0.2)" }}>{embers}</span>
              <span style={{ fontFamily: '"JetBrains Mono", monospace', fontSize: 10, color: "rgba(233,234,238,0.25)" }}>embers</span>
            </div>
            <div style={{ display: "flex", alignItems: "center", gap: 6, background: "rgba(255,255,255,0.04)", border: "1px solid rgba(255,255,255,0.07)", borderRadius: 8, padding: "7px 12px" }}>
              <Star style={{ width: 13, height: 13, color: "#EA580C" }} />
              <span style={{ fontFamily: '"Pixelify Sans", sans-serif', fontSize: 15, fontWeight: 700, color: "#E9EAEE" }}>{solvedCount}</span>
              <span style={{ fontFamily: '"JetBrains Mono", monospace', fontSize: 10, color: "rgba(233,234,238,0.25)" }}>/ {TOTAL}</span>
            </div>
          </motion.div>
        </div>

        {/* XP bar — full width */}
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.4, delay: 0.2 }} style={{ marginBottom: 8 }}>
          <XPBar progress={progress} />
        </motion.div>
        <div style={{ fontFamily: '"JetBrains Mono", monospace', fontSize: 10, color: "rgba(233,234,238,0.25)", marginBottom: 24, letterSpacing: "0.04em" }}>
          {solvedCount} XP{toNext > 0 && <span style={{ color: "rgba(234,88,12,0.5)" }}> · {toNext} to {RANKS[Math.min(level + 1, RANKS.length - 1)]}</span>}
        </div>

        {/* Bottom row: track bars left, continue button right */}
        <div style={{ display: "flex", alignItems: "center", gap: 24, flexWrap: "wrap" }}>
          <div style={{ display: "flex", gap: 20, flex: 1, minWidth: 200 }}>
            <TrackBar label="Academy" solved={academySolved} total={ACADEMY_COUNT} color="#0891B2" />
            <TrackBar label="Gauntlet" solved={gauntletSolved} total={GAUNTLET_COUNT} color="#EA580C" />
          </div>

          <motion.div initial={{ opacity: 0, y: 6 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.45, delay: 0.25 }} style={{ display: "flex", gap: 10, flexShrink: 0 }}>
            <Link to="/daily" style={{ textDecoration: "none" }}>
              <motion.div whileHover={{ scale: 1.04 }} whileTap={{ scale: 0.97 }} style={{ display: "flex", alignItems: "center", gap: 6, background: "rgba(255,255,255,0.04)", border: "1px solid rgba(255,255,255,0.09)", borderRadius: 8, padding: "10px 16px", cursor: "pointer" }}>
                <Calendar style={{ width: 13, height: 13, color: "rgba(233,234,238,0.4)" }} />
                <span style={{ fontFamily: '"Pixelify Sans", sans-serif', fontSize: 13, color: "rgba(233,234,238,0.5)" }}>Daily</span>
              </motion.div>
            </Link>

            {nextChallenge ? (
              <Link to={`/challenge/${nextChallenge.id}`} style={{ textDecoration: "none" }}>
                <motion.div
                  whileHover={{ scale: 1.04, boxShadow: "0 6px 32px rgba(234,88,12,0.5), 0 0 0 1px rgba(251,146,60,0.25) inset" }}
                  whileTap={{ scale: 0.97 }}
                  style={{ display: "flex", alignItems: "center", gap: 10, background: "#EA580C", borderRadius: 8, padding: "10px 20px", cursor: "pointer", boxShadow: "0 4px 20px rgba(234,88,12,0.3)" }}
                >
                  <span style={{ fontFamily: '"Pixelify Sans", sans-serif', fontSize: 15, fontWeight: 700, color: "white", whiteSpace: "nowrap" }}>
                    {solvedCount === 0 ? "Start forging" : nextChallenge.title}
                  </span>
                  <ArrowRight style={{ width: 14, height: 14, color: "rgba(255,255,255,0.8)", flexShrink: 0 }} />
                </motion.div>
              </Link>
            ) : (
              <div style={{ display: "flex", alignItems: "center", gap: 8, background: "rgba(34,197,94,0.1)", border: "1px solid rgba(34,197,94,0.25)", borderRadius: 8, padding: "10px 20px" }}>
                <span style={{ fontFamily: '"Pixelify Sans", sans-serif', fontSize: 14, fontWeight: 700, color: "#22C55E" }}>All complete!</span>
              </div>
            )}
          </motion.div>
        </div>
      </div>

      {/* Bottom edge glow */}
      <div style={{ position: "absolute", bottom: 0, left: 0, right: 0, height: 1, background: "linear-gradient(90deg, transparent, rgba(234,88,12,0.35) 40%, rgba(234,88,12,0.35) 60%, transparent)" }} />
    </div>
  );
}

// ─── Features section ─────────────────────────────────────────────────────────

const services = [
  {
    icon: <GraduationCap className="w-6 h-6" />,
    secondaryIcon: <Sparkles className="w-4 h-4 absolute -top-1 -right-1 text-[#0891B2]" />,
    title: "Academy Track",
    description: `${ACADEMY_COUNT} beginner challenges, each preceded by a lesson. Read it, run the example, then solve. Built for brand-new coders and kids.`,
    position: "left" as const,
    href: "/academy",
  },
  {
    icon: <Swords className="w-6 h-6" />,
    secondaryIcon: <CheckCircle className="w-4 h-4 absolute -top-1 -right-1 text-[#EA580C]" />,
    title: "The Gauntlet",
    description: `${GAUNTLET_COUNT} story challenges across 5 acts. Starts hard, ends brutally hard. Every puzzle is wrapped in a continuous narrative.`,
    position: "left" as const,
    href: "/gauntlet",
  },
  {
    icon: <Shuffle className="w-6 h-6" />,
    secondaryIcon: <Star className="w-4 h-4 absolute -top-1 -right-1 text-[#EA580C]" />,
    title: "Per-Player Puzzles",
    description: "Hard challenges generate a unique input per player from a seeded RNG. No two answers are the same.",
    position: "left" as const,
    href: "/gauntlet",
  },
  {
    icon: <Code2 className="w-6 h-6" />,
    secondaryIcon: <Sparkles className="w-4 h-4 absolute -top-1 -right-1 text-[#0891B2]" />,
    title: "JS & Python",
    description: "Pick your language. Your solve() runs client-side in a Web Worker: JavaScript natively, Python via Pyodide. No backend, no data sent.",
    position: "right" as const,
    href: "/academy",
  },
  {
    icon: <BookOpen className="w-6 h-6" />,
    secondaryIcon: <CheckCircle className="w-4 h-4 absolute -top-1 -right-1 text-[#0891B2]" />,
    title: "Technique Lessons",
    description: "Optional deep-dives on BFS, Dijkstra, cycle detection, CRT and more. Anchored to the challenge they unlock.",
    position: "right" as const,
    href: "/gauntlet",
  },
  {
    icon: <Map className="w-6 h-6" />,
    secondaryIcon: <Star className="w-4 h-4 absolute -top-1 -right-1 text-[#EA580C]" />,
    title: "Story Campaign",
    description: "Relight the Core, descend into the Waking Deep, unlock Founder secrets. Every Gauntlet puzzle carries a narrative beat.",
    position: "right" as const,
    href: "/gauntlet",
  },
];

const stats = [
  { icon: <Trophy />, value: TOTAL,  label: "Challenges", suffix: "" },
  { icon: <BookOpen />, value: 28,   label: "Lessons",    suffix: "" },
  { icon: <Calendar />, value: 5,    label: "Acts",       suffix: "" },
  { icon: <TrendingUp />, value: 2,  label: "Languages",  suffix: "×" },
];

interface ServiceItemProps {
  icon: React.ReactNode;
  secondaryIcon?: React.ReactNode;
  title: string;
  description: string;
  variants: import("framer-motion").Variants;
  delay: number;
  direction: "left" | "right";
  href: string;
}

function ServiceItem({ icon, secondaryIcon, title, description, variants, delay, direction, href }: ServiceItemProps) {
  return (
    <Link to={href} style={{ textDecoration: "none" }}>
      <motion.div
        className="flex flex-col group cursor-pointer"
        variants={variants}
        transition={{ delay }}
        whileHover={{ y: -5, transition: { duration: 0.2 } }}
      >
        <motion.div
          className="flex items-center gap-3 mb-3"
          initial={{ x: direction === "left" ? -20 : 20, opacity: 0 }}
          animate={{ x: 0, opacity: 1 }}
          transition={{ duration: 0.6, delay: delay + 0.2 }}
        >
          <motion.div
            className="relative p-3 rounded-lg transition-colors duration-300"
            style={{ color: "#EA580C", background: "rgba(234,88,12,0.08)" }}
            whileHover={{ rotate: [0, -10, 10, -5, 0], transition: { duration: 0.5 } }}
          >
            {icon}
            {secondaryIcon}
          </motion.div>
          <h3
            className="text-xl font-medium transition-colors duration-300 group-hover:text-[#EA580C]"
            style={{ color: "#202e44" }}
          >
            {title}
          </h3>
        </motion.div>
        <motion.p
          className="text-sm leading-relaxed pl-12"
          style={{ color: "rgba(32,46,68,0.75)" }}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.6, delay: delay + 0.4 }}
        >
          {description}
        </motion.p>
        <div className="mt-3 pl-12 flex items-center text-xs font-medium opacity-0 group-hover:opacity-100" style={{ color: "#EA580C", transition: "opacity 200ms ease" }}>
          <span className="flex items-center gap-1">
            Go there <ArrowRight className="w-3 h-3" />
          </span>
        </div>
      </motion.div>
    </Link>
  );
}

interface StatCounterProps {
  icon: React.ReactNode;
  value: number;
  label: string;
  suffix: string;
  delay: number;
}

function StatCounter({ icon, value, label, suffix, delay }: StatCounterProps) {
  const countRef = useRef(null);
  const isInView = useInView(countRef, { once: true });
  const springValue = useSpring(0, { stiffness: 60, damping: 25 });

  useEffect(() => {
    if (isInView) springValue.set(value);
  }, [isInView, value, springValue]);

  const displayValue = useTransform(springValue, (latest) => Math.floor(latest));

  return (
    <motion.div
      className="p-6 rounded-xl flex flex-col items-center text-center group transition-colors duration-300"
      style={{ background: "rgba(255,255,255,0.5)", backdropFilter: "blur(4px)" }}
      variants={{
        hidden: { opacity: 0, y: 20 },
        visible: { opacity: 1, y: 0, transition: { duration: 0.6, delay } },
      }}
      whileHover={{ y: -5, transition: { duration: 0.2 } }}
    >
      <motion.div
        className="w-14 h-14 rounded-full flex items-center justify-center mb-4 transition-colors duration-300 group-hover:bg-[#EA580C]/10"
        style={{ background: "rgba(32,46,68,0.05)", color: "#EA580C" }}
        whileHover={{ rotate: 360, transition: { duration: 0.8 } }}
      >
        {icon}
      </motion.div>
      <div ref={countRef} className="text-3xl font-bold flex items-center" style={{ color: "#202e44" }}>
        <motion.span>{displayValue}</motion.span>
        <span>{suffix}</span>
      </div>
      <p className="text-sm mt-1" style={{ color: "rgba(32,46,68,0.65)" }}>{label}</p>
      <motion.div
        className="h-0.5 mt-3 transition-all duration-300 group-hover:w-16"
        style={{ width: 40, background: "#EA580C" }}
      />
    </motion.div>
  );
}

function ForgeTerminal() {
  const lines = [
    { t: "comment", s: "// forge-code · gauntlet" },
    { t: "blank" },
    { t: "fn",      s: "function solve(text) {" },
    { t: "code",    s: "  const lines = text.split('\\n')" },
    { t: "code",    s: "  let total = 0" },
    { t: "code",    s: "  for (const line of lines) {" },
    { t: "code",    s: "    total += Number(line)" },
    { t: "code",    s: "  }" },
    { t: "return",  s: "  return String(total)" },
    { t: "fn",      s: "}" },
    { t: "blank" },
    { t: "result",  s: "✓  Correct  →  42" },
  ];

  const colors: Record<string, string> = {
    comment: "#38BDF8",
    fn:      "#FB923C",
    code:    "#CBD5E1",
    return:  "#86EFAC",
    result:  "#4ADE80",
    blank:   "transparent",
  };

  return (
    <div style={{
      background: "#1A1D23",
      borderRadius: 10,
      overflow: "hidden",
      boxShadow: "0 24px 64px rgba(0,0,0,0.28), 0 4px 16px rgba(0,0,0,0.2)",
    }}>
      <div style={{
        background: "#252830",
        padding: "10px 14px",
        display: "flex",
        alignItems: "center",
        gap: 6,
        borderBottom: "1px solid rgba(74,80,92,0.3)",
      }}>
        <div style={{ width: 8, height: 8, borderRadius: "50%", background: "#EA580C" }} />
        <div style={{ width: 8, height: 8, borderRadius: "50%", background: "#FB923C" }} />
        <div style={{ width: 8, height: 8, borderRadius: "50%", background: "#22C55E" }} />
        <span style={{
          marginLeft: 8,
          fontFamily: '"JetBrains Mono", monospace',
          fontSize: 10,
          color: "rgba(152,160,173,0.5)",
          letterSpacing: "0.04em",
        }}>
          solve.js
        </span>
      </div>
      <div style={{ padding: "16px 18px", display: "flex", flexDirection: "column", gap: 3 }}>
        {lines.map((line, i) => (
          <div key={i} style={{
            fontFamily: '"JetBrains Mono", monospace',
            fontSize: 11,
            lineHeight: 1.6,
            color: colors[line.t] ?? "#CBD5E1",
            whiteSpace: "pre",
            background: line.t === "result" ? "rgba(34,197,94,0.08)" : "transparent",
            borderRadius: line.t === "result" ? 4 : 0,
            padding: line.t === "result" ? "2px 6px" : "0",
            marginTop: line.t === "result" ? 6 : 0,
          }}>
            {line.s ?? ""}
          </div>
        ))}
      </div>
    </div>
  );
}

// ─── Screen ───────────────────────────────────────────────────────────────────

export function ProfileScreen() {
  const sectionRef = useRef<HTMLDivElement>(null);
  const statsRef = useRef<HTMLDivElement>(null);
  const isInView = useInView(sectionRef, { once: false, amount: 0.1 });
  const isStatsInView = useInView(statsRef, { once: false, amount: 0.3 });

  const { scrollYProgress } = useScroll({
    target: sectionRef,
    offset: ["start end", "end start"],
  });

  const y1 = useTransform(scrollYProgress, [0, 1], [0, -50]);
  const y2 = useTransform(scrollYProgress, [0, 1], [0, 50]);
  const rotate1 = useTransform(scrollYProgress, [0, 1], [0, 20]);
  const rotate2 = useTransform(scrollYProgress, [0, 1], [0, -20]);

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: { opacity: 1, transition: { staggerChildren: 0.2, delayChildren: 0.3 } },
  };

  const itemVariants = {
    hidden: { y: 20, opacity: 0 },
    visible: { y: 0, opacity: 1, transition: { duration: 0.6, ease: "easeOut" } },
  };

  return (
    <div className="w-full">
      {/* ── Game HUD ── */}
      <GameHUD />

      {/* ── About / Features ── */}
      <section
        ref={sectionRef}
        className="w-full py-24 px-4 overflow-hidden relative"
        style={{ background: "linear-gradient(to bottom, #F2F2EB, #F8F8F2)", color: "#202e44" }}
      >
        <motion.div
          className="absolute top-20 left-10 w-64 h-64 rounded-full blur-3xl"
          style={{ background: "rgba(234,88,12,0.06)", y: y1, rotate: rotate1 }}
        />
        <motion.div
          className="absolute bottom-20 right-10 w-80 h-80 rounded-full blur-3xl"
          style={{ background: "rgba(8,145,178,0.06)", y: y2, rotate: rotate2 }}
        />
        <motion.div
          className="absolute top-1/2 left-1/4 w-4 h-4 rounded-full"
          style={{ background: "rgba(234,88,12,0.25)" }}
          animate={{ y: [0, -15, 0], opacity: [0.5, 1, 0.5] }}
          transition={{ duration: 3, repeat: Infinity, ease: "easeInOut" }}
        />

        <motion.div
          className="container mx-auto max-w-6xl relative z-10"
          initial="hidden"
          animate={isInView ? "visible" : "hidden"}
          variants={containerVariants}
        >
          <motion.div className="flex flex-col items-center mb-6" variants={itemVariants}>
            <motion.span
              className="font-medium mb-2 flex items-center gap-2"
              style={{ color: "#EA580C" }}
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.2 }}
            >
              <Zap className="w-4 h-4" />
              DISCOVER FORGE CODE
            </motion.span>
            <h2 className="text-4xl md:text-5xl font-light mb-4 text-center" style={{ color: "#202e44" }}>
              About
            </h2>
            <motion.div
              className="h-1 rounded-full"
              style={{ background: "#EA580C", width: 0 }}
              animate={{ width: 96 }}
              transition={{ duration: 1, delay: 0.5 }}
            />
          </motion.div>

          <motion.p
            className="text-center max-w-2xl mx-auto mb-16"
            style={{ color: "rgba(32,46,68,0.75)" }}
            variants={itemVariants}
          >
            A coding challenge game that runs entirely in your browser. Two tracks, one for
            beginners and one for experts, both built around writing a single{" "}
            <code style={{ fontFamily: '"JetBrains Mono", monospace', fontSize: 13, color: "#EA580C" }}>
              solve(text)
            </code>{" "}
            function that answers a puzzle.
          </motion.p>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 relative">
            <div className="space-y-16">
              {services.filter((s) => s.position === "left").map((s, i) => (
                <ServiceItem
                  key={`left-${i}`}
                  icon={s.icon}
                  secondaryIcon={s.secondaryIcon}
                  title={s.title}
                  description={s.description}
                  variants={itemVariants}
                  delay={i * 0.2}
                  direction="left"
                  href={s.href}
                />
              ))}
            </div>

            <div className="flex justify-center items-center order-first md:order-none mb-8 md:mb-0">
              <motion.div className="relative w-full max-w-xs" variants={itemVariants}>
                <motion.div
                  initial={{ scale: 0.9, opacity: 0 }}
                  animate={{ scale: 1, opacity: 1 }}
                  transition={{ duration: 0.8, delay: 0.3 }}
                  whileHover={{ scale: 1.03, transition: { duration: 0.3 } }}
                >
                  <ForgeTerminal />
                  <motion.div
                    className="absolute inset-0 flex items-end justify-center p-4 rounded-xl"
                    style={{ background: "linear-gradient(to top, rgba(26,29,35,0.7) 0%, transparent 50%)" }}
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    transition={{ duration: 0.8, delay: 0.9 }}
                  >
                    <Link
                      to="/gauntlet"
                      className="flex items-center gap-2 text-sm font-medium px-4 py-2 rounded-full"
                      style={{ background: "white", color: "#202e44" }}
                    >
                      Enter the Gauntlet <ArrowRight className="w-4 h-4" />
                    </Link>
                  </motion.div>
                </motion.div>
                <motion.div
                  className="absolute inset-0 rounded-xl -m-3 -z-10"
                  style={{ border: "4px solid rgba(8,145,178,0.35)" }}
                  initial={{ opacity: 0, scale: 1.1 }}
                  animate={{ opacity: 1, scale: 1 }}
                  transition={{ duration: 0.8, delay: 0.6 }}
                />
              </motion.div>
            </div>

            <div className="space-y-16">
              {services.filter((s) => s.position === "right").map((s, i) => (
                <ServiceItem
                  key={`right-${i}`}
                  icon={s.icon}
                  secondaryIcon={s.secondaryIcon}
                  title={s.title}
                  description={s.description}
                  variants={itemVariants}
                  delay={i * 0.2}
                  direction="right"
                  href={s.href}
                />
              ))}
            </div>
          </div>

          <motion.div
            ref={statsRef}
            className="mt-24 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-8"
            initial="hidden"
            animate={isStatsInView ? "visible" : "hidden"}
            variants={containerVariants}
          >
            {stats.map((stat, i) => (
              <StatCounter
                key={i}
                icon={stat.icon}
                value={stat.value}
                label={stat.label}
                suffix={stat.suffix}
                delay={i * 0.1}
              />
            ))}
          </motion.div>

          <motion.div
            className="mt-20 p-8 rounded-xl flex flex-col md:flex-row items-center justify-between gap-6"
            style={{ background: "#202e44", color: "white" }}
            initial={{ opacity: 0, y: 30 }}
            animate={isStatsInView ? { opacity: 1, y: 0 } : { opacity: 0, y: 30 }}
            transition={{ duration: 0.8, delay: 0.5 }}
          >
            <div className="flex-1">
              <h3 className="text-2xl font-medium mb-2">Ready to start forging?</h3>
              <p style={{ color: "rgba(255,255,255,0.75)" }}>
                Pick a track and write your first{" "}
                <code style={{ fontFamily: '"JetBrains Mono", monospace' }}>solve()</code>.
              </p>
            </div>
            <div className="flex gap-3 flex-wrap">
              <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
                <Link
                  to="/academy"
                  className="px-6 py-3 rounded-lg flex items-center gap-2 font-medium transition-colors"
                  style={{ background: "#0891B2", color: "white" }}
                >
                  Academy <ArrowRight className="w-4 h-4" />
                </Link>
              </motion.div>
              <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
                <Link
                  to="/gauntlet"
                  className="px-6 py-3 rounded-lg flex items-center gap-2 font-medium transition-colors"
                  style={{ background: "#EA580C", color: "white" }}
                >
                  Gauntlet <ArrowRight className="w-4 h-4" />
                </Link>
              </motion.div>
            </div>
          </motion.div>
        </motion.div>
      </section>
    </div>
  );
}
