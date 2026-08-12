import { Fragment, useEffect, useMemo, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { getLesson } from "../../content/lessons";
import { pathForLesson, indexInPath } from "../../content/path";
import { LANGUAGES, LANGUAGE_LABELS, type GradeResult, type RunResult } from "../../engine/types";
import { preloadRuntime, runCode } from "../../engine/runner";
import { gradeRun } from "../../engine/runner/grade";
import { isUnlocked, nextItem } from "../../engine/progress/path";
import { useProgress } from "../../engine/progress/store";
import { Editor } from "../../components/Editor";
import { OutputPanel } from "../../components/OutputPanel";
import { ChallengeArt } from "../../components/ui/challenge-art";
import { Sprocket } from "../../components/ui/sprocket";
import {
  HexGrid,
  GlowBlob,
  CornerRune,
  CircuitTrace,
  ForgeStamp,
  MoltenSeam,
} from "../../components/ui/forge-decor";

function hrefFor(kind: "lesson" | "challenge", id: string) {
  return kind === "lesson" ? `/lesson/${id}` : `/challenge/${id}`;
}

export function LessonScreen() {
  const { id = "" } = useParams();
  const navigate = useNavigate();
  const lesson = getLesson(id);

  const solved = useProgress((s) => s.solved);
  const readLessons = useProgress((s) => s.readLessons);
  const language = useProgress((s) => s.language);
  const setLanguage = useProgress((s) => s.setLanguage);
  const markLessonRead = useProgress((s) => s.markLessonRead);

  const complete = useMemo(
    () => new Set([...solved, ...readLessons]),
    [solved, readLessons],
  );

  const [code, setCode] = useState("");
  const [running, setRunning] = useState(false);
  const [result, setResult] = useState<RunResult | null>(null);
  const [grade, setGrade] = useState<GradeResult | null>(null);

  useEffect(() => {
    preloadRuntime(language);
  }, [language]);
  useEffect(() => {
    if (lesson) setCode(lesson.example.code[language]);
    setResult(null);
    setGrade(null);
  }, [id, language, lesson]);

  if (!lesson) {
    return (
      <div className="rounded-2xl border border-border bg-panel p-10 text-center text-dim">
        That lesson doesn't exist.{" "}
        <Link to="/academy" className="text-ember underline">Back to Academy</Link>.
      </div>
    );
  }

  const path = pathForLesson(lesson);
  const index = indexInPath(path, lesson.id);
  const locked = index >= 0 && !isUnlocked(index, path, complete);
  if (locked) {
    const prev = path[index - 1];
    return (
      <div className="rounded-xl border border-border bg-panel p-10 text-center text-dim">
        <strong>{lesson.title}</strong> is locked. Finish{" "}
        {prev ? (
          <Link to={hrefFor(prev.kind, prev.id)} className="text-ember underline">
            the previous step
          </Link>
        ) : (
          "the previous step"
        )}{" "}
        first.
      </div>
    );
  }

  async function handleRun() {
    if (!lesson) return;
    setRunning(true);
    const res = await runCode(language, code, lesson.example.input);
    setResult(res);
    setGrade(gradeRun(res, lesson.example.expected));
    setRunning(false);
  }

  function handleContinue() {
    if (!lesson) return;
    markLessonRead(lesson.id);
    // Optional (Gauntlet) technique lessons aren't on the path — return to the challenge.
    if (index < 0) {
      navigate(`/challenge/${lesson.before}`);
      return;
    }
    const next = nextItem(path, new Set([...complete, lesson.id]));
    navigate(next ? hrefFor(next.kind, next.id) : "/");
  }

  return (
    <div style={{ background: "#1A1D22", minHeight: "100%" }}>
    <div className="relative mx-auto flex max-w-6xl flex-col gap-6 px-6 py-8 lg:px-8">
      {/* Ambient page glow */}
      <GlowBlob x="15%" y="-8%" color="#0891B2" size={500} opacity={0.035} />
      <GlowBlob x="88%" y="90%" color="#EA580C" size={380} opacity={0.03} />

      <div className="flex flex-wrap items-center gap-3">
        <Link to={index < 0 ? "/gauntlet" : "/academy"} className="font-mono text-sm text-dim hover:text-text">
          ← back
        </Link>
        <span className="rounded border border-steel-dim/40 bg-steel/10 px-2 py-0.5 font-mono text-[10px] font-semibold uppercase tracking-wide text-steel">
          lesson
        </span>
        <h1 className={`font-display text-2xl font-extrabold tracking-tight ${readLessons.includes(lesson.id) ? "text-steel" : ""}`}>{lesson.title}</h1>
        <span className="font-mono text-xs text-dim">{lesson.concept}</span>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        {/* ── Teaching panel ── */}
        <div className="relative overflow-hidden rounded-xl border border-border bg-panel">
          {/* Molten seam along the top edge (steel-toned for lessons) */}
          <MoltenSeam accent="steel" style={{ position: "absolute", top: 0, left: 0, right: 0, zIndex: 4 }} />

          {/* Decoration layer */}
          <div
            aria-hidden="true"
            style={{ position: "absolute", inset: 0, zIndex: 1, pointerEvents: "none", overflow: "hidden" }}
          >
            <HexGrid style={{ opacity: 0.35 }} />
            <GlowBlob x="92%" y="3%" color="#0891B2" size={320} opacity={0.08} />
            <GlowBlob x="4%" y="96%" color="#EA580C" size={240} opacity={0.04} />

            {/* Single ghost art watermark */}
            <div style={{ position: "absolute", right: -24, bottom: -24, opacity: 0.05 }}>
              {lesson.before
                ? <ChallengeArt id={lesson.before} size={200} />
                : <Sprocket size={180} mood="neutral" />
              }
            </div>

            <CircuitTrace
              flip
              style={{ position: "absolute", bottom: 44, right: 6 }}
              color="#0891B2"
              opacity={0.09}
            />
          </div>

          {/* Corner runes — bottom pair only */}
          <CornerRune corner="bl" style={{ position: "absolute", bottom: 9, left: 9, zIndex: 3 }} color="#0891B2" opacity={0.3} />
          <CornerRune corner="br" style={{ position: "absolute", bottom: 9, right: 9, zIndex: 3 }} color="#0891B2" opacity={0.3} />

          {/* Struck-metal "L" stamp, top-right */}
          <div
            className="absolute right-4 top-4"
            style={{ zIndex: 5, filter: "drop-shadow(0 3px 8px rgba(0,0,0,0.5))" }}
            title="Lesson"
          >
            <ForgeStamp label="L" accent="steel" size={46} />
          </div>

          {/* Art banner */}
          <div
            className="relative flex items-center gap-5 border-b border-border px-6 py-5 pr-16"
            style={{ zIndex: 2, background: "linear-gradient(135deg, rgba(8,145,178,0.1) 0%, rgba(42,45,51,0) 70%)" }}
          >
            <div
              className="rounded-xl overflow-hidden shrink-0"
              style={{ boxShadow: "0 4px 20px rgba(0,0,0,0.5), 0 0 0 1px rgba(8,145,178,0.2)" }}
            >
              {lesson.before
                ? <ChallengeArt id={lesson.before} size={100} />
                : <Sprocket size={100} mood="neutral" />
              }
            </div>
            <div>
              <p className="font-mono text-[10px] font-bold uppercase tracking-[0.2em] text-steel mb-1">lesson</p>
              <p className="font-display text-base font-bold text-text leading-tight">{lesson.title}</p>
              <p className="mt-1 font-mono text-xs text-dim">{lesson.concept}</p>
            </div>
          </div>

          {/* Body */}
          <div className="relative p-6" style={{ zIndex: 2 }}>
            <LessonBody body={lesson.body} />
          </div>
        </div>

        {/* Runnable example */}
        <div className="flex flex-col gap-3">
          <div className="rounded-xl border border-steel-dim/40 bg-steel/[0.12] p-4">
            <p className="font-mono text-xs font-semibold uppercase tracking-wider text-steel">
              ▸ try it
            </p>
            <p className="mt-1 text-sm text-text font-sans" style={{ fontFamily: 'var(--font-sans)' }}>{lesson.example.prompt}</p>
          </div>

          <div className="flex items-center justify-between">
            <div className="flex gap-1 rounded-lg border border-border bg-panel p-1">
              {LANGUAGES.map((lang) => (
                <button
                  key={lang}
                  onClick={() => setLanguage(lang)}
                  className={`rounded-md px-3 py-1 font-mono text-sm transition-colors ${
                    lang === language ? "bg-steel font-semibold text-bg" : "text-dim hover:text-text"
                  }`}
                >
                  {LANGUAGE_LABELS[lang]}
                </button>
              ))}
            </div>
            <button
              onClick={() => setCode(lesson.example.code[language])}
              className="font-mono text-xs text-dim hover:text-text"
            >
              reset example
            </button>
          </div>

          <Editor value={code} language={language} onChange={setCode} accent="steel" />

          <div className="flex flex-wrap items-center gap-3">
            <button
              onClick={handleRun}
              disabled={running}
              className="rounded-lg border border-steel/60 bg-steel/15 px-6 py-2.5 font-display font-semibold text-steel transition-colors hover:bg-steel/25 disabled:opacity-70"
            >
              {running ? "Running…" : "Run example"}
            </button>
            <button
              onClick={handleContinue}
              className="rounded-lg bg-ember px-6 py-2.5 font-display font-semibold text-bg hover:bg-ember-bright"
              style={{ transition: "background-color 150ms ease, box-shadow 150ms ease", boxShadow: "0 4px 16px -4px rgba(234,88,12,0.5), 0 0 0 1px rgba(234,88,12,0.2)" }}
            >
              Continue →
            </button>
          </div>

          <OutputPanel running={running} result={result} grade={grade} />
        </div>
      </div>
    </div>
    </div>
  );
}

/** Lightweight renderer for the lesson body: ## headings, - bullets, ```fences```, **bold**, `code`. */
function LessonBody({ body }: { body: string }) {
  const lines = body.split("\n");
  const blocks: React.ReactNode[] = [];
  let i = 0;
  let key = 0;

  while (i < lines.length) {
    const line = lines[i];

    if (line.startsWith("```")) {
      const code: string[] = [];
      i++;
      while (i < lines.length && !lines[i].startsWith("```")) code.push(lines[i++]);
      i++;
      blocks.push(
        <pre key={key++} className="my-3 overflow-auto rounded-lg border border-border bg-panel-2 p-3 font-mono text-xs text-steel-dim" style={{ borderLeft: "3px solid rgba(234,88,12,0.5)" }}>
          {code.join("\n")}
        </pre>,
      );
      continue;
    }
    if (line.startsWith("## ")) {
      blocks.push(
        <h3 key={key++} className="mt-4 font-display text-base font-semibold">
          {line.slice(3)}
        </h3>,
      );
      i++;
      continue;
    }
    if (line.startsWith("- ")) {
      const items: string[] = [];
      while (i < lines.length && lines[i].startsWith("- ")) items.push(lines[i++].slice(2));
      blocks.push(
        <ul key={key++} className="my-2 flex list-disc flex-col gap-1.5 pl-5 text-dim font-sans" style={{ fontFamily: 'var(--font-sans)', fontSize: '0.875rem' }}>
          {items.map((it, n) => (
            <li key={n} style={{ lineHeight: 1.6 }}>{renderInline(it)}</li>
          ))}
        </ul>,
      );
      continue;
    }
    if (line.trim() === "") {
      i++;
      continue;
    }
    const para: string[] = [line];
    i++;
    while (
      i < lines.length &&
      lines[i].trim() !== "" &&
      !lines[i].startsWith("## ") &&
      !lines[i].startsWith("- ") &&
      !lines[i].startsWith("```")
    ) {
      para.push(lines[i++]);
    }
    blocks.push(
      <p key={key++} className="my-2 text-dim font-sans" style={{ lineHeight: 1.75, fontFamily: 'var(--font-sans)', fontSize: '0.875rem' }}>
        {renderInline(para.join(" "))}
      </p>,
    );
  }
  return <div>{blocks}</div>;
}

function renderInline(text: string): React.ReactNode {
  const parts = text.split(/(\*\*[^*]+\*\*|`[^`]+`)/g);
  return parts.map((p, i) => {
    if (p.startsWith("**") && p.endsWith("**")) {
      return (
        <strong key={i} className="font-semibold text-text">
          {p.slice(2, -2)}
        </strong>
      );
    }
    if (p.startsWith("`") && p.endsWith("`")) {
      return (
        <code key={i} className="rounded bg-ember/10 px-1 py-0.5 font-mono text-xs text-ember">
          {p.slice(1, -1)}
        </code>
      );
    }
    return <Fragment key={i}>{p}</Fragment>;
  });
}
