import XCTest
import CoreGraphics
@testable import EditorCore

final class BrushMathTests: XCTestCase {
    func testCatmullRomInterpolation() {
        let engine = BrushEngine.shared
        let p0 = CGPoint(x: 0, y: 0)
        let p1 = CGPoint(x: 10, y: 10)
        let p2 = CGPoint(x: 20, y: 10)
        let p3 = CGPoint(x: 30, y: 0)
        
        let curve = engine.interpolatePoints(p0: p0, p1: p1, p2: p2, p3: p3, steps: 10)
        XCTAssertEqual(curve.count, 11)
        XCTAssertEqual(curve.first?.x ?? 0, 10.0, accuracy: 1e-4)
        XCTAssertEqual(curve.last?.x ?? 0, 20.0, accuracy: 1e-4)
    }
    
    func testPaintStampRGBA() {
        let engine = BrushEngine.shared
        var buffer = [UInt8](repeating: 0, count: 20 * 20 * 4)
        let preset = BrushPreset(size: 10.0, hardness: 1.0, opacity: 1.0, flow: 1.0)
        let color = (r: UInt8(255), g: UInt8(0), b: UInt8(0), a: UInt8(255))
        
        engine.paintStamp(
            at: CGPoint(x: 10, y: 10),
            preset: preset,
            color: color,
            pressure: 1.0,
            buffer: &buffer,
            width: 20,
            height: 20
        )
        
        // Center pixel (10, 10) must be pure red (255, 0, 0, 255)
        let centerIdx = (10 * 20 + 10) * 4
        XCTAssertEqual(buffer[centerIdx], 255)
        XCTAssertEqual(buffer[centerIdx + 1], 0)
        XCTAssertEqual(buffer[centerIdx + 2], 0)
        XCTAssertEqual(buffer[centerIdx + 3], 255)
        
        // Outside stamp radius (e.g. 0, 0) remains 0
        XCTAssertEqual(buffer[0], 0)
        XCTAssertEqual(buffer[3], 0)
    }
    
    func testPaintMaskStamp() {
        let engine = BrushEngine.shared
        var maskData = Data(repeating: 0, count: 20 * 20)
        let preset = BrushPreset(size: 8.0, hardness: 1.0, opacity: 1.0, flow: 1.0)
        
        engine.paintMaskStamp(
            at: CGPoint(x: 10, y: 10),
            preset: preset,
            value: 255,
            pressure: 1.0,
            maskData: &maskData,
            width: 20,
            height: 20
        )
        
        // Center pixel must be 255
        XCTAssertEqual(maskData[10 * 20 + 10], 255)
        // Outside must be 0
        XCTAssertEqual(maskData[0], 0)
    }
}
