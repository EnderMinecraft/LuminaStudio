import Foundation
import CoreGraphics

// MARK: - Monotone Cubic Spline (Fritsch-Carlson)

public struct MonotoneCubicSpline: Sendable {
    private let xs: [Double]
    private let ys: [Double]
    private let ms: [Double]
    
    public init(points: [SplinePoint]) {
        let sorted = points.sorted { $0.x < $1.x }
        var cleanPoints: [SplinePoint] = []
        for pt in sorted {
            if let last = cleanPoints.last, abs(last.x - pt.x) < 1e-5 {
                continue // avoid duplicate X
            }
            cleanPoints.append(pt)
        }
        if cleanPoints.isEmpty {
            cleanPoints = [SplinePoint(x: 0, y: 0), SplinePoint(x: 1, y: 1)]
        } else if cleanPoints.count == 1 {
            cleanPoints = [SplinePoint(x: 0, y: cleanPoints[0].y), SplinePoint(x: 1, y: cleanPoints[0].y)]
        }
        
        let n = cleanPoints.count
        var xArr = cleanPoints.map { $0.x }
        var yArr = cleanPoints.map { $0.y }
        
        // Secant slopes
        var deltas = [Double](repeating: 0, count: n - 1)
        for i in 0..<(n - 1) {
            deltas[i] = (yArr[i + 1] - yArr[i]) / (xArr[i + 1] - xArr[i])
        }
        
        // Initial tangent estimates (averages)
        var mArr = [Double](repeating: 0, count: n)
        mArr[0] = deltas[0]
        for i in 1..<(n - 1) {
            mArr[i] = (deltas[i - 1] + deltas[i]) / 2.0
        }
        mArr[n - 1] = deltas[n - 2]
        
        // Fritsch-Carlson Monotonicity adjustments
        for i in 0..<(n - 1) {
            let delta = deltas[i]
            if abs(delta) < 1e-9 {
                mArr[i] = 0.0
                mArr[i + 1] = 0.0
            } else {
                let alpha = mArr[i] / delta
                let beta = mArr[i + 1] / delta
                let dist = alpha * alpha + beta * beta
                if dist > 9.0 {
                    let tau = 3.0 / sqrt(dist)
                    mArr[i] = tau * alpha * delta
                    mArr[i + 1] = tau * beta * delta
                }
            }
        }
        
        self.xs = xArr
        self.ys = yArr
        self.ms = mArr
    }
    
    public func evaluate(at x: Double) -> Double {
        let xClamped = max(0.0, min(1.0, x))
        if xClamped <= xs.first! { return ys.first! }
        if xClamped >= xs.last! { return ys.last! }
        
        // Binary search for segment
        var low = 0
        var high = xs.count - 1
        while low <= high {
            let mid = (low + high) / 2
            if xs[mid] <= xClamped {
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        let i = max(0, min(xs.count - 2, high))
        
        let h = xs[i + 1] - xs[i]
        let t = (xClamped - xs[i]) / h
        let t2 = t * t
        let t3 = t2 * t
        
        let h00 = 2.0 * t3 - 3.0 * t2 + 1.0
        let h10 = t3 - 2.0 * t2 + t
        let h01 = -2.0 * t3 + 3.0 * t2
        let h11 = t3 - t2
        
        let y = h00 * ys[i] + h10 * h * ms[i] + h01 * ys[i + 1] + h11 * h * ms[i + 1]
        return max(0.0, min(1.0, y))
    }
    
    public func generate256LUT() -> [UInt8] {
        var lut = [UInt8](repeating: 0, count: 256)
        for i in 0..<256 {
            let input = Double(i) / 255.0
            let output = evaluate(at: input)
            lut[i] = UInt8(round(output * 255.0))
        }
        return lut
    }
}

// MARK: - Adjustment Engine

public final class AdjustmentEngine: Sendable {
    public static let shared = AdjustmentEngine()
    
    public init() {}
    
    public func applyAdjustments(
        parameters: AdjustmentParameters,
        buffer: inout [UInt8],
        width: Int,
        height: Int
    ) {
        switch parameters {
        case .brightnessContrast(let data):
            applyBrightnessContrast(data: data, buffer: &buffer, count: width * height)
        case .exposure(let data):
            applyExposure(data: data, buffer: &buffer, count: width * height)
        case .levels(let data):
            applyLevels(data: data, buffer: &buffer, count: width * height)
        case .curves(let data):
            applyCurves(data: data, buffer: &buffer, count: width * height)
        case .hueSaturation(let data):
            applyHueSaturation(data: data, buffer: &buffer, count: width * height)
        case .vibrance(let data):
            applyVibrance(data: data, buffer: &buffer, count: width * height)
        case .colorBalance(let data):
            applyColorBalance(data: data, buffer: &buffer, count: width * height)
        case .temperatureTint(let data):
            applyTemperatureTint(data: data, buffer: &buffer, count: width * height)
        case .blackAndWhite(let data):
            applyBlackAndWhite(data: data, buffer: &buffer, count: width * height)
        case .vignette(let data):
            applyVignette(data: data, buffer: &buffer, width: width, height: height)
        }
    }
    
    // MARK: - Filter Math Implementations
    
    private func applyBrightnessContrast(data: BrightnessContrastData, buffer: inout [UInt8], count: Int) {
        var lut = [UInt8](repeating: 0, count: 256)
        let contrastFactor = (1.0 + data.contrast)
        for i in 0..<256 {
            var v = (Double(i) / 255.0 - 0.5) * contrastFactor + 0.5 + data.brightness
            v = max(0.0, min(1.0, v))
            lut[i] = UInt8(round(v * 255.0))
        }
        for i in 0..<count {
            let idx = i * 4
            buffer[idx] = lut[Int(buffer[idx])]
            buffer[idx + 1] = lut[Int(buffer[idx + 1])]
            buffer[idx + 2] = lut[Int(buffer[idx + 2])]
        }
    }
    
    private func applyExposure(data: ExposureData, buffer: inout [UInt8], count: Int) {
        let multiplier = pow(2.0, data.exposureEV)
        var lut = [UInt8](repeating: 0, count: 256)
        for i in 0..<256 {
            let v = min(1.0, (Double(i) / 255.0) * multiplier)
            lut[i] = UInt8(round(v * 255.0))
        }
        for i in 0..<count {
            let idx = i * 4
            buffer[idx] = lut[Int(buffer[idx])]
            buffer[idx + 1] = lut[Int(buffer[idx + 1])]
            buffer[idx + 2] = lut[Int(buffer[idx + 2])]
        }
    }
    
    private func applyLevels(data: LevelsData, buffer: inout [UInt8], count: Int) {
        var lut = [UInt8](repeating: 0, count: 256)
        let inRange = max(1e-4, data.whitePoint - data.blackPoint)
        let invGamma = 1.0 / data.midtoneGamma
        let outRange = data.outputWhite - data.outputBlack
        
        for i in 0..<256 {
            let input = Double(i) / 255.0
            let normalized = max(0.0, min(1.0, (input - data.blackPoint) / inRange))
            let gammaAdjusted = pow(normalized, invGamma)
            let output = data.outputBlack + gammaAdjusted * outRange
            lut[i] = UInt8(round(max(0.0, min(1.0, output)) * 255.0))
        }
        for i in 0..<count {
            let idx = i * 4
            buffer[idx] = lut[Int(buffer[idx])]
            buffer[idx + 1] = lut[Int(buffer[idx + 1])]
            buffer[idx + 2] = lut[Int(buffer[idx + 2])]
        }
    }
    
    private func applyCurves(data: CurvesData, buffer: inout [UInt8], count: Int) {
        let rgbLut = MonotoneCubicSpline(points: data.rgbPoints).generate256LUT()
        let rLut = MonotoneCubicSpline(points: data.redPoints).generate256LUT()
        let gLut = MonotoneCubicSpline(points: data.greenPoints).generate256LUT()
        let bLut = MonotoneCubicSpline(points: data.bluePoints).generate256LUT()
        
        for i in 0..<count {
            let idx = i * 4
            let r = rLut[Int(rgbLut[Int(buffer[idx])])]
            let g = gLut[Int(rgbLut[Int(buffer[idx + 1])])]
            let b = bLut[Int(rgbLut[Int(buffer[idx + 2])])]
            buffer[idx] = r
            buffer[idx + 1] = g
            buffer[idx + 2] = b
        }
    }
    
    private func applyHueSaturation(data: HueSaturationData, buffer: inout [UInt8], count: Int) {
        let satFactor = 1.0 + data.saturation
        let lightFactor = data.lightness
        let hueShift = data.hueShiftDegrees
        
        for i in 0..<count {
            let idx = i * 4
            var r = Double(buffer[idx]) / 255.0
            var g = Double(buffer[idx + 1]) / 255.0
            var b = Double(buffer[idx + 2]) / 255.0
            
            // RGB -> HSL
            let maxC = max(r, max(g, b))
            let minC = min(r, min(g, b))
            let delta = maxC - minC
            var l = (maxC + minC) / 2.0
            var s = 0.0
            var h = 0.0
            
            if delta > 1e-5 {
                s = l > 0.5 ? delta / (2.0 - maxC - minC) : delta / (maxC + minC)
                if maxC == r {
                    h = ((g - b) / delta) + (g < b ? 6.0 : 0.0)
                } else if maxC == g {
                    h = ((b - r) / delta) + 2.0
                } else {
                    h = ((r - g) / delta) + 4.0
                }
                h *= 60.0
            }
            
            // Adjust HSL
            h = (h + hueShift).truncatingRemainder(dividingBy: 360.0)
            if h < 0 { h += 360.0 }
            s = max(0.0, min(1.0, s * satFactor))
            if lightFactor > 0 {
                l += (1.0 - l) * lightFactor
            } else if lightFactor < 0 {
                l += l * lightFactor
            }
            l = max(0.0, min(1.0, l))
            
            // HSL -> RGB
            let (nr, ng, nb) = hslToRgb(h: h / 360.0, s: s, l: l)
            buffer[idx] = UInt8(round(nr * 255.0))
            buffer[idx + 1] = UInt8(round(ng * 255.0))
            buffer[idx + 2] = UInt8(round(nb * 255.0))
        }
    }
    
    private func applyVibrance(data: VibranceData, buffer: inout [UInt8], count: Int) {
        let vib = data.vibrance
        for i in 0..<count {
            let idx = i * 4
            let r = Double(buffer[idx]) / 255.0
            let g = Double(buffer[idx + 1]) / 255.0
            let b = Double(buffer[idx + 2]) / 255.0
            
            let maxC = max(r, max(g, b))
            let minC = min(r, min(g, b))
            let sat = maxC - minC
            let l = (maxC + minC) / 2.0
            
            // Boost lower saturated colors more than already saturated ones
            let boost = (1.0 - sat) * vib
            let newR = r + (r - l) * boost
            let newG = g + (g - l) * boost
            let newB = b + (b - l) * boost
            
            buffer[idx] = UInt8(max(0, min(255, round(newR * 255.0))))
            buffer[idx + 1] = UInt8(max(0, min(255, round(newG * 255.0))))
            buffer[idx + 2] = UInt8(max(0, min(255, round(newB * 255.0))))
        }
    }
    
    private func applyColorBalance(data: ColorBalanceData, buffer: inout [UInt8], count: Int) {
        for i in 0..<count {
            let idx = i * 4
            var r = Double(buffer[idx]) + data.cyanRed * 30.0
            var g = Double(buffer[idx + 1]) + data.magentaGreen * 30.0
            var b = Double(buffer[idx + 2]) + data.yellowBlue * 30.0
            buffer[idx] = UInt8(max(0, min(255, round(r))))
            buffer[idx + 1] = UInt8(max(0, min(255, round(g))))
            buffer[idx + 2] = UInt8(max(0, min(255, round(b))))
        }
    }
    
    private func applyTemperatureTint(data: TemperatureTintData, buffer: inout [UInt8], count: Int) {
        let tempOffset = data.temperature * 35.0
        let tintOffset = data.tint * 25.0
        for i in 0..<count {
            let idx = i * 4
            let r = Double(buffer[idx]) + tempOffset
            let g = Double(buffer[idx + 1]) - tintOffset
            let b = Double(buffer[idx + 2]) - tempOffset
            buffer[idx] = UInt8(max(0, min(255, round(r))))
            buffer[idx + 1] = UInt8(max(0, min(255, round(g))))
            buffer[idx + 2] = UInt8(max(0, min(255, round(b))))
        }
    }
    
    private func applyBlackAndWhite(data: BlackAndWhiteData, buffer: inout [UInt8], count: Int) {
        let total = max(1e-4, data.redWeight + data.greenWeight + data.blueWeight)
        let rw = data.redWeight / total
        let gw = data.greenWeight / total
        let bw = data.blueWeight / total
        for i in 0..<count {
            let idx = i * 4
            let gray = Double(buffer[idx]) * rw + Double(buffer[idx + 1]) * gw + Double(buffer[idx + 2]) * bw
            let byte = UInt8(max(0, min(255, round(gray))))
            buffer[idx] = byte
            buffer[idx + 1] = byte
            buffer[idx + 2] = byte
        }
    }
    
    private func applyVignette(data: VignetteData, buffer: inout [UInt8], width: Int, height: Int) {
        let cx = Double(width) / 2.0
        let cy = Double(height) / 2.0
        let maxDist = sqrt(cx * cx + cy * cy) * data.radius
        let softness = max(0.01, data.softness)
        let innerDist = maxDist * (1.0 - softness)
        
        for y in 0..<height {
            let dy = Double(y) - cy
            let dy2 = dy * dy
            for x in 0..<width {
                let dx = Double(x) - cx
                let dist = sqrt(dx * dx + dy2)
                if dist > innerDist {
                    let factor = min(1.0, (dist - innerDist) / (maxDist - innerDist))
                    let darkFactor = 1.0 - factor * data.intensity
                    let idx = (y * width + x) * 4
                    buffer[idx] = UInt8(round(Double(buffer[idx]) * darkFactor))
                    buffer[idx + 1] = UInt8(round(Double(buffer[idx + 1]) * darkFactor))
                    buffer[idx + 2] = UInt8(round(Double(buffer[idx + 2]) * darkFactor))
                }
            }
        }
    }
    
    private func hslToRgb(h: Double, s: Double, l: Double) -> (Double, Double, Double) {
        if s < 1e-6 { return (l, l, l) }
        let q = l < 0.5 ? l * (1.0 + s) : l + s - l * s
        let p = 2.0 * l - q
        func hue2rgb(_ p: Double, _ q: Double, _ t: Double) -> Double {
            var temp = t
            if temp < 0.0 { temp += 1.0 }
            if temp > 1.0 { temp -= 1.0 }
            if temp < 1.0 / 6.0 { return p + (q - p) * 6.0 * temp }
            if temp < 1.0 / 2.0 { return q }
            if temp < 2.0 / 3.0 { return p + (q - p) * (2.0 / 3.0 - temp) * 6.0 }
            return p
        }
        return (hue2rgb(p, q, h + 1.0 / 3.0), hue2rgb(p, q, h), hue2rgb(p, q, h - 1.0 / 3.0))
    }
}
