import RealityKit
import SwiftUI

#if os(iOS) || os(visionOS)
import UIKit
typealias PlatformColor = UIColor
#elseif os(macOS)
import AppKit
typealias PlatformColor = NSColor
#endif

class Tile {
    var type: Int
    var row: Int
    var col: Int
    var entity: Entity
    
    init(type: Int, row: Int, col: Int) {
        self.type = type
        self.row = row
        self.col = col
        
        let color = Tile.getColor(type: type)
        let mesh = MeshResource.generateSphere(radius: 0.05)
        let material = SimpleMaterial(color:color, isMetallic: false)
        self.entity = ModelEntity(mesh: mesh, materials: [material])
        self.entity.generateCollisionShapes(recursive: true)
        self.entity.name = Tile.colorName(color: color)
        
        // Set initial position
        self.entity.position = SIMD3<Float>(Float(Constants.columns-col)*Constants.tileSize, Float(Constants.rows-row)*Constants.tileSize,0)
        
        // print("original position \(entity.position), row \(row), column \(col), name, \(entity.name)")
        
        self.entity.generateCollisionShapes(recursive: false)
        
#if os(visionOS)
        self.entity.components.set(InputTargetComponent())
        self.entity.components.set(HoverEffectComponent())
#endif
        
        
    }
    
    
    // Assign a color based on tile type
    static func getColor(type: Int) -> PlatformColor {
        switch type {
        case 0: return .red
        case 1: return .blue
        case 2: return .green
        default: return .gray
        }
    }
    
    static func colorName(color: PlatformColor) -> String {
        switch color {
        case .red:
            return "red"
        case .blue:
            return "blue"
        case .green:
            return "green"
        default:
            return "gray"
        }
    }
}
