import XCTest
import CoreGraphics
@testable import EditorCore

final class TransformAndCropTests: XCTestCase {
    func testTransformSnapping() {
        let engine = TransformEngine.shared
        let layerSize = CGSize(width: 100, height: 100)
        let canvasSize = CGSize(width: 1000, height: 1000)
        
        // Canvas center is (500, 500). Layer center is translation + (50, 50).
        // If translation is (448, 448), layer center is (498, 498), within 8pt of 500 -> snaps to 450!
        let (snapped, guides) = engine.snap(
            translation: CGPoint(x: 448, y: 448),
            layerSize: layerSize,
            canvasSize: canvasSize
        )
        XCTAssertEqual(snapped.x, 450.0)
        XCTAssertEqual(snapped.y, 450.0)
        XCTAssertEqual(guides.count, 2)
    }
    
    func testRotationSnapping() {
        let engine = TransformEngine.shared
        // 88 degrees in radians = 1.53588. pi/2 = 1.57079. Diff is ~0.035 < 0.087 threshold.
        let snapped = engine.snapRotation(1.53588)
        XCTAssertEqual(snapped, .pi / 2.0, accuracy: 1e-4)
    }
    
    func testCropRuleOfThirdsLines() {
        let config = CropConfiguration(cropRect: CGRect(x: 0, y: 0, width: 300, height: 600))
        let (verts, horizs) = config.ruleOfThirdsLines
        XCTAssertEqual(verts.0, 100.0)
        XCTAssertEqual(verts.1, 200.0)
        XCTAssertEqual(horizs.0, 200.0)
        XCTAssertEqual(horizs.1, 400.0)
    }
    
    func testCropExecution() {
        let doc = LuminaDocument(configuration: CanvasConfiguration(width: 500, height: 500))
        let cropRect = CGRect(x: 50, y: 50, width: 200, height: 200)
        CropEngine.shared.applyCrop(to: doc, cropRect: cropRect)
        
        XCTAssertEqual(doc.configuration.width, 200)
        XCTAssertEqual(doc.configuration.height, 200)
        XCTAssertEqual(doc.layers.first?.pixelWidth, 200)
        XCTAssertEqual(doc.layers.first?.pixelHeight, 200)
    }
}
