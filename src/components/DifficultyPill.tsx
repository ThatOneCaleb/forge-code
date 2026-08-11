const LABELS: Record<number, string> = {
  1: "Warm-up",
  2: "Easy",
  3: "Medium",
  4: "Hard",
  5: "Tough",
  6: "Expert",
  7: "Brutal",
  8: "Savage",
  9: "Insane",
  10: "Nightmare",
};

const SCALE = 10;

/** Color climbs steel (cool/easy) → ember → red (brutal) as difficulty rises. */
function tierClasses(d: number): { cls: string; glow: string } {
  if (d <= 2) return { cls: "border-steel-dim/50 bg-steel/10 text-steel", glow: "0 0 8px rgba(8,145,178,0.25) inset, 0 0 6px rgba(8,145,178,0.15)" };
  if (d <= 4) return { cls: "border-ember/40 bg-ember/10 text-ember-bright", glow: "0 0 8px rgba(249,115,22,0.2) inset, 0 0 6px rgba(249,115,22,0.1)" };
  if (d <= 6) return { cls: "border-ember/60 bg-ember/15 text-ember", glow: "0 0 10px rgba(234,88,12,0.3) inset, 0 0 8px rgba(234,88,12,0.15)" };
  if (d <= 8) return { cls: "border-danger/50 bg-danger/10 text-danger", glow: "0 0 10px rgba(239,68,68,0.25) inset, 0 0 8px rgba(239,68,68,0.12)" };
  return { cls: "border-danger/70 bg-danger/20 text-danger", glow: "0 0 14px rgba(239,68,68,0.4) inset, 0 0 10px rgba(239,68,68,0.2)" };
}

export function DifficultyPill({ difficulty }: { difficulty: number }) {
  const label = LABELS[difficulty] ?? `L${difficulty}`;
  const { cls, glow } = tierClasses(difficulty);
  return (
    <span
      title={`Difficulty ${difficulty} of ${SCALE} · ${label}`}
      className={`inline-flex items-center gap-1.5 rounded-md border px-2 py-0.5 font-mono text-xs ${cls}`}
      style={{ boxShadow: glow }}
    >
      <span className="font-bold tracking-tight">L{difficulty}</span>
      <span className="opacity-60">·</span>
      <span>{label}</span>
    </span>
  );
}
