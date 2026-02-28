# Game Constants Reference

All tunable values live in `SuperMiego/Config/GameConstants.swift`. This is the single source of truth for game feel, physics, and balance. Modify values here rather than hardcoding numbers in individual files.

## Screen

| Constant | Value | Notes |
|----------|-------|-------|
| `designWidth` | 844 | Target screen width in points |
| `designHeight` | 390 | Target screen height in points |

## Tiles

| Constant | Value | Notes |
|----------|-------|-------|
| `tileSize` | 32 | Size of each grid tile in points |

## Player Movement

| Constant | Value | Notes |
|----------|-------|-------|
| `walkSpeed` | 200 | Horizontal movement speed |
| `runSpeed` | 350 | (Defined but currently unused in Player.swift) |
| `lowJumpForce` | 609 | Upward impulse for ground tap jump |
| `highJumpForce` | 861 | Upward impulse for air tap jump |

The player currently has up to 3 air jumps (hardcoded in `Player.swift`, not in GameConstants).

## Physics

| Constant | Value | Notes |
|----------|-------|-------|
| `gravity` | -1400 | World gravity (negative = downward) |
| `terminalVelocity` | -800 | Max fall speed |

## Enemies

| Constant | Value | Notes |
|----------|-------|-------|
| `walkSpeed` | 60 | Goomba/Koopa patrol speed |
| `goombaSize` | 32×32 | Display size for goombas |
| `koopaSize` | 32×40 | Display size for koopas |
| `shellSpeed` | 300 | Kicked koopa shell speed |

Note: Enemy.swift currently uses its own hardcoded sizes (28×28 for goomba, 28×36 for koopa) which differ from GameConstants. This is a known inconsistency.

## Items

| Constant | Value | Notes |
|----------|-------|-------|
| `mushroomSpeed` | 80 | Mushroom horizontal movement |
| `starBounceSpeed` | 200 | Star vertical bounce impulse |
| `fireballSpeed` | 400 | Fireball horizontal speed |
| `fireballBounce` | 200 | Fireball bounce impulse |
| `fireballSize` | 12×12 | Fireball display size |
| `maxFireballs` | 2 | Max simultaneous fireballs |

## Camera

| Constant | Value | Notes |
|----------|-------|-------|
| `leadOffset` | 50 | Camera leads ahead of player |
| `smoothing` | 0.08 | Camera follow smoothing (0–1, lower = smoother) |

## Scoring

| Constant | Value | Notes |
|----------|-------|-------|
| `coin` | 200 | Points per coin |
| `stomp` | 100 | Points per enemy stomp |
| `block` | 200 | Points per block hit |
| `comboMultiplier` | up to 8 | Increases with consecutive stomps |

## Gameplay

| Constant | Value | Notes |
|----------|-------|-------|
| `startingLives` | 3 | Lives at game start |
| `coinsForLife` | 100 | Coins needed for extra life |
| `invincibilityDuration` | 10.0 | Star power duration (seconds) |
| `levelTime` | 300 | Level timer (seconds) |

## Touch Input

| Constant | Value | Notes |
|----------|-------|-------|
| `dragDeadZone` | 20 | Minimum drag distance before movement |
| `maxDragDistance` | 120 | Drag distance for max speed |
| `tapThreshold` | — | Max movement for a touch to count as tap (not drag) |

## Debug

| Constant | Value | Notes |
|----------|-------|-------|
| `showCollisionOverlays` | false | Renders red overlays on all physics bodies |

## Level

| Constant | Value | Notes |
|----------|-------|-------|
| `levelWidth` | 120 | Level width in tiles |
| `levelHeight` | 14 | Level height in tiles |
| `groundHeight` | 2 | Ground thickness in tiles |
