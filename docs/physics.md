# Physics & Collision System

## Physics Categories (Bitmasks)

Defined in `SuperMiego/Config/PhysicsCategories.swift`:

| Category | Bit | Value | Used By |
|----------|-----|-------|---------|
| `none` | — | 0 | Disabled physics |
| `player` | 0 | 1 | Player node |
| `ground` | 1 | 2 | Ground blocks |
| `block` | 2 | 4 | Bricks, question blocks, pipes |
| `enemy` | 3 | 8 | Goombas, Koopas, Piranhas |
| `item` | 4 | 16 | Mushrooms, fire flowers, stars, 1-ups |
| `coin` | 5 | 32 | Collectible coins |
| `playerFeet` | 6 | 64 | (Reserved, not actively used) |
| `flagpole` | 7 | 128 | End-of-level flagpole |
| `fireball` | 8 | 256 | Player fireballs |
| `deathZone` | 9 | 512 | Pits, water |
| `platform` | 10 | 1024 | One-way platforms |
| `shell` | 11 | 2048 | Kicked Koopa shells |

## Collision vs Contact

SpriteKit distinguishes between:
- **collisionBitMask**: Physical collisions (things bounce off each other). Handled by the physics engine automatically.
- **contactTestBitMask**: Contact notifications (triggers `didBegin(contact:)`). Handled in code by `CollisionHandler`.

Example: The player *collides* with ground/blocks (can't pass through) and *contacts* enemies/items/coins (triggers game logic).

## Collision Handler

`CollisionHandler` (`SuperMiego/Systems/CollisionHandler.swift`) implements `SKPhysicsContactDelegate`. It:

1. Receives `didBegin(contact:)` and `didEnd(contact:)` calls from SpriteKit
2. Identifies the two bodies by `categoryBitMask`
3. Routes to specific handler methods (e.g., player↔enemy, player↔item)

Key collision interactions:

| Body A | Body B | Behavior |
|--------|--------|----------|
| Player | Enemy | Stomp (if falling onto) or take damage (if side contact) |
| Player | Item | Collect power-up |
| Player | Coin | Collect coin, add score |
| Player | Flagpole | Level complete |
| Player | DeathZone | Player dies |
| Player | Ground | Ground contact tracking (for jump state) |
| Fireball | Enemy | Kill enemy |
| Enemy | Ground/Block | Reverse walk direction (via `hitWall()`) |

## Ground Detection

The player tracks ground contact via a counter (`groundContactCount`):
- `contactWithGround()` increments the counter
- `endContactWithGround()` decrements it
- Player is considered grounded when `groundContactCount > 0 && velocity.dy <= 1`

This counter approach handles the case where the player stands on multiple ground tiles simultaneously.

Coyote time (0.1s) gives a brief grace period after leaving the ground where the player can still jump.

## Debug Collision Overlays

Controlled by `GameConstants.Debug.showCollisionOverlays` (default: `false`).

When enabled:
- Semi-transparent red rectangles are drawn over every physics body
- A recursive scene walker in `GameScene` catches any physics body without an explicit overlay
- Background tree opacity is reduced to 0.1 for visibility
- Console logs all discovered physics bodies

To enable, set the flag to `true` in `GameConstants.swift`:
```swift
struct Debug {
    static let showCollisionOverlays = true
}
```

The overlays are added as child nodes named `"collisionDebug"` with `zPosition = 0.1` relative to their parent.

## Player Physics Body Shape

The player uses a polygon body with beveled bottom corners, NOT a simple rectangle:

```
    ┌──────────┐
    │          │
    │          │
    │          │
    └─╲      ╱─┘
       ╲────╱
      4px bevel
```

This prevents the player from catching on seams between adjacent ground tiles — a well-known SpriteKit bug where rectangle bodies snag on the invisible boundary between two perfectly aligned tiles. Do not revert this to `SKPhysicsBody(rectangleOf:)`.
