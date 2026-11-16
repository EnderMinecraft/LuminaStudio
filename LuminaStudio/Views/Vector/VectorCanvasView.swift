import SwiftUI
import CoreGraphics
import VectorCore

public struct VectorCanvasView: View {
    @Bindable var viewModel: VectorEditorViewModel
    
    @State private var dragStart: CGPoint? = nil
    @State private var dragCurrent: CGPoint? = nil
    
    public init(viewModel: VectorEditorViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Workspace background
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                if let artboard = viewModel.document.activeArtboard {
                    // Zoomable & Pannable Artboard Layer
                    ZStack(alignment: .topLeading) {
                        // Artboard Paper
                        Rectangle()
                            .fill(Color(hex: artboard.backgroundColorHex) ?? .white)
                            .frame(width: artboard.size.width, height: artboard.size.height)
                            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
                        
                        // Vector Nodes
                        ForEach(artboard.children) { node in
                            VectorNodeRendererView(node: node, isSelected: viewModel.selectedNodeIDs.contains(node.id))
                        }
                        
                        // Pen Drafting Preview
                        if !viewModel.penPoints.isEmpty {
                            PenDraftingOverlay(points: viewModel.penPoints, current: dragCurrent)
                        }
                        
                        // Pencil Drafting Preview
                        if !viewModel.pencilPoints.isEmpty {
                            PencilDraftingOverlay(points: viewModel.pencilPoints)
                        }
                        
                        // Shape Drafting Preview
                        if let rect = viewModel.activeDragRect {
                            ShapeDraftingOverlay(rect: rect, shapeType: viewModel.activeShapeType)
                        }
                        
                        // Selection Bounding Box & Handles
                        if !viewModel.selectedNodeIDs.isEmpty {
                            SelectionBoundingBoxOverlay(viewModel: viewModel, artboard: artboard)
                        }
                    }
                    .frame(width: artboard.size.width, height: artboard.size.height)
                    .scaleEffect(viewModel.zoomScale)
                    .offset(x: viewModel.panOffset.x, y: viewModel.panOffset.y)
                    .gesture(canvasDragGesture(artboard: artboard))
                }
            }
        }
    }
    
    // MARK: - Gesture Handling
    
    private func canvasDragGesture(artboard: ArtboardNode) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let localPoint = screenToCanvas(value.location, artboard: artboard)
                
                switch viewModel.activeTool {
                case .pencil:
                    viewModel.addPencilSample(at: localPoint)
                case .shape:
                    if dragStart == nil { dragStart = localPoint }
                    dragCurrent = localPoint
                    if let start = dragStart {
                        let rect = CGRect(
                            x: min(start.x, localPoint.x),
                            y: min(start.y, localPoint.y),
                            width: max(10, abs(localPoint.x - start.x)),
                            height: max(10, abs(localPoint.y - start.y))
                        )
                        viewModel.activeDragRect = rect
                    }
                case .select:
                    if let firstSelected = viewModel.selectedNodeIDs.first {
                        // Drag node
                        if dragStart == nil { dragStart = localPoint }
                    }
                default:
                    break
                }
            }
            .onEnded { value in
                let localPoint = screenToCanvas(value.location, artboard: artboard)
                
                switch viewModel.activeTool {
                case .pen:
                    viewModel.addPenPoint(at: localPoint)
                case .pencil:
                    viewModel.finishPencilStroke()
                case .shape:
                    if let rect = viewModel.activeDragRect {
                        viewModel.addShape(frame: rect)
                        viewModel.activeDragRect = nil
                    }
                    dragStart = nil
                    dragCurrent = nil
                case .select:
                    // Check tap on nodes if distance is small
                    if value.translation.width * value.translation.width + value.translation.height * value.translation.height < 25 {
                        hitTestNode(at: localPoint, in: artboard)
                    }
                    dragStart = nil
                default:
                    break
                }
            }
    }
    
    private func hitTestNode(at point: CGPoint, in artboard: ArtboardNode) {
        for node in artboard.children.reversed() {
            if hitTest(node: node, point: point) {
                viewModel.selectNode(node.id)
                return
            }
        }
        viewModel.deselectAll()
    }
    
    private func hitTest(node: VectorNode, point: CGPoint) -> Bool {
        switch node {
        case .path(let p):
            for sub in p.subpaths {
                if sub.boundingBox.insetBy(dx: -10, dy: -10).contains(point) {
                    return true
                }
            }
            return false
        case .parametric(let s):
            return s.frame.insetBy(dx: -10, dy: -10).contains(point)
        case .text(let t):
            let box = CGRect(origin: t.origin, size: CGSize(width: t.fontSize * CGFloat(t.text.count) * 0.6, height: t.fontSize))
            return box.contains(point)
        case .group(let g):
            return g.children.contains { hitTest(node: $0, point: point) }
        }
    }
    
    private func screenToCanvas(_ screenPoint: CGPoint, artboard: ArtboardNode) -> CGPoint {
        // Un-scale and un-offset to artboard coordinate space
        let originX = (screenPoint.x - viewModel.panOffset.x) / viewModel.zoomScale
        let originY = (screenPoint.y - viewModel.panOffset.y) / viewModel.zoomScale
        return CGPoint(x: max(0, min(artboard.size.width, originX)), y: max(0, min(artboard.size.height, originY)))
    }
}

// MARK: - Node Subview Renderers

private struct VectorNodeRendererView: View {
    let node: VectorNode
    let isSelected: Bool
    
    var body: some View {
        switch node {
        case .path(let pathNode):
            let path = createSwiftUIPath(from: pathNode.subpaths)
            ZStack {
                if let fillHex = pathNode.fillColorHex, let color = Color(hex: fillHex) {
                    path.fill(color)
                }
                if pathNode.strokeWidth > 0, let strokeHex = pathNode.strokeColorHex, let color = Color(hex: strokeHex) {
                    path.stroke(color, lineWidth: pathNode.strokeWidth)
                }
            }
            .opacity(Double(pathNode.opacity))
            
        case .parametric(let s):
            let path = Path(VectorRenderEngine.shared.createParametricPath(node: s))
            ZStack {
                if let fillHex = s.fillColorHex, let color = Color(hex: fillHex) {
                    path.fill(color)
                }
                if s.strokeWidth > 0, let strokeHex = s.strokeColorHex, let color = Color(hex: strokeHex) {
                    path.stroke(color, lineWidth: s.strokeWidth)
                }
            }
            .opacity(Double(s.opacity))
            
        case .text(let t):
            Text(t.text)
                .font(.custom(t.fontName, size: t.fontSize))
                .foregroundColor(Color(hex: t.fillColorHex) ?? .black)
                .opacity(Double(t.opacity))
                .position(x: t.origin.x + (t.fontSize * CGFloat(t.text.count) * 0.3), y: t.origin.y + t.fontSize / 2.0)
            
        case .group(let g):
            ForEach(g.children) { child in
                VectorNodeRendererView(node: child, isSelected: false)
            }
            .opacity(Double(g.opacity))
        }
    }
    
    private func createSwiftUIPath(from subpaths: [BezierSubpath]) -> Path {
        var path = Path()
        for sub in subpaths {
            guard !sub.points.isEmpty else { continue }
            let pts = sub.points
            path.move(to: pts[0].position)
            for i in 0..<(pts.count - 1) {
                let curr = pts[i]
                let next = pts[i + 1]
                let c1 = curr.outHandle ?? curr.position
                let c2 = next.inHandle ?? next.position
                path.addCurve(to: next.position, control1: c1, control2: c2)
            }
            if sub.isClosed && pts.count > 1 {
                let last = pts.last!
                let first = pts.first!
                let c1 = last.outHandle ?? last.position
                let c2 = first.inHandle ?? first.position
                path.addCurve(to: first.position, control1: c1, control2: c2)
                path.closeSubpath()
            }
        }
        return path
    }
}

// MARK: - Drafting Overlays

private struct PenDraftingOverlay: View {
    let points: [AnchorPoint]
    let current: CGPoint?
    
    var body: some View {
        Canvas { context, _ in
            guard !points.isEmpty else { return }
            var path = Path()
            path.move(to: points[0].position)
            for i in 1..<points.count {
                path.addLine(to: points[i].position)
            }
            if let curr = current {
                path.addLine(to: curr)
            }
            context.stroke(path, with: .color(.blue), lineWidth: 2)
            
            // Draw anchor points
            for pt in points {
                let rect = CGRect(x: pt.position.x - 5, y: pt.position.y - 5, width: 10, height: 10)
                context.fill(Path(rect), with: .color(.white))
                context.stroke(Path(rect), with: .color(.blue), lineWidth: 2)
            }
        }
    }
}

private struct PencilDraftingOverlay: View {
    let points: [CGPoint]
    
    var body: some View {
        Canvas { context, _ in
            guard points.count >= 2 else { return }
            var path = Path()
            path.move(to: points[0])
            for pt in points.dropFirst() {
                path.addLine(to: pt)
            }
            context.stroke(path, with: .color(.orange), lineWidth: 2.5)
        }
    }
}

private struct ShapeDraftingOverlay: View {
    let rect: CGRect
    let shapeType: VectorShapeType
    
    var body: some View {
        ZStack {
            switch shapeType {
            case .rect:
                Rectangle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    .foregroundColor(.blue)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            case .ellipse:
                Circle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    .foregroundColor(.blue)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            default:
                Rectangle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    .foregroundColor(.blue)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            }
        }
    }
}

private struct SelectionBoundingBoxOverlay: View {
    let viewModel: VectorEditorViewModel
    let artboard: ArtboardNode
    
    var body: some View {
        // Calculate union bounding box of selected nodes
        var box: CGRect = .null
        for child in artboard.children where viewModel.selectedNodeIDs.contains(child.id) {
            box = box.union(getFrame(child))
        }
        
        if !box.isNull {
            let padded = box.insetBy(dx: -4, dy: -4)
            ZStack {
                Rectangle()
                    .stroke(Color.accentColor, lineWidth: 1.5)
                    .frame(width: padded.width, height: padded.height)
                    .position(x: padded.midX, y: padded.midY)
                
                // 4 Corner Handles
                ForEach([
                    CGPoint(x: padded.minX, y: padded.minY),
                    CGPoint(x: padded.maxX, y: padded.minY),
                    CGPoint(x: padded.minX, y: padded.maxY),
                    CGPoint(x: padded.maxX, y: padded.maxY)
                ], id: \.x) { pt in
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                        .border(Color.accentColor, width: 1.5)
                        .position(pt)
                }
            }
        }
    }
    
    private func getFrame(_ node: VectorNode) -> CGRect {
        switch node {
        case .path(let p):
            var b: CGRect = .null
            for sub in p.subpaths { b = b.union(sub.boundingBox) }
            return b.isNull ? CGRect(x: 0, y: 0, width: 50, height: 50) : b
        case .parametric(let s): return s.frame
        case .text(let t): return CGRect(origin: t.origin, size: CGSize(width: 100, height: 40))
        case .group(let g):
            var b: CGRect = .null
            for c in g.children { b = b.union(getFrame(c)) }
            return b.isNull ? .zero : b
        }
    }
}

// MARK: - Color Hex Initializer

private extension Color {
    init?(hex: String) {
        var clean = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        if clean.count == 6 { clean += "FF" }
        guard clean.count == 8, let val = UInt32(clean, radix: 16) else { return nil }
        let r = Double((val >> 24) & 0xFF) / 255.0
        let g = Double((val >> 16) & 0xFF) / 255.0
        let b = Double((val >> 8) & 0xFF) / 255.0
        let a = Double(val & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
