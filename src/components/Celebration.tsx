import { useEffect } from "react";
import confetti from "canvas-confetti";

/** Fires a tasteful confetti burst once when mounted. */
export function fireConfetti() {
  const colors = ["#EA580C", "#F97316", "#0284C7", "#FBBF24", "#16A34A"];
  confetti({ particleCount: 90, spread: 70, origin: { y: 0.35 }, colors });
  setTimeout(() => {
    confetti({ particleCount: 50, angle: 60, spread: 55, origin: { x: 0 }, colors });
    confetti({ particleCount: 50, angle: 120, spread: 55, origin: { x: 1 }, colors });
  }, 150);
}

export function Celebration() {
  useEffect(() => {
    fireConfetti();
  }, []);
  return null;
}
