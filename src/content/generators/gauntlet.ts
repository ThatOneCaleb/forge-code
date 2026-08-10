import type { PuzzleInstance } from "../../engine/types";
import type { Rng } from "../../engine/rng";

// Per-player generators for the Gauntlet challenges. Each builds a random input
// and computes `expected` with the SAME logic as that challenge's reference
// solution; the generator cross-check test verifies agreement across seeds.

export function genRucksack(rng: Rng): PuzzleInstance {
  const lower = "abcdefghijklmnopqrstuvwxyz";
  const upper = lower.toUpperCase();
  const prio = (c: string) =>
    c >= "a" && c <= "z" ? c.charCodeAt(0) - 96 : c.charCodeAt(0) - 64 + 26;
  const n = rng.range(12, 30);
  const lines: string[] = [];
  let total = 0;
  for (let k = 0; k < n; k++) {
    const pool = rng.next() < 0.5 ? lower : upper;
    const idxs = [...Array(26).keys()];
    for (let x = idxs.length - 1; x > 0; x--) {
      const j = rng.int(x + 1);
      [idxs[x], idxs[j]] = [idxs[j], idxs[x]];
    }
    const half = rng.range(3, 6);
    const shared = pool[idxs[0]];
    const left = [shared, ...idxs.slice(1, half).map((i) => pool[i])];
    const right = [shared, ...idxs.slice(half, half + half - 1).map((i) => pool[i])];
    lines.push(left.join("") + right.join(""));
    total += prio(shared);
  }
  return { input: lines.join("\n"), expected: String(total) };
}

export function genRps(rng: Rng): PuzzleInstance {
  const opp = ["A", "B", "C"], me = ["X", "Y", "Z"];
  const n = rng.range(30, 80);
  const lines: string[] = [];
  let score = 0;
  for (let k = 0; k < n; k++) {
    const a = rng.int(3), b = rng.int(3);
    lines.push(`${opp[a]} ${me[b]}`);
    score += b + 1;
    if (a === b) score += 3;
    else if ((b - a + 3) % 3 === 1) score += 6;
  }
  return { input: lines.join("\n"), expected: String(score) };
}

export function genCaesar(rng: Rng): PuzzleInstance {
  const n = rng.range(1, 25);
  const words = ["the", "forge", "core", "deep", "spark", "iron", "gear", "ada", "sprocket", "vault", "ember", "cold", "waking", "founders"];
  const count = rng.range(40, 90);
  const msg = Array.from({ length: count }, () => rng.pick(words)).join(" ");
  let enc = "";
  for (const c of msg) {
    if (c >= "a" && c <= "z") enc += String.fromCharCode(((c.charCodeAt(0) - 97 + n) % 26) + 97);
    else enc += c;
  }
  return { input: `${n}\n${enc}`, expected: msg };
}

export function genBrackets(rng: Rng): PuzzleInstance {
  const pairs = [["(", ")"], ["[", "]"], ["{", "}"]];
  function build(depth: number): string {
    if (depth <= 0 || rng.next() < 0.35) return "";
    const p = rng.pick(pairs);
    return p[0] + build(depth - 1) + p[1] + (rng.next() < 0.55 ? build(depth - 1) : "");
  }
  // A long sequence: many balanced groups concatenated.
  const groups = rng.range(20, 45);
  let s = "";
  for (let g = 0; g < groups; g++) s += build(rng.range(2, 5)) || "()";
  if (rng.next() < 0.5) {
    const chars = [...s];
    chars[rng.int(chars.length)] = rng.pick(["(", ")", "[", "]", "{", "}"]);
    s = chars.join("");
  }
  const map: Record<string, string> = { ")": "(", "]": "[", "}": "{" };
  const st: string[] = [];
  let ok = true;
  for (const c of s) {
    if (c === "(" || c === "[" || c === "{") st.push(c);
    else if (c in map) { if (st.pop() !== map[c]) { ok = false; break; } }
  }
  return { input: s, expected: ok && st.length === 0 ? "yes" : "no" };
}

export function genRunLength(rng: Rng): PuzzleInstance {
  const letters = "abcdefghijklmnopqrstuvwxyz";
  const n = rng.range(50, 90);
  let input = "", out = "";
  for (let k = 0; k < n; k++) {
    const ch = letters[rng.int(26)];
    const cnt = rng.range(1, 12);
    input += ch + cnt;
    out += ch.repeat(cnt);
  }
  return { input, expected: out };
}

export function genCountRegions(rng: Rng): PuzzleInstance {
  const W = rng.range(12, 20), H = rng.range(12, 20);
  const grid: string[][] = [];
  for (let r = 0; r < H; r++) {
    const row: string[] = [];
    for (let c = 0; c < W; c++) row.push(rng.next() < 0.45 ? "#" : ".");
    grid.push(row);
  }
  const seen = new Set<string>();
  let regions = 0;
  for (let r = 0; r < H; r++) {
    for (let c = 0; c < W; c++) {
      if (grid[r][c] === "#" && !seen.has(r + "," + c)) {
        regions++;
        const stack = [[r, c]];
        seen.add(r + "," + c);
        while (stack.length) {
          const [y, x] = stack.pop()!;
          for (const [dy, dx] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
            const ny = y + dy, nx = x + dx;
            if (ny >= 0 && ny < H && nx >= 0 && nx < W && grid[ny][nx] === "#" && !seen.has(ny + "," + nx)) {
              seen.add(ny + "," + nx);
              stack.push([ny, nx]);
            }
          }
        }
      }
    }
  }
  return { input: grid.map((r) => r.join("")).join("\n"), expected: String(regions) };
}

export function genTinyVm(rng: Rng): PuzzleInstance {
  const n = rng.range(30, 70);
  const lines: string[] = [];
  let acc = 0;
  const CAP = 1e12; // keep the accumulator well within safe-integer range (JS === Python)
  for (let k = 0; k < n; k++) {
    let op = k === 0 ? "set" : rng.pick(["set", "add", "mul", "add", "set"]);
    const arg = rng.range(1, 9);
    if (op === "mul" && acc * arg > CAP) op = "add"; // avoid overflow/precision drift
    lines.push(`${op} ${arg}`);
    if (op === "set") acc = arg;
    else if (op === "add") acc += arg;
    else acc *= arg;
  }
  return { input: lines.join("\n"), expected: String(acc) };
}

export function genMaze(rng: Rng): PuzzleInstance {
  const W = rng.range(13, 18), H = rng.range(13, 18);
  const g: string[][] = [];
  for (let r = 0; r < H; r++) {
    const row: string[] = [];
    for (let c = 0; c < W; c++) row.push(rng.next() < 0.25 ? "#" : ".");
    g.push(row);
  }
  g[0][0] = "S";
  g[H - 1][W - 1] = "E";
  const seen = new Set([`0,0`]);
  let frontier = [[0, 0, 0]];
  let dist = -1;
  while (frontier.length) {
    const next: number[][] = [];
    for (const [y, x, d] of frontier) {
      if (g[y][x] === "E") { dist = d; break; }
      for (const [dy, dx] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
        const ny = y + dy, nx = x + dx;
        if (ny >= 0 && ny < H && nx >= 0 && nx < W && g[ny][nx] !== "#" && !seen.has(ny + "," + nx)) {
          seen.add(ny + "," + nx);
          next.push([ny, nx, d + 1]);
        }
      }
    }
    if (dist >= 0) break;
    frontier = next;
  }
  return { input: g.map((r) => r.join("")).join("\n"), expected: String(dist) };
}

// ----- Act I (d4–5): aggregate over a large, unique-per-player input -----

// Story IS the algorithm: heat spreads outward from seeded rods, one tick at a
// time (4-directionally). Answer = ticks until the whole grid is hot.
export function genHeatSpread(rng: Rng): PuzzleInstance {
  const W = rng.range(16, 26), H = rng.range(13, 20);
  const grid: string[][] = [];
  for (let r = 0; r < H; r++) grid.push(new Array(W).fill("."));
  const seeds = rng.range(3, 8);
  for (let k = 0; k < seeds; k++) grid[rng.int(H)][rng.int(W)] = "#";

  const hot = (g: string[][], y: number, x: number) =>
    y >= 0 && y < H && x >= 0 && x < W && g[y][x] === "#";
  let g = grid.map((r) => r.slice());
  let ticks = 0;
  while (g.some((row) => row.includes("."))) {
    const next = g.map((r) => r.slice());
    let changed = false;
    for (let y = 0; y < H; y++)
      for (let x = 0; x < W; x++)
        if (g[y][x] === "." && (hot(g, y - 1, x) || hot(g, y + 1, x) || hot(g, y, x - 1) || hot(g, y, x + 1))) {
          next[y][x] = "#";
          changed = true;
        }
    g = next;
    ticks++;
    if (!changed) break;
  }
  return { input: grid.map((r) => r.join("")).join("\n"), expected: String(ticks) };
}

export function genPrimeCensus(rng: Rng): PuzzleInstance {
  const isPrime = (n: number) => {
    if (n < 2) return false;
    for (let i = 2; i * i <= n; i++) if (n % i === 0) return false;
    return true;
  };
  const N = rng.range(300, 600);
  const nums: number[] = [];
  for (let k = 0; k < N; k++) nums.push(rng.range(2, 9999));
  return { input: nums.join("\n"), expected: String(nums.filter(isPrime).length) };
}

export function genGcdSum(rng: Rng): PuzzleInstance {
  const gcd = (a: number, b: number) => { while (b) { const t = a % b; a = b; b = t; } return a; };
  const N = rng.range(200, 400);
  const lines: string[] = [];
  let s = 0;
  for (let k = 0; k < N; k++) {
    const a = rng.range(1, 999), b = rng.range(1, 999);
    lines.push(`${a} ${b}`);
    s += gcd(a, b);
  }
  return { input: lines.join("\n"), expected: String(s) };
}

export function genFibSum(rng: Rng): PuzzleInstance {
  const fib = (n: number) => { if (n <= 2) return 1; let a = 1, b = 1; for (let i = 3; i <= n; i++) { const c = a + b; a = b; b = c; } return b; };
  const N = rng.range(200, 400);
  const vals: number[] = [];
  let s = 0;
  for (let k = 0; k < N; k++) { const n = rng.range(1, 35); vals.push(n); s += fib(n); }
  return { input: vals.join("\n"), expected: String(s) };
}

export function genPowerSum(rng: Rng): PuzzleInstance {
  const N = rng.range(150, 300);
  const lines: string[] = [];
  let s = 0;
  for (let k = 0; k < N; k++) {
    const b = rng.range(2, 9), e = rng.range(0, 10);
    let v = 1;
    for (let i = 0; i < e; i++) v *= b;
    lines.push(`${b} ${e}`);
    s += v;
  }
  return { input: lines.join("\n"), expected: String(s) };
}

export function genBinarySum(rng: Rng): PuzzleInstance {
  const N = rng.range(200, 400);
  const lines: string[] = [];
  let s = 0;
  for (let k = 0; k < N; k++) {
    const len = rng.range(4, 14);
    let str = "1";
    for (let i = 1; i < len; i++) str += rng.int(2);
    let v = 0;
    for (const c of str) v = v * 2 + Number(c);
    lines.push(str);
    s += v;
  }
  return { input: lines.join("\n"), expected: String(s) };
}

export function genMostCommon(rng: Rng): PuzzleInstance {
  const vocab = ["gear", "cog", "bolt", "spring", "valve", "piston", "rivet", "axle", "cam", "shaft"];
  const N = rng.range(200, 500);
  const words: string[] = [];
  for (let k = 0; k < N; k++) words.push(rng.pick(vocab));
  const counts: Record<string, number> = {};
  let best = "", bestN = 0;
  for (const w of words) {
    counts[w] = (counts[w] || 0) + 1;
    if (counts[w] > bestN) { bestN = counts[w]; best = w; }
  }
  return { input: words.join(" "), expected: best };
}

export function genSortDesc(rng: Rng): PuzzleInstance {
  const N = rng.range(100, 250);
  const nums: number[] = [];
  for (let k = 0; k < N; k++) nums.push(rng.range(1, 999));
  return { input: nums.join(" "), expected: [...nums].sort((a, b) => b - a).join(" ") };
}

export function genGridCount(rng: Rng): PuzzleInstance {
  const W = rng.range(25, 45), H = rng.range(25, 45);
  const rows: string[] = [];
  let count = 0;
  for (let r = 0; r < H; r++) {
    let row = "";
    for (let c = 0; c < W; c++) { if (rng.next() < 0.5) { row += "#"; count++; } else row += "."; }
    rows.push(row);
  }
  return { input: rows.join("\n"), expected: String(count) };
}

export function genCalorieGroups(rng: Rng): PuzzleInstance {
  const G = rng.range(10, 30);
  const groups: string[] = [];
  let best = 0;
  for (let g = 0; g < G; g++) {
    const n = rng.range(2, 6);
    const vals: number[] = [];
    let sum = 0;
    for (let k = 0; k < n; k++) { const v = rng.range(1, 99); vals.push(v); sum += v; }
    groups.push(vals.join("\n"));
    if (sum > best) best = sum;
  }
  return { input: groups.join("\n\n"), expected: String(best) };
}

export function genPairSums(rng: Rng): PuzzleInstance {
  const n = rng.range(150, 300);
  const nums: number[] = [];
  for (let k = 0; k < n; k++) nums.push(rng.range(1, 50));
  const target = rng.range(20, 80);
  let count = 0;
  for (let i = 0; i < n; i++) for (let j = i + 1; j < n; j++) if (nums[i] + nums[j] === target) count++;
  return { input: `${target}\n${nums.join(" ")}`, expected: String(count) };
}

export function genReactor(rng: Rng): PuzzleInstance {
  const n = rng.range(15, 40);
  const nums: number[] = [];
  let total = 0;
  for (let k = 0; k < n - 1; k++) {
    const v = rng.range(-9, 9) || 1;
    nums.push(v);
    total += v;
  }
  nums.push(-total); // total sum 0 → running sum revisits 0 within one pass
  const seen = new Set([0]);
  let freq = 0, i = 0, ans = 0;
  while (i < 100000) {
    freq += nums[i % nums.length];
    if (seen.has(freq)) { ans = freq; break; }
    seen.add(freq);
    i++;
  }
  const fmt = (v: number) => (v >= 0 ? "+" : "") + v;
  return { input: nums.map(fmt).join("\n"), expected: String(ans) };
}

// ===== Act IV — The Hidden Layer (d10) =====

// Least-risk descent through a grid of digits 1-9 (Dijkstra, 4-directional;
// cost = the risk of each cell you enter, start cell not counted).
export function genHazardDescent(rng: Rng): PuzzleInstance {
  const W = rng.range(16, 22), H = rng.range(16, 22);
  const grid: number[][] = [];
  for (let r = 0; r < H; r++) {
    const row: number[] = [];
    for (let c = 0; c < W; c++) row.push(rng.range(1, 9));
    grid.push(row);
  }
  return { input: grid.map((r) => r.join("")).join("\n"), expected: String(dijkstraGrid(grid, W, H)) };
}

function dijkstraGrid(grid: number[][], W: number, H: number): number {
  const dist = new Array(W * H).fill(Infinity);
  dist[0] = 0;
  const heap: [number, number][] = []; // binary min-heap of [cost, index]
  const push = (c: number, i: number) => {
    heap.push([c, i]);
    let k = heap.length - 1;
    while (k > 0) { const p = (k - 1) >> 1; if (heap[p][0] <= heap[k][0]) break; [heap[p], heap[k]] = [heap[k], heap[p]]; k = p; }
  };
  const pop = (): [number, number] => {
    const top = heap[0], last = heap.pop()!;
    if (heap.length) {
      heap[0] = last;
      let k = 0;
      for (;;) {
        const l = 2 * k + 1, r = 2 * k + 2;
        let m = k;
        if (l < heap.length && heap[l][0] < heap[m][0]) m = l;
        if (r < heap.length && heap[r][0] < heap[m][0]) m = r;
        if (m === k) break;
        [heap[m], heap[k]] = [heap[k], heap[m]]; k = m;
      }
    }
    return top;
  };
  push(0, 0);
  while (heap.length) {
    const [c, i] = pop();
    if (c > dist[i]) continue;
    if (i === W * H - 1) return c;
    const y = Math.floor(i / W), x = i % W;
    for (const [dy, dx] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
      const ny = y + dy, nx = x + dx;
      if (ny >= 0 && ny < H && nx >= 0 && nx < W) {
        const ni = ny * W + nx, nc = c + grid[ny][nx];
        if (nc < dist[ni]) { dist[ni] = nc; push(nc, ni); }
      }
    }
  }
  return dist[W * H - 1];
}

// A looping L/R ribbon walks a labeled node network from AAA to ZZZ. Built so
// the walk follows a hidden chain of exactly T distinct nodes → answer is T.
export function genInstructionRibbon(rng: Rng): PuzzleInstance {
  const T = rng.range(300, 900);
  const instrLen = rng.range(5, 16);
  let instr = "";
  for (let i = 0; i < instrLen; i++) instr += rng.next() < 0.5 ? "L" : "R";

  const letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  const used = new Set<string>(["AAA", "ZZZ"]);
  const newLabel = () => {
    for (;;) {
      const s = letters[rng.int(26)] + letters[rng.int(26)] + letters[rng.int(26)];
      if (!used.has(s)) { used.add(s); return s; }
    }
  };

  const path: string[] = ["AAA"];
  for (let i = 1; i < T; i++) path.push(newLabel());
  path.push("ZZZ");

  const decoys: string[] = [];
  const decoyCount = rng.range(20, 60);
  for (let i = 0; i < decoyCount; i++) decoys.push(newLabel());
  const allLabels = [...path, ...decoys];
  const randLabel = () => allLabels[rng.int(allLabels.length)];

  const branches = new Map<string, [string, string]>();
  for (let i = 0; i < T; i++) {
    const dir = instr[i % instrLen];
    const nextNode = path[i + 1], decoy = randLabel();
    branches.set(path[i], dir === "L" ? [nextNode, decoy] : [decoy, nextNode]);
  }
  branches.set("ZZZ", [randLabel(), randLabel()]);
  for (const d of decoys) branches.set(d, [randLabel(), randLabel()]);

  const lines = allLabels.map((lab) => {
    const [l, r] = branches.get(lab)!;
    return `${lab} = (${l}, ${r})`;
  });
  for (let i = lines.length - 1; i > 0; i--) { const j = rng.int(i + 1); [lines[i], lines[j]] = [lines[j], lines[i]]; }

  return { input: `${instr}\n\n${lines.join("\n")}`, expected: String(T) };
}

// Seat automaton (8-neighbour) run to a stable state; answer = occupied seats.
export function genSettlingLattice(rng: Rng): PuzzleInstance {
  const W = rng.range(20, 30), H = rng.range(20, 30);
  const grid: string[][] = [];
  for (let r = 0; r < H; r++) {
    const row: string[] = [];
    for (let c = 0; c < W; c++) row.push(rng.next() < 0.6 ? "L" : ".");
    grid.push(row);
  }
  return { input: grid.map((r) => r.join("")).join("\n"), expected: String(settleSeats(grid, W, H)) };
}

function settleSeats(start: string[][], W: number, H: number): number {
  const dirs = [[-1, -1], [-1, 0], [-1, 1], [0, -1], [0, 1], [1, -1], [1, 0], [1, 1]];
  let g = start.map((r) => r.slice());
  for (let round = 0; round < 500; round++) {
    const next = g.map((r) => r.slice());
    let changed = false;
    for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
      if (g[y][x] === ".") continue;
      let occ = 0;
      for (const [dy, dx] of dirs) {
        const ny = y + dy, nx = x + dx;
        if (ny >= 0 && ny < H && nx >= 0 && nx < W && g[ny][nx] === "#") occ++;
      }
      if (g[y][x] === "L" && occ === 0) { next[y][x] = "#"; changed = true; }
      else if (g[y][x] === "#" && occ >= 4) { next[y][x] = "L"; changed = true; }
    }
    g = next;
    if (!changed) break;
  }
  let count = 0;
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) if (g[y][x] === "#") count++;
  return count;
}

// ===== Act V — The Last Forge (d10) =====

// Pair-insertion growth over N steps; answer = most-common minus least-common
// element count. N is large enough that only pair-frequency counting is feasible.
export function genRegrowth(rng: Rng): PuzzleInstance {
  const K = rng.range(6, 9);
  const alphabet = "ABCDEFGHIJ".slice(0, K).split("");
  const N = rng.range(30, 38);
  const L = rng.range(10, 16);
  const template = Array.from({ length: L }, () => rng.pick(alphabet)).join("");
  const rules: Record<string, string> = {};
  const ruleLines: string[] = [];
  for (const a of alphabet) for (const b of alphabet) {
    const c = rng.pick(alphabet);
    rules[a + b] = c;
    ruleLines.push(`${a}${b} -> ${c}`);
  }
  for (let i = ruleLines.length - 1; i > 0; i--) { const j = rng.int(i + 1); [ruleLines[i], ruleLines[j]] = [ruleLines[j], ruleLines[i]]; }
  const expected = polymerDiff(template, rules, N);
  return { input: `${N}\n${template}\n\n${ruleLines.join("\n")}`, expected: String(expected) };
}

function polymerDiff(template: string, rules: Record<string, string>, N: number): number {
  let pairs: Record<string, number> = {};
  for (let i = 0; i + 1 < template.length; i++) {
    const p = template[i] + template[i + 1];
    pairs[p] = (pairs[p] || 0) + 1;
  }
  const elem: Record<string, number> = {};
  for (const ch of template) elem[ch] = (elem[ch] || 0) + 1;
  for (let step = 0; step < N; step++) {
    const next: Record<string, number> = {};
    for (const p in pairs) {
      const cnt = pairs[p];
      const c = rules[p];
      if (c === undefined) { next[p] = (next[p] || 0) + cnt; continue; }
      const left = p[0] + c, right = c + p[1];
      next[left] = (next[left] || 0) + cnt;
      next[right] = (next[right] || 0) + cnt;
      elem[c] = (elem[c] || 0) + cnt;
    }
    pairs = next;
  }
  const vals = Object.values(elem);
  return Math.max(...vals) - Math.min(...vals);
}

// Align staggered cycles: earliest t so each numbered token at index i satisfies
// (t + i) % period == 0. Distinct-prime periods keep it solvable and bounded.
export function genBeaconAlignment(rng: Rng): PuzzleInstance {
  const pool = [7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43];
  for (let i = pool.length - 1; i > 0; i--) { const j = rng.int(i + 1); [pool[i], pool[j]] = [pool[j], pool[i]]; }
  const chosen: number[] = [];
  let product = 1;
  const target = rng.range(4, 6);
  for (const p of pool) {
    if (chosen.length >= target) break;
    if (product * p > 1e10) continue;
    chosen.push(p); product *= p;
  }
  const M = chosen.length + rng.range(60, 90);
  const idxs = [...Array(M).keys()];
  for (let i = idxs.length - 1; i > 0; i--) { const j = rng.int(i + 1); [idxs[i], idxs[j]] = [idxs[j], idxs[i]]; }
  const busPos = idxs.slice(0, chosen.length);
  const tokens: string[] = new Array(M).fill("x");
  busPos.forEach((pos, k) => { tokens[pos] = String(chosen[k]); });

  let t = 0, step = 1;
  tokens.forEach((tok, i) => {
    if (tok === "x") return;
    const p = Number(tok);
    while ((t + i) % p !== 0) t += step;
    step *= p;
  });
  return { input: tokens.join(","), expected: String(t) };
}

// Handlers relay items whose values would explode under repeated ops; reduce
// mod the product of all divisors to stay bounded. Answer = product of the two
// highest inspection counts after R rounds.
export function genFoundersEngine(rng: Rng): PuzzleInstance {
  const primes = [2, 3, 5, 7, 11, 13, 17, 19, 23];
  const H = rng.range(4, 6);
  const pool = [...primes];
  for (let i = pool.length - 1; i > 0; i--) { const j = rng.int(i + 1); [pool[i], pool[j]] = [pool[j], pool[i]]; }
  const divs = pool.slice(0, H);
  const R = rng.range(20, 40);
  const ops: string[] = [];
  const startItems: number[][] = [];
  const trueT: number[] = [], falseT: number[] = [];
  for (let i = 0; i < H; i++) {
    const nItems = rng.range(1, 4);
    startItems.push(Array.from({ length: nItems }, () => rng.range(1, 99)));
    const kind = rng.int(3);
    if (kind === 0) ops.push(`* ${rng.range(2, 9)}`);
    else if (kind === 1) ops.push(`+ ${rng.range(1, 9)}`);
    else ops.push("* old");
    let t = rng.int(H); while (t === i) t = rng.int(H);
    let f = rng.int(H); while (f === i || f === t) f = rng.int(H);
    trueT.push(t); falseT.push(f);
  }
  const expected = simulateEngine(R, startItems.map((a) => a.slice()), ops, divs, trueT, falseT, H);
  const lines: string[] = [];
  for (let i = 0; i < H; i++) {
    lines.push(`items=${startItems[i].join(",")} | op=${ops[i]} | div=${divs[i]} | true=${trueT[i]} | false=${falseT[i]}`);
  }
  return { input: `${R}\n\n${lines.join("\n")}`, expected: String(expected) };
}

function simulateEngine(
  R: number, items: number[][], ops: string[], divs: number[],
  trueT: number[], falseT: number[], H: number,
): number {
  const L = divs.reduce((a, b) => a * b, 1);
  const counts = new Array(H).fill(0);
  for (let round = 0; round < R; round++) {
    for (let i = 0; i < H; i++) {
      const held = items[i];
      items[i] = [];
      for (let val of held) {
        counts[i]++;
        const op = ops[i];
        if (op === "* old") val = (val * val) % L;
        else {
          const sp = op.split(" ");
          const k = Number(sp[1]);
          val = sp[0] === "*" ? (val * k) % L : (val + k) % L;
        }
        const target = val % divs[i] === 0 ? trueT[i] : falseT[i];
        items[target].push(val);
      }
    }
  }
  counts.sort((a, b) => b - a);
  return counts[0] * counts[1];
}

// ===== Act II filler — The Waking Deep (d7) =====

// Merge overlapping inclusive integer ranges; expected = total positions covered.
export function genIntervalMerge(rng: Rng): PuzzleInstance {
  const n = rng.range(200, 400);
  const ranges: [number, number][] = [];
  const lines: string[] = [];
  for (let i = 0; i < n; i++) {
    const a = rng.int(1_000_000);
    const b = a + rng.range(1, 5000);
    ranges.push([a, b]);
    lines.push(`${a} ${b}`);
  }
  return { input: `${n}\n${lines.join("\n")}`, expected: String(unionLength(ranges)) };
}

function unionLength(ranges: [number, number][]): number {
  const sorted = ranges.slice().sort((a, b) => a[0] - b[0]);
  let total = 0, curS = sorted[0][0], curE = sorted[0][1];
  for (let i = 1; i < sorted.length; i++) {
    const [s, e] = sorted[i];
    if (s > curE) { total += curE - curS + 1; curS = s; curE = e; }
    else if (e > curE) curE = e;
  }
  return total + (curE - curS + 1);
}

// ===== Act III expansion — The Endgame (d8-d10) =====

// Bit-frequency diagnostic: most/least common bit per column -> gamma * epsilon.
export function genBitDiagnostic(rng: Rng): PuzzleInstance {
  const W = rng.range(10, 14);
  const N = rng.range(300, 600);
  const rows: string[] = [];
  for (let i = 0; i < N; i++) {
    let r = "";
    for (let c = 0; c < W; c++) r += rng.int(2);
    rows.push(r);
  }
  return { input: rows.join("\n"), expected: String(bitDiag(rows)) };
}

function bitDiag(rows: string[]): number {
  const W = rows[0].length;
  let gamma = "", epsilon = "";
  for (let c = 0; c < W; c++) {
    let ones = 0;
    for (const r of rows) if (r[c] === "1") ones++;
    if (ones >= rows.length - ones) { gamma += "1"; epsilon += "0"; }
    else { gamma += "0"; epsilon += "1"; }
  }
  return parseInt(gamma, 2) * parseInt(epsilon, 2);
}

// Least total distance to align numbers to a common point (absolute cost) = median.
export function genCrabAlign(rng: Rng): PuzzleInstance {
  const n = rng.range(500, 1000);
  const nums = Array.from({ length: n }, () => rng.int(2000));
  return { input: nums.join(","), expected: String(crabAlign(nums)) };
}

function crabAlign(nums: number[]): number {
  const s = nums.slice().sort((a, b) => a - b);
  const m = s[Math.floor(s.length / 2)];
  let t = 0;
  for (const x of nums) t += Math.abs(x - m);
  return t;
}

// Age-bucket exponential population: each timer resets to 6 and spawns an 8 at zero.
export function genAgeBuckets(rng: Rng): PuzzleInstance {
  const D = rng.range(120, 220);
  const n = rng.range(300, 600);
  const timers = Array.from({ length: n }, () => rng.int(9));
  return { input: `${D}\n${timers.join(",")}`, expected: String(agePop(timers, D)) };
}

function agePop(timers: number[], D: number): number {
  const b = new Array(9).fill(0);
  for (const t of timers) b[t]++;
  for (let d = 0; d < D; d++) {
    const z = b[0];
    for (let i = 0; i < 8; i++) b[i] = b[i + 1];
    b[6] += z; b[8] = z;
  }
  return b.reduce((a, c) => a + c, 0);
}

// Bingo: first board to complete a row or column; score = sum unmarked * last draw.
export function genBingo(rng: Rng): PuzzleInstance {
  const pool = Array.from({ length: 100 }, (_, i) => i);
  for (let i = pool.length - 1; i > 0; i--) { const j = rng.int(i + 1); [pool[i], pool[j]] = [pool[j], pool[i]]; }
  const draws = pool.slice();
  const B = rng.range(6, 12);
  const boardBlocks: string[] = [];
  for (let bi = 0; bi < B; bi++) {
    const nums = Array.from({ length: 100 }, (_, i) => i);
    for (let i = nums.length - 1; i > 0; i--) { const j = rng.int(i + 1); [nums[i], nums[j]] = [nums[j], nums[i]]; }
    const cells = nums.slice(0, 25);
    const rowsTxt: string[] = [];
    for (let r = 0; r < 5; r++) {
      rowsTxt.push(cells.slice(r * 5, r * 5 + 5).map((v) => String(v).padStart(2, " ")).join(" "));
    }
    boardBlocks.push(rowsTxt.join("\n"));
  }
  const input = `${draws.join(",")}\n\n${boardBlocks.join("\n\n")}`;
  return { input, expected: String(bingoScore(input)) };
}

function bingoScore(text: string): number {
  const parts = text.trim().split("\n\n");
  const draws = parts[0].split(",").map(Number);
  const boards = parts.slice(1).map((b) => b.trim().split("\n").map((row) => row.trim().split(/\s+/).map(Number)));
  const marked = boards.map(() => Array.from({ length: 5 }, () => new Array(5).fill(false)));
  const wins = (bi: number) => {
    for (let i = 0; i < 5; i++) {
      if (marked[bi][i].every(Boolean)) return true;
      if ([0, 1, 2, 3, 4].every((j) => marked[bi][j][i])) return true;
    }
    return false;
  };
  for (const d of draws) {
    for (let bi = 0; bi < boards.length; bi++)
      for (let r = 0; r < 5; r++) for (let c = 0; c < 5; c++) if (boards[bi][r][c] === d) marked[bi][r][c] = true;
    for (let bi = 0; bi < boards.length; bi++) {
      if (wins(bi)) {
        let unmarked = 0;
        for (let r = 0; r < 5; r++) for (let c = 0; c < 5; c++) if (!marked[bi][r][c]) unmarked += boards[bi][r][c];
        return unmarked * d;
      }
    }
  }
  return -1;
}

// Fold a sheet of dots along the given lines; expected = distinct dots remaining.
export function genPaperFold(rng: Rng): PuzzleInstance {
  const a = rng.range(15, 25), b = rng.range(15, 25);
  const n = rng.range(150, 300);
  const seen = new Set<string>();
  const coordLines: string[] = [];
  for (let i = 0; i < n; i++) {
    const x = rng.int(2 * a + 1), y = rng.int(2 * b + 1);
    const key = `${x},${y}`;
    if (seen.has(key)) continue;
    seen.add(key);
    coordLines.push(key);
  }
  const input = `${coordLines.join("\n")}\n\nfold along y=${b}\nfold along x=${a}`;
  return { input, expected: String(foldDots(input)) };
}

function foldDots(text: string): number {
  const parts = text.trim().split("\n\n");
  let dots = new Set<string>();
  for (const line of parts[0].trim().split("\n")) dots.add(line);
  const folds = parts[1].trim().split("\n").map((l) => {
    const m = l.match(/fold along ([xy])=(\d+)/)!;
    return [m[1], Number(m[2])] as [string, number];
  });
  for (const [axis, a] of folds) {
    const next = new Set<string>();
    for (const key of dots) {
      let [x, y] = key.split(",").map(Number);
      if (axis === "x" && x > a) x = 2 * a - x;
      if (axis === "y" && y > a) y = 2 * a - y;
      next.add(`${x},${y}`);
    }
    dots = next;
  }
  return dots.size;
}

// Syntax scoring: first illegal closing bracket per line scores points; sum them.
export function genSyntaxScore(rng: Rng): PuzzleInstance {
  const openers = ["(", "[", "{", "<"];
  const closerOf: Record<string, string> = { "(": ")", "[": "]", "{": "}", "<": ">" };
  const n = rng.range(60, 120);
  const lines: string[] = [];
  for (let i = 0; i < n; i++) {
    // Build a well-nested sequence, then maybe corrupt it with a wrong closer.
    const stack: string[] = [];
    let s = "";
    const len = rng.range(10, 40);
    for (let k = 0; k < len; k++) {
      const openBias = stack.length === 0 || (stack.length < 8 && rng.next() < 0.6);
      if (openBias) { const o = rng.pick(openers); stack.push(o); s += o; }
      else { s += closerOf[stack.pop()!]; }
    }
    if (rng.next() < 0.6 && stack.length >= 0) {
      // corrupt: append a wrong closer somewhere by replacing next expected
      const wrong = rng.pick([")", "]", "}", ">"]);
      s += wrong;
    } else {
      while (stack.length) s += closerOf[stack.pop()!];
    }
    lines.push(s);
  }
  return { input: lines.join("\n"), expected: String(syntaxScore(lines.join("\n"))) };
}

function syntaxScore(text: string): number {
  const pairs: Record<string, string> = { ")": "(", "]": "[", "}": "{", ">": "<" };
  const pts: Record<string, number> = { ")": 3, "]": 57, "}": 1197, ">": 25137 };
  let total = 0;
  for (const line of text.trim().split("\n")) {
    const st: string[] = [];
    for (const ch of line) {
      if ("([{<".includes(ch)) st.push(ch);
      else if (st.pop() !== pairs[ch]) { total += pts[ch]; break; }
    }
  }
  return total;
}

// Reactor reboot: apply on/off cuboids clamped to [-50,50]; count lit cells.
export function genReactorReboot(rng: Rng): PuzzleInstance {
  const n = rng.range(40, 80);
  const lines: string[] = [];
  for (let i = 0; i < n; i++) {
    const state = rng.next() < 0.65 ? "on" : "off";
    const span = () => { const a = rng.range(-50, 45); const b = a + rng.range(1, 20); return [a, Math.min(b, 50)]; };
    const [x1, x2] = span(), [y1, y2] = span(), [z1, z2] = span();
    lines.push(`${state} x=${x1}..${x2},y=${y1}..${y2},z=${z1}..${z2}`);
  }
  const input = lines.join("\n");
  return { input, expected: String(reactorLit(input)) };
}

function reactorLit(text: string): number {
  const on = new Set<string>();
  for (const line of text.trim().split("\n")) {
    const m = line.match(/(on|off) x=(-?\d+)\.\.(-?\d+),y=(-?\d+)\.\.(-?\d+),z=(-?\d+)\.\.(-?\d+)/)!;
    const state = m[1] === "on";
    let [x1, x2, y1, y2, z1, z2] = m.slice(2).map(Number);
    x1 = Math.max(x1, -50); x2 = Math.min(x2, 50);
    y1 = Math.max(y1, -50); y2 = Math.min(y2, 50);
    z1 = Math.max(z1, -50); z2 = Math.min(z2, 50);
    for (let x = x1; x <= x2; x++) for (let y = y1; y <= y2; y++) for (let z = z1; z <= z2; z++) {
      const key = `${x},${y},${z}`;
      if (state) on.add(key); else on.delete(key);
    }
  }
  return on.size;
}

// Count paths from start to end where small (lowercase) caves are visited once.
export function genCavePaths(rng: Rng): PuzzleInstance {
  const smalls = ["a", "b", "c", "d", "e", "f", "g", "h"].slice(0, rng.range(6, 8));
  const bigs = ["A", "B", "C"].slice(0, rng.range(2, 3));
  const nodes = ["start", ...smalls, ...bigs, "end"];
  const edgeSet = new Set<string>();
  const addEdge = (u: string, v: string) => {
    if (u === v) return;
    if (/[A-Z]/.test(u) && /[A-Z]/.test(v)) return; // never connect two big caves
    const key = [u, v].sort().join("-");
    edgeSet.add(key);
  };
  // Guarantee a route: start -> smalls chain -> end.
  addEdge("start", smalls[0]);
  for (let i = 0; i + 1 < smalls.length; i++) addEdge(smalls[i], smalls[i + 1]);
  addEdge(smalls[smalls.length - 1], "end");
  // Sprinkle extra edges for branching.
  const extra = rng.range(10, 16);
  for (let i = 0; i < extra; i++) addEdge(rng.pick(nodes), rng.pick(nodes));
  const lines = [...edgeSet];
  for (let i = lines.length - 1; i > 0; i--) { const j = rng.int(i + 1); [lines[i], lines[j]] = [lines[j], lines[i]]; }
  const input = lines.join("\n");
  return { input, expected: String(cavePaths(input)) };
}

function cavePaths(text: string): number {
  const adj: Record<string, string[]> = {};
  for (const line of text.trim().split("\n")) {
    const [a, b] = line.split("-");
    (adj[a] ||= []).push(b);
    (adj[b] ||= []).push(a);
  }
  const small = (n: string) => n === n.toLowerCase();
  let count = 0;
  const walk = (node: string, visited: Set<string>) => {
    if (node === "end") { count++; return; }
    for (const nx of adj[node] || []) {
      if (small(nx) && visited.has(nx)) continue;
      const nv = new Set(visited);
      if (small(nx)) nv.add(nx);
      walk(nx, nv);
    }
  };
  walk("start", new Set(["start"]));
  return count;
}

// ===== Act IV expansion — The Hidden Layer (d10) =====

// 3D cellular life (Conway cubes): active if 2-3 active neighbours (or 3 for
// inactive); expected = active cells after 6 cycles.
export function genConwayCubes(rng: Rng): PuzzleInstance {
  const H = rng.range(12, 16), W = rng.range(12, 16);
  const rows: string[] = [];
  for (let y = 0; y < H; y++) {
    let r = "";
    for (let x = 0; x < W; x++) r += rng.next() < 0.35 ? "#" : ".";
    rows.push(r);
  }
  const input = rows.join("\n");
  return { input, expected: String(conwayActive(input)) };
}

function conwayActive(text: string): number {
  const rows = text.trim().split("\n");
  let active = new Set<string>();
  for (let y = 0; y < rows.length; y++) for (let x = 0; x < rows[y].length; x++) if (rows[y][x] === "#") active.add(`${x},${y},0`);
  for (let c = 0; c < 6; c++) {
    const counts = new Map<string, number>();
    for (const key of active) {
      const [x, y, z] = key.split(",").map(Number);
      for (let dx = -1; dx <= 1; dx++) for (let dy = -1; dy <= 1; dy++) for (let dz = -1; dz <= 1; dz++) {
        if (dx === 0 && dy === 0 && dz === 0) continue;
        const k = `${x + dx},${y + dy},${z + dz}`;
        counts.set(k, (counts.get(k) || 0) + 1);
      }
    }
    const next = new Set<string>();
    for (const [k, n] of counts) {
      const on = active.has(k);
      if (on && (n === 2 || n === 3)) next.add(k);
      else if (!on && n === 3) next.add(k);
    }
    active = next;
  }
  return active.size;
}

// Grid of energy levels; each step all rise by 1, cells over 9 flash and boost
// neighbours (chain reaction), then reset to 0. Expected = total flashes / 100 steps.
export function genOctoFlash(rng: Rng): PuzzleInstance {
  const H = rng.range(12, 16), W = rng.range(12, 16);
  const rows: string[] = [];
  for (let y = 0; y < H; y++) {
    let r = "";
    for (let x = 0; x < W; x++) r += String(rng.int(10));
    rows.push(r);
  }
  const input = rows.join("\n");
  return { input, expected: String(octoFlashes(input)) };
}

function octoFlashes(text: string): number {
  const g = text.trim().split("\n").map((r) => r.split("").map(Number));
  const H = g.length, W = g[0].length;
  let flashes = 0;
  for (let step = 0; step < 100; step++) {
    for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) g[y][x]++;
    const flashed = Array.from({ length: H }, () => new Array(W).fill(false));
    let changed = true;
    while (changed) {
      changed = false;
      for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
        if (g[y][x] > 9 && !flashed[y][x]) {
          flashed[y][x] = true; flashes++; changed = true;
          for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
            const ny = y + dy, nx = x + dx;
            if (ny >= 0 && ny < H && nx >= 0 && nx < W && !(dy === 0 && dx === 0)) g[ny][nx]++;
          }
        }
      }
    }
    for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) if (flashed[y][x]) g[y][x] = 0;
  }
  return flashes;
}

// Longest-weight path from node 0 to node N-1 in a DAG (edges go low->high).
export function genDagLongest(rng: Rng): PuzzleInstance {
  const N = rng.range(30, 60);
  const edges: string[] = [];
  for (let i = 0; i + 1 < N; i++) edges.push(`${i} ${i + 1} ${rng.range(1, 20)}`);
  const extra = rng.range(N, 2 * N);
  for (let i = 0; i < extra; i++) {
    const u = rng.int(N - 1);
    const v = u + 1 + rng.int(N - 1 - u);
    edges.push(`${u} ${v} ${rng.range(1, 20)}`);
  }
  for (let i = edges.length - 1; i > 0; i--) { const j = rng.int(i + 1); [edges[i], edges[j]] = [edges[j], edges[i]]; }
  const input = `${N}\n${edges.join("\n")}`;
  return { input, expected: String(dagLongest(input)) };
}

function dagLongest(text: string): number {
  const lines = text.trim().split("\n");
  const N = Number(lines[0]);
  const adj: [number, number][][] = Array.from({ length: N }, () => []);
  for (const l of lines.slice(1)) {
    const [u, v, w] = l.split(" ").map(Number);
    adj[u].push([v, w]);
  }
  const dp = new Array(N).fill(-Infinity);
  dp[0] = 0;
  for (let u = 0; u < N; u++) {
    if (dp[u] === -Infinity) continue;
    for (const [v, w] of adj[u]) dp[v] = Math.max(dp[v], dp[u] + w);
  }
  return dp[N - 1];
}

// Arithmetic where + and * share precedence, evaluated left to right (parens
// first). Expected = sum of every line's value.
export function genMathEval(rng: Rng): PuzzleInstance {
  const n = rng.range(30, 60);
  const lines: string[] = [];
  for (let i = 0; i < n; i++) {
    const leaves = rng.range(6, 11);
    lines.push(buildExpr(rng, leaves));
  }
  const input = lines.join("\n");
  return { input, expected: String(mathSum(input)) };
}

function buildExpr(rng: Rng, leaves: number): string {
  if (leaves <= 1) return String(rng.range(1, 9));
  const left = rng.range(1, leaves - 1);
  const right = leaves - left;
  const l = buildExpr(rng, left);
  const r = buildExpr(rng, right);
  const op = rng.next() < 0.5 ? " + " : " * ";
  const ls = left >= 2 && rng.next() < 0.5 ? `(${l})` : l;
  const rs = right >= 2 && rng.next() < 0.5 ? `(${r})` : r;
  return ls + op + rs;
}

function evalFlat(line: string): number {
  let i = 0;
  const parse = (): number => {
    let val: number | null = null, op = "+";
    while (i < line.length) {
      const ch = line[i];
      if (ch === " ") { i++; continue; }
      if (ch === ")") { i++; break; }
      let v: number;
      if (ch === "(") { i++; v = parse(); }
      else if (ch >= "0" && ch <= "9") { let num = ""; while (i < line.length && line[i] >= "0" && line[i] <= "9") { num += line[i]; i++; } v = Number(num); }
      else { op = ch; i++; continue; }
      val = val === null ? v : (op === "+" ? val + v : val * v);
    }
    return val ?? 0;
  };
  return parse();
}

function mathSum(text: string): number {
  let t = 0;
  for (const line of text.trim().split("\n")) t += evalFlat(line);
  return t;
}

// Union-find: count connected groups among N nodes given a list of links.
export function genUnionFind(rng: Rng): PuzzleInstance {
  const N = rng.range(40, 90);
  const m = rng.range(20, N);
  const edges: string[] = [];
  for (let i = 0; i < m; i++) {
    const a = rng.int(N);
    let b = rng.int(N);
    while (b === a) b = rng.int(N);
    edges.push(`${a} ${b}`);
  }
  const input = `${N}\n${edges.join("\n")}`;
  return { input, expected: String(countComponents(input)) };
}

function countComponents(text: string): number {
  const lines = text.trim().split("\n");
  const N = Number(lines[0]);
  const parent = Array.from({ length: N }, (_, i) => i);
  const find = (x: number): number => { while (parent[x] !== x) { parent[x] = parent[parent[x]]; x = parent[x]; } return x; };
  for (const l of lines.slice(1)) {
    if (!l.trim()) continue;
    const [a, b] = l.split(" ").map(Number);
    parent[find(a)] = find(b);
  }
  let c = 0;
  for (let i = 0; i < N; i++) if (find(i) === i) c++;
  return c;
}

// Seven-segment: count output words that have a unique segment count (digits
// 1, 4, 7, 8 -> lengths 2, 4, 3, 7).
export function genSevenSeg(rng: Rng): PuzzleInstance {
  const segs: Record<number, string> = {
    0: "abcefg", 1: "cf", 2: "acdeg", 3: "acdfg", 4: "bcdf",
    5: "abdfg", 6: "abdefg", 7: "acf", 8: "abcdefg", 9: "abcdfg",
  };
  const n = rng.range(30, 60);
  const lines: string[] = [];
  for (let i = 0; i < n; i++) {
    const base = "abcdefg".split("");
    const perm = base.slice();
    for (let k = perm.length - 1; k > 0; k--) { const j = rng.int(k + 1); [perm[k], perm[j]] = [perm[j], perm[k]]; }
    const map: Record<string, string> = {};
    for (let k = 0; k < 7; k++) map[base[k]] = perm[k];
    const encode = (d: number) => {
      const letters = segs[d].split("").map((c) => map[c]);
      for (let k = letters.length - 1; k > 0; k--) { const j = rng.int(k + 1); [letters[k], letters[j]] = [letters[j], letters[k]]; }
      return letters.join("");
    };
    const signalDigits = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    for (let k = signalDigits.length - 1; k > 0; k--) { const j = rng.int(k + 1); [signalDigits[k], signalDigits[j]] = [signalDigits[j], signalDigits[k]]; }
    const signals = signalDigits.map(encode).join(" ");
    const outputs = Array.from({ length: 4 }, () => encode(rng.int(10))).join(" ");
    lines.push(`${signals} | ${outputs}`);
  }
  const input = lines.join("\n");
  return { input, expected: String(sevenSegCount(input)) };
}

function sevenSegCount(text: string): number {
  let count = 0;
  for (const line of text.trim().split("\n")) {
    const out = line.split("|")[1].trim().split(/\s+/);
    for (const w of out) if ([2, 3, 4, 7].includes(w.length)) count++;
  }
  return count;
}

// Polymer collapse: adjacent same-letter opposite-case pairs annihilate;
// expected = length of the fully reduced string.
export function genPolymerCollapse(rng: Rng): PuzzleInstance {
  const len = rng.range(600, 1500);
  let s = "";
  for (let i = 0; i < len; i++) {
    const letter = String.fromCharCode(97 + rng.int(8));
    s += rng.next() < 0.5 ? letter : letter.toUpperCase();
  }
  return { input: s, expected: String(polymerLength(s)) };
}

function polymerLength(text: string): number {
  const s = text.trim();
  const st: string[] = [];
  for (const ch of s) {
    const top = st[st.length - 1];
    if (top && top !== ch && top.toLowerCase() === ch.toLowerCase()) st.pop();
    else st.push(ch);
  }
  return st.length;
}

// ===== Act V expansion — The Last Forge (all d10) =====

const signed = (n: number): string => (n >= 0 ? `+${n}` : `${n}`);

// Handheld halting: a program of acc/jmp/nop; return acc just before any
// instruction runs a second time. Every jmp is kept in-range and the last
// instruction is always a jmp, so the program can never halt — a loop is
// guaranteed and the answer is well defined.
export function genHandheldHalt(rng: Rng): PuzzleInstance {
  const N = rng.range(24, 44);
  const ops: string[] = [];
  for (let i = 0; i < N; i++) {
    const forceJmp = i === N - 1;
    const kind = forceJmp ? 2 : rng.int(3); // 0 nop, 1 acc, 2 jmp
    if (kind === 0) ops.push(`nop ${signed(rng.range(-9, 9))}`);
    else if (kind === 1) ops.push(`acc ${signed(rng.range(-5, 5))}`);
    else {
      let o = rng.range(-i, N - 1 - i); // keep i + o inside [0, N-1]
      if (o === 0) o = i < N - 1 ? 1 : -1;
      ops.push(`jmp ${signed(o)}`);
    }
  }
  const input = ops.join("\n");
  return { input, expected: String(handheldAcc(input)) };
}

function handheldAcc(text: string): number {
  const prog = text.trim().split("\n").map((l) => {
    const [op, a] = l.split(" ");
    return { op, a: Number(a) };
  });
  const seen = new Set<number>();
  let ip = 0, acc = 0;
  while (ip < prog.length && !seen.has(ip)) {
    seen.add(ip);
    const { op, a } = prog[ip];
    if (op === "acc") { acc += a; ip++; }
    else if (op === "jmp") { ip += a; }
    else ip++;
  }
  return acc;
}

// Smoke basins: flood-fill regions of non-9 cells; product of the three largest.
export function genSmokeBasins(rng: Rng): PuzzleInstance {
  const R = rng.range(10, 14), C = rng.range(10, 14);
  const rows: string[] = [];
  for (let i = 0; i < R; i++) {
    let row = "";
    for (let j = 0; j < C; j++) row += rng.next() < 0.4 ? "9" : String(rng.int(9));
    rows.push(row);
  }
  const input = rows.join("\n");
  return { input, expected: String(basinProduct(input)) };
}

function basinProduct(text: string): number {
  const grid = text.trim().split("\n").map((r) => r.split("").map(Number));
  const R = grid.length, C = grid[0].length;
  const seen = Array.from({ length: R }, () => new Array(C).fill(false));
  const sizes: number[] = [];
  for (let i = 0; i < R; i++) for (let j = 0; j < C; j++) {
    if (grid[i][j] === 9 || seen[i][j]) continue;
    let size = 0;
    const stack: [number, number][] = [[i, j]];
    seen[i][j] = true;
    while (stack.length) {
      const [y, x] = stack.pop()!;
      size++;
      for (const [dy, dx] of [[1, 0], [-1, 0], [0, 1], [0, -1]] as const) {
        const ny = y + dy, nx = x + dx;
        if (ny >= 0 && ny < R && nx >= 0 && nx < C && !seen[ny][nx] && grid[ny][nx] !== 9) {
          seen[ny][nx] = true;
          stack.push([ny, nx]);
        }
      }
    }
    sizes.push(size);
  }
  sizes.sort((a, b) => b - a);
  return sizes.slice(0, 3).reduce((a, b) => a * b, 1);
}

// Adapter chain: count the distinct arrangements of adapters that connect the
// outlet (0) to the device (max + 3) using steps of 1..3. Uses BigInt.
export function genAdapterChain(rng: Rng): PuzzleInstance {
  const n = rng.range(40, 70);
  let cur = 0;
  const adapters: number[] = [];
  for (let i = 0; i < n; i++) {
    cur += rng.range(1, 3);
    adapters.push(cur);
  }
  const shuffled = adapters.slice();
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = rng.int(i + 1);
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }
  return { input: shuffled.join(","), expected: adapterArrangements(shuffled).toString() };
}

function adapterArrangements(nums: number[]): bigint {
  const arr = nums.slice().sort((a, b) => a - b);
  const device = arr[arr.length - 1] + 3;
  const all = [0, ...arr, device];
  const ways = new Map<number, bigint>();
  ways.set(0, 1n);
  for (let i = 1; i < all.length; i++) {
    const v = all[i];
    let w = 0n;
    for (let d = 1; d <= 3; d++) if (ways.has(v - d)) w += ways.get(v - d)!;
    ways.set(v, w);
  }
  return ways.get(device)!;
}

// Docking data: apply a 36-bit mask (X keeps, 0/1 force) to each written value
// and sum everything left in memory.
export function genDockingMask(rng: Rng): PuzzleInstance {
  const blocks = rng.range(4, 8);
  const lines: string[] = [];
  for (let b = 0; b < blocks; b++) {
    let mask = "";
    for (let i = 0; i < 36; i++) {
      const r = rng.int(4); // 0->1, 1->0, else X (roughly half X)
      mask += r === 0 ? "1" : r === 1 ? "0" : "X";
    }
    lines.push(`mask = ${mask}`);
    const writes = rng.range(2, 5);
    for (let w = 0; w < writes; w++) {
      lines.push(`mem[${rng.int(100000)}] = ${rng.int(100000)}`);
    }
  }
  const input = lines.join("\n");
  return { input, expected: dockingSum(input) };
}

function dockingSum(text: string): string {
  const mem = new Map<number, number>();
  let mask = "";
  for (const line of text.trim().split("\n")) {
    if (line.startsWith("mask")) { mask = line.split(" = ")[1]; continue; }
    const m = line.match(/mem\[(\d+)\] = (\d+)/)!;
    const bin = Number(m[2]).toString(2).padStart(36, "0");
    let out = "";
    for (let i = 0; i < 36; i++) out += mask[i] === "X" ? bin[i] : mask[i];
    mem.set(Number(m[1]), parseInt(out, 2));
  }
  let sum = 0;
  for (const v of mem.values()) sum += v;
  return String(sum);
}

// Waypoint navigation: a waypoint (starting 10 east, 1 north) is moved and
// rotated; F moves the ship toward it. Return the ship's Manhattan distance.
export function genWaypointNav(rng: Rng): PuzzleInstance {
  const n = rng.range(30, 80);
  const acts = ["N", "S", "E", "W", "L", "R", "F"] as const;
  const lines: string[] = [];
  for (let i = 0; i < n; i++) {
    const a = rng.pick(acts);
    const v = a === "L" || a === "R" ? rng.pick([90, 180, 270]) : rng.range(1, 12);
    lines.push(`${a}${v}`);
  }
  const input = lines.join("\n");
  return { input, expected: String(waypointDist(input)) };
}

function waypointDist(text: string): number {
  let sx = 0, sy = 0, wx = 10, wy = 1;
  for (const line of text.trim().split("\n")) {
    const a = line[0];
    const v = Number(line.slice(1));
    if (a === "N") wy += v;
    else if (a === "S") wy -= v;
    else if (a === "E") wx += v;
    else if (a === "W") wx -= v;
    else if (a === "F") { sx += wx * v; sy += wy * v; }
    else {
      let times = (v / 90) % 4;
      if (a === "R") times = (4 - times) % 4;
      for (let t = 0; t < times; t++) { const nx = -wy, ny = wx; wx = nx; wy = ny; }
    }
  }
  return Math.abs(sx) + Math.abs(sy);
}

// Crossing vents: horizontal, vertical, and 45-degree lines; count grid points
// covered by at least two lines.
export function genVentOverlaps(rng: Rng): PuzzleInstance {
  const n = rng.range(150, 300);
  const M = 200;
  const lines: string[] = [];
  for (let i = 0; i < n; i++) {
    const x1 = rng.int(M), y1 = rng.int(M);
    const kind = rng.int(3); // 0 horiz, 1 vert, 2 diagonal
    const len = rng.range(1, 12);
    let x2 = x1, y2 = y1;
    if (kind === 0) x2 = clampM(x1 + (rng.next() < 0.5 ? len : -len), M);
    else if (kind === 1) y2 = clampM(y1 + (rng.next() < 0.5 ? len : -len), M);
    else {
      const dx = rng.next() < 0.5 ? 1 : -1;
      const dy = rng.next() < 0.5 ? 1 : -1;
      const maxX = dx > 0 ? M - 1 - x1 : x1;
      const maxY = dy > 0 ? M - 1 - y1 : y1;
      const L = Math.min(len, maxX, maxY);
      x2 = x1 + dx * L;
      y2 = y1 + dy * L;
    }
    lines.push(`${x1},${y1} -> ${x2},${y2}`);
  }
  const input = lines.join("\n");
  return { input, expected: String(ventOverlaps(input)) };
}

function clampM(v: number, M: number): number {
  return Math.max(0, Math.min(M - 1, v));
}

function ventOverlaps(text: string): number {
  const grid = new Map<string, number>();
  for (const line of text.trim().split("\n")) {
    const [p1, p2] = line.split(" -> ");
    const [x1, y1] = p1.split(",").map(Number);
    const [x2, y2] = p2.split(",").map(Number);
    const dx = Math.sign(x2 - x1), dy = Math.sign(y2 - y1);
    const steps = Math.max(Math.abs(x2 - x1), Math.abs(y2 - y1));
    for (let s = 0; s <= steps; s++) {
      const k = `${x1 + dx * s},${y1 + dy * s}`;
      grid.set(k, (grid.get(k) || 0) + 1);
    }
  }
  let count = 0;
  for (const v of grid.values()) if (v >= 2) count++;
  return count;
}

// Sea cucumbers: east herd then south herd move each step; return the first
// step on which nothing moves.
export function genSeaCucumber(rng: Rng): PuzzleInstance {
  // Some random configurations oscillate forever on the torus (e.g. a ">.>." row
  // with even width), so the automaton never settles. Regenerate until we get a
  // grid that provably halts within a generous cap. This stays deterministic per
  // seed because every draw comes from the same rng sequence.
  const CAP = 1000;
  for (let attempt = 0; attempt < 200; attempt++) {
    const R = rng.range(12, 16), C = rng.range(12, 16);
    const rows: string[] = [];
    for (let i = 0; i < R; i++) {
      let row = "";
      for (let j = 0; j < C; j++) {
        const r = rng.next();
        row += r < 0.25 ? ">" : r < 0.45 ? "v" : ".";
      }
      rows.push(row);
    }
    const input = rows.join("\n");
    const steps = seaSteps(input, CAP);
    if (steps > 0) return { input, expected: String(steps) };
    // Non-halting grid: fall through and draw a fresh one from the rng.
  }
  // Fallback (astronomically unlikely): an empty grid settles on step 1.
  const R = rng.range(12, 16), C = rng.range(12, 16);
  const input = Array.from({ length: R }, () => ".".repeat(C)).join("\n");
  return { input, expected: String(seaSteps(input, CAP)) };
}

/** Steps until nothing moves. Returns -1 if it does not settle within `cap`. */
function seaSteps(text: string, cap = 100000): number {
  let grid = text.trim().split("\n").map((r) => r.split(""));
  const R = grid.length, C = grid[0].length;
  let step = 0;
  while (step < cap) {
    step++;
    let moved = false;
    let ng = grid.map((r) => r.slice());
    for (let i = 0; i < R; i++) for (let j = 0; j < C; j++) {
      if (grid[i][j] === ">" && grid[i][(j + 1) % C] === ".") { ng[i][j] = "."; ng[i][(j + 1) % C] = ">"; moved = true; }
    }
    grid = ng;
    ng = grid.map((r) => r.slice());
    for (let i = 0; i < R; i++) for (let j = 0; j < C; j++) {
      if (grid[i][j] === "v" && grid[(i + 1) % R][j] === ".") { ng[i][j] = "."; ng[(i + 1) % R][j] = "v"; moved = true; }
    }
    grid = ng;
    if (!moved) return step;
  }
  return -1;
}
