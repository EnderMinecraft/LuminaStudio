import Foundation

public final class CreateLayerMaskCommand: Command, @unchecked Sendable {
    public let name: String = "Add Layer Mask"
    public let estimatedMemoryBytes: Int
    private let layer: Layer
    private let mask: LayerMask
    
    public init(layer: Layer, mask: LayerMask) {
        self.layer = layer
        self.mask = mask
        self.estimatedMemoryBytes = mask.maskData.count
    }
    
    public func execute() async throws {
        layer.mask = mask
    }
    
    public func undo() async throws {
        layer.mask = nil
    }
}

public final class InvertLayerMaskCommand: Command, @unchecked Sendable {
    public let name: String = "Invert Layer Mask"
    public let estimatedMemoryBytes: Int = 64
    private let layer: Layer
    
    public init(layer: Layer) {
        self.layer = layer
    }
    
    public func execute() async throws {
        guard let mask = layer.mask else { return }
        mask.isInverted.toggle()
    }
    
    public func undo() async throws {
        guard let mask = layer.mask else { return }
        mask.isInverted.toggle()
    }
}

public final class ApplyLayerMaskCommand: Command, @unchecked Sendable {
    public let name: String = "Apply Layer Mask"
    public let estimatedMemoryBytes: Int
    private let layer: Layer
    private let previousMask: LayerMask?
    private let previousPixels: Data?
    
    public init(layer: Layer) {
        self.layer = layer
        self.previousMask = layer.mask
        self.previousPixels = layer.rawPixelData
        self.estimatedMemoryBytes = layer.rawPixelData?.count ?? 1024
    }
    
    public func execute() async throws {
        guard let mask = layer.mask, let pixelData = layer.rawPixelData,
              layer.pixelWidth > 0, layer.pixelHeight > 0 else { return }
        
        let w = layer.pixelWidth
        let h = layer.pixelHeight
        var newPixels = [UInt8](pixelData)
        
        for y in 0..<h {
            for x in 0..<w {
                let maskVal = Double(mask.sample(x: x, y: y)) / 255.0
                let idx = (y * w + x) * 4 + 3
                let oldA = Double(newPixels[idx])
                newPixels[idx] = UInt8(max(0, min(255, round(oldA * maskVal))))
            }
        }
        
        layer.rawPixelData = Data(newPixels)
        layer.mask = nil
    }
    
    public func undo() async throws {
        layer.rawPixelData = previousPixels
        layer.mask = previousMask
    }
}

public final class ToggleLayerMaskCommand: Command, @unchecked Sendable {
    public let name: String
    public let estimatedMemoryBytes: Int = 64
    private let layer: Layer
    
    public init(layer: Layer) {
        self.layer = layer
        let willEnable = !(layer.mask?.isEnabled ?? false)
        self.name = willEnable ? "Enable Layer Mask" : "Disable Layer Mask"
    }
    
    public func execute() async throws {
        layer.mask?.isEnabled.toggle()
    }
    
    public func undo() async throws {
        layer.mask?.isEnabled.toggle()
    }
}
