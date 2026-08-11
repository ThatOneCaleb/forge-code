const E = "#EA580C"; // ember
const EB = "#FB923C"; // ember-bright
const S = "#0891B2"; // steel
const SD = "#38BDF8"; // steel-dim
const G = "#22C55E"; // success
const T = "#E9EAEE"; // text
const D = "#98A0AD"; // dim
const P = "#333740"; // panel
const P2 = "#3E434E"; // panel-2
const B = "#4A505C"; // border

function Art({ children, bg = P }: { children: React.ReactNode; bg?: string }) {
  return (
    <svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg" style={{ display: "block" }}>
      <rect width="48" height="48" rx="8" fill={bg} />
      {children}
    </svg>
  );
}

// ── ACADEMY ────────────────────────────────────────────────────────────────────

const HELLO_FORGE = () => (
  <Art>
    {/* door frame */}
    <rect x="13" y="10" width="22" height="30" rx="2" fill={P2} stroke={B} strokeWidth="1.2" />
    <rect x="16" y="13" width="16" height="27" rx="1" fill={S} opacity="0.18" />
    {/* door open (right leaf) */}
    <rect x="25" y="13" width="8" height="24" rx="1" fill={SD} opacity="0.7" />
    {/* speech bubble */}
    <rect x="6" y="6" width="16" height="11" rx="4" fill={E} />
    <polygon points="14,17 18,17 16,21" fill={E} />
    <text x="14" y="15" fontFamily="monospace" fontSize="7" fill={T} textAnchor="middle">Hi!</text>
  </Art>
);

const SUM_TWO = () => (
  <Art>
    {/* block A */}
    <rect x="5" y="18" width="12" height="12" rx="2" fill={S} opacity="0.8" />
    <text x="11" y="27.5" fontFamily="monospace" fontSize="8" fill={T} textAnchor="middle" fontWeight="bold">2</text>
    {/* plus */}
    <text x="24" y="27.5" fontFamily="monospace" fontSize="10" fill={D} textAnchor="middle">+</text>
    {/* block B */}
    <rect x="31" y="18" width="12" height="12" rx="2" fill={S} opacity="0.8" />
    <text x="37" y="27.5" fontFamily="monospace" fontSize="8" fill={T} textAnchor="middle" fontWeight="bold">3</text>
    {/* result */}
    <rect x="14" y="34" width="20" height="10" rx="2" fill={E} />
    <text x="24" y="41.5" fontFamily="monospace" fontSize="8" fill={T} textAnchor="middle" fontWeight="bold">= 5</text>
    {/* arrow down */}
    <line x1="24" y1="31" x2="24" y2="34" stroke={D} strokeWidth="1.2" />
  </Art>
);

const EVEN_ODD = () => (
  <Art>
    {[0,1,2,3,4,5].map((i) => (
      <rect key={i} x={6 + i * 6.5} y="19" width="5" height="10" rx="1.5"
        fill={i % 2 === 0 ? S : E} opacity={i % 2 === 0 ? 0.8 : 0.8} />
    ))}
    <text x="8" y="38" fontFamily="monospace" fontSize="6" fill={SD}>E</text>
    <text x="14.5" y="38" fontFamily="monospace" fontSize="6" fill={E}>O</text>
    <text x="21" y="38" fontFamily="monospace" fontSize="6" fill={SD}>E</text>
    <text x="27.5" y="38" fontFamily="monospace" fontSize="6" fill={E}>O</text>
    <text x="34" y="38" fontFamily="monospace" fontSize="6" fill={SD}>E</text>
    <text x="40.5" y="38" fontFamily="monospace" fontSize="6" fill={E}>O</text>
  </Art>
);

const ABS_DIFF = () => (
  <Art>
    {/* number line */}
    <line x1="8" y1="28" x2="40" y2="28" stroke={B} strokeWidth="1.5" />
    {/* ticks */}
    {[8,16,24,32,40].map((x,i) => (
      <line key={i} x1={x} y1="25" x2={x} y2="31" stroke={D} strokeWidth="1" />
    ))}
    {/* two points */}
    <circle cx="12" cy="28" r="3.5" fill={S} />
    <circle cx="36" cy="28" r="3.5" fill={E} />
    {/* bracket showing distance */}
    <path d="M12 20 L12 17 L36 17 L36 20" stroke={G} strokeWidth="1.5" fill="none" />
    <text x="24" y="14" fontFamily="monospace" fontSize="6" fill={G} textAnchor="middle">|diff|</text>
    <text x="10" y="39" fontFamily="monospace" fontSize="6" fill={SD}>3</text>
    <text x="34" y="39" fontFamily="monospace" fontSize="6" fill={EB}>10</text>
  </Art>
);

const SHOUT = () => (
  <Art>
    {/* megaphone body */}
    <polygon points="8,20 8,28 18,32 18,16" fill={E} opacity="0.9" />
    {/* horn flare */}
    <polygon points="18,16 18,32 30,38 30,10" fill={EB} opacity="0.7" />
    {/* sound waves */}
    <path d="M32 20 Q38 24 32 28" stroke={T} strokeWidth="1.5" fill="none" strokeLinecap="round" />
    <path d="M34 16 Q42 24 34 32" stroke={T} strokeWidth="1.2" fill="none" strokeLinecap="round" opacity="0.5" />
    {/* small text in */}
    <text x="6" y="22" fontFamily="monospace" fontSize="4.5" fill={D}>abc</text>
    {/* big text out */}
    <text x="33" y="14" fontFamily="monospace" fontSize="5.5" fill={T} fontWeight="bold">ABC</text>
  </Art>
);

const REVERSE = () => (
  <Art>
    {/* forward text */}
    <text x="24" y="20" fontFamily="monospace" fontSize="9" fill={SD} textAnchor="middle">ABC</text>
    {/* curved arrow */}
    <path d="M10 26 Q24 40 38 26" stroke={E} strokeWidth="1.8" fill="none" strokeLinecap="round" />
    <polygon points="9,24 7,30 14,28" fill={E} />
    {/* reversed text */}
    <text x="24" y="38" fontFamily="monospace" fontSize="9" fill={T} textAnchor="middle">CBA</text>
  </Art>
);

const SUM_TO_N = () => (
  <Art>
    {/* staircase of blocks */}
    {[4,3,2,1].map((h, i) => (
      <rect key={i} x={10 + i * 8} y={36 - h * 7} width="7" height={h * 7}
        rx="1" fill={i === 3 ? E : S} opacity={0.5 + i * 0.15} />
    ))}
    {/* sum label */}
    <text x="24" y="10" fontFamily="monospace" fontSize="6" fill={G} textAnchor="middle">1+2+3+4</text>
    <text x="24" y="18" fontFamily="monospace" fontSize="7" fill={T} textAnchor="middle" fontWeight="bold">= 10</text>
  </Art>
);

const COUNT_DOWN = () => (
  <Art>
    {["5","4","3","2","1"].map((n, i) => (
      <text key={n} x={9 + i * 8} y="30" fontFamily="monospace" fontSize={14 - i * 1.5}
        fill={i === 4 ? E : SD} textAnchor="middle" fontWeight="bold" opacity={0.4 + i * 0.15}>{n}</text>
    ))}
    <path d="M24 33 L24 40 L20 37" stroke={E} strokeWidth="1.5" strokeLinecap="round" fill="none" />
    <path d="M24 40 L28 37" stroke={E} strokeWidth="1.5" strokeLinecap="round" />
  </Art>
);

const FACTORIAL = () => (
  <Art>
    <text x="24" y="14" fontFamily="monospace" fontSize="9" fill={T} textAnchor="middle" fontWeight="bold">4!</text>
    <line x1="24" y1="16" x2="24" y2="21" stroke={D} strokeWidth="1" />
    {/* cascade */}
    {["4×3","×2","×1"].map((s, i) => (
      <text key={i} x="24" y={25 + i * 8} fontFamily="monospace" fontSize="7"
        fill={i === 2 ? E : SD} textAnchor="middle">{s}</text>
    ))}
    <line x1="14" y1="42" x2="34" y2="42" stroke={B} strokeWidth="1" />
    <text x="24" y="48" fontFamily="monospace" fontSize="7" fill={G} textAnchor="middle">24</text>
  </Art>
);

const FIZZBUZZ = () => (
  <Art>
    {Array.from({length:15}, (_,i) => {
      const col = i % 5; const row = Math.floor(i/5);
      const isFizz = (i+1) % 3 === 0;
      const isBuzz = (i+1) % 5 === 0;
      return (
        <rect key={i} x={8 + col*7} y={10 + row*10} width="6" height="8" rx="1"
          fill={isFizz && isBuzz ? G : isFizz ? E : isBuzz ? S : P2}
          opacity={isFizz || isBuzz ? 0.9 : 0.4} />
      );
    })}
    <text x="24" y="44" fontFamily="monospace" fontSize="5" fill={D} textAnchor="middle">Fizz · Buzz · Both</text>
  </Art>
);

const COUNT_VOWELS = () => (
  <Art>
    {"FORGE".split("").map((ch, i) => {
      const isVowel = "AEIOU".includes(ch);
      return (
        <g key={i}>
          <rect x={5 + i * 8} y="17" width="7" height="14" rx="1.5"
            fill={isVowel ? E : P2} opacity={isVowel ? 0.9 : 0.5} />
          <text x={8.5 + i * 8} y="27.5" fontFamily="monospace" fontSize="6"
            fill={isVowel ? T : D} textAnchor="middle" fontWeight={isVowel ? "bold" : "normal"}>{ch}</text>
        </g>
      );
    })}
    <text x="24" y="40" fontFamily="monospace" fontSize="6" fill={G} textAnchor="middle">vowels: 2</text>
  </Art>
);

const COUNT_WORDS = () => (
  <Art>
    <rect x="5" y="15" width="16" height="11" rx="2" fill={S} opacity="0.7" />
    <text x="13" y="23" fontFamily="monospace" fontSize="6" fill={T} textAnchor="middle">Hello</text>
    <rect x="27" y="15" width="16" height="11" rx="2" fill={S} opacity="0.7" />
    <text x="35" y="23" fontFamily="monospace" fontSize="6" fill={T} textAnchor="middle">World</text>
    {/* gap indicator */}
    <line x1="22" y1="20" x2="26" y2="20" stroke={D} strokeWidth="1" strokeDasharray="1 1" />
    <text x="24" y="36" fontFamily="monospace" fontSize="7" fill={E} textAnchor="middle" fontWeight="bold">2 words</text>
  </Art>
);

const MAX_OF_LIST = () => (
  <Art>
    {[6,12,8,18,5,10].map((h, i) => (
      <rect key={i} x={6 + i * 6.5} y={38 - h * 1.6} width="5" height={h * 1.6}
        rx="1" fill={h === 18 ? E : S} opacity={h === 18 ? 1 : 0.45} />
    ))}
    {/* crown on max */}
    <polygon points="29,10 31,6 33,10" fill={EB} />
    <text x="24" y="44" fontFamily="monospace" fontSize="5.5" fill={EB} textAnchor="middle">max = 18</text>
  </Art>
);

const UNIQUE_COUNT = () => (
  <Art>
    {/* repeated items */}
    {[S,S,E,S,E,E,G].map((c, i) => (
      <circle key={i} cx={8 + i * 5.5} cy={c === G ? 20 : 24} r="4"
        fill={c} opacity={c === G ? 1 : 0.4}
        stroke={c === G ? T : "none"} strokeWidth="1" />
    ))}
    <text x="24" y="36" fontFamily="monospace" fontSize="5.5" fill={D} textAnchor="middle">duplicates fade</text>
    <text x="24" y="43" fontFamily="monospace" fontSize="6" fill={G} textAnchor="middle" fontWeight="bold">unique: 3</text>
  </Art>
);

// ── GAUNTLET ───────────────────────────────────────────────────────────────────

const IS_PRIME = () => (
  <Art>
    <circle cx="24" cy="22" r="12" fill={E} opacity="0.15" stroke={E} strokeWidth="1.5" />
    <text x="24" y="27" fontFamily="monospace" fontSize="13" fill={E} textAnchor="middle" fontWeight="bold">7</text>
    {/* failed division lines */}
    <line x1="8" y1="8" x2="18" y2="18" stroke={D} strokeWidth="1" opacity="0.4" />
    <line x1="40" y1="8" x2="30" y2="18" stroke={D} strokeWidth="1" opacity="0.4" />
    <line x1="8" y1="36" x2="18" y2="26" stroke={D} strokeWidth="1" opacity="0.4" />
    <text x="6" y="12" fontFamily="monospace" fontSize="5" fill={D} opacity="0.6">÷2</text>
    <text x="34" y="12" fontFamily="monospace" fontSize="5" fill={D} opacity="0.6">÷3</text>
    <text x="6" y="40" fontFamily="monospace" fontSize="5" fill={D} opacity="0.6">÷5</text>
    <text x="24" y="42" fontFamily="monospace" fontSize="6" fill={G} textAnchor="middle">prime ✓</text>
  </Art>
);

const GCD = () => (
  <Art>
    <rect x="5" y="14" width="20" height="8" rx="2" fill={S} opacity="0.6" />
    <text x="15" y="20.5" fontFamily="monospace" fontSize="6" fill={T} textAnchor="middle">12</text>
    <rect x="5" y="26" width="14" height="8" rx="2" fill={SD} opacity="0.6" />
    <text x="12" y="32.5" fontFamily="monospace" fontSize="6" fill={T} textAnchor="middle">8</text>
    {/* shared segment highlight */}
    <rect x="5" y="14" width="14" height="20" rx="2" fill={E} opacity="0.25" stroke={E} strokeWidth="1" />
    <text x="12" y="22" fontFamily="monospace" fontSize="5" fill={EB} textAnchor="middle">GCD</text>
    <text x="30" y="25" fontFamily="monospace" fontSize="10" fill={T} fontWeight="bold">= 4</text>
  </Art>
);

const FIBONACCI = () => (
  <Art>
    {/* fibonacci squares — simplified */}
    <rect x="22" y="22" width="4" height="4" rx="0.5" fill={E} opacity="0.9" />
    <rect x="18" y="22" width="4" height="4" rx="0.5" fill={EB} opacity="0.8" />
    <rect x="14" y="18" width="8" height="8" rx="1" fill={S} opacity="0.7" />
    <rect x="6" y="10" width="16" height="16" rx="1.5" fill={SD} opacity="0.5" />
    {/* spiral arc */}
    <path d="M22 26 Q22 22 18 22 Q14 22 14 18 Q14 10 6 10" stroke={G} strokeWidth="1.5" fill="none" strokeLinecap="round" />
    <text x="36" y="28" fontFamily="monospace" fontSize="7" fill={D}>1,1</text>
    <text x="33" y="36" fontFamily="monospace" fontSize="7" fill={E}>2,3</text>
    <text x="30" y="44" fontFamily="monospace" fontSize="7" fill={EB}>5…</text>
  </Art>
);

const MOST_COMMON = () => (
  <Art>
    {[4,7,3,14,5,2].map((h, i) => (
      <rect key={i} x={5 + i * 6.5} y={38 - h * 1.8} width="5" height={h * 1.8}
        rx="1" fill={h === 14 ? E : S} opacity={h === 14 ? 1 : 0.35} />
    ))}
    <polygon points="32,8 34,4 36,8" fill={EB} />
    <text x="33" y="3" fontFamily="monospace" fontSize="5" fill={EB} textAnchor="middle">★</text>
    <text x="24" y="45" fontFamily="monospace" fontSize="5.5" fill={E} textAnchor="middle">most common</text>
  </Art>
);

const SORT_DESC = () => (
  <Art>
    {[18,14,10,6,3].map((h, i) => (
      <rect key={i} x={7 + i * 7} y={38 - h * 1.7} width="6" height={h * 1.7}
        rx="1" fill={S} opacity={0.4 + (4 - i) * 0.12} />
    ))}
    <path d="M10 10 L38 28" stroke={E} strokeWidth="1.5" strokeDasharray="2 2" />
    <polygon points="38,24 40,30 34,29" fill={E} />
    <text x="24" y="45" fontFamily="monospace" fontSize="5.5" fill={SD} textAnchor="middle">descending</text>
  </Art>
);

const POWER_RECURSION = () => (
  <Art>
    <text x="24" y="13" fontFamily="monospace" fontSize="9" fill={E} textAnchor="middle" fontWeight="bold">2⁴</text>
    <line x1="24" y1="15" x2="16" y2="22" stroke={D} strokeWidth="1" />
    <line x1="24" y1="15" x2="32" y2="22" stroke={D} strokeWidth="1" />
    <text x="13" y="28" fontFamily="monospace" fontSize="7" fill={SD} textAnchor="middle">2³</text>
    <text x="35" y="28" fontFamily="monospace" fontSize="7" fill={SD} textAnchor="middle">×2</text>
    <line x1="13" y1="30" x2="8" y2="37" stroke={D} strokeWidth="1" opacity="0.5" />
    <line x1="13" y1="30" x2="18" y2="37" stroke={D} strokeWidth="1" opacity="0.5" />
    <text x="8" y="43" fontFamily="monospace" fontSize="6" fill={B} textAnchor="middle">2²</text>
    <text x="18" y="43" fontFamily="monospace" fontSize="6" fill={B} textAnchor="middle">×2</text>
    <text x="40" y="43" fontFamily="monospace" fontSize="7" fill={G}>16</text>
  </Art>
);

const BINARY_TO_DECIMAL = () => (
  <Art>
    {"1010".split("").map((bit, i) => (
      <rect key={i} x={5 + i * 9} y="12" width="8" height="14" rx="2"
        fill={bit === "1" ? E : P2} opacity={bit === "1" ? 0.9 : 0.4} />
    ))}
    {"1010".split("").map((bit, i) => (
      <text key={i} x={9 + i * 9} y="22.5" fontFamily="monospace" fontSize="7"
        fill={bit === "1" ? T : D} textAnchor="middle" fontWeight="bold">{bit}</text>
    ))}
    <path d="M24 27 L24 32" stroke={D} strokeWidth="1.2" />
    <polygon points="20,31 24,36 28,31" fill={D} />
    <text x="24" y="44" fontFamily="monospace" fontSize="10" fill={G} textAnchor="middle" fontWeight="bold">10</text>
  </Art>
);

const GRID_COUNT = () => (
  <Art>
    {Array.from({length:16}, (_,i) => {
      const filled = [1,3,5,6,9,12,14].includes(i);
      return (
        <rect key={i} x={9 + (i%4)*8} y={9 + Math.floor(i/4)*8} width="7" height="7" rx="1.5"
          fill={filled ? S : P2} opacity={filled ? 0.8 : 0.3} />
      );
    })}
    <text x="24" y="45" fontFamily="monospace" fontSize="6" fill={SD} textAnchor="middle">count: 7</text>
  </Art>
);

const CALORIE_GROUPS = () => (
  <Art>
    {/* three groups of dots */}
    {[[3,E],[5,S],[2,EB]].map(([count, color], gi) => {
      const n = count as number;
      const c = color as string;
      return Array.from({length: n}, (_, j) => (
        <circle key={`${gi}-${j}`} cx={8 + gi * 15 + (j % 2) * 5} cy={14 + Math.floor(j/2) * 6}
          r="2.5" fill={c} opacity="0.7" />
      ));
    })}
    {/* dividers */}
    <line x1="19" y1="9" x2="19" y2="37" stroke={B} strokeWidth="1" strokeDasharray="2 2" />
    <line x1="34" y1="9" x2="34" y2="37" stroke={B} strokeWidth="1" strokeDasharray="2 2" />
    <text x="24" y="44" fontFamily="monospace" fontSize="5.5" fill={E} textAnchor="middle">max group total</text>
  </Art>
);

const PAIR_SUMS = () => (
  <Art>
    <circle cx="12" cy="28" r="6" fill={S} opacity="0.8" />
    <text x="12" y="30.5" fontFamily="monospace" fontSize="7" fill={T} textAnchor="middle">7</text>
    <circle cx="36" cy="28" r="6" fill={SD} opacity="0.8" />
    <text x="36" y="30.5" fontFamily="monospace" fontSize="7" fill={T} textAnchor="middle">3</text>
    <path d="M18 24 Q24 12 30 24" stroke={E} strokeWidth="1.5" fill="none" />
    <text x="24" y="14" fontFamily="monospace" fontSize="6" fill={E} textAnchor="middle">= 10</text>
    <text x="24" y="42" fontFamily="monospace" fontSize="5.5" fill={D} textAnchor="middle">target: 10</text>
  </Art>
);

const RUCKSACK = () => (
  <Art>
    {/* bag outline */}
    <rect x="6" y="14" width="36" height="26" rx="4" fill={P2} stroke={B} strokeWidth="1.2" />
    {/* strap */}
    <path d="M16 14 Q24 6 32 14" stroke={B} strokeWidth="2" fill="none" />
    {/* divider */}
    <line x1="24" y1="14" x2="24" y2="40" stroke={E} strokeWidth="1.5" strokeDasharray="2 1" />
    {/* left items */}
    {[S,SD,S].map((c,i) => <circle key={i} cx={13} cy={20+i*6} r="2.5" fill={c} opacity="0.7" />)}
    {/* right items */}
    {[SD,E,SD].map((c,i) => <circle key={i} cx={35} cy={20+i*6} r="2.5" fill={c} opacity="0.7" />)}
    {/* common item */}
    <circle cx="24" cy="27" r="4" fill={E} stroke={T} strokeWidth="1" />
  </Art>
);

const RPS_SCORE = () => (
  <Art>
    {/* R */}
    <circle cx="12" cy="24" r="9" fill={P2} stroke={S} strokeWidth="1.2" />
    <text x="12" y="28" fontFamily="monospace" fontSize="9" fill={S} textAnchor="middle">✊</text>
    {/* P */}
    <circle cx="24" cy="24" r="9" fill={P2} stroke={D} strokeWidth="1.2" />
    <text x="24" y="28" fontFamily="monospace" fontSize="9" fill={D} textAnchor="middle">✋</text>
    {/* S */}
    <circle cx="36" cy="24" r="9" fill={P2} stroke={E} strokeWidth="1.2" />
    <text x="36" y="28" fontFamily="monospace" fontSize="9" fill={E} textAnchor="middle">✌</text>
  </Art>
);

const CAESAR_DECODE = () => (
  <Art>
    {/* cipher wheel */}
    <circle cx="24" cy="24" r="16" fill={P2} stroke={B} strokeWidth="1.2" />
    <circle cx="24" cy="24" r="10" fill={P} stroke={E} strokeWidth="1" />
    {/* letters around outer */}
    {["A","D","G","J","M","P"].map((ch, i) => {
      const angle = (i / 6) * Math.PI * 2 - Math.PI / 2;
      return <text key={i} x={24 + 13 * Math.cos(angle)} y={24.5 + 13 * Math.sin(angle)}
        fontFamily="monospace" fontSize="5" fill={D} textAnchor="middle">{ch}</text>;
    })}
    {/* inner shifted */}
    {["X","A","D","G","J","M"].map((ch, i) => {
      const angle = (i / 6) * Math.PI * 2 - Math.PI / 2;
      return <text key={i} x={24 + 7.5 * Math.cos(angle)} y={24.5 + 7.5 * Math.sin(angle)}
        fontFamily="monospace" fontSize="5" fill={E} textAnchor="middle">{ch}</text>;
    })}
    {/* rotation arrow */}
    <path d="M34 16 Q42 24 34 32" stroke={EB} strokeWidth="1.5" fill="none" strokeLinecap="round" />
    <polygon points="34,30 38,34 30,33" fill={EB} />
  </Art>
);

const BALANCED_BRACKETS = () => (
  <Art>
    {[
      {ch:"{", x:5, y:18, c:E},
      {ch:"[", x:12, y:22, c:S},
      {ch:"(", x:19, y:26, c:SD},
      {ch:")", x:26, y:26, c:SD},
      {ch:"]", x:33, y:22, c:S},
      {ch:"}", x:40, y:18, c:E},
    ].map(({ch,x,y,c}) => (
      <text key={ch+x} x={x} y={y} fontFamily="monospace" fontSize="11" fill={c} fontWeight="bold">{ch}</text>
    ))}
    <path d="M7 20 Q24 38 41 20" stroke={G} strokeWidth="1" fill="none" opacity="0.5" />
    <text x="24" y="44" fontFamily="monospace" fontSize="6" fill={G} textAnchor="middle">balanced ✓</text>
  </Art>
);

const RUN_LENGTH = () => (
  <Art>
    {/* encoded */}
    <text x="24" y="16" fontFamily="monospace" fontSize="7" fill={E} textAnchor="middle">3A 2B 1C</text>
    <path d="M24 19 L24 24" stroke={D} strokeWidth="1.2" />
    <polygon points="20,23 24,28 28,23" fill={D} />
    {/* decoded */}
    {"AAABBC".split("").map((ch,i) => (
      <rect key={i} x={6+i*6} y="29" width="5" height="9" rx="1"
        fill={ch==="A"?E:ch==="B"?S:G} opacity="0.8" />
    ))}
    {"AAABBC".split("").map((ch,i) => (
      <text key={i} x={8.5+i*6} y="36.5" fontFamily="monospace" fontSize="5.5" fill={T} textAnchor="middle">{ch}</text>
    ))}
  </Art>
);

const COUNT_REGIONS = () => (
  <Art>
    {/* small grid with flood-fill regions */}
    {[
      [E,E,P2,S,S],
      [E,P2,P2,S,P2],
      [P2,P2,G,G,G],
      [SD,P2,G,P2,P2],
    ].map((row, ri) =>
      row.map((c, ci) => (
        <rect key={`${ri}-${ci}`} x={6+ci*7.5} y={7+ri*8} width="6.5" height="7"
          rx="1" fill={c} opacity={c===P2?0.25:0.7} />
      ))
    )}
    <text x="24" y="44" fontFamily="monospace" fontSize="6" fill={D} textAnchor="middle">4 regions</text>
  </Art>
);

const TINY_VM = () => (
  <Art>
    {/* chip */}
    <rect x="12" y="12" width="24" height="24" rx="3" fill={P2} stroke={S} strokeWidth="1.5" />
    {/* pins */}
    {[16,22,28].map(y => <line key={y} x1="6" y1={y} x2="12" y2={y} stroke={S} strokeWidth="1.2" />)}
    {[16,22,28].map(y => <line key={y} x1="36" y1={y} x2="42" y2={y} stroke={S} strokeWidth="1.2" />)}
    {/* register label */}
    <text x="24" y="22" fontFamily="monospace" fontSize="5.5" fill={D} textAnchor="middle">acc</text>
    <rect x="17" y="24" width="14" height="6" rx="1" fill={P} stroke={E} strokeWidth="0.8" />
    <text x="24" y="29" fontFamily="monospace" fontSize="5.5" fill={E} textAnchor="middle">42</text>
  </Art>
);

const MAZE_PATH = () => (
  <Art>
    {/* maze walls as rects */}
    {[
      {x:6,y:6,w:36,h:3},{x:6,y:6,w:3,h:36},{x:6,y:39,w:36,h:3},{x:39,y:6,w:3,h:21},
      {x:14,y:14,w:3,h:16},{x:14,y:14,w:16,h:3},{x:22,y:22,w:14,h:3},{x:30,y:22,w:3,h:10},
    ].map((r,i) => (
      <rect key={i} x={r.x} y={r.y} width={r.w} height={r.h} fill={B} />
    ))}
    {/* path */}
    <path d="M9 24 L9 30 L22 30 L22 36 L30 36 L30 33 L36 33" stroke={E} strokeWidth="2"
      strokeLinecap="round" strokeLinejoin="round" fill="none" />
    <circle cx="9" cy="24" r="2.5" fill={G} />
    <text x="37" y="34" fontFamily="monospace" fontSize="6" fill={G}>E</text>
  </Art>
);

const REACTOR_CYCLES = () => (
  <Art>
    {/* frequency wave */}
    <path d="M5 24 Q10 14 15 24 Q20 34 25 24 Q30 14 35 24 Q40 34 43 24"
      stroke={E} strokeWidth="2" fill="none" strokeLinecap="round" />
    <line x1="5" y1="24" x2="43" y2="24" stroke={B} strokeWidth="1" />
    {/* repeat markers */}
    {[15,25,35].map(x => (
      <circle key={x} cx={x} cy="24" r="2.5" fill={S} />
    ))}
    <text x="24" y="42" fontFamily="monospace" fontSize="5.5" fill={SD} textAnchor="middle">first repeat</text>
    <circle cx="25" cy="24" r="4" fill="none" stroke={G} strokeWidth="1.5" />
  </Art>
);

const FLOOD_BARRIERS = () => (
  <Art>
    {/* bars of different heights */}
    {[10,6,14,4,12,8].map((h,i) => (
      <rect key={i} x={5+i*6.5} y={40-h*2} width="5.5" height={h*2} rx="1"
        fill={S} opacity="0.7" />
    ))}
    {/* water fill level */}
    <rect x="5" y="22" width="38" height="18" fill={SD} opacity="0.2" />
    <line x1="5" y1="22" x2="43" y2="22" stroke={SD} strokeWidth="1.5" strokeDasharray="3 2" />
    <text x="24" y="12" fontFamily="monospace" fontSize="5.5" fill={SD} textAnchor="middle">water: 8 units</text>
  </Art>
);

const SEALED_VAULT = () => (
  <Art>
    {/* vault door */}
    <rect x="8" y="8" width="32" height="32" rx="4" fill={P2} stroke={S} strokeWidth="2" />
    {/* dial */}
    <circle cx="24" cy="24" r="10" fill={P} stroke={E} strokeWidth="1.5" />
    {/* notches */}
    {Array.from({length:10},(_,i) => {
      const a = (i/10)*Math.PI*2; const r=8;
      return <line key={i} x1={24+r*Math.cos(a)} y1={24+r*Math.sin(a)}
        x2={24+10*Math.cos(a)} y2={24+10*Math.sin(a)} stroke={B} strokeWidth="1" />;
    })}
    {/* pointer */}
    <line x1="24" y1="24" x2="24" y2="15" stroke={E} strokeWidth="2" strokeLinecap="round" />
    <circle cx="24" cy="24" r="2" fill={E} />
  </Art>
);

const BIT_DIAGNOSTIC = () => (
  <Art>
    {[
      "01001001",
      "11010010",
      "00110101",
    ].map((row, ri) =>
      row.split("").map((bit, ci) => (
        <text key={`${ri}-${ci}`} x={6+ci*5} y={14+ri*10}
          fontFamily="monospace" fontSize="6"
          fill={bit==="1"?(ri===0?E:ri===1?S:EB):D}
          opacity={bit==="1"?0.9:0.3}>{bit}</text>
      ))
    )}
    <line x1="5" y1="38" x2="43" y2="38" stroke={B} strokeWidth="1" />
    <text x="24" y="45" fontFamily="monospace" fontSize="5.5" fill={G} textAnchor="middle">gamma · epsilon</text>
  </Art>
);

const CRAB_ALIGN = () => (
  <Art>
    {/* number line */}
    <line x1="6" y1="30" x2="42" y2="30" stroke={B} strokeWidth="1.5" />
    {/* crabs at positions */}
    {[8,10,16,28,35].map((x,i) => (
      <circle key={i} cx={x} cy="30" r="3.5" fill={S} opacity="0.7" />
    ))}
    {/* optimal position */}
    <line x1="18" y1="10" x2="18" y2="38" stroke={E} strokeWidth="1.5" strokeDasharray="2 2" />
    {/* arrows converging */}
    {[[8,18],[10,18],[28,18],[35,18]].map(([from,to],i) => (
      <path key={i} d={`M${from} 22 L${to} 22`} stroke={EB} strokeWidth="1"
        markerEnd="url(#arr)" opacity="0.6" />
    ))}
    <text x="18" y="44" fontFamily="monospace" fontSize="5.5" fill={E} textAnchor="middle">align</text>
  </Art>
);

const AGE_BUCKETS = () => (
  <Art>
    {[5,8,12,9,6,3].map((h,i) => (
      <rect key={i} x={5+i*6.5} y={38-h*2.5} width="5.5" height={h*2.5}
        rx="1" fill={i===2?E:SD} opacity={i===2?0.9:0.5} />
    ))}
    {/* x-axis labels */}
    {["<20","20s","30s","40s","50s","60+"].map((l,i) => (
      <text key={i} x={7.5+i*6.5} y="45" fontFamily="monospace" fontSize="3.5" fill={D} textAnchor="middle">{l}</text>
    ))}
    <line x1="5" y1="38" x2="43" y2="38" stroke={B} strokeWidth="1" />
  </Art>
);

const FOUNDERS_LOTTERY = () => (
  <Art>
    {/* lottery balls */}
    {[[12,16,E],[24,16,S],[36,16,SD],[12,30,EB],[24,30,G],[36,30,E]].map(([cx,cy,fill],i) => (
      <g key={i}>
        <circle cx={cx as number} cy={cy as number} r="7" fill={fill as string} opacity="0.7" />
        <text x={cx as number} y={(cy as number)+3} fontFamily="monospace" fontSize="6"
          fill={T} textAnchor="middle" fontWeight="bold">{i*7+3}</text>
      </g>
    ))}
    <text x="24" y="45" fontFamily="monospace" fontSize="5.5" fill={D} textAnchor="middle">pick the winner</text>
  </Art>
);

const FOLDED_MAP = () => (
  <Art>
    {/* paper */}
    <rect x="5" y="8" width="38" height="26" rx="2" fill={P2} stroke={B} strokeWidth="1.2" />
    {/* fold lines */}
    <line x1="24" y1="8" x2="24" y2="34" stroke={E} strokeWidth="1.5" strokeDasharray="2 2" />
    {/* left half dots */}
    {[[10,16],[10,24],[18,20]].map(([x,y],i) => (
      <circle key={i} cx={x} cy={y} r="2" fill={S} opacity="0.7" />
    ))}
    {/* right half dots (mirrored) */}
    {[[38,16],[38,24],[30,20]].map(([x,y],i) => (
      <circle key={i} cx={x} cy={y} r="2" fill={E} opacity="0.7" />
    ))}
    {/* overlap highlight */}
    <rect x="5" y="8" width="19" height="26" fill={EB} opacity="0.12" />
    <text x="24" y="42" fontFamily="monospace" fontSize="5.5" fill={E} textAnchor="middle">fold → overlap</text>
  </Art>
);

const BROKEN_CIPHER = () => (
  <Art>
    {/* garbled characters */}
    {"#@&%!?".split("").map((ch,i) => (
      <text key={i} x={7+i*7} y="22" fontFamily="monospace" fontSize="8" fill={B}>{ch}</text>
    ))}
    {/* decode arrow */}
    <path d="M24 25 L24 30" stroke={E} strokeWidth="1.2" />
    <polygon points="20,29 24,34 28,29" fill={E} />
    {/* decoded */}
    {"FORGE!".split("").map((ch,i) => (
      <text key={i} x={7+i*7} y="43" fontFamily="monospace" fontSize="8"
        fill={i===5?E:T} fontWeight="bold">{ch}</text>
    ))}
  </Art>
);

const CORE_REBOOT = () => (
  <Art>
    <circle cx="24" cy="22" r="14" fill={P2} stroke={E} strokeWidth="1.5" />
    {/* power symbol */}
    <path d="M20 12 Q24 8 28 12" stroke={E} strokeWidth="2" fill="none" strokeLinecap="round" />
    <line x1="24" y1="10" x2="24" y2="18" stroke={E} strokeWidth="2" strokeLinecap="round" />
    {/* spinning arc */}
    <path d="M14 22 Q14 30 22 32 Q30 34 34 27" stroke={EB} strokeWidth="1.5"
      fill="none" strokeLinecap="round" strokeDasharray="3 2" />
    <polygon points="34,24 36,30 30,28" fill={EB} />
    {/* sparks */}
    <circle cx="12" cy="14" r="1.5" fill={E} opacity="0.8" />
    <circle cx="36" cy="14" r="1.5" fill={E} opacity="0.8" />
    <text x="24" y="42" fontFamily="monospace" fontSize="5.5" fill={SD} textAnchor="middle">rebooting…</text>
  </Art>
);

const ROOT_TUNNELS = () => (
  <Art>
    {/* tree nodes */}
    <circle cx="24" cy="8" r="5" fill={E} opacity="0.8" />
    <line x1="24" y1="13" x2="14" y2="22" stroke={D} strokeWidth="1.2" />
    <line x1="24" y1="13" x2="34" y2="22" stroke={D} strokeWidth="1.2" />
    <circle cx="14" cy="25" r="4" fill={S} opacity="0.7" />
    <circle cx="34" cy="25" r="4" fill={S} opacity="0.7" />
    <line x1="14" y1="29" x2="9" y2="37" stroke={D} strokeWidth="1.2" />
    <line x1="14" y1="29" x2="19" y2="37" stroke={D} strokeWidth="1.2" />
    <line x1="34" y1="29" x2="29" y2="37" stroke={D} strokeWidth="1.2" />
    <line x1="34" y1="29" x2="39" y2="37" stroke={D} strokeWidth="1.2" />
    {/* highlighted tunnel path */}
    <circle cx="9" cy="40" r="3" fill={G} />
    <path d="M24 13 L14 22 L9 37" stroke={G} strokeWidth="1.5" fill="none" strokeLinecap="round" />
  </Art>
);

const UNDER_THE_TREES = () => (
  <Art>
    {/* grid */}
    {Array.from({length:20},(_,i) => (
      <rect key={i} x={6+(i%5)*7.5} y={6+Math.floor(i/5)*7.5} width="6.5" height="6.5"
        rx="1" fill={P2} stroke={B} strokeWidth="0.5" />
    ))}
    {/* L-piece */}
    {[[0,0],[0,1],[1,1]].map(([r,c],i) => (
      <rect key={i} x={6+c*7.5} y={6+r*7.5} width="6.5" height="6.5" rx="1" fill={E} opacity="0.8" />
    ))}
    {/* S-piece */}
    {[[1,2],[1,3],[2,3],[2,4]].map(([r,c],i) => (
      <rect key={i} x={6+c*7.5} y={6+r*7.5} width="6.5" height="6.5" rx="1" fill={S} opacity="0.8" />
    ))}
    <text x="24" y="46" fontFamily="monospace" fontSize="5.5" fill={G} textAnchor="middle">pack them all</text>
  </Art>
);

const HAZARD_DESCENT = () => (
  <Art>
    {/* grid with values */}
    {[[8,3,5,4],[3,7,1,9],[2,4,6,2],[5,1,3,8]].map((row,ri) =>
      row.map((v,ci) => (
        <rect key={`${ri}-${ci}`} x={6+ci*9} y={5+ri*9} width="8" height="8" rx="1"
          fill={v>6?E:v<3?S:P2} opacity={v>6?0.7:v<3?0.5:0.3} />
      ))
    )}
    {/* descent path */}
    <path d="M10 9 L10 18 L19 18 L19 27 L19 36" stroke={G} strokeWidth="1.8"
      strokeLinecap="round" strokeLinejoin="round" fill="none" />
    <circle cx="10" cy="9" r="2" fill={G} />
    <text x="24" y="46" fontFamily="monospace" fontSize="5.5" fill={E} textAnchor="middle">minimize risk</text>
  </Art>
);

const INSTRUCTION_RIBBON = () => (
  <Art>
    {/* tape ribbon */}
    <rect x="4" y="18" width="40" height="12" rx="2" fill={P2} stroke={B} strokeWidth="1" />
    {/* tape holes */}
    {[7,12,17,22,27,32,37].map(x => (
      <circle key={x} cx={x} cy="24" r="1.5" fill={B} />
    ))}
    {/* instructions above tape */}
    {["nop","acc","jmp","acc","nop","jmp"].map((op,i) => (
      <text key={i} x={7+i*6.5} y="15" fontFamily="monospace" fontSize="4"
        fill={op==="jmp"?E:op==="acc"?S:D} textAnchor="middle">{op}</text>
    ))}
    {/* read head */}
    <rect x="20" y="14" width="8" height="20" rx="1" fill={E} opacity="0.2" stroke={E} strokeWidth="1" />
    <polygon points="22,34 24,38 26,34" fill={E} />
  </Art>
);

const SETTLING_LATTICE = () => (
  <Art>
    {/* lattice grid */}
    {Array.from({length:15},(_,i) => {
      const col = i % 5; const row = Math.floor(i/5);
      const settled = row === 2 || (row === 1 && col > 2);
      return (
        <rect key={i} x={7+col*7} y={10+row*10} width="6" height="8" rx="1"
          fill={settled ? S : E} opacity={settled ? 0.7 : 0.3} />
      );
    })}
    {/* falling grain */}
    <circle cx="14" cy="8" r="3" fill={EB} opacity="0.9" />
    <line x1="14" y1="8" x2="14" y2="14" stroke={EB} strokeWidth="1" strokeDasharray="1.5 1" />
    <text x="24" y="46" fontFamily="monospace" fontSize="5.5" fill={SD} textAnchor="middle">sand falls down</text>
  </Art>
);

const CONWAY_CUBES = () => (
  <Art>
    {/* 3×3 grid front face */}
    {Array.from({length:9},(_,i) => {
      const alive = [1,3,5,7,8].includes(i);
      return (
        <rect key={i} x={9+(i%3)*9} y={9+Math.floor(i/3)*9} width="7" height="7" rx="1"
          fill={alive ? E : P2} opacity={alive ? 0.85 : 0.25} />
      );
    })}
    {/* depth suggestion (isometric-ish) */}
    {[1,3,5,7].map(i => {
      const alive = [1,3,5,7,8].includes(i);
      if (!alive) return null;
      const col = i % 3; const row = Math.floor(i/3);
      return <rect key={i} x={12+(col)*9} y={6+row*9} width="7" height="7" rx="1"
        fill={S} opacity="0.25" />;
    })}
    <text x="24" y="45" fontFamily="monospace" fontSize="5.5" fill={D} textAnchor="middle">3D cellular</text>
  </Art>
);

const OCTO_FLASH = () => (
  <Art>
    {/* central octopus dot */}
    <circle cx="24" cy="24" r="6" fill={E} />
    {/* radiating tentacles / flash */}
    {Array.from({length:8},(_,i) => {
      const a = (i/8)*Math.PI*2;
      const x1 = 24 + 8*Math.cos(a); const y1 = 24 + 8*Math.sin(a);
      const x2 = 24 + 18*Math.cos(a); const y2 = 24 + 18*Math.sin(a);
      return (
        <g key={i}>
          <line x1={x1} y1={y1} x2={x2} y2={y2} stroke={EB} strokeWidth="1.5" opacity="0.7" />
          <circle cx={x2} cy={y2} r="2.5" fill={i<4?S:SD} opacity="0.6" />
        </g>
      );
    })}
    <text x="24" y="46" fontFamily="monospace" fontSize="5.5" fill={EB} textAnchor="middle">chain flash!</text>
  </Art>
);

const DAG_LONGEST = () => (
  <Art>
    {/* nodes */}
    {[[10,24],[20,12],[20,36],[32,20],[32,36],[42,28]].map(([cx,cy],i) => (
      <circle key={i} cx={cx} cy={cy} r="5" fill={i===0||i===3||i===5?E:P2}
        stroke={i===0||i===3||i===5?EB:B} strokeWidth="1" opacity={i===0||i===3||i===5?1:0.6} />
    ))}
    {/* edges — highlighted path */}
    <line x1="15" y1="24" x2="27" y2="20" stroke={E} strokeWidth="1.8" />
    <line x1="37" y1="20" x2="37" y2="28" stroke={E} strokeWidth="1.8" />
    {/* other edges */}
    <line x1="15" y1="24" x2="15" y2="36" stroke={D} strokeWidth="1" opacity="0.4" />
    <line x1="25" y1="12" x2="27" y2="20" stroke={D} strokeWidth="1" opacity="0.4" />
    <line x1="25" y1="36" x2="27" y2="36" stroke={D} strokeWidth="1" opacity="0.4" />
    <text x="24" y="46" fontFamily="monospace" fontSize="5.5" fill={E} textAnchor="middle">longest path</text>
  </Art>
);

const MATH_EVAL = () => (
  <Art>
    {/* expression tree */}
    <text x="24" y="14" fontFamily="monospace" fontSize="10" fill={E} textAnchor="middle">×</text>
    <line x1="22" y1="15" x2="14" y2="24" stroke={D} strokeWidth="1" />
    <line x1="26" y1="15" x2="34" y2="24" stroke={D} strokeWidth="1" />
    <text x="12" y="30" fontFamily="monospace" fontSize="9" fill={S} textAnchor="middle">+</text>
    <text x="36" y="30" fontFamily="monospace" fontSize="9" fill={SD} textAnchor="middle">3</text>
    <line x1="10" y1="31" x2="7" y2="38" stroke={D} strokeWidth="1" />
    <line x1="14" y1="31" x2="17" y2="38" stroke={D} strokeWidth="1" />
    <text x="7" y="44" fontFamily="monospace" fontSize="8" fill={D} textAnchor="middle">2</text>
    <text x="17" y="44" fontFamily="monospace" fontSize="8" fill={D} textAnchor="middle">5</text>
    <text x="38" y="44" fontFamily="monospace" fontSize="6.5" fill={G}>= 21</text>
  </Art>
);

const UNION_FIND = () => (
  <Art>
    {/* separate sets first */}
    <circle cx="10" cy="16" r="5" fill={S} opacity="0.6" />
    <circle cx="22" cy="16" r="5" fill={S} opacity="0.6" />
    <line x1="15" y1="16" x2="17" y2="16" stroke={D} strokeWidth="1" strokeDasharray="2 1" />
    {/* merged set */}
    <ellipse cx="16" cy="32" rx="14" ry="8" fill={E} opacity="0.2" stroke={E} strokeWidth="1.2" />
    <circle cx="10" cy="32" r="4" fill={E} opacity="0.7" />
    <circle cx="22" cy="32" r="4" fill={EB} opacity="0.7" />
    <line x1="14" y1="32" x2="18" y2="32" stroke={T} strokeWidth="1.5" />
    {/* third set */}
    <circle cx="38" cy="24" r="6" fill={G} opacity="0.5" />
    <text x="38" y="27" fontFamily="monospace" fontSize="7" fill={T} textAnchor="middle">C</text>
    <text x="24" y="46" fontFamily="monospace" fontSize="5.5" fill={D} textAnchor="middle">union → find</text>
  </Art>
);

const SEVEN_SEG = () => (
  <Art>
    {/* simplified 7-seg display for "2" */}
    {/* top */}
    <rect x="14" y="8" width="20" height="3" rx="1.5" fill={E} />
    {/* top-right */}
    <rect x="32" y="9" width="3" height="13" rx="1.5" fill={E} />
    {/* middle */}
    <rect x="14" y="21" width="20" height="3" rx="1.5" fill={E} />
    {/* bot-left */}
    <rect x="12" y="23" width="3" height="13" rx="1.5" fill={E} />
    {/* bottom */}
    <rect x="14" y="35" width="20" height="3" rx="1.5" fill={E} />
    {/* dim segments */}
    <rect x="12" y="9" width="3" height="13" rx="1.5" fill={B} opacity="0.4" />
    <rect x="32" y="23" width="3" height="13" rx="1.5" fill={B} opacity="0.4" />
    <text x="24" y="46" fontFamily="monospace" fontSize="5.5" fill={SD} textAnchor="middle">seven-seg</text>
  </Art>
);

const POLYMER_COLLAPSE = () => (
  <Art>
    {/* chain before */}
    {"ABBA".split("").map((ch,i) => (
      <g key={i}>
        <rect x={6+i*9} y="12" width="8" height="10" rx="2"
          fill={ch==="A"?E:S} opacity="0.8" />
        <text x={10+i*9} y="20" fontFamily="monospace" fontSize="6" fill={T} textAnchor="middle">{ch}</text>
        {i<3 && <line x1={14+i*9} y1="17" x2={15+i*9} y2="17" stroke={B} strokeWidth="1" />}
      </g>
    ))}
    {/* collapse arrow */}
    <path d="M24 24 L24 30" stroke={D} strokeWidth="1.2" />
    <polygon points="20,29 24,34 28,29" fill={D} />
    {/* result — BB collapsed */}
    {"AA".split("").map((ch,i) => (
      <g key={i}>
        <rect x={15+i*9} y="35" width="8" height="10" rx="2" fill={E} opacity="0.8" />
        <text x={19+i*9} y="43" fontFamily="monospace" fontSize="6" fill={T} textAnchor="middle">{ch}</text>
      </g>
    ))}
  </Art>
);

const REGROWTH = () => (
  <Art>
    {[
      ["L",".","L","L","."],
      [".","L",".",".","."],
      ["L",".","#","#","L"],
      [".",".",".",".","."],
      ["L",".","L",".","L"],
    ].map((row,ri) =>
      row.map((c,ci) => (
        <rect key={`${ri}-${ci}`} x={6+ci*7.5} y={5+ri*7.5} width="6.5" height="6.5" rx="1"
          fill={c==="L"?S:c==="#"?E:P2} opacity={c==="."?0.2:0.8} />
      ))
    )}
    <text x="24" y="45" fontFamily="monospace" fontSize="5.5" fill={D} textAnchor="middle">seats fill/empty</text>
  </Art>
);

const BEACON_ALIGNMENT = () => (
  <Art>
    {/* beacons */}
    <circle cx="8" cy="10" r="4" fill={S} opacity="0.8" />
    <circle cx="40" cy="10" r="4" fill={S} opacity="0.8" />
    <circle cx="24" cy="38" r="4" fill={S} opacity="0.8" />
    {/* triangulation lines */}
    <line x1="12" y1="10" x2="26" y2="23" stroke={S} strokeWidth="1" opacity="0.4" />
    <line x1="36" y1="10" x2="26" y2="23" stroke={S} strokeWidth="1" opacity="0.4" />
    <line x1="24" y1="34" x2="26" y2="23" stroke={S} strokeWidth="1" opacity="0.4" />
    {/* target point */}
    <circle cx="26" cy="23" r="4" fill={E} />
    <circle cx="26" cy="23" r="8" fill="none" stroke={E} strokeWidth="1" opacity="0.3" />
    <text x="24" y="46" fontFamily="monospace" fontSize="5.5" fill={E} textAnchor="middle">triangulate</text>
  </Art>
);

const LOOPING_LEDGER = () => (
  <Art>
    {/* tape */}
    <rect x="5" y="17" width="38" height="14" rx="2" fill={P2} stroke={B} strokeWidth="1" />
    {["nop","acc","jmp","acc","nop"].map((op,i) => (
      <text key={i} x={9+i*7.5} y="26.5" fontFamily="monospace" fontSize="4.5"
        fill={op==="jmp"?E:op==="acc"?S:D} textAnchor="middle">{op}</text>
    ))}
    {/* loop arrow */}
    <path d="M43 17 Q48 12 48 5 Q48 3 38 3 Q6 3 6 3 Q4 3 4 5 Q4 14 5 17"
      stroke={E} strokeWidth="1.5" fill="none" strokeLinecap="round" strokeDasharray="2 2" />
    <polygon points="4,14 8,17 2,17" fill={E} />
    <text x="24" y="40" fontFamily="monospace" fontSize="5.5" fill={EB} textAnchor="middle">detect loop!</text>
  </Art>
);

const SMOKE_BASINS = () => (
  <Art>
    {/* terrain heights */}
    {[5,9,2,8,1,7,4,9,3,8].map((h,i) => {
      const isLow = h < 3;
      return (
        <rect key={i} x={3+i*4.4} y={38-h*3.2} width="3.8" height={h*3.2}
          rx="0.5" fill={isLow?E:S} opacity={isLow?0.9:0.4} />
      );
    })}
    {/* smoke in basins */}
    {[2,4].map(i => (
      <ellipse key={i} cx={5+i*8.8} cy="38" rx="5" ry="2" fill={EB} opacity="0.3" />
    ))}
    <line x1="3" y1="38" x2="45" y2="38" stroke={B} strokeWidth="1" />
    <text x="24" y="46" fontFamily="monospace" fontSize="5.5" fill={E} textAnchor="middle">find basins</text>
  </Art>
);

const ADAPTER_CHAIN = () => (
  <Art>
    {/* adapters chained */}
    {[1,4,5,6,7,10,11,12].map((j,i,arr) => {
      const x = 5 + i * 5.5;
      return (
        <g key={j}>
          <rect x={x} y="19" width="4.5" height="10" rx="1"
            fill={j>9?E:j>6?S:SD} opacity="0.7" />
          {i < arr.length-1 && (
            <line x1={x+4.5} y1="24" x2={x+5.5} y2="24" stroke={B} strokeWidth="1" />
          )}
        </g>
      );
    })}
    <text x="24" y="38" fontFamily="monospace" fontSize="5" fill={D} textAnchor="middle">joltage gaps: 1 or 3</text>
    <text x="24" y="44" fontFamily="monospace" fontSize="6" fill={G} textAnchor="middle" fontWeight="bold">×arrangements</text>
  </Art>
);

const DOCKING_MASK = () => (
  <Art>
    {/* 10-bit mask (simplified from 36) */}
    {"1X01X10X01".split("").map((b,i) => (
      <g key={i}>
        <rect x={3+i*4.3} y="14" width="3.5" height="12" rx="1"
          fill={b==="X"?E:b==="1"?S:P2} opacity={b==="X"?0.9:b==="1"?0.7:0.3} />
        <text x={4.75+i*4.3} y="23" fontFamily="monospace" fontSize="4.5"
          fill={b==="X"?T:b==="1"?T:D} textAnchor="middle">{b}</text>
      </g>
    ))}
    {/* expanding X arrow */}
    <path d="M14 28 L10 34 M14 28 L18 34" stroke={E} strokeWidth="1.2" />
    <path d="M29 28 L25 34 M29 28 L33 34" stroke={E} strokeWidth="1.2" />
    <text x="24" y="44" fontFamily="monospace" fontSize="5.5" fill={EB} textAnchor="middle">X floats 0 or 1</text>
  </Art>
);

const WAYPOINT_RUN = () => (
  <Art>
    {/* compass rose */}
    <circle cx="36" cy="12" r="8" fill={P2} stroke={B} strokeWidth="1" />
    <text x="36" y="10" fontFamily="monospace" fontSize="5" fill={D} textAnchor="middle">N</text>
    <text x="36" y="18" fontFamily="monospace" fontSize="5" fill={D} textAnchor="middle">S</text>
    <text x="31" y="15" fontFamily="monospace" fontSize="5" fill={D} textAnchor="middle">W</text>
    <text x="41" y="15" fontFamily="monospace" fontSize="5" fill={D} textAnchor="middle">E</text>
    {/* ship */}
    <polygon points="18,28 24,16 30,28" fill={E} opacity="0.8" />
    {/* waypoint dot */}
    <circle cx="10" cy="10" r="3.5" fill={S} />
    {/* path line */}
    <line x1="18" y1="24" x2="12" y2="12" stroke={G} strokeWidth="1.2" strokeDasharray="2 1" />
    <text x="24" y="42" fontFamily="monospace" fontSize="5.5" fill={D} textAnchor="middle">rotate waypoint</text>
  </Art>
);

const CROSSING_VENTS = () => (
  <Art>
    {/* grid background */}
    {Array.from({length:6},(_,i) => (
      <line key={`h${i}`} x1="6" y1={10+i*6} x2="42" y2={10+i*6} stroke={B} strokeWidth="0.5" opacity="0.3" />
    ))}
    {Array.from({length:6},(_,i) => (
      <line key={`v${i}`} x1={6+i*7} y1="10" x2={6+i*7} y2="40" stroke={B} strokeWidth="0.5" opacity="0.3" />
    ))}
    {/* vent lines */}
    <line x1="6" y1="10" x2="42" y2="10" stroke={S} strokeWidth="2" opacity="0.8" />
    <line x1="6" y1="28" x2="42" y2="28" stroke={SD} strokeWidth="2" opacity="0.7" />
    <line x1="20" y1="10" x2="20" y2="40" stroke={E} strokeWidth="2" opacity="0.8" />
    <line x1="34" y1="10" x2="34" y2="28" stroke={EB} strokeWidth="2" opacity="0.7" />
    {/* overlap dots */}
    <circle cx="20" cy="10" r="3.5" fill={G} />
    <circle cx="34" cy="10" r="3.5" fill={G} />
    <circle cx="20" cy="28" r="3.5" fill={G} />
    <text x="24" y="46" fontFamily="monospace" fontSize="5.5" fill={G} textAnchor="middle">overlaps: 3</text>
  </Art>
);

const SEA_CUCUMBER = () => (
  <Art>
    {/* grid with arrows */}
    {[
      [">",".",">","v","."],
      [".",">",".",".","v"],
      [">",".",".","v","."],
      [".",".",">",".","."],
    ].map((row,ri) =>
      row.map((c,ci) => (
        <g key={`${ri}-${ci}`}>
          <rect x={5+ci*8} y={5+ri*9} width="7" height="8" rx="1"
            fill={c===">"?E:c==="v"?S:P2} opacity={c==="."?0.15:0.7} />
          {c!=="." && (
            <text x={8.5+ci*8} y={11+ri*9} fontFamily="monospace" fontSize="6"
              fill={T} textAnchor="middle">{c}</text>
          )}
        </g>
      ))
    )}
    <text x="24" y="46" fontFamily="monospace" fontSize="5.5" fill={D} textAnchor="middle">step until still</text>
  </Art>
);

const FOUNDERS_ENGINE = () => (
  <Art bg="#1A1C21">
    {/* outer gear */}
    <circle cx="24" cy="24" r="18" fill={P} stroke={E} strokeWidth="1.5" />
    {/* gear teeth */}
    {Array.from({length:12},(_,i) => {
      const a = (i/12)*Math.PI*2; const r=18; const r2=22;
      return <line key={i} x1={24+r*Math.cos(a)} y1={24+r*Math.sin(a)}
        x2={24+r2*Math.cos(a)} y2={24+r2*Math.sin(a)}
        stroke={E} strokeWidth="2" strokeLinecap="round" />;
    })}
    {/* inner gear */}
    <circle cx="24" cy="24" r="11" fill={P2} stroke={EB} strokeWidth="1" />
    {Array.from({length:8},(_,i) => {
      const a = (i/8)*Math.PI*2; const r=11; const r2=14;
      return <line key={i} x1={24+r*Math.cos(a)} y1={24+r*Math.sin(a)}
        x2={24+r2*Math.cos(a)} y2={24+r2*Math.sin(a)}
        stroke={EB} strokeWidth="1.5" strokeLinecap="round" />;
    })}
    {/* core */}
    <circle cx="24" cy="24" r="5" fill={E} />
    <circle cx="24" cy="24" r="2" fill={T} />
    {/* energy sparks */}
    <circle cx="6" cy="6" r="2" fill={EB} opacity="0.8" />
    <circle cx="42" cy="6" r="2" fill={EB} opacity="0.8" />
    <circle cx="6" cy="42" r="2" fill={EB} opacity="0.6" />
    <circle cx="42" cy="42" r="2" fill={EB} opacity="0.6" />
  </Art>
);

// ── REGISTRY ───────────────────────────────────────────────────────────────────

import React from "react";

const ART: Record<string, () => React.ReactElement> = {
  "hello-forge": HELLO_FORGE,
  "sum-two": SUM_TWO,
  "even-odd": EVEN_ODD,
  "abs-diff": ABS_DIFF,
  "shout": SHOUT,
  "reverse": REVERSE,
  "sum-to-n": SUM_TO_N,
  "count-down": COUNT_DOWN,
  "factorial": FACTORIAL,
  "fizzbuzz-count": FIZZBUZZ,
  "count-vowels": COUNT_VOWELS,
  "count-words": COUNT_WORDS,
  "max-of-list": MAX_OF_LIST,
  "unique-count": UNIQUE_COUNT,
  // gauntlet
  "is-prime": IS_PRIME,
  "gcd": GCD,
  "fibonacci": FIBONACCI,
  "most-common": MOST_COMMON,
  "sort-desc": SORT_DESC,
  "power-recursion": POWER_RECURSION,
  "binary-to-decimal": BINARY_TO_DECIMAL,
  "grid-count": GRID_COUNT,
  "calorie-groups": CALORIE_GROUPS,
  "pair-sums": PAIR_SUMS,
  "rucksack-priorities": RUCKSACK,
  "rps-score": RPS_SCORE,
  "caesar-decode": CAESAR_DECODE,
  "balanced-brackets": BALANCED_BRACKETS,
  "run-length-decode": RUN_LENGTH,
  "count-regions": COUNT_REGIONS,
  "tiny-vm": TINY_VM,
  "maze-path": MAZE_PATH,
  "reactor-cycles": REACTOR_CYCLES,
  "flood-barriers": FLOOD_BARRIERS,
  "sealed-vault": SEALED_VAULT,
  "bit-diagnostic": BIT_DIAGNOSTIC,
  "crab-align": CRAB_ALIGN,
  "age-buckets": AGE_BUCKETS,
  "founders-lottery": FOUNDERS_LOTTERY,
  "folded-map": FOLDED_MAP,
  "broken-cipher": BROKEN_CIPHER,
  "core-reboot": CORE_REBOOT,
  "root-tunnels": ROOT_TUNNELS,
  "under-the-trees": UNDER_THE_TREES,
  "hazard-descent": HAZARD_DESCENT,
  "instruction-ribbon": INSTRUCTION_RIBBON,
  "settling-lattice": SETTLING_LATTICE,
  "conway-cubes": CONWAY_CUBES,
  "octo-flash": OCTO_FLASH,
  "dag-longest": DAG_LONGEST,
  "math-eval": MATH_EVAL,
  "union-find": UNION_FIND,
  "seven-seg": SEVEN_SEG,
  "polymer-collapse": POLYMER_COLLAPSE,
  "regrowth": REGROWTH,
  "beacon-alignment": BEACON_ALIGNMENT,
  "looping-ledger": LOOPING_LEDGER,
  "smoke-basins": SMOKE_BASINS,
  "adapter-chain": ADAPTER_CHAIN,
  "docking-mask": DOCKING_MASK,
  "waypoint-run": WAYPOINT_RUN,
  "crossing-vents": CROSSING_VENTS,
  "sea-cucumber": SEA_CUCUMBER,
  "founders-engine": FOUNDERS_ENGINE,
};

function DefaultArt({ size }: { size: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 48 48" fill="none">
      <rect width="48" height="48" rx="8" fill={P} />
      <circle cx="24" cy="24" r="10" stroke={B} strokeWidth="1.5" />
      <line x1="18" y1="18" x2="30" y2="30" stroke={B} strokeWidth="1.5" />
      <line x1="30" y1="18" x2="18" y2="30" stroke={B} strokeWidth="1.5" />
    </svg>
  );
}

export function ChallengeArt({ id, size = 44 }: { id: string; size?: number }) {
  const Component = ART[id];
  if (!Component) return <DefaultArt size={size} />;
  return (
    <div style={{ width: size, height: size, flexShrink: 0 }}>
      <Component />
    </div>
  );
}
