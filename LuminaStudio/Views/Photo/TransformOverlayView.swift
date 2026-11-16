import SwiftUI
import EditorCore

public struct TransformOverlayView: View {
    @Bindable public var viewModel: PhotoEditorViewModel
    
    public init(viewModel: PhotoEditorViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        guard let layer = viewModel.activeLayer else { return AnyView(EmptyView()) }
        let canvasSize = viewModel.document.configuration.size
        let layerRect = CGRect(x: 0, y: 0, width: layer.pixelWidth > 0 ? layer.pixelWidth : Int(canvasSize.width),
                               height: layer.pixelHeight > 0 ? layer.pixelHeight : Int(canvasSize.height))
        
        let screenTopLeft = viewModel.viewport.screenPoint(from: CGPoint(x: layerRect.minX, y: layerRect.minY), canvasSize: canvasSize)
        let screenBottomRight = viewModel.viewport.screenPoint(from: CGPoint(x: layerRect.maxX, y: layerRect.maxY), canvasSize: canvasSize)
        let screenRect = CGRect(
            x: min(screenTopLeft.x, screenBottomRight.x),
            y: min(screenTopLeft.y, screenBottomRight.y),
            width: abs(screenBottomRight.x - screenTopLeft.x),
            height: abs(screenBottomRight.y - screenTopLeft.y)
        )
        
        return AnyView(
            ZStack {
                // Layer Bounding Box Outline
                Rectangle()
                    .stroke(Color.accentColor, lineWidth: 1.5)
                    .frame(width: screenRect.width, height: screenRect.height)
                    .position(x: screenRect.midX, y: screenRect.midY)
                
                // 8 Resize Handles
                handle(at: CGPoint(x: screenRect.minX, y: screenRect.minY))
                handle(at: CGPoint(x: screenRect.midX, y: screenRect.minY))
                handle(at: CGPoint(x: screenRect.maxX, y: screenRect.minY))
                handle(at: CGPoint(x: screenRect.minX, y: screenRect.midY))
                handle(at: CGPoint(x: screenRect.maxX, y: screenRect.midY))
                handle(at: CGPoint(x: screenRect.minX, y: screenRect.maxY))
                handle(at: CGPoint(x: screenRect.midX, y: screenRect.maxY))
                handle(at: CGPoint(x: screenRect.maxX, y: screenRect.maxY))
                
                // Rotation Stalk Handle
                Path { p in
                    p.move(to: CGPoint(x: screenRect.midX, y: screenRect.minY))
                    p.addLine(to: CGPoint(x: screenRect.midX, y: screenRect.minY - 24))
                }
                .stroke(Color.accentColor, lineWidth: 1.5)
                
                Circle()
                    .fill(Color.white)
                    .stroke(Color.accentColor, lineWidth: 2)
                    .frame(width: 14, height: 14)
                    .position(x: screenRect.midX, y: screenRect.minY - 24)
            }
            .allowsHitTesting(false)
        )
    }
    
    private func handle(at point: CGPoint) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.white)
            .stroke(Color.accentColor, lineWidth: 1.5)
            .frame(width: 12, height: 12)
            .position(point)
    }
}
