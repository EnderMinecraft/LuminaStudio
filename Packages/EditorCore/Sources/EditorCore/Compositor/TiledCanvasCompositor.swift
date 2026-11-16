import Foundation
import CoreGraphics
import Metal

#if canImport(MetalKit)
import MetalKit
#endif

public final class TiledCanvasCompositor: @unchecked Sendable {
    public let deviceManager: MetalDeviceManager
    private let tileCache: TileCache<String, MTLTexture>
    
    public init(deviceManager: MetalDeviceManager = .shared, cacheCapacity: Int = 512) {
        self.deviceManager = deviceManager
        self.tileCache = TileCache<String, MTLTexture>(capacity: cacheCapacity)
    }
    
    /// Flattens document layers into an RGBA8 buffer of size (width x height)
    public func compositeToBuffer(document: LuminaDocument) -> Data {
        let w = document.configuration.width
        let h = document.configuration.height
        let totalBytes = w * h * 4
        
        // Start with canvas background
        let (bgR, bgG, bgB, bgA) = document.configuration.backgroundColor.rgba
        var canvasBuffer = [UInt8](repeating: 0, count: totalBytes)
        let rByte = UInt8(bgR * 255.0)
        let gByte = UInt8(bgG * 255.0)
        let bByte = UInt8(bgB * 255.0)
        let aByte = UInt8(bgA * 255.0)
        
        if aByte > 0 {
            for i in 0..<(w * h) {
                let off = i * 4
                canvasBuffer[off] = rByte
                canvasBuffer[off + 1] = gByte
                canvasBuffer[off + 2] = bByte
                canvasBuffer[off + 3] = aByte
            }
        }
        
        // Composite visible layers from bottom to top
        for layer in document.layers where layer.isVisible && layer.opacity > 0 {
            guard let layerPixels = layer.rawPixelData,
                  layer.pixelWidth > 0, layer.pixelHeight > 0 else {
                continue
            }
            
            let layerOpacity = Double(layer.opacity)
            let blendMode = layer.blendMode
            let mask = layer.mask
            let lw = layer.pixelWidth
            let lh = layer.pixelHeight
            
            layerPixels.withUnsafeBytes { srcPtr in
                guard let src = srcPtr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
                
                let copyW = min(w, lw)
                let copyH = min(h, lh)
                
                for y in 0..<copyH {
                    for x in 0..<copyW {
                        let dstIndex = (y * w + x) * 4
                        let srcIndex = (y * lw + x) * 4
                        
                        let sR = Double(src[srcIndex]) / 255.0
                        let sG = Double(src[srcIndex + 1]) / 255.0
                        let sB = Double(src[srcIndex + 2]) / 255.0
                        var sA = Double(src[srcIndex + 3]) / 255.0 * layerOpacity
                        
                        if let mask = mask, mask.isEnabled {
                            let maskVal = Double(mask.sample(x: x, y: y)) / 255.0
                            sA *= maskVal
                        }
                        
                        if sA <= 0.0 { continue }
                        
                        let dR = Double(canvasBuffer[dstIndex]) / 255.0
                        let dG = Double(canvasBuffer[dstIndex + 1]) / 255.0
                        let dB = Double(canvasBuffer[dstIndex + 2]) / 255.0
                        let dA = Double(canvasBuffer[dstIndex + 3]) / 255.0
                        
                        // Blend RGB
                        let blended = blendMode.blend(backdrop: (dR, dG, dB), source: (sR, sG, sB))
                        
                        // Standard Porter-Duff source-over compositing with alpha
                        let outA = sA + dA * (1.0 - sA)
                        if outA > 0.0 {
                            let outR = (blended.r * sA + dR * dA * (1.0 - sA)) / outA
                            let outG = (blended.g * sA + dG * dA * (1.0 - sA)) / outA
                            let outB = (blended.b * sA + dB * dA * (1.0 - sA)) / outA
                            
                            canvasBuffer[dstIndex] = UInt8(max(0.0, min(1.0, outR)) * 255.0)
                            canvasBuffer[dstIndex + 1] = UInt8(max(0.0, min(1.0, outG)) * 255.0)
                            canvasBuffer[dstIndex + 2] = UInt8(max(0.0, min(1.0, outB)) * 255.0)
                            canvasBuffer[dstIndex + 3] = UInt8(max(0.0, min(1.0, outA)) * 255.0)
                        }
                    }
                }
            }
        }
        
        return Data(canvasBuffer)
    }
    
    /// Generates a CGImage from the composited document
    public func renderCGImage(document: LuminaDocument) -> CGImage? {
        let w = document.configuration.width
        let h = document.configuration.height
        let buffer = compositeToBuffer(document: document)
        
        let colorSpace = document.configuration.colorSpace.cgColorSpace
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let provider = CGDataProvider(data: buffer as CFData) else { return nil }
        
        return CGImage(
            width: w,
            height: h,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: w * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    }
}
