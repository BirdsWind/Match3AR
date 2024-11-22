import Combine
import SwiftUI
import RealityKit

struct GameView: NSViewControllerRepresentable {
    func makeNSViewController(context: Context) -> GameViewController {
        return GameViewController()
    }
    
    func updateNSViewController(_ uiViewController: GameViewController, context: Context) {
    }
}

class GameViewController: NSViewController {
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
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.red.cgColor
    }
    
    override func loadView() {
        view = NSView(frame: NSMakeRect(0.0, 0.0, 300, 300))
        
        let label = NSTextField(labelWithString: "NSViewController without Storyboard")
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
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
        
        let click = NSClickGestureRecognizer(target: self, action: #selector(onClickGesture))
        self.arView.addGestureRecognizer(click)
    }
    
    
    @objc
    func onClickGesture(_ click: NSClickGestureRecognizer) {
        guard let ray = arView.ray(through: click.location(in: arView)) else {
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
