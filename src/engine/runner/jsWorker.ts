/// <reference lib="webworker" />
// Runs user JavaScript in an isolated worker. The user defines `solve(text)`;
// we call it with the puzzle input and post back the stringified result.

interface RunMessage {
  id: string;
  source: string;
  input: string;
}

self.onmessage = (e: MessageEvent<RunMessage>) => {
  const { id, source, input } = e.data;
  const logs: string[] = [];
  const realLog = console.log;
  console.log = (...args: unknown[]) => {
    logs.push(args.map((a) => (typeof a === "string" ? a : JSON.stringify(a))).join(" "));
  };

  try {
    // Define the user's code, then hand back their `solve` function.
    const factory = new Function(
      `"use strict";\n${source}\n;return typeof solve === "function" ? solve : null;`,
    );
    const solve = factory();
    if (typeof solve !== "function") {
      throw new Error("Define a function named solve(text) that returns the answer.");
    }
    const result = solve(input);
    self.postMessage({
      id,
      ok: true,
      output: result === undefined || result === null ? "" : String(result),
      logs,
    });
  } catch (err) {
    self.postMessage({
      id,
      ok: false,
      output: "",
      logs,
      error: err instanceof Error ? err.message : String(err),
    });
  } finally {
    console.log = realLog;
  }
};
