import XCTest
@testable import EditorCore

final class FilterTests: XCTestCase {
    func testPixelateHomogenizesBlocks() {
        let engine = FilterEngine.shared
        // 4x4 image with alternating colors
        var buffer: [UInt8] = []
        for y in 0..<4 {
            for x in 0..<4 {
                let v = UInt8((x + y) * 20)
                buffer.append(contentsOf: [v, v, v, 255])
            }
        }
        
        engine.applyPixelate(blockSize: 2, buffer: &buffer, width: 4, height: 4)
        
        // Inside top-left 2x2 block (pixels (0,0), (1,0), (0,1), (1,1)), all values should be identical!
        let v00 = buffer[(0 * 4 + 0) * 4]
        let v10 = buffer[(0 * 4 + 1) * 4]
        let v01 = buffer[(1 * 4 + 0) * 4]
        let v11 = buffer[(1 * 4 + 1) * 4]
        
        XCTAssertEqual(v00, v10)
        XCTAssertEqual(v00, v01)
        XCTAssertEqual(v00, v11)
    }
    
    func testChromaticAberrationOffset() {
        let engine = FilterEngine.shared
        // 10x1 image: black on left, white on right
        var buffer: [UInt8] = []
        for x in 0..<10 {
            let v: UInt8 = x >= 5 ? 255 : 0
            buffer.append(contentsOf: [v, v, v, 255])
        }
        
        // Offset red by 2px to left
        engine.applyChromaticAberration(offsetPixels: 2, buffer: &buffer, width: 10, height: 1)
        
        // At x = 5: red is sampled from x = 3 (which was 0), while green is at x = 5 (255)
        let idx5 = 5 * 4
        XCTAssertEqual(buffer[idx5], 0)     // Red
        XCTAssertEqual(buffer[idx5 + 1], 255) // Green
    }
}
