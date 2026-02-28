import SpriteKit

protocol PauseMenuDelegate: AnyObject {
    func pauseMenuDidSelectResume()
    func pauseMenuDidSelectRestart()
}

class PauseMenuOverlay: SKNode {
    weak var delegate: PauseMenuDelegate?

    // UI Elements
    private var backgroundDimmer: SKSpriteNode!
    private var menuContainer: SKSpriteNode!
    private var titleLabel: SKLabelNode!
    private var resumeButton: MenuButton!
    private var restartButton: MenuButton!

    // Touch tracking
    private var pressedButton: MenuButton?

    private let viewSize: CGSize

    init(viewSize: CGSize) {
        self.viewSize = viewSize
        super.init()
        setupOverlay()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupOverlay() {
        name = "pauseMenuOverlay"
        zPosition = 150

        // Semi-transparent background
        backgroundDimmer = SKSpriteNode(
            color: SKColor(white: 0, alpha: 0.7),
            size: viewSize
        )
        backgroundDimmer.zPosition = 0
        addChild(backgroundDimmer)

        // Menu container
        menuContainer = SKSpriteNode(
            color: SKColor(white: 0.15, alpha: 0.95),
            size: CGSize(width: 260, height: 200)
        )
        menuContainer.zPosition = 1
        menuContainer.position = .zero
        addChild(menuContainer)

        // Border effect
        let border = SKShapeNode(rectOf: CGSize(width: 262, height: 202), cornerRadius: 12)
        border.strokeColor = SKColor(white: 0.4, alpha: 1.0)
        border.lineWidth = 2
        border.fillColor = .clear
        border.zPosition = 2
        menuContainer.addChild(border)

        // Title
        titleLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        titleLabel.text = "PAUSED"
        titleLabel.fontSize = 28
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: 55)
        titleLabel.zPosition = 3
        addChild(titleLabel)

        // Resume Button (green)
        resumeButton = MenuButton(
            text: "RESUME",
            size: CGSize(width: 160, height: 44),
            color: SKColor(red: 0.2, green: 0.55, blue: 0.3, alpha: 1.0)
        )
        resumeButton.position = CGPoint(x: 0, y: 0)
        resumeButton.name = "resumeButton"
        resumeButton.zPosition = 3
        addChild(resumeButton)

        // Restart Button (red)
        restartButton = MenuButton(
            text: "RESTART",
            size: CGSize(width: 160, height: 44),
            color: SKColor(red: 0.6, green: 0.2, blue: 0.2, alpha: 1.0)
        )
        restartButton.position = CGPoint(x: 0, y: -55)
        restartButton.name = "restartButton"
        restartButton.zPosition = 3
        addChild(restartButton)
    }

    // MARK: - Touch Handling

    func handleTouchBegan(at location: CGPoint) -> Bool {
        guard let parentNode = parent else { return false }
        let localLocation = convert(location, from: parentNode)

        if resumeButton.hitTest(localLocation) {
            resumeButton.setPressed(true)
            pressedButton = resumeButton
            return true
        }

        if restartButton.hitTest(localLocation) {
            restartButton.setPressed(true)
            pressedButton = restartButton
            return true
        }

        return false
    }

    func handleTouchMoved(at location: CGPoint) {
        guard let pressed = pressedButton, let parentNode = parent else { return }

        let localLocation = convert(location, from: parentNode)
        let stillInside = pressed.hitTest(localLocation)
        pressed.setPressed(stillInside)
    }

    func handleTouchEnded(at location: CGPoint) {
        guard let pressed = pressedButton, let parentNode = parent else { return }

        let localLocation = convert(location, from: parentNode)
        pressed.setPressed(false)

        if pressed.hitTest(localLocation) {
            // Button was activated
            if pressed === resumeButton {
                delegate?.pauseMenuDidSelectResume()
            } else if pressed === restartButton {
                delegate?.pauseMenuDidSelectRestart()
            }
        }

        pressedButton = nil
    }

    func handleTouchCancelled() {
        pressedButton?.setPressed(false)
        pressedButton = nil
    }

    // MARK: - Animation

    func animateIn() {
        alpha = 0
        menuContainer.setScale(0.8)

        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.2)
        scaleUp.timingMode = .easeOut

        run(fadeIn)
        menuContainer.run(scaleUp)
    }

    func animateOut(completion: @escaping () -> Void) {
        let fadeOut = SKAction.fadeOut(withDuration: 0.15)
        let scaleDown = SKAction.scale(to: 0.9, duration: 0.15)

        menuContainer.run(scaleDown)
        run(SKAction.sequence([fadeOut, SKAction.run(completion)]))
    }
}

// MARK: - MenuButton Helper Class

class MenuButton: SKSpriteNode {
    private let label: SKLabelNode
    private let normalColor: SKColor
    private let pressedColor: SKColor

    init(text: String, size: CGSize, color: SKColor) {
        self.normalColor = color
        self.pressedColor = color.withAlphaComponent(0.6)

        label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.text = text
        label.fontSize = 16
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center

        super.init(texture: nil, color: color, size: size)

        addChild(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setPressed(_ pressed: Bool) {
        color = pressed ? pressedColor : normalColor
        let scale: CGFloat = pressed ? 0.95 : 1.0
        run(SKAction.scale(to: scale, duration: 0.05))
    }

    func hitTest(_ point: CGPoint) -> Bool {
        let rect = CGRect(
            x: -size.width / 2,
            y: -size.height / 2,
            width: size.width,
            height: size.height
        )
        return rect.contains(point)
    }
}
