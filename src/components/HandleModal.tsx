import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { useProgress } from "../engine/progress/store";
import { isHandleTaken } from "../lib/leaderboard-api";

export function HandleModal({ onClose }: { onClose: () => void }) {
  const setHandle = useProgress((s) => s.setHandle);
  const currentHandle = useProgress((s) => s.handle);
  const playerSeed = useProgress((s) => s.playerSeed);
  const [value, setValue] = useState(currentHandle);
  const [error, setError] = useState("");
  const [checking, setChecking] = useState(false);

  async function submit() {
    const trimmed = value.trim();
    if (trimmed.length < 2) { setError("At least 2 characters."); return; }
    if (trimmed.length > 20) { setError("Max 20 characters."); return; }
    if (!/^[a-zA-Z0-9_-]+$/.test(trimmed)) { setError("Letters, numbers, _ and - only."); return; }

    // Skip uniqueness check if keeping the same handle
    if (trimmed !== currentHandle) {
      setChecking(true);
      const taken = await isHandleTaken(trimmed, playerSeed);
      setChecking(false);
      if (taken) { setError("That handle is already taken."); return; }
    }

    setHandle(trimmed);
    onClose();
  }

  return (
    <AnimatePresence>
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        className="fixed inset-0 z-50 flex items-center justify-center"
        style={{ background: "rgba(10,10,12,0.75)", backdropFilter: "blur(4px)" }}
        onClick={(e) => { if (e.target === e.currentTarget) onClose(); }}
      >
        <motion.div
          initial={{ scale: 0.93, opacity: 0, y: 12 }}
          animate={{ scale: 1, opacity: 1, y: 0 }}
          exit={{ scale: 0.95, opacity: 0 }}
          transition={{ type: "spring", stiffness: 380, damping: 30 }}
          className="relative w-full max-w-sm rounded-2xl border p-8"
          style={{
            background: "#1E2026",
            borderColor: "rgba(234,88,12,0.25)",
            boxShadow: "0 24px 64px -12px rgba(0,0,0,0.7), 0 0 0 1px rgba(234,88,12,0.08)",
          }}
        >
          {/* Top ember line */}
          <div className="absolute inset-x-0 top-0 h-px rounded-t-2xl" style={{ background: "linear-gradient(90deg, transparent, rgba(234,88,12,0.6), transparent)" }} />

          <p className="font-mono text-[10px] font-bold uppercase tracking-[0.25em] text-ember mb-3">Forge Code</p>
          <h2 className="font-display text-2xl font-black tracking-tight text-text mb-1">Pick your handle</h2>
          <p className="text-sm text-dim mb-6">
            Saved to your browser. Appears on the leaderboard.
          </p>

          <input
            autoFocus
            type="text"
            value={value}
            onChange={(e) => { setValue(e.target.value); setError(""); }}
            onKeyDown={(e) => { if (e.key === "Enter") submit(); if (e.key === "Escape") onClose(); }}
            maxLength={20}
            placeholder="e.g. ByteSmith42"
            className="w-full rounded-lg border bg-transparent px-4 py-2.5 font-mono text-sm text-text placeholder:text-dim/50 outline-none"
            style={{
              borderColor: error ? "rgba(234,88,12,0.6)" : "rgba(255,255,255,0.1)",
              background: "rgba(255,255,255,0.04)",
            }}
          />
          {error && <p className="mt-1.5 font-mono text-[11px] text-ember">{error}</p>}

          <div className="mt-5 flex gap-3">
            <button
              onClick={submit}
              disabled={checking}
              className="flex-1 rounded-lg py-2.5 font-display text-sm font-bold tracking-wide transition-opacity hover:opacity-90 active:opacity-75 disabled:opacity-50"
              style={{ background: "#EA580C", color: "#fff" }}
            >
              {checking ? "Checking…" : "Save handle"}
            </button>
            {currentHandle && (
              <button
                onClick={onClose}
                className="rounded-lg px-4 py-2.5 font-display text-sm font-semibold text-dim transition-colors hover:text-text"
                style={{ background: "rgba(255,255,255,0.05)" }}
              >
                Cancel
              </button>
            )}
          </div>
        </motion.div>
      </motion.div>
    </AnimatePresence>
  );
}
