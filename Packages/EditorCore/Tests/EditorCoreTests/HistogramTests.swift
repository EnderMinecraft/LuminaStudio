import XCTest
@testable import EditorCore

final class HistogramTests: XCTestCase {
    func testSolidColorHistogram() {
        let engine = HistogramEngine.shared
        // 100 pixels of pure solid blue (0, 0, 255, 255)
        var buffer: [UInt8] = []
        for _ in 0..<100 {
            buffer.append(contentsOf: [0, 0, 255, 255])
        }
        
        let hist = engine.computeHistogram(from: buffer, count: 100)
        XCTAssertEqual(hist.redBins[0], 100)
        XCTAssertEqual(hist.greenBins[0], 100)
        XCTAssertEqual(hist.blueBins[255], 100)
        XCTAssertEqual(hist.maxBinValue, 100)
    }
    
    func testAutoEnhanceDynamicRange() {
        let engine = AutoEnhanceEngine.shared
        // Muted low-contrast image between 50 and 150
        var buffer: [UInt8] = []
        for i in 0..<200 {
            let v = UInt8(50 + (i % 100))
            buffer.append(contentsOf: [v, v, v, 255])
        }
        
        let result = engine.analyzeAndEnhance(from: buffer, count: 200)
        XCTAssertGreaterThan(result.levels.blackPoint, 0.0)
        XCTAssertLessThan(result.levels.whitePoint, 1.0)
        XCTAssertGreaterThan(result.vibrance.vibrance, 0.0)
    }
}
