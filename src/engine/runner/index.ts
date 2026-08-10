import type { Language, RunResult } from "../types";

/** Hard cap so an infinite loop can't hang the tab forever. */
export const RUN_TIMEOUT_MS = 15_000;

interface Pending {
  resolve: (r: RunResult) => void;
  timer: ReturnType<typeof setTimeout>;
  started: number;
}

const workers: Partial<Record<Language, Worker>> = {};
const pending: Partial<Record<Language, Map<string, Pending>>> = {};

function createWorker(lang: Language): Worker {
  const worker =
    lang === "python"
      ? new Worker(new URL("./pythonWorker.ts", import.meta.url), { type: "module" })
      : new Worker(new URL("./jsWorker.ts", import.meta.url), { type: "module" });

  const map = new Map<string, Pending>();
  pending[lang] = map;

  worker.onmessage = (e: MessageEvent) => {
    const { id, ok, output, logs, error } = e.data;
    const p = map.get(id);
    if (!p) return;
    clearTimeout(p.timer);
    map.delete(id);
    p.resolve({
      ok: Boolean(ok),
      output: output ?? "",
      logs: logs ?? [],
      error,
      durationMs: Math.round(performance.now() - p.started),
    });
  };

  worker.onerror = (e) => {
    // A hard worker error rejects every in-flight run and resets the worker.
    for (const [, p] of map) {
      clearTimeout(p.timer);
      p.resolve({
        ok: false,
        output: "",
        logs: [],
        error: e.message || "Worker crashed.",
        durationMs: Math.round(performance.now() - p.started),
      });
    }
    map.clear();
    resetWorker(lang);
  };

  return worker;
}

function getWorker(lang: Language): Worker {
  let w = workers[lang];
  if (!w) {
    w = createWorker(lang);
    workers[lang] = w;
  }
  return w;
}

function resetWorker(lang: Language) {
  workers[lang]?.terminate();
  workers[lang] = undefined;
  pending[lang]?.clear();
}

/** Warm the Python runtime ahead of the first run (Pyodide load is slow). */
export function preloadRuntime(lang: Language) {
  if (lang === "python") getWorker("python");
}

/**
 * Execute `source` (which must define `solve(text)`) against `input`.
 * Always resolves — failures come back as `{ ok: false, error }`.
 */
export function runCode(lang: Language, source: string, input: string): Promise<RunResult> {
  const worker = getWorker(lang);
  const id =
    typeof crypto !== "undefined" && "randomUUID" in crypto
      ? crypto.randomUUID()
      : String(Math.random());
  const started = performance.now();

  return new Promise<RunResult>((resolve) => {
    const timer = setTimeout(() => {
      pending[lang]?.delete(id);
      // A timed-out worker may be stuck in a loop — kill it and start fresh.
      resetWorker(lang);
      resolve({
        ok: false,
        output: "",
        logs: [],
        error: `Timed out after ${RUN_TIMEOUT_MS / 1000}s — check for an infinite loop.`,
        durationMs: Math.round(performance.now() - started),
      });
    }, RUN_TIMEOUT_MS);

    pending[lang]!.set(id, { resolve, timer, started });
    worker.postMessage({ id, source, input });
  });
}
