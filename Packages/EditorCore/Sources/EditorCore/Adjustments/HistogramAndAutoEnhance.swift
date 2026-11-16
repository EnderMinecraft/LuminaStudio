import Foundation
import CoreGraphics

public struct HistogramData: Sendable, Equatable {
    public var redBins: [Int]
    public var greenBins: [Int]
    public var blueBins: [Int]
    public var luminanceBins: [Int]
    public var maxBinValue: Int
    
    public init() {
        self.redBins = [Int](repeating: 0, count: 256)
        self.greenBins = [Int](repeating: 0, count: 256)
        self.blueBins = [Int](repeating: 0, count: 256)
        self.luminanceBins = [Int](repeating: 0, count: 256)
        self.maxBinValue = 1
    }
}

public final class HistogramEngine: Sendable {
    public static let shared = HistogramEngine()
    
    public init() {}
    
    public func computeHistogram(from buffer: [UInt8], count: Int) -> HistogramData {
        var result = HistogramData()
        var maxVal = 1
        
        for i in 0..<count {
            let idx = i * 4
            let r = Int(buffer[idx])
            let g = Int(buffer[idx + 1])
            let b = Int(buffer[idx + 2])
            let lum = (r * 77 + g * 150 + b * 29) >> 8 // Fast integer Rec. 601 luminance
            
            result.redBins[r] += 1
            result.greenBins[g] += 1
            result.blueBins[b] += 1
            result.luminanceBins[lum] += 1
            
            maxVal = max(maxVal, max(result.redBins[r], max(result.greenBins[g], result.blueBins[b])))
        }
        
        result.maxBinValue = maxVal
        return result
    }
}

// MARK: - On-Device Auto Enhance

public struct AutoEnhanceResult: Sendable {
    public let levels: LevelsData
    public let vibrance: VibranceData
    public let brightnessContrast: BrightnessContrastData
}

public final class AutoEnhanceEngine: Sendable {
    public static let shared = AutoEnhanceEngine()
    
    public init() {}
    
    public func analyzeAndEnhance(from buffer: [UInt8], count: Int) -> AutoEnhanceResult {
        let histogram = HistogramEngine.shared.computeHistogram(from: buffer, count: count)
        
        let totalPixels = max(1, count)
        let lowThreshold = Int(Double(totalPixels) * 0.005) // 0.5% percentile
        let highThreshold = Int(Double(totalPixels) * 0.995) // 99.5% percentile
        
        var cumulative = 0
        var autoBlackPoint = 0.0
        var autoWhitePoint = 1.0
        
        for i in 0..<256 {
            cumulative += histogram.luminanceBins[i]
            if cumulative >= lowThreshold && autoBlackPoint == 0.0 {
                autoBlackPoint = Double(i) / 255.0
            }
            if cumulative >= highThreshold {
                autoWhitePoint = Double(i) / 255.0
                break
            }
        }
        
        let levels = LevelsData(
            blackPoint: min(0.2, autoBlackPoint),
            midtoneGamma: 1.05,
            whitePoint: max(0.8, autoWhitePoint)
        )
        let vibrance = VibranceData(vibrance: 0.15, saturation: 0.05)
        let brightnessContrast = BrightnessContrastData(brightness: 0.02, contrast: 0.08)
        
        return AutoEnhanceResult(
            levels: levels,
            vibrance: vibrance,
            brightnessContrast: brightnessContrast
        )
    }
}

// MARK: - Clone Stamp Engine

public final class CloneStampEngine: Sendable {
    public static let shared = CloneStampEngine()
    
    public init() {}
    
    public func stamp(
        sourceCenter: CGPoint,
        targetCenter: CGPoint,
        radius: CGFloat,
        hardness: Double,
        opacity: Double,
        sourceBuffer: [UInt8],
        targetBuffer: inout [UInt8],
        width: Int,
        height: Int
    ) {
        let r = Double(radius)
        guard r > 0 else { return }
        
        let dx = targetCenter.x - sourceCenter.x
        let dy = targetCenter.y - sourceCenter.y
        
        let minX = max(0, Int(floor(targetCenter.x - radius)))
        let maxX = min(width - 1, Int(ceil(targetCenter.x + radius)))
        let minY = max(0, Int(floor(targetCenter.y - radius)))
        let maxY = min(height - 1, Int(ceil(targetCenter.y + radius)))
        
        let hardnessThreshold = r * hardness
        
        for y in minY...maxY {
            let tdy = Double(y) - Double(targetCenter.y)
            let tdy2 = tdy * tdy
            for x in minX...maxX {
                let tdx = Double(x) - Double(targetCenter.x)
                let dist = sqrt(tdx * tdx + tdy2)
                guard dist <= r else { continue }
                
                var falloff: Double = 1.0
                if hardness < 1.0 && dist > hardnessThreshold {
                    let t = (dist - hardnessThreshold) / (r - hardnessThreshold)
                    falloff = 0.5 * (1.0 + cos(.pi * t))
                }
                let stampAlpha = opacity * falloff
                
                let sx = Int(round(Double(x) - Double(dx)))
                let sy = Int(round(Double(y) - Double(dy)))
                guard sx >= 0, sx < width, sy >= 0, sy < height else { continue }
                
                let sIdx = (sy * width + sx) * 4
                let dIdx = (y * width + x) * 4
                
                let sR = Double(sourceBuffer[sIdx])
                let sG = Double(sourceBuffer[sIdx + 1])
                let sB = Double(sourceBuffer[sIdx + 2])
                let sA = Double(sourceBuffer[sIdx + 3]) / 255.0 * stampAlpha
                
                let dR = Double(targetBuffer[dIdx])
                let dG = Double(targetBuffer[dIdx + 1])
                let dB = Double(targetBuffer[dIdx + 2])
                let dA = Double(targetBuffer[dIdx + 3]) / 255.0
                
                let outA = sA + dA * (1.0 - sA)
                if outA > 0.0 {
                    let outR = (sR * sA + dR * dA * (1.0 - sA)) / outA
                    let outG = (sG * sA + dG * dA * (1.0 - sA)) / outA
                    let outB = (sB * sA + dB * dA * (1.0 - sA)) / outA
                    
                    targetBuffer[dIdx] = UInt8(max(0, min(255, round(outR))))
                    targetBuffer[dIdx + 1] = UInt8(max(0, min(255, round(outG))))
                    targetBuffer[dIdx + 2] = UInt8(max(0, min(255, round(outB))))
                    targetBuffer[dIdx + 3] = UInt8(max(0, min(255, round(outA * 255.0))))
                }
            }
        }
    }
}
