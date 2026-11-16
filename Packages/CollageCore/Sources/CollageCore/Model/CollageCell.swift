import Foundation
import CoreGraphics

public struct CollageCell: Codable, Sendable, Identifiable, Equatable {
    public var id: UUID
    public var assetID: String?
    public var contentOffset: CGPoint
    public var contentScale: Double
    public var rotationQuarterTurns: Int // 0, 1, 2, 3
    public var isFlippedHorizontally: Bool
    public var isFlippedVertically: Bool
    public var filterPresetID: String?
    public var customCornerRadius: CGFloat?
    
    public init(
        id: UUID = UUID(),
        assetID: String? = nil,
        contentOffset: CGPoint = .zero,
        contentScale: Double = 1.0,
        rotationQuarterTurns: Int = 0,
        isFlippedHorizontally: Bool = false,
        isFlippedVertically: Bool = false,
        filterPresetID: String? = nil,
        customCornerRadius: CGFloat? = nil
    ) {
        self.id = id
        self.assetID = assetID
        self.contentOffset = contentOffset
        self.contentScale = contentScale
        self.rotationQuarterTurns = rotationQuarterTurns
        self.isFlippedHorizontally = isFlippedHorizontally
        self.isFlippedVertically = isFlippedVertically
        self.filterPresetID = filterPresetID
        self.customCornerRadius = customCornerRadius
    }
}
