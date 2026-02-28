# Architecture Overview

A SpriteKit-based 2D platformer built with SwiftUI as the app shell. This document maps the codebase for AI agents.

## Directory Structure

```
SuperMiego/
├── App/
│   └── SuperMiegoApp.swift          ← SwiftUI entry point, launches MenuScene
├── Assets.xcassets/
│   └── Sprites/
│       ├── Player/                  ← player_idle, player_jump, player_run, player_dead
│       └── Enemies/                 ← goomba_walk1, goomba_walk2, goomba_dead
├── Config/
│   ├── GameConstants.swift          ← All tunable values (speeds, sizes, forces, scoring)
│   ├── PhysicsCategories.swift      ← Bitmask definitions for collision system
│   └── AssetNames.swift             ← Asset name constants (partially used)
├── Entities/
│   ├── Player.swift                 ← Player state machine, movement, animation, power-ups
│   └── Enemy.swift                  ← Goomba/Koopa/Piranha behavior, stomp/shell mechanics
├── Levels/
│   ├── Level1.swift                 ← Level layout as a 2D character array
│   └── LevelLoader.swift            ← Parses level data into SpriteKit nodes
├── Nodes/
│   ├── BlockNode.swift              ← Ground, brick, question blocks, pipes, platforms
│   └── ItemNode.swift               ← Mushroom, fire flower, star, 1-up, fireball
├── Scenes/
│   ├── MenuScene.swift              ← Title screen with rain/mist effects
│   └── GameScene.swift              ← Main game loop, input, systems orchestration
├── Systems/
│   ├── CameraController.swift       ← Side-scrolling camera with player tracking
│   ├── CollisionHandler.swift       ← SKPhysicsContactDelegate routing
│   ├── GameStateManager.swift       ← Score, coins, lives, timer, level completion
│   └── InputManager.swift           ← (Unused) Alternative input scheme
└── UI/
    ├── HUD.swift                    ← Score, coins, lives, time, world display
    └── PauseMenuOverlay.swift       ← Pause menu with resume/restart
```

## Execution Flow

```
SuperMiegoApp (SwiftUI)
  └─ SpriteView presents MenuScene
       └─ START GAME transitions to GameScene
            ├─ didMove(to:)
            │   ├─ Creates worldNode (container for all game objects)
            │   ├─ LevelLoader.buildLevel(from: Level1, in: worldNode)
            │   ├─ Creates Player, adds to worldNode
            │   ├─ Sets up CameraController, CollisionHandler, GameStateManager
            │   └─ Creates HUD (attached to camera, not world)
            └─ update(_:)
                ├─ GameStateManager.update (timer countdown)
                ├─ Player.update (movement, jump, animation)
                ├─ Enemy.update (walk patrol)
                ├─ ItemNode.update (mushroom/star movement)
                ├─ Fireball.update
                └─ CameraController.update (follow player)
```

## Key Systems

### Input (GameScene)
Touch-based, implemented directly in GameScene (not via InputManager):
- **Drag horizontally**: Move left/right. Velocity scales with drag distance (dead zone: 20pt, max: 120pt).
- **Tap**: Jump. Ground tap = low jump, air tap = high jump (up to 3 air jumps).
- The HUD pause button intercepts touches before game input.

### Physics (CollisionHandler)
All collision routing goes through `CollisionHandler`, which implements `SKPhysicsContactDelegate`. It identifies contact pairs by their `categoryBitMask` and dispatches to the appropriate handler (stomp enemy, collect item, hit block, etc.). See `docs/physics.md` for details.

### Camera (CameraController)
Horizontal side-scroller camera. Tracks the player with a configurable lead offset and smoothing factor. Clamped to level bounds so it doesn't scroll past the edges.

### Game State (GameStateManager)
Tracks score, coins, lives, time remaining. Handles coin→life conversion (every 100 coins). Manages level completion and game over conditions. Delegates UI updates to HUD.

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
- **AssetNames is partially used.** Player and Enemy load textures by hardcoded string names, not via AssetNames constants.
- **Levels are Swift code, not data files.** Level1.swift defines the layout as a `[[Character]]` array. There are no JSON/plist level files.
- **worldNode vs camera.** Game objects are children of `worldNode`. HUD elements are children of `cameraNode` (so they stay on screen). Don't add game objects to the camera or HUD elements to the world.
- **Player physics body uses beveled corners.** The bottom corners are beveled (4px) to prevent getting stuck on tile seams between adjacent ground blocks. This is a known SpriteKit issue. Do not change the physics body back to a simple rectangle.
