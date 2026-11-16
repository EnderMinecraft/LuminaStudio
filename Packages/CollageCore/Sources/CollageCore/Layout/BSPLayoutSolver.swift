import Foundation
import CoreGraphics

public struct SolvedCellLayout: Sendable, Equatable {
    public let cellID: UUID
    public let rect: CGRect
    public let cell: CollageCell
    
    public init(cellID: UUID, rect: CGRect, cell: CollageCell) {
        self.cellID = cellID
        self.rect = rect
        self.cell = cell
    }
}

public struct SolvedDivider: Sendable, Equatable {
    public let splitID: UUID
    public let direction: SplitDirection
    public let rect: CGRect // Hit-testable frame
    public let currentRatio: Double
    
    public init(splitID: UUID, direction: SplitDirection, rect: CGRect, currentRatio: Double) {
        self.splitID = splitID
        self.direction = direction
        self.rect = rect
        self.currentRatio = currentRatio
    }
}

public final class BSPLayoutSolver: Sendable {
    public static let shared = BSPLayoutSolver()
    
    public init() {}
    
    public func solve(
        node: CollageLayoutNode,
        in bounds: CGRect,
        spacing: CGFloat,
        margin: CGFloat
    ) -> (cells: [SolvedCellLayout], dividers: [SolvedDivider]) {
        let contentRect = bounds.insetBy(dx: margin, dy: margin)
        guard contentRect.width > 0, contentRect.height > 0 else { return ([], []) }
        
        var cells: [SolvedCellLayout] = []
        var dividers: [SolvedDivider] = []
        
        solveRecursive(
            node: node,
            rect: contentRect,
            spacing: spacing,
            cells: &cells,
            dividers: &dividers
        )
        
        return (cells, dividers)
    }
    
    private func solveRecursive(
        node: CollageLayoutNode,
        rect: CGRect,
        spacing: CGFloat,
        cells: inout [SolvedCellLayout],
        dividers: inout [SolvedDivider]
    ) {
        switch node {
        case .leaf(let id, let cell):
            cells.append(SolvedCellLayout(cellID: id, rect: rect, cell: cell))
            
        case .split(let id, let direction, let ratio, let first, let second):
            let clampedRatio = max(0.1, min(0.9, ratio))
            let halfSpacing = spacing / 2.0
            
            switch direction {
            case .vertical:
                // Splits into left and right
                let totalW = rect.width - spacing
                let w1 = totalW * CGFloat(clampedRatio)
                let w2 = totalW - w1
                
                let rect1 = CGRect(x: rect.minX, y: rect.minY, width: w1, height: rect.height)
                let dividerRect = CGRect(x: rect1.maxX, y: rect.minY, width: spacing, height: rect.height)
                let rect2 = CGRect(x: dividerRect.maxX, y: rect.minY, width: w2, height: rect.height)
                
                dividers.append(SolvedDivider(splitID: id, direction: .vertical, rect: dividerRect, currentRatio: clampedRatio))
                solveRecursive(node: first, rect: rect1, spacing: spacing, cells: &cells, dividers: &dividers)
                solveRecursive(node: second, rect: rect2, spacing: spacing, cells: &cells, dividers: &dividers)
                
            case .horizontal:
                // Splits into top and bottom
                let totalH = rect.height - spacing
                let h1 = totalH * CGFloat(clampedRatio)
                let h2 = totalH - h1
                
                let rect1 = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: h1)
                let dividerRect = CGRect(x: rect.minX, y: rect1.maxY, width: rect.width, height: spacing)
                let rect2 = CGRect(x: rect.minX, y: dividerRect.maxY, width: rect.width, height: h2)
                
                dividers.append(SolvedDivider(splitID: id, direction: .horizontal, rect: dividerRect, currentRatio: clampedRatio))
                solveRecursive(node: first, rect: rect1, spacing: spacing, cells: &cells, dividers: &dividers)
                solveRecursive(node: second, rect: rect2, spacing: spacing, cells: &cells, dividers: &dividers)
            }
        }
    }
}
