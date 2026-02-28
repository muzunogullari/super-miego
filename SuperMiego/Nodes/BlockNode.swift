import SpriteKit

enum BlockType {
    case ground
    case brick
    case question
    case empty
    case pipe
    case platform
}

enum BlockContent: Equatable {
    case nothing
    case coin
    case mushroom
    case fireFlower
    case star
    case oneUp
    case multiCoin(count: Int)
}

protocol BlockNodeDelegate: AnyObject {
    func blockDidSpawnItem(_ block: BlockNode, item: ItemType, at position: CGPoint)
    func blockDidSpawnCoin(_ block: BlockNode, at position: CGPoint)
    func blockDidBreak(_ block: BlockNode)
}

class BlockNode: SKSpriteNode {
    weak var blockDelegate: BlockNodeDelegate?

    let blockType: BlockType
    private(set) var content: BlockContent
    private(set) var isEmpty: Bool = false

    private var coinCount: Int = 0
    private var isAnimating: Bool = false

    // MARK: - Initialization

    init(type: BlockType, content: BlockContent = .nothing) {
        self.blockType = type
        self.content = content

        let size = CGSize(width: GameConstants.tileSize, height: GameConstants.tileSize)
        let color: SKColor

        switch type {
        case .ground:
            color = SKColor(red: 0.45, green: 0.3, blue: 0.2, alpha: 1.0) // Brown
        case .brick:
            color = SKColor(red: 0.55, green: 0.35, blue: 0.25, alpha: 1.0) // Lighter brown
        case .question:
            color = SKColor(red: 0.9, green: 0.75, blue: 0.2, alpha: 1.0) // Gold
        case .empty:
            color = SKColor(red: 0.4, green: 0.35, blue: 0.3, alpha: 1.0) // Dark brown
        case .pipe:
            color = SKColor(red: 0.3, green: 0.5, blue: 0.3, alpha: 1.0) // Dark green
        case .platform:
            color = SKColor(red: 0.5, green: 0.45, blue: 0.4, alpha: 1.0) // Gray-brown
        }

        super.init(texture: nil, color: color, size: size)

        name = "block"

        if case .multiCoin(let count) = content {
            coinCount = count
        }

        setupPhysics()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPhysics() {
        let body: SKPhysicsBody

        switch blockType {
        case .platform:
            // One-way platform - thin collision at top
            body = SKPhysicsBody(rectangleOf: CGSize(width: size.width, height: 4),
                               center: CGPoint(x: 0, y: size.height / 2 - 2))
            body.categoryBitMask = PhysicsCategory.platform
        default:
            body = SKPhysicsBody(rectangleOf: size)
            body.categoryBitMask = blockType == .ground ? PhysicsCategory.ground : PhysicsCategory.block
        }

        body.collisionBitMask = PhysicsCategory.player | PhysicsCategory.enemy | PhysicsCategory.item
        body.contactTestBitMask = 0
        body.isDynamic = false
        body.friction = 0.2
        body.restitution = 0

        physicsBody = body
    }

    // MARK: - Hit From Below

    func hitFromBelow(byBigPlayer: Bool) {
        guard !isAnimating else { return }

        switch blockType {
        case .brick:
            if byBigPlayer && content == .nothing {
                breakBlock()
            } else {
                bumpBlock()
                releaseContent()
            }

        case .question:
            if !isEmpty {
                bumpBlock()
                releaseContent()
                becomeEmpty()
            }

        default:
            break
        }
    }

    private func bumpBlock() {
        guard !isAnimating else { return }
        isAnimating = true

        let bumpUp = SKAction.moveBy(x: 0, y: GameConstants.blockBumpHeight,
                                     duration: GameConstants.blockBumpDuration / 2)
        let bumpDown = SKAction.moveBy(x: 0, y: -GameConstants.blockBumpHeight,
                                       duration: GameConstants.blockBumpDuration / 2)
        bumpUp.timingMode = .easeOut
        bumpDown.timingMode = .easeIn

        run(SKAction.sequence([bumpUp, bumpDown])) { [weak self] in
            self?.isAnimating = false
        }
    }

    private func releaseContent() {
        let spawnPosition = CGPoint(x: position.x, y: position.y + size.height)

        switch content {
        case .coin:
            blockDelegate?.blockDidSpawnCoin(self, at: spawnPosition)
            content = .nothing

        case .multiCoin(_):
            blockDelegate?.blockDidSpawnCoin(self, at: spawnPosition)
            coinCount -= 1
            if coinCount <= 0 {
                content = .nothing
                becomeEmpty()
            } else {
                content = .multiCoin(count: coinCount)
            }

        case .mushroom:
            blockDelegate?.blockDidSpawnItem(self, item: .mushroom, at: spawnPosition)
            content = .nothing

        case .fireFlower:
            blockDelegate?.blockDidSpawnItem(self, item: .fireFlower, at: spawnPosition)
            content = .nothing

        case .star:
            blockDelegate?.blockDidSpawnItem(self, item: .star, at: spawnPosition)
            content = .nothing

        case .oneUp:
            blockDelegate?.blockDidSpawnItem(self, item: .oneUp, at: spawnPosition)
            content = .nothing

        case .nothing:
            break
        }
    }

    private func breakBlock() {
        isAnimating = true
        blockDelegate?.blockDidBreak(self)

        // Create particles
        for i in 0..<4 {
            let particle = SKSpriteNode(color: color, size: CGSize(width: 12, height: 12))
            particle.position = position
            parent?.addChild(particle)

            let angle = CGFloat.pi / 4 + CGFloat(i) * CGFloat.pi / 2
            let velocity = CGVector(dx: cos(angle) * 150, dy: sin(angle) * 200 + 150)

            let move = SKAction.customAction(withDuration: 1.0) { node, time in
                let t = CGFloat(time)
                node.position.x += velocity.dx * 0.016
                node.position.y += (velocity.dy - 500 * t) * 0.016
                node.zRotation += 0.2
            }

            particle.run(SKAction.sequence([move, SKAction.removeFromParent()]))
        }

        removeFromParent()
    }

    private func becomeEmpty() {
        isEmpty = true
        color = SKColor(red: 0.4, green: 0.35, blue: 0.3, alpha: 1.0)
    }
}

// MARK: - Pipe Block

class PipeNode: SKSpriteNode {
    let pipeHeight: Int
    var isWarp: Bool = false
    var warpDestination: CGPoint?

    init(height: Int) {
        self.pipeHeight = height

        let tileSize = GameConstants.tileSize
        let size = CGSize(width: tileSize * 2, height: tileSize * CGFloat(height))
        let color = SKColor(red: 0.3, green: 0.55, blue: 0.3, alpha: 1.0) // Green

        super.init(texture: nil, color: color, size: size)

        name = "pipe"
        anchorPoint = CGPoint(x: 0.5, y: 0)

        setupPhysics()
        addTopSection()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPhysics() {
        let body = SKPhysicsBody(rectangleOf: size, center: CGPoint(x: 0, y: size.height / 2))
        body.categoryBitMask = PhysicsCategory.ground
        body.collisionBitMask = PhysicsCategory.player | PhysicsCategory.enemy
        body.isDynamic = false
        physicsBody = body
    }

    private func addTopSection() {
        let topSize = CGSize(width: size.width + 8, height: GameConstants.tileSize / 2)
        let top = SKSpriteNode(color: SKColor(red: 0.35, green: 0.6, blue: 0.35, alpha: 1.0),
                               size: topSize)
        top.position = CGPoint(x: 0, y: size.height - topSize.height / 2)
        addChild(top)
    }
}
