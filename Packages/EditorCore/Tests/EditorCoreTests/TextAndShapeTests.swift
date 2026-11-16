import XCTest
import CoreGraphics
@testable import EditorCore

final class TextAndShapeTests: XCTestCase {
    func testTextRenderingProducesNonEmptyBuffer() {
        let engine = TextEngine.shared
        let style = TextStyleData(fontName: "HelveticaNeue", fontSize: 32.0, colorHex: "#FFFFFF")
        let (buffer, size) = engine.renderText(text: "Test", style: style, bounds: CGSize(width: 200, height: 100))
        
        XCTAssertGreaterThan(size.width, 0)
        XCTAssertGreaterThan(size.height, 0)
        XCTAssertEqual(buffer.count, Int(size.width * size.height * 4))
        // Must contain non-zero alpha pixels for text glyphs
        let hasVisiblePixels = buffer.contains { $0 > 0 }
        XCTAssertTrue(hasVisiblePixels)
    }
    
    func testShapeRenderingRectangle() {
        let engine = ShapeEngine.shared
        let shapeData = ShapeLayerData(type: .rectangle, fillColorHex: "#FF0000", strokeWidth: 0)
        let buffer = engine.renderShape(data: shapeData, bounds: CGSize(width: 50, height: 50))
        
        XCTAssertEqual(buffer.count, 50 * 50 * 4)
        // Center pixel (25, 25) should be filled with red (255, 0, 0, 255)
        let centerIdx = (25 * 50 + 25) * 4
        XCTAssertEqual(buffer[centerIdx], 255)
        XCTAssertEqual(buffer[centerIdx + 3], 255)
    }
    
    func testShapeRenderingStar() {
        let engine = ShapeEngine.shared
        let shapeData = ShapeLayerData(type: .star, fillColorHex: "#00FF00", strokeWidth: 0)
        let buffer = engine.renderShape(data: shapeData, bounds: CGSize(width: 60, height: 60))
        
        XCTAssertEqual(buffer.count, 60 * 60 * 4)
        let centerIdx = (30 * 60 + 30) * 4
        XCTAssertEqual(buffer[centerIdx + 1], 255) // Green
    }
}
