import XCTest
@testable import EditorCore

final class AdjustmentMathTests: XCTestCase {
    func testMonotoneCubicSplineEndpoints() {
        let pts = [
            SplinePoint(x: 0.0, y: 0.0),
            SplinePoint(x: 0.5, y: 0.8),
            SplinePoint(x: 1.0, y: 1.0)
        ]
        let spline = MonotoneCubicSpline(points: pts)
        
        XCTAssertEqual(spline.evaluate(at: 0.0), 0.0, accuracy: 1e-4)
        XCTAssertEqual(spline.evaluate(at: 0.5), 0.8, accuracy: 1e-4)
        XCTAssertEqual(spline.evaluate(at: 1.0), 1.0, accuracy: 1e-4)
        
        // Monotonicity: intermediate values should be monotonically non-decreasing
        var prev = 0.0
        for i in 1...50 {
            let x = Double(i) / 50.0
            let y = spline.evaluate(at: x)
            XCTAssertGreaterThanOrEqual(y, prev - 1e-6)
            prev = y
        }
    }
    
    func testSplineLUTGeneration() {
        let pts = [SplinePoint(x: 0, y: 0), SplinePoint(x: 1, y: 1)]
        let spline = MonotoneCubicSpline(points: pts)
        let lut = spline.generate256LUT()
        
        XCTAssertEqual(lut.count, 256)
        XCTAssertEqual(lut[0], 0)
        XCTAssertEqual(lut[128], 128)
        XCTAssertEqual(lut[255], 255)
    }
    
    func testBrightnessContrastMapping() {
        var buffer: [UInt8] = [128, 128, 128, 255]
        let data = BrightnessContrastData(brightness: 0.1, contrast: 0.0)
        AdjustmentEngine.shared.applyAdjustments(parameters: .brightnessContrast(data), buffer: &buffer, width: 1, height: 1)
        
        // 128 / 255 = ~0.502. + 0.1 brightness = ~0.602 -> ~153
        XCTAssertGreaterThan(buffer[0], 128)
    }
    
    func testExposureMapping() {
        var buffer: [UInt8] = [100, 100, 100, 255]
        let data = ExposureData(exposureEV: 1.0) // 1 EV = 2x brighter
        AdjustmentEngine.shared.applyAdjustments(parameters: .exposure(data), buffer: &buffer, width: 1, height: 1)
        
        XCTAssertEqual(buffer[0], 200)
    }
}
