import SpriteKit

enum ProjectileType {
    case snowflake  // Freezes player temporarily
    case fireball   // Kills player
}

class TurtleEnemy: SKSpriteNode {
    private var moveDirection: CGFloat = -1
    private let moveSpeed: CGFloat = 40
    private var shootTimer: TimeInterval = 0
    private let shootInterval: TimeInterval = 2.5
    private var projectileType: ProjectileType

    weak var gameScene: SKScene?
    var isDead: Bool = false

    init(projectileType: ProjectileType = .snowflake) {
        self.projectileType = projectileType

        // Green for snowflake shooter, red for fireball shooter
        let color = projectileType == .snowflake ?
            SKColor(red: 0.2, green: 0.6, blue: 0.3, alpha: 1.0) :
            SKColor(red: 0.7, green: 0.2, blue: 0.2, alpha: 1.0)

        let size = CGSize(width: 48, height: 48)  // 2x scale
        super.init(texture: nil, color: color, size: size)

        name = "turtleEnemy"
        zPosition = 5

        setupVisual()
        setupPhysics()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupVisual() {
        // Shell body (darker)
        let shell = SKSpriteNode(
            color: projectileType == .snowflake ?
                SKColor(red: 0.1, green: 0.4, blue: 0.2, alpha: 1.0) :
                SKColor(red: 0.5, green: 0.1, blue: 0.1, alpha: 1.0),
            size: CGSize(width: 40, height: 32)
        )
        shell.position = CGPoint(x: 0, y: -4)
        shell.zPosition = -0.1
        addChild(shell)

        // Head
        let head = SKSpriteNode(
            color: SKColor(red: 0.9, green: 0.8, blue: 0.6, alpha: 1.0),
            size: CGSize(width: 16, height: 16)
        )
        head.position = CGPoint(x: -16, y: 8)
        head.zPosition = 0.1
        addChild(head)

        // Eyes
        let eye = SKSpriteNode(color: .black, size: CGSize(width: 4, height: 4))
        eye.position = CGPoint(x: -20, y: 12)
        eye.zPosition = 0.2
        addChild(eye)

        // Icon indicator (snowflake or flame)
        let indicator = SKLabelNode(fontNamed: "Menlo-Bold")
        indicator.text = projectileType == .snowflake ? "❄" : "🔥"
        indicator.fontSize = 14
        indicator.position = CGPoint(x: 0, y: 24)
        indicator.zPosition = 0.2
        addChild(indicator)
    }

    private func setupPhysics() {
        let body = SKPhysicsBody(rectangleOf: CGSize(width: size.width - 8, height: size.height - 4))
        body.categoryBitMask = PhysicsCategory.enemy
        body.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.block
        body.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.fireball
        body.allowsRotation = false
        body.friction = 0.2
        body.restitution = 0
        body.mass = 0.3
        physicsBody = body
    }

    func update(deltaTime: TimeInterval) {
        guard !isDead else { return }

        // Check if fallen off map
        if position.y < -100 {
            print("[TURTLE] fell off map at x=\(position.x)")
            isDead = true
            removeFromParent()
            return
        }

        // Move
        physicsBody?.velocity.dx = moveDirection * moveSpeed

        // Shooting timer
        shootTimer += deltaTime
        if shootTimer >= shootInterval {
            shootTimer = 0
            print("[TURTLE] shooting \(projectileType) at position \(position)")
            shootProjectile()
        }
    }

    private func shootProjectile() {
        guard let scene = gameScene else { return }

        let projectile = Projectile(type: projectileType)

        // Throw from turtle's position
        let offsetX: CGFloat = moveDirection < 0 ? -30 : 30
        projectile.position = CGPoint(x: position.x + offsetX, y: position.y + 20)
        projectile.direction = moveDirection

        scene.addChild(projectile)
        projectile.launch()  // Give it arc velocity

        // Shoot animation - pause briefly
        let pause = SKAction.sequence([
            SKAction.scaleY(to: 0.8, duration: 0.1),
            SKAction.scaleY(to: 1.0, duration: 0.1)
        ])
        run(pause)
    }

    func reverseDirection() {
        moveDirection *= -1
        xScale = moveDirection > 0 ? -1 : 1
    }

    func hitWall() {
        reverseDirection()
    }

    func die() {
        guard !isDead else { return }
        print("[TURTLE] dying at position \(position)")
        isDead = true

        physicsBody?.velocity = .zero
        physicsBody?.collisionBitMask = 0
        physicsBody?.contactTestBitMask = 0

        // Death animation
        let flip = SKAction.scaleY(to: -1, duration: 0.1)
        let fall = SKAction.moveBy(x: 0, y: -200, duration: 0.5)
        let remove = SKAction.removeFromParent()

        run(SKAction.sequence([flip, fall, remove]))
    }

    func stomp() {
        // Turtle retreats into shell when stomped - doesn't die immediately
        die()  // For now, just die
    }
}

// MARK: - Projectile

class Projectile: SKSpriteNode {
    let projectileType: ProjectileType
    var direction: CGFloat = -1
    private var hasLanded: Bool = false
    private var lifetime: TimeInterval = 8.0
    private var landedTime: TimeInterval = 0

    init(type: ProjectileType) {
        self.projectileType = type

        let color: SKColor
        let size: CGSize

        switch type {
        case .snowflake:
            color = SKColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 1.0)
            size = CGSize(width: 20, height: 20)
        case .fireball:
            color = SKColor(red: 1.0, green: 0.4, blue: 0.1, alpha: 1.0)
            size = CGSize(width: 24, height: 24)
        }

        super.init(texture: nil, color: color, size: size)

        name = "projectile"
        zPosition = 6

        setupVisual()
        setupPhysics()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupVisual() {
        switch projectileType {
        case .snowflake:
            // Snowflake shape using label
            let snow = SKLabelNode(fontNamed: "Menlo")
            snow.text = "❄️"
            snow.fontSize = 18
            snow.verticalAlignmentMode = .center
            addChild(snow)

            // Spin animation
            let spin = SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 1.0))
            run(spin)

        case .fireball:
            // Fireball glow
            let glow = SKSpriteNode(color: SKColor.yellow, size: CGSize(width: 16, height: 16))
            glow.zPosition = -0.1
            addChild(glow)

            // Flicker animation
            let flicker = SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 1.2, duration: 0.1),
                SKAction.scale(to: 0.9, duration: 0.1)
            ]))
            run(flicker)
        }
    }

    private func setupPhysics() {
        let body = SKPhysicsBody(circleOfRadius: size.width / 2 - 2)
        body.categoryBitMask = PhysicsCategory.enemyProjectile
        body.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.block
        body.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.ground | PhysicsCategory.block
        body.isDynamic = true
        body.affectedByGravity = true  // Arc trajectory
        body.allowsRotation = false
        body.restitution = 0.2
        body.friction = 0.8
        body.mass = 0.05
        physicsBody = body
    }

    /// Called by turtle when shooting - gives initial throw velocity
    func launch() {
        let throwSpeed: CGFloat = 120
        let throwAngle: CGFloat = 0.4  // upward angle
        physicsBody?.velocity = CGVector(
            dx: direction * throwSpeed,
            dy: throwSpeed * throwAngle
        )
    }

    func update(deltaTime: TimeInterval) {
        guard !hasLanded else {
            // Ice sits on ground, eventually fades
            landedTime += deltaTime
            if landedTime > 5.0 {
                alpha = max(0, 1.0 - (landedTime - 5.0) / 2.0)
                if alpha <= 0 {
                    removeFromParent()
                }
            }
            return
        }

        // Lifetime (while in air)
        lifetime -= deltaTime
        if lifetime <= 0 {
            removeFromParent()
        }
    }

    /// Called when projectile hits ground/block
    func hitGround() {
        switch projectileType {
        case .snowflake:
            // Ice stops and stays on ground
            hasLanded = true
            physicsBody?.velocity = .zero
            physicsBody?.isDynamic = false
            physicsBody?.contactTestBitMask = PhysicsCategory.player  // Can still freeze player
            removeAction(forKey: "spin")
            // Stop spinning, just sit there
            run(SKAction.rotate(toAngle: 0, duration: 0.1))

        case .fireball:
            // Fireball explodes and dies
            let poof = SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 1.5, duration: 0.1),
                    SKAction.fadeOut(withDuration: 0.1)
                ]),
                SKAction.removeFromParent()
            ])
            run(poof)
        }
    }
}
