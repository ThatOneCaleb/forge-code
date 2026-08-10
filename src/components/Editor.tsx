import CodeMirror from "@uiw/react-codemirror";
import { python } from "@codemirror/lang-python";
import { javascript } from "@codemirror/lang-javascript";
import { oneDark } from "@codemirror/theme-one-dark";
import type { Extension } from "@codemirror/state";
import { EditorView } from "@codemirror/view";
import type { Language } from "../engine/types";

const noPasteExtension = EditorView.domEventHandlers({
  paste(e) { e.preventDefault(); return true; },
  drop(e) { e.preventDefault(); return true; },
});

const forgeTheme = EditorView.theme({
  "&": {
    backgroundColor: "#1B1410",
    color: "#EDE0CF",
    fontSize: "13px",
    fontFamily: '"JetBrains Mono", ui-monospace, monospace',
  },
  ".cm-content": {
    padding: "12px 0",
    caretColor: "#EA580C",
  },
  ".cm-line": {
    padding: "0 12px",
  },
  ".cm-gutters": {
    backgroundColor: "#161009",
    borderRight: "1px solid #32211A",
    color: "#5A4E44",
  },
  ".cm-activeLineGutter": {
    backgroundColor: "#211810",
  },
  ".cm-activeLine": {
    backgroundColor: "rgba(234,88,12,0.06)",
  },
  ".cm-selectionBackground, &.cm-focused .cm-selectionBackground": {
    backgroundColor: "rgba(234,88,12,0.18)",
  },
  ".cm-cursor": {
    borderLeftColor: "#EA580C",
    borderLeftWidth: "2px",
  },
  ".cm-matchingBracket": {
    backgroundColor: "rgba(234,88,12,0.25)",
    outline: "none",
  },
}, { dark: true });

function extensions(language: Language, noPaste = false): Extension[] {
  const base = language === "python" ? [python()] : [javascript({ jsx: false })];
  return noPaste ? [...base, noPasteExtension] : base;
}

interface EditorProps {
  value: string;
  language: Language;
  onChange: (value: string) => void;
  /** Accent color for the terminal chrome — ember for challenges, steel for lessons. */
  accent?: "ember" | "steel";
  /** Block paste and drop (used for daily challenges). */
  noPaste?: boolean;
}

const ACCENTS = {
  ember: { dot: "#EA580C", glow: "rgba(234,88,12,0.55)", text: "#FB923C" },
  steel: { dot: "#4A90C4", glow: "rgba(74,144,196,0.5)", text: "#6BAAD8" },
};

export function Editor({ value, language, onChange, accent = "ember", noPaste = false }: EditorProps) {
  const filename = language === "python" ? "solve.py" : "solve.js";
  const a = ACCENTS[accent];
  const lineCount = value.split("\n").length;

  return (
    <div
      className="overflow-hidden rounded-lg border border-border"
      style={{ boxShadow: `0 8px 30px -12px rgba(0,0,0,0.6), 0 0 0 1px ${a.glow.replace(/[\d.]+\)$/, "0.12)")}` }}
    >
      {/* Forge terminal chrome */}
      <div
        className="flex items-center gap-3 border-b px-3.5 py-2"
        style={{
          background: "linear-gradient(180deg, #201811 0%, #161009 100%)",
          borderColor: "#32211A",
        }}
      >
        {/* Rivet lights */}
        <div className="flex items-center gap-1.5">
          <span style={{ width: 9, height: 9, borderRadius: "50%", background: a.dot, boxShadow: `0 0 6px ${a.glow}` }} />
          <span style={{ width: 9, height: 9, borderRadius: "50%", background: "#4A505C" }} />
          <span style={{ width: 9, height: 9, borderRadius: "50%", background: "#32211A" }} />
        </div>

        {/* Filename tab */}
        <div
          className="flex items-center gap-1.5 rounded-md px-2.5 py-0.5"
          style={{ background: "rgba(0,0,0,0.35)", border: "1px solid #32211A" }}
        >
          <svg width="10" height="10" viewBox="0 0 10 10" aria-hidden="true">
            <path d="M2 1 H6 L8 3 V9 H2 Z" fill="none" stroke={a.text} strokeWidth="0.9" opacity="0.8" />
          </svg>
          <span className="font-mono text-[11px] font-semibold" style={{ color: "#EDE0CF" }}>
            {filename}
          </span>
        </div>

        {/* Status readout */}
        <div className="ml-auto flex items-center gap-2 font-mono text-[10px] uppercase tracking-[0.15em]" style={{ color: "#5A4E44" }}>
          <span>{lineCount} ln</span>
          <span style={{ color: "#32211A" }}>·</span>
          <span className="flex items-center gap-1" style={{ color: a.text }}>
            <span style={{ width: 5, height: 5, borderRadius: "50%", background: a.dot, boxShadow: `0 0 5px ${a.glow}` }} />
            forge
          </span>
        </div>
      </div>

      <CodeMirror
        value={value}
        theme={[oneDark, forgeTheme]}
        height="340px"
        extensions={extensions(language, noPaste)}
        onChange={onChange}
        basicSetup={{
          lineNumbers: true,
          highlightActiveLine: true,
          foldGutter: false,
          autocompletion: true,
          tabSize: 2,
        }}
      />
    </div>
  );
}
