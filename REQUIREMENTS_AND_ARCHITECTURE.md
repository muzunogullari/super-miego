# Super Miego - Requirements & Architecture

## Project Overview

A 2D side-scrolling platformer for iOS, inspired by Super Mario Bros gameplay mechanics with a Pacific Northwest theme (forests, rain, water, moss, evergreens).

**Target Platform:** iPhone (Landscape)
**Framework:** SpriteKit (Native Swift)
**Minimum iOS:** 17.0
**Initial Scope:** Level 1 with placeholder assets

---

## Theme & Visual Direction

### Pacific Northwest Aesthetic
- **Environment:** Temperate rainforest, tall evergreens (Douglas fir, Cedar), ferns, moss-covered surfaces
- **Weather:** Misty, overcast, light rain particles
- **Water:** Streams, puddles, waterfalls as level elements
- **Color Palette:** Deep greens, browns, slate blues, fog grays
- **Mood:** Lush, damp, mysterious

### Placeholder Asset Strategy
All assets will use simple colored shapes/primitives initially, structured for easy replacement:
- Player: Green rectangle
- Enemies: Red shapes
- Blocks: Brown/gray rectangles
- Collectibles: Yellow circles
- Background: Layered gradient rectangles

---

## Gameplay Mechanics (Mario-Style)

### Player States
| State | Description |
|-------|-------------|
| Small | Default state, one-hit death |
| Super | After mushroom, taller, can break bricks, reverts to Small on hit |
| Fire | After fire flower, can shoot projectiles, reverts to Super on hit |
| Invincible | After star, temporary invulnerability + kills enemies on contact |
| Dead | Death animation, lose life, respawn or game over |

### Player Physics
- **Run Speed:** Accelerates to max velocity, decelerates with friction
- **Jump:** Variable height based on button hold duration (short tap = small jump, hold = full jump)
- **Gravity:** Consistent downward acceleration
- **Air Control:** Horizontal movement allowed while airborne (reduced acceleration)

### Blocks
| Block Type | Behavior |
|------------|----------|
| Ground | Solid, static platform |
| Brick | Breakable when Super/Fire, bounces when Small, may contain coins |
| Question (?) | Releases item on hit (coin, mushroom, fire flower, star), becomes empty |
| Empty | Previously hit question block, solid but inactive |
| Pipe | Decorative or warp point (future levels) |
| Platform | One-way platforms (can jump through from below) |

### Items & Power-ups
| Item | Effect |
|------|--------|
| Coin | +1 coin, 100 coins = extra life |
| Mushroom | Small → Super (grows larger) |
| Fire Flower | Super → Fire (can shoot fireballs) |
| Star | Temporary invincibility (~10 seconds) |
| 1-Up Mushroom | +1 life |

### Enemies
| Enemy | Behavior | Defeat Method |
|-------|----------|---------------|
| Goomba-type | Walks forward, turns at edges/walls | Stomp (top), fireball |
| Koopa-type | Walks, retreats into shell when stomped | Stomp → shell, kick shell, fireball |
| Piranha-type | Emerges from pipes periodically | Fireball only (no stomp) |

### Scoring
- Coin: 200 points
- Enemy stomp: 100 points (combos multiply)
- Block item: 200 points
- Flagpole: Height-based bonus (100-5000)

### Lives & Death
- Start with 3 lives
- Death triggers: Enemy contact (when Small), falling into pit, timer expiration
- On death: Respawn at level start or checkpoint
- Game Over: 0 lives → restart level

### Level Completion
- Reach flagpole at end of level
- Timer bonus converted to points
- Transition to next level (future)

---

## Controls (Simplified Touch)

### Control Scheme
```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│                    [GAME VIEW]                          │
│                                                         │
├───────────────────────┬─────────────────────────────────┤
│                       │                                 │
│   LEFT    │   RIGHT   │           JUMP / ACTION         │
│   (tap)   │   (tap)   │         (tap = jump)            │
│           │           │     (tap while Fire = shoot)    │
│    ◄──    │    ──►    │              ▲                  │
│                       │                                 │
└───────────────────────┴─────────────────────────────────┘
     Left 1/3 screen          Right 2/3 screen
```

### Touch Behavior
- **Left third of screen:**
  - Tap left half → move left
  - Tap right half → move right
  - Release → stop (with deceleration)

- **Right two-thirds of screen:**
  - Tap → jump (hold for higher jump)
  - While Fire state + in-air or grounded → shoot fireball

- **Pause:** Tap pause button (top corner)

---

## Technical Architecture

### Project Structure
```
SuperMiego/
├── SuperMiego.xcodeproj
├── SuperMiego/
│   ├── App/
│   │   ├── SuperMiegoApp.swift          # App entry point
│   │   └── Info.plist
│   │
│   ├── Scenes/
│   │   ├── GameScene.swift              # Main gameplay scene
│   │   ├── MenuScene.swift              # Title/start menu
│   │   ├── GameOverScene.swift          # Game over screen
│   │   └── LevelCompleteScene.swift     # Level completion
│   │
│   ├── Entities/
│   │   ├── Player.swift                 # Player character
│   │   ├── Enemy.swift                  # Base enemy class
│   │   ├── Goomba.swift                 # Goomba-type enemy
│   │   ├── Koopa.swift                  # Koopa-type enemy
│   │   └── Piranha.swift                # Pipe enemy
│   │
│   ├── Components/
│   │   ├── PhysicsComponent.swift       # Physics body setup
│   │   ├── AnimationComponent.swift     # Sprite animations
│   │   └── StateComponent.swift         # State machine
│   │
│   ├── Nodes/
│   │   ├── BlockNode.swift              # Interactive blocks
│   │   ├── CoinNode.swift               # Collectible coins
│   │   ├── ItemNode.swift               # Power-up items
│   │   └── FlagpoleNode.swift           # Level end
│   │
│   ├── Systems/
│   │   ├── InputManager.swift           # Touch input handling
│   │   ├── CameraController.swift       # Side-scrolling camera
│   │   ├── CollisionHandler.swift       # Physics collision logic
│   │   ├── GameStateManager.swift       # Lives, score, game state
│   │   └── AudioManager.swift           # Sound effects & music
│   │
│   ├── Levels/
│   │   ├── LevelLoader.swift            # Parse level data
│   │   ├── Level1.swift                 # Level 1 definition
│   │   └── TileMap.swift                # Tile-based level structure
│   │
│   ├── Config/
│   │   ├── GameConstants.swift          # Physics, speeds, sizes
│   │   ├── PhysicsCategories.swift      # Collision bitmasks
│   │   └── AssetNames.swift             # Centralized asset references
│   │
│   ├── UI/
│   │   ├── HUD.swift                    # Score, coins, lives, timer
│   │   └── PauseMenu.swift              # Pause overlay
│   │
│   └── Assets.xcassets/
│       ├── Sprites/
│       │   ├── Player/
│       │   ├── Enemies/
│       │   ├── Blocks/
│       │   ├── Items/
│       │   └── Environment/
│       ├── Backgrounds/
│       └── UI/
│
├── SuperMiegoTests/
└── README.md
```

### Core Classes

#### GameScene
- Main update loop (60 FPS)
- Manages all game entities
- Handles physics simulation
- Coordinates subsystems

#### Player
- State machine (Small, Super, Fire, Invincible, Dead)
- Physics body with proper collision shape
- Animation controller for each state
- Input response (movement, jump, shoot)

#### InputManager
- Processes touch events
- Maps screen regions to actions
- Provides input state to Player

#### CameraController
- Follows player horizontally
- Clamps to level bounds
- Smooth interpolation

#### CollisionHandler
- Physics contact delegate
- Routes collisions to appropriate handlers
- Manages enemy stomps, item collection, block hits

### Physics Categories (Bitmasks)
```swift
struct PhysicsCategory {
    static let none:        UInt32 = 0
    static let player:      UInt32 = 0b1        // 1
    static let ground:      UInt32 = 0b10       // 2
    static let block:       UInt32 = 0b100      // 4
    static let enemy:       UInt32 = 0b1000     // 8
    static let item:        UInt32 = 0b10000    // 16
    static let coin:        UInt32 = 0b100000   // 32
    static let playerFeet:  UInt32 = 0b1000000  // 64 (for stomp detection)
    static let flagpole:    UInt32 = 0b10000000 // 128
}
```

### Game Constants
```swift
struct GameConstants {
    // Player
    static let playerWalkSpeed: CGFloat = 200
    static let playerRunSpeed: CGFloat = 350
    static let playerJumpImpulse: CGFloat = 450
    static let playerMaxJumpTime: TimeInterval = 0.3

    // Physics
    static let gravity: CGFloat = -980
    static let friction: CGFloat = 0.2

    // Tiles
    static let tileSize: CGFloat = 32

    // Camera
    static let cameraSmoothing: CGFloat = 0.1

    // Gameplay
    static let startingLives: Int = 3
    static let coinsForLife: Int = 100
    static let invincibilityDuration: TimeInterval = 10.0
    static let levelTimeLimit: TimeInterval = 300 // 5 minutes
}
```

---

## Level 1 Design

### Structure
```
Total Width: ~100 tiles (3200 points at 32pt tiles)
Height: 14 tiles (448 points, fits landscape iPhone)

Sections:
[Start] → [Training] → [First Enemy] → [Platforming] → [Water/Pit] → [Finale] → [Flagpole]
```

### Tile Legend
```
- = empty/sky
# = ground
B = brick
? = question block (coin)
M = question block (mushroom)
F = question block (fire flower)
G = goomba
K = koopa
P = pipe (2 tiles wide, variable height)
| = pipe body
W = water/pit (death zone)
> = flagpole
```

### Level 1 Layout (Simplified ASCII)
```
Section 1: Start & Training
----------------------------------?--B-B-?-B-----
----------------------------------------------
----------------------------------------------
----------------------------------------------
----------------------------------------------
----------------------------------------------
----------------------------------------------
----------------------------------------------
----------------------------------------------
##############################################

Section 2: First Enemies & Pits
-----?--M--?--------------------------------
--------------------------------------------
--------------------------------------------
--------------------------------------------
--------------------------------------------
-------------G-------G----G-----------------
--------------------------------------------
--------------------------------------------
------##########--------#######-------------
######          ########       ##############
      (pit)              (pit)

Section 3: Pipes & Platforms
        ___
       |   |  ___
    ___|   | |   |___
   |       | |       |
   |   P   | |   P   |
############################################

Section 4: Flagpole
                    |
                    |
                    |
                    |
                    |
                   [>]
######################
```

### Level Elements Summary
- Platforms with gaps (death pits)
- Question blocks with coins
- 1 Mushroom block (early, teaches power-up)
- 1 Fire flower block (mid-level, after platforming section)
- 5-8 Goombas placed progressively
- 2-3 Koopas in later section
- 3 Pipes (decorative, maybe 1 secret warp in future)
- Water pit visual with death zone
- Flagpole at end

---

## Asset Pipeline

### Placeholder Assets (Phase 1)
Generated programmatically or simple shapes:

| Asset | Placeholder | Final Notes |
|-------|-------------|-------------|
| Player (Small) | 24x32 green rect | Hiker/ranger character |
| Player (Super) | 24x64 green rect | Taller version |
| Goomba | 32x32 red circle | Banana slug or similar |
| Koopa | 32x40 red rect | Raccoon or beaver |
| Ground tile | 32x32 brown rect | Mossy earth/rocks |
| Brick | 32x32 gray rect | Bark/log texture |
| Question block | 32x32 yellow rect | Fern-wrapped mystery |
| Coin | 16x16 yellow circle | Pinecone or acorn |
| Mushroom | 24x24 orange rect | Actual mushroom (chanterelle) |
| Pipe | 64xN green rect | Hollow log |
| Background | Gradient layers | Misty forest parallax |

### Asset Replacement Strategy
1. Assets defined via `AssetNames.swift` constants
2. All sprites loaded through central `AssetLoader`
3. Replace placeholder images in `Assets.xcassets`
4. No code changes required for visual updates

---

## Audio Design

### Sound Effects (Placeholder: System Sounds)
| Event | Sound |
|-------|-------|
| Jump | Short blip |
| Coin collect | Chime |
| Power-up | Rising tone |
| Enemy stomp | Thud |
| Player hit | Descending tone |
| Player death | Sad jingle |
| Block break | Crunch |
| Fireball | Whoosh |
| Level complete | Fanfare |

### Music
- Level BGM: Placeholder silence or simple loop
- Final: Ambient forest sounds + light adventure music

---

## Development Phases

### Phase 1: Foundation (Current)
- [x] Requirements document
- [ ] Xcode project setup
- [ ] Basic GameScene with placeholder tiles
- [ ] Player movement & physics
- [ ] Touch input system
- [ ] Camera following

### Phase 2: Core Gameplay
- [ ] Blocks (ground, brick, question)
- [ ] Collision system
- [ ] Player states (small, super)
- [ ] Coins & scoring
- [ ] Basic enemies (goomba)

### Phase 3: Full Mechanics
- [ ] All power-ups (mushroom, fire flower, star)
- [ ] All enemies (koopa, piranha)
- [ ] HUD (lives, score, coins, timer)
- [ ] Death & respawn
- [ ] Level complete (flagpole)

### Phase 4: Polish
- [ ] Menus (start, pause, game over)
- [ ] Sound effects
- [ ] Particle effects (dust, water drops)
- [ ] Background parallax
- [ ] Screen shake & juice

### Phase 5: Assets
- [ ] Import custom sprites
- [ ] Import custom audio
- [ ] Final visual polish

---

## Open Questions / Future Considerations

1. **Save System:** Save progress between sessions?
2. **Multiple Levels:** Level selection or linear progression?
3. **Achievements:** Game Center integration?
4. **Haptics:** Vibration feedback on impacts?
5. **Accessibility:** VoiceOver support, colorblind modes?
6. **Analytics:** Track player deaths, completion rates?

---

*Document Version: 1.0*
*Last Updated: February 2026*
