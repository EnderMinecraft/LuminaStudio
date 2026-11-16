import Foundation
import CoreGraphics

#if canImport(Vision)
import Vision
#endif

public enum SelectionMode: String, CaseIterable, Sendable {
    case replace = "New"
    case add = "Add (+)"
    case subtract = "Subtract (-)"
    case intersect = "Intersect (∩)"
}

public enum SelectionToolType: String, CaseIterable, Sendable {
    case rectangle = "Rectangle"
    case ellipse = "Ellipse"
    case lasso = "Lasso"
    case polygonalLasso = "Polygonal Lasso"
    case magicWand = "Magic Wand"
    case subject = "Select Subject"
}

public final class SelectionMask: @unchecked Sendable, Equatable {
    public let width: Int
    public let height: Int
    public var data: [UInt8]
    
    public init(width: Int, height: Int, initialValue: UInt8 = 0) {
        self.width = max(1, width)
        self.height = max(1, height)
        self.data = [UInt8](repeating: initialValue, count: max(1, width) * max(1, height))
    }
    
    public var hasSelection: Bool {
        data.contains { $0 > 0 }
    }
    
    public static func == (lhs: SelectionMask, rhs: SelectionMask) -> Bool {
        lhs.width == rhs.width && lhs.height == rhs.height && lhs.data == rhs.data
    }
    
    public func duplicate() -> SelectionMask {
        let copy = SelectionMask(width: width, height: height)
        copy.data = self.data
        return copy
    }
    
    // MARK: - Combination Operations
    
    public func combine(with incoming: [UInt8], mode: SelectionMode) {
        guard incoming.count == data.count else { return }
        
        switch mode {
        case .replace:
            data = incoming
            
        case .add:
            for i in 0..<data.count {
                data[i] = UInt8(min(255, Int(data[i]) + Int(incoming[i])))
            }
            
        case .subtract:
            for i in 0..<data.count {
                data[i] = UInt8(max(0, Int(data[i]) - Int(incoming[i])))
            }
            
        case .intersect:
            for i in 0..<data.count {
                let v = (Int(data[i]) * Int(incoming[i])) / 255
                data[i] = UInt8(v)
            }
        }
    }
    
    // MARK: - Mask Operations
    
    public func invert() {
        for i in 0..<data.count {
            data[i] = 255 - data[i]
        }
    }
    
    public func selectAll() {
        data = [UInt8](repeating: 255, count: width * height)
    }
    
    public func deselect() {
        data = [UInt8](repeating: 0, count: width * height)
    }
    
    /// Separable box blur approximating feathering
    public func feather(radius: Int) {
        guard radius > 0 else { return }
        let r = min(50, radius)
        var temp = [UInt8](repeating: 0, count: width * height)
        
        // Horizontal pass
        for y in 0..<height {
            let rowOffset = y * width
            var windowSum = 0
            for x in -r...r {
                let clampedX = max(0, min(width - 1, x))
                windowSum += Int(data[rowOffset + clampedX])
            }
            let windowSize = r * 2 + 1
            for x in 0..<width {
                temp[rowOffset + x] = UInt8(windowSum / windowSize)
                let removeX = max(0, min(width - 1, x - r))
                let addX = max(0, min(width - 1, x + r + 1))
                windowSum += Int(data[rowOffset + addX]) - Int(data[rowOffset + removeX])
            }
        }
        
        // Vertical pass
        for x in 0..<width {
            var windowSum = 0
            for y in -r...r {
                let clampedY = max(0, min(height - 1, y))
                windowSum += Int(temp[clampedY * width + x])
            }
            let windowSize = r * 2 + 1
            for y in 0..<height {
                data[y * width + x] = UInt8(windowSum / windowSize)
                let removeY = max(0, min(height - 1, y - r))
                let addY = max(0, min(height - 1, y + r + 1))
                windowSum += Int(temp[addY * width + x]) - Int(temp[removeY * width + x])
            }
        }
    }
    
    /// Morphological dilation (expansion)
    public func expand(pixels: Int) {
        guard pixels > 0 else { return }
        let p = min(30, pixels)
        let copy = data
        for y in 0..<height {
            for x in 0..<width {
                var maxVal: UInt8 = 0
                for dy in -p...p {
                    let ny = y + dy
                    guard ny >= 0, ny < height else { continue }
                    for dx in -p...p {
                        let nx = x + dx
                        guard nx >= 0, nx < width else { continue }
                        if dx * dx + dy * dy <= p * p {
                            maxVal = max(maxVal, copy[ny * width + nx])
                            if maxVal == 255 { break }
                        }
                    }
                    if maxVal == 255 { break }
                }
                data[y * width + x] = maxVal
            }
        }
    }
    
    /// Morphological erosion (contraction)
    public func contract(pixels: Int) {
        guard pixels > 0 else { return }
        let p = min(30, pixels)
        let copy = data
        for y in 0..<height {
            for x in 0..<width {
                var minVal: UInt8 = 255
                for dy in -p...p {
                    let ny = y + dy
                    guard ny >= 0, ny < height else { continue }
                    for dx in -p...p {
                        let nx = x + dx
                        guard nx >= 0, nx < width else { continue }
                        if dx * dx + dy * dy <= p * p {
                            minVal = min(minVal, copy[ny * width + nx])
                            if minVal == 0 { break }
                        }
                    }
                    if minVal == 0 { break }
                }
                data[y * width + x] = minVal
            }
        }
    }
}

// MARK: - Selection Engine

public final class SelectionEngine: @unchecked Sendable {
    public static let shared = SelectionEngine()
    
    public init() {}
    
    public func makeRectSelection(rect: CGRect, width: Int, height: Int) -> [UInt8] {
        var buffer = [UInt8](repeating: 0, count: width * height)
        let minX = max(0, Int(floor(rect.minX)))
        let maxX = min(width - 1, Int(ceil(rect.maxX)))
        let minY = max(0, Int(floor(rect.minY)))
        let maxY = min(height - 1, Int(ceil(rect.maxY)))
        
        guard minX <= maxX, minY <= maxY else { return buffer }
        
        for y in minY...maxY {
            let row = y * width
            for x in minX...maxX {
                buffer[row + x] = 255
            }
        }
        return buffer
    }
    
    public func makeEllipseSelection(in rect: CGRect, width: Int, height: Int) -> [UInt8] {
        var buffer = [UInt8](repeating: 0, count: width * height)
        let cx = rect.midX
        let cy = rect.midY
        let rx = rect.width / 2.0
        let ry = rect.height / 2.0
        guard rx > 0, ry > 0 else { return buffer }
        
        let minX = max(0, Int(floor(rect.minX)))
        let maxX = min(width - 1, Int(ceil(rect.maxX)))
        let minY = max(0, Int(floor(rect.minY)))
        let maxY = min(height - 1, Int(ceil(rect.maxY)))
        
        let rx2 = Double(rx * rx)
        let ry2 = Double(ry * ry)
        
        for y in minY...maxY {
            let dy = Double(CGFloat(y) - cy)
            let dy2 = dy * dy
            let row = y * width
            for x in minX...maxX {
                let dx = Double(CGFloat(x) - cx)
                let val = (dx * dx) / rx2 + dy2 / ry2
                if val <= 1.0 {
                    buffer[row + x] = 255
                }
            }
        }
        return buffer
    }
    
    public func makePolygonSelection(points: [CGPoint], width: Int, height: Int) -> [UInt8] {
        var buffer = [UInt8](repeating: 0, count: width * height)
        guard points.count >= 3 else { return buffer }
        
        // Raycasting point-in-polygon
        for y in 0..<height {
            let py = CGFloat(y)
            let row = y * width
            for x in 0..<width {
                let px = CGFloat(x)
                var inside = false
                var j = points.count - 1
                for i in 0..<points.count {
                    let pi = points[i]
                    let pj = points[j]
                    if ((pi.y > py) != (pj.y > py)) &&
                       (px < (pj.x - pi.x) * (py - pi.y) / (pj.y - pi.y) + pi.x) {
                        inside.toggle()
                    }
                    j = i
                }
                if inside {
                    buffer[row + x] = 255
                }
            }
        }
        return buffer
    }
    
    public func makeMagicWandSelection(
        startPoint: CGPoint,
        tolerance: Double,
        isContiguous: Bool,
        sourceBuffer: [UInt8],
        width: Int,
        height: Int
    ) -> [UInt8] {
        var selection = [UInt8](repeating: 0, count: width * height)
        let sx = Int(round(startPoint.x))
        let sy = Int(round(startPoint.y))
        guard sx >= 0, sx < width, sy >= 0, sy < height else { return selection }
        
        let targetIndex = (sy * width + sx) * 4
        let tR = sourceBuffer[targetIndex]
        let tG = sourceBuffer[targetIndex + 1]
        let tB = sourceBuffer[targetIndex + 2]
        let tA = sourceBuffer[targetIndex + 3]
        
        func match(x: Int, y: Int) -> Bool {
            let idx = (y * width + x) * 4
            let dr = Double(sourceBuffer[idx]) - Double(tR)
            let dg = Double(sourceBuffer[idx + 1]) - Double(tG)
            let db = Double(sourceBuffer[idx + 2]) - Double(tB)
            let da = Double(sourceBuffer[idx + 3]) - Double(tA)
            let dist = sqrt(dr * dr + dg * dg + db * db + da * da) / (255.0 * 2.0)
            return dist <= tolerance
        }
        
        if !isContiguous {
            for y in 0..<height {
                for x in 0..<width {
                    if match(x: x, y: y) {
                        selection[y * width + x] = 255
                    }
                }
            }
            return selection
        }
        
        var visited = [Bool](repeating: false, count: width * height)
        var queue = [(x: sx, y: sy)]
        visited[sy * width + sx] = true
        
        while !queue.isEmpty {
            let (cx, cy) = queue.removeLast()
            selection[cy * width + cx] = 255
            
            let neighbors = [(cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)]
            for (nx, ny) in neighbors {
                guard nx >= 0, nx < width, ny >= 0, ny < height else { continue }
                let nIdx = ny * width + nx
                guard !visited[nIdx] else { continue }
                visited[nIdx] = true
                if match(x: nx, y: ny) {
                    queue.append((nx, ny))
                }
            }
        }
        
        return selection
    }
    
    #if canImport(Vision)
    public func selectSubject(from cgImage: CGImage) async throws -> SelectionMask {
        let mask = SelectionMask(width: cgImage.width, height: cgImage.height)
        
        if #available(iOS 17.0, macOS 14.0, *) {
            let request = VNGenerateForegroundInstanceMaskRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])
            
            if let result = request.results?.first {
                let maskPixelBuffer = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
                CVPixelBufferLockBaseAddress(maskPixelBuffer, .readOnly)
                defer { CVPixelBufferUnlockBaseAddress(maskPixelBuffer, .readOnly) }
                
                let mw = CVPixelBufferGetWidth(maskPixelBuffer)
                let mh = CVPixelBufferGetHeight(maskPixelBuffer)
                if let base = CVPixelBufferGetBaseAddress(maskPixelBuffer) {
                    let ptr = base.assumingMemoryBound(to: UInt8.self)
                    let copyLen = min(mask.data.count, mw * mh)
                    for i in 0..<copyLen {
                        mask.data[i] = ptr[i] > 128 ? 255 : 0
                    }
                }
            }
        } else {
            // Fallback for older targets
            mask.selectAll()
        }
        
        return mask
    }
    #endif
}
