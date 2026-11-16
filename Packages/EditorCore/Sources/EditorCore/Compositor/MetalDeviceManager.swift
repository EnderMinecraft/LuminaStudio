import Foundation
import Metal

#if canImport(MetalKit)
import MetalKit
#endif

public final class MetalDeviceManager: @unchecked Sendable {
    public static let shared = MetalDeviceManager()
    
    public let device: MTLDevice?
    public let commandQueue: MTLCommandQueue?
    public let defaultPixelFormat: MTLPixelFormat
    
    private init() {
        if let dev = MTLCreateSystemDefaultDevice() {
            self.device = dev
            self.commandQueue = dev.makeCommandQueue()
            self.defaultPixelFormat = .bgra8Unorm
        } else {
            self.device = nil
            self.commandQueue = nil
            self.defaultPixelFormat = .bgra8Unorm
        }
    }
    
    public var isMetalAvailable: Bool {
        device != nil && commandQueue != nil
    }
    
    public func makeTexture(width: Int, height: Int, pixelFormat: MTLPixelFormat = .bgra8Unorm) -> MTLTexture? {
        guard let device = device else { return nil }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: pixelFormat,
            width: max(1, width),
            height: max(1, height),
            mipmapped: false
        )
        descriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        descriptor.storageMode = .shared
        return device.makeTexture(descriptor: descriptor)
    }
}
