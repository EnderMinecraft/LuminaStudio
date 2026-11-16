import Foundation
import CoreGraphics

public enum HandleMode: String, Codable, Sendable {
    case corner
    case smooth
    case symmetric
}

public struct AnchorPoint: Codable, Sendable, Equatable {
    public var id: UUID
    public var position: CGPoint
    public var inHandle: CGPoint?
    public var outHandle: CGPoint?
    public var handleMode: HandleMode
    
    public init(
        id: UUID = UUID(),
        position: CGPoint,
        inHandle: CGPoint? = nil,
        outHandle: CGPoint? = nil,
        handleMode: HandleMode = .corner
    ) {
        self.id = id
        self.position = position
        self.inHandle = inHandle
        self.outHandle = outHandle
        self.handleMode = handleMode
    }
}
