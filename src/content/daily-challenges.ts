import type { Rng } from "../engine/rng";

export interface DailyChallenge {
  id: string;
  title: string;
  concept: string;
  prompt: string;
  input: string;
  expected: string;
  hints: string[];
  js: string;
  py: string;
  generate: (rng: Rng) => { input: string; expected: string };
}

/** First date a daily challenge is available. Index 0 = this date. */
export const DAILY_LAUNCH_DATE = "2026-08-10";

export const DAILY_CHALLENGES: DailyChallenge[] = [
  // ── Day 0 ──────────────────────────────────────────────────────────────────
  {
    id: "daily-word-freq",
    title: "Most Common Word",
    concept: "hash maps / frequency counting",
    prompt: `Given a list of words (one per line), return the word that appears most often.
If there's a tie, return the one that comes first alphabetically.

Example input:
apple
banana
apple
cherry
banana
apple

Example output:
apple`,
    input: "apple\nbanana\napple\ncherry\nbanana\napple",
    expected: "apple",
    hints: ["Use a dictionary/object to count occurrences.", "Sort alphabetically first, then find the max."],
    js: `function solve(text) {
  const words = text.trim().split("\\n");
  const freq = {};
  for (const w of words) freq[w] = (freq[w] || 0) + 1;
  return Object.keys(freq).sort().reduce((a, b) => freq[a] >= freq[b] ? a : b);
}`,
    py: `def solve(text):
    words = text.strip().split("\\n")
    freq = {}
    for w in words:
        freq[w] = freq.get(w, 0) + 1
    return sorted(freq, key=lambda w: (-freq[w], w))[0]`,
    generate(rng) {
      const pool = ["forge","ember","anvil","spark","flame","steel","iron","coal","coke","bloom","billet","ingot","mold","cast","smelt","quench","temper","alloy","flux","slag"];
      const chosen = [...pool].sort(() => rng.next() - 0.5).slice(0, 6);
      const winner = rng.pick(chosen);
      const lines: string[] = [];
      const counts: Record<string, number> = {};
      for (const w of chosen) { counts[w] = rng.range(1, 3); }
      counts[winner] = Math.max(...Object.values(counts)) + rng.range(1, 2);
      for (const [w, n] of Object.entries(counts)) for (let i = 0; i < n; i++) lines.push(w);
      lines.sort(() => rng.next() - 0.5);
      const freq: Record<string, number> = {};
      for (const w of lines) freq[w] = (freq[w] || 0) + 1;
      const expected = Object.keys(freq).sort().reduce((a, b) => freq[a] >= freq[b] ? a : b);
      return { input: lines.join("\n"), expected };
    },
  },

  // ── Day 1 ──────────────────────────────────────────────────────────────────
  {
    id: "daily-stock-profit",
    title: "Best Trade",
    concept: "single-pass min tracking",
    prompt: `Given a list of daily stock prices (one per line), return the maximum profit
you could make by buying once and selling once on a later day.
If no profit is possible, return 0.

Example input:
7
1
5
3
6
4

Example output:
5`,
    input: "7\n1\n5\n3\n6\n4",
    expected: "5",
    hints: ["Track the minimum price seen so far.", "At each step, check if selling today beats the current best profit."],
    js: `function solve(text) {
  const prices = text.trim().split("\\n").map(Number);
  let minPrice = Infinity, maxProfit = 0;
  for (const p of prices) {
    minPrice = Math.min(minPrice, p);
    maxProfit = Math.max(maxProfit, p - minPrice);
  }
  return String(maxProfit);
}`,
    py: `def solve(text):
    prices = list(map(int, text.strip().split("\\n")))
    min_price, max_profit = float('inf'), 0
    for p in prices:
        min_price = min(min_price, p)
        max_profit = max(max_profit, p - min_price)
    return str(max_profit)`,
    generate(rng) {
      const n = rng.range(6, 12);
      const prices = Array.from({ length: n }, () => rng.range(1, 100));
      let minP = Infinity, maxProfit = 0;
      for (const p of prices) { minP = Math.min(minP, p); maxProfit = Math.max(maxProfit, p - minP); }
      return { input: prices.join("\n"), expected: String(maxProfit) };
    },
  },

  // ── Day 2 ──────────────────────────────────────────────────────────────────
  {
    id: "daily-run-length",
    title: "Run-Length Decode",
    concept: "string parsing",
    prompt: `Decode a run-length encoded string. The format is pairs of (count)(char).
Return the expanded string.

Example input:
3a2b4c1d

Example output:
aaabbccccd`,
    input: "3a2b4c1d",
    expected: "aaabbccccd",
    hints: ["Walk through the string two characters at a time.", "The digit tells you how many times to repeat the next character."],
    js: `function solve(text) {
  const s = text.trim();
  let out = "";
  for (let i = 0; i < s.length; i += 2) out += s[i + 1].repeat(Number(s[i]));
  return out;
}`,
    py: `def solve(text):
    s = text.strip()
    return "".join(s[i+1] * int(s[i]) for i in range(0, len(s), 2))`,
    generate(rng) {
      const chars = "abcdefghijklmnop";
      const n = rng.range(4, 8);
      let input = "", expected = "";
      for (let i = 0; i < n; i++) {
        const count = rng.range(1, 5);
        const ch = chars[rng.int(chars.length)];
        input += `${count}${ch}`;
        expected += ch.repeat(count);
      }
      return { input, expected };
    },
  },

  // ── Day 3 ──────────────────────────────────────────────────────────────────
  {
    id: "daily-missing-number",
    title: "Missing Number",
    concept: "sum formula / sets",
    prompt: `Given n-1 distinct numbers from the range 1 to n (one per line), find the missing one.

Example input:
5
1
3
4
2
(that's n=5, and 5 numbers are given but one from 1..5 is missing — wait, here 4 lines give 1,3,4,2 missing 5)

Actually the first line is n, then n-1 numbers follow.

Example input:
5
1
3
4
2

Example output:
5`,
    input: "5\n1\n3\n4\n2",
    expected: "5",
    hints: ["Sum of 1..n is n*(n+1)/2.", "Subtract the sum of given numbers from the expected total."],
    js: `function solve(text) {
  const lines = text.trim().split("\\n").map(Number);
  const n = lines[0];
  const given = lines.slice(1);
  const expected = n * (n + 1) / 2;
  return String(expected - given.reduce((a, b) => a + b, 0));
}`,
    py: `def solve(text):
    lines = list(map(int, text.strip().split("\\n")))
    n = lines[0]
    return str(n * (n + 1) // 2 - sum(lines[1:]))`,
    generate(rng) {
      const n = rng.range(5, 15);
      const missing = rng.range(1, n);
      const nums = Array.from({ length: n }, (_, i) => i + 1).filter(x => x !== missing);
      nums.sort(() => rng.next() - 0.5);
      return { input: `${n}\n${nums.join("\n")}`, expected: String(missing) };
    },
  },

  // ── Day 4 ──────────────────────────────────────────────────────────────────
  {
    id: "daily-two-sum",
    title: "Pair Sum",
    concept: "hash set lookup",
    prompt: `Given a target number on the first line, then a list of integers (one per line),
find two numbers that add up to the target. Return them space-separated, smaller first.
There is always exactly one solution.

Example input:
9
2
7
11
15

Example output:
2 7`,
    input: "9\n2\n7\n11\n15",
    expected: "2 7",
    hints: ["For each number x, check if (target - x) is in a set of numbers you've seen.", "Build the set as you go."],
    js: `function solve(text) {
  const lines = text.trim().split("\\n").map(Number);
  const target = lines[0], nums = lines.slice(1);
  const seen = new Set();
  for (const n of nums) {
    const complement = target - n;
    if (seen.has(complement)) return [Math.min(n, complement), Math.max(n, complement)].join(" ");
    seen.add(n);
  }
}`,
    py: `def solve(text):
    lines = list(map(int, text.strip().split("\\n")))
    target, nums = lines[0], lines[1:]
    seen = set()
    for n in nums:
        c = target - n
        if c in seen:
            return f"{min(n,c)} {max(n,c)}"
        seen.add(n)`,
    generate(rng) {
      const a = rng.range(1, 50), b = rng.range(1, 50);
      const target = a + b;
      const decoys = Array.from({ length: rng.range(3, 7) }, () => rng.range(1, 99)).filter(x => x !== a && x !== b);
      const nums = [a, b, ...decoys].sort(() => rng.next() - 0.5);
      const small = Math.min(a, b), large = Math.max(a, b);
      return { input: `${target}\n${nums.join("\n")}`, expected: `${small} ${large}` };
    },
  },

  // ── Day 5 ──────────────────────────────────────────────────────────────────
  {
    id: "daily-climbing-stairs",
    title: "Staircase Ways",
    concept: "dynamic programming (Fibonacci variant)",
    prompt: `You're climbing a staircase. Each step you can climb 1 or 2 stairs.
Given n (the number of stairs), return how many distinct ways you can reach the top.

Example input:
5

Example output:
8`,
    input: "5",
    expected: "8",
    hints: ["Ways to reach step n = ways to reach step n-1 + ways to reach step n-2.", "This is the Fibonacci sequence starting from dp[1]=1, dp[2]=2."],
    js: `function solve(text) {
  const n = Number(text.trim());
  if (n <= 1) return "1";
  let a = 1, b = 2;
  for (let i = 3; i <= n; i++) [a, b] = [b, a + b];
  return String(b);
}`,
    py: `def solve(text):
    n = int(text.strip())
    if n <= 1: return "1"
    a, b = 1, 2
    for _ in range(3, n + 1):
        a, b = b, a + b
    return str(b)`,
    generate(rng) {
      const n = rng.range(3, 15);
      let a = 1, b = 2;
      for (let i = 3; i <= n; i++) { const t = a + b; a = b; b = t; }
      return { input: String(n), expected: String(n <= 1 ? 1 : b) };
    },
  },

  // ── Day 6 ──────────────────────────────────────────────────────────────────
  {
    id: "daily-house-robber",
    title: "House Robber",
    concept: "dynamic programming (non-adjacent sum)",
    prompt: `A row of houses has gold in each one (values given one per line).
You can't rob two adjacent houses. Return the maximum gold you can steal.

Example input:
2
7
9
3
1

Example output:
12`,
    input: "2\n7\n9\n3\n1",
    expected: "12",
    hints: ["dp[i] = max(dp[i-1], dp[i-2] + houses[i])", "You only need the last two values, not the full array."],
    js: `function solve(text) {
  const h = text.trim().split("\\n").map(Number);
  let prev2 = 0, prev1 = 0;
  for (const v of h) { const cur = Math.max(prev1, prev2 + v); prev2 = prev1; prev1 = cur; }
  return String(prev1);
}`,
    py: `def solve(text):
    h = list(map(int, text.strip().split("\\n")))
    prev2 = prev1 = 0
    for v in h:
        prev2, prev1 = prev1, max(prev1, prev2 + v)
    return str(prev1)`,
    generate(rng) {
      const n = rng.range(4, 10);
      const h = Array.from({ length: n }, () => rng.range(1, 20));
      let prev2 = 0, prev1 = 0;
      for (const v of h) { const cur = Math.max(prev1, prev2 + v); prev2 = prev1; prev1 = cur; }
      return { input: h.join("\n"), expected: String(prev1) };
    },
  },

  // ── Day 7 ──────────────────────────────────────────────────────────────────
  {
    id: "daily-roman-to-int",
    title: "Roman Numerals",
    concept: "lookup tables / left-to-right parsing",
    prompt: `Convert a Roman numeral string to an integer.
Symbols: I=1, V=5, X=10, L=50, C=100, D=500, M=1000.
A smaller value before a larger one means subtraction (e.g. IV=4, IX=9).

Example input:
MCMXCIV

Example output:
1994`,
    input: "MCMXCIV",
    expected: "1994",
    hints: ["If the current symbol is less than the next one, subtract it; otherwise add it.", "Process left to right."],
    js: `function solve(text) {
  const map = {I:1,V:5,X:10,L:50,C:100,D:500,M:1000};
  const s = text.trim();
  let total = 0;
  for (let i = 0; i < s.length; i++) {
    const cur = map[s[i]], next = map[s[i+1]] || 0;
    total += cur < next ? -cur : cur;
  }
  return String(total);
}`,
    py: `def solve(text):
    m = {'I':1,'V':5,'X':10,'L':50,'C':100,'D':500,'M':1000}
    s = text.strip()
    total = 0
    for i in range(len(s)):
        cur = m[s[i]]
        nxt = m[s[i+1]] if i+1 < len(s) else 0
        total += -cur if cur < nxt else cur
    return str(total)`,
    generate(rng) {
      const n = rng.range(1, 3999);
      const vals = [1000,900,500,400,100,90,50,40,10,9,5,4,1];
      const syms = ["M","CM","D","CD","C","XC","L","XL","X","IX","V","IV","I"];
      let rem = n, roman = "";
      for (let i = 0; i < vals.length; i++) while (rem >= vals[i]) { roman += syms[i]; rem -= vals[i]; }
      return { input: roman, expected: String(n) };
    },
  },

  // ── Day 8 ──────────────────────────────────────────────────────────────────
  {
    id: "daily-compress",
    title: "String Compress",
    concept: "run-length encoding",
    prompt: `Compress a string using run-length encoding: replace consecutive repeated characters
with the character followed by its count. If a character appears once, just write it (no "1").
If the compressed string isn't shorter, return the original.

Example input:
aabcccdddd

Example output:
a2bc3d4`,
    input: "aabcccdddd",
    expected: "a2bc3d4",
    hints: ["Walk through counting consecutive characters.", "Only append the count if it's greater than 1."],
    js: `function solve(text) {
  const s = text.trim();
  let out = "", i = 0;
  while (i < s.length) {
    let j = i;
    while (j < s.length && s[j] === s[i]) j++;
    out += s[i] + (j - i > 1 ? j - i : "");
    i = j;
  }
  return out.length < s.length ? out : s;
}`,
    py: `def solve(text):
    s = text.strip()
    out, i = "", 0
    while i < len(s):
        j = i
        while j < len(s) and s[j] == s[i]:
            j += 1
        out += s[i] + (str(j - i) if j - i > 1 else "")
        i = j
    return out if len(out) < len(s) else s`,
    generate(rng) {
      const chars = "abcdefghij";
      let s = "";
      const n = rng.range(5, 10);
      for (let i = 0; i < n; i++) s += chars[rng.int(chars.length)].repeat(rng.range(1, 5));
      // compute expected
      let out = "", k = 0;
      while (k < s.length) {
        let j = k;
        while (j < s.length && s[j] === s[k]) j++;
        out += s[k] + (j - k > 1 ? j - k : "");
        k = j;
      }
      const expected = out.length < s.length ? out : s;
      return { input: s, expected };
    },
  },

  // ── Day 9 ──────────────────────────────────────────────────────────────────
  {
    id: "daily-product-except-self",
    title: "Product Array",
    concept: "prefix / suffix products",
    prompt: `Given a list of integers (one per line), return a new list where each element
is the product of all OTHER numbers. Output one number per line.
Do not use division.

Example input:
1
2
3
4

Example output:
24
12
8
6`,
    input: "1\n2\n3\n4",
    expected: "24\n12\n8\n6",
    hints: ["Build a prefix product array, then a suffix product array.", "output[i] = prefix[i] * suffix[i]"],
    js: `function solve(text) {
  const nums = text.trim().split("\\n").map(Number);
  const n = nums.length;
  const prefix = Array(n).fill(1), suffix = Array(n).fill(1);
  for (let i = 1; i < n; i++) prefix[i] = prefix[i-1] * nums[i-1];
  for (let i = n-2; i >= 0; i--) suffix[i] = suffix[i+1] * nums[i+1];
  return nums.map((_, i) => prefix[i] * suffix[i]).join("\\n");
}`,
    py: `def solve(text):
    nums = list(map(int, text.strip().split("\\n")))
    n = len(nums)
    prefix = [1]*n; suffix = [1]*n
    for i in range(1,n): prefix[i] = prefix[i-1]*nums[i-1]
    for i in range(n-2,-1,-1): suffix[i] = suffix[i+1]*nums[i+1]
    return "\\n".join(str(prefix[i]*suffix[i]) for i in range(n))`,
    generate(rng) {
      const n = rng.range(4, 6);
      const nums = Array.from({ length: n }, () => rng.range(1, 9));
      const prefix = Array(n).fill(1), suffix = Array(n).fill(1);
      for (let i = 1; i < n; i++) prefix[i] = prefix[i-1] * nums[i-1];
      for (let i = n-2; i >= 0; i--) suffix[i] = suffix[i+1] * nums[i+1];
      const result = nums.map((_, i) => prefix[i] * suffix[i]);
      return { input: nums.join("\n"), expected: result.join("\n") };
    },
  },

  // ── Day 10 ─────────────────────────────────────────────────────────────────
  {
    id: "daily-coin-change",
    title: "Fewest Coins",
    concept: "dynamic programming (coin change)",
    prompt: `Given a target amount on the first line and coin denominations on the second line
(space-separated), return the minimum number of coins needed to make that amount.
If it's impossible, return -1.

Example input:
11
1 5 6 9

Example output:
2`,
    input: "11\n1 5 6 9",
    expected: "2",
    hints: ["Build a dp array where dp[i] = min coins for amount i.", "For each coin, update dp[amount] = min(dp[amount], dp[amount-coin] + 1)."],
    js: `function solve(text) {
  const lines = text.trim().split("\\n");
  const amount = Number(lines[0]);
  const coins = lines[1].split(" ").map(Number);
  const dp = Array(amount + 1).fill(Infinity);
  dp[0] = 0;
  for (let i = 1; i <= amount; i++)
    for (const c of coins)
      if (c <= i && dp[i - c] + 1 < dp[i]) dp[i] = dp[i - c] + 1;
  return String(dp[amount] === Infinity ? -1 : dp[amount]);
}`,
    py: `def solve(text):
    lines = text.strip().split("\\n")
    amount = int(lines[0])
    coins = list(map(int, lines[1].split()))
    dp = [float('inf')] * (amount + 1)
    dp[0] = 0
    for i in range(1, amount + 1):
        for c in coins:
            if c <= i and dp[i-c]+1 < dp[i]:
                dp[i] = dp[i-c]+1
    return str(-1 if dp[amount] == float('inf') else dp[amount])`,
    generate(rng) {
      const coins = [1, rng.range(3, 6), rng.range(7, 12)];
      const amount = rng.range(10, 30);
      const dp = Array(amount + 1).fill(Infinity);
      dp[0] = 0;
      for (let i = 1; i <= amount; i++)
        for (const c of coins)
          if (c <= i && dp[i-c]+1 < dp[i]) dp[i] = dp[i-c]+1;
      const expected = dp[amount] === Infinity ? -1 : dp[amount];
      return { input: `${amount}\n${coins.join(" ")}`, expected: String(expected) };
    },
  },

  // ── Day 11 ─────────────────────────────────────────────────────────────────
  {
    id: "daily-max-subarray",
    title: "Max Subarray",
    concept: "Kadane's algorithm",
    prompt: `Given a list of integers (one per line, can be negative), find the contiguous
subarray with the largest sum and return that sum.

Example input:
-2
1
-3
4
-1
2
1
-5
4

Example output:
6`,
    input: "-2\n1\n-3\n4\n-1\n2\n1\n-5\n4",
    expected: "6",
    hints: ["At each element, decide: extend the current subarray or start fresh.", "current = max(num, current + num)"],
    js: `function solve(text) {
  const nums = text.trim().split("\\n").map(Number);
  let cur = nums[0], best = nums[0];
  for (let i = 1; i < nums.length; i++) { cur = Math.max(nums[i], cur + nums[i]); best = Math.max(best, cur); }
  return String(best);
}`,
    py: `def solve(text):
    nums = list(map(int, text.strip().split("\\n")))
    cur = best = nums[0]
    for n in nums[1:]:
        cur = max(n, cur + n)
        best = max(best, cur)
    return str(best)`,
    generate(rng) {
      const n = rng.range(6, 12);
      const nums = Array.from({ length: n }, () => rng.range(-8, 8));
      let cur = nums[0], best = nums[0];
      for (let i = 1; i < nums.length; i++) { cur = Math.max(nums[i], cur + nums[i]); best = Math.max(best, cur); }
      return { input: nums.join("\n"), expected: String(best) };
    },
  },

  // ── Day 12 ─────────────────────────────────────────────────────────────────
  {
    id: "daily-jump-game",
    title: "Can You Jump?",
    concept: "greedy (reachability tracking)",
    prompt: `Each number in the list (one per line) represents the maximum jump length from that position.
Starting at index 0, can you reach the last index? Return YES or NO.

Example input:
2
3
1
1
4

Example output:
YES`,
    input: "2\n3\n1\n1\n4",
    expected: "YES",
    hints: ["Track the furthest index you can reach so far.", "If your current position exceeds the furthest reach, you're stuck."],
    js: `function solve(text) {
  const nums = text.trim().split("\\n").map(Number);
  let reach = 0;
  for (let i = 0; i < nums.length; i++) {
    if (i > reach) return "NO";
    reach = Math.max(reach, i + nums[i]);
  }
  return "YES";
}`,
    py: `def solve(text):
    nums = list(map(int, text.strip().split("\\n")))
    reach = 0
    for i, n in enumerate(nums):
        if i > reach: return "NO"
        reach = max(reach, i + n)
    return "YES"`,
    generate(rng) {
      const n = rng.range(5, 10);
      const nums = Array.from({ length: n }, () => rng.range(0, 4));
      nums[0] = Math.max(nums[0], 1);
      let reach = 0;
      for (let i = 0; i < nums.length; i++) { if (i > reach) break; reach = Math.max(reach, i + nums[i]); }
      const canReach = reach >= nums.length - 1;
      if (!canReach) { nums[rng.range(0, Math.floor(n/2))] = rng.range(2, 5); }
      let reach2 = 0;
      for (let i = 0; i < nums.length; i++) { if (i > reach2) break; reach2 = Math.max(reach2, i + nums[i]); }
      return { input: nums.join("\n"), expected: reach2 >= nums.length - 1 ? "YES" : "NO" };
    },
  },

  // ── Day 13 ─────────────────────────────────────────────────────────────────
  {
    id: "daily-anagram-check",
    title: "Anagram Pairs",
    concept: "character frequency comparison",
    prompt: `Given pairs of words (two per line, space-separated), output YES if they are anagrams
of each other, NO otherwise. One pair per line.

Example input:
listen silent
hello world
anagram nagaram

Example output:
YES
NO
YES`,
    input: "listen silent\nhello world\nanagram nagaram",
    expected: "YES\nNO\nYES",
    hints: ["Sort both words and compare — anagrams will be identical when sorted.", "Or count character frequencies and compare the maps."],
    js: `function solve(text) {
  return text.trim().split("\\n").map(line => {
    const [a, b] = line.split(" ");
    return [...a].sort().join("") === [...b].sort().join("") ? "YES" : "NO";
  }).join("\\n");
}`,
    py: `def solve(text):
    results = []
    for line in text.strip().split("\\n"):
        a, b = line.split()
        results.append("YES" if sorted(a) == sorted(b) else "NO")
    return "\\n".join(results)`,
    generate(rng) {
      const words = ["forge","embers","steel","listen","silent","anagram","nagaram","dusty","study","night","thing","inch","chin"];
      const pairs: string[] = [];
      const answers: string[] = [];
      const n = rng.range(3, 5);
      for (let i = 0; i < n; i++) {
        if (rng.next() < 0.5) {
          const w = rng.pick(words);
          const shuffled = [...w].sort(() => rng.next() - 0.5).join("");
          pairs.push(`${w} ${shuffled}`);
          answers.push([...w].sort().join("") === [...shuffled].sort().join("") ? "YES" : "NO");
        } else {
          const a = rng.pick(words), b = rng.pick(words.filter(x => x !== a));
          pairs.push(`${a} ${b}`);
          answers.push([...a].sort().join("") === [...b].sort().join("") ? "YES" : "NO");
        }
      }
      return { input: pairs.join("\n"), expected: answers.join("\n") };
    },
  },

  // ── Day 14 ─────────────────────────────────────────────────────────────────
  {
    id: "daily-palindrome-count",
    title: "Count Palindromes",
    concept: "string checking",
    prompt: `Given a list of words (one per line), return how many are palindromes
(read the same forwards and backwards, case-insensitive).

Example input:
racecar
hello
level
world
madam

Example output:
3`,
    input: "racecar\nhello\nlevel\nworld\nmadam",
    expected: "3",
    hints: ["Compare the word to its reverse.", "Use .toLowerCase() to handle case."],
    js: `function solve(text) {
  const words = text.trim().split("\\n");
  return String(words.filter(w => { const s = w.toLowerCase(); return s === [...s].reverse().join(""); }).length);
}`,
    py: `def solve(text):
    words = text.strip().split("\\n")
    return str(sum(1 for w in words if w.lower() == w.lower()[::-1]))`,
    generate(rng) {
      const palindromes = ["racecar","level","madam","refer","civic","rotor","kayak","radar","noon","deed","peep","tenet"];
      const nonPalindromes = ["hello","world","forge","ember","steel","spark","flame","blast","draft","quest"];
      const items: string[] = [];
      let count = 0;
      const n = rng.range(5, 8);
      for (let i = 0; i < n; i++) {
        if (rng.next() < 0.4) { items.push(rng.pick(palindromes)); count++; }
        else items.push(rng.pick(nonPalindromes));
      }
      return { input: items.join("\n"), expected: String(count) };
    },
  },

  // ── Day 15 ─────────────────────────────────────────────────────────────────
  {
    id: "daily-longest-common-prefix",
    title: "Common Prefix",
    concept: "string comparison",
    prompt: `Given a list of words (one per line), find the longest common prefix shared by all of them.
If there is no common prefix, return an empty string (blank line).

Example input:
flower
flow
flight

Example output:
fl`,
    input: "flower\nflow\nflight",
    expected: "fl",
    hints: ["Compare the first word to each other word character by character.", "Shorten your candidate prefix whenever there's a mismatch."],
    js: `function solve(text) {
  const words = text.trim().split("\\n");
  let prefix = words[0];
  for (const w of words.slice(1)) while (!w.startsWith(prefix)) prefix = prefix.slice(0, -1);
  return prefix;
}`,
    py: `def solve(text):
    words = text.strip().split("\\n")
    prefix = words[0]
    for w in words[1:]:
        while not w.startswith(prefix):
            prefix = prefix[:-1]
    return prefix`,
    generate(rng) {
      const bases = ["forge","craft","flame","steel","ember","bloom","spark","trace","blend","draft"];
      const base = rng.pick(bases);
      const prefixLen = rng.range(1, base.length);
      const prefix = base.slice(0, prefixLen);
      const suffixes = ["er","ing","ed","ly","ment","ness","tion","al","ous","ive"];
      const words = Array.from({ length: rng.range(3, 5) }, () => prefix + rng.pick(suffixes));
      // compute actual prefix
      let p = words[0];
      for (const w of words.slice(1)) while (!w.startsWith(p)) p = p.slice(0, -1);
      return { input: words.join("\n"), expected: p };
    },
  },

  // ── Day 16 ─────────────────────────────────────────────────────────────────
  {
    id: "daily-rotate-array",
    title: "Rotate Right",
    concept: "modular arithmetic on arrays",
    prompt: `Given k on the first line and a list of numbers (one per line),
rotate the list to the right by k steps and return it one per line.

Example input:
3
1
2
3
4
5
6
7

Example output:
5
6
7
1
2
3
4`,
    input: "3\n1\n2\n3\n4\n5\n6\n7",
    expected: "5\n6\n7\n1\n2\n3\n4",
    hints: ["k steps right means the last k elements move to the front.", "Use k % n to handle cases where k > n."],
    js: `function solve(text) {
  const lines = text.trim().split("\\n");
  const k = Number(lines[0]), nums = lines.slice(1);
  const n = nums.length, r = k % n;
  return [...nums.slice(n - r), ...nums.slice(0, n - r)].join("\\n");
}`,
    py: `def solve(text):
    lines = text.strip().split("\\n")
    k, nums = int(lines[0]), lines[1:]
    n, r = len(nums), int(lines[0]) % len(nums)
    return "\\n".join(nums[-r:] + nums[:-r])`,
    generate(rng) {
      const n = rng.range(4, 8);
      const nums = Array.from({ length: n }, () => rng.range(1, 20));
      const k = rng.range(1, n * 2);
      const r = k % n;
      const rotated = [...nums.slice(n - r), ...nums.slice(0, n - r)];
      return { input: `${k}\n${nums.join("\n")}`, expected: rotated.join("\n") };
    },
  },

  // ── Day 17 ─────────────────────────────────────────────────────────────────
  {
    id: "daily-hamming",
    title: "Hamming Distance",
    concept: "XOR / bit counting",
    prompt: `Given two integers (one per line), return the Hamming distance —
the number of bit positions where they differ.

Example input:
1
4

Example output:
2`,
    input: "1\n4",
    expected: "2",
    hints: ["XOR the two numbers — set bits in the result are the differing positions.", "Count the set bits (popcount) in the XOR result."],
    js: `function solve(text) {
  const [a, b] = text.trim().split("\\n").map(Number);
  let x = a ^ b, count = 0;
  while (x) { count += x & 1; x >>= 1; }
  return String(count);
}`,
    py: `def solve(text):
    a, b = map(int, text.strip().split("\\n"))
    return str(bin(a ^ b).count('1'))`,
    generate(rng) {
      const a = rng.range(0, 255), b = rng.range(0, 255);
      let x = a ^ b, count = 0;
      while (x) { count += x & 1; x >>= 1; }
      return { input: `${a}\n${b}`, expected: String(count) };
    },
  },

  // ── Day 18 ─────────────────────────────────────────────────────────────────
  {
    id: "daily-digit-sum",
    title: "Digital Root",
    concept: "repeated digit summing",
    prompt: `The digital root of a number is found by repeatedly summing its digits
until you reach a single digit.

Example input:
493

Example output:
7

(4+9+3=16, 1+6=7)`,
    input: "493",
    expected: "7",
    hints: ["Keep summing digits until the result is less than 10.", "Or use the formula: 1 + (n-1) % 9 (works for all n > 0)."],
    js: `function solve(text) {
  let n = Number(text.trim());
  while (n >= 10) n = String(n).split("").reduce((a, d) => a + Number(d), 0);
  return String(n);
}`,
    py: `def solve(text):
    n = int(text.strip())
    while n >= 10:
        n = sum(int(d) for d in str(n))
    return str(n)`,
    generate(rng) {
      const n = rng.range(100, 99999);
      let x = n;
      while (x >= 10) x = String(x).split("").reduce((a, d) => a + Number(d), 0);
      return { input: String(n), expected: String(x) };
    },
  },

  // ── Day 19 ─────────────────────────────────────────────────────────────────
  {
    id: "daily-matrix-diagonal",
    title: "Diagonal Sum",
    concept: "2D array indexing",
    prompt: `Given an n×n matrix (one row per line, space-separated numbers),
return the sum of both diagonals. Count the center element only once (for odd n).

Example input:
1 2 3
4 5 6
7 8 9

Example output:
25`,
    input: "1 2 3\n4 5 6\n7 8 9",
    expected: "25",
    hints: ["Primary diagonal: matrix[i][i]", "Secondary diagonal: matrix[i][n-1-i]", "If n is odd, the center (matrix[n/2][n/2]) is counted in both — subtract it once."],
    js: `function solve(text) {
  const grid = text.trim().split("\\n").map(r => r.split(" ").map(Number));
  const n = grid.length;
  let sum = 0;
  for (let i = 0; i < n; i++) { sum += grid[i][i] + grid[i][n-1-i]; }
  if (n % 2 === 1) sum -= grid[Math.floor(n/2)][Math.floor(n/2)];
  return String(sum);
}`,
    py: `def solve(text):
    grid = [list(map(int, r.split())) for r in text.strip().split("\\n")]
    n = len(grid)
    total = sum(grid[i][i] + grid[i][n-1-i] for i in range(n))
    if n % 2 == 1: total -= grid[n//2][n//2]
    return str(total)`,
    generate(rng) {
      const n = rng.pick([3, 4, 5]);
      const grid = Array.from({ length: n }, () => Array.from({ length: n }, () => rng.range(1, 9)));
      let sum = 0;
      for (let i = 0; i < n; i++) sum += grid[i][i] + grid[i][n-1-i];
      if (n % 2 === 1) sum -= grid[Math.floor(n/2)][Math.floor(n/2)];
      return { input: grid.map(r => r.join(" ")).join("\n"), expected: String(sum) };
    },
  },

  // ── Day 20 ─────────────────────────────────────────────────────────────────
  {
    id: "daily-unique-paths",
    title: "Grid Paths",
    concept: "combinatorics / DP on a grid",
    prompt: `A robot starts at the top-left of an m×n grid and can only move right or down.
Given m and n (space-separated on one line), return the number of unique paths to the bottom-right.

Example input:
3 7

Example output:
28`,
    input: "3 7",
    expected: "28",
    hints: ["dp[i][j] = dp[i-1][j] + dp[i][j-1]", "First row and column are all 1s (only one way to reach them)."],
    js: `function solve(text) {
  const [m, n] = text.trim().split(" ").map(Number);
  const dp = Array.from({ length: m }, () => Array(n).fill(1));
  for (let i = 1; i < m; i++) for (let j = 1; j < n; j++) dp[i][j] = dp[i-1][j] + dp[i][j-1];
  return String(dp[m-1][n-1]);
}`,
    py: `def solve(text):
    m, n = map(int, text.strip().split())
    dp = [[1]*n for _ in range(m)]
    for i in range(1,m):
        for j in range(1,n):
            dp[i][j] = dp[i-1][j] + dp[i][j-1]
    return str(dp[m-1][n-1])`,
    generate(rng) {
      const m = rng.range(2, 6), n = rng.range(2, 8);
      const dp = Array.from({ length: m }, () => Array(n).fill(1));
      for (let i = 1; i < m; i++) for (let j = 1; j < n; j++) dp[i][j] = dp[i-1][j] + dp[i][j-1];
      return { input: `${m} ${n}`, expected: String(dp[m-1][n-1]) };
    },
  },
];
