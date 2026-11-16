import Foundation
import CoreGraphics

public struct ColorRGBA: Sendable, Equatable {
    public var r: UInt8
    public var g: UInt8
    public var b: UInt8
    public var a: UInt8
    
    public init(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
    
    public var hexString: String {
        String(format: "#%02X%02X%02X", r, g, b)
    }
}

public struct GradientStop: Sendable, Equatable {
    public var location: Double // 0.0 to 1.0
    public var color: ColorRGBA
    
    public init(location: Double, color: ColorRGBA) {
        self.location = max(0.0, min(1.0, location))
        self.color = color
    }
}

// MARK: - Eyedropper Engine

public final class EyedropperEngine: Sendable {
    public static let shared = EyedropperEngine()
    
    public init() {}
    
    public func sampleColor(
        at point: CGPoint,
        in buffer: Data,
        width: Int,
        height: Int,
        aperture: Int = 1 // 1: 1x1, 3: 3x3, 5: 5x5
    ) -> ColorRGBA? {
        let px = Int(round(point.x))
        let py = Int(round(point.y))
        guard px >= 0, px < width, py >= 0, py < height else { return nil }
        
        let half = aperture / 2
        var sumR: Int = 0
        var sumG: Int = 0
        var sumB: Int = 0
        var sumA: Int = 0
        var count: Int = 0
        
        buffer.withUnsafeBytes { ptr in
            guard let bytes = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
            for dy in -half...half {
                let sy = py + dy
                guard sy >= 0, sy < height else { continue }
                for dx in -half...half {
                    let sx = px + dx
                    guard sx >= 0, sx < width else { continue }
                    let idx = (sy * width + sx) * 4
                    sumR += Int(bytes[idx])
                    sumG += Int(bytes[idx + 1])
                    sumB += Int(bytes[idx + 2])
                    sumA += Int(bytes[idx + 3])
                    count += 1
                }
            }
        }
        
        guard count > 0 else { return nil }
        return ColorRGBA(
            r: UInt8(sumR / count),
            g: UInt8(sumG / count),
            b: UInt8(sumB / count),
            a: UInt8(sumA / count)
        )
    }
}

// MARK: - Flood Fill Engine

public final class FloodFillEngine: @unchecked Sendable {
    public static let shared = FloodFillEngine()
    
    public init() {}
    
    public func fill(
        startPoint: CGPoint,
        fillColor: ColorRGBA,
        tolerance: Double, // 0.0 to 1.0 (0% to 100%)
        isContiguous: Bool,
        buffer: inout [UInt8],
        width: Int,
        height: Int
    ) {
        let sx = Int(round(startPoint.x))
        let sy = Int(round(startPoint.y))
        guard sx >= 0, sx < width, sy >= 0, sy < height else { return }
        
        let targetIndex = (sy * width + sx) * 4
        let targetR = buffer[targetIndex]
        let targetG = buffer[targetIndex + 1]
        let targetB = buffer[targetIndex + 2]
        let targetA = buffer[targetIndex + 3]
        
        func colorDistance(r: UInt8, g: UInt8, b: UInt8, a: UInt8) -> Double {
            let dr = Double(r) - Double(targetR)
            let dg = Double(g) - Double(targetG)
            let db = Double(b) - Double(targetB)
            let da = Double(a) - Double(targetA)
            return sqrt(dr * dr + dg * dg + db * db + da * da) / (255.0 * 2.0)
        }
        
        if !isContiguous {
            // Replace all matching pixels
            for i in 0..<(width * height) {
                let off = i * 4
                let dist = colorDistance(r: buffer[off], g: buffer[off + 1], b: buffer[off + 2], a: buffer[off + 3])
                if dist <= tolerance {
                    buffer[off] = fillColor.r
                    buffer[off + 1] = fillColor.g
                    buffer[off + 2] = fillColor.b
                    buffer[off + 3] = fillColor.a
                }
            }
            return
        }
        
        // Scanline contiguous flood-fill
        var visited = [Bool](repeating: false, count: width * height)
        var queue: [(x: Int, y: Int)] = [(sx, sy)]
        visited[sy * width + sx] = true
        
        while !queue.isEmpty {
            let (cx, cy) = queue.removeLast()
            let idx = (cy * width + cx) * 4
            
            buffer[idx] = fillColor.r
            buffer[idx + 1] = fillColor.g
            buffer[idx + 2] = fillColor.b
            buffer[idx + 3] = fillColor.a
            
            let neighbors = [(cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)]
            for (nx, ny) in neighbors {
                guard nx >= 0, nx < width, ny >= 0, ny < height else { continue }
                let nIdx = ny * width + nx
                guard !visited[nIdx] else { continue }
                
                let pIdx = nIdx * 4
                let dist = colorDistance(r: buffer[pIdx], g: buffer[pIdx + 1], b: buffer[pIdx + 2], a: buffer[pIdx + 3])
                if dist <= tolerance {
                    visited[nIdx] = true
                    queue.append((nx, ny))
                }
            }
        }
    }
}

// MARK: - Gradient Engine

public enum GradientType: String, CaseIterable, Sendable {
    case linear = "Linear"
    case radial = "Radial"
}

public final class GradientEngine: Sendable {
    public static let shared = GradientEngine()
    
    public init() {}
    
    public func renderLinearGradient(
        from start: CGPoint,
        to end: CGPoint,
        stops: [GradientStop],
        width: Int,
        height: Int,
        buffer: inout [UInt8]
    ) {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let lengthSq = Double(dx * dx + dy * dy)
        guard lengthSq > 0 else { return }
        
        let sortedStops = stops.sorted { $0.location < $1.location }
        
        for y in 0..<height {
            for x in 0..<width {
                let vx = Double(x) - Double(start.x)
                let vy = Double(y) - Double(start.y)
                let dot = vx * Double(dx) + vy * Double(dy)
                let t = max(0.0, min(1.0, dot / lengthSq))
                
                let color = interpolateColor(at: t, stops: sortedStops)
                let idx = (y * width + x) * 4
                buffer[idx] = color.r
                buffer[idx + 1] = color.g
                buffer[idx + 2] = color.b
                buffer[idx + 3] = color.a
            }
        }
    }
    
    public func renderRadialGradient(
        center: CGPoint,
        radius: CGFloat,
        stops: [GradientStop],
        width: Int,
        height: Int,
        buffer: inout [UInt8]
    ) {
        guard radius > 0 else { return }
        let rDouble = Double(radius)
        let sortedStops = stops.sorted { $0.location < $1.location }
        
        for y in 0..<height {
            let dy = Double(y) - Double(center.y)
            let dy2 = dy * dy
            for x in 0..<width {
                let dx = Double(x) - Double(center.x)
                let dist = sqrt(dx * dx + dy2)
                let t = max(0.0, min(1.0, dist / rDouble))
                
                let color = interpolateColor(at: t, stops: sortedStops)
                let idx = (y * width + x) * 4
                buffer[idx] = color.r
                buffer[idx + 1] = color.g
                buffer[idx + 2] = color.b
                buffer[idx + 3] = color.a
            }
        }
    }
    
    private func interpolateColor(at t: Double, stops: [GradientStop]) -> ColorRGBA {
        guard !stops.isEmpty else { return ColorRGBA(r: 0, g: 0, b: 0, a: 255) }
        if stops.count == 1 { return stops[0].color }
        if t <= stops.first!.location { return stops.first!.color }
        if t >= stops.last!.location { return stops.last!.color }
        
        for i in 0..<(stops.count - 1) {
            let s1 = stops[i]
            let s2 = stops[i + 1]
            if t >= s1.location && t <= s2.location {
                let factor = (t - s1.location) / max(1e-6, s2.location - s1.location)
                let r = Double(s1.color.r) + (Double(s2.color.r) - Double(s1.color.r)) * factor
                let g = Double(s1.color.g) + (Double(s2.color.g) - Double(s1.color.g)) * factor
                let b = Double(s1.color.b) + (Double(s2.color.b) - Double(s1.color.b)) * factor
                let a = Double(s1.color.a) + (Double(s2.color.a) - Double(s1.color.a)) * factor
                return ColorRGBA(r: UInt8(round(r)), g: UInt8(round(g)), b: UInt8(round(b)), a: UInt8(round(a)))
            }
        }
        return stops.last!.color
    }
}
