import SpriteKit

class HUD: SKNode {
    // Labels
    private var scoreLabel: SKLabelNode!
    private var coinLabel: SKLabelNode!
    private var livesLabel: SKLabelNode!
    private var timeLabel: SKLabelNode!
    private var worldLabel: SKLabelNode!

    // Icons
    private var coinIcon: SKSpriteNode!

    // Pause button
    private var pauseButton: SKSpriteNode!

    private let fontSize: CGFloat = 14
    private let padding: CGFloat = 16

    var onPauseTapped: (() -> Void)?

    override init() {
        super.init()
        setupHUD()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupHUD() {
        zPosition = 100

        // Score section (top left)
        let scoreTitle = createLabel(text: "SCORE", size: fontSize - 2)
        scoreTitle.position = CGPoint(x: -350, y: 160)
        addChild(scoreTitle)

        scoreLabel = createLabel(text: "000000", size: fontSize)
        scoreLabel.position = CGPoint(x: -350, y: 145)
        addChild(scoreLabel)

        // Coins section
        coinIcon = SKSpriteNode(color: .yellow, size: CGSize(width: 12, height: 12))
        coinIcon.position = CGPoint(x: -220, y: 152)
        addChild(coinIcon)

        coinLabel = createLabel(text: "x00", size: fontSize)
        coinLabel.horizontalAlignmentMode = .left
        coinLabel.position = CGPoint(x: -208, y: 145)
        addChild(coinLabel)

        // World section (center)
        let worldTitle = createLabel(text: "WORLD", size: fontSize - 2)
        worldTitle.position = CGPoint(x: -50, y: 160)
        addChild(worldTitle)

        worldLabel = createLabel(text: "1-1", size: fontSize)
        worldLabel.position = CGPoint(x: -50, y: 145)
        addChild(worldLabel)

        // Time section
        let timeTitle = createLabel(text: "TIME", size: fontSize - 2)
        timeTitle.position = CGPoint(x: 100, y: 160)
        addChild(timeTitle)

        timeLabel = createLabel(text: "300", size: fontSize)
        timeLabel.position = CGPoint(x: 100, y: 145)
        addChild(timeLabel)

        // Lives section (top right)
        let livesIcon = SKSpriteNode(color: SKColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0),
                                     size: CGSize(width: 12, height: 16))
        livesIcon.position = CGPoint(x: 220, y: 152)
        addChild(livesIcon)

        livesLabel = createLabel(text: "x3", size: fontSize)
        livesLabel.horizontalAlignmentMode = .left
        livesLabel.position = CGPoint(x: 232, y: 145)
        addChild(livesLabel)

        // Pause button (top right corner)
        pauseButton = SKSpriteNode(color: SKColor(white: 0.3, alpha: 0.8),
                                   size: CGSize(width: 40, height: 40))
        pauseButton.position = CGPoint(x: 380, y: 152)
        pauseButton.name = "pauseButton"
        addChild(pauseButton)

        // Pause icon (two bars)
        let bar1 = SKSpriteNode(color: .white, size: CGSize(width: 6, height: 20))
        bar1.position = CGPoint(x: -6, y: 0)
        pauseButton.addChild(bar1)

        let bar2 = SKSpriteNode(color: .white, size: CGSize(width: 6, height: 20))
        bar2.position = CGPoint(x: 6, y: 0)
        pauseButton.addChild(bar2)
    }

    private func createLabel(text: String, size: CGFloat) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.text = text
        label.fontSize = size
        label.fontColor = .white
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        return label
    }

    // MARK: - Update Methods

    func updateScore(_ score: Int) {
        scoreLabel.text = String(format: "%06d", score)
    }

    func updateCoins(_ coins: Int) {
        coinLabel.text = String(format: "x%02d", coins)

        // Animate coin icon
        let bounce = SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        coinIcon.run(bounce)
    }

    func updateLives(_ lives: Int) {
        livesLabel.text = "x\(lives)"
    }

    func updateTime(_ time: TimeInterval) {
        let seconds = max(0, Int(time))
        timeLabel.text = "\(seconds)"

        // Flash when low on time
        if seconds <= 30 {
            timeLabel.fontColor = seconds % 2 == 0 ? .red : .white
        } else {
            timeLabel.fontColor = .white
        }
    }

    func setWorld(_ world: String) {
        worldLabel.text = world
    }

    func updateLevel(_ level: Int) {
        worldLabel.text = "1-\(level)"
    }

    // MARK: - Touch Handling

    func handleTouch(at location: CGPoint) -> Bool {
        let locationInHUD = convert(location, from: parent!)

        if pauseButton.contains(locationInHUD) {
            onPauseTapped?()
            return true
        }

        return false
    }

    // MARK: - Animations

    func showPointsPopup(_ points: Int, at position: CGPoint) {
        let popup = SKLabelNode(fontNamed: "Menlo-Bold")
        popup.text = "+\(points)"
        popup.fontSize = 12
        popup.fontColor = .white
        popup.position = position
        popup.zPosition = 50
        parent?.addChild(popup)

        let moveUp = SKAction.moveBy(x: 0, y: 40, duration: 0.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)

        popup.run(SKAction.sequence([
            moveUp,
            fadeOut,
            SKAction.removeFromParent()
        ]))
    }

    func showExtraLifeAnimation() {
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.text = "1UP"
        label.fontSize = 20
        label.fontColor = SKColor(red: 0.3, green: 0.9, blue: 0.4, alpha: 1.0)
        label.position = CGPoint(x: 0, y: 0)
        label.zPosition = 150
        addChild(label)

        let scaleUp = SKAction.scale(to: 1.5, duration: 0.3)
        let wait = SKAction.wait(forDuration: 0.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)

        label.run(SKAction.sequence([scaleUp, wait, fadeOut, SKAction.removeFromParent()]))
    }
}
