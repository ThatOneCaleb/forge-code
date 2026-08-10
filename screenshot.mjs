// Screenshot a URL with Playwright.
// Usage: node screenshot.mjs http://localhost:5173 [label] [desktop|mobile]
// Examples:
//   node screenshot.mjs http://localhost:5173
//   node screenshot.mjs http://localhost:5173 hero
//   node screenshot.mjs http://localhost:5173 hero mobile
//   SHOT_VIEWPORT=1 node screenshot.mjs http://localhost:5173        (viewport only, not full-page)
//   SHOT_TO="#pricing" node screenshot.mjs http://localhost:5173     (scroll to element first)
// Saves auto-incremented PNGs to ./temporary screenshots/screenshot-N[-label][-mobile].png
import { chromium } from 'playwright';
import { mkdir, readdir, writeFile } from 'node:fs/promises';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = dirname(fileURLToPath(import.meta.url));
const OUT_DIR = join(ROOT, 'temporary screenshots');

const url = process.argv[2] || 'http://localhost:5173';
const label = process.argv[3] || '';
const mode = process.argv[4] || 'desktop';

const VIEWPORTS = {
  desktop: { width: 1440, height: 900, deviceScaleFactor: 1 },
  mobile:  { width: 390,  height: 844, deviceScaleFactor: 2 },
};

async function nextIndex() {
  await mkdir(OUT_DIR, { recursive: true });
  const files = await readdir(OUT_DIR).catch(() => []);
  let max = 0;
  for (const f of files) {
    const m = f.match(/^screenshot-(\d+)/);
    if (m) max = Math.max(max, parseInt(m[1], 10));
  }
  return max + 1;
}

const vp = VIEWPORTS[mode] ?? VIEWPORTS.desktop;
const browser = await chromium.launch({ headless: true });
const context = await browser.newContext({
  viewport: { width: vp.width, height: vp.height },
  deviceScaleFactor: vp.deviceScaleFactor,
});

try {
  const page = await context.newPage();
  await page.goto(url, { waitUntil: 'networkidle', timeout: 60_000 });

  // Scroll through to trigger scroll-based reveals / counters, then return to top.
  await page.evaluate(async () => {
    const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
    const step = Math.round(window.innerHeight * 0.7);
    for (let y = 0; y <= document.body.scrollHeight; y += step) {
      window.scrollTo(0, y);
      await sleep(120);
    }
    window.scrollTo(0, document.body.scrollHeight);
    await sleep(300);
    window.scrollTo(0, 0);
    await sleep(400);
  });

  // Optionally scroll to a CSS selector before capture.
  if (process.env.SHOT_TO) {
    await page.evaluate((sel) => {
      document.querySelector(sel)?.scrollIntoView({ block: 'start' });
    }, process.env.SHOT_TO);
  }

  // Let fonts and animations settle.
  await page.waitForTimeout(1000);

  const i = await nextIndex();
  const parts = [`screenshot-${i}`];
  if (label) parts.push(label);
  if (mode === 'mobile') parts.push('mobile');
  const outPath = join(OUT_DIR, parts.join('-') + '.png');

  const buf = await page.screenshot({ fullPage: process.env.SHOT_VIEWPORT !== '1' });
  await writeFile(outPath, buf);
  console.log(`Saved ${outPath}`);
} finally {
  await context.close();
  await browser.close();
}
