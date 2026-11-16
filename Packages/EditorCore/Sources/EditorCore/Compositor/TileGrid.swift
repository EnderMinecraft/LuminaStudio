import Foundation
import CoreGraphics

public struct TileGrid: Sendable {
    public let canvasWidth: Int
    public let canvasHeight: Int
    public let tileSize: Int
    public let columns: Int
    public let rows: Int
    
    public init(canvasWidth: Int, canvasHeight: Int, tileSize: Int = TileCoordinate.defaultTileSize) {
        self.canvasWidth = canvasWidth
        self.canvasHeight = canvasHeight
        self.tileSize = tileSize
        self.columns = max(1, Int(ceil(Double(canvasWidth) / Double(tileSize))))
        self.rows = max(1, Int(ceil(Double(canvasHeight) / Double(tileSize))))
    }
    
    public var totalTiles: Int {
        columns * rows
    }
    
    public func coordinate(for point: CGPoint) -> TileCoordinate? {
        guard point.x >= 0, point.x < CGFloat(canvasWidth),
              point.y >= 0, point.y < CGFloat(canvasHeight) else {
            return nil
        }
        let tx = Int(point.x) / tileSize
        let ty = Int(point.y) / tileSize
        return TileCoordinate(x: tx, y: ty, tileSize: tileSize)
    }
    
    public func tiles(intersecting rect: CGRect) -> [TileCoordinate] {
        guard rect.width > 0, rect.height > 0 else { return [] }
        let canvasRect = CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight)
        let clipped = rect.intersection(canvasRect)
        guard !clipped.isNull else { return [] }
        
        let minX = max(0, Int(floor(clipped.minX / CGFloat(tileSize))))
        let maxX = min(columns - 1, Int(floor((clipped.maxX - 0.001) / CGFloat(tileSize))))
        let minY = max(0, Int(floor(clipped.minY / CGFloat(tileSize))))
        let maxY = min(rows - 1, Int(floor((clipped.maxY - 0.001) / CGFloat(tileSize))))
        
        var result: [TileCoordinate] = []
        result.reserveCapacity((maxX - minX + 1) * (maxY - minY + 1))
        for ty in minY...maxY {
            for tx in minX...maxX {
                result.append(TileCoordinate(x: tx, y: ty, tileSize: tileSize))
            }
        }
        return result
    }
    
    public func allTiles() -> [TileCoordinate] {
        var result: [TileCoordinate] = []
        result.reserveCapacity(totalTiles)
        for ty in 0..<rows {
            for tx in 0..<columns {
                result.append(TileCoordinate(x: tx, y: ty, tileSize: tileSize))
            }
        }
        return result
    }
}
