import Combine
import SwiftUI
import RealityKit
import ARKit

struct GameView: View {
    private let camera: PerspectiveCamera
    private let root: AnchorEntity
    private var gameController: GameController


    init() {
        self.camera = PerspectiveCamera()
        self.root = AnchorEntity()
        self.root.addChild(self.camera)
        self.gameController = GameController(root:self.root, camera: self.camera)
    }

    var body: some View {
        if #available(iOS 17.0, *) {
            // Use RealityView for iOS 17 and later
            RealityGameView(root: root, controller: gameController)
        } else {
            // Use ARView for iOS 16 and earlier
            ARGameView(root: root, controller: gameController)
        }

    }

#if swift(>=5.9) && canImport(RealityKit)
    @available(iOS 17.0, *)
    struct RealityGameView: UIViewRepresentable {
        private var root: AnchorEntity
        private var gameController: GameController

        init(root: AnchorEntity, controller: GameController) {
            self.root = root
            self.gameController = controller
        }

        var body: some View {
            RealityView { content in
                content.add(root)
                gameController.setupScene()
            }.gesture(TapGesture().targetedToAnyEntity().onEnded { tap in
                if let tile = gameController.getTile(from: tap.entity) {
                    gameController.didPressTile(tile: tile)
                }
            })
        }
    }

#else
    struct RealityGameView: View {
        private var root: AnchorEntity
        private var gameController: GameController

        init(root: AnchorEntity, controller: GameController) {
            self.root = root
            self.gameController = controller
        }


        var body: some View {
            Text("RealityView is unavaiable on this version of iOS")
        }
    }

#endif

    /// iOS 16 and earlier ARView implementation
    struct ARGameView: UIViewRepresentable {
        private var root: AnchorEntity
        private var gameController: GameController

        init(root: AnchorEntity, controller: GameController) {
            self.root = root
            self.gameController = controller
        }


        func makeCoordinator() -> Coordinator {
            Coordinator(controller: gameController)
        }

        func makeUIView(context: Context) -> ARView {
            let arView = ARView(frame: .zero)
            setupScene(for: arView)
            let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.onTapGesture(_:)))
            arView.addGestureRecognizer(tapGesture)
            context.coordinator.arView = arView
            return arView
        }

        func updateUIView(_ uiView: ARView, context: Context) {
            // Update the view if necessary
        }

        private func setupScene(for arView: ARView) {
            arView.scene.addAnchor(self.root)
            gameController.setupScene()
        }


        //Let's brighe the SwiftUI and UIKit, so we can take advantage of the UIViewRepresentable and UIKit functions by creating a coordinator class
        class Coordinator: NSObject, UIGestureRecognizerDelegate {
            var arView: ARView?
            private var gameController: GameController
            init(controller: GameController) {
                self.gameController = controller
                super.init()
            }
            
            @objc
            func onTapGesture(_ tap: UITapGestureRecognizer) {
                guard let ray = arView?.ray(through: tap.location(in: arView)) else {
                    return
                }

                guard let hit = arView?.scene.raycast(origin: ray.origin, direction: ray.direction).first else {
                    return
                }

                if let modelEntity = hit.entity as? ModelEntity, let tile = gameController.getTile(from: modelEntity) {
                    gameController.didPressTile(tile: tile)
                }
            }
        }
    }
}
