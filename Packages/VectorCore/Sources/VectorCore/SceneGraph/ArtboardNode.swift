import Foundation
import CoreGraphics

public struct ArtboardNode: Codable, Sendable, Identifiable, Equatable {
    public var id: UUID
    public var name: String
    public var size: CGSize
    public var backgroundColorHex: String
    public var children: [VectorNode]
    
    public init(
        id: UUID = UUID(),
        name: String = "Artboard 1",
        size: CGSize = CGSize(width: 1920, height: 1080),
        backgroundColorHex: String = "#FFFFFF",
        children: [VectorNode] = []
    ) {
        self.id = id
        self.name = name
        self.size = size
        self.backgroundColorHex = backgroundColorHex
        self.children = children
    }
}

public final class VectorDocument: Codable, @unchecked Sendable, Identifiable {
    public var id: UUID
    public var title: String
    public var artboards: [ArtboardNode]
    public var selectedNodeIDs: [UUID]
    public var createdAt: Date
    public var modifiedAt: Date
    
    public init(
        id: UUID = UUID(),
        title: String = "Untitled Vector",
        artboards: [ArtboardNode] = [ArtboardNode()],
        selectedNodeIDs: [UUID] = []
    ) {
        self.id = id
        self.title = title
        self.artboards = artboards
        self.selectedNodeIDs = selectedNodeIDs
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
    
    public var activeArtboard: ArtboardNode? {
        artboards.first
    }
}
