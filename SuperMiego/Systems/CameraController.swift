import SpriteKit

class CameraController {
    weak var camera: SKCameraNode?
    weak var player: SKNode?

    private var levelBounds: CGRect = .zero
    private var viewportSize: CGSize = .zero

    // MARK: - Setup

    func configure(camera: SKCameraNode, player: SKNode, levelBounds: CGRect, viewportSize: CGSize) {
        self.camera = camera
        self.player = player
        self.levelBounds = levelBounds
        self.viewportSize = viewportSize

        // Start camera centered on player, clamped to level
        let startX = max(viewportSize.width / 2,
                        min(player.position.x, levelBounds.width - viewportSize.width / 2))
        camera.position = CGPoint(x: startX, y: viewportSize.height / 2)
    }

    // MARK: - Update

    func update(deltaTime: TimeInterval) {
        guard let camera = camera, let player = player else { return }

        // Target X - player position with slight lead
        let leadOffset: CGFloat = 60
        let targetX = player.position.x + (player.xScale > 0 ? leadOffset : -leadOffset)

        // Smooth follow X
        let smoothingX: CGFloat = 0.08
        var newX = camera.position.x + (targetX - camera.position.x) * smoothingX

        // Clamp X to level bounds
        let minX = viewportSize.width / 2
        let maxX = max(minX, levelBounds.width - viewportSize.width / 2)
        newX = max(minX, min(maxX, newX))

        // Camera Y follows player directly - center on player
        let targetY = player.position.y
        let smoothingY: CGFloat = 0.2  // Fast Y tracking
        var newY = camera.position.y + (targetY - camera.position.y) * smoothingY

        // Clamp Y so the viewport bottom never goes below ground level (y=0)
        let minY = viewportSize.height / 2
        let maxY = levelBounds.height
        newY = max(minY, min(maxY, newY))

        camera.position = CGPoint(x: newX, y: newY)
    }

    // MARK: - Reset

    func reset(to position: CGPoint) {
        guard let camera = camera else { return }

        let startX = max(viewportSize.width / 2,
                        min(position.x, levelBounds.width - viewportSize.width / 2))
        camera.position = CGPoint(x: startX, y: viewportSize.height / 2)
    }

    func updateBounds(_ bounds: CGRect) {
        levelBounds = bounds
    }

    // MARK: - Helpers

    func getVisibleRect() -> CGRect {
        guard let camera = camera else { return .zero }

        return CGRect(
            x: camera.position.x - viewportSize.width / 2,
            y: 0,
            width: viewportSize.width,
            height: viewportSize.height
        )
    }

    func isOnScreen(_ position: CGPoint) -> Bool {
        let rect = getVisibleRect()
        return rect.contains(position)
    }
}
