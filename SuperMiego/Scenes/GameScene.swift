import SpriteKit

class GameScene: SKScene {
    // MARK: - Nodes
    private var player: Player!
    private var cameraNode: SKCameraNode!
    private var hud: HUD!
    private var worldNode: SKNode!

    // MARK: - Systems
    private var cameraController: CameraController!
    private var collisionHandler: CollisionHandler!
    private var gameState: GameStateManager!

    // MARK: - Level Data
    private var blocks: [BlockNode] = []
    private var enemies: [Enemy] = []
    private var items: [SKNode] = []
    private var fireballs: [Fireball] = []

    private var levelData: LevelData!
    private var levelBounds: CGRect = .zero

    // MARK: - Input State
    private var moveDirection: CGFloat = 0
    private var isJumpPressed: Bool = false
    private var jumpPressTime: TimeInterval = 0
    private var movementTouchID: Int?
    private var jumpTouchID: Int?

    // MARK: - State
    private var lastUpdateTime: TimeInterval = 0
    private var isGamePaused: Bool = false

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        // Set anchor point to bottom-left for easier coordinate math
        anchorPoint = CGPoint(x: 0, y: 0)

        setupScene()
        setupWorldNode()
        setupCamera()
        setupSystems()
        loadLevel()
        setupPlayer()
        setupHUD()
    }

    private func setupScene() {
        backgroundColor = SKColor(red: 0.4, green: 0.6, blue: 0.7, alpha: 1.0)

        // Let SpriteKit handle gravity - don't divide by framerate
        physicsWorld.gravity = CGVector(dx: 0, dy: -30)
    }

    private func setupWorldNode() {
        worldNode = SKNode()
        worldNode.name = "world"
        addChild(worldNode)

        // Add background to world
        createBackground()
    }

    private func createBackground() {
        // Sky layers
        for i in 0..<3 {
            let skyStripe = SKSpriteNode(
                color: SKColor(red: 0.4 + CGFloat(i) * 0.05,
                              green: 0.55 + CGFloat(i) * 0.05,
                              blue: 0.65 + CGFloat(i) * 0.02,
                              alpha: 1.0),
                size: CGSize(width: 5000, height: size.height / 3)
            )
            skyStripe.anchorPoint = CGPoint(x: 0, y: 0)
            skyStripe.position = CGPoint(x: 0, y: size.height * CGFloat(2 - i) / 3)
            skyStripe.zPosition = -100
            worldNode.addChild(skyStripe)
        }

        // Distant trees
        for i in 0..<50 {
            let treeHeight = CGFloat.random(in: 80...180)
            let tree = SKSpriteNode(
                color: SKColor(red: 0.15, green: 0.25, blue: 0.2, alpha: 0.5),
                size: CGSize(width: 50, height: treeHeight)
            )
            tree.anchorPoint = CGPoint(x: 0.5, y: 0)
            tree.position = CGPoint(x: CGFloat(i) * 100, y: 60)
            tree.zPosition = -50
            worldNode.addChild(tree)
        }
    }

    private func setupSystems() {
        cameraController = CameraController()

        gameState = GameStateManager()
        gameState.delegate = self

        collisionHandler = CollisionHandler()
        collisionHandler.delegate = self
        collisionHandler.gameState = gameState
        physicsWorld.contactDelegate = collisionHandler
    }

    private func setupPlayer() {
        player = Player()
        player.zPosition = 10
        player.playerDelegate = self
        player.position = levelData.playerStart
        worldNode.addChild(player)

        collisionHandler.player = player

        // Configure camera after player is positioned
        cameraController.configure(
            camera: cameraNode,
            player: player,
            levelBounds: levelBounds,
            viewportSize: size
        )
    }

    private func setupCamera() {
        cameraNode = SKCameraNode()
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(cameraNode)
        camera = cameraNode
    }

    private func loadLevel() {
        levelData = Level1.getData()

        let tileSize = GameConstants.tileSize
        levelBounds = CGRect(
            x: 0,
            y: 0,
            width: CGFloat(levelData.width) * tileSize,
            height: CGFloat(levelData.height) * tileSize
        )

        let loader = LevelLoader()
        let levelElements = loader.buildLevel(from: levelData, in: worldNode)

        blocks = levelElements.blocks
        enemies = levelElements.enemies
        items = levelElements.items

        for block in blocks {
            block.blockDelegate = self
        }
    }

    private func setupHUD() {
        hud = HUD()
        hud.zPosition = 100
        cameraNode.addChild(hud)

        hud.updateScore(gameState.score)
        hud.updateCoins(gameState.coins)
        hud.updateLives(gameState.lives)
        hud.updateTime(gameState.timeRemaining)
        hud.setWorld("1-1")

        hud.onPauseTapped = { [weak self] in
            self?.togglePause()
        }

        setupControlOverlays()
    }

    private func setupControlOverlays() {
        let overlayAlpha: CGFloat = 0.15
        let movementWidth = size.width / 3.0
        let jumpWidth = size.width * 2.0 / 3.0
        let overlayHeight = size.height * 0.25

        // Container for control overlays (attached to camera)
        let controlsNode = SKNode()
        controlsNode.name = "controlOverlays"
        controlsNode.zPosition = 90
        cameraNode.addChild(controlsNode)

        // Movement zone (left third of screen)
        let movementBg = SKSpriteNode(
            color: SKColor(white: 1.0, alpha: overlayAlpha),
            size: CGSize(width: movementWidth, height: overlayHeight)
        )
        movementBg.anchorPoint = CGPoint(x: 0, y: 0)
        movementBg.position = CGPoint(x: -size.width / 2, y: -size.height / 2)
        controlsNode.addChild(movementBg)

        // Left arrow
        let leftArrow = createArrowLabel(text: "◀", size: 28)
        leftArrow.position = CGPoint(
            x: -size.width / 2 + movementWidth * 0.25,
            y: -size.height / 2 + overlayHeight / 2
        )
        controlsNode.addChild(leftArrow)

        // Right arrow
        let rightArrow = createArrowLabel(text: "▶", size: 28)
        rightArrow.position = CGPoint(
            x: -size.width / 2 + movementWidth * 0.75,
            y: -size.height / 2 + overlayHeight / 2
        )
        controlsNode.addChild(rightArrow)

        // Divider line in movement zone
        let divider = SKSpriteNode(
            color: SKColor(white: 1.0, alpha: 0.3),
            size: CGSize(width: 2, height: overlayHeight - 20)
        )
        divider.position = CGPoint(
            x: -size.width / 2 + movementWidth / 2,
            y: -size.height / 2 + overlayHeight / 2
        )
        controlsNode.addChild(divider)

        // Movement label
        let moveLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        moveLabel.text = "MOVE"
        moveLabel.fontSize = 10
        moveLabel.fontColor = SKColor(white: 1.0, alpha: 0.6)
        moveLabel.position = CGPoint(
            x: -size.width / 2 + movementWidth / 2,
            y: -size.height / 2 + 8
        )
        controlsNode.addChild(moveLabel)

        // Jump zone (right two-thirds)
        let jumpBg = SKSpriteNode(
            color: SKColor(red: 0.3, green: 0.5, blue: 0.8, alpha: overlayAlpha),
            size: CGSize(width: jumpWidth, height: overlayHeight)
        )
        jumpBg.anchorPoint = CGPoint(x: 0, y: 0)
        jumpBg.position = CGPoint(x: -size.width / 2 + movementWidth, y: -size.height / 2)
        controlsNode.addChild(jumpBg)

        // Jump arrow
        let jumpArrow = createArrowLabel(text: "▲", size: 32)
        jumpArrow.position = CGPoint(
            x: -size.width / 2 + movementWidth + jumpWidth / 2,
            y: -size.height / 2 + overlayHeight / 2
        )
        controlsNode.addChild(jumpArrow)

        // Jump label
        let jumpLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        jumpLabel.text = "JUMP (hold for higher)"
        jumpLabel.fontSize = 10
        jumpLabel.fontColor = SKColor(white: 1.0, alpha: 0.6)
        jumpLabel.position = CGPoint(
            x: -size.width / 2 + movementWidth + jumpWidth / 2,
            y: -size.height / 2 + 8
        )
        controlsNode.addChild(jumpLabel)

        // Vertical separator line between zones
        let separator = SKSpriteNode(
            color: SKColor(white: 1.0, alpha: 0.4),
            size: CGSize(width: 2, height: overlayHeight)
        )
        separator.anchorPoint = CGPoint(x: 0.5, y: 0)
        separator.position = CGPoint(x: -size.width / 2 + movementWidth, y: -size.height / 2)
        controlsNode.addChild(separator)

        // Fade out overlays after 5 seconds
        let fadeAction = SKAction.sequence([
            SKAction.wait(forDuration: 5.0),
            SKAction.fadeAlpha(to: 0.05, duration: 1.0)
        ])
        controlsNode.run(fadeAction)
    }

    private func createArrowLabel(text: String, size: CGFloat) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.fontSize = size
        label.fontColor = SKColor(white: 1.0, alpha: 0.7)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        return label
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        guard !isGamePaused else { return }

        let deltaTime: TimeInterval
        if lastUpdateTime == 0 {
            deltaTime = 1.0 / 60.0
        } else {
            deltaTime = min(currentTime - lastUpdateTime, 1.0 / 30.0)
        }
        lastUpdateTime = currentTime

        // Update game timer
        gameState.updateTime(deltaTime)

        // Update player with current input
        player.update(deltaTime: deltaTime, moveDirection: moveDirection, isJumpHeld: isJumpPressed)

        // Update enemies
        for enemy in enemies where !enemy.isDead {
            enemy.update(deltaTime: deltaTime)
        }

        // Update items
        for item in items {
            (item as? ItemNode)?.update(deltaTime: deltaTime)
        }

        // Update fireballs
        updateFireballs(deltaTime: deltaTime)

        // Update camera
        cameraController.update(deltaTime: deltaTime)

        // Check for fall death
        if player.position.y < -100 && player.playerState != .dead {
            player.die()
        }
    }

    private func updateFireballs(deltaTime: TimeInterval) {
        fireballs.removeAll { fireball in
            if fireball.parent == nil {
                return true
            }
            fireball.update(deltaTime: deltaTime)

            // Remove if off-screen
            let cameraLeft = cameraNode.position.x - size.width / 2
            if fireball.position.x < cameraLeft - 50 || fireball.position.y < -50 {
                fireball.removeFromParent()
                return true
            }
            return false
        }
    }

    // MARK: - Touch Handling (Simplified)

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let view = view else { return }

        for touch in touches {
            let viewLocation = touch.location(in: view)
            let touchID = touch.hash

            // Check HUD first (in camera space)
            let cameraLocation = touch.location(in: cameraNode)
            if hud.handleTouch(at: cameraLocation) {
                continue
            }

            // Left third = movement, Right two-thirds = jump
            let movementWidth = view.bounds.width / 3.0

            if viewLocation.x < movementWidth {
                // Movement zone
                movementTouchID = touchID
                updateMovementFromTouch(viewLocation, in: view)
            } else {
                // Jump zone
                jumpTouchID = touchID
                isJumpPressed = true
                jumpPressTime = lastUpdateTime
                player.startJump()
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let view = view else { return }

        for touch in touches {
            let viewLocation = touch.location(in: view)
            let touchID = touch.hash

            if touchID == movementTouchID {
                updateMovementFromTouch(viewLocation, in: view)
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchID = touch.hash

            if touchID == movementTouchID {
                movementTouchID = nil
                moveDirection = 0
            }
            if touchID == jumpTouchID {
                jumpTouchID = nil
                isJumpPressed = false
                player.endJump()
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    private func updateMovementFromTouch(_ location: CGPoint, in view: SKView) {
        let movementWidth = view.bounds.width / 3.0
        let midPoint = movementWidth / 2.0

        // Note: UIKit Y is inverted, but we only care about X here
        if location.x < midPoint {
            moveDirection = -1
        } else {
            moveDirection = 1
        }
    }

    // MARK: - Pause

    private func togglePause() {
        isGamePaused.toggle()
        self.isPaused = isGamePaused

        if isGamePaused {
            showPauseOverlay()
        } else {
            hidePauseOverlay()
        }
    }

    private func showPauseOverlay() {
        let overlay = SKSpriteNode(color: SKColor(white: 0, alpha: 0.7), size: size)
        overlay.zPosition = 150
        overlay.name = "pauseOverlay"
        cameraNode.addChild(overlay)

        let pauseLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        pauseLabel.text = "PAUSED"
        pauseLabel.fontSize = 32
        pauseLabel.fontColor = .white
        pauseLabel.position = CGPoint(x: 0, y: 20)
        overlay.addChild(pauseLabel)

        let tapLabel = SKLabelNode(fontNamed: "Menlo")
        tapLabel.text = "Tap pause to continue"
        tapLabel.fontSize = 16
        tapLabel.fontColor = .gray
        tapLabel.position = CGPoint(x: 0, y: -30)
        overlay.addChild(tapLabel)
    }

    private func hidePauseOverlay() {
        cameraNode.childNode(withName: "pauseOverlay")?.removeFromParent()
    }

    // MARK: - Death & Respawn

    private func handlePlayerDeath() {
        gameState.loseLife()

        if gameState.isGameOver {
            showGameOver()
        } else {
            run(SKAction.sequence([
                SKAction.wait(forDuration: 2.0),
                SKAction.run { [weak self] in
                    self?.respawnPlayer()
                }
            ]))
        }
    }

    private func respawnPlayer() {
        gameState.resetForNewLife()
        player.reset(at: levelData.playerStart)

        // Reset input
        moveDirection = 0
        isJumpPressed = false
        movementTouchID = nil
        jumpTouchID = nil

        cameraController.configure(
            camera: cameraNode,
            player: player,
            levelBounds: levelBounds,
            viewportSize: size
        )
    }

    private func showGameOver() {
        isGamePaused = true
        self.isPaused = true

        let overlay = SKSpriteNode(color: SKColor(white: 0, alpha: 0.8), size: size)
        overlay.zPosition = 150
        overlay.name = "gameOverOverlay"
        cameraNode.addChild(overlay)

        let gameOverLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.fontSize = 36
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: 0, y: 20)
        overlay.addChild(gameOverLabel)

        let tapLabel = SKLabelNode(fontNamed: "Menlo")
        tapLabel.text = "Tap to restart"
        tapLabel.fontSize = 16
        tapLabel.fontColor = .gray
        tapLabel.position = CGPoint(x: 0, y: -30)
        overlay.addChild(tapLabel)
    }

    // MARK: - Level Complete

    private func handleLevelComplete() {
        isGamePaused = true
        gameState.completeLevel()

        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.run { [weak self] in
                self?.showLevelComplete()
            }
        ]))
    }

    private func showLevelComplete() {
        let overlay = SKSpriteNode(color: SKColor(white: 0, alpha: 0.7), size: size)
        overlay.zPosition = 150
        cameraNode.addChild(overlay)

        let completeLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        completeLabel.text = "LEVEL COMPLETE!"
        completeLabel.fontSize = 28
        completeLabel.fontColor = .yellow
        completeLabel.position = CGPoint(x: 0, y: 30)
        overlay.addChild(completeLabel)

        let scoreLabel = SKLabelNode(fontNamed: "Menlo")
        scoreLabel.text = "Score: \(gameState.score)"
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: 0, y: -20)
        overlay.addChild(scoreLabel)
    }
}

// MARK: - PlayerDelegate

extension GameScene: PlayerDelegate {
    func playerDidDie(_ player: Player) {
        handlePlayerDeath()
    }

    func playerDidShootFireball(_ player: Player, at position: CGPoint, direction: CGFloat) {
        guard fireballs.count < GameConstants.maxFireballs else { return }

        let fireball = Fireball(direction: direction)
        fireball.position = position
        fireball.zPosition = 5
        worldNode.addChild(fireball)
        fireballs.append(fireball)
    }

    func playerDidCollectPowerUp(_ player: Player, type: ItemType) {
        // Sound effects would go here
    }
}

// MARK: - BlockNodeDelegate

extension GameScene: BlockNodeDelegate {
    func blockDidSpawnItem(_ block: BlockNode, item: ItemType, at position: CGPoint) {
        let itemNode = ItemNode(type: item)
        itemNode.spawnFromBlock(at: position)
        itemNode.zPosition = 5
        worldNode.addChild(itemNode)
        items.append(itemNode)
    }

    func blockDidSpawnCoin(_ block: BlockNode, at position: CGPoint) {
        gameState.collectCoin()

        let coin = SKSpriteNode(color: .yellow, size: GameConstants.coinSize)
        coin.position = position
        coin.zPosition = 15
        worldNode.addChild(coin)

        let moveUp = SKAction.moveBy(x: 0, y: 50, duration: 0.3)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        coin.run(SKAction.sequence([moveUp, fadeOut, SKAction.removeFromParent()]))
    }

    func blockDidBreak(_ block: BlockNode) {
        // Sound effects would go here
    }
}

// MARK: - GameStateDelegate

extension GameScene: GameStateDelegate {
    func gameStateDidUpdateScore(_ score: Int) {
        hud?.updateScore(score)
    }

    func gameStateDidUpdateCoins(_ coins: Int) {
        hud?.updateCoins(coins)
    }

    func gameStateDidUpdateLives(_ lives: Int) {
        hud?.updateLives(lives)
    }

    func gameStateDidUpdateTime(_ time: TimeInterval) {
        hud?.updateTime(time)
    }

    func gameStateDidGetExtraLife() {
        hud?.showExtraLifeAnimation()
    }

    func gameStateDidTriggerGameOver() {
        // Handled in handlePlayerDeath
    }
}

// MARK: - CollisionHandlerDelegate

extension GameScene: CollisionHandlerDelegate {
    func collisionHandlerDidCollectCoin() {}

    func collisionHandlerDidCollectPowerUp(type: ItemType) {}

    func collisionHandlerDidStompEnemy(points: Int, at position: CGPoint) {
        hud?.showPointsPopup(points, at: convert(position, from: worldNode))
    }

    func collisionHandlerDidKillEnemy(at position: CGPoint) {}

    func collisionHandlerPlayerDidDie() {
        handlePlayerDeath()
    }

    func collisionHandlerDidReachFlagpole() {
        handleLevelComplete()
    }
}
