import XCTest
import CoreGraphics
@testable import EditorCore

final class SelectionTests: XCTestCase {
    func testRectSelection() {
        let engine = SelectionEngine.shared
        let rect = CGRect(x: 2, y: 2, width: 4, height: 4)
        let mask = engine.makeRectSelection(rect: rect, width: 10, height: 10)
        
        // Point inside rect (e.g. 3, 3) must be 255
        XCTAssertEqual(mask[3 * 10 + 3], 255)
        // Point outside rect (e.g. 0, 0) must be 0
        XCTAssertEqual(mask[0], 0)
    }
    
    func testEllipseSelection() {
        let engine = SelectionEngine.shared
        let rect = CGRect(x: 0, y: 0, width: 10, height: 10)
        let mask = engine.makeEllipseSelection(in: rect, width: 10, height: 10)
        
        // Center (5, 5) must be 255
        XCTAssertEqual(mask[5 * 10 + 5], 255)
        // Corner (0, 0) must be 0
        XCTAssertEqual(mask[0], 0)
    }
    
    func testSelectionBooleanOperations() {
        let sel = SelectionMask(width: 4, height: 4, initialValue: 0)
        // Set left half to 255
        var leftHalf = [UInt8](repeating: 0, count: 16)
        for y in 0..<4 {
            leftHalf[y * 4 + 0] = 255
            leftHalf[y * 4 + 1] = 255
        }
        
        // 1. Replace
        sel.combine(with: leftHalf, mode: .replace)
        XCTAssertEqual(sel.data[0], 255)
        XCTAssertEqual(sel.data[3], 0)
        
        // 2. Add right column
        var rightCol = [UInt8](repeating: 0, count: 16)
        for y in 0..<4 {
            rightCol[y * 4 + 3] = 255
        }
        sel.combine(with: rightCol, mode: .add)
        XCTAssertEqual(sel.data[0], 255)
        XCTAssertEqual(sel.data[3], 255)
        
        // 3. Subtract right column
        sel.combine(with: rightCol, mode: .subtract)
        XCTAssertEqual(sel.data[3], 0)
        XCTAssertEqual(sel.data[0], 255)
        
        // 4. Invert
        sel.invert()
        XCTAssertEqual(sel.data[3], 255)
        XCTAssertEqual(sel.data[0], 0)
    }
    
    func testDilationAndErosion() {
        let mask = SelectionMask(width: 10, height: 10, initialValue: 0)
        // Single central pixel
        mask.data[5 * 10 + 5] = 255
        
        // Expand (dilation) by 1 pixel
        mask.expand(pixels: 1)
        // Neighboring pixels should now be 255
        XCTAssertEqual(mask.data[5 * 10 + 6], 255)
        XCTAssertEqual(mask.data[6 * 10 + 5], 255)
        // Far pixel remains 0
        XCTAssertEqual(mask.data[0], 0)
        
        // Contract (erosion) by 1 pixel
        mask.contract(pixels: 1)
        // Corners around center must be eroded back to 0
        XCTAssertEqual(mask.data[6 * 10 + 6], 0)
    }
}
