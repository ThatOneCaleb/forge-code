/// <reference lib="webworker" />
// Runs user Python via Pyodide (loaded once from CDN). The user defines
// `solve(text)`; we call it with the puzzle input and post back str(result).
// Execution is fully client-side — no code leaves the browser.

interface RunMessage {
  id: string;
  source: string;
  input: string;
}

const PYODIDE_VERSION = "0.26.4";
const PYODIDE_BASE = `https://cdn.jsdelivr.net/pyodide/v${PYODIDE_VERSION}/full/`;

let pyodidePromise: Promise<any> | null = null;

async function getPyodide(): Promise<any> {
  if (!pyodidePromise) {
    pyodidePromise = (async () => {
      const mod = await import(/* @vite-ignore */ `${PYODIDE_BASE}pyodide.mjs`);
      return mod.loadPyodide({ indexURL: PYODIDE_BASE });
    })();
  }
  return pyodidePromise;
}

self.onmessage = async (e: MessageEvent<RunMessage>) => {
  const { id, source, input } = e.data;
  const logs: string[] = [];
  try {
    const pyodide = await getPyodide();
    pyodide.setStdout({ batched: (s: string) => logs.push(s) });
    pyodide.setStderr({ batched: (s: string) => logs.push(s) });

    // Fresh namespace each run so a previous `solve` can't leak through.
    const namespace = pyodide.globals.get("dict")();
    try {
      namespace.set("__forge_text__", input);
      await pyodide.runPythonAsync(source, { globals: namespace });
      const result = await pyodide.runPythonAsync(
        "str(solve(__forge_text__))",
        { globals: namespace },
      );
      self.postMessage({ id, ok: true, output: String(result), logs });
    } finally {
      namespace.destroy();
    }
  } catch (err) {
    self.postMessage({
      id,
      ok: false,
      output: "",
      logs,
      error: friendlyPyError(err),
    });
  }
};

function friendlyPyError(err: unknown): string {
  const msg = err instanceof Error ? err.message : String(err);
  // Pyodide prepends a long traceback; keep the last, most relevant line.
  const lines = msg.trim().split("\n").filter(Boolean);
  const last = lines[lines.length - 1] ?? msg;
  if (/NameError:.*solve/.test(msg)) {
    return "Define a function named solve(text) that returns the answer.";
  }
  return last;
}
