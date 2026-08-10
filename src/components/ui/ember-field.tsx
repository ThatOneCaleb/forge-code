import { useEffect, useRef } from "react";

// Rising embers: sparse warm particles drifting up behind the hero.
// Ships as code, uses the Molten Terminal ember palette, respects reduced-motion.

interface Ember {
  x: number;
  y: number;
  vx: number;
  vy: number;
  size: number;
  life: number;
  maxLife: number;
  wander: number;
  flicker: number;
  color: string;
}

// ember, ember-bright, hot spark (rgb triplets)
const COLORS = ["234,88,12", "249,115,22", "253,186,116"];

export function EmberField({ className }: { className?: string }) {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

    const ctx = canvas.getContext("2d");
    const parent = canvas.parentElement;
    if (!ctx || !parent) return;

    let width = 0;
    let height = 0;
    let raf = 0;
    let running = true;
    const embers: Ember[] = [];

    // Pre-render one soft glow sprite per color (cheap to blit each frame).
    const sprites = new Map<string, HTMLCanvasElement>();
    for (const color of COLORS) {
      const s = document.createElement("canvas");
      s.width = s.height = 32;
      const sc = s.getContext("2d")!;
      const g = sc.createRadialGradient(16, 16, 0, 16, 16, 16);
      g.addColorStop(0, `rgba(${color},0.9)`);
      g.addColorStop(0.4, `rgba(${color},0.35)`);
      g.addColorStop(1, `rgba(${color},0)`);
      sc.fillStyle = g;
      sc.fillRect(0, 0, 32, 32);
      sprites.set(color, s);
    }

    function targetCount() {
      return Math.round(Math.min(70, Math.max(24, width / 22)));
    }

    function spawn(initial: boolean): Ember {
      const maxLife = 220 + Math.random() * 260;
      return {
        x: Math.random() * width,
        y: initial ? Math.random() * height : height + Math.random() * 24,
        vx: (Math.random() - 0.5) * 0.25,
        vy: -(0.25 + Math.random() * 0.7),
        size: 0.6 + Math.random() * 1.8,
        life: initial ? Math.random() * maxLife : 0,
        maxLife,
        wander: Math.random() * Math.PI * 2,
        flicker: Math.random() * Math.PI * 2,
        color: COLORS[Math.floor(Math.random() * COLORS.length)],
      };
    }

    function resize() {
      const rect = parent!.getBoundingClientRect();
      width = rect.width;
      height = rect.height;
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      canvas!.width = Math.max(1, Math.floor(width * dpr));
      canvas!.height = Math.max(1, Math.floor(height * dpr));
      canvas!.style.width = `${width}px`;
      canvas!.style.height = `${height}px`;
      ctx!.setTransform(dpr, 0, 0, dpr, 0, 0);

      const target = targetCount();
      while (embers.length < target) embers.push(spawn(true));
      if (embers.length > target) embers.length = target;
    }

    function frame() {
      if (!running) return;
      ctx!.clearRect(0, 0, width, height);
      ctx!.globalCompositeOperation = "lighter";
      for (const e of embers) {
        e.life++;
        e.wander += 0.02;
        e.x += e.vx + Math.sin(e.wander) * 0.15;
        e.y += e.vy;

        const t = e.life / e.maxLife;
        if (t >= 1 || e.y < -12) {
          Object.assign(e, spawn(false));
          continue;
        }

        let alpha = t < 0.15 ? t / 0.15 : t > 0.6 ? 1 - (t - 0.6) / 0.4 : 1;
        alpha *= 0.55 * (0.75 + Math.sin(e.life * 0.2 + e.flicker) * 0.25);

        const r = e.size * 4;
        ctx!.globalAlpha = Math.max(0, alpha);
        ctx!.drawImage(sprites.get(e.color)!, e.x - r, e.y - r, r * 2, r * 2);
      }
      ctx!.globalAlpha = 1;
      ctx!.globalCompositeOperation = "source-over";
      raf = requestAnimationFrame(frame);
    }

    function start() {
      if (running) return;
      running = true;
      raf = requestAnimationFrame(frame);
    }
    function stop() {
      running = false;
      cancelAnimationFrame(raf);
    }

    resize();
    const ro = new ResizeObserver(resize);
    ro.observe(parent);

    // Pause when the hero scrolls offscreen or the tab is hidden.
    const io = new IntersectionObserver(
      ([entry]) => (entry.isIntersecting ? start() : stop()),
      { threshold: 0 },
    );
    io.observe(parent);
    const onVisibility = () => (document.hidden ? stop() : start());
    document.addEventListener("visibilitychange", onVisibility);

    raf = requestAnimationFrame(frame);

    return () => {
      stop();
      ro.disconnect();
      io.disconnect();
      document.removeEventListener("visibilitychange", onVisibility);
    };
  }, []);

  return (
    <canvas
      ref={canvasRef}
      aria-hidden="true"
      className={className}
      style={{ position: "absolute", inset: 0, width: "100%", height: "100%", pointerEvents: "none" }}
    />
  );
}
