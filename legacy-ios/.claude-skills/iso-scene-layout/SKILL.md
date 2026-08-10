---
name: iso-scene-layout
description: Use when the isometric base camp scene (IsoScene.swift) looks wrong — floating objects, structures misaligned, characters in the sky, cluttered layout, or anything visually broken in the Challenges tab scene. Governs ALL placement rules for the SpriteKit isometric scene.
---

# Iso Scene Layout — Rules + Rebuild Protocol

## The One Rule: Plan Before Placing

**Never add or move objects by trial and error.** Every build costs 30+ seconds. Instead:
1. Draw the zone map (text grid) first
2. Verify math on paper
3. Write the code
4. Build once

---

## Core Math

```
isoPoint(col, row).x = (col - row) * tileW / 2       = (col - row) * 65
isoPoint(col, row).y = (col + row) * tileH / 2       = (col + row) * 32.5

tileW = 130pt   (diamond width, left-to-right)
tileH = 65pt    (diamond height, front-to-back)
```

**The diamond center** (where objects stand) is at `isoPoint(col, row)`. The canvas center of a structure sprite should be placed here.

**For objects placed ON the terrain** (not floating, not sunk):
- Use `isoPoint(col, row)` as position — this IS the standing surface in screen space
- `yOff: 0` is slightly sunk (canvas center at diamond center); `yOff: 20–32` looks grounded
- Negative yOff = underground → object appears floating because base is hidden

---

## Character Grounding Rule

Characters float when `anchorPoint.y` is set incorrectly relative to the feet position in the sprite.

**Correct character placement:**
```swift
sprite.setScale(1.0)
// anchorY = feet_y_in_canvas / canvas_height (measure feet position in the sprite PNG)
// For astronautA_NE: feet at UIKit y≈322 → SpriteKit y = 190 → anchorY = 190/512 = 0.371
sprite.anchorPoint = CGPoint(x: 0.5, y: 0.371)
// Position = isoPoint — the diamond center IS the ground standing point
sprite.position = isoPoint(col: start.0, row: start.1)
```

**Do NOT add tileH/2** to character y — that places them at the back edge of the tile (too high).

---

## Zone Map — Always Draw This First

Before writing any placement code, fill in a text grid like this:

```
     col: 0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19
row 0:    [  ][  ][  ][  ][  ][  ][  ][  ][  ][  ][  ][  ][  ][  ][  ]
row 1:    [  ][  ][  ][  ][MR][MR][MR][MR][MR][MR][MR][MR][MR][MR][  ]
row 2:    [  ][cr][  ][  ][MR][  ][  ][  ][  ][  ][  ][  ][  ][  ][  ]
...
```

Label each occupied tile with a 2-char code: LP=landing pad, GN=generator, CC=command center, CD=comms dish, HD=habitat dome, SD=supply depot, CG=crystal garden, RG=rover garage, MR=monorail, RD=road, ch=character, cr=crater/deco.

**Zones must be separated by ≥1 empty tile** so structures don't visually collide.

---

## Placement Rules

### Structures (512×512 Kenney sprites via `tileSprite()`)
- Scale formula: `tileW / texWidth * desiredVisualScale`
- For 512×512 content sprites: `130/512 * N` where N is desired visual tile-heights (3.0 = 3 tiles tall)
- `yOff: 32` minimum to sit on terrain surface (not sunk into diamond center)
- Layer 3 for walls/main bodies, layer 4 for chimneys/tall elements, layer 5 for domes

### Terrain (via `terrainSprite()` — do NOT use `tileSprite()`)
- `setScale(1.0)` — the 512×512 canvas contains the 130pt diamond, no scaling needed
- `anchorPoint.y = 0.384` — centers on the diamond's vertical midpoint
- Layer 0 for base ground, layer 1 for roads/paths, layer 2 for raised platforms

### Stairs — must connect two things
- Stairs are only placed where the road tile (layer 1) meets a raised platform
- The stair's high end must touch the platform edge; the low end must touch road tile
- If no platform is adjacent: **remove the stairs entirely**

### Characters
- Never spawn at a col or row that has a structure occupying its tile (they clip)
- Keep waypoints within the 3×3 tile zone around their landmark
- All waypoints must use `isoPoint.y + tileH/2` (see grounding rule above)

---

## Clutter Rule

**Max 2 named structures per 3×3 zone.** If more than 2 structures overlap in a 3-tile radius, one moves or is removed. The scene should read as distinct landmarks, not noise.

The 20×11 grid has room for exactly 7 landmark zones — don't squeeze in more:
| Zone | Cols | Rows | Max structures |
|------|------|------|----------------|
| Landing Pad + Rocket | 4–8 | 5–9 | 3 (pad + rocket + stairs) |
| Comms Dish | 5–8 | 2–5 | 2 (big dish + support) |
| Generator | 9–12 | 4–7 | 3 (large + small + barrels) |
| Command Centre | 12–16 | 3–7 | 4 (floor + 2 walls + corridor) |
| Habitat Dome | 13–16 | 7–10 | 2 (dome + gate) |
| Supply Depot | 16–19 | 4–7 | 3 (hangar + barrels + rail) |
| Crystal Garden | 16–19 | 2–5 | 4 (crystals only — no buildings) |
| Rover Garage | 4–8 | 9–11 | 3 (hangar + 2 vehicles) |
| Monorail | 4–18 | 1–2 | track + train only |
| Decorations | edges | any | craters + rocks in open corners |

---

## Rebuild Protocol

When the scene looks wrong, follow this order:

1. **Screenshot + list every visible problem** (floating, clutter, disconnected, wrong scale)
2. **Draw the zone map** for the affected region
3. **Fix grounding math first** (characters, then structures)
4. **Fix connectivity** (stairs → platform, road → gate)
5. **Fix clutter** (move or remove, never just scale down)
6. **Build once, screenshot, evaluate**

---

## Common Bugs + Fixes

| Symptom | Cause | Fix |
|---------|-------|-----|
| Character floats in sky | `anchorPoint.y` too high; position not at `isoPoint.y + tileH/2` | Use grounding rule above |
| Structure sunk into ground | `yOff` too small (< 32) | Set `yOff: 32` minimum |
| Stairs to nowhere | Stairs placed without adjacent platform | Remove stairs or add connecting road |
| Objects clip through each other | Two structures at same (col, row, layer) | Move one 1 col or give different layer |
| Scene looks cluttered | More than 2 structures in a 3-tile zone | Pick the hero piece, remove the rest |
| Sky spawns twice | `skyBuilt` flag not set before returning early | Already fixed; don't remove the guard |
