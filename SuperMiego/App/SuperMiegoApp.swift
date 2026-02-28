import SwiftUI
import SpriteKit

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
        GeometryReader { geometry in
            SpriteView(scene: createScene(size: geometry.size))
                .ignoresSafeArea()
        }
    }

    private func createScene(size: CGSize) -> SKScene {
        let scene = MenuScene(size: size)
        scene.scaleMode = .aspectFill
        return scene
    }
}

#Preview {
    GameContainerView()
        .ignoresSafeArea()
}
