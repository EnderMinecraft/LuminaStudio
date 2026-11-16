import Foundation
import CoreGraphics

public final class CollageCellEngine: Sendable {
    public static let shared = CollageCellEngine()
    
    public init() {}
    
    public func updateCell(
        in root: CollageLayoutNode,
        cellID: UUID,
        modifier: (inout CollageCell) -> Void
    ) -> CollageLayoutNode {
        switch root {
        case .leaf(let id, var cell):
            if id == cellID {
                modifier(&cell)
            }
            return .leaf(id: id, cell: cell)
            
        case .split(let id, let dir, let ratio, let first, let second):
            let newFirst = updateCell(in: first, cellID: cellID, modifier: modifier)
            let newSecond = updateCell(in: second, cellID: cellID, modifier: modifier)
            return .split(id: id, direction: dir, ratio: ratio, first: newFirst, second: newSecond)
        }
    }
    
    public func rotateCell90Degrees(in root: CollageLayoutNode, cellID: UUID) -> CollageLayoutNode {
        updateCell(in: root, cellID: cellID) { cell in
            cell.rotationQuarterTurns = (cell.rotationQuarterTurns + 1) % 4
        }
    }
    
    public func flipCell(in root: CollageLayoutNode, cellID: UUID, horizontal: Bool) -> CollageLayoutNode {
        updateCell(in: root, cellID: cellID) { cell in
            if horizontal {
                cell.isFlippedHorizontally.toggle()
            } else {
                cell.isFlippedVertically.toggle()
            }
        }
    }
    
    public func swapCells(in root: CollageLayoutNode, idA: UUID, idB: UUID) -> CollageLayoutNode {
        let all = root.allCells()
        guard let cellA = all.first(where: { $0.id == idA }),
              let cellB = all.first(where: { $0.id == idB }) else {
            return root
        }
        
        let pass1 = updateCell(in: root, cellID: idA) { cell in
            cell.assetID = cellB.assetID
            cell.contentOffset = cellB.contentOffset
            cell.contentScale = cellB.contentScale
            cell.rotationQuarterTurns = cellB.rotationQuarterTurns
            cell.isFlippedHorizontally = cellB.isFlippedHorizontally
            cell.isFlippedVertically = cellB.isFlippedVertically
            cell.filterPresetID = cellB.filterPresetID
        }
        
        let pass2 = updateCell(in: pass1, cellID: idB) { cell in
            cell.assetID = cellA.assetID
            cell.contentOffset = cellA.contentOffset
            cell.contentScale = cellA.contentScale
            cell.rotationQuarterTurns = cellA.rotationQuarterTurns
            cell.isFlippedHorizontally = cellA.isFlippedHorizontally
            cell.isFlippedVertically = cellA.isFlippedVertically
            cell.filterPresetID = cellA.filterPresetID
        }
        
        return pass2
    }
}
