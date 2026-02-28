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

    // MARK: - Input State (Drag + Tap System)
    private struct TrackedTouch {
        let id: Int
        let startLocation: CGPoint
        let startTime: TimeInterval
        var currentLocation: CGPoint
        var isDrag: Bool
    }

    private var activeTouches: [Int: TrackedTouch] = [:]
    private var dragTouchID: Int? = nil
    private var moveDirection: CGFloat = 0

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

        if GameConstants.Debug.showCollisionOverlays {
            addCollisionOverlaysToAllNodes(self)
        }
    }

    private func setupScene() {
        backgroundColor = SKColor(red: 0.4, green: 0.6, blue: 0.7, alpha: 1.0)

        // Let SpriteKit handle gravity - don't divide by framerate
        physicsWorld.gravity = CGVector(dx: 0, dy: -15)
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
        let treeAlpha: CGFloat = GameConstants.Debug.showCollisionOverlays ? 0.1 : 0.5
        for i in 0..<50 {
            let treeHeight = CGFloat.random(in: 80...180)
            let tree = SKSpriteNode(
                color: SKColor(red: 0.15, green: 0.25, blue: 0.2, alpha: treeAlpha),
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
        let overlayAlpha: CGFloat = 0.2

        // Container for control overlays (attached to camera)
        let controlsNode = SKNode()
        controlsNode.name = "controlOverlays"
        controlsNode.zPosition = 90
        cameraNode.addChild(controlsNode)

        // Instruction bar at bottom
        let instructionBg = SKSpriteNode(
            color: SKColor(white: 0, alpha: overlayAlpha),
            size: CGSize(width: size.width * 0.85, height: 50)
        )
        instructionBg.position = CGPoint(x: 0, y: -size.height / 2 + 35)
        controlsNode.addChild(instructionBg)

        // Control instructions
        let instructionLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        instructionLabel.text = "DRAG to move  |  TAP to jump  |  DOUBLE-TAP for high jump"
        instructionLabel.fontSize = 11
        instructionLabel.fontColor = SKColor(white: 1.0, alpha: 0.85)
        instructionLabel.position = CGPoint(x: 0, y: -size.height / 2 + 35)
        instructionLabel.verticalAlignmentMode = .center
        controlsNode.addChild(instructionLabel)

        // Fade out after 5 seconds
        let fadeAction = SKAction.sequence([
            SKAction.wait(forDuration: 5.0),
            SKAction.fadeAlpha(to: 0.0, duration: 1.0),
            SKAction.removeFromParent()
        ])
        controlsNode.run(fadeAction)
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
        player.update(deltaTime: deltaTime, moveDirection: moveDirection)

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

    // MARK: - Touch Handling (Drag + Tap System)

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let view = view else { return }
        let currentTime = CACurrentMediaTime()

        for touch in touches {
            let viewLocation = touch.location(in: view)
            let touchID = touch.hash

            // Check HUD first (in camera space)
            let cameraLocation = touch.location(in: cameraNode)
            if hud.handleTouch(at: cameraLocation) {
                continue
            }

            // Check pause menu if paused
            if isGamePaused {
                // Check for game over overlay tap
                if cameraNode.childNode(withName: "gameOverOverlay") != nil {
                    restartLevel()
                    continue
                }

                if let pauseMenu = cameraNode.childNode(withName: "pauseMenuOverlay") as? PauseMenuOverlay {
                    if pauseMenu.handleTouchBegan(at: cameraLocation) {
                        continue
                    }
                }
                continue  // Ignore other touches when paused
            }

            // Create tracked touch
            let trackedTouch = TrackedTouch(
                id: touchID,
                startLocation: viewLocation,
                startTime: currentTime,
                currentLocation: viewLocation,
                isDrag: false
            )
            activeTouches[touchID] = trackedTouch
            print("[TAP] touchBegan id=\(touchID) at \(viewLocation)")
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let view = view else { return }

        for touch in touches {
            let viewLocation = touch.location(in: view)
            let touchID = touch.hash

            // Handle pause menu touch move
            if isGamePaused {
                let cameraLocation = touch.location(in: cameraNode)
                if let pauseMenu = cameraNode.childNode(withName: "pauseMenuOverlay") as? PauseMenuOverlay {
                    pauseMenu.handleTouchMoved(at: cameraLocation)
                }
                continue
            }

            guard var trackedTouch = activeTouches[touchID] else { continue }

            trackedTouch.currentLocation = viewLocation

            // Check if moved beyond dead zone (becomes a drag)
            if !trackedTouch.isDrag {
                let dx = viewLocation.x - trackedTouch.startLocation.x
                let dy = viewLocation.y - trackedTouch.startLocation.y
                let distance = hypot(dx, dy)

                if distance > GameConstants.dragDeadZone {
                    trackedTouch.isDrag = true

                    // Claim as drag touch if none exists
                    if dragTouchID == nil {
                        dragTouchID = touchID
                    }
                }
            }

            activeTouches[touchID] = trackedTouch

            // Update movement if this is the drag touch
            if dragTouchID == touchID {
                updateMovementFromDrag(trackedTouch)
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let currentTime = CACurrentMediaTime()

        for touch in touches {
            let touchID = touch.hash

            // Handle pause menu touch end
            if isGamePaused {
                let cameraLocation = touch.location(in: cameraNode)
                if let pauseMenu = cameraNode.childNode(withName: "pauseMenuOverlay") as? PauseMenuOverlay {
                    pauseMenu.handleTouchEnded(at: cameraLocation)
                }
                continue
            }

            guard let trackedTouch = activeTouches[touchID] else {
                print("[TAP] touchEnded id=\(touchID) - NOT IN activeTouches!")
                continue
            }

            // Was this the drag touch?
            if dragTouchID == touchID {
                print("[TAP] touchEnded id=\(touchID) - was drag touch, clearing")
                dragTouchID = nil
                moveDirection = 0
            }

            // Check if this was a tap (short duration, minimal movement)
            let duration = currentTime - trackedTouch.startTime
            let movement = hypot(
                trackedTouch.currentLocation.x - trackedTouch.startLocation.x,
                trackedTouch.currentLocation.y - trackedTouch.startLocation.y
            )

            let isTap = duration < GameConstants.tapMaxDuration && movement < GameConstants.tapMaxMovement
            print("[TAP] touchEnded id=\(touchID) duration=\(String(format: "%.3f", duration))s movement=\(String(format: "%.1f", movement))px isDrag=\(trackedTouch.isDrag) isTap=\(isTap)")
            print("[TAP]   thresholds: maxDuration=\(GameConstants.tapMaxDuration)s maxMovement=\(GameConstants.tapMaxMovement)px")

            if isTap {
                // Tap detected - try to jump
                print("[TAP]   -> TAP -> attempting jump")
                player.tryJump()
            } else {
                print("[TAP]   -> NOT A TAP (duration or movement exceeded)")
            }

            // Clean up
            activeTouches.removeValue(forKey: touchID)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchID = touch.hash

            if isGamePaused {
                if let pauseMenu = cameraNode.childNode(withName: "pauseMenuOverlay") as? PauseMenuOverlay {
                    pauseMenu.handleTouchCancelled()
                }
            }

            if dragTouchID == touchID {
                dragTouchID = nil
                moveDirection = 0
            }

            activeTouches.removeValue(forKey: touchID)
        }
    }

    private func updateMovementFromDrag(_ touch: TrackedTouch) {
        let dx = touch.currentLocation.x - touch.startLocation.x

        if dx > GameConstants.dragDeadZone {
            moveDirection = 1  // Move right
        } else if dx < -GameConstants.dragDeadZone {
            moveDirection = -1  // Move left
        } else {
            moveDirection = 0  // In dead zone = stop
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
        let pauseMenu = PauseMenuOverlay(viewSize: size)
        pauseMenu.delegate = self
        cameraNode.addChild(pauseMenu)
        pauseMenu.animateIn()
    }

    private func hidePauseOverlay() {
        if let pauseMenu = cameraNode.childNode(withName: "pauseMenuOverlay") as? PauseMenuOverlay {
            pauseMenu.animateOut { [weak pauseMenu] in
                pauseMenu?.removeFromParent()
            }
        }
    }

    private func restartLevel() {
        // Unpause
        isGamePaused = false
        self.isPaused = false

        // Remove pause overlay and game over overlay
        cameraNode.childNode(withName: "pauseMenuOverlay")?.removeFromParent()
        cameraNode.childNode(withName: "gameOverOverlay")?.removeFromParent()

        // Reset game state
        gameState.reset()

        // Reset input
        moveDirection = 0
        activeTouches.removeAll()
        dragTouchID = nil

        // Remove existing enemies
        for enemy in enemies {
            enemy.removeFromParent()
        }
        enemies.removeAll()

        // Remove existing items
        for item in items {
            item.removeFromParent()
        }
        items.removeAll()

        // Remove fireballs
        for fireball in fireballs {
            fireball.removeFromParent()
        }
        fireballs.removeAll()

        // Remove blocks
        for block in blocks {
            block.removeFromParent()
        }
        blocks.removeAll()

        // Reload level
        loadLevel()

        // Reset player
        player.reset(at: levelData.playerStart)

        // Reconfigure camera
        cameraController.configure(
            camera: cameraNode,
            player: player,
            levelBounds: levelBounds,
            viewportSize: size
        )

        // Update HUD
        hud.updateScore(gameState.score)
        hud.updateCoins(gameState.coins)
        hud.updateLives(gameState.lives)
        hud.updateTime(gameState.timeRemaining)
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
        activeTouches.removeAll()
        dragTouchID = nil

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

// MARK: - PauseMenuDelegate

extension GameScene: PauseMenuDelegate {
    func pauseMenuDidSelectResume() {
        togglePause()
    }

    func pauseMenuDidSelectRestart() {
        restartLevel()
    }
}

// MARK: - Debug Collision Overlays

extension GameScene {
    /// Recursively walks the node tree and adds a red overlay to every node
    /// that has a physics body, unless it already has one.
    private func addCollisionOverlaysToAllNodes(_ root: SKNode) {
        for child in root.children {
            if let body = child.physicsBody,
               child.childNode(withName: "collisionDebug") == nil {
                let overlaySize: CGSize
                let overlayPos: CGPoint

                if let sprite = child as? SKSpriteNode {
                    overlaySize = sprite.size
                    overlayPos = .zero
                } else if let bodyFrame = body.node?.frame {
                    overlaySize = bodyFrame.size
                    overlayPos = .zero
                } else {
                    overlaySize = CGSize(width: 32, height: 32)
                    overlayPos = .zero
                }

                let categoryStr = String(body.categoryBitMask, radix: 2)
                let collisionStr = String(body.collisionBitMask, radix: 2)
                print("[CollisionDebug] Found untagged physics body: node=\(child.name ?? "<unnamed>") cat=\(categoryStr) col=\(collisionStr) pos=\(child.position) size=\(overlaySize)")

                let overlay = SKSpriteNode(
                    color: SKColor(red: 1, green: 0, blue: 0, alpha: 0.5),
                    size: overlaySize
                )
                overlay.position = overlayPos
                overlay.zPosition = 100
                overlay.name = "collisionDebug"
                child.addChild(overlay)
            }

            addCollisionOverlaysToAllNodes(child)
        }
    }
}
