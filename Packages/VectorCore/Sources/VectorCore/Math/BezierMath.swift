import Foundation
import CoreGraphics

public struct BezierCurveSegment: Sendable {
    public let p0: CGPoint
    public let p1: CGPoint
    public let p2: CGPoint
    public let p3: CGPoint
    
    public init(p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint) {
        self.p0 = p0
        self.p1 = p1
        self.p2 = p2
        self.p3 = p3
    }
    
    /// Evaluates curve point at t in [0, 1] using Bernstein polynomials
    public func point(at t: Double) -> CGPoint {
        let t = max(0.0, min(1.0, t))
        let u = 1.0 - t
        let tt = t * t
        let uu = u * u
        let uuu = uu * u
        let ttt = tt * t
        
        let x = uuu * Double(p0.x) + 3.0 * uu * t * Double(p1.x) + 3.0 * u * tt * Double(p2.x) + ttt * Double(p3.x)
        let y = uuu * Double(p0.y) + 3.0 * uu * t * Double(p1.y) + 3.0 * u * tt * Double(p2.y) + ttt * Double(p3.y)
        return CGPoint(x: x, y: y)
    }
    
    /// Evaluates derivative (tangent) at t in [0, 1]
    public func derivative(at t: Double) -> CGPoint {
        let t = max(0.0, min(1.0, t))
        let u = 1.0 - t
        let dx = 3.0 * u * u * Double(p1.x - p0.x) + 6.0 * u * t * Double(p2.x - p1.x) + 3.0 * t * t * Double(p3.x - p2.x)
        let dy = 3.0 * u * u * Double(p1.y - p0.y) + 6.0 * u * t * Double(p2.y - p1.y) + 3.0 * t * t * Double(p3.y - p2.y)
        return CGPoint(x: dx, y: dy)
    }
    
    /// Splits cubic curve into two sub-curves at parameter t using de Casteljau's algorithm
    public func split(at t: Double) -> (left: BezierCurveSegment, right: BezierCurveSegment) {
        let t = max(0.0, min(1.0, t))
        
        func lerp(_ a: CGPoint, _ b: CGPoint, _ factor: Double) -> CGPoint {
            CGPoint(x: Double(a.x) + (Double(b.x) - Double(a.x)) * factor,
                    y: Double(a.y) + (Double(b.y) - Double(a.y)) * factor)
        }
        
        let p01 = lerp(p0, p1, t)
        let p12 = lerp(p1, p2, t)
        let p23 = lerp(p2, p3, t)
        
        let p012 = lerp(p01, p12, t)
        let p123 = lerp(p12, p23, t)
        
        let p0123 = lerp(p012, p123, t)
        
        let left = BezierCurveSegment(p0: p0, p1: p01, p2: p012, p3: p0123)
        let right = BezierCurveSegment(p0: p0123, p1: p123, p2: p23, p3: p3)
        return (left, right)
    }
}
