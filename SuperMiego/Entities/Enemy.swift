import SpriteKit

enum EnemyType {
    case goomba
    case koopa
    case piranha
}

enum EnemyState {
    case walking
    case shell
    case shellMoving
    case dead
}

class Enemy: SKSpriteNode {
    let enemyType: EnemyType
    private(set) var state: EnemyState = .walking
    private var moveDirection: CGFloat = -1 // Start moving left

    private let walkSpeed: CGFloat = 50

    // MARK: - Textures & Animation
    private var walkFrames: [SKTexture] = []
    private var deadTexture: SKTexture?

    // MARK: - Initialization

    init(type: EnemyType) {
        self.enemyType = type

        let size: CGSize
        let color: SKColor

        switch type {
        case .goomba:
            size = CGSize(width: 28, height: 28)
            color = .clear
        case .koopa:
            size = CGSize(width: 28, height: 36)
            color = SKColor(red: 0.2, green: 0.5, blue: 0.2, alpha: 1.0)
        case .piranha:
            size = CGSize(width: 28, height: 40)
            color = SKColor(red: 0.7, green: 0.2, blue: 0.2, alpha: 1.0)
        }

        super.init(texture: nil, color: color, size: size)

        name = "enemy"
        zPosition = 5

        if type == .goomba {
            loadGoombaTextures()
        }
        setupPhysics()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func loadGoombaTextures() {
        let walk1 = SKTexture(imageNamed: "goomba_walk1")
        let walk2 = SKTexture(imageNamed: "goomba_walk2")
        deadTexture = SKTexture(imageNamed: "goomba_dead")

        for tex in [walk1, walk2, deadTexture!] {
            tex.filteringMode = .nearest
        }

        walkFrames = [walk1, walk2]
        texture = walk1

        let waddle = SKAction.animate(with: walkFrames, timePerFrame: 0.25)
        run(SKAction.repeatForever(waddle), withKey: "waddleAnimation")
    }

    private func setupPhysics() {
        let bodySize = CGSize(width: size.width - 4, height: size.height - 2)
        let body = SKPhysicsBody(rectangleOf: bodySize)

        body.categoryBitMask = PhysicsCategory.enemy
        body.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.block
        body.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.fireball

        body.allowsRotation = false
        body.friction = 0
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

    // MARK: - Update

    func update(deltaTime: TimeInterval) {
        guard state == .walking || state == .shellMoving else { return }

        let speed: CGFloat
        switch state {
        case .walking:
            speed = walkSpeed
        case .shellMoving:
            speed = 250
        default:
            return
        }

        physicsBody?.velocity.dx = moveDirection * speed
    }

    // MARK: - Collision Response

    func hitWall() {
        moveDirection *= -1
        xScale = moveDirection > 0 ? -1 : 1
    }

    // MARK: - Damage

    func stomp() {
        switch enemyType {
        case .goomba:
            state = .dead
            physicsBody?.velocity = .zero
            physicsBody?.categoryBitMask = 0
            physicsBody?.collisionBitMask = 0
            physicsBody?.contactTestBitMask = 0

            removeAction(forKey: "waddleAnimation")
            if let dead = deadTexture {
                texture = dead
            }

            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.5),
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.removeFromParent()
            ]))

        case .koopa:
            if state == .walking {
                // Turn into shell
                state = .shell
                size = CGSize(width: 28, height: 24)
                color = SKColor(red: 0.2, green: 0.4, blue: 0.2, alpha: 1.0)
                physicsBody?.velocity = .zero
            } else if state == .shell {
                // Kick shell - direction based on player position (assume right for now)
                kickShell(direction: -moveDirection)
            } else if state == .shellMoving {
                // Stop shell
                state = .shell
                physicsBody?.velocity = .zero
            }

        case .piranha:
            // Can't stomp piranha
            break
        }
    }

    func kickShell(direction: CGFloat) {
        guard enemyType == .koopa else { return }

        state = .shellMoving
        moveDirection = direction

        // Shell can hurt other enemies
        physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.enemy
    }

    func hitByFireball() {
        state = .dead
        removeAction(forKey: "waddleAnimation")

        physicsBody?.collisionBitMask = 0
        physicsBody?.contactTestBitMask = 0
        physicsBody?.affectedByGravity = false
        physicsBody?.velocity = CGVector(dx: 0, dy: 200)

        // Flip and fall
        run(SKAction.sequence([
            SKAction.group([
                SKAction.scaleY(to: -1, duration: 0),
                SKAction.moveBy(x: 0, y: 100, duration: 0.3),
            ]),
            SKAction.moveBy(x: 0, y: -400, duration: 0.8),
            SKAction.removeFromParent()
        ]))
    }

    func hitByInvinciblePlayer() {
        hitByFireball() // Same animation
    }

    func hitByShell() {
        hitByFireball() // Same animation
    }

    // MARK: - Query

    var isDead: Bool {
        return state == .dead
    }

    var canDamagePlayer: Bool {
        switch state {
        case .dead, .shell:
            return false
        default:
            return true
        }
    }
}
