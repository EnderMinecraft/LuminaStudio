import Foundation
import CoreGraphics

public enum SplitDirection: String, Codable, Sendable {
    case horizontal // Splits top and bottom
    case vertical   // Splits left and right
}

public indirect enum CollageLayoutNode: Codable, Sendable, Equatable {
    case leaf(id: UUID, cell: CollageCell)
    case split(id: UUID, direction: SplitDirection, ratio: Double, first: CollageLayoutNode, second: CollageLayoutNode)
    
    public var id: UUID {
        switch self {
        case .leaf(let id, _): return id
        case .split(let id, _, _, _, _): return id
        }
    }
    
    public var leafCount: Int {
        switch self {
        case .leaf:
            return 1
        case .split(_, _, _, let first, let second):
            return first.leafCount + second.leafCount
        }
    }
    
    public func allCells() -> [CollageCell] {
        switch self {
        case .leaf(_, let cell):
            return [cell]
        case .split(_, _, _, let first, let second):
            return first.allCells() + second.allCells()
        }
    }
}
