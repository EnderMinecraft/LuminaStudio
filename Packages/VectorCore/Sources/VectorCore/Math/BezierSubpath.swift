import Foundation
import CoreGraphics

public struct BezierSubpath: Codable, Sendable, Equatable {
    public var id: UUID
    public var isClosed: Bool
    public var points: [AnchorPoint]
    
    public init(id: UUID = UUID(), isClosed: Bool = false, points: [AnchorPoint] = []) {
        self.id = id
        self.isClosed = isClosed
        self.points = points
    }
    
    public var boundingBox: CGRect {
        guard !points.isEmpty else { return .zero }
        var minX = points[0].position.x
        var maxX = points[0].position.x
        var minY = points[0].position.y
        var maxY = points[0].position.y
        
        for pt in points {
            minX = min(minX, pt.position.x)
            maxX = max(maxX, pt.position.x)
            minY = min(minY, pt.position.y)
            maxY = max(maxY, pt.position.y)
            
            if let inH = pt.inHandle {
                minX = min(minX, inH.x)
                maxX = max(maxX, inH.x)
                minY = min(minY, inH.y)
                maxY = max(maxY, inH.y)
            }
            if let outH = pt.outHandle {
                minX = min(minX, outH.x)
                maxX = max(maxX, outH.x)
                minY = min(minY, outH.y)
                maxY = max(maxY, outH.y)
            }
        }
        
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
