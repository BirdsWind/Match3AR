import RealityKit
import SwiftUI

class GameController {
    private var root: Entity
    private var camera: Entity
    private var grid: [[Tile?]] = []
    
    init(root: Entity, camera: Entity) {
        self.root = root
        self.camera = camera
    }
    
    func setupScene() {
        // the rendering goes from the top right as the first ball
        for row in (0..<Constants.rows) {
            var rowTiles = [Tile]()
            for col in (0..<Constants.columns) {
                var tile: Tile
                repeat {
                    tile = Tile(type: Int.random(in: 0..<Constants.tileTypes), row: row, col: col)
                } while hasHorizontalMatch(at: row, col: col, with: tile, rowTiles: rowTiles)
                
                root.addChild(tile.entity)
                rowTiles.append(tile)
            }
            grid.append(rowTiles)
        }
        
        camera.look(at: [0, 0, 0], from: [0, 0,Constants.cameraPosition], relativeTo: root)
    }
    
    private func hasHorizontalMatch(at row: Int, col: Int, with tile: Tile, rowTiles: [Tile]) -> Bool {
        let currentType = tile.type
        
        // Check for horizontal match (left and second-left tiles)
        if col >= 2 {
            let leftTile = rowTiles[col - 1]
            let secondLeftTile = rowTiles[col - 2]
            if leftTile.type == currentType, secondLeftTile.type == currentType {
                return true
            }
        }
        return false
    }
    
    func getTile(from entity: Entity) -> Tile? {
        let row = getTileRow(position: entity.position)
        let column = getTileColumn(position: entity.position)
        return grid[row][column]
    }
    
    func didPressTile(tile: Tile) {
        animateRemove(tile: tile, withDuration: 0.3) {
            self.removeTile(tile: tile)
        }
    }
    
    private func getTileRow(position:SIMD3<Float>)-> Int {
        return Int((Float(Constants.rows)-position.y/Constants.tileSize).rounded())
    }
    
    private func getTileColumn(position:SIMD3<Float>)-> Int {
        return Int((Float(Constants.columns)-position.x/Constants.tileSize).rounded())
    }
    
    private func removeTile(tile: Tile) {
        tile.entity.removeFromParent()
        self.grid[tile.row][tile.col] = nil
        self.dropTiles() { [self] in
            self.checkAndRemoveHorizontalMatches()
            
        }
    }
    
    
    private func dropTiles(completion: @escaping ()->Void) {
        var animationCount = 0
        
        for col in 0..<Constants.columns {
            for row in (0..<Constants.rows).reversed() {
                
                
                if grid[row][col] == nil {
                    for aboveRow in (0..<row).reversed() {
                        if let upperTile = grid[aboveRow][col] {
                            //Move tile down
                            grid[row][col] = upperTile
                            upperTile.row = row
                            grid[aboveRow][col] = nil
                            animationCount += 1
                            animateTileFall(tile:upperTile) {
                                animationCount -= 1
                                if animationCount == 0 {
                                    print("all tiles fallen")
                                }
                            }
                            break
                        }
                    }
                }
            }
            
            // Fill the top row with new random tiles if needed
            for emptyRow in 0..<Constants.rows {
                if grid[emptyRow][col] == nil {
                    let newTile = Tile(type: Int.random(in: 0..<Constants.tileTypes), row: emptyRow, col: col)
                    newTile.entity.position.y = Float(Constants.rows-emptyRow+1)*Constants.tileSize
                    newTile.entity.position.z = 0.0
                    animationCount += 1
                    root.addChild(newTile.entity)
                    grid[emptyRow][col] = newTile
                    animateTileFall(tile: newTile) {
                        animationCount -= 1
                        if animationCount == 0 {
                            completion() // Proceed when all new tiles are generated
                        }
                    }
                }
            }
        }
        
        // If no animations are required, trigger the completion immediately
        if animationCount == 0 {
            completion()
        }
    }
    
    
    private func animateTileFall(tile: Tile, completion: @escaping ()-> Void) {
        let duration: TimeInterval = 0.5
        let finalPosition = SIMD3<Float>(Float(Constants.columns-tile.col)*Constants.tileSize, Float(Constants.rows-tile.row)*Constants.tileSize, 0)
        
        let moveAction = RealityKit.Transform(translation: finalPosition)
        
        let relativeEntity: Entity?
#if os(xrOS)
        relativeEntity =  camera
#else
        relativeEntity = nil
#endif
        tile.entity.move(to: moveAction, relativeTo: relativeEntity, duration: duration, timingFunction: .easeInOut)
        print("after move action, tile position \(tile.entity.position)")
        DispatchQueue.main.asyncAfter(deadline: .now()+duration + 0.5){
            print("after move action, tile position \(tile.entity.position)")
            completion()
        }
    }
    
    
    func animateRemove(tile: Tile, withDuration duration: TimeInterval, completion: @escaping () -> Void) {
        // Scale down to make it "disappear"
        let finalScale = SIMD3<Float>(repeating: 0.001)
        let relativeEntity: Entity?
#if os(xrOS)
        relativeEntity =  camera
#else
        relativeEntity = nil
#endif
        
        tile.entity.move(to: Transform(scale: finalScale, rotation: tile.entity.transform.rotation, translation: tile.entity.transform.translation),
                         relativeTo: relativeEntity, duration: duration, timingFunction: .easeInOut)
        
        // After the animation completes, call the completion handler to remove the tile
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            completion()
        }
    }
    
    private func findFirstHorizontalMatch() -> [Tile]? {
        for row in 0..<Constants.rows {
            var match: [Tile] = []
            var previousType: Int? = nil
            
            for column in 0..<Constants.columns {
                if let tile = grid[row][column] {
                    if tile.type == previousType {
                        match.append(tile)
                    } else {
                        if match.count >= 3 {
                            return match // Return the first match found
                        }
                        match = [tile] // Start a new match sequence
                    }
                    previousType = tile.type
                }
            }
            
            if match.count >= 3 {
                return match // Return the match if it's at the end of the row
            }
        }
        return nil
    }
    
    
    private func checkAndRemoveHorizontalMatches() {
        if let match = findFirstHorizontalMatch() {
            // Remove the match with animation
            removeMatch(match: match) {
                // After removal, update tile positions
                self.dropTiles() {
                    self.checkAndRemoveHorizontalMatches() // Recursive call to check for the next match
                }
            }
        } else {
            // No more matches found
            print("No more horizontal matches.")
        }
    }
    
    private func removeMatch(match: [Tile], completion: @escaping ()->Void) {
        for tile in match {
            tile.entity.removeFromParent()
            self.grid[tile.row][tile.col] = nil
            //TODO: can add animation
        }
        
        // Once all tiles are removed, trigger the next step
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion()
        }
    }
    
}

