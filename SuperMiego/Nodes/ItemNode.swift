import SpriteKit

enum ItemType {
    case coin
    case mushroom
    case fireFlower
    case star
    case oneUp
}

class ItemNode: SKSpriteNode {
    let itemType: ItemType
    private var velocity: CGVector = .zero
    private var moveDirection: CGFloat = 1
    private var isEmerging: Bool = true
    private var emergeStartY: CGFloat = 0
    private var emergeTargetY: CGFloat = 0

    // MARK: - Initialization

    init(type: ItemType) {
        self.itemType = type

        let size: CGSize
        let color: SKColor

        switch type {
        case .coin:
            size = GameConstants.coinSize
            color = SKColor.yellow
        case .mushroom:
            size = GameConstants.mushroomSize
            color = SKColor(red: 0.9, green: 0.4, blue: 0.3, alpha: 1.0) // Red-orange
        case .fireFlower:
            size = GameConstants.fireFlowerSize
            color = SKColor.orange
        case .star:
            size = GameConstants.starSize
            color = SKColor.yellow
        case .oneUp:
            size = GameConstants.mushroomSize
            color = SKColor(red: 0.3, green: 0.8, blue: 0.4, alpha: 1.0) // Green
        }

        super.init(texture: nil, color: color, size: size)

        name = "item"
        setupPhysics()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPhysics() {
        let body = SKPhysicsBody(rectangleOf: size)
        body.categoryBitMask = PhysicsCategory.item
        body.collisionBitMask = PhysicsCategory.itemCollision
        body.contactTestBitMask = PhysicsCategory.itemContact
        body.allowsRotation = false
        body.friction = 0
        body.restitution = 0

        switch itemType {
        case .coin:
            // Coins don't have physics - they just animate and disappear
            body.isDynamic = false
            body.collisionBitMask = 0
        case .star:
            body.restitution = 1.0 // Bouncy
        default:
            break
        }

        physicsBody = body
    }

    // MARK: - Spawn

    func spawnFromBlock(at blockPosition: CGPoint) {
        position = blockPosition
        emergeStartY = blockPosition.y
        emergeTargetY = blockPosition.y + GameConstants.tileSize
        isEmerging = true

        // Disable physics during emerge
        physicsBody?.isDynamic = false

        if itemType == .coin {
            // Coin just pops up and disappears
            animateCoinCollect()
        }
    }

    private func animateCoinCollect() {
        let moveUp = SKAction.moveBy(x: 0, y: 50, duration: 0.3)
        moveUp.timingMode = .easeOut
        let moveDown = SKAction.moveBy(x: 0, y: -20, duration: 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: 0.1)

        run(SKAction.sequence([moveUp, moveDown, fadeOut, SKAction.removeFromParent()]))
    }

    // MARK: - Update

    func update(deltaTime: TimeInterval) {
        if isEmerging {
            updateEmerge(deltaTime: deltaTime)
            return
        }

        switch itemType {
        case .mushroom, .oneUp:
            updateMushroom(deltaTime: deltaTime)
        case .star:
            updateStar(deltaTime: deltaTime)
        default:
            break
        }
    }

    private func updateEmerge(deltaTime: TimeInterval) {
        guard itemType != .coin else { return }

        let emergeSpeed: CGFloat = 50
        position.y += emergeSpeed * CGFloat(deltaTime)

        if position.y >= emergeTargetY {
            position.y = emergeTargetY
            isEmerging = false
            physicsBody?.isDynamic = true

            // Start moving
            switch itemType {
            case .mushroom, .oneUp:
                velocity.dx = moveDirection * GameConstants.mushroomMoveSpeed
            case .star:
                velocity.dx = moveDirection * GameConstants.starBounceSpeed
                velocity.dy = GameConstants.starBounceImpulse
            default:
                break
            }
        }
    }

    private func updateMushroom(deltaTime: TimeInterval) {
        physicsBody?.velocity = CGVector(dx: velocity.dx, dy: physicsBody?.velocity.dy ?? 0)
    }

    private func updateStar(deltaTime: TimeInterval) {
        // Star bounces - handled by physics restitution
        physicsBody?.velocity = CGVector(dx: velocity.dx, dy: physicsBody?.velocity.dy ?? 0)
    }

    // MARK: - Collision

    func hitWall() {
        moveDirection *= -1
        velocity.dx = moveDirection * (itemType == .star ? GameConstants.starBounceSpeed : GameConstants.mushroomMoveSpeed)
    }

    func collected() {
        removeFromParent()
    }
}

// MARK: - Fireball

class Fireball: SKSpriteNode {
    private var velocity: CGVector
    private let direction: CGFloat

    init(direction: CGFloat) {
        self.direction = direction
        self.velocity = CGVector(dx: direction * GameConstants.fireballSpeed, dy: 0)

        let size = GameConstants.fireballSize
        let color = SKColor.orange

        super.init(texture: nil, color: color, size: size)

        name = "fireball"
        setupPhysics()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPhysics() {
        let body = SKPhysicsBody(circleOfRadius: size.width / 2)
        body.categoryBitMask = PhysicsCategory.fireball
        body.collisionBitMask = PhysicsCategory.fireballCollision
        body.contactTestBitMask = PhysicsCategory.fireballContact
        body.allowsRotation = true
        body.friction = 0
        body.restitution = 1.0
        body.linearDamping = 0
        body.angularDamping = 0

        physicsBody = body
    }

    func update(deltaTime: TimeInterval) {
        physicsBody?.velocity = CGVector(dx: velocity.dx, dy: physicsBody?.velocity.dy ?? 0)
        zRotation += CGFloat(deltaTime) * 15 * direction
    }

    func bounced() {
        // Bounce effect already handled by restitution
        // Add bounce impulse if needed
        if let dy = physicsBody?.velocity.dy, dy < 50 {
            physicsBody?.applyImpulse(CGVector(dx: 0, dy: GameConstants.fireballBounceImpulse))
        }
    }

    func hitEnemy() {
        // Explosion effect
        let expand = SKAction.scale(to: 2.0, duration: 0.1)
        let fade = SKAction.fadeOut(withDuration: 0.1)
        run(SKAction.sequence([SKAction.group([expand, fade]), SKAction.removeFromParent()]))
    }

    func hitWall() {
        hitEnemy() // Same effect
    }
}
