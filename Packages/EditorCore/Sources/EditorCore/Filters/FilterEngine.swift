import Foundation
import CoreGraphics

public enum FilterType: String, CaseIterable, Sendable {
    case gaussianBlur = "Gaussian Blur"
    case motionBlur = "Motion Blur"
    case radialBlur = "Radial Blur"
    case pixelate = "Pixelate"
    case noise = "Add Noise"
    case unsharpMask = "Unsharp Mask"
    case chromaticAberration = "Chromatic Aberration"
    case liquify = "Liquify (Push Warp)"
}

public final class FilterEngine: @unchecked Sendable {
    public static let shared = FilterEngine()
    
    public init() {}
    
    // MARK: - Gaussian Blur (Separable)
    
    public func applyGaussianBlur(radius: Double, buffer: inout [UInt8], width: Int, height: Int) {
        let r = max(1, Int(round(radius)))
        guard r > 0 else { return }
        
        let sigma = max(0.5, radius / 2.0)
        let kernelSize = r * 2 + 1
        var kernel = [Double](repeating: 0, count: kernelSize)
        var sum = 0.0
        for i in -r...r {
            let v = exp(-Double(i * i) / (2.0 * sigma * sigma))
            kernel[i + r] = v
            sum += v
        }
        for i in 0..<kernelSize { kernel[i] /= sum }
        
        var temp = [UInt8](repeating: 0, count: width * height * 4)
        
        // Horizontal pass
        for y in 0..<height {
            let rowOffset = y * width
            for x in 0..<width {
                var accR = 0.0
                var accG = 0.0
                var accB = 0.0
                var accA = 0.0
                for k in -r...r {
                    let kx = max(0, min(width - 1, x + k))
                    let idx = (rowOffset + kx) * 4
                    let w = kernel[k + r]
                    accR += Double(buffer[idx]) * w
                    accG += Double(buffer[idx + 1]) * w
                    accB += Double(buffer[idx + 2]) * w
                    accA += Double(buffer[idx + 3]) * w
                }
                let outIdx = (rowOffset + x) * 4
                temp[outIdx] = UInt8(round(accR))
                temp[outIdx + 1] = UInt8(round(accG))
                temp[outIdx + 2] = UInt8(round(accB))
                temp[outIdx + 3] = UInt8(round(accA))
            }
        }
        
        // Vertical pass
        for x in 0..<width {
            for y in 0..<height {
                var accR = 0.0
                var accG = 0.0
                var accB = 0.0
                var accA = 0.0
                for k in -r...r {
                    let ky = max(0, min(height - 1, y + k))
                    let idx = (ky * width + x) * 4
                    let w = kernel[k + r]
                    accR += Double(temp[idx]) * w
                    accG += Double(temp[idx + 1]) * w
                    accB += Double(temp[idx + 2]) * w
                    accA += Double(temp[idx + 3]) * w
                }
                let outIdx = (y * width + x) * 4
                buffer[outIdx] = UInt8(round(accR))
                buffer[outIdx + 1] = UInt8(round(accG))
                buffer[outIdx + 2] = UInt8(round(accB))
                buffer[outIdx + 3] = UInt8(round(accA))
            }
        }
    }
    
    // MARK: - Pixelate
    
    public func applyPixelate(blockSize: Int, buffer: inout [UInt8], width: Int, height: Int) {
        let b = max(2, blockSize)
        for by in stride(from: 0, to: height, by: b) {
            for bx in stride(from: 0, to: width, by: b) {
                let sampleX = min(width - 1, bx + b / 2)
                let sampleY = min(height - 1, by + b / 2)
                let sampleIdx = (sampleY * width + sampleX) * 4
                
                let sR = buffer[sampleIdx]
                let sG = buffer[sampleIdx + 1]
                let sB = buffer[sampleIdx + 2]
                let sA = buffer[sampleIdx + 3]
                
                for py in by..<min(height, by + b) {
                    for px in bx..<min(width, bx + b) {
                        let outIdx = (py * width + px) * 4
                        buffer[outIdx] = sR
                        buffer[outIdx + 1] = sG
                        buffer[outIdx + 2] = sB
                        buffer[outIdx + 3] = sA
                    }
                }
            }
        }
    }
    
    // MARK: - Chromatic Aberration
    
    public func applyChromaticAberration(offsetPixels: Int, buffer: inout [UInt8], width: Int, height: Int) {
        let off = max(1, offsetPixels)
        let copy = buffer
        for y in 0..<height {
            for x in 0..<width {
                let currentIdx = (y * width + x) * 4
                // Red sampled from left
                let redX = max(0, x - off)
                let redIdx = (y * width + redX) * 4
                // Blue sampled from right
                let blueX = min(width - 1, x + off)
                let blueIdx = (y * width + blueX) * 4
                
                buffer[currentIdx] = copy[redIdx]
                // Green stays at center
                buffer[currentIdx + 2] = copy[blueIdx + 2]
            }
        }
    }
    
    // MARK: - Add Noise
    
    public func applyNoise(amount: Double, buffer: inout [UInt8], width: Int, height: Int) {
        let factor = max(0.0, min(1.0, amount)) * 60.0
        for i in 0..<(width * height) {
            let idx = i * 4
            let noise = (Double.random(in: -1.0...1.0)) * factor
            buffer[idx] = UInt8(max(0, min(255, round(Double(buffer[idx]) + noise))))
            buffer[idx + 1] = UInt8(max(0, min(255, round(Double(buffer[idx + 1]) + noise))))
            buffer[idx + 2] = UInt8(max(0, min(255, round(Double(buffer[idx + 2]) + noise))))
        }
    }
    
    // MARK: - Unsharp Mask
    
    public func applyUnsharpMask(radius: Double, intensity: Double, buffer: inout [UInt8], width: Int, height: Int) {
        var blurred = buffer
        applyGaussianBlur(radius: radius, buffer: &blurred, width: width, height: height)
        
        let alpha = max(0.1, intensity)
        for i in 0..<(width * height) {
            let idx = i * 4
            for c in 0..<3 {
                let orig = Double(buffer[idx + c])
                let blur = Double(blurred[idx + c])
                let sharp = orig + alpha * (orig - blur)
                buffer[idx + c] = UInt8(max(0, min(255, round(sharp))))
            }
        }
    }
    
    // MARK: - Basic Liquify (Push Warp)
    
    public func applyLiquifyPush(
        center: CGPoint,
        direction: CGPoint,
        radius: CGFloat,
        strength: Double,
        buffer: inout [UInt8],
        width: Int,
        height: Int
    ) {
        let r = Double(radius)
        guard r > 0 else { return }
        let copy = buffer
        
        let minX = max(0, Int(floor(center.x - radius)))
        let maxX = min(width - 1, Int(ceil(center.x + radius)))
        let minY = max(0, Int(floor(center.y - radius)))
        let maxY = min(height - 1, Int(ceil(center.y + radius)))
        
        for y in minY...maxY {
            let dy = Double(y) - Double(center.y)
            let dy2 = dy * dy
            for x in minX...maxX {
                let dx = Double(x) - Double(center.x)
                let dist = sqrt(dx * dx + dy2)
                guard dist <= r else { continue }
                
                // Falloff factor (1 at center, 0 at radius)
                let factor = (1.0 - dist / r) * strength
                let srcX = max(0.0, min(Double(width - 1), Double(x) - Double(direction.x) * factor))
                let srcY = max(0.0, min(Double(height - 1), Double(y) - Double(direction.y) * factor))
                
                let sxInt = Int(round(srcX))
                let syInt = Int(round(srcY))
                let srcIdx = (syInt * width + sxInt) * 4
                let dstIdx = (y * width + x) * 4
                
                buffer[dstIdx] = copy[srcIdx]
                buffer[dstIdx + 1] = copy[srcIdx + 1]
                buffer[dstIdx + 2] = copy[srcIdx + 2]
                buffer[dstIdx + 3] = copy[srcIdx + 3]
            }
        }
    }
}
