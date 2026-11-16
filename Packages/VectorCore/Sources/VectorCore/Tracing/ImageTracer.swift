import Foundation
import CoreGraphics

#if canImport(Vision)
import Vision
#endif

public final class ImageTracer: @unchecked Sendable {
    public static let shared = ImageTracer()
    
    public init() {}
    
    public struct TracingOptions: Sendable {
        public var contrastAdjustment: Float
        public var detectsDarkOnLight: Bool
        public var detailLevel: Float       // 0.0 (fewest anchors) to 1.0 (most detail)
        public var cornerTolerance: CGFloat // Epsilon for RDP simplification
        
        public init(
            contrastAdjustment: Float = 1.0,
            detectsDarkOnLight: Bool = false,
            detailLevel: Float = 0.5,
            cornerTolerance: CGFloat = 1.5
        ) {
            self.contrastAdjustment = contrastAdjustment
            self.detectsDarkOnLight = detectsDarkOnLight
            self.detailLevel = detailLevel
            self.cornerTolerance = cornerTolerance
        }
    }
    
    public func traceImage(
        rgbaPixels: [UInt8],
        width: Int,
        height: Int,
        options: TracingOptions = TracingOptions()
    ) async -> [BezierSubpath] {
        guard width > 0 && height > 0 && rgbaPixels.count >= width * height * 4 else {
            return []
        }
        
        #if canImport(Vision)
        // 1. Convert pixel buffer to CGImage for Vision request
        if let cgImage = createCGImage(from: rgbaPixels, width: width, height: height) {
            do {
                let visionSubpaths = try await traceWithVision(cgImage: cgImage, width: width, height: height, options: options)
                if !visionSubpaths.isEmpty {
                    return visionSubpaths
                }
            } catch {
                // Fall back to CPU Moore-Neighbor contour tracer
            }
        }
        #endif
        
        // 2. Fallback: Fast Moore-Neighbor contour tracing algorithm
        return traceMooreNeighbor(rgbaPixels: rgbaPixels, width: width, height: height, options: options)
    }
    
    #if canImport(Vision)
    private func traceWithVision(
        cgImage: CGImage,
        width: Int,
        height: Int,
        options: TracingOptions
    ) async throws -> [BezierSubpath] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectContoursRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let results = request.results as? [VNContoursObservation],
                      let observation = results.first else {
                    continuation.resume(returning: [])
                    return
                }
                
                var subpaths: [BezierSubpath] = []
                let contourCount = observation.contourCount
                
                // Sample contours up to max 100 prominent outlines
                let limit = min(contourCount, 100)
                for i in 0..<limit {
                    guard let contour = try? observation.contour(at: i) else { continue }
                    let points = contour.normalizedPoints
                    guard points.count >= 3 else { continue }
                    
                    var canvasPoints: [CGPoint] = []
                    for pt in points {
                        // Vision coordinates: (0,0) is bottom-left, convert to top-left
                        let x = CGFloat(pt.x) * CGFloat(width)
                        let y = CGFloat(1.0 - pt.y) * CGFloat(height)
                        canvasPoints.append(CGPoint(x: x, y: y))
                    }
                    
                    let simplified = CurveFitting.simplifyRDP(points: canvasPoints, epsilon: options.cornerTolerance)
                    guard simplified.count >= 3 else { continue }
                    let subpath = CurveFitting.fitSubpath(points: simplified, maxError: options.cornerTolerance * 1.5, isClosed: true)
                    subpaths.append(subpath)
                }
                
                continuation.resume(returning: subpaths)
            }
            
            request.contrastAdjustment = options.contrastAdjustment
            request.detectsDarkOnLight = options.detectsDarkOnLight
            request.maximumImageDimension = 1024
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    #endif
    
    // MARK: - Moore-Neighbor CPU Fallback Tracer
    
    private func traceMooreNeighbor(
        rgbaPixels: [UInt8],
        width: Int,
        height: Int,
        options: TracingOptions
    ) -> [BezierSubpath] {
        // Threshold raster into binary mask
        var binary = [Bool](repeating: false, count: width * height)
        for y in 0..<height {
            for x in 0..<width {
                let idx = (y * width + x) * 4
                let a = rgbaPixels[idx + 3]
                let lum = 0.299 * Double(rgbaPixels[idx]) + 0.587 * Double(rgbaPixels[idx + 1]) + 0.114 * Double(rgbaPixels[idx + 2])
                binary[y * width + x] = (a > 64 && lum < 200)
            }
        }
        
        var visited = [Bool](repeating: false, count: width * height)
        var rawContours: [[CGPoint]] = []
        
        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let idx = y * width + x
                if binary[idx] && !visited[idx] && !binary[idx - 1] {
                    // Start contour tracing
                    let ring = traceContourRing(startX: x, startY: y, binary: binary, visited: &visited, width: width, height: height)
                    if ring.count >= 6 {
                        rawContours.append(ring)
                    }
                }
            }
        }
        
        var subpaths: [BezierSubpath] = []
        for ring in rawContours.prefix(50) {
            let simplified = CurveFitting.simplifyRDP(points: ring, epsilon: options.cornerTolerance)
            guard simplified.count >= 3 else { continue }
            let subpath = CurveFitting.fitSubpath(points: simplified, maxError: options.cornerTolerance * 2.0, isClosed: true)
            subpaths.append(subpath)
        }
        
        return subpaths
    }
    
    private func traceContourRing(
        startX: Int,
        startY: Int,
        binary: [Bool],
        visited: inout [Bool],
        width: Int,
        height: Int
    ) -> [CGPoint] {
        var ring: [CGPoint] = [CGPoint(x: startX, y: startY)]
        visited[startY * width + startX] = true
        
        // 8-neighborhood directions clockwise
        let dx = [0, 1, 1, 1, 0, -1, -1, -1]
        let dy = [-1, -1, 0, 1, 1, 1, 0, -1]
        
        var cx = startX
        var cy = startY
        var dir = 7 // backtrack direction
        
        for _ in 0..<2048 {
            var found = false
            for d in 0..<8 {
                let testDir = (dir + d) % 8
                let nx = cx + dx[testDir]
                let ny = cy + dy[testDir]
                
                if nx >= 0 && nx < width && ny >= 0 && ny < height && binary[ny * width + nx] {
                    cx = nx
                    cy = ny
                    dir = (testDir + 5) % 8
                    ring.append(CGPoint(x: cx, y: cy))
                    visited[cy * width + cx] = true
                    found = true
                    break
                }
            }
            
            if !found || (cx == startX && cy == startY) {
                break
            }
        }
        return ring
    }
    
    private func createCGImage(from pixels: [UInt8], width: Int, height: Int) -> CGImage? {
        var mutablePixels = pixels
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        
        guard let context = CGContext(
            data: &mutablePixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else { return nil }
        
        return context.makeImage()
    }
}
