import XCTest
import CoreGraphics
@testable import EditorCore

final class CutoutTests: XCTestCase {
    func testShiftEdgeExpansionAndContraction() {
        let engine = CutoutEngine.shared
        let mask = LayerMask(width: 10, height: 10, initialValue: 0)
        // Center pixel at (5, 5)
        mask.setSample(x: 5, y: 5, value: 255)
        
        // Shift edge +1 (expansion)
        engine.shiftEdge(mask: mask, delta: 1)
        XCTAssertEqual(mask.sample(x: 5, y: 5), 255)
        XCTAssertEqual(mask.sample(x: 5, y: 6), 255)
        XCTAssertEqual(mask.sample(x: 6, y: 5), 255)
        XCTAssertEqual(mask.sample(x: 0, y: 0), 0)
        
        // Shift edge -1 (contraction)
        engine.shiftEdge(mask: mask, delta: -1)
        // Edges should be contracted back
        XCTAssertEqual(mask.sample(x: 6, y: 6), 0)
    }
    
    func testFeatherEdgeSmoothsTransition() {
        let engine = CutoutEngine.shared
        let mask = LayerMask(width: 10, height: 10, initialValue: 0)
        // Fill top half with 255
        for y in 0..<5 {
            for x in 0..<10 {
                mask.setSample(x: x, y: y, value: 255)
            }
        }
        
        engine.feather(mask: mask, radius: 2)
        // Boundary row 4 should now have feathered intermediate value between 0 and 255
        let valRow4 = mask.sample(x: 5, y: 4)
        XCTAssertGreaterThan(valRow4, 50)
        XCTAssertLessThan(valRow4, 255)
        
        // Boundary row 5 should now have non-zero feathered alpha
        let valRow5 = mask.sample(x: 5, y: 5)
        XCTAssertGreaterThan(valRow5, 0)
        XCTAssertLessThan(valRow5, 200)
    }
    
    func testSmallSpeckRemoval() {
        let engine = CutoutEngine.shared
        let mask = LayerMask(width: 20, height: 20, initialValue: 0)
        
        // 1. Large subject island (10x10 = 100 pixels)
        for y in 2..<12 {
            for x in 2..<12 {
                mask.setSample(x: x, y: y, value: 255)
            }
        }
        
        // 2. Stray island / speck (single pixel at 18, 18)
        mask.setSample(x: 18, y: 18, value: 255)
        // 3. Another small speck of 3 pixels
        mask.setSample(x: 18, y: 2, value: 255)
        mask.setSample(x: 18, y: 3, value: 255)
        mask.setSample(x: 19, y: 2, value: 255)
        
        // Remove specks smaller than 20 pixels
        let removedCount = engine.removeSmallSpecks(mask: mask, minPixelCount: 20)
        XCTAssertEqual(removedCount, 4) // 1 + 3 = 4 pixels removed
        
        // Main island remains preserved at 255
        XCTAssertEqual(mask.sample(x: 5, y: 5), 255)
        // Stray specks must now be 0!
        XCTAssertEqual(mask.sample(x: 18, y: 18), 0)
        XCTAssertEqual(mask.sample(x: 18, y: 2), 0)
    }
    
    func testContrastSteepening() {
        let engine = CutoutEngine.shared
        let mask = LayerMask(width: 2, height: 2, initialValue: 140) // slightly above 128
        engine.adjustContrast(mask: mask, contrast: 0.5)
        
        // Values above 128 should be driven closer to 255
        XCTAssertGreaterThan(mask.sample(x: 0, y: 0), 140)
    }
}
