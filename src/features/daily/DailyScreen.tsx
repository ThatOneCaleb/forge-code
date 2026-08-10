import { useEffect, useMemo, useRef, useState } from "react";
import { LANGUAGES, LANGUAGE_LABELS, type GradeResult, type RunResult } from "../../engine/types";
import { preloadRuntime, runCode } from "../../engine/runner";
import { gradeRun } from "../../engine/runner/grade";
import { useProgress } from "../../engine/progress/store";
import { getTodayChallenge, dailyInstance, todayDateString } from "../../engine/daily";
import { submitDailyScore, fetchDailyLeaderboard } from "../../lib/leaderboard-api";
import { Editor } from "../../components/Editor";
import { OutputPanel } from "../../components/OutputPanel";
import { Celebration } from "../../components/Celebration";

function fmt(secs: number) {
  const m = Math.floor(secs / 60), s = secs % 60;
  return `${m}:${String(s).padStart(2, "0")}`;
}

export function DailyScreen() {
  const language = useProgress((s) => s.language);
  const setLanguage = useProgress((s) => s.setLanguage);
  const playerSeed = useProgress((s) => s.playerSeed);
  const handle = useProgress((s) => s.handle);

  const challenge = getTodayChallenge();
  const dateStr = todayDateString();
  const puzzle = useMemo(() => dailyInstance(challenge, dateStr, playerSeed), [challenge, dateStr, playerSeed]);

  const starterCode = language === "python" ? "def solve(text):\n    " : "function solve(text) {\n  \n}";
  const [code, setCode] = useState(starterCode);
  const [running, setRunning] = useState(false);
  const [result, setResult] = useState<RunResult | null>(null);
  const [grade, setGrade] = useState<GradeResult | null>(null);
  const [solved, setSolved] = useState(false);
  const [finalTime, setFinalTime] = useState<number | null>(null);
  const [elapsedSecs, setElapsedSecs] = useState(0);
  const [timerStarted, setTimerStarted] = useState(false);
  const startedAt = useRef<number | null>(null);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const [board, setBoard] = useState<{ handle: string; time_seconds: number }[]>([]);
  const [boardLoading, setBoardLoading] = useState(true);

  useEffect(() => { preloadRuntime(language); }, [language]);
  useEffect(() => { setCode(starterCode); setResult(null); setGrade(null); }, [language]);
  useEffect(() => {
    fetchDailyLeaderboard(dateStr).then((rows) => { setBoard(rows); setBoardLoading(false); });
  }, [dateStr, solved]);

  function handleFirstKeystroke() {
    if (timerStarted || solved) return;
    setTimerStarted(true);
    startedAt.current = Date.now();
    intervalRef.current = setInterval(() => {
      setElapsedSecs(Math.floor((Date.now() - startedAt.current!) / 1000));
    }, 1000);
  }

  function handleChange(val: string) {
    handleFirstKeystroke();
    setCode(val);
  }

  async function handleRun() {
    if (!timerStarted) handleFirstKeystroke();
    setRunning(true);
    const res = await runCode(language, code, puzzle.input);
    const gr = gradeRun(res, puzzle.expected);
    setResult(res);
    setGrade(gr);
    setRunning(false);

    if (gr.correct && !solved) {
      setSolved(true);
      if (intervalRef.current) clearInterval(intervalRef.current);
      const t = Math.floor((Date.now() - (startedAt.current ?? Date.now())) / 1000);
      setFinalTime(t);
      if (handle) {
        await submitDailyScore({ date: dateStr, handle, player_seed: playerSeed, time_seconds: t });
        const rows = await fetchDailyLeaderboard(dateStr);
        setBoard(rows);
      }
    }
  }

  const yourBoardEntry = board.find((r) => r.handle === handle);
  const yourRank = yourBoardEntry ? board.indexOf(yourBoardEntry) + 1 : null;

  return (
    <div style={{ background: "#1A1D22", minHeight: "100%" }}>
      {solved && <Celebration />}
      <div className="mx-auto flex max-w-6xl flex-col gap-6 px-6 py-8 lg:px-8">

        {/* Header */}
        <div className="flex flex-wrap items-start justify-between gap-4">
          <div>
            <p className="font-mono text-[10px] font-bold uppercase tracking-[0.28em] text-ember">
              Daily Challenge · {dateStr}
            </p>
            <h1 className="mt-1 font-display text-2xl font-black tracking-tight text-text">
              {challenge.title}
            </h1>
            <p className="mt-0.5 font-mono text-xs text-dim">{challenge.concept}</p>
          </div>

          <div className="flex items-center gap-4">
            {/* Timer */}
            <div
              className="rounded-lg border px-4 py-2 text-center"
              style={{
                borderColor: solved ? "rgba(74,144,196,0.4)" : "rgba(234,88,12,0.3)",
                background: solved ? "rgba(74,144,196,0.08)" : "rgba(234,88,12,0.06)",
              }}
            >
              <p className="font-mono text-[10px] uppercase tracking-wider text-dim">time</p>
              <p className="font-display text-xl font-black" style={{ color: solved ? "#4A90C4" : "#EA580C" }}>
                {fmt(finalTime ?? elapsedSecs)}
              </p>
            </div>

          </div>
        </div>

        {solved && (
          <div
            className="rounded-xl border p-4 text-center"
            style={{ borderColor: "rgba(74,144,196,0.35)", background: "rgba(74,144,196,0.08)" }}
          >
            <p className="font-display text-lg font-black text-steel">
              Solved in {fmt(finalTime ?? 0)}
              {yourRank && ` · Rank #${yourRank} today`}
            </p>
            {!handle && <p className="mt-1 font-mono text-xs text-dim">Set a handle in the nav to appear on the leaderboard.</p>}
          </div>
        )}

        <div className="grid gap-6 lg:grid-cols-2">
          {/* Prompt */}
          <div className="rounded-xl border border-border bg-panel p-5">
            <p className="font-mono text-[10px] font-bold uppercase tracking-widest text-ember mb-3">Puzzle</p>
            <pre className="whitespace-pre-wrap font-mono text-xs text-dim leading-relaxed">{challenge.prompt}</pre>
            <div className="mt-4 border-t border-border pt-4">
              <p className="font-mono text-[10px] uppercase tracking-widest text-dim mb-2">Your input (unique to you)</p>
              <pre className="max-h-32 overflow-auto rounded border border-border bg-panel-2 p-2 font-mono text-xs text-steel-dim">
                {puzzle.input}
              </pre>
            </div>
          </div>

          {/* Editor */}
          <div className="flex flex-col gap-3">
            {/* Language toggle */}
            <div className="flex gap-1 rounded-lg border border-border bg-panel p-1 w-fit">
              {LANGUAGES.map((lang) => (
                <button
                  key={lang}
                  onClick={() => setLanguage(lang)}
                  className="rounded-md px-3 py-1.5 font-mono text-xs font-semibold transition-colors"
                  style={language === lang
                    ? { background: "rgba(234,88,12,0.2)", color: "#FB923C", boxShadow: "0 0 0 1px rgba(234,88,12,0.3)" }
                    : { color: "#6B7280" }}
                >
                  {LANGUAGE_LABELS[lang]}
                </button>
              ))}
            </div>

            <Editor
              value={code}
              language={language}
              onChange={handleChange}
              accent="ember"
              noPaste
            />

            <button
              onClick={handleRun}
              disabled={running || solved}
              className="rounded-lg px-6 py-2.5 font-display text-sm font-bold tracking-wide transition-opacity hover:opacity-90 active:opacity-75 disabled:opacity-40"
              style={{ background: "linear-gradient(135deg, #EA580C, #C2440C)", color: "#fff", boxShadow: "0 4px 16px -4px rgba(234,88,12,0.5)" }}
            >
              {running ? "Running…" : solved ? "Solved!" : "Run"}
            </button>

            <OutputPanel running={running} result={result} grade={grade} />
          </div>
        </div>

        {/* Daily leaderboard */}
        <div className="rounded-xl border border-border bg-panel p-5">
          <p className="font-mono text-[10px] font-bold uppercase tracking-widest text-ember mb-4">
            Today's Fastest
          </p>
          {boardLoading ? (
            <p className="font-mono text-xs text-dim">Loading…</p>
          ) : board.length === 0 ? (
            <p className="font-mono text-xs text-dim">No completions yet — be the first.</p>
          ) : (
            <div className="flex flex-col gap-1.5">
              {board.slice(0, 10).map((row, i) => (
                <div
                  key={row.handle}
                  className="flex items-center gap-3 rounded-lg px-4 py-2"
                  style={{
                    background: row.handle === handle ? "rgba(74,144,196,0.1)" : "rgba(255,255,255,0.03)",
                    borderLeft: row.handle === handle ? "2px solid #4A90C4" : "2px solid transparent",
                  }}
                >
                  <span className="w-6 font-display text-sm font-black" style={{ color: i === 0 ? "#D97706" : i === 1 ? "#9CA3AF" : i === 2 ? "#92400E" : "rgba(152,160,173,0.4)" }}>
                    {i + 1}
                  </span>
                  <span className="flex-1 font-display text-sm font-semibold text-text">{row.handle}</span>
                  <span className="font-mono text-sm font-bold" style={{ color: i === 0 ? "#EA580C" : "#98A0AD" }}>
                    {fmt(row.time_seconds)}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
