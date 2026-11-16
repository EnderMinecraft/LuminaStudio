import Foundation
import CoreGraphics

public struct LineSegment: Sendable, Equatable {
    public let start: CGPoint
    public let end: CGPoint
    
    public init(start: CGPoint, end: CGPoint) {
        self.start = start
        self.end = end
    }
}

public final class MarchingAntsGenerator: Sendable {
    public static let shared = MarchingAntsGenerator()
    
    public init() {}
    
    /// Generates boundary line segments around selected regions (threshold >= 128)
    public func generateBorderSegments(mask: SelectionMask, sampleStep: Int = 1) -> [LineSegment] {
        let w = mask.width
        let h = mask.height
        let step = max(1, sampleStep)
        var segments: [LineSegment] = []
        
        func isSelected(_ x: Int, _ y: Int) -> Bool {
            guard x >= 0, x < w, y >= 0, y < h else { return false }
            return mask.data[y * w + x] >= 128
        }
        
        for y in stride(from: 0, to: h, by: step) {
            for x in stride(from: 0, to: w, by: step) {
                let current = isSelected(x, y)
                
                // Right border
                if current != isSelected(x + step, y) {
                    let rx = CGFloat(x + step)
                    segments.append(LineSegment(
                        start: CGPoint(x: rx, y: CGFloat(y)),
                        end: CGPoint(x: rx, y: CGFloat(y + step))
                    ))
                }
                
                // Bottom border
                if current != isSelected(x, y + step) {
                    let by = CGFloat(y + step)
                    segments.append(LineSegment(
                        start: CGPoint(x: CGFloat(x), y: by),
                        end: CGPoint(x: CGFloat(x + step), y: by)
                    ))
                }
            }
        }
        
        return segments
    }
    
    public func createCGPath(from segments: [LineSegment]) -> CGPath {
        let path = CGMutablePath()
        for seg in segments {
            path.move(to: seg.start)
            path.addLine(to: seg.end)
        }
        return path
    }
}
