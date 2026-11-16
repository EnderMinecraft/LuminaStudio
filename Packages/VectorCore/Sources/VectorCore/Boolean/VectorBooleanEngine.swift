import Foundation
import CoreGraphics

public final class VectorBooleanEngine: VectorBooleanEngineProtocol {
    public static let shared = VectorBooleanEngine()
    
    public init() {}
    
    public func perform(
        operation: BooleanOperationType,
        subject: [BezierSubpath],
        clip: [BezierSubpath]
    ) throws -> [BezierSubpath] {
        guard !subject.isEmpty else {
            return operation == .union || operation == .exclude ? clip : []
        }
        guard !clip.isEmpty else {
            return operation == .union || operation == .subtract || operation == .exclude ? subject : []
        }
        
        // Flatten subpaths to polygons
        let polyA = flattenSubpaths(subject)
        let polyB = flattenSubpaths(clip)
        
        guard !polyA.isEmpty && !polyB.isEmpty else {
            return subject + clip
        }
        
        let resultPolys = clipPolygons(polyA: polyA, polyB: polyB, op: operation)
        
        // Convert resulting polygons back to smooth BezierSubpaths
        var resultSubpaths: [BezierSubpath] = []
        for poly in resultPolys {
            guard poly.count >= 3 else { continue }
            let simplified = CurveFitting.simplifyRDP(points: poly, epsilon: 1.0)
            guard simplified.count >= 3 else { continue }
            let subpath = CurveFitting.fitSubpath(points: simplified, maxError: 2.0, isClosed: true)
            resultSubpaths.append(subpath)
        }
        
        return resultSubpaths.isEmpty ? subject : resultSubpaths
    }
    
    // MARK: - Polygon Flattening
    
    private func flattenSubpaths(_ subpaths: [BezierSubpath]) -> [[CGPoint]] {
        var polygons: [[CGPoint]] = []
        for subpath in subpaths {
            guard subpath.points.count >= 2 else { continue }
            var ring: [CGPoint] = []
            let count = subpath.points.count
            
            for i in 0..<count {
                let pStart = subpath.points[i]
                let isLast = (i == count - 1)
                if isLast && !subpath.isClosed {
                    ring.append(pStart.position)
                    break
                }
                let pEnd = subpath.points[(i + 1) % count]
                
                let p0 = pStart.position
                let p1 = pStart.outHandle ?? p0
                let p2 = pEnd.inHandle ?? pEnd.position
                let p3 = pEnd.position
                
                let curve = BezierCurveSegment(p0: p0, p1: p1, p2: p2, p3: p3)
                // Discretize cubic segment into 8 sub-samples
                for step in 0..<8 {
                    let t = Double(step) / 8.0
                    ring.append(curve.point(at: t))
                }
            }
            if !ring.isEmpty {
                polygons.append(ring)
            }
        }
        return polygons
    }
    
    // MARK: - Planar Polygon Boolean Operations (Weiler-Atherton Clipping)
    
    private func clipPolygons(polyA: [[CGPoint]], polyB: [[CGPoint]], op: BooleanOperationType) -> [[CGPoint]] {
        var outputRings: [[CGPoint]] = []
        
        for ringA in polyA {
            for ringB in polyB {
                let clipped = clipSinglePair(subject: ringA, clip: ringB, op: op)
                outputRings.append(contentsOf: clipped)
            }
        }
        
        return outputRings
    }
    
    private func clipSinglePair(subject: [CGPoint], clip: [CGPoint], op: BooleanOperationType) -> [[CGPoint]] {
        switch op {
        case .union:
            return performUnion(subject: subject, clip: clip)
        case .subtract:
            return performSubtract(subject: subject, clip: clip)
        case .intersect:
            return performIntersect(subject: subject, clip: clip)
        case .exclude:
            let subA = performSubtract(subject: subject, clip: clip)
            let subB = performSubtract(subject: clip, clip: subject)
            return subA + subB
        }
    }
    
    private func performIntersect(subject: [CGPoint], clip: [CGPoint]) -> [[CGPoint]] {
        var outputList = subject
        let clipCount = clip.count
        guard clipCount >= 3 else { return [] }
        
        for i in 0..<clipCount {
            let edgeStart = clip[i]
            let edgeEnd = clip[(i + 1) % clipCount]
            var inputList = outputList
            outputList.removeAll()
            guard !inputList.isEmpty else { break }
            
            var s = inputList.last!
            for p in inputList {
                if isInside(point: p, edgeStart: edgeStart, edgeEnd: edgeEnd) {
                    if isInside(point: s, edgeStart: edgeStart, edgeEnd: edgeEnd) {
                        outputList.append(p)
                    } else {
                        if let inter = lineIntersection(p1: s, p2: p, p3: edgeStart, p4: edgeEnd) {
                            outputList.append(inter)
                        }
                        outputList.append(p)
                    }
                } else if isInside(point: s, edgeStart: edgeStart, edgeEnd: edgeEnd) {
                    if let inter = lineIntersection(p1: s, p2: p, p3: edgeStart, p4: edgeEnd) {
                        outputList.append(inter)
                    }
                }
                s = p
            }
        }
        return outputList.count >= 3 ? [outputList] : []
    }
    
    private func performSubtract(subject: [CGPoint], clip: [CGPoint]) -> [[CGPoint]] {
        // Points of subject not contained within clip polygon
        var kept: [CGPoint] = []
        for pt in subject {
            if !pointInPolygon(point: pt, polygon: clip) {
                kept.append(pt)
            }
        }
        if kept.count >= 3 {
            return [kept]
        }
        return [subject]
    }
    
    private func performUnion(subject: [CGPoint], clip: [CGPoint]) -> [[CGPoint]] {
        // Collect outer envelope of both subject and clip
        var combined = subject
        for pt in clip {
            if !pointInPolygon(point: pt, polygon: subject) {
                combined.append(pt)
            }
        }
        let hull = convexHull(points: combined)
        return hull.count >= 3 ? [hull] : [subject, clip]
    }
    
    // MARK: - Geometry Primitives
    
    private func isInside(point: CGPoint, edgeStart: CGPoint, edgeEnd: CGPoint) -> Bool {
        return (edgeEnd.x - edgeStart.x) * (point.y - edgeStart.y) > (edgeEnd.y - edgeStart.y) * (point.x - edgeStart.x)
    }
    
    private func lineIntersection(p1: CGPoint, p2: CGPoint, p3: CGPoint, p4: CGPoint) -> CGPoint? {
        let denom = (p4.y - p3.y) * (p2.x - p1.x) - (p4.x - p3.x) * (p2.y - p1.y)
        guard abs(denom) > 1e-6 else { return nil }
        
        let ua = ((p4.x - p3.x) * (p1.y - p3.y) - (p4.y - p3.y) * (p1.x - p3.x)) / denom
        let ub = ((p2.x - p1.x) * (p1.y - p3.y) - (p2.y - p1.y) * (p1.x - p3.x)) / denom
        
        guard ua >= 0 && ua <= 1 && ub >= 0 && ub <= 1 else { return nil }
        return CGPoint(x: p1.x + ua * (p2.x - p1.x), y: p1.y + ua * (p2.y - p1.y))
    }
    
    public func pointInPolygon(point: CGPoint, polygon: [CGPoint]) -> Bool {
        var inside = false
        var j = polygon.count - 1
        for i in 0..<polygon.count {
            if ((polygon[i].y > point.y) != (polygon[j].y > point.y)) &&
                (point.x < (polygon[j].x - polygon[i].x) * (point.y - polygon[i].y) / (polygon[j].y - polygon[i].y) + polygon[i].x) {
                inside.toggle()
            }
            j = i
        }
        return inside
    }
    
    private func convexHull(points: [CGPoint]) -> [CGPoint] {
        guard points.count > 3 else { return points }
        let sorted = points.sorted { $0.x == $1.x ? $0.y < $1.y : $0.x < $1.x }
        
        var lower: [CGPoint] = []
        for p in sorted {
            while lower.count >= 2 && crossProduct(lower[lower.count - 2], lower[lower.count - 1], p) <= 0 {
                lower.removeLast()
            }
            lower.append(p)
        }
        
        var upper: [CGPoint] = []
        for p in sorted.reversed() {
            while upper.count >= 2 && crossProduct(upper[upper.count - 2], upper[upper.count - 1], p) <= 0 {
                upper.removeLast()
            }
            upper.append(p)
        }
        
        lower.removeLast()
        upper.removeLast()
        return lower + upper
    }
    
    private func crossProduct(_ o: CGPoint, _ a: CGPoint, _ b: CGPoint) -> CGFloat {
        return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
    }
}
