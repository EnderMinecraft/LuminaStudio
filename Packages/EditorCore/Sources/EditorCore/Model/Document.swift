import Foundation
import CoreGraphics

public final class LuminaDocument: Codable, @unchecked Sendable, Identifiable {
    public var id: UUID
    public var title: String
    public var configuration: CanvasConfiguration
    public var layers: [Layer]
    public var activeLayerID: UUID?
    public var createdAt: Date
    public var modifiedAt: Date
    
    public init(
        id: UUID = UUID(),
        title: String = "Untitled",
        configuration: CanvasConfiguration = CanvasConfiguration(),
        layers: [Layer] = [],
        activeLayerID: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.configuration = configuration
        self.layers = layers
        self.activeLayerID = activeLayerID ?? layers.first?.id
        self.createdAt = Date()
        self.modifiedAt = Date()
        
        if self.layers.isEmpty {
            createDefaultBackgroundLayer()
        }
    }
    
    public var activeLayer: Layer? {
        guard let id = activeLayerID else { return layers.first }
        return layers.first(where: { $0.id == id })
    }
    
    public func createDefaultBackgroundLayer() {
        let (r, g, b, a) = configuration.backgroundColor.rgba
        let w = configuration.width
        let h = configuration.height
        
        var pixelBuffer = Data(count: w * h * 4)
        pixelBuffer.withUnsafeMutableBytes { ptr in
            guard let bytes = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
            let rByte = UInt8(r * 255.0)
            let gByte = UInt8(g * 255.0)
            let bByte = UInt8(b * 255.0)
            let aByte = UInt8(a * 255.0)
            for i in 0..<(w * h) {
                let offset = i * 4
                bytes[offset] = rByte
                bytes[offset + 1] = gByte
                bytes[offset + 2] = bByte
                bytes[offset + 3] = aByte
            }
        }
        
        let bgLayer = Layer(
            id: UUID(),
            name: "Background",
            opacity: 1.0,
            blendMode: .normal,
            isVisible: true,
            isLocked: false,
            transform: .identity,
            mask: nil,
            kind: .raster(assetID: nil),
            rawPixelData: pixelBuffer,
            pixelWidth: w,
            pixelHeight: h
        )
        layers = [bgLayer]
        activeLayerID = bgLayer.id
    }
    
    // MARK: - Layer Operations
    
    @discardableResult
    public func addLayer(_ layer: Layer) -> Layer {
        layers.append(layer)
        activeLayerID = layer.id
        modifiedAt = Date()
        return layer
    }
    
    public func insertLayer(_ layer: Layer, at index: Int) {
        let safeIndex = max(0, min(index, layers.count))
        layers.insert(layer, at: safeIndex)
        activeLayerID = layer.id
        modifiedAt = Date()
    }
    
    @discardableResult
    public func removeLayer(byID id: UUID) -> Layer? {
        guard let index = layers.firstIndex(where: { $0.id == id }) else { return nil }
        let removed = layers.remove(at: index)
        if activeLayerID == id {
            let nextIndex = min(index, max(0, layers.count - 1))
            activeLayerID = layers.indices.contains(nextIndex) ? layers[nextIndex].id : nil
        }
        modifiedAt = Date()
        return removed
    }
    
    @discardableResult
    public func duplicateLayer(byID id: UUID) -> Layer? {
        guard let index = layers.firstIndex(where: { $0.id == id }) else { return nil }
        let copy = layers[index].duplicate()
        layers.insert(copy, at: index + 1)
        activeLayerID = copy.id
        modifiedAt = Date()
        return copy
    }
    
    public func moveLayer(from sourceIndex: Int, to destinationIndex: Int) {
        guard layers.indices.contains(sourceIndex) else { return }
        let layer = layers.remove(at: sourceIndex)
        let safeDest = max(0, min(destinationIndex, layers.count))
        layers.insert(layer, at: safeDest)
        modifiedAt = Date()
    }
    
    public func findLayer(byID id: UUID) -> Layer? {
        layers.first(where: { $0.id == id })
    }
    
    public func findLayerIndex(byID id: UUID) -> Int? {
        layers.firstIndex(where: { $0.id == id })
    }
}
