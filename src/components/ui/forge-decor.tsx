import { useId } from "react";

/** Subtle hexagonal grid that tiles across its container. */
export function HexGrid({ style }: { style?: React.CSSProperties }) {
  const id = useId();
  return (
    <svg
      aria-hidden="true"
      style={{ position: "absolute", inset: 0, width: "100%", height: "100%", pointerEvents: "none", ...style }}
    >
      <defs>
        <pattern id={`hg${id}`} width="36" height="31.2" patternUnits="userSpaceOnUse">
          <path
            d="M18 1 L35 10.6 L35 20.6 L18 30.2 L1 20.6 L1 10.6 Z"
            fill="none"
            stroke="rgba(74,80,92,0.55)"
            strokeWidth="0.5"
          />
        </pattern>
      </defs>
      <rect width="100%" height="100%" fill={`url(#hg${id})`} />
    </svg>
  );
}

/** Atmospheric radial glow blob — gives panels depth and warmth. */
export function GlowBlob({
  x,
  y,
  color = "#EA580C",
  size = 280,
  opacity = 0.1,
  style,
}: {
  x: string | number;
  y: string | number;
  color?: string;
  size?: number;
  opacity?: number;
  style?: React.CSSProperties;
}) {
  return (
    <div
      aria-hidden="true"
      style={{
        position: "absolute",
        left: x,
        top: y,
        width: size,
        height: size,
        borderRadius: "50%",
        background: `radial-gradient(circle, ${color} 0%, transparent 65%)`,
        opacity,
        pointerEvents: "none",
        filter: "blur(48px)",
        transform: "translate(-50%, -50%)",
        ...style,
      }}
    />
  );
}

/** L-bracket corner ornament — makes panels feel hand-framed. */
export function CornerRune({
  corner = "tl",
  arm = 16,
  color = "#EA580C",
  opacity = 0.45,
  style,
}: {
  corner?: "tl" | "tr" | "bl" | "br";
  arm?: number;
  color?: string;
  opacity?: number;
  style?: React.CSSProperties;
}) {
  const o = 4;
  const e = arm + o;
  const dim = e + o;
  const paths = {
    tl: `M${e} ${o} L${o} ${o} L${o} ${e}`,
    tr: `M${o} ${o} L${e} ${o} L${e} ${e}`,
    bl: `M${e} ${e} L${o} ${e} L${o} ${o}`,
    br: `M${o} ${e} L${e} ${e} L${e} ${o}`,
  };
  return (
    <svg
      width={dim}
      height={dim}
      viewBox={`0 0 ${dim} ${dim}`}
      aria-hidden="true"
      style={{ display: "block", ...style }}
    >
      <path
        d={paths[corner]}
        fill="none"
        stroke={color}
        strokeWidth="1.5"
        strokeLinecap="square"
        opacity={opacity}
      />
    </svg>
  );
}

/** PCB-style circuit trace decoration. */
export function CircuitTrace({
  flip = false,
  color = "#EA580C",
  opacity = 0.16,
  style,
}: {
  flip?: boolean;
  color?: string;
  opacity?: number;
  style?: React.CSSProperties;
}) {
  return (
    <svg
      width="160"
      height="96"
      viewBox="0 0 160 96"
      aria-hidden="true"
      style={{
        display: "block",
        pointerEvents: "none",
        transform: flip ? "scale(-1,-1)" : undefined,
        ...style,
      }}
    >
      <g stroke={color} strokeWidth="1" fill="none">
        <path d="M0 48 H44 V18 H100 V48 H160" opacity={opacity} />
        <circle cx="44" cy="48" r="3.5" fill={color} opacity={opacity} />
        <circle cx="100" cy="48" r="3.5" fill={color} opacity={opacity} />
        <rect x="97" y="15" width="6" height="6" stroke={color} fill="none" opacity={opacity} />
        <line x1="100" y1="15" x2="100" y2="0" stroke={color} strokeDasharray="3 3" opacity={opacity * 0.5} />
        <path d="M0 72 H32 V82 H66" opacity={opacity * 0.55} />
        <path d="M112 82 H136 V72 H160" opacity={opacity * 0.55} />
        <circle cx="32" cy="82" r="2" fill={color} opacity={opacity * 0.7} />
        <circle cx="136" cy="72" r="2" fill={color} opacity={opacity * 0.7} />
      </g>
    </svg>
  );
}

/** Small scattered ember dots — baked positions, no random. */
const BAKED: [number, number, number, string, number][] = [
  [11, 19, 2, "#EA580C", 0.28], [37, 54, 1.5, "#FB923C", 0.22],
  [63, 11, 2.5, "#EA580C", 0.17], [84, 77, 2, "#0891B2", 0.26],
  [21, 87, 1.5, "#EA580C", 0.19], [92, 33, 2, "#FB923C", 0.22],
  [49, 44, 1, "#0891B2", 0.17], [74, 24, 2, "#EA580C", 0.25],
  [6, 64, 1.5, "#FB923C", 0.18], [43, 81, 2.5, "#EA580C", 0.15],
  [96, 8, 1.5, "#0891B2", 0.2], [28, 31, 1, "#EA580C", 0.26],
];

export function EmberDots({ count = 8, style }: { count?: number; style?: React.CSSProperties }) {
  return (
    <svg
      viewBox="0 0 100 100"
      preserveAspectRatio="xMidYMid slice"
      aria-hidden="true"
      style={{ position: "absolute", inset: 0, width: "100%", height: "100%", pointerEvents: "none", ...style }}
    >
      {BAKED.slice(0, count).map(([x, y, r, c, o], i) => (
        <circle key={i} cx={x} cy={y} r={r} fill={c} opacity={o} />
      ))}
    </svg>
  );
}

/** Vertical bar "equalizer" showing difficulty 1–10. */
export function DifficultyMeter({ level, max = 10 }: { level: number; max?: number }) {
  return (
    <div
      className="flex items-end gap-px"
      title={`Difficulty ${level}/${max}`}
      aria-label={`Difficulty ${level} of ${max}`}
    >
      {Array.from({ length: max }, (_, i) => (
        <div
          key={i}
          style={{
            width: 3,
            height: 4 + i * 1.4,
            borderRadius: 1,
            background:
              i < level
                ? `linear-gradient(to top, #EA580C, #FB923C)`
                : "rgba(74,80,92,0.4)",
          }}
        />
      ))}
    </div>
  );
}

/** Struck-metal octagonal medallion — a "forge stamp" holding a number or short label. */
export function ForgeStamp({
  label,
  size = 46,
  accent = "ember",
  dim = false,
}: {
  label: string;
  size?: number;
  accent?: "ember" | "steel";
  dim?: boolean;
}) {
  const id = useId();
  const ring = accent === "ember" ? "#EA580C" : "#0891B2";
  const ringDim = accent === "ember" ? "#7A3410" : "#164E63";
  const text = accent === "ember" ? "#FB923C" : "#38BDF8";
  // Octagon path in a 48 box
  const oct = "M16 3 L32 3 L45 16 L45 32 L32 45 L16 45 L3 32 L3 16 Z";
  return (
    <svg width={size} height={size} viewBox="0 0 48 48" aria-hidden="true" style={{ display: "block", opacity: dim ? 0.6 : 1 }}>
      <defs>
        <linearGradient id={`fs${id}`} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#3E3128" />
          <stop offset="48%" stopColor="#2A211A" />
          <stop offset="52%" stopColor="#211810" />
          <stop offset="100%" stopColor="#161009" />
        </linearGradient>
        <radialGradient id={`fsg${id}`} cx="50%" cy="34%" r="70%">
          <stop offset="0%" stopColor={ring} stopOpacity="0.28" />
          <stop offset="70%" stopColor={ring} stopOpacity="0" />
        </radialGradient>
      </defs>
      {/* Beveled metal body */}
      <path d={oct} fill={`url(#fs${id})`} stroke={ringDim} strokeWidth="1.5" />
      {/* Inner engraved ring */}
      <path d="M17 8 L31 8 L40 17 L40 31 L31 40 L17 40 L8 31 L8 17 Z" fill="none" stroke={ring} strokeWidth="0.75" opacity="0.55" />
      {/* Top-edge highlight (struck bevel) */}
      <path d="M16 3 L32 3 L45 16" fill="none" stroke="#5A4A3C" strokeWidth="1" opacity="0.7" />
      {/* Heat glow */}
      <path d={oct} fill={`url(#fsg${id})`} />
      {/* Rivets */}
      {[[12, 12], [36, 12], [12, 36], [36, 36]].map(([cx, cy], i) => (
        <circle key={i} cx={cx} cy={cy} r="1.1" fill={ringDim} />
      ))}
      <text
        x="24"
        y="24"
        textAnchor="middle"
        dominantBaseline="central"
        fontFamily='"Chakra Petch", sans-serif'
        fontSize={label.length > 2 ? 13 : 17}
        fontWeight="800"
        fill={text}
        style={{ letterSpacing: "-0.02em" }}
      >
        {label}
      </text>
    </svg>
  );
}

/** A glowing "molten seam" — a top-edge accent that reads like a strip of cooling metal. */
export function MoltenSeam({ accent = "ember", style }: { accent?: "ember" | "steel"; style?: React.CSSProperties }) {
  const c = accent === "ember" ? "234,88,12" : "8,145,178";
  return (
    <div aria-hidden="true" style={{ position: "relative", height: 3, ...style }}>
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: `linear-gradient(90deg, transparent, rgba(${c},0.15) 8%, rgba(${c},0.85) 30%, rgba(${c},0.55) 50%, rgba(${c},0.9) 72%, rgba(${c},0.15) 92%, transparent)`,
        }}
      />
      <div
        style={{
          position: "absolute",
          inset: "-2px 0 auto 0",
          height: 8,
          filter: "blur(5px)",
          background: `linear-gradient(90deg, transparent, rgba(${c},0.5) 35%, rgba(${c},0.6) 65%, transparent)`,
        }}
      />
    </div>
  );
}

/** A thin horizontal rule with ember center glow — replaces plain dividers in key spots. */
export function ForgeDivider({ style }: { style?: React.CSSProperties }) {
  return (
    <div
      aria-hidden="true"
      style={{
        height: 1,
        background: "linear-gradient(90deg, transparent 0%, rgba(234,88,12,0.5) 40%, rgba(234,88,12,0.5) 60%, transparent 100%)",
        ...style,
      }}
    />
  );
}
