import { useEffect, useMemo, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { getChallenge } from "../../content/challenges";
import { pathForChallenge, indexInPath, optionalLessonFor } from "../../content/path";
import { LANGUAGES, LANGUAGE_LABELS, type GradeResult, type PathItem, type PuzzleInstance, type RunResult } from "../../engine/types";
import { preloadRuntime, runCode } from "../../engine/runner";
import { gradeRun } from "../../engine/runner/grade";
import { isUnlocked } from "../../engine/progress/path";
import { useProgress } from "../../engine/progress/store";
import { puzzleRng } from "../../engine/rng";
import { Editor } from "../../components/Editor";
import { OutputPanel } from "../../components/OutputPanel";
import { Celebration } from "../../components/Celebration";
import { EmberToastWrapper } from "../../components/EmberToast";
import { ChallengeArt } from "../../components/ui/challenge-art";
import {
  HexGrid,
  GlowBlob,
  CircuitTrace,
  MoltenSeam,
} from "../../components/ui/forge-decor";

export function ChallengeScreen() {
  const { id = "" } = useParams();
  const challenge = getChallenge(id);

  const solvedList = useProgress((s) => s.solved);
  const readLessons = useProgress((s) => s.readLessons);
  const playerSeed = useProgress((s) => s.playerSeed);
  const reroll = useProgress((s) => s.reroll);
  const language = useProgress((s) => s.language);
  const setLanguage = useProgress((s) => s.setLanguage);
  const setDraft = useProgress((s) => s.setDraft);
  const markSolved = useProgress((s) => s.markSolved);
  const draft = useProgress((s) => (challenge ? s.drafts[challenge.id]?.[language] : undefined));

  const solved = useMemo(() => new Set(solvedList), [solvedList]);
  const complete = useMemo(
    () => new Set([...solvedList, ...readLessons]),
    [solvedList, readLessons],
  );
  const puzzle = useMemo<PuzzleInstance>(() => {
    if (!challenge) return { input: "", expected: "" };
    if (challenge.generate) return challenge.generate(puzzleRng(playerSeed, challenge.id));
    return { input: challenge.input, expected: challenge.expected };
  }, [challenge, playerSeed]);

  const [running, setRunning] = useState(false);
  const [result, setResult] = useState<RunResult | null>(null);
  const [grade, setGrade] = useState<GradeResult | null>(null);
  const [hintsShown, setHintsShown] = useState(0);
  const [justSolved, setJustSolved] = useState(false);
  const [showToast, setShowToast] = useState(false);
  const [showSolution, setShowSolution] = useState(false);

  useEffect(() => { preloadRuntime(language); }, [language]);
  useEffect(() => {
    setResult(null); setGrade(null); setHintsShown(0);
    setJustSolved(false); setShowSolution(false);
  }, [id, language, playerSeed]);

  if (!challenge) {
    return (
      <Empty>
        That challenge doesn't exist.{" "}
        <Link to="/academy" className="text-ember underline">Back to Academy</Link>.
      </Empty>
    );
  }

  const path = pathForChallenge(challenge);
  const pathIndex = indexInPath(path, challenge.id);
  if (!isUnlocked(pathIndex, path, complete)) {
    const prev = path[pathIndex - 1];
    return (
      <Empty>
        <strong>{challenge.title}</strong> is locked. Finish{" "}
        {prev ? (
          <Link to={hrefFor(prev)} className="text-ember underline">the previous step</Link>
        ) : (
          "the previous step"
        )}{" "}
        first.
      </Empty>
    );
  }

  const code = draft ?? challenge.starterCode[language];
  const alreadySolved = solved.has(challenge.id);
  const technique = optionalLessonFor(challenge.id);
  const next: PathItem | undefined = path[pathIndex + 1];
  const nextHref = next ? hrefFor(next) : null;
  const nextLabel = next
    ? next.kind === "lesson" ? next.lesson.title : next.challenge.title
    : "";

  async function handleRun() {
    if (!challenge) return;
    setRunning(true); setJustSolved(false);
    const res = await runCode(language, code, puzzle.input);
    const g = gradeRun(res, puzzle.expected);
    setResult(res); setGrade(g); setRunning(false);
    if (g.correct) {
      const wasUnsolved = !solved.has(challenge.id);
      markSolved(challenge.id);
      if (wasUnsolved) { setJustSolved(true); setShowToast(true); }
    }
  }

  return (
    <div style={{ background: "#1A1D22", minHeight: "100%" }}>
    <div className="relative mx-auto flex max-w-6xl flex-col gap-6 px-6 py-8 lg:px-8">
      {/* Ambient page glow */}
      <GlowBlob x="78%" y="-6%" color="#EA580C" size={560} opacity={0.035} />
      <GlowBlob x="12%" y="88%" color="#0891B2" size={420} opacity={0.03} />

      {justSolved && <Celebration />}
      <EmberToastWrapper
        show={showToast}
        amount={challenge.difficulty * 5}
        onDone={() => setShowToast(false)}
      />

      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          <Link to={`/${challenge.track}`} className="font-mono text-sm text-dim hover:text-text">
            ← back
          </Link>
          <h1 className={`font-display text-2xl font-extrabold tracking-tight ${alreadySolved ? "text-success" : ""}`}>
            {challenge.title}
          </h1>
        </div>
        <div className="flex items-center gap-3">
          <span className="font-mono text-xs text-dim">{challenge.topic}</span>
        </div>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        {/* ── Left: challenge info ── */}
        <div className="relative overflow-hidden rounded-xl border border-border/60 bg-panel">
          {/* Molten seam along the top edge */}
          <MoltenSeam accent="ember" style={{ position: "absolute", top: 0, left: 0, right: 0, zIndex: 4 }} />

          {/* Decoration layer — sits above bg-panel, below content */}
          <div
            aria-hidden="true"
            style={{ position: "absolute", inset: 0, zIndex: 1, pointerEvents: "none", overflow: "hidden" }}
          >
            <HexGrid style={{ opacity: 0.4 }} />
            <GlowBlob x="94%" y="3%" color="#EA580C" size={340} opacity={0.09} />
            <GlowBlob x="4%" y="96%" color="#0891B2" size={280} opacity={0.05} />

            {/* Single large ghost watermark, bottom-right */}
            <div style={{ position: "absolute", right: -30, bottom: -30, opacity: 0.05 }}>
              <ChallengeArt id={challenge.id} size={210} />
            </div>

            <CircuitTrace
              style={{ position: "absolute", bottom: 40, left: 4 }}
              color="#EA580C"
              opacity={0.11}
            />
          </div>

          {/* Content layer */}
          <div className="relative flex flex-col divide-y divide-border px-5" style={{ zIndex: 2 }}>
            {/* Featured art + meta */}
            <div className="flex items-center gap-5 py-5 pr-14">
              <div
                className="rounded-xl overflow-hidden shrink-0"
                style={{ boxShadow: "0 4px 24px rgba(0,0,0,0.55), 0 0 0 1px rgba(255,255,255,0.06)" }}
              >
                <ChallengeArt id={challenge.id} size={112} />
              </div>
              {challenge.track === "gauntlet" && (
                <p className="text-sm italic leading-relaxed text-dim">{challenge.story}</p>
              )}
              {challenge.track === "academy" && (
                <div>
                  <p className="font-mono text-[10px] font-bold uppercase tracking-[0.2em] text-steel mb-1">teaches</p>
                  <p className="font-display text-sm font-semibold text-text">{challenge.concept}</p>
                </div>
              )}
            </div>

            {technique && (
              <div className="py-3">
                <Link
                  to={`/lesson/${technique.id}`}
                  className="inline-flex items-center gap-2 font-mono text-xs"
                >
                  <span className="font-bold uppercase tracking-[0.15em] text-steel-dim">Technique</span>
                  <span className="text-border">·</span>
                  <span className="text-steel underline underline-offset-2 transition-colors hover:text-steel-dim">
                    {technique.title}
                  </span>
                </Link>
              </div>
            )}

            <div className="py-5">
              <p className="mb-3 font-mono text-[10px] font-bold uppercase tracking-[0.2em] text-steel">
                teaches: {challenge.concept}
              </p>
              <pre className="whitespace-pre-wrap font-sans text-sm leading-relaxed text-text">{challenge.prompt}</pre>
            </div>

            <details className="py-4 text-sm" open={Boolean(challenge.generate)}>
              <summary className="cursor-pointer font-mono text-[10px] font-bold uppercase tracking-[0.2em] text-dim">
                Your input
                {challenge.generate && (
                  <span className="ml-1.5 font-normal normal-case tracking-normal text-locked">
                    ({puzzle.input.split("\n").length} lines)
                  </span>
                )}
              </summary>
              <div className="mt-3">
                {challenge.generate && (
                  <div className="mb-1.5 flex justify-end">
                    <button
                      onClick={reroll}
                      className="font-mono text-xs text-dim hover:text-ember"
                      title="Generate a fresh puzzle"
                    >
                      ↺ reroll
                    </button>
                  </div>
                )}
                <pre className="max-h-40 overflow-auto whitespace-pre-wrap rounded-lg border border-border bg-panel-2 p-3 font-mono text-xs text-steel-dim">
                  {puzzle.input}
                </pre>
                <p className="mt-1.5 font-mono text-[10px] text-locked">
                  passed as <code className="text-ember">text</code> to your <code className="text-ember">solve(text)</code>
                </p>
              </div>
            </details>

            <div className="py-5 text-sm">
              <div className="flex items-center justify-between">
                <span className="font-mono text-[10px] font-bold uppercase tracking-[0.2em] text-dim">Hints</span>
                {hintsShown < challenge.hints.length && (
                  <button
                    onClick={() => setHintsShown((n) => n + 1)}
                    className="font-mono text-xs text-ember hover:text-ember-bright"
                  >
                    reveal {hintsShown}/{challenge.hints.length}
                  </button>
                )}
              </div>
              {hintsShown === 0 ? (
                <p className="mt-2 text-xs text-locked">Stuck? Reveal hints one at a time.</p>
              ) : (
                <ul className="mt-2 flex list-disc flex-col gap-1 pl-5 text-dim">
                  {challenge.hints.slice(0, hintsShown).map((h, i) => (
                    <li key={i}>{h}</li>
                  ))}
                </ul>
              )}
            </div>
          </div>
        </div>

        {/* ── Right: editor + run ── */}
        <div className="flex flex-col gap-3">
          <div className="flex items-center justify-between">
            <div className="flex gap-1 rounded-lg border border-border bg-panel p-1">
              {LANGUAGES.map((lang) => (
                <button
                  key={lang}
                  onClick={() => setLanguage(lang)}
                  className={`rounded-md px-3 py-1 font-mono text-sm transition-colors ${
                    lang === language
                      ? "bg-ember font-semibold text-bg"
                      : "text-dim hover:text-text"
                  }`}
                >
                  {LANGUAGE_LABELS[lang]}
                </button>
              ))}
            </div>
            <button
              onClick={() => setDraft(challenge.id, language, challenge.starterCode[language])}
              className="font-mono text-xs text-dim hover:text-text"
            >
              reset code
            </button>
          </div>

          <Editor
            value={code}
            language={language}
            onChange={(v) => setDraft(challenge.id, language, v)}
            accent="ember"
          />

          <div className="flex items-center gap-3">
            <button
              onClick={handleRun}
              disabled={running}
              className={`rounded-lg bg-ember px-7 py-2.5 font-display font-semibold text-bg disabled:opacity-70 ${running ? "pop-pulse" : ""}`}
              style={{
                transition: "background-color 150ms ease, box-shadow 150ms ease",
                boxShadow: running ? undefined : "0 4px 16px -4px rgba(234,88,12,0.5), 0 0 0 1px rgba(234,88,12,0.2)",
              }}
            >
              {running ? "Running…" : "Run"}
            </button>
            {language === "python" && (
              <span className="font-mono text-xs text-dim">
                first Python run loads the runtime (~a few seconds)
              </span>
            )}
          </div>

          <OutputPanel running={running} result={result} grade={grade} />

          {(justSolved || (alreadySolved && grade?.correct)) && (
            <div
              className="rounded-xl border border-success/30 bg-success/[0.08] p-5"
              style={{ boxShadow: "0 0 30px -8px rgba(34,197,94,0.2), 0 0 0 1px rgba(34,197,94,0.1) inset" }}
            >
              <p
                className="font-display text-lg font-semibold text-success"
                style={{ textShadow: "0 0 20px rgba(34,197,94,0.4)" }}
              >
                {!next
                  ? challenge.track === "gauntlet"
                    ? "The deep goes quiet. You cleared the Gauntlet."
                    : "The Core is relit. You finished the Academy."
                  : "Nice work. That part of the Forge is back online."}
              </p>
              {next && nextHref ? (
                <Link
                  to={nextHref}
                  className="mt-3 inline-block rounded-lg bg-ember px-5 py-2 font-display font-semibold text-bg transition-colors hover:bg-ember-bright"
                >
                  Next: {nextLabel}
                </Link>
              ) : (
                <Link to="/" className="mt-3 inline-block text-ember underline">
                  Back to the Forge
                </Link>
              )}
            </div>
          )}

          {alreadySolved && (
            <details
              open={showSolution}
              onToggle={(e) => setShowSolution((e.target as HTMLDetailsElement).open)}
              className="border-t border-border pt-4 text-sm"
            >
              <summary className="cursor-pointer font-mono text-[10px] font-bold uppercase tracking-[0.2em] text-dim">
                Peek at one solution
              </summary>
              <pre className="mt-3 overflow-auto rounded-lg border border-border bg-panel-2 p-3 font-mono text-xs text-steel-dim">
                {challenge.solution[language]}
              </pre>
            </details>
          )}
        </div>
      </div>
    </div>
    </div>
  );
}

function hrefFor(item: PathItem) {
  return item.kind === "lesson" ? `/lesson/${item.id}` : `/challenge/${item.id}`;
}

function Empty({ children }: { children: React.ReactNode }) {
  return (
    <div className="rounded-2xl border border-border bg-panel p-10 text-center text-dim">{children}</div>
  );
}
