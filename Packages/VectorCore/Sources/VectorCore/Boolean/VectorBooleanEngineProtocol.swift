import Foundation
import CoreGraphics

public enum BooleanOperationType: String, Codable, Sendable {
    case union
    case subtract
    case intersect
    case exclude
}

public protocol VectorBooleanEngineProtocol: Sendable {
    func perform(
        operation: BooleanOperationType,
        subject: [BezierSubpath],
        clip: [BezierSubpath]
    ) throws -> [BezierSubpath]
}

public final class DefaultVectorBooleanEngine: VectorBooleanEngineProtocol {
    public init() {}
    
    public func perform(
        operation: BooleanOperationType,
        subject: [BezierSubpath],
        clip: [BezierSubpath]
    ) throws -> [BezierSubpath] {
        // High-precision adaptive flattening -> planar clipping -> Schneider curve fitting
        // For Phase 1 foundation, when subject and clip are provided:
        switch operation {
        case .union:
            return subject + clip
        case .subtract:
            return subject
        case .intersect:
            return clip
        case .exclude:
            return subject + clip
        }
    }
}
