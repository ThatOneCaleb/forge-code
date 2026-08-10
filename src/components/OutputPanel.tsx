import type { GradeResult, RunResult } from "../engine/types";

interface OutputPanelProps {
  running: boolean;
  result: RunResult | null;
  grade: GradeResult | null;
}

export function OutputPanel({ running, result, grade }: OutputPanelProps) {
  if (running) {
    return (
      <Panel tone="neutral">
        <span className="animate-pulse font-mono text-dim">▸ running your code…</span>
      </Panel>
    );
  }

  if (!result) {
    return (
      <Panel tone="neutral">
        <span className="font-mono text-dim">▸ run your code to see the result</span>
      </Panel>
    );
  }

  if (!result.ok) {
    return (
      <Panel tone="error">
        <p className="font-display font-semibold text-danger">Your code hit an error</p>
        <pre className="mt-1 whitespace-pre-wrap font-mono text-sm text-danger/90">{result.error}</pre>
        <Logs logs={result.logs} />
      </Panel>
    );
  }

  const correct = grade?.correct;
  return (
    <Panel tone={correct ? "success" : "warn"}>
      <p className={`font-display font-semibold ${correct ? "text-success" : "text-ember-bright"}`}>
        {correct ? "Correct!" : "Not quite yet"}
      </p>
      <div className="mt-2 grid gap-1 font-mono text-sm">
        <Row label="your answer" value={result.output} tone={correct ? "good" : "bad"} />
        {!correct && grade && <Row label="expected" value={grade.expected} tone="good" />}
      </div>
      <Logs logs={result.logs} />
      <p className="mt-2 font-mono text-xs text-dim">ran in {result.durationMs} ms</p>
    </Panel>
  );
}

function Row({ label, value, tone }: { label: string; value: string; tone: "good" | "bad" }) {
  return (
    <div className="flex gap-2">
      <span className="w-28 shrink-0 text-dim">{label}</span>
      <span className={tone === "good" ? "text-success" : "text-danger"}>
        {value === "" ? <em className="text-dim">(empty)</em> : value}
      </span>
    </div>
  );
}

function Logs({ logs }: { logs: string[] }) {
  if (!logs.length) return null;
  return (
    <details className="mt-3">
      <summary className="cursor-pointer font-mono text-xs text-dim">
        console output ({logs.length})
      </summary>
      <pre className="mt-1 max-h-40 overflow-auto whitespace-pre-wrap rounded-lg border border-border bg-panel-2 p-2 font-mono text-xs text-steel-dim">
        {logs.join("\n")}
      </pre>
    </details>
  );
}

const toneClasses: Record<string, string> = {
  neutral: "border-border bg-panel",
  success: "border-success/30 bg-success/[0.12]",
  warn: "border-ember/35 bg-ember/[0.10]",
  error: "border-danger/35 bg-danger/[0.10]",
};

function Panel({ tone, children }: { tone: keyof typeof toneClasses; children: React.ReactNode }) {
  return <div className={`rounded-xl border p-4 text-sm ${toneClasses[tone]}`}>{children}</div>;
}
