# Architecture Overview

A SpriteKit-based 2D platformer built with SwiftUI as the app shell. This document maps the codebase for AI agents.

## Directory Structure

```
SuperMiego/
├── App/
│   └── SuperMiegoApp.swift          ← SwiftUI entry point + UIKit SKView host, launches MenuScene
├── Assets.xcassets/
│   └── Sprites/
│       ├── Player/                  ← player_idle, player_jump, player_run, player_dead
│       ├── Enemies/                 ← goomba_walk1, goomba_walk2, goomba_dead
│       ├── Blocks/                  ← brick_crate
│       └── Backgrounds/             ← bg_mountains, bg_tree_1-4, bg_cloud_1-3
├── Config/
│   ├── GameConstants.swift          ← All tunable values (speeds, sizes, forces, scoring)
│   ├── PhysicsCategories.swift      ← Bitmask definitions for collision system
│   └── AssetNames.swift             ← Asset name constants (partially used)
├── Entities/
│   ├── Player.swift                 ← Player state machine, movement, animation, power-ups
│   ├── Enemy.swift                  ← Goomba/Koopa/Piranha behavior, stomp/shell mechanics
│   └── TurtleEnemy.swift            ← Ice/fire turtle enemy variants
├── Levels/
│   ├── Level1.swift                 ← Level wrappers + LevelManager entry points (legacy name)
│   ├── LevelLoader.swift            ← Parses level data into SpriteKit nodes
│   └── LevelGenerator.swift         ← Procedural level generation for all 5 levels
├── Nodes/
│   ├── BlockNode.swift              ← Ground, brick (crate texture), question blocks, platforms
│   └── ItemNode.swift               ← Mushroom, fire flower, star, 1-up, fireball
├── Scenes/
│   ├── MenuScene.swift              ← Title screen with rain/mist effects
│   └── GameScene.swift              ← Main game loop, input, parallax, audio, systems orchestration
├── Systems/
│   ├── CameraController.swift       ← Side-scrolling camera with player tracking + Y clamp
│   ├── CollisionHandler.swift       ← SKPhysicsContactDelegate routing
│   ├── GameStateManager.swift       ← Score, coins, lives, timer, level completion
│   └── InputManager.swift           ← (Unused) Alternative input scheme
├── UI/
│   ├── HUD.swift                    ← Score, coins, lives, time, world display
│   └── PauseMenuOverlay.swift       ← Pause menu with resume/restart
└── background_audio.m4a             ← Looping gameplay background music
```

## Execution Flow

```
SuperMiegoApp (SwiftUI)
  └─ GameViewControllerRepresentable
       └─ GameViewController (UIKit)
            ├─ owns SKView
            ├─ presents MenuScene
            ├─ becomes first responder for hardware keyboard input
            └─ forwards A / D / Space to GameScene when active
                 └─ START GAME transitions to GameScene
                      ├─ didMove(to:)
                      │   ├─ Creates worldNode (container for all game objects)
                      │   ├─ loadLevel() — LevelManager/LevelGenerator for levels 1-5
                      │   ├─ Creates Player, adds to worldNode
                      │   ├─ Sets up CameraController, CollisionHandler, GameStateManager
                      │   ├─ createBackground() — 4-layer parallax (sky, mountains, trees, clouds)
                      │   ├─ Creates HUD (attached to camera, not world)
                      │   └─ playBackgroundMusic() — AVAudioPlayer, loops infinitely
                      └─ update(_:)
                          ├─ GameStateManager.update (timer countdown)
                          ├─ Player.update (movement, jump, animation)
                          ├─ Enemy.update (walk patrol)
                          ├─ TurtleEnemy.update (patrol + projectile firing)
                          ├─ ItemNode.update (mushroom/star movement)
                          ├─ Fireball.update
                          ├─ CameraController.update (follow player)
                          ├─ updateParallax() — repositions background layers relative to camera
                          └─ updateClouds(deltaTime:) — drifts clouds rightward, wraps
```

## Key Systems

### Input (GameScene + GameViewController)
Touch gameplay input is implemented directly in `GameScene` (not via InputManager):
- **Drag horizontally**: Move left/right. Velocity scales with drag distance (dead zone: 20pt, max: 120pt).
- **Tap**: Jump. Ground tap = low jump, air tap = high jump (`GameConstants.maxAirJumps`, default: 1 extra jump = double-jump total).
- The HUD pause button intercepts touches before game input.

There is also hidden hardware keyboard support for simulator/debug use:
- **A**: Move left
- **D**: Move right
- **Space**: Jump

Keyboard events are captured by the UIKit `GameViewController` host and forwarded into `GameScene`. The player-facing HUD text intentionally stays touch-only.

### Physics (CollisionHandler)
All collision routing goes through `CollisionHandler`, which implements `SKPhysicsContactDelegate`. It identifies contact pairs by their `categoryBitMask` and dispatches to the appropriate handler (stomp enemy, collect item, hit block, etc.). See `docs/physics.md` for details.

### Camera (CameraController)
Horizontal side-scroller camera. Tracks the player with a configurable lead offset and smoothing factor. Clamped to level bounds so it doesn't scroll past the edges. The Y clamp uses `minY = viewportSize.height / 2` so the viewport bottom sits flush at world y=0 (no gap below ground).

### Parallax Background (GameScene)
4 layers, all children of the scene (NOT worldNode). Repositioned every frame in `updateParallax()` based on camera position:
- **skyLayer** (z: -100, parallax: 0.95): Procedural solid-fill stripes using `GameConstants.Colors`, standardized to RGB(119, 139, 170)
- **cloudLayer** (z: -90): Floating clouds that drift rightward and wrap. Updated in `updateClouds(deltaTime:)`
- **distantLayer** (z: -80, parallax: 0.75): Tileable mountain range
- **nearbyLayer** (z: -60, parallax: 0.4): Randomized PNW evergreen tree silhouettes

All layers are positioned so their base aligns with the top of ground tiles (`groundTop = tileSize * 2`).

### Audio (GameScene)
Background music uses `AVAudioPlayer` (not `SKAudioNode`) loaded from `background_audio.m4a`. Loops infinitely at 40% volume. Note: `AVAudioPlayer` is NOT paused by SpriteKit's `isPaused` — if you implement pause/resume for audio, you need to handle it manually.

### Game State (GameStateManager)
Tracks score, coins, lives, time remaining. Handles coin→life conversion (every 100 coins). Timer expiry now triggers player death through a delegate callback. Delegates UI updates to HUD.

## Delegation Pattern

The codebase uses delegates extensively to decouple systems:

| Delegate Protocol | Implementor | Purpose |
|-------------------|-------------|---------|
| `PlayerDelegate` | GameScene | Player death, fireball shooting, power-up collection |
| `BlockNodeDelegate` | GameScene | Coin/item spawning from hit blocks |
| `GameStateDelegate` | GameScene | Score/lives/time UI updates, game over, level complete |
| `CollisionHandlerDelegate` | GameScene | High-level collision event routing |
| `PauseMenuDelegate` | GameScene | Resume and restart actions |

## Important Gotchas

- **InputManager is unused.** GameScene has its own drag+tap input system. InputManager exists but is not wired in.
- **Hardware keyboard input is not owned by GameScene's responder chain.** It is captured in `GameViewController` and forwarded into `GameScene` helper methods.
- **AssetNames is partially used.** Player and Enemy load textures by hardcoded string names, not via AssetNames constants.
- **Levels are Swift code, not data files.** `LevelManager` currently generates all 5 levels via `LevelGenerator`; `Level1.swift` now acts as a wrapper/entry-point file rather than a hand-authored layout.
- **worldNode vs camera vs background.** Game objects are children of `worldNode`. HUD elements are children of `cameraNode`. Parallax background layers are children of the scene itself (not worldNode, not camera). Don't mix these up.
- **Player physics body is intentionally not a full rectangle.** It keeps beveled bottom corners (4px) to prevent tile-seam snagging, plus a trimmed top and narrower width so the sprite can fit 2-tile tunnels and match the visible art more closely. Do not change it back to a full rectangle.
- **Enemy sizing is only partially centralized.** Goombas now use `GameConstants.goombaSize` and occupy a full 32×32 tile. Koopa and piranha sizes still use local values inside `Enemy.swift`, so check the entity source file before assuming `GameConstants` controls every enemy dimension.
- **Player friction is intentionally zero.** Horizontal movement is driven manually in `Player.updateMovement()`, so surface friction is disabled to prevent wall-slide behavior when the player jumps into solid tiles.
- **Background music doesn't pause.** `AVAudioPlayer` is independent of SpriteKit's `isPaused`. If pause/resume for audio is needed, it must be handled manually.
- **`.pip_tmp/` folder.** Contains a local Pillow install for image processing scripts. It should stay uncommitted; if it appears as untracked in your worktree, exclude it before committing. Reinstall with `pip3 install --target .pip_tmp Pillow` if needed for sprite work.
- **5 levels with progression.** The game has 5 levels. Level completion triggers a transition to the next level. After level 5, the game loops or ends (check `GameScene` for current behavior).
