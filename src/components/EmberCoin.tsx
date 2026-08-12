import { useId } from "react";

interface EmberCoinProps {
  size?: number;
  glow?: boolean;
}

export function EmberCoin({ size = 20, glow = false }: EmberCoinProps) {
  const id = useId().replace(/:/g, "");
  return (
    <svg
      viewBox="0 0 100 100"
      width={size}
      height={size}
      style={{ flexShrink: 0, overflow: "visible" }}
      aria-hidden="true"
    >
      <defs>
        <radialGradient id={`${id}-a`} cx="40%" cy="30%" r="65%">
          <stop offset="0%" stopColor="#FDBA74" />
          <stop offset="55%" stopColor="#EA580C" />
          <stop offset="100%" stopColor="#9A3412" />
        </radialGradient>
        <radialGradient id={`${id}-b`} cx="50%" cy="50%" r="50%">
          <stop offset="0%" stopColor="#FFF7ED" stopOpacity="0.9" />
          <stop offset="100%" stopColor="#FB923C" stopOpacity="0.1" />
        </radialGradient>
        {glow && (
          <filter id={`${id}-glow`} x="-40%" y="-40%" width="180%" height="180%">
            <feGaussianBlur stdDeviation="6" result="blur" />
            <feMerge>
              <feMergeNode in="blur" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>
        )}
      </defs>

      {/* Outer ring */}
      <circle
        cx="50" cy="50" r="45"
        fill="none"
        stroke={`url(#${id}-a)`}
        strokeWidth="4"
        opacity="0.45"
        filter={glow ? `url(#${id}-glow)` : undefined}
      />

      {/* Mid ring */}
      <circle
        cx="50" cy="50" r="32"
        fill="none"
        stroke={`url(#${id}-a)`}
        strokeWidth="3.5"
        opacity="0.75"
      />

      {/* Inner fill */}
      <circle
        cx="50" cy="50" r="18"
        fill={`url(#${id}-a)`}
      />

      {/* Highlight specular */}
      <circle
        cx="43" cy="40" r="7"
        fill={`url(#${id}-b)`}
        opacity="0.6"
      />
    </svg>
  );
}
