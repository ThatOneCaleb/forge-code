/** Sprocket — the square robot mascot. Two big eyes, speaker-grill mouth, ember antennas. */
export function Sprocket({
  size = 40,
  mood = "neutral",
  className,
}: {
  size?: number;
  mood?: "neutral" | "happy" | "thinking";
  className?: string;
}) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 40 40"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className={className}
    >
      {/* Body */}
      <rect x="3" y="3" width="34" height="34" rx="7" fill="#2D3139" stroke="#0891B2" strokeWidth="1.5" />

      {/* Ear nubs */}
      <rect x="1" y="14" width="2" height="7" rx="1" fill="#4A505C" />
      <rect x="37" y="14" width="2" height="7" rx="1" fill="#4A505C" />

      {/* Antenna left */}
      <rect x="12" y="0" width="2.5" height="6" rx="1.25" fill="#4A505C" />
      <circle cx="13.25" cy="0" r="2" fill="#EA580C" />

      {/* Antenna right */}
      <rect x="25.5" y="0" width="2.5" height="6" rx="1.25" fill="#4A505C" />
      <circle cx="26.75" cy="0" r="2" fill="#EA580C" />

      {/* Left eye socket */}
      <rect x="8" y="13" width="11" height="10" rx="4" fill="#E9EAEE" />
      {/* Left pupil */}
      <circle
        cx={mood === "thinking" ? 16 : 13.5}
        cy={mood === "happy" ? 20 : 18}
        r="3.5"
        fill="#1A1C21"
      />
      {/* Left glint */}
      <circle cx="10.5" cy="15" r="1.5" fill="white" />

      {/* Right eye socket */}
      <rect x="21" y="13" width="11" height="10" rx="4" fill="#E9EAEE" />
      {/* Right pupil */}
      <circle
        cx={mood === "thinking" ? 29 : 26.5}
        cy={mood === "happy" ? 20 : 18}
        r="3.5"
        fill="#1A1C21"
      />
      {/* Right glint */}
      <circle cx="23.5" cy="15" r="1.5" fill="white" />

      {/* Speaker grill — 3 horizontal slots */}
      <rect x="12" y="29" width="5" height="1.5" rx="0.75" fill="#4A505C" />
      <rect x="17.5" y="29" width="5" height="1.5" rx="0.75" fill="#4A505C" />
      <rect x="23" y="29" width="5" height="1.5" rx="0.75" fill="#4A505C" />

      {/* Status LED strip at bottom */}
      <rect x="3" y="33" width="34" height="4" rx="0" fill="#2A2F38" />
      <rect x="3" y="33" width="34" height="4" rx="0" ry="0" />
      <rect x="3" y="34" width="34" height="3" rx="0" fill="#252930" />
      <circle cx="13" cy="35.5" r="1.5" fill={mood === "happy" ? "#22C55E" : "#EA580C"} opacity="0.8" />
      <circle cx="20" cy="35.5" r="1.5" fill="#0891B2" opacity="0.6" />
      <circle cx="27" cy="35.5" r="1.5" fill={mood === "thinking" ? "#FB923C" : "#4A505C"} opacity="0.5" />
    </svg>
  );
}
