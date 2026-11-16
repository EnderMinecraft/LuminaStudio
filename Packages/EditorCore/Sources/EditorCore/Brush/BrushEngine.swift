import Foundation
import CoreGraphics

public final class BrushEngine: @unchecked Sendable {
    public static let shared = BrushEngine()
    
    public init() {}
    
    // MARK: - Catmull-Rom Spline Interpolation
    
    public func interpolatePoints(
        p0: CGPoint,
        p1: CGPoint,
        p2: CGPoint,
        p3: CGPoint,
        steps: Int = 8
    ) -> [CGPoint] {
        var result: [CGPoint] = []
        result.reserveCapacity(steps)
        
        for i in 0...steps {
            let t = Double(i) / Double(steps)
            let t2 = t * t
            let t3 = t2 * t
            
            let x = 0.5 * ((2.0 * p1.x) +
                           (-p0.x + p2.x) * t +
                           (2.0 * p0.x - 5.0 * p1.x + 4.0 * p2.x - p3.x) * t2 +
                           (-p0.x + 3.0 * p1.x - 3.0 * p2.x + p3.x) * t3)
            
            let y = 0.5 * ((2.0 * p1.y) +
                           (-p0.y + p2.y) * t +
                           (2.0 * p0.y - 5.0 * p1.y + 4.0 * p2.y - p3.y) * t2 +
                           (-p0.y + 3.0 * p1.y - 3.0 * p2.y + p3.y) * t3)
            
            result.append(CGPoint(x: x, y: y))
        }
        return result
    }
    
    // MARK: - Stamp Painting
    
    /// Renders a circular brush stamp into an RGBA8 buffer
    public func paintStamp(
        at center: CGPoint,
        preset: BrushPreset,
        color: (r: UInt8, g: UInt8, b: UInt8, a: UInt8),
        pressure: Double,
        buffer: inout [UInt8],
        width: Int,
        height: Int
    ) {
        let sizeMultiplier = preset.sizeWithPressure ? pressure : 1.0
        let effectiveRadius = (preset.size * CGFloat(sizeMultiplier)) / 2.0
        guard effectiveRadius >= 0.5 else { return }
        
        let opacityMultiplier = preset.opacityWithPressure ? pressure : 1.0
        let stampAlpha = preset.opacity * preset.flow * opacityMultiplier
        let hardness = preset.hardness
        
        let minX = max(0, Int(floor(center.x - effectiveRadius)))
        let maxX = min(width - 1, Int(ceil(center.x + effectiveRadius)))
        let minY = max(0, Int(floor(center.y - effectiveRadius)))
        let maxY = min(height - 1, Int(ceil(center.y + effectiveRadius)))
        
        let rDouble = Double(effectiveRadius)
        let hardnessThreshold = rDouble * hardness
        
        for y in minY...maxY {
            let dy = Double(y) - Double(center.y)
            let dy2 = dy * dy
            for x in minX...maxX {
                let dx = Double(x) - Double(center.x)
                let dist = sqrt(dx * dx + dy2)
                guard dist <= rDouble else { continue }
                
                var falloff: Double = 1.0
                if hardness < 1.0 && dist > hardnessThreshold {
                    let t = (dist - hardnessThreshold) / (rDouble - hardnessThreshold)
                    // Cosine smooth decay
                    falloff = 0.5 * (1.0 + cos(.pi * t))
                }
                
                let pixelIndex = (y * width + x) * 4
                let alphaFactor = stampAlpha * falloff
                
                if preset.isEraser {
                    // Erase: reduce alpha
                    let currentA = Double(buffer[pixelIndex + 3]) / 255.0
                    let newA = max(0.0, currentA * (1.0 - alphaFactor))
                    buffer[pixelIndex + 3] = UInt8(newA * 255.0)
                } else {
                    // Paint color: alpha blend onto destination
                    let sR = Double(color.r)
                    let sG = Double(color.g)
                    let sB = Double(color.b)
                    let sA = Double(color.a) / 255.0 * alphaFactor
                    
                    let dR = Double(buffer[pixelIndex])
                    let dG = Double(buffer[pixelIndex + 1])
                    let dB = Double(buffer[pixelIndex + 2])
                    let dA = Double(buffer[pixelIndex + 3]) / 255.0
                    
                    let outA = sA + dA * (1.0 - sA)
                    if outA > 0.0 {
                        let outR = (sR * sA + dR * dA * (1.0 - sA)) / outA
                        let outG = (sG * sA + dG * dA * (1.0 - sA)) / outA
                        let outB = (sB * sA + dB * dA * (1.0 - sA)) / outA
                        
                        buffer[pixelIndex] = UInt8(max(0, min(255, outR)))
                        buffer[pixelIndex + 1] = UInt8(max(0, min(255, outG)))
                        buffer[pixelIndex + 2] = UInt8(max(0, min(255, outB)))
                        buffer[pixelIndex + 3] = UInt8(max(0, min(255, outA * 255.0)))
                    }
                }
            }
        }
    }
    
    /// Renders a stamp onto a single-channel 8-bit mask (used for layer masks and cutout refine)
    public func paintMaskStamp(
        at center: CGPoint,
        preset: BrushPreset,
        value: UInt8, // 255 to reveal/restore, 0 to hide/erase
        pressure: Double,
        maskData: inout Data,
        width: Int,
        height: Int
    ) {
        let sizeMultiplier = preset.sizeWithPressure ? pressure : 1.0
        let effectiveRadius = (preset.size * CGFloat(sizeMultiplier)) / 2.0
        guard effectiveRadius >= 0.5 else { return }
        
        let opacityMultiplier = preset.opacityWithPressure ? pressure : 1.0
        let stampAlpha = preset.opacity * preset.flow * opacityMultiplier
        let hardness = preset.hardness
        
        let minX = max(0, Int(floor(center.x - effectiveRadius)))
        let maxX = min(width - 1, Int(ceil(center.x + effectiveRadius)))
        let minY = max(0, Int(floor(center.y - effectiveRadius)))
        let maxY = min(height - 1, Int(ceil(center.y + effectiveRadius)))
        
        let rDouble = Double(effectiveRadius)
        let hardnessThreshold = rDouble * hardness
        
        maskData.withUnsafeMutableBytes { ptr in
            guard let bytes = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
            
            for y in minY...maxY {
                let dy = Double(y) - Double(center.y)
                let dy2 = dy * dy
                for x in minX...maxX {
                    let dx = Double(x) - Double(center.x)
                    let dist = sqrt(dx * dx + dy2)
                    guard dist <= rDouble else { continue }
                    
                    var falloff: Double = 1.0
                    if hardness < 1.0 && dist > hardnessThreshold {
                        let t = (dist - hardnessThreshold) / (rDouble - hardnessThreshold)
                        falloff = 0.5 * (1.0 + cos(.pi * t))
                    }
                    
                    let index = y * width + x
                    let currentVal = Double(bytes[index])
                    let targetVal = Double(value)
                    let factor = stampAlpha * falloff
                    let newVal = currentVal + (targetVal - currentVal) * factor
                    bytes[index] = UInt8(max(0, min(255, round(newVal))))
                }
            }
        }
    }
}

public final class PaintStrokeCommand: Command, @unchecked Sendable {
    public let name: String
    public let estimatedMemoryBytes: Int
    private let layer: Layer
    private let previousData: Data
    private let newData: Data
    
    public init(layer: Layer, previousData: Data, newData: Data, isEraser: Bool = false) {
        self.layer = layer
        self.previousData = previousData
        self.newData = newData
        self.estimatedMemoryBytes = previousData.count
        self.name = isEraser ? "Eraser Stroke" : "Brush Stroke"
    }
    
    public func execute() async throws {
        layer.rawPixelData = newData
    }
    
    public func undo() async throws {
        layer.rawPixelData = previousData
    }
}
