import type { PuzzleInstance, Language } from "../../engine/types";
import type { Rng } from "../../engine/rng";

/**
 * Genuine Advent-of-Code-caliber puzzles: the story defines a system, the input
 * is an artifact of it, and the task is a non-obvious multi-step process. Each
 * puzzle bundles its per-player `generate`, both reference solvers, and a fixed
 * worked example. Generators cross-checked against the JS solver by the tests.
 */
export interface Puzzle {
  generate: (rng: Rng) => PuzzleInstance;
  solution: Record<Language, string>;
  example: PuzzleInstance;
}

// ---------------------------------------------------------------------------
// The Boot Loop — a handheld VM that loops forever; report the accumulator the
// instant an instruction is about to run a second time. (acc/jmp/nop ±N.)
// ---------------------------------------------------------------------------
export const BOOT_LOOP: Puzzle = {
  example: {
    input: "nop +0\nacc +1\njmp +4\nacc +3\njmp -3\nacc -99\nacc +1\njmp -4\nacc +6",
    expected: "5",
  },
  solution: {
    javascript: `function solve(text) {
  const prog = text.trim().split("\\n").map((l) => {
    const [op, arg] = l.split(/\\s+/);
    return [op, Number(arg)];
  });
  let pc = 0, acc = 0;
  const seen = new Set();
  while (pc < prog.length && !seen.has(pc)) {
    seen.add(pc);
    const [op, arg] = prog[pc];
    if (op === "acc") { acc += arg; pc++; }
    else if (op === "jmp") { pc += arg; }
    else pc++;
  }
  return acc;
}
`,
    python: `def solve(text):
    prog = []
    for line in text.strip().split("\\n"):
        op, arg = line.split()
        prog.append((op, int(arg)))
    pc, acc = 0, 0
    seen = set()
    while 0 <= pc < len(prog) and pc not in seen:
        seen.add(pc)
        op, arg = prog[pc]
        if op == "acc":
            acc += arg
            pc += 1
        elif op == "jmp":
            pc += arg
        else:
            pc += 1
    return acc
`,
  },
  generate: (rng) => {
    const run = (prog: [string, number][]) => {
      let pc = 0, acc = 0;
      const seen = new Set<number>();
      let steps = 0;
      while (pc >= 0 && pc < prog.length && steps++ < 100000) {
        if (seen.has(pc)) return acc; // looped
        seen.add(pc);
        const [op, arg] = prog[pc];
        if (op === "acc") { acc += arg; pc++; }
        else if (op === "jmp") { pc += arg; }
        else pc++;
      }
      return null; // terminated or ran off the end — no loop
    };
    for (let attempt = 0; attempt < 200; attempt++) {
      const n = rng.range(30, 80);
      const prog: [string, number][] = [];
      for (let i = 0; i < n; i++) {
        const op = rng.pick(["acc", "jmp", "nop", "acc", "nop"]);
        const arg = op === "jmp" ? rng.range(-6, 6) : rng.range(-9, 9);
        prog.push([op, arg]);
      }
      const acc = run(prog);
      if (acc !== null) {
        const input = prog.map(([op, arg]) => `${op} ${arg >= 0 ? "+" : ""}${arg}`).join("\n");
        return { input, expected: String(acc) };
      }
    }
    // Fallback: a guaranteed tiny loop (extremely unlikely to be needed).
    return { input: "acc +3\njmp -1", expected: "3" };
  },
};

// ---------------------------------------------------------------------------
// Cooling Overlaps — each line assigns two drones a section (a range). Count
// the pairs whose sections overlap at all (share at least one cell).
// ---------------------------------------------------------------------------
export const SECTION_OVERLAPS: Puzzle = {
  example: {
    input: "2-4,6-8\n2-3,4-5\n5-7,7-9\n2-8,3-7\n6-6,4-6\n2-6,4-8",
    expected: "4",
  },
  solution: {
    javascript: `function solve(text) {
  let count = 0;
  for (const line of text.trim().split("\\n")) {
    const [l, r] = line.split(",");
    const [a, b] = l.split("-").map(Number);
    const [c, d] = r.split("-").map(Number);
    if (a <= d && c <= b) count++;
  }
  return count;
}
`,
    python: `def solve(text):
    count = 0
    for line in text.strip().split("\\n"):
        l, r = line.split(",")
        a, b = (int(x) for x in l.split("-"))
        c, d = (int(x) for x in r.split("-"))
        if a <= d and c <= b:
            count += 1
    return count
`,
  },
  generate: (rng) => {
    const n = rng.range(40, 90);
    const lines: string[] = [];
    let count = 0;
    for (let k = 0; k < n; k++) {
      const a = rng.range(1, 90), b = a + rng.range(0, 9);
      const c = rng.range(1, 90), d = c + rng.range(0, 9);
      lines.push(`${a}-${b},${c}-${d}`);
      if (a <= d && c <= b) count++;
    }
    return { input: lines.join("\n"), expected: String(count) };
  },
};

// ---------------------------------------------------------------------------
// Signal Lock — a stream of symbols. Return the position (1-based, of the last
// character) of the first run of 4 all-distinct characters in a row.
// ---------------------------------------------------------------------------
export const SIGNAL_LOCK: Puzzle = {
  example: {
    input: "mjqjpqmgbljsphdztnvjfqwrcgsmlb",
    expected: "7",
  },
  solution: {
    javascript: `function solve(text) {
  const s = text.trim();
  const K = 4;
  for (let i = K; i <= s.length; i++) {
    if (new Set(s.slice(i - K, i)).size === K) return i;
  }
  return -1;
}
`,
    python: `def solve(text):
    s = text.strip()
    K = 4
    for i in range(K, len(s) + 1):
        if len(set(s[i - K:i])) == K:
            return i
    return -1
`,
  },
  generate: (rng) => {
    const alphabet = "abcdef";
    const len = rng.range(400, 900);
    let s = "";
    for (let i = 0; i < len; i++) s += alphabet[rng.int(alphabet.length)];
    let ans = -1;
    for (let i = 4; i <= s.length; i++) {
      if (new Set(s.slice(i - 4, i)).size === 4) { ans = i; break; }
    }
    // Guarantee a marker exists (append one if the random stream had none).
    if (ans === -1) { s += "abcd"; ans = s.length; }
    return { input: s, expected: String(ans) };
  },
};

// ---------------------------------------------------------------------------
// Rope Drag — the crane's head moves by steps; the tail follows (stepping
// diagonally to stay adjacent). Count the distinct cells the tail visits.
// ---------------------------------------------------------------------------
export const ROPE_DRAG: Puzzle = {
  example: {
    input: "R 4\nU 4\nL 3\nD 1\nR 4\nD 1\nL 5\nR 2",
    expected: "13",
  },
  solution: {
    javascript: `function solve(text) {
  const dirs = { R: [1, 0], L: [-1, 0], U: [0, 1], D: [0, -1] };
  let hx = 0, hy = 0, tx = 0, ty = 0;
  const seen = new Set(["0,0"]);
  const sign = (n) => (n > 0 ? 1 : n < 0 ? -1 : 0);
  for (const line of text.trim().split("\\n")) {
    const [d, nStr] = line.split(/\\s+/);
    const [dx, dy] = dirs[d];
    const n = Number(nStr);
    for (let s = 0; s < n; s++) {
      hx += dx; hy += dy;
      if (Math.abs(hx - tx) > 1 || Math.abs(hy - ty) > 1) {
        tx += sign(hx - tx); ty += sign(hy - ty);
        seen.add(tx + "," + ty);
      }
    }
  }
  return seen.size;
}
`,
    python: `def solve(text):
    dirs = {"R": (1, 0), "L": (-1, 0), "U": (0, 1), "D": (0, -1)}
    hx = hy = tx = ty = 0
    seen = {(0, 0)}
    sign = lambda n: (n > 0) - (n < 0)
    for line in text.strip().split("\\n"):
        d, n = line.split()
        dx, dy = dirs[d]
        for _ in range(int(n)):
            hx += dx
            hy += dy
            if abs(hx - tx) > 1 or abs(hy - ty) > 1:
                tx += sign(hx - tx)
                ty += sign(hy - ty)
                seen.add((tx, ty))
    return len(seen)
`,
  },
  generate: (rng) => {
    const dirs = ["R", "L", "U", "D"];
    const n = rng.range(30, 70);
    const lines: string[] = [];
    for (let k = 0; k < n; k++) lines.push(`${rng.pick(dirs)} ${rng.range(1, 9)}`);
    // Compute the answer with the same rules.
    const D: Record<string, [number, number]> = { R: [1, 0], L: [-1, 0], U: [0, 1], D: [0, -1] };
    let hx = 0, hy = 0, tx = 0, ty = 0;
    const seen = new Set(["0,0"]);
    const sign = (v: number) => (v > 0 ? 1 : v < 0 ? -1 : 0);
    for (const line of lines) {
      const [d, s] = line.split(" ");
      const [dx, dy] = D[d];
      const steps = Number(s);
      for (let i = 0; i < steps; i++) {
        hx += dx; hy += dy;
        if (Math.abs(hx - tx) > 1 || Math.abs(hy - ty) > 1) {
          tx += sign(hx - tx); ty += sign(hy - ty);
          seen.add(tx + "," + ty);
        }
      }
    }
    return { input: lines.join("\n"), expected: String(seen.size) };
  },
};

// ---------------------------------------------------------------------------
// The Filesystem — replay a terminal session (cd/ls) to learn each directory's
// total size, then sum the sizes of all directories that are ≤ 100000.
// ---------------------------------------------------------------------------
export const FILESYSTEM: Puzzle = {
  example: {
    input: [
      "$ cd /", "$ ls", "dir a", "14848514 b.txt", "8504156 c.dat", "dir d",
      "$ cd a", "$ ls", "dir e", "29116 f", "2557 g", "62596 h.lst",
      "$ cd e", "$ ls", "584 i", "$ cd ..", "$ cd ..",
      "$ cd d", "$ ls", "4060174 j", "8033020 d.log", "5626152 d.ext", "7214296 k",
    ].join("\n"),
    expected: "95437",
  },
  solution: {
    javascript: `function solve(text) {
  const sizes = {};
  const stack = [];
  for (const line of text.trim().split("\\n")) {
    if (line === "$ cd /") stack.length = 0, stack.push("/");
    else if (line === "$ cd ..") stack.pop();
    else if (line.startsWith("$ cd ")) stack.push(line.slice(5));
    else if (line === "$ ls" || line.startsWith("dir ")) continue;
    else {
      const size = Number(line.split(" ")[0]);
      for (let i = 0; i < stack.length; i++) {
        const key = stack.slice(0, i + 1).join("/");
        sizes[key] = (sizes[key] || 0) + size;
      }
    }
  }
  let total = 0;
  for (const k in sizes) if (sizes[k] <= 100000) total += sizes[k];
  return total;
}
`,
    python: `def solve(text):
    sizes = {}
    stack = []
    for line in text.strip().split("\\n"):
        if line == "$ cd /":
            stack = ["/"]
        elif line == "$ cd ..":
            stack.pop()
        elif line.startswith("$ cd "):
            stack.append(line[5:])
        elif line == "$ ls" or line.startswith("dir "):
            continue
        else:
            size = int(line.split(" ")[0])
            for i in range(len(stack)):
                key = "/".join(stack[:i + 1])
                sizes[key] = sizes.get(key, 0) + size
    return sum(s for s in sizes.values() if s <= 100000)
`,
  },
  generate: (rng) => {
    interface Node { files: number[]; dirs: Record<string, Node>; }
    const make = (depth: number): Node => {
      const node: Node = { files: [], dirs: {} };
      for (let i = 0, n = rng.range(1, 4); i < n; i++) node.files.push(rng.range(1000, 90000));
      if (depth < 3) for (let i = 0, n = rng.range(1, 3); i < n; i++) {
        node.dirs["d" + depth + "x" + i] = make(depth + 1);
      }
      return node;
    };
    const root = make(0);
    const lines = ["$ cd /"];
    const emit = (node: Node) => {
      lines.push("$ ls");
      for (const name in node.dirs) lines.push("dir " + name);
      for (const size of node.files) lines.push(size + " f" + size + ".txt");
      for (const name in node.dirs) { lines.push("$ cd " + name); emit(node.dirs[name]); lines.push("$ cd .."); }
    };
    emit(root);
    const totals: number[] = [];
    const total = (node: Node): number => {
      let sum = node.files.reduce((a, b) => a + b, 0);
      for (const name in node.dirs) sum += total(node.dirs[name]);
      totals.push(sum);
      return sum;
    };
    total(root);
    return { input: lines.join("\n"), expected: String(totals.filter((s) => s <= 100000).reduce((a, b) => a + b, 0)) };
  },
};

// ---------------------------------------------------------------------------
// Beacon Line — each sensor reaches a Manhattan radius (distance to its beacon).
// On one scan row, count cells within reach of at least one sensor (merge the
// per-sensor intervals).
// ---------------------------------------------------------------------------
export const BEACON_LINE: Puzzle = {
  example: { input: "10\n8 7 2 10\n0 11 2 10", expected: "17" },
  solution: {
    javascript: `function solve(text) {
  const lines = text.trim().split("\\n");
  const Y = Number(lines[0]);
  const intervals = [];
  for (let i = 1; i < lines.length; i++) {
    const [sx, sy, bx, by] = lines[i].split(/\\s+/).map(Number);
    const r = Math.abs(sx - bx) + Math.abs(sy - by);
    const reach = r - Math.abs(sy - Y);
    if (reach >= 0) intervals.push([sx - reach, sx + reach]);
  }
  intervals.sort((a, b) => a[0] - b[0]);
  let count = 0, cur = null;
  for (const iv of intervals) {
    if (cur && iv[0] <= cur[1] + 1) cur[1] = Math.max(cur[1], iv[1]);
    else { if (cur) count += cur[1] - cur[0] + 1; cur = iv.slice(); }
  }
  if (cur) count += cur[1] - cur[0] + 1;
  return count;
}
`,
    python: `def solve(text):
    lines = text.strip().split("\\n")
    Y = int(lines[0])
    intervals = []
    for line in lines[1:]:
        sx, sy, bx, by = (int(v) for v in line.split())
        r = abs(sx - bx) + abs(sy - by)
        reach = r - abs(sy - Y)
        if reach >= 0:
            intervals.append([sx - reach, sx + reach])
    intervals.sort()
    count = 0
    cur = None
    for iv in intervals:
        if cur and iv[0] <= cur[1] + 1:
            cur[1] = max(cur[1], iv[1])
        else:
            if cur:
                count += cur[1] - cur[0] + 1
            cur = list(iv)
    if cur:
        count += cur[1] - cur[0] + 1
    return count
`,
  },
  generate: (rng) => {
    const Y = rng.range(0, 40);
    const lines = [String(Y)];
    const n = rng.range(12, 24);
    for (let i = 0; i < n; i++) {
      const sx = rng.range(-40, 40), sy = rng.range(-10, 50);
      const bx = sx + rng.range(-12, 12), by = sy + rng.range(-12, 12);
      lines.push(`${sx} ${sy} ${bx} ${by}`);
    }
    const input = lines.join("\n");
    // Compute with the same logic.
    const intervals: number[][] = [];
    for (let i = 1; i < lines.length; i++) {
      const [sx, sy, bx, by] = lines[i].split(/\s+/).map(Number);
      const r = Math.abs(sx - bx) + Math.abs(sy - by);
      const reach = r - Math.abs(sy - Y);
      if (reach >= 0) intervals.push([sx - reach, sx + reach]);
    }
    intervals.sort((a, b) => a[0] - b[0]);
    let count = 0;
    let cur: number[] | null = null;
    for (const iv of intervals) {
      if (cur && iv[0] <= cur[1] + 1) cur[1] = Math.max(cur[1], iv[1]);
      else { if (cur) count += cur[1] - cur[0] + 1; cur = iv.slice(); }
    }
    if (cur) count += cur[1] - cur[0] + 1;
    return { input, expected: String(count) };
  },
};

// ---------------------------------------------------------------------------
// Tree Line — a grid of tree heights (0–9). Count trees visible from outside:
// a tree is visible if every tree between it and an edge (in any of the four
// directions) is strictly shorter.
// ---------------------------------------------------------------------------
export const TREE_LINE: Puzzle = {
  example: { input: "30373\n25512\n65332\n33549\n35390", expected: "21" },
  solution: {
    javascript: `function solve(text) {
  const g = text.trim().split("\\n").map((r) => r.split("").map(Number));
  const H = g.length, W = g[0].length;
  let count = 0;
  for (let y = 0; y < H; y++)
    for (let x = 0; x < W; x++) {
      const h = g[y][x];
      let vis = false;
      let ok = true;
      for (let i = 0; i < x; i++) if (g[y][i] >= h) { ok = false; break; }
      if (ok) vis = true;
      ok = true;
      for (let i = x + 1; i < W; i++) if (g[y][i] >= h) { ok = false; break; }
      if (ok) vis = true;
      ok = true;
      for (let i = 0; i < y; i++) if (g[i][x] >= h) { ok = false; break; }
      if (ok) vis = true;
      ok = true;
      for (let i = y + 1; i < H; i++) if (g[i][x] >= h) { ok = false; break; }
      if (ok) vis = true;
      if (vis) count++;
    }
  return count;
}
`,
    python: `def solve(text):
    g = [[int(c) for c in row] for row in text.strip().split("\\n")]
    H, W = len(g), len(g[0])
    count = 0
    for y in range(H):
        for x in range(W):
            h = g[y][x]
            vis = (
                all(g[y][i] < h for i in range(0, x))
                or all(g[y][i] < h for i in range(x + 1, W))
                or all(g[i][x] < h for i in range(0, y))
                or all(g[i][x] < h for i in range(y + 1, H))
            )
            if vis:
                count += 1
    return count
`,
  },
  generate: (rng) => {
    const W = rng.range(12, 20), H = rng.range(12, 20);
    const rows: string[] = [];
    for (let y = 0; y < H; y++) {
      let row = "";
      for (let x = 0; x < W; x++) row += rng.int(10);
      rows.push(row);
    }
    const g = rows.map((r) => r.split("").map(Number));
    let count = 0;
    for (let y = 0; y < H; y++)
      for (let x = 0; x < W; x++) {
        const h = g[y][x];
        let vis = false;
        const dirs: [number, number][] = [[0, -1], [0, 1], [-1, 0], [1, 0]];
        for (const [dy, dx] of dirs) {
          let ok = true;
          let ny = y + dy, nx = x + dx;
          while (ny >= 0 && ny < H && nx >= 0 && nx < W) {
            if (g[ny][nx] >= h) { ok = false; break; }
            ny += dy; nx += dx;
          }
          if (ok) { vis = true; break; }
        }
        if (vis) count++;
      }
    return { input: rows.join("\n"), expected: String(count) };
  },
};

// ---------------------------------------------------------------------------
// Syntax Scoring — each line of brackets ()[]{}<> is either incomplete or
// corrupted. Find the FIRST bracket that closes the wrong type on each line,
// score it (3/57/1197/25137), and sum those scores.
// ---------------------------------------------------------------------------
export const SYNTAX_SCORING: Puzzle = {
  example: {
    input: [
      "[({(<(())[]>[[{[]{<()<>>", "[(()[<>])]({[<{<<[]>>(", "{([(<{}[<>[]}>{[]{[(<()>",
      "(((({<>}<{<{<>}{[]{[]{}", "[[<[([]))<([[{}[[()]]]", "[{[{({}]{}}([{[{{{}}([]",
      "{<[[]]>}<{[{[{[]{()[[[]", "[<(<(<(<{}))><([]([]()", "<{([([[(<>()){}]>(<<{{",
      "<{([{{}}[<[[[<>{}]]]>[]]",
    ].join("\n"),
    expected: "26397",
  },
  solution: {
    javascript: `function solve(text) {
  const pair = { ")": "(", "]": "[", "}": "{", ">": "<" };
  const score = { ")": 3, "]": 57, "}": 1197, ">": 25137 };
  let total = 0;
  for (const line of text.trim().split("\\n")) {
    const st = [];
    for (const c of line) {
      if (c === "(" || c === "[" || c === "{" || c === "<") st.push(c);
      else if (st.pop() !== pair[c]) { total += score[c]; break; }
    }
  }
  return total;
}
`,
    python: `def solve(text):
    pair = {")": "(", "]": "[", "}": "{", ">": "<"}
    score = {")": 3, "]": 57, "}": 1197, ">": 25137}
    total = 0
    for line in text.strip().split("\\n"):
        st = []
        for c in line:
            if c in "([{<":
                st.append(c)
            else:
                if not st or st.pop() != pair[c]:
                    total += score[c]
                    break
    return total
`,
  },
  generate: (rng) => {
    const opens = "([{<", closes = ")]}>";
    const close: Record<string, string> = { "(": ")", "[": "]", "{": "}", "<": ">" };
    const build = (depth: number): string => {
      if (depth <= 0 || rng.next() < 0.4) return "";
      let s = "";
      for (let g = 0, n = rng.range(1, 3); g < n; g++) {
        const o = opens[rng.int(4)];
        s += o + build(depth - 1) + close[o];
      }
      return s;
    };
    const lines: string[] = [];
    for (let i = 0, n = rng.range(12, 24); i < n; i++) {
      let line = build(rng.range(3, 6)) || "()";
      if (rng.next() < 0.55) {
        const idxs: number[] = [];
        for (let j = 0; j < line.length; j++) if (closes.includes(line[j])) idxs.push(j);
        if (idxs.length) {
          const j = rng.pick(idxs);
          let wrong = closes[rng.int(4)];
          while (wrong === line[j]) wrong = closes[rng.int(4)];
          line = line.slice(0, j) + wrong + line.slice(j + 1);
        }
      }
      lines.push(line);
    }
    const pair: Record<string, string> = { ")": "(", "]": "[", "}": "{", ">": "<" };
    const score: Record<string, number> = { ")": 3, "]": 57, "}": 1197, ">": 25137 };
    let total = 0;
    for (const line of lines) {
      const st: string[] = [];
      for (const c of line) {
        if (c === "(" || c === "[" || c === "{" || c === "<") st.push(c);
        else if (st.pop() !== pair[c]) { total += score[c]; break; }
      }
    }
    return { input: lines.join("\n"), expected: String(total) };
  },
};

// ---------------------------------------------------------------------------
// The Loading Crane — parse a drawing of crate stacks and a list of moves, run
// the crane (one crate at a time), and read the crate now on top of each stack.
// ---------------------------------------------------------------------------
export const SUPPLY_STACKS: Puzzle = {
  example: {
    input: "    [D]    \n[N] [C]    \n[Z] [M] [P]\n 1   2   3 \n\nmove 1 from 2 to 1\nmove 3 from 1 to 3\nmove 2 from 2 to 1\nmove 1 from 1 to 2",
    expected: "CMZ",
  },
  solution: {
    javascript: `function solve(text) {
  const [drawing, moves] = text.split("\\n\\n");
  const lines = drawing.split("\\n");
  const labels = lines[lines.length - 1].trim().split(/\\s+/);
  const cols = labels.length;
  const stacks = Array.from({ length: cols }, () => []);
  for (let r = lines.length - 2; r >= 0; r--) {
    for (let c = 0; c < cols; c++) {
      const ch = lines[r][1 + c * 4];
      if (ch && ch !== " ") stacks[c].push(ch);
    }
  }
  for (const mv of moves.trim().split("\\n")) {
    const m = mv.match(/move (\\d+) from (\\d+) to (\\d+)/);
    const n = +m[1], from = +m[2] - 1, to = +m[3] - 1;
    for (let k = 0; k < n; k++) {
      const x = stacks[from].pop();
      if (x !== undefined) stacks[to].push(x);
    }
  }
  return stacks.map((s) => s[s.length - 1] || "").join("");
}
`,
    python: `def solve(text):
    import re
    drawing, moves = text.split("\\n\\n")
    lines = drawing.split("\\n")
    cols = len(lines[-1].split())
    stacks = [[] for _ in range(cols)]
    for r in range(len(lines) - 2, -1, -1):
        for c in range(cols):
            idx = 1 + c * 4
            ch = lines[r][idx] if idx < len(lines[r]) else " "
            if ch != " ":
                stacks[c].append(ch)
    for mv in moves.strip().split("\\n"):
        m = re.match(r"move (\\d+) from (\\d+) to (\\d+)", mv)
        n, frm, to = int(m.group(1)), int(m.group(2)) - 1, int(m.group(3)) - 1
        for _ in range(n):
            if stacks[frm]:
                stacks[to].append(stacks[frm].pop())
    return "".join(s[-1] if s else "" for s in stacks)
`,
  },
  generate: (rng) => {
    const cols = rng.range(3, 6);
    const letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    const stacks: string[][] = [];
    for (let c = 0; c < cols; c++) {
      const h = rng.range(3, 8);
      const st: string[] = [];
      for (let i = 0; i < h; i++) st.push(letters[rng.int(26)]);
      stacks.push(st);
    }
    const maxH = Math.max(...stacks.map((s) => s.length));
    const drawing: string[] = [];
    for (let level = maxH - 1; level >= 0; level--) {
      let line = "";
      for (let c = 0; c < cols; c++) {
        const seg = level < stacks[c].length ? `[${stacks[c][level]}]` : "   ";
        line += (c === 0 ? "" : " ") + seg;
      }
      drawing.push(line);
    }
    let labelLine = "";
    for (let c = 0; c < cols; c++) labelLine += (c === 0 ? "" : " ") + ` ${c + 1} `;

    // Simulate valid moves on a working copy → the result is the answer.
    const work = stacks.map((s) => s.slice());
    const moveLines: string[] = [];
    const M = rng.range(25, 60);
    for (let m = 0; m < M; m++) {
      const nonEmpty = work.map((s, i) => (s.length ? i : -1)).filter((i) => i >= 0);
      if (nonEmpty.length === 0) break;
      const from = rng.pick(nonEmpty);
      let to = rng.int(cols);
      if (to === from) to = (to + 1) % cols;
      const n = rng.range(1, work[from].length);
      moveLines.push(`move ${n} from ${from + 1} to ${to + 1}`);
      for (let k = 0; k < n; k++) work[to].push(work[from].pop() as string);
    }
    const expected = work.map((s) => (s.length ? s[s.length - 1] : "")).join("");
    return {
      input: `${drawing.join("\n")}\n${labelLine}\n\n${moveLines.join("\n")}`,
      expected,
    };
  },
};
