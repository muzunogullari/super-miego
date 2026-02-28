import SpriteKit

struct LevelData {
    let width: Int
    let height: Int
    let tiles: [[Character]]
    let playerStart: CGPoint
    let flagpolePosition: CGPoint
}

class LevelLoader {
    private let tileSize = GameConstants.tileSize

    func loadLevel(from tiles: [[Character]]) -> LevelData {
        var playerStart = CGPoint(x: 100, y: 100)
        var flagpolePos = CGPoint.zero

        // Find player start and flagpole
        for (rowIndex, row) in tiles.enumerated() {
            for (colIndex, char) in row.enumerated() {
                let y = CGFloat(tiles.count - 1 - rowIndex) * tileSize + tileSize / 2
                let x = CGFloat(colIndex) * tileSize + tileSize / 2

                if char == "@" {
                    playerStart = CGPoint(x: x, y: y + tileSize)
                }
                if char == ">" {
                    flagpolePos = CGPoint(x: x, y: y)
                }
            }
        }

        return LevelData(
            width: tiles[0].count,
            height: tiles.count,
            tiles: tiles,
            playerStart: playerStart,
            flagpolePosition: flagpolePos
        )
    }

    func buildLevel(from data: LevelData, in parentNode: SKNode) -> (blocks: [BlockNode], enemies: [Enemy], items: [SKNode]) {
        var blocks: [BlockNode] = []
        var enemies: [Enemy] = []
        var items: [SKNode] = []

        let tiles = data.tiles

        for (rowIndex, row) in tiles.enumerated() {
            for (colIndex, char) in row.enumerated() {
                let y = CGFloat(tiles.count - 1 - rowIndex) * tileSize + tileSize / 2
                let x = CGFloat(colIndex) * tileSize + tileSize / 2
                let position = CGPoint(x: x, y: y)

                switch char {
                case "#", "G":
                    let block = BlockNode(type: .ground)
                    block.position = position
                    parentNode.addChild(block)
                    blocks.append(block)

                case "B":
                    let block = BlockNode(type: .brick)
                    block.position = position
                    parentNode.addChild(block)
                    blocks.append(block)

                case "?":
                    let block = BlockNode(type: .question, content: .coin)
                    block.position = position
                    parentNode.addChild(block)
                    blocks.append(block)

                case "M":
                    let block = BlockNode(type: .question, content: .mushroom)
                    block.position = position
                    parentNode.addChild(block)
                    blocks.append(block)

                case "F":
                    let block = BlockNode(type: .question, content: .fireFlower)
                    block.position = position
                    parentNode.addChild(block)
                    blocks.append(block)

                case "S":
                    let block = BlockNode(type: .question, content: .star)
                    block.position = position
                    parentNode.addChild(block)
                    blocks.append(block)

                case "1":
                    let block = BlockNode(type: .question, content: .oneUp)
                    block.position = position
                    parentNode.addChild(block)
                    blocks.append(block)

                case "g":
                    let enemy = Enemy(type: .goomba)
                    enemy.position = position
                    parentNode.addChild(enemy)
                    enemies.append(enemy)

                case "k":
                    let enemy = Enemy(type: .koopa)
                    enemy.position = position
                    parentNode.addChild(enemy)
                    enemies.append(enemy)

                case "W":
                    // Death zone
                    let deathZone = SKNode()
                    deathZone.name = "deathZone"
                    let body = SKPhysicsBody(rectangleOf: CGSize(width: tileSize, height: tileSize))
                    body.categoryBitMask = PhysicsCategory.deathZone
                    body.collisionBitMask = 0
                    body.contactTestBitMask = PhysicsCategory.player
                    body.isDynamic = false
                    deathZone.physicsBody = body
                    deathZone.position = position

                    if GameConstants.Debug.showCollisionOverlays {
                        let deathZoneOverlay = SKSpriteNode(
                            color: SKColor(red: 1, green: 0, blue: 0, alpha: 0.5),
                            size: CGSize(width: tileSize, height: tileSize)
                        )
                        deathZoneOverlay.position = .zero
                        deathZoneOverlay.zPosition = 0.1
                        deathZoneOverlay.name = "collisionDebug"
                        deathZone.addChild(deathZoneOverlay)
                    }

                    parentNode.addChild(deathZone)

                    // Visual water
                    let water = SKSpriteNode(
                        color: SKColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.8),
                        size: CGSize(width: tileSize, height: tileSize)
                    )
                    water.position = position
                    water.zPosition = -5
                    parentNode.addChild(water)

                case ">":
                    let pole = createFlagpole(at: position)
                    parentNode.addChild(pole)
                    items.append(pole)

                case "C":
                    let coin = createCoin(at: position)
                    parentNode.addChild(coin)
                    items.append(coin)

                case "=":
                    let platform = BlockNode(type: .platform)
                    platform.position = position
                    parentNode.addChild(platform)
                    blocks.append(platform)

                case "[":
                    // Pipe top - create pipe here
                    createPipe(at: position, tiles: tiles, rowIndex: rowIndex, colIndex: colIndex, in: parentNode)

                default:
                    break
                }
            }
        }

        return (blocks, enemies, items)
    }

    private func createPipe(at topPosition: CGPoint, tiles: [[Character]], rowIndex: Int, colIndex: Int, in parentNode: SKNode) {
        // Count pipe height by looking down
        var height = 1
        var checkRow = rowIndex + 1
        while checkRow < tiles.count && colIndex < tiles[checkRow].count {
            let char = tiles[checkRow][colIndex]
            if char == "P" || char == "|" {
                height += 1
                checkRow += 1
            } else {
                break
            }
        }

        let pipeWidth = tileSize * 2
        let pipeHeight = tileSize * CGFloat(height)

        // Pipe body
        let pipe = SKSpriteNode(
            color: SKColor(red: 0.2, green: 0.5, blue: 0.25, alpha: 1.0),
            size: CGSize(width: pipeWidth - 4, height: pipeHeight)
        )
        pipe.position = CGPoint(
            x: topPosition.x + tileSize / 2,
            y: topPosition.y - pipeHeight / 2 + tileSize / 2
        )
        pipe.zPosition = 1

        let pipeBody = SKPhysicsBody(rectangleOf: pipe.size)
        pipeBody.categoryBitMask = PhysicsCategory.ground
        pipeBody.collisionBitMask = PhysicsCategory.player | PhysicsCategory.enemy
        pipeBody.isDynamic = false
        pipe.physicsBody = pipeBody

        if GameConstants.Debug.showCollisionOverlays {
            let collisionDebug = SKSpriteNode(
                color: SKColor(red: 1, green: 0, blue: 0, alpha: 0.5),
                size: pipe.size
            )
            collisionDebug.position = .zero
            collisionDebug.zPosition = 100
            collisionDebug.name = "collisionDebug"
            pipe.addChild(collisionDebug)
        }

        parentNode.addChild(pipe)

        // Pipe top lip
        let lip = SKSpriteNode(
            color: SKColor(red: 0.25, green: 0.55, blue: 0.3, alpha: 1.0),
            size: CGSize(width: pipeWidth + 8, height: tileSize / 2)
        )
        lip.position = CGPoint(
            x: topPosition.x + tileSize / 2,
            y: topPosition.y + tileSize / 4
        )
        lip.zPosition = 2
        parentNode.addChild(lip)
    }

    private func createFlagpole(at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position
        container.name = "flagpole"

        let poleHeight: CGFloat = 160

        // Pole
        let pole = SKSpriteNode(
            color: SKColor(red: 0.35, green: 0.3, blue: 0.25, alpha: 1.0),
            size: CGSize(width: 6, height: poleHeight)
        )
        pole.anchorPoint = CGPoint(x: 0.5, y: 0)
        pole.position = CGPoint(x: 0, y: 0)
        container.addChild(pole)

        // Ball on top
        let ball = SKSpriteNode(color: SKColor.yellow, size: CGSize(width: 14, height: 14))
        ball.position = CGPoint(x: 0, y: poleHeight + 7)
        container.addChild(ball)

        // Flag
        let flag = SKSpriteNode(
            color: SKColor(red: 0.2, green: 0.6, blue: 0.3, alpha: 1.0),
            size: CGSize(width: 28, height: 20)
        )
        flag.anchorPoint = CGPoint(x: 0, y: 0.5)
        flag.position = CGPoint(x: 3, y: poleHeight - 15)
        container.addChild(flag)

        // Physics for detection
        let bodySize = CGSize(width: 20, height: poleHeight)
        let body = SKPhysicsBody(rectangleOf: bodySize, center: CGPoint(x: 0, y: poleHeight / 2))
        body.categoryBitMask = PhysicsCategory.flagpole
        body.collisionBitMask = 0
        body.contactTestBitMask = PhysicsCategory.player
        body.isDynamic = false
        container.physicsBody = body

        if GameConstants.Debug.showCollisionOverlays {
            let flagpoleOverlay = SKSpriteNode(
                color: SKColor(red: 1, green: 0, blue: 0, alpha: 0.5),
                size: bodySize
            )
            flagpoleOverlay.position = CGPoint(x: 0, y: poleHeight / 2)
            flagpoleOverlay.zPosition = 0.1
            flagpoleOverlay.name = "collisionDebug"
            container.addChild(flagpoleOverlay)
        }

        return container
    }

    private func createCoin(at position: CGPoint) -> SKSpriteNode {
        let coin = SKSpriteNode(color: SKColor.yellow, size: CGSize(width: 16, height: 16))
        coin.position = position
        coin.name = "coin"
        coin.zPosition = 5

        let body = SKPhysicsBody(rectangleOf: coin.size)
        body.categoryBitMask = PhysicsCategory.coin
        body.collisionBitMask = 0
        body.contactTestBitMask = PhysicsCategory.player
        body.isDynamic = false
        coin.physicsBody = body

        if GameConstants.Debug.showCollisionOverlays {
            let coinOverlay = SKSpriteNode(
                color: SKColor(red: 1, green: 0, blue: 0, alpha: 0.5),
                size: coin.size
            )
            coinOverlay.position = .zero
            coinOverlay.zPosition = 0.1
            coinOverlay.name = "collisionDebug"
            coin.addChild(coinOverlay)
        }

        // Spinning animation
        let spin = SKAction.repeatForever(SKAction.sequence([
            SKAction.scaleX(to: 0.3, duration: 0.15),
            SKAction.scaleX(to: 1.0, duration: 0.15)
        ]))
        coin.run(spin)

        return coin
    }
}
