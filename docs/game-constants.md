# Game Constants Reference

Most tunable values live in `SuperMiego/Config/GameConstants.swift`. It is the primary balancing file, but some movement/collision tuning still lives in `Player.swift` and `GameScene.swift`.

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
| `playerWalkSpeed` | 200 | Base horizontal movement constant |
| `playerRunSpeed` | 350 | Defined but currently unused |
| `playerAcceleration` | 800 | Ground acceleration tuning constant |
| `playerDeceleration` | 1000 | Ground deceleration tuning constant |
| `playerAirAcceleration` | 400 | Air acceleration tuning constant |

Note: `Player.swift` still uses some local movement values instead of these constants, so check the entity file when tuning actual runtime feel.

## Player Jump

| Constant | Value | Notes |
|----------|-------|-------|
| `playerJumpImpulse` | 420 | Legacy jump impulse constant |
| `playerJumpHoldForce` | 600 | Legacy hold-force constant |
| `playerMaxJumpTime` | 0.25 | Legacy max hold time |
| `playerMinJumpTime` | 0.1 | Legacy min hold time |
| `lowJumpForce` | 609 | Actual ground tap jump impulse |
| `highJumpForce` | 861 | Actual air jump impulse |
| `maxAirJumps` | 1 | Extra air jumps after leaving ground (1 = double-jump total) |

The current tap-jump path uses `lowJumpForce` / `highJumpForce`. The older hold-to-jump constants remain defined but are not the active jump path.

## Physics

| Constant | Value | Notes |
|----------|-------|-------|
| `gravity` | -1400 | World gravity (negative = downward) |
| `terminalVelocity` | -800 | Max fall speed |

Note: `GameScene` currently sets `physicsWorld.gravity` directly to `-12`, so the runtime gravity does not match `GameConstants.gravity`.

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
| `mushroomMoveSpeed` | 80 | Mushroom horizontal movement |
| `starBounceSpeed` | 100 | Star horizontal movement |
| `starBounceImpulse` | 300 | Star bounce impulse |
| `fireballSpeed` | 400 | Fireball horizontal speed |
| `fireballBounceImpulse` | 200 | Fireball bounce impulse |
| `fireballSize` | 12×12 | Fireball display size |
| `maxFireballs` | 2 | Max simultaneous fireballs |

## Camera

| Constant | Value | Notes |
|----------|-------|-------|
| `cameraLeadOffset` | 50 | Camera leads ahead of player |
| `cameraSmoothing` | 0.08 | Camera follow smoothing (0–1, lower = smoother) |

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
| `powerUpBlinkDuration` | 2.0 | Damage blink duration |
| `levelTimeLimit` | 300 | Level timer (seconds) |

## Touch Input

| Constant | Value | Notes |
|----------|-------|-------|
| `dragDeadZone` | 20 | Minimum drag distance before movement |
| `dragMaxDistance` | 120 | Drag distance for max speed |
| `tapMaxDuration` | 0.25 | Max time for a tap gesture |
| `doubleTapWindow` | 0.30 | Defined, but double-tap input is not currently used |
| `tapMaxMovement` | 15 | Max movement for a touch to count as tap |

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
