// Deterministic, seeded PRNG so each player gets a unique-but-stable puzzle
// input. Same seed → same sequence, which is how we make a challenge's input
// vary per player yet stay fixed for that player across sessions.

export interface Rng {
  /** Float in [0, 1). */
  next(): number;
  /** Integer in [0, maxExclusive). */
  int(maxExclusive: number): number;
  /** Integer in [min, max] inclusive. */
  range(min: number, max: number): number;
  /** Random element of a non-empty array. */
  pick<T>(arr: readonly T[]): T;
}

/** mulberry32 — tiny, fast, good-enough PRNG for puzzle generation. */
export function makeRng(seed: number): Rng {
  let a = seed >>> 0;
  const next = () => {
    a |= 0;
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
  return {
    next,
    int: (maxExclusive) => Math.floor(next() * maxExclusive),
    range: (min, max) => min + Math.floor(next() * (max - min + 1)),
    pick: (arr) => arr[Math.floor(next() * arr.length)],
  };
}

/** Hash an arbitrary string to a uint32 seed (xfnv1a). */
export function hashSeed(str: string): number {
  let h = 2166136261 >>> 0;
  for (let i = 0; i < str.length; i++) {
    h ^= str.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return h >>> 0;
}

/** A stable per-player, per-challenge RNG. */
export function puzzleRng(playerSeed: string, challengeId: string): Rng {
  return makeRng(hashSeed(`${playerSeed}:${challengeId}`));
}
