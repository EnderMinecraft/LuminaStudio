import Foundation
import CoreGraphics

public enum CurveFitting {
    // MARK: - Ramer-Douglas-Peucker (RDP) Polyline Simplification
    
    public static func simplifyRDP(points: [CGPoint], epsilon: CGFloat) -> [CGPoint] {
        guard points.count > 2 else { return points }
        
        var maxDistance: CGFloat = 0.0
        var index = 0
        let first = points.first!
        let last = points.last!
        
        for i in 1..<(points.count - 1) {
            let dist = perpendicularDistance(point: points[i], lineStart: first, lineEnd: last)
            if dist > maxDistance {
                maxDistance = dist
                index = i
            }
        }
        
        if maxDistance > epsilon {
            let left = simplifyRDP(points: Array(points[0...index]), epsilon: epsilon)
            let right = simplifyRDP(points: Array(points[index..<points.count]), epsilon: epsilon)
            return Array(left.dropLast()) + right
        } else {
            return [first, last]
        }
    }
    
    private static func perpendicularDistance(point: CGPoint, lineStart: CGPoint, lineEnd: CGPoint) -> CGFloat {
        let dx = lineEnd.x - lineStart.x
        let dy = lineEnd.y - lineStart.y
        let lenSq = dx * dx + dy * dy
        if lenSq == 0 {
            let px = point.x - lineStart.x
            let py = point.y - lineStart.y
            return sqrt(px * px + py * py)
        }
        
        let t = max(0, min(1, ((point.x - lineStart.x) * dx + (point.y - lineStart.y) * dy) / lenSq))
        let projX = lineStart.x + t * dx
        let projY = lineStart.y + t * dy
        let px = point.x - projX
        let py = point.y - projY
        return sqrt(px * px + py * py)
    }
    
    // MARK: - Schneider's Algorithm: Cubic Bezier Curve Fitting
    
    public static func fitCurve(points: [CGPoint], maxError: CGFloat) -> [BezierCurveSegment] {
        guard points.count >= 2 else { return [] }
        if points.count == 2 {
            let p0 = points[0]
            let p3 = points[1]
            let p1 = CGPoint(x: p0.x + (p3.x - p0.x) / 3.0, y: p0.y + (p3.y - p0.y) / 3.0)
            let p2 = CGPoint(x: p0.x + 2.0 * (p3.x - p0.x) / 3.0, y: p0.y + 2.0 * (p3.y - p0.y) / 3.0)
            return [BezierCurveSegment(p0: p0, p1: p1, p2: p2, p3: p3)]
        }
        
        let tHat1 = computeLeftTangent(points: points, end: 0)
        let tHat2 = computeRightTangent(points: points, end: points.count - 1)
        
        var segments: [BezierCurveSegment] = []
        fitCubic(points: points, first: 0, last: points.count - 1, tHat1: tHat1, tHat2: tHat2, error: maxError, segments: &segments)
        return segments
    }
    
    public static func fitSubpath(points: [CGPoint], maxError: CGFloat, isClosed: Bool) -> BezierSubpath {
        let segments = fitCurve(points: points, maxError: maxError)
        guard !segments.isEmpty else { return BezierSubpath(isClosed: isClosed, points: []) }
        
        var anchors: [AnchorPoint] = []
        for (i, seg) in segments.enumerated() {
            if i == 0 {
                anchors.append(AnchorPoint(
                    position: seg.p0,
                    inHandle: nil,
                    outHandle: seg.p1,
                    handleMode: .smooth
                ))
            } else {
                anchors[anchors.count - 1].outHandle = seg.p1
            }
            
            let isLast = (i == segments.count - 1)
            anchors.append(AnchorPoint(
                position: seg.p3,
                inHandle: seg.p2,
                outHandle: isLast ? nil : nil,
                handleMode: .smooth
            ))
        }
        
        return BezierSubpath(isClosed: isClosed, points: anchors)
    }
    
    // MARK: - Private Recursive Schneider Fitting Helpers
    
    private static func fitCubic(
        points: [CGPoint],
        first: Int,
        last: Int,
        tHat1: CGPoint,
        tHat2: CGPoint,
        error: CGFloat,
        segments: inout [BezierCurveSegment]
    ) {
        let count = last - first + 1
        if count == 2 {
            let p0 = points[first]
            let p3 = points[last]
            let dist = hypot(p3.x - p0.x, p3.y - p0.y) / 3.0
            let p1 = CGPoint(x: p0.x + tHat1.x * dist, y: p0.y + tHat1.y * dist)
            let p2 = CGPoint(x: p3.x + tHat2.x * dist, y: p3.y + tHat2.y * dist)
            segments.append(BezierCurveSegment(p0: p0, p1: p1, p2: p2, p3: p3))
            return
        }
        
        var u = chordLengthParameterize(points: points, first: first, last: last)
        var curve = generateBezier(points: points, first: first, last: last, uPrime: u, tHat1: tHat1, tHat2: tHat2)
        var (maxErr, splitPoint) = computeMaxError(points: points, first: first, last: last, curve: curve, u: u)
        
        if maxErr < error {
            segments.append(curve)
            return
        }
        
        // If error is small enough, try Newton-Raphson parameter re-estimation
        if maxErr < error * error * 2.0 {
            for _ in 0..<4 {
                let uPrime = reparameterize(points: points, first: first, last: last, u: u, curve: curve)
                curve = generateBezier(points: points, first: first, last: last, uPrime: uPrime, tHat1: tHat1, tHat2: tHat2)
                let (newErr, newSplit) = computeMaxError(points: points, first: first, last: last, curve: curve, u: uPrime)
                if newErr < error {
                    segments.append(curve)
                    return
                }
                u = uPrime
                maxErr = newErr
                splitPoint = newSplit
            }
        }
        
        // Split at point of maximum error
        let tHatCenter = computeCenterTangent(points: points, center: splitPoint)
        let negCenter = CGPoint(x: -tHatCenter.x, y: -tHatCenter.y)
        fitCubic(points: points, first: first, last: splitPoint, tHat1: tHat1, tHat2: tHatCenter, error: error, segments: &segments)
        fitCubic(points: points, first: splitPoint, last: last, tHat1: negCenter, tHat2: tHat2, error: error, segments: &segments)
    }
    
    private static func generateBezier(
        points: [CGPoint],
        first: Int,
        last: Int,
        uPrime: [Double],
        tHat1: CGPoint,
        tHat2: CGPoint
    ) -> BezierCurveSegment {
        let p0 = points[first]
        let p3 = points[last]
        let nPts = last - first + 1
        
        var c = [[0.0, 0.0], [0.0, 0.0]]
        var x = [0.0, 0.0]
        
        for i in 0..<nPts {
            let u = uPrime[i]
            let b0 = (1.0 - u) * (1.0 - u) * (1.0 - u)
            let b1 = 3.0 * u * (1.0 - u) * (1.0 - u)
            let b2 = 3.0 * u * u * (1.0 - u)
            let b3 = u * u * u
            
            let a1 = CGPoint(x: Double(tHat1.x) * b1, y: Double(tHat1.y) * b1)
            let a2 = CGPoint(x: Double(tHat2.x) * b2, y: Double(tHat2.y) * b2)
            
            c[0][0] += Double(a1.x * a1.x + a1.y * a1.y)
            c[0][1] += Double(a1.x * a2.x + a1.y * a2.y)
            c[1][0] = c[0][1]
            c[1][1] += Double(a2.x * a2.x + a2.y * a2.y)
            
            let pt = points[first + i]
            let tmp = CGPoint(
                x: Double(pt.x) - (Double(p0.x) * b0 + Double(p0.x) * b1 + Double(p3.x) * b2 + Double(p3.x) * b3),
                y: Double(pt.y) - (Double(p0.y) * b0 + Double(p0.y) * b1 + Double(p3.y) * b2 + Double(p3.y) * b3)
            )
            
            x[0] += Double(a1.x * tmp.x + a1.y * tmp.y)
            x[1] += Double(a2.x * tmp.x + a2.y * tmp.y)
        }
        
        let detC0C1 = c[0][0] * c[1][1] - c[1][0] * c[0][1]
        var alphaL = 0.0
        var alphaR = 0.0
        
        if abs(detC0C1) > 1e-6 {
            let detC0X = c[0][0] * x[1] - c[0][1] * x[0]
            let detXC1 = x[0] * c[1][1] - x[1] * c[0][1]
            alphaL = detXC1 / detC0C1
            alphaR = detC0X / detC0C1
        }
        
        let segLength = hypot(p3.x - p0.x, p3.y - p0.y)
        let epsilon = 1e-6 * Double(segLength)
        if alphaL < epsilon || alphaR < epsilon {
            alphaL = Double(segLength) / 3.0
            alphaR = alphaL
        }
        
        let p1 = CGPoint(x: Double(p0.x) + Double(tHat1.x) * alphaL, y: Double(p0.y) + Double(tHat1.y) * alphaL)
        let p2 = CGPoint(x: Double(p3.x) + Double(tHat2.x) * alphaR, y: Double(p3.y) + Double(tHat2.y) * alphaR)
        return BezierCurveSegment(p0: p0, p1: p1, p2: p2, p3: p3)
    }
    
    private static func reparameterize(
        points: [CGPoint],
        first: Int,
        last: Int,
        u: [Double],
        curve: BezierCurveSegment
    ) -> [Double] {
        var uPrime = u
        let count = last - first + 1
        for i in 0..<count {
            uPrime[i] = newtonRaphsonRootFind(curve: curve, point: points[first + i], u: u[i])
        }
        return uPrime
    }
    
    private static func newtonRaphsonRootFind(curve: BezierCurveSegment, point: CGPoint, u: Double) -> Double {
        let q_u = curve.point(at: u)
        let q_prime = curve.derivative(at: u)
        
        let num = (Double(q_u.x) - Double(point.x)) * Double(q_prime.x) + (Double(q_u.y) - Double(point.y)) * Double(q_prime.y)
        let den = Double(q_prime.x * q_prime.x + q_prime.y * q_prime.y)
        if abs(den) < 1e-6 { return u }
        let uNext = u - num / den
        return max(0.0, min(1.0, uNext))
    }
    
    private static func chordLengthParameterize(points: [CGPoint], first: Int, last: Int) -> [Double] {
        let count = last - first + 1
        var u = Array(repeating: 0.0, count: count)
        for i in 1..<count {
            let prev = points[first + i - 1]
            let curr = points[first + i]
            u[i] = u[i - 1] + Double(hypot(curr.x - prev.x, curr.y - prev.y))
        }
        let total = u.last ?? 1.0
        if total > 0.0 {
            for i in 0..<count {
                u[i] /= total
            }
        }
        return u
    }
    
    private static func computeMaxError(
        points: [CGPoint],
        first: Int,
        last: Int,
        curve: BezierCurveSegment,
        u: [Double]
    ) -> (CGFloat, Int) {
        var maxDist: CGFloat = 0.0
        var splitPoint = (last - first) / 2 + first
        let count = last - first + 1
        
        for i in 1..<(count - 1) {
            let ptOnCurve = curve.point(at: u[i])
            let actual = points[first + i]
            let dist = hypot(ptOnCurve.x - actual.x, ptOnCurve.y - actual.y)
            if dist > maxDist {
                maxDist = dist
                splitPoint = first + i
            }
        }
        return (maxDist, splitPoint)
    }
    
    private static func computeLeftTangent(points: [CGPoint], end: Int) -> CGPoint {
        let d = CGPoint(x: points[end + 1].x - points[end].x, y: points[end + 1].y - points[end].y)
        let len = hypot(d.x, d.y)
        return len > 0 ? CGPoint(x: d.x / len, y: d.y / len) : CGPoint(x: 1, y: 0)
    }
    
    private static func computeRightTangent(points: [CGPoint], end: Int) -> CGPoint {
        let d = CGPoint(x: points[end - 1].x - points[end].x, y: points[end - 1].y - points[end].y)
        let len = hypot(d.x, d.y)
        return len > 0 ? CGPoint(x: d.x / len, y: d.y / len) : CGPoint(x: -1, y: 0)
    }
    
    private static func computeCenterTangent(points: [CGPoint], center: Int) -> CGPoint {
        let pPrev = points[center - 1]
        let pNext = points[center + 1]
        let d = CGPoint(x: pNext.x - pPrev.x, y: pNext.y - pPrev.y)
        let len = hypot(d.x, d.y)
        return len > 0 ? CGPoint(x: d.x / len, y: d.y / len) : CGPoint(x: 1, y: 0)
    }
}
