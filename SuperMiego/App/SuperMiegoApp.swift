import SwiftUI
import SpriteKit
import UIKit

@main
struct SuperMiegoApp: App {
    var body: some Scene {
        WindowGroup {
            GameContainerView()
                .ignoresSafeArea()
                .statusBarHidden()
        }
    }
}

struct GameContainerView: View {
    var body: some View {
        GameViewControllerRepresentable()
            .ignoresSafeArea()
    }
}

private struct GameViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> GameViewController {
        GameViewController()
    }

    func updateUIViewController(_ uiViewController: GameViewController, context: Context) {
    }
}

private final class GameViewController: UIViewController {
    private let skView = SKView()

    override var canBecomeFirstResponder: Bool {
        true
    }

    override func loadView() {
        view = skView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        skView.ignoresSiblingOrder = true
        skView.showsFPS = false
        skView.showsNodeCount = false
        skView.isMultipleTouchEnabled = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
        presentInitialSceneIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        presentInitialSceneIfNeeded()

        guard let scene = skView.scene, scene.size != skView.bounds.size else { return }

        scene.size = skView.bounds.size
        if let gameScene = scene as? GameScene {
            gameScene.viewportDidChangeSize()
        }
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if handleGameplayPresses(presses, isPressed: true) {
            return
        }
        super.pressesBegan(presses, with: event)
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if handleGameplayPresses(presses, isPressed: false) {
            return
        }
        super.pressesEnded(presses, with: event)
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if handleGameplayPresses(presses, isPressed: false) {
            return
        }
        super.pressesCancelled(presses, with: event)
    }

    private func presentInitialSceneIfNeeded() {
        guard skView.scene == nil, skView.bounds.size != .zero else { return }

        let scene = MenuScene(size: skView.bounds.size)
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)
    }

    private func handleGameplayPresses(_ presses: Set<UIPress>, isPressed: Bool) -> Bool {
        guard let gameScene = skView.scene as? GameScene else { return false }

        var handledAny = false
        for press in presses {
            guard let key = press.key?.charactersIgnoringModifiers.lowercased() else { continue }

            let handled: Bool
            if isPressed {
                handled = gameScene.handleKeyboardKeyDown(key)
            } else {
                handled = gameScene.handleKeyboardKeyUp(key)
            }

            handledAny = handledAny || handled
        }

        return handledAny
    }
}

#Preview {
    GameContainerView()
        .ignoresSafeArea()
}
