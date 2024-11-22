import Combine
import SwiftUI
import RealityKit

struct GameView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> GameViewController {
        return GameViewController()
    }
    
    func updateUIViewController(_ uiViewController: GameViewController, context: Context) {
    }
}


class GameViewController: UIViewController {
    private let arView: ARView
    private let camera: PerspectiveCamera
    private let anchorEntity: AnchorEntity
    private let gameController: GameController
    
    
    init() {
        self.camera = PerspectiveCamera()
        self.arView = ARView()
        self.anchorEntity = AnchorEntity()
        self.anchorEntity.addChild(self.camera)
        self.arView.scene.addAnchor(self.anchorEntity)
        self.gameController = GameController(root:self.anchorEntity, camera: self.camera)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        self.view.addSubview(self.arView)
        self.arView.translatesAutoresizingMaskIntoConstraints = false
        self.arView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        self.arView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        self.arView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        self.arView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        gameController.setupScene()
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTapGesture))
        self.arView.addGestureRecognizer(tap)
    }
    
    @objc
    func onTapGesture(_ tap: UITapGestureRecognizer) {
        guard let ray = arView.ray(through: tap.location(in: arView)) else {
            return
        }
        
        guard let hit = arView.scene.raycast(origin: ray.origin, direction: ray.direction).first else {
            return
        }
        
        if let modelEntity = hit.entity as? ModelEntity, let tile = gameController.getTile(from: modelEntity) {
            gameController.didPressTile(tile: tile)
        }
    }
}
