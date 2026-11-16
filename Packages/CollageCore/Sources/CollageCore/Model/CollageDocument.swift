import Foundation
import CoreGraphics

public final class CollageDocument: Codable, @unchecked Sendable, Identifiable {
    public var id: UUID
    public var title: String
    public var rootNode: CollageLayoutNode
    public var aspectRatioPreset: AspectRatioPreset
    public var cellSpacing: CGFloat
    public var outerMargin: CGFloat
    public var cornerRadius: CGFloat
    public var backgroundColorHex: String
    public var createdAt: Date
    public var modifiedAt: Date
    
    public init(
        id: UUID = UUID(),
        title: String = "Untitled Collage",
        rootNode: CollageLayoutNode = .leaf(id: UUID(), cell: CollageCell()),
        aspectRatioPreset: AspectRatioPreset = .square,
        cellSpacing: CGFloat = 8.0,
        outerMargin: CGFloat = 16.0,
        cornerRadius: CGFloat = 8.0,
        backgroundColorHex: String = "#FFFFFF"
    ) {
        self.id = id
        self.title = title
        self.rootNode = rootNode
        self.aspectRatioPreset = aspectRatioPreset
        self.cellSpacing = cellSpacing
        self.outerMargin = outerMargin
        self.cornerRadius = cornerRadius
        self.backgroundColorHex = backgroundColorHex
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}
