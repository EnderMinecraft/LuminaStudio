import Foundation
import CoreGraphics

public final class CollageDividerEngine: Sendable {
    public static let shared = CollageDividerEngine()
    
    // Magnetic snap ratios with snap threshold
    public static let magneticRatios: [Double] = [0.25, 0.333, 0.5, 0.667, 0.75]
    public static let snapThreshold: Double = 0.025
    
    public init() {}
    
    public func updateRatio(
        in root: CollageLayoutNode,
        splitID: UUID,
        newRatio: Double,
        enableSnapping: Bool = true
    ) -> (updatedRoot: CollageLayoutNode, snappedRatio: Double, didSnap: Bool) {
        var finalRatio = max(0.1, min(0.9, newRatio))
        var didSnap = false
        
        if enableSnapping {
            for magnet in Self.magneticRatios {
                if abs(finalRatio - magnet) < Self.snapThreshold {
                    finalRatio = magnet
                    didSnap = true
                    break
                }
            }
        }
        
        let updated = updateNodeRecursive(node: root, targetID: splitID, newRatio: finalRatio)
        return (updated, finalRatio, didSnap)
    }
    
    private func updateNodeRecursive(
        node: CollageLayoutNode,
        targetID: UUID,
        newRatio: Double
    ) -> CollageLayoutNode {
        switch node {
        case .leaf:
            return node
            
        case .split(let id, let dir, let currentRatio, let first, let second):
            if id == targetID {
                return .split(id: id, direction: dir, ratio: newRatio, first: first, second: second)
            } else {
                let updatedFirst = updateNodeRecursive(node: first, targetID: targetID, newRatio: newRatio)
                let updatedSecond = updateNodeRecursive(node: second, targetID: targetID, newRatio: newRatio)
                return .split(id: id, direction: dir, ratio: currentRatio, first: updatedFirst, second: updatedSecond)
            }
        }
    }
}
