
import SwiftUI
import RealityKit

struct GameView: View {
    @State var sceneUpdateSubscription: EventSubscription? = nil
    @State var gameController: GameController
    @State var root: Entity
    @State var camera: Entity
    
    init() {
        let root = Entity()
        let camera = Entity()
        self._root = State(wrappedValue: root)
        self._camera = State(wrappedValue: camera)
        let gameController = GameController(root: root, camera: camera)
        self.gameController = gameController
    }
    
    var body: some View {
        RealityView { content in
            let world = Entity()
            world.addChild(root)
            world.addChild(camera)
            content.add(world)
            
            // towards TV depth z position, minus, deeper
            // towards ceiling y position plus, higher
            //towards window, left and right, plus towards right
            //recommendation pretty centered [0.5,1, 0], camera position [0,0,root]
            world.position = [0.5,1, 0]
            
            sceneUpdateSubscription = content.subscribe(to: SceneEvents.Update.self) { event in
                root.transform = Transform(matrix: camera.transform.matrix.inverse)
            }
            
            gameController.setupScene()
            
        }.gesture(TapGesture().targetedToAnyEntity().onEnded { tap in
            if let tile = gameController.getTile(from: tap.entity) {
                gameController.didPressTile(tile: tile)
            }
            
        })
    }
}






