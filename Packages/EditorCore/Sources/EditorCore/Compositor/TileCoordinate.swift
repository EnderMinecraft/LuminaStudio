import Foundation
import CoreGraphics

public struct TileCoordinate: Hashable, Codable, Sendable {
    public static let defaultTileSize: Int = 256
    
    public let x: Int
    public let y: Int
    public let tileSize: Int
    
    public init(x: Int, y: Int, tileSize: Int = defaultTileSize) {
        self.x = x
        self.y = y
        self.tileSize = tileSize
    }
    
    public var rect: CGRect {
        CGRect(
            x: CGFloat(x * tileSize),
            y: CGFloat(y * tileSize),
            width: CGFloat(tileSize),
            height: CGFloat(tileSize)
        )
    }
    
    public func clampedRect(canvasWidth: Int, canvasHeight: Int) -> CGRect {
        let base = rect
        let canvasRect = CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight)
        return base.intersection(canvasRect)
    }
}
