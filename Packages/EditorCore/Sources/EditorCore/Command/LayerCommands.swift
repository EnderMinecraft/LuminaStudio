import Foundation

public final class AddLayerCommand: Command, @unchecked Sendable {
    public let name: String
    public let estimatedMemoryBytes: Int
    private let document: LuminaDocument
    private let layer: Layer
    private let insertionIndex: Int
    
    public init(document: LuminaDocument, layer: Layer, insertionIndex: Int? = nil) {
        self.document = document
        self.layer = layer
        self.insertionIndex = insertionIndex ?? document.layers.count
        self.name = "Add Layer '\(layer.name)'"
        self.estimatedMemoryBytes = layer.rawPixelData?.count ?? 1024
    }
    
    public func execute() async throws {
        document.insertLayer(layer, at: insertionIndex)
    }
    
    public func undo() async throws {
        document.removeLayer(byID: layer.id)
    }
}

public final class RemoveLayerCommand: Command, @unchecked Sendable {
    public let name: String
    public let estimatedMemoryBytes: Int
    private let document: LuminaDocument
    private let layer: Layer
    private let originalIndex: Int
    
    public init(document: LuminaDocument, layerID: UUID) throws {
        guard let index = document.findLayerIndex(byID: layerID),
              let foundLayer = document.findLayer(byID: layerID) else {
            throw NSError(domain: "Lumina", code: 404, userInfo: [NSLocalizedDescriptionKey: "Layer not found"])
        }
        self.document = document
        self.layer = foundLayer
        self.originalIndex = index
        self.name = "Delete Layer '\(foundLayer.name)'"
        self.estimatedMemoryBytes = foundLayer.rawPixelData?.count ?? 1024
    }
    
    public func execute() async throws {
        document.removeLayer(byID: layer.id)
    }
    
    public func undo() async throws {
        document.insertLayer(layer, at: originalIndex)
    }
}

public final class DuplicateLayerCommand: Command, @unchecked Sendable {
    public let name: String
    public let estimatedMemoryBytes: Int
    private let document: LuminaDocument
    private let sourceLayerID: UUID
    private var duplicatedLayerID: UUID?
    
    public init(document: LuminaDocument, sourceLayerID: UUID) {
        self.document = document
        self.sourceLayerID = sourceLayerID
        let srcName = document.findLayer(byID: sourceLayerID)?.name ?? "Layer"
        self.name = "Duplicate Layer '\(srcName)'"
        self.estimatedMemoryBytes = document.findLayer(byID: sourceLayerID)?.rawPixelData?.count ?? 1024
    }
    
    public func execute() async throws {
        if let copy = document.duplicateLayer(byID: sourceLayerID) {
            duplicatedLayerID = copy.id
        }
    }
    
    public func undo() async throws {
        if let id = duplicatedLayerID {
            document.removeLayer(byID: id)
        }
    }
}

public final class ReorderLayerCommand: Command, @unchecked Sendable {
    public let name: String
    public let estimatedMemoryBytes: Int = 128
    private let document: LuminaDocument
    private let fromIndex: Int
    private let toIndex: Int
    
    public init(document: LuminaDocument, fromIndex: Int, toIndex: Int) {
        self.document = document
        self.fromIndex = fromIndex
        self.toIndex = toIndex
        self.name = "Reorder Layer"
    }
    
    public func execute() async throws {
        document.moveLayer(from: fromIndex, to: toIndex)
    }
    
    public func undo() async throws {
        document.moveLayer(from: toIndex, to: fromIndex)
    }
}

public final class SetOpacityCommand: Command, @unchecked Sendable {
    public let name: String
    public let estimatedMemoryBytes: Int = 64
    private let layer: Layer
    private let oldOpacity: Float
    private let newOpacity: Float
    
    public init(layer: Layer, newOpacity: Float) {
        self.layer = layer
        self.oldOpacity = layer.opacity
        self.newOpacity = newOpacity
        self.name = "Change Opacity"
    }
    
    public func execute() async throws {
        layer.opacity = newOpacity
    }
    
    public func undo() async throws {
        layer.opacity = oldOpacity
    }
}

public final class SetVisibilityCommand: Command, @unchecked Sendable {
    public let name: String
    public let estimatedMemoryBytes: Int = 64
    private let layer: Layer
    private let oldVisible: Bool
    private let newVisible: Bool
    
    public init(layer: Layer, isVisible: Bool) {
        self.layer = layer
        self.oldVisible = layer.isVisible
        self.newVisible = isVisible
        self.name = isVisible ? "Show Layer" : "Hide Layer"
    }
    
    public func execute() async throws {
        layer.isVisible = newVisible
    }
    
    public func undo() async throws {
        layer.isVisible = oldVisible
    }
}

public final class SetBlendModeCommand: Command, @unchecked Sendable {
    public let name: String
    public let estimatedMemoryBytes: Int = 64
    private let layer: Layer
    private let oldMode: LuminaBlendMode
    private let newMode: LuminaBlendMode
    
    public init(layer: Layer, newMode: LuminaBlendMode) {
        self.layer = layer
        self.oldMode = layer.blendMode
        self.newMode = newMode
        self.name = "Change Blend Mode to \(newMode.rawValue)"
    }
    
    public func execute() async throws {
        layer.blendMode = newMode
    }
    
    public func undo() async throws {
        layer.blendMode = oldMode
    }
}

public final class RenameLayerCommand: Command, @unchecked Sendable {
    public let name: String
    public let estimatedMemoryBytes: Int = 64
    private let layer: Layer
    private let oldName: String
    private let newName: String
    
    public init(layer: Layer, newName: String) {
        self.layer = layer
        self.oldName = layer.name
        self.newName = newName
        self.name = "Rename Layer"
    }
    
    public func execute() async throws {
        layer.name = newName
    }
    
    public func undo() async throws {
        layer.name = oldName
    }
}

public final class ToggleLockCommand: Command, @unchecked Sendable {
    public let name: String
    public let estimatedMemoryBytes: Int = 64
    private let layer: Layer
    private let oldLocked: Bool
    
    public init(layer: Layer) {
        self.layer = layer
        self.oldLocked = layer.isLocked
        self.name = layer.isLocked ? "Unlock Layer" : "Lock Layer"
    }
    
    public func execute() async throws {
        layer.isLocked = !oldLocked
    }
    
    public func undo() async throws {
        layer.isLocked = oldLocked
    }
}
