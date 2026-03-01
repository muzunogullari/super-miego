# Session Handoff

Last updated: Mar 1, 2026. This document captures the current state of the project for the next agent picking up work.

## Recent Commit History

```
adbc47e Fix level transition and add fire turtle enemies
83f9d10 Add looping background music to gameplay
8fa55b4 Add drifting cloud layer and fix green fringe on cloud assets
a07424c Add 5 levels with progression and level complete flow
0e20f00 Add level generator, turtle enemies, and fix player growth
70c8e22 Align background layers with ground surface
2b8945b Fix camera Y clamp so ground sits flush with screen bottom
ad19604 Add PNW parallax backgrounds, tileable mountains, tree assets, and brick crate texture
24fcbe3 Add agent-facing documentation for codebase and sprite pipeline
aefba67 Add goomba pixel art sprites with waddle animation and death state
c53dc68 Regenerate all player sprites from unified sheet for consistent art style
```

## What Was Done This Session

### Sprites
- **Player**: All 6 poses (idle, 3 run frames, jump, dead) regenerated from a single unified sprite sheet. This was critical -- generating poses separately causes mismatched proportions/styles. See `docs/sprite-pipeline.md` for the full process.
- **Goomba enemies**: 3 sprites (walk1, walk2, dead) generated from a photo of the user's friend. Humorous goomba-style with wild curly hair and glasses. Waddle animation loops constantly, dead texture shown on stomp.
- **Brick blocks**: Replaced flat brown color with a wooden crate pixel art texture (PNW rustic vibe).

### Parallax Background System
- 4-layer parallax system in `GameScene.createBackground()` and `GameScene.updateParallax()`:
  - **Sky** (parallax 0.95): 3-stripe procedural gradient, PNW overcast blues
  - **Mountains** (parallax 0.75): Tileable Olympic-style pixel art mountain range with snow caps. Edge-blended programmatically for seamless tiling.
  - **Trees** (parallax 0.4): 4 distinct PNW evergreen silhouettes (Douglas fir, cedar, spruce, sapling), randomly placed with varying sizes and opacity.
  - **Clouds** (parallax 0.95, drifts): 3 cloud textures that float rightward and wrap around. Updated in `updateClouds(deltaTime:)`.
- Backgrounds are anchored so tree bases align with the top of the ground tiles.

### Camera
- Fixed camera Y clamp so the viewport bottom sits flush at y=0 (no gap below ground).
- `CameraController.swift` line: `let minY = viewportSize.height / 2`

### Audio
- Background music (`background_audio.m4a`) loops infinitely during gameplay via `AVAudioPlayer`.
- Plays at 40% volume. Only in GameScene, not MenuScene.

### Documentation
- Created `docs/` folder with 5 documents (architecture, physics, level-design, game-constants, sprite-pipeline).

## Post-Handoff Gameplay Fixes

- **Jump limit**: Extra air jumps are now configurable via `GameConstants.maxAirJumps` (default `1`, which gives a double-jump total).
- **Grounding/pipe stability**: Pipe side contacts no longer incorrectly clear grounded state. `CollisionHandler` tracks true support contacts, and `Player` supplements that with contact-body checks plus foot probes.
- **Platforms**: One-way platform collisions are now wired into the player's collision/contact handling.
- **Timer expiry**: `GameStateManager` now triggers player death when time reaches zero.
- **Player hitbox**: The small-form player body is beveled at the feet, trimmed at the top, and intentionally narrower so the sprite can fit 2-tile tunnels and match the visible art more closely.

## Current File Inventory

### Swift Files (20 total)
| File | Purpose |
|------|---------|
| `App/SuperMiegoApp.swift` | SwiftUI entry, launches MenuScene |
| `Scenes/GameScene.swift` | Main game loop, input, parallax, audio, all delegate implementations |
| `Scenes/MenuScene.swift` | Title screen |
| `Entities/Player.swift` | Player state machine, movement, animation, power-ups |
| `Entities/Enemy.swift` | Goomba/Koopa/Piranha (goomba has sprite textures) |
| `Entities/TurtleEnemy.swift` | Ice/fire turtle enemy type |
| `Nodes/BlockNode.swift` | Ground, brick (crate texture), question, platform |
| `Nodes/ItemNode.swift` | Mushroom, fire flower, star, 1-up, Fireball |
| `Systems/CameraController.swift` | Parallax-aware camera with Y clamp |
| `Systems/CollisionHandler.swift` | Physics contact routing |
| `Systems/GameStateManager.swift` | Score, coins, lives, timer |
| `Systems/InputManager.swift` | **UNUSED** - GameScene has its own drag+tap input |
| `Levels/Level1.swift` | Level wrappers + `LevelManager` entry points |
| `Levels/LevelLoader.swift` | Parses character grids into nodes |
| `Levels/LevelGenerator.swift` | Procedural level generation (added by remote) |
| `Config/GameConstants.swift` | All tunable values + Debug flags |
| `Config/PhysicsCategories.swift` | Collision bitmasks |
| `Config/AssetNames.swift` | Asset name constants (partially used) |
| `UI/HUD.swift` | Score, coins, lives, time, pause button |
| `UI/PauseMenuOverlay.swift` | Pause menu |

### Asset Catalog (`Assets.xcassets/Sprites/`)
```
Player/         → player_idle, player_jump, player_run (3-frame sheet), player_dead
Enemies/        → goomba_walk1, goomba_walk2, goomba_dead
Blocks/         → brick_crate
Backgrounds/    → bg_mountains, bg_tree_1-4, bg_cloud_1-3
coin.imageset   → coin sprite
```

### Audio
- `SuperMiego/background_audio.m4a` — gameplay background music

## What Still Needs Sprites (Using Placeholder Colors)

These entities are still rendered as flat colored rectangles:

| Entity | Current Color | Suggested Asset |
|--------|--------------|-----------------|
| **Ground blocks** | Dark brown `(0.45, 0.3, 0.2)` | Dirt/grass tile |
| **Question blocks** | Gold `(0.9, 0.75, 0.2)` | Classic question mark block |
| **Empty blocks** | Dark brown `(0.4, 0.35, 0.3)` | Darker used-up block |
| **Pipes** | Dark green `(0.3, 0.55, 0.3)` | Green pipe (top + body) |
| **Platforms** | Gray-brown `(0.5, 0.45, 0.4)` | Wooden platform |
| **Koopa enemies** | Green `(0.2, 0.5, 0.2)` | Turtle sprite |
| **Piranha enemies** | Red `(0.7, 0.2, 0.2)` | Piranha plant sprite |
| **Coins (floating)** | Yellow | Animated coin |
| **Mushroom** | Red | Mushroom power-up |
| **Fire flower** | Orange | Fire flower |
| **Star** | Yellow | Star power-up |
| **Fireball** | Orange | Fireball projectile |
| **Flagpole** | Gray/Green | End-of-level flag |
| **Turtle enemies** | (TurtleEnemy.swift) | Fire turtle |

## Known Issues & Quirks

1. **Player physics body is intentionally not a full rectangle.** It keeps 4px beveled bottom corners to prevent tile-seam snagging, plus a trimmed top and narrower width for tunnel clearance and better visual fit. Do NOT revert to a simple rectangle.
2. **GameConstants vs actual code**: Enemy sizes in `Enemy.swift` (28×28 goomba) differ from `GameConstants` (32×32). The code values are what's actually used.
3. **InputManager.swift is completely unused.** GameScene implements its own drag+tap system.
4. **`.pip_tmp/` folder**: Contains locally-installed Pillow for image processing. Keep it uncommitted; if it appears as untracked, exclude it before committing. Reinstall with `pip3 install --target .pip_tmp Pillow` if needed.
5. **Cloud green fringe**: The cloud chromakey uses an aggressive `is_greenish()` check (g > 150 and g > r*1.3 and g > b*1.3). Standard `is_green()` leaves anti-aliasing fringe on white/light-colored sprites.
6. **Background music only plays in GameScene**, not MenuScene. It doesn't pause/resume with game pause (the scene `isPaused` pauses SpriteKit actions but not AVAudioPlayer).
7. **Levels**: The game has 5 levels with progression. `LevelManager` currently routes all 5 through `LevelGenerator.swift`.

## User Preferences

- The user (Diego) is the player character sprite (bald, beard, black shirt, jeans, barefoot).
- Goomba enemies are based on a photo of someone he knows (curly hair, glasses, polo shirt).
- **PNW (Pacific Northwest) aesthetic**: The game has a Seattle/Olympic Mountains vibe. Overcast skies, evergreen trees, snow-capped mountains. Keep this theme for future assets.
- The user prefers iterating visually -- build, screenshot, adjust. Don't over-engineer; show results early.
- When generating sprites, always use a **single image generation call** for all poses of a character. This is non-negotiable after the player sprite debacle.
