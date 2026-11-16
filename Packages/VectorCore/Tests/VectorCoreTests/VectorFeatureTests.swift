import XCTest
import CoreGraphics
@testable import VectorCore

final class VectorFeatureTests: XCTestCase {
    func testRDPPolylineSimplification() {
        // Collinear line with intermediate jitter within epsilon
        let points = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 10, y: 0.1),
            CGPoint(x: 20, y: -0.1),
            CGPoint(x: 30, y: 0),
            CGPoint(x: 100, y: 0)
        ]
        let simplified = CurveFitting.simplifyRDP(points: points, epsilon: 1.0)
        XCTAssertEqual(simplified.count, 2)
        XCTAssertEqual(simplified.first?.x, 0)
        XCTAssertEqual(simplified.last?.x, 100)
    }
    
    func testSchneiderCurveFitting() {
        // Arch-shaped points
        let points = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 25, y: 40),
            CGPoint(x: 50, y: 50),
            CGPoint(x: 75, y: 40),
            CGPoint(x: 100, y: 0)
        ]
        let segments = CurveFitting.fitCurve(points: points, maxError: 5.0)
        XCTAssertFalse(segments.isEmpty)
        XCTAssertEqual(segments.first?.p0.x, 0)
        XCTAssertEqual(segments.last?.p3.x, 100)
    }
    
    func testBooleanUnion() {
        let pA = BezierSubpath(isClosed: true, points: [
            AnchorPoint(position: CGPoint(x: 0, y: 0)),
            AnchorPoint(position: CGPoint(x: 50, y: 0)),
            AnchorPoint(position: CGPoint(x: 50, y: 50)),
            AnchorPoint(position: CGPoint(x: 0, y: 50))
        ])
        let pB = BezierSubpath(isClosed: true, points: [
            AnchorPoint(position: CGPoint(x: 25, y: 0)),
            AnchorPoint(position: CGPoint(x: 75, y: 0)),
            AnchorPoint(position: CGPoint(x: 75, y: 50)),
            AnchorPoint(position: CGPoint(x: 25, y: 50))
        ])
        
        let engine = VectorBooleanEngine.shared
        do {
            let result = try engine.perform(operation: .union, subject: [pA], clip: [pB])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.first?.isClosed == true)
        } catch {
            XCTFail("Boolean union failed: \(error)")
        }
    }
    
    func testSVGExportAndImport() {
        let rectNode = ParametricShapeNode(
            name: "Test Rect",
            kind: .rect,
            frame: CGRect(x: 10, y: 20, width: 200, height: 100),
            fillColorHex: "#FF0000"
        )
        let artboard = ArtboardNode(
            name: "Artboard 1",
            size: CGSize(width: 800, height: 600),
            children: [.parametric(rectNode)]
        )
        let doc = VectorDocument(title: "SVG Test", artboards: [artboard])
        
        let svg = VectorInterchange.shared.exportSVG(document: doc)
        XCTAssertTrue(svg.contains("<svg"))
        XCTAssertTrue(svg.contains("<rect"))
        XCTAssertTrue(svg.contains("width=\"800\""))
        
        let imported = VectorInterchange.shared.importSVG(xmlString: svg)
        XCTAssertEqual(imported.artboards.first?.size.width, 800)
        XCTAssertEqual(imported.artboards.first?.size.height, 600)
        XCTAssertEqual(imported.artboards.first?.children.count, 1)
    }
    
    func testArtboardRenderingProducesValidBuffer() {
        let starNode = ParametricShapeNode(
            name: "Star",
            kind: .star,
            frame: CGRect(x: 50, y: 50, width: 100, height: 100),
            fillColorHex: "#00FF00"
        )
        let artboard = ArtboardNode(
            size: CGSize(width: 200, height: 200),
            children: [.parametric(starNode)]
        )
        
        let (buffer, size) = VectorRenderEngine.shared.renderArtboard(artboard, scale: 1.0)
        XCTAssertEqual(size.width, 200)
        XCTAssertEqual(size.height, 200)
        XCTAssertEqual(buffer.count, 200 * 200 * 4)
        
        // Background was white (255, 255, 255, 255), so pixel 0 should be 255
        XCTAssertEqual(buffer[0], 255)
    }
    
    func testMooreNeighborTracing() async {
        let w = 64
        let h = 64
        var pixels = [UInt8](repeating: 255, count: w * h * 4)
        // Draw centered dark box
        for y in 20..<44 {
            for x in 20..<44 {
                let idx = (y * w + x) * 4
                pixels[idx] = 10
                pixels[idx + 1] = 10
                pixels[idx + 2] = 10
                pixels[idx + 3] = 255
            }
        }
        
        let tracer = ImageTracer.shared
        let subpaths = await tracer.traceImage(
            rgbaPixels: pixels,
            width: w,
            height: h,
            options: ImageTracer.TracingOptions(cornerTolerance: 1.0)
        )
        
        XCTAssertFalse(subpaths.isEmpty)
        XCTAssertTrue(subpaths.first?.isClosed == true)
        XCTAssertGreaterThanOrEqual(subpaths.first?.points.count ?? 0, 3)
    }
}
