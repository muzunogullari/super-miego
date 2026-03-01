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
    case dollarBurst(count: Int)  // Spawns multiple dollar bills
    case enemySurprise            // Spawns an enemy
}

protocol BlockNodeDelegate: AnyObject {
    func blockDidSpawnItem(_ block: BlockNode, item: ItemType, at position: CGPoint)
    func blockDidSpawnCoin(_ block: BlockNode, at position: CGPoint)
    func blockDidSpawnDollarBurst(_ block: BlockNode, count: Int, at position: CGPoint)
    func blockDidSpawnEnemy(_ block: BlockNode, at position: CGPoint)
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
        var tex: SKTexture? = nil

        switch type {
        case .ground:
            color = SKColor(red: 0.45, green: 0.3, blue: 0.2, alpha: 1.0)
        case .brick:
            let brickTex = SKTexture(imageNamed: "brick_crate")
            brickTex.filteringMode = .nearest
            tex = brickTex
            color = .clear
        case .question:
            color = SKColor(red: 0.9, green: 0.75, blue: 0.2, alpha: 1.0)
        case .empty:
            color = SKColor(red: 0.4, green: 0.35, blue: 0.3, alpha: 1.0)
        case .pipe:
            color = SKColor(red: 0.3, green: 0.5, blue: 0.3, alpha: 1.0)
        case .platform:
            color = SKColor(red: 0.5, green: 0.45, blue: 0.4, alpha: 1.0)
        }

        super.init(texture: tex, color: color, size: size)

        name = "block"

        if case .multiCoin(let count) = content {
            coinCount = count
        }

        // Add visual decoration for question blocks
        if type == .question {
            setupQuestionBlockVisual()
        }

        setupPhysics()
    }

    private func setupQuestionBlockVisual() {
        // Add a "?" label
        let questionMark = SKLabelNode(fontNamed: "Helvetica-Bold")
        questionMark.text = "?"
        questionMark.fontSize = 20
        questionMark.fontColor = SKColor(red: 0.6, green: 0.4, blue: 0.1, alpha: 1.0)
        questionMark.verticalAlignmentMode = .center
        questionMark.horizontalAlignmentMode = .center
        questionMark.position = .zero
        questionMark.zPosition = 0.1
        questionMark.name = "questionMark"
        addChild(questionMark)

        // Add a subtle bounce animation
        let bounce = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 2, duration: 0.4),
            SKAction.moveBy(x: 0, y: -2, duration: 0.4)
        ])
        questionMark.run(SKAction.repeatForever(bounce))

        // Add border/outline effect
        let border = SKShapeNode(rectOf: CGSize(width: size.width - 4, height: size.height - 4), cornerRadius: 3)
        border.strokeColor = SKColor(red: 0.7, green: 0.5, blue: 0.15, alpha: 1.0)
        border.lineWidth = 2
        border.fillColor = .clear
        border.position = .zero
        border.zPosition = 0.05
        addChild(border)
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
        body.contactTestBitMask = PhysicsCategory.player
        body.isDynamic = false
        body.friction = 0.2
        body.restitution = 0

        physicsBody = body

        if GameConstants.Debug.showCollisionOverlays {
            let overlay: SKSpriteNode
            if case .platform = blockType {
                overlay = SKSpriteNode(color: SKColor(red: 1, green: 0, blue: 0, alpha: 0.5),
                                      size: CGSize(width: size.width, height: 4))
                overlay.position = CGPoint(x: 0, y: size.height / 2 - 2)
            } else {
                overlay = SKSpriteNode(color: SKColor(red: 1, green: 0, blue: 0, alpha: 0.5), size: size)
                overlay.position = .zero
            }
            overlay.zPosition = 0.1
            overlay.name = "collisionDebug"
            addChild(overlay)
        }
    }

    // MARK: - Hit From Below

    func hitFromBelow(byBigPlayer: Bool) {
        print("[BLOCK] hitFromBelow called - type: \(blockType), content: \(content), isEmpty: \(isEmpty), isAnimating: \(isAnimating)")
        guard !isAnimating else {
            print("[BLOCK] Skipping - already animating")
            return
        }

        switch blockType {
        case .brick:
            print("[BLOCK] Brick block hit")
            if byBigPlayer && content == .nothing {
                breakBlock()
            } else {
                bumpBlock()
                releaseContent()
            }

        case .question:
            print("[BLOCK] Question block hit, isEmpty: \(isEmpty)")
            if !isEmpty {
                print("[BLOCK] Releasing content: \(content)")
                bumpBlock()
                releaseContent()
                becomeEmpty()
            }

        default:
            print("[BLOCK] Other block type, ignoring")
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
        print("[BLOCK] releaseContent called, content: \(content), delegate: \(blockDelegate != nil ? "SET" : "NIL")")

        switch content {
        case .coin:
            print("[BLOCK] Spawning coin at \(spawnPosition)")
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

        case .dollarBurst(let count):
            blockDelegate?.blockDidSpawnDollarBurst(self, count: count, at: spawnPosition)
            content = .nothing

        case .enemySurprise:
            blockDelegate?.blockDidSpawnEnemy(self, at: spawnPosition)
            content = .nothing

        case .nothing:
            break
        }
    }

    private func breakBlock() {
        isAnimating = true
        blockDelegate?.blockDidBreak(self)

        // Create particles
        let particleColor = blockType == .brick
            ? SKColor(red: 0.55, green: 0.35, blue: 0.2, alpha: 1.0)
            : color
        for i in 0..<4 {
            let particle = SKSpriteNode(color: particleColor, size: CGSize(width: 12, height: 12))
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

        // Remove question mark visual
        childNode(withName: "questionMark")?.removeFromParent()
        children.filter { $0 is SKShapeNode }.forEach { $0.removeFromParent() }
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
