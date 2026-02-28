import SpriteKit

enum PlayerState {
    case small
    case big
    case fire
    case invincible
    case dead
}

enum JumpType {
    case none
    case low
    case high
}

protocol PlayerDelegate: AnyObject {
    func playerDidDie(_ player: Player)
    func playerDidShootFireball(_ player: Player, at position: CGPoint, direction: CGFloat)
    func playerDidCollectPowerUp(_ player: Player, type: ItemType)
}

class Player: SKSpriteNode {
    weak var playerDelegate: PlayerDelegate?

    // MARK: - State
    private(set) var playerState: PlayerState = .small
    private(set) var isOnGround: Bool = false
    private(set) var facingRight: Bool = true
    private(set) var isInvulnerable: Bool = false

    // MARK: - Jump State
    private var isJumping: Bool = false
    private var jumpHoldTime: TimeInterval = 0
    private var canJump: Bool = true
    private var airJumpsRemaining: Int = 3  // Allow up to 3 air jumps
    private var coyoteTime: TimeInterval = 0
    private let coyoteTimeDuration: TimeInterval = 0.1
    private var currentJumpType: JumpType = .none

    // MARK: - Movement
    private let moveSpeed: CGFloat = 180
    private let airMoveSpeed: CGFloat = 140
    private let jumpForce: CGFloat = 520
    private let jumpHoldForce: CGFloat = 280
    private let maxJumpHoldTime: TimeInterval = 0.2

    // MARK: - Ground Detection
    private var groundContactCount: Int = 0

    // MARK: - Timers
    private var invulnerabilityTimer: TimeInterval = 0
    private var invincibilityTimer: TimeInterval = 0
    private var blinkTimer: TimeInterval = 0
    private var previousState: PlayerState = .small

    // MARK: - Textures & Animation
    private var idleTexture: SKTexture!
    private var jumpTexture: SKTexture!
    private var deadTexture: SKTexture!
    private var runFrames: [SKTexture] = []
    private var isRunAnimating: Bool = false

    // MARK: - Initialization

    init() {
        let size = CGSize(width: 28, height: 32)
        super.init(texture: nil, color: .clear, size: size)

        name = "player"
        zPosition = 10

        loadTextures()
        texture = idleTexture
        setupPhysics()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPhysics() {
        // Slightly smaller physics body for better feel
        let bodySize = CGSize(width: size.width - 4, height: size.height - 2)

        // Beveled bottom corners prevent catching on tile seams between adjacent ground blocks
        let halfW = bodySize.width / 2
        let halfH = bodySize.height / 2
        let bevel: CGFloat = 4
        let path = CGMutablePath()
        path.addLines(between: [
            CGPoint(x: -halfW, y: halfH),
            CGPoint(x: halfW, y: halfH),
            CGPoint(x: halfW, y: -halfH + bevel),
            CGPoint(x: halfW - bevel, y: -halfH),
            CGPoint(x: -halfW + bevel, y: -halfH),
            CGPoint(x: -halfW, y: -halfH + bevel),
        ])
        path.closeSubpath()
        let body = SKPhysicsBody(polygonFrom: path)

        body.categoryBitMask = PhysicsCategory.player
        body.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.block
        body.contactTestBitMask = PhysicsCategory.ground | PhysicsCategory.block | PhysicsCategory.enemy | PhysicsCategory.item | PhysicsCategory.coin | PhysicsCategory.flagpole | PhysicsCategory.deathZone

        body.allowsRotation = false
        body.friction = 0.1
        body.restitution = 0
        body.linearDamping = 0
        body.mass = 0.1

        physicsBody = body

        if GameConstants.Debug.showCollisionOverlays {
            let overlay = SKSpriteNode(color: SKColor(red: 1, green: 0, blue: 0, alpha: 0.5), size: bodySize)
            overlay.position = .zero
            overlay.zPosition = 0.1
            overlay.name = "collisionDebug"
            addChild(overlay)
        }
    }

    // MARK: - Textures

    private func loadTextures() {
        idleTexture = SKTexture(imageNamed: "player_idle")
        jumpTexture = SKTexture(imageNamed: "player_jump")
        deadTexture = SKTexture(imageNamed: "player_dead")

        // Split 3-frame horizontal sprite sheet into individual frames
        let runSheet = SKTexture(imageNamed: "player_run")
        let frameWidth: CGFloat = 1.0 / 3.0
        for i in 0..<3 {
            let rect = CGRect(x: CGFloat(i) * frameWidth, y: 0, width: frameWidth, height: 1.0)
            runFrames.append(SKTexture(rect: rect, in: runSheet))
        }

        // Nearest-neighbor filtering for crisp pixel art
        for tex in [idleTexture!, jumpTexture!, deadTexture!] + runFrames {
            tex.filteringMode = .nearest
        }
    }

    private func updateAnimation(moveDirection: CGFloat) {
        if playerState == .dead {
            texture = deadTexture
            removeAction(forKey: "runAnimation")
            isRunAnimating = false
            return
        }

        if !isOnGround {
            texture = jumpTexture
            removeAction(forKey: "runAnimation")
            isRunAnimating = false
            return
        }

        if abs(moveDirection) > 0 || abs(physicsBody?.velocity.dx ?? 0) > 20 {
            if !isRunAnimating {
                isRunAnimating = true
                let animate = SKAction.animate(with: runFrames, timePerFrame: 0.1)
                run(SKAction.repeatForever(animate), withKey: "runAnimation")
            }
        } else {
            texture = idleTexture
            removeAction(forKey: "runAnimation")
            isRunAnimating = false
        }
    }

    // MARK: - Update

    func update(deltaTime: TimeInterval, moveDirection: CGFloat) {
        guard playerState != .dead else { return }

        updateGroundState(deltaTime: deltaTime)
        updateMovement(direction: moveDirection)
        updateJump(deltaTime: deltaTime)
        updateTimers(deltaTime: deltaTime)
        updateFacing(direction: moveDirection)
        updateAnimation(moveDirection: moveDirection)
    }

    private func updateGroundState(deltaTime: TimeInterval) {
        // Use velocity to help determine ground state
        guard let velocity = physicsBody?.velocity else { return }

        // Consider grounded if we have ground contacts OR very low vertical velocity while contacts exist
        let wasOnGround = isOnGround
        isOnGround = groundContactCount > 0 && velocity.dy <= 1

        if wasOnGround && !isOnGround {
            // Just left ground - start coyote time
            coyoteTime = coyoteTimeDuration
        }

        if coyoteTime > 0 {
            coyoteTime -= deltaTime
        }
    }

    private func updateMovement(direction: CGFloat) {
        guard let body = physicsBody else { return }

        let speed = isOnGround ? moveSpeed : airMoveSpeed

        if direction != 0 {
            body.velocity.dx = direction * speed
        } else {
            // Quick stop on ground, gradual in air
            if isOnGround {
                body.velocity.dx *= 0.8
                if abs(body.velocity.dx) < 10 {
                    body.velocity.dx = 0
                }
            } else {
                body.velocity.dx *= 0.95
            }
        }
    }

    private func updateJump(deltaTime: TimeInterval) {
        guard let body = physicsBody else { return }

        // Tap-based jumping: no hold bonus needed
        // Both low and high jumps have fixed heights determined by initial force

        // Reset jump state when landing
        if isOnGround && body.velocity.dy <= 0 {
            if isJumping {
                print("[JUMP] landed - resetting jump state")
            }
            isJumping = false
            canJump = true
            airJumpsRemaining = 3  // Reset air jumps on landing
            currentJumpType = .none
        }
    }

    private func updateTimers(deltaTime: TimeInterval) {
        // Invulnerability (after damage)
        if invulnerabilityTimer > 0 {
            invulnerabilityTimer -= deltaTime
            blinkTimer -= deltaTime
            if blinkTimer <= 0 {
                isHidden.toggle()
                blinkTimer = 0.08
            }
            if invulnerabilityTimer <= 0 {
                isHidden = false
                isInvulnerable = false
            }
        }

        // Star power invincibility
        if invincibilityTimer > 0 {
            invincibilityTimer -= deltaTime

            // Blink warning when about to expire
            if invincibilityTimer < 2.0 {
                blinkTimer -= deltaTime
                if blinkTimer <= 0 {
                    alpha = alpha > 0.8 ? 0.5 : 1.0
                    blinkTimer = 0.1
                }
            } else {
                // Rainbow effect could go here
                alpha = 1.0
            }

            if invincibilityTimer <= 0 {
                alpha = 1.0
                playerState = previousState
            }
        }
    }

    private func updateFacing(direction: CGFloat) {
        if direction > 0 {
            facingRight = true
            xScale = abs(xScale)
        } else if direction < 0 {
            facingRight = false
            xScale = -abs(xScale)
        }
    }

    // MARK: - Input Actions

    /// Called on tap - handles both ground jump and air jumps (up to 3)
    func tryJump() {
        print("[JUMP] tryJump called - isOnGround=\(isOnGround) airJumpsRemaining=\(airJumpsRemaining) canJump=\(canJump) coyoteTime=\(coyoteTime)")
        guard playerState != .dead else {
            print("[JUMP]   -> REJECTED: player dead")
            return
        }

        if isOnGround || coyoteTime > 0 {
            // Ground jump - low jump
            print("[JUMP]   -> GROUND JUMP (low)")
            isJumping = true
            canJump = false
            airJumpsRemaining = 3  // Reset air jumps when jumping from ground
            coyoteTime = 0
            currentJumpType = .low
            physicsBody?.velocity.dy = GameConstants.lowJumpForce
        } else if airJumpsRemaining > 0 {
            // Air jump - high jump
            print("[JUMP]   -> AIR JUMP (high) - \(airJumpsRemaining) remaining")
            airJumpsRemaining -= 1
            currentJumpType = .high
            physicsBody?.velocity.dy = GameConstants.highJumpForce
        } else {
            print("[JUMP]   -> REJECTED: not on ground and no air jumps remaining")
        }
    }

    func startLowJump() {
        tryJump()
    }

    func startHighJump() {
        tryJump()
    }

    func shoot() -> Bool {
        guard playerState == .fire else { return false }

        let fireballX = facingRight ? position.x + size.width / 2 + 8 : position.x - size.width / 2 - 8
        let fireballPos = CGPoint(x: fireballX, y: position.y)
        let direction: CGFloat = facingRight ? 1 : -1

        playerDelegate?.playerDidShootFireball(self, at: fireballPos, direction: direction)
        return true
    }

    // MARK: - Ground Contact

    func contactWithGround() {
        groundContactCount += 1
    }

    func endContactWithGround() {
        groundContactCount = max(0, groundContactCount - 1)
    }

    // MARK: - Power-ups

    func collectMushroom() {
        guard playerState == .small else { return }
        grow()
        playerDelegate?.playerDidCollectPowerUp(self, type: .mushroom)
    }

    func collectFireFlower() {
        if playerState == .small {
            grow()
        }
        playerState = .fire
        playerDelegate?.playerDidCollectPowerUp(self, type: .fireFlower)
    }

    func collectStar() {
        previousState = playerState
        playerState = .invincible
        invincibilityTimer = 10.0
        blinkTimer = 0.1
        playerDelegate?.playerDidCollectPowerUp(self, type: .star)
    }

    private func grow() {
        playerState = .big
        let newSize = CGSize(width: 28, height: 56)

        // Move up so we don't clip into ground
        position.y += (newSize.height - size.height) / 2

        size = newSize

        // Update physics body
        physicsBody = nil
        setupPhysics()
    }

    private func shrink() {
        playerState = .small
        let newSize = CGSize(width: 28, height: 32)
        size = newSize

        physicsBody = nil
        setupPhysics()

        // Temporary invulnerability
        isInvulnerable = true
        invulnerabilityTimer = 2.0
        blinkTimer = 0.08
    }

    // MARK: - Damage

    func takeDamage() {
        guard !isInvulnerable && playerState != .invincible && playerState != .dead else { return }

        switch playerState {
        case .fire:
            playerState = .big
            isInvulnerable = true
            invulnerabilityTimer = 2.0
            blinkTimer = 0.08

        case .big:
            shrink()

        case .small:
            die()

        default:
            break
        }
    }

    func die() {
        guard playerState != .dead else { return }
        playerState = .dead

        texture = deadTexture
        removeAction(forKey: "runAnimation")
        isRunAnimating = false

        // Stop all physics
        physicsBody?.velocity = .zero
        physicsBody?.collisionBitMask = 0
        physicsBody?.contactTestBitMask = 0
        physicsBody?.affectedByGravity = false

        // Death animation - pop up then fall
        let jumpUp = SKAction.moveBy(x: 0, y: 80, duration: 0.3)
        jumpUp.timingMode = .easeOut
        let fall = SKAction.moveBy(x: 0, y: -500, duration: 1.0)
        fall.timingMode = .easeIn

        run(SKAction.sequence([jumpUp, fall])) { [weak self] in
            self?.playerDelegate?.playerDidDie(self!)
        }
    }

    // MARK: - Bounce (for stomping enemies)

    func bounce() {
        physicsBody?.velocity.dy = 350
    }

    // MARK: - Reset

    func reset(at newPosition: CGPoint) {
        position = newPosition
        playerState = .small
        isOnGround = false
        facingRight = true
        xScale = 1
        isInvulnerable = false
        isJumping = false
        jumpHoldTime = 0
        canJump = true
        airJumpsRemaining = 3
        coyoteTime = 0
        currentJumpType = .none
        groundContactCount = 0
        invulnerabilityTimer = 0
        invincibilityTimer = 0
        isHidden = false
        alpha = 1.0

        size = CGSize(width: 28, height: 32)
        texture = idleTexture
        color = .clear
        removeAction(forKey: "runAnimation")
        isRunAnimating = false

        physicsBody?.velocity = .zero
        physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.block
        physicsBody?.contactTestBitMask = PhysicsCategory.ground | PhysicsCategory.block | PhysicsCategory.enemy | PhysicsCategory.item | PhysicsCategory.coin | PhysicsCategory.flagpole | PhysicsCategory.deathZone
        physicsBody?.affectedByGravity = true
    }
}
