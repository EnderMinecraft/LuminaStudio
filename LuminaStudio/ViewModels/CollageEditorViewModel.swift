import Foundation
import SwiftUI
import CoreGraphics
import CollageCore
import EditorCore

@Observable
public final class CollageEditorViewModel: @unchecked Sendable {
    public var document: CollageDocument
    public let commandManager: CommandManager
    
    // Selection & Dragging
    public var selectedCellID: UUID? = nil
    public var draggingDividerID: UUID? = nil
    public var snappedRatioPill: String? = nil
    
    // Modals
    public var isTemplateBrowserPresented: Bool = false
    public var isExportSheetPresented: Bool = false
    public var statusMessage: String = "Collage Studio Ready"
    
    // Cross-workspace callback
    public var onOpenInPhotoEditor: ((_ cells: [SolvedCellLayout], _ canvasSize: CGSize, _ cornerRadius: CGFloat, _ bgColorHex: String) -> Void)?
    
    public init(document: CollageDocument, commandManager: CommandManager) {
        self.document = document
        self.commandManager = commandManager
        
        // Ensure starting with a 3-photo template if blank
        if document.rootNode.leafCount <= 1 {
            if let defaultTmpl = TemplateRegistry.shared.templates.first(where: { $0.photoCount == 3 && $0.category == "Hero" }) {
                document.rootNode = defaultTmpl.rootNodeBuilder()
            }
        }
    }
    
    // MARK: - Template Selection
    
    public func applyTemplate(_ template: CollageTemplate) {
        document.rootNode = template.rootNodeBuilder()
        selectedCellID = nil
        statusMessage = "Applied \(template.name)"
    }
    
    // MARK: - Divider Dragging with Magnetic Snapping
    
    public func updateDividerRatio(splitID: UUID, newRatio: Double) {
        let (updated, finalRatio, didSnap) = CollageDividerEngine.shared.updateRatio(
            in: document.rootNode,
            splitID: splitID,
            newRatio: newRatio,
            enableSnapping: true
        )
        document.rootNode = updated
        
        if didSnap {
            snappedRatioPill = "\(Int(round(finalRatio * 100)))% (Snapped)"
        } else {
            snappedRatioPill = "\(Int(round(finalRatio * 100)))%"
        }
    }
    
    public func finishDividerDrag() {
        draggingDividerID = nil
        snappedRatioPill = nil
    }
    
    // MARK: - Cell Operations
    
    public func selectCell(_ id: UUID) {
        if selectedCellID == id {
            selectedCellID = nil
        } else {
            selectedCellID = id
        }
    }
    
    public func rotateSelectedCell() {
        guard let id = selectedCellID else { return }
        document.rootNode = CollageCellEngine.shared.rotateCell90Degrees(in: document.rootNode, cellID: id)
        statusMessage = "Rotated cell 90°"
    }
    
    public func flipSelectedCell(horizontal: Bool) {
        guard let id = selectedCellID else { return }
        document.rootNode = CollageCellEngine.shared.flipCell(in: document.rootNode, cellID: id, horizontal: horizontal)
        statusMessage = horizontal ? "Flipped horizontally" : "Flipped vertically"
    }
    
    // MARK: - Cross-Workspace: Open in Photo Editor
    
    public func openInPhotoEditor() {
        let targetSize = CollageRenderEngine.shared.targetSize(for: document.aspectRatioPreset, baseDimension: 2048)
        let bounds = CGRect(origin: .zero, size: targetSize)
        let (cells, _) = BSPLayoutSolver.shared.solve(
            node: document.rootNode,
            in: bounds,
            spacing: document.cellSpacing * 2.0,
            margin: document.outerMargin * 2.0
        )
        
        onOpenInPhotoEditor?(cells, targetSize, document.cornerRadius * 2.0, document.backgroundColorHex)
        statusMessage = "Unrolled into layered Photo document"
    }
}
