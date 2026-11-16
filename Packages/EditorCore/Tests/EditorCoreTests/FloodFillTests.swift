import XCTest
import CoreGraphics
@testable import EditorCore

final class FloodFillTests: XCTestCase {
    func testContiguousFloodFill() {
        let engine = FloodFillEngine.shared
        // 10x10 white buffer
        var buffer = [UInt8](repeating: 255, count: 10 * 10 * 4)
        
        // Draw black vertical barrier dividing buffer into left and right at x = 5
        for y in 0..<10 {
            let idx = (y * 10 + 5) * 4
            buffer[idx] = 0
            buffer[idx + 1] = 0
            buffer[idx + 2] = 0
            buffer[idx + 3] = 255
        }
        
        // Fill left side at (2, 2) with pure red
        let red = ColorRGBA(r: 255, g: 0, b: 0, a: 255)
        engine.fill(
            startPoint: CGPoint(x: 2, y: 2),
            fillColor: red,
            tolerance: 0.1,
            isContiguous: true,
            buffer: &buffer,
            width: 10,
            height: 10
        )
        
        // Left side (2, 2) must be filled with red
        let filledIdx = (2 * 10 + 2) * 4
        XCTAssertEqual(buffer[filledIdx], 255)
        XCTAssertEqual(buffer[filledIdx + 1], 0)
        XCTAssertEqual(buffer[filledIdx + 2], 0)
        
        // Right side (8, 2) should NOT be filled (remains white)
        let rightIdx = (2 * 10 + 8) * 4
        XCTAssertEqual(buffer[rightIdx], 255)
        XCTAssertEqual(buffer[rightIdx + 1], 255)
        XCTAssertEqual(buffer[rightIdx + 2], 255)
    }
}
