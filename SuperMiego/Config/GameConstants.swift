import Foundation
import CoreGraphics

struct GameConstants {
    // MARK: - Screen
    static let designWidth: CGFloat = 844  // Reference viewport width used for layout tuning.
    static let designHeight: CGFloat = 390  // Reference viewport height used for layout tuning.

    // MARK: - Tiles
    static let tileSize: CGFloat = 32  // Base world tile size in points.

    // MARK: - Player Movement
    static let playerWalkSpeed: CGFloat = 200  // Target ground speed while moving.
    static let playerRunSpeed: CGFloat = 350  // Reserved faster move speed; not currently used.
    static let playerAcceleration: CGFloat = 800  // Reserved ground acceleration tuning value.
    static let playerDeceleration: CGFloat = 1000  // Reserved ground stop/brake tuning value.
    static let playerAirAcceleration: CGFloat = 550  // Max horizontal velocity change per second while airborne.

    // MARK: - Physics
    static let gravity: CGFloat = -1400  // Reserved gravity constant; GameScene currently sets gravity directly.
    static let terminalVelocity: CGFloat = -800  // Intended max falling speed clamp.

    // MARK: - Player Size
    static let playerSmallSize = CGSize(width: 24, height: 32)  // Logical small-form sprite size reference.
    static let playerSuperSize = CGSize(width: 24, height: 56)  // Logical big-form sprite size reference.

    // MARK: - Enemy
    static let enemyWalkSpeed: CGFloat = 60  // Default enemy patrol speed reference.
    static let goombaSize = CGSize(width: 32, height: 32)  // Standardized goomba size: one tile by one tile.
    static let koopaSize = CGSize(width: 32, height: 40)  // Koopa display size reference.
    static let shellSpeed: CGFloat = 300  // Target speed for kicked koopa shells.

    // MARK: - Items
    static let coinSize = CGSize(width: 16, height: 16)  // Display size for collectible coins.
    static let mushroomSize = CGSize(width: 28, height: 28)  // Display size for mushroom power-ups.
    static let fireFlowerSize = CGSize(width: 28, height: 28)  // Display size for fire flower power-ups.
    static let starSize = CGSize(width: 28, height: 28)  // Display size for invincibility stars.
    static let mushroomMoveSpeed: CGFloat = 80  // Horizontal speed for spawned mushrooms.
    static let starBounceSpeed: CGFloat = 100  // Horizontal speed for moving stars.
    static let starBounceImpulse: CGFloat = 300  // Upward bounce impulse for stars after impact.

    // MARK: - Fireball
    static let fireballSpeed: CGFloat = 400  // Horizontal travel speed for player fireballs.
    static let fireballBounceImpulse: CGFloat = 200  // Bounce strength when fireballs hit the ground.
    static let fireballSize = CGSize(width: 12, height: 12)  // Display size for fireballs.
    static let maxFireballs: Int = 2  // Max simultaneous player fireballs allowed.

    // MARK: - Camera
    static let cameraLeadOffset: CGFloat = 50  // Intended look-ahead distance for camera follow.
    static let cameraSmoothing: CGFloat = 0.08  // Intended camera lerp factor.

    // MARK: - Gameplay
    static let startingLives: Int = 3  // Lives granted at the start of a run.
    static let coinsForLife: Int = 100  // Coins required to award an extra life.
    static let invincibilityDuration: TimeInterval = 10.0  // Duration of star-mode invincibility.
    static let powerUpBlinkDuration: TimeInterval = 2.0  // Blink duration after taking damage.
    static let levelTimeLimit: TimeInterval = 300  // Countdown timer per level, in seconds.

    // MARK: - Scoring
    static let coinPoints: Int = 200  // Score awarded for collecting a coin.
    static let enemyStompPoints: Int = 100  // Base score for stomping an enemy.
    static let blockItemPoints: Int = 200  // Score awarded when spawning an item from a block.
    static let comboMultiplier: Int = 2  // Score multiplier step for chained stomps.
    static let maxComboMultiplier: Int = 8  // Cap for stomp combo scaling.

    // MARK: - Animation
    static let playerIdleFrameDuration: TimeInterval = 0.15  // Reserved idle animation timing.
    static let playerWalkFrameDuration: TimeInterval = 0.1  // Reserved player run frame timing.
    static let enemyWalkFrameDuration: TimeInterval = 0.2  // Reserved enemy walk frame timing.
    static let blockBumpDuration: TimeInterval = 0.15  // Total duration of the block bump animation.
    static let blockBumpHeight: CGFloat = 8  // Vertical travel distance for a bumped block.

    // MARK: - Level
    static let levelWidth: Int = 120  // Default procedural level width in tiles.
    static let levelHeight: Int = 14  // Default procedural level height in tiles.
    static let groundHeight: Int = 2  // Ground thickness from the bottom of the map, in tiles.

    // MARK: - Touch Input
    static let dragDeadZone: CGFloat = 20.0  // Minimum drag distance before movement starts.
    static let dragMaxDistance: CGFloat = 120.0  // Drag distance that maps to full movement speed.
    static let tapMaxDuration: TimeInterval = 0.25  // Max touch duration that still counts as a tap.
    static let tapMaxMovement: CGFloat = 15.0  // Max finger travel that still counts as a tap.

    // MARK: - Jump Forces (Tap System)
    static let lowJumpForce: CGFloat = 609  // Vertical impulse for the ground jump.
    static let highJumpForce: CGFloat = 861  // Vertical impulse for the extra air jump.
    static let maxAirJumps: Int = 1  // Extra jumps allowed after leaving the ground.

    // MARK: - Debug
    struct Debug {
        /// When true, draws semi-transparent red overlays on all collision bodies.
        static let showCollisionOverlays = false  // Enables red physics-body overlays for debugging.
    }

    // MARK: - Colors
    struct Colors {
        static let backgroundRed: CGFloat = 119.0 / 255.0  // Shared sky/background red channel.
        static let backgroundGreen: CGFloat = 139.0 / 255.0  // Shared sky/background green channel.
        static let backgroundBlue: CGFloat = 170.0 / 255.0  // Shared sky/background blue channel.
    }
}
