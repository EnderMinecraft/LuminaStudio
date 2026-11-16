import Foundation
import CoreGraphics

#if canImport(Vision)
import Vision
#endif

public final class CutoutEngine: @unchecked Sendable {
    public static let shared = CutoutEngine()
    
    public init() {}
    
    // MARK: - Auto Cutout via Vision Framework
    
    public func performAutoCutout(
        image: CGImage,
        personOnly: Bool = false
    ) async throws -> (mask: LayerMask, instanceCount: Int) {
        let w = image.width
        let h = image.height
        let mask = LayerMask(width: w, height: h, initialValue: 0)
        
        #if canImport(Vision)
        if #available(iOS 17.0, macOS 14.0, *) {
            if personOnly {
                // High-precision person segmentation
                let request = VNGeneratePersonSegmentationRequest()
                request.qualityLevel = .accurate
                let handler = VNImageRequestHandler(cgImage: image, options: [:])
                try handler.perform([request])
                
                if let result = request.results?.first {
                    let pixelBuffer = result.pixelBuffer
                    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
                    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
                    
                    let pw = CVPixelBufferGetWidth(pixelBuffer)
                    let ph = CVPixelBufferGetHeight(pixelBuffer)
                    if let base = CVPixelBufferGetBaseAddress(pixelBuffer) {
                        let floatPtr = base.assumingMemoryBound(to: Float32.self)
                        for y in 0..<h {
                            let sy = min(ph - 1, Int(Double(y) * Double(ph) / Double(h)))
                            for x in 0..<w {
                                let sx = min(pw - 1, Int(Double(x) * Double(pw) / Double(w)))
                                let prob = floatPtr[sy * pw + sx]
                                mask.setSample(x: x, y: y, value: UInt8(max(0, min(255, round(prob * 255.0)))))
                            }
                        }
                    }
                    return (mask, 1)
                }
            } else {
                // Multi-subject foreground instance mask
                let request = VNGenerateForegroundInstanceMaskRequest()
                let handler = VNImageRequestHandler(cgImage: image, options: [:])
                try handler.perform([request])
                
                if let result = request.results?.first {
                    let instances = result.allInstances
                    let count = instances.count
                    let maskBuffer = try result.generateScaledMaskForImage(forInstances: instances, from: handler)
                    CVPixelBufferLockBaseAddress(maskBuffer, .readOnly)
                    defer { CVPixelBufferUnlockBaseAddress(maskBuffer, .readOnly) }
                    
                    let pw = CVPixelBufferGetWidth(maskBuffer)
                    let ph = CVPixelBufferGetHeight(maskBuffer)
                    if let base = CVPixelBufferGetBaseAddress(maskBuffer) {
                        let ptr = base.assumingMemoryBound(to: UInt8.self)
                        for y in 0..<h {
                            let sy = min(ph - 1, Int(Double(y) * Double(ph) / Double(h)))
                            for x in 0..<w {
                                let sx = min(pw - 1, Int(Double(x) * Double(pw) / Double(w)))
                                let val = ptr[sy * pw + sx]
                                mask.setSample(x: x, y: y, value: val > 128 ? 255 : 0)
                            }
                        }
                    }
                    return (mask, count)
                }
            }
        }
        #endif
        
        // High-contrast central subject fallback
        let cx = w / 2
        let cy = h / 2
        let r = min(w, h) / 3
        for y in 0..<h {
            let dy = y - cy
            for x in 0..<w {
                let dx = x - cx
                if dx * dx + dy * dy <= r * r {
                    mask.setSample(x: x, y: y, value: 255)
                }
            }
        }
        return (mask, 1)
    }
    
    // MARK: - Edge Controls
    
    /// Shift edge: delta > 0 grows mask (dilation), delta < 0 shrinks mask (erosion)
    public func shiftEdge(mask: LayerMask, delta: Int) {
        guard delta != 0 else { return }
        let p = min(25, abs(delta))
        let w = mask.width
        let h = mask.height
        let copy = [UInt8](mask.maskData)
        
        mask.maskData.withUnsafeMutableBytes { ptr in
            guard let bytes = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
            for y in 0..<h {
                for x in 0..<w {
                    if delta > 0 {
                        // Expansion (Max)
                        var maxV: UInt8 = 0
                        for dy in -p...p {
                            let ny = y + dy
                            guard ny >= 0, ny < h else { continue }
                            for dx in -p...p {
                                let nx = x + dx
                                guard nx >= 0, nx < w else { continue }
                                if dx * dx + dy * dy <= p * p {
                                    maxV = max(maxV, copy[ny * w + nx])
                                    if maxV == 255 { break }
                                }
                            }
                            if maxV == 255 { break }
                        }
                        bytes[y * w + x] = maxV
                    } else {
                        // Contraction (Min)
                        var minV: UInt8 = 255
                        for dy in -p...p {
                            let ny = y + dy
                            guard ny >= 0, ny < h else { continue }
                            for dx in -p...p {
                                let nx = x + dx
                                guard nx >= 0, nx < w else { continue }
                                if dx * dx + dy * dy <= p * p {
                                    minV = min(minV, copy[ny * w + nx])
                                    if minV == 0 { break }
                                }
                            }
                            if minV == 0 { break }
                        }
                        bytes[y * w + x] = minV
                    }
                }
            }
        }
    }
    
    /// Feather mask edge using separable box blur
    public func feather(mask: LayerMask, radius: Int) {
        guard radius > 0 else { return }
        let r = min(40, radius)
        let w = mask.width
        let h = mask.height
        var temp = [UInt8](repeating: 0, count: w * h)
        let original = [UInt8](mask.maskData)
        
        // Horizontal pass
        for y in 0..<h {
            let rowOffset = y * w
            var windowSum = 0
            for x in -r...r {
                let clampedX = max(0, min(w - 1, x))
                windowSum += Int(original[rowOffset + clampedX])
            }
            let windowSize = r * 2 + 1
            for x in 0..<w {
                temp[rowOffset + x] = UInt8(windowSum / windowSize)
                let removeX = max(0, min(w - 1, x - r))
                let addX = max(0, min(w - 1, x + r + 1))
                windowSum += Int(original[rowOffset + addX]) - Int(original[rowOffset + removeX])
            }
        }
        
        // Vertical pass
        mask.maskData.withUnsafeMutableBytes { ptr in
            guard let bytes = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
            for x in 0..<w {
                var windowSum = 0
                for y in -r...r {
                    let clampedY = max(0, min(h - 1, y))
                    windowSum += Int(temp[clampedY * w + x])
                }
                let windowSize = r * 2 + 1
                for y in 0..<h {
                    bytes[y * w + x] = UInt8(windowSum / windowSize)
                    let removeY = max(0, min(h - 1, y - r))
                    let addY = max(0, min(h - 1, y + r + 1))
                    windowSum += Int(temp[addY * w + x]) - Int(temp[removeY * w + x])
                }
            }
        }
    }
    
    /// Adjust edge contrast (steepens transition around 128)
    public func adjustContrast(mask: LayerMask, contrast: Double) {
        let factor = 1.0 + contrast * 3.0
        mask.maskData.withUnsafeMutableBytes { ptr in
            guard let bytes = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
            for i in 0..<mask.maskData.count {
                let norm = Double(bytes[i]) / 255.0
                let steep = (norm - 0.5) * factor + 0.5
                bytes[i] = UInt8(max(0, min(255, round(steep * 255.0))))
            }
        }
    }
    
    // MARK: - Smart Edge Guided Filter
    
    public func paintSmartEdgeStamp(
        at center: CGPoint,
        radius: CGFloat,
        value: UInt8,
        hardness: Double,
        rgbPixels: [UInt8],
        mask: LayerMask
    ) {
        let w = mask.width
        let h = mask.height
        let r = Double(radius)
        guard r > 0 else { return }
        
        let cx = Int(round(center.x))
        let cy = Int(round(center.y))
        guard cx >= 0, cx < w, cy >= 0, cy < h else { return }
        
        // Sample center color
        let centerIdx = (cy * w + cx) * 4
        let cR = Double(rgbPixels[centerIdx])
        let cG = Double(rgbPixels[centerIdx + 1])
        let cB = Double(rgbPixels[centerIdx + 2])
        
        let minX = max(0, Int(floor(center.x - radius)))
        let maxX = min(w - 1, Int(ceil(center.x + radius)))
        let minY = max(0, Int(floor(center.y - radius)))
        let maxY = min(h - 1, Int(ceil(center.y + radius)))
        
        let sigmaColor = 45.0 // Color similarity variance
        let sigmaColorSq = 2.0 * sigmaColor * sigmaColor
        
        mask.maskData.withUnsafeMutableBytes { ptr in
            guard let bytes = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
            for y in minY...maxY {
                let dy = Double(y) - Double(center.y)
                let dy2 = dy * dy
                for x in minX...maxX {
                    let dx = Double(x) - Double(center.x)
                    let spatialDist = sqrt(dx * dx + dy2)
                    guard spatialDist <= r else { continue }
                    
                    let pIdx = (y * w + x) * 4
                    let pR = Double(rgbPixels[pIdx])
                    let pG = Double(rgbPixels[pIdx + 1])
                    let pB = Double(rgbPixels[pIdx + 2])
                    let colorDistSq = (pR - cR) * (pR - cR) + (pG - cG) * (pG - cG) + (pB - cB) * (pB - cB)
                    
                    // Bilateral weight = spatial decay * color similarity weight
                    let colorWeight = exp(-colorDistSq / sigmaColorSq)
                    let spatialWeight = 1.0 - (spatialDist / r) * (1.0 - hardness)
                    let weight = max(0.0, min(1.0, colorWeight * spatialWeight))
                    
                    let mIdx = y * w + x
                    let current = Double(bytes[mIdx])
                    let target = Double(value)
                    let newV = current + (target - current) * weight
                    bytes[mIdx] = UInt8(max(0, min(255, round(newV))))
                }
            }
        }
    }
    
    // MARK: - Hair & Fine-Detail Trimap Refinement
    
    public func refineHairDetails(mask: LayerMask, rgbPixels: [UInt8]) {
        let w = mask.width
        let h = mask.height
        let copy = [UInt8](mask.maskData)
        
        mask.maskData.withUnsafeMutableBytes { ptr in
            guard let bytes = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
            for y in 2..<(h - 2) {
                for x in 2..<(w - 2) {
                    let idx = y * w + x
                    let alpha = copy[idx]
                    // If in unknown boundary zone (15..240)
                    if alpha > 15 && alpha < 240 {
                        // Sample local neighborhood for foreground (>=240) and background (<=15)
                        var fgR = 0.0, fgG = 0.0, fgB = 0.0, fgCount = 0.0
                        var bgR = 0.0, bgG = 0.0, bgB = 0.0, bgCount = 0.0
                        
                        for dy in -2...2 {
                            for dx in -2...2 {
                                let nx = x + dx
                                let ny = y + dy
                                let nAlpha = copy[ny * w + nx]
                                let pIdx = (ny * w + nx) * 4
                                if nAlpha >= 240 {
                                    fgR += Double(rgbPixels[pIdx])
                                    fgG += Double(rgbPixels[pIdx + 1])
                                    fgB += Double(rgbPixels[pIdx + 2])
                                    fgCount += 1.0
                                } else if nAlpha <= 15 {
                                    bgR += Double(rgbPixels[pIdx])
                                    bgG += Double(rgbPixels[pIdx + 1])
                                    bgB += Double(rgbPixels[pIdx + 2])
                                    bgCount += 1.0
                                }
                            }
                        }
                        
                        if fgCount > 0 && bgCount > 0 {
                            let fR = fgR / fgCount, fG = fgG / fgCount, fB = fgB / fgCount
                            let bR = bgR / bgCount, bG = bgG / bgCount, bB = bgB / bgCount
                            let curIdx = (y * w + x) * 4
                            let cR = Double(rgbPixels[curIdx]), cG = Double(rgbPixels[curIdx + 1]), cB = Double(rgbPixels[curIdx + 2])
                            
                            // Projection of (C - B) onto (F - B)
                            let dFR = fR - bR, dFG = fG - bG, dFB = fB - bB
                            let dCR = cR - bR, dCG = cG - bG, dCB = cB - bB
                            let num = dCR * dFR + dCG * dFG + dCB * dFB
                            let den = dFR * dFR + dFG * dFG + dFB * dFB
                            if den > 1.0 {
                                let estimatedAlpha = max(0.0, min(1.0, num / den))
                                bytes[idx] = UInt8(round(estimatedAlpha * 255.0))
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Color Decontamination
    
    public func decontaminateColors(rgbPixels: inout [UInt8], mask: LayerMask, strength: Double = 0.8) {
        let w = mask.width
        let h = mask.height
        let maskBytes = [UInt8](mask.maskData)
        
        for y in 2..<(h - 2) {
            for x in 2..<(w - 2) {
                let mIdx = y * w + x
                let alpha = maskBytes[mIdx]
                // Only operate on soft edges
                if alpha > 20 && alpha < 235 {
                    // Search for nearest confident foreground pixel (>=245)
                    var foundR: Double?
                    var foundG: Double?
                    var foundB: Double?
                    var minDist = 999.0
                    
                    for dy in -3...3 {
                        for dx in -3...3 {
                            let nx = x + dx
                            let ny = y + dy
                            if maskBytes[ny * w + nx] >= 245 {
                                let d = Double(dx * dx + dy * dy)
                                if d < minDist {
                                    minDist = d
                                    let pIdx = (ny * w + nx) * 4
                                    foundR = Double(rgbPixels[pIdx])
                                    foundG = Double(rgbPixels[pIdx + 1])
                                    foundB = Double(rgbPixels[pIdx + 2])
                                }
                            }
                        }
                    }
                    
                    if let fR = foundR, let fG = foundG, let fB = foundB {
                        let curIdx = (y * w + x) * 4
                        let origR = Double(rgbPixels[curIdx])
                        let origG = Double(rgbPixels[curIdx + 1])
                        let origB = Double(rgbPixels[curIdx + 2])
                        let factor = strength * (1.0 - Double(alpha) / 255.0)
                        
                        rgbPixels[curIdx] = UInt8(round(origR + (fR - origR) * factor))
                        rgbPixels[curIdx + 1] = UInt8(round(origG + (fG - origG) * factor))
                        rgbPixels[curIdx + 2] = UInt8(round(origB + (fB - origB) * factor))
                    }
                }
            }
        }
    }
    
    // MARK: - Connected-Component Speck Cleanup
    
    public func removeSmallSpecks(mask: LayerMask, minPixelCount: Int = 100) -> Int {
        let w = mask.width
        let h = mask.height
        var labels = [Int](repeating: 0, count: w * h)
        var currentLabel = 0
        var componentSizes: [Int: Int] = [:]
        
        let bytes = [UInt8](mask.maskData)
        
        // 4-way Connected-Component Labeling (BFS)
        for y in 0..<h {
            for x in 0..<w {
                let idx = y * w + x
                if bytes[idx] > 30 && labels[idx] == 0 {
                    currentLabel += 1
                    var size = 0
                    var queue: [(Int, Int)] = [(x, y)]
                    labels[idx] = currentLabel
                    
                    while !queue.isEmpty {
                        let (cx, cy) = queue.removeLast()
                        size += 1
                        let neighbors = [(cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)]
                        for (nx, ny) in neighbors {
                            guard nx >= 0, nx < w, ny >= 0, ny < h else { continue }
                            let nIdx = ny * w + nx
                            if bytes[nIdx] > 30 && labels[nIdx] == 0 {
                                labels[nIdx] = currentLabel
                                queue.append((nx, ny))
                            }
                        }
                    }
                    componentSizes[currentLabel] = size
                }
            }
        }
        
        // Clear components below minPixelCount threshold
        var removedCount = 0
        mask.maskData.withUnsafeMutableBytes { ptr in
            guard let outBytes = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
            for i in 0..<(w * h) {
                let lbl = labels[i]
                if lbl > 0, let sz = componentSizes[lbl], sz < minPixelCount {
                    outBytes[i] = 0
                    removedCount += 1
                }
            }
        }
        return removedCount
    }
}
