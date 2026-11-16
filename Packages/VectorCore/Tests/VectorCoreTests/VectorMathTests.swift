import XCTest
import CoreGraphics
@testable import VectorCore

final class VectorMathTests: XCTestCase {
    func testBezierCurveEvaluation() {
        let p0 = CGPoint(x: 0, y: 0)
        let p1 = CGPoint(x: 0, y: 100)
        let p2 = CGPoint(x: 100, y: 100)
        let p3 = CGPoint(x: 100, y: 0)
        
        let curve = BezierCurveSegment(p0: p0, p1: p1, p2: p2, p3: p3)
        
        // At t = 0
        let start = curve.point(at: 0.0)
        XCTAssertEqual(start.x, 0.0, accuracy: 1e-4)
        XCTAssertEqual(start.y, 0.0, accuracy: 1e-4)
        
        // At t = 1
        let end = curve.point(at: 1.0)
        XCTAssertEqual(end.x, 100.0, accuracy: 1e-4)
        XCTAssertEqual(end.y, 0.0, accuracy: 1e-4)
        
        // At t = 0.5 (symmetric arch)
        let mid = curve.point(at: 0.5)
        XCTAssertEqual(mid.x, 50.0, accuracy: 1e-4)
        XCTAssertEqual(mid.y, 75.0, accuracy: 1e-4)
    }
    
    func testDeCasteljauSplit() {
        let p0 = CGPoint(x: 0, y: 0)
        let p1 = CGPoint(x: 0, y: 100)
        let p2 = CGPoint(x: 100, y: 100)
        let p3 = CGPoint(x: 100, y: 0)
        
        let curve = BezierCurveSegment(p0: p0, p1: p1, p2: p2, p3: p3)
        let (left, right) = curve.split(at: 0.5)
        
        // Left end point must match mid point
        let mid = curve.point(at: 0.5)
        XCTAssertEqual(left.p3.x, mid.x, accuracy: 1e-4)
        XCTAssertEqual(left.p3.y, mid.y, accuracy: 1e-4)
        
        // Right start point must match mid point
        XCTAssertEqual(right.p0.x, mid.x, accuracy: 1e-4)
        XCTAssertEqual(right.p0.y, mid.y, accuracy: 1e-4)
    }
    
    func testSubpathBoundingBox() {
        let p1 = AnchorPoint(position: CGPoint(x: 10, y: 20))
        let p2 = AnchorPoint(position: CGPoint(x: 100, y: 200))
        let subpath = BezierSubpath(isClosed: true, points: [p1, p2])
        
        let bbox = subpath.boundingBox
        XCTAssertEqual(bbox.origin.x, 10.0)
        XCTAssertEqual(bbox.origin.y, 20.0)
        XCTAssertEqual(bbox.width, 90.0)
        XCTAssertEqual(bbox.height, 180.0)
    }
}
