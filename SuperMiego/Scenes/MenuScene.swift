import SpriteKit

class MenuScene: SKScene {
    private var titleLabel: SKLabelNode!
    private var startButton: SKSpriteNode!
    private var backgroundLayer: SKNode!

    override func didMove(to view: SKView) {
        setupBackground()
        setupTitle()
        setupStartButton()
        setupDecorations()
    }

    private func setupBackground() {
        backgroundColor = SKColor(
            red: GameConstants.Colors.backgroundRed,
            green: GameConstants.Colors.backgroundGreen,
            blue: GameConstants.Colors.backgroundBlue,
            alpha: 1.0
        )

        backgroundLayer = SKNode()
        backgroundLayer.zPosition = -10
        addChild(backgroundLayer)

        // Misty forest silhouette
        for i in 0..<8 {
            let tree = SKSpriteNode(color: SKColor(red: 0.15, green: 0.25, blue: 0.2, alpha: 0.7),
                                   size: CGSize(width: 80, height: CGFloat.random(in: 150...280)))
            tree.anchorPoint = CGPoint(x: 0.5, y: 0)
            tree.position = CGPoint(x: CGFloat(i) * (size.width / 7) - 50,
                                   y: 0)
            backgroundLayer.addChild(tree)
        }

        // Ground
        let ground = SKSpriteNode(color: SKColor(red: 0.25, green: 0.35, blue: 0.25, alpha: 1.0),
                                 size: CGSize(width: size.width, height: 60))
        ground.anchorPoint = CGPoint(x: 0, y: 0)
        ground.position = .zero
        backgroundLayer.addChild(ground)
    }

    private func setupTitle() {
        // Game title
        titleLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        titleLabel.text = "SUPER MIEGO"
        titleLabel.fontSize = 48
        titleLabel.fontColor = SKColor(red: 0.3, green: 0.8, blue: 0.4, alpha: 1.0)
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.65)
        titleLabel.zPosition = 10
        addChild(titleLabel)

        // Subtitle
        let subtitle = SKLabelNode(fontNamed: "Menlo")
        subtitle.text = "Pacific Northwest Adventure"
        subtitle.fontSize = 16
        subtitle.fontColor = SKColor(white: 0.9, alpha: 0.8)
        subtitle.position = CGPoint(x: size.width / 2, y: size.height * 0.55)
        subtitle.zPosition = 10
        addChild(subtitle)

        // Gentle pulsing animation on title
        let scaleUp = SKAction.scale(to: 1.05, duration: 1.5)
        let scaleDown = SKAction.scale(to: 1.0, duration: 1.5)
        titleLabel.run(SKAction.repeatForever(SKAction.sequence([scaleUp, scaleDown])))
    }

    private func setupStartButton() {
        startButton = SKSpriteNode(color: SKColor(red: 0.2, green: 0.6, blue: 0.3, alpha: 1.0),
                                   size: CGSize(width: 200, height: 50))
        startButton.position = CGPoint(x: size.width / 2, y: size.height * 0.35)
        startButton.zPosition = 10
        startButton.name = "startButton"
        addChild(startButton)

        let buttonLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        buttonLabel.text = "START GAME"
        buttonLabel.fontSize = 20
        buttonLabel.fontColor = .white
        buttonLabel.verticalAlignmentMode = .center
        startButton.addChild(buttonLabel)

        // Button hover effect
        let brighten = SKAction.colorize(with: SKColor(red: 0.3, green: 0.7, blue: 0.4, alpha: 1.0),
                                         colorBlendFactor: 1.0, duration: 0.5)
        let dim = SKAction.colorize(with: SKColor(red: 0.2, green: 0.6, blue: 0.3, alpha: 1.0),
                                    colorBlendFactor: 1.0, duration: 0.5)
        startButton.run(SKAction.repeatForever(SKAction.sequence([brighten, dim])))
    }

    private func setupDecorations() {
        // Floating mist particles
        if let mist = SKEmitterNode(fileNamed: "Mist") {
            mist.position = CGPoint(x: size.width / 2, y: size.height * 0.2)
            mist.zPosition = 5
            addChild(mist)
        }

        // Rain effect (subtle)
        createRainEffect()

        // Instructions
        let instructions = SKLabelNode(fontNamed: "Menlo")
        instructions.text = "Left side: Move | Right side: Jump"
        instructions.fontSize = 12
        instructions.fontColor = SKColor(white: 0.7, alpha: 0.8)
        instructions.position = CGPoint(x: size.width / 2, y: size.height * 0.15)
        instructions.zPosition = 10
        addChild(instructions)
    }

    private func createRainEffect() {
        // Simple rain using lines
        let rainLayer = SKNode()
        rainLayer.zPosition = 3
        addChild(rainLayer)

        for _ in 0..<30 {
            let raindrop = SKSpriteNode(color: SKColor(white: 0.8, alpha: 0.3),
                                       size: CGSize(width: 1, height: 15))
            raindrop.position = CGPoint(x: CGFloat.random(in: 0...size.width),
                                       y: CGFloat.random(in: 0...size.height))

            let fall = SKAction.moveBy(x: -20, y: -size.height - 20, duration: Double.random(in: 0.5...1.0))
            let reset = SKAction.run {
                raindrop.position = CGPoint(x: CGFloat.random(in: 0...self.size.width),
                                           y: self.size.height + 20)
            }

            raindrop.run(SKAction.repeatForever(SKAction.sequence([fall, reset])))
            rainLayer.addChild(raindrop)
        }
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if startButton.contains(location) {
            startGame()
        }
    }

    private func startGame() {
        // Button press animation
        startButton.run(SKAction.sequence([
            SKAction.scale(to: 0.9, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1),
            SKAction.run { [weak self] in
                self?.transitionToGame()
            }
        ]))
    }

    private func transitionToGame() {
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = .aspectFill

        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(gameScene, transition: transition)
    }
}
