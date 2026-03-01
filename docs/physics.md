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
| `enemyProjectile` | 12 | 4096 | Snowflake/fireball projectiles from turtle enemies |

## Collision vs Contact

SpriteKit distinguishes between:
- **collisionBitMask**: Physical collisions (things bounce off each other). Handled by the physics engine automatically.
- **contactTestBitMask**: Contact notifications (triggers `didBegin(contact:)`). Handled in code by `CollisionHandler`.

Example: The player *collides* with ground/blocks/platforms (can't pass through) and *contacts* enemies/items/coins (triggers game logic).

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
| Player | Ground/Block/Platform | Ground/support tracking (for jump state) |
| Fireball | Enemy | Kill enemy |
| Enemy | Ground/Block | Reverse walk direction (via `hitWall()`) |

## Ground Detection

Grounding uses multiple signals:
- `CollisionHandler` tracks only true support contacts in an internal set, so brushing a pipe wall does not decrement the player's support count.
- `contactWithGround()` / `endContactWithGround()` still maintain `groundContactCount` for confirmed landing contacts.
- `Player.updateGroundState()` also checks current contact bodies plus three probe points just below the feet, which makes pipe tops and tile-edge transitions more stable.
- The player is treated as grounded while supported unless vertical rise speed exceeds roughly 25% of `lowJumpForce`, which filters out small physics jitter while walking.

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

The player uses a polygon body with beveled bottom corners, a trimmed top, and a narrower width, NOT a full rectangle:

```
    ┌──────────┐
    │          │
    │          │
    │          │
    └─╲      ╱─┘
       ╲────╱
      4px bevel
```

This prevents the player from catching on seams between adjacent ground tiles, keeps the hitbox closer to the visible sprite, and allows clean travel through 2-tile tunnels. Do not revert this to `SKPhysicsBody(rectangleOf:)`.
