import Foundation
import CoreGraphics

struct GameConstants {
    // MARK: - Screen
    static let designWidth: CGFloat = 844  // iPhone landscape base
    static let designHeight: CGFloat = 390

    // MARK: - Tiles
    static let tileSize: CGFloat = 32

    // MARK: - Player Movement
    static let playerWalkSpeed: CGFloat = 200
    static let playerRunSpeed: CGFloat = 350
    static let playerAcceleration: CGFloat = 800
    static let playerDeceleration: CGFloat = 1000
    static let playerAirAcceleration: CGFloat = 400

    // MARK: - Player Jump
    static let playerJumpImpulse: CGFloat = 420
    static let playerJumpHoldForce: CGFloat = 600
    static let playerMaxJumpTime: TimeInterval = 0.25
    static let playerMinJumpTime: TimeInterval = 0.1

    // MARK: - Physics
    static let gravity: CGFloat = -1400
    static let terminalVelocity: CGFloat = -800

    // MARK: - Player Size
    static let playerSmallSize = CGSize(width: 24, height: 32)
    static let playerSuperSize = CGSize(width: 24, height: 56)

    // MARK: - Enemy
    static let enemyWalkSpeed: CGFloat = 60
    static let goombaSize = CGSize(width: 32, height: 32)
    static let koopaSize = CGSize(width: 32, height: 40)
    static let shellSpeed: CGFloat = 300

    // MARK: - Items
    static let coinSize = CGSize(width: 16, height: 16)
    static let mushroomSize = CGSize(width: 28, height: 28)
    static let fireFlowerSize = CGSize(width: 28, height: 28)
    static let starSize = CGSize(width: 28, height: 28)
    static let mushroomMoveSpeed: CGFloat = 80
    static let starBounceSpeed: CGFloat = 100
    static let starBounceImpulse: CGFloat = 300

    // MARK: - Fireball
    static let fireballSpeed: CGFloat = 400
    static let fireballBounceImpulse: CGFloat = 200
    static let fireballSize = CGSize(width: 12, height: 12)
    static let maxFireballs: Int = 2

    // MARK: - Camera
    static let cameraLeadOffset: CGFloat = 50
    static let cameraSmoothing: CGFloat = 0.08

    // MARK: - Gameplay
    static let startingLives: Int = 3
    static let coinsForLife: Int = 100
    static let invincibilityDuration: TimeInterval = 10.0
    static let powerUpBlinkDuration: TimeInterval = 2.0
    static let levelTimeLimit: TimeInterval = 300

    // MARK: - Scoring
    static let coinPoints: Int = 200
    static let enemyStompPoints: Int = 100
    static let blockItemPoints: Int = 200
    static let comboMultiplier: Int = 2
    static let maxComboMultiplier: Int = 8

    // MARK: - Animation
    static let playerIdleFrameDuration: TimeInterval = 0.15
    static let playerWalkFrameDuration: TimeInterval = 0.1
    static let enemyWalkFrameDuration: TimeInterval = 0.2
    static let blockBumpDuration: TimeInterval = 0.15
    static let blockBumpHeight: CGFloat = 8

    // MARK: - Level
    static let levelWidth: Int = 120  // tiles
    static let levelHeight: Int = 14  // tiles
    static let groundHeight: Int = 2  // tiles from bottom

    // MARK: - Touch Input
    static let dragDeadZone: CGFloat = 20.0           // Pixels before drag registers
    static let dragMaxDistance: CGFloat = 120.0       // Pixels for full speed
    static let tapMaxDuration: TimeInterval = 0.25    // Max time for tap gesture
    static let doubleTapWindow: TimeInterval = 0.30   // Window between taps for double-tap
    static let tapMaxMovement: CGFloat = 15.0         // Max movement distance for tap gesture

    // MARK: - Jump Forces (Tap System)
    static let lowJumpForce: CGFloat = 609            // Ground jump (870 * 0.7)
    static let highJumpForce: CGFloat = 861           // Air jump (1230 * 0.7)
    static let maxAirJumps: Int = 1                   // 1 = double-jump total

    // MARK: - Debug
    struct Debug {
        /// When true, draws semi-transparent red overlays on all collision bodies.
        static let showCollisionOverlays = false
    }

    // MARK: - Colors
    struct Colors {
        static let backgroundRed: CGFloat = 119.0 / 255.0
        static let backgroundGreen: CGFloat = 139.0 / 255.0
        static let backgroundBlue: CGFloat = 170.0 / 255.0
    }
}
