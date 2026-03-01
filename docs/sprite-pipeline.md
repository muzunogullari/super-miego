# Sprite Pipeline

How to generate, process, and integrate pixel art sprites into the game. This document is written for AI agents working on this codebase.

## Critical Lessons (Read First)

1. **Generate ALL poses for a character in a SINGLE image generation call.** If you generate idle, run, jump, and dead separately, each will have different body proportions, line weights, and art styles. No amount of code-level size tweaking can fix mismatched art. This was learned the hard way through many failed iterations.

2. **Use a solid `#00FF00` green background** in the generation prompt. Magenta (`#FF00FF`) overlaps with skin tones and anti-aliasing. White backgrounds are ambiguous. Green is trivially chromakeyed.

3. **Explicitly say "NO BORDERS, NO FRAMES"** in the prompt. Image generators love adding decorative black borders around sprite frames. These borders are extremely difficult to separate from the character's own black pixel art outlines.

4. **Do NOT divide the sprite sheet into equal columns.** The generated sprites are never evenly spaced. Always detect the actual boundaries by scanning for fully-green column gaps between sprites.

## Step-by-Step Pipeline

### Step 1: Generate the Sprite Sheet

Use a single image generation call with ALL poses for the character. Key prompt elements:

- Art style: "16-bit pixel art, Super Mario World SNES style"
- Background: "solid bright green (#00FF00) background"
- Layout: "arranged in a single horizontal row" or "2 rows of N"
- Anti-clutter: "NO borders, NO frames, NO decorative elements"
- Consistency: "EXACT SAME character with IDENTICAL proportions, colors, and style"
- Pixel art quality: "clean chunky pixel art with black outlines"

Provide reference images of existing sprites to maintain style consistency across characters.

**Example prompt structure:**
```
A pixel art sprite sheet on a solid bright green (#00FF00) background.
16-bit Super Mario World SNES style. N poses of the SAME character
arranged in a single horizontal row.

[Character description]

Pose 1 (STATE): [description]
Pose 2 (STATE): [description]
...

CRITICAL: All N poses must show the EXACT SAME character with IDENTICAL
proportions, colors, and style. Clean chunky pixel art with black
outlines. NO borders, NO frames, NO decorative elements. Just the
character on solid green.
```

### Step 2: Analyze the Layout

The generated image will NOT have evenly spaced sprites. You must detect actual boundaries.

**2a. Find content row bounds** — scan for rows that are entirely green to find horizontal gaps separating rows of sprites:

```python
for y in range(h):
    all_green = all(is_green(img.getpixel((x, y))) for x in range(0, w, 4))
    if all_green:
        green_rows.append(y)
# Group consecutive green rows into gaps
# Content rows are between the gaps
```

**2b. Find sprite column boundaries per row** — for each content row, scan for columns that are entirely green within that row's vertical range:

```python
for x in range(w):
    all_green = all(is_green(img.getpixel((x, y))) for y in range(row_top, row_bottom + 1))
    if all_green:
        green_cols.append(x)
# Group consecutive green columns into gaps (filter for width > 3px)
# Sprite regions are between the gaps
```

This gives you exact `(x_start, x_end)` per sprite per row.

### Step 3: Extract and Process Sprites

```python
from PIL import Image

def is_green(px):
    return px[1] > 180 and px[0] < 80 and px[2] < 80

# 1. Remove green background
for y in range(h):
    for x in range(w):
        if is_green(img.getpixel((x, y))):
            img.putpixel((x, y), (0, 0, 0, 0))

# 2. Crop each sprite region and trim to content bounding box
cell = img.crop((x_start, row_top, x_end + 1, row_bottom + 1))
bbox = cell.getbbox()
content = cell.crop(bbox)

# 3. Place into uniform square cells (bottom-aligned for standing poses)
cell_size = max(max_width, max_height)  # across ALL poses
out = Image.new('RGBA', (cell_size, cell_size), (0, 0, 0, 0))
fx = (cell_size - content.size[0]) // 2      # center horizontally
fy = cell_size - content.size[1]              # bottom-align (feet at bottom)
out.paste(content, (fx, fy))
```

**Why square cells matter:** SpriteKit renders textures into the node's `size`. If all textures share the same aspect ratio (1:1 square cells), a single fixed display size works without distortion across all animation states. This eliminates the need for per-state size hacks.

**Bottom-alignment:** Standing/walking/running/jumping poses should be bottom-aligned so feet stay at the same level. Dead/special poses can be center-aligned.

### Step 4: Save as Xcode Asset Catalog

Each sprite needs an `.imageset` folder inside `SuperMiego/Assets.xcassets/Sprites/`.

**Directory structure:**
```
SuperMiego/Assets.xcassets/Sprites/
├── Enemies/
│   ├── Contents.json              ← folder group marker
│   ├── goomba_walk1.imageset/
│   │   ├── Contents.json
│   │   └── goomba_walk1.png
│   └── ...
└── Player/
    ├── player_idle.imageset/
    │   ├── Contents.json
    │   └── player_idle.png
    └── ...
```

**Contents.json for each `.imageset`:**
```json
{
  "images": [
    {
      "filename": "<name>.png",
      "idiom": "universal",
      "scale": "1x"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

**Contents.json for group folders** (like `Enemies/`, `Player/`):
```json
{
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

For multi-frame animations (like a run cycle), you have two options:
- **Separate imagesets per frame** (used for goomba walk): `goomba_walk1.imageset`, `goomba_walk2.imageset`
- **Single sprite sheet imageset** (used for player run): `player_run.imageset` containing a horizontal strip, sliced in code with `SKTexture(rect:in:)`

### Step 5: Load in Code

**Single textures:**
```swift
let texture = SKTexture(imageNamed: "goomba_walk1")
texture.filteringMode = .nearest  // REQUIRED for crisp pixel art
```

**Sprite sheet slicing (for run cycles etc.):**
```swift
let sheet = SKTexture(imageNamed: "player_run")
let frameWidth: CGFloat = 1.0 / 3.0  // 3 frames
for i in 0..<3 {
    let rect = CGRect(x: CGFloat(i) * frameWidth, y: 0, width: frameWidth, height: 1.0)
    runFrames.append(SKTexture(rect: rect, in: sheet))
}
```

**Idle/waddle animation (constant loop):**
```swift
let waddle = SKAction.animate(with: [walk1, walk2], timePerFrame: 0.25)
run(SKAction.repeatForever(waddle), withKey: "waddleAnimation")
```

**State-based animation (run only when moving):**
```swift
if isMoving && !isRunAnimating {
    isRunAnimating = true
    let animate = SKAction.animate(with: runFrames, timePerFrame: 0.1)
    run(SKAction.repeatForever(animate), withKey: "runAnimation")
} else if !isMoving {
    texture = idleTexture
    removeAction(forKey: "runAnimation")
    isRunAnimating = false
}
```

Always call `removeAction(forKey:)` before switching away from an animated state, or the animation will keep overwriting the texture.

### Step 6: Display Size

Set the node's `size` to a fixed value that looks right at game scale. All current sprites use:

| Entity | Display Size | Notes |
|--------|-------------|-------|
| Player (small) | 56 x 64 | Slightly taller than wide |
| Player (big) | 56 x 112 | After mushroom |
| Goomba | 28 x 28 | Small enemy |
| Koopa | 28 x 36 | Taller enemy |

Because all textures for a given character use square cells (1:1 aspect ratio), a single fixed size applies to all animation states without distortion.

## Dependencies

Image processing uses Python with `Pillow`. Install locally:
```bash
pip3 install --target .pip_tmp Pillow
```

Then in scripts:
```python
import sys
sys.path.insert(0, '.pip_tmp')
from PIL import Image
```

The `.pip_tmp` folder is a local scratch install and should not be committed. If it appears as untracked in your worktree, exclude it before committing.

## Common Pitfalls

| Pitfall | Consequence | Fix |
|---------|------------|-----|
| Generating sprites in separate calls | Mismatched proportions/style between states | Single generation call for all poses |
| Using magenta background | Hard to chromakey cleanly, bleeds into skin tones | Use `#00FF00` green |
| Dividing sheet into equal columns | Cuts through sprites, causes bleeding between frames | Scan for actual green column gaps |
| Not using `.nearest` filtering | Blurry pixel art | Set `tex.filteringMode = .nearest` |
| Using `SKAction.animate(resize: true)` | Node resizes to raw texture pixel dimensions (huge) | Use fixed `size`, don't pass `resize: true` |
| Forgetting `removeAction(forKey:)` | Animation keeps overwriting texture after state change | Always remove animation action before switching state |
| Non-square texture cells | Different states have different aspect ratios, causing stretch | Pad all poses into uniform square cells |
| Not bottom-aligning standing poses | Feet jump up/down between animation frames | Bottom-align content in each cell |
