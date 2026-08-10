import type { PuzzleInstance } from "../../engine/types";
import type { Rng } from "../../engine/rng";

// ---------------------------------------------------------------------------
// "Under the Trees" — 2D polyomino packing (an Advent-of-Code-hardest puzzle).
//
// Generation is CONSTRUCTION-BASED so the answer is known without any expensive
// search: fittable regions are built by actually packing pieces (a packing
// therefore provably exists); unfittable regions are built by overfilling area
// (provably impossible). This keeps per-player generation instant and always
// correct. The reference solver (shipped as the js/py solution) is a real
// packing solver, validated by the fixed AoC worked example (answer 2), which
// includes an area-feasible-but-unpackable region — so a pure area check fails
// the example and the true algorithm is required.
// ---------------------------------------------------------------------------

type Cell = [number, number];

function normalize(cells: Cell[]): Cell[] {
  let mR = Infinity, mC = Infinity;
  for (const [r, c] of cells) { if (r < mR) mR = r; if (c < mC) mC = c; }
  const s = cells.map(([r, c]) => [r - mR, c - mC] as Cell);
  s.sort((a, b) => a[0] - b[0] || a[1] - b[1]);
  return s;
}
const keyOf = (cells: Cell[]) => cells.map(([r, c]) => r + "," + c).join(";");

function orientations(cells: Cell[]): Cell[][] {
  const seen = new Map<string, Cell[]>();
  for (let ref = 0; ref < 2; ref++) {
    let work: Cell[] = ref === 0 ? cells : cells.map(([r, c]) => [r, -c] as Cell);
    for (let rot = 0; rot < 4; rot++) {
      work = work.map(([r, c]) => [c, -r] as Cell);
      const n = normalize(work);
      seen.set(keyOf(n), n);
    }
  }
  return [...seen.values()];
}

/** A connected shape inside a 3x3 box, 4–6 cells. */
function randShape(rng: Rng): Cell[] {
  const size = rng.range(4, 6);
  const cells = new Set<number>([rng.int(3) * 3 + rng.int(3)]);
  let guard = 0;
  while (cells.size < size && guard++ < 60) {
    const arr = [...cells];
    const base = arr[rng.int(arr.length)];
    const br = Math.floor(base / 3), bc = base % 3;
    const dirs: Cell[] = [[1, 0], [-1, 0], [0, 1], [0, -1]];
    const [dr, dc] = dirs[rng.int(4)];
    const nr = br + dr, nc = bc + dc;
    if (nr >= 0 && nr < 3 && nc >= 0 && nc < 3) cells.add(nr * 3 + nc);
  }
  return normalize([...cells].map((i) => [Math.floor(i / 3), i % 3] as Cell));
}

function shapeDiagram(cells: Cell[]): string {
  let maxR = 0, maxC = 0;
  for (const [r, c] of cells) { if (r > maxR) maxR = r; if (c > maxC) maxC = c; }
  const filled = new Set(cells.map(([r, c]) => r + "," + c));
  const rows: string[] = [];
  for (let r = 0; r <= maxR; r++) {
    let row = "";
    for (let c = 0; c <= maxC; c++) row += filled.has(r + "," + c) ? "#" : ".";
    rows.push(row);
  }
  return rows.join("\n");
}

/** Build a region that is packable by construction: place pieces that fit. */
function buildFittable(
  rng: Rng,
  shapeOrients: Cell[][][],
  areas: number[],
  W: number,
  H: number,
  targetFill: number,
): number[] {
  const grid = new Uint8Array(W * H);
  const counts = [0, 0, 0, 0, 0, 0];
  let placedArea = 0;
  let attempts = 0;
  const goal = targetFill * W * H;
  while (placedArea < goal && attempts++ < 500) {
    const t = rng.int(6);
    const orient = rng.pick(shapeOrients[t]);
    let maxR = 0, maxC = 0;
    for (const [r, c] of orient) { if (r > maxR) maxR = r; if (c > maxC) maxC = c; }
    if (maxR >= H || maxC >= W) continue;
    const top = rng.int(H - maxR);
    const left = rng.int(W - maxC);
    let ok = true;
    for (const [r, c] of orient) if (grid[(top + r) * W + (left + c)] !== 0) { ok = false; break; }
    if (!ok) continue;
    for (const [r, c] of orient) grid[(top + r) * W + (left + c)] = 1;
    counts[t]++;
    placedArea += areas[t];
  }
  return counts;
}

export function generatePacking(rng: Rng): PuzzleInstance {
  const shapes: Cell[][] = [];
  for (let i = 0; i < 6; i++) shapes.push(randShape(rng));
  const shapeOrients = shapes.map(orientations);
  const areas = shapes.map((s) => s.length);

  const shapeSection = shapes.map((s, i) => `${i}:\n${shapeDiagram(s)}`).join("\n\n");

  const regionLines: string[] = [];
  let fittable = 0;
  const N = rng.range(36, 48);
  for (let n = 0; n < N; n++) {
    const W = rng.range(6, 12);
    const H = rng.range(6, 12);
    const cap = W * H;
    const makeFittable = rng.next() < 0.55;
    const counts = buildFittable(rng, shapeOrients, areas, W, H, makeFittable ? 0.7 : 0.85);

    if (makeFittable) {
      fittable++;
    } else {
      // Overfill area → provably unpackable.
      let area = counts.reduce((s, c, i) => s + c * areas[i], 0);
      while (area <= cap) {
        const t = rng.int(6);
        counts[t]++;
        area += areas[t];
      }
    }
    regionLines.push(`${W}x${H}: ${counts.join(" ")}`);
  }

  return {
    input: `${shapeSection}\n\n${regionLines.join("\n")}`,
    expected: String(fittable),
  };
}

/** Self-contained JS reference: parse → orientations → MRV exact-cover pack → count. */
export const PACKING_JS = `function solve(text) {
  const lines = text.split("\\n");
  const shapes = [];
  const regions = [];
  let i = 0;
  while (i < lines.length) {
    const line = lines[i];
    if (/^\\d+:\\s*$/.test(line)) {
      i++;
      const cells = [];
      let r = 0;
      while (i < lines.length && /[#.]/.test(lines[i]) && !/^\\d+x\\d+:/.test(lines[i])) {
        const row = lines[i];
        for (let c = 0; c < row.length; c++) if (row[c] === "#") cells.push([r, c]);
        r++; i++;
      }
      shapes.push(cells);
    } else if (/^\\d+x\\d+:/.test(line)) {
      const [dim, rest] = line.split(":");
      const [W, H] = dim.split("x").map(Number);
      const counts = rest.trim().split(/\\s+/).map(Number);
      regions.push({ W, H, counts });
      i++;
    } else i++;
  }
  const norm = (cs) => {
    let mR = 1e9, mC = 1e9;
    for (const [r, c] of cs) { if (r < mR) mR = r; if (c < mC) mC = c; }
    return cs.map(([r, c]) => [r - mR, c - mC]).sort((a, b) => a[0] - b[0] || a[1] - b[1]);
  };
  const keyf = (cs) => cs.map(([r, c]) => r + "," + c).join(";");
  const orients = (cells) => {
    const m = new Map();
    for (let ref = 0; ref < 2; ref++) {
      let w = ref === 0 ? cells : cells.map(([r, c]) => [r, -c]);
      for (let rot = 0; rot < 4; rot++) { w = w.map(([r, c]) => [c, -r]); const n = norm(w); m.set(keyf(n), n); }
    }
    return [...m.values()];
  };
  const shapeOr = shapes.map(orients);
  const areas = shapes.map((s) => s.length);

  function canPack(W, H, counts0) {
    const cap = W * H;
    let realArea = 0;
    for (let t = 0; t < counts0.length; t++) realArea += counts0[t] * areas[t];
    let fillers = cap - realArea;
    if (fillers < 0) return false;
    const placements = [];
    const cover = Array.from({ length: cap }, () => []);
    for (let t = 0; t < counts0.length; t++) {
      if (counts0[t] === 0) continue;
      for (const o of shapeOr[t]) {
        let maxR = 0, maxC = 0;
        for (const [r, c] of o) { if (r > maxR) maxR = r; if (c > maxC) maxC = c; }
        for (let top = 0; top + maxR < H; top++) for (let left = 0; left + maxC < W; left++) {
          const idxs = o.map(([r, c]) => (top + r) * W + (left + c));
          const pi = placements.length; placements.push({ t, idxs });
          for (const id of idxs) cover[id].push(pi);
        }
      }
    }
    const counts = counts0.slice();
    const grid = new Uint8Array(cap);
    let freeCount = cap;
    function rec() {
      if (freeCount === 0) return true;
      let bestCell = -1, bestOpts = 1e9, bestList = null;
      for (let cell = 0; cell < cap; cell++) {
        if (grid[cell] !== 0) continue;
        let opts = fillers > 0 ? 1 : 0;
        const list = [];
        for (const pi of cover[cell]) {
          const p = placements[pi];
          if (counts[p.t] === 0) continue;
          let ok = true;
          for (const id of p.idxs) if (grid[id] !== 0) { ok = false; break; }
          if (ok) { opts++; list.push(pi); }
        }
        if (opts < bestOpts) { bestOpts = opts; bestCell = cell; bestList = list; if (opts === 0) break; }
      }
      if (bestOpts === 0) return false;
      for (const pi of bestList) {
        const p = placements[pi];
        for (const id of p.idxs) grid[id] = 1;
        counts[p.t]--; freeCount -= p.idxs.length;
        if (rec()) return true;
        for (const id of p.idxs) grid[id] = 0;
        counts[p.t]++; freeCount += p.idxs.length;
      }
      if (fillers > 0) {
        grid[bestCell] = 1; fillers--; freeCount--;
        if (rec()) return true;
        grid[bestCell] = 0; fillers++; freeCount++;
      }
      return false;
    }
    return rec();
  }

  let fit = 0;
  for (const reg of regions) if (canPack(reg.W, reg.H, reg.counts)) fit++;
  return fit;
}
`;

/** Self-contained Python reference (mirror of the JS solver). */
export const PACKING_PY = `def solve(text):
    import re
    lines = text.split("\\n")
    shapes = []
    regions = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if re.match(r"^\\d+:\\s*$", line):
            i += 1
            cells = []
            r = 0
            while i < len(lines) and re.search(r"[#.]", lines[i]) and not re.match(r"^\\d+x\\d+:", lines[i]):
                row = lines[i]
                for c, ch in enumerate(row):
                    if ch == "#":
                        cells.append((r, c))
                r += 1
                i += 1
            shapes.append(cells)
        elif re.match(r"^\\d+x\\d+:", line):
            dim, rest = line.split(":")
            w, h = (int(x) for x in dim.split("x"))
            counts = [int(x) for x in rest.split()]
            regions.append((w, h, counts))
            i += 1
        else:
            i += 1

    def norm(cs):
        mr = min(r for r, _ in cs); mc = min(c for _, c in cs)
        return sorted((r - mr, c - mc) for r, c in cs)

    def orients(cells):
        seen = {}
        w = cells
        for ref in range(2):
            w = cells if ref == 0 else [(r, -c) for r, c in cells]
            for _ in range(4):
                w = [(c, -r) for r, c in w]
                n = norm(w)
                seen[tuple(n)] = n
        return list(seen.values())

    shape_or = [orients(s) for s in shapes]
    areas = [len(s) for s in shapes]

    def can_pack(W, H, counts0):
        cap = W * H
        real = sum(counts0[t] * areas[t] for t in range(len(counts0)))
        fillers = [cap - real]
        if fillers[0] < 0:
            return False
        placements = []
        cover = [[] for _ in range(cap)]
        for t in range(len(counts0)):
            if counts0[t] == 0:
                continue
            for o in shape_or[t]:
                maxr = max(r for r, _ in o); maxc = max(c for _, c in o)
                for top in range(H - maxr):
                    for left in range(W - maxc):
                        idxs = [(top + r) * W + (left + c) for r, c in o]
                        pi = len(placements)
                        placements.append((t, idxs))
                        for idc in idxs:
                            cover[idc].append(pi)
        counts = list(counts0)
        grid = bytearray(cap)
        free = [cap]

        def rec():
            if free[0] == 0:
                return True
            best_cell = -1; best_opts = 1 << 30; best_list = None
            for cell in range(cap):
                if grid[cell] != 0:
                    continue
                opts = 1 if fillers[0] > 0 else 0
                lst = []
                for pi in cover[cell]:
                    t, idxs = placements[pi]
                    if counts[t] == 0:
                        continue
                    if all(grid[idc] == 0 for idc in idxs):
                        opts += 1; lst.append(pi)
                if opts < best_opts:
                    best_opts = opts; best_cell = cell; best_list = lst
                    if opts == 0:
                        break
            if best_opts == 0:
                return False
            for pi in best_list:
                t, idxs = placements[pi]
                for idc in idxs: grid[idc] = 1
                counts[t] -= 1; free[0] -= len(idxs)
                if rec():
                    return True
                for idc in idxs: grid[idc] = 0
                counts[t] += 1; free[0] += len(idxs)
            if fillers[0] > 0:
                grid[best_cell] = 1; fillers[0] -= 1; free[0] -= 1
                if rec():
                    return True
                grid[best_cell] = 0; fillers[0] += 1; free[0] += 1
            return False

        return rec()

    return sum(1 for (W, H, counts) in regions if can_pack(W, H, counts))
`;

// The real Advent-of-Code worked example (answer 2) — the fixed, hand-checkable
// case shown in the prompt. Its third region is area-feasible but unpackable.
export const PACKING_EXAMPLE: PuzzleInstance = {
  input: [
    "0:", "###", "##.", "##.", "",
    "1:", "###", "##.", ".##", "",
    "2:", ".##", "###", "##.", "",
    "3:", "##.", "###", "##.", "",
    "4:", "###", "#..", "###", "",
    "5:", "###", ".#.", "###", "",
    "4x4: 0 0 0 0 2 0",
    "12x5: 1 0 1 0 2 2",
    "12x5: 1 0 1 0 3 2",
  ].join("\n"),
  expected: "2",
};
