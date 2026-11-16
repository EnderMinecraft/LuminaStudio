import XCTest
@testable import EditorCore

final class BlendMathTests: XCTestCase {
    func testNormalBlend() {
        let b = (r: 0.2, g: 0.4, b: 0.6)
        let s = (r: 0.8, g: 0.1, b: 0.9)
        let res = LuminaBlendMode.normal.blend(backdrop: b, source: s)
        XCTAssertEqual(res.r, 0.8, accuracy: 1e-4)
        XCTAssertEqual(res.g, 0.1, accuracy: 1e-4)
        XCTAssertEqual(res.b, 0.9, accuracy: 1e-4)
    }
    
    func testMultiplyBlend() {
        let b = (r: 0.5, g: 0.8, b: 0.2)
        let s = (r: 0.5, g: 0.5, b: 0.5)
        let res = LuminaBlendMode.multiply.blend(backdrop: b, source: s)
        XCTAssertEqual(res.r, 0.25, accuracy: 1e-4)
        XCTAssertEqual(res.g, 0.40, accuracy: 1e-4)
        XCTAssertEqual(res.b, 0.10, accuracy: 1e-4)
    }
    
    func testScreenBlend() {
        let b = (r: 0.5, g: 0.0, b: 1.0)
        let s = (r: 0.5, g: 0.0, b: 0.5)
        let res = LuminaBlendMode.screen.blend(backdrop: b, source: s)
        // 1 - (1-0.5)*(1-0.5) = 0.75
        XCTAssertEqual(res.r, 0.75, accuracy: 1e-4)
        XCTAssertEqual(res.g, 0.0, accuracy: 1e-4)
        XCTAssertEqual(res.b, 1.0, accuracy: 1e-4)
    }
    
    func testDifferenceBlend() {
        let b = (r: 0.3, g: 0.9, b: 0.5)
        let s = (r: 0.8, g: 0.2, b: 0.5)
        let res = LuminaBlendMode.difference.blend(backdrop: b, source: s)
        XCTAssertEqual(res.r, 0.5, accuracy: 1e-4)
        XCTAssertEqual(res.g, 0.7, accuracy: 1e-4)
        XCTAssertEqual(res.b, 0.0, accuracy: 1e-4)
    }
    
    func testExclusionBlend() {
        let b = (r: 0.3, g: 0.5, b: 0.0)
        let s = (r: 0.7, g: 0.5, b: 1.0)
        let res = LuminaBlendMode.exclusion.blend(backdrop: b, source: s)
        // b + s - 2 * b * s
        // r: 0.3 + 0.7 - 2 * 0.21 = 1.0 - 0.42 = 0.58
        XCTAssertEqual(res.r, 0.58, accuracy: 1e-4)
        // g: 0.5 + 0.5 - 2 * 0.25 = 1.0 - 0.5 = 0.5
        XCTAssertEqual(res.g, 0.50, accuracy: 1e-4)
        // b: 0.0 + 1.0 - 0 = 1.0
        XCTAssertEqual(res.b, 1.00, accuracy: 1e-4)
    }
    
    func testDarkenAndLighten() {
        let b = (r: 0.4, g: 0.8, b: 0.1)
        let s = (r: 0.7, g: 0.2, b: 0.9)
        let darken = LuminaBlendMode.darken.blend(backdrop: b, source: s)
        XCTAssertEqual(darken.r, 0.4, accuracy: 1e-4)
        XCTAssertEqual(darken.g, 0.2, accuracy: 1e-4)
        XCTAssertEqual(darken.b, 0.1, accuracy: 1e-4)
        
        let lighten = LuminaBlendMode.lighten.blend(backdrop: b, source: s)
        XCTAssertEqual(lighten.r, 0.7, accuracy: 1e-4)
        XCTAssertEqual(lighten.g, 0.8, accuracy: 1e-4)
        XCTAssertEqual(lighten.b, 0.9, accuracy: 1e-4)
    }
}
