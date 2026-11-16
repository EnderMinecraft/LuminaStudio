import SwiftUI
import EditorCore

public struct CropOverlayView: View {
    @Bindable public var viewModel: PhotoEditorViewModel
    
    public init(viewModel: PhotoEditorViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        let canvasSize = viewModel.document.configuration.size
        let crop = viewModel.cropConfig.cropRect
        
        let screenTL = viewModel.viewport.screenPoint(from: CGPoint(x: crop.minX, y: crop.minY), canvasSize: canvasSize)
        let screenBR = viewModel.viewport.screenPoint(from: CGPoint(x: crop.maxX, y: crop.maxY), canvasSize: canvasSize)
        let screenRect = CGRect(
            x: min(screenTL.x, screenBR.x),
            y: min(screenTL.y, screenBR.y),
            width: abs(screenBR.x - screenTL.x),
            height: abs(screenBR.y - screenTL.y)
        )
        
        let (verts, horizs) = viewModel.cropConfig.ruleOfThirdsLines
        let v1Screen = viewModel.viewport.screenPoint(from: CGPoint(x: verts.0, y: 0), canvasSize: canvasSize).x
        let v2Screen = viewModel.viewport.screenPoint(from: CGPoint(x: verts.1, y: 0), canvasSize: canvasSize).x
        let h1Screen = viewModel.viewport.screenPoint(from: CGPoint(x: 0, y: horizs.0), canvasSize: canvasSize).y
        let h2Screen = viewModel.viewport.screenPoint(from: CGPoint(x: 0, y: horizs.1), canvasSize: canvasSize).y
        
        return ZStack {
            // Darkened outer mask
            Color.black.opacity(0.4)
                .mask {
                    Rectangle()
                        .overlay {
                            Rectangle()
                                .frame(width: screenRect.width, height: screenRect.height)
                                .position(x: screenRect.midX, y: screenRect.midY)
                                .blendMode(.destinationOut)
                        }
                }
            
            // White Crop Border
            Rectangle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: screenRect.width, height: screenRect.height)
                .position(x: screenRect.midX, y: screenRect.midY)
            
            // Rule-of-Thirds Grid Lines
            Path { p in
                // Vertical lines
                p.move(to: CGPoint(x: v1Screen, y: screenRect.minY))
                p.addLine(to: CGPoint(x: v1Screen, y: screenRect.maxY))
                
                p.move(to: CGPoint(x: v2Screen, y: screenRect.minY))
                p.addLine(to: CGPoint(x: v2Screen, y: screenRect.maxY))
                
                // Horizontal lines
                p.move(to: CGPoint(x: screenRect.minX, y: h1Screen))
                p.addLine(to: CGPoint(x: screenRect.maxX, y: h1Screen))
                
                p.move(to: CGPoint(x: screenRect.minX, y: h2Screen))
                p.addLine(to: CGPoint(x: screenRect.maxX, y: h2Screen))
            }
            .stroke(Color.white.opacity(0.5), lineWidth: 1)
            
            // Corner Bracket Handles
            cornerBracket(at: CGPoint(x: screenRect.minX, y: screenRect.minY), dx: 1, dy: 1)
            cornerBracket(at: CGPoint(x: screenRect.maxX, y: screenRect.minY), dx: -1, dy: 1)
            cornerBracket(at: CGPoint(x: screenRect.minX, y: screenRect.maxY), dx: 1, dy: -1)
            cornerBracket(at: CGPoint(x: screenRect.maxX, y: screenRect.maxY), dx: -1, dy: -1)
        }
        .allowsHitTesting(false)
    }
    
    private func cornerBracket(at point: CGPoint, dx: CGFloat, dy: CGFloat) -> some View {
        Path { p in
            p.move(to: CGPoint(x: point.x, y: point.y + dy * 20))
            p.addLine(to: point)
            p.addLine(to: CGPoint(x: point.x + dx * 20, y: point.y))
        }
        .stroke(Color.white, lineWidth: 3)
    }
}
