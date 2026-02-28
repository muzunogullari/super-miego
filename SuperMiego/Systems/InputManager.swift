import SpriteKit

enum InputAction {
    case moveLeft
    case moveRight
    case jump
    case none
}

protocol InputManagerDelegate: AnyObject {
    func inputManager(_ manager: InputManager, didUpdateMovement direction: CGFloat)
    func inputManager(_ manager: InputManager, didStartJump hold: Bool)
    func inputManager(_ manager: InputManager, didEndJump: Void)
    func inputManager(_ manager: InputManager, didRequestShoot: Void)
}

class InputManager {
    weak var delegate: InputManagerDelegate?

    // Touch tracking
    private var movementTouch: UITouch?
    private var jumpTouch: UITouch?

    // State
    private(set) var currentDirection: CGFloat = 0
    private(set) var isJumpHeld: Bool = false
    private var jumpStartTime: TimeInterval = 0

    // Screen regions (calculated on first use)
    private var sceneSize: CGSize = .zero
    private var movementRegionWidth: CGFloat = 0

    func configure(for sceneSize: CGSize) {
        self.sceneSize = sceneSize
        self.movementRegionWidth = sceneSize.width / 3.0
    }

    // MARK: - Touch Handling

    func touchBegan(_ touch: UITouch, at location: CGPoint) {
        if location.x < movementRegionWidth {
            // Left third - movement
            handleMovementTouchBegan(touch, at: location)
        } else {
            // Right two-thirds - jump
            handleJumpTouchBegan(touch)
        }
    }

    func touchMoved(_ touch: UITouch, at location: CGPoint) {
        if touch == movementTouch {
            handleMovementTouchMoved(at: location)
        }
    }

    func touchEnded(_ touch: UITouch) {
        if touch == movementTouch {
            handleMovementTouchEnded()
        } else if touch == jumpTouch {
            handleJumpTouchEnded()
        }
    }

    func touchCancelled(_ touch: UITouch) {
        touchEnded(touch)
    }

    // MARK: - Movement

    private func handleMovementTouchBegan(_ touch: UITouch, at location: CGPoint) {
        movementTouch = touch
        updateMovementDirection(for: location)
    }

    private func handleMovementTouchMoved(at location: CGPoint) {
        updateMovementDirection(for: location)
    }

    private func handleMovementTouchEnded() {
        movementTouch = nil
        currentDirection = 0
        delegate?.inputManager(self, didUpdateMovement: 0)
    }

    private func updateMovementDirection(for location: CGPoint) {
        let regionCenter = movementRegionWidth / 2.0

        if location.x < regionCenter {
            currentDirection = -1
        } else {
            currentDirection = 1
        }

        delegate?.inputManager(self, didUpdateMovement: currentDirection)
    }

    // MARK: - Jump

    private func handleJumpTouchBegan(_ touch: UITouch) {
        jumpTouch = touch
        isJumpHeld = true
        jumpStartTime = CACurrentMediaTime()
        delegate?.inputManager(self, didStartJump: true)
    }

    private func handleJumpTouchEnded() {
        jumpTouch = nil
        isJumpHeld = false
        delegate?.inputManager(self, didEndJump: ())
    }

    // MARK: - Query Methods

    func getJumpHoldDuration() -> TimeInterval {
        guard isJumpHeld else { return 0 }
        return CACurrentMediaTime() - jumpStartTime
    }

    func requestShoot() {
        delegate?.inputManager(self, didRequestShoot: ())
    }

    // MARK: - Reset

    func reset() {
        movementTouch = nil
        jumpTouch = nil
        currentDirection = 0
        isJumpHeld = false
    }
}
