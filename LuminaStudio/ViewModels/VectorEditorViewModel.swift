import Foundation
import SwiftUI
import CoreGraphics
import VectorCore
import EditorCore

public enum VectorTool: String, CaseIterable, Identifiable, Sendable {
    case select = "Select"
    case directSelect = "Direct Select"
    case pen = "Pen"
    case pencil = "Pencil"
    case shape = "Shape"
    case text = "Text"
    case eyedropper = "Eyedropper"
    
    public var id: String { rawValue }
    
    public var systemImage: String {
        switch self {
        case .select: return "arrow.up.left.and.arrow.down.right"
        case .directSelect: return "cursorarrow"
        case .pen: return "pencil.tip"
        case .pencil: return "pencil"
        case .shape: return "square.on.circle"
        case .text: return "textformat"
        case .eyedropper: return "eyedropper.halffull"
        }
    }
}

public enum VectorShapeType: String, CaseIterable, Identifiable, Sendable {
    case rect = "Rectangle"
    case roundedRect = "Rounded Rect"
    case ellipse = "Ellipse"
    case polygon = "Polygon"
    case star = "Star"
    case line = "Line"
    
    public var id: String { rawValue }
    
    public var systemImage: String {
        switch self {
        case .rect: return "rectangle"
        case .roundedRect: return "app"
        case .ellipse: return "circle"
        case .polygon: return "hexagon"
        case .star: return "star"
        case .line: return "line.diagonal"
        }
    }
}

@Observable
public final class VectorEditorViewModel: @unchecked Sendable {
    public var document: VectorDocument
    public let commandManager: CommandManager
    
    // Tools
    public var activeTool: VectorTool = .select
    public var activeShapeType: VectorShapeType = .rect
    public var selectedNodeIDs: Set<UUID> = []
    public var selectedAnchorID: UUID? = nil
    
    // Appearance defaults
    public var fillColorHex: String = "#3B82F6"
    public var strokeColorHex: String = "#1E40AF"
    public var strokeWidth: CGFloat = 3.0
    public var opacity: Float = 1.0
    
    // Viewport
    public var zoomScale: CGFloat = 1.0
    public var panOffset: CGPoint = .zero
    
    // Active drafting states
    public var penPoints: [AnchorPoint] = []
    public var pencilPoints: [CGPoint] = []
    public var activeDragRect: CGRect? = nil
    
    // Modals
    public var isExportSheetPresented: Bool = false
    public var isTraceSheetPresented: Bool = false
    public var statusMessage: String = "Vector Studio Ready"
    
    // Cross-workspace callback
    public var onSendToPhoto: ((_ pixelBuffer: [UInt8], _ size: CGSize) -> Void)?
    
    public init(document: VectorDocument, commandManager: CommandManager) {
        self.document = document
        self.commandManager = commandManager
        
        // Ensure at least one demo shape is available if document is blank
        if let artboard = document.activeArtboard, artboard.children.isEmpty {
            let starShape = ParametricShapeNode(
                name: "Star",
                kind: .star,
                frame: CGRect(x: 400, y: 300, width: 250, height: 250),
                fillColorHex: "#F59E0B",
                strokeColorHex: "#B45309",
                strokeWidth: 4.0
            )
            let circleShape = ParametricShapeNode(
                name: "Circle",
                kind: .ellipse,
                frame: CGRect(x: 750, y: 300, width: 250, height: 250),
                fillColorHex: "#3B82F6",
                strokeColorHex: "#1D4ED8",
                strokeWidth: 4.0
            )
            document.artboards[0].children.append(.parametric(starShape))
            document.artboards[0].children.append(.parametric(circleShape))
        }
    }
    
    // MARK: - Node Operations
    
    public func selectNode(_ id: UUID, toggle: Bool = false) {
        if toggle {
            if selectedNodeIDs.contains(id) {
                selectedNodeIDs.remove(id)
            } else {
                selectedNodeIDs.insert(id)
            }
        } else {
            selectedNodeIDs = [id]
        }
    }
    
    public func deselectAll() {
        selectedNodeIDs.removeAll()
        selectedAnchorID = nil
        penPoints.removeAll()
        pencilPoints.removeAll()
    }
    
    public func deleteSelectedNodes() {
        guard !selectedNodeIDs.isEmpty, var artboard = document.activeArtboard else { return }
        let toRemove = selectedNodeIDs
        artboard.children.removeAll { toRemove.contains($0.id) }
        document.artboards[0] = artboard
        selectedNodeIDs.removeAll()
        statusMessage = "Deleted selected nodes"
    }
    
    // MARK: - Pen Tool Actions
    
    public func addPenPoint(at position: CGPoint, handleMode: HandleMode = .corner) {
        let anchor = AnchorPoint(position: position, handleMode: handleMode)
        penPoints.append(anchor)
        statusMessage = "Pen: Added point (\(Int(position.x)), \(Int(position.y)))"
    }
    
    public func finishPenPath(isClosed: Bool) {
        guard penPoints.count >= 2, var artboard = document.activeArtboard else {
            penPoints.removeAll()
            return
        }
        
        let subpath = BezierSubpath(isClosed: isClosed, points: penPoints)
        let pathNode = PathNode(
            name: "Path \(artboard.children.count + 1)",
            subpaths: [subpath],
            fillColorHex: isClosed ? fillColorHex : nil,
            strokeColorHex: strokeColorHex,
            strokeWidth: strokeWidth,
            opacity: opacity
        )
        artboard.children.append(.path(pathNode))
        document.artboards[0] = artboard
        penPoints.removeAll()
        statusMessage = "Created path"
    }
    
    // MARK: - Pencil Tool Actions
    
    public func addPencilSample(at point: CGPoint) {
        pencilPoints.append(point)
    }
    
    public func finishPencilStroke(smoothing: CGFloat = 2.0) {
        guard pencilPoints.count >= 2, var artboard = document.activeArtboard else {
            pencilPoints.removeAll()
            return
        }
        
        let simplified = CurveFitting.simplifyRDP(points: pencilPoints, epsilon: smoothing)
        let subpath = CurveFitting.fitSubpath(points: simplified, maxError: smoothing * 1.5, isClosed: false)
        
        let pathNode = PathNode(
            name: "Pencil Stroke",
            subpaths: [subpath],
            fillColorHex: nil,
            strokeColorHex: strokeColorHex,
            strokeWidth: strokeWidth,
            opacity: opacity
        )
        artboard.children.append(.path(pathNode))
        document.artboards[0] = artboard
        pencilPoints.removeAll()
        statusMessage = "Created pencil stroke"
    }
    
    // MARK: - Shape Creation
    
    public func addShape(frame: CGRect) {
        guard var artboard = document.activeArtboard else { return }
        let kind: ParametricShapeNode.ShapeKind
        switch activeShapeType {
        case .rect: kind = .rect
        case .roundedRect: kind = .roundedRect
        case .ellipse: kind = .ellipse
        case .polygon: kind = .polygon
        case .star: kind = .star
        case .line: kind = .line
        }
        
        let shape = ParametricShapeNode(
            name: activeShapeType.rawValue,
            kind: kind,
            frame: frame,
            cornerRadius: 16.0,
            polygonSides: 6,
            fillColorHex: fillColorHex,
            strokeColorHex: strokeColorHex,
            strokeWidth: strokeWidth,
            opacity: opacity
        )
        artboard.children.append(.parametric(shape))
        document.artboards[0] = artboard
        statusMessage = "Created \(activeShapeType.rawValue)"
    }
    
    // MARK: - Boolean Operations
    
    public func performBoolean(operation: BooleanOperationType) {
        guard let artboard = document.activeArtboard, selectedNodeIDs.count >= 2 else {
            statusMessage = "Select at least 2 paths to perform boolean operations"
            return
        }
        
        var selectedPaths: [PathNode] = []
        for child in artboard.children {
            if selectedNodeIDs.contains(child.id) {
                if case .path(let p) = child {
                    selectedPaths.append(p)
                } else if case .parametric(let s) = child {
                    // Convert parametric shape to path
                    let cgPath = VectorRenderEngine.shared.createParametricPath(node: s)
                    let pNode = PathNode(
                        name: s.name,
                        subpaths: [BezierSubpath(isClosed: true, points: [
                            AnchorPoint(position: s.frame.origin),
                            AnchorPoint(position: CGPoint(x: s.frame.maxX, y: s.frame.minY)),
                            AnchorPoint(position: CGPoint(x: s.frame.maxX, y: s.frame.maxY)),
                            AnchorPoint(position: CGPoint(x: s.frame.minX, y: s.frame.maxY))
                        ])],
                        fillColorHex: s.fillColorHex,
                        strokeColorHex: s.strokeColorHex,
                        strokeWidth: s.strokeWidth,
                        opacity: s.opacity
                    )
                    selectedPaths.append(pNode)
                }
            }
        }
        
        guard selectedPaths.count >= 2 else {
            statusMessage = "Boolean operations require vector paths"
            return
        }
        
        let subject = selectedPaths[0].subpaths
        let clip = selectedPaths[1].subpaths
        
        do {
            let resultSubpaths = try VectorBooleanEngine.shared.perform(operation: operation, subject: subject, clip: clip)
            var newArtboard = artboard
            let idsToRemove = selectedNodeIDs
            newArtboard.children.removeAll { idsToRemove.contains($0.id) }
            
            let combined = PathNode(
                name: "\(operation.rawValue.capitalized) Path",
                subpaths: resultSubpaths,
                fillColorHex: selectedPaths[0].fillColorHex ?? fillColorHex,
                strokeColorHex: selectedPaths[0].strokeColorHex,
                strokeWidth: selectedPaths[0].strokeWidth,
                opacity: selectedPaths[0].opacity
            )
            newArtboard.children.append(.path(combined))
            document.artboards[0] = newArtboard
            selectedNodeIDs = [combined.id]
            statusMessage = "Boolean \(operation.rawValue) applied"
        } catch {
            statusMessage = "Boolean failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Alignment
    
    public func alignSelected(alignment: AlignmentType) {
        guard var artboard = document.activeArtboard, selectedNodeIDs.count >= 2 else { return }
        // Compute bounding box of selection
        var minX: CGFloat = .greatestFiniteMagnitude
        var maxX: CGFloat = -.greatestFiniteMagnitude
        var minY: CGFloat = .greatestFiniteMagnitude
        var maxY: CGFloat = -.greatestFiniteMagnitude
        
        for child in artboard.children where selectedNodeIDs.contains(child.id) {
            let frame = getNodeFrame(child)
            minX = min(minX, frame.minX)
            maxX = max(maxX, frame.maxX)
            minY = min(minY, frame.minY)
            maxY = max(maxY, frame.maxY)
        }
        
        let selFrame = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        
        for i in 0..<artboard.children.count {
            let child = artboard.children[i]
            guard selectedNodeIDs.contains(child.id) else { continue }
            artboard.children[i] = applyAlignment(node: child, selFrame: selFrame, type: alignment)
        }
        document.artboards[0] = artboard
        statusMessage = "Aligned \(alignment)"
    }
    
    public enum AlignmentType: String, CaseIterable, Identifiable {
        case left, centerX, right, top, centerY, bottom
        public var id: String { rawValue }
    }
    
    private func getNodeFrame(_ node: VectorNode) -> CGRect {
        switch node {
        case .path(let p):
            var box: CGRect = .null
            for sub in p.subpaths {
                box = box.union(sub.boundingBox)
            }
            return box.isNull ? CGRect(x: 0, y: 0, width: 100, height: 100) : box
        case .parametric(let s):
            return s.frame
        case .text(let t):
            return CGRect(origin: t.origin, size: CGSize(width: t.fontSize * CGFloat(t.text.count) * 0.6, height: t.fontSize))
        case .group(let g):
            var box: CGRect = .null
            for c in g.children {
                box = box.union(getNodeFrame(c))
            }
            return box.isNull ? .zero : box
        }
    }
    
    private func applyAlignment(node: VectorNode, selFrame: CGRect, type: AlignmentType) -> VectorNode {
        let frame = getNodeFrame(node)
        var dx: CGFloat = 0
        var dy: CGFloat = 0
        
        switch type {
        case .left: dx = selFrame.minX - frame.minX
        case .centerX: dx = selFrame.midX - frame.midX
        case .right: dx = selFrame.maxX - frame.maxX
        case .top: dy = selFrame.minY - frame.minY
        case .centerY: dy = selFrame.midY - frame.midY
        case .bottom: dy = selFrame.maxY - frame.maxY
        }
        
        return offsetNode(node, dx: dx, dy: dy)
    }
    
    private func offsetNode(_ node: VectorNode, dx: CGFloat, dy: CGFloat) -> VectorNode {
        switch node {
        case .path(var p):
            for i in 0..<p.subpaths.count {
                for j in 0..<p.subpaths[i].points.count {
                    p.subpaths[i].points[j].position.x += dx
                    p.subpaths[i].points[j].position.y += dy
                    if let inH = p.subpaths[i].points[j].inHandle {
                        p.subpaths[i].points[j].inHandle = CGPoint(x: inH.x + dx, y: inH.y + dy)
                    }
                    if let outH = p.subpaths[i].points[j].outHandle {
                        p.subpaths[i].points[j].outHandle = CGPoint(x: outH.x + dx, y: outH.y + dy)
                    }
                }
            }
            return .path(p)
        case .parametric(var s):
            s.frame.origin.x += dx
            s.frame.origin.y += dy
            return .parametric(s)
        case .text(var t):
            t.origin.x += dx
            t.origin.y += dy
            return .text(t)
        case .group(var g):
            g.children = g.children.map { offsetNode($0, dx: dx, dy: dy) }
            return .group(g)
        }
    }
    
    // MARK: - Cross-Workspace Actions
    
    public func sendToPhotoWorkspace() {
        guard let artboard = document.activeArtboard else { return }
        let (buffer, size) = VectorRenderEngine.shared.renderArtboard(artboard, scale: 1.0)
        onSendToPhoto?(buffer, size)
        statusMessage = "Rendered and sent to Photo Workspace"
    }
}
